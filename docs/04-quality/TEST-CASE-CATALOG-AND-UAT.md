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
- TC-CAP-004: Capacity reduction below the current qualifying Inspector count (distinct enabled account + active Inspector grant + effective operational assignment) is rejected; pending, rejected, suspended, disabled and expired-role accounts are excluded.
- TC-CAP-005: Concurrent Inspector activations/assignment grants across both locations cannot exceed the combined configured capacity; each qualifying account is counted once across multiple roles/assignments.
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
- TC-PRINT-001: Print Officer can individually print an approved final PDF only within explicit permission and scope.
- TC-PRINT-002: Bounded batch print enforces configured maximum size and records a distinct outcome for each document.
- TC-PRINT-003: Partial batch failure is represented per document; successful items are not incorrectly retried or duplicated.
- TC-PRINT-004: Retry accepts failed documents only and does not create duplicate success events.
- TC-PRINT-005: Concurrent print/reprint requests allocate unique atomic ordinals for each document and preserve document-version linkage.
- TC-PRINT-006: Batch operation rejects unapproved, missing, wrong-scope or non-final-PDF documents without unauthorized disclosure.
- TC-PRINT-007: Recorded print event does not claim physical paper output; direct printer integration is not required.
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
These are planned cases only; not executed. TC-LOAD-001..003 in Section 3 are the canonical load-test IDs; T-11 adds browser/device compatibility prerequisites only. 100 concurrent users is a load-test target, not a production capacity or SLA claim. Numeric SLO thresholds remain open pending measured baseline and provider verification.



## T-14 — Inspector capacity test requirements (PO-approved 2026-11-24)

Add/retain test coverage for: enabled account + active Inspector grant + effective assignment counts once; duplicate assignments/other roles still count once; missing/ineffective assignment does not count; pending/rejected/suspended/disabled/expired-role accounts are excluded; cross-location combined cap is enforced atomically under concurrent role/assignment changes; values 0 and above 100 are rejected; reducing cap below current qualifying count is rejected without deactivation. Test execution is not claimed by this documentation update.



## Registration-first and Super Admin staffing test requirements

- Verify registration creates a pending account without operational access or Inspector capacity count.
- Verify Super Admin approval is required before role, scope, team membership or assignment can be granted.
- Verify only Super Admin can set team count and assign personnel to teams.
- Verify pending/rejected/suspended/disabled/unregistered identities cannot be assigned.
- Verify users cannot self-assign roles, teams, scope or operational work through UI or direct API.
- Verify team staffing changes enforce the T-14 combined capacity predicate atomically and generate audit events.



## T-15 — INS-016 audit policy test requirements (PO-approved 2026-11-24)

Add/retain tests proving:
- Every defined critical command commits its business mutation and audit event atomically.
- Injected audit insert/validation failure rolls back the corresponding critical state mutation and returns failure.
- No success response is returned when the audit event has not committed.
- Event actor, active role, scope, action/event type, timestamp, correlation/idempotency reference and privacy-safe change context match the authorized command context.
- Ordinary application roles and direct client paths cannot update/delete audit records or bypass audited critical commands.
- Audit read and export require explicit least-privilege permission and are themselves auditable where required by the catalogue.
- Sensitive evidence access and export produce audit events without placing raw evidence, secrets or credentials in event payloads.
- Idempotent retries do not create misleading duplicate business events; audit event semantics remain deterministic and traceable.
- T-10 retention, legal-hold and metadata rules are treated as configuration/policy gates, not guessed defaults.

These are test requirements only. Test execution and implementation are not claimed.


## T-16 — Required serial uniqueness and evidence-linkage tests (PO-approved option B)

