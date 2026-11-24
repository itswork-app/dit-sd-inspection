# Notification Event Registry — Technical Reconciliation

**Document ID:** NLA-EVENT-TECH-RECON-001  
**Version:** 0.1.2  
**Status:** STATIC TECHNICAL RECONCILIATION — PARTIAL; CMD-002/003/005/010/013 REVIEWED, ALL PARTIAL / UNRESOLVED / NOT ENABLED  
**Date:** 2026-11-24  
**Branch:** `docs/notification-resolver-lock-closure`  
**Scope:** First technical pass for NREG-001 (`account.approved`) and NREG-002 (`account.rejected`)  
**Authority:** AGENTS.md v1.2.2; Decision Register; CMD-001–054 Cross-Command Reconciliation; CMD-001–010 Detailed Contract Review; PostgreSQL Command Contract Catalogue; Command Physical Object Crosswalk; LOCK-NORMALIZATION-001; NLA-001; NLA-L05-TDR-001; L05 Eligibility-Writer Participation Matrix; POQ-04.

## 1. Purpose and boundary

This document records a static, evidence-bounded technical pass over the first two PO-approved event candidates. It is not an executable event contract, source-code inspection, live database inspection, or technical approval.

The following remain prohibited until G10 activation: source code, SQL, migrations, grants/revokes, RLS changes, live database operations, provider setup, deployment and production/staging mutation. No event is enabled by this document.

The registry's seven status dimensions remain controlling. All five reviewed rows remain:

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
| L05 Source-Event Path Mapping v0.1.0 | CMD-002/003 source command transaction boundary, candidate lock sequence and required L05 insertion point | Candidate map copied from command manifest; source-code/function call-graph evidence and post-L05 order remain absent |
| L05 Eligibility-Writer Participation Matrix | CMD-002/003 are known account/login-eligibility writer paths; admin, support, disable/suspend/reactivate, auth reconciliation and other non-command writers are incomplete | No complete physical writer inventory; zero writers certified to participate |
| NLA-001 and NLA-L05-TDR-001 | POQ-01/04 snapshot and suppression invariants; proposed outbox and L05 protocol | Snapshot relation/header NOT ADMITTED; L05 and transaction isolation not technically approved |
| Decision Register / POQ-04 | Approved pre-mutation candidate snapshot and post-mutation suppression semantics | Event-specific eligibility mapping for pending account transitions is not yet resolved |

## 3. Reconciliation findings — CMD-002 / NREG-001

### 3.1 Producer and transaction boundary

**Static candidate:** CMD-002 `approve-account` is the producer path for the logical candidate `account.approved`.

The detailed contract and L05 source-event path map identify one source command transaction: conditional target-account approval, immutable account decision, idempotency result, canonical event/audit fact, and (only after a future event is enabled and the physical model is admitted) outbox plus immutable candidate snapshot. This is not an asynchronous post-commit producer or provider callback. The path map explicitly requires those facts to commit atomically.

**Not proven:** the actual producer function, physical event writer, exact event envelope/schema version, exact canonical event storage representation, and transaction behavior in a deployed database. The proposed use of `audit_events.id` as `notification_outbox.source_event_id` in NLA-001 does not by itself prove that every audit row is a canonical notification source event.

### 3.2 Candidate mutation and write set

Proposed source objects:

- Read: target `app_users`; actor `app_users` and effective authorization grants; idempotency record.
- Write: target `app_users.approval_status` and decision metadata; append `account_decisions`; `idempotency_records`; `audit_events`.

The candidate atomic unit is account transition + immutable decision + idempotency result + required audit/event. If a future enabled notification rule requires an outbox and immutable candidate snapshot, those records must join this same transaction under POQ-01/04. Neither outbox nor candidate-snapshot physical relation is currently admitted.

### 3.3 Candidate lock path

LOCK-NORMALIZATION-001 records this candidate order:

