# Notification Audience Guard — Technical Decision Record

**Document ID:** NLA-L05-TDR-001  
**Version:** 0.1.14  
**Status:** PO-APPROVED CANDIDATE — technical approval pending Engineering, Database and Security  
**Date:** 2026-11-25  
**Decision authority:** Product Owner candidate selection recorded in NLA-RESOLVER-LOCK-001 §11  
**Parent design:** NLA-RESOLVER-LOCK-001 v0.1.11  
**Scope:** PostgreSQL transaction serialization for event-time notification audience resolution; CMD-001–040 source-event paths, CMD-051 policy publication, CMD-052 fan-out and CMD-054 escalation

## 1. Decision requested

Admit a single global, transaction-scoped PostgreSQL advisory lock as the primary audience-eligibility serialization mechanism, provisionally assigned candidate rank **L05**, for the first implementation slice.

The Product Owner selected this mechanism as the primary candidate. This TDR recommends a concrete primitive and protocol for Engineering, Database and Security review. It does **not** itself approve L05, assign final numeric lock-key constants, admit the rank into the canonical lock graph, or authorize SQL, migration, grants, RLS, functions, or implementation.

**Proposed decision:** use `pg_advisory_xact_lock(int, int)` with one reserved, fixed two-integer key pair representing the global notification-audience domain. Do not hash tenant IDs, selectors, event types or user IDs in the initial design. Do not shard the guard in the first release.

## 2. Context and correctness invariant

The reviewed source inventory contains 40/40 source event declarations, but no complete resolver lock path is certified (0/40). The application command lock certification remains 0/50. The candidate recipient snapshot relation and outbox snapshot header remain NOT ADMITTED.

The required invariant is:

> For each eligible source event, the persisted candidate recipient/scope set must correspond to one serial point in the order of all committed eligibility-changing operations and the event's own source mutation. Retries consume that immutable set; later authorization checks may suppress but never widen it.

A preflight SELECT is not a serialization mechanism. A row lock on only the actor or target is not a complete audience predicate fence. The guard is correct only if every transaction capable of changing the policy or any predicate used by the resolver participates before taking conflicting mutable locks.

## 3. Proposed PostgreSQL primitive and key identity

### 3.1 Primitive

Use transaction-level advisory locking:

```sql
SELECT pg_advisory_xact_lock(:namespace_key, :audience_guard_key);
```

The parameter types are PostgreSQL signed 32-bit integers. The selected pair must be reserved in a repository/database-wide advisory-lock registry before implementation. The registry must establish that no other feature or function uses the same pair. The actual integer values are intentionally **TBD** until that registry and the deployed database inventory are reviewed.

Why this primitive:
- transaction-scoped lifetime: PostgreSQL releases the lock automatically on COMMIT or ROLLBACK;
- one stable global key avoids selector-hash collisions and multi-key ordering ambiguity;
- no persistent lock row, cleanup job or lease-expiry protocol is needed;
- it can be acquired before any source-domain row locks and held across the atomic source + outbox + snapshot transaction.

Do not use session-level `pg_advisory_lock` / `pg_advisory_unlock`: pooled connections and transaction boundaries make session ownership unsafe for this invariant. Do not use a hash of selector strings as a first-release key. A future sharded scheme requires a new decision, canonical byte encoding, collision analysis and globally sorted multi-key acquisition.

### 3.2 Key allocation controls

The reserved key pair must be:
- documented once in the canonical advisory-lock registry;
- identical in every source, eligibility-writer and scheduler path;
- inaccessible as a client-controlled input;
- referenced through one internal helper, not duplicated literals across functions;
- covered by a static repository search and a live `pg_locks` verification after G10.

The helper is a convenience, not an enforcement boundary by itself. Direct DML and alternate writers must be denied or routed through reviewed trusted functions so no eligibility mutation can bypass the guard.

## 4. Transaction protocol and isolation requirements

### 4.1 Required isolation

**Proposed required isolation: READ COMMITTED**, verified for every relevant PostgREST/worker transaction path. The resolver depends on a fresh statement snapshot after a transaction has waited for L05.

At READ COMMITTED, each SQL command obtains a fresh snapshot. Therefore:
1. acquire L05 in its own SQL command;
2. only after that command returns, issue a separate SQL command to read the current policy and recipient eligibility;
3. do not combine lock acquisition and recipient SELECT into one SQL statement or CTE;
4. revalidate and persist the snapshot while L05 remains held.

This separation is material: a statement that waits for an advisory lock already has a statement snapshot. Combining the lock wait and candidate read in one statement can observe a snapshot taken before the wait. REPEATABLE READ uses a transaction snapshot and is not accepted for this protocol without a separately proven snapshot-refresh strategy. SERIALIZABLE remains the unselected contingency and must not be layered on casually.

The actual transaction isolation used by Supabase/PostgREST, user command wrappers, CMD-052 and CMD-054 is not yet verified. Database must prove it from the deployed configuration and integration evidence before approval.

#### 4.1.1 RPC wrapper volatility and fresh-snapshot contract

Every PostgREST RPC command wrapper that acquires L05 and then resolves an audience **must be declared `VOLATILE`**. It must not be declared `STABLE` or `IMMUTABLE`. For a PL/pgSQL wrapper, lock acquisition and audience resolution must be distinct procedural SQL commands, for example a `PERFORM pg_advisory_xact_lock(...)` followed by a separate `SELECT` statement. Do not combine them in one SQL expression, CTE, or single SQL-function statement.

This is required because PostgreSQL VOLATILE functions obtain a fresh snapshot for each query they execute, whereas STABLE/IMMUTABLE functions use the calling query's snapshot. Actual wrapper/helper volatility metadata, function language, call path and READ COMMITTED behavior must be inspected and tested through the authenticated PostgREST RPC path before technical approval. This is a proposed design requirement, not evidence that deployed functions already comply.

Reference: https://www.postgresql.org/docs/current/xfunc-volatility.html

### 4.2 Source transaction order

For each command that can emit an allowlisted notification event:

1. Begin transaction under the verified isolation contract.
2. Perform only the approved L00 idempotency arbitration; no principal, role, scope, project, assignment, notification or other domain aggregate row lock may be taken yet.
3. Acquire L05 in a dedicated SQL command using the fixed internal key pair.
4. Immediately after the L05 lock call returns, capture exactly one database wall-clock instant into a `timestamptz` variable as `audience_evaluated_at := clock_timestamp()`. This is the audience eligibility linearization instant for this transaction.
5. In a subsequent SQL command, read the immutable effective notification policy version and resolve the bounded event-time recipient/scope candidate set using that captured instant for every time-dependent predicate. Do not use `now()`, `CURRENT_TIMESTAMP`, `transaction_timestamp()` or `statement_timestamp()` as the post-wait audience evaluation instant.
6. Acquire the union of actor, target and candidate principal rows in stable UUID order (L15), then applicable role rows (L16), scope-grant rows (L17), and conditional catalogue rows (L18).
7. Acquire every required FK parent in the approved canonical order (L20 and L30–L55 classes as applicable); then acquire remaining source-specific domain locks in the admitted global order.
8. Revalidate policy version, account state, role/scope validity, assignment membership/effective dates, capacity and parent lifecycle while L05 is still held. Apply explicit post-transition semantics for self-revoke, account suspension, membership end and closure.
9. Perform the source mutation; append canonical event, required audit, idempotency result, outbox intent and all immutable snapshot rows in the same transaction.
10. Verify the snapshot row count/hash/completion marker against the exact inserted set, then commit. Any failure in the required atomic unit rolls back the source mutation.

A command with an event type statically and immutably excluded from notification policy matching may omit L05 only when the exclusion is explicit in its command manifest and cannot be changed by policy publication. Runtime policy lookup cannot be used to skip L05 before the lock.

### 4.2.1 Historical pre-PO review checkpoint — superseded by approved POQ-04

The current transaction sequence resolves the candidate audience after L05 and before applying the source mutation. This naturally defines a **pre-transition eligibility snapshot** at `audience_evaluated_at`. Recommended default: candidate eligibility is evaluated against the state serialized before the command's source mutation; the source mutation, canonical event and immutable candidate snapshot then commit atomically. A transition must not retroactively rewrite the captured candidate set.

For explicit event participants (actor, target, affected account/member), inclusion must be represented by an approved event participant/selector rule; do not silently append the actor or target outside the policy's exact selector grammar. Dispatch-time account/channel/consent and mandatory security checks may suppress an existing candidate under POQ-01, but may never add a new candidate. Scope revalidation may also suppress only under the approved POQ-01 contract.

**Historical note:** this paragraph records the pre-approval state only. The Product Owner subsequently approved all five transition outcomes in §4.2.2 and DECISION-REGISTER.md POQ-04 on 2026-11-24. The product-decision dependency is resolved; technical validation requirements remain open.

### 4.3 Candidate total order

`L00 → L05 → L10 (when T-14 applies) → L15 → L16 → L17 → conditional L18 → L20 → L30 → L40 → L50 → L55 → L60 → L70 → L80 → L90 → L100 → L110`

This is a proposed order, not an admitted graph. L05 must precede every mutable domain lock in a participating transaction. T-14 L10 ordering and all existing command-specific conflicts must be reconciled before any source path is certified. No transaction may acquire a lower-ranked row after a higher-ranked row.

The captured `audience_evaluated_at` is one immutable instant for the eligibility decision. Effective intervals use half-open semantics `[valid_from, valid_until)`: an item is effective when `valid_from <= audience_evaluated_at` and `(valid_until IS NULL OR audience_evaluated_at < valid_until)`. This is a proposed technical convention and requires PO confirmation wherever it changes an existing approved domain contract. Policy, role, scope, assignment/member and parent-state predicates must all use the same captured value; no per-row wall-clock sampling is allowed.

The canonical source event's business timestamp remains a separate fact unless the domain event contract explicitly equates it with `audience_evaluated_at`. Persist both when they represent different concepts; never silently rewrite a business-event timestamp to the audience evaluation instant.

Reference: https://www.postgresql.org/docs/current/functions-datetime.html

## 5. Mandatory writer participation matrix

All rows below are in-scope for the guard unless a static proof shows the mutation cannot affect any enabled selector. The final command-ID mapping is a mandatory approval artifact; this category list is not a substitute for that matrix.

