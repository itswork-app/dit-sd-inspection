# Product Requirements Document — Dit. SD Inspection

Status: Draft — Product Owner validation required  
Version: 0.1.0  
Release target: Production  
Scope baseline: IFP and Standing Bracket only

## 1. Product purpose

Replace the existing inspection application used by Direktorat Sekolah Dasar (Dit. SD) with a secure, reliable web application/PWA supporting the inspection lifecycle from controlled access and unit identification through evidence capture, checklist completion, review, approval, document generation, printing, reporting, and operational oversight.

This is a replacement project, not a SaaS offering. The legacy application is a behavioral and output reference only. No legacy source-code or database access is assumed.

## 2. Product principles and constraints

1. Feature parity with the known legacy workflow and outputs comes first; controlled improvements follow.
2. Initial rollout contains Interactive Flat Panel (IFP) and Standing Bracket. The product is instrument-extensible: all instrument types are managed through Super Admin configuration, not hardcoded as a permanent two-instrument limit.
3. There are two inspection locations in the initial project.
4. Inspector capacity is configurable from minimum 1 to maximum 100 distinct active Inspector accounts across both locations combined; default value is 50. Allocation between locations is controlled by Super Admin; the capacity is not per location. Values outside 1–100 are rejected.
5. Supabase PostgreSQL is the single source of truth; Supabase Auth and private Storage are used. Vercel hosts/deploys the web/PWA. GitHub is source control and CI.
6. Cost-first engineering must not weaken security, privacy, evidence integrity, backup/recovery, or production reliability.
7. Official inspection criteria and report meanings must not be changed by UX or engineering convenience.
8. Actual inspection facts and target/reporting allocations are separate dimensions.
9. Historical inspection versions and original evidence are immutable; corrections create new versions or append-only events.
10. All operational access is server-enforced and scoped; UI hiding alone is not authorization.

## 3. Users and roles

- **Project Sponsor:** institutional sponsorship and production authorization.
- **Product Owner:** owns scope, official instrument content, business rules, acceptance and UAT.
- **Super Admin:** global administration, approved configuration, project/session planning, assignments, and cross-project oversight.
- **Admin / Koordinator Lapangan (Korlap):** operational supervision within assigned location/session.
- **Inspector:** performs assigned unit inspections and submits evidence.
- **Reviewer:** reviews, returns for correction, or approves submitted inspections.
- **Print Officer:** prints/reprints approved final PDFs and records print actions.
- **Attendance Verifier:** proposed functional responsibility; authority remains open until approved.

Users may hold multiple roles, but operational authority requires explicit assignment and scope. Self-review/self-approval is prohibited.

## 4. Product scope

### 4.1 In scope
- Google sign-in, account approval, role and permission assignment.
- Project, session, location, instrument, team, target, and operational assignment management.
- Super Admin-managed instrument catalog: create, configure, activate/deactivate, and version instrument types without application code changes when using supported configuration primitives.
- Instrument and checklist configuration with versioning and historical snapshots.
- Serial number entry/capture, unit claim, duplicate prevention, and recovery.
- IFP and Standing Bracket checklists and photo/evidence capture.
- Limited offline draft inspection and safe synchronization.
- Pre-submit validation, immutable submission versions, reviewer correction and approval.
- PDF generation, print/reprint tracking, BA, attendance evidence.
- Actual and Target reporting, role-specific dashboards, notifications, and audit.
- Production operations, security, backup/restore, monitoring, and recovery.

### 4.2 Out of scope unless separately approved
- Additional instrument types are not included in the initial rollout until configured and separately approved for project use; the platform must support adding them through Super Admin configuration without code changes where supported by the configuration model.
- SaaS/multi-customer commercial packaging.
- Digital signatures replacing wet signatures in Phase 1.
- Parent/customer portals, payments, sales, inventory, or unrelated modules.
- Unapproved integrations or automated decisions that alter inspection outcomes.
- A second primary database, microservices, Redis, VPS, or additional paid infrastructure without an approved architecture decision.

## 5. Core domain concepts

- **Project:** bounded inspection engagement with locations, dates, targets, and instruments.
- **Session:** operational time window and scope under a project.
- **Assignment:** one location + one instrument + one team + schedule/scope; parallel assignments may operate in the same session period.
- **Unit:** physical item identified by serial number within project/instrument scope.
- **Inspection:** an Inspector's examination of one unit.
- **Inspection revision:** immutable submitted version; correction creates a subsequent version.
- **Evidence:** photo/video/document attached to an inspection or checklist item; original is preserved.
- **Instrument version:** immutable snapshot of checklist, specifications, and evidence requirements used by a session.
- **Target allocation:** versioned planned reporting allocation, separate from actual inspection events.
- **Print event:** append-only record that an authorized Print Officer initiated printing of an approved document.

