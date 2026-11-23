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
| GOV-005 | Initial scope is non-SaaS and includes IFP and Standing Bracket only | PRD-001..003 | PRD | Scope audit and sign-off | BASELINED; sign-off pending |
| CAP-001 | Configurable Inspector capacity starts at 50 and can increase up to 100 total across both locations combined | Decision Register OPS-001 | RBAC and Authorization; Project, Session, Target, and Assignment Model | Capacity range, audit, and atomic concurrency tests | BASELINED |
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
| DOC-003 | BA and attendance have distinct lifecycle and authority | Document decisions | Reports, Documents, Printing, Attendance, and Audit | Document UAT and role tests | DETAIL OPEN |
| RPT-001 | Actual and Target reports are distinct; actual dates are never rewritten | RPT decisions | Reports, Documents, Printing, Attendance, and Audit | Reconciliation/date-integrity tests | BASELINED |
| AUD-001 | Audit coverage and controls require explicit approval before implementation | INS-016 proposal | Reports, Documents, Printing, Attendance, and Audit | Audit coverage/tamper tests | PROPOSED |
| OPS-002 | Production includes tested backup/restore, monitoring, deployment, and rollback | Engineering Governance | Operations package pending | Restore drill and rollback evidence | REQUIRED; detail pending |

## Instrument-specific traceability (pending official source validation)

| Requirement ID | Instrument | Requirement area | Known source coverage | Verification plan | Status |
|---|---|---|---|---|---|
| IFP-001 | IFP | Checklist categories and 49 identified checklist statements across five categories | Transcribed from legacy reference descriptions; official source not validated | Reconcile exact text/order against authorized checklist | DRAFTED / SOURCE VALIDATION OPEN |
| IFP-002 | IFP | Ten identified photo-slot labels | Legacy reference descriptions; completeness/mandatory status unverified | Verify labels, required rules, exceptions, PDF placement | DRAFTED / SOURCE VALIDATION OPEN |
| BRK-001 | Standing Bracket | Checklist categories and item list | 19 visible checklist rows transcribed from supplied screenshots; complete authoritative list not established | Confirm full checklist, grouping, text, and response rules | PARTIAL / SOURCE VALIDATION OPEN |
| BRK-002 | Standing Bracket | Five identified photo-slot labels | Legacy reference descriptions; completeness/mandatory status unverified | Verify complete list and required rules | DRAFTED / SOURCE VALIDATION OPEN |
| PRD-001 | Product | Product scope, journeys, functional/non-functional requirements | PRD v0.1.0 | Product Owner review | DRAFTED / REVIEW REQUIRED |
| AC-001 | Product | Observable acceptance criteria | Acceptance Criteria v0.1.0 | Map to test cases and UAT evidence | DRAFTED / REVIEW REQUIRED |

## Package C design artifacts

- `docs/03-functional-design/RBAC-AND-AUTHORIZATION.md`
- `docs/03-functional-design/PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md`
- `docs/03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md`
- `docs/03-functional-design/OFFLINE-SYNC-AND-RECOVERY.md`
- `docs/03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md`

All are design drafts, not formal Product Owner approvals. Open decisions are explicitly retained in each document.

## Change-control rules

- Every new requirement receives a stable ID; IDs are never reused.
- Every approved requirement must link to an authorized source or decision.
- Every implementation PR references requirement IDs.
- Every implemented requirement links to code paths/PRs; verified requirements link to test results or UAT evidence.
- Changes to approved requirements require impact analysis across UX, data, authorization, audit, migration, reporting, tests, and operations.
- Unknown source details remain OPEN; do not fill gaps with assumptions.
