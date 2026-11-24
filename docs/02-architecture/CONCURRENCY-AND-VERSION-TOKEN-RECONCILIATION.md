# Concurrency and Version Token Reconciliation

**Document ID:** CONCURRENCY-001  
**Version:** 0.1.1  
**Status:** Engineering proposal — PO/Security review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Scope:** CMD-001–054, physical schema, command catalogue, transaction/lock contracts, audit and QA traceability  
**Gate:** G3 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Executive decision summary

The cross-command audit identified a systemic mismatch: several command contracts require \`expected_version\` or \`expected_row_version\`, while the corresponding physical table does not define a concurrency token. Other commands use business-version numbers, revision numbers, hashes, lock rows or worker lease tokens that must not be conflated with an aggregate row version.

This document proposes one consistent model for review. It does not approve new columns, change an API contract, close any finding, or authorize a migration.

**Recommended direction for PO/Security review:**

1. Use a dedicated monotonic \`row_version BIGINT\` on mutable aggregate rows where optimistic concurrency is part of the command contract.
2. Expose it consistently as \`expected_row_version\`; return \`row_version\` in successful mutation responses.
3. Keep business version numbers, inspection revision numbers, content hashes, print sequence numbers and worker lease/fencing tokens as separate concepts.
4. Remove \`expected_version\` from CMD-050 notification-read if the operation remains a recipient-self, set-once \`read_at\` update; use a conditional idempotent update instead of adding a high-volume inbox version column.
5. Preserve row locks and database constraints for cross-row invariants. A row version is not a substitute for serialization, authorization or uniqueness constraints.

No item below is approved until the appropriate Product Owner and Security owners accept the exact source changes. Institutional approval remains necessary where T-10/T-12 or other reserved authority applies.

## 2. Authority, source documents and evidence boundary

Reviewed on branch \`docs/t17-instrument-governance-t18-command-boundary\`:

- \`AGENTS.md\` v1.2.0.
- \`docs/02-architecture/PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md\` v0.3.0.
- \`docs/02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md\` v0.3.0.
- \`docs/02-architecture/CMD-001-010-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-011-020-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-021-030-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-031-040-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-041-044-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-045-048-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/CMD-049-054-DETAILED-CONTRACT-REVIEW.md\`.
- \`docs/02-architecture/PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md\`.
- \`docs/02-architecture/PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md\`.
- \`docs/04-quality/TEST-CASE-CATALOG-AND-UAT.md\`.
- \`docs/00-project-charter/DECISION-REGISTER.md\` and \`IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md\`.

Evidence is static document inspection only. No live Supabase catalog, deployed route, runtime SQL, RLS, grant, lock behavior, query plan or CI/test result was inspected or executed.

## 3. Terminology — keep version domains separate

| Term | Purpose | Must not be treated as |
|---|---|---|
| \`row_version\` | Monotonic concurrency token for one mutable aggregate row | Business release/version number, timestamp or revision number |
| \`expected_row_version\` | Caller’s observed row version used for a compare-and-swap mutation | Authorization credential or idempotency key |
| \`version\` / \`version_number\` | Business sequence, e.g. target plan or instrument version | Proof that a draft has not changed since it was read |
| \`revision_no\` / \`expected_revision_no\` | Inspection content/review revision identity | Aggregate row concurrency token |
| \`policy_hash\` / \`expected_draft_hash\` | Canonical content identity and stale-draft detection | Monotonic row version or secret |
| \`sequence_no\` / \`expected_sequence\` | Per-document print-event ordering | Generic row version |
| \`lease_token\` / fencing generation | Worker ownership and stale-worker exclusion | User-facing row version |
| \`updated_at\` | Observability and chronology | Reliable compare-and-swap token |

A business version may remain unchanged while a draft is edited, and a row may be updated more than once within one business version. The two fields therefore cannot be substituted for one another.

## 4. Proposed canonical row-version contract

### 4.1 Physical representation

For each mutable aggregate explicitly approved to use optimistic concurrency:

- Column: \`row_version BIGINT NOT NULL DEFAULT 1\`.
- Constraint: \`row_version >= 1\`.
- Initial value: 1 on creation.
- Increment: exactly once for each successful semantic mutation of that aggregate in a command transaction.
- No increment for rejected commands, authorization failures, idempotent replays or approved semantic no-ops.
- The mutation, version increment, required domain event, audit event and idempotency result commit atomically.
- Append-only or immutable rows do not receive \`row_version\` merely to make the schema look uniform.

The exact SQL type/default/check is a proposal pending physical schema review. Do not add it through a migration before approval.

### 4.2 API representation

Use one field name, \`expected_row_version\`, for mutable aggregate compare-and-swap requests. Return the resulting \`row_version\` after a successful mutation.

Because PostgreSQL BIGINT exceeds JavaScript's exact integer range, the API contract should either:
- serialize row versions as canonical decimal strings; or
- impose and enforce a numeric upper bound no greater than JavaScript's safe integer range.

**Recommendation:** decimal string at JSON boundaries, parsed and validated server-side as a positive signed 64-bit integer. This is a design recommendation, not an approved API schema.

Do not accept \`expected_version\` as an alias indefinitely. If an alias is retained during a compatibility window, define precedence, deprecation and removal in an explicit API version change.

### 4.3 Compare-and-swap behavior

For a simple aggregate mutation, the logical database operation is equivalent to:

\`\`\`sql
UPDATE <aggregate>
SET <approved_mutable_fields> = <new_values>,
    row_version = row_version + 1
WHERE id = <target_id>
  AND row_version = <expected_row_version>
RETURNING row_version;
\`\`\`

This is illustrative only; it is not an executable migration or command function. Complex commands may lock the aggregate row, revalidate all authorization/state/dependency predicates, compare the token, and then update within one transaction. Do not combine an unlocked preflight read with a later unconditional write.

A zero-row compare-and-swap result must be resolved without leaking existence or scope information: re-authorize and distinguish stale state from not-found/denied only where the caller is entitled to know.

### 4.4 Idempotency order and replay

1. Authenticate and validate the caller.
2. Resolve the idempotency key and canonical request hash.
3. For a matching completed replay, re-check current authorization as required by the command contract and return the stored original result; do not compare the stale client version again or mutate.
4. Reject same key with a different semantic request hash.
5. For a new command, acquire required locks in the approved global order.
6. Compare the expected token and revalidate state/scope/SoD under the lock.
7. Apply the semantic mutation and increment the aggregate token once.
8. Append required domain/audit evidence and persist the result atomically.

Idempotency and row-version checks solve different problems; neither replaces the other.

### 4.5 Cross-row invariants

Row versions do not replace:
- T-14 project capacity serialization on the shared \`project_capacity_settings\` row;
- canonical serial-key arbitration and unit/association/claim lock order;
- unique/exclusion/partial unique constraints;
- one terminal review decision per inspection revision;
- deterministic child-row locking;
- worker lease/fencing checks;
- immutable event/revision records.

The canonical global lock order remains controlling. The CMD-026 conflict identified in the cross-command reconciliation must be resolved before implementation.

## 5. Command-to-token reconciliation

The following matrix distinguishes existing physical tokens from missing/proposed ones. “Existing” means only that the current physical specification lists the column; it does not mean runtime existence or behavior is verified.

| Command | Current contract token | Aggregate / target | Physical specification today | Proposed disposition |
|---|---|---|---|---|
| CMD-005 revoke role | \`expected_version\` in catalogue (optional); detailed review includes it | \`user_roles\` grant row | No \`row_version\` listed | Add proposed \`user_roles.row_version\`; settle whether required and use \`expected_row_version\` consistently |
| CMD-007 revoke scope | Detailed review includes \`expected_version\`; canonical catalogue omits it | \`user_scope_grants\` grant row | No \`row_version\` listed | Resolve catalogue/review mismatch; add proposed \`row_version\` only if PO/Security retains client CAS |
| CMD-009 update project | \`expected_version\` | \`projects\` | No version/update token listed | Add proposed \`projects.row_version\` |
| CMD-010 close project | \`expected_version\` | \`projects\` | No version/update token listed | Share \`projects.row_version\`; closure still needs a complete dependency/fencing contract |
| CMD-012 update session | \`expected_version\` | \`sessions\` | No version token listed | Add proposed \`sessions.row_version\` |
| CMD-013 transition session | \`expected_version\` | \`sessions\` | No version token listed | Share \`sessions.row_version\`; increment on each successful state transition |
| CMD-016 change Inspector capacity | \`expected_version\` | \`project_capacity_settings\` | No version token listed | Add proposed \`row_version\`; keep the same row as the T-14 serialization point |
| CMD-017 manage target plan | Business \`version\` / plan version | Mutable draft \`target_plans\` row | Business \`version\` exists; no separate row token; \`session_id\` also unresolved | Do not treat business version as CAS; define draft \`row_version\` or approved hash-CAS before concurrent draft updates |
| CMD-019 save instrument draft | Draft/version identity; no complete CAS field | Mutable \`instrument_versions\` draft aggregate | \`version_number\` exists; no \`row_version\` or canonical config hash listed | Define draft \`row_version\` or hash-CAS; define deterministic config hash and canonicalization |
| CMD-020 publish instrument version | \`expected_draft_hash\` | \`instrument_versions\` draft content | T-17 requires hash/snapshot; physical table does not list canonical config hash | Define physical \`config_hash\` (or approved equivalent) and compare exact server-computed hash under lock |
| CMD-021 deactivate instrument | \`expected_version\` | \`instruments\` | No version token listed | Add proposed \`instruments.row_version\` |
| CMD-024 end/revoke association | \`expected_version\` | \`unit_project_associations\` | No version token listed | Add proposed \`row_version\`; retain active-work gate and approved ENDED/REVOKED semantics |
| CMD-027 release unit claim | \`expected_version\` | \`unit_claims\` | \`row_version\` already listed | Align API name to \`expected_row_version\`; define initial/increment rules and whether required |
| CMD-028 save draft | \`expected_row_version\` | \`inspections\` aggregate | \`row_version\` already listed | Retain; define semantic no-op and increment exactly once per successful save mutation |
| CMD-029 submit inspection | \`expected_row_version\` | \`inspections\` aggregate | \`row_version\` already listed | Retain; increment once with immutable revision/state/event/audit transaction |
| CMD-030 return inspection | \`expected_revision_no\` | \`inspections\` aggregate + exact revision | \`inspections.row_version\` listed | Revision binding exists; decide whether expected aggregate row version is also required; always increment row version on successful aggregate state mutation |
| CMD-031 approve inspection | \`expected_revision_no\` | \`inspections\` aggregate + exact revision | \`inspections.row_version\` listed | Same decision as CMD-030; unique terminal-decision invariant and aggregate lock remain mandatory |
| CMD-032 reopen inspection | \`expected_row_version\` | \`inspections\` aggregate | \`row_version\` already listed | Retain; define one-active-draft lifecycle and increment once |
| CMD-035 sync batch | Catalogue says \`expected_version\`; detailed review says \`expected_row_version\` | Each operation’s \`inspections\` aggregate | \`inspections.row_version\` listed | Normalize each operation to \`expected_row_version\`; increment once for each successfully applied semantic operation |
| CMD-040 verify attendance | \`expected_version\` | \`attendance_records\` aggregate; exact immutable \`attendance_document_id\` | No version token listed | Add proposed \`attendance_records.row_version\`; keep document ID as immutable source identity and append verification decision |
| CMD-050 mark notification read | Optional \`expected_version\` | Recipient-owned \`notifications\` row | No version token listed | Remove optional version field; use set-once conditional update on \`read_at IS NULL\`, stable idempotent result and recipient-self authorization |

### 5.1 Commands without an external row-version field

The absence of \`expected_row_version\` does not mean concurrency can be ignored. The current command designs rely on other mechanisms:

- CMD-001–003: target-account row lock, unique Auth mapping and append-only account decisions.
- CMD-004/006/008/011/014/018/022/023/025/026/033/034/036/038/039: unique constraints, canonical-key arbitration, aggregate locks, idempotency and/or append-only intent/history as specified per command.
- CMD-014/015: T-14 capacity row serialization and deterministic assignment/member locks; no extra version token is justified solely by the capacity invariant.
- CMD-025: conflict-row lock and one terminal resolution; append-only decision evidence.
- CMD-037/038: \`expected_sequence\` and append-only \`print_events\` are per-document ordering controls, not aggregate row versions.
- CMD-041–044: read/query snapshot and cursor consistency; not mutation CAS.
- CMD-045–048: remain blocked; do not design version columns before institutional/operational authority and physical records are approved.
- CMD-049: recipient-scoped read query and stable cursor; no mutation CAS.
- CMD-052/053: lease owner/token/expiry and fencing semantics; worker lease token is not a row version.
- CMD-054: server-derived time, pinned policy version and unique escalation event key; caller time must not control due-ness.

These mechanisms still require command-specific lock, uniqueness, idempotency and failure tests.

## 6. Cross-command design rules

### 6.1 Aggregate ownership

A command must identify one authoritative mutable aggregate row whose \`row_version\` protects the semantic state transition. Child-row writes are included in the same transaction. A command must not compare a version on one table and then mutate a different aggregate without an explicit parent/child concurrency rule.

### 6.2 Increment semantics

- Increment once per successful command-level semantic mutation, not once per SQL statement or child row.
- For CMD-035, each independently committed operation increments its target inspection aggregate once.
- A command that only appends a separate immutable event but does not change aggregate state does not automatically increment unrelated aggregates.
- A semantic no-op policy must be explicit. Recommended behavior: return a stable no-op outcome without incrementing the token or emitting a duplicate state-change event.
- Replays return the originally stored resulting version and never increment again.

### 6.3 Multi-command races

- CMD-005 Inspector revoke, CMD-004 Inspector grant, CMD-014/015 membership changes and CMD-016 capacity changes must continue to serialize on the same capacity row and use the identical T-14 qualifying-account predicate.
- CMD-009/010 project metadata/closure operations must serialize on the project row; closure must also fence concurrent child operations through an approved dependency-lock protocol.
- CMD-012/013 session metadata/transition operations must serialize on the session row; closure gates must prevent new child work racing with closure.
- CMD-021 deactivation must serialize with operations that select the instrument for new work, without rewriting pinned historical assignments.
- CMD-024 association end/revoke must serialize with claim/draft/submission operations referencing that exact association.
- CMD-027 claim release and CMD-028–032 inspection mutations must use the approved unit/claim/inspection lock order; the unresolved CMD-026 lock conflict remains blocking.
- CMD-030/031 terminal review decisions must serialize and enforce one terminal decision for the exact revision; revision number alone is not a substitute for the aggregate lock/unique invariant.
- CMD-039 upload/replacement and CMD-040 verification must serialize on the attendance aggregate and exact immutable document version.

### 6.4 Draft hashes and immutable versions

For CMD-019/020, a business \`version_number\` identifies the instrument version but does not detect edits within a mutable draft. The draft needs a canonical content representation and a concurrency guard. Recommended design:
- canonicalize the allowlisted configuration deterministically;
- calculate a server-side content hash;
- persist the hash with the draft snapshot;
- save/publish compares the expected hash or \`row_version\` under the instrument-version lock;
- publish freezes the exact content/hash and appends the publication record;
- published content is immutable.

Do not trust a client-computed hash as proof of content integrity. The server recomputes it from validated canonical data.

For CMD-017, target plan \`version\` is a business version. A mutable DRAFT needs its own concurrency guard; published plan versions remain immutable. Resolve the missing \`session_id\` and allocation key independently.

### 6.5 Worker lease fencing

CMD-052/053 use bounded worker leases. A stale worker must not complete work after another worker reclaimed the lease. The design needs a lease generation/token checked on every completion/failure transition, plus expiry and owner checks. This is not a user-facing \`expected_row_version\`; define a separate fencing contract and exact physical fields in the NLA-001/schema reconciliation.

## 7. Contract vocabulary mismatches to resolve

| ID | Source mismatch | Required resolution |
|---|---|---|
| CV-01 | CMD-005 catalogue marks \`expected_version?\` optional; detailed review includes it and stale-version outcome | Decide whether CAS is mandatory; normalize field name and response |
| CV-02 | CMD-007 detailed review includes \`expected_version\`; catalogue omits it | Add/remove only after explicit contract decision |
| CV-03 | CMD-035 catalogue uses \`expected_version\`; detailed review uses \`expected_row_version\` | Normalize to one field name and bind each operation to \`inspections.row_version\` |
| CV-04 | CMD-040 uses generic \`expected_version\` with no explicit target | Bind to attendance aggregate row or remove through approved concurrency design |
| CV-05 | CMD-030/031 use \`expected_revision_no\` while mutating inspection aggregate | Decide whether aggregate expected row version is also required; keep revision identity and row concurrency distinct |
| CV-06 | CMD-050 optional \`expected_version\` conflicts with set-once read timestamp and no physical version column | Remove version field or approve a real version model; recommended removal |
| CV-07 | CMD-020 \`expected_draft_hash\` has no explicitly named physical config-hash field | Define server-computed canonical hash persistence and comparison |
| CV-08 | CMD-017 business \`version\` is not draft concurrency control | Define separate row/hash token for mutable draft |

## 8. Required test coverage

All cases below are additions/clarifications to existing planned command test IDs. They are **PLANNED / NOT EXECUTED**.

| Test concern | Commands | Required assertion |
|---|---|---|
| Initial version | All proposed row-version aggregates | New mutable aggregate starts at exactly 1 |
| Stale write | CMD-005/007/009/010/012/013/016/021/024/027–032/035/040 | Stale token cannot overwrite newer state; safe typed outcome |
| Concurrent same token | Same commands | Exactly one semantic mutation wins; loser receives stale/conflict result |
| Increment cardinality | All versioned commands | One increment per semantic command mutation; no double increment |
| No-op | Commands where no-op is possible | Approved no-op does not increment or duplicate state-change audit |
| Replay | All idempotent mutations | Same key returns stored result/version; no second increment |
| Key reuse | All idempotent mutations | Same key/different semantic hash is rejected |
| Audit failure | All audited mutations | Mutation and version increment roll back together |
| Authorization race | Role/scope, project/session, capacity, association and inspection commands | Revoked/changed authority revalidated under lock; no stale authorization |
| Capacity race | CMD-004/005/014/015/016 | Shared T-14 lock/predicate prevents over-cap state |
| Draft hash | CMD-019/020/051 | Hash mismatch rejects stale publish; server recomputes canonical hash |
| Revision race | CMD-029–032 | Revision identity, aggregate version, one terminal decision and reopen lifecycle remain consistent |
| Sync partial commit | CMD-035 | Each successful operation increments once; conflicted operation preserves client data; replay does not reapply |
| Attendance version | CMD-039/040 | Replacement racing verification is serialized; decision references exact immutable document |
| Notification set-once | CMD-050 | Repeated read is idempotent; no version field is required; delivery state remains separate |
| Lease fencing | CMD-052/053 | Expired/reclaimed worker token cannot commit stale completion or duplicate provider dispatch |

Use existing IDs such as \`TC-CMD-CONTRACT-024-005\`, \`TC-CMD-CONTRACT-024-007\`, \`TC-CMD-CONTRACT-024-009\`, \`TC-CMD-CONTRACT-024-010\`, \`TC-CMD-CONTRACT-024-012\`, \`TC-CMD-CONTRACT-024-013\`, \`TC-CMD-CONTRACT-024-016\`, \`TC-CMD-CONTRACT-024-021\`, \`TC-CMD-CONTRACT-024-024\`, \`TC-CMD-CONTRACT-024-027\` through \`TC-CMD-CONTRACT-024-032\`, \`TC-CMD-CONTRACT-024-035\`, \`TC-CMD-CONTRACT-024-040\`, and notification test IDs. Do not claim coverage until the test catalogue contains the precise assertion and fixtures.

## 9. Decisions required before source-contract updates

| Decision | Required owner | Proposed resolution | Current status |
|---|---|---|---|
| CV-01..08 vocabulary and token targets | PO + Engineering | Accept/reject each mapping in §5 and §7 | OPEN |
| Physical \`row_version\` type/default/check | Engineering + Security + PO | Approve BIGINT, positive default and increment contract | OPEN |
| API JSON representation | Engineering + Security | Decimal string recommended for BIGINT | OPEN |
| CMD-005/007 CAS requirement | PO + Security | Explicitly decide required token vs lock-only transition | OPEN |
| CMD-030/031 review concurrency | PO + Engineering + Security | Keep revision identity and decide aggregate CAS requirement | OPEN |
| CMD-050 set-once read | PO + Security | Remove optional expected_version; conditional update | OPEN |
| CMD-017/019 draft concurrency | PO + Engineering | Approve row token/hash model and immutable publish behavior | OPEN |
| CMD-040 attendance aggregate | PO + Institution | Approve attendance record state model and version target; institutional verifier/SoD remains separate | OPEN |
| Worker lease fencing | Security + Operations | Approve lease generation/token and physical fields | OPEN |

No decision is inferred from this document. Any institutional authority requirement remains reserved to the institution.

## 10. Impacted source documents after approval

Once the decisions are accepted, update these sources in one coherent change set with their own SemVer and traceability:
1. Physical Database Schema and Integrity Specification.
2. PostgreSQL Command Contract Catalogue.
3. Detailed command reviews for each affected range.
4. Privileged Command Boundary and Transaction Specification.
5. Canonical Permission Registry / Command Authorization Verification Matrix only where authorization or command fields are affected.
6. Physical Schema ↔ RLS ↔ Command Reconciliation.
7. Audit Event Catalogue.
8. Test Case Catalog and UAT Plan.
9. RTM, DGA-001 and RAID Register.
10. NLA-001 only for notification-specific read/worker lease behavior.

Do not edit all canonical sources to the proposed values before PO/Security approval. Do not create a migration or runtime test from this proposal.

## 11. Gate disposition

| Gate | Status | Reason |
|---|---|---|
| G3 physical data/integrity | NOT READY | Multiple required token columns and aggregate semantics are not approved/physicalized |
| G4 security/authorization | NOT READY | Exact authorization and worker/ACL evidence remain open |
| G5 API/command contract | NOT READY | Field names/targets/optionality mismatch across catalogue and reviews |
| G7 test/evidence | NOT READY | Planned tests only; no execution evidence |
| G9 scope freeze | NOT READY | Cross-command decisions and institutional blockers remain |
| G10 implementation authorization | NOT AUTHORIZED | No separate written authorization |

**Final disposition:** The concurrency/version model is now mapped as a decision-ready proposal. It is not an approved schema, executable API contract, migration plan or evidence of runtime correctness.
