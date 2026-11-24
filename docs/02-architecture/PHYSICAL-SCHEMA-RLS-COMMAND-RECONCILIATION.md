# Physical Schema ↔ RLS ↔ Command Reconciliation

**Status:** Engineering/security reconciliation draft — review required; no implementation authority  
**Version:** 0.2.0  
**Date:** 2026-11-24  
**Scope:** Package L physical table catalogue, Package M table-by-table RLS catalogue, logical ERD, T-18 command boundary and command authorization matrix.

## 1. Executive result

A line-by-line name comparison of the current Package L physical table catalogue and Package M RLS catalogue finds **48 physical tables and 48 RLS entries with exact name parity**: no physical table is missing from the RLS catalogue and no RLS table is absent from the physical catalogue.

This is a documentation inventory check only. It does not prove the tables exist in a live Supabase project, that RLS is enabled, that any policy is deployed, or that grants are correct.

The prior two ERD-only entities have been dispositioned in the documentation design: T-13 requires `print_batches`, and INS-015's ambiguous `notification_events` placeholder is replaced by six explicit notification lifecycle tables. The proposed physical schema and RLS catalogue now each contain 48 tables with exact name parity. This is static documentation reconciliation only, not live database verification.

## 2. Controlling sources and rules

- [Physical Database Schema and Integrity Specification](PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md) defines the 41 proposed physical tables and key columns.
- [Table-by-Table RLS Policy Catalogue](TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md) defines the proposed 48-table SELECT and mutation posture.
- [Data Model and ERD](DATA-MODEL-AND-ERD.md) is the logical model and currently names additional entities.
- [Command Authorization Verification Matrix](COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md) maps logical command families and their authorization/testing responsibilities.
- T-18 option A is PO-approved: browser-facing anon/authenticated roles receive no direct INSERT/UPDATE/DELETE on protected business/governance tables. Mutations run through narrowly granted PostgreSQL command functions with caller JWT. RLS remains an independent read boundary.

Interpretation: the catalogue's INSERT/UPDATE value `CMD` means a mutation may occur only inside an authorized trusted command transaction. It is **not** a direct PostgREST/browser table grant. `NONE` means no direct browser table access for that operation. Exact database role grants and command-function EXECUTE grants remain unapproved/unimplemented.

## 3. Proposed 48-table inventory and privilege posture

The key-column/constraint descriptions are transcribed from Package L; SELECT classes and mutation classifications are transcribed from Package M. This table is a review crosswalk, not executable SQL.

