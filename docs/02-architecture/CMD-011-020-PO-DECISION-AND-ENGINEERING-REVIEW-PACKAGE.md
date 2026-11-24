# CMD-011–020 Product Decision and Engineering Review Package

**Document ID:** CMD-011-020-DECISION-PACKAGE-001  
**Version:** 0.2.1  
**Status:** PO PRODUCT DECISIONS APPROVED; ENGINEERING / SECURITY REVIEW OPEN  
**Date:** 2026-11-24  
**Branch:** `docs/audit-lock-and-identity-reconciliation`  
**Parent references:** AGENTS.md v1.2.0; DGA-001; MIB-001; IRG-001; DECISION-REGISTER; LOCK-PROTOCOL-DECISION-RESOLUTION-001; LOCK-GRAPH-001; LOCK-MANIFEST-001; CMD-011–020 Detailed Contract Review v0.2.0  
**Gate:** G9 NOT READY; G10 NOT AUTHORIZED

---

## 1. Purpose and decision boundary

This package records the Product Owner's explicit approval (2026-11-24) of the recommended product semantics for CMD-011–020, with compatibility resolutions against existing T-07, T-14 and T-17 decisions. It remains a controlled documentation artifact; technical and institutional approvals are separate.

It does not:
- record an approval on behalf of the Product Owner, Engineering, Security, Database, QA or institution;
- amend the canonical command catalogue, physical schema, ERD, permission registry, RLS catalogue or lock manifest;
- approve PostgreSQL lock primitives, constraints, triggers, functions, owners, grants, RLS or effective privileges;
- authorize SQL, migrations, source code, CI execution, live database inspection, deployment or merge.

Authority remains as stated in root AGENTS.md. PO decisions may settle product behavior within PO authority. Technical lock/security/database decisions require Engineering and Security approval. Institutional records, legal, privacy, attendance and operational authority remain with their authorized institutional owners.

### 1.1 Evidence boundary

The current review is static documentation analysis. No source code, SQL, migration, CI workflow, automated test, concurrency test, live database catalog, deployed ACL/RLS inspection or deployment was executed. All technical mechanisms below are recommendations to review, not proven behavior.

## 2. Recommended Product Owner decisions — CMD-011–020

The following product semantics and business invariants were explicitly approved by the Product Owner on 2026-11-24 and recorded in the Decision Register. Compatibility resolutions below preserve higher-authority existing decisions. Downstream normative documents still require controlled reconciliation and technical review.

