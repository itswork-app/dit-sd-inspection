# Physical Database Schema and Integrity Specification

**Status:** Engineering specification draft — approval required before migrations  
**Version:** 0.4.4  
**Package:** L — Physical Data Model and Integrity  
**Date:** 2026-11-23


## Schema/RLS reconciliation reference

The proposed physical schema and RLS catalogues are reconciled at 48/48 table names: the original 41 plus `print_batches` and six explicit notification lifecycle tables. The ambiguous ERD-only `notification_events` placeholder is removed. This is a documentation design inventory only; it does not establish live schema existence, deployed RLS or grants.

## 1. Purpose and implementation boundary

This document converts the logical ERD into a physical PostgreSQL design contract for review. It is not a migration and does not authorize application coding.

Platform baseline:
- Supabase PostgreSQL is the only system of record.
- Supabase Auth owns authentication identities; application tables own approval, roles, permissions, and operational scope.
- All primary keys are UUID unless a stable human-readable code is explicitly needed.
- All instants are `timestamptz` stored in UTC.
- Exact quantities use integer or `numeric`, never floating point.
- Foreign keys and constraints enforce integrity even when commands are retried or clients are stale.
- Operational history is retained; submitted revisions, published instrument versions, review events, print events, and audit events are immutable to normal application roles.

## 2. Canonical physical design conventions

1. Use snake_case table and column names.
2. Use `uuid` primary keys with server-generated UUIDs.
3. Add `created_at`, `created_by` where meaningful, and `updated_at` only to mutable aggregates/configuration rows.
4. Use explicit lifecycle status columns constrained to documented values; avoid free-form status text.
5. Use composite foreign keys where they are needed to prove same-project/same-instrument/same-revision relationships.
6. Use `ON DELETE RESTRICT` for operational history and published configuration. Cascading deletion is not allowed for submitted inspections, evidence, review, documents, print, and audit records.
7. Use soft lifecycle transitions for users, roles, instruments, sessions, assignments, and units; do not hard-delete records referenced by history.
8. Store raw serial input and normalized serial key separately. Never overwrite the raw value.
9. Every state-changing command runs through an approved trusted command boundary and transaction.
10. RLS is an additional access boundary, not a replacement for constraints or command authorization.

## 3. Core table catalogue

### 3.1 Identity and authorization

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `app_users` | `id`, `auth_user_id`, `display_name`, `approval_status`, `account_status` | Unique `auth_user_id`; one application profile per Auth identity; constrained status; no operational access unless approved and active |
| `roles` | `id`, `code`, `name`, `is_system`, `status` | Unique normalized role code; system roles cannot be deleted |
| `permissions` | `id`, `code`, `description` | Unique permission code; immutable code after use |
| `role_permissions` | `role_id`, `permission_id` | Composite primary key |
| `user_roles` | `user_id`, `role_id`, `valid_from`, `valid_until`, `status`, `granted_by`, `reason` | FK; valid interval; indexes by user/status and role/status; grant/revoke audited |
| `user_scope_grants` | `user_id`, `scope_type`, `scope_id`, `permission_id` or role reference, effective interval | Constrained scope type; no implicit location inheritance; scope target integrity validated by trusted command |
| `account_decisions` | `user_id`, `decision`, `actor_id`, `reason`, `decided_at` | Append-only; actor cannot approve own account |

Auth mapping: `app_users.auth_user_id` references `auth.users(id)`. Do not store passwords, provider tokens, or secrets in application tables.

### 3.2 Project and operational planning

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `projects` | `id`, `code`, `name`, `status`, `timezone` | Unique project code; valid IANA timezone |
| `locations` | `id`, `project_id`, `code`, `name`, `status` | Unique `(project_id, code)`; project FK |
| `sessions` | `id`, `project_id`, `code`, `status`, `starts_at`, `ends_at` | Unique `(project_id, code)`; valid interval; explicit state transition command |
| `teams` | `id`, `project_id`, `code`, `name`, `status` | Unique `(project_id, code)` |
| `operational_assignments` | `id`, `project_id`, `session_id`, `location_id`, `instrument_id`, `instrument_version_id`, `team_id`, `starts_at`, `ends_at`, `status` | Composite FKs or command validation prove every referenced row belongs to same project; exactly one location/instrument/team; interval valid; selected instrument version is published |
| `assignment_members` | `id`, `assignment_id`, `user_id`, `operational_role`, `valid_from`, `valid_until`, `status` | FK; valid interval; unique active membership for same assignment/user/role; indexes by user and assignment |
| `project_capacity_settings` | `project_id`, `inspector_cap`, `updated_at`, `updated_by` | One row per project; CHECK integer 1..100; default 50; all cap-affecting commands lock this row |
| `target_plans` | `id`, `project_id`, `version`, `status` | Unique `(project_id, version)`; published plans immutable |
| `target_allocations` | `id`, `target_plan_id`, `assignment_id`, `target_date`, `quantity` | Nonnegative integer quantity; unique allocation key as defined by target dimension; never rewrites actual activity |

**Superseded by T-14 PO APPROVED option A (2026-11-24).** Count distinct enabled login accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment in the governed project/session scope. Count each account once across roles and assignments; exclude pending, rejected, suspended, disabled and expired-role accounts. Enforce the combined cap atomically across both locations (1–100, default 50); reject a reduction below the current qualifying count rather than silently deactivating accounts. See the T-14 decision block below.

