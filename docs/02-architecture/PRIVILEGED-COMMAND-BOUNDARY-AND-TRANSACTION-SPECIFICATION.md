# Privileged Command Boundary and Transaction Specification

**Status:** Architecture direction PO APPROVED (T-18 option A, 2026-11-24); command-specific design and implementation gates remain open  
**Version:** 0.1.0  
**Package:** N — Trusted Command Boundary  
**Date:** 2026-11-23

## 1. Decision summary

Adopt a single explicit command boundary:
1. Browser/PWA authenticates with Supabase Auth and calls a Vercel server route for business commands.
2. The server route validates request shape, obtains the verified Supabase user session, and derives the actor from the verified session. It never trusts client-supplied actor, role, or scope.
3. The server invokes a narrowly scoped PostgreSQL function for each transactional command using the caller's authenticated Supabase JWT where supported.
4. The PostgreSQL function performs database-backed identity, approval, permission, scope, resource-state, and separation-of-duties checks, then performs the atomic state change and event writes in one transaction.
5. Direct browser table writes to privileged tables are denied by grants/RLS. Read paths use RLS-protected queries or reviewed security-invoker views.
6. Service-role credentials are not the default command identity and must not be used to bypass RLS. If a specific infrastructure task truly requires service role, isolate it to a server-only operation with explicit approval, least privilege, and audit.

This is the proposed standard pattern for the product. Any exception must have an ADR and threat-model review.

## 2. Why this boundary

- Vercel server routes provide a stable HTTP/API boundary, request validation, rate limiting, and controlled access to secrets.
- PostgreSQL functions provide a real transaction boundary for multi-row invariants and concurrency locks.
- Supabase Auth JWT allows the database to derive the authenticated subject via `auth.uid()`.
- RLS remains active for ordinary reads and database access; command functions do not become generic table-write proxies.
- The design avoids a second backend, a VPS, microservices, or an additional database.

## 3. Command execution sequence

1. Client submits command envelope and current Supabase access token/session.
2. Vercel route validates HTTP method, content type, request size, schema version, and command payload.
3. Server verifies session using Supabase Auth; reject missing/expired/invalid session.
4. Server forwards the caller's authenticated JWT to Supabase/PostgREST RPC. It does not replace it with service-role identity.
5. PostgreSQL resolves `auth.uid()` to `app_users`; verifies active/approved account.
6. Function resolves active roles, permissions, explicit scope, resource state, and separation-of-duties rules from database rows.
7. Function claims idempotency key and checks request hash.
8. Function locks required rows, validates invariants, writes aggregate state and append-only event rows atomically.
9. Function persists idempotent result and returns stable response.
10. Server maps safe domain result/error to HTTP response; secrets, SQL, stack traces, and internal identifiers are not exposed.
11. Client reconciles by server version; it never assumes success until acknowledgement.

## 4. Command function security contract

Every exposed RPC must have a command specification containing:
- stable command name and version;
- authenticated caller requirement;
- permission code;
- scope derivation rules;
- accepted resource IDs and payload schema;
- resource state preconditions;
- separation-of-duties checks;
- rows locked and lock order;
- constraints relied upon;
- idempotency scope and retention;
- event/audit writes;
- result and stable error codes;
- maximum execution time and payload size;
- positive and negative security tests.

No generic update-any-row or arbitrary SQL RPC is permitted.

### SECURITY DEFINER restrictions

Use SECURITY INVOKER by default. SECURITY DEFINER is allowed only where RLS recursion or narrowly justified internal access makes it necessary, and only if:
- function owner is a dedicated non-login owner with minimal grants;
- fixed trusted search_path (prefer empty path and fully qualified object names);
- PUBLIC execute is revoked;
- execute is granted only to required database roles;
- actor identity is derived from `auth.uid()`;
- permission/scope/state checks occur inside the function;
- no client-supplied actor or role is accepted;
- function body is reviewed and covered by unauthorized-caller tests;
- function does not return rows outside caller scope.

## 5. Direct table access policy

