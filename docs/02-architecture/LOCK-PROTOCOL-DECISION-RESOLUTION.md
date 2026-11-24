# Lock Protocol Decision Resolution — LPR-01–LPR-11

**Document ID:** LOCK-PROTOCOL-DECISION-RESOLUTION-001  
**Version:** 0.3.11  
**Status:** PO product decisions LPR-02–LPR-06 APPROVED; technical lock protocol remains OPEN / NOT approved for implementation  
**Date:** 2026-11-24  
**Scope:** Candidate global lock protocol for CMD-001–054 and asynchronous finalizers  
**Parent:** LOCK-GRAPH-001; LOCK-MANIFEST-001  
**Gate:** G3/G4/G5/G7/G9 NOT READY; G10 NOT ACTIVE

## 1. Executive recommendation

The source-level lock recipes are not safe to implement as currently written. They contain incompatible acquisition orders, incomplete resource sets and unverified implicit database lock paths. This document proposes one deterministic protocol for decision and security review; it does not declare the protocol approved, prove the graph acyclic, or authorize implementation.

**Recommendation:** adopt a single monotonic resource order, require every command to publish a complete per-command lock manifest, and prohibit any transaction from acquiring a lower-ranked resource after a higher-ranked one. Where a command cannot obey that order, redesign its transaction boundary rather than adding an undocumented exception.

No canonical command catalogue, physical schema, migration, function, grant, RLS policy or detailed command review is changed by this proposal.

## 2. Evidence boundary and authority

This proposal is based on static review of AGENTS.md v1.2.0, MIB-001, DGA-001, IRG-001, the Decision Register, PostgreSQL Command Contract Catalogue, Physical Database Schema and Integrity Specification, CONCURRENCY-001, LOCK-GRAPH-001, LOCK-MANIFEST-001 and detailed reviews for CMD-011–054.

No live PostgreSQL/Supabase catalog, trigger/function call graph, deployed ACL, lock trace, transaction execution or concurrency test was inspected or run. All resource ranks and protocols below are logical design proposals; exact lock primitives, SQL and physical targets remain subject to approved schema and database review.

Authority precedence remains unchanged: PO decisions govern product behavior; institutional authorities govern reserved legal/records/privacy/security/operations matters; Engineering and Security approve technical lock and privilege design within their authority. A PO decision cannot substitute for security or institutional approval.

## 3. Candidate canonical resource order — technical approval required

Use the following total order. A command acquires only the classes it needs, in ascending order. The rank is a logical ordering contract, not a prescription to lock every listed row.

| Rank | Resource class | Examples / purpose | Required rule |
|---:|---|---|---|
| L00 | Idempotency arbitration | actor + command + scope + key | Claim or resolve the idempotency identity before domain locks; same-key/different-hash rejects |
| L10 | Shared invariant serialization | T-14 capacity control row | Every operation that can change the qualifying Inspector population or capacity uses the same serialization point first |
| L15 | Principal/account aggregate | `app_users` | Stable user UUID order; account eligibility and target-principal state |
| L16 | User-role grant aggregate | `user_roles` | Stable (user_id, role_id, grant_id) order; role validity and Inspector eligibility |
| L17 | User-scope grant aggregate | `user_scope_grants` | Stable (user_id, scope_type, scope_id, grant_id) order |
| L18 | Mutable authorization catalog (conditional) | `roles`, `permissions`, `role_permissions` | Freeze during normal operations or approve a separate rank/change protocol; do not assume immutable without evidence |
| L20 | Canonical identity arbitration | normalized serial/instrument identity and conflict key | All unit identity writers derive the same canonical key and acquire it before project/unit rows |
| L30 | Project/session lifecycle parents | project, session | Parent lifecycle fence precedes child creation, mutation and finalization; multiple parents sorted by stable ID |
| L40 | Instrument and immutable version references | instrument, instrument_version | Validate active/selectable status and pin immutable version; do not mutate historical versions |
| L50 | Assignment and operational grouping | operational assignment, team, location | Deterministic UUID order; assignment eligibility revalidated after parent and instrument checks |
| L55 | Assignment membership | assignment_members | Stable (assignment_id, user_id, membership_id) order |
| L60 | Canonical unit | unit identity/lifecycle row | Acquire after identity arbitration and scoped parents |
| L70 | Association episode | unit-project association | One active episode invariant; exact association is revalidated after lock |
| L80 | Claim aggregate | unit claim | Claim lifecycle before inspection lifecycle; unique active claim is final database arbitration |
| L90 | Inspection aggregate | inspection | Inspection state/version and current revision are revalidated after lock |
| L100 | Dependent mutable aggregates | evidence upload intent, attendance record, document job, print batch, notification policy/inbox/delivery state | Exact per-command sub-order and source-version binding required; no external I/O while held |
| L110 | Append-only facts | revisions, review decisions, domain events, audit events, delivery attempts, notification escalation/access events | Insert after mutable aggregate validation; uniqueness constraints remain final arbitration |

