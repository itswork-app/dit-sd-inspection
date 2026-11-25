# Notification Event Registry — Technical Reconciliation

**Document ID:** NLA-EVENT-TECH-RECON-001  
**Version:** 0.1.8  
**Status:** STATIC TECHNICAL RECONCILIATION — PARTIAL; NREG-001..011 (CMD-002/003/005/010/013/014/015/029/030/031/032) REVIEWED, ALL PARTIAL / UNRESOLVED / NOT ENABLED  
**Date:** 2026-11-24  
**Branch:** `docs/notification-resolver-lock-closure`  
**Scope:** Static technical reconciliation of all eleven first-batch registry rows NREG-001..011; all rows remain partial and unresolved  
**Authority:** AGENTS.md v1.2.2; Decision Register; CMD-001–054 Cross-Command Reconciliation; CMD-001–010 Detailed Contract Review; PostgreSQL Command Contract Catalogue; Command Physical Object Crosswalk; LOCK-NORMALIZATION-001; NLA-001; NLA-L05-TDR-001; L05 Eligibility-Writer Participation Matrix; POQ-04.

## 1. Purpose and boundary

This document records a static, evidence-bounded technical pass over all eleven PO-approved event candidates: CMD-002/003, CMD-005, CMD-010/013, CMD-014/015 and CMD-029/030/031/032. It is not an executable event contract, source-code inspection, live database inspection, or technical approval. CMD-001 `account.requested` remains deferred and is not among the approved first-batch candidates; CMD-031/032 are reviewed below; all eleven rows remain partial.

The following remain prohibited until G10 activation: source code, SQL, migrations, grants/revokes, RLS changes, live database operations, provider setup, deployment and production/staging mutation. No event is enabled by this document.

The registry's seven status dimensions remain controlling. All eleven reviewed rows remain:

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
| CMD-011–020 Detailed Contract Review | CMD-010/013/014/015 source command contracts, state/roster mutation boundaries, candidate read/write sets and unresolved concurrency/active-work rules | Candidate route/RPC and physical contracts remain unapproved |
| L05 Source-Event Path Mapping | CMD-002/003/005/010/013/014/015/029/030/031/032 producer transaction and proposed event/outbox/snapshot atomicity, candidate source paths and lock-order conflicts | Static candidate map; no source-code/function call graph or deployed transaction proof |
| L05 Eligibility-Writer Participation Matrix | Account, role, capacity, project/session, assignment/member and inspection/evidence writer families, including known non-command writer gaps | Incomplete writer inventory; no writer certified to participate |
| Command Lock Manifest Normalization Register | Candidate normalized global lock sequences for CMD-002/003/005/010/013/014/015/029/030/031/032 | Candidate ordering only; no lock certification or acyclic graph proof |
| Notification Recipient Resolver Lock-Set Review | Known CMD-014/015 resolver rank inversions and required reordering | Review findings only; no resolver or lock set admitted |
| PostgreSQL Command Contract Catalogue v0.4.8 | CMD-002/003 logical event names, permission family, target-account scope and candidate transaction semantics | Permission registry and command contracts remain unapproved for execution |
| Command Physical Object Crosswalk | CMD-002/003 proposed `app_users`, `account_decisions`, `idempotency_records`, `audit_events` dependencies | Proposed physical model, not live schema proof |
| Physical Database Schema and Integrity Specification | `app_users` candidate fields include `id`, `auth_user_id`, `approval_status`, `account_status`; `account_decisions` is proposed append-only with user, decision, actor, reason and time | Exact constraints, state model, deployed columns and ACL are unverified |
| LOCK-NORMALIZATION-001 v0.1.1 | Candidate L05 and lock-order paths for CMD-002/003 | Candidate order only; no admitted rank or certified path |
| L05 Source-Event Path Mapping v0.1.0 | CMD-002/003 source command transaction boundary, candidate lock sequence and required L05 insertion point | Candidate map copied from command manifest; source-code/function call-graph evidence and post-L05 order remain absent |
| L05 Eligibility-Writer Participation Matrix | CMD-002/003 are known account/login-eligibility writer paths; admin, support, disable/suspend/reactivate, auth reconciliation and other non-command writers are incomplete | No complete physical writer inventory; zero writers certified to participate |
| NLA-001 and NLA-L05-TDR-001 | POQ-01/04 snapshot and suppression invariants; proposed outbox and L05 protocol | Snapshot relation/header NOT ADMITTED; L05 and transaction isolation not technically approved |
| Decision Register / POQ-04 | Approved pre-mutation candidate snapshot and post-mutation suppression semantics | Event-specific eligibility mapping for pending account transitions is not yet resolved |
| CMD-031–040 Detailed Contract Review v0.2.0 | CMD-031 exact submitted revision, Reviewer assignment/SoD, terminal decision; CMD-032 explicit reopen authority, reason, immutable history and candidate transaction boundary | Proposal only; reviewer assignment, terminal-decision arbiter, reopen grant matrix and mutable draft context remain unresolved |
| LOCK-MANIFEST-001 v0.4.30 §7.13 and LOCK-GRAPH-001 v0.4.23 §30 | Candidate CMD-031/032 resource order and shared approve/return/reopen serialization | Candidate order only; physical lock set, FK/trigger/helper edges and acyclic graph are not certified |
| L05 source-event map v0.1.0 and writer matrix v0.1.4 | CMD-031/032 source-event candidate transactions and known eligibility writer families | No deployed call graph; writer inventory incomplete; no writer certified to participate |

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


