# Requirements Traceability Matrix — Dit. SD Inspection

**Document ID:** RTM-001  
**Version:** 0.1.22  
Status: Baseline draft — requirements require source validation  
Purpose: Link product intent to specifications, implementation units, and verification evidence. This matrix is a control index, not a substitute for detailed specifications or test cases.

## Requirement ID convention

- **GOV:** governance and project constraints.
- **AUTH:** authentication and account lifecycle.
- **AUTH-LOCK:** identity/authorization serialization and lock-order requirements.
- **RBAC:** roles, permissions, and assignment scope.
- **SES:** project/session/location/team/target management.
- **INS:** inspection and instrument behavior.
- **EVD:** photo/video evidence.
- **OFF:** offline operation and synchronization.
- **REV:** review, correction, and approval.
- **DOC:** PDF, print, BA, and attendance.
- **RPT:** reporting and dashboards.
- **AUD:** audit and notifications.
- **OPS:** deployment and production operations.
- **RET:** institutional records retention, legal hold and disposition.
- **INC:** security incident governance and response.
- **PROV:** provider ownership, configuration and secret custody.
- **REL:** release governance and artifact provenance.

## Traceability baseline

| Requirement ID | Requirement statement | Source / decision | Specification | Verification evidence | Status |
|---|---|---|---|---|---|
| GOV-001 | Release target is production | MGT-001 | Project Charter | Production readiness checklist | APPROVED |
| GOV-002 | Optimize lifecycle cost without waiving security, privacy, integrity, backup, or reliability | MGT-002 | ADR-001, Engineering Governance | Cost and security review | APPROVED |
| GOV-003 | Use Supabase + Vercel; GitHub for source control/CI | TECH-001, TECH-003 | ADR-001 | Architecture/deployment review | APPROVED |
| GOV-004 | Supabase PostgreSQL is sole primary source of truth | TECH-002 | ADR-001 | Data-flow and architecture tests | APPROVED |
| GOV-005 | Non-SaaS replacement; initial rollout includes IFP and Standing Bracket, while the platform supports future Super Admin-configured instrument types | PRD-001..003, CFG-001 | PRD; Physical Database Schema and Integrity Specification | Scope audit and configuration UAT | BASELINED; sign-off pending |
| CAP-001 | Configurable Inspector capacity ranges from 1 to 100; default 50, total across both locations combined | Decision Register OPS-001 | RBAC and Authorization; Project, Session, Target, and Assignment Model | Capacity range, audit, and atomic concurrency tests | BASELINED |
| AUTH-001 | Google sign-in; new accounts await approval and role assignment | Authentication decisions | RBAC and Authorization | Auth lifecycle tests | BASELINED |
| RBAC-001 | Users may hold multiple roles only with explicit scoped assignments | RBAC decisions | RBAC and Authorization | Positive/negative authorization tests | BASELINED |
| RBAC-002 | Operational authority is scoped by session, location, instrument, and assignment | RBAC decisions | RBAC and Authorization | RLS/API authorization tests | BASELINED |
| RBAC-003 | Self-review and self-approval are prohibited | WF decisions | RBAC and Authorization; Inspection Lifecycle | Negative workflow tests | BASELINED |
| RBAC-004 | One canonical permission registry maps every command to explicit permission, scope, grant authority and separation-of-duties rule; legacy codes are explicitly mapped or retired | T-17/T-18; Canonical Permission Registry v0.1.0 | Canonical Permission Registry; Command Authorization Verification Matrix; RBAC and Authorization; Privileged Command Boundary; RLS and Authorization | PO/security approval; exact role/grantor authority; table RLS + RPC EXECUTE mapping; 36 planned TC-CMD-AUTHZ-024 cases plus command-specific tests | DESIGN DRAFT CREATED; APPROVAL, EXACT GRANTS/RLS AND EXECUTABLE VERIFICATION OPEN |
| SES-001 | Project targets and official assignments are centrally governed | Planning decisions | Project, Session, Target, and Assignment Model | Role, target, and audit tests | BASELINED |
| SES-002 | Overlapping assignments across different locations are prevented | Assignment decisions | Project, Session, Target, and Assignment Model | Conflict/concurrency tests | BASELINED |
| SES-003 | Session cannot close while configured operational/document gates remain incomplete | Session closure decisions | Project, Session, Target, and Assignment Model | Closure-gate tests | BASELINED |
| INS-001 | Active inspections bind to frozen instrument/checklist versions | Configuration decisions | Inspection Lifecycle; instrument specs | Snapshot/version immutability tests | BASELINED |
| INS-002 | Default OK presentation is not automatic verification | Inspection decisions | PRD; instrument specs | UI and validation tests | BASELINED |
| INS-003 | Serial number identifies unit; duplicate active claims are prevented | Claim decisions | Inspection Lifecycle and Claims | Concurrency and uniqueness tests | BASELINED |
| INS-004 | Required checklist/evidence validation blocks incomplete submission | Inspection decisions | Inspection Lifecycle and Claims | Positive/negative submission tests | BASELINED |
| EVD-001 | Evidence and media state are preserved and linked to inspection revision | Evidence decisions | Offline Sync and Recovery; Inspection Lifecycle | Storage integrity and sync tests | BASELINED |
| OFF-001 | Offline drafts synchronize idempotently with conflict detection | Offline decisions | Offline, Sync, and Recovery | Offline/retry/conflict/recovery tests | DESIGN DRAFT |
| REV-001 | Reviewer returns work with reason; Inspector corrects and resubmits | WF-001..003 | Inspection Lifecycle and Claims | Revision lifecycle tests | BASELINED |
| REV-002 | Submitted revisions are immutable; approved work reopens only with authority and reason | WF-004..006 | Inspection Lifecycle and Claims | Immutability/reopen tests | BASELINED |
| DOC-001 | PDF is generated from approved revision; print events and reprints are recorded | Document decisions | Reports, Documents, Printing, Attendance, and Audit | PDF snapshot and print-event tests | BASELINED |
| DOC-002 | Wet signatures remain in scope; digital signature is not assumed | Document decisions | Reports and Documents | Template review and UAT | BASELINED |
| DOC-003 | BA and attendance have distinct lifecycle and authority | Document decisions and supplied BA/attendance samples | Reports, Documents, Printing, Attendance, and Audit | TC-DOC-005, TC-DOC-007, TC-DOC-008 | DETAIL OPEN |
| DOC-004 | BA instrument summary reconciles sample, good, and defective counts from source inspections | Supplied BA sample | Reports, Documents, Printing, Attendance, and Audit | TC-DOC-006, TC-DOC-007 | DESIGN DRAFT |
| DOC-005 | Standing Bracket serial-number annex is generated from inspection records with condition and evidence references | Supplied Standing Bracket annex sample | Standing Bracket Instrument Specification; Reports and Documents | TC-DOC-009, TC-DOC-010 | DESIGN DRAFT |
| DOC-006 | IFP PDF preserves approved checklist, serial identities, Ya/Tdk answers, and signature area | Supplied `Pemeriksaan Barang.pdf` sample | IFP Instrument Specification; Reports and Documents | TC-DOC-011 | RECONCILED TO SAMPLE / TEMPLATE APPROVAL OPEN |
| RPT-001 | Actual and Target reports are distinct; actual dates are never rewritten | RPT decisions | Reports, Documents, Printing, Attendance, and Audit | Reconciliation/date-integrity tests | BASELINED |
| AUD-GOV-001 | Audit coverage and controls follow the PO-approved INS-016 policy before implementation | T-15 PO APPROVED option A; institutional T-10 controls | Audit Event Catalogue and Governance; Privileged Command Boundary | Audit coverage/tamper/atomic rollback tests plus institutional policy evidence | PO APPROVED; institutional and implementation verification OPEN |
| OPS-002 | Production includes tested backup/restore, monitoring, deployment, and rollback | Engineering Governance | Performance and Operations Baseline | Restore drill and rollback evidence | REQUIRED; detail pending |
| PERF-001 | System is designed and load-tested for 100 concurrent authenticated users | PRD §14 | Performance and Operations Baseline | Load test at 10/25/50/75/100 users; latency, error, resource, and integrity report | BASELINED; thresholds pending |
| DATA-001 | PostgreSQL model preserves scoped relational integrity and immutable inspection revisions | PRD, functional decisions | Data Model and ERD | Migration, constraint, and immutability tests | DESIGN DRAFT |
| DATA-002 | Physical schema defines instrument catalog/versioning, instrument-type-wide canonical serial identity, durable project associations, global claims, immutable revisions, evidence links, and transaction invariants | Package L; PO-approved T-16 option B | Data Model and ERD; Physical Database Schema and Integrity Specification | Global serial uniqueness, association/FK, cross-project isolation, concurrency, evidence-link and immutability tests | DESIGN RECONCILIATION RECORDED; TECH REVIEW/POLICY OPEN; IMPLEMENTATION NOT AUTHORIZED |
| CFG-001 | Super Admin can create/configure/deactivate and directly publish supported declarative instrument versions without a second-person approval; published versions are immutable and sessions/history retain frozen snapshots | Decision Register CFG-001; T-17 PO APPROVED (A), 2026-11-24 | PRD; Data Model and ERD; Physical Database Schema; RLS/Authorization; Privileged Command Boundary | Allowlist/schema validation, publish permission, atomic audit, immutability, session pinning, deactivation and historical snapshot tests | PO APPROVED (A); design specified; cross-document technical review and verification OPEN |
| SEC-001 | All exposed application data and evidence access are protected by server authorization and RLS | ADR-001, security decisions | RLS and Authorization Design; Security Threat Model | RLS matrix and negative authorization tests | DESIGN DRAFT |
| SEC-002 | Every application table and private Storage object class has an explicit deny-by-default policy and role/scope access matrix | Package M | Table-by-Table RLS Policy Catalogue | Staging RLS, RPC, view, and Storage positive/negative test matrix | DRAFT COMPLETE; REVIEW/EXECUTION OPEN |
| SEC-003 | Physical table inventory, RLS catalogue, ERD entities, and T-18 command privilege boundaries remain reconciled; no ERD-only entity is implemented/exposed without physical schema and RLS disposition | Package L/M; T-18 option A; T-13; INS-015 | Physical Schema ↔ RLS ↔ Command Reconciliation; Physical Database Schema; Data Model and ERD; Table-by-Table RLS Catalogue; NLA-001 | Proposed 48/48 physical↔RLS name parity; seven new tables (print_batches + six notification lifecycle tables); table-specific RLS tests and live ACL/function/Storage verification | DOCUMENTATION INVENTORY RECONCILED; TECH REVIEW AND LIVE PRIVILEGE VERIFICATION OPEN |
| SEC-004 | Every logical state-changing/read command has a versioned contract covering request allowlist, JWT-derived actor, permission, scope/SoD, physical read/write set, lock/idempotency/audit/outcome and dedicated tests; blocked institutional commands remain unavailable | T-14..T-18; NLA-001 | PostgreSQL Command Contract Catalogue; API and Transaction Contracts; Privileged Command Boundary; Canonical Permission Registry; Command Authorization Verification Matrix; NLA-001 | 54 proposed command/read/worker operations CMD-001..054; CMD-049..054 notification extension; exact routes/RPC signatures/role grants/RLS/EXECUTE and tests | DESIGN CATALOGUE EXTENDED; PO/SECURITY APPROVAL AND IMPLEMENTATION VERIFICATION OPEN |
| SEC-005 | PostgreSQL function security mode, function owner, caller roles, exact-signature EXECUTE ACL, table ACL, PUBLIC/anon denial, internal helper exposure and approved T-18 Option A execution model are verified before any RPC/migration | T-18 PO APPROVED Option A; PostgreSQL Function Security & EXECUTE Grant Design; T18 Execution Model Security Review | Function Security & EXECUTE Grant Design; T18 Execution Model Security Review; Privileged Command Boundary; RLS and Authorization; Table-by-Table RLS Catalogue; PostgreSQL Command Contract Catalogue | Live role/function/ACL inventory; per-function owner/search_path/EXECUTE review; 69 function-security cases + 12 TC-EXEC-MODEL-027 cases; end-to-end caller-JWT and staging negative tests | EXECUTION MODEL PO APPROVED; FUNCTION/ACL INVENTORY AND IMPLEMENTATION VERIFICATION OPEN |
| EVD-002 | Evidence uses private storage, verified upload lifecycle, and immutable originals | ADR-001, evidence decisions | Evidence Storage and Media Lifecycle | Upload, checksum, access-control, and recovery tests | DESIGN DRAFT |
| EVD-003 | Evidence privacy, classification, retention, legal hold, deletion and recovery are controlled and institutionally approved | Package O | Evidence Privacy, Retention, Deletion and Recovery Specification | Access, hold, expiry, deletion, object recovery and audit tests | DRAFT; INSTITUTIONAL APPROVAL BLOCKED |
| OPS-003 | Database and object backups have approved RPO/RTO and proven restore procedures | Package P | Backup, Restore and Disaster Recovery Plan | Isolated PostgreSQL + Storage restore drill and checksum reconciliation | DRAFT; PROVIDER VERIFICATION BLOCKED |
| OPS-004 | Production region, environments, secrets, quotas, billing and provider ownership are governed | Package Q | Production Environment, Secrets and Provider Governance | Environment isolation, secret scan, quota sheet, deployment/rollback and account review | DRAFT; SPONSOR APPROVAL BLOCKED |
| API-001 | Critical commands are idempotent and transactionally enforce claims, submission, approval, and capacity | Functional decisions; T-18 PO-approved architecture | API and Transaction Contracts; Privileged Command Boundary | Per-command duplicate/retry/concurrency/audit rollback tests | COMMAND-FAMILY INVENTORY; PER-COMMAND CONTRACTS OPEN |
| API-002 | Every privileged mutation executes through a trusted Vercel route and narrowly scoped PostgreSQL command boundary; browser direct DML is denied | Package N; T-18 PO APPROVED (A), 2026-11-24 | Privileged Command Boundary; Command Authorization Verification Matrix; RLS/grant catalogue | TC-CMD-018 boundary cases; TC-CMD-AUTHZ-024-001..040 design cases; later command-specific audit/idempotency/concurrency tests | PO APPROVED; individual command contracts, exact grants/RLS and executable verification OPEN |

