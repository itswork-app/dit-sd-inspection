# G11 Evidence Closure Plan — Dit. SD Inspection

**Document ID:** G11-ECP-001  
**Version:** 1.0.0  
**Status:** ACTIVE — evidence collection and external execution gates remain open  
**Date:** 2026-11-27  
**Baseline:** `main` merge commit `ae271615bacae3c3b48eeaafee72ae1c6829fbf1` (PR #42)  
**Authority:** `AGENTS.md` v1.3.0; MIB-001; DGA-001  
**Purpose:** Turn the remaining G11 verification gaps into explicit, independently verifiable work packages. This plan is not evidence of execution, provider approval, UAT completion, or production readiness.

## 1. Current gate position

- **G9-F1 / G9-TECH:** FROZEN.
- **G10:** ACTIVE; I1–I5 are implemented on isolated local/development infrastructure using synthetic data.
- **G11:** PARTIAL. Local suites and rehearsals are recorded in DGA-001 §§22–23. Hosted GitHub Actions CI has now passed on the PR #42 merge commit; repository enforcement is not complete because the repository ruleset named `main` (ID `28208385`) is currently `disabled`.
- **G12:** NOT VERIFIED / BLOCKED. No production deployment or real institutional data operation is authorized or evidenced.

### 1.1 Verified CI evidence

| Evidence | Result | Boundary |
|---|---|---|
| PR #42 head `390855b248d28c36e0fd47feae7fb9758788da82`, run #92 / `45961872626` | PASS | PR-triggered CI only |
| Merge commit `ae271615bacae3c3b48eeaafee72ae1c6829fbf1`, main push run #93 / `45965232365` | PASS | Actual `push` event on `main`; Quality checks job completed successfully |
| Combined commit statuses for merge SHA | Empty | GitHub Actions run evidence is available separately; do not infer required branch protection from this endpoint |
| Repository ruleset `main`, ID `28208385` | DISABLED | Ruleset enforcement is not active |
| Branch protection endpoint | NOT READABLE by current integration (HTTP 403) | No claim is made that branch protection is absent; verify with an administrator |

Run #93 executed checkout, Node.js setup, dependency installation, and `npm run check` (lint, typecheck, unit tests and production build). See [run #93](https://github.com/itswork-app/dit-sd-inspection/actions/runs/45965232365).

## 2. Work packages and closure criteria

| Work package | DGA | Required execution/evidence | Closure condition | Current state |
|---|---|---|---|---|
| WP-01 Hosted CI | B15 | Preserve successful main-push run #93 and subsequent PR/main runs; record commit SHA, workflow/run ID, event, job conclusion and timestamps | At least one successful main-push run and successful PR quality gate on the reviewed head; failed/skipped jobs explained | PASS for current merge SHA; ongoing |
| WP-02 Repository enforcement | B15 / I-012 | Repository administrator reviews ruleset `28208385`, enables enforcement after validating required checks and recovery access; independently verify required-check configuration and branch protection | Active enforcement on `main`, correct required status checks, no bypass beyond approved emergency policy, and evidence snapshot | OPEN — ruleset disabled |
| WP-03 Managed PostgreSQL + Storage recovery | B06 | On an authorized isolated managed-provider project, export/restore PostgreSQL and required Storage object bytes; checksum reconciliation; validate schema, RLS/grants, references, tombstones/legal holds; measure RPO/RTO | Signed drill report includes source/target, provider/region/plan, backup timestamp, checksums, measured RPO/RTO, validation, exceptions and operations sign-off | BLOCKED — provider ownership/plan/access and approval not established |
| WP-04 Real-device offline UAT | B07 | Execute approved role-based scenarios on actual supported Android Chrome device(s); capture OS/device/browser build, offline edits, reconnect/replay, conflicts, logout/purge, device-loss recovery and evidence access controls | Traceable test IDs, sanitized logs/screenshots where useful, defects disposition, tester identity/role and PO/security acceptance | NOT EXECUTED — physical test devices and UAT participants required |
| WP-05 Staging load/SLO | B08 | After authorized staging/provider setup and approved numeric SLOs, run representative workload at 10/25/50/75/100 concurrent authenticated users including photo upload, DB writes, reports and PDF | Reproducible report includes dataset/workload, environment/plan/region, p50/p95/p99, throughput, errors, DB/storage metrics, integrity checks, thresholds and approval | BLOCKED — staging and numeric SLO approval absent |
| WP-06 Remaining QA catalogue | G11 | Map every planned test ID to executed result or explicit not-applicable/deferred rationale; prioritize critical security, authorization, data-integrity, offline, notification, document/print and recovery cases | No critical test unaccounted for; failures fixed/retested; deferred cases have owner, reason, compensating control and gate impact | PARTIAL — catalogue contains 413+ definitions; not all have execution evidence |

## 3. Execution sequence

1. **CI and repository governance (WP-01/WP-02):** keep the existing workflow; verify main-push and PR runs. A repository administrator must inspect and enable the `main` ruleset only after confirming the intended required checks and recovery/bypass policy. Do not weaken checks to obtain a green result.
2. **Provider readiness (WP-03/WP-05):** obtain written provider ownership, billing, region, plan, quota, backup and staging authorization under T-12. Do not use production data. Use a separately authorized isolated managed project and synthetic data.
3. **Recovery drill (WP-03):** test PostgreSQL and Storage together. The prior local rehearsal excluded Storage object bytes and is not a managed-provider restore.
4. **Device/UAT (WP-04):** identify actual supported device/browser builds and approved participants. Test offline behavior and recovery without real institutional evidence unless separately authorized.
5. **Performance (WP-05):** approve numeric SLO thresholds before measuring pass/fail. The 100-user profile is a target, not a capacity claim. Do not load-test production.
6. **QA reconciliation (WP-06):** use test IDs and evidence records; no bulk status changes based on design documents or aggregate local test counts.

## 4. Evidence record contract

Every execution record must include:

- Stable work package and test IDs; requirement/decision/command references.
- Exact commit SHA and application/build version where applicable.
- Environment type (local, CI, isolated managed test, staging, device); provider, region and plan only when applicable.
- Timestamp (UTC), executor role, tool/command and test-data classification.
- Result: PASS / FAIL / BLOCKED / NOT EXECUTED / NOT APPLICABLE.
- Machine-readable logs/artifacts or durable evidence reference; redact tokens, credentials, personal data and evidence payloads.
- Defects, retries, deviations, limitations and linked remediation.
- Reviewer/approver and sign-off authority appropriate to the gate.

A green CI run proves only the checks in that workflow. It does not prove managed recovery, real-device UAT, staging capacity, institutional approval or G12 readiness.

## 5. Authorization and safety boundaries

This plan remains within documentation and read-only GitHub evidence review. It does not authorize:

- production/staging deployment or mutation;
- managed database creation, migration, restore or data transfer;
- use of real institutional personal data or evidence in development;
- changes to provider plans, billing, secrets, OAuth, retention or legal-hold settings;
- enabling external notification providers or `CMD-044` before written T-10/T-12 approvals;
- treating the disabled ruleset as an invitation to bypass governance.

The ruleset must be changed only by an authorized repository administrator using the reviewed repository settings workflow. No secrets or credentials should be shared in chat or committed.

## 6. Current disposition

G11 remains **PARTIAL**. The latest merge commit has a successful main-push CI run, which closes the narrow hosted execution proof for that commit. Repository enforcement (ruleset disabled), managed-provider PostgreSQL + Storage restore, real-device offline UAT, staging load/SLO and the unexecuted portion of the QA catalogue remain open. G12 remains **NOT VERIFIED / BLOCKED**.

This plan is a sequencing and evidence-control artifact; it does not claim that any blocked external work package has been executed.