## 17. Reconciliation findings — CMD-014 / NREG-006

### 17.1 Producer and transaction boundary

**Static candidate:** CMD-014 `publish-assignment` is the source command path for `assignment.created`. The proposed command is create-only and publishes one assignment plus its complete initial roster atomically. The L05 source-event path map places the canonical event, audit, idempotency, and (only after future event admission and physical model approval) outbox plus immutable candidate snapshot in this same source transaction. It is not a per-member asynchronous producer by inference.

The exact deployed producer/function, canonical event envelope/schema version, event identity, and whether the source emits one aggregate event or any per-member facts are not proven.

### 17.2 Candidate mutation and write set

Proposed source objects include `projects`, `sessions`, `locations`, `instruments`, `instrument_versions`, `teams`, `app_users`, `user_roles`, `operational_assignments`, `assignment_members`, `project_capacity_settings`, `idempotency_records` and `audit_events`.

The command writes `operational_assignments`, all `assignment_members` rows, idempotency and audit/event facts. It requires a complete initial roster and all-or-nothing validation; no partial assignment publication is allowed. Assignment status is server-selected, but the exact initial status and assignment row-version/overlap constraints remain open. No direct capacity-setting write is intended.

### 17.3 Candidate lock path and T-14

Candidate normalized order: L00 idempotency → L05 audience guard → conditional L10 capacity row(s), sorted by project UUID, if any proposed member can qualify as Inspector → L15 affected principals → L16 role grants → L17 scope grants → conditional L18 catalogue → L30 project then session parent fences → L40 instrument/version → L50 assignment → L55 initial membership rows in stable key order → L110 append-only facts.

The source map and normalized manifest are not identical in every rank detail; the normalized register is itself a review candidate. Exact L05/L10 order, affected project set, L15–L18 physical coverage, project/session/instrument/assignment FK lock edges, overlap uniqueness, trigger/helper graph and lock compatibility remain uncertified. T-14 requires the same distinct enabled-account predicate and one shared serialization point across role grants/revokes, assignment publication/member changes and capacity changes.

### 17.4 Recipient and event-time semantics

The conceptual recipient question is limited to members explicitly selected by the exact approved event contract. The command's initial `members[]` request data is not itself an approved event payload or participant projection; client-supplied user IDs cannot become trusted notification recipients without server-side validation and a canonical event contract. No actor auto-inclusion or role-wide broadcast is allowed.

A key unresolved boundary exists: the initial membership rows are created by this command and therefore do not exist in the pre-mutation assignment state. POQ-01/04 still requires the immutable audience to be evaluated at the serialized pre-mutation instant and exact selectors alone to select participants. The event contract must explicitly define whether a trusted `AFFECTED_MEMBER` participant projection can select newly inserted members as event participants without treating them as pre-existing assignment members. No automatic append of all inserted members is authorized by this technical review. The source event and candidate snapshot must commit atomically with the assignment and roster.

### 17.5 Deduplication and admission

The source command idempotency and unique assignment/member constraints are candidate arbiters only. Exact uniqueness of initial roster entries, event identity, duplicate membership handling, one-candidate-per-principal dedup, source-event/outbox uniqueness and immutable snapshot checkpoint are unresolved. A retry must reuse the original candidate set and must not fan out once per duplicate selector or member row.

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-006 | `assignment.created` | CMD-014 atomic create + complete initial roster transaction identified statically; deployed producer/event envelope not proven | Initial members are conceptual candidates only; pre-mutation event-participant semantics and trusted mapping unresolved | Aggregate transaction proposed; roster uniqueness, event cardinality and snapshot dedup unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 18. Reconciliation findings — CMD-015 / NREG-007

### 18.1 Producer and transaction boundary

