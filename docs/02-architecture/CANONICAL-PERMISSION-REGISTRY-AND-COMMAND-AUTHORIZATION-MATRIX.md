# Canonical Permission Registry and Command Authorization Matrix

**Status:** Draft for Product Owner and security review — NOT approved for implementation  
**Version:** 0.1.0 | **Package:** M/N | **Date:** 2026-11-24  
**Authority:** T-15, T-17, T-18; legacy RBAC catalogue and privileged command inventory

## 1. Purpose and mandatory rules

This is the proposed single registry for permission identifiers. It resolves vocabulary drift but does not approve role grants, SQL seeds, RLS policies, PostgreSQL EXECUTE grants, or implementation.

1. Every state-changing command requires an explicit narrow permission and independently validated resource scope.
2. Actor identity is derived from the authenticated Supabase caller JWT at the PostgreSQL boundary using auth.uid(). Caller-supplied actor, role or scope is never authoritative.
3. Role name, UI visibility, global catalog authority, canonical unit ID or client-supplied scope is never sufficient authorization.
4. Grant/revoke authority is separate. No self-elevation; grantors may administer only permissions within their approved authority; separation of duties always applies.
5. T-17 requires separate instrument.manage, instrument.publish and instrument.deactivate permissions.
6. Evidence read/export and audit read/export are distinct permissions. Export is independently authorized and audited.
7. Browser direct INSERT/UPDATE/DELETE on protected business, governance, membership, configuration, evidence, audit and idempotency tables is denied. Mutations use Vercel route → caller-JWT PostgreSQL command function.
8. Unknown permission, missing/ambiguous scope, inactive account, expired grant or failed required audit append means DENY / fail closed.
9. No role-to-permission matrix is approved by this document. Exact role grants, grantor authority, delegation and scope semantics remain PO/security review items.

## 2. Proposed canonical permission registry

All codes are proposed unless explicitly identified as T-17 decisions. Immutable codes and semantics require formal approval before seeding or use.

