# PostgreSQL Function Security & EXECUTE Grant Design

**Status:** TECHNICAL SSOT CLOSED — T-18 Option A Hybrid Function Security & Exact ACL Design finalized for G9-TECH freeze (live catalog introspection & runtime verification gated to G11)  
**Version:** 1.0.0 | **Date:** 2026-11-27  
**Depends on:** T-18 option A; PostgreSQL Command Contract Catalogue v1.0.0; Physical Schema v1.0.0 and 62-table RLS Catalogue v1.0.0; Canonical Permission Registry v1.0.0.

## 1. Purpose and strict boundary

This document defines the intended PostgreSQL function privilege model and maps the 54 proposed operations to function security classes and caller roles. It is a review artifact only. It does not create functions, roles, schemas, ACLs, grants, revokes, migrations, policies or runtime tests.

**Important:** PostgreSQL function EXECUTE permission is not the same as business authorization. An EXECUTE grant only permits invocation. Every exposed function must still authenticate the caller, derive actor from `auth.uid()`, check account status, approved permission, scope, resource state and SoD, and enforce invariants transactionally.

## 2. T-18 execution-model decision — PO APPROVED Option A

The Product Owner approved **Option A: narrow SECURITY DEFINER command wrappers** on 2026-11-24. This resolves the prior compatibility blocker between (a) denying direct browser DML on protected tables and (b) executing protected writes through the caller's authenticated database role.

Approved hybrid model:
- Protected state-changing commands use individually reviewed, narrow SECURITY DEFINER functions owned by a dedicated least-privileged NOLOGIN role.
- Read-only functions/queries use SECURITY INVOKER where feasible, with RLS and least-privilege SELECT.
- Internal helpers are not exposed through PostgREST and receive only exact internal EXECUTE privileges.
- Browser roles retain no direct INSERT/UPDATE/DELETE on protected business/governance tables.
- Caller JWT is forwarded through the approved Vercel → Supabase/PostgREST path; PostgreSQL derives actor using auth.uid().
- No user command is executed as service_role.

This approval selects the execution model only. It does **not** approve any exact function, owner role, signature, grant, table ACL, RLS policy, route mapping, migration, or implementation. Option B is not selected. Option C remains incompatible with T-18.

### Mandatory SECURITY DEFINER owner and function controls

Every protected-write definer function must be reviewed individually. Its dedicated NOLOGIN owner must not be SUPERUSER, BYPASSRLS, CREATEROLE, LOGIN, protected-table owner, or inherit table-owner/migration/service-role privileges. Grant only minimum required object privileges. A table-owner exception is outside the baseline and requires a separate explicit security/PO exception, FORCE ROW LEVEL SECURITY and updated threat-model review.

Every function must use fixed `SET search_path = ''`, fully schema-qualified references, no client-controlled dynamic SQL, exact-signature EXECUTE grants, PUBLIC/anon denial, strict input allowlists, caller-JWT actor derivation, database-backed permission/scope/state/SoD checks, deterministic locking, idempotency, atomic mutation+event+audit, and rollback on audit failure. Do not accept caller-supplied actor, role, permission or scope as trusted. Never grant browser authenticated table DML to make SECURITY INVOKER writes work; never substitute service_role.

SECURITY INVOKER remains preferred for scoped reads and non-privileged helpers. SECURITY DEFINER does not automatically preserve RLS: verify effective owner privileges, table ownership, FORCE RLS, memberships and ACLs. SQL Editor checks alone do not prove the real HTTP caller-JWT path.

See [T-18 Execution Model Security Review](T18-EXECUTION-MODEL-SECURITY-REVIEW.md) for the approved model, threat controls, acceptance evidence and remaining gates.

## 3. Supabase/PostgreSQL trust principals

These are conceptual principal classes; actual role existence, memberships, attributes and schema ownership must be introspected in the target Supabase project before any migration.

| Principal | Intended purpose | Browser exposure | User-command execution |
|---|---|---|---|
| `anon` | Unauthenticated PostgREST requests | Public client key only; no protected data access | No |
| `authenticated` | Caller JWT subject for ordinary user requests | Browser session | Only exact reviewed RPC EXECUTE grants; no protected table DML |
| `service_role` | Trusted server-only maintenance/integration use, subject to explicit need | Never | Not the identity for user-initiated commands; bypass-RLS capability makes broad use unacceptable |
| Migration/owner principal | Schema, DDL and migration lifecycle | Never | No runtime command traffic |
| Dedicated function owner (candidate) | Own only specific hardened SECURITY DEFINER functions | Never; non-login | Function owner only; no general application login |
| Internal worker principal (if later approved) | Outbox, document rendering callbacks or scheduled maintenance | Never | Separate workload identity and command contract; not a substitute for caller identity |

