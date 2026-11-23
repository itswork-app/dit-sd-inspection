# Requirements Traceability Matrix — Dit. SD Inspection

Status: Baseline draft — requirements require source validation  
Purpose: Link product intent to specifications, implementation units, and verification evidence. This matrix is a control index, not a substitute for detailed specifications or test cases.

## Requirement ID convention

- **GOV:** governance and project constraints.
- **AUTH:** authentication and account lifecycle.
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
| AUD-001 | Audit coverage and controls require explicit approval before implementation | INS-016 proposal | Reports, Documents, Printing, Attendance, and Audit | Audit coverage/tamper tests | PROPOSED |
| OPS-002 | Production includes tested backup/restore, monitoring, deployment, and rollback | Engineering Governance | Performance and Operations Baseline | Restore drill and rollback evidence | REQUIRED; detail pending |
| PERF-001 | System is designed and load-tested for 100 concurrent authenticated users | PRD §14 | Performance and Operations Baseline | Load test at 10/25/50/75/100 users; latency, error, resource, and integrity report | BASELINED; thresholds pending |
| DATA-001 | PostgreSQL model preserves scoped relational integrity and immutable inspection revisions | PRD, functional decisions | Data Model and ERD | Migration, constraint, and immutability tests | DESIGN DRAFT |
| DATA-002 | Physical schema defines instrument catalog/versioning, serial identity, claims, revisions, evidence links, and transaction invariants | Package L | Physical Database Schema and Integrity Specification | Constraint, concurrency, immutability, and snapshot tests | DRAFT COMPLETE; PO ITEMS OPEN |
| CFG-001 | Super Admin can create/configure/version supported instrument types without code changes; active sessions and history retain frozen versions | Decision Register CFG-001 | PRD; Data Model and ERD; Physical Database Schema and Integrity Specification | Instrument configuration UAT; version freeze and historical snapshot tests | APPROVED; DESIGN DRAFT |
| SEC-001 | All exposed application data and evidence access are protected by server authorization and RLS | ADR-001, security decisions | RLS and Authorization Design; Security Threat Model | RLS matrix and negative authorization tests | DESIGN DRAFT |
| SEC-002 | Every application table and private Storage object class has an explicit deny-by-default policy and role/scope access matrix | Package M | Table-by-Table RLS Policy Catalogue | Staging RLS, RPC, view, and Storage positive/negative test matrix | DRAFT COMPLETE; REVIEW/EXECUTION OPEN |
| EVD-002 | Evidence uses private storage, verified upload lifecycle, and immutable originals | ADR-001, evidence decisions | Evidence Storage and Media Lifecycle | Upload, checksum, access-control, and recovery tests | DESIGN DRAFT |
| EVD-003 | Evidence privacy, classification, retention, legal hold, deletion and recovery are controlled and institutionally approved | Package O | Evidence Privacy, Retention, Deletion and Recovery Specification | Access, hold, expiry, deletion, object recovery and audit tests | DRAFT; INSTITUTIONAL APPROVAL BLOCKED |
| OPS-003 | Database and object backups have approved RPO/RTO and proven restore procedures | Package P | Backup, Restore and Disaster Recovery Plan | Isolated PostgreSQL + Storage restore drill and checksum reconciliation | DRAFT; PROVIDER VERIFICATION BLOCKED |
| OPS-004 | Production region, environments, secrets, quotas, billing and provider ownership are governed | Package Q | Production Environment, Secrets and Provider Governance | Environment isolation, secret scan, quota sheet, deployment/rollback and account review | DRAFT; SPONSOR APPROVAL BLOCKED |
| API-001 | Critical commands are idempotent and transactionally enforce claims, submission, approval, and capacity | Functional decisions | API and Transaction Contracts | Duplicate/retry/concurrency/transaction tests | DESIGN DRAFT |
| API-002 | Every privileged mutation executes through a trusted Vercel route and narrowly scoped PostgreSQL command boundary; browser direct DML is denied | Package N | Privileged Command Boundary and Transaction Specification | Forged-actor, direct-DML, RPC grant, and concurrency tests | DRAFT COMPLETE; APPROVAL OPEN |

## Instrument-specific traceability (pending official source validation)

| Requirement ID | Instrument | Requirement area | Known source coverage | Verification plan | Status |
|---|---|---|---|---|---|
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

Package N proposes the Vercel route + caller-JWT PostgreSQL command-function pattern. This is not yet approved or implemented.

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
|---|---|---|---|---|
| UX-001 | Role-based information architecture and scoped navigation | Information Architecture and Navigation | Role-based navigation and scope tests | DESIGN DRAFT |
| UX-002 | Mobile-first inspection flows with explicit save/sync states | Screen Flows and Wireframe Specification | Mobile E2E and usability UAT | DESIGN DRAFT |
| UX-003 | Consistent responsive and accessible UI components | Design System and Responsive UX | Responsive, keyboard, contrast, and screen-reader checks | DESIGN DRAFT |
| QA-001 | Layered quality gates for functional, security, data integrity, and recovery | Test Strategy and Quality Gates | CI and release evidence | DESIGN DRAFT |
| QA-002 | Traceable test cases for authorization, capacity, lifecycle, offline, documents, and reporting | Test Case Catalog and UAT | Executed test records and Product Owner sign-off | CATALOG DRAFT |