**Static candidate:** CMD-015 `change-assignment-members` is the source command path for `assignment.changed`. The command validates all add/end operations before any write, applies them atomically, preserves historical membership rows and appends the event/audit/idempotency facts. The L05 source-event map proposes outbox and immutable candidate snapshot in the same source transaction only after event admission and physical approval.

The exact event schema/version, aggregate event cardinality, member-delta payload and deployed producer are not proven. It is not yet established whether one aggregate `assignment.changed` event represents all membership changes or whether a separate exact event per member operation is required; do not invent multiple notifications.

### 18.2 Candidate mutation, effective time and active-work boundary

Proposed write set: `assignment_members`, `idempotency_records`, `audit_events`; no role grant/revoke write and no reassignment of existing inspections/claims. The request requires a per-membership `effective_at` for each end operation. The exact event-time eligibility evaluation uses one captured `audience_evaluated_at`; end-membership intervals are half-open `[valid_from, valid_until)` under the POQ-04 approved pre-end rule.

The command review leaves active-claim/in-progress-inspection behavior unresolved: block the end, allow a future-effective end, or preserve a grandfathered workflow. No option is assumed. The exact physical membership lifecycle fields, uniqueness and history model also remain proposed.

### 18.3 Candidate lock path and T-14

Candidate normalized order: L00 → L05 → conditional L10 capacity rows sorted by project UUID if Inspector eligibility changes → L15–L18 affected principal/role/scope rows → L30 project then session parent fences → L50 assignment → L55 affected membership rows in stable key order → L110 append-only event/audit facts.

This remains a proposal. The source path map's shorter assignment-first path must be reconciled with the parent-first normalized order. All membership expiry/renewal/reconciliation, administrative roster import/repair and direct-DML paths must be included. The same T-14 predicate and serialization point must be used before and after the entire atomic membership change; no partial add/end batch is allowed.

### 18.4 Recipient and POQ-04 dispatch semantics

POQ-04 specifically requires pre-end membership evaluation at the one captured instant. A member may enter the immutable candidate set only if the exact event selector selects that principal while the pre-end membership is effective. After commit, current assignment/member scope revalidation may suppress the captured candidate because the membership has ended; no substitute member may be added.

The event may also add new members. Their inclusion semantics are not settled by the approved end-member rule. Retained members must not be silently included or excluded by inference. The event registry's added/ended/retained distinction must be made explicit in the canonical event/selector contract. Actor is never implicit; no global assignment or role broadcast is authorized.

### 18.5 Deduplication and admission

The source command is all-or-nothing and idempotent at the command level, but exact event cardinality, semantic member-delta identity, duplicate add/end operation handling, source event ID and outbox/snapshot dedup remain unresolved. Replays must not produce a second event or new recipient set. An ended member must not be replaced by another current member on retry.

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-007 | `assignment.changed` | CMD-015 atomic member add/end transaction identified statically; deployed producer/event envelope not proven | Added/ended/retained member selection unresolved; POQ-04 pre-end semantics apply; no substitute member | Aggregate event cardinality, semantic delta identity and snapshot/outbox dedup unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 19. Assignment-event cross-command blockers

| ID | Finding | Impact | Required evidence / owner |
|---|---|---|---|
| NER-TR-23 | CMD-014 initial roster rows do not exist in the pre-mutation assignment state | A selector cannot treat inserted members as pre-existing effective members without an explicit event-participant rule | PO + Engineering + Security: define trusted new-member participant semantics consistent with POQ-01/04 |
| NER-TR-24 | CMD-015 event does not yet distinguish added, ended and retained members in an approved canonical contract | Incorrect recipients, retained-member broadcast or duplicate per-member notices may result | PO + Engineering: approve event cardinality and exact member-delta projection |
| NER-TR-25 | CMD-015 active claim/in-progress inspection behavior is unresolved | Ending membership may orphan work or silently reassign ownership | PO + Engineering + Operations: block/future-effective/grandfather rule and operational recovery |
| NER-TR-26 | T-14 L10, L05, L15–L18, L30, L40, L50 and L55 ordering is not certified for assignment writers | Capacity corruption, deadlocks or eligibility snapshot races | Engineering + Database + Security: one complete global lock/parent-FK graph and opposing-transaction proof |
| NER-TR-27 | Assignment/member unique constraints, interval overlap, physical version/history and exact FK/trigger graph remain open | Source event and candidate snapshot cannot be bound to a deterministic membership delta | Database: approved physical constraints and event-to-row provenance |
| NER-TR-28 | Expiry/renewal/import/repair/direct-DML writers are incomplete | L05 writer completeness cannot be proven | Engineering + Security + Operations: complete entrypoint/owner/ACL and guarded transaction inventory |

