# Engineering & Security Technical Resolution Package — LPR-01 and LPR-07–LPR-11

**Document ID:** TECH-RESOLUTION-LPR-001  
**Version:** 0.1.8  
**Status:** TECHNICAL RECOMMENDATION FOR ENGINEERING / DATABASE / SECURITY REVIEW — NOT APPROVED FOR IMPLEMENTATION  
**Date:** 2026-11-24  
**Repository / branch:** `itswork-app/dit-sd-inspection` / `docs/audit-lock-and-identity-reconciliation`  
**Authority:** AGENTS.md v1.2.2; MIB-001 v1.0.11; IRG-001 v1.0.4; DGA-001 v1.11.43; SSOT-AUDIT-001 v0.1.5; Decision Register; T-07, T-14, T-16, T-17, T-18; LOCK-PROTOCOL-DECISION-RESOLUTION-001; LOCK-GRAPH-001; LOCK-MANIFEST-001  
**Scope:** LPR-01, LPR-07, LPR-08, LPR-09, LPR-10, LPR-11; cross-command project/session fences; CMD-001–054 and asynchronous finalizers  
**Gate:** G3/G4/G5/G7/G9 NOT READY; G10 NOT ACTIVE

---

## 1. Executive disposition

This package converts the existing lock and concurrency findings into a concrete, reviewable Engineering/Database/Security decision set. It is a **recommendation**, not a technical approval. No authority's approval is inferred from the Product Owner's “continue” instruction.

The current candidate L00–L110 hierarchy is incomplete because it omits mutable identity and authorization aggregates. It also does not resolve parent lock compatibility, complete lock modes, function/trigger/FK/index side effects, worker identities, or all 54 command manifests. The source recipes therefore cannot yet be represented as one proven acyclic graph.

### 1.1 Recommended resolution

1. Adopt the refined candidate resource order in §3 as the basis for technical review, subject to explicit Engineering and Security sign-off.
2. Use a compatible parent-fence protocol: child writers take `FOR SHARE` on project/session parents; parent state changes and closure take `FOR NO KEY UPDATE`; always acquire project before session. This is a logical recommendation requiring validation against the deployed PostgreSQL major version and every actual write path.
3. Place T-14 capacity serialization before all account, role, scope, and assignment-membership changes that can alter the qualifying Inspector population.
4. Add explicit resource classes for `app_users`, `user_roles`, and `user_scope_grants`; do not hide them inside assignment locks.
5. Treat worker claim, provider I/O and finalization as separate transactions with lease fencing; never hold database row locks over external I/O.
6. Normalize the 50 in-scope application command manifests against one schema. Keep CMD-045–048 as four external control-plane traceability IDs with no application lock set; do not include them in the application lock-certification denominator. An inventory row is not lock-complete until all fields and implicit lock edges are evidenced.
7. Keep LPR-10 NOT EXECUTED until an authorized isolated PostgreSQL environment, exact schema/commit, and reproducible adversarial test evidence exist.

### 1.2 Approval boundary

| Item | Authority | Current disposition |
|---|---|---|
| Product semantics LPR-02–LPR-06 | Product Owner | APPROVED; unchanged |
| Candidate rank hierarchy LPR-01 | Engineering + Security; PO only for product-impacting policy | PROPOSED; OPEN |
| Exact lock primitives and effective lock graph LPR-07 | Engineering + Database + Security | PROPOSED; OPEN |
| Worker identity, queue fencing, callback trust and ACL LPR-08 | Security + Operations + provider owner | PROPOSED; OPEN |
| 50-application-command manifest normalization LPR-09 | Engineering + Database/Security + QA | SPECIFICATION; OPEN |
| Adversarial concurrency suite LPR-10 | Engineering + QA + Security | NOT EXECUTED |
| Identity/authorization ranks LPR-11 | Engineering + Security; institutional owner where relevant | PROPOSED; OPEN |

No permission grant, function owner, EXECUTE ACL, RLS policy, migration, DDL, trigger, worker principal, provider secret, or implementation action is approved by this package.

---

## 2. Governing invariants and scope

The recommendations preserve the following existing product decisions and controls:

- **T-07:** session states are exactly `DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`; `CLOSED` is terminal in ordinary flow. Korlap may activate/pause/resume/request closure only within assigned scope and granted permission. Super Admin is final closure authority after gates; exceptional reopen is separately privileged, reasoned and audited.
- **T-14:** combined Inspector capacity is 1–100, default 50; count distinct login-enabled accounts with active Inspector role and at least one currently effective operational Inspector assignment in governed project/session scope. Reject a reduction below the current qualifying count; never silently revoke eligibility.
- **T-16:** canonical unit identity is `(instrument_type, serial_normalized)`, global across projects.
- **T-17:** published instrument versions are immutable; assignments/sessions remain pinned; publication requires the explicit `instrument.publish` authority.
- **T-18:** narrow SECURITY DEFINER functions for protected writes are the approved architecture direction; each concrete function still requires individual owner, effective privilege, fixed search_path, caller-JWT path, RLS and exact EXECUTE ACL review.
- No external Storage, scanner, PDF, print, email, push or provider call occurs while a database row lock is held.
- Critical mutation, required event/audit and idempotency outcome remain atomic.

**Correction required:** older rows in the CMD decision package still describe `PLANNED` and `CLOSE_REQUESTED` as persisted session states. Those descriptions conflict with T-07 and the reconciled CMD-011–020 catalogue. The controlling state set is T-07; `CLOSE_REQUESTED` is an action/event only. The older proposed chain must not be used as an enum or implementation contract.

---

## 3. Refined candidate global resource order — LPR-01

The following is the recommended total order for Engineering/Security review. Ranks are logical lock classes, not a requirement to lock every row. A command must acquire only the classes it needs, in ascending order, and must disclose all implicit edges.

| Rank | Resource class | Representative resources | Candidate ordering rule |
|---:|---|---|---|
| L00 | Idempotency arbitration | actor + command + scope + key | Claim/resolve before domain locks; same key + different semantic hash rejects |
| L10 | Shared invariant serialization | `project_capacity_settings` for T-14 | First domain lock for every path that can change the qualifying Inspector population or capacity |
| L15 | Principal/account aggregate | `app_users` | Stable user UUID order; account eligibility and target-principal state |
| L16 | User-role grant aggregate | `user_roles` | Stable (user_id, role_id, grant_id) order; role validity and Inspector eligibility |
| L17 | User-scope grant aggregate | `user_scope_grants` | Stable (user_id, scope_type, scope_id, permission/grant_id) order |
| L18 | Mutable authorization catalog (conditional) | `roles`, `permissions`, `role_permissions` | Must be immutable/frozen during normal operations or assigned a separately approved rank and change protocol; do not assume these rows are static without evidence |
| L20 | Canonical identity arbitration | `(instrument_type, serial_normalized)` | One deterministic arbitration mechanism shared by all canonical unit writers |
| L30 | Project/session lifecycle parents | `projects`, `sessions` | Project before session; multiple same-class parents by stable UUID order |
| L40 | Instrument and immutable version references | `instruments`, `instrument_versions` | Instrument before version; validate active/selectable status and pin immutable version |
| L50 | Assignment and operational grouping | `operational_assignments`, `teams`, `locations` | Parent IDs and same-rank rows in stable UUID order |
| L55 | Assignment membership | `assignment_members` | Stable (assignment_id, user_id, membership_id) order |
| L60 | Canonical unit | `units` | After identity arbitration and scoped parent/resource validation |
| L70 | Association episode | `unit_project_associations` | Exact active association revalidated after lock |
| L80 | Claim aggregate | `unit_claims` | Claim before inspection; unique active claim remains final arbitration |
| L90 | Inspection aggregate | `inspections` | Revalidate state, row_version, claim and current revision after lock |
| L100 | Dependent mutable aggregates | evidence intents, attendance, document jobs, print batches, notification policy/inbox/delivery | Per-command sub-order and source-version binding required; no external I/O while held |
| L110 | Append-only facts | revisions, review decisions, domain/audit events, attempts, escalation/access events | Insert after mutable-state validation; uniqueness remains final arbitration |

### 3.1 LPR-11 identity/authorization ordering

Recommended ordering is `L10 → L15 → L16 → L17 → L20 → L30 → L40 → L50 → L55` when all those resources are applicable.

