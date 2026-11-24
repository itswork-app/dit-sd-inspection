# Global Lock-Order and Concurrency Graph Reconciliation

**Document ID:** LOCK-GRAPH-001  
**Version:** 0.1.1  
**Status:** Engineering proposal — PO/Engineering/Security review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Scope:** CMD-001–054; shared aggregates, cross-command locks, asynchronous workers, idempotency and transaction boundaries  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Executive conclusion

The current command documentation contains a proposed global lock sequence, but it is not yet a proven global lock hierarchy or an acyclic concurrency graph.

- The command catalogue states: idempotency → capacity → canonical serial key → project/session/assignment → unit → association → inspection → evidence/document → append-only events.
- The CMD-011–020 review uses an expanded order: idempotency → capacity → project/session/assignment → instrument/version → affected child rows → append-only events.
- The CMD-021–030 review explicitly identifies CMD-026 as conflicting with the catalogue: the catalogue row describes unit → association → assignment/claim, while the detailed CMD-026 review requires canonical serial key → project/session/assignment → unit → association → inspection/claim.
- CMD-023/024 local recipes and other parent/child operations do not fully state all shared resources or their relative order.
- Worker lease claims, notification fan-out, provider callbacks, document rendering, print batches and attendance upload/finalization have independent transaction boundaries that must be reconciled without holding database locks over external I/O.

The repository therefore cannot currently claim that all command lock paths are deadlock-free, race-free or globally consistent. This document records observed conflicts and proposes a reviewable graph. It does not silently replace the canonical catalogue or authorize implementation.

**Disposition:** proposal only. CMD-026 remains unresolved. No lock cycle has been proven absent; no runtime lock graph, deadlock trace, PostgreSQL catalog or concurrent test was executed.

## 2. Authority and evidence boundary

Reviewed on branch `docs/t17-instrument-governance-t18-command-boundary`:

- Root `AGENTS.md` v1.2.0.
- PostgreSQL Command Contract Catalogue v0.2.0.
- Physical Database Schema and Integrity Specification v0.2.0.
- Privileged Command Boundary and Transaction Specification v0.1.0.
- CMD-001–010, CMD-011–020, CMD-021–030, CMD-031–040 and CMD-049–054 detailed reviews.
- CONCURRENCY-001 v0.1.0 and CMD-001–054 Cross-Command Reconciliation v0.2.0.
- DGA-001 v1.3.0 and notification worker design references.

Evidence is static document inspection only. No live Supabase catalog, PostgreSQL lock table, deployed function, query plan, transaction trace, RLS/grant, worker runtime, CI workflow or test result was inspected or executed. The catalogue's “approved global order” wording is not treated as proof that the complete hierarchy passed cross-command review; the detailed reviews themselves identify unresolved conflicts.

## 3. Locking vocabulary and invariants

| Term | Meaning | Constraint |
|---|---|---|
| Arbitration | Atomic claim of an idempotency key/request identity | Unique and transactionally scoped; replay must not repeat mutation |
| Serialization row | Shared row protecting a cross-row invariant, e.g. project capacity | Every command changing that invariant acquires the same serialization point first |
| Canonical-key arbitration | Lock/advisory/unique-key protocol for normalized unit identity | All writers derive the same key and use the same order |
| Aggregate lock | Parent/lifecycle row gating child operations | Parent/child protocol prevents child work racing with closure/deactivation |
| Child lock | Unit, association, claim, inspection, evidence, document or dependent row | Multi-row acquisitions are deterministic |
| Lease/fencing | Worker ownership generation/token with expiry | Stale worker cannot commit after reclaim; not a user row version |
| Append-only write | Event, audit, decision, revision or attempt insertion | Insert after required mutable-row locks; uniqueness is final arbitration |
| External effect | Storage/provider/rendering/network operation | Never while holding DB row locks; use durable intent and guarded finalization |

Mandatory invariants:

