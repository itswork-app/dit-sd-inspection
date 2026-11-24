# CMD-031–040 Detailed Contract Review

**Status:** Engineering contract review — proposal only; PO/security/institutional review required; NOT approved for implementation  
**Document version:** 0.2.3  
**Date:** 2026-11-24  
**Scope:** CMD-031 through CMD-040  
**Repository phase:** Documentation / SSOT maturation  
**Controls:** T-08 attendance authority; T-09 limited offline direction; T-10 institutional records/privacy gate; T-13 print batch; T-15 append-only audit; T-18 Option A command boundary; G9 NOT READY; G10 NOT ACTIVE pending verified G9 and the required separate G10 activation record.

## 1. Purpose, authority and non-authority

This document expands the canonical PostgreSQL Command Contract Catalogue for CMD-031–040. It is a documentation-only engineering review. It does not authorize application source changes, SQL, migrations, PostgreSQL functions, route exposure, grants/revokes, RLS changes, live database changes, storage-policy changes, deployment, CI execution or merge.

The command catalogue remains the source of stable logical command IDs, proposed permission codes, command intent and test-series references. The physical database specification remains the proposed physical-object source. The permission registry and authorization verification matrix remain drafts. The PRD, Decision Register, approved PO decisions, MIB-001, DGA-001, IRG-001 and root AGENTS.md retain higher authority according to their scope.

No route name, RPC/function name, table extension, worker identity, storage bucket policy, retention duration, upload limit, batch limit, SoD rule or provider behavior is approved by this review merely because it appears as a candidate below.

### 1.1 Source facts used

- CMD-031 is approve-inspection; CMD-032 is reopen-inspection.
- CMD-033/034 define upload-intent creation and upload confirmation for inspection evidence.
- CMD-035 is the limited offline sync batch.
- CMD-036 is asynchronous approved-document generation.
- CMD-037/038 are individual and bounded batch print recording.
- CMD-039/040 are attendance document upload and attendance verification.
- The physical design names inspections, inspection_revisions, review_events, inspection_events, evidence_assets, documents, print_batches, print_events, attendance_records, attendance_documents, audit_events, idempotency_records and sync_batches.
- T-08 PO direction separates attendance upload and verification permissions. The institutional attendance authority and any uploader/verifier SoD rule remain to be evidenced.
- T-09 permits only bounded offline editing of a draft whose unit was claimed online; offline claim, submit, review and administrative actions are prohibited.
- T-10 requires formal institutional records/legal/privacy review before evidence classification, limits, retention, deletion and related controls can be approved.
- T-13 selects individual and bounded batch printing, failed-only retry and per-document outcomes; an application print signal is not proof of physical paper output.
- T-15 approves append-only audit direction and atomic audit for critical mutations; institutional retention, classification and audit access remain open.
- T-18 Option A is the PO-approved command-boundary direction, not approval of any specific function owner, function signature or EXECUTE grant.

### 1.2 Shared execution contract

Every mutation below inherits the catalogue's common envelope:

1. Vercel route validates method, content type, body size, schema version and strict allowlisted fields. It verifies the Supabase session and forwards the caller JWT.
2. PostgreSQL derives the actor from trusted auth context (auth.uid()), resolves one active/approved application user, and evaluates permission, active role/scope, resource state and SoD in the mutation transaction.
3. Actor, role, permission, reviewer identity and effective scope are never trusted from client payload fields.
4. Protected browser roles receive no direct INSERT/UPDATE/DELETE on business or governance tables. RLS is not a substitute for command authorization.
5. Protected writes follow PO-approved T-18 Option A through narrow SECURITY DEFINER wrappers, with individual function security approval, a dedicated least-privileged NOLOGIN owner, schema-qualified references, fixed empty search_path, PUBLIC/anon denial and exact-signature EXECUTE grants. SECURITY INVOKER remains preferred for scoped reads and non-elevated helpers.
6. Mutation idempotency is scoped to actor + command + resource scope + opaque key, with a canonical semantic request hash. Same key/same hash returns the prior outcome after reauthorization; same key/different hash returns IDEMPOTENCY_KEY_REUSED.
7. The global lock order is idempotency arbitration → relevant project/session/assignment → inspection → evidence/document → append-only events. Lock only invariant-bearing rows; sort multi-row locks deterministically.
8. Business state, domain event, audit event and idempotency outcome commit atomically. Audit failure rolls back the protected database mutation.
9. Do not hold database locks across Storage transfer, PDF rendering, provider calls or other network I/O. Use intent/finalization or durable outbox/job reconciliation.
10. Return stable typed outcomes. Do not leak resource existence to unauthorized callers or expose SQL, stack traces, secrets, signed URL tokens or raw evidence.
11. Candidate routes and RPC names below are naming proposals only. The command catalogue explicitly says physical function and REST route names are not approved.
12. All tests listed in the QA catalogue remain PLANNED / NOT EXECUTED unless a separate execution record proves otherwise.

### 1.3 Common response envelope proposal

Each successful or safely rejected command should return a versioned response containing:

- schema_version;
- command_id;
- outcome;
- correlation_id;
- resource identifiers that the caller is authorized to know;
- resulting resource version or sequence where applicable;
- event identifier(s) where applicable;
- idempotent_replay boolean;
- server occurred_at timestamp;
- typed error code and safe field-level validation details for rejected outcomes.

The response must not contain a signed Storage URL in durable audit metadata, raw evidence bytes, access tokens, internal SQL diagnostics or hidden cross-scope identifiers. Short-lived upload authorization is returned only by the upload-intent operation over the authenticated transport and is never persisted in audit payloads.

## 2. Contract review — CMD-031 approve-inspection

### 2.1 Intent and state transition

Approve one exact submitted inspection revision. Approval is a review decision on an immutable revision, not an edit to Inspector answers. The inspection aggregate may transition to APPROVED only if the exact submitted revision remains current and reviewable at commit time.

The approved revision remains immutable. Approval does not generate a PDF, record a print, or by itself establish unit completion. Those are separate CMD-036 and CMD-037 operations.

### 2.2 Proposed request schema

Required fields:
- schema_version;
- inspection_id: UUID;
- revision_id: UUID;
- expected_revision_no: positive integer;
- idempotency_key: opaque high-entropy key.

Optional field:
- reason: bounded text only when an approved policy requires a reason for approval or exception.

Forbidden fields:
- actor_user_id, reviewer_id, role, permission, project_id, session_id, location_id, assignment_id, approval timestamp, target status, or client-supplied audit fields.

### 2.3 Proposed response schema

Outcome APPROVED returns:
- inspection_id;
- revision_id;
- approved_revision_no;
- inspection_status = APPROVED;
- resulting row_version;
- review_event_id;
- inspection_event_id;
- audit_event_id;
- occurred_at;
- idempotent_replay.

Typed rejections include INVALID_STATE, REVISION_NOT_CURRENT, REVISION_NOT_SUBMITTED, STALE_VERSION, SOD_VIOLATION, REVIEW_ASSIGNMENT_REQUIRED, PERMISSION_DENIED, ACCOUNT_INACTIVE, IDEMPOTENCY_KEY_REUSED and AUDIT_WRITE_FAILED.

### 2.4 Authorization, scope and SoD

Permission: inspection.review.

Required checks:
- authenticated actor resolves to one active and approved app_users row;
- active inspection.review grant is valid at transaction time;
- reviewer is explicitly assigned to the inspection's project/session/location/assignment scope through approved persisted assignment data;
- inspection is within the reviewer's effective assignment scope;
- target revision belongs to the supplied inspection and is in the exact submitted state;
- target revision number equals expected_revision_no and the inspection's current reviewable revision;
- reviewer is not the revision author;
- reviewer is not inferred from a client-supplied role or from a generic Super Admin label;
- account, role, scope and assignment are not revoked/expired at authorization time;
- any institutional review qualification or reviewer eligibility rule must be evidenced before being enforced as an approved rule.

