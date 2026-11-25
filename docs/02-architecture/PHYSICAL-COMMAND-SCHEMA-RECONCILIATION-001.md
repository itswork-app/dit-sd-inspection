# Physical Command-to-Schema Reconciliation — CMD-001–054

**Document ID:** CMD-SCHEMA-RECONCILIATION-001  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Status:** Static documentation reconciliation — Engineering / Database / Security review required; NOT approved for implementation  
**Branch baseline:** docs/audit-lock-and-identity-reconciliation  
**Scope:** Package L physical schema, Package M RLS catalogue, PostgreSQL command catalogue and CMD-PHYSICAL-CROSSWALK-001  
**Gate:** G9 NOT READY; G10 NOT ACTIVE

## 1. Executive result

A static comparison of the current source documents establishes:

- Physical schema table inventory: **48** unique table names.
- Table-by-table RLS inventory: **48** unique table names.
- Exact name parity: **48/48**; no table name is missing on either side.
- Command crosswalk: **50** application-command entries (CMD-001–044 and CMD-049–054); CMD-045–048 remain external control-plane IDs and are excluded.
- Technical lock certification: **0/50**.
- This comparison does not establish live database existence, deployed RLS, effective grants, physical constraints, lock behavior, or command correctness.

The 48/48 result closes only the table-name inventory comparison between Package L and Package M. It does not close command-level physicalization, column-level contracts, FK/index/trigger/function coverage, worker identities, Storage contracts, or authorization proof.

## 2. Sources and method

Compared on the same documentation branch:

1. `PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md` — Package L proposed table catalogue.
2. `TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md` — Package M table and access posture.
3. `POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md` — command-level logical/physical contracts.
4. `COMMAND-PHYSICAL-OBJECT-CROSSWALK-001.md` — per-command physical read/write proposals.

Method: extract unique table identifiers from Package L and Package M table rows and compare exact names; then inspect command crosswalk sections and their explicit schema-gap statements against Package L. This is static text analysis only. It does not parse or execute SQL, inspect a live Supabase project, or prove that a proposed object exists.

## 3. Package L ↔ Package M inventory parity

| Check | Result | Disposition |
|---|---:|---|
| Package L unique physical table names | 48 | Static inventory |
| Package M RLS table names | 48 | Static inventory |
| Package L tables absent from Package M | 0 | No name delta |
| Package M tables absent from Package L | 0 | No name delta |
| RLS enabled / policies deployed / grants effective | NOT VERIFIED | Requires database and role evidence |

This parity must not be described as RLS certification. The RLS catalogue itself states that CMD means trusted-command-only mutation and does not confer direct browser/PostgREST DML rights. Exact role grants and function EXECUTE grants remain unapproved/unimplemented.

## 4. Command-to-schema physicalization findings

### 4.1 Identity, authorization and project concurrency

| Command(s) | Finding | Required closure evidence |
|---|---|---|
| CMD-001 | No dedicated account-request entity is defined. `app_users` request lifecycle ownership, signup timing, pending uniqueness and request history remain ambiguous. | Approved lifecycle/state model; canonical entity decision; uniqueness/upsert predicate; FK and append-only decision/history design. |
| CMD-002–003 | `account_decisions` is present, but terminal decision uniqueness, state transition arbiter and concurrency/version mechanism are not fully specified. | Unique terminal-decision key or equivalent serialized arbiter; explicit state machine; race tests. |
| CMD-004–007 | `user_roles` and `user_scope_grants` exist, but interval exclusion, grant history, exact scope-type target map, row-version/CAS and SoD are incomplete. | Canonical permission registry; constrained scope map/FKs; interval and grantor-ceiling rules; audit/history model; Database/Security approval. |
| CMD-009–010 | `projects` lists id/code/name/status/timezone but not a project row-version/CAS field. CMD-009's expected version and CMD-010's parent fence therefore lack a physical token contract. | Approved version column/type/increment rule; enumerate every child writer and finalizer; parent-fence protocol and concurrency tests. |
| CMD-011–013 | `sessions` has no documented `row_version`; CMD-011–013 propose expected row-version semantics. Session closure dependencies also need complete enumeration. | Add an approved physical version field and increment rule; complete child dependency predicates and lock/fence protocol. |
| CMD-014–016 | `operational_assignments` and `assignment_members` do not document row-version fields. CMD-016 cap semantics are PO-approved, but every capacity-affecting writer and initialization/serialization primitive still needs proof. | Exact row-version fields where required; complete T-14 writer inventory; project capacity row initialization and serialized predicate proof. |

