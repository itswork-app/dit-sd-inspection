# Command-Level Lock Manifest Reconciliation — CMD-001–054

**Document ID:** LOCK-MANIFEST-001  
**Version:** 0.4.17
**Status:** Engineering reconciliation proposal — review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Parent:** LOCK-GRAPH-001 v0.4.10  
**Scope:** Per-command resource inventory, source-stated lock sequence, shared invariants, competing commands, constraints and unresolved ordering  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT ACTIVE.

## 1. Executive conclusion

This document converts the current command reviews into a 54-row lock manifest inventory. It records only resource and ordering facts that are explicitly present in the reviewed command documents, and labels missing or contradictory information as OPEN. It is not a normalized, approved lock plan.

**Critical result:** 54/54 logical command IDs are represented in the inventory, but **0/54 are certified lock-complete**. The manifest is an evidence and reconciliation artifact, not a proof of deadlock freedom. In particular, source-stated lock order conflicts remain in CMD-023/024/025/026/027/028, and CMD-031–040 contain further aggregate/child and external-effect boundaries requiring cross-check against the global candidate ranks.

No command catalogue, physical schema, function, API, migration or runtime behavior is changed by this document.

## 2. Authority, source set and method

Root `AGENTS.md` v1.2.0 was re-read from the target branch at the start of this work session. The source baseline below records the exact reviewed snapshot used for this reconciliation checkpoint on 2026-11-24 (it is not a live pointer to later document edits):

| Source | Reviewed snapshot version / identity | Use in this reconciliation |
|---|---|---|
| MIB-001 | v1.0.1 | Authority, gates and documentation-phase boundary |
| DGA-001 | v1.11.10 | Active evidence-backed gap queue and gate disposition |
| IRG-001 | v1.0.1 | Phase and authorization governance |
| Decision Register | Current branch revision | Approved PO decisions and institutional dependencies |
| PostgreSQL Command Contract Catalogue | v0.4.1 | Canonical logical CMD-001–054 operation inventory and proposed contracts |
| Physical Database Schema and Integrity Specification | v0.3.0 | Proposed entities, constraints, indexes and transaction invariants |
| LOCK-GRAPH-001 | v0.4.6 | Candidate resource ranks, cross-command conflicts and planned race scenarios |
| CONCURRENCY-001 | v0.1.3 | Aggregate token, idempotency and worker-fencing mismatches |
| LOCK-PROTOCOL-DECISION-RESOLUTION-001 | v0.3.4 | LPR decision state and static reconciliation checkpoint |
| Detailed command reviews | Seven current command-range documents; CMD-001–010 review v0.3.2 at this checkpoint | Per-command source-stated operations and dependencies |

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

CMD-001–010 now have a separate candidate-normalized overlay in §7 and in CMD-001–010 Detailed Contract Review v0.3.4. CMD-011–048 retain legacy inventory notation pending per-command normalization. Those labels preserve source-order observations and must not be used as executable lock instructions.

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

The current candidate ranks include L00 idempotency, L10 shared invariant, L15 principal/account, L16 user-role, L17 user-scope grant, L18 mutable authorization catalog (conditional), L20 canonical identity, L30 project/session, L40 instrument/version, L50 assignment/operational grouping, L55 assignment membership, L60 canonical unit, L70 association, L80 claim, L90 inspection, L100 dependent mutable aggregates, and L110 append-only facts. These remain proposals, not an approved lock order. CMD-001–010 are candidate-normalized against these ranks in §7; LPR-01/LPR-07/LPR-11 approval and physical evidence remain open.

CMD-011–048 legacy labels are intentionally not mechanically rewritten in this checkpoint because that would conceal unresolved source-order conflicts and the L40/L70 one-to-many mappings. They remain OPEN for per-command normalization. CMD-049–054 use explicit resource/transaction descriptions below rather than legacy rank labels. A dash means the source does not specify a row lock; it does not mean implicit database locking is absent.

## 4. CMD-001–054 command-level inventory

