# Inspection Reviewer Assignment Entity — Technical Proposal

**Document ID:** REVIEW-ASSIGNMENT-001  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Status:** Engineering / Database / Security / Product Owner review required — NOT APPROVED  
**Scope:** CMD-030 return-inspection; CMD-031 approve-inspection; NREG-009/NREG-010 reviewer authorization dependency  
**Authority:** PRD and Decision Register; AGENTS.md; Canonical Permission Registry; CMD-021–030 and CMD-031–040 detailed contract reviews; assignment model; physical schema; REVIEW-ARBITER-001.

## 1. Purpose and non-goals

The current command contracts require a persisted Reviewer assignment, exact inspection scope, active `inspection.review` authority, and reviewer != immutable revision author. The current physical/command model does not identify an authoritative Reviewer appointment source.

This proposal defines the smallest explicit appointment model for review. It is a static candidate only. It does not approve a role grant, assign any real person, create a deployed table, change the PRD, or authorize SQL, migrations, grants, RLS, routes, runtime tests or deployment.

Do not treat generic project membership, `assignment_members`, Inspector membership, a Super Admin label, client-supplied reviewer IDs, or revision authorship as proof of Reviewer appointment.

## 2. Baseline policy to carry forward

The working baseline is **one effective Reviewer appointment for a target inspection revision at the review serialization instant**. This is not dual review and does not create multiple review rounds.

- Exactly one Reviewer principal is resolved for the target revision at the command's database-time authorization point.
- That principal must have a current persisted appointment covering the inspection's exact operational-assignment scope.
- CMD-030 and CMD-031 must both use the same appointment source and the same eligibility predicate.
- The authenticated actor must equal the resolved Reviewer principal.
- The Reviewer must not equal `inspection_revisions.author_id` for the exact target revision.
- A Reviewer may also hold another operational role; there is no blanket prohibition on holding Inspector and Reviewer roles. The hard SoD rule is no self-review of the exact revision. Any broader role-combination prohibition requires explicit PO/institutional policy.
- A second Reviewer, quorum, delegation chain, multi-round review, substitute reviewer, or automatic fallback is out of scope unless separately approved.

If no appointment exists, more than one appointment is effective, the appointment is expired/revoked, or the scope cannot be proven, deny review fail-closed. Never pick the first matching row.

## 3. Candidate authoritative entity

### 3.1 Proposed relation

Candidate relation name: `inspection_reviewer_assignments`.

One row represents one appointment of one Reviewer principal to review inspections within one existing `operational_assignments` scope. The operational assignment is the scope anchor; its existing project/session/location parents are derived through foreign keys and must not be independently trusted from the client.

| Candidate attribute | Purpose | Authority / constraint |
|---|---|---|
| `id` | Stable appointment identity | Server-generated primary key |
| `operational_assignment_id` | Exact project/session/location/instrument work-scope anchor | FK to existing `operational_assignments`; never client authority |
| `reviewer_user_id` | Appointed Reviewer principal | FK to approved/enabled `app_users`; must not be inferred from Inspector roster |
| `valid_from` | Appointment start | Server-validated UTC instant |
| `valid_until` | Optional planned end | Half-open interval `[valid_from, valid_until)`; null means no planned end |
| `assigned_by` | Granting principal | Derived from authenticated `auth.uid()`; exact grantor authority remains open |
| `created_at` | Appointment creation time | Server timestamp |
| `ended_at` | Early revocation/end instant, if any | Server timestamp; cannot precede `valid_from` |
| `ended_by` | Principal ending appointment | Derived from authenticated actor or separately authenticated control-plane principal |
| `end_reason` | Durable reason for early end | Required if policy/authority approves mandatory reason; exact rule remains open |

This is a logical attribute proposal, not an approved physical DDL. Database must reconcile names, nullability, FK targets, indexes, exclusion/uniqueness enforcement and history semantics against the authoritative schema.

### 3.2 Why a separate entity

Existing `operational_assignments` and `assignment_members` describe operational staffing. The current roster contract uses the operational role `INSPECTOR`; it does not define Reviewer as an assignment-member role or establish reviewer appointment authority.

Therefore:
- Do not add `REVIEWER` to the Inspector roster enum by inference.
- Do not reinterpret `assignment_members` as reviewer authorization.
- Keep review appointment and Inspector work membership separate.
- Reuse `operational_assignment_id` only as the exact scope anchor, not as proof that every roster member may review.

