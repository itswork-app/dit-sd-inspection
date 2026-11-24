# CMD-001–054 Cross-Command Reconciliation

**Document ID:** CMD-CROSSWALK-001-054  
**Version:** 0.4.0  
**Status:** Engineering reconciliation — OPEN; no executable command contract approved  
**Date:** 2026-11-24  
**Repository phase:** Documentation / SSOT maturation  
**Authority:** AGENTS.md, MIB-001, DGA-001, IRG-001, T-10, T-14–T-18 and the approved Decision Register  
**Controls:** G2–G10; DGA-B04–B19; G9 NOT READY; G10 NOT AUTHORIZED.

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
- PostgreSQL Command Contract Catalogue v0.2.0.
- Canonical Permission Registry and Command Authorization Matrix v0.2.0.
- Command Authorization Verification Matrix.
- Physical Database Schema and Integrity Specification v0.2.0.
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

T-18 does **not** approve every command, function signature, route, role, grant, RLS policy or SECURITY DEFINER exception. The live Supabase inventory and actual Vercel-to-PostgREST caller-JWT path remain unverified.

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
| X-DB-16 | CMD-050 | expected_version is in the command catalogue but notifications schema has no version column | Remove expected_version or approve a physical version model |
| X-DB-17 | CMD-051 | Policy draft lifecycle is not fully represented by the proposed policy_versions table | Define draft identity/edit history/hash canonicalization/publish concurrency |
| X-DB-18 | CMD-052 | NLA/schema/catalogue differ on outbox payload and lease field detail | Reconcile safe_payload versus payload_ref, lease owner/token/expiry, retry/status fields and partial fan-out |
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
- notifications: recipient-self read and command-only self read/dismiss mutation;
- notification_outbox: no browser read; internal worker only;
- notification_deliveries: no browser access; worker-only mutation, restricted operations reader only if approved;
- notification_delivery_attempts: no browser access; append-only sanitized worker history;
- notification_escalation_events: restricted oversight/worker access;
- notification_policy_versions: explicit configuration-scope read and reviewed command-only draft/publish.

Each table requires exact positive/negative RLS tests and SQL privilege review. RLS does not itself grant SQL privileges, and a function EXECUTE grant does not itself authorize the business action.

### 4.4 API, command and transport gaps

- The command catalogue contains logical command IDs and candidate input fields; no final REST path or PostgreSQL signature is approved.
- API-AND-TRANSACTION-CONTRACTS.md defines a common envelope and selected transaction patterns, but does not replace a complete command-by-command request/response schema and exact route/RPC mapping.
- The Command Authorization Verification Matrix reports 54 individual command draft rows but zero approved/executable command-specific contracts.
- Candidate names such as cmd_<name>_v1 remain naming conventions only; actual SQL types, overloads, route methods, response schemas and typed error mappings must be derived from approved physical types and inspected inventory.
- CMD-053 provider callback/webhook ingestion is an identified gap: NLA-001 describes result/webhook recording, but CMD-049–054 do not clearly assign a separate logical callback-ingestion operation or explicitly scope it within CMD-053.
- CMD-054 catalogue input evaluation_time must not become a caller-controlled clock; due-ness must derive from server time and approved SLA semantics.

### 4.5 Audit event and privacy gaps

T-15 / INS-016 direction is PO-approved: append-only audit, critical mutation/audit atomicity, fail-closed behavior on audit failure and least-privilege read/export. It is not a substitute for T-10 institutional approval.

Cross-command audit mismatches and dependencies:
- CMD-022/025 identity-conflict lifecycle requires exact conflict-open/resolved/rejected event keys; the command reviews identify missing or non-final event mapping.
- CMD-040 has VERIFIED/REJECTED outcomes, but attendance.rejected is not clearly enumerated in the audit event catalogue.
- CMD-043 audit access requires a non-recursive access-audit path and field-minimized event projection.
- CMD-044 requires institutional export authority and a complete export request/job/manifest/artifact lifecycle; none is established by the current physical inventory.
- CMD-050 notification.read audit semantics must be reconciled with the privacy and volume implications of recording every inbox read.
- CMD-053 delivery attempts belong in the dedicated append-only attempt table; routine retries should not be duplicated into the general audit stream.
- CMD-053 provider callback audit/event semantics need an explicit integration contract.
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

The systemic version-token mismatch has a dedicated decision-ready proposal: [Concurrency and Version Token Reconciliation](CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) v0.1.0.

The proposal maps command request fields to their intended aggregate/token, separates row versions from business versions, inspection revision numbers, content hashes, print sequences and worker lease/fencing tokens, and identifies catalogue-versus-review mismatches for CMD-005, CMD-007, CMD-035, CMD-040 and CMD-050.

Key dispositions:
- Existing physical \`row_version\` fields on \`inspections\` and \`unit_claims\` are retained as design references; their exact initialization/increment semantics still require approval.
- Proposed missing tokens include \`user_roles\`, \`user_scope_grants\`, \`projects\`, \`sessions\`, \`project_capacity_settings\`, \`instruments\`, \`unit_project_associations\` and \`attendance_records\`.
- \`target_plans.version\` and \`instrument_versions.version_number\` are business sequence identifiers, not draft compare-and-swap tokens.
- CMD-050 is proposed to use an idempotent set-once \`read_at\` update rather than adding a version column to every notification.
- CMD-052/053 lease fencing is distinct from user-facing row versioning.
- All proposed fields and API changes remain OPEN pending PO/Security decisions. No physical schema, command catalogue or detailed review is silently amended by this proposal.

**Gate effect:** X-02 remains OPEN; G3/G5/G9 remain NOT READY and G10 remains NOT AUTHORIZED. This update improves traceability but does not close the finding.


## 11. Global lock-order and concurrency graph update — 2026-11-24

A dedicated proposal is recorded in [LOCK-GRAPH-001 — Global Lock-Order and Concurrency Graph Reconciliation](GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) v0.1.0. It reconciles the currently documented lock recipes, records the CMD-026 and CMD-023 ordering conflicts, proposes candidate resource ranks, maps cross-command race intersections, identifies potential deadlock inversions, and specifies per-command lock manifests plus 30 planned concurrency tests.

Key findings:
- The catalogue's current global sequence and the CMD-011–020 expanded sequence do not fully align on instrument/version placement.
- CMD-026's detailed lock recipe conflicts with its catalogue row; CMD-023/024 recipes also need normalization.
- Capacity eligibility, project/session closure, instrument deactivation, association/claim/inspection lifecycle, attendance document verification and worker finalization need complete competing-writer inventories.
- The static review cannot prove the graph acyclic; no runtime deadlock or concurrency test was executed.

**Disposition:** X-16 OPEN; DGA-B18 OPEN. LOCK-GRAPH-001 is a proposal only. The canonical command catalogue, detailed command reviews and physical schema have not been silently changed. G3/G4/G5/G7/G9 remain NOT READY and G10 remains NOT AUTHORIZED.


## 12. Command-level lock manifest inventory — 2026-11-24

[LOCK-MANIFEST-001 — Command-Level Lock Manifest Reconciliation CMD-001–054](COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) v0.1.0 records a source-evidence inventory for every proposed command. Coverage is 54/54 IDs; lock-complete certification is 0/54. This is not a pass result: source order conflicts and incomplete lock targets remain explicit.

The manifest does not change the canonical command catalogue, physical schema or detailed command reviews. It adds X-17 and requires approved global order, per-command lock targets, deterministic multi-row ordering, implicit constraint/trigger review, worker fencing and adversarial test evidence. No test was executed. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT AUTHORIZED.
