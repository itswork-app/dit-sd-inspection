# L05 Event-to-Selector Registry — Candidate v1

**Document ID:** NLA-L05-EVENT-SELECTOR-REGISTRY-001  
**Version:** 0.1.4  
**Status:** STATIC CROSSWALK / REVIEW CANDIDATE — NOT APPROVED, NO EVENT ENABLED  
**Date:** 2026-11-25  
**Baseline:** `main` at `4c72c9a0bf634e6c8f58f40527b5662c612b1da2`  
**Authority:** AGENTS.md v1.2.3; Decision Register POQ-01 and POQ-04; NLA-L05-TDR-001 v0.1.11; NLA-EVENT-REGISTRY-001 v0.1.13; NLA-EVENT-TRIAGE-001 v0.1.3; L05 source-event map v0.1.1; L05 writer matrix v0.1.5.

## 1. Purpose and decision boundary

This document is the event-to-selector crosswalk requested for F-05/F-04 review. It consolidates the CMD-001–040 source-event declarations, the eleven Product Owner-approved first-batch notification candidates, candidate selector grammar v1, trusted participant/scope questions, and the logical eligibility-writer dependencies that must be considered before L05 can be certified.

It is a **static review artifact**, not an enabled event allowlist, executable policy registry, canonical schema, SQL contract, lock manifest approval, or implementation instruction.

The Product Owner approved eleven candidate intents for specification and technical review only. POQ-04 approved five transition-semantic recommendations. Neither approval admits a selector, participant field, role ID, scope ID, event payload, dispatch profile, physical relation, L05 rank/key, grant, or runtime behavior.

**Hard boundary:** all events in this document remain `NOT ENABLED`. Unknown participant mappings, scope bindings, dependency columns, or source transaction boundaries stay explicitly unresolved. Do not fill gaps by guessing from actor/target fields, role names, assignment membership, UI context, or audit records.

## 2. Binding invariants

1. **Exact event identity:** policy matching is by one exact canonical event token. No wildcard, prefix matching, slash alternatives, conditional prose, or implicit matching of all events emitted by a command.
2. **Immutable event-time audience:** for a policy-eligible event, the candidate audience and authorized scope/checkpoint are resolved once and persisted with the source event. Fan-out and retries reuse the same candidate set.
3. **POQ-04 transition rule:** the five approved transition outcomes use the serialized pre-mutation state and one captured `audience_evaluated_at`. The source mutation, canonical event, audit, idempotency outcome, outbox intent, policy pin, and complete candidate snapshot must share the approved atomic transaction boundary.
4. **No implicit participants:** actor, target, and affected member are candidates only when the exact event selector independently selects a trusted, explicitly mapped participant. No actor/target/member is silently appended.
5. **Suppression is not audience mutation:** dispatch-time account, channel, consent/revocation, current-scope, parent-state, and mandatory security checks may suppress an existing candidate under the pinned dispatch profile. They may never add a recipient, replace a recipient, rewrite the snapshot, or reset its checkpoint.
6. **Independent resource authorization:** receiving a notice does not authorize opening the referenced inspection, project, session, document, evidence, or other resource.
7. **Fail closed:** unknown event token, missing/ambiguous participant mapping, unknown selector key, invalid scope binding, unsupported predicate, or unresolved event cardinality prevents policy publication/admission for that row.
8. **No notification from mere audit activity:** an audit row, read/query, draft save, upload intent, print action, retry, generic update, or batch envelope does not become a user notification source by inference.

## 3. Candidate selector grammar v1

The grammar below transcribes the current TDR review candidate. It is **not approved for policy publication or implementation**.

### 3.1 Envelope

- `grammar_version`: integer exactly `1`.
- `match`: exactly `ANY`.
- `selectors`: array of 1–8 `SelectorClause` entries.
- `ANY` means OR across the top-level clauses only; nested expression trees are not supported.
- The eight-clause limit is provisional and requires Engineering resource-bound validation plus Security/PO approval before it becomes normative.

### 3.2 Permitted clause kinds (candidate only)

**ROLE_SCOPE**

A principal qualifies only when the canonical role and corresponding membership/grant are effective for the scope resolved from the canonical source event at the single captured `audience_evaluated_at`. The exact role identifiers, grant relations, scope taxonomy, source columns, and parent dependencies are not yet admitted. A role label alone never implies a scope.

**EVENT_PARTICIPANT**

Selects only the server-resolved principal reference mapped to a named participant in the exact event contract. Candidate participant names are `ACTOR`, `TARGET`, and `AFFECTED_MEMBER`; each must be explicitly mapped by an approved event contract. `ACTOR` derives from trusted authenticated command/worker identity. `TARGET` and `AFFECTED_MEMBER` cannot be supplied by the client or guessed from arbitrary JSON.

A missing, ambiguous, conditional, or untrusted mapping is a publication-time validation error. The existence of an actor, target, or member in a command request is not enough to make that principal a recipient.

### 3.3 Canonicalization and temporal semantics (candidate only)

