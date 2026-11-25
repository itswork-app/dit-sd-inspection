# CMD-001–010 Detailed Contract Review

**Status:** Engineering contract review — RBAC-003 product semantics PO-APPROVED; command contracts, canonical permissions and technical/security controls remain PROPOSAL ONLY; NOT approved for implementation  
**Version:** 0.4.0  
**Date:** 2026-11-25  
**Scope:** CMD-001 through CMD-010  
**Controls:** RBAC-003 PO-approved product semantics; T-14 Inspector capacity; T-15 append-only audit direction; T-18 Option A command boundary; full-system G9 NOT READY; G10-F1 foundation-only ACTIVE; business feature-entry gates remain applicable.

**Current gate clarification (2026-11-25):** G9-F1 foundation scope is frozen and G10-F1 foundation implementation is active under root AGENTS.md §3.2. Full-system G9 remains NOT READY; business-feature entry gates remain open. RBAC-003 approves product semantics only and does not authorize executable CMD-001–007 business mutations, SQL, schema, grants/RLS or production changes.


## 1. Purpose and non-authority

This document expands the existing PostgreSQL Command Contract Catalogue for CMD-001–010. It is a documentation-only review artifact. It does not authorize source changes, SQL, migrations, function creation, grants/revokes, live database changes, deployment, or merge.

The canonical command catalogue remains the ID and permission-code source. RBAC-003 is the authoritative PO decision for account lifecycle, role delegation, scope inheritance and revocation semantics. This document reconciles those semantics into CMD-001–007; it does not approve permission seeding, physical role grants, route exposure, function ownership, RLS, or EXECUTE ACLs.

## 2. Shared contract envelope

### 2.1 Transport and identity

- Candidate transport pattern: `POST /api/commands/{logical-command-name}`; exact route names and API version are provisional and require API contract approval.
- Candidate RPC naming pattern: `public.cmd_<logical_command_name>_v1(...)`; no function name/signature is approved or asserted to exist.
- Route validates method, content type, body size, schema version, allowlisted fields and authentication session.
- Route forwards the caller JWT. It must not accept trusted actor ID, role, permission, approval state or effective scope from the client.
- Database derives actor only from `auth.uid()`, resolves the active approved `app_users` identity and evaluates permission, validity, scope and SoD in the same transaction as the mutation.
- Anonymous and PUBLIC execution are denied. Browser roles have no direct INSERT/UPDATE/DELETE on protected tables. The actual owner, security mode, search_path and EXECUTE ACL remain unverified and must be reviewed per function against Supabase catalog evidence.
- Protected writes follow PO-approved T-18 Option A through narrow SECURITY DEFINER wrappers. Each function requires individual security approval, a dedicated least-privileged NOLOGIN owner, fixed empty search_path, schema-qualified references, PUBLIC/anon denial and exact-signature EXECUTE grants. SECURITY INVOKER remains preferred for scoped reads and non-elevated helpers.

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
- Account lifecycle is governed by RBAC-003: `app_users` is created on first successful verified Google sign-in with `PENDING` status; each access request is a separate `account_requests` record and each approve/reject outcome is an append-only `account_decisions` record. A pending request is not duplicated; an approved account does not obtain additional authority through another account-approval request; a rejected account may submit a new request.
- A request for another UID or any privilege-bearing field is rejected; never silently honor client-supplied identity.

### Physical read/write set

- Read: authenticated identity mapping in `app_users`; idempotency record.
- Write: `app_users` identity/current account state on first verified sign-in; `account_requests` for each distinct access request; append-only `account_decisions` for approve/reject outcomes; `idempotency_records`; `audit_events`.
- **Logical model approved; physical design open:** RBAC-003 approves the separation of identity, request history and decision history. Exact columns, keys, uniqueness, FKs, indexes, state projection and migration strategy require Database/Engineering/Security review.

### Transaction, lock and audit

