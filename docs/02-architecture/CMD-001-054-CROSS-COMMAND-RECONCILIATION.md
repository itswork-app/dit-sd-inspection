# CMD-001–054 Cross-Command Reconciliation

**Document ID:** CMD-CROSSWALK-001-054  
**Version:** 0.8.12
**Status:** Engineering reconciliation — OPEN; no executable command contract approved  
**Date:** 2026-11-24  
**Repository phase:** Documentation / SSOT maturation  
**Authority:** AGENTS.md, MIB-001, DGA-001, IRG-001, T-10, T-14–T-18 and the approved Decision Register  
**Controls:** G2–G10; DGA-B04–B21; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Purpose and conclusion

This document reconciles the complete proposed command inventory CMD-001–054 across detailed command reviews, the canonical command catalogue, permission registry, physical schema, table-by-table RLS catalogue, API/transaction design, function security design, audit event catalogue, RTM, QA catalogue and RAID register.

The review is static and documentation-only. It does not inspect a live Supabase database, deployed Vercel routes, GitHub rulesets, provider configuration or production environment. It does not authorize implementation.

### 1.1 Executive conclusion

- All proposed logical commands CMD-001–054 now have a corresponding detailed contract review document, grouped as 001–010, 011–020, 021–030, 031–040, 041–044, 045–048 and 049–054.
- The command catalogue contains 54 proposed operations. The Command Authorization Verification Matrix reports **0 approved/executable command-specific contracts**.
- The physical schema and RLS catalogues have proposed 48/48 table-name parity. This proves documentation inventory parity only, not physical completeness, live existence, deployed RLS, grants or command-level data integrity.
- The permission registry remains a PO/security draft. Role grants, grantor authority, SoD and exact permission-to-command predicates are not approved end-to-end.
- T-18 Option A (Vercel route forwarding caller JWT to narrowly scoped PostgreSQL functions) is PO-approved as an architecture pattern. Individual function signatures, owners, security mode, search_path, EXECUTE ACL, JWT propagation and runtime tests remain unverified.
- Detailed command tests and function-security tests are specifications only; none are execution evidence.
- T-10 institutional records/privacy decisions and T-12 provider ownership evidence remain blocked.
- CMD-045–048 remain intentionally blocked by authority/schema prerequisites.
- Notification CMD-049–054 remain proposals; worker identity/ACL, policy authority, recipient selectors, provider capability and T-10 controls remain open.

**Disposition: G9 NOT READY. G10 NOT AUTHORIZED.** No implementation, SQL, migration, grant/revoke, RLS change, live database operation, provider setup, deployment, CI execution or merge is authorized or claimed.

## 2. Scope, sources and review method

### 2.1 Detailed command review coverage

| Command range | Detailed review | Coverage and disposition |
|---|---|---|
| CMD-001–010 | CMD-001-010-DETAILED-CONTRACT-REVIEW.md | Request/response proposals, authorization, read/write sets, transactions, audit, route candidates and tests; cross-command findings remain open |
| CMD-011–020 | CMD-011-020-DETAILED-CONTRACT-REVIEW.md | Session, assignment, capacity, target and instrument contracts; physical versioning and lifecycle gaps remain |
| CMD-021–030 | CMD-021-030-DETAILED-CONTRACT-REVIEW.md | Instrument deactivation, unit identity/association, claims, draft, submit and review; lock order and physical lifecycle gaps remain |
| CMD-031–040 | CMD-031-040-DETAILED-CONTRACT-REVIEW.md | Review, reopen, evidence, sync, documents, print, attendance; multiple schema/authority gaps remain |
| CMD-041–044 | CMD-041-044-DETAILED-CONTRACT-REVIEW.md | Reports and audit read/export; T-10 and metric/export blockers remain |
| CMD-045–048 | CMD-045-048-DETAILED-CONTRACT-REVIEW.md | Intentionally blocked retention, security incident, provider configuration and production release operations |
| CMD-049–054 | CMD-049-054-DETAILED-CONTRACT-REVIEW.md | Notification inbox, policy publication and internal workers; NLA-001 approvals and mismatches remain |

The detailed review documents are engineering proposals. Their presence does not convert candidate names, request fields, routes, function names, permissions, physical objects or tests into approved contracts.

### 2.2 Controlling documents reviewed

- Root AGENTS.md v1.2.0.
- MIB-001 and IRG-001.
- DGA-001 and Decision Register.
- PostgreSQL Command Contract Catalogue v0.4.1.
- Canonical Permission Registry and Command Authorization Matrix v0.2.0.
- Command Authorization Verification Matrix.
- Physical Database Schema and Integrity Specification v0.3.0.
- Table-by-Table RLS Policy Catalogue v0.2.0.
- Physical Schema ↔ RLS ↔ Command Reconciliation v0.2.0.
- API and Transaction Contracts.
- Privileged Command Boundary and Transaction Specification.
- PostgreSQL Function Security and EXECUTE Grant Design.
- T-18 Execution Model Security Review.
- Audit Event Catalogue and Governance.
- NLA-001 v0.1.1.
- Evidence Privacy, Retention, Deletion and Recovery Specification.
- Production Environment, Secrets and Provider Governance.
- Requirements Traceability Matrix, Test Case Catalog and UAT Plan, RAID Register.
- All seven detailed command review documents listed in §2.1.

### 2.3 Evidence classification

Use these distinctions throughout:

- **PO APPROVED:** product decision within PO authority.
- **INSTITUTIONAL APPROVAL REQUIRED:** reserved authority not supplied by PO approval.
- **DESIGN PROPOSAL:** static engineering proposal, not approved executable contract.
- **DOCUMENTATION INVENTORY:** names/counts reconciled across documents only.
- **NOT VERIFIED:** no live or runtime evidence.
- **PLANNED / NOT EXECUTED:** test case exists but has not run.
- **BLOCKED:** required authority/schema/security evidence is absent.

## 3. Cross-command invariants

### 3.1 Trusted identity and authorization

All protected commands must derive actor identity from the authenticated caller JWT at PostgreSQL using auth.uid(). Client-supplied actor, role, permission, scope, publisher, reviewer, approver, worker identity or provider authority is not trusted.