| ID | Decision requested | Recommended PO disposition | Rationale / impact | Required PO response |
|---|---|---|---|---|
| PO-CMD011-01 | Initial session state | Approve server-selected initial state **PLANNED**; only a later explicit CMD-013 transition may activate it. | Prevents client-controlled lifecycle and aligns create vs transition responsibilities. Confirm the state exists in the authoritative lifecycle enum before adopting. | APPROVED — 2026-11-24 |
| PO-CMD011-02 | Project eligibility for session creation | Permit creation only while parent project is in an explicitly approved planning/open state; reject CLOSED, archived, suspended or otherwise terminal project states. | Child creation must not reopen or bypass parent closure. Exact project enum names must be copied from the approved state machine, not invented in implementation. | APPROVED — 2026-11-24 |
| PO-CMD011-03 | Session timezone semantics | Treat session start/end as UTC instants; interpret user-entered local times using the project's canonical IANA timezone. Do not add a session timezone override unless a documented product need is approved. | Avoids dual timezone authority and inconsistent reporting. Ambiguous/nonexistent local DST times must be rejected with an actionable validation error. | APPROVED — 2026-11-24 |
| PO-CMD011-04 | Session overlap | Do not prohibit overlapping sessions by default. Enforce only project-scoped unique session code and valid interval unless operations supplies a concrete scheduling invariant. | Prevents inventing a business restriction unsupported by the current PRD. | APPROVED — 2026-11-24 |
| PO-CMD012-01 | Session code mutability | Make session code immutable after creation; allow only approved schedule/description metadata fields to change. | Avoids identity drift across assignments, reports, audit and external references. Any correction should use a separately audited administrative correction path. | APPROVED — 2026-11-24 |
| PO-CMD012-02 | Session metadata changes after work begins | Once any assignment, claim, inspection, attendance or report references the session, reject date/time changes that would invalidate or reinterpret existing work. Allow non-semantic metadata changes only. | Preserves historical meaning and avoids silent movement of work. | APPROVED — 2026-11-24 |
| PO-CMD012-03 | Change reason | Require a non-empty reason for every accepted session metadata update. | Supports accountable changes without storing unnecessary personal data. | APPROVED — 2026-11-24 |
| PO-CMD013-01 | Session lifecycle | Approve a finite state machine with PLANNED → ACTIVE → PAUSED → ACTIVE → CLOSE_REQUESTED → CLOSED, subject to explicit allowed edges; CLOSED is terminal in normal operation. | Prevents arbitrary target states and clarifies pause/resume/close semantics. The exact enum and edge matrix must be reconciled with existing workflow documents before approval is made normative. | APPROVED — 2026-11-24 |
| PO-CMD013-02 | Korlap transition authority | Do not grant broad transition authority. Korlap may execute only individually enumerated transitions for assigned project/session scope; default recommendation is no close/final-close authority. | Enforces least privilege and separates operational control from final closure. | APPROVED — 2026-11-24 |
| PO-CMD013-03 | Close request vs final close | Treat close request and final close as distinct states/actions. Final close requires an approved closure checklist and explicit authorized role; no implicit auto-close. | Makes blockers visible and prevents a premature terminal state. | APPROVED — 2026-11-24 |
| PO-CMD013-04 | Reopen | CLOSED remains terminal for normal commands. Any exceptional reopening requires a separate privileged command, reason, audit and institutional approval where required. | Consistent with LPR-04; no hidden transition flag on CMD-013. | RECONFIRMED — 2026-11-24 |
| PO-CMD014-01 | Assignment publication | Treat CMD-014 as create-only; one command creates one new assignment and its complete initial roster atomically. | Prevents ambiguous create/upsert behavior and partial roster publication. | APPROVED — 2026-11-24 |
| PO-CMD014-02 | Assignment initial state | Server assigns the approved initial published state only after all project/session/instrument/member validations pass. No client-supplied status. | Keeps publication semantics atomic and server-authoritative. Exact enum must be reconciled with the canonical lifecycle catalogue. | APPROVED — 2026-11-24 |
| PO-CMD014-03 | Assignment interval boundaries | Use half-open intervals [start, end): start inclusive, end exclusive; null end means open-ended. | Avoids double-counting at adjacent boundaries. Confirm this does not conflict with existing attendance/assignment policy. | APPROVED — 2026-11-24 |
| PO-CMD014-04 | Membership overlap | Reject overlapping effective membership for the same user where it creates duplicate or conflicting Inspector eligibility in the same governed project/session; do not infer cross-project exclusivity without a policy. | Preserves T-14 distinct-account counting while avoiding unsupported global staffing restrictions. | APPROVED — 2026-11-24 |
| PO-CMD015-01 | Membership end timestamp | Approve per-membership effective_at for each end operation; reject one ambiguous command-level timestamp when multiple members are ended at different times. | Makes batch change semantics deterministic and auditable. | APPROVED — 2026-11-24 |
| PO-CMD015-02 | Active work on member removal | Do not delete, reassign or invalidate already-submitted inspections. Block immediate removal only where it would orphan an active claim/in-progress workflow; permit future-effective end where policy allows. Exact grandfathering/transfer authority needs operational approval. | Protects submitted evidence and prevents stale work ownership. | APPROVED — 2026-11-24 |
| PO-CMD015-03 | Reason and history | Require a reason; end membership rows rather than hard-delete; retain history under approved retention policy. | Supports audit and staffing traceability. Retention duration remains institutional, not a PO assumption. | APPROVED — 2026-11-24 |
| PO-CMD016-01 | Capacity semantics | Reaffirm T-14: integer cap 1–100, default 50; count distinct login-enabled accounts with active Inspector role and at least one currently effective operational Inspector assignment in governed project/session scope. | This is already PO-approved; this package does not reopen or change it. | EXISTING DECISION — RECONFIRMED |
| PO-CMD016-02 | Capacity reduction | Reject any cap reduction below the current qualifying distinct-account count. Never silently revoke roles or remove assignments to force compliance. | Preserves transparent staffing state and avoids destructive side effects. | EXISTING DECISION — RECONFIRMED |
| PO-CMD017-01 | Target-plan scope | Prefer session-scoped plans. Require session_id and ensure the session belongs to project_id; allow project-wide plans only if a separate product requirement and explicit scope mode are approved. | Removes ambiguity in plan applicability and report selection. | APPROVED — 2026-11-24 |
| PO-CMD017-02 | Target plan actions | Approve strict action union CREATE_DRAFT, REPLACE_DRAFT_ALLOCATIONS, PUBLISH; one action per command. Published plans immutable; corrections create a new version. | Makes mutation semantics explicit and prevents client-selected arbitrary status. | APPROVED — 2026-11-24 |
| PO-CMD017-03 | Allocation uniqueness | One allocation per (target_plan_id, assignment_id, target_date); duplicates rejected, not silently summed. | Deterministic aggregate and idempotency semantics. | APPROVED — 2026-11-24 |
| PO-CMD017-04 | Zero allocation | Permit zero only if it means an explicit zero target; otherwise reject and omit the row. Recommended: reject zero and require positive integer quantity. | Avoids semantically empty allocations. | APPROVED — 2026-11-24 |
| PO-CMD018-01 | New instrument initial state | Create instrument in INACTIVE/DRAFT-equivalent non-selectable state until a first version is published; it must not be assignable at creation. | Separates catalog creation from version publication. Confirm exact existing enum before approval. | APPROVED — 2026-11-24 |
| PO-CMD018-02 | Instrument code normalization | Use Unicode NFKC, trim surrounding whitespace, uppercase invariant ASCII code alphabet, reject internal whitespace/control characters, and enforce unique normalized code. | Produces stable global identity. Engineering must validate Unicode/locale edge cases and database collation/constraint implementation. | APPROVED — 2026-11-24 |
| PO-CMD019-01 | Draft editing | Saving a draft replaces the complete declarative configuration atomically; omitted children are removed from the draft only, and published snapshots are never changed. | Avoids ambiguous partial merge behavior. Stable child IDs are preserved only when deterministic code matching is approved. | APPROVED — 2026-11-24 |
| PO-CMD019-02 | Schema safety | Only versioned, allowlisted declarative JSON schema primitives are permitted; no executable expressions, dynamic code, arbitrary regex execution or unbounded recursion. | Security boundary for configurable instruments. Exact schema and validation allowlist require Security/Engineering approval. | CONFIRM / AMEND |
| PO-CMD019-03 | Change summary | Require a meaningful change_summary for each draft save; do not store raw sensitive content in audit metadata. | Supports version governance and review traceability. | APPROVED — 2026-11-24 |
| PO-CMD020-01 | Publication authority | Reaffirm T-17: authorized Super Admin with explicit instrument.publish may publish without a second approver. instrument.manage alone is insufficient. | Already PO-approved; no second-person gate is to be invented. | EXISTING DECISION — RECONFIRMED |
| PO-CMD020-02 | Publication immutability | Published version and all child configuration are immutable; correction requires a new draft/version. Assignment/session binding remains pinned; no automatic rebind. | Protects reproducibility and historical inspection evidence. | CONFIRM / AMEND |
| PO-CMD020-03 | Re-publish behavior | Same idempotency key returns original result; different key against already-published version returns ALREADY_PUBLISHED/IMMUTABLE and emits no second publication event. | Avoids duplicate publication facts. | APPROVED — 2026-11-24 |