## Package R — Audit event catalogue and governance

| ID | Requirement | Specification | Verification | Status |
|---|---|---|---|---|
| AUD-001 | Material business, security, and governance actions use a canonical event envelope with actor, active role, scope, resource, outcome, and timestamp | Audit Event Catalogue and Governance | AUD-T01..T12 | DESIGN DRAFT; INS-016 approval pending |
| AUD-002 | Critical state changes and their audit event commit atomically; audit append failure rolls back the protected mutation | Audit Event Catalogue and Governance; Privileged Command Boundary | AUD-T01..T03 | DESIGN DRAFT |
| AUD-003 | Audit history is append-only for application roles; corrections use compensating events | Audit Event Catalogue and Governance; RLS Catalogue | AUD-T03, AUD-T11 | DESIGN DRAFT |
| AUD-004 | Audit payloads exclude secrets, signed URL tokens, raw media, and unnecessary personal data | Audit Event Catalogue and Governance; Evidence Privacy and Retention | AUD-T09 | DESIGN DRAFT |
| AUD-005 | Audit access/export, legal holds, retention disposition, and security administration are permissioned and audited | Audit Event Catalogue and Governance | AUD-T08, AUD-T10 | DESIGN DRAFT; institutional approval pending |

New source evidence: the 23-November Standing Bracket form and 20-November BA are reconciled in the Standing Bracket Instrument Specification and Instrument Requirements Verification Matrix. The Product Owner confirmed the 23-November document as the official Standing Bracket instrument source on 2026-11-23. Its 19-row checklist (6 physical + 13 accessories) is the project baseline; the earlier screenshot transcription remains a separate observation to be mapped without silent merging. The BA sample supports serial-annex/count-reconciliation requirements but does not approve signatory policy.


## Package S — Final audit disposition

| ID | Requirement / gate | Audit artifact | Verification / approval evidence | Status |
|---|---|---|---|---|
| GOV-005-S | Cross-document baseline must be reconciled before scope freeze | Package S — Final Cross-Document Audit and Scope-Freeze Readiness | Approved closure of S-01..S-12 and completed scope-freeze checklist | NOT READY |
| INS-S-001 | Standing Bracket controlled source checklist and item mapping must be approved | Standing Bracket Instrument Specification; Package S | Controlled source/version and Product Owner/institution approval | BLOCKED |
| DOC-S-001 | BA signatory, attendance verification, and report reconciliation authority must be approved | Reports, Documents, Printing, Attendance, and Audit Design; Package S | Approved document governance and UAT | BLOCKED |
| OFF-S-001 | Offline/device/local data protection contract must be approved | Offline Sync and Recovery; Package S | Approved device matrix, retention, encryption, conflict and recovery acceptance | BLOCKED |
| AUD-S-001 | INS-016 audit policy and institutional governance must be approved or explicitly deferred | Audit Event Catalogue and Governance; Package S | Formal approval/deferment with compensating controls | BLOCKED |
| OPS-S-001 | Provider, region, quota, billing, backup and restore capability must be verified | Packages O/P/Q; Package S | Provider capability sheet, approved budget/region, successful restore drill | BLOCKED |


## Package T decision traceability

The detailed PO decision closure register is maintained in `docs/00-project-charter/PACKAGE-T-PO-DECISION-CLOSURE-PACK.md`. Decision IDs T-01 through T-18 cover authoritative instrument masters, BA signatories, executive-summary signature, client report delivery, actual report metrics, project closure, session authority, attendance verification, offline scope, evidence privacy/retention, device/performance baseline, provider operations, print workflow, Inspector capacity semantics, INS-016 audit policy, serial/evidence integrity, CFG-001 publication governance and privileged command boundary.

These IDs are decision-tracking references, not implementation-complete requirements. T-01 through T-04 have explicit PO outcomes recorded in the Decision Register and detailed Package T update; T-01 Standing Bracket source is confirmed; official IFP source and SB photo/evidence rules remain outstanding. T-02 institutional signatory authority remains outstanding. T-05 through T-18 remain OPEN/BLOCKED. Each decision must be reconciled into the relevant requirement/specification and verification case. PO approval does not replace institutional approval or implementation verification.


## Package T — accepted PO decisions and traceability (2026-11-23)

| Decision | Approved direction | Traceability follow-up | Residual gate |
|---|---|---|---|
| T-01 | Official approved institutional source documents are authoritative master; SB source confirmed by PO | Trace SB's 19 official rows to source and preserve provenance; reconcile earlier screenshot; confirm IFP source and SB photo rules | PARTIALLY CLOSED: IFP source and SB photo/evidence rules remain OPEN |
| T-02 | BA signatory blocks configurable per approved template | Verify variable party count, organization, role/title, order and required/optional behavior | Institutional signatory authority and approved template remain OPEN |
| T-03 | Executive-summary signature configurable per template; default none unless required | Verify configured signature/no-signature variants in PDF tests | PO direction closed; institutional template governs |
| T-04 | PDF-only client delivery for initial release; portal deferred | Verify permission-controlled PDF access/distribution and mark portal out of initial scope | PO direction closed; portal needs change request |

T-01 through T-04 are not blanket closure of Package S. Remaining decisions and evidence dependencies remain active. Do not mark scope freeze ready based on these partial closures.