- Resolve own `app_users` row by unique `auth_user_id`; serialize concurrent first requests with the unique constraint/upsert conflict path, not a client-selected UID.
- Persist request state, idempotency result and `account.requested` audit event atomically.
- No lock on another user's row.
- Audit failure rolls back any profile/request mutation.

### Typed outcomes

`ACCEPTED`, `ALREADY_PENDING`, `ALREADY_APPROVED`, `AUTH_REQUIRED`, `VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REUSED`, `INTERNAL_AUDIT_FAILURE`. Exact stable mapping to existing catalogue outcomes remains subject to API/QA reconciliation.

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
- Target must exist and be in `PENDING` state with an eligible active request. `REJECTED` can return to `PENDING` only through a new request; `SUSPENDED` and `DISABLED` are not approvable through the ordinary request path. Any reinstatement/recovery is a separate explicitly authorized workflow.
- Do not infer authority from display title or client role claim.
- The decision must be performed by a distinct actor; self-approval is a hard denial.

### Physical read/write set

- Read: target `app_users`; actor `app_users` and effective authorization grants; idempotency record.
- Write: target `app_users` current account status; append `account_decisions` linked to the exact `account_requests` row; update the request's current disposition only if the physical model uses a mutable projection; `idempotency_records`; `audit_events`.
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
- Rejection requires a structured category and a non-empty, length-bounded explanation. The category vocabulary and exact min/max bounds are technical/schema details to be specified; the mandatory category-plus-reason rule is PO-approved.
- No role, scope or permission is implicitly revoked/granted by this command unless a separately approved lifecycle rule explicitly requires it.

### Physical read/write set

- Read: target `app_users`; actor authorization; idempotency record.
- Write: target `app_users` current account status; append `account_decisions` linked to the exact `account_requests` row; update a request disposition projection only if the approved physical model requires it; `idempotency_records`; `audit_events`.
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
- Grantor must hold the exact canonical permission and be within an explicit, effective delegation ceiling for the requested role and scope. An actor may never delegate authority exceeding the actor's own effective authority.
- Self-grant is denied.
- Global roles and project-scoped roles are distinct authority classes. Each role definition must declare its class; project scope is mandatory for project-scoped roles and forbidden/ignored only where the canonical role definition explicitly declares a global role. No implicit project or child-scope inheritance is allowed.
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
- An ordinary revoke must not remove the last active administrator. No hard delete is permitted. Recovery must use a separately controlled, reasoned and audited break-glass process; its operator eligibility, activation, expiry and dual-control details remain technical/security design work.
- Revoke ends validity/status; it never deletes grant history.
- Revoke of already-revoked/expired grant returns a stable no-op/state outcome and must not emit duplicate success events.
- Revoking Inspector eligibility must serialize against capacity-changing commands even if the cap is not being lowered.

### Physical read/write set

- Read: `user_roles` target; actor authorization; role catalog; `project_capacity_settings` and qualifying count if Inspector; idempotency record.
- Write: target `user_roles.status/valid_until` (exact canonical revocation representation to be chosen); `idempotency_records`; `audit_events`.
- Do not delete the original row.

### Transaction, locks and audit

- Lock capacity row first for any Inspector eligibility reduction, then role row.
- The request currently carries `expected_version`, but physical `user_roles` has no approved version column. Do not implement this field until Database/Engineering either adds and verifies a concurrency token or removes/replaces the request field through controlled contract change.
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
- Self-scope assignment is prohibited; no exception is approved by RBAC-003.
- Scope inheritance is never implicit. A grant applies only to the exact declared scope and any separately approved explicit mapping; project scope does not silently confer session/location/team/assignment authority.
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
- After revocation, subsequent protected commands must revalidate current server/database authorization and deny the revoked scope. Existing assignments, sessions, inspection history and evidence remain intact; revocation does not silently abort, delete, reassign or rewrite in-progress work. Exact in-flight transaction serialization, cache invalidation and session-token freshness remain technical contracts.
- Revoke of inactive/expired grant must return a stable no-op/state outcome.

### Physical read/write set