| Physical table | Key columns (Package L) | Proposed SELECT class | INSERT / UPDATE / DELETE (Package M) | Integrity focus |
|---|---|---|---|---|
| `app_users` | `id, auth_user_id, display_name, approval_status, account_status` | R-self; R-admin | CMD/CMD/NONE | Unique `auth_user_id`; one application profile per Auth identity; constrained status; no operational access unless approved and active |
| `roles` | `id, code, name, is_system, status` | R-admin; optionally authenticated read of non-sensitive active role labels | CMD/CMD/NONE | Unique normalized role code; system roles cannot be deleted |
| `permissions` | `id, code, description` | R-admin | CMD/CMD/NONE | Unique permission code; immutable code after use |
| `role_permissions` | `role_id, permission_id` | R-admin | CMD/CMD/NONE | Composite primary key |
| `user_roles` | `user_id, role_id, valid_from, valid_until, status, granted_by, reason` | R-self limited to own grants; R-admin | CMD/CMD/NONE | FK; valid interval; indexes by user/status and role/status; grant/revoke audited |
| `user_scope_grants` | `user_id, scope_type, scope_id, permission_id or role reference, effective interval` | R-self limited to own effective grants; R-admin | CMD/CMD/NONE | Constrained scope type; no implicit location inheritance; scope target integrity validated by trusted command |
| `account_decisions` | `user_id, decision, actor_id, reason, decided_at` | R-self limited to own decision history; R-admin | CMD/NONE/NONE | Append-only; actor cannot approve own account |
| `projects` | `id, code, name, status, timezone` | R-scope; R-admin | CMD/CMD/NONE | Unique project code; valid IANA timezone |
| `locations` | `id, project_id, code, name, status` | R-scope; R-admin | CMD/CMD/NONE | Unique `(project_id, code)`; project FK |
| `sessions` | `id, project_id, code, status, starts_at, ends_at` | R-scope; R-admin | CMD/CMD/NONE | Unique `(project_id, code)`; valid interval; explicit state transition command |
| `teams` | `id, project_id, code, name, status` | R-scope; R-admin | CMD/CMD/NONE | Unique `(project_id, code)` |
| `operational_assignments` | `id, project_id, session_id, location_id, instrument_id, instrument_version_id, team_id, starts_at, ends_at, status` | R-scope; R-admin | CMD/CMD/NONE | Composite FKs or command validation prove every referenced row belongs to same project; exactly one location/instrument/team; interval valid; selected instrument version is published |
| `assignment_members` | `id, assignment_id, user_id, operational_role, valid_from, valid_until, status` | R-scope for relevant assignment; R-admin | CMD/CMD/NONE | FK; valid interval; unique active membership for same assignment/user/role; indexes by user and assignment |
| `project_capacity_settings` | `project_id, inspector_cap, updated_at, updated_by` | R-admin; read-only operational summary if approved | CMD/CMD/NONE | One row per project; CHECK integer 1..100; default 50; all cap-affecting commands lock this row |
| `target_plans` | `id, project_id, version, status` | R-scope; R-admin | CMD/CMD/NONE | Unique `(project_id, version)`; published plans immutable |
| `target_allocations` | `id, target_plan_id, assignment_id, target_date, quantity` | R-scope; R-admin | CMD/CMD/NONE | Nonnegative integer quantity; unique allocation key as defined by target dimension; never rewrites actual activity |
| `instruments` | `id, code, name, description, status, created_by` | R-published; R-admin | CMD/CMD/NONE | Unique immutable code; status ACTIVE/INACTIVE/ARCHIVED; Super Admin command controls lifecycle |
| `instrument_versions` | `id, instrument_id, version_number, status, schema_version, published_at, published_by` | R-published; R-admin | CMD/CMD/NONE | Unique `(instrument_id, version_number)`; DRAFT/PUBLISHED/RETIRED; published rows immutable |
| `checklist_sections` | `id, instrument_version_id, code, label, sort_order` | R-published; R-admin | CMD/CMD/NONE | Unique code/order within version; FK |
| `checklist_items` | `id, section_id, code, label, answer_type, sort_order, required, applicability_rule, validation_config` | R-published; R-admin | CMD/CMD/NONE | Unique code/order within section; answer_type allowlist; declarative validation only |
| `specification_fields` | `id, instrument_version_id, code, label, value_type, expected_value, unit, required, sort_order` | R-published; R-admin | CMD/CMD/NONE | Unique code/order per version; constrained value_type; typed values validated server-side |
| `evidence_slot_definitions` | `id, instrument_version_id, code, label, required, allowed_media_types, sort_order, applicability_rule` | R-published; R-admin | CMD/CMD/NONE | Unique code/order per version; MIME allowlist; limits inherited from approved global evidence policy |
| `instrument_version_publications` | `instrument_version_id, published_by, published_at, change_summary` | R-scope; R-admin | CMD/NONE/NONE | Append-only publication record |
| `units` | `id, instrument_id, serial_raw, serial_normalized, normalization_version, status` | R-scope; R-admin | CMD/CMD/NONE | Canonical physical identity; no `project_id`; unique `(instrument_id, serial_normalized)` for non-null serial; retain raw input and normalization version |
| `unit_project_associations` | `id, unit_id, project_id, status, associated_at, associated_by, association_reason, ended_at, ended_by, end_reason` | R-scope through matching project membership; R-admin | CMD/CMD/NONE | Status ACTIVE/ENDED/REVOKED; valid start/end interval; FK to canonical unit and project; partial unique ACTIVE `(unit_id, project_id)`; unique `(id, unit_id, project_id)` for composite references; no hard delete |
| `unit_identity_conflicts` | `id, instrument_id, serial_normalized, serial_raw_submitted, proposed_project_id, candidate_unit_id, reported_by, status, resolution, resolved_by, resolution_reason, created_at, resolved_at` | R-conflict-reviewer; minimum necessary project-scoped metadata only | CMD/CMD/NONE | Durable controlled duplicate workflow; candidate FK; reasoned/audited resolution; never creates a second canonical unit by itself |
| `inspections` | `id, unit_id, unit_project_association_id, project_id, assignment_id, status, current_revision_no, row_version` | R-scope according to Inspector/Reviewer/Korlap/Print Officer permissions; R-admin | CMD/CMD/NONE | Composite FK proves association matches unit+project and assignment belongs to same project; command proves instrument match and active association; one active inspection lifecycle per canonical unit subject to authorized reopen/reinspection rules |
| `inspection_revisions` | `id, inspection_id, revision_no, instrument_version_id, snapshot_hash, author_id, submitted_at, payload_snapshot` | R-scope; R-admin | CMD/NONE/NONE | Unique `(inspection_id, revision_no)`; immutable after submission; instrument version must match assignment snapshot |
| `checklist_responses` | `id, inspection_revision_id, checklist_item_id, answer, note, answered_by, answered_at` | R-scope; R-admin | CMD/CMD/NONE | Unique `(inspection_revision_id, checklist_item_id)`; item belongs to revision's instrument version; answer conforms to item schema |
| `specification_responses` | `id, inspection_revision_id, specification_field_id, observed_value, note` | R-scope; R-admin | CMD/CMD/NONE | Unique per revision/field; field belongs to exact version |
| `unit_claims` | `id, unit_id, unit_project_association_id, project_id, assignment_id, inspector_id, status, claimed_at, expires_at, released_at, row_version` | R-scope for holder and authorized supervisors/reviewers; R-admin | CMD/CMD/NONE | Composite FKs prove association and assignment share project+unit; partial unique index on canonical `unit_id` for ACTIVE claim across projects; valid expiry; unit-row lock for acquisition/expiry takeover |
| `review_events` | `id, inspection_revision_id, reviewer_id, decision, reason, created_at` | R-scope for assigned reviewers and authorized supervisors; R-admin | CMD/NONE/NONE | Append-only; decision constrained; author != reviewer for approve; one terminal decision per revision unless explicit workflow permits |
| `inspection_events` | `id, inspection_id, event_type, actor_id, from_state, to_state, reason, created_at` | R-scope; R-admin | CMD/NONE/NONE | Append-only; state update and event insert in same transaction |
| `evidence_assets` | `id, inspection_id, inspection_revision_id, slot_definition_id, object_key, sha256, byte_size, mime_type, upload_status, uploaded_by` | R-scope; R-admin | CMD/CMD/NONE | Unique object key; checksum format; nonnegative size; slot belongs to exact instrument version; immutable finalized object identity |
| `documents` | `id, project_id, inspection_revision_id, document_type, template_version, source_hash, output_hash, object_key, status` | R-scope; R-admin | CMD/CMD/NONE | Unique generation key per source revision/template/type where appropriate; immutable generated artifact |
| `print_events` | `id, document_id, actor_id, sequence_no, client_print_signal, created_at` | R-scope for authorized print/operational roles; R-admin | CMD/NONE/NONE | Unique `(document_id, sequence_no)`; append-only; signal does not claim physical printer confirmation |
| `attendance_records` | `id, project_id, session_id, status` | R-scope; R-admin | CMD/CMD/NONE | One logical attendance record per defined session/scope |
| `attendance_documents` | `id, attendance_record_id, object_key, sha256, uploaded_by, status` | R-scope; R-admin | CMD/CMD/NONE | Append-only replacement versions; replacement reason required |
| `audit_events` | `id, actor_id, action, target_type, target_id, scope, correlation_id, created_at, metadata` | R-admin; R-scope only if a specific audit-read permission is granted | CMD/NONE/NONE | Append-only at DB privilege level; indexes by actor/time, target/time, correlation ID |
| `idempotency_records` | `id, actor_id, command_type, scope_key, idempotency_key, request_hash, result_reference, status, expires_at` | NONE | CMD/CMD/NONE | Unique `(actor_id, command_type, scope_key, idempotency_key)`; same key/different hash rejected; retention > maximum offline retry window |
| `sync_batches` | `id, actor_id, device_id, batch_key, payload_hash, status, acknowledged_at` | R-self/R-scope for own device batches only | CMD/CMD/NONE | Unique actor/device/batch key; replay safe; conflict records retained |

