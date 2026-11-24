# Inspection Draft Context and Revision Lifecycle — Technical Proposal

**Document ID:** INSPECTION-DRAFT-001  
**Version:** 0.1.1  
**Date:** 2026-11-24  
**Status:** Engineering / Database / Security / Product Owner review required — NOT APPROVED  
**Scope:** CMD-026 claim-unit; CMD-028 save-draft; CMD-029 submit-inspection; CMD-030 return-inspection; CMD-032 reopen-inspection; CMD-033/034 evidence upload/finalization  
**Product journey:** Dit. SD IFP and Standing Bracket inspection only  
**Authority:** PRD §6; Decision Register WF-001, WF-002, INS-010, T-09, T-16, SES-001; CMD-021–030 and CMD-031–040 detailed reviews; physical schema v0.4.4; AGENTS.md.

## 1. Purpose and user-journey contract

This proposal resolves one specific ambiguity: the application needs a durable, mutable workspace while an Inspector is completing or correcting an inspection, but a submitted inspection revision must be immutable.

The physical model currently defines immutable submitted `inspection_revisions` and revision-keyed response rows, while CMD-028 and CMD-032 require a mutable draft context that is not yet physicalized. The proposal separates these concepts without changing the field workflow or introducing new application actors.

The user-facing journey remains:

1. Super Admin configures a project, session, location, IFP or Standing Bracket instrument version, team and operational assignment.
2. An approved Inspector opens work in the exact active assignment and claims the unit while online.
3. The application resolves the canonical serial under the selected instrument type, confirms the project association and prevents a second active claim.
4. The Inspector records the checklist, specification observations, findings and configured photo evidence.
5. The Inspector may continue editing only an already-claimed draft while offline under T-09 controls; submission remains online-only.
6. Server-side completeness, evidence and sync checks pass before submission. Submission freezes one immutable revision.
7. The assigned Reviewer either returns that exact revision with a reason or approves it. The Reviewer never edits Inspector answers.
8. A returned inspection receives a new editable draft context based on the returned revision. The Inspector corrects it and submits a new immutable revision; earlier revisions remain unchanged.
9. An approved inspection can be reopened only through CMD-032 with explicit authority, exact approved revision and mandatory reason. Reopen creates a new draft context; it does not change the approved revision or its downstream artifacts.
10. Only an approved immutable revision is eligible for final PDF/BA generation and Print Officer print/reprint. Reporting distinguishes Inspected, Submitted, Approved and Completed; Completed still requires approved inspection + final PDF + recorded Print Officer print action.

IFP and Standing Bracket remain separate published instrument versions. Their configured checklist, specification fields, evidence slots and applicability rules are evaluated against the version pinned to the assignment/inspection. The currently documented IFP ten photo labels and Standing Bracket five photo labels are reference lists only; required/conditional status remains OPEN until the controlled source/configuration is approved. This proposal does not change instrument content.

## 2. Core design rule

**A draft context is mutable working state; an inspection revision is an immutable submitted snapshot.**

Do not use an unsubmitted mutable row in `inspection_revisions` and then describe it as immutable. Do not update a submitted revision to correct it. Do not create a second inspection aggregate for a return or approved reopen.

Candidate relation: `inspection_draft_contexts` (new, candidate-only).

- One inspection aggregate may have multiple historical draft contexts over its lifecycle.
- At most one context may be ACTIVE for an inspection at a time.\n- Every inspection attempt is immutably bound to exactly one session (`session_id`); no context, claim, draft, evidence workflow or returned correction may be resumed in another session.\n- An unfinished attempt must be explicitly aborted before its session can be finally closed. ABORTED is terminal; a later session creates a new inspection attempt and context rather than reviving the old one.
- An ACTIVE context is the only writable working copy.
- On successful submission, the context is sealed as SUBMITTED and is bound to exactly one new immutable `inspection_revisions` row.
- A later return or authorized reopen creates a new ACTIVE context. It never reactivates or overwrites an old context.
- Draft contexts and submitted revisions retain their original instrument-version binding.