See [NLA-L05-WRITER-MATRIX-001](L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md) v0.1.4 for the current static command/non-command writer inventory. That artifact is intentionally PARTIAL: selector dependency grammar, deployed function/trigger/job inventory, direct-DML bypass evidence and actual writer ownership remain unknown. It does not close the complete-writer requirement.

| Writer class | Required behavior |
|---|---|
| Account approval/rejection, suspension, disablement, reactivation | Acquire L05 before app_users/account eligibility locks and mutation |
| Role grant/revoke/expiry/renewal/delegation | Acquire L05 before user_roles/roles/delegation rows |
| Scope grant/revoke/expiry/renewal/reassignment | Acquire L05 before user_scope_grants and scope-parent mutation |
| Assignment create/change/revoke and member start/end/expiry | Acquire L05 before assignment/member eligibility locks |
| Capacity and qualifying-population changes (T-14) | Acquire L05 before L10 and relevant eligibility rows, subject to final L05/L10 order approval |
| Project/session open/close/reopen and scope transitions | Acquire L05 before project/session parent locks when those states participate in selectors |
| Relevant location/unit/association lifecycle changes | Acquire L05 before any row that changes selector qualification |
| Import, bulk admin, sync, repair, background and support tools | Same protocol; no privileged bypass |
| CMD-051 policy publish/retire/effective-window change | Acquire L05 before mutable policy aggregate lock/update; source resolver reads policy only after L05 |
| CMD-054 escalation resolver | Acquire L05 before mutable recipient/policy/escalation locks; re-read due state after L05 |
| Read-only queries and CMD-052 immutable snapshot consumption | Do not acquire L05 unless they mutate eligibility; CMD-052 must never re-resolve |

**Hard failure condition:** one unreviewed writer that can change eligibility without L05 invalidates the serialization proof. Direct table DML, triggers, cascades, admin scripts and scheduled maintenance must be included in the writer inventory. A trigger that acquires L05 after a caller has already locked a higher-ranked row is not an acceptable substitute for correct wrapper-level acquisition.

## 6. CMD-051 policy publication serialization

Policy publish is an eligibility writer because it changes the selector grammar, event-type allowlist, priority/channels, scope and effective version used by future source events.

Proposed sequence:
1. perform authorization preflight without taking the mutable policy-row lock;
2. acquire L05;
3. re-read current published version and compare expected-current-version;
4. validate selector schema/allowlist and effective interval;
5. acquire policy rows and append the publish/audit facts in their approved order;
6. commit.

Source transactions acquire L05 first and read the effective policy in a later statement. Thus either the source transaction serializes before publication and uses the prior version, or after publication and uses the new version. The exact overlap/effective-time semantics remain a policy-schema approval item.

## 7. Timeout, failure and retry contract

No numeric timeout, retry count or backoff is invented here. They must be set from the approved database performance SLO and tested workload.

- Apply a transaction-local `lock_timeout` before attempting L05, using an approved bounded value. The setting must be effective before the lock command executes.
- Apply a separate transaction/statement execution budget; a lock wait timeout is not a substitute for a total transaction budget.
- On lock timeout (SQLSTATE `55P03`), deadlock detected (`40P01`) or serialization failure (`40001`, if encountered by a separately approved path), roll back the **entire** transaction. Never continue with a partial source/outbox/snapshot write.
- Retry only transient failures, with bounded attempts and jitter selected by Operations. Preserve the original idempotency key and request hash. Re-enter the full transaction and reacquire L05.
- Do not retry authorization, validation, policy, FK-integrity or business-conflict failures as if transient.
- Resolve ambiguous client/worker outcomes through the durable idempotency record; do not create a second source event or a second logical outbox.
- Record safe structured metrics: guard wait duration, hold duration, timeout count, deadlock count, retries, audience cardinality and transaction duration. Never log recipient payloads, tokens, secrets or evidence.

The actual PostgREST error mapping and worker retry owner must be tested; clients must not independently retry with a new idempotency key.

## 8. Contention and bounded-audience performance

The global guard intentionally serializes all participating source and eligibility-writer transactions. This is the safest initial shape but the highest-contention option.

The guard hold time includes policy resolution, candidate discovery, required row-lock acquisition, source mutation and atomic snapshot persistence. It must exclude network/provider I/O, email/push dispatch, object storage, rendering and other external work.

A first-order upper bound for serialized guard throughput is approximately `1 / mean_guard_hold_seconds`; actual throughput is lower due to database work, queueing and contention. This is a planning bound, not an SLO.

Before approval:
- Product/Engineering must set a maximum candidate audience cardinality and behavior when it is exceeded (fail closed; do not truncate or silently page a partial immutable audience);
- Database must benchmark the largest allowed audience and worst-case FK parent set;
- Operations must set numeric lock wait, transaction, retry and queue-age budgets;
- record p50/p95/p99 wait/hold/transaction latency, timeout rate, deadlocks, rows per snapshot and WAL/IO impact;
- demonstrate that normal command traffic and eligibility updates remain within the approved SLO under mixed load.

No sharding is allowed as an unreviewed optimization. If the global guard cannot meet the approved SLO, return to a new decision comparing SERIALIZABLE, scope-sharded advisory keys or a temporal/versioned eligibility model.

## 9. FK, unique-index, trigger and helper-function edge review

The candidate snapshot relation and outbox header remain NOT ADMITTED. Before admission, Database must obtain exact proposed DDL and enumerate every FK and its referenced unique key, nullability, delete action, supporting index, trigger and helper function.

At minimum, review candidate references to:
- notification_outbox;
- app_users;
- projects and sessions;
- locations;
- operational_assignments and assignment membership;
- any additional scope or policy reference introduced by the selector model.

For every insert/update/delete path, document implicit FK row-lock behavior (including KEY SHARE), unique-index arbitration and trigger/helper side effects. Explicitly pre-acquire all required parent rows in the approved global order before child inserts. Do not use `NOT VALID`, disable constraints, weaken referential integrity or omit FKs merely to suppress lock edges. Exact FK lock behavior must be verified against the final DDL in an isolated PostgreSQL environment.

CMD-052 must claim an outbox row in a short transaction, commit, then perform fan-out in a separate transaction. It reads only the immutable candidate set, does not acquire L05, does not re-resolve roles/grants/assignments, and does not hold an outbox claim-row lock while inserting inbox rows or calling providers. CMD-053 provider I/O stays outside database transactions.

## 10. CMD-054 scheduler protocol

1. Read due candidate IDs and pinned policy metadata as preflight only; no mutable policy/notification row lock is taken. Any preflight timestamp is advisory only and must not decide effective eligibility.
2. For each bounded work unit, begin a READ COMMITTED transaction and acquire L05 before mutable recipient/policy/escalation locks.
3. Immediately after L05 returns, capture one `timestamptz audience_evaluated_at := clock_timestamp()` for that work unit.
4. In a subsequent SQL command, re-read due state, current policy validity and event-time candidate eligibility using that exact captured instant.
5. Acquire all principal/scope/FK parents and remaining notification/escalation rows in the approved order.
6. Insert the unique escalation fact, outbox intent and immutable candidate snapshot, persisting the same evaluation instant atomically.
7. Commit. No provider I/O and no domain workflow state mutation.

Scheduler duplicate ticks converge through a unique escalation idempotency key. Exact due-state and policy-version semantics remain open until PO/Operations approval.

## 11. Lock graph and deadlock proof obligations

The graph must include more than explicit `FOR UPDATE` calls:
- advisory lock L05 and its acquisition point;
- L00 idempotency arbiter;
- L10 T-14 capacity fence;
- all row-lock modes and stable multi-row ordering;
- FK KEY SHARE/NO KEY UPDATE/UPDATE effects;
- unique-index conflict waits;
- triggers, cascades, deferred constraints and helper functions;
- CMD-052 lease claim and finalization;
- CMD-054 scheduler and policy publication;
- every admin/import/sync/repair writer.

Required proof:
1. every participating transaction acquires L05 before any domain row lock;
2. no code path acquires L05 from a trigger or helper after a higher-ranked row is held;
3. all multi-row lock sets use a stable total key order;
4. no path takes a lower-ranked resource after a higher-ranked one;
5. all FK/unique/trigger/helper edges are represented;
6. static graph analysis reports no cycle for the approved set;
7. adversarial PostgreSQL tests confirm the predicted waits/rollbacks under concurrent schedules.

Until all seven are evidenced, the global graph is NOT PROVEN ACYCLIC.

## 12. Adversarial test plan

All tests are PLANNED / NOT EXECUTED. Run only after G10 activation in an isolated PostgreSQL environment with exact DDL, functions, grants and transaction isolation.

| Test | Concurrent schedule | Required result |
|---|---|---|
| NRL-T01 | Source event vs role grant/revoke | Exactly one serial order; persisted audience matches that order; no widening on retry |
| NRL-T02 | Source event vs account suspension/disable | No recipient outside the committed event-time eligibility result |
| NRL-T03 | Source event vs scope grant/revoke/expiry | Snapshot and source event serialize; no partial candidate set |
| NRL-T04 | Source event vs assignment/member effective-date transition | Exact effective-time semantics; no phantom/missing member |
| NRL-T05 | Source event vs project/session close/reopen | Closure and event resolution have a deterministic serial order |
| NRL-T06 | Source event vs T-14 capacity change | L05/L10 order is consistent; no over-capacity eligibility race |
| NRL-T07 | Two overlapping source events plus policy publish | Policy version and audience snapshots are deterministic; no duplicate logical outbox |
| NRL-T08 | CMD-052 fan-out vs revoke/closure after source commit | Fan-out consumes only immutable snapshot; no re-resolution/widening; FK safety |
| NRL-T09 | Duplicate CMD-054 ticks vs CMD-051 policy publish | One escalation key; deterministic policy snapshot; no deadlock |
| NRL-T10 | FK/unique conflict, lock timeout, deadlock and forced transaction abort | Entire atomic unit rolls back; bounded retry replays same idempotency key; no orphan snapshot/outbox |
| NRL-T11 | Authenticated PostgREST RPC waits for L05 while an eligibility writer commits | VOLATILE wrapper executes lock and resolver as distinct internal SQL commands; post-wait resolver sees the committed change under READ COMMITTED; combined-statement negative control demonstrates stale snapshot |
| NRL-T12 | Source transaction waits on L05 across a role/assignment/policy effective-time boundary | One post-lock `clock_timestamp()` instant drives all temporal predicates and the persisted snapshot; transaction-start timestamp is not used |
| NRL-T13 | Mixed source-event and eligibility-writer workload at the PO/Operations-approved maximum audience cardinality | Record p50/p95/p99 L05 wait/hold/transaction latency, throughput, timeout/deadlock/retry rates, queue age, audience cardinality and database I/O; meet approved SLO without partial audiences or starvation |

