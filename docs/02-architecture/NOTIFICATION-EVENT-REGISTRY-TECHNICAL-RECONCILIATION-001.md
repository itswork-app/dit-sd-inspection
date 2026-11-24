# Notification Event Registry — Technical Reconciliation

**Document ID:** NLA-EVENT-TECH-RECON-001  
**Version:** 0.1.0  
**Status:** STATIC TECHNICAL RECONCILIATION — PARTIAL; CMD-002/003 REVIEWED, BOTH UNRESOLVED / NOT ENABLED  
**Date:** 2026-11-24  
**Branch:** `docs/notification-resolver-lock-closure`  
**Scope:** First technical pass for NREG-001 (`account.approved`) and NREG-002 (`account.rejected`)  
**Authority:** AGENTS.md v1.2.2; Decision Register; CMD-001–054 Cross-Command Reconciliation; CMD-001–010 Detailed Contract Review; PostgreSQL Command Contract Catalogue; Command Physical Object Crosswalk; LOCK-NORMALIZATION-001; NLA-001; NLA-L05-TDR-001; L05 Eligibility-Writer Participation Matrix; POQ-04.

## 1. Purpose and boundary

This document records a static, evidence-bounded technical pass over the first two PO-approved event candidates. It is not an executable event contract, source-code inspection, live database inspection, or technical approval.

The following remain prohibited until G10 activation: source code, SQL, migrations, grants/revokes, RLS changes, live database operations, provider setup, deployment and production/staging mutation. No event is enabled by this document.

The registry's seven status dimensions remain controlling. Both rows remain:

- PO intent: `APPROVED_FOR_SPECIFICATION_ONLY`
- Canonical contract: `UNRESOLVED`
- Recipient mapping: `UNRESOLVED`
- Selector: `UNRESOLVED`
- Dispatch profile: `UNRESOLVED`
- Technical review: `PARTIAL_STATIC_REVIEW` (this document only; not technical approval)
- Publication: `NOT_ENABLED`

## 2. Evidence reviewed

| Source | Static evidence used | Limitation |
|---|---|---|
| CMD-001–010 Detailed Contract Review v0.3.4 | CMD-002/003 candidate request, response, authorization, read/write sets, transaction and audit proposals | Engineering proposal; no approved executable route/RPC/function |
| PostgreSQL Command Contract Catalogue v0.4.8 | CMD-002/003 logical event names, permission family, target-account scope and candidate transaction semantics | Permission registry and command contracts remain unapproved for execution |
| Command Physical Object Crosswalk | CMD-002/003 proposed `app_users`, `account_decisions`, `idempotency_records`, `audit_events` dependencies | Proposed physical model, not live schema proof |
| Physical Database Schema and Integrity Specification | `app_users` candidate fields include `id`, `auth_user_id`, `approval_status`, `account_status`; `account_decisions` is proposed append-only with user, decision, actor, reason and time | Exact constraints, state model, deployed columns and ACL are unverified |
| LOCK-NORMALIZATION-001 v0.1.1 | Candidate L05 and lock-order paths for CMD-002/003 | Candidate order only; no admitted rank or certified path |
| L05 Eligibility-Writer Participation Matrix | CMD-002/003 are known account/login-eligibility writer paths; admin, support, disable/suspend/reactivate, auth reconciliation and other non-command writers are incomplete | No complete physical writer inventory; zero writers certified to participate |
| NLA-001 and NLA-L05-TDR-001 | POQ-01/04 snapshot and suppression invariants; proposed outbox and L05 protocol | Snapshot relation/header NOT ADMITTED; L05 and transaction isolation not technically approved |
| Decision Register / POQ-04 | Approved pre-mutation candidate snapshot and post-mutation suppression semantics | Event-specific eligibility mapping for pending account transitions is not yet resolved |

## 3. Reconciliation findings — CMD-002 / NREG-001

### 3.1 Producer and transaction boundary

**Static candidate:** CMD-002 `approve-account` is the producer path for the logical candidate `account.approved`.

