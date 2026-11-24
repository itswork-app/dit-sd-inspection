# Command Physical Object Crosswalk — CMD-001–054

**Document ID:** CMD-PHYSICAL-CROSSWALK-001  
**Version:** 0.1.1  
**Date:** 2026-11-24  
**Status:** Source-derived physical read/write proposal — Engineering / Database / Security review required; NOT approved for implementation  
**Parent:** LOCK-NORMALIZATION-001 v0.1.0; LOCK-MANIFEST-001 v0.4.24  
**Gate:** G3/G4/G5/G7/G9 NOT READY; G10 NOT ACTIVE

## 1. Purpose and evidence boundary

This crosswalk extracts the command-specific physical read/write sets from the detailed contract reviews. It is intended to make table/object references, write effects and schema gaps reviewable beside the 50-command normalized lock register. Every object is a proposed reference from documentation, not proof of deployed existence, deployed policy, lock acquisition, or grant correctness.

Names marked candidate, missing, not specified, or not fully physicalized remain OPEN. Never create a table, column, index, trigger, function, permission or storage object solely because it appears as a proposal below. For each command, Engineering/Database must reconcile exact schema, keys, FKs, indexes, triggers, functions and hidden lock paths; Security must reconcile RLS, ownership and EXECUTE ACL.

CMD-045–048 are excluded external control-plane IDs. They have no application physical read/write set.

## 2. Command-specific physical object sets

### CMD-001

Source section: ### Physical read/write set

- Read: authenticated identity mapping in `app_users`; idempotency record.
- Write: `app_users` only if the canonical account-request lifecycle assigns profile/request fields there; `idempotency_records`; `audit_events`.
- **Model gap:** no dedicated account-request entity is listed. Confirm whether `app_users` is created at Auth signup or first request, and whether a separate request state/history table is required. Do not infer a table.

### CMD-002

Source section: ### Physical read/write set

- Read: target `app_users`; actor `app_users` and effective authorization grants; idempotency record.
- Write: target `app_users.approval_status` and decision metadata; append `account_decisions`; `idempotency_records`; `audit_events`.
- Preserve prior decisions; do not overwrite decision history.

### CMD-003

Source section: ### Physical read/write set

- Read: target `app_users`; actor authorization; idempotency record.
- Write: target `app_users.approval_status`; append `account_decisions`; `idempotency_records`; `audit_events`.
- Decision history is append-only.

### CMD-004

Source section: ### Physical read/write set

- Read: actor and target `app_users`; role catalog; current `user_roles`; effective grantor ceiling; `project_capacity_settings` when applicable; qualifying role/assignment membership rows for Inspector cap; idempotency record.
- Write: `user_roles`; `idempotency_records`; `audit_events`; `permission.changed` audit/domain event only if the approved role-to-permission bundle changes.
- The current physical table inventory does not show a separate role-grant event table; role history must be retained through append-only audit and/or a separately approved grant-history design.

### CMD-005

Source section: ### Physical read/write set

- Read: `user_roles` target; actor authorization; role catalog; `project_capacity_settings` and qualifying count if Inspector; idempotency record.
- Write: target `user_roles.status/valid_until` (exact canonical revocation representation to be chosen); `idempotency_records`; `audit_events`.
- Do not delete the original row.

### CMD-006

Source section: ### Physical read/write set

- Read: actor/target `app_users`; target scope table selected by `scope_type`; role/permission catalog; grantor's effective grants; existing `user_scope_grants`; idempotency record.
- Write: `user_scope_grants`; `idempotency_records`; `audit_events`.
- Scope target validation must use a fixed allowlist of table mappings, never dynamic SQL built from client `scope_type`.

### CMD-007

Source section: ### Physical read/write set

- Read: `user_scope_grants` target; actor effective grant; idempotency record; dependent assignment/session references only if approved revocation policy requires them.
- Write: `user_scope_grants` lifecycle fields; `idempotency_records`; `audit_events`.
- Physical schema does not currently state a `version` field; align expected_version with the eventual schema.

### CMD-008

Source section: ### Physical read/write set

- Read: actor `app_users` and effective global permission; idempotency record; unique code index.
- Write: `projects`; `idempotency_records`; `audit_events`.
- Physical schema must include server-generated ID, status default, created/updated metadata and a uniqueness rule on normalized code.

### CMD-009

Source section: ### Physical read/write set

- Read: `projects` target; actor authorization; idempotency record.
- Write: mutable project metadata and version/update metadata; `idempotency_records`; `audit_events`.
- **Schema gap:** current physical table summary lists `id, code, name, status, timezone` but does not explicitly list `version`, `updated_at` or `updated_by`. The request's `expected_version` cannot be implemented correctly until the physical specification defines the version mechanism.

### CMD-010

Source section: ### Physical read/write set

- Read: `projects`; sessions; assignments/members; inspections/revisions/review events; evidence lifecycle; documents; print batches/events; target/actual reconciliation; sync conflicts; legal holds if modeled; actor authorization; idempotency record.
- Write: `projects.status/closed_at/version`; `idempotency_records`; `audit_events`. No dependent record is changed by default.
- Exact dependency tables and predicates must be enumerated in the controlling ERD/schema before approval.

