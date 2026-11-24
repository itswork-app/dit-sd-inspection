# Privileged Command Boundary and Transaction Specification

**Status:** Architecture decision draft — approval required before implementation  
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
| `claim-unit` / `release-unit-claim` | inspection.claim | Assignment membership; one active claim; server time; draft preserved |
| `save-draft` | inspection.edit | Assignment + claim; expected row version; draft only |
| `create-upload-intent` / `confirm-upload` | evidence.upload | Allowed slot, scope, quota, signature/size/checksum validation; pending to finalized state |
| `submit-inspection` | inspection.submit | Lock aggregate; required answers/evidence; no conflicts; immutable revision and state transition atomic |
| `return-inspection` / `approve-inspection` | inspection.review | Assigned reviewer; expected revision; no self-review; append event and transition |
| `reopen-inspection` | inspection.reopen | Explicit authority and reason; preserve approved revision; create new revision context |
| `sync-batch` | sync.apply | Actor/device scope; batch idempotency; partial result and conflict records durable |
| `generate-approved-pdf` | document.generate | Exact approved revision/template snapshot; immutable artifact metadata |
| `record-print` | document.print | Authorized print scope; monotonic per-document sequence; append-only |
| `upload-attendance-document` / `verify-attendance` | attendance.upload / attendance.verify | Session scope; authority pending PO confirmation; append replacement versions |
| `get-actual-report` / `get-target-report` | report.read | Actual/target separated; row scope; no actual timestamp rewrite |

The command names are logical. REST route names and exact payload schemas remain a later API implementation artifact.

## 7. Lock order and concurrency

Use a documented global lock order to reduce deadlocks:
1. project capacity/settings row when capacity is involved;
2. project/session/assignment row(s);
3. unit row;
4. inspection aggregate row;
5. idempotency record/key;
6. evidence/document row(s);
7. append-only event insert.

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

1. Approve this Vercel route + caller-JWT PostgreSQL command-function pattern as the standard boundary.
2. Approve exact SECURITY DEFINER exceptions after function-by-function review.
3. Confirm Inspector capacity counting predicate.
4. Confirm offline maximum retry window and idempotency retention.
5. Approve final permission codes and attendance/audit authorities.
6. Complete the table-by-table RLS catalogue review.
7. Implement only after Package K blockers and required PO/institutional decisions are resolved.

## 13. Disposition

**Command boundary:** DESIGN DRAFT COMPLETE FOR REVIEW.  
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

T-18 (command architecture and direct-DML denial) is still awaiting Product Owner approval; this document currently describes the proposed design, not an approved implementation authorization.
