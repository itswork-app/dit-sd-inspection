# Package S — Final Cross-Document Audit and Scope-Freeze Readiness

> **Historical snapshot note:** The original audit and §9.15–§9.16 were produced before/around the 2026-11-24 conditional authorization transition. The original “Implementation authorization: NOT GRANTED” field and older G10 NOT AUTHORIZED statements are preserved historical records, not current status. Current state is PO CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED; G9 NOT READY; G10 NOT ACTIVE. See §9.17.

**Status:** Audit completed — NOT READY FOR SCOPE FREEZE  
**Implementation authorization:** NOT GRANTED  
**Repository:** itswork-app/dit-sd-inspection  
**Branch reviewed:** docs/phase-0-foundation  
**PR:** #2 (Draft / Open)  
**Review date:** 2026-11-23  
**Audit basis:** Current PR change inventory (45 files) and direct content review of the charter, decision/governance registers, PRD, acceptance criteria, instrument specifications, functional workflows, architecture/database/RLS/command/audit/privacy/recovery documents, UX specifications, and quality/test plans.

## 1. Executive conclusion

The documentation baseline is substantial and has a consistent architectural direction: non-SaaS institutional inspection replacement; initial IFP and Standing Bracket instruments; Super Admin-configurable instrument definitions; Supabase PostgreSQL as the source of truth; Supabase Auth/RLS/private Storage; Vercel application hosting; and a modular-monolith approach.

However, the baseline is NOT READY for scope freeze and does not authorize feature implementation. Several product and institutional decisions remain open, and source reconciliation issues must be closed before implementation contracts can be treated as authoritative.

The review found no basis to claim that the application has been implemented, database/RLS policies are deployed, CI is passing, or security, backup restore, offline behavior, and performance have been tested.

## 2. Scope and review method

Reviewed the current 45-file PR #2 change inventory and directly fetched the principal documents across governance (Charter, Decision Register, Phase 0 Plan, RAID, RTM, Packages F/G/I), product (PRD, Acceptance Criteria, IFP and Standing Bracket specifications), functional design (RBAC, inspection lifecycle/claims, project/session/assignment, reports/documents/audit), architecture (system, logical and physical data models, RLS catalogue, privileged command boundary, audit governance, evidence privacy, backup/restore, API, performance), UX, and QA/test plans.

This is a documentation consistency review. It is not a legal opinion, independent security assessment, implementation review, penetration test, provider entitlement verification, or executed UAT.

## 3. Consistent baseline confirmed

| Area | Cross-document result | Disposition |
|---|---|---|
| Product boundary | Replacement application, not SaaS; feature parity before improvements | Consistent |
| Initial instruments | IFP and Standing Bracket initially; future instrument types configurable by Super Admin | Consistent in core product/architecture direction |
| Platform | Supabase + Vercel; PostgreSQL single source of truth; GitHub source/CI | Consistent |
| Capacity | Configurable 1–100 distinct active Inspector accounts combined across both locations; default 50 | Consistent in current charter/governance baseline; exact active-account predicate still open |
| Identity | Google sign-in; pending account approval; no self-assigned roles | Consistent |
| Authorization | Multi-role with explicit assignment scope; backend enforcement; RLS; separation of duties | Consistent as design baseline |
| Inspection | Immutable submitted revisions; correction through Inspector resubmission; authorized reopen with reason | Consistent as proposed workflow |
| Instrument configuration | Declarative, versioned configuration; active session freezes version; history retains snapshot | Consistent conceptually; schema and validation primitives need final approval |
| Reporting | Actual events separate from target allocations | Consistent |
| Cost/security | Cost-first does not waive security, privacy, integrity, backup, or reliability | Consistent |

## 4. Findings requiring correction or approval

### S-01 — Standing Bracket source reconciliation remains unresolved
**Severity:** BLOCKER

The 23-November sample form and earlier screenshot transcription each show 19 visible rows (six physical-condition rows plus thirteen accessory rows in the sample form). Wording, context, item mapping, and authority of the two sources have not been proven identical. The form labels the item “Interactive Flat Panel (IFP) Standing Bracket”, which is ambiguous and must not be silently normalized.

Required action: keep each source observation distinct; obtain the controlled approved checklist/version; confirm instrument identity/model applicability, item mapping, mandatory/conditional/N/A behavior, and evidence slots; reconcile provisional IDs only after authorized confirmation.

### S-02 — IFP source authority and evidence-slot rules remain open
**Severity:** BLOCKER

The IFP specification identifies 49 checklist statements, 14 specification fields, and 10 photo labels. The official controlled checklist/version, model applicability, photo-slot completeness, and mandatory/conditional/optional rules have not been formally approved.