## 20. Evidence required to close CMD-014/015

1. Exact canonical event schema/version, producer identity, source-event identity and event cardinality for assignment creation and membership changes.
2. Approved trusted participant projection for the complete initial roster and explicit semantics for new members under the pre-mutation snapshot rule.
3. PO-approved added/ended/retained member event semantics, including whether a single aggregate event or multiple exact member events are produced; no inferred fan-out.
4. PO/Operations decision for active claims and in-progress inspections when a member is ended; no automatic reassignment.
5. Physical assignment/member keys, interval constraints, overlap semantics, history/immutability, aggregate version strategy and all FK/trigger/unique lock edges.
6. Complete T-14 qualifying population writer inventory and approved L05/L10/L15–L18/L30/L40/L50/L55 global order.
7. Exact event/outbox/snapshot dedup keys and proof that source mutation + event + audit + idempotency + immutable snapshot commit atomically.
8. Security/Engineering/Database review of trusted caller identity, role/scope grants, function owner/search_path/EXECUTE ACL, direct-DML bypass and L05 participation.
9. TC-NOTIF-082..085 and command/concurrency/security cases remain PLANNED until G10 activation; execute only in the authorized isolated environment.

## 21. Updated gate and work status

- CMD-002/003/005/010/013/014/015: partial static producer/transaction review completed; technical admission remains OPEN.
- NREG-001..007: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- L05/L10, assignment membership and project/session parent fences: candidate proposals only; not technically approved.
- Eligibility/source writer coverage: PARTIAL; non-command writers, expiry and repair paths incomplete; 0 writers certified.
- Resolver certification: 0/40. Application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC. Candidate snapshot relation/header: NOT ADMITTED.
- Tests: PLANNED / NOT EXECUTED. G9 NOT READY. G10 NOT ACTIVE.

**Disposition:** Continue with CMD-029 and CMD-030 next. CMD-029 has a dual source declaration (`inspection.submitted` and `inspection_revision.created`) and requires exact one-notice dedup semantics; CMD-030 requires exact assigned-Inspector mapping. Both are PO-approved candidates only.


## 22. Reconciliation findings — CMD-029 / NREG-008

### 22.1 Producer and transaction boundary

**Static candidate:** CMD-029 `submit-inspection` is the producer path for the single user-facing notification intent `inspection.submitted`. The source declaration also includes `inspection_revision.created`, a related immutable revision fact. The PO-approved candidate is `inspection.submitted` only; the revision-created fact is not a second approved notice.

The source command transaction validates the active claim/assignment/association, required persisted responses and finalized evidence, creates an immutable submitted revision, advances the inspection aggregate, appends the submission/revision events and audit, and persists idempotency atomically. If the notification candidate is later enabled, its outbox and immutable candidate snapshot must be included in the same source transaction. The exact event cardinality and whether both facts reside in `audit_events` or separate domain-event storage remain unresolved.

### 22.2 Candidate source objects and integrity

Proposed reads include `inspections`, `unit_claims`, `unit_project_associations`, `operational_assignments`, `assignment_members`, pinned `instrument_versions`, checklist/specification definitions and responses, evidence slot definitions/assets, `sync_batches` and idempotency. Writes include inspection status/current revision/row_version, append-only `inspection_revisions`, `inspection_events`, idempotency and audit.

The submitted revision is immutable and contains the exact pinned instrument version, canonical payload snapshot and hash. Submission does not auto-approve, assign a Reviewer, generate a PDF or mutate assignment/association/unit history. A pending upload intent is not finalized evidence; unresolved sync conflicts block submission.

### 22.3 Candidate lock path and F-03/F-04 dependency

The normalized candidate order is L00 → L05 → L30 project/session/assignment context → L60 unit → L70 association → L80 active claim → L90 inspection → L100 evidence/response snapshot inputs → L110 append-only facts. This is a candidate order only. The source-event path map and earlier source manifest place the inspection aggregate before claim/association/assignment dependencies, which conflicts with the normalized parent-first order. That conflict must be resolved before any path is certified; inserting L05 at the front does not repair it.

The selector dependency universe is not frozen. If the notification selector depends on assignment membership, reviewer assignment, inspection state or project/session scope, each referenced table/column and every writer must be included in F-04. Exact evidence-object verification, trigger/FK edges, snapshot canonicalization and lock modes remain open.

### 22.4 Recipient, event token and deduplication