### 3.1 Deterministic same-rank ordering

- Lock multiple rows within a rank by a stable, immutable key in ascending order (UUID byte ordering or another explicitly documented canonical comparator).
- A command must declare the comparator; incidental query-plan order is not acceptable.
- A foreign-key, unique-index, trigger or helper-function lock is part of the effective lock set even when it is not visible in the command's top-level SQL.
- A command may not perform a late lookup that introduces a lower-ranked lock after a higher-ranked lock.
- Revalidation of actor, permission, scope, status, expiry, revision, version and capacity must occur after the serialization rows governing those facts have been acquired.

### 3.2 Idempotency and replay

The L00 arbitration must be short and transactionally safe. The same semantic request hash returns the durable outcome only after the required current authorization checks. A different hash under the same idempotency identity rejects. Deadlock/serialization retries must reuse the same key and may not duplicate domain events, audit events or external effects.

## 4. Conflict resolutions recommended

### 4.1 CMD-022–027: canonical identity, association, conflict, claim

**Recommended order:** L00 → L10 when T-14 eligibility is affected → L20 canonical identity → L30 project/session → L40 instrument/version → L50 assignment/membership → L60 unit → L70 association → L80 claim → L90 inspection → L100 dependent mutable aggregates where applicable → L110 append-only facts.

- CMD-022 registration, CMD-023 association, CMD-024 end/revoke, CMD-025 conflict resolution, CMD-026 claim and CMD-027 release must use the same canonical identity derivation and lock order.
- CMD-023/024/026 must not retain unit-first or association-first recipes that contradict this order.
- CMD-025 conflict-first behavior may select a candidate but must not lock a conflict row before L20 if the operation subsequently needs canonical identity arbitration. Resolve the candidate identity, acquire L20, then lock scoped resources in order and revalidate conflict state.
- CMD-026 catalogue row and detailed review must be reconciled to the same order. No separate special order for claim creation.
- CMD-027 release uses the same L20–L80 chain when it must prove identity/association context; if it only mutates an already identified claim, the manifest may justify a narrower L00 → L30 → L50 → L60 → L70 → L80 path, but it must not acquire omitted lower ranks later.
- Unique constraints for one active unit identity/association/claim remain necessary. Locks alone are not the integrity guarantee.

**PO disposition (LPR-02): APPROVED.** Canonical identity is `(instrument_type, serial_normalized)` and is global across projects, consistent with T-16. Cross-project duplicates are controlled conflicts requiring authorized review, reason and audit; no silent merge/overwrite. The exact normalization algorithm, arbitration primitive, uniqueness constraints and exception policy remain subject to Engineering/Security and institutional review.

### 4.2 CMD-028–032 and CMD-035: claim/inspection/revision/review/sync

**Recommended order:** L00 → L30 → L50 → L60 → L70 → L80 claim → L90 inspection → L100 evidence/document child (only where applicable) → L110 revision/review/event/audit.

- Claim precedes inspection because inspection ownership and eligibility depend on a valid active claim/association.
- CMD-028 save draft, CMD-029 submit, CMD-030 return, CMD-031 approve, CMD-032 reopen and CMD-035 sync must share the same parent/claim/inspection order.
- Revisions and review decisions are append-only facts at L110; they do not become a reason to lock a revision before its inspection aggregate.
- Exact expected_row_version, expected_revision_no and sync operation identity remain distinct tokens. Each command validates all relevant tokens after acquiring its aggregate locks.
- CMD-035 must not lock an inspection through a different path than online commands; sync conflict records require their own documented child rank and idempotency identity.

**PO disposition (LPR-03): APPROVED.** A valid active claim is mandatory before every normal inspection workflow. Any administrative correction/migration exception must use a separately permissioned, reasoned and audited path. Engineering/Security must define exact command, permission, audit and legacy-data treatment.

### 4.3 CMD-009–016: project/session parent fence and T-14 capacity

- Project/session state rows are the lifecycle fence. Every child writer/finalizer must lock and revalidate the applicable parent before touching child aggregates.
- Closing a project/session must serialize against creation, assignment, claim, inspection, evidence finalization, attendance verification and any asynchronous job that can advance scoped work.
- Preflight reads are advisory only; they cannot replace the parent lock and in-transaction revalidation.
- T-14 capacity uses L10 before any user/role/membership row that contributes to the qualifying count. Every eligibility-changing path must participate: role grant/revoke/expiry, account disable/suspension, assignment membership activation/deactivation, and capacity changes.
- A path that does not affect the T-14 qualifying population need not acquire L10, but that exclusion must be proven in its manifest.

