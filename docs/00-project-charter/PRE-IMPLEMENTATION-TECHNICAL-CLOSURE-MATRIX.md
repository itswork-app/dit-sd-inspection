# Pre-Implementation Technical Closure Matrix — F-03, F-04 and SES-001

**Document ID:** PTCM-001  
**Version:** 0.1.1  
**Status:** CONTROLLED STATIC CLOSURE MATRIX — REVIEW REQUIRED; NOT APPROVED FOR IMPLEMENTATION  
**Date:** 2026-11-25  
**Repository baseline:** `main` at `0db79d376face690b353d466a18129b6dd0ae5b2`  
**Authority:** AGENTS.md v1.2.3; MIB-001; DGA-001; LOCK-GRAPH-001 v0.4.25; LOCK-MANIFEST-001 v0.4.32; LOCK-NORMALIZATION-001 v0.1.1; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.14; NLA-L05-TDR-001 v0.1.14; NLA-L05-WRITER-MATRIX-001 v0.1.6; SES-001 Decision Register; QA v0.7.3  
**Gate:** G9 NOT READY; G10 NOT ACTIVE

## 1. Purpose and boundary

This matrix turns the currently documented F-03 global lock-order, F-04 eligibility-writer participation and SES-001 packed-unit ABORT gaps into evidence-oriented closure work. It is a cross-document navigation and acceptance-control artifact. It does not approve a lock rank, allocate a command ID, admit a physical relation, certify a writer, create institutional authority, or authorize implementation.

The only permitted work before G10 remains documentation, read-only repository inspection and static consistency analysis. The repository currently contains no application source tree, executable migration history or deployed database catalog snapshot. The current governance boundary does not authorize live database inspection. Therefore physical/deployed evidence must be supplied through a separately authorized and controlled evidence process; it cannot be fabricated from design documents.

## 2. Current evidence baseline

| Item | Current evidence | Disposition |
|---|---|---|
| Command traceability | 54 IDs; 50 application commands and 4 external control-plane IDs | Inventory only |
| Candidate lock manifests | Candidate boundaries recorded for 50 application commands | 0/50 technically certified |
| Global lock graph | Conflicting candidate orders and unverified implicit edges recorded | NOT PROVEN ACYCLIC |
| L05 source declarations | CMD-001–040 mapped at design level | 40/40 declarations; 0/40 resolver paths certified |
| Eligibility writer matrix | Logical writer classes listed; physical entrypoints and owners absent | F-04 OPEN; 0 writers certified |
| Notification candidates | 11 PO-approved candidate intents | 0 technically admitted; 0 enabled |
| SES-001 | Session-bound attempt and exceptional packed-unit ABORT semantics approved by PO | Technical contract incomplete |
| QA | Test specifications exist | PLANNED / NOT EXECUTED |
| CI / runtime | No checks/workflow evidence returned for the reviewed documentation commits | ABSENT; not PASS |

## 3. F-03 — Global lock-order closure matrix

### 3.1 Known source-level ordering conflicts

These are contradictions already recorded in LOCK-GRAPH-001 §4–6 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 §4. They are not reproduced database deadlocks and must not be described as such.

| Conflict ID | Paths / shared invariant | Contradiction or missing proof | Required closure evidence | Current status |
|---|---|---|---|---|
| F03-C01 | CMD-022–027 canonical unit identity, association, claim | CMD-023 has a unit-first recipe; CMD-026 detailed review requires canonical identity → project/session/assignment → unit → association → inspection/claim; CMD-026 catalogue row differs | One reviewed command-by-command lock set for CMD-022–028, exact shared keys, deterministic multi-row ordering, FK/unique/trigger/helper edges and opposing-command tests | OPEN |
| F03-C02 | CMD-009–016 project/session/assignment closure and child writes | Parent-first guidance exists but full child-writer/finalizer participation and actual fence modes are not proven | Exact parent fence, child mutation/finalizer inventory, transaction boundaries, compatible row-lock modes and close-vs-child race evidence | OPEN |
| F03-C03 | CMD-004/005/014/015/016 T-14 capacity | Capacity-first candidate rule is not proven for all account, role, membership, expiry, admin and repair writers | Exact qualifying predicate and affected-project set; all writer entrypoints; common serialization point; deterministic opposing transactions | OPEN |
| F03-C04 | CMD-014/018–021 assignment and instrument | Relative ordering of project/session/assignment versus instrument/version is unresolved | One approved relative order, immutable version pin semantics, instrument deactivate/publish vs assignment publication tests | OPEN |
| F03-C05 | CMD-026–034 inspection, claim, revision, review, evidence | Claim/inspection/child ordering, active-claim arbiter, revision concurrency and evidence finalization are incomplete | Exact aggregate lock sets, terminal decision uniqueness, draft-context arbiter, same-session checks, stale revision denial and submit/return/reopen/evidence races | OPEN |
| F03-C06 | CMD-035 sync operations | Batch envelope vs per-operation transaction/savepoint semantics and event cardinality unresolved | Approved per-operation atomicity contract, operation identity, replay/partial failure outcomes and online-vs-sync concurrency evidence | OPEN |
| F03-C07 | CMD-036–040 async document/print/attendance finalizers | Worker identity/lease rank, print sequence arbiter, attendance aggregate/version and verifier authority incomplete | Exact finalizer transaction, lease fencing, per-item print outcomes, immutable source/document version and institutional attendance approval | OPEN |
| F03-C08 | CMD-049–054 notification and workers | L05 candidate guard, snapshot FK effects, worker queue locks, provider callback and escalation identity not admitted | Technical approval of L05 or approved alternative, complete source/writer participation, worker principal/ACL, callback trust and queue/finalizer order | OPEN |
| F03-C09 | All 50 application commands | FK KEY SHARE, unique-index waits, triggers, cascades, deferred constraints and nested helpers are not represented by a verified deployed graph | Exact physical catalog and call graph for the target schema revision; graph construction and independent acyclicity review | OPEN |