- A change to account state that can change T-14 eligibility acquires L10 first, then the target `app_users` row, then any affected `user_roles` rows.
- Inspector role grant/revoke acquires L10 first, then target principal row(s), then exact role-grant row(s).
- Scope-grant changes acquire the affected principal and exact scope-grant rows in deterministic order. Acquire L10 as well if the scope mutation changes the T-14 qualifying predicate; otherwise the manifest must prove why it does not.
- Assignment publication or membership changes that can change Inspector eligibility acquire L10, then all affected principal/role/scope rows in stable order, then project/session parents, instrument/version, assignment and membership rows.
- Permission checks that must remain stable through the mutation must lock or otherwise serialize the exact grant rows being relied upon. A preflight authorization read is not sufficient if a concurrent revoke can invalidate the decision before commit.
- `role_permissions` and permission catalog mutation must be frozen under a separately governed administrative path or receive a formally approved rank. Do not classify mutable authorization policy as an append-only event.

### 3.2 T-14 capacity serialization rule

All operations capable of changing the qualifying count must acquire the same project capacity row before touching the rows that contribute to the predicate. The candidate list includes:

- Inspector role grant, revoke, expiry, suspension or validity-window change;
- account enable/disable/suspend/reject/approval transitions where login eligibility changes;
- assignment membership add/end/activation/effective-time change;
- project/session state changes if the approved interpretation of “currently effective operational assignment” makes that state part of eligibility;
- capacity change itself.

The final bullet concerning project/session closure requires explicit predicate confirmation by Engineering/PO and, where operational policy is reserved, the institution. If closure removes an account from the qualifying population, CMD-010/CMD-013 must acquire L10 before L15–L17 and L30. If it does not, the exact predicate must explain why.

The capacity row should exist exactly once for every project before any eligibility mutation. Recommended initialization is atomic creation with the project (or an approved deterministic backfill before any writer is enabled). A missing row must fail closed; do not silently treat “missing” as unlimited capacity. The exact upsert/unique arbitration and migration/backfill procedure require Database approval.

### 3.3 Same-rank ordering and lock upgrades

- Sort every multi-row acquisition by the declared immutable comparator; do not rely on query-plan row order.
- Determine the strongest required lock mode for each row before acquiring it. Do not take a weak lock and later upgrade it after acquiring a higher-ranked resource.
- A command may not acquire a lower rank through a helper, trigger, FK check or late authorization lookup after a higher rank has been acquired.
- A transaction that cannot follow the order must split into durable intent + guarded finalization or be redesigned; no undocumented rank exception.

---

## 4. Project/session parent-fence recommendation

### 4.1 Candidate compatible lock modes

Use one consistent parent protocol:

| Operation | Project parent | Session parent | Purpose |
|---|---|---|---|
| Child create/mutate/finalize | `FOR SHARE` | `FOR SHARE` where session-scoped | Multiple child writers may proceed concurrently; conflicts with parent state mutation |
| Project metadata/state update or project close | `FOR NO KEY UPDATE` | Then affected sessions `FOR NO KEY UPDATE` in UUID order if the command changes/checks them | Serializes project-level state changes against child writers |
| Session metadata/state transition or final close | `FOR SHARE` | `FOR NO KEY UPDATE` | Parent project remains stable; session mutation serializes against session child writers |
| Session creation | `FOR SHARE` | New row insert | Prevents creation racing with project closure |
| Multi-project/multi-session operation | Required parent mode in project-before-session order; same-rank UUID order | Same | Prevents order inversion |

**Rationale:** PostgreSQL `FOR KEY SHARE` is compatible with `FOR NO KEY UPDATE`; it therefore does not provide the required fence against a normal non-key status update that obtains `FOR NO KEY UPDATE`. `FOR SHARE` conflicts with `FOR NO KEY UPDATE`, while remaining compatible with other `FOR SHARE` child writers. The exact lock conflict matrix must be verified against the actual deployed PostgreSQL major version and any triggers/functions that update key columns.

### 4.2 Required transaction sequence

For a session-scoped child command:

1. Authenticate and validate request envelope; resolve idempotency identity at L00.
2. Acquire L10 and L15–L18 if the command changes or relies on T-14/authorization state as required by its manifest.
3. Resolve project/session identifiers using non-locking reads only as locators.
4. Acquire project `FOR SHARE`, then session `FOR SHARE`; revalidate the session still belongs to that project, both are in permitted states, and caller scope is still valid.
5. Acquire remaining resources in ascending rank (instrument/version, assignment/membership, unit, association, claim, inspection, dependent rows).
6. Revalidate authorization, effective times, state, versions and invariants after the relevant locks.
7. Mutate aggregate + required domain event + audit + idempotency outcome atomically.
8. Commit; perform external I/O only after commit through durable intent/outbox.

For session update/transition, use project `FOR SHARE` then session `FOR NO KEY UPDATE`. For project update/close, acquire project `FOR NO KEY UPDATE` before any child/dependency checks. A parent mutation must not first acquire a weaker parent lock and later upgrade it.

### 4.3 Closure and asynchronous finalizer rules

- CMD-010 project close acquires the project parent fence before inspecting or locking sessions/assignments/dependent blockers. If it changes T-14 eligibility, L10 is acquired before identity and parent ranks.
- CMD-013 final session closure acquires project `FOR SHARE`, then session `FOR NO KEY UPDATE`, and only then evaluates the complete closure checklist and dependent blockers. It must not introduce a session-first path.
- Every child writer, claim path, inspection submit/approval, attendance verifier, evidence/document/print finalizer and other operation capable of advancing project/session work must acquire the applicable parent fence before its child aggregate.
- An asynchronous worker commits its lease/intent before external I/O. Its finalizer starts a new transaction, reacquires the complete parent chain in canonical order, validates source version and fencing generation, then commits or records a terminal/reconciliation outcome. It may not rely on a parent status read made before external I/O.
- A close operation must account for pending durable intents/jobs. If an external operation is in flight, closure must either block on a defined pending-work gate or close with an explicit policy that guarantees the later finalizer cannot advance a closed resource. The chosen disposition is an Operations/Product decision where workflow impact exists.
- No cascading delete, implicit child state rewrite or silent role/assignment revocation is introduced by closure.

### 4.4 CMD-009–015 normalization requirements

| Command | Required parent order | Additional ranks / review |
|---|---|---|
| CMD-009 update-project | L10 if eligibility affected → L30 project `FOR NO KEY UPDATE` | Project row_version/CAS; revalidate permitted project transition |
| CMD-010 close-project | L10 if eligibility affected → L30 project `FOR NO KEY UPDATE` → sessions in UUID order `FOR NO KEY UPDATE` as required | Full closure blocker inventory; no preflight-only gate |
| CMD-011 create-session | L00 → L30 project `FOR SHARE` → insert session | T-07 initial state is `DRAFT`; no `PLANNED` state |
| CMD-012 update-session | L00 → L30 project `FOR SHARE` → session `FOR NO KEY UPDATE` | expected_row_version; immutable code; schedule/dependent-work guard |
| CMD-013 transition-session | L10 if eligibility affected → L30 project `FOR SHARE` → session `FOR NO KEY UPDATE` | T-07 transitions; `CLOSE_REQUESTED` action/event only; final close authority/gates |
| CMD-014 publish-assignment | L10 if Inspector eligibility affected → L15–L18 affected principals/grants → project then session `FOR SHARE` → L40 instrument/version `FOR SHARE` → L50 assignment → L55 members | Complete initial roster; all user IDs sorted; T-14 recheck under capacity lock |
| CMD-015 change-assignment-members | L10 if Inspector eligibility affected → L15–L18 affected principals/grants → project then session `FOR SHARE` → L40/L50 assignment → L55 members | Per-member effective_at, reason, active-work blocker, submitted inspection preservation |

This table is a candidate sequence only. Each command's exact read/write set, lock modes, isolation level and constraints remain subject to review.

---

## 5. LPR-07 — exact primitives, call graph and effective privileges

Engineering/Database/Security should not approve a command based only on its top-level function text. The reviewed object graph must include:

1. Vercel route → Supabase client/JWT forwarding → PostgREST RPC → exposed PostgreSQL function.
2. Function owner, SECURITY DEFINER/INVOKER mode, fixed search_path, schema-qualified references and effective role memberships.
3. Every nested function/procedure, trigger function, trigger timing, dynamic SQL branch and exception handler.
4. Every table read/write, row lock, unique/exclusion index arbitration, FK check, deferred constraint and sequence access.
5. RLS policies, FORCE ROW LEVEL SECURITY state, table ownership, grants, default privileges, PUBLIC/anon/authenticated/service-role privileges and exact-signature EXECUTE ACL.
6. Auth helper functions and the exact caller-JWT/auth.uid() propagation path.
7. Idempotency, audit and event writes, including rollback behavior on audit failure.
8. External intent/outbox/worker boundary and any callback entry point.

**Required evidence per privileged function:** stable function identity/signature; owner and role-membership proof; SECURITY mode; search_path; schema references; effective privileges; caller JWT test; positive and negative role/scope/SoD tests; RLS interaction; dependency graph; lock set; transaction boundary; exact grant/revoke diff reviewed by Security. No blanket approval of all SECURITY DEFINER functions is implied by T-18.

**Candidate primitive guidance:** use explicit row locks only for invariant-bearing existing rows; use unique/exclusion constraints for final arbitration; use compare-and-swap for mutable aggregate versions; use a documented canonical-key arbitration strategy for absent-row identity; use transaction-scoped locks only where every writer can derive exactly the same key. Exact primitive selection is OPEN until Database/Security reviews physical constraints, PostgreSQL version, extension availability and trigger/function behavior.

---

## 6. LPR-08 — worker identity, lease fencing and callback trust

### 6.1 Worker execution boundary

- User commands and background workers are distinct principals and distinct authorization paths.
- Each worker type receives only the minimum permission to claim its own queue class, read the exact source snapshot and finalize its own result.
- Worker identity must be non-interactive and auditable. No browser token, user role, or general-purpose service-role credential is accepted as a substitute for a worker-specific authorization design.
- Queue claim is a short transaction: select bounded eligible work, atomically claim it, increment a monotonic fencing generation, set lease owner/expiry and persist attempt identity; then commit.
- Provider, Storage, scanner, PDF renderer, email/push and print I/O occurs outside database transactions.
- Finalization uses a new transaction and conditional predicate on exact job ID + lease owner + fencing generation + unexpired lease + expected source version. A stale worker must affect zero rows and must not append success facts.
- Lease expiry/reclaim increments the fencing generation. Wall-clock expiry alone is not sufficient to reject a stale worker after a newer worker has reclaimed the job.
- Retryable/unknown provider outcomes are durable and idempotent; never turn timeout into success or failure without reconciliation.

### 6.2 Provider callbacks

- Callback/webhook ingress is not a browser command and does not rely on `auth.uid()`.
- Verify provider authenticity using the provider's supported signature/secret mechanism, timestamp tolerance and replay/idempotency key; retain only the minimum safe verification evidence.
- Bind callback to provider account, provider event/attempt identity and the exact internal delivery/job. Reject unknown or mismatched identities without leaking internal records.
- Callback processing is idempotent and appends immutable outcome evidence. It cannot directly mutate arbitrary source business state.
- Provider capability, signature semantics, callback retry behavior, secret custody and data location require provider-owner/Operations/Security approval.

### 6.3 Required worker inventory

For CMD-033/034, CMD-036, CMD-038/039, CMD-044 and CMD-049–054 where asynchronous processing applies, document: worker class, principal, queue/table, claim predicate, batch bound, lease duration, fencing generation, attempt identity, source-version binding, allowed writes, external I/O, finalization locks, callback trust, retry policy, dead-letter/reconciliation and ACL. Missing workers remain BLOCKED, not inferred.

---

## 7. LPR-09 — normalized 50-application-command lock manifest

Every manifest row must contain the following fields before it can be certified:

| Field | Required content |
|---|---|
| Identity | CMD ID, contract version, owning detailed review, command type |
| Transaction boundary | One transaction / per-item transaction / intent + finalizer / read-only |
| Principal | Caller/worker/provider identity and exact authorization context |
| Ordered resources | Rank, table/object, exact row predicate/key, lock mode, comparator |
| Implicit edges | FK checks, unique/exclusion indexes, triggers, helper functions, sequences, RLS and deferred constraints |
| Revalidation | State, parent status, permission/scope, effective time, version, source snapshot and SoD checks after lock |
| Shared invariants | T-14, identity, claim, revision, closure, publication, print sequence, notification uniqueness, etc. |
| Competitors | Every command/worker/callback that can touch the same invariant |
| Constraints | Exact named constraint/index and behavior; “constraint exists” requires schema evidence |
| Retry/idempotency | Key scope/hash, replay, SQLSTATE classification, timeout/retry policy |
| Atomic evidence | Mutation + domain event + audit + idempotency result; rollback/failure semantics |
| External effects | Durable intent, lease/fence, I/O boundary, guarded finalization and reconciliation |
| Test links | Pairwise conflict tests, barrier plan, expected invariant, evidence URI/commit/environment |
| Status | INVENTORIED / NORMALIZED / REVIEWED / CERTIFIED with approver and evidence |