### 2.1 Approval interpretation and compatibility resolutions

The Product Owner approved the recommended product decisions as a group. The following compatibility resolutions are binding interpretations of that approval: (1) CMD-011 initial state is the existing T-07 `DRAFT`, not a new `PLANNED` state; (2) CMD-013 preserves T-07 states `DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`; `CLOSE_REQUESTED` is an action/event, not a persisted state; (3) Super Admin remains final session-closure authority consistent with T-06/T-07; (4) T-14 and T-17 are reaffirmed only and are not reopened. Exact enum values and technical enforcement must be reconciled against canonical documents before implementation.

## 3. Engineering and Security decision requests — LPR-01, LPR-07–LPR-11

The following are not PO decisions. The Product Owner must not be asked to approve SQL lock modes, PostgreSQL privileges, function owners or database internals.

| ID | Technical decision required | Recommended review direction | Required approvers/evidence |
|---|---|---|---|
| LPR-01 | Whether candidate L00–L110 hierarchy is acceptable as a logical ordering basis | Accept only as a review hypothesis after adding identity/authorization classes and resolving parent-fence compatibility. A logical rank table alone is not proof of an acyclic effective graph. | Engineering + Security; complete graph and documented exceptions |
| LPR-07 | Exact lock primitives, constraints and function/trigger call graph | Define exact tables, predicates, lock modes, isolation level, FK/unique-index/trigger/helper edges and function execution context for each command. Explicitly resolve project/session close fence. | Database Engineering + Security; catalog inventory and lock conflict analysis |
| LPR-08 | Worker identity, queue fencing, provider callback trust and ACL | Dedicated non-login least-privileged worker principal per trust boundary; monotonic lease generation/fencing token; no queue lock during provider I/O; authenticated callback signature/replay verification; exact ACL. | Security + Operations + provider owner; threat model and negative tests |
| LPR-09 | Reconcile 54 manifests and physical constraints/call graph | Normalize each manifest only after LPR-01/LPR-07/LPR-11; include every implicit edge and competing command/worker. | Engineering + Database + Security + QA; 54 row review records |
| LPR-10 | Adversarial concurrency suite | Execute only after an authorized isolated schema/environment exists; deterministic barriers, both start orders, final invariant snapshots, SQLSTATE/deadlock diagnostics and retry assertions. | Engineering + QA + Security; reproducible run evidence |
| LPR-11 | Account/authorization aggregate classes | Introduce explicit ordered logical classes for account identity/state, role grants and scope grants; define same-rank comparator and their relation to L10 capacity and L30 parents. | Engineering + Security; PO/institution only for product lifecycle authority |