## Instrument-specific traceability (pending official source validation)

| Requirement ID | Instrument | Requirement area | Known source coverage | Verification plan | Status |
| IFP-001 | IFP | Checklist categories and 49 checklist statements across five categories | Reconciled against supplied two-page `Pemeriksaan Barang.pdf` sample report and legacy screenshots | Confirm controlled authority/version and current validity; retain exact text/order from sample | RECONCILED TO SAMPLE / AUTHORITY OPEN |
| IFP-002 | IFP | Ten identified photo-slot labels | Legacy reference screenshots; sample PDF does not establish photo-slot completeness or mandatory status | Confirm full slot list, required rules, exceptions, and PDF placement | PARTIAL / COMPLETENESS OPEN |
| BRK-001 | Standing Bracket | Checklist categories and item list | 19 visible checklist rows from supplied screenshots; serial-number annex sample separately reconciled; complete authoritative list not established | Confirm full checklist, grouping, text, and response rules | PARTIAL / SOURCE VALIDATION OPEN |
| BRK-002 | Standing Bracket | Five identified photo-slot labels | Legacy reference descriptions; completeness/mandatory status unverified | Verify complete list and required rules | DRAFTED / SOURCE VALIDATION OPEN |
| PRD-001 | Product | Product scope, journeys, functional/non-functional requirements | PRD v0.1.0 | Product Owner review | DRAFTED / REVIEW REQUIRED |
| AC-001 | Product | Observable acceptance criteria | Acceptance Criteria v0.1.0 | Map to test cases and UAT evidence | DRAFTED / REVIEW REQUIRED |

## Instrument verification matrix

| ID | Requirement | Specification | Verification | Status |
|---|---|---|---|---|
| QA-INS-001 | Every identified IFP checklist item has stable ID and category-based verification | IFP Instrument Specification | TC-IFP-CHK-001..004; Instrument Requirements Verification Matrix | DESIGN DRAFT |
| QA-INS-002 | IFP model-specific specification fields are verified against frozen configuration | IFP Instrument Specification | TC-IFP-SP-001 | DESIGN DRAFT |
| QA-INS-003 | IFP evidence slots are verified without assuming unapproved mandatory status | IFP Instrument Specification | TC-IFP-PH-001 | DESIGN DRAFT |
| QA-INS-004 | All 19 visible Standing Bracket rows have provisional trace IDs and test coverage | Standing Bracket Instrument Specification | TC-BRK-CHK-001..002 | PARTIAL / SOURCE VALIDATION OPEN |
| QA-INS-005 | Standing Bracket evidence labels have test coverage without assuming completeness | Standing Bracket Instrument Specification | TC-BRK-PH-001 | PARTIAL / SOURCE VALIDATION OPEN |
| QA-INS-006 | Instrument versioning, historical snapshots, serial handling, concurrency, and PDF parity are verified | Instrument specifications; architecture | TC-INSTR-001..008 | DESIGN DRAFT |

## Package C design artifacts

- `docs/03-functional-design/RBAC-AND-AUTHORIZATION.md`
- `docs/03-functional-design/PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md`
- `docs/03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md`
- `docs/03-functional-design/OFFLINE-SYNC-AND-RECOVERY.md`
- `docs/03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md`

All are design drafts, not formal Product Owner approvals. Open decisions are explicitly retained in each document.

## Package O/P/Q — Privacy, recovery, and production operations

- `docs/02-architecture/EVIDENCE-PRIVACY-RETENTION-DELETION-AND-RECOVERY.md`
- `docs/02-architecture/BACKUP-RESTORE-AND-DISASTER-RECOVERY-PLAN.md`
- `docs/02-architecture/PRODUCTION-ENVIRONMENT-SECRETS-AND-PROVIDER-GOVERNANCE.md`

These documents define proposed controls and release gates. Retention periods, RPO/RTO, provider plans/quotas, region, and named operational owners remain unapproved or unverified.

## Package L/M/N — Database integrity, RLS, and trusted command artifacts

- `docs/02-architecture/PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md`

Package N's Vercel route + caller-JWT PostgreSQL command-function pattern is PO APPROVED (T-18 option A). It remains design-only: no route/RPC, grants, RLS policies or security tests have been implemented or verified.

## Package L/M — Database integrity and authorization policy artifacts

- `docs/02-architecture/PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md`
- `docs/02-architecture/TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md`

These are design artifacts only. They do not constitute migrations, deployed RLS, or executed security tests.

## Package D technical architecture artifacts

- `docs/02-architecture/SYSTEM-ARCHITECTURE.md`
- `docs/02-architecture/DATA-MODEL-AND-ERD.md`
- `docs/02-architecture/RLS-AND-AUTHORIZATION-DESIGN.md`
- `docs/02-architecture/EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md`
- `docs/02-architecture/API-AND-TRANSACTION-CONTRACTS.md`
- `docs/02-architecture/SECURITY-THREAT-MODEL.md`
- `docs/02-architecture/PERFORMANCE-AND-OPERATIONS-BASELINE.md`

Package D is a technical design draft, not an implementation authorization. Physical schema, provider plans, offline storage, media limits, numeric SLOs, and operations ownership remain subject to review and approval.

## Package K — Security, Data Integrity & Production Readiness Audit

- `docs/00-project-charter/PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md`

Audit outcome: documentation review completed; security posture not tested/certified; production readiness not ready.

## Change-control rules

- Every new requirement receives a stable ID; IDs are never reused.
- Every approved requirement must link to an authorized source or decision.
- Every implementation PR references requirement IDs.
- Every implemented requirement links to code paths/PRs; verified requirements link to test results or UAT evidence.
- Changes to approved requirements require impact analysis across UX, data, authorization, audit, migration, reporting, tests, and operations.
- Unknown source details remain OPEN; do not fill gaps with assumptions.

## Package E — UX and Quality traceability

| ID | Requirement | Design / Test Artifact | Verification | Status |
| UX-001 | Role-based information architecture and scoped navigation | Information Architecture and Navigation | Role-based navigation and scope tests | DESIGN DRAFT |
| UX-002 | Mobile-first inspection flows with explicit save/sync states | Screen Flows and Wireframe Specification | Mobile E2E and usability UAT | DESIGN DRAFT |
| UX-003 | Consistent responsive and accessible UI components | Design System and Responsive UX | Responsive, keyboard, contrast, and screen-reader checks | DESIGN DRAFT |
| QA-001 | Layered quality gates for functional, security, data integrity, and recovery | Test Strategy and Quality Gates | CI and release evidence | DESIGN DRAFT |
| QA-002 | Traceable test cases for authorization, capacity, lifecycle, offline, documents, and reporting | Test Case Catalog and UAT | Command-specific positive/negative/audit rollback/idempotency/concurrency evidence; executed test records and Product Owner sign-off | CATALOG DRAFT; command-specific coverage OPEN |

## Package R — Audit event catalogue and governance

