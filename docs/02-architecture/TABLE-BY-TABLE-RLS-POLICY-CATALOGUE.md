# Table-by-Table RLS Policy Catalogue

**Status:** TECHNICAL SSOT CLOSED — READY FOR G9-TECH FREEZE (62/62 table-by-table RLS policy parity reconciled with Physical Schema v1.0.0; live RLS testing gated to G11)  
**Version:** 1.0.0
**Package:** M — RLS and Authorization Policy Catalogue  
**Date:** 2026-11-27


## Physical schema reconciliation reference

See [Physical Schema ↔ RLS ↔ Command Reconciliation](PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md) for the proposed 48-table crosswalk, including T-13 `print_batches` and the six NLA-001 notification tables. These are proposed policies only; no live RLS or grants are verified.

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
| `units` | R-scope; R-admin | CMD | CMD | NONE | Unit creation/serial normalization command only; canonical serial uniqueness DB enforced; unit ID alone grants no scope |
| `unit_project_associations` | R-scope through matching project membership; R-admin | CMD | CMD | NONE | Durable ACTIVE/ENDED/REVOKED episodes; create/end only through reasoned audited commands; no hard delete |
| `unit_identity_conflicts` | R-conflict-reviewer; minimum necessary project-scoped metadata only | CMD | CMD | NONE | Restricted same-instrument duplicate workflow; authorized resolution only; never exposes candidate project's inspection history |
| `inspections` | R-scope according to Inspector/Reviewer/Korlap/Print Officer permissions; R-admin | CMD | CMD | NONE | Aggregate state changes only through commands |
| `inspection_revisions` | R-scope; R-admin | CMD | NONE | NONE | Immutable after submission; draft snapshot handling only via command |
| `checklist_responses` | R-scope; R-admin | CMD | CMD | NONE | Draft writes are command-only through T-18; browser direct DML is denied |
| `specification_responses` | R-scope; R-admin | CMD | CMD | NONE | Draft writes are command-only through T-18; browser direct DML is denied |
| `unit_claims` | R-scope for holder and authorized supervisors/reviewers; R-admin | CMD | CMD | NONE | Atomic claim and release command; no client expiry edits |
| `review_events` | R-scope for assigned reviewers and authorized supervisors; R-admin | CMD | NONE | NONE | Append-only |
| `inspection_events` | R-scope; R-admin | CMD | NONE | NONE | Append-only |
| `evidence_assets` | R-scope; R-admin | CMD | CMD | NONE | Pending metadata managed by upload commands; finalized metadata immutable |
| `documents` | R-scope; R-admin | CMD | CMD | NONE | Generation/finalization command only; output immutable |
| `print_batches` | R-scope for authorized print/operational roles; R-admin | CMD | CMD | NONE | Batch metadata scoped to project/session/location; created/updated only by bounded batch command; no direct DML |
| `print_events` | R-scope for authorized print/operational roles; R-admin | CMD | NONE | NONE | Append-only per-document attempt; batch reference must be in same authorized scope |
| `attendance_records` | R-scope; R-admin | CMD | CMD | NONE | Lifecycle command only |
| `attendance_documents` | R-scope; R-admin | CMD | CMD | NONE | Replacement creates new version; no overwrite of original |
| `audit_events` | R-admin; R-scope only if a specific audit-read permission is granted | CMD | NONE | NONE | No direct client write; no update/delete for application roles |
| `idempotency_records` | NONE | CMD | CMD | NONE | Internal command machinery; retention cleanup via controlled maintenance |
| `sync_batches` | R-self/R-scope for own device batches only | CMD | CMD | NONE | Batch payload not exposed broadly; no cross-user read |
| `notification_policy_versions` | NONE by default; narrowly scoped configuration read only after explicit grant approval | CMD-051 only | CMD-051 only | NONE | Published immutable; CMD-051 publish-only; no persisted draft CRUD; role/grantor/SoD grants not approved |
| `notification_outbox` | NONE for browser roles; internal worker only | CMD | CMD | NONE | Private fan-out queue; no browser reads; internal worker privilege separately reviewed |
| `notifications` | R-self where `recipient_user_id = auth.uid()` only | CMD-050 set-once read through trusted command; no direct DML | NONE | NONE | No R-admin/global inbox read; dismissed_at is dormant; POQ-03 excludes dismiss/archive from MVP; scope columns never widen recipient ownership |
| `notification_deliveries` | NONE for browser roles; internal worker; narrowly scoped operations reader only if approved | CMD | CMD | NONE | Provider state not exposed to recipients; worker-only mutation |
| `notification_delivery_attempts` | NONE for browser roles; internal worker; restricted audit/operations reader if approved | CMD | NONE | NONE | Append-only sanitized attempts; no provider secrets or message bodies |
| `notification_escalation_events` | NONE for browser roles; internal worker only; restricted operations reader only after explicit approval | CMD | NONE | NONE | Append-only; no browser oversight access inferred from role title |

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
4. **Superseded by T-18 PO APPROVED option A (2026-11-24):** browser-facing direct DML is denied on protected business/governance tables, including draft answer/response tables. Draft persistence uses the trusted Vercel route → caller-JWT PostgreSQL command function. The remaining work is the exact table grants, command EXECUTE grants and executable verification.
5. Evidence retention/deletion and legal-hold policy.
6. **INS-016 PO APPROVED (T-15 option A):** implement append-only audit writes and atomic fail-closed critical commands; institutional retention/legal-hold/disposition and final audit-reader/export authority remain open under T-10.
7. Institutional data classification and privacy/legal basis.



