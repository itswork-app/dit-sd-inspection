# Package I — Final Product Owner Decision & Scope Freeze Preparation

**Status:** Decision worksheet — recommendations are NOT approvals  
**Version:** 0.1.0  
**Date:** 2026-11-23  
**Branch:** docs/phase-0-foundation

## 1. Purpose

Package I converts the remaining Package F–H findings into a concise decision worksheet. It distinguishes approved baseline decisions, source-derived facts, recommended defaults, and decisions requiring explicit Product Owner or institutional authority.

This package does not approve decisions on the user's behalf and does not authorize feature implementation, merge, production deployment, or scope freeze.

## 2. Decision status vocabulary

- **APPROVED:** explicitly accepted by the authorized owner or already recorded as an approved decision.
- **SOURCE-OBSERVED:** directly visible in supplied legacy screenshots or sample documents; not automatically an institutional policy.
- **RECOMMENDED — PENDING:** engineering recommendation awaiting explicit approval.
- **OPEN:** insufficient evidence or authority to decide.
- **BLOCKED:** must be resolved before scope freeze or implementation of the affected capability.

## 3. Existing approved baseline — do not reopen without change request

| Area | Approved baseline |
|---|---|
| Product | Replacement inspection application for Direktorat Sekolah Dasar; not SaaS |
| Initial instruments | IFP and Standing Bracket only |
| Delivery target | Production |
| Engineering priority | Cost-first without weakening security, integrity, privacy, recovery, or reliability |
| Platform | Supabase + Vercel; GitHub source control and CI |
| Database | Supabase PostgreSQL is the sole primary source of truth |
| Identity | Google sign-in; new users pending approval; role assignment by authorized Super Admin |
| RBAC | Multiple roles allowed; operational scope explicit by assignment/session/location/instrument; no self-elevation or self-review |
| Workflow | Reviewer returns corrections to Inspector; immutable version history; authorized reopen with reason and audit |
| Reports | Actual and Target are separate; actual timestamps never rewritten to fit targets |
| Per-unit documents | Wet signature in Phase 1; approval + final PDF + recorded print action defines per-unit completion |
| Inspector capacity | Configurable minimum 1, default 50, hard maximum 100 distinct active Inspector accounts across both locations combined. |
| Performance | 100 concurrent authenticated users is a load-test target, not a proven capacity claim |
| Offline | High-level limited offline inspection and safe sync approved; detailed technical and recovery contract remains to be finalized |

## 4. Source-observed evidence baseline

These statements are limited to the user-supplied photographs/PDF and the legacy screenshots already reviewed.

| Evidence | Directly observed | Not established by this evidence |
|---|---|---|
| IFP filled inspection PDF | IFP model/identity fields, physical and packaging serials, five checklist sections, visible checklist statements, Ya/Tdk response presentation, signature area | Controlled checklist revision/issuing authority; complete photo-slot rules; whether sample is the canonical template |
| Standing Bracket checklist screenshots | 19 distinct visible checklist rows; second image repeats two rows due scroll overlap | Complete checklist; full category names; N/A/conditional behavior; mandatory photo rules |
| Standing Bracket serial annex | Serial-number table, BAIK/CACAT condition column, separate good/defective documentation references, two paraf blocks, 13 sample rows marked BAIK | Fixed row limit; universal all-good outcome; authoritative template revision; mandatory paraf rules |
| BA sample | IFP and SB summary rows; inspected/good/defective columns; two party blocks | Authorized signatories, whether both parties are mandatory in all cases, canonical template |
| Attendance sample | Name and institution columns; one attendance column for each of three activity dates | Verification authority; exact required personnel fields; canonical template revision |

No personal names, NIP values, or other personal identifiers from the sample attendance sheet are needed in the software specification or test fixtures.

## 5. Decision worksheet

### I-01 — Inspector capacity bounds

**Approved:** minimum 1, default 50, maximum 100 distinct active Inspector accounts combined across both locations. Super Admin may configure any integer in the range 1–100. Capacity counts distinct active Inspector accounts once, regardless of assignments. Any reduction below the current active count must be rejected until the count is brought within the new cap; do not silently deactivate accounts.