Additional assertions:
- demonstrate the stale-snapshot hazard when lock and resolver read are combined into one statement, then verify the separate-statement READ COMMITTED protocol;
- verify every writer uses the same registered key pair;
- inspect `pg_locks` while blocked and after commit/rollback;
- prove no advisory session lock remains in pooled connections;
- prove CMD-052 and CMD-053 perform no provider I/O inside a database transaction.

## 13. Approval checklist and open decisions

| Review item | Proposed disposition | Required approver/evidence |
|---|---|---|
| Primitive | `pg_advisory_xact_lock(int,int)` | Database + Security |
| Global key pair / namespace registry | TBD; no constants assigned | Database |
| READ COMMITTED and separate-statement snapshot contract | Required | Database + Engineering; verify PostgREST/worker configuration |
| L05 relative to L00/L10 and all row ranks | Proposed | Engineering + Database |
| Complete writer-to-command matrix, including CMD-051 and admin paths | OPEN | Engineering + Security |
| Exact helper ownership/search_path/EXECUTE ACL and direct-DML denial | OPEN | Security |
| Exact FK/unique/trigger/helper topology | OPEN | Database |
| Timeout/retry/transaction budget | OPEN | Database + Operations |
| Audience cardinality and performance SLO | OPEN | PO + Engineering + Operations |
| Function volatility and post-wait snapshot proof through authenticated RPC | OPEN — design requirement added; deployed metadata/evidence absent | Engineering + Database + Security |
| Post-L05 audience evaluation instant and effective-interval boundary approval | OPEN — proposed `clock_timestamp()` capture; PO/domain confirmation and test evidence pending | PO + Engineering + Database + Security |
| Pre-/post-transition recipient inclusion semantics for revoke/suspend/end/close/self-revoke | OPEN — reviewer proposal documented; explicit PO decision required | PO + Security + Engineering |
| Global-guard contention benchmark and measurable workload acceptance | OPEN — benchmark protocol required; numeric SLOs remain TBD | PO + Engineering + Database + Operations |
| Static acyclicity and NRL-T01..T13 evidence | NOT EXECUTED | Engineering + Database + Security |

**No numeric constants are approved:** advisory key integers, lock timeout, statement/transaction timeout, retry count, jitter, audience maximum and latency SLO remain TBD.

## 14. Gate and implementation boundary

- PO candidate selection: APPROVED (2026-11-24).
- Technical approval of this TDR: PENDING.
- Canonical L05 rank admission: NOT APPROVED.
- Complete resolver lock paths: 0/40 certified.
- Application lock certification: 0/50.
- Candidate snapshot relation/header: NOT ADMITTED.
- Static global graph acyclicity: NOT PROVEN.
- QA NRL-T01..T13 / TC-NOTIF-042..054: PLANNED / NOT EXECUTED.
- G9: NOT READY. G10: NOT ACTIVE.

This is a documentation-only technical proposal. It authorizes no source code, SQL, migration, function, grant/revoke, RLS change, live database inspection, CI/runtime test, provider setup, deployment or merge.


## 15. Product Owner approval record — 2026-11-24

**Decision:** APPROVED by the Product Owner as the preferred technical candidate and as the baseline for formal Engineering, Database and Security review.

**Approved scope of this decision:**
- endorse the proposed `pg_advisory_xact_lock(int,int)` global transaction guard as the primary candidate for L05;
- endorse the proposed READ COMMITTED / separate-statement resolver snapshot protocol for detailed technical review;
- direct Engineering, Database and Security to validate the complete writer participation matrix, lock graph, FK/unique/trigger/helper edges, transaction isolation, timeout/retry policy and measured contention before implementation;
- use this TDR as the review baseline and update it only through controlled, evidence-backed decisions.

**Explicitly not approved by this PO decision:**
- final admission of L05 into the canonical global lock graph;
- actual advisory key integer values or namespace reservation;
- deployed transaction isolation configuration;
- exact command/function/helper signatures, owner roles, search_path, ACL, grants/revokes or RLS;
- candidate snapshot relation/header DDL, constraints or indexes;
- numeric lock/statement/transaction timeouts, retry count/backoff, audience cap or performance SLO;
- any SQL, migration, source code, CI/runtime test, database mutation, provider setup, deployment or production operation.

**Revision 0.1.2 review note:** F-01 and F-02 have been translated into explicit proposed requirements: VOLATILE RPC wrapper with separate internal SQL statements; and one `clock_timestamp()` capture immediately after L05 for all effective-time predicates. These amendments do not prove deployed function metadata, isolation or runtime behavior and do not close the review findings until independent evidence is supplied.

**Authority separation:** This is Product Owner approval of the candidate design direction, not Engineering, Database or Security technical certification. Those approvals and their evidence remain mandatory. G9 remains NOT READY and G10 remains NOT ACTIVE until the repository's gate requirements are independently satisfied and recorded.



## 4.2.2 Approved explicit transition outcomes — POQ-04 (PO APPROVED)

This section records the complete five-row product decision approved by the Product Owner on 2026-11-24 and canonicalized in DECISION-REGISTER.md. These are approved product semantics, not a technical certification or implementation authorization.

| Transition | Event-time snapshot (pre-mutation) | Dispatch-time behavior |
|---|---|---|
| Role revoke (CMD-005) | Evaluate the exact policy selector against pre-revoke role/scope state. Include the target only if selected and eligible; never auto-append actor or target. | Revalidate current role/scope. Suppress a candidate whose required role/scope is no longer effective. Never widen. |
| Account reject/disable/suspend (CMD-002/003) | Evaluate against pre-transition account state; a selected account may be persisted as a candidate. | Suppress while account is not enabled. A later retry after reactivation may proceed only for that same immutable candidate, subject to all other current checks. |
| Assignment-member end (CMD-015) | Evaluate pre-end membership at the one captured instant and the approved half-open interval rule. | Suppress if required current assignment/member scope is no longer effective. Never substitute another member. |
| Project/session close (CMD-010/013) | Evaluate against pre-close parent state; snapshot and closure event commit atomically. | Apply current active-scope policy; suppress when closure makes the required scope invalid. Never add a post-close recipient. |
| Self-revoke by actor | Include actor only when the exact selector selects the actor under pre-revoke eligibility. No implicit inclusion/exclusion. | Revalidate the actor's current role/scope; suppress if no longer eligible under the applicable current-scope policy. |

**Common invariant:** event-time candidate membership is immutable. Dispatch-time suppression is a distinct, auditable delivery decision and may not rewrite the snapshot or add recipients. Candidate retries reuse the same event-time set/checkpoint. Any retry after account reactivation remains limited to a candidate already present in that set.

**PO status: APPROVED (2026-11-24).** Security/Engineering review remains mandatory before technical admission, particularly for current-scope suppression after revoke/closure, retry eligibility after reactivation, selector determinism and audit evidence. No implementation, DDL, grants, RLS, live DB or runtime test is authorized by this product decision.



## 4.2.3 POQ-04 approval and remaining technical disposition — 2026-11-24

The Product Owner approved all five transition outcomes in §4.2.2 without changes. POQ-04 is therefore closed as a product decision. F-05 remains OPEN pending Security/Engineering validation of the exact selector grammar, current-scope suppression rules, retry-after-reactivation behavior, parent-state semantics, auditability and consistency with the selected L05 protocol. This approval does not admit a physical snapshot relation/header, lock rank, PostgreSQL primitive, function contract or runtime behavior. Resolver certification remains 0/40; application lock certification remains 0/50; G9 NOT READY; G10 NOT ACTIVE.


## 4.2.4 F-05 technical validation contract — OPEN (2026-11-24)

POQ-04 is approved at Product Owner level. The following technical items are mandatory before F-05 can be closed. This section defines review/evidence requirements; it does not invent missing product policy or admit implementation details.

| ID | Required technical definition / evidence | Current finding | Required owner |
|---|---|---|---|
| F05-T1 Selector grammar and allowlist | Versioned, typed grammar with explicit event-type allowlist; permitted selector kinds; role and scope identifiers; named actor/self/target semantics; boolean composition; null/missing-field behavior; effective-time rules; deterministic canonicalization; overlap/dedup semantics; maximum depth/cardinality; invalid-selector fail-closed behavior; policy-version pin | NLA-001 §5 gives only broad selector examples. Exact grammar, dependency columns and bounds are not defined. | Engineering + Security; PO only if product behavior changes |
| F05-T2 Dispatch authorization matrix | For each selector/event type, identify which captured qualification predicates are rechecked at dispatch, which current security predicates are always rechecked, and which transition-specific parent/scope checks apply. Distinguish recipient qualification from independent authorization to receive/open the notice. | Generic current-scope wording is insufficient. Role-revoke and project/session-close notices can be suppressed by the very transition they announce unless an event-specific rule is explicit. | Security + Engineering |
| F05-T3 Suppression/retry state machine | Enumerate stable reason codes and classify each as terminal, retryable, or policy-reschedulable; define retry owner, attempt ceiling/backoff/expiry, checkpoint handling, and permitted recovery triggers. Reactivation may only resume an original snapshot candidate and must re-run every current mandatory check. | POQ-04 permits retry after account reactivation for the same candidate but does not define timing, state transition, retry limits or interaction with consent/channel/policy changes. | Engineering + Security + Operations |
| F05-T4 Audit evidence | Define append-only event/attempt records, reason-code taxonomy, correlation IDs, actor/worker identity, policy and snapshot references, timestamps, outcome transitions, integrity/retention controls and data-minimization rules. | Logical evidence envelope and provenance/correlation/privacy candidate contract documented in §17; physical representation, stable literal reason codes, integrity mechanism and T-10 policy remain unapproved. | Security + Engineering + Database + Records/Privacy authority |
| F05-T5 Atomicity and snapshot binding | Prove source mutation, canonical event, audit, idempotency outcome, outbox intent, pinned policy reference and complete immutable candidate set share the approved transaction boundary and captured audience_evaluated_at. | Candidate snapshot relation/header remains NOT ADMITTED; producer paths and writer participation remain uncertified. | Engineering + Database + Security |

