# Command-Level Lock Manifest Reconciliation — CMD-001–054

**Document ID:** LOCK-MANIFEST-001  
**Version:** 0.4.1
**Status:** Engineering reconciliation proposal — review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Parent:** LOCK-GRAPH-001 v0.4.1  
**Scope:** Per-command resource inventory, source-stated lock sequence, shared invariants, competing commands, constraints and unresolved ordering  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Executive conclusion

This document converts the current command reviews into a 54-row lock manifest inventory. It records only resource and ordering facts that are explicitly present in the reviewed command documents, and labels missing or contradictory information as OPEN. It is not a normalized, approved lock plan.

**Critical result:** 54/54 logical command IDs are represented in the inventory, but **0/54 are certified lock-complete**. The manifest is an evidence and reconciliation artifact, not a proof of deadlock freedom. In particular, source-stated lock order conflicts remain in CMD-023/024/025/026/027/028, and CMD-031–040 contain further aggregate/child and external-effect boundaries requiring cross-check against the global candidate ranks.

No command catalogue, physical schema, function, API, migration or runtime behavior is changed by this document.

## 2. Authority, source set and method

Root `AGENTS.md` v1.2.0 was re-read from the target branch at the start of this work session. The source baseline below records the exact reviewed snapshot used for this reconciliation checkpoint on 2026-11-24 (it is not a live pointer to later document edits):

| Source | Reviewed snapshot version / identity | Use in this reconciliation |
|---|---|---|
| MIB-001 | v1.0.1 | Authority, gates and documentation-phase boundary |
| DGA-001 | v1.9.10 | Active evidence-backed gap queue and gate disposition |
| IRG-001 | v1.0.1 | Phase and authorization governance |
| Decision Register | Current branch revision | Approved PO decisions and institutional dependencies |
| PostgreSQL Command Contract Catalogue | v0.3.1 | Canonical logical CMD-001–054 operation inventory and proposed contracts |
| Physical Database Schema and Integrity Specification | v0.3.0 | Proposed entities, constraints, indexes and transaction invariants |
| LOCK-GRAPH-001 | v0.3.9 | Candidate resource ranks, cross-command conflicts and planned race scenarios |
| CONCURRENCY-001 | v0.1.2 | Aggregate token, idempotency and worker-fencing mismatches |
| LOCK-PROTOCOL-DECISION-RESOLUTION-001 | v0.2.3 | LPR decision state and static reconciliation checkpoint |
| Detailed command reviews | Seven current command-range documents; CMD-001–010 review v0.2.0 at snapshot time | Per-command source-stated operations and dependencies |

This replaces the stale historical snapshot labels in the original v0.3.2 review method (including DGA v1.4.0, catalogue/physical schema v0.2.0 and lock graph v0.1.0). Version refresh is a traceability correction only; it does not imply those sources or any command lock manifest are approved.

Method:
1. Extract the lock/transaction/read-write statements stated by each command review.
2. Record source-stated acquisition sequence separately from the candidate global rank hierarchy.
3. Identify shared invariants and known competing commands from the cross-command review.
4. Mark unknown resource order, implicit trigger/FK/index behavior, constraints, worker identity or authority as OPEN; do not infer them.
5. Treat read-only commands as having no row-lock manifest unless the source explicitly defines one. Treat blocked commands as not designable for implementation.
6. Reconcile every static finding against the current source versions above; preserve a distinction between documented design and physical/runtime evidence.

Evidence is static documentation inspection only. No PostgreSQL catalog, query plan, lock graph, transaction trace, deployed function, RLS/grant, CI or concurrency test was executed.

## 3. Legacy manifest notation and candidate-rank crosswalk

The CMD-001–048 rows below retain the compact rank labels used by the earlier LOCK-GRAPH-001 v0.3.2 extraction. Those labels are **legacy inventory notation**, not the current candidate ranks in LOCK-GRAPH-001 v0.4.0 / LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.1. They preserve source-order observations for audit traceability and must not be used as executable lock instructions.

| Legacy label in CMD-001–048 rows | Legacy meaning | Current candidate rank mapping | Reconciliation rule |
|---|---|---|---|
| L0 | Idempotency arbitration | L00 | Rename only after command-specific idempotency identity/hash is confirmed |
| L10 | Shared serialization row | L10 | Preserve only where the T-14/shared invariant predicate applies |
| L20 | Canonical identity arbitration | L20 | Confirm exact canonical key and arbitration primitive |
| L30 | Project/session parent | L30 | Confirm every applicable parent and stable multi-row order |
| L40 | Assignment/instrument references | L40 instrument/version **or** L50 assignment/membership | Split by actual resource; never mechanically map the combined legacy label |
| L50 | Canonical unit | L60 | Confirm unit row and parent ordering |
| L60 | Association episode | L70 | Confirm exact association episode/key |
| L70 | Claim/inspection aggregate | L80 claim **or** L90 inspection | Split claim and inspection resources and preserve source order as a conflict where necessary |
| L80 | Dependent child aggregate | L100 | Identify exact mutable child aggregate and per-command sub-order |
| L90 | Append-only facts | L110 | Confirm append-only event/audit/revision/attempt identity and unique arbiter |

