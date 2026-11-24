# Notification Source-Event Snapshot and Lock-Order Reconciliation

**Document ID:** NLA-LOCK-RECON-001  
**Version:** 0.1.0  
**Status:** Engineering reconciliation proposal — NOT approved for implementation  
**Date:** 2026-11-24  
**Baseline branch / HEAD:** `docs/audit-lock-and-identity-reconciliation` / `f3e5598b6e0da6d67cef82e4942518c6e212c483`  
**Target:** G9 scope-freeze evidence; notification snapshot and global lock graph  
**Authority:** AGENTS.md v1.2.2; POQ-01; NLA-001; LOCK-GRAPH-001; LOCK-MANIFEST-001; CMD-001–054 reviews

## 1. Purpose and disposition

This document closes the *inventory and static reconciliation gap* for notification source-event writes. It does not approve a physical table, FK set, lock rank, selector grammar, worker grant, SQL, migration or runtime behavior.

The controlling product decision POQ-01 is fixed: resolve and persist the event-time candidate audience and authorized source scope/checkpoint in the source transaction; retries reuse that immutable set; dispatch-time account/channel/consent/security checks may suppress candidates but never widen the audience.

The candidate relation `notification_outbox_recipients` and outbox snapshot header fields remain **NOT ADMITTED** and are excluded from the canonical 48-table inventory. This document does not change that status.

**Key finding:** CMD-001–040 are potential source-event producers because their contracts define business mutations and/or append-only domain/audit events. The current SSOT does not provide an approved event-type-to-notification-policy allowlist for those commands. Therefore this inventory identifies the complete application-command search surface, but it does not claim every command emits a notification or invent a policy mapping. CMD-054 is a separate scheduler-generated source. CMD-052 is a consumer/fan-out worker, CMD-053 is a delivery worker, and CMD-049–051 are not source-domain notification producers.

## 2. Scope and exclusions

| Command range | Notification role | Disposition |
|---|---|---|
| CMD-001–010 | Potential source-domain event producers | Inventory all 10; policy match/event allowlist not approved |
| CMD-011–020 | Potential source-domain event producers | Inventory all 10; source lock-order defects remain |
| CMD-021–030 | Potential source-domain event producers | Inventory all 10; several source lock orders remain BLOCKED |
| CMD-031–040 | Potential source-domain event producers | Inventory all 10; worker/external-effect boundaries remain |
| CMD-041–044 | Read-only or institutionally blocked audit/report operations | Not admitted as notification source writers; any future access notification requires a separate approved event/purpose contract |
| CMD-045–048 | External control-plane traceability IDs | No application transaction or source outbox writer |
| CMD-049 | Recipient inbox read | Consumer/read path only |
| CMD-050 | Recipient read-state transition | Notification lifecycle event `notification.read`; not a source-domain notification intent |
| CMD-051 | Notification policy publication | Configuration/audit event; does not itself create a notification outbox intent unless a separately approved policy explicitly says so |
| CMD-052 | Outbox fan-out | Consumer only; claims and materializes existing source intents |
| CMD-053 | Provider delivery | Consumer only; no source-domain intent |
| CMD-054 | SLA/escalation scheduler | Separate internal source; creates its own escalation event, outbox intent and candidate snapshot atomically |

CMD-036's generic document-generation job/outbox is not `notification_outbox` and must remain a separate durable operation model. The notification queue must not be repurposed for PDF, export, print or attendance work.

## 3. Source-command lock inventory

The following is an inventory of source-stated locks already documented in LOCK-MANIFEST-001 v0.4.26. It is deliberately not a new canonical order. “Snapshot references” means the candidate rows that a source command may need to persist if its event is eligible under a future approved notification policy.