- TC-UNIT-016-001: Same normalized serial in the same instrument type is rejected as a second canonical unit even when the incoming record belongs to a different project.
- TC-UNIT-016-002: Same normalized serial is permitted for a different instrument type.
- TC-UNIT-016-003: Concurrent claims/creation for the same instrument-type + normalized-serial key serialize to one canonical unit; no duplicate unit rows are created.
- TC-UNIT-016-004: Same-type cross-project collision enters controlled review and requires authorized actor, reason and audit; no silent merge or historical rewrite occurs.
- TC-UNIT-016-005: Project/session/assignment authorization remains enforced when multiple projects reference the same canonical unit.
- TC-EVD-016-001: Evidence references the exact immutable inspection revision and instrument version, and a mismatched version/slot is rejected.
- TC-EVD-016-002: Original checksum, uploader, capture/upload timestamps and storage object identity remain preserved.
- TC-EVD-016-003: Finalized evidence cannot be overwritten; replacement creates a new evidence record/object and audit event while the original remains linked to its historical revision.
- TC-EVD-016-004: Failed audit write rolls back the critical evidence replacement/resolution transaction in accordance with T-15.

These are test specifications only; no test execution is claimed.


## T-17 — Instrument configuration governance test specifications

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-CFG-001-001 | Submit unknown field type or validation primitive | Rejected server-side; no executable expression is evaluated |
| TC-CFG-001-002 | Configure ordering, applicability, expected values and evidence slots | Persisted only as validated declarative data within one draft version |
| TC-CFG-001-003 | Authorized Super Admin with `instrument.publish` publishes valid draft | Publication succeeds without second-person approval; actor is derived from trusted session |
| TC-CFG-001-004 | Caller lacks `instrument.publish` or is not authorized Super Admin | Denied; no version or publication record is created |
| TC-CFG-001-005 | Audit write fails during publication | Entire publication transaction rolls back |
| TC-CFG-001-006 | Attempt to edit/delete a published version or child config | Denied; correction requires a new version |
| TC-CFG-001-007 | Publish a newer version/deactivate old version while a session references old version | Existing session and historical revisions retain exact pinned version/snapshot |
| TC-CFG-001-008 | Attempt to use canonical unit identity from another project without association/assignment | Denied; canonical identity does not grant operational access |

Test cases are specifications only; no test execution, migration or code change is claimed.


## T-18 — Privileged command boundary security test specifications

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-CMD-018-001 | Browser attempts direct INSERT/UPDATE/DELETE against each protected table | Denied by database grants/RLS; no state or audit row changes |
| TC-CMD-018-002 | Valid caller JWT invokes an authorized command through its Vercel route | Route verifies session; PostgreSQL derives the same actor from auth.uid(); command succeeds only when all scope/state checks pass |
| TC-CMD-018-003 | Client spoofs actor ID, role, project, session or assignment in payload | Spoofed fields are ignored/rejected; database-derived identity and grants determine authorization |
| TC-CMD-018-004 | Missing, expired, revoked JWT or pending/disabled application account | Command is rejected; no mutation or success response |
| TC-CMD-018-005 | Authenticated caller has wrong permission, role, project, session or assignment | Forbidden; no protected mutation; no cross-scope data disclosure |
| TC-CMD-018-006 | Caller attempts self-review or violates separation-of-duties | Rejected inside the command transaction |
| TC-CMD-018-007 | Concurrent commands race on capacity, serial uniqueness, active claim or state transition | Locks/constraints serialize the invariant; no over-capacity, duplicate canonical unit, double claim or invalid transition |
| TC-CMD-018-008 | Same idempotency key and same request is replayed | One business effect; stable prior outcome returned |
| TC-CMD-018-009 | Same idempotency key is reused with a different request hash | Rejected as idempotency conflict; no second mutation |
| TC-CMD-018-010 | Required audit/event insert fails | Entire business transaction rolls back; no success response is returned |
| TC-CMD-018-011 | SECURITY DEFINER function is reviewed/deployed | search_path is pinned, references are schema-qualified, inputs validated, owner/grants minimal, unintended PUBLIC execution revoked |
| TC-CMD-018-012 | Inspect deployed frontend bundle and browser network/configuration | No service-role credential is present or exposed |
| TC-CMD-018-013 | Authorized caller invokes command for resource outside assigned scope | Denied even if caller has global catalog/admin permission; canonical unit identity does not widen operational access |
| TC-CMD-018-014 | Command returns typed validation/forbidden/conflict/retryable outcomes | Stable typed response; no stack trace, secret, sensitive policy detail or unauthorized resource-existence disclosure |

