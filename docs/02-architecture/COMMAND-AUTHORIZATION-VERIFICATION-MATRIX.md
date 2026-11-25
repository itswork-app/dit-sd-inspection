# Command Authorization Verification Matrix

**Status:** Design draft — PO/security review required; not implementation authority  
**Version:** 0.4.2  
**Date:** 2026-11-24  
**Depends on:** T-15, T-16, T-17, T-18; Canonical Permission Registry v0.2.0; RLS and Authorization Design; Privileged Command Boundary and Transaction Specification


## Physical schema/RLS reconciliation dependency

See [Physical Schema ↔ RLS ↔ Command Reconciliation](PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md) for the proposed 48-table physical/RLS name parity and exact key-column crosswalk. The command-family mapping remains logical; this reconciliation does not finalize individual command schemas, RPC signatures, table grants or executable predicates.

## 1. Purpose and decision boundary

This matrix converts the current logical command-family inventory into a reviewable authorization and verification contract. It bridges the PO-approved architecture direction and later API/RPC design. It does not claim that route names, PostgreSQL function names, physical table names, grants, RLS policies or executable tests are finalized.

The Canonical Permission Registry v0.1.0 remains a draft. Permission semantics, legacy mappings, role grants, grant/revoke authority, scope predicates and SoD rules require explicit PO/security review. A permission appearing below is a proposed mapping, not an approved grant.

**Hard boundary:** documentation only. No code, SQL, migration, permission seed, GRANT/REVOKE, RLS policy, RPC, deployment, runtime test, CI change or merge is authorized or performed.

## 2. Common command envelope and mandatory contract

| Concern | Required verification contract | Current disposition |
|---|---|---|
| Transport | Browser/PWA → Vercel Server Route → PostgreSQL command function | T-18 option A PO-approved |
| Request | Versioned envelope; strict allowlisted fields; method/content-type/size/schema validation; reject unknown privileged fields | Exact per-command schemas TBD |
| Authentication | Verify Supabase session; forward caller JWT; reject missing, invalid, expired or revoked session | Architecture approved; implementation absent |
| Actor | PostgreSQL derives subject from auth.uid(); resolve active/approved app_users; never trust actor/role/scope in payload | Required |
| Permission | Resolve canonical code and active grant from database state at transaction time | Registry v0.1.0 draft; grants unapproved |
| Scope | Derive from persisted project/session/location/assignment/resource relationships; payload IDs are selectors, never proof of authority | Exact predicates need PO/security and schema review |
| SoD | Evaluate actor/subject/reviewer/approver/grantor relationships in the same transaction; multiple roles never bypass SoD | Command-specific conditions below; some authority remains open |
| Direct DML | Browser anon/authenticated roles have no INSERT/UPDATE/DELETE on protected business/governance tables; RLS default deny; reads separately scoped | Design only; exact grants/RLS not deployed |
| RPC grants | Specific EXECUTE grant per function and caller role; no generic update-any-row or arbitrary SQL RPC | Function inventory/grants TBD |
| Atomicity | Business mutation, domain event and required audit event commit in one transaction; audit failure rolls back | T-15 option A PO-approved |
| Idempotency | Actor + command + resource scope + key; canonical semantic request hash; same hash returns prior result; different hash returns IDEMPOTENCY_KEY_REUSED; reauthorize before disclosing result | Retention duration open |
| Concurrency | Apply global lock order only to required rows; deterministic ordering for multi-row locks; enforce invariants with constraints/locks | Exact lock set per command TBD |
| Outcomes | Stable typed success/validation/forbidden/conflict/retryable outcomes; no stack traces, secrets, SQL or resource-existence leaks | Exact schemas TBD |
| Observability | Correlation/idempotency references; privacy-safe logs; no JWT, service-role key, signed URL token, raw evidence or unnecessary personal data | Design requirement |
| SECURITY DEFINER | INVOKER default; exception needs rationale, pinned trusted/empty search_path, schema-qualified objects, minimal non-login owner, PUBLIC EXECUTE revoked, narrow grants and unauthorized-caller tests | No exception approved |