- Read: `user_scope_grants` target; actor effective grant; idempotency record; dependent assignment/session references only if approved revocation policy requires them.
- Write: `user_scope_grants` lifecycle fields; `idempotency_records`; `audit_events`.
- Physical schema does not currently state a `version` field while the candidate request carries `expected_version`; align the request and physical concurrency token before implementation.

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
| Project/session parent fence is not consistent across child writers; CMD-011 FOR KEY SHARE may not conflict with a non-key project status UPDATE, while CMD-012/013 are session-first and CMD-015 omits explicit project/session parent locks | CMD-010–015 | Engineering/Security select compatible row-lock/serialization modes, redesign reverse-order session paths, require parent-first locks in CMD-014/015 and prove state revalidation after waits | Blocks project/session concurrency acceptance |
| Actual function owner, SECURITY mode, search_path and EXECUTE ACL not verified in Supabase | CMD-001–010 | Read-only catalog inventory and per-function security review after authorized environment access | Blocks G9/G10 |
| Mutable identity/authorization rows have no class in candidate L00–L110 lock hierarchy | CMD-001–007 | Engineering/Security resolve LPR-11: rank and same-rank order for app_users, user_roles and user_scope_grants relative to T-14 capacity, project/session parents, grantor authority and assignment membership | Blocks rank normalization and concurrency approval |

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

## 7. Historical lock-rank reconciliation checkpoint — superseded by §9

The row-level CMD-001–010 overlay in LOCK-MANIFEST-001 v0.4.5 preserves source-stated lock/transaction behavior while distinguishing candidate-rank mappings from unclassified resources.

- CMD-001–003 mutate or arbitrate app_users account identity/state. CMD-004/005 mutate user_roles. CMD-006/007 mutate user_scope_grants. None of these mutable resource classes is named in the current L00–L110 candidate hierarchy.
- Do not map these resources to L50 assignment/membership or L110 append-only facts by analogy. This historical statement that CMD-001–007 are not rank-normalized is superseded by §9's candidate normalization; LPR-11 technical approval remains OPEN.
- CMD-004/005 must share the T-14 capacity serialization point whenever a role/account mutation changes the qualifying Inspector population; the full eligibility-changing writer set is not yet proven complete.
- CMD-002/003 must share the same target-account terminal transition and uniqueness protocol; actor authorization revocation race remains unresolved.
- CMD-006/007 require an explicit order among target principal, grantor authority, scope parent and scope-grant row, plus a revocation-freshness policy.
- CMD-008 is unique-key insert arbitration; CMD-009/010 use the project parent candidate rank, but physical CAS tokens and complete parent-fence/closure-blocker coverage remain open.

No candidate rank or lock primitive is approved by this checkpoint. No source code, SQL, migration, grant, live database inspection, CI or test was executed.

## 8. Change history

- **0.3.0 — 2026-11-24:** Added the missing identity/authorization resource-class finding and LPR-11 traceability; reconciled the detailed CMD-001–010 review with the new row-level manifest overlay. Proposal status and G9/G10 boundaries unchanged.
- **0.3.1 — 2026-11-24:** Synchronized the row-level overlay reference to LOCK-MANIFEST-001 v0.4.3. No contract authority or approval status changed.
- **0.3.2 — 2026-11-24:** Added the CMD-011–015 project/session parent-fence compatibility finding and synchronized the manifest reference to v0.4.5. No lock mode or lifecycle authority was approved.


## 9. CMD-001–010 candidate lock-manifest normalization — 2026-11-24

**Status:** Candidate normalization for Engineering / Database / Security / QA review. This section supersedes the earlier source-order summaries in §§3–7 wherever they conflict. It does not approve a physical lock plan, schema, privilege model, or implementation.

### 9.1 Shared acquisition and revalidation contract

