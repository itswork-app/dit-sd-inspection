# Durable Operation Ledgers and Artifact Lifecycle — CMD-035/036/038/039/040

**Document ID:** DURABLE-OPERATION-LEDGER-PROPOSAL-001  
**Version:** 0.2.0  
**Date:** 2026-11-27  
**Status:** Engineering / Database / Security / Product review proposal — NOT APPROVED FOR IMPLEMENTATION  
**Scope:** Offline sync operation outcomes, document generation jobs, print batch manifests/results, attendance document versions and verification history  
**Gate:** G9-F1 FROZEN; G10-F1 ACTIVE for bounded foundation only; full-system G9 NOT READY; CMD-035/036/038/039/040 business mutations and workers remain feature-gated.

**Current gate interpretation (2026-11-26):** Historical G10 NOT ACTIVE labels in the dated body are snapshots from before staged foundation activation. G10-F1 does not authorize these business mutations, candidate schema objects, workers or provider operations.

## 1. Purpose and boundary

This proposal addresses physical objects missing from the current Package L catalogue for CMD-035, CMD-036, CMD-038, CMD-039 and CMD-040. It provides candidate data boundaries, uniqueness/idempotency rules, lifecycle invariants and RLS/worker posture for review.

It does not add any candidate table to the canonical physical schema or RLS inventory. Candidate names and fields below are not approved DDL. No SQL, migration, source code, provider, Storage or live database operation is authorized.

## 2. CMD-035 — durable offline sync operation ledger

### 2.1 Problem

A `sync_batches` envelope alone cannot reconstruct partial operation application, preserve a lost-acknowledgement result, distinguish same-operation replay from operation-ID reuse with different content, or provide a stable result for every operation in a batch.

### 2.2 Candidate relational model

**Candidate object A: `sync_batch_operations`**

| Candidate field | Purpose |
|---|---|
| `id` | Server-generated primary key |
| `sync_batch_id` | FK to `sync_batches` |
| `operation_id` | Client-generated stable operation identity within the batch |
| `operation_index` | Original order in submitted manifest |
| `inspection_id` | Target inspection reference |
| `operation_type` | Strict allowlisted operation kind |
| `semantic_hash` | Server-canonical hash of normalized operation payload |
| `expected_row_version` | Client's expected inspection aggregate version |
| `status` | RECEIVED / APPLIED / CONFLICTED / REJECTED |
| `result_code` | Typed, stable outcome code |
| `resulting_row_version` | Version after successful application, if applied |
| `result_reference` | Minimal typed reference to durable domain result |
| `received_at`, `completed_at` | Server timestamps |

Candidate constraints:
- Unique `(sync_batch_id, operation_id)`.
- Unique `(sync_batch_id, operation_index)`.
- FK to the batch and target inspection; exact project/assignment scope must be validated from persisted rows.
- `semantic_hash` is computed server-side from canonicalized allowlisted fields; never trust a client-provided hash as the canonical value.
- Once terminal, operation result identity and semantic hash are immutable. A retry with same ID/hash returns the stored outcome; same ID/different hash returns IDEMPOTENCY_KEY_REUSED.
- Every submitted operation receives a durable result, including rejected/conflicted operations. Do not discard invalid operations from the manifest.
- Operation payloads should not be copied into long-lived result rows unless required; preserve only minimized data and a safe result reference.

**Candidate object B: device binding registry**

A separate device-binding object is required because the current model has no durable device enrollment, ownership, public-key binding, revocation or trust state. Candidate fields include user identity, opaque device ID, public-key fingerprint or attestation reference, status, enrolled/revoked timestamps and audit references. Never store device private keys. Exact platform attestation and recovery policy remains a Security/Operations decision.

### 2.3 Transaction and replay model