**PO disposition (LPR-04): APPROVED.** A closed project/session rejects new normal mutations and finalization; reopening requires an explicit privileged workflow, reason and audit. This aligns with T-06/T-07. Engineering/Security must define the complete parent-fence and in-flight finalizer graph.

**PO disposition (LPR-05): APPROVED as a clarification of existing T-14, not a replacement.** The controlling predicate counts distinct login-enabled accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment in governed project/session scope. Registration alone and pending/rejected/suspended/disabled or expired-role accounts do not count. Assignment/team-membership and capacity-changing paths must use one shared serialization point when they can change that population. The existing combined 1–100 cap/default 50 remains controlling. Engineering/Security must verify every eligibility-changing path and exact effective-time semantics.

### 4.4 CMD-014/018–021: instrument/version/assignment interaction

- Assignment publication follows L30 parent → L40 instrument/version → L50 assignment/membership. It pins an immutable instrument version.
- Instrument publish/deactivation locks the L40 instrument row and revalidates current status/version. It must not, after holding L40, acquire L30 parent locks or L50 assignment locks in a reverse order.
- To prevent a concurrent assignment from selecting an instrument being deactivated, both paths contend on the same L40 instrument row: assignment publication locks/revalidates it before publishing; deactivation changes status/version under L40. A waiting assignment must re-read and reject an inactive instrument.
- If deactivation needs to enumerate or mutate assignments, redesign as a separate bounded workflow/outbox that follows L30 → L40 → L50; do not perform instrument-first then assignment mutation.
- Historical session/assignment references remain pinned to immutable instrument versions; deactivation must not rewrite historical snapshots.

**PO disposition (LPR-06): APPROVED.** Deactivation blocks new assignment selection; sessions already pinned to an immutable version retain that historical version by default. A safety withdrawal may explicitly override continued use through a separately authorized, reasoned and audited workflow. The safety authority, affected-session handling and technical enforcement remain open; Engineering/Security must validate the concurrency and integrity mechanism.

### 4.5 CMD-033–040: evidence, documents, attendance and print

- Create durable upload/render/print intent under the applicable L30–L90 parent/aggregate locks; commit before Storage, malware scan, image processing, PDF rendering or printing.
- External I/O MUST NOT occur while a database row lock is held.
- Finalization starts a new short transaction, reacquires the full applicable parent and source aggregate chain in canonical order, validates the original source revision/version and job fencing token, then appends the result.
- Attendance verification must bind to one immutable attendance document version. Institutional attendance authority remains blocked by DGA-B03.
- Print sequence allocation must have one per-document serialization point. Do not use max(sequence)+1 without a serialization/unique constraint design.
- Rendering completion is not physical print evidence; print events remain separate.

### 4.6 CMD-049–054: notification workers and provider callbacks

- Queue/outbox/delivery claims are short, independent transactions. A worker must not hold a queue-row lock while acquiring domain aggregate locks.
- Worker lease ownership uses a monotonically increasing fencing generation/token plus expiry; it is not a user row_version.
- External provider calls happen after the claim transaction commits. Persist attempt identity and outcome in separate short transactions.
- A callback/webhook must enter through a separately authenticated provider boundary, validate provider authenticity/replay protection, and be idempotent on provider + event/attempt identity. It must not be treated as a browser command or ordinary user JWT.
- If finalization changes a source aggregate, reacquire the entire relevant domain lock chain in ascending order and verify the fencing token before commit.
- Scheduler ticks use a unique policy-version + escalation-step + target-window identity so duplicate ticks cannot create duplicate escalation events.
- Worker principal, role, function owner, EXECUTE ACL, secret custody, provider capabilities and T-10 data policy remain separate approvals.

- Command mapping for review (not implementation approval):
  - CMD-049 is a recipient-scoped read; use MVCC/read consistency and a stable actor-bound cursor, not a mutation lock.
  - CMD-050 mutates only the recipient-owned notification read projection at L100; append an L110 audit fact only if the approved audit policy requires it. Do not modify delivery state.
  - CMD-051 serializes the policy draft/version and effective-scope publication at L100, then appends the L110 audit fact. Draft identity, canonical hash, same-scope ordering and interval exclusion remain open.
  - CMD-052 claims one bounded outbox item in a short isolated queue transaction; commit the lease/fencing generation before fan-out. Recipient inbox and delivery projections are L100 writes, with unique constraints as final duplicate arbitration. Never hold the queue-row lock while acquiring domain aggregates or performing provider I/O.
  - CMD-053 claims/updates the exact delivery projection at L100 and appends immutable attempt outcomes at L110. Provider I/O occurs outside transactions. Provider callback ingestion is a separately authenticated boundary; its logical command mapping remains unresolved.
  - CMD-054 evaluates due state against server UTC and the pinned policy version; it writes notification/outbox projections at L100 and one unique escalation fact at L110. Duplicate scheduler ticks must converge on the same policy-version/step/window identity.