## 4. Reconciliation findings

### 4.1 Exact parity

- Package L physical table count: 41.
- Package M RLS catalogue table count: 41.
- Physical tables without an RLS catalogue row: none.
- RLS rows without a physical table specification: none.
- The two inventories have proposed exact name parity at 48/48, including `print_batches` and the six notification lifecycle tables. `notification_events` is removed from the logical ERD and is not a physical table.

### 4.2 Disposition of former ERD-only entities

| Former discrepancy | Design disposition | Evidence | Remaining gate |
|---|---|---|---|
| `print_batches` | RETAIN and add to physical schema/RLS. T-13 option B requires a durable batch ID and per-document outcomes. `print_events` stores append-only per-document attempts and optional batch reference. | T-13 PO-approved decision; API contract §6 print/batch-print; NLA-001 print model | Exact schema constraints, lock order, route contract and tests need technical review |
| `notification_events` | REMOVE as ambiguous placeholder. Replace with `notification_policy_versions`, `notification_outbox`, `notifications`, `notification_deliveries`, `notification_delivery_attempts`, `notification_escalation_events`. | INS-015 PO-approved direction; NLA-001 v0.1.0 | PO/security review, worker principal/ACL, T-10 retention/privacy and provider approvals |

The 48/48 count is a proposed documentation inventory. It does not prove live database existence, deployed RLS or grants.

