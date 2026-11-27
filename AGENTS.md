# Repository Agent Instructions — Dit. SD Inspection

**Document ID:** ENG-AGENT-001  
**Version:** 1.3.0  
**Status:** MANDATORY ENGINEERING POLICY  
**Applies to:** Every human contributor, coding agent, reviewer and automation working in this repository.

## 1. Mandatory read-before-work rule

**MUST READ THIS FILE FIRST.** Before every new work session and before every substantive task, read the current root `AGENTS.md` from the target branch/ref. Do not rely on memory, a prior chat summary, a cached copy or assumptions. If the file cannot be read, STOP repository edits and report the blocker.

After reading this file:
1. Read the relevant approved PRD, Decision Register, ADRs, Master Implementation Blueprint (MIB-001), Documentation Gap Audit (DGA-001), and domain/security/QA documents for the task.
2. Confirm repository, branch, base ref, HEAD and current diff before editing.
3. State scope, allowed/prohibited actions, dependencies, risks and expected evidence.
4. If this file changes during the task, re-read it and apply the new rules immediately.
5. Before finishing, verify the exact diff, links, traceability, tests and resulting repository state.

For ChatGPT-assisted work, the assistant must fetch and inspect this root `AGENTS.md` at the beginning of every new repository work session before any repository mutation. This instruction is persistent for future sessions; it is not satisfied by reading it once in an earlier conversation.

## 2. Source of truth and decision authority

1. Approved Product Owner decisions in the Decision Register and linked records govern product behavior within PO authority.
2. Institutional legal, records, privacy, security, finance and operational approvals govern matters reserved to those authorities; PO approval cannot replace them.
3. Approved PRD and controlled source instruments govern product scope and inspection content.
4. Approved ADRs govern technical decisions.
5. MIB-001 defines governance and gate authority; DGA-001 is the active gap-closure queue; IRG-001 defines the implementation/release roadmap.
6. Detailed domain, API, data, security, UX and QA specifications must conform to higher-authority sources.
7. Drafts, examples, inferred rules and unapproved proposals are not authoritative.

If two authoritative sources conflict, do not guess or implement around the conflict. Record it, identify impact and request a decision. Preserve historical decision records; supersede through explicit change control.

## 3. Current phase and hard authorization boundary

Current phase: **G10 FULL-SYSTEM SYNTHETIC IMPLEMENTATION ACTIVE (G9-TECH FROZEN — 2026-11-27)**.

- Foundation scope freeze: **G9-F1 FROZEN** (`G10-F1` foundation runtime locally verified 2026-11-27).
- Full-system Technical SSOT freeze: **G9-TECH FROZEN (2026-11-27)** — 14/14 technical DGA blockers (`B07`, `B09..B14`, `B16..B22`) closed across v1.0.0 baseline (`62` canonical tables / `62/62` RLS parity / `52` application commands `CMD-001..044`, `CMD-049..056`; `CMD-045..048` excluded external control plane).
- Product Owner authorization: **G9-TECH FREEZE & G10 FULL-SYSTEM SYNTHETIC IMPLEMENTATION ACTIVATED (2026-11-27; PO/sole maintainer explicit sign-off)**.
- Production / real institutional data readiness (`G12`): **NOT VERIFIED / BLOCKED** on external institutional/provider/operational items (`DGA-B01..B06`, `B08`, `B15`).

G10 Full-System Synthetic Implementation permits ordered implementation of phases `I1 → I5` on dedicated feature branches using **synthetic/test data in isolated local/development environments**: versioned local Supabase SQL migrations, `T-18` least-privileged `NOLOGIN` function owners (`app_cmd_definer`/`app_worker_definer`), RLS policies, canonical `CMD-001..043` / `CMD-049..052` / `CMD-054..056` wrappers, typed Next.js API routes, UI workflows, and automated unit/integration/RLS/concurrency tests.

Still STRICTLY PROHIBITED under G10 Synthetic Implementation:
- production data/evidence collection or processing real institutional personal data in development;
- production/staging deployment, live hosted database mutation without explicit authorization, irreversible retention/deletion or legal-hold disposition;
- enabling `CMD-044` (`export-audit`) or external notification provider dispatch adapters (`CMD-053` email/push / `INT-NOTIF-001`) before written `T-10` and `T-12` approvals;
- creating any application surface for PO-excluded external control-plane IDs `CMD-045..048`;
- handling or requesting secrets in chat, or committing `.env` / credentials;
- bypassing branch protection or repository rules, or reporting unexecuted tests as PASS.

