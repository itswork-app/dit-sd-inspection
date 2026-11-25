# Aggregate Version and Parent-Fence Resolution — CMD-009–016

**Document ID:** AGGREGATE-CONCURRENCY-RESOLUTION-001  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Status:** Engineering / Database decision proposal — NOT APPROVED FOR IMPLEMENTATION  
**Scope:** Project, session, assignment-membership and Inspector-capacity concurrency  
**Authority:** AGENTS.md v1.2.2; MIB-001; DGA-001; LOCK-MANIFEST-001; LOCK-GRAPH-001; PostgreSQL Command Contract Catalogue  
**Gate:** G9 NOT READY; G10 NOT ACTIVE

## 1. Purpose

Resolve the missing aggregate version-token and parent-fence contracts identified for CMD-009–016 without claiming that any column, constraint, lock mode or migration has been approved or deployed.

The proposal separates three different mechanisms:

1. **Optimistic concurrency token** — detects a stale client mutation of one aggregate.
2. **Parent fence** — serializes child writers against parent lifecycle/metadata transitions and prevents late child work after closure.
3. **Invariant serialization row** — serializes all writers that can change a shared population predicate, here the T-14 qualifying Inspector count.

These mechanisms are not interchangeable. In particular, `updated_at` is not a concurrency token, and a parent fence does not automatically increment the parent's row version.

## 2. Proposed canonical token convention

For mutable command-owned aggregates in this scope, standardize on:

- Physical column: `row_version BIGINT NOT NULL DEFAULT 1`.
- Initial value: `1`.
- Client precondition: `expected_row_version BIGINT` for update/transition commands that edit an existing aggregate.
- Successful semantic mutation: increment exactly once per aggregate per command transaction.
- No-op or rejected mutation: do not increment.
- Overflow: fail closed; do not wrap.
- A stale expected value returns typed `STALE_VERSION`; no last-write-wins fallback.
- `updated_at` and `updated_by` remain audit/operational metadata only and are never substituted for `row_version`.
- Compare and increment inside the database transaction after acquiring the prescribed aggregate lock; do not trust a client-computed next value.

The proposed CAS form is conceptually:

```sql
UPDATE <aggregate>
SET <allowlisted_fields> = ...,
    row_version = row_version + 1,
    updated_at = statement_timestamp(),
    updated_by = <trusted_actor>
WHERE id = <target_id>
  AND row_version = <expected_row_version>
RETURNING row_version;
```

This is illustrative pseudocode only, not executable migration or implementation SQL. The actual function must also enforce authorization, lifecycle predicates, audit atomicity, idempotency and the approved lock order.

## 3. Proposed aggregate field map

| Aggregate | Proposed physical token | Commands | Token behavior |
|---|---|---|---|
| Project | `projects.row_version` | CMD-009, CMD-010 | Increment on successful project metadata update or project lifecycle transition only. |
| Session | `sessions.row_version` | CMD-012, CMD-013 | Increment on successful session metadata update or lifecycle transition only. CMD-011 creates a new session at version 1. |
| Assignment membership aggregate | `operational_assignments.row_version` | CMD-014, CMD-015 | CMD-014 creates assignment at version 1. CMD-015 compares and increments the parent assignment version once for the complete membership batch. |
| Inspector capacity setting | `project_capacity_settings.row_version` | CMD-016 | Increment only when the configured cap changes. T-14 population-changing commands lock this row but do not increment this configuration token merely because membership/role population changed. |

### 3.1 Deliberate exclusions

- `assignment_members.row_version` is not proposed in this scope. Membership mutations are serialized through the parent assignment aggregate; exact member rows are selected and changed under that parent lock, with stable member-key ordering and state predicates.
- `project.row_version` is not incremented for every child insert/update. It represents the project aggregate's own metadata/lifecycle state, not a synthetic version of all project descendants.
- `sessions.row_version` is not incremented for assignment creation. Session child creation is governed by the session parent fence and closure predicate, not by changing the session's own token.
- Capacity-row `row_version` represents the configured cap value. It is not a counter for the number of qualifying Inspectors; population changes are serialized by the capacity row lock and re-counted using the canonical T-14 predicate.

These boundaries avoid accidental token churn and prevent one aggregate's version from being misrepresented as a global descendant version.