- Direct browser INSERT/UPDATE/DELETE is denied for all privileged domain tables.
- Direct browser writes to draft answer tables are also denied in the initial release; `save-draft` command persists draft and responses transactionally.
- Read-only SELECT is permitted only where the Table-by-Table RLS Policy Catalogue grants it.
- No browser access to idempotency records, internal sync payloads, audit write paths, or privileged authorization internals.
- No broad authenticated policy such as `USING (true)` or `WITH CHECK (true)`.
- Realtime subscriptions, if later used, must inherit the same RLS scope and must not expose cross-assignment events.

## 6. Command catalogue and transaction rules

| Command | Required permission | Transactional invariants |
|---|---|---|
| `request-account-access` | account.request | Auth UID maps to own pending profile; cannot set own role/approval |
| `approve-account` / `reject-account` | account.approve | Actor != subject; account decision append-only; role/scope grants validated |
| `grant-role` / `revoke-role` | role.manage | Cannot self-elevate; capacity row lock for Inspector grant; audit same transaction |
| `create-project` / `update-project` | project.manage | Project code unique; status transition valid |
| `create-session` / `transition-session` | session.manage / session.transition | Project scope; allowed transition; closure gates checked atomically |
| `publish-assignment` / `change-assignment-members` | assignment.manage | One location/instrument/team; published instrument version; no overlapping cross-location membership |
| `change-inspector-capacity` | capacity.manage | Lock global capacity row; count approved predicate; 1..100; reject below count |
| `create-instrument` / `save-instrument-draft` | instrument.manage | Super Admin; declarative schema allowlist; code unique; draft only |
| `publish-instrument-version` | instrument.publish | T-17 PO APPROVED (A): authorized Super Admin publishes directly without second-person approval; derive actor from trusted session; validate schema/allowlists; atomically append publication + audit; increment version; immutable snapshot |
| `register-canonical-unit` | unit.register | Normalize using published instrument policy; unique instrument+serial; lock canonical key; collision opens controlled conflict, never duplicate row |
| `associate-unit-to-project` / `end-unit-project-association` | unit.associate / unit.association.end | Verify actor authority, project and candidate unit; reason; durable association episode; audit same transaction |
| `resolve-unit-identity-conflict` | unit.identity.resolve | Authorized reviewer verifies candidate; may associate existing canonical unit or reject with reason; never silently merge/create duplicate |
| `claim-unit` / `release-unit-claim` | inspection.claim | Active unit-project association + same-project assignment + matching instrument; lock canonical unit; one active claim globally per unit; server time; draft preserved |
| `save-draft` | inspection.edit | Inspection's stored association + same-project assignment + active claim; expected row version; draft only |
| `create-upload-intent` / `confirm-upload` | evidence.upload | Allowed slot, scope, quota, signature/size/checksum validation; pending to finalized state |
| `submit-inspection` | inspection.submit | Lock aggregate; required answers/evidence; no conflicts; immutable revision and state transition atomic |
| `return-inspection` / `approve-inspection` | inspection.review | Assigned reviewer; expected revision; no self-review; append event and transition |
| `reopen-inspection` | inspection.reopen | Explicit authority and reason; preserve approved revision; create new revision context |
| `sync-batch` | sync.apply | Actor/device scope; batch idempotency; partial result and conflict records durable |
| `generate-approved-pdf` | document.generate | Exact approved revision/template snapshot; immutable artifact metadata |
| `record-print` | document.print | Authorized print scope; monotonic per-document sequence; append-only |
| `upload-attendance-document` / `verify-attendance` | attendance.upload / attendance.verify | T-08 PO APPROVED: Korlap verifies within assigned location/scope; upload and verify are separate permissions; upload never auto-verifies; append replacement versions |
| `get-actual-report` / `get-target-report` | report.read | Actual/target separated; row scope; no actual timestamp rewrite |
| `deactivate-instrument` | Permission code and scope to be confirmed; reason required | Separate from publication; authorized Super Admin; reasoned status transition; audit same transaction; never rewrites pinned versions |
| `access-evidence` / `export-evidence` | Read/export permissions to be confirmed separately | Re-check project/assignment/history authority; short-lived authorized access; audit each sensitive access/export; never expose object keys as authority |
| `close-project` | Permission code and closure authority to be confirmed | Super Admin closure only after configured session, inspection, document and actual/target reconciliation gates; reason/confirmation and audit |
| `read-audit` / `export-audit` | Explicit audit-read/export permissions to be confirmed | Least-privilege filters, reason/context where policy requires, access/export itself audited; retention/legal-hold policy remains institutional |
| `record-print-batch` | Orchestrator only; per-document `document.print` remains authoritative | Bounded batch; each item independently authorized and idempotent; partial outcomes; no all-or-nothing claim; no duplicate successful print event |