- These mappings reconcile logical resource classes only. Queue claim tables, notification physical keys, indexes, triggers, function calls, worker principals and ACLs are not verified; no rank or implementation mechanism is approved by this paragraph.

## 5. Per-command manifest closure requirements

A command is not lock-complete until its manifest records:

1. Exact command ID and contract version.
2. Ordered ranks and exact table/row/key predicates.
3. Same-rank deterministic comparator.
4. Shared invariants and every competing command/worker.
5. Revalidation predicates performed after each relevant lock.
6. Unique/check/FK/exclusion constraints, triggers and helper-function call graph.
7. Isolation level, lock timeout, statement timeout and retryable SQLSTATE behavior.
8. Idempotency identity/hash and atomic event/audit outcome.
9. External intent, lease, fencing, finalization and reconciliation boundaries.
10. Adversarial command-pair test IDs and evidence on the exact schema/commit.

The inventory currently covers 54/54 command IDs but certifies 0/54 complete manifests. This proposal does not change that count.

## 6. Required decisions and accountability

| ID | Decision | Decision owner | Status |
|---|---|---|---|
| LPR-01 | Endorse/reject the candidate rank hierarchy as the basis for technical review | PO for product-impacting policy; Engineering + Security for technical approval | OPEN |
| LPR-02 | Define canonical unit identity and conflict-resolution semantics | PO + domain owner; Engineering + Security for enforcement | PO APPROVED — technical enforcement OPEN |
| LPR-03 | Confirm mandatory claim requirement and documented exceptions | PO | PO APPROVED — exception implementation review OPEN |
| LPR-04 | Define project/session closure and treatment of in-flight work | PO + institutional operations owner where policy requires | PO APPROVED — lifecycle/authority enforcement OPEN |
| LPR-05 | Confirm T-14 eligibility counting rule and effective-time semantics | PO + institutional operations owner; Security/Engineering implement | PO APPROVED — preserve T-14 predicate; technical path audit OPEN |
| LPR-06 | Define instrument deactivation effect on already-pinned sessions | PO + instrument owner | PO APPROVED — safety withdrawal authority/enforcement OPEN |
| LPR-07 | Approve exact lock primitives, function/trigger graph and effective privileges | Engineering + Security | OPEN |
| LPR-08 | Approve worker identity, queue fencing, provider callback trust and ACL | Security + Operations + provider owner | OPEN |
| LPR-09 | Normalize/review all 50 in-scope application command manifests and physical constraints/call graph; retain CMD-045–048 as external traceability only | Engineering + Database/Security + QA | OPEN |
| LPR-10 | Run adversarial concurrency suite in authorized isolated environment | Engineering + QA + Security | NOT EXECUTED |
| LPR-11 | Define and approve lock classes/order for account identity and authorization aggregates (`app_users`, `user_roles`, `user_scope_grants`) relative to T-14 capacity, project/session parents and assignment membership | Engineering + Security; PO for product-impacting lifecycle; institution where authority applies | OPEN |

The user/PO is not asked to approve SQL, lock primitives, function owners, grants or RLS. Those are Engineering/Security decisions and require their own evidence and review.

## 7. Explicit blockers that this proposal does not close

- T-10 institutional data classification, legal basis, retention, deletion/disposition, legal hold, audit access/export and metadata.
- T-12 actual provider/legal account ownership, billing owner, region, quota, budget and recovery entitlements.
- DGA-B01/B02 authoritative instrument sources and completeness.
- DGA-B03 BA signatory and attendance authority.
- DGA-B06 backup/restore evidence; DGA-B07 device/offline security; DGA-B08 numeric SLOs.
- DGA-B09 permission registry and grantor/SoD approval.
- DGA-B10 exact executable contracts for CMD-001–054.
- DGA-B11 live schema/RLS/constraints verification; DGA-B12 T-18 function owner/ACL/JWT evidence.
- DGA-B13 notification worker/provider/T-10 approvals; DGA-B14 reporting/closure semantics; DGA-B15 CI/branch protection evidence.
- DGA-B16 onward including version-token and lock graph/manifest closure (see DGA-001 current register).

These require named authorities and source/runtime evidence; no document-only proposal can substitute for them.

## 8. Verification plan — PLANNED / NOT EXECUTED

