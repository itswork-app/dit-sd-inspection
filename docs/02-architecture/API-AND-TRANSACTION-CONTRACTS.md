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
| Documents | `generate-approved-pdf`, `record-print`, `record-print-batch` | Generate snapshot PDF; record individual or bounded batch print actions with per-document outcomes |
| Reporting | `get-actual-report`, `get-target-report` | Read distinct actual/target dimensions |

These are logical command names, not a finalized REST URL contract. Batch print is an orchestration of independently authorized per-document print commands; it is not a single all-or-nothing print-success transaction. Batch print is an orchestration of independently authorized per-document print commands; it is not a single all-or-nothing print-success transaction.

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

  "command_id": "same-command-uuid",
  "status": "accepted",
  "resource_version": 8,
  "server_time": "UTC timestamp",
  "result": {}

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

### Print and batch-print transaction (PO-approved T-13 option B)

- Verify caller identity, `document.print` permission, scope, approved inspection state and final immutable PDF version for every document.
- Enforce a configurable maximum batch size; reject an oversized request before starting any print operation.
- Persist a batch identifier and one outcome per document: success recorded, failed, or cancelled. Do not infer success for documents without an explicit successful application result.
- Allocate each document's print/reprint ordinal atomically under concurrency control and link it to the exact document version.
- Retry accepts failed document identifiers only; it must reject already successful/cancelled items and must not create duplicate success events.
- A partial batch remains partial; return per-document results and aggregate counts without claiming physical printer output.
- Browser print initiation/confirmation is an application-level event only. Direct printer integration is outside initial release.



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
- **T-09 option B is PO-approved (2026-11-23):** limited offline draft editing only for already claimed units. Offline storage activation remains gated on approved device/browser and local-data safeguards (T-10/T-11).
- Whether bulk operations are needed for field throughput.
- Rate limits and abuse protection.



## T-14 — Atomic Inspector capacity command contract (PO-approved 2026-11-24)

All commands that create/enable an Inspector role grant, establish an effective operational Inspector assignment, or change the configured cap must apply the same canonical count: distinct enabled login accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment within the governed project/session scope. Count each account once; exclude pending, rejected, suspended, disabled and expired-role accounts. Enforce the combined cap atomically across both locations (1–100, default 50). Reject cap 0, cap above 100, and reductions below the current qualifying count until reconciled. Never silently deactivate accounts. Client pre-checks are advisory only; server transaction is authoritative.


## Registration-first and Super Admin staffing command rules (PO clarification, 2026-11-24)

`request-account-access` creates/provisions a pending account only; it must not create Inspector eligibility. Super Admin-only commands approve/reject accounts, grant/revoke roles, set scopes, create/configure teams, add/remove team members, and publish/change operational assignments. These commands must reject unregistered, pending, rejected, suspended or disabled accounts as assignees; reject caller self-elevation/self-assignment; validate staffing against the session plan and combined Inspector cap in one transaction. Team count and personnel composition are Super Admin-controlled configuration, not user self-service.


## T-16 — Serial identity and evidence transaction rules (PO-approved option B, 2026-11-24)

`claim-unit` must resolve the canonical unit using `(instrument_id, serial_normalized)` across all projects; project ID is not part of the uniqueness key. Different instrument types may reuse the same serial. Before creating a unit, the command must atomically check/lock the canonical key and route a same-type cross-project collision to controlled conflict resolution rather than create a duplicate or silently merge records. Authorization remains project/session/assignment scoped even when the canonical unit is shared across projects. Conflict resolution requires an authorized actor, explicit reason, deterministic outcome and append-only audit.

Evidence commands must bind each evidence record to the exact immutable inspection revision and instrument version. Preserve checksum, uploader, capture/upload timestamps and immutable storage object identity. Finalized evidence cannot be overwritten in place; replacement creates a new evidence record/object and audit event while retaining the original history. All checks and writes must be transactional/idempotent as applicable. This contract is not implemented or tested yet.
