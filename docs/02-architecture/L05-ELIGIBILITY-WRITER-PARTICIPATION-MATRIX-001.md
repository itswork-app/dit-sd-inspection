# L05 Eligibility-Writer Participation Matrix

**Document ID:** NLA-L05-WRITER-MATRIX-001  
**Version:** 0.1.6  
**Status:** STATIC INVENTORY — INCOMPLETE; NOT CERTIFIED  
**Date:** 2026-11-25  
**Inputs:** NLA-L05-TDR-001 v0.1.14; NLA-L05-EVENT-SELECTOR-REGISTRY-001 v0.1.4; L05 source-event map v0.1.1; LOCK-MANIFEST-001 v0.4.32; PostgreSQL Command Contract Catalogue v0.4.8; Function Security & EXECUTE Grant Design v0.3.3; physical schema proposal v0.4.8

## 1. Purpose and decision boundary

This matrix inventories known command-level and non-command writer classes that may change notification recipient or scope eligibility. It is an evidence register, not proof that every physical writer has been discovered. The exact selector grammar and complete physical call graph are not approved; therefore the universe of eligibility-affecting rows cannot yet be proven exhaustive.

**Candidate rule:** every transaction that can change a row or effective-time predicate used by an enabled notification selector must acquire candidate L05 after L00 idempotency arbitration and before its first conflicting mutable lock. It must use the same registered key pair and transaction lifetime as source-event resolvers. Expiry caused only by wall-clock passage has no writer transaction; it must be evaluated against the one post-L05 `audience_evaluated_at`.

No direct table write, alternate RPC, SECURITY DEFINER helper, trigger, cascade, administrative script, import, sync, repair or scheduled task may bypass the rule. A trigger that acquires L05 after its caller has already acquired a higher-ranked lock is not an acceptable repair.

## 2. Command-level writer inventory

