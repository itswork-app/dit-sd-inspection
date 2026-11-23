# Table-by-Table RLS Policy Catalogue

**Status:** Security policy design draft — security review and implementation approval required  
**Version:** 0.1.0  
**Package:** M — RLS and Authorization Policy Catalogue  
**Date:** 2026-11-23

## 1. Purpose and security boundary

This catalogue defines the intended access posture for every application table identified in Package L. It is a policy design artifact, not executable SQL, not a deployed Supabase policy set, and not evidence that RLS has been tested.

Security baseline:
- RLS enabled on every exposed application table.
- No policy means deny; never add broad authenticated-user access as a convenience.
- Browser clients receive only the minimum permissions required for safe reads and narrowly scoped draft operations.
- State transitions, role grants, configuration publication, claims, submission, review, evidence finalization, print sequencing, and audit writes occur only through trusted commands.
- A trusted command must independently derive actor identity from the authenticated session, verify account status, permission, scope, resource state, and separation of duties, then perform a short transaction.
- Service-role credentials are server-only. Using service role does not waive command-level authorization.
- Views must use invoker security unless a reviewed exception is required. SECURITY DEFINER functions require a fixed safe search_path, minimal grants, internal authorization, and negative tests.
- No browser-supplied user ID, role, scope, location, or actor identity is authoritative.

## 2. Identity and helper-function contract

Proposed helper functions (names illustrative; final SQL names follow migration conventions):
- `current_app_user_id()`: resolves `auth.uid()` to one active application profile; returns NULL if mapping is missing or account is not active/approved.
- `has_permission(permission_code)`: evaluates active role grants and permission assignments from database state.
- `has_scope(scope_type, scope_id, permission_code)`: evaluates explicit effective scope and active assignment membership.
- `is_assigned_to(assignment_id, operational_role)`: confirms current user has active membership for the assignment and role.
- `can_access_project(project_id, permission_code)`: derives project access only from explicit grants or active assignment membership.

Helper requirements:
1. Derive identity from `auth.uid()`; never accept a user UUID parameter as the caller identity.
2. Avoid recursive RLS evaluation. Use narrowly scoped SECURITY DEFINER only where required to read authorization tables without recursion; set fixed search_path and revoke PUBLIC execute.
3. Return false on missing profile, inactive account, invalid scope, or ambiguous state.
4. Use database time for effective intervals.
5. Do not trust user-editable user metadata or client JWT custom claims as the source of current roles/scopes.
6. Add unit tests for helper functions and direct table tests proving no privilege escalation.
7. Ensure service-role and migration-owner behavior is explicitly distinguished from normal application access.

## 3. Global access classes

- **Self:** current authenticated user's own profile and account request.
- **Assigned operational scope:** rows reachable through active project/session/location/assignment membership and the required operational role.
- **Reviewer scope:** only assigned review queues and related immutable submissions/evidence.
- **Korlap scope:** only explicitly assigned location/session supervision data.
- **Super Admin configuration:** global administrative read/write for approved configuration commands; operational actions still require explicit assignment.
- **Trusted command only:** no direct browser INSERT/UPDATE/DELETE. Mutations go through an approved command boundary.
- **No client access:** internal authorization, idempotency, audit, and system-control tables are not directly exposed.

## 4. Table-by-table policy matrix

Legend:
- **R-self** = SELECT own row only.
- **R-scope** = SELECT only within explicit assigned scope.
- **R-admin** = SELECT for Super Admin with permission.
- **CMD** = mutation only through trusted command; direct client DML denied.
- **NONE** = no direct browser access.
- **R-published** = SELECT published/active configuration only when user has access to its project/assignment.