Before any implementation, Engineering/QA/Security must:
- Build the complete effective lock graph including row locks, unique-index arbitration, foreign-key checks, triggers, helper functions and worker paths.
- Prove the proposed rank graph has no reverse edge or cycle for all commands.
- Run each conflicting command pair in both start orders with deterministic barriers.
- Capture final invariant state, SQLSTATE, lock wait/deadlock diagnostics and retry behavior.
- Verify parent closure against every child writer/finalizer.
- Verify T-14 count/capacity under concurrent eligibility changes.
- Verify stale worker fencing after lease expiry/reclaim.
- Verify audit/idempotency atomic rollback and no duplicate event after retry.
- Tie all results to exact schema migration head, code commit, test run and isolated environment.

No test, CI, SQL, migration, live database query, grant, deployment or runtime inspection was performed for this document.

## 9. Gate disposition

| Gate | Status | Reason |
|---|---|---|
| G3 data/transaction | NOT READY | Candidate ordering requires approval and physical lock graph/constraints are unverified |
| G4 security | NOT READY | Worker and function identities/ACLs and effective privilege paths remain unverified |
| G5 API/command | NOT READY | 54 manifests remain incomplete/unapproved |
| G7 quality/evidence | NOT READY | Concurrency tests planned only |
| G9 SSOT/scope freeze | NOT READY | Product, institutional and technical blockers remain |
| G10 implementation | NOT AUTHORIZED | Separate written implementation authorization is absent |

**Final disposition:** PO product semantics LPR-02–LPR-06 are approved and recorded in the Decision Register. LPR-01 (candidate rank hierarchy) and LPR-07–LPR-11 remain open for technical review, manifest reconciliation and authorized concurrency evidence. This does not approve the canonical lock protocol, close DGA-B18/B19/B20/B21, certify deadlock freedom or authorize implementation.


## 10. Decision update — 2026-11-24

Document version 0.2.0 records the Product Owner approvals for LPR-02 through LPR-06. T-14's existing approved eligibility predicate and 1–100 combined capacity remain controlling; LPR-05 is a clarification and does not supersede them. LPR-01 and LPR-07–LPR-11 remain open. All physical lock mechanisms, exact constraints, trigger/function paths, effective privileges and adversarial concurrency evidence remain unapproved or unverified. No tests, CI, SQL, migration, live database query, grants or deployment were performed.


## 11. Static reconciliation checkpoint — 2026-11-24

This checkpoint records contradictions and incomplete paths that are visible from the current documentation set. It is a review ledger, not a technical decision and not a substitute for the LPR approvals in §6.

| Area / commands | Static documentation finding | Required closure before certification | Current status |
|---|---|---|---|
| Parent/session fence — CMD-011–015 vs CMD-009/010 | CMD-011 proposes project FOR KEY SHARE; CMD-012/013 lock session before resolving/locking project; CMD-014 lists project/session/assignment refs after T-14 capacity; CMD-015 locks assignment/members/users without an explicit project/session parent fence. PostgreSQL FOR KEY SHARE does not conflict with FOR NO KEY UPDATE, which is normally acquired by a non-key UPDATE; a plain project status update is therefore not proven to fence CMD-011. | Engineering/Security must approve one project/session order, explicit compatible/conflicting lock modes, all closure blockers and every child/worker finalizer path; redesign session-first paths and reconcile CMD-010–015 manifests. | OPEN |
| Canonical unit lifecycle — CMD-022–027 | Source recipes disagree on relative order among canonical identity, project, unit, association, assignment, conflict and claim resources. The command catalogue and lock manifest do not express one identical CMD-026 sequence. | Approve one canonical identity arbitration primitive and one total resource order; reconcile CMD-022–027 catalogue, detailed reviews, manifest, constraints and conflict workflow. | OPEN |
| Inspection aggregate — CMD-028–032 | Aggregate-first source recipes are not yet reconciled with parent, claim, association and assignment fencing. Claim expiry/takeover and inspection finalization must not authorize stale work. | Approve one shared order and exact CAS/revision semantics for save, submit, return, approve and reopen; prove all terminal decisions and claim transitions are serialized. | OPEN |
| Offline synchronization — CMD-035 | The source permits either short per-operation transactions or savepoints, but the atomicity and failure model is not selected. | Decide batch envelope semantics, operation commit boundaries, deterministic multi-inspection ordering, replay behavior and partial-result durability. | OPEN |
| Evidence/document finalizers — CMD-033/034/036 | External Storage/rendering must occur outside DB locks, but the physical intent, immutable source binding, lease generation, worker identity and finalization fence are not verified. | Approve intent/object identity, checksum/metadata verification, source-version revalidation, worker principal/ACL, lease fencing, compensation and orphan reconciliation. | OPEN |
| Print sequencing — CMD-037/038 | Per-document sequence allocation is proposed, but the physical allocator, durable batch item identity, retry boundary and partial recovery contract remain incomplete. | Approve sequence serialization/uniqueness, batch item manifest, idempotency identity, lease/recovery behavior and event cardinality. | OPEN |
| Attendance — CMD-039/040 | Upload/replacement and verification are separate, but immutable document version binding, aggregate version token, institutional authority and uploader/verifier separation are not closed. | Obtain institutional verification/SoD authority and approve the physical version, replacement, verify fence and audit contract. | BLOCKED_BY_INSTITUTIONAL_AUTHORITY |
| Notification workers/callbacks — CMD-049–054 | Outbox, fan-out, dispatch and escalation paths are described, but worker identities, lease fencing, callback trust, provider idempotency and effective ACLs are not verified. | Security/Operations/provider owner must approve worker principals, exact privileges, lease-generation fencing, callback authentication and ambiguous provider-outcome reconciliation. | OPEN |
| Implicit database edges — CMD-001–054 | Documentation does not establish actual FK checks, unique-index arbitration, triggers, helper-function calls, row-lock modes or effective privilege/RLS behavior. | Inspect the authorized target schema and deployed function/trigger/ACL inventory; produce a complete effective lock/call graph tied to the exact schema head. | NOT VERIFIED |
| Adversarial evidence — CMD-001–054 and workers | LG-01–LG-41 are planned scenarios only. No deterministic concurrency execution or deadlock diagnostics are recorded. | Run the approved suite in an authorized isolated environment; retain fixtures, barriers, isolation level, SQLSTATE/lock diagnostics and invariant snapshots. | NOT EXECUTED |