1. L00 idempotency arbitration.
2. Candidate L05 audience guard before the first mutable lock, if this event is admitted for notification matching.
3. Conditional L10 capacity rows only if the account transition changes login-enabled eligibility in the approved T-14 qualifying-Inspector predicate; affected project set must be stable and ordered.
4. L15 actor and target principals in stable UUID order.
5. L16 actor role-grant rows; L17 applicable actor scope-grant rows; conditional L18 authorization catalogue rows.
6. Target account transition and append-only decision/audit facts at the relevant terminal rank.

The L05 source-event path map independently records the same candidate prefix and CMD-002 transaction boundary. This is a normalization proposal, not an approved lock plan. The exact L05 key, L05/L10 order, account row lock mode, decision uniqueness arbiter, FK/trigger edges and opposing-writer graph remain unapproved. The detailed command review's simpler target-row locking statement must be reconciled to this normalized global order before certification.

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

The proposed source command transaction conditionally transitions the target account to rejected, appends an immutable account decision, persists idempotency and appends the canonical event/audit fact atomically; the L05 source-event path map also places any future outbox and immutable candidate snapshot in this same transaction. Rejection is not deletion.

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


## 9. Reconciliation findings — CMD-005 / NREG-003

### 9.1 Producer and transaction boundary

**Static candidate:** CMD-005 `revoke-role` is the source command path for `role.revoked`. The L05 source-event path map records a source command transaction in which the role grant is ended, the canonical event/audit fact and idempotency result are appended, and (only after a future event is enabled and the physical model is admitted) the outbox and immutable candidate snapshot commit atomically. This is not an asynchronous provider event.

The exact deployed producer/function, canonical event envelope/schema version, physical event identity and source-code call graph are not proven. The audit event catalogue lists `role.revoked`, but that declaration is not proof of a stable notification contract.

### 9.2 Candidate mutation and write set

Proposed source objects:

- Read: target `user_roles` grant; actor authorization and effective delegation/revocation ceiling; role catalogue; `project_capacity_settings` and qualifying Inspector count where applicable; idempotency record.
- Write: target `user_roles.status/valid_until` using a canonical revocation representation still to be selected; `idempotency_records`; append-only `audit_events`.
- Preserve the original role-grant history; do not delete the row.

The physical schema proposal lists `user_roles` fields `user_id`, `role_id`, `valid_from`, `valid_until`, `status`, `granted_by`, `reason`. It does not list `row_version`, although the detailed CMD-005 request currently carries `expected_version`. This mismatch blocks an executable compare-and-swap contract. Either the approved physical schema must define a concurrency token and increment rule, or the request field must be removed through controlled contract reconciliation; do not assume `updated_at` or invent a column.

### 9.3 Candidate lock path and competing writers

The normalized candidate sequence is:

1. L00 idempotency arbitration.
2. Candidate L05 audience guard before the first mutable lock, if the event is admitted for notification matching.
3. Conditional L10 capacity serialization if the revoked grant reduces the T-14 qualifying-Inspector population.
4. L15 actor and target principals in stable UUID order.
5. L16 actor revocation-authority rows and exact target `user_roles` grant in deterministic order.
6. L17 applicable delegation/scope rows; conditional L18 role/permission catalogue references if mutable.
7. Guarded target grant transition and append-only audit/event facts.

This is a candidate order only. L05/L10 compatibility, exact lock modes, principal/grant lock set, FK/trigger/helper edges and acyclicity are not certified. The source map says L05 must precede the first mutable lock; mechanically adding L05 does not repair any existing later-rank inversion.

Known competing writers include CMD-004 grant-role, concurrent CMD-005 revoke, CMD-014/015 assignment eligibility changes, CMD-016 capacity changes, account suspension/disablement, and non-command role expiry/renewal/delegation maintenance, import/synchronization and admin repair. The writer matrix explicitly marks the non-command paths and direct-DML/bypass evidence incomplete.

### 9.4 Recipient, selector and POQ-04 dispatch semantics

The revoked target is a conceptual candidate only. Under POQ-04, evaluate the exact approved selector against serialized pre-revoke role/scope state at the one captured `audience_evaluated_at`. Include the target only if the selector independently selects and pre-mutation eligibility holds. The actor is never automatically appended; for self-revoke, actor inclusion occurs only if the exact selector independently selects the actor under pre-revoke eligibility.

