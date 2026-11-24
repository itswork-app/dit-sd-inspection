# RLS and Authorization Design — Dit. SD Inspection

Status: Security design draft — policy approval required  
Version: 0.1.0

## 1. Enforcement model

Authorization is deny-by-default and evaluated at every server command and database data boundary.

A permitted operation requires all applicable conditions:
1. Valid authenticated Supabase identity.
2. Active and approved application account.
3. Explicit role and permission grant.
4. Explicit project/location/session/assignment scope.
5. Valid resource state and allowed state transition.
6. Separation-of-duties rules satisfied.
7. RLS permits the underlying row/object access.

UI visibility is not an authorization control.

## 2. Identity mapping

- Google sign-in establishes external identity only.
- Map `auth.uid()` to exactly one active `app_users` record.
- Missing, pending, rejected, suspended, or revoked application account has no operational access.
- Role and scope changes are effective only after a server-authorized administrative transaction.
- Do not trust role names, user IDs, project IDs, or scope claims submitted by the browser without database-backed validation.

## 3. Scope evaluation

Resolve effective access from explicit grants and active assignment membership. Avoid implicit cross-location inheritance. A Korlap assigned to location A receives no operational authority at location B unless separately granted. Super Admin global administration is distinct from Inspector/Reviewer operational participation; the latter still requires explicit assignment.

## 4. RLS policy design

- Enable RLS on every exposed application table.
- Default policy posture is no access.
- Add explicit SELECT/INSERT/UPDATE/DELETE policies only where needed; deny DELETE for immutable history, submitted revisions, audit events, and finalized evidence metadata.
- Prefer security-invoker views/functions unless elevated privilege is essential and formally reviewed.
- Any SECURITY DEFINER function must set a safe search_path, validate caller identity/permission/scope internally, minimize grants, and have tests for unauthorized callers.
- Keep service-role keys only in trusted server environments; never use service role as a shortcut around authorization.
- Storage policies must verify ownership/scope through relational metadata, not merely a predictable object path.

## 5. Operation matrix (baseline)

| Resource / action | Inspector | Reviewer | Korlap/Admin | Super Admin |
|---|---|---|---|---|
| Read own assigned active inspection | Yes | Scoped review queue | Scoped supervision | Global administration |
| Create/update own draft | Assigned scope only | No | No by default | Only if separately assigned Inspector |
| Submit inspection | Assigned scope only | No | No by default | Only if separately assigned Inspector |
| Return/approve | No | Assigned scope; never own work | No by default | Only if separately assigned Reviewer and independent |
| Reopen approved work | No | No by default | Explicit permission only | Yes, with reason |
| Configure instrument versions | No | No | No by default | Yes |
| Manage users/roles/scopes | No | No | No by default | Yes |
| View audit events | Only relevant history when explicitly permitted | Scoped only with explicit audit-read permission | Location/project scope only with explicit audit-read permission | No implicit global read/export; explicit audit-read/export permission and institutional authority required; no edit |
| Print approved PDF | No by default | No by default | If separately assigned Print Officer | If separately assigned Print Officer |

This matrix is a draft and must be reconciled with the final role/permission catalog.

## 6. Separation of duties

- An actor cannot review or approve a revision they authored.
- Role combinations do not bypass per-transaction separation rules.
- Reopen requires explicit permission and a reason; it creates an audit event and a new work path, not mutation of the approved revision.
- Account/role/permission/scope changes cannot be self-approved.
- A Super Admin acting as Inspector or Reviewer must have explicit assignment; global administrative authority does not grant automatic operational membership.

## 7. Capacity and concurrency controls