1. Every command mutating a shared invariant participates in the same serialization protocol.
2. Each command enumerates its complete lock set, including helper functions, triggers, foreign-key checks and uniqueness arbitration.
3. A transaction acquires locks only in the approved global order; it cannot acquire a lower-ranked resource after a higher-ranked one.
4. Same-class multi-row locks use a deterministic total order (stable primary key/canonical key), never incidental query-plan order.
5. Lock only invariant-bearing rows; use constraints for final arbitration.
6. Revalidate authorization, scope, status, effective time and capacity predicates after relevant serialization locks are held.
7. Row versions do not replace locks/constraints for cross-row invariants; locks do not replace idempotency or optimistic concurrency.
8. Required domain mutation, event, audit and idempotency result remain atomic. External effects use intent/outbox, lease, attempt and reconciliation state.
9. No lock is held across Storage, malware scan, image inspection, PDF rendering, email/push provider I/O or other network operation.
10. Deadlock/serialization/lock-timeout retry is safe only under the command's idempotency and retry contract.

## 4. Candidate canonical resource ranks — REVIEW REQUIRED

This is a candidate ordering to reconcile current sources, not an approved implementation order. A rank is a lock class; commands lock only applicable classes.

| Candidate rank | Resource class | Examples | Open point |
|---:|---|---|---|
| 0 | Idempotency arbitration | `idempotency_records`, command request key | Atomic claim before domain locks |
| 10 | Shared invariant/serialization rows | `project_capacity_settings` | Must precede role/assignment eligibility rows for T-14 |
| 20 | Canonical identity arbitration | instrument + normalized serial key; conflict identity | All unit writers use same key protocol |
| 30 | Project/session parents | `projects`, `sessions` | Deterministic UUID order |
| 40 | Assignment and instrument references | `operational_assignments`, `assignment_members`, `instruments`, `instrument_versions`, teams/locations | Relative assignment-versus-instrument order is OPEN |
| 50 | Canonical unit | `units` | Unit identity/lifecycle |
| 60 | Association episode | `unit_project_associations` | Exact project/unit relationship |
| 70 | Claim and inspection aggregate | `unit_claims`, `inspections` | Claim-versus-inspection order is OPEN |
| 80 | Evidence/document/attendance/print aggregates | evidence assets, documents, attendance records/documents, print batches | Relative ordering must be specified per command |
| 90 | Append-only facts | domain events, audit events, revisions, review decisions, delivery attempts | Insert after mutable-state checks |

Unresolved rank questions:

- CMD-026 detailed review supports canonical serial key → project/session/assignment → unit → association → inspection/claim, but its catalogue row contradicts this.
- CMD-023 review includes a unit-first recipe followed by project and association-key arbitration, inconsistent with the CMD-026 detailed recipe.
- CMD-011–020 adds instrument/version locks but does not consistently place them relative to assignment and unit resources.
- Capacity rank 10 is required for T-14 Inspector eligibility changes. CMD-005 revoke must lock capacity first when revoking Inspector eligibility; CMD-004 grant, CMD-014/015 membership changes and CMD-016 cap changes must share the same row and predicate.
- Claim-versus-inspection order, and evidence-versus-document/attendance/print order, are not fully defined.
- Notification and worker queue rows should not be pulled into a domain aggregate lock chain unless explicitly required. Source notification intent is inserted transactionally after source locks; workers claim queue rows in separate short transactions.

No command may be implemented using this candidate table until owners approve each unresolved relative ordering and the complete graph is rechecked.

## 5. Cross-command lock inventory and race matrix