- Every clause evaluates against the required serialized event-time state and the same captured instant.
- Effective intervals use the proposed half-open convention `[valid_from, valid_until)`; the interval rule remains subject to approval wherever it changes an existing domain contract.
- Canonicalize clauses by kind and canonical reference values; collapse exact duplicate clauses before policy hashing.
- Deduplicate candidates by the approved candidate identity key. The key and physical representation remain unapproved.
- The authorized scope evidence is the deterministic union of only the scopes selected by matching clauses. Never infer scope from a role label or widen it to a parent/global scope.
- The candidate L05 TDR proposes a post-lock `clock_timestamp()` capture and a separate subsequent SQL statement for resolver reads. This registry does not approve the PostgreSQL primitive, key pair, transaction isolation, wrapper volatility, or lock order.

### 3.4 Prohibited constructs

No nested boolean logic, NOT, wildcard, prefix match, arbitrary JSON path, SQL/expression text, client principal/scope IDs, unknown keys, duplicate keys, unknown grammar versions, unbounded arrays, or implicit participant expansion. Unsupported syntax must fail closed and be auditable without logging sensitive payloads.

## 4. First-batch event-to-selector registry — eleven PO-approved candidates

The following eleven intents are approved only for specification and technical review. Selector kind, participant mapping, scope binding, and dispatch profile are candidate placeholders until the exact trusted source contract is approved.

| Registry ID | Exact candidate event | Candidate selector / participant mapping | Candidate scope binding | Writer/dependency domains to reconcile | Current disposition |
|---|---|---|---|---|---|
| NREG-001 | `account.approved` (CMD-002) | Candidate `EVENT_PARTICIPANT: TARGET` only if the requesting-account principal is explicitly projected by the trusted source event. No implicit target. Exact field and identity relation are unresolved. | Account-request identity; no project/location/session scope is presumed. Any operational scope requires an explicit source contract. | Account state / `app_users`; trusted auth identity; actor/target authorization rows; conditional T-14 capacity path if login eligibility changes. | PARTIAL STATIC REVIEW; participant, selector, source payload, dedup and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-002 | `account.rejected` (CMD-003) | Candidate `EVENT_PARTICIPANT: TARGET` only after the exact requesting-account mapping is approved. Target is not auto-added. | Account-request identity; no operational scope is presumed. | Account state / `app_users`; auth identity; actor/target authority; conditional T-14 eligibility path; decision uniqueness. | PARTIAL STATIC REVIEW; participant, selector, source payload, dedup and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-003 | `role.revoked` (CMD-005) | Candidate `EVENT_PARTICIPANT: TARGET` and/or `ACTOR` only when each is independently selected by an exact clause. Candidate `ROLE_SCOPE` may use the pre-revoke grant/scope, but exact role/scope IDs and target projection are unresolved. | Exact revoked grant scope, if any; no global-role or all-project expansion. | `app_users`, `user_roles`, role/permission catalog, `user_scope_grants`, grantor/delegation authority, conditional T-14 capacity rows, and all expiry/renewal/repair writers. | PARTIAL STATIC REVIEW; POQ-04 applies; target/actor mapping, physical version token, selector and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-004 | `project.closed` (CMD-010) | Candidate `ROLE_SCOPE` for assigned operational participants only if the exact policy selects their canonical role and project scope. No project-wide/global broadcast. | Exact project scope and authorized pre-close assignment/location scope; child scope expansion is not inferred. | Project parent and closure fence; sessions, assignments/members, locations/teams, account/role/scope eligibility, T-14 capacity where affected, child writers/finalizers. | PARTIAL STATIC REVIEW; POQ-04 pre-close semantics apply; role/scope IDs, closure event payload, dispatch profile and parent-fence proof UNRESOLVED; NOT ENABLED. |
| NREG-005 | `session.closed` (CMD-013 final transition only) | Candidate `ROLE_SCOPE` for assigned operational participants only if the exact selector selects their canonical role and session scope. `session.close_requested` is not interchangeable and is excluded. | Exact session scope bound to its project and approved assignment/location scope. | Session and project parent fences; assignment/member scope; account/role/scope eligibility; active work and finalizer writers. | PARTIAL STATIC REVIEW; POQ-04 pre-close semantics apply; final source transaction, participant projection, dispatch profile and parent-fence proof UNRESOLVED; NOT ENABLED. |
| NREG-006 | `assignment.created` (CMD-014) | Candidate `EVENT_PARTICIPANT: AFFECTED_MEMBER` only if the command's trusted transaction result defines the exact initial roster and participant semantics. Newly inserted members are not inferred from a post-commit membership query. Actor is not implicit. | Exact created assignment plus its approved project/session/location parents. | T-14 capacity serialization; project/session/assignment parents; assignment-member rows; member principals/roles/scopes; roster creation, import and repair writers. | PARTIAL STATIC REVIEW; initial-roster event projection, pre/post-mutation evaluation rule, member cardinality and dedup UNRESOLVED; NOT ENABLED. |
| NREG-007 | `assignment.changed` (CMD-015) | Candidate `EVENT_PARTICIPANT: AFFECTED_MEMBER` only after the event is decomposed into exact added/ended/retained semantics. For member-end, POQ-04 pre-end selection applies; no replacement member. | Exact assignment and its project/session/location parents; no cross-assignment expansion. | T-14 capacity; assignment/member rows; app-user, role and scope eligibility; membership expiry/renewal/import/repair writers. | PARTIAL STATIC REVIEW; event cardinality, member-delta projection, selector and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-008 | `inspection.submitted` (CMD-029) | Candidate `ROLE_SCOPE` for the assigned Reviewer and/or a trusted `EVENT_PARTICIPANT` mapping only if the exact reviewer-assignment source is approved. Do not infer the Reviewer from the actor, revision author, or generic assignment membership. | Exact inspection, immutable submitted revision, session/project, and reviewer-assignment scope. | Inspection/revision aggregate; reviewer assignment and SoD; project/session/assignment/member; role/scope eligibility; claim/association/evidence dependencies; final submit writer. | PARTIAL STATIC REVIEW; exact revision event boundary, reviewer identity source, selector, scope and dedup UNRESOLVED; NOT ENABLED. |
| NREG-009 | `inspection.returned_for_correction` (CMD-030) | Candidate `ROLE_SCOPE` for the responsible assigned Inspector and/or trusted `EVENT_PARTICIPANT` only after the exact inspection/revision-to-Inspector mapping is approved. Reviewer/actor is not a substitute. | Exact inspection and returned immutable revision within its session/project/assignment scope. | Inspection/revision and terminal review-decision arbiter; reviewer/Inspector assignment; role/scope eligibility; claim/association and parent locks. | PARTIAL STATIC REVIEW; responsible Inspector mapping, decision identity, selector and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-010 | `inspection.approved` (CMD-031) | Candidate `ROLE_SCOPE` and/or trusted `EVENT_PARTICIPANT` for the responsible Inspector only after the exact source assignment is approved. Do not infer the recipient from reviewer, actor, or revision author. | Exact approved inspection revision and its session/project/assignment scope. | Inspection aggregate; exact current revision; reviewer assignment/SoD; terminal decision uniqueness; role/scope and parent dependencies. | PARTIAL STATIC REVIEW; responsible Inspector mapping, terminal-decision arbiter, selector and dispatch profile UNRESOLVED; NOT ENABLED. |
| NREG-011 | `inspection.reopened` (CMD-032) | **No selector can be admitted yet.** The next-action owner is unresolved. Do not substitute the prior Inspector, Reviewer, or reopening actor. | Exact inspection/revision/session/project scope is known conceptually; the authorized next-action assignment is not. | Inspection aggregate and mutable draft context; reopen authority/SoD; active claim/association/assignment/evidence/document blockers; role/scope and parent writers. | PARTIAL STATIC REVIEW; next-action owner, authority, draft context, selector and dispatch profile UNRESOLVED; NOT ENABLED. |