The command names are logical. REST route names and exact payload schemas remain a later API implementation artifact. The table below is a command-family inventory, not yet a complete executable contract: each row must be expanded with request/response schema, full authorization predicate, lock set/order, idempotency scope, audit event type, typed outcomes and linked test cases before implementation.

## 7. Lock order and concurrency

Use a documented global lock order to reduce deadlocks:
1. idempotency key arbitration/record for the authenticated actor + command + resource scope;
2. governed project's capacity/settings row when capacity is involved (one row serializes the combined two-location cap);
3. canonical serial-key advisory/unique-key arbitration, if registering/resolving;
4. project/session/assignment row(s), in deterministic UUID order;
5. canonical unit row(s), in deterministic UUID order;
6. unit-project association row(s), in deterministic UUID order;
7. inspection aggregate row(s), in deterministic UUID order;
8. evidence/document row(s), in deterministic UUID order;
9. append-only domain/audit event inserts.

A command locks only rows required for its invariant. Avoid holding database locks during Storage transfer, PDF rendering, or external network calls. If a command spans multiple units, lock in deterministic UUID order.

For each race-sensitive command, tests must run simultaneous transactions, not only sequential unit tests.

## 8. Idempotency contract

- Key scope: authenticated actor + command type + resource scope + idempotency key.
- Request hash: canonical serialization of schema version and semantic payload; ignore non-semantic transport headers.
- Same key and same hash: return the original final result.
- Same key and different hash: return `IDEMPOTENCY_KEY_REUSED`.
- Concurrent same-key requests: exactly one transaction performs the command; others wait/return the stored result.
- Persist a pending/processing state only within a transaction or with a recoverable lease design; no permanently stuck processing rows.
- Retention must exceed the maximum offline retry window plus operational recovery buffer. Exact duration remains open until offline window is approved.
- Authorization is rechecked before disclosing a stored result; idempotency must not become an IDOR channel.

## 9. Error contract

Stable error families:
- Authentication: `AUTH_REQUIRED`, `SESSION_INVALID`
- Account: `ACCOUNT_NOT_APPROVED`, `ACCOUNT_SUSPENDED`
- Authorization: `PERMISSION_DENIED`, `SCOPE_DENIED`, `SEPARATION_OF_DUTIES_VIOLATION`
- State/version: `INVALID_STATE_TRANSITION`, `STALE_VERSION`
- Integrity: `DUPLICATE_SERIAL`, `ACTIVE_CLAIM_EXISTS`, `ASSIGNMENT_OVERLAP`, `INSPECTOR_CAPACITY_EXCEEDED`
- Evidence: `EVIDENCE_NOT_READY`, `EVIDENCE_INVALID`, `QUOTA_EXCEEDED`
- Idempotency/sync: `IDEMPOTENCY_KEY_REUSED`, `SYNC_CONFLICT`
- General: `VALIDATION_FAILED`, `RATE_LIMITED`, `INTERNAL_ERROR`

Errors must not disclose whether an unauthorized resource exists. Use a consistent not-found/denied strategy based on the threat model.

## 10. Rate limiting and abuse controls

- Rate limit authentication-adjacent and write commands by account, IP, and command class where appropriate.
- Apply upload intent limits by user, assignment, and project.
- Bound request body, batch size, number of checklist responses, and evidence slots.
- Protect PDF generation and bulk printing against unbounded fan-out.
- Do not rely only on Vercel in-memory rate limits; use a durable/shared mechanism only if justified and approved. Initial limits can be enforced with provider-supported controls and database transactional quotas.
- Record rate-limit events without logging tokens or sensitive payloads.

## 11. Required tests

