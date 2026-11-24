# Command-Level Lock Manifest Reconciliation — CMD-001–054

**Document ID:** LOCK-MANIFEST-001  
**Version:** 0.4.28
**Status:** Engineering reconciliation proposal — review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Parent:** LOCK-GRAPH-001 v0.4.21  
**Scope:** Per-command resource inventory, source-stated lock sequence, shared invariants, competing commands, constraints and unresolved ordering  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT ACTIVE.

## 1. Executive conclusion

This document converts the current command reviews into a 54-row lock manifest inventory. It records only resource and ordering facts that are explicitly present in the reviewed command documents, and labels missing or contradictory information as OPEN. It is not a normalized, approved lock plan.

**Critical result:** 54/54 traceability IDs are represented: 50 application commands and 4 external control-plane IDs. The application lock-certification denominator is **0/50 certified lock-complete**; CMD-045–048 have no application lock set and are excluded. The manifest is an evidence and reconciliation artifact, not a proof of deadlock freedom. In particular, source-stated lock order conflicts remain in CMD-023/024/025/026/027/028, and CMD-031–040 contain further aggregate/child and external-effect boundaries requiring cross-check against the global candidate ranks.

No command catalogue, physical schema, function, API, migration or runtime behavior is changed by this document.

## 2. Authority, source set and method

Root `AGENTS.md` v1.2.0 was re-read from the target branch at the start of this work session. The source baseline below records the exact reviewed snapshot used for this reconciliation checkpoint on 2026-11-24 (it is not a live pointer to later document edits):

| Source | Reviewed snapshot version / identity | Use in this reconciliation |
|---|---|---|
| MIB-001 | v1.0.1 | Authority, gates and documentation-phase boundary |
| DGA-001 | v1.11.55 | Active evidence-backed gap queue and gate disposition |
| IRG-001 | v1.0.1 | Phase and authorization governance |
| Decision Register | Current branch revision | Approved PO decisions and institutional dependencies |
| PostgreSQL Command Contract Catalogue | v0.4.8 | Canonical logical CMD-001–054 operation inventory and proposed contracts |
| Physical Database Schema and Integrity Specification | v0.4.4 | Proposed entities, constraints, indexes and transaction invariants |
| LOCK-GRAPH-001 | v0.4.19 | Candidate resource ranks, cross-command conflicts and planned race scenarios |
| CONCURRENCY-001 | v0.1.7 | Aggregate token, idempotency and worker-fencing mismatches |
| LOCK-PROTOCOL-DECISION-RESOLUTION-001 | v0.3.12 | LPR decision state and static reconciliation checkpoint |
| Detailed command reviews | Seven current command-range documents; CMD-049–054 review v0.1.3 at this checkpoint | Per-command source-stated operations and dependencies |

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
| CMD-045 | retention/legal-hold (traceability only) | NO APPLICATION TRANSACTION/LOCK SET | Institutional records/legal/privacy lifecycle remains external | PO-approved institutional control-plane scope; T-10 evidence remains blocked | DEFERRED_EXTERNAL_CONTROL_PLANE — no app lock protocol or destructive command |
| CMD-046 | review-security-incident (traceability only) | NO APPLICATION TRANSACTION/LOCK SET | Incident-case lifecycle and evidence custody remain external | PO-approved incident-response control-plane scope; RACI remains open | DEFERRED_EXTERNAL_CONTROL_PLANE — no app case or reviewer command |
| CMD-047 | manage-provider-configuration (traceability only) | NO APPLICATION TRANSACTION/LOCK SET | Provider-native configuration and secret management remain external | PO-approved provider control-plane scope; T-12 evidence remains blocked | OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL |
| CMD-048 | manage-production-release (traceability only) | NO APPLICATION TRANSACTION/LOCK SET | Protected source-control/deployment operations remain external | PO-approved release control-plane scope; DGA-B15 remains unverified | OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL |
| CMD-049 | list-own-notifications | Recipient-owned MVCC read query; no mutation lock specified | CMD-052 fan-out creating inbox rows; CMD-050 read acknowledgement | Recipient RLS and stable (created_at, id) pagination keys | PARTIAL — exact index plan, maximum page size and live RLS evidence open; no cross-page snapshot is claimed |
| CMD-050 | mark-notification-read | Short idempotent transaction: one recipient-owned notifications row guarded set-once update; first transition appends notification.read atomically | Concurrent mark-read; CMD-052 notification creation; delivery-state updates must remain separate | Conditional set-once read_at update; no notification row_version | PARTIAL — documentation contract aligned; exact audit implementation and RLS/ACL verification open |
| CMD-051 | publish-notification-policy | Short policy/scope transaction: compare expected current published version, allocate next version, publish immutable document and append audit fact | Concurrent publish; scheduler CMD-054 reads pinned policy version | Unique policy/scope/version and one effective version per interval proposed | BLOCKED — exact lock target/exclusion constraint, policy scope order and permission/SoD open; persisted draft CRUD excluded |
| CMD-052 | fanout-notification-outbox | Source-event transaction persists immutable event-time recipient/scope candidate rows + snapshot hash/count before commit (candidate-only, NOT ADMITTED); then isolated short claim transaction on one bounded outbox row → owner/token-hash/generation/expiry fencing tuple → commit; separate fan-out transaction reads candidates and writes inbox/delivery rows; no provider I/O | Source event vs account/role/scope revocation; source event vs project/session closure; duplicate fan-out; lease expiry/reclaim; CMD-049 inbox read; CMD-053 dispatch; CMD-054 escalation snapshot | Unique source_event_id/policy_version_id; candidate PK outbox/recipient; unique notification outbox/recipient and notification/channel; snapshot hash/count; safe_payload | BLOCKED — candidate relation/header fields not admitted; source transaction may introduce implicit FK KEY SHARE edges to L15/L30/L50/L55 resources after higher-rank locks; exact global order, scope FKs, fan-out bounds, worker principal/ACL open |
| CMD-053 | dispatch-notification-delivery | Short claim transaction on exact delivery row and durable attempt identity → commit; provider I/O outside transaction; guarded outcome transaction revalidates owner/token-hash/generation/expiry and appends attempt result | Retry, INT-NOTIF-001 callback ingress, UNKNOWN reconciliation, lease reclaim | Attempt idempotency/provider key where supported; append-only attempt history | BLOCKED — provider capability, callback-specific durable dedup/auth and worker identity/ACL remain open |
| CMD-054 | evaluate-notification-escalation | Short scheduler transaction: capture one DB UTC instant; due check against pinned policy version and notification state → unique escalation arbitration → append escalation fact, outbox intent and own event-time candidate/scope snapshot atomically; no source business-state mutation or provider I/O | Duplicate scheduler ticks; CMD-051 policy publish; CMD-052 fan-out; account/role/scope revocation; implicit FK edges from candidate snapshot | Unique notification/policy_version/step/event key; candidate outbox/recipient uniqueness and snapshot hash/count proposed; no caller evaluation_time | BLOCKED — candidate relation not admitted; lock order against notification/policy rows and L15/L16/L17 recipient authority plus scope FKs unresolved; SLA and scheduler principal/ACL remain open |

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
| G5 API/command | NOT READY | 50 application manifests in scope; 4 external IDs excluded; 0/50 application manifests certified lock-complete |
| G7 QA/evidence | NOT READY | Concurrency tests planned only |
| G9 scope freeze | NOT READY | LM-01–LM-10 and existing institutional/technical blockers remain |
| G10 implementation | NOT AUTHORIZED | No separate written implementation authorization |

