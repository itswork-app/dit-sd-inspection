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

The command-family authorization mapping is maintained in [Command Authorization Verification Matrix](../02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md). The following 40 cases are allocated to command-family review and common security-boundary verification. They are planned specifications, not executed tests. They do not replace later per-command request/response, RLS, EXECUTE-grant, audit rollback, idempotency and concurrency cases once exact command contracts are approved.

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
| TC-CMD-AUTHZ-024-037 | Notification inbox recipient isolation — Recipient A lists or marks recipient B's notification read, or follows a notification link without source-resource permission | No cross-recipient row/read-state mutation; referenced resource independently re-authorizes; no resource existence leakage |
| TC-CMD-AUTHZ-024-038 | Notification policy authority — Caller without approved notification.policy.manage scope, grantor ceiling or required SoD publishes a policy or changes a published version | Denied; published versions immutable; no role grant inferred from title; policy/audit state unchanged |
| TC-CMD-AUTHZ-024-039 | Notification worker boundary — anon/authenticated/browser caller invokes fan-out, provider dispatch or escalation operation, or presents forged worker/lease identity | Browser invocation denied; only separately approved worker principal and valid lease may proceed; no service-role caller identity substitution |
| TC-CMD-AUTHZ-024-040 | Notification business-state isolation — Provider failure, retry exhaustion or escalation processing attempts to change inspection/project/session state | Notification lifecycle may change only its own state; inspection/project/session state remains unchanged; duplicate processing is idempotent |

**Execution status:** NOT EXECUTED. No runtime, database, RLS, grant, RPC or deployment changes were made by adding these specifications.

## Package M — per-table RLS and T-18 privilege verification plan (2026-11-24)

The table-level inventory and exact privilege interpretation are documented in [Physical Schema ↔ RLS ↔ Command Reconciliation](../02-architecture/PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md). The following 48 cases allocate one verification case to every table in the current proposed Package L/M inventory. These are design specifications only, not executed staging tests. Each test must record fixture actor, active account state, role/grants, scope graph, database role, request, SQLSTATE/API outcome, and actual row visibility/mutation result.