- Forged actor ID, role, location, assignment, and project in payload cannot change authorization.
- Pending/rejected/suspended account denied by every command.
- Wrong-location/wrong-session/wrong-assignment command denied.
- Direct PostgREST DML denied for privileged tables.
- RPC called by anon or unauthorized authenticated user denied.
- SECURITY DEFINER function cannot be invoked by PUBLIC and cannot leak cross-scope rows.
- Concurrent claim, submit, review, capacity grant, print sequence, and idempotency tests.
- Same key/same hash replay returns same result; same key/different hash rejected.
- Expired session, role revocation, and scope revocation during work handled safely.
- Server logs contain no access tokens, service-role keys, signed URLs, or raw evidence.

## 12. Open approvals and implementation gates

1. Expand every command-family row into a complete command contract: request/response schema, actor/permission/scope predicate, state transition, lock set/order, idempotency key/hash/retention, domain and audit event, typed outcomes, retry semantics and positive/negative/concurrency test IDs.
2. Reconcile the command inventory against T-18: instrument deactivation, evidence access/export, project closure, audit read/export and bounded batch-print orchestration must have explicit authority and per-command contracts.
3. Complete function-by-function review of any SECURITY DEFINER exception; pin search_path and minimize owner/grants.
4. Complete the table-by-table RLS and direct-DML denial catalogue and exact command EXECUTE grant matrix.
5. Confirm offline maximum retry window and idempotency retention; align with the approved T-09 offline boundary and device safeguards.
6. Complete technical review of the documented T-16 canonical unit/project association, composite foreign keys and claim scope; obtain institution-approved serial normalization/exception policy before migration.
7. Reconcile API error codes, typed outcomes and audit event catalogue; ensure every critical command has deterministic fail-closed audit behavior.
8. Implement only after Package K blockers and required institutional decisions are resolved; T-18 approval is not implementation authorization.

## 13. Disposition

**Command boundary:** ARCHITECTURE DIRECTION PO APPROVED (T-18 option A); command-family inventory exists, but command-by-command contracts and grant/test traceability remain INCOMPLETE.  
**Transport implementation:** NOT IMPLEMENTED.  
**RPCs/functions:** NONE CREATED.  
**Service-role access:** NOT CONFIGURED.  
**Security tests:** NOT EXECUTED.  
**Implementation authorization:** NOT GRANTED.



## 14. T-15 audit atomicity requirement — PO-approved (2026-11-24)

Every critical command that changes business, security or governance state must write its canonical audit event in the same PostgreSQL transaction as the state mutation. The command must return failure and roll back the mutation if the audit insert or required audit validation fails. Do not emit a success response before both state and audit event commit. The event must bind the authenticated actor, active role, authorized scope, command/action, timestamp, correlation/idempotency reference and privacy-safe change context. Evidence access/export commands must also create audit events under the approved event catalogue.

The command boundary must not expose audit update/delete operations to application callers. Audit read/export is separately permissioned. This extends the command transaction requirements; it does not waive caller-JWT authorization, RLS, least privilege, idempotency or server-side validation. T-10 retention/legal-hold and network metadata policy remain externally blocked. No implementation or tests are claimed.


## T-17 publication command contract

`publish-instrument-version` is a privileged command. It must authenticate the caller, derive actor identity server-side, require explicit `instrument.publish`, verify the caller is an authorized Super Admin, validate supported declarative field types/validation primitives, checklist ordering/applicability, expected values and evidence-slot rules, and reject arbitrary scripts/SQL/executable expressions. It atomically transitions the draft to PUBLISHED and writes the publication record plus required audit event; failure of either write rolls back the entire transaction. No second-person approval is required under PO-approved T-17 option A. The published version and children are immutable; a correction requires a new version. Deactivation is a separate reasoned/audited command. Existing assignments and historical revisions remain pinned to their selected version.

T-18 is PO APPROVED option A (2026-11-24): this Vercel route + caller-JWT PostgreSQL command-function pattern is the selected standard architecture, including direct browser DML denial. Approval does not authorize implementation; command-specific design, RLS/grants and residual gates remain open.


## T-18 — Approved command architecture and mandatory controls (2026-11-24)

**Decision:** Product Owner approved option A. The Vercel server route + caller-JWT PostgreSQL command-function pattern is the standard boundary for privileged and state-changing business commands.