| Command | Logical operation | Source-stated lock/resource sequence | Shared invariant / competing path | Constraint or final arbiter stated in source | Status / unresolved manifest item |
|---|---|---|---|---|---|
| CMD-001 | request-account-access | Candidate: L00 → L15 caller `app_users`; absent row uses unique `auth_user_id` insert/upsert arbiter | Concurrent first request; CMD-002/003 decision | Unique `auth_user_id`; canonical request-state arbiter | CANDIDATE-NORMALIZED — account-request entity/lifecycle and implicit UPSERT/trigger edges OPEN |
| CMD-002 | approve-account | Candidate: L00 → conditional L10 capacity rows if login-enabled eligibility changes → L15 actor/target principals sorted → L16/L17 actor authority rows → L18 catalog; L110 decision/audit | CMD-003 same-target race; authority revoke; capacity-changing account lifecycle | Conditional target-account state transition + unique decision identity | CANDIDATE-NORMALIZED — account state table, affected-project set, version and decision uniqueness OPEN |
| CMD-003 | reject-account | Candidate: same as CMD-002; conditional L10 if T-14 eligibility changes; L15 sorted principals; L16/L17 actor authority; L18 catalog; L110 decision/audit | CMD-002 same-target race; grantor revocation; account eligibility | Shared target-account transition and decision arbiter | CANDIDATE-NORMALIZED — rejectable states, no-cascade and terminal uniqueness OPEN |
| CMD-004 | grant-role | Candidate: L00 → L10 if Inspector eligibility changes → L15 actor/target sorted → L16 actor/target role rows sorted → L17 delegation scope rows → L18 catalog → L110 audit | CMD-005/014/015/016; account eligibility; concurrent grantor revocation | Unique/exclusion principal-role-scope interval arbiter | CANDIDATE-NORMALIZED — role scope, interval constraint, capacity row and catalog mutability OPEN |
| CMD-005 | revoke-role | Candidate: L00 → L10 if Inspector eligibility reduction → L15 actor/target sorted → L16 actor authority + exact target grant sorted → L17 delegation scope → L18 catalog → L110 audit | CMD-004/014/015/016; account suspension/expiry; duplicate revoke | Conditional target-grant lifecycle update | CANDIDATE-NORMALIZED — `expected_version` lacks physical `user_roles.row_version`; last-admin and revocation representation OPEN |
| CMD-006 | grant-scope | Candidate: L00 → conditional L10 → L15 principals → L16 if role authority → L17 grants → L18 catalog → L30/L50 scope target → L110 audit | CMD-007, duplicate grants, parent closure/change | Unique/exclusion scope interval arbiter | CANDIDATE-NORMALIZED — scope mapping, Inspector predicate and interval constraint OPEN |
| CMD-007 | revoke-scope | Candidate: L00 → conditional L10 if revocation changes T-14 → L15 principals sorted → L16 if needed → L17 actor authority + exact target grant sorted → L18 if needed → L30/L50 scope parent only if required → L110 audit | CMD-006 grant; concurrent revoke; protected commands using grant | Conditional lifecycle update of exact scope grant | CANDIDATE-NORMALIZED — physical version token, expiry and authorization freshness OPEN |
| CMD-008 | create-project | Candidate: L00 → L15 actor → L16/L17 authority → L18 catalog → L30 unique normalized-code arbiter + project insert; initialize default capacity row in same transaction as a new project | Concurrent same normalized code; capacity-row bootstrap | Unique normalized project code; unique project capacity row | CANDIDATE-NORMALIZED — normalization/collation, capacity bootstrap and trigger/FK edges OPEN |
| CMD-009 | update-project | Candidate: L00 → L15 actor → L16/L17 project authority → L18 catalog → L30 project `FOR NO KEY UPDATE` + CAS | CMD-010 close; CMD-011–054 project child writers/finalizers | Project row lock + approved CAS token | CANDIDATE-NORMALIZED — project row_version/updated metadata absent; timezone semantics OPEN |
| CMD-010 | close-project | Candidate: L00 → conditional L10 if T-14 eligibility changes → L15 actor → L16/L17 project.close authority → L18 catalog → L30 project `FOR NO KEY UPDATE`; evaluate blockers behind parent fence | CMD-009; CMD-011–054 child writers/finalizers | Project parent fence + complete blocker predicates; no cascade | CANDIDATE-NORMALIZED — closure gates, T-14 effect, pending work, row_version and child-fence coverage OPEN |
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
| CMD-049 | list-own-notifications | Recipient-owned MVCC read query; no mutation lock specified | CMD-052 fan-out creating inbox rows; CMD-050 read acknowledgement | Recipient RLS and stable (created_at, id) pagination keys | PARTIAL — exact index plan, maximum page size and live RLS evidence open; no cross-page snapshot is claimed |
| CMD-050 | mark-notification-read | Short idempotent transaction: one recipient-owned notifications row guarded set-once update; first transition appends notification.read atomically | Concurrent mark-read; CMD-052 notification creation; delivery-state updates must remain separate | Conditional set-once read_at update; no notification row_version | PARTIAL — documentation contract aligned; exact audit implementation and RLS/ACL verification open |
| CMD-051 | publish-notification-policy | Short policy/scope transaction: compare expected current published version, allocate next version, publish immutable document and append audit fact | Concurrent publish; scheduler CMD-054 reads pinned policy version | Unique policy/scope/version and one effective version per interval proposed | BLOCKED — exact lock target/exclusion constraint, policy scope order and permission/SoD open; persisted draft CRUD excluded |
| CMD-052 | fanout-notification-outbox | Isolated short claim transaction on one bounded outbox row → persist owner/token-hash/generation/expiry fencing tuple → commit; separate fan-out transaction writes recipient notification/delivery rows using unique arbiters; no provider I/O | Duplicate fan-out, lease expiry/reclaim, CMD-049 inbox read, CMD-053 dispatch | Unique source_event_id/policy_version_id; unique outbox/recipient; unique notification/channel; safe_payload | BLOCKED — worker principal/ACL and recipient eligibility timing remain open; lease/payload vocabulary aligned at documentation level |
| CMD-053 | dispatch-notification-delivery | Short claim transaction on exact delivery row and durable attempt identity → commit; provider I/O outside transaction; guarded outcome transaction revalidates owner/token-hash/generation/expiry and appends attempt result | Retry, INT-NOTIF-001 callback ingress, UNKNOWN reconciliation, lease reclaim | Attempt idempotency/provider key where supported; append-only attempt history | BLOCKED — provider capability, callback-specific durable dedup/auth and worker identity/ACL remain open |
| CMD-054 | evaluate-notification-escalation | Short scheduler transaction: capture one DB UTC instant; due check against pinned policy version and notification state → unique escalation arbitration → append escalation fact and outbox intent atomically; no source business-state mutation or provider I/O | Duplicate scheduler ticks, CMD-051 policy publish, CMD-052 fan-out | Unique notification/policy_version/step/event key proposed; no caller evaluation_time | BLOCKED — SLA start/pause/calendar semantics and scheduler principal/ACL remain open |

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