Never assume a role name, NOLOGIN attribute, BYPASSRLS flag, membership or schema privilege from a template. Inspect `pg_roles`, `pg_auth_members`, `information_schema.role_table_grants`, `information_schema.routine_privileges`, `pg_proc`, `pg_namespace`, `pg_class`, `pg_default_acl` and Supabase project configuration in a controlled environment.

## 4. Function classes and grant policy

| Class | Function purpose | Security mode | Caller ACL | Internal authorization |
|---|---|---|---|---|
| F1 | Protected business mutation commands CMD-001..040 | narrow SECURITY DEFINER under PO-approved Option A; per-function security approval and evidence required | Exact signature EXECUTE to `authenticated`; PUBLIC and `anon` denied | Mandatory JWT actor + active account + canonical permission + scope + state + SoD + audit/idempotency |
| F2 | Scoped read commands CMD-041..044 when implemented as RPC | SECURITY INVOKER preferred | Exact EXECUTE to `authenticated` only if route uses RPC; no anon unless separately public-approved | RLS plus explicit permission/scope and bounded filters; audit read/export distinction |
| F3 | Internal authorization helpers | INVOKER if feasible; narrowly hardened DEFINER only to avoid RLS recursion | Not exposed to PostgREST; no PUBLIC/anon/authenticated EXECUTE unless an explicit reviewed call path requires it | Derive caller from auth context; no caller-supplied actor ID |
| F4 | Trigger functions | INVOKER unless documented need | Not callable as public RPC; trigger invocation only | Validate immutable/audit invariants; no hidden bypass |
| F5 | Worker/integration callbacks | Separate design; do not reuse user RPC | No browser grant; dedicated workload principal only after approval | Signed/verified workload identity, narrow task authorization and append-only audit |
| F6 | Blocked institutional operations CMD-045..048 | No function exists | No EXECUTE to any application role | Must remain unavailable until T-10/T-12 authority and physical schema exist |

### Universal ACL baseline

1. Revoke default `PUBLIC` EXECUTE for every application function; PostgreSQL grants EXECUTE to PUBLIC by default unless revoked.
2. Do not grant EXECUTE at schema-wide or wildcard level.
3. Grant by exact function identity including argument types, not just an ambiguous function name.
4. Revoke `anon` EXECUTE for all protected command/read RPCs.
5. Grant `authenticated` only the individually approved RPC signatures required by the caller path.
6. Do not grant `service_role` blanket EXECUTE on user command functions. Any server worker function is separately classified and justified.
7. Internal helpers are not part of the exposed PostgREST API. Their execute rights are limited to the owning function/trigger path and approved roles.
8. Review overloads, default privileges, inherited role membership, exposed schemas and PostgREST schema exposure; an exact grant is ineffective if a broader inherited grant remains.
9. Do not rely on function names being obscure. Authorization must be enforced inside each callable function.
10. Recheck ACLs after every migration and role/schema change.

## 5. Candidate function inventory and grant matrix

Names below are **logical candidate identifiers only**, not approved PostgreSQL names or deployed functions. Proposed convention if approved: one versioned function per command, e.g. `cmd_<logical_name>_v1`; actual argument types must be derived from approved schemas and inspected physical types.

| Command IDs | Candidate function grouping | Class | Intended caller | EXECUTE decision |
|---|---|---|---|---|
| CMD-001..040 | One distinct function per command; do not bundle unrelated commands into a generic executor | F1 | `authenticated` via caller JWT, after per-function Option A security review | Exact signature only; PUBLIC/anon denied; authenticated grant pending |
| CMD-041..044, CMD-049 | Separate read RPCs only if a read route needs database function abstraction; otherwise ordinary RLS-scoped SELECT | F2 | `authenticated`, recipient-self predicate for CMD-049 | Exact signature only if implemented; no broader grant |
| CMD-045..048 | No function / no route | F6 | None | Explicitly denied / not created |
| CMD-050..051 | One distinct mutation function per command; read acknowledgement and policy publication remain separate | F1 | `authenticated` only after recipient-self or approved policy-scope checks | Exact signature only; PUBLIC/anon denied; policy role grants not approved |
| CMD-052..054 | Internal-only fan-out, provider dispatch and escalation workers; never browser callable | F5 | Dedicated non-login worker principal/scheduler trust path; not `authenticated` or `service_role` impersonation | No browser EXECUTE; exact worker identity, owner and EXECUTE ACL require T-18 security approval |
| RLS helper functions | `current_app_user_id`, `has_permission`, `has_scope`, `is_assigned_to`, `can_access_project` are illustrative names from RLS design | F3 | Internal only | No direct browser EXECUTE; exact internal call chain TBD |
| Audit/immutability triggers | Exact trigger inventory not yet supplied | F4 | Trigger invocation only | No direct browser EXECUTE |
| Storage/object verification and outbox callbacks | Separate contracts required | F5 | No user role by default | Not approved |