| Table | SELECT | INSERT | UPDATE | DELETE | Notes |
|---|---|---|---|---|---|
| `app_users` | R-self; R-admin | CMD | CMD | NONE | User cannot change own approval, account status, roles, or display identity fields outside allowed profile update command |
| `roles` | R-admin; optionally authenticated read of non-sensitive active role labels | CMD | CMD | NONE | System role codes protected |
| `permissions` | R-admin | CMD | CMD | NONE | Permission catalogue is administrative |
| `role_permissions` | R-admin | CMD | CMD | NONE | Changes audited and reviewed |
| `user_roles` | R-self limited to own grants; R-admin | CMD | CMD | NONE | User cannot grant/revoke own roles |
| `user_scope_grants` | R-self limited to own effective grants; R-admin | CMD | CMD | NONE | Scope target validation in trusted command |
| `account_decisions` | R-self limited to own decision history; R-admin | CMD | NONE | NONE | Append-only decision history |
| `projects` | R-scope; R-admin | CMD | CMD | NONE | Project creation and lifecycle through command |
| `locations` | R-scope; R-admin | CMD | CMD | NONE | Project membership enforced |
| `sessions` | R-scope; R-admin | CMD | CMD | NONE | Inspector reads only active assigned sessions |
| `teams` | R-scope; R-admin | CMD | CMD | NONE | Membership and scope checked |
| `operational_assignments` | R-scope; R-admin | CMD | CMD | NONE | No self-assignment or client scope edits |
| `assignment_members` | R-scope for relevant assignment; R-admin | CMD | CMD | NONE | Membership grant/revoke privileged and audited |
| `project_capacity_settings` | R-admin; read-only operational summary if approved | CMD | CMD | NONE | Global lock and capacity-count predicate enforced |
| `target_plans` | R-scope; R-admin | CMD | CMD | NONE | Draft mutable only by authorized planner; published immutable |
| `target_allocations` | R-scope; R-admin | CMD | CMD | NONE | Versioned; never edits actual activity |
| `instruments` | R-published; R-admin | CMD | CMD | NONE | Super Admin catalog management only |
| `instrument_versions` | R-published; R-admin | CMD | CMD | NONE | Draft writes via configuration command; published immutable |
| `checklist_sections` | R-published; R-admin | CMD | CMD | NONE | Draft version only |
| `checklist_items` | R-published; R-admin | CMD | CMD | NONE | Declarative validation schema allowlist |
| `specification_fields` | R-published; R-admin | CMD | CMD | NONE | Typed values; no executable expressions |
| `evidence_slot_definitions` | R-published; R-admin | CMD | CMD | NONE | Required status and allowed media are versioned |
| `instrument_version_publications` | R-scope; R-admin | CMD | NONE | NONE | Append-only publication history |
| `units` | R-scope; R-admin | CMD | CMD | NONE | Unit creation/serial normalization command only; serial uniqueness DB enforced |
| `inspections` | R-scope according to Inspector/Reviewer/Korlap/Print Officer permissions; R-admin | CMD | CMD | NONE | Aggregate state changes only through commands |
| `inspection_revisions` | R-scope; R-admin | CMD | NONE | NONE | Immutable after submission; draft snapshot handling only via command |
| `checklist_responses` | R-scope; R-admin | CMD | CMD | NONE | Direct draft writes prohibited until a narrow, reviewed draft-write contract exists |
| `specification_responses` | R-scope; R-admin | CMD | CMD | NONE | Same as checklist responses |
| `unit_claims` | R-scope for holder and authorized supervisors/reviewers; R-admin | CMD | CMD | NONE | Atomic claim and release command; no client expiry edits |
| `review_events` | R-scope for assigned reviewers and authorized supervisors; R-admin | CMD | NONE | NONE | Append-only |
| `inspection_events` | R-scope; R-admin | CMD | NONE | NONE | Append-only |
| `evidence_assets` | R-scope; R-admin | CMD | CMD | NONE | Pending metadata managed by upload commands; finalized metadata immutable |
| `documents` | R-scope; R-admin | CMD | CMD | NONE | Generation/finalization command only; output immutable |
| `print_events` | R-scope for authorized print/operational roles; R-admin | CMD | NONE | NONE | Append-only sequence allocation |
| `attendance_records` | R-scope; R-admin | CMD | CMD | NONE | Lifecycle command only |
| `attendance_documents` | R-scope; R-admin | CMD | CMD | NONE | Replacement creates new version; no overwrite of original |
| `audit_events` | R-admin; R-scope only if a specific audit-read permission is granted | CMD | NONE | NONE | No direct client write; no update/delete for application roles |
| `idempotency_records` | NONE | CMD | CMD | NONE | Internal command machinery; retention cleanup via controlled maintenance |
| `sync_batches` | R-self/R-scope for own device batches only | CMD | CMD | NONE | Batch payload not exposed broadly; no cross-user read |

**Important:** this is the complete catalogue for Package L's proposed table inventory. Any new table, view, RPC, or Storage bucket must be added to this catalogue before it is exposed. A missing row is a release blocker.

## 5. Role and resource-specific constraints

### Inspector
- Read only own active assignment, own draft, and relevant published instrument version.
- May not list all units outside assigned assignment.
- May not read other Inspectors' drafts or evidence.
- Draft mutation, claim, upload, and submit are command-authorized and assignment-scoped.
- Cannot read reviewer-only notes or approve/return actions.

### Reviewer
- Read only submissions assigned to the reviewer and evidence necessary for review.
- Cannot modify Inspector responses or evidence.
- Cannot review/approve a revision authored by the same account, regardless of other roles.
- Return/approve commands append immutable review events.

### Korlap/Admin
- Read operational progress and permitted records within explicit location/session scope.
- No default authority to edit inspection answers or approve results.
- Can perform only separately granted administrative/operational commands.
- Cross-location access is denied unless explicitly granted.