**Important:** candidate clause kinds in this table are review directions only. They do not authorize a role, a permission, a principal, a scope, or a policy publication.

## 5. Complete CMD-001–040 source-declaration disposition

This table preserves the source declaration and the existing product triage. It is not an enabled allowlist. `P` means a product discussion candidate, `O` means operational/control event with no current user-notice justification, `U` means unresolved/composite token, and `X` means excluded from ordinary matching.

| CMD | Source declaration | Triage | Registry / selector disposition | Candidate writer or dependency domains |
|---|---|---|---|---|
| CMD-001 | `account.requested` | P | Secondary candidate deferred; no PO-approved first-batch selector. Requesting-user intent is conceptual only. | Account-request identity, `app_users`/auth identity, request transaction and idempotency. |
| CMD-002 | `account.approved` | P | NREG-001; target participant mapping unresolved; NOT ENABLED. | Account state, `app_users`, auth identity, role/scope eligibility, conditional T-14 capacity. |
| CMD-003 | `account.rejected` | P | NREG-002; target participant mapping unresolved; NOT ENABLED. | Account state, `app_users`, auth identity, role/scope eligibility, conditional T-14 capacity. |
| CMD-004 | `role.assigned`; conditional `permission.changed` | U | Split exact tokens and source conditions first; no selector or event admission. | `app_users`, `user_roles`, role/permission catalog, delegation/scope grants, T-14 capacity if Inspector eligibility changes. |
| CMD-005 | `role.revoked` | P | NREG-003; POQ-04 pre-revoke/self-revoke semantics; NOT ENABLED. | `app_users`, `user_roles`, `user_scope_grants`, role catalog, delegation, T-14 capacity, expiry/repair writers. |
| CMD-006 | `scope.changed` | U | Grant direction and exact event identity unresolved; no selector. | `user_scope_grants`, scope parents, actor/target authority, T-14 where qualifying population changes. |
| CMD-007 | `scope.changed` | U | Reuses CMD-006 token for revoke direction; distinct exact identity/discriminator required; no selector. | `user_scope_grants`, scope parents, actor/target authority, expiry/reassignment/repair writers. |
| CMD-008 | `project.created` | O | No recipient implied; excluded from current notification candidates. | Project insert, actor authority, project scope and default capacity initialization. |
| CMD-009 | `project.updated` | O | Generic update; no field-level material-change policy; no selector. | Project row/version, project scope and any selector-relevant mutable fields. |
| CMD-010 | `project.closed` | P | NREG-004; POQ-04 pre-close semantics; NOT ENABLED. | Project/session parent, assignments/members, locations/teams, role/scope, child writers/finalizers, T-14 if affected. |
| CMD-011 | `session.created` | O | No future assignment recipients inferred; no selector. | Project/session parent, session insert, assignment planning. |
| CMD-012 | `session.updated` | O | Generic update without material-field policy; no selector. | Session/project parent, assignment/time dependencies and closure writers. |
| CMD-013 | `session.close_requested` action/event; final `session.closed` | U | Only exact final `session.closed` maps to NREG-005; `session.close_requested` is excluded. | Session/project parent fence, closure dependencies, active inspection/evidence/document/attendance finalizers. |
| CMD-014 | `assignment.created` | P | NREG-006; exact initial-roster participant projection unresolved; NOT ENABLED. | T-14 capacity, project/session/assignment parents, assignment members, member principals/roles/scopes. |
| CMD-015 | `assignment.changed` | P | NREG-007; added/ended/retained member outcomes must be separated; POQ-04 pre-end rule; NOT ENABLED. | T-14 capacity, assignment/member rows, app_users, roles/scopes, expiry/import/repair. |
| CMD-016 | `capacity.limit_changed` | O | Administrative capacity change; no user recipient implied. | Project capacity settings and qualifying account/role/assignment population. |
| CMD-017 | `target.created/reallocated/version_published` | U | Split exact tokens and define material recipient intent before any PO review; no selector. | Project/session, target plan, allocations, immutable published plan version. |
| CMD-018 | `instrument.created` | O | Administrative catalog event; no selector. | Instrument catalog and canonical code uniqueness. |
| CMD-019 | `instrument.version_drafted`; unspecified “config changed events” | U | Draft edits are not notice events; undefined config token remains unresolved. | Instrument/version/configuration rows, child configuration, assignment references. |
| CMD-020 | `instrument.version_published` | P | Secondary candidate only; no first-batch selector or active-Inspector broadcast. | Instrument/version publication, immutable session snapshots, assignment references, scoped administrators if later approved. |
| CMD-021 | `instrument.deactivated` | O | No recipient implied; do not infer cancellation of active work. | Instrument lifecycle, assignment references and safety-withdrawal path. |
| CMD-022 | `unit.registered` OR `identity_conflict_opened` | U | Distinct outcomes; split exact tokens and contracts; no shared selector. | Canonical unit identity key, instrument type, project/assignment context, conflict identity. |
| CMD-023 | `unit.project_associated` | O | No human notice specified; no selector. | Canonical unit, project, assignment, association uniqueness and parent ordering. |
| CMD-024 | `unit.project_association_ended/revoked` | U | Slash notation unresolved; exact transition token(s) required; no selector. | Unit, association, project, claim, inspection and child-work blockers. |
| CMD-025 | `unit.identity_conflict_resolved/rejected` | U | Split exact resolution/rejection tokens; affected principals unresolved; no selector. | Conflict record, canonical unit, project/association key, authorization and audit. |
| CMD-026 | `unit.claimed` AND `inspection.created` | U | Two domain facts, not one notice; exact event boundaries/correlation and product intent unresolved. | Canonical unit, project/session/assignment, unit/association, claim and inspection aggregates. |
| CMD-027 | `unit.claim_released` | O | Recovery/control event; no next Inspector inferred or substituted. | Unit/association/assignment/claim/inspection release path. |
| CMD-028 | `inspection.draft_saved` | O | Autosave/retry noise; excluded from ordinary notifications. | Inspection draft aggregate, active claim/association/assignment, response children. |
| CMD-029 | `inspection.submitted` AND `inspection_revision.created` | U | NREG-008 applies only to the single review-queue intent `inspection.submitted`; revision-created is not a second notice. | Inspection/revision, exact reviewer assignment, claim/association/assignment, evidence finalization and idempotency. |
| CMD-030 | `inspection.returned_for_correction` | P | NREG-009; responsible Inspector mapping unresolved; NOT ENABLED. | Inspection/revision, terminal review decision, reviewer/Inspector assignment, role/scope and claim/association. |
| CMD-031 | `inspection.approved` | P | NREG-010; responsible Inspector mapping unresolved; NOT ENABLED. | Inspection/current revision, reviewer assignment/SoD, terminal-decision uniqueness, role/scope. |
| CMD-032 | `inspection.reopened` | P | NREG-011; next-action owner unresolved; no selector can be admitted; NOT ENABLED. | Inspection/draft context, reopen authority/SoD, active work blockers, claim/association/assignment/evidence/document writers. |
| CMD-033 | `evidence.upload_intent_created` | O | Technical intermediate only; never proof of upload; no selector. | Inspection aggregate, pending evidence metadata, quota/reservation if approved; Storage authorization after commit. |
| CMD-034 | `evidence.uploaded` | O | No user notice established; private evidence remains independently authorized. | External Storage verification, evidence finalization, inspection/claim/assignment revalidation. |
| CMD-035 | `sync.batch_applied/conflicted` plus per-operation domain events | U | Batch envelope and each domain event have different boundaries; no batch-wide broadcast. Resolve transaction/savepoint and per-operation event cardinality first. | Sync operation ledger/result, device trust, each underlying command's writer dependencies and idempotency. |
| CMD-036 | `pdf.generated`, `ba.generated`, `attendance.generated` | U | Distinct document classes/finalizers; split exact tokens; generation is not print/signature/verification. | Renderer job/lease, immutable source revision/template, document finalizer, attendance authority and worker ACL. |
| CMD-037 | `document.printed`, `document.reprinted` | O | Print audit events; no notification absent a separate approved need. | Document/version, per-document print sequence and append-only print events. |
| CMD-038 | `document.print_batch_created/completed/partial` plus per-document print events | U | Separate batch envelope from each per-document outcome; no batch-wide notification by default. | Batch manifest/item identity, per-document version/sequence, worker lease and per-item finalizer. |
| CMD-039 | `attendance.uploaded/replaced` | U | Split upload/replacement tokens; no Attendance Verifier notification until authority and exact source are approved. | Attendance record/document version, private Storage verification, uploader/verifier SoD and institutional authority. |
| CMD-040 | `attendance.verified` | O | No recipient implied; Attendance Verifier authority/sign-off remains external. | Attendance record/document version, verifier identity/authority and audit. |