The documentation-only merge exception GOV-MERGE-001 remains a separate, narrow merge policy for documentation-only PRs; it is not the authorization source for G10-F1. Full-system G9 and later feature gates remain open.

### 3.1 Product Owner conditional authorization received — 2026-11-24

The Product Owner supplied explicit written authorization to transition toward implementation from zero in this repository, using the current SSOT as the build baseline. The authorization directs the team to close G9 prerequisites, freeze scope only after critical blockers are closed, and activate G10 only after verification. After G10 activation, implementation may proceed on a dedicated branch for source code, database schema, migrations, API, frontend and automated testing. Production changes, deployment and operations affecting real data require separate approval. No gate may be marked PASS without required evidence and approvals.

This paragraph records the original conditional authorization and is superseded for the bounded foundation scope by §3.2. Full-system G9/G10 and feature-entry gates remain applicable. Canonical PO approval record: `docs/00-project-charter/DECISION-REGISTER.md`.

## 4. Architecture and security invariants

- Platform baseline: Vercel + Supabase PostgreSQL/Auth/RLS/Storage + GitHub.
- PostgreSQL is the single source of truth for application data.
- Prefer modular monolith; do not introduce microservices without measured justification and approved ADR.
- Enforce authorization at server/database boundaries; UI visibility is never authorization.
- Preserve caller JWT and derive actor identity from trusted auth context; never trust client actor/role/scope.
- Do not use service-role credentials as a substitute for caller identity or expose them to browsers.
- Protected writes follow approved T-18 hybrid execution model; each privileged function needs individual owner/privilege/search_path/EXECUTE/RLS review.
- Default deny. Exact grants, role/scope checks, SoD, account state and resource state must be explicit.
- Critical business mutation, canonical event, audit and idempotency outcome must be atomic; audit failure fails closed.
- Preserve immutable submitted revisions, original evidence and published instrument versions.
- Evidence storage is private; authorized access is time-limited and audited.
- Offline synchronization is bounded, idempotent and conflict-aware; never silently overwrite.
- No secrets, tokens, sensitive personal data or evidence payloads in commits/logs.

## 5. Documentation and traceability requirements

For every requirement or behavior change:
- use stable requirement/decision/ADR/command/API/test IDs;
- identify authoritative source, approval state and owner;
- map requirement → workflow/state → entity/invariant → command/API → permission/security control → acceptance criterion → test/evidence → gate;
- update all impacted documents and DGA/RTM/RAID status;
- record unresolved dependencies explicitly;
- distinguish approved, proposed, open, blocked, implemented, tested and verified.

A document edit does not prove implementation. A planned test does not prove a test passed. Never report an item closed without closure evidence.

### 5.1 Current approved notification product decisions (2026-11-24)

The following POQ-001 decisions are approved in the canonical Decision Register and must be treated as fixed product semantics unless superseded through explicit change control:

- **POQ-01 — Option C, hybrid recipient eligibility:** persist the event-time candidate audience and authorized source scope/checkpoint. Fan-out and retries reuse that immutable candidate set. Dispatch-time account, channel, consent/revocation and mandatory security revalidation may suppress candidates but must never widen the audience.
- **POQ-02 — Option C, per-policy SLA:** each immutable policy version declares elapsed-time or explicitly defined business-time semantics. Initial-release default is `ELAPSED_UTC`. Quiet hours defer eligible channel delivery only; they do not pause, stop or reset the SLA clock.
- **POQ-03 — Option A, dismissal excluded from MVP:** expose recipient-owned set-once `read_at` only. No dismiss/archive command, permission, browser write or UX action is in MVP. Any proposed `dismissed_at` field is dormant and must not be exposed or mutated.

These approvals close Product Owner semantics only. They do not approve the durable snapshot/checkpoint schema, selector grammar, worker identity/ACL, provider callbacks, policy administration grants/SoD, T-10 privacy/retention, physical schema/RLS, tests, G9 scope freeze or G10 implementation authorization. NLA-001, CMD contracts, schema, RLS, API, RTM and QA must remain synchronized to these decisions. Current notification QA cases TC-NOTIF-001..029 are planned and NOT EXECUTED.