The conceptual recipient is the Reviewer assigned to the submitted inspection. The physical schema and command review do not identify an authoritative Reviewer-assignment relation or exact participant field. Do not infer Reviewer eligibility from Super Admin, project membership, generic `assignment_members` or a role title. A notification selector must bind to an approved reviewer-assignment source and the exact submitted revision/inspection scope.

The two source facts must not become two notices. The registry admits only `inspection.submitted`; `inspection_revision.created` remains a related source fact for provenance/correlation. The exact canonical event ID, revision reference, dedup key and outbox policy pin are unresolved. A replay or duplicate submission must not create a second submitted revision or a second notification snapshot.

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-008 | `inspection.submitted` | CMD-029 source transaction and immutable revision creation identified statically; deployed producer/event envelope not proven | Assigned Reviewer is conceptual only; authoritative assignment source and participant projection absent | Submission + revision facts atomic; one-notice distinction explicit; exact event ID/dedup and snapshot key unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 23. Reconciliation findings — CMD-030 / NREG-009

### 23.1 Producer and transaction boundary

**Static candidate:** CMD-030 `return-inspection` is the source command path for `inspection.returned_for_correction`. The command appends a terminal RETURN decision for the exact current submitted revision, updates the inspection lifecycle state/version, appends inspection/audit events and persists idempotency atomically. It must not mutate the submitted revision snapshot, response rows or evidence identity.

The exact deployed producer, canonical event envelope/schema version and source event identity are not proven. A duplicate return on the same revision is a state conflict, not a second decision or notification.

### 23.2 Candidate source objects and reviewer/Inspector identity

Proposed reads: `inspections`, `inspection_revisions`, `review_events`, reviewer permission/scope, reviewer assignment source (unresolved) and idempotency. Proposed writes: append-only `review_events`, inspection state/row_version, append-only `inspection_events`, idempotency and audit. The review event proposal contains revision ID, reviewer ID, decision, reason and creation time; it does not identify an assignment ID, review round or decision sequence.

The conceptual notification recipient is the responsible Inspector for the returned revision. The stored revision author may be a relevant trusted identity, but the approved assignment-to-Inspector mapping and rule for whether author equals current responsible Inspector are not established. Do not substitute the reviewer, Super Admin, generic assignment member or role title. The exact Inspector participant projection and current assignment scope require approval.

### 23.3 Candidate lock path, SoD and decision uniqueness

Normalized candidate order: L00 → L05 → L30 project/session/assignment/reviewer-authority context → L60 unit → L70 association only if required for current review eligibility → L90 inspection → L100 target revision/review-decision key → L110 append-only facts. This is not certified; the source command review's inspection-first path conflicts with the normalized parent-first order. Do not add a lower-rank parent/association lock after taking the inspection lock.

The reviewer must be the currently assigned reviewer for the exact inspection scope; reviewer != revision author is mandatory, including users holding both Inspector and Reviewer permissions. The physical review model lacks an explicit reviewer-assignment ID, decision sequence or review-round key. Exactly one terminal review decision per revision must be enforced; approve-vs-return must serialize on the inspection aggregate. The source event and candidate snapshot must commit atomically with the return transition.

### 23.4 Recipient, selector and dispatch

Only the exact approved selector may select the responsible Inspector. No participant is appended implicitly. Dispatch must preserve the captured event-time candidate set; current account/channel/consent/security and approved current-scope checks may suppress but never widen. A notification does not expose the return reason or protected evidence unless the approved privacy and message projection explicitly permits it; source-resource access remains independently authorized.

### 23.5 Deduplication and admission

One successful RETURN decision for the exact current revision may produce one `inspection.returned_for_correction` source fact and one immutable candidate snapshot. Same-key replay returns the prior outcome; distinct-key duplicate return is rejected. The exact unique decision key, review round identity, event ID and outbox/snapshot dedup remain unresolved.

| Registry ID | Event | Producer path evidence | Participant / selector | Dedup / transaction | Technical disposition |
|---|---|---|---|---|---|
| NREG-009 | `inspection.returned_for_correction` | CMD-030 return decision transaction identified statically; deployed producer/event envelope not proven | Responsible Inspector is conceptual only; author/current-assignment mapping and reviewer-assignment source unresolved | One terminal RETURN per revision proposed; exact decision uniqueness, event ID and snapshot dedup unresolved | **PARTIAL STATIC REVIEW — UNRESOLVED / NOT ENABLED** |

## 24. Inspection-event cross-command blockers