This relation is not admitted to the canonical 48-table physical inventory. It is a candidate entity pending review and cross-document admission.

## 3. Candidate physical representation

### 3.1 `inspection_draft_contexts`

| Candidate attribute | Purpose / rule |
|---|---|
| `id` | Server-generated UUID primary key |
| `inspection_id` | FK to the stable inspection aggregate |\n| `session_id` | Immutable FK to the exact active session in which this inspection attempt was claimed; never reassigned |
| `context_no` | Monotonic per-inspection draft-context sequence; unique with inspection_id |
| `instrument_version_id` | Exact published version pinned by the inspection/assignment |
| `base_revision_id` | Nullable FK to the immutable revision from which a correction/reopen draft is derived; null for the initial draft |
| `origin` | Closed server-owned vocabulary: INITIAL, RETURN_CORRECTION, APPROVED_REOPEN |
| `status` | ACTIVE, SUBMITTED or ABORTED; no client-selected status; ABORTED is terminal |
| `payload_schema_version` | Version of the strict typed draft payload contract |
| `draft_payload` | Canonical mutable working payload; server validates against the pinned instrument version |
| `created_at / created_by` | Server timestamp and trusted command actor |
| `updated_at` | Server timestamp; never client time |

Candidate constraints:
- Unique `(inspection_id, context_no)`.
- At most one ACTIVE row per inspection (partial unique index or equivalent final database invariant).
- Composite FK/constraint must prove the context belongs to the same inspection and instrument version.
- `base_revision_id`, when present, must belong to the same inspection and same pinned instrument version.
- An ACTIVE context cannot be edited after it transitions to SUBMITTED.
- A SUBMITTED context must resolve to exactly one immutable revision through `inspection_revisions.source_draft_context_id` (candidate FK/unique key).
- Context history is not hard-deleted. No abandoned/cancelled state is introduced until a real user journey requires one.

### 3.2 Inspection aggregate pointer

Candidate addition to `inspections`: nullable `active_draft_context_id`, with a composite FK proving the pointed context belongs to the same inspection. The pointer must equal the sole ACTIVE context or be null when there is no editable draft.

The inspection aggregate remains the lifecycle and serialization point. Its `session_id` is immutable and must match the session pinned by the originating operational assignment/claim. Its existing `row_version` remains the optimistic concurrency token for CMD-028 and state-changing inspection commands unless Engineering approves a single consistent alternative. Do not add a second independently incremented token without defining which command owns each increment.

### 3.3 Immutable revision linkage

Candidate addition to `inspection_revisions`: `source_draft_context_id`, unique and non-null for revisions created through the normal submit workflow. This identifies the exact sealed context from which the submitted snapshot was built.

The submitted revision continues to carry:
- inspection_id and monotonically allocated revision_no;
- exact instrument_version_id and canonical payload snapshot/hash;
- immutable author_id and submitted_at;
- normalized `checklist_responses` and `specification_responses` keyed to the submitted revision.

The draft JSON payload is not a replacement for the immutable submitted snapshot or normalized revision response rows. At submission, the server validates and materializes the canonical payload into the immutable revision snapshot and revision-keyed response records in one transaction.

### 3.4 Draft payload contract

`draft_payload` is JSONB storage, not an arbitrary merge API. It must have:
- an explicit `payload_schema_version`;
- allowlisted checklist item IDs and typed answers from the exact pinned instrument version;
- allowlisted specification field IDs and typed observed values;
- bounded notes/findings fields subject to T-10 privacy approval;
- explicit semantics for omitted, null, empty and removal operations;
- deterministic canonicalization for equality/no-op detection and eventual submission snapshot hashing.

CMD-028 remains a strict patch command. The server applies the patch to the existing canonical draft payload, validates the complete resulting payload and increments the inspection row_version exactly once for a semantic change. An omitted collection must never delete existing answers. Arbitrary client JSON merge, unknown item IDs, cross-version fields and unsupported answer/value types are rejected.

## 4. Evidence lifecycle and exact revision binding