### 3.2 Candidate rank table is not an approval

LOCK-GRAPH-001 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 contain a candidate L00/L10/L15–L110 ordering. This PTCM does not endorse or normalize that candidate into canonical command instructions. LPR-01 and LPR-07–LPR-11 remain open as recorded in the lock-protocol decision register.

In particular:
- Do not resolve CMD-023/CMD-026 by selecting whichever narrative appears newest; reconcile catalogue, detailed command reviews, physical constraints and competing writers under accountable review.
- Do not insert candidate L05 into the canonical graph until its primitive/key, transaction lifetime, function volatility/snapshot semantics, timeout/retry, every selector dependency and complete writer participation are technically approved.
- Do not infer that a trigger can safely acquire a lower-ranked guard after its caller has already locked higher-ranked rows.
- Do not count source-event declaration mapping (40/40) as lock-path certification (0/40).
- Do not count candidate command boundary normalization (50/50) as lock certification (0/50).

### 3.3 F-03 evidence package and exit criteria

| Evidence ID | Required artifact / proof | Review owner(s) | Exit condition |
|---|---|---|---|
| F03-E01 | Frozen command/resource vocabulary and explicit source-of-truth hierarchy | Engineering + Database + Security | No conflicting candidate order remains unexplained; superseded text is clearly historical |
| F03-E02 | Per-command manifests for 50 application commands | Engineering + Database + QA | Exact read/write set, lock target, modes, order, same-rank key order, invariants, competing writers, retry and tests for every command |
| F03-E03 | Physical constraint and implicit-lock inventory | Database | FK, unique/exclusion indexes, trigger/cascade/deferred/function edges tied to exact schema/migration SHA |
| F03-E04 | Function and worker call graph | Engineering + Security + Operations | Caller, owner, SECURITY DEFINER/INVOKER, volatility, pinned search_path, EXECUTE ACL, transaction boundary and nested mutation paths recorded |
| F03-E05 | Global directed lock graph and cycle review | Database + independent Engineering reviewer | Every edge evidence-backed; graph acyclic; unresolved edges explicitly block certification |
| F03-E06 | Deterministic adversarial test suite and raw evidence | QA + Engineering + Security | Exact PostgreSQL major/schema SHA, schedule, lock diagnostics, SQLSTATE, winner/loser outcomes, invariant checks and repeatability retained |
| F03-E07 | Approved retry/timeout/deadlock semantics | Engineering + Security + PO where user-visible semantics change | No hidden retry, no duplicated side effect, idempotency preserved, bounded timeout/retry budgets approved |
| F03-E08 | Formal technical sign-off and synchronized SSOT | Engineering + Database + Security + QA | Lock graph, manifest, command contracts, physical schema, RTM, RAID, DGA and QA all reference the same approved revision |

**F-03 exit:** all F03-E01..E08 accepted; all 50 application commands technically certified or explicitly removed from frozen scope by approved change control; resolver paths separately certified where L05 applies; no unresolved cycle or implicit edge; required concurrency evidence exists. A static diagram alone cannot satisfy this exit.

## 4. F-04 — Eligibility-writer closure matrix

### 4.1 Known logical writer domains

The current writer matrix identifies candidate domains including account lifecycle, role grants/revocations/expiry, scope grants/delegation, T-14 capacity, project/session lifecycle, assignment/membership, location/team, instrument/version where selectors depend on them, unit/association/claim/inspection where selectors depend on them, async finalizers, notification policy publication/escalation, direct browser/API DML, SECURITY DEFINER helpers, triggers/cascades, imports/sync/repair, scheduled expiry and emergency mutation.

