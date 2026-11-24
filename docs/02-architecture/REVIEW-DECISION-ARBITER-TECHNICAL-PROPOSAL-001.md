# Review Decision Arbiter — CMD-030/031/032 Technical Proposal

**Document ID:** REVIEW-ARBITER-001  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Status:** Engineering / Database / Security review required — NOT APPROVED  
**Repository phase:** Documentation / SSOT maturation  
**Scope:** CMD-030 return-for-correction, CMD-031 approve-inspection, CMD-032 reopen-inspection  
**Authority:** AGENTS.md; approved PRD and Decision Register; CMD-021–030 and CMD-031–040 detailed contract reviews; physical schema specification; LOCK-MANIFEST-001; LOCK-GRAPH-001.

## 1. Purpose and non-goals

This proposal isolates the shared review-decision invariant so that CMD-030 and CMD-031 cannot independently create conflicting terminal decisions for one submitted revision, while CMD-032 cannot race a pending review transition.

This is a static design proposal. It does not certify any lock path, approve reviewer assignment or permission grants, resolve the inspection state machine, define a new draft storage model, authorize schema changes, or establish that any database object currently exists.

No application code, SQL migration, grant, RLS change, live database operation, runtime test, deployment, merge, or gate transition is included.

## 2. Canonical invariant

For each immutable submitted `inspection_revisions.id`:

1. At most one terminal review decision may commit.
2. The only terminal decisions currently specified by the command contracts are `APPROVE` (CMD-031) and `RETURN` (CMD-030).
3. CMD-030 and CMD-031 must use the same physical uniqueness arbiter and the same inspection aggregate serialization point.
4. A resubmission is a new immutable revision and therefore receives a new decision slot. A prior revision is never reopened for another terminal decision.
5. CMD-032 is not a review decision. It may transition an already APPROVED inspection only after revalidating the exact approved revision and all approved lifecycle blockers. It must not erase, replace, or mutate the prior review event.

If Product Owner/institutional workflow later requires multiple review rounds against the same immutable revision, this invariant must be changed through explicit decision and schema change control. Do not silently add a review-round concept.

## 3. Physical arbiter proposal

The current physical schema describes:

`review_events(id, inspection_revision_id, reviewer_id, decision, reason, created_at)`

It does not name a unique terminal-decision constraint, review-round field, or decision-sequence field.

### 3.1 Preferred candidate, subject to schema-owner confirmation

If `review_events` stores terminal decisions only, make `inspection_revision_id` unique:

```sql
ALTER TABLE public.review_events
  ADD CONSTRAINT review_events_one_decision_per_revision
  UNIQUE (inspection_revision_id);
```

This is the smallest physical invariant and directly expresses the currently documented one-terminal-decision-per-revision rule. PostgreSQL's unique index/constraint is the final arbiter under concurrent inserts; application pre-checks are not a substitute.

### 3.2 Conditional alternative

If the approved table contract permits non-terminal review events in the same table, use a partial unique index over the exact, approved terminal decision vocabulary:

```sql
CREATE UNIQUE INDEX review_events_one_terminal_decision_per_revision
  ON public.review_events (inspection_revision_id)
  WHERE decision IN ('APPROVE', 'RETURN');
```

This alternative is NOT selectable until Database confirms the complete decision vocabulary, case/canonicalization rule, and whether any other decision is terminal. Do not deploy both alternatives.

### 3.3 Required physical validation

Before either candidate is admitted, Database must confirm:

- `inspection_revision_id` is NOT NULL and references the exact immutable revision.
- `decision` has a constrained canonical vocabulary matching CMD-030/031.
- The chosen uniqueness rule does not conflict with existing rows or a formally approved correction/reverification workflow.
- The index is backed by the intended FK and supporting review-queue indexes.
- Direct browser DML is denied under T-18; only the narrowly granted trusted command boundary may append review decisions.
- The constraint/index name and migration ordering are recorded in the physical schema and migration review package.

No physical DDL is approved by this proposal.

## 4. Shared command protocol

### 4.1 CMD-030 — return

- Claim idempotency using the canonical L00 protocol.
- Resolve the authenticated actor and validate the persisted Reviewer assignment, exact scope, `inspection.review` permission, active account/grants, and reviewer != revision author.
- Acquire all required parent/assignment/claim resources only under one globally reconciled order; this proposal does not choose or certify that order.
- Lock the inspection aggregate using the one shared review serialization primitive.
- Revalidate that the target is the exact current submitted revision and remains reviewable.
- Append `review_events.decision = 'RETURN'`; the unique arbiter rejects any competing terminal decision.
- Update inspection lifecycle and row_version, append inspection event, audit event, and idempotency result atomically.
- Map the uniqueness conflict to a stable `ALREADY_REVIEWED`/terminal-decision conflict. Do not retry it as a transient deadlock.

### 4.2 CMD-031 — approve

Use the same sequence and physical arbiter as CMD-030, with `review_events.decision = 'APPROVE'` and the approved transition. The exact current immutable submitted revision, persisted Reviewer assignment, exact scope, active permission and reviewer != author must be revalidated after the inspection serialization point.

An approve-vs-return race must have exactly one winner. The losing transaction must leave no inspection state transition, review event, audit event, notification outbox, candidate snapshot, or successful idempotency result.

### 4.3 CMD-032 — reopen

- Claim idempotency and resolve explicit `inspection.reopen` authority and exact scope.
- Follow the same globally approved parent/assignment/claim/inspection lock order; do not acquire a lower-ranked parent after the inspection aggregate.
- Serialize on the inspection aggregate shared with CMD-030/031.
- Revalidate APPROVED state, exact approved revision, row_version, active-work blockers, and final lifecycle constraints.
- Preserve the approved revision, its review event, evidence, generated documents and print history.
- Create or reference exactly one new editable draft context only after its physical representation and uniqueness invariant are approved.

