# Package T — Product Owner Decision Closure Pack

**Document status:** Draft for Product Owner review  
**Version:** 0.1.0  
**Date:** 2026-11-23  
**Repository branch:** `docs/phase-0-foundation`  
**Purpose:** Convert the remaining Package S scope-freeze blockers and high-risk items into explicit, reviewable Product Owner decisions.

> This pack is a decision instrument, not an approval record. Recommendations below are proposals only. A recommendation becomes an approved product decision only after the Product Owner explicitly accepts it and the Decision Register is updated.

## 1. Executive status

Package S concluded that the documentation baseline is substantial, cross-document consistency is partial, scope freeze is not ready, and feature implementation is not authorized.

Package T does not change that status by itself. It organizes decisions, identifies the lowest-risk recommended path, and defines what evidence is needed to close each gate.

### Decision states

| State | Meaning |
|---|---|
| APPROVED | Explicitly accepted by Product Owner and recorded in the Decision Register |
| REJECTED | Explicitly declined; replacement direction recorded |
| DEFERRED | Deliberately postponed with owner, due date/event, and scope consequence |
| OPEN | No explicit decision yet |
| BLOCKED | Cannot be decided responsibly until required source evidence or institutional authority is available |

Recommendations in this pack are not approvals. Explicit Product Owner approvals are recorded in Section 7 and Section 8 and in the Decision Register.

## 2. Decision summary

| ID | Topic | Current state | Recommended direction | Scope-freeze impact |
|---|---|---|---|---|
| T-01 | Official IFP and Standing Bracket master requirements | PARTIALLY CLOSED: SB official source confirmed; IFP source OPEN | Approve controlled master checklists and evidence-slot matrix from authoritative signed/issued source | Blocker |
| T-02 | BA signatories and signing authority | PO APPROVED; institutional authority OPEN | Configurable signatory blocks, ordered by document template; require explicit authorized signatory records | Blocker for final BA |
| T-03 | Executive-summary signature | PO APPROVED | No signature by default; enable only through approved template configuration | High |
| T-04 | Client report delivery | PO APPROVED | PDF-only for initial release; defer client portal | High |
| T-05 | Actual report headline/count basis | PO APPROVED | Show separate counts for inspected, submitted, approved, and completed; never collapse into one ambiguous total | Blocker for report acceptance |
| T-06 | Project closure and reconciliation | PO APPROVED | Explicit closure gate after all sessions, inspections, reviews, documents, attendance and reconciliation are complete | Blocker |
| T-07 | Session creation authority and state transitions | PO APPROVED | Super Admin creates/configures; Korlap operates assigned session within bounded transitions | Blocker |
| T-08 | Attendance verification authority | PO APPROVED | Designate explicit verifier permission and independent verification; do not infer from upload role | Blocker for verified attendance |
| T-09 | Offline scope and conflict policy | PO APPROVED (B) | Limited offline editing only for already claimed drafts; online claim and final submit/approval/admin; idempotent conflict-safe sync | Device/local-data controls remain open before activation |
| T-10 | Evidence limits, retention, deletion and privacy | PO APPROVED option B; institutional review BLOCKED | Obtain institutional records/privacy approval before setting limits and retention schedule | Blocker |
| T-11 | Supported devices, performance and service objectives | PO APPROVED option B; exact matrix/SLO validation OPEN | Approve a minimum browser/device matrix and measurable test profile before implementation acceptance | High |
| T-12 | Provider operations, region, quota, backups and ownership | BLOCKED | Verify actual Supabase/Vercel plans, region, quotas, backup/restore and named operational owners | Blocker |
| T-13 | Print Officer and print-control workflow | PO APPROVED (B) | Permissioned queue; individual + bounded batch printing; per-document outcomes and audited print/reprint events | High |
| T-14 | Inspector capacity semantics | PO APPROVED (A) | Count distinct enabled accounts with active Inspector role and effective operational assignment | High |
| T-15 | Audit event policy INS-016 | PO APPROVED (A) | Append-only catalogue; atomic audit + critical mutation; fail-closed on audit failure | Blocker until implementation and institutional controls verified |
| T-16 | Serial-number uniqueness and evidence/revision linkage | PO APPROVED (B) | Unique normalized serial within instrument type across all projects; immutable evidence-to-revision/version linkage and audited replacement | Blocker until schema, transaction and tests are reconciled |
| T-17 | Instrument configuration governance CFG-001 | APPROVED DIRECTION; detailed controls OPEN | Declarative, versioned configuration with bounded supported field and validation types; no arbitrary code | Must be completed in design |
| T-18 | Privileged command boundary | OPEN | All privileged mutations through narrowly scoped server-side commands with caller identity, authorization and atomic transactions | Blocker |

## 3. Detailed decision records

### T-01 — Authoritative instrument requirements

