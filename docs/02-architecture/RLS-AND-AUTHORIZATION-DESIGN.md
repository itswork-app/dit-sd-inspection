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
| View audit events | Own relevant history | Scoped as approved | Location scope as approved | Global read/export; no edit |
| Print approved PDF | No by default | No by default | If separately assigned Print Officer | If separately assigned Print Officer |

This matrix is a draft and must be reconciled with the final role/permission catalog.

## 6. Separation of duties

- An actor cannot review or approve a revision they authored.
- Role combinations do not bypass per-transaction separation rules.
- Reopen requires explicit permission and a reason; it creates an audit event and a new work path, not mutation of the approved revision.
- Account/role/permission/scope changes cannot be self-approved.
- A Super Admin acting as Inspector or Reviewer must have explicit assignment; global administrative authority does not grant automatic operational membership.

## 7. Capacity and concurrency controls

- Distinct active Inspector accounts across both locations are counted globally.
- Configured Inspector capacity may be set below 50; the initial/default value is 50 and the hard maximum is 100 distinct active Inspector accounts across both locations combined. Super Admin may change the configured value within the approved range. Count each person once regardless of assignment count. Capacity changes and Inspector activation/role grant must be authorized, audited, and enforced atomically.
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

- Exact permission granularity and configurable permission administration UX.
- Whether Super Admin global audit export is all data or filtered.
- RLS helper-function design and JWT claims strategy.
- Whether server-side operations use Edge/Server functions or tightly scoped PostgreSQL RPCs.
- Institutional privacy and audit-retention rules.
