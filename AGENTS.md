# Engineering Instructions

## Source of truth
1. Approved PRD and Decision Register are the product source of truth.
2. Approved ADRs are the technical source of truth.
3. Record ambiguity; do not invent business rules.
4. Change approved decisions only through documented change control.

## Delivery
- Production is the release target; cost-first engineering priority applies.
- Prefer the lowest total-cost solution that meets security, data integrity, reliability, and maintainability requirements.
- Do not begin feature implementation before product and architecture gates pass.
- Every work item needs testable acceptance criteria and traceable evidence.
- Keep main stable; use short-lived branches and pull requests.

## Engineering
- Prefer a modular monolith unless measured requirements justify otherwise.
- Use versioned database migrations.
- Enforce authorization on server and data layers; UI hiding is not authorization.
- Preserve audit history and historical configuration snapshots.
- Submitted inspection versions and original evidence are immutable; corrections create new versions.
- Offline sync must be idempotent and conflict-aware; never silently overwrite competing work.
- Never commit secrets or log tokens/sensitive evidence.

## Cost controls
- Avoid paid services until a requirement demonstrates their necessity.
- Prefer managed/free-tier services only after checking quotas, backup, security, data residency, and production limits.
- Use tiered CI: fast relevant checks on pull requests; broader suites on integration/release events.
- Avoid duplicate jobs and unnecessary workflow triggers.
- Track recurring infrastructure, storage, bandwidth, email, monitoring, and CI costs before production approval.
- Do not reduce backup, access control, evidence integrity, or recovery controls merely to save cost.

## Quality and honesty
- Add appropriate unit, integration, end-to-end, authorization, and scope-isolation tests.
- Include mobile, accessibility, low-connectivity, and recovery states.
- Do not claim completion without verification; report blockers and deferred decisions explicitly.