| Permission code | Capability | Scope class | Grant authority and constraints | Command families | Required audit family |
|---|---|---|---|---|---|
| account.request | Submit own pending access request | SELF | Authenticated applicant; cannot set status, role or scope | request-account-access | account.requested |
| account.approve | Approve/reject/suspend/reactivate account | GLOBAL_IDENTITY | Super Admin; actor != subject; reasoned decision | approve/reject/suspend/reactivate-account | account.* |
| role.manage | Grant/revoke roles and permission bundles | GLOBAL_IDENTITY / PROJECT | Super Admin; no self-grant; administer target role only; SoD | grant-role/revoke-role | role.*, permission.changed |
| scope.manage | Grant/revoke project/session/location/team scope | RESOURCE_SCOPE | Super Admin; no self-assignment; validate target | grant-scope/revoke-scope | scope.changed |
| project.manage | Create/update project metadata | PROJECT | Super Admin; unique code and valid state | create-project/update-project | project.created/updated |
| project.close | Final project closure | PROJECT | Explicit Super Admin authority; gates, reconciliation, reason and confirmation | close-project | project.closed |
| session.manage | Create/update session configuration | PROJECT_SESSION | Super Admin; project scope | create-session/update-session | session.created/updated |
| session.transition | Activate/pause/resume/close/reopen session | PROJECT_SESSION | Super Admin and Korlap only for approved transitions in assigned scope | transition-session | session.* |
| assignment.manage | Publish assignment and change members | PROJECT_SESSION_ASSIGNMENT | Explicit staffing authority; no self-assignment; no overlapping membership | publish-assignment/change-assignment-members | assignment.* |
| capacity.manage | Change combined Inspector cap | PROJECT_CAPACITY | Super Admin; 1..100; reject below T-14 qualifying count; atomic settings-row lock | change-inspector-capacity | capacity.limit_changed |
| target.manage | Create/update/publish target plan and allocation | PROJECT_SESSION | Authorized planner; published target immutable; never writes actuals | target commands | target.* |
| instrument.manage | Create instrument and edit draft configuration | GLOBAL_CATALOG | T-17 explicit; Super Admin; declarative allowlist only | create-instrument/save-instrument-draft | instrument.created/updated/version_drafted |
| instrument.publish | Publish validated immutable instrument version | GLOBAL_CATALOG | T-17 explicit; Super Admin; no second-person approval; publication + audit atomic | publish-instrument-version | instrument.version_published |
| instrument.deactivate | Deactivate instrument from future selection | GLOBAL_CATALOG | T-17 explicit; Super Admin; reason required; pinned history unchanged | deactivate-instrument | instrument.deactivated |
| unit.register | Register canonical physical unit | GLOBAL_UNIT_IDENTITY | Authorized command under verified context; canonical key arbitration | register-canonical-unit | unit.registered/identity_conflict_opened |
| unit.associate | Associate verified unit with project | PROJECT_UNIT_ASSOCIATION | Explicit project authority; verification and reason | associate-unit-to-project | unit.project_associated |
| unit.association.end | End/revoke project association episode | PROJECT_UNIT_ASSOCIATION | Explicit project authority; reason; durable history | end-unit-project-association | unit.project_association_ended/revoked |
| unit.identity.resolve | Resolve same-instrument identity conflict | CONFLICT_REVIEW | Designated reviewer; independent verification; no silent merge | resolve-unit-identity-conflict | unit.identity_conflict_resolved/rejected |
| inspection.claim | Claim/release canonical unit | PROJECT_SESSION_ASSIGNMENT_UNIT | Active association; same-project assignment; matching instrument; global one-active-claim rule | claim-unit/release-unit-claim | unit.claimed/claim_released/claim_expired |
| inspection.edit | Save own claimed draft | INSPECTION_OWNER | Own active claim; expected version; draft state only | save-draft | inspection.draft_saved |
| inspection.submit | Submit complete inspection revision | INSPECTION_OWNER | Own claim; required answers/evidence; no conflicts | submit-inspection | inspection.submitted |
| inspection.review | Return or approve submitted revision | ASSIGNED_REVIEW | Assigned reviewer; expected revision; no self-review | return-inspection/approve-inspection | inspection.returned_for_correction/approved |
| inspection.reopen | Reopen approved inspection | PROJECT_INSPECTION | Explicit Super Admin or separately authorized Admin; reason; preserve prior revision | reopen-inspection | inspection.reopened |
| evidence.upload | Create upload intent and finalize upload | INSPECTION_EVIDENCE | Exact slot, assignment, private storage, checksum/size/quota validation | create-upload-intent/confirm-upload | evidence.uploaded |
| evidence.read | View/read evidence | INSPECTION_HISTORY | Explicit history authority; short-lived access; access audited | access-evidence | evidence.accessed/downloaded |
| evidence.export | Export evidence package | PROJECT_EVIDENCE_EXPORT | Separate explicit export authority; purpose/scope/limits; audit | export-evidence | evidence.exported |
| sync.apply | Apply offline batch for own bound device | SELF_DEVICE_ASSIGNMENT | Previously claimed drafts only; server reauthorization; idempotent partial results | sync-batch | sync.batch_applied/conflicted |
| document.generate | Generate approved PDF/BA/attendance artifact | RESOURCE_DOCUMENT | Exact approved revision/template snapshot; authorized project scope | generate-approved-pdf/generate-document | pdf.generated/ba.generated/attendance.generated |
| document.print | Record individual print/reprint | RESOURCE_DOCUMENT | Authorized document scope; monotonic sequence | record-print | document.printed/reprinted |
| document.print.batch | Orchestrate bounded batch print | RESOURCE_DOCUMENT_BATCH | Each item separately authorized/idempotent; partial outcomes | record-print-batch | Per-document print events and batch outcome |
| attendance.upload | Upload/replace attendance evidence | PROJECT_LOCATION_ATTENDANCE | Korlap/authorized actor in assigned location; upload never verifies | upload-attendance-document | attendance.uploaded/replaced |
| attendance.verify | Verify attendance | PROJECT_LOCATION_ATTENDANCE | Korlap in assigned location; distinct from upload | verify-attendance | attendance.verified |
| report.read | Read actual/target reports | PROJECT_REPORT | Assigned project/session scope; actual and target separated | get-actual-report/get-target-report | report.accessed where policy requires |
| audit.read | Search/read audit events | AUDIT_SCOPE | Purpose-bound least privilege; no implied global access | read-audit | audit.accessed/search_performed |
| audit.export | Export audit events | AUDIT_EXPORT_SCOPE | Separate grant, approved purpose, filters, limits and institutional authority | export-audit | audit.exported |
| retention.manage | Manage approved retention disposition/legal hold | RECORDS_GOVERNANCE | Institutional records authority after T-10; dual control if required | retention/legal-hold commands | legal_hold.* / retention.disposition_* |
| security.review | Review restricted security incidents | SECURITY_CASE | Designated security reviewer; minimum necessary access | security incident commands | security.incident_* |
| provider.manage | Change provider/environment configuration | PLATFORM_GOVERNANCE | Named platform custodian; institutional ownership approval under T-12 | provider configuration commands | provider.configuration_changed |
| release.manage | Deploy/rollback production release | PLATFORM_GOVERNANCE | Named release operator and approved release process | deployment/rollback commands | production.release_* |
| notification.read | Read/mark-read own inbox notifications | SELF | Recipient identity must equal auth.uid(); notification does not grant source-resource access | list-own-notifications/mark-notification-read | notification.read |
| notification.policy.manage | Draft/publish scoped notification policy versions | NOTIFICATION_CONFIG_SCOPE | Explicit config scope, grantor ceiling and SoD; role grants NOT APPROVED | publish-notification-policy | notification.policy_published |