**Status:** APPROVED — recorded in OPS-001 following user confirmation on 2026-11-23.

### I-02 — IFP and Standing Bracket source authority

**Source-observed:** the supplied photographs and PDF establish a usable baseline for visible legacy content.

**Recommendation:** approve the supplied references as the reconstruction baseline for Phase 1 parity, while recording the exact source image/PDF and transcribed content version. Any unreadable, cropped, or absent item must remain an explicit gap and require instrument-owner confirmation. Do not fabricate checklist rows or photo slots.

**Required before freeze:** confirm that the visible content is the intended current operational checklist, and resolve the Standing Bracket ambiguous quantity transcription “Ring/klem Roda (4 pcs) + 4 (4pcs)”.

**Status:** BLOCKED pending authorized confirmation of completeness and current validity.

### I-03 — BA signatory blocks

**Source-observed:** two blocks are present in the sample: Tim Pemeriksaan Direktorat SD and PT Hisense International Indonesia.

**Recommendation:** make block label, organization, representative name, title, order, and optional identity fields configurable and versioned. Require both blocks for the sample-equivalent supplier/factory visit BA only if the institutional document owner confirms; do not infer signatory authority from application roles.

**Status:** RECOMMENDED — PENDING institutional confirmation.

### I-04 — Executive summary signature

**Recommendation:** no signature block by default unless the approved official template requires one. If required, use versioned configurable signatory metadata.

**Status:** RECOMMENDED — PENDING.

### I-05 — Client report delivery

**Recommendation:** Phase 1 produces downloadable PDF reports only, accessed by authorized users and delivered through the approved institutional channel. Defer a client-facing portal to a separately approved scope change.

**Status:** RECOMMENDED — PENDING.

### I-06 — Actual report headline and reconciliation

**Recommendation:** avoid a single ambiguous total. Display separate counts for inspected, submitted, returned, approved, PDF generated, print action recorded, and completed. Define completed as approved + final PDF generated + print action recorded, consistent with the approved per-unit completion rule. For an executive headline, use completed and expose all other states as breakdowns.

**Status:** RECOMMENDED — PENDING explicit report-owner acceptance.

### I-07 — Project closure

**Recommendation:** explicit Super Admin project-close action only after all sessions are closed, assignments reconciled, no active claims/drafts/reviews/corrections/sync conflicts remain, and required reports, BA, attendance, and print deliverables are complete. Closing creates an immutable snapshot and audit event. Reopening requires elevated permission, reason, and audit.

**Status:** RECOMMENDED — PENDING.

### I-08 — Session creation and state transitions

**Recommendation:** Super Admin creates sessions and assignments. Proposed states: DRAFT, ACTIVE, PAUSED, CLOSED. Korlap/Admin may activate, pause, resume, and request closure only within assigned scope and explicit permission. No automatic closure by date.

**Open sub-decision:** whether Korlap can activate a session or only Super Admin.

**Status:** RECOMMENDED — PENDING.

### I-09 — Attendance verification

**Recommendation:** separate attendance.verify permission assigned by Super Admin to an authorized institutional verifier. A user must not verify their own upload unless an explicit, documented segregation-of-duties exception is approved.

**Status:** RECOMMENDED — PENDING.

### I-10 — Offline scope and recovery

**Already approved at high level:** limited offline inspection and safe sync.

**Recommendation for detailed contract:**
- Offline is allowed only for an inspection already claimed while online.
- No offline new claim, final submit, approval, role/assignment changes, or session administration.
- Persist draft and evidence locally until server acknowledgement; never silently discard acknowledged local work.
- Use idempotent sync operations and explicit server reconciliation.
- Claim expiry must not delete local work; require server-side claim/revision validation before final submit.
- Surface conflicts to the user; never silently overwrite server or local changes.
- Encrypt local sensitive data at rest where supported by the approved browser/device capability; define sign-out, shared-device, lost-device, and local-data purge behavior.
- Enable offline in production only on a tested supported browser/device matrix.