## 3. Command-family authorization matrix

Object names below are logical resource/data classes from current architecture and registry, not a final physical schema inventory. Where exact physical names or per-object policies are not established, they remain TBD. RLS read policy, browser DML privilege and RPC EXECUTE privilege must be reviewed separately.

| ID / family | Logical commands | Proposed permission | Actor, scope and SoD contract | Data/RLS/grant review | Atomic audit | Planned tests |
|---|---|---|---|---|---|---|
| CA-01 Account access | request-account-access | account.request | Auth UID maps only to own request; applicant cannot set role/status/scope | app_users and request/decision records (exact request table TBD); self-only read; command-only writes | account.requested | 001 |
| CA-02 Account decision | approve/reject/suspend/reactivate-account | account.approve | Global identity authority; actor != subject; reasoned append-only decision | app_users, account_decisions; protected DML denied; narrow RPC EXECUTE | account.* | 002 |
| CA-03 Role/permission grant | grant-role/revoke-role | role.manage | Grantor authority and target-role ceiling; no self-grant/elevation; T-14 capacity lock for Inspector eligibility | user_roles, permissions, role_permissions, project_capacity_settings; exact grantor policy TBD | role.*, permission.changed | 003–004 |
| CA-04 Scope grant | grant-scope/revoke-scope | scope.manage | Explicit target principal/project/session/location/team; no self-assignment; delegation authority required | user_scope_grants, assignment_members; command-only writes | scope.changed | 005 |
| CA-05 Project lifecycle | create/update-project; close-project | project.manage; project.close | Project-scoped closure; session, inspection, document and actual/target reconciliation gates; reason/confirmation; closure authority still open for approval | projects and related resources; dependency graph/table list TBD | project.created/updated/closed | 006–007 |
| CA-06 Session lifecycle | create/update-session; transition-session | session.manage; session.transition | PO semantics: T-07 states DRAFT/ACTIVE/PAUSED/CLOSED; Korlap may activate/pause/resume/request closure only in assigned scope; Super Admin final closure after gates; CLOSED terminal in ordinary flow; reopen privileged/reasoned/audited. Exact permission grants/transition matrix remain open | sessions, projects; project/session RLS; command-only writes | session.*; CLOSE_REQUESTED action/event only | 008 |
| CA-07 Assignment/staffing | publish-assignment/change-assignment-members | assignment.manage | Exact project/session/location/instrument; no self-assignment; overlap/staffing rules; published instrument required | operational_assignments, assignment_members; command-only writes | assignment.* | 009 |
| CA-08 Inspector capacity | change-inspector-capacity | capacity.manage | Governed project settings; 1..100; reject below distinct enabled account + active Inspector grant + effective operational assignment count; serialize with role/assignment eligibility | project_capacity_settings, user_roles, assignment_members; one settings-row lock | capacity.limit_changed | 010 |
| CA-09 Target planning | create/update/publish target plan/allocation | target.manage | Authorized project/session planner; published target immutable; target never mutates actuals | target_plans, target_allocations; exact RLS/planner authority TBD | target.* | 011 |
| CA-10 Instrument governance | create-instrument/save-instrument-draft; publish-instrument-version; deactivate-instrument | instrument.manage; instrument.publish; instrument.deactivate | Super Admin global catalog only; separate permissions; declarative allowlist; T-17 A direct publication without second approver; immutable published version; reasoned deactivation; no operational membership implied | instruments, instrument_versions, checklist_sections/items, specification_fields, evidence_slot_definitions, instrument_version_publications; browser DML denied; RPC grants TBD | instrument.* | 012–014 |
| CA-11 Canonical unit identity | register-canonical-unit | unit.register | Canonical key (instrument_type, serial_normalized); identity lookup cannot reveal project activity; conflict never duplicates or silently merges | units; no unaffiliated serial enumeration; command-only writes | unit.registered / identity_conflict_opened | 015 |
| CA-12 Unit project association | associate-unit-to-project/end-unit-project-association | unit.associate; unit.association.end | Explicit project authority; verified unit; reason; durable association episode; no hard delete/history rewrite | unit_project_associations; project-scoped reads; command-only writes | unit.project_associated / ended or revoked | 016 |
| CA-13 Identity conflict | resolve-unit-identity-conflict | unit.identity.resolve | Designated reviewer; minimum necessary metadata; independently verify, associate existing identity or reject with reason | unit_identity_conflicts, units, unit_project_associations; restricted conflict RLS | unit.identity_conflict_resolved/rejected | 017 |
| CA-14 Claim/release | claim-unit/release-unit-claim | inspection.claim | Active association + same-project assignment + matching instrument; global one-active-claim-per-unit; canonical unit lock; server time; preserve draft | units, unit_project_associations, unit_claims, inspections; association-scoped RLS | unit.claimed/claim_released/claim_expired | 018 |
| CA-15 Inspection draft | save-draft | inspection.edit | Own active claim; exact stored association/project/assignment; draft-only; expected row version | inspections, checklist_responses, specification_responses; direct DML denied | inspection.draft_saved | 019 |
| CA-16 Submit/review/reopen | submit-inspection; return-inspection/approve-inspection; reopen-inspection | inspection.submit; inspection.review; inspection.reopen | Required answers/evidence; immutable submitted revision; assigned reviewer != author; expected revision; reopen requires explicit authority/reason and new revision context | inspections, inspection_revisions, review_events, inspection_events, response rows; immutable revision protection | inspection.submitted/returned/approved/reopened | 020–022 |
| CA-17 Evidence upload/finalize | create-upload-intent/confirm-upload | evidence.upload | Exact inspection/assignment/allowed slot; signature/MIME/size/checksum/quota; pending→verified/finalized | evidence_assets and private Storage; Storage policy tied to relational scope; metadata DML denied | evidence.uploaded | 023 |
| CA-18 Evidence read/export | access-evidence/export-evidence | evidence.read; evidence.export | Explicit history authority; export separately granted and purpose/scope-bound; recheck access; short-lived access | evidence_assets/private Storage/export artifact TBD; no public bucket; signed URL/export mechanism TBD | evidence.accessed/downloaded/exported | 024–025 |
| CA-19 Offline sync | sync-batch | sync.apply | Own bound device and previously claimed draft; server reauthorization; no offline claim/approval/final submit/admin; idempotent partial outcomes and conflict preservation | sync_batches, inspections, responses, evidence_assets; sync internals narrowly scoped | sync.batch_applied/conflicted + domain events | 026 |
| CA-20 Document generation | generate-approved-pdf/generate-document | document.generate | Authorized resource/project; exact approved revision/template snapshot; immutable artifact metadata | documents, inspection_revisions, attendance_records; artifact RLS/Storage TBD | pdf/ba/attendance.generated | 027 |
| CA-21 Print | record-print/record-print-batch | document.print; document.print.batch | Per-document scope; bounded batch; each item separately authorized/idempotent; partial outcomes; atomic monotonic sequence; failed-only retry | documents, print_events; append-only print history; batch authority remains draft | document.printed/reprinted + batch outcome | 028–029 |
| CA-22 Attendance | upload-attendance-document/verify-attendance | attendance.upload; attendance.verify | Assigned Korlap/location; distinct upload and verify; upload never verifies; replacement versions append | attendance_records, attendance_documents; location RLS; command-only writes | attendance.uploaded/replaced/verified | 030 |
| CA-23 Report read | get-actual-report/get-target-report | report.read | Effective project/session scope; actual and target separate; read-only; no actual mutation | inspections, target_plans, target_allocations; row-scoped SELECT | report.accessed where catalogue requires | 031 |
| CA-24 Audit read/export | read-audit/export-audit | audit.read; audit.export | Purpose-bound scope; export separately granted; institutional authority for global/records access; access itself audited | audit_events/export artifacts; SELECT/EXECUTE separation; no direct audit DML | audit.accessed/search_performed/exported | 032–033 |
| CA-25 Retention/legal hold | retention/legal-hold commands | retention.manage | Institutional records authority only after written T-10 direction; legal hold precedence; no irreversible disposition before policy approval | audit_events, evidence_assets, Storage, retention records; exact schema TBD; command-only | legal_hold.* / retention.disposition_* | 034 |
| CA-26 Security case review | security incident commands | security.review | Designated security reviewer; case-scoped minimum access; no blanket Super Admin equivalence | Security case/restricted audit classes; exact schema TBD | security.incident_* | 035 |
| CA-27 Provider/release | provider configuration; deployment/rollback | provider.manage; release.manage | Named custodian/release operator under approved ownership/process; SoD per institutional policy; T-12 evidence unresolved | Provider/environment configuration and release records; exact schema/authority TBD | provider.configuration_changed / production.release_* | 036 |

