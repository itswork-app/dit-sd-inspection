# Project Charter — Dit. SD Inspection

Status: Draft for stakeholder validation
Release target: Production
Engineering priority: Cost-first
Repository: https://github.com/itswork-app/dit-sd-inspection

## Purpose
Build a reliable replacement application for the existing Dit. SD inspection workflow, covering field inspection, review, approval, document generation, printing, reporting, and operational oversight.

## Initial scope
- IFP inspection instrument.
- Standing Bracket inspection instrument.
- Google sign-in with controlled account approval and role assignment.
- Scoped roles and operational assignments.
- Project, session, location, instrument, team, and target management.
- Serial-number capture, unit claiming, checklists, standard photos, and finding evidence.
- Limited offline inspection and safe synchronization.
- Reviewer correction and approval workflow.
- PDF generation, print/reprint tracking, Berita Acara (BA), and attendance documents.
- Actual and Target reporting, dashboards, audit trail, and notifications.
- Versioned configuration and historical snapshots.

## Out of scope unless separately approved
- SaaS or multi-customer commercial offering.
- Instruments beyond IFP and Standing Bracket in the initial release.
- Digital signatures replacing wet signatures in Phase 1.
- Unapproved integrations or automation that changes inspection outcomes.

## Product strategy
1. Achieve workflow and output parity with the known legacy reference first.
2. Improve reliability, security, usability, and operational control without changing official inspection meaning.
3. Preserve actual inspection facts; target allocation must never be represented as actual activity.
4. Treat the legacy app as reference only; no source-code/database access is assumed.
5. Validate official instrument content against authorized source documents. Current screenshots and descriptions provide partial evidence; gaps remain open until confirmed.

## Authority
- Product Owner/project sponsor approves business rules, scope, official instrument content, and acceptance.
- CTO/Engineering Lead owns architecture, engineering standards, security design, quality, and release recommendation.
- Super Admin administers approved configuration within governed permissions.
- Admin/Koordinator Lapangan supervises assigned operational locations and sessions.
- Inspector performs assigned inspections.
- Reviewer returns work for correction or approves it; self-review/self-approval is prohibited.
- Print Officer prints approved documents within assigned scope.

Multi-role accounts require explicit assignment. Operational authority is scoped to session, location, and instrument.

## Production objective
Production release requires agreed scope implemented and verified, critical journeys working end-to-end, security and data-integrity controls passing, operational and recovery procedures documented, UAT accepted, and no unresolved release-blocking defects. Production readiness is not a claim of zero future defects.

## Cost-first interpretation
Optimize total lifecycle cost, not only initial hosting price. Prefer simple architecture, managed services with transparent limits, minimal paid dependencies, and selective CI. Retain non-negotiable controls for security, privacy, evidence integrity, backups, recovery, and availability appropriate to the approved operational risk.

## Constraints and assumptions
- Legacy source code is unavailable.
- Reference material is based on user-provided screenshots and workflow descriptions; some checklist details are incomplete.
- Technology stack and hosting are not yet approved.
- Data residency, privacy, retention, procurement, official logos, signatories, and institutional content require authorized stakeholder confirmation.

## Change control
Changes to scope, official criteria, approval authority, retention, completion rules, or reporting semantics require a Decision Register entry or ADR with approver, rationale, impact, and effective version.