## 6. Primary user journeys

### 6.1 Account access
1. User signs in with Google.
2. New/unapproved user receives PENDING_APPROVAL status and cannot access operational data.
3. Super Admin approves/rejects account and assigns roles/permissions/scope.
4. User accesses only permitted projects, sessions, locations, instruments, and actions.

### 6.2 Session and assignment
1. Super Admin configures project, locations, instruments, target plan, sessions, and assignments.
2. Each operational assignment is limited to one location, one instrument, and one team.
3. Super Admin assigns Korlap, Inspectors, Reviewer, and Print Officer as required.
4. System rejects overlapping assignments for the same user.
5. Korlap supervises assigned operations; Inspector sees only assigned active work.

### 6.3 Inspection
1. Inspector opens an active assigned session and selects/enters a unit serial number.
2. System normalizes serial number under approved instrument rules and claims the unit atomically.
3. Existing claim by another Inspector cannot be duplicated; authorized resume/reassignment follows recovery rules.
4. Inspector completes configured checklist and evidence slots, records findings and evidence where needed.
5. Draft and evidence persist locally during permitted offline operation and sync safely.
6. Server-side validation blocks submission if mandatory checklist, evidence, exception reasons, or sync conditions are incomplete.
7. Inspector confirms and submits; submitted version becomes immutable.

### 6.4 Review and correction
1. Reviewer receives scoped submission queue.
2. Reviewer either returns the inspection with explicit correction reasons or approves it.
3. Returned inspection goes back to Inspector; Reviewer does not silently edit Inspector data.
4. Inspector corrects and resubmits as a new revision; history remains available.
5. Approved inspection can be reopened only by an authorized role with reason and audit record.

### 6.5 PDF and print
1. Approved inspection becomes eligible for final PDF generation.
2. PDF reflects the approved immutable inspection snapshot and configured template version.
3. Print Officer uses a dedicated permissioned queue and may print approved final PDFs individually or in bounded/configurable batches.
4. Batch printing records an independent outcome for every document; a partial batch is never represented as wholly successful.
5. Retry targets failed documents only and must not duplicate successful print events.
6. Reprint is allowed and visibly numbered (e.g. "Cetak ke-2"); sequence allocation is atomic and the same approved document version is retained unless controlled regeneration creates a new version.
7. Print action is a recorded application action; the system cannot prove paper physically emerged from a printer.
8. Per-unit wet signature is completed on paper; the print event does not imply signature completion.
9. Direct printer integration is not included in the initial release.

### 6.6 Session closure
Super Admin is the final project-closure authority. Project closure is explicit and non-automatic and is allowed only after all sessions are closed; no unresolved claims, drafts, corrections or pending reviews remain; required inspections, final PDFs, print events, BA and attendance artifacts are complete and verified; and actual-versus-target reconciliation is reviewed. The closer records confirmation/reason and the system records an audit event. No date-based auto-close. Any exception requires separately permissioned override, reason and audit. Session and project closure are distinct.

## 7. Functional requirement groups

| ID | Requirement | Priority | Acceptance summary |
|---|---|---|---|
| AUTH-001 | Google sign-in | Must | Valid identity can authenticate; unauthorized identity cannot access data |
| AUTH-002 | Pending account approval | Must | New user cannot operate until approved and assigned |
| RBAC-001 | Multi-role and scoped permission model | Must | Every operation enforces explicit role, permission, and assignment scope |
| CAP-001 | Configurable Inspector capacity ranges from 1 to 100; default 50, across both locations combined | Must | System rejects activation/assignment that would exceed the configured global cap |
| SES-001 | Project/session/location/instrument/team planning | Must | Super Admin can configure; parallel assignments remain independently scoped |
| SES-002 | Assignment conflict prevention | Must | Overlapping assignment for same user is rejected atomically |
| INS-001 | Versioned instrument configuration | Must | Session retains immutable version snapshot |
| INS-002 | Serial number claim and duplicate control | Must | One active claim per normalized unit; duplicate does not create second inspection |
| INS-003 | Checklist and evidence capture | Must | Inspector can complete configured instrument requirements |
| OFF-001 | Limited offline draft and synchronization | Must | No loss/overwrite on retry, conflict, or temporary disconnection |
| INS-004 | Pre-submit validation | Must | Incomplete or conflicted inspection cannot submit |
| REV-001 | Reviewer return/approval | Must | Return reason and approval actor/time are recorded |
| REV-002 | Immutable revision history | Must | Corrections create new revision; previous submissions remain readable |
| DOC-001 | Approved PDF generation | Must | PDF matches approved data and template snapshot |
| DOC-002 | Print/reprint event tracking | Must | Only authorized officer prints approved documents; count and actor are recorded |
| DOC-003 | BA and attendance document workflows | Must | Exact templates/authority must be approved before implementation |
| RPT-001 | Actual and Target reporting | Must | Target allocations never rewrite actual activity |
| AUD-001 | Audit and activity history | Must | Final audit coverage must be approved before implementation |
| OPS-001 | Production operations and recovery | Must | Backup/restore, monitoring, deployment, rollback and incident runbooks tested |