| Test ID | Table | Proposed SELECT class | Table-specific focus | Expected result |
|---|---|---|---|---|
| TC-RLS-024-001 | `app_users` | R-self; R-admin | User cannot change own approval, account status, roles, or display identity fields outside allowed profile update command | SELECT is limited to the catalogue class: R-self; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-002 | `roles` | R-admin; optionally authenticated read of non-sensitive active role labels | System role codes protected | SELECT is limited to the catalogue class: R-admin; optionally authenticated read of non-sensitive active role labels. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-003 | `permissions` | R-admin | Permission catalogue is administrative | SELECT is limited to the catalogue class: R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-004 | `role_permissions` | R-admin | Changes audited and reviewed | SELECT is limited to the catalogue class: R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-005 | `user_roles` | R-self limited to own grants; R-admin | User cannot grant/revoke own roles | SELECT is limited to the catalogue class: R-self limited to own grants; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-006 | `user_scope_grants` | R-self limited to own effective grants; R-admin | Scope target validation in trusted command | SELECT is limited to the catalogue class: R-self limited to own effective grants; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-007 | `account_decisions` | R-self limited to own decision history; R-admin | Append-only decision history | SELECT is limited to the catalogue class: R-self limited to own decision history; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-008 | `projects` | R-scope; R-admin | Project creation and lifecycle through command | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-009 | `locations` | R-scope; R-admin | Project membership enforced | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-010 | `sessions` | R-scope; R-admin | Inspector reads only active assigned sessions | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-011 | `teams` | R-scope; R-admin | Membership and scope checked | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-012 | `operational_assignments` | R-scope; R-admin | No self-assignment or client scope edits | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-013 | `assignment_members` | R-scope for relevant assignment; R-admin | Membership grant/revoke privileged and audited | SELECT is limited to the catalogue class: R-scope for relevant assignment; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-014 | `project_capacity_settings` | R-admin; read-only operational summary if approved | Global lock and capacity-count predicate enforced | SELECT is limited to the catalogue class: R-admin; read-only operational summary if approved. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-015 | `target_plans` | R-scope; R-admin | Draft mutable only by authorized planner; published immutable | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-016 | `target_allocations` | R-scope; R-admin | Versioned; never edits actual activity | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-017 | `instruments` | R-published; R-admin | Super Admin catalog management only | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-018 | `instrument_versions` | R-published; R-admin | Draft writes via configuration command; published immutable | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-019 | `checklist_sections` | R-published; R-admin | Draft version only | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-020 | `checklist_items` | R-published; R-admin | Declarative validation schema allowlist | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-021 | `specification_fields` | R-published; R-admin | Typed values; no executable expressions | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-022 | `evidence_slot_definitions` | R-published; R-admin | Required status and allowed media are versioned | SELECT is limited to the catalogue class: R-published; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-023 | `instrument_version_publications` | R-scope; R-admin | Append-only publication history | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-024 | `units` | R-scope; R-admin | Unit creation/serial normalization command only; canonical serial uniqueness DB enforced; unit ID alone grants no scope | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-025 | `unit_project_associations` | R-scope through matching project membership; R-admin | Durable ACTIVE/ENDED/REVOKED episodes; create/end only through reasoned audited commands; no hard delete | SELECT is limited to the catalogue class: R-scope through matching project membership; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-026 | `unit_identity_conflicts` | R-conflict-reviewer; minimum necessary project-scoped metadata only | Restricted same-instrument duplicate workflow; authorized resolution only; never exposes candidate project's inspection history | SELECT is limited to the catalogue class: R-conflict-reviewer; minimum necessary project-scoped metadata only. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-027 | `inspections` | R-scope according to Inspector/Reviewer/Korlap/Print Officer permissions; R-admin | Aggregate state changes only through commands | SELECT is limited to the catalogue class: R-scope according to Inspector/Reviewer/Korlap/Print Officer permissions; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-028 | `inspection_revisions` | R-scope; R-admin | Immutable after submission; draft snapshot handling only via command | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-029 | `checklist_responses` | R-scope; R-admin | Draft writes are command-only through T-18; browser direct DML is denied | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-030 | `specification_responses` | R-scope; R-admin | Draft writes are command-only through T-18; browser direct DML is denied | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-031 | `unit_claims` | R-scope for holder and authorized supervisors/reviewers; R-admin | Atomic claim and release command; no client expiry edits | SELECT is limited to the catalogue class: R-scope for holder and authorized supervisors/reviewers; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-032 | `review_events` | R-scope for assigned reviewers and authorized supervisors; R-admin | Append-only | SELECT is limited to the catalogue class: R-scope for assigned reviewers and authorized supervisors; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-033 | `inspection_events` | R-scope; R-admin | Append-only | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-034 | `evidence_assets` | R-scope; R-admin | Pending metadata managed by upload commands; finalized metadata immutable | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-035 | `documents` | R-scope; R-admin | Generation/finalization command only; output immutable | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-036 | `print_events` | R-scope for authorized print/operational roles; R-admin | Append-only sequence allocation | SELECT is limited to the catalogue class: R-scope for authorized print/operational roles; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-037 | `attendance_records` | R-scope; R-admin | Lifecycle command only | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-038 | `attendance_documents` | R-scope; R-admin | Replacement creates new version; no overwrite of original | SELECT is limited to the catalogue class: R-scope; R-admin. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-039 | `audit_events` | R-admin; R-scope only if a specific audit-read permission is granted | No direct client write; no update/delete for application roles | SELECT is limited to the catalogue class: R-admin; R-scope only if a specific audit-read permission is granted. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-040 | `idempotency_records` | NONE | Internal command machinery; retention cleanup via controlled maintenance | Unauthenticated and authenticated browser roles cannot SELECT this internal table; direct INSERT/UPDATE/DELETE are denied; only the explicitly authorized command/maintenance path can affect rows. |
| TC-RLS-024-041 | `sync_batches` | R-self/R-scope for own device batches only | Batch payload not exposed broadly; no cross-user read | SELECT is limited to the catalogue class: R-self/R-scope for own device batches only. Wrong project/location/session/assignment/subject or revoked membership returns no row/denies access. Browser INSERT/UPDATE/DELETE are denied even where the design labels the operation CMD; the approved command path must independently authorize the mutation. |
| TC-RLS-024-042 | `print_batches` | R-scope for authorized print/operational roles; R-admin | Batch metadata is restricted to its project/session/location scope; item outcomes are derived from authorized per-document events; retry cannot widen scope; browser direct DML denied. |
| TC-RLS-024-043 | `notification_policy_versions` | R-config-scope for explicitly authorized policy administrators; R-admin | Only approved config scope can read/manage drafts; published versions immutable; no role grant inferred from title; browser direct DML denied. |
| TC-RLS-024-044 | `notification_outbox` | NONE for browser roles; internal worker only | Anonymous/authenticated browser SELECT and DML are denied; only separately approved worker path can claim/complete leases; no payload leakage. |
| TC-RLS-024-045 | `notifications` | R-self where recipient_user_id = auth.uid(); R-admin | Recipient A cannot read/mark-read/dismiss recipient B's row; resource navigation independently re-authorizes; project role alone cannot read another recipient's inbox. |
| TC-RLS-024-046 | `notification_deliveries` | NONE for browser roles; internal worker; restricted operations reader only if approved | Recipients cannot inspect provider state; worker-only mutation; unauthenticated/forged provider callback cannot change delivery state. |
| TC-RLS-024-047 | `notification_delivery_attempts` | NONE for browser roles; internal worker; restricted oversight only if approved | No browser access; attempts are append-only and sanitized; no provider credentials, tokens or message bodies exposed. |
| TC-RLS-024-048 | `notification_escalation_events` | R-config-scope only for explicitly authorized oversight; internal worker | No cross-scope escalation visibility; append-only; escalation cannot mutate inspection/project/session state. |