| AUD-001 | Material business, security, and governance actions use a canonical event envelope with actor, active role, scope, resource, outcome, and timestamp | Audit Event Catalogue and Governance | AUD-T01..T12 | PO APPROVED (T-15 A); institutional metadata/retention approvals and implementation verification OPEN |
| AUD-002 | Critical state changes and their audit event commit atomically; audit append failure rolls back the protected mutation | Audit Event Catalogue and Governance; Privileged Command Boundary | AUD-T01..T03 | PO APPROVED (T-15 A); command implementation and tests OPEN |
| AUD-003 | Audit history is append-only for application roles; corrections use compensating events | Audit Event Catalogue and Governance; RLS Catalogue | AUD-T03, AUD-T11 | PO APPROVED (T-15 A); grants/deployment verification OPEN |
| AUD-004 | Audit payloads exclude secrets, signed URL tokens, raw media, and unnecessary personal data | Audit Event Catalogue and Governance; Evidence Privacy and Retention | AUD-T09 | PO APPROVED (T-15 A); institutional classification and implementation verification OPEN |
| AUD-005 | Audit access/export, legal holds, retention disposition, and security administration are permissioned and audited | Audit Event Catalogue and Governance | AUD-T08, AUD-T10 | PO APPROVED (T-15 A) for least-privilege direction; institutional retention/legal-hold/export authority OPEN |

New source evidence: the 23-November Standing Bracket form and 20-November BA are reconciled in the Standing Bracket Instrument Specification and Instrument Requirements Verification Matrix. The Product Owner confirmed the 23-November document as the official Standing Bracket instrument source on 2026-11-23. Its 19-row checklist (6 physical + 13 accessories) is the project baseline; the earlier screenshot transcription remains a separate observation to be mapped without silent merging. The BA sample supports serial-annex/count-reconciliation requirements but does not approve signatory policy.

## Package S — Final audit disposition

| ID | Requirement / gate | Audit artifact | Verification / approval evidence | Status |
| GOV-005-S | Cross-document baseline must be reconciled before scope freeze | Package S — Final Cross-Document Audit and Scope-Freeze Readiness | Approved closure of S-01..S-12 and completed scope-freeze checklist | NOT READY |
| INS-S-001 | Standing Bracket controlled source checklist and item mapping must be approved | Standing Bracket Instrument Specification; Package S | Controlled source/version and Product Owner/institution approval | BLOCKED |
| DOC-S-001 | BA signatory, attendance verification, and report reconciliation authority must be approved | Reports, Documents, Printing, Attendance, and Audit Design; Package S | Approved document governance and UAT | BLOCKED |
| OFF-S-001 | Offline/device/local data protection contract must be approved | Offline Sync and Recovery; Package S | Approved device matrix, retention, encryption, conflict and recovery acceptance | BLOCKED |
| AUD-S-001 | INS-016 audit policy and institutional governance must be approved or explicitly deferred | T-15 PO APPROVED option A; T-10 institutional authority | Audit Event Catalogue and Governance; Package S | PO policy: APPROVED; institutional classification/retention/deletion/legal-hold/network-metadata authority: BLOCKED; implementation and verification: NOT AUTHORIZED / NOT EXECUTED |
| OPS-S-001 | Provider, region, quota, billing, backup and restore capability must be verified | Packages O/P/Q; Package S | Provider capability sheet, approved budget/region, successful restore drill | BLOCKED |

## Package T decision traceability

The detailed PO decision closure register is maintained in `docs/00-project-charter/PACKAGE-T-PO-DECISION-CLOSURE-PACK.md`. Decision IDs T-01 through T-18 cover authoritative instrument masters, BA signatories, executive-summary signature, client report delivery, actual report metrics, project closure, session authority, attendance verification, offline scope, evidence privacy/retention, device/performance baseline, provider operations, print workflow, Inspector capacity semantics, INS-016 audit policy, serial/evidence integrity, CFG-001 publication governance and privileged command boundary.

These IDs are decision-tracking references, not implementation-complete requirements. T-01 through T-04 have explicit PO outcomes recorded in the Decision Register and detailed Package T update; T-01 Standing Bracket source is confirmed; official IFP source and SB photo/evidence rules remain outstanding. T-02 institutional signatory authority remains outstanding. T-05 through T-09 are PO APPROVED (2026-11-23); T-10 option B is PO APPROVED as a formal institutional records/legal/privacy review path; written institutional policy remains BLOCKED. T-11 option B is PO APPROVED for current mainstream stable browsers with explicit exclusions; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED as an alternative provider-ownership arrangement subject to formal institutional definition and approval; actual ownership, billing, region, provider capability and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 is PO APPROVED option A; T-15 is PO APPROVED option A; T-16 is PO APPROVED option B (2026-11-24); T-17 publication governance and T-18 command architecture/execution model are PO APPROVED; design documentation is reconciled, while live technical inventory, per-function review, implementation and verification remain OPEN/BLOCKED. T-09 option B approves limited offline editing only for already claimed drafts; device/local-data safeguards remain open. Each decision must be reconciled into the relevant requirement/specification and verification case. PO approval does not replace institutional approval or implementation verification.

## Package T — accepted PO decisions and traceability (2026-11-23)

| Decision | Approved direction | Traceability follow-up | Residual gate |
|---|---|---|---|
| T-01 | Official approved institutional source documents are authoritative master; SB source confirmed by PO | Trace SB's 19 official rows to source and preserve provenance; reconcile earlier screenshot; confirm IFP source and SB photo rules | PARTIALLY CLOSED: IFP source and SB photo/evidence rules remain OPEN |
| T-02 | BA signatory blocks configurable per approved template | Verify variable party count, organization, role/title, order and required/optional behavior | Institutional signatory authority and approved template remain OPEN |
| T-03 | Executive-summary signature configurable per template; default none unless required | Verify configured signature/no-signature variants in PDF tests | PO direction closed; institutional template governs |
| T-04 | PDF-only client delivery for initial release; portal deferred | Verify permission-controlled PDF access/distribution and mark portal out of initial scope | PO direction closed; portal needs change request |
| T-05 | Distinct actual counts: Inspected, Submitted, Approved, Completed | Verify metric definitions, timestamp/filter labels and Completed formula | PO APPROVED; implementation/test pending |
| T-06 | Super Admin final project closure after gates and actual/target reconciliation | Test all blockers, explicit reason/confirmation, audit, and no date auto-close | PO APPROVED; implementation/test pending |
| T-07 | Super Admin creates/configures sessions; Korlap transitions within scope/permissions; CLOSED terminal normally | Test role/scope/state transitions and privileged reopening | PO APPROVED; implementation/test pending |
| T-08 | Korlap verifies attendance within assigned scope; upload never auto-verifies | Test separated permissions, scope, audit and verification state | PO APPROVED; implementation/test pending |
| T-09 | Option B: offline editing only for already claimed drafts; no offline claim/approval/final submit/admin | Verify idempotent sync, server authorization recheck, visible conflict preservation, pending evidence gating and prohibited offline commands | PO APPROVED; device/local-data safeguards and implementation/tests pending |

T-01 through T-08 are partial decision closures, not blanket closure of Package S. Remaining decisions and evidence dependencies remain active. Do not mark scope freeze ready based on these partial closures.

## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.

## T-11 traceability update
| Requirement | PO decision | Verification | Status |
| Supported browser baseline | T-11 option B: current stable Chrome Android for Inspector; current stable Chrome/Edge desktop for other operational/admin roles; explicit exclusions | TC-COMP-001..006 | PO APPROVED; execution pending |
| Tablet compatibility | Conditional on responsive, camera, upload and PDF/print validation | TC-COMP-004 | Validation pending |
| Concurrent load profile | 100 concurrent authenticated users; staged 10/25/50/75/100 | TC-LOAD-001..002 | Target approved; execution pending |
| Numeric performance SLO | Set only after workload/provider verification and baseline measurement | Performance baseline and load evidence | OPEN |

| OPS-005 | Provider ownership arrangement must be institutionally defined and approved; account/billing owners, custodians, region authority and recovery roles must be evidenced | Package T-12; Package Q/P | Signed ownership/governance record, provider capability sheet, named recovery contacts, successful PostgreSQL + Storage restore drill | PO option C APPROVED; institutional/provider verification BLOCKED |

### T-13 — Print workflow decision (PO approved 2026-11-23)

T-13 option B is PO APPROVED. The general print workflow maps to acceptance requirements AC-DOC-008 through AC-DOC-012 and TC-PRINT-001 through TC-PRINT-007. The dedicated durable batch lifecycle maps to TC-PRINT-BATCH-001 through TC-PRINT-BATCH-008. TC-DOC-009..011 remain document/instrument cases and are not the print-batch test range. Detailed implementation and test execution remain pending.


## T-14 traceability — Inspector capacity predicate (PO-approved 2026-11-24)

Trace the canonical predicate across UI, server commands, PostgreSQL transactions, authorization and QA: distinct enabled login account + active Inspector role grant + at least one currently effective operational Inspector assignment in governed project/session scope. Exclude pending, rejected, suspended, disabled and expired-role accounts; deduplicate across assignments/roles. Preserve combined cap 1–100, default 50, atomic enforcement, invalid-value rejection and no silent deactivation on cap reduction. Test execution remains pending.


## Registration and Super Admin staffing traceability

Trace registration → pending account → Super Admin approval → role/permission/scope grant → Super Admin team membership and operational assignment. Registration alone grants no access and no capacity eligibility. Super Admin controls team count and team staffing; self-assignment is prohibited. Verification must cover UI, API, database constraints, RLS/privileged commands and audit events. Inspector cap eligibility remains the T-14 distinct enabled account + active Inspector role + effective operational assignment predicate.



## T-15 traceability — approved INS-016 audit policy (2026-11-24)

Trace critical business/security/governance commands to an append-only audit event committed atomically with the state mutation. Audit-write failure must fail closed and roll back the mutation. Trace actor, active role, scope, action/event, timestamp, correlation/idempotency reference and privacy-safe change context through command contract, database schema, RLS/grants and QA. Sensitive evidence access/export must be auditable; ordinary application roles cannot alter or delete audit events; audit read/export is least-privilege. T-10 institutional decisions still govern classification, retention, deletion/disposition, legal hold and network metadata. PO approval is recorded; implementation, institutional approvals and test execution remain pending.


## T-16 traceability update (PO-approved option B, 2026-11-24)

Trace T-16 through PRD INS-002, canonical unit identity in the ERD, physical unique key `(instrument_id, serial_normalized)` across all projects, claim-unit transaction behavior, controlled cross-project duplicate resolution, immutable evidence-to-revision/instrument-version linkage, audit events, and TC-UNIT-016/TC-EVD-016 tests. Different instrument types may reuse the same serial. Project authorization must remain scoped even where the canonical unit is referenced by multiple projects. The association/FK/claim model is now documented for technical review; institutional normalization/exception policy, implementation and test execution remain pending.