## 4. Proposed command contracts and lock behavior

Resource ranks below refer to the candidate ranks in LOCK-GRAPH-001. They remain a review hypothesis until PostgreSQL lock compatibility, every implicit FK/trigger/function edge and the complete writer graph are independently verified.

| Command | Proposed token/request | Proposed lock and mutation contract |
|---|---|---|
| CMD-009 update-project | `projects.row_version`; normalize request field to `expected_row_version` | L00 idempotency; authorization; project L30 `FOR NO KEY UPDATE`; revalidate editable state and allowlist; CAS update; increment project token once; audit/idempotency commit atomically. |
| CMD-010 close-project | `projects.row_version`; require `expected_row_version` | L00; conditional L10 capacity fence if closure changes T-14 eligibility; project L30 `FOR NO KEY UPDATE`; evaluate the complete closure blockers while holding the parent fence; CAS lifecycle transition; increment once. Do not cascade or mutate child states implicitly. |
| CMD-011 create-session | No expected token; new session starts at `row_version = 1` | L00; project L30 `FOR SHARE`; revalidate project permits creation after any lock wait; insert session with server-selected DRAFT and unique (project_id, code) arbiter; audit/idempotency atomic. |
| CMD-012 update-session | `sessions.row_version`; request `expected_row_version` | L00; project L30 `FOR SHARE`; session L30 `FOR NO KEY UPDATE`; revalidate session/project state and dependent-work schedule predicate; CAS allowlisted metadata update; increment once. |
| CMD-013 transition-session | `sessions.row_version`; request `expected_row_version` | L00; project L30 `FOR SHARE`; session L30 `FOR NO KEY UPDATE`; revalidate actor, scope and transition after lock wait; evaluate closure blockers while holding session fence; transition/event/audit/idempotency atomic; increment once on an actual state transition. |
| CMD-014 publish-assignment | No expected token; new assignment starts at `row_version = 1` | L00; affected L10 capacity rows `FOR UPDATE` sorted by project UUID; L15–L18 authorization; project then session L30 `FOR SHARE`; L40 instrument/version `FOR SHARE`; create assignment and complete initial member roster atomically. Revalidate T-14 predicate at the capacity serialization point. |
| CMD-015 change-assignment-members | Add `expected_row_version` for parent assignment aggregate | L00; affected L10 capacity rows when eligibility changes; L15–L18 authorization; project/session L30 `FOR SHARE`; assignment L50 `FOR NO KEY UPDATE`; compare parent version; lock exact member rows in stable key order; validate entire batch before writes; end-date/add members; increment assignment token once; preserve history and submitted inspections. |
| CMD-016 change-inspector-capacity | `project_capacity_settings.row_version`; require `expected_row_version` | L00; exact project L10 capacity row `FOR UPDATE`; fail closed if absent; compare token; compute current qualifying account count using the canonical T-14 predicate; reject below count or outside 1..100; update cap and increment once; audit/idempotency atomic. |

## 5. Parent-fence protocol

### 5.1 Project fence

- Child commands that create or mutate project-scoped work acquire the project parent row with the approved shared fence mode before locking lower-ranked child resources.
- Project metadata/lifecycle commands acquire the conflicting project parent mutation mode before evaluating or changing parent state.
- CMD-009 and CMD-010 must revalidate project status after acquiring the parent lock.
- Every project-scoped child writer and asynchronous finalizer must participate, including commands and workers that may create a late durable intent.
- A child writer that waited behind a parent transition must re-read and reject a now-closed/ineligible project; pre-lock authorization or status reads are not sufficient.
- CMD-010 must not assume a finite blocker query is safe until the complete child-writer/finalizer inventory is reconciled.

### 5.2 Session fence

- Session child writers acquire project parent fence first, then the session parent fence, then lower-ranked assignment/work resources.
- CMD-012 and CMD-013 acquire the session mutation fence and revalidate state after lock wait.
- CMD-011 and CMD-014 must acquire the session shared fence before inserting child work.
- CMD-013 closure evaluates the complete dependent-work set while holding the session fence.
- A child writer that waited behind a transition must re-read the session state and reject work if the session is no longer eligible.

### 5.3 Assignment membership fence

