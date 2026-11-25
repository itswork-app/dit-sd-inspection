# Performance and Operations Baseline — Dit. SD Inspection

Status: Draft — numeric SLOs require baseline testing and approval  
Version: 0.1.0

## 1. Capacity definitions

These are separate requirements:

- **Inspector account capacity:** configurable from 1 to 100 distinct Inspector users across both locations combined; default value 50.
- **Concurrent application usage:** design and load-test target up to 100 authenticated users actively using the application at the same time.
- **Evidence workload:** concurrent photo uploads are a separate workload dimension and must be included in a representative test profile.

Passing the account-capacity test does not prove concurrent performance. Passing a 100-user load test does not prove storage upload capacity unless uploads are included.

## 2. Performance design principles

- Paginate all potentially large lists; never load an entire project history into the browser.
- Index foreign keys, scope filters, normalized serial lookup, lifecycle status, and common date/report dimensions based on query plans.
- Avoid N+1 queries; use bounded joins/aggregations and server-side pagination.
- Keep dashboards on bounded, indexed queries. Add materialized/summary tables only if profiling proves they are needed and refresh semantics are approved.
- Use thumbnails/previews for lists; fetch originals only on demand.
- Upload media directly to private object storage using authorized upload intents; do not proxy large file bodies through application functions unless a measured constraint requires it.
- Keep critical transactions short; do not hold database locks while uploading files or generating PDFs.
- Use optimistic version checks for draft updates and transactional locks for claims/approval/capacity.
- Debounce search and avoid excessive polling.
- Cache only non-sensitive or safely scoped data; never let cache bypass RLS or leak across users.

## 3. Initial load-test workload

Test at 10, 25, 50, 75, and 100 concurrent users, with a representative mixture:
- authentication/session bootstrap;
- session and assignment reads;
- serial search and unit claim;
- draft saves and checklist updates;
- evidence upload intent/confirmation and concurrent media upload;
- review queue and approval;
- dashboard and actual/target reports;
- PDF generation/print event operations.

Include mobile-like network latency, packet loss/retry scenarios, and realistic photo sizes once field evidence requirements are known.

## 4. Required measurements

Record environment and plan, region, dataset size, user mix, request rate, throughput, p50/p95/p99 latency, error rate, database CPU/memory/connections, slow queries, storage upload duration/failure/retry, egress, and browser performance. Report API latency separately from media transfer duration.

## 5. Provisional acceptance approach

Do not invent fixed latency promises before measuring the selected plan and field network. Before UAT, Product Owner and engineering approve explicit thresholds for:
- login/session bootstrap;
- core reads and writes;
- claim and submit transactions;
- dashboard/report queries;
- image upload completion and retry;
- offline synchronization recovery.

At 100 concurrent users, integrity requirements are absolute: no lost acknowledged write, duplicate active claim, duplicate revision, cross-scope data leak, unauthorized transition, or silent conflict overwrite.

## 6. Operations baseline

- Version-controlled migrations and reviewed deployment.
- Separate production secrets from previews.
- Provider usage and quota monitoring for database, storage, egress, auth, Vercel compute/transfer, and CI.
- Tested database backup and restore; evidence object recovery/retention must also be addressed.
- Deployment rollback procedure and forward-fix migration policy.
- Incident log with severity, impact, owner, mitigation, root cause, and follow-up.
- Production health checks and application error monitoring; exact tool and cost require approval.
- No release based only on green CI; backup restore, RLS, UAT, and operational readiness are separate gates.

## 7. CI cost policy

- Pull requests: formatting/lint, type checks, unit tests, migration/static checks, and targeted security checks.
- Main/release: broader integration and RLS tests, build, end-to-end smoke tests.
- Scheduled/release candidate: full browser, offline, load, and recovery suites.
- Avoid duplicate workflow triggers; skipped checks are not passes.
- Do not skip security or data-integrity controls merely to save minutes.

## 8. Open decisions

- Production region and data residency.
- Provider plan and verified quotas/backup capabilities.
- Numeric SLO thresholds.
- Evidence size distribution and concurrency profile.
- Monitoring/alerting tool and owner.
- Backup retention, RPO/RTO, restore cadence, and object storage recovery.
- Support hours and incident response responsibility.


## T-11 compatibility and load-test decision
- PO-approved browser baseline: current stable Chrome on Android for Inspector; current stable Chrome or Edge on desktop for Korlap, Reviewer, Super Admin and Print Officer.
- Tablet use requires explicit responsive, camera, upload and PDF/print validation.
- Exclude obsolete/unsupported releases, embedded in-app browsers, modified browsers, and devices failing required capabilities.
- Record exact OS/device minimums and tested browser build numbers in the release/UAT compatibility matrix; do not infer exact version numbers from this decision.
- Required load-test profile remains 100 concurrent authenticated users, staged at 10/25/50/75/100. This is a test target, not a capacity/SLA claim.
- Numeric latency/error-rate SLOs remain OPEN until provider plan/region/quotas and representative workload are verified and measured.

T-11 option B is PO-approved; compatibility and load tests have not been executed.


## T-14 — Inspector account capacity definition (PO-approved 2026-11-24)

The account-capacity metric counts distinct enabled login accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment within governed project/session scope. Count once across roles/assignments; exclude pending, rejected, suspended, disabled and expired-role accounts. The cap is combined across both locations, configurable 1–100 with default 50, and must be atomically enforced. This metric is separate from the 100-concurrent-authenticated-user load-test target.