This list is a logical class inventory only. It is not an exhaustive list of deployed objects, jobs or principals.

### 4.2 Physical inventory evidence required

For the exact deployed schema/migration revision, a separately authorized read-only inventory must capture:
1. Schemas, tables, columns, constraints, indexes, triggers, trigger functions, policies, roles and grants.
2. Every PostgREST RPC and every reachable helper; owner, SECURITY DEFINER/INVOKER, volatility, pinned search_path, EXECUTE ACL and nested calls.
3. Scheduled jobs, queue workers, webhook/provider callbacks, imports, sync, backfills, support/admin scripts, repair/reconciliation and emergency procedures.
4. Principal/workload identity and transaction boundary for every writer.
5. Exact selector dependency columns/relations from the approved grammar, joined to every mutating entrypoint and implicit FK/trigger/helper edge.
6. Negative authorization evidence proving ordinary/browser roles cannot bypass reviewed wrappers.
7. A writer-by-writer evidence record: deployed name, source/migration SHA, principal, mutation set, first lock, L05/approved serialization acquisition point, lock order, retry behavior, bypass control, reviewer and artifact reference.

### 4.3 Writer certification record

| Certification field | Required value |
|---|---|
| Writer ID | Stable inventory ID; do not invent deployed object names |
| Physical entrypoint | Exact schema-qualified function/trigger/job/API/script name or explicit NOT APPLICABLE |
| Revision | Deployed migration/schema/source SHA |
| Principal | Exact login/workload/owner role and caller identity behavior |
| Mutation set | Exact relations/columns and indirect writes |
| Selector dependencies | Exact registered selector version and referenced fields |
| Transaction boundary | Actual transaction/finalizer boundary |
| Guard participation | Approved serialization key and acquisition point, or approved exclusion proof |
| Implicit edges | FK, unique, trigger, cascade, helper and deferred effects |
| Bypass evidence | ACL/RLS/REST negative proof and emergency-path controls |
| Verification | Adversarial schedule, raw logs, outcome and reviewer |
| Status | DISCOVERED / REVIEWED / CERTIFIED / EXCLUDED_BY_APPROVED_CHANGE; no implied promotion |

**F-04 exit:** selector grammar and per-event dependencies approved; physical writer universe complete for all dependency columns; every writer certified to participate or formally excluded; no bypass path; graph and test evidence reconciled. Current state remains 0 certified writers.

## 5. SES-001 — Packed-unit ABORT technical contract closure

### 5.1 Product semantics that must not change

- One inspection attempt is immutably bound to exactly one session.
- Return correction remains with the original Inspector in the original active session.
- ABORT is exceptional: exact Reviewer RETURN for an identified error, unit already packed/boxed and shipment-ready such that correction/reinspection is impracticable, Inspector submits reasoned request, and Admin/Korlap explicitly approves.
- Packing alone, generic incomplete/hanging work, or CMD-027 claim release does not qualify.
- Request alone does not change inspection state or release claim. Rejection leaves the attempt unresolved and correction path available.
- Approval transitions only the exact still-current returned revision to terminal ABORTED; requester and approver must be different principals.
- Preserve prior revisions, evidence metadata and audit history. ABORTED is not approval, completion, good/defective classification or print completion.
- Later session creates a new inspection_id; it never reactivates or rebinds the old attempt.
- CMD-013 FINAL_CLOSE cannot create, approve or bulk-apply ABORT; pending request and unresolved attempts block closure.

### 5.2 Technical decisions still required

| ID | Required technical decision/evidence | Accountable review | Status |
|---|---|---|---|
| SES-T01 | Assign exact command/API identities to request and approve/reject actions; do not invent CMD IDs or overload CMD-027 | Engineering + PO | OPEN |
| SES-T02 | Exact role, scope, account-state and requester/approver separation-of-duties matrix for Admin/Korlap | Security + PO | OPEN |
| SES-T03 | Accepted evidence proving the unit is already packed/boxed and shipment-ready, evidence custody, reviewer and anti-tamper/expiry rules | Operations + Institution + Security | OPEN |
| SES-T04 | Request binds to inspection_id, immutable session_id, exact submitted revision and exact Reviewer RETURN decision | Database + Engineering | OPEN |
| SES-T05 | At most one pending request; immutable terminal decision; history for rejected/approved requests; stale revision/CAS rejection | Database + Engineering | OPEN |
| SES-T06 | Atomic approval write set: decision, inspection ABORTED, conditional active-claim release, domain/audit event and idempotency result; rollback all on failure | Database + Engineering + Security | OPEN |
| SES-T07 | Exact lock order and race treatment against correction submit, review decision, claim release, evidence finalization and CMD-013 FINAL_CLOSE | Database + Engineering + QA | OPEN |
| SES-T08 | Physical FK/unique/check constraints, RLS, function owner/search_path/EXECUTE ACL and private evidence reference validation | Database + Security | OPEN |
| SES-T09 | QA mapping for request/reject/approve, wrong principal/scope, stale revision, no packed proof, idempotency, rollback and races | QA + Engineering | PLANNED / NOT EXECUTED |
| SES-T10 | Session reopen semantics after a prior ABORTED attempt; TC-SESSION-008 remains policy-blocked | PO + Operations | OPEN |