### 3.3 Extensible instrument catalogue and configuration

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `instruments` | `id`, `instrument_type`, `code`, `name`, `description`, `status`, `created_by` | `instrument_type` is a unique, immutable canonical type key; `code` is a unique catalog code; status ACTIVE/INACTIVE/ARCHIVED; Super Admin command controls lifecycle |
| `instrument_versions` | `id`, `instrument_id`, `version_number`, `status`, `schema_version`, `published_at`, `published_by` | Unique `(instrument_id, version_number)`; DRAFT/PUBLISHED/RETIRED; published rows immutable |
| `checklist_sections` | `id`, `instrument_version_id`, `code`, `label`, `sort_order` | Unique code/order within version; FK |
| `checklist_items` | `id`, `section_id`, `code`, `label`, `answer_type`, `sort_order`, `required`, `applicability_rule`, `validation_config` | Unique code/order within section; answer_type allowlist; declarative validation only |
| `specification_fields` | `id`, `instrument_version_id`, `code`, `label`, `value_type`, `expected_value`, `unit`, `required`, `sort_order` | Unique code/order per version; constrained value_type; typed values validated server-side |
| `evidence_slot_definitions` | `id`, `instrument_version_id`, `code`, `label`, `required`, `allowed_media_types`, `sort_order`, `applicability_rule` | Unique code/order per version; MIME allowlist; limits inherited from approved global evidence policy |
| `instrument_version_publications` | `instrument_version_id`, `published_by`, `published_at`, `change_summary` | Append-only publication record |

**Extensibility contract:** Super Admin can create a new instrument catalog entry and configure supported checklist sections/items, typed specification fields, evidence slots, ordering, mandatory status, applicability, and supported declarative validations. A new instrument using these primitives must not require application code changes. The system must reject unsupported field/validation types. Configuration must never execute arbitrary SQL, JavaScript, HTML, or uploaded code.

Every assignment/session binds to one published instrument version. Every inspection revision stores the exact version ID and a canonical configuration snapshot/hash. Later edits publish a new version and cannot alter active sessions or historical revisions.

### 3.4 Units, inspections, revisions, claims, and review

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `units` | `id`, `instrument_type`, `serial_raw`, `serial_normalized`, `normalization_version`, `status` | Canonical physical identity; no `project_id` or catalog-row identity in the uniqueness key; FK to `instruments.instrument_type`; unique `(instrument_type, serial_normalized)` for non-null serial; retain raw input and normalization version |
| `unit_project_associations` | `id`, `unit_id`, `project_id`, `status`, `associated_at`, `associated_by`, `association_reason`, `ended_at`, `ended_by`, `end_reason` | Status ACTIVE/ENDED/REVOKED; valid start/end interval; FK to canonical unit and project; partial unique ACTIVE `(unit_id, project_id)`; unique `(id, unit_id, project_id)` for composite references; no hard delete |
| `unit_identity_conflicts` | `id`, `instrument_type`, `serial_normalized`, `serial_raw_submitted`, `proposed_project_id`, `candidate_unit_id`, `reported_by`, `status`, `resolution`, `resolved_by`, `resolution_reason`, `created_at`, `resolved_at` | Durable controlled duplicate workflow keyed by canonical type + normalized serial; candidate FK; reasoned/audited resolution; never creates a second canonical unit by itself |
| `inspections` | `id`, `unit_id`, `unit_project_association_id`, `project_id`, `assignment_id`, `status`, `current_revision_no`, `row_version` | Composite FK proves association matches unit+project and assignment belongs to same project; command proves instrument match and active association; one active inspection lifecycle per canonical unit subject to authorized reopen/reinspection rules |
| `inspection_revisions` | `id`, `inspection_id`, `revision_no`, `instrument_version_id`, `snapshot_hash`, `author_id`, `submitted_at`, `payload_snapshot` | Unique `(inspection_id, revision_no)`; immutable after submission; instrument version must match assignment snapshot |
| `checklist_responses` | `id`, `inspection_revision_id`, `checklist_item_id`, `answer`, `note`, `answered_by`, `answered_at` | Unique `(inspection_revision_id, checklist_item_id)`; item belongs to revision's instrument version; answer conforms to item schema |
| `specification_responses` | `id`, `inspection_revision_id`, `specification_field_id`, `observed_value`, `note` | Unique per revision/field; field belongs to exact version |
| `unit_claims` | `id`, `unit_id`, `unit_project_association_id`, `project_id`, `assignment_id`, `inspector_id`, `status`, `claimed_at`, `expires_at`, `released_at`, `row_version` | Composite FKs prove association and assignment share project+unit; partial unique index on canonical `unit_id` for ACTIVE claim across projects; valid expiry; unit-row lock for acquisition/expiry takeover |
| `review_events` | `id`, `inspection_revision_id`, `reviewer_id`, `decision`, `reason`, `created_at` | Append-only; decision constrained; author != reviewer for approve; one terminal decision per revision unless explicit workflow permits |
| `inspection_events` | `id`, `inspection_id`, `event_type`, `actor_id`, `from_state`, `to_state`, `reason`, `created_at` | Append-only; state update and event insert in same transaction |

#### Serial normalization rule