**Problem:** Current IFP and Standing Bracket transcriptions are useful working evidence, but they are not yet proven to be the authoritative, complete, approved master requirements. Standing Bracket source observations must remain separate where wording or item mapping differs. Photo-slot mandatory status is also unconfirmed.

**Recommendation:**
1. Obtain the current officially issued/approved checklist and supporting instrument specification for each instrument.
2. Have the responsible institutional owner confirm checklist wording, item order, applicability, expected values, evidence/photo slots and mandatory status.
3. Record source title, revision/date, issuing authority, approval evidence and effective date.
4. Publish the confirmed definitions as immutable instrument versions under CFG-001.
5. Keep historical sessions attached to the version they started with.

**Options:** (A) Approve controlled source-backed masters; (B) authorize a clearly labelled provisional pilot configuration; (C) defer instrument until evidence is supplied.

**Cost/effort:** Low to moderate documentation and validation effort; avoids expensive rework in data, UX, reports and acceptance tests.

**Risk if deferred:** The system may encode an incomplete or unofficial checklist, causing inspection disputes and invalid reports.

**Decision required:** Identify who has authority to approve each master instrument definition and whether a provisional pilot is permitted.

**State after PO response (2026-11-23): PO APPROVED option A.** Product Owner confirmed `Pemeriksaan Barang_SB.pdf` as the official Standing Bracket instrument document. Its 19 visible rows (6 physical + 13 accessories) are the official project baseline. Remaining: confirm official IFP source, any additional SB annex/specification, and photo-slot rules/mandatory status. Preserve ambiguous source wording verbatim.

### T-02 — BA signatories and signing authority

**Problem:** The available sample BA shows blocks for Tim Pemeriksaan Direktorat SD and PT Hisense International Indonesia. It does not establish a permanent signatory policy, required number/order of signatories, or authority to sign.

**Recommendation:** Make signatory blocks configurable per approved BA template, including organization, role/title, display order and required/optional status. The actual person signing must be selected from an authorized record or entered by an authorized administrator with an audit trail. Do not hardcode the sample parties as universal policy.

**Options:** (A) Two configurable parties as in sample; (B) configurable number of parties per BA template; (C) another institutionally approved signatory structure.

**Cost/effort:** Low if settled before PDF template implementation; moderate rework if changed later.

**Risk if deferred:** BA output may have incorrect legal/administrative signatory blocks.

**Decision required:** Confirm template-level flexibility and identify the authority that approves signatory names/titles.

**State after PO response (2026-11-23): PO APPROVED option B.** Configurable signatory blocks per approved template are accepted. Actual authorized signatory identities/roles and institutional approval remain OPEN/BLOCKED.

### T-03 — Executive-summary signature

**Problem:** Available evidence does not establish that the executive summary requires a signature.

**Recommendation:** No signature block by default. Permit an explicitly configured signature block only when an approved document template requires it.

**Options:** (A) No signature; (B) signature required; (C) configurable per report template.

**Cost/effort:** Low.

**Risk if deferred:** Minor template rework; avoid presenting an unapproved signature as official.

**Decision required:** Choose A, B or C.

**State after PO response (2026-11-23): PO APPROVED option C.** Signature behavior is configurable per report template; no signature by default unless the approved template requires it.

### T-04 — Client report delivery

**Problem:** PDF-only delivery versus a client-facing portal has not been approved.

**Recommendation:** PDF-only for the initial release. Keep reports generated, versioned and distributed through an authorized workflow. Defer a client portal to a later approved phase.

**Options:** (A) PDF-only; (B) portal; (C) both.

**Cost/effort:** PDF-only has the lowest implementation, security and operational cost. A portal adds identity, access, support and data-exposure requirements.

**Risk if deferred:** Scope uncertainty can expand authentication, authorization and support requirements.

**Decision required:** Approve initial delivery channel and whether portal is explicitly out of initial scope.

**State after PO response (2026-11-23): PO APPROVED option A.** PDF-only client report delivery is approved for initial release; client portal is deferred and requires a later change request.

### T-05 — Actual report headline/count basis

**Problem:** A single “actual” total can mean inspected, submitted, approved or administratively completed. These states are not equivalent.

**Recommendation:** Display distinct, labelled metrics:
- Inspected: an inspection record has been started/recorded according to the approved metric definition.
- Submitted: a revision has been submitted for review.
- Approved: a reviewer has approved the relevant revision.
- Completed: approved inspection + final PDF generated + Print Officer print action recorded.

Use the existing completion definition for Completed. The report must state its measurement timestamp and filters. Do not infer physical printing from PDF opening or downloading.

**Options:** (A) Distinct state counts (recommended); (B) one approved-count headline with supporting breakdown; (C) another explicitly defined metric.

**Cost/effort:** Low to moderate; requires metric definitions and report labels.

**Risk if deferred:** Reports may overstate progress or mislead institutional stakeholders.