- Use the T-14 PO-approved qualifying-account predicate: distinct enabled login account + active Inspector role grant + at least one currently effective operational Inspector assignment within the governed project/session scope.
- Exclude pending, rejected, suspended, disabled and expired-role accounts; count each account once across both locations, multiple assignments and multiple roles.
- Configured capacity ranges from 1 to 100 qualifying accounts across both locations combined; default value is 50. Super Admin may change the configured value within the approved range. Capacity changes and Inspector eligibility changes must be authorized, audited, and enforced atomically under the governed project's capacity-settings row lock.
- Count and activation/role grant must be checked in one serializable/locked transaction (or equivalent single-row capacity lock) to prevent concurrent over-allocation.
- Revoke/deactivate transitions must update the count semantics atomically.
- Every capacity change records actor, previous value, new value, time, and reason.

## 8. Test requirements

- Unauthenticated, pending, rejected, suspended, and revoked users are denied.
- Same role in wrong location/session/assignment is denied.
- IDOR attempts using another user's inspection/evidence/document IDs are denied.
- Cross-location read/write is denied absent explicit grant.
- Reviewer cannot approve own inspection even with multiple roles.
- Direct REST/SQL access cannot bypass RLS.
- Storage object guessing and expired signed URLs do not expose evidence.
- Capacity race test proves concurrent activations cannot exceed configured cap.
- Audit and submitted revision mutation/deletion attempts are denied.

## 9. Open decisions

- Canonical permission registry and mapping between the legacy RBAC vocabulary and T-17/T-18 command identifiers.
- Exact permission granularity and configurable permission administration UX.
- Whether Super Admin global audit export is all data or filtered.
- RLS helper-function design and JWT claims strategy.
- Final table-by-table RLS/grant catalogue, including reviewed command-specific RPC EXECUTE grants and any SECURITY DEFINER exceptions.
- Institutional privacy and audit-retention rules.


## T-17 — Instrument publication permissions

- `instrument.manage` permits authorized Super Admin catalog/draft management; it does not implicitly grant publication.
- `instrument.publish` is an explicit privileged permission assigned only to authorized Super Admin principals. Under PO-approved T-17 option A, this permission allows direct publication after server-side declarative schema validation; no second-person approval step is required.
- `instrument.deactivate` is a separate privileged permission/action and must include reason + audit. Deactivation never deletes or mutates a published version.
- Publication must occur only through the trusted command boundary; browser direct INSERT/UPDATE/DELETE of instrument catalog/version/configuration/publication/audit tables is denied.
- Global catalog administration does not grant operational inspection membership. Unit inspection, claims, evidence, and responses must enforce explicit project association, session, assignment, role and permission. Cross-project canonical unit references must not widen RLS visibility.

These are authorization design requirements, not deployed policies or test results. T-18 option A is PO APPROVED: Vercel routes forward the caller JWT to narrowly scoped PostgreSQL commands; protected-table browser DML is denied. The exact table/function grants and RLS policies remain design gates, not deployed policies.


## T-18 — Caller-JWT command authorization and direct-DML denial (PO APPROVED option A, 2026-11-24)

- Vercel routes are the only browser-facing entry point for protected state-changing commands. They verify the Supabase session and forward the caller JWT; they do not accept client-supplied actor, role or scope as authority.
- PostgreSQL derives the authenticated subject from auth.uid() and resolves an approved/enabled app_users identity. Every command checks explicit permission, active role, project association, session, assignment, target state and separation of duties at the database transaction boundary.
- Browser roles have no direct INSERT/UPDATE/DELETE privilege on protected business, membership, assignment, instrument/version/configuration/publication, evidence, revision, audit or idempotency tables. RLS remains enabled and deny-by-default for exposed tables; command EXECUTE grants are specific and least-privilege.
- Read access is independently scoped by RLS. A global Super Admin instrument-catalog permission does not grant inspection access to units, sessions, assignments or evidence.
- Prefer SECURITY INVOKER. A SECURITY DEFINER function must be explicitly reviewed, pin search_path, qualify object names, validate all inputs, use a minimally privileged owner, revoke unnecessary PUBLIC execution and grant EXECUTE only to the intended caller role.
- Service-role keys are server-only and must not be used as a blanket RLS bypass for user-initiated commands. Any exception requires a separate ADR, threat-model and audit.
- RLS/grant tests must attempt direct DML through anon/authenticated clients and verify denial, then verify authorized command success and wrong-role/wrong-project/wrong-session/wrong-assignment denial. Also test revoked/expired JWT, pending/disabled account, self-review, replay, idempotency hash mismatch and audit rollback.