| Eligibility domain / mutable resource | Known command/event paths | Other known or possible writers | Required candidate participation point | Current evidence / unresolved items |
|---|---|---|---|---|
| Account approval and login eligibility | CMD-002 approve-account; CMD-003 reject-account | Admin support actions; account disable/suspend/reactivate paths not mapped to stable command IDs; auth/account reconciliation jobs | L05 before target `app_users` and any capacity/role row locks | Command paths mapped; complete account lifecycle writer inventory absent; exact app_users state fields and auth-provider sync ownership open |
| Role grants and revocations | CMD-004 grant-role; CMD-005 revoke-role | Role expiry/renewal/delegation maintenance; admin repair; role synchronization/import | L05 before `user_roles`, grantor/delegation and authorization catalogue rows | Grant/revoke commands mapped; expiry is time-derived and must use captured instant; renewal/delegation writer IDs and direct-DML denial evidence open |
| Permission/role catalogue | CMD-004/005 read role/permission catalog; no approved catalogue-mutation command identified | Migration/admin maintenance, permission-bundle import, privileged repair | If mutable at runtime, L05 before `roles`, `permissions`, `role_permissions`; otherwise prove immutable/frozen after bootstrap | No runtime mutation path approved; immutability/freeze proof and owner/ACL evidence open |
| Scope grants and delegation | CMD-006 grant-scope; CMD-007 revoke-scope | Scope expiry/renewal/reassignment, administrative repair/import | L05 before `user_scope_grants` and any mutable scope-parent row | Command paths mapped; exact scope parent taxonomy, lifecycle and non-command writer paths open |
| Inspector capacity and qualifying population | CMD-002/003 when account eligibility changes; CMD-004/005 when Inspector role eligibility changes; CMD-014/015 assignment roster changes; CMD-016 change-inspector-capacity | Scheduled reconciliation or admin repair of qualifying counts/capacity settings | L05 before L10 capacity fence and every qualifying account/role/assignment row, subject to final L05/L10 graph approval | T-14 predicate known; full affected-project set and one canonical L05/L10 order not approved |
| Project lifecycle and scope | CMD-008 create-project; CMD-009 update-project; CMD-010 close-project | Admin/import/repair of project status, timezone or scope fields; trigger/cascade effects | L05 before project row and dependent lifecycle locks when those fields participate in selectors | Command-level paths known; direct DML, trigger/cascade and child-fence inventory open |
| Session lifecycle and scope | CMD-011 create-session; CMD-012 update-session; CMD-013 transition-session | Administrative correction/import; scheduled close/reconciliation if introduced | L05 before project/session parent locks and dependent child locks | CMD-012/013 source order and closure dependency order remain blocked; non-command lifecycle writers unverified |
| Assignment and membership | CMD-014 publish-assignment; CMD-015 change-assignment-members | Membership expiry/renewal/reconciliation, administrative roster import/repair | L05 before L10 (if T-14 applies), project/session, assignment and membership locks | Command paths known; exact writer functions, expiry maintenance and all roster mutation routes open |
| Location/team/operational scope | CMD-014 assignment references; CMD-015 membership references; CMD-010/012/013 lifecycle interactions | Location/team create/update/deactivate/reassign paths not mapped to stable command IDs; imports/repair | L05 before any mutable location/team/scope parent that participates in selectors | Physical tables are proposed; full CRUD command inventory and selector dependency proof absent |
| Instrument/version selector dependencies | CMD-018 create-instrument; CMD-019 save-instrument-draft; CMD-020 publish-instrument-version; CMD-021 deactivate-instrument; CMD-014 assignment publication | Catalogue import/repair and any instrument lifecycle maintenance | L05 only if the approved selector grammar depends on instrument/version state; then before instrument/version/assignment locks | Whether instrument state is a recipient selector is not established; do not include or exclude until selector grammar is frozen |
| Canonical unit and association selector dependencies | CMD-022 register-canonical-unit; CMD-023 associate-unit-to-project; CMD-024 end association; CMD-025 resolve identity conflict; CMD-026 claim-unit; CMD-027 release claim | Unit/association reconciliation and administrative repair | L05 only if approved selectors depend on unit/association/claim state; then before L20/L30/L50/L60/L70 and related locks | Selector dependency not established; CMD-023–027 lock-order conflicts remain blockers |
| Inspection and evidence lifecycle selector dependencies | CMD-028–034 inspection, revision, evidence and upload commands; CMD-035 sync-batch | Async upload confirmation, sync replay/reconciliation and evidence repair | L05 only if selectors depend on inspection/evidence state; otherwise prove exclusion. For eligible events, before inspection/claim/evidence locks | Exact selector dependency and CMD-035 per-operation transaction/savepoint contract open |
| Document generation / print / attendance lifecycle | CMD-036–040; CMD-038 per-document print item events | Renderer finalizer, print worker, attendance upload finalizer and verifier | Event-producing finalizer/command acquires L05 before lease/source/document/attendance locks; external render/Storage stays outside DB transaction | Worker/finalizer identities, lease functions, exact source version and institutional attendance authority open |
| Notification policy publication | CMD-051 publish-notification-policy | Policy retirement/effective-window update; administrative repair or direct policy table mutation | L05 before policy version/aggregate locks; resolver reads policy after L05 in a later SQL command | CMD-051 identified; retirement/effective-window writer and policy admin ACL/SoD not approved |
| Notification escalation | CMD-054 evaluate-notification-escalation | Scheduler duplicate ticks, retry/reclaim and operational replay | Each bounded evaluation transaction acquires L05 before mutable policy/recipient/escalation locks; capture evaluation instant after lock | Scheduler principal/ACL and exact lock order open |
| Notification fan-out / delivery | CMD-052 fanout; CMD-053 dispatch | Worker reclaim, retry, provider callback integration INT-NOTIF-001 | CMD-052 consumes immutable candidates and must not re-resolve eligibility; CMD-053 does not change source eligibility | Candidate snapshot relation NOT ADMITTED; worker identity/ACL and provider callback boundary open |
| Direct browser/API DML | No command ID; protected tables are intended to deny direct browser DML under T-18 | Supabase REST table endpoints, alternate RPCs, service-role clients | Must be denied or routed exclusively through reviewed command wrappers that acquire L05 | Proposed security model exists; deployed GRANT/RLS evidence not available; cannot certify bypass prevention |
| SECURITY DEFINER functions and internal helpers | CMD-001–054 wrappers/helpers; exact names not yet physicalized | Nested helper calls, owner-role bypass, SECURITY DEFINER search_path and EXECUTE ACL | Entry wrapper acquires L05 before calling any helper that can lock/mutate eligibility; helper must not acquire L05 late | Function inventory and per-function owner/search_path/ACL review not complete |
| Triggers, cascades, deferred constraints and FK side effects | Any command touching eligibility or selector-parent rows | Row/statement triggers, cascading FK actions, deferred triggers/constraints | Must not acquire L05 after higher-ranked row locks; include every implicit lock edge in graph | Exact trigger/cascade/deferred constraint inventory and DDL absent/unverified |
| Imports, bulk administration and repair | No complete stable command-ID mapping | One-off SQL, backfill, import jobs, support scripts, repair/reconciliation tasks | Either prohibit after controlled bootstrap or route through approved guarded transactions; batch must define bounded per-item atomicity | No exhaustive job/script inventory or evidence of prohibition |
| Scheduled expiry and lifecycle maintenance | No stable command IDs for time-derived expiry; CMD-054 is scheduler for escalation only | Expiry workers, nightly reconciliation, lifecycle sweeps | Pure time passage is evaluated using captured `audience_evaluated_at`; any materialized state update must acquire L05 before mutable locks | Existence and ownership of maintenance workers not established |
| Database ownership / emergency mutation | No application command ID | Owner/superuser, migration role, emergency console, provider dashboard | Define approved maintenance window and prove no concurrent source resolver can observe an unguarded mutation; otherwise prohibit concurrent bypass | Operations and provider ownership evidence absent; cannot certify |