These are acceptance specifications only. No implementation, migration, security test or deployment is claimed.


## T-16 — Canonical unit association and cross-project isolation test specifications

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-UNIT-016-006 | Create known serial for instrument A when no canonical key exists | One canonical `units` row is created without a project_id; a separate authorized association row links it to the requested project |
| TC-UNIT-016-007 | Associate the same verified physical unit with a second project | A second `unit_project_associations` episode is created; no second `units` row is created; both project histories remain distinct |
| TC-UNIT-016-008 | End one project's association while another project association remains active | Ended association is retained; other association remains valid; no historical inspection rows are rewritten |
| TC-UNIT-016-009 | Attempt inspection/claim with unit_id but no matching active project association | Denied; no inspection, claim, evidence or scope disclosure |
| TC-UNIT-016-010 | Inspection association belongs to Project A but assignment belongs to Project B | Composite FK/command validation rejects the write |
| TC-UNIT-016-011 | Assignment instrument differs from canonical unit instrument | Command rejects; no claim or inspection is created |
| TC-UNIT-016-012 | Same physical unit is actively claimed in Project A; Project B attempts claim through its own association | Denied by global active-claim invariant; no second active claim |
| TC-UNIT-016-013 | Same physical unit is associated with two projects; Project A member queries Project B inspection/evidence | Denied absent independent Project B assignment and history permission; canonical unit reference does not grant visibility |
| TC-UNIT-016-014 | User's project association ends or assignment is revoked while draft/history exists | New operational commands denied; historical records and evidence remain intact under explicit history-access policy |
| TC-UNIT-016-015 | Duplicate serial conflict is opened | No second canonical unit row; conflict record captures candidate and submitted context with restricted visibility |
| TC-UNIT-016-016 | Authorized conflict reviewer resolves by association to verified candidate | New association + resolution + audit commit atomically; no historical unit/inspection rows are merged or rewritten |
| TC-UNIT-016-017 | Concurrent canonical registration with same instrument+normalized serial from two projects | Unique key/lock yields one canonical unit; one request creates it and the other becomes a controlled conflict or verified association path |
| TC-UNIT-016-018 | Serial normalization policy changes for an instrument version | Existing canonical keys are not silently rewritten; migration/re-key requires explicit reviewed plan and collision analysis |

All are acceptance specifications only. No test, migration or runtime implementation has been executed.


## Command-to-test traceability gaps (T-18 follow-up)

The generic TC-CMD-018 suite is a boundary-level security suite; it does not by itself prove every command's business invariant. Before implementation authorization, add command-specific positive, negative, audit-failure, idempotent-replay and concurrency cases for every command family. At minimum, the following currently lack explicit dedicated case IDs in this catalogue:

- Account request/approve/reject, role grant/revoke, scope grant/revoke and team staffing, including self-elevation and atomic capacity predicate.
- Project/session create, update, transition and close, including every closure gate.
- Assignment publish/member changes, cross-location overlap, instrument-version pinning and staffing authorization.
- Instrument create/draft/update/deactivate and publication, including deactivation reason, active-session pinning and audit rollback.
- Canonical unit registration, project association/end, identity-conflict resolution and claim release, including audit rollback and concurrent association/claim races.
- Evidence read/access/export, upload intent/confirm/finalize/replace, private-object authorization and audit-on-access/export.
- Inspection draft/save, return, correction, approve, reopen and sync reconciliation, including per-command stale-version/idempotency outcomes.
- PDF generation, individual print and batch orchestration, including generation retry and per-document partial failure.
- Attendance document upload/replacement/verification and project-level actual/target report reads.
- Audit read/export, retention/legal-hold command controls, and any privileged maintenance command.

