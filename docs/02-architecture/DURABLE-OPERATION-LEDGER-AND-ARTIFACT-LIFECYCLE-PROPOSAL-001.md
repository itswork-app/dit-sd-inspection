# Durable Operation Ledgers and Artifact Lifecycle — CMD-035/036/038/039/040

**Document ID:** DURABLE-OPERATION-LEDGER-PROPOSAL-001  
**Version:** 0.1.1  
**Date:** 2026-11-26  
**Status:** Engineering / Database / Security / Product review proposal — NOT APPROVED FOR IMPLEMENTATION  
**Scope:** Offline sync operation outcomes, document generation jobs, print batch manifests/results, attendance document versions and verification history  
**Gate:** G9-F1 FROZEN; G10-F1 ACTIVE for bounded foundation only; full-system G9 NOT READY; CMD-035/036/038/039/040 business mutations and workers remain feature-gated.

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

