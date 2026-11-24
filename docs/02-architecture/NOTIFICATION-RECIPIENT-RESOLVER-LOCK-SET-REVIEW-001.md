# Notification Recipient-Resolver Lock-Set Review

**Document ID:** NLA-RESOLVER-LOCK-001  
**Version:** 0.1.4  
**Status:** Engineering design proposal — NOT APPROVED; no lock rank or physical mechanism is admitted  
**Date:** 2026-11-24  
**Repository baseline:** docs/audit-lock-and-identity-reconciliation at 7d722a77ac37a4c82a026daeddd1b00df4a4f713  
**Inputs:** AGENTS.md v1.2.2; NLA-001 v0.1.5; LOCK-MANIFEST-001 v0.4.27; LOCK-GRAPH-001 v0.4.20; RTM NOTIF-014/015; RAID R-037; DGA-001 v1.11.56

## 1. Executive result

The producer inventory is complete at the documentation boundary: LOCK-MANIFEST-001 §7.7 maps all 40 domain command event declarations (CMD-001–040) to their current candidate source lock paths. CMD-054 is separately identified as a scheduler-generated source. CMD-052/053 are consumers, not domain source producers.

The remaining defect is narrower and more important: **none of the 40 source paths proves that the complete notification recipient-resolver lock set is acquired before source aggregate locks.** Existing L15/L16/L17 locks, where present, generally cover the command actor/target or grant being mutated—not the complete candidate recipient set. The graph therefore correctly reports 0/40 resolver paths certified and 0/50 application commands lock-certified.

This document proposes a common resolver serialization boundary and a source-specific lock protocol for review. It does not approve a new lock rank, advisory lock, isolation level, schema, FK, index, function, grant or implementation. The candidate notification_outbox_recipients relation and outbox snapshot header fields remain NOT ADMITTED.

## 2. Invariants that the design must satisfy

1. Exact event-type allowlisting: a source command creates a notification intent only when an immutable enabled policy explicitly matches the exact canonical event type and approved selector schema. No wildcard or implicit notification for every audit event.
2. Event-time audience: recipient and authorized source-scope candidates are resolved at one explicit linearization point and committed atomically with the source event, required audit event and outbox intent.
3. No widening: CMD-052 retries consume only persisted candidates. Current account/channel/consent/security checks may suppress; they cannot add recipients or re-resolve current membership.
4. Complete eligibility consistency: concurrent account, role, scope, assignment/member, capacity and parent-lifecycle changes must serialize against the recipient resolver or be detected and retried under an approved serializable protocol.
5. FK safety: every referenced row/key used by snapshot and inbox inserts is accounted for, including implicit FK KEY SHARE, unique-index, trigger and helper-function effects.
6. One total order: no transaction may acquire a lower-ranked resource after a higher-ranked resource. Multi-row acquisitions use stable deterministic ordering.
7. Atomicity: business mutation + canonical event + required audit + idempotency + outbox + complete snapshot commit or roll back together.
8. Worker isolation: no queue-row lock is held during fan-out work or provider I/O; no provider I/O occurs inside a database transaction.

## 3. Source-command resolver coverage matrix

The source lock paths below are extracted from LOCK-MANIFEST-001 §4 and §7.7. “Existing identity locks” means locks currently documented for the command's own actor/target/authority—not proof that all candidate recipients are locked.

