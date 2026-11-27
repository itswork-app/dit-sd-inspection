# Implementation Roadmap and Release Governance

**Document ID:** IRG-001  
**Version:** 1.0.10  
**Status:** CONTROLLED PLAN — STAGED FOUNDATION IMPLEMENTATION  
**Date:** 2026-11-27  
**Authority:** MIB-001, AGENTS.md, approved Decision Register and ADRs  
**Product Owner authorization:** CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED (2026-11-24)
**G10-F1 foundation implementation:** ACTIVE (2026-11-25, following PR #26) — bounded synthetic-data foundation scope only; full-system G9 NOT READY; later business-feature gates remain open

**Current gate interpretation (2026-11-27):** Historical sections 10–11 retain the pre-activation G10 NOT ACTIVE state as dated snapshots. The controlling state under AGENTS.md v1.2.5 is G9-F1 FOUNDATION SCOPE FROZEN and G10-F1 FOUNDATION IMPLEMENTATION ACTIVE for bounded foundation work only. Full-system G9, later business features and production operations remain separately gated.

## 1. Purpose

This roadmap defines the ordered path from documentation closure to production operation. It is not a blanket authorization for full-system or later business-feature implementation. The separately approved G9-F1/G10-F1 decision in `AGENTS.md` currently authorizes only the bounded synthetic-data foundation scope; this roadmap elaborates delivery and release controls for that stage and all later stages.

## 2. Mandatory execution protocol

At the start of every work session and before every substantive repository task, the implementer/agent MUST:

1. Read the current root `AGENTS.md` from the target branch and ref.
2. Read the relevant approved PRD, Decision Register entries, ADRs, MIB-001, DGA-001 and domain/security/QA specifications.
3. Identify the active branch, base branch, current HEAD and working-tree state before editing.
4. State the task scope, allowed actions, out-of-scope actions, dependencies and expected evidence.
5. Follow the source-of-truth precedence in MIB-001. If documents conflict, stop the affected work, record the conflict and request resolution; do not improvise.
6. Make the smallest coherent change, update traceability/tests/docs, and verify the exact resulting diff and repository state.
7. Report completed work separately from proposed work, and distinguish authored, reviewed, executed, passed and independently verified evidence.

For ChatGPT-assisted repository work, fetch and inspect `AGENTS.md` before making repository changes in every new work session. If it cannot be read, do not edit the repository. Re-read it after any change to `AGENTS.md` and apply the new instructions immediately.

## 3. Pre-implementation gates

### Phase 0 — Governance and repository baseline
**Purpose:** Establish controlled source-of-truth and delivery governance.

Deliverables:
- MIB-001 and DGA-001 current.
- Root AGENTS.md operational and mandatory.
- Stable branch/PR policy, CODEOWNERS/review ownership plan, issue/decision traceability.
- Document inventory and status reconciliation.
- Secrets/data handling and contribution instructions.

Exit criteria:
- Repository intent and source-of-truth precedence confirmed.
- No conflicting active decision status.
- Branch protection/required review plan documented; live GitHub settings verified before implementation.
- All DGA governance blockers closed or explicitly accepted by authorized authority.

### Phase 1 — Product and institutional closure
**Purpose:** Freeze what the product must do and who has authority.

Deliverables:
- Controlled IFP and Standing Bracket source inventories and row-by-row reconciliation.
- Approved applicability, evidence/photo-slot, annex and exception rules.
- Complete actor/role/scope and workflow requirements.
- Approved BA/report/attendance authority and institutional records/privacy/legal/retention decisions.
- Complete RTM and acceptance criteria.

Exit criteria:
- Every in-scope requirement has authoritative source and approver.
- No unresolved critical/high ambiguity affecting product behavior or lawful operation.
- Institutional decisions are evidenced by authorized written records.

### Phase 2 — Domain, data and transaction design
**Purpose:** Make the domain and persistence model executable without guessing.

Deliverables:
- Complete state machines, command preconditions/postconditions and invariants.
- Reconciled conceptual/logical/physical ERD and object inventory.
- Canonical identity, FK/composite constraints, uniqueness and lifecycle.
- Notification and print persistence decisions.
- Exact transaction, idempotency, locking, retry, outbox/compensation and external-side-effect semantics.
- Data retention, evidence lifecycle and report reproducibility.

Exit criteria:
- Every entity and database object has lifecycle, owner, constraints and retention.
- Every cross-entity invariant has a DB or command enforcement point and negative test.
- No unresolved ERD-only or physical-only object.

### Phase 3 — Security and authorization design
**Purpose:** Close the security contract before privileged code exists.

Deliverables:
- Canonical permission registry; role, scope, grantor ceiling, SoD and revocation rules.
- Table/view/function/sequence/storage object privilege matrix.
- Table-by-table RLS policies and exact grants.
- Function owner, effective privilege, SECURITY INVOKER/DEFINER, search_path and EXECUTE ACL specification.
- Threat model, abuse cases, audit/privacy controls, account recovery and device/offline threat model.
- Caller-JWT propagation contract and service-role isolation.

Exit criteria:
- Every route, command, query and storage operation has explicit actor, permission and resource scope.
- Deny-by-default behavior and negative authorization tests are specified.
- All institutional privacy/security dependencies are approved.

### Phase 4 — API, UX and integration contracts
**Purpose:** Ensure client/server/database contracts are complete and testable.

Deliverables:
- Each command/query contract with exact request/response schemas, errors, authorization, DB read/write set, transaction and audit behavior.
- Route-to-command mapping and Supabase Auth/JWT forwarding design.
- UX role journeys, accessibility, responsive, offline, retry, conflict and recovery states.
- Provider integration and failure/compensation contracts.

Exit criteria:
- 100% in-scope requirements map to API/command/query and UX behavior.
- No generic/unbounded privileged RPC or undocumented side effect.
- Contract tests and acceptance tests are mapped to every operation.

### Phase 5 — Quality and production operations design
**Purpose:** Define how readiness will be proven and operated.

Deliverables:
- Test pyramid and risk-based coverage matrix.
- Unit, integration, RLS/authorization, tenant-isolation, concurrency, E2E, accessibility, offline, performance, security and recovery suites.
- Numeric SLOs, representative workload/media profile, capacity and cost model.
- CI tiers, required checks, dependency/security scanning, migration validation and release process.
- Environment separation, secrets, backups, restore, monitoring, incident response, rollback and support runbooks.

Exit criteria:
- Every requirement has acceptance and verification evidence.
- Provider capabilities, ownership, quotas, region and recovery entitlements are confirmed.
- RPO/RTO and SLOs are approved and testable.
- Restore and incident exercises are fully specified.

### Phase 6 — Final SSOT audit and scope freeze (G9)
**Purpose:** Freeze an implementation-ready baseline.

Exit criteria:
- DGA-001 blocking items are closed with evidence or formally accepted by the correct authority.
- Cross-document audit finds no unresolved critical/high design contradiction or missing contract.
- RTM is complete from source through tests.
- Independent reviewer signs the SSOT/scope-freeze record.
- Baseline is tagged/documented as the approved implementation specification version.

### Phase 7 — Explicit implementation authorization (G10)
This is a separate decision. Scope freeze does not authorize implementation by itself.

Required authorization record:
- approved scope/version and target release;
- named implementation owner/reviewer;
- allowed repositories/branches/environments;
- permitted actions (source, migrations, tests, infrastructure);
- prohibited actions (e.g. production DB changes/deployments unless separately authorized);
- rollback and change-approval authority.

No full-system or later business-feature implementation begins before its applicable authorization record exists. The bounded G9-F1/G10-F1 foundation stage is separately ACTIVE under `AGENTS.md` §3.2; that staged authorization does not satisfy or waive later feature-entry gates.

## 4. Implementation delivery phases

The I0/I1 foundation tasks may proceed only to the extent explicitly included in the active G10-F1 scope. I2 and later phases, business command handlers, production data and operations remain gated by their own entry criteria and separate authorization. The phase list below is a roadmap, not an expansion of the active foundation authorization.

### I0 — Engineering bootstrap
- Create application scaffold only after approved stack/runtime decisions.
- Pin supported runtime and package manager; commit lockfile.
- Configure strict type/lint/format/test/build checks.
- Establish environment validation, secret boundaries, logging redaction and health checks.
- Configure preview/staging/production separation and minimal CI.
- No business features in this phase.

### I1 — Platform and identity foundation
- Supabase Auth integration and server-side session handling.
- Caller JWT forwarding; no browser service-role credential.
- Account lifecycle, role/scope model and deny-by-default baseline.
- Tenant/project isolation and private storage foundation.
- Prove negative access cases before adding workflows.

### I2 — Database foundation and privileged command runtime
- Versioned migrations with review and rollback/forward-repair strategy.
- Least-privileged function owner and exact grants.
- RLS and SECURITY DEFINER review.
- Idempotency, audit and event transaction primitives.
- Test migration from empty database and upgrade from prior schema.
- No production SQL execution without separate authorization.

### I3 — Core domain and instrument governance
- Instrument catalog, version validation/publication/deactivation.
- Canonical unit identity, project associations, serial conflict workflow.
- Project/session/location/team assignment and claims.
- Historical snapshot and immutable evidence lineage.

### I4 — Inspection execution and offline capability
- Inspection sessions and state transitions.
- Checklist execution, conditional/N/A rules and evidence upload.
- Bounded offline drafts, idempotent sync and explicit conflict resolution.
- Submission/revision immutability and review/resubmission workflow.

### I5 — Reporting, audit and notifications
- Deterministic report calculations and reproducible PDF generation.
- Print-event capture distinct from PDF open/download.
- Append-only audit and authorized audit access/export.
- INS-015 notification delivery, retries, read/delivery state, SLA/escalation and audited configuration.

### I6 — Acceptance, migration rehearsal and hardening
- Full regression, tenant isolation, privilege escalation and negative authorization tests.
- Concurrency, load, accessibility, device, offline and recovery testing.
- Database and object-storage restore drills.
- Data migration/reconciliation rehearsal if an authorized legacy source becomes available.
- UAT and operational rehearsal; no silent acceptance of unresolved defects.

### I7 — Production release and hypercare
- Signed go/no-go checklist and release approval.
- Controlled deployment, smoke tests and monitoring.
- Rollback/forward-fix plan and tested recovery contacts.
- Hypercare, incident triage, defect prioritization and post-release review.
- Release closeout only after operational acceptance and evidence archive.

## 5. Engineering workflow and quality policy

- One focused branch and PR per coherent change; avoid giant cross-domain PRs.
- PR must state requirement/decision IDs, scope, risks, migrations, security impact, test evidence, rollback and documentation impact.
- No merge with failing required checks, unresolved blocking review comments, missing migration review or undocumented behavior.
- Use small, reversible database changes. Prefer expand → migrate/backfill → verify → contract for breaking schema changes.
- Never run destructive production migrations as an implicit part of deploy.
- Separate schema migration, application deployment and data backfill when ordering matters.
- Test against a fresh database and an upgraded database.
- Enforce secret scanning, dependency review and least privilege.
- Keep observability useful but privacy-safe; redact credentials, JWTs, personal data and evidence payloads.
- CI cost optimization may reduce redundant triggers, not required security or release evidence.

## 6. Semantic Versioning policy

The application and released public interfaces use **Semantic Versioning 2.0.0**: `MAJOR.MINOR.PATCH`.

- **MAJOR:** incompatible public API, externally consumed contract, or explicitly versioned product behavior change.
- **MINOR:** backward-compatible capability addition.
- **PATCH:** backward-compatible bug fix.
- **Pre-release:** use identifiers such as `0.3.0-alpha.1`, `0.3.0-beta.1`, `1.0.0-rc.1`; build metadata may identify CI builds but does not affect precedence.
- Start at `0.y.z` while the product is pre-1.0 and public compatibility guarantees are not yet declared. `1.0.0` is reserved for the first formally accepted stable production release after G12.
- Version tags are immutable and created only from reviewed release commits. Never move or overwrite a published tag.
- Maintain a human-readable CHANGELOG with Added, Changed, Deprecated, Removed, Fixed and Security sections.
- Use conventional commit style where practical; commit messages do not replace PR review or release notes.

### 6.1 Independent version domains
### 6.2 Controlled document SemVer

Each controlled specification (PRD, ADR, architecture contract, permission registry, QA catalogue, MIB, DGA and controlled operational plan) has its own version. Document version and approval status are separate: a document at 1.x may still be a draft or proposal and does not imply approval.

- **MAJOR:** incompatible change to an approved requirement, authority boundary, public contract, security invariant or previously approved baseline; requires impact analysis and explicit supersession/approval.
- **MINOR:** backward-compatible addition or material expansion of requirements, commands, permissions, test coverage or design detail.
- **PATCH:** editorial correction, clarification or traceability/status correction that does not change approved behavior or authority.
- Pre-1.0 proposals use `0.y.z`; do not imply stability or implementation approval.
- Bump the affected document version in the same commit as its content change. Update dependent documents, RTM/DGA/RAID references and cross-document links in the same coherent change set.
- Never use a document version bump to silently approve a PO or institutional decision. Approval evidence and approver remain explicit.
- A scope-freeze baseline at G9 is separately identified by its immutable Git commit/tag and approval record; it does not retroactively make every individual draft authoritative.


Do not force every artifact to share one version number:
- **Application release:** SemVer tag, e.g. `v0.8.0` or `v1.0.0`.
- **Public API:** explicit contract versioning and compatibility/deprecation policy; breaking changes require a major version or a documented versioned route.
- **Database schema:** monotonic immutable migration identifiers (timestamp/sequence), not SemVer alone. Record the application versions compatible with each migration.
- **Documentation baseline:** versioned MIB/SSOT release, linked to approved decisions and RTM baseline.
- **Instrument configuration:** immutable business version IDs; never equate them to application SemVer.
- **Test evidence:** tied to exact commit SHA, app version, migration head, environment and test run ID.

## 7. Release checklist

A release candidate is eligible only when:
- scope and acceptance criteria are approved;
- CI required checks pass on exact commit;
- migrations are reviewed and tested from clean and upgrade paths;
- security/RLS/permission and tenant-isolation suites pass;
- functional, E2E, accessibility, offline and supported-device suites pass;
- performance meets approved SLO and workload;
- backup and restore evidence meets RPO/RTO;
- monitoring, alerting, incident and rollback procedures are ready;
- UAT and business owner acceptance are recorded;
- no unaccepted critical/high-severity blocker remains.

G12 production approval is an explicit sign-off, not an automatic result of a successful pipeline.

## 8. Current status

- G9-F1 foundation scope: **FROZEN**.
- G10-F1 foundation implementation: **ACTIVE** under AGENTS.md v1.2.5 and the governing PR #26 decision; limited to repository/app bootstrap, development configuration, CI, authentication shell, development-only database foundation/migrations, typed API boundary, observability and automated tests using synthetic data.
- Full-system G9: **NOT READY**; later business-feature entry gates remain open.
- CMD-031–040 business mutations, unresolved privileged RPCs, domain schema/RLS/grants, evidence/attendance workflows and worker/provider paths are **NOT AUTHORIZED BY G10-F1** until their feature-entry contracts and approvals are complete.
- POQ-01..03 notification product semantics: **APPROVED 2026-11-24; technical, security and institutional dependencies remain OPEN**.
- Product Owner conditional implementation authorization: **RECEIVED (2026-11-24)**; staged G9-F1/G10-F1 activation is recorded separately.
- Foundation implementation verification: **LOCALLY VERIFIED** on `feat/foundation-bootstrap-v1-rebased` (`npm ci && npm run check` PASS, 2026-11-27); hosted GitHub Actions CI remains **BLOCKED** by account billing/spending limit (Check Run `140276596713`).
- Current SSOT audit: **DGA-001 v1.18.0 — full-system gate NOT READY; G9-F1/G10-F1 foundation active**.
- Application SemVer: **not assigned yet**; no release tag exists.
- Target stable release: **v1.0.0 only after G12 acceptance**.

---


## 9. External evidence intake — 2026-11-24

EVID-EXT-001 v0.1.0 indexes the six Product Owner-supplied inspection artifacts. DGA-B01..B03 have been refined to distinguish evidence receipt and PO acceptance from institutional source/signatory/attendance authority. This is a documentation and evidence-indexing milestone only; it does not pass G1/G9, authorize merge or open G10.


## 10. Product Owner conditional implementation authorization — 2026-11-24

The Product Owner's written conditional authorization is recorded in the Decision Register and MIB-001. It authorizes transition toward implementation from zero in this repository, using the SSOT baseline; closure of G9 prerequisites; scope freeze only after critical blockers are closed; and G10 activation only after verification. After G10 activation, source code, database schema, migrations, API, frontend and automated tests may proceed on a dedicated implementation branch. Production changes, deployment and operations affecting real data require separate approval. No gate may be reported PASS without required evidence and approvals.

**Current disposition:** PO conditional authorization RECEIVED; G9 NOT READY; G10 NOT ACTIVE; I0–I7 NOT STARTED. This does not waive institutional, Security, Database, Operations or provider approvals. The root AGENTS.md remains the controlling execution boundary.


## 11. Post-PR #19 implementation-entry status — 2026-11-25

The latest controlled main baseline is `779f46c45444f7878d2128869288e986ff6b0b7a`. PRs #14–#19 merged the F05-T1..T5 candidate documentation. IER-001 v0.1.0 is the consolidated closure sequence for remaining G9 evidence.

The next work is documentation and independent evidence closure, not feature coding: complete F-04 physical writer/bypass inventory; prove F-03 lock acyclicity and certify resolver paths; close F05-T1..T5 with technical/physical approvals and T-10 institutional decisions; complete SES-001 command/SoD/atomicity/QA contracts; close source instrument authority and remaining DGA blockers; reconcile schema/RLS/functions and operational controls; then conduct independent G9 review.

**Current status:** G9 NOT READY; G10 NOT ACTIVE; I0–I7 NOT STARTED / NOT AUTHORIZED. QA remains PLANNED / NOT EXECUTED; CI/workflow evidence is ABSENT where unavailable. No implementation activity is permitted until G9 passes and a separate G10 activation record is approved. Production changes and deployment require separate authorization.

## 12. Current staged implementation status — 2026-11-25

This status index supersedes earlier roadmap status snapshots in §§3, 4, 8, 10 and 11 wherever they describe G10 as inactive or implementation as wholly unauthorized. Historical decision records and their original dates remain preserved.

- G9-F1 foundation scope: **FROZEN**.
- G10-F1 foundation implementation: **ACTIVE**, under root AGENTS.md §3.2, for the bounded foundation scope using synthetic/test data on a dedicated feature branch.
- Full-system G9: **NOT READY**. Full-system G10 and later business-feature implementation: **NOT AUTHORIZED**; applicable feature-entry gates remain open.
- PR #31 (RBAC-003 governance and reconciliation): **MERGED** to main at `44dce2cbcc052c6e909e1b0a080062a5b60d94eb`.
- PR #30 (foundation bootstrap): **OPEN / NOT MERGED**. Integrated branch head is `0537ef51bccacfa277a6eeab3ccaef4a0cd45979`; it is based on current main with zero commits behind at the reconciliation checkpoint.
- Exact-head CI run #60 completed as **failure**, but the job exposed no steps and its log artifact was unavailable. Root cause is undetermined; this is neither a quality-check PASS nor evidence of a source-level test failure.
- `package-lock.json` is absent. Repository lint, typecheck, Vitest, migration validation and production build are **NOT VERIFIED** on the exact PR head. Do not merge until authentic dependency locking and reproducible exact-head checks pass, followed by maintainer review.
- Production readiness remains **NOT VERIFIED**. No production data, hosted database mutation, deployment, business command, business schema, grants/RLS or privileged RPC is authorized by this foundation status.

**Current implementation disposition:** continue only with bounded foundation hardening and verification. Preserve all later feature-entry gates.


## 13. CI-independent foundation checkpoint — 2026-11-25

The current branch `feat/foundation-bootstrap-v1-rebased` is at `ca933fe47c4ee44cf2eba262eb80522c6075bfbf`, 103 commits ahead and zero behind main at the checkpoint. PR #30 remains open and unmerged.

GitHub Actions has not supplied a usable verification result for this latest head. The Product Owner suspects the Actions quota may be exhausted, but this was not independently verified. No rerun was performed. Static source review is permitted as engineering analysis but is not runtime evidence. `package-lock.json` remains absent; lint, typecheck, Vitest, migration checks and build remain NOT VERIFIED. Continue only with bounded foundation review and non-executing changes until a usable Node/npm environment and Actions capacity are available.


## 14. Staged foundation and feature-entry status reconciliation — 2026-11-26

This update aligns IRG-001 with root AGENTS.md v1.2.5, MIB-001 v1.0.16 and DGA-001 v1.14.2. Historical sections 10–11 retain the gate state recorded on their original dates; they are not the current authorization state.

- G9-F1 foundation scope is FROZEN; G10-F1 foundation implementation is ACTIVE following PR #26.
- G10-F1 is limited to synthetic-data foundation work. It does not activate full-system G9, later business-feature implementation or production operations.
- The CMD-035 transaction-boundary documentation update on the dedicated documentation branch is not executable business implementation and does not change the G10-F1 boundary.
- Full-system G9 remains NOT READY; no production readiness, automated verification or release approval is claimed.


## 15. Foundation verification and main integration checkpoint — 2026-11-27

Branch `feat/foundation-bootstrap-v1-rebased` (PR #30) has integrated `main` through PR #37 (`5b7fdd9`), committed a reproducible `package-lock.json`, hardened `.github/workflows/ci.yml` to run `npm ci --no-audit --no-fund` with `contents: read`, fixed the `@supabase/ssr@0.7.0` `setAll` runtime/type defect and test typing/config issues, and passed the full local quality gate (`npm ci && npm run check`: ESLint, TypeScript, migration check, 63/63 Vitest tests, 5/5 Node migration tests, Next.js 16.4.6 production build).

Hosted GitHub Actions remains blocked externally by the account billing/spending limit (GitHub Check Run `140276596713`). Maintain all later feature-entry gates: full-system G9 remains NOT READY, business mutations and production operations remain NOT AUTHORIZED, and production readiness remains NOT VERIFIED.
