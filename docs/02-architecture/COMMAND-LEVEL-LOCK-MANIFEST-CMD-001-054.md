# Command-Level Lock Manifest Reconciliation — CMD-001–054

**Document ID:** LOCK-MANIFEST-001  
**Version:** 0.3.0
**Status:** Engineering reconciliation proposal — review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Parent:** LOCK-GRAPH-001 v0.2.0  
**Scope:** Per-command resource inventory, source-stated lock sequence, shared invariants, competing commands, constraints and unresolved ordering  
**Gate:** G3 NOT READY; G4 NOT READY; G5 NOT READY; G7 NOT READY; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Executive conclusion

This document converts the current command reviews into a 54-row lock manifest inventory. It records only resource and ordering facts that are explicitly present in the reviewed command documents, and labels missing or contradictory information as OPEN. It is not a normalized, approved lock plan.

**Critical result:** 54/54 logical command IDs are represented in the inventory, but **0/54 are certified lock-complete**. The manifest is an evidence and reconciliation artifact, not a proof of deadlock freedom. In particular, source-stated lock order conflicts remain in CMD-023/024/025/026/027/028, and CMD-031–040 contain further aggregate/child and external-effect boundaries requiring cross-check against the global candidate ranks.

No command catalogue, physical schema, function, API, migration or runtime behavior is changed by this document.

## 2. Authority, source set and method

Root AGENTS.md v1.2.0 was read first from the target branch. This review also inspected MIB-001 v1.0.1, DGA-001 v1.4.0, IRG-001 v1.0.1, Decision Register, PostgreSQL Command Contract Catalogue v0.2.0, Physical Database Schema and Integrity Specification v0.2.0, LOCK-GRAPH-001 v0.1.0, CONCURRENCY-001 v0.1.0 and the seven detailed command review documents.

Method:
1. Extract the lock/transaction/read-write statements stated by each command review.
2. Record source-stated acquisition sequence separately from the candidate global rank hierarchy.
3. Identify shared invariants and known competing commands from the cross-command review.
4. Mark unknown resource order, implicit trigger/FK/index behavior, constraints, worker identity or authority as OPEN; do not infer them.
5. Treat read-only commands as having no row-lock manifest unless the source explicitly defines one. Treat blocked commands as not designable for implementation.

Evidence is static documentation inspection only. No PostgreSQL catalog, query plan, lock graph, transaction trace, deployed function, RLS/grant, CI or concurrency test was executed.

## 3. Manifest vocabulary

| Code | Candidate class from LOCK-GRAPH-001 | Meaning |
|---|---|---|
| L0 | Idempotency arbitration | Unique actor/command/resource/key request identity |
| L10 | Shared serialization row | T-14 project capacity or another shared invariant row |
| L20 | Canonical identity arbitration | Canonical `(instrument_type, serial_normalized)` identity or conflict identity |
| L30 | Project/session parent | Project and session lifecycle gates |
| L40 | Assignment/instrument references | Assignment, membership, instrument and published version |
| L50 | Canonical unit | Unit identity/lifecycle |
| L60 | Association episode | Unit-project association |
| L70 | Claim/inspection aggregate | Active claim and inspection aggregate |
| L80 | Dependent child aggregate | Revision, evidence, document, attendance, print, policy or notification row |
| L90 | Append-only facts | Domain/audit/review/attempt/escalation events |

The L-ranks are candidate analysis labels, not an approved lock order. A dash means the source does not specify a row lock for that command; it does not mean that implicit database locking is absent.

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
| CMD-049 | list-own-notifications | Recipient-owned read query; no write lock specified | CMD-052 fan-out creating inbox rows; CMD-050 read acknowledgement | Recipient RLS and stable pagination keys | PARTIAL — snapshot pagination semantics and safe delivery-field projection open |
| CMD-050 | mark-notification-read | L0 if mutation idempotency required → one recipient-owned notifications row guarded update → L90 only if approved audit semantics | Concurrent mark-read; CMD-052 notification creation; delivery-state updates must remain separate | Conditional set-once read_at update; no notification row_version | PARTIAL — remove expected_version or approve token; exact audit requirement and set-once semantics open |
| CMD-051 | publish-notification-policy | L0 → policy draft/version serialization row → policy version/scope uniqueness arbitration → immutable publish/audit | Concurrent draft edit/publish; scheduler CMD-054 reads policy version | Unique policy/scope/version and one effective version per interval proposed | BLOCKED — exact lock target/exclusion constraint, draft hash/version lifecycle and policy scope order open |
| CMD-052 | fanout-notification-outbox | Short claim transaction: outbox row bounded lease/claim → commit; fan-out writes unique notification and delivery rows; no provider I/O | Duplicate fan-out, lease expiry/reclaim, CMD-049 inbox read, CMD-053 dispatch | Unique source_event_id/policy_version_id; unique outbox/recipient; unique notification/channel | BLOCKED — worker principal/ACL, lease owner/token/expiry, partial checkpointing and payload schema open |
| CMD-053 | dispatch-notification-delivery | Short claim/attempt transaction → provider I/O outside DB transaction → short guarded outcome transaction on exact delivery/attempt lease | Retry, callback/webhook, UNKNOWN reconciliation, lease reclaim | Attempt idempotency/provider key where supported; append-only attempt history | BLOCKED — callback command boundary, provider capability, worker identity/ACL and attempt unique key open |
| CMD-054 | evaluate-notification-escalation | Short scheduler transaction: policy-version/notification/step due-check and unique escalation arbitration → append event/outbox; no provider I/O | Duplicate scheduler ticks, CMD-051 policy publish, CMD-052 fan-out | Unique notification/policy_version/step/event key proposed | BLOCKED — server UTC SLA clock, scheduler principal/ACL, due-time predicate and retry/unique contract open |

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

[LOCK-PROTOCOL-DECISION-RESOLUTION-001](LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.2.0 provides a candidate global rank hierarchy and proposed resolutions for the source-order conflicts. It defines the required per-command manifest evidence, identifies PO-owned product-policy decisions separately from Engineering/Security technical approvals, and preserves the 54/54 inventory with 0/54 certified lock-complete.

The proposal does not amend command recipes, physical schema, constraints or runtime behavior. No tests or database inspection were performed. LM-01–LM-10 remain open/not executed; G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED.