**Status definitions:**
- INVENTORIED: command ID exists in the register.
- NORMALIZED: all fields above are filled from authoritative contracts/schema; no guessed lock path.
- REVIEWED: Engineering, Database and Security have reviewed applicable details and accepted findings.
- CERTIFIED: complete effective graph and required tests prove the manifest against the exact schema/code commit/environment.

The current baseline is 54/54 traceability IDs inventoried: 50 application commands and 4 external control-plane IDs. Application lock certification remains 0/50. No command is upgraded by this package. LPR-09 remains OPEN until all 50 application rows are normalized and reviewed; CMD-045–048 remain outside the application lock set.

---

## 8. LPR-10 — adversarial concurrency verification plan (NOT EXECUTED)

Testing must run only after G10 or a separately authorized isolated-test scope, with no production data or credentials. Before execution, record PostgreSQL major/minor, extensions, migration head, function/trigger/constraint inventory, code commit, test harness version, isolation level, pool settings and environment.

### 8.1 Required conflict matrix

| Test family | Competing operations | Required assertion |
|---|---|---|
| Parent closure | CMD-010 vs CMD-011/012/014/015 and every project child writer | No child commits after closure wins; no closure passes while a blocking in-flight operation is active |
| Session closure | CMD-013 vs CMD-012/014/015, claims, inspection transitions and finalizers | T-07 state/gates hold; no late finalizer advances CLOSED session |
| T-14 | CMD-004/005/014/015/016 plus account eligibility changes | Combined distinct-account count never exceeds cap; no silent revocation; reductions below count reject |
| Identity | CMD-022/023/025/026/027 | One canonical identity/active association/claim; no cross-project duplicate or lost conflict |
| Claim/inspection | CMD-026/027 vs CMD-028–035 | One active claim; stale claim cannot submit/approve; revisions and terminal decisions remain unique |
| Instrument | CMD-014/018/019/020/021 | Assignment pins only published active version; published snapshot immutable; deactivation/publication races deterministic |
| Evidence/document | CMD-033/034/036 vs submit/reopen/closure | No unfinalized evidence accepted; stale worker cannot finalize against changed/closed source |
| Attendance/print | CMD-039/040 and CMD-037/038 | Exact document version verified; per-document print sequence unique and monotonic; partial batch retry does not duplicate success |
| Notifications | CMD-051–054, duplicate scheduler/fan-out/dispatch/callback | One logical recipient delivery/escalation; stale lease cannot commit; callbacks replay safely |
| Authorization | CMD-002–007 vs protected commands and concurrent revocation | No stale permission/scope after revoke commits; no self-elevation or grantor ceiling bypass |
| Idempotency/audit | Every critical mutation vs retry, timeout, deadlock, forced audit failure | One durable result/event; failure rolls back mutation; replay never repeats external effect |

### 8.2 Execution protocol

- Use two or more independent sessions with deterministic barriers, not sleep-only timing.
- Run each pair in both acquisition/start orders and repeat under representative concurrency.
- Capture SQLSTATE, deadlock reports, lock waits, statement timing, transaction outcome and final invariant state.
- Include timeout, worker crash, lease expiry/reclaim, provider timeout/unknown outcome, audit insert failure and retry.
- Assert both safety (no invalid state) and liveness (bounded completion or classified retry); no unbounded retry loop.
- Tie evidence to exact schema migration head, code commit and environment; QA and Security sign the result.
- Do not mark LPR-10 complete based on unit tests or a static graph alone.

No test was executed for this package.

---

## 9. LPR-01 and LPR-07–LPR-11 decision record template

