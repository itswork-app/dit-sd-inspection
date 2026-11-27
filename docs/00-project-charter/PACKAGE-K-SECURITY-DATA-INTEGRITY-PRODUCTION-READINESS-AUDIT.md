# Package K — Security, Data Integrity & Production Readiness Audit

> [!NOTE]
> **Historical audit note:** This document is a historical security/integrity audit from 2026-11-23 on branch `docs/phase-0-foundation`. Current security threat modeling and verification matrices are maintained in [SECURITY-THREAT-MODEL.md](../02-architecture/SECURITY-THREAT-MODEL.md) and [DGA-001](DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md).

**Status:** Historical audit snapshot — superseded by Package S and Security Threat Model  
**Version:** 0.1.1  
**Date:** 2026-11-23  
**Branch:** docs/phase-0-foundation

## 1. Executive conclusion

**Result: PARTIAL — NOT READY FOR SCOPE FREEZE OR FEATURE IMPLEMENTATION.**

The current architecture contains sound baseline principles: PostgreSQL as the sole source of truth, deny-by-default RLS, explicit assignment scope, private Storage, immutable submitted revisions, idempotent commands, transactional invariants, and separate actual/target reporting.

However, these are design statements only. No migration, deployed RLS policy, security test, penetration test, restore drill, object-recovery drill, load test, or production provider configuration was executed or inspected in this audit.

This package identifies design consistency and production-readiness gaps. It does not certify security or authorize implementation.

## 2. Audit scope and evidence

Reviewed current branch documents:
- `docs/02-architecture/DATA-MODEL-AND-ERD.md`
- `docs/02-architecture/RLS-AND-AUTHORIZATION-DESIGN.md`
- `docs/02-architecture/API-AND-TRANSACTION-CONTRACTS.md`
- `docs/02-architecture/SECURITY-THREAT-MODEL.md`
- `docs/02-architecture/EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md`
- `docs/02-architecture/PERFORMANCE-AND-OPERATIONS-BASELINE.md`
- `docs/03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md`
- `docs/03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md`
- `docs/00-project-charter/RAID-REGISTER.md`
- `docs/00-project-charter/DECISION-REGISTER.md`

Review method: source-text consistency and design gap review. No source-code repository implementation or cloud account configuration was available/inspected as part of this package.

## 3. Confirmed design invariants

The following are documented and should remain architecture constraints:
1. Supabase PostgreSQL is the sole primary source of truth.
2. Supabase Auth identity is mapped to one application profile; pending/rejected/suspended accounts have no operational access.
3. RLS is enabled on every exposed application table; default posture is deny.
4. Service-role credentials never enter browser bundles or public repositories.
5. Every operation checks identity, approval, permission, explicit scope, resource state, and separation of duties.
6. Cross-location authority is never inherited implicitly.
7. Submitted revisions, finalized evidence, print events, and audit events are not silently overwritten.
8. Claims, submission, review, capacity changes, and idempotent commands require transaction-level concurrency protection.
9. Evidence uses private Storage, opaque object keys, authorized upload intent, and content verification.
10. Actual activity timestamps are never rewritten to match target allocation.
11. Inspector capacity is configurable from 1 to 100 distinct active Inspector accounts combined across locations; default 50.
12. The 100 concurrent authenticated-user target is a test target, not proven production capacity.

## 4. Corrections made during this audit

Two architecture documents retained a stale capacity range of 50..100 despite the approved 1..100 policy:
- Data Model and ERD: project capacity settings constraint.
- API and Transaction Contracts: capacity-change command validation.

Both documents have been corrected to range 1..100, default 50. This is a documentation correction only; no database constraint or command has been implemented.

## 5. Findings

### K-01 — Physical schema and database invariants are not final
**Severity:** BLOCKER

The ERD is logical and explicitly leaves serial uniqueness, assignment temporal overlap, role/scope inheritance, evidence linkage, claim expiry, target reconciliation, and document snapshot semantics open.

Required before schema freeze:
- define canonical serial normalization per instrument, including case, whitespace, punctuation, Unicode, and null/unknown serial handling;
- define duplicate identity scope (project + instrument, or other authorized rule) and reinspection path;
- define unique/partial indexes for active claims and revision numbering;
- define FK/check constraints for project/session/location/instrument/assignment consistency;
- define effective-time semantics for assignment membership and overlap prevention;
- define revision-to-checklist-version and evidence-to-revision constraints;
- define delete/update restrictions for immutable records;
- define transaction isolation/locking strategy and race tests for every global invariant.

