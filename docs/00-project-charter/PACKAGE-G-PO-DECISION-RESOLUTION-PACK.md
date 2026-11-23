# Package G — Product Owner Decision Resolution Pack

Status: Prepared for Product Owner decision — proposals are NOT approvals
Version: 0.1.0
Date: 2026-11-23

## Purpose

Consolidate unresolved decisions that block the requirements and architecture freeze. Recommendations reduce implementation ambiguity while preserving institutional authority. No proposal becomes approved without explicit Product Owner acceptance or an authorized source document.

## Decision priority

### G-01 — Authoritative instrument source (BLOCKER)

**Current evidence**
- IFP specification: 49 checklist statements, 14 model specification fields, and 10 photo labels identified from reference descriptions; official source and mandatory status remain unverified.
- Standing Bracket: 19 visible checklist rows and 5 photo labels identified; the screenshots show partial checklist content, and photo labels are not validated by the supplied checklist screenshots.

**Recommendation**
Obtain the controlled/current official checklist, technical specification, and documentation/photo requirements for both instruments. Record document title, issuer, version/date, page/section, and approval owner. Reconcile each row and photo slot line-by-line. Do not implement instrument content until this is complete.

**Decision owner:** Product Owner / authorized instrument owner.

### G-02 — BA signatory blocks

**Known source:** reference BA screenshot shows two blocks: Tim Pemeriksaan Direktorat SD and PT Hisense International Indonesia.

**Recommendation**
Keep both as configurable signatory blocks with configurable label, name, title, order, and optional organization metadata. Require Product Owner to confirm whether both parties are mandatory for every BA and who authorizes final issuance. Preserve each issued BA template version.

**Decision owner:** Product Owner / institutional document authority.

### G-03 — Executive summary signature

**Recommendation**
No signature block by default unless the official template or authorized owner requires it. If required, use a versioned configurable signature block. Do not infer signature authority from application roles.

**Decision owner:** Product Owner.

### G-04 — Client report delivery

**Recommendation**
Phase 1: generate downloadable PDF reports only, delivered by authorized users through the approved institutional channel. Defer client portal until explicitly required; this avoids a new external identity and access surface.

**Decision owner:** Product Owner / Project Sponsor.

### G-05 — Actual report headline count

**Recommendation**
Display separate counts instead of one ambiguous headline: inspected/claimed; submitted; returned for correction; approved; PDF generated; print action recorded; completed (approved + final PDF + recorded print action). For executive headline, use completed and expose the other states as breakdowns. Product Owner must confirm the headline basis.

**Decision owner:** Product Owner.

### G-06 — Project closure and reconciliation

**Recommendation**
Require explicit Super Admin project-close command after all sessions are closed, assignments reconciled, no unresolved inspection/review/claim/sync conflict remains, and required reports/BA/attendance deliverables are completed. Closure creates a snapshot and audit event. Reopening requires elevated permission, reason, and audit.

**Decision owner:** Product Owner / Project Sponsor.

### G-07 — Session creation authority and state transitions

**Recommendation**
Super Admin creates/configures sessions and assignments. Korlap/Admin may activate, pause, resume, and request closure only within assigned scope and configured permissions. Use proposed states DRAFT, ACTIVE, PAUSED, CLOSED; no automatic closure by date. Confirm if Korlap may activate sessions or only Super Admin.

**Decision owner:** Product Owner.

### G-08 — Attendance verification authority

**Recommendation**
Introduce a distinct attendance.verify permission, initially assigned by Super Admin to an institutional verifier role. Korlap may upload attendance evidence but cannot verify their own upload unless an explicit segregation-of-duties exception is approved.

**Decision owner:** Product Owner / Project Sponsor.

### G-09 — Offline scope and recovery

**Recommendation**
Keep offline support limited to an already claimed inspection draft, acquired online. No offline new claims, approval, final submit, session administration, or role changes. Preserve local data until server acknowledgement. On claim expiry, keep local work and require server-side reconciliation before submit. Require supported-device testing before enabling offline in production.

**Decision owner:** Product Owner accepts workflow; CTO approves technical controls.

### G-10 — Evidence limits, retention, and deletion

**Recommendation**
Before implementation, approve allowed formats and server-side content validation; maximum per-photo and per-inspection size/count; compression and thumbnail rules; private bucket and time-limited access; retention schedule by evidence/document type; legal hold and deletion authorization; backup/object recovery and deletion audit. No automatic deletion of original evidence before an approved retention schedule exists.

**Decision owner:** Project Sponsor / institutional privacy and records authority.

### G-11 — Provider and production operations

**Recommendation**
Use separate Supabase projects/environments for development/staging/production where feasible, separate Vercel deployment environments, least-privilege secrets, versioned migrations, verified backup/restore, and explicit billing/ownership. Confirm actual plan terms, quotas, region, data residency, and institutional procurement before production commitment.

**Decision owner:** Project Sponsor / CTO.

### G-12 — Numeric performance thresholds

**Recommendation**
Keep 100 concurrent authenticated users as the load-test target. Establish latency/error thresholds after a baseline test on the selected provider plan and representative field network. Integrity/security requirements remain absolute. Include concurrent photo uploads and sync retry behavior.

**Decision owner:** CTO proposes measurable SLO; Product Owner accepts operational usability.

### G-13 — Audit trail INS-016

**Recommendation**
Approve append-only audit coverage for authentication/account lifecycle, role/scope/permission, assignments, session/target/configuration changes, claims, inspection revisions, review/approval/reopen, evidence, sync/conflicts, PDFs/printing, BA/attendance, reports, and privileged exports. Super Admin may view/export but not edit/delete audit events through the application. Define retention and access.

**Decision owner:** Product Owner / Project Sponsor.

### G-14 — Inspector capacity clarification

**Current approved contract**
- Initial configured capacity: 50 distinct Inspector accounts.
- Super Admin may raise the configured cap up to 100.
- Hard maximum: 100 distinct Inspector accounts across both locations combined.
- Count a person once regardless of assignment count.
- Capacity changes and account activation are atomic and audited.
- Separate performance target: up to 100 concurrent authenticated users.

**Status:** APPROVED in OPS-001. RAID and charter references reconciled to this rule.

## Freeze gate

Requirements/architecture scope freeze may proceed only when G-01 has authoritative instrument evidence and Product Owner approval; G-02 through G-10 are explicitly accepted, rejected, or resolved by authorized source policy; G-11 has an approved production ownership/provider decision; G-12 has a measurable test plan and later test evidence before production release; G-13 is approved or explicitly deferred with compensating controls; and Decision Register, PRD, RTM, RAID, functional design, architecture, UX, and tests are consistent.

## Important boundary

This pack does not authorize implementation. A recommendation is not an approved decision. Any item without explicit approval remains OPEN and must not be silently encoded as a production rule.