**Execution status:** all 48 cases are PLANNED / NOT EXECUTED. They must be run against staging Supabase after approved migrations and grants exist. A passing mock or API-only test does not prove Postgres RLS or table privileges.

## Package N — individual PostgreSQL command contract verification (2026-11-24)

See [PostgreSQL Command Contract Catalogue](../02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) for 54 proposed logical command/read/worker operations (CMD-001..054). The following 48 original command cases each verify the named operation's contract boundary; notification operations CMD-049..054 have dedicated TC-NOTIF-001..018 coverage, including forged actor/scope rejection, command-specific invariant, typed outcome and no direct browser DML. They are design cases only. They do not execute PostgreSQL functions or prove grants/RLS.

| Test ID | Command | Permission | Authorization/security assertion | Command-specific invariant assertion | Expected typed outcome family | Status |
|---|---|---|---|---|---|---|
| TC-CMD-CONTRACT-024-001 | CMD-001 `request-account-access` | `account.request` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | ACCEPTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-002 | CMD-002 `approve-account` | `account.approve` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | APPROVED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-003 | CMD-003 `reject-account` | `account.approve` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | REJECTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-004 | CMD-004 `grant-role` | `role.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | T-14 combined Inspector cap is enforced atomically under concurrent role/assignment/cap changes; no silent deactivation. | GRANTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-005 | CMD-005 `revoke-role` | `role.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | REVOKED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-006 | CMD-006 `grant-scope` | `scope.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | GRANTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-007 | CMD-007 `revoke-scope` | `scope.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | REVOKED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-008 | CMD-008 `create-project` | `project.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | CREATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-009 | CMD-009 `update-project` | `project.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | UPDATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-010 | CMD-010 `close-project` | `project.close` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | CLOSED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-011 | CMD-011 `create-session` | `session.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | CREATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-012 | CMD-012 `update-session` | `session.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | UPDATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-013 | CMD-013 `transition-session` | `session.transition` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | TRANSITIONED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-014 | CMD-014 `publish-assignment` | `assignment.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | T-14 combined Inspector cap is enforced atomically under concurrent role/assignment/cap changes; no silent deactivation. | PUBLISHED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-015 | CMD-015 `change-assignment-members` | `assignment.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | T-14 combined Inspector cap is enforced atomically under concurrent role/assignment/cap changes; no silent deactivation. | UPDATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-016 | CMD-016 `change-inspector-capacity` | `capacity.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | T-14 combined Inspector cap is enforced atomically under concurrent role/assignment/cap changes; no silent deactivation. | UPDATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-017 | CMD-017 `manage-target-plan` | `target.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | DRAFTED/UPDATED/PUBLISHED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-018 | CMD-018 `create-instrument` | `instrument.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | CREATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-019 | CMD-019 `save-instrument-draft` | `instrument.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | SAVED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-020 | CMD-020 `publish-instrument-version` | `instrument.publish` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | PUBLISHED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-021 | CMD-021 `deactivate-instrument` | `instrument.deactivate` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | DEACTIVATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-022 | CMD-022 `register-canonical-unit` | `unit.register` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | REGISTERED/EXISTING_AUTHORIZED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-023 | CMD-023 `associate-unit-to-project` | `unit.associate` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | ASSOCIATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-024 | CMD-024 `end-unit-project-association` | `unit.association.end` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | `unit.project_association_ended/revoked` | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-025 | CMD-025 `resolve-unit-identity-conflict` | `unit.identity.resolve` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | `unit.identity_conflict_resolved/rejected` | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-026 | CMD-026 `claim-unit` | `inspection.claim` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | CLAIMED/RESUMED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-027 | CMD-027 `release-unit-claim` | `inspection.claim` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Canonical serial uniqueness, durable association and one-active-claim-per-unit invariants survive cross-project concurrent attempts. | RELEASED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-028 | CMD-028 `save-draft` | `inspection.edit` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Expected revision/row version, active claim, immutable submitted revision and reviewer/author SoD are enforced atomically. | SAVED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-029 | CMD-029 `submit-inspection` | `inspection.submit` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Expected revision/row version, active claim, immutable submitted revision and reviewer/author SoD are enforced atomically. | SUBMITTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-030 | CMD-030 `return-inspection` | `inspection.review` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Expected revision/row version, active claim, immutable submitted revision and reviewer/author SoD are enforced atomically. | RETURNED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-031 | CMD-031 `approve-inspection` | `inspection.review` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Expected revision/row version, active claim, immutable submitted revision and reviewer/author SoD are enforced atomically. | APPROVED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-032 | CMD-032 `reopen-inspection` | `inspection.reopen` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Expected revision/row version, active claim, immutable submitted revision and reviewer/author SoD are enforced atomically. | REOPENED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-033 | CMD-033 `create-upload-intent` | `evidence.upload` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Private object intent/finalization verifies server-observed object metadata; invalid/missing object is not finalized; orphan reconciliation is observable. | INTENT_CREATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-034 | CMD-034 `confirm-upload` | `evidence.upload` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Private object intent/finalization verifies server-observed object metadata; invalid/missing object is not finalized; orphan reconciliation is observable. | FINALIZED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-035 | CMD-035 `sync-batch` | `sync.apply` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Each offline operation is reauthorized and ordered; conflicts preserve queued data; forbidden submit/review/admin operations are rejected. | APPLIED/PARTIAL/CONFLICTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-036 | CMD-036 `generate-approved-document` | `document.generate` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | GENERATED/ACCEPTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-037 | CMD-037 `record-print` | `document.print` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | RECORDED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-038 | CMD-038 `record-print-batch` | `document.print.batch` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Batch size is bounded; each item has independent outcome; only failed items retry; successful items never duplicate. | PARTIAL/SUCCEEDED/REJECTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-039 | CMD-039 `upload-attendance-document` | `attendance.upload` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Private object intent/finalization verifies server-observed object metadata; invalid/missing object is not finalized; orphan reconciliation is observable. | UPLOADED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-040 | CMD-040 `verify-attendance` | `attendance.verify` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Attendance upload does not grant verify authority; verifier scope and any approved uploader/verifier SoD are enforced. | VERIFIED/REJECTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-041 | CMD-041 `get-actual-report` | `report.read` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | OK | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-042 | CMD-042 `get-target-report` | `report.read` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/replay requests cannot duplicate the business result; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED. | OK | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-043 | CMD-043 `read-audit` | `audit.read` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Purpose and scope are enforced; export permission is distinct; access/export events are audited without recursive sensitive payload leakage. | OK | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-044 | CMD-044 `export-audit` | `audit.export` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Purpose and scope are enforced; export permission is distinct; access/export events are audited without recursive sensitive payload leakage. | ACCEPTED/EXPORTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-045 | CMD-045 `retention/legal-hold` | `retention.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Command remains unavailable until its institutional authority and physical schema are approved; no placeholder function/table is exposed. | BLOCKED_BY_POLICY | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-046 | CMD-046 `review-security-incident` | `security.review` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Command remains unavailable until its institutional authority and physical schema are approved; no placeholder function/table is exposed. | BLOCKED_BY_SCHEMA_AUTHORITY | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-047 | CMD-047 `manage-provider-configuration` | `provider.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Command remains unavailable until its institutional authority and physical schema are approved; no placeholder function/table is exposed. | BLOCKED_BY_T12 | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-048 | CMD-048 `manage-production-release` | `release.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Command remains unavailable until its institutional authority and physical schema are approved; no placeholder function/table is exposed. | `production.release_deployed/rollback_performed` | PLANNED / NOT EXECUTED |

**Execution gate:** all 48 cases remain PLANNED / NOT EXECUTED. Before execution, bind each case to the approved exact RPC signature, route schema, staging migration, caller database role, fixtures, expected SQLSTATE/domain mapping and captured result. For blocked CMD-045..048, the expected result is deny/not exposed until the prerequisite institutional authority/schema is approved.

## PostgreSQL function security and EXECUTE grant verification (2026-11-24)

See [PostgreSQL Function Security & EXECUTE Grant Design](../02-architecture/POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md). The following cases are design-only. They must be bound to exact function identities/argument types, actual database roles, deployed ACLs, RLS state and the approved T-18 execution model before staging execution.

### Per-operation security cases

| Test ID | Operation | Function class / permission | Security assertion | Expected outcome | Status |
|---|---|---|---|---|---|
| TC-FN-SEC-025-001 | CMD-001 `request-account-access` | F1 / `account.request` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-002 | CMD-002 `approve-account` | F1 / `account.approve` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-003 | CMD-003 `reject-account` | F1 / `account.approve` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-004 | CMD-004 `grant-role` | F1 / `role.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-005 | CMD-005 `revoke-role` | F1 / `role.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-006 | CMD-006 `grant-scope` | F1 / `scope.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-007 | CMD-007 `revoke-scope` | F1 / `scope.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-008 | CMD-008 `create-project` | F1 / `project.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-009 | CMD-009 `update-project` | F1 / `project.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-010 | CMD-010 `close-project` | F1 / `project.close` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-011 | CMD-011 `create-session` | F1 / `session.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-012 | CMD-012 `update-session` | F1 / `session.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-013 | CMD-013 `transition-session` | F1 / `session.transition` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-014 | CMD-014 `publish-assignment` | F1 / `assignment.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-015 | CMD-015 `change-assignment-members` | F1 / `assignment.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-016 | CMD-016 `change-inspector-capacity` | F1 / `capacity.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-017 | CMD-017 `manage-target-plan` | F1 / `target.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-018 | CMD-018 `create-instrument` | F1 / `instrument.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-019 | CMD-019 `save-instrument-draft` | F1 / `instrument.manage` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-020 | CMD-020 `publish-instrument-version` | F1 / `instrument.publish` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-021 | CMD-021 `deactivate-instrument` | F1 / `instrument.deactivate` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-022 | CMD-022 `register-canonical-unit` | F1 / `unit.register` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-023 | CMD-023 `associate-unit-to-project` | F1 / `unit.associate` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-024 | CMD-024 `end-unit-project-association` | F1 / `unit.association.end` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-025 | CMD-025 `resolve-unit-identity-conflict` | F1 / `unit.identity.resolve` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-026 | CMD-026 `claim-unit` | F1 / `inspection.claim` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-027 | CMD-027 `release-unit-claim` | F1 / `inspection.claim` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-028 | CMD-028 `save-draft` | F1 / `inspection.edit` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-029 | CMD-029 `submit-inspection` | F1 / `inspection.submit` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-030 | CMD-030 `return-inspection` | F1 / `inspection.review` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-031 | CMD-031 `approve-inspection` | F1 / `inspection.review` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-032 | CMD-032 `reopen-inspection` | F1 / `inspection.reopen` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-033 | CMD-033 `create-upload-intent` | F1 / `evidence.upload` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-034 | CMD-034 `confirm-upload` | F1 / `evidence.upload` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-035 | CMD-035 `sync-batch` | F1 / `sync.apply` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-036 | CMD-036 `generate-approved-document` | F1 / `document.generate` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-037 | CMD-037 `record-print` | F1 / `document.print` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-038 | CMD-038 `record-print-batch` | F1 / `document.print.batch` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-039 | CMD-039 `upload-attendance-document` | F1 / `attendance.upload` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-040 | CMD-040 `verify-attendance` | F1 / `attendance.verify` | Exact command signature only; anon/PUBLIC denied; authenticated has no protected table DML; command path enforces JWT actor, permission, scope, SoD, audit and idempotency. T-18 Option A model is PO-approved; exact function owner, signature, grants, JWT path and per-function security review remain mandatory before exposure. | COMMAND_ALLOWED_IF_AUTHORIZED / EXECUTE_DENIED_OR_BUSINESS_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-041 | CMD-041 `get-actual-report` | F2 / `report.read` | Only exact approved read RPC EXECUTE may be granted to authenticated; anon/PUBLIC denied; bounded scope enforced and RLS remains effective. | READ_ALLOWED_IN_SCOPE / DENIED_OUT_OF_SCOPE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-042 | CMD-042 `get-target-report` | F2 / `report.read` | Only exact approved read RPC EXECUTE may be granted to authenticated; anon/PUBLIC denied; bounded scope enforced and RLS remains effective. | READ_ALLOWED_IN_SCOPE / DENIED_OUT_OF_SCOPE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-043 | CMD-043 `read-audit` | F2 / `audit.read` | Only exact approved read RPC EXECUTE may be granted to authenticated; anon/PUBLIC denied; bounded scope enforced and RLS remains effective. | READ_ALLOWED_IN_SCOPE / DENIED_OUT_OF_SCOPE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-044 | CMD-044 `export-audit` | F2 / `audit.export` | Only exact approved read RPC EXECUTE may be granted to authenticated; anon/PUBLIC denied; bounded scope enforced and RLS remains effective. | READ_ALLOWED_IN_SCOPE / DENIED_OUT_OF_SCOPE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-045 | CMD-045 `retention/legal-hold` | F6 / `retention.manage` | No PostgreSQL function or route is exposed; anon/authenticated/service_role cannot invoke a placeholder operation before approved authority and schema exist. | NOT_EXPOSED / AUTHORITY_OR_SCHEMA_BLOCKED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-046 | CMD-046 `review-security-incident` | F6 / `security.review` | No PostgreSQL function or route is exposed; anon/authenticated/service_role cannot invoke a placeholder operation before approved authority and schema exist. | NOT_EXPOSED / AUTHORITY_OR_SCHEMA_BLOCKED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-047 | CMD-047 `manage-provider-configuration` | F6 / `provider.manage` | No PostgreSQL function or route is exposed; anon/authenticated/service_role cannot invoke a placeholder operation before approved authority and schema exist. | NOT_EXPOSED / AUTHORITY_OR_SCHEMA_BLOCKED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-048 | CMD-048 `manage-production-release` | F6 / `release.manage` | No PostgreSQL function or route is exposed; anon/authenticated/service_role cannot invoke a placeholder operation before approved authority and schema exist. | NOT_EXPOSED / AUTHORITY_OR_SCHEMA_BLOCKED | PLANNED / NOT EXECUTED |