Required action: obtain the authoritative instrument source and explicit Product Owner/institution sign-off before enabling submission gates.

### S-03 — BA and attendance authority is incomplete
**Severity:** BLOCKER

The 20-November Standing Bracket BA provides a real sample with 460 checked units, 456 good, and 4 defective; it also shows serial-number annex structure, condition groups, and paraf/signature blocks for Tim Pemeriksa Dit.SD and PT Hisense. This is sample evidence, not approval of permanent signatory identities, required signatory count/order, or verification authority.

Required action: approve BA parties/signatory blocks/order/titles/mandatory status; attendance verifier role and replacement rules; BA issue and signed-copy lifecycle; and count source/reconciliation policy for reports and session/project closure.

### S-04 — Session lifecycle and planning authority are not fully frozen
**Severity:** BLOCKER

The session model leaves session creation authority and exact state transitions open. Planning says Super Admin controls official assignments, while operational workflow supports Inspector self-claiming units within an assigned team/session. These are compatible only if the distinction is explicit: Super Admin assigns a person to the operational assignment; Inspector claims an eligible unit within that assignment.

Required action: approve session creation authority; state machine and pause/resume/close/reopen transitions; distinction between official team membership and per-unit claim; closed-session reopening authority and treatment of offline drafts at pause/closure.

### S-05 — Offline, device, and local data protection contract is incomplete
**Severity:** BLOCKER

Supported devices/browsers, local encryption, cache lifetime, purge, device-loss response, conflict resolution, and maximum offline retry window remain unresolved.

Required action: approve bounded offline scope and device/browser matrix, then align functional, API, storage, privacy, and acceptance documents.

### S-06 — Privacy, records retention, deletion, and legal hold require institutional approval
**Severity:** BLOCKER

Retention durations, legal basis, records classification, original EXIF handling, deletion/disposition authority, legal hold, and audit retention remain open.

Required action: obtain decisions from authorized institutional legal, privacy, security, and records owners. Engineering must not invent statutory retention periods.

### S-07 — Production provider, region, quota, backup, and ownership are unverified
**Severity:** BLOCKER

Supabase/Vercel are the chosen technology baseline, but actual organization/project, region/data residency, plans, quotas, backup/PITR eligibility, Storage object recovery, billing owner, budget, alerts, and operational contacts have not been verified. Proposed RPO/RTO and backup cadence are not evidence of capability.

Required action: complete provider capability and cost review, approve region and plan, configure environments, and execute isolated database and Storage restore drills.

### S-08 — Physical schema, RLS, and privileged command boundary require technical closure
**Severity:** BLOCKER

PO direction is approved for T-16 canonical serial identity, T-17 instrument publication governance and T-18 caller-JWT command architecture plus Option A narrow SECURITY DEFINER protected-write wrappers. The project-independent canonical unit + durable project-association model is documented. However, physical constraints/composite FKs, institutional serial normalization/exception policy, exact table/function grants, RLS helper implementation, per-function SECURITY DEFINER review, command-by-command contracts and executable security/concurrency evidence remain OPEN. No policy or command is deployed.

Required action: complete technical review of schema/association constraints; publish the canonical permission registry; reconcile every table/view/RPC/Storage object with exact grants; complete command contracts and dedicated negative/concurrency tests before any implementation authorization.

### S-09 — PO-approved audit direction; institutional governance remains blocked
**Severity:** BLOCKER

INS-016 is PO APPROVED option A under T-15: append-only audit records, atomic critical mutation + audit, fail-closed behavior, privacy-safe event context and least-privilege read/export. Institutional classification, retention, deletion/disposition, legal hold, network metadata, independent archive decision and final audit-reader/export authority remain OPEN under T-10. The command-level implementation and verification are also not complete.

Required action: obtain formal institutional records/privacy/legal/security decisions and complete command-level atomic audit contracts, RLS/grants and failure-injection test design. Do not treat PO approval as institutional policy approval or implementation evidence.

### S-10 — Report delivery, report count basis, and project reconciliation remain open
**Severity:** HIGH

Actual vs Target separation is consistent, but headline count semantics, client portal vs PDF-only, separate vs shared templates, final reconciliation, and project closure authority remain open.

Required action: decide exact report count states and delivery/closure process; ensure BA, serial annex, report totals, and inspection register use the same authoritative records.

### S-11 — Numeric performance and service objectives are not approved or measured
**Severity:** HIGH

The 100 concurrent authenticated-user workload is a test-design target, not measured capacity. Numeric latency/error/availability SLOs, evidence upload profile, export/print workload, and provider usage envelope remain open.