### Event-specific hazards requiring explicit review

1. **Role revoke / self-revoke:** the event-time selector may include a target/actor under pre-revoke state, while dispatch-time authorization may suppress them immediately after revocation. Security must distinguish recipient qualification from access to the protected resource; the notice itself must never grant resource access.
2. **Account suspension/reactivation:** only a recipient already in the immutable snapshot can be reconsidered after reactivation. Consent revocation, channel disablement, policy expiry, account re-suspension and other mandatory restrictions must be re-evaluated. Reactivation must not clear unrelated suppression reasons or reset the candidate checkpoint.
3. **Assignment-member end:** current assignment membership may suppress a captured candidate, but the system must not substitute a new member or rebuild the audience.
4. **Project/session close:** a blanket parent-must-currently-be-active dispatch predicate can suppress the closure notification for every intended recipient. Security/Engineering must define an explicit per-event dispatch rule and demonstrate the PO-approved outcome; do not infer a universal active-parent requirement.
5. **Selector overlap:** one principal matching multiple selectors must yield one candidate identity per outbox/scope according to a canonical deduplication key; channel fan-out must not duplicate the recipient snapshot.

### F-05 technical exit criteria

- F05-T1..T5 have reviewed, versioned specifications and named approvers.
- Every enabled event selector has an explicit deterministic selector definition and a traceable dependency-column set.
- Dispatch/suppression behavior is deterministic for all five POQ-04 transitions and ordinary events, including closure notices.
- Suppression reason codes and retry state transitions are exhaustive, append-only/auditable and do not mutate the candidate set.
- Security and Engineering approvals are recorded; Database approves transaction/schema/lock integration where applicable.
- TC-NOTIF-055..064 are mapped to the final definitions, then executed only after G10 activation in the authorized isolated environment.
- No unresolved conflict remains between POQ-01, POQ-04, NLA-001, TDR, worker state machine, RLS/ACL and QA.

Until all criteria are met, F-05 remains OPEN. No lock rank, physical relation, function, SQL, migration, grants, RLS, runtime behavior or G10 activation is approved by this addendum.


## 4.2.5 F05-T1 — candidate selector grammar v1 (for Engineering/Security/PO approval)

**Status: REVIEW CANDIDATE — NOT APPROVED FOR POLICY PUBLICATION OR IMPLEMENTATION.** This grammar deliberately supports only the two selector families already described by NLA-001 §5: (a) role plus effective scope membership and (b) explicitly named event participant. It is not arbitrary query language and does not define physical columns or SQL.

### A. Abstract grammar

PolicySelectorV1 is an object with:
- grammar_version: integer exactly 1
- match: exactly ANY
- selectors: array containing 1 to 8 SelectorClause entries

SelectorClause is exactly one of:

1. RoleScopeClause:
   - kind: ROLE_SCOPE
   - role_ref: canonical role key from the approved role registry
   - scope.kind: PROJECT, SESSION, LOCATION or ASSIGNMENT
   - scope.binding: SOURCE_EVENT_SCOPE

2. EventParticipantClause:
   - kind: EVENT_PARTICIPANT
   - participant: ACTOR, TARGET or AFFECTED_MEMBER

Semantics:
- ANY means OR across the top-level selector clauses. There is no nested expression tree.
- A ROLE_SCOPE clause is conjunctive: the principal has the canonical role and the corresponding membership/grant is effective at the one captured audience_evaluated_at instant for the scope resolved from the canonical source event.
- An EVENT_PARTICIPANT clause selects only the server-resolved principal reference mapped to that named participant in the event contract. ACTOR is derived from the authenticated command/worker identity; TARGET and AFFECTED_MEMBER must be explicit event-contract fields. A missing or ambiguous participant mapping is a publication-time validation error, not a reason to guess.
- Every clause evaluates against the serialized pre-mutation state and the same captured instant. Effective intervals are half-open [valid_from, valid_until).
- The selector list is canonicalized by clause kind and canonical reference values; duplicate clauses are removed before policy hashing. Candidate principals are deduplicated by the approved candidate identity key; authorized scope evidence must be the deterministic union of only the scopes actually selected by matching clauses. No scope may be inferred from a role label.
- Maximum eight clauses and one OR level are a conservative v1 review proposal. Engineering must validate resource bounds; Security and PO must approve or change the limit before it becomes normative.

### B. Explicitly prohibited constructs

No nested AND/OR/NOT, negation, wildcard, free-form role label, arbitrary JSON path, SQL/expression string, regex, caller-supplied user ID, caller-supplied scope ID, dynamic table/column name, time function, subquery, recursive group, or implicit actor/target append. No selector may reference a field absent from the event-to-selector registry. Unknown keys, duplicate JSON keys, unknown enum values, malformed identifiers, unresolved participant bindings, excessive clauses or unsupported grammar versions fail closed at policy publication. Runtime evaluation must not reinterpret or silently downgrade an invalid policy.

### C. Required event-to-selector registry

Before any event type is enabled, a versioned registry row must define: exact canonical event_type; source CMD/worker and transaction boundary; selector grammar version; permitted selector clause kinds; event-scope binding (including its source and cardinality); ACTOR/TARGET/AFFECTED_MEMBER field mappings; role/scope dependency references; dispatch profile; and policy-effective interval. Wildcards and prefix matching are forbidden.

The source map v0.1.0 is an inventory, not this registry. Composite declarations (for example, alternative or conditional events in a single CMD row) must be split into exact canonical event tokens before any token is enabled. In particular, CMD-004, CMD-017, CMD-019, CMD-022, CMD-026, CMD-029, CMD-035..040 contain composite/conditional event declarations whose exact event token and participant/scope mapping must be resolved. A CMD being listed in the source map does not imply every event it can emit is notification-enabled.

### D. Fail-closed and deterministic evaluation

1. Resolve the pinned immutable policy version and exact event registry entry after L05, in a fresh SQL command.
2. Validate the complete selector document against the registered grammar version and event-specific clause allowlist.
3. Resolve all symbolic participant and scope bindings from trusted canonical event/source state; never from client claims.
4. Evaluate every clause against the same pre-mutation snapshot and captured instant.
5. Canonicalize and deduplicate candidates and selected scope evidence; calculate snapshot digest/count only over the canonical representation approved by the physical snapshot contract.
6. If the event token, policy version, selector, participant mapping, scope binding or dependency registration is unknown or ambiguous, fail the source transaction atomically. Do not emit a partial outbox or fallback audience.

### E. Dependency mapping required for F-04

Each registry entry must produce a machine-reviewable dependency list of every principal, role, grant, assignment/member, scope-parent and time-validity object consulted. The list must be reconciled to command and non-command writers, including direct DML, SECURITY DEFINER helpers, triggers, cascades, imports, repair, expiry and scheduled jobs. This mapping is a mandatory input to the writer matrix and lock graph. No selector may be published if its dependencies are not registered.

### 4.2.5.1 F05-T1 structural validation and canonicalization profile — candidate only

**Status: REVIEW CANDIDATE — NOT APPROVED.** This subsection makes the existing abstract grammar testable at the document-contract level. It does not admit role keys, scope IDs, event participant fields, physical columns, policy publication or runtime implementation. Engineering and Security must review it; Product Owner review is required if any proposed rule changes approved product behavior.

#### F. Exact structural contract

The policy document is a JSON object with exactly these top-level members:

- `grammar_version`: JSON integer `1` (not a string, decimal, exponent, boolean or null).
- `match`: exact string `ANY`.
- `selectors`: JSON array with 1–8 clause objects.

No additional top-level members are accepted. Each clause has exactly the keys for its selected `kind`:

- `ROLE_SCOPE`: exactly `kind`, `role_ref`, `scope`. `role_ref` is a non-empty exact canonical role-registry key; `scope` is an object with exactly `kind` and `binding`; `scope.kind` is one of `PROJECT`, `SESSION`, `LOCATION`, `ASSIGNMENT`; `scope.binding` is exactly `SOURCE_EVENT_SCOPE`.
- `EVENT_PARTICIPANT`: exactly `kind` and `participant`; `participant` is exactly one of `ACTOR`, `TARGET`, `AFFECTED_MEMBER`.

The grammar is closed: unknown keys, missing required keys, duplicate object keys, duplicate top-level members, duplicate nested members, wrong JSON types, empty identifiers, unknown enum values, unsupported grammar versions and malformed JSON are rejected. Duplicate JSON keys must be detected by the parser before conversion into a map/object that could silently discard one value. No last-key-wins or first-key-wins behavior is permitted.

#### G. Null, missing and cardinality semantics

- JSON `null` is invalid for every required member. Omission is not equivalent to null, empty string, empty array, false, zero, or a default.
- Missing event token, registry row, policy pin, participant binding, role-registry entry, scope binding or required dependency is a hard validation failure. There is no fallback selector, default role, inferred actor/target, wildcard, or partial audience.
- A participant field mapped by an event contract must resolve to one canonical principal identity. Missing, null, malformed, ambiguous, untrusted or multi-valued participant results are invalid for that mapping. A participant may be absent from a particular event only when the exact event registry explicitly declares that participant mapping as not applicable; the clause cannot then reference it.
- `SOURCE_EVENT_SCOPE` must resolve only from trusted canonical source-event state. Its scope kind and cardinality must be declared per event registry row. Zero, multiple, ambiguous or cross-parent scopes are not silently coerced: they fail closed unless a future approved row explicitly defines the exact cardinality and deterministic set semantics. Current NREG rows do not yet contain those approved bindings.
- Effective-time evaluation uses the one captured `audience_evaluated_at` and the candidate half-open interval rule `[valid_from, valid_until)`. Null interval bounds are allowed only where the authoritative domain contract explicitly defines an unbounded endpoint; this grammar does not invent such a domain rule.

#### H. Boolean, participant and scope semantics