CMD-033/034 must target the active draft context, not an unsubmitted immutable revision ID. The existing `revision_context` input is therefore a candidate reference to `inspection_draft_contexts.id`; this mapping must be made explicit before API freeze.

Candidate evidence linkage:
- CMD-033 creates an upload intent for one exact active draft context, pinned instrument version and configured slot.
- CMD-034 server-verifies the private Storage object and finalizes evidence metadata for that draft context. Client-declared checksum/size/MIME are not proof.
- Candidate `evidence_assets.draft_context_id` binds pre-submit evidence to the active context.
- During CMD-029, each accepted evidence asset is bound once to the exact newly created immutable `inspection_revision_id` in the same transaction that seals the draft and creates the revision. Object key, bytes, checksum, uploader and original capture/upload metadata are never overwritten.
- After revision binding, evidence is immutable and cannot be reattached to another revision by ordinary application roles.

**Evidence carry-forward is OPEN.** The prior approved/returned revision's evidence remains preserved and viewable as historical evidence to authorized participants. This proposal does not silently copy an old evidence asset into a new revision or claim that historical evidence satisfies a new revision's required slot. Product Owner and institutional evidence authority must decide whether unchanged evidence may be explicitly carried forward, what provenance/revalidation is required, and how the exact revision link is represented. Until that decision and the physical relationship are approved, do not infer reuse; submission must follow the approved required-evidence policy.

No evidence slot is made mandatory by this proposal. IFP and Standing Bracket slot mandatory/applicability flags remain configuration/source-controlled.

## 5. Lifecycle mapping to the actual inspection journey

| Journey point | Command | Draft-context behavior | Revision/history behavior |
|---|---|---|---|
| First online unit claim | CMD-026 | Create initial ACTIVE context atomically with a new inspection; resume existing context only under approved resume rules | No submitted revision is created |
| Save checklist/specification/finding | CMD-028 | Patch the one ACTIVE context; validate pinned instrument version; use inspection row_version CAS | No submitted revision or historical response is overwritten |
| Capture/upload evidence | CMD-033/034 | Intent and verified evidence bind to active context | Evidence is linked to exact immutable revision only at successful submit |
| Inspector submits | CMD-029 | Validate complete context; seal it as SUBMITTED; clear active pointer | Create next immutable revision, snapshot/hash, normalized response rows and exact evidence links atomically |
| Reviewer returns | CMD-030 | Create a new ACTIVE context seeded from the exact returned revision's answer/specification snapshot; set origin RETURN_CORRECTION | Append RETURN decision/event; returned revision and its evidence remain unchanged |
| Inspector corrects/resubmits | CMD-028/029 | Edit the new active context; submit it once | Create revision_no + 1; prior revision and review event remain immutable |
| Reviewer approves | CMD-031 | No active draft is permitted for the approved transition | Append APPROVE decision/event for the exact current submitted revision |
| Authorized reopen | CMD-032 | Create a new ACTIVE context seeded from the exact approved revision; set origin APPROVED_REOPEN | Preserve approved revision, review decision, evidence, generated documents and print history |
| PDF generation/printing | CMD-036–038 | Not permitted from an ACTIVE/unsubmitted draft | Source must be the exact approved immutable revision and approved template version |

CMD-030 and CMD-032 context creation is part of the same transaction as the return/reopen state change, event/audit append and idempotency result. If any required write fails, neither the lifecycle transition nor the new context commits.

### 5.1 Claim and editing authority

The draft context does not itself grant permission to edit. Normal edit and evidence commands require the valid active claim, claim owner, approved account, effective Inspector assignment, project/session scope and explicit permissions.

- Initial CMD-026 claim creates the inspection and its first active draft context atomically.
- Return/reopen does not silently create a second inspection or transfer/release a claim.
- The existing claim/resume workflow must explicitly define how an eligible Inspector obtains or resumes the active draft after RETURNED_FOR_CORRECTION or REOPENED. A returned revision's author is not automatically granted a new claim, and a generic assignment member cannot bypass claim ownership.
- If claim ownership, assignment membership, association or session state is invalid, editing remains blocked until the approved recovery/reassignment path resolves it.
- Offline editing remains limited to the already-claimed draft; claim acquisition, submit, review, reopen, PDF finalization and print remain online-only.