1. Accept the bounded batch envelope and persist the full ordered operation manifest, operation IDs and server-canonical semantic hashes in one short acceptance transaction. Acceptance does not mutate inspection drafts.
2. Process each operation in its own short PostgreSQL transaction. Each operation targets exactly one inspection; no transaction holds inspection locks across multiple operations or across the batch.
3. In that operation transaction, arbitrate/lock the operation identity, reauthorize the user and bound device, validate current claim/assignment/scope, acquire the target inspection aggregate, and compare the expected row version.
4. Apply only permitted draft response mutations; increment the inspection row version exactly once for a semantic mutation.
5. Atomically persist the APPLIED result, corresponding domain/audit events and idempotency outcome with the operation mutation. For a business conflict/rejection, persist a terminal CONFLICTED/REJECTED result without a domain mutation in that same operation transaction.
6. An unexpected infrastructure failure rolls back only the current operation transaction and leaves its ledger entry non-terminal/retryable. Previously committed operation outcomes remain durable. Batch state is derived from the operation ledger; a lost acknowledgement is recovered by replaying the same batch and operation IDs.
7. A savepoint may be used inside one operation transaction for local error handling, but it is not an alternative batch-level commit model and does not provide independently durable operation outcomes. Duplicate operation ID with a different semantic hash is rejected without applying a second effect.

CMD-035 remains restricted to previously claimed draft work. No offline claim, submit, review, approval, print, attendance verification or administrative mutation is introduced by this proposal.

## 3. CMD-036 — document generation source, template and worker lifecycle

### 3.1 Problem

The current `documents` proposal is inspection-revision-centric, while the command catalogue also permits approved attendance/document source types. A generic renderer job, immutable template identity and recoverable worker lifecycle are not specified. The notification outbox is not a document-rendering queue and must not be reused.

### 3.2 Candidate object boundaries

**Candidate object A: immutable template version registry**

A candidate `document_template_versions` object should identify:
- document type and immutable version key;
- canonical template content hash and approved asset references;
- source schema/version compatibility;
- renderer compatibility/version constraints;
- status and publication/approval actor/time;
- immutable publication record.

No arbitrary user-uploaded executable templates, scripts, macros, HTML or renderer code. Only reviewed declarative templates and allowlisted assets may be published.

**Candidate object B: generic document generation job**

A candidate `document_generation_jobs` object should include:
- stable generation key and request hash;
- document ID or reserved artifact identity;
- source type and exact immutable source-version reference;
- template-version reference and template hash;
- status QUEUED / PROCESSING / RETRY_WAIT / COMPLETED / FAILED / CANCELLED;
- attempt count, next-attempt time, safe error code;
- lease owner, token hash, monotonic generation and expiry;
- created/updated/completed timestamps and worker correlation ID.

**Candidate object C: append-only generation attempts**

A candidate `document_generation_attempts` object should preserve attempt number, job ID, worker correlation, start/finish time, outcome, sanitized error code and output hash/reference when successful. It must not store secrets, access tokens, signed URLs, full renderer responses or source document bodies.

### 3.3 Source identity and immutable artifact provenance

Avoid an unconstrained polymorphic source ID with no FK. Engineering/Database should select one of:
- typed nullable source FK columns with a CHECK enforcing exactly one permitted source; or
- a normalized source-reference relation with explicit per-source FK tables and a canonical source version/hash.

At minimum, generated output must bind to an exact approved source version/hash and exact template version/hash. If the source changes, the prior artifact remains immutable and a new generation identity is required. The output object key and output hash are finalized only after the renderer output is independently validated and stored in private Storage.

### 3.4 Worker protocol

- Claim jobs in a short transaction using bounded queue selection and a lease-fencing tuple.
- Render outside database transactions and without holding database locks.
- Finalize only if lease owner, token hash, generation and expiry still match.
- A stale worker cannot overwrite or finalize a newer attempt.
- Retries are bounded and idempotent by generation key; uncertain renderer completion is reconciled by checking the immutable artifact identity/hash before retry.
- Worker identity and EXECUTE/table ACL are separate Security decisions; browser roles receive no queue access.
- CMD-036 acceptance, generated, failed and retry outcomes must be auditable without exposing document content or secrets.

### 3.5 Canonical generation identity and idempotency

The request idempotency key and the generation identity solve different problems and must not be conflated.