A permitted user command requires all applicable checks:
1. valid authenticated identity;
2. active and approved application account;
3. explicit approved permission grant;
4. effective scope over the exact resource;
5. allowed resource state and transition;
6. separation-of-duties constraints;
7. RLS and SQL privilege boundary;
8. idempotency and audit requirements.

Role names and UI visibility do not grant access. A global catalog or identity permission does not imply project access. A notification does not authorize access to its source resource.

### 3.2 T-18 command boundary

T-18 Option A is the approved architecture pattern:
- Vercel route validates a typed request and verified Supabase session;
- caller JWT is forwarded unchanged to the corresponding PostgreSQL command function;
- PostgreSQL derives actor with auth.uid() and performs authoritative checks;
- protected browser-side direct INSERT/UPDATE/DELETE remains denied;
- each function receives only the exact approved EXECUTE grant;
- read-only paths prefer SECURITY INVOKER/RLS where feasible;
- each SECURITY DEFINER function requires an individually reviewed least-privileged NOLOGIN owner, safe search_path, schema-qualified references and exact grants.

T-18 approves the narrow SECURITY DEFINER wrapper model for protected writes and SECURITY INVOKER preference for scoped reads. It does **not** approve any individual command contract, function signature, route, role, grant, RLS policy, function owner or exact EXECUTE ACL. The live Supabase inventory and actual Vercel-to-PostgREST caller-JWT path remain unverified.

### 3.3 Atomicity, audit and external effects

For a protected database mutation, the approved design direction requires business state, canonical domain event, required audit event and idempotency outcome to commit atomically. Where a domain command must create notification intent, the outbox intent is part of that same transaction. Audit/outbox failure fails closed when required by the contract.

External Storage transfer, PDF rendering, provider email/push, print device action, deployment and backup/restore cannot be included in one PostgreSQL transaction. These require explicit durable state machines, leases/outbox/saga or compensation, idempotent retry, uncertain outcomes and reconciliation.

### 3.4 Immutability and history

Submitted inspection revisions, published instrument versions, review decisions, print events, audit events, delivery attempts, published notification policies and escalation events require immutable history. Corrections create a new version/event; they do not silently rewrite the historical fact.

### 3.5 Global lock order and serialization

The privileged command specification defines this global lock order:
1. idempotency arbitration;
2. governed project capacity/settings row where capacity is involved;
3. canonical serial-key arbitration where registering/resolving;
4. project/session/assignment rows in deterministic order;
5. canonical unit rows in deterministic order;
6. unit-project association rows in deterministic order;
7. inspection aggregate rows in deterministic order;
8. evidence/document rows in deterministic order;
9. append-only domain/audit event inserts.

The detailed CMD-026 claim review identifies a lock-order conflict: its local matrix places assignment after unit/association while the global hierarchy requires project/session/assignment before unit/association. This remains a blocking concurrency design conflict. No code should be written until a single canonical order and a full cross-command lock graph are approved and tested.

T-14 also requires all Inspector-capacity-affecting commands to serialize on the same project capacity/settings row and use the identical qualifying-account predicate. The relevant writers include role grant/revoke and assignment/member/capacity operations (CMD-004/005 and CMD-014/015/016). A local implementation of CMD-016 cannot prove the global cap.

## 4. Consolidated findings

### 4.1 Physical model and concurrency token gaps

The following cross-command gaps recur across independent command reviews:

| Finding | Commands | Current discrepancy | Required resolution |
|---|---|---|---|
| X-DB-01 | CMD-001 | No dedicated account-request entity is identified; pending request/history ownership is unclear | PO/architecture decide Auth signup versus request lifecycle and authoritative request/history model |
| X-DB-02 | CMD-004–007 | Role/scope history, grant kind, validity intervals, cache/revocation freshness and last-admin recovery are incomplete | Approve physical grant model, immutable history, interval/overlap constraints, grantor ceiling and authorization freshness |
| X-DB-03 | CMD-009/010 | Project optimistic version/update metadata is absent from physical summary | Approve row_version/version strategy and increment semantics or replace expected_version contract |
| X-DB-04 | CMD-012/013 | Sessions require expected_version but physical sessions table has no version token | Approve physical version field and transition increment semantics |
| X-DB-05 | CMD-016 | Capacity command expects a version but project_capacity_settings lacks a version field | Approve version token/default-row initialization while retaining T-14 shared serialization |
| X-DB-06 | CMD-021 | Instruments require expected_version but physical instruments schema has no row_version | Approve token and deactivation concurrency semantics |
| X-DB-07 | CMD-022/023 | Unit identity_attributes and typed association evidence reference are not physicalized | Define allowlisted attributes/provenance model; reject arbitrary URL/object key |
| X-DB-08 | CMD-024 | Association expected_version has no physical column; ENDED/REVOKED and active-work gates incomplete | Approve association episode state model, versioning and active-claim/draft/reviewable-work rules |
| X-DB-09 | CMD-028/032 | Mutable draft response representation is unclear relative to immutable submitted revisions and reopen | Define draft revision identity, response patch semantics, no-op behavior and reopen projection |
| X-DB-10 | CMD-029/035 | Durable per-operation sync conflict/result model and device registry/binding/revocation are absent | Define device lifecycle, operation ledger, conflict state/query and retry/revocation behavior |
| X-DB-11 | CMD-030/031 | Reviewer assignment source and eligibility predicate are not physicalized | Approve explicit reviewer assignment and one terminal review decision per revision |
| X-DB-12 | CMD-033/034 | Evidence upload intent/reservation/expiry is missing; storage metadata must be server-observed | Define two-phase upload schema, quota reservation, object verification and server-owned object reference |
| X-DB-13 | CMD-036/037 | Document source provenance, template registry/version, renderer job lifecycle and immutable document version/print sequence are incomplete | Define source FK/provenance, template/version, job/lease/retry and lock-safe version/sequence allocation |
| X-DB-14 | CMD-038 | Print batch item manifest and durable outcomes for invalid/unresolvable items are unclear | Decide print_batch_items or equivalent stable manifest; define per-item outcome and aggregate reconciliation |
| X-DB-15 | CMD-039/040 | Attendance location/assignment linkage, upload metadata and append-only verification history are incomplete | Define exact location scope, two-phase upload, immutable verification history, rejection event and uploader/verifier SoD |
| X-DB-16 | CMD-050 | Previous expected_version field conflicted with no physical notifications row-version | RESOLVED AT DOCUMENTATION BOUNDARY: remove expected_version; guarded set-once read_at is the state arbiter; runtime/audit verification remains open |
| X-DB-17 | CMD-051 | Persisted draft lifecycle was previously conflated with the publish command | RESOLVED AT COMMAND SCOPE: CMD-051 is publish-only; persisted draft CRUD is excluded pending a separate approved command/schema |
| X-DB-18 | CMD-052 | NLA/schema/catalogue previously differed on payload and lease detail | RESOLVED AT DOCUMENTATION BOUNDARY: safe_payload and owner/token-hash/generation/expiry lease tuple aligned; partial progress remains PROCESSING and retries use uniqueness arbiters |
| X-DB-19 | CMD-045–048 | Retention/legal-hold, security-case, provider-config and release-record schemas are absent or intentionally undefined | Keep blocked until institutional/operational authority and domain models are approved; do not add placeholders |

