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

- AC-CAP-001: The system supports a configurable global Inspector capacity with a baseline/default of 50 and an absolute maximum of 100 users across both locations combined.
- AC-CAP-002: Super Admin may increase the configured capacity above 50, but cannot set it below 50 or above 99; the capacity is shared across both locations and allocation may be uneven.
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

- AC-OFF-001: Inspector can save an allowed draft and evidence while disconnected.
- AC-OFF-002: Repeated sync retries do not create duplicate inspection, evidence, or submission records.
- AC-OFF-003: Local draft/evidence is retained until server acknowledgement.
- AC-OFF-004: Conflicts never silently overwrite either side.
- AC-OFF-005: Final submit, review, approval, final PDF, and print action require server connectivity.
- AC-OFF-006: Device loss/reassignment follows an authorized recovery process with reason and audit history.

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
- AC-DOC-008: BA and attendance workflows follow approved templates and authorized verification rules; implementation is blocked until those rules are approved.

## 8. Reporting and session closure

- AC-RPT-001: Actual reporting uses actual event timestamps and counts.
- AC-RPT-002: Target reporting uses versioned target allocations.
- AC-RPT-003: Changing target allocation never changes actual inspection dates/times.
- AC-RPT-004: Daily, weekly, and final report variants exist for Actual and Target.
- AC-RPT-005: Korlap scope and Super Admin global scope are enforced in report access.
- AC-SES-001: Session cannot close while configured required workflow/document/print tasks remain incomplete.
- AC-SES-002: Session is not auto-closed merely because its calendar date passes.

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
- BA signatory blocks, authority, and lifecycle.
- Attendance verification role and authority.
- Actual report headline/count basis and client report delivery mechanism.
- Session state machine and final closure authority.


## 11. Concurrent usage and performance acceptance

- AC-PERF-001: The production candidate is load-tested with up to 100 concurrent authenticated users using representative mixed workflows.
- AC-PERF-002: The load test records environment/plan, workload mix, throughput, p50/p95/p99 latency, error rate, database utilization, and media upload performance.
- AC-PERF-003: Under the approved 100-user test profile, there is no data loss, duplicate active claim, duplicate submission, authorization bypass, or corrupted transaction.
- AC-PERF-004: Performance thresholds for interactive reads/writes, dashboards, and media uploads are explicitly approved after a baseline test on the selected production plan; passing the concurrency count alone is not sufficient for release.