For each test, record exact command/function, caller fixture, permission/scope fixture, resource state, request/idempotency key, expected typed outcome, audit event expectation, lock/concurrency setup and evidence. These are test-design gaps, not permission to add implementation or run tests. No test execution is claimed.

## T-18 — Command authorization verification matrix (design cases, 2026-11-24)

The command-family authorization mapping is maintained in [Command Authorization Verification Matrix](../02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md). The following 36 cases are allocated to command-family review and common security-boundary verification. They are planned specifications, not executed tests. They do not replace later per-command request/response, RLS, EXECUTE-grant, audit rollback, idempotency and concurrency cases once exact command contracts are approved.

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-CMD-AUTHZ-024-001 | Account self-request — Authenticated caller requests access for another UID or supplies role/scope fields | Request is rejected or constrained to auth.uid(); no privilege or scope is created |
| TC-CMD-AUTHZ-024-002 | Account decision SoD — Approver approves/rejects own account or submits decision without authority/reason | Denied; actor != subject enforced; no decision mutation; no audit success event |
| TC-CMD-AUTHZ-024-003 | Role grant authority — Grantor assigns a role above own delegation ceiling or self-grants | Denied in PostgreSQL; no role/permission mutation; security event audited |
| TC-CMD-AUTHZ-024-004 | Inspector grant capacity — Concurrent Inspector role/assignment grants race at configured capacity | Capacity row lock serializes; qualifying distinct account count never exceeds configured limit |
| TC-CMD-AUTHZ-024-005 | Scope grant self-assignment — Caller grants own project/session/location/team scope or targets unauthorized resource | Denied; no scope row is created; scope mutation is audited only on success |
| TC-CMD-AUTHZ-024-006 | Project closure gates — Caller closes project with open session/inspection/document or unreconciled actual/target data | Closure denied with stable typed blocker; no project close timestamp/state mutation |
| TC-CMD-AUTHZ-024-007 | Project closure audit rollback — Required audit insert fails during otherwise eligible project closure | Entire closure rolls back; no success response |
| TC-CMD-AUTHZ-024-008 | Session transition scope — Korlap transitions a session outside assigned project/location or requests prohibited transition | Denied; no state change or cross-scope disclosure |
| TC-CMD-AUTHZ-024-009 | Assignment publication — Assignment contains overlapping member/location/instrument or unpublished instrument version | Rejected atomically; no partial membership changes; audit failure rolls back |
| TC-CMD-AUTHZ-024-010 | Capacity mutation — Capacity set outside 1..100 or below qualifying active Inspector count | Rejected; no silent deactivation; concurrent eligibility changes serialize |
| TC-CMD-AUTHZ-024-011 | Target plan isolation — Target planner attempts to alter actual inspection counts or published target version | Denied; actual facts unchanged; published target remains immutable |
| TC-CMD-AUTHZ-024-012 | Instrument draft permission — Non-Super Admin or caller lacking instrument.manage edits catalog/draft | Denied; no draft/catalog mutation |
| TC-CMD-AUTHZ-024-013 | Instrument publish permission — Caller lacks explicit instrument.publish or is not authorized Super Admin | Denied; no publication/version record |
| TC-CMD-AUTHZ-024-014 | Instrument publication atomicity — Audit insert fails during valid T-17 direct publication | Draft remains unpublished; publication and audit both roll back |
| TC-CMD-AUTHZ-024-015 | Canonical unit key — Concurrent registration of same instrument_id + serial_normalized from two projects | One canonical unit maximum; second request enters controlled conflict/association flow |
| TC-CMD-AUTHZ-024-016 | Unit association authority — Caller associates/ends unit association without project authority or reason | Denied; association episode/history unchanged |
| TC-CMD-AUTHZ-024-017 | Identity conflict reviewer — Unauthorized caller enumerates or resolves cross-project identity conflict | Denied; minimum metadata only; no merge or historical rewrite |
| TC-CMD-AUTHZ-024-018 | Claim global uniqueness — Two projects concurrently claim same canonical unit via separate active associations | Exactly one active claim; losing command receives typed conflict; no cross-project leakage |
| TC-CMD-AUTHZ-024-019 | Draft ownership/version — Caller saves another inspector's draft or stale row version | Denied or STALE_VERSION; no overwrite; audit records only valid mutation |
| TC-CMD-AUTHZ-024-020 | Submit/review/reopen lifecycle — Submit missing evidence, self-review, wrong reviewer scope or reopen without reason | Each invalid transition denied; immutable prior revisions remain unchanged |
| TC-CMD-AUTHZ-024-021 | Evidence upload boundary — Upload intent targets unauthorized slot/scope or object fails signature/checksum/size | Rejected; object not finalized; no unauthorized Storage metadata exposure |
| TC-CMD-AUTHZ-024-022 | Evidence access/export separation — Caller has evidence.read but not evidence.export and attempts export | Read may follow approved scope; export denied; access/export audit behavior is distinct |
| TC-CMD-AUTHZ-024-023 | Offline sync reauthorization — Revoked account/device/assignment replays a previously claimed-draft batch | Server reauthorization rejects unauthorized changes; conflict/replay outcome is durable and idempotent |
| TC-CMD-AUTHZ-024-024 | Document generation snapshot — Generate PDF from unapproved revision or altered template instead of pinned snapshot | Denied or deterministic validation failure; no misleading artifact is published |
| TC-CMD-AUTHZ-024-025 | Print batch authorization — Batch contains wrong-scope/unapproved document and successful plus failed items | Per-document authorization and partial outcomes; successful items not duplicated on retry |
| TC-CMD-AUTHZ-024-026 | Attendance upload/verify separation — Uploader attempts to mark own upload verified without attendance.verify | Denied; upload remains unverified; distinct permission and audit trail enforced |
| TC-CMD-AUTHZ-024-027 | Report read isolation — Caller requests another project/session actual or target report | Denied by RLS/scope; actual and target sources remain separate |
| TC-CMD-AUTHZ-024-028 | Audit read/export separation — Caller has audit.read only and attempts export or global unfiltered query | Export/global query denied absent explicit scope/authority; access attempt is handled safely |
| TC-CMD-AUTHZ-024-029 | Retention/legal hold gate — Caller attempts deletion/disposition without written T-10 institutional policy or during legal hold | No irreversible disposition; legal hold takes precedence; command remains blocked |
| TC-CMD-AUTHZ-024-030 | Security case isolation — Operational Admin or Super Admin without security.review opens restricted incident | Denied; no case detail leakage; only designated reviewer receives minimum necessary access |
| TC-CMD-AUTHZ-024-031 | Provider/release authority — Unapproved custodian changes provider or deploys/rolls back production | Denied pending T-12 authority/process; no configuration or release state change |
| TC-CMD-AUTHZ-024-032 | Caller identity spoofing — Client sends forged actor, active role, project, session or assignment fields | Database uses auth.uid() and persisted grants; forged fields cannot widen authority |
| TC-CMD-AUTHZ-024-033 | Protected-table direct DML — Anon/authenticated client attempts direct INSERT/UPDATE/DELETE on every protected table | All prohibited operations denied; no business/audit rows change |
| TC-CMD-AUTHZ-024-034 | Idempotency replay and hash — Same key/same semantic request then same key/different semantic request | First replay returns original outcome; changed hash returns IDEMPOTENCY_KEY_REUSED |
| TC-CMD-AUTHZ-024-035 | Audit fail-closed boundary — Required audit validation/insert fails for any critical state-changing command | Business mutation rolls back and no success response is emitted |
| TC-CMD-AUTHZ-024-036 | RPC/SECURITY DEFINER grant review — Unauthorized role calls RPC or PUBLIC attempts SECURITY DEFINER function | Only explicit EXECUTE principals succeed; pinned search_path, minimal owner/grants, schema-qualified refs verified |

**Execution status:** NOT EXECUTED. No runtime, database, RLS, grant, RPC or deployment changes were made by adding these specifications.