T-17 decision traceability: Super Admin direct publication is authorized only through a trusted server command that derives the actor from the authenticated session, checks explicit `instrument.publish`, validates the complete declarative version and atomically records publication plus audit. No second-person publication approval is required. Published configuration cannot be edited in place. Operational access to units/inspections remains project/session/assignment/permission-scoped even though canonical unit identity is cross-project. T-16 association/schema pattern is now specified; technical review and institutional serial policy remain pre-migration dependencies.


## T-18 traceability — PO-approved command architecture (2026-11-24)

Trace every state-changing business/governance command from browser action through Vercel route, verified Supabase caller session, caller-JWT PostgreSQL function, database-derived actor (auth.uid()), explicit permission/role/scope/assignment/state/separation-of-duties checks, concurrency/idempotency controls and atomic state + event/audit transaction. Verify protected-table browser INSERT/UPDATE/DELETE is denied by grants/RLS; caller JWT is propagated rather than replaced with service-role identity; service-role secrets never reach the browser; SECURITY DEFINER functions pin search_path and have reviewed minimal grants; typed outcomes do not leak sensitive details. Include T-15 audit rollback behavior and T-17 instrument publish/deactivate commands. Cross-project canonical unit identity must not widen project authorization; reconcile T-16 associations before migration. Architecture approval is recorded; implementation, RLS deployment and test execution remain pending.


## T-16 canonical unit/project association traceability (design reconciliation)

Trace `units` as a project-independent canonical physical identity keyed by `(instrument_id, serial_normalized)` for known serials; `unit_project_associations` as the durable project-membership relation; `unit_identity_conflicts` as the controlled same-type duplicate workflow; and inspections/claims as bound to exact association + project + same-project assignment. Verify composite foreign keys, assignment instrument consistency, global one-active-claim-per-unit constraint, lock order, idempotency and atomic audit through T-18 command functions. Verify RLS never treats `unit_id` as a grant and that all inspection/evidence access resolves through association, session, assignment and permission. Required QA coverage is TC-UNIT-016-001..018 and TC-EVD-016-001..004. T-16 PO uniqueness decision is approved; relational association design is now specified for review; institutional exception/normalization policy, implementation and executable verification remain open. No migration or code is authorized.


## RBAC-004 implementation boundary

The proposed Canonical Permission Registry and Command Authorization Matrix v0.1.0 is the single draft vocabulary baseline. It does not approve code semantics, legacy mappings, role grants, grantor authority, scope, SoD, permission seed, RLS, PostgreSQL EXECUTE grants or implementation. Those approvals and evidence remain required before scope freeze.

## SEC-006 — Live Supabase security inventory

Before implementation, collect and review a read-only live database inventory covering project/environment identity, PostgreSQL version, roles/memberships, schema/table/routine/sequence ownership and ACLs, RLS flags/policies, function exact signatures/owners/security modes/search_path/EXECUTE ACLs, default privileges, views/triggers, Storage policies and Dashboard exposure/backup configuration. Evidence and acceptance criteria are defined in [Supabase Live Database Security Inventory Runbook](../02-architecture/SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md). Status: NOT EXECUTED; no live database connector/session available in this workspace. Repository-only design review does not satisfy SEC-006. T-18 execution-model selection is PO APPROVED Option A; deployed function/role/ACL conformance remains unverified. Implementation remains NOT AUTHORIZED.

## SEC-006 — Live Supabase security inventory verification cases

QA cases TC-LIVE-INV-026-001..010 define the evidence checks for target environment/version, role/membership, ownership/schema ACL, table ACL/RLS, function/EXECUTE inventory, SECURITY DEFINER owner hardening, default ACL/inheritance, views/triggers/sequences, Storage policies and Dashboard/provider controls. All 10 are PLANNED / NOT EXECUTED pending an approved read-only live database session. See the Supabase Live Database Security Inventory Runbook. This is a metadata audit only and does not authorize schema or privilege changes.



## SEC-007 — Application repository runtime implementation evidence

T-19 read-only tree audit on 2026-11-24 found 54 blobs on `docs/t17-instrument-governance-t18-command-boundary`, limited to `AGENTS.md`, `README.md` and `docs/`; zero source/configuration files were found in the scanned implementation extensions. The default branch `main` contained only `README.md` at the inspected ref. Therefore Vercel route handlers, Supabase client separation, caller-JWT propagation, migrations, PostgreSQL functions/grants/RLS, CI tests and deployment configuration cannot be verified in this repository. This is an absence-of-evidence finding, not a code defect or proof that no implementation exists elsewhere. Confirm the canonical application repository/branch before implementation or further runtime claims. See [T-19 Repository Runtime Architecture Audit](../02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md). QA cases TC-REPO-AUDIT-028-001..008 are BLOCKED / NOT EXECUTED. Scope freeze remains NOT READY; implementation remains NOT AUTHORIZED.

## INS-015 notification traceability — NLA-001 (2026-11-24)

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-001 | Notification intent is durable and created atomically with source event/audit | INS-015; INS-016; T-18 | NLA-001 v0.1.4 §3, §8; notification_outbox | TC-NOTIF-001..003, TC-NOTIF-022 | DESIGN PROPOSED; REVIEW OPEN |
| NOTIF-002 | In-app inbox is recipient-self scoped; source resource is re-authorized | INS-015 | NLA-001 §4.3, §5, §9 | TC-NOTIF-004..006, TC-NOTIF-018 | DESIGN PROPOSED; SECURITY REVIEW OPEN |
| NOTIF-003 | Delivery and read state are independent; retries are idempotent | INS-015 | NLA-001 §3.2, §4.4–4.5, §7 | TC-NOTIF-007..011, TC-NOTIF-015, TC-NOTIF-021..024, TC-NOTIF-026 | DESIGN PROPOSED; PROVIDER/WORKER REVIEW OPEN |
| NOTIF-004 | Policy configuration is versioned, validated and audited | INS-015 | NLA-001 §4.1, §8–9 | TC-NOTIF-012, TC-NOTIF-016, TC-NOTIF-020 | DESIGN PROPOSED; PO/SECURITY APPROVAL OPEN |
| NOTIF-005 | SLA reminders/escalations are idempotent and never mutate inspection state | INS-015 | NLA-001 §4.6, §7 | TC-NOTIF-013..014, TC-NOTIF-025 | DESIGN PROPOSED; POLICY REVIEW OPEN |
| NOTIF-006 | Channels are in-app, optional push and important email; no WhatsApp MVP | INS-015 | NLA-001 §2, §6 | TC-NOTIF-008, TC-NOTIF-015..017, TC-NOTIF-023..024 | PO DIRECTION APPROVED; PROVIDER/OPERATIONS REVIEW OPEN |

## T-13 batch print traceability update

T-13 requires a durable batch identifier and per-document outcomes. The physical design now includes `print_batches` and extends `print_events` with batch linkage, outcome and append-only attempt semantics. Verify bounded batch size, partial outcomes, failed-only retries, idempotency, concurrency and no physical-printer-success claim. Related planned test series: TC-CMD-CONTRACT-024-038 and DOC-PRINT; exact cases remain to be allocated and executed.

## T-13 print batch verification traceability — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| PRINT-BATCH-001 | Bounded batch persists durable batch identity and per-document outcomes with partial-result semantics | T-13 PO APPROVED option B | API and Transaction Contracts §6; Physical Database Schema; NLA-001 §13; CMD-038 | TC-PRINT-BATCH-001..008 | DESIGN RECORDED; TECH REVIEW OPEN |

## Lock protocol PO decision traceability — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| UNIT-IDENTITY-001 | A physical unit is globally canonical by (instrument_type, serial_normalized) across projects; same-type collisions are controlled conflicts with authorized reasoned resolution and immutable history. | T-16; LPR-02 PO APPROVED | PRD §6; Inspection Lifecycle; Physical Database Schema; LOCK-PROTOCOL-DECISION-RESOLUTION §4.1 | Canonical normalization, cross-project duplicate, cross-instrument reuse, conflict authorization/audit and historical-link tests; exact QA IDs to be assigned | PO APPROVED; TECHNICAL/POLICY/VERIFICATION OPEN |
| CLAIM-001 | Every normal inspection requires a valid active claim bound to the canonical unit and applicable project/session/assignment; no implicit bypass. | INS-005; LPR-03 PO APPROVED | Inspection Lifecycle; CMD-026..032; LOCK-PROTOCOL-DECISION-RESOLUTION §4.2 | No-claim denial, expired/released claim, cross-assignment denial, authorized correction/migration exception and audit tests; exact QA IDs to be assigned | PO APPROVED; COMMAND/PERMISSION/VERIFICATION OPEN |
| LIFECYCLE-FENCE-001 | CLOSED project/session rejects new normal mutations and finalization; reopening is a separately privileged, reasoned and audited workflow. | T-06/T-07; LPR-04 PO APPROVED | Project Session and Assignment Model; CMD-009..013; LOCK-PROTOCOL-DECISION-RESOLUTION §4.3 | Closure races against every child writer/finalizer, in-flight worker fencing, reopen authorization and audit tests; exact QA IDs to be assigned | PO APPROVED; LOCK GRAPH/COMMAND/VERIFICATION OPEN |
| CAP-002 | T-14 counts distinct login-enabled accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment in governed project/session scope; all eligibility-changing paths share one serialization point. | T-14; LPR-05 PO APPROVED clarification | Decision Register T-14; Project Session and Assignment Model; LOCK-PROTOCOL-DECISION-RESOLUTION §4.3 | Predicate parity, deduplication, eligibility changes concurrent with capacity changes, combined 1–100 cap/default 50 and no silent deactivation tests; exact QA IDs to be assigned | PO APPROVED; PATH AUDIT/CONCURRENCY/VERIFICATION OPEN |
| INSTRUMENT-DEACTIVATION-001 | Deactivation blocks new assignment selection while already-pinned sessions retain immutable historical versions by default; safety withdrawal is an explicit authorized, reasoned and audited override. | INS-001/CFG-001; LPR-06 PO APPROVED | PRD; Instrument Specification; CMD-014/018..021; LOCK-PROTOCOL-DECISION-RESOLUTION §4.4 | Assignment/deactivation race, pinned historical version retention, explicit safety withdrawal scope and audit tests; exact QA IDs to be assigned | PO APPROVED; AUTHORITY/LOCK/VERIFICATION OPEN |

**Traceability boundary:** PO approval settles the product requirements above, not the technical lock order, physical constraints, function/trigger graph, privileges, RLS or test execution. LPR-01 and LPR-07–LPR-11 remain open; G9 is NOT READY and G10 is NOT AUTHORIZED.