A second reviewer is not required by the current catalogue. Do not introduce dual approval without a PO/institutional decision.

### 2.5 Physical read/write set

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

### 2.6 Transaction, lock and idempotency

- Claim the idempotency scope before aggregate mutation.
- Lock the inspection aggregate row.
- Re-read and validate current revision number, submitted state, revision ownership, author, reviewer assignment, permission and scope after lock acquisition.
- Enforce one terminal review decision per revision using a database uniqueness/invariant mechanism. The existing review_events design says one terminal decision per revision unless an explicit workflow permits otherwise.
- Update inspection state and row_version, append review_events and inspection_events, append audit_events, and persist idempotency result in one transaction.
- Concurrent approve/return attempts for the same revision must serialize; exactly one terminal decision may commit.
- A replay with the same key and semantic payload returns the stored result only after current authorization is rechecked. A different payload under the same key is rejected.

### 2.7 Audit and typed outcomes

Required business event: inspection.approved.

Audit metadata should identify inspection, revision, revision number, actor, active role/scope, outcome, correlation ID and server timestamp. Do not copy inspection answers or evidence payload into the audit row.

Audit insertion failure must roll back the status transition and review event. A denied attempt may produce a security audit event through the approved safe denial path; it must not expose whether an out-of-scope inspection exists.

### 2.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/inspections/{inspection_id}/approve
- Candidate RPC: cmd_approve_inspection_v1
- Candidate permission: inspection.review
- Candidate response: APPROVED or typed conflict/denial outcome.

These names are not verified against deployed routes, function inventory or EXECUTE ACL.

### 2.9 Required tests

Positive: assigned active reviewer approves the exact submitted revision authored by another user.

Negative: self-review; wrong project/session/location; inactive or expired assignment; wrong revision; draft/returned/previously approved state; stale revision number; inactive account; missing permission; forged actor/reviewer/scope; direct browser DML.

Replay: same key/same payload returns one existing decision; same key/different payload returns IDEMPOTENCY_KEY_REUSED; replay after permission revocation does not disclose prior result without reauthorization.

Concurrency: approve vs return; two simultaneous approvals; stale revision racing with reopen; review and audit append ordering.

Audit failure: injected audit append failure leaves inspection status, review_events and inspection_events unchanged.

Existing QA mapping: TC-CMD-CONTRACT-024-031 and TC-FN-SEC-025-031 — both PLANNED / NOT EXECUTED.

## 3. Contract review — CMD-032 reopen-inspection

### 3.1 Intent and state transition

Reopen a previously approved inspection only through explicit reopen authority, with a mandatory reason and preserved approved history. The prior approved revision, its evidence, generated documents and print events remain historical records and are never overwritten or deleted.

The command creates a new editable revision context. The current physical specification does not yet make the persistence representation for that draft context sufficiently explicit. Do not assume that a new immutable inspection_revisions row should be inserted before the new draft is submitted.

### 3.2 Proposed request schema

Required fields:
- schema_version;
- inspection_id: UUID;
- approved_revision_id: UUID;
- expected_row_version: positive integer;
- reason: bounded non-empty text;
- idempotency_key.

Forbidden fields:
- actor_user_id, role, target status, new revision number, author_id, approval override, previous evidence mutation or client timestamp.

### 3.3 Proposed response schema

Outcome REOPENED returns:
- inspection_id;
- preserved_approved_revision_id;
- current inspection status = REOPENED (or the final approved state-machine label if the PO resolves a distinct draft state);
- new draft context reference, if and only if the physical model defines one;
- current_revision_no and resulting row_version;
- inspection_event_id;
- audit_event_id;
- occurred_at;
- idempotent_replay.

The draft context identifier and status vocabulary are unresolved. The response must not invent a revision identifier that has no persisted row.

Typed rejections: REOPEN_NOT_AUTHORIZED, INVALID_STATE, APPROVED_REVISION_MISMATCH, STALE_VERSION, ACTIVE_WORK_CONFLICT, PERMISSION_DENIED, IDEMPOTENCY_KEY_REUSED and AUDIT_WRITE_FAILED.

### 3.4 Authorization, scope and SoD

Permission: inspection.reopen.

Required checks:
- explicit approved reopen grant; the permission registry describes explicit Super Admin or separately authorized Admin authority, but the exact grantor/role matrix remains draft;
- target inspection is in the actor's authorized project/inspection scope;
- current inspection is APPROVED and approved_revision_id is the exact approved immutable revision;
- actor is not allowed to bypass the explicit permission merely by holding a generic role label;
- account and grant are active and unexpired;
- reason is present and passes length/content policy;
- active claims, later reinspection or other lifecycle constraints are checked using the final approved lifecycle graph;
- any additional approval/SoD requirement is not assumed unless recorded by an authorized decision.

### 3.5 Physical read/write set

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

### 3.6 Transaction, lock and idempotency

- Claim idempotency first.
- Lock the inspection aggregate row.
- Revalidate approved state, exact approved revision, row_version, permission, project scope and current claim/lifecycle blockers under the lock.
- Create or point to exactly one new draft context according to the PO-approved revision model.
- Preserve historical approved revision and all downstream artifacts.
- Update aggregate state/version and append inspection_events + audit_events + idempotency result atomically.
- Concurrent reopen requests with different keys must not create two active draft contexts.
- A replay returns the original result after reauthorization.

### 3.7 Audit and typed outcomes

Required event: inspection.reopened. Reason is mandatory. Audit must reference the prior approved revision and the new draft context if one is durably created. Audit failure rolls back the reopen transition and new draft-context creation.

### 3.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/inspections/{inspection_id}/reopen
- Candidate RPC: cmd_reopen_inspection_v1
- Candidate permission: inspection.reopen

No deployed route, RPC signature or EXECUTE grant is verified.

### 3.9 Required tests

Positive: explicitly authorized actor reopens the exact approved revision with a reason.

Negative: generic Super Admin without explicit grant; non-approved inspection; wrong approved revision; stale row_version; missing reason; out-of-scope project; invalid account; client-supplied author/status; attempt to mutate historical evidence/document.

Replay: same request produces one draft context; different payload under same key is rejected.

Concurrency: two reopen requests; reopen racing with report/document generation; reopen racing with a new claim or reinspection; stale clients cannot fork active draft contexts.

Audit failure: no state change and no new draft context if audit append fails.

Existing QA mapping: TC-CMD-CONTRACT-024-032 and TC-FN-SEC-025-032 — PLANNED / NOT EXECUTED.

## 4. Contract review — CMD-033 create-upload-intent

### 4.1 Intent and lifecycle

Create a short-lived, narrowly scoped authorization for uploading one evidence object to private Storage. The database records a pending metadata/intent state before bytes are transferred. The client never chooses an authoritative Storage object key.

This command does not prove that bytes were uploaded, does not finalize evidence, and does not satisfy a required evidence slot until CMD-034 has verified and finalized the object.

### 4.2 Proposed request schema

Required:
- schema_version;
- inspection_id;
- revision_context reference;
- slot_definition_id;
- declared_mime_type;
- declared_byte_size;
- declared_sha256;
- client_file_id: stable client-generated opaque identifier;
- idempotency_key.

The declared metadata is an expectation only. It is not proof of actual object type, size or checksum.

Forbidden:
- raw object_key, bucket name, signed URL, Storage path, uploaded_by, verified=true, final status, project/assignment override, arbitrary slot configuration or client quota override.

### 4.3 Proposed response schema

Outcome INTENT_CREATED returns:
- evidence_asset_id;
- intent status = PENDING_UPLOAD;
- server-generated opaque object reference;
- short-lived upload authorization or upload target;
- allowed method/content type/headers where provider supports them;
- expires_at from server time;
- maximum policy-derived constraints;
- correlation_id and idempotent_replay.

