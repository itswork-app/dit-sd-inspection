# CERT-001 — Technical Certification Assessment

**Document ID:** CERT-001  
**Version:** 0.1.7
**Assessment date:** 2026-11-24  
**Repository:** `itswork-app/dit-sd-inspection`  
**Branch:** `docs/audit-lock-and-identity-reconciliation`  
**Assessment baseline:** `00859d5c39381f6ff6b58190abfec09c8e4b8bbd`  
**Pull request:** [PR #3 — docs: final governance and command-contract reconciliation](https://github.com/itswork-app/dit-sd-inspection/pull/3)  
**Overall result:** **NOT CERTIFIED**  
**G9:** NOT READY  
**G10:** NOT ACTIVE

## 1. Purpose and authority

This is an internal, evidence-based technical assessment of the documentation and repository evidence available at the assessment baseline. It is not an accredited third-party certification, institutional approval, penetration-test attestation, production-readiness certificate, or substitute for accountable Security, Database, Operations, provider, records, legal, privacy, or institutional reviewers.

The Product Owner's conditional implementation authorization is acknowledged. It authorizes continued G9 prerequisite closure; it does not activate G10 or waive approvals reserved to other authorities.

The controlling repository instruction is root `AGENTS.md` v1.2.2. Until G9 is verified and a separate G10 activation record is approved, work remains limited to read-only inspection, static analysis, and approved documentation updates. No source implementation, SQL execution, migration, grant/revoke, live database change, deployment, merge, or production data operation was performed by this assessment.

## 2. Assessment scope and method

Reviewed:
- Root engineering policy and current Product Owner Decision Register.
- DGA-001, MIB-001, implementation roadmap, Package S, RTM and RAID.
- Physical schema, RLS catalogue, schema/RLS/command reconciliation, permission registry and T-18 function-security design.
- Command contract and lock-manifest material for CMD-001..054, global lock-order graph, notification lifecycle design, threat model and QA catalogue.
- PR #3 metadata, changed-file inventory, review submissions, review threads, commit status and PR-triggered workflow runs.

Assessment method:
1. Read the current root `AGENTS.md` before repository work.
2. Inspect the exact PR head and its 43 changed files.
3. Compare canonical table-name inventories across physical schema, RLS catalogue and reconciliation crosswalk.
4. Compare current gate declarations with the Decision Register and repository instructions.
5. Distinguish documentary design evidence from deployed/runtime evidence.
6. Assign PASS only where the required evidence is present. Planned tests, static counts and PO design decisions are not runtime proof.

## 3. Corrective documentation work completed in this assessment

The following documentation-only corrections were committed to the PR #3 head:

| Correction | Result |
|---|---|
| Physical schema ↔ RLS ↔ command crosswalk | Reconciled to 48 table rows; exact table-name parity verified against the physical schema and RLS catalogue |
| Notification lifecycle inventory | Removed the stale `notification_events` placeholder from the crosswalk and listed the six current notification lifecycle tables |
| Canonical unit identity | Aligned `instruments`, `units` and `unit_identity_conflicts` to the approved `instrument_type` identity and `(instrument_type, serial_normalized)` key |
| Print event schema | Aligned the crosswalk to `batch_id`, `attempt_no`, `outcome`, `failure_code` and `idempotency_key` in the physical specification |
| G10 gate wording | Updated current gate summaries to `NOT ACTIVE` and clarified that older `NOT AUTHORIZED` statements in dated addenda are historical snapshots |
| Controlled document versions | Bumped the affected document versions in accordance with repository SemVer governance |

These corrections improve static SSOT consistency. They do not establish live schema, RLS, grants, function privileges, runtime behavior, or gate closure.

## 4. Certification domain results

| Domain | Result | Evidence and reason |
|---|---|---|
| Architecture and SSOT integrity | PARTIAL | Architecture and authority hierarchy are documented. Crosswalk table-name parity is 48/48 after correction. Full requirement/source/authority reconciliation remains open. |
| Requirements traceability | PARTIAL | RTM and QA catalogue are extensive, but source authority, acceptance closure and independent traceability review remain incomplete. |
| Database and data integrity | NOT VERIFIED | 48-table schema is a proposal. No live PostgreSQL catalog, DDL, constraints, indexes, triggers, sequences, grants or migration state was inspected. |
| Authorization and access control | NOT VERIFIED | Permission registry remains draft; effective role/grantor/SoD rules, live RLS, object ACLs and Storage policies are not proven. |
| API and command contracts | NOT VERIFIED | 54 command IDs are inventoried/reviewed, but exact route/RPC signatures, authorization predicates, physical read/write sets and executable end-to-end evidence remain incomplete. |
| Transaction and concurrency | FAIL — design gate | The lock documents themselves record unresolved ordering conflicts and incomplete parent/child and worker-finalizer paths. The manifest reports 0/54 certified lock-complete; no acyclic graph or adversarial concurrency proof exists. |
| Audit and idempotency | NOT VERIFIED | PO-approved atomicity direction exists, but database enforcement, effective ACLs, retention policy and failure-injection tests have not been executed. |
| Evidence and Storage security | NOT VERIFIED | Private Storage and upload controls are design requirements. Institutional evidence policy, object policies, signed-URL authorization and recovery are not verified. |
| Reliability and recovery | NOT VERIFIED | PostgreSQL and Storage restore drills have not been executed; provider entitlements and measured RPO/RTO are not evidenced. |
| QA and operational readiness | NOT VERIFIED | The QA catalogue contains 413 distinct planned test definitions by DGA's static ID scan. No application, database, security, load, restore, compatibility or UAT test execution is evidenced. |

## 5. Gate disposition

| Gate | Current result | Required closure evidence |
|---|---|---|
| G0 — Governance/repository intent | PARTIAL | Complete repository ruleset, reviewer, branch protection, document authority and change-control evidence |
| G1 — Product closure | BLOCKED | Controlled IFP source/provenance and applicability; complete Standing Bracket annex reconciliation; approved evidence/photo-slot rules; institutional BA/signatory/attendance authority |
| G2 — Domain/workflow closure | PARTIAL / BLOCKED | Close remaining state transitions, exception paths, authority rules, report/closure and attendance semantics |
| G3 — Data/transaction closure | BLOCKED | Complete physical constraints, version-token mapping, command read/write sets, approved lock hierarchy, acyclic graph and database evidence |
| G4 — Security/privacy closure | BLOCKED | Canonical permission/grantor/SoD matrix, T-10 institutional decisions, live ACL/RLS/Storage verification and per-function security review |
| G5 — API/integration closure | BLOCKED | Exact command schemas, route/RPC mapping, JWT forwarding, provider contracts, error/idempotency semantics and command-specific evidence |
| G6 — UX/accessibility closure | PARTIAL | Supported device/browser matrix, offline/local-data controls, accessibility acceptance and UAT evidence |
| G7 — QA strategy closure | PARTIAL | Close traceability gaps and execute required automated, negative-authorization, concurrency and integration tests after G10 |
| G8 — Production operations closure | BLOCKED | Provider/account ownership, billing, region, quotas, secrets custody, monitoring, incident ownership, SLO and restore evidence |
| G9 — Final SSOT/scope freeze | NOT READY | All critical upstream blockers closed; independent cross-document review; signed scope-freeze record |
| G10 — Implementation activation | NOT ACTIVE | Verified G9, approved scope-freeze record and separate G10 activation record |
| G11 — Build and verification | NOT STARTED | Authorized implementation branch, source code, migrations, CI and test evidence |
| G12 — Production release | NOT STARTED | Staging/UAT, production security, restore/rollback, operations acceptance and explicit release approval |

## 6. Critical non-conformities and dependencies

### NC-001 — Authoritative instrument and evidence rules
- IFP controlled source/version provenance, full applicability and photo-slot rules remain open.
- Standing Bracket's 460-row annex and source completeness remain to be reconciled; ambiguous wording and photo-slot applicability need authoritative resolution.
- Required evidence: controlled source files, page/annex inventory, row-level reconciliation and instrument-owner confirmation.

### NC-002 — Institutional document authority
- BA signatory delegation and attendance verification authority are not proven by sample layouts or partially completed records.
- Required evidence: institution-approved templates, signed authority matrix, authorized signatories/verifiers and completed verified examples.

### NC-003 — Institutional privacy and records governance
- T-10 approves the review path, not the resulting data policy.
- Classification, lawful basis/purpose, evidence limits, retention, deletion/disposition, legal hold, audit retention/export and network metadata remain blocked.
- Required evidence: written decisions from authorized institutional records, legal, privacy and security functions.

### NC-004 — Provider ownership and operational control
- Actual Supabase/Vercel legal and account owner, billing owner, custodians, region, plans, quotas, budget and recovery entitlements remain unverified.
- Required evidence: approved ownership/RACI, account and plan evidence, region decision, cost/quota sheet, MFA/custody and exit/recovery controls.

### NC-005 — Recovery and reliability
- Backup configuration is not restore proof. PostgreSQL and Storage object recovery drills are not executed.
- Required evidence: isolated restore drills, checksums/reconciliation, measured RPO/RTO, rollback evidence and Operations sign-off.

### NC-006 — Device/offline and performance
- Device/browser build matrix, local-data protection, cache/purge, shared-device logout, device-loss recovery and offline behavior remain incomplete.
- The 100-user target is a test profile, not demonstrated capacity. Numeric latency/error/availability/upload SLOs remain unapproved and unmeasured.
- Required evidence: approved compatibility matrix, threat model, numeric workload/SLO sheet and staging test report.

### NC-007 — Authorization and command execution
- The canonical permission registry is draft; exact role-to-permission grants, grantor ceiling, revocation freshness and SoD remain open.
- T-18 Option A is an approved execution model only. Per-function owner, effective privileges, fixed search path, exact-signature EXECUTE ACL, PUBLIC/anon denial, JWT propagation and route-to-PostgREST behavior are not verified.
- Required evidence: approved permission matrix, live PostgreSQL role/function/ACL inventory, function-by-function review and caller-JWT positive/negative tests.

### NC-008 — Command and concurrency integrity
- 54 command IDs are inventoried; 50/54 have candidate execution/transaction boundaries documented; CMD-045..048 remain hard-gated; 0/54 are technically approved/certified lock-complete.
- LPR-01 and LPR-07..LPR-11, exact lock modes, implicit FK/index/trigger/function edges, deterministic same-rank ordering, parent fences, worker finalizers and the effective acyclic graph remain open.
- Required evidence: approved normalized manifest, physical dependency extraction, complete lock graph, PostgreSQL concurrency/deadlock tests and Security/Engineering review.

### NC-009 — Audit, notifications, print and closure
- Audit append-only/atomicity has PO direction but lacks deployed enforcement and institutional retention policy.
- Notification selector grammar, durable event-time recipient snapshot/checkpoint, worker identity/ACL, provider callbacks, retry horizons and T-10 policy remain open.
- Print-batch schema/command behavior and project/session closure fences need technical review and execution evidence.
- Required evidence: synchronized schema/command/RLS/API/QA contracts, exact privileges, failure-injection and concurrency tests.

### NC-010 — CI and independent review
- PR #3 is Draft/Open. At assessment time it has no review submissions or review threads.
- The assessed HEAD has no combined status entries and no PR-triggered workflow runs returned by the inspected GitHub endpoints.
- Required evidence: administrator-verified branch/ruleset and required-check configuration, actual successful CI run, required independent approvals and resolved review comments.

## 7. Required closure sequence

1. **Authority and source closure:** complete NC-001 through NC-004. Do not infer institutional authority or create policy values.
2. **Design closure:** resolve NC-006 through NC-009; reconcile the canonical permission matrix, all command contracts, schema/RLS/Storage, version tokens and lock hierarchy.
3. **Independent review:** obtain named Engineering, Security, Database, Operations and institutional approvals for their respective domains. A Product Owner approval cannot substitute for these authorities.
4. **G9 verification:** run a fresh, evidence-indexed SSOT and requirement traceability audit; close all critical non-conformities; obtain the approved scope-freeze record.
5. **G10 activation:** record a separate G10 activation decision only after G9 passes. Re-read `AGENTS.md` and establish the authorized implementation branch.
6. **Post-G10 implementation:** follow IRG-001 in order. Build platform/identity/database foundations first; create immutable migrations; implement least-privilege RLS and command functions; then APIs/UI and automated tests.
7. **G11/G12 verification:** execute CI, functional, security, concurrency, performance, compatibility, recovery, rollback and UAT evidence on the exact release commit and environment before production release approval.

## 8. Evidence limitations

At this assessment baseline:
- No application source implementation or migration was inspected because none is authorized in the current phase.
- No live Supabase/PostgreSQL catalog, RLS policy, grant, Storage bucket policy, Vercel environment or provider account was inspected.
- No SQL, migration, grant/revoke, deployment or production data operation was executed.
- No unit, integration, E2E, RLS, security, concurrency, load, restore, rollback or UAT test was executed by this assessment.
- PR #3 had zero review submissions, zero review threads, zero returned combined status entries and zero returned PR-triggered workflow runs at the assessed HEAD.

Absence of returned CI/status records is reported as “no evidence returned by the inspected endpoints,” not proof that no checks exist anywhere in the organization.

## 9. Final certification decision

**Overall technical certification: NOT CERTIFIED.**

The repository has a substantial specification baseline and the static 48-table crosswalk inconsistency identified during this review has been corrected. However, the remaining design, authority, security, database, concurrency, provider, recovery, CI and test evidence is insufficient for G9 scope freeze.

**Implementation recommendation:** do not activate G10 yet. Continue only the authorized G9 closure work. No implementation or production gate may be marked PASS until its own objective evidence and accountable approvals are recorded.

This report is an internal assessment artifact and does not represent external accreditation or institutional certification.


## 10. Current-head reassessment addendum — 2026-11-24

This addendum supersedes the assessment baseline and repository-state observations in §§1, 6 and 8 only where they refer to the latest inspected branch state. The current PR #3 head at reassessment is `133af5c000b7d00ec34afddcfccf8fcf4d6d91b0` on `docs/audit-lock-and-identity-reconciliation`; PR #3 remains Draft/Open. The current PR review query returned zero review submissions; the combined commit-status query returned no status entries; the PR-triggered workflow-run query returned no runs. These are endpoint observations, not proof that organization-wide checks or policies do not exist.

The lock inventory is now explicitly reconciled as 54 traceability IDs: 50 application commands plus 4 external control-plane IDs (CMD-045–048). All 50 application commands have candidate execution/transaction boundaries documented; full normalized-manifest review and independent technical approval remain open. Application lock certification is **0/50**. LPR-01 and LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. The effective PostgreSQL lock graph is not certified acyclic.

The overall assessment remains **NOT CERTIFIED**. G9 remains NOT READY; G10 remains NOT ACTIVE. No application source, SQL, migration, grants/revokes, live database/provider inspection, CI execution, tests, deployment, merge or production data operation is claimed. This addendum is a static documentation/repository-state reassessment only and does not substitute for independent Engineering, Security, Database, Operations or institutional approval.


## 11. Normalized command-register reassessment — 2026-11-24

LOCK-NORMALIZATION-001 v0.1.0 was added and statically checked against the source tables. It contains 50 unique application command rows (CMD-001–044 and CMD-049–054), with CMD-045–048 correctly excluded as external control-plane IDs. The normalized register is a documentation consolidation, not technical approval. The unresolved fields and conflict register remain explicit. LPR-09 remains OPEN; LPR-10 remains NOT EXECUTED; no effective PostgreSQL lock graph acyclic proof or 0/50-to-PASS transition is claimed. Overall technical certification remains NOT CERTIFIED; G9 NOT READY; G10 NOT ACTIVE.


## 12. Physical object crosswalk reassessment — 2026-11-24

CMD-PHYSICAL-CROSSWALK-001 v0.1.0 was added with 50 command headings: 40 source-derived physical read/write sections for CMD-001–040, four explicit OPEN/BLOCKED entries for CMD-041–044, and six source-derived notification/worker entries for CMD-049–054. CMD-045–048 remain excluded external control-plane IDs. This validates the documentation inventory and exposes physicalization gaps; it does not verify any live table, index, FK, trigger, function, RLS policy, grant, Storage object or provider. In particular, CMD-041–044 require a complete physical query/export model, and CMD-044 remains blocked by T-10.

The 50-command normalized register LOCK-NORMALIZATION-001 v0.1.1 now explicitly includes physical read/write set as a required field and links the physical crosswalk. The static inventory is 50 unique application commands; 0/50 are technically approved/certified lock-complete. LPR-09 remains OPEN; LPR-10 remains NOT EXECUTED. Overall technical certification remains **NOT CERTIFIED**; G9 NOT READY; G10 NOT ACTIVE. No source implementation, SQL, migration, grants/revokes, CI execution, tests, live database inspection, deployment, merge or production data operation was performed.


## CMD-041–044 physical read/export reconciliation — 2026-11-24

Evidence reviewed: CMD-041–044 Detailed Contract Review v0.1.1; Command Physical Object Crosswalk v0.1.1; physical schema/RLS/ERD candidate annexes; Permission Registry v0.2.4; Audit Event Catalogue candidate event disposition; QA catalogue v0.3.8.

Certification effect:
- CMD-041/042: physical source read sets now documented against canonical proposed source tables. This is a documentation completeness improvement only; metric semantics, exact query plans/indexes, bounded limits and runtime RLS remain unverified.
- CMD-043: safe query/projection and anti-recursion design is documented; T-10 reader authority, purpose, classification, retention/legal hold and append-failure policy remain BLOCKED.
- CMD-044: three candidate export object families are documented but NOT ADMITTED; T-10 blocks any executable path.
- 18 new tests are PLANNED / NOT EXECUTED and contribute zero passing evidence.

No certification gate advances. G9 remains NOT READY; G10 remains NOT ACTIVE; application lock certification remains 0/50. No source, SQL, migration, grant, live DB, runtime test or deployment evidence was produced by this documentation pass.


## CMD-045–048 and notification audience snapshot review — 2026-11-24

CMD-045–048 PO-approved application-scope disposition is now consistent in the resolution proposal v0.1.2, detailed review v0.1.4, canonical command catalogue and QA v0.4.2. These are traceability-only external control-plane responsibilities with no application permission or physical command boundary. External T-10/T-12/incident-response/release evidence remains open; no live settings or absence verification is claimed.

NLA-001 v0.1.4 identifies the POQ-01 physical gap and proposes candidate-only `notification_outbox_recipients` to persist event-time recipient/scope snapshots. The candidate is mapped across schema v0.4.4, RLS v0.2.5, ERD v0.3.3, permission v0.2.5, command catalogue v0.4.8, crosswalk v0.1.2 and QA v0.4.1. It is NOT ADMITTED and not counted in the canonical 48 tables. The product semantics are PO-approved; physical representation, bounds, indexes/FKs, RLS/ACL, worker identity and runtime behavior are not approved or verified.

TC-NOTIF-030..035 and TC-RLS-024-049 are PLANNED / NOT EXECUTED. No passing evidence is added. G9 remains NOT READY; G10 remains NOT ACTIVE; application lock certification remains 0/50. No source, SQL, migration, grant, RLS deployment, runtime test, CI or deployment was performed.


## Notification audience snapshot lock-order assessment — 2026-11-24

POQ-01 event-time recipient/scope semantics are approved. The candidate physical representation `notification_outbox_recipients` and candidate outbox snapshot header fields are documented but NOT ADMITTED and excluded from the 48-table inventory. NLA-001 v0.1.4, CMD-049–054 review v0.1.3, schema v0.4.4, RLS v0.2.5, ERD v0.3.3, command catalogue v0.4.8, lock manifest v0.4.26 and global graph v0.4.19 now share the same candidate boundary.

The candidate introduces potential implicit FK KEY SHARE edges to account and scope rows. Exact source command lock sets, recipient eligibility linearization, FK topology, worker transaction order and full competing-writer inventory remain OPEN. RAID R-037 and RTM NOTIF-015 track the critical lock-order risk. LG-41..45 and TC-NOTIF-036..040 are PLANNED / NOT EXECUTED.

No certification gate advances. Global lock graph is not proven acyclic; LPR-01/LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE; application lock certification remains 0/50.