## 3. Mandatory evidence needed to close this matrix

1. Freeze the exact notification selector grammar and list every source column/table referenced by every enabled selector.
2. Enumerate all exposed PostgREST RPC functions, internal helpers, triggers, event triggers, cascades, deferred constraints and job entrypoints from the exact deployed migration/catalog state.
3. Map every function to its caller roles, owner role, volatility, SECURITY DEFINER/INVOKER mode, pinned search_path and EXECUTE ACL.
4. Prove browser roles cannot directly mutate protected tables and that no service-role or admin script bypass exists during normal operation.
5. Inventory all imports, sync, repair, backfill, scheduled expiry and admin/support jobs, with owner, schedule, transaction boundary and mutation set.
6. For every writer, record exact table/columns, operation, acquisition point, L05 key identity, transaction scope, first mutable lock, post-lock order, retry behavior and evidence.
7. Include all FK/unique/trigger/helper edges in the global graph; prove acyclicity after source and writer mappings are reconciled.
8. Add opposing-transaction tests for each distinct writer class, including a writer that commits while a source transaction waits for L05.

## 4. Certification disposition

| Measure | Status |
|---|---|
| Known command-level writer classes identified | PARTIAL — command IDs mapped where present |
| Non-command writer classes identified | PARTIAL — classes listed, actual entrypoints/owners absent |
| Exact RPC/function/trigger/admin/import/repair/scheduler inventory | NOT COMPLETE |
| Selector dependency universe frozen | NOT APPROVED |
| All eligibility-changing writers proven to acquire L05 | 0 certified |
| Direct-DML and privileged bypass prevention | NOT VERIFIED |
| Global lock graph acyclicity | NOT PROVEN |
| G9 / G10 | NOT READY / NOT ACTIVE |

This matrix does not authorize implementation, SQL, migration, grants/revokes, RLS changes, live database inspection, runtime tests, deployment or merge.


## 6. Source baseline refresh — 2026-11-24

The current candidate lock-manifest baseline is LOCK-MANIFEST-001 v0.4.30, including the CMD-031–040 candidate overlay in §7.13. This refresh does not expand the physical writer inventory or change its certification state. Exact deployed RPC/helper/trigger/job names, selector dependency universe, ownership/ACL, direct-DML bypass proof and admin/import/repair/expiry paths remain unavailable. The matrix remains INCOMPLETE; no writer is certified to participate in L05.


## 7. POQ-04 selector grammar dependency — 2026-11-24

POQ-04 is PO APPROVED, but the exact selector grammar remains unapproved technically. The current §1/§2 writer inventory cannot be considered exhaustive until F05-T1 freezes every selector kind, event allowlist, principal/scope reference, boolean dependency, effective-time predicate and referenced column/table. A selector that references a new field or parent resource changes the eligibility-writer universe and may introduce a new lock/FK/trigger edge.

**Required reconciliation before certification:**
1. Build a selector-to-column/table dependency map from the versioned grammar and every enabled policy version.
2. Join each dependency to command and non-command writer paths, including direct DML, SECURITY DEFINER helpers, triggers/cascades, imports, sync, repair, expiry, admin and scheduler paths.
3. For every writer, prove L05 acquisition before the first conflicting mutable lock, and include implicit FK/unique/trigger/helper edges.
4. Re-run global graph acyclicity analysis after the dependency map is complete.
5. Reject any policy selector that references an unregistered dependency or exceeds approved depth/cardinality bounds.

**Status:** selector dependency universe NOT FROZEN; exact physical writer inventory INCOMPLETE; 0 writers certified to participate in L05. This addendum does not alter the 0/40 resolver and 0/50 application certification counts, and does not authorize implementation or database operations.


## 8. Selector grammar v1 dependency intake — 2026-11-24