Do not log or audit the signed authorization value. Its TTL, maximum file size, per-inspection quota, allowed MIME types and resumable upload support are OPEN pending T-10/institutional policy and provider evidence. No numeric value is invented here.

### 4.4 Authorization, scope and SoD

Permission: evidence.upload.

Required checks:
- actor is the Inspector who owns the active claim, or another explicitly authorized actor if approved by the final policy;
- inspection is in DRAFT/authorized editable state;
- active claim, association and assignment still bind to the same unit, project, session, location and published instrument version;
- requested slot belongs to the exact instrument version pinned to the inspection;
- slot applicability and required/optional semantics are evaluated using the pinned instrument snapshot;
- MIME/size/quota constraints come from an approved policy version, not client input;
- account, assignment and claim remain active at transaction time;
- duplicate client_file_id is idempotent only when semantic metadata matches;
- upload intent cannot be used to attach evidence to another inspection, revision or slot.

### 4.5 Physical read/write set

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

### 4.6 Transaction, lock and idempotency

- Claim idempotency first.
- Lock the inspection aggregate and any quota/reservation row required by the final policy.
- Recheck claim, assignment, slot/version and authorization.
- Create one pending evidence metadata record and persist the intent outcome atomically with audit/idempotency.
- Generate a narrow, short-lived upload authorization after the transaction or through a carefully defined provider adapter; do not hold DB locks during token/provider calls.
- If token generation fails after reservation, return a retryable outcome and reconcile the pending reservation without creating duplicate metadata.
- Concurrent uploads must not exceed the approved quota. A count-then-insert without a serialization point is insufficient.

### 4.7 Audit and typed outcomes

Required event candidate: evidence.upload_intent_created. Existing audit catalogue includes evidence upload/access events but exact intent event naming needs reconciliation. Never store raw signed URLs, auth tokens, evidence bytes, or full client payload in audit metadata.

Typed outcomes: INTENT_CREATED, SLOT_INVALID, CLAIM_INVALID, ASSIGNMENT_INVALID, QUOTA_EXCEEDED, FILE_POLICY_REJECTED, DUPLICATE_CLIENT_FILE, INTENT_EXPIRED, PERMISSION_DENIED and RETRYABLE_FAILURE.

### 4.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/inspections/{inspection_id}/evidence-upload-intents
- Candidate RPC: cmd_create_evidence_upload_intent_v1
- Candidate permission: evidence.upload

No function or Storage policy is verified.

### 4.9 Required tests

Positive: valid active claimant creates intent for a slot in the pinned version.

Negative: wrong claim, expired assignment, wrong instrument version, unknown slot, inapplicable slot, invalid declared type/size, forged object key, other user's inspection, direct Storage access outside authorized path.

Replay: same client_file_id and same hash returns one intent; same identifier with changed semantic metadata is rejected; expired intent cannot be reused.

Concurrency: simultaneous uploads at quota boundary; duplicate client_file_id; claim release racing with intent creation; assignment revocation racing with upload intent.

Audit failure: pending evidence row and intent result do not commit if required audit append fails.

Existing QA mapping: TC-CMD-CONTRACT-024-033 and TC-FN-SEC-025-033 — PLANNED / NOT EXECUTED.

## 5. Contract review — CMD-034 confirm-upload

### 5.1 Intent and lifecycle

Confirm completion of a prior CMD-033 upload by having the server inspect the exact private Storage object bound to the pending evidence record. The command finalizes metadata only after server-observed object existence and policy checks.

Critical correction to the catalogue's proposed request: storage_object_ref and observed_sha256/size/MIME must not be trusted as client assertions. The server must resolve the object reference from its own pending evidence row and obtain actual metadata from the Storage provider. Client-supplied values may be compared as hints, but they are never verification evidence.

### 5.2 Proposed request schema

Required:
- schema_version;
- evidence_asset_id;
- idempotency_key.

Optional:
- upload_completion_reference: opaque provider/client receipt only if the provider's documented API supports it and it is cryptographically or server-side verifiable.

Forbidden:
- caller-supplied authoritative object key, bucket, verified checksum, actual size, actual MIME type, uploader identity or final upload status.

### 5.3 Proposed response schema

Outcome FINALIZED returns:
- evidence_asset_id;
- inspection_id;
- slot_definition_id;
- finalized status = VERIFIED/AVAILABLE (canonical status vocabulary to be fixed);
- server-observed sha256, byte_size and mime_type;
- finalized_at;
- audit_event_id;
- idempotent_replay.

Only metadata safe for the authorized actor is returned. No raw object path or signed download URL is required in this response.

### 5.4 Authorization, scope and SoD

Permission: evidence.upload.

Required checks:
- actor and resource still satisfy the approved upload authorization;
- evidence_asset_id references a pending intent created for the same authorized inspection, slot and revision context;
- active claim/assignment and account state are revalidated at finalization time;
- object is in the configured private bucket and at the server-generated key;
- actual object exists and metadata is obtained from the trusted Storage service;
- actual MIME is verified using file signature/content inspection where required, not only extension or browser header;
- actual size is within the approved limit;
- actual checksum is computed or provider-verified according to an approved integrity contract;
- object has not already been finalized, replaced, attached elsewhere or expired.

### 5.5 Physical read/write set

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

### 5.6 Transaction, lock and idempotency

Two-stage external workflow:
1. Outside a DB transaction, load the pending intent by ID under an authorized read, derive its server-owned object key, and inspect the private Storage object. Do not accept a client-supplied key as the lookup target.
2. Start a short DB transaction, claim idempotency, lock the evidence row, revalidate pending state, actor, claim/assignment, intent expiry and expected object identity, compare server-observed metadata, then finalize evidence + audit + idempotency atomically.

If the object disappears or changes between inspection and finalization, reject or retry safely. The object key and checksum must be immutable after finalization. Do not hold a row lock while calling Storage.

Same-key replay returns the prior result only after authorization. Same key with changed semantic payload is rejected. A second confirm for an already-finalized object may return ALREADY_FINALIZED only when the actor remains authorized and the request maps to the same immutable object.

### 5.7 Audit and typed outcomes

Required event: evidence.uploaded. Audit records evidence asset, inspection, slot, checksum, size, MIME, actor, scope, timestamp and correlation; never store object authorization tokens or bytes.

Typed outcomes: FINALIZED, OBJECT_MISSING, OBJECT_METADATA_MISMATCH, CHECKSUM_MISMATCH, MIME_REJECTED, SIZE_REJECTED, INTENT_EXPIRED, CLAIM_INVALID, ALREADY_FINALIZED, RETRYABLE_STORAGE_FAILURE and AUDIT_WRITE_FAILED.

### 5.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/evidence-assets/{evidence_asset_id}/confirm
- Candidate RPC: cmd_confirm_evidence_upload_v1
- Candidate permission: evidence.upload

The RPC must not receive caller-asserted observed metadata as trusted arguments. Whether Storage inspection belongs in the Vercel route/provider adapter or a separately approved trusted worker remains an architecture decision.

### 5.9 Required tests

Positive: valid pending intent and actual private object match the approved metadata policy.

Negative: forged object key; wrong bucket; public object; missing object; changed object; checksum mismatch; MIME spoof; size over limit; expired intent; revoked assignment; unauthorized actor; direct browser metadata mutation.

Replay: confirm replay; same key/different asset; concurrent duplicate confirmation; expired intent replay; finalized immutable object cannot be replaced in place.

Concurrency: confirm vs intent expiry; confirm vs claim release; confirm vs inspection submit; object replacement race.

Audit failure: evidence must not become finalized if audit insertion fails. Reconciliation must identify any object left in Storage without a finalized database reference.

Existing QA mapping: TC-CMD-CONTRACT-024-034 and TC-FN-SEC-025-034 — PLANNED / NOT EXECUTED.

## 6. Contract review — CMD-035 sync-batch

### 6.1 Intent and allowed operation set

Apply a bounded batch of offline edits for the authenticated user's own device and previously claimed inspection drafts. This is not a generic offline command bus.