**No one-to-one SQL function name or argument list is finalized.** The 54 command catalogue rows remain logical operation contracts. Before any grant, inspect actual function inventory and settle API route-to-RPC mapping, exact signatures, return types, schema exposure and owner.

## 6. SECURITY DEFINER hardening requirements

A SECURITY DEFINER exception is permitted only after an individual threat model and reviewer sign-off. Minimum checklist:

- Dedicated NOLOGIN owner with only required table/sequence privileges; never own broad schemas or unrelated functions.
- The definer owner must not own protected application tables and must not inherit table-owner, SUPERUSER or BYPASSRLS capabilities. If a table-owner exception is unavoidable, FORCE ROW LEVEL SECURITY and explicit threat-model review are mandatory; command-level authorization remains mandatory regardless.
- Function is schema-qualified and has a fixed safe search_path; prefer `SET search_path = ''` with all object references schema-qualified. If extension functions are needed, qualify their trusted schema explicitly.
- No dynamic SQL from client input. If dynamic SQL is unavoidable, identifiers are selected from fixed allowlists and values are bound parameters.
- PUBLIC and anon EXECUTE revoked; exact authenticated signature grant only after approval.
- Function reads caller JWT context and derives subject with `auth.uid()`; it never accepts actor, user, role, permission or scope as trusted arguments.
- Reject null/ambiguous auth subject; map to exactly one approved/active `app_users` profile.
- Check permission grant, validity, target scope, account status, state transition, and SoD inside the function.
- Validate every resource relationship, including same-project association/assignment and instrument/version relationships.
- Keep transaction short; no network/Storage/PDF calls while locks are held.
- Lock rows in documented deterministic order; rely on unique/FK/check constraints for final invariants.
- Business mutation, domain event, audit event and idempotency result commit atomically; audit failure rolls back.
- Do not return rows outside caller scope or leak whether unauthorized IDs exist.
- Set statement/lock/idle-in-transaction timeouts appropriate to command class at the correct session/transaction boundary.
- Review function volatility, parallel-safety, configuration settings, owner, ACL, dependencies and body hash in release evidence.
- Add positive, anonymous, forged-actor, wrong-scope, revoked-permission, stale-state, replay, concurrency and audit-failure tests.

## 7. Schema/table privilege posture

The following is the target policy class, not an executable grant matrix. Exact per-table privileges must be generated from the reconciled 48-table proposed inventory and separately approved.

| Table class | anon | authenticated browser | Hardened command owner (if approved) | Migration owner |
|---|---|---|---|---|
| Publicly approved reference data | No access unless explicitly approved | SELECT only if RLS says published/public | Minimum required | DDL |
| User self-profile | No | RLS-limited SELECT; no protected status/role mutation | Specific command function only | DDL |
| Project/assignment/inspection aggregates | No | RLS-limited SELECT; no direct DML | Only exact tables/operations required by each function | DDL |
| Draft response/evidence/document/attendance | No | RLS-limited SELECT; no direct DML under T-18 | Only exact command owner/function path | DDL |
| Roles/permissions/scope grants | No | No direct DML; read only if specifically approved | Exact administrative command path | DDL |
| Audit/idempotency/sync internals | No | No direct browser access | Exact command/trigger/worker path | DDL |
| Retention/security/provider/release records not yet modeled | No | No access | No grant | Only after approved schema |

RLS and SQL ACL must be tested independently. A SELECT policy does not itself grant SELECT; a table GRANT does not override RLS; a SECURITY DEFINER owner may bypass RLS depending on role attributes/table ownership and must be deliberately constrained. Do not assume RLS applies to a definer owner with BYPASSRLS or table-owner behavior.

## 8. Required catalog introspection before implementation