T-18 is an approved architecture decision only. This document is not evidence that RLS or grants have been deployed or tested. T-16 association model is specified in the ERD/physical schema; technical review and institution-approved normalization/exception policy remain pre-migration dependencies.


## T-16 — Unit association RLS and project isolation contract

- `units` is a canonical identity table, not a project membership table. A raw `unit_id` or serial lookup is never sufficient authorization to read an inspection, claim, evidence object or project activity.
- Project-scoped unit visibility is granted only through an ACTIVE `unit_project_associations` row joined to the caller's effective project/session/assignment membership and permission. Historical inspection/revision access is allowed only through the exact stored association/project and the separately approved historical-read rule; ending an association does not erase history or grant access to former project members automatically.
- For every inspection/claim row, verify association ID + unit ID + project ID and assignment ID + project ID. The assignment's instrument must equal the canonical unit's instrument. Reject mismatched tuples even if each individual ID exists.
- `unit_project_associations` reads are project-scoped. Create/end operations are command-only, reasoned and audited. Browser direct DML is denied under T-18.
- `unit_identity_conflicts` is visible only to authorized duplicate-resolution reviewers and relevant project-scoped actors under a privacy-safe conflict workflow. Candidate canonical unit IDs must not disclose other project's inspection details.
- A global Super Admin catalog permission does not imply project association, unit operational access or cross-project evidence access.
- Claim and inspection commands lock the canonical unit and validate the exact active association plus same-project assignment. A unique ACTIVE claim on `unit_id` prevents a second project from concurrently claiming the same physical unit.

Required RLS/grant matrix cases: associated project member allowed only within assignment/session scope; another project member denied absent their own association; former association member denied current operational access; historical access follows explicit approved history permission; conflict reviewer sees minimum necessary metadata; unaffiliated caller cannot enumerate canonical serials or candidate project membership. These are design requirements, not deployed policies or executed tests.


## T-18 permission and audit-read reconciliation

The role/action matrix above is descriptive only and does not grant permissions. T-17's explicit `instrument.manage`, `instrument.publish` and `instrument.deactivate` permissions remain separate. T-18 requires narrow command-specific permission codes; the legacy RBAC permission catalogue has not yet been fully mapped to the command inventory. Evidence read/export, audit read/export and project closure must receive explicit permissions and approved scope/authority; Super Admin status alone is not a substitute. The RLS matrix must not imply automatic global audit export.

The canonical permission registry, legacy-code mapping, role grants, command EXECUTE grants and table RLS remain open review items. No deployed authorization policy is claimed.




## Command authorization verification matrix dependency

Use ../02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md as the command-family verification crosswalk. It maps 27 logical families to proposed permissions, actor/scope/SoD rules, current RLS data classes, audit events and 36 planned design cases. The current Table-by-Table RLS Policy Catalogue remains the exact proposed 41-table inventory. Neither document establishes deployed RLS or grants. Command-level schemas, exact RPC EXECUTE grants, role/grantor approval and executable tests remain open.

## Canonical permission registry dependency

Use ../02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md as the proposed canonical vocabulary and command mapping. The role/action matrix in this document is descriptive and does not grant authority. Final role-to-permission mapping, grant/revoke authority, exact scope predicates, per-object RLS and RPC EXECUTE grants remain open pending PO/security review. Evidence read/export and audit read/export are separate capabilities.

## PostgreSQL function execution privilege dependency

See [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md). RLS, SQL table ACL and function EXECUTE ACL are separate controls. The design identifies a critical unresolved interaction between SECURITY INVOKER and the T-18 prohibition on browser direct table DML; do not grant protected table DML to authenticated as a workaround. PO/security must approve the execution model before implementation.