## CMD-011–020 Product Owner decision traceability — 2026-11-24

| Requirement ID | Approved requirement | Authority | Design reference | Verification anchor | Status |
|---|---|---|---|---|---|
| SES-011 | Session creation uses server-selected T-07 DRAFT; project lifecycle gate; UTC instants with canonical project IANA timezone; reject DST gap/fold input; overlap not prohibited by default | PO CMD-011; T-07 | Decision Register; CMD-011–020 decision package; Project/Session/Assignment Model | TC-CMD-CONTRACT-024-011 | PO APPROVED; CONTRACT/TECHNICAL REVIEW OPEN |
| SES-012 | Session code immutable; allowlisted metadata only; reason required; reject schedule reinterpretation after dependent work exists | PO CMD-012 | Decision Register; CMD detailed review | TC-CMD-CONTRACT-024-012 | PO APPROVED; CAS/DEPENDENCY PREDICATE OPEN |
| SES-013 | T-07 state set preserved; closure request is action/event; Korlap scope limited; Super Admin final closure; CLOSED terminal in ordinary flow; reopen privileged/reasoned/audited | PO CMD-013; T-06/T-07 | Decision Register; Project/Session/Assignment Model | TC-CMD-CONTRACT-024-013 | PO APPROVED; TRANSITION/LOCK/SECURITY REVIEW OPEN |
| ASN-014 | One create-only atomic assignment + complete roster; half-open interval; scoped effective membership conflict predicate | PO CMD-014 | Decision Register; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-014 | PO APPROVED; CAPACITY/PARENT-FENCE REVIEW OPEN |
| ASN-015 | Per-member effective_at; reasoned end-dating; no hard delete; submitted inspections remain unchanged after removal | PO CMD-015 | Decision Register; Project/Session/Assignment Model | TC-CMD-CONTRACT-024-015 | PO APPROVED; ACTIVE-WORK POLICY OPEN |
| CAP-016 | T-14 predicate unchanged; cap 1–100/default 50; reject below count; no silent role/assignment revocation | PO CMD-016; T-14 | Decision Register; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-016 | REAFFIRMED; TECHNICAL SERIALIZATION OPEN |
| TGT-017 | Session-scoped target plans by default; explicit draft/replace/publish actions; unique allocation triple; reject zero; immutable published versions | PO CMD-017 | Decision Register; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-017 | PO APPROVED; QUANTITY/CAS CONTRACT OPEN |
| INS-018 | New instrument draft/inactive until published; normalized unique code using approved normalization direction | PO CMD-018 | Decision Register; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-018 | PO APPROVED; ALPHABET/COLLATION SECURITY REVIEW OPEN |
| INS-019 | Atomic complete declarative draft replacement; immutable published snapshot; change summary; no dynamic code/arbitrary regex/unbounded recursion | PO CMD-019 | Decision Register; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-019 | PO APPROVED; SCHEMA/HASH/CAS SECURITY REVIEW OPEN |
| INS-020 | T-17 explicit instrument.publish, immutable published versions, pinned assignments/sessions, new version for corrections and idempotent no-duplicate publication | PO CMD-020; T-17 | Decision Register; T-17; CMD-011–020 detailed review | TC-CMD-CONTRACT-024-020 | REAFFIRMED; FUNCTION/ACL/HASH REVIEW OPEN |

**Traceability boundary:** The requirements above close PO product-semantic decisions only. They do not approve role grants, physical schema, lock order, function ACLs, RLS, concurrency safety or tests. Every referenced case remains PLANNED / NOT EXECUTED. G9 NOT READY; G10 NOT ACTIVE.


## Engineering/Security technical lock resolution traceability — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| LOCK-ORDER-001 | Every transaction acquires all invariant-bearing resources in one approved total order; no lower-ranked resource is acquired after a higher rank; implicit FK/index/trigger/helper edges are included | Engineering + Database + Security approval required; TECH-RESOLUTION-LPR-001 proposal | LOCK-PROTOCOL-DECISION-RESOLUTION; GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH; COMMAND-LEVEL-LOCK-MANIFEST | Complete effective lock graph, manifest review, reverse-order pair tests and deadlock diagnostics | PROPOSED; TECHNICAL APPROVAL OPEN |
| AUTH-LOCK-001 | Account, role and scope authorization state is serialized consistently with T-14 capacity and scoped project/session/assignment operations | LPR-11; Engineering + Security | TECH-RESOLUTION-LPR-001 §3.1; CMD-001–007 and CMD-014–016 manifests | Grant/revoke/account-state races against protected commands; stale authorization negative tests | PROPOSED; TECHNICAL APPROVAL OPEN |
| PARENT-FENCE-001 | Project/session child writers and finalizers acquire parent fences before child rows; closure and parent updates use conflicting lock modes and revalidate blockers | T-06/T-07; LPR-04; Engineering/Database/Security | TECH-RESOLUTION-LPR-001 §4; CMD-009–015 | Deterministic closure-vs-child/finalizer concurrency tests on deployed PostgreSQL major | PROPOSED; TECHNICAL APPROVAL OPEN |
| WORKER-FENCE-001 | Asynchronous workers use least-privilege identities, durable leases and monotonic fencing generations; external I/O occurs outside database locks; finalizers revalidate source and parent state | LPR-08; Security + Operations + provider owner | TECH-RESOLUTION-LPR-001 §6; NLA-001; command-specific worker contracts | Lease expiry/reclaim, stale worker, callback authenticity/replay and provider unknown-outcome tests | PROPOSED; SECURITY/OPERATIONS APPROVAL OPEN |
| LOCK-MANIFEST-001 | All 54 command/worker paths have complete ordered resource, lock mode, implicit edge, competing writer, revalidation, retry and test evidence manifests | LPR-09; Engineering + Database + Security + QA | COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054; CMD-001–010 Detailed Contract Review §9; TECH-RESOLUTION-LPR-001 §7 | 54/54 normalized and reviewed; certification evidence per command | 54/54 INVENTORIED; 10/54 CANDIDATE-NORMALIZED; 0/54 TECHNICALLY APPROVED/CERTIFIED |
| CONCURRENCY-TEST-001 | Adversarial concurrency tests prove shared invariants and safe retry behavior on exact schema/code/environment | LPR-10; Engineering + QA + Security | TECH-RESOLUTION-LPR-001 §8 | Reproducible test run with barriers, SQLSTATE/lock diagnostics and final invariant assertions | NOT EXECUTED |


## CMD-001–010 candidate lock-manifest traceability — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| AUTH-LOCK-002 | Account approval, role grant/revoke and scope grant/revoke must serialize actor/target identity and exact mutable authorization grants; actor/target rows use deterministic UUID order and grantor authority is revalidated under lock | LPR-11; Engineering + Security; PO/institution for lifecycle policy | CMD-001–010 Detailed Contract Review v0.3.4 §9; LOCK-GRAPH-001 v0.4.10; LOCK-MANIFEST-001 v0.4.13 | Approve/reject, grant/revoke, scope grant/revoke, stale grantor and target eligibility adversarial tests | CANDIDATE-NORMALIZED; TECHNICAL APPROVAL OPEN |
| CAPACITY-LOCK-001 | Every account/role/scope/assignment path that changes T-14 qualifying Inspector population locks the complete affected project capacity set before principal/role rows | T-14; LPR-05; Engineering + Security + PO | CMD-001–010 Detailed Contract Review v0.3.4 §9.1–9.3; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.8; TECH-RESOLUTION-LPR-001 §3.2 | Cross-command capacity race tests and post-lock affected-project-set revalidation | CANDIDATE-NORMALIZED; PREDICATE/WRITER SET OPEN |
| PROJECT-FENCE-001 | Project update/closure serializes against every child writer/finalizer using project parent FOR NO KEY UPDATE versus child FOR SHARE candidate modes | T-06; LPR-04; Engineering/Database/Security | CMD-001–010 Detailed Contract Review §9.2; LOCK-GRAPH-001 §19; LOCK-PROTOCOL-DECISION-RESOLUTION §14 | Project close vs CMD-011–054 writer/finalizer barrier tests on exact PostgreSQL major | CANDIDATE-NORMALIZED; TECHNICAL APPROVAL OPEN |


**Source baseline:** CMD-001–054 Cross-Command Reconciliation v0.8.8; QA Catalogue v0.3.3; DGA-001 v1.11.15. These references document candidate lock normalization only; no technical approval or execution evidence is inferred.


## CMD-045–048 authority and control-plane traceability — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| RET-001 | Retention/legal-hold/disposition are institutional records-governance responsibilities, not executable application commands; application must not initiate destructive disposition or release holds | T-10; institutional records/legal/privacy/security authorities; PO approval of CMD-045–048 proposal (2026-11-24) | CMD-045–048 Resolution Proposal §2/4.1; Decision Register T-10 and CMD-045–048 decision | Institutional policy, retention/hold/disposition authority, backup/object treatment and external control evidence; no application-command tests | APPLICATION SCOPE RESOLVED — INSTITUTIONAL T-10 GATE BLOCKED |
| INC-001 | Security incident response is handled by the institution-designated incident-response control plane; no app case CRUD, generic reviewer permission or implicit mitigation | Institutional security authority; incident-response owner; T-10 where records/privacy apply | CMD-045–048 Resolution Proposal §2/4.2; Detailed Contract Review §5 | Incident RACI, escalation/on-call, evidence custody and privacy/legal handoff evidence | APPLICATION SCOPE RESOLVED — INCIDENT RACI OPEN |
| PROV-001 | Provider configuration is outside the application command surface; provider-native controls and institution-approved secret management are authoritative; no app secret/configuration CRUD | T-12; institution/provider custodians; PO approval of CMD-045–048 proposal (2026-11-24) | CMD-045–048 Resolution Proposal §2/4.3; Decision Register T-12; DGA-B05 | Signed account/billing/custodian RACI, region/plan/quotas, budget, secret manager, recovery entitlements and restore evidence | APPLICATION SCOPE RESOLVED — T-12 EVIDENCE BLOCKED |
| REL-001 | Production release authority is enforced by protected repository/deployment control planes; no application deployment/rollback command may bypass them | MIB-001; repository administrator; Operations/Security; PO approval of CMD-045–048 proposal (2026-11-24) | CMD-045–048 Resolution Proposal §2/4.4; Detailed Contract Review §7; DGA-B15 | Rulesets, required CI, protected environments, artifact provenance, operator/approver SoD, migration and rollback evidence | APPLICATION SCOPE RESOLVED — RELEASE GOVERNANCE OPEN/BLOCKING |

