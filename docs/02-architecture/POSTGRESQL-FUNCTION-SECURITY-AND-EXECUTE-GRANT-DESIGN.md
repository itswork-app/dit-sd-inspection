# PostgreSQL Function Security & EXECUTE Grant Design

**Status:** Security architecture proposal — T-18 Option A approved; per-function privilege review required; NOT approved for implementation  
**Version:** 0.2.0 | **Date:** 2026-11-24  
**Depends on:** T-18 option A; PostgreSQL Command Contract Catalogue v0.2.0; physical schema and 48-table proposed RLS catalogue; canonical permission registry v0.2.0 draft.

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
| F1 | Protected business mutation commands CMD-001..040 | SECURITY DEFINER only after Option A approval; otherwise not implementable under current caller/table-DML boundary | Exact signature EXECUTE to `authenticated`; PUBLIC and `anon` denied | Mandatory JWT actor + active account + canonical permission + scope + state + SoD + audit/idempotency |
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
- T-18 Option A model: PO APPROVED; per-function implementation/security verification and INVOKER/DEFINER compatibility remain OPEN.
- Scope freeze: **NOT READY**.
- Implementation authorization: **NOT GRANTED**.

## 12. Change control

Any change to caller roles, function security mode, function owner, search_path, EXECUTE ACL, table ACL, RLS policy, exposed schema, JWT propagation or service-role usage requires synchronized updates to this document, the command catalogue, RLS catalogue, command boundary, API contracts, QA catalogue, RTM and Package S. Never infer approval from a draft row or a successful documentation commit.

## Live database inventory prerequisite

See [Supabase Live Database Security Inventory Runbook](SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md). It defines read-only catalog queries and Dashboard evidence needed to verify actual roles, memberships, ownership, ACLs, RLS/policies, function signatures/security modes/owners/EXECUTE grants, default privileges, views, triggers, sequences and Storage policies. The runbook has not been executed against a live database. Repository design artifacts are not proof of deployed state. Do not finalize the T-18 execution model or prepare grants/migrations until live evidence is reviewed and the INVOKER/DEFINER/executor conflict is explicitly resolved.
