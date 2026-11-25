# RBAC and Authorization Design

**Status:** Draft v0.2.0 — RBAC-003 product semantics PO-APPROVED; technical permission/schema/security design OPEN  
**Package:** C — Functional and Operational Design

## 1. Purpose

Define identity lifecycle, role assignment, scope enforcement, separation of duties, and privileged administration for the Dit. SD inspection replacement application.

## 2. Identity lifecycle

1. A user authenticates with Google; the application identity is created on the first successful server-verified sign-in.
2. First-time application identity is provisioned as `PENDING` and has no operational access.
3. Access requests are stored separately from the identity; approve/reject decisions are retained in append-only decision history.
4. Account states are `PENDING`, `APPROVED`, `REJECTED`, `SUSPENDED` and `DISABLED`.
5. A rejected account may submit a new request; each request/decision remains separately recorded. A suspended account may be reinstated only by an explicit authorized decision. A disabled account is never reactivated automatically.
6. Account approval does not implicitly grant a role, permission, team membership or operational assignment. Role grants, scope grants and operational assignments are separate explicit workflows.
7. Role/scope revocation and account-state changes are authorized, reasoned where required and audited.

Google identity proves control of an account; it does not itself grant institutional access.

## 3. Role model

Roles are records, not hard-coded UI labels. Multiple roles per user are supported through a many-to-many relationship. Initial role concepts:

- **Super Admin:** global system configuration and administration.
- **Admin / Korlap:** operational supervision within explicitly assigned location/session scope.
- **Reviewer:** review, approve, or return submitted inspections within assigned scope.
- **Inspector:** perform assigned inspections and evidence capture.
- **Print Officer:** print approved inspection reports and record print events.

A user may hold more than one role, but each action must resolve the exact effective permission and scope from server/database state. Role possession alone does not grant access to every project, session, location, instrument, team or assignment. Global roles and project-scoped roles are distinct classes; every canonical role declares its class, and project-scoped roles require an explicit project scope.

## 4. Authorization decision

Every protected backend operation evaluates all of:

- authenticated user is active;
- user has the required permission;
- user has the required role;
- an active assignment grants the requested session/location/instrument scope;
- transaction state permits the operation;
- separation-of-duties rules are satisfied.

The frontend may hide unavailable actions for usability, but backend authorization is authoritative. Supabase Row Level Security (RLS) is required as a database-level defense; privileged server operations must independently validate the same policy.

## 5. Scope model

Scope is explicit and non-inheriting. Project, session, location, instrument, team and operational assignment are separate scope dimensions; a grant applies only to its exact declared scope unless a separate explicit permission mapping authorizes another scope. There is no implicit parent-to-child or cross-location inheritance.

- A Korlap assigned to Location A does not gain Inspector or Reviewer access at Location B.
- A user assigned to multiple teams must have a distinct explicit assignment for each.
- Super Admin has global administration permissions. When acting as Inspector or Reviewer, Super Admin still needs an explicit operational assignment.
- Inspector capacity ranges from 1 to 100 qualifying accounts across both locations combined; default value is 50. Count a distinct account once only when login-enabled, `APPROVED`, holding an active Inspector role grant and at least one currently effective operational Inspector assignment in the governed project/session scope. `PENDING`, `REJECTED`, `SUSPENDED`, `DISABLED`, expired-role and unassigned accounts are excluded. Capacity changes and every eligibility-changing path must be authorized, audited and serialized atomically. This is one global capacity, not a per-location allowance.

## 6. Separation of duties

- An actor cannot approve their own account request, grant a role to themselves or assign a scope to themselves.
- Inspector cannot review/approve their own inspection.
- Reviewer must be explicitly assigned to the applicable operational assignment.
- Admin/Korlap does not approve by default. Approval is allowed only if separately assigned Reviewer and the transaction's separation-of-duties rules still pass.
- Super Admin may act in operational roles only through explicit assignment; global administration does not bypass self-review prohibition.
- Reopen of an approved inspection requires Super Admin or Admin with explicit reopen permission, a reason, and audit history.

## 7. Initial permission catalogue

The following is a proposed permission vocabulary; exact role-to-permission mapping remains configurable and must be validated before implementation.