### 3.1 Recommended logical resource classes for LPR-11 review

Candidate refinement for discussion (not approved ranks):

1. **Account principal state:** `app_users` — approval, enabled/suspended state and account lifecycle.
2. **Role grant state:** `user_roles` — role activation, revocation, expiry and grantor authority.
3. **Scope grant state:** `user_scope_grants` — project/session/location/team scope lifecycle.

Engineering/Security should decide whether these are three separate ordered ranks or one compound authorization rank with a deterministic table/key comparator. Do not collapse mutable authorization rows into append-only audit rank L110.

Required design properties:
- CMD-004/005 paths that change Inspector eligibility must acquire the approved T-14 capacity serialization point before modifying eligibility-bearing role/account/membership state.
- Account disable/suspension and role/scope revocation must have defined freshness/fencing semantics against in-flight commands and active work.
- Actor authorization revalidation must not introduce a lower-ranked lock after higher-ranked project/session or assignment locks.
- Grantor authority, target principal, project/session/location/team scope and assignment membership must have one globally consistent acquisition order.
- Every competing command and asynchronous worker must be included in the effective graph.

No concrete rank number is assigned here because LPR-01 remains open.

## 4. CMD-011–020 recommended parent-fence review

The current detailed contract review contains a documented contradiction:

- CMD-011 proposes project `FOR KEY SHARE`.
- CMD-012 and CMD-013 acquire session before resolving/locking project.
- CMD-014 lists project/session/reference locks after the T-14 capacity lock.
- CMD-015 lacks an explicit complete project/session parent fence.
- PostgreSQL `FOR KEY SHARE` is compatible with `FOR NO KEY UPDATE`; an ordinary non-key parent status UPDATE is therefore not proven to serialize with the proposed child fence.

### 4.1 Recommended protocol shape for Engineering/Security review

Subject to LPR-01 and exact PostgreSQL conflict analysis:

1. Resolve immutable parent identifiers using a non-authoritative/preflight read only.
2. Claim idempotency according to the approved L00 design.
3. If the operation changes T-14 eligibility, acquire the shared capacity serialization point at the approved rank before eligibility-bearing rows.
4. Acquire project and session lifecycle fences in one globally agreed order, sorted by stable IDs where multiple rows exist.
5. Use lock modes that demonstrably conflict with the parent closure mutation and with all relevant competing child writers; do not prescribe `FOR KEY SHARE` as a closure fence without proof.
6. Revalidate parent state, actor authority, project/session relationship and closure conditions after the fences are held.
7. Acquire instrument/version, assignment/member and child aggregates only in the approved ascending order.
8. Append domain/audit/idempotency facts atomically.
9. Any close/finalizer command must use the same parent fence and enumerate all child writers and asynchronous finalizers.
10. External I/O remains outside DB transactions; finalizers reacquire the complete ordered chain and validate a fencing generation/source version.