### Global function/ACL boundary cases

| Test ID | Boundary | Scope | Assertion | Expected evidence | Status |
|---|---|---|---|---|---|
| TC-FN-SEC-025-064 | CMD-049 `list-own-notifications` | F2 / `notification.read` | Recipient-self rows only; no resource authorization inherited from notification; exact read RPC or scoped SELECT only; anon/PUBLIC denied. | READ_OWN / DENIED_OTHER_RECIPIENT | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-065 | CMD-050 `mark-notification-read` | F1 / `notification.read` | Exact recipient-self row, expected version and idempotent acknowledgement; no cross-recipient update; audit/read state atomicity per approved policy. | MARKED_READ / NOT_FOUND_OR_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-066 | CMD-051 `publish-notification-policy` | F1 / `notification.policy.manage` | Exact approved policy scope and grantor ceiling; published version immutable; no role grants inferred; policy publication and audit atomic. | PUBLISHED_IF_AUTHORIZED / DENIED_OR_STALE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-067 | CMD-052 `fanout-notification-outbox` | F5 / internal worker principal | No browser EXECUTE; worker identity, lease token, bounded batch and idempotent recipient/channel fan-out required; no user actor impersonation. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-068 | CMD-053 `dispatch-notification-delivery` | F5 / internal delivery worker | No browser EXECUTE; provider I/O outside DB transaction; lease and attempt idempotency; ambiguous provider acceptance remains UNKNOWN; secrets/payloads redacted. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-069 | CMD-054 `evaluate-notification-escalation` | F5 / internal scheduler/worker | No browser EXECUTE; policy-version-pinned SLA evaluation; unique escalation step; recipient revalidation; no business-state mutation. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-049 | Global privilege boundary — Role ACL snapshot | Global | Catalog evidence confirms expected role attributes/memberships; no unreviewed LOGIN/SUPERUSER/BYPASSRLS or inherited broad grant. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-050 | Global privilege boundary — PUBLIC EXECUTE denial | Global | PUBLIC cannot execute any protected application RPC or internal helper; overloads are checked by identity arguments. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-051 | Global privilege boundary — anon boundary | Global | anon cannot execute protected RPCs or read protected application data. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-052 | Global privilege boundary — authenticated direct DML denial | Global | authenticated cannot INSERT/UPDATE/DELETE any protected table, including draft response/evidence/document tables. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-053 | Global privilege boundary — Exact RPC allowlist | Global | authenticated can execute only approved exact signatures; unapproved overloads and neighboring functions are denied. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-054 | Global privilege boundary — service_role isolation | Global | User-initiated commands preserve caller JWT and never use service_role as the user identity. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-055 | Global privilege boundary — Internal helper exposure | Global | Internal authorization helpers are not callable through exposed PostgREST schemas or broad EXECUTE grants. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-056 | Global privilege boundary — SECURITY DEFINER owner | Global | Each approved definer owner is NOLOGIN, non-superuser, not BYPASSRLS and has only minimum object privileges. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-057 | Global privilege boundary — search_path shadowing | Global | Pinned search_path and schema qualification prevent untrusted schema/object shadowing. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-058 | Global privilege boundary — JWT actor spoofing | Global | Forged actor/user/role/scope payloads and user-editable JWT metadata cannot elevate identity or permission. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-059 | Global privilege boundary — Revocation immediacy | Global | Expired/revoked role or permission is denied at command transaction time. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-060 | Global privilege boundary — Non-disclosure | Global | Unauthorized function calls do not reveal whether protected resource IDs exist. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-061 | Global privilege boundary — Atomic audit failure | Global | Audit write failure rolls back protected business mutation and idempotency result. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-062 | Global privilege boundary — Default ACL/inheritance | Global | Default privileges, role inheritance and schema usage do not reintroduce broad EXECUTE or table DML. | PASS only when ACL/catalog evidence and negative runtime test agree | PLANNED / NOT EXECUTED |