## 6. Implementation workflow (within the activated stage)

Follow IRG-001 phases I0–I7 in order. G10-F1 authorizes only the bounded foundation stage. Do not start later business features until their individual entry gates are closed. Do not skip platform, identity, database or security foundations to start visible features. Each phase has explicit entry/exit criteria.

- Use short-lived focused branches and pull requests.
- PR description must include requirement/decision IDs, behavior, design, threat/security impact, migration impact, test results, rollback and docs updated.
- Require review and passing required checks before merge.
- Database migrations are immutable, ordered, reviewed and tested from both clean and upgraded states.
- Use expand → migrate/backfill → verify → contract for breaking schema evolution.
- Do not couple destructive migration or production data changes implicitly to deployment.
- Keep staging/production isolated and secrets server-only.
- Optimize CI minutes by avoiding duplicate triggers, not by dropping required security or release checks.

## 7. SemVer and version governance

Follow IRG-001 §6 and Semantic Versioning 2.0.0:
- Application release versions: MAJOR.MINOR.PATCH; pre-1.0 use 0.y.z and pre-release labels.
- First stable production release is v1.0.0 only after G12 acceptance.
- MAJOR = incompatible public contract; MINOR = backward-compatible feature; PATCH = backward-compatible fix.
- Immutable release tags and maintained CHANGELOG.
- Database migrations use immutable monotonic identifiers and compatibility notes, not app SemVer alone.
- Controlled documents follow IRG-001 §6.2 with independent document SemVer; bump the affected document in the same commit, keep approval status separate from version, and synchronize impacted RTM/DGA/RAID/SSOT references.
- API contracts, documentation baselines, instrument versions and test evidence have separate version/identity domains.

Do not invent or tag an application version before an actual release artifact exists.

## 8. Quality and production standards

Required verification is risk-based and includes as applicable:
- unit, integration, contract and end-to-end tests;
- RLS, role/scope, tenant isolation, privilege escalation and negative authorization;
- idempotency, concurrency, audit atomicity and data integrity;
- accessibility, supported devices, responsive, offline and recovery;
- performance against approved numeric SLO/workload;
- backup/restore and rollback drills;
- dependency/security scanning, secret scanning and migration validation;
- UAT and operational acceptance.

Production readiness requires evidence on the exact release commit, schema migration head and environment. CI green alone is insufficient.

## 9. Cost, reliability and maintainability

- Choose the lowest total lifecycle cost that satisfies security, privacy, integrity, reliability and support requirements.
- Start on the smallest suitable provider plan; measure real usage before scaling.
- Track DB/storage/egress/compute/backups/email/Vercel/GitHub Actions consumption.
- Keep logs privacy-safe, structured and actionable.
- Do not reduce backup, security, recovery, audit or test integrity to save cost.

## 10. Reporting contract

Every work report must state:
- branch and exact HEAD/commit;
- files changed;
- decisions made versus decisions still required;
- checks actually executed and their results;
- evidence not available or not executed;
- open blockers and next gate;
- whether any action was outside the authorized scope (must be none).

Never claim “100% ready”, “production-grade”, “passed” or “verified” without objective, reproducible evidence.

## 11. Governing references

- `README.md`
- `docs/00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md` (MIB-001)
- `docs/00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md` (DGA-001)
- `docs/00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md` (IRG-001)
- `docs/00-project-charter/DECISION-REGISTER.md`
- `docs/00-project-charter/PRODUCT-OWNER-OPEN-DECISION-PACKET.md` (POQ-001)
- Approved PRD, ADRs, RTM, RAID and detailed architecture/security/QA documents.

---


## 12. Documentation-only merge exception — GOV-MERGE-001 (2026-11-25)

The Product Owner approved a narrow exception for documentation-only PRs to merge to the default branch before G10, subject to `docs/00-project-charter/GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md`. Every PR requires a complete diff audit, recorded maintainer self-review attestation where the solo-maintainer exception applies (not an independent GitHub approval), available checks with absent checks reported as ABSENT, no branch-protection bypass, and post-merge verification. This exception does not automatically approve a PR and does not activate G10, mark G9 ready, freeze scope, authorize implementation or establish production readiness. Source code, scripts, SQL, migrations, schema, grants/RLS, provider changes, deployment, release, secrets and data mutation remain outside this exception.


