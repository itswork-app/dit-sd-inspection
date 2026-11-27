# Inspection Lifecycle, Unit Claims, Review, and Revision

**Status:** Draft v0.2.0 — requires Product Owner validation  
**Package:** C — Functional and Operational Design

## 1. Scope

Defines the lifecycle of an individual physical unit from claim through inspection, evidence capture, submission, review, approval, PDF generation, printing, and completion.

## 2. Proposed state model

Inspection states:

- `DRAFT`: claimed or started; editable by assigned Inspector.
- `SUBMITTED`: Inspector submitted; locked from ordinary Inspector edits.
- `RETURNED`: Reviewer returned with reason; correction required.
- `APPROVED`: Reviewer approved a specific immutable submission version.
- `REOPENED`: authorized reopening of an approved inspection; creates a new editable revision context.

Document processing is tracked separately:
- PDF: `NOT_GENERATED`, `GENERATED`, `SUPERSEDED`.
- Print: zero or more immutable print events, each with sequence number/time/operator.
- Unit completion is derived only when approved + final PDF generated + print event recorded.

## 3. Claim rules

- Inspector may claim only an available unit in an active session and explicitly assigned operational assignment.
- Claim acquisition must be atomic, using a database transaction/unique active-claim constraint or equivalent serialization mechanism.
- Two Inspectors cannot hold active claims for the same unit simultaneously.
- Inspector may manually release a claim while in an editable draft state.
- Claims expire after a configurable timeout. Expiry must not discard draft data or uploaded media.
- If a unit is under review or approved, ordinary release is prohibited.
- Claim expiry must not erase local unsynchronized work. The server must preserve the draft and flag claim ownership/expiry for controlled recovery.

## 4. Inspection capture

Each inspection binds to:
- project/session/assignment;
- unit identity and serial number;
- instrument type and immutable instrument configuration version;
- checklist version;
- required evidence/photo slot version;
- Inspector identity and active role.

Checklist answers must be explicit. A UI default checkmark must never be treated as proof that the Inspector verified the item. *(Superseded for MVP `PASS_FAIL`/`YES_NO` field checklists by `PO-2026-11-27-CHECKLIST-DEFAULT-OK-001` Option 1B in `DECISION-REGISTER.md`, with explicit Inspector confirmation on submit and mandatory defect explanation + photo/video evidence under `PO-2026-11-27-VIDEO-EVIDENCE-001` Option 2A.)*

For each checklist item:
- record answer and actor/time;
- support only configured response values;
- non-compliance requires an explanation and configured evidence where applicable;
- N/A or NOT_TESTABLE may be used only if enabled for that item and accompanied by a reason;
- authorized evidence waiver requires actor, reason, and audit event.

Submission is blocked if required checklist items, required photos, serial identity, or required notes are incomplete or if unresolved synchronization conflicts exist.

## 5. Submission and review

1. Inspector validates the inspection.
2. Backend checks all required data, assignment scope, claim ownership, configuration version, and sync/conflict state.
3. Submission creates an immutable submission version and locks that version.
4. Assigned Reviewer sees the submitted version.
5. Reviewer either approves or returns it with a mandatory reason.
6. Reviewer cannot approve an inspection created/submitted by the same user.
7. A returned inspection is routed back to the Inspector for correction; Reviewer does not directly edit Inspector responses.
8. Inspector creates a new revision and resubmits. Prior versions and reviewer decisions remain accessible.

## 6. Reopen after approval

- Approved inspection can be reopened only by Super Admin or Admin with explicit `inspection.reopen` permission.
- Reopen requires a reason.
- Reopen creates a new revision; it does not mutate the approved version.
- Actor, active role, timestamp, prior approved version, reason, and resulting revision are audited.
- Existing PDFs and print events remain historical artifacts and are marked superseded where appropriate; they are not deleted.

## 7. Concurrency and idempotency

- Claim acquisition and submission must be transaction-safe.
- Repeated submit requests with the same idempotency key must not create duplicate versions.
- Review actions must be conditional on the expected current state/version.
- A stale client must receive a conflict response and reconcile; it must not overwrite newer server state silently.

## 8. Proposed entities

- `inspections`
- `inspection_revisions`
- `inspection_answers`
- `inspection_evidence`
- `inspection_claims`
- `inspection_reviews`
- `inspection_events`
- `idempotency_records`

## 9. Acceptance criteria

- Duplicate simultaneous claims are impossible.
- Draft and media survive manual release, timeout, refresh, and reconnect.
- No submission bypasses required checklist/evidence validation.
- Reviewer cannot edit submitted answers.
- Inspector cannot self-review or self-approve.
- Return/correction/resubmission preserves complete version history.
- Reopen requires permission and reason, preserving approved versions.
- Duplicate network retries do not duplicate submissions or review decisions.

## 10. Open decisions

- Exact claim timeout duration and warning period.
- Whether more than one Inspector may collaborate on one unit (current design assumes one active claim/owner).
- Whether a reviewer may delegate a review to another assigned Reviewer.
- Exact answer value set and per-checklist-item validation schema.


## T-16 — Serial identity and evidence history (PO-approved option B, 2026-11-24)

A normalized serial is unique within its instrument type across all projects. The uniqueness key excludes project ID; the same serial string may exist for a different instrument type. Claiming a unit resolves the canonical instrument-type identity while all inspection access remains constrained by project, session, assignment and role scope. A same-type duplicate detected across projects is a controlled conflict requiring authorized resolution, reason and audit; do not silently create a second canonical unit, merge records or erase historical inspections.

Every evidence item remains linked to the exact immutable inspection revision and instrument version. Preserve its original metadata, checksum, uploader, capture/upload timestamps and immutable storage object identity. Do not overwrite finalized evidence; replacement creates a new evidence record and audit event. Historical revision/evidence relationships remain readable and unchanged.

## Product Owner decision update — mandatory claim and canonical unit (2026-11-24)

- The canonical physical unit key is (instrument_type, serial_normalized) and is global across projects. Project/session/assignment authorization remains independently scoped; canonical identity does not grant cross-project access.
- Every normal inspection workflow requires a valid active claim before draft mutation, evidence finalization, submission or review progression. Claim ownership must bind to the exact canonical unit and applicable project association/assignment context.
- No implicit or client-selected bypass is permitted. Any administrative correction or historical migration exception must use a separately permissioned server-side path with explicit reason, actor, scope and append-only audit evidence. The exception must not create a second active claim or silently rewrite historical ownership.
- Claim expiry/release prevents further normal writes until a valid claim is reacquired through the approved recovery path; preserve existing draft and evidence for authorized recovery.
- Same-type serial collisions across projects are controlled conflicts requiring authorized review, reason and audit. Never silently merge units, overwrite records or discard inspection history. Different instrument types may reuse the same normalized serial.

**Approval boundary:** LPR-02/LPR-03 are PO-approved product semantics. Canonicalization algorithm, unique constraints, lock primitives, exact exception permission, command contracts and concurrency tests remain subject to Engineering/Security review. No implementation or test execution is claimed.