## Command authorization matrix cross-reference

See COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md, section 5, for the 28-family crosswalk against this catalogue's current proposed 48 tables. That crosswalk identifies registry domains for retention/legal-hold, security cases and provider/release that are not represented by current tables, plus the unresolved audit-export artifact model. These are inventory gaps, not permission to create or expose new tables. Update this catalogue before any such object is introduced or exposed. The matrix and this catalogue remain design artifacts; no RLS policy or grant is deployed or verified.

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



## T-14 — Capacity predicate and authorization consistency (PO-approved 2026-11-24)

RLS and privileged capacity commands must consistently recognize a qualifying Inspector account as a distinct enabled login account with an active Inspector role grant and at least one currently effective operational Inspector assignment within the governed project/session scope. Do not count pending, rejected, suspended, disabled or expired-role accounts; do not count one account more than once for multiple roles/assignments. The global combined cap remains 1–100 (default 50) and must be enforced atomically by the privileged transaction, not by client-side/RLS count-then-write logic. No executable policy is implied by this design note.


## T-18 — Direct-DML and command grant decision reconciliation

The former open question about direct draft writes is CLOSED by T-18 option A. No browser-facing anon/authenticated role may INSERT, UPDATE or DELETE protected business/governance tables, including draft response tables, membership, assignments, instrument configuration/publication, evidence metadata, revisions, claims, audit or idempotency records. Draft writes use the trusted command boundary; ordinary reads remain independently scoped by RLS.

The catalogue still requires a table-by-table privilege review, exact command-function EXECUTE grants, review of views/triggers/functions and any SECURITY DEFINER exceptions, plus positive/negative authorization tests. This document remains a policy design artifact; no executable policies or grants are deployed or verified.

## Function ACL and caller-role dependency

See [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md) for the independent function EXECUTE and table ACL posture. CMD means command-only mutation, not table DML for the caller role. RLS policies do not grant SQL privileges. Exact ACL and caller-role verification remains open; no grants are deployed.

## NLA-001 notification security notes

- Browser callers can read only their own `notifications` rows and can mutate only their own `read_at` through the trusted CMD-050 command; POQ-03 excludes dismiss/archive from MVP, so `dismissed_at` is dormant with no command, permission or browser mutation. Direct browser DML remains denied.
- No browser role reads or mutates outbox, delivery queue, provider attempt or escalation worker tables.
- Policy versions require explicit config scope and `notification.policy.manage`; no role-to-permission grant is implied by title.
- Internal worker role, owner, JWT/scheduler trust, exact EXECUTE ACL and effective privileges are a separate T-18 security blocker.
- Every new row above requires table-specific positive/negative RLS tests and exact grants before exposure.


### Notification least-privilege reconciliation — 2026-11-24

- notifications is recipient-self SELECT only; no R-admin/global browse path is proposed. CMD-050 read acknowledgement is a trusted-command mutation with a recipient-self predicate; browser direct UPDATE remains denied.
- notification_policy_versions is default-deny for browser roles. Any scoped configuration read requires an explicit approved grant; CMD-051 publication remains a trusted command and no role grant is implied.
- notification_outbox, notification_deliveries, notification_delivery_attempts and notification_escalation_events are not browser-readable or browser-mutable. Internal workers require a separately approved workload identity and exact function ACL; service_role is not an assumed worker identity.
- INT-NOTIF-001 is a server-side provider integration ingress, not a browser RPC and not a table grant.
- Exact policies, grants, function owners, worker identity and live RLS tests remain unverified. These are design-only dispositions.


## Final audit correction — notification mutation boundary (2026-11-24)

The earlier summary phrase “approved dismiss field” was inconsistent with the canonical CMD-049–054 contract and the table-level rule that dismissed_at is dormant. It is corrected: only recipient-owned read_at is currently exposed through CMD-050; no dismiss command or browser mutation is approved.


## POQ-03 RLS disposition — 2026-11-24