1. Derive actor identity exclusively from the caller JWT / `auth.uid()`; client actor, role, permission, approval, or scope fields are forbidden.
2. Validate the request envelope and derive the canonical semantic request hash. Claim or resolve L00 idempotency before domain locks. A same-key/same-hash replay returns the durable result only after current authorization is revalidated; a different hash rejects.
3. If a command can change the T-14 qualifying Inspector population, acquire every affected `project_capacity_settings` serialization row at L10 in ascending project UUID order before L15–L18. The affected project set may be discovered by a non-locking locator read, but must be recomputed after the capacity locks; if it changed, abort/retry rather than acquire a new lower-rank L10 row late. RBAC-003 plus T-14 define the account-state eligibility: only login-enabled `APPROVED` accounts can qualify; `PENDING`, `REJECTED`, `SUSPENDED` and `DISABLED` accounts do not count. Approval/rejection/suspension/disable and Inspector role/scope/assignment changes must use L10 whenever they change the qualifying population.
4. Acquire all required principal rows at L15 in ascending immutable user UUID order. Include both actor and target when both are involved. A nonexistent self-account row in CMD-001 is arbitrated by the unique `auth_user_id` constraint/upsert path, not by pretending a row lock exists.
5. Acquire the exact authorization rows required for the decision: L16 `user_roles` by (user_id, role_id, grant_id); then L17 `user_scope_grants` by (user_id, scope_type, scope_id, grant_kind, grant_ref, grant_id); then L18 role/permission catalogue rows by stable primary key. L18 must be immutable/frozen during ordinary commands or governed by a separately approved mutation protocol. The lock set must include the actor's grantor ceiling and any target grants whose state is part of the invariant.
6. Acquire project/session/scope resource rows at L30, then operational grouping rows at L50, only after L10–L18. For multiple parents, project before session and stable UUID order within a class. Child writers use project/session `FOR SHARE`; project state changes/closure use project `FOR NO KEY UPDATE`; session state changes use project `FOR SHARE` then session `FOR NO KEY UPDATE`. These are candidate modes requiring PostgreSQL-version and effective-call-graph review.
7. Revalidate actor account state, exact permission, grantor ceiling, target account eligibility, scope compatibility, resource lifecycle, validity interval and T-14 count after the governing locks have been acquired. For capacity and closure predicates, use a post-fence READ COMMITTED statement snapshot or SERIALIZABLE plus retry; a pre-fence REPEATABLE READ snapshot is not sufficient. Do not authorize from an earlier preflight snapshot.
8. For L10 capacity predicates and CMD-010 closure blockers, the post-lock reads must observe all transactions that committed before the serialization fence was acquired. Candidate minimum: acquire the fence, then issue the predicate/blocker read under READ COMMITTED so it receives a fresh statement snapshot; alternatively use SERIALIZABLE with explicit serialization-failure retry. Do not rely on a REPEATABLE READ snapshot established before waiting on the fence.
9. Commit the domain mutation, append-only decision/audit fact and idempotency outcome atomically. Audit failure aborts the transaction. No external I/O occurs while row locks are held.

### 9.2 Per-command candidate manifest