T-09 expressly prohibits offline claim acquisition, submit, approval/review, role or assignment changes, session administration and other privileged actions. Final submit remains online and must revalidate server-confirmed evidence and unresolved conflicts.

The only candidate offline operation in this review is a narrow draft patch operation over allowlisted checklist/specification responses and notes. The final operation allowlist must be reconciled with the approved offline UX and instrument schema; do not permit arbitrary table names, SQL, generic patch paths or unknown operation types.

### 6.2 Proposed request schema

Required:
- schema_version;
- device_id: opaque registered device reference;
- batch_id: stable client-generated UUID;
- payload_hash: canonical hash of the full semantic batch;
- idempotency_key;
- operations: bounded array of operations, each containing operation_id, inspection_id, expected_row_version, operation_type and strict allowlisted payload.

Candidate operation payload:
- checklist response patch entries keyed by checklist item ID;
- specification response patch entries keyed by specification field ID;
- notes patch only if allowed by the approved offline contract.

Forbidden:
- actor_user_id, role, permission, assignment scope, claim owner, target status, submitted revision, approval decision, arbitrary entity/table name, object key, evidence verification state, server timestamp or operation ordering override.

Maximum batch count, payload bytes, retry horizon and per-inspection operation count are OPEN and must be set from approved workload/device/provider evidence.

### 6.3 Proposed response schema

Outcome APPLIED, PARTIAL or CONFLICTED returns:
- batch_id;
- batch status;
- server acknowledged_at;
- ordered per-operation results containing operation_id, inspection_id, outcome, resulting row_version if applied, safe error code if rejected/conflicted, and whether the operation was an idempotent replay;
- retry guidance that preserves unacknowledged client operations.

The response must not imply that an entire batch was atomic. Each operation result is durable and independently reconcilable.

### 6.4 Authorization, scope and SoD

Permission: sync.apply.

For each operation, independently revalidate:
- device is registered, bound to auth.uid(), active and not revoked;
- authenticated account is active and approved;
- the inspection was claimed online by this actor before the offline session and the claim remains eligible under the approved recovery/expiry policy;
- actor is still the authorized Inspector for that inspection's persisted assignment;
- inspection is still in an editable draft state;
- project, session, location, assignment, unit association and instrument version still match persisted records;
- expected row_version is current or the operation follows a specifically approved merge policy;
- each item/field belongs to the exact pinned instrument version;
- no operation type is claim, release, submit, approve, return, reopen, attendance verification, permission change, assignment change, session/project administration or document print/generation;
- no client-supplied identity, role or scope can widen authorization.

Device identity and revocation are material security dependencies. The current physical schema references device_id in sync_batches but does not define a device registry/binding/revocation table or complete credential lifecycle.

### 6.5 Physical read/write set

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

### 6.6 Transaction, lock and idempotency

- Validate batch envelope and canonical payload hash before processing.
- Arbitrate batch key by actor + device + batch_id and reject same batch ID with different hash.
- Persist batch envelope durably.
- Process operations in deterministic client sequence or an explicitly defined server order; sort inspection locks deterministically to prevent deadlocks.
- Reauthorize every operation immediately before applying it.
- Each operation uses its own short transaction or a clearly specified savepoint strategy. A failed operation must not erase previously committed successful operations.
- Compare expected_row_version; stale operations become explicit CONFLICTED results and preserve client data for user resolution. Never use last-write-wins.
- A duplicate operation_id with the same semantic hash returns the original operation result. Same ID with a different hash is rejected.
- Batch replay returns stored per-operation results after reauthorization; it must not reapply committed changes.
- Persist acknowledgement only after all operation outcomes are durable.
- Evidence bytes are not silently synchronized through this command. Evidence upload follows the dedicated online intent/finalization workflow unless a separately approved offline evidence design exists.

### 6.7 Audit and typed outcomes

Required event family: sync.batch_applied and/or sync.batch_conflicted, plus relevant inspection.draft_saved/domain events for successfully applied operations.

Do not log raw offline payloads, personal information beyond necessity, evidence bytes, tokens or device secrets. Audit should reference batch and operation IDs, inspection IDs, safe outcome codes and server timestamps.

Typed outcomes: APPLIED, PARTIAL, CONFLICTED, DEVICE_NOT_BOUND, DEVICE_REVOKED, CLAIM_INVALID, INSPECTION_NOT_EDITABLE, STALE_VERSION, OPERATION_NOT_ALLOWED_OFFLINE, FIELD_NOT_IN_PINNED_VERSION, PAYLOAD_HASH_MISMATCH, IDEMPOTENCY_KEY_REUSED, BATCH_TOO_LARGE and RETRYABLE_FAILURE.

### 6.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/sync/batches
- Candidate RPC: cmd_apply_sync_batch_v1
- Candidate permission: sync.apply

No device authentication, route, RPC or device credential lifecycle is verified.

### 6.9 Required tests

Positive: own active device syncs a draft patch to a previously claimed inspection.

Negative: unbound/revoked device; different actor; unclaimed inspection; expired/released claim; wrong assignment; submitted/approved inspection; unknown operation; offline submit/review/claim/admin; forged actor/scope; stale version; direct DML.

Replay: same batch/hash; same batch/different hash; duplicate operation ID/same hash; duplicate operation ID/different hash; lost acknowledgement then retry; replay after permission/device revocation.

Concurrency: two devices or batches edit same inspection; operations for multiple inspections in reverse order; claim expiry during sync; role/assignment revocation during sync; same operation submitted concurrently.

Audit failure: each applied mutation and required audit event must be atomic. If one operation's audit fails, that operation must not commit; prior committed operations remain represented in the durable partial batch result.

Existing QA mapping: TC-CMD-CONTRACT-024-035 and TC-FN-SEC-025-035 — PLANNED / NOT EXECUTED.

## 7. Contract review — CMD-036 generate-approved-document

### 7.1 Intent and supported sources

Generate an immutable PDF artifact from an exact approved source revision and approved template version. The command is asynchronous where rendering or Storage writes occur outside PostgreSQL.

For inspection PDFs, the source is the exact approved immutable inspection revision and frozen instrument configuration. BA and attendance document variants require their own approved source mapping, signatory/template authority and institutional decisions. T-02/T-03 PO directions do not establish institutional signatory identities or authorize a final BA template. T-04 selects PDF-only client delivery for the initial release.

### 7.2 Proposed request schema

Required:
- schema_version;
- document_type from a strict allowlist;
- source_resource_type from a strict allowlist;
- source_resource_id;
- approved_revision_id when the document type is revision-based;
- template_version;
- request_hash or idempotency_key (canonical request hash is computed/verified server-side).

Forbidden:
- caller-supplied output_hash, object_key, generated_by, approved=true, source payload snapshot, arbitrary HTML/template content, executable template code or status override.

### 7.3 Proposed response schema

Initial outcome ACCEPTED returns:
- document_id;
- generation_job_reference;
- document_type;
- source_resource_id;
- approved source revision/version;
- template_version;
- status = QUEUED or GENERATING (canonical status set TBD);
- accepted_at;
- idempotent_replay.

Terminal outcome GENERATED returns:
- document_id and immutable document version;
- output_hash;
- safe download reference only after a separate authorized read/access check;
- generated_at;
- audit event reference.

Failure outcomes: SOURCE_NOT_APPROVED, SOURCE_REVISION_MISMATCH, TEMPLATE_VERSION_UNAVAILABLE, TEMPLATE_NOT_AUTHORIZED, GENERATION_FAILED, STORAGE_FINALIZATION_FAILED, RETRYABLE_FAILURE and IDEMPOTENCY_KEY_REUSED.

### 7.4 Authorization, scope and SoD

Permission: document.generate.

