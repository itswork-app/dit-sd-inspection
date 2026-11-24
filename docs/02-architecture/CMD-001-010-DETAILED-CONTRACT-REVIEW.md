# CMD-001–010 Detailed Contract Review

**Status:** Engineering contract review — proposal only; PO/security review required; NOT approved for implementation  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Scope:** CMD-001 through CMD-010  
**Controls:** T-15 append-only audit direction; T-18 Option A command boundary; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Purpose and non-authority

This document expands the existing PostgreSQL Command Contract Catalogue for CMD-001–010. It is a documentation-only review artifact. It does not authorize source changes, SQL, migrations, function creation, grants/revokes, live database changes, deployment, or merge.

The canonical command catalogue remains the ID and permission-code source. This document identifies contract details and unresolved decisions; it does not approve permission seeding, role grants, route exposure, function ownership, or EXECUTE ACLs.

## 2. Shared contract envelope

### 2.1 Transport and identity

- Candidate transport pattern: `POST /api/commands/{logical-command-name}`; exact route names and API version are provisional and require API contract approval.
- Candidate RPC naming pattern: `public.cmd_<logical_command_name>_v1(...)`; no function name/signature is approved or asserted to exist.
- Route validates method, content type, body size, schema version, allowlisted fields and authentication session.
- Route forwards the caller JWT. It must not accept trusted actor ID, role, permission, approval state or effective scope from the client.
- Database derives actor only from `auth.uid()`, resolves the active approved `app_users` identity and evaluates permission, validity, scope and SoD in the same transaction as the mutation.
- Anonymous and PUBLIC execution are denied. Browser roles have no direct INSERT/UPDATE/DELETE on protected tables. The actual owner, security mode, search_path and EXECUTE ACL remain unverified and must be reviewed per function against Supabase catalog evidence.
- No SECURITY DEFINER function is presumed. Any exception requires separate security approval, a non-login least-privileged owner, pinned safe search_path, schema-qualified references, revoked PUBLIC EXECUTE and exact grants.

### 2.2 Idempotency

For each mutation, the server derives a canonical request hash from command ID/version and normalized semantic payload. The idempotency scope is actor + command + resource scope + opaque key.

- Same key and same hash: return the original typed result after reauthorization; do not repeat side effects.
- Same key and different hash: return `IDEMPOTENCY_KEY_REUSED`.
- Concurrent same-key calls must serialize through the unique idempotency key constraint/atomic claim.
- Idempotency record and business mutation/audit event commit or roll back atomically.
- Retention must exceed the approved maximum retry/offline window; exact retention is not approved here.

### 2.3 Audit and errors

- Successful critical mutations append the required domain audit event in the same transaction. Audit insert failure aborts the mutation and suppresses success.
- Denials are recorded only where the approved security-event policy requires; do not log sensitive request bodies, credentials, tokens or unnecessary personal data.
- Use stable typed outcomes. Do not reveal resource existence to unauthorized callers.
- Database/server time is authoritative; client timestamps are not trusted for validity decisions.
- Correlation ID is generated or validated at the trusted boundary and propagated to audit/diagnostic context.

### 2.4 Shared test minimum

Every command requires: authorized positive case; unauthenticated/unauthorized and wrong-scope negative cases; forged actor/role/scope input; malformed and boundary input; same-key replay; same-key/different-payload replay; concurrent conflicting calls; audit-insert failure rollback; direct browser DML denial; and function EXECUTE ACL verification. These are planned test requirements, not executed tests.

## 3. Detailed command contracts

## CMD-001 — request-account-access

**Permission:** `account.request`  
**Candidate route/RPC:** `POST /api/commands/request-account-access` → candidate `public.cmd_request_account_access_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "display_name": "string",
  "requested_contact": "string|null"
}
```

No `user_id`, `auth_user_id`, actor, role, approval status, account status or scope field is accepted. The actor is `auth.uid()`.

### Response

