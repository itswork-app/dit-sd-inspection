# CMD-011–020 Detailed Contract Review

**Status:** PO product semantics APPROVED (2026-11-24); Engineering/Security contract review OPEN; NOT approved for implementation  
**Version:** 0.3.9  
**Date:** 2026-11-24  
**Scope:** CMD-011 through CMD-020  
**Controls:** T-14 Inspector capacity; T-15 append-only audit direction; T-17 instrument governance; T-18 Option A command boundary; G9 NOT READY; G10 NOT ACTIVE.

## 1. Purpose, authority and source hierarchy

This document expands the canonical PostgreSQL Command Contract Catalogue for CMD-011–020. It is a documentation-only engineering review. It does not authorize source changes, SQL, migrations, PostgreSQL functions, grants/revokes, RLS changes, live database changes, deployment, or merge.

Source-of-truth hierarchy for this review:

1. PostgreSQL Command Contract Catalogue — stable logical command IDs, proposed permission codes, command intent and test-series references.
2. Canonical Permission Registry and Command Authorization Matrix — permission semantics and scope classes; still draft and not approved for role seeding.
3. Physical Database Schema and Integrity Specification plus Data Model/ERD — proposed physical entities and constraints; not proof of live schema.
4. Table-by-Table RLS Policy Catalogue and Physical Schema ↔ RLS ↔ Command Reconciliation — proposed table access posture; not proof of deployed RLS or grants.
5. Audit Event Catalogue and Governance — proposed event vocabulary and append-only requirements.
6. T-14, T-17 and T-18 decisions — approved Product Owner constraints, without implying implementation readiness.

Where sources conflict or omit a required field, this review records a gap. It does not silently add a physical column, state, permission grant, route, RPC, or institutional rule.

## 2. Shared command boundary and contract envelope

### 2.1 Transport and identity