- Top-level `ANY` is the only boolean composition: a principal qualifies if at least one valid clause selects that principal. No implicit AND, NOT, nested expression, threshold or priority semantics exist.
- Within one `ROLE_SCOPE` clause, role effectiveness and the exact bound scope-membership predicate are conjunctive for the same principal and the same captured instant.
- `EVENT_PARTICIPANT` is a direct selection of the trusted principal resolved by the exact named participant mapping. It is not a role grant, scope grant, authorization bypass or proof that the principal may open the source resource.
- `ACTOR`, `TARGET` and `AFFECTED_MEMBER` are independent participant names. No one implies another. Actor/self-revoke is represented by the event's trusted ACTOR mapping only; there is no separate SELF selector.
- Matching a principal through multiple clauses yields one candidate identity only after the still-unapproved candidate identity key is supplied by the snapshot contract. Matching scopes are not widened: the selected scope evidence is limited to the deterministic union of scopes actually matched by valid clauses. The physical scope serialization and cross-scope deduplication key remain NOT ADMITTED.

#### I. Canonicalization and equality

Canonicalization is a semantic normalization profile, not an approved byte-level JSON/hash format:

1. Validate the original JSON token stream first, including duplicate-key detection and exact type checks.
2. Normalize no identifier by trimming, case folding, Unicode normalization, alias lookup or display-label conversion. Registry keys and enum tokens must match their exact registered canonical value.
3. Remove only structurally identical duplicate clauses. Do not collapse distinct participant clauses, role references, scope kinds or bindings.
4. Order clauses deterministically by the fixed kind order `ROLE_SCOPE` then `EVENT_PARTICIPANT`; within `ROLE_SCOPE`, compare exact `role_ref`, then `scope.kind`, then `scope.binding`; within `EVENT_PARTICIPANT`, order by `ACTOR`, `TARGET`, `AFFECTED_MEMBER`. Comparisons are exact canonical-token comparisons, not locale-sensitive display sorting.
5. Clause equality is equality of all declared typed members after validation. A duplicate clause cannot alter the candidate or selected-scope result.
6. Do not infer a policy digest, serialized hash format, candidate identity key, scope ordering, or physical snapshot representation from this ordering. Those remain part of F05-T5 / physical snapshot approval.

#### J. Candidate event-intent allowlist boundary

The PO-approved specification/review candidate set is exactly:

`account.approved`, `account.rejected`, `role.revoked`, `project.closed`, `session.closed`, `assignment.created`, `assignment.changed`, `inspection.submitted`, `inspection.returned_for_correction`, `inspection.approved`, `inspection.reopened`.

This is a **candidate-intent allowlist for specification work only**, not a publishable/runtime event allowlist. Each token still requires an exact canonical producer, source transaction boundary, event schema/version, event-specific permitted clause set, participant mapping, scope binding, dependency list, dispatch profile, deduplication and accountable technical approval. All eleven remain `UNRESOLVED / NOT ENABLED`. `session.close_requested`, `inspection_revision.created`, `account.requested`, composite/conditional tokens and all other CMD declarations are not admitted by implication.

#### K. Event-specific clause admission remains unresolved

This grammar defines the maximum candidate clause shapes only. It does not assign any clause to an NREG row. In particular, it does not decide whether an event uses `ROLE_SCOPE`, `EVENT_PARTICIPANT`, both, or neither; it does not choose role keys, participant fields, scope kind/cardinality or dependency columns. A policy must be rejected if it contains a clause not explicitly admitted by that exact event's eventually approved registry row.

#### L. F05-T1 closure evidence still required

F05-T1 cannot close on this document alone. Closure requires:
- Engineering and Security review of the typed structure, parser behavior, null/missing semantics, canonicalization, equality and resource bounds;
- PO confirmation only if the proposed semantics change an approved POQ decision;
- canonical role and scope registries, including authoritative IDs and lifecycle/effective-time contracts;
- all eleven event rows completed with exact event token, per-event clause allowlist, trusted participant mappings, scope source/cardinality and dependency-column list (or explicit exclusion of a candidate row through approved change control);
- a machine-reviewable validation corpus covering valid/invalid structures, duplicate JSON keys, null/missing values, clause ordering, overlap, untrusted participant data and unknown/composite event tokens;
- synchronized TDR, event registry, event-to-selector crosswalk, writer matrix, RTM/RAID and QA references.

Until that evidence is reviewed and approved, F05-T1 remains **OPEN — CANDIDATE SPECIFICATION ONLY**; no selector is publishable, no event is enabled, and F-04 dependency certification remains 0.

## 4.2.6 F05-T2 — event-specific dispatch authorization matrix (candidate)

The table below distinguishes event-time recipient qualification from dispatch-time delivery eligibility. It is a review candidate implementing the POQ-04 outcomes; Security/Engineering must approve each row. The source resource remains independently authorized when a user opens it.

| Transition/event family | Immutable event-time candidate rule | Dispatch-time checks | Explicit non-rule / anti-suppression guard |
|---|---|---|---|
| CMD-005 role revoke; self-revoke | Pre-revoke role/scope state; actor/target only when the exact registered selector clause selects that participant | Account enabled; current channel capability and consent; mandatory security restrictions; apply current-scope check only where the event registry's approved dispatch profile requires it | Do not require the revoked role to remain effective merely to deliver the revocation notice. Notice delivery grants no access to the revoked resource. |
| CMD-002/003 account approve/reject and approved disable/suspend lifecycle events | Pre-mutation eligibility; target is not implicit and must be selected by a registered clause | Suppress while account is disabled/suspended/expired; reactivation may reconsider only the same original snapshot candidate; re-check consent, channel, current scope where applicable and mandatory security | Reactivation never rebuilds/widens the snapshot, resets the checkpoint, or clears unrelated suppression reasons. |
| CMD-015 assignment-member end | Pre-end membership and effective interval at captured instant; affected member only when explicitly selected | Account/channel/consent/security checks; current scope checks follow the event-specific dispatch profile | Do not require current membership in the just-ended assignment as a universal delivery prerequisite; no substitute member. |
| CMD-010 project close; CMD-013 session close | Pre-close parent/scope state and selected event-time audience, committed atomically with closure | Account/channel/consent/security checks; evaluate only the explicit closure-event dispatch profile | Do not apply a blanket parent.status = ACTIVE predicate after the close event. Closure notice does not grant access to the closed resource. |
| Ordinary non-transition event | Pre-mutation selector evaluation under the exact event registry entry | Account/channel/consent/security plus only the event-specific current role/scope checks explicitly declared in the pinned dispatch profile | No generic inference from current role labels or current parent status; no widening or substitute recipients. |

## 4.2.6.1 F05-T2 — first-batch event dispatch review matrix (candidate; not approved)

**Status: PARTIAL STATIC REVIEW — NOT APPROVED FOR PUBLICATION OR IMPLEMENTATION.** This matrix applies the POQ-01 mandatory revalidation boundary and the five POQ-04 transition outcomes to the eleven specification-only NREG candidates. It distinguishes established product constraints from unresolved per-event technical decisions. It does not create dispatch profiles or resolve any recipient mapping.

### A. Common dispatch boundary

For every candidate that is eventually admitted, the pinned event-time candidate set is immutable. Before each channel attempt, the system must re-evaluate the current account state, selected channel capability/eligibility, consent/revocation and mandatory security restrictions. These checks can suppress only an existing candidate. They cannot add, substitute, reselect, or rewrite a candidate, scope, policy pin or checkpoint. Receiving a notification never authorizes opening the referenced source resource.

The exact account-state predicate, channel predicate, consent source, mandatory security rule, current role/scope predicate, parent-state predicate, suppression reason and retry classification must be specified in the event's pinned dispatch profile. No generic current-role, current-assignment, or active-parent predicate may be silently applied to every event.

### B. Per-candidate review matrix

| NREG / exact candidate token | Event-time candidate boundary | Mandatory dispatch checks | Transition-specific rule / prohibited inference | Technical disposition |
|---|---|---|---|---|
| NREG-001 — `account.approved` | Exact event registry and selector only; no target is implicit. Trusted account-request principal projection and pre/post account-state source boundary are not yet approved. | POQ-01 account/channel/consent/security revalidation applies to any future candidate. | Do not assume that a request actor, target field or newly enabled account is a recipient without an approved participant projection. Exact treatment of approved-account state at dispatch remains unresolved. | OPEN — producer, target projection, selector and account predicate unresolved; NOT ENABLED. |
| NREG-002 — `account.rejected` | POQ-04 pre-transition account state; target is included only if the exact selector independently selects a trusted mapped participant. | Account must remain eligible under the POQ-04 approved rejection/disabled-state suppression rule; channel, consent and mandatory security checks still apply. | A rejected/disabled account is suppressed while not enabled. No reactivation may rebuild the snapshot, clear unrelated reasons or add a candidate. | POQ-04 semantics approved; exact participant/source contract and dispatch implementation unresolved; NOT ENABLED. |
| NREG-003 — `role.revoked` | POQ-04 pre-revoke role/scope state; actor and target are selected only by their own exact registered clauses. | Account/channel/consent/security; current-scope checks only where the approved event-specific profile requires them. | Do not require the revoked role to remain effective merely to deliver the revocation notice. No implicit actor/target inclusion. | POQ-04 semantics approved; exact target mapping, current-scope predicate and profile unresolved; NOT ENABLED. |
| NREG-004 — `project.closed` | POQ-04 pre-close project/parent state; selected candidates and closure event must share the approved atomic boundary. | Account/channel/consent/security; only the explicit closure profile's current-scope checks. | No blanket `project.status = ACTIVE` or equivalent parent-active predicate after closure. Notice does not grant project access. | POQ-04 semantics approved; exact role/scope selection and closure profile unresolved; NOT ENABLED. |
| NREG-005 — `session.closed` | POQ-04 pre-close session/parent state; only final committed `session.closed`, never `session.close_requested`. | Account/channel/consent/security; only the explicit closure profile's current-scope checks. | No blanket active-session or active-project predicate after closure. Notice does not grant session/project access. | POQ-04 semantics approved; final producer boundary, participant mapping and closure profile unresolved; NOT ENABLED. |
| NREG-006 — `assignment.created` | Initial roster and newly inserted members must be represented by an explicit trusted event projection consistent with POQ-01/04. Pre-mutation membership alone cannot identify newly created membership. | Account/channel/consent/security; any current assignment/scope check must be explicitly defined by the admitted profile. | Do not infer recipients by querying the post-commit roster or append every inserted member. Do not infer the actor as recipient. | OPEN — initial-roster cardinality, event-time projection and dispatch profile unresolved; NOT ENABLED. |
| NREG-007 — `assignment.changed` | Exact added/ended/retained membership outcomes must be decomposed. POQ-04 pre-end evaluation applies to an ended member; no replacement recipient. | Account/channel/consent/security; current-scope checks only as explicitly defined for the exact change outcome. | Do not use a universal current-membership-in-the-ended-assignment requirement; do not substitute added/retained members for an ended candidate. Added-member selection remains separately unresolved. | POQ-04 member-end semantics approved; event cardinality, added-member projection and profile unresolved; NOT ENABLED. |
| NREG-008 — `inspection.submitted` | Exact committed submitted revision and trusted assigned Reviewer mapping are required; no actor/revision-author substitution. | Account/channel/consent/security; current assignment/role/scope behavior must be explicit in the pinned profile. | Do not infer the Reviewer from the submitter, revision author or generic assignment membership. Independent authorization still applies when opening the inspection. | OPEN — Reviewer source, submit boundary, scope and dispatch predicates unresolved; NOT ENABLED. |
| NREG-009 — `inspection.returned_for_correction` | Exact return decision/revision and trusted responsible-Inspector mapping are required. | Account/channel/consent/security; current assignment/role/scope behavior must be explicit in the pinned profile. | Do not substitute the Reviewer or return actor for the responsible Inspector. Notification does not authorize correction or access to evidence. | OPEN — responsible Inspector source, decision boundary and profile unresolved; NOT ENABLED. |
| NREG-010 — `inspection.approved` | Exact approved revision and trusted responsible-Inspector mapping are required. | Account/channel/consent/security; current assignment/role/scope behavior must be explicit in the pinned profile. | Do not infer the Inspector from the Reviewer, approval actor or revision author. Notification does not grant access to the approved inspection. | OPEN — terminal-decision source, Inspector mapping and profile unresolved; NOT ENABLED. |
| NREG-011 — `inspection.reopened` | No candidate selector can be admitted until the authorized next-action owner and reopen source contract are defined. | Common account/channel/consent/security checks would apply only after a candidate is validly admitted. | Do not substitute the prior Inspector, Reviewer, reopening actor or generic assignment member as next-action owner. | OPEN — next-action owner and authority unresolved; no selector/profile can be admitted; NOT ENABLED. |