## 3.2 Product Owner clarification — institutional responsibility and staged implementation (2026-11-25)

The Product Owner explicitly states that institutional authorization, coordination and compliance are the Product Owner's responsibility and are not to be treated as a separate institutional-approval prerequisite for beginning engineering work. Do not repeatedly request institutional approval artifacts from the Product Owner as a condition for the bounded development scope below. This is an allocation of project responsibility; it is not a claim that an external institution has issued a written approval.

To keep development safe while that responsibility is managed by the Product Owner:
- Engineering may proceed with synthetic/test data in isolated development environments.
- Do not import, collect, expose or process real institutional personal data or inspection evidence in development until the Product Owner has completed any applicable institutional arrangements.
- Do not enable irreversible retention/deletion, legal-hold disposition, production evidence collection, or production deployment from this decision.
- Production data, provider ownership, operational custody and go-live remain subject to the Product Owner's separate operational authorization and applicable obligations.

### Staged gate decision

A bounded foundation scope freeze is recorded as G9-F1 FOUNDATION SCOPE FROZEN. It covers repository/app bootstrap, development configuration, CI, authentication shell, database foundation/migration framework, typed API boundary, observability baseline and automated tests using synthetic data only. It expressly excludes production data, production deployment, and business command handlers whose contracts or lock/security protocols remain unresolved.

G10-F1 FOUNDATION IMPLEMENTATION: ACTIVE upon merge of the PR carrying this decision. Source code, development-only schema/migrations, CI and tests for the bounded foundation scope may be created on a dedicated feature branch. This staged activation supersedes the prior blanket prohibition only for G10-F1. It does not declare full-system G9 complete, does not activate all business features, and does not authorize production operations.

F-03/F-04, command-level authorization, notification worker/provider security, physical RLS/grants, institutional source/evidence details and other unresolved domain work remain explicit feature-entry gates. A feature must not be coded as an executable business mutation until its command contract, authorization, transaction/lock behavior and acceptance tests are sufficiently resolved. Unresolved features may be scaffolded only as non-operational placeholders where needed by the foundation.

### Solo-maintainer review model

The Product Owner is the sole maintainer and accountable engineering decision owner for this repository. Independent reviewer availability is not a prerequisite for development. Each PR must still receive documented maintainer self-review, full-diff inspection, automated checks where configured, and post-merge verification. Self-review cannot turn unexecuted tests or unverified runtime behavior into PASS.

Root policy version: 1.3.0. Section 3 and §3.3 below are the controlling authorization for G9-TECH / G10 full-system synthetic-data implementation.

## 3.3 Product Owner sign-off — G9-TECH Freeze and G10 Full-System Synthetic Implementation (2026-11-27)

On 2026-11-27, the Product Owner / sole repository maintainer explicitly approved:
1. **G9-TECH FREEZE:** Freezing the Full-System Technical SSOT baseline (`DGA-001` v2.0.0, `SSOT-AUDIT-001` v1.0.0, `Physical Schema` v1.0.0 [62 tables], `RLS Catalogue` v1.0.0 [62/62], `Command Catalogue` v1.0.0 [52 application commands], `Permission Registry` v1.0.0, `Function Security` v1.0.0, `CONCURRENCY-001` v1.0.0, `LOCK-PROTOCOL-DECISION-RESOLUTION-001` v1.0.0, `LOCK-GRAPH-001` v1.0.0, `LOCK-MANIFEST-001` v1.0.0, `NLA-001` v1.0.0, `OFFLINE-SYNC-AND-RECOVERY.md` v1.0.0).
2. **G10 FULL-SYSTEM SYNTHETIC IMPLEMENTATION ACTIVE:** Authorizing ordered implementation of `IRG-001` phases `I1 → I5` on dedicated feature branches using synthetic/test data in isolated local/development environments (beginning with `I1/I2` Identity, RBAC-003, Audit, Idempotency & `CMD-001..007`).

All production/real-data/external gates (`DGA-B01..B06`, `B08`, `B15`, `T-10`, `T-12`, `CMD-044`, external `CMD-053` providers, and `G12`) remain strictly enforced. Every implemented slice must prove clean local PostgreSQL migration, RLS negative tests, SoD/CAS/idempotency tests, and `npm run check` PASS before progressing.
