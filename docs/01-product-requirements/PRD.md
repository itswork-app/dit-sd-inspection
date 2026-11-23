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
2. Initial instruments are only Interactive Flat Panel (IFP) and Standing Bracket.
3. There are two inspection locations in the initial project.
4. Inspector capacity starts at 50 users and may be increased by Super Admin, but must remain up to 100 (hard maximum 100) across both locations combined. Allocation between locations is controlled by Super Admin; the capacity is not per location.
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
- Instrument and checklist configuration with versioning and historical snapshots.
- Serial number entry/capture, unit claim, duplicate prevention, and recovery.
- IFP and Standing Bracket checklists and photo/evidence capture.
- Limited offline draft inspection and safe synchronization.
- Pre-submit validation, immutable submission versions, reviewer correction and approval.
- PDF generation, print/reprint tracking, BA, attendance evidence.
- Actual and Target reporting, role-specific dashboards, notifications, and audit.
- Production operations, security, backup/restore, monitoring, and recovery.

### 4.2 Out of scope unless separately approved
- Instruments other than IFP and Standing Bracket.
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
3. Print Officer prints the approved PDF; system records actor, time, document, and print count.
4. Reprint is allowed and visibly numbered (e.g. "Cetak ke-2").
5. Print action is a recorded user action; the system cannot prove paper physically emerged from a printer.
6. Per-unit wet signature is completed on paper; the print event does not imply signature completion.

### 6.6 Session closure
Korlap confirms closure only when configured closure requirements are satisfied. The system must block closure while required inspections, reviews, print actions, BA/attendance documents, or other configured deliverables remain incomplete. Exact transition model and final authority remain subject to Product Owner approval.

## 7. Functional requirement groups

| ID | Requirement | Priority | Acceptance summary |
|---|---|---|---|
| AUTH-001 | Google sign-in | Must | Valid identity can authenticate; unauthorized identity cannot access data |
| AUTH-002 | Pending account approval | Must | New user cannot operate until approved and assigned |
| RBAC-001 | Multi-role and scoped permission model | Must | Every operation enforces explicit role, permission, and assignment scope |
| CAP-001 | Maximum 50 Inspectors across two locations combined | Must | System rejects activation/assignment that would exceed approved project cap |
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
- Offline mode is limited to approved Inspector draft workflows.
- Final submit, review, approval, PDF finalization, and print events require server connectivity.
- Local data is retained until server acknowledgement; conflict resolution must preserve both sides/evidence.
- Exact offline cache encryption, supported devices/browsers, retention and recovery policy remain open technical decisions.

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
- Headline count basis, reconciliation, client delivery mechanism, and final project closure are still OPEN.

## 10. Configuration and history

Super Admin may configure approved operational settings, including roles/permissions, checklist items, photo slots, validation rules, reviewer assignment, templates, notifications, and targets. Configuration changes must be versioned and audited. Active sessions freeze instrument/configuration versions. Historical records retain their original snapshots and must not be retroactively rewritten.

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
- report headline/count basis and client delivery channel;
- session creation authority and state transitions;
- attendance verification authority;
- offline package and conflict-resolution details;
- evidence limits, retention, privacy and deletion;
- supported devices/browsers and performance targets.

## 13. Change control

Every change to approved scope requires a change request, rationale, impact analysis, Product Owner approval, updated Decision Register/RTM/PRD, and regression-test impact. No unapproved feature may enter implementation.


## 14. Concurrent usage and performance baseline

The system must be designed and tested for up to **100 concurrent authenticated users** using the application at the same time. This is a capacity and performance acceptance target, not an unconditional guarantee independent of hosting plan, network, device, or workload. Before production approval, run a representative load test covering concurrent login/session reads, inspection draft saves, checklist updates, evidence metadata operations, dashboard/report reads, and claim/submit transactions. Record the tested environment, workload mix, throughput, p50/p95/p99 latency, error rate, database resource usage, and storage/network bottlenecks. No silent data loss, duplicate claim, authorization bypass, or transaction corruption is acceptable under the test load. Upload duration for photos must be measured separately from application API latency.