The claim TTL, release-on-submit behavior, resume/reassignment and post-approval claim disposition remain separate open decisions. This proposal does not change them.

## 6. CMD-032 reopen guardrails

CMD-032 is allowed only when:
- the inspection is APPROVED;
- the supplied approved_revision_id is the exact currently approved immutable revision;
- actor has explicit approved `inspection.reopen` authority and exact project/inspection scope;
- reason is present and audited;
- no active draft context already exists;
- no conflicting active claim, claim takeover, new reinspection, report/document generation or finalizer is in a state that makes reopening unsafe under the final approved blocker graph.

On success, one new ACTIVE context is created from the approved revision's canonical answer/specification snapshot, with origin APPROVED_REOPEN and base_revision_id set to the approved revision. The inspection moves to the final approved reopened state label (the existing CMD-032 candidate is REOPENED; canonical enum admission remains open), active_draft_context_id is set, row_version increments once, and inspection.reopened + audit + idempotency records commit atomically.

CMD-032 must not:
- update or delete the approved inspection_revisions row, review_events, checklist/specification response rows, evidence objects, generated documents, print batches/events or audit history;
- silently select a new Inspector, Reviewer, assignment, team, location or project;
- silently release, expire, transfer or create a claim;
- create a second inspection aggregate for the same unit lifecycle;
- bypass session/project closure or active-work/finalizer fences.

The identity of the next Inspector/claim owner after reopen remains OPEN and must be decided by the authorized operational owner. The new context may exist but remains non-editable until a valid claim and assignment authority exist.

## 7. State and integrity invariants

1. At most one ACTIVE draft context per inspection.
2. An inspection's active_draft_context_id points only to its own ACTIVE context.
3. One draft context can produce at most one submitted immutable revision.
4. One submitted revision belongs to exactly one inspection and one pinned instrument version.
5. Revision numbers are allocated under the inspection aggregate lock and unique per inspection.
6. A submitted revision and its normalized response rows are never updated/deleted by normal application roles.
7. A return or reopen creates a new context; it never reactivates an old submitted context.
8. CMD-030 RETURN and CMD-031 APPROVE share one inspection serialization point and one terminal-decision-per-revision arbiter.
9. Evidence intent/finalization is bound to one active context; successful submission binds the evidence to one exact immutable revision without changing object identity.
10. A failed audit/event/idempotency write rolls back the state transition, context creation/seal and revision creation.
11. A stale expected_row_version cannot overwrite newer draft content.
12. Closed/paused parent lifecycle, invalid claim, invalid association, invalid assignment and unresolved sync conflicts block the relevant mutation according to approved gates.
13. PDF and print operations source only an approved immutable revision; a draft or returned inspection is never reportable as approved/completed.
14. Notification delivery/read state never changes inspection state or assigns work.

## 8. Required user-journey acceptance scenarios

All cases below are design requirements only — NOT EXECUTED.