| Command | Candidate ordered resources and lock modes | Required post-lock revalidation | Competing paths / final arbiter | Open evidence |
|---|---|---|---|---|
| CMD-001 request-account-access | L00 idempotency; L15 caller's `app_users` row if it exists; otherwise unique `auth_user_id` INSERT/UPSERT arbiter | JWT subject maps to exactly one own Auth identity; request lifecycle allows create/update; no privilege fields accepted | Concurrent first request, duplicate retry, CMD-002/003 decision; unique auth_user_id plus one canonical request lifecycle | Physical columns/keys/FKs/unique constraints for the PO-approved app_users + account_requests + append-only account_decisions logical model; UPSERT predicate, trigger/FK edges, request-state projection and idempotent repeat outcomes |
| CMD-002 approve-account | L00; L10 capacity rows only if approved account-state transition can change T-14 eligibility; L15 actor + target app_users sorted; L16 actor role grants; L17 actor scope grants if applicable; L18 permission/role catalogue; target account decision row at L110 insert | Actor remains active and holds global account-approval authority; actor != target; target remains in an approvable source state; any affected capacity project set is unchanged; account transition is valid | CMD-003 reject race and duplicate CMD-002; target app_users row conditional state transition / unique decision identity | Physical state/version token and immutable decision uniqueness; exact permission source and actor grantor ceiling; capacity serialization when a transition changes the approved T-14 eligibility predicate |
| CMD-003 reject-account | Same order and exact shared target-account protocol as CMD-002; L10 only if this transition can change T-14 eligibility | Same actor/target/authority checks; target remains rejectable; mandatory reason; no implicit role/scope revocation unless separately approved | CMD-002 approval race; target app_users conditional transition and immutable account_decisions identity | Physical request/decision uniqueness and state/version token; reason category enum and bounds; explicit no-cascade enforcement; capacity serialization if a qualifying Inspector population can change |
| CMD-004 grant-role | L00; L10 for Inspector-eligibility-changing grant (all affected project capacity rows sorted); L15 actor + target principals sorted; L16 actor delegation grants + target role set in tuple order; L17 relevant actor scope/delegation grants; L18 role/permission catalogue; insert target user_roles at L16 under the already-held principal/catalogue locks | Actor active and authorized for exact role/scope within delegation ceiling; target approved/enabled; role enabled; interval valid; self-grant denied; Inspector predicate and capacity rechecked under L10 | CMD-005 revoke, duplicate/overlapping grants, CMD-014/015 membership, CMD-016 cap, account eligibility changes; unique/exclusion arbiter for principal-role-scope interval | Physical role/scope representation, append-only grant history, exact interval exclusion, capacity row existence, permission bundle immutability/governance and concurrency-token strategy |
| CMD-005 revoke-role | L00; L10 for Inspector eligibility reduction; L15 actor + target principal sorted; L16 actor authority rows + exact target user_role row sorted; L17 relevant delegation scope rows; L18 role catalogue if mutable | Actor may revoke exact grant and has revocation ceiling; target grant remains active/revocable; last-admin/recovery protection; Inspector count and role validity rechecked; already-revoked is stable no-op | CMD-004 grant, concurrent revoke, CMD-014/015/016, account suspension; exact user_roles row conditional update | `expected_version` has no approved physical `user_roles.row_version`; revocation representation, last-admin break-glass mechanics, immutable grant history and token strategy remain technical/security design work |
| CMD-006 grant-scope | L00; L10 if the grant can change T-14 qualifying eligibility (e.g. approved Inspector role/scope mapping); L15 actor + target principals sorted; L16 if role-grant authority is involved; L17 actor delegation rows + target duplicate-check rows sorted; L18 role/permission catalogue; L30 project/session scope parent; L50 location/team/assignment scope target as applicable | Actor has authority for exact parent scope and grant kind/ref; target active; fixed scope-type mapping; target exists, belongs to expected parent and is operationally grantable; no implicit inheritance; no overlap | CMD-007 revoke, duplicate overlapping grants, concurrent scope-parent closure/change, CMD-004/005 where role semantics overlap; unique/exclusion constraint on user + scope + kind/ref + interval | Exact scope-type-to-table map and parent chain; whether a particular explicit scope grant changes T-14 eligibility; interval exclusion, grantor-ceiling physical representation and deterministic lock order |
| CMD-007 revoke-scope | L00; L10 if this scope revocation changes T-14 qualifying eligibility; L15 actor + target principal sorted; L16 if role-derived authority required; L17 actor delegation rows + exact target grant row sorted; L18 catalogue only if its mutability affects interpretation; L30/L50 scope parent only if needed to prove current revocation authority/lifecycle | Actor may revoke the exact grant under current delegation ceiling; target grant remains active; scope identity matches; revocation effective time and authorization cache semantics are explicit | CMD-006 grant, duplicate revokes, protected commands relying on grant; conditional lifecycle update on exact grant | Physical row_version absent while request carries expected_version; grant expiry/effective-time semantics, exact in-flight transaction ordering, cache/session freshness and enforcement that active assignments/sessions/history are preserved |
| CMD-008 create-project | L00; L15 actor principal; L16 actor project-creation grant; L17 if global authority is represented by scope grant; L18 permission catalogue; L30 normalized project-code unique arbiter + project insert; create the default T-14 capacity row in the same transaction as a new project (bootstrap-only child creation) | Actor retains global project-create authority; normalized code/timezone valid; status is server-selected DRAFT; capacity default is exactly T-14 approved default; project and capacity row are both committed or neither | Concurrent same normalized code; project creation and capacity initialization; unique normalized-code constraint and unique project-capacity key | Code normalization/collation; physical capacity table/key/default; hidden trigger/FK lock edges; whether capacity row is created in same transaction or via approved migration/backfill |
| CMD-009 update-project | L00; L15 actor principal; L16 actor project.manage grant; L17 project-scope grant if required; L18 catalogue if mutable; L30 project row `FOR NO KEY UPDATE` (candidate) and CAS predicate | Actor still has project authority; project remains editable; patch is non-empty and allowlisted; code/status immutable; expected aggregate token matches; timezone change does not reinterpret persisted instants | CMD-010 close, CMD-011 session creation, every project child writer; project row lock + approved CAS/version constraint | Physical projects row_version/updated_at/updated_by absent; timezone change semantics and lock-timeout/retry policy |
| CMD-010 close-project | L00; L10 if project/session closure changes the T-14 predicate; L15 actor principal; L16 actor project.close grant; L17 exact project scope grant; L18 catalogue if mutable; L30 project row `FOR NO KEY UPDATE`; then evaluate blockers while parent fence is held. Lock session rows `FOR NO KEY UPDATE` in UUID order only if closure explicitly mutates/serializes session state; no implicit cascade is allowed | Actor retains project.close authority; project is closable; closure dependency set is complete; all child writers/finalizers obey the project parent `FOR SHARE` fence; pending durable intents are accounted for; project remains unchanged through CAS | CMD-009 update; CMD-011–054 project-scoped child writers/finalizers; project parent fence is the serialization gate, with exact blocker predicates/constraints as secondary arbiters | PO/institutional closure blocker set; T-14 closure effect; project row_version absent; pending worker/outbox policy; child-writer coverage and all implicit lock edges |