Required action: approve measurable workload and SLO thresholds, then run tests in the selected staging environment and retain results.

### S-12 — CI and repository controls are not verified by this audit
**Severity:** HIGH

The test strategy defines cost-aware CI and branch protection expectations, but this review did not inspect live branch protection settings, current workflow execution, provider quota, or required checks.

Required action: verify actual GitHub rules and CI workflows and record a successful required-check run before merge.

## 5. Cross-document alignment rules to retain

1. Super Admin configuration is declarative and constrained to supported field types/validation primitives; arbitrary executable code is not permitted.
2. Instrument version changes do not rewrite active sessions or historical inspections.
3. Official assignment and per-unit claim are separate concepts.
4. Actual inspection events are immutable facts; target allocations are separate, versioned planning data.
5. A completed unit follows the current baseline definition: approved inspection, final PDF generation, and recorded Print Officer print action.
6. Physical printing is never inferred from opening or downloading a PDF.
7. T-15 / INS-016 is PO APPROVED: audit write and critical state mutation must be atomic and fail closed; institutional retention and metadata policy remain separate gates.
8. No public evidence URL; private object access is mediated and authorized.
9. A document/sample is reference evidence, not automatically an authoritative specification.
10. Proposed design, approved decision, implemented control, and tested control remain distinct statuses.

## 6. Decision Register and RAID updates required

Before scope freeze: convert each remaining blocker into a tracked decision/issue with an accountable institutional role; retain T-15 as PO APPROVED while keeping T-10 institutional records/privacy controls OPEN; keep source checklist/photo requirements OPEN until controlled source approval; keep provider/region/backup and privacy/retention dependencies OPEN until verified; implement and verify the T-14 qualifying Inspector predicate; complete T-16 technical review and T-18 per-function/permission/ACL verification; decide session creation and closed-session reopening; and resolve report count/delivery/closure semantics.

## 7. Scope-freeze gate

- [ ] Controlled IFP checklist, specification, and photo requirements approved.
- [ ] Controlled Standing Bracket checklist and photo requirements approved.
- [ ] BA, signatory, attendance, and verification authority approved.
- [ ] Session lifecycle, creation authority, assignment, and claim boundary approved.
- [ ] Offline/device/local data protection contract approved.
- [ ] Privacy, records retention, deletion, and legal hold approved.
- [ ] Production region, plans, quotas, billing, operational owners, and recovery capabilities approved.
- [ ] Physical schema and serial identity invariants approved.
- [ ] RLS and privileged command boundary approved.
- [x] INS-016 PO direction approved under T-15; [ ] institutional T-10 classification, retention, legal hold, disposition and audit metadata policy approved; [ ] command-level atomic audit implementation/test evidence.
- [ ] Report delivery/count/reconciliation/project closure approved.
- [ ] Performance workload and measurable thresholds approved.
- [ ] UAT owner, pilot scope, release/rollback criteria, and operational support owners confirmed.
- [ ] PRD, Decision Register, RTM, RAID, functional design, architecture, UX, and QA artifacts reconciled after decisions.

## 8. Audit disposition

**Documentation baseline:** SUBSTANTIAL; usable for controlled decision closure and design refinement.  
**Cross-document consistency:** PARTIAL; major architectural direction aligns, but unresolved source/authority and operational contracts remain.  
**Scope freeze:** NOT READY.  
**Feature implementation:** NOT AUTHORIZED.  
**Production readiness:** NOT ASSESSED / NOT ESTABLISHED.

No code, migrations, live RLS, application routes, deployed infrastructure, security tests, restore drills, load tests, or UAT were executed as part of Package S.

## 9. Follow-up reconciliation after T-15 through T-18 (2026-11-24)

This follow-up preserves Package S as the historical pre-decision audit and supersedes only status statements affected by later approved decisions.

### 9.1 Reconciled decisions

- **S-08 / T-16:** The Product Owner approved canonical serial uniqueness across projects by instrument type. The physical design now specifies project-independent `units`, durable `unit_project_associations`, controlled duplicate conflicts, composite association/project/assignment integrity and a global active claim per canonical unit. The association model is documented for technical review; institutional serial normalization/exception policy and implementation remain open.
- **S-08 / T-18:** The Product Owner approved the Vercel route → PostgreSQL command function pattern with caller JWT. Protected browser-facing business/governance table DML is denied by design; PostgreSQL derives actor identity and performs permission/scope/state/separation checks with mutation and audit atomically. RLS/grants and command-specific function review are not deployed or verified.
- **S-09 / T-15:** INS-016 is now PO APPROVED option A. Atomic append-only audit and fail-closed critical writes are the approved direction. Institutional retention, legal hold, classification, network metadata and archive requirements remain open.
- **Capacity / T-14:** The distinct enabled-account + active Inspector grant + effective assignment predicate is PO-approved and must be enforced atomically across both locations.
- **Instrument governance / T-17:** Super Admin direct publication through explicit `instrument.publish`, declarative server-side validation, atomic audit and immutable published versions is PO-approved.