- Candidate transport: \`POST /api/commands/{logical-command-name}\`. Exact route names, API version and OpenAPI definitions remain provisional.
- Candidate RPC convention: \`public.cmd_<logical_command_name>_v1(...)\`. No candidate function is asserted to exist or approved for creation.
- Browser/PWA → Vercel server route → PostgreSQL command function, forwarding the authenticated caller JWT, is the PO-approved T-18 Option A flow.
- The route validates method, content type, body size, schema version, allowlisted fields and Supabase session. It must not replace the caller JWT with a service-role identity for user-initiated commands.
- PostgreSQL derives actor identity from \`auth.uid()\`, resolves exactly one approved/enabled \`app_users\` identity and evaluates permission, scope, resource state, validity and SoD inside the mutation transaction.
- Client-supplied actor ID, role, permission, project authority, approval state, published state or effective scope is never authoritative.
- Browser roles receive no direct INSERT/UPDATE/DELETE on protected business/governance tables. RLS remains an independent read boundary.
- Protected writes follow PO-approved T-18 Option A through narrow SECURITY DEFINER wrappers. Each function requires individual security approval, a dedicated least-privileged NOLOGIN owner, fixed empty search_path, schema-qualified references, PUBLIC/anon denial and exact-signature EXECUTE grants. SECURITY INVOKER remains preferred for scoped reads and non-elevated helpers.
- Actual function owner, security mode, search_path, role grants and EXECUTE ACL have not been verified against the live database.

### 2.2 Proposed common request envelope

The command-specific schemas below are allowlists. The following envelope fields are proposed consistently where the command is a mutation:

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {}
}
\`\`\`

The actor and trusted authorization context are derived server-side and are not accepted in payload. `expected_row_version` is the proposed aggregate compare-and-swap field; it is not implementable until the physical token and increment semantics are approved.

### 2.3 Proposed common response envelope

\`\`\`json
{
  "command_id": "uuid",
  "status": "accepted",
  "resource_id": "uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {},
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

Typed outcomes are command-specific and must be stable machine-readable values. Do not return resource existence or sensitive metadata to unauthorized callers.

### 2.4 Idempotency, audit and failures

- Scope: authenticated actor + command type + resource scope + opaque idempotency key.
- Hash canonical schema version and normalized semantic payload; ignore transport-only metadata.
- Same key + same hash returns the original final result after current authorization is re-evaluated. Same key + different hash returns \`IDEMPOTENCY_KEY_REUSED\`.
- Concurrent same-key calls must produce one logical execution through atomic idempotency arbitration and a unique constraint.
- Idempotency record, domain mutation and required audit event commit or roll back atomically.
- Audit append failure aborts the domain mutation and suppresses success.
- Use database/server time for effective dates and state decisions. Client timestamps cannot determine authorization or eligibility.
- Exact idempotency retention remains an open policy decision and must exceed the approved maximum retry/offline window.

### 2.5 Lock order and transaction policy

Follow the documented global lock order: idempotency arbitration → project capacity row when relevant → project/session/assignment rows in deterministic UUID order → instrument/version rows where applicable → affected child rows in deterministic key order → append-only domain/audit event inserts.

Do not hold database locks during Storage transfers, PDF rendering or external network calls. Lock only rows needed for the command invariant. A multi-resource mutation must sort lock acquisition deterministically and roll back as one unit unless the contract explicitly describes a durable partial-result workflow.

### 2.6 Shared verification minimum

For each command, allocate concrete test IDs beyond the reserved catalogue reference and cover:

1. Authorized positive case and exact persisted state.
2. Unauthenticated, inactive/pending account, missing permission, wrong project/session scope and SoD negative cases.
3. Forged actor/role/scope/status/published fields.
4. Malformed, unknown, missing, boundary and oversized payload values.
5. Same-key/same-payload replay and same-key/different-payload rejection.
6. Concurrent conflicting calls and lock-order/deadlock behavior.
7. Required audit append failure rollback.
8. Direct browser DML denial and exact function EXECUTE ACL.
9. Cross-project/cross-session/cross-instrument reference substitution.
10. Published/immutable resource mutation denial where relevant.

These are test specifications, not executed tests.

## 3. Detailed command contracts

## CMD-011 — create-session

**Permission:** \`session.manage\`  
**Scope:** Global Super Admin authority plus explicit project scope, as defined by the permission matrix.  
**Candidate route:** \`POST /api/commands/create-session\`  
**Candidate RPC:** \`public.cmd_create_session_v1\`  
Names are provisional and must be checked against actual deployed inventory before adoption.

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "project_id": "uuid",
    "code": "SESSION-2027-01",
    "starts_at": "2027-01-01T00:00:00Z",
    "ends_at": "2027-01-31T23:59:59Z"
  }
}
\`\`\`

No initial status, actor, project scope, location, team, assignment or approval field is accepted. The server selects the T-07 initial state `DRAFT`; `PLANNED` is not a valid session state.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "created",
  "resource_id": "session-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "project_id": "project-uuid",
    "code": "SESSION-2027-01",
    "starts_at": "UTC timestamp",
    "ends_at": "UTC timestamp",
    "status": "server-selected-initial-state"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, validation and SoD

- Caller must resolve to an approved, enabled Super Admin identity with \`session.manage\` and effective authority for the target project.
- Verify project exists, is in a state that permits session creation, and is within caller's effective project scope.
- Normalize code according to a documented canonical rule; enforce uniqueness within project.
- Require valid timestamps and \`starts_at < ends_at\`; reject invalid/ambiguous temporal input.
- Timezone handling is a schema gap: physical \`sessions\` lists \`starts_at\` and \`ends_at\`, while \`timezone?\` appears in the command catalogue and \`projects\` owns an IANA timezone. Confirm whether session time is stored as UTC instants interpreted under \`projects.timezone\`, or whether a session-level timezone field is required.
- Do not allow caller to create a session directly in ACTIVE/CLOSED or another lifecycle state.

### Physical read/write set

- Read: \`projects\`; \`sessions\` for duplicate code and lifecycle checks; \`idempotency_records\`.
- Write: \`sessions\`; \`idempotency_records\`; \`audit_events\`.
- Physical schema documents \`sessions(id, project_id, code, status, starts_at, ends_at)\`, unique \`(project_id, code)\`, and valid interval.
- No session-level `row_version` is specified in the physical schema. The API token proposal is `expected_row_version`; physical approval remains open.

### Transaction, lock and idempotency

- Begin transaction; claim idempotency key at L00.
- Acquire the project parent fence before session insertion. Candidate mode is \`FOR SHARE\`, which is compatible with concurrent child writers and conflicts with parent state mutation/closure using \`FOR NO KEY UPDATE\`; exact mode remains subject to Engineering/Database approval and deployed PostgreSQL verification.
- Revalidate project lifecycle after any lock wait; validate normalized code; rely on unique \`(project_id, code)\` as final duplicate arbiter.
- Insert session using server-selected initial status; insert idempotency result and \`session.created\` audit event atomically.
- Concurrent same project/code requests must yield one created session and a typed duplicate result; do not leak another project's session.

### Audit and typed outcomes

- Required event: \`session.created\`; include actor, project/session target, correlation ID and minimal approved metadata.
- Outcomes: \`CREATED\`, \`DUPLICATE_CODE\`, \`PROJECT_NOT_FOUND\` (only where disclosure is authorized), \`PROJECT_STATE_INVALID\`, \`INVALID_INTERVAL\`, \`TIMEZONE_INVALID\`, \`PERMISSION_DENIED\`, \`SCOPE_DENIED\`, \`VALIDATION_FAILED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Create in authorized project; reject unauthorized project and non-Super-Admin caller.
- Duplicate normalized code under concurrent requests; unique constraint remains authoritative.
- Reject starts_at >= ends_at, malformed timestamp and invalid project timezone.
- Reject client-supplied status/actor/scope fields.
- Race create-session against project closure; no session may be created after closure serialization point.
- Audit failure rolls back session and idempotency result.

### Open decisions

**PO semantics resolved:** server-selected T-07 DRAFT; creation only in a project state that permits session creation; UTC instants interpreted through the project's canonical IANA timezone; reject DST gaps/folds; overlap is not prohibited by default.

**Technical decisions still open:** exact project-state enum binding; timestamp precision and API parsing contract; whether a denormalized session timezone snapshot is needed (do not infer a column); project/code uniqueness and parent-fence enforcement.

## CMD-012 — update-session

**Permission:** \`session.manage\`  
**Candidate route:** \`POST /api/commands/update-session\`  
**Candidate RPC:** \`public.cmd_update_session_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "session_id": "uuid",
    "expected_row_version": "7",
    "patch": {
      "starts_at": "2027-01-02T00:00:00Z",
      "ends_at": "2027-02-01T23:59:59Z"
    },
    "reason": "string"
  }
}
\`\`\`

Patch keys must be an explicit allowlist. Session code is immutable. Status, project_id, code, actor, permission, scope, transition target and assignment membership are excluded. The exact non-identity metadata allowlist remains an Engineering/API contract detail.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "updated",
  "resource_id": "session-uuid",
  "resource_version": 8,
  "server_time": "UTC timestamp",
  "result": {
    "changed_fields": ["starts_at", "ends_at"]
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, validation and SoD

- Approved/enabled Super Admin with \`session.manage\` and effective project scope for the session's immutable project binding.
- Resolve the immutable project binding through a non-locking locator read, then acquire project `FOR SHARE` followed by session `FOR NO KEY UPDATE`; revalidate the session-to-project binding and caller scope after the locks. Do not trust client project_id.
- Reject status/lifecycle mutation; CMD-013 owns state transitions.
- Validate all timestamps and code constraints after merging patch with stored values.
- If any assignment, claim, inspection, attendance or report references the session, reject schedule changes that would reinterpret existing work. Session code is immutable; accepted metadata changes require a non-empty reason.
- No self-assignment concept applies, but session metadata changes must not implicitly alter assignment membership or scope.

### Physical read/write set

- Read: \`sessions\`, parent \`projects\`, relevant \`operational_assignments\` and any session-bound work needed to validate impact; \`idempotency_records\`.
- Write: \`sessions\` and \`audit_events\`, plus \`idempotency_records\`.
- **Blocking schema gap:** \`sessions\` physical catalogue does not define \`version\`, \`row_version\`, or \`updated_at\`, while CMD-012 proposes \`expected_row_version\`. Physical row_version and increment rule remain unapproved. Do not implement optimistic concurrency until an explicit version column and increment rule are approved and added to the physical specification.

### Transaction, lock and idempotency

- Claim idempotency key at L00. Acquire project `FOR SHARE` before session `FOR NO KEY UPDATE` (project-before-session). Revalidate parent/session lifecycle and expected_row_version under lock.
- Validate dependent assignment/session time constraints under deterministic row locks or an approved exclusion/constraint mechanism, without acquiring a lower-ranked resource late.
- Update only allowlisted metadata; increment approved row version atomically.
- Append \`session.updated\` and idempotency result in the same transaction.
- Until the version field is defined, any \`expected_row_version\` contract is provisional and must fail design review rather than silently use timestamps or client values as a substitute.

### Audit and typed outcomes

- Required event: \`session.updated\`; record changed field names and reason, not unnecessary before/after personal data.
- Outcomes: \`UPDATED\`, \`STALE_VERSION\`, \`INVALID_STATE\`, \`DEPENDENT_ASSIGNMENT_CONFLICT\`, \`INVALID_INTERVAL\`, \`IMMUTABLE_FIELD\`, \`PERMISSION_DENIED\`, \`SCOPE_DENIED\`, \`VALIDATION_FAILED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Update allowed metadata with correct version.
- Reject stale version and concurrent conflicting update; exactly one version wins.
- Reject project_id/status/actor/scope/assignment changes in patch.
- Reject updates that invalidate existing assignment intervals.
- Verify code immutability decision and behavior.
- Audit failure rolls back metadata and version increment.

### Open decisions

**PO semantics resolved:** immutable session code; allowlisted non-identity metadata; non-empty reason; reject schedule reinterpretation after dependent work exists.

**Technical decisions still open:** exact metadata allowlist/dependent-work predicate; row-version/CAS representation and increment; physical field and project/session lock/fence design.

## CMD-013 — transition-session

**Permission:** \`session.transition\`  
**Candidate route:** \`POST /api/commands/transition-session\`  
**Candidate RPC:** \`public.cmd_transition_session_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "session_id": "uuid",
    "action": "ACTIVATE",
    "expected_row_version": "3",
    "reason": "string"
  }
}
\`\`\`

Allowed target states are not free-form. The exact transition graph must be an approved finite enum. Caller cannot supply from_state, actor, project scope, approval or bypass flags.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "transitioned",
  "resource_id": "session-uuid",
  "resource_version": 4,
  "server_time": "UTC timestamp",
  "result": {
    "from_state": "DRAFT",
    "to_state": "ACTIVE",
    "transition_event": "session.activated"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, state machine and SoD

- Preserve T-07 states exactly: `DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`; `CLOSE_REQUESTED` is not a state. The request payload carries an allowlisted action, never a client-selected target state.
- Korlap may ACTIVATE, PAUSE, RESUME or REQUEST_CLOSURE only within assigned scope and explicit permission. Super Admin performs FINAL_CLOSE only after closure gates; exceptional REOPEN is separately privileged, reasoned and audited. Exact action-to-permission mapping remains a Security/Engineering decision.
- Korlap may perform only the exact transition(s) approved for their assigned project/session scope. Korlap must not receive general \`session.transition\` authority that implicitly permits all transitions.
- Verify active account, permission, project/session scope and assignment membership for Korlap in the same transaction.
- Enforce a finite legal transition graph. Audit catalogue names: \`session.activated\`, \`session.paused\`, \`session.resumed\`, \`session.close_requested\`, \`session.closed\`.
- `CLOSED` is terminal in ordinary flow. Reopen is an exceptional privileged, reasoned and audited workflow; it is not a Korlap transition.
- A closure request is an action/event (`session.close_requested`), not an intermediate persisted state. Final closure is the transition to `CLOSED` by Super Admin after the approved closure gates. Operational checklist evidence remains subject to institutional authority where required.
- Transition must not alter assignment membership, target plans or inspection data.

### Physical read/write set

- Read: \`sessions\`, \`projects\`; \`operational_assignments\`, \`assignment_members\` for Korlap scope; closure dependency records for a close transition; \`idempotency_records\`.
- Write: \`sessions\`; \`audit_events\`; \`idempotency_records\`.
- **Blocking schema gap:** \`sessions\` has no defined row version field, although CMD-013 proposes \`expected_row_version\`. Physical row_version and increment rule remain unapproved.
- **Lifecycle status:** T-07 state vocabulary and actor boundary are PO-approved; exact transition matrix, action-to-permission mapping, closure checklist evidence and institutional gates remain open.

### Transaction, lock and idempotency

- Claim idempotency key at L00; acquire project `FOR SHARE` then session `FOR NO KEY UPDATE`; re-evaluate actor authorization, T-07 state and action under lock.
- Compare approved version token; validate exact transition edge.
- For close/final close, lock or consistently snapshot all dependency aggregates in deterministic order. Do not infer that absence of a dependency means closure is safe if the dependency inventory is incomplete.
- Update state/version and append the corresponding event atomically. Audit failure rolls back transition.
- Concurrent transition calls serialize on the session aggregate; second conflicting transition returns \`STALE_VERSION\` or \`INVALID_STATE_TRANSITION\`, not silent success.

### Audit and typed outcomes

- Map each allowed transition to one exact event from the audit catalogue. Do not use a generic \`session.*\` string in implementation.
- Outcomes: \`TRANSITIONED\`, \`INVALID_STATE_TRANSITION\`, \`CLOSURE_BLOCKED\`, \`STALE_VERSION\`, \`DENIED\`, \`SCOPE_DENIED\`, \`REASON_REQUIRED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Every approved transition edge positive test; every unapproved edge negative test.
- Korlap may execute only its approved assigned-scope edge; cross-session/project denied.
- CLOSED terminal behavior; forged target state and bypass flags rejected.
- Close gate blocks on every required dependency; race transition against assignment/session work creation.
- Concurrent transitions and audit failure rollback.
- Verify each transition emits exactly the expected event.

### Open decisions

**PO semantics resolved:** preserve T-07 states DRAFT/ACTIVE/PAUSED/CLOSED; CLOSED terminal in ordinary flow; CLOSE_REQUESTED is an action/event, not a state; Korlap may activate/pause/resume/request closure only within assigned scope and explicit permission; Super Admin is final closure authority after gates; reopening is privileged, reasoned and audited.

**Technical/institutional decisions still open:** exact transition table and permission mapping; closure checklist and operational evidence; row-version/CAS physicalization; parent/child fence and lock order; any institution-reserved closure criteria.

## CMD-014 — publish-assignment

**Permission:** \`assignment.manage\`  
**Candidate route:** \`POST /api/commands/publish-assignment\`  
**Candidate RPC:** \`public.cmd_publish_assignment_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "project_id": "uuid",
    "session_id": "uuid",
    "location_id": "uuid",
    "instrument_id": "uuid",
    "instrument_version_id": "uuid",
    "team_id": "uuid",
    "starts_at": "2027-01-01T00:00:00Z",
    "ends_at": "2027-01-31T23:59:59Z",
    "members": [
      {
        "user_id": "uuid",
        "operational_role": "INSPECTOR",
        "valid_from": "2027-01-01T00:00:00Z",
        "valid_until": null
      }
    ]
  }
}
\`\`\`

No status, actor, approval, effective project scope or publication bypass field is accepted. Member role values must be a server allowlist. Team composition/count remains Super Admin-controlled.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "published",
  "resource_id": "assignment-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "project_id": "uuid",
    "session_id": "uuid",
    "member_count": 1,
    "assignment_status": "server-selected-published-state"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope, SoD and invariants

- Caller must be an approved/enabled Super Admin with \`assignment.manage\` for the project.
- \`project_id\`, \`session_id\`, \`location_id\`, \`instrument_id\`, \`instrument_version_id\` and \`team_id\` must all resolve and belong to the same project as required by the physical model.
- Session must be in a state permitting assignment publication. The exact allowed states require CMD-013 lifecycle approval.
- Instrument version must be PUBLISHED and valid for new assignment selection; never bind a draft, retired or inactive version.
- Every member must be a registered, approved, enabled application account. Reject pending, rejected, suspended or disabled users.
- Reject caller self-assignment and any membership overlap prohibited by the staffing policy, including cross-location overlap.
- T-14: all Inspector eligibility-affecting changes serialize on the single \`project_capacity_settings\` row and use the canonical distinct-account predicate. Count each enabled account once across both locations and all qualifying assignments/roles. Enforce combined cap 1–100; do not silently disable or omit members.
- Do not allow a member to be assigned outside the assignment/session's project. A client-supplied \`project_id\` is a lookup selector only, never proof of authority.

### Physical read/write set

- Read: \`projects\`, \`sessions\`, \`locations\`, \`instruments\`, \`instrument_versions\`, \`teams\`, \`app_users\`, \`user_roles\`, existing \`operational_assignments\` and \`assignment_members\` for overlap, \`project_capacity_settings\`, \`idempotency_records\`.
- Write: \`operational_assignments\`, \`assignment_members\`, and if the physical model requires it, only the capacity row's audit/version metadata must not be modified as a side effect of assignment publication; plus \`idempotency_records\`, \`audit_events\`.
- No direct write to \`project_capacity_settings\` for this command.
- **Schema gaps:** no assignment row_version is defined; overlap semantics and exact membership effective-time uniqueness are not fully specified. Confirm whether assignment status starts as PUBLISHED or another state.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- Lock \`project_capacity_settings\` first whenever any proposed member can qualify as Inspector; this is the T-14 serialization point shared with role grant, member changes and capacity changes.
- Acquire affected principal, role and scope-grant rows at L15–L18 in stable-key order; then acquire project and session parent fences at L30 (`FOR SHARE`, project before session), instrument/version at L40 (`FOR SHARE`), assignment at L50 and membership rows at L55.
- Revalidate same-project references, authorization, published instrument version, account/role eligibility, self-assignment and effective times after the relevant locks.
- Validate overlap and calculate post-command distinct qualifying Inspector count while holding capacity lock.
- Insert assignment and all member rows atomically; append \`assignment.created\` and any approved capacity-related audit detail; insert idempotency result.
- If any member fails validation, reject the entire publish operation. No partial roster publication.

### Audit and typed outcomes

- Required event: \`assignment.created\` (or \`assignment.changed\` only if a documented upsert/edit behavior is separately approved; do not silently mix create and update).
- Outcomes: \`PUBLISHED\`, \`PROJECT_REFERENCE_MISMATCH\`, \`SESSION_INVALID\`, \`INSTRUMENT_VERSION_NOT_PUBLISHED\`, \`ACCOUNT_NOT_ELIGIBLE\`, \`SELF_ASSIGNMENT_FORBIDDEN\`, \`ASSIGNMENT_OVERLAP\`, \`CAPACITY_EXCEEDED\`, \`DUPLICATE_ASSIGNMENT\`, \`PERMISSION_DENIED\`, \`SCOPE_DENIED\`, \`VALIDATION_FAILED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Valid all-same-project assignment with published instrument version.
- Cross-project substitution for every reference type.
- Draft/retired instrument version rejected.
- Pending/suspended/disabled member and self-assignment rejected.
- Cross-location overlap and duplicate active membership rejected.
- Concurrent assignment publication vs role grant/member change/capacity reduction cannot exceed T-14 cap.
- Same account in multiple assignments counted once.
- All-or-nothing roster behavior; audit failure rolls back assignment and members.
- Direct DML denied.

### Open decisions

**PO semantics resolved:** create-only command; one atomic assignment plus complete initial roster; server selects initial published state after validation; half-open [start,end) intervals; reject overlap only where it creates duplicate/conflicting effective Inspector eligibility in the same project/session scope.

**Technical decisions still open:** exact eligible session states and persisted assignment enum; role/membership uniqueness constraints; T-14 capacity serialization and parent-fence order; version token only if a later update contract requires it.

## CMD-015 — change-assignment-members

**Permission:** \`assignment.manage\`  
**Candidate route:** \`POST /api/commands/change-assignment-members\`  
**Candidate RPC:** \`public.cmd_change_assignment_members_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "assignment_id": "uuid",
    "add_members": [
      {
        "user_id": "uuid",
        "operational_role": "INSPECTOR",
        "valid_from": "2027-01-05T00:00:00Z",
        "valid_until": null
      }
    ],
    "end_members": [
      {
        "assignment_member_id": "uuid",
        "effective_at": "2027-01-05T00:00:00Z"
      }
    ],
    "reason": "string"
  }
}
\`\`\`

The PO-approved contract requires per-membership \`effective_at\` for each end operation. Client cannot provide status or actor.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "updated",
  "resource_id": "assignment-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "added_members": 1,
    "ended_members": 1,
    "effective_at": "UTC timestamp"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope and invariants

- Approved/enabled Super Admin with \`assignment.manage\` for the assignment's project.
- Resolve assignment and project from database; no client-supplied scope is trusted.
- Additions require registered, approved, enabled accounts, valid role and interval, and no self-assignment.
- End operations must target active membership rows belonging to this assignment. Reject cross-assignment IDs.
- T-14 capacity row is locked first if Inspector eligibility may change; evaluate before and after using the same distinct-account predicate.
- Ending an Inspector assignment may reduce eligibility but must not silently revoke the user's Inspector role or alter other assignments.
- Existing inspections/claims are not reassigned or deleted. If removing a member would invalidate an active claim or in-progress inspection, behavior must be specified: block, allow future-effective removal, or preserve a grandfathered workflow. No policy is currently authoritative.

### Physical read/write set

- Read: \`operational_assignments\`, \`projects\`, \`sessions\`, \`assignment_members\`, \`app_users\`, \`user_roles\`, \`project_capacity_settings\`, active \`unit_claims\`/inspection dependencies when removing an Inspector; \`idempotency_records\`.
- Write: \`assignment_members\`; \`idempotency_records\`; \`audit_events\`.
- No role grant/revoke write; no direct change to assignment's project/session/instrument binding.
- **Schema gap:** \`assignment_members\` has no explicit row_version or updated_at. The catalogue does not require expected_version, but concurrency must be handled by row locks and uniqueness constraints.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- If Inspector eligibility may change, acquire L10 capacity first.
- Acquire affected principal/role/scope rows L15–L18 before project/session parents L30; acquire project then session parent fences (`FOR SHARE`), assignment L50, then assignment_members L55 in stable order. Revalidate assignment-to-parent binding after the locks.
- Validate all add/end operations before writing any; reject duplicate IDs, duplicate semantic operations, invalid intervals and conflicting add/end of same membership.
- Check current effective Inspector count and post-change count under the capacity lock; reject if cap exceeded.
- Update membership lifecycle with effective times; preserve historical rows. Do not hard delete.
- Append \`assignment.changed\`, idempotency result and any explicitly required audit metadata atomically.
- Entire command is atomic; no partial membership changes.

### Audit and typed outcomes

- Required event: \`assignment.changed\`; metadata records added/ended counts and reason, not unnecessary personal data.
- Outcomes: \`UPDATED\`, \`CAPACITY_EXCEEDED\`, \`OVERLAP\`, \`MEMBER_NOT_ACTIVE\`, \`MEMBERSHIP_NOT_IN_ASSIGNMENT\`, \`ACTIVE_CLAIM_BLOCKS_CHANGE\` (only where removal would orphan an active claim/in-progress workflow under the approved operational policy), \`INVALID_EFFECTIVE_TIME\`, \`DENIED\`, \`SCOPE_DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Add/remove valid member and verify durable history.
- Reject self-assignment, pending/rejected/suspended/disabled account and invalid role.
- Reject cross-assignment membership ID and duplicate add/end entries.
- Concurrency with CMD-014, CMD-016 and CMD-004 Inspector grant; cap never exceeded.
- Same user assigned across two locations counted once.
- Test active claim/inspection behavior against the approved policy.
- Audit failure rolls back all membership changes.

### Open decisions

**PO semantics resolved:** each membership end has its own effective_at; each accepted change requires a reason; membership is end-dated, not hard-deleted; submitted inspections are never deleted, reassigned or invalidated by member removal.

**Technical/operational decisions still open:** active claim/in-progress workflow handling; authorization freshness for future-effective ends; exact overlap predicate where duplicate/conflicting Inspector eligibility may result; request schema and history enforcement.

## CMD-016 — change-inspector-capacity

**Permission:** \`capacity.manage\`  
**Decision:** T-14 PO-approved canonical predicate and cap semantics.  
**Candidate route:** \`POST /api/commands/change-inspector-capacity\`  
**Candidate RPC:** \`public.cmd_change_inspector_capacity_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "project_id": "uuid",
    "inspector_cap": 50,
    "expected_row_version": "4",
    "reason": "string"
  }
}
\`\`\`

Cap must be an integer. Reject null, float, string coercion, zero, negative values and values above 100.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "updated",
  "resource_id": "project-uuid",
  "resource_version": 5,
  "server_time": "UTC timestamp",
  "result": {
    "inspector_cap": 50,
    "qualifying_inspector_count": 23
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization and T-14 predicate

- Approved/enabled Super Admin with \`capacity.manage\` and authority for the governed project.
- T-14 qualifying count at the transaction serialization point is the number of distinct user accounts satisfying all three conditions:
  1. Login account is enabled.
  2. An active Inspector role grant exists.
  3. At least one currently effective operational Inspector assignment exists within the governed project/session scope.
- Count each account once across assignments, roles and both locations.
- Exclude pending, rejected, suspended, disabled and expired-role accounts.
- Allowed cap: integer 1..100; default 50.
- Reject a proposed reduction below current qualifying count. Never deactivate, revoke roles or remove assignments to force a cap reduction.
- Client-side count is advisory only; database transaction is authoritative.

### Physical read/write set

- Read: \`projects\`, \`project_capacity_settings\`, \`app_users\`, \`user_roles\`, \`operational_assignments\`, \`assignment_members\`, \`idempotency_records\`.
- Write: \`project_capacity_settings\`, \`idempotency_records\`, \`audit_events\`.
- **Blocking schema gap:** physical \`project_capacity_settings\` defines \`project_id, inspector_cap, updated_at, updated_by\`, but no \`version\`/row_version. CMD-016 proposes \`expected_row_version\`; the physical version column and increment rule must be approved and specified before optimistic concurrency is implemented.

### Transaction, lock and idempotency

- Claim idempotency key at L00, then acquire exactly one \`project_capacity_settings\` row at L10 using the Database-approved exclusive serialization primitive. If no row exists, fail closed; initialization/backfill must be defined before any writer is enabled.
- Lock/read eligibility rows at L15–L17 after the capacity row; every command that changes the T-14 qualifying population must use the same capacity-row-first protocol.
- Compute qualifying count from the canonical predicate under this serialization point.
- Validate cap range and reject if new cap < qualifying count.
- Update cap, updated_at and updated_by from server/actor; increment approved version token; append \`capacity.limit_changed\` and idempotency result atomically.
- All commands that affect Inspector eligibility must participate in the same serialization protocol; otherwise the cap can be exceeded despite this command's local correctness.

### Audit and typed outcomes

- Required event: \`capacity.limit_changed\`; include previous/new cap, qualifying count, project ID, reason and actor.
- Outcomes: \`UPDATED\`, \`CAPACITY_BELOW_CURRENT_COUNT\`, \`VALIDATION_FAILED\`, \`PROJECT_NOT_FOUND\`, \`CAPACITY_ROW_MISSING\` (until initialization rule approved), \`STALE_VERSION\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Boundary values 1 and 100 accepted when count permits; 0, 101, negative, fractional and non-integer rejected.
- Reduction below qualifying count rejected; equal/above accepted.
- Verify distinct-account count across multiple assignments and both locations.
- Verify pending/rejected/suspended/disabled/expired users excluded.
- Race CMD-004, CMD-014, CMD-015 and CMD-016; no execution ordering may exceed cap.
- Stale expected version and same-key replay behavior.
- Audit failure rolls back cap change.
- Direct DML denied.

### Open decisions

**PO semantics resolved/reaffirmed:** T-14 predicate, distinct enabled accounts with active Inspector role and currently effective operational Inspector assignment in governed scope; cap 1–100/default 50; reject below count; never silently revoke.

**Technical decisions still open:** row-version/CAS; deterministic capacity-row initialization; exact server-time boundary; shared serialization across CMD-004/005/014/015/016 and all other eligibility writers.

## CMD-017 — manage-target-plan

**Permission:** \`target.manage\`  
**Candidate route:** \`POST /api/commands/manage-target-plan\`  
**Candidate RPC:** \`public.cmd_manage_target_plan_v1\`

### Request

The canonical catalogue describes one logical command with an action discriminator. This review proposes a strict action union; only one action is accepted per call.

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "project_id": "uuid",
    "session_id": "uuid",
    "action": "CREATE_DRAFT",
    "plan_id": null,
    "expected_plan_version": null,
    "allocations": [
      {
        "assignment_id": "uuid",
        "target_date": "2027-01-15",
        "quantity": 25
      }
    ],
    "reason": "string"
  }
}
\`\`\`

Proposed actions: \`CREATE_DRAFT\`, \`REPLACE_DRAFT_ALLOCATIONS\`, \`PUBLISH\`. The final enum and whether draft editing is whole-plan replacement or incremental allocation commands require PO approval. A caller may not send arbitrary status or version values.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "drafted",
  "resource_id": "target-plan-uuid",
  "resource_version": 1,
  "server_time": "UTC timestamp",
  "result": {
    "plan_version": 1,
    "plan_status": "DRAFT",
    "allocation_count": 1
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope and invariants

- Caller must hold \`target.manage\` and be an explicitly authorized planner in the target project/session scope. The permission matrix identifies an authorized planner; exact role-to-permission grants are not approved.
- Validate project and optional session relationship. If session_id is omitted, the plan's project-only semantics must be explicitly approved.
- Every allocation assignment must belong to the same project and, where session-scoped, the same session.
- Quantity must be a nonnegative integer; no float, negative or silent coercion.
- A PUBLISHED plan is immutable. Corrections require a new plan version, never in-place mutation of published allocations.
- Target plans and allocations are planning data only. They must never write, adjust or backfill actual inspection/activity data.
- The physical catalogue has \`target_plans(id, project_id, version, status)\` and \`target_allocations(id, target_plan_id, assignment_id, target_date, quantity)\`; it does not fully define session binding or the allocation uniqueness dimension.

### Physical read/write set

- Read: \`projects\`, \`sessions\` when session-scoped, \`operational_assignments\`, existing \`target_plans\` and \`target_allocations\`, \`idempotency_records\`.
- Write: \`target_plans\`, \`target_allocations\`, \`idempotency_records\`, \`audit_events\`.
- No writes to \`inspections\`, \`inspection_revisions\`, \`inspection_events\` or actual-report sources.
- **Schema gaps:** target plan has a business \`version\` but no separate row_version; target plan physical columns omit \`session_id\`; target allocation uniqueness key is not finalized. Do not assume business version alone provides concurrent draft-write protection.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- For new plan, lock project (and session if present) as needed to validate lifecycle and create next project plan version. Enforce unique \`(project_id, version)\`.
- For draft replacement, lock target plan row and all existing allocation rows in deterministic order; verify plan remains DRAFT and expected plan version/hash.
- Validate the entire allocation set before deleting/replacing any draft allocations. Published plan rows cannot be updated/deleted.
- For publish, lock plan row, validate complete allocation set, atomically transition DRAFT → PUBLISHED and append publication/audit event.
- If draft replacement uses delete-and-reinsert internally, it must remain one transaction and must not affect published history; confirm whether soft/history versioning is required.
- Insert idempotency result and exact target audit event atomically.

### Audit and typed outcomes

- Required events: \`target.created\`, \`target.reallocated\`, \`target.version_published\` mapped to the action. Do not emit all three for every action.
- Outcomes: \`DRAFTED\`, \`UPDATED\`, \`PUBLISHED\`, \`IMMUTABLE\`, \`STALE_PLAN_VERSION\`, \`ALLOCATION_INVALID\`, \`ASSIGNMENT_SCOPE_MISMATCH\`, \`SESSION_SCOPE_MISMATCH\`, \`VALIDATION_FAILED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Create a draft with valid assignments and integer allocations.
- Reject assignment from another project/session and invalid date/quantity.
- Draft replacement is atomic; invalid row leaves previous draft unchanged.
- Published plan and allocations are immutable through every command and direct DML.
- Concurrent draft updates/publish serialize; stale version/hash rejected.
- Verify no actual inspection/report data changes.
- Audit failure rolls back create/reallocation/publish.

### Open decisions

**PO semantics resolved:** session-scoped plans by default; project-wide plans require separate justified PO change; actions CREATE_DRAFT/REPLACE_DRAFT_ALLOCATIONS/PUBLISH; published plans immutable and corrections create new versions; unique allocation key (target_plan_id, assignment_id, target_date); duplicate rows and zero quantity rejected.

**Technical/product-detail decisions still open:** quantity units/range and reporting selection rules; draft row-version/hash CAS; version sequencing and supersession metadata; exact session binding and physical constraints.

## CMD-018 — create-instrument

**Permission:** \`instrument.manage\`  
**Decision:** T-17 separates manage, publish and deactivate permissions.  
**Candidate route:** \`POST /api/commands/create-instrument\`  
**Candidate RPC:** \`public.cmd_create_instrument_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "code": "INSTRUMENT-ABC",
    "name": "Instrument display name",
    "description": "Optional plain text description"
  }
}
\`\`\`

No status, active flag, version number, published version, project scope or actor field is accepted. The server selects initial catalog status according to the approved lifecycle; this initial status is not fully specified in the command catalogue.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "created",
  "resource_id": "instrument-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "code": "INSTRUMENT-ABC",
    "name": "Instrument display name",
    "status": "server-selected-initial-state"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, validation and SoD

- Approved/enabled Super Admin with explicit \`instrument.manage\`; global catalog authority does not imply project operational access.
- Normalize code using a documented rule and enforce global uniqueness.
- Code is immutable after use; display name and description updates are not part of CMD-018 and require a separate command or an approved extension.
- Description must be plain text and bounded in length. Reject executable content and arbitrary HTML/SQL/script fields.
- Creating an instrument does not publish a version and does not authorize assignments to use it.

### Physical read/write set

- Read: \`instruments\` for duplicate normalized code; \`idempotency_records\`.
- Write: \`instruments\`; \`idempotency_records\`; \`audit_events\`.
- Physical schema: \`instruments(id, code, name, description, status, created_by)\`, unique immutable code; status values ACTIVE/INACTIVE/ARCHIVED.
- No project, assignment, checklist or version rows are written by CMD-018.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- Insert instrument with server-derived \`created_by\` and server-selected initial status.
- Let unique code constraint arbitrate concurrent duplicate creation.
- Append \`instrument.created\` and idempotency result atomically.
- No second-person approval is specified for catalog entry creation; T-17's no-second-approver decision specifically concerns publication and must not be generalized beyond its stated scope.

### Audit and typed outcomes

- Required event: \`instrument.created\`.
- Outcomes: \`CREATED\`, \`DUPLICATE_CODE\`, \`INVALID_CODE\`, \`VALIDATION_FAILED\`, \`PERMISSION_DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Authorized global catalog creation; project-scoped non-admin denied.
- Duplicate normalized code under concurrency.
- Reject status/created_by/published version fields and executable description payload.
- Verify no version or operational assignment is created.
- Audit failure rolls back instrument insert.

### Open decisions

**PO semantics resolved:** new instrument is draft/inactive and cannot be selected for assignment until a version is published; code normalization direction is Unicode NFKC, trim surrounding whitespace, invariant uppercase for approved ASCII alphabet, reject internal whitespace/control characters, unique normalized value.

**Technical decisions still open:** exact permitted ASCII alphabet/reserved codes, Unicode test vectors, collation and unique enforcement; name/description bounds and normalization.

## CMD-019 — save-instrument-draft

**Permission:** \`instrument.manage\`  
**Candidate route:** \`POST /api/commands/save-instrument-draft\`  
**Candidate RPC:** \`public.cmd_save_instrument_draft_v1\`

### Request

The command catalogue currently uses generic \`sections[]\`, \`fields[]\` and \`evidence_slots[]\`. The physical schema distinguishes checklist items from specification fields. This review makes that distinction explicit to avoid writing generic fields into the wrong entity.

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "instrument_id": "uuid",
    "version_id": null,
    "schema_version": 1,
    "change_summary": "Draft configuration update",
    "sections": [
      {
        "code": "SECTION-01",
        "label": "Section label",
        "sort_order": 1,
        "items": [
          {
            "code": "ITEM-01",
            "label": "Checklist question",
            "answer_type": "BOOLEAN",
            "sort_order": 1,
            "required": true,
            "applicability_rule": null,
            "validation_config": {}
          }
        ]
      }
    ],
    "specification_fields": [
      {
        "code": "FIELD-01",
        "label": "Measured value",
        "value_type": "DECIMAL",
        "expected_value": null,
        "unit": "unit",
        "required": false,
        "sort_order": 1
      }
    ],
    "evidence_slots": [
      {
        "code": "PHOTO-01",
        "label": "Evidence photo",
        "required": true,
        "allowed_media_types": ["image/jpeg", "image/png"],
        "sort_order": 1,
        "applicability_rule": null
      }
    ]
  }
}
\`\`\`

The enum examples above are illustrative only. The authoritative allowlists for answer_type, value_type, applicability_rule and validation_config are not yet attached as versioned schemas. The server must reject unknown keys and types.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "saved",
  "resource_id": "instrument-version-uuid",
  "resource_version": 1,
  "server_time": "UTC timestamp",
  "result": {
    "instrument_id": "instrument-uuid",
    "version_number": 1,
    "status": "DRAFT",
    "configuration_hash": "sha256-hex"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, schema safety and immutability

- Approved/enabled Super Admin with explicit \`instrument.manage\`; global catalog authority only.
- Target instrument must exist and be in a lifecycle state permitting a new draft.
- If version_id is null, server allocates the next version number under instrument-row lock. If version_id is supplied, it must identify a DRAFT version of that same instrument.
- Only DRAFT version and its child configuration may be changed.
- PUBLISHED or RETIRED version content cannot be edited. Corrections require a new draft version.
- Validate complete schema server-side against a strict, versioned declarative schema.
- Reject scripts, SQL, HTML executable expressions, arbitrary code, unsafe regular expressions, dynamic function names, unbounded recursive rules and unknown validation primitives.
- Validate uniqueness of codes/order within each version/section and all cross-references.
- Evidence MIME values must be allowlisted; actual size/quota controls remain under the approved evidence policy, not arbitrary instrument-level overrides.
- Saving a draft does not publish it or make it selectable for assignments.

### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, existing \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`.
- Write: \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`, \`audit_events\`.
- \`instrument_version_publications\` is not written by draft save.
- **Schema gap:** physical specification does not explicitly define a canonical configuration hash/content-hash column or row_version for DRAFT version concurrency. T-17 requires retained configuration snapshot/hash; define exact storage and canonicalization before implementation.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- Lock instrument row, then target instrument_version row (or serialize version-number allocation under instrument lock).
- Verify version belongs to instrument and is DRAFT.
- Validate the entire proposed configuration before any child mutation.
- Replace or reconcile child rows in deterministic order within one transaction. Preserve stable child IDs only if an approved reconciliation rule exists; otherwise define replacement semantics and history handling.
- Compute canonical configuration hash over schema_version and normalized child content. Store it in an approved physical field.
- Append \`instrument.version_drafted\` and any exact \`checklist_item.changed\` / \`evidence_slot.changed\` events required by the audit policy. Do not emit vague “config changed” events without a defined event type.
- Insert idempotency result atomically. Any validation or audit failure rolls back all draft changes.

### Audit and typed outcomes

- Required event: \`instrument.version_drafted\`; child-level change events only if the event catalogue policy requires them and defines their metadata.
- Outcomes: \`SAVED\`, \`VALIDATION_FAILED\`, \`PUBLISHED_IMMUTABLE\`, \`INSTRUMENT_NOT_FOUND\`, \`VERSION_NOT_FOUND\`, \`VERSION_NOT_DRAFT\`, \`DUPLICATE_SCHEMA_CODE\`, \`UNSUPPORTED_FIELD_TYPE\`, \`UNSUPPORTED_VALIDATION_RULE\`, \`UNSAFE_EXECUTABLE_CONTENT\`, \`STALE_DRAFT\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Save valid configuration with all child entities mapped to correct physical tables.
- Reject unsupported answer/value types, unknown properties, script/SQL/HTML executable content and unsafe validation rules.
- Reject cross-version child references, duplicate codes/order and invalid MIME allowlist.
- Published/retired version mutation denied through command and direct DML.
- Concurrent draft saves serialize; stale draft hash/version rejected.
- Verify canonical hash changes only when semantic configuration changes.
- Audit failure rolls back parent and every child mutation.

### Open decisions

**PO semantics resolved:** atomic complete declarative draft replacement; omitted children removed from draft only; published snapshots immutable; meaningful change summary; no executable expressions/dynamic code/arbitrary regex/unbounded recursion.

**Technical/security decisions still open:** exact versioned schema/primitive allowlist; size/depth/MIME/value bounds; stable child identity; canonical hash and draft CAS; audit event granularity.

## CMD-020 — publish-instrument-version

**Permission:** \`instrument.publish\`  
**Decision:** T-17 PO APPROVED A — authorized Super Admin may publish directly without second-person approval.  
**Candidate route:** \`POST /api/commands/publish-instrument-version\`  
**Candidate RPC:** \`public.cmd_publish_instrument_version_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "instrument_id": "uuid",
    "version_id": "uuid",
    "change_summary": "Approved instrument content and validation changes",
    "expected_draft_hash": "sha256-hex"
  }
}
\`\`\`

No published_by, published_at, target status, approver ID, second-approver field, version number or client-supplied actor is accepted. Actor and publication time are server-derived.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "published",
  "resource_id": "instrument-version-uuid",
  "resource_version": 1,
  "server_time": "UTC timestamp",
  "result": {
    "instrument_id": "instrument-uuid",
    "version_number": 1,
    "status": "PUBLISHED",
    "published_by": "auth-derived-app-user-uuid",
    "published_at": "UTC timestamp",
    "configuration_hash": "sha256-hex"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization and T-17 invariants

- Caller must be approved/enabled Super Admin with explicit \`instrument.publish\`; \`instrument.manage\` alone is insufficient.
- T-17 explicitly permits direct publication by the authorized Super Admin; do not add a second-person approval gate.
- Actor is derived from caller JWT via \`auth.uid()\`; published_by cannot be caller supplied.
- Target version must belong to target instrument and be DRAFT.
- Recompute canonical configuration hash server-side and compare with \`expected_draft_hash\`; reject if stale or different.
- Validate all schema types, field definitions, references, required evidence slots, applicability and all declarative rules against server allowlists.
- Reject executable content and unsupported primitives.
- On success, version and all child configuration become immutable. Corrections require a new version.
- Publication does not automatically rebind existing assignments/sessions or rewrite inspection history. Each assignment/session remains pinned to its selected published version.
- Deactivation is a separate command and permission; CMD-020 cannot deactivate an instrument.

### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`.
- Write: \`instrument_versions\` (status, published_at, published_by and approved version metadata); append \`instrument_version_publications\`; append \`audit_events\`; \`idempotency_records\`.
- Child configuration tables are read for validation and must be protected from subsequent mutation; no child content update is part of publication.
- **Schema gap:** physical specification lists published_at/published_by but does not fully specify change_summary, immutable snapshot/hash storage, or a database-level immutability enforcement mechanism. T-17 requires all of these to be retained and enforced.

### Transaction, lock and idempotency

- Claim idempotency key at L00.
- Lock instrument row first, then instrument_version row.
- Recheck caller permission, instrument/version relationship, DRAFT status and expected hash under lock.
- Recompute hash from canonical child configuration; never trust a client-computed hash as evidence of validity.
- Validate complete schema and all cross-references.
- Update version to PUBLISHED with server-derived published_by/time and immutable snapshot/hash; append publication row and \`instrument.version_published\` audit event in the same transaction.
- Ensure child tables cannot be changed after publication through command validation, constraints/triggers and direct DML denial. The exact enforcement design must be approved and tested.
- Audit failure rolls back publication and publication-history row.
- Same-key replay returns original publication result; a different key targeting an already-published version returns a typed already-published/immutable outcome, not a second publication event.

### Audit and typed outcomes

- Required event: \`instrument.version_published\`; publication history row and audit event commit atomically.
- Outcomes: \`PUBLISHED\`, \`SCHEMA_INVALID\`, \`STALE_DRAFT\`, \`VERSION_NOT_DRAFT\`, \`VERSION_INSTRUMENT_MISMATCH\`, \`INSTRUMENT_NOT_FOUND\`, \`HASH_MISMATCH\`, \`UNSUPPORTED_FIELD_TYPE\`, \`UNSAFE_EXECUTABLE_CONTENT\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Authorized Super Admin publishes valid draft without second approver.
- \`instrument.manage\` without \`instrument.publish\` is denied.
- Non-Super-Admin and wrong global scope denied.
- Stale hash, altered child configuration, unsupported type and cross-instrument version rejected.
- Concurrent publish and draft edit serialize; exactly one valid publication.
- Published parent and child configuration immutable via every command and direct DML.
- Verify actor/time are server-derived and cannot be forged.
- Publication record and audit event atomic; audit failure rolls back both.
- Existing assignment/session bindings and historical inspection revisions remain unchanged.

### Open decisions

**PO semantics resolved/reaffirmed:** T-17 Super Admin requires explicit instrument.publish; instrument.manage alone is insufficient; publication is server-validated; published version/children immutable; corrections create a new version; assignments/sessions remain pinned; same-key replay returns original result and a distinct key cannot create duplicate publication.

**Technical decisions still open:** canonical hash persistence/canonicalization; physical immutability enforcement; publication record schema; exact typed already-published outcome; function owner/ACL and atomic transaction proof.

## 4. Cross-command invariants and dependency map

| Invariant | Commands | Required control |
|---|---|---|
| Session lifecycle | CMD-011–013, CMD-014, CMD-017 | Session creation, metadata update, state transition and downstream assignment/target operations share one approved lifecycle graph and lock discipline |
| Session/project temporal integrity | CMD-011–014 | Valid IANA project timezone, valid intervals, exact UTC/timezone interpretation, consistent overlap policy |
| Inspector capacity | CMD-004, CMD-014, CMD-015, CMD-016 | Same T-14 distinct-account predicate; capacity row first; all eligibility-changing commands serialize on one project row |
| Assignment integrity | CMD-014–015, CMD-017 | Same-project references; approved session state; published instrument version; eligible accounts; no self-assignment or prohibited overlap |
| Target immutability | CMD-017 | Draft mutable; published immutable; versioned correction; never writes actuals |
| Instrument immutability | CMD-018–020 | Separate manage/publish permissions; declarative schema allowlist; publication atomic; published configuration immutable |
| Audit atomicity | CMD-011–020 | Exact typed domain event in same transaction; audit failure aborts mutation |
| Direct DML/ACL | CMD-011–020 | Browser INSERT/UPDATE/DELETE denied; only exact command function EXECUTE grants after review |

## 5. Consolidated findings and blockers

### F-011-01 — Session timezone semantics are ambiguous

The command catalogue permits timezone, while the physical session table does not define it and projects already own IANA timezone. Choose one canonical interpretation before API schema freeze.

### F-011-02 — Session initial state and lifecycle graph are incomplete

CMD-011 initial state is PO-approved as T-07 DRAFT. CMD-013 preserves DRAFT/ACTIVE/PAUSED/CLOSED and treats CLOSE_REQUESTED as action/event. Exact transition edges and permission mapping remain Engineering/Security review items.

### F-012-01 — Session optimistic concurrency is not physicalized

CMD-012 and CMD-013 propose `expected_row_version`, but `sessions` has no `row_version` in the physical specification. Database/Engineering must approve the physical token and increment rule before implementation.

### F-014-01 — Assignment/member lifecycle and overlap semantics are incomplete

The PO has approved half-open [start,end) intervals, the scoped duplicate/conflicting Inspector eligibility predicate and preservation of submitted inspections. Active claim/in-progress orphan handling and physical uniqueness remain technical/operational review items.

### F-016-01 — Capacity settings version is missing

CMD-016 proposes `expected_row_version`; `project_capacity_settings` has no `row_version`. T-14 predicate is PO-approved; physical versioning and deterministic capacity-row initialization remain design gaps.

### F-017-01 — Target plan scope and allocation uniqueness are incomplete

Physical target_plans has project_id but no session_id. Target allocation uniqueness is described as “as defined by target dimension” without a final key. Draft concurrency token and immutable history strategy are not fully specified.

### F-019-01 — Instrument configuration schema is not executable as a strict contract yet

The physical model lists declarative columns but does not publish versioned allowlists for answer_type, value_type, applicability_rule or validation_config. A versioned JSON schema and deterministic canonicalization are required.

### F-019/020-01 — Instrument configuration hash/snapshot is not fully physicalized

T-17 requires a retained configuration snapshot/hash, but the physical schema does not fully define storage, canonicalization or immutability enforcement for parent and child rows.

### F-014/015/016-01 — T-14 serialization must be proven across all writers

CMD-004 Inspector role grants, CMD-014 assignment publication, CMD-015 membership changes and CMD-016 capacity updates must all lock the same project capacity row first and use the identical qualifying-account predicate. A local CMD-016 implementation alone cannot prove the cap.

### F-011/012/013/014/017-01 — Session closure dependency graph is not yet complete

Closing a session must not strand assignments, targets or active work. The complete closure gate and serialization protocol must be approved before CMD-013 can close sessions.

## 6. PO decisions closed; technical/security decisions before contract freeze

The Product Owner's CMD-011–020 product-semantic decisions are approved and recorded in the Decision Register. The approved semantics are synchronized in the command catalogue and functional model. No further PO response is required for the approved items unless a proposed change would alter them.

The remaining pre-freeze decisions are assigned to the competent technical or institutional authorities:
1. Engineering/Database: project/session parent-fence lock mode and one total order across CMD-009–015; PostgreSQL row-lock compatibility and complete competing-writer paths.
2. Engineering/QA: physical row-version/CAS fields and increments for sessions and capacity settings; exact dependent-work predicate and transition matrix implementation.
3. Engineering/Database/Security: T-14 capacity serialization across all eligibility-changing commands; membership active-claim/in-progress behavior; exact assignment constraints.
4. Product/Engineering: target quantity unit/range and report selection semantics; draft concurrency and versioning.
5. Engineering/Security: instrument code alphabet/collation; declarative schema allowlist and bounds; canonical configuration hash, child identity and CAS; publication immutability enforcement.
6. Security/Database: function owner, effective privileges, RLS interaction, search_path, exact EXECUTE ACL and caller-JWT route evidence for each protected command.
7. Institution/Operations: any closure checklist, records/privacy retention, active-work disposition or other authority reserved outside PO product scope.


## 7. Verification and implementation status

| Area | Status |
|---|---|
| Canonical CMD-011–020 catalogue review | DOCUMENTED |
| Proposed request/response contracts | DOCUMENTED; PO product semantics approved, API/schema review remains open |
| Permission/scope/SoD review | DOCUMENTED; role grants not approved |
| Physical read/write set | DOCUMENTED against proposed schema only |
| Lock/transaction/idempotency design | DOCUMENTED; not implemented or runtime-verified |
| Audit event mapping | DOCUMENTED against event catalogue |
| RLS/privilege posture | DOCUMENTED against proposed catalogues only |
| Live Supabase table/RLS/function owner/EXECUTE verification | NOT PERFORMED |
| Positive/negative/replay/concurrency/audit-failure tests | SPECIFIED ONLY; NOT EXECUTED |
| T-10 / T-12 institutional/provider evidence | OPEN |
| CMD-045–048 institutional authority | BLOCKED |
| Notification worker identity and ACL | PENDING APPROVAL |
| G9 | NOT READY |
| G10 | NOT AUTHORIZED |
| Source code / SQL / migration / grants / live DB / deployment / merge | NOT PERFORMED |

No implementation readiness or production readiness is claimed by this review.

## 8. Change control

- Product semantics for CMD-011–020 are PO APPROVED as recorded in the Decision Register; this document remains an engineering proposal and is not technical/security approval.
- Do not implement any candidate route, RPC, SQL, index, trigger, grant or RLS policy solely from this document.
- Update the canonical command catalogue, permission registry, physical schema, RLS catalogue, audit catalogue and test catalogue together when an issue is resolved.
- Preserve immutable command IDs. Breaking contract changes require a new schema/API version and explicit compatibility plan.
- Re-review CMD-001–010 findings alongside CMD-011–020 where shared invariants intersect, especially T-14 capacity serialization and version-field gaps.


## 9. Product Owner semantic decision overlay — 2026-11-24

The Decision Register's CMD-011–020 approval addendum and decision package v0.2.0 are authoritative for product semantics. This overlay supersedes conflicting candidate semantics in this review only where explicitly stated below. It does not approve API/JSON schemas, database fields/constraints, lock modes/order, permission grants, function signatures/ACLs, or implementation.

| Command | PO-approved product semantics | Contract reconciliation required before freeze |
|---|---|---|
| CMD-011 create-session | Server selects initial state `DRAFT` under a project state that the canonical project lifecycle permits for session creation. Persist UTC instants; local input is interpreted using the project's canonical IANA timezone. Reject ambiguous/nonexistent DST local times. Overlap is not prohibited by default. | Replace any `PLANNED` candidate with canonical `DRAFT`; resolve exact project-state enum, timestamp precision/input contract, project/code uniqueness and parent fence. |
| CMD-012 update-session | Session code is immutable. Only allowlisted non-identity metadata is mutable. Once dependent work references the session, reject schedule changes that reinterpret existing work. Every accepted metadata update has a non-empty reason. | Define exact metadata allowlist and dependent-work predicate. Session row-version/CAS and lock order remain Engineering/QA decisions; current physical schema lacks the required token. |
| CMD-013 transition-session | Canonical states remain `DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`; `CLOSED` is terminal in ordinary flow. Korlap's actions are limited to activate/pause/resume/request closure within assigned scope and explicit permission. Final closure is a separate authorized action after gate validation; reopening is privileged, reasoned and audited. | `CLOSE_REQUESTED` is an action/event, not a persisted state. Super Admin remains final closure authority per T-06/T-07. Exact transition matrix, permissions, closure checklist and lock/fence protocol remain open. |
| CMD-014 publish-assignment | One create-only command atomically creates one assignment and its complete initial roster. Server chooses initial published state only after validation. Assignment intervals are half-open `[start,end)`. Reject overlapping effective membership only when it creates duplicate/conflicting Inspector eligibility in the same governed project/session scope. | Define exact lifecycle enum and overlap predicate. T-14 capacity serialization, parent-fence and atomic roster implementation remain technical review items. |
| CMD-015 change-assignment-members | Every membership end has its own `effective_at`; every accepted change has a reason; history is ended, not hard-deleted. Submitted inspections are never deleted, reassigned or invalidated by member removal. | Request shape must represent per-member effective times. Active claims/in-progress orphaning and transfer/grandfathering behavior require operational-owner review. Retention remains under T-10. |
| CMD-016 change-inspector-capacity | Reaffirm T-14 unchanged: integer cap 1–100, default 50; distinct enabled accounts with active Inspector role and at least one currently effective operational Inspector assignment in governed project/session scope; reject reduction below count; never silently revoke roles/assignments. | No new capacity rule is created. Shared serialization, row version and physical enforcement remain open. |
| CMD-017 manage-target-plan | Prefer session-scoped plans; project-wide plans require separate justified product change. Actions are `CREATE_DRAFT`, `REPLACE_DRAFT_ALLOCATIONS`, `PUBLISH`. Published plans are immutable; corrections create a new version. Allocation uniqueness is `(target_plan_id, assignment_id, target_date)`; duplicates and zero quantity are rejected. | Make `session_id` required for normal plans or define separately approved project-wide exception; define quantity unit/range and draft concurrency token. |
| CMD-018 create-instrument | New instrument is draft/inactive and not selectable for assignment until a version is published. Code normalization direction: Unicode NFKC, trim surrounding whitespace, invariant uppercase for the approved ASCII alphabet, reject internal whitespace/control characters, unique normalized value. | ASCII alphabet, Unicode edge cases, collation and physical uniqueness enforcement require Engineering/Security approval before executable contract. |
| CMD-019 save-instrument-draft | Save replaces the complete declarative configuration atomically; omitted children are removed from draft only; published snapshots are immutable; each save requires meaningful change summary. No executable expressions/dynamic code, arbitrary regex execution or unbounded recursion. | Exact schema/primitive allowlist, depth/size limits, stable child identity, canonical hash and concurrency token require Security/Engineering approval. |
| CMD-020 publish-instrument-version | Reaffirm T-17: Super Admin with explicit `instrument.publish` publishes after server validation; `instrument.manage` alone is insufficient. Published version/children are immutable; correction creates a new version; assignments/sessions stay pinned. Same idempotency key replays original result; a different key cannot duplicate publication. | T-17 is not reopened. Exact hash, ACL, atomicity, audit and immutable snapshot enforcement remain Engineering/Security/QA review. |

### Authority and status boundary

Product-semantic review for CMD-011–020 is **PO APPROVED**. This does not close engineering findings F-011-01 through F-019/020-01, approve any candidate lock sequence, or close DGA-B14/B17/B18/B19/B21. T-14 and T-17 are reaffirmed, not reopened. All tests remain planned/not executed; G9 NOT READY; G10 NOT ACTIVE.


## 10. Current gate status synchronization — 2026-11-24

The current controlling authorization state is recorded in root `AGENTS.md` v1.2.2 and MIB-001: conditional Product Owner implementation authorization has been received; G9 remains NOT READY; G10 remains NOT ACTIVE pending verified G9 and a separate approved G10 activation record. Historical wording in prior snapshots is not current authorization. This status correction does not close any engineering/security finding, approve a command contract or lock protocol, or authorize implementation. All CMD-011–020 execution tests remain PLANNED / NOT EXECUTED.


## SES-001 / WF-003 — CMD-013 final session-close inspection gate (2026-11-24)

PO-approved SES-001 and WF-003 refine the CMD-013 closure precondition:

1. `REQUEST_CLOSURE` remains a request/action only. It does not set the session to CLOSED and does not itself abort unit work.
2. Before `FINAL_CLOSE`, every inspection attempt belonging to the exact session must be accounted for. A completed attempt must satisfy the approved inspection/review/document/print completion requirements. An incomplete or returned-but-unresolved attempt must already have a committed terminal ABORTED outcome.
3. CMD-013 must fail with `CLOSURE_BLOCKED` while any attempt has no allowed terminal outcome, including an active claim, active draft context, pending submit/review, evidence finalization or other in-flight inspection work. The exact blocker inventory must be completed with Operations/Engineering/Database; absence of a row in one current table is not proof of no work.
4. CMD-013 must not silently abort units, release claims, delete drafts or synthesize missing evidence. Abort is an explicit per-unit operation before final close. A failed/partial abort leaves the session open and the attempt unresolved.
5. Once all blockers are cleared, Super Admin final close rechecks the complete blocker predicate under the approved session parent fence and child-writer serialization protocol, then atomically commits session CLOSED, `session.closed`, required audit and idempotency. It must not cascade-delete or rewrite inspection history.
6. An ABORTED attempt remains a non-completion in actual reports/recaps and must not be counted as inspected, approved, good, defective or printed. A later session starts a new attempt; the old attempt remains immutable.

**Technical disposition:** CMD-013 session row_version/CAS, complete inspection/evidence/document/print/worker blocker inventory, parent/child lock protocol, event/audit atomicity and runtime tests remain OPEN. The ABORTED state/event and exact abort command contract are not yet physically admitted. No implementation or test execution is authorized by this addendum.


### T-07 privileged session reopen × SES-001 abort boundary — open

T-07 permits a CLOSED session to be reopened only through a privileged, reasoned and audited action. SES-001 makes every ABORTED inspection attempt terminal and non-resumable. It remains an explicit PO/operational decision whether the reopened session may accept a brand-new inspection aggregate under the same session_id. Until that rule is approved, CMD-013 session reopen may not reactivate any prior attempt, and CMD-026 must fail closed if accepting a new attempt would rely on the unresolved policy. This is traced as IDC-O10 / TC-SESSION-008; it does not relax final-close blocker checks or allow work to cross session IDs.