| Source command | Existing source-stated lock/resource set before append-only facts | Snapshot references potentially introduced | Static disposition |
|---|---|---|---|
| CMD-001 request-account-access | L00; caller `app_users` at candidate L15 | app_users | Candidate normalized; account-request lifecycle and UPSERT/trigger edges open |
| CMD-002 approve-account | L00; conditional L10; sorted L15 principals; L16/L17 authority; conditional L18; L110 | app_users plus policy-selected scope refs | Candidate normalized; account/capacity effects open |
| CMD-003 reject-account | Same family as CMD-002 | app_users plus policy-selected scope refs | Candidate normalized; state and capacity effects open |
| CMD-004 grant-role | L00; conditional L10; sorted L15/L16/L17; conditional L18; L110 | app_users; possibly project/session/location/assignment scope refs | Candidate normalized; T-14 and grant interval details open |
| CMD-005 revoke-role | L00; conditional L10; sorted L15/L16/L17; conditional L18; L110 | app_users; possibly scope refs | Candidate normalized; physical row-version and last-admin rules open |
| CMD-006 grant-scope | L00; conditional L10; L15/L16/L17/L18; scope parent L30/L50 when required; L110 | app_users and scope parents | Candidate normalized; scope-type map and interval arbiter open |
| CMD-007 revoke-scope | L00; conditional L10; L15/L16/L17/L18; scope parent L30/L50 only when required; L110 | app_users and scope parents | Candidate normalized; authorization freshness open |
| CMD-008 create-project | L00; L15/L16/L17/L18; L30 project/code arbiter and capacity bootstrap | app_users, projects | Candidate normalized; trigger/FK edges open |
| CMD-009 update-project | L00; L15/L16/L17/L18; L30 project CAS | app_users, projects | Candidate normalized; project row-version absent |
| CMD-010 close-project | L00; conditional L10; L15/L16/L17/L18; L30 parent fence and blockers | app_users, projects and any policy-selected child scope refs | Candidate normalized; child-fence coverage open |
| CMD-011 create-session | L00; L30 project parent (proposed KEY SHARE/equivalent); session insert; L90 | app_users, projects, sessions, optional location/assignment | PARTIAL; exact parent lock mode not reconciled with project close |
| CMD-012 update-session | L00; session then project/dependencies | app_users, projects, sessions, optional location/assignment | BLOCKED; session-first order conflicts with parent-first proposal |
| CMD-013 transition-session | L00; session then closure dependencies | app_users, projects, sessions, optional location/assignment | BLOCKED; parent/session order and blocker set unresolved |
| CMD-014 publish-assignment | L00; conditional L10; project/session/assignment refs; instrument/version/user refs; assignment/member writes | app_users, projects, sessions, locations, operational_assignments, assignment_members | PARTIAL; parent comparator and instrument rank unresolved |
| CMD-015 change-assignment-members | L00; conditional L10; assignment; assignment_members and users | app_users, projects/sessions/locations/assignment refs | PARTIAL; parent fence and eligibility writers incomplete |
| CMD-016 change-inspector-capacity | L00; L10 capacity row; eligibility rows; capacity update | app_users and scope refs if policy selects them | PARTIAL; exhaustive eligibility writer set open |
| CMD-017 manage-target-plan | L00; L30 project/session; target plan; allocations | app_users, projects, sessions, optional location/assignment | PARTIAL; plan/session relation and allocation key open |
| CMD-018 create-instrument | L00; unique instrument-code arbitration; instrument insert | app_users; instrument refs only if selector/scope contract requires them | PARTIAL; no parent row lock specified |
| CMD-019 save-instrument-draft | L00; L40 instrument/version; child configuration rows | app_users; instrument/version refs if part of approved notification scope | BLOCKED; instrument/assignment rank and config hash open |
| CMD-020 publish-instrument-version | L00; L40 instrument/version; child validation; publication/audit | app_users; instrument/version refs if required | PARTIAL; immutable snapshot enforcement open |
| CMD-021 deactivate-instrument | L00; instrument; assignment reference checks | app_users; instrument/assignment refs if required | BLOCKED; token and instrument/assignment order open |
| CMD-022 register-canonical-unit | L00; L20 canonical serial key; context authorization; unit insert | app_users; project/session/location/assignment refs if required | PARTIAL; context-vs-canonical-key order open |
| CMD-023 associate-unit-to-project | L00; source recipe unit L50 → project L30 → association L60 | app_users, projects, sessions, locations, assignments | BLOCKED; source order conflicts with parent-before-unit hierarchy |
| CMD-024 end-unit-project-association | L00; unit/association/active claim/inspection dependencies | app_users and all selected project/session/location/assignment refs | BLOCKED; complete deterministic order absent |
| CMD-025 resolve-unit-identity-conflict | L00; conflict row → candidate unit → project/association key | app_users and selected scope refs | BLOCKED; conflict-first rank unresolved |
| CMD-026 claim-unit | L00; L20 canonical key → L30 project/session/assignment → L50 unit → L60 association → L70 inspection/claim | app_users, projects, sessions, locations, assignments | BLOCKED; catalogue/detail lock conflict remains |
| CMD-027 release-unit-claim | L00; source recipe unit → association → assignment → claim → inspection | app_users and selected scope refs | BLOCKED; differs from candidate global order |
| CMD-028 save-draft | L00; inspection aggregate → claim/association/assignment dependencies → response children | app_users, projects, sessions, locations, assignments | BLOCKED; aggregate-first vs parent-first conflict |
| CMD-029 submit-inspection | L00; inspection → claim/association/assignment/evidence → revision/events | app_users, projects, sessions, locations, assignments | BLOCKED; dependency order and evidence race open |
| CMD-030 return-inspection | L00; inspection → target revision → review-decision key | app_users, projects, sessions, locations, assignments | BLOCKED; review decision uniqueness/order open |
| CMD-031 approve-inspection | L00; inspection → current revision/reviewer assignment → review/inspection/audit facts | app_users, projects, sessions, locations, assignments | BLOCKED; child locks and terminal arbiter open |
| CMD-032 reopen-inspection | L00; inspection → approved revision and active-work blockers | app_users, projects, sessions, locations, assignments | BLOCKED; blocker locks and worker race open |
| CMD-033 create-upload-intent | L00; inspection; conditional quota/reservation; pending evidence | app_users, projects, sessions, locations, assignments | BLOCKED; quota/evidence keys open |
| CMD-034 confirm-upload | External Storage inspection before DB locks; then L00, evidence, inspection/claim/assignment revalidation | app_users and selected source scope refs | BLOCKED; external boundary and evidence-vs-inspection order open |
| CMD-035 sync-batch | L00; inspection rows sorted or per-operation transactions; operation-specific children | app_users and per-operation source scope refs | BLOCKED; transaction granularity not selected |
| CMD-036 generate-approved-document | Short transaction L00; source/document generation key; pending document/job/outbox; worker/render/finalize separately | app_users and source scope refs only if a separate notification is emitted by an approved source event | BLOCKED; document job schema/worker ACL open; its job outbox is not notification_outbox |
| CMD-037 record-print | L00; document aggregate/version; sequence allocator; print/audit facts | app_users and source scope refs if approved policy selects print events | BLOCKED; sequence allocator missing |
| CMD-038 record-print-batch | Batch L00/envelope; per-item document/version/sequence and event | app_users and per-item source scope refs if approved | BLOCKED; durable item manifest incomplete |
| CMD-039 upload-attendance-document | L00; attendance record; conditional quota/reservation; pending document; Storage outside transaction | app_users and attendance scope refs | BLOCKED; intent/version and authority open |
| CMD-040 verify-attendance | L00; attendance record; exact attendance document; append-only verification fact | app_users and attendance scope refs | BLOCKED; SoD/version and verify-vs-replace fence open |