### 9.2 Current cross-document findings

1. Package K and this Package S remain historical audit records; their original pre-decision findings must be read with this addendum and the Decision Register.
2. Package L/M/N design artifacts now contain the T-16/T-17/T-18 direction, but still require technical review, command/grant completeness, and executable verification before migration or release.
3. API contracts, RTM, system architecture and RLS catalogue require consistent status language for the approved command boundary and direct-DML prohibition.
4. T-01 source completeness (official IFP source and evidence-slot rules), T-02 institutional signatory authority, T-10 institutional privacy/records approval, T-11 measurable SLO/device validation, and T-12 provider/ownership/recovery verification remain unresolved.
5. CI/repository protections and release evidence must be inspected separately; a clean documentation diff or green CI alone does not establish scope-freeze or production readiness.

### 9.3 Updated disposition

**Product Owner decision closure:** T-14 through T-18 are approved at PO level as recorded in the Decision Register.  
**Technical design:** materially advanced; Package L/M/N cross-document and implementation-level review remains open.  
**Institutional/provider evidence:** BLOCKED for the items listed above.  
**Scope freeze:** NOT READY.  
**Feature implementation:** NOT AUTHORIZED.  
**Implementation, migration, deployment, security tests, restore drills, load tests and UAT:** NOT EXECUTED / NOT CLAIMED.

The original S-01..S-12 checklist is still a useful gate inventory, but decision items closed by T-14..T-18 must not be represented as awaiting Product Owner approval. External institutional and technical verification gates remain active.


## 9.4 Command-by-command audit follow-up (2026-11-24)

The T-18 command boundary architecture is PO-approved, but the command inventory is not yet a complete implementation contract. The follow-up audit identified and corrected documentation-level issues: duplicate lock-order numbering, inconsistent capacity lock/predicate wording, duplicate QA test IDs for load and batch-print scenarios, and incomplete API error-code alignment. The lock order now places authenticated actor-scoped idempotency arbitration first, followed by capacity, canonical serial, project/assignment, unit, association, inspection, evidence/document and append-only event locks.

The command inventory now explicitly records previously omitted families: instrument deactivation, evidence access/export, project closure, audit read/export and bounded batch-print orchestration. Their exact permission codes and detailed contracts remain OPEN and must not be inferred from broad Super Admin status. The test catalogue records that generic TC-CMD-018 security cases are boundary-level only; command-specific positive/negative, audit-failure, idempotency and concurrency cases are still missing for several command families.

**Current Package N status:** architecture PO-approved; command-family inventory improved; command-by-command request/response schemas, permission/scope predicates, lock/idempotency/audit/error contracts, exact grants and dedicated test traceability remain INCOMPLETE. No implementation or test execution is claimed. Scope freeze remains NOT READY.


## 9.5 Permission registry and audit-status reconciliation (2026-11-24)

The earlier S-09 and Package R wording that INS-016 remained unapproved is superseded: T-15 option A is PO APPROVED. The remaining blocker is institutional T-10 approval and command-level implementation/verification, not another PO decision on the audit direction.

The legacy RBAC permission vocabulary and the T-18 command inventory are not yet one canonical registry. Several command identifiers are absent from the legacy catalogue, while legacy codes (notably combined `audit.view` and `document.upload`) need explicit mapping or separation. T-17's `instrument.manage`, `instrument.publish` and `instrument.deactivate` remain distinct. Evidence read/export, audit read/export and project closure require explicit narrow authority; no broad role may implicitly grant them.

**Required closure:** publish canonical permission registry and legacy-code disposition; map every command to one or more exact permissions and scope predicates; map every permission to role/grant authority and separation-of-duties rule; link each command to its RLS/EXECUTE grant and dedicated test cases. This is a scope-freeze blocker. No permission seed, grants or implementation are claimed.


## 9.6 Canonical permission registry baseline (2026-11-24)

Created docs/02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md v0.1.0 as the single proposed permission vocabulary. It defines narrow codes for identity, role/scope, project/session/assignment/capacity/target, T-17 instrument governance, T-16 unit association, inspection lifecycle, evidence read/export, offline sync, document generation/print/batch, attendance upload/verify, report read, audit read/export, retention/legal hold, security, provider and release administration. It also records scope classes, proposed grant constraints, legacy-code disposition, command-to-data/RLS/audit/test traceability, and the deliberately unapproved role-class matrix.