### C. POQ-04 preservation and conflict handling

The role-revoke, account-reject/disable/suspend, assignment-member-end, project/session-close and self-revoke outcomes in DECISION-REGISTER.md POQ-04 remain binding. This matrix does not weaken them. Where the exact dispatch behavior is not established by POQ-01/POQ-04, the state is explicitly **UNRESOLVED**; Engineering/Security must not fill it by applying a universal predicate or inferring a product outcome. Any proposed change to the approved product outcomes requires explicit PO change control.

Mandatory security restrictions cannot be bypassed to deliver a transition notice. If a mandatory security rule conflicts with delivery, fail closed and escalate through the approved Security/PO decision path. A notice is not an authorization grant.

### D. F05-T2 closure evidence

F05-T2 remains OPEN until:
- each NREG row has an approved, versioned dispatch profile with explicit account, channel, consent, mandatory-security, current-role/scope and parent-state predicate semantics (including explicit intentional omissions);
- all five POQ-04 outcomes have event-specific positive and negative assertions, including role revoke/self-revoke, rejected-account suppression/reactivation, assignment-member end, project close and final session close;
- NREG-001/006/008/009/010/011 source and recipient gaps are resolved without inferred principals;
- retry classification and suppression reason mapping are consistent with F05-T3, append-only audit with F05-T4, and immutable event-time snapshot with F05-T5;
- Security and Engineering approvals are recorded, with PO approval only for changes to approved product behavior;
- TC-NOTIF-055..059 and TC-NOTIF-062/069 are mapped to the final profiles and remain unexecuted until authorized G10 test conditions exist.

Until then, the table is a review aid only: all eleven NREG rows remain NOT ENABLED, no dispatch profile is approved, and F-05 remains OPEN.

## 4.2.7 F05-T3 — suppression and retry state machine (candidate; not approved)

**Status: PARTIAL CANDIDATE — NOT APPROVED FOR IMPLEMENTATION.** This specification separates deterministic eligibility suppression, safe transient transport retry, ambiguous provider acceptance and terminal failure. It preserves the immutable POQ-01 candidate audience and POQ-04 transition outcomes. It does not select a provider, set numeric retry budgets, approve reason codes, or change the canonical delivery-state graph.

### A. Non-negotiable invariants

1. Candidate membership, authorized source scope, policy pin and fan-out checkpoint are immutable after the source transaction commits. A suppression or retry outcome never deletes, replaces, widens, reconstructs or reorders that snapshot.
2. A retry operates only on the same original candidate and same logical delivery/channel under the same pinned event/policy references. It cannot create a second source event, outbox intent, notification or candidate.
3. Before each external attempt, re-run POQ-01 account status, channel eligibility, consent/revocation and mandatory security checks, plus only the event-specific scope/parent predicates in the approved dispatch profile.
4. POQ-04 account reactivation may permit reconsideration of the same original candidate only. It cannot clear unrelated consent, channel, scope, policy or security suppression; it cannot reset the checkpoint or add a recipient.
5. Quiet hours defer eligible channel delivery only. They do not pause, stop or reset the pinned SLA clock under POQ-02.
6. Provider I/O occurs outside database transactions. Each attempt is bounded by a valid worker lease; stale/reclaimed workers cannot finalize. Attempt evidence is append-only and sanitized.
7. Ambiguous provider acceptance is `UNKNOWN`, not success and not a safe blind retry. Reconcile through provider idempotency/status capability where available; otherwise apply only an explicitly approved duplicate-tolerant recovery rule. Exactly-once external delivery is not claimed.
8. Delivery/suppression/retry state is separate from inbox read state and source business state. A notification failure never changes inspection, project, session, assignment or evidence state.

### B. Outcome classes — candidate taxonomy

These are semantic classes for review. The exact persisted status values and stable reason-code strings remain unapproved.

| Candidate reason family | Candidate outcome class | Candidate reschedule/retry condition | Open control |
|---|---|---|---|
| Account not enabled / suspended / expired | SUPPRESSED — POLICY_RESCHEDULABLE only for the POQ-04 account transition case | Reconsider only after authoritative reactivation; reuse the same candidate and checkpoint; rerun every current mandatory check | Exact account state mapping, reschedule trigger/owner and policy-effective window |
| Quiet hours / channel delivery window | DEFERRED — POLICY_RESCHEDULABLE | Resume at the next allowed time under the pinned policy; SLA clock continues | Time-zone source, boundary handling and channel policy details |
| Channel unavailable / subscription invalid | SUPPRESSED or TERMINAL_FAILURE depending on authoritative channel state | No retry unless the pinned policy explicitly allows rescheduling after the channel becomes eligible | Temporary versus permanent channel-state taxonomy and reactivation trigger |
| Consent revoked / opt-out | SUPPRESSED — classification unresolved | No automatic retry or reactivation inference; any later consent change must be evaluated under an explicitly approved consent policy | Whether later re-consent can reschedule the same candidate; authoritative consent evidence |
| Mandatory security restriction | SUPPRESSED — fail closed | No retry unless the authoritative security control explicitly clears the restriction and the pinned profile permits reconsideration | Security owner, clearance evidence and retry authority |
| Event-specific current-scope / parent predicate fails | SUPPRESSED — classification unresolved | Only an explicit event-specific profile may authorize rescheduling; never substitute another candidate | Per-event profile and POQ-04 exception mapping |
| Pinned policy unavailable/invalid or snapshot integrity fails | TERMINAL / QUARANTINE candidate | No fallback to a newer policy, current membership query or rebuilt audience | Exact integrity incident and operational recovery procedure |
| Provider transient transport/service failure before acceptance is known | RETRYABLE_FAILURE candidate | Bounded exponential backoff with jitter; preserve logical delivery identity; numeric ceiling/age/backoff require Operations approval | Provider classification, retry budget, lease and overload behavior |
| Provider rate limit | RETRYABLE_FAILURE candidate | Respect a provider-authenticated retry instruction only after provider selection and validation; apply approved global ceiling | Provider-specific response trust and cap |
| Provider permanent rejection (e.g. invalid destination or rejected payload) | TERMINAL_FAILURE or SUPPRESSED candidate | No automatic retry unless corrected input is authorized through a separate controlled path; do not mutate the original event snapshot | Provider-specific permanent-error mapping and correction authority |
| Provider acceptance may have occurred but result is unknown | UNKNOWN — RECONCILIATION_REQUIRED | Reconcile by stable provider reference/idempotency; do not blind resend | Provider capability and bounded/manual reconciliation procedure |
| Worker lease lost / stale generation | No delivery outcome inferred from stale worker | Reclaim only through the current lease protocol; stale worker cannot commit an attempt result | Lease reclaim schedule, stale-worker fencing and monitoring |
| Invalid callback / replay / unknown provider reference | CALLBACK_REJECTED — no delivery-state transition | No retry; authenticate, validate freshness/reference and deduplicate callback | Provider-specific callback authentication and durable dedup mechanism |

### C. Candidate logical state progression

The existing NLA-001 proposal defines these transitions: `PENDING → SENDING | SUPPRESSED | EXPIRED`; `SENDING → SENT | FAILED | UNKNOWN`; `SENT → DELIVERED` or provider-confirmed `FAILED`; `UNKNOWN` advances only after provider reconciliation; `SUPPRESSED → PENDING` only where the pinned policy explicitly permits rescheduling; terminal `DELIVERED / FAILED / EXPIRED` states do not regress.

**Blocking state-graph gap:** the current NLA-001 state progression does not explicitly define the legal transition for a retryable provider failure after `SENDING`. It does not say whether a retryable failure enters a distinct `RETRY_WAIT` state or returns to `PENDING` with a guarded `next_attempt_at`. This TDR does not choose either transition or add a physical status. NLA-001, TDR, command contracts, QA and the proposed schema must reconcile this before F05-T3 can close. Until then, no retryable-failure state transition is admitted for implementation.

### D. Retry ownership, budgets and checkpoints