| Commands | Shared resource / competing path | Required property | Current finding |
|---|---|---|---|
| CMD-004/005/014/015/016 | capacity row, roles, assignment members, accounts | All Inspector eligibility changes and cap changes lock the same capacity row first, then affected rows deterministically and re-evaluate the T-14 predicate | Capacity-first appears in reviews; exhaustive eligibility-changing paths remain open |
| CMD-009/010/011/012/013/014/015 | projects, sessions, assignments and child work | Parent closure/transition serializes with child creation/advance; no stale preflight commits after closure | Parent-first guidance exists; complete child-writer coverage unproven |
| CMD-017 | target plans/allocations, project/session | Draft edits and publication serialize against exact plan; published plan immutable | Business version is not draft CAS; allocation key/session relation open |
| CMD-018/019/020/021/014 | instruments, versions, assignments | Draft edit/publish/deactivation and new assignment selection serialize; pinned historical versions unchanged | Instrument-versus-assignment lock order unresolved |
| CMD-022/023/024/025/026/027 | canonical key, units, associations, conflict rows, claims | Canonical identity arbitration precedes project/assignment/unit/association/claim locks in one order | CMD-023/024/026 recipes conflict; CMD-026 catalogue conflict explicit |
| CMD-026/027/028/029/030/031/032 | claims, inspections, revisions, review decisions | Claim lifecycle and inspection/review transitions serialize on exact lifecycle rows | Claim-versus-inspection ordering and fencing incomplete |
| CMD-028–032/035 | inspections, revisions, sync operations | Online and sync operations cannot overwrite same aggregate; correct row version and revision identity checked | CONCURRENCY-001 maps proposal; approval remains open |
| CMD-029–032 | inspections, revisions, review events | Submit/return/approve/reopen prevent stale decisions and enforce one terminal decision per revision | Revision identity and aggregate version distinct; lock/unique contract incomplete |
| CMD-033/034/036 | evidence, documents and source revisions | Finalization binds exact source revision; no lock during upload/render; stale worker fenced | Job/outbox/lease schemas and worker ACL incomplete |
| CMD-037/038 | documents, print batches/events | Sequence allocation and batch outcomes stable under retries | Allocator/manifest/lease details open |
| CMD-039/040 | attendance records/documents | Upload/replacement and verification serialize on attendance aggregate and immutable document version | Physical relationship/upload intent/verification history incomplete; institutional authority blocked |
| CMD-049/050 | recipient notification row | Concurrent mark-read yields one set-once timestamp; pagination is read consistency, not write locking | Conditional idempotent update proposed; audit semantics open |
| CMD-051 | notification policy draft/version | Concurrent edits and publish compare exact draft version/hash; published snapshot immutable | Draft/hash lifecycle open |
| CMD-052 | notification outbox/fan-out | Bounded worker claims; uniqueness prevents duplicate inbox rows; lease reclaim fences stale worker | Worker principal/lease/ACL and checkpointing open |
| CMD-053 | delivery/provider callback | Dispatch, UNKNOWN, callback and retry idempotent per attempt identity; provider I/O outside transaction | Callback command boundary/provider capability unresolved |
| CMD-054 | escalation event/policy version | Concurrent scheduler ticks create one version-pinned event per policy step; no source state mutation | Scheduler identity, server clock and unique key open |
| CMD-045–048 | retention, incident, provider/release | No lock design until institutional authority, physical schema and operational ownership supplied | Authority-blocked |

## 6. Static deadlock-cycle analysis — incomplete

A deadlock cycle is possible when concurrent transactions acquire shared resources in opposite orders. The source documents expose these potential inversions; none has been reproduced against a database.

### 6.1 Unit/association/project

- CMD-023 review recipe: lock canonical unit row, then target project row and association-key range/unique key.
- CMD-026 detailed recipe: canonical serial key, then project/session/assignment, then unit, then association, then inspection/claim.
- CMD-026 catalogue row: unit → association → assignment/claim.

If one path holds unit then waits for project/assignment while another holds project/assignment then waits for unit, a cycle is possible.

**Closure:** normalize CMD-022 registration, CMD-023 association creation, CMD-024 end/revoke, CMD-025 conflict resolution, CMD-026 claim, CMD-027 release and CMD-028–032 inspection transitions to one approved lock set/order. Add opposing-command concurrency tests.

### 6.2 Capacity/eligibility

The intended invariant is capacity row first, then role/member/user rows. A path that locks user/role/member first and later requests capacity, including a helper/trigger, can invert this order.

**Closure:** inventory all paths changing qualifying Inspector status: account suspension/disable, role grant/revoke/expiry, assignment membership start/end and cap changes. Every path must use the same capacity serialization point and eligibility predicate, or an explicitly approved alternative.

### 6.3 Project/session closure

Parent closure locks project/session and evaluates child blockers. Child commands must lock/check the same parent before creating or advancing work. A child-first path can invert against closure.

**Closure:** enumerate commands, worker finalizers and background tasks creating/finalizing/advancing scoped work. Define a parent status fence and/or child lock protocol. A preflight SELECT is insufficient.

### 6.4 Instrument/assignment

Assignment publication locks project/session/assignment and published instrument/version references. Instrument publish/deactivation may inspect assignments. Opposite acquisition order can deadlock.

**Closure:** approve one relative rank for project/session/assignment versus instrument/version; preserve pinned historical versions.

### 6.5 Inspection/review/evidence

Claim and inspection commands touch unit/association/claim/inspection/revision/review/evidence rows. A path locking revision/evidence before inspection can invert against a path locking inspection first.

**Closure:** approve aggregate/claim/child order and apply it to submit, return, approve, reopen, sync and evidence finalization. Enforce unique active claim and one terminal review decision.