The document is a draft baseline, not a PO decision. The legacy permission table remains a historical vocabulary snapshot. No permission code is approved for seeding merely by appearing in the new registry. PO/security approval is required for code semantics, every legacy mapping/retirement, role-to-permission grants, grant/revoke authority, project-close authority, evidence/audit read/export, security/platform custodians, and SoD. Exact per-table RLS, per-function EXECUTE grants and concrete command-specific test IDs remain incomplete. RBAC-004 is now DESIGN DRAFT CREATED, not closed.

**Package M/N status:** canonical vocabulary draft created; approval and executable authorization traceability OPEN. Scope freeze remains NOT READY. No permission seed, SQL grant, RLS change, route/RPC, migration, runtime test or deployment occurred.

## 9.7 Command authorization verification matrix (2026-11-24)

Created [Command Authorization Verification Matrix](../02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md) v0.1.0 and linked it to the QA catalogue. It maps 27 logical command families to proposed canonical permission codes, trusted actor/scope/SoD rules, logical data and RLS/grant review classes, atomic audit events and 36 newly allocated design-level verification cases (TC-CMD-AUTHZ-024-001..036). The 36 IDs were checked for uniqueness within the new series; they are specifications only and have not been executed.

The matrix explicitly leaves unknown physical table/function names, request/response schemas, exact role/grantor authority, detailed scope predicates, table-by-table RLS, RPC EXECUTE grants, SECURITY DEFINER exceptions, idempotency retention and some command authorities as TBD/open. It does not convert the permission registry into approved policy and does not authorize implementation.

**Package N follow-up:** command-family mapping is now documented, but individual command contracts remain incomplete (0 complete command-specific contracts). The next technical closure must reconcile the authoritative physical schema and every table's SELECT/INSERT/UPDATE/DELETE policy, then define each individual RPC signature/EXECUTE grant and exact positive/negative/replay/audit-rollback/concurrency tests. T-10 institutional records/privacy, T-12 provider ownership, T-16 serial policy/relational technical review and remaining instrument/document source authorities continue to block scope freeze.

**Disposition unchanged:** permission registry PO/security approval OPEN; RLS/grants/RPCs NOT IMPLEMENTED; tests NOT EXECUTED; scope freeze NOT READY; implementation NOT AUTHORIZED.

## 9.8 Physical schema ↔ RLS ↔ command reconciliation (2026-11-24)

Created [Physical Schema ↔ RLS ↔ Command Reconciliation](../02-architecture/PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md) v0.1.0. A deterministic name comparison of the current Package L physical catalogue and Package M RLS catalogue found exact **41/41 table parity**: no physical table lacks an RLS catalogue row, and no RLS row lacks a physical table specification. The reconciliation records key columns, proposed SELECT classes, CMD/NONE mutation classes and integrity focus for all 41 tables.

The logical ERD currently names two additional entities absent from both physical and RLS catalogues: `print_batches` and `notification_events`. Their disposition is open. `print_batches` requires an explicit decision on whether the per-document `print_events` + idempotency model is sufficient or a durable batch aggregate is needed. `notification_events` requires reconciliation with INS-015: durable notification state, recipient/assignment scope, delivery/read state, retries/idempotency, channels, audit/versioning and retention must be specified before adding a physical table. Neither ERD-only name authorizes a migration or exposure.

The reconciliation also separates T-18 browser DML denial from command-only mutations: a catalogue value of CMD is not a browser table grant. The QA catalogue now allocates 41 table-specific design cases (TC-RLS-024-001..041), one per table, to verify declared SELECT scope and browser DML denial; they are planned, not executed. Exact database role GRANT/REVOKE, per-command RPC signatures/EXECUTE grants, RLS predicates, Storage policies, views, triggers, functions, sequences and SECURITY DEFINER review remain open. No live database was inspected, no RLS/grant was deployed, and no runtime security test was executed.

**Updated disposition:** physical/RLS inventory documentation parity PASS (41/41); ERD-only entity disposition OPEN; live database/RLS/grants verification OPEN; command-specific contracts and executable tests OPEN; scope freeze NOT READY; implementation NOT AUTHORIZED.

## 9.9 Individual PostgreSQL command contract catalogue (2026-11-24)

Created [PostgreSQL Command Contract Catalogue](../02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) v0.1.0. It expands the 27 logical command families into **48 individual logical operations** (CMD-001..048), including proposed request allowlists, permission, JWT-derived actor, scope/SoD, physical read/write set, lock/invariant, idempotency, audit event and typed outcomes. No PostgreSQL function names/signatures or REST paths are represented as verified; those are deliberately left unapproved because the deployed schema/function inventory has not been inspected.