## 4.1 Historical CMD-001–010 source-order overlay — superseded by §7

Historical note: this source-order extraction is retained for audit traceability only. Its statements that L15–L18 are unclassified and CMD-001–007 cannot be candidate-normalized are superseded by the candidate overlay in §7 and CMD-001–010 Detailed Contract Review v0.3.3 §9. This historical table is not an executable order.

| Command | Mutable resource(s) | Candidate rank mapping | Source-stated serialization / transaction boundary | Competing path and final arbiter | Normalization disposition |
|---|---|---|---|---|---|
| CMD-001 | Own app_users request/profile state; idempotency_records | Candidate L00 → L15 own app_users if present; absent row uses unique auth_user_id insert/upsert arbiter; L110 audit | Resolve actor from auth.uid(); own identity only; reject privilege-bearing fields; atomically commit canonical request state, idempotency and account.requested | Concurrent first request and CMD-002/003; unique auth_user_id plus approved request lifecycle | CANDIDATE-NORMALIZED — request entity/lifecycle and implicit UPSERT/trigger edges OPEN; not certified |
| CMD-002 | Actor + target app_users; actor authority grants; account_decisions | Candidate L00 → conditional L10 → L15 sorted actor/target → L16/L17 actor grants → L18 catalog → L110 decision/audit | Revalidate active approver, global authority, actor != target and target source state after locks; conditional state transition and decision/audit/idempotency atomic | CMD-003, concurrent approvals, actor grant revocation; target row and unique terminal decision arbiter | CANDIDATE-NORMALIZED — account state/eligibility map, capacity project set, row version and decision uniqueness OPEN |
| CMD-003 | Actor + target app_users; actor authority grants; account_decisions | Candidate same as CMD-002; L10 only when rejection changes T-14 eligibility | Revalidate active approver, actor != target, rejectable source state and mandatory reason; no implicit role/scope revocation; atomic decision/audit/idempotency | CMD-002 approve and concurrent reject; shared target row and terminal decision arbiter | CANDIDATE-NORMALIZED — rejectable states, capacity effect, row version and terminal uniqueness OPEN |
| CMD-004 | Actor/target principals; user_roles; grantor scope; role catalogue | Candidate L00 → L10 if Inspector eligibility changes → L15 sorted principals → L16 sorted actor/target grants → L17 delegation grants → L18 catalog → L110 audit | Revalidate grantor ceiling, target eligibility, role/scope and interval; T-14 count under L10; no self-grant | CMD-005/014/015/016 and account eligibility; unique/exclusion principal-role-scope interval | CANDIDATE-NORMALIZED — scope, interval, capacity row, role history and catalogue mutability OPEN |
| CMD-005 | Actor/target principals; exact user_roles grant; grantor scope | Candidate L00 → L10 if Inspector eligibility reduction → L15 sorted principals → L16 exact grants → L17 delegation scope → L18 catalog → L110 audit | Revalidate exact revocation authority, active grant, last-admin rule and capacity count; lifecycle update, idempotency and audit atomic | CMD-004/014/015/016, account suspension/expiry, duplicate revoke; conditional target-grant update | CANDIDATE-NORMALIZED — expected_version has no physical user_roles.row_version; last-admin and revocation representation OPEN |
| CMD-006 | Actor/target principals; user_scope_grants; scope parent | Candidate L00 → conditional L10 if T-14 changes → L15 sorted principals → L16 if role authority → L17 sorted grants → L18 catalog → L30/L50 target scope → L110 audit | Revalidate grantor ceiling, target, fixed scope-type mapping, parent relation, inheritance prohibition and validity interval | CMD-007, overlapping grant, scope-parent closure/change; unique/exclusion scope interval | CANDIDATE-NORMALIZED — physical scope map, Inspector mapping and interval arbiter OPEN |
| CMD-007 | Actor/target principals; exact user_scope_grants; scope parent if authority needs it | Candidate L00 → conditional L10 → L15 sorted principals → L16 if needed → L17 exact actor/target grants → L18 if needed → L30/L50 parent → L110 audit | Revalidate exact revocation ceiling and target grant; no hard delete; define effective time and authorization cache freshness | CMD-006 grant, duplicate revoke, protected commands relying on grant; conditional lifecycle update | CANDIDATE-NORMALIZED — expected_version lacks physical row_version; propagation and active-work policy OPEN |
| CMD-008 | New project + normalized code + capacity settings | Candidate L00 → L15 actor → L16/L17 authority → L18 catalog → L30 unique code insert; create default capacity row atomically in same transaction | Revalidate project-create authority, code normalization and timezone; project and T-14 capacity row commit/rollback together | Concurrent normalized-code create; unique code and unique project-capacity arbiters | CANDIDATE-NORMALIZED — code normalization, capacity bootstrap and trigger/FK edges OPEN |
| CMD-009 | Existing projects metadata aggregate; idempotency | Candidate L00 → L15 actor/authority → L30 project FOR NO KEY UPDATE + CAS | Revalidate project.manage, editable state, allowlisted patch and timezone semantics; increment approved aggregate token atomically | CMD-010 close; CMD-011–054 child writers; project row is shared fence | CANDIDATE-NORMALIZED — projects.row_version/updated metadata absent; CAS contract OPEN |
| CMD-010 | Existing projects lifecycle aggregate + blocker set; idempotency | Candidate L00 → conditional L10 if T-14 affected → L15/L16/L17/L18 authority → L30 project FOR NO KEY UPDATE → blocker evaluation behind parent fence | Revalidate project.close, project state, complete blocker set and pending durable intents; no dependent cascade; child writers must take project FOR SHARE | CMD-009 and CMD-011–054 child/finalizer paths; project parent fence | CANDIDATE-NORMALIZED — blocker authority, T-14 effect, pending work, CAS and all child-fence coverage OPEN |