### K-02 — RLS is a policy framework, not an executable policy catalogue
**Severity:** BLOCKER

The design states deny-by-default and RLS on all exposed tables, but does not yet enumerate a complete table-by-table action matrix, policy predicates, helper functions, and test fixtures.

Required:
- inventory every exposed table, view, RPC, and Storage bucket;
- specify SELECT/INSERT/UPDATE/DELETE policy for each role and scope;
- identify tables that must have no client write path;
- specify safe `SECURITY DEFINER` function use, fixed search_path, ownership, grants, and caller validation;
- specify how user roles/scopes are resolved without trusting mutable browser metadata or unsafe JWT claims;
- test direct PostgREST access, view behavior, function execution, and Storage object access for positive and negative cases;
- prove that Super Admin global admin permissions do not bypass per-transaction separation of duties.

### K-03 — Privileged command boundary remains open
**Severity:** BLOCKER

The API contract leaves server route, PostgreSQL RPC, and hybrid transport undecided. This affects where authorization, transaction boundaries, service-role access, and idempotency are enforced.

Required:
- define one trusted command execution boundary for every state-changing command;
- prohibit browser direct writes to privileged tables;
- specify which commands use narrowly granted RPC versus trusted server handler and why;
- define request schema, actor derivation, scope derivation, transaction, idempotency, and error behavior per command;
- ensure privileged credentials never bypass business authorization or RLS unintentionally.

### K-04 — Audit trail policy is not fully approved
**Severity:** HIGH

INS-016 remains PROPOSED in Decision Register. Architecture documents describe append-only audit coverage, but final event catalogue, retention, access/export authority, tamper resistance, and operational review are not approved.

Required:
- obtain explicit approval for INS-016;
- define event schema, correlation IDs, before/after fields with data minimization, reason requirements, and immutable write path;
- restrict update/delete at database privileges and policy level, not only UI;
- define retention, export, legal hold, and audit access;
- test that failed/denied privileged attempts are logged where policy requires and that audit events cannot be edited/deleted by application roles.

### K-05 — Evidence object lifecycle and recovery are incomplete
**Severity:** BLOCKER

The evidence design has private buckets, upload intent, checksum, MIME/signature validation, idempotent retry, and immutable object identity. It intentionally leaves file limits, abandoned upload cleanup, retention, deletion, and resumable upload thresholds unresolved.

Additional production issue: database backup/restore alone does not prove that corresponding Storage objects can be recovered consistently.

Required:
- approve MIME allowlist and server-side content signature validation;
- establish per-file, per-inspection, and aggregate quotas from actual field evidence and provider limits;
- define pending/abandoned upload reconciliation and safe cleanup after an approved grace period;
- define object versioning/immutability strategy and checksum verification;
- define evidence retention, deletion authorization, legal hold, and audit;
- test object loss, checksum mismatch, partial upload, retry, orphaned metadata, and orphaned object;
- document and test joint recovery of database metadata and Storage objects.

### K-06 — Backup, restore, and disaster recovery are not evidenced
**Severity:** BLOCKER

The RAID register identifies restore proof as a critical risk. The operations baseline requires backup/restore and object recovery but has no approved numeric RPO/RTO, schedule, retention, or completed drill.

Required:
- verify actual Supabase plan and backup/PITR capabilities at procurement time;
- approve numeric RPO/RTO and recovery owners;
- define database backup cadence/retention and encryption/access;
- define Storage object recovery and metadata consistency;
- define restore into isolated environment, credential rotation, DNS/deployment cutover, and reconciliation;
- run and record a restore drill before production release.

### K-07 — Production environment and provider governance are unverified
**Severity:** BLOCKER

Supabase/Vercel are approved platform choices, but account ownership, billing, region/data residency, project separation, quotas, backup entitlements, support, and deployment permissions are not confirmed.

Required:
- separate development, staging, and production projects/environments;
- confirm production region and institutional data-residency requirements;
- verify quotas and limits for Auth, Postgres compute/connections, Storage, egress, Vercel functions/transfer, and CI;
- name billing owner, project owner, incident owner, deployment approver, and security contact;
- define secrets management, rotation, least-privilege tokens, preview deployment restrictions, and break-glass access;
- define usage alerts and spend/upgrade thresholds.

### K-08 — Idempotency and offline conflict contract is incomplete
**Severity:** HIGH