The QA catalogue now contains **48 unique planned cases** (TC-CMD-CONTRACT-024-001..048), one per logical operation. They are design specifications only, not executed tests. CMD-045..048 (retention/legal hold, security incident review, provider configuration, production release) are explicitly blocked pending T-10/T-12 institutional authority and physical schema. CMD-038 does not assume an approved `print_batches` table; `notification_events` remains a separate INS-015 ERD/physical schema discrepancy.

**Important distinction:** 48 draft contract rows exist, but **0 approved/executable command contracts** are complete. Exact OpenAPI/JSON Schema, route mapping, PostgreSQL signatures/types, function owner/security mode/search_path, per-role table grants, RPC EXECUTE grants, executable RLS predicates, Storage policy, exact role/grantor matrix, idempotency retention and staging test evidence remain open. The permission registry is still a draft.

**Disposition unchanged:** no migrations, seeds, grants, RLS changes, functions, routes, runtime tests or deployment were performed. Scope freeze NOT READY; implementation NOT AUTHORIZED.

## 9.10 PostgreSQL function security and EXECUTE grant design (2026-11-24)

Created [PostgreSQL Function Security & EXECUTE Grant Design](../02-architecture/POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md) v0.1.0. It maps 48 logical operations to provisional function classes (F1 protected mutations, F2 scoped reads, F3 internal helpers, F4 triggers, F5 workers, F6 blocked institutional operations), defines target caller-principal classes, exact-signature ACL principles, PUBLIC/anon denial, SECURITY DEFINER hardening, catalog introspection requirements and 63 planned security cases (48 per-operation + 15 global).

**Resolution:** the Product Owner approved Option A on 2026-11-24: narrow SECURITY DEFINER command wrappers for protected writes, with SECURITY INVOKER for read-only paths/helpers where feasible. The approved model rejects broad authenticated table DML, service-role substitution and a separate executor connection as the default. Each definer function requires a dedicated least-privileged NOLOGIN owner, fixed empty search_path, schema-qualified references, exact-signature grants, caller-JWT actor derivation, internal authorization and atomic audit. See T18 Execution Model Security Review. Exact functions, owner grants, live ACL inventory and runtime verification remain open.

No live Supabase role/function/ACL introspection was performed. No functions, role changes, grants/revokes, table ACL changes, RLS, migrations or runtime tests were executed. All 63 cases remain PLANNED / NOT EXECUTED.

**Updated disposition:** T-18 execution-model decision PO APPROVED Option A; role/ACL inventory OPEN; exact function signatures, owners and grants OPEN; end-to-end JWT and runtime verification NOT EXECUTED; scope freeze NOT READY; implementation NOT AUTHORIZED.

## 9.11 Supabase live database security inventory runbook (2026-11-24)

Created [Supabase Live Database Security Inventory Runbook](../02-architecture/SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md) v0.1.0 with metadata-only SELECT queries for environment/version, role attributes/memberships, schema/table ownership and ACL, RLS/policies, function signatures/owners/security modes/settings/EXECUTE ACL, default privileges, sequences, views, triggers and Storage policy metadata. It also defines the Dashboard evidence needed for exposed schemas, Auth configuration, environment-variable names (never values), region, backups/PITR, network and provider ownership.

Repository path inspection did not find supabase/config.toml or supabase/migrations/README.md at the inspected branch paths. This is not proof that no configuration/migrations exist elsewhere. No Supabase/PostgreSQL connector or read-only database session is available in this workspace; live inventory is therefore **NOT EXECUTED**. The runbook explicitly prohibits privilege/schema mutations and instructs reviewers not to elevate access when a query is denied.

QA added 10 unique planned cases (TC-LIVE-INV-026-001..010) for live inventory evidence. The runbook SQL blocks were statically checked to contain SELECT statements only; no SQL was executed. Existing 63 function-security cases remain separate and PLANNED / NOT EXECUTED.

**Disposition unchanged:** live role/ACL/RLS/function inventory OPEN; T-18 Option A selection PO APPROVED but deployed conformance unverified; T-10 institutional records/privacy and T-12 provider/backup/ownership evidence remain blockers; scope freeze NOT READY; implementation NOT AUTHORIZED.



## 9.12 T-18 execution-model security review (2026-11-24)

Created [T-18 Execution Model Security Review](../02-architecture/T18-EXECUTION-MODEL-SECURITY-REVIEW.md) following explicit PO approval of Option A. The approved hybrid model uses narrow SECURITY DEFINER PostgreSQL command wrappers for protected writes and SECURITY INVOKER/RLS for read-only paths where feasible. It defines dedicated NOLOGIN owner isolation, fixed empty search_path, schema-qualified references, exact EXECUTE ACLs, caller-JWT preservation, internal database authorization, direct browser DML denial, and atomic audit/idempotency requirements.

