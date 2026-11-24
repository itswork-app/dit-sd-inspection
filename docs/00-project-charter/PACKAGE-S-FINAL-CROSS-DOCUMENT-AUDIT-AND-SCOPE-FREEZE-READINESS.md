# Package S — Final Cross-Document Audit and Scope-Freeze Readiness

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

PO direction is approved for T-16 canonical serial identity, T-17 instrument publication governance and T-18 caller-JWT command architecture/direct-DML denial. The project-independent canonical unit + durable project-association model is documented. However, physical constraints/composite FKs, institutional serial normalization/exception policy, exact table/function grants, RLS helper implementation, SECURITY DEFINER review, command-by-command contracts and executable security/concurrency evidence remain OPEN. No policy or command is deployed.

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

Before scope freeze: convert each remaining blocker into a tracked decision/issue with an accountable institutional role; retain T-15 as PO APPROVED while keeping T-10 institutional records/privacy controls OPEN; keep source checklist/photo requirements OPEN until controlled source approval; keep provider/region/backup and privacy/retention dependencies OPEN until verified; implement and verify the T-14 qualifying Inspector predicate; complete T-16 technical review and T-18 command/permission closure; decide session creation and closed-session reopening; and resolve report count/delivery/closure semantics.

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

**Critical compatibility finding:** T-18 combines a prohibition on browser-facing `authenticated` table DML with a preference for SECURITY INVOKER command functions. An INVOKER function executes with caller privileges; if `authenticated` lacks protected table DML, it cannot perform protected writes. If table DML is granted to that same role, the browser may also use it directly unless a separate execution boundary is proven. This is not solved by RLS alone. The design explicitly rejects broad authenticated DML and service-role substitution. PO/security must decide between narrowly hardened SECURITY DEFINER command wrappers (candidate, not approved) and a proven separate command-executor principal. SECURITY INVOKER remains preferred for read-only paths/helpers that do not need privilege elevation.

No live Supabase role/function/ACL introspection was performed. No functions, role changes, grants/revokes, table ACL changes, RLS, migrations or runtime tests were executed. All 62 cases remain PLANNED / NOT EXECUTED.

**Updated disposition:** function security design documented; INVOKER/DML compatibility decision OPEN; role/ACL inventory OPEN; exact function signatures and grants OPEN; scope freeze NOT READY; implementation NOT AUTHORIZED.