### 2.1 Scope class meanings

SELF = own account/request only. GLOBAL_IDENTITY and GLOBAL_CATALOG = named global administration only, never operational project access. PROJECT/PROJECT_SESSION/PROJECT_SESSION_ASSIGNMENT = explicit effective membership and state. PROJECT_CAPACITY = one governed project's capacity settings; count distinct qualifying Inspector accounts across both locations. GLOBAL_UNIT_IDENTITY = canonical identity only, no project history access. PROJECT_UNIT_ASSOCIATION = exact unit/project association episode. CONFLICT_REVIEW = restricted duplicate-conflict metadata. INSPECTION_OWNER/ASSIGNED_REVIEW/PROJECT_INSPECTION = immutable inspection binding plus current effective assignment/history authority. INSPECTION_EVIDENCE/INSPECTION_HISTORY/PROJECT_EVIDENCE_EXPORT = exact evidence scope with read/export separated. SELF_DEVICE_ASSIGNMENT = authenticated user and bound device for already claimed drafts only. RESOURCE_DOCUMENT and RESOURCE_DOCUMENT_BATCH = exact document version and authorized print scope. PROJECT_LOCATION_ATTENDANCE/PROJECT_REPORT = assigned project/session/location. AUDIT_SCOPE/AUDIT_EXPORT_SCOPE = purpose-bound audit access with export separate. RECORDS_GOVERNANCE/SECURITY_CASE/PLATFORM_GOVERNANCE = named institutional/platform authority only.

## 3. Legacy permission disposition

No silent aliasing. A legacy permission is invalid for a new command until its mapping is approved and existing grants are reviewed/migrated.