After commit, current role/scope and mandatory security revalidation may suppress the captured candidate because the revocation may have invalidated the qualification that selected it. This is a separate dispatch decision and must not erase or rewrite the immutable candidate snapshot. A notification does not preserve access to the revoked resource and cannot grant access to any source resource.

No event participant field, role ID, scope reference, selector clause, dispatch profile, channel or message payload is approved. The command's `user_role_id` is a grant identifier; it does not alone prove the trusted target-principal projection for the event contract.

### 9.5 Deduplication, replay and state races

The command proposal requires an idempotent guarded transition and a stable no-op/state outcome for an already revoked or expired grant; it must not emit a duplicate success event. The candidate source dedup boundary is therefore tied to the one successful role transition, not to every retry or audit attempt.

Unresolved: exact revocation representation/effective timestamp; whether expired grants can be explicitly revoked; unique transition/event identity; source-event ID; whether event append is guarded by the same state transition; candidate snapshot/outbox uniqueness; and handling of a grant renewed/replaced concurrently with a revoke. The current `expected_version` field has no matching physical version token, so stale-write prevention is not proven.

### 9.6 Additional blockers

| ID | Finding | Impact | Required evidence / owner |
|---|---|---|---|
| NER-TR-10 | `user_roles.expected_version` has no proposed physical `row_version` | Stale concurrent revocation cannot be specified as a physical CAS contract | Engineering + Database: approved token/increment or remove request field under change control |
| NER-TR-11 | Exact revocation representation and effective-time semantics are open | Selector pre-state and dispatch current-scope checks cannot be bound to an exact role validity predicate | PO + Engineering + Security: status/valid_until transition and effective-time contract |
| NER-TR-12 | Last-admin/recovery protection and revocation delegation ceiling are not approved | Role revocation authority and recovery safety are not executable | PO + Security/institutional authority: exact grantor ceiling, SoD and last-admin recovery policy |
| NER-TR-13 | T-14 capacity effect is conditional for Inspector role revocation | Missing L10 participation can corrupt the qualifying population under concurrent grant/assignment/cap operations | Engineering + Database: prove predicate impact and approve common L05/L10 order |
| NER-TR-14 | Non-command role expiry/renewal/delegation, import, sync, repair and privileged bypass writers remain incomplete | L05 writer-completeness cannot be certified | Engineering + Security + Operations: exact entrypoint/table/column/owner/ACL and lock participation inventory |
| NER-TR-15 | `user_role_id` does not by itself define an approved target participant field | Recipient selector may bind the wrong identity or silently append target/actor | Engineering + Security + PO if product semantics change: trusted event participant projection and selector review |

### 9.7 Admission decision

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-003 | `role.revoked` | CMD-005 source command transaction identified statically; deployed producer/event envelope not proven | Revoked target is only a conceptual candidate; exact selector and target projection not admitted; actor never implicit | Atomic command boundary proposed; `expected_version` has no physical token; transition identity and snapshot/outbox dedup unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 10. Evidence required to close CMD-005

1. Exact canonical `role.revoked` event schema/version, source ID, trusted target participant projection and transaction producer proof.
2. Approved role-grant lifecycle: active/expired/revoked states, effective interval, canonical revocation write, expected-version/CAS resolution and stable duplicate/no-op behavior.
3. Approved revocation authority, grantor ceiling, SoD and last-admin/recovery rule.
4. POQ-04 event-time selector and dispatch suppression profile, including target and self-revoke actor cases; no implicit participant append.
5. Complete L05/L10 writer inventory for role, account and assignment/capacity eligibility, including non-command expiry/renewal/delegation, import, sync, admin repair, trigger and direct-DML paths.
6. Engineering/Database/Security approval of L05/L10 order, exact PostgreSQL lock modes, role/scope/parent/FK/unique/trigger/helper graph, function owner/search_path/EXECUTE ACL and authenticated caller-JWT path.
7. Exact terminal transition/event/outbox/snapshot dedup keys and immutable retry checkpoint; TC-NOTIF-077/078 and command/security concurrency tests specified and later executed only after G10 activation.