These requirements are governance/architecture traceability records, not implementation authorization. All related tests remain PLANNED / NOT EXECUTED.


## Notification command-control traceability addendum — 2026-11-24

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-007 | CMD-052/053 workers use a least-privilege workload identity and durable owner/token-hash/generation/expiry fencing; stale workers cannot finalize after lease reclaim; CMD-052 reuses the approved immutable event-time candidate audience and may only suppress candidates after dispatch-time revalidation | T-18; LPR-08; POQ-01; Security/Operations | NLA-001 v0.1.4 §3/4.3/5/14/15; CMD-049–054 review v0.1.3; LOCK-MANIFEST-001 | TC-NOTIF-002/003/015/021/022 and new audience non-widening case | PO SEMANTICS APPROVED; SNAPSHOT/WORKER IDENTITY/ACL DESIGN OPEN |
| NOTIF-008 | Provider callbacks are accepted only through INT-NOTIF-001 with provider authentication, freshness, known delivery reference, durable event deduplication and monotonic status transitions | T-18; provider security authority | NLA-001 v0.1.4 §9/14; API and Transaction Contracts §INT-NOTIF-001 | TC-NOTIF-023/024/026; signature/replay, unknown reference, out-of-order callback and UNKNOWN reconciliation | PROPOSED; PROVIDER SELECTION/AUTHENTICATION OPEN |
| NOTIF-009 | CMD-051 publishes only a validated immutable policy version using server-canonical hash and expected-current-version comparison; no draft CRUD or role grant is inferred | INS-015; T-18 | NLA-001 v0.1.4 §10/14; CMD-049–054 review v0.1.3 §7; permission registry | TC-NOTIF-012/020; schema allowlist, stale publish, concurrent version allocation, immutability | PROPOSED; PERMISSION/SCOPE/SoD APPROVAL OPEN |
| NOTIF-010 | CMD-054 uses one database-derived UTC instant per evaluation; no caller-supplied evaluation_time; due checks remain pinned to policy version. POQ-02 approves per-policy elapsed/business-time semantics, initial default ELAPSED_UTC, and quiet hours as delivery deferral only | INS-015; T-18; POQ-02 | NLA-001 v0.1.4 §7/14/15; CMD-049–054 review v0.1.3 | TC-NOTIF-013/014/025 plus explicit quiet-hours-do-not-pause-SLA case | PO SEMANTICS APPROVED; START EVENT/CALENDAR/PAUSE RULES AND EXECUTION OPEN |
| NOTIF-011 | Notification content and operational metadata are minimized; no evidence, message body, token, secret, signed URL or full provider response enters general audit/logs; T-10 controls retention/disposition | T-10; INS-016 | NLA-001 v0.1.4 §8/14; Audit Event Catalogue; Evidence Privacy Specification | TC-NOTIF-016 and privacy/retention review | BLOCKED — INSTITUTIONAL T-10 APPROVAL |
| NOTIF-012 | Inbox reads are recipient-self only; read_at is set once; first transition emits one notification.read event; delivery and source business state remain independent. Dismiss/archive is excluded from MVP; dismissed_at is dormant and no dismiss operation is exposed | INS-015; INS-016; T-15; POQ-03 | NLA-001 v0.1.4 §5/8/14/15; CMD catalogue CMD-049/050; RLS catalogue | TC-NOTIF-005/007/019/024; negative dismiss-surface check | PO SEMANTICS APPROVED; RLS/AUDIT IMPLEMENTATION VERIFICATION OPEN |

All notification cases TC-NOTIF-001..040 remain PLANNED / NOT EXECUTED. These requirements do not approve any route, function, worker, provider, permission grant, schema object or production activation.


## Identifier uniqueness audit correction — 2026-11-24

The final documentation audit detected a duplicate requirement identifier in the appended lock traceability section. The general authorization serialization requirement retains AUTH-LOCK-001; the detailed CMD-001–010 actor/target/grantor lock requirement is now AUTH-LOCK-002. Requirement statements and statuses are unchanged. AUTH-LOCK IDs are unique within this matrix.


## Cross-document governance audit checkpoint — 2026-11-24

The SSOT cross-document audit confirms 125 unique requirement IDs. Package S §9.15 remains a historical snapshot and is superseded for current inventory/status by Package S §9.16 and DGA-001 v1.11.23. Package T v0.1.1 remains a historical decision pack; the Decision Register remains the canonical PO decision index.

T-13 verification traceability is now explicit:
- TC-PRINT-001..007: general print permission, batch behavior, retry, concurrency and physical-output boundary.
- TC-PRINT-BATCH-001..008: durable batch identity, per-document projection, scope, partial outcomes, retry, sequence, idempotency and output semantics.
- TC-DOC-009..011: Standing Bracket annex and IFP document cases; not a print-batch range.

No test was executed. This is a traceability correction only and does not change T-13 product semantics or authorize implementation.

### NOTIF-013 — dismissal exclusion

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-013 | MVP has no dismiss/archive command, permission, browser write or UX action; only recipient-owned set-once read_at is supported | INS-015; POQ-03 | NLA-001 v0.1.4 §15; CMD-049–054 review v0.1.3; RLS and API catalogues | TC-NOTIF-029; static API/permission/UX absence review | PO APPROVED; CROSS-DOCUMENT IMPLEMENTATION DESIGN REVIEW OPEN |


## Product Owner notification decisions — POQ-001 (2026-11-24)

POQ-01 Option C, POQ-02 Option C and POQ-03 Option A were explicitly approved by the Product Owner on 2026-11-24 and are recorded in the Decision Register. These approvals close the three product-semantic questions only:

- **Audience (POQ-01):** persist the event-time candidate audience and authorized source scope/checkpoint; fan-out/retries reuse it; dispatch-time account/channel/consent/revocation checks may suppress candidates but must never widen the audience.
- **SLA (POQ-02):** immutable policy versions declare elapsed or business-time semantics; initial default is `ELAPSED_UTC`. Quiet hours defer delivery only and do not pause/stop/reset the SLA clock. Business calendars, time zones and pause/reset conditions need explicit policy specification before activation.
- **Dismissal (POQ-03):** dismiss/archive is excluded from MVP. Only recipient-owned set-once `read_at` is exposed; no dismiss command, permission, browser write or UX action exists. Any `dismissed_at` field retained in a proposal is dormant.

The following technical details remain open: exact selector grammar and snapshot/checkpoint representation; partial fan-out fencing; policy schema and worker authorization; provider capability/callback security; exact schema constraints/indexes/RLS; institutional T-10 retention/privacy; test execution and live evidence. G9 remains NOT READY and G10 NOT ACTIVE.


## NOTIF-014/015 — audience snapshot physicalization and lock-order evidence

| Requirement ID | Requirement | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-014 | For each notification-producing source event, persist a deduplicated immutable recipient and authorized source-scope candidate set bound to the event and policy version before the source transaction commits. CMD-052/054 retries consume only that set; dispatch-time account/channel/consent/security checks may suppress but never add recipients. | POQ-01 APPROVED; INS-015 | NLA-001 v0.1.4 §15–17; physical schema v0.4.4 candidate annex; RLS v0.2.5; ERD v0.3.3; CMD-049–054 review v0.1.3 | TC-NOTIF-027/030–035; TC-RLS-024-049; source snapshot hash/count, duplicate selector, retry, revocation and scope integrity evidence | PO SEMANTICS APPROVED; PHYSICAL CANDIDATE NOT ADMITTED; ENGINEERING/DB/SECURITY REVIEW OPEN |
| NOTIF-015 | Notification snapshot writers, CMD-052 fan-out, CMD-054 scheduler and CMD-053 callback ingress must include all source/recipient/scope/queue/policy locks and implicit FK KEY SHARE/unique-index/trigger/helper edges in the global resource order; no lower-rank resource may be acquired after a higher-rank lock. | LPR-09; T-18; Engineering/Database/Security | LOCK-MANIFEST-001 v0.4.26 §7.6; LOCK-GRAPH-001 v0.4.19 §27; CMD-049–054 review v0.1.3 §17; RAID R-037 | TC-NOTIF-036–040; LG-41–45; exact PostgreSQL lock traces, deterministic concurrency tests and full acyclic graph proof | OPEN — CRITICAL; 0/50 LOCK-CERTIFIED |

All related notification and concurrency tests remain PLANNED / NOT EXECUTED. These requirements do not approve a new table, migration, index, RLS policy, worker identity, function, grant or implementation. G9 remains NOT READY; G10 remains NOT ACTIVE.


### NOTIF-015 resolver lock-set evidence pointer — 2026-11-24

[NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001](../02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) v0.1.5 classifies the complete 40-command source inventory and identifies 0/40 resolver paths with certified complete audience locks. Candidate options are a global transaction-scoped L05 guard or a fully participating SERIALIZABLE predicate protocol; neither is approved. NOTIF-015 remains OPEN — CRITICAL pending PO event-time semantics, Engineering/Database/Security mechanism approval, complete writer participation, exact FK/index/trigger/function graph, acyclicity proof and NRL-T01..T10 runtime evidence. Related QA remains PLANNED / NOT EXECUTED; application lock certification 0/50.


### NOTIF-015 resolver test mapping — 2026-11-24

QA v0.4.4 maps recipient-resolver lock-set verification to TC-NOTIF-042..051. These cases complement TC-NOTIF-036..040 (LG-41..45) and remain PLANNED / NOT EXECUTED. NOTIF-015 remains OPEN — CRITICAL; no resolver mechanism, new lock rank, candidate relation or command lock path is certified.


### NOTIF-015 resolver mechanism selection — 2026-11-24

PO selected Option A (global transaction-scoped audience guard, candidate L05) as the primary mechanism to submit for technical approval; Option B SERIALIZABLE remains contingency-only. See [NLA-RESOLVER-LOCK-001 v0.1.6](../02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) §11. NOTIF-015 remains OPEN — CRITICAL until Engineering/Database/Security approve the primitive/key, canonical order, full writer participation, FK/trigger/helper graph, timeout/retry, contention limits and acyclicity evidence. No L05 rank or implementation is approved; resolver certification 0/40 and application lock certification 0/50.


### NOTIF-015 technical design checkpoint — 2026-11-24

[NLA-L05-TDR-001 v0.1.0](../02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) proposes the concrete L05 PostgreSQL transaction guard protocol. NOTIF-015 remains OPEN — CRITICAL pending Engineering/Database/Security approval, deployed isolation evidence, complete writer-to-command matrix, exact FK/trigger/helper topology, lock budgets, bounded audience/performance SLO and NRL-T01..T10 execution. L05 is not admitted; candidate snapshot relation/header remain NOT ADMITTED.


