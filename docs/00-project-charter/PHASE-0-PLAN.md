# Phase 0 — Project Foundation

Status: In progress  
Exit condition: Project foundation reviewed and approved; open assumptions and owners are explicit.

## Confirmed management decisions

- Release target: Production.
- Engineering priority: Cost-first.
- Platform: Supabase + Vercel; GitHub for source control and CI.
- Supabase PostgreSQL is the single source of truth.
- Product is a replacement inspection application, not SaaS.
- Initial instruments: IFP and Standing Bracket.
- Strategy: feature parity first, improvements after.
- Legacy source code is unavailable; supplied workflows/screenshots are reference material.
- Repository: itswork-app/dit-sd-inspection; private; default branch main.

## Work items

| ID | Work item | Exit evidence | Status |
|---|---|---|---|
| P0-01 | Confirm charter and product boundaries | Approved charter | Drafted; approval pending |
| P0-02 | Define roles and decision authority | Stakeholder/RACI matrix | Drafted; validate |
| P0-03 | Establish Git and PR governance | Branch/PR policy | Drafted; configure |
| P0-04 | Establish quality and cost gates | Approved governance | Drafted; validate |
| P0-05 | Create decision and requirement traceability | Decision Register and RTM | Drafted; validate |
| P0-06 | Inventory reference material and evidence gaps | Reference inventory | Drafted; source artifacts still required |
| P0-07 | Record risks, assumptions, dependencies | RAID register | Drafted; review owners and mitigations |
| P0-08 | Define production constraints and cost envelope | Hosting, privacy, retention, budget, operations decisions | Pending stakeholder input |
| P0-09 | Record Supabase/Vercel platform baseline | ADR-001 | Drafted |
| P0-10 | Validate production plan eligibility and quotas | Cost and operational assessment | Pending |

## Capacity constraint

Maximum 50 distinct Inspector users across both inspection locations combined. Recorded as OPS-001 in Decision Register. Enforcement must be atomic.

## Package B — Product Requirements

- PRD v0.1.0 drafted.
- IFP instrument specification drafted from identified reference content; official source validation remains open.
- Standing Bracket specification now includes 19 checklist rows visible in supplied screenshots; complete official checklist and photo-slot rules remain unverified.
- Acceptance Criteria v0.1.0 drafted.
- Package B is NOT approved; Product Owner validation and authoritative source documents remain required.

## Package C — Functional and Operational Design

Drafted:
- RBAC and Authorization.
- Project, Session, Target, and Assignment Model.
- Inspection Lifecycle, Unit Claims, Review, and Revision.
- Offline, Synchronization, Conflict, and Recovery.
- Reports, Documents, Printing, Attendance, and Audit.

Package C clarifies the functional baseline while preserving unresolved decisions. It does not authorize implementation. All five documents require review, and the offline/browser/storage limits require validation against actual field devices.

## Package D — Technical Architecture\n\nDrafted seven technical design documents:\n- System architecture and trust boundaries.\n- Logical data model and ERD.\n- RLS and authorization design.\n- Evidence storage and media lifecycle.\n- API and critical transaction contracts.\n- Security threat model.\n- Performance and operations baseline, including 100-user concurrent load-test approach.\n\nPackage D is not approved and does not authorize feature implementation. Exact physical schema, transport choices, offline storage, media limits/retention, provider plan, numerical performance thresholds, backup objectives, and operational ownership remain open.\n\n## Phase 0 exit checklist

- [ ] Charter approved by Product Owner.
- [ ] Stakeholder roles and final decision authority confirmed.
- [ ] Scope and exclusions accepted.
- [ ] Engineering Governance accepted.
- [ ] Repository protection and required reviews configured.
- [ ] Decision Register and traceability established.
- [ ] Reference inventory and checklist gaps documented.
- [ ] RAID register reviewed with owners.
- [ ] Production constraints, budget owner, and compliance owners identified.
- [ ] Supabase/Vercel plan eligibility and production constraints reviewed.
- [ ] Phase 1 entry criteria accepted.

## Phase 1 entry criteria

Do not begin feature implementation until Phase 0 is approved, PRD and Package C decisions are consolidated, official IFP and Standing Bracket checklist/photo requirements are validated against authorized references, acceptance criteria are testable and traceable, and the architecture/security/quality packages are reviewed.


## Package E — UX and Quality Engineering

Drafted five documents:
- Information architecture and navigation.
- Screen flows and wireframe specification.
- Design system and responsive UX.
- Test strategy and quality gates.
- Test case catalog and UAT plan.

Package E is a design/test-planning package only. No UI implementation or test execution is claimed. Visual tokens, device/browser support, accessibility verification, numeric performance SLOs, official instrument source validation, and UAT sign-off remain open.
