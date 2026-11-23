# Project Charter — Dit. SD Inspection

**Status:** Draft for stakeholder validation  
**Release target:** Production  
**Engineering priority:** Balanced  
**Repository:** https://github.com/itswork-app/dit-sd-inspection

## 1. Purpose
Build a reliable replacement application for the existing inspection workflow used by Direktorat Sekolah Dasar (Dit. SD). The application supports field inspection, review, approval, document generation, printing, reporting, and operational oversight for the defined inspection instruments.

## 2. Product scope

### In scope — initial release
- IFP and Standing Bracket inspection instruments.
- Google sign-in and controlled account approval.
- Configurable roles, permissions, and operational assignments.
- Project, week/session period, location, instrument, team, and target management.
- Serial-number capture, unit claiming, checklist, standard photos, and finding evidence.
- Limited offline inspection and safe synchronization.
- Reviewer correction/approval workflow.
- PDF generation, print/reprint tracking, Berita Acara (BA), and attendance documents.
- Actual and Target reporting, dashboards, audit trail, and notifications.
- Versioned configuration and historical snapshots.

### Out of scope unless separately approved
- SaaS or multi-customer commercial offering.
- Instruments other than IFP and Standing Bracket.
- Digital signature as a replacement for wet signatures in Phase 1.
- Unapproved integrations or automation that changes inspection outcomes.
- Features inferred solely from assumptions about legacy internals.

## 3. Product strategy
1. Achieve workflow and output parity with the known legacy reference first.
2. Improve reliability, security, usability, and operational control without changing official inspection meaning.
3. Preserve actual inspection facts; target/reporting allocation must never be represented as actual activity.
4. Treat the legacy application as a reference only. No legacy source-code or database access is assumed.
5. Official instrument content must be grounded in confirmed source material. Current screenshots provide partial evidence; incomplete checklist content must be validated before specification freeze.

## 4. Stakeholders and authority
- **Product Owner / project sponsor:** approves business rules, scope, official instrument content, operational policy, and acceptance.
- **CTO / Engineering Lead:** owns technical architecture, engineering standards, security design, implementation quality, and release recommendation.
- **Super Admin:** administers the application and approved configurations within governed permissions.
- **Admin / Koordinator Lapangan (Korlap):** supervises assigned operational locations and sessions.
- **Inspector:** performs assigned inspections.
- **Reviewer:** reviews, returns for correction, and approves inspections; cannot approve their own inspection.
- **Print Officer:** prints approved documents within assigned scope.
- **Other signatories / document custodians:** authority to be confirmed in the final document workflow.

A person may hold multiple roles only through explicit assignment and permission. Operational authority is scoped to the relevant session/location/instrument assignment. Self-review and self-approval are prohibited.

## 5. Release objective
Production release means the agreed product scope is implemented and verified; critical user journeys work end-to-end; security and data-integrity controls pass; operational documentation and recovery procedures exist; UAT is accepted; and no unresolved release-blocking defects remain.

Production readiness is not a claim of zero future defects.

## 6. Success measures
Measures to define and approve before UAT:
- Completion rate of required inspection workflows.
- Duplicate serial-number and duplicate-claim prevention.
- Successful offline-to-online synchronization and conflict recovery.
- Accuracy of PDFs, BA, attendance, and Actual/Target reports.
- Authorization and scope-isolation test results.
- Defect severity and closure status.
- Backup/restore and operational recovery evidence.

## 7. Constraints and assumptions
- Legacy source code is unavailable to this project.
- Current reference material consists of user-provided screenshots and workflow descriptions; some instrument details remain incomplete.
- No technology stack has been approved yet.
- Hosting, data residency, retention, privacy, and procurement constraints require stakeholder confirmation.
- Production credentials, official logos, names, signatories, and institutional content must be supplied or approved by authorized stakeholders.

## 8. Change control
Any change to scope, official instrument criteria, approval authority, data retention, completion rules, or reporting semantics must be recorded in the Decision Register or an ADR, with approver, rationale, impact, and effective version.