The current candidate ranks are L00 idempotency, L10 shared invariant, L20 canonical identity, L30 project/session, L40 instrument/version, L50 assignment/membership, L60 canonical unit, L70 association, L80 claim, L90 inspection, L100 dependent mutable aggregates, and L110 append-only facts. These remain proposals, not an approved lock order. The current hierarchy has no explicit resource class for mutable account identity or authorization grants (app_users, user_roles, user_scope_grants); CMD-001–007 therefore cannot be rank-normalized until LPR-11 is resolved.

CMD-001–048 legacy labels are intentionally not mechanically rewritten in this checkpoint because that would conceal unresolved source-order conflicts and the L40/L70 one-to-many mappings. They remain OPEN for per-command normalization. CMD-049–054 use explicit resource/transaction descriptions below rather than legacy rank labels. A dash means the source does not specify a row lock; it does not mean implicit database locking is absent.

## 4. CMD-001–054 command-level inventory

| Command | Logical operation | Source-stated lock/resource sequence | Shared invariant / competing path | Constraint or final arbiter stated in source | Status / unresolved manifest item |
|---|---|---|---|---|---|
| CMD-001 | request-account-access | L0 → own app_users identity/upsert; no other user's row | Concurrent first request for same Auth identity | Unique auth_user_id / upsert conflict path | PARTIAL — exact account-request canonical entity/lifecycle and implicit conflict lock details open |
| CMD-002 | approve-account | L0 → target app_users → account_decisions/audit | Approve vs reject; competing decision for same target | Conditional source-state transition | PARTIAL — actor/target authorization revalidated under lock; exact account row version not defined |
| CMD-003 | reject-account | L0 → target app_users → account_decisions/audit | Reject vs approve for same target | Conditional source-state transition | PARTIAL — same aggregate protocol as CMD-002 must be identical; row version absent |
| CMD-004 | grant-role | L0 → L10 project_capacity_settings when Inspector eligibility changes → target/user_role rows → L90 | CMD-005, CMD-014, CMD-015, CMD-016 and account eligibility reduction | Role/scope interval uniqueness; exact exclusion strategy open | PARTIAL — capacity-first applies only when Inspector predicate affected; all eligibility paths must be enumerated |
| CMD-005 | revoke-role | L0 → L10 capacity row for Inspector eligibility reduction → target user_roles row → L90 | CMD-004 grant, CMD-014/015 membership, CMD-016 cap; account suspension/expiry | Conditional lifecycle update; row_version not in physical schema | BLOCKED — request expected_version has no approved physical token; capacity path must include every eligibility-reducing operation |
| CMD-006 | grant-scope | L0 → target principal and relevant scope/grant rows in deterministic order → L90 | CMD-007 revoke and overlapping grant for same user/scope/kind/ref/interval | No-overlap active grant constraint/strategy not finalized | PARTIAL — exact parent/scope table rank and same-class sort key open |
| CMD-007 | revoke-scope | L0 → exact user_scope_grants row → L90 | CMD-006 grant and concurrent revocation | Lifecycle update; no hard delete; physical version field absent | BLOCKED — expected_version mismatch; grantor scope revalidation and dependent-work policy open |
| CMD-008 | create-project | L0 → unique normalized project-code arbitration → project insert → L90 | Concurrent same normalized project code | Unique normalized code constraint | PARTIAL — insert path is constraint-arbitrated; exact normalized-key implementation remains schema review |
| CMD-009 | update-project | L0 → L30 project row/CAS → L90 | CMD-010 close; CMD-011 session creation and all project-scoped child writers | Row version/CAS proposed, physical version field gap | BLOCKED — expected_version lacks approved physical token; project closure fence must share parent lock |
| CMD-010 | close-project | L0 → L30 project row → dependent blockers in deterministic order → L90 | Every child command/worker creating or advancing project work; CMD-009 | Conditional CLOSED transition; dependency constraints not complete | BLOCKED — closure dependency inventory and child-writer lock protocol incomplete; preflight alone insufficient |
| CMD-011 | create-session | L0 → L30 project row (FOR KEY SHARE or approved equivalent) → session insert → L90 | CMD-010 project close; duplicate session creation | Unique project/code constraint | PARTIAL — exact lock mode must be reconciled with project close and child mutation protocol |
| CMD-012 | update-session | L0 → session row → parent project → assignment/time dependencies → L90 | CMD-013 transition/close; CMD-014/015 assignment work | Deterministic dependency locks or approved exclusion constraint | BLOCKED — source order session then parent differs from proposed parent-first child gate; session row_version missing |
| CMD-013 | transition-session | L0 → session row → closure dependencies in deterministic order → L90 | CMD-012; assignment/member changes; all session child writers | Session aggregate serialization; dependency set incomplete | BLOCKED — parent/session ordering and complete closure blocker set unresolved; row_version missing |
| CMD-014 | publish-assignment | L0 → L10 capacity row if Inspector candidate → L30 project/session/assignment references (UUID order) → L40 affected users/role references → insert assignment/members → L90 | CMD-004/005/015/016, CMD-009/010/011/012/013, CMD-021 | Capacity predicate; overlap and duplicate assignment constraints | PARTIAL — instrument/version relative rank versus assignment remains open; exact all-member lock set needed |
| CMD-015 | change-assignment-members | L0 → L10 capacity row if Inspector membership changes → assignment row → assignment_members and user rows (UUID order) → L90 | CMD-004/005/014/016; session/project closure | Effective-time lifecycle; overlap/uniqueness strategy | PARTIAL — assignment/project/session/instrument parent order and expiry/suspension writers need exhaustive alignment |
| CMD-016 | change-inspector-capacity | L0 → L10 one project_capacity_settings row → eligibility rows → capacity update → L90 | CMD-004/005/014/015 and any account/role/membership eligibility path | Shared capacity row serializes canonical distinct-account predicate | PARTIAL — capacity row initialization, missing-row behavior and all eligibility writers open |
| CMD-017 | manage-target-plan | L0 → L30 project/session for new plan → target_plan row → allocation rows deterministic order → L90 | Concurrent draft edit/reallocation/publish; project/session closure | Unique project/version; published plan immutability | PARTIAL — plan/session relation, allocation key sort, draft CAS token/hash and delete/reinsert history unresolved |
| CMD-018 | create-instrument | L0 → unique instrument code arbitration → instrument insert → L90 | Concurrent duplicate code creation | Unique code constraint | PARTIAL — insert-only path; no parent row lock specified |
| CMD-019 | save-instrument-draft | L0 → L40 instrument row → instrument_version row → child configuration rows deterministic order → L90 | CMD-020 publish; competing draft saves; CMD-021 deactivation/assignment selection | Instrument row serializes version allocation; canonical config hash proposed | BLOCKED — config hash physical field, child replacement/history and assignment/instrument global rank open |
| CMD-020 | publish-instrument-version | L0 → L40 instrument row → instrument_version row → child config validation → publication/audit | CMD-019 draft save; CMD-021 deactivate; CMD-014 assignment publication | Version status/hash and immutable published snapshot; DB enforcement not finalized | PARTIAL — publication history/child immutability constraint and cross-command instrument/assignment order open |
| CMD-021 | deactivate-instrument | L0 → instrument row → assignment reference checks → L90 | CMD-014 assignment publish; CMD-019/020 version changes | Lifecycle transition; active-assignment guard only if approved | BLOCKED — source token expected_version lacks approved physical field; instrument-vs-assignment lock order open |
| CMD-022 | register-canonical-unit | L0 → L20 canonical serial-key unique arbitration; authorize instrument/project/assignment context; unit insert → L90 | CMD-023 association, CMD-025 conflict resolution, CMD-026 claim | Unique `(instrument_type, serial_normalized)` canonical identity key; unknown serial uses new server UUID | PARTIAL — exact ordering of context rows versus canonical-key arbitration and duplicate collision workflow open |
| CMD-023 | associate-unit-to-project | L0 → source says L50 unit → L30 project → L60 association key/unique arbiter → L90 | CMD-024 end/revoke; CMD-025 conflict resolution; CMD-026 claim | Partial unique ACTIVE association index | BLOCKED — source unit-first order conflicts with CMD-026 parent-before-unit candidate order and global hierarchy |
| CMD-024 | end-unit-project-association | L0 → source says unit + association + active claim/inspection rows in globally deterministic order → L90 | CMD-023 association; CMD-026 claim; CMD-027 release; CMD-028–032 inspection lifecycle | ACTIVE association and dependency guard; association history retained | BLOCKED — exact relative order of project/assignment/unit/association/claim/inspection is not stated |
| CMD-025 | resolve-unit-identity-conflict | L0 → source says conflict row → candidate unit → project/association key → L90 | CMD-023 association; CMD-026 claim; other conflict resolver | Unique ACTIVE association index; one conflict resolution | BLOCKED — conflict-first order may invert canonical-key/project/unit path; conflict identity rank unresolved |
| CMD-026 | claim-unit | L0 → L20 canonical `(instrument_type, serial_normalized)` key → L30 project/session/assignment → L50 unit → L60 association → L70 inspection/claim → L90 | CMD-023/024/025/027; CMD-028 save draft; claim expiry/takeover | Partial unique ACTIVE claim index; inspection lifecycle atomic | BLOCKED — conflicts with catalogue row (unit→association→assignment/claim); claim/inspection ordering and takeover semantics open |
| CMD-027 | release-unit-claim | L0 → source says canonical unit → association → assignment → claim → inspection → L90 | CMD-026 claim/takeover/expiry; CMD-028–032 inspection lifecycle | Claim row_version and single terminal claim outcome | BLOCKED — assignment-before-unit candidate hierarchy differs from source; exact lock set/order and token/schema alignment open |
| CMD-028 | save-draft | L0 → inspection aggregate → active claim/association/assignment dependencies → response children → L90 | CMD-026/027 claim lifecycle; CMD-029 submit; CMD-035 sync; CMD-032 reopen | inspections.row_version CAS; pinned instrument version | BLOCKED — source aggregate-first order conflicts with parent/association rank proposal; exact child sort key/no-op behavior open |
| CMD-029 | submit-inspection | L0 → inspection aggregate → claim/association/assignment + evidence rows → revision allocation → immutable revision/events → L90 | CMD-028 save; CMD-030 return; CMD-031 approve; CMD-032 reopen; CMD-033 evidence; CMD-035 sync | Unique (inspection_id, revision_no); row_version CAS | BLOCKED — dependency lock order and evidence finalization race must align; event cardinality/source table open |
| CMD-030 | return-inspection | L0 → inspection aggregate → target revision → review decision key → L90 | CMD-031 approve; CMD-029 submit; CMD-032 reopen | One terminal review decision per revision; immutable revision | BLOCKED — exact review decision uniqueness constraint and shared inspection/revision order need approval |
| CMD-031 | approve-inspection | L0 → inspection aggregate → validate exact current revision/reviewer assignment → review_events/inspection_events/audit/idempotency | CMD-030 return; CMD-032 reopen; competing approval | Current submitted revision and one terminal decision; physical unique arbiter to verify | BLOCKED — detailed review requires aggregate lock; exact child row locks and unique terminal decision constraint must be made explicit |
| CMD-032 | reopen-inspection | L0 → inspection aggregate → validate approved revision and active-work blockers → inspection_events/audit/idempotency | CMD-031 approve; CMD-028–030; CMD-033/036 finalizers | expected_row_version; immutable approved history | BLOCKED — blocker lock set, claim/association dependency order and worker finalization race unresolved |
| CMD-033 | create-upload-intent | L0 → inspection aggregate → quota/reservation row if policy requires → pending evidence metadata → L90; upload authorization after commit | CMD-027 release; CMD-029 submit; CMD-032 reopen; concurrent upload/quota | Pending intent uniqueness/quota constraint not finalized | BLOCKED — exact quota row and evidence key/index contract open; never hold locks during Storage token/I/O |
| CMD-034 | confirm-upload | External Storage object inspection first (no DB lock) → L0 → evidence row → revalidate inspection/claim/assignment → finalize evidence/audit | CMD-033 intent expiry; CMD-027 release; CMD-029 submit; object replacement | Immutable object key/checksum after finalization; metadata comparison | BLOCKED — evidence-vs-inspection lock order and Storage TOCTOU policy require approved contract |
| CMD-035 | sync-batch | L0 → inspection rows sorted deterministically (or separately committed operation transactions/savepoints) → operation-specific child writes → L90 | CMD-028–032 online operations; same-device duplicate/replay | expected_row_version per operation; operation_id idempotency | BLOCKED — source explicitly allows short per-operation transactions or savepoints; choose one; multi-inspection sorting and batch atomicity need decision |
| CMD-036 | generate-approved-document | Short transaction: L0 → source/document generation key → PENDING document/job/outbox → L90; worker external render/Storage outside locks; short guarded finalize validates lease/source version | CMD-032 reopen; CMD-029/031 source revision; duplicate workers/retry | Unique generation request/source-template identity not fully specified; immutable source revision | BLOCKED — job/outbox/lease/worker identity/ACL and document source/template schema absent |
| CMD-037 | record-print | L0 → document aggregate/version row → allocate sequence → print_events/audit → L90 | CMD-038 batch; concurrent print/reprint same document | Unique (document_id, sequence_no) proposed; expected_sequence | BLOCKED — document version identity and sequence storage/allocator missing |
| CMD-038 | record-print-batch | Batch L0 and batch envelope → per item: authorization + document aggregate/version row → per-document sequence → print event/audit; no batch-wide lock during printing | CMD-037 print; retries/partial batch | Per-document idempotency/sequence; durable item manifest unclear | BLOCKED — print_batch_items/stable item identity/worker lease and partial recovery contract open |
| CMD-039 | upload-attendance-document | L0 → attendance record → quota/reservation if approved → pending document identity; Storage upload outside transaction → short finalize locks attendance + exact document | CMD-040 verify; concurrent replacement/upload | Immutable document identity/checksum; pending intent uniqueness not defined | BLOCKED — intent/finalize split, document version and institutional upload authority unresolved |
| CMD-040 | verify-attendance | L0 → attendance_records → exact attendance_documents row → L90 | CMD-039 replacement; concurrent verifier; assignment/account eligibility changes | expected_version field but physical token unspecified; immutable doc version | BLOCKED — institutional authority/SoD and version token absent; verify-vs-replace fence incomplete |
| CMD-041 | get-actual-report | Read-only scoped snapshot/query; no mutation lock specified | CMD-037/038 print events and source inspection lifecycle | Consistent read/snapshot semantics; no idempotency | PARTIAL — snapshot/isolation, pagination and read-time authorization details remain in read contract |
| CMD-042 | get-target-report | Read-only target plan/allocation query; no mutation lock specified | CMD-017 plan draft/publish; project/session lifecycle | Published plan immutability and report version pinning | PARTIAL — read consistency and draft-vs-published selection semantics open |
| CMD-043 | read-audit | Read-only, purpose-bound query; no row locks over response serialization | Audit appenders; T-10 reader authority | Scope/purpose/filter constraints; T-10 authority absent | BLOCKED — institutional read authority, classification, retention and snapshot semantics open |
| CMD-044 | export-audit | BLOCKED; proposed short transaction for request/job only, then worker snapshot/render outside locks | Audit appenders; legal hold/retention; duplicate export requests | Idempotent request/hash and immutable watermark/manifest proposed | BLOCKED_BY_T10 — no request/job/worker/schema/authority may be assumed |
| CMD-045 | retention/legal-hold | BLOCKED; no approved lock manifest | Hold/release vs disposition/delete across DB, Storage, backups and providers | No approved physical model or institutional policy | BLOCKED_BY_POLICY — do not design or implement lock protocol until authority/schema approved |
| CMD-046 | review-security-incident | BLOCKED; no approved lock manifest | Concurrent incident review/action and evidence custody | No approved security-case model or designated authority | BLOCKED_BY_SCHEMA_AUTHORITY — do not infer case row or lock order |
| CMD-047 | manage-provider-configuration | BLOCKED; future provider change outside DB transaction with durable orchestration only if approved | Concurrent config version changes and provider API outcome | T-12 ownership and provider evidence absent | BLOCKED_BY_T12 — no provider settings or lock model approved |
| CMD-048 | manage-production-release | BLOCKED; release control remains GitHub/Vercel governed unless separate ADR | Concurrent release/rollback and migration compatibility | No application release schema or named release authority | BLOCKED_BY_AUTHORITY — no app RPC/lock path approved |
| CMD-049 | list-own-notifications | Recipient-owned MVCC read query; no mutation lock specified | CMD-052 fan-out creating inbox rows; CMD-050 read acknowledgement | Recipient RLS and stable pagination keys | PARTIAL — snapshot pagination semantics and safe delivery-field projection open |
| CMD-050 | mark-notification-read | Short idempotent transaction: one recipient-owned notifications row guarded set-once update; optional append-only access/domain audit only if approved | Concurrent mark-read; CMD-052 notification creation; delivery-state updates must remain separate | Conditional set-once read_at update; no notification row_version | PARTIAL — remove expected_version or approve token; exact audit requirement and set-once semantics open |
| CMD-051 | publish-notification-policy | Short policy-aggregate transaction: serialize exact draft/version and effective scope, publish immutable version, append audit fact | Concurrent draft edit/publish; scheduler CMD-054 reads policy version | Unique policy/scope/version and one effective version per interval proposed | BLOCKED — exact lock target/exclusion constraint, draft hash/version lifecycle and policy scope order open |
| CMD-052 | fanout-notification-outbox | Isolated short claim transaction on one bounded outbox row → persist lease/fencing generation → commit; separate fan-out transaction writes recipient notification/delivery rows using unique arbiters; no provider I/O | Duplicate fan-out, lease expiry/reclaim, CMD-049 inbox read, CMD-053 dispatch | Unique source_event_id/policy_version_id; unique outbox/recipient; unique notification/channel | BLOCKED — worker principal/ACL, lease owner/token/expiry, partial checkpointing and payload schema open |
| CMD-053 | dispatch-notification-delivery | Short claim transaction on exact delivery row and durable attempt identity → commit; provider I/O outside transaction; guarded outcome transaction revalidates exact lease generation and appends attempt result | Retry, callback/webhook, UNKNOWN reconciliation, lease reclaim | Attempt idempotency/provider key where supported; append-only attempt history | BLOCKED — callback command boundary, provider capability, worker identity/ACL and attempt unique key open |
| CMD-054 | evaluate-notification-escalation | Short scheduler transaction: server-UTC due check against pinned policy version and notification state → unique escalation arbitration → append escalation fact and outbox intent atomically; no source business-state mutation or provider I/O | Duplicate scheduler ticks, CMD-051 policy publish, CMD-052 fan-out | Unique notification/policy_version/step/event key proposed | BLOCKED — server UTC SLA clock, scheduler principal/ACL, due-time predicate and retry/unique contract open |