Idempotency semantics are described, but retention duration is open and the full sync conflict policy is not finalized. An offline retry window longer than idempotency retention can create ambiguous replay behavior.

Required:
- set idempotency retention longer than the maximum supported offline window;
- define key scope, request-hash canonicalization, concurrent same-key behavior, and replay authorization;
- define sync batch ordering, partial success, acknowledgement persistence, and retry semantics;
- define conflict categories and user resolution workflow;
- ensure local data is not discarded before server acknowledgement and claim expiry does not silently destroy drafts;
- test device clock skew, app/browser termination, network loss at each sync step, repeated batch delivery, and lost acknowledgement.

### K-09 — Global capacity semantics require one canonical database rule
**Severity:** HIGH

The approved policy is 1..100, default 50, counting distinct active Inspector accounts globally across both locations. The database must define precisely what qualifies as an active Inspector account (approved account + active Inspector role grant, versus currently assigned Inspector) and how a role revocation, suspension, or account deactivation affects the count.

Required:
- select one canonical counting predicate in the domain model;
- enforce it in the same transaction as activation/role grant and capacity change;
- prevent race conditions under concurrent approval/role changes;
- reject capacity reduction below current counted active accounts; never silently deactivate;
- test values 1, 50, 100; reject 0 and 101; test simultaneous activation at cap;
- record capacity changes and count-affecting transitions in audit.

### K-10 — Performance and cost envelope has no measured baseline
**Severity:** HIGH

The 100-user concurrency target is stated, but workload mix, dataset size, photo sizes, request rate, latency/error SLOs, and actual provider resource envelope are not yet approved or measured.

Required:
- define representative Inspector, Reviewer, Korlap, Print Officer, and Super Admin request mix;
- include concurrent uploads, PDF generation, dashboard/report reads, claims, submissions, and sync;
- define p95/p99 and error thresholds per critical operation;
- run stepped load tests and record database, Storage, Vercel, browser, and egress metrics;
- test poor mobile network and retry behavior;
- estimate monthly operating cost from measured usage before production approval.

### K-11 — Document generation and print evidence need integrity detail
**Severity:** HIGH

The document design correctly distinguishes PDF generation, print action, and wet signature. However, PDF renderer trust boundary, deterministic source snapshot, template versioning, checksum, and print result evidence need final technical contracts.

Required:
- render only from approved immutable revision and versioned template;
- store output checksum and source revision/template version;
- make generation idempotent or create a new explicit document version;
- distinguish print requested, browser print dialog opened where observable, and user-confirmed print result; do not overstate physical printing based solely on a click;
- ensure sequence numbers are transactionally allocated;
- test stale/revoked access, repeated generation, concurrent print, and reprint history.

### K-12 — Security operations and incident response are not operationalized
**Severity:** HIGH

Monitoring categories are listed, but alert thresholds, incident severity, escalation, response ownership, credential revocation, and post-incident evidence handling are not defined.

Required:
- define incident severity and on-call/response owner;
- define alerts for unusual exports, repeated denials, auth anomalies, storage spikes, quota exhaustion, database saturation, and failed backup/restore;
- define credential/session revocation and compromised-account procedure;
- define incident log retention, evidence preservation, notification, and recovery checklist;
- conduct tabletop exercise before production release.

## 6. Cross-document consistency checks

| Check | Result | Required action |
|---|---|---|
| Inspector capacity range | CORRECTED | ERD and API contract now state 1..100, default 50 |
| RLS baseline | CONSISTENT AT PRINCIPLE LEVEL | Complete executable policy catalogue still required |
| Private evidence storage | CONSISTENT AT PRINCIPLE LEVEL | Limits, retention, deletion, object recovery open |
| Immutable revisions | CONSISTENT AT PRINCIPLE LEVEL | Physical constraints and tests open |
| Transactional claims/approval | CONSISTENT AT PRINCIPLE LEVEL | Concrete lock/index strategy open |
| Audit trail | PARTIAL | INS-016 approval and retention open |
| Backup/restore | PARTIAL | RPO/RTO and successful drill absent |
| Provider production readiness | OPEN | Plans, region, quotas, ownership unverified |
| Offline sync | PARTIAL | Idempotency retention/conflict details open |
| Actual vs Target | CONSISTENT | Keep separate in schema and report contract |
| Print evidence | PARTIAL | Do not equate print click with verified physical output |

## 7. Required follow-up artifacts