| Commands | Existing source lock shape | Resolver coverage finding | Required correction before certification |
|---|---|---|---|
| CMD-001 | L00 → caller L15; absent-row unique auth_user_id arbiter | Caller only; no complete candidate audience or selector predicate fence | Add common resolver boundary before source mutation; union actor and candidates into one sorted L15 set |
| CMD-002–003 | L00 → conditional L10 → actor/target L15 → actor L16/L17 → conditional L18 → decision/audit | Actor/target only; candidate recipient set and predicate serialization not proven | Resolver boundary before account decision locks; define post-approval/rejection audience semantics |
| CMD-004–005 | L00 → conditional L10 → actor/target L15/L16 → delegation L17 → conditional L18 | Grantor/grantee rows only; candidate audience and concurrent grant/expiry predicate not covered | Common resolver boundary before L10/identity locks; include role-grant changes in same serialization domain |
| CMD-006–007 | L00 → L15/L16/L17/L18 → optional scope parent L30/L50 | Better prefix, but only command authority rows are named; complete recipient set and scope predicate not proven | Resolve/serialize the selector set first; union all candidate principals/grants and scope parents in deterministic order |
| CMD-008–010 | L00 → actor L15/L16/L17/L18 → L30 project | Actor authority precedes project, but candidate recipients are not included | Pre-acquire resolver set and scope FK parents before project aggregate fence |
| CMD-011 | L00 → project L30 → session insert | L30 precedes candidate L15/L16/L17; project child-fence mode also open | Resolver boundary before project lock; then project/session in approved parent order |
| CMD-012–013 | L00 → session then project/dependencies | Child-first path already blocked; resolver locks would add further reverse-order edges | Normalize project/session order and resolver prefix together; no local patch |
| CMD-014 | L00 → L10 → project/session/assignment L30 → instrument L40 → affected users/role refs | Explicit higher-rank L30/L40 before affected user/role references; direct inversion candidate | Move complete resolver L15/L16/L17 acquisition ahead of L30/L40; preserve L10-first only where T-14 applies |
| CMD-015 | L00 → L10 → assignment L50 → members L55/users | Assignment/member rows precede candidate principal/grant resolution | Resolver prefix before L50/L55; merge candidate and changed-member user IDs into one sorted set |
| CMD-016 | L00 → L10 capacity row → eligibility rows | Eligibility row classes and resolver overlap unspecified | Define exact eligibility row set; common audience guard and T-14 guard order must be approved |
| CMD-017 | L00 → project/session L30 → plan/allocations | Parent locks precede recipient resolver resources | Resolver prefix before L30; plan/allocation locks follow the approved parent order |
| CMD-018 | L00 → unique instrument code → instrument insert | No explicit candidate identity/authorization lock set | Resolver prefix before any instrument arbitration if the event is notification-eligible |
| CMD-019–020 | L00 → instrument/version L40 → configuration/publication rows | L40 precedes candidate principal/grant rows | Resolver prefix before L40; keep immutable version checks after |
| CMD-021 | L00 → instrument → assignment reference checks | Instrument/assignment resources precede candidate identity/grant rows | Resolver prefix before instrument/assignment checks |
| CMD-022 | L00 → canonical key L20 → context authorization → unit insert | L20 may precede candidate L15/L16/L17 | Resolver prefix before L20; preserve one canonical serial-key arbitration protocol |
| CMD-023–025 | L00 → unit/conflict → project/association key in conflicting orders | Existing source order is independently blocked and cannot accept resolver edges safely | Normalize canonical identity, project/assignment, unit, association and conflict rank first; then insert resolver prefix before those resources |
| CMD-026 | L00 → L20 → L30 → L50 → L60 → L70/claim/inspection | Candidate L20/L30/L50 path precedes recipient identity/grant resources | Resolver prefix before L20; reconcile catalogue/detail order before certification |
| CMD-027 | L00 → unit → association → assignment → claim → inspection | Existing order conflicts with candidate global hierarchy and precedes resolver resources | Normalize claim path and resolver prefix together |
| CMD-028–032 | L00 → inspection aggregate → claim/association/assignment/revision/review children | Inspection/child locks precede candidate identity/scope resources | Normalize parent/claim/assignment/inspection order and acquire resolver prefix before all of them |
| CMD-033 | L00 → inspection → quota/evidence intent | Inspection precedes candidate identity/scope resources | Resolver prefix before inspection/quota locks; preserve upload authorization boundary |
| CMD-034 | External object inspection → L00 → evidence → inspection/claim/assignment revalidation | External I/O is outside DB locks, but DB child locks precede candidate identity/scope refs | Keep Storage inspection outside transaction; resolver prefix must precede DB evidence/domain locks |
| CMD-035 | L00 → sorted inspections or per-operation transaction → operation children | Candidate identity/scope resources are not explicitly pre-acquired per operation | Choose operation transaction boundary; each notification-producing operation gets its own resolver prefix and snapshot |
| CMD-036 | L00 → source/document generation key → pending document/job; asynchronous guarded finalizer | Request and finalizer have different lock sets; finalizer may reach source aggregate before resolver | Define finalizer as event source; resolver prefix before finalizer source/lease locks; document job outbox remains separate |
| CMD-037–038 | L00 → document aggregate/sequence; batch then per-item document locks | Document/item locks precede candidate identity/scope resources | Resolver prefix per emitted item event before document sequence locks; no batch-wide audience lock |
| CMD-039–040 | L00 → attendance record/document; external Storage between short transactions | Attendance/document locks precede candidate identity/scope resources | Resolver prefix in the finalization/verification source transaction before attendance/document locks; institution authority remains separate |