| TC-FN-SEC-025-063 | SECURITY DEFINER owner table ownership | Global | Definer owner does not own protected application tables or inherit table-owner privileges; if an exception is approved, FORCE ROW LEVEL SECURITY and explicit threat-model evidence are required. | PASS only when ownership, role inheritance, FORCE RLS and runtime negative tests agree | PLANNED / NOT EXECUTED |

**Execution gate:** 69 cases are PLANNED / NOT EXECUTED (54 operation-level cases for CMD-001..054 plus 15 global privilege-boundary cases). T-18 execution-model selection is PO-approved as Option A. Exact function-level reviews, live role/ACL inventory and runtime evidence remain mandatory before any protected mutation RPC or grant is implemented. No SQL, grants, revokes, migrations, RLS changes or runtime tests were performed by this documentation update.

## Supabase live database security inventory verification (2026-11-24)

See [Supabase Live Database Security Inventory Runbook](../02-architecture/SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md). These cases require actual read-only catalog/Dashboard evidence from the approved target environment. Repository documents or screenshots of proposed schemas are not substitutes. No live database inventory has been executed.

| Test ID | Inventory surface | Verification requirement | Evidence / acceptance | Status |
|---|---|---|---|---|
| TC-LIVE-INV-026-001 | Environment identity and engine | Verify target project/environment label, database identity and PostgreSQL version before interpreting catalog results. | Approved non-secret environment reference and timestamp; no credentials captured. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-002 | Roles and memberships | Inventory role attributes and memberships; identify LOGIN, SUPERUSER, CREATEROLE, BYPASSRLS and inherited privileges. | All application and privileged roles classified; unexpected privilege paths resolved. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-003 | Schema and object ownership | Inventory schemas, table/view/partition/sequence ownership and schema ACLs. | Ownership reconciled to approved least-privilege model; no unreviewed exposed schema. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-004 | Table ACL and RLS | Inventory table ACLs, RLS enabled/forced flags and all policies. | Protected browser roles lack direct INSERT/UPDATE/DELETE; exposed application tables have reviewed deny-by-default RLS. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-005 | Function inventory and EXECUTE | Inventory exact function identities/overloads, owners, language, SECURITY mode, function settings and effective EXECUTE grants. | PUBLIC/anon and inherited broad EXECUTE paths are resolved; exact approved signatures only. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-006 | SECURITY DEFINER ownership | Verify definer owner attributes, memberships, protected-table ownership, search_path and schema qualification. | NOLOGIN least-privileged owner; no SUPERUSER/BYPASSRLS or inherited table-owner privilege; exception requires approved threat model. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-007 | Default ACL and inheritance | Inspect default privileges, schema usage and inherited table/routine grants. | No future object silently receives broad PUBLIC/browser DML or EXECUTE. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-008 | Views, triggers and sequences | Inventory view ownership/security behavior, trigger targets and sequence ACLs. | No unreviewed privilege bypass or direct sequence exposure. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-009 | Storage policy metadata | Inventory Storage bucket/object policy definitions and bucket privacy/limits without reading object data. | Upload/download/delete policies are scoped; no public evidence exposure; T-10 limits remain unset until institutional approval. | PLANNED / NOT EXECUTED |
| TC-LIVE-INV-026-010 | Supabase Dashboard/provider controls | Verify exposed schemas, Auth configuration, environment-variable names only, backups/PITR, region, network and ownership/recovery evidence. | T-12 provider/backup/ownership gates have authoritative evidence; secrets are never exported. | PLANNED / NOT EXECUTED |

