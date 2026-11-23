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

Inspector capacity is configurable from minimum 1 to maximum 100 distinct active Inspector accounts across both locations combined; default value is 50. Recorded as OPS-001. Enforcement must be atomic and audited.

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

## Package D — Technical Architecture

Drafted seven technical design documents:
- System architecture and trust boundaries.
- Logical data model and ERD.
- RLS and authorization design.
- Evidence storage and media lifecycle.
- API and critical transaction contracts.
- Security threat model.
- Performance and operations baseline, including 100-user concurrent load-test approach.

Package D is not approved and does not authorize feature implementation. Exact physical schema, transport choices, offline storage, media limits/retention, provider plan, numerical performance thresholds, backup objectives, and operational ownership remain open.

## Package L — Physical Database Schema and Integrity

Drafted physical PostgreSQL table catalogue, constraints, indexes, transaction invariants, serial identity proposal, immutable inspection/evidence linkage, and configurable instrument schema/versioning. PO confirmation remains open for serial uniqueness and Inspector capacity counting predicate. No migrations were created or executed.

## Package M — Table-by-Table RLS Policy Catalogue

Drafted deny-by-default access matrix for every Package L table and private Storage object class, including role/scope and privileged-function rules. No executable policies were deployed and no security tests were run.

## Package N — Privileged Command Boundary

Drafted Vercel route + caller-JWT PostgreSQL command-function pattern, transactional command catalogue, idempotency and security requirements. Approval remains open; no RPC or route was implemented.

## Package O — Evidence Privacy, Retention, Deletion and Recovery

Drafted data classification, minimization, private access, retention schedule template, legal hold, controlled deletion, integrity and recovery requirements. Institutional legal/records approval and exact retention durations remain blockers.

## Package P — Backup, Restore and Disaster Recovery

Drafted database and Storage backup strategy, restore runbook, incident scenarios, RPO/RTO proposals, provider verification checklist, and restore-drill requirements. Provider capability and recovery objectives remain unverified/unapproved; no restore drill has been executed.

## Package Q — Production Environment, Secrets and Provider Governance

Drafted environment separation, provider responsibilities, region and quota verification, cost governance, secret handling, CI/CD, monitoring, and incident response. Provider plan, region, quota sheet, billing ownership and named operators remain open.

## Phase 0 exit checklist

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
- [ ] Institutional privacy, retention, deletion, and legal-hold policy approved.
- [ ] PostgreSQL and Storage backup/recovery capabilities verified and restore drill passed.
- [ ] Production region, provider plans/quotas, billing owner, secrets, and environment separation approved.
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


## Package R — Audit Event Catalogue and Governance

Created `docs/02-architecture/AUDIT-EVENT-CATALOGUE-AND-GOVERNANCE.md`, defining canonical audit event fields, business/security/governance event families, critical transaction fail-closed behavior, append-only controls, privacy-safe payloads, retention/legal hold, access/export auditing, and verification requirements. INS-016 remains an unapproved draft proposal. No schema, trigger, policy, or application code has been implemented; no tests have been executed.

New Standing Bracket evidence was also reconciled into the instrument specification and verification matrix. The 23-November sample form contains 19 visible checklist rows (6 physical + 13 accessories); earlier screenshot transcription also contains 19 visible rows. Exact source mapping, controlled checklist authority, signatory policy, and photo-slot requirements remain open.


## Package S — Final Cross-Document Audit and Scope-Freeze Readiness

Created `docs/00-project-charter/PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md`. The current 45-file PR change inventory and principal governance, product, functional, architecture, UX, and QA documents were reviewed. Architectural direction is broadly consistent, but the disposition is **NOT READY FOR SCOPE FREEZE** and **FEATURE IMPLEMENTATION NOT AUTHORIZED**. The report records 9 blocker findings and 3 high findings, including instrument source authority, BA/attendance authority, session lifecycle, offline/device protection, privacy/retention, provider/recovery verification, schema/RLS/command approval, INS-016 audit approval, reporting semantics, performance thresholds, and CI/repository controls. No implementation or environment tests were executed.


## Package T — Product Owner decision closure

- Decision closure pack: `docs/00-project-charter/PACKAGE-T-PO-DECISION-CLOSURE-PACK.md`.
- Package T converts Package S findings into 18 explicit PO decision records, with recommendations, options, cost/effort, risks and consequences of deferral.
- Package T decisions T-01 through T-04 have explicit PO outcomes recorded in the Decision Register; T-01 source evidence and T-02 institutional signatory authority remain outstanding. T-05 through T-18 remain OPEN/BLOCKED unless explicitly decided. Recommendations are not approvals.
- Scope freeze remains NOT READY; feature implementation remains NOT AUTHORIZED.
- PR #2 remains draft and must not be merged until mandatory gates are closed and verified.