### 5.1 Explicit scope exclusions

- CMD-041–044 are read-side/report/audit operations and do not gain notification side effects by inference.
- CMD-045–048 are separate institutional, incident, provider, and release control-plane responsibilities; they are not application notification events.
- CMD-049–054 are notification read/fan-out/dispatch/policy/escalation operations and are excluded from ordinary event matching by default to prevent recursion. CMD-052 consumes immutable candidates and must not re-resolve; CMD-053 dispatches and does not create source-event recipients; CMD-051 is an eligibility writer; CMD-054 is a scheduler-generated source with its own separate review.
- `account.requested` (CMD-001) and `instrument.version_published` (CMD-020) remain secondary P-class candidates, neither approved nor rejected for a later decision.
- No IFP or Standing Bracket checklist item, photo slot, inspection evidence byte, or evidence-completeness transition is a notification event by inference.

## 6. POQ-04 event-transition dispatch contract

The five Product Owner-approved outcomes remain binding and must be represented by event-specific dispatch profiles. This section restates product semantics; it does not approve the technical dispatch matrix.

| Transition | Event-time snapshot | Dispatch / retry invariant | Explicit anti-suppression guard |
|---|---|---|---|
| Role revoke (CMD-005) | Evaluate exact selectors against pre-revoke role/scope state. Target is included only if selected; actor is never auto-added. | Revalidate account, channel, consent, mandatory security, and only the current-scope predicates explicitly required by the pinned profile. | Do not require the revoked role to remain effective merely to deliver its revocation notice. Notice grants no access to the revoked resource. |
| Account reject/disable/suspend (CMD-002/003 and any separately approved lifecycle event) | Evaluate against pre-transition account state; target is not implicit. | Suppress while account is disabled/suspended/expired. After reactivation, retry may reconsider only the same original candidate and must re-run all mandatory checks. | Reactivation cannot rebuild/widen the snapshot, reset checkpoint, or clear unrelated suppression reasons. |
| Assignment-member end (CMD-015) | Evaluate membership and selectors before ending membership at the one captured instant. | Revalidate current account/channel/consent/security and only the event-specific scope predicates. | Do not universally require current membership in the just-ended assignment; never substitute a replacement member. |
| Project/session close (CMD-010/013) | Evaluate against pre-close parent/scope state; snapshot commits atomically with the final closure event. | Revalidate account/channel/consent/security and only the explicit closure-event profile. | Do not apply a blanket `parent.status = ACTIVE` requirement after closure. A closure notice does not authorize access to the closed resource. |
| Self-revoke | Actor is included only if the exact event selector independently selects the actor under pre-revoke eligibility. | Revalidate current account/channel/consent/security and applicable current-scope rules. | No implicit actor inclusion or exclusion. |