Dismiss/archive is excluded from MVP by explicit Product Owner decision. There is no dismiss command, permission, browser write or UX action. The only recipient mutation in MVP is the trusted CMD-050 set-once read_at transition. Any retained dismissed_at column is dormant and must not receive a browser UPDATE policy or trusted mutation path. Worker identity, exact ACLs and live RLS verification remain open.


## Candidate-only RLS and authorization annex — CMD-035/036/038/039/040 (2026-11-24)

**Status:** Review mapping only. The matrix below does NOT add tables to the canonical 48-table inventory, does NOT create permissions, and does NOT authorize policies or grants. Candidate objects remain unadmitted pending the approvals listed in DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001 v0.1.0.

| Candidate object family | Existing command/permission mapping | Browser SELECT | Browser INSERT/UPDATE/DELETE | Trusted boundary / unresolved approval |
|---|---|---|---|---|
| sync_batch_operations | CMD-035 / sync.apply | Own batch outcomes only if a minimal read API is approved; no raw device proof or cross-user enumeration | NONE | CMD-035 only; operation result immutability, per-operation transaction boundary and exact RLS predicate open |
| device_bindings | CMD-035 sync.apply is not enrollment authority | Self-owned minimal status only if separately approved | NONE | Enrollment/revocation command and permission are TBD; do not infer from sync.apply |
| document_template_versions | No approved command/permission mapped | Published safe metadata only if separately approved | NONE | Template publication command, permission, grantor ceiling and SoD are TBD; no arbitrary template upload |
| document_generation_jobs | CMD-036 / document.generate | NONE | NONE | Internal renderer workload identity + exact function/table ACL required; document.generate authorizes request, not worker execution |
| document_generation_attempts | CMD-036 / document.generate | NONE | NONE | Internal renderer append-only writer; sanitized operations read only if separately approved |
| print_batch_items | CMD-038 / document.print.batch | Actor/scope-limited result read through a trusted query | NONE | CMD-038 owns immutable manifest creation; no direct browser DML |
| print_batch_item_results | CMD-038 / document.print.batch | Actor/scope-limited result read through a trusted query | NONE | Append-only trusted per-item result path; attempt identity and retries open |
| attendance_verification_events | CMD-040 / attendance.verify | R-scope only for authorized attendance roles, if institutional authority approves | NONE | CMD-040 trusted append-only write; uploader/verifier SoD, location/assignment proof and T-10 retention open |

### Permission registry reconciliation requirement

The PostgreSQL Command Contract Catalogue references canonical permission registry v0.2.2, but this review did not establish the registry's exact repository path or retrieve its authoritative content. Therefore this annex does not claim the permission registry has been updated or that the listed mappings are registry-verified. Before any candidate object is admitted, retrieve the authoritative registry and reconcile exact permission codes, resource scopes, grantor ceilings, SoD, worker principals and EXECUTE/table ACL. In particular, device enrollment and template publication require explicit authorization design; they must not inherit sync.apply or document.generate by assumption.

The existing 48-table policy matrix remains the canonical proposed table inventory. These candidate rows are not live RLS policies and no grant or policy has been deployed or verified.


## CMD-044 candidate-only RLS/ACL annex — NOT ADMITTED (2026-11-24)

**T-10 BLOCKED.** The following matrix is a future review boundary only. It adds no rows to the canonical 48-table RLS catalogue and authorizes no browser SELECT, DML, GRANT, policy or worker principal.

| Candidate object | Browser SELECT | Browser INSERT/UPDATE/DELETE | Internal access candidate | Required boundary before admission |
|---|---|---|---|---|
| audit_export_jobs | NONE by default; minimal requester-owned status projection only if T-10 approves | NONE | Narrow export coordinator/worker command only | Named requester scope, policy-version binding, idempotency and fenced lease; exact worker role/ACL open |
| audit_export_manifests | NONE | NONE | Finalizer-only immutable insert; approved integrity verifier read | Immutable after finalization; exact event identity/projection policy and canonical serialization approved |
| audit_export_artifacts | NONE; no object key or signed URL exposed | NONE | Finalizer writes metadata after private Storage verification; download service resolves separate access decision | Private bucket, encryption/key custody, approved region, separate download authority, expiry/retention/legal hold/deletion |

No candidate object inherits access from audit.read or audit.export automatically. audit.export authorizes only the approved export request boundary if T-10 later permits it; it does not itself authorize artifact download. Worker identities must be dedicated, non-user workload principals with exact table/function ACL, no browser EXECUTE and no service_role impersonation. No direct browser DML on audit records or candidate export records is permitted.

The candidate annex is excluded from the 48-table canonical inventory. T-10 authority, purpose, classification, SoD, field projection, recipient, retention/legal hold, storage provider/region, encryption/key custody and deletion evidence remain blockers.