## 5. Cross-command lock-order findings

### 5.1 Confirmed documentation inconsistencies

1. **CMD-023 vs CMD-026:** CMD-023 states unit → project → association key. CMD-026 states canonical key → project/session/assignment → unit → association → inspection/claim. These are not yet a single canonical order.
2. **CMD-025 vs CMD-026:** CMD-025 states conflict row → candidate unit → project/association key; CMD-026 begins with canonical serial key and parent/assignment rows. Conflict identity rank and lock inversion are unresolved.
3. **CMD-027 vs candidate hierarchy:** CMD-027 states unit → association → assignment → claim → inspection, whereas the candidate hierarchy puts assignment before unit/association. Must be normalized by owner decision, not guessed.
4. **CMD-028–032:** inspection aggregate-first recipes are explicit, but they must be reconciled with the parent/assignment/association/claim order used by claim and association writers. Define a single protocol that does not acquire a lower-ranked parent after inspection.
5. **CMD-012/013 and CMD-023/024:** some source recipes lock child/aggregate before parent/dependencies. Parent closure commands can deadlock if the inverse path is retained.
6. **CMD-014/015/016:** T-14 capacity row is intended as the common serialization point, but all eligibility-changing paths (role grant/revoke/expiry, account suspension/disable, assignment membership add/end/expiry and cap change) are not yet fully enumerated.
7. **CMD-019/020/021/014:** instrument/version versus project/session/assignment relative ordering is not approved.
8. **CMD-033/034/036/039/040:** external Storage/render operations must remain outside DB locks; finalization must revalidate source, lease and immutable object/document version under the approved domain order.
9. **CMD-037/038:** print sequence must be allocated under one per-document serialization point; batch envelope must not become a global document lock.
10. **CMD-052/053/054:** worker queue claims, attempt outcomes and scheduler deduplication must use short transactions and trusted fencing; queue locks must not be held while acquiring domain locks or performing provider I/O.