**Common invariant:** suppression and attempt outcomes are append-only/auditable delivery evidence. They never mutate candidate membership. Retry uses the original candidate set, policy pin and checkpoint.

## 7. Eligibility-writer dependency crosswalk (F-04 intake)

The following are logical dependency classes derived from the current writer matrix. They are **not physical column names, an exhaustive deployed writer inventory, or approved lock recipes**.

| Dependency class | Known command writers | Non-command / implicit writers requiring inventory | Candidate L05 participation requirement | Open evidence |
|---|---|---|---|---|
| Account/login eligibility | CMD-002/003; CMD-001 request identity | Auth reconciliation, support disable/suspend/reactivate, import/repair | Before `app_users`/account eligibility and any capacity/role locks when an enabled selector depends on account state. | Exact account state fields, identity mapping, entrypoints, ownership and direct-DML denial. |
| Role grants/revocations | CMD-004/005 | Expiry, renewal, delegation, import, synchronization, repair | Before `user_roles`, delegation and authorization-catalog rows. | Exact role lifecycle, interval constraints, version token, all writers and ACL. |
| Scope grants/delegation | CMD-006/007 | Expiry, renewal, reassignment, import and repair | Before `user_scope_grants` and mutable scope parents. | Scope taxonomy, parent lifecycle, exact grant/revoke semantics and writer IDs. |
| Role/permission catalog | CMD-004/005 read catalog | Migration/admin maintenance, permission-bundle import, privileged repair | If runtime mutable, before `roles`, `permissions`, `role_permissions`; otherwise prove immutable/frozen after bootstrap. | Catalog mutability, ownership, ACL and no-bypass evidence. |
| T-14 Inspector capacity | CMD-002/003, CMD-004/005, CMD-014/015, CMD-016 | Scheduled reconciliation, administrative capacity/population repair | Candidate L05 before L10 and qualifying account/role/assignment rows, subject to approved L05/L10 order. | Complete affected-project set and one canonical shared serialization protocol. |
| Project lifecycle/scope | CMD-008/009/010 | Import/repair, triggers/cascades, administrative project mutation | Before project parent and dependent lifecycle locks if referenced by an enabled selector. | Direct DML, parent-fence, child-writer and implicit FK/trigger edges. |
| Session lifecycle/scope | CMD-011/012/013 | Administrative correction/import; any scheduled close path | Before project/session parents and dependent child locks if referenced by an enabled selector. | CMD-012/013 source order, final-close fence, reopen and child-finalizer coverage. |
| Assignment/membership | CMD-014/015 | Expiry/renewal, roster import/repair, administrative membership changes | Before L10 (if T-14 applies), project/session, assignment and membership locks. | Exact added/ended/retained member projection, writer functions and effective-time records. |
| Location/team scope | CMD-014/015 and CMD-010/012/013 interactions | Location/team create/update/deactivate/reassign, import/repair | Before any mutable location/team/scope parent actually referenced by an enabled selector. | Full CRUD command inventory and selector dependency proof. |
| Instrument/version | CMD-018–021 and CMD-014 references | Catalog import/repair and lifecycle maintenance | L05 only if approved selector grammar depends on instrument/version state. | Do not include or exclude until selector grammar is frozen; instrument is not assumed a recipient scope. |
| Unit/association/claim | CMD-022–027 | Reconciliation and administrative repair | L05 only if an approved selector depends on unit/association/claim state. | Selector dependency not established; CMD-023–027 lock conflicts remain separate blockers. |
| Inspection/revision/evidence | CMD-028–034; underlying operations in CMD-035 | Upload finalizer, sync replay, evidence repair | L05 only if an approved selector depends on these states; otherwise prove exclusion. | CMD-035 operation boundary, revision and evidence source semantics, exact selector columns. |
| Document/print/attendance | CMD-036–040 | Renderer finalizer, print worker, attendance upload finalizer/verifier | Event-producing finalizer acquires candidate L05 before lease/source/document/attendance locks; external render/Storage remains outside DB transaction. | Worker identity/ACL, immutable source version, per-item event cardinality, attendance authority. |
| Notification policy | CMD-051 | Retirement/effective-window update, admin repair/direct table mutation | Before mutable policy-version/scope locks; source resolver reads policy only after L05. | Policy administration grants/SoD, retirement writer, policy immutability and ACL. |
| Notification escalation | CMD-054 | Duplicate scheduler ticks, retry/reclaim and operational replay | Before mutable recipient/policy/escalation locks; re-read due state after lock. | Scheduler principal/ACL, dedup key, lock order and snapshot semantics. |
| Browser/API direct DML | No application CMD | Supabase REST table endpoints, alternate RPCs, service-role clients | Must be denied or routed exclusively through reviewed wrappers that acquire the approved guard. | Deployed grants/RLS and caller-JWT path not available. |
| SECURITY DEFINER/helpers | CMD-001–054 wrappers/helpers | Nested helpers, owner-role bypass, alternate entrypoints | Entry wrapper acquires guard before any helper can lock/mutate an eligibility dependency. | Exact function inventory, owner, search_path, EXECUTE ACL and call graph. |
| Triggers/FK/cascades | Any eligibility or selector-parent mutation | Row/statement/deferred triggers, FK KEY SHARE, cascades, unique-index waits | Must not acquire L05 late after a higher-ranked row lock; every implicit edge belongs in the graph. | DDL, trigger inventory, FK topology and actual lock behavior. |
| Imports/bulk/repair/expiry | No complete CMD mapping | One-off SQL, backfills, import jobs, support scripts, repair, scheduled expiry | Prohibit concurrent bypass or route through the same reviewed transaction protocol. | Exhaustive job/script inventory, owners and controls absent. |
| Database owner/emergency | No application CMD | Owner/superuser, migration role, emergency console/provider dashboard | Define maintenance window and prove no concurrent resolver observes an unguarded mutation; otherwise prohibit bypass. | Operations/provider RACI and emergency-access evidence absent. |