Capture a reviewed, versioned snapshot from the target Supabase project (staging first):

- Database version and Supabase/PostgreSQL extensions.
- Roles: name, LOGIN, SUPERUSER, CREATEDB, CREATEROLE, REPLICATION, BYPASSRLS, inheritance, memberships.
- Schemas: owner, usage/create grants, PostgREST exposed schemas.
- Tables/partitions: owner, RLS enabled/forced, ACL, policies, triggers, constraints.
- Functions/procedures: schema, identity arguments, result type, owner, language, SECURITY INVOKER/DEFINER, volatility, configuration/search_path, ACL, definition hash.
- Default privileges for every owner/schema/object type.
- Sequences, views/materialized views and view security mode.
- Storage buckets and object policies separately.
- Existing API routes and exact route-to-function mapping.
- Service-role usage locations; verify no user-initiated command replaces caller JWT.
- Function dependency graph, overloads, PUBLIC grants and inherited grants.

Do not run broad privilege-changing DDL while inventory is incomplete. Do not expose catalog dumps containing secrets or connection strings.

## 9. Verification plan

The QA catalogue allocates one planned security case per each of the 54 proposed operations plus 15 global privilege-boundary tests. All remain PLANNED / NOT EXECUTED until a staging database and approved ACL/migration exist.

Global tests must prove:
1. `anon` cannot execute protected RPCs or read protected tables.
2. `authenticated` cannot directly INSERT/UPDATE/DELETE any protected business/governance table, including draft answer tables.
3. `authenticated` can execute only individually approved RPC signatures; a neighboring overload remains denied.
4. `PUBLIC` has no EXECUTE on protected application functions.
5. `service_role` is never used as the caller identity for user-initiated commands.
6. Internal helper functions are not callable through exposed PostgREST paths.
7. SECURITY DEFINER owner is NOLOGIN and not SUPERUSER/BYPASSRLS; function owner has no unrelated broad grants.
8. search_path is pinned; untrusted schema shadowing cannot redirect object resolution.


## 10. Technical SSOT Closure — Concrete T-18 Schema, Role Ownership & Per-Command ACL Matrix (2026-11-27)

This section closes the technical design portion of `DGA-B12` for **Full-System Technical SSOT (`G9-TECH`)**. Live PostgreSQL catalog introspection (`pg_roles`, `pg_proc`, `information_schema`) and runtime negative-ACL tests remain mandatory `G11` build-time verification evidence.

### 10.1 Schema & Non-Login Role Separation

| Database schema / role | Type | Attributes / Exposure | Purpose |
|---|---|---|---|
| `public` (or dedicated `app_data` + PostgREST-exposed `app_rpc`) | Schema | Protected business/governance tables have `ENABLE ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY`; `REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES FROM PUBLIC, anon, authenticated` | Ensures browser callers can NEVER perform direct table DML |
| `app_internal` | Schema | **NOT exposed in PostgREST**; `REVOKE ALL ON SCHEMA app_internal FROM PUBLIC, anon, authenticated` | Houses `F3` authorization helpers, `F4` immutability triggers, and `F5` internal worker functions (`CMD-052..054`, render finalizer) |
| `app_migrator` | Role | Migration DDL owner only (not used at runtime) | Owns tables, indexes, constraints, and migrations |
| `app_cmd_definer` | Role | `NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT` | Dedicated owner of all `F1` narrow `SECURITY DEFINER` command functions (`CMD-001..040`, `CMD-050..051`, `CMD-055..056`). Receives ONLY explicit minimum table/sequence grants per reviewed command; does NOT own protected tables |
| `app_worker_definer` | Role | `NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT` | Dedicated owner of `F5` internal worker functions (`CMD-052..054`, `CMD-036` render finalizer). Zero browser/`authenticated` `EXECUTE` grants |

### 10.2 Standardized Per-Command T-18 Function Classification (56 Stable IDs)