### 11.1 Reconciliation rules

1. Do not resolve a contradiction by silently preferring the candidate rank table; it remains subject to LPR-01 and technical approval.
2. Do not infer physical lock behavior from logical labels such as L20/L30/L50 or from a proposed unique constraint.
3. A unique index, foreign-key check, trigger, helper function or worker can add an effective lock edge; each must be represented after physical inspection.
4. A command is not lock-complete merely because its logical operation appears in the 54-row inventory.
5. Keep institutional blockers distinct from technical blockers. Engineering cannot approve attendance authority, retention/legal hold or provider ownership on behalf of the institution.
6. Update the canonical command catalogue, detailed review, lock manifest, global graph, QA plan and DGA register together only after the relevant authority has approved the decision.
7. No row in this checkpoint is certified complete; all tests remain PLANNED / NOT EXECUTED unless a separate reproducible evidence record is attached.
8. Do not infer that a project parent fence is effective from the phrase FOR KEY SHARE. Verify the row-lock conflict matrix against the deployed PostgreSQL major version; FOR KEY SHARE is compatible with FOR NO KEY UPDATE, so an ordinary non-key status UPDATE alone may not serialize a child writer.

### 11.2 Identity and authorization aggregate rank gap — CMD-001–007

A row-by-row review of CMD-001–007 found mutable or authorization-bearing resources that are not represented by a named class in the current L00–L110 candidate hierarchy:

- `app_users`: own-account request state and target-account approval/rejection state (CMD-001–003); target-account eligibility in role/scope grants (CMD-004/006).
- `user_roles`: grant/revoke lifecycle and Inspector eligibility (CMD-004/005).
- `user_scope_grants`: scope grant/revoke lifecycle (CMD-006/007).

These resources must not be silently mapped to L50 assignment/membership, L30 project/session, or L110 append-only facts. L110 applies only to append-only decision/audit facts, not mutable account or grant state. A candidate class assignment is now proposed in §3 and TECH-RESOLUTION-LPR-001 §3.1: app_users at L15, user_roles at L16 and user_scope_grants at L17; mutable roles/permissions/role_permissions require L18 or a frozen-catalogue control. Engineering/Security approval of these ranks and the actor/target grant lock strategy remains OPEN.

The candidate protocol must obtain explicit approval for:
1. Whether account, role-grant and scope-grant rows form one rank or separate ordered ranks, including stable same-rank table/key ordering.
2. How CMD-004/005 Inspector eligibility mutations acquire the L10 capacity serialization row before any row whose change can alter the T-14 qualifying population.
3. How account approval/disable/suspension and role/scope revocation serialize with permission revalidation and any active-work policy.
4. How grantor authorization rows, target principal rows and project/session/location/team/assignment scope rows are ordered without creating reverse edges.
5. Whether commands need to lock actor authorization rows or use a separately approved authorization-epoch/snapshot contract to prevent revocation races.

