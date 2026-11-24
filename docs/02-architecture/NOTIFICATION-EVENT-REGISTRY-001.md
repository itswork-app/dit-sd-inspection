# Notification Event Registry — PO-Approved Specification Candidates

**Document ID:** NLA-EVENT-REGISTRY-001  
**Version:** 0.1.7  
**Status:** DRAFT — PO INTENT APPROVED FOR SPECIFICATION/REVIEW ONLY; ALL ROWS UNRESOLVED / NOT ENABLED; NREG-001..009 PARTIAL STATIC REVIEW ONLY  
**Date:** 2026-11-24  
**Branch:** `docs/notification-resolver-lock-closure`  
**Authority:** PRD-001, Decision Register PO event-candidate decision (2026-11-24), NLA-EVENT-TRIAGE-001 v0.1.1, CMD source-event map. This document does not supersede them.

## 1. Purpose and binding interpretation

This registry records exactly the eleven first-batch event candidates approved by the Product Owner for registry specification and Security/Engineering/Database review. Approval is limited to progressing these candidates through specification and review. It is **not** approval to enable publication, dispatch, recipient resolution, channels, templates, role grants, schema, code or implementation.

All rows are deliberately initialized as:

- `po_intent_status = APPROVED_FOR_SPECIFICATION_ONLY`
- `canonical_contract_status = UNRESOLVED`
- `recipient_mapping_status = UNRESOLVED`
- `selector_status = UNRESOLVED`
- `dispatch_profile_status = UNRESOLVED`
- `technical_review_status = NOT_REVIEWED`
- `publication_status = NOT_ENABLED`

No physical event field, participant ID, role ID, scope column, selector expression, channel or dispatch predicate is inferred here. Conceptual workflow actors below are review questions only, not recipient mappings.

## 2. CMD-002/003/005/010/013/014/015/029/030 technical review checkpoint

NREG-001 (`account.approved`), NREG-002 (`account.rejected`), NREG-003 (`role.revoked`), NREG-004 (`project.closed`), NREG-005 (`session.closed`), NREG-006 (`assignment.created`), NREG-007 (`assignment.changed`), NREG-008 (`inspection.submitted`) and NREG-009 (`inspection.returned_for_correction`) received a partial static technical reconciliation in [NLA-EVENT-TECH-RECON-001 v0.1.5](NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md). The command-level candidate producer transactions and proposed source objects are identified, but the deployed producer, canonical event envelope/version, participant projection, account-state predicate split, decision uniqueness, complete account-writer inventory, L05/L10 order, and event/outbox/snapshot deduplication remain unresolved. This is not technical approval. All nine reviewed rows remain `UNRESOLVED / NOT ENABLED`; no selector, recipient, channel, dispatch profile, schema or implementation is admitted.

For NREG-001 through NREG-009 only, `technical_review_status = PARTIAL_STATIC_REVIEW`; all other registry rows remain `NOT_REVIEWED`. The registry's publication status remains `NOT_ENABLED` for all eleven rows.

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