- **Request idempotency** identifies one caller command submission. Its scope is the authenticated actor, command, and caller-supplied idempotency key. The server computes a canonical semantic request hash. Reuse with the same hash returns the prior accepted/result reference after current read authorization; reuse with a different hash returns `IDEMPOTENCY_KEY_REUSED`.
- **Generation identity** identifies the artifact that should exist for a specific immutable input tuple. Candidate canonical tuple: document type + typed source identity + exact immutable source version/hash + template identity/version/hash + renderer profile/version + explicitly versioned output options that can change bytes (for example locale or page profile, if supported). The server computes the stable generation key from this normalized tuple.
- A uniqueness arbiter must prevent concurrent requests from creating two active or completed artifact identities for the same generation tuple. A second authorized request for the same tuple resolves to the existing job/document identity rather than creating a duplicate render.
- Actor identity is an authorization/audit attribute, not part of the artifact's content identity. It must not let two authorized actors create duplicate copies merely by changing caller identity.
- A deliberate new render after a renderer/template correction must have a materially different, immutable renderer/template version in the tuple. Do not add an opaque client nonce to bypass deduplication. If a business correction requires a second artifact for the same source/template tuple, the allowed supersession/reissue semantics require explicit Product Owner approval and a distinct versioned reason/identity.
- The canonical hash excludes transport-only fields, timestamps, caller-supplied output metadata and fields that cannot change rendered bytes.

The exact unique key, idempotency retention horizon and reissue semantics remain Engineering/Database/Product decisions; this is a candidate identity model, not an approved uniqueness constraint.

### 3.6 Job state, lease and fencing protocol

The following is a candidate transition model; exact enum names and retry limits remain open:

`QUEUED → PROCESSING → COMPLETED`, with `PROCESSING → RETRY_WAIT → PROCESSING` for retryable failures and terminal `FAILED` or `CANCELLED` only through controlled transitions. A terminal attempt record is append-only; a job projection may change only through a compare-and-swap transition.

- Claim is a short database transaction. It selects eligible queued/retry-due work, increments a monotonic lease generation/fencing counter, assigns a server-issued opaque lease token (persist only a hash where feasible), sets lease expiry and records the attempt start. Claim commits before rendering begins.
- A worker heartbeat may extend the lease only when job ID, lease owner, token hash, generation and current unexpired lease all match. Heartbeat is a compare-and-swap update; it cannot revive an expired or superseded lease.
- Reclaim after expiry increments the fencing generation. The previous worker is permanently stale even if it later completes rendering.
- The worker identity is a distinct non-human workload identity. It is not `document.generate`, `authenticated`, `service_role` or a browser session. Its exact authentication, function/table privileges, Storage access, network egress and secret custody require Security/Operations approval.
- Claim, heartbeat, retry scheduling and finalization each use bounded transactions. No source/document/job row lock is held during renderer or Storage I/O.
- A worker may render more than once under at-least-once delivery. The invariant is one accepted immutable artifact identity and one valid finalization, not exactly-once execution of the external renderer.

Lease duration, heartbeat interval, maximum attempts, backoff schedule, dead-letter policy, queue fairness and worker concurrency are deliberately unset pending workload/provider/SLO evidence.

### 3.7 Rendering, object storage and guarded finalization

1. The worker loads only the server-pinned immutable source snapshot/reference and immutable template version/hash. It must not re-resolve a mutable "latest" template or accept client-supplied source content at render time.
2. It renders outside PostgreSQL transactions. Renderer input is bounded and schema-validated; template content is declarative and reviewed. Executable macros/scripts, arbitrary remote includes and unbounded network fetches are prohibited.
3. The worker writes to a server-generated private Storage object identity using create-if-absent/immutable semantics where supported. It computes or independently verifies the output checksum and obtains server-observed object metadata. A retry must reconcile an existing object by exact generation identity and checksum; it must never overwrite an existing finalized object.
4. Finalization runs in a short transaction and checks the current lease fencing tuple, expected job state/version, exact document/generation identity, pinned source version/hash, pinned template version/hash and server-observed output object identity/checksum/size/MIME. It appends the generation attempt outcome, updates the document/job terminal projection, appends the required audit event and records the durable result atomically.
5. If the lease is expired/reclaimed, the source binding no longer matches, or object metadata does not match, finalization fails closed. The artifact is not exposed as GENERATED. Any orphan private object is reconciled by a separate idempotent process; no immediate delete is inferred.
6. A failed audit append rolls back the relational finalization. The external object may remain as an orphan for reconciliation, but no successful document pointer/status may commit without its required audit event.