## 4. Required command-level contract fields

Before implementation, split each family into individual commands and fill every field. A family-level row is not a complete executable contract.

| Field | Acceptance rule |
|---|---|
| Stable command ID/name/version | Unique and stable; aliases/versioning documented |
| Request/response schema | Exact fields, types, bounds, normalization, unknown-field behavior, limits and typed outcomes |
| Permission | Exact approved canonical code(s) |
| Trusted actor | JWT subject → app identity; active account/role resolved at transaction time |
| Scope predicate | Exact relational joins for project/session/location/assignment/resource/history |
| Grantor/delegation | Who may grant/revoke; target-role ceiling; no self-grant |
| SoD | Exact actor vs subject/author/reviewer/approver/grantor checks |
| State preconditions | Allowed current states and transition graph |
| Read/write set | Exact physical tables/views/Storage objects; no guessed names |
| RLS | Per-table operation matrix and predicate for anon/authenticated/server/migration roles |
| RPC EXECUTE | Exact function signature and intended database role; PUBLIC denied unless justified |
| Security mode | INVOKER default; each DEFINER exception separately reviewed |
| Locks/constraints | Exact rows, order, unique/FK/check constraints and race behavior |
| Idempotency | Key scope, canonical hash, retention, replay authorization and concurrent behavior |
| Audit | Exact event schema, atomicity, fail-closed validation and privacy-safe payload |
| Tests | Positive, wrong-role/scope, spoofing, direct DML, audit rollback, replay/hash mismatch and concurrency as applicable |