**Decision required:** Approve the primary headline metric while retaining state breakdowns.

**State after PO response (2026-11-23): PO APPROVED option A.** Actual reports must display distinct labelled counts for Inspected, Submitted, Approved and Completed. Completed remains approved inspection + final PDF generated + Print Officer print action recorded. Report measurement timestamp and filters must be visible; opening/downloading a PDF is not a print event.

### T-06 — Project closure and reconciliation

**Problem:** Exact final project close conditions and reconciliation authority need explicit approval.

**Recommendation:** Use explicit, non-automatic project closure. A project may be closed only after:
1. All sessions are closed.
2. No unresolved claims, drafts, corrections or pending reviews remain.
3. Required inspections have reached the required final state.
4. Required PDFs and print events are recorded.
5. Required BA and attendance artifacts are complete and verified according to policy.
6. Actual-versus-target reconciliation is reviewed.
7. Authorized closer records a reason/confirmation and the system writes an audit event.

Do not auto-close by date. Any exception should use a separately permissioned, reasoned override with audit.

**Options:** (A) Super Admin closes after all gates; (B) Korlap requests and Super Admin confirms; (C) another approved authority model.

**Cost/effort:** Moderate workflow and reporting design.

**Risk if deferred:** Projects can appear complete while operational or documentary obligations remain unresolved.

**Decision required:** Confirm who requests, validates and finally authorizes project closure, and whether exceptions are allowed.

**State after PO response (2026-11-23): PO APPROVED option A.** Super Admin is the final project-closure authority after all gates and actual-versus-target reconciliation pass. Closure is explicit, non-automatic, reasoned and audited. No date-based auto-close; any exception requires separately permissioned override, reason and audit.

### T-07 — Session creation authority and state transitions

**Problem:** Session creation authority and complete transition rules are not fully locked.

**Recommendation:** Super Admin exclusively creates and configures sessions, target, location, instrument and team assignments. Korlap operates only assigned sessions and may activate, pause, resume or request closure only if the approved permission matrix grants those actions. Proposed states: DRAFT, ACTIVE, PAUSED, CLOSED. CLOSED is terminal for ordinary operation; reopening requires explicit privileged permission, reason and audit.

**Options:** (A) Recommended authority/state model; (B) Super Admin performs all state transitions; (C) institution-defined alternative.

**Cost/effort:** Low if approved before command/API design.

**Risk if deferred:** Conflicting authority and inconsistent session lifecycle behavior.

**Decision required:** Approve creator, transition authority, terminal-state behavior and reopening rule.

**State after PO response (2026-11-23): PO APPROVED option A.** Super Admin exclusively creates/configures sessions, targets, locations, instruments and team assignments. Korlap may activate, pause, resume or request closure only within assigned scope and granted permissions. States are DRAFT, ACTIVE, PAUSED, CLOSED. CLOSED is terminal in ordinary flow; reopening requires explicit privileged permission, reason and audit.

### T-08 — Attendance verification authority

**Problem:** Attendance upload and verification are distinct actions, but verifier authority is unresolved.

**Recommendation:** Separate permissions for generate, print, upload, download and verify. The verifier must be explicitly assigned by Super Admin or granted through an approved role/scope rule. Uploading a file must never automatically mark attendance VERIFIED.

**Options:** (A) Korlap verifies within assigned location; (B) designated Reviewer verifies; (C) dedicated attendance verifier; (D) another approved model.

**Cost/effort:** Low to moderate.

**Risk if deferred:** Uploaded attendance could be mistaken for verified evidence.

**Decision required:** Choose verifier role and scope, including whether the uploader may verify the same artifact.

**State after PO response (2026-11-23): PO APPROVED option A.** Korlap verifies attendance within assigned location/scope. Generate, print, upload, download and verify are separate permissions; upload never automatically marks an artifact VERIFIED. Super Admin assigns/grants verifier authority.

### T-09 — Offline scope and conflict policy

**Problem:** Offline behavior and supported device/browser requirements remain unresolved. Full offline operation would significantly increase security, synchronization and recovery complexity.

**Recommendation:** Online-first initial release. If limited offline support is required, permit editing only on an already claimed draft with locally persisted work. Do not allow offline claim, approval, final submit, role/scope changes, session administration or other privileged actions. On reconnect, use idempotent synchronization, explicit conflict detection and user-visible resolution; never silently overwrite a newer revision. Local data protection and purge rules must be approved before enabling offline persistence.

**Options:** (A) Online-only; (B) limited offline draft editing; (C) full offline workflow (not recommended for initial release).

**Cost/effort:** Online-only lowest cost; limited offline moderate/high; full offline high.

**Risk if deferred:** Unbounded offline scope creates substantial schedule, security and data-loss risk.

**Decision required:** Is offline operation required for initial rollout? If yes, choose B and approve device/local-data controls.

