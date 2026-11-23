# Engineering Instructions

## Authority and source of truth
1. Approved PRD and Decision Register are the product source of truth.
2. Approved Architecture Decision Records (ADRs) are the technical source of truth.
3. If a requirement is unclear, record the gap and ask for a decision. Do not silently invent product behavior.
4. Do not change an approved decision without a documented, reviewed change.

## Delivery rules
- Production is the release target. Balanced engineering priorities apply.
- Deliver in gated phases; do not begin feature implementation before product scope and architecture gates pass.
- Every feature must have acceptance criteria, tests, and traceable evidence.
- Keep main stable. Use short-lived feature branches and pull requests.
- Do not merge with failing required checks, unresolved critical/high security findings, or known data-integrity regressions.

## Engineering rules
- Prefer a modular monolith unless measured requirements justify another architecture.
- Use schema migrations for database changes; never make undocumented manual production schema edits.
- Enforce authorization on the server and data layer; UI hiding is not authorization.
- Preserve audit history and historical configuration snapshots.
- Submitted inspection versions and original evidence are immutable; corrections create new versions.
- Design offline synchronization for retries, idempotency, and explicit conflict resolution.
- Never log secrets, access tokens, or sensitive evidence content.
- Keep secrets out of Git; use environment-specific secret management.

## Quality rules
- Add unit, integration, and end-to-end tests at appropriate boundaries.
- Include negative authorization tests and session/location scope tests.
- Validate accessibility, mobile usability, and low-connectivity workflows.
- CI should be economical: run fast relevant checks on pull requests and broader suites on protected integration/release events.
- A skipped job must be visibly reported as skipped, not treated as a passing test.
- Document operational procedures, backup/restore, monitoring, and incident response before production release.

## Working agreement
- Do not claim a task is complete without verifying its output.
- Report blockers, assumptions, risks, and deferred decisions explicitly.
- Never fabricate test results, repository state, deployment status, or approvals.