The accountable reviewers must record one explicit outcome per item: APPROVE, REJECT or AMEND, with reviewer identity/role, date, rationale, affected document versions, conditions and evidence references.

| ID | Proposed technical disposition | Accountable review | Current status |
|---|---|---|---|
| LPR-01 | Accept/refine the candidate rank order in §3, including L15–L18 identity/authorization classes and no late lower-rank acquisition | Engineering + Security | OPEN — no approval inferred |
| LPR-07 | Approve exact PostgreSQL lock modes/primitives only after effective object graph, deployed version, privileges and implicit index/FK/trigger paths are inventoried | Engineering + Database + Security | OPEN |
| LPR-08 | Approve worker-specific identity, lease/fencing, provider callback trust, secrets custody and ACL per worker/provider | Security + Operations + provider owner | OPEN |
| LPR-09 | Normalize/review all 50 application manifests against §7; reconcile each command catalogue/detail/physical schema/test reference. Keep CMD-045–048 as external traceability only | Engineering + Database + Security + QA | OPEN |
| LPR-10 | Execute §8 adversarial suite in authorized isolated environment and attach reproducible evidence | Engineering + QA + Security | NOT EXECUTED |
| LPR-11 | Approve L15–L18 identity/authorization ordering relative to L10, L20, L30 and L50/L55; validate T-14 writer coverage | Engineering + Security; institution where relevant | OPEN |

---

## 10. Documentation correction and synchronization obligations

Before any technical approval is recorded:

1. Reconcile the older CMD-011/CMD-013 state language with T-07 in the decision package, command catalogue, detailed review, functional model, API/transaction contracts, QA tests and all lock artifacts.
2. Replace every source recipe that acquires session before project with project-before-session; document any command that does not require a session parent and justify it.
3. Replace CMD-011's `FOR KEY SHARE` proposal with the approved compatible parent-fence mode only after Engineering/Database approval; do not silently implement this candidate.
4. Add L15–L18 to the graph and all affected CMD-001–007, CMD-004/005, CMD-014/015 and CMD-016 manifests.
5. Reconcile CMD-010/013 closure with all child writers and async finalizers; identify pending-work disposition and T-14 effect.
6. Normalize CMD-023–027 identity/association/claim order and CMD-028–040 aggregate/finalizer order.
7. Add worker principal, lease/fencing and callback contract for every async command.
8. Update physical schema/ERD/constraints only after exact design approval; do not infer DDL from this proposal.
9. Update RTM, RAID and DGA status only when documentary or runtime closure evidence exists.

---

## 11. Current verification and gate status

Static documentation review only. The root AGENTS.md v1.2.2, MIB-001 v1.0.11, IRG-001 v1.0.4, DGA-001 v1.11.39, SSOT-AUDIT-001 v0.1.5, Decision Register, lock resolution, global graph, 54-command manifest, command catalogue, detailed command reviews, physical schema and privileged transaction specification were inspected.

Not performed: source-code changes, SQL, migrations, grants/revokes, live database catalog/lock inspection, CI, automated tests, adversarial concurrency tests, deployment, merge or production changes.

| Item | Status |
|---|---|
| LPR-01 | OPEN — technical approval required |
| LPR-07 | OPEN — exact primitives/effective graph approval required |
| LPR-08 | OPEN — worker/provider security approval required |
| LPR-09 | OPEN — 50 application manifest normalization/review required; CMD-045–048 are external traceability IDs |
| LPR-10 | NOT EXECUTED |
| LPR-11 | OPEN — identity/authorization rank approval required |
| DGA-B14 | PARTIAL |
| DGA-B17 | OPEN |
| DGA-B18 | PARTIAL |
| DGA-B19 | OPEN |
| DGA-B21 | OPEN |
| Lock manifest | 54/54 traceability IDs inventoried (50 application + 4 external); 0/50 application commands certified |
| G3/G4/G5/G7/G9 | NOT READY |
| G10 | NOT ACTIVE — pending verified G9 and separate activation record |

**Final disposition:** this package makes the technical decisions concrete and reviewable; it does not approve them on behalf of Engineering, Database, Security, QA, Operations or the institution. Do not merge this PR or begin implementation based on this package alone.


## 12. Authority and evidence freshness addendum — 2026-11-24

