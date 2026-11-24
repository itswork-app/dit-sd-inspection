# L05 Audience Guard — Internal Technical Review

**Document ID:** L05-REVIEW-001  
**Version:** 0.1.1  
**Review status:** REQUEST CHANGES — NOT TECHNICALLY APPROVED  
**Review date:** 2026-11-24  
**Reviewer capacity:** Internal technical reviewer acting for Product Owner interests; not an independent human Engineering, Database, Security or institutional sign-off  
**Reviewed artifact:** NLA-L05-TDR-001 v0.1.1  
**Reviewed branch:** `docs/notification-resolver-lock-closure`  
**Review scope:** static documentation and PostgreSQL semantics; no live database, code, migration, CI or runtime verification

## 1. Executive verdict

The global transaction-scoped advisory guard is a reasonable candidate for technical evaluation. The current TDR is **not ready for technical approval** and must remain a proposal. The review finds two correctness-critical omissions and several blocking completeness/governance gaps.

**Reviewer decision: REQUEST CHANGES.** Do not admit L05 into LOCK-GRAPH-001, do not certify any resolver path, do not approve candidate snapshot DDL, and do not activate implementation from this review.

The Product Owner's candidate-direction approval remains valid. This review does not revoke it; it distinguishes product direction from technical proof.

## 2. Findings

### F-01 — Function volatility and snapshot behavior are underspecified

**Severity:** BLOCKER / correctness-critical  
**TDR references:** §4.1, §4.2, §13

The TDR correctly requires lock acquisition and recipient resolution to execute as separate SQL commands under READ COMMITTED. However, the repository's approved execution architecture uses PostgREST RPC and narrow SECURITY DEFINER command wrappers. A client RPC is commonly one top-level SQL statement invoking a database function. The TDR does not specify the volatility category and execution form of the wrapper/helper.

PostgreSQL documents that VOLATILE functions obtain a fresh snapshot for each query they execute, whereas STABLE and IMMUTABLE functions use the calling query's snapshot. Merely writing two internal SQL statements is therefore not a sufficient contract if the wrapper is declared STABLE or IMMUTABLE, or if the actual execution path does not obtain the required fresh snapshot.

**Required correction:**
1. Explicitly require the source command wrapper that waits for L05 and then resolves the audience to be VOLATILE; prohibit STABLE/IMMUTABLE for this path.
2. Specify the actual PL/pgSQL/SPI or equivalent execution form and ensure the advisory-lock call completes before the resolver query begins.
3. Verify that the wrapper's subsequent resolver query receives a fresh READ COMMITTED snapshot after the wait, through the real PostgREST caller-JWT RPC path.
4. Add an adversarial test in which an eligibility writer commits while the source transaction is waiting for L05; assert the post-wait resolver sees the committed change.
5. Record the exact transaction isolation and volatility metadata for every participating wrapper/helper.

Reference: PostgreSQL Function Volatility Categories — https://www.postgresql.org/docs/current/xfunc-volatility.html

### F-02 — Event-time timestamp/linearization point is not defined relative to the L05 wait

**Severity:** BLOCKER / correctness-critical  
**TDR references:** §2, §4.1, §4.2, §6, §10, §13

The invariant requires an event-time audience, and the writer set includes effective intervals, role expiry, assignment membership, policy effective windows and parent lifecycle. L05 serializes cooperative writers, but it does not stop wall-clock time from advancing while a transaction waits.

PostgreSQL `now()` / `transaction_timestamp()` / `CURRENT_TIMESTAMP` represent transaction start time. A transaction can begin, wait for L05, and then resolve recipients using a timestamp that predates the wait. A grant or assignment may have expired during that wait, yet still appear eligible under a transaction-start timestamp. Conversely, a future effective interval may become active while waiting.

**Required correction:**
1. Define one authoritative `audience_evaluated_at` / event linearization instant, captured only after L05 has been successfully acquired.
2. Use a database wall-clock value such as `clock_timestamp()` at that point, capture it once, and pass the same value to every role/scope/assignment/capacity/policy effective-interval predicate and the immutable snapshot/outbox metadata.
3. Define inclusive/exclusive interval boundaries and precedence for policy effective_from/effective_until, role valid_from/valid_until, assignment membership and parent lifecycle.
4. State whether the canonical source event timestamp is this same instant or a separate business-event timestamp, and explain the relationship.
5. Add a test where a role or assignment expires while the source transaction is blocked on L05; prove the resolver uses the post-acquisition evaluation instant.

Reference: PostgreSQL Date/Time Functions — https://www.postgresql.org/docs/current/functions-datetime.html

### F-03 — The TDR does not reconcile L05 into the 40 source transaction paths

**Severity:** BLOCKER / deadlock and atomicity risk  
**TDR references:** §4.2, §4.3, §5, §11, §13  
**Source references:** LOCK-MANIFEST-001 §1/§4; NLA-RESOLVER-LOCK-001 §3/§4

