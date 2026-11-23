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
- Package T decisions T-01 through T-08 have explicit PO outcomes recorded in the Decision Register. T-01 Standing Bracket source is confirmed; official IFP source and SB photo/evidence rules remain outstanding. T-02 institutional signatory authority remains outstanding. T-09 option B is now PO APPROVED: limited offline draft editing only for already claimed units, with online-only claim/finalization/approval/admin actions and idempotent conflict-safe synchronization. Device/browser support, local-data protection, retention/purge and recovery remain open; T-10 option B is PO APPROVED as the formal institutional records/legal/privacy review path; written policy remains BLOCKED pending institutional authority. T-11 option B is PO APPROVED: current mainstream stable browsers with explicit exclusions; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED: alternative provider-ownership arrangement subject to written institutional definition/approval. Actual ownership, billing, custodians, region, quotas and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B: individual and bounded batch printing with per-document outcomes, failed-only retry, atomic reprint sequence and no claim of physical paper output. Detailed design/test evidence remains pending. T-14 through T-18 remain OPEN/BLOCKED. Recommendations are not approvals.
- Scope freeze remains NOT READY; feature implementation remains NOT AUTHORIZED.
- PR #2 remains draft and must not be merged until mandatory gates are closed and verified.


### Package T T-09 — offline scope decision (2026-11-23)

Product Owner approved option B. The initial release may support offline editing only for an inspection draft whose unit was claimed online. Offline claim, approval, final submit, role/assignment changes, session administration and privileged actions remain online-only. Reconnect sync must be idempotent, recheck authorization and claim/state, preserve both sides of conflicts and never silently overwrite. Required media must be server-confirmed before final submit. Production activation remains gated on approved device/browser matrix, local-data protection, shared-device/logout, retention/purge and recovery controls (T-10/T-11). No implementation or tests are claimed; scope freeze remains NOT READY.


## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.


## Package T-11 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — support current mainstream browser versions with explicit exclusions.** Inspector field workflow uses current stable Chrome on Android; Korlap, Reviewer, Super Admin and Print Officer use current stable Chrome or Edge on desktop. Tablet support is conditional on responsive, camera, upload and PDF/print validation. Obsolete/unsupported browser releases, embedded in-app browsers and modified browsers are excluded. Exact OS/device minimums and browser build numbers must be recorded from actual UAT devices; this decision does not invent exact version numbers.

The 100 concurrent authenticated-user load-test target remains the required acceptance profile, tested at 10/25/50/75/100 concurrent users. This is a test target, not a demonstrated production capacity or SLA. Numeric latency/error-rate SLOs remain OPEN pending workload definition, provider plan/region/quota verification and baseline measurement. No implementation, compatibility test or load test is claimed as executed.


## Package T-12 — Product Owner decision (2026-11-23)
PO APPROVED option C: an alternative provider-ownership arrangement may be adopted only after formal institutional definition and written approval. The specific owner, billing authority, custodians, region approver and recovery contacts remain unidentified and must not be inferred. Provider plan/quotas, budget, region, backup/PITR, Storage recovery and restore drill remain verification gates. No production deployment/data use is authorized by this decision.


### Package T-13 — Product Owner decision (2026-11-23)

PO approved option B: individual and bounded/configurable batch printing through the permissioned Print Officer queue. Every document has an independent outcome; retry targets failed documents only; successful print events are not duplicated; reprint ordinals are atomic and linked to the exact approved PDF version. The application event does not prove physical paper output. Direct printer integration is excluded from initial release. Related functional, PRD, acceptance, API, data-model, QA and governance documents were updated. This is a product decision only: no implementation or tests are claimed, scope freeze remains NOT READY, and feature implementation remains NOT AUTHORIZED.