**Execution gate:** All 10 inventory cases remain PLANNED / NOT EXECUTED because no live Supabase connector/session is available. The audit must use the read-only runbook, preserve permission errors and redacted evidence, and must not execute migrations or privilege changes.



### T-18 approved execution-model verification

The T-18 execution model is PO APPROVED as Option A. These additional acceptance cases verify the selected narrow SECURITY DEFINER pattern. All cases remain PLANNED / NOT EXECUTED.

| Test ID | Boundary | Assertion | Expected evidence | Status |
|---|---|---|---|---|
| TC-EXEC-MODEL-027-001 | Dedicated definer owner | Owner is NOLOGIN, non-superuser, non-BYPASSRLS, non-CREATEROLE and has no inherited broad privilege. | Role catalog, memberships and effective privilege evidence. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-002 | Ownership isolation | Definer owner owns no protected business table/schema and inherits no table-owner or migration-owner privilege. | Ownership and membership inventory reconciled to function-by-function owner matrix. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-003 | search_path hardening | Every definer function has fixed empty search_path and fully qualified object references. | Function catalog configuration and source review; shadow-object attack denied. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-004 | Exact EXECUTE ACL | PUBLIC/anon denied; authenticated receives only individually approved exact signatures; overloads and inherited grants checked. | Routine ACL and effective privilege evidence plus negative invocation tests. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-005 | Caller JWT preservation | Vercel route forwards the verified caller JWT to the PostgreSQL RPC without service-role substitution. | End-to-end HTTP trace with redacted claims and expected auth.uid() binding. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-006 | Actor spoofing | Caller-supplied actor/user/role/scope and user-editable metadata cannot change database-derived identity or authority. | Forged payload/JWT metadata negative tests. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-007 | Protected direct DML | Browser anon/authenticated roles cannot directly INSERT/UPDATE/DELETE protected tables. | Table ACL and RLS catalog evidence plus PostgREST direct-DML denial tests. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-008 | RLS/owner interaction | Definer owner has no unintended RLS bypass; table ownership, FORCE RLS and memberships match approved model. | Catalog evidence and cross-scope runtime tests. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-009 | Authorization freshness | Disabled account, revoked/expired permission, wrong project/session/assignment and failed SoD are denied at command time. | Positive/negative tests using real caller JWT and database grants. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-010 | Atomic audit failure | Failure to write required audit event rolls back business mutation, canonical event and idempotency result. | Controlled transaction fault-injection evidence. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-011 | Idempotency/concurrency | Replays, mismatched request hashes and concurrent duplicate commands cannot duplicate state transitions or audit outcomes. | Concurrent integration test results and transaction traces. | PLANNED / NOT EXECUTED |
| TC-EXEC-MODEL-027-012 | Read path separation | Read-only queries use SECURITY INVOKER/RLS by default and do not gain write privileges through helper functions or views. | Function/view security inventory and cross-scope read/write negative tests. | PLANNED / NOT EXECUTED |



