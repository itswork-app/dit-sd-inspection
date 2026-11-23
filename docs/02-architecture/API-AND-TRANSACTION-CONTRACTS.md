# API and Transaction Contracts — Dit. SD Inspection

Status: Application command design draft — endpoint implementation not authorized  
Version: 0.1.0

## 1. Contract principles

- Prefer explicit business commands over generic table CRUD.
- Every command authenticates identity and checks application approval, permission, scope, resource state, and separation of duties.
- Validate all payloads server-side; browser validation is usability only.
- Use idempotency for retryable writes and offline sync.
- Use database transactions for multi-row invariants.
- Return stable machine-readable error codes; never expose secrets or internal SQL.
- Commands are versioned; breaking changes require compatibility and migration planning.

## 2. Candidate command surface

| Capability | Command | Purpose |
|---|---|---|
| Account | `request-account-access` | Create/update pending application profile |
| Admin | `approve-account` / `reject-account` | Approve and assign authorized role/scope |
| Planning | `create-session`, `publish-assignment` | Create operational plan and explicit assignments |
| Planning | `change-inspector-capacity` | Change global Inspector cap within 1..100 |
| Unit | `claim-unit` | Atomically claim normalized serial identity |
| Unit | `release-unit-claim` | Voluntary release with safe draft preservation |
| Inspection | `save-draft` | Persist draft and checklist response changes |
| Evidence | `create-upload-intent`, `confirm-upload` | Controlled private media lifecycle |
| Inspection | `submit-inspection` | Validate and append immutable submitted revision |
| Review | `return-inspection`, `approve-inspection` | Reviewer decision with separation-of-duties |
| Review | `reopen-inspection` | Authorized reopen with reason |
| Offline | `sync-batch` | Idempotently apply offline draft operations |
| Documents | `generate-approved-pdf`, `record-print` | Generate snapshot PDF and record print event |
| Reporting | `get-actual-report`, `get-target-report` | Read distinct actual/target dimensions |

These are logical command names, not a finalized REST URL contract.

## 3. Standard request envelope

```json
{
  "command_id": "client-generated-uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "resource_id": "uuid",
  "expected_version": 7,
  "payload": {}
}
```

The exact payload is command-specific. Do not accept actor role, user ID, or effective scope as authoritative client input; derive these from authenticated server/database state.

## 4. Standard response envelope

```json
{
  "command_id": "same-command-uuid",
  "status": "accepted",
  "resource_id": "uuid",
  "resource_version": 8,
  "server_time": "UTC timestamp",
  "result": {}
}
```

For validation or conflict errors, return a stable code, safe message, and relevant current version/state when disclosure is authorized.

## 5. Idempotency

- Idempotency key is scoped to authenticated actor + command type + resource scope.
- Persist request hash and final result reference.
- Same key + same request hash returns the original result.
- Same key + different request hash returns `IDEMPOTENCY_KEY_REUSED`.
- Concurrent requests with the same key serialize to one logical execution.
- Retention duration is an open policy decision; it must exceed the maximum offline retry window.

## 6. Critical transaction contracts

### Claim unit
- Normalize serial according to approved instrument rules.
- Begin transaction; lock relevant unit/claim key.
- Verify active assignment and user Inspector membership.
- Check existing active claim and duplicate inspection rules.
- Create claim and inspection draft atomically.
- Return existing authorized draft for resume where policy permits; otherwise return conflict.
- Never create two active claims for one unit.

### Offline synchronization (`sync-batch`)
- Accept only operations for an inspection draft whose unit was claimed while online.
- Authenticate the caller and re-evaluate current role, assignment scope, claim ownership, claim validity and inspection state for every batch.
- Require stable operation IDs/idempotency keys; same key and same request returns the original result, while key reuse with a different payload is rejected.
- Enforce dependency ordering between draft metadata and evidence; acknowledge media only after server-side object verification.
- Reject stale expected versions with a structured `SYNC_CONFLICT` response containing only authorized current-state/version details.
- Preserve queued client data and server state; resolution must be explicit and authorized. No last-write-wins.
- Never permit this command to claim a unit, approve, final-submit, change roles/assignments, administer sessions or execute privileged actions.

### Submit inspection
- Lock inspection aggregate and verify expected draft version.
- Verify active claim/assignment, instrument snapshot, required checklist answers, exception reasons, and verified evidence.
- Verify no unresolved sync conflicts.
- Append immutable inspection revision and submission event.
- Transition aggregate to SUBMITTED in the same transaction.
- Repeated command with same idempotency key returns same revision; stale expected version returns conflict.

### Approve inspection
- Lock inspection aggregate.
- Verify reviewer permission and assignment scope.
- Verify reviewer is not author of the submitted revision.
- Append review event and transition state atomically.
- Never mutate submitted revision payload.

### Change Inspector capacity
- Lock the global capacity settings row.
- Validate new capacity as an integer in [1, 100]; default is 50.
- Count distinct active Inspector accounts across both locations.
- Reject a reduction below current active count.
- Update capacity and append audit event in the same transaction.

## 7. Error code baseline

- `AUTH_REQUIRED`, `ACCOUNT_NOT_APPROVED`, `PERMISSION_DENIED`, `SCOPE_DENIED`
- `RESOURCE_NOT_FOUND`, `INVALID_STATE_TRANSITION`, `STALE_VERSION`
- `ACTIVE_CLAIM_EXISTS`, `ASSIGNMENT_OVERLAP`, `INSPECTOR_CAPACITY_EXCEEDED`
- `VALIDATION_FAILED`, `EVIDENCE_NOT_READY`, `SYNC_CONFLICT`
- `IDEMPOTENCY_KEY_REUSED`, `RATE_LIMITED`, `INTERNAL_ERROR`

## 8. Open decisions

- Exact transport: server route, database RPC, or hybrid per command.
- REST path naming and API versioning.
- Authentication/session refresh strategy.
- Idempotency retention and conflict resolution UX.
- T-09 option B is PO-approved; offline storage activation remains gated on approved device/browser and local-data safeguards (T-10/T-11).
- Whether bulk operations are needed for field throughput.
- Rate limits and abuse protection.
