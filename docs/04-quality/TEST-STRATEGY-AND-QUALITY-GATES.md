# Test Strategy and Quality Gates

Status: Quality strategy draft — thresholds and environments require approval
Version: 0.1.0

## 1. Quality objectives
Prove functional parity for approved scope, data integrity, authorization isolation, recoverability, evidence integrity, and performance for the agreed concurrency target.

## 2. Test layers
1. Static: formatting, lint, type checks, dependency and secret scanning.
2. Unit: domain rules, state transitions, validation, target/actual calculations.
3. Database: migration, constraints, transaction, RLS policy tests.
4. Integration: Auth, Storage, command/API, idempotency, document generation.
5. End-to-end: user journeys by role on mobile and desktop.
6. Offline: local persistence, reconnect, replay, conflict, account revocation.
7. Security: IDOR, privilege escalation, cross-location access, upload abuse, signed URL access.
8. Concurrency/load: claims, capacity activation, draft writes, review/submit, dashboard, photo upload.
9. Recovery: database backup restore, evidence object recovery, deployment rollback.
10. UAT: field users validate approved workflow and official instrument data.

## 3. Critical invariants
- Inspector capacity is 50–100 distinct users combined across both locations.
- Concurrent load test target is 100 active authenticated users.
- No duplicate active unit claim.
- No acknowledged write is lost.
- No duplicate revision due to retry.
- No user can read/write outside authorized scope.
- No self-review/self-approval.
- Submitted revisions and original evidence are immutable.
- Actual inspection timestamps are never rewritten to fit target allocation.
- An inspection is not "completed" until its defined approval, PDF, and print-record conditions are met.
- Session cannot close while required work/documents/processes remain outstanding.

## 4. Test data
Use synthetic identities, units, serials, and images. Avoid production personal data and real institutional evidence in development/CI. Include multiple locations, parallel assignments, multi-role users, revoked accounts, duplicate serials, stale clients, and incomplete/offline drafts.

## 5. CI strategy (cost-aware)
- Pull request: formatting/lint, type checks, unit tests, migration checks, focused RLS/security tests, build.
- Main/release candidate: integration tests, broader RLS matrix, E2E smoke, artifact checks.
- Scheduled or release candidate: full E2E, offline/recovery, load, and security regression suite.
- Avoid duplicate workflow triggers and redundant full suites on every documentation-only change.
- A skipped check is not a pass; record why it was skipped and the required gate that replaces it.
- Keep critical security/data integrity checks on PR even under free CI quotas.

## 6. Exit criteria by severity
- Critical: zero open.
- High: zero open unless documented risk acceptance by authorized Product Owner and technical owner; never waive data leakage or corruption.
- Medium/low: triaged, owner and target date recorded.
- No flaky test may be silently ignored; quarantine requires ticket, owner, expiry, and replacement coverage.

## 7. Evidence of test completion
Each release candidate must retain commit SHA, environment, test suite/version, result, timestamp, logs/artifacts, known limitations, and approver. Screenshots alone are not sufficient for backend security or data integrity claims.

## 8. Open decisions
- Exact unit/integration/E2E framework.
- Numeric latency/error-rate SLO.
- Supported browsers/devices.
- Test/staging environment cost and provider quotas.
- Independent penetration test requirement.
- UAT participant list and sign-off authority.
