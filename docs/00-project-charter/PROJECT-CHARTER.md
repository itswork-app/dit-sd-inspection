# Project Charter — Dit. SD Inspection

Status: Draft for stakeholder validation  
Release target: Production  
Engineering priority: Cost-first  
Technology baseline: Supabase + Vercel + GitHub

## Purpose
Build a reliable replacement application for the existing Dit. SD inspection workflow, covering field inspection, review, approval, document generation, printing, reporting, and operational oversight.

## Initial scope
- IFP and Standing Bracket inspection instruments.
- Google sign-in with controlled account approval and role assignment.
- Scoped roles and operational assignments.
- Project, session, location, instrument, team, and target management.
- Serial-number capture, unit claiming, checklists, standard photos, and finding evidence.
- Limited offline inspection and safe synchronization.
- Reviewer correction and approval workflow.
- PDF generation, print/reprint tracking, Berita Acara (BA), and attendance documents.
- Actual and Target reporting, dashboards, audit trail, and notifications.
- Versioned configuration and historical snapshots.

## Platform baseline
- **Supabase:** PostgreSQL, Authentication, Row Level Security, and private Storage.
- **Vercel:** web/PWA hosting, deployment, and preview environments.
- **GitHub:** source control, pull requests, and economical CI.
- Supabase PostgreSQL is the single source of truth. Do not introduce a second primary database.
- No separate microservices or additional paid infrastructure without a documented requirement and cost/benefit review.

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
5. Validate official instrument content against authorized source documents.

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
Optimize total lifecycle cost, not only initial hosting price. Start with the smallest suitable plans, measure actual consumption, and scale only when usage or production risk requires it. Retain non-negotiable security, privacy, evidence integrity, backup, and recovery controls.

## Operational capacity constraint
- Inspector capacity starts at 50 and may be increased by Super Admin to a hard maximum of 100 distinct users across the two inspection locations combined. This is a combined project cap, not 100 per location. Super Admin controls allocation through explicit assignments.

## Constraints
Legacy source code is unavailable. Reference material is based on screenshots and workflow descriptions; some checklist details remain incomplete. Data residency, privacy, retention, procurement, official logos, signatories, and institutional content require authorized stakeholder confirmation.