### 6.6 Worker queues and external effects

Worker claim transactions lock only queue/outbox/delivery rows, persist lease/fencing generation and commit. External work occurs after commit. Completion re-locks the queue item and validates worker identity, current fencing token, expiry and immutable source/version binding.

**Closure:** no worker transaction may hold a queue-row lock while acquiring a domain aggregate lock in reverse order. If finalization touches a domain aggregate, define a short transaction that acquires the full domain lock set in canonical order. Worker identities and ACLs remain unapproved.

## 7. Required per-command lock manifest

Every command contract must add a normalized manifest:

| Field | Required content |
|---|---|
| `command_id` | Stable CMD ID and contract version |
| `lock_classes` | Ordered resource classes from approved hierarchy |
| `lock_targets` | Exact table/row/key predicates |
| `multi_row_order` | Deterministic ordering key |
| `shared_invariants` | Capacity, canonical identity, parent lifecycle, active claim, terminal review, sequence, lease |
| `competing_commands` | All CMD IDs/workers touching the same invariant |
| `revalidation_after_lock` | Permission, scope, status, expiry, revision, version/hash and effective-time predicates |
| `constraints` | Unique/check/FK/exclusion constraints relied upon |
| `retry_semantics` | Deadlock/serialization/lock-timeout handling with idempotency |
| `external_boundary` | Intent, lease, I/O boundary, fencing and reconciliation |
| `tests` | Positive/negative and adversarial command-pair tests |

No command is lock-complete until its manifest is reviewed against all commands and implicit database objects.

## 8. Required concurrency tests — PLANNED / NOT EXECUTED

| ID | Concurrent scenario | Required assertion |
|---|---|---|
| LG-01 | CMD-004 grant vs CMD-016 cap reduction | Capacity invariant holds; no over-cap state |
| LG-02 | CMD-004 grant vs CMD-005 Inspector revoke | Shared capacity row; final qualifying count correct |
| LG-03 | CMD-014 assignment publish vs CMD-016 capacity update | Same T-14 predicate/serialization point |
| LG-04 | CMD-015 membership change vs CMD-005 revoke/account suspension | Eligibility remains correct |
| LG-05 | CMD-009/010 project close vs CMD-011/014 child creation | No child mutation commits after closure fence |
| LG-06 | CMD-012/013 session transition vs CMD-014/015 child mutation | Session closure and child work serialize |
| LG-07 | CMD-019 draft save vs CMD-020 publish | Stale draft cannot publish; published snapshot immutable |
| LG-08 | CMD-021 deactivate vs CMD-014 assignment publish | No new assignment selects invalid instrument |
| LG-09 | CMD-022 register vs CMD-023 associate | One canonical identity and valid active association |
| LG-10 | CMD-023 associate vs CMD-024 end/revoke | No duplicate active episode or invalid end |
| LG-11 | CMD-024 end association vs CMD-026 claim | Claim cannot attach to invalid association |
| LG-12 | CMD-025 conflict resolution vs CMD-023/026 | No duplicate active association |
| LG-13 | CMD-026 claim vs CMD-027 release | One valid claim lifecycle |
| LG-14 | CMD-026 claim vs CMD-028 save draft | No claim/inspection ownership mismatch |
| LG-15 | CMD-029 submit vs CMD-030 return/CMD-031 approve | One legal transition |
| LG-16 | CMD-030 return vs CMD-031 approve | One terminal decision for exact revision |
| LG-17 | CMD-031 approve vs CMD-032 reopen | Approved history preserved |
| LG-18 | CMD-028–032 online mutation vs CMD-035 sync | No stale overwrite or duplicate replay |
| LG-19 | CMD-033 evidence finalize vs CMD-032 reopen/CMD-029 submit | Finalization binds exact revision |
| LG-20 | CMD-036 render vs source revision change | Stale render cannot finalize |
| LG-21 | CMD-037/038 concurrent print batches | Unique monotonic sequence across retries |
| LG-22 | CMD-039 replace attendance doc vs CMD-040 verify | Verify exact immutable document version |
| LG-23 | CMD-050 simultaneous mark-read | One stable read timestamp |
| LG-24 | CMD-052 duplicate fan-out/lease reclaim | One inbox row per recipient; stale worker fenced |
| LG-25 | CMD-053 callback vs retry/UNKNOWN | One durable outcome per provider attempt |
| LG-26 | CMD-054 duplicate scheduler tick | One escalation per policy step/window |
| LG-27 | Opposing unit/association/claim paths | No deadlock under approved order |
| LG-28 | Project/session close vs every child writer | No post-closure child mutation |
| LG-29 | Deadlock/timeout then idempotent retry | No duplicate mutation/event |
| LG-30 | Audit append failure under competing commands | State/version changes roll back atomically |