**Writer completeness is not established.** The existence of a command row does not prove that every deployed function, helper, trigger, cascade, import, expiry job, repair path, support tool, or privileged operator participates. A single unreviewed writer that can change a selector predicate invalidates the L05 serialization proof.

## 8. F-05 technical validation checklist

| Finding | Required closure evidence | Current status |
|---|---|---|
| F05-T1 — selector grammar and allowlist | Approve grammar version, exact event allowlist, permitted clauses, role/scope references, participant semantics, boolean/null behavior, effective-time rules, canonicalization/dedup, bounds and fail-closed behavior. Each enabled event has one complete registry row and dependency-column set. | REVIEW CANDIDATE ONLY; NOT APPROVED. |
| F05-T2 — dispatch authorization matrix | For each event, approve captured qualification checks, mandatory current account/channel/consent/security checks, event-specific current-scope and parent-state rules, and independent resource authorization. | PARTIAL CANDIDATE; NOT APPROVED. |
| F05-T3 — suppression/retry state machine | Approve stable reason codes; terminal/retryable/policy-reschedulable classification; owner; attempt ceiling/backoff/expiry; checkpoint behavior; reactivation triggers and revalidation. | OPEN; no reason-code or retry budget invented here. |
| F05-T4 — audit evidence | Approve append-only suppression/attempt evidence, correlation IDs, worker identity, policy/snapshot references, timestamps, integrity, retention, privacy and minimization. | OPEN; T-10 Records/Privacy dependencies remain. |
| F05-T5 — atomicity and snapshot binding | Prove source mutation, event, audit, idempotency, outbox, policy pin and complete immutable candidate snapshot share one approved transaction and captured instant; include all source and writer paths. | OPEN; candidate snapshot relation/header NOT ADMITTED; 0/40 resolver paths certified. |