| ID | Finding | Impact | Required evidence / owner |
|---|---|---|---|
| NER-TR-29 | CMD-029 declares both `inspection.submitted` and `inspection_revision.created` | Duplicate notices or incorrect source-event identity | Engineering + Database: canonical event cardinality/storage mapping; only `inspection.submitted` is the approved notice candidate |
| NER-TR-30 | Reviewer assignment source is not concretely physicalized | No trusted assigned-Reviewer recipient can be resolved for submission | PO + Engineering + Security + Database: explicit reviewer assignment entity/relationship, scope and effective-time mapping |
| NER-TR-31 | CMD-029 source lock order inspection-first conflicts with normalized parent/claim/assignment order | Deadlock or audience snapshot race; resolver cannot be certified | Engineering + Database + Security: canonical global order and full opposing transaction graph |
| NER-TR-32 | CMD-030 review event lacks assignment ID, review round and decision sequence | Multiple terminal decisions or ambiguous review ownership | Database + Engineering: exact unique terminal-decision key and reviewer assignment provenance |
| NER-TR-33 | Inspector recipient mapping from revision author to currently responsible assigned Inspector is not approved | Notice may target stale author or wrong assignment member | PO + Engineering + Security: exact author/current-member semantics and event participant projection |
| NER-TR-34 | Reviewer != author and current reviewer assignment checks are not backed by a physical assignment source | SoD and review authorization cannot be proven | Security + Database: reviewer assignment, current scope, reviewer/author identity and ACL evidence |
| NER-TR-35 | Evidence/response snapshot, claim, association and inspection locks/FKs are not reconciled | Event transaction and L05 audience resolution may invert lock order | Engineering + Database: full FK/trigger/helper graph and canonical order |

## 25. Evidence required to close CMD-029/030

1. Exact event schema/version and transaction identity for `inspection.submitted`, with `inspection_revision.created` explicitly treated as a related non-notification fact unless separately approved.
2. Approved physical Reviewer assignment source, scope/effective-time semantics and exact participant projection for NREG-008.
3. Approved current responsible-Inspector mapping for NREG-009, including whether revision author and current assignment member must match.
4. Exact physical review-decision unique key/review round and reviewer-assignment ID; enforce one terminal decision per revision and approve-vs-return serialization.
5. Canonical lock order across project/session/assignment/unit/association/claim/inspection/evidence/revision and every writer; include implicit FK/trigger/helper edges.
6. Approved selector dependencies and complete F-04 writer map for assignment, review authority, inspection, claim, association and evidence state.
7. Atomic source mutation + revision/review facts + event + audit + idempotency + outbox + complete immutable candidate snapshot proof at one captured instant.
8. Exact event/snapshot dedup keys, no duplicate submission/return notice, and planned negative tests for wrong Reviewer/Inspector, stale revision, SoD, replay and lock inversion. Execute only after G10 activation.

## 26. Updated gate and work status

- CMD-002/003/005/010/013/014/015/029/030: partial static producer/transaction review completed; technical admission remains OPEN.
- NREG-001..009: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- L05, parent/claim/assignment/inspection lock order: candidate proposals only; not technically approved.
- Reviewer assignment and responsible-Inspector mapping: NOT ADMITTED.
- Resolver certification: 0/40. Application lock certification: 0/50. Global lock graph NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header NOT ADMITTED. Tests PLANNED / NOT EXECUTED. G9 NOT READY. G10 NOT ACTIVE.

**Disposition:** Continue with CMD-031/032 next. Their event candidates are PO-approved, but review-decision and reopen semantics must be reconciled against exact current revision, SoD, active work and immutable event boundaries.


## 27. Reconciliation findings — CMD-031 / NREG-010

### 27.1 Exact source event and transaction boundary

**Static candidate:** CMD-031 `approve-inspection` is the source command for the exact `inspection.approved` candidate. The detailed contract defines approval as a decision on one exact immutable submitted revision, not an edit to Inspector answers. The approved revision must still be the current reviewable revision at commit time.

The candidate source transaction includes the inspection aggregate transition and row-version update, one terminal APPROVE review decision for the exact revision, the inspection transition event, audit event, idempotency result, and—only after future technical admission—outbox plus immutable candidate snapshot. These facts must commit atomically. The proposed source event is not a PDF-generation, print, or unit-completion event.

**Not proven:** deployed producer/function, physical canonical event storage and envelope/version, source-event primary identity, exact event-to-audit/outbox correlation key, and deployed transaction semantics. `audit_events` metadata naming `inspection.approved` is a candidate fact, not proof that the audit row itself is the canonical notification event.

### 27.2 Revision and terminal-decision identity

The request contract supplies `inspection_id`, `revision_id`, and `expected_revision_no`. Server-side validation must prove the revision belongs to the inspection, is submitted, remains current, and is the exact revision approved at commit. The immutable revision and its evidence/answers are not updated.