- Preserve the exact submitted string in `serial_raw`.
- Apply Unicode NFC normalization, trim leading/trailing whitespace, and normalize repeated internal whitespace to a single ASCII space.
- Apply case folding only if the instrument's published serial policy declares case-insensitive identifiers.
- Preserve punctuation and leading zeroes; do not strip hyphens, slashes, or zeros by default.
- Store the policy/version used in `normalization_version`.
- Empty/unknown serials do not receive a shared normalized key; they require a separate authorized identification workflow.
- If an official instrument-specific rule differs, it must be configured/versioned and tested before use.

PO-approved T-16 option B: one normalized serial per canonical `instrument_type` across all projects. Enforce unique `(instrument_type, serial_normalized)` for non-null serials; project ID and catalog-row `instrument_id` are not part of the key. `instruments.instrument_type` is the stable, unique, immutable type identifier referenced by `units` and `unit_identity_conflicts`. Assignment/catalog configuration continues to use `instrument_id`; trusted commands verify that the assignment's catalog row resolves to the same `instrument_type` as the canonical unit. `units` therefore has no `project_id`. `unit_project_associations` records durable project membership episodes; inspections and claims reference the exact association and same-project assignment through composite foreign keys. An association may be ended without rewriting historical inspections. A same-type cross-project collision opens a controlled conflict record; only an authorized, reasoned and audited resolution may associate the candidate canonical unit with the project. Never create a second same-type canonical unit, silently merge records or rewrite historical inspection rows. Reinspection follows the authorized lifecycle and preserves revision/evidence history. This is a design invariant, not an executed migration.

#### Active claim and assignment overlap

- Enforce one ACTIVE claim per unit with a partial unique index.
- Claim acquisition and expiry takeover must run in one transaction, locking the unit or deterministic claim key.
- Never use client time to determine claim expiry; compare against database server time.
- Preserve drafts/evidence when claims expire; reassignment changes claim ownership, not draft history.
- Assignment overlap cannot be enforced with a simple row CHECK because it spans membership, assignment, and location rows. A trusted transaction must lock the user's active assignment set, compare effective time ranges and locations, and reject conflicting cross-location overlap. A database exclusion constraint may be added only if the final relational representation supports it without false positives.

### 3.5 Evidence, documents, print, attendance, audit, and idempotency

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `evidence_assets` | `id`, `inspection_id`, `inspection_revision_id`, `slot_definition_id`, `object_key`, `sha256`, `byte_size`, `mime_type`, `upload_status`, `uploaded_by` | Unique object key; checksum format; nonnegative size; slot belongs to exact instrument version; immutable finalized object identity |
| `documents` | `id`, `project_id`, `inspection_revision_id`, `document_type`, `template_version`, `source_hash`, `output_hash`, `object_key`, `status` | Unique generation key per source revision/template/type where appropriate; immutable generated artifact |
| `print_batches` | `id`, `actor_id`, `project_id`, `session_id`, `location_id`, `requested_count`, `status`, `request_hash`, `retry_of_batch_id`, `created_at`, `completed_at` | Positive bounded count; unique actor/idempotency scope; batch status reconciled from per-document outcomes; no claim of physical printer confirmation |
| `print_events` | `id`, `batch_id`, `document_id`, `actor_id`, `sequence_no`, `attempt_no`, `outcome`, `failure_code`, `client_print_signal`, `idempotency_key`, `created_at` | Unique `(document_id, sequence_no)`; append-only; batch reference nullable for individual print; outcome required; failed-only retry appends new attempt; signal does not claim physical printer confirmation |
| `attendance_records` | `id`, `project_id`, `session_id`, `status` | One logical attendance record per defined session/scope |
| `attendance_documents` | `id`, `attendance_record_id`, `object_key`, `sha256`, `uploaded_by`, `status` | Append-only replacement versions; replacement reason required |
| `audit_events` | `id`, `actor_id`, `action`, `target_type`, `target_id`, `scope`, `correlation_id`, `created_at`, `metadata` | Append-only at DB privilege level; indexes by actor/time, target/time, correlation ID |
| `idempotency_records` | `id`, `actor_id`, `command_type`, `scope_key`, `idempotency_key`, `request_hash`, `result_reference`, `status`, `expires_at` | Unique `(actor_id, command_type, scope_key, idempotency_key)`; same key/different hash rejected; retention > maximum offline retry window |
| `sync_batches` | `id`, `actor_id`, `device_id`, `batch_key`, `payload_hash`, `status`, `acknowledged_at` | Unique actor/device/batch key; replay safe; conflict records retained |
| `notification_policy_versions` | `id`, `policy_key`, `version_no`, `scope_type`, `scope_id`, `schema_version`, `policy_document`, `policy_hash`, `status`, `effective_from`, `effective_until`, `created_by`, `published_by`, timestamps | Unique policy/scope/version; strict versioned allowlist validation; published immutable; one effective version per scope/time; DRAFT reserved for a separately approved workflow and not written by CMD-051 |
| `notification_outbox` | `id`, `source_event_id`, `event_type`, `scope_type`, `scope_id`, `policy_version_id`, `safe_payload`, `status`, `attempt_count`, `next_attempt_at`, `lease_owner`, `lease_token_hash`, `lease_generation`, `lease_expires_at`, `last_error_code`, `created_at`, `processed_at` | Unique source-event/policy; server-issued token hash + monotonic fencing generation; short `SKIP LOCKED` claim; bounded retry/dead-letter; no provider I/O in transaction |
| `notifications` | `id`, `outbox_id`, `recipient_user_id`, project/session/location/assignment scope, `event_type`, `priority`, `title_key`, `body_key`, `safe_payload`, `created_at`, `expires_at`, `read_at`, `dismissed_at` (reserved) | Unique `(outbox_id, recipient_user_id)`; self-only read; set-once `read_at` with no row-version token; dismissal excluded from MVP by POQ-03; dismissed_at dormant with no command or browser mutation; safe minimal payload; source resource re-authorized on navigation |
| `notification_deliveries` | `id`, `notification_id`, `channel`, `status`, `attempt_count`, `next_attempt_at`, `last_attempt_at`, `sent_at`, `delivered_at`, `lease_owner`, `lease_token_hash`, `lease_generation`, `lease_expires_at`, `provider_message_ref`, `last_error_code`, timestamps | Unique `(notification_id, channel)`; delivery state independent of inbox read state; lease fencing on every finalizer; provider callback transitions validated/idempotent |
| `notification_delivery_attempts` | `id`, `delivery_id`, `attempt_no`, `idempotency_key`, `started_at`, `finished_at`, `outcome`, `provider_message_ref`, `safe_error_code`, `retryable`, `worker_correlation_id` | Unique delivery/attempt and idempotency key; append-only; sanitized provider metadata only |
| `notification_escalation_events` | `id`, `notification_id`, `policy_version_id`, `step_no`, `event_type`, `due_at`, `evaluated_at`, `recipient_resolution_ref`, `outbox_id`, `outcome`, `reason_code` | Unique notification/policy/step/event; append-only; no business-state mutation |