### Print Officer
- Read only approved source revision and documents in explicit print assignment scope.
- Print/reprint commands append events; cannot alter inspection result.
- Physical print completion is not inferred from opening a print dialog.

### Super Admin
- Global configuration and account/role/scope administration only through explicit permissions and audited commands.
- May inspect global operational data only where the permission catalogue grants it.
- Global administrative role does not automatically grant Inspector, Reviewer, or Print Officer membership.
- When acting in an operational role, must have explicit assignment and comply with separation of duties.

## 6. Storage bucket policy catalogue

All evidence and generated documents use private buckets. Public buckets are prohibited for inspection evidence.

| Bucket / object class | Read | Upload | Replace/delete |
|---|---|---|---|
| Inspection evidence | R-scope via metadata-linked authorization | Narrow upload intent for assigned draft and allowed slot | No overwrite after finalization; deletion only under approved retention/legal-hold command |
| Generated PDFs | R-scope for authorized document roles | Trusted document-generation service only | Immutable; supersede by new document version |
| BA/attendance scans | R-scope for authorized operational/document roles | Upload intent with session and document scope | Replacement appends new version with reason; original retained per approved policy |

Storage policy requirements:
- Validate the object against relational metadata and caller assignment, not object key alone.
- Use opaque random object keys; never place names, NIP, serial number, or other personal data in paths.
- Enforce size/type limits in trusted upload intent and confirmation.
- Verify actual content signature, byte size, and checksum before finalization.
- Signed URLs are short-lived, scoped to one object, never logged, and not treated as permanent access grants.
- Pending object cleanup follows approved retention/grace policy; no arbitrary bucket-wide delete job.
- RLS and Storage policies are tested independently; database table access does not imply object access.

## 7. Views, RPCs, and elevated privileges

- Every view is reviewed for invoker/definer behavior and row filtering.
- Default to security-invoker views.
- Every RPC has a documented caller grant, input schema, actor derivation, authorization checks, transaction boundary, error contract, and idempotency rule.
- SECURITY DEFINER functions must set `search_path = ''` or a fixed trusted schema path, fully qualify referenced objects, revoke PUBLIC execute, grant only to required roles, and validate caller identity internally.
- No generic "admin update any table" RPC.
- No RPC accepts a caller-supplied actor ID as authoritative.
- No direct client GRANT to privileged schema or table.
- Service-role use must be limited to trusted server code and logged; it must not be exposed to browsers or preview builds.

## 8. Required authorization test matrix

Every exposed table must have tests for:
1. unauthenticated caller;
2. authenticated but pending account;
3. rejected, suspended, and revoked account;
4. approved user with no role;
5. correct role but wrong project;
6. correct project but wrong location;
7. correct location but wrong session;
8. correct session but wrong assignment;
9. Inspector attempting another user's draft/evidence;
10. Reviewer attempting to edit submitted answers;
11. Reviewer attempting self-approval with multiple roles;
12. Korlap attempting approval without explicit permission;
13. Super Admin attempting operational action without explicit assignment;
14. direct PostgREST DML bypass attempts;
15. Storage object guessing and expired signed URL;
16. RPC calls with forged actor/scope/resource parameters;
17. attempted mutation/deletion of immutable history;
18. role/scope revocation during an active session;
19. concurrency race on claim and capacity;
20. views and nested relations preserving row scope.

For each test, record actor fixture, grants, resource fixture, request, expected result, actual result, and database/provider version. Run against staging Supabase, not only mocked unit tests.

## 9. Open security approvals

1. Final permission catalogue and which roles may read audit data.
2. Whether Super Admin global operational read is unrestricted or permission-segmented.
3. Exact RLS helper implementation and reviewed SECURITY DEFINER exceptions.
4. Direct draft-write strategy: trusted command only versus narrowly scoped client writes protected by RLS.
5. Evidence retention/deletion and legal-hold policy.
6. Audit event policy INS-016 approval, access, retention, and export.
7. Institutional data classification and privacy/legal basis.

## 10. Release gate and disposition

Before production:
- Generate executable SQL policies from this approved catalogue.
- Confirm RLS enabled on every exposed table and Storage bucket.
- Test all positive and negative cases in staging.
- Review every view, RPC, SECURITY DEFINER function, and grant.
- Prove no service-role credential reaches browser bundles, logs, or preview deployments.
- Complete independent security review and record remediation evidence.

**Catalogue status:** DRAFT COMPLETE FOR SECURITY REVIEW.  
**RLS deployment:** NOT EXECUTED.  
**Authorization tests:** NOT EXECUTED.  
**Security certification:** NOT CLAIMED.  
**Implementation authorization:** NOT GRANTED.
