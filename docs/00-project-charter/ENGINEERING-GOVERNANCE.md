# Engineering Governance

Status: Proposed baseline for approval

## Delivery principles
- Production is the release target; cost-first is the engineering priority.
- Choose the lowest total-cost option that satisfies required security, privacy, integrity, reliability, and maintainability.
- Deliver through gated phases; a phase is complete only with evidence.
- Feature parity precedes optional enhancements.
- Keep architecture as simple as requirements permit.

## Git workflow
- main is the stable integration/release branch.
- Use short-lived branches named by type and scope: docs/, feat/, fix/, test/.
- Changes enter main through Pull Requests.
- PRs include purpose, requirement/decision link, test evidence, risk, and migration/rollback notes where applicable.
- Configure required reviews and CI checks before production development scales.

## Definition of Ready
- Business behavior and permissions are defined.
- Acceptance criteria are testable.
- Dependencies and data/audit implications are understood.
- UX includes loading, empty, error, offline, and recovery states where relevant.

## Definition of Done
- Acceptance criteria pass.
- Relevant automated tests pass.
- Negative authorization and data-scope behavior are tested.
- Audit and observability needs are addressed.
- Documentation is updated.
- No unresolved blocker or critical defect remains.
- PR review and required CI checks pass.

## Quality gates
- G0: Project foundation approved.
- G1: Product scope and PRD frozen.
- G2: Architecture, security, data model, and ADRs approved.
- G3: UX flows and acceptance criteria approved.
- G4: Engineering foundation and CI verified.
- G5: Feature implementation and integration tests pass.
- G6: System, security, offline, performance, and regression tests pass.
- G7: UAT, operational readiness, backup/restore, and release approval complete.

## Cost governance
- Prefer free/open-source tools where operationally sound.
- Evaluate total cost: hosting, database, object storage, egress, email, monitoring, backups, CI minutes, support, and engineering maintenance.
- Establish budget alerts and usage limits where providers support them.
- CI pull-request workflow should run only relevant fast checks; broader suites run on main, scheduled, or release-candidate events.
- Avoid duplicate workflow triggers and unnecessary matrix expansion.
- Never treat a skipped check as a pass.
- Do not remove security scanning, backup validation, access control, or data-integrity tests solely to reduce spend; instead right-size frequency and tooling.
- Document free-tier quotas and the cost/behavior when quotas are exceeded before production approval.

## Security and data integrity
- Enforce access at API/server and database layers.
- Scope operational access to explicit assignments.
- Preserve immutable submitted versions and append-only audit events.
- Snapshot configuration versions used by inspections.
- Use least privilege, managed secrets, private evidence storage, and tested backup/restore.
- Offline sync must be idempotent and conflict-aware.

## Release and operations
- Use separate development, staging, and production environments where practical and cost-effective; document any approved consolidation and its risks.
- Production release requires migration and rollback/recovery plan, monitoring, and UAT sign-off.
- Record incidents, severity, impact, mitigation, root cause, and corrective actions.