### 3.3 Scope resolution

The candidate appointment is bound to one `operational_assignment_id`. The command must resolve the target inspection's canonical assignment path from trusted stored relationships (currently expected through the inspection/claim/assignment chain) and verify that the assignment's project, session, location and instrument bindings match the inspection's immutable context.

The exact FK path must be confirmed against the authoritative physical schema before admission. If the inspection cannot be deterministically linked to one operational assignment, this proposal is blocked; do not fall back to project-only or session-only matching.

A Reviewer needing access to several operational assignments receives separate explicit appointment rows for those scopes. No wildcard/global appointment is implied.

## 4. Appointment lifecycle and uniqueness

1. Appointment is created only by an authenticated grantor with an explicitly approved assignment authority and exact project scope.
2. Effective eligibility is evaluated using database time and the half-open interval `[valid_from, valid_until)`.
3. Early end closes the appointment; the historical row is retained and never hard-deleted.
4. Reappointment creates a new appointment row. An ended row is never reactivated.
5. At any instant, one operational assignment may resolve to at most one effective Reviewer under this baseline. Overlapping effective appointments for the same scope are invalid even if they name the same person; duplicate rows must not make resolution ambiguous.
6. One target revision may receive only one terminal decision (APPROVE or RETURN), enforced separately by the shared `review_events` uniqueness arbiter in REVIEW-ARBITER-001.

The physical exclusion/uniqueness mechanism for overlapping time intervals is OPEN. A partial unique index on a boolean/current flag is not sufficient to prevent overlapping future-effective intervals. Database must select and verify a PostgreSQL-compatible invariant (including required extensions and concurrency behavior) before this entity is admitted.

## 5. Authorization and separation of duties

### 5.1 Reviewer execution

CMD-030 and CMD-031 must, inside the trusted PostgreSQL transaction:

- derive actor from `auth.uid()`;
- resolve one approved/enabled `app_users` identity;
- verify active `inspection.review` grant and its exact scope;
- resolve exactly one effective `inspection_reviewer_assignments` row for the target inspection's assignment scope;
- require appointment.reviewer_user_id = authenticated actor;
- verify the appointment and all parent scope bindings remain effective;
- verify target revision belongs to the inspection, is the exact current submitted revision, and is still reviewable;
- enforce reviewer_user_id != immutable revision author_id;
- revalidate the above after acquiring the final approved serialization/lock set.

The request must not accept authoritative `reviewer_user_id`, `author_id`, project/session/location/assignment scope, appointment status, or decision actor from the client.

### 5.2 Grantor and revocation authority

The permission registry currently states that role grants, grantor ceiling, scope authority and SoD are not approved end-to-end. Accordingly, this proposal does **not** decide which existing actor (Super Admin, Admin/Korlap, Project Sponsor, or any other actor) may appoint or revoke a Reviewer.

Before implementation, the authorized governance owner must approve:
- named grantor principal class and exact permission;
- grantor scope ceiling and no-self-appointment rule;
- whether appointment and revocation require an independent approver;
- whether a grantor may appoint themselves (candidate default: deny);
- mandatory reason and evidence requirements;
- emergency replacement/break-glass authority, if any.

A generic role label never supplies this authority. No role seed or grant is implied.

### 5.3 Separation-of-duties matrix

| Relationship | Candidate rule | Status |
|---|---|---|
| Reviewer vs exact revision author | Must be different principals | Required by existing command contract |
| Reviewer vs Inspector role-holder | Not automatically prohibited; exact revision author check still applies | No broader prohibition approved |
| Appointment grantor vs Reviewer | Candidate deny self-appointment; authority decision required | OPEN |
| Appointment grantor vs appointment revoker | Independent control desirable; not mandated without authority decision | OPEN |
| Reviewer vs responsible Inspector / notification participant | Do not infer participant identity from Reviewer, author or generic assignment membership | Existing NREG-010 boundary |
| Multiple effective Reviewers for one scope/revision | Deny ambiguity; one effective Reviewer baseline | Candidate policy |

## 6. CMD-030 / CMD-031 shared resolution protocol

The same resolver and appointment predicate must be used for return and approval:

1. Claim idempotency using the canonical command protocol.
2. Resolve immutable target identifiers without treating client scope as authority.
3. Acquire the complete, globally reconciled authorization, project/session, assignment and inspection locks in the eventual approved order. This proposal does not certify that order.
4. Resolve the current effective Reviewer appointment and revalidate parent scope after lock waits.
5. Verify actor == appointed Reviewer and actor != exact revision author.
6. Verify exact current submitted revision and reviewable inspection state.
7. Append RETURN or APPROVE using the shared terminal-decision arbiter.
8. Commit inspection transition, review event, inspection event, audit event and idempotency result atomically.

An appointment ending concurrently with review must have a deterministic result under the final lock protocol: either the review serializes before the end and is valid at its authorization instant, or the end serializes first and the review is denied. A stale pre-lock appointment read is never sufficient.

## 7. Required adversarial acceptance cases

All cases are specifications only — NOT EXECUTED.

| ID | Scenario | Required result |
|---|---|---|
| RAS-01 | Reviewer has one active appointment for exact assignment and is not revision author | Review may proceed if all other gates pass |
| RAS-02 | No persisted appointment; only Inspector membership exists | Deny |
| RAS-03 | Generic Super Admin or project member without appointment | Deny |
| RAS-04 | Appointment expired or ended before authorization instant | Deny |
| RAS-05 | Two overlapping effective appointment rows for the scope | Deny and raise integrity signal; never choose one |
| RAS-06 | Appointment points to another assignment/project/session/location | Deny |
| RAS-07 | Authenticated Reviewer is the exact revision author | Deny; no review event/state change |
| RAS-08 | Reviewer has Inspector role but is not author of target revision | No blanket role-based denial; continue other checks |
| RAS-09 | Appointment end/revoke races with CMD-030 or CMD-031 | One deterministic serialized outcome |
| RAS-10 | Client forges reviewer, author or assignment ID | Ignore/reject forged authority; derive from trusted records |
| RAS-11 | Reviewer assignment history is ended then reappointed | Old row retained; new appointment row used |
| RAS-12 | Same revision receives concurrent RETURN and APPROVE | Shared terminal arbiter permits exactly one decision |

## 8. Required cross-document updates before admission

After Product Owner/governance and Engineering/Database/Security review, synchronize:
- canonical physical schema and ERD;
- permission registry and grantor/delegation/SoD matrix;
- CMD-030 and CMD-031 read/write sets, authorization predicates and error outcomes;
- CMD-014/015 assignment lock dependencies only if appointment writes share any existing parent/identity resources;
- lock manifest and global lock graph, including appointment create/end vs review reads;
- NREG-009/NREG-010 recipient-participant mapping without inferring a responsible Inspector;
- RTM, RAID and QA catalogue with traceable test IDs.

No current document should be silently treated as updated by this proposal.

## 9. Open items and disposition

| ID | Open item | Required authority/evidence |
|---|---|---|
| RAS-O01 | Confirm inspection → claim → operational_assignment FK path | Database / Engineering physical-schema evidence |
| RAS-O02 | Approve exact appointment grantor, permission and scope ceiling | Product Owner / institutional authority / Security |
| RAS-O03 | Approve self-appointment and grantor/revoker SoD | Product Owner / institutional authority / Security |
| RAS-O04 | Approve appointment interval, revocation and history semantics | Product Owner / Engineering / Database |
| RAS-O05 | Select concurrency-safe no-overlap constraint for effective appointments | Database |
| RAS-O06 | Confirm whether one effective Reviewer per operational assignment is correct across all inspection types | Product Owner / workflow authority |
| RAS-O07 | Map appointment create/end commands and all writer paths into the global lock graph | Engineering / Database |
| RAS-O08 | Verify role/permission grant, RLS and function ACL behavior | Security / Database |

**Disposition:**
- Separate persisted Reviewer appointment entity: **CANDIDATE PROPOSED; NOT APPROVED**.
- One effective Reviewer per target revision: **WORKING BASELINE; PO/GOVERNANCE CONFIRMATION REQUIRED**.
- Reviewer != exact revision author: **REQUIRED BY EXISTING CMD-030/031 CONTRACTS**.
- `assignment_members` as Reviewer authority: **REJECTED AS AN UNSUPPORTED INFERENCE**.
- Role/grantor matrix and SoD beyond no-self-review: **OPEN**.
- Physical DDL, grants, RLS, runtime tests: **NOT AUTHORIZED / NOT PERFORMED**.
- G9: **NOT READY**; G10: **NOT ACTIVE**.

This proposal is not independent Product Owner, institutional, Engineering, Database or Security approval.