| ID | Scenario | Expected result |
|---|---|---|
| IDC-01 | Inspector claims a new IFP unit online | One inspection + one ACTIVE draft context; pinned IFP version |
| IDC-02 | Inspector claims a Standing Bracket unit | One inspection + one ACTIVE context; pinned Standing Bracket version; no IFP schema crossover |
| IDC-03 | Two Inspectors claim the same canonical unit concurrently | One active claim and one inspection lifecycle only |
| IDC-04 | Inspector saves partial checklist then loses connectivity | Only already-claimed draft can continue offline under T-09 controls |
| IDC-05 | Sync replays same operation | Idempotent result; no duplicated response/evidence |
| IDC-06 | Sync conflicts with a newer server draft | Preserve both versions; explicit conflict; never last-write-wins |
| IDC-07 | Inspector submits with missing required applicable answer/evidence | Submission rejected; draft remains editable; no immutable revision created |
| IDC-08 | Successful submit | One immutable revision + normalized response rows + exact evidence binding + atomic events/audit |
| IDC-09 | Reviewer returns with a reason | Submitted revision remains unchanged; one new ACTIVE correction context is created from its answer/specification snapshot |
| IDC-10 | Inspector corrects and resubmits | New revision number; previous revision/return reason/evidence history preserved |
| IDC-11 | Reviewer attempts self-review | Denied when reviewer equals exact revision author |
| IDC-12 | Concurrent RETURN vs APPROVE on same revision | Exactly one terminal decision commits |
| IDC-13 | Authorized actor reopens exact approved revision with reason | New ACTIVE reopen context; approved revision/PDF/print history unchanged |
| IDC-14 | Two concurrent reopen requests with distinct idempotency keys | One context and one reopen event; second receives typed state conflict |
| IDC-15 | Reopen races with PDF generation or print finalization | Deterministic serialization/blocker; no approved artifact is rewritten |
| IDC-16 | Save with stale row_version | STALE_VERSION; no response or evidence metadata lost |
| IDC-17 | Evidence upload intent targets another inspection/context or wrong instrument slot | Denied |
| IDC-18 | Browser attempts direct DML on draft payload or revision rows | Denied by ACL/RLS; only trusted command boundary mutates |
| IDC-19 | Audit append fails during return/reopen/submit | Full transaction rollback; no partial context/revision/state |
| IDC-20 | Draft context expires only because claim expires | Context and local/server evidence history are preserved; no silent deletion or ownership transfer |

## 9. Cross-document admission required

This proposal is not admitted until the following are reconciled and approved:
- PRD and Decision Register: user-visible correction/reopen behavior, evidence carry-forward, next-action owner and any change to WF-001/WF-002/INS-010;
- physical schema and ERD: candidate relation, FKs, unique active-context invariant, active pointer, source_draft_context_id, evidence draft/revision binding, JSONB payload schema and immutability enforcement;
- CMD-026/028/029/030/032/033/034: exact request/response IDs, claim resume, row_version owner, evidence context mapping, transaction/read/write sets and error outcomes;
- lock manifest/global graph: context creation/update/seal, evidence finalization, reviewer decision, reopen, claim and document-finalizer paths;
- RLS/ACL/function security: no browser direct DML; exact caller-JWT command boundaries;
- audit/event registry and notification mapping: exact events, atomicity, recipients and no implicit role/participant inference;
- RTM, RAID, DGA and QA: stable requirements, accountable owners, unresolved policy decisions and adversarial tests.

## 10. Open decisions and disposition

| ID | Open question | Accountable authority |
|---|---|---|
| IDC-O01 | Approve candidate `inspection_draft_contexts` relation and strict JSONB payload representation | Product Owner / Engineering / Database |
| IDC-O02 | Confirm one active context per inspection and initial context creation within CMD-026 | Product Owner / Engineering / Database |
| IDC-O03 | Confirm context creation on CMD-030 return and CMD-032 reopen | Product Owner / operational owner / Engineering |
| IDC-O04 | Decide who owns/claims a returned or reopened draft; no silent transfer | Product Owner / operational owner |
| IDC-O05 | Decide claim release/expiry/resume behavior across submit, return, approve and reopen | Product Owner / operational owner / Engineering |
| IDC-O06 | Decide evidence carry-forward/reuse across revisions and its provenance/link model | Product Owner / institutional evidence authority / Database |
| IDC-O07 | Approve draft payload answer types, note/privacy policy, JSONB bounds and canonical hash | Product Owner / Security / Engineering / Database |
| IDC-O08 | Prove active-context uniqueness, FK consistency, CAS and lock graph under concurrency | Database / Engineering / Security / QA |
| IDC-O09 | Confirm CMD-032 blocker policy against claims, association, session closure and document finalizers | Operational owner / Engineering / Database |