## 5. Crosswalk to the current proposed 48-table RLS catalogue

The authoritative current proposed 48-table inventory is [Table-by-Table RLS Policy Catalogue](TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md), section 4. It includes T-13 `print_batches` and the six NLA-001 notification tables. The following crosswalk maps command families to its exact listed table names. It does not imply that every listed table is read/write-accessible to the command; the catalogue's R-self/R-scope/R-admin/CMD/NONE rules remain controlling design constraints.

| Command families | Exact tables in current RLS inventory |
|---|---|
| CA-01 / CA-02 Account access and decision | app_users, account_decisions |
| CA-03 Role/permission grant | roles, permissions, role_permissions, user_roles, project_capacity_settings |
| CA-04 Scope grant | user_scope_grants, assignment_members |
| CA-05 Project lifecycle | projects, locations, sessions, operational_assignments, inspections, documents, target_plans, target_allocations, attendance_records (closure dependency reads; exact gate query still TBD) |
| CA-06 Session lifecycle | sessions, projects |
| CA-07 Assignment/staffing | teams, locations, sessions, operational_assignments, assignment_members, instruments, instrument_versions |
| CA-08 Inspector capacity | project_capacity_settings, user_roles, assignment_members |
| CA-09 Target planning | target_plans, target_allocations |
| CA-10 Instrument governance | instruments, instrument_versions, checklist_sections, checklist_items, specification_fields, evidence_slot_definitions, instrument_version_publications |
| CA-11 Canonical unit identity | units |
| CA-12 Unit project association | unit_project_associations, units |
| CA-13 Identity conflict | unit_identity_conflicts, units, unit_project_associations |
| CA-14 Claim/release | units, unit_project_associations, unit_claims, inspections, operational_assignments, assignment_members |
| CA-15 Inspection draft | inspections, checklist_responses, specification_responses, unit_claims, unit_project_associations |
| CA-16 Submit/review/reopen | inspections, inspection_revisions, checklist_responses, specification_responses, review_events, inspection_events, evidence_assets, unit_claims |
| CA-17 / CA-18 Evidence upload/read/export | evidence_assets plus private Storage bucket/object policies |
| CA-19 Offline sync | sync_batches, idempotency_records, inspections, checklist_responses, specification_responses, evidence_assets |
| CA-20 Document generation | documents, inspection_revisions, attendance_records plus private Storage |
| CA-21 Print | print_batches, documents, print_events |
| CA-22 Attendance | attendance_records, attendance_documents |
| CA-23 Report read | inspections, target_plans, target_allocations |
| CA-24 Audit read/export | audit_events; export artifact storage/table is not yet in the 48-table inventory |
| CA-25 Retention/legal hold | audit_events, evidence_assets and private Storage; retention/hold records are not in the current 48-table inventory |
| CA-26 Security case review | No dedicated security-case table is in the current inventory |
| CA-27 Provider/release administration | No provider-configuration or release-record table is in the current inventory |
| CA-28 Notification inbox/policy/workers | notifications, notification_policy_versions, notification_outbox, notification_deliveries, notification_delivery_attempts, notification_escalation_events; internal worker operations are not browser-callable |