### Required per-event registry fields before admission

- Exact canonical `event_type` and immutable policy-effective interval.
- Owning CMD/worker, exact source/finalizer transaction boundary, and event cardinality.
- Grammar version and exact permitted selector clauses.
- Trusted ACTOR/TARGET/AFFECTED_MEMBER mapping and canonical principal identity.
- Exact event-scope binding, source and cardinality.
- Every referenced role, grant, assignment/member, scope-parent, account-state and temporal dependency.
- Event-specific dispatch profile and suppression reason mapping.
- Source-event/outbox/snapshot deduplication and correlation keys.
- Required L05 and other lock participation, FK/trigger/helper edges, and atomicity evidence.
- Named Product, Engineering, Database, Security, Operations and institutional approvers where their authority applies.

## 9. QA traceability and execution boundary

The following existing test definitions are relevant to this registry and remain **PLANNED / NOT EXECUTED**:

- TC-NOTIF-055..059: POQ-04 transition outcomes.
- TC-NOTIF-060..064: selector validity, participant overlap, closure dispatch, reactivation/retry and append-only suppression/audit outcomes.
- TC-NOTIF-065..070: grammar v1, prohibited syntax, trusted participant projection, exact event token, event-specific dispatch and canonical candidate serialization.
- TC-NOTIF-077/078: role-revoke/self-revoke, role lifecycle, replay and version/lock behavior.
- TC-NOTIF-082..085: assignment/member event cardinality, T-14 capacity and L05/L10 writer participation.
- NRL-T01..T13 and related lock-graph cases: candidate lock/writer schedules; not executed.

No test may be described as passing from this registry. Runtime/concurrency execution requires G10 activation, approved contracts, exact schema/functions/grants, an authorized isolated PostgreSQL environment, and reproducible evidence tied to the tested revision.

## 10. Certification and gate disposition

| Measure | Current evidence |
|---|---|
| CMD-001–040 source declarations inventoried | 40/40 in the source-event map |
| First-batch PO-approved candidate intents | 11 for specification/review only |
| Candidate registry entries technically admitted | 0 |
| Events enabled for publication/dispatch | 0 |
| Exact selector grammar | Candidate v1 only; not approved |
| Selector dependency universe | Not frozen |
| Complete eligibility-writer inventory | Incomplete |
| Writers certified to acquire L05 | 0 |
| Resolver paths certified | 0/40 |
| Application command lock certification | 0/50 |
| Global lock graph | NOT PROVEN ACYCLIC |
| Candidate snapshot relation/header | NOT ADMITTED |
| QA | PLANNED / NOT EXECUTED |
| F-05 / F-04 / F-03 / F-07 | OPEN |
| G9 / G10 | NOT READY / NOT ACTIVE |
| Production readiness | NOT VERIFIED |

