# Test Case Catalog and UAT Plan

Status: Test catalog draft — execution not started
Version: 0.6.2

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
| TC-RLS-024-043 | `notification_policy_versions` | NONE by default; narrowly scoped config read only after explicit grant approval | Browser roles cannot read by default; CMD-051 publication is command-only; no persisted draft CRUD or role grant inferred; browser direct DML denied. |
| TC-RLS-024-044 | `notification_outbox` | NONE for browser roles; internal worker only | Anonymous/authenticated browser SELECT and DML are denied; only separately approved worker path can claim/complete leases; no payload leakage. |
| TC-RLS-024-045 | `notifications` | R-self where recipient_user_id = auth.uid() only | Recipient A cannot read/mark-read recipient B's row; no R-admin/global inbox access; resource navigation independently re-authorizes; project role alone cannot read another recipient's inbox; dismissed_at remains dormant. |
| TC-RLS-024-046 | `notification_deliveries` | NONE for browser roles; internal worker; restricted operations reader only if approved | Recipients cannot inspect provider state; worker-only mutation; unauthenticated/forged provider callback cannot change delivery state. |
| TC-RLS-024-047 | `notification_delivery_attempts` | NONE for browser roles; internal worker; restricted oversight only if approved | No browser access; attempts are append-only and sanitized; no provider credentials, tokens or message bodies exposed. |
| TC-RLS-024-048 | `notification_escalation_events` | NONE for browser roles; internal worker only; restricted operations reader only after explicit approval | Browser roles cannot read or mutate; append-only; escalation cannot mutate inspection/project/session state. |

**Execution status:** all 48 cases are PLANNED / NOT EXECUTED. They must be run against staging Supabase after approved migrations and grants exist. A passing mock or API-only test does not prove Postgres RLS or table privileges.

## Package N — individual PostgreSQL command contract verification (2026-11-24)

See [PostgreSQL Command Contract Catalogue](../02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) for 54 proposed logical command/read/worker operations (CMD-001..054). The following 48 original command cases each verify the named operation's contract boundary; notification operations CMD-049..054 have dedicated TC-NOTIF-001..018 coverage, including forged actor/scope rejection, command-specific invariant, typed outcome and no direct browser DML. They are design cases only. They do not execute PostgreSQL functions or prove grants/RLS.