## 8. Non-functional requirements

### Security and privacy
- Deny-by-default authorization; server-side checks and Supabase RLS.
- Private evidence storage; signed access only for authorized users and limited duration.
- Secrets are never shipped to the browser; service-role credentials remain server-side.
- Account approval, role, permission, assignment, and configuration changes are auditable.
- No cross-location access unless explicitly granted.
- Data minimization, retention, deletion, and privacy rules must be approved before production.

### Integrity and reliability
- Use database constraints and transactions for claims, assignment conflicts, and state transitions.
- Use idempotency for sync and retryable commands.
- Preserve immutable inspection revisions and original evidence.
- Never mark a record complete merely because a client-side action occurred without server confirmation.
- No silent conflict overwrite or automatic evidence deletion.

### Offline behavior
- **PO-approved T-09 option B:** limited offline draft editing is in the initial product scope, but only for an inspection unit already claimed while online.
- Offline claim acquisition, final submission, review/approval, role or assignment changes, session administration, PDF finalization, print events and all privileged actions require connectivity.
- Reconnection must be authenticated and idempotent; the server rechecks identity, authorization, assignment, claim ownership and current state.
- Stale writes are rejected as explicit conflicts; preserve local pending data and server state for authorized resolution. Never silently apply last-write-wins.
- Required evidence must be acknowledged by the server before final submission.
- Production offline persistence remains gated on approved device/browser support, local-data protection, shared-device/logout, retention/purge and recovery controls; T-10 institutional privacy/records approval remains open.

### Performance and accessibility
- Define measurable load, upload, and interaction budgets during architecture and test planning.
- Core workflows must remain usable on supported field devices and unstable mobile networks.
- Accessibility and browser/device support matrix must be approved before UAT.

## 9. Reporting requirements

- Actual reports reflect true activity timestamps and counts.
- Target reports reflect planned targets and approved target-date allocations.
- Daily, weekly, and final reports exist in both Actual and Target variants.
- Actual reports are internal; Target reports are client-facing under current baseline.
- Korlap validates/approves daily reports within assigned location; Super Admin monitors global progress.
- Actual reports display separate Inspected, Submitted, Approved and Completed counts; Completed = approved inspection + final PDF generated + Print Officer print action recorded.
- Super Admin is final project-closure authority after all required gates and actual-versus-target reconciliation pass.

## 10. Configuration and history

Super Admin may configure approved operational settings, including the instrument catalog (create/edit/activate/deactivate), instrument metadata, checklist sections/items/order, specification fields and expected values, evidence/photo slots, mandatory/conditional applicability, supported validation rules, reviewer assignment, document templates, notifications, and targets. Instrument configuration is declarative and limited to supported field types and validation primitives; it does not execute arbitrary code. Each published configuration is versioned and audited. Active sessions freeze the selected instrument version; historical records retain their original snapshots. Configuration changes must be versioned and audited. Active sessions freeze instrument/configuration versions. Historical records retain their original snapshots and must not be retroactively rewritten.

## 11. Release acceptance

Production release is blocked until:
- all in-scope requirements are mapped to test cases;
- official instrument content and required evidence are approved;
- authorization/RLS negative tests pass;
- offline, duplicate claim, concurrency, and recovery tests pass;
- PDF/report reconciliation is accepted;
- backup restore and rollback are rehearsed;
- UAT is signed off by Product Owner;
- no unresolved release-blocking critical/high defects remain;
- operational ownership, provider plan, privacy, and retention are approved.

## 12. Open decisions and source gaps

See Decision Register and Reference & Evidence Inventory. At minimum:
- complete authoritative IFP and Standing Bracket checklist/photo requirements;
- exact official IFP expected specification values and model applicability;
- Standing Bracket checklist detail;
- BA signatories and authority;
- executive-summary signature requirement;
- detailed report metric implementation and acceptance-test evidence;
- session pause behavior for already-open drafts and offline submissions;
- detailed attendance verification and evidence acceptance rules;
- offline package and conflict-resolution details;
- evidence limits, retention, privacy and deletion;
- supported devices/browsers and performance targets.

## 13. Change control

Every change to approved scope requires a change request, rationale, impact analysis, Product Owner approval, updated Decision Register/RTM/PRD, and regression-test impact. No unapproved feature may enter implementation.


## 14. Concurrent usage and performance baseline