The current command manifest explicitly states that source lock-order conflicts remain in CMD-023–028 and CMD-031–040. The resolver review separately maps 40/40 source event declarations but certifies 0/40 complete resolver lock paths. It identifies concrete cases where source transactions already acquire L30/L40/L50/L60/L70/L90 resources before candidate recipient locks, and asynchronous finalizers (notably CMD-036 and CMD-039/040) have separate request/finalization transaction boundaries.

The TDR gives a universal target sequence (L00 → L05 → …) but does not provide a command-by-command migration from the current source-stated order to that sequence. A rule that L05 must be first does not itself prove that existing transactions can obey it without reordering their locks or changing transaction boundaries.

**Required correction:**
1. Add a 40-row source-event matrix mapping each eligible event to its exact source command, actual transaction/finalizer boundary, current lock sequence, required L05 acquisition point, all post-L05 locks, and required redesign.
2. Explicitly resolve the already-blocked CMD-012/013, CMD-023–032 and CMD-036–040 paths; do not treat them as covered by the generic template.
3. For asynchronous finalizers, identify the finalizer as the event-producing transaction and prove L05 is acquired before its source/lease/aggregate locks while preserving source mutation + event + audit + outbox + snapshot atomicity.
4. Identify statically excluded event types only where exclusion cannot be changed by CMD-051 policy publication.
5. Re-run static lock graph analysis after the per-command remapping.

Until this matrix exists, the 0/40 resolver certification result must remain unchanged.

### F-04 — Eligibility writer matrix is category-level, not command/function complete

**Severity:** BLOCKER  
**TDR references:** §5, §6, §11, §13

The TDR itself says the final command-ID mapping is mandatory and that the category list is not a substitute. The actual list of every RPC, SECURITY DEFINER helper, trigger, import, administrative, repair, sync and scheduled path is still absent. It also does not establish which paths are denied direct DML versus forced through the guard.

**Required correction:** publish an exhaustive writer-to-command/function/trigger matrix with exact target tables, mutation types, acquisition point, authority boundary, bypass prevention and evidence. Every path capable of changing an enabled selector must participate before it takes any conflicting mutable row lock. A single bypass invalidates the global-guard proof.

### F-05 — Self-revocation and post-transition recipient semantics remain unresolved

**Severity:** HIGH  
**TDR references:** §4.2, §5, §13

The TDR instructs the implementation to “apply explicit post-transition semantics” for self/target role revoke, account suspension, assignment end and closure, but does not specify the expected audience. This affects whether the actor/target is included in the event snapshot, and whether the snapshot represents pre-state or post-state eligibility.

**Required correction:** obtain/record PO-approved expected outcomes for each transition class, then encode those outcomes in the source command contract and NRL tests. Do not leave this as an implementation-time interpretation.

### F-06 — Canonical PO decision register and cross-document version pointers are stale

**Severity:** MEDIUM / traceability  
**TDR references:** header and §15

The TDR header still names parent NLA-RESOLVER-LOCK-001 v0.1.6 while the branch currently contains v0.1.8. AGENTS.md names DECISION-REGISTER.md as the canonical PO approval record, but the L05 candidate approval is currently recorded in the TDR/review/RAID/DGA, not yet in the canonical Decision Register.

**Required correction:** synchronize the parent version pointer and add the exact candidate-direction decision, scope and non-authorization boundary to DECISION-REGISTER.md. Keep the TDR and register consistent.

### F-07 — Global guard performance acceptance is not measurable yet

**Severity:** HIGH  
**TDR references:** §8, §13

The TDR correctly leaves audience cardinality, lock timeout, retry budget and SLO values TBD. Consequently, no performance approval can be given. A single global exclusive guard serializes all participating source events and eligibility mutations; the proposed throughput bound is only a planning approximation.

**Required correction:** obtain approved workload/audience limits and measurable p95/p99 wait/hold/transaction budgets, then benchmark mixed source-event and eligibility-writer traffic at the maximum audience size. Define starvation/fairness and overload behavior, not only timeout/retry behavior.

## 3. Positive observations

- Transaction-scoped advisory locking is preferable to session-level locking for this short atomic unit because it is automatically released at transaction end.
- A single global key is easier to reason about than an early sharded/hash-based key model.
- The TDR correctly prohibits provider/network I/O while holding L05.
- The TDR correctly separates CMD-052 claim from fan-out and forbids recipient re-resolution/widening.
- The TDR recognizes FK KEY SHARE, unique-index, trigger, cascade and helper edges as part of the graph.
- The TDR correctly keeps numeric budgets and key constants unapproved rather than inventing them.

PostgreSQL advisory-lock semantics reference: https://www.postgresql.org/docs/current/explicit-locking.html

## 4. Required revision order

1. Close F-01 and F-02 first; without a provable snapshot and time linearization point, the audience invariant is not established.
2. Complete F-03 and F-04: 40 source-event transaction paths and all eligibility writers must be mapped exactly.
3. Resolve F-05 with explicit PO semantics and test expectations.
4. Close F-06 traceability drift.
5. Complete F-07 performance envelope and evidence.
6. Only then submit the revised TDR for Engineering/Database/Security technical approval and static graph certification.

