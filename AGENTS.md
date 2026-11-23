# Engineering Instructions

## Source of truth
1. Approved PRD and Decision Register are the product source of truth.
2. Approved ADRs are the technical source of truth.
3. Record ambiguity; do not invent business rules.
4. Change approved decisions only through documented change control.

## Delivery
- Production is the release target; cost-first engineering priority applies.
- Approved platform baseline: Supabase + Vercel + GitHub.
- Prefer the lowest total-cost implementation that meets security, integrity, reliability, and maintainability requirements.
- Do not begin feature implementation before product and architecture gates pass.
- Keep main stable; use short-lived branches and pull requests.

## Engineering
- Prefer a modular monolith unless measured requirements justify otherwise.
- Supabase PostgreSQL is the single source of truth for application data.
- Enforce authorization with server-side checks and Supabase RLS; UI hiding is not authorization.
- Use versioned database migrations.
- Preserve audit history and historical configuration snapshots.
- Submitted inspection versions and original evidence are immutable; corrections create new versions.
- Offline sync must be idempotent and conflict-aware; never silently overwrite competing work.
- Keep evidence storage private and issue time-limited access only after authorization.
- Never commit secrets or log tokens/sensitive evidence.

## Cost controls
- Start with the lowest suitable plan and monitor actual usage.
- Review database size, storage, egress, compute, backups, email, Vercel usage, and GitHub Actions minutes.
- Use tiered CI: fast relevant checks on pull requests; broader suites on integration/release events.
- Avoid duplicate jobs and unnecessary workflow triggers.
- Do not reduce security, backup, evidence integrity, or recovery controls merely to save cost.

## Quality and honesty
- Add appropriate unit, integration, end-to-end, authorization, and scope-isolation tests.
- Include mobile, accessibility, low-connectivity, and recovery states.
- Do not claim completion without verification; report blockers and deferred decisions explicitly.