### 4.1.1 Cross-command conclusions for CMD-001–010

1. **L00 is a common arbitration boundary, not a substitute for domain locks.** A matching replay must not repeat a mutation; authorization revalidation requirements remain command-specific.
2. **Identity/authorization rows require explicit ranks.** The current candidate overlay proposes L15 app_users, L16 user_roles, L17 user_scope_grants and conditional L18 authorization catalog. LPR-11 approval remains OPEN; see §7.
3. **T-14 capacity is a mandatory earlier serialization point** for every mutation that can change the qualifying Inspector population, including role grant/revoke and account eligibility changes. CMD-004/005 are not the complete eligibility writer inventory.
4. **CMD-002/003 must share one target-account transition protocol.** The terminal-decision uniqueness mechanism and actor authorization revocation race need explicit resolution.
5. **CMD-006/007 need an authorization freshness contract.** Grantor delegation and revocation effects cannot be reduced to locking only the target grant row without deciding how concurrent authorization changes are fenced.
6. **CMD-008 relies on a unique normalized-code arbiter**, not a preflight row lock.
7. **CMD-009/010 require a common project parent fence.** Every project-scoped child writer must lock the parent before child resources and revalidate project state after waiting; closure's complete blocker set and compatible lock modes remain OPEN.
8. All rank assignments in this overlay are candidate mappings only. No exact PostgreSQL lock mode, trigger/FK implicit lock, physical index, function call graph or runtime lock behavior was verified.

