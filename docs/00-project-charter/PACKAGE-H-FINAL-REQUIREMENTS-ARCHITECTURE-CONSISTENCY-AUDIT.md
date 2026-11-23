# Package H — Final Requirements & Architecture Consistency Audit

**Status:** Audit complete for current documentation baseline; scope freeze NOT approved  
**Version:** 0.1.0  
**Branch:** `docs/phase-0-foundation`  
**Audit date:** 2026-11-23  
**Audit type:** Documentation-only cross-document review

## 1. Purpose and boundary

Package H checks consistency across project governance, PRD, instrument specifications, functional design, architecture, UX, quality strategy, test catalogue, decision register, RAID, and evidence inventory.

This audit does not inspect or certify application code, database migrations, deployed Supabase policies, Vercel configuration, provider quotas, backup restoration, security posture, CI execution, or load-test performance. No feature implementation is authorized by this audit.

## 2. Baseline evidence reconciled

| Evidence | What it supports | Remaining limitation |
|---|---|---|
| User-supplied `Pemeriksaan Barang.pdf` (2-page filled IFP report) | IFP identity fields, physical and packaging serial numbers, five checklist sections, 49 checklist statements, 14 model specification entries, Ya/Tdk response presentation, Inspector sign area | Does not identify controlled revision/issuing authority or establish photo-slot completeness |
| Legacy IFP screenshots | IFP photo-slot labels and application flow | Mandatory/conditional status and complete screen states require confirmation |
| Standing Bracket checklist screenshots | 19 visible checklist rows | Full checklist, grouping, exact ambiguous quantity, and response/exception rules remain open |
| Standing Bracket serial-number annex photograph | Serial number + BAIK/CACAT table, condition-specific documentation references, two paraf blocks, 13 sample good rows | Sample does not establish fixed row limit, canonical template, or mandatory paraf rules |
| BA sample photograph | Activity/date/location, IFP and SB rows, sample/good/defective counts, two party blocks | Authorized template revision and signatory authority remain open |
| Attendance sheet photograph | Activity/location, participant name/institution, daily columns for 23–25 November 2026 | Approved personnel fields, attendance verification authority, and canonical template remain open |

Supplied evidence is treated as available baseline evidence. It must not be described as missing. Only completeness, authority, revision, or unreadable portions remain open.

## 3. Cross-document findings

| ID | Severity | Finding | Disposition |
|---|---|---|---|
| H-001 | High | Capacity wording incorrectly implied 50 was the minimum in several documents and tests. | Corrected: configurable below or above 50, default 50, hard maximum 100 distinct active Inspector accounts combined across both locations. Minimum permitted value remains an explicit policy parameter to confirm before implementation. |
| H-002 | High | RTM still described IFP checklist as legacy transcription only after the two-page PDF sample was supplied. | Corrected: IFP-001 is reconciled to sample; controlled authority/version remains open. IFP photo-slot completeness remains partial/open. |
| H-003 | Medium | BA, attendance, and Standing Bracket annex evidence needed to be translated into output requirements, not just listed as screenshots. | Added requirements to Reports, Documents, Printing, Attendance, and Audit design; evidence inventory records REF-016..REF-018. |
| H-004 | High | Standing Bracket visible checklist rows and annex evidence do not prove complete instrument requirements. | Remains open; do not infer missing checklist rows or mandatory photo rules. |
| H-005 | High | Offline contract depends on supported browsers/devices, local data protection, conflict behavior, and claim recovery not yet approved. | Remains open; implementation must not exceed approved offline scope. |
| H-006 | High | Institutional privacy, retention, deletion, legal basis, data residency, and evidence access policy are not documented as approved. | Remains open; production data handling cannot be frozen. |
| H-007 | High | Supabase/Vercel plan, quotas, region, billing ownership, environment separation, backup and restore capability are not verified. | Remains open; production operations approval blocked. |
| H-008 | Medium | Physical ERD invariants, serial normalization, assignment temporal constraints, and evidence-to-revision linkage require final constraint-level review. | Remains open before migrations. |
| H-009 | Medium | Trusted command boundary between Vercel server functions and PostgreSQL RPC is not finalized. | Remains open before API implementation. |
| H-010 | Medium | BA/attendance authority, report headline definition, project reconciliation, and exact session transitions are not fully approved. | Remains open for Product Owner decisions. |
| H-011 | Medium | Audit INS-016 remains PROPOSED; it is not an approved policy. | Keep status PROPOSED until explicit decision. |
| H-012 | Medium | 100 concurrent authenticated users is a load-test target, not proven capacity or an unconditional latency guarantee. | Keep as test target; establish measurable thresholds and run representative tests later. |