### 5.2 Candidate lock manifest acceptance rules

A command manifest can be marked REVIEWED only when all are true:

- Every mutable row/key and invariant-bearing parent is listed.
- Source-stated order has been reconciled to the approved global hierarchy.
- All same-class multi-row targets have a deterministic sort key.
- Competing commands and background workers are listed.
- Authorization/scope/state/version/expiry predicates are rechecked after locks.
- Unique/check/FK/exclusion constraints and their exact columns/predicates are verified against approved physical schema.
- Implicit trigger, FK, uniqueness and helper-function lock behavior is reviewed.
- External I/O is outside database transactions; durable intent/lease/fencing and recovery are specified.
- Idempotency, audit atomicity and retry behavior are explicit.
- Adversarial concurrency tests pass on an authorized isolated database and evidence is attached to the exact revision.

No command currently meets all criteria based on the static source set.

## 6. Required decisions and owners

| ID | Decision/evidence | Owner | Status |
|---|---|---|---|
| LM-01 | Approve global rank order and relative rank of project/session, assignment/instrument, unit/association, claim/inspection and child aggregates | Engineering + Security + PO | OPEN |
| LM-02 | Resolve CMD-023/024/025/026/027 source-order conflicts and update catalogue rows only after approval | Engineering + Security | OPEN |
| LM-03 | Normalize CMD-028–032 aggregate/claim/revision/evidence/review lock order | Engineering + Security + PO | OPEN |
| LM-04 | Exhaustively enumerate T-14 eligibility-changing commands and use one capacity serialization protocol | PO + Engineering + Security | OPEN |
| LM-05 | Define project/session closure fence and enumerate all child writers/finalizers | PO + Engineering + Security | OPEN |
| LM-06 | Approve instrument/version/assignment lock interaction and deactivation guard | PO + Engineering + Security | OPEN |
| LM-07 | Approve evidence, document, print and attendance row/version identities and lock order | Engineering + Security; Institution for attendance | OPEN |
| LM-08 | Approve worker identities, queue lease/fencing, ACL and callback ingestion boundary | Security + Operations + provider owner | OPEN |
| LM-09 | Reconcile every lock manifest against exact physical constraints, triggers, FK and function call graph | Engineering + Database/Security | OPEN |
| LM-10 | Execute adversarial concurrent command-pair and deadlock tests on authorized isolated DB | Engineering + QA + Security | NOT EXECUTED |