**Status:** RECOMMENDED — PENDING technical and Product Owner acceptance.

### I-11 — Evidence limits, privacy, retention, and deletion

**Recommendation:**
- Approve a narrow allowlist of image/document MIME types and validate actual file content server-side, not only filename/extension.
- Set per-file, per-inspection, and total-count limits after sampling real field evidence and provider quotas.
- Use private storage, short-lived authorized access, and least-privilege upload/download.
- Preserve originals; generate derived thumbnails/previews separately.
- Establish retention by record type (inspection evidence, PDFs, BA, attendance, audit logs), legal hold, deletion authority, backup/object recovery, and deletion audit.
- Do not auto-delete original evidence until the institutional records/privacy authority approves the schedule.
- Minimize personal data in application fields and logs; define access/export controls.

**Status:** BLOCKED pending institutional privacy/records approval and measurable file limits.

### I-12 — Supabase/Vercel production operations

**Recommendation:**
- Verify current plans, quotas, region, data residency, auth limits, database/storage limits, egress, compute, backups, and support terms directly before procurement.
- Use separate development/staging/production environments and secrets; no production credentials in preview/browser bundles.
- Version migrations; review and test rollback/forward-fix procedure.
- Define backup schedule, retention, RPO/RTO, database restore drill, and evidence object recovery test.
- Assign billing owner, project owner, incident owner, monitoring owner, and deployment approver.
- Confirm production usage/upgrade thresholds and CI quota policy.

**Status:** BLOCKED pending provider/account verification and named operational ownership.

### I-13 — Performance acceptance

**Approved target:** test up to 100 concurrent authenticated users.

**Recommendation:** before UAT, approve measurable p95/p99 latency and error thresholds for login, core reads/writes, claims, submit, review, dashboards, PDF generation, upload, and sync. Test 10/25/50/75/100 concurrency with representative photo uploads and field-network conditions. No unconditional “lag-free” claim without measured evidence.

**Status:** RECOMMENDED — PENDING numeric thresholds; test evidence required before production release.

### I-14 — Audit trail INS-016

**Current status:** PROPOSED, not approved.

**Recommendation:** approve append-only audit coverage for account lifecycle, role/scope/permission changes, assignments, sessions/targets/configuration, claims, inspection revisions, review/approval/reopen, evidence, sync/conflicts, PDF/print, BA/attendance, reports, and privileged exports. Super Admin can view/export but not edit/delete events through the application. Define retention and authorized audit access.

**Status:** RECOMMENDED — PENDING.

## 6. Required traceability work before scope freeze

1. Assign stable requirement IDs to every IFP and Standing Bracket checklist item and photo slot.
2. Link each requirement to acceptance criteria and positive/negative test cases.
3. Link BA summary, attendance multi-date columns, and serial-number annex to test IDs.
4. Ensure open decisions are marked consistently in Decision Register, PRD, RTM, RAID, and detailed design.
5. Test capacity values 1, 50, and 100; reject 0 and 101; verify concurrent activation cannot exceed the configured cap.
6. Confirm offline recovery, evidence retention, and document authority requirements have testable acceptance criteria.
7. Re-run a full document consistency audit after decisions are approved.

## 7. Freeze gate

Scope freeze is permitted only when:
- all Phase 1 instrument requirements are complete or explicitly accepted as known gaps by the authorized owner;
- all blocking decisions above are approved, rejected, or explicitly deferred with documented scope impact and compensating controls;
- PRD, RTM, Decision Register, RAID, architecture, functional design, UX, and tests agree;
- security/privacy and provider/operations ownership are approved;
- UAT owner, pilot scope, release criteria, and rollback owner are identified.

Feature implementation remains unauthorized until the authorized Product Owner explicitly approves the frozen baseline.

## 8. Current conclusion

**Package I decision worksheet: PREPARED.**  
**Scope freeze: NOT READY.**  
**Feature implementation: NOT AUTHORIZED.**

The next action is to resolve pending Product Owner decisions and obtain institutional confirmation where the decision concerns official checklist, records, privacy, or signatory authority. Engineering recommendations in this document are not approvals.