**Result:** 40/40 source declarations are mapped; 0/40 resolver lock paths are certified. This is not a statement that every source command will emit notifications. The immutable policy allowlist decides which exact event types are eligible.

## 4. Candidate common serialization boundary

### 4.1 Option A — global transaction-level audience guard (recommended for design review)

Introduce a candidate transaction-level advisory serialization guard at **L05**, after L00 idempotency arbitration and before L10 capacity or any principal/domain row lock.

- Every source command that may emit an allowlisted event acquires the guard before any domain lock.
- Every writer that can change candidate eligibility acquires the same guard before changing account status, role grants, scope grants, assignment membership, effective intervals, capacity eligibility or relevant parent lifecycle state.
- The initial safe variant uses one global audience guard. This is intentionally coarse and may reduce write concurrency; it avoids an incomplete per-scope key registry during the first release.
- A later sharded design may derive one or more guard keys from an approved selector-schema version and canonical scope tuple. Multi-key acquisition must sort by canonical byte representation and use a collision-safe encoding.
- The guard is transaction-scoped and automatically released on commit/rollback. It is not a substitute for row constraints, authorization checks, idempotency or audit atomicity.

**Candidate order:** L00 → L05 audience guard → L10 when T-14 applies → L15 principals → L16 roles → L17 scope grants → conditional L18 catalog → L20 canonical identity when applicable → L30 project/session → L40 instrument/version → L50 assignment/location → L55 membership → L60 unit → L70 association → L80 claim → L90 inspection → L100 dependent aggregates → L110 append-only facts.

L05 is a new candidate rank and is **NOT APPROVED**. It must be inserted into every affected source/eligibility-writer manifest and global graph only after PO, Engineering, Database and Security review. If the global guard is used, all relevant writers must acquire it; partial participation invalidates the guarantee.

**Cost/trade-off:** the global guard serializes notification-eligible source transactions against all audience-eligibility mutations. This is the simplest correctness baseline but can become a throughput bottleneck. Before implementation, define a maximum wait/timeout, retry policy, fairness expectations and a measured fan-out/transaction budget. Do not silently shard the guard before the selector key model is approved.

### 4.2 Option B — SERIALIZABLE predicate snapshot

A second candidate is to execute the source mutation, recipient predicate reads and snapshot writes under PostgreSQL SERIALIZABLE isolation, with bounded retries for SQLSTATE 40001 and all eligibility-changing writers participating in the same serializable consistency model.

This option avoids introducing an advisory lock rank but requires:
- all relevant writer paths to participate in the serializable protocol;
- exact selector predicates and supporting indexes;
- explicit retry/idempotency behavior;
- a proof that mixed isolation levels cannot invalidate the intended eligibility guarantee;
- pre-acquisition of FK parent rows in canonical order to address row-lock edges independently of SSI.

This option is NOT APPROVED and must not be mixed casually with Option A. Database must compare contention, abort rates, query plans and operational complexity before selection.

### 4.3 Decision recommendation

For a low-scale first release, Option A's single global L05 guard is the more reviewable candidate because it makes writer participation explicit and gives a single deterministic serialization point. It is not approved by this recommendation. PO must approve the event-time linearization semantics; Engineering/Database/Security must approve lock identity, order, scope, timeout and all participating writers. If the global guard is rejected, the selected alternative must provide equivalent proof against concurrent grants, revocations, account disablement, assignment changes and parent closure.

## 5. Candidate source transaction sequence

After the common guard is approved, every eligible source command follows this template:

