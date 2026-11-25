# Notification Event Registry — PO-Approved Specification Candidates

**Document ID:** NLA-EVENT-REGISTRY-001  
**Version:** 0.1.13  
**Status:** DRAFT — PO INTENT APPROVED FOR SPECIFICATION/REVIEW ONLY; ALL ROWS UNRESOLVED / NOT ENABLED; NREG-001..011 PARTIAL STATIC REVIEW ONLY  
**Date:** 2026-11-25  
**Baseline:** `main` at `f3248037c5754ca537c033422d3e247be34f931d`  
**Authority:** PRD-001, Decision Register PO event-candidate decision (2026-11-24), NLA-EVENT-TRIAGE-001 v0.1.3, CMD source-event map. This document does not supersede them.

## 1. Purpose and binding interpretation

This registry records exactly the eleven first-batch event candidates approved by the Product Owner for registry specification and Security/Engineering/Database review. Approval is limited to progressing these candidates through specification and review. It is **not** approval to enable publication, dispatch, recipient resolution, channels, templates, role grants, schema, code or implementation.

All rows are deliberately initialized as:

- `po_intent_status = APPROVED_FOR_SPECIFICATION_ONLY`
- `canonical_contract_status = UNRESOLVED`
- `recipient_mapping_status = UNRESOLVED`
- `selector_status = UNRESOLVED`
- `dispatch_profile_status = UNRESOLVED`
- `technical_review_status = PARTIAL_STATIC_REVIEW` (bounded static review only; not technical approval)
- `publication_status = NOT_ENABLED`

No physical event field, participant ID, role ID, scope column, selector expression, channel or dispatch predicate is inferred here. Conceptual workflow actors below are review questions only, not recipient mappings.

## 2. CMD-002/003/005/010/013/014/015/029/030/031/032 technical review checkpoint

NREG-001 through NREG-011 (including NREG-010 `inspection.approved` and NREG-011 `inspection.reopened`) received a partial static technical reconciliation in [NLA-EVENT-TECH-RECON-001 v0.1.7](NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md). The command-level candidate producer transactions and proposed source objects are identified, but deployed producers, canonical event envelopes/versions, participant projections, exact event identities, decision uniqueness, reviewer assignment, reopen authority/draft persistence, complete writer inventory, L05 order, and event/outbox/snapshot deduplication remain unresolved. This is not technical approval. All eleven rows remain `UNRESOLVED / NOT ENABLED`; no selector, recipient, channel, dispatch profile, schema or implementation is admitted.

For NREG-001 through NREG-011, `technical_review_status = PARTIAL_STATIC_REVIEW`; this means a bounded static pass only, not technical approval. All eleven rows still have `canonical_contract_status`, `recipient_mapping_status`, `selector_status`, and `dispatch_profile_status = UNRESOLVED`. The registry's publication status remains `NOT_ENABLED` for all eleven rows.

## 3. Approved candidate inventory

| Registry ID | Source CMD | Candidate event token | PO-approved purpose boundary | Conceptual recipient question (not a mapping) | Contract / dedup issue | Status |
|---|---:|---|---|---|---|---|
| NREG-001 | CMD-002 | `account.approved` | Notify about the applicant's account approval outcome | Which trusted account-request principal, if any, is selected by the approved event contract? | Exact producer, immutable event payload and target mapping unresolved | UNRESOLVED / NOT ENABLED |
| NREG-002 | CMD-003 | `account.rejected` | Notify about the applicant's account rejection outcome | Which trusted account-request principal, if any, is selected by the approved event contract? | Exact producer, immutable event payload and target mapping unresolved | UNRESOLVED / NOT ENABLED |
| NREG-003 | CMD-005 | `role.revoked` | Notify about a role revocation when the exact policy independently selects a candidate | Is the revoked target selected by the exact event selector? Actor is never implicit | POQ-04 pre-mutation candidate snapshot and post-revoke suppression rules are mandatory | UNRESOLVED / NOT ENABLED |
| NREG-004 | CMD-010 | `project.closed` | Notify scoped operational participants about committed project closure, only if selected | Which exact pre-close scoped participants are selected? | Must bind to committed close transaction; no blanket active-parent dispatch predicate | UNRESOLVED / NOT ENABLED |
| NREG-005 | CMD-013 | `session.closed` | Notify scoped operational participants about final committed session closure; not close request | Which exact pre-close scoped participants are selected? | Final `session.closed` producer/token and transaction boundary are not yet proven; `session.close_requested` is excluded | UNRESOLVED / NOT ENABLED |
| NREG-006 | CMD-014 | `assignment.created` | Notify only members explicitly selected for newly created operational assignment | Which inserted assignment members are selected by trusted event data? | Exact insert/member event contract, assignment scope and participant mapping unresolved | UNRESOLVED / NOT ENABLED |
| NREG-007 | CMD-015 | `assignment.changed` | Notify only selected members affected by a committed membership change | Which added/ended members are selected; are retained members excluded? | Must distinguish added, ended and retained membership; POQ-04 pre-end semantics apply | UNRESOLVED / NOT ENABLED |
| NREG-008 | CMD-029 | `inspection.submitted` | Notify the appropriate review workflow about a committed submitted revision | Which assigned Reviewer principal is selected by trusted assignment data? | Submission vs `inspection_revision.created` relationship, atomic boundary and dedup key unresolved | UNRESOLVED / NOT ENABLED |
| NREG-009 | CMD-030 | `inspection.returned_for_correction` | Notify the responsible inspection workflow about explicit return for correction | Which assigned Inspector principal is selected by trusted assignment data? | Exact inspection/revision/assignment mapping and return transaction unresolved | UNRESOLVED / NOT ENABLED |
| NREG-010 | CMD-031 | `inspection.approved` | Notify the responsible inspection workflow about committed approval | Which Inspector principal is selected by the approved event contract? | Exact approved revision and responsible Inspector mapping unresolved | UNRESOLVED / NOT ENABLED |
| NREG-011 | CMD-032 | `inspection.reopened` | Notify scoped operational participants about authorized reopening | Who owns the next action under the approved event contract? | Reopening authority, next-action owner and assignment mapping unresolved | UNRESOLVED / NOT ENABLED |

