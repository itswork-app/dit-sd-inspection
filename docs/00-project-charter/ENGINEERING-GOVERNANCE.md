# Engineering Governance

**Status:** Proposed baseline for approval

## 1. Delivery principles
- Production is the target; balanced priorities apply across quality, security, cost, and speed.
- Use gated delivery. A phase is complete only when its exit criteria are evidenced.
- Feature parity precedes optional enhancements.
- Prefer the simplest architecture that satisfies verified requirements.
- No production data mutation without migration, authorization, audit, and recovery plan.

## 2. Git workflow
- main is the protected, releasable branch.
- Work is performed on short-lived branches named by type and scope, e.g. docs/..., feat/..., fix/..., test/....
- Changes enter main through Pull Requests.
- PRs must include purpose, scope, linked requirement/decision, test evidence, risk, and migration/rollback notes where applicable.
- Require review and required CI checks before merge once branch protection is configured.
- Avoid direct commits to main after governance is enabled.

## 3. Definition of Ready
A work item is ready when:
- User/business behavior is defined.
- Acceptance criteria are testable.
- Dependencies and permissions are identified.
- Data and audit implications are understood.
- UX states include loading, empty, error, offline, and recovery where relevant.

## 4. Definition of Done
A work item is done when:
- Acceptance criteria pass.
- Relevant automated tests pass.
- Authorization and negative-path behavior are tested.
- Observability and audit needs are implemented.
- Documentation is updated.
- No unresolved blocker or critical defect remains.
- PR review and CI requirements pass.

## 5. Quality gates
- G0: Project foundation approved.
- G1: Product scope and PRD frozen for the release.
- G2: Architecture, security model, data model, and ADRs approved.
- G3: UX flows and acceptance criteria approved.
- G4: Engineering foundation and CI verified.
- G5: Feature-complete implementation and integration tests pass.
- G6: System, security, offline, performance, and regression testing pass.
- G7: UAT, operational readiness, backup/restore, and release approval complete.

## 6. CI cost control
- Pull request: formatting/lint, type/static checks, focused unit tests, changed-module tests, secret scanning where available.
- Main integration: full unit and integration suite, migration validation, build.
- Scheduled or release candidate: broader end-to-end, security, dependency, and performance checks.
- Avoid duplicate expensive jobs for unchanged scopes unless risk requires them.
- A skipped job must be visibly reported as skipped, not treated as a passing test.
- Exact CI provider, quotas, branch protection settings, and required checks remain open until stack selection.

## 7. Security and data integrity
- Enforce access on server/API and database layers; never rely only on UI visibility.
- Scope all operational access to explicit assignments.
- Preserve immutable submitted versions and append-only audit events.
- Store versioned configuration references/snapshots with inspection records.
- Use least privilege, secret management, private evidence storage, and tested backup/restore.
- Offline sync must be idempotent and conflict-aware; never silently overwrite competing work.

## 8. Release and incident control
- Maintain separate development, staging, and production environments where supported.
- Production release requires approved migrations, rollback/recovery plan, monitoring, and UAT sign-off.
- Record incidents, severity, impact, mitigation, root cause, and corrective actions.
- No release with unresolved critical security or data-integrity findings.