Until LPR-11 is resolved, CMD-001–007 cannot receive normalized candidate-rank sequences. Their row-level overlays in LOCK-MANIFEST-001 are resource inventories only, not approved acquisition orders.

## 12. Change history

- **0.2.2 — 2026-11-24:** Aligned the L100/L110 resource examples with mutable notification policy/inbox/delivery state and append-only notification escalation/access facts; added per-command logical mappings for CMD-049–054 and explicitly retained queue isolation, callback-boundary and worker-security gaps. No technical lock decision was approved and no implementation authority changed.
- **0.2.3 — 2026-11-24:** Corrected the recommended-order summary to include L100 dependent mutable aggregates between L90 inspection and L110 append-only facts, matching the rank table. Candidate order remains unapproved.
- **0.3.0 — 2026-11-24:** Added LPR-11 to resolve the previously unclassified `app_users`, `user_roles` and `user_scope_grants` lock classes and their ordering against T-14 capacity and project/session parent fences. Added an explicit static gap analysis for CMD-001–007. No rank or technical protocol was approved.
- **0.3.1 — 2026-11-24:** Reordered §11.2 beneath the §11.1 reconciliation rules for correct document hierarchy and clarified the unresolved identity/authorization rank gap. No decision status changed.
- **0.3.2 — 2026-11-24:** Added the CMD-011–015 project/session parent-fence cross-check, including PostgreSQL row-lock compatibility implications for CMD-011 versus CMD-010. Parent-fence design remains OPEN; no lock mode was approved.


## 13. Engineering/Security technical resolution package — 2026-11-24

[TECH-RESOLUTION-LPR-001](ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) v0.1.0 provides a concrete review proposal for LPR-01 and LPR-07–LPR-11. It proposes L15/L16/L17 identity and authorization ranks (with L18 policy-catalogue treatment), a project-before-session parent fence using child FOR SHARE and parent mutation FOR NO KEY UPDATE, T-14 capacity-first participation, worker lease fencing/callback boundaries, a normalized 54-row manifest schema and an adversarial test plan. All technical items remain OPEN; LPR-10 remains NOT EXECUTED. This addendum does not approve any lock primitive, rank, function, trigger, ACL, worker principal, migration or test result. It also records the required T-07 correction: session states remain DRAFT/ACTIVE/PAUSED/CLOSED and CLOSE_REQUESTED is an action/event only.


## 14. Refined identity/authorization rank proposal — 2026-11-24

The main candidate rank table now includes L15–L18 and separates assignment rows at L50 from assignment membership at L55, matching TECH-RESOLUTION-LPR-001 v0.1.0. This is a candidate hierarchy for Engineering/Security review, not an approved global lock order. LPR-01 and LPR-11 remain OPEN until the accountable reviewers record explicit approval or amendment.


## 14. CMD-001–010 candidate manifest normalization — 2026-11-24

**Reference baseline:** CMD-001–010 Detailed Contract Review v0.3.4 §9; LOCK-MANIFEST-001 v0.4.12; LOCK-GRAPH-001 v0.4.10. This is a technical proposal for review, not approval of LPR-01, LPR-07 or LPR-11.

### 14.1 Proposed command order

| Command | Candidate order | Main concurrency contract |
|---|---|---|
| CMD-001 | L00 → L15 own account row / unique Auth identity insert arbiter | One request lifecycle per Auth identity; no assumed row lock for absent identity |
| CMD-002/003 | L00 → conditional L10 → L15 sorted actor/target → L16/L17 actor authority → L18 catalog → L110 decision | One target-account terminal transition; approve/reject race serialized on same target row |
| CMD-004/005 | L00 → conditional L10 → L15 sorted principals → L16 role grants → L17 delegation grants → L18 catalog → L110 audit | Grant/revoke and all Inspector eligibility writers share L10 and exact L16 grant identity |
| CMD-006/007 | L00 → conditional L10 → L15 → L16 if role authority → L17 → L18 → L30/L50 scope target → L110 audit | Grant/revoke and duplicate interval operations share the exact L17 grant key and approved parent mapping |
| CMD-008 | L00 → L15/L16/L17/L18 actor authority → L30 unique project-code insert; capacity row bootstrapped atomically | Project and default capacity settings commit or roll back together |
| CMD-009 | L00 → L15/L16/L17/L18 actor authority → L30 project FOR NO KEY UPDATE candidate + CAS | Metadata update serializes with close and project child writers |
| CMD-010 | L00 → conditional L10 → L15/L16/L17/L18 actor authority → L30 project FOR NO KEY UPDATE candidate → blocker evaluation | Close is fenced against every project child writer/finalizer using project FOR SHARE |

