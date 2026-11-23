# Production Environment, Secrets and Provider Governance

**Status:** Production operations design draft — sponsor and security approval required  
**Version:** 0.1.0  
**Package:** Q  
**Date:** 2026-11-23

## 1. Objective

Define a reproducible, cost-first production operating model for the approved Supabase + Vercel + GitHub stack. This document does not select a paid plan, assert current provider quotas, or approve a region. Those facts must be verified against the actual organization account and current provider terms before launch.

## 2. Environment topology

Minimum environment separation:
- **Local:** developer workstation; synthetic or anonymized fixtures only.
- **Preview/CI:** isolated Supabase project or safe test database; no production data or production secrets.
- **Staging/UAT:** separate Supabase project and Vercel environment; controlled test accounts and representative non-production evidence.
- **Production:** dedicated Supabase project and Vercel production deployment; restricted maintainers and approved operational access.

Do not point preview deployments at production Supabase by default. A preview must not inherit production secrets. If a separate Supabase project is temporarily unaffordable, the alternative must be a documented, reviewed isolation design; separate schemas alone are not assumed to provide adequate isolation.

## 3. Approved service responsibilities

| Service | Responsibility | Prohibited use |
|---|---|---|
| Supabase Auth | Google sign-in identity and session | Treating user-editable metadata as role/scope authority |
| Supabase PostgreSQL | Sole system of record, constraints, RLS, command transactions | Secondary database or unreviewed privileged data writes |
| Supabase Storage | Private inspection evidence and official document objects | Public evidence bucket or unscoped permanent public URLs |
| Vercel | PWA/web hosting and server-side command/API routes | Storing data as an alternative system of record |
| GitHub | Source control, reviewed PRs, CI, migration/document history | Public repository or committing production secrets |

No Firebase backend, Redis, VPS, microservices, or additional paid infrastructure is introduced without a documented need, ADR, security/cost assessment, and approval.

## 4. Region and data residency

The production region is an OPEN decision. Before selection:
1. Obtain institutional data-residency and procurement requirements.
2. Confirm Supabase database and Storage region availability and actual location.
3. Confirm Vercel function/runtime region and data processing locations relevant to server routes.
4. Review cross-region transfer, backup, support, logs, and subprocessors.
5. Document latency to the two field locations and provider service dependencies.
6. Obtain institutional privacy/legal approval.

Do not assume that choosing an Indonesian or nearby region is sufficient legal compliance. Do not deploy production data until the authorized sponsor signs the region and data-transfer decision.

## 5. Provider plan and quota verification

Create a signed-off capacity sheet from the actual organization accounts. Verify:
- Supabase database compute, storage, connection limits, Auth MAU/OTP/social-provider limits, Storage capacity, file limits, egress, backup/PITR, log retention, support entitlement, and overage/suspension behavior.
- Vercel build minutes, function execution/time/memory, bandwidth/transfer, request limits, deployment retention, environment-variable limits, region availability, and plan restrictions.
- GitHub Actions minutes, concurrency, artifact retention, cache limits, private repository restrictions, and billing alerts.
- Google OAuth consent/scope configuration, quota and account restrictions where applicable.

For each quota record: provider, plan, metric, included allowance, hard limit, overage price/behavior, observed baseline, projected peak, alert threshold, owner, verification date, and official source/contract reference.

No numerical provider quota or price is asserted by this document. Re-check immediately before procurement and go-live because plans and terms change.

## 6. Cost governance

- Cost-first means remove waste, not security controls.
- Keep CI selective by path and trigger, but required security/data-integrity checks cannot be skipped to save minutes.
- Use private image previews and bounded pagination to reduce egress.
- Set upload quotas and evidence limits only after legibility and institutional record requirements are confirmed.
- Avoid unnecessary background jobs, polling, duplicate workflows, and unbounded PDF generation.
- Alert before quotas are exhausted; establish owner and action for each threshold.
- Define an approved monthly budget and escalation ceiling before production.
- Define a no-surprise billing owner and payment method; do not rely on a developer's personal account as an undocumented production dependency.
- Review cost weekly during pilot and monthly after stable operation.

Cost model categories:
1. Supabase compute/database.
2. Database storage and backup/PITR.
3. Storage object capacity.
4. Storage egress and signed download traffic.
5. Auth usage and provider limits.
6. Vercel hosting, functions, bandwidth, and build.
7. GitHub Actions and artifact retention.
8. Monitoring/logging, if separately charged.
9. Domain/DNS and institutional procurement overhead.

## 7. Secret inventory and handling

Maintain a secret inventory containing only metadata:
- secret name/key identifier;
- service and environment;
- purpose and consumers;
- owner role;
- creation/last-rotation date;
- expiry/review date;
- rotation/revocation procedure.