### 9.3 Authorization freshness and lock-cycle guard

- The actor's authority is itself mutable state. A command must lock the exact role/scope grant rows that justify its authorization before mutating the target. A concurrent revoke must use the same L16/L17 row and ordering; the command either commits before revoke or re-evaluates after revoke, never uses a stale preflight grant.
- For operations involving both actor and target principals, L15 rows are acquired by sorted user UUID, not actor-first/target-second. This avoids actor-target inversion when two administrators act on each other.
- For multiple project capacity rows, acquire L10 rows by ascending project UUID before any L15 lock. If a later discovery reveals a missing project capacity row, abort/retry; never acquire a late L10 after L15.
- The L10 account/project membership predicate and exact set of capacity rows are still open. A design that cannot enumerate the affected project set before L15 is not yet lock-complete.
- `roles`, `permissions` and `role_permissions` must either be frozen for normal operations with an explicit governance mechanism or included in a reviewed L18 protocol. A read-only catalog assumption without enforced immutability is insufficient.

### 9.4 Required adversarial test pairs — planned, not executed

| Pair / case | Required assertion | Test anchor |
|---|---|---|
| Concurrent first account request | One canonical request and one account identity; no duplicate side effects | TC-CMD-CONTRACT-024-001 |
| Approve vs reject same target | Exactly one valid terminal account decision; loser receives stable conflict | TC-CMD-CONTRACT-024-002/003 |
| Role grant vs revoke | One valid grant lifecycle; no overlapping active grant or lost revocation | TC-CMD-CONTRACT-024-004/005 |
| Inspector role grant/revoke vs assignment membership/cap change | All writers serialize through the same L10 rows; cap never exceeded and no silent revocation | TC-CMD-CONTRACT-024-004/005/014/015/016 |
| Scope grant vs revoke / duplicate grant | One active interval per approved scope key; revoked grant is no longer authoritative | TC-CMD-CONTRACT-024-006/007 |
| Scope grant vs project/session closure | Scope cannot be newly granted against a closed/incompatible target; no parent/scope lock inversion | TC-CMD-CONTRACT-024-006/007/010/013 |
| Concurrent same normalized project code | Exactly one project and one capacity-settings row; losing request has stable duplicate outcome | TC-CMD-CONTRACT-024-008 |
| Project update vs project close | One serial outcome; no metadata update after CLOSED and no close based on stale version | TC-CMD-CONTRACT-024-009/010 |
| Project close vs session/assignment/claim/inspection/evidence/document/print/notification finalizer | Child mutation either commits before close and is included in blockers, or waits and is rejected after CLOSED | TC-CMD-CONTRACT-024-010–054 as applicable |