T-15 / INS-016 audit event scope and append-only/atomicity direction are PO-approved. Institutional classification, retention, legal hold, disposition, network metadata and final audit-reader/export authority remain subject to external approval under T-10. The table design above is a proposed implementation structure, not an implemented schema.

## 4. Critical indexes and database constraints

Required before production migration:
1. Unique `app_users(auth_user_id)`.
2. Unique project-scoped codes for locations, sessions, teams.
3. Unique `instruments(code)`.
4. Unique `instrument_versions(instrument_id, version_number)`.
5. Partial unique `units(instrument_type, serial_normalized)` for non-null serial keys; project ID and catalog-row ID are excluded.
6. Partial unique `unit_project_associations(unit_id, project_id)` where status = ACTIVE; retain ended association episodes.
7. Unique `unit_project_associations(id, unit_id, project_id)` to support composite inspection/claim FKs.
8. Partial unique `unit_claims(unit_id)` where status = ACTIVE, enforcing one physical-unit claim across projects.
9. Unique `inspection_revisions(inspection_id, revision_no)`.
10. Unique `checklist_responses(inspection_revision_id, checklist_item_id)`.
11. Unique `specification_responses(inspection_revision_id, specification_field_id)`.
12. Unique `print_events(document_id, sequence_no)`.
13. Unique idempotency scope key.
14. Index all foreign keys used for RLS scope predicates, review queues, project/session dashboards, and evidence lookup.
15. CHECK constraints for positive revision numbers, valid intervals, enumerated statuses, capacity 1..100, and nonnegative quantities/sizes.
16. Composite FKs or trusted transaction assertions for project/instrument/version/revision/association consistency.

## 5. Transactional invariants

| Command | Lock / atomicity requirement | Invariant |
|---|---|---|
| Approve account / grant Inspector role | Lock project capacity row before counting and granting | T-14 PO-approved qualifying-account predicate is applied atomically; global combined cap cannot be exceeded |
| Change capacity | Lock capacity row | New integer 1..100; reject below current count; never silently deactivate |
| Publish instrument version | Lock instrument catalog row | Version number unique; immutable published version |
| Bind assignment to instrument | Validate published version | Assignment cannot bind draft/retired version |
| Register/associate/resolve unit | Lock canonical serial key and unit row | One canonical unit per instrument+normalized serial; association/conflict outcome audited |
| Claim unit | Lock canonical unit row, then association and assignment | At most one active claim for a physical unit across projects; association and assignment must share project |
| Save draft | Compare row_version | Stale writes rejected; no silent overwrite |
| Submit inspection | Lock inspection aggregate | Validation + revision insert + state transition + event + idempotency result atomic |
| Review | Lock inspection aggregate | Correct state/version; no self-review; event and transition atomic |
| Generate PDF | Stable source snapshot/hash | PDF represents exact approved revision and template version |
| Record print | Lock document sequence | Monotonic unique print sequence; append-only event |
| Sync batch | Unique batch/idempotency key | Replays do not duplicate effects |

Do not hold database locks while transferring media or rendering PDF. Upload and render outside the critical transaction, then confirm/finalize with a short transaction.

## 6. Immutable and mutable boundaries

Mutable until publication/approval:
- draft instrument versions;
- project planning drafts;
- unsubmitted inspection draft;
- pending evidence metadata before finalization.

Immutable after transition:
- published instrument versions;
- submitted inspection revisions and their answer snapshots;
- finalized evidence object identity and checksum;
- reviewer decisions;
- generated document outputs;
- print events;
- audit events under PO-approved T-15 append-only controls; retention disposition remains governed by institutional T-10 policy.