### T-19 repository runtime architecture audit verification

The read-only repository audit found no application implementation or runtime/configuration artifacts on the audited refs. The following cases are BLOCKED / NOT EXECUTED until the intended application repository/branch and implementation baseline are available.

| Test ID | Boundary | Assertion | Required evidence | Status |
|---|---|---|---|---|
| TC-REPO-AUDIT-028-001 | Repository identity | Confirm the canonical application repository and branch; determine whether this repository is intentionally documentation-only or the application source of truth. | PO-confirmed repository/branch record and tree inventory. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-002 | Vercel runtime | Verify framework, build configuration, route handlers, serverless runtime and preview/production isolation. | Source/config review and reproducible Vercel build/deployment evidence. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-003 | Supabase client separation | Verify browser and server clients are separate; server secrets are server-only and never bundled into browser assets. | Client initialization source, build artifact scan and secret-handling review. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-004 | Caller JWT propagation | Verify Vercel forwards the verified caller JWT unchanged to PostgREST RPC and does not substitute service_role for user commands. | End-to-end authenticated HTTP test with redacted evidence and database auth.uid() assertion. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-005 | Database migration inventory | Verify versioned migrations, exact SECURITY DEFINER functions, dedicated owners, search_path, table grants, RLS and exact EXECUTE ACLs. | Complete migration/source inventory reconciled with live read-only catalog inventory. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-006 | Route-command mapping | Verify every protected route maps to one approved command contract and does not permit client-selected function names, overloads or privileged scope. | Route/API/RPC mapping, schema validation and negative authorization tests. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-007 | Automated quality/security coverage | Verify unit, integration, authorization, tenant/project isolation, audit rollback, idempotency and concurrency tests are present and runnable. | CI workflow inventory, test reports and reproducible local/CI execution. | BLOCKED / NOT EXECUTED |
| TC-REPO-AUDIT-028-008 | Build and deployment provenance | Verify lockfile, pinned runtime/toolchain, reproducible build, deployment commit provenance and environment protection. | Build logs, artifact provenance and Vercel/GitHub environment configuration evidence. | BLOCKED / NOT EXECUTED |