The detailed contract proposes one database command transaction that conditionally changes the target account's approval state, appends an immutable account decision, records idempotency and appends the canonical audit/domain fact. The catalogue and cross-command reconciliation identify the event as part of CMD-002's transaction; the command does not represent an asynchronous post-commit event or an external provider callback.

**Not proven:** the actual producer function, physical event writer, exact event envelope/schema version, exact canonical event storage representation, and transaction behavior in a deployed database. The proposed use of `audit_events.id` as `notification_outbox.source_event_id` in NLA-001 does not by itself prove that every audit row is a canonical notification source event.

### 3.2 Candidate mutation and write set

Proposed source objects:

- Read: target `app_users`; actor `app_users` and effective authorization grants; idempotency record.
- Write: target `app_users.approval_status` and decision metadata; append `account_decisions`; `idempotency_records`; `audit_events`.

The candidate atomic unit is account transition + immutable decision + idempotency result + required audit/event. If a future enabled notification rule requires an outbox and immutable candidate snapshot, those records must join this same transaction under POQ-01/04. Neither outbox nor candidate-snapshot physical relation is currently admitted.

### 3.3 Candidate lock path

LOCK-NORMALIZATION-001 records this candidate order:

1. L00 idempotency arbitration.
2. L05 audience guard before mutable eligibility/domain locks, if this event is admitted for notification matching.
3. L10 capacity rows only if the account transition changes the approved T-14 qualifying-Inspector population.
4. L15 actor and target principals in stable UUID order.
5. L16 actor role-grant rows; L17 applicable actor scope-grant rows; conditional L18 authorization catalogue rows.
6. Target account transition and append-only decision/audit facts at the relevant terminal rank.

This is a normalization proposal, not an approved lock plan. The exact L05 key, L05/L10 order, account row lock mode, decision uniqueness arbiter, FK/trigger edges and opposing-writer graph remain unapproved. The detailed command review's simpler target-row locking statement must be reconciled to this normalized global order before certification.

### 3.4 Recipient and selector

The command contract's `target_user_id` and proposed `account_decisions.user_id` identify the conceptual subject of the decision. They do **not** establish an approved notification participant field or selector expression.

The only admissible product intent is the applicant/requesting account as a conceptual candidate question. No event payload key, recipient UUID path, selector clause, role, channel, or account-request table is admitted. `EVENT_PARTICIPANT` is a review-candidate selector concept only and remains subject to technical approval.

### 3.5 Dispatch and POQ-04 application

The target may only enter the immutable event-time candidate set if an exact future-approved selector selects it from trusted pre-mutation state at the captured `audience_evaluated_at`. The actor is not implicitly included.

Dispatch-time account/channel/consent and mandatory security checks may suppress an existing candidate but may not add another recipient. For account-state transitions, the approved POQ-04 rule requires suppression while the selected account is not enabled; a later retry after reactivation may only reuse the original candidate.

**Open semantic application:** CMD-002 changes the target from a pending/request state toward approval. The current documents do not precisely separate (a) whether the pending applicant is eligible to be snapshotted as the event participant before mutation from (b) whether account-enabled status is a dispatch-time suppression predicate. If enabled status is applied as a pre-mutation candidate gate, the applicant may be excluded before an approval event can notify them. The exact split must be resolved in the selector/dispatch contract without changing POQ-04 or widening the audience.

### 3.6 Deduplication and race handling

The source command is idempotent by actor + command + target/resource + opaque key in the proposal. Approval/rejection race is expected to be resolved by a conditional target-state transition and one terminal decision. NLA-001 proposes unique outbox fan-out by source event + policy version and unique inbox rows by outbox + recipient.

**Unresolved:** the exact unique constraint or canonical decision identity enforcing one terminal account decision; exact event ID; whether an audit/event insert is guaranteed exactly once under command replay; and the exact notification deduplication key. Do not substitute the proposed outbox uniqueness constraint for the missing source-decision invariant.

## 4. Reconciliation findings — CMD-003 / NREG-002