## 4.1.2 Project/session parent-fence cross-check — CMD-010–015 — 2026-11-24

The first-ten-command overlay depends on a project-parent fence. Static comparison with CMD-011–015 shows that the child-writer side is not yet consistently specified:

| Command | Source-stated sequence in detailed review | Parent-fence finding |
|---|---|---|
| CMD-011 create-session | L00 → lock project FOR KEY SHARE (or approved equivalent) → validate project state → insert session | The exact mode is explicitly open. PostgreSQL documents that FOR KEY SHARE does not conflict with FOR NO KEY UPDATE, and an UPDATE that does not modify key columns normally acquires FOR NO KEY UPDATE. Therefore a plain project status UPDATE by CMD-010 is not proven to conflict with CMD-011's proposed FOR KEY SHARE. The closure protocol needs an explicitly compatible/conflicting lock design, not a generic "parent lock" label. |
| CMD-012 update-session | L00 → lock session row → resolve parent project → validate state/version → update | Session-first order conflicts with the candidate project-before-session parent hierarchy. A concurrent project closure that locks project then session can deadlock against this reverse path. |
| CMD-013 transition-session | L00 → lock session row → validate state/authorization → lock or snapshot closure dependencies | The source recipe does not acquire the project parent before the session row. Project/session closure and child mutation order remains unresolved. |
| CMD-014 publish-assignment | L00 → L10 capacity when applicable → project/session/assignment reference rows in deterministic UUID order → affected users → insert assignment/members | This is the closest parent-first recipe, but exact cross-table comparator, lock modes, and whether all parent rows are locked rather than merely read must be specified. |
| CMD-015 change-assignment-members | L00 → L10 capacity when applicable → assignment row → assignment_members and user rows | No explicit project/session parent fence is stated before the assignment/member mutation. Session/project closure can race unless the parent fence is added in an approved order. |

### Required closure protocol decisions

1. Every project/session child writer must acquire the approved parent fence before any child aggregate lock, then re-read/revalidate parent lifecycle state after any wait.
2. CMD-012/013 must be redesigned or explicitly justified so they do not lock session first and project later.
3. CMD-014/015 must explicitly identify which project/session parent rows are locked, not only read for validation.
4. CMD-010 must use a parent lock mode or serialization primitive that conflicts with every child-writer fence. In particular, do not assume an ordinary non-key UPDATE conflicts with a child FOR KEY SHARE lock.
5. The close transaction must acquire parent fence before blocker child rows; child writers must acquire parent fence before child rows. This avoids the parent→child versus child→parent cycle, but only if every writer participates.
6. After acquiring the parent fence, re-evaluate all blockers under a transactionally consistent policy. A preflight SELECT alone is not a closure fence.

**Technical reference:** PostgreSQL, Explicit Locking, §13.3.2 Row-Level Locks and Table 13.3 (lock conflicts): https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS. The documented FOR KEY SHARE / FOR NO KEY UPDATE compatibility must be checked against the exact PostgreSQL major version deployed by the institution. This is documentation evidence, not live database evidence.

**Disposition:** project/session parent fencing remains OPEN. No exact lock mode is approved, and no command is certified lock-complete by this cross-check.

## 4.2 CMD-049–054 notification transaction boundary reconciliation — 2026-11-24

| Command | Logical mutable resource | Append-only fact / arbiter | Transaction boundary and unresolved evidence |
|---|---|---|---|
| CMD-049 | None; recipient-owned read projection only | Stable (created_at, id) ordering and actor/filter-bound cursor | MVCC/read consistency only; no row lock over response serialization. Cursor snapshot/watermark and RLS/index evidence remain unverified. |
| CMD-050 | One recipient-owned notification read projection | First transition appends notification.read atomically; no page-read event | One short guarded transaction; delivery state is separate. No expected_version or row_version; read_at IS NULL is the state guard. |
| CMD-051 | Candidate policy document and effective scope | Immutable publish/audit fact; uniqueness/exclusion is final arbitration | One short publish-only transaction. Server hash/version; expected current version compare; exact lock/exclusion and SoD remain open. Persisted draft CRUD excluded. |
| CMD-052 | Outbox lease claim, then recipient notification and delivery projections | Unique source-event/policy, outbox-recipient and notification-channel keys; append-only facts where approved | Claim/lease transaction commits before fan-out. Fan-out must checkpoint safely after partial progress. No queue lock is held during domain aggregate work or provider I/O. |
| CMD-053 | Exact delivery projection and lease generation | Append-only attempt identity/outcome; provider event dedup through INT-NOTIF-001 | Claim and guarded outcome are short transactions; provider I/O is outside. Callback ingress is INT-NOTIF-001; provider-specific auth and durable dedup implementation remain open. |
| CMD-054 | Pinned policy/notification due-state read and outbox intent | Unique notification/policy-version/step/window escalation fact | One short scheduler transaction uses server UTC and atomic event/outbox insertion. Scheduler principal, due-time semantics and exact unique key remain open. |