## 11. Updated gate and work status

- CMD-002/003 and CMD-005: partial static producer/transaction review completed; technical admission remains OPEN.
- NREG-001/002/003: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- L05/L10: candidate order only; not technically approved.
- Eligibility writer coverage: PARTIAL; non-command writers and bypass paths incomplete; 0 writers certified.
- Resolver certification: 0/40. Application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC. Candidate snapshot relation/header: NOT ADMITTED.
- Tests: PLANNED / NOT EXECUTED. G9 NOT READY. G10 NOT ACTIVE.

**Disposition:** Continue with CMD-010 and exact final CMD-013 `session.closed` next. CMD-004 remains an unresolved composite notification declaration and is not a PO-approved candidate; it must not be silently added to the event registry.


## 12. Reconciliation findings — CMD-010 / NREG-004

### 12.1 Producer and transaction boundary

**Static candidate:** CMD-010 `close-project` is the source command path for `project.closed`. The event must represent the committed transition of the project to CLOSED, not a preflight, close request, audit-only attempt or partial dependency check. The L05 source-event path map records a source command transaction in which project state, canonical event/audit, idempotency and (only after future event admission and physical model approval) outbox plus immutable candidate snapshot commit atomically.

The actual producer/function, canonical event envelope/schema version, event identity and deployed transaction are not proven. The command contract itself says no notification side effect exists unless separately modeled through a transactional outbox.

### 12.2 Candidate mutation, closure gates and physical concurrency

Proposed write set: `projects.status/closed_at/version`, `idempotency_records`, `audit_events`. The proposed read set spans project-scoped sessions, assignments/members, inspections/revisions/review events, evidence finalization, documents, print batches/events, target/actual reconciliation, sync conflicts, actor authorization and any approved legal/institutional hold model. The exact dependency tables and predicates are not enumerated or approved.

The closure dependency graph is open. Candidate blockers in the detailed review include non-closed sessions, active assignments/claims, in-flight inspections, pending evidence/document finalizers, unresolved print batches, required document issuance/signature, actual-vs-target reconciliation, pending sync conflicts and legal/institutional holds. These are review candidates, not a final closure checklist. Closure must not cascade-delete history or imply records disposition.

The physical project summary lacks a proven row-version/CAS field although CMD-010 carries `expected_version`. The exact version token, increment rule, lock mode and blocker predicate are unresolved.

### 12.3 Candidate lock path and competing writers

Candidate source order from the normalized manifest is L00 → candidate L05 → conditional L10 if closure changes T-14 eligibility → L15 actor → L16/L17 project-close authority → conditional L18 catalogue → L30 project parent fence (candidate `FOR NO KEY UPDATE`) → evaluate the complete closure dependency set while the fence is held → project transition + append-only event/audit facts.

This is not certified. The closure check is only safe if every child writer/finalizer acquires a compatible project parent fence before child locks and revalidates after waiting. The current command reviews identify a parent/child inconsistency: CMD-011's candidate `FOR KEY SHARE` may not conflict with a non-key project status update; CMD-012/013 have session-first order; CMD-015 omits explicit project/session parent locks. CMD-014/015 and asynchronous finalizers also need complete parent-fence treatment. L05 insertion cannot repair those existing inversions.

### 12.4 Recipient, selector and POQ-04 dispatch semantics

The PO-approved purpose is a scoped closure notice to operational participants selected by the exact approved event policy. No blanket project-wide or role-wide broadcast is inferred. The selector must evaluate against the pre-close project state at the one captured `audience_evaluated_at`; actor/target/participants are included only when the exact selector selects them. No role ID, membership table, participant field or scope projection is admitted by this review.

POQ-04 requires the immutable candidate snapshot and final closure event to commit atomically. Dispatch-time current-scope policy may suppress a captured candidate when closure makes the required scope invalid, but must not widen or replace the audience. A blanket “parent must currently be active” predicate can suppress every closure notice and is not an approved universal rule. The event-specific dispatch profile must explicitly resolve this behavior while preserving source-resource authorization independently.