- The delivery worker is the candidate owner of provider attempts under the approved internal workload identity and lease. Whether a scheduler only wakes due work or can transition a retry state is unresolved and must be explicit.
- Operations must approve maximum attempts, maximum age/horizon, exponential-backoff parameters, jitter, lock/statement budgets, dead-letter threshold, alert thresholds and manual reconciliation SLA. No numeric value is invented here.
- The retry attempt must preserve the original event/outbox/candidate/policy references, logical delivery identity, channel and correlation chain. Attempt number is monotonic within that logical delivery.
- Reclaim after lease expiry increments the lease generation; a stale worker cannot finalize, suppress, mark success, or schedule another attempt.
- Suppression of one candidate/channel does not stop other valid candidates/channels from progressing. A partial fan-out checkpoint advances only for durably finalized items and never resets because one item is suppressed or retried.
- An unknown provider outcome blocks blind duplicate dispatch until reconciliation or an explicitly approved duplicate-tolerant decision.
- Retry exhaustion or age expiry produces a durable terminal/dead-letter disposition and an operational alert; it does not delete the original notification intent or rewrite the source business state.

### E. Append-only evidence and privacy

Each attempt requires durable, append-only evidence of logical delivery reference, attempt number, safe idempotency reference, start/finish time, worker correlation/lease generation, outcome class, sanitized reason/error code, retryable classification and provider reference where available. Suppression/reconciliation transitions must be correlated to the pinned policy and original candidate without copying message bodies, evidence, tokens, credentials or full provider responses into logs/audit.

Routine attempt records belong in the dedicated append-only delivery-attempt history. Do not emit a general audit event for every routine retry. Security-relevant administration, policy changes, manual reconciliation and terminal operational interventions remain auditable under the approved audit catalogue. T-10 classification, retention, legal hold and disposition remain unresolved institutional controls.

### F. Closure evidence and open decisions

F05-T3 remains OPEN until:
- stable reason codes and exhaustive terminal/retryable/policy-reschedulable classifications are approved by Engineering/Security/Operations;
- the retryable-failure transition gap in the NLA-001 state graph is resolved consistently across TDR, NLA-001, command contracts, candidate schema and QA;
- account reactivation, consent re-grant, channel re-enable, security-clearance and scope/parent transitions have explicit reschedule ownership and eligibility rules, without widening the original snapshot;
- provider transient/permanent/unknown classifications and callback reconciliation are based on a selected provider's verified capabilities;
- attempt ceiling, retry horizon, backoff/jitter, dead-letter, alert and manual-reconciliation budgets are approved by Operations;
- append-only evidence, correlation, privacy minimization and T-10 retention dependencies are resolved;
- TC-NOTIF-056/063/064 and relevant provider/lease cases are mapped to the final state machine and remain PLANNED / NOT EXECUTED until authorized G10 execution.

**Disposition:** candidate state/reason taxonomy only. No stable code, retry budget, worker/scheduler authority, provider behavior, physical status, table, command, migration or runtime transition is approved. F05-T3 remains OPEN; F-05 remains OPEN; G9 NOT READY; G10 NOT ACTIVE.

**Mandatory dispatch-profile fields:** account eligibility predicate; channel capability predicate; consent/revocation predicate; mandatory security predicate; current role/scope predicate (including whether it is intentionally omitted for a transition notice); parent-state predicate (including whether it is intentionally omitted for closure notices); retry classification; and suppression reason mapping. Each predicate must be versioned and auditable.

**Decision boundary:** this matrix does not override the NLA baseline that disabled, suspended or expired accounts are ineligible for dispatch. The precise account-reactivation reschedule rule, terminal/retryable reason catalog and scope/security exceptions remain approval inputs. A conflict between mandatory security and delivery of a transition notice must fail closed and be escalated for explicit Security/PO resolution, not silently bypassed.


## 16. L05 event-to-selector registry crosswalk — 2026-11-25

[NLA-L05-EVENT-SELECTOR-REGISTRY-001](L05-EVENT-TO-SELECTOR-REGISTRY-001.md) v0.1.3 now provides the static CMD-001–040 event-to-selector crosswalk, the eleven PO-approved first-batch candidate mappings, candidate grammar v1, logical scope/participant questions, and F-04 eligibility-writer dependency intake.

This artifact is an inventory/review candidate only. It does not convert the eleven PO-approved specification candidates into an enabled allowlist, resolve any NREG participant or scope, approve grammar v1, admit L05 or its key, or certify a producer/writer path. Composite/conditional CMD declarations remain unresolved; all eleven NREG rows remain PARTIAL STATIC REVIEW / NOT ENABLED. F05-T1..T5 remain OPEN; selector dependency universe remains NOT FROZEN; writers certified 0; resolver certification 0/40; application lock certification 0/50; global graph NOT PROVEN ACYCLIC; candidate snapshot relation/header NOT ADMITTED; G9 NOT READY; G10 NOT ACTIVE.

The new crosswalk is a traceability aid for Engineering/Security/Database review. Exact source function/worker boundaries, physical columns, implicit FK/trigger/helper edges, all non-command writers, suppression reason codes, retry budgets, audit/retention approvals and atomic snapshot proof remain required. No SQL, migration, grants, RLS, runtime test or implementation is authorized.

## 17. F05-T4 append-only audit evidence contract — candidate (2026-11-25)

**Disposition: candidate specification for Security/Engineering/Records-Privacy review; not a physical schema or implementation approval.** This section refines the F05-T4 acceptance item in §4.2.4. It does not select a new table, command, provider, retention period, hash-chain design or deletion mechanism.

### 17.1 Evidence classes and ownership

1. **Delivery attempt evidence** belongs in the proposed dedicated `notification_delivery_attempts` history. Each actual provider attempt and its final classified outcome is one immutable evidence item. Routine retries and provider callbacks must not each create a general `audit_events` row.
2. **Candidate suppression/reschedule evidence** records each decision that changes a candidate/channel's dispatch eligibility or schedules a permitted reconsideration. It must remain linked to the same original candidate and checkpoint. Its final physical representation (dedicated append-only outcome rows or an approved extension of an existing notification history) remains a Database decision; no new table is admitted here.
3. **Security/governance audit evidence** remains in the canonical `audit_events` stream for policy publication/retirement, privileged administration, manual UNKNOWN reconciliation, terminal operational intervention and other catalogue-approved material actions. Preserve the existing one-time `notification.read` event rule.
4. **Operational telemetry** may aggregate queue age, retry counts and sanitized error classes. It is not the authoritative evidence ledger and must not replace durable attempt/outcome records.

### 17.2 Required logical evidence envelope

Each attempt/outcome evidence item must carry, where applicable and without inventing unavailable identifiers:

- stable evidence ID and evidence kind/version;
- canonical source event ID and outbox ID;
- immutable candidate identity and source-scope reference (logical candidate only; candidate relation remains NOT ADMITTED);
- pinned policy-version ID and canonical policy digest/reference;
- logical delivery ID, recipient reference, channel and monotonic attempt number;
- end-to-end correlation ID, server request/operation ID and safe idempotency reference (never the raw idempotency key);
- actor provenance: initiating user principal and trusted role/scope context where a human action exists; or the approved workload identity for worker actions;
- worker lease generation/fencing token reference for worker-owned transitions;
- controlled outcome class, stable reason-code reference, retry classification and sanitized error code;
- provider reference only when available and safe as an opaque identifier; never raw credentials or full provider payload;
- database/server UTC timestamps for decision/attempt start, completion and durable recording, with client timestamps treated only as untrusted diagnostics.

A field may be absent only when its event kind makes it inapplicable or the source does not yet exist; absence must not be filled by inference. Exact physical nullability, foreign keys, uniqueness and ordering constraints require Database review.

### 17.3 Provenance, correlation and state integrity

- User actor identity must be derived from the authenticated server context; a browser-supplied actor, role, scope, worker ID or provider identity is never authoritative.
- Worker identity must be authenticated by the approved internal workload mechanism and bound to the current lease generation. A stale worker cannot append a success, failure, suppression, retry-schedule or reconciliation outcome after losing its lease.
- Provider callback evidence must be admitted only after provider-specific authentication, freshness, reference binding and replay/deduplication checks. Callback claims are not trusted actor identity.
- Every attempt/outcome must link to the original source event → outbox → immutable candidate → pinned policy → logical delivery → attempt/checkpoint chain. A retry continues the original correlation lineage; it does not create a new candidate or reset the checkpoint.
- A duplicate idempotent request must resolve to the same durable outcome and must not create contradictory evidence. A legitimate new attempt has a distinct monotonically increasing attempt number.
- Decision/attempt times are server/database controlled UTC instants. Ordering must be established by an approved persisted sequence/constraint or a deterministic per-delivery ordering rule; timestamps alone must not be treated as a concurrency-safe sequence.
- Corrections are additive, linked compensating evidence. Committed evidence is never edited in place or silently removed.

### 17.4 Reason taxonomy and privacy boundary

F05-T3 outcome classes remain the source for suppression/retry classification: policy suppression, quiet-hour deferral, account/channel/consent/security/scope restriction, transient provider failure, permanent rejection, UNKNOWN pending reconciliation, lease loss and invalid/replayed callback. F05-T4 requires stable machine-readable reason codes and an exhaustive mapping from each reason to terminal, retryable, policy-reschedulable or no-transition behavior. The literal code catalogue and its owners remain OPEN; this document does not invent final production code strings or budgets.

Evidence must exclude message bodies, inspection/evidence content, raw user notes, passwords, JWTs, cookies, API/service-role credentials, signed URLs, raw idempotency keys, full provider responses and unnecessary personal/network metadata. Use opaque references, allow-listed attributes and sanitized error classes. IP/device/network metadata is omitted unless T-10 explicitly approves purpose, fields, access and retention.

### 17.5 Append-only and integrity controls

The candidate contract requires no UPDATE/DELETE path for committed attempt/outcome evidence for application, browser or worker principals; append through an approved server-side path only. Any correction is a new linked evidence item. Database ownership/provider administrators remain privileged trust boundaries and require independently governed platform evidence.

Integrity verification must include duplicate/missing evidence detection, referential/correlation-chain reconciliation, attempt-number continuity and stale-lease rejection. A hash chain, signed checkpoint or external WORM archive is not assumed or approved by this section; any such control requires a separate design for canonical serialization, concurrency, key custody, recovery, cost and institutional approval. Do not describe database append-only grants or hashes as absolute tamper-proofing.

