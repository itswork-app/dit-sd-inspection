# T-18 Execution Model Security Review

**Status:** PO APPROVED — Option A execution model (2026-11-24); implementation gates OPEN  
**Version:** 1.0.0  
**Decision:** Hybrid PostgreSQL Command Execution Model  
**Scope:** Documentation and security design only. No SQL, migration, grants, revokes, deployment, or runtime tests are authorized or claimed.

## 1. Decision

The Product Owner approves **Option A: narrow SECURITY DEFINER command wrappers** for protected writes, combined with SECURITY INVOKER for read-only operations where feasible.

This decision resolves the T-18 execution-model choice. It does not approve every future function, owner grant, schema, exact signature, route, table privilege, or implementation detail. Every SECURITY DEFINER function remains subject to individual review and the gates in this document.

## 2. Approved execution model

| Workload | Execution model | Boundary |
|---|---|---|
| Protected state-changing command | Narrow SECURITY DEFINER PostgreSQL function | One explicit command contract per function; caller JWT preserved |
| Read-only scoped query/RPC | SECURITY INVOKER preferred | RLS and least-privilege SELECT remain effective |
| Internal helper | Not exposed through PostgREST | Exact internal call path and minimum EXECUTE only |
| Trigger | Trigger-only execution | No browser RPC exposure |
| Background worker/integration | Separate future workload design | Not covered by this approval |
| Institutional operations CMD-045..048 | Not implemented/exposed | Remain blocked by T-10/T-12 authority and schema gates |

Vercel server routes remain the application command boundary. The route validates the envelope and verified Supabase session, then forwards the caller's authenticated JWT to the corresponding PostgreSQL command function. PostgreSQL derives the actor from `auth.uid()`; client-supplied actor, role, permission, or scope is never authoritative.

## 3. SECURITY DEFINER owner requirements

Each approved command function must be owned by a dedicated least-privileged `NOLOGIN` role. That role must:

- Not be SUPERUSER, BYPASSRLS, CREATEROLE, or LOGIN.
- Not own protected business tables, schemas, or unrelated application objects.
- Not inherit table-owner, migration-owner, service-role, or other broad privileges.
- Receive only the exact table/sequence privileges needed by that function class.
- Have no interactive credentials and no browser-visible key.
- Be reviewed for effective privileges, memberships, default ACLs and ownership chains, not merely its role name/attributes.

A protected-table owner exception is not part of the approved baseline. If evidence shows it is unavoidable, stop and obtain a separate explicit security/PO exception with FORCE ROW LEVEL SECURITY, an updated threat model, and independent review. Do not silently proceed.

## 4. Function hardening contract

Every SECURITY DEFINER function must satisfy all of the following before its exact signature is granted:

1. Fixed `SET search_path = ''`; all tables, functions, types, operators where relevant, and extensions are schema-qualified.
2. No dynamic SQL derived from caller input. If dynamic SQL is unavoidable, identifiers come only from fixed allowlists and values are bound parameters.
3. Exact function identity/signature is reviewed; revoke EXECUTE from PUBLIC and `anon`; grant only the exact approved signature to the required caller role.
4. No schema-wide or wildcard EXECUTE grants; review overloads, inherited memberships, default privileges and exposed PostgREST schemas.
5. Caller JWT is propagated unchanged through the supported Supabase/PostgREST path. Derive actor from `auth.uid()`; reject missing/invalid subject and resolve exactly one enabled/approved application account.
6. Never accept caller-supplied actor, user ID, role, permission, project, assignment or scope as trusted authorization facts. Resource identifiers in the payload are untrusted selectors and must be independently authorized.
7. Check active account, current permission, role, project/session/assignment association, resource state, SoD and every relational invariant inside the transaction.
8. Do not use user-editable JWT metadata as an authorization source. Authorization comes from trusted database records and verified claims.
9. Keep the transaction short; use deterministic lock order, constraints as final race guards, and explicit idempotency semantics.
10. Business state, canonical event, audit event and idempotency result commit atomically. Audit failure or invariant failure rolls back the transaction.
11. Do not perform network, Storage, email, PDF rendering or other external I/O while database locks are held.
12. Return stable typed outcomes without exposing SQL, stack traces, secret values or existence of unauthorized resources.

## 5. RLS and privilege interaction