Required checks:
- active document.generate grant and exact project/resource scope;
- source resource belongs to authorized project/session/location;
- inspection source is APPROVED and points to the exact immutable approved_revision_id;
- template version is published/approved and is valid for document_type and source type;
- source snapshot and instrument version are pinned and immutable;
- caller cannot provide a different source hash or mark an unapproved source as approved;
- any BA signatory data is drawn only from an institutionally approved template/authority configuration;
- attendance artifact generation is not treated as attendance verification;
- account and grant remain active at enqueue and finalization boundaries.

### 7.5 Physical read/write set

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

### 7.6 Transaction, lock and idempotency

Two-phase asynchronous workflow:
1. In a short DB transaction, reauthorize source and template, lock only the relevant source/document generation key, reserve a unique generation request, create a PENDING document record, persist a durable job/outbox item, append the accepted audit event and idempotency result.
2. A separately approved worker claims the durable job using a bounded lease, renders outside DB locks, stores the artifact in private Storage, computes/obtains output checksum, and finalizes the document in a short DB transaction.
3. Finalization verifies the same source revision/template version, expected job lease/version and output object metadata; it appends the generated audit event atomically.
4. Failed jobs use bounded retries and explicit terminal failure/dead-letter/reconciliation states. No duplicate final artifact is created for the same generation key.
5. A retry after an uncertain provider response reconciles by immutable request key and object checksum before retrying. Never overwrite a historical artifact in place.

The current schema does not specify the worker identity, job lease, retry policy, renderer provider, template storage or worker ACL. These are blockers, not defaults.

### 7.7 Audit and typed outcomes

Event family: pdf.generated / ba.generated / attendance.generated, plus accepted/failed events if the audit catalogue is extended. Audit must link source resource, exact source revision, template version, output hash, document version, actor/request and timestamps. No raw PDF bytes or signed download URL.

### 7.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/documents/generations
- Candidate RPC: cmd_request_approved_document_generation_v1
- Candidate permission: document.generate
- Candidate worker callback/finalizer: separate trusted internal boundary, exact identity and authorization TBD.

No worker or function privilege is verified.

### 7.9 Required tests

Positive: generate a PDF from exact approved immutable revision and published template.

Negative: unapproved source; wrong revision; changed template; cross-project source; arbitrary template code; caller-supplied output hash/object key; unsupported document type; unauthorized source.

Replay: duplicate generation key; same key/different semantic request; retry after renderer timeout; worker retry after uncertain Storage write; source revision remains immutable.

Concurrency: two requests for same source/template; source reopen racing with generation; duplicate workers; lease expiry while rendering; finalization racing with retry.

Audit failure: enqueue must not be committed without required accepted audit; final artifact status must not become GENERATED without required generated audit. Reconciliation must handle orphan Storage artifacts.

Existing QA mapping: TC-CMD-CONTRACT-024-036 and TC-FN-SEC-025-036 — PLANNED / NOT EXECUTED.

## 8. Contract review — CMD-037 record-print

### 8.1 Intent

Record an application-level print action for one immutable, generated document version. This is evidence that an authorized user initiated/confirmed a print action in the application. It is not proof that a physical printer produced paper, that all pages printed, or that a wet signature was applied.

T-13 requires monotonic per-document sequence and append-only per-document outcomes. Reprints append a new event; they never overwrite a previous print event.

### 8.2 Proposed request schema

Required:
- schema_version;
- document_id;
- document_version;
- idempotency_key.

Optional:
- expected_sequence: positive integer for clients that want stale-sequence detection;
- client_print_signal: small allowlisted signal describing the application UI action, never a printer attestation.

Forbidden:
- actor_id, print_sequence, attempt_no, printed_at, outcome, physical_printer_success, printer device identity or document output bytes.

### 8.3 Proposed response schema

Outcome RECORDED returns:
- document_id;
- document_version;
- sequence_no;
- attempt_no;
- print_event_id;
- resulting document completion projection if safely available;
- audit_event_id;
- occurred_at;
- idempotent_replay.

Typed rejections: DOCUMENT_NOT_FOUND, DOCUMENT_NOT_FINAL, DOCUMENT_VERSION_MISMATCH, PRINT_SCOPE_DENIED, STALE_SEQUENCE, IDEMPOTENCY_KEY_REUSED and AUDIT_WRITE_FAILED.

### 8.4 Authorization, scope and SoD

Permission: document.print.

Required checks:
- actor has active document.print grant in exact project/session/location scope;
- document is final, immutable and downloadable/printable for this scope;
- document version matches the requested immutable version;
- source and project relationship are consistent;
- caller cannot select an arbitrary historical or superseded document unless explicit policy permits reprint;
- no inference of print authority from generic Admin/Super Admin role;
- account and print assignment remain active at transaction time.

### 8.5 Physical read/write set

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

### 8.6 Transaction, lock and idempotency

- Claim idempotency.
- Lock the document aggregate/version row.
- Revalidate document finality, version, source scope and print permission.
- Allocate the next sequence under the same lock and enforce unique (document_id, sequence_no).
- Append print_events and audit_events and persist idempotency outcome atomically.
- A failed audit insert must roll back sequence allocation and print event.
- If expected_sequence is supplied and does not match current sequence, return STALE_SEQUENCE without consuming a sequence.
- A retry with the same idempotency key must not increment the sequence a second time.

### 8.7 Audit and typed outcomes

Required event family: document.printed / document.reprinted. Audit should identify document version, sequence, actor, scope and application signal. Do not label outcome as physical_print_confirmed.

### 8.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/documents/{document_id}/versions/{document_version}/print-events
- Candidate RPC: cmd_record_document_print_v1
- Candidate permission: document.print

No route or RPC is verified.

### 8.9 Required tests

Positive: authorized Print Officer records a print action for a final document version.

Negative: draft/pending/failed document; wrong version; out-of-scope user; missing print permission; caller-forged actor/sequence/time; direct browser DML.

Replay: same key creates one event and one sequence; different payload under same key rejected; reprint with a new key appends a new sequence.

Concurrency: simultaneous print events allocate unique monotonic sequence values; expected_sequence race; document version changes/supersession race.

Audit failure: no sequence/event commit if audit fails.

Existing QA mapping: TC-CMD-CONTRACT-024-037 and TC-FN-SEC-025-037 — PLANNED / NOT EXECUTED.

## 9. Contract review — CMD-038 record-print-batch

### 9.1 Intent and outcome model

Orchestrate bounded print actions for a set of documents. The batch is a durable grouping and reconciliation envelope, not one all-or-nothing print transaction. Each document receives an independently authorized, idempotent outcome. Failed items may be retried; successful items must never be duplicated by a retry.

### 9.2 Proposed request schema

Required:
- schema_version;
- items: bounded array of document_id, document_version and stable item_key;
- idempotency_key for the batch.

Optional:
- retry_failed_only boolean;
- retry_of_batch_id for a retry batch, if the prior batch is eligible.

Forbidden:
- actor_id, requested_count, batch status, item outcome, sequence number, prior success assertion, printer success, arbitrary max count override or document content.

The maximum batch count and rate limits are OPEN and must be derived from workload, provider and UX evidence. Do not choose an arbitrary production number in this document.

### 9.3 Proposed response schema

Outcome SUCCEEDED, PARTIAL or REJECTED returns:
- batch_id;
- batch status;
- requested_count;
- succeeded_count;
- failed_count;
- ordered per-item result with item_key, document_id when authorized, document_version, item outcome, safe error code, print_event_id and sequence_no when recorded;
- retry_batch_eligible;
- created_at/completed_at;
- idempotent_replay.

No response may imply that paper physically printed.

### 9.4 Authorization, scope and SoD

Permission: document.print.batch for batch orchestration and document.print for each item, unless the final approved registry explicitly defines a different non-duplicative authority model.

Required checks:
- actor has batch permission in the relevant project/session/location scope;
- every item independently passes document.print authorization and final-document checks;
- all documents belong to a permitted scope; mixed-scope batches are rejected or partitioned according to an explicit PO-approved rule;
- item document version is exact and final;
- retry_failed_only selects only previously failed items from the referenced batch, not caller-selected successful items;
- caller cannot forge prior failure or success;
- maximum count, request bytes, processing duration and retry count are bounded by approved policy.

