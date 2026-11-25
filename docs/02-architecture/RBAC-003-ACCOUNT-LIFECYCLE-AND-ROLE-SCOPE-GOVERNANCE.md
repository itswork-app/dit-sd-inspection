# RBAC-003 — Account Lifecycle, Role and Scope Governance

**Document ID:** RBAC-003  
**Version:** 0.1.0  
**Status:** PO-APPROVED PRODUCT SEMANTICS — TECHNICAL DESIGN OPEN  
**Decision date:** 2026-11-25  
**Authority:** Product Owner / sole repository maintainer  
**Canonical decision:** [Decision Register — RBAC-003](../00-project-charter/DECISION-REGISTER.md)  
**Related decisions:** RBAC-001, RBAC-002, T-14, T-15, T-18  
**Related commands:** CMD-001–007

## 1. Purpose and authority

This specification records the eleven RBAC-003 recommendations explicitly approved by the Product Owner without amendment on 2026-11-25. It is authoritative for the product semantics listed below.

Approval of product semantics is not approval of a physical database design, canonical permission seed, role/grantor matrix, API/RPC signature, SQL, migration, PostgreSQL grant, RLS policy, SECURITY DEFINER function, lock mode, concurrency proof, implementation or production operation.

If an existing lower-level proposal conflicts with this specification, reconcile the proposal to RBAC-003. Do not silently change RBAC-001, RBAC-002 or T-14.

## 2. Normative invariants

1. Authentication establishes a verified identity, not operational authorization.
2. A newly created application account is PENDING; it has no operational permissions until separately approved, granted the necessary role and assigned the required explicit operational scope.
3. Multiple roles per account remain allowed under RBAC-002. Every role and scope grant is explicit and independently revocable.
4. Authorization is enforced server-side and at the database boundary. Client-supplied actor, account status, role, permission, grantor authority or scope is never trusted.
5. Every approval, rejection, role grant/revoke, scope grant/revoke and recovery action is attributable, reasoned where required, auditable and protected against self-escalation.
6. No role, project, session, location, team or assignment scope is inherited implicitly.
7. Revocation must affect subsequent protected authorization decisions without silently rewriting historical or in-progress business records.

## 3. Account lifecycle

### 3.1 Identity creation

- Create the app_users logical identity on the first successful Google sign-in after the Supabase Auth identity has been verified server-side.
- The new application account starts with status PENDING.
- Google authentication, email verification, profile completion or successful callback does not grant operational access.
- A pending account remains outside the effective Inspector-capacity population defined by T-14.

### 3.2 Logical history model

The approved logical separation is:

| Logical entity | Responsibility | History rule |
|---|---|---|
| app_users | Auth-backed application identity and current account state | One canonical application identity per Auth identity; mutable current-state projection |
| account_requests | One row per distinct request for operational access | Preserve prior requests; do not overwrite a rejected request with a later request |
| account_decisions | Approve/reject decision facts linked to the exact request and target | Append-only; no hard delete or in-place rewriting |

These are logical entity responsibilities, not a physical schema approval. Exact table/column names, primary and foreign keys, uniqueness, indexes, constraints, state projection, migration and retention remain subject to Database/Engineering/Security review.

### 3.3 Account states and ordinary transitions

| Current state | Allowed ordinary transition | Guard |
|---|---|---|
| PENDING | APPROVED | Eligible request; authorized approver; actor != target |
| PENDING | REJECTED | Eligible request; authorized approver; actor != target; mandatory category and bounded reason |
| REJECTED | PENDING | A new access request creates a new request record; prior request/decision remains immutable |
| APPROVED | SUSPENDED | Explicit authorized, reasoned and audited action |
| APPROVED | DISABLED | Explicit authorized, reasoned and audited action |
| SUSPENDED | APPROVED | Explicit authorized reinstatement decision; never automatic |
| SUSPENDED | DISABLED | Explicit authorized action |

DISABLED is not automatically reactivated. Any exceptional recovery from DISABLED requires a separately specified and authorized recovery workflow; it is not part of ordinary account approval.

All state transitions are conditional and concurrency-safe. No implicit role or scope grant/revoke is coupled to account approval or rejection. Account suspension/disable must remove the account from future authorization and from the T-14 qualifying population where applicable, but the exact shared capacity fence and transaction protocol remain technical work.

### 3.4 Repeat request behavior

