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

These are logical command names, not a finalized REST URL contract. Batch print is an orchestration of independently authorized per-document print commands; it is not a single all-or-nothing print-success transaction.

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
- Lock the governed project's capacity settings row; this single row serializes the combined two-location cap.
- Validate new capacity as an integer in [1, 100]; default is 50.
- Count distinct enabled login accounts that have an active Inspector role grant and at least one currently effective operational Inspector assignment in the governed project/session scope; count each account once across both locations and multiple assignments/roles.
- Exclude pending, rejected, suspended, disabled and expired-role accounts.
- Reject a reduction below the current qualifying count; never silently deactivate accounts.
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
- `ACTIVE_CLAIM_EXISTS`, `ASSIGNMENT_OVERLAP`, `INSPECTOR_CAPACITY_EXCEEDED`, `CANONICAL_UNIT_CONFLICT`, `UNIT_ASSOCIATION_REQUIRED`, `INSTRUMENT_MISMATCH`
- `VALIDATION_FAILED`, `EVIDENCE_NOT_READY`, `EVIDENCE_INVALID`, `AUDIT_WRITE_FAILED`, `SYNC_CONFLICT`
- `IDEMPOTENCY_KEY_REUSED`, `RATE_LIMITED`, `RETRYABLE_FAILURE`, `INTERNAL_ERROR`

These codes are a proposed stable baseline to reconcile with every PostgreSQL function and route response; they are not yet an approved exhaustive enum. Unauthorized callers must not receive resource-existence details.

## 8. Open decisions

- **T-18 PO APPROVED option A (2026-11-24):** all protected browser-facing state-changing commands use a Vercel server route that verifies the Supabase caller session and forwards the caller JWT to a narrowly scoped PostgreSQL command function. PostgreSQL derives actor identity with auth.uid() and performs permission, role, project association, session, assignment, state and separation-of-duties checks inside the transaction. Protected-table browser INSERT/UPDATE/DELETE is denied; exact command-specific EXECUTE grants and RLS policies remain design/review gates.
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


## T-18 — Approved transport and privilege boundary reconciliation

The former open transport choice is closed at Product Owner level. The selected flow is Browser/PWA → Vercel server route → PostgreSQL command function with the authenticated caller JWT. The route validates request/session and forwards caller identity; it must not replace the caller JWT with a service-role identity for user-initiated commands. PostgreSQL derives the actor from `auth.uid()`, resolves the approved/enabled application account, and validates permission, role, project association, session, assignment, resource state and separation of duties before mutation.

Browser-facing anon/authenticated roles receive no direct INSERT/UPDATE/DELETE on protected business or governance tables. Reads remain independently RLS-scoped. Only narrow, explicitly granted command functions may mutate protected state. Every critical mutation and its required audit event commit atomically; audit failure rolls back the mutation. SECURITY DEFINER exceptions require pinned search_path, schema-qualified references, strict input validation, least-privileged ownership and minimal EXECUTE grants.

## T-16 — Canonical unit association command context

A canonical unit is resolved by `(instrument_id, serial_normalized)` across projects. The project is not part of the uniqueness key. `register-canonical-unit` creates or resolves the canonical identity; `associate-unit-to-project` and `end-unit-project-association` manage durable project-membership episodes; `resolve-unit-identity-conflict` handles same-instrument serial collisions without cloning or silently merging canonical units. Claim, draft, submit, review, evidence and document commands must bind to the exact association + project + same-project assignment and must not infer authorization from unit ID alone. The global active-claim invariant serializes claims across projects.

These decisions are design-only. Exact endpoint payloads, grant matrix, institutional serial normalization/exception policy, migrations and tests remain open; no implementation is claimed.


## Command-by-command closure requirements (T-18)

The command list in this document is a capability inventory, not yet a complete route/RPC contract. Before implementation, each logical command must have its own versioned request and response schema, permission code, server-derived actor rule, project/session/assignment scope predicate, state-transition guard, lock set/order, idempotency scope and request hash, audit event type, typed outcome/error mapping, retry semantics and positive/negative/concurrency test references.

The inventory must include, in addition to the currently enumerated commands: instrument deactivation; evidence access and export; project closure; audit read and export; and bounded batch-print orchestration. Batch print remains a per-document sequence of independently authorized/idempotent print commands, not an atomic all-or-nothing mutation. Permission codes for the additional privileged operations must be explicitly confirmed in the permission catalogue rather than inferred from broad Super Admin status.

T-14 capacity commands use the exact approved qualifying-account predicate and the project capacity-settings row lock across both locations. T-16 unit commands require canonical serial-key arbitration, durable project association and global active-claim serialization. No command may infer operational authorization from global catalog authority or canonical unit identity alone.

## PostgreSQL individual command contract catalogue

The 48-operation draft contract catalogue is maintained in [PostgreSQL Command Contract Catalogue](POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md). It defines proposed request allowlists, actor/scope/SoD, physical read/write references, lock/idempotency/audit rules and typed outcomes per logical command. Its names and fields are proposals, not approved REST routes or PostgreSQL signatures. See its explicit blockers for T-10, T-12, T-16, Storage, project closure and ERD-only objects. No implementation is authorized by the catalogue.

## Function execution model and database ACL gate

The route-to-RPC contract must follow [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md). User commands preserve the caller JWT. Do not use service_role to work around authenticated table ACLs. The SECURITY INVOKER versus protected-table DML boundary must be resolved before RPC implementation.

## NLA-001 — Notification lifecycle and worker transaction contracts (proposed)

### Recipient inbox read
- `list-own-notifications` is a read-only query restricted to `recipient_user_id = auth.uid()` with cursor/filter binding to the actor. It does not reveal source-resource details outside the recipient's scope.
- `mark-notification-read` is idempotent and sets `read_at` once using server UTC. It cannot update delivery state or business state.

### Policy publication
- Policy changes create a new immutable `notification_policy_versions` row after strict schema/allowlist validation and permission/scope/SoD checks. Publishing and its audit event are atomic. Existing outbox rows retain their pinned policy version.

### Outbox fan-out
- The originating domain command writes its domain event, audit event and minimal outbox intent atomically. Failure to persist audit or outbox intent rolls back that source command.
- Internal fan-out claims a bounded lease, resolves recipients from the pinned policy, deduplicates recipient selectors and creates one inbox row and per-channel delivery projection idempotently. No provider I/O occurs in the transaction.

### Provider dispatch and retry
- Worker claims a delivery lease, appends an attempt record and performs provider I/O outside a database transaction. Completion is guarded/idempotent. Use provider idempotency where supported; otherwise represent ambiguous acceptance as UNKNOWN and reconcile before claiming success.
- Retry is bounded and policy-controlled; routine delivery failure never blocks or rolls back the underlying business command.

### SLA/reminder/escalation
- Evaluate policy-version-pinned thresholds using server time. Append one unique escalation event per notification/policy/step/type. Enqueue another notification only after recipient scope is revalidated. Never change source business state.

Worker identity, scheduler authentication, database role, function owner and exact EXECUTE ACL remain a separate T-18 security approval. CMD-052..054 must not be browser-callable.