1. Begin transaction and claim idempotency (L00).
2. Acquire the approved audience serialization guard (candidate L05).
3. Read the immutable enabled policy version and exact selector schema. Reject unsupported/unknown event types; do not use wildcard selectors.
4. Discover the bounded candidate principal and scope identifiers.
5. Acquire the union of actor, target and candidate principal rows (L15) in sorted UUID order; then relevant role grants (L16), scope grants (L17), and conditional mutable catalog rows (L18), each in a deterministic order.
6. Acquire all candidate scope FK parent rows in the approved hierarchy: project/session (L30), instrument/version if referenced (L40), location/assignment (L50), assignment membership (L55). Include every FK parent, not only the source command's main aggregate.
7. Revalidate the selector predicates, account status, grant validity/effective intervals, assignment membership, parent status, source event type and policy version while the guard is held. Apply the source command's intended post-transition semantics explicitly (especially self/target role revoke, account suspension and assignment end).
8. Acquire remaining source-specific locks in the approved global order; perform the business mutation.
9. Append canonical source event, required audit event, idempotency result, outbox intent and all deduplicated candidate recipient/scope rows. Finalize the snapshot hash/count/completion marker only after every candidate row succeeds.
10. Commit. Any required audit/outbox/snapshot failure rolls back the protected source mutation. No provider, email, push, Storage or network I/O occurs in this transaction.

This is a design template only. It cannot be applied to CMD-012/013, CMD-023–032 or any other blocked source path until that command's own source lock order is normalized.

## 6. Candidate FK pre-acquisition and worker boundaries

### 6.1 Source transaction FK targets

Before inserting candidate rows, pre-acquire every referenced parent in the approved global order. Candidate references currently proposed by NLA-001 are:
- outbox_id → notification_outbox.id (same-transaction parent; insert after its required policy/source references);
- recipient_user_id → app_users.id (L15);
- project_id → projects.id (L30);
- session_id → sessions.id (L30, after project in deterministic order);
- location_id → locations.id (candidate L50 grouping; Database must approve exact rank);
- assignment_id → operational_assignments.id (L50);
- any approved composite FK must be expanded into its complete referenced-row set.

Exact FK definitions, delete behavior, nullability, unique keys and lock modes remain open. A KEY SHARE observation is not a substitute for verifying actual PostgreSQL behavior against exact DDL.

### 6.2 CMD-052 fan-out

- Claim one outbox row in a short transaction; persist owner/token-hash/generation/expiry and commit.
- In a separate transaction, read the immutable candidate set in deterministic recipient order.
- Do not re-resolve current roles, grants or assignments. Do not acquire the global audience guard for fan-out.
- Before inserting inbox rows, acquire the referenced FK parent rows in the approved order and stable key order; do not first lock a queue/notification row and then request a lower-ranked domain row.
- Insert inbox/delivery projections idempotently; use unique constraints as final arbiters.
- Never hold an outbox claim lock across fan-out or provider I/O.

The exact notification FK topology and whether parent pre-acquisition is needed for every column remain Database review items.

### 6.3 CMD-054 scheduler

- Read due candidates and pinned policy metadata without taking a mutable notification/policy lock first.
- Acquire the same approved audience guard (candidate L05) before locking mutable recipient eligibility or notification state.
- Revalidate due state, policy version and event-time candidate eligibility after the guard.
- Acquire notification/policy/recipient/scope rows in the final approved order; use the unique escalation key as the final idempotency arbiter.
- Persist escalation fact + its own outbox + complete event-time snapshot atomically.
- No provider I/O and no source business-state mutation.

The current CMD-054 order is not certified; the sequence above is a candidate redesign requiring approval.

### 6.4 CMD-053 callback and delivery

CMD-053 is not a recipient resolver. Keep provider I/O outside DB transactions. Callback ingress INT-NOTIF-001 must authenticate the provider event and deduplicate its provider identity before applying an allowlisted monotonic delivery transition. Do not introduce an audience guard unless the callback is separately approved to mutate recipient eligibility—which it is not in the current design.

## 7. Required writer participation inventory

The L05 candidate guard is only correct if every path that can change selector results participates. At minimum, review:
- account approval, rejection, suspension, disablement, reactivation and any login-eligibility transition;
- role grant, revoke, expiry, renewal and grantor/delegation change;
- scope grant, revoke, expiry, renewal and scope-parent reassignment;
- assignment creation/change/revoke and assignment-member start/end/expiry;
- Inspector capacity change and every operation changing the qualifying population;
- project/session close, reopen or scope transition that affects notification selectors;
- any administrative/import/sync/worker path that mutates these records;
- notification policy publish/retire/effective-interval changes that alter the event allowlist or selector grammar; CMD-051 must participate before taking its mutable policy aggregate lock;\n- all triggers, RPCs, helper functions and direct database privileges capable of bypassing command-level participation.