- A second request while an equivalent request is pending must not create a parallel active request; return/reference the existing active request.
- An already approved account does not gain new roles or scopes by submitting another account-approval request. Additional authority requires the separate role/scope grant workflows.
- A rejected account may submit a new request. The new request has a new identity and links to the same application account; prior request and decision history remain preserved.
- Idempotent retries of the same semantic request return the original durable result. Reuse of the same idempotency key with a different semantic payload is rejected.

Exact public outcome codes and physical uniqueness constraints remain API/Database/QA decisions.

### 3.5 Rejection rationale

- A rejection must contain a structured category and a non-empty, length-bounded explanatory reason.
- The decision and its reason are stored in the append-only decision history.
- The exact category vocabulary and minimum/maximum character bounds must be specified in the physical/API contract. This detail must not weaken the mandatory category-and-reason requirement.
- Any user-facing disclosure policy must avoid exposing sensitive internal security or administrative notes.

## 4. Role governance

### 4.1 Role classes

- **Global role:** authority whose canonical definition applies at the platform/organization level.
- **Project-scoped role:** authority valid only within one explicitly identified project.
- Each canonical role definition must declare its class. A project-scoped role must have a project scope; a global role must not be made project-scoped by client input.
- An account may hold multiple roles, consistent with RBAC-002.
- A role grant does not, by itself, create an operational assignment, team membership, session assignment or unit claim. Those remain separate domain concepts and commands.

The exact global-role and project-role inventory, permission bundles and legacy-code mapping remain open in the canonical permission registry.

### 4.2 Grantor delegation ceiling

- A grantor may grant or revoke only the exact authority within the grantor's own effective, current delegation ceiling.
- Delegation cannot create authority the grantor does not possess.
- The ceiling is checked server-side against the canonical permission and grant records at the time of the command.
- A role's display label or a client-supplied role claim is not proof of delegation authority.
- Grantor authority and the target grant being changed must be revalidated under the approved concurrency protocol.

### 4.3 Separation of duties and self-service prohibitions

The following are hard denials:

- self-approval of an account request;
- self-grant of a role;
- self-assignment of a scope;
- using a grant to exceed the actor's own delegation ceiling;
- changing client-controlled profile or metadata to elevate role, permission, account state or scope.

No narrow self-service exception is approved by RBAC-003.

### 4.4 Last active administrator protection

- An ordinary grant/revoke/account-state operation must not reduce the active administrator set to zero.
- The last active administrator cannot be revoked, suspended or disabled through the ordinary path if that would leave no active administrator.
- No role or grant history is hard-deleted.
- Recovery from an administrator lockout uses a separately controlled, reasoned and audited break-glass process.

The exact definition of active administrator, recovery operator eligibility, dual-control requirement, activation/expiry, emergency credential custody and audit review are technical/security design items. Until that process is approved, ordinary operations fail closed when they would remove the last active administrator.

## 5. Scope governance

### 5.1 Explicit scope only

Scope grants must identify the exact target scope and grant kind. Supported scope concepts may include project, session, location, instrument, team and assignment, but the canonical mapping and parent relationships must be explicit.

There is no implicit inheritance:
- project scope does not automatically grant session scope;
- session scope does not automatically grant location/instrument/team/assignment scope;
- location or team membership does not silently grant a role;
- an Inspector role does not by itself create an effective operational assignment.

The canonical permission registry must define which exact role/permission may be used at each scope type. The database must validate scope existence and parent compatibility using a fixed allowlist, not dynamic client-directed table selection.

### 5.2 Scope revocation

- Revocation is recorded; it does not delete the grant history.
- Subsequent protected commands must revalidate current server/database authorization and deny a revoked grant.
- Authorization cannot rely only on stale JWT role/scope claims or a long-lived client cache.
- Existing assignments, sessions, inspection history, revisions and evidence remain intact.
- Revocation does not silently abort a session, reassign an Inspector, delete evidence, rewrite a submitted inspection or change an already-recorded outcome.
- Any workflow action required for already-running work must follow its own approved domain command/state transition and audit rules.
- A command already in flight must serialize against the relevant grant revocation so the outcome is deterministic; exact lock order, isolation and cache/session invalidation behavior remain technical design work.

## 6. T-14 Inspector capacity compatibility

RBAC-003 does not change or reopen T-14.

The approved combined capacity remains 1–100 accounts, default 50. Count a distinct account once only when it is:
1. login-enabled;
2. in APPROVED account state;
3. holding an active Inspector role grant; and
4. holding at least one currently effective operational Inspector assignment in the governed project/session scope.