**Source-reopen race remains a Product Owner decision.** CMD-032 requires preserving an already approved immutable revision and its historical PDF/print history, but current documentation does not settle what to do when a generation job was accepted before reopen and finishes after the inspection is reopened. Two possible policies have different user-visible outcomes: (A) permit finalization as a historical artifact bound to the still-approved immutable revision, or (B) mark the job stale/cancelled and require a separately authorized request. Do not infer either. Until this edge is decided, finalization must not silently rebind to a new draft/current revision; the race remains blocked and must fail closed or remain pending for controlled resolution.

### 3.8 Retry, cancellation and uncertain outcomes

- Classify failures as retryable infrastructure/provider failure, deterministic render/input failure, authorization/source invalidation, lease loss, object-integrity mismatch or audit failure. The taxonomy and retryability are server-owned.
- Retry only when the prior attempt is known not to have finalized. If renderer/Storage completion is uncertain, first reconcile by generation identity, object key and checksum. Never blindly create a new artifact or overwrite the previous object.
- A retry creates a new append-only attempt number and fencing generation; it does not erase prior attempt evidence.
- Terminal failure is reached only after the approved bounded retry policy or a non-retryable condition. Dead-letter/reconciliation is explicit and observable.
- Cancellation, if exposed, is a separately authorized command/policy. A client disconnect, browser timeout, lease expiry or source update is not itself proof that an external render stopped.
- Access to a generated artifact is a separate scoped read decision. The generation response must not return a durable public URL or reusable signed URL.

### 3.9 Required observability and acceptance evidence

The worker and command should emit privacy-safe correlation fields: generation key/reference, job ID, attempt number, fencing generation, state transition, source version ID/hash, template version/hash, renderer version, duration, safe error code and output checksum. Never log source content, PDF bytes, JWTs, lease tokens, signed URLs, credentials or personal evidence payloads.

Minimum test scenarios (all PLANNED / NOT EXECUTED):
- concurrent same-tuple requests resolve to one generation identity and one durable job;
- same caller idempotency key/same semantic request replays; changed semantic request is rejected;
- template publication/revocation or renderer-version change cannot mutate a pinned in-flight request;
- worker crash before render, during render, after Storage write and before finalization;
- lease expiry/reclaim while old worker is still running; stale worker cannot finalize;
- heartbeat racing with reclaim; only the current fencing generation remains valid;
- duplicate renderer execution and uncertain Storage response reconcile without overwriting;
- source revision/reopen race follows the explicit PO decision and never rebinds to a newer draft;
- checksum, MIME, size, private bucket and object-key mismatch fail closed;
- audit failure prevents GENERATED state; orphan object is discoverable and reconciled;
- authorization revocation before enqueue/finalization is enforced at the defined boundary;
- no browser identity can claim, heartbeat, retry, finalize or read the worker queue.

These cases require exact physical schema, function/worker ACL, Storage policy, event cardinality and concurrency harness approval before execution. No test result is claimed.

## 4. CMD-038 — durable print batch manifest and item outcomes

### 4.1 Problem

`print_batches.requested_count` and `print_events` do not preserve every requested item, especially invalid/unresolvable documents, after a lost acknowledgement. A batch cannot be reliably reconstructed from a count and only successful/resolvable print events.

### 4.2 Candidate object boundaries

**Candidate object A: `print_batch_items` — immutable request manifest**

Candidate fields:
- server ID, batch FK, stable client `item_key`, original request position;
- requested document ID/version reference (may be unresolved at acceptance);
- resolved document FK when resolution succeeds;
- request item hash;
- initial resolution state and server timestamp.

Candidate constraints:
- Unique `(batch_id, item_key)`.
- Unique `(batch_id, request_position)`.
- Item manifest becomes immutable after batch acceptance.
- Batch count and configured upper bound must equal the number of persisted manifest items; do not accept a count-only batch.

**Candidate object B: `print_batch_item_results` — append-only outcomes**