### 12.5 Deduplication and race handling

The command uses actor + command + project scope + opaque idempotency key in the proposal. Concurrent close attempts must yield one committed state transition. Only the successful final transition may create the canonical `project.closed` fact and one immutable candidate snapshot. Retries must reuse the original source-event/snapshot checkpoint.

Unresolved: exact project version token; final closure gate set; canonical event identity; source/outbox/snapshot uniqueness; treatment of pending async finalizers; child-writer fence compatibility; and whether the T-14 qualifying population changes on project closure.

### 12.6 Admission decision

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-004 | `project.closed` | CMD-010 final project transition transaction identified statically; deployed producer/event envelope not proven | Scoped operational participant intent only; no physical mapping or selector admitted | Candidate atomic closure/audit/idempotency boundary; closure version, blockers and outbox/snapshot uniqueness unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 13. Reconciliation findings — CMD-013 / NREG-005

### 13.1 Exact event and producer boundary

**Static candidate:** CMD-013 `transition-session` may produce the approved exact event `session.closed` only for the final committed transition of the session to CLOSED. `session.close_requested` is a distinct action/event and is not interchangeable with the final state event; it is not part of NREG-005's approved candidate token.

The final close command transaction must atomically persist the session state transition, exact `session.closed` event/audit, idempotency and (only after future event admission and physical model approval) outbox plus immutable candidate snapshot. The actual producer/function, canonical event envelope/schema version and deployed transaction are not proven.

### 13.2 State machine, write set and concurrency token

PO-approved T-07 semantics preserve session states DRAFT/ACTIVE/PAUSED/CLOSED; CLOSED is terminal in ordinary flow. A closure request is an action/event, not a persisted intermediate state. Korlap may request closure only within assigned scope and explicit permission; Super Admin is the final-close authority after the approved closure gates. Reopen is exceptional, separately privileged, reasoned and audited; it is not implied by this candidate.

Proposed read/write objects include `sessions`, `projects`, `operational_assignments`, `assignment_members`, closure dependencies, `idempotency_records` and `audit_events`. The physical session proposal lacks a defined row-version field although CMD-013 carries `expected_row_version`; no CAS contract is proven. The exact transition-to-permission map, closure evidence and institutional gates remain open.

### 13.3 Candidate lock path and parent/child conflict

The source path map records a source command transaction and identifies the existing candidate sequence as session row → closure dependencies, with an explicit finding that session-before-project order conflicts with the parent-first global hierarchy. The normalized global candidate order requires project parent before session parent, then dependent closure aggregates in deterministic order. The exact compatible lock modes and all child writer/finalizer participation remain unresolved.

L05, if this exact final event is admitted, must be acquired after L00 and before the first mutable lock. That prefix does not solve the project/session parent inversion. CMD-010 closure and CMD-011/012/014/015 child paths must share one proven parent-fence protocol so a child cannot slip past final closure and no transaction acquires a lower-ranked parent after a child.

### 13.4 Recipient, selector and dispatch

The PO-approved intent is a scoped notice for the final session closure, not the closure request. Exact operational participants, source event scope, role IDs and membership projection are not approved. Resolve candidates from pre-close session/project scope under the exact selector only. Do not infer all assignment members or every project participant.

POQ-04 requires snapshot and final `session.closed` transition to commit atomically. Dispatch-time current-scope revalidation may suppress but never widen. A blanket active-parent check may suppress the very closure notice being announced; event-specific dispatch semantics must be explicit and must not grant access to the closed session or related resources.

### 13.5 Deduplication and race handling

One final state transition must emit one exact `session.closed` fact. A preceding `session.close_requested` action, repeated request, duplicate transition, or replay must not create a second final-closure notice. The command's idempotency and guarded session transition are candidate arbiters, but the missing physical session version token, exact event identity and outbox/snapshot uniqueness prevent certification.