### 4.3 T-18 privilege interpretation gap

The RLS catalogue correctly classifies protected mutations as `CMD`, but it does not yet provide a per-table PostgreSQL privilege grant script or exact command-function signatures. The following must be separately enumerated and reviewed:

1. Table privileges for `anon`, `authenticated`, trusted command caller, service-only execution identity (if any), and migration owner.
2. Explicit `REVOKE` posture for browser roles on INSERT/UPDATE/DELETE and on protected sequences where relevant.
3. Narrow `GRANT EXECUTE` for every individual command function; no wildcard function execution.
4. Function owner, SECURITY INVOKER/DEFINER mode, fixed search_path, PUBLIC execute revocation and nested object privileges.
5. SELECT grants and RLS policies independently; a SELECT grant without a matching RLS policy must remain deny-by-default.
6. Storage bucket/object policies and signed URL issuance separately from relational table RLS.
7. Views, materialized views, triggers, helper functions, sequences and extensions are separate attack surfaces; none is covered merely by a table count.

### 4.4 Table-level policy is not a complete command contract

The SELECT classes `R-self`, `R-scope`, `R-admin`, `R-published`, and `R-conflict-reviewer` are policy labels, not executable predicates. For each table, security review must specify the exact joins and effective-time rules, including project/session/location/assignment association. In particular:

- `units` is globally canonical but must not be globally enumerable; project visibility flows through `unit_project_associations` and operational scope.
- `unit_identity_conflicts` must reveal only minimum candidate metadata to authorized conflict reviewers; never disclose another project's inspection history.
- `instrument_version_publications` is a catalog publication history; global catalog permission is not operational project membership.
- `inspection_revisions`, `review_events`, `inspection_events`, `print_events`, and `audit_events` are append-only history surfaces; normal application roles must not update/delete.
- `evidence_assets` metadata access does not itself authorize Storage object access.
- `idempotency_records` is internal and has no direct browser read.
- `sync_batches` visibility is restricted to the caller's own device/batch and effective scope.

## 5. Command/data-surface coverage checks

