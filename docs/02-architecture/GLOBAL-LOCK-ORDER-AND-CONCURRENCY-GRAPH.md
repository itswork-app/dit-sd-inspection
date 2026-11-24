# Global Lock-Order and Concurrency Graph Reconciliation

**Document ID:** LOCK-GRAPH-001  
**Version:** 0.4.21
**Status:** Engineering proposal — PO/Engineering/Security review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Scope:** CMD-001–054; shared aggregates, cross-command locks, asynchronous workers, idempotency and transaction boundaries  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT ACTIVE (conditional PO authorization received; activation remains gated by verified G9 and a separate G10 activation record).

**Current gate interpretation (2026-11-24):** Dated historical sections below that say “G10 NOT AUTHORIZED” are preserved snapshots from before the Product Owner's conditional implementation authorization. The current controlling state is G9 NOT READY and G10 NOT ACTIVE; implementation remains gated by verified G9 and a separate G10 activation record.

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

Reviewed on branch `docs/audit-lock-and-identity-reconciliation` on 2026-11-24:

- Root `AGENTS.md` v1.2.0.
- PostgreSQL Command Contract Catalogue v0.4.1.
- Physical Database Schema and Integrity Specification v0.3.0.
- Privileged Command Boundary and Transaction Specification v0.2.0.
- CMD-001–010, CMD-011–020, CMD-021–030, CMD-031–040, CMD-041–044, CMD-045–048 and CMD-049–054 detailed reviews.
- CONCURRENCY-001 v0.1.3 and CMD-001–054 Cross-Command Reconciliation v0.8.5.
- DGA-001 v1.11.10 and NLA-001 / notification worker design references.

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
| L00 | Idempotency arbitration | `idempotency_records`, actor + command + scope + key | Atomic claim before domain locks; same-key/different-hash rejects |
| L10 | Shared invariant serialization | `project_capacity_settings` and other approved cross-row serialization rows | Must precede all eligibility-changing role/assignment paths for T-14 |
| L15 | Principal/account aggregate | `app_users` | Stable user UUID order; account eligibility and target-principal state |
| L16 | User-role grant aggregate | `user_roles` | Stable (user_id, role_id, grant_id) order |
| L17 | User-scope grant aggregate | `user_scope_grants` | Stable (user_id, scope_type, scope_id, grant_id) order |
| L18 | Mutable authorization catalog (conditional) | `roles`, `permissions`, `role_permissions` | Freeze during normal operations or approve a separate rank/change protocol; do not assume immutable without evidence |
| L20 | Canonical identity arbitration | `(instrument_type, serial_normalized)` and conflict identity | All unit writers derive and arbitrate the same canonical key |
| L30 | Project/session lifecycle parents | `projects`, `sessions` | Parent fence before child work; multiple parents in stable ID order |
| L40 | Instrument and immutable version references | `instruments`, `instrument_versions` | Validate active/selectable status and pin immutable version |
| L50 | Assignment and operational grouping | `operational_assignments`, teams, locations | Deterministic UUID order; revalidate eligibility after parent/instrument checks |
| L55 | Assignment membership | `assignment_members` | Stable (assignment_id, user_id, membership_id) order |
| L60 | Canonical unit | `units` | Unit identity/lifecycle after canonical identity and scoped parents |
| L70 | Association episode | `unit_project_associations` | Exact active association revalidated after lock |
| L80 | Claim aggregate | `unit_claims` | Claim lifecycle before inspection lifecycle; unique active claim is final arbitration |
| L90 | Inspection aggregate | `inspections` | Inspection state/version and current revision revalidated after lock |
| L100 | Dependent mutable aggregates | evidence intents, attendance records, document jobs, print batches, notification policy/inbox/delivery projections | Exact per-command sub-order and source-version binding; no external I/O while held |
| L110 | Append-only facts | revisions, review decisions, domain/audit events, delivery attempts, escalation/access events | Insert after mutable-state validation; uniqueness constraints remain final arbitration |

### 4.1 Identity and authorization rank proposal — APPROVAL OPEN

The refined candidate table now proposes L15 for app_users, L16 for user_roles, L17 for user_scope_grants and conditional L18 for mutable roles/permissions/role_permissions. These rows are mutable authorization-bearing aggregates, not append-only facts and not L50 assignment membership. LPR-11 remains OPEN because Engineering/Security have not approved the ranks, actor/target lock strategy, grantor-authority freshness or the relation to L10/L20/L30/L50/L55. No rank is approved by this proposal.

Unresolved rank questions:

- CMD-026 detailed review supports canonical serial key → project/session/assignment → unit → association → inspection/claim, but its catalogue row contradicts this.
- CMD-023 review includes a unit-first recipe followed by project and association-key arbitration, inconsistent with the CMD-026 detailed recipe.
- CMD-011–020 adds instrument/version locks but does not consistently place them relative to assignment and unit resources.
- Capacity rank 10 is required for T-14 Inspector eligibility changes. CMD-005 revoke must lock capacity first when revoking Inspector eligibility; CMD-004 grant, CMD-014/015 membership changes and CMD-016 cap changes must share the same row and predicate.
- Claim-versus-inspection order, and evidence-versus-document/attendance/print order, are not fully defined.
- Notification and worker queue rows should not be pulled into a domain aggregate lock chain unless explicitly required. Source notification intent remains atomic with the source event, but POQ-01 candidate recipient/scope snapshot introduces potential lower-rank eligibility and implicit FK KEY SHARE edges; its lock order is not yet proven. Workers claim queue rows in separate short transactions.

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
| CMD-052 | notification outbox/fan-out | Bounded worker claims; immutable POQ-01 event-time recipient/scope candidate set; uniqueness prevents duplicate inbox rows; lease reclaim fences stale worker | Candidate relation/header not admitted; source-event snapshot may introduce implicit FK KEY SHARE edges against L15/L30/L50/L55 resources; worker principal/lease/ACL open |
| CMD-053 | delivery/provider callback | Dispatch, UNKNOWN, callback and retry idempotent per attempt identity; provider I/O outside transaction | Callback command boundary/provider capability unresolved |
| CMD-054 | escalation event/policy version | Concurrent scheduler ticks create one version-pinned event per policy step and its own event-time candidate/scope snapshot; no source state mutation | Candidate snapshot lock order/implicit FK edges, scheduler identity, server clock and unique key open |
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
| LG-31 | Concurrent CMD-022 registration of the same instrument_type + normalized serial from different projects | Exactly one canonical unit exists; losing request becomes a controlled conflict with reason/audit; no cross-project activity disclosure |
| LG-32 | Concurrent CMD-022 registration of the same serial under different instrument_type values | Both canonical units may exist; no false cross-type collision |
| LG-33 | Concurrent CMD-026 claims for the same canonical unit from different projects/assignments | At most one ACTIVE claim globally; loser receives a typed conflict; no scope escalation |
| LG-34 | Claim expiry/takeover vs CMD-027 release and CMD-028 save-draft | Exactly one legal claim outcome; stale/expired claim cannot authorize a new draft mutation |
| LG-35 | T-14 role grant/revoke/expiry, account disable/suspension, assignment-member start/end/expiry vs CMD-004/005/015/016 | Every eligibility-changing path uses the same approved serialization point and exact predicate; no over-cap or stale qualifying count |
| LG-36 | Pending-account approval/activation vs role grant and operational assignment provisioning | Pending/rejected/disabled account never becomes operational or capacity-eligible through a race |
| LG-37 | CMD-020 instrument-version publish vs CMD-021 deactivation vs CMD-014 assignment publish | Assignment pins one exact published version; inactive instrument cannot be newly selected; no mutable published snapshot |
| LG-38 | Explicit safety withdrawal vs already-pinned sessions and in-flight inspection work | Only authorized, reasoned, audited withdrawal can override default historical pinning; affected work follows one deterministic disposition |
| LG-39 | Project/session closure vs asynchronous document, notification and provider finalizers | No stale worker can finalize scoped work after the parent fence; fencing and parent state are revalidated |
| LG-40 | CMD-051 notification policy publication vs CMD-052 fan-out | Each recipient notification binds one immutable policy version; concurrent publication cannot produce mixed policy evaluation |
| LG-41 | Concurrent same idempotency key/same hash vs same key/different hash | Same semantic request resolves to one durable outcome; different hash rejects; no duplicate mutation/event/external intent |

Tests require deterministic fixtures, barriers/latches, bounded timeouts, declared isolation level, captured SQLSTATE/lock diagnostics, and final invariant snapshots. Run only against an isolated test database after implementation authorization. **No test above has been executed.**

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

[LOCK-MANIFEST-001 — Command-Level Lock Manifest Reconciliation CMD-001–054](COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) now inventories source-stated lock/resource sequences for all 54 logical command IDs. It records 54/54 inventory coverage and 0/54 certified lock-complete based on the current static evidence. It explicitly preserves unresolved ordering rather than normalizing conflicting source contracts.

The manifest confirms the CMD-023/024/025/026/027/028 ordering issues, parent/child closure conflicts, T-14 eligibility path gaps, instrument/assignment rank gap, evidence/document/attendance finalization gaps, print sequence allocator gaps and notification worker fencing gaps. It is an evidence inventory, not an approved lock plan or proof of deadlock freedom. All new tests remain planned/not executed; G9 remains NOT READY and G10 NOT AUTHORIZED.


## 13. Lock protocol decision-resolution proposal — 2026-11-24