SECURITY DEFINER executes with the function owner's privileges. Therefore the owner and its effective memberships determine whether table ACLs or RLS can be bypassed. The design must not assume that RLS automatically protects a definer function.

- Keep the owner separate from table ownership and BYPASSRLS roles.
- Inspect table ownership, FORCE ROW LEVEL SECURITY, role memberships, function owner, schema ACLs and all effective privileges.
- Do not give the browser's `authenticated` role protected table INSERT/UPDATE/DELETE as a workaround.
- Do not substitute `service_role` for the caller identity.
- Every command must enforce authorization internally even when RLS also applies.
- RLS remains the default read boundary; SECURITY INVOKER read paths must be tested under the real caller JWT.

## 6. JWT propagation and Vercel route contract

The route must verify the Supabase session and forward the same caller access token for the PostgREST RPC call. It must not replace the caller token with a service-role token. The actual repository implementation, Supabase client configuration, route handlers, token refresh behavior and deployed PostgREST exposure have not yet been proven by live inventory.

Acceptance evidence must show the real HTTP path from an authenticated browser session through Vercel to PostgreSQL, including:
- valid user JWT maps to the expected `auth.uid()`;
- expired, malformed, absent and revoked sessions are denied;
- a forged actor/scope field does not alter the database-derived actor;
- user-editable metadata cannot elevate permissions;
- a request cannot invoke another command or overload by changing route/payload fields;
- route errors do not leak credentials, SQL or internal stack traces.

SQL Editor tests alone are insufficient to prove caller-JWT propagation.

## 7. Grant and schema exposure baseline

- Protected browser roles receive no direct INSERT/UPDATE/DELETE on protected business, governance, publication, membership, assignment, audit or idempotency tables.
- `anon` receives no protected command EXECUTE or protected data access.
- `authenticated` receives only exact, individually approved command function signatures.
- PUBLIC EXECUTE is revoked for protected application functions and internal helpers.
- No broad service_role EXECUTE on user commands.
- Internal helpers are not exposed in PostgREST schemas.
- Verify schema USAGE, exposed schemas, function overloads, default privileges, inherited grants, views, triggers and sequences.
- Read-only SELECT grants and RLS policies are independently reviewed; command EXECUTE is not a substitute for read authorization.

## 8. Required security verification

The QA catalogue allocates `TC-EXEC-MODEL-027-001..012`. All cases are PLANNED / NOT EXECUTED. At minimum, verify:
- owner attributes, memberships, ownership and effective grants;
- fixed search_path and schema-shadowing resistance;
- PUBLIC/anon denial and exact authenticated EXECUTE allowlist;
- browser direct-DML denial;
- JWT actor binding and spoofed metadata rejection;
- account/permission revocation and cross-project/assignment denial;
- SoD and invalid state transitions;
- replay/idempotency and concurrent duplicate commands;
- atomic rollback when audit insert fails;
- real Vercel-to-PostgREST HTTP path with caller JWT;
- safe typed outcomes and non-disclosure.

Any failed security test blocks the affected command and release. No waiver is implied.

## 9. Remaining prerequisites

1. Execute the read-only Supabase live inventory against the approved target project and reconcile roles, memberships, schema/table/function ownership, ACLs, RLS, policies, default privileges, views, triggers, sequences and exposed schemas.
2. Inspect the complete repository for actual Vercel routes, Supabase clients, auth helpers, migrations and function definitions; reconcile the documented flow with implementation evidence.
3. Finalize the exact 48 command contracts, request/response schemas, function signatures, route mapping, locks, idempotency and typed outcomes.
4. Reconcile all table grants and RLS policies; identify every SECURITY DEFINER function individually.
5. Complete T-16 technical review, T-17 publication controls, T-15 audit atomicity, T-10 institutional records/privacy controls and T-12 provider ownership/recovery prerequisites.
6. Obtain security review sign-off and explicit implementation authorization before any migration or code change.

## 10. Status

- T-18 execution model: **PO APPROVED — Option A**.
- Option B: not selected; no separate command-executor connection is authorized.
- Option C: rejected under the current no-direct-browser-DML boundary.
- Exact functions, roles, grants, route paths and implementation: **OPEN / NOT APPROVED**.
- Live Supabase inventory: **NOT EXECUTED**.
- Runtime security tests: **NOT EXECUTED**.
- Scope freeze: **NOT READY**.
- Feature implementation: **NOT AUTHORIZED**.