Candidate fields:
- batch item FK, attempt number, result status, safe failure code;
- resolved document/version reference where available;
- print-event reference where a print attempt is recorded;
- started/completed timestamps and idempotency reference.

Candidate constraints:
- Unique `(batch_item_id, attempt_no)`.
- Every retry creates a new result/attempt; prior failure is never overwritten.
- Invalid/unresolvable items receive durable rejection outcomes even when no `print_events` row can be created.
- Batch aggregate status is a projection of persisted item outcomes, not caller input.

Existing `print_events` remains the append-only per-document print-attempt record and must retain its sequence/attempt uniqueness. The final design must avoid double-counting one physical application print attempt between item results and print events; choose one authoritative attempt identity and cross-reference the other record.

### 4.3 Transaction and retry model

- Accept the bounded batch and persist the immutable item manifest atomically with the batch envelope.
- Resolve each item independently under actor scope and immutable document-version checks.
- Process each item with its own idempotency identity and per-document sequence arbiter.
- `retry_failed_only` selects only items whose latest terminal result is retryable failure under the approved failure taxonomy; it never replays successful items.
- A lost acknowledgement returns the same batch/item result set for the same idempotency key.
- The system records an application print signal only; it must not claim physical printer completion.

## 5. CMD-039/040 — attendance document versions and verification history

### 5.1 Scope authority gap

Current `attendance_records` lists project and session but no location or assignment authority, while upload and verification are location-scoped. The authoritative relationship proving which Korlap/location owns an attendance record must come from persisted assignment/scope relations, not client-supplied location IDs.

Engineering and the institution must decide whether attendance is scoped by:
- a direct immutable `location_id` on the attendance record, validated against project/session; or
- a unique assignment reference whose persisted location and effective Korlap membership provide the authority.

Do not implement either choice until the institutional authority model is approved.

### 5.2 Attendance document version candidate

A finalized `attendance_documents` row should identify an immutable version:
- attendance record FK and monotonically allocated version number;
- private Storage object key, SHA-256, MIME type and byte size;
- uploader identity and upload/finalization timestamps;
- replacement reason and predecessor document reference where applicable;
- verification status projection only if explicitly defined.

Candidate uniqueness: `(attendance_record_id, version_no)`; object key unique; finalized object identity/checksum immutable. Upload intent expiry, quota reservation and object verification metadata need a defined lifecycle. Engineering should choose whether to reuse the approved generic evidence upload-intent mechanism or define a narrowly scoped attendance upload-intent object; do not silently reuse `evidence_assets` if its parent/authorization semantics do not fit attendance.

### 5.3 Append-only verification history candidate

**Candidate object: `attendance_verification_events`**

Candidate fields:
- attendance record FK;
- exact attendance document/version FK and checksum snapshot;
- verifier account ID;
- decision VERIFIED / REJECTED (or approved institutional vocabulary);
- reason and decision timestamp;
- assignment/location authority reference used at decision time;
- verification round/sequence and idempotency reference;
- optional supersedes/reverification reference only if institutional policy authorizes re-verification.

Candidate invariants:
- Append-only; no update/delete by application roles.
- A decision binds to one exact immutable document version and checksum.
- The attendance record's current status is a projection of the latest valid verification event, not the sole source of history.
- Concurrent verify/reject commands serialize on the attendance record and enforce one terminal decision per version/round under the approved lifecycle.
- Replacing a document does not rewrite prior verification history; a new version requires a new verification decision.
- Uploader/verifier separation-of-duties remains unresolved pending institutional authority; do not assume same-person or different-person behavior.
- Retention, legal hold, classification and audit export remain subject to T-10 external approval.

## 6. Cross-cutting security and RLS posture

Candidate objects must be added to the Package L and Package M catalogues before implementation. Proposed access posture:

| Candidate object family | Browser access | Trusted mutation boundary |
|---|---|---|
| Sync operation ledger | Own batch/result only if a narrowly scoped read is approved; never expose raw device proof | CMD-035 only; device binding/worker/admin paths separately reviewed |
| Device registry | Self-owned minimal status read only if approved; no private key material | Explicit enrollment/revocation command and trusted identity/device control |
| Template versions | Published approved template metadata only within permitted scope | Privileged template publication workflow; no arbitrary template upload |
| Document jobs/attempts | No browser queue access; document result only through authorized artifact access | Internal renderer worker with least-privilege ACL and lease fencing |
| Print batch items/results | Actor/scope-limited batch result read | CMD-038 and controlled per-item worker/command path |
| Attendance verification events | R-scope only for authorized attendance roles; no global reader inferred | CMD-040 append-only trusted command |