**Interpretation:** This table captures documented source lock statements, not proof that the lock sets are complete. The source command's event-type mapping and notification-policy eligibility are not yet canonical. Any source event not on an approved allowlist must not create an outbox row.

## 4. Candidate snapshot FK/implicit-lock crosswalk

The only currently described snapshot relation is candidate-only `notification_outbox_recipients`. Its proposed fields are `outbox_id`, `recipient_user_id`, optional `project_id`, `session_id`, `location_id`, `assignment_id`, `scope_snapshot_hash`, and `resolved_at`. The current proposal suggests an FK to the outbox and app user, plus composite scope FKs or a trusted scope assertion. None is admitted.

| Candidate FK/reference | Referenced resource/rank candidate | Possible implicit effect during INSERT | Required proof before admission |
|---|---|---|---|
| `outbox_id → notification_outbox.id` | Outbox/queue resource; no approved rank | FK validation against parent outbox row | Define source transaction insert order; avoid holding an outbox/queue row before later lower-rank references |
| `recipient_user_id → app_users.id` | L15 | PostgreSQL FK validation can take KEY SHARE on referenced principal row | Source transaction must already hold the same referenced principal row under the approved mode/order; deterministic recipient UUID order |
| `project_id → projects.id` | L30 | KEY SHARE may be taken on referenced project row | Acquire/validate project parent before insert; align with project closure fence |
| `session_id → sessions.id` | L30 | KEY SHARE may be taken on referenced session row | Acquire project then session in deterministic order; reconcile CMD-012/013 |
| `location_id → locations.id` | Candidate scope rank not yet explicit; likely within operational scope ordering, NOT assigned here | KEY SHARE may be taken on referenced location row | Assign a reviewed rank and composite parent integrity; stable ID order |
| `assignment_id → operational_assignments.id` | L50 | KEY SHARE may be taken on referenced assignment row | Acquire project/session/location/assignment parents in one approved order; reconcile CMD-014/015 |
| Composite scope FK(s) | Multiple parent classes | May check multiple referenced rows; exact lock sequence depends on FK definition and executor plan | Publish exact DDL/constraint list and prove referenced-row lock order; no polymorphic-FK assumptions |