**State after PO response (2026-11-23): PO APPROVED option B.** Initial release supports limited offline draft editing only for an already claimed inspection unit, where the claim was acquired online. Offline claim acquisition, approval, final submission, role/assignment changes, session administration and privileged actions are prohibited. Reconnection uses authenticated, idempotent synchronization with server-side authorization rechecks, explicit conflict detection, preservation of both local and server versions, and no silent last-write-wins. Offline persistence must not be enabled in production until device/browser support, local-data protection, retention/purge, shared-device logout and recovery controls are approved. T-10 privacy/records retention remains a separate BLOCKED decision.

### T-10 — Evidence limits, retention, deletion and privacy

**Problem:** Institutional data classification, lawful basis, retention periods, deletion authority, legal hold and evidence size/type limits are not approved.

**Recommendation:** Obtain written institutional privacy/records approval before production evidence collection. Then define:
- data classification and permitted personal information;
- allowed file types, per-file and per-inspection size limits;
- retention schedule by record class;
- legal hold and investigation freeze;
- deletion eligibility, approval and audit;
- private object access and time-limited authorized retrieval;
- backup/restore and post-deletion treatment;
- local/offline copy protection if applicable.

Until approved, do not invent retention periods or implement irreversible deletion.

**Options:** (A) institution supplies approved schedule; (B) formal records/legal review before schedule; (C) pilot with restricted evidence and explicit temporary handling policy approved by institution.

**Cost/effort:** Moderate governance effort; prevents legal/privacy remediation later.

**Risk if deferred:** Unlawful or unsafe retention/deletion, uncontrolled sensitive evidence, or inability to meet records obligations.

**Decision required:** Name the institutional records/privacy approver and provide approved classification/retention direction.

**State after PO response (2026-11-23): PO APPROVED option B.** Formal institutional records/legal/privacy review is the required path before the evidence policy is defined. Institutional approval and written policy remain BLOCKED; no numeric limits or retention periods are approved.

### T-11 — Supported devices, performance and service objectives

**Problem:** The 100 concurrent-user figure is a test target, not a demonstrated capacity or service-level commitment. Browser/device matrix and numeric performance objectives are not final.

**Recommendation:** Approve a minimum support matrix before implementation: supported desktop/mobile operating systems, browsers and minimum versions, camera permissions, upload behavior, print/PDF behavior and network assumptions. Establish measurable test scenarios for 100 concurrent authenticated users, evidence upload, review queue, report generation and synchronization. Set numeric SLOs only after workload definition and provider verification.

**Options:** (A) Institution-owned managed device/browser matrix; (B) current mainstream browser versions with explicit exclusions; (C) broader support after cost review.

**Cost/effort:** Moderate testing; broad compatibility increases QA cost.

**Risk if deferred:** Unclear acceptance criteria and unbounded device support.

**Decision required:** Approve device/browser baseline and whether 100 concurrent users is the required acceptance load profile.

**State after PO response (2026-11-23): PO APPROVED option B.** Mainstream stable browser baseline with explicit exclusions is accepted. Exact OS/device and browser build versions must be validated and recorded in UAT. The 100 concurrent-user load profile remains an acceptance test target; numeric SLOs remain OPEN pending provider/workload verification.

### T-12 — Provider operations, region, quota, backup and ownership

**Problem:** Supabase/Vercel plan, region/data residency, quotas, billing owner, backup and point-in-time recovery capabilities, Storage recovery, operational contacts and restore evidence have not been verified.

**Recommendation:** Keep the approved cost-first Supabase + Vercel architecture, but require a pre-production verification sheet containing:
- actual account/project ownership and billing owner;
- selected region and institutional approval;
- plan/quotas and expected usage envelope;
- PostgreSQL backup/PITR capability and retention;
- Storage object backup/recovery approach;
- environment separation and secret ownership;
- two operational recovery contacts;
- restore drill evidence and measured recovery results;
- monitoring, incident response and escalation responsibility.

Do not assume a provider feature or plan capability without checking the actual subscribed plan and project settings.

**Options:** (A) institution owns provider accounts; (B) organization-owned accounts with named custodians; (C) another formally approved ownership arrangement.

**Cost/effort:** Verification effort low/moderate; production costs depend on verified plan and usage.

**Risk if deferred:** Data residency, billing, access continuity and recoverability remain unproven.

**Decision required:** Confirm account owner, billing owner, region approver and operational recovery contacts.

**State:** PO APPROVED option C (2026-11-23); actual ownership arrangement, provider verification and institutional authorization remain BLOCKED.

### T-13 — Print Officer and print-control workflow

**Problem:** Print Officer screens, batch operations, printer assumptions and failure/reprint handling need more detail.