### 4.2 Plans, instrument configuration and identity/inspection

| Command(s) | Finding | Required closure evidence |
|---|---|---|
| CMD-017 | `target_plans` does not list `session_id`; draft row-version/CAS and the unique allocation key are not settled. | Decide project/session scope; define immutable publication snapshot, draft concurrency and allocation uniqueness. |
| CMD-019–020 | Configuration tables exist, but canonical serialization/hash, persisted snapshot shape, child immutability enforcement and publication concurrency are incomplete. | Canonicalization specification; immutable snapshot schema; trigger/ACL or equivalent database enforcement; publication lock/unique arbiter. |
| CMD-021 | `instruments` has no documented row-version; lifecycle guard and serialization against assignment creation/deactivation are incomplete. | Version/lifecycle contract and shared serialization protocol with assignment writers. |
| CMD-022–025 | Canonical unit/association/conflict tables are present, but conflict ranking/unique arbiter and complete race behavior require explicit approval. CMD-023/025 ordering conflict remains carried forward. | Approved identity-conflict state machine, candidate ranking and unique arbiter; association episode and privacy-safe outcomes; race tests. |
| CMD-026–030 | Core claim/inspection/revision/event tables exist. Exact mutable draft response representation, row-version coverage, event creation and terminal review uniqueness still need reconciliation. | Command-specific field/write allowlists; aggregate concurrency tokens; exact review uniqueness and append-only event transaction proof. |

### 4.3 Evidence, sync, document, print and attendance

| Command(s) | Finding | Required closure evidence |
|---|---|---|
| CMD-033–034 | `evidence_assets` lacks explicit intent expiry, upload authorization state, client file identity, quota reservation and finalization metadata. Storage authorization is an external side effect. | Upload-intent state machine, expiry/quota model, server-observed finalization contract, object trust/TOCTOU controls and Storage policy review. |
| CMD-035 | `sync_batches` stores a batch envelope but no durable per-operation result ledger or device registry/binding model is specified. Batch status alone cannot reconstruct partial application or lost-ack retries. | Approve a per-operation ledger (candidate name only; no table is approved by this report), semantic hash/replay contract, device trust model and conflict outcomes. |
| CMD-036 | `documents` is not a generic source-resource model; template registry/version and durable renderer job/outbox/lease/attempt model are absent. Notification outbox must not be reused for document rendering. | Generic source identity/provenance; approved template registry; dedicated renderer job lifecycle, worker ACL/lease and immutable artifact version/hash. |
| CMD-037 | Document version identity and concurrency-safe print sequence allocation are not explicit. | Stable immutable document-version identity and database-backed sequence allocator with concurrency proof. |
| CMD-038 | `print_batches` and `print_events` exist, but no durable batch-item manifest/result object is specified. requested_count alone cannot reconstruct every item after lost acknowledgement. | Decide whether a child item/result object is required; define stable item key, invalid/unresolvable item outcomes and replay semantics. |
| CMD-039 | `attendance_records` lacks location/assignment authority fields; `attendance_documents` lacks upload intent, version, replacement reason, MIME/size and finalization/verification metadata. | Institution-approved location/assignment authority; immutable document version and upload lifecycle; Storage and privacy review. |
| CMD-040 | No append-only attendance verification history object is defined. Updating only attendance status loses the document version, checksum, reviewer, reason and later re-verification history. | Approve an immutable verification event model (candidate name only) or an equivalently complete append-only design; map it to audit and institutional authority. |