**Disposition:**
- Separate mutable draft context from immutable submitted revision: **CANDIDATE PROPOSED; NOT APPROVED**.
- One active context per inspection: **CANDIDATE INVARIANT; APPROVAL REQUIRED**.
- CMD-026 creates initial context; CMD-030 and CMD-032 create follow-on contexts: **CANDIDATE FLOW; APPROVAL REQUIRED**.
- Reviewer cannot edit Inspector data; return creates a new correction context: **CONSISTENT WITH APPROVED WF-001 / INS-010 DIRECTION; PHYSICAL DESIGN STILL OPEN**.
- Approved revision and all historical evidence/documents/print records remain immutable after reopen: **REQUIRED BY WF-002 / CMD-032 CONTRACT**.
- Evidence carry-forward, next Inspector/claim owner and claim lifecycle: **OPEN — NO ASSUMPTION**.
- Physical DDL, migration, grants, RLS, runtime tests: **NOT AUTHORIZED / NOT PERFORMED**.
- G9: **NOT READY**; G10: **NOT ACTIVE**.

This proposal preserves the intended field workflow while separating mutable work-in-progress from immutable inspection evidence. It is not Product Owner, institutional, Engineering, Database, Security or QA approval.

## 11. PO-approved session-bound attempt and abort lifecycle — SES-001 (2026-11-24)

The Product Owner approved SES-001 in the canonical Decision Register. This section is a technical reconciliation of that decision; it does not by itself admit the candidate schema or certify command/lock contracts.

### 11.1 Session binding
- Each inspection attempt is created/claimed in one exact active session and stores an immutable session_id.
- CMD-028 draft edits, T-09 offline continuation, CMD-033/034 evidence operations, CMD-029 submit and any WF-001 returned correction are valid only within that same session.
- The Inspector who authored the returned revision remains the only Inspector allowed to correct it; the correction must still occur within the original session.
- No resume, claim transfer, context reactivation or draft continuation is allowed across sessions.

### 11.2 Abort before final session closure
- A unit attempt that is incomplete when the session is being closed must be explicitly transitioned to terminal ABORTED before final session closure.
- Abort is not submit, return, approval or completion. It must preserve the inspection attempt, any already-submitted immutable revisions, captured evidence and audit history.
- Abort must atomically terminate the active draft context, close/release the attempt's active claim, append the required event/audit record and store the idempotency result. If any required write fails, the abort and session-close progression fail closed.
- A unit in ABORTED state cannot be edited, submitted, reopened or resumed. A subsequent session creates a new inspection attempt bound to that new session; it does not mutate the old attempt.
- Evidence from an aborted attempt remains historical and is not automatically carried into the new attempt. Any future evidence reuse requires a separately approved provenance/policy model.
- Final session closure is blocked while any unit attempt remains unresolved; each must first reach an allowed terminal state or be explicitly aborted.

### 11.3 Command and model implications (candidate only)
- Add immutable session_id to the inspection aggregate and enforce same-session consistency across claim, draft context, evidence, revisions and assignment scope.
- Add ABORTED to the candidate inspection-attempt and draft-context terminal vocabulary; do not represent abort as SUBMITTED or a generic claim release alone.
- CMD-027 currently means release-unit-claim. Engineering must decide whether it can safely implement the full abort transaction or whether a dedicated command is needed. A claim release without terminally aborting the inspection attempt is insufficient.
- Session close command must inspect all unit attempts in its exact session and refuse closure until unresolved attempts are completed or aborted.
- Physical uniqueness must permit a new attempt in a later session while preserving global canonical unit identity and preventing simultaneous active claims. Exact historical-attempt key/constraint strategy remains for Database review.

### 11.4 Explicit boundary still requiring resolution
SES-001 clearly prohibits cross-session continuation and requires abort of unfinished attempts before session close. The precise disposition of a revision returned by a Reviewer but not corrected before session closure must be encoded as an abort of the overall attempt, preserving the returned immutable revision and reason. A later session must start a new attempt; it must not reopen the prior correction context. The same Inspector restriction applies to correction while the original session remains active.

**Disposition:** SES-001 product semantics are PO APPROVED. Session FK, abort state machine, CMD-027 versus dedicated abort command, claim-release atomicity, session-close writer/lock graph, RLS/ACL, event registry, physical constraints and QA remain NOT CERTIFIED / OPEN. No schema or implementation is approved by this proposal.