### Required execution contract
1. Browser/PWA authenticates through Supabase Auth and submits a typed command envelope to a narrowly scoped Vercel route. The client cannot select an arbitrary table/function or supply an authoritative actor, role or scope.
2. Route validates HTTP method, content type, payload size, schema/version and command input; verifies the Supabase session and forwards the caller's JWT to the matching PostgreSQL function.
3. PostgreSQL derives the actor from the JWT subject (auth.uid()), resolves the application account and checks enabled/approved state, explicit permission, active role, project/session/assignment scope, target state and separation of duties. Database checks are authoritative; route checks are defense in depth.
4. Command validates transition and inputs, takes required row/advisory locks, enforces idempotency and performs the business mutation plus required domain event and INS-016 audit insert in one transaction. Audit failure or invariant failure rolls back the entire command. Return success only after commit.
5. Protected business, membership, assignment, instrument configuration/publication, audit and idempotency tables deny browser direct INSERT/UPDATE/DELETE through grants and RLS. Read access remains RLS-controlled. A command function is narrowly scoped to one business capability, not a generic DML proxy.
6. Prefer SECURITY INVOKER. Any SECURITY DEFINER function requires an explicit function-level ADR/review, pinned search_path, schema-qualified references, strict input validation, safe ownership, and minimal EXECUTE grants. Revoke default PUBLIC execution where applicable.
7. Never expose service-role credentials to the browser. Caller JWT is the default command identity. Any server-only service-role exception must be isolated, explicitly approved, least-privileged, audited and threat-modelled.
8. Use stable typed outcomes for success, unauthenticated, forbidden, invalid input/transition, conflict/stale version, idempotency mismatch and retryable infrastructure failure. Do not disclose protected resource existence or sensitive policy detail to unauthorized callers.

### Command catalogue and cross-decision consistency

Apply this contract to account approval/role and assignment changes, team staffing, session/project lifecycle, instrument draft/publish/deactivate, unit creation/duplicate resolution/claim, inspection draft/submit/review, evidence finalize/replace/access/export, document generation/print, attendance verification, project closure, audit access/export and offline sync reconciliation. Each command needs a separate request/response schema, permission, scope rule, lock/idempotency key, state invariant, audit event and positive/negative/concurrency test. T-14 capacity count, T-16 canonical serial uniqueness, association authorization and global active-claim uniqueness must be checked inside the same serialized transaction as the affected mutation. The capacity lock is the governed project's capacity-settings row and the predicate counts distinct qualifying accounts across both locations. T-17 publish-instrument-version uses the same boundary and atomic audit rule.

### Approval boundary and remaining gates

T-18 approves the architecture pattern only. It does not approve every command's detailed contract, any SECURITY DEFINER exception, a deployed RLS policy, or production service-role use. Complete command-by-command permission and transaction catalogue, table-level RLS/grant matrix, T-16 association/FK technical review and institutional serial policy, T-10 institutional policy and T-12 provider/recovery verification before implementation. No route/RPC/migration has been created and no tests have been executed.


## T-16 — Canonical unit commands and association enforcement

All unit lifecycle commands use the T-18 Vercel route + caller-JWT PostgreSQL function pattern. `register-canonical-unit` normalizes a serial using the instrument's published policy and arbitrates the unique `(instrument_id, serial_normalized)` key. A collision creates a controlled `unit_identity_conflicts` record and returns a typed conflict; it never creates a second canonical unit. `associate-unit-to-project` creates a durable association episode only after authorized verification and records actor, project, unit, reason and audit event atomically. `end-unit-project-association` ends operational membership without deleting association or inspection history. `resolve-unit-identity-conflict` may attach the proposed project to the verified existing unit or reject/close the conflict with reason; no silent merge or historical row rewrite.

`claim-unit` locks the canonical unit row before association/assignment checks, verifies the association is ACTIVE and belongs to the same project as the assignment, verifies assignment instrument equals unit instrument and caller is an effective assignment member, then checks the global active claim. A partial unique index on active `unit_claims.unit_id` is the final race guard across projects. The claim row stores association ID and project ID. `save-draft`, submit, review, evidence, document and export commands derive scope through the inspection's immutable association/project binding and re-check effective session/assignment/permission. The unit ID alone never grants scope.

Each command requires explicit request/response schema, permission, actor-derived audit envelope, idempotency scope, lock order, typed outcomes and positive/negative/concurrency cases. This is a command-contract design, not implementation.