## 4. Shared invariants

1. POQ-01 and POQ-04 are binding: resolve an immutable event-time candidate set against serialized pre-mutation state at one captured `audience_evaluated_at`; include actor/target/affected member only if the exact approved selector selects them; commit source mutation, canonical event and candidate snapshot atomically; dispatch-time checks may suppress but never widen; retries reuse the same candidate set/checkpoint.
2. Event tokens must be exact canonical tokens. No wildcard, prefix match, slash alternatives, generic command token or arbitrary JSON/SQL selector.
3. A source event must be emitted at the authoritative committed transaction/finalization boundary. Action requests, audit records, batch envelopes and technical intermediate states are not substitutes.
4. Candidate identity and scope must come from trusted server/database source data. No client-supplied principal IDs or inferred institutional affiliation.
5. Dispatch authorization is event-specific. A role revoke, ended assignment or project/session closure must not be suppressed merely because the transition itself invalidated the pre-event qualification. Suppression still cannot widen the candidate set.
6. A notification does not grant access. Opening the referenced resource requires independent authorization.
7. No channel, template, priority, SLA, quiet-hour behavior or delivery provider is approved by this event-candidate decision. Existing separately approved notification policies remain controlling.
8. Do not add school principals, teachers, students, parents, school-customer personas or Attendance Verifier as recipients by inference. The canonical permission/grant matrix remains NOT APPROVED.
9. Do not include evidence bytes, permanent evidence URLs, JWTs, provider secrets or sensitive finding payloads.
10. No checklist/photo-slot completion event or evidence-completeness rule is introduced for IFP or Standing Bracket.

## 5. Per-row admission checklist

Each row must remain NOT ENABLED until all applicable evidence is supplied and approved:

- exact canonical event name, schema/version and producer;
- owning command/worker and transaction/finalizer boundary;
- immutable trusted event fields and exact participant mapping;
- approved role/scope identifiers and bounded selector grammar;
- selector dependency columns/tables and complete eligibility-writer/bypass inventory (F-04);
- event-specific dispatch profile, suppression reason catalog and retry/recovery semantics (F-05);
- deduplication/correlation semantics for related source facts;
- atomicity proof covering source mutation, event, audit, idempotency, outbox, policy pin and candidate snapshot;
- lock-order and acyclicity certification (F-03);
- measured workload limits and p50/p95/p99 contention SLO evidence (F-07);
- Security, Engineering, Database and applicable Records/Privacy approval;
- authorized acceptance tests and reproducible evidence after G10 activation.

Missing evidence leaves the relevant field UNRESOLVED and the row NOT ENABLED. No partial row may be published.

## 6. Explicitly outside this registry

- `account.requested` (CMD-001): secondary P-class candidate, deferred; neither approved nor rejected.
- `session.close_requested`: excluded as a notification event in this batch; only final `session.closed` is a candidate.
- `inspection_revision.created`: related fact, not a second notice; dedup/atomic source contract unresolved.
- All remaining CMD-001..040 declarations not listed above.
- CMD-041..044 read-side operations; CMD-045..048 separate control-plane review; CMD-049..054 excluded from ordinary matching by default.

## 7. Governance and gate status