The repeated version-token pattern is systemic, not a set of isolated API issues. Every expected_version field must map to a physical concurrency token, a documented compare-and-swap predicate and an increment rule. A request field alone does not provide optimistic concurrency.

### 4.2 Authorization, permission and SoD gaps

1. The canonical permission registry v0.2.0 is a draft; it is not authority to seed permissions or grant roles.
2. Role-to-permission mapping, grantor/delegation ceiling, self-grant prohibition, scope inheritance, revocation freshness and emergency/break-glass authority are not approved end-to-end.
3. Proposed permissions retention.manage, security.review, provider.manage and release.manage require institutional/operational authority; CMD-045–048 remain blocked.
4. notification.read is self-scoped; it must not grant access to the referenced project, inspection or evidence.
5. notification.policy.manage is a proposed scoped configuration permission; role grants and grantor/SoD matrix remain open.
6. CMD-052–054 are internal worker/scheduler operations, not user-role permissions. They must not be seeded as ordinary authenticated user grants.
7. Attendance uploader/verifier, Inspector/reviewer, grantor/target, policy author/publisher, provider change requestor/approver/executor and release requestor/approver/operator separation must be explicit where required by the authorized policy.
8. Super Admin labels do not imply global audit, security-case, records, provider or production-release authority.

### 4.3 RLS and SQL privilege gaps

The 48/48 physical/RLS table-name parity is a documentation inventory check. It does not prove:
- live table existence or exact columns/types/constraints;
- RLS enabled/forced or deployed policy predicates;
- table/sequence/schema ACLs;
- exact command function signatures or EXECUTE grants;
- function owner, SECURITY INVOKER/DEFINER mode, search_path or nested object privileges;
- view/materialized-view/trigger/helper-function safety;
- Storage bucket/object policy or signed URL enforcement;
- actual caller JWT forwarding and PostgREST exposure.

The RLS catalogue's CMD label means command-only mutation; it is not a direct browser DML grant. The following notification posture is proposed:
- notifications: recipient-self read only; CMD-050 set-once read via trusted command; no R-admin/global inbox read; dismissed_at is dormant;
- notification_outbox: no browser read; internal worker only;
- notification_deliveries: no browser access; worker-only mutation, restricted operations reader only if approved;
- notification_delivery_attempts: no browser access; append-only sanitized worker history;
- notification_escalation_events: no browser access by default; internal worker only; restricted operations reader only after explicit approval;
- notification_policy_versions: default-deny browser read; any narrowly scoped configuration read requires an approved grant; CMD-051 publish-only.

Each table requires exact positive/negative RLS tests and SQL privilege review. RLS does not itself grant SQL privileges, and a function EXECUTE grant does not itself authorize the business action.

### 4.4 API, command and transport gaps

- The command catalogue contains logical command IDs and candidate input fields; no final REST path or PostgreSQL signature is approved.
- API-AND-TRANSACTION-CONTRACTS.md defines a common envelope and selected transaction patterns, but does not replace a complete command-by-command request/response schema and exact route/RPC mapping.
- The Command Authorization Verification Matrix reports 54 individual command draft rows but zero approved/executable command-specific contracts.
- Candidate names such as cmd_<name>_v1 remain naming conventions only; actual SQL types, overloads, route methods, response schemas and typed error mappings must be derived from approved physical types and inspected inventory.
- CMD-053 provider callbacks are assigned to INT-NOTIF-001, a separate provider-authenticated integration ingress; provider-specific signature, freshness, event deduplication and runtime ACL remain open.
- CMD-054 no longer accepts evaluation_time; the worker captures one DB UTC instant. SLA start, calendar/timezone and pause/close semantics remain open.

### 4.5 Audit event and privacy gaps

T-15 / INS-016 direction is PO-approved: append-only audit, critical mutation/audit atomicity, fail-closed behavior on audit failure and least-privilege read/export. It is not a substitute for T-10 institutional approval.

Cross-command audit mismatches and dependencies:
- CMD-022/025 identity-conflict lifecycle requires exact conflict-open/resolved/rejected event keys; the command reviews identify missing or non-final event mapping.
- CMD-040 has VERIFIED/REJECTED outcomes, but attendance.rejected is not clearly enumerated in the audit event catalogue.
- CMD-043 audit access requires a non-recursive access-audit path and field-minimized event projection.
- CMD-044 requires institutional export authority and a complete export request/job/manifest/artifact lifecycle; none is established by the current physical inventory.
- CMD-050 emits notification.read once on the first set-once read transition; inbox page access and duplicate acknowledgements do not emit general audit events.
- CMD-053 delivery attempts belong in the dedicated append-only attempt table; routine retries should not be duplicated into the general audit stream.
- INT-NOTIF-001 callback state changes remain in delivery projections and privacy-safe telemetry; routine callbacks/retries do not flood the general audit stream.
- CMD-045 retention/legal-hold must reconcile immutable audit history with institutional disposition policy. Engineering cannot decide to retain all personal data indefinitely or delete audit rows silently.
- CMD-046 security-case access and actions must be auditable, but case evidence and sensitive payloads must be minimized.
- CMD-047 provider changes and CMD-048 release events require safe metadata and approved evidence retention.