## 7. Planned verification — NOT EXECUTED

Use LOCK-GRAPH-001 test groups LG-01–LG-30 as the minimum baseline. Add these command-specific assertions:

- **LM-T01:** assert every command's actual row-lock acquisition order matches the approved manifest.
- **LM-T02:** run each shared-resource command pair in both start orders with barriers; record completion, SQLSTATE, lock wait graph and final invariant.
- **LM-T03:** force uniqueness conflict and FK/trigger paths to validate implicit lock interactions.
- **LM-T04:** force audit append failure and verify full rollback of domain state, row_version, event and idempotency outcome.
- **LM-T05:** force deadlock/serialization failure and replay same idempotency key; prove no duplicate event or mutation.
- **LM-T06:** expire/reclaim worker lease while old worker is paused; old fencing token must be unable to finalize.
- **LM-T07:** pause external Storage/provider operation while unrelated DB transactions proceed; prove no DB row lock is held across I/O.
- **LM-T08:** race parent closure with every child writer and worker finalizer; no post-closure mutation may commit.
- **LM-T09:** race source revision/reopen with evidence/document finalization; artifact must bind only to exact immutable source revision.
- **LM-T10:** run the full adversarial matrix under the production-intended isolation level and bounded lock/statement timeouts.

All tests are PLANNED / NOT EXECUTED. No CI, local test, SQL, migration or database inspection was performed.