**Final disposition:** LOCK-MANIFEST-001 provides a 54-ID traceability inventory (50 application commands + 4 external control-plane IDs) and identifies where application manifests cannot yet be certified. It does not normalize conflicting orders, approve any command, prove deadlock freedom or authorize implementation.


## 9. Lock protocol decision-resolution proposal — 2026-11-24

[LOCK-PROTOCOL-DECISION-RESOLUTION-001](LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.2.3 provides a candidate global rank hierarchy and proposed resolutions for the source-order conflicts. It defines the required per-command manifest evidence, identifies PO-owned product-policy decisions separately from Engineering/Security technical approvals, and preserves the 54/54 inventory with 0/54 certified lock-complete.

The proposal does not amend command recipes, physical schema, constraints or runtime behavior. No tests or database inspection were performed. LM-01–LM-10 remain open/not executed; G3/G4/G5/G7/G9 remain NOT READY and G10 NOT ACTIVE.

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


## 7.3 CMD-021–030 candidate lock-order overlay — 2026-11-24

This overlay reconciles CMD-021–030 against their detailed read/write and transaction contracts, the candidate global ranks in LOCK-GRAPH-001, and the CMD-001–020 overlay above. It records a proposed order only where the source supports a defensible candidate. Conflicting source sequences are called out rather than silently normalized. This is documentation-only; no lock mode, SQL, constraint, function, privilege, or implementation is approved.

| Command | Candidate ordered resource sequence | Required revalidation / invariant | Unresolved boundary |
|---|---|---|---|
| CMD-021 deactivate-instrument | L00 idempotency → L40 instrument aggregate → read assignment/version references → L110 | Recheck permission and lifecycle under instrument lock; preserve published versions and historical assignments; deactivation only affects future selection unless a separately approved guard says otherwise | ACTIVE/INACTIVE/ARCHIVED transition matrix, assignment guard, reactivation authority and instrument row-version token unresolved; no inferred cascade |
| CMD-022 register-unit | L00 idempotency → L20 canonical serial-key unique-index arbitration (known serial only) → L30 project/assignment context validation → L60 unit insert → L110 | Normalize using pinned instrument policy; unique (instrument_type, serial_normalized) is final arbiter; unknown serial uses server UUID without shared key; collision response must not disclose protected candidates | L20 may be unique-index arbitration rather than explicit row lock; registration context, identity_attributes schema, unknown-serial policy and conflict workflow/event unresolved |
| CMD-023 associate-unit-to-project | L00 → L20 canonical serial/identity arbitration where applicable → L30 project parent → L60 canonical unit → L70 association-key/unique-index arbitration → L110 | Recheck project authority and conflict status; create a new ACTIVE episode; partial unique ACTIVE (unit_id, project_id) is final arbiter; never reactivate historical ended episode | Source says unit before project; this conflicts with candidate global L30-before-L60. Candidate overlay prefers global rank pending explicit Engineering/Database decision and proof that no path requires reverse order |
| CMD-024 end/revoke-unit-association | L00 → L20 canonical identity if used to locate unit → L30 project parent → L60 unit → L70 association → L80 claim → L90 inspection → L110 | Recheck ACTIVE association and authority; evaluate active claim/workflow dependencies using DB time; preserve ended/revoked association history; fail without mutation when dependency blocks | Exact dependency subset and rank order for claim/inspection references; association row_version absent despite expected_version; event-key mapping and FK/index edges unresolved |
| CMD-025 resolve-unit-identity-conflict | L00 → L20 canonical serial-key arbitration → L30 proposed project context → L60 candidate unit → L70 association-key arbitration (ASSOCIATE_EXISTING only) → conflict row at its approved rank → L110 | Revalidate reviewer authority, conflict status, candidate match and independent verification; REJECT changes only conflict record; ASSOCIATE_EXISTING creates a new association episode; unique ACTIVE association is final arbiter | Source says conflict row first, which conflicts with canonical identity/project/unit ordering. Conflict row rank and safe locator strategy must be approved; do not lock conflict first until global order and all competing resolvers are reconciled |
| CMD-026 claim-unit-and-create-inspection | L00 → L20 canonical serial-key arbitration when serial lookup applies → L30 project then session → L50 assignment → L60 unit → L70 association → L80 claim → L90 inspection → L110 | Revalidate membership, scope, association, instrument and effective intervals after locks; use DB time for expiry; claim and new inspection are atomic; partial unique ACTIVE claim is final arbiter; resume must not emit inspection.created | Source's canonical serial → project/session/assignment → unit → association → claim/inspection is the controlling candidate sequence; lock-mode compatibility, takeover/draft preservation, resumed-claim lifecycle and exact event mapping unresolved |
| CMD-027 release-unit-claim | L00 → L20 canonical identity locator if needed → L30 project/session → L50 assignment → L60 unit → L70 association → L80 claim → L90 inspection (only if required by approved state guard) → L110 | Reauthorize owner/supervisor and scope; compare claim row_version; exactly one release/expiry/takeover terminal outcome; preserve inspection unless an explicit transition is approved | Source says unit/association/assignment/claim/inspection in global order but does not specify every locator; avoid unnecessary inspection lock; lock-mode and takeover race proof open |
| CMD-028 save-inspection-draft | L00 → L30 project/session/assignment context → L60 unit → L70 association → L80 active claim → L90 inspection → L100 response children in deterministic key order → L110 | Reauthorize under lock; compare inspection row_version; validate complete patch against pinned instrument version; omitted response rows are not deletions; increment once per semantic mutation; audit atomically | Exact dependency lock set/order, mutable draft revision representation, response uniqueness and no-op version behavior unresolved |
| CMD-029 submit-inspection | L00 → L30 project/session/assignment context → L60 unit → L70 association → L80 active claim → L90 inspection → L100 evidence/response snapshot inputs in deterministic order → L110 | Revalidate claim/association/assignment; compare row_version; verify persisted responses/evidence; compute canonical snapshot/hash server-side; allocate revision under inspection lock; immutable revision, status, events and idempotency commit atomically | Exact evidence-object verification/locking, snapshot canonicalization, event cardinality/storage mapping and any implicit storage/trigger edges unresolved |
| CMD-030 return-inspection-for-correction | L00 → L30 project/session/assignment/reviewer authority context → L60 unit → L70 association (only if required for current review eligibility) → L90 inspection → L100 target revision/review decision key → L110 | Revalidate reviewer scope, reviewer != author, revision ownership and expected revision; one terminal decision per revision; approve-vs-return serializes on inspection aggregate; submitted revision remains immutable | Reviewer assignment source, review round/decision sequence uniqueness, exact dependency locks and whether association is a necessary lock are unresolved; do not add a lower-rank lock after inspection |

### 7.3.1 Explicit conflict dispositions

1. **CMD-023 unit-before-project:** retained as a source conflict; candidate overlay uses L30 project before L60 unit to align with the global rank proposal. This is not a claim that the existing source contract has been approved or that PostgreSQL will acquire no hidden reverse edge.
2. **CMD-025 conflict-row-first:** not accepted as executable order. Conflict row must be placed only after canonical locator/project/unit ordering is agreed. A safe locator read may identify candidate IDs but must not disclose them or authorize mutation; all state and authority must be revalidated after locks.
3. **CMD-026 canonical serial order:** preserve serial-key arbitration before project/session/assignment and unit/association/claim/inspection. Do not mechanically place L20 after L30 for this path.
4. **CMD-028–030 inspection aggregate:** inspection is the serialization point for draft mutation, submission and terminal review decision; response/evidence/revision/review children are ordered after it. Any command acquiring a child first is a graph conflict requiring explicit reconciliation.
5. **CMD-021/022 lifecycle and uniqueness:** instrument deactivation preserves published version/assignment history; canonical serial uniqueness is represented as unique-index arbitration unless a reviewed design specifies an explicit lock.

### 7.3.2 Evidence and disposition

CMD-021–030 now have candidate overlays (10 additional rows; **30/54 candidate-normalized at documentation level**). This is not technical approval, a lock-completeness claim, or an acyclic graph proof. CMD-023 and CMD-025 source-order conflicts are explicitly retained; CMD-026 preserves the canonical serial-key-first path. Exact PostgreSQL lock modes, implicit FK/index/trigger/function edges, version/uniqueness constraints, Engineering/Database/Security approval and adversarial concurrency evidence remain open. **Certified lock-complete remains 0/54.**


## 7.3 CMD-021–030 candidate lock-order overlay — 2026-11-24

This overlay is a static reconciliation of CMD-021–030 Detailed Contract Review v0.3.0 against candidate ranks in LOCK-GRAPH-001 v0.4.11, the proposed physical schema v0.4.2 and the command catalogue. It does not change PO semantics, resolve open product decisions, approve lock modes, or authorize implementation. Where the detailed contract itself contains conflicting or incomplete ordering, the row explicitly remains unresolved.

| Command | Candidate resource sequence for review | Invariants to revalidate | Unresolved / blocking points |
|---|---|---|---|
| CMD-021 deactivate-instrument | L00 idempotency → L40 instrument → L110 audit | Recheck explicit deactivate permission and current lifecycle under instrument lock; preserve published versions, assignments and inspection history | No physical instrument row_version; ACTIVE/INACTIVE/ARCHIVED transition matrix, future-assignment behavior and active-assignment guard not decided; race with CMD-014 assignment publication needs shared instrument serialization/freshness proof |
| CMD-022 register-unit | L00 → L20 canonical (instrument_type, serial_normalized) arbitration → insert/read L60 unit → optional conflict aggregate only if approved → L110 | Apply the instrument's versioned normalization policy; unique canonical key is final arbiter; no duplicate canonical unit; unknown serial receives independent UUID and no shared key; privacy-safe collision response | Exact identity_attributes storage absent; serial-policy source/version activation and unknown-serial lifecycle unresolved; conflict row creation/event key must not precede approved schema and audit catalogue |
| CMD-023 associate-unit-to-project | L00 → candidate L20 canonical identity arbitration → L30 project parent → L60 unit → L70 association-key/episode → L110 | Revalidate project authority, conflict status, instrument/project compatibility and active association after locks; partial unique ACTIVE key arbitrates duplicate association | Source recipe says unit before project and key-range locking but does not establish global order; proposed sequence is not approved; re-association eligibility, evidence_ref and SoD remain open |
| CMD-024 end/revoke-association | L00 → candidate L20 → L30 project parent → L60 unit → L70 association → L80 claim → L90 inspection/dependency rows → L110 | Revalidate ACTIVE association and actor scope; use DB time; block if active work predicate says so; preserve association history and all submitted revisions/evidence | Detailed recipe says unit/association/claim/inspection without parent order; no association row_version; ENDED vs REVOKED semantics and active-work behavior unresolved; CMD-026 race must be proven |
| CMD-025 resolve-identity-conflict | L00 → conflict aggregate (rank not yet assigned) → candidate L20 identity key → L30 project → L60 unit → L70 association if ASSOCIATE_EXISTING → L110 | Revalidate reviewer authority, conflict status, candidate identity and SoD under lock; only one terminal resolution; unique active association final arbiter | Conflict aggregate rank and canonical order relative to L20 are unresolved; exact audit event keys absent from catalogue; reviewer appointment/SoD and existing association behavior unresolved |
| CMD-026 claim-unit | L00 → L20 canonical serial key when applicable → L30 project → session → L50 assignment → L55 membership → L60 unit → L70 association → L80 claim → L90 inspection → L110 | Revalidate actor, assignment membership, association, instrument and effective intervals after locks; DB-time expiry; unique ACTIVE claim final arbiter; create inspection only when genuinely new | Detailed review explicitly conflicts with catalogue order; canonical serial-key arbitration and parent/assignment/unit ordering must be unified with CMD-022–025/027–029; takeover/resume/expiry/offline policy and event cardinality remain unresolved |
| CMD-027 release-claim | L00 → candidate L20 if serial-key arbitration is required by shared lifecycle → L30 project → L50 assignment → L55 membership → L60 unit → L70 association → L80 claim → L90 inspection if lifecycle predicate requires → L110 | Revalidate owner or explicit supervisor permission, claim state/version and inspection state; increment claim row_version once; release vs expiry/takeover has one terminal winner | Detailed review omits project/session parent and does not establish whether L20 is required; supervisor authority, reason, lifecycle eligibility, row_version initialization and scheduler event ordering unresolved |
| CMD-028 save-inspection-draft | L00 → candidate L20 only if serial identity must be revalidated → L30 project/session → L50 assignment → L55 membership → L60 unit → L70 association → L80 claim → L90 inspection → L100 response/draft children → L110 | Reauthorize claim owner and scope under lock; compare inspections.row_version; validate pinned instrument version before writes; patch only explicit response keys; increment once per semantic mutation; audit without answer-value leakage | Exact parent/reference lock set, draft revision representation, patch null/empty/delete semantics and no-op token behavior unresolved; candidate ordering must be reconciled with CMD-026/027 and schema |
| CMD-029 submit-inspection | L00 → candidate L20 when identity revalidation is required → L30 project/session → L50 assignment → L55 membership → L60 unit → L70 association → L80 claim → L90 inspection → L100 evidence/sync dependencies in deterministic order → L110 revision/events | Revalidate claim, association, assignment, evidence and sync conflicts; snapshot persisted server-side responses; allocate revision under inspection lock; immutable revision/hash and status transition atomic | Evidence object/provider verification boundary, canonical serialization/hash, sync-conflict representation, return/resubmit lifecycle and claim-after-submit policy unresolved; no external I/O while holding domain locks |
| CMD-030 return-for-correction | L00 → L30 project/session (if required by reviewer scope) → L50 assignment/scope reference → L90 inspection → target revision/review-decision key → L110 review/audit facts | Revalidate reviewer assignment, reviewer != author, current revision and reviewable state; exactly one terminal review decision; immutable submitted revision remains unchanged | Detailed recipe starts at inspection aggregate and does not fully map assignment/scope resources; review-decision key rank and approve-vs-return lock equivalence must be reconciled with approval command; reviewer assignment schema/round identity unresolved |

### 7.3.1 Critical conflict register

1. **CMD-026 order conflict:** the command catalogue's legacy sequence (unit → association → assignment/claim) conflicts with the detailed contract's canonical serial key → project/session/assignment → unit → association → inspection/claim. The detailed contract sequence is captured as a candidate only; neither source is silently declared authoritative for physical locking. Resolve the full writer set and PostgreSQL implicit edges before approval.
2. **CMD-023/024 parent-fence omission:** their local recipes acquire unit/association before or without a complete project/session parent fence. The overlay proposes a parent-before-child candidate order to align with CMD-011–020, but this is a design reconciliation requiring review, not a certified correction.
3. **CMD-025 conflict aggregate:** unit_identity_conflicts needs an explicit lock rank and deterministic relation to canonical identity arbitration and association creation. A conflict row lock acquired first may invert against unit/association writers unless all competing paths use the same order.
4. **CMD-021 instrument lifecycle race:** deactivation and assignment publication must share a serialization/revalidation strategy. Locking the instrument only in CMD-021 is insufficient if CMD-014 does not lock/revalidate the same instrument lifecycle row before publishing.
5. **CMD-028/029/030 review lifecycle:** draft save, submit, return and approval must serialize on the inspection aggregate and revision decision key. The same terminal-decision invariant must cover approve and return; the current CMD-030 review does not by itself prove that shared protocol.
6. **L20 scope:** commands that do not resolve or mutate canonical serial identity must not acquire L20 merely to fit a global sequence. Where identity lookup is necessary, the exact canonical-key arbitration primitive and ordering must be specified.

### 7.3.2 Evidence and disposition

CMD-021–030 now have candidate resource-order overlays in this manifest. Together with CMD-001–020, **30/54 commands are candidate-normalized at documentation level; 0/54 are technically approved/certified**. The CMD-021–030 overlay exposes unresolved ordering rather than claiming those paths are closed. Required next evidence includes complete competing-writer inventory, conflict aggregate rank, approved instrument/association/claim/review lifecycle semantics, exact physical row-version and uniqueness constraints, PostgreSQL implicit FK/index/trigger/function edges, Engineering/Database/Security review, and adversarial concurrency tests. LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED.


## 7.4 CMD-031–040 candidate lock-order overlay — 2026-11-24

This overlay maps the reviewed transaction boundaries for approval/reopen, evidence intent/finalization, offline sync, document generation/printing, and attendance evidence/verification. It distinguishes database serialization from external Storage/render/print work. Candidate rank labels are not certification; where the source lacks a physical aggregate or worker identity, the row remains explicitly unresolved.

| Command | Candidate ordered resource sequence | Required revalidation / invariant | Unresolved boundary |
|---|---|---|---|
| CMD-031 approve-inspection | L00 idempotency → L30 project/session/assignment authority context (read/revalidate) → L90 inspection aggregate → L100 exact revision/review-decision key → L110 append-only events/idempotency | Re-read submitted state, current revision, author/reviewer assignment, permission and scope under inspection lock; exactly one terminal decision per revision; update status/row_version and append review/inspection/audit events atomically | Reviewer assignment source, review decision unique constraint/round model, SoD rule and whether authority context requires locks are not fully specified; must serialize against CMD-030 return and any other terminal reviewer command |
| CMD-032 reopen-inspection | L00 → L30 project/session/assignment context → L90 inspection aggregate → L100 approved revision/draft-context key → L110 | Revalidate approved state, exact approved revision, row_version, permission/scope and claim/lifecycle blockers; preserve approved revision and downstream artifacts; only one active draft context can be created | Mutable draft storage/context is unresolved; do not invent revision identifier or mutate approved revision; concurrent reopen must be serialized by inspection aggregate and a unique active-draft invariant |
| CMD-033 create-upload-intent | L00 → L30 project/session/assignment context → L90 inspection aggregate → L100 evidence slot/quota reservation and pending evidence metadata → L110; external upload authorization after commit | Recheck claim, assignment, pinned slot/version and permission; reserve quota atomically; create one pending metadata record; short-lived scoped token generated outside DB locks; retry reconciles reservation without duplicate metadata | Quota serialization row/constraint and evidence slot aggregate are not specified; provider token generation failure and orphan reservation compensation need durable state |
| CMD-034 confirm-upload | Authorized private Storage object inspection outside transaction → L00 idempotency → L100 pending evidence row/intent → L110 | Server derives object key from pending intent; compare observed object identity/metadata/checksum; revalidate actor, claim, assignment, intent expiry and pending state under row lock; finalize metadata + audit + idempotency atomically | Exact evidence-row parent/inspection lock ordering and Storage metadata trust contract need review; never hold DB locks across Storage calls; immutable object key/checksum after finalization |
| CMD-035 sync-batch | L00 batch idempotency/envelope → L30 project/session/assignment context → L90 inspection aggregates sorted by stable UUID per operation → L100 response child rows in stable key order → L110 per-operation durable result | Reauthorize each operation immediately before apply; expected_row_version required; no last-write-wins; each operation independently committed/reconciled; duplicate operation ID/hash returns prior result; preserve failed client data | Device registry/binding/revocation absent; exact per-operation transaction/savepoint policy and operation ordering unresolved; no claims/submit/approve/print/attendance admin operations in offline batch |
| CMD-036 generate-approved-document | L00 → L30 source project/session/assignment authority context → L90 immutable approved source revision → L100 document generation key/document row + durable outbox/job reservation → L110; renderer/Storage work outside DB locks | Revalidate source revision/template version at reservation and finalization; unique generation key prevents duplicate artifact; worker lease/version checked; output checksum and private object metadata verified; immutable artifact finalization/audit atomic | Worker identity, lease, retry/dead-letter, template version storage, renderer provider and worker ACL are missing; never hold DB locks across render/Storage I/O or overwrite prior artifact |
| CMD-037 record-print | L00 → L100 document aggregate/version → print sequence key → L110 | Revalidate finality, version, source scope and print permission under document lock; allocate monotonic sequence; unique (document_id, sequence_no); print event/audit/idempotency atomic; stale expected_sequence consumes no sequence | Physical document aggregate row/version and print sequence schema/lock mode require verification; external printer operation must not be represented as successful solely by a record-print event |
| CMD-038 record-print-batch | L00 batch envelope → per-item L100 document aggregate/version in deterministic stable-key order, one short transaction per item → L110 per-item durable outcomes | No batch-wide lock; authorize each item; stable item key; durable per-document sequence; reconcile counts from stored results; retry only failed items; successful items never repeat; resumable PARTIAL/PROCESSING state | Batch lease/worker model and canonical item key unresolved; exact batch status transition/cleanup policy and print-provider uncertainty need design |
| CMD-039 upload-attendance-document | L00 → attendance record aggregate → quota/reservation row (if approved) → pending attendance document identity → L110; private upload outside transaction; finalization locks attendance record then exact document | Verify scope/replacement preconditions; append new document version, never overwrite prior object/history; same client_file_id + hash idempotent; changed payload rejected; finalization verifies server-observed object metadata | Attendance document quota row and replacement status projection unresolved; orphan cleanup requires durable compensation; exact physical attendance-document version uniqueness and lock rank missing |
| CMD-040 verify-attendance | L00 → attendance record aggregate → exact immutable attendance document version → append-only verification decision/audit → L110 | Revalidate location scope, attendance.verify permission, institutional verifier authority, document finalization/version/checksum and expected_version; uploader/verifier SoD; concurrent verify/reject serializes to one terminal decision per version | Verification history physical table absent; attendance/document row-version fields and exact event vocabulary/SoD authority unresolved; no claim of verification until authoritative history exists |

### 7.4.1 Cross-command conflicts and external-I/O boundary

1. **CMD-030 versus CMD-031:** return and approve must serialize on the same inspection aggregate and share one terminal-decision uniqueness invariant. A command-specific review lock acquired before the inspection aggregate would create a reverse edge.
2. **CMD-032 versus CMD-031/030:** reopen is permitted only from approved state; it must not race a pending terminal decision or create multiple draft contexts. Inspection aggregate is the serialization point.
3. **CMD-033/034:** upload intent reservation and object confirmation are separate phases. CMD-034 must inspect the private object outside DB locks, then lock and revalidate the pending intent before finalization. External Storage calls never occur while holding database row locks.
4. **CMD-035:** sort all inspection aggregate locks by stable UUID when one operation touches multiple inspections; each operation has an independent durable result. Batch envelope state must not be mistaken for an atomic multi-inspection transaction.
5. **CMD-036/037/038:** generation and printing are distinct. Rendering/Storage and printer/network actions happen outside DB locks; database transactions reserve/finalize durable intent and record observed outcomes. Batch print cannot hold a global batch lock across item work.
6. **CMD-039/040:** verification is tied to an immutable attendance document version. Replacement must not silently inherit VERIFIED status; verification decisions serialize on attendance record then exact document version until the physical history model is approved.

### 7.4.2 Evidence and disposition

CMD-031–040 now have candidate transaction/resource overlays (10 additional rows; **40/54 candidate-normalized at documentation level**). This does not certify the lock graph or imply that missing physical aggregates exist. Worker identity/lease/ACL, device registry, evidence quota, attendance verification history, review uniqueness, document sequence, exact lock modes and implicit FK/index/trigger/function edges remain open. Engineering/Database/Security review and adversarial concurrency evidence are still required. **Certified lock-complete remains 0/54.**


## 7.5 CMD-041–048 read-path and authority-gate reconciliation — 2026-11-24

### CMD-041–044 — read/report/audit operations

These commands are read-oriented and do not acquire write locks in the proposed contract. The candidate execution boundary is therefore a bounded, scoped read rather than a fabricated row-lock sequence:

| Command | Candidate read boundary | Required controls | Unresolved boundary |
|---|---|---|---|
| CMD-041 get-actual-report | Resolve actor/scope → bounded actual-data query with stable scope/time ordering → cursor/page response | Actual-only source; separate Inspected/Submitted/Approved/Completed semantics; stable opaque cursor bound to actor/scope/filter/watermark; bounded range/page | Exact report snapshot/watermark strategy, headline-count basis, query plans/indexes and workload limits remain unapproved |
| CMD-042 get-target-report | Resolve actor/scope → bounded target-plan query → deterministic calculation/version → cursor/page response | Target plan is read-only and cannot rewrite actuals; target data is distinct from actual; deterministic calculation/version | Target snapshot/calculation version, templates, indexes and workload limits remain open |
| CMD-043 read-audit | Validate audit.read + approved purpose/scope → bounded SECURITY INVOKER/RLS read → stable cursor/page; separate narrow access-audit append path only if approved | audit.read is distinct from report.read/export; no raw evidence, secrets, object keys or unrestricted network metadata; anti-recursion | T-10 reader/purpose/classification policy, RLS, function owner/ACL, access event policy and retention remain unresolved |
| CMD-044 export-audit | No executable lock plan; policy-gated design only | T-10 institutional approval, export authority/SoD, purpose/scope, artifact encryption/access/expiry/retention/legal hold, durable job and audit required before design can be enabled | Explicitly BLOCKED by T-10; export job/manifest/artifact schema and policy are absent. Do not implement or grant |

### CMD-045–048 — external control-plane traceability IDs (PO APPROVED)

The Product Owner approved CMD-045–048 Control-Plane Resolution Proposal v0.1.2 (PO accepted v0.1.0) on 2026-11-24. These four IDs remain in the 54-ID traceability inventory but are not application commands and have no application transaction/lock set. They are excluded from the application lock-certification denominator:

| Command | Application lock disposition | External evidence dependency |
|---|---|---|
| CMD-045 retention/legal-hold | DEFERRED_EXTERNAL_CONTROL_PLANE — no application transaction/lock set | T-10 institutional records/legal/privacy policy and external records/storage lifecycle evidence |
| CMD-046 review-security-incident | DEFERRED_EXTERNAL_CONTROL_PLANE — no application transaction/lock set | Designated institutional incident-response owner, RACI, case/evidence handling and escalation |
| CMD-047 manage-provider-configuration | OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL — no application transaction/lock set | T-12 signed provider ownership/custody, region/plan/budget, secret manager and recovery evidence |
| CMD-048 manage-production-release | OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL — no application transaction/lock set | GitHub/release governance, CI/rulesets, protected environments, artifact provenance and operator/approver SoD |

No application permission labels for CMD-045–048 may be seeded or granted. No application route, worker, function, migration, provider mutation or production action is authorized. Any future narrow integration requires a new requirement/command ID and separate approval.

### 7.5.1 Normalization and evidence boundary

CMD-041–044 now have candidate read-boundary normalization. CMD-045–048 are external control-plane traceability IDs with no application lock set. CMD-049–054 retain their separately recorded notification transaction boundaries in §4.2 and subsequent notification alignment notes. Across the 54-ID inventory, **50 application commands have candidate execution/transaction boundaries; 4 IDs are external control-plane responsibilities; 0/50 application commands are technically approved/certified lock-complete**. This count is documentation coverage only, not proof of database locks, RLS, ACL or runtime behavior.


## 10. Application certification denominator and current cross-document baseline — 2026-11-24

The inventory retains **54/54 stable traceability IDs** for historical continuity. CMD-045–048 are external control-plane responsibilities and are not executable application commands; they have no application lock manifest, route, RPC, worker or transaction. The application lock-certification denominator is therefore **50**, not 54. Current static coverage is **50/50 application commands with candidate execution/transaction boundaries documented; 0/50 technically approved or certified lock-complete**. Candidate boundaries do not mean the full normalized manifest schema is complete, the global graph is acyclic, or PostgreSQL behavior is proven. LPR-09 remains OPEN; LPR-10 remains NOT EXECUTED. Current parent graph: LOCK-GRAPH-001 v0.4.20. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT ACTIVE.


## 11. Canonical normalized register pointer — 2026-11-24

[LOCK-NORMALIZATION-001](COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md) v0.1.0 consolidates the 50 in-scope application command boundaries into a uniform review register. It preserves the source-specific unresolved fields and conflicts. The 54-ID traceability inventory remains 50 application commands plus 4 external control-plane IDs. CMD-PHYSICAL-CROSSWALK-001 v0.1.2 records proposed physical read/write sets for 50 IDs, with CMD-041–044 explicitly OPEN. Candidate boundary coverage is 50/50; technical approval/certification remains 0/50. LPR-09 remains OPEN; LPR-10 remains NOT EXECUTED. This pointer does not authorize implementation or certify the global graph.


## 7.6 CMD-049–054 POQ-01 audience snapshot and implicit lock-edge reconciliation — 2026-11-24

POQ-01 requires the event-time recipient and authorized source-scope candidate set to be durably persisted before the source event transaction commits. NLA-001 v0.1.5 proposes `notification_outbox_recipients` and outbox snapshot header fields (version/hash/count/completion). These are candidate-only, NOT ADMITTED, and are excluded from the canonical 48-table inventory.

### Candidate resource/transaction boundaries

| Path | Candidate sequence | Lock/constraint concern | Disposition |
|---|---|---|---|
| Source command that emits a notification | Resolve candidate recipient and scope set; acquire/revalidate all mutable eligibility resources in one canonical order; then persist source event + audit + outbox + immutable recipient rows atomically | Candidate FK checks may acquire implicit KEY SHARE locks on app_users, projects, sessions, locations and assignments. If recipient rows are inserted after the source command already holds L30/L50/L55 domain locks, this may create a lower-rank-after-higher-rank edge against account/scope revocation paths | OPEN — no lock recipe certified; all source commands/events that emit notifications and their lock sets must be inventoried |
| CMD-052 claim | Lock one bounded notification_outbox row; persist lease owner/token-hash/generation/expiry; commit | Claim row lock must not be held while reading/mutating domain aggregates or performing provider I/O | Candidate short claim only; worker identity/ACL open |
| CMD-052 fan-out | Read immutable candidate rows for the claimed outbox in deterministic recipient-key order; insert notifications/deliveries idempotently; derive remaining work by anti-join | Notification FK checks may create additional implicit KEY SHARE edges; candidate-to-notification FK/cardinality and direct user/scope FKs must be designed to avoid reverse-rank acquisition | OPEN — exact FKs/indexes and transaction boundaries not approved |
| CMD-054 scheduler | Capture one DB UTC instant; lock due notification/policy/unique escalation key in approved order; append escalation/outbox and persist its own event-time candidate snapshot | Candidate FK checks may acquire recipient/scope locks after notification/policy locks; scheduler must not widen audience or mutate source business state | OPEN — lock order and snapshot helper boundary not approved |
| CMD-053 provider callback | Authenticate provider outside DB; short transaction locks exact delivery/dedup identity and applies monotonic status transition | Provider-event dedup key/storage and delivery-row/attempt lock order are provider-dependent and not fully physicalized | OPEN — provider selection and durable callback dedup/auth evidence required |

### Mandatory proof before lock-manifest admission

1. Inventory every source command/event that may enqueue a notification and map its source aggregate lock set.
2. Inventory account, role, scope, assignment and project/session writers that may change recipient eligibility.
3. Define the event-time linearization point and a deterministic L15/L16/L17 plus applicable L30/L50/L55 resource order, or approve a temporal snapshot strategy with equivalent consistency.
4. Enumerate implicit FK KEY SHARE locks, unique-index arbitration, triggers and helper-function edges for candidate and notification inserts.
5. Prove CMD-052/CMD-054 cannot acquire lower-ranked domain resources after outbox/policy/notification locks.
6. Add opposing-transaction tests for event-time snapshot vs grant revocation, assignment end, project/session closure, worker reclaim and duplicate fan-out.
7. Re-run global graph acyclicity review after the candidate physical model is approved; do not infer acyclicity from the documentation sequence.

**Disposition:** CMD-049/050 remain read/set-once paths; CMD-051 policy publish remains BLOCKED on exact policy aggregate and permission/SoD; CMD-052/054 audience snapshot is a candidate design with unresolved implicit lock edges; CMD-053 provider callback remains provider-dependent. No new lock rank is approved. Lock-complete remains 0/50; LPR-01/LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.


## 7.7 Source-event producer lock inventory for POQ-01 — 2026-11-24

### Purpose and completeness boundary

NLA-001 §4.2/§5/§16 requires an enabled notification policy match to create its outbox intent and immutable event-time audience snapshot in the same transaction as the canonical source event. The command catalogue currently defines 40 application domain commands (CMD-001–040) that can append source-domain events. This matrix enumerates all 40 command event declarations and their existing candidate lock paths as the source-producer audit baseline. It does **not** assert that every event type has an enabled notification rule; policy event allowlisting remains explicit and must never be inferred from a role label or wildcard.

CMD-036–040 require special treatment because their canonical events may be emitted by short asynchronous finalization transactions rather than by the initiating request transaction. The finalizer's source-version/lease/aggregate locks—not merely the initiating command's reservation locks—must be included. CMD-035 may emit one sync event plus multiple operation-specific domain events; each emitted event is a separate candidate source event and must be idempotently correlated to its durable operation result.

| CMD | Operation | Canonical event(s) | Existing candidate lock path | Current lock disposition |
|---|---|---|---|---|
| CMD-001 | `request-account-access` | `account.requested` | Candidate: L00 → L15 caller `app_users`; absent row uses unique `auth_user_id` insert/upsert arbiter | CANDIDATE-NORMALIZED — account-request entity/lifecycle and implicit UPSERT/trigger edges OPEN |
| CMD-002 | `approve-account` | `account.approved` | Candidate: L00 → conditional L10 capacity rows if login-enabled eligibility changes → L15 actor/target principals sorted → L16/L17 actor authority rows → L18 catalog; L110 decision/audit | CANDIDATE-NORMALIZED — account state table, affected-project set, version and decision uniqueness OPEN |
| CMD-003 | `reject-account` | `account.rejected` | Candidate: same as CMD-002; conditional L10 if T-14 eligibility changes; L15 sorted principals; L16/L17 actor authority; L18 catalog; L110 decision/audit | CANDIDATE-NORMALIZED — rejectable states, no-cascade and terminal uniqueness OPEN |
| CMD-004 | `grant-role` | `role.assigned; permission.changed if bundle changes` | Candidate: L00 → L10 if Inspector eligibility changes → L15 actor/target sorted → L16 actor/target role rows sorted → L17 delegation scope rows → L18 catalog → L110 audit | CANDIDATE-NORMALIZED — role scope, interval constraint, capacity row and catalog mutability OPEN |
| CMD-005 | `revoke-role` | `role.revoked` | Candidate: L00 → L10 if Inspector eligibility reduction → L15 actor/target sorted → L16 actor authority + exact target grant sorted → L17 delegation scope → L18 catalog → L110 audit | CANDIDATE-NORMALIZED — `expected_version` lacks physical `user_roles.row_version`; last-admin and revocation representation OPEN |
| CMD-006 | `grant-scope` | `scope.changed` | Candidate: L00 → conditional L10 → L15 principals → L16 if role authority → L17 grants → L18 catalog → L30/L50 scope target → L110 audit | CANDIDATE-NORMALIZED — scope mapping, Inspector predicate and interval constraint OPEN |
| CMD-007 | `revoke-scope` | `scope.changed` | Candidate: L00 → conditional L10 if revocation changes T-14 → L15 principals sorted → L16 if needed → L17 actor authority + exact target grant sorted → L18 if needed → L30/L50 scope parent only if required → L110 audit | CANDIDATE-NORMALIZED — physical version token, expiry and authorization freshness OPEN |
| CMD-008 | `create-project` | `project.created` | Candidate: L00 → L15 actor → L16/L17 authority → L18 catalog → L30 unique normalized-code arbiter + project insert; initialize default capacity row in same transaction as a new project | CANDIDATE-NORMALIZED — normalization/collation, capacity bootstrap and trigger/FK edges OPEN |
| CMD-009 | `update-project` | `project.updated` | Candidate: L00 → L15 actor → L16/L17 project authority → L18 catalog → L30 project `FOR NO KEY UPDATE` + CAS | CANDIDATE-NORMALIZED — project row_version/updated metadata absent; timezone semantics OPEN |
| CMD-010 | `close-project` | `project.closed` | Candidate: L00 → conditional L10 if T-14 eligibility changes → L15 actor → L16/L17 project.close authority → L18 catalog → L30 project `FOR NO KEY UPDATE`; evaluate blockers behind parent fence | CANDIDATE-NORMALIZED — closure gates, T-14 effect, pending work, row_version and child-fence coverage OPEN |
| CMD-011 | `create-session` | `session.created` | L0 → L30 project row (FOR KEY SHARE or approved equivalent) → session insert → L90 | PARTIAL — exact lock mode must be reconciled with project close and child mutation protocol |
| CMD-012 | `update-session` | `session.updated` | L0 → session row → parent project → assignment/time dependencies → L90 | BLOCKED — source order session then parent differs from proposed parent-first child gate; session row_version missing |
| CMD-013 | `transition-session` | `session.close_requested` is action/event, not state; final event `session.closed` | L0 → session row → closure dependencies in deterministic order → L90 | BLOCKED — parent/session ordering and complete closure blocker set unresolved; row_version missing |
| CMD-014 | `publish-assignment` | `assignment.created` | L0 → L10 capacity row if Inspector candidate → L30 project/session/assignment references (UUID order) → L40 affected users/role references → insert assignment/members → L90 | PARTIAL — instrument/version relative rank versus assignment remains open; exact all-member lock set needed |
| CMD-015 | `change-assignment-members` | `assignment.changed` | L0 → L10 capacity row if Inspector membership changes → assignment row → assignment_members and user rows (UUID order) → L90 | PARTIAL — assignment/project/session/instrument parent order and expiry/suspension writers need exhaustive alignment |
| CMD-016 | `change-inspector-capacity` | `capacity.limit_changed` | L0 → L10 one project_capacity_settings row → eligibility rows → capacity update → L90 | PARTIAL — capacity row initialization, missing-row behavior and all eligibility writers open |
| CMD-017 | `manage-target-plan` | `target.created/reallocated/version_published` | L0 → L30 project/session for new plan → target_plan row → allocation rows deterministic order → L90 | PARTIAL — plan/session relation, allocation key sort, draft CAS token/hash and delete/reinsert history unresolved |
| CMD-018 | `create-instrument` | `instrument.created` | L0 → unique instrument code arbitration → instrument insert → L90 | PARTIAL — insert-only path; no parent row lock specified |
| CMD-019 | `save-instrument-draft` | `instrument.version_drafted; config changed events` | L0 → L40 instrument row → instrument_version row → child configuration rows deterministic order → L90 | BLOCKED — config hash physical field, child replacement/history and assignment/instrument global rank open |
| CMD-020 | `publish-instrument-version` | `instrument.version_published` | L0 → L40 instrument row → instrument_version row → child config validation → publication/audit | PARTIAL — publication history/child immutability constraint and cross-command instrument/assignment order open |
| CMD-021 | `deactivate-instrument` | `instrument.deactivated` | L0 → instrument row → assignment reference checks → L90 | BLOCKED — source token expected_version lacks approved physical field; instrument-vs-assignment lock order open |
| CMD-022 | `register-canonical-unit` | `unit.registered or identity_conflict_opened` | L0 → L20 canonical serial-key unique arbitration; authorize instrument/project/assignment context; unit insert → L90 | PARTIAL — exact ordering of context rows versus canonical-key arbitration and duplicate collision workflow open |
| CMD-023 | `associate-unit-to-project` | `unit.project_associated` | L0 → source says L50 unit → L30 project → L60 association key/unique arbiter → L90 | BLOCKED — source unit-first order conflicts with CMD-026 parent-before-unit candidate order and global hierarchy |
| CMD-024 | `end-unit-project-association` | `unit.project_association_ended/revoked` | L0 → source says unit + association + active claim/inspection rows in globally deterministic order → L90 | BLOCKED — exact relative order of project/assignment/unit/association/claim/inspection is not stated |
| CMD-025 | `resolve-unit-identity-conflict` | `unit.identity_conflict_resolved/rejected` | L0 → source says conflict row → candidate unit → project/association key → L90 | BLOCKED — conflict-first order may invert canonical-key/project/unit path; conflict identity rank unresolved |
| CMD-026 | `claim-unit` | `unit.claimed and inspection.created` | L0 → L20 canonical `(instrument_type, serial_normalized)` key → L30 project/session/assignment → L50 unit → L60 association → L70 inspection/claim → L90 | BLOCKED — conflicts with catalogue row (unit→association→assignment/claim); claim/inspection ordering and takeover semantics open |
| CMD-027 | `release-unit-claim` | `unit.claim_released` | L0 → source says canonical unit → association → assignment → claim → inspection → L90 | BLOCKED — assignment-before-unit candidate hierarchy differs from source; exact lock set/order and token/schema alignment open |
| CMD-028 | `save-draft` | `inspection.draft_saved` | L0 → inspection aggregate → active claim/association/assignment dependencies → response children → L90 | BLOCKED — source aggregate-first order conflicts with parent/association rank proposal; exact child sort key/no-op behavior open |
| CMD-029 | `submit-inspection` | `inspection.submitted and inspection_revision.created` | L0 → inspection aggregate → claim/association/assignment + evidence rows → revision allocation → immutable revision/events → L90 | BLOCKED — dependency lock order and evidence finalization race must align; event cardinality/source table open |
| CMD-030 | `return-inspection` | `inspection.returned_for_correction` | L0 → inspection aggregate → target revision → review decision key → L90 | BLOCKED — exact review decision uniqueness constraint and shared inspection/revision order need approval |
| CMD-031 | `approve-inspection` | `inspection.approved` | L0 → inspection aggregate → validate exact current revision/reviewer assignment → review_events/inspection_events/audit/idempotency | BLOCKED — detailed review requires aggregate lock; exact child row locks and unique terminal decision constraint must be made explicit |
| CMD-032 | `reopen-inspection` | `inspection.reopened` | L0 → inspection aggregate → validate approved revision and active-work blockers → inspection_events/audit/idempotency | BLOCKED — blocker lock set, claim/association dependency order and worker finalization race unresolved |
| CMD-033 | `create-upload-intent` | `evidence.upload_intent_created` | L0 → inspection aggregate → quota/reservation row if policy requires → pending evidence metadata → L90; upload authorization after commit | BLOCKED — exact quota row and evidence key/index contract open; never hold locks during Storage token/I/O |
| CMD-034 | `confirm-upload` | `evidence.uploaded` | External Storage object inspection first (no DB lock) → L0 → evidence row → revalidate inspection/claim/assignment → finalize evidence/audit | BLOCKED — evidence-vs-inspection lock order and Storage TOCTOU policy require approved contract |
| CMD-035 | `sync-batch` | `sync.batch_applied/conflicted plus domain events` | L0 → inspection rows sorted deterministically (or separately committed operation transactions/savepoints) → operation-specific child writes → L90 | BLOCKED — source explicitly allows short per-operation transactions or savepoints; choose one; multi-inspection sorting and batch atomicity need decision |
| CMD-036 | `generate-approved-document` | `pdf.generated/ba.generated/attendance.generated` | Short transaction: L0 → source/document generation key → PENDING document/job/outbox → L90; worker external render/Storage outside locks; short guarded finalize validates lease/source version | BLOCKED — job/outbox/lease/worker identity/ACL and document source/template schema absent |
| CMD-037 | `record-print` | `document.printed/document.reprinted` | L0 → document aggregate/version row → allocate sequence → print_events/audit → L90 | BLOCKED — document version identity and sequence storage/allocator missing |
| CMD-038 | `record-print-batch` | `document.print_batch_created/completed/partial` plus per-document print events | Batch L0 and batch envelope → per item: authorization + document aggregate/version row → per-document sequence → print event/audit; no batch-wide lock during printing | BLOCKED — print_batch_items/stable item identity/worker lease and partial recovery contract open |
| CMD-039 | `upload-attendance-document` | `attendance.uploaded/replaced` | L0 → attendance record → quota/reservation if approved → pending document identity; Storage upload outside transaction → short finalize locks attendance + exact document | BLOCKED — intent/finalize split, document version and institutional upload authority unresolved |
| CMD-040 | `verify-attendance` | `attendance.verified` | L0 → attendance_records → exact attendance_documents row → L90 | BLOCKED — institutional authority/SoD and version token absent; verify-vs-replace fence incomplete |

### Source-producer lock implications

1. For CMD-001–034, where the canonical event is committed by the command transaction, any matched notification outbox intent and candidate audience snapshot must be part of that same transaction. A post-commit notification worker must not resolve recipients from current membership.
2. CMD-035 must define whether each operation is a separate transaction/savepoint and identify exactly which operation-level event commits with which durable operation result. Snapshot completeness and fan-out bounds apply per source event, not merely per batch envelope.
3. CMD-036 and CMD-038 require explicit finalizer boundaries: renderer completion and each print-batch item outcome can be distinct source events. The finalizer must atomically append its event, audit, outbox and candidate audience snapshot after validating its lease/source-version fence. A batch-level projection event must not be mistaken for every per-document print event.
4. CMD-039 upload completion/replacement events are emitted only after private Storage verification and the short guarded database finalization; the verified document version and attendance scope are the event-time snapshot basis.
5. CMD-040 verification is a source event only after the exact immutable attendance-document version and verifier authority/SoD are checked under the approved transaction fence.
6. The event-time audience resolver may need L15/L16/L17 principal/grant/scope resources plus L30/L50 project/session/assignment references. These resources are not currently represented in all 40 candidate lock paths. This matrix therefore proves producer coverage, **not** a complete recipient-resolution lock set.
7. A producer path that already holds L30/L40/L50/L60/L70/L90 resources before resolving L15/L16/L17 eligibility can invert the proposed global order. The matrix exposes where the resolver would be appended; it does not authorize appending it in that order. Each producer needs a reviewed pre-lock/linearization strategy or an approved temporal snapshot design.
8. CMD-041/042 report access and CMD-043/044 audit access/export are not included in the 40 source-domain mutation producers. Their conditional access events require a separately approved side-effect/audit access boundary; do not silently attach notification fan-out to read queries. CMD-045–048 remain external control-plane IDs. CMD-049–054 are notification lifecycle commands/events and must be excluded from recursive notification matching unless a separately approved non-recursive rule is defined.

### Admission criteria

Before any notification snapshot relation or lock rank is admitted:
- enumerate each enabled event type and the exact source command/finalizer that emits it;
- map every producer's full held lock set at the notification snapshot linearization point;
- map all competing account, role, scope, project, session, assignment and membership writers;
- enumerate candidate FK KEY SHARE, unique-index, trigger and helper-function edges;
- specify recipient temporal eligibility semantics and exact scope tuple;
- prove no lower-rank resource is acquired after a higher-rank lock across all producers and workers;
- validate deterministic fan-out bounds, snapshot hash/count and rollback behavior;
- prove the resulting effective global graph acyclic and execute opposing-transaction tests.

**Disposition:** 40/40 domain command event declarations mapped to candidate lock paths; recipient resolver lock-set coverage remains incomplete; no producer is lock-certified by this matrix. Candidate snapshot relation/header remain NOT ADMITTED. G9 NOT READY; G10 NOT ACTIVE; application lock certification 0/50.


## 7.8 Recipient-resolver lock-set review — 2026-11-24

[NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001](NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) v0.1.2 analyzes the resolver lock-set coverage for all 40 source declarations already inventoried in §7.7. It finds that actor/target locks do not prove the complete candidate recipient set is fenced; 0/40 source resolver paths are certified. It proposes (not approves) a global transaction-scoped audience guard at candidate L05, with SERIALIZABLE predicate snapshot as an alternative, followed by deterministic L15/L16/L17 and scope-parent pre-acquisition. L05 is NOT APPROVED and must not be used as an executable instruction. Event-time linearization, policy allowlist, selector grammar, writer participation, FK DDL, worker boundaries and all command-specific lock conflicts remain OPEN. Candidate relation/header remain NOT ADMITTED. 0/50 application lock certification; G9 NOT READY; G10 NOT ACTIVE.