QA added 12 unique planned cases (TC-EXEC-MODEL-027-001..012) covering owner attributes and ownership, search_path, exact EXECUTE ACL, caller-JWT path, actor spoofing, browser DML denial, RLS interaction, authorization freshness, audit rollback, idempotency/concurrency and read-path separation. These are PLANNED / NOT EXECUTED.

**Decision status:** T-18 execution-model selection PO APPROVED Option A. **Verification status:** actual repository runtime route/client implementation, live Supabase role/function/ACL inventory, exact function signatures/owners/grants and runtime tests remain OPEN / NOT EXECUTED. Option B is not selected. Scope freeze remains NOT READY; implementation remains NOT AUTHORIZED.


## 9.13 T-19 repository runtime architecture audit — superseded interpretation (2026-11-24)

The original T-19 tree inspection was performed against the documentation branch and `main`. The initial audit correctly recorded that no application source/configuration was present in those refs, but its proposed follow-up question about whether a separate application repository was intended is superseded by the Product Owner clarification on 2026-11-24.

**Confirmed repository intent:** `itswork-app/dit-sd-inspection` is the single repository for both the authoritative documentation and the future application. The current phase is intentionally documentation/SSOT maturation. Application source, migrations and deployment artifacts are not expected until documentation gates close and separate implementation authorization is granted. Their current absence is not a repository defect.

The T-19 source-tree scan remains a valid historical snapshot only. Its earlier file-count value is not treated as a current inventory count. The latest T-19 audit document records the updated branch intent and evidence boundary.

**Disposition:** documentation-first repository intent CONFIRMED; no application implementation expected in current phase; scope freeze NOT READY; implementation NOT AUTHORIZED. See [T-19 Repository Runtime Architecture Audit](../02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md).

## 9.14 Documentation gap audit — implementation gate readiness (2026-11-24)

Created [Documentation Gap Audit — Gate Implementation Readiness](DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) v1.0.0 after reviewing the current Master Implementation Blueprint, Package S/T, Decision Register, RTM, RAID, PRD, PostgreSQL command catalogue, physical schema, RLS reconciliation, QA catalogue, backup/recovery, performance and provider governance documents.

The audit confirms substantial documentation coverage but identifies active blockers: authoritative IFP/evidence-slot source; Standing Bracket annex/photo rules; institutional BA/signatory authority; T-10 records/privacy/legal approvals; T-12 provider ownership/region/plan/quota/budget evidence; offline device/local-data controls; numeric SLOs; canonical permission/role/grantor/SoD approval; incomplete 48 command contracts (0 approved/executable end-to-end); unresolved ERD-only `print_batches` and `notification_events`; exact RLS/grants/function signatures and caller-JWT runtime proof; notification lifecycle/physical persistence; report/closure reconciliation; CI/branch protection evidence; and stale status language across historical decision/audit artifacts.

The QA catalogue contains 348 distinct test identifiers by text-level scan, including 48 command-contract, 36 command-authorization, 41 RLS-table, 63 function-security, 12 T-18 execution-model, 10 live-inventory and 8 repository-audit planned cases. These are specifications, not executed or passing tests. One test identifier appears more than once as a textual reference. No application, live database, CI, security, restore, load or UAT execution was performed by this audit.

**Updated disposition:** documentation inventory SUBSTANTIAL; documentation closure INCOMPLETE; scope freeze NOT READY; implementation NOT AUTHORIZED; production readiness NOT VERIFIED. The gap audit is the active work queue and must be reconciled as each item closes.

## 9.15 Current SSOT reconciliation — command, permission and function-security baseline (2026-11-24)

This addendum supersedes historical counts/status in sections 9.10 and 9.14 where they conflict with the current documentation branch. It preserves those sections as dated historical audit records.

- Current proposed physical schema/RLS inventory: **48/48 table-name parity** by static document comparison. This is a proposed documentation inventory, not deployed database evidence.
- Current proposed command inventory: **54 operations (CMD-001..054)** across 28 authorization families. CMD-001..048 remain the original domain operations; CMD-049..054 add notification inbox, policy and internal worker operations.
- Canonical permission registry and command authorization matrix: v0.2.0 proposal. No role-to-permission, grantor/delegation or worker-principal grant is approved.
- Command authorization verification: **40 planned cases** (TC-CMD-AUTHZ-024-001..040), not executed.
- Function security verification: **69 planned cases** (TC-FN-SEC-025-001..069), comprising 54 operation-level and 15 global privilege-boundary cases; not executed.
- QA catalogue: **391 distinct test identifiers** by text-level scan. Counts are identifiers/specifications, not execution evidence.
- T-18 Option A remains PO-approved at model-selection level. Function owners, effective privileges, exact signatures, EXECUTE ACLs, JWT propagation and runtime conformance remain open.
- DGA-B10, B11, B12 and B13 remain open; B14 remains partial; B16 is partially reconciled. Scope freeze remains NOT READY and implementation authorization remains NOT GRANTED.