### 14.2 T-14 and authorization lock prerequisites

- The T-14 affected project set must be discovered before L15, L10 rows locked by ascending project UUID, and the set revalidated after lock. The qualifying-count read must use a fresh post-L10 READ COMMITTED statement snapshot or SERIALIZABLE with retry. If the set expands, abort/retry; no late lower-rank lock acquisition.
- Whether CMD-002/003 account-state transitions, CMD-006/007 role-bearing scope grants, or CMD-010 project closure alter the qualifying predicate is not yet approved. Each must either use L10 or document a predicate proof that it cannot affect the count.
- Actor and target principals are locked by sorted UUID. Actor role/scope grants used to authorize the mutation are locked at L16/L17 so a concurrent revoke cannot silently race the authorization decision.
- Mutable authorization catalog rows must be frozen for normal writes or governed under an approved L18 protocol.
- A project/session scope grant must lock the scope's lifecycle parent after L17 and before its L50 operational target; exact type-to-table mapping and inheritance remain open.

### 14.3 Project closure fence

CMD-010 takes the project `FOR NO KEY UPDATE` candidate fence before evaluating closure blockers. Every project-scoped child command and asynchronous finalizer must take project `FOR SHARE` before any child aggregate and revalidate project state after waiting. The fence makes preflight reads advisory only. A missing fence in any writer path invalidates the closure safety claim. No cascade, implicit session close or history deletion is introduced. Pending durable intents and external in-flight work require explicit blocker/reconciliation policy.

### 14.4 Remaining technical decisions

| Decision | Current proposal | Approval / evidence still required |
|---|---|---|
| LPR-01 / LPR-11 | L15 app_users, L16 user_roles, L17 user_scope_grants, conditional L18 authorization catalog | Engineering + Security approve rank and actor/target/grantor lock coverage |
| LPR-07 | L00/L10/L15–L18/L30 parent-first order | Database/Engineering inspect FK, unique-index, trigger, helper-function and actual PostgreSQL lock edges |
| T-14 affected project set | L10 rows sorted before identity rows | Engineering/PO confirm account/project/session/role/scope predicate and complete writer set |
| Project fence | Child FOR SHARE; project mutation/close FOR NO KEY UPDATE | Engineering/Database/Security validate lock matrix and every CMD-011–054 child/finalizer |
| CAS tokens | Existing request expected_version fields retained as unresolved contract inputs | Physical schema must define row_version/increment semantics or contracts must remove the token; no token is invented here |
| Project capacity bootstrap | Create default capacity row atomically with new project | Database approve physical key, default, unique constraint and FK/trigger path |
| Closure blocker graph | Evaluate after project fence | PO/institution define blocker classes, Operations define pending-work policy, Engineering maps physical predicates |

CMD-001–010 are candidate-normalized at documentation level only. LPR-01 and LPR-07–LPR-11 remain OPEN; LPR-10 NOT EXECUTED; 0/54 commands are certified lock-complete.


## Conditional Product Owner authorization status synchronization — 2026-11-24

The Product Owner's explicit conditional implementation authorization is recorded in the canonical Decision Register. It permits transition toward implementation from zero using the SSOT baseline, subject to G9 closure and a separate G10 activation record. **Current status: G9 NOT READY; G10 NOT ACTIVE.** This status synchronization does not approve this technical proposal, any lock mode, permission, function ACL, migration or runtime behavior. Technical and institutional approval boundaries stated in this document remain unchanged.


## 13. LPR-09 application-scope denominator clarification — 2026-11-24

LPR-09 applies to **50 application commands**, not all 54 traceability IDs. CMD-045–048 are approved external control-plane dispositions and must not be assigned application lock sets. The 54/54 inventory count remains valid only as traceability coverage. The current manifest records candidate transaction/resource boundaries for the 50 application commands, but complete normalized-field coverage, physical lock-target evidence and accountable technical approvals are not yet established. Therefore LPR-09 remains OPEN and application lock certification remains **0/50**. LPR-10 remains NOT EXECUTED. No lock mode, privilege, schema, function, worker ACL or runtime behavior is approved by this clarification. LOCK-MANIFEST-001 v0.4.23 and LOCK-GRAPH-001 v0.4.16 are the current linked baselines.


## 14. Normalized manifest register reference — 2026-11-24

[LOCK-NORMALIZATION-001](COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md) v0.1.0 is the consolidated field-level review index for the 50 application commands. It does not resolve or approve LPR-01 or LPR-07–LPR-09/LPR-11; LPR-10 remains NOT EXECUTED. CMD-045–048 remain external control-plane IDs and are excluded. The register's OPEN items must be resolved against exact physical schema and effective PostgreSQL behavior before any lock protocol approval.
