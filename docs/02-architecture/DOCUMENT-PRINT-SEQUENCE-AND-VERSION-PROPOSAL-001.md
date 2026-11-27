# Document Print Sequence and Version Identity — CMD-037

**Document ID:** PRINT-SEQUENCE-PROPOSAL-001  
**Version:** 0.1.1  
**Date:** 2026-11-27  
**Status:** Engineering / Database / Security review proposal — NOT APPROVED FOR IMPLEMENTATION  
**Authority:** PO-approved T-13 option B; DOC-002; CMD-037 contract review  
**Scope:** Individual print/reprint event identity, per-document sequence allocation, idempotency and audit atomicity  
**Gate:** G9-F1 FROZEN; G10-F1 ACTIVE for bounded foundation only; CMD-037 remains feature-gated.

## 1. Product semantics that are already decided

T-13 option B is PO APPROVED: individual printing and bounded batch printing are both in the initial product direction. Each document receives its own outcome; batch printing is not an all-or-nothing transaction. Failed documents alone may be retried, and successful print events must not be duplicated by a retry. Direct printer integration is not selected.

DOC-002 is PO APPROVED: per-unit completion follows approval, final PDF generation and a Print Officer print action being recorded. A reprint increments the count.

The recorded event is an application-level print action only. It is not evidence that a physical printer produced paper, all pages were printed, or a wet signature was applied. No response, audit event, report or UI may claim physical-print confirmation.

This proposal does not change those PO decisions. It supplies a candidate engineering/data protocol only.

## 2. Identity and event semantics

### 2.1 Immutable printable version

A print command must resolve one exact, server-issued immutable PDF version. The caller cannot choose or forge output hash, object key, status, actor, timestamp, sequence or attempt number.

The current physical catalogue has a `documents.id` and immutable-artifact fields, but does not define whether `documents` is a logical document with child versions or whether each row itself is one immutable generated version. CMD-037 currently asks for both `document_id` and `document_version`. These representations are not interchangeable.

**Required before admission:** Database/Engineering must choose and document one canonical identity model:
- logical `document_id` plus a separate immutable `document_version_id` FK; or
- one `documents.id` per immutable printable artifact, in which case a separate caller-supplied `document_version` is redundant and should be removed from the contract.

Do not treat a mutable version number or “latest” pointer as proof of the exact artifact. A print event must permanently identify the exact immutable output hash/version it refers to. C37-01 remains OPEN until this crosswalk is resolved against CMD-036 and the ERD.

### 2.2 Sequence and reprint semantics

Candidate canonical semantics:
- `sequence_no` is the monotonically increasing, per-logical-document ordinal of successfully recorded application print actions.
- First recorded action receives sequence 1 and audit action `document.printed`; subsequent distinct print actions receive 2, 3, … and `document.reprinted`.
- A retry/replay of the same idempotent command returns the original event and sequence; it does not consume a new sequence.
- A new intentional reprint uses a new idempotency key and appends one new event with the next sequence.
- Validation, authorization, stale-sequence or other rejected commands do not consume a sequence and do not create a successful `print_events` row.
- Sequence allocation is per logical document, not per browser, batch or actor. If a version model is introduced, each event also binds the exact immutable version printed while the sequence remains monotonic across that logical document's versions.

The current `print_events.attempt_no` field is not defined consistently with `sequence_no` and the CMD-038 item retry model. It must not become a second independently incremented reprint counter. Database/Engineering must either remove it from the individual print-event model or define its distinct meaning and uniqueness rules. CMD-038 retry-attempt numbering belongs to the durable per-item result model; it must not create a duplicate successful print event.

### 2.3 Idempotency identity

Use the existing idempotency record uniqueness model: authenticated actor + command type + exact document scope + idempotency key. Compute a server-canonical request hash from the document/version identity, expected sequence (when supplied) and allowlisted client signal.

- Same actor/scope/key + same hash returns the stored event/result after current read/print authorization is rechecked.
- Same actor/scope/key + different hash returns `IDEMPOTENCY_KEY_REUSED`; it must not allocate a sequence.
- Two concurrent submissions with the same key converge on one result.
- A new key is required for an intentional reprint.
- Idempotency retention must cover the supported retry horizon; the exact duration remains a separate platform/operations decision.

Actor identity is derived from the authenticated server context. A client-supplied actor, timestamp, sequence or result is forbidden.

## 3. Candidate physical sequence allocator