CMD-030 return and CMD-031 approve must serialize on the same inspection aggregate and one terminal-decision-per-revision invariant. The physical design names append-only `review_events`, but the exact unique arbiter, review-round model, terminal-decision key and database constraint are not admitted. Two approvals or approve-vs-return cannot both commit for the same revision.

### 27.3 Reviewer authority and participant mapping

The command contract requires an active authenticated account, explicit `inspection.review` authority, persisted reviewer assignment for the exact project/session/location/assignment scope, and reviewer != revision author. A generic Super Admin label, project membership, title or client-supplied reviewer ID is insufficient. The current catalogue does not require dual review; do not introduce it by inference.

The physical reviewer-assignment relation and eligibility predicate remain unphysicalized/unapproved. NREG-010's conceptual responsible-Inspector notification question is not a recipient mapping: approval actor, reviewer, revision author and responsible Inspector are distinct identities unless an approved contract explicitly equates them. No principal is selected by this reconciliation.

### 27.4 Lock, writer and event-time snapshot

The source command text is inspection-aggregate-first. LOCK-MANIFEST-001 §7.13 proposes the candidate order L00 → L05 → reviewer/target principals → role grants → scope grants → project/session parents → assignment/member scope → inspection aggregate → append-only facts. This is only a proposal; the exact reviewer-assignment object, membership lock requirements, review-decision arbiter, FK/trigger/helper edges and complete eligibility-writer participation are unresolved. The candidate order must be reconciled with the shared CMD-028–032 inspection/revision serialization and the global graph.

The future source transaction must evaluate the immutable notification candidate set against the approved pre-mutation state at one captured `audience_evaluated_at`, and atomically commit source transition, canonical event, audit, idempotency, outbox and complete snapshot. Dispatch may suppress existing candidates but never add recipients. No selector, recipient, scope tuple or physical snapshot relation is admitted.

### 27.5 NREG-010 disposition

NREG-010 is now `PARTIAL_STATIC_REVIEW` only. Canonical contract, recipient mapping, selector and dispatch profile remain `UNRESOLVED`; publication remains `NOT_ENABLED`.

## 28. Reconciliation findings — CMD-032 / NREG-011

### 28.1 Exact source event and transaction boundary

**Static candidate:** CMD-032 `reopen-inspection` is the source command for the exact `inspection.reopened` candidate. Reopen is a privileged lifecycle transition from APPROVED state, requires an explicit authority and mandatory reason, and preserves the approved revision and all historical evidence, generated documents and print events. It is not a return-for-correction event and does not itself approve a new revision.

The candidate transaction includes the inspection lifecycle/version transition, append-only inspection event and audit event, idempotency result, and—only after future technical admission—outbox plus immutable candidate snapshot. All must commit atomically. A replay must return the original result after reauthorization; concurrent requests cannot create multiple active draft contexts.

**Not proven:** deployed producer/function, canonical event envelope/version and physical event identity, exact event-to-audit/outbox correlation key, and deployed transaction semantics.

### 28.2 Reopen authority, next-action owner and participant mapping

The command review proposes permission `inspection.reopen` and an explicit grant, with project/inspection scope and active account/grant checks. The permission registry's suggested Super Admin or separately authorized Admin authority is still draft; the exact role/grantor/SoD matrix is not approved. A generic Super Admin label does not grant reopen authority.

The new next-action owner is unresolved. The Inspector who authored the prior revision, current assignment member, reviewer who approved it, and actor who reopens it must not be treated as interchangeable. NREG-011's conceptual operational-participant question is not an approved recipient selector. No role, recipient or substitute participant is admitted.

### 28.3 Draft context and active-work blockers

The physical specification does not define a sufficiently explicit mutable draft representation after reopen. Do not insert an immutable `inspection_revisions` row prematurely, invent a draft revision ID, or mutate the approved revision. The state vocabulary (including whether REOPENED is a durable state or a projection into a separately modeled draft state), draft response storage, pointer/version semantics and one-active-draft uniqueness are unresolved.

The exact blocker inventory and lock dependencies for active claims, unit/project association, assignment membership, evidence finalizers, document generation and print history also remain unresolved. Reopen must preserve prior artifacts and serialize against CMD-028/029/030 and relevant finalizers; no active-work policy or blanket blocker is inferred.

### 28.4 Lock, writer and event-time snapshot

LOCK-MANIFEST-001 §7.13 proposes L00 → candidate L05 → principal/role/scope authority → project/session → assignment/member → active claim only where required → inspection aggregate → mutable draft context only if physically modeled → append-only event/audit. This is a candidate order, not an admitted physical lock set. The blocker dependency universe, association/claim rank, draft-context entity, FK/trigger/helper edges and complete writer participation are not proven. The source review's inspection-first sequence must not be treated as certified.