Before scope freeze, prepare:
1. Physical Schema and Database Constraint Specification.
2. Table-by-Table RLS Policy Catalogue and Authorization Test Matrix.
3. Privileged Command Boundary ADR and command transaction specifications.
4. Audit Event Catalogue and INS-016 approval record.
5. Evidence Retention, Deletion, and Object Recovery Policy.
6. Backup/Restore and Disaster Recovery Runbook with approved RPO/RTO.
7. Environment, Secrets, Provider Quota, and Operations Ownership Plan.
8. Offline Idempotency and Conflict Resolution Contract.
9. Load-Test Workload and Numeric SLO Acceptance Plan.
10. PDF/Print Integrity Contract.
11. Incident Response and Security Monitoring Runbook.

## 8. Release gates

Production release must be blocked until:
- RLS and authorization negative tests pass in staging;
- privileged command boundaries are reviewed;
- immutable revision and evidence integrity tests pass;
- database and object recovery drill passes;
- provider quotas and production ownership are confirmed;
- security incident response and credential revocation are ready;
- performance tests meet approved numeric thresholds;
- UAT, institutional privacy/records approval, and rollback plan are accepted.

## 9. Final status

**Package K audit:** COMPLETED AS DOCUMENTATION REVIEW.  
**Security posture:** NOT TESTED / NOT CERTIFIED.  
**Data integrity design:** PARTIAL.  
**Production operations readiness:** NOT READY.  
**Scope freeze:** NOT READY.  
**Feature implementation:** NOT AUTHORIZED.

No code, migrations, cloud settings, RLS policies, backup configuration, or tests were executed by this package.


## 10. Post-decision reconciliation addendum (2026-11-24)

This addendum supersedes only the decision-status statements below that were written before the Product Owner decisions T-15 through T-18. The original findings remain useful as an audit history; they must not be read as the current decision register.

### 10.1 Decisions now closed at Product Owner level

- **K-01 / T-16:** PO-approved option B establishes canonical serial uniqueness by (instrument_id, serial_normalized) across projects. The project-independent `units` + durable `unit_project_associations` + controlled `unit_identity_conflicts` model, composite project/association references, and global active-claim invariant are now specified in the ERD and physical schema. This closes the earlier product-direction ambiguity, not technical review, institutional normalization/exception policy, migration design or implementation verification.
- **K-03 / T-18:** PO-approved option A selects Vercel server route → PostgreSQL command function with caller JWT. Database-derived actor, protected-table direct-DML denial, explicit EXECUTE grants and atomic authorization/mutation/audit are now specified. Exact grants, function-by-function review and executable verification remain open.
- **K-04 / T-15:** INS-016 is PO APPROVED option A. Append-only audit events, atomic critical mutation + audit, fail-closed behavior and least-privilege audit access are the approved direction. Institutional retention, legal hold, classification, network metadata and independent archive decisions remain external blockers.
- **K-08 / T-09:** Limited offline draft editing for already claimed units is PO-approved. Device/local-data safeguards, maximum retry window, idempotency retention and conflict-resolution implementation remain open.
- **K-09 / T-14:** The qualifying Inspector predicate is PO-approved: distinct enabled account + active Inspector grant + at least one currently effective operational assignment, counted once and enforced atomically across both locations (cap 1–100; default 50).

### 10.2 Remaining blockers after T-15 through T-18

1. Complete and review every physical table constraint, composite FK, index, command lock order and null/unknown-serial workflow before migration.
2. Complete the table-by-table RLS/grant matrix, including command-specific EXECUTE grants, SECURITY DEFINER exceptions and direct browser-DML denial coverage.
3. Reconcile every command payload/outcome and idempotency retention with the approved offline window and T-18 caller-JWT boundary.
4. Obtain institutional approval for evidence classification, lawful purpose, limits, retention, legal hold, deletion and recovery.
5. Verify actual provider ownership, region, plans, quotas, backup/PITR and Storage-object recovery; execute and record an isolated restore drill.
6. Approve measurable performance SLOs after provider and workload validation; execute load, security, offline, PDF/print and UAT verification.
7. Close source-authority and operational policy gaps, including official IFP source, photo-slot rules, BA signatory authority and other institutional approvals tracked in Package T/RAID.

**Current disposition remains unchanged:** documentation audit only; scope freeze NOT READY; feature implementation NOT AUTHORIZED; no migration, deployment, runtime/security test or restore drill is claimed.