**Recommendation:** Dedicated permissioned queue for approved inspections with final PDFs. Print Officer records each print action, actor, timestamp, document version and print sequence. Reprints retain the same approved document version unless a controlled regeneration creates a new version. Display “Cetak ke-2” or equivalent from the recorded sequence. Support individual and carefully bounded batch printing, with per-document outcomes and retry handling. A print event records the application action, not proof that paper physically emerged from a printer.

**Options:** (A) Individual print only for initial release; (B) individual + batch print; (C) direct printer integration.

**Cost/effort:** A is lowest cost; B moderate; C higher and device-specific.

**Risk if deferred:** Inconsistent print records and manual operational workarounds.

**Decision required:** Approve initial print mode and the meaning/limits of a recorded print event.

**State after PO response (2026-11-23): PO APPROVED option B.** Initial release supports both individual and batch printing. Batch size must be bounded/configurable; every document receives an independent outcome (success recorded, failed, or cancelled). Retry is limited to failed documents and must not duplicate successful print events. Reprint sequence allocation is atomic. The application records an authorized print action; it does not prove physical paper output. Direct printer integration is not included in this decision.

### T-14 — Inspector capacity semantics

**Problem:** Approved cap contract is minimum 1, default 50, maximum 100 distinct active Inspector accounts combined across both locations. The precise definition of an account counted as active Inspector is resolved by PO approval of T-14 option A.

**Recommendation:** Count distinct user accounts that are enabled for login, have an active Inspector role grant, and have at least one currently effective operational Inspector assignment within the governed project/session scope. Count each account once even if it has multiple assignments or roles. Exclude pending, rejected, suspended, disabled and expired-role accounts. If the institution intends a different meaning (for example, all users with an Inspector role regardless of current assignment), explicitly choose it.

The enforcement must be atomic. Reject 0 and values above 100. If reducing the cap below the current count, reject the change until the count is within the new cap; do not silently deactivate accounts.

**Options:** (A) Count enabled users with active Inspector role and effective assignment (recommended); (B) count all enabled users with active Inspector role regardless of assignment; (C) institution-defined predicate.

**Cost/effort:** Low; important for deterministic enforcement.

**Risk if deferred:** Capacity enforcement can differ across UI, API and database.

**Decision required:** Approve the canonical active-account predicate.

**State:** OPEN.

### T-15 — Audit event policy INS-016

**Problem:** Append-only audit catalogue and atomic write requirements are proposed but not approved.

**Recommendation:** Approve INS-016 as a mandatory control for critical business/security/governance actions. Critical state mutation and its audit event must commit atomically; if the audit write fails, the critical mutation fails closed. Restrict update/delete privileges on audit records, record actor, active role, scope, action, timestamp, correlation/idempotency reference and privacy-safe change context. Access/export of sensitive evidence should itself be auditable. Retention and legal-hold policy remains subject to T-10.

**Options:** (A) Approve the proposed INS-016 controls; (B) approve with documented exceptions; (C) replace with an institution-approved audit standard.

**Cost/effort:** Moderate database and command design effort; lower than retrofitting audit after launch.

**Risk if deferred:** Critical actions may not be reconstructable or attributable.

**Decision required:** Approve the catalogue and fail-closed atomicity rule, or provide the governing alternative.

**State after PO response (2026-11-24): PO APPROVED option A.** Append-only audit records and atomic/fail-closed audit writes for critical mutations are approved. Institutional retention/legal-hold/metadata decisions and technical implementation evidence remain open.

### T-16 — Serial uniqueness and evidence/revision linkage

**Problem:** Serial-number uniqueness scope and exceptions are not final. Evidence must be tied to the exact inspection revision and instrument version to preserve historical integrity.

1. Bind each evidence record to an immutable inspection revision and instrument version.
2. Preserve original evidence metadata, checksum, uploader, capture/upload time and storage object identity.
3. Do not overwrite evidence in place; replacement creates a new evidence record and audit event.
4. Do not assume serial numbers are globally unique across instrument types, suppliers or projects.
5. Approve a uniqueness rule only after confirming whether duplicate serials can legitimately occur across instrument categories, projects, locations or supplier batches.
6. Provide a controlled duplicate-resolution workflow with reason and audit rather than silently rejecting or merging historical records.

**Options:** (A) Unique within instrument type + project; (B) unique within instrument type across all projects; (C) no hard uniqueness constraint, duplicate warning and controlled review; (D) institution-provided rule.

**Cost/effort:** Moderate; impacts database constraints and claim/inspection transaction logic.

**Risk if deferred:** False duplicate rejection or duplicate physical-unit records.

**Decision required:** Approve serial uniqueness scope and duplicate handling.