### 9.5 Physical read/write set

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

### 9.6 Transaction, lock and idempotency

- Create the batch envelope in a short transaction after batch-level authorization and idempotency arbitration.
- Process each item with its own authorization and short transaction. Do not hold a batch-wide lock while printing or processing external actions.
- Each item has a stable key derived from batch identity + item_key + document version; exact canonical key design must be approved.
- Lock each document aggregate/version independently and allocate its own monotonic sequence.
- Commit per-document event + audit + idempotency outcome atomically.
- Reconcile batch status from durable per-item results; do not trust client-supplied counts.
- A retry batch may include only failed items from its source batch. A prior success cannot be repeated by failed-only retry.
- Duplicate batch replay returns stored results and does not create new attempts.
- If processing stops midway, the batch remains PARTIAL/PROCESSING and can resume from durable item state. The exact lease/worker model is not yet specified.

### 9.7 Audit and typed outcomes

Required events: document.print_batch_created, document.print_batch_completed or document.print_batch_partial, plus per-document document.printed/document.reprinted events.

Audit must distinguish batch orchestration from individual document actions. Batch audit does not replace per-document audit. Do not record physical printer success.

Typed outcomes: SUCCEEDED, PARTIAL, REJECTED, BATCH_TOO_LARGE, MIXED_SCOPE_NOT_ALLOWED, ITEM_NOT_PRINTABLE, ITEM_SCOPE_DENIED, DOCUMENT_VERSION_MISMATCH, RETRY_NOT_FAILED_ONLY, IDEMPOTENCY_KEY_REUSED and RETRYABLE_FAILURE.

### 9.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/print-batches
- Candidate RPC: cmd_create_print_batch_v1 and a separately reviewed item-processing command/worker boundary.
- Candidate permissions: document.print.batch + per-item document.print.

The catalogue currently describes one logical command. Whether batch creation and per-item processing are one command implementation or an orchestration boundary is a design decision, not settled here.

### 9.9 Required tests

Positive: bounded all-success batch; partial batch; retry only failed items; per-item outcomes and batch totals reconcile.

Negative: over-limit batch; mixed unauthorized scope; forged item outcome; retry includes a successful item; draft document; invalid version; missing batch permission; per-item print permission absent; direct DML.

Replay: batch replay; same key/different manifest; duplicate item_key; lost acknowledgement; retry of a partial batch does not duplicate successful items.

Concurrency: two batches print the same document; overlapping retry batches; two workers process same batch; batch status aggregation races with final item completion.

Audit failure: item print event and its audit event are atomic; batch aggregate status cannot claim success if required item/audit records are absent.

Existing QA mapping: TC-CMD-CONTRACT-024-038 and TC-FN-SEC-025-038 — PLANNED / NOT EXECUTED. Eight T-13 print-batch tests are separately referenced by DGA-001; their execution remains unverified.

## 10. Contract review — CMD-039 upload-attendance-document

### 10.1 Intent and lifecycle

Upload or replace an attendance evidence document for one logical attendance record. Upload is never equivalent to verification. A replacement is a new immutable document version with a mandatory reason; prior attendance documents remain preserved.

The current command catalogue describes one logical upload command, while the evidence lifecycle requires an intent → private Storage upload → server verification → finalization sequence. The exact split between intent creation and finalization is not resolved for attendance. Reuse of CMD-033/034's evidence flow may be possible, but it must not be assumed to fit attendance data or authorization without an explicit design decision.

### 10.2 Proposed request schema

Intent phase required:
- schema_version;
- attendance_record_id;
- client_file_id;
- declared_mime_type;
- declared_byte_size;
- declared_sha256;
- idempotency_key.

For a replacement:
- replacement_reason: required bounded non-empty text.

Finalization phase:
- attendance_document_id;
- idempotency_key or a phase-specific continuation key;
- no client-supplied authoritative object key, observed checksum, MIME, size or uploader identity.

Whether both phases share one logical command ID or need distinct command sub-operations is OPEN.

### 10.3 Proposed response schema

Intent phase returns:
- attendance_document_id;
- pending upload state;
- server-generated opaque object reference and short-lived upload authorization;
- expires_at;
- policy-derived allowed metadata;
- idempotent_replay.

Finalization returns:
- attendance_document_id;
- attendance_record_id;
- immutable document version/reference;
- server-observed checksum, byte_size and MIME type;
- status = UPLOADED/PENDING_VERIFICATION (canonical status vocabulary TBD);
- uploaded_at;
- audit_event_id;
- idempotent_replay.

The upload response must never set attendance_records.status to VERIFIED.

### 10.4 Authorization, scope and SoD

Permission: attendance.upload.

Required checks:
- active account and attendance.upload grant;
- actor is an authorized Korlap or separately authorized uploader in the assigned project/session/location;
- attendance record belongs to the actor's effective assignment scope;
- attendance record is in an upload-eligible state;
- replacement references the exact prior document and requires a reason;
- file metadata and actual object are checked against institutionally approved policy;
- upload does not grant attendance.verify;
- no client-supplied project/location/actor field can widen scope.

T-08 says Korlap verifies attendance in assigned location and distinguishes generate, print, upload, download and verify permissions. The actual institutional verification authority and role matrix remain open. Do not infer that every Korlap can upload or that upload authority is global.

### 10.5 Physical read/write set

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

### 10.6 Transaction, lock and idempotency

- Claim idempotency for the upload intent.
- Lock the attendance record and any quota/reservation row required by approved policy.
- Verify record scope and replacement preconditions.
- Create one pending attendance document identity and reservation, then authorize private upload outside the DB transaction.
- After upload, server verifies object metadata and finalizes in a short transaction after locking the attendance record/document.
- Replacement appends a new document version; it never overwrites the prior object or verification history.
- A replacement should not silently preserve a prior VERIFIED status. Whether it resets the attendance record to PENDING_VERIFICATION and invalidates a prior verification projection must be explicitly modeled.
- Repeated upload with same client_file_id and same hash is idempotent; changed payload is rejected.
- Orphan object cleanup is a separately authorized/reconciled lifecycle process; do not delete objects on a failed request without a durable compensation record.

### 10.7 Audit and typed outcomes

Required event family: attendance.uploaded / attendance.replaced. Record attendance_record_id, attendance_document_id/version, actor, scope, checksum, safe metadata, replacement reason and server timestamp. Never store object tokens or bytes.

Typed outcomes: UPLOAD_INTENT_CREATED, UPLOADED, REPLACEMENT_REASON_REQUIRED, ATTENDANCE_RECORD_NOT_FOUND, SCOPE_DENIED, FILE_POLICY_REJECTED, OBJECT_MISSING, CHECKSUM_MISMATCH, INTENT_EXPIRED, ALREADY_FINALIZED, IDEMPOTENCY_KEY_REUSED and RETRYABLE_STORAGE_FAILURE.

### 10.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/attendance-records/{attendance_record_id}/documents
- Candidate confirmation route: POST /api/attendance-documents/{attendance_document_id}/confirm
- Candidate RPCs: cmd_create_attendance_upload_intent_v1 and cmd_finalize_attendance_document_upload_v1.

These are candidates to make the two-phase external upload explicit. The canonical catalogue currently has one CMD-039; whether these are two internal functions under one logical command or a catalogue change requires explicit design review.

### 10.9 Required tests

Positive: authorized assigned Korlap creates and finalizes attendance document; replacement appends a new version and requires reason.

Negative: upload actor outside location; unauthorized role; wrong attendance record; unapproved file type/size; invalid checksum; missing object; forged location/actor/object key; upload attempt treated as verification; direct Storage/table access.

Replay: same client_file_id/hash; same key/different file; retry after uncertain Storage result; duplicate replacement request; prior document remains immutable.