## POQ-01 candidate notification audience snapshot RLS/ACL — NOT ADMITTED (2026-11-24)

**Candidate relation:** `notification_outbox_recipients`. This is a future-review security boundary only; it is not added to the canonical 48-table RLS inventory and no policy/grant is approved.

| Access path | Candidate policy |
|---|---|
| Anonymous/browser SELECT | DENY |
| Authenticated/browser SELECT | DENY, including recipient self; candidate audience is not an inbox/read API |
| Browser INSERT/UPDATE/DELETE | DENY |
| Source domain command transaction | Narrow server-owned command path may insert the event-time snapshot atomically with source event/outbox, only after exact T-18 function review |
| CMD-052 workload | SELECT only for rows belonging to the claimed outbox and current fenced lease; no direct mutation of immutable recipient/scope snapshot |
| Admin/operations | No default access; break-glass or diagnostics require separately approved purpose, scope and audit |

Candidate immutable fields: outbox_id, recipient_user_id, project/session/location/assignment scope references, scope_snapshot_hash and resolved_at. The snapshot must be complete before outbox work is claimable. Candidate rows cannot be updated to replace recipients after source-event time; current dispatch restrictions are represented by channel suppression outcomes, not snapshot edits.

The workload identity, function owner, exact EXECUTE ACL, caller-JWT propagation, RLS interaction and lease predicate remain T-18 review items. No worker may impersonate service_role or receive an authenticated-user permission. Candidate relation is NOT ADMITTED and does not change the canonical 48-table count.


## 10. Technical SSOT Closure — Admitted 14-Table RLS Policy Extension (Total 62/62 Parity, 2026-11-27)

All 62 canonical tables in `Physical Schema v1.0.0` MUST have `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY`, with zero direct browser `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE` grants (`CMD` = `app_cmd_definer` / `app_worker_definer` only).

| # | Table | SELECT | INSERT | UPDATE | DELETE | Policy Guard |
|---:|---|---|---|---|---|---|
| 49 | `account_requests` | `R-self; R-admin` | `CMD` | `CMD` | `NONE` | Applicant reads own requests; `super_admin` reads approval queue |
| 50 | `inspection_draft_contexts` | `R-scope` (own active claim / assigned supervisor) | `CMD` | `CMD` | `NONE` | Mutable draft context bound to active claim/session |
| 51 | `inspection_reviewer_assignments` | `R-scope; R-admin` | `CMD` | `CMD` | `NONE` | Assigned reviewer and project/session supervisors only |
| 52 | `inspection_abort_requests` | `R-scope; R-admin` | `CMD-055` | `CMD-056` | `NONE` | Original Inspector + assigned Admin/Korlap/Super Admin |
| 53 | `inspection_abort_decisions` | `R-scope; R-admin` | `CMD-056` | `NONE` | `NONE` | Append-only; `decider_user_id != requester_user_id` |
| 54 | `device_bindings` | `R-self; R-admin` | `CMD` | `CMD` | `NONE` | User sees own bound devices only |
| 55 | `sync_operation_results` | `R-self` (via own `sync_batch`) | `CMD-035` | `NONE` | `NONE` | Append-only per-operation sync outcomes |
| 56 | `document_versions` | `R-scope; R-admin` | `CMD-036` | `CMD-036` (`SUPERSEDED` flag only) | `NONE` | Immutable artifact hash/key; Print Officer sees authorized scope |
| 57 | `document_generation_jobs` | `R-scope` (safe status only); worker internal | `CMD-036` | Worker `app_worker_definer` | `NONE` | No browser DML; lease columns internal |
| 58 | `document_print_counters` | `NONE` | `CMD-037/038` | `CMD-037/038` | `NONE` | Internal sequence allocator; zero browser access |
| 59 | `print_batch_items` | `R-scope` (authorized Print Officer/Admin) | `CMD-038` | `NONE` | `NONE` | Immutable ordered manifest |
| 60 | `print_batch_item_results` | `R-scope` (authorized Print Officer/Admin) | `CMD-038` | `NONE` | `NONE` | Append-only per-item attempt outcomes |
| 61 | `attendance_verification_events` | `R-scope` (assigned location Korlap/Admin) | `CMD-040` | `NONE` | `NONE` | Append-only attendance verification decisions |
| 62 | `notification_outbox_recipients` | `NONE` (browser roles); worker `app_worker_definer` only | Source `CMD` | `NONE` | `NONE` | Immutable event-time candidate snapshot (`POQ-01` / `F05-T5`) |

**Closure disposition (2026-11-27):** Exact **62/62** physical-schema-to-RLS design parity is **CLOSED** for `G9-TECH` freeze. Deployed RLS verification and negative-access test execution remain gated to `G11`.