**State after PO response (2026-11-24): PO APPROVED option B.** Within one instrument type, a normalized serial number is unique across all projects. The uniqueness key is instrument type + normalized serial, not project + instrument. The rule does not assert uniqueness across different instrument types. A detected cross-project duplicate within the same instrument type is a conflict requiring controlled, reasoned and audited resolution; the system must not silently merge records or discard history. Evidence is bound to the exact immutable inspection revision and instrument version; original metadata, checksum, uploader, capture/upload timestamps and storage object identity are preserved. Evidence is never overwritten in place; replacement creates a new evidence record and audit event. This is Product Owner direction; source/institutional exception policy and implementation verification remain open.

### T-17 — Instrument configuration governance CFG-001

**Approved direction:** Super Admin manages configurable instrument definitions; IFP and Standing Bracket are initial configurations, not hardcoded permanent limits.

**Required design completion:**
- supported declarative field types and validation primitives;
- checklist section/item ordering and applicability;
- expected values/specification fields;
- evidence-slot definitions and mandatory/conditional rules;
- draft/publish/deactivate/version lifecycle;
- permissions and approval/audit rules for configuration changes;
- immutable published versions and active-session version pinning;
- historical inspection snapshot behavior;
- compatibility/migration policy when a new version is published.

**Recommendation:** Keep configuration declarative and bounded. Do not allow arbitrary scripts, SQL, executable expressions or unrestricted user-supplied code. Super Admin should be able to draft and publish a version only through validated supported primitives.

**Risk if deferred:** “Configurable” may become unsafe or ambiguous, and historical results may change meaning.

**Decision required:** Confirm whether Super Admin may publish instrument versions directly or whether a second approval is required.

**State:** APPROVED DIRECTION; detailed publication governance OPEN.

### T-18 — Privileged command boundary

**Problem:** The API/database boundary for privileged mutations is drafted but not approved.

**Recommendation:** Use server-side command endpoints/functions for state-changing operations. Each command must:
- validate caller identity from a trusted authenticated context;
- derive actor identity server-side, never trust a client-supplied actor ID;
- check permission, role, scope, assignment and separation-of-duties rules;
- validate state transition and input;
- enforce idempotency for retryable operations;
- execute business mutation and required audit write in one transaction;
- use least privilege and narrowly scoped database function grants;
- prevent clients from directly mutating protected tables;
- return stable, typed outcomes and safe error codes.

Security-definer functions, if required, must pin search_path, validate inputs and have minimal ownership/grants. No broad service-role credential may be exposed to the browser.

**Options:** (A) Approve the proposed Vercel server route + caller-JWT PostgreSQL command-function pattern; (B) alternative reviewed command architecture; (C) defer privileged mutations (not compatible with feature implementation).

**Cost/effort:** Moderate; foundational architecture work.

**Risk if deferred:** Authorization rules may be bypassed or inconsistently enforced.

**Decision required:** Approve command boundary and direct-DML denial policy.

**State:** OPEN; implementation blocked.

## 4. Recommended decision order

Resolve decisions in this order to minimize rework:

1. **Institutional authority and source evidence:** T-01, T-02, T-10, T-12.
2. **Core operational governance:** T-06, T-07, T-08, T-14, T-15.
3. **Data integrity and security architecture:** T-16, T-18, and detailed CFG-001 controls in T-17.
4. **Operational product behavior:** T-04, T-05, T-09, T-13.
5. **Acceptance and quality baseline:** T-03, T-11.

A deferred decision must identify the affected feature as excluded or blocked. Deferral must not be interpreted as implied approval.

## 5. Scope-freeze gate mapping

| Gate | Required evidence | Related decisions |
|---|---|---|
| Authoritative instrument masters | Approved IFP/SB source, reconciled checklist and evidence matrix | T-01, T-17 |
| BA and report templates | Approved signatory policy and report delivery/count rules | T-02, T-03, T-04, T-05 |
| Session/project lifecycle | Approved authority, transitions and close/reconciliation rules | T-06, T-07 |
| Attendance | Named verifier role and workflow | T-08 |
| Offline and devices | Approved online/offline scope, local-data policy, support matrix | T-09, T-11 |
| Privacy and evidence | Institutional classification, retention, deletion and legal-hold approval | T-10 |
| Provider operations | Region, ownership, plan/quotas, backup/restore and recovery evidence | T-12 |
| Printing | Print queue, print event and reprint rules | T-13 |
| Inspector capacity | Canonical count predicate and atomic enforcement | T-14 |
| Audit | Approved INS-016 controls and event requirements | T-15 |
| Database integrity | Serial uniqueness, evidence/revision/version constraints | T-16 |
| Instrument configuration | Complete declarative schema and publish/version governance | T-17 |
| Privileged commands | Approved command boundary and grants/RLS interaction | T-18 |

## 6. Approval recording protocol

For each decision, the Product Owner response must identify one of:
- **Approve** — accept the recommended direction.
- **Reject** — reject it and state the replacement direction.
- **Defer** — postpone with a reason and a trigger/date for reconsideration.
- **Need evidence** — specify the source, authority or evidence needed.