## 4. Capacity contract after correction

- Default configured Inspector capacity: 50.
- The configured value may be lower or higher than 50.
- Hard maximum: 100 distinct active Inspector accounts across both locations combined.
- This is a single project-wide cap, not a per-location cap.
- A person is counted once regardless of number of assignments.
- Super Admin controls configured capacity and allocation between locations.
- Capacity change and Inspector activation/role grant must be authorized, audited, and atomic.
- The minimum permitted configured value must be explicitly set as a policy parameter before implementation; do not silently assume 50.

The separate performance target remains 100 concurrent authenticated users. It is not the same as the Inspector account capacity.

## 5. Architecture invariants retained

1. Supabase PostgreSQL is the only primary source of truth.
2. Supabase Auth is the identity provider; private Supabase Storage holds evidence.
3. Vercel hosts the web/PWA and narrowly scoped trusted server operations.
4. No service-role secret may be exposed to the browser.
5. Every exposed application table requires server-side authorization and RLS.
6. Submitted inspection revisions and original evidence remain immutable; corrections create new revisions or append-only events.
7. Actual inspection facts are never rewritten to match target allocations.
8. Claims, capacity, submit, review, approval, and print sequencing require concurrency-safe transaction boundaries and retry/idempotency controls.
9. Self-review and self-approval are prohibited.
10. Operational authority is explicitly scoped by assignment/session/location/instrument.
11. No second primary database, Redis, Firebase backend, VPS, or microservices without a separately approved ADR.

## 6. Traceability and test coverage review

The RTM provides a useful high-level requirement index and the quality package includes test families for authentication, authorization, capacity, inspection lifecycle, evidence/offline, reports/documents, and session closure.

Before scope freeze, the following traceability work remains:
- Add explicit trace links from BA summary counts, attendance multi-date columns, and Standing Bracket serial annex generation to acceptance criteria and test IDs.
- Map each instrument checklist item and each photo slot to stable requirement IDs and corresponding positive/negative tests.
- Resolve the minimum Inspector capacity parameter and align test boundaries.
- Ensure each unresolved decision is visibly marked OPEN in PRD, Decision Register, RTM, RAID, and relevant detailed specification.
- Confirm that no proposed policy (including INS-016) is treated as approved in test acceptance criteria.

## 7. Scope-freeze blockers

The following must be resolved or explicitly accepted by the authorized Product Owner / institutional authority before scope freeze:

1. Controlled source authority/version and completeness for IFP and Standing Bracket checklists, specifications, and photo-slot rules.
2. Final BA template/signatory authority and attendance template/verification authority.
3. Final Standing Bracket annex policy, condition coding, and paraf requirements.
4. Client report delivery method, actual headline count, project reconciliation, and final closure rules.
5. Session creation authority and exact state transitions.
6. Offline supported-device/browser matrix, local data protection, conflict/recovery rules.
7. Privacy/legal basis, data residency, retention/deletion, legal hold, and evidence access policy.
8. Supabase/Vercel plan, quotas, region, billing owner, environment setup, backup/restore, monitoring, and rollback ownership.
9. Final ERD constraints, serial normalization/uniqueness, temporal assignment semantics, and evidence-revision binding.
10. Final API trusted-command boundary and privileged operation model.
11. Numeric performance thresholds and representative load profile; 100 concurrent-user test remains required.
12. Explicit disposition of INS-016 audit proposal and remaining operational/document authority decisions.

## 8. Audit conclusion

**DOCUMENTATION BASELINE: SUBSTANTIAL / CONSISTENCY CORRECTIONS APPLIED.**  
**SCOPE FREEZE: NOT READY.**  
**FEATURE IMPLEMENTATION: NOT AUTHORIZED.**

Package H records and corrects identified documentation inconsistencies. It does not convert recommendations into approvals or substitute engineering assumptions for official source evidence and institutional decisions. Continue with a final decision-resolution and traceability pass; do not start feature coding until the blockers are resolved or explicitly accepted by the authorized owner.