Corrections create a new version or append-only event. Do not update historical rows to make them appear current.

## 7. Unresolved Product Owner / institutional decisions

These are not silently resolved by engineering:
1. Complete technical review of the T-16 canonical unit + `unit_project_associations` + conflict workflow, composite FK implementation and project-scoped RLS; obtain institution-approved serial-normalization and exception policy before migration.
2. Implement and verify the T-14 PO-approved qualifying Inspector predicate and atomic combined-cap enforcement; the PO decision itself is closed.
3. Implement T-15-approved audit append/atomicity and least-privilege access; obtain institutional approval for retention, legal hold, disposition, network metadata and final audit-reader/export authority.
4. Approve privacy classification, evidence retention/deletion, and institutional legal basis.
5. Confirm official instrument source and version content before publishing production instrument versions.
6. Approve exact session and assignment effective-time semantics.
7. Confirm reinspection rules after APPROVED and after project closure.

## 8. Migration and verification gates

No migration may be written until:
- the Product Owner resolves the items in Section 7 that affect constraints;
- T-18 command architecture is PO APPROVED; complete the table-by-table RLS/grant catalogue, command-specific EXECUTE grants, direct-DML denial matrix and any SECURITY DEFINER function review;
- evidence retention and object recovery contracts are approved;
- all enum/status transitions are reconciled with functional workflow docs.

Before production:
- apply migrations to disposable Supabase project;
- test all constraints and concurrent races;
- verify RLS positive/negative access matrix for every table;
- verify no application role can mutate immutable rows;
- test backup and object restore;
- run representative load and upload tests;
- capture migration checksums and rollback/recovery evidence.

## 9. Package L disposition

**Physical data model:** DRAFT COMPLETE FOR REVIEW.  
**Resolved by this package:** schema catalogue, integrity boundaries, instrument extensibility primitives, canonical serial identity and project-association design, active-claim uniqueness, revision/evidence linkage, critical index/transaction requirements.  
**Still blocked:** Product Owner confirmation items in Section 7; detailed table-by-table RLS/grant catalogue and command-specific function review (T-18 architecture approved); evidence/privacy policy; backup/restore plan.  
**Implementation authorization:** NOT GRANTED.  
**Migrations/tests executed:** NONE.



## T-14 — Canonical Inspector capacity predicate (PO-approved 2026-11-24)

The capacity count is the number of **distinct user accounts** satisfying all three conditions at the enforcement transaction's serialization point: (1) login account is enabled; (2) an active Inspector role grant exists; and (3) at least one currently effective operational Inspector assignment exists within the governed project/session scope. Count each account once across assignments and roles. Exclude pending, rejected, suspended, disabled and expired-role accounts. The count and cap check must be enforced atomically across both locations. Preserve the approved cap range 1–100, default 50; reject 0 and values above 100. Reject a proposed cap reduction below the current qualifying count until the count is reconciled; do not deactivate accounts implicitly. This section specifies the predicate; it is not an executed migration or implementation.


## Account registration and Super Admin-controlled staffing invariant (PO clarification, 2026-11-24)

The account lifecycle must precede staffing: a registered/authenticated identity is provisioned as pending; only Super Admin approval/activation may grant role(s), permissions, scope, team membership and operational assignment. Registration alone confers no operational access and is not counted as an Inspector. Super Admin owns team creation/count and team-member assignment. Enforce foreign keys to an existing approved application account for every role grant/team membership/operational assignment; reject self-assignment and assignments to pending, rejected, suspended or disabled accounts. Capacity counting follows T-14's canonical distinct-account predicate and must be evaluated atomically with changes that affect eligibility.


## T-16 — Approved serial and evidence integrity invariant (2026-11-24)

The canonical serial uniqueness key is `(instrument_type, serial_normalized)` across all projects; project ID and catalog-row ID are deliberately excluded. `instrument_type` is a stable immutable key on the instrument catalogue and is referenced by canonical units. Different instrument types may reuse the same serial string. Null/unknown serial handling remains a separate authorized identification workflow and must not be represented by a shared empty key. A duplicate within the same instrument type is not silently merged: block creation of a second canonical unit and route the conflict to authorized resolution with reason and append-only audit. The project association model must permit project-scoped inspection history to reference the canonical unit identity while preserving project/session scope.

Every evidence record must reference the exact immutable inspection revision and instrument version and a valid slot/item in that version. Preserve original metadata, checksum, uploader, capture time, upload time and immutable storage object identity. Finalized evidence objects are never overwritten in place. Replacement creates a new evidence record/object identity and audit event; historical revision/evidence links remain intact. Database constraints, transaction locking, RLS/command authorization and tests must enforce these rules together. No migration or runtime implementation is claimed.


## T-17 — Publication authority and lifecycle invariants (PO APPROVED A)

- `instrument_versions` may transition DRAFT → PUBLISHED only through the trusted `publish-instrument-version` command. The command derives `published_by` from the authenticated caller, requires explicit `instrument.publish` held by an authorized Super Admin, validates every field type/validation primitive and cross-reference against server allowlists, and rejects arbitrary executable content.
- The publication row and corresponding append-only audit event are committed atomically. Audit failure rolls back publication. A published version and its child configuration are immutable; corrections require a new version.
- Deactivation is a separate privileged, reasoned and audited lifecycle action. It prevents future selection but does not delete, rewrite, or invalidate historical version references.
- Each operational assignment/session references one published version. New publication does not automatically alter existing assignments or historical inspection revisions. Rebinding/migration of an existing assignment is not implied by T-17 and requires a separately specified, authorized workflow.
- `published_by`, publication time, version number, schema version, change summary and configuration snapshot/hash must be retained. Database-level constraints/triggers and command authorization must prevent direct browser mutation and post-publication edits.

