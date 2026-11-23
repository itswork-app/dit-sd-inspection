# Requirements Traceability Matrix — Dit. SD Inspection

Status: Baseline draft — requirements require source validation  
Purpose: Link approved product intent to specifications, implementation units, and verification evidence. This matrix is a control index, not a substitute for the detailed PRD or test cases.

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

| Requirement ID | Requirement statement | Source / decision | Specification owner | Verification evidence | Status |
|---|---|---|---|---|---|
| GOV-001 | Release target is production | MGT-001 | CTO / Engineering Lead | Production readiness checklist and release evidence | APPROVED |
| GOV-002 | Optimize lifecycle cost without waiving security, privacy, integrity, backup, or reliability | MGT-002 | CTO / Engineering Lead | Cost review plus security/operations gates | APPROVED |
| GOV-003 | Use Supabase + Vercel; GitHub for source control/CI | TECH-001, TECH-003 | CTO / Engineering Lead | ADR and deployment pipeline | APPROVED |
| GOV-004 | Supabase PostgreSQL is the sole primary source of truth | TECH-002 | CTO / Engineering Lead | Architecture review and data-flow tests | APPROVED |
| GOV-005 | Initial product scope is not SaaS and includes only IFP and Standing Bracket | PRD-001..003 | Product Owner | Scope audit and PRD sign-off | APPROVED |
| OPS-001 | Maximum 50 Inspector users across both locations combined | OPS-001 decision | Product Owner / Super Admin | Database constraint/service validation and assignment tests | APPROVED |
| AUTH-001 | Users sign in with Google; new accounts await approval and role assignment | RBAC-001 | Product Owner / CTO | Auth and account lifecycle integration tests | APPROVED |
| RBAC-001 | Users may hold multiple roles only with explicit scoped assignments | RBAC-002 | Product Owner / CTO | Positive and negative authorization tests | APPROVED |
| RBAC-002 | Operational authority is scoped by session, location, instrument, and assignment | RBAC-002 | CTO / Engineering Lead | RLS and API authorization tests | APPROVED |
| RBAC-003 | Self-review and self-approval are prohibited | WF-001 | Product Owner / CTO | Negative workflow tests | APPROVED |
| SES-001 | Super Admin controls official project/session targets and assignments | Planning decisions | Product Owner | Role/permission tests and audit assertions | BASELINED; detail pending |
| SES-002 | An Inspector cannot be scheduled in overlapping locations/times | Assignment decisions | Product Owner / CTO | Conflict and concurrency tests | BASELINED |
| INS-001 | Active sessions freeze the version of instrument configuration | INS-001 | Product Owner / CTO | Snapshot and version immutability tests | APPROVED |
| INS-002 | Checklist uses exception-based UX; default OK presentation is not automatic verification | INS-002 | Product Owner | UI and validation tests | APPROVED |
| INS-003 | Serial number claims a unit; duplicate active claims are prevented | INS-005, INS-008 | Product Owner / CTO | Concurrency, normalization, and uniqueness tests | APPROVED |
| INS-004 | Required checklist/photo/evidence validation blocks incomplete submission | INS-009 | Product Owner | Positive/negative submission tests | APPROVED |
| EVD-001 | Original evidence is preserved; server receipt and device capture time are distinct | INS-007 | CTO / Engineering Lead | Metadata/hash/storage integrity tests | APPROVED |
| OFF-001 | Limited offline inspection is supported with safe, idempotent synchronization | INS-003, INS-006 | CTO / Engineering Lead | Offline, retry, conflict, device-loss and recovery tests | APPROVED |
| REV-001 | Reviewer may return work with reason; Inspector corrects and resubmits | WF-001, INS-010 | Product Owner | Revision lifecycle tests | APPROVED |
| REV-002 | Submitted revisions are immutable; approved work reopens only with authority and reason | WF-002, INS-010 | Product Owner / CTO | Immutability and reopen authorization tests | APPROVED |
| DOC-001 | Final PDF follows approval; print action is recorded and reprints counted | DOC-001, DOC-002, INS-011 | Product Owner | PDF snapshot and print-event tests | APPROVED |
| DOC-002 | Wet signatures remain in Phase 1; digital signatures do not replace them | DOC-001 | Product Owner | Document template review and UAT | APPROVED |
| DOC-003 | BA and attendance documents follow separately defined lifecycle and authority | Existing workflow decisions | Product Owner | Document UAT and role tests | DETAIL OPEN |
| RPT-001 | Actual and Target reporting are distinct and actual activity dates are never rewritten | RPT-001, RPT-002 | Product Owner / CTO | Report reconciliation and date-integrity tests | APPROVED |
| AUD-001 | Audit trail and activity monitoring requirements must be finalized before implementation | INS-016 | Product Owner / CTO | Audit coverage matrix and tamper-resistance tests | PROPOSED |
| OPS-002 | Production includes tested backup/restore, monitoring, deployment and rollback procedures | Engineering Governance | CTO / Engineering Lead | Restore drill, deployment rehearsal, rollback evidence | REQUIRED; detail pending |

## Instrument-specific traceability (pending official source validation)

| Requirement ID | Instrument | Requirement area | Known source coverage | Verification plan | Status |
|---|---|---|---|---|---|
| IFP-001 | IFP | Checklist categories and checklist items | Partial content described from supplied reference screens | Reconcile exact text/order against authorized checklist; test every item and status | OPEN |
| IFP-002 | IFP | Required photo slots | Ten photo labels described in project discovery | Verify labels, required/conditional rules, exception handling and PDF placement | OPEN |
| BRK-001 | Standing Bracket | Checklist categories and checklist items | Incomplete reference coverage | Obtain complete authoritative checklist; create item-level IDs | OPEN |
| BRK-002 | Standing Bracket | Required photo slots | Five photo labels described in project discovery; completeness unverified | Verify complete list and required/conditional rules | OPEN |

## Change-control rules

- Every new requirement receives a stable ID; IDs are never reused.
- Every approved requirement must link to a decision or authorized source.
- Every implementation PR references requirement IDs.
- Every requirement marked implemented must link to code paths/PRs; verified requirements must link to test results or UAT evidence.
- Changes to approved requirements require impact analysis across UX, data model, authorization, audit, migration, reporting, tests, and operations.
- Unknown source details remain OPEN; do not fill gaps with assumptions.