### 17.6 T-10 boundary and F05-T4 exit criteria

T-10 remains BLOCKED pending written institutional records/legal/privacy/security approval for classification, purpose, retention triggers/duration, archive, deletion/disposition, legal hold, access/export and network metadata. No retention duration, purge schedule, legal basis, IP collection or irreversible disposition may be inferred. Until that approval exists, these values remain OPEN / NOT SET and no retention implementation is authorized.

F05-T4 may close only after Security and Engineering approve the logical contract and stable reason taxonomy; Database approves physical append-only enforcement, constraints, ordering and access model; Records/Privacy authority supplies the T-10 decisions; and QA cases TC-NOTIF-095..099 are mapped to the admitted design. Execution still requires G10 and an authorized isolated environment. F05-T4 remains OPEN; F-05 remains OPEN; G9 NOT READY; G10 NOT ACTIVE.



## 18. F05-T5 atomic source-event and immutable snapshot binding — candidate (2026-11-25)

**Disposition: candidate transaction-boundary contract for Engineering/Database/Security review; not a physical schema, lock certification or implementation approval.** This section refines F05-T5 in §4.2.4 and RTM NOTIF-020. It does not admit a candidate snapshot relation/header, event/outbox key, digest algorithm, SQL function, lock rank, grant, RLS policy or migration.

### 18.1 Atomicity invariant

For each eventually admitted notification-producing source transition, the following logical facts must become durable together or not at all:

1. the authoritative source-domain mutation and its resulting canonical state/version;
2. the exact canonical source event instance(s) admitted by that producer contract, with explicit event cardinality and no duplicate event identity;
3. the required canonical audit evidence for the critical mutation;
4. the durable idempotency outcome for the command execution;
5. the corresponding outbox intent(s), each bound to its exact admitted source event instance;
6. the exact immutable policy-version reference applicable to the event;
7. the complete event-time candidate recipient/scope set, including an explicit completed-snapshot boundary and its initial fan-out checkpoint state.

Every admitted source event instance, required audit evidence, idempotency outcome, corresponding outbox intent, policy pin and complete candidate snapshot must share the same approved database transaction as the source mutation. If the producer contract admits multiple event instances, their exact cardinality and per-event outbox/snapshot binding must be explicit; this section does not infer one event per command. A partial commit is invalid: no source mutation without its required event/audit/idempotency/outbox/snapshot, and no notification intent or candidate snapshot for a source mutation that rolls back. Audit-write failure fails closed for the critical mutation under T-15. The exact event/audit cardinality and idempotency object remain governed by their canonical contracts.

A fully evaluated empty candidate set is distinct from a missing, partial, failed or unresolved snapshot. Empty is admissible only when the exact approved event/policy contract permits it and the resolver has completed successfully. Unknown selector, unresolved participant/scope, incomplete dependency registration, resolver error or snapshot-integrity failure aborts the entire source transaction; it must not be converted into an empty audience or fallback audience.

### 18.2 Candidate transaction sequence — logical, not a lock-order approval

The following sequence expresses required data dependencies only. It does not assign numeric lock ranks or supersede the canonical lock manifest/graph:

1. Authenticate and authorize the command using trusted server context; derive the idempotency lookup identity from the canonical command contract, never from a client actor, role or scope claim. A previously completed idempotency result may be returned; do not commit a standalone success outcome or source-event claim before the source transaction.
2. Enter the approved source-command transaction and acquire every required serialization guard/fence in the separately approved global order. Candidate L05 must not be treated as admitted until Engineering/Database/Security approve its primitive, key, participation and graph position.
3. Immediately after the approved audience-serialization point, capture one database-controlled UTC `audience_evaluated_at`. This exact instant is reused for every effective-time predicate, policy-effective interval and candidate-eligibility evaluation in the transaction. Do not substitute transaction-start time, client time, per-row timestamps or a later second clock read.
4. Resolve the exact canonical event token, producer contract, immutable policy version and event-specific selector/dispatch registry entries. Missing, ambiguous, expired or unsupported references fail closed; never fall back to the latest policy or rebuild from current membership after commit.
5. Evaluate the complete candidate audience and authorized source-scope evidence against the serialized pre-mutation state at that one captured instant, using only the event's approved selector/dependency mapping. Canonicalize and deduplicate under the eventually approved identity/scope rules; do not invent those physical keys here.
6. Apply the source mutation and persist the exact admitted canonical event instance(s), required audit evidence, idempotency result, corresponding outbox intent(s), policy pin(s), complete immutable candidate snapshot(s) and initial checkpoint(s) as one transaction. The event and snapshot must identify the same source operation and captured instant.
7. Commit once. No provider/network I/O, email/push call, browser callback or external side effect occurs while the database transaction is open.

The logical sequence is not a certified global lock order. Exact guard acquisition, source-parent locks, FK/unique/trigger/helper edges, worker interaction and lock timeout/retry remain governed by the full lock manifests and F-04/R-037 review. A command path is not certified merely because this sequence is documented.

### 18.3 Binding and completeness requirements

- **One producer execution:** each event instance is attributable to one exact canonical source-command/finalizer execution and one committed source transition. A projection, audit row or post-commit query is not a substitute for the producer transaction.
- **One captured instant:** source eligibility, role/grant/membership effective intervals, event-time participant/scope resolution and policy-effective selection use the same `audience_evaluated_at`. The persisted reference is the exact instant used by the resolver.
- **One immutable policy pin:** persist the exact immutable policy version/reference selected for the event. Policy publication/retirement racing the producer must have one approved serialization outcome; a later retry never substitutes a newer policy.
- **Complete candidate snapshot:** persist every selected candidate and only its authorized selected scope evidence, together with an explicit snapshot-complete boundary. A worker must not observe or fan out a partially materialized set. Exact candidate identity, scope encoding, row/header relation, digest/count fields and constraints remain Database decisions.
- **Stable correlation:** source operation, canonical event, outbox, policy pin, candidate snapshot, logical delivery and initial checkpoint must be reconcilable without relying on timestamps alone. Exact IDs, uniqueness keys and digest serialization remain unapproved until the physical contract is admitted.
- **Idempotent replay:** replay of the same command/idempotency identity returns the original durable outcome and references; it must not create a second source event, outbox, policy pin or candidate snapshot. A genuinely new source command creates its own independently bound snapshot.
- **Post-commit immutability:** fan-out and every retry consume the exact committed snapshot and checkpoint. They may record append-only suppression/attempt outcomes and advance only the approved checkpoint; they may not re-resolve membership, replace recipients/scopes, reset the checkpoint or mutate the source event.
- **Failure atomicity:** any failure before commit—including audit, idempotency, event, outbox, policy-pin, candidate insert, uniqueness, FK, serialization or integrity failure—rolls back all source-transaction facts. A lost client response after commit is resolved by idempotency replay, not by creating a second event.

### 18.4 Concurrency and failure cases requiring proof

1. Two source commands competing with role/grant, assignment membership, scope, account eligibility, policy publication/retirement and project/session lifecycle writers must serialize under one approved protocol; no mixed-time candidate set is allowed.
2. A writer that commits while the producer waits at the approved audience guard must be reflected consistently according to the single captured instant and approved PostgreSQL command/snapshot semantics.
3. Concurrent fan-out workers cannot observe an incomplete candidate set or advance a checkpoint past an uncommitted/unfinished candidate.
4. Duplicate source-command replay, transaction retry after deadlock/serialization failure and lost commit acknowledgement must converge on one durable idempotent outcome.
5. A provider timeout or ambiguous external acceptance occurs only after database commit and is handled by F05-T3/F05-T4; it cannot roll back or recreate the source event/snapshot.
6. Any stale worker/lease generation is unable to mutate the committed candidate set or finalize a conflicting checkpoint.

### 18.5 Physical and governance decisions deliberately not made

This candidate does not choose the snapshot table/header, candidate identity key, source/outbox foreign keys, policy-pin columns, unique constraints, ordering/sequence primitive, canonical serialization/digest, empty-snapshot representation, initial checkpoint encoding, RLS/ACL, trigger/helper behavior, exact PostgreSQL isolation configuration, lock key/rank, timeout/retry budgets or provider mechanism. It does not certify any source path or eligibility writer.

Database must map the logical envelope to exact DDL and FK/unique/index/trigger/helper dependencies. Engineering must identify every producer/finalizer and idempotency boundary. Security must review trusted identity, policy pin, scope minimization and fail-closed behavior. All source and non-command eligibility writers must be reconciled to the approved lock graph before any resolver path is certified. T-10 remains a separate institutional dependency; no retention or purge policy is inferred.

### 18.6 F05-T5 closure evidence

F05-T5 remains OPEN until all of the following are supplied and approved:

- Engineering identifies every exact producer transaction/finalizer for every candidate event and proves source mutation, event, audit, idempotency, outbox, policy pin and complete snapshot are inside that transaction.
- Database approves the physical snapshot/header representation, FK/unique/index/trigger/helper graph, ordering/completeness constraints and atomic rollback behavior.
- Security approves trusted actor/event projection, policy pinning, scope binding, fail-closed semantics, worker visibility and no-widening controls.
- Engineering/Database/Security approve one global serialization protocol and demonstrate all relevant eligibility-changing writers participate; resolver coverage must be evidence-backed, not inferred from static inventory.
- The one captured database instant is proven to be taken at the approved serialization point and reused by all effective-time predicates.
- Idempotency replay, concurrent writers, partial-write injection, commit-ack loss, policy publication race, empty-versus-incomplete snapshot, fan-out visibility and rollback cases have deterministic isolated-database evidence.
- TC-NOTIF-100..105 are mapped to the admitted physical contract and executed only after G10 activation in the authorized isolated environment.
- TDR, NLA-001, event/selector registry, source map, writer matrix, lock manifests/graph, RTM, RAID, DGA and QA are synchronized; no unresolved contradiction remains.

**Current disposition:** F05-T5 remains OPEN — CANDIDATE TRANSACTION-BOUNDARY CONTRACT ONLY. F-05/F-04 remain OPEN; resolver certification 0/40; application lock certification 0/50; global graph acyclicity NOT PROVEN; candidate snapshot relation/header NOT ADMITTED; G9 NOT READY; G10 NOT ACTIVE. No implementation, SQL, migration, grants/RLS, runtime test, provider setup, deployment or data mutation is authorized by this section.