No SQL, migration, permission seed, grant/revoke, live database mutation, deployment, CI/runtime/security/load/restore test or UAT was performed by this documentation update.


## 9.16 Current cross-document governance reconciliation — 2026-11-24

This addendum supersedes §9.15 only for current navigation and inventory counts. Sections 9.10, 9.14 and 9.15 remain historical snapshots and are not rewritten as if they had been produced from later source versions.

### Current controlled sources

- AGENTS.md v1.2.0 — mandatory repository policy.
- MIB-001 v1.0.7 — governance control plane.
- DGA-001 v1.11.26 — active gap register; 21 DGA-B IDs.
- IRG-001 v1.0.1 — pre-implementation roadmap; not authorization.
- Decision Register — canonical current Product Owner decision index.
- Package T v0.1.1 — historical decision pack; PO outcomes are recorded, current authority remains the Decision Register and dated addenda.
- RTM-001 v0.1.2 — 125 unique requirement IDs.
- RAID-001 v0.1.1 — 65 unique risk/assumption/issue/dependency IDs.
- QA Catalogue v0.3.5 — 410 unique planned test-case definitions in the current DGA scan.

### Current static inventory

- Proposed command catalogue: 54/54 command IDs and QA anchors.
- Command lock manifest: 54/54 inventoried; 10/54 candidate-normalized; 0/54 technically approved/certified.
- Proposed physical schema/RLS inventory: 48/48 table-name parity by static document comparison only.
- QA: 410 unique planned test definitions; no test execution is claimed.
- Notification QA: TC-NOTIF-001..026 planned only.
- Print batch QA: TC-PRINT-BATCH-001..008 planned only.

The §9.15 value of 391 distinct test identifiers remains a valid historical text-level count for that checkpoint; it is superseded for current inventory navigation by the later DGA-001 scan of 410 unique test-case definitions. Neither count represents executed tests.

### Decision and authority status

- T-01: Standing Bracket source confirmed by PO; official IFP source and complete photo/evidence-slot/annex reconciliation remain open.
- T-02: configurable BA signatory blocks are PO-approved; institutional signatory authority and final template remain open.
- T-05..T-18 and LPR-02..LPR-06 retain their recorded PO outcomes; design, technical, institutional and verification dependencies remain open where specified.
- T-10: PO-approved institutional review path only; written institutional records/legal/privacy policy remains blocked.
- T-12: PO-approved alternative provider-ownership path only; actual owners, custodians, region, plan, budget and recovery evidence remain blocked.
- No PO decision authorizes implementation, merge, production data use, SQL, migrations, grants or deployment.

### Current cross-document audit and request packages

- [SSOT-AUDIT-001 — Cross-Document Reconciliation Audit](SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md) records the DGA/RTM/RAID/Decision Register/Package S/T reconciliation.
- [POQ-001 — Product Owner Open Decision Packet](PRODUCT-OWNER-OPEN-DECISION-PACKET.md) contains only unresolved product-semantic questions.
- [AUTH-001 — Institutional and Technical Authority Approval Package](INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md) routes institutional, Security, Database, repository and Operations evidence requests.

### Gate disposition

G1–G8 retain the current DGA dispositions; G9 remains NOT READY; G10 remains NOT AUTHORIZED; G11/G12 remain NOT STARTED. This addendum improves current cross-document navigation and traceability only. It does not close S-01..S-12, establish scope freeze, or replace independent G9 review.


## 9.17 Current authorization and gate status — 2026-11-25

This addendum supersedes only the authorization and gate-status pointers in the historical snapshot above; it does not rewrite the evidence boundary or findings of the original audit.

- Product Owner conditional implementation authorization: **RECEIVED (2026-11-24)**.
- G9 scope freeze: **NOT READY**; institutional, source-authority, command, schema, security, lock and operational evidence blockers remain open.
- G10 implementation activation: **NOT ACTIVE**; it requires verified G9 and a separate approved G10 activation record.
- Production readiness: **NOT VERIFIED**.
- The GOV-MERGE-001 exception permits only qualifying documentation-only PR merges under its separate review controls; it does not authorize implementation or waive G9/G10.