If a writer is outside this repository's application boundary, its participation must be enforced by database policy or the design must use an isolation model that safely handles it. A command inventory alone is not proof of complete writer coverage.

## 8. Adversarial verification plan — specification only

| Test ID | Race | Required evidence |
|---|---|---|
| NRL-T01 | Source event vs role grant/revoke/expiry | One serial winner; candidate set matches approved event-time point; no mixed state |
| NRL-T02 | Source event vs account suspension/disable/reactivation | No candidate eligibility race; dispatch suppression remains independent |
| NRL-T03 | Source event vs scope grant/revoke/expiry | Scope tuple and recipient set are consistent; no widening |
| NRL-T04 | Source event vs assignment-member start/end/expiry | Exact effective interval and assignment scope are honored |
| NRL-T05 | Source event vs project/session closure | Parent fence and snapshot path serialize; no post-close child event |
| NRL-T06 | CMD-014/015 T-14 capacity change vs resolver | Capacity predicate and candidate selector do not deadlock or use stale eligibility |
| NRL-T07 | Two source events with overlapping candidate sets | Stable principal/grant/scope lock ordering; no deadlock |
| NRL-T08 | CMD-052 fan-out vs grant revocation and parent deletion/closure | Immutable candidate set is consumed; FK behavior is safe; stale workers cannot finalize |
| NRL-T09 | CMD-054 duplicate scheduler ticks vs CMD-051 policy publish and recipient revoke | One escalation event; pinned policy; immutable snapshot; no reverse-rank edge |
| NRL-T10 | Inject FK violation, unique conflict, deadlock and serialization failure | Atomic rollback, typed retry outcome, idempotent replay and observable SQLSTATE/lock graph |

All tests are PLANNED / NOT EXECUTED. Execution requires G10 activation and an approved isolated database environment.

## 9. Required decisions and closure evidence

| ID | Decision/evidence | Owner | Status |
|---|---|---|---|
| NRL-D01 | Approve exact event-time linearization point and post-transition audience semantics | PO + Security | OPEN |
| NRL-D02 | Select Option A global L05 guard, Option B SERIALIZABLE, or another proven equivalent | PO + Engineering + Database + Security | OPEN |
| NRL-D03 | If L05 is selected, approve canonical lock key, transaction scope, timeout, retry and writer participation | Engineering + Database + Security | OPEN |
| NRL-D04 | Approve selector grammar, exact event allowlist, recipient bound and scope tuple | PO + Security | OPEN |
| NRL-D05 | Approve exact snapshot FK/composite-FK/unique/index/delete definitions and row lock modes | Database + Security | OPEN |
| NRL-D06 | Normalize all 40 source command lock manifests against the chosen resolver prefix; resolve existing CMD conflicts | Engineering + Database + Security | OPEN |
| NRL-D07 | Prove all eligibility-changing writers and non-command mutation paths participate | Engineering + Security + Operations | OPEN |
| NRL-D08 | Prove worker transaction separation and CMD-054 lock order | Engineering + Security | OPEN |
| NRL-D09 | Complete effective graph and static cycle analysis including FK/index/trigger/function/advisory edges | Engineering + Database | OPEN |
| NRL-D10 | Execute NRL-T01..T10 on authorized isolated PostgreSQL and attach reproducible traces | Engineering + QA + Security | NOT EXECUTED |

## 10. Gate and certification disposition

| Evidence | Current status |
|---|---|
| CMD-001–040 source event declaration inventory | 40/40 mapped in LOCK-MANIFEST-001 §7.7 |
| Source-specific candidate lock paths | 40/40 documented; not technically certified |
| Complete resolver lock set before source aggregate | 0/40 certified |
| Eligibility writer participation | OPEN |
| Event-time linearization and selector allowlist | OPEN |
| Candidate FK topology / exact lock modes | OPEN; relation NOT ADMITTED |
| Global lock graph acyclic | NOT PROVEN |
| Application lock certification | 0/50 |
| QA TC-NOTIF-001..051 and related RLS/function-security cases | PLANNED / NOT EXECUTED |
| G9 | NOT READY |
| G10 | NOT ACTIVE |

This document advances static analysis only. It does not close RAID R-037 or RTM NOTIF-015, admit a physical relation, approve a new rank, certify any command, authorize code/SQL/migration/grants, or change G9/G10.