Concurrency: two uploads to same attendance record; replacement races with verification; verification races with finalization; two concurrent replacements cannot create ambiguous latest versions.

Audit failure: no finalized upload/replacement state without required audit; orphan reconciliation remains possible.

Existing QA mapping: TC-CMD-CONTRACT-024-039 and TC-FN-SEC-025-039 — PLANNED / NOT EXECUTED.

## 11. Contract review — CMD-040 verify-attendance

### 11.1 Intent and state transition

Record an authorized decision on one exact attendance document version for one attendance record. Verification is distinct from upload and must not be inferred from file presence, uploader role or successful Storage finalization.

The catalogue permits VERIFIED/REJECTED outcomes and states that uploader/verifier SoD is still to be confirmed if required by institutional policy. The current PO direction does not by itself settle whether the same person may upload and verify the same attendance document.

### 11.2 Proposed request schema

Required:
- schema_version;
- attendance_record_id;
- attendance_document_id;
- decision: VERIFY or REJECT (mapping to final canonical VERIFIED/REJECTED states);
- expected_version;
- idempotency_key.

Optional:
- reason: required for REJECT and any policy-defined exception; bounded non-empty text.

Forbidden:
- actor_id, verifier_id, role, location, uploaded_by, verified_at, target status, checksum or client audit metadata.

### 11.3 Proposed response schema

Outcome VERIFIED or REJECTED returns:
- attendance_record_id;
- attendance_document_id and immutable document version;
- decision;
- resulting attendance status/version;
- verification_event_id;
- audit_event_id;
- occurred_at;
- idempotent_replay.

Typed rejections: VERIFY_AUTHORITY_REQUIRED, ATTENDANCE_RECORD_NOT_FOUND, DOCUMENT_NOT_FINAL, DOCUMENT_VERSION_MISMATCH, SOD_VIOLATION, INVALID_STATE, STALE_VERSION, PERMISSION_DENIED, IDEMPOTENCY_KEY_REUSED and AUDIT_WRITE_FAILED.

### 11.4 Authorization, scope and SoD

Permission: attendance.verify.

Required checks:
- actor has an active attendance.verify grant in the exact assigned location and session/project scope;
- actor is the institutionally authorized verifier for the attendance record;
- attendance document belongs to the supplied attendance record and is finalized, immutable and not superseded;
- verification is against the exact current document version and checksum;
- the same upload permission alone never authorizes verification;
- if institutional SoD requires uploader != verifier, compare trusted uploaded_by with auth.uid() and reject self-verification;
- if SoD has not been decided, do not silently assume either permissive or restrictive production policy. Keep this rule explicitly BLOCKED until the institutional authority supplies the decision;
- record and document state allow the requested decision; duplicate terminal decisions are rejected unless a formally approved correction/reverification path exists;
- account, role and assignment remain active at transaction time.

### 11.5 Physical read/write set

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

### 11.6 Transaction, lock and idempotency

- Claim idempotency.
- Lock attendance_records, then the exact attendance_documents row in deterministic order.
- Revalidate location scope, active attendance.verify permission, institutional verifier authority, document finalization/version/checksum and expected_version.
- Apply any approved uploader/verifier SoD rule using trusted uploaded_by data.
- Append one verification decision for the exact immutable document version.
- Update the current status projection only if the approved state model requires it.
- Append audit event and idempotency result atomically.
- Concurrent verify/reject attempts on the same version must serialize; exactly one terminal decision is accepted unless a formal re-verification workflow exists.
- A new replacement document must not inherit an earlier document's VERIFIED decision.

### 11.7 Audit and typed outcomes

Required event: attendance.verified for successful verification. The event catalogue currently names attendance.verified but does not clearly enumerate attendance.rejected; add/reconcile a rejected event if that outcome is retained.

Audit metadata must reference attendance record, exact document version/checksum, verifier, assigned location/scope, decision, reason code and server timestamp. Do not include raw file bytes or Storage token.

### 11.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/attendance-records/{attendance_record_id}/documents/{attendance_document_id}/verification
- Candidate RPC: cmd_verify_attendance_v1
- Candidate permission: attendance.verify

No route/RPC or actual EXECUTE ACL is verified.

### 11.9 Required tests

Positive: authorized institutional verifier verifies exact finalized document in assigned location.

Negative: upload-only permission; unassigned location; unauthorized Korlap; unfinalized/superseded document; wrong attendance record; wrong checksum/version; forged verifier/location; prohibited self-verification if institutional SoD is approved; missing institutional authority.

Replay: same decision/key; same key/different decision; duplicate terminal decision; replay after replacement; replay after permission revocation.

Concurrency: verify vs reject; verify vs replacement; two verifiers; assignment revocation during verification; stale expected_version.

Audit failure: verification status and event must not commit if audit append fails.

Existing QA mapping: TC-CMD-CONTRACT-024-040 and TC-FN-SEC-025-040 — PLANNED / NOT EXECUTED.

## 12. Cross-command findings and required decisions

The following findings are design gaps, not implementation defects. No live database or deployed code was inspected.

| Finding | Commands | Evidence / impact | Required closure |
|---|---|---|---|
| C31-01 | 031 | review_events has one terminal decision per revision, but the exact constraint and review assignment/eligibility predicate are not fully physicalized | PO/security approve reviewer assignment, grant matrix, exact revision terminality and uniqueness rule |
| C32-01 | 032 | inspection_revisions is immutable after submission, but the new mutable draft context after reopen has no fully specified physical representation | Decide whether draft responses live in inspection aggregate tables, a separate draft revision table, or another explicit model; reconcile state machine and completion projection |
| C32-02 | 032, 036, 037 | Reopening an approved inspection must preserve the old approved revision, PDF and print history while defining how current completion/report projections behave | PO approve re-open/reinspection and historical document/report treatment |
| C33-01 | 033 | evidence_assets has no explicit intent expiry, client_file_id, reservation/quota state or token lifecycle columns | Physical schema extension or separate intent entity; approved limits/TTL under T-10 and provider evidence |
| C34-01 | 034 | Catalogue proposes caller-observed storage metadata; this must be corrected to server-observed metadata from server-owned object reference | Update canonical command catalogue and route/RPC contract; security review provider metadata verification |
| C35-01 | 035 | sync_batches exists but device registry/binding/revocation and durable per-operation outcome ledger are absent | Define device identity lifecycle and per-operation persistence; align T-09, offline threat model, physical schema and RLS |
| C36-01 | 036 | documents lacks generic source type/id, template registry/version and renderer job/outbox lifecycle | Define source-to-document FK/provenance, template version storage, job state, lease, retry, worker identity and ACL |
| C37-01 | 037 | document version identity and print sequence counter/allocator are not fully represented by the physical schema | Define immutable document version key and lock-safe sequence allocation |
| C38-01 | 038 | print_batches/print_events exist but full item manifest, stable item key and durable outcomes for invalid/unresolvable items are unclear | Decide whether print_batch_items is required; define worker/lease and aggregate reconciliation semantics |
| C39-01 | 039 | attendance_records lacks location/assignment linkage; attendance_documents lacks upload-intent, MIME/size/version/replacement metadata | Define exact location scope relation and complete two-phase upload schema; align with T-08 and T-10 |
| C40-01 | 040 | No explicit attendance verification history object; attendance.rejected event is not clearly in the event catalogue | Define immutable decision history, exact state machine, rejection event and re-verification rules |
| C40-02 | 040 | Uploader/verifier SoD and actual institutional verifier authority remain unresolved | Obtain written institutional authority; do not invent or silently waive SoD |
| C31-040-01 | 031–040 | Exact route/RPC mapping, function owner, SECURITY mode, search_path, EXECUTE grants and live RLS/privilege state are not verified | Per-function review and authorized live catalog inventory before G10 |
| C31-040-02 | 031–040 | All command tests are catalogue specifications only | Execute tests only after G10 and authorized environments; attach reproducible results to exact commit/schema |