After explicit decisions:
1. Update `DECISION-REGISTER.md` with stable decision IDs, decision text, date, approver/authority and rationale.
2. Update affected PRD, functional design, architecture, security, QA, RTM and RAID documents.
3. Fetch the changed files back from GitHub and verify the exact committed content.
4. Re-run cross-document consistency review.
5. Update the scope-freeze gate status only when evidence is present.
6. Keep PR #2 draft and do not merge until every mandatory gate is closed and explicitly accepted.

## 7. Non-authorization statement

This package does not authorize:
- application feature implementation;
- database migration creation or execution;
- production Supabase/Vercel configuration;
- deployment or production data collection;
- claiming that RLS, audit, backup, restore, load or security controls are implemented or tested.

**Current overall status remains: NOT READY FOR SCOPE FREEZE; FEATURE IMPLEMENTATION NOT AUTHORIZED.**

## Package T — Product Owner decision outcomes (2026-11-23)

| Decision | PO outcome | Requirement / traceability consequence | Residual status |
|---|---|---|---|
| T-01 | PO APPROVED: official source documents are authoritative masters; SB document confirmed | SB 19-row source baseline is confirmed; retain provenance and reconcile prior screenshot transcription separately | PARTIALLY CLOSED: IFP source and SB photo/evidence rules remain open |
| T-02 | APPROVED: configurable BA signatory blocks per approved template | Add verification for configurable party count, organization, role/title, order and required/optional status | OPEN for actual authorized signatory identities/authority and final institutional template |
| T-03 | APPROVED: signature behavior configurable per report template; default none unless required | Add template configuration and PDF verification; do not hardcode a universal executive-summary signature | PO decision closed; approved template requirement still controls |
| T-04 | APPROVED: PDF-only client report delivery in initial release | Client portal excluded from initial release; controlled PDF generation/access/distribution remains in scope | PO decision closed; later portal needs change request |

PO approval does not replace institutional authorization or source evidence. T-01 through T-09 have explicit PO outcomes; T-10 option B is PO APPROVED as the formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED; the actual alternative arrangement and institutional/provider verification remain BLOCKED. T-13 is PO APPROVED option B; T-14 is PO APPROVED option A; T-15 through T-18 remain OPEN/BLOCKED. No implementation authorization is granted by these decisions.

## 8. Product Owner decision outcomes — T-05 through T-08 (2026-11-23)

| ID | Approved outcome | State / implementation qualification |
| T-05 | A — Distinct labelled counts for Inspected, Submitted, Approved and Completed. Completed = approved inspection + final PDF generated + Print Officer print action recorded. | PO APPROVED; metric implementation and report tests remain pending. |
| T-06 | A — Super Admin closes project only after all closure gates and actual-versus-target reconciliation pass. Explicit, non-automatic, reasoned and audited. | PO APPROVED; gate enforcement and tests remain pending. |
| T-07 | A — Super Admin creates/configures sessions; Korlap operates assigned sessions within granted permissions. DRAFT, ACTIVE, PAUSED, CLOSED; CLOSED terminal in ordinary flow. | PO APPROVED; reopening requires privileged permission, reason and audit. State/permission tests remain pending. |
| T-08 | A — Korlap verifies attendance within assigned location/scope. Generate, print, upload, download and verify are separate permissions; upload never automatically verifies. | PO APPROVED; Super Admin assigns/grants verifier authority; implementation and tests remain pending. |

The Product Owner explicitly approved T-05=A, T-06=A, T-07=A and T-08=A on 2026-11-23; T-09 option B was subsequently approved on 2026-11-23. T-10 option B is PO APPROVED as the formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED; the actual alternative arrangement and institutional/provider verification remain BLOCKED. T-13 is PO APPROVED option B; T-14 is PO APPROVED option A; T-15 through T-18 remain OPEN/BLOCKED. No implementation authorization is granted by these decisions.

## Package T — T-09 Product Owner decision (2026-11-23)

The Product Owner explicitly approved **T-09 option B — limited offline draft editing**. This is a product-scope decision, not authorization to enable offline persistence before local-data security and institutional retention controls are approved.

- Offline work is permitted only for an already claimed draft whose claim was acquired online.
- Claim acquisition, approval, final submission, role/assignment changes, session administration and privileged actions require connectivity.
- Reconnection is authenticated and idempotent; server authorization and current claim/state are rechecked.
- Stale/conflicting writes are rejected and surfaced; preserve both sides for authorized resolution; never use silent last-write-wins.
- Required evidence must be server-confirmed before final submission.
- Browser/device matrix, local-data protection, shared-device/logout behavior, retention/purge and recovery remain open dependencies under T-10/T-11.

T-09 is PO-approved; implementation, device controls and verification remain pending. Scope freeze remains NOT READY and feature implementation remains NOT AUTHORIZED.

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