The active-draft arbiter cannot be specified safely yet because the current physical model does not define the mutable draft-context entity/pointer and its lifecycle. Do not invent a revision ID, mutate an immutable submitted revision, or add an assumed unique index to a table that does not yet represent draft context.

## 5. Serialization and lock-graph obligations

The inspection aggregate is the common logical serialization point for save/submit/return/approve/reopen transitions. The unique review-event arbiter is the final database backstop for competing terminal decisions; it does not replace the aggregate lock or authorization revalidation.

The following are distinct obligations and must not be collapsed into an unsupported claim of one certified lock order:

1. L00 idempotency arbitration.
2. Candidate L05 audience guard, only if the notification design is admitted after Security/Database approval.
3. Reviewer principal, role and scope authorization dependencies.
4. Project/session parent fences and persisted reviewer assignment scope.
5. Optional active-claim or lifecycle blocker resources required by the final reopen predicate.
6. Inspection aggregate serialization.
7. Exact immutable revision read and review-event append/unique arbiter.
8. Dependent mutable draft-context resource, only for CMD-032 after the schema exists.
9. Append-only review/inspection/audit facts and idempotency outcome.

LOCK-MANIFEST-001 currently contains differing candidate descriptions for CMD-030/031/032, and LOCK-GRAPH-001 §30 is a candidate overlay rather than a proven total order. Engineering and Database must reconcile the full read/write/lock set, exact PostgreSQL lock modes, implicit FK KEY SHARE edges, unique-index waits, triggers, helper functions, and worker/finalizer paths before graph certification.

A uniqueness violation is an invariant conflict, not proof that the overall lock graph is acyclic. No lock rank is admitted by this document.

## 6. Required adversarial acceptance cases

All cases below are specifications only; they are NOT EXECUTED.

| ID | Concurrent or adversarial case | Required result |
|---|---|---|
| RA-01 | CMD-030 RETURN races CMD-031 APPROVE on the same revision | Exactly one terminal decision commits |
| RA-02 | Two CMD-031 approvals with different idempotency keys | One decision; other receives terminal-decision conflict |
| RA-03 | Two CMD-030 returns with different idempotency keys | One decision; other receives terminal-decision conflict |
| RA-04 | Duplicate same-key/same-payload replay | Stored result returned only after current authorization revalidation |
| RA-05 | Same idempotency key with different semantic payload | Reject as key reuse; no second decision |
| RA-06 | CMD-032 reopen races a pending CMD-030 or CMD-031 | Reopen revalidates after serialization and cannot bypass an uncommitted/pending decision |
| RA-07 | CMD-032 repeated with different idempotency keys | At most one active draft context; exact physical arbiter remains blocked pending draft model |
| RA-08 | Reviewer is revision author, unassigned, expired, revoked, or out of scope | Deny; no review event or state mutation |
| RA-09 | Target revision is stale, not submitted, not current, or belongs to another inspection | Reject; no review event or state mutation |
| RA-10 | Audit append fails after a proposed decision | Entire transaction rolls back |
| RA-11 | Unique terminal-decision constraint is hit under race | Stable terminal conflict; no partial state/audit/outbox/snapshot result |
| RA-12 | Resubmission creates a new immutable revision | New revision may receive one terminal decision; prior revision remains immutable and terminal |

## 7. Open decisions and evidence

| ID | Open item | Owner / required evidence |
|---|---|---|
| RA-O01 | Persisted Reviewer assignment entity, grantor, effective interval and exact project/session/location/assignment scope | Product Owner / Security / Database; approved authority matrix and physical relationship |
| RA-O02 | Exact decision vocabulary and whether review_events contains terminal decisions only | Engineering / Database; canonical enum and schema contract |
| RA-O03 | Returned-for-correction state transition and resubmission/new-revision lifecycle | Product Owner / institutional workflow authority; approved state machine |
| RA-O04 | CMD-032 explicit reopen grant matrix, SoD, next-action owner and active-work blocker set | Product Owner / Security / institutional authority |
| RA-O05 | Mutable draft context representation and one-active-draft invariant | Engineering / Database; physical entity, pointer and uniqueness design |
| RA-O06 | One total lock order across reviewer authorization, project/session/assignment, optional claim, inspection and child resources | Engineering / Database / Security; complete call graph and PostgreSQL edge analysis |
| RA-O07 | T-18 function owner, SECURITY mode, search_path, EXECUTE ACL, RLS and direct-DML denial evidence | Security / Database; function-by-function privilege review |
| RA-O08 | Concurrency, rollback, replay and deadlock evidence | QA / Engineering; reproducible tests on approved disposable environment after G10 |

## 8. Disposition

- CMD-030/031 shared terminal-decision invariant: **SPECIFIED AS A CANDIDATE; PHYSICAL ARBITER NOT APPROVED**.
- CMD-032 active-draft invariant: **BLOCKED — physical draft context missing**.
- Reviewer assignment / permission / SoD: **UNRESOLVED**.
- Global lock order / acyclicity: **NOT PROVEN**.
- Resolver certification: **0/40**.
- Application lock certification: **0/50**.
- QA: **PLANNED / NOT EXECUTED**.
- G9: **NOT READY**.
- G10: **NOT ACTIVE**.

This document is an internal static proposal, not independent Engineering, Database, Security, institutional, or Product Owner approval. It creates no implementation authorization.