### CMD-011

Source section: ### Physical read/write set

- Read: \`projects\`; \`sessions\` for duplicate code and lifecycle checks; \`idempotency_records\`.
- Write: \`sessions\`; \`idempotency_records\`; \`audit_events\`.
- Physical schema documents \`sessions(id, project_id, code, status, starts_at, ends_at)\`, unique \`(project_id, code)\`, and valid interval.
- No session-level `row_version` is specified in the physical schema. The API token proposal is `expected_row_version`; physical approval remains open.

### CMD-012

Source section: ### Physical read/write set

- Read: \`sessions\`, parent \`projects\`, relevant \`operational_assignments\` and any session-bound work needed to validate impact; \`idempotency_records\`.
- Write: \`sessions\` and \`audit_events\`, plus \`idempotency_records\`.
- **Blocking schema gap:** \`sessions\` physical catalogue does not define \`version\`, \`row_version\`, or \`updated_at\`, while CMD-012 proposes \`expected_row_version\`. Physical row_version and increment rule remain unapproved. Do not implement optimistic concurrency until an explicit version column and increment rule are approved and added to the physical specification.

### CMD-013

Source section: ### Physical read/write set

- Read: \`sessions\`, \`projects\`; \`operational_assignments\`, \`assignment_members\` for Korlap scope; closure dependency records for a close transition; \`idempotency_records\`.
- Write: \`sessions\`; \`audit_events\`; \`idempotency_records\`.
- **Blocking schema gap:** \`sessions\` has no defined row version field, although CMD-013 proposes \`expected_row_version\`. Physical row_version and increment rule remain unapproved.
- **Lifecycle status:** T-07 state vocabulary and actor boundary are PO-approved; exact transition matrix, action-to-permission mapping, closure checklist evidence and institutional gates remain open.

### CMD-014

Source section: ### Physical read/write set

- Read: \`projects\`, \`sessions\`, \`locations\`, \`instruments\`, \`instrument_versions\`, \`teams\`, \`app_users\`, \`user_roles\`, existing \`operational_assignments\` and \`assignment_members\` for overlap, \`project_capacity_settings\`, \`idempotency_records\`.
- Write: \`operational_assignments\`, \`assignment_members\`, and if the physical model requires it, only the capacity row's audit/version metadata must not be modified as a side effect of assignment publication; plus \`idempotency_records\`, \`audit_events\`.
- No direct write to \`project_capacity_settings\` for this command.
- **Schema gaps:** no assignment row_version is defined; overlap semantics and exact membership effective-time uniqueness are not fully specified. Confirm whether assignment status starts as PUBLISHED or another state.

### CMD-015

Source section: ### Physical read/write set

- Read: \`operational_assignments\`, \`projects\`, \`sessions\`, \`assignment_members\`, \`app_users\`, \`user_roles\`, \`project_capacity_settings\`, active \`unit_claims\`/inspection dependencies when removing an Inspector; \`idempotency_records\`.
- Write: \`assignment_members\`; \`idempotency_records\`; \`audit_events\`.
- No role grant/revoke write; no direct change to assignment's project/session/instrument binding.
- **Schema gap:** \`assignment_members\` has no explicit row_version or updated_at. The catalogue does not require expected_version, but concurrency must be handled by row locks and uniqueness constraints.

### CMD-016

Source section: ### Physical read/write set

- Read: \`projects\`, \`project_capacity_settings\`, \`app_users\`, \`user_roles\`, \`operational_assignments\`, \`assignment_members\`, \`idempotency_records\`.
- Write: \`project_capacity_settings\`, \`idempotency_records\`, \`audit_events\`.
- **Blocking schema gap:** physical \`project_capacity_settings\` defines \`project_id, inspector_cap, updated_at, updated_by\`, but no \`version\`/row_version. CMD-016 proposes \`expected_row_version\`; the physical version column and increment rule must be approved and specified before optimistic concurrency is implemented.

### CMD-017

Source section: ### Physical read/write set

- Read: \`projects\`, \`sessions\` when session-scoped, \`operational_assignments\`, existing \`target_plans\` and \`target_allocations\`, \`idempotency_records\`.
- Write: \`target_plans\`, \`target_allocations\`, \`idempotency_records\`, \`audit_events\`.
- No writes to \`inspections\`, \`inspection_revisions\`, \`inspection_events\` or actual-report sources.
- **Schema gaps:** target plan has a business \`version\` but no separate row_version; target plan physical columns omit \`session_id\`; target allocation uniqueness key is not finalized. Do not assume business version alone provides concurrent draft-write protection.

### CMD-018

Source section: ### Physical read/write set

- Read: \`instruments\` for duplicate normalized code; \`idempotency_records\`.
- Write: \`instruments\`; \`idempotency_records\`; \`audit_events\`.
- Physical schema: \`instruments(id, code, name, description, status, created_by)\`, unique immutable code; status values ACTIVE/INACTIVE/ARCHIVED.
- No project, assignment, checklist or version rows are written by CMD-018.

### CMD-019

Source section: ### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, existing \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`.
- Write: \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`, \`audit_events\`.
- \`instrument_version_publications\` is not written by draft save.
- **Schema gap:** physical specification does not explicitly define a canonical configuration hash/content-hash column or row_version for DRAFT version concurrency. T-17 requires retained configuration snapshot/hash; define exact storage and canonicalization before implementation.

### CMD-020

Source section: ### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`idempotency_records\`.
- Write: \`instrument_versions\` (status, published_at, published_by and approved version metadata); append \`instrument_version_publications\`; append \`audit_events\`; \`idempotency_records\`.
- Child configuration tables are read for validation and must be protected from subsequent mutation; no child content update is part of publication.
- **Schema gap:** physical specification lists published_at/published_by but does not fully specify change_summary, immutable snapshot/hash storage, or a database-level immutability enforcement mechanism. T-17 requires all of these to be retained and enforced.

### CMD-021

Source section: ### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, \`operational_assignments\` (future/current selection impact), \`idempotency_records\`.
- Write: \`instruments\`, \`idempotency_records\`, \`audit_events\`.
- No write to \`instrument_versions\`, \`instrument_version_publications\`, assignment rows, inspections or historical records.
- Physical \`instruments\` columns are \`id, code, name, description, status, created_by\`; no version column is specified.

### CMD-022

Source section: ### Physical read/write set

- Read: \`instruments\`, \`units\`, \`operational_assignments\`, \`projects\`, \`idempotency_records\`; read existing \`unit_project_associations\` only when the approved collision/visibility policy requires it.
- Write: \`units\` for a genuinely new canonical identity; \`unit_identity_conflicts\` for a controlled collision workflow if the approved policy says registration creates a conflict; \`idempotency_records\`; \`audit_events\`.
- No write to \`unit_project_associations\`, \`unit_claims\` or \`inspections\`.
- Physical columns: \`units(id, instrument_type, serial_raw, serial_normalized, normalization_version, status)\`; known serial unique key is \`(instrument_type, serial_normalized)\` for non-null serials.

### CMD-023

Source section: ### Physical read/write set

- Read: \`units\`, \`projects\`, \`unit_project_associations\`, \`unit_identity_conflicts\`, and project-scoped instrument/assignment configuration as needed; \`idempotency_records\`.
- Write: \`unit_project_associations\`, \`idempotency_records\`, \`audit_events\`.
- No write to \`units\`, \`unit_claims\`, \`inspections\` or historical association rows.
- Physical association columns: \`id, unit_id, project_id, status, associated_at, associated_by, association_reason, ended_at, ended_by, end_reason\`; partial unique ACTIVE \`(unit_id, project_id)\`; unique \`(id, unit_id, project_id)\` supports composite references.

### CMD-024

Source section: ### Physical read/write set

- Read: \`unit_project_associations\`, \`units\`, \`unit_claims\`, \`inspections\`, \`operational_assignments\`, \`assignment_members\`, and related active workflow state; \`idempotency_records\`.
- Write: \`unit_project_associations\` (status, ended_at, ended_by, end_reason only); \`idempotency_records\`; \`audit_events\`.
- No writes to \`units\`, \`unit_claims\`, \`inspections\`, \`inspection_revisions\`, evidence or assignment/member rows.
- Physical association schema has no row_version/updated_at column despite the catalogue's expected_version field.

### CMD-025

Source section: ### Physical read/write set

- Read: \`unit_identity_conflicts\`, \`units\`, \`projects\`, \`unit_project_associations\`, reviewer identity/permission/scope state; \`idempotency_records\`.
- Write: \`unit_identity_conflicts\` (resolution, resolved_by, resolution_reason, resolved_at, status); \`unit_project_associations\` only for approved ASSOCIATE_EXISTING; \`idempotency_records\`; \`audit_events\`.
- No write to canonical \`units\`, historical associations, inspections, claims, revisions or evidence.
- Physical conflict columns include \`instrument_type, serial_normalized, serial_raw_submitted, proposed_project_id, candidate_unit_id, reported_by, status, resolution, resolved_by, resolution_reason, created_at, resolved_at\`.

### CMD-026

Source section: ### Physical read/write set

- Read: \`units\`, \`unit_project_associations\`, \`projects\`, \`operational_assignments\`, \`assignment_members\`, \`instruments\`, \`instrument_versions\`, \`unit_claims\`, \`inspections\`, \`idempotency_records\`.
- Write: \`unit_claims\`, \`inspections\`, \`inspection_events\` (if inspection.created is represented there), \`idempotency_records\`, \`audit_events\`.
- The command catalogue explicitly states claim and inspection creation; the physical schema requires an inspection lifecycle and claim references. Exact event-row creation and initial inspection revision creation need final mapping.
- No write to \`units\`, association, assignment membership, instrument configuration, checklist responses or evidence.
- Physical \`unit_claims\` contains \`row_version\`; \`inspections\` contains \`row_version\`. Both must have defined initial/increment rules.

### CMD-027

Source section: ### Physical read/write set

- Read: \`unit_claims\`, \`units\`, \`inspections\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`idempotency_records\`.
- Write: \`unit_claims\` (status, released_at, row_version); \`idempotency_records\`; \`audit_events\`.
- Write to \`inspection_events\` only if the approved state machine explicitly defines a corresponding inspection transition; otherwise no inspection write.
- No write to checklist/specification responses, inspection revisions, evidence assets, canonical unit or association.

### CMD-028

Source section: ### Physical read/write set

- Read: \`inspections\`, \`unit_claims\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, existing \`checklist_responses\`, \`specification_responses\`, \`idempotency_records\`.
- Write: \`inspections\` (row_version and any approved draft aggregate metadata); \`checklist_responses\`; \`specification_responses\`; \`idempotency_records\`; \`audit_events\`.
- \`inspection_revisions\` should not be mutated as a submitted immutable revision. Whether a DRAFT revision row exists and is mutable is unresolved.
- No write to \`inspection_events\` unless the audit/state model explicitly records draft save there; the audit catalogue defines \`inspection.draft_saved\` as a business event but physical mapping must be finalized.
- Physical response tables key rows by \`inspection_revision_id\`; the physical model does not fully specify how a mutable draft revision is represented separately from submitted immutable revisions.

### CMD-029

Source section: ### Physical read/write set

- Read: \`inspections\`, \`unit_claims\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`checklist_responses\`, \`specification_responses\`, \`evidence_assets\`, \`sync_batches\`, \`idempotency_records\`.
- Write: \`inspections\` (status, current_revision_no, row_version); append \`inspection_revisions\`; append \`inspection_events\`; \`idempotency_records\`; \`audit_events\`.
- No write to response content or evidence object identity as part of submission. If the physical design stores a frozen payload snapshot on \`inspection_revisions\`, snapshot creation must be atomic with status transition.
- Do not mutate published instrument configuration, assignment, association, canonical unit or historical revisions.

### CMD-030

Source section: ### Physical read/write set

- Read: \`inspections\`, \`inspection_revisions\`, \`review_events\`, reviewer permission/scope and reviewer assignment source (currently unresolved), \`idempotency_records\`.
- Write: append \`review_events\`; update \`inspections\` state/row_version; append \`inspection_events\`; \`idempotency_records\`; \`audit_events\`.
- No write to \`inspection_revisions\`, \`checklist_responses\`, \`specification_responses\`, \`evidence_assets\`, \`unit_claims\`, \`units\` or association.
- Physical \`review_events\` contains \`inspection_revision_id, reviewer_id, decision, reason, created_at\` and is append-only. \`inspection_events\` is also append-only.
- **Schema gap:** the physical review event table does not define an explicit reviewer-assignment ID, decision sequence, or review round identifier. The inspection state/row_version model must prevent multiple terminal decisions for the same revision unless an approved workflow says otherwise.

### CMD-031

Source section: ### 2.5 Physical read/write set

Proposed reads:
- inspections;
- inspection_revisions;
- review_events;
- assignment_members;
- operational_assignments;
- sessions, locations and projects as needed to prove the same scope;
- app_users, user_roles, user_scope_grants, permissions and role_permissions as needed by the authorization resolver;
- idempotency_records.

Proposed writes:
- inspections: status and row_version only;
- review_events: append one terminal APPROVE decision for the exact revision;
- inspection_events: append the APPROVED transition;
- audit_events: append inspection.approved;
- idempotency_records: persist the canonical result.

Do not update checklist_responses, specification_responses, inspection_revisions, evidence_assets or previously generated documents as part of approval.

### CMD-032

Source section: ### 3.5 Physical read/write set

Proposed reads:
- inspections;
- inspection_revisions;
- review_events and inspection_events;
- unit_claims;
- unit_project_associations;
- operational_assignments and assignment_members;
- evidence_assets;
- documents and print_events, to preserve and correctly project historical completion;
- authorization and idempotency records.

Proposed writes:
- inspections: lifecycle state/current draft pointer or revision counter and row_version;
- inspection_events: append inspection.reopened transition;
- audit_events: append inspection.reopened;
- idempotency_records: persist result.

Do not update or delete the approved inspection_revisions row, review_events, finalized evidence, generated documents or print_events. If a new draft needs separate mutable response storage, that physical structure is a required design decision before implementation.

### CMD-033

Source section: ### 4.5 Physical read/write set

Proposed reads:
- inspections;
- unit_claims;
- unit_project_associations;
- operational_assignments and assignment_members;
- instrument_versions and evidence_slot_definitions;
- existing evidence_assets for duplicate and quota accounting;
- authorization and idempotency records.

Proposed writes:
- evidence_assets: create PENDING_UPLOAD metadata row with server-generated object key/reference and declared metadata;
- idempotency_records;
- audit_events: append evidence.upload_intent_created or the canonical event selected by the audit catalogue.

Storage authorization is an external side effect. The exact storage object and token-generation contract must be designed separately. The physical schema currently lists evidence_assets fields but does not explicitly list intent expiry, upload authorization state, client_file_id, reservation accounting or quota-reservation lifecycle.

### CMD-034

Source section: ### 5.5 Physical read/write set

Proposed reads:
- evidence_assets;
- inspections;
- unit_claims and operational_assignments/assignment_members;
- evidence_slot_definitions and pinned instrument version;
- authorization and idempotency records.

Proposed writes:
- evidence_assets: transition pending → finalized/verified and persist server-observed metadata;
- audit_events: append evidence.uploaded;
- idempotency_records: persist final result.

The Storage object itself is not a relational write. Orphan object reconciliation and deletion are separate controlled lifecycle operations and must not be silently folded into this command.

### CMD-035

Source section: ### 6.5 Physical read/write set

Proposed reads:
- sync_batches;
- inspections;
- unit_claims;
- unit_project_associations;
- operational_assignments and assignment_members;
- sessions/projects/locations;
- checklist_responses and specification_responses;
- instrument_versions, checklist_items and specification_fields;
- device registry/binding state (physical model missing);
- authorization and idempotency records.

Proposed writes:
- sync_batches: one durable batch envelope and terminal/partial state;
- checklist_responses and specification_responses: only allowlisted draft response mutations;
- inspections: increment row_version for each successfully applied operation;
- inspection_events and audit_events for applied/conflicted outcomes as required by the audit policy;
- idempotency_records;
- durable per-operation result ledger (physical object/table not currently specified).

Important physical-schema gap: the current physical specification lists sync_batches but does not list sync_batch_operations or another child object that durably records every operation's outcome, semantic hash and replay result. A batch-level status alone cannot reliably reconstruct partial application or answer a lost-acknowledgement retry. A candidate child ledger is required for design review; its name and schema are NOT approved here.

### CMD-036

Source section: ### 7.5 Physical read/write set

Proposed reads:
- documents;
- inspections and inspection_revisions;
- instrument_versions and immutable snapshot data;
- projects/sessions/locations and authorization scope;
- attendance_records/attendance_documents only for approved attendance document types;
- approved template/version registry (physical table/object not yet specified);
- existing documents for duplicate generation key;
- idempotency records.

Proposed writes:
- documents: reserve one immutable generation identity/status and later finalize output_hash/object_key/status;
- audit_events: document generation accepted/generated/failed events as defined by the audit catalogue;
- idempotency_records;
- durable renderer job/outbox record (physical design missing).

Important physical-schema gaps:
- documents currently lists inspection_revision_id but does not define a generic source_resource_type/source_resource_id mapping for BA or attendance source types.
- A template registry/version table and approved template lifecycle are not explicit in the physical table catalogue.
- No generic document-generation job/outbox/lease/attempt table is specified. notification_outbox is notification-specific and must not be silently reused for PDF work.
- document version identity and template snapshot/hash semantics need exact schema.
- The catalogue references attendance_records as a possible source, but its relationship to documents and immutable output provenance is not yet fully physicalized.

### CMD-037

Source section: ### 8.5 Physical read/write set

Proposed reads:
- documents;
- projects/sessions/locations and assignment scope;
- authorization and idempotency records;
- print_events to derive current sequence if the database row does not store a sequence counter.

Proposed writes:
- print_events: append exactly one event with actor, document, sequence_no, attempt_no, outcome, safe client_print_signal and idempotency reference;
- audit_events: append document.printed or document.reprinted;
- idempotency_records.

The physical schema does not list document_version as a documents key column or an explicit immutable document-version table. It also does not state where the current print sequence is materialized. The implementation contract must choose a stable version identity and concurrency-safe sequence allocation before approval.

### CMD-038

Source section: ### 9.5 Physical read/write set

Proposed reads:
- print_batches;
- documents;
- print_events;
- assignment/project/session/location scope;
- authorization and idempotency records;
- previous batch outcomes for retry_failed_only.

Proposed writes:
- print_batches: create durable batch row and update aggregate status/counts only through controlled transitions;
- print_events: append one per-document attempt outcome, including a safe failure outcome where the target document is resolvable and policy permits recording it;
- audit_events: batch-created/completed/partial events and per-document print events;
- idempotency_records.

Important schema gap: print_batches and print_events exist in the proposed physical catalogue, but there is no explicit print_batch_items table. print_events has batch_id, document_id, outcome, failure_code, attempt_no and idempotency_key, which may represent successful and failed attempts for resolvable documents. It does not clearly persist the full requested manifest, stable item_key, or outcomes for invalid/unresolvable items. A batch-level requested_count is insufficient to reconstruct every requested item after a lost acknowledgement. Decide whether a durable child manifest/result table is required; do not assume it exists.

### CMD-039

Source section: ### 10.5 Physical read/write set

Proposed reads:
- attendance_records;
- attendance_documents;
- projects, sessions, locations and operational_assignments/assignment_members for scope;
- app_users and authorization records;
- idempotency records;
- approved file policy and storage configuration (not fully physicalized).

Proposed writes:
- attendance_documents: append a pending upload/version record and later finalize immutable object metadata;
- audit_events: append attendance.uploaded or attendance.replaced;
- idempotency_records.

Physical schema gaps:
- attendance_records currently lists project_id, session_id and status but no location_id or explicit assignment reference, while authorization is location-scoped.
- attendance_documents lists attendance_record_id, object_key, sha256, uploaded_by and status, but not client_file_id, MIME, byte_size, version number, upload intent/expiry, replacement_reason, finalized_at or object-verification metadata.
- No attendance upload intent table or explicit mapping to the generic evidence_assets lifecycle is defined.
- No explicit immutable attendance-document version key or unique active/latest-document constraint is listed.
- The schema must identify which table or relation proves the attendance record's location and assigned Korlap. Do not rely on a client-supplied location_id.

### CMD-040

Source section: ### 11.5 Physical read/write set

Proposed reads:
- attendance_records;
- attendance_documents;
- existing attendance verification history (physical object currently missing);
- projects/sessions/locations and assignment_members/operational_assignments;
- app_users and authorization records;
- idempotency_records.

Proposed writes:
- attendance_records: status/version projection only if the final state model defines it;
- append-only attendance_verification_events (candidate table name; NOT present in current physical inventory), or an equivalently specified immutable event structure;
- audit_events: append attendance.verified or attendance.rejected if the event catalogue is extended;
- idempotency_records.

Physical schema gap: the current catalogue lists attendance_records and attendance_documents but no dedicated verification-event table or detailed verification columns. Updating attendance_records.status alone cannot preserve which document version was checked, who decided, the decision/reason, the checksum, or the history of a later replacement/reverification. The append-only history model must be made explicit before implementation.

### CMD-041

**PHYSICAL READ SET RECONCILED — PROPOSAL, NOT APPROVED:** `inspections`, `inspection_revisions`, `inspection_events`, `review_events`, `documents`, `print_events`, `units`, `unit_project_associations`, `operational_assignments`, `assignment_members`, `sessions`, `locations`, `projects`, and referenced immutable instrument-version records. Authorization resolver reads effective account/grant/scope records. No business-table writes. Optional `audit_events` append only if the approved report-access policy requires it.

The report is computed from authoritative source records; no report snapshot/materialized table is assumed. Apply one authorized scope predicate before aggregation, use event-time and state-as-of semantics from a versioned metric dictionary, and return `measured_at` plus an explicit watermark. Candidate index families (not DDL) are project/session/assignment plus event timestamp and immutable event/resource ID for inspection/review/print events, and project/session/status/version for current-state joins. Exact index keys/order, EXPLAIN plans and numeric bounds remain OPEN pending approved workload and G10 staging evidence. RLS rows for source entities remain controlling; aggregate output must not reveal counts outside location scope.

### CMD-042

**PHYSICAL READ SET RECONCILED — PROPOSAL, NOT APPROVED:** `target_plans`, `target_allocations`, `projects`, `sessions`, `locations`, instrument references and `operational_assignments`/`assignment_members` only where needed to prove effective scope or supported allocation dimensions. Optional actual-progress overlay may read CMD-041 source entities only after PO approval and must carry its own metric-definition version and watermark. No business-table writes.

Resolve one immutable PUBLISHED `target_plans` version once per cursor chain; bind the cursor to actor, project/session, plan-version ID, normalized filters, sort and snapshot/watermark. Do not use a mutable "latest plan" lookup on subsequent pages. No report snapshot table is assumed. Candidate index families (not DDL): `target_plans(project_id, version, status)` and `target_allocations(target_plan_id, target_date, allocation dimension, id)`; exact dimension key and index order remain dependent on final allocation contract and EXPLAIN evidence.

### CMD-043

**PHYSICAL READ SET RECONCILED — PROPOSAL, T-10 BLOCKED:** `audit_events` plus only the minimum authorization/scope resolver and safe label references (`app_users`, roles/scope grants, projects/sessions/locations) needed for the approved purpose. The query returns event-type-specific allowlisted projections, never arbitrary `metadata` JSON. No mutation to existing audit rows.

Access logging is a distinct append operation, not a read-triggered call back into CMD-043. Candidate anti-recursion rule: the access event carries a dedicated event class/action and correlation ID; the audit-read query excludes its own access-event class by server policy, while other approved readers may see it only if the T-10 field/purpose matrix permits. At most one access event is emitted per request/correlation ID. Whether append failure blocks the read or routes to a durable monitored path is an institutional T-10 decision and remains OPEN. No new purpose/schema registry table is assumed; those are external governance inputs until approved. Candidate index family: `audit_events(scope/time)` and `audit_events(actor/time)` with event ID tie-breaker, subject to classification, partition and query-plan review.

### CMD-044

**BLOCKED / NO EXECUTABLE PHYSICAL SET:** T-10 institutional records/privacy authority is absent. No export route, function, permission grant, job, bucket, worker or artifact may be created. A candidate-only object model is documented in the CMD-041–044 review and physical schema annex for future review; it is NOT admitted to the canonical 48-table inventory. Export requires institutional approval of authority, purpose, SoD, scope, classification, format/volume, recipient, encryption/key custody, download authorization, retention/legal hold, deletion and recovery. Existing `documents` and `notification_outbox` are not to be repurposed.

### CMD-049

Source section: ### 5.5 Physical query and consistency

Proposed read set: notifications, with any minimal policy-safe joins required for display. No mutation is allowed. Use stable deterministic ordering, such as created_at plus immutable id, with a cursor that preserves ordering across pages. Define how concurrent inserts and read-state changes affect page consistency; do not claim a snapshot across pages unless the query mechanism provides one.

The schema lists recipient_user_id, created_at, expires_at, read_at and dismissed_at. Exact indexes for recipient + ordering + unread filtering, composite scope integrity and RLS predicates remain to be reviewed.

### CMD-050

Source section: ### 6.4 Physical write and transaction

Proposed read/write set: one notifications row. Use a guarded recipient-owned update and ensure RLS independently enforces recipient ownership. The update should be monotonic and idempotent. Do not update notification_deliveries, notification_delivery_attempts, outbox, escalation history or source business tables.

The canonical audit event is notification.read, emitted once only when the first set-once transition changes read_at from NULL. The event and state transition commit atomically; a required audit failure rolls back the read transition. Repeated/no-op acknowledgements emit no duplicate event. Inbox page access is not a general audit event; use only privacy-safe aggregate telemetry if operationally needed. This is a design reconciliation, not a deployed audit control.

### CMD-051

Source section: ### 7.5 Physical transaction and audit

Proposed read/write set: notification_policy_versions and audit_events. Publication must atomically validate the draft/hash/version, allocate a unique version, freeze the policy document/hash, record publisher and effective interval, and append the required audit event. Published policy immutability must be enforced at the database boundary, not just UI.

The schema proposes unique policy/scope/version and one effective published version per policy/scope/time interval. Exact locking/exclusion strategy, composite scope FK and indexes are not yet approved. Do not infer a deployed constraint.

### CMD-052

Source section: ### 8.4 Physical write set and transaction

Proposed objects: notification_outbox, notifications and notification_deliveries. Claim using a bounded lease and row-locking strategy equivalent to SKIP LOCKED; never hold a transaction across provider I/O. Create one inbox row per outbox/recipient and one external delivery row per selected notification/channel, with uniqueness preventing duplicates.

NLA-001 proposes unique source_event_id/policy_version_id on the outbox, unique outbox_id/recipient_user_id on notifications, and unique notification_id/channel on notification_deliveries. Partial fan-out remains PROCESSING; retries resume idempotently through these unique arbiters. The outbox and delivery lease tuple is lease_owner, server-issued token hash, monotonic lease_generation and lease_expires_at; every finalizer checks the current tuple. safe_payload is the canonical minimized payload field. Exact nullability, indexes, constraints and recipient eligibility timing still require approval.

### CMD-053

Source section: ### 9.5 Physical write set and history

Proposed objects: notification_deliveries and append-only notification_delivery_attempts. Delivery projection tracks current status; attempts preserve each sanitized try. Provider callback/webhook processing is an untrusted inbound boundary and must authenticate signatures, validate provider reference and legal state transition, deduplicate callbacks and remain idempotent.

**Callback integration boundary:** provider callbacks are assigned to INT-NOTIF-001, a separately authenticated integration ingress, not a new CMD ID and not a browser-callable RPC. It validates provider signature/freshness, maps a known provider message reference to one delivery, uses a durable provider-event deduplication mechanism, and applies only allowlisted monotonic status transitions. Provider-specific authentication, event-ID persistence and dedup retention remain open until a provider is selected; no generic callback mutation path is permitted.

Never persist provider credentials, full provider response bodies, message bodies, access tokens or signed URLs in attempt history. Keep safe provider reference and error codes only.

### CMD-054

Source section: ### 10.5 Physical write set and idempotency

Proposed objects: notification_escalation_events and notification_outbox. Append one event for the unique notification/policy-version/step/event key, then create an outbox intent for the next notification if eligible. The uniqueness constraint makes repeated scheduler ticks idempotent.

NLA-001 proposes unique notification_id/policy_version_id/step_no/event_type. Exact locking, due-time predicate, retry, concurrent scheduler behavior, event/outbox atomicity and retention must be reviewed. No provider I/O occurs in this command.

## 3. Explicit physicalization gaps carried forward

| Command(s) | Physical design gap recorded by source | Required disposition |
|---|---|---|
| CMD-001 | No dedicated account-request entity is listed; `app_users` ownership of request lifecycle is undecided | PO/Engineering decide canonical request/history model; Database specify uniqueness, upsert predicate and FK/trigger edges |
| CMD-002–003 | Account decision state, terminal uniqueness and version mechanism are incomplete | Specify state machine, immutable decision key and concurrent approval/rejection arbiter |
| CMD-004–007 | Role/scope interval constraints, history, row versions and exact scope-type table map remain incomplete | Reconcile permission registry, grant history, SoD, effective intervals and RLS |
| CMD-009–010 | Project row-version/CAS fields and complete closure blocker set are not physicalized | Define aggregate token and enumerate every child writer/finalizer behind the parent fence |
| CMD-011–013 | `sessions.row_version` and increment rule are absent; closure dependency set incomplete | Approve physical token and complete project/session child-fence protocol |
| CMD-014–016 | Assignment/member row-version and capacity serialization implementation/initialization are not fully defined | Prove complete T-14 writer coverage and exact constraints/lock primitive |
| CMD-017 | `target_plans.session_id`, allocation key and draft row-version/CAS unresolved | Reconcile plan scope, immutable published snapshot and draft concurrency |
| CMD-019–020 | Canonical configuration hash/snapshot and database-level child immutability enforcement incomplete | Define canonicalization, snapshot persistence, triggers/ACL and immutable publication |
| CMD-021 | Instrument row-version and lifecycle guard are absent | Define lifecycle transition and shared assignment/deactivation serialization |
| CMD-022–025 | Conflict workflow and conflict-row rank/unique arbiter require explicit design; CMD-023/025 order conflicts retained | Approve canonical identity, conflict resolution, association episode and privacy-safe collision outcomes |
| CMD-026–030 | Claim/inspection event creation, mutable draft representation, review decision uniqueness and physical row-version rules need exact mapping | Reconcile command catalogue, schema, audit events and concurrency tokens |
| CMD-033–034 | Evidence intent expiry/quota reservation, object trust and finalization metadata are incomplete | Define intent lifecycle and Storage TOCTOU/finalization contract; no external I/O under DB locks |
| CMD-035 | Durable per-operation sync result ledger/device registry is not specified | Decide per-operation transaction model and physical operation ledger/device trust boundary |
| CMD-036 | Generic document generation job/outbox, worker lease/ACL, template registry and source identity are missing | Design dedicated durable job/lease model and immutable artifact provenance |
| CMD-037–038 | Document version identity, print sequence storage, durable batch item manifest/result model are incomplete | Define sequence allocator and recoverable per-item batch outcomes |
| CMD-039–040 | Attendance location/assignment authority, upload intent/version fields and verification history are incomplete | Obtain institutional authority and define immutable attendance document/verification model |
| CMD-041–044 | Command-specific physical read/write details, report snapshot/watermark, audit read purpose/RLS and T-10 export design are not fully specified | Define bounded query objects/indexes/cursors; CMD-044 remains blocked by T-10 |
| CMD-049–054 | Notification indexes, composite scope integrity, policy exclusion constraints, worker ACL/lease schema and provider-event dedup remain unverified | Complete NLA physical schema, exact unique keys, worker identity, callback auth and retry proof |

## 4. Verification result

Static extraction produced 50 command-specific entries: 40 source-derived entries for CMD-001–040, 4 explicit OPEN/BLOCKED entries for CMD-041–044, and 6 source-derived entries for CMD-049–054. CMD-045–048 are excluded external IDs. This is source extraction, not physical schema validation.

Current status: LPR-09 OPEN; LPR-10 NOT EXECUTED; 0/50 technically certified; G9 NOT READY; G10 NOT ACTIVE. No live database, RLS, grants, Storage or provider environment was inspected; no SQL, migration, test, CI or deployment was executed.

## Aggregate concurrency proposal cross-reference — 2026-11-24

[AGGREGATE-CONCURRENCY-RESOLUTION-001](AGGREGATE-CONCURRENCY-RESOLUTION-001.md) v0.1.0 records a candidate aggregate-token and parent-fence design for CMD-009–016. It distinguishes entity row-version CAS, parent lifecycle fences and T-14 capacity serialization. Candidate tokens are proposed for `projects`, `sessions`, `operational_assignments` and `project_capacity_settings`; no field is approved by this cross-reference. CMD-015's expected assignment aggregate version is a proposed request-contract addition and remains open. The proposal does not resolve the complete project/session child-writer/finalizer inventory, the complete T-14 population writer set, PostgreSQL lock compatibility or implicit FK/trigger/function edges. Existing OPEN status remains unchanged; no command is technically certified.


## Durable operation and artifact lifecycle proposal cross-reference — 2026-11-24

[DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001](DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md) v0.1.0 records candidate physical boundaries for CMD-035 sync operation results/device binding, CMD-036 immutable template versions and renderer job/attempt lifecycle, CMD-038 immutable print batch-item manifest and append-only item outcomes, and CMD-039/040 attendance document version and verification history. Candidate names are not canonical schema and are not approved for implementation. Attendance location/assignment authority, device enrollment/revocation, template publication authority, per-item attempt identity, uploader/verifier SoD, RLS/ACL and retention remain open. No technical certification or gate status is advanced.