PostgreSQL row-lock compatibility and FK implementation details must be verified against the supported PostgreSQL version and exact DDL. This static crosswalk is not a claim that every FK check always creates a conflicting lock or that a deadlock has already occurred.

## 5. Required source transaction protocol — candidate, not approved

The following is the only acceptable shape for further design review. It does not authorize implementation.

1. **Idempotency first:** acquire the command's idempotency arbitration point (candidate L00) and reject same-key/different-payload replay.
2. **Resolve policy and bounded selector inputs:** read one immutable policy version and its allowlisted selector grammar. Do not run arbitrary SQL or accept client-selected recipients. Policy selector grammar and policy administration authority remain OPEN.
3. **Discover candidate identifiers without claiming authorization:** obtain the bounded candidate principal and scope key set needed for the event-time audience. Reads alone are not the final eligibility decision.
4. **Acquire mutable eligibility/scope references in one reviewed global order:** lock all candidate `app_users` (L15), `user_roles` (L16), `user_scope_grants` (L17), and any approved mutable authorization catalog rows (L18), then the applicable project/session (L30), instrument/version (L40), assignment/location (L50 and any separately approved location rank), and assignment membership (L55) rows. Sort each class by stable primary/canonical key. This is a candidate sequence; LPR approvals and the complete cross-command graph are still required.
5. **Acquire the source command's remaining aggregate/resource locks:** only after the above pre-acquisition, acquire the source command's remaining L20/L60/L70/L80/L90/L100 resources in the final approved order. This step cannot be applied mechanically to current blocked CMD-012/013/023–032 recipes; those commands first require their own lock manifests to be normalized.
6. **Revalidate after locks:** re-evaluate account status, active role/scope grants, assignment membership/effective intervals, project/session state, source resource state, policy version and exact selector predicates. Compute the event-time candidate set from the locked, authoritative state and the source command's intended state transition. For self-revocation/eligibility-changing commands, explicitly define whether the actor/target is included under the post-transition snapshot; never infer.
7. **Perform the source mutation and append facts:** in the same transaction, perform the business mutation, append the canonical domain event and required audit event, insert the notification outbox intent, insert the deduplicated candidate recipient/scope rows, and finalize snapshot version/hash/count/completion metadata. The outbox must not become claimable until snapshot completeness is established.
8. **Commit atomically:** any required mutation, audit, outbox or snapshot failure rolls back the source transaction. No external provider I/O occurs in this transaction.
9. **Worker isolation:** CMD-052 claims one bounded outbox row in a short transaction and commits the lease before reading candidate rows/materializing inbox rows. It must not hold the outbox claim lock while acquiring domain/authorization locks or doing provider I/O. CMD-053 performs provider I/O outside DB transactions and uses a separate guarded finalization transaction.
10. **Escalation isolation:** CMD-054 captures one DB UTC instant, pins the policy version, arbitrates the unique escalation event and persists its own outbox plus event-time snapshot atomically. Its policy/notification locks must be reconciled against L15–L55 before any snapshot FK write.