| Permission | Intended capability |
|---|---|
| `account.review` | Approve/reject pending users |
| `role.assign` | Assign roles |
| `scope.assign` | Assign project/session/location/team scope |
| `config.manage` | Manage instrument and workflow configuration |
| `session.manage` | Create/update/open/pause/close sessions |
| `assignment.manage` | Manage operational assignments |
| `inspection.claim` | Claim an available unit |
| `inspection.edit` | Create/update own draft |
| `inspection.submit` | Submit inspection |
| `inspection.review` | Review submitted inspection |
| `inspection.approve` | Approve inspection |
| `inspection.return` | Return inspection for correction |
| `inspection.reopen` | Reopen approved inspection |
| `report.view` | View authorized reports |
| `report.validate` | Validate daily report |
| `document.print` | Print approved PDF/document |
| `document.upload` | Upload attendance/BA evidence |
| `audit.view` | View/export audit events |

## 8. Data model baseline

Proposed logical entities:

- `users`
- `roles`
- `permissions`
- `user_roles`
- `role_permissions`
- `projects`
- `sessions`
- `operational_assignments`
- `assignment_members`
- `audit_events`

Avoid storing authorization as client-editable profile metadata. Use constrained identifiers and relational membership records. RLS policies should be tested for both allowed and denied access, including direct API requests.

## 9. Audit requirements

Record actor, active role, action, target entity, session/assignment scope, timestamp, outcome, reason where required, and correlation/request identifier. Sensitive changes include approval/rejection, role and scope changes, permission changes, configuration changes, and privileged reopen actions.

Audit events are append-only. Administrative users may view/export but cannot edit or delete audit history through the application.

## 10. Security acceptance

- Pending/rejected/suspended users cannot read operational data.
- User cannot self-assign or elevate role/scope.
- Cross-location access is denied unless explicitly assigned.
- Inspector self-approval is denied by backend and database policy.
- Global Inspector cap cannot be exceeded under concurrent account approval/role assignment.
- RLS negative tests cover reads and writes for every role/scope combination.
- Role, scope, and permission changes are auditable.

## 11. Open technical decisions

- Exact role-to-permission and global/project role inventory.
- Canonical grantor/delegation ceiling, revocation authority and SoD matrix.
- Physical account/request/decision/role/scope schema and concurrency tokens.
- Account linking, lost-access recovery and last-administrator break-glass procedure.
- Exact RLS, PostgreSQL grants, function ACL and authorization freshness implementation.

Product semantics for reapplication, suspended-account reinstatement, last-administrator protection, global/project role classes, self-service prohibitions and non-inheriting scope are approved by Decision Register RBAC-003. T-07 remains controlling: Super Admin exclusively creates/configures sessions; Korlap may transition only within assigned scope and explicit permission. INS-012 retains the separate Print Officer role decision.



## T-14 — Inspector capacity eligibility (PO-approved 2026-11-24)

An account contributes once to the combined Inspector cap only when it is login-enabled, in `APPROVED` account state, has an active Inspector role grant, and has at least one currently effective operational Inspector assignment within the governed project/session scope. `PENDING`, `REJECTED`, `SUSPENDED`, `DISABLED` and expired-role accounts are excluded. Multiple roles/assignments do not multiply the count. Assignment and role grant status must be evaluated server-side; client UI is not authoritative.


## Super Admin-controlled account and staffing lifecycle (PO clarification, 2026-11-24)

1. A person completes the first server-verified Google sign-in and an application identity is provisioned in `PENDING`.
2. Each access request and approve/reject decision is stored separately; decision history is append-only.
3. Registration alone grants no inspection access, role, permission, team membership or operational assignment and does not count toward Inspector capacity.
4. Super Admin approves or rejects the access request. Role grants, permission grants, scope grants, team membership and operational assignment are separate explicit actions; approval does not imply any of them.
5. Super Admin determines team count and personnel assigned to each team. A user cannot create or select their own team membership, role or operational assignment.
5. An account counts toward the Inspector cap only when it is enabled, has an active Inspector role grant, and has at least one currently effective operational Inspector assignment in governed project/session scope. Count once per account.
6. Role, team and assignment changes are authorized, effective-dated where applicable, and audited. Revocation/suspension removes eligibility according to the canonical capacity predicate.


## 12. T-17/T-18 permission catalogue reconciliation