T-10 still blocks classification, lawful/institutional purpose, evidence limits, retention, deletion/disposition, legal hold, audit retention/export and network metadata. No retention duration, legal basis or deletion eligibility is approved by this reconciliation.

### 4.6 External-effect and recovery gaps

The following operations cross database/provider boundaries and cannot be described as one atomic PostgreSQL transaction:
- CMD-033/034 evidence upload/finalization and orphan reconciliation;
- CMD-036 PDF rendering and document generation;
- CMD-038 physical/batch printing and per-document result reconciliation;
- CMD-045 disposition across database, Storage, backups and provider replicas;
- CMD-047 provider configuration/secret rotation;
- CMD-048 deployment/migration/rollback;
- CMD-052–054 notification fan-out, provider dispatch, webhook and scheduler processing.

Each requires durable intent/state, idempotency, bounded lease, retry, uncertain result, compensation or reconciliation, operational monitoring and immutable evidence. Provider calls must not be performed while holding database locks.

### 4.7 Institutional and operational blockers

| Dependency | Affected commands | Current state | Required evidence |
|---|---|---|---|
| T-10 records/privacy | CMD-033/034, 043–046, 049–054 and evidence/offline flows | PO-approved formal review path only; substantive policy BLOCKED | Written institutional classification, purpose/legal basis, evidence limits, retention, deletion/disposition, legal-hold, audit/export and metadata policy |
| T-12 provider ownership | CMD-047/048 and notification providers | PO-approved alternative arrangement direction only; actual ownership BLOCKED | Signed ownership/RACI, legal/account and billing owner, custodians, region, plans, quotas, budget, support and recovery entitlements |
| T-14 capacity | CMD-004/005, 014/015/016 | Predicate direction PO-approved; physical versioning and cross-writer serialization still need proof | Shared capacity-row lock and identical predicate across every writer; concurrency evidence |
| T-16 serial/association | CMD-022–027 | PO direction approved; physical identity/association and lock review gaps remain | Approved normalization/exception policy, composite FK/association model, conflict authority and lock graph |
| T-17 instrument governance | CMD-019/020/021 and dependent workflows | PO direction approved; configuration hash/snapshot and schema allowlist details remain open | Versioned declarative schema, deterministic hash, immutable publication and compatibility evidence |
| T-18 execution | CMD-001–044, CMD-049–054 | Option A pattern PO-approved; per-function design and runtime evidence open | Route/JWT proof, function owner/security mode/search_path/EXECUTE ACL, table ACL/RLS and negative tests |
| CI/repository governance | All release-bound commands | Live branch protection/ruleset and required checks NOT VERIFIED | Read-only ruleset/workflow evidence and authorized required-check run |
| Recovery/provider capability | CMD-033/034, 036–038, 047/048, 053 | NOT VERIFIED | Provider capability, quota/cost, backup/Storage restore, incident contacts and measured recovery evidence |

## 5. Traceability and verification reconciliation

### 5.1 Command-to-test coverage

The current documentation distinguishes:
- 48 original command contract cases: TC-CMD-CONTRACT-024-001 through TC-CMD-CONTRACT-024-048;
- family-level authorization cases: TC-CMD-AUTHZ-024-001 through TC-CMD-AUTHZ-024-036;
- notification lifecycle cases: TC-NOTIF-001 through TC-NOTIF-018;
- function-security cases and T-18 execution-model cases, with their own separate series.

These are planned test identifiers, not executed evidence. Do not treat the existence of a test row as proof that the command's physical invariant, permission, RLS, function ACL or provider boundary passes.

The command review documents include command-specific positive, negative, replay, concurrency, audit-failure and external-effect cases. The exact test-to-command-to-requirement crosswalk still requires reconciliation and approved fixtures, function signatures, expected typed outcomes and evidence schema.

### 5.2 Test execution boundary

No unit, integration, contract, RLS, authorization, concurrency, load, accessibility, UAT, provider, backup/restore or production operational test is claimed by this document. Test execution requires G10 and authorized environments. Results must be bound to exact commit, schema/migration head, environment, test data and evidence artifact.

### 5.3 RTM and RAID

The RTM currently records the command design catalogue as extended while PO/security approval and implementation verification remain open. AUD-GOV-001 remains PO-approved only at the T-15 direction level; institutional and implementation verification are open. EVD-003 and OPS-004 remain draft/blocked by institutional policy and provider ownership.

RAID D-026 remains OPEN for NLA-001 recipient selectors, policy authority, worker identity/ACL, provider capability and T-10 retention/privacy. R-026 is mitigating by design but verification remains open. R-025 remains OPEN / CRITICAL for premature implementation-gate entry.

This reconciliation does not close any DGA, RTM or RAID item. A status change requires accountable-owner acceptance and referenced closure evidence.

## 6. Consolidated action register

