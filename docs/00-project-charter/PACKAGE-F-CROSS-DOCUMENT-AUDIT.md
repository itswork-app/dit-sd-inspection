# Package F — Cross-Document Architecture Audit

Status: Audit in progress — scope freeze NOT approved
Version: 0.1.0
Branch: docs/phase-0-foundation
Audit date: 2026-11-23

## 1. Scope

Reviewed the current PR #2 document inventory across project governance, product requirements, functional design, architecture, UX, and quality planning. This is a document consistency review only. No application code, migrations, deployed environment, live RLS policies, or load tests have been executed.

## 2. Findings and corrections

| ID | Severity | Finding | Action / disposition |
|---|---|---|---|
| AUD-F-001 | High | Capacity was inconsistent: approved OPS-001 permits a configurable capacity below or above 50 (default 50), up to 100 combined, while Project Charter and Phase 0 Plan still stated a hard maximum of 50. | Corrected Project Charter and Phase 0 Plan: default 50, configurable below or above 50, global hard maximum 100. |
| AUD-F-002 | Medium | Literal escaped newline sequences were inserted into Phase 0 Plan and RTM, damaging Markdown section/table formatting. | Repaired escaped newline sequences in both documents. |
| AUD-F-003 | High | Official IFP and Standing Bracket checklists/photo-slot rules remain incomplete or not validated against controlled authoritative source documents. | OPEN/BLOCKER for requirements freeze; no official wording inferred. |
| AUD-F-004 | High | Offline behavior depends on browser storage, device capability, claim expiry, shared-device security, and recovery policies not yet validated. | OPEN/BLOCKER for final offline contract and production approval. |
| AUD-F-005 | High | Institutional privacy, legal basis, retention/deletion, data residency, evidence handling, and document access policy are not approved. | OPEN/BLOCKER for production design approval. |
| AUD-F-006 | High | Provider plans, quotas, backup capability, restore behavior, environment isolation, billing ownership, and production usage are not verified. | OPEN/BLOCKER for production operations approval. |
| AUD-F-007 | Medium | Physical schema and several ERD invariants remain logical proposals; serial normalization/uniqueness, temporal assignment semantics, and evidence-to-revision linkage require final decisions. | OPEN before migrations. |
| AUD-F-008 | Medium | Exact API transport and privileged operation boundary (Vercel server functions vs PostgreSQL RPC) remain undecided. | OPEN before endpoint implementation. |
| AUD-F-009 | Medium | Numeric performance SLOs and photo workload profile are not established; 100 concurrent users is a test target, not a demonstrated capability. | OPEN until representative load tests on selected plan. |
| AUD-F-010 | Medium | BA signatory policy, attendance verification authority, report count/reconciliation rules, and some session transitions remain unresolved. | OPEN for document/workflow freeze. |
| AUD-F-011 | Medium | Audit INS-016 is proposed in Decision Register, while PRD/RTM describe audit capability at broader requirement level. | Keep audit coverage and retention policy explicitly pending Product Owner approval. |
| AUD-F-012 | Low | Package D/E artifacts are drafts and no UI, database migration, automated tests, RLS policy, or load test has been implemented/executed. | Correctly retain Phase 0 status; do not represent plans as test evidence. |

## 3. Capacity contract after correction

- Configured Inspector capacity may be below or above 50; initial/default is 50 and hard maximum is 100.
- Super Admin may increase it up to 100.
- 100 is the hard maximum across both locations combined, not per location.
- Count distinct active users holding Inspector role once, regardless of assignment count.
- Capacity activation/role grant and capacity changes must be enforced atomically.
- Separately, load-test up to 100 concurrent authenticated users with representative mixed workload. This is not a guarantee until measured.

## 4. Architecture consistency rules

- Supabase PostgreSQL remains the only source of truth; no Firebase/Redis/second database.
- Vercel hosts the web application and narrowly scoped trusted server operations.
- Browser is untrusted; no service-role credential in client bundles.
- RLS is required on every exposed application table; Storage remains private.
- Submitted revisions and finalized evidence originals remain immutable.
- Actual activity timestamps are never altered to match target allocation.
- No self-review/self-approval; assignment scope is explicit.
- All capacity/claim/submit/review state changes must be transactionally safe and idempotent where retryable.

## 5. Scope-freeze blockers

The following must be resolved or explicitly accepted by the authorized Product Owner before requirements and architecture can be frozen:
1. Authoritative IFP and Standing Bracket checklist/photo evidence sources.
2. Final BA, attendance, report and session lifecycle business rules.
3. Offline scope and supported device/browser matrix.
4. Institutional privacy, retention, deletion, and evidence access requirements.
5. Provider plan, quotas, backup/restore, environment and billing ownership.
6. Final permission matrix, physical data constraints, API command boundary, and measurable performance thresholds.

## 6. Audit conclusion

**NOT READY FOR SCOPE FREEZE. NOT AUTHORIZED FOR FEATURE IMPLEMENTATION.**

The documentation packages provide a useful baseline, but material product, operational, privacy, and platform decisions remain unresolved. The capacity and Markdown formatting inconsistencies identified in this pass are corrected on the documentation branch. Remaining blockers must be resolved through source evidence or explicit Product Owner decisions, not engineering assumptions.

## 7. Evidence limitations

This audit verifies document content and internal consistency only. It does not certify the deployed Supabase/Vercel configuration, actual RLS enforcement, backup restoration, security posture, CI status, or 100-user performance. Those require implementation and environment-level evidence in later gates.