| Command/data family | Current physical tables | Review result |
|---|---|---|
| Identity and role administration | app_users, roles, permissions, role_permissions, user_roles, user_scope_grants, account_decisions | Physical coverage exists; role-grant ceiling and grantor authority remain open |
| Project/session/assignment/capacity | projects, locations, sessions, teams, operational_assignments, assignment_members, project_capacity_settings | Physical coverage exists; exact lifecycle/temporal predicates and closure gate remain open |
| Target planning | target_plans, target_allocations | Physical coverage exists; planner authority and published immutability need command tests |
| Instrument governance | instruments, instrument_versions, checklist_sections, checklist_items, specification_fields, evidence_slot_definitions, instrument_version_publications | Physical coverage exists; T-17 permissions distinct; production source content approval remains open |
| Canonical unit and claims | units, unit_project_associations, unit_identity_conflicts, unit_claims | Physical coverage exists; T-16 relational technical review and institutional serial policy remain open |
| Inspection/review | inspections, inspection_revisions, checklist_responses, specification_responses, review_events, inspection_events | Physical coverage exists; exact state machine, author/reviewer SoD and revision write model remain open |
| Evidence and documents | evidence_assets, documents | Relational metadata coverage exists; Storage policy and evidence read/export authorization remain open |
| Print | `print_batches`, `print_events` | Durable batch ID and per-document attempt outcomes are specified under T-13; technical constraints/tests remain open |
| Attendance | attendance_records, attendance_documents | Physical coverage exists; verification authority/signatory policy remains open |
| Audit/idempotency/offline | audit_events, idempotency_records, sync_batches | Physical coverage exists; T-10 policy, idempotency retention and device/offline policy remain open |
| Notifications | `notification_policy_versions`, `notification_outbox`, `notifications`, `notification_deliveries`, `notification_delivery_attempts`, `notification_escalation_events` | NLA-001 design proposal; PO/security review, worker ACL, T-10 retention and provider dependencies remain open |

## 6. Required closure artifacts

Before implementation authorization, produce and review:

1. Independent technical review of the T-13 `print_batches` design and NLA-001's six notification lifecycle tables; confirm removal of the ambiguous `notification_events` placeholder from the ERD.
2. A per-table DB-role privilege matrix with exact GRANT/REVOKE statements, reviewed against T-18.
3. A per-command RPC catalogue with exact schema/signature, caller role, EXECUTE grant, actor derivation, authorization predicates, lock/idempotency/audit/error contract.
4. Executable RLS predicate specifications and positive/negative tests for every table, including nested relations and revoked memberships.
5. A Storage bucket/object policy matrix and signed URL issuance/revocation model.
6. An inventory of views, triggers, functions, sequences, materialized views and SECURITY DEFINER functions, including owner/search_path/grants.
7. A test evidence index linking every table/command to test fixtures, expected results, actual results and environment/version. No test is considered complete until actually executed and recorded.

## 7. Verification status

- Proposed physical schema inventory: **48**.
- Proposed RLS catalogue entries: **48**.
- Static documentation name parity: **48/48**.
- Former ERD-only entities: **0 unresolved by name**; `print_batches` retained, `notification_events` replaced by six lifecycle tables.
- Live database existence/RLS/grants inspected: **NO**.
- SQL migrations or policies created/executed: **NO**.
- Command function inventory/signatures complete: **NO**.
- Per-table verification cases: **48 planned** (TC-RLS-024-001..048); executable authorization tests: **NOT EXECUTED**.
- Scope freeze: **NOT READY**.
- Implementation authorization: **NOT GRANTED**.

## 8. Change control

Any change to physical tables, ERD entities, RLS classes, table privileges, command functions, Storage objects, views or elevated functions must update this reconciliation, Package L, Package M, ERD, Command Authorization Verification Matrix, QA catalogue and RTM/Package S as applicable. Keep logical model entities, approved physical schema, deployed schema and tested policy evidence as four distinct states.

## 9. Per-table verification case allocation

The QA catalogue now allocates one design-level test to each of the 48 proposed tables: TC-RLS-024-001..048. Each case checks the table's declared SELECT class, an unauthorized/wrong-scope read, and the T-18 prohibition on browser-facing direct INSERT/UPDATE/DELETE even when the catalogue labels a mutation CMD. Internal tables with SELECT NONE receive explicit no-client-access assertions. All 48 cases are planned only and require execution against staging Supabase after approved migrations/grants.

## NLA-001 / T-13 reconciliation addendum — 2026-11-24

- T-13 PO-approved batch printing requires persistent batch identity and per-document outcomes; `print_batches` is now part of the proposed physical schema and RLS catalogue.
- `print_events` now records each per-document attempt/outcome and optional `batch_id`; retry appends a new attempt and is failed-only.
- INS-015 notification persistence is specified in NLA-001 using six tables; `notification_events` is removed from ERD.
- Proposed inventory parity is 48/48. This is not live Supabase evidence. Exact constraints, grants, RLS predicate verification, worker identity and test execution remain open.