| ID | Priority | Scope | Required action | Accountable authority | Gate |
|---|---|---|---|---|---|
| X-01 | Critical | CMD-001–054 | Approve canonical permission registry, role/grantor matrix, scope and SoD | PO + Security | G2/G4 |
| X-02 | Critical | CMD-001–054 | Reconcile all expected_version fields to physical version tokens and compare-and-swap semantics; see [Concurrency and Version Token Reconciliation](CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) | Engineering + PO + Security | G3/G5 |
| X-03 | Critical | CMD-026 and all multi-row writers | Resolve global lock order and prove cross-command lock graph | Engineering + Security | G3/G7 |
| X-04 | Critical | CMD-001–054 | Complete route/RPC/request/response/function signature mapping; no candidate name promoted by assumption | Engineering + Security | G5 |
| X-05 | Critical | CMD-001–054 | Per-function owner, SECURITY mode, search_path, exact EXECUTE ACL, table ACL and caller-JWT proof | Engineering + Security | G4/G5 |
| X-06 | Critical | CMD-001–054 | Reconcile physical schema, constraints, RLS predicates, views, triggers, sequences and Storage policy | Engineering + Security | G3/G4 |
| X-07 | Critical | CMD-022/025/040 and audit | Complete canonical event keys and immutable history mapping | Engineering + PO/Security | G4/G7 |
| X-08 | Critical | CMD-043–046, 049–054 | Obtain T-10 institutional records/privacy decisions | Institution records/legal/privacy/security authorities | G1/G4/G8 |
| X-09 | High | CMD-047/048 and notification channels | Close T-12 provider ownership, plan, region, quota, budget and recovery evidence | Sponsor + Institution + Operations | G8 |
| X-10 | High | CMD-033/034, 036–038, 045, 047/048, 052–054 | Define external-effect state machines, retries, uncertain outcomes and reconciliation | Engineering + Operations + Security | G3/G7/G8 |
| X-11 | High | CMD-049–054 | Approve NLA-001 selectors, policy authority, worker identity/ACL, callback boundary and SLA clock | PO + Security + Institution + Operations | G2/G4/G5 |
| X-12 | High | CMD-001–054 | Reconcile every command to RTM, QA case IDs, fixtures, expected outcomes and evidence artifacts | Engineering + QA + PO | G7 |
| X-13 | High | All | Execute live read-only Supabase inventory and reconcile actual objects/ACL/RLS after authorized access | Security + authorized DB owner | G4/G9 |
| X-14 | High | All | Verify GitHub rulesets, required CI checks, secrets scanning and release workflow | Repository administrator | G0/G8 |
| X-15 | High | All | Reconcile DGA/RAID/RTM with accepted evidence; no status-only closure | Document owner + PO | G9 |
| X-16 | Critical | CMD-001–054 | Reconcile global lock ranks, CMD-023/024/026 order, T-14 eligibility serialization, parent closure fences, claim/inspection ordering and worker lease boundaries; add lock manifests and execute adversarial concurrency tests | Engineering + Security + PO; Operations/Institution where applicable | G3/G4/G5/G7/G9 |\n
| X-17 | Critical | CMD-001–054 | Review LOCK-MANIFEST-001 54-command resource/lock inventory; resolve all source-order contradictions, missing lock targets, implicit constraints and competing worker paths; certify manifests and execute concurrency evidence | Engineering + Security + PO; Operations/Institution where applicable | G3/G4/G5/G7/G9 |
| X-18 | Critical | CMD-001–054 | Review LOCK-PROTOCOL-DECISION-RESOLUTION-001; obtain PO/domain policy decisions, Engineering/Security approval of the effective lock graph, reconcile all command manifests and retain adversarial concurrency evidence | PO/domain owner; Engineering + Security; Operations/Institution where applicable | G3/G4/G5/G7/G9 |

## 7. Gate disposition

| Gate | Disposition | Reason |
|---|---|---|
| G0 | PARTIAL / OPEN | Repository governance documented; live ruleset/required-check verification outstanding |
| G1 | NOT READY | Source/institutional authority and T-10/T-12 dependencies remain |
| G2 | NOT READY | Role, state, SoD and several workflow decisions remain open |
| G3 | NOT READY | Physical schema, concurrency token, lock order and lifecycle gaps remain |
| G4 | NOT READY | Permission/RLS/function ACL, privacy and institutional approvals remain |
| G5 | NOT READY | Exact routes, request/response schemas, function signatures and provider callback mapping remain |
| G6 | NOT READY | UX/accessibility/offline compatibility and notification UX decisions remain |
| G7 | NOT READY | Tests planned but not executed; traceability and test fixtures remain incomplete |
| G8 | NOT READY | Provider ownership, region, quotas, backup/restore and operational evidence remain |
| G9 | NOT READY | Critical cross-document and authority gaps remain |
| G10 | NOT AUTHORIZED | No separate implementation authorization |

## 8. Required change-control rules

1. Do not mark any finding closed solely because a document now exists.
2. A finding closes only with approved authority, exact updated source documents and reproducible evidence where applicable.
3. Preserve stable CMD IDs. A material contract change requires explicit change control and compatible schema/API versioning.
4. Keep application SemVer, controlled-document SemVer, API contract versions, database migration identifiers and instrument versions separate.
5. Update the canonical command catalogue, permission registry, physical schema, RLS catalogue, audit catalogue, API contracts, RTM, QA and DGA/RAID together when an approved decision changes their semantics.
6. Never infer an approved role grant, route, function, table, index, trigger, worker, provider, or release control from a proposal.
7. Re-read AGENTS.md before every new repository work session and substantive task.
8. No code, SQL, migration, grants/revokes, RLS, live database mutation, provider setup, deployment, CI execution or merge before the required gate and explicit authorization.

## 9. Next work

1. Review this cross-command register with PO, security and institutional authorities; obtain decisions for critical items X-01 through X-10.
2. Reconcile accepted decisions into canonical source documents and the DGA/RTM/RAID with independent document SemVer changes.
3. Execute only authorized read-only platform inventory after the responsible owner grants access; do not infer runtime state from documentation.
4. Reassess G9 only after closure evidence is accepted. G10 remains a separate explicit authorization.

**Final boundary:** This is a documentation reconciliation. It does not close scope, approve executable contracts, authorize implementation or establish production readiness.


## 10. Concurrency/version-token reconciliation update — 2026-11-24

The systemic version-token mismatch has a dedicated decision-ready proposal: [Concurrency and Version Token Reconciliation](CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) v0.1.2.

The proposal maps command request fields to their intended aggregate/token, separates row versions from business versions, inspection revision numbers, content hashes, print sequences and worker lease/fencing tokens, and identifies remaining catalogue-versus-review mismatches for CMD-005, CMD-007, CMD-035 and CMD-040. CMD-050 expected_version has been removed.