| Command IDs | Logical function convention | Class | Security mode | Owner | `SET search_path` | Caller `EXECUTE` grant |
|---|---|---|---|---|---|---|
| `CMD-001..007` | `cmd_request_account_access_v1` .. `cmd_revoke_scope_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-008..017` | `cmd_create_project_v1` .. `cmd_manage_target_plan_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-018..021` | `cmd_create_instrument_v1` .. `cmd_deactivate_instrument_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-022..032`, `CMD-055..056` | `cmd_register_canonical_unit_v1` .. `cmd_reopen_inspection_v1`, `cmd_request_inspection_abort_v1`, `cmd_decide_inspection_abort_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-033..040` | `cmd_create_upload_intent_v1` .. `cmd_verify_attendance_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-041..043`, `CMD-049` | `qry_get_actual_report_v1`, `qry_get_target_report_v1`, `qry_read_audit_v1`, `qry_list_own_notifications_v1` | F2 | `SECURITY INVOKER` | `app_migrator` | `''` | Exact signature to `authenticated` only; RLS enforced under caller JWT |
| `CMD-044` | `cmd_export_audit_v1` | F1 (GATED) | `SECURITY DEFINER` | `app_cmd_definer` | `''` | **Not granted / runtime-disabled** until written `T-10` approval |
| `CMD-045..048` | **NONE — External control plane (PO APPROVED)** | F6 | N/A | N/A | N/A | **No function created; zero grants** |
| `CMD-050..051` | `cmd_mark_notification_read_v1`, `cmd_publish_notification_policy_v1` | F1 | `SECURITY DEFINER` | `app_cmd_definer` | `''` | Exact signature to `authenticated` only; `PUBLIC`/`anon` revoked |
| `CMD-052..054` | `app_internal.wrk_fanout_notification_outbox_v1`, `wrk_dispatch_notification_delivery_v1` (external adapter disabled until `T-10`/`T-12`), `wrk_evaluate_notification_escalation_v1` | F5 | `SECURITY DEFINER` | `app_worker_definer` | `''` | Dedicated non-login worker role only; **zero `PUBLIC`/`anon`/`authenticated` grants** |

### 10.3 Mandatory Per-Function Body Template Invariants

Every `F1` function MUST execute in this fixed order before returning:
1. Validate non-null `auth.uid()` from caller JWT; reject immediately if null.
2. Validate input allowlist, bounds, and canonical types (zero dynamic SQL).
3. Perform `L00` idempotency lookup/claim (`actor + command + scope + key + canonical_hash`). On completed replay: re-check current authorization, then return original result without mutation.
4. Acquire locks strictly in ascending canonical rank order (`LOCK-PROTOCOL-DECISION-RESOLUTION-001` v1.0.0) with `SET LOCAL lock_timeout = '5s'` and `SET LOCAL statement_timeout = '15s'`.
5. Revalidate `app_users.account_status = 'APPROVED'` (except `CMD-001`), canonical permission grant, explicit scope, grantor ceiling, resource state, SoD, and `expected_row_version` / hash under lock.
6. Execute business mutation, append canonical domain event, append `audit_events` row, and store idempotency outcome in the same transaction; any error rolls back atomically (fail-closed).

**Closure disposition (2026-11-27):** `DGA-B12` technical design is **CLOSED** for `G9-TECH` freeze. Deployed role/grant introspection and live caller-JWT positive/negative test execution remain gated to `G11`.
9. Forged JWT/user metadata/client actor/role/scope cannot elevate authority.
10. Revoked/expired role or permission takes effect at transaction time.
11. Unauthorized function calls do not leak resource existence or sensitive state.
12. Audit failure rolls back protected mutation; concurrent calls preserve uniqueness/capacity/claim invariants.
13. Default privileges and inherited role membership do not reintroduce PUBLIC/anon/broad EXECUTE.
14. PostgREST exposure and direct SQL access are tested separately.

## 10. Open decisions and blockers

- **Critical:** verify each protected command's approved T-18 Option A execution path against direct-DML denial; the model selection itself is PO-approved, but per-function owner/ACL/RLS/JWT evidence remains open.
- Verify actual Supabase role names, memberships, attributes and PostgREST schema configuration.
- Approve canonical permission semantics and role/grantor/delegation matrix.
- Inspect actual 48-table proposed ACL/RLS inventory and exact SQL types/constraints.
- Decide which read operations are ordinary RLS SELECT versus read RPC.
- Approve function owner strategy, SECURITY DEFINER exception list and internal helper call chain.
- Formalize route/function version mapping, request/response schemas and idempotency retention.
- Resolve T-10 audit/export/retention authority, T-12 provider/release ownership, Storage policy and ERD-only entities.
- Obtain staging evidence for RLS and ACL tests.

## 11. Current disposition