- CMD-014 is create-only and inserts a complete initial roster in one transaction.
- CMD-015 serializes all add/end operations for one assignment on the parent assignment row.
- The request's `expected_row_version` protects the complete membership aggregate from stale roster edits.
- Each member's effective time is preserved; ending membership is an end-dated history mutation, not deletion.
- All proposed add/end operations are validated before any write. The transaction is all-or-nothing.
- The assignment token increments once if and only if the batch changes semantic membership state.

## 6. T-14 capacity serialization

The canonical PO-approved T-14 qualifying-account predicate remains unchanged: count distinct enabled login accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment in the governed project/session scope.

Candidate serialization rule:

1. Discover every affected project capacity row from trusted persisted relationships, not client-supplied scope.
2. Acquire all affected capacity rows in ascending project UUID order at L10 using one exclusive row-locking primitive.
3. Re-discover the affected project set after acquiring the fence; abort/retry if it changed.
4. Re-evaluate account enabled state, active role grant, effective assignment interval and governed scope after the lock wait.
5. Perform the role/account/membership/cap mutation in the same transaction.
6. Enforce cap 1..100 and reject any operation that would exceed it; CMD-016 also rejects a reduction below the current qualifying count.
7. Every writer that can change any predicate term must participate, including role grant/revoke, account enable/disable/approval transitions if applicable, assignment publication, assignment membership changes and capacity updates.

The full writer list is not yet proven complete. The exact account lifecycle commands and any administrative/provider paths that can alter login eligibility must be inventoried before this protocol can be approved. The capacity row must be created atomically with project creation or established by a controlled, verified backfill before commands can operate; missing rows fail closed.

## 7. Required database invariants and verification

Before approval, Database/Engineering must specify and verify:

- Exact column types, nullability, defaults, overflow behavior and increment semantics for all four aggregate tokens.
- Whether all relevant commands use the same trusted transaction/function boundary and prevent direct client DML bypass.
- FK/trigger/function implicit lock edges and whether any edge violates the proposed rank order.
- PostgreSQL row-lock compatibility for each parent-fence mode, including the interaction between concurrent child writers, parent mutation, capacity rows and FK checks.
- Stable UUID ordering for multi-project capacity locks and multi-member child locks.
- Complete writer/finalizer inventory for project, session, assignment membership and T-14 population.
- Revalidation after every lock wait; no reliance on pre-lock authorization/state reads.
- CAS race tests: two clients with same expected version; exactly one semantic mutation succeeds.
- Parent-fence races: child creation vs project/session close; no late child work after successful close.
- Membership races: concurrent CMD-015 batches; stale batch rejected; no partial roster mutation.
- Capacity races: concurrent grant/assignment/cap changes; qualifying population never exceeds cap.
- Deadlock and serialization retry policy with bounded retries and typed outcomes.
- Audit and idempotency writes commit atomically with each semantic mutation.

## 8. Explicit unresolved decisions

| ID | Decision required | Owner / evidence |
|---|---|---|
| AGC-01 | Approve or reject canonical BIGINT row_version convention and field map | Database + Engineering schema review |
| AGC-02 | Confirm CMD-015 expected_row_version request precondition and assignment aggregate semantics | Product/Engineering contract review; PO approval if product behavior changes |
| AGC-03 | Approve exact PostgreSQL parent lock modes and rank/implicit-edge graph | Database + independent concurrency review |
| AGC-04 | Prove complete T-14 qualifying-population writer inventory and capacity-row bootstrap | Engineering + Database + Security |
| AGC-05 | Define project/session closure blocker set and pending-intent/finalizer handling | Product + Engineering + Operations |
| AGC-06 | Define bounded deadlock/serialization retry behavior and audit/idempotency atomicity | Engineering + Database + QA |

No item in this register is marked APPROVED. This proposal does not amend the canonical physical schema, does not close LPR items, and does not authorize SQL, migration or source implementation.

## 9. Gate disposition

- CMD-009–016 concurrency design: **PROPOSAL WRITTEN; REVIEW OPEN**.
- Physical schema approval: **NOT APPROVED**.
- PostgreSQL lock compatibility / implicit-edge proof: **NOT EXECUTED**.
- Global lock graph acyclicity: **NOT CERTIFIED**.
- Application lock certification: **0/50**.
- G9: **NOT READY**.
- G10: **NOT ACTIVE**.