| Legacy code | Proposed disposition | Canonical code | Notes |
|---|---|---|---|
| account.review | REPLACE | account.approve | Review existing grants; no implicit grant inheritance |
| role.assign | REPLACE | role.manage | Cannot administer every role by default |
| scope.assign | REPLACE | scope.manage | Explicit scope validation |
| config.manage | RETIRE / SPLIT | instrument.manage, instrument.publish, instrument.deactivate | T-17 separation is mandatory |
| session.manage | RETAIN, NARROW | session.manage | Configuration only; transitions separate |
| assignment.manage | RETAIN, NARROW | assignment.manage | Staffing authority and no self-assignment |
| inspection.claim/edit/submit/review/reopen | RETAIN, NARROW | Same code | Review covers return/approve only after grant policy approval |
| inspection.approve / inspection.return | REVIEW / MERGE CANDIDATE | inspection.review | No silent alias; review old grants and SoD |
| report.view | REPLACE | report.read | Read only |
| report.validate | UNMAPPED / REVIEW | None yet | No matching approved command; deny new use |
| document.print | RETAIN | document.print | Batch orchestration separately authorized |
| document.upload | RETIRE / SPLIT | attendance.upload, attendance.verify | Upload never implies verification |
| audit.view | RETIRE / SPLIT | audit.read, audit.export | Read and export are separate; re-review existing grants |

New command vocabulary includes account.request, account.approve, project.manage, project.close, session.transition, capacity.manage, target.manage, instrument.*, unit.*, evidence.*, sync.apply, document.generate, document.print.batch, attendance.*, report.read, audit.*, retention.manage, security.review, provider.manage and release.manage. Each new code must be approved in this registry before use.

## 4. Command → permission → RLS/data → audit → test traceability

| Command family | Permission | Scope / separation-of-duties | Protected data and RLS classes | Required audit | Dedicated test series (IDs to allocate) |
|---|---|---|---|---|---|
| Request account | account.request | Self only; no role/scope fields | app_users, account_decisions | account.requested | RBAC-REG |
| Approve/reject/suspend/reactivate | account.approve | Global identity; actor != subject | app_users, account_decisions | account.* | RBAC-ACCOUNT |
| Grant/revoke role | role.manage | Grantor authority; no self-elevation; T-14 capacity lock | user_roles, permissions, role_permissions, project_capacity_settings | role.*, permission.changed | RBAC-GRANT |
| Grant/revoke scope | scope.manage | Explicit target; no self-assignment | user_scope_grants, assignment_members | scope.changed | RBAC-SCOPE |
| Project create/update/close | project.manage / project.close | Closure gates, reconciliation, reason and confirmation | projects and related project resources | project.* | PROJ-CMD |
| Session create/update/transition | session.manage / session.transition | Project scope; role-specific transition; closure gates | sessions, projects | session.* | SES-CMD |
| Assignment publish/member changes | assignment.manage | Project/session/location/instrument; overlap and staffing rules | operational_assignments, assignment_members | assignment.* | ASSIGN-CMD |
| Inspector capacity | capacity.manage | T-14 predicate; governed capacity row lock | project_capacity_settings, user_roles, assignment_members | capacity.limit_changed | CAP-CMD |
| Target plan/allocation | target.manage | Project/session planner; published immutable | target_plans, target_allocations | target.* | TARGET-CMD |
| Instrument draft/publish/deactivate | instrument.manage / instrument.publish / instrument.deactivate | Global catalog only; allowlist; pinned history | instruments, instrument_versions, checklist_sections/items, specification_fields, evidence_slot_definitions, instrument_version_publications | instrument.* | INSTR-CMD |
| Canonical unit register/associate/end/resolve | unit.register / unit.associate / unit.association.end / unit.identity.resolve | Canonical serial lock; project association; restricted conflict reviewer | units, unit_project_associations, unit_identity_conflicts | unit.* | UNIT-CMD |
| Claim/release | inspection.claim | Active association; same-project assignment; matching instrument; global uniqueness | units, unit_project_associations, unit_claims, inspections | unit.claimed/claim_released | CLAIM-CMD |
| Draft/submit/review/reopen | inspection.edit / inspection.submit / inspection.review / inspection.reopen | Immutable binding; assignment; SoD; expected version | inspections, inspection_revisions, checklist_responses, specification_responses, review_events, inspection_events | inspection.* | INSP-CMD |
| Evidence upload/finalize | evidence.upload | Exact slot, private object, quota/checksum | evidence_assets and private Storage | evidence.uploaded | EVID-UPLOAD |
| Evidence read/export | evidence.read / evidence.export | History authority; export separately granted | evidence_assets and private Storage | evidence.accessed/downloaded/exported | EVID-ACCESS |
| Offline sync | sync.apply | Own bound device; previously claimed draft; server reauthorization | sync_batches, inspections, responses, evidence_assets | sync.batch_* and domain events | SYNC-CMD |
| Document generate | document.generate | Exact approved revision/template; immutable artifact | documents, inspection_revisions, attendance_records | pdf/ba/attendance.generated | DOC-GEN |
| Individual/batch print | document.print / document.print.batch | Per-document authority/idempotency; durable batch aggregate and partial outcomes | print_batches, documents, print_events | document.printed/reprinted; batch lifecycle | DOC-PRINT |
| Notification inbox | notification.read | Recipient-self only; source resource re-authorized on navigation | notifications | notification.read | NOTIF-INBOX |
| Notification policy | notification.policy.manage | Explicit policy scope; immutable versions; role/grantor matrix pending approval | notification_policy_versions, audit_events | notification.policy_published | NOTIF-POLICY |
| Notification workers | Internal worker principals only; no user permission | Outbox lease, idempotent fan-out/delivery/escalation; worker ACL review required | notification_outbox, notifications, notification_deliveries, notification_delivery_attempts, notification_escalation_events | Dedicated operational telemetry/escalation events | NOTIF-WORKER |
| Attendance upload/verify | attendance.upload / attendance.verify | Korlap assigned location; distinct permissions | attendance_records, attendance_documents | attendance.uploaded/replaced/verified | ATT-CMD |
| Actual/target report read | report.read | Project/session row scope; no actual mutation | inspections, target_plans, target_allocations | report.accessed where policy requires | RPT-CMD |
| Audit read/export | audit.read / audit.export | Purpose/scope; export separate | audit_events and export artifacts | audit.accessed/search_performed/exported | AUD-CMD |
| Retention/legal hold | retention.manage | T-10 institutional authority; legal hold precedence | audit_events, evidence_assets, storage, retention records | legal_hold.* / retention.disposition_* | RET-CMD |
| Security incident review | security.review | Restricted case scope | security incident records and restricted audit events | security.incident_* | SEC-CMD |
| Provider/release administration | provider.manage / release.manage | Named custodian/release operator; institutional approval | provider/environment configuration and release records | provider.configuration_changed / production.release_* | OPS-CMD |