- Logical operations mapped to function security classes: 54 (CMD-001..054); exact per-function signatures and grants remain unapproved.
- Exact PostgreSQL functions inspected: 0 in this document workflow.
- Exact function signatures approved: 0.
- Role/ACL introspection from live Supabase: not performed.
- EXECUTE grants/revokes applied: none.
- Protected-table DML grants/revokes applied: none.
- RLS/Storage changes deployed: none.
- Runtime security tests executed: none.
- T-18 Option A model: PO APPROVED; per-function implementation/security verification, owner/ACL/RLS analysis and caller-JWT path evidence remain OPEN.
- Scope freeze: **NOT READY**.
- Implementation authorization: **NOT GRANTED**.

## 12. Change control

Any change to caller roles, function security mode, function owner, search_path, EXECUTE ACL, table ACL, RLS policy, exposed schema, JWT propagation or service-role usage requires synchronized updates to this document, the command catalogue, RLS catalogue, command boundary, API contracts, QA catalogue, RTM and Package S. Never infer approval from a draft row or a successful documentation commit.

## Live database inventory prerequisite

See [Supabase Live Database Security Inventory Runbook](SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md). It defines read-only catalog queries and Dashboard evidence needed to verify actual roles, memberships, ownership, ACLs, RLS/policies, function signatures/security modes/owners/EXECUTE grants, default privileges, views, triggers, sequences and Storage policies. The runbook has not been executed against a live database. Repository design artifacts are not proof of deployed state. Do not prepare grants/migrations or expose functions until live evidence is reviewed and each SECURITY DEFINER owner, effective privilege set, RLS interaction, exact EXECUTE ACL and caller-JWT route path is approved. The execution-model choice itself is already resolved by PO approval of Option A.


## INT-NOTIF-001 integration security classification — 2026-11-24

INT-NOTIF-001 is classified as F5 provider/integration ingress, not as a browser RPC, user command permission or generic service-role endpoint. It must terminate at a server-side route that authenticates the selected provider, validates callback freshness and event identity, resolves only a known provider_message_ref, applies a narrow monotonic delivery-state transition and uses a durable deduplication mechanism. It must not accept a user JWT as proof of provider identity and must not call a broad privileged command function.

The callback route's secret manager, signature algorithm, provider identity, database function boundary, function owner, EXECUTE ACL, RLS interaction and failure/rotation process remain unapproved until provider selection and T-18 Security/Operations review. CMD-052..054 remain internal-only worker/scheduler operations with separate least-privilege identities. No function, role or grant was created or tested.


## POQ-01 audience snapshot and notification worker function boundary — 2026-11-24

**Candidate design only; no function, role, ACL, grant or migration is approved.**

1. **Source transaction snapshot writer:** candidate relation `notification_outbox_recipients` is populated in the same transaction as the source command's business mutation, canonical event, audit event and outbox intent. The candidate insert must derive recipient/scope eligibility from database-authoritative source-event-time state. It must not accept client-supplied recipient IDs, roles or scope claims. Engineering may use a narrowly scoped F3 internal helper called only by reviewed source command wrappers, or an equivalent in-transaction implementation; the helper must not be exposed through PostgREST or granted to browser roles.
2. **CMD-052 fan-out worker:** F5 workload principal may read candidate rows only for the currently claimed outbox under the valid owner/token-hash/generation/expiry lease. It may insert inbox and delivery rows through a separately reviewed narrow function boundary. It cannot update/delete candidate rows, claim unrelated outboxes, widen recipients or impersonate an application user.
3. **CMD-053 delivery worker:** separate F5 workload principal and exact scope limited to eligible delivery rows, attempt append and guarded result finalization. Provider I/O remains outside database transactions. UNKNOWN remains the outcome for ambiguous provider acceptance.
4. **CMD-054 scheduler:** separate F5 workload principal, one database UTC evaluation instant, immutable policy-version binding, and atomic escalation-event/outbox/event-time-candidate persistence. It cannot mutate inspection/project/session state.
5. **INT-NOTIF-001 callback ingress:** separate F5 provider trust principal; provider signature, freshness, known provider reference, durable provider-event dedup and monotonic transition checks are required. It cannot access inbox read state, source business state or broad worker functions. Provider-specific cryptographic algorithm, secret source, rotation, replay window and dedup retention remain blocked until a provider is selected.

Every candidate function still requires an individually reviewed owner, role membership, effective privilege set, fixed search_path, schema-qualified SQL, exact signature, PUBLIC/anon/authenticated denial as appropriate, RLS interaction, narrow EXECUTE ACL, caller/workload authentication, bounded inputs, lock/lease behavior and negative runtime evidence. The candidate snapshot relation is NOT ADMITTED and the internal workload identities are not yet established. service_role is not a default worker principal.