The system must be designed and tested for up to **100 concurrent authenticated users** using the application at the same time. This is a capacity and performance acceptance target, not an unconditional guarantee independent of hosting plan, network, device, or workload. Before production approval, run a representative load test covering concurrent login/session reads, inspection draft saves, checklist updates, evidence metadata operations, dashboard/report reads, and claim/submit transactions. Record the tested environment, workload mix, throughput, p50/p95/p99 latency, error rate, database resource usage, and storage/network bottlenecks. No silent data loss, duplicate claim, authorization bypass, or transaction corruption is acceptable under the test load. Upload duration for photos must be measured separately from application API latency.


## Package T — Product Owner-approved decisions (2026-11-23)

The Product Owner approved the following directions:
- **T-01:** The officially issued/approved institutional source documents are the authoritative master for IFP and Standing Bracket requirements. Current transcriptions and screenshots remain reference evidence only until reconciled against those controlled sources. Instrument definitions must retain source provenance and immutable version history.
- **T-02:** BA signatory blocks are configurable per approved BA template. The template may configure number of parties, organization, role/title, order and required/optional status. Actual signatory authority and identities must still follow institutional approval; sample parties are not hardcoded as universal policy.
- **T-03:** Executive-summary signature is configurable per report template. No signature is the default unless the approved template requires one.
- **T-04:** Initial release is PDF-only for client report delivery. A client portal is deferred and requires a later approved change request.

- **T-05:** Actual reports show distinct labelled Inspected, Submitted, Approved and Completed counts. Completed = approved inspection + final PDF generated + Print Officer print action recorded. Measurement timestamp and filters are displayed; PDF open/download is not a print event.
- **T-06:** Super Admin is final project-closure authority after all gates and actual-versus-target reconciliation pass. Closure is explicit, non-automatic, reasoned and audited; no date-based auto-close.
- **T-07:** Super Admin exclusively creates/configures sessions, targets, locations, instruments and team assignments. Korlap operates assigned sessions within explicit permissions; DRAFT, ACTIVE, PAUSED and CLOSED states apply. CLOSED is terminal in ordinary flow; reopening requires privileged permission, reason and audit.
- **T-08:** Korlap verifies attendance within assigned location/scope and explicit verifier permission. Generate, print, upload, download and verify are separate permissions; upload never automatically sets VERIFIED.
- **T-13:** Initial release supports individual and bounded batch printing from a permissioned Print Officer queue, with independent per-document outcomes, failed-only retry and atomic reprint sequence. Direct printer integration is excluded; print action does not prove physical paper output.

These decisions are PO-approved product direction, not proof of institutional authorization or implementation. The official instrument masters and BA signatory authority remain external evidence dependencies. PDF delivery remains permission-controlled and auditable. Phase 0 gates remain in force; feature implementation is not authorized.


### Package T T-09 — approved offline scope (2026-11-23)

Product Owner approved option B: limited offline editing of an already claimed draft only. The online claim prerequisite and online-only privileged/finalization actions are mandatory. Idempotent synchronization, server-side authorization rechecks, explicit conflict handling and preservation of both versions are required. Offline storage activation is conditional on device and local-data safeguards; PO approval does not resolve T-10 privacy/retention or T-11 device support.


## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.


## Package T-11 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — support current mainstream browser versions with explicit exclusions.** The supported baseline is:
- Inspector field workflow: Android devices using a current stable Google Chrome release, with camera permission and evidence upload capability.
- Korlap and Reviewer: desktop Chrome or Microsoft Edge current stable releases.
- Super Admin and Print Officer: desktop Chrome or Microsoft Edge current stable releases, including PDF viewing and browser print workflow.
- Tablet layouts may be used only after responsive, camera, upload and PDF/print validation; tablet support is not presumed from viewport rendering alone.
- Explicit exclusions: obsolete/unsupported browser releases, embedded in-app browsers, modified browsers, and devices that fail required camera, upload, authentication, offline-safety or PDF/print tests.

Exact OS/device minimum versions and the tested browser build numbers must be recorded in the release/UAT compatibility matrix; this PO decision does not invent exact version numbers. The 100 concurrent authenticated-user load-test target remains the required acceptance load profile and must be tested at staged levels (10, 25, 50, 75, 100). This is a test target, not a demonstrated production capacity or service-level guarantee. Numeric latency/error-rate SLOs remain OPEN until workload and actual Supabase/Vercel plan/region/quotas are verified and baseline measurements are collected. No implementation, compatibility test or load test is claimed as executed.


### T-13 — Print workflow decision (PO approved 2026-11-23)

Initial release supports individual and bounded/configurable batch printing. Every document in a batch is independently permission-checked and receives its own success-recorded, failed or cancelled outcome. Retry may include failed documents only and must not duplicate a previously successful print event. Reprints retain the approved document version unless a controlled regeneration creates a new version; sequence allocation is atomic. A recorded print event means the authorized application action was recorded, not that physical paper output was verified. Direct printer integration is excluded from initial release.