The test series above are reserved identifiers, not existing test cases. Before implementation authorization, allocate unique concrete IDs, fixtures, exact function names, request schemas, typed outcomes, audit expectations, idempotency/replay, failure-injection and concurrency cases. Generic TC-CMD-018 does not prove each command's business invariant.

## 5. Role and grant matrix — NOT APPROVED

The following are constraints, not grants.

| Principal class | Candidate permission scope | Prohibited implicit authority |
|---|---|---|
| Applicant/pending | account.request for self | Operational access, role/scope, project or evidence access |
| Inspector | inspection.claim/edit/submit and evidence.upload only within effective assignment, if explicitly granted | Review/approve, cross-assignment reads, unit-global visibility, role/scope grants |
| Reviewer | inspection.review and evidence.read within assigned review scope, if explicitly granted | Self-review, role/scope grant, evidence export by implication |
| Korlap | session.transition only for allowed assigned-scope transitions; attendance.upload/verify separately | Global session control, project close, evidence export, account/role grants |
| Print Officer | document.print within authorized document scope | Document generation/edit; evidence/audit export |
| Admin | Explicitly delegated project/operational permissions | Global catalog administration, project close, audit export, role administration by default |
| Super Admin | Explicit global administration permissions; T-17 catalog permissions separately granted | Automatic operational assignment, unrestricted evidence/audit export, SoD bypass, unrestricted DB access |
| Security/Records/Platform custodian | security.review / retention.manage / provider.manage / release.manage under named authority | Ordinary operational data access or blanket Super Admin equivalence |