The future source transaction must persist the immutable event-time candidate snapshot with the committed reopen event and mutation at one captured `audience_evaluated_at`. Retries reuse that snapshot. Dispatch-time checks may suppress but never widen it. No selector, recipient, scope tuple or physical snapshot relation is admitted.

### 28.5 NREG-011 disposition

NREG-011 is now `PARTIAL_STATIC_REVIEW` only. Canonical contract, recipient mapping, selector and dispatch profile remain `UNRESOLVED`; publication remains `NOT_ENABLED`.

## 29. Consolidated CMD-031/032 closure requirements

1. Admit the exact canonical source-event identity, schema/version, producer transaction and outbox/snapshot dedup keys.
2. Physicalize and approve reviewer assignment, exact scope binding, reviewer eligibility, reviewer != author SoD, and one terminal review decision per revision/round.
3. Define and approve the explicit `inspection.reopen` grant/role/authority/SoD matrix and the next-action owner without identity substitution.
4. Define mutable draft persistence, state vocabulary, revision pointer/version behavior and one-active-draft uniqueness without mutating immutable approved history.
5. Enumerate active claim/association/assignment/evidence/document finalizer blockers and every command/non-command writer; reconcile all implicit FK/trigger/helper edges.
6. Independently validate the complete L05/global lock order, event-time linearization, atomic source-event/audit/idempotency/outbox/snapshot transaction and post-event suppression.
7. Execute deterministic approve-vs-return, approve-vs-reopen, duplicate approval, duplicate reopen, stale revision, SoD, authorization, audit rollback, snapshot retry and lock-cycle tests only after G10 activation.

## 30. Updated gate and work status

- CMD-002/003/005/010/013/014/015/029/030/031/032: partial static producer/transaction review completed; technical admission remains OPEN.
- NREG-001..011: PARTIAL STATIC REVIEW; canonical contract, recipient mapping, selector and dispatch profile UNRESOLVED; NOT ENABLED.
- Reviewer assignment, responsible Inspector and reopen next-action owner mappings: NOT ADMITTED.
- Reopen permission/grant matrix and mutable draft persistence: NOT ADMITTED.
- L05, parent/claim/assignment/inspection lock order: candidate proposals only; not technically approved.
- Resolver certification: 0/40. Application lock certification: 0/50. Global lock graph NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header NOT ADMITTED. Tests PLANNED / NOT EXECUTED. G9 NOT READY. G10 NOT ACTIVE.

**Disposition:** All eleven PO-approved candidates have now received a partial static technical pass. This does not admit any canonical event contract, recipient, selector, dispatch profile, physical schema or event publication.


## 31. Closure ownership and evidence pointer — 2026-11-24

The detailed approval/reopen acceptance matrix is maintained in [TECH-RESOLUTION-LPR-001 v0.1.11](ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) §18. It assigns product-semantic decisions to PO/operational authority, permission and SoD review to Security, physical identity/constraint/transaction/lock proof to Engineering and Database, and planned verification review to QA. The matrix is a review instrument only; it does not grant authority or close an item.

The controlling lock decision status is [LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.13](LOCK-PROTOCOL-DECISION-RESOLUTION.md): LPR-01/LPR-07/LPR-09/LPR-11 OPEN and LPR-10 NOT EXECUTED. CMD-031/032 source order, candidate rank order, and complete writer/implicit-edge graph remain unreconciled and uncertified. No change to NREG row admission or publication status follows from this pointer.


## 32. CMD-030/031/032 review-decision arbiter pointer — 2026-11-24

[REVIEW-ARBITER-001 v0.1.0](REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md) now records a bounded candidate for one terminal review decision per immutable revision. CMD-030 RETURN and CMD-031 APPROVE share the same inspection serialization point and proposed physical uniqueness arbiter. The preferred unique constraint depends on confirmation that `review_events` stores terminal decisions only; a partial index depends on Database approval of the terminal decision vocabulary. Neither is approved or implemented.

CMD-032 remains blocked on the physical mutable draft-context representation and one-active-draft arbiter. Reviewer assignment/SoD, exact lock ordering and implicit lock edges remain unresolved. This proposal does not establish an event producer, recipient mapping, selector, dispatch profile or event enablement.

NREG-010 `inspection.approved` and NREG-011 `inspection.reopened` remain PARTIAL / UNRESOLVED / NOT ENABLED. Resolver certification 0/40; application lock certification 0/50; global graph NOT PROVEN ACYCLIC; QA PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.