**Disposition:** the event-to-selector crosswalk is authored as a static review candidate. It does not close F-05 or F-04, approve an event, admit L05, certify a lock path, change the PRD, or authorize implementation. Any unresolved token, selector, participant, scope or writer dependency remains a blocker.

## 11. Required next review

1. Engineering and Security review the exact selector grammar and event-specific dispatch profiles for the eleven PO-approved candidates.
2. Resolve event token decomposition and trusted source projection for the composite CMD declarations before any event is considered for admission.
3. Reconcile each selector's referenced logical dependencies against the complete physical writer/function/trigger/import/expiry inventory.
4. Reconcile source and eligibility-writer L05 prefixes with T-14 L10, parent fences, FK/unique/trigger/helper edges and the global lock graph.
5. Update NREG rows, the writer matrix, command lock manifests, RTM, DGA and QA only after accountable-owner review; keep every row NOT ENABLED until all admission evidence is complete.

No SQL, migration, grant, RLS, source code, provider change, live database inspection, runtime test, deployment or production data operation is performed or authorized by this document.


## 12. F05-T1 structural grammar hardening cross-reference — 2026-11-25

NLA-L05-TDR-001 v0.1.11 §4.2.5.1 now specifies a more precise **candidate-only** structural profile for grammar v1: exact object keys and JSON types, duplicate-key rejection before lossy parsing, null/missing behavior, participant/scope cardinality failures, OR and conjunction semantics, exact identifier matching, deterministic clause ordering and duplicate-clause equality, and the distinction between PO-approved candidate-intent tokens and a runtime-publishable event allowlist.

This clarification does not fill the unresolved per-event bindings in this crosswalk. In particular:
- no canonical role key or scope ID is admitted;
- no NREG row receives an approved ROLE_SCOPE or EVENT_PARTICIPANT clause;
- no ACTOR/TARGET/AFFECTED_MEMBER source field or SOURCE_EVENT_SCOPE cardinality is approved;
- no candidate identity key, scope serialization, policy digest or physical snapshot representation is admitted;
- the eleven PO-approved tokens remain specification/review candidates only and all remain NOT ENABLED.

F05-T1 remains OPEN pending Engineering/Security review, canonical role/scope registries, exact per-event mappings and dependency columns, a machine-reviewable positive/negative validation corpus, and synchronized RTM/QA evidence and outstanding RAID cross-reference. F-04 writer certification remains 0; resolver certification 0/40; application lock certification 0/50; global graph NOT PROVEN ACYCLIC; G9 NOT READY; G10 NOT ACTIVE. No implementation, SQL, migration, grants/RLS, live DB, runtime test or deployment is authorized.


## 13. F05-T2 event-specific dispatch matrix cross-reference — 2026-11-25

NLA-L05-TDR-001 v0.1.11 §4.2.6.1 adds an eleven-row dispatch review matrix. It separates POQ-01 mandatory current account/channel/consent/security checks from transition-specific current-role/scope/parent predicates, records the five POQ-04 approved outcomes, and explicitly leaves unresolved source/recipient/profile semantics unresolved for NREG-001/006/008/009/010/011.

The matrix is a static review aid, not approved dispatch policy. All eleven NREG rows remain UNRESOLVED / NOT ENABLED. No current-role, assignment-membership or active-parent predicate may be inferred as universal; no recipient substitution or resource-access grant is permitted. Mandatory security restrictions remain fail-closed.

F05-T2 remains OPEN pending Security/Engineering approval of each versioned event profile, resolution of source/recipient gaps, aligned F05-T3/T4/T5 contracts, and TC-NOTIF-055..059/062/069 acceptance evidence after G10 activation. All QA remains PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.


## 14. F05-T5 atomic source-event and snapshot binding cross-reference — 2026-11-25

NLA-L05-TDR-001 v0.1.14 §18 defines a candidate logical atomicity contract: source mutation, canonical event, required audit evidence, idempotency outcome, outbox intent, exact policy-version pin, complete immutable candidate recipient/scope set and initial checkpoint share one approved transaction and one captured `audience_evaluated_at`. An incomplete or unresolved snapshot fails the source transaction; a successfully evaluated empty audience is not equivalent to missing/partial evidence.

This crosswalk does not identify an admitted producer, physical relation/header, candidate key, digest, uniqueness constraint, lock rank or writer certification. Each of the eleven candidate event rows still needs an exact source-command/finalizer, transaction boundary, participant/scope/dependency mapping, policy pin and event-specific approval. Composite/conditional command declarations remain unresolved and no event is enabled.

F05-T5 remains OPEN pending Engineering producer inventory, Database physical/atomicity approval, Security provenance and fail-closed review, complete eligibility-writer serialization proof and deterministic isolated-database evidence. TC-NOTIF-100..105 remain PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.