The current schema proposes unique `(document_id, sequence_no)` and append-only `print_events`, but does not specify a concurrency-safe sequence allocator.

Candidate object: `document_print_counters` (NOT ADMITTED):
- `document_id`: PK and FK to the logical document aggregate;
- `last_sequence_no`: nonnegative integer, initially zero;
- `updated_at`: server timestamp.

Candidate invariants:
1. Exactly one counter exists per printable logical document before a successful print action can commit. It may be initialized with the document lifecycle or created idempotently on first print.
2. The counter is a mutable operational projection; the generated document/version and historical print events remain immutable.
3. Increment is performed atomically under a row lock or compare-and-swap update, returning the allocated sequence.
4. The counter increment, `print_events` insert, audit append and idempotency result commit in one PostgreSQL transaction.
5. Unique `(document_id, sequence_no)` on `print_events` remains a final integrity guard, not the primary allocator.
6. Any failure before commit, including audit append failure, rolls back the counter increment and event together. No sequence gaps are introduced by rejected commands or failed transactions.
7. Direct browser DML cannot update the counter or insert print events.

If Database chooses a different allocator, it must prove the same serialization and rollback invariants. Do not use `MAX(sequence_no)+1` without a proven serialization primitive; an ordinary read is not a concurrency-safe allocator.

## 4. CMD-037 transaction and lock boundary

Candidate transaction, all within one short PostgreSQL transaction:
1. Derive actor from caller JWT; establish command idempotency identity and canonical request hash. Replays must still pass current authorization before returning document-scoped information.
2. Lock and revalidate the logical document and exact immutable version. Require final/generated/printable state, matching output/version identity, and exact project/session/location scope.
3. Recheck active `document.print` permission and assignment/account eligibility at transaction time. Do not infer print authority from generic Admin or Super Admin role.
4. If `expected_sequence` is supplied, define it as the caller's expected current `last_sequence_no` (zero before first print). Compare before increment; mismatch returns `STALE_SEQUENCE` without consuming a sequence.
5. Lock/update the document's print counter and allocate `last_sequence_no + 1`.
6. Append one `print_events` row bound to the exact document version and allocated sequence. Derive `document.printed` versus `document.reprinted` from the allocated sequence, never from client input.
7. Append the required audit event and complete the idempotency result with the print event reference.
8. Commit. If audit, event, counter or idempotency persistence fails, the entire transaction rolls back.

Candidate lock order: command/idempotency arbitration → document aggregate/version → print counter → print event/audit append. Exact global ranks, row lock modes, FK/index/trigger edges and interaction with CMD-038 require Engineering/Database/Security review. The counter lock is per document; unrelated documents should not serialize on a global allocator.

The command records an application action; it does not wait for, call or attest a physical printer. Any browser download/open step remains separate from the authoritative event transaction and cannot be used as proof of paper output.

## 5. Authorization and historical-version boundary

- Only an active `document.print` grant in the exact authorized project/session/location scope may record the action.
- The exact immutable document version must be final and printable.
- **PO decision DOC-003 (2026-11-27):** an inspection-derived document can only be generated after its source session has started. Once a final immutable artifact has been generated from an eligible approved source, closing the source session does not revoke its print/reprint eligibility. The artifact becomes historical but remains printable; do not require session reopen or a currently ACTIVE session merely to print it. Current `document.print` permission, exact resource scope, artifact integrity and final immutable status are still mandatory.
- DOC-003 does not decide whether a superseded/replaced artifact version remains printable when a newer version exists. C37-02 remains OPEN only for that distinct version-supersession policy; do not conflate session closure with version supersession.
- Reauthorization is required on every new command and before disclosing an idempotent replay result.
- Print events and audit history are append-only; correction is a new controlled event, never mutation/deletion of the historical row.


### 5.1 Session-start and post-closure print rule — PO APPROVED DOC-003

- An inspection-derived document must not be generated before its source inspection session has started. The source must have a durable session-start/activation fact; a DRAFT session is ineligible. The command must reject a pre-start generation request rather than create a pending job or artifact.
- Once generated and finalized from the exact approved immutable inspection revision, the artifact remains a durable historical record. Transitioning the source session to CLOSED does not invalidate, hide, delete, regenerate or make that artifact unprintable.
- A Print Officer may print/reprint that exact finalized artifact after session closure, subject to current `document.print` permission, current actor/account eligibility, exact resource scope and artifact-integrity checks. Session closure is not itself a denial reason; no session reopen is required just to print.
- This rule does not authorize edits to the closed session or its inspection, and does not by itself approve new generation after closure. It does not decide whether superseded/replaced versions remain printable; that remains C37-02.