## Package T-12 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option C — an alternative provider-ownership arrangement, subject to formal institutional approval and written definition.** The Product Owner does not designate a specific legal entity, account holder, billing owner, custodian, or contractual arrangement in this approval. Those identities and responsibilities must not be inferred or invented.

Before any production provider account or production data is used, the institution must document and authorize the selected arrangement, including: (1) legal/account owner for Supabase and Vercel; (2) billing owner, payment method and budget authority; (3) named primary and secondary provider custodians/recovery contacts; (4) access grant, MFA, least-privilege and offboarding controls; (5) project/data ownership and transfer/exit rights; (6) region and data-residency approver; and (7) incident, backup, restore and escalation responsibility. The arrangement must ensure continuity if a developer or individual custodian leaves.

This PO decision approves the alternative-arrangement path only. It does not establish institutional authorization, identify the actual owner/custodians, approve a region or provider plan, approve billing, or prove backup/recovery capability. Provider plan/quotas, region, budget, RPO/RTO, Storage object recovery and restore-drill evidence remain OPEN/BLOCKED until verified against actual accounts and approved by authorized institutional parties. No production data deployment or production readiness is authorized by this decision. No implementation or restore test is claimed as executed.

## Package T — T-13 Product Owner decision (2026-11-23)


This is PO product direction only. Detailed batch limits, UI behavior, browser print behavior, and test evidence remain to be finalized and validated. No implementation or tests are claimed. T-14 through T-18 remain open; scope freeze remains NOT READY and feature implementation remains NOT AUTHORIZED.


**State after PO response (2026-11-23): PO APPROVED option B.** Initial release supports individual and batch printing. Batch size must be bounded/configurable; every document receives an independent outcome (success recorded, failed, or cancelled). Retry is limited to failed documents and must not duplicate successful print events. Reprint sequence allocation is atomic. The application records an authorized print action; it does not prove physical paper output. Direct printer integration is not included.




### T-14 — Inspector capacity counting predicate

**Decision (2026-11-24): PO APPROVED option A.** Count distinct user accounts that are enabled for login, have an active Inspector role grant, and have at least one currently effective operational Inspector assignment within the governed project/session scope. Count each account once even when it has multiple assignments or roles. Exclude pending, rejected, suspended, disabled, and expired-role accounts. Enforce the already-approved combined cap atomically across both locations (minimum 1, default 50, maximum 100); reject 0 and values above 100. A cap reduction below the current qualifying-account count must be rejected until the count is brought within the proposed cap; never silently deactivate accounts.

This is a Product Owner decision defining the counting predicate. It does not authorize implementation, and does not change the cap values. Database, authorization, API, and test specifications must use the same predicate. Scope freeze remains NOT READY and feature implementation remains NOT AUTHORIZED.


### T-14 clarification — account registration and Super Admin-controlled staffing (2026-11-24)

The Inspector lifecycle is ordered: a person must first register/authenticate and obtain an application account; registration alone grants no operational access and does not count toward Inspector capacity. Super Admin then approves/activates the account and explicitly assigns its role(s), project/session/location scope, team membership and operational assignment. Super Admin controls the number of teams and the number/identity of personnel assigned to each team, subject to the approved Inspector capacity and applicable project/session plan. Only a registered, enabled account with an active Inspector role grant and at least one currently effective operational Inspector assignment counts once toward the combined Inspector cap. Users cannot self-select teams, roles, or assignments.



## Package T — T-15 Product Owner decision (2026-11-24)

**Decision: PO APPROVED option A — approve the proposed INS-016 audit controls.** The Product Owner approves the append-only audit event catalogue and the following mandatory controls for critical actions:

1. Audit records are append-only through application operations; ordinary application roles cannot update or delete recorded events.
2. Each critical business/security/governance mutation and its audit event commit in the same database transaction. If the audit insert fails, the critical mutation fails closed and rolls back.
3. Events record actor identity, active role, applicable scope, action/event type, timestamp, correlation and idempotency references, and privacy-safe change context.
4. Access to and export of sensitive inspection evidence are auditable events.
5. Audit access is least-privilege and separately permissioned; payloads must not contain secrets, credentials, raw evidence, or unnecessary personal data.
6. Audit retention, deletion/disposition, legal hold, and network metadata remain governed by T-10 and institutional records/privacy/security approvals. This decision does not invent retention periods or approve IP/network metadata collection.

**Boundary:** This is Product Owner approval of the INS-016 product/technical control direction. It is not institutional approval of retention, legal hold, classification, WORM archive, network metadata, or provider capabilities. Schema, RLS, command grants, transaction behavior and tests still require detailed reconciliation and implementation evidence. No migration, code, test execution or production activation is claimed. Scope freeze remains NOT READY and feature implementation remains NOT AUTHORIZED.