### 13.6 Admission decision

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-005 | `session.closed` | CMD-013 final CLOSED transition identified statically; deployed producer/event envelope not proven | Scoped operational participant intent only; exact participant/scope projection and selector unresolved | Request vs final-close distinction is explicit; session CAS token, parent-fence protocol and outbox/snapshot uniqueness unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 14. Closure-event cross-command blockers

| ID | Finding | Impact | Required evidence / owner |
|---|---|---|---|
| NER-TR-16 | CMD-010 project closure blocker graph and child-writer inventory are not approved | Project close may race with new child work or omit pending finalizers | PO + Engineering + Security + institutional owner: approved blocker set and parent-fence matrix |
| NER-TR-17 | Project row-version/CAS representation is absent from the physical summary while CMD-010 carries `expected_version` | Stale/concurrent close protection is not specified | Engineering + Database: approved physical token/increment or controlled request-contract change |
| NER-TR-18 | CMD-011–015 parent/child lock order is inconsistent; CMD-015 omits explicit parent fences | Closure and child operations may race or deadlock | Engineering + Database + Security: one compatible project→session→assignment/member order, exact lock modes and opposing-transaction proof |
| NER-TR-19 | CMD-013 session row-version/CAS field is absent and transition permission mapping/closure evidence remain open | Final `session.closed` transaction cannot be certified | Engineering + Database + Security + PO/institution: physical token, transition matrix and final-close authority/evidence |
| NER-TR-20 | Final `session.closed` must be distinguished from `session.close_requested` in producer and dedup contract | Request event could be incorrectly notified as final closure or duplicate final notice | Engineering: exact event schema, final transition identity and negative event-token contract |
| NER-TR-21 | Dispatch-time current-scope/parent checks can suppress closure notice if treated as universal active-parent predicate | Closure event becomes invisible to intended candidates | Security + Engineering: event-specific dispatch profile with independent resource authorization |
| NER-TR-22 | Closure's effect on T-14 eligibility and L05/L10 order is not proven | Missing or inverted capacity/audience lock path | Engineering + Database: predicate impact analysis and approved global lock order |

## 15. Evidence required to close CMD-010/013

1. Approved project/session closure state machines, exact final-close actor/permission map, closure blocker inventory, institutional closure evidence and reopen boundary.
2. Complete project/session child writer/finalizer inventory for CMD-011–040, including assignment changes, inspections, evidence, document/print/attendance finalizers, sync, imports, repair and scheduled jobs.
3. Approved physical project/session concurrency tokens and compare-and-swap predicates/increment rules, or controlled removal/replacement of expected-version fields.
4. Compatible project-parent/session-parent/child lock modes and deterministic order, including CMD-014/015; proof that every child writer acquires parent fences before child locks and revalidates after waits.
5. Exact event producer schema/version and event identity for `project.closed` and final `session.closed`; prove `session.close_requested` is excluded from NREG-005.
6. Exact trusted participant/scope projection, approved selector dependencies and event-specific closure dispatch profile under POQ-04.
7. Prove final source mutation, event, audit, idempotency, outbox and complete immutable candidate snapshot commit atomically at one captured `audience_evaluated_at` after G10 activation.
8. Exact closure/retry dedup keys and planned tests for child-writer races, duplicate close, request-vs-final-close, dispatch suppression and audit rollback. Execution only after G10 activation.

## 16. Updated gate and work status

- CMD-002/003/005/010/013: partial static producer/transaction review completed; technical admission remains OPEN.
- NREG-001..005: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- L05/L10 and project/session parent fences: candidate proposals only; not technically approved.
- Eligibility/source writer coverage: PARTIAL; non-command writers and child finalizers incomplete; 0 writers certified.
- Resolver certification: 0/40. Application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC. Candidate snapshot relation/header: NOT ADMITTED.
- Tests: PLANNED / NOT EXECUTED. G9 NOT READY. G10 NOT ACTIVE.

**Disposition:** Continue with CMD-014 and CMD-015 next. Both are PO-approved candidates, but CMD-014 is create-only with complete initial roster, and CMD-015 requires explicit added/ended/retained-member treatment under POQ-04. Preserve their exact membership transition boundaries; do not infer recipients.