### 5.3 Command and data-model guardrails

- Request and decision are distinct protected actions. Do not assume one command can both request and approve.
- Do not reuse CMD-027; it is release-only. Do not assign the behavior to CMD-013 FINAL_CLOSE.
- Do not overload review_events for Admin/Korlap disposition; reviewer approval/return authority is a different domain.
- Do not add a table, column, enum, index or constraint by implication. Database must select and approve the physical representation against the canonical schema and table-count governance.
- Requester != approver is a server-enforced invariant, not a UI rule.
- ABORT approval must revalidate the exact current Reviewer-returned revision after serialization; stale approvals fail closed.
- Claim release is conditional and part of approval only. No release on request or rejection.
- Do not accept client-supplied actor, role, session, revision or evidence ownership as authority.
- Preserve append-only historical evidence; never rewrite old inspection.session_id or old evidence to fit a later session.

## 6. Cross-document synchronization required

After accountable technical decisions, update in one controlled documentation change set:
- Command contract catalogue and detailed CMD-026/027/013 contracts plus new request/decision command identities if approved.
- Physical schema/integrity specification, physical command crosswalk, RLS catalogue, permission registry and function-security/EXECUTE design.
- LOCK-MANIFEST-001, LOCK-GRAPH-001, LOCK-NORMALIZATION-001 and LPR resolution package.
- PRD/workflow/state model and Decision Register only if PO semantics change.
- QA TC-INS-DRAFT-021..027 and TC-SESSION-002..008, preserving stable IDs and PLANNED / NOT EXECUTED until execution.
- RTM-001, RAID-001, DGA-001, MIB-001 and IRG-001.
- IER-001 and final documentation closure audit.

No source of truth should claim technical closure until the same approved decision and evidence references are reflected consistently.

## 7. Gate and authorization disposition

| Gate | Current state | Exit requirement |
|---|---|---|
| F-03 global lock graph | OPEN / NOT PROVEN ACYCLIC | F03-E01..E08 complete and independently reviewed |
| F-04 eligibility writers | OPEN / 0 certified | Approved selector dependency map and complete physical writer/bypass evidence |
| F05-T1..T5 | OPEN candidate specifications | Technical/physical/security admission and T-10 institutional approval where required |
| SES-001 technical contract | OPEN | SES-T01..T10 resolved with approved command, security, physical, lock and QA artifacts |
| G9 scope freeze | NOT READY | All DGA blockers closed with evidence; exact immutable baseline and PO scope-freeze approval |
| G10 implementation | NOT ACTIVE | Separate G10 activation record after verified G9 |
| QA runtime | PLANNED / NOT EXECUTED | G10 active, approved isolated environment, exact schema/source SHA and recorded results |

**Final disposition:** PTCM-001 makes the remaining work explicit and testable but closes no technical blocker by itself. F-03 remains NOT PROVEN ACYCLIC; F-04 remains 0 writers certified; SES-001 remains PO-approved semantics with technical contract OPEN; G9 NOT READY; G10 NOT ACTIVE. No code, SQL, migration, grants/RLS, live database inspection, provider change, runtime test, deployment or production data mutation is performed or authorized by this document.

## 8. Change control

Any change to approved SES-001 semantics requires a new PO decision. Any institutional evidence/records/retention decision requires the authorized institutional owner. Technical approval requires accountable Engineering, Database, Security and QA review. Static inventories, candidate ranks, diagrams and planned tests are not certifications.


## 9. Post-PR #23 baseline reconciliation — 2026-11-25

PTCM-001 v0.1.1 is reviewed against `main` at `0db79d376face690b353d466a18129b6dd0ae5b2`, after PR #23 merged. Its referenced LOCK-GRAPH-001 baseline is v0.4.25. The underlying F-03/F-04/SES-001 dispositions are unchanged: F-03 NOT PROVEN ACYCLIC; F-04 0 writers certified; SES-001 technical contract OPEN; QA PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE. This version update reconciles document provenance only and does not close evidence requirements or authorize implementation.