### 12.1 Required cross-document reconciliation

Before these contracts can be frozen:
1. Update PostgreSQL Command Contract Catalogue where CMD-034 currently suggests caller-supplied observed metadata; actual Storage metadata must be server-observed.
2. Reconcile inspection lifecycle state machine, reopen behavior, revision numbering and completion projection across PRD, functional design, physical schema and reports.
3. Reconcile evidence upload intent fields, quota reservation, private Storage authorization, finalization and orphan compensation.
4. Reconcile T-09 offline device identity, operation allowlist, per-operation result persistence, revocation and retry horizon.
5. Reconcile document source types, template versions, immutable document versions, generation job/outbox and worker identity.
6. Reconcile T-13 batch manifest, per-document failure outcomes, failed-only retry, lock/idempotency and aggregate status.
7. Reconcile attendance location scope, upload/finalization, verification history, SoD and institutional authority.
8. Reconcile event names and append-only audit event payloads with the audit catalogue and T-15 policy.
9. Update RTM, DGA-001 and RAID only after the accountable document owner accepts the finding mapping and status evidence.
10. Keep proposed candidate names visibly provisional until approved and checked against the actual database/function inventory.

## 13. Consolidated test plan

All tests below are specifications, not executed evidence.

| Test dimension | Minimum coverage across CMD-031–040 |
|---|---|
| Positive | One valid authorized path per command with exact persisted resource/version |
| Negative authorization | Wrong user, wrong project/session/location/assignment, inactive account, expired/revoked permission, forged actor/role/scope |
| State validation | Wrong inspection/revision/document/attendance state; stale version; superseded artifact |
| SoD | Inspector/reviewer; uploader/verifier when institutional rule is decided; grant/role cannot bypass SoD |
| Replay | Same key/same payload; same key/different payload; duplicate operation/item; lost acknowledgement; retry after provider timeout |
| Concurrency | Competing review decisions; duplicate reopen; upload/finalize races; multi-device sync; duplicate generation workers; print sequence races; batch retry races; attendance replacement vs verification |
| Audit atomicity | Inject audit write failure for every state-changing transaction; no partial protected state without required audit |
| Direct DML/RLS | Browser anon/authenticated cannot write protected tables; scoped reads do not cross project/session/location; Storage objects remain private |
| Function security | Exact signature, owner, SECURITY mode, search_path, PUBLIC/anon/authenticated EXECUTE ACL and caller-JWT propagation |
| External side effects | Storage missing/metadata mismatch/orphan; renderer timeout/uncertain success; worker lease expiry; partial print batch |
| Recovery | Reconcile pending intents, partial sync batches, queued document jobs, partial print batches and attendance uploads without duplicate mutation |

Existing catalogue mappings:
- TC-CMD-CONTRACT-024-031 through TC-CMD-CONTRACT-024-040.
- TC-FN-SEC-025-031 through TC-FN-SEC-025-040.
- T-13 print-batch series is separately specified in the QA catalogue.
- Every listed case remains PLANNED / NOT EXECUTED. No test execution is claimed by this document.

## 14. Gate and verification disposition

| Item | Current status | Evidence boundary |
|---|---|---|
| CMD-031–040 detailed review | DOCUMENTED — PROPOSAL | Static review of canonical repository documents |
| Request/response proposals | DOCUMENTED — PROPOSAL | Not approved OpenAPI/JSON Schema |
| Permission/scope/SoD | PARTIAL — REVIEW REQUIRED | Permission registry and institutional authority remain draft/open |
| Physical read/write sets | DOCUMENTED WITH GAPS | Static physical schema; missing entities/columns identified |
| Transactions/locks/idempotency | DOCUMENTED — PROPOSAL | Not implemented or runtime-tested |
| Audit mapping | PARTIAL — REVIEW REQUIRED | T-15 direction PO-approved; event/retention details remain open |
| Route/RPC mapping | CANDIDATE ONLY | No route/function inventory verified |
| Supabase function owner/EXECUTE ACL | NOT VERIFIED | No live database access or catalog query performed |
| RLS and Storage policy | NOT VERIFIED | No deployed policy inspection performed |
| Tests | PLANNED / NOT EXECUTED | No unit, integration, security, concurrency or UAT test run |
| G9 | NOT READY | DGA-001 blockers and contract/design gaps remain |
| G10 | NOT ACTIVE | Conditional Product Owner authorization received; G9 is NOT READY and the separate G10 activation record is not approved |
| Source code / SQL / migration / grants | NOT PERFORMED | Outside permitted scope |
| Live database / deployment / merge | NOT PERFORMED | Outside permitted scope |

## 15. Next work

1. Continue CMD-041–048 read contracts and identify which are blocked or require institutional authority.
2. Do not begin CMD-045–048 implementation or assume authority; their existing catalogue blockers remain binding.
3. After CMD-041–048, review CMD-049–054 notification extensions separately against NLA-001 and worker security decisions.
4. Perform a cross-command reconciliation of CMD-001–054 against physical schema, permission registry, RLS catalogue, audit catalogue, route/API mapping, test catalogue, RTM, DGA and RAID.
5. Close PO/security/institutional decisions before treating any contract as approved.
6. Re-run G9 documentation readiness only when closure evidence exists. G10 remains a separate explicit authorization.

**Final boundary:** This review changes documentation only. No source code, SQL, migration, grant/revoke, RLS, Storage policy, live database, deployment, CI execution or merge was performed.

## CMD-032 draft-context lifecycle cross-check — 2026-11-24

[INSPECTION-DRAFT-001](INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md) v0.1.0 proposes that CMD-032 create one new ACTIVE draft context seeded from the exact approved immutable revision. The approved revision, its review decision, evidence, generated documents, print history and audit history remain unchanged. The new context is not editable until a valid Inspector claim/assignment path exists.

The candidate also requires CMD-032 to serialize against the inspection aggregate and conflicting active claims/finalizers, without silently transferring or releasing claims or selecting a next Inspector. Next-action ownership, claim resume/reassignment, evidence carry-forward and the canonical REOPENED state label remain OPEN.

This is documentation-only candidate design. The proposal does not approve the role/grant matrix, physical schema, DDL, RLS, ACL, command implementation, runtime tests or lock certification. CMD-032 remains NOT CERTIFIED; G9 NOT READY; G10 NOT ACTIVE.


## SES-001 session-bound correction and reopen guardrail — 2026-11-24

PO decision SES-001 is APPROVED. CMD-030 return does not authorize cross-session correction: only the exact original revision author/Inspector may correct, and only within the inspection attempt's originating active session. CMD-032 approved reopen is likewise constrained to that same originating session while it remains active; if the session is already finally closed, CMD-032 must fail closed and must not create a new draft context under the old inspection attempt. A later session must create a new inspection attempt instead.

ABORT is not a general cleanup path for incomplete or hanging work. It is eligible only after a Reviewer has returned the exact submitted revision for an identified error and the physical unit is already packed/boxed and prepared for shipment such that correction/reinspection is impracticable. The responsible Inspector must submit an ABORT request with a reason; Admin/Korlap must explicitly approve or reject it. Only an approved request may transition the attempt to terminal ABORTED. If the unit remains practically accessible, the same Inspector must correct and resubmit through WF-001 in the original active session. An incomplete/hanging attempt without the qualifying Reviewer-returned packed-unit facts remains unresolved and blocks FINAL_CLOSE.

ABORTED preserves the submitted revision, Reviewer return decision, evidence and audit history; it is not approval, inspection completion, a good/defective classification or print completion. A later session must create a new inspection attempt with a distinct inspection_id. CMD-013 cannot initiate, approve or bulk-apply ABORT and cannot use it to bypass unrelated closure gates. These constraints do not resolve the CMD-032 explicit authority, claim, finalizer, lock graph, RLS/ACL or physical schema blockers. No implementation or schema admission is implied.
