# Product Acceptance Criteria — Dit. SD Inspection

Status: Draft — test design and Product Owner review required  
This document defines observable acceptance outcomes. Detailed test cases and automation mapping will be produced in the Quality package.

## 1. Authentication and account lifecycle

- AC-AUTH-001: A user can authenticate using the approved Google sign-in flow.
- AC-AUTH-002: A first-time/unapproved account is assigned PENDING_APPROVAL and cannot read or mutate operational data.
- AC-AUTH-003: Only an authorized Super Admin can approve/reject users and assign roles/permissions.
- AC-AUTH-004: A user cannot grant themselves roles, permissions, or scope.
- AC-AUTH-005: Rejected, suspended, or unapproved accounts cannot perform operational actions.

## 2. Inspector capacity and assignments

- AC-CAP-001: The system supports a configurable global Inspector capacity from 1 to 100 distinct active Inspector accounts across both locations combined, with default 50.
- AC-CAP-002: Super Admin may configure capacity to any integer from 1 through 100; default is 50. The capacity is shared across both locations and allocation may be uneven. Values outside this range are rejected.
- AC-CAP-003: Korlap, Reviewer, Print Officer, and Super Admin are counted only when they also hold the Inspector role; each distinct person counts once.
- AC-CAP-004: Concurrent attempts to activate/assign Inspectors cannot exceed the currently configured global capacity; capacity changes and activation are transaction-safe and audited.
- AC-ASG-001: An assignment is scoped to one location, one instrument, and one team.
- AC-ASG-002: An Inspector cannot be assigned to overlapping time windows at different locations.
- AC-ASG-003: A user with multiple roles can perform an operational action only with explicit applicable assignment.
- AC-ASG-004: A Korlap cannot approve an inspection unless explicitly assigned Reviewer and separation-of-duties checks pass.

## 3. Instrument configuration and inspection

- AC-INS-001: IFP and Standing Bracket are separate configurable instruments.
- AC-INS-002: A session freezes the instrument configuration version used for its inspections.
- AC-INS-003: Editing a later configuration does not mutate existing inspection snapshots.
- AC-INS-004: An Inspector can only access an active session and assigned work.
- AC-INS-005: Serial-number normalization follows the approved instrument-specific rule; raw serial is retained.
- AC-INS-006: Duplicate active claims are prevented atomically.
- AC-INS-007: A duplicate scan does not create a duplicate inspection.
- AC-INS-008: The same Inspector can resume their existing claim and draft.
- AC-INS-009: A claim release/expiry does not discard saved draft data or evidence.
- AC-INS-010: Reinspection of a previously inspected serial requires explicit authorization and preserves history.

## 4. Checklist and evidence

- AC-EVD-001: The checklist displays the exact approved version, category, item text, and order.
- AC-EVD-002: A default OK visual state is not treated as Inspector verification without explicit confirmation.
- AC-EVD-003: A non-compliant item requires a finding note and configured supporting evidence before submission.
- AC-EVD-004: NOT_TESTABLE/NOT_APPLICABLE can be used only when enabled and accompanied by a reason.
- AC-EVD-005: A mandatory photo slot must contain valid evidence or an authorized exception with reason.
- AC-EVD-006: Original evidence is preserved; replacement/deletion is governed and audited.
- AC-EVD-007: Server receipt time is distinct from device capture time.
- AC-EVD-008: Evidence integrity hash is calculated after server receipt; the original file remains immutable.
- AC-EVD-009: A submission is blocked when mandatory checklist/evidence requirements are incomplete.

## 5. Offline and synchronization

- AC-OFF-001: Inspector can continue editing a draft offline only after the unit was claimed while online; offline claim acquisition is rejected.
- AC-OFF-002: Repeated sync retries do not create duplicate inspection, evidence, or submission records.
- AC-OFF-003: Local draft/evidence is retained until server acknowledgement.
- AC-OFF-004: Conflicts never silently overwrite either side.
- AC-OFF-005: Final submit, review, approval, final PDF, print action, role/assignment changes, session administration and privileged actions require server connectivity.
- AC-OFF-006: Device loss/reassignment follows an authorized recovery process with reason and audit history.
- AC-OFF-007: Reconnect rechecks current identity, authorization, assignment, claim ownership and server state before applying queued operations.
- AC-OFF-008: Stale/conflicting writes are rejected and shown for explicit resolution; neither local nor server data is silently overwritten.
- AC-OFF-009: Required evidence is not treated as synchronized/ready until server acknowledgement; final submission is blocked while required media remains pending.
- AC-OFF-010: Replaying the same queued operation is idempotent and creates no duplicate inspection, evidence or revision.