### 4.1 Producer and transaction boundary

**Static candidate:** CMD-003 `reject-account` is the producer path for the logical candidate `account.rejected`.

The proposed transaction conditionally transitions the target account to rejected, appends an immutable account decision, persists idempotency and appends the canonical event/audit fact atomically. Rejection is not deletion.

**Not proven:** the actual producer function, event envelope/schema version, physical canonical event representation, deployed transaction behavior, and whether any account/auth synchronization occurs inside or outside the transaction.

### 4.2 Candidate mutation and write set

Proposed source objects:

- Read: target `app_users`; actor authorization; idempotency record.
- Write: target `app_users.approval_status`; append `account_decisions`; `idempotency_records`; `audit_events`.

No role, scope or permission revocation is implied by rejection unless a separately approved lifecycle rule explicitly requires it. No such cascade may be invented by the notification resolver.

### 4.3 Candidate lock path

The normalized candidate order is the same account-transition protocol as CMD-002: L00 → candidate L05 → conditional L10 if T-14 eligibility changes → L15 principals sorted → L16/L17/L18 authorization reads/locks as applicable → target account transition → append-only decision/event facts.

This order is not technically certified. CMD-002 and CMD-003 must share the same target-account arbitration and decision uniqueness protocol so concurrent approve/reject cannot commit two terminal outcomes.

### 4.4 Recipient, selector and dispatch

The applicant/target account is a conceptual recipient candidate only. No physical event participant field, selector, role or channel is approved.

Under POQ-04, the target is eligible for snapshot only if the exact selector independently selects it against the serialized pre-rejection state. If included, dispatch-time account-state validation may suppress while the account is not enabled. Reactivation may only make the same original candidate eligible for a later retry; it cannot create a new recipient or widen the candidate set.

**Open semantic application:** the documents do not yet state whether a pending applicant is snapshotted as an event participant independently of the enabled-account dispatch gate. This must be explicit to avoid the rejection notice being removed by an over-broad pre-transition account-state filter.

### 4.5 Deduplication and race handling

The same unresolved source decision identity and idempotency concerns as CMD-002 apply. The reject command's conditional state transition is the proposed race arbiter against CMD-002 and duplicate CMD-003 requests. Exact uniqueness, version/CAS strategy, and source-event/outbox deduplication remain unproven.

## 5. Cross-command findings and blockers

| ID | Finding | Impact | Required evidence / owner |
|---|---|---|---|
| NER-TR-01 | Account request lifecycle has no dedicated request entity in the current proposed physical inventory; CMD-001 ownership in `app_users` is unresolved | Applicant principal and request history provenance cannot be assumed from a notification label | PO + Engineering + Database: canonical Auth signup/request lifecycle and stable request-to-user relation |
| NER-TR-02 | `app_users` candidate `approval_status` and `account_status` exist in proposed schema vocabulary, but exact eligibility predicate/state transition table is incomplete | Snapshot eligibility and dispatch suppression can be conflated | PO + Engineering + Security: approved state machine and separate snapshot/dispatch predicates |
| NER-TR-03 | `account_decisions` is proposed append-only, but terminal uniqueness, exact decision key and concurrency token are unresolved | CMD-002/003 race and event dedup cannot be certified | Database: exact unique/exclusion/CAS strategy and FK/trigger graph |
| NER-TR-04 | L05 account writers include CMD-002/003 but non-command account disable/suspend/reactivate, support/admin and auth reconciliation paths are incomplete | Event-time audience serialization cannot be proven | Engineering + Security + Operations: complete writer entrypoint/owner/table/column/ACL inventory |
| NER-TR-05 | T-14 account eligibility effect and L05/L10 order are conditional and unresolved | A lock path may be incomplete or inverted if account transition changes Inspector capacity eligibility | Engineering + Database: prove whether account state is in the T-14 predicate; then approve one global order |
| NER-TR-06 | Event names are logical catalogue/audit declarations; exact canonical event envelope/version/participant projection is absent | Registry cannot bind event token to a trusted physical producer | Engineering + Database: exact event schema/version, source ID, event writer and transaction-boundary evidence |
| NER-TR-07 | POQ-04 pending-applicant semantics are not mapped explicitly to CMD-002/003 | A pre-transition account-enabled filter could exclude the intended applicant; dispatch suppression could be misapplied | PO + Security: explicitly separate participant selection from account/channel dispatch suppression while preserving no-widening |
| NER-TR-08 | Permission registry and command-specific approval grants remain draft; L05 is only a candidate technical mechanism | Neither source command nor audience resolver is executable/authorized | Security: exact actor authority, function owner/search_path/EXECUTE ACL, RLS and caller-JWT evidence |
| NER-TR-09 | Snapshot relation/header, policy selector grammar and exact FK/trigger/helper lock graph are not admitted | Atomic immutable recipient snapshot cannot be proven | Engineering + Database + Security: approved physical model, selector dependency map, writer-complete graph and runtime evidence after G10 |