| Test ID | Command | Permission | Authorization/security assertion | Command-specific invariant assertion | Expected typed outcome family | Status |
|---|---|---|---|---|---|---|
| TC-CMD-CONTRACT-024-001 | CMD-001 `request-account-access` | `account.request` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent first requests for one auth_user_id converge on one canonical account/request lifecycle; unique-index/UPSERT arbitration has no duplicate audit or idempotency result; same key/different hash rejects. | ACCEPTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-002 | CMD-002 `approve-account` | `account.approve` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Approve/reject race with CMD-003 yields exactly one legal terminal decision; actor authority revoke cannot be bypassed by stale preflight; duplicate replay remains idempotent. | APPROVED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-003 | CMD-003 `reject-account` | `account.approve` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Reject/approve race shares the exact target-account transition; no duplicate terminal decision, implicit role/scope revocation or stale actor authority. | REJECTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-004 | CMD-004 `grant-role` | `role.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Grant/revoke, assignment membership and cap-change races share the same L10 capacity rows before L15/L16; T-14 cap never exceeds limit and no silent deactivation occurs. | GRANTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-005 | CMD-005 `revoke-role` | `role.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Inspector revoke serializes with grant/assignment/cap changes through L10; concurrent duplicate revoke is one transition; last-admin guard and stale token behavior are enforced. | REVOKED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-006 | CMD-006 `grant-scope` | `scope.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent duplicate/overlapping scope grants converge on one valid interval; grantor ceiling is stable under concurrent revoke; closed/incompatible scope parent cannot receive a new grant. | GRANTED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-007 | CMD-007 `revoke-scope` | `scope.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent grant/revoke and duplicate revoke converge on one grant lifecycle; protected commands do not accept stale revoked authorization after the approved freshness boundary. | REVOKED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-008 | CMD-008 `create-project` | `project.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Concurrent normalized-code creates yield one project; project and default T-14 capacity settings are created atomically or both roll back; no missing/duplicate capacity row. | CREATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-009 | CMD-009 `update-project` | `project.manage` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Competing project updates use approved CAS; update vs close serializes on project parent; no metadata write commits after CLOSED and stale version is rejected. | UPDATED | PLANNED / NOT EXECUTED |
| TC-CMD-CONTRACT-024-010 | CMD-010 `close-project` | `project.close` | Forged actor/role/scope fields and wrong-scope caller are rejected; protected direct browser DML remains denied. | Close vs every project child writer/finalizer is serialized by the parent fence: child commits before close and is included in blockers, or waits and is rejected after close; pending intents are accounted for; no cascade/history rewrite. | CLOSED | PLANNED / NOT EXECUTED |
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
| TC-CMD-CONTRACT-024-045 | CMD-045 (external traceability ID) | NONE — no app permission | No app route/RPC/function/table/worker or application retention authority exists in the approved design; external institutional records control plane is authoritative. | No app mutation. T-10 policy and institutional authority must be evidenced externally; no hold/release/disposition is inferred from application role. | DEFERRED_EXTERNAL_CONTROL_PLANE | PLANNED / NOT EXECUTED — external evidence only |
| TC-CMD-CONTRACT-024-046 | CMD-046 (external traceability ID) | NONE — no app permission | No app security-case route/permission/table or implicit mitigation; only institution-designated incident-response process is authoritative. | No app case mutation or account/provider action; incident RACI and evidence chain remain external dependencies. | DEFERRED_EXTERNAL_CONTROL_PLANE | PLANNED / NOT EXECUTED — external evidence only |
| TC-CMD-CONTRACT-024-047 | CMD-047 (external traceability ID) | NONE — no app permission | Provider-native console and approved secret manager only; no app provider CRUD, route, worker, secret reference or credential exposure. | No app configuration mutation; T-12 ownership, custodians, billing, region, quota and recovery evidence are verified externally. | OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL | PLANNED / NOT EXECUTED — external evidence only |
| TC-CMD-CONTRACT-024-048 | CMD-048 (external traceability ID) | NONE — no app permission | Protected GitHub/deployment control plane only; no app deploy/rollback route, function, worker or alternate production control path. | No application deployment event; immutable commit/artifact/schema/migration and deployment evidence remains in protected release systems. | OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL | PLANNED / NOT EXECUTED — external evidence only |

**Execution gate:** all 48 traceability anchors remain PLANNED / NOT EXECUTED. CMD-001–044 and CMD-049–054 application operations require exact approved signatures, staging migration, caller/workload identity, fixtures and captured results. CMD-045–048 are not application commands: their anchors are external control-plane evidence checks only, not RPC/route tests.

### CMD-045–048 blocked-command review subcases — design only

The following subcases expand the CMD-045–048 traceability anchors. They are external control-plane readiness/evidence checks, not tests of application commands. No app route, RPC, function, table, worker or permission exists or may be inferred. They are planned and not executed.

| Test ID | Command | Scenario / assertion | Expected result | Status |
|---|---|---|---|---|
| TC-CMD-045-048-001 | CMD-045 | T-10 institutional policy absent or incomplete | Command unavailable; no hold, retention or disposition mutation | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-002 | CMD-045 | Active approved hold races with queued disposition | No covered record/object is disposed; deterministic audited outcome | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-003 | CMD-045 | Unauthorized hold release or arbitrary client approval reference | Denied; no policy or hold state changes | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-004 | CMD-046 | Incident scope/authority not approved or caller lacks case scope | Command unavailable or denied without case enumeration | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-005 | CMD-046 | Break-glass access, if institutionally approved | Bounded access, reason, expiry and independent review evidence | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-006 | CMD-046 | Incident review attempts to mutate business state or self-grant privileges | Denied; no operational state or authorization mutation | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-007 | CMD-047 | T-12 ownership/custody or approved secret manager absent | No provider configuration write path | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-008 | CMD-047 | Raw secret/token/private key supplied or emitted in logs/audit/errors | Rejected and never persisted or disclosed | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-009 | CMD-047 | Unauthorized provider/environment/config key or stale version | Denied; approved configuration remains unchanged | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-010 | CMD-048 | Missing release operator, environment approval or required CI check | Promotion/rollback unavailable | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-011 | CMD-048 | Artifact digest/source commit mismatch or untrusted artifact | Promotion denied; immutable provenance retained | PLANNED / NOT EXECUTED |
| TC-CMD-045-048-012 | CMD-048 | Rollback with incompatible/destructive schema reversal | Rollback blocked pending approved recovery/compatibility plan | PLANNED / NOT EXECUTED |

Execution requires the relevant external authority and approved control-plane process, named accountable owners, and reproducible evidence. These cases do not authorize creation or invocation of application commands, nor testing against production or real institutional data.

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
| TC-FN-SEC-025-064 | CMD-049 `list-own-notifications` | F2 / `notification.read` | Recipient-self rows only; no resource authorization inherited from notification; exact read RPC or scoped SELECT only; anon/PUBLIC denied. | READ_OWN / DENIED_OTHER_RECIPIENT | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-065 | CMD-050 `mark-notification-read` | F1 / `notification.read` | Exact recipient-self row; guarded set-once read_at update; no expected_version or cross-recipient update; first transition audit atomicity. | MARKED_READ / NOT_FOUND_OR_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-066 | CMD-051 `publish-notification-policy` | F1 / `notification.policy.manage` | Exact approved policy scope and grantor ceiling; published version immutable; no role grants inferred; policy publication and audit atomic. | PUBLISHED_IF_AUTHORIZED / DENIED_OR_STALE | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-067 | CMD-052 `fanout-notification-outbox` | F5 / internal worker principal | No browser EXECUTE; worker identity, lease token, bounded batch and idempotent recipient/channel fan-out required; no user actor impersonation. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-068 | CMD-053 `dispatch-notification-delivery` | F5 / internal delivery worker | No browser EXECUTE; provider I/O outside DB transaction; lease and attempt idempotency; ambiguous provider acceptance remains UNKNOWN; secrets/payloads redacted. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-069 | CMD-054 `evaluate-notification-escalation` | F5 / internal scheduler/worker | No browser EXECUTE; policy-version-pinned SLA evaluation; unique escalation step; recipient revalidation; no business-state mutation. | WORKER_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-070 | POQ-01 source-event audience snapshot helper | F3 internal helper, invoked only by reviewed source command wrapper | No PostgREST/browser EXECUTE; derives recipient and scope from database-authoritative event-time state; candidate rows and snapshot hash/count commit atomically with source event/outbox; client cannot supply recipient/role/scope. | INTERNAL_CALL_ONLY / ATOMIC_SNAPSHOT_OR_ROLLBACK | PLANNED / NOT EXECUTED |
| TC-FN-SEC-025-071 | CMD-052 notification fan-out worker | F5 / dedicated workload principal | No browser EXECUTE; worker reads only candidate rows for the currently claimed outbox under valid lease; cannot mutate candidate rows, widen audience, impersonate user or access unrelated outboxes. | WORKER_SCOPE_ONLY / BROWSER_DENIED | PLANNED / NOT EXECUTED |

**Execution gate:** 71 cases are PLANNED / NOT EXECUTED (54 operation-level cases for CMD-001..054, 15 global privilege-boundary cases and 2 notification snapshot/worker-boundary cases). T-18 execution-model selection is PO-approved as Option A. Exact function-level reviews, live role/ACL inventory and runtime evidence remain mandatory before any protected mutation RPC or grant is implemented. No SQL, grants, revokes, migrations, RLS changes or runtime tests were performed by this documentation update.

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
- TC-NOTIF-002: duplicate outbox processing creates one inbox row per recipient from the immutable event-time candidate audience; retries cannot add recipients outside that snapshot.
- TC-NOTIF-003: multiple selectors resolving the same user produce one recipient notification within the immutable event-time candidate audience; later selector/role changes cannot widen a retry.
- TC-NOTIF-004: role membership without matching assignment scope cannot receive or read scoped notification.
- TC-NOTIF-005: recipient A cannot list/read/mark-read recipient B's notification.
- TC-NOTIF-006: notification link does not bypass authorization on the referenced resource.
- TC-NOTIF-007: delivery state and read state remain independent under all transitions.
- TC-NOTIF-008: quiet hours suppress/defer only channels allowed by the pinned policy and correct time zone; they do not pause, stop or reset the SLA clock.
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

- TC-NOTIF-019: CMD-050 first set-once read transition emits exactly one notification.read audit event; duplicate/no-op acknowledgement emits no duplicate event.
- TC-NOTIF-020: concurrent CMD-051 publishes compare against expected_current_version_id; stale publication is rejected, version allocation is unique and published content remains immutable.
- TC-NOTIF-021: after CMD-052 lease expiry/reclaim, a stale worker generation cannot finalize or overwrite the current outbox result.
- TC-NOTIF-022: partial CMD-052 fan-out retry creates no duplicate recipient inbox or channel delivery rows and does not lose the accepted outbox intent.
- TC-NOTIF-023: INT-NOTIF-001 rejects invalid provider signature, stale callback timestamp, replayed provider event and unknown provider reference without changing delivery state.
- TC-NOTIF-024: provider callback applies only allowlisted monotonic delivery transitions and cannot change notification read_at or source business state.
- TC-NOTIF-025: CMD-054 uses one database UTC evaluation instant; caller-supplied evaluation_time is rejected and cannot manipulate due-ness.
- TC-NOTIF-026: ambiguous provider acceptance remains UNKNOWN until safe reconciliation; retry does not blindly duplicate a potentially accepted send.

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


## CMD-011–020 PO decision verification traceability — 2026-11-24

The following product semantics are approved; the referenced cases remain **PLANNED / NOT EXECUTED**. Extend the detailed case steps/fixtures before implementation so each semantic invariant has a positive, negative and concurrency case where applicable.

| Command / requirement | Required assertions | Existing case anchor | Execution |
|---|---|---|---|
| CMD-011 session creation | Server-selected DRAFT; project lifecycle gate; UTC/timezone conversion; DST gap/fold rejection; overlap permitted by default; immutable unique project/code | TC-CMD-CONTRACT-024-011 | PLANNED / NOT EXECUTED |
| CMD-012 session metadata | Code immutable; allowlist only; non-empty reason; schedule change rejected after dependent work; stale row version rejected once token contract approved | TC-CMD-CONTRACT-024-012 | PLANNED / NOT EXECUTED |
| CMD-013 session lifecycle | Exact T-07 state set; legal transitions; CLOSE_REQUESTED action/event only; Korlap scoped request/action limits; Super Admin final closure; CLOSED terminal; privileged audited reopen | TC-CMD-CONTRACT-024-013 | PLANNED / NOT EXECUTED |
| CMD-014 assignment publication | Atomic complete roster; server-selected published state; half-open interval boundary; eligibility overlap predicate; T-14 cap under concurrent writers | TC-CMD-CONTRACT-024-014 | PLANNED / NOT EXECUTED |
| CMD-015 membership changes | Per-member effective_at; reason required; end-date not delete; submitted inspection remains unchanged; active claim/workflow edge behavior explicitly tested after operational decision | TC-CMD-CONTRACT-024-015 | PLANNED / NOT EXECUTED |
| CMD-016 capacity | T-14 qualifying account predicate, default 50 and range 1–100; reject below count; no silent revocation; concurrent role/assignment/cap changes | TC-CMD-CONTRACT-024-016 | PLANNED / NOT EXECUTED |
| CMD-017 target plans | Session scope default; explicit action enum; uniqueness triple; duplicate and zero quantity rejected; published immutable/new version for correction | TC-CMD-CONTRACT-024-017 | PLANNED / NOT EXECUTED |
| CMD-018 instrument creation | Draft/inactive not selectable; normalization test vectors (NFKC, surrounding trim, case, internal whitespace/control); uniqueness; permitted alphabet pending security decision | TC-CMD-CONTRACT-024-018 | PLANNED / NOT EXECUTED |
| CMD-019 draft configuration | Atomic full replacement; omitted draft children removed only; published snapshot untouched; change summary required; executable/dynamic constructs and unbounded input rejected | TC-CMD-CONTRACT-024-019 | PLANNED / NOT EXECUTED |
| CMD-020 publication | Explicit instrument.publish; instrument.manage alone denied; server validation; immutable version/children; pinning; correction new version; same-key replay and distinct-key no-duplicate behavior | TC-CMD-CONTRACT-024-020 | PLANNED / NOT EXECUTED |

**QA boundary:** Product acceptance semantics are approved; test design completeness, security review, concurrency strategy, test fixtures, execution and evidence remain open. No test has been run by this documentation update.


## CMD-001–010 candidate lock/concurrency coverage — 2026-11-24

The concurrency expectations in TC-CMD-CONTRACT-024-001..009 have been aligned with CMD-001–010 Detailed Contract Review v0.3.4 §9. They remain **PLANNED / NOT EXECUTED**. The test design must use deterministic transaction barriers, assert final database invariants and typed loser outcomes, capture relevant SQLSTATE/lock diagnostics, and run against the exact approved schema and PostgreSQL major. This documentation update is not execution evidence and does not close LPR-10.

- TC-NOTIF-027: event-time candidate-audience snapshot is immutable across partial fan-out/retries; dispatch-time revalidation may suppress disabled/revoked/ineligible candidates but cannot add any recipient outside the snapshot.
- TC-NOTIF-028: quiet-hours delivery deferral does not pause, stop or reset the policy's SLA clock; initial-release ELAPSED_UTC due time is computed from the named server-UTC start event.
- TC-NOTIF-029: MVP exposes no dismiss/archive command, permission, browser write or UX action; any proposed dismissed_at field remains dormant.


## POQ-01..03 acceptance coverage — 2026-11-24

The Product Owner approved the audience, SLA and dismissal semantics on 2026-11-24. TC-NOTIF-027..029 add explicit acceptance cases for non-widening audience retries, quiet-hours/SLA independence and the absence of dismiss/archive in MVP. Later v0.4.1–0.4.2 add TC-NOTIF-030..040 for durable audience snapshots and adversarial lock-order races, TC-RLS-024-049 and TC-FN-SEC-025-070..071. All TC-NOTIF-001..040 and the related RLS/function-security cases remain PLANNED / NOT EXECUTED; no implementation or runtime behavior is proven by this catalogue update.


## 12. Candidate durable-object verification cases — CMD-035/036/038/039/040

**Status:** PLANNED / NOT EXECUTED. These cases are conditional specifications for candidate objects only. They must not be run until the corresponding objects are approved, admitted to the physical schema and RLS catalogue, implemented in an authorized G10 phase, and deployed to a controlled test environment. They do not imply the candidate objects exist.

| Test ID | Candidate boundary | Verification objective | Expected result | Status |
|---|---|---|---|---|
| TC-CANDIDATE-LEDGER-001 | CMD-035 sync_batch_operations | Same batch/operation ID and same canonical semantic hash replay | Return identical durable terminal result; no duplicate mutation or event | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-002 | CMD-035 sync_batch_operations | Same operation ID with different semantic hash | Reject IDEMPOTENCY_KEY_REUSED; preserve original result; no second mutation | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-003 | CMD-035 sync_batch_operations | Partial batch crash between operation commits and client acknowledgement | Every accepted operation has one durable terminal result; replay reconstructs exact batch outcome | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-004 | CMD-035 device binding | Revoked, rebound or wrong-owner device submits queued operation | Deny before mutation; no trust inferred from possession of device_id | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-005 | CMD-036 document generation | Worker lease expires and stale worker attempts finalization after a newer generation claims job | Stale finalizer rejected by owner/token-hash/generation/expiry fence; newer output remains authoritative | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-006 | CMD-036 template/source provenance | Source revision or template version changes after generation request | Artifact remains bound to exact immutable source/template versions and hashes; no silent substitution | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-007 | CMD-038 print batch manifest | Invalid/unresolvable item and lost acknowledgement | Immutable manifest and durable per-item rejection survive replay; requested item count is reconstructable | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-008 | CMD-038 print batch results | retry_failed_only after mixed success/failure | Only retryable failed items receive a new attempt; successful items are never duplicated | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-009 | CMD-039 attendance document version | Replacement upload races with verification of prior version | Both versions remain immutable; verification binds exact version/checksum; no replacement overwrites evidence | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-010 | CMD-040 attendance verification history | Concurrent VERIFIED and REJECTED decisions for same document version/round | One legal terminal decision wins under approved serialization; losing request receives typed conflict; history is append-only | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-011 | CMD-040 institutional SoD | Uploader attempts verification when policy requires separation | Deny with SOD_VIOLATION; expected behavior remains blocked until institution approves the SoD rule | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-012 | Candidate RLS/ACL | Browser attempts direct DML or cross-tenant reads on every candidate object | Deny; no browser direct mutation; only explicitly approved narrow read projections are visible | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-013 | CMD-036 worker identity | Renderer job invoked with user JWT, service_role impersonation or untrusted workload identity | Deny; only separately approved workload principal and exact EXECUTE ACL may claim/finalize jobs | PLANNED / NOT EXECUTED |
| TC-CANDIDATE-LEDGER-014 | Candidate permission boundary | sync.apply attempts device enrollment/revocation; document.generate attempts template publication | Deny; no implicit permission inheritance; dedicated command/permission must be approved first | PLANNED / NOT EXECUTED |

**Execution guard:** The 14 cases above are not part of the existing executed-test denominator and do not count as passing evidence. Allocate final test IDs and bind them to approved schemas, exact function signatures, database roles, RLS policies, fixtures and test evidence only after design admission. No tests were run as part of this documentation update.


## 13. CMD-041–044 physical read/export verification cases

**Status:** PLANNED / NOT EXECUTED. All cases below require approved contracts and a controlled G10 test environment. CMD-043 and CMD-044 cases requiring T-10 remain non-executable until institutional approval. No live audit data or production export is permitted.

| Test ID | Command | Scenario | Expected result | Status |
|---|---|---|---|---|
| TC-REPORT-ACTUAL-001 | CMD-041 | Assigned-location user requests project-wide actual aggregate including unauthorized locations | Scope predicate is applied before aggregation; unauthorized locations and their counts are not disclosed | PLANNED / NOT EXECUTED |
| TC-REPORT-ACTUAL-002 | CMD-041 | Reopened/revised inspection has multiple submission/approval/print events | Counts follow approved metric dictionary and distinct-resource key; no raw event double-counting | PLANNED / NOT EXECUTED |
| TC-REPORT-ACTUAL-003 | CMD-041 | Completed inspection has approval and final PDF but no Print Officer print action | Completed count excludes it; PDF open/download is not treated as print | PLANNED / NOT EXECUTED |
| TC-REPORT-ACTUAL-004 | CMD-041 | New events occur between cursor pages | Cursor watermark yields documented consistent/as-of behavior; no silent metric drift or duplicate/omitted resource | PLANNED / NOT EXECUTED |
| TC-REPORT-TARGET-001 | CMD-042 | New target plan version is published between cursor pages | Existing cursor remains pinned to original immutable published plan version | PLANNED / NOT EXECUTED |
| TC-REPORT-TARGET-002 | CMD-042 | Caller supplies draft, superseded or cross-project plan version | Denied or non-disclosing not-visible result; no draft/scope leakage | PLANNED / NOT EXECUTED |
| TC-REPORT-TARGET-003 | CMD-042 | Actual progress overlay is disabled or not approved | Response contains target allocations only; no actual values or implied actual completion | PLANNED / NOT EXECUTED |
| TC-AUDIT-READ-001 | CMD-043 | Reader has report.read but lacks audit.read or approved purpose | Denied without event/resource existence disclosure | PLANNED / NOT EXECUTED |
| TC-AUDIT-READ-002 | CMD-043 | Audit event contains unknown or sensitive metadata keys | Event-specific projection redacts/rejects unapproved fields; arbitrary metadata JSON is never returned | PLANNED / NOT EXECUTED |
| TC-AUDIT-READ-003 | CMD-043 | Successful audit search emits access event | Exactly one access event per request/correlation ID; access event does not recursively invoke CMD-043 | PLANNED / NOT EXECUTED |
| TC-AUDIT-READ-004 | CMD-043 | Access-event append fails | Behavior follows explicit T-10 fail-closed or durable-monitored policy; no silent suppression | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-001 | CMD-044 | T-10 is absent, incomplete or revoked | Export remains unavailable; no job, artifact, bucket write or signed URL is created | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-002 | CMD-044 | Same approved export idempotency key and same normalized filter hash is replayed | Same job/result is returned; no duplicate export artifact | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-003 | CMD-044 | Same idempotency key is reused with a different purpose/scope/filter hash | Reject key reuse; original request/job remains unchanged | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-004 | CMD-044 | Export worker lease expires and stale worker finalizes after a newer generation claims job | Stale finalizer rejected by lease fencing; no stale artifact becomes authoritative | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-005 | CMD-044 | Storage upload acknowledgement is uncertain or checksum differs | Reconciliation detects orphan/partial object; artifact not marked EXPORTED until checksum and manifest verify | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-006 | CMD-044 | User has audit.export but lacks separately approved artifact download authority | Download denied; no object key or signed URL disclosed | PLANNED / NOT EXECUTED |
| TC-AUDIT-EXPORT-007 | CMD-044 | Legal hold is applied while export is queued or before artifact disposition | Policy-defined hold blocks prohibited generation/disposition; decision is auditable and no retention bypass occurs | PLANNED / NOT EXECUTED |

**Execution guard:** 18 cases above are specification-only. CMD-043 execution requires T-10 reader-purpose-field/retention authority. CMD-044 execution requires complete T-10 approval plus approved schema, RLS, worker, Storage, encryption, download, retention and recovery controls. These cases are not passing evidence and do not change G9/G10.


## POQ-01 candidate audience snapshot verification — planned only

The following tests validate the approved event-time audience semantics against the candidate relation `notification_outbox_recipients`. They remain PLANNED / NOT EXECUTED; the relation is NOT ADMITTED and no runtime behavior is claimed.

| Test ID | Scenario | Expected result | Status |
|---|---|---|---|
| TC-NOTIF-030 | Source event creates notification outbox intent and candidate recipients | Candidate recipient/scope rows and canonical snapshot hash/count are committed atomically with the source event; incomplete snapshot cannot become claimable | PLANNED / NOT EXECUTED |
| TC-NOTIF-031 | Role or assignment membership changes after source event but before CMD-052 retry | Retry consumes only the persisted event-time candidate set; no current-state re-resolution and no recipient widening | PLANNED / NOT EXECUTED |
| TC-NOTIF-032 | Same recipient matches multiple policy selectors | One candidate row and one inbox notification per outbox/recipient; selector overlap cannot duplicate recipients or channel rows | PLANNED / NOT EXECUTED |
| TC-NOTIF-033 | Candidate scope tuple contains cross-project/session/location/assignment references or a mismatched scope hash | Composite integrity/transaction validation rejects the inconsistent candidate; no outbox is marked snapshot-complete | PLANNED / NOT EXECUTED |
| TC-NOTIF-034 | Account/channel consent is revoked after event-time snapshot but before external dispatch | Original candidate remains immutable; the affected channel is suppressed; no new recipient is added and no inbox/source business state is rewritten | PLANNED / NOT EXECUTED |
| TC-NOTIF-035 | Partial CMD-052 fan-out crashes after some inbox rows are materialized | Retry deterministically scans candidate rows missing inbox rows; unique keys prevent duplicates; outbox completes only when candidate and materialized counts reconcile | PLANNED / NOT EXECUTED |

### Candidate RLS case

| Test ID | Candidate object | Scenario | Expected result | Status |
|---|---|---|---|---|
| TC-RLS-024-049 | `notification_outbox_recipients` (NOT ADMITTED) | Anonymous/authenticated browser attempts SELECT/INSERT/UPDATE/DELETE; CMD-052 attempts cross-outbox read or stale-lease read | All browser access denied; worker read is restricted to the currently claimed outbox and valid lease; candidate rows remain immutable | PLANNED / NOT EXECUTED |

**Execution gate:** Engineering/Database/Security must first admit or replace the candidate physical representation, approve exact scope FKs/hash/count/transaction bounds, RLS/ACL and workload identity, and activate G10. No test may be reported PASS before reproducible staging evidence is attached.


The two new function-security cases are conditional on approval/admission of the candidate notification audience snapshot design and exact F3/F5 function identities. They are PLANNED / NOT EXECUTED and do not authorize function creation or grant changes.


## POQ-01 notification audience lock-order adversarial cases

These cases are mapped to LOCK-GRAPH-001 LG-41..LG-45. They are deterministic concurrency specifications only; all remain PLANNED / NOT EXECUTED. The candidate relation is NOT ADMITTED, and these cases cannot be run until the physical representation and transaction/lock protocol are approved.

| Test ID | Graph edge | Concurrent scenario | Required invariant / expected result | Status |
|---|---|---|---|---|
| TC-NOTIF-036 | LG-41 | Source event persists event-time audience while a grantor concurrently revokes a recipient role/scope grant | One serializable/locked winner is reflected in the immutable candidate snapshot; no mixed authorization state, audience widening or deadlock; exact typed outcome recorded | PLANNED / NOT EXECUTED |
| TC-NOTIF-037 | LG-42 | Source event snapshot races assignment-member end and project/session closure | Candidate scope is consistent with the approved event-time linearization point; no recipient is retained outside its authorized source scope; closure fence and snapshot path do not deadlock | PLANNED / NOT EXECUTED |
| TC-NOTIF-038 | LG-43 | CMD-052 claims outbox and materializes inbox rows while source-scope FK checks and project/session lifecycle writers run | No lower-rank-after-higher-rank acquisition; no duplicate inbox/delivery rows; stale or out-of-scope candidate cannot be materialized | PLANNED / NOT EXECUTED |
| TC-NOTIF-039 | LG-44 | CMD-054 scheduler tick snapshots escalation recipients while role/scope revocation and duplicate scheduler tick race | One unique escalation event and one immutable event-time candidate set; no re-resolution/widening; no deadlock or duplicate outbox | PLANNED / NOT EXECUTED |
| TC-NOTIF-040 | LG-45 | CMD-052 lease expires and is reclaimed while stale and current worker generations attempt fan-out finalization | Only current owner/token-hash/generation/expiry can finalize; immutable candidate rows unchanged; inbox creation remains idempotent | PLANNED / NOT EXECUTED |

**Evidence required when authorized:** exact migration/schema SHA, PostgreSQL major, deterministic transaction barriers, lock wait graph/deadlock diagnostics, SQLSTATE/typed outcomes, final invariant queries and test-runner evidence. Do not mark PASS from mocks or static reasoning.


## Source-event producer completeness and transaction-boundary case

| Test ID | Scope | Scenario | Expected result / invariant | Status |
|---|---|---|---|---|
| TC-NOTIF-041 | CMD-001..040 / LOCK-MANIFEST-001 §7.7 | Reconcile every enabled notification event type against one or more explicitly identified canonical source commands/finalizers (each event instance bound to exactly one producer transaction); exercise event cardinality for CMD-035 sync operations and CMD-036/038/039 finalizers | No enabled policy event type is orphaned or mapped only to a projection instead of its source fact; every event instance identifies its single producing command execution/finalizer; every source event, audit, outbox and immutable audience snapshot share the required transaction boundary; CMD-041..044 read-side events are excluded absent a separately approved access-event boundary; CMD-049..054 cannot recursively trigger notification fan-out by default | PLANNED / NOT EXECUTED |

**Evidence required:** approved policy event-type allowlist; producer/event crosswalk; transaction/finalizer sequence diagrams; source-event and outbox correlation keys; durable operation/finalizer idempotency; rollback/partial-failure evidence; recipient snapshot lock-set and FK-edge analysis. Static 40/40 producer mapping is documentation coverage only and is not a passing execution result.


## Recipient-resolver lock-set adversarial cases — 2026-11-24

**Design reference:** NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001 v0.1.2; LOCK-MANIFEST-001 §7.7–7.8; LOCK-GRAPH-001 §29.  
**Status:** All cases PLANNED / NOT EXECUTED. These are specification-only until the Product Owner approves event-time linearization and Engineering/Database/Security select and approve the resolver serialization mechanism. If the L05 guard is rejected, execute the equivalent assertions against the approved alternative. No candidate table, lock rank or mechanism is approved by these test definitions.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-042 | Source event races role grant, revoke or expiry while recipient selectors are evaluated | One approved serialization winner is reflected in the immutable candidate set; no mixed authorization state, audience widening or deadlock | PLANNED / NOT EXECUTED |
| TC-NOTIF-043 | Source event races account suspension, disablement or reactivation | Recipient eligibility follows the approved event-time linearization point; dispatch-time restrictions may suppress but never add candidates | PLANNED / NOT EXECUTED |
| TC-NOTIF-044 | Source event races scope grant, revoke, expiry or scope reassignment | Candidate recipient and scope tuple are internally consistent; no unauthorized scope reference or audience widening | PLANNED / NOT EXECUTED |
| TC-NOTIF-045 | Source event races assignment-member start, end or expiry | Candidate membership reflects the approved effective-time rule; assignment and membership locks follow the canonical order | PLANNED / NOT EXECUTED |
| TC-NOTIF-046 | Source event races project/session close or transition | Parent lifecycle fence and snapshot path serialize; no child event or notification intent commits after a rejected closure boundary | PLANNED / NOT EXECUTED |
| TC-NOTIF-047 | T-14 capacity change races notification recipient resolution | Capacity and recipient predicates use their approved shared serialization mechanism; no stale eligibility count or lock cycle | PLANNED / NOT EXECUTED |
| TC-NOTIF-048 | Two notification-eligible source commands have overlapping candidate audiences | Principal, grant and scope rows are acquired in deterministic order; both transactions complete or return a safe retry outcome; no duplicate candidate per outbox/recipient | PLANNED / NOT EXECUTED |
| TC-NOTIF-049 | CMD-052 fan-out races grant revocation and project/session closure after source snapshot | Fan-out consumes only immutable candidate rows; it does not re-resolve membership; FK behavior is safe; stale worker cannot finalize | PLANNED / NOT EXECUTED |
| TC-NOTIF-050 | CMD-054 duplicate scheduler ticks race CMD-051 policy publication and recipient revocation | Exactly one escalation event wins; pinned policy and event-time snapshot remain immutable; no lower-rank-after-higher-rank acquisition | PLANNED / NOT EXECUTED |
| TC-NOTIF-051 | Inject FK violation, unique conflict, deadlock or serialization failure during source snapshot transaction | Source mutation, event, audit, idempotency, outbox and snapshot roll back atomically; retry is bounded/idempotent; SQLSTATE and lock diagnostics are captured | PLANNED / NOT EXECUTED |
| TC-NOTIF-052 | Authenticated PostgREST RPC waits on L05 while an eligibility writer commits; wrapper volatility and internal SQL command boundaries are inspected | Wrapper is VOLATILE; lock and resolver are separate internal SQL commands; post-wait resolver sees the committed writer under READ COMMITTED; STABLE/combined-statement negative control is rejected | PLANNED / NOT EXECUTED |
| TC-NOTIF-053 | Source transaction waits across a role, assignment or policy effective-time boundary before acquiring L05 | One clock_timestamp instant is captured after L05; every effective predicate and immutable snapshot uses the same value; transaction-start timestamp is not used for eligibility | PLANNED / NOT EXECUTED |
| TC-NOTIF-054 | Mixed source-event and eligibility-writer workload at the PO/Operations-approved maximum audience cardinality | p50/p95/p99 L05 wait/hold/transaction latency, throughput, timeout/deadlock/retry rates, queue age, audience size and database I/O are measured and meet approved SLO; no partial audience, starvation or unbounded queue growth | PLANNED / NOT EXECUTED |

**Execution evidence required:** exact approved mechanism and lock-rank version; schema/FK/index/trigger/function SHA; PostgreSQL major/version; deterministic transaction barriers; SQLSTATE and lock-wait/deadlock diagnostics; final invariant queries; source-event/outbox/snapshot correlation; rollback and retry evidence. Mocks or static reasoning do not pass these cases. G10 activation and an authorized isolated PostgreSQL environment are prerequisites.


### Resolver test execution prerequisite — 2026-11-24

PO has selected candidate L05 as the primary mechanism for technical approval review. TC-NOTIF-042..054 remain PLANNED / NOT EXECUTED until Engineering/Database/Security approve the concrete primitive/key, transaction-scoped lifetime, writer participation, canonical order, timeout/retry and bounded contention profile. If L05 is rejected, the cases must be re-baselined against the approved alternative; do not test a mixed L05 + SERIALIZABLE design. This selection does not activate G10 or authorize database/runtime testing.


### NRL-T01..T13 execution controls — 2026-11-24

[NLA-L05-TDR-001 v0.1.3](../02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) defines the concurrency schedules and required outcomes for NRL-T01..T12, including VOLATILE wrapper snapshot behavior, post-lock time capture, a READ COMMITTED stale-snapshot control and `pg_locks` inspection. These tests remain PLANNED / NOT EXECUTED until G10 is activated, exact DDL/functions/grants and deployed isolation are approved, and an isolated PostgreSQL environment is available. Do not claim runtime or concurrency certification from this document.


### L05 review response — snapshot and time linearization cases — 2026-11-24

TC-NOTIF-052 and TC-NOTIF-053 extend the planned QA set for F-01/F-02 from L05-REVIEW-001. Both are specification-only and PLANNED / NOT EXECUTED. They require the final approved wrapper/function definitions, exact PostgREST caller-JWT execution path, deployed READ COMMITTED evidence and an isolated PostgreSQL environment after G10 activation. No runtime result is implied.


### L05 transition-semantics and contention evidence — 2026-11-24

TC-NOTIF-054 specifies the mixed-load benchmark for the global audience guard. It remains PLANNED / NOT EXECUTED until PO/Operations approve audience/workload limits and numeric SLOs, Engineering/Database approve the final lock design, and G10 activates an isolated PostgreSQL test environment. Pre-/post-transition recipient outcomes remain PO decision inputs and must be added as explicit assertions before these tests can pass.


### F-05 approved transition-semantics acceptance cases — POQ-04 (2026-11-24)

The following cases translate the PO-approved matrix into explicit assertions. They remain PLANNED / NOT EXECUTED; this catalog update is not evidence of runtime behavior.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-055 | Role revoke races source-event audience resolution; target and actor are separately selected/not selected by policy | Candidate snapshot reflects pre-revoke serialized state and exact selector only; no implicit actor/target append; post-commit current-scope revalidation suppresses revoked target when required; no widening | PLANNED / NOT EXECUTED |
| TC-NOTIF-056 | Account is rejected/disabled/suspended after event-time snapshot; later reactivated before retry | Original candidate snapshot remains unchanged; send is suppressed while account is not enabled; later retry may send only to the same original candidate after reactivation and all current checks; no candidate is added | PLANNED / NOT EXECUTED |
| TC-NOTIF-057 | Assignment member ends concurrently with source event | Snapshot uses the serialized pre-end membership at one captured instant; after end, current-scope revalidation may suppress that candidate; no substitute member is added | PLANNED / NOT EXECUTED |
| TC-NOTIF-058 | Project/session closes concurrently with source event | Snapshot is evaluated against pre-close parent state and commits atomically with the closure event; dispatch applies approved current active-scope rule; no post-close recipient is added | PLANNED / NOT EXECUTED |
| TC-NOTIF-059 | Actor revokes own role while an event policy may or may not select actor | Actor appears only if exact selector selects actor under pre-revoke eligibility; post-revoke current-scope check may suppress delivery; no implicit inclusion/exclusion or audience widening | PLANNED / NOT EXECUTED |

**Execution control:** POQ-04 approval is satisfied. TC-NOTIF-055..059 still require finalized selector grammar and dispatch-suppression semantics validated by Security/Engineering, approved technical design, G10 activation and an authorized isolated PostgreSQL environment. They remain specification-only and PLANNED / NOT EXECUTED.



### POQ-04 approval synchronization — 2026-11-24

POQ-04 is PO APPROVED in full. TC-NOTIF-055..059 now trace to approved product semantics; all five remain PLANNED / NOT EXECUTED pending Security/Engineering validation, final technical design, G10 activation and authorized isolated PostgreSQL execution. No test result is implied.


### F-05 technical validation cases — selector, dispatch, retry and audit (2026-11-24)

These cases supplement TC-NOTIF-055..059. They are derived from the PO-approved POQ-04 semantics but require the F05-T1..T5 technical definitions and Security/Engineering approval before execution. All remain PLANNED / NOT EXECUTED.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-060 | Publish or evaluate a policy with malformed, unknown, unbounded or unauthorized selector fields/operators | Selector validation fails closed; no event snapshot is created from an unapproved selector; policy version and rejection outcome are auditable; registered selector dependencies are exact | PLANNED / NOT EXECUTED |
| TC-NOTIF-061 | Actor, target and affected member overlap across multiple selectors; include negative controls where a participant is not selected | Only principals selected by the exact event selector appear; no implicit participant append; one canonical candidate per recipient/scope; ordering/canonicalization is deterministic | PLANNED / NOT EXECUTED |
| TC-NOTIF-062 | Project/session closure event is dispatched after parent becomes closed | Dispatch follows the explicitly approved event-specific closure-notice rule; no blanket active-parent predicate silently suppresses all intended recipients; no new recipient is added and resource access remains independently authorized | PLANNED / NOT EXECUTED |
| TC-NOTIF-063 | Candidate is suppressed for account status, then account is reactivated; vary consent, channel, role/scope and re-suspension before retry | Retry may consider only the original immutable candidate; every mandatory current check is re-evaluated; reactivation cannot clear unrelated suppression, rebuild snapshot or reset checkpoint; bounded retry/state outcome is deterministic | PLANNED / NOT EXECUTED |
| TC-NOTIF-064 | Multiple suppression/retry attempts occur, including terminal and retryable reasons | Each outcome is append-only, correlated to source event/outbox/candidate/policy/attempt, uses an approved reason code, records worker identity/time, excludes unnecessary sensitive payload and cannot rewrite candidate membership | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-060..064 require the approved selector grammar, event-specific dispatch matrix, suppression reason/state catalog, audit schema and F05-T1..T5 sign-offs. Runtime execution additionally requires G10 activation and the authorized isolated PostgreSQL environment. No test result is implied.


### F-05 selector grammar and event-specific dispatch profile tests — 2026-11-24

These acceptance cases target TDR v0.1.8 §4.2.5–4.2.6. They remain PLANNED / NOT EXECUTED; the grammar and dispatch profile are review candidates, not approved runtime contracts.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-065 | Validate grammar v1 with each permitted clause kind and canonical ordering | ROLE_SCOPE and EVENT_PARTICIPANT are the only accepted clause kinds; canonicalization is deterministic; duplicate clauses collapse without changing the selected principal/scope set | PLANNED / NOT EXECUTED |
| TC-NOTIF-066 | Submit nested logic, NOT, wildcard, arbitrary JSON path, SQL/expression text, client principal/scope IDs, unknown keys, duplicate keys, unknown version or more than eight clauses | Policy publication fails closed; no policy version becomes effective; sanitized rejection is auditable | PLANNED / NOT EXECUTED |
| TC-NOTIF-067 | Evaluate actor/target/affected-member bindings with missing, ambiguous or untrusted event fields | Publication rejects an incomplete registry mapping; no caller-supplied identity is accepted; source transaction cannot create a partial outbox/snapshot | PLANNED / NOT EXECUTED |
| TC-NOTIF-068 | Event token is composite, conditional, unknown, prefix-matched or absent from the exact event registry | No wildcard/prefix fallback; ambiguous composite token is not enabled; transaction fails atomically without a partial candidate snapshot | PLANNED / NOT EXECUTED |
| TC-NOTIF-069 | Role-revocation, assignment-member-end and project/session-close dispatch | Each pinned dispatch profile follows its transition-specific rule; no blanket revoked-role/current-membership/active-parent predicate suppresses the notice; opening source resource still requires independent authorization | PLANNED / NOT EXECUTED |
| TC-NOTIF-070 | Multiple matching clauses select same recipient with overlapping/different authorized scopes | One canonical recipient candidate is produced; only scopes explicitly selected by matching clauses are retained; deduplication and scope serialization are deterministic and cannot widen authorization | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-065..070 require PO/Security/Engineering approval of grammar v1, event registry, dispatch profiles and canonical candidate/scope serialization. Runtime execution requires G10 activation and the authorized isolated PostgreSQL environment. No test result is implied.


### PRD scope and notification-domain guard test — 2026-11-24

This case verifies that notification policy cannot introduce application personas or recipient roles that are absent from the approved PRD/permission registry. It is PLANNED / NOT EXECUTED and does not approve the still-unapproved role/grant matrix.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-071 | Attempt to publish a notification policy that targets an unregistered institutional persona (for example, a school principal/Kepala Sekolah), teacher, student, parent or school-customer persona, or relies only on institutional affiliation rather than an approved application principal and scoped assignment | Policy publication fails closed; no recipient or event is enabled; no role, permission, scope or audience is inferred from institution metadata; rejection is auditable. Only principals and scope mappings explicitly admitted by the approved PRD/permission registry and exact event policy can be selected | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-071 requires an approved canonical principal/role registry, PO-approved event allowlist and Security/Engineering-approved policy validation. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Product allowlist and event-triage guard — 2026-11-24

This case validates that a producer event declaration does not become a notification trigger merely by existing in the CMD catalogue or candidate triage. It remains PLANNED / NOT EXECUTED.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-072 | Attempt to publish a notification policy for an event absent from the explicit PO-approved event allowlist, including an operational/control event, unresolved composite token, generic command token, or a triage-only PO discussion candidate | Publication fails closed; no outbox notification is created and no recipient is resolved. Only an exact canonical event token with explicit PO approval, complete participant/scope mapping, approved dispatch profile and technical sign-offs can be enabled. Triage classification alone never enables an event | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-072 requires the exact PO-approved event allowlist and complete technical registry. Runtime execution requires G10 activation and the authorized isolated environment. No test result is implied.


### PO-approved event candidate registry admission guards — 2026-11-24

These tests are planned controls for the eleven PO-approved specification candidates. They do not imply event enablement or technical approval.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-073 | Attempt to publish any of the eleven PO-approved candidate tokens before exact source contract, trusted participant mapping, selector dependency, dispatch profile, deduplication and required Security/Engineering/Database approvals are complete | Publication fails closed; PO approval for specification/review is not treated as publication authorization; all unresolved rows remain NOT ENABLED | PLANNED / NOT EXECUTED |
| TC-NOTIF-074 | Attempt to publish an event outside the eleven approved candidate intents, including deferred `account.requested`, `session.close_requested`, or related `inspection_revision.created` as a second notification | Publication fails closed unless a separate explicit PO decision and complete technical admission record exists; no implied event, recipient or channel is created | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-073/074 require exact canonical registry contracts and Security/Engineering/Database sign-offs. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Account outcome event candidate safety — 2026-11-24

These cases guard the unresolved mapping between account event-time candidate selection and dispatch-time account eligibility, and the account decision race/dedup boundary. They remain planned; they do not approve the event or execute a test.

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-075 | Attempt to admit `account.approved` or `account.rejected` while the exact pre-transition participant selector and dispatch-time enabled-account suppression predicates are not separately specified | Technical admission/publication fails closed; a pending applicant is not silently excluded by reusing a dispatch gate as a snapshot gate, and no recipient is inferred from a command field without an approved event projection | PLANNED / NOT EXECUTED |
| TC-NOTIF-076 | Race CMD-002 approval against CMD-003 rejection and replay either command with the same or conflicting idempotency key | At most one terminal account decision and its canonical source event commit; replay does not create a second decision/event/outbox/snapshot; conflicting payload or terminal state is rejected; audit failure rolls back the atomic source transaction | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-075/076 require the approved account state machine, event/participant contract, decision uniqueness/CAS and source transaction proof. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Role revocation event candidate safety — 2026-11-24

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-077 | CMD-005 revokes a role selected by a notification policy, including a self-revoke attempt | Event-time candidate set is evaluated against pre-revoke state; target or actor is included only if the exact selector independently selects them; actor/target is never auto-appended; post-commit current role/scope revalidation may suppress but cannot widen or rewrite the snapshot | PLANNED / NOT EXECUTED |
| TC-NOTIF-078 | Concurrent role grant/revoke, duplicate revoke replay, stale expected_version, and revoke of an already expired/revoked grant | At most one valid role transition and canonical `role.revoked` event commit; replay/no-op does not create duplicate event/outbox/snapshot; stale version is rejected only when backed by an approved physical CAS token; L05/L10 serialization covers all qualifying Inspector writers | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-077/078 require the approved role lifecycle, exact target participant mapping, selector/dispatch profile, physical version strategy, last-admin/SoD policy and complete L05/L10 writer proof. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Project/session closure event candidate safety — 2026-11-24

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-079 | CMD-013 emits `session.close_requested` and later performs the final CLOSED transition | `session.close_requested` never matches NREG-005; only the exact final committed `session.closed` event can be considered, with one final transition identity and no duplicate notice on request/replay | PLANNED / NOT EXECUTED |
| TC-NOTIF-080 | CMD-010 project closure or CMD-013 final session closure resolves an audience and dispatches after the parent is closed | Candidate snapshot is evaluated against pre-close state and commits atomically with the final closure event; event-specific dispatch may suppress only under the approved rule, never by an accidental universal active-parent predicate; no recipient is added or substituted | PLANNED / NOT EXECUTED |
| TC-NOTIF-081 | Project/session closure races with child creation, assignment/member changes, inspection/evidence/document finalization or duplicate closure requests | Every child writer is serialized by the approved parent-fence protocol; one terminal close and one event/snapshot commit; no child mutation slips past closure; stale version and audit failure fail closed | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-079..081 require approved closure state machines, exact event tokens, trusted participant mapping, event-specific dispatch profile, physical version/CAS, complete child-writer inventory and compatible parent-fence lock proof. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Assignment event candidate safety — 2026-11-24

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-082 | CMD-014 creates an assignment with a complete initial roster; attempt to select newly inserted members through a pre-mutation event-time selector | Publication/admission fails closed until the trusted event-participant projection explicitly defines new-member selection consistent with POQ-01/04; no client-supplied member ID is trusted and no inserted member is implicitly appended | PLANNED / NOT EXECUTED |
| TC-NOTIF-083 | CMD-015 adds, ends and retains members in one atomic change; event policy attempts to select each category | Exact added/ended/retained semantics are enforced; ended members are evaluated against pre-end membership at one captured instant; dispatch may suppress but never widen or substitute; retained-member inclusion is not inferred | PLANNED / NOT EXECUTED |
| TC-NOTIF-084 | CMD-015 ends a member who owns an active claim or in-progress inspection | The approved operational rule (block, future-effective end or grandfathered work) is applied; no silent reassignment/deletion occurs; no event is enabled while the active-work policy is unresolved | PLANNED / NOT EXECUTED |
| TC-NOTIF-085 | Concurrent CMD-014/015 membership changes, CMD-004/005 role eligibility changes and CMD-016 capacity updates; duplicate command replay | One shared approved T-14/L05 serialization protocol preserves the distinct enabled-Inspector cap; command/event/snapshot is atomic and idempotent; no partial roster/member change or duplicate notification is produced | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-082..085 require approved event/participant contract, member-delta semantics, active-work policy, physical membership constraints and complete L05/L10 writer/lock proof. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### Inspection submission/return event candidate safety — 2026-11-24

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-086 | CMD-029 emits both `inspection.submitted` and `inspection_revision.created` for one submitted revision | Only the exact approved `inspection.submitted` candidate can trigger one user notice; revision-created remains a related provenance fact and cannot create a second notice; replay does not create a new revision or candidate snapshot | PLANNED / NOT EXECUTED |
| TC-NOTIF-087 | Resolve a Reviewer for a submitted inspection when no approved physical reviewer-assignment source is configured, or when only Super Admin/project membership/generic role labels exist | Registry admission/publication fails closed; no Reviewer is inferred from title, global role or generic membership; exact inspection/project/session/assignment scope is required | PLANNED / NOT EXECUTED |
| TC-NOTIF-088 | CMD-030 returns a submitted revision; attempt to notify the revision author, current assignment Inspector, another member or the reviewer | Only the exact approved responsible-Inspector participant mapping may be selected; reviewer != author SoD is enforced; no author/current-member equivalence or recipient substitution is assumed | PLANNED / NOT EXECUTED |
| TC-NOTIF-089 | Concurrent approve vs return, duplicate return replay, stale revision, and audit failure for the same submitted revision | Exactly one terminal review decision commits per revision; event, audit, idempotency and any admitted outbox/snapshot are atomic; duplicate decision creates no second event/notice; submitted revision/evidence remain immutable | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-086..089 require approved event cardinality, physical Reviewer assignment, responsible-Inspector mapping, review-round/decision uniqueness, SoD and canonical lock graph. Runtime execution requires G10 activation and an authorized isolated environment. No test result is implied.


### CMD-031/032 approval and reopen event candidate safety — 2026-11-24

| Test ID | Scenario | Expected result / invariant | Status |
|---|---|---|---|
| TC-NOTIF-090 | CMD-031 approval references a revision that is not the exact current submitted immutable revision, or the supplied revision/inspection pair does not match | Reject without event/outbox/snapshot; no revision or evidence mutation; no notice candidate is created | PLANNED / NOT EXECUTED |
| TC-NOTIF-091 | CMD-031 attempts approval with no persisted Reviewer assignment, generic role/project membership only, wrong scope, inactive grant, or reviewer equal to revision author | Fail closed; no Reviewer or responsible Inspector is inferred; reviewer != author SoD and exact assignment scope are enforced | PLANNED / NOT EXECUTED |
| TC-NOTIF-092 | CMD-030 return races CMD-031 approval, two approvals race, or stale revision races a terminal decision | Exactly one legal terminal decision commits for the exact revision; inspection transition, review event, audit, idempotency and any admitted outbox/snapshot are atomic | PLANNED / NOT EXECUTED |
| TC-NOTIF-093 | CMD-032 reopen is attempted by generic Super Admin without explicit approved reopen grant, with wrong scope, inactive grant, missing reason or mismatched approved revision | Fail closed; no reopen event, candidate snapshot or draft context is created; authority is never inferred from role label | PLANNED / NOT EXECUTED |
| TC-NOTIF-094 | Concurrent CMD-032 reopen requests, or reopen races active claim/evidence/document finalization; prior approved revision has evidence/documents/print history | At most one active draft context exists once its model is approved; immutable approved revision and all historical artifacts remain unchanged; blockers serialize without lock inversion; one immutable event-time candidate snapshot is committed atomically | PLANNED / NOT EXECUTED |

**Execution control:** TC-NOTIF-090..094 are specification-only. They require the physical Reviewer assignment and review-decision uniqueness model, approved reopen grant/SoD matrix, mutable draft representation, complete active-work/finalizer writer inventory, admitted source-event/outbox/snapshot identity and certified global lock protocol. Runtime execution requires verified G9, separate G10 activation and an authorized isolated environment. No test was executed.

## Inspection draft-context and immutable revision lifecycle — 2026-11-24

**Design source:** INSPECTION-DRAFT-001 v0.1.0.  
**Status:** PLANNED / NOT EXECUTED. These cases are based on a candidate technical design; they do not approve its schema or authorize implementation.

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-INS-DRAFT-001 | Claim a new IFP unit online | Exactly one inspection and one active draft context are created with the pinned IFP version |
| TC-INS-DRAFT-002 | Claim a new Standing Bracket unit | Exactly one inspection and one active context are created with the pinned Standing Bracket version; no instrument crossover |
| TC-INS-DRAFT-003 | Concurrent claim of one canonical unit from two assignments/projects | One active claim and one inspection lifecycle only |
| TC-INS-DRAFT-004 | Save partial checklist/specification draft | Strict typed patch updates only the active context; inspection row_version advances once for a semantic change |
| TC-INS-DRAFT-005 | Continue offline after online claim | Only the already-claimed draft can be edited offline; no offline claim/submit/review/reopen |
| TC-INS-DRAFT-006 | Replay a synchronized draft operation | Idempotent result; no duplicate response or evidence mutation |
| TC-INS-DRAFT-007 | Sync conflicts with newer server draft | Both versions are preserved; explicit conflict; no last-write-wins |
| TC-INS-DRAFT-008 | Submit with missing required applicable answer/evidence or unresolved sync conflict | Submission rejected; active draft remains editable; no immutable revision is created |
| TC-INS-DRAFT-009 | Successful submit | One immutable revision, canonical snapshot/hash, normalized response rows, evidence binding, events, audit and idempotency result commit atomically |
| TC-INS-DRAFT-010 | Reviewer returns a submitted revision with reason | Submitted revision remains unchanged; one new active correction context is created from the exact returned revision |
| TC-INS-DRAFT-011 | Inspector corrects and resubmits | New immutable revision number; prior revision and return decision remain unchanged |
| TC-INS-DRAFT-012 | Reviewer self-review | Denied when authenticated Reviewer equals the exact immutable revision author |
| TC-INS-DRAFT-013 | Concurrent approve versus return on one revision | Exactly one terminal review decision commits |
| TC-INS-DRAFT-014 | Authorized reopen of exact approved revision with reason | One new active reopen context; approved revision and all historical artifacts remain unchanged |
| TC-INS-DRAFT-015 | Concurrent reopen with distinct idempotency keys | One context and one reopen event; other request receives a typed state conflict |
| TC-INS-DRAFT-016 | Reopen races with document generation or print finalization | Deterministic serialization/blocker; no approved artifact is rewritten |
| TC-INS-DRAFT-017 | Save with stale inspection row_version | STALE_VERSION; no draft answer or evidence metadata is lost |
| TC-INS-DRAFT-018 | Evidence intent/finalization uses wrong draft context or instrument slot | Denied; evidence cannot cross inspection, assignment or instrument version |
| TC-INS-DRAFT-019 | Browser attempts direct DML on draft payload, response rows or immutable revisions | Denied by database ACL/RLS; mutation only through approved command boundary |
| TC-INS-DRAFT-020 | Required audit append fails during submit, return or reopen | Full transaction rollback; no partial lifecycle transition, context or revision remains |

The evidence carry-forward decision across revisions, next Inspector/claim owner after return/reopen, claim release/resume/reassignment semantics, final state vocabulary, physical uniqueness/FK strategy, RLS/ACL and lock graph remain open. These cases must be refined after those decisions are approved. All 20 cases are PLANNED / NOT EXECUTED.


## SES-001 session-bound inspection and abort verification — 2026-11-24

**Authority:** PO-approved SES-001. **Status:** PLANNED / NOT EXECUTED. These cases verify approved product semantics only; physical schema, command contracts and implementation remain unapproved.

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-INS-DRAFT-021 | Attempt to claim or create an inspection attempt under a closed, inactive or out-of-scope session | Denied; no inspection, draft context, claim or evidence intent is created |
| TC-INS-DRAFT-022 | Attempt to resume an ACTIVE draft, claim or evidence workflow from a different session | Denied; original session_id remains immutable; no data is copied or mutated |
| TC-INS-DRAFT-023 | Session close requested while a unit attempt remains incomplete or a returned correction remains unresolved | Final session close is blocked until that unit attempt is explicitly aborted or reaches an allowed terminal outcome |
| TC-INS-DRAFT-024 | Abort an incomplete unit attempt at session end, including retry with same idempotency key | One terminal ABORTED outcome; active draft is sealed against writes; claim is released; audit/event/idempotency commit atomically; retries do not duplicate effects |
| TC-INS-DRAFT-025 | Abort fails during audit/event/claim-release write or races with submit/evidence finalization/session close | Entire abort transaction rolls back or one legal serialized outcome wins; no partially aborted attempt or falsely closed session |
| TC-INS-DRAFT-026 | Start inspection of the same canonical unit in a later session after prior attempt was ABORTED | A new inspection attempt is created with the new session_id; old attempt, revisions and evidence remain immutable; old evidence is not automatically reused |

Returned correction and authorized reopen must additionally remain within the original session and, for correction, the original Inspector. All cases remain PLANNED / NOT EXECUTED.


## SES-001 / WF-003 — CMD-013 close gate and CMD-027 non-abort verification (2026-11-24)

**Status:** PLANNED / NOT EXECUTED. All cases require approved command contracts, physical schema/RLS, G10 activation and a controlled test environment.

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-SESSION-002 | CMD-013 FINAL_CLOSE while any unit attempt in the session has an active claim, active draft, pending review, evidence finalization or other unresolved work | `CLOSURE_BLOCKED`; session remains ACTIVE/PAUSED as applicable; no session.closed event, partial abort, claim release or history mutation |
| TC-SESSION-003 | Unit attempt is explicitly aborted with reason, then Super Admin retries FINAL_CLOSE | Abort is a terminal auditable non-completion; claim is no longer active; immutable revisions/evidence remain; final close succeeds only when every other closure gate is satisfied |
| TC-SESSION-004 | CMD-027 release-unit-claim is called on an incomplete draft before FINAL_CLOSE | Claim becomes RELEASED while draft remains preserved; inspection attempt is still unresolved; CMD-013 remains CLOSURE_BLOCKED until a separate approved abort/completion outcome exists |
| TC-SESSION-005 | FINAL_CLOSE races an abort, submit, evidence finalization, review decision or document/print finalizer | One deterministic serialized outcome; either child work commits before close and is included in blocker evaluation, or close wins and stale child operation is rejected; no work commits after CLOSED |
| TC-SESSION-006 | Session closes with one or more ABORTED unit attempts and all other required work complete | Session reaches CLOSED; aborted units remain visible as non-completion and are excluded from inspected/approved/good/defective/printed counts; no evidence or revision is fabricated |
| TC-SESSION-007 | Abort transaction fails at claim release, inspection/draft state, audit or idempotency write | Full abort rollback; unit remains unresolved; session cannot close; retry with same idempotency key yields one outcome |

These cases extend TC-SESSION-001 and TC-INS-DRAFT-021..026. They do not establish that CMD-027 is an abort command; TC-SESSION-004 explicitly protects the current release-only semantics.