## Notification lifecycle verification — NLA-001 (planned, not executed)

- TC-NOTIF-001: source event and outbox intent commit atomically; audit/outbox failure rolls back the business mutation.
- TC-NOTIF-002: duplicate outbox processing creates one inbox row per recipient.
- TC-NOTIF-003: multiple selectors resolving the same user produce one recipient notification.
- TC-NOTIF-004: role membership without matching assignment scope cannot receive or read scoped notification.
- TC-NOTIF-005: recipient A cannot list/read/mark-read recipient B's notification.
- TC-NOTIF-006: notification link does not bypass authorization on the referenced resource.
- TC-NOTIF-007: delivery state and read state remain independent under all transitions.
- TC-NOTIF-008: quiet hours suppress/defer only channels allowed by the pinned policy and correct time zone.
- TC-NOTIF-009: provider retry is idempotent; duplicate webhook/result does not create duplicate state transitions.
- TC-NOTIF-010: provider accepted + worker crash yields safe UNKNOWN/reconciliation behavior, not false exactly-once claims.
- TC-NOTIF-011: expired worker lease is reclaimable without duplicate fan-out.
- TC-NOTIF-012: policy publish creates immutable version/hash; old outbox retains old policy version.
- TC-NOTIF-013: escalation step runs once; no eligible recipient does not widen scope.
- TC-NOTIF-014: failed notification delivery never changes inspection/project/session status.
- TC-NOTIF-015: revoked/disabled account or push subscription is excluded at dispatch.
- TC-NOTIF-016: sensitive payloads, tokens and provider secrets are absent from logs/audit/attempt records.
- TC-NOTIF-017: outbox backlog, dead-letter, retry age and provider failure metrics/alerts are observable.
- TC-NOTIF-018: cursor pagination cannot cross recipient identity or filter scope.

These cases are test specifications only. No notification tests have been executed.

## Print batch lifecycle verification — T-13 (planned, not executed)

- TC-PRINT-BATCH-001: reject a batch exceeding the configured maximum before creating any per-document print event.
- TC-PRINT-BATCH-002: persist one durable batch ID and one current outcome per requested document; aggregate counts reconcile to per-document outcomes.
- TC-PRINT-BATCH-003: each document is independently authorized for exact project/session/location scope and immutable PDF version.
- TC-PRINT-BATCH-004: mixed success/failure/cancelled results remain partial; no batch-wide success is inferred.
- TC-PRINT-BATCH-005: retry accepts failed documents only; successful/cancelled documents are rejected and prior events remain immutable.
- TC-PRINT-BATCH-006: concurrent print/reprint attempts allocate unique monotonic per-document sequence numbers without duplicate success outcomes.
- TC-PRINT-BATCH-007: duplicate request replay is idempotent; same key/different semantic payload returns IDEMPOTENCY_KEY_REUSED.
- TC-PRINT-BATCH-008: application print initiation/confirmation is not represented as proof of physical paper output or printer-device success.

These cases are test specifications only; they are not executed.