## 6. Admission decision for the first two registry rows

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-001 | `account.approved` | CMD-002 candidate transaction identified in static command docs; deployed producer/event envelope not proven | Conceptual target only; no admitted participant field or selector | Candidate atomic command facts identified; decision uniqueness, event identity and outbox/snapshot key unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |
| NREG-002 | `account.rejected` | CMD-003 candidate transaction identified in static command docs; deployed producer/event envelope not proven | Conceptual target only; no admitted participant field or selector | Candidate atomic command facts identified; decision uniqueness, event identity and outbox/snapshot key unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

No event is technically admitted. No recipient, role, selector, channel, dispatch profile, schema field, function, grant, migration or runtime behavior is approved by this reconciliation.

## 7. Evidence required to close CMD-002/003

1. Approved account lifecycle state machine, including Auth identity creation, request ownership, approval/rejection eligibility, disable/suspend/reactivate behavior and the exact distinction between `approval_status` and `account_status`.
2. Approved canonical account-decision contract: terminal uniqueness, decision identity, concurrency token/CAS predicate, reason bounds, actor/target SoD and append-only history.
3. Exact event producer contract: canonical token, event schema/version, source-event identity, participant projection, transaction owner and proof that mutation + decision + event + audit + idempotency + future outbox/snapshot commit atomically.
4. Explicit PO/Security mapping of POQ-04 pending-applicant snapshot eligibility versus dispatch-time enabled-account suppression for both approval and rejection.
5. Complete account eligibility writer inventory, including support/admin, disable/suspend/reactivate, Auth reconciliation, import, repair, trigger, cascade and direct-DML paths; exact owner, table/column, transaction and L05 participation evidence.
6. Proof whether CMD-002/003 change the T-14 qualifying-Inspector predicate; if so, approved L05/L10 ordering and complete capacity-writer participation.
7. Approved selector grammar and exact dependencies, then a writer-complete dependency map; no guessed event JSON paths.
8. Security/Database approval of L05 key allocation, isolation/snapshot protocol, lock compatibility, FK/unique/trigger/helper graph, and authenticated RPC/worker ACL.
9. Approved source event/outbox/candidate snapshot uniqueness and retry semantics; test specifications linked to TC-NOTIF-073/074 and relevant command, concurrency and function-security cases. Execution remains prohibited until G10 activation.

## 8. Current gate and work status

- CMD-002 / CMD-003: static producer and candidate transaction review completed; technical admission remains OPEN.
- NREG-001 / NREG-002: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- L05: candidate only; not technically approved.
- Account eligibility writer coverage: PARTIAL; non-command writer inventory incomplete; 0 writers certified.
- Resolver certification: 0/40.
- Application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header: NOT ADMITTED.
- Tests: PLANNED / NOT EXECUTED.
- G9: NOT READY. G10: NOT ACTIVE.

**Disposition:** Continue the same evidence-bounded reconciliation with CMD-005 and CMD-010/013 only after the CMD-002/003 findings are linked to the registry and cross-document pointers. No code or database work is authorized.
