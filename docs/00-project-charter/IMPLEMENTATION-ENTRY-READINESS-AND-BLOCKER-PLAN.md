# Implementation Entry Readiness and Remaining Blocker Plan

**Document ID:** IER-001  
**Version:** 0.1.1  
**Status:** CONTROLLED READINESS PLAN — NOT AN IMPLEMENTATION AUTHORIZATION  
**Date:** 2026-11-25  
**Repository baseline:** `main` at `7b57e200130807b3ac5adafb323794afd284691f`  
**Authority:** Root `AGENTS.md`, MIB-001, DGA-001, Decision Register, approved PRD/ADR, RTM-001, RAID-001 and QA Catalogue  
**Current gates:** G9 NOT READY; G10 NOT ACTIVE

## 1. Purpose

This document consolidates the remaining evidence required to move Dit. SD Inspection from documentation maturation to a verified scope freeze (G9), then to a separately authorized implementation phase (G10). It is a readiness control artifact, not a claim that the system is implementation-ready.

The approved product scope remains the IFP and Standing Bracket inspections for the Dit. SD inspection team. This document does not add personas, workflows, commands, permissions, physical objects, channels or institutional authority.

## 2. Verified repository baseline

At the time of this audit:
- Canonical branch: `main`.
- Main HEAD at audit time: `7b57e200130807b3ac5adafb323794afd284691f` (post-PR #22).
- PRs #14–#22 are merged; PR #18 records F05-T4, PR #19 records F05-T5, PR #20–#21 reconcile readiness/audit, and PR #22 reconciles F-04 writer-matrix evidence boundaries.
- Main contains NLA-001 v0.1.24, NLA-L05-TDR-001 v0.1.14 and QA Catalogue v0.7.3.
- RTM-001 v0.1.32 and RAID-001 v0.1.29 contain F05-T4/T5 traceability.
- Notification event candidates remain specification/review-only: 11 candidates, 0 technically admitted, 0 enabled.
- SES-001 remains PO-approved business semantics with technical command/security/physical/QA closure outstanding.
- No application source, SQL, migration, grants/RLS deployment, live database change, provider configuration, runtime test or deployment is represented as completed by this documentation baseline.
- CI/workflow evidence is ABSENT where no checks or workflow runs are returned. QA catalogue cases remain PLANNED / NOT EXECUTED.

## 3. Binding product decisions to preserve

### 3.1 Session-bound inspection and returned correction

Each physical-unit inspection attempt belongs to exactly one inspection session. Drafts, evidence, submission and returned correction remain bound to that same session. The responsible Inspector corrects and resubmits the returned attempt in the original active session. A claim, draft or attempt must not be resumed or transferred into another session.

### 3.2 Exceptional packed-unit ABORT

ABORT is permitted only when:
1. an inspection was submitted;
2. Reviewer returned it for an identified error;
3. the physical unit is already packed/boxed and prepared for shipment, making correction/reinspection impracticable;
4. the responsible Inspector submits a reasoned request; and
5. Admin/Korlap explicitly approves it.

If correction remains practicable, the same Inspector must use the normal correction/resubmission path in the original active session. Packing alone is insufficient. A generic unfinished or hanging attempt is not eligible.

Approved ABORT is terminal and auditable; it is not inspection approval, successful completion, good/defective classification or print completion. Preserve prior revisions, Reviewer return, evidence metadata and audit history. A later inspection requires a new attempt in its own session. Pending ABORT requests and unresolved unit attempts block final session closure. CMD-013 cannot create, approve or bulk-apply ABORT.

### 3.3 Notifications

Preserve POQ-01 immutable event-time candidate audience and no-widening retries; POQ-02 per-policy SLA and quiet-hours delivery deferral only; POQ-03 no dismiss/archive in MVP; and POQ-04's five approved transition outcomes. Notifications remain asynchronous and must not mutate inspection/session outcomes or grant resource access. All eleven event candidates remain NOT ENABLED until per-row technical and institutional admission evidence is approved.

## 4. Blocking workstreams before G9

| Workstream | Current evidence | Required closure evidence | Gate effect |
|---|---|---|---|
| F-04 eligibility writers | Writer inventory incomplete; 0 writers certified | Exact deployed writer inventory across RPCs, SECURITY DEFINER functions, triggers/cascades, direct DML, imports, sync, repair, scheduled jobs and emergency paths; prove no bypass and prove every selector-dependent writer participates in the approved serialization protocol | Blocking |
| F-03 global lock order | Resolver 0/40; application lock certification 0/50; graph not proven acyclic | Exact producer/finalizer call graphs, physical FK/trigger/helper edges, full lock unions, complete writer participation, static acyclicity proof and deterministic concurrency/deadlock evidence | Critical blocking |
| F05-T1 selector grammar | Candidate grammar documented; technical approval and complete per-event mappings pending | Security/Engineering approval, exact event-to-selector clauses, trusted participant/scope cardinality and dependency columns for each candidate | Blocking |
| F05-T2 dispatch matrix | Candidate matrix only | Per-event source/recipient/parent/current-scope decisions and approved dispatch profiles; no inferred recipient or universal predicate | Blocking |
| F05-T3 suppression/retry | Candidate taxonomy; retryable provider failure after SENDING has no approved legal transition | Approve complete delivery state graph, stable reason codes, retry owner/scheduler, bounded attempts/age/backoff/dead-letter/alerts, provider-specific outcomes and ambiguous-acceptance reconciliation | Blocking |
| F05-T4 audit evidence | Logical append-only envelope documented | Database physical representation/constraints/ordering/ACL and integrity method; Security/Engineering approval; callback validation; approved reason codes; written T-10 classification, purpose, retention, legal hold, disposition and audit-access policy | Blocking |
| F05-T5 atomic snapshot | Logical transaction boundary documented | Exact producer/finalizer transaction per event; admitted snapshot/header and policy pin; identity/scope keys, uniqueness/completeness/order; atomic rollback proof; approved L05 lock protocol and evidence | Blocking |
| SES-001 ABORT | PO semantics approved; exact technical contract remains open | Command identity, request/decision records, requester/approver SoD, permission/scope matrix, packed-state evidence policy, atomic state/claim/audit/event/idempotency write set, lock/RLS/schema and QA cases | Blocking |
| T-10 / institutional authority | Written approval absent in current evidence | Authorized written records/privacy classification, purpose, retention, legal hold, disposition, access/export and relevant network metadata decisions | Blocking |
| Instruments and source authority | IFP source/photo-slot status and Standing Bracket evidence/photo rules remain open | Controlled current instrument source, full item-by-item validation, evidence/photo rules and accountable approval | Blocking |
| Physical database and security | 48/48 table-name parity is static proposal comparison only | Independent review of tables, constraints, indexes, FK/trigger/function graph, RLS, grants/EXECUTE ACL, Storage policies and migration plan against approved contracts | Blocking |
| QA / CI / operations | QA PLANNED / NOT EXECUTED; CI evidence absent | Test mapping to admitted contracts; isolated DB test execution after G10; measurable SLO/load, backup/restore, monitoring, incident, rollback and operational acceptance evidence | Blocking |

## 5. Notification-specific acceptance boundary

- Source mutation, canonical event, audit, idempotency result, outbox intent, exact policy version, complete immutable recipient/scope snapshot and initial checkpoint must be one atomic producer transaction.
- One database-controlled UTC `audience_evaluated_at` is captured only at the approved serialization point and reused for every effective-time predicate.
- A fully evaluated empty audience must be distinguishable from missing, partial, unresolved or failed snapshot materialization. Ambiguous/incomplete state fails closed.
- After commit, fan-out/retry consumes only the committed snapshot/checkpoint; it never re-resolves membership, widens recipients, resets checkpoints or creates another source event/outbox.
- Provider I/O occurs outside the source transaction. Delivery attempts and suppression/reconciliation evidence are append-only; stale lease generations cannot finalize outcomes.
- User, worker and provider callback provenance must be independently authenticated. Sensitive message/evidence payloads, tokens, credentials, signed URLs, raw idempotency keys and full provider responses are excluded from durable logs.
- T-10 retention and disposition remain disabled/unset until written institutional approval. No retention duration or purge schedule is inferred.

## 6. Required order of work

1. Reconcile all current source-of-truth documents and resolve stale pointers/status contradictions.
2. Complete F-04 physical eligibility-writer inventory and exact selector dependency mapping.
3. Complete F-03 producer/resolver lock-union and global acyclicity proof; retain 0/40 and 0/50 until evidence-backed certification exists.
4. Close F05-T1 through T5 with Engineering, Database and Security approvals; resolve T-10 institutional decisions separately.
5. Complete SES-001 technical command/SoD/atomicity/physical/QA contract without inventing a command ID.
6. Close instrument/source authority and all remaining DGA blocking rows.
7. Reconcile 54 command contracts, permissions, schema/RLS/functions, operational controls and QA traceability.
8. Execute independent cross-document review and publish immutable G9 candidate baseline with evidence.
9. Obtain explicit G9 scope-freeze approval.
10. Record a separate G10 activation decision. Only then may implementation begin on a dedicated implementation branch under the updated AGENTS.md.

## 7. G9 evidence checklist

G9 cannot be marked PASS until all applicable items are linked to exact artifacts and accountable approvals:
- [ ] All blocking DGA rows closed with evidence, not narrative status alone.
- [ ] Product scope, acceptance criteria, source instruments and SES-001 behavior reconciled.
- [ ] All 54 command contracts and permission/SoD boundaries reviewed.
- [ ] F-04 writer inventory complete and bypass controls proven.
- [ ] F-03 global lock graph proven acyclic; resolver/application lock certification evidence-backed.
- [ ] F05-T1..T5 technically approved and physical contracts admitted, or explicitly excluded from the frozen scope with approved rationale.
- [ ] T-10/T-12 and other institutional approvals recorded by authorized authorities.
- [ ] Schema, RLS, functions, triggers, Storage, grants and migration design independently reviewed.
- [ ] QA cases mapped; required pre-implementation static reviews complete; runtime tests remain correctly gated to G10.
- [ ] CI, operations, backup/restore, security, privacy, incident and rollback requirements have an approved implementation plan.
- [ ] Independent cross-document audit reports no unresolved contradiction.
- [ ] Product Owner signs the exact immutable G9 baseline.

## 8. G10 activation checklist

G10 requires a separate explicit record after G9:
- [ ] G9 PASS evidence and immutable baseline SHA.
- [ ] Named implementation scope, branch and allowed environments.
- [ ] Engineering, Database and Security approvals for the first implementation slice.
- [ ] Approved migration/test strategy and isolated environment.
- [ ] Secrets/provider ownership and least-privilege plan.
- [ ] Explicit G10 activation approval and updated root AGENTS.md.

## 9. Current disposition

**Documentation progress:** F05-T1..T5 candidate specifications are synchronized across NLA-001, TDR, QA, RTM and RAID as of the current main baseline. This is meaningful documentation progress, not technical closure.

**G9: NOT READY. G10: NOT ACTIVE. Implementation: NOT STARTED / NOT AUTHORIZED.** No SQL, migration, grants, RLS deployment, source code, provider configuration, live database operation, runtime test, deployment or production data mutation is authorized by this plan.

## 10. Change control

Any change to approved product semantics requires a new Product Owner decision. Any institutional retention/privacy/records decision requires the relevant authorized institution. Technical admission requires Engineering, Database and Security evidence. Never turn a candidate proposal, planned test, static inventory or self-review into a certification claim.


## 11. F-03 / F-04 / SES-001 technical closure control — 2026-11-25

[PTCM-001 — Pre-Implementation Technical Closure Matrix](PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md) v0.1.0 now decomposes the remaining F-03 lock-order contradictions into nine explicit conflict classes and eight evidence exit artifacts; F-04 into a physical writer/bypass evidence package and writer-by-writer certification record; and SES-001 into ten technical decisions. This matrix is a controlled closure aid, not an approval or closure of any blocker.

Current verified baseline after PR #22: `main` at `7b57e200130807b3ac5adafb323794afd284691f`. The F-03 graph remains NOT PROVEN ACYCLIC; resolver certification 0/40; application lock certification 0/50; F-04 writer certification 0; SES-001 technical contract OPEN. QA remains PLANNED / NOT EXECUTED; CI/workflow evidence ABSENT where no checks/runs are returned. G9 NOT READY; G10 NOT ACTIVE.