## 6. CMD-038 interaction

T-13 requires individual and bounded batch printing, per-document outcomes, failed-only retry and no duplicate successful event.

CMD-038 must invoke the same per-document authorization, version validation, idempotency and sequence-allocation boundary as CMD-037. The batch envelope is not a substitute for the per-document command contract.

- Persist the batch manifest before item processing.
- Each item is processed in its own short transaction and locks only one document/counter at a time.
- Do not hold multiple document/counter locks across the batch; this avoids overlapping-batch lock-order cycles.
- Each item has a stable key and durable attempt/result history. A retry targets failed items only.
- A successful item is immutable as a successful outcome and is never reissued as a new print event by batch retry.
- Batch status is a projection of item results; it is not a physical printer status.

The exact boundary between `print_batch_item_results` and `print_events`, and the semantics of the existing `attempt_no` column, remain Database/Engineering decisions. There must be one authoritative successful print-event identity per application print action.

## 7. Audit and reporting

Required successful event family:
- sequence 1: `document.printed`;
- sequence greater than 1: `document.reprinted`.

Audit metadata should bind the actor, scope, logical document, exact immutable version/output hash, sequence, idempotency/correlation reference, safe allowlisted application signal and server timestamp. Do not store PDF bytes, signed URLs, credentials or arbitrary client payloads.

T-05 completion reporting may count a document as completed only after approval, final PDF generation and a recorded Print Officer application action. It must not infer paper output or signature application. Reprints increment the print count but must not multiply the logical completed-document count.

The audit catalogue must confirm exact event names, metadata schema, retention and read visibility before certification; this proposal does not admit or deploy new audit privileges.

## 8. Required verification evidence — PLANNED / NOT EXECUTED

- first print allocates sequence 1 and emits `document.printed`;
- intentional reprint with a new key allocates sequence 2 and emits `document.reprinted`;
- same key/same hash replay returns the same event and sequence;
- same key/different hash rejects without sequence allocation;
- concurrent same-key submissions create exactly one event;
- concurrent distinct print actions for one document allocate unique contiguous sequences;
- prints for different documents do not contend on a global counter;
- stale `expected_sequence` rejects without consuming a sequence;
- wrong, pending, failed, non-final or out-of-scope document/version rejects;
- revoked permission/account/assignment is rechecked at command time;
- audit insert failure rolls back counter, event and idempotency result;
- direct browser DML cannot mutate counter or print events;
- overlapping CMD-038 batches processing shared documents cannot duplicate success or deadlock;
- batch retry reprocesses failed items only and never duplicates prior success;
- post-session-closure print remains allowed under DOC-003; superseded/replaced-version eligibility remains an explicit open decision.

Tests require an isolated synthetic-data database, deterministic barriers, declared transaction isolation, captured SQLSTATE/lock diagnostics and invariant snapshots. Existing TC-CMD-CONTRACT-024-037 and TC-FN-SEC-025-037 remain PLANNED / NOT EXECUTED.

## 9. Open decisions and admission blockers

| ID | Open issue | Required owner/disposition |
|---|---|---|
| C37-01 | Logical document vs immutable version identity; current physical schema has no version FK/table and print_events cannot bind a precise version | Engineering + Database; reconcile CMD-036, ERD, physical schema and API contract |
| C37-02 | Whether a superseded/replaced artifact version remains eligible when a newer version exists; session closure alone is not a print blocker under DOC-003 | Product Owner |
| C37-03 | Meaning and storage location of `attempt_no` versus per-document `sequence_no` and CMD-038 item attempts | Engineering + Database |
| C37-04 | Counter object/allocator, exact lock modes/ranks, unique indexes, FK/trigger edges and RLS/ACL | Database + Security |
| C37-05 | Exact audit event metadata, retention and visibility | Audit/Records authority + Security |
| C37-06 | Maximum CMD-038 batch size/rate limits and operational SLO | Product Owner + Operations, supported by workload/UAT evidence |

**Disposition:** Candidate contract only. CMD-037 is NOT CERTIFIED; CMD-031–040 remains 0/10 certified; application lock certification remains 0/50; global graph acyclicity remains NOT PROVEN; G9 NOT READY. No schema admission, SQL, migration, RLS/grants, application handler, printer integration, automated test, live database operation or production action is authorized or claimed.