TDR v0.1.8 proposes only ROLE_SCOPE and EVENT_PARTICIPANT selector clauses, but the proposal is not yet approved. The eight-clause cap is provisional. Before a selector is enabled, its event registry entry must enumerate every consulted principal, role, grant, assignment/member, scope-parent and effective-time dependency. The writer inventory must be generated/reconciled from those dependencies, not inferred from the CMD list alone.

**Required intake per exact event token:** event type; source CMD/worker; source transaction boundary; grammar version; allowed clause kinds; participant-to-canonical-principal mapping; scope binding and cardinality; dependency references; dispatch profile; and effective policy interval. Composite/conditional CMD declarations must be split before they enter the enabled event registry.

**Writer-matrix effect:** the candidate grammar narrows the allowed selector language but does not establish the actual dependency universe. Every registry dependency must be joined to command writers and non-command paths (direct DML, SECURITY DEFINER, triggers/cascades, imports, sync, repair, expiry, admin and scheduled jobs). Any unregistered dependency or writer invalidates certification. Status remains INCOMPLETE; 0 writers certified to participate in L05.


## 9. Event-to-selector dependency crosswalk — 2026-11-25

[NLA-L05-EVENT-SELECTOR-REGISTRY-001](L05-EVENT-TO-SELECTOR-REGISTRY-001.md) v0.1.4 maps CMD-001–040 source declarations, the eleven PO-approved specification candidates, candidate ROLE_SCOPE/EVENT_PARTICIPANT clause families, conceptual participant/scope bindings, and the logical writer domains that must be reconciled.

Use the crosswalk to derive the exact selector dependency universe; do not treat its logical resource classes as physical columns or an exhaustive deployed writer list. The selector grammar remains a review candidate, no event is enabled, and no writer is certified to acquire L05. Exact function/trigger/FK/helper/import/expiry/repair entrypoints, ownership, ACL, bypass prevention and complete lock graph remain OPEN. Resolver certification 0/40; application lock certification 0/50; G9 NOT READY; G10 NOT ACTIVE.


## 10. Post-F05-T5 writer inventory boundary — 2026-11-25

The current crosswalk is NLA-L05-EVENT-SELECTOR-REGISTRY-001 v0.1.4, with candidate selector grammar hardening (F05-T1), dispatch review (F05-T2) and atomic source-event/snapshot binding (F05-T5). This matrix now points to those versions; the update is a documentation pointer reconciliation only.

The repository's current `main` contains project documentation, `AGENTS.md` and `README.md`, but no application source tree, executable migration history or deployed database catalog snapshot. The current governance boundary also does not authorize live database inspection. Consequently, the following cannot be truthfully enumerated or certified from repository evidence: actual deployed RPC/function names, SECURITY DEFINER ownership/search_path/EXECUTE ACL, trigger/cascade/deferred-constraint inventory, PostgREST grants, scheduled job definitions, import/sync/repair scripts, support/admin entrypoints, emergency mutation paths or direct-DML bypasses.

**F-04 remains OPEN — NOT CERTIFIED.** The command-level rows and non-command writer classes in §2 are logical inventory candidates, not a complete physical writer inventory. No writer is certified. Do not convert a class name into an assumed deployed entrypoint, infer a Supabase object from the proposed schema, or treat the 40/40 source declaration map as writer coverage.

### 10.1 Required evidence package for physical inventory

When the required read-only environment access is separately authorized, capture and review an immutable inventory tied to the exact deployed migration/schema revision:
1. Supabase/PostgreSQL catalog extracts for schemas, tables, columns, constraints, indexes, triggers, trigger functions, policies, grants, roles and function metadata.
2. PostgREST-exposed RPC inventory plus all internal functions reachable from those entrypoints; record owner, SECURITY DEFINER/INVOKER, volatility, pinned search_path, EXECUTE grants and nested calls.
3. Scheduled jobs, queue workers, webhook/provider callbacks, imports, sync, backfills, support/admin scripts, repair/reconciliation and emergency procedures, with owner and execution identity.
4. Per-selector dependency columns and relations from the approved exact selector registry; join every dependency to all mutating entrypoints and implicit FK/trigger/helper edges.
5. A writer-by-writer evidence row: deployed name, source revision, principal, mutation set, transaction boundary, first lock, L05 acquisition point, retry semantics, bypass control, reviewer and evidence reference.
6. Negative authorization evidence proving browser/ordinary roles cannot mutate protected eligibility rows outside reviewed wrappers.

Until this package exists, resolver certification remains 0/40, application lock certification 0/50, writer certification 0, global lock graph NOT PROVEN ACYCLIC, G9 NOT READY and G10 NOT ACTIVE.