**T-16 dependency status (updated 2026-11-24):** canonical unit/project association, composite FK and global claim semantics are now specified in the reconciliation block below. The Product Owner's uniqueness decision is approved; the relational design still requires technical review and institution-approved serial normalization/exception policy before migration. No migration or test execution is claimed.


## T-18 database privilege alignment (PO APPROVED option A, 2026-11-24)

The selected command architecture requires the database privilege model to deny browser-facing anon/authenticated roles direct INSERT/UPDATE/DELETE on protected business and governance tables. Expose only narrowly scoped command functions with explicit EXECUTE grants; keep ordinary reads under RLS. Derive actor from the caller JWT at the PostgreSQL boundary and validate permission, role, project association, session, assignment, state and separation-of-duties within the command transaction. Protected writes use the PO-approved narrow SECURITY DEFINER command-wrapper model, subject to individual function review, dedicated least-privileged NOLOGIN ownership, fixed empty search_path, schema-qualified references, strict validation, exact-signature EXECUTE grants, PUBLIC/anon denial and effective-privilege/RLS analysis. SECURITY INVOKER remains preferred for scoped reads and non-elevated helpers. The architecture decision is approved, but exact grants/policies and executable verification remain pending. No migration or test execution is claimed.


## T-16 — Reconciled canonical unit / project association contract

The canonical `units` table is project-independent. Its candidate key is `(instrument_type, serial_normalized)` for known serials. The stable `instrument_type` FK is resolved from the instrument catalogue; assignment `instrument_id` remains a configuration reference and must resolve to the same type in the trusted command. Project-specific visibility and work are represented only by `unit_project_associations`; no RLS policy or command may infer association from `unit_id` alone. Each association episode is durable and auditable. The model allows one unit to be associated with multiple projects, but the partial unique active claim index on `unit_id` prevents concurrent claims of that physical item across any projects.

`inspections` and `unit_claims` carry `unit_id`, `unit_project_association_id`, and `project_id`; composite foreign keys prove the association belongs to that unit and project and the assignment belongs to that same project. A trusted command additionally proves assignment instrument equals the unit instrument and the association is ACTIVE at claim/start. Historical inspection rows retain their association ID when an association ends. The physical unit record is never cloned to create a project-local copy.

`unit_identity_conflicts` captures same-instrument normalized-serial collisions. Conflict resolution either creates an association to the verified existing canonical unit or closes/rejects the report with reason; it cannot create a second canonical unit or silently merge/retarget historical records. No institution-specific duplicate exception is permitted until the external exception policy is approved.

**Constraint correction:** the previous project-scoped unique index `units(project_id, instrument_id, serial_normalized)` and the subsequent `(instrument_id, serial_normalized)` candidate key are withdrawn. Both contradicted the controlling PO key `(instrument_type, serial_normalized)`. The canonical key is now explicit and independent of project and instrument-catalog row identity; association constraints remain as specified above. The schema remains design-only; no migration has been created or executed.

## PostgreSQL function privilege compatibility gate

See [T-18 Execution Model Security Review](T18-EXECUTION-MODEL-SECURITY-REVIEW.md) and [PostgreSQL Function Security & EXECUTE Grant Design](POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md). T-18 Option A resolves the architecture-level conflict by selecting narrow SECURITY DEFINER wrappers for protected writes and SECURITY INVOKER for scoped reads where feasible. This is not blanket approval: each function's owner, memberships, effective privileges, RLS interaction, search_path, signature, caller-JWT path and exact EXECUTE ACL must be reviewed and verified before exposure. No broad table DML is permitted as a shortcut; no live ACL or runtime path has been verified.

## Notification and print persistence design addendum — NLA-001 / T-13

The six notification tables above are proposed by [Notification Lifecycle and Delivery Architecture](NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) v0.1.4. `notification_events` is not a physical entity and must not be added. Source mutation + domain event + audit + outbox intent are atomic; fan-out and provider delivery are asynchronous. Delivery attempts and escalation history are append-only. Read state is stored only on recipient-owned `notifications` rows. CMD-050 has no row-version field; CMD-052/053 use separate lease fencing fields, not a business row-version token. INT-NOTIF-001 is a provider callback ingress and adds no table to the current 48-table proposal.

T-13 requires durable batch identity and per-document outcomes. `print_batches` stores batch lifecycle and request identity; `print_events` stores every per-document attempt/outcome and optional batch reference. Batch status/counts are reconciled from latest per-document outcomes. Retry is failed-only and appends attempts; it never overwrites prior outcomes or claims physical printer success.

All constraints, exact composite FKs, partial indexes, enum/check definitions and transaction/locking details remain subject to technical review before any migration. T-10 retention/disposition remains institutionally blocked.


## CMD-011–020 Product Owner semantics — physicalization boundary (2026-11-24)