### 4.4 Reporting, audit, export and notifications

| Command(s) | Finding | Required closure evidence |
|---|---|---|
| CMD-041–044 | Existing crosswalk entries remain OPEN/BLOCKED; bounded query objects, report snapshot/watermark, audit-read purpose/RLS and T-10 export design are incomplete. | Define exact bounded read model, stable cursor/snapshot semantics, purpose-specific permissions and institutional T-10 approval for export. |
| CMD-049 | `notifications` exists, but recipient + ordering + unread indexes, composite scope integrity and cursor/page consistency are not fully specified. | Exact index set, recipient-only RLS proof, stable cursor contract and concurrency semantics. |
| CMD-050 | Set-once `read_at` semantics are specified at product level; atomic notification.read audit and recipient-owned guarded update still need technical verification. | Database command transaction and RLS/ACL tests; exactly-once transition event evidence. |
| CMD-051 | `notification_policy_versions` exists, but effective-time exclusion/serialization, composite scope FK and exact policy administration grants/SoD remain open. | Approved exclusion/locking strategy, scope integrity and role/grantor/SoD review. |
| CMD-052–054 | Notification tables and proposed lease columns exist in the catalogue, but worker identity/ACL, callback authentication, provider-event deduplication, lease fencing and retry proof remain unverified. | Worker principal and least-privilege grants; provider-specific signed callback contract; durable event dedup; stale-worker fencing and retry/concurrency evidence. |

## 5. Cross-document corrections required

1. Preserve the 48/48 Package L/Package M parity result, but label it strictly as table-name inventory parity.
2. Do not treat proposed candidate objects as approved schema: `sync_batch_operations`, document renderer jobs/outbox, print batch items, attendance verification events and upload-intent structures require explicit design approval before entering the canonical physical inventory.
3. Resolve row-version naming consistently. The command contracts use `expected_row_version` in several places, while the schema omits the corresponding physical columns for projects, sessions and other aggregates. Do not infer that `version`, `row_version` and `expected_version` are interchangeable.
4. Preserve CMD-045–048 as external control-plane IDs; they must not be materialized as app commands or tables.
5. Keep CMD-041–044 OPEN/BLOCKED until their command-specific physical read/write and authorization contracts are complete.
6. Reconcile this report with DGA-001, LOCK-MANIFEST-001, LOCK-GRAPH-001, LPR-001, CERT-001, RTM and RAID before changing any gate status.

## 6. Gate and evidence disposition

- Package L ↔ Package M table-name parity: **PASS — static inventory check only**.
- Command physicalization completeness: **NOT PASS**.
- Physical schema / FK / index / trigger / function certification: **NOT EXECUTED / NOT CERTIFIED**.
- RLS deployment and effective grants: **NOT VERIFIED**.
- Global lock graph acyclicity: **NOT CERTIFIED**.
- Application lock certification: **0/50**.
- G9: **NOT READY**.
- G10: **NOT ACTIVE**.

No source code, SQL, migration, grant/revoke, live database, Storage, provider, CI, test, deployment, production-data or protected-branch operation was performed. This document is a static reconciliation artifact and does not authorize implementation.

## 7. Next closure sequence

1. Engineering and Database resolve the field-level version/CAS contract and parent/child fence coverage for CMD-009–016.
2. Engineering/Database approve or reject the candidate durable objects for CMD-035, CMD-036, CMD-038 and CMD-040; update Package L, ERD, RLS, command contracts and crosswalk together.
3. Security approves permission registry, SoD, command EXECUTE ACL, worker identity and provider callback trust boundaries.
4. Complete CMD-041–044 physical query and T-10 institutional dependencies.
5. Recompute the command crosswalk and global lock graph; obtain independent technical review and evidence before any G9 decision.
6. Record a separate G10 activation only after G9 is independently verified. Until then, implementation remains prohibited by root AGENTS.md v1.2.2.
