# Physical Database Schema and Integrity Specification

**Status:** Engineering specification draft — approval required before migrations  
**Version:** 0.1.0  
**Package:** L — Physical Data Model and Integrity  
**Date:** 2026-11-23

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

**Inspector capacity counting predicate remains a Product Owner confirmation blocker.** The policy says distinct active Inspector accounts, not assignment rows. The implementation must choose whether the counted set is (a) approved + active accounts with an active Inspector role grant, or (b) those accounts additionally assigned to an active project. Do not ship either interpretation silently. Whichever is approved must be counted once globally for the project across both locations and enforced atomically during account/role/assignment activation and cap changes.

### 3.3 Extensible instrument catalogue and configuration

| Table | Key columns | Required constraints / indexes |
|---|---|---|
| `instruments` | `id`, `code`, `name`, `description`, `status`, `created_by` | Unique immutable code; status ACTIVE/INACTIVE/ARCHIVED; Super Admin command controls lifecycle |
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
| `units` | `id`, `project_id`, `instrument_id`, `serial_raw`, `serial_normalized`, `normalization_version`, `status` | Unique `(instrument_id, serial_normalized)` when serial is present, enforced across all projects; retain raw input; normalization version required |
| `inspections` | `id`, `unit_id`, `assignment_id`, `status`, `current_revision_no`, `row_version` | Unit/assignment project+instrument consistency; one active inspection lifecycle per unit subject to authorized reopen/reinspection rules |
| `inspection_revisions` | `id`, `inspection_id`, `revision_no`, `instrument_version_id`, `snapshot_hash`, `author_id`, `submitted_at`, `payload_snapshot` | Unique `(inspection_id, revision_no)`; immutable after submission; instrument version must match assignment snapshot |
| `checklist_responses` | `id`, `inspection_revision_id`, `checklist_item_id`, `answer`, `note`, `answered_by`, `answered_at` | Unique `(inspection_revision_id, checklist_item_id)`; item belongs to revision's instrument version; answer conforms to item schema |
| `specification_responses` | `id`, `inspection_revision_id`, `specification_field_id`, `observed_value`, `note` | Unique per revision/field; field belongs to exact version |
| `unit_claims` | `id`, `unit_id`, `assignment_id`, `inspector_id`, `status`, `claimed_at`, `expires_at`, `released_at`, `row_version` | Partial unique index on `unit_id` for ACTIVE claim; valid expiry; transaction lock for acquisition/expiry takeover |
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

PO-approved T-16 option B: one normalized serial per instrument type across all projects. Enforce the unique key `(instrument_id, serial_normalized)` for non-null normalized serials; project ID must not be part of this uniqueness key. The data model must support an existing physical unit being referenced by project-scoped inspection activity without creating a second same-type unit identity. A same-type cross-project collision must enter controlled review with reason and audit; never silently merge or discard history. Reinspection must link to the canonical unit identity and follow an authorized new inspection/reopen path. This is a design invariant, not an executed migration.

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
| `print_events` | `id`, `document_id`, `actor_id`, `sequence_no`, `client_print_signal`, `created_at` | Unique `(document_id, sequence_no)`; append-only; signal does not claim physical printer confirmation |
| `attendance_records` | `id`, `project_id`, `session_id`, `status` | One logical attendance record per defined session/scope |
| `attendance_documents` | `id`, `attendance_record_id`, `object_key`, `sha256`, `uploaded_by`, `status` | Append-only replacement versions; replacement reason required |
| `audit_events` | `id`, `actor_id`, `action`, `target_type`, `target_id`, `scope`, `correlation_id`, `created_at`, `metadata` | Append-only at DB privilege level; indexes by actor/time, target/time, correlation ID |
| `idempotency_records` | `id`, `actor_id`, `command_type`, `scope_key`, `idempotency_key`, `request_hash`, `result_reference`, `status`, `expires_at` | Unique `(actor_id, command_type, scope_key, idempotency_key)`; same key/different hash rejected; retention > maximum offline retry window |
| `sync_batches` | `id`, `actor_id`, `device_id`, `batch_key`, `payload_hash`, `status`, `acknowledged_at` | Unique actor/device/batch key; replay safe; conflict records retained |

The INS-016 audit control direction is PO-approved under T-15 option A. The table design above remains a proposed implementation structure; detailed technical approval and T-10 institutional classification, retention, deletion/disposition, legal-hold and network-metadata controls remain pending.

## 4. Critical indexes and database constraints

Required before production migration:
1. Unique `app_users(auth_user_id)`.
2. Unique project-scoped codes for locations, sessions, teams.
3. Unique `instruments(code)`.
4. Unique `instrument_versions(instrument_id, version_number)`.
5. Unique `units(project_id, instrument_id, serial_normalized)` for non-null serial keys.
6. Partial unique `unit_claims(unit_id)` where status = ACTIVE.
7. Unique `inspection_revisions(inspection_id, revision_no)`.
8. Unique `checklist_responses(inspection_revision_id, checklist_item_id)`.
9. Unique `specification_responses(inspection_revision_id, specification_field_id)`.
10. Unique `print_events(document_id, sequence_no)`.
11. Unique idempotency scope key.
12. Index all foreign keys used for RLS scope predicates, review queues, project/session dashboards, and evidence lookup.
13. CHECK constraints for positive revision numbers, valid intervals, enumerated statuses, capacity 1..100, and nonnegative quantities/sizes.
14. Composite FKs or trusted transaction assertions for project/instrument/version/revision consistency.