This is a review sequence, not an approved lock recipe. Engineering/Security must resolve its relationship to L00/L10/L20/L30 and all other command paths before updating canonical manifests.

### 4.2 Command-specific expected design outcomes

| Command | Expected design outcome before lock certification |
|---|---|
| CMD-011 create-session | Parent project closure fence; project state revalidated; server-selected initial state; unique project/code arbitration; exact time semantics |
| CMD-012 update-session | Project/session fence in canonical order; explicit row_version token; metadata allowlist; dependent-work validation |
| CMD-013 transition-session | Same parent/session fence; approved finite state graph; explicit role-edge matrix; closure checklist/finalization serialization |
| CMD-014 publish-assignment | T-14 capacity fence when qualifying population may change; project/session/instrument references; all roster writes atomic; exact overlap constraints |
| CMD-015 change-assignment-members | Same T-14 fence for Inspector eligibility; assignment/member/user rows in approved order; active-work removal policy; append-only history |
| CMD-016 change-inspector-capacity | Same T-14 serialization point; approved row_version; one-row initialization/uniqueness; canonical count predicate |
| CMD-017 manage-target-plan | Explicit project/session scope; target-plan aggregate/version fence; deterministic allocation uniqueness; immutable publication |
| CMD-018 create-instrument | Global normalized code uniqueness; server-selected non-selectable initial state; no version publication side effect |
| CMD-019 save-instrument-draft | Instrument then version/children in approved order; complete schema validation; deterministic canonical hash; draft concurrency token |
| CMD-020 publish-instrument-version | Instrument/version fence; server-recomputed hash; immutable child snapshot; publication/audit atomicity; exact ACL |

## 5. Required synchronized artifacts after decisions

No canonical document is changed merely because this package recommends a direction. Once the correct authority records decisions, the document owner must update the complete impact set in one controlled reconciliation:

- Decision Register and dated decision addendum.
- CMD-011–020 Detailed Contract Review.
- PostgreSQL Command Contract Catalogue.
- Physical Database Schema and Integrity Specification.
- ERD / data model and constraints crosswalk.
- LOCK-PROTOCOL-DECISION-RESOLUTION-001.
- GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.
- COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.
- Concurrency and Version Token Reconciliation.
- Canonical Permission Registry / Command Authorization Matrix where impacted.
- QA catalogue and traceability matrix.
- DGA-001 and RAID register.

Each changed document must receive its own SemVer increment under IRG-001 §6.2. Approval status remains separate from document version.

## 6. Lock-complete certification contract

A command may be marked **DOCUMENTATION-LOCK-COMPLETE** only when all are present and reviewed:

1. Approved contract version and exact request/response allowlists.
2. Approved physical read/write set, including every table and predicate.
3. Exact ordered lock classes, physical lock targets/modes and deterministic same-rank comparator.
4. Every shared invariant and competing command/worker.
5. Revalidation rules after the controlling locks.
6. FK, unique, check, exclusion, trigger, helper-function and implicit database lock edges.
7. Isolation level, lock/statement timeouts and retryable SQLSTATE behavior.
8. Idempotency identity/hash/retention and atomic audit/event outcomes.
9. External intent, lease, fencing, finalization and reconciliation boundaries.
10. Permission, actor, scope, SoD and revocation freshness contract.
11. Adversarial test IDs and explicit evidence references tied to the exact schema/commit.
12. Independent Engineering and Security review recorded.

Documentation lock completeness does not mean runtime correctness. A separate **RUNTIME-LOCK-VERIFIED** status requires authorized tests against the exact schema and code commit, including adversarial concurrency evidence.

Current baseline remains **0/54 certified**. This package does not change that count.

## 7. Required closure sequence

