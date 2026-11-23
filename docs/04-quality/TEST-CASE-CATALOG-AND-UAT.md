# Test Case Catalog and UAT Plan

Status: Test catalog draft — execution not started
Version: 0.1.0

## 1. Test case format
Each executed case records ID, build SHA, environment, preconditions, steps, expected result, actual result, evidence, tester, timestamp, and defect reference.

## 2. Account and authorization
- TC-AUTH-001: Google sign-in maps to one application identity.
- TC-AUTH-002: Pending account cannot access operational data.
- TC-AUTH-003: Super Admin approval and explicit role/scope grant enable only approved access.
- TC-AUTH-004: Rejected/suspended/revoked user is denied on subsequent requests.
- TC-AUTH-005: User cannot self-assign or elevate role.
- TC-AUTH-006: Multi-role user receives only explicitly assigned operational scopes.
- TC-AUTH-007: Korlap at location A cannot access location B without explicit scope.
- TC-AUTH-008: Reviewer cannot approve own submitted revision.
- TC-AUTH-009: Direct API/RLS access denies unauthorized row/object access.

## 3. Capacity and concurrency
- TC-CAP-001: Default configured Inspector capacity is 50.
- TC-CAP-002: Super Admin can configure capacity to any integer from 1 through 100, including values below 50.
- TC-CAP-003: Capacity accepts 1 and 100, rejects 0 and 101, and accepts valid intermediate values below and above default 50.
- TC-CAP-004: Capacity reduction below current active Inspector count is rejected.
- TC-CAP-005: Concurrent Inspector activations cannot exceed configured capacity.
- TC-LOAD-001: Representative workload at 10/25/50/75/100 concurrent users.
- TC-LOAD-002: 100-user mixed workload records throughput, p50/p95/p99 latency, errors, database resource use, and media upload performance.
- TC-LOAD-003: Under 100-user test, no lost acknowledged writes, duplicate claims/revisions, authorization bypass, or transaction corruption.

## 4. Inspection lifecycle
- TC-INSP-001: Inspector sees only active assigned session/assignment.
- TC-INSP-002: Claiming a unit creates one active claim and draft.
- TC-INSP-003: Two Inspectors claim same unit simultaneously; only one succeeds.
- TC-INSP-004: Release/expiry preserves draft and media.
- TC-INSP-005: Checklist defaults to unanswered, not OK.
- TC-INSP-006: Mandatory evidence and checklist validation blocks submit.
- TC-INSP-007: N/A/not-testable requires configured permission and reason.
- TC-INSP-008: Submit creates immutable revision.
- TC-INSP-009: Duplicate submit retry returns same result.
- TC-INSP-010: Stale draft version returns conflict without overwriting newer data.
- TC-INSP-011: Reviewer return creates correction task and preserves prior revision.
- TC-INSP-012: Inspector correction creates next revision.
- TC-INSP-013: Reopen approved inspection requires authority and reason.

## 4. Instrument requirement verification

Detailed data-driven coverage is defined in docs/04-quality/INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md.

- TC-IFP-CHK-001..004: Verify all 49 identified IFP checklist rows by category, including unanswered initial state, explicit result, finding handling, immutable revision, and PDF parity.
- TC-IFP-SP-001: Verify all 14 model-specific IFP specification fields against the frozen model configuration.
- TC-IFP-PH-001: Verify all 10 identified IFP photo-slot labels, evidence linkage, privacy, retry, version snapshot, and only approved gating rules.
- TC-BRK-CHK-001..002: Verify all 19 provisionally identified Standing Bracket rows, preserving exact visible transcription and unresolved quantity ambiguity.
- TC-BRK-PH-001: Verify all 5 identified Standing Bracket photo labels without assuming completeness or mandatory status.
- TC-INSTR-001..008: Verify cross-instrument serial policy, configuration version freezing, historical snapshots, stale input rejection, concurrency conflicts, PDF parity, and non-retroactive evidence rules.

These are designed test procedures. Execution has not started. Source authority and completeness remain open as stated in each instrument specification.

## 5. Evidence and offline
- TC-EVD-001: Upload intent rejects unauthorized slot/scope.
- TC-EVD-002: Invalid MIME/signature/oversize file rejected.
- TC-EVD-003: Interrupted upload can retry without duplicate evidence record.
- TC-EVD-004: Evidence becomes available only after server verification.
- TC-EVD-005: Original evidence cannot be replaced/deleted by ordinary role.
- TC-OFF-001: Draft survives refresh/reopen while offline within approved retention.
- TC-OFF-002: Reconnect sync is idempotent.
- TC-OFF-003: Conflicting edits are surfaced; no silent last-write-wins.
- TC-OFF-004: Account revocation blocks future server operations and sync.
- TC-OFF-005: Device loss scenario and local-data minimization are tested.
- TC-OFF-006: Offline claim acquisition, approval, final submission, role/assignment change, session administration and privileged actions are denied.
- TC-OFF-007: Sync rechecks current authorization, assignment and claim ownership; revoked/expired access is not accepted.
- TC-OFF-008: Stale server version produces a visible conflict and preserves both local and server versions without last-write-wins.
- TC-OFF-009: Required media remains pending until server object verification; final submit is blocked until all required media is acknowledged.
- TC-OFF-010: Duplicate/replayed sync operations are idempotent across retry and reconnect.
- TC-OFF-011: Shared-device logout, local cache protection, purge and recovery follow the approved device/privacy policy before production activation.