PENDING, REJECTED, SUSPENDED, DISABLED, expired-role and unassigned accounts do not count. Registration alone does not count. Every account, role, scope, team/membership, assignment or capacity mutation that changes the qualifying population must use the same approved serialization point. The complete writer inventory and lock proof remain open.

## 7. Command reconciliation

| Command | RBAC-003 semantics that must be enforced | Technical closure still required |
|---|---|---|
| CMD-001 request-account-access | Verified first sign-in creates PENDING identity; separate request history; no privilege fields; idempotent repeat behavior | Physical entities/keys/constraints, upsert arbitration, exact outcome schema, audit and concurrency |
| CMD-002 approve-account | Authorized global identity approver; actor != target; eligible pending request; append-only decision; no implicit role/scope grant | Canonical permission source, exact request eligibility, decision uniqueness, row/version token, capacity fence if predicate changes |
| CMD-003 reject-account | Same SoD and authority boundary; mandatory category + bounded reason; append-only decision; no implicit role/scope cascade | Category/length contract, physical decision schema, uniqueness, state concurrency and capacity fence |
| CMD-004 grant-role | Global/project class explicit; grantor ceiling; target approved/active; self-grant denied; no role-based implicit assignment | Canonical role/permission/grantor/SoD registry, interval uniqueness, grant history, schema and T-14 lock integration |
| CMD-005 revoke-role | Grantor ceiling; no hard delete; protect last active administrator; separate break-glass recovery | Revocation representation, physical version token, last-admin invariant, capacity lock and adversarial tests |
| CMD-006 grant-scope | Exact explicit scope; target/scope compatibility; grantor ceiling; self-assignment denied; no inheritance | Scope type/table map, parent chain, permission mapping, interval uniqueness, schema and lock order |
| CMD-007 revoke-scope | Deny subsequent access after authoritative revalidation; preserve active work/history; no silent abort/reassignment | Physical version token, revocation linearization, cache/session freshness, lock order and negative/race tests |

Candidate route/RPC names and permission labels in detailed reviews remain proposals until reconciled against the canonical command catalogue and approved permission registry.

## 8. Required security and QA evidence

The following are required before any CMD-001–007 implementation can pass its feature-entry gate:

- positive and negative authorization tests for every global/project role and scope combination;
- self-approval, self-grant, self-assignment and delegation-ceiling denial tests;
- pending/rejected/suspended/disabled account denial tests;
- duplicate first-login, duplicate request and approve-vs-reject race tests;
- append-only decision and grant-history integrity tests;
- last-active-administrator protection and break-glass recovery tests;
- explicit non-inheritance tests across project/session/location/instrument/team/assignment;
- revoke-vs-protected-command concurrency tests proving a deterministic authorization boundary;
- T-14 capacity races across account, role, scope, team, assignment and cap changes;
- direct browser DML denial, RLS isolation and exact function EXECUTE ACL verification;
- audit failure rollback and idempotency replay tests;
- migration tests from empty and upgraded database states.

These are required test definitions, not evidence that tests have been authored or executed. No test is PASS until executed and tied to the exact commit/schema/environment.

## 9. Open technical work — not PO decisions

1. Canonical role and permission registry, exact global/project role inventory, grantor ceiling and SoD matrix.
2. Physical app_users, account_requests, account_decisions, user_roles and user_scope_grants schema, constraints, history, keys and indexes.
3. Account linking, duplicate Auth identity arbitration, lost-access recovery and break-glass workflow.
4. Exact role/scope interval and revocation representation.
5. expected_version/row_version parity: candidate CMD-005 and CMD-007 requests carry expected_version, while the current physical schema summary does not define matching version fields.
6. LPR-11 identity/authorization lock ranks, deterministic same-rank order, actor/target/grantor lock coverage and effective lock graph proof.
7. Complete L10 capacity-project discovery and all eligibility-changing writer inventory.
8. Authorization freshness, cache invalidation, session behavior and revocation linearization.
9. Table-by-table RLS, grants, function owner/security mode/search_path/EXECUTE ACL and caller-JWT propagation.
10. Route/RPC request/response contracts, typed errors, QA fixtures and executed negative/concurrency evidence.

No item in this list is closed by PO approval alone.

## 10. Change history

- **0.1.0 — 2026-11-25:** Initial controlled specification of the eleven RBAC-003 Product Owner-approved semantics. Technical design and implementation remain open.