These rows reconcile logical resource/transaction boundaries only. The queue tables, policy/inbox/delivery physical keys, indexes, FK/trigger edges, worker principals, function owners, EXECUTE ACLs and provider callback runtime are not verified. Queue claim rows must never remain locked while external I/O occurs. If a worker ever mutates a source domain aggregate, it must separately reacquire the full approved parent/source lock chain and validate fencing; no such source mutation is authorized by CMD-049–054.


## 6. Historical technical resolution overlay — superseded by §§7 and 8

[TECH-RESOLUTION-LPR-001](ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) §7 defines the required normalized manifest schema. This historical note is retained for provenance. The current CMD-001–010 candidate normalization is in §7; current technical source versions and approvals remain as stated in §8. L15–L18 ranks, project/session fence modes, implicit database lock edges, worker identities/fencing and pairwise evidence remain technically unapproved/unverified. Baseline remains 54/54 INVENTORIED, 10/54 CANDIDATE-NORMALIZED and 0/54 CERTIFIED; LPR-09 OPEN; LPR-10 NOT EXECUTED.


## 7. Current source-version and rank synchronization — 2026-11-24

Current linked candidate sources: LOCK-GRAPH-001 v0.4.10; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.8; CMD-011–020 Detailed Contract Review v0.3.6; PostgreSQL Command Contract Catalogue v0.4.1; CONCURRENCY-001 v0.1.3; TECH-RESOLUTION-LPR-001 v0.1.0. The refined L15–L18 identity/authorization and L55 membership classes are candidate ranks only. This source refresh does not normalize or certify any of the 54 rows: 54/54 remain INVENTORIED; 0/54 CERTIFIED.


**Parent reference note:** this manifest was refreshed against LOCK-GRAPH-001 v0.4.7; the source-version table in §7 is a dated review snapshot, not a live version pointer. Subsequent parent edits require a new explicit review checkpoint.


## 7. CMD-001–010 candidate-normalized lock overlay — 2026-11-24

The authoritative per-command candidate sequence and revalidation contract is **CMD-001–010 Detailed Contract Review v0.3.3 §9**. The ten inventory rows above now point to that overlay. This is a candidate documentation normalization only.

### 7.1 Shared ordering rules

- L00 idempotency precedes domain locks.
- L10 capacity rows, where the T-14 predicate can change, precede L15–L18 and are sorted by project UUID. A locator read may identify candidate projects; the set must be revalidated after L10. A late newly discovered capacity row requires abort/retry.
- L15 principal rows are sorted by user UUID; actor and target are not actor-first.
- L16 user-role grants, L17 user-scope grants, and conditional L18 role/permission catalogue rows use declared immutable tuple/key ordering.
- L30 project/session parents follow identity/authorization ranks; project before session. Project child writers use candidate FOR SHARE; project updates/closure use candidate FOR NO KEY UPDATE. Exact PostgreSQL compatibility and all hidden lock edges remain open.
- L50 scope/operational grouping rows follow parent locks. L110 facts are appended only after mutable-state validation.
- A new project may bootstrap its T-14 capacity row in the same transaction as project creation. This is a narrowly scoped new-aggregate initialization exception: the project and capacity row are not externally visible until commit; the unique parent/capacity constraints and trigger/FK lock edges still require Database review.

### 7.2 Normalization count and residuals

**10/54 command manifests candidate-normalized at documentation level; 0/54 technically approved or lock-complete certified.** CMD-011–054 remain pending their own per-command normalization. The candidate hierarchy is not yet proven acyclic. No physical PostgreSQL inventory, transaction trace or concurrency test was executed.


## 8. Current source-version checkpoint — 2026-11-24