[LOCK-PROTOCOL-DECISION-RESOLUTION-001](LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.3.2 consolidates a candidate monotonic resource order and explicit recommendations for CMD-022–027, CMD-028–032/035, project/session closure, T-14 capacity, instrument/assignment interaction, evidence/document/attendance/print, and notification worker/callback boundaries. It assigns PO, Engineering, Security, institutional and Operations decision ownership.

**Disposition:** proposal only; not an approved lock protocol and not proof of an acyclic graph. Canonical command contracts and physical schema remain unchanged. 54/54 commands remain inventoried and 0/54 certified lock-complete. All tests remain PLANNED / NOT EXECUTED. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED.

## 14. Candidate-rank and notification boundary reconciliation — 2026-11-24

The rank table in §4 is now aligned with the candidate L00–L110 vocabulary in LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.2. This corrects the prior graph's compressed 0–90 model, which combined instrument with assignment, claim with inspection, and omitted the dependent-mutable versus append-only distinction. The candidate order remains unapproved; the change is a documentation reconciliation, not Engineering/Security approval.

CMD-049–054 must be interpreted as follows:
- CMD-049: recipient-owned read only; MVCC/read consistency and actor/filter-bound cursor, no mutation lock.
- CMD-050: one recipient-owned read-state projection in a short guarded transaction; delivery state remains separate; expected_version remains unresolved against the physical schema.
- CMD-051: policy draft/version and effective-scope serialization in one short policy transaction; immutable published version and append-only audit fact; exact draft/hash/interval arbitration remains open.
- CMD-052: isolated bounded outbox claim transaction with lease/fencing generation, committed before fan-out; separate fan-out transaction consumes immutable POQ-01 event-time recipient/scope candidates and creates inbox/delivery projections with unique arbiters; no provider I/O. Candidate relation is NOT ADMITTED.
- CMD-053: exact delivery claim/outcome transactions and append-only attempt facts; provider I/O outside transactions; callback authentication and logical command mapping remain open.
- CMD-054: server-UTC due evaluation against pinned policy version; unique escalation fact, outbox intent and its own event-time recipient/scope snapshot committed atomically; no source business-state mutation.

The notification queue is not a license to acquire queue locks and then domain aggregate locks. If any future worker operation must mutate a source aggregate, it must release its queue claim transaction, start a new transaction, acquire the full approved L30–L100 source chain in ascending order and validate the fencing generation. Physical queue tables, unique/FK indexes, triggers, helper calls, worker identity, function owner, EXECUTE ACL and provider callback runtime remain NOT VERIFIED.

## 15. Historical CMD-001–010 identity-rank gap — superseded by §19

LOCK-MANIFEST-001 (current branch revision) adds a row-level overlay for CMD-001–010. It separates mutable resource rows, unique-key arbiters, append-only facts, competing command paths and unresolved physical evidence.

Key conclusions:
- CMD-001 uses own-identity upsert/unique auth_user_id arbitration; a missing app_users row cannot be treated as an already-lockable row.
- CMD-002/003 share one target-account transition protocol. Their actor authorization freshness, terminal-decision uniqueness and account row-version semantics remain open.
- CMD-004/005 must acquire the same T-14 project capacity serialization row before any row whose mutation changes the qualifying Inspector population. The current rank table does not classify app_users/user_roles, so capacity-first is only a partial order, not a complete normalized path.
- CMD-006/007 need an explicit order among target principal, grantor authority, scope parent and user_scope_grants, plus a revocation-freshness contract.
- CMD-008 relies on unique normalized project-code arbitration, not a preflight row lock.
- CMD-009/010 use the project parent candidate rank L30. All project-scoped child writers must acquire the parent fence before child resources, then revalidate project state after any wait. Child-first writers can deadlock against closure or commit stale work after closure.
- CMD-010's blocker inventory, parent lock mode, child-writer coverage and physical project row-version token remain unresolved.

LPR-11 is added to LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.1 to define and approve identity/account/authorization lock classes and their order relative to T-14 capacity, project/session parents and assignment membership. This historical checkpoint is superseded by §19, which proposes L15–L18 and candidate-normalizes CMD-001–010 at documentation level. LPR-11 technical approval remains OPEN. This does not close DGA-B18/B19, prove an acyclic graph, certify deadlock freedom or authorize implementation.

## 16. Project/session parent-fence lock-mode reconciliation — CMD-010–015 — 2026-11-24

Static review of CMD-011–015 detailed contracts identifies four different parent-fence patterns:
- CMD-011 proposes locking the project FOR KEY SHARE before session insertion.
- CMD-012 locks the session row before resolving the parent project.
- CMD-013 locks the session row before closure dependencies and does not specify a project-parent lock first.
- CMD-014 lists project/session/assignment reference locks after the T-14 capacity row, while CMD-015 locks capacity, assignment, members and users without explicitly listing project/session parent locks.

This is not one consistent parent-first protocol. In addition, PostgreSQL's row-level lock matrix matters: FOR KEY SHARE is compatible with FOR NO KEY UPDATE; an UPDATE that does not modify key columns normally acquires FOR NO KEY UPDATE. Therefore CMD-011's proposed FOR KEY SHARE does not, by itself, prove serialization against CMD-010's ordinary non-key project status UPDATE. See PostgreSQL Explicit Locking §13.3.2 and Table 13.3: https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS.

Required design closure:
1. Select a project/session parent-fence lock mode or other serialization primitive that demonstrably conflicts between closure and every child writer.
2. Acquire parents before child aggregates in every path; redesign CMD-012/013 session-first sequences.
3. Ensure CMD-014/015 explicitly lock required parent rows, not merely read them.
4. Revalidate parent lifecycle after waits and before child mutation.
5. Have CMD-010 acquire the parent fence before child blocker rows and re-evaluate blockers under a transactionally consistent policy.
6. Verify the exact behavior against the deployed PostgreSQL major version and physical schema before certification.

The source evidence establishes a design gap, not the deployed lock graph. No PostgreSQL catalog, SQL, lock trace or concurrency test was executed. LPR-01 and LPR-07–LPR-11 remain open; G3/G7/G9 NOT READY and G10 NOT AUTHORIZED.


## 17. Refined candidate order and parent-fence review proposal — 2026-11-24

[TECH-RESOLUTION-LPR-001](ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) §3–§4 proposes additional L15 app_users, L16 user_roles, L17 user_scope_grants and conditional L18 authorization-catalog ranks. It also proposes project-before-session ordering and compatible child FOR SHARE / parent mutation FOR NO KEY UPDATE modes, subject to Engineering/Database/Security approval and deployed PostgreSQL verification. The graph remains a proposal: no effective function/trigger/FK/index graph or acyclic proof exists. LPR-01/LPR-07/LPR-11 remain OPEN; no rank certification changes.


## 17.1 Rank-table synchronization — 2026-11-24

The candidate rank table now includes L15–L18 and L55 as proposed in TECH-RESOLUTION-LPR-001 v0.1.0. The table is a proposal only. LPR-01/LPR-11 remain OPEN; no acyclic proof or command certification is claimed.


## 18. Current source-version refresh — 2026-11-24

This graph now consumes the current candidate sources: PostgreSQL Command Contract Catalogue v0.4.1; CMD-011–020 Detailed Contract Review v0.3.6; CONCURRENCY-001 v0.1.3; CMD-001–054 Cross-Command Reconciliation v0.8.4; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.4; LOCK-MANIFEST-001 v0.4.7; TECH-RESOLUTION-LPR-001 v0.1.0; DGA-001 v1.11.8. Version synchronization is not technical approval. LPR-01/LPR-07–LPR-11 remain open; LPR-10 not executed; no lock graph is certified acyclic.


## 19. CMD-001–010 candidate edge normalization — 2026-11-24

**Authority:** candidate overlay only; see CMD-001–010 Detailed Contract Review v0.3.4 §9 and LOCK-MANIFEST-001 v0.4.10. No Engineering/Database/Security approval or acyclic proof is implied.

### 19.1 Candidate edge set

- `CMD-001`: L00 → L15 own account row; if no row exists, unique `auth_user_id` insert/upsert is the arbiter. A nonexistent row is not row-locked.
- `CMD-002/003`: L00 → conditional L10 for every affected T-14 project → L15 actor/target principal rows sorted by UUID → L16/L17 actor authorization grants → L18 catalog if mutable → L110 decision/audit. Both commands use one target-account state transition and terminal-decision protocol.
- `CMD-004/005`: L00 → conditional L10 → L15 sorted principals → L16 role grants → L17 delegation scope grants → L18 catalogue → L110 audit. The same L10 row set is shared with CMD-014/015/016 and every other eligibility-changing account/role path.
- `CMD-006/007`: L00 → conditional L10 if the scope mutation changes the T-14 predicate → L15 principals → L16 where role authority is involved → L17 exact grants → L18 catalogue → L30 project/session parent → L50 location/team/assignment scope target → L110 audit. The concrete scope-type-to-physical-resource map remains open.
- `CMD-008`: L00 → L15/L16/L17/L18 actor authority → L30 normalized-code unique insert. Initialize the default capacity row atomically with the new project in the same transaction; this new-aggregate bootstrap is not a general permission to acquire L10 late on an existing project.
- `CMD-009`: L00 → L15/L16/L17/L18 actor authority → L30 project `FOR NO KEY UPDATE` candidate mode + CAS.
- `CMD-010`: L00 → conditional L10 if closure changes T-14 eligibility → L15/L16/L17/L18 actor authority → L30 project `FOR NO KEY UPDATE` candidate mode → closure blocker evaluation while the parent fence is held.

### 19.2 Candidate shared-invariant edges

| Shared invariant | Competing command paths | Required serialization / final arbiter | Remaining proof |
|---|---|---|---|
| One account identity and request lifecycle | CMD-001 first request/profile provisioning | Unique `app_users.auth_user_id` plus approved request-state owner | UPSERT predicate, Auth provisioning race, request-history entity, trigger/FK effects |
| One terminal account decision | CMD-002 approve vs CMD-003 reject | Same L15 target row + conditional transition + unique terminal decision identity | Eligible source states, terminal uniqueness, row_version and actor-authority freshness |
| Role grant lifecycle and delegation ceiling | CMD-004 grant vs CMD-005 revoke | Same L15 principal and L16 exact grant rows; L17 grantor ceiling rows | Interval/exclusion constraint, last-admin recovery, grant-history representation |
| Scope grant lifecycle and authorization freshness | CMD-006 grant vs CMD-007 revoke | Same L15 principal and L17 exact scope-grant rows; parent L30/L50 as needed | Scope hierarchy, inheritance, cache/token invalidation and overlap arbiter |
| Project normalized-code uniqueness and capacity initialization | CMD-008 concurrent create | Unique normalized-code key; project + capacity row atomic bootstrap | Canonical normalization/collation, physical key, hidden FK/trigger edges |
| Project metadata vs closure vs children | CMD-009 / CMD-010 / CMD-011–054 | Project `FOR NO KEY UPDATE` conflicts with child `FOR SHARE`; child revalidates after wait | Every child and worker path must actually take the fence; closure blockers and CAS must be complete |
| T-14 Inspector qualifying count | CMD-002/003 when eligibility changes; CMD-004/005; CMD-006/007 if applicable; CMD-014/015/016 | Same L10 capacity row(s), sorted by project UUID, before L15–L18 | Complete writer inventory, account/project/session predicate, affected-project discovery and missing-row policy |

### 19.3 Authorization freshness and deadlock constraints

- Actor and target principal rows at L15 must be acquired in sorted UUID order; never actor-first by convention.
- Actor role and scope grants are mutable resources. Commands must lock the exact L16/L17 grants used to justify authorization, or prove an equivalent serializable/revocation-fencing mechanism. A preflight permission read alone is insufficient.
- Any command that may change T-14 eligibility must discover the complete affected project set before L15, lock L10 rows in ascending project UUID order, and revalidate the set. A newly discovered lower-rank L10 after L15 is an abort/retry condition.
- If `roles`, `permissions` or `role_permissions` are mutable, they require enforced freeze or a separately approved L18 mutation protocol.
- CMD-010 closure relies on a project parent fence only if every project-scoped child writer/finalizer takes the matching project `FOR SHARE` before child resources. A missing child fence is a correctness defect, not an exception to be silently accepted.
- After waiting for L10 or a project parent fence, the capacity/blocker predicate must use a fresh post-fence READ COMMITTED statement snapshot, or SERIALIZABLE with retry. A REPEATABLE READ snapshot established before the lock wait can omit a transaction that committed while the closer waited and is therefore not sufficient by itself.
- Project/session close does not cascade-delete or rewrite child history. Pending durable intents/jobs must be explicitly included in the blocker/reconciliation policy.

### 19.4 Disposition

CMD-001–010 are candidate-normalized at documentation level. The effective graph still contains unverified implicit FK/index/trigger/function edges; LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 is NOT EXECUTED. The graph is not certified acyclic and lock-complete remains 0/54.


## 20. Current CMD-001–010 source refresh — 2026-11-24

The current candidate overlay is CMD-001–010 Detailed Contract Review v0.3.4 §9; LOCK-MANIFEST-001 v0.4.12; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.8; DGA-001 v1.11.14; QA Catalogue v0.3.3. The older §15 gap narrative is historical and superseded by §§19–20. Candidate design only; LPR-01/LPR-07/LPR-11 remain OPEN and 0/54 certified.


## 21. CMD-011–020 manifest integration checkpoint — 2026-11-24

LOCK-MANIFEST-001 v0.4.17 now contains a candidate resource-order overlay for CMD-011–020, derived from their detailed transaction/read-write contracts. The overlay records project/session parent fences, T-14 capacity-first participation, identity/scope rows, instrument/version ordering, and target-plan residuals. It intentionally retains unresolved physical and implicit database edges rather than declaring the global graph complete.

Integration findings:
- CMD-011–013 introduce/confirm the project-before-session candidate parent fence. The project-closure path CMD-010 must be analyzed against every session child writer, including FK/trigger/function paths and post-wait predicate snapshots.
- CMD-014–016 must share one L10 capacity serialization primitive and exactly the same qualifying-Inspector predicate as CMD-004. Candidate rank order alone does not prove the invariant if any role, membership, assignment or capacity writer is omitted.
- CMD-017 target-plan aggregate/child lock ranks are not yet certified; its project/session references and publication/history semantics require an explicit physical aggregate contract.
- CMD-018 canonical instrument-code uniqueness must be modeled as the actual unique-index arbitration path unless an approved explicit lock is introduced.
- CMD-019/020 instrument/version/child order requires database-level immutability and child-writer exclusion proof.

The manifest now has 20/54 candidate-normalized documentation rows (CMD-001–020) and 0/54 technically approved/certified. This count describes the manifest's candidate overlays, not an acyclic graph proof. LPR-01, LPR-07 and LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. The effective graph remains uncertified because implicit FK/index/trigger/function edges, exact lock modes and adversarial evidence are outstanding.


## 22. CMD-021–030 lock-manifest integration checkpoint — 2026-11-24

LOCK-MANIFEST-001 v0.4.18 adds candidate overlays for CMD-021–030. The integration exposes material conflicts that must remain visible in the global graph:

- CMD-023 source order (unit before project) conflicts with the candidate L30 project-before-L60 unit rank. The manifest records the global-rank candidate but preserves the source conflict for Engineering/Database resolution.
- CMD-025 source order (conflict row first) conflicts with canonical serial/project/unit ordering. The conflict row is not accepted as an executable first lock; its rank and safe locator/revalidation strategy remain open.
- CMD-026 preserves canonical serial-key arbitration before project/session/assignment, unit, association, claim and inspection. This path must be reconciled against all unit and claim writers.
- CMD-028/029/030 share the inspection aggregate serialization point; revision, response, evidence and review children must not be acquired first by a competing writer.
- CMD-021 deactivation must preserve published instrument versions and assignment history; CMD-022 canonical serial uniqueness is a unique-index arbitration path unless a reviewed design explicitly defines a separate lock.

The candidate manifest count is now 30/54 documentation-normalized (CMD-001–030); 0/54 are technically approved or certified. This is not a proof of an acyclic graph. Exact lock modes, implicit FK/index/trigger/function edges, complete competing-writer coverage, physical constraints, independent Engineering/Database/Security review and adversarial concurrency evidence remain open. LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED.


## 22. CMD-021–030 manifest integration checkpoint — 2026-11-24

LOCK-MANIFEST-001 v0.4.18 adds candidate resource-order overlays for CMD-021–030. The overlay records, without certifying, the canonical serial identity arbiter (L20), project/session and assignment parent references, unit/association/claim/inspection lifecycle resources, and dependent response/evidence/revision facts.

The cross-command review exposes the following graph obligations:
- CMD-022 registration, CMD-023 association, CMD-024 association end/revoke, CMD-025 conflict resolution and CMD-026 claim must converge on one canonical identity arbitration strategy. A unique index may be the final arbiter, but any explicit key/advisory lock must have one stable identity and rank.
- CMD-023/024 local ordering does not consistently include the project/session parent fence. The proposed L30-before-child sequence must be reviewed against all association writers and project/session closure.
- CMD-025 requires a lock rank for the conflict aggregate. Conflict-first ordering can invert with unit/association-first paths; no rank is assigned as approved by this checkpoint.
- CMD-026 is an explicit source conflict: its detailed contract orders canonical serial key → project/session/assignment → unit → association → claim/inspection, while the catalogue retains a legacy unit → association → assignment/claim sequence. No source precedence or physical lock mode is certified here.
- CMD-021 deactivation must serialize/revalidate against CMD-014 assignment publication on the instrument lifecycle resource; current local CMD-021 locking does not prove the competing writer participates.
- CMD-028 draft save, CMD-029 submit and CMD-030 return must share the inspection aggregate serialization and one terminal review-decision invariant with the approval path. Evidence/object-provider checks must not hold database locks across external I/O.

Manifest progress is now **30/54 candidate-normalized at documentation level; 0/54 technically approved/certified**. The candidate graph is not proven acyclic or lock-complete. Exact lock modes, implicit FK/index/trigger/function edges, conflict aggregate rank, complete competing writers, row-version and immutable revision constraints, and adversarial tests remain open. LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED.


## 23. CMD-031–040 lock-manifest integration checkpoint — 2026-11-24

LOCK-MANIFEST-001 v0.4.19 adds candidate transaction/resource overlays for CMD-031–040. The global graph must preserve these shared serialization and external-I/O boundaries:

- CMD-030 return, CMD-031 approve and CMD-032 reopen serialize on the inspection aggregate. Return/approve share one terminal-decision invariant; reopen cannot race a pending decision or create duplicate draft contexts.
- CMD-033 upload-intent reservation and CMD-034 confirmation are separate database phases. Private Storage inspection/token issuance occurs outside row locks; finalization re-locks and revalidates the pending intent.
- CMD-035 sync-batch uses deterministic inspection UUID lock order and independent durable per-operation outcomes; it is not an atomic multi-inspection transaction. Device identity/revocation remains a missing physical control.
- CMD-036 document generation uses a durable request/outbox and worker lease; rendering/Storage I/O occurs outside DB locks. Worker identity/lease/ACL are not specified.
- CMD-037 print sequence allocation serializes on the document aggregate. CMD-038 processes each batch item in its own short transaction; no batch-wide lock across printing.
- CMD-039 attendance document replacement creates a new immutable version. CMD-040 verification is bound to that exact version and must serialize one terminal decision; verification-history physical storage is missing.

Candidate manifest progress is now 40/54 documentation-normalized (CMD-001–040); 0/54 technically approved/certified. This is not proof of an acyclic effective database lock graph. Exact physical aggregates, worker/device identities, quota/sequence/verification constraints, lock modes, implicit FK/index/trigger/function edges, independent technical review and adversarial evidence remain open.


## 24. CMD-041–048 read-path and privileged-command gate integration — 2026-11-24

CMD-041 actual reporting and CMD-042 target reporting are bounded read paths, not write-lock participants. Their correctness depends on actor/scope authorization, stable cursor pagination, explicit source separation and a defined snapshot/watermark; no lock rank should be invented for them. CMD-043 audit reading is a separate sensitive read path: purpose and scope validation, SECURITY INVOKER/RLS, bounded cursor and anti-recursion are required. CMD-044 audit export remains non-executable until T-10 institutional records/privacy authority, export SoD, artifact lifecycle and external job model are approved.

CMD-045 retention/legal-hold, CMD-046 security incident review, CMD-047 provider configuration and CMD-048 production release remain deliberately outside the executable lock graph. Their authority/state models are blocked by institutional policy, schema/authority, provider ownership and release governance respectively. Do not assign candidate lock ranks to undefined privileged state machines and do not seed/grant their proposed permission labels.

Command boundary coverage: 50/54 commands have documented candidate execution/transaction boundaries (CMD-001–044 and CMD-049–054); CMD-045–048 remain hard-gated; 0/54 technically approved/certified. This coverage is not a proven acyclic graph. Report snapshot semantics, audit purpose/RLS/ACL, export lifecycle, privileged state models, worker identity/ACL, implicit PostgreSQL edges, independent review and adversarial runtime tests remain open.


## 25. Application lock-certification denominator reconciliation — 2026-11-24

The graph covers 54 stable traceability IDs, but CMD-045–048 are external control-plane responsibilities and have no application transaction or lock set. Accordingly, the application denominator is **50 commands**. Current static documentation records candidate execution/transaction boundaries for all 50 application commands; this is not normalized-manifest certification. **0/50 application commands are technically approved or certified lock-complete.** LPR-01, LPR-07–LPR-09 and LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. The effective PostgreSQL lock graph is not proven acyclic because exact lock modes, implicit FK/index/trigger/function edges, privileges and competing writer paths remain unverified. LOCK-MANIFEST-001 is synchronized to v0.4.24. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT ACTIVE.


## 26. Normalized application command register integration — 2026-11-24

[LOCK-NORMALIZATION-001](COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md) v0.1.1 consolidates 50 application command boundaries across mutation, bounded-read and notification/worker paths. The register is linked to CMD-PHYSICAL-CROSSWALK-001 v0.1.2 for proposed physical read/write sets. Both are source-normalization aids, not an approved lock protocol. It preserves the unresolved CMD-011–015 parent-fence modes, CMD-023/025 ordering conflicts, CMD-026 canonical-key order, CMD-028–031 inspection/review serialization, CMD-033–040 evidence/document/attendance dependencies, and CMD-049–054 worker/provider dependencies. Exact PostgreSQL modes and implicit edges remain unverified; the graph is not certified acyclic. LPR-09 OPEN; LPR-10 NOT EXECUTED; 0/50 certified; G9 NOT READY; G10 NOT ACTIVE.


## 27. POQ-01 notification audience snapshot lock-graph review — 2026-11-24

POQ-01 approves the product rule: resolve and durably persist event-time candidate recipients and their authorized source scope; retries reuse the same set; dispatch-time revalidation may suppress only. NLA-001 v0.1.5 proposes candidate relation `notification_outbox_recipients` plus candidate snapshot version/hash/count/completion fields on the outbox header. These are NOT ADMITTED and have no approved lock rank.

### 27.1 New potential lock edges

The proposed recipient relation may carry FKs to `app_users`, projects, sessions, locations and assignments. PostgreSQL FK validation may acquire implicit KEY SHARE locks on referenced rows. This creates a potential conflict with the existing candidate hierarchy:

- A source domain command may already hold L30 project/session and L50/L55 assignment/membership locks before appending the outbox recipient snapshot. Candidate FK validation can then touch L15 recipient accounts or other lower-ranked authorization resources.
- Account/role/scope revocation commands may acquire L15/L16/L17 before L30/L50/L55. If the source event snapshot path takes the reverse order, a cycle may be possible.
- CMD-052 may claim an outbox row before inserting inbox rows whose FKs touch recipient/scope references. The exact FK topology could therefore create a lower-rank-after-queue edge.
- CMD-054 may hold notification/policy/escalation rows before persisting a new candidate snapshot that references recipient and scope resources.
- CMD-053 provider callback deduplication has a separate unresolved provider-event identity/storage edge; it must not be conflated with the candidate recipient relation.

These are potential edges, not observed runtime deadlocks. No cycle is claimed proven; no acyclicity is claimed.

### 27.2 Required resolution before candidate admission

1. Inventory every source command/event that can create notification_outbox and map its complete already-held source locks.
2. Inventory all account, role, scope, assignment and parent lifecycle writers that can change candidate eligibility.
3. Define the event-time eligibility linearization point. A preflight SELECT alone is insufficient.
4. Specify whether recipient/grant/scope rows are locked in sorted L15/L16/L17 and applicable L30/L50/L55 order before source aggregate locks, or whether a temporal snapshot model provides equivalent consistency without conflicting row locks.
5. Include every implicit FK KEY SHARE, unique-index, trigger and helper-function edge for recipient snapshot and inbox inserts.
6. Prove that CMD-052 and CMD-054 do not acquire lower-ranked domain resources after queue/policy/notification locks.
7. Add deterministic opposing-transaction tests for grant revocation, assignment end, project/session closure, event snapshot, worker reclaim and duplicate fan-out.
8. Recompute the full effective graph and prove acyclicity only after the physical model and all source/worker paths are approved.

### 27.3 Candidate test intersections

- LG-41: event-time recipient snapshot vs concurrent role/scope revocation — one deterministic winner; no audience widening.
- LG-42: event-time snapshot vs assignment end and project/session closure — no stale or cross-scope recipient.
- LG-43: CMD-052 outbox claim/fan-out vs notification/source-scope FK checks — no reverse-rank acquisition or duplicate inbox rows.
- LG-44: CMD-054 scheduler tick vs recipient grant revocation and duplicate tick — one immutable candidate set and one escalation event.
- LG-45: stale CMD-052 lease generation vs concurrent fan-out retry — stale worker cannot finalize or alter candidate snapshot.

**Disposition:** POQ-01 product semantics APPROVED; physical snapshot representation NOT ADMITTED; candidate lock order OPEN; worker identity/ACL OPEN; provider callback dedup OPEN; global graph remains NOT CERTIFIED ACYCLIC. Application lock certification remains 0/50; G9 NOT READY; G10 NOT ACTIVE.


## 28. Complete notification source-producer lock coverage — 2026-11-24

LOCK-MANIFEST-001 v0.4.27 §7.7 now maps all 40 canonical application domain command event declarations (CMD-001–040) to their current candidate lock paths and lock dispositions. This closes a static producer-inventory gap only. It does not certify the event policy allowlist, recipient resolver locks or any source command lock path.

### 28.1 Source event producer classes

- CMD-001–034: command transaction source events. Where an immutable policy explicitly allowlists the exact event type, outbox intent and candidate audience snapshot must be committed atomically with that source event and audit record.
- CMD-035: operation-level sync events plus domain events emitted by individual operations. Each event instance must be bound to its durable operation result and transaction/savepoint boundary; batch-envelope completion is not a substitute.
- CMD-036: generated-document event is emitted by guarded renderer finalization, after source revision/template and worker lease validation.
- CMD-037: each print/reprint event is emitted by the guarded document/version sequence transaction.
- CMD-038: each item-level print event is distinct from the batch projection event and is bound to the durable item outcome.
- CMD-039: attendance upload/replacement event is emitted after private Storage verification and guarded document-version finalization.
- CMD-040: attendance verification event is emitted after exact document-version, verifier scope and SoD validation.

CMD-041/042 conditional report-access events and CMD-043/044 audit access/export events remain excluded from this mutation-producer inventory. Any read-side notification side effect requires a separately approved access-event transaction boundary. CMD-045–048 remain external control-plane IDs. CMD-049–054 are excluded from policy event matching by default to prevent recursive notification chains.

### 28.2 Lock graph coverage gap

The 40 producer rows currently describe each command's candidate source lock path, but do not yet include a complete recipient-resolution lock set. The resolver may need L15 principal, L16 role-grant, L17 scope-grant and applicable L30/L50 scope-parent resources. A producer may already hold L30/L40/L50/L60/L70/L90 before its source event is appended. Acquiring L15/L16/L17 at that point would be a potential lower-rank-after-higher-rank edge.

Asynchronous finalizers add separate edges: CMD-036 renderer lease/source-version fence; CMD-038 batch-item/document sequence; CMD-039 attendance/document version. The finalizer's actual held locks at event commit must be mapped separately from the initiating request's reservation path.

### 28.3 Required proof

1. Approve the exact event-type allowlist and all producers for each enabled type.
2. Bind every event instance to one command execution or finalizer transaction, including event cardinality and idempotency identity.
3. Identify the event-time audience linearization point and authoritative temporal source for role, scope and assignment membership.
4. Map the complete resolver lock set against every producer's already-held locks and all competing grant/revocation/assignment/project/session writers.
5. Enumerate implicit FK KEY SHARE, unique-index, trigger and helper-function edges.
6. Prove no reverse-rank acquisition in source commands, CMD-052, CMD-054 or callback/finalizer paths.
7. Recompute and prove the effective graph acyclic, then execute deterministic opposing-transaction tests.

**Disposition:** 40/40 source command event declarations statically mapped; 0/40 notification-recipient resolver lock paths certified. The candidate relation/header remain NOT ADMITTED. LOCK-GRAPH remains NOT CERTIFIED ACYCLIC; application lock certification 0/50; G9 NOT READY; G10 NOT ACTIVE.


## 29. Recipient-resolver serialization boundary — 2026-11-24

[NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001](NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) v0.1.2 classifies the 40 source paths in LOCK-MANIFEST-001 §7.7 and explains why command actor/target locks do not certify the full notification audience predicate. It proposes a global transaction-level audience guard at candidate L05 before L10/L15 and all source aggregate resources, with SERIALIZABLE predicate snapshot as an alternative. **L05 is a design option only, not an approved rank.** All account/role/scope/assignment/capacity/parent-lifecycle writers and policy publication would need consistent participation if selected. Candidate FK parents must still be acquired in deterministic L15/L30/L40/L50/L55 order. No new edge is considered closed; exact FK/trigger/helper behavior and full acyclicity remain unproven. Resolver certification 0/40; application lock certification 0/50; graph NOT CERTIFIED ACYCLIC; G9 NOT READY; G10 NOT ACTIVE.