Every candidate object requires:
- explicit PK/FK/check/unique/index design;
- exact RLS predicates and direct-DML denial;
- trusted function EXECUTE grants and worker identity where relevant;
- audit/idempotency atomicity;
- privacy-minimized payloads and bounded retention after T-10;
- threat-model and concurrency tests.

## 7. Decisions required before canonical schema admission

| Decision | Required owner/evidence |
|---|---|
| Approve sync operation ledger, batch partial-commit model and device enrollment/revocation authority | Product + Engineering + Security + Database |
| Approve immutable template registry, supported document source types and renderer job/lease model | Product + Engineering + Security + Operations |
| Approve print batch item manifest and authoritative per-item attempt/result identity | Product + Engineering + Database |
| Approve attendance scope authority (location vs assignment), upload lifecycle and version model | Institution + Product + Engineering + Security |
| Approve attendance verification vocabulary, terminal/reverification rules and uploader/verifier SoD | Institution + Product + Security |
| Approve exact RLS/ACL/worker identities and retention classification | Security + Database + Operations + institutional T-10 authority |

## 8. Gate disposition

- CMD-035/036/038/039/040 physicalization: **CANDIDATE DESIGNS DOCUMENTED; REVIEW OPEN**.
- Canonical physical schema admission: **NOT APPROVED**.
- RLS/ACL/worker identity: **NOT APPROVED / NOT VERIFIED**.
- Concurrency, replay, lease-fencing and race evidence: **NOT EXECUTED**.
- G9: **NOT READY**.
- G10: **NOT ACTIVE**.

### 4.4 CMD-038 lifecycle reconciliation — 2026-11-27

**Status:** candidate engineering contract only; no Product Owner approval of remaining policy values and no schema admission. This subsection refines §§4.2–4.3; it does not change the candidate-only status of either object.

#### Durable acceptance and immutable manifest

1. Batch submission is one short acceptance transaction. It authenticates the caller, validates the batch-level permission and request envelope, arbitrates actor + command + idempotency key against a server-computed canonical request hash, creates the batch envelope, persists every ordered manifest item, and commits the stored acceptance result atomically.
2. Same key + same canonical hash replays the same batch identity and accepted manifest. Same key + different hash returns IDEMPOTENCY_KEY_REUSED; it must not create or mutate a batch.
3. The server derives requested_count from the persisted manifest. It is not accepted from the caller. Client-supplied count, status, result, success assertion, sequence, actor identity and retry eligibility are forbidden.
4. The accepted manifest is immutable: stable item_key, request position, original document/version request, and canonical item hash are retained even when the document cannot be resolved or authorized. A stable key is unique within a batch; request position is unique within a batch. Duplicate item keys or duplicate canonical item identity are rejected according to an explicit normalization rule; the normalization rule remains an engineering decision.
5. The maximum item count, request-byte limit, per-actor rate limit, acceptance expiry and retention are not assigned here. The configured maximum must be evidence-based and approved before implementation; do not substitute an arbitrary number or an unbounded array.

#### Item outcome authority and attempt identity

- print_batch_items is the durable identity of each requested item; print_batch_item_results is the append-only history of processing attempts/outcomes. The latest eligible terminal result is a projection input, not a mutable overwrite.
- A result attempt is identified by (batch_item_id, attempt_no) as a candidate uniqueness rule. attempt_no is an item-processing attempt ordinal only; it is not print_events.attempt_no, not sequence_no, and not a reprint count.
- print_events remains the authoritative per-document application print/reprint event stream. A result that records a successful application print action references exactly one committed print_event; one print_event may be referenced by at most one authoritative item result. A rejected/failed item with no recorded application print action has no successful print event. Whether failed print_events rows are retained for resolvable documents, and exact audit event cardinality for rejected items, remain open (C38-03).
- An item result is never rewritten from failed to successful. A later retry appends a new attempt/result. A successful result is terminal for that batch item and cannot be selected by a failed-only retry.