- PO candidate intent: APPROVED for specification/review only.
- Event registry rows: 11 recorded; 0 technically admitted; 0 enabled.
- F-05: OPEN — technical validation pending.
- F-04: OPEN — physical eligibility-writer and selector dependency inventory incomplete.
- F-03: OPEN — complete source-path normalization and resolver lock certification absent.
- F-07: OPEN — workload limits and measured contention/SLO evidence absent.
- Resolver certification: 0/40; application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header: NOT ADMITTED.
- QA: PLANNED / NOT EXECUTED.
- G9: NOT READY. G10: NOT ACTIVE.

This is a documentation artifact only. No source code, SQL, migration, grants/revokes, RLS, live database changes, runtime tests, provider setup, deployment, merge or implementation activation is authorized or performed.


## 8. CMD-031/032 static review checkpoint — 2026-11-24

NREG-010 `inspection.approved` and NREG-011 `inspection.reopened` received a partial static technical reconciliation in NLA-EVENT-TECH-RECON-001 v0.1.7.

- NREG-010: approval is tied to one exact current immutable submitted revision. Explicit persisted Reviewer assignment and reviewer != revision author are required. The terminal-decision arbiter must serialize CMD-030 return against CMD-031 approval. The responsible Inspector recipient mapping is not established by the approval actor, reviewer, author or generic assignment membership.
- NREG-011: reopen requires explicit `inspection.reopen` authority, scope, mandatory reason and preservation of approved revision/evidence/documents/print history. The role/grant matrix, next-action owner and mutable draft representation are unresolved. Do not infer that the prior Inspector, reviewer or reopening actor owns the next action.
- Both source paths require atomic source mutation + canonical event + audit + idempotency + immutable event-time candidate snapshot. L05 and parent/assignment/inspection lock ordering remain candidate proposals, not certified.
- All eleven rows are now `technical_review_status = PARTIAL_STATIC_REVIEW` only. All eleven remain canonical-contract, recipient-mapping, selector and dispatch-profile `UNRESOLVED`, and publication `NOT_ENABLED`.
- Resolver certification 0/40; application lock certification 0/50; global graph NOT PROVEN ACYCLIC; candidate snapshot relation/header NOT ADMITTED; tests PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.

This checkpoint does not approve any recipient, role, permission grant, event schema, selector, dispatch profile, physical column, channel or implementation.


## 9. L05 event-to-selector crosswalk intake — 2026-11-25

[NLA-L05-EVENT-SELECTOR-REGISTRY-001](L05-EVENT-TO-SELECTOR-REGISTRY-001.md) v0.1.3 is the companion static crosswalk for all CMD-001–040 declarations and the eleven first-batch candidate rows. It records candidate selector kinds, unresolved trusted participant/scope mappings, POQ-04 dispatch invariants and the logical eligibility-writer dependency domains.

This cross-reference does not change any NREG row. NREG-001..011 remain PARTIAL STATIC REVIEW / UNRESOLVED / NOT ENABLED; 0 technically admitted and 0 enabled. No event, selector, recipient, role, permission, scope, channel, schema or dispatch profile is approved by the crosswalk. F-05/F-04/F-03/F-07 remain OPEN; resolver 0/40; application locks 0/50; global graph NOT PROVEN ACYCLIC; G9 NOT READY; G10 NOT ACTIVE.


## 10. F05-T1 structural grammar clarification — 2026-11-25

NLA-L05-TDR-001 v0.1.11 §4.2.5.1 clarifies the candidate grammar's exact structure, closed-key/type validation, duplicate JSON-key rejection, null/missing semantics, trusted participant/scope cardinality, canonical clause ordering and fail-closed behavior. NLA-L05-EVENT-SELECTOR-REGISTRY-001 v0.1.3 cross-references that specification.

This does not alter any NREG row or convert PO specification intent into technical admission. All eleven rows remain PARTIAL_STATIC_REVIEW; canonical event contract, recipient mapping, selector, dispatch profile and publication remain UNRESOLVED / NOT ENABLED. Candidate-intent tokens are not a runtime allowlist. No role/scope IDs, participant fields, per-event clause allowlists, dependency columns, policy digest, snapshot key or physical schema are approved. F05-T1 and F-04 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.


## 11. F05-T2 event-specific dispatch review — 2026-11-25

NLA-L05-TDR-001 v0.1.11 §4.2.6.1 adds a candidate-only dispatch review matrix for NREG-001..011. It records POQ-01 mandatory dispatch revalidation and POQ-04 transition-specific guards, while preserving unresolved participant, source, current-scope and parent-state profile questions.

No row is technically admitted and no dispatch profile is approved. All eleven rows remain PARTIAL_STATIC_REVIEW / UNRESOLVED / NOT ENABLED. In particular, the matrix does not infer recipients for assignment creation/change, inspection submit/return/approve/reopen, and does not introduce universal current-role/current-membership/active-parent predicates. F05-T2 remains OPEN pending Security/Engineering approval and the per-row evidence in §5.