**Inventory gap:** the current proposed catalogue has 48 tables and three additional command domains (retention/legal-hold records, security cases, provider/release records) are referenced by the registry but do not have corresponding tables in that inventory. They must remain unimplemented/unexposed until data ownership, schema and RLS/EXECUTE design are approved and the catalogue is updated. Export artifacts also need a deliberate decision on whether they use an existing documents/storage model or a new table; do not assume either.

The physical schema specification and ERD remain authoritative for actual table existence. A table's presence in the RLS catalogue is a proposed policy entry, not evidence of a deployed table or policy.

## 6. Database/RLS reconciliation rules

1. Build the authoritative physical table inventory from ERD and physical schema specification; do not infer names from UI or command labels.
2. For every table, separately record SELECT/INSERT/UPDATE/DELETE for anon, authenticated, command caller, trusted server-only operations and migration owner. Default deny.
3. Link every command to exact RPC signature, EXECUTE grant, security mode, owner and search_path. No wildcard EXECUTE grant.
4. For each read path, document RLS predicate and joins; each command must repeat permission/scope/state checks inside PostgreSQL even if Vercel performs preliminary validation.
5. Treat Storage bucket policies and signed URL issuance as separate authorization surfaces; object key possession is not authority.
6. Canonical unit visibility requires active association + effective project/session/assignment + permission. unit_id alone never grants visibility.
7. Global instrument catalog authority never grants operational project membership.
8. Mutation and audit append commit together. Ordinary application roles cannot update/delete audit.
9. API success, green CI or documentation checks do not prove deployed RLS/grants are correct.

## 7. Open decisions and dependencies

- PO/security approval of permission semantics and all legacy mappings in registry v0.1.0.
- Role-to-permission matrix, grant/revoke authority, role ceilings and exact SoD.
- Project-close permission/authority and closure dependency definition.
- Evidence read/export authority, purpose, limits and signed URL/export mechanism.
- Audit read/export authority and institutional T-10 policy.
- Retention/legal-hold commands blocked pending authorized institutional review.
- Security/platform custodian roles and provider/release authority subject to T-12.
- Exact physical schema, per-table RLS/grants, function list and EXECUTE grants.
- T-16 association/FK/claim technical review and institutional serial normalization/exception policy.
- Offline maximum retry window and idempotency retention.
- Typed API outcome/error alignment and complete audit-event mapping.