No role-to-permission grant is approved. PO and institutional security must confirm grant matrix, delegation, scope types, role combinations, SoD and break-glass process.

## 6. RLS and database grant contract

For every exposed table, view, Storage bucket and RPC, record object name, data classification, SELECT policy, INSERT/UPDATE/DELETE policy, RLS helper, permission, scope derivation and negative test. Protected-table browser writes are denied, including draft response tables. Command functions receive exact EXECUTE grants; no generic command executor or PUBLIC execute. Audit and immutable history have no application UPDATE/DELETE path. Idempotency and internal sync payloads have no browser access. Private Storage access is never authorized by object-key possession. View/function security modes are reviewed. SECURITY DEFINER requires pinned search_path, schema-qualified references, safe owner and minimal grants. Migration owner, service role and runtime caller are separate trust principals. Every command derives actor from auth.uid() and rechecks permission/scope/state inside PostgreSQL.

The current proposed RLS catalogue contains 48 table entries; that is not evidence RLS or grants exist or are correct. Reconcile all tables, views, functions, buckets and future objects before implementation.

## 7. Audit contract

T-15 requires critical permission/command events to be appended atomically with protected mutation. Audit role/scope/permission grants and revokes; account decisions; instrument draft/publish/deactivate; project/session/assignment/capacity/target changes; unit association/conflict/claim; inspection lifecycle; evidence upload/access/download/export; document generation/print; attendance upload/verify; audit read/export; retention/legal hold; provider/release changes. Audit append failure rolls back critical state mutation. T-10 institutional retention, legal hold, deletion/disposition, network metadata and final audit reader/export authority remain open.

## 8. Approval and closure checklist

- [ ] PO approves canonical code set and semantics.
- [ ] PO approves/rejects each legacy mapping and retirement.
- [ ] PO approves role-to-permission and delegation matrix.
- [ ] PO confirms project-close, evidence read/export, audit read/export, security and platform custodian authority.
- [ ] Institution approves T-10 records/privacy/security matters.
- [ ] Every command maps to exact permission and scope predicate.
- [ ] Every permission maps to grant/revoke authority and SoD.
- [ ] Every table/view/Storage bucket maps to exact RLS and browser DML posture.
- [ ] Every PostgreSQL function maps to exact EXECUTE grant and security mode.
- [ ] Every command maps to audit event, idempotency and typed outcomes.
- [ ] Every command has dedicated positive/negative/audit-failure/replay/concurrency test IDs.
- [ ] Legacy grants are inventoried and migrated without erasing history.
- [ ] Security review and staging verification evidence is attached.

**Disposition:** DRAFT / NOT APPROVED. This document does not authorize permission seed, grants, schema migration, route/RPC implementation, runtime tests, deployment or scope freeze.

## Individual command contract reference

The [PostgreSQL Command Contract Catalogue](POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) expands the registry's 28 logical families into 54 proposed operations (CMD-001..054): 48 original domain operations plus six NLA-001 notification operations. The original 48 have individual contract test IDs; notification operations have lifecycle tests TC-NOTIF-001..018 and authorization tests TC-CMD-AUTHZ-024-037..040. This does not approve any permission semantics, role grant, grantor authority, RPC signature or EXECUTE grant. The registry remains a PO/security review draft and is not permission-seed authority.

## Function ACL and caller execution model

See [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md). Permission grants and PostgreSQL EXECUTE grants are different: the former authorize a business action; the latter permit function invocation. Neither implies the other. Registry v0.1.0 remains a PO/security draft; no role mapping or EXECUTE grant is approved.

## NLA-001 permission extension

`notification.read` is self-scoped and never grants access to the referenced project/inspection/evidence. `notification.policy.manage` is a proposed scoped configuration permission; no role-to-permission assignment or grantor authority is approved. CMD-052..054 are internal worker operations and must not be represented as user-role permissions. Add exact scope predicates, grants, negative tests and SoD review before implementation.