## 6. Review and approval

- AC-REV-001: Reviewer sees only submissions within explicit scope.
- AC-REV-002: Reviewer can return an inspection with mandatory reason and item-level indicators where configured.
- AC-REV-003: Returned inspection becomes editable by its Inspector through correction workflow.
- AC-REV-004: Resubmission creates a new immutable revision.
- AC-REV-005: Reviewer cannot silently modify Inspector answers or evidence.
- AC-REV-006: Self-review and self-approval are rejected server-side.
- AC-REV-007: Reopening approved inspection requires explicit permission, reason, and audit event.

## 7. PDF, print, BA and attendance

- AC-DOC-001: Only approved inspection snapshots can produce a final PDF.
- AC-DOC-002: PDF content is reproducible from the approved inspection and template version.
- AC-DOC-003: Per-unit Inspector identity is populated according to approved configuration; wet-signature area remains available.
- AC-DOC-004: Print Officer can print only within explicit scope and permission.
- AC-DOC-005: Print action records actor, timestamp, document, and print count.
- AC-DOC-006: Reprints increment the count and show the correct reprint label.
- AC-DOC-007: A print action does not imply that paper was physically printed or signed.
- AC-DOC-008: Print Officer can print an approved final PDF individually or through a bounded/configurable batch operation, subject to explicit permission and scope.
- AC-DOC-009: Every document in a batch has an independent recorded outcome; partial success is represented accurately and is never reported as whole-batch success.
- AC-DOC-010: Retry is restricted to failed documents and does not duplicate successful print events.
- AC-DOC-011: Reprint sequence is allocated atomically and remains linked to the same approved document version unless controlled regeneration creates a new version.
- AC-DOC-012: Direct printer integration is not required for initial release; print event records the application action, not verified physical paper output.
- AC-DOC-008: Print Officer can print an approved final PDF individually or through a bounded/configurable batch operation, subject to explicit permission and scope.
- AC-DOC-009: Every document in a batch has an independent recorded outcome; partial success is represented accurately and is never reported as whole-batch success.
- AC-DOC-010: Retry is restricted to failed documents and does not duplicate successful print events.
- AC-DOC-011: Reprint sequence is allocated atomically and remains linked to the same approved document version unless controlled regeneration creates a new version.
- AC-DOC-012: Direct printer integration is not required for initial release; print event records the application action, not verified physical paper output.
- AC-DOC-008: BA and attendance workflows follow approved templates and authorized verification rules; implementation is blocked until those rules are approved.

## 8. Reporting and session closure

- AC-RPT-001: Actual reporting uses actual event timestamps and counts.
- AC-RPT-002: Target reporting uses versioned target allocations.
- AC-RPT-003: Changing target allocation never changes actual inspection dates/times.
- AC-RPT-004: Daily, weekly, and final report variants exist for Actual and Target.
- AC-RPT-005: Korlap scope and Super Admin global scope are enforced in report access.
- AC-RPT-006: Actual report distinctly labels Inspected, Submitted, Approved and Completed counts.
- AC-RPT-007: Completed count includes only approved inspection + final PDF generated + Print Officer print action recorded; PDF open/download is not a print event.
- AC-SES-001: Session cannot close while configured required workflow/document/print tasks remain incomplete.
- AC-SES-002: Session is not auto-closed merely because its calendar date passes.
- AC-SES-003: Only Super Admin can finally close the project after all closure gates and actual-versus-target reconciliation pass; closure records actor, timestamp, reason/confirmation and audit event.
- AC-SES-004: Session creator/configuration authority is Super Admin; Korlap state actions are limited to assigned scope and granted permissions.
- AC-SES-005: CLOSED session is terminal in ordinary flow; reopening requires privileged permission, reason and audit.
- AC-ATT-001: Korlap can verify attendance only within assigned location/scope and explicit verifier permission.
- AC-ATT-002: Generate, print, upload, download and verify are separate permissions; upload never automatically sets VERIFIED.

## 9. Production quality

- AC-OPS-001: All in-scope requirements map to test cases and evidence.
- AC-OPS-002: RLS and API authorization negative tests prove cross-scope access is denied.
- AC-OPS-003: Backup restoration and rollback procedures are rehearsed successfully.
- AC-OPS-004: Monitoring and operational ownership are defined before go-live.
- AC-OPS-005: Product Owner UAT sign-off exists and release-blocking defects are resolved or formally dispositioned.