## 8. Verification status

- Logical command families mapped: 27.
- Individual command contract draft rows: **54** (CMD-001..054; CMD-049..054 extend the original 48 with notification inbox/policy/worker operations) in PostgreSQL Command Contract Catalogue.
- Approved/executable command-specific contracts: **0**; exact schemas, physical PostgreSQL signatures, role grants, EXECUTE grants, deployed RLS and staging evidence remain incomplete.
- Planned family-level verification IDs: TC-CMD-AUTHZ-024-001 through TC-CMD-AUTHZ-024-036 (36 cases); not executed.
- Planned individual contract cases: TC-CMD-CONTRACT-024-001 through TC-CMD-CONTRACT-024-048 (48 cases); not executed.
- RLS/grants/RPCs deployed: **No evidence / not performed**.
- Runtime/security/concurrency tests executed: **No**.
- Permission registry approved: **No; draft only**.
- Scope freeze: **NOT READY**.
- Implementation authorization: **NOT GRANTED**.

## 9. Change control

Changes to permission codes, command mappings, role grants, scope predicates, RLS, function grants, audit events or test expectations must update this matrix, the Canonical Permission Registry, RBAC, RLS, command boundary, test catalogue and RTM/Package S as applicable. Do not silently alias legacy permissions or infer grants from job titles.

## Individual command contract catalogue dependency

[PostgreSQL Command Contract Catalogue](POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) expands the 28 authorization families into 54 proposed operations (CMD-001..054). The original 48 operations have TC-CMD-CONTRACT-024-001..048; NLA-001 notification operations have TC-NOTIF-001..026 and TC-CMD-AUTHZ-024-037..040. This is a detailed proposal, not 54 approved/executable contracts: exact physical PostgreSQL signatures, API routes, role grants, deployed RLS, EXECUTE grants, approved schemas and runtime evidence remain absent. CMD-045..048 are explicitly blocked pending institutional authority/schema. CMD-052..054 are internal-only workers and require dedicated non-browser identity/ACL review.

## PostgreSQL function security and caller ACL dependency

See [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md) for the function class matrix, exact-signature ACL rules and 62 planned QA cases. No role/ACL inventory has been captured from live Supabase. T-18 Option A resolves the architecture selection; individual function owners, effective privileges, RLS interaction, exact EXECUTE ACLs and caller-JWT route-path evidence remain explicit PO/security implementation blockers.


## CMD-011–020 Product Owner semantic alignment — authorization verification boundary (2026-11-24)

Product semantics for CMD-011–020 are PO APPROVED. This matrix records the approved actor/action boundary where relevant; it does not approve permission codes, role-to-permission mappings, grantor ceilings, RLS predicates, PostgreSQL EXECUTE grants or implementation. CA-06 explicitly preserves the T-07 state vocabulary and prevents Korlap request authority from being interpreted as final-close or reopen authority. T-14 and T-17 remain existing controlling decisions.



## Notification command and integration verification alignment — 2026-11-24

The notification authorization boundary is aligned to NLA-001 v0.1.2 and CMD-049–054 Detailed Contract Review v0.1.1:
- CMD-049 is recipient-self read only with an actor/filter-bound cursor.
- CMD-050 is a trusted recipient-self set-once read transition; no expected_version or direct browser DML.
- CMD-051 is publish-only and requires an approved scoped notification.policy.manage grant; no role assignment is approved.
- CMD-052..054 are internal-only worker/scheduler operations with a separate workload identity and exact EXECUTE ACL still pending.
- INT-NOTIF-001 is a provider-authenticated server integration ingress, not a CMD ID or browser RPC.
- No provider, worker principal, database role, function owner, grant, route or live RLS behavior is verified. TC-NOTIF-001..026 and the notification function-security cases remain PLANNED / NOT EXECUTED.