This revision corrects the stale root-policy reference from AGENTS.md v1.2.0 to v1.2.1 and records the current governance source versions. It does not change any technical recommendation or approval status. AUTH-06/AUTH-07 remain pending; LPR-01 and LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED; lock certification remains 0/54. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT ACTIVE pending verified G9 and a separate approved activation record. No implementation, SQL, migration, grants/revokes, CI, live database inspection or test execution is claimed.


## Conditional Product Owner authorization status synchronization — 2026-11-24

The Product Owner's explicit conditional implementation authorization is recorded in the canonical Decision Register. It permits transition toward implementation from zero using the SSOT baseline, subject to G9 closure and a separate G10 activation record. **Current status: G9 NOT READY; G10 NOT ACTIVE.** This status synchronization does not approve this technical proposal, any lock mode, permission, function ACL, migration or runtime behavior. Technical and institutional approval boundaries stated in this document remain unchanged.


## 13. Current gate and source-baseline synchronization — 2026-11-24

This version synchronizes the current authority pointers to root AGENTS.md v1.2.2, MIB-001 v1.0.11, IRG-001 v1.0.4 and DGA-001 v1.11.39. The controlling authorization state is conditional Product Owner implementation authorization received; G9 NOT READY; G10 NOT ACTIVE pending verified G9 and a separate approved G10 activation record. Any earlier “G10 NOT AUTHORIZED” statement in this document is a historical snapshot, not the current state.

This correction changes no technical approval, lock primitive, worker identity, ACL, manifest certification or test status. LPR-01 and LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED; lock certification remains 0/50 application commands. G3/G4/G5/G7/G9 remain NOT READY. No implementation, SQL, migration, grants/revokes, CI, live database inspection, concurrency test, deployment or merge is claimed.


## 14. Application lock-certification denominator clarification — 2026-11-24

CMD-045–048 are Product Owner-approved external control-plane traceability IDs and do not represent application commands, routes, RPCs, workers or database transactions. Accordingly, LPR-09 normalization and LPR-10 adversarial application lock verification apply to the 50 in-scope application commands only. The repository inventory remains 54/54 traceability IDs; the current application lock certification baseline remains 0/50. This denominator clarification is documentation reconciliation only and does not certify any manifest or change any technical approval/test status.


## 15. Current cross-document lock baseline — 2026-11-24

Current linked document versions are DGA-001 v1.11.40, LOCK-MANIFEST-001 v0.4.24, LOCK-GRAPH-001 v0.4.17, LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.11, CMD-CROSSWALK-001-054 v0.8.19 and CONCURRENCY-001 v0.1.7. The traceability inventory is 54 IDs, comprising 50 application commands and 4 external control-plane IDs. LPR-09 and LPR-10 apply to the 50 application commands only. Candidate transaction/resource boundaries are documented for 50/50 application commands, but full normalized-manifest completion and technical certification remain OPEN; certified lock-complete is 0/50. LPR-01 and LPR-07–LPR-09/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. This addendum is a static source-version/denominator reconciliation, not technical approval or runtime evidence.


## 16. Normalized manifest register and LPR-09 scope — 2026-11-24

[LOCK-NORMALIZATION-001](COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md) v0.1.0 now provides a single structured register for all 50 in-scope application commands, preserving candidate resource order, revalidation/invariants and unresolved evidence. It is not an approved physical lock manifest. LPR-09 remains OPEN until all 50 records are reconciled to exact physical objects, implicit FK/index/trigger/function edges, privileges and competing writers and receive accountable Engineering/Database/Security/QA approval. LPR-10 remains NOT EXECUTED; no concurrency certification is claimed. CMD-045–048 remain excluded external IDs.


## 17. Normalized register inventory verification — 2026-11-24

The new LOCK-NORMALIZATION-001 v0.1.0 contains exactly 50 unique in-scope application command rows: CMD-001–044 and CMD-049–054. CMD-045–048 are excluded external control-plane IDs. This verifies row inventory and traceability only. It does not close LPR-09: exact physical objects, PostgreSQL implicit edges, privileges, complete competing writers, and named technical approvals remain outstanding. LPR-10 remains NOT EXECUTED; certified lock-complete remains 0/50; G9 NOT READY; G10 NOT ACTIVE.