## 10. Open acceptance decisions

- Exact authoritative IFP and Standing Bracket checklist/photo slot completeness.
- Official specification applicability and model variants.
- Supported devices/browsers and measurable performance targets.
- Offline device/browser support, encryption, retention, and recovery details.
- Evidence size/type limits and retention/deletion policy.
- Institutional approval of actual BA signatory identities/roles and final template.
- Detailed attendance evidence acceptance rules and verifier audit evidence.
- Official IFP master source and Standing Bracket photo-slot requirements.
- Institutional BA signatory authority and final approved template.


## 11. Concurrent usage and performance acceptance

- AC-PERF-001: The production candidate is load-tested with up to 100 concurrent authenticated users using representative mixed workflows.
- AC-PERF-002: The load test records environment/plan, workload mix, throughput, p50/p95/p99 latency, error rate, database utilization, and media upload performance.
- AC-PERF-003: Under the approved 100-user test profile, there is no data loss, duplicate active claim, duplicate submission, authorization bypass, or corrupted transaction.
- AC-PERF-004: Performance thresholds for interactive reads/writes, dashboards, and media uploads are explicitly approved after a baseline test on the selected production plan; passing the concurrency count alone is not sufficient for release.


## Package T decisions accepted by Product Owner (2026-11-23)

- T-01 source authority: acceptance criteria must verify that the IFP and Standing Bracket master definitions are reconciled against current institutionally approved source documents, with provenance and effective revision recorded. The source documents and formal approval evidence are still required before this criterion can pass.
- T-02 BA: acceptance must verify configurable signatory blocks per approved template (party count, organization, role/title, order, required/optional). Acceptance of the configuration capability does not establish actual signatory authority or identity.
- T-03 executive summary: acceptance must verify that signature behavior is configurable per report template and defaults to no signature unless the approved template requires it.
- T-04 client report delivery: initial-release acceptance is PDF-only; a client portal is outside initial scope and requires a later approved change request. PDF access and distribution remain permission-controlled and auditable.

- T-05 acceptance: Actual reports show separate Inspected, Submitted, Approved and Completed counts; Completed is approved inspection + final PDF generated + Print Officer print action recorded; timestamp and filters are shown.
- T-06 acceptance: only Super Admin closes a project after all gates and actual-versus-target reconciliation pass; closure is explicit, reasoned, audited and never date-triggered.
- T-07 acceptance: Super Admin creates/configures sessions; Korlap transitions only within assigned scope and permission; CLOSED is terminal in ordinary flow; reopening is privileged, reasoned and audited.
- T-08 acceptance: Korlap verifies attendance only within assigned scope and explicit verifier permission; upload never automatically marks VERIFIED; all attendance actions have separate permissions.
- T-13 acceptance: individual and bounded batch printing are supported; each document has an independent outcome; failed-only retry does not duplicate success; reprint sequence is atomic and version-bound; no physical-output claim or direct printer integration is assumed.
- T-13 acceptance: individual and bounded batch printing are supported; each document has an independent outcome; failed-only retry does not duplicate success; reprint sequence is atomic and version-bound; no physical-output claim or direct printer integration is assumed.

The open-decision list reflects remaining external evidence and detailed acceptance items, not reversal of these PO approvals.


**T-09 PO decision:** Option B (limited offline draft editing) APPROVED on 2026-11-23. Production acceptance remains conditional on approved device/browser, local-data protection, retention/purge, shared-device logout and recovery controls; these are not deemed complete by this PO decision.


## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.


## T-11 acceptance criteria
Numeric latency/error-rate SLOs remain OPEN until workload, provider plan/region/quotas and measured baseline are reviewed and approved.
- Supported baseline is current stable Chrome on Android for Inspector; current stable Chrome or Edge desktop for Korlap, Reviewer, Super Admin and Print Officer.
- Tablet is supported only after responsive, camera, upload and PDF/print validation.
- Unsupported/obsolete releases, embedded in-app browsers and modified browsers are excluded.
- Exact OS/device minimums and browser build numbers are recorded in UAT evidence.
- The 100 concurrent authenticated-user profile is load-tested in staged levels 10/25/50/75/100; no claim of capacity is accepted without measured evidence.
- Numeric SLOs are not treated as approved until workload, provider plan/region/quotas and baseline measurements are reviewed and approved.
