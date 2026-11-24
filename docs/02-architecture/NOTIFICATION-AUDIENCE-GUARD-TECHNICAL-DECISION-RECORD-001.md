# Notification Audience Guard — Technical Decision Record

**Document ID:** NLA-L05-TDR-001  
**Version:** 0.1.2  
**Status:** PO-APPROVED CANDIDATE — technical approval pending Engineering, Database and Security  
**Date:** 2026-11-24  
**Decision authority:** Product Owner candidate selection recorded in NLA-RESOLVER-LOCK-001 §11  
**Parent design:** NLA-RESOLVER-LOCK-001 v0.1.8  
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

### 4.2.1 Post-transition audience semantics — reviewer proposal, PO decision required

The current transaction sequence resolves the candidate audience after L05 and before applying the source mutation. This naturally defines a **pre-transition eligibility snapshot** at `audience_evaluated_at`. Recommended default: candidate eligibility is evaluated against the state serialized before the command's source mutation; the source mutation, canonical event and immutable candidate snapshot then commit atomically. A transition must not retroactively rewrite the captured candidate set.

For explicit event participants (actor, target, affected account/member), inclusion must be represented by an approved event participant/selector rule; do not silently append the actor or target outside the policy's exact selector grammar. Dispatch-time account/channel/consent and mandatory security checks may suppress an existing candidate under POQ-01, but may never add a new candidate. Scope revalidation may also suppress only under the approved POQ-01 contract.

This is a **review recommendation, not a PO-approved semantic decision**. Product Owner must explicitly decide expected outcomes for at least: role revoke (CMD-005), account reject/disable/suspend (CMD-002/003 and any future account lifecycle path), assignment member end (CMD-015), project/session close (CMD-010/013), and self-revoke by the actor. The current phrase “apply explicit post-transition semantics” is not executable until those outcomes are recorded and covered by tests.

### 4.3 Candidate total order

`L00 → L05 → L10 (when T-14 applies) → L15 → L16 → L17 → conditional L18 → L20 → L30 → L40 → L50 → L55 → L60 → L70 → L80 → L90 → L100 → L110`

This is a proposed order, not an admitted graph. L05 must precede every mutable domain lock in a participating transaction. T-14 L10 ordering and all existing command-specific conflicts must be reconciled before any source path is certified. No transaction may acquire a lower-ranked row after a higher-ranked row.

The captured `audience_evaluated_at` is one immutable instant for the eligibility decision. Effective intervals use half-open semantics `[valid_from, valid_until)`: an item is effective when `valid_from <= audience_evaluated_at` and `(valid_until IS NULL OR audience_evaluated_at < valid_until)`. This is a proposed technical convention and requires PO confirmation wherever it changes an existing approved domain contract. Policy, role, scope, assignment/member and parent-state predicates must all use the same captured value; no per-row wall-clock sampling is allowed.

The canonical source event's business timestamp remains a separate fact unless the domain event contract explicitly equates it with `audience_evaluated_at`. Persist both when they represent different concepts; never silently rewrite a business-event timestamp to the audience evaluation instant.

Reference: https://www.postgresql.org/docs/current/functions-datetime.html

## 5. Mandatory writer participation matrix

All rows below are in-scope for the guard unless a static proof shows the mutation cannot affect any enabled selector. The final command-ID mapping is a mandatory approval artifact; this category list is not a substitute for that matrix.

See [NLA-L05-WRITER-MATRIX-001](L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md) v0.1.0 for the current static command/non-command writer inventory. That artifact is intentionally PARTIAL: selector dependency grammar, deployed function/trigger/job inventory, direct-DML bypass evidence and actual writer ownership remain unknown. It does not close the complete-writer requirement.

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