### NOTIF-015 current resolver and lock-order baseline — 2026-11-24

Current references: NLA-001 v0.1.10; NLA-RESOLVER-LOCK-001 v0.1.10; NLA-L05-TDR-001 v0.1.4; L05 source-event map v0.1.0; L05 eligibility-writer matrix v0.1.2; LOCK-MANIFEST-001 v0.4.30 §§7.7/7.13; LOCK-GRAPH-001 v0.4.23 §§28–30; QA Catalogue v0.4.6.

The CMD-031–040 candidate overlay is partial and does not certify any resolver path. The exact deployed writer set, selector grammar, FK/trigger/helper edges, worker identity/lease, attendance aggregate/version constraints and full graph acyclicity remain open. NRL-T01..T13 and TC-NOTIF-001..054 remain PLANNED / NOT EXECUTED. NOTIF-015 remains OPEN — CRITICAL; resolver certification 0/40; application lock certification 0/50; candidate snapshot relation/header NOT ADMITTED; G9 NOT READY; G10 NOT ACTIVE.


## F-05 technical acceptance traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design / control reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-016 | Every enabled notification event uses a versioned, deterministic, bounded selector grammar and explicit event allowlist; selector dependencies map to all eligibility-changing writers | POQ-01; POQ-04; Security/Engineering | NLA-L05-TDR-001 v0.1.7 §4.2.4 F05-T1; NLA-001 v0.1.13 §21; writer matrix v0.1.3 | TC-NOTIF-060/061; selector negative controls and selector-to-column/writer inventory | OPEN — SELECTOR GRAMMAR / DEPENDENCY UNIVERSE NOT FROZEN |
| NOTIF-017 | Dispatch revalidation distinguishes event-time recipient qualification from current delivery/security authorization and defines transition-specific parent/scope behavior | POQ-01; POQ-04; Security | NLA-L05-TDR-001 v0.1.7 §4.2.4 F05-T2; NLA-001 v0.1.13 §21 | TC-NOTIF-055/057/058/059/062; closure and revoke notice cases | OPEN — SECURITY/ENGINEERING VALIDATION REQUIRED |
| NOTIF-018 | Suppression/retry uses an exhaustive reason/state model; account reactivation can reconsider only the same immutable candidate and cannot clear unrelated restrictions or widen the audience | POQ-01; POQ-04 | NLA-L05-TDR-001 v0.1.7 §4.2.4 F05-T3; NLA-001 v0.1.13 §21 | TC-NOTIF-056/063; bounded retry, consent/channel/re-suspension negative controls | OPEN — RETRY/STATE CONTRACT NOT DEFINED |
| NOTIF-019 | Suppression and retry outcomes are append-only, correlated, privacy-minimized and auditable | INS-016; T-10; Security/Records/Privacy | NLA-L05-TDR-001 v0.1.7 §4.2.4 F05-T4; NLA-001 v0.1.13 §21 | TC-NOTIF-064; audit integrity, provenance, retention and minimization review | OPEN — AUDIT CONTRACT / INSTITUTIONAL RETENTION REVIEW REQUIRED |
| NOTIF-020 | Source mutation, canonical event, audit, idempotency result, outbox intent, pinned policy and complete immutable candidate set commit atomically at one captured audience_evaluated_at | POQ-01; POQ-04; T-18 | NLA-L05-TDR-001 v0.1.7 §4.2.4 F05-T5; L05 source map v0.1.0; writer matrix v0.1.3 | TC-NOTIF-055..064 plus transaction-boundary and rollback evidence | OPEN — SNAPSHOT RELATION/HEADER NOT ADMITTED; PRODUCER PATHS NOT CERTIFIED |

All TC-NOTIF-055..064 remain PLANNED / NOT EXECUTED. These requirements do not authorize implementation, SQL, migration, grants, RLS, runtime testing or G10 activation. F-05 remains OPEN; G9 NOT READY; G10 NOT ACTIVE.


## F-05 selector registry and dispatch profile traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-021 | Every enabled event has an exact canonical event-to-selector registry entry binding source transaction, grammar version, allowed clause kinds, participant/scope mapping, dependencies and dispatch profile; composite/conditional event declarations are split before enablement | INS-015; POQ-01; POQ-04; Security/Engineering | NLA-L05-TDR-001 v0.1.8 §4.2.5; NLA-001 v0.1.14 §22; source map v0.1.0 | TC-NOTIF-067/068; exact-token registry review and dependency completeness | OPEN — REGISTRY NOT ESTABLISHED |
| NOTIF-022 | Dispatch authorization is a versioned event-specific profile that separates event-time qualification from account/channel/consent/security/current-scope/parent-state checks; transition notices cannot be accidentally suppressed by revoked-role, ended-membership or active-parent predicates | POQ-04; INS-015; Security | NLA-L05-TDR-001 v0.1.8 §4.2.6; NLA-001 v0.1.14 §22 | TC-NOTIF-062/063/069; Security review of transition matrix and source-resource reauthorization | OPEN — SECURITY/ENGINEERING APPROVAL REQUIRED |

TC-NOTIF-065..070 supplement TC-NOTIF-055..064. All TC-NOTIF-055..070 remain PLANNED / NOT EXECUTED. Grammar v1, eight-clause bound, event registry and dispatch profiles are review candidates only. No implementation, SQL, migration, grants, RLS, runtime testing or G10 activation is approved.


## PO-approved event-candidate specification traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-023 | The notification registry contains only the eleven PO-approved first-batch candidate intents for specification/review; each remains NOT ENABLED until exact canonical source contract, trusted participant mapping, selector dependencies, dispatch profile, deduplication, atomicity and required technical approvals are complete | INS-015; PO event-candidate decision (2026-11-24); POQ-01; POQ-04 | NLA-EVENT-TRIAGE-001 v0.1.2; NLA-EVENT-REGISTRY-001 v0.1.0; NLA-001 v0.1.21 | TC-NOTIF-073/074; row-by-row registry admission evidence and negative publication tests | OPEN — SPECIFICATION CANDIDATES ONLY; TECHNICAL ADMISSION PENDING |

TC-NOTIF-073/074 remain PLANNED / NOT EXECUTED. PO approval does not authorize event publication, recipient/channel activation, implementation or G10. F-05/F-04/F-03/F-07 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.


## Account outcome event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-024 | Account outcome candidates must bind an exact CMD-002/003 producer transaction, canonical event schema/version and trusted participant projection; pre-transition snapshot selection must be explicitly separated from dispatch-time enabled-account suppression | INS-015; POQ-01; POQ-04; CMD-002/003; Security | NLA-EVENT-REGISTRY-001 v0.1.1; NLA-EVENT-TECH-RECON-001 v0.1.0 §§3–4; L05 source-event path map v0.1.0 | TC-NOTIF-073/075; exact source/participant/selector review | OPEN — ACCOUNT PARTICIPANT AND STATE-PREDICATE CONTRACT UNRESOLVED |
| NOTIF-025 | CMD-002/003 must serialize competing terminal decisions and atomically bind account mutation, immutable decision, canonical event, audit, idempotency and (only after admission) outbox/candidate snapshot; every account eligibility writer must participate in the approved L05 protocol | POQ-01; POQ-04; T-18; Security/Engineering/Database | NLA-EVENT-TECH-RECON-001 v0.1.0 §§3–5; LOCK-NORMALIZATION-001 v0.1.1; L05 writer matrix v0.1.4 | TC-NOTIF-076; command concurrency, atomic rollback, uniqueness and complete-writer evidence | OPEN — DECISION UNIQUENESS / WRITER COVERAGE / LOCK PROOF MISSING |

TC-NOTIF-075/076 remain PLANNED / NOT EXECUTED. NOTIF-024/025 are design/verification requirements, not implementation authorization. G9 NOT READY; G10 NOT ACTIVE.


## Role revocation event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-026 | `role.revoked` must snapshot only principals selected by the exact approved selector against pre-revoke role/scope state; actor is never implicit, and dispatch-time current-role/scope checks may suppress but never widen or rewrite the immutable candidate set | POQ-01; POQ-04; INS-015; CMD-005 | NLA-EVENT-REGISTRY-001 v0.1.2; NLA-EVENT-TECH-RECON-001 v0.1.1 §9; NLA-L05-TDR-001 v0.1.8 §4.2.2 | TC-NOTIF-077; target/self-revoke positive and negative selector cases | OPEN — EVENT PARTICIPANT / DISPATCH PROFILE UNRESOLVED |
| NOTIF-027 | CMD-005 must use an approved physical concurrency token or remove the unresolved expected_version request field; role transition, audit, idempotency and future admitted outbox/snapshot are atomic, with complete L05/L10 writer participation | POQ-01; POQ-04; T-14; T-18; Security/Database | NLA-EVENT-TECH-RECON-001 v0.1.1 §§9–10; LOCK-NORMALIZATION-001 v0.1.1; L05 writer matrix v0.1.4 | TC-NOTIF-078; stale-write, duplicate, capacity and writer-completeness evidence | OPEN — PHYSICAL CAS / WRITER / LOCK PROOF MISSING |

TC-NOTIF-077/078 remain PLANNED / NOT EXECUTED. NOTIF-026/027 do not authorize implementation or G10 activation.


## Project/session closure event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-028 | `project.closed` and exact final `session.closed` events must bind only to committed closure transitions; pre-close candidate audience and closure event commit atomically; `session.close_requested` is excluded from NREG-005 | POQ-01; POQ-04; T-07; CMD-010/013 | NLA-EVENT-REGISTRY-001 v0.1.3; NLA-EVENT-TECH-RECON-001 v0.1.2 §§12–13; L05 source-event path map v0.1.0 | TC-NOTIF-079/080; exact-token and transaction-boundary review | OPEN — FINAL EVENT CONTRACT / SNAPSHOT ADMISSION REQUIRED |
| NOTIF-029 | Closure dispatch uses an explicit event-specific current-scope rule; no universal active-parent predicate may accidentally suppress the closure notice; suppression never widens/replaces the snapshot or grants resource access | POQ-01; POQ-04; INS-015; Security | NLA-EVENT-TECH-RECON-001 v0.1.2 §§12–13; NLA-L05-TDR-001 v0.1.8 §4.2.2 | TC-NOTIF-080; closure dispatch matrix and independent source-resource authorization | OPEN — SECURITY/ENGINEERING PROFILE NOT APPROVED |
| NOTIF-030 | Project/session closure is serialized against every child writer/finalizer using compatible parent-first fences and physical concurrency tokens; closure gate set is complete and idempotent | T-07; CMD-010–015; T-18; Database/Security | NLA-EVENT-TECH-RECON-001 v0.1.2 §§12–15; LOCK-NORMALIZATION-001 v0.1.1 | TC-NOTIF-081; parent/child race, CAS, blocker completeness and rollback evidence | OPEN — PARENT FENCE / CAS / CHILD WRITER INVENTORY INCOMPLETE |