All listed cases remain PLANNED / NOT EXECUTED. Exact barriers, transaction isolation, SQLSTATE assertions, lock diagnostics and test fixtures must be approved by QA/Engineering before execution.

### 9.5 Candidate normalization disposition

CMD-001–010 are **candidate-normalized at documentation level** against L00/L10/L15–L18/L30/L50/L110. RBAC-003 closes the Product Owner semantic decisions for account lifecycle, role classes/delegation, self-service prohibitions, last-admin protection, explicit scopes and revocation effects for CMD-001–007. This does not approve the command contracts, physical schema, canonical permission registry, grantor matrix, row-version strategy, RLS/ACL, lock modes, effective graph or tests. They are not technically approved, not proven acyclic, not verified against physical PostgreSQL objects and not lock-complete certified. The authoritative manifest count remains 54/54 inventoried, 0/54 certified.

## 10. RBAC-003 Product Owner semantic reconciliation — 2026-11-25

The Product Owner approved RBAC-003 without amendment. This section records how that decision constrains CMD-001–007; it is not a technical approval.

- **CMD-001:** first verified Google sign-in creates the \`PENDING\` application identity. The logical history model separates \`app_users\`, \`account_requests\` and append-only \`account_decisions\`. Pending duplicates reuse the active request; approved accounts do not gain authority through repeat account approval; rejected accounts may submit a new request.
- **CMD-002/003:** approval/rejection are distinct-actor decisions; actor != target. Approval applies to an eligible pending request. Rejection requires a structured category and bounded explanation. Every decision is append-only. Neither command silently grants/revokes roles or scopes.
- **CMD-004/005:** global and project-scoped roles are distinct; grantor authority is bounded by an explicit effective delegation ceiling; self-grant is denied; no hard delete; ordinary revoke protects the last active administrator. Any break-glass recovery is separate, reasoned and audited.
- **CMD-006/007:** scope grants are explicit and non-inheriting; self-assignment is denied. Revocation denies subsequent protected commands after server-side revalidation while preserving existing assignments, sessions, inspection history and evidence. It does not silently abort or reassign work.
- **T-14:** the approved combined Inspector capacity predicate is unchanged. Only login-enabled APPROVED accounts with an active Inspector role and an effective operational assignment qualify; all other account states are excluded. Every writer changing that population must serialize through the same approved capacity fence.
- **Still open:** canonical permission/role/grantor/SoD matrix; physical identity/request/decision/role/scope schema; account recovery and break-glass mechanism; exact row-version/CAS tokens; RLS/grants/function ACL; LPR-11 and full lock graph; route/RPC contracts; concurrency/negative QA and actual execution evidence.

Change history:
- **0.4.0 — 2026-11-25:** Reconciled RBAC-003 PO-approved semantics into CMD-001–007 and the candidate lock manifest. No command, schema, permission registry, grant, RLS, function, lock protocol or implementation was technically approved.


CMD-001–010 are **candidate-normalized at documentation level** against L00/L10/L15–L18/L30/L50/L110. They are not technically approved, not proven acyclic, not verified against physical PostgreSQL objects and not lock-complete certified. The authoritative manifest count remains 54/54 inventoried, 0/54 certified.