| Step | Work | Exit evidence | Status |
|---:|---|---|---|
| 1 | PO responds to proposed CMD-011–020 product decisions | Dated Decision Register entries with rationale | **COMPLETE — PO APPROVED 2026-11-24** |
| 2 | Engineering/Security resolve LPR-01, LPR-07–LPR-09 and LPR-11 | Signed technical decision record and approved logical/physical lock model | PENDING |
| 3 | Reconcile CMD-011–020 contract/schema/manifest/graph | Cross-document consistency review | PENDING |
| 4 | Resolve remaining commands and worker paths CMD-001–054 | 54 individually reviewed manifests | PENDING |
| 5 | Independent static graph review | Acyclic effective graph including implicit edges | PENDING |
| 6 | QA/Security execute authorized concurrency suite | Reproducible evidence and diagnostics | NOT AUTHORIZED / NOT EXECUTED |
| 7 | Reconcile DGA-001 and evaluate G9 | All G9 criteria evidenced and accepted | NOT READY |
| 8 | Separate written G10 authorization | Explicit authorization record | NOT AUTHORIZED |

No step may be marked complete solely because a document exists or a checklist is filled.

## 8. Decision response register

Record each response in the Decision Register; this table is a working response sheet only.

| Decision group | Items | Response | Approver | Date / evidence |
|---|---|---|---|---|
| Session creation | PO-CMD011-01..04 | **PO APPROVED (DRAFT state compatibility)** | Product Owner | 2026-11-24; Decision Register addendum |
| Session update | PO-CMD012-01..03 | **PO APPROVED** | Product Owner | 2026-11-24; Decision Register addendum |
| Session transition/closure | PO-CMD013-01..04 | **PO APPROVED (T-07 state compatibility)** | Product Owner | 2026-11-24; Decision Register addendum |
| Assignment publication | PO-CMD014-01..04 | **PO APPROVED** | Product Owner | 2026-11-24; Decision Register addendum |
| Membership changes | PO-CMD015-01..03 | **PO APPROVED (operational exception review remains)** | Product Owner | 2026-11-24; Decision Register addendum |
| Inspector capacity | PO-CMD016-01..02 | EXISTING T-14 DECISION — REAFFIRMED | Decision Register | T-14; not reopened |
| Target plans | PO-CMD017-01..04 | **PO APPROVED** | Product Owner | 2026-11-24; Decision Register addendum |
| Instrument creation | PO-CMD018-01..02 | **PO APPROVED (technical normalization review remains)** | Product Owner | 2026-11-24; Decision Register addendum |
| Instrument draft | PO-CMD019-01..03 | **PO APPROVED (schema safety review remains)** | Product Owner | 2026-11-24; Decision Register addendum |
| Instrument publication | PO-CMD020-01..03 | **EXISTING T-17 DECISION — REAFFIRMED** | Decision Register | T-17; not reopened |
| Logical lock hierarchy | LPR-01 | OPEN | Engineering + Security; PO only for product implications | — |
| Physical lock/security design | LPR-07 | OPEN | Engineering + Security | — |
| Worker/callback trust | LPR-08 | OPEN | Security + Operations + provider owner | — |
| Manifest reconciliation | LPR-09 | OPEN | Engineering + Database + Security + QA | — |
| Concurrency evidence | LPR-10 | NOT EXECUTED | Engineering + QA + Security | — |
| Identity/authorization ranks | LPR-11 | OPEN | Engineering + Security; PO/institution for lifecycle policy | — |

## 9. Current gate and work report

- Documentation package: updated to v0.2.0; Product Owner decision responses recorded and verified in Decision Register.
- CMD-011–020: product-semantic decisions PO APPROVED; detailed contracts still require cross-document reconciliation and Engineering/Security/QA review.
- LPR-01 and LPR-07–LPR-11: open or not executed as above.
- Lock-complete certification: 0/54.
- DGA-B18: PARTIAL.
- DGA-B19: OPEN.
- DGA-B21: OPEN.
- G9: NOT READY.
- G10: NOT AUTHORIZED.
- Source code / SQL / migrations / CI / automated tests / concurrency tests / live database inspection / deployment: NOT EXECUTED.

**Next authorized action:** reconcile approved product semantics across canonical command/state/schema/permission/QA documents, while routing LPR-01 and LPR-07–LPR-11 to Engineering/Security/Database/QA/Operations. Obtain institutional approvals where required, then re-run static consistency review. Do not start implementation.