**Important:** step 4 is not a blanket instruction to lock every user or every assignment. It applies only to the bounded candidate set and exact scope references required by an approved selector. Lock footprint, maximum audience size, chunking semantics and fan-out bounds must be decided before implementation.

## 6. Lock-order risk register and closure criteria

| ID | Risk | Required closure evidence | Owner | Status |
|---|---|---|---|---|
| NSL-01 | No canonical event-type → source CMD → notification policy allowlist | Approved matrix with exact event key, source CMD, selector version, scope tuple and policy version behavior | Product Owner + Engineering | OPEN |
| NSL-02 | Source command may hold L30/L50/L55 before snapshot FK takes L15/L16/L17 KEY SHARE | Per-source normalized manifest proves all candidate principal/authorization/scope references are pre-acquired in global order | Engineering + Database | OPEN |
| NSL-03 | Snapshot FK definitions are not admitted or fully specified | Exact PK/unique/FK/composite-FK DDL proposal, nullability, delete behavior and index list; static constraint-edge review | Database | OPEN |
| NSL-04 | CMD-012/013 session-first and CMD-023/024/025/027/028–032 conflicting source orders | Updated per-command manifests plus opposing-command graph reconciliation | Engineering | OPEN |
| NSL-05 | Mutable eligibility writers may race snapshot resolution | Complete writer inventory for account disable/suspension, role grant/revoke/expiry, scope grant/revoke/expiry, assignment/member start/end/expiry, capacity and parent closure | Engineering + Security | OPEN |
| NSL-06 | Location rank and composite scope integrity are undefined | Approved location resource rank, parent relationship and composite-FK/lock order | Database + Engineering | OPEN |
| NSL-07 | Source snapshot could reflect ambiguous pre/post mutation eligibility | PO-approved event-time semantics for every eligibility-changing source event, including self/target revocation and account suspension | Product Owner + Security | OPEN |
| NSL-08 | Candidate audience size may create unbounded source transaction | Approved maximum candidate count, deterministic batching/atomicity strategy and rejection/deferral behavior | Product Owner + Engineering | OPEN |
| NSL-09 | Worker claim/fan-out could reverse domain lock order | Separate transaction proof: claim+commit, then read candidates/materialize; finalizers do not retain queue locks across domain locks | Engineering + Security | OPEN |
| NSL-10 | Global acyclicity is unproven | Complete directed lock-edge inventory including explicit locks, FK, unique/exclusion arbitration, triggers, functions and workers; static cycle check plus runtime adversarial tests after G10 | Engineering + Database + QA | OPEN |

## 7. Global graph additions and opposing-path tests

Add these edges to LOCK-GRAPH-001 only as candidate edges until ranks and DDL are approved:

- Source command → L15 principal rows required by candidate audience.
- Source command → L16 role rows and L17 scope-grant rows used by the selector.
- Source command → L30 project/session scope references.
- Source command → approved location rank and L50 assignment/L55 membership references.
- Snapshot INSERT → implicit FK checks for every declared referenced key.
- CMD-052 fan-out → outbox claim row, then candidate rows, then notification/delivery inserts in a separate transaction.
- CMD-054 → notification/policy serialization rows, then recipient/scope eligibility rows and snapshot FK checks; exact order remains open.

Required adversarial scenarios (specification only; NOT EXECUTED):

| Test ID | Competing transactions | Required assertion |
|---|---|---|
| NSL-T01 | CMD-014 assignment publication vs source notification snapshot | No assignment/member FK edge is acquired after a higher-ranked lock if the competing path holds L15/L16/L17 |
| NSL-T02 | CMD-005 role revoke vs CMD-014/015 source snapshot | Same T-14/eligibility serialization point; no stale recipient candidate |
| NSL-T03 | CMD-007 scope revoke vs CMD-011/017/023 source snapshot | Scope snapshot is either committed before revoke or reflects revocation; no mixed authorization |
| NSL-T04 | CMD-010 project close vs CMD-011/014/017 source snapshot | Source child operation and snapshot obey the same parent fence; no notification for rejected post-close work |
| NSL-T05 | CMD-012/013 session transition vs CMD-014/015/017 source snapshot | Parent/session lock order is identical and acyclic |
| NSL-T06 | CMD-023/026 association/claim vs source snapshot | Canonical key → parent → assignment → unit → association → claim/inspection order is consistent after approval |
| NSL-T07 | CMD-052 claim/reclaim vs fan-out materialization | Claim lock is committed before candidate processing; stale worker cannot finalize |
| NSL-T08 | CMD-054 duplicate scheduler ticks vs CMD-051 policy publication and scope revocation | One unique escalation event; pinned policy; event-time recipient set; no widening |
| NSL-T09 | Two source commands insert overlapping candidate snapshots | Principal/scope rows acquired in deterministic key order; no cycle from recipient/scope FK checks |
| NSL-T10 | Inject FK violation and uniqueness conflict on each candidate reference | Error/rollback behavior is atomic; lock graph and retry semantics are observed, not assumed |

## 8. Required SSOT updates before any admission

When the decisions and evidence exist, update together:

1. PostgreSQL Command Contract Catalogue: explicit notification-eligible source event allowlist and source transaction snapshot contract.
2. All affected detailed CMD reviews: source-specific normalized lock manifest, pre-acquired candidate reference set and event-time audience semantics.
3. NLA-001: exact selector grammar, immutable snapshot header/recipient schema, scope checkpoint, bounded audience and retry behavior.
4. Physical Database Schema and ERD: exact admitted table/columns/constraints/indexes only after Database review.
5. RLS/command reconciliation and privileged function security design: internal worker and source-command access boundaries.
6. Global lock graph and command-level lock manifest: every explicit/implicit edge and approved resource rank.
7. Test Case Catalog/UAT, RTM, RAID and DGA: trace each risk and test to closure evidence.

Do not mark a blocker closed merely because this document records a candidate protocol.

## 9. Certification status at this checkpoint

| Gate/evidence | Status |
|---|---|
| Source command search surface CMD-001–040 inventoried | DOCUMENTED — policy/event allowlist still OPEN |
| CMD-054 separate scheduler source identified | DOCUMENTED — lock order OPEN |
| CMD-052/CMD-053 classified as consumers | DOCUMENTED |
| Candidate snapshot FK reference set inventoried | DOCUMENTED — DDL NOT ADMITTED |
| Snapshot lock-order protocol | CANDIDATE ONLY — NOT APPROVED |
| Per-command application lock certification | 0/50 certified; unchanged |
| Global lock graph acyclic | NOT PROVEN |
| Notification QA/runtime tests | NOT EXECUTED |
| G9 | NOT READY |
| G10 | NOT ACTIVE |

No code, SQL, migration, RLS/grant, database mutation, deployment or runtime test is performed or authorized by this document.