The CMD-001–010 candidate overlay in §7 supersedes the historical source-order extraction in §4.1 and the earlier technical overlay in §6. Current linked sources: CMD-001–010 Detailed Contract Review v0.3.3; LOCK-GRAPH-001 v0.4.7; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.5; PostgreSQL Command Contract Catalogue v0.4.1; DGA-001 v1.11.11; TECH-RESOLUTION-LPR-001 v0.1.0. The manifest source list is a dated review snapshot, not a live pointer. 54/54 remain inventoried; 10/54 candidate-normalized; 0/54 technically approved/certified.


**Current linked source refresh:** CMD-001–010 review v0.3.4; LOCK-GRAPH-001 v0.4.8; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.6; DGA-001 v1.11.12; QA Catalogue v0.3.2. The §2 source snapshot remains the original review baseline and is not rewritten as a live pointer.


**Version baseline note:** the current linked-source versions above are the reviewed checkpoint for this document revision; later DGA/crosswalk edits do not retroactively change the evidence boundary.


## CMD-049–054 notification contract field alignment — 2026-11-24

The current candidate request/transaction overlay is synchronized to NLA-001 v0.1.2 and CMD review v0.1.1: CMD-050 has no expected_version; CMD-052/053 use the same lease owner/token-hash/generation/expiry fencing tuple; CMD-053 provider callbacks use INT-NOTIF-001; CMD-054 uses one database UTC instant and no caller evaluation_time. These changes clarify logical contracts only. They do not normalize additional command lock manifests or approve the effective lock graph. DGA-B19 remains OPEN; 10/54 candidate-normalized and 0/54 technically approved/certified.


## Current parent snapshot correction — 2026-11-24

The manifest header parent pointer is updated to LOCK-GRAPH-001 v0.4.10, the current candidate graph reviewed for this audit. Historical source-version tables and dated checkpoint notes remain historical snapshots and are not silently rewritten. The parent graph remains unapproved; 10/54 manifests are candidate-normalized at documentation level and 0/54 are technically approved/certified.


## Conditional Product Owner authorization status synchronization — 2026-11-24

The Product Owner's explicit conditional implementation authorization is recorded in the canonical Decision Register. It permits transition toward implementation from zero using the SSOT baseline, subject to G9 closure and a separate G10 activation record. **Current status: G9 NOT READY; G10 NOT ACTIVE.** This status synchronization does not approve this technical proposal, any lock mode, permission, function ACL, migration or runtime behavior. Technical and institutional approval boundaries stated in this document remain unchanged.


## 7.2 CMD-011–020 candidate lock-order overlay — 2026-11-24

This overlay advances the static reconciliation of CMD-011–020 using the command-specific transaction and read/write sections in CMD-011–020 Detailed Contract Review v0.3.6, the candidate ranks in LOCK-GRAPH-001 v0.4.10, and the current PO-approved semantic decisions. It is a **candidate documentation overlay only**. It does not approve lock modes, physical constraints, SQL, function privileges, or implementation. Any unresolved resource rank or competing writer is explicitly retained as a blocker; no legacy label is promoted to an executable instruction.