## 5. Reviewer disposition and gate status

| Item | Reviewer disposition |
|---|---|
| PO candidate-direction decision | Remains APPROVED |
| PostgreSQL advisory transaction lock as candidate | ACCEPTABLE FOR FURTHER DESIGN |
| TDR v0.1.1 technical approval | REQUEST CHANGES |
| L05 canonical rank admission | NOT APPROVED |
| Resolver path certification | 0/40 — unchanged |
| Application lock certification | 0/50 — unchanged |
| Global graph acyclicity | NOT PROVEN |
| Candidate snapshot relation/header | NOT ADMITTED |
| NRL-T01..T10 | PLANNED / NOT EXECUTED |
| G9 / G10 | NOT READY / NOT ACTIVE |
| Code, SQL, migration, grants, RLS, runtime or deployment | NOT AUTHORIZED |

## 6. Evidence limitations

This review is based on repository documentation and official PostgreSQL documentation. No source code, deployed function metadata, live PostgreSQL/Supabase configuration, advisory-lock registry, catalog, query plan, trigger graph, CI run or concurrency test was inspected. No claim of runtime safety or independent institutional sign-off is made.


## 7. Revision response checkpoint — 2026-11-24

TDR v0.1.2 and the synchronized QA artifacts now specify the proposed response to F-01/F-02, with NRL-T11/T12 and TC-NOTIF-052/053. The response is documentation-only; deployed wrapper volatility, authenticated RPC snapshot behavior, effective-time policy approval and execution evidence remain absent. F-01/F-02 remain OPEN pending evidence.

[L05-SOURCE-MAP-001](../02-architecture/L05-SOURCE-EVENT-PATH-MAPPING-001.md) v0.1.0 provides a 40-row source-event/transaction-boundary mapping for F-03. It does not normalize the existing command lock sequences; 0/40 paths remain normalized/certified.

[NLA-L05-WRITER-MATRIX-001](../02-architecture/L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md) v0.1.0 advances F-04 by listing known command and non-command writer classes. It is explicitly partial because exact deployed functions, triggers, jobs, selector dependencies, ACLs and bypass evidence are unavailable. No writer is certified to participate in L05.

F-05 post-transition audience outcomes and F-07 measured contention envelope remain open. F-06 is partially addressed by updating the TDR parent pointer to NLA-RESOLVER-LOCK-001 v0.1.8 and recording the candidate-direction decision in canonical DECISION-REGISTER.md; remaining cross-document pointers still require a final audit.


## 8. Remaining decision/evidence checkpoint — 2026-11-24

F-05 remains OPEN. TDR v0.1.2 now recommends pre-transition eligibility as the default because resolution precedes the source mutation, but this is not a Product Owner decision. Explicit outcomes are still required for role revoke, account rejection/suspension, assignment-member end, project/session closure and self-revoke.

F-07 remains OPEN. NRL-T13 / TC-NOTIF-054 now specify the mixed-load benchmark and the required measurements (p50/p95/p99 lock wait/hold/transaction latency, throughput, timeout/deadlock/retry rates, queue age, audience cardinality and database I/O). Numeric workload limits and SLO thresholds remain unapproved and no benchmark has been run.

F-06 is partially remediated: TDR parent pointer now names NLA-RESOLVER-LOCK-001 v0.1.8 and the L05 candidate-direction decision is recorded in the canonical Decision Register. The lock manifest and other cross-references were synchronized where found; a repository-wide link/version audit remains pending.


## 9. Current cross-reference and CMD-031–040 response — 2026-11-24

F-06 is closed for the scoped L05 cross-reference set. The current pointer set is NLA-001 v0.1.8; parent resolver review v0.1.9; TDR v0.1.2; source map v0.1.0; writer matrix v0.1.1; LOCK-MANIFEST-001 v0.4.30; LOCK-GRAPH-001 v0.4.23; RTM v0.1.8; RAID v0.1.7; DGA v1.11.60; QA v0.4.5; cross-command reconciliation v0.8.26. Historical source references remain in their dated checkpoints.

F-03 has advanced but remains OPEN: CMD-031/032/033/034/037 have partial candidate lock ordering in LOCK-MANIFEST-001 §7.13; CMD-035/036/038/039/040 remain blocked. The source map is an inventory, not proof of all held locks, function/finalizer call graphs, or a cycle-free total order. F-04 remains OPEN because the writer matrix is incomplete and no physical writer is certified. F-05 transition semantics and F-07 measured contention envelope remain OPEN.

Reviewer disposition remains REQUEST CHANGES — NOT TECHNICALLY APPROVED. L05 remains unadmitted; resolver certification 0/40; application lock certification 0/50; global graph NOT PROVEN ACYCLIC; candidate snapshot relation/header NOT ADMITTED; NRL-T01..T13 and TC-NOTIF-001..054 PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.