TC-NOTIF-079..081 remain PLANNED / NOT EXECUTED. NOTIF-028..030 do not authorize implementation or G10 activation.


## Assignment event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-031 | `assignment.created` must bind to one committed create-only transaction and a trusted event-participant projection for its complete initial roster; new members are not assumed to be pre-existing members in the pre-mutation state | POQ-01; POQ-04; CMD-014; Security | NLA-EVENT-REGISTRY-001 v0.1.4; NLA-EVENT-TECH-RECON-001 v0.1.3 §17 | TC-NOTIF-082; event-participant and complete-roster atomicity review | OPEN — NEW-MEMBER SNAPSHOT SEMANTICS UNRESOLVED |
| NOTIF-032 | `assignment.changed` must define exact added/ended/retained member event cardinality and selector mapping; ended membership is evaluated pre-end at one captured instant, with no replacement recipient | POQ-01; POQ-04; CMD-015 | NLA-EVENT-TECH-RECON-001 v0.1.3 §18; NLA-L05-TDR-001 v0.1.8 §4.2.2 | TC-NOTIF-083; member-delta and no-widening tests | OPEN — MEMBER-DELTA CONTRACT UNRESOLVED |
| NOTIF-033 | Ending assignment membership with active claims/in-progress inspections follows an explicit operational rule and never silently reassigns or deletes work | CMD-015; POQ/Operations | NLA-EVENT-TECH-RECON-001 v0.1.3 §§18–20 | TC-NOTIF-084; active-work ownership and recovery evidence | OPEN — ACTIVE-WORK POLICY UNRESOLVED |
| NOTIF-034 | Assignment/member writers, role/account eligibility writers and capacity updates share one approved L05/L10 serialization and atomic idempotent event/snapshot protocol | T-14; POQ-01; POQ-04; T-18; Database/Security | NLA-EVENT-TECH-RECON-001 v0.1.3 §§17–20; LOCK-NORMALIZATION-001 v0.1.1; L05 writer matrix v0.1.4 | TC-NOTIF-085; concurrency, capacity, lock-order and writer-completeness evidence | OPEN — GLOBAL WRITER / LOCK PROOF MISSING |

TC-NOTIF-082..085 remain PLANNED / NOT EXECUTED. NOTIF-031..034 do not authorize implementation or G10 activation.


## Inspection submit/return event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-035 | `inspection.submitted` is the sole PO-approved notice candidate for CMD-029; `inspection_revision.created` is a related immutable source fact and must not create a duplicate notice | PO event-candidate decision; POQ-01/04; CMD-029 | NLA-EVENT-REGISTRY-001 v0.1.5; NLA-EVENT-TECH-RECON-001 v0.1.4 §22 | TC-NOTIF-086; exact event cardinality and replay dedup | OPEN — SOURCE EVENT ID / DEDUP CONTRACT UNRESOLVED |
| NOTIF-036 | Submission notices target only a Reviewer selected through an approved physical assignment source and exact inspection scope; global role/title/project membership is insufficient | INS-015; CMD-029; Security/PO | NLA-EVENT-TECH-RECON-001 v0.1.4 §§22/24–25 | TC-NOTIF-087; wrong-scope and missing-assignment negative cases | OPEN — REVIEWER ASSIGNMENT SOURCE NOT ADMITTED |
| NOTIF-037 | Return-for-correction notices target only the exact approved responsible-Inspector participant; revision author/current assignment mapping is explicit and reviewer != author SoD remains enforced | PO event-candidate decision; CMD-030; Security | NLA-EVENT-TECH-RECON-001 v0.1.4 §23; canonical permission/assignment registry | TC-NOTIF-088; author/member/reviewer substitution negatives | OPEN — RESPONSIBLE INSPECTOR MAPPING UNRESOLVED |
| NOTIF-038 | Submission/review events are atomic with immutable revision/review facts, audit and idempotency; exactly one terminal review decision per revision; source lock order is globally compatible | T-18; CMD-029/030; Database/Security | NLA-EVENT-TECH-RECON-001 v0.1.4 §§22–25; LOCK-NORMALIZATION-001 v0.1.1 | TC-NOTIF-089; approve-vs-return race, replay, rollback and lock-order evidence | OPEN — DECISION UNIQUENESS / LOCK / SNAPSHOT PROOF MISSING |

TC-NOTIF-086..089 remain PLANNED / NOT EXECUTED. NOTIF-035..038 do not authorize implementation or G10 activation.


## Inspection approval/reopen event technical traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| NOTIF-039 | `inspection.approved` is emitted only for the exact current immutable submitted revision; approval actor/reviewer/revision author/responsible Inspector are not conflated | PO event-candidate decision; CMD-031; T-18 | NLA-EVENT-REGISTRY-001 v0.1.10; NLA-EVENT-TECH-RECON-001 v0.1.7 §27 | TC-NOTIF-090; exact revision and event identity/dedup evidence | OPEN — SOURCE EVENT / REVISION BINDING UNRESOLVED |
| NOTIF-040 | Approval recipient selection requires an approved persisted Reviewer/participant mapping and exact scope; reviewer != revision author; no generic role/title inference | CMD-031; Security/PO | NLA-EVENT-TECH-RECON-001 v0.1.7 §27 | TC-NOTIF-091; assignment, scope and SoD negatives | OPEN — REVIEWER ASSIGNMENT / PARTICIPANT MAPPING NOT ADMITTED |
| NOTIF-041 | CMD-030 return and CMD-031 approval serialize on one inspection aggregate and one terminal-decision-per-revision arbiter | CMD-030/031; physical integrity proposal; T-18 | NLA-EVENT-TECH-RECON-001 v0.1.6 §§27/29; LOCK-MANIFEST-001 §7.13; LOCK-GRAPH-001 §30 | TC-NOTIF-092; concurrent terminal-decision, audit rollback and retry evidence | OPEN — UNIQUE ARBITER / GLOBAL LOCK PROOF MISSING |
| NOTIF-042 | `inspection.reopened` requires explicit approved authority, exact scope and mandatory reason; next-action owner is explicitly mapped and not inferred | CMD-032; Decision Register; Security/PO | NLA-EVENT-TECH-RECON-001 v0.1.6 §28 | TC-NOTIF-093; role/grant/scope/reason negative cases | OPEN — REOPEN AUTHORITY / RECIPIENT MAPPING UNRESOLVED |
| NOTIF-043 | Reopen preserves immutable approved revision and downstream artifacts, creates at most one well-defined mutable draft context, and atomically snapshots the exact event-time audience | CMD-032; T-15/T-18; POQ-01/04 | NLA-EVENT-TECH-RECON-001 v0.1.6 §§28–29; LOCK-MANIFEST-001 §7.13 | TC-NOTIF-094; draft uniqueness, active-work/finalizer race and snapshot evidence | OPEN — DRAFT PHYSICAL MODEL / ACTIVE-WORK LOCK PROOF MISSING |

TC-NOTIF-090..094 remain PLANNED / NOT EXECUTED. NOTIF-039..043 do not approve event publication, recipient mapping, schema, implementation or G10 activation.


## Current CMD-031/032 source and schema cross-check — 2026-11-24

The physical schema v0.4.4 declares `review_events(id, inspection_revision_id, reviewer_id, decision, reason, created_at)`, append-only behavior, reviewer/author separation for approval and the invariant of one terminal decision per revision. It does **not** name a review-round/decision-sequence field or a concrete unique index/constraint that enforces the invariant. This is a documented invariant, not proof of an admitted database arbiter.

The source-event path map v0.1.0 and command lock manifest v0.4.30 still express inspection-aggregate-first candidate paths for CMD-030/031/032, while the candidate global graph §30 proposes reviewer/authorization and project/session/assignment/optional-claim context before the inspection aggregate. This ordering conflict remains explicit and unresolved; no proposed sequence is certified. LPR-01/LPR-07/LPR-09/LPR-11 remain OPEN; LPR-10 NOT EXECUTED; 0/50 lock certified.

## Inspection draft-context candidate traceability — 2026-11-24

| Requirement ID | Requirement / invariant | Authority | Design reference | Verification | Status |
|---|---|---|---|---|---|
| INS-021 | Mutable in-progress inspection work is held in a distinct draft context; submitted revisions remain immutable; one active context per inspection | PRD §6.3–6.4; WF-001/WF-002; INS-010; T-09; candidate design only | INSPECTION-DRAFT-001 v0.1.0; CMD-021–030 review §CMD-028/029; Physical Schema candidate annex | IDC-01..08, IDC-16, IDC-18..20; active-context uniqueness, stale write, submit atomicity, ACL and rollback | CANDIDATE PROPOSED — PO / ENGINEERING / DATABASE / SECURITY APPROVAL OPEN |
| REV-003 | Reviewer return preserves the submitted revision and creates a new correction draft context; resubmission creates the next immutable revision | WF-001 APPROVED; INS-010 APPROVED | PRD §6.4; INSPECTION-DRAFT-001 §5; CMD-030 | IDC-09..12, exact return reason, revision immutability, new revision and concurrent decision | PRODUCT DIRECTION BASELINED; PHYSICAL LIFECYCLE NOT APPROVED |
| REV-004 | Authorized reopen of the exact approved revision creates a new draft context and preserves approved history and downstream artifacts | WF-002 APPROVED; CMD-032 contract | INSPECTION-DRAFT-001 §6; CMD-031–040 review | IDC-13..15, exact approved revision, mandatory reason, active-work/finalizer race and history preservation | PRODUCT DIRECTION BASELINED; OWNER / CLAIM / PHYSICAL LIFECYCLE OPEN |
| EVD-004 | Evidence is captured against an active draft context and bound to the exact immutable revision at submit; evidence carry-forward is not inferred | T-16 PO APPROVED; CMD-033/034 | INSPECTION-DRAFT-001 §4; Physical Schema candidate annex | IDC-07, IDC-08, IDC-17, evidence checksum/version/context binding and carry-forward decision | CANDIDATE PROPOSED — INSTITUTIONAL EVIDENCE / PO / DATABASE APPROVAL OPEN |

These rows are candidate traceability entries only. They do not amend the approved PRD, change WF-001/WF-002/INS-010, approve a physical entity, or authorize implementation. IDC-01..20 are design acceptance IDs, not executed QA evidence. The formal QA catalogue/test IDs and requirement disposition must be reconciled after the candidate is reviewed.