Secret classes:
- Supabase publishable/anon key (client-exposed by design, protected by RLS and grants);
- Supabase service-role/secret key (server-only, never client);
- Supabase database credentials (restricted server/operations only);
- Google OAuth client secret (server/provider configuration only);
- Vercel deployment tokens (restricted CI/maintainer only);
- signing/encryption keys (server-side only, if introduced).

Rules:
- Never commit secrets to Git, issues, PRs, logs, screenshots, test fixtures, or documentation.
- Never bundle service-role/database/OAuth secrets into PWA JavaScript.
- Use separate keys per environment.
- Limit access to least privilege and require MFA for provider accounts.
- Rotate after suspected exposure, staff departure, or provider incident.
- Keep recovery path for key rotation and dependent service restart.
- Scan repository history and build artifacts for accidental secrets before release.
- Do not paste secret values into ChatGPT or project docs.

## 8. Identity, access, and account governance

- Provider organization ownership must be institutional, not tied to a single personal account.
- Require MFA for GitHub, Supabase, Vercel, and Google identity administration.
- Maintain at least two authorized provider owners/recovery contacts; names and authorization must be confirmed.
- Separate routine developer access from production administration.
- Grant temporary production access with ticket/reason and expiry where supported.
- Review provider members and tokens quarterly and after personnel changes.
- Revoke access promptly after role termination.
- Keep a break-glass procedure with approval, alerting, and post-use review.
- Never share a common administrator login.

## 9. CI/CD and release controls

- Protect `main`; require PR review and required CI checks.
- Production deployment occurs only from approved main/release commit.
- Preview deployments use non-production credentials and data.
- Build artifacts must not contain secrets.
- Migration changes are reviewed separately from application code and tested on staging.
- Use expand/contract migrations for changes that need zero/low downtime; destructive schema changes require verified backup and rollback/forward-fix plan.
- Record deployed commit SHA, migration version, environment, deployment time, actor, and health-check result.
- Keep last known-good deployment and documented rollback procedure.
- Do not assume application rollback reverses database migrations.
- Production hotfixes still require review and post-incident reconciliation.

## 10. Monitoring, alerts, and operational ownership

Monitor:
- database availability, CPU, connections, storage, slow queries, and failed transactions;
- Auth failures and abnormal account/role changes;
- Storage usage, upload failures, checksum mismatches, missing objects, egress;
- Vercel errors, function latency/timeouts, deployment failures, bandwidth;
- CI minutes and repeated failing workflows;
- quota/billing thresholds;
- backup completion and restore-drill status;
- audit/security events and unusual access patterns.

Every alert must have severity, threshold, recipient role, response window, and escalation action. Exact numeric thresholds and tools remain open until provider plans and baseline measurements are known.

## 11. Incident response

Minimum process:
1. Detect and classify incident (availability, integrity, privacy/security, billing/quota).
2. Assign incident commander and technical lead.
3. Contain access or writes where needed without destroying evidence.
4. Preserve relevant logs and event IDs; do not copy tokens or sensitive data into incident notes.
5. Notify institutional security/privacy/records owners under approved timelines.
6. Restore service or data using Package P runbook.
7. Rotate credentials if exposure is suspected.
8. Validate RLS, data integrity, evidence references, and reports before reopening.
9. Record root cause, impact, decisions, and corrective actions.
10. Review whether external or regulatory notification is required with authorized institutional officers.

## 12. Production go-live checklist

- [ ] Institutional provider account owners and billing owner assigned.
- [ ] Supabase/Vercel/GitHub plans and quotas verified from current account evidence.
- [ ] Region and data residency approved.
- [ ] Separate staging and production projects/environments.
- [ ] MFA and least-privilege provider membership.
- [ ] Secret inventory and rotation/recovery runbook.
- [ ] Production service-role key is server-only and absent from browser bundles.
- [ ] Private Storage and RLS tests passed.
- [ ] Backup/PITR and Storage recovery verified; restore drill passed.
- [ ] Monitoring, alert recipients, incident owner, and support process active.
- [ ] Budget and quota alerts approved.
- [ ] Deployment and migration rollback/forward-fix process tested.
- [ ] UAT and operational acceptance completed.

## 13. Open approvals

1. Institutional owner, billing owner, and two provider recovery contacts.
2. Supabase and Vercel plan selection and monthly budget ceiling.
3. Production region and data residency.
4. Exact quota sheet and alert thresholds.
5. Monitoring tool and support hours.
6. Incident response and notification responsibility.
7. Whether separate Supabase staging project is funded before implementation/UAT.
8. Secret rotation cadence and break-glass approvers.

**Provider plan:** NOT SELECTED/VERIFIED.  
**Production region:** OPEN.  
**Quota/billing sheet:** NOT COMPLETED.  
**Provider organization ownership:** NOT CONFIRMED.  
**Production environment:** NOT CONFIGURED.  
**Go-live authorization:** NOT GRANTED.