The Product Owner has approved the product-semantic invariants in the Decision Register for CMD-011–020. This physical specification must conform to those invariants, but this approval is not a physical schema approval and does not authorize migrations.

| Approved semantic invariant | Physical implication to reconcile | Current boundary |
|---|---|---|
| Session initial state is T-07 `DRAFT`; states remain DRAFT/ACTIVE/PAUSED/CLOSED | Session state CHECK/enum and command transition validation must use the canonical state vocabulary; no `PLANNED` or `CLOSE_REQUESTED` persisted state | Exact DDL/constraint and transition function remain unapproved |
| Session times are UTC instants interpreted from project IANA timezone; DST-invalid/ambiguous local inputs rejected | Define timestamp type/precision and preserve project timezone source; validate input before persistence | No new timezone column or conversion function is approved by this addendum |
| Session code immutable; metadata changes reasoned; dependent-work schedule changes rejected | Immutable identity rule, reason/audit payload, dependent-work predicate | Exact trigger/command enforcement and `sessions.row_version` remain open |
| CMD-014 roster creation atomic; half-open assignment intervals | Assignment/member constraints and transaction boundary | Parent fences, exclusion/unique constraints and lock order require Engineering/DB review |
| CMD-015 per-member effective_at; end history not delete; preserve submitted inspections | Membership history fields and FK/delete behavior must support end-dating and historical references | Exact column names, retention and active-claim behavior remain unresolved |
| T-14 capacity predicate unchanged | Same qualifying-account predicate and one serialization point across every eligibility-changing writer | Existing capacity row and version semantics require technical validation |
| CMD-017 session-scoped plans; unique allocation key; reject zero quantity; immutable published plans | Unique key on (target_plan_id, assignment_id, target_date), quantity CHECK, immutable publication boundary | Quantity units/range, project-wide exception and draft CAS remain open |
| CMD-018 normalized instrument code unique; draft/inactive until publication | Persist or deterministically compute normalized code; unique constraint and assignment-selectability rule | Permitted ASCII alphabet, collation and normalization implementation require Engineering/Security approval |
| CMD-019 complete declarative draft replacement; published snapshots immutable | Child reconciliation and immutable snapshot/hash representation | Schema allowlist, bounds, stable child keys, hash and CAS remain open |
| CMD-020 T-17 explicit publish permission and immutable version pinning | Publication row/event, immutable child snapshot and assignment/session version references | Existing T-17 design remains subject to exact function/ACL/constraint review |

**No inferred DDL:** This table records semantic obligations and missing physical decisions. It deliberately does not invent column names, data types, indexes, constraints, triggers, lock modes or migration order. G3/G5/G9 remain NOT READY; G10 NOT AUTHORIZED.


## NLA-001 physical field reconciliation — 2026-11-24

The notification physical proposal uses one canonical minimized payload field, safe_payload, for outbox and inbox records. The outbox and delivery queue projections carry the same logical lease tuple: lease_owner, lease_token_hash, monotonic lease_generation and lease_expires_at. The opaque lease token is returned only to the authenticated internal worker; raw tokens are never persisted or logged. Completion, failure, retry and dead-letter transitions validate the current owner, token hash, generation and expiry.

The notifications table intentionally has no row_version for CMD-050. Its read_at field is set once by a recipient-owned guarded update. dismissed_at remains dormant and is not exposed or mutated because POQ-03 excludes dismiss/archive from MVP. The provider callback ingress INT-NOTIF-001 uses the existing delivery projection and an approved durable deduplication mechanism; this addendum does not create a seventh notification table or claim live schema verification.

All columns, constraints, indexes, policies and functions remain proposed until Engineering/Database/Security review and separate G10 authorization.


## POQ-01..03 schema reconciliation — 2026-11-24

The Product Owner approved: (1) a durable event-time candidate-audience snapshot/checkpoint, with dispatch-time revalidation permitted only to suppress candidates and never to widen the audience; (2) versioned per-policy elapsed/business-time SLA semantics with ELAPSED_UTC as the initial-release default and quiet hours that defer delivery only; and (3) exclusion of dismiss/archive from MVP. The physical schema must still define and review the exact snapshot/checkpoint representation, policy mode fields and constraints. A dormant dismissed_at column is not an MVP capability. All remain proposed pending Engineering/Database/Security review and G10.


## Candidate-only physical object annex — CMD-035/036/038/039/040 (2026-11-24)

**Status:** DESIGN CANDIDATES ONLY — NOT PART OF THE CANONICAL 48-TABLE INVENTORY; NOT APPROVED FOR DDL OR IMPLEMENTATION.

The following candidate objects are introduced by DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001 v0.1.0 solely to make the schema gap explicit. They must not be treated as existing or approved physical tables.