The table in Section 7 is the initial legacy vocabulary, not the complete command-boundary permission catalogue. It must not be treated as an exhaustive or authoritative list for implementation. T-17 explicitly establishes separate `instrument.manage`, `instrument.publish` and `instrument.deactivate` permissions; publication and deactivation are distinct privileged actions. T-18 requires every state-changing command to have a narrow explicit permission and scope predicate.

The current command inventory uses additional identifiers including `account.request`, `account.approve`, `role.manage`, `project.manage`, `session.transition`, `capacity.manage`, `unit.register`, `unit.associate`, `unit.association.end`, `unit.identity.resolve`, `evidence.upload`, `sync.apply`, `document.generate`, `attendance.upload`, `attendance.verify` and `report.read`. These identifiers are not all present in the legacy Section 7 catalogue. Conversely, legacy identifiers such as `account.review`, `role.assign`, `scope.assign`, `config.manage`, `report.view`, `report.validate`, `document.upload` and `audit.view` have not been formally mapped to the newer command identifiers. In particular, legacy `audit.view` combines read/export and must be split or explicitly constrained before it can satisfy T-15 least-privilege requirements; `document.upload` must be reconciled with separate `attendance.upload` and `attendance.verify` commands.

**Required before implementation:** publish one canonical permission registry with immutable permission codes, human-readable capability, resource/action, required scope type, assignable principal class, grant/revoke authority, separation-of-duties constraints and linked command/function. Record explicit mapping or retirement for every legacy code. Add separate least-privilege permissions for evidence read/export and audit read/export; confirm project-close authority; do not infer these from Super Admin role alone. Do not silently alias old and new codes or grant broad permissions to make commands pass.

No final role-to-permission matrix, SQL permission seed, RLS grant, command EXECUTE grant or runtime test is approved by this reconciliation. Permission-code reconciliation remains OPEN.


## 13. Canonical permission registry reference

The single proposed permission vocabulary and command mapping is maintained in [Canonical Permission Registry and Command Authorization Matrix](../02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md). Section 7 in this document remains a legacy vocabulary snapshot and is not authoritative for new command implementation. Decision Register RBAC-003 approves product semantics for global/project role classes, effective delegation ceiling, self-grant/self-assignment prohibition, last-active-administrator protection and explicit non-inheriting scopes. The registry's exact permission codes, legacy mappings, role-to-permission matrix, grant/revoke authority and SoD implementation still require technical/security review. Until then, no permission seed or new role grants are authorized.

## Command authorization verification reference

The proposed command-family mapping and planned verification cases are maintained in ../02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md. This matrix does not approve role-to-permission grants or legacy aliases. The role/grantor authority, SoD, exact scope predicates, per-table RLS and per-function EXECUTE grants remain subject to PO/security review.


## 14. RBAC-003 Product Owner semantic reconciliation — 2026-11-25

The Product Owner approved all eleven RBAC-003 recommendations without amendment. The controlling details are in [RBAC-003 — Account Lifecycle, Role and Scope Governance](../02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md) and the Decision Register.

- First verified Google sign-in creates a PENDING app identity. Separate account_requests and append-only account_decisions preserve request and decision history.
- Account approval does not grant roles/scopes implicitly. Rejection requires a structured category and bounded reason; rejected users may reapply through a new request.
- Global roles and project-scoped roles are distinct. Grant/revoke authority is bounded by the actor's effective delegation ceiling.
- Self-approval, self-role-grant and self-scope-assignment are denied. Ordinary actions cannot remove the last active administrator; recovery requires a separate reasoned and audited break-glass procedure.
- Scopes are explicit and non-inheriting, including project, session, location, instrument, team and assignment.
- Revocation denies subsequent protected commands after authoritative server/database revalidation while preserving existing assignments, sessions, inspection history and evidence. It does not silently abort or reassign work.
- T-14 Inspector capacity remains unchanged and uses the approved login-enabled APPROVED account + active Inspector role + effective operational assignment predicate.

**Technical design remains open:** exact role/permission/grantor/SoD matrix, physical schema, RLS/grants/function ACL, recovery procedure, version tokens, LPR-11 lock graph, capacity writer certification, authorization freshness, and executed negative/concurrency tests. No implementation or test PASS is claimed.