Tests require deterministic fixtures, barriers/latches, bounded timeouts, isolation-level declaration and captured SQLSTATE/lock diagnostics. Run only against an isolated test database after implementation authorization. **No test above has been executed.**

## 9. Decisions and evidence required

| ID | Decision/evidence | Owner | Status |
|---|---|---|---|
| LGD-01 | Approve global resource ranks, including instrument/version and claim/inspection order | Engineering + Security + PO | OPEN |
| LGD-02 | Resolve CMD-023/024/026 lock conflict and catalogue CMD-026 row | Engineering + Security | OPEN |
| LGD-03 | Approve exhaustive T-14 eligibility path inventory and capacity protocol | PO + Engineering + Security | OPEN |
| LGD-04 | Approve project/session closure fence and complete child-writer list | PO + Engineering + Security | OPEN |
| LGD-05 | Approve instrument deactivation/publish/assignment lock interaction | PO + Engineering + Security | OPEN |
| LGD-06 | Approve claim/inspection/revision/evidence/review child ordering | PO + Engineering + Security | OPEN |
| LGD-07 | Approve document/print/attendance/worker lease boundaries | Engineering + Security + Operations; Institution for attendance | OPEN |
| LGD-08 | Approve worker identity, lease/fencing fields, ACL and callback boundary | Security + Operations + provider owner | OPEN |
| LGD-09 | Add reviewed lock manifests to all 54 commands and implicit worker paths | Engineering + QA | OPEN |
| LGD-10 | Execute adversarial concurrency/deadlock tests and retain evidence | Engineering + QA + Security | NOT EXECUTED |

## 10. Impacted sources after approval

After LGD-01–10 decisions, update as applicable: PostgreSQL Command Contract Catalogue; all seven detailed command reviews; Physical Database Schema and Integrity Specification; Privileged Command Boundary and Transaction Specification; NLA-001 and notification reviews; CONCURRENCY-001; Audit Event Catalogue; RTM; Test Case Catalog/UAT; RAID; CMD-001–054 Cross-Command Reconciliation; DGA-001.

Do not update canonical lock recipes to the candidate hierarchy before approval. Do not create migrations, indexes, functions, triggers, advisory locks or runtime code from this proposal.

## 11. Gate disposition

| Gate | Status | Reason |
|---|---|---|
| G3 data/transaction | NOT READY | Global lock hierarchy and resource ordering are not reconciled |
| G4 security | NOT READY | Worker identity/ACL and runtime function/privilege evidence remain open |
| G5 API/command | NOT READY | 54 proposed contracts lack complete normalized lock manifests |
| G7 QA/evidence | NOT READY | Concurrency/deadlock cases planned only; not executed |
| G9 scope freeze | NOT READY | LGD-01–10 and existing institutional/technical blockers remain |
| G10 implementation | NOT AUTHORIZED | No separate written authorization |

**Final disposition:** A cross-command lock/concurrency proposal has been recorded. Current documentation does not prove a globally acyclic lock graph or race-free command behavior. Resolve the listed decisions, update canonical contracts, and execute tests only after required gates and authorization.


## 12. Command-level manifest inventory update — 2026-11-24

[LOCK-MANIFEST-001 — Command-Level Lock Manifest Reconciliation CMD-001–054](COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) v0.1.0 now inventories source-stated lock/resource sequences for all 54 logical command IDs. It records 54/54 inventory coverage and 0/54 certified lock-complete based on the current static evidence. It explicitly preserves unresolved ordering rather than normalizing conflicting source contracts.

The manifest confirms the CMD-023/024/025/026/027/028 ordering issues, parent/child closure conflicts, T-14 eligibility path gaps, instrument/assignment rank gap, evidence/document/attendance finalization gaps, print sequence allocator gaps and notification worker fencing gaps. It is an evidence inventory, not an approved lock plan or proof of deadlock freedom. All new tests remain planned/not executed; G9 remains NOT READY and G10 NOT AUTHORIZED.