```json
{
  "outcome": "ACCEPTED",
  "request_id": "uuid",
  "approval_status": "PENDING",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Caller must be authenticated and map to exactly one own Auth-backed application identity.
- The command can create/update only the caller's own request/profile state; it cannot grant role, permission, project membership or scope.
- Existing approved, suspended, rejected or pending account behavior must be explicitly decided. The catalogue currently lists `ALREADY_PENDING`, but does not fully define all repeat-state outcomes.
- A request for another UID or any privilege-bearing field is rejected; never silently honor client-supplied identity.

### Physical read/write set

- Read: authenticated identity mapping in `app_users`; idempotency record.
- Write: `app_users` only if the canonical account-request lifecycle assigns profile/request fields there; `idempotency_records`; `audit_events`.
- **Model gap:** no dedicated account-request entity is listed. Confirm whether `app_users` is created at Auth signup or first request, and whether a separate request state/history table is required. Do not infer a table.

### Transaction, lock and audit

- Resolve own `app_users` row by unique `auth_user_id`; serialize concurrent first requests with the unique constraint/upsert conflict path, not a client-selected UID.
- Persist request state, idempotency result and `account.requested` audit event atomically.
- No lock on another user's row.
- Audit failure rolls back any profile/request mutation.

### Typed outcomes

`ACCEPTED`, `ALREADY_PENDING`, `ALREADY_APPROVED` (if PO approves this outcome), `AUTH_REQUIRED`, `VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REUSED`, `INTERNAL_AUDIT_FAILURE`.

### Test additions

- Self-request creates exactly one pending request.
- Forged target UID, role, scope or approval fields rejected.
- Concurrent first request yields one logical request.
- Replay returns same request ID; changed payload under same key rejected.
- Already-pending and already-approved behavior matches approved state table.
- Audit failure leaves no new request/profile transition.
- Anonymous/PUBLIC EXECUTE and browser direct DML denied.

## CMD-002 — approve-account

**Permission:** `account.approve`  
**Candidate route/RPC:** `POST /api/commands/approve-account` → candidate `public.cmd_approve_account_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "target_user_id": "uuid",
  "reason": "non-empty decision rationale"
}
```

Decision is fixed by the command; caller cannot submit an alternate decision value.

### Response

```json
{
  "outcome": "APPROVED",
  "target_user_id": "uuid",
  "approval_status": "APPROVED",
  "decision_id": "uuid",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization, scope and SoD

- Require authenticated active approved approver with global identity-administration authority; exact role/grant source must be approved in the canonical permission registry.
- Actor must not equal target user.
- Target must exist, be eligible for approval and not be disabled/suspended/rejected under the final account-state transition table.
- Do not infer authority from display title or client role claim.
- The decision must be performed by a distinct actor; self-approval is a hard denial.

### Physical read/write set

- Read: target `app_users`; actor `app_users` and effective authorization grants; idempotency record.
- Write: target `app_users.approval_status` and decision metadata; append `account_decisions`; `idempotency_records`; `audit_events`.
- Preserve prior decisions; do not overwrite decision history.

### Transaction, lock and audit

- Lock target `app_users` row, then append decision record in the same transaction.
- Validate actor authority and actor != target after deriving actor from JWT.
- Conditional transition from the approved source state prevents concurrent approve/reject races.
- Append `account.approved` and decision record atomically with profile state and idempotency result.

### Typed outcomes

`APPROVED`, `ACCOUNT_NOT_FOUND` (only where disclosure is safe; otherwise generic `NOT_FOUND_OR_DENIED`), `STATE_CONFLICT`, `SOD_VIOLATION`, `PERMISSION_DENIED`, `VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Authorized approval of eligible target succeeds and creates one immutable decision.
- Self-approval, unauthorized approver, inactive approver and forged actor rejected.
- Approve/reject race produces one valid terminal decision.
- Replay returns original decision; altered reason with same key rejected.
- Audit failure rolls back both status transition and decision row.
- Target data is not disclosed to unauthorized caller.

## CMD-003 — reject-account

**Permission:** `account.approve`  
**Candidate route/RPC:** `POST /api/commands/reject-account` → candidate `public.cmd_reject_account_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "target_user_id": "uuid",
  "reason": "non-empty rejection rationale"
}
```

### Response

```json
{
  "outcome": "REJECTED",
  "target_user_id": "uuid",
  "approval_status": "REJECTED",
  "decision_id": "uuid",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Same global identity authority and actor != target SoD requirement as CMD-002.
- Target must be in a rejectable state. Rejection is a state transition, not deletion.
- Reason is mandatory and length-bounded; final minimum/maximum and any reason taxonomy require PO/privacy approval.
- No role, scope or permission is implicitly revoked/granted by this command unless a separately approved lifecycle rule explicitly requires it.

### Physical read/write set

- Read: target `app_users`; actor authorization; idempotency record.
- Write: target `app_users.approval_status`; append `account_decisions`; `idempotency_records`; `audit_events`.
- Decision history is append-only.

### Transaction, lock and audit

- Lock target account row and conditionally transition from an eligible state.
- Append decision and `account.rejected` audit event atomically.
- Audit failure rolls back the transition and decision.

### Typed outcomes

`REJECTED`, `STATE_CONFLICT`, `NOT_FOUND_OR_DENIED`, `SOD_VIOLATION`, `PERMISSION_DENIED`, `VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Authorized rejection with mandatory reason succeeds.
- Self-rejection, forged actor and unauthorized approver denied.
- Concurrent approve/reject race yields one terminal result.
- Repeated request does not create duplicate decisions.
- Audit failure rolls back; no success event on failure.

## CMD-004 — grant-role

**Permission:** `role.manage`  
**Candidate route/RPC:** `POST /api/commands/grant-role` → candidate `public.cmd_grant_role_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "target_user_id": "uuid",
  "role_code": "allowlisted-role-code",
  "valid_from": "RFC3339 timestamp",
  "valid_until": "RFC3339 timestamp|null",
  "reason": "non-empty grant rationale",
  "project_id": "uuid|null"
}
```

### Response

```json
{
  "outcome": "GRANTED",
  "user_role_id": "uuid",
  "target_user_id": "uuid",
  "role_code": "allowlisted-role-code",
  "valid_from": "RFC3339 timestamp",
  "valid_until": "RFC3339 timestamp|null",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization, scope and SoD

- Target account must be approved and active.
- Grantor must hold `role.manage` and be within an explicit delegation ceiling for the requested role and scope.
- Self-grant is denied.
- Global vs project-scoped role semantics must be explicit; `project_id` must not be ambiguously optional for roles that require scope.
- Role code must resolve to an enabled canonical role; caller cannot supply permission bundles.
- Inspector grants invoke the same T-14 qualifying-account capacity predicate as assignment eligibility changes and cap updates.

### Physical read/write set

- Read: actor and target `app_users`; role catalog; current `user_roles`; effective grantor ceiling; `project_capacity_settings` when applicable; qualifying role/assignment membership rows for Inspector cap; idempotency record.
- Write: `user_roles`; `idempotency_records`; `audit_events`; `permission.changed` audit/domain event only if the approved role-to-permission bundle changes.
- The current physical table inventory does not show a separate role-grant event table; role history must be retained through append-only audit and/or a separately approved grant-history design.

### Transaction, locks and audit

- For Inspector eligibility changes, lock the project capacity row first, then target/role rows in deterministic order. All commands that change qualifying Inspector eligibility (grant, assignment membership change, cap update, and any eligibility-reducing revoke/suspension path) must use the same serialization point.
- Enforce uniqueness/no overlapping active grant for the same principal-role-scope interval; exact exclusion/constraint strategy requires schema review.
- Insert role grant, idempotency record and audit event atomically.
- **Review finding:** CMD-005 revoke must also serialize on the same capacity row when revoking an Inspector role; otherwise a concurrent grant can race with a revoke and produce an incorrect capacity count.

### Typed outcomes

`GRANTED`, `TARGET_NOT_ELIGIBLE`, `ROLE_NOT_ALLOWED`, `DELEGATION_EXCEEDED`, `SOD_VIOLATION`, `CAPACITY_EXCEEDED`, `SCOPE_INVALID`, `STATE_CONFLICT`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Grant within delegation ceiling succeeds; above-ceiling and self-grant denied.
- Pending/rejected/suspended/disabled target denied.
- Inspector cap boundary and concurrent grant/assignment/cap update tests.
- Overlapping duplicate grants rejected or normalized according to approved interval policy.
- Replay and changed-payload replay behavior.
- Audit failure rolls back grant.
- No direct DML or unauthorized EXECUTE.

## CMD-005 — revoke-role

**Permission:** `role.manage`  
**Candidate route/RPC:** `POST /api/commands/revoke-role` → candidate `public.cmd_revoke_role_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "user_role_id": "uuid",
  "reason": "non-empty revocation rationale",
  "expected_version": 1
}
```

### Response

```json
{
  "outcome": "REVOKED",
  "user_role_id": "uuid",
  "status": "REVOKED",
  "revoked_at": "RFC3339 timestamp",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Caller must have revocation authority over the exact role and scope; grantor ceiling/revocation delegation must be checked.
- Protect last-admin/recovery principal according to a formally approved recovery rule; do not hardcode an assumed exception.
- Revoke ends validity/status; it never deletes grant history.
- Revoke of already-revoked/expired grant returns a stable no-op/state outcome and must not emit duplicate success events.
- Revoking Inspector eligibility must serialize against capacity-changing commands even if the cap is not being lowered.

### Physical read/write set

- Read: `user_roles` target; actor authorization; role catalog; `project_capacity_settings` and qualifying count if Inspector; idempotency record.
- Write: target `user_roles.status/valid_until` (exact canonical revocation representation to be chosen); `idempotency_records`; `audit_events`.
- Do not delete the original row.

### Transaction, locks and audit

- Lock capacity row first for any Inspector eligibility reduction, then role row.
- Compare `expected_version` if optimistic concurrency is retained; physical `user_roles` currently does not explicitly list a version column, so either add one to the approved schema or remove this request field.
- Persist revoke state, idempotency and `role.revoked` audit event atomically.

### Typed outcomes

`REVOKED`, `ALREADY_REVOKED`, `ROLE_GRANT_NOT_FOUND`, `DELEGATION_EXCEEDED`, `LAST_ADMIN_PROTECTED`, `STALE_VERSION`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Authorized revoke and immutable history.
- Unauthorized scope/role revoke denied.
- Last-admin protection and approved recovery-path test.
- Concurrent Inspector revoke vs grant/cap mutation serializes.
- Replay, stale version and already-revoked behavior.
- Audit failure rolls back revoke.

## CMD-006 — grant-scope

**Permission:** `scope.manage`  
**Candidate route/RPC:** `POST /api/commands/grant-scope` → candidate `public.cmd_grant_scope_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "target_user_id": "uuid",
  "scope_type": "PROJECT|SESSION|LOCATION|TEAM|ASSIGNMENT",
  "scope_id": "uuid",
  "grant_kind": "ROLE|PERMISSION",
  "grant_ref": "canonical-role-or-permission-code",
  "valid_from": "RFC3339 timestamp",
  "valid_until": "RFC3339 timestamp|null",
  "reason": "non-empty rationale"
}
```

### Response

```json
{
  "outcome": "GRANTED",
  "scope_grant_id": "uuid",
  "target_user_id": "uuid",
  "scope_type": "PROJECT",
  "scope_id": "uuid",
  "grant_kind": "ROLE",
  "grant_ref": "canonical-code",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization, scope and SoD

- Target must be approved and active; target/scope references must exist and be compatible.
- Grantor must have `scope.manage` for the exact parent scope and cannot delegate authority beyond their own effective grant ceiling.
- Self-assignment is denied under current authorization test catalogue; confirm whether any narrowly defined self-service scope exception exists before approval.
- Scope inheritance is never implicit. Parent-to-child inheritance rules must be explicit and permission-specific.
- Role and permission grants must not share an ambiguous untyped reference. The request above makes the discriminant explicit; confirm canonical model compatibility.

### Physical read/write set

- Read: actor/target `app_users`; target scope table selected by `scope_type`; role/permission catalog; grantor's effective grants; existing `user_scope_grants`; idempotency record.
- Write: `user_scope_grants`; `idempotency_records`; `audit_events`.
- Scope target validation must use a fixed allowlist of table mappings, never dynamic SQL built from client `scope_type`.

### Transaction, locks and audit

- Validate all target and grantor authority inside the transaction.
- Lock the target principal and relevant scope/grant rows in deterministic order; enforce no overlapping duplicate active grant for same user + scope + grant kind/ref + interval.
- Append `scope.changed` audit event with before/after grant identity but no sensitive payload.
- Mutation, idempotency and audit commit atomically.

### Typed outcomes

`GRANTED`, `TARGET_NOT_ELIGIBLE`, `SCOPE_INVALID`, `SCOPE_TYPE_MISMATCH`, `DELEGATION_EXCEEDED`, `SOD_VIOLATION`, `DUPLICATE_ACTIVE_GRANT`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Valid scope grant succeeds for authorized parent scope.
- Self-assignment, out-of-scope target, mismatched scope type and forged grantor denied.
- Role-vs-permission discriminator enforced.
- Parent scope does not silently grant child scope.
- Concurrent duplicate grants produce one active grant.
- Replay and audit failure rollback tested.

## CMD-007 — revoke-scope

**Permission:** `scope.manage`  
**Candidate route/RPC:** `POST /api/commands/revoke-scope` → candidate `public.cmd_revoke_scope_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "scope_grant_id": "uuid",
  "reason": "non-empty revocation rationale",
  "expected_version": 1
}
```

### Response

```json
{
  "outcome": "REVOKED",
  "scope_grant_id": "uuid",
  "status": "REVOKED",
  "revoked_at": "RFC3339 timestamp",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Caller must be authorized to revoke the exact grant under the same delegation ceiling and scope rules used for CMD-006.
- Revocation cannot widen access, rewrite history or delete the grant.
- Define impact on already-open sessions/assignments and cached authorization: effective access should be re-evaluated at command time; revocation propagation/claims invalidation is a separate explicit contract.
- Revoke of inactive/expired grant must return a stable no-op/state outcome.

### Physical read/write set

- Read: `user_scope_grants` target; actor effective grant; idempotency record; dependent assignment/session references only if approved revocation policy requires them.
- Write: `user_scope_grants` lifecycle fields; `idempotency_records`; `audit_events`.
- Physical schema does not currently state a `version` field; align expected_version with the eventual schema.

### Transaction, locks and audit

- Lock exact scope grant row; verify grantor authority over its scope and grant type.
- Update lifecycle state without hard delete; append `scope.changed` audit event.
- Commit mutation/idempotency/audit atomically; audit failure rolls back.

### Typed outcomes

`REVOKED`, `ALREADY_REVOKED`, `SCOPE_GRANT_NOT_FOUND`, `DELEGATION_EXCEEDED`, `STALE_VERSION`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Authorized revoke succeeds and leaves historical grant evidence.
- Unauthorized actor, wrong scope and forged grant ID denied without existence leakage.
- Concurrent duplicate revoke creates one transition.
- Replay, stale version and expired grant behavior.
- Audit failure rolls back.
- Subsequent authorization checks no longer honor revoked grant.

## CMD-008 — create-project

**Permission:** `project.manage`  
**Candidate route/RPC:** `POST /api/commands/create-project` → candidate `public.cmd_create_project_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "code": "normalized-project-code",
  "name": "Project name",
  "timezone": "Asia/Jakarta"
}
```

Do not accept arbitrary initial status by default. Initial status should be a server-selected non-operational state (candidate: `DRAFT`) unless PO explicitly approves another transition.

### Response

```json
{
  "outcome": "CREATED",
  "project_id": "uuid",
  "code": "normalized-project-code",
  "status": "DRAFT",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Require explicit global project-creation authority; project scope does not exist yet, so do not invent scope from client input.
- Validate code normalization, uniqueness and IANA timezone.
- Project status is controlled by lifecycle commands; create cannot create directly in CLOSED/ACTIVE/APPROVED.
- Name/code length, allowed code alphabet and case-folding rules require a shared canonical validation specification.

### Physical read/write set

- Read: actor `app_users` and effective global permission; idempotency record; unique code index.
- Write: `projects`; `idempotency_records`; `audit_events`.
- Physical schema must include server-generated ID, status default, created/updated metadata and a uniqueness rule on normalized code.

### Transaction, lock and audit

- Use unique normalized project-code constraint as the serialization authority; do not rely on preflight SELECT alone.
- Insert project, idempotency result and `project.created` audit event atomically.
- Audit failure rolls back project creation.

### Typed outcomes

`CREATED`, `DUPLICATE_CODE`, `INVALID_TIMEZONE`, `VALIDATION_FAILED`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Authorized valid project create.
- Duplicate code under case/normalization variants rejected.
- Invalid timezone and lifecycle status injection rejected.
- Concurrent same-code create yields one project.
- Replay and changed-payload replay.
- Audit failure leaves no project row.
- Direct browser DML and unauthorized EXECUTE denied.

## CMD-009 — update-project

**Permission:** `project.manage`  
**Candidate route/RPC:** `POST /api/commands/update-project` → candidate `public.cmd_update_project_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "project_id": "uuid",
  "expected_version": 1,
  "patch": {
    "name": "new name",
    "timezone": "Asia/Jakarta"
  }
}
```

Patch must be non-empty and limited to explicitly mutable fields. Code and lifecycle status are excluded unless separate approved commands govern them.

### Response

```json
{
  "outcome": "UPDATED",
  "project_id": "uuid",
  "version": 2,
  "updated_at": "RFC3339 timestamp",
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization and invariants

- Require `project.manage` and effective authority over the target project.
- Project must be in a state that permits metadata updates.
- Cannot bypass project close/reopen lifecycle or modify immutable code through generic patch.
- Empty patch, unknown fields, null-clearing without explicit semantics and stale version are rejected.

### Physical read/write set

- Read: `projects` target; actor authorization; idempotency record.
- Write: mutable project metadata and version/update metadata; `idempotency_records`; `audit_events`.
- **Schema gap:** current physical table summary lists `id, code, name, status, timezone` but does not explicitly list `version`, `updated_at` or `updated_by`. The request's `expected_version` cannot be implemented correctly until the physical specification defines the version mechanism.

### Transaction, lock and audit

- Lock target project row and compare expected version; alternatively use a single conditional UPDATE with version predicate and require exactly one row.
- Increment version atomically; append `project.updated` with safe before/after field names, not sensitive full payload.
- Update/idempotency/audit commit atomically.

### Typed outcomes

`UPDATED`, `PROJECT_NOT_FOUND`, `STALE_VERSION`, `INVALID_STATE`, `EMPTY_PATCH`, `FIELD_NOT_MUTABLE`, `VALIDATION_FAILED`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Valid metadata update increments version once.
- Stale concurrent update rejected without lost update.
- Unknown/immutable field and empty patch rejected.
- Closed project update denied unless explicitly allowed.
- Replay returns original version/result.
- Audit failure rolls back metadata and version.

## CMD-010 — close-project

**Permission:** `project.close`  
**Candidate route/RPC:** `POST /api/commands/close-project` → candidate `public.cmd_close_project_v1`; provisional only.

### Request

```json
{
  "schema_version": 1,
  "idempotency_key": "opaque-client-generated-key",
  "project_id": "uuid",
  "expected_version": 1,
  "reason": "non-empty closure rationale",
  "confirmation_token": "optional short-lived server-issued token"
}
```

The confirmation token is not an authorization credential. If retained, its issuance, binding, expiry and one-time consumption rules must be specified. Otherwise remove it from the request contract.

### Response

```json
{
  "outcome": "CLOSED",
  "project_id": "uuid",
  "closed_at": "RFC3339 timestamp",
  "version": 2,
  "blockers": [],
  "replayed": false,
  "correlation_id": "uuid"
}
```

### Authorization, scope and closure invariants

- Require explicit `project.close` permission and effective authority over the exact project.
- Project must be in a closable lifecycle state; already-closed and concurrent close attempts have stable outcomes.
- Closure dependency graph is **not yet approved**. Candidate blockers for PO confirmation: non-closed sessions; active assignments/claims; inspections in draft/submitted/returned/review states; pending evidence finalization; document generation/finalization jobs; unresolved print batches; unissued/unsigned required documents; unreconciled actual-vs-target reporting; pending sync conflicts; legal/institutional hold.
- The system must not cascade-delete operational history or silently mutate dependent records to force closure.
- T-10 institutional retention/disposition remains external; closure must not imply record deletion or retention completion.

### Physical read/write set

- Read: `projects`; sessions; assignments/members; inspections/revisions/review events; evidence lifecycle; documents; print batches/events; target/actual reconciliation; sync conflicts; legal holds if modeled; actor authorization; idempotency record.
- Write: `projects.status/closed_at/version`; `idempotency_records`; `audit_events`. No dependent record is changed by default.
- Exact dependency tables and predicates must be enumerated in the controlling ERD/schema before approval.

### Transaction, locks and audit

- Lock project row first; evaluate dependent blockers in deterministic order using transactionally consistent reads/locks sufficient to prevent a concurrent child operation from slipping past the closure check.
- All child commands that create/advance project-scoped work must reject once closure has committed. The concurrency protocol must be explicit; a plain preflight SELECT is insufficient.
- If no blockers, conditionally transition project to CLOSED and append `project.closed` audit event atomically.
- Audit failure rolls back closure. No notification/worker side effect is part of this command unless separately modeled through transactional outbox.

### Typed outcomes

`CLOSED`, `CLOSURE_BLOCKED` (with stable non-sensitive blocker codes), `STALE_VERSION`, `ALREADY_CLOSED`, `INVALID_STATE`, `PERMISSION_DENIED`, `IDEMPOTENCY_KEY_REUSED`.

### Test additions

- Eligible project closes successfully.
- Every approved blocker class independently blocks closure with no project mutation.
- Unauthorized/wrong-project caller denied without existence leakage.
- Concurrent child creation/inspection transition vs closure cannot bypass the closure gate.
- Concurrent close requests yield one transition.
- Audit failure rolls back close.
- Reopen behavior is not inferred; test remains blocked until separate reopen authority/lifecycle is approved.
- No cascade delete or implicit record disposition occurs.

## 4. Cross-command findings and required decisions

| Finding | Affected command(s) | Required resolution | Gate |
|---|---|---|---|
| Account request has no dedicated request entity; lifecycle placement in `app_users` is unclear | CMD-001 | PO/architecture decide Auth signup vs first request, pending-state owner and history model | Blocks final request schema |
| Account decision state machine and eligible source states are incomplete | CMD-002/003 | Approve complete account transition matrix and duplicate decision semantics | Blocks final transition contract |
| Role history/overlap and version representation not fully physicalized | CMD-004/005 | Define uniqueness/interval constraints, immutable grant history, version column and last-admin recovery rule | Blocks schema freeze |
| Inspector revoke must share capacity serialization point with grants and cap changes | CMD-004/005 | Align all eligibility-affecting commands on the same project capacity lock and predicate | Blocks concurrency approval |
| `permission_or_role_ref` is ambiguous | CMD-006 | Use explicit grant-kind discriminator and validate scope compatibility/inheritance | Blocks final request schema |
| Scope grant revocation/cache invalidation semantics are unspecified | CMD-006/007 | Define authorization freshness and effects on active assignments/sessions | Blocks security acceptance |
| Project status on create must not bypass lifecycle | CMD-008 | Choose server default and allowed initial state | Blocks final request schema |
| Project optimistic version fields absent from current physical summary | CMD-009/010 | Add approved version/update metadata or change contract to a fully specified alternative | Blocks physical-schema parity |
| Project closure dependencies and concurrency protocol are not approved | CMD-010 | PO + institution define closure blockers, child-command fencing and reopen authority | Blocks CMD-010 contract completion |
| Actual function owner, SECURITY mode, search_path and EXECUTE ACL not verified in Supabase | CMD-001–010 | Read-only catalog inventory and per-function security review after authorized environment access | Blocks G9/G10 |

## 5. Route/RPC mapping status

The ten candidate route/RPC pairs in this document are naming proposals only. No physical route or PostgreSQL function has been approved, created or verified. Before implementation, each mapping must have:
1. Exact HTTP method/path, request/response JSON Schema and versioning.
2. JWT forwarding and trusted actor derivation proof.
3. Exact PostgreSQL schema/function/signature and overload review.
4. Owner, SECURITY INVOKER/DEFINER decision, search_path and EXECUTE grants.
5. Explicit physical read/write set and transaction boundary.
6. Authorization/SoD/scope predicate and typed error mapping.
7. Test evidence for positive, negative, replay, concurrency, audit failure and ACL denial.

## 6. Verification status and next action

- Documentation review: **performed** against the current command catalogue, physical schema summary, audit catalogue and planned test catalogue.
- Contract implementation: **not performed**.
- PostgreSQL/Supabase runtime verification: **not performed**.
- Tests: **specifications only; not executed**.
- G9: **NOT READY**.
- G10: **NOT AUTHORIZED**.
- Institutional/provider dependencies T-10/T-12 remain open.
- CMD-045–048 remain blocked by institutional authority; this review does not change that status.
- Notification worker identity and ACL remain pending separate approval.

Next documentation-only step: resolve the cross-command decisions above with PO/security/institutional owners, then reconcile the approved CMD-001–010 contract back into the canonical catalogue and test catalogue. Do not proceed to SQL/RPC implementation until G9 is explicitly READY and G10 is explicitly AUTHORIZED.