| Command | Candidate ordered resource sequence | Required revalidation / invariant | Unresolved boundary |
|---|---|---|---|
| CMD-011 create-session | L00 idempotency → L30 project parent fence → create session aggregate → L110 audit/idempotency result | Revalidate project lifecycle after parent-lock wait; normalize code; unique (project_id, code) is final duplicate arbiter; server selects DRAFT; UTC instants derived from canonical project IANA timezone | Exact project lock mode, project/session FK/trigger edges, project lifecycle enum, timestamp precision and uniqueness behavior require Engineering/Database approval and PostgreSQL verification |
| CMD-012 update-session | L00 → L30 project parent fence → session aggregate → dependent assignment/work rows only under an approved deterministic order → L110 | Project before session; revalidate lifecycle and allowlisted metadata; immutable session code; dependent-work schedule predicate; non-empty reason; increment approved row-version token | Physical sessions.row_version and increment rule are absent; dependent-work lock set and exact CAS contract unresolved; do not substitute updated_at |
| CMD-013 transition-session | L00 → L30 project parent fence → session aggregate → complete closure dependency set in deterministic order → L110 | Revalidate actor authorization, T-07 state and transition after locks; only DRAFT/ACTIVE/PAUSED/CLOSED; CLOSE_REQUESTED is action/event; CLOSED terminal in ordinary flow; audit atomic with state change | Complete closure dependency inventory, per-transition permissions, row-version field, parent fence modes and pending-intent policy unresolved |
| CMD-014 publish-assignment | L00 → L10 project capacity serialization row(s), sorted by project UUID → L15 principal → L16 user-role → L17 scope-grant → conditional L18 authorization catalog → L30 project then session → L40 instrument/version → L50 assignment → L55 membership rows → L110 | Revalidate scope, same-project references, published instrument, account/role eligibility, self-assignment, effective interval and half-open overlap; count distinct qualifying Inspectors under the same T-14 capacity serialization point; publish complete roster atomically | L10 exact DB primitive and complete project set; L15–L18 physical coverage; assignment/member constraints and implicit FK/trigger edges require review and proof |
| CMD-015 change-assignment-members | L00 → conditional L10 capacity rows sorted by project UUID → L15–L18 affected principal/role/scope rows → L30 project then session → L50 assignment → L55 membership rows in stable key order → L110 | Validate all add/end operations before writes; revalidate assignment-parent binding; use identical T-14 qualifying predicate; preserve history with effective-time changes; no hard delete; all-or-nothing batch | Active-claim/in-progress behavior and exact eligibility-changing paths remain unresolved; same-rank ordering and capacity-row initialization/coverage require review |
| CMD-016 update-project-capacity | L00 → L10 exactly one existing project capacity row → L15–L17 eligibility rows → L110 | Fail closed if capacity row absent; use same qualifying-account predicate as CMD-004/014/015; reject cap below current qualifying count; update and audit atomically | Exclusive L10 primitive, row initialization/backfill and physical row-version field/increment rule require approval; all population-changing writers must participate |
| CMD-017 manage-target-plan | L00 → L30 project and optional session parent(s) for new plan → target-plan aggregate → allocation children in deterministic key order → L110 | Draft replacement validates the complete allocation set before mutation; published plans immutable; enforce project/version uniqueness; publish atomically; never mutate actual inspection/report sources | Target-plan/session scope mismatch, child uniqueness key, separate row-version/CAS, aggregate lock rank and delete/reinsert history semantics remain unresolved; no final rank certification |
| CMD-018 create-instrument | L00 → L20 canonical normalized instrument-code uniqueness arbiter → instrument row → L110 | Server derives creator and initial inactive/draft availability; normalized code uniqueness is database-arbitrated; no project/assignment/checklist/version side effects | Exact normalization function/collation/index and whether L20 is an explicit lock or unique-index arbitration must be specified; do not add a pre-lock unsupported by the source |
| CMD-019 save-instrument-draft | L00 → L40 instrument → instrument_version → checklist/specification/evidence child rows in deterministic stable-key order → L110 | Verify parent/version relationship and DRAFT state; validate full proposed configuration before mutation; canonical hash over normalized content; atomic replacement and audit; published content immutable | Child reconciliation semantics, hash storage/canonicalization, draft CAS/row version, exact child ordering and DML/trigger edges remain unresolved |
| CMD-020 publish-instrument-version | L00 → L40 instrument → instrument_version → read/validate immutable child snapshot → L110 | Recheck explicit instrument.publish permission, relationship, DRAFT state and expected hash under lock; recompute hash server-side; publish immutable snapshot and publication/audit facts atomically; deny subsequent child mutation | Database-level immutability enforcement, hash/snapshot fields, direct-DML denial, function ACL and trigger/FK lock edges require Engineering/Database/Security approval |

### 7.2.1 Cross-command conflict edges retained

- CMD-011–013 share the project/session parent fence. CMD-010 project closure must conflict safely with session creation/update/transition; project-before-session is a candidate order, not a certified PostgreSQL lock protocol.
- CMD-014/015/016 participate in the same T-14 capacity invariant. CMD-004 role grants must use the identical qualifying-account predicate and capacity-first serialization. A writer omitted from this set invalidates the global capacity proof.
- CMD-017 target-plan mutations must not be conflated with actual inspection activity or reporting sources. Session/project closure dependencies must include target-plan state only if the approved closure policy says so.
- CMD-018 code uniqueness is a canonical-key/index arbitration concern; CMD-019/020 instrument/version/child ordering must be reconciled with all other writers of instrument versions and published child content.
- All rows above require comparison with implicit FK, unique-index, trigger, function and RLS paths. The visible application-level order alone cannot prove the effective database lock graph acyclic.

### 7.2.2 Evidence and disposition

CMD-011–020 now have explicit candidate sequence overlays in this manifest (10 additional rows; 20/54 candidate-normalized at documentation level). This is not technical approval or certification. The following remain open: exact PostgreSQL lock modes; complete implicit lock edges; physical row-version/hash/immutability constraints; all competing writer paths; Engineering/Database/Security review; and adversarial concurrency execution. LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. **Certified lock-complete remains 0/54.**