## 5. Transactional invariants

| Command | Lock / atomicity requirement | Invariant |
|---|---|---|
| Approve account / grant Inspector role | Lock project capacity row before counting and granting | Global cap cannot be exceeded; count predicate awaits PO confirmation |
| Change capacity | Lock capacity row | New integer 1..100; reject below current count; never silently deactivate |
| Publish instrument version | Lock instrument catalog row | Version number unique; immutable published version |
| Bind assignment to instrument | Validate published version | Assignment cannot bind draft/retired version |
| Claim unit | Lock unit/claim key | At most one active claim |
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
- audit events according to PO-approved INS-016/T-15, after detailed technical review; production retention and disposition remain subject to T-10 institutional approval.

Corrections create a new version or append-only event. Do not update historical rows to make them appear current.

## 7. Unresolved Product Owner / institutional decisions

These are not silently resolved by engineering:
1. Reconcile PO-approved T-16 option B (instrument type + normalized serial across all projects) into the final unit/project association model; confirm any institution-approved exception and instrument-specific normalization/case-sensitivity policy before migration.
2. Confirm exact Inspector capacity counting predicate (active Inspector role grant versus additionally assigned active project).
3. Complete technical review of INS-016 event scope/access/export and obtain T-10 institutional approval for classification, retention, deletion/disposition and legal hold.
4. Approve privacy classification, evidence retention/deletion, and institutional legal basis.
5. Confirm official instrument source and version content before publishing production instrument versions.
6. Approve exact session and assignment effective-time semantics.
7. Confirm reinspection rules after APPROVED and after project closure.

## 8. Migration and verification gates

No migration may be written until:
- the Product Owner resolves the items in Section 7 that affect constraints;
- table-by-table RLS catalogue and privileged command boundary are approved;
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
**Resolved by this package:** schema catalogue, integrity boundaries, instrument extensibility primitives, serial normalization proposal, active-claim uniqueness, revision/evidence linkage, critical index/transaction requirements.  
**Still blocked:** Product Owner confirmation items in Section 7; RLS catalogue; privileged command boundary; evidence/privacy policy; backup/restore plan.  
**Implementation authorization:** NOT GRANTED.  
**Migrations/tests executed:** NONE.



## T-14 — Canonical Inspector capacity predicate (PO-approved 2026-11-24)

The capacity count is the number of **distinct user accounts** satisfying all three conditions at the enforcement transaction's serialization point: (1) login account is enabled; (2) an active Inspector role grant exists; and (3) at least one currently effective operational Inspector assignment exists within the governed project/session scope. Count each account once across assignments and roles. Exclude pending, rejected, suspended, disabled and expired-role accounts. The count and cap check must be enforced atomically across both locations. Preserve the approved cap range 1–100, default 50; reject 0 and values above 100. Reject a proposed cap reduction below the current qualifying count until the count is reconciled; do not deactivate accounts implicitly. This section specifies the predicate; it is not an executed migration or implementation.


## Account registration and Super Admin-controlled staffing invariant (PO clarification, 2026-11-24)

The account lifecycle must precede staffing: a registered/authenticated identity is provisioned as pending; only Super Admin approval/activation may grant role(s), permissions, scope, team membership and operational assignment. Registration alone confers no operational access and is not counted as an Inspector. Super Admin owns team creation/count and team-member assignment. Enforce foreign keys to an existing approved application account for every role grant/team membership/operational assignment; reject self-assignment and assignments to pending, rejected, suspended or disabled accounts. Capacity counting follows T-14's canonical distinct-account predicate and must be evaluated atomically with changes that affect eligibility.


## T-16 — Approved serial and evidence integrity invariant (2026-11-24)

The canonical serial uniqueness key is `(instrument_id, serial_normalized)` across all projects; project ID is deliberately excluded. Different instrument types may reuse the same serial string. Null/unknown serial handling remains a separate authorized identification workflow and must not be represented by a shared empty key. A duplicate within the same instrument type is not silently merged: block creation of a second canonical unit and route the conflict to authorized resolution with reason and append-only audit. The project association model must permit project-scoped inspection history to reference the canonical unit identity while preserving project/session scope.

Every evidence record must reference the exact immutable inspection revision and instrument version and a valid slot/item in that version. Preserve original metadata, checksum, uploader, capture time, upload time and immutable storage object identity. Finalized evidence objects are never overwritten in place. Replacement creates a new evidence record/object identity and audit event; historical revision/evidence links remain intact. Database constraints, transaction locking, RLS/command authorization and tests must enforce these rules together. No migration or runtime implementation is claimed.