Key dispositions:
- Existing physical \`row_version\` fields on \`inspections\` and \`unit_claims\` are retained as design references; their exact initialization/increment semantics still require approval.
- Proposed missing tokens include \`user_roles\`, \`user_scope_grants\`, \`projects\`, \`sessions\`, \`project_capacity_settings\`, \`instruments\`, \`unit_project_associations\` and \`attendance_records\`.
- \`target_plans.version\` and \`instrument_versions.version_number\` are business sequence identifiers, not draft compare-and-swap tokens.
- CMD-050 is proposed to use an idempotent set-once \`read_at\` update rather than adding a version column to every notification.
- CMD-052/053 lease fencing is distinct from user-facing row versioning.
- All proposed fields and API changes remain OPEN pending PO/Security decisions. No physical schema, command catalogue or detailed review is silently amended by this proposal.

**Gate effect:** X-02 remains OPEN; G3/G5/G9 remain NOT READY and G10 remains NOT AUTHORIZED. This update improves traceability but does not close the finding.


## 11. Global lock-order and concurrency graph update — 2026-11-24

A dedicated proposal is recorded in [LOCK-GRAPH-001 — Global Lock-Order and Concurrency Graph Reconciliation](GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) v0.3.2. It reconciles the currently documented lock recipes, records the CMD-026 and CMD-023 ordering conflicts, proposes candidate resource ranks, maps cross-command race intersections, identifies potential deadlock inversions, and specifies per-command lock manifests plus 41 planned concurrency tests.

Key findings:
- The catalogue's current global sequence and the CMD-011–020 expanded sequence do not fully align on instrument/version placement.
- CMD-026's detailed lock recipe conflicts with its catalogue row; CMD-023/024 recipes also need normalization.
- Capacity eligibility, project/session closure, instrument deactivation, association/claim/inspection lifecycle, attendance document verification and worker finalization need complete competing-writer inventories.
- The static review cannot prove the graph acyclic; no runtime deadlock or concurrency test was executed.

**Disposition:** X-16 OPEN; DGA-B18 OPEN. LOCK-GRAPH-001 is a proposal only. The canonical command catalogue, detailed command reviews and physical schema have not been silently changed. G3/G4/G5/G7/G9 remain NOT READY and G10 remains NOT AUTHORIZED.


## 12. Command-level lock manifest inventory — 2026-11-24

[LOCK-MANIFEST-001 — Command-Level Lock Manifest Reconciliation CMD-001–054](COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) v0.3.2 records a source-evidence inventory for every proposed command. Coverage is 54/54 IDs; lock-complete certification is 0/54. This is not a pass result: source order conflicts and incomplete lock targets remain explicit.

The manifest does not change the canonical command catalogue, physical schema or detailed command reviews. It adds X-17 and requires approved global order, per-command lock targets, deterministic multi-row ordering, implicit constraint/trigger review, worker fencing and adversarial test evidence. No test was executed. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT AUTHORIZED.


## 13. Lock protocol decision-resolution proposal — 2026-11-24

[LOCK-PROTOCOL-DECISION-RESOLUTION-001](LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.2.0 consolidates a candidate resource hierarchy and decision-ready recommendations for the 54-command lock protocol. It separates five PO/domain decisions (canonical identity/conflict semantics; claim requirement/exceptions; project/session closure and in-flight work; T-14 eligibility semantics; instrument deactivation effect) from technical approvals reserved to Engineering/Security and institutional/Operations authorities.

**Disposition:** PO decisions LPR-02–LPR-06 are now approved and recorded; X-18 and DGA-B20 remain OPEN because LPR-01 and LPR-07–LPR-10, complete manifests and effective lock-graph evidence remain outstanding. The PO decisions do not approve a global lock order, alter canonical command contracts or prove deadlock freedom. G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED; tests remain planned/not executed.


## 14. Product Owner lock-protocol decision update — 2026-11-24

The Decision Register records PO approval of LPR-02–LPR-06: canonical unit identity `(instrument_type, serial_normalized)` across projects; mandatory active claim for normal inspection; closed project/session mutation/finalization fence with explicit audited reopen; T-14 eligibility using the already approved T-14 predicate and shared serialization point; and instrument deactivation preserving pinned historical versions except for explicit safety withdrawal. These approvals settle product semantics only. LPR-01 and LPR-07–LPR-10, command manifest certification, physical constraints/trigger/function graph and adversarial concurrency evidence remain open. X-18/DGA-B20 are therefore still OPEN; G9 remains NOT READY and G10 NOT AUTHORIZED.


## 15. PO decision traceability synchronization — 2026-11-24

The approved LPR-02–LPR-06 product semantics are now traced into the Decision Register, PRD v0.2.0, Inspection Lifecycle and Claims v0.2.0, Project/Session/Assignment Model v0.2.0, RTM and RAID. The RTM adds UNIT-IDENTITY-001, CLAIM-001, LIFECYCLE-FENCE-001, CAP-002 and INSTRUMENT-DEACTIVATION-001. RAID records D-028 and R-027/R-028 as open technical dependencies/risks. The prior T-16 RAID identity key has been normalized to `(instrument_type, serial_normalized)` to match the controlling Decision Register. These updates establish documentation traceability only; command catalogue, physical schema, RLS, permissions, locks and QA execution remain open. G9 NOT READY; G10 NOT AUTHORIZED.


## CMD-011–020 Product Owner semantic approval synchronization — 2026-11-24

Product semantics for CMD-011–020 are PO APPROVED and recorded in the Decision Register. The detailed review, command catalogue, Project/Session/Assignment Model, physical-schema semantic overlay, RTM and QA traceability now consume those decisions. This does not change this cross-command reconciliation's status: **engineering reconciliation OPEN; no executable command contract approved**.

The approved semantics are not lock approvals. CMD-010–015 project/session parent-fence incompatibility, T-14 capacity serialization, row-version/CAS physicalization, identity/authorization rank gaps, function privilege/ACL evidence, and all 54 command manifests remain technical dependencies. DGA-B14/B17/B18/B19/B21 remain partial/open as recorded; lock certification remains 0/54; G9 NOT READY; G10 NOT AUTHORIZED.


## LPR technical resolution and command-contract overlay — 2026-11-24

The current candidate technical recommendations are consolidated in [TECH-RESOLUTION-LPR-001](ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) v0.1.0. The detailed CMD-001–010 review v0.3.4 and CMD-011–020 review v0.3.6 and PostgreSQL Command Contract Catalogue v0.4.2 now identify the proposed project-before-session fence, L15–L18 identity/authorization ordering and T-14 capacity-first path for CMD-009–016. The CMD decision package v0.2.4 directly preserves T-07's DRAFT/ACTIVE/PAUSED/CLOSED states; CLOSE_REQUESTED is action/event only.

These are candidate specifications, not technical approval. LPR-01/LPR-07/LPR-08/LPR-09/LPR-11 remain OPEN; LPR-10 NOT EXECUTED. The global graph is not proven acyclic, all 54 manifests are not certified, and no physical lock/privilege graph or concurrency evidence exists. G3/G4/G5/G7/G9 remain NOT READY; G10 NOT AUTHORIZED.


## Current lock source baseline — 2026-11-24

Current linked lock sources are LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.6; LOCK-GRAPH-001 v0.4.8; LOCK-MANIFEST-001 v0.4.10; TECH-RESOLUTION-LPR-001 v0.1.0; CMD-011–020 Detailed Contract Review v0.3.6; PostgreSQL Command Contract Catalogue v0.4.2. The proposed L15–L18 and L55 classes and parent-fence modes remain subject to Engineering/Database/Security approval. This document remains OPEN; 0/54 lock-complete certification and G9/G10 statuses are unchanged.


## CMD-001–010 candidate lock-manifest normalization — 2026-11-24

CMD-001–010 Detailed Contract Review v0.3.4 §9, LOCK-MANIFEST-001 v0.4.13, LOCK-GRAPH-001 v0.4.10 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.8 now share one candidate ordering overlay. It covers L00 idempotency; conditional L10 T-14 serialization; sorted L15 principal, L16 role, L17 scope-grant and conditional L18 catalog resources; L30 project/session parents; L50 operational scope targets; and L110 append-only facts. Candidate project fencing uses project FOR SHARE for child writers and FOR NO KEY UPDATE for project update/closure; closure/capacity predicates require fresh post-fence READ COMMITTED snapshots or SERIALIZABLE with retry.

QA Catalogue v0.3.3 aligns TC-CMD-CONTRACT-024-001..010 concurrency assertions. All remain PLANNED / NOT EXECUTED. **10/54 command manifests are candidate-normalized at documentation level; 0/54 are technically approved or lock-complete certified.** LPR-01/LPR-07/LPR-11 remain OPEN; LPR-10 NOT EXECUTED; the graph is not proven acyclic; G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED.


## CMD-045–048 blocked-command synchronization — 2026-11-24

[CMD-045–048 Detailed Contract Review](CMD-045-048-DETAILED-CONTRACT-REVIEW.md) v0.1.0 is the detailed boundary source for the four blocked commands. The canonical catalogue is now v0.4.2 and explicitly links the review; QA Catalogue v0.3.4 adds 12 planned review subcases; RTM RET-001 / INC-001 / PROV-001 / REL-001 and RAID D-031..D-033/R-032..R-033 record the authority, security and operational dependencies.

Disposition remains unchanged:
- CMD-045 BLOCKED_BY_POLICY pending T-10 institutional records/legal/privacy/security approval.
- CMD-046 BLOCKED_BY_SCHEMA_AUTHORITY pending incident-response authority, product-vs-external-system scope and case model.
- CMD-047 BLOCKED_BY_T12 pending provider ownership/custody, region/plan and approved secret-management controls.
- CMD-048 BLOCKED_BY_AUTHORITY pending release operator, CI/ruleset, protected environment, artifact provenance and separation-of-duties evidence.

No route, RPC, table, permission grant, secret-manager resource, CI rule or deployment operation is authorized by this synchronization. The 54-command inventory remains 10/54 candidate-normalized and 0/54 technically approved/certified; all relevant QA cases remain PLANNED / NOT EXECUTED. G9 remains NOT READY and G10 NOT AUTHORIZED.


## CMD-049–054 notification cross-document reconciliation — 2026-11-24

### 1. Canonical source snapshot

| Artifact | Current proposal version | Reconciled concern |
|---|---:|---|
| NLA-001 Notification Lifecycle and Delivery Architecture | 0.1.2 | Domain lifecycle, six tables, worker lease fencing, integration callback and planned tests |
| CMD-049–054 Detailed Contract Review | 0.1.1 | Per-command request, authorization, transaction, idempotency and blocker review |
| PostgreSQL Command Contract Catalogue | 0.4.4 | CMD-001..054 logical request, transaction boundary and candidate-only lock-order wording |
| Physical Database Schema | 0.4.1 | safe_payload, outbox/delivery lease fields, read_at set-once semantics |
| Table-by-Table RLS Catalogue | 0.2.2 | Recipient-self inbox and default-deny worker/configuration tables; dismiss remains inactive |
| API and Transaction Contracts | 0.2.1 | User commands, internal worker boundary and INT-NOTIF-001 |
| Audit Event Catalogue | Current NLA linkage addendum | First-read event, policy publication and escalation event semantics |
| Command-Level Lock Manifest | 0.4.15 | Current LOCK-GRAPH-001 v0.4.10 parent pointer; candidate-only, 0/54 certified |
| Concurrency and Version Token Reconciliation | 0.1.6 | CMD-050 notification_id-only request; CMD-052/053 lease fencing; CMD-054 DB time |
| QA Catalogue | 0.3.5 | TC-NOTIF-001..026 and TC-FN-SEC-025-064..069 |
| RTM / RAID / DGA | RTM-001 v0.1.0; RAID-001 v0.1.0; DGA-001 v1.11.20 | Unique requirement/risk IDs; NOTIF-007..012; D-034..D-036/R-034..R-035; gate blockers |

### 2. Command-to-domain crosswalk

| Command | Domain/data boundary | Authorization / execution | Verification | Disposition |
|---|---|---|---|---|
| CMD-049 list-own-notifications | notifications; stable actor/filter-bound cursor | authenticated recipient self via auth.uid(); scoped read/RLS; no global inbox | TC-NOTIF-005/006/018; TC-FN-SEC-025-064 | Proposal aligned; exact indexes/page cap/live RLS open |
| CMD-050 mark-notification-read | notifications.read_at set-once; no row-version | recipient-self trusted command; direct browser DML denied | TC-NOTIF-005/007/019; TC-FN-SEC-025-065 | expected_version removed at documentation level; audit implementation open |
| CMD-051 publish-notification-policy | notification_policy_versions + audit_events | notification.policy.manage; explicit scope/grantor/SoD not approved | TC-NOTIF-012/020; TC-FN-SEC-025-066 | Publish-only boundary aligned; permission and policy-schema approval open |
| CMD-052 fanout-notification-outbox | notification_outbox → notifications + notification_deliveries | internal workload only; no browser RPC; lease fencing | TC-NOTIF-002/003/011/021/022; TC-FN-SEC-025-067 | Field vocabulary aligned; worker identity and recipient eligibility semantics open |
| CMD-053 dispatch-notification-delivery | notification_deliveries + append-only notification_delivery_attempts | internal delivery worker; provider I/O outside DB transaction | TC-NOTIF-007/009/010/015/016/023/024/026; TC-FN-SEC-025-068 | INT-NOTIF-001 boundary assigned; provider auth/dedup/capability open |
| CMD-054 evaluate-notification-escalation | notification_escalation_events + notification_outbox | internal scheduler; one DB UTC instant; pinned policy | TC-NOTIF-013/014/025; TC-FN-SEC-025-069 | Caller evaluation_time removed; SLA semantics and scheduler ACL open |

### 3. Resolved documentation mismatches

1. CMD-050 no longer accepts expected_version. The physical notifications proposal has no row-version column; read_at is guarded and set once. The first transition emits one notification.read event atomically; duplicate/no-op requests emit no duplicate event.
2. CMD-051 is publish-only. The server computes policy_hash and version_no and compares optional expected_current_version_id. Persisted draft CRUD is excluded; a future draft workflow requires a separate approved command/schema.
3. CMD-052/053 use canonical safe_payload and the same logical lease tuple: lease_owner, lease_token_hash, monotonic lease_generation and lease_expires_at. Partial fan-out remains PROCESSING and resumes through unique arbiters.
4. CMD-053 inbound provider callbacks use INT-NOTIF-001, a separately authenticated integration ingress. It is not a new CMD ID, browser RPC or seventh notification table.
5. CMD-054 accepts no evaluation_time; one database-derived UTC instant is captured per evaluation transaction.
6. dismissed_at remains reserved; no dismiss behavior or browser write is approved.
7. Browser inbox visibility is recipient-self only; no R-admin/global inbox path is proposed. Worker queues, attempts and escalation history are not browser-readable.

### 4. Remaining blockers and owner decisions

| Blocker | Commands | Required owner decision/evidence | DGA / RAID |
|---|---|---|---|
| Recipient event-time vs fan-out-time eligibility and deterministic retry snapshot | 052, 054 | PO + Security approve the exact eligibility checkpoint and snapshot/revalidation semantics | DGA-B13; R-034 |
| notification.policy.manage grant, scope, grantor ceiling, selector grammar and SoD | 051 | PO + Security approval; no role grant is inferred | DGA-B09/B13; D-036 |
| Worker/scheduler principal, scheduler trust, database role, function owner, exact EXECUTE ACL, token custody and rate limits | 052–054 | Security + Operations evidence and exact function review | DGA-B12/B13; D-034 |
| Provider selection, quotas/cost, secret custody, callback signature/freshness and durable event deduplication | 053 / INT-NOTIF-001 | T-12 provider owner + Security approval and capability evidence | DGA-B05/B13; D-035/R-035 |
| Retry horizon, maximum attempts, UNKNOWN reconciliation and operational alert thresholds | 052–053 | PO + Operations approval; values must not be inferred from examples | DGA-B08/B13; R-026/R-035 |
| SLA start event, elapsed vs business time, timezone/DST, paused/closed behavior and expiry | 054 | PO + Security/Operations approval | DGA-B13; NOTIF-010 |
| Classification, purpose, retention, deletion/disposition, legal hold, audit export and network/time-zone metadata | 049–054 | Written institutional T-10 approval | DGA-B04/B13; NOTIF-011 |
| Exact composite FKs, indexes, enums/checks, policy immutability, RLS, function owner and grants | 049–054 | Engineering/Database/Security design review plus later live evidence | DGA-B11/B12 |
| Dismiss/archive UX and behavior | 049/050 | PO/UX decision | DGA-B13 |

### 5. Inventory and gate status

- Logical command inventory: 54/54 IDs present; all six notification commands have a detailed review and a cross-document proposal mapping.
- Candidate lock normalization: remains 10/54. CMD-049–054 transaction fields are clarified but are not counted as normalized or certified manifests.
- Technical command approval/certification: 0/54.
- Physical schema/RLS: 48/48 proposed table-name parity only; no live database/RLS/grant evidence.
- QA: 410 distinct test-case definitions by line-level ID scan; TC-NOTIF-001..026 and all notification function-security cases remain PLANNED / NOT EXECUTED.
- CI, workflow checks, provider setup, database inspection and deployment: not executed in this documentation task.
- G9: NOT READY. G10: NOT AUTHORIZED.

This crosswalk is static documentation evidence only. It does not approve a command, worker, provider, route, function, permission grant, table, policy, migration or production action.


## Final documentation consistency audit — current source snapshot (2026-11-24)

The current source versions in §1 supersede older source-version references in this cross-command document only where those references are presented as current. Earlier checkpoint sections remain dated historical evidence. The canonical command catalogue now explicitly labels the global lock ranks as a candidate proposal, not an approved order. RTM-001 and RAID-001 have unique identifiers after the final audit correction. The local Markdown references in the current cross-command and linked core documents were checked against the repository tree; no missing local targets were found in the reviewed set.