## 6. Reports and documents
- TC-DOC-001: Approved PDF matches immutable inspection revision.
- TC-DOC-002: PDF inspector identity is sourced from approved configuration/inspection record.
- TC-DOC-003: Print event is recorded only after explicit print confirmation.
- TC-DOC-004: Reprint ordinal increments and prior print events remain.
- TC-DOC-009: Print Officer can individually print an approved final PDF only within explicit permission and scope.
- TC-DOC-010: Bounded batch print enforces configured maximum size and records a distinct outcome for each document.
- TC-DOC-011: Partial batch failure is represented per document; successful items are not incorrectly retried or duplicated.
- TC-DOC-012: Retry accepts failed documents only and does not create duplicate success events.
- TC-DOC-013: Concurrent print/reprint requests allocate unique atomic ordinals for each document and preserve document-version linkage.
- TC-DOC-014: Batch operation rejects unapproved, missing, wrong-scope or non-final-PDF documents without unauthorized disclosure.
- TC-DOC-015: Recorded print event does not claim physical paper output; direct printer integration is not required.
- TC-DOC-005: BA and attendance document lifecycle statuses are correct.
- TC-DOC-006: BA instrument summary rows reconcile inspected sample, good, and defective counts against source inspection records, including a zero-count instrument row.
- TC-DOC-007: BA template renders configured activity/date/location narrative and authorized signatory blocks without hardcoded sample values.
- TC-DOC-008: Multi-day attendance output creates one date-labelled attendance column per configured activity date; assignment alone does not mark a participant present.
- TC-DOC-009: Standing Bracket serial-number annex rows reconcile to inspection records and preserve instrument, serial, condition, evidence reference, and configured paraf blocks.
- TC-DOC-010: Annex generation does not impose the sample's 13-row count or all-good condition as a fixed rule.
- TC-DOC-011: IFP PDF reproduces the approved checklist version, serial identities, Ya/Tdk answers, and configured signature area.
- TC-RPT-001: Actual report uses actual event timestamps/counts.
- TC-RPT-002: Target report uses versioned target allocations and never rewrites actual activity.
- TC-RPT-003: Dashboard counts reconcile with source inspection states.
- TC-SESSION-001: Session close is blocked by incomplete drafts, claims, reviews, prints, or required documents.

## 7. UAT stages
1. Test preparation: Product Owner confirms official IFP/Bracket checklist, photo requirements, role matrix, report/document templates, and acceptance thresholds.
2. Admin UAT: account approval, assignments, configuration, target planning, audit.
3. Inspector UAT: sign-in, assignment, claim, evidence, checklist, offline/reconnect, submit.
4. Reviewer UAT: queue, inspect, return, approve, separation of duties.
5. Korlap UAT: team supervision, actual/target reporting, session close.
6. Print/document UAT: PDF accuracy, individual print, bounded batch, partial failure, failed-only retry, reprint sequence, BA and attendance. Physical printer output is checked operationally where available but is not asserted by the application event.
7. Cross-role end-to-end UAT: complete representative inspection from assignment to recorded print and reporting.
8. Defect triage and retest; Product Owner signs acceptance only after critical/high issues resolved.

## 8. UAT sign-off record
Record build SHA, test environment, participants/roles, test cases passed/failed/blocked, defects, known limitations, Product Owner decision, date, and explicit release recommendation. No implied approval from silence.


**T-09 scope status:** PO-approved option B. These are designed test procedures only; none are reported as executed. Device/local-data controls and institutional retention approval remain prerequisites to production activation.


## T-10 decision verification coverage
- TC-EVD-006: Evidence upload is blocked when the file type or configured limit has not been institutionally approved; no default numeric limit may be treated as policy.
- TC-EVD-007: Retention expiry does not delete a record under legal/institutional hold.
- TC-EVD-008: Deletion requires the approved authority, eligibility checks, reason, dependency checks and immutable audit evidence.
- TC-EVD-009: Backup/restore and post-deletion behavior follow the institutionally approved records policy.
- TC-EVD-010: Production evidence collection remains blocked until written institutional records/legal/privacy approval and accepted evidence limits are recorded.

These are planned verification cases only; not executed. T-10 option B is PO-approved as a review path, not as institutional policy approval.


## T-11 compatibility and performance verification coverage
- TC-COMP-001: Inspector core workflow on current stable Chrome for Android, including camera permission, evidence upload, authentication and supported offline-draft behavior.
- TC-COMP-002: Korlap and Reviewer workflows on current stable Chrome and Edge desktop.
- TC-COMP-003: Super Admin and Print Officer workflows on current stable Chrome and Edge desktop, including PDF preview and print action.
- TC-COMP-004: Tablet is accepted only after responsive layout, camera, upload and PDF/print checks pass.
- TC-COMP-005: Unsupported/obsolete, embedded in-app and modified browsers are rejected or shown a clear unsupported-browser notice.
- TC-COMP-006: Record exact OS/device models and browser build numbers for every compatibility run.
- TC-LOAD-001: Execute representative mixed workload at 10, 25, 50, 75 and 100 concurrent authenticated users; capture p50/p95/p99 latency, throughput, error rate, database and storage metrics.
- TC-LOAD-002: At target load, verify no acknowledged write loss, duplicate active claim/revision, unauthorized transition, cross-scope access or silent conflict overwrite.

These are planned cases only; not executed. 100 concurrent users is a load-test target, not a production capacity or SLA claim. Numeric SLO thresholds remain open pending measured baseline and provider verification.