#### Processing and transaction boundaries

1. Batch acceptance and item processing are separate transactions. Acceptance does not claim that any item has printed.
2. Each item is authorized and processed in its own short database transaction. Revalidate the current caller authority and exact document/version/scope at the item boundary; enqueue-time permission is not a permanent authorization grant.
3. One item transaction locks at most one document aggregate/version and its sequence allocator. It must not hold a batch-wide lock or multiple document locks while processing items. CMD-037 candidate sequence increment, print_event, required audit fact and idempotency outcome commit atomically; audit failure rolls back that item's sequence/event/idempotency mutation.
4. Persist the item result and its idempotency linkage in the same transaction as the item outcome. A committed success followed by a lost acknowledgement is recovered by replaying the same batch/item identity and returns the same event/sequence; it does not allocate another sequence.
5. A process crash before item commit leaves that item uncommitted/retryable and cannot roll back prior committed items. A crash after commit but before response is resolved by reading/replaying the committed item result. No transaction or database lock spans browser rendering, PDF delivery, or physical printer I/O.
6. Batch aggregate status/counts are derived from the immutable manifest and durable item results. They are a projection only; they must never be accepted from the caller or used as a substitute for item-level evidence. The projection update/reconciliation path must be idempotent and must not overwrite item history.

#### Failed-only retry and partial recovery

- A retry request identifies the prior batch and requests failed-only retry. The server derives the eligible subset from the source batch's durable results; the caller cannot submit a list of items claimed to have failed.
- The retry creates a new batch envelope with a new batch idempotency key and a new immutable manifest containing only eligible failed items, retaining source batch/item references. Original batches, manifests and results remain unchanged.
- Previously successful items are excluded server-side even if the caller includes their item keys or asserts that they failed. A batch with no eligible failed items returns a stable no-op/rejection outcome and creates no print event; exact response code remains open.
- A retryable failure classification must be explicit and deterministic. Authorization denial, invalid/non-printable document, stale version, scope mismatch, audit failure and transient infrastructure failure must not be collapsed into one generic retryable state. Retry limits, backoff, expiry, cancellation and manual requeue policy remain OPEN.
- If two retry batches race from the same partial batch, per-document sequence/idempotency arbitration prevents duplicate successful print events. Whether the product permits overlapping retry batches or serializes them at batch/item eligibility level remains C38-04.
- A batch may remain incomplete while item results are pending. Exact PROCESSING/PARTIAL/SUCCEEDED/REJECTED terminal transition rules and stale-batch recovery authority require approval; do not infer a lease or worker principal. A worker/lease is not authorized by this proposal.

#### Privacy, access and retention

The accepted manifest and item results contain document identifiers, version references, safe error codes and actor/batch references only as needed for reconciliation. They must not duplicate PDF bytes, evidence, raw request bodies, tokens, or unrestricted Storage object keys. Batch-result reads require actor- and resource-scope authorization; candidate tables receive no browser DML and no broad worker/table access. Retention, expiry and legal-hold disposition remain governed by T-10 and are not set here.

#### Open blockers

- C38-01: candidate manifest/result objects, exact PK/FK/index/check constraints, canonical item hash and identity normalization, and admission to the physical schema/RLS/ERD.
- C38-02: batch/item worker or synchronous orchestration model, lease/fencing (if any), recovery ownership, and whether concurrent/overlapping retry batches are permitted.
- C38-03: authoritative attempt identity across item results, print_events.attempt_no, CMD-037 sequence_no, and audit event cardinality for failed/rejected items.
- C38-04: PO decision on mixed-scope batches (reject vs partition), retry limits/expiry/cancellation, empty failed-only retry, and exact terminal batch-state semantics.
- C38-05: approved numeric maximum batch size, request/rate/processing bounds and retention; no numeric values are inferred.
- C37-01..04 remain independent CMD-037 blockers and continue to constrain CMD-038.

No candidate table, function, worker, permission, RLS policy, grant, route, migration, SQL or runtime behavior is approved by this addendum.