## 8. Gate disposition

| Gate | Status | Reason |
|---|---|---|
| G3 data/transaction | NOT READY | Source lock orders remain inconsistent and physical constraints are not verified |
| G4 security | NOT READY | Worker identity/ACL and runtime function privileges unverified |
| G5 API/command | NOT READY | 54 manifests inventoried, 0 certified lock-complete |
| G7 QA/evidence | NOT READY | Concurrency tests planned only |
| G9 scope freeze | NOT READY | LM-01–LM-10 and existing institutional/technical blockers remain |
| G10 implementation | NOT AUTHORIZED | No separate written implementation authorization |

**Final disposition:** LOCK-MANIFEST-001 provides a 54-command source-evidence inventory and identifies where a complete manifest cannot yet be established. It does not normalize conflicting orders, approve any command, prove deadlock freedom or authorize implementation.


## 9. Lock protocol decision-resolution proposal — 2026-11-24

[LOCK-PROTOCOL-DECISION-RESOLUTION-001](LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.2.3 provides a candidate global rank hierarchy and proposed resolutions for the source-order conflicts. It defines the required per-command manifest evidence, identifies PO-owned product-policy decisions separately from Engineering/Security technical approvals, and preserves the 54/54 inventory with 0/54 certified lock-complete.

The proposal does not amend command recipes, physical schema, constraints or runtime behavior. No tests or database inspection were performed. LM-01–LM-10 remain open/not executed; G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED.

## 4.1 CMD-001–010 row-level resource and lock normalization overlay — 2026-11-24

This overlay decomposes the first ten commands into mutable aggregates, unique arbiters, append-only facts and known competing paths. It does **not** invent a rank for identity/authorization rows. The source-stated sequences below are preserved as observations; candidate-rank mapping is only made where the current L00–L110 table has an explicit class.

| Command | Mutable resource(s) | Candidate rank mapping | Source-stated serialization / transaction boundary | Competing path and final arbiter | Normalization disposition |
|---|---|---|---|---|---|
| CMD-001 | Own app_users request/profile state; idempotency_records | L00 idempotency; app_users class UNDEFINED; audit_events L110 | Resolve actor from auth.uid(); create/update only own identity. For first profile creation, rely on unique app_users.auth_user_id insert/upsert conflict arbitration; do not assume a pre-existing row lock. Commit request state, idempotency result and account.requested fact atomically. | Concurrent first request for same Auth identity; unique auth_user_id is final arbiter. Auth signup/profile provisioning race and separate request-history entity remain unresolved. | PARTIAL — account lifecycle/entity and identity-row rank absent; no executable order certified. |
| CMD-002 | Target app_users approval state; immutable account_decisions; idempotency | L00; target account class UNDEFINED; decision/audit facts L110 | Lock exact target account row, revalidate eligible source state and actor/target SoD, conditionally transition, append one decision and audit fact in same transaction. Actor authorization must be derived from caller JWT and revalidated in the transaction. | CMD-003 reject and duplicate/concurrent approvals; conditional source-state transition plus a final unique terminal-decision invariant must arbitrate. Actor-grant revocation race and physical terminal uniqueness are unresolved. | PARTIAL — target account rank, actor authorization lock/snapshot contract and row-version/terminal uniqueness evidence absent. |
| CMD-003 | Target app_users rejection state; immutable account_decisions; idempotency | L00; target account class UNDEFINED; decision/audit facts L110 | Same target-account serialization protocol as CMD-002; lock the target row, conditionally transition and append immutable decision/audit atomically. | CMD-002 approve and competing reject; must share the exact same target-row lock and terminal-state predicate. | PARTIAL — same unclassified identity/authorization resource and physical terminal-decision gaps as CMD-002. |
| CMD-004 | Target app_users; user_roles grant; optional project scope; capacity row | L00; L10 when Inspector qualifying population changes; account/role-grant classes UNDEFINED; optional project parent L30 only if a concrete project-scoped rule requires it; audit L110 | If the operation changes T-14 eligibility, acquire the same project project_capacity_settings serialization row before any eligibility-changing account/role/membership row; then lock/revalidate all affected rows in a deterministic order and evaluate the canonical distinct-account predicate. Non-Inspector grant path still needs an approved grant-row order. | CMD-005, CMD-014, CMD-015, CMD-016 and account enable/disable/suspension/expiry paths. Role interval uniqueness/exclusion is not finalized. | PARTIAL — L10 capacity-first is required where applicable, but account/role-grant classes and same-rank order are undefined; do not map user_roles to L50 by analogy. |
| CMD-005 | Exact user_roles grant lifecycle; target/account and grantor authority; capacity row for Inspector revoke | L00; L10 for every Inspector eligibility reduction; user_roles/account classes UNDEFINED; audit L110 | Acquire the same capacity row before the eligibility-reducing grant mutation, then lock exact role grant and revalidate grantor ceiling, target state and last-admin policy. Lifecycle update, idempotency and audit are atomic; no hard delete. | CMD-004 grant, CMD-014/015 membership, CMD-016 cap change, and account suspension/expiry. Physical row_version is absent while request contains expected_version. | BLOCKED — no rank class for role/account rows; expected-version physical mismatch and complete eligibility-path inventory unresolved. |
| CMD-006 | Target app_users; grantor authorization; scope target; user_scope_grants | L00; project/session/location/team/assignment target may map to L30/L50 by actual entity; principal and scope-grant rows UNDEFINED; audit L110 | Source review says lock target principal then relevant scope/grant rows deterministically. Validate grantor delegation ceiling, target eligibility, scope-type compatibility and no-overlap policy in the same transaction. | CMD-007 revoke and overlapping grant for same user/scope/kind/ref/interval. Principal-first source order may conflict with parent-first scope fencing; no-overlap constraint and inheritance policy are unresolved. | PARTIAL — rank/order conflict cannot be resolved until LPR-11; no mechanical mapping. |
| CMD-007 | Exact user_scope_grants lifecycle; grantor authorization; dependent active-work policy if approved | L00; scope-grant row class UNDEFINED; dependent scope parent may be L30/L50; audit L110 | Lock exact grant row, revalidate authority over the grant's scope/type, update lifecycle without deletion and append audit atomically. | CMD-006 grant and concurrent duplicate revocation; downstream cache/session/assignment effects are not specified. expected_version has no physical version field. | BLOCKED — unclassified grant row, missing concurrency token and unresolved revocation propagation/dependent-work policy. |
| CMD-008 | New projects row; normalized project-code key; idempotency | L00; unique-code insert arbitration (no existing-row rank); append-only audit L110 | Normalize code using one approved canonical algorithm; insert using the unique normalized-code constraint as the final arbiter; do not rely on preflight SELECT. New project row is created within the same transaction as idempotency and audit. | Concurrent create with normalization/case variants; unique normalized-code index must reject one contender. Exact normalized-key expression/index remains a schema review item. | PARTIAL — insert arbitration is identified; canonical normalization/index expression and physical evidence remain open. |
| CMD-009 | Existing projects metadata aggregate; idempotency | L00 → L30 project row → L110 audit | Lock project row or use one conditional compare-and-swap update; compare expected token under serialization, update only allowlisted mutable metadata and increment the approved aggregate token exactly once. | CMD-010 close and CMD-011+ project-scoped child writers; project parent is the shared fence. Physical schema does not define projects.row_version, updated_at or updated_by despite request expected_version. | BLOCKED — L30 mapping is clear but CAS cannot be finalized until schema/token decision and parent-fence mode are approved. |
| CMD-010 | Existing projects lifecycle aggregate plus all closure blocker resources; idempotency | L00 → L30 project parent → dependent child classes in approved ascending order → L110 audit | Lock/fence the project parent first. All child commands/workers that create or advance project work must acquire the same parent fence before locking child resources, revalidate project state after any wait, then mutate. Closure evaluates a transactionally consistent blocker set and conditionally closes only if clear. Never rely on preflight-only reads, cascade-delete history or hold locks over external I/O. | CMD-009 metadata update; CMD-011 session creation; CMD-012/013 session transitions; CMD-014/015 assignments/members; all project-scoped commands/workers/finalizers. If child writers lock children before the parent, close-vs-child can deadlock or admit stale work. Exact blocker inventory and compatible parent lock modes are not approved. | BLOCKED — closure authority/blockers, parent-fence coverage, child lock order and project row-version token remain incomplete. |

### 4.1.1 Cross-command conclusions for CMD-001–010

1. **L00 is a common arbitration boundary, not a substitute for domain locks.** A matching replay must not repeat a mutation; authorization revalidation requirements remain command-specific.
2. **Identity/authorization rows are an explicit rank gap.** app_users, user_roles and user_scope_grants cannot be treated as append-only L110 facts or silently folded into L50 assignment/membership. LPR-11 is required before CMD-001–007 can be rank-normalized.
3. **T-14 capacity is a mandatory earlier serialization point** for every mutation that can change the qualifying Inspector population, including role grant/revoke and account eligibility changes. CMD-004/005 are not the complete eligibility writer inventory.
4. **CMD-002/003 must share one target-account transition protocol.** The terminal-decision uniqueness mechanism and actor authorization revocation race need explicit resolution.
5. **CMD-006/007 need an authorization freshness contract.** Grantor delegation and revocation effects cannot be reduced to locking only the target grant row without deciding how concurrent authorization changes are fenced.
6. **CMD-008 relies on a unique normalized-code arbiter**, not a preflight row lock.
7. **CMD-009/010 require a common project parent fence.** Every project-scoped child writer must lock the parent before child resources and revalidate project state after waiting; closure's complete blocker set and compatible lock modes remain OPEN.
8. All rank assignments in this overlay are candidate mappings only. No exact PostgreSQL lock mode, trigger/FK implicit lock, physical index, function call graph or runtime lock behavior was verified.

## 4.2 CMD-049–054 notification transaction boundary reconciliation — 2026-11-24

| Command | Logical mutable resource | Append-only fact / arbiter | Transaction boundary and unresolved evidence |
|---|---|---|---|
| CMD-049 | None; recipient-owned read projection only | Stable (created_at, id) ordering and actor/filter-bound cursor | MVCC/read consistency only; no row lock over response serialization. Cursor snapshot/watermark and RLS/index evidence remain unverified. |
| CMD-050 | One recipient-owned notification read projection | Optional L110 audit fact only if approved; set-once read_at is the state guard | One short guarded transaction; delivery state is separate. Remove expected_version or define an approved physical token; no version column is currently specified. |
| CMD-051 | Policy draft/version and effective scope | Immutable publish/audit fact; uniqueness/exclusion is final arbitration | One short policy transaction. Draft identity/hash, same-scope version allocation, interval exclusion and SoD remain open. |
| CMD-052 | Outbox lease claim, then recipient notification and delivery projections | Unique source-event/policy, outbox-recipient and notification-channel keys; append-only facts where approved | Claim/lease transaction commits before fan-out. Fan-out must checkpoint safely after partial progress. No queue lock is held during domain aggregate work or provider I/O. |
| CMD-053 | Exact delivery projection and lease generation | Append-only attempt identity/outcome; provider + event/attempt callback deduplication | Claim and guarded outcome are short transactions; provider I/O is outside. Callback ingestion is a separately authenticated boundary whose logical command mapping remains unresolved. |
| CMD-054 | Pinned policy/notification due-state read and outbox intent | Unique notification/policy-version/step/window escalation fact | One short scheduler transaction uses server UTC and atomic event/outbox insertion. Scheduler principal, due-time semantics and exact unique key remain open. |

These rows reconcile logical resource/transaction boundaries only. The queue tables, policy/inbox/delivery physical keys, indexes, FK/trigger edges, worker principals, function owners, EXECUTE ACLs and provider callback runtime are not verified. Queue claim rows must never remain locked while external I/O occurs. If a worker ever mutates a source domain aggregate, it must separately reacquire the full approved parent/source lock chain and validate fencing; no such source mutation is authorized by CMD-049–054.