| Candidate object | Owning command / worker | Purpose | Admission status |
|---|---|---|---|
| sync_batch_operations | CMD-035 | Durable per-operation manifest, semantic hash, expected version and terminal result | NOT ADMITTED; batch partial-commit/replay contract and FK/retention open |
| device_bindings (candidate family; final name TBD) | CMD-035 trusted device enrollment/revocation boundary | User/device binding, trust state and revocation; no private key storage | NOT ADMITTED; identity, attestation and recovery authority open |
| document_template_versions | Privileged template publication workflow; exact command ID/permission TBD | Immutable approved template version/hash and renderer compatibility | NOT ADMITTED; product approval and template governance open |
| document_generation_jobs | CMD-036 + internal renderer worker | Durable asynchronous generation intent, source/template identity and lease | NOT ADMITTED; source FK model and worker identity/ACL open |
| document_generation_attempts | Internal renderer worker | Append-only sanitized attempt outcomes and output provenance | NOT ADMITTED; attempt retention and worker ACL open |
| print_batch_items | CMD-038 | Immutable requested item manifest and stable item identity | NOT ADMITTED; request/result identity and FK design open |
| print_batch_item_results | CMD-038 | Durable per-item outcome and retry history | NOT ADMITTED; authoritative attempt identity vs print_events open |
| attendance_verification_events | CMD-040 | Append-only decision bound to exact attendance document version/checksum | NOT ADMITTED; institutional authority, SoD and retention open |

### CMD-044 audit-export candidate objects — NOT ADMITTED (2026-11-24)

**T-10 BLOCKED.** The following are future-review candidates only; they are not approved tables, not part of the canonical 48-table inventory, and must not be created while T-10 remains unresolved.

| Candidate object | Purpose | Minimum candidate integrity controls | Admission blockers |
|---|---|---|---|
| `audit_export_jobs` | Durable request/job state, actor, approved purpose/policy reference, normalized filter hash, request idempotency, snapshot watermark, status and worker lease fencing | Unique actor/idempotency key; same key/hash replays same job; same key/different hash rejected; legal state transitions; lease owner/token-hash/generation/expiry; no client-controlled actor/scope | T-10 authority/purpose, dual control, job lifecycle, worker identity and retention |
| `audit_export_manifests` | Immutable export manifest for exact ordered event selection, schema/policy version, scope/filter hash, snapshot/watermark, record count and canonical manifest hash | One immutable manifest per finalized job; canonical serialization version; ordered event identity/range or immutable manifest reference; checksum and count reconciliation | Event projection/classification, canonical hash format, snapshot semantics |
| `audit_export_artifacts` | Private object metadata: opaque storage reference, format, byte count, content checksum, encryption/key reference, generated timestamp and integrity state | Unique artifact identity; private bucket only; object-key not user-controlled; checksum verified after upload; no public URL; artifact metadata append/finalize path | Approved storage region/provider, encryption/key custody, download authorization, expiry, retention/legal hold and deletion proof |

Do not create a generic `export_requests` framework, polymorphic artifact table, or worker principal by assumption. Approval/download decision records, if dual control is required, need a separately approved model and must not be silently folded into the three candidates. A download permission is not inferred from `audit.export`; exact authority and permission vocabulary remain T-10 decisions.

The candidate object count above is not a revised table count. Package L's canonical inventory remains 48 proposed tables until Product, Engineering, Database, Security and institutional approvals admit a concrete model and the physical schema, RLS, permission registry, ERD, command contracts, indexes/FKs and QA catalogue are updated together.

Do not add a generic polymorphic source FK, generic worker table or generic device credential store without explicit review. Do not reuse notification_outbox for document generation. Do not claim candidate names exist in a deployed database. T-10 retention/legal hold remains externally blocked.


## POQ-01 candidate recipient snapshot relation — NOT ADMITTED (2026-11-24)

The six notification tables remain the current canonical proposal. POQ-01 requires a durable event-time candidate recipient and source-scope snapshot; the current six-table model does not explicitly persist that set. The following seventh notification relation is a candidate only and is excluded from the canonical 48-table inventory until Engineering, Database and Security approve it.

| Candidate relation | Candidate fields | Candidate integrity |
|---|---|---|
| `notification_outbox_recipients` | `outbox_id`, `recipient_user_id`, `project_id?`, `session_id?`, `location_id?`, `assignment_id?`, `scope_snapshot_hash`, `resolved_at` | Unique/PK `(outbox_id, recipient_user_id)`; FK to outbox and app user; composite FK or trusted assertion for scope hierarchy; immutable after audience snapshot finalization; canonical sorted snapshot hash/count reconciled to outbox header |

Candidate outbox-header fields (NOT ADMITTED additions): `audience_snapshot_version`, `audience_snapshot_hash`, `audience_snapshot_count`, and `audience_snapshot_completed_at`. These are required to reconcile candidate-row count and canonical digest before an outbox is claimable; exact types/checks and hash serialization remain open.

Candidate transaction requirements:
- Recipient identity and scope are resolved against source-event-time authorization state, not current membership at retry time.
- Candidate rows and the snapshot completion marker/hash/count are persisted in the same transaction as the source event and outbox intent, or through another formally approved immutable event-time snapshot mechanism that cannot widen the audience.
- CMD-052 reads candidate rows deterministically and idempotently materializes `notifications`; existing `(outbox_id, recipient_user_id)` uniqueness remains a second arbiter.
- External channel eligibility is revalidated at dispatch; it may suppress a candidate's channel delivery but may not add a recipient or rewrite the immutable snapshot.
- No browser SELECT/INSERT/UPDATE/DELETE, no authenticated user grant, no generic worker table and no service_role impersonation.

Numeric fan-out bound, transaction latency/lock budget, exact scope FKs, canonical hash format, outbox snapshot header fields, RLS/ACL, workload identity and recovery behavior remain OPEN. This candidate is NOT ADMITTED, creates no migration authority, and does not change the current 48-table parity count.
