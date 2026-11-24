# Documentation Gap Audit — Gate Implementation Readiness

**Document ID:** DGA-001  
**Version:** 1.11.7
**Audit date:** 2026-11-24  
**Branch reviewed:** `docs/audit-lock-and-identity-reconciliation`  
**Authority:** Master Implementation Blueprint MIB-001  
**Status:** AUDIT IN PROGRESS — GATE IMPLEMENTATION NOT READY  
**Implementation authorization:** NOT GRANTED

## 1. Executive conclusion

The documentation baseline is substantial, but the repository is **not yet ready to enter implementation**. This audit found unresolved source authority, institutional approvals, design-to-contract gaps, ERD/physical-schema discrepancies, incomplete command-level contracts, unverified operational/provider assumptions, and absent implementation/runtime evidence.

This is not a claim that every possible gap has been found. It is the current evidence-backed gap register from the reviewed documents. A clean document inventory, a large test catalogue, or PO approval of an architectural direction is not equivalent to implementation readiness.

The audit distinguishes:
- **PO decision closed:** Product Owner has selected the product direction.
- **Design closed:** implementable specifications and cross-document mappings are complete and reviewed.
- **Institutional approval closed:** the authorized institutional owner has supplied written authority.
- **Implementation verified:** deployed code/database behavior has passed evidence-backed tests.

These states must not be collapsed.

## 2. Audit method and evidence boundary

Reviewed the current documentation branch's Master Implementation Blueprint, README, T-19 audit, Package S, Package T, Decision Register, RTM, RAID, PRD, command contract catalogue, physical schema, RLS catalogue/reconciliation, QA catalogue, recovery plan, performance baseline and provider governance.

The QA catalogue contains 391 distinct test identifiers by text-level scan. TC-LOAD-001 and TC-NOTIF-001 each appear more than once as a cross-reference plus a test definition; this does not create additional unique cases. Major planned series include 48 original command-contract cases, 40 command-authorization cases, 48 table/RLS cases, 69 function-security cases, 12 T-18 execution-model cases, 10 live-inventory cases, 8 repository-audit cases, 18 notification lifecycle cases and 8 T-13 print-batch cases. They are specifications only unless an execution record explicitly proves otherwise.

No application code, migrations, live Supabase database, deployed RLS/grants, Vercel runtime, production provider account, CI workflow execution, backup restore, load test, security test or UAT was executed by this documentation audit.

## 3. Blocking gaps

| ID | Area | Evidence-backed gap | Required closure evidence | Accountable authority | Status |
|---|---|---|---|---|---|
| DGA-B01 | Instrument authority — IFP | Official controlled IFP source/version, exact checklist/specification wording, applicability and photo-slot rules not evidenced | Controlled source document, provenance, item-by-item reconciliation and authorized approval | PO + institutional instrument owner | BLOCKED |
| DGA-B02 | Standing Bracket instrument | Official SB PDF and 19 visible rows confirmed by PO, but annex/specification completeness, ambiguous source wording and photo-slot mandatory rules remain unresolved | Full source/annex inventory and explicit item/evidence-slot applicability approval | PO + institutional instrument owner | OPEN |
| DGA-B03 | BA and attendance authority | Configurable signatory-block product direction approved; actual authorized signatory identities/titles/template and attendance verification authority remain institution-dependent | Approved BA template and written signatory/attendance authority matrix | Institutional owner | BLOCKED |
| DGA-B04 | Institutional data governance | T-10 approves formal review path only; classification, legal basis/purpose, evidence limits, retention, deletion/disposition, legal hold, audit retention/export and network metadata not approved | Written decisions by authorized records/legal/privacy/security functions | Institution | BLOCKED |
| DGA-B05 | Provider and ownership | T-12 approves alternative ownership path only; actual legal/account owner, billing owner, custodians, region, plans, quotas, budget and recovery entitlements unverified | Signed ownership/RACI, current provider account evidence, quota/cost sheet, region approval | Sponsor + institution | BLOCKED |
| DGA-B06 | Recovery and backup | Proposed RPO/RTO and cadence are not provider capability evidence; database and object restore not demonstrated | Isolated PostgreSQL and Storage restore drills with checksums, measured RPO/RTO and sign-off | Operations owner | NOT EXECUTED |
| DGA-B07 | Device/offline security | T-09/T-11 product direction approved; exact device/OS/browser build matrix, local protection, cache/purge, shared-device logout, device loss and offline recovery remain incomplete | Approved compatibility matrix, local threat model, retention/purge rules and tested recovery cases | PO + security/institution | OPEN |
| DGA-B08 | Performance SLO | 100 concurrent users is a test target, not proven capacity; numeric latency/error/availability/upload SLOs and representative media profile not approved/measured | Approved workload/SLO sheet and staging load-test report | PO + engineering + provider owner | OPEN |
| DGA-B09 | Canonical permission registry | Registry is a draft; exact role-to-permission grants, grant/revoke authority, SoD, legacy-code disposition and command permission assignments not approved end-to-end | Approved canonical registry, complete role/grantor matrix and legacy mapping | PO + security authority | OPEN |
| DGA-B10 | Command contracts | CMD-001..054 remain draft; CMD-049..054 extend the original 48 with NLA-001 notification operations. None are approved/executable end-to-end contracts; exact schemas, routes, function signatures, physical read/write sets, permission predicates, locks/idempotency retention, grants and typed errors remain incomplete | Review 54 proposed contracts or explicit scoped exclusion/deferment; exact route/RPC/schema/permission/test traceability | Engineering + security + PO | OPEN |
| DGA-B11 | Database/RLS/ERD | Static documentation inventory is now proposed at 48/48: T-13 `print_batches` retained; ambiguous `notification_events` replaced by six NLA-001 tables. Exact composite constraints, grants, RLS predicates, views, functions, triggers, sequences and Storage policies remain unverified | Independent technical review of 48-table crosswalk, all constraints/privileges/RLS and live inventory before implementation | Engineering + security | DESIGN RECONCILED; LIVE VERIFICATION OPEN |
| DGA-B12 | T-18 execution model | Option A is PO-approved, but function-by-function owner, effective privileges, search_path, exact EXECUTE ACL, JWT forwarding and real route-to-PostgREST path have no runtime evidence | Per-function security review, live inventory, route design, end-to-end caller-JWT negative/positive test | Engineering + security | NOT VERIFIED |
| DGA-B13 | Audit/INS-015 notifications | NLA-001 now specifies outbox, recipient inbox, channel delivery, append-only attempts, immutable policy versions and escalation history. Worker identity/ACL, role grants, exact recipient selector semantics, provider capability and T-10 retention/privacy remain open | PO/security review of NLA-001; worker security approval; provider evidence; institutional T-10 policy; cross-document and test review | PO + engineering + institution | DESIGN PROPOSAL RECORDED; APPROVALS OPEN |
| DGA-B14 | Reports/project closure | T-05/T-06 metrics, BA/serial annex and closure graph remain open. T-13 print batch persistence is mapped to `print_batches` + append-only per-document `print_events`; eight dedicated print-batch cases are now specified, but projection, retry and concurrency tests remain unexecuted. CMD-010 project closure also lacks a proven parent-fence protocol against CMD-011–015 child writers | Metric definitions, closure gates, project/session parent-fence lock modes and child-writer order, print schema/command review and execution evidence | PO + engineering + security | PARTIAL; PRINT DESIGN SPECIFIED, CLOSURE FENCE OPEN |
| DGA-B15 | CI/repository governance | Required CI jobs, branch protection, review requirements, secrets scanning, migration checks and actual workflow run were not verified | Live GitHub ruleset/workflow evidence and successful required-check run | Repository administrator | NOT VERIFIED |
| DGA-B16 | Scope/authority document freshness | Package T status was reconciled; Package S now has a current 9.15 addendum superseding historical 9.14 counts; RTM/RAID and remaining historical audit status still require crosswalk review | Controlled status addenda and reconciled decision/requirement/RAID crosswalk | Document owner + PO | PARTIAL; REMAINING CROSSWALK OPEN |
| DGA-B17 | Concurrency/version token contract | `expected_version`, `expected_row_version`, business version, revision, hash, print sequence and worker lease semantics are not consistently mapped to physical aggregates; CMD-005/007/035/040/050 have field/target mismatches | PO/Security decisions on [Concurrency and Version Token Reconciliation](../02-architecture/CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md), followed by synchronized schema/catalogue/review/QA updates | PO + engineering + security; institution for attendance authority | OPEN — PROPOSAL DOCUMENTED, DECISIONS PENDING |
| DGA-B18 | Global lock order and concurrency graph | PO product semantics LPR-02–LPR-06 are approved; candidate ranks are cross-document aligned, but mutable identity/authorization resources remain unclassified, CMD-010–015 parent-fence lock modes/order are contradictory or incomplete, and command paths, implicit database edges and effective graph remain technically unapproved/unverified | Resolve LPR-01, LPR-07–LPR-11 in [LOCK-PROTOCOL-DECISION-RESOLUTION-001](../02-architecture/LOCK-PROTOCOL-DECISION-RESOLUTION.md), resolve identity ranks and the project/session parent-fence conflict, normalize all command/worker manifests, then provide acyclic-graph and adversarial concurrency evidence | Engineering + Security + PO; Operations/Institution where applicable | PARTIAL — PO DECISIONS RECORDED; TECHNICAL GRAPH OPEN |
| DGA-B19 | Command-level lock manifest coverage | 54 command IDs are inventoried; CMD-001–010 now have a row-level resource overlay but remain rank-unresolved where identity/authorization classes are missing; CMD-011–048 retain legacy labels pending per-command normalization; CMD-049–054 have explicit transaction boundaries; CMD-010–015 parent-fence review identifies a FOR KEY SHARE / FOR NO KEY UPDATE compatibility gap and session-first paths. Physical lock targets, deterministic order, implicit constraints and certification remain incomplete | Review [LOCK-MANIFEST-001](../02-architecture/COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md), resolve LM-01–LM-10, LPR-11 and project/session parent-fence conflicts, normalize all 54 rows only after technical approval, then execute adversarial concurrency evidence | Engineering + Security + PO; Operations/Institution where applicable | OPEN — 54/54 INVENTORIED, 0/54 NORMALIZED/CERTIFIED |
| DGA-B20 | Global lock protocol decision resolution | PO product decisions LPR-02–LPR-06 are recorded; candidate rank order, technical approvals and complete effective lock graph remain unaccepted | Review [LOCK-PROTOCOL-DECISION-RESOLUTION-001](../02-architecture/LOCK-PROTOCOL-DECISION-RESOLUTION.md); resolve LPR-01 and LPR-07–LPR-11, reconcile all command manifests and validate the effective graph | PO/domain owner; Engineering + Security; Operations/Institution where applicable | PARTIAL — PO DECISIONS RECORDED; TECHNICAL/GRAPH CLOSURE OPEN |
| DGA-B21 | Identity and authorization aggregate lock classes | app_users, user_roles and user_scope_grants are mutable resources used by CMD-001–007 but are absent from the L00–L110 candidate resource taxonomy; their order relative to T-14 capacity, project/session parents, grantor authority and assignment membership is undefined | Resolve LPR-11 with Engineering/Security; define exact resource class(es), deterministic same-rank order, authorization freshness/revocation fencing and cross-command competing paths; update graph, manifest, schema and tests | Engineering + Security; PO/institution where lifecycle authority applies | OPEN — CMD-001–007 NOT RANK-NORMALIZED |

## 4. High-risk design quality gaps

These items may be closable through documentation work but remain implementation blockers until complete:

1. **Command completeness:** CMD-045..048 are intentionally blocked pending institutional/operational authority and missing schemas; CMD-001..044 also require detailed review. A one-row command matrix is not a full API/database contract.
2. **Notification approval and verification:** NLA-001 v0.1.1 now proposes recipient, priority, channel, quiet-hour, reminder, SLA/escalation, retry, delivery/read, outbox, policy versioning, audit and worker lifecycle. Remaining blockers are PO/security approval, exact recipient-selector/role authority, worker identity/ACL, provider capability and T-10 retention/privacy; `notification_events` has been removed as an ambiguous placeholder.
3. **Print batch technical review:** T-13 requires durable batch identity and per-document outcomes; `print_batches` and batch-linked append-only `print_events` are now specified. Review aggregate projection, retry, lock/idempotency and failure/concurrency tests; do not treat the design as implementation evidence.
4. **Permission authority:** distinguish role assignment, permission grant, scope grant, grantor ceiling, emergency access, break-glass and revocation freshness. A Super Admin label is not a substitute for a specific permission.
5. **Evidence lifecycle:** specify upload-intent reservation, object verification, orphan cleanup, immutable original, replacement, malware/content validation if required, signed URL lifetime, export audit and retention/disposition.
6. **Transaction boundaries:** specify which commands are one atomic transaction, which external operations use outbox/saga/compensation, and how partial outcomes are reconciled. In particular upload confirmation, PDF generation, batch print and offline sync cannot be described as one database transaction across external services.
7. **Offline conflict model:** define operation ordering, partial batch application, per-operation outcomes, version vectors/row versions, device binding/revocation, retry horizon and local copy destruction.
8. **Report reproducibility:** pin report time zone, as-of timestamp, filter semantics, revision selection, void/reopen treatment, target-plan version and PDF/template version.
9. **Account lifecycle and recovery:** define Google OAuth edge cases, account linking, duplicate identity, lost access, admin lockout, last-admin protection, role expiry/revocation and session invalidation.
10. **Operational SLOs:** define service availability and recovery objectives only after provider capability and institutional service hours are known; distinguish provider SLA from application SLO.

## 5. Decision-state reconciliation rules

The following Product Owner directions are closed at PO level and must not be re-opened as undecided product choices unless formally superseded: T-05 through T-18 as recorded in the Decision Register, including T-15 INS-016, T-16 canonical identity, T-17 instrument publication and T-18 Option A. Their design, institutional and verification dependencies remain open as stated above.

T-01 remains partially closed: Standing Bracket official source is confirmed; IFP source and remaining source/evidence-slot reconciliation are open. T-02 is PO-approved for configurable BA signatory blocks; actual institutional signatory authority remains open. T-09/T-10/T-11/T-12 product directions do not close their respective institutional, device, provider or operational dependencies.

Package T's document-level status must be updated from “Draft for Product Owner review” to “Historical decision pack — PO outcomes recorded; current authority is Decision Register + dated addenda.” Do not rewrite history or imply every dependency is approved.

## 6. Gate disposition

| Gate | Current status | Reason |
|---|---|---|
| G0 Governance/repository intent | PARTIAL | Repository purpose clarified; document freshness/crosswalk still open |
| G1 Product closure | BLOCKED | IFP source, SB evidence rules, institutional BA authority |
| G2 Workflow closure | PARTIAL/BLOCKED | PO decisions recorded; edge cases and exact transitions/authority need reconciliation |
| G3 Data/transaction closure | BLOCKED | ERD-only entities, concurrency token columns/increment semantics, unresolved global lock graph, lock-order conflicts, constraints and external transaction patterns |
| G4 Security/privacy closure | BLOCKED | Permission matrix, live ACL/RLS, T-10 institutional approvals |
| G5 API/integration closure | BLOCKED | 54 proposed operations have detailed reviews; exact approved schemas/routes/RPCs, consistent expected_row_version targets, permission mapping and runtime evidence remain open |
| G6 UX/accessibility closure | PARTIAL | Responsive and offline/device acceptance evidence incomplete |
| G7 QA strategy closure | PARTIAL | Test design extensive; traceability gaps and all relevant execution evidence pending |
| G8 Production operations closure | BLOCKED | Provider, ownership, region, quotas, SLO, restore and incident owners unverified |
| G9 Final SSOT/scope freeze | NOT READY | Upstream blockers and document freshness remain |
| G10 Implementation authorization | NOT AUTHORIZED | Separate explicit authorization required after G9 |
| G11 Build/verification | NOT STARTED | No application implementation |
| G12 Production release | NOT STARTED | No deployment/UAT/restore/load/security evidence |

## 7. Next closure sequence

1. Reconcile historical status language in Package T, Package S, Decision Register, RTM and RAID without changing approved decision meaning.
2. Close instrument source/evidence-slot and BA/template authority evidence.
3. Obtain PO/security review of NLA-001, close worker/provider/T-10 dependencies, and technically review the six notification tables plus T-13 `print_batches`/`print_events` transaction and RLS contracts.
4. Complete the cross-command reconciliation of all 54 detailed command reviews; resolve physical/version/lock/audit/permission mismatches, then approve exact request/response schemas, route/RPC mapping and command-specific tests.
5. Complete canonical permission/role/grantor/SoD matrix and exact object privilege/RLS/Storage matrix.
6. Complete offline/device, report reproducibility, evidence lifecycle, account recovery and operational SLO specifications.
7. Obtain institutional T-10/T-12 decisions and current provider capability evidence.
8. Perform final requirement-to-design-to-test traceability and independent cross-document consistency review.
9. Only after blockers are closed, request scope-freeze approval; then request separate implementation authorization.

## 8. Final disposition

**Documentation inventory:** SUBSTANTIAL  
**Documentation closure:** INCOMPLETE  
**Implementation readiness:** NOT READY  
**Scope freeze:** NOT READY  
**Implementation authorization:** NOT GRANTED  
**Production readiness:** NOT VERIFIED

No source code, migration, SQL, grants, live database mutation, deployment, security test, load test, restore drill or UAT is authorized or claimed by this audit.

---

## NLA-001 / T-13 closure evidence update — 2026-11-24

- NLA-001 v0.1.1 records the INS-015 lifecycle, proposed six-table persistence model, recipient and channel rules, retry/UNKNOWN semantics, audit/privacy boundary, worker contract, CMD-049..054 and TC-NOTIF-001..018.
- T-13 is reconciled by adding `print_batches` to physical schema/RLS and linking per-document attempt outcomes in `print_events`.
- Proposed physical/RLS inventory: 48 tables each; static document parity only.
- DGA-B10, B11, B13 and B14 remain open/partial. No PO/security sign-off, live database inspection, migration, grant, provider setup or test execution is claimed.


## CMD-001..054 detailed review and cross-command reconciliation update — 2026-11-24

The detailed command review coverage is now documented across seven controlled engineering review files:

- CMD-001–010 — [Detailed Contract Review](../02-architecture/CMD-001-010-DETAILED-CONTRACT-REVIEW.md)
- CMD-011–020 — [Detailed Contract Review](../02-architecture/CMD-011-020-DETAILED-CONTRACT-REVIEW.md)
- CMD-021–030 — [Detailed Contract Review](../02-architecture/CMD-021-030-DETAILED-CONTRACT-REVIEW.md)
- CMD-031–040 — [Detailed Contract Review](../02-architecture/CMD-031-040-DETAILED-CONTRACT-REVIEW.md)
- CMD-041–044 — [Detailed Contract Review](../02-architecture/CMD-041-044-DETAILED-CONTRACT-REVIEW.md)
- CMD-045–048 — [Detailed Contract Review](../02-architecture/CMD-045-048-DETAILED-CONTRACT-REVIEW.md)
- CMD-049–054 — [Detailed Contract Review](../02-architecture/CMD-049-054-DETAILED-CONTRACT-REVIEW.md)

The cross-command synthesis is recorded in [CMD-001–054 Cross-Command Reconciliation](../02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md).

**Important status distinction:** detailed review coverage is complete as documentation, but the command contracts are not approved or executable. The Command Authorization Verification Matrix still reports zero approved/executable command-specific contracts. The 48/48 physical-schema/RLS count remains static table-name parity only.

### Current command and crosswalk disposition

| Item | Updated evidence | Current status |
|---|---|---|
| DGA-B10 — command completeness | 54 logical command/read/worker operations reviewed in seven detailed documents; consolidated cross-command register created | OPEN — approvals and exact traceability remain |
| DGA-B11 — database/RLS/ERD | 48/48 proposed table-name parity crosswalk | DESIGN RECONCILED; LIVE VERIFICATION OPEN |
| DGA-B12 — T-18 execution | Option A PO-approved; per-function owner, security mode, search_path, exact EXECUTE ACL and caller-JWT proof absent | NOT VERIFIED |
| DGA-B13 — notification lifecycle | CMD-049–054 review and NLA-001 crosswalk recorded | DESIGN PROPOSAL RECORDED; PO/SECURITY/WORKER/PROVIDER/T-10 APPROVALS OPEN |
| DGA-B04 — institutional data governance | T-10 formal review path only | BLOCKED pending written institutional decisions |
| DGA-B05 — provider ownership | T-12 alternative ownership direction only | BLOCKED pending signed ownership/RACI and provider evidence |

### Consolidated high-priority unresolved findings

- Physical concurrency tokens are absent for multiple commands that propose expected_version; each needs an approved physical token and compare-and-swap rule.
- CMD-026 local lock order conflicts with the global lock hierarchy; the cross-command lock graph must be reconciled before implementation.
- Several command families still lack explicit physical entities or lifecycle models, including account requests, reviewer assignment, draft revision context, sync operation conflicts, evidence upload intent, document generation/versioning, attendance verification history, retention/legal hold and security cases.
- Canonical permission semantics, role/grantor matrix, SoD and worker authority remain unapproved.
- Candidate route/RPC/function mappings and exact function ACLs remain unapproved and unverified.
- Audit event names and privacy projections require reconciliation; T-10 remains the institutional blocker for retention, disposition, legal hold and audit export.
- CMD-053 provider callback/webhook ingestion lacks a clearly assigned logical command boundary.
- Provider ownership, plan, region, quota, billing and recovery evidence remain unverified under T-12.
- All test cases remain planned; no runtime, security, concurrency, provider, UAT or operational test execution is claimed.

### Gate disposition

G5 remains BLOCKED. G9 remains NOT READY. G10 remains NOT AUTHORIZED. The completion of detailed documentation reviews does not close DGA-B10, authorize implementation or establish production readiness. Each DGA item may be closed only with accountable-owner acceptance and the required source/approval/runtime evidence.


## Concurrency/version-token proposal update — 2026-11-24

A dedicated decision-ready proposal is now available: [CONCURRENCY-001 — Concurrency and Version Token Reconciliation](../02-architecture/CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) v0.1.2. The complete 54-command crosswalk links it from [CMD-001–054 Cross-Command Reconciliation](../02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md) v0.8.2.

The proposal maps:
- missing aggregate tokens for role/scope grants, projects, sessions, capacity settings, instruments, associations and attendance records;
- existing \`inspections.row_version\` and \`unit_claims.row_version\` semantics;
- target-plan/instrument business versions versus mutable-draft concurrency;
- CMD-005/007/035/040/050 field and target mismatches;
- immutable revision/hash, print sequence and worker lease/fencing domains.

**Disposition:** DGA-B17 OPEN. No PO/Security decision has been inferred. G3/G5 remain BLOCKED, G9 remains NOT READY and G10 remains NOT AUTHORIZED. The proposal does not alter the canonical physical schema or command contracts and no tests were executed.


## Global lock/concurrency graph update — 2026-11-24

[LOCK-GRAPH-001 — Global Lock-Order and Concurrency Graph Reconciliation](../02-architecture/GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) v0.3.2 records the cross-command lock-order disagreements and proposes a candidate resource hierarchy, command/race matrix, potential deadlock inversions, lock-manifest requirements and 41 planned concurrency tests, including explicit cross-project canonical-identity collisions, cross-project claim arbitration, T-14 eligibility writers, instrument publish/deactivation, safety withdrawal, parent-fenced async finalizers and immutable notification-policy fan-out.

**Disposition:** DGA-B18 PARTIAL. PO product decisions LPR-02–LPR-06 are recorded; the proposal still does not prove an acyclic graph, resolve the complete CMD-026 and competing-command lock paths, alter canonical command contracts or authorize implementation. G3/G4/G5/G7 remain NOT READY/BLOCKED as recorded above; G9 remains NOT READY and G10 remains NOT AUTHORIZED. No tests or runtime lock inspection were executed.


## Command-level lock manifest update — 2026-11-24

[LOCK-MANIFEST-001](../02-architecture/COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) v0.3.2 inventories all 54 command IDs, with source-stated resource/lock sequence, shared invariant, competing command paths, stated constraints and unresolved decisions. Static inventory coverage is 54/54; lock-complete certification is 0/54. DGA-B19 remains OPEN. This does not imply any command is approved, executable or deadlock-free. G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED; no tests or runtime inspection were performed.


## Lock protocol decision-resolution update — 2026-11-24

[DGA-B20 — Global lock protocol decision resolution](../02-architecture/LOCK-PROTOCOL-DECISION-RESOLUTION.md) v0.2.0 consolidates the candidate hierarchy and resolves source conflicts as recommendations only. PO decisions are separated from Engineering/Security technical approvals and institutional/Operations evidence.

**Disposition:** DGA-B20 PARTIAL — PO decisions LPR-02–LPR-06 are approved. LPR-01 and LPR-07–LPR-11, normalized lock manifests and effective graph evidence remain open. This proposal does not amend canonical command contracts, prove deadlock freedom or authorize implementation. G3/G4/G5/G7/G9 remain NOT READY; G10 NOT AUTHORIZED. No tests or runtime/database inspection were executed.


## Lock protocol PO decision update — 2026-11-24

The Product Owner has approved LPR-02–LPR-06 and the Decision Register records the exact semantics. This partially closes the PO decision portion of DGA-B20 only. LPR-01 and LPR-07–LPR-11, 54-command lock-manifest normalization/certification, live effective lock graph and adversarial concurrency evidence remain open. DGA-B18 and DGA-B19 remain open; G3/G4/G5/G7/G9 remain NOT READY and G10 NOT AUTHORIZED. No tests or runtime/database inspection were executed.


## PO lock protocol decision traceability synchronization — 2026-11-24

LPR-02–LPR-06 are now reflected in PRD v0.2.0, Inspection Lifecycle and Claims v0.2.0, Project/Session/Assignment Model v0.2.0, RTM and RAID. RTM adds five stable requirements (UNIT-IDENTITY-001, CLAIM-001, LIFECYCLE-FENCE-001, CAP-002, INSTRUMENT-DEACTIVATION-001); RAID records D-028 and R-027/R-028 as unresolved technical dependencies/risks. The T-16 identity key mismatch in RAID was corrected to `(instrument_type, serial_normalized)`. This closes only documentation synchronization for the PO decisions. DGA-B18/B19/B20 remain partial/open for technical lock hierarchy, 54 command manifests, physical graph/constraints and concurrency evidence. G9 NOT READY; G10 NOT AUTHORIZED. No tests, CI, SQL, migration, live database inspection or deployment were performed.

## Static cross-document contradiction correction — 2026-11-24

A targeted static consistency pass found two material documentation contradictions and corrected the affected source documents in branch `docs/audit-lock-and-identity-reconciliation`:

1. **T-16 canonical identity:** the Decision Register, RTM and functional design require `(instrument_type, serial_normalized)`, but the physical schema, ERD and command-level references still used `(instrument_id, serial_normalized)`. The physical schema and ERD now define `instruments.instrument_type` as a stable, unique, immutable canonical type key; `units` and `unit_identity_conflicts` reference that key; assignment/catalog configuration continues to use `instrument_id` and trusted commands must prove type equality. Project membership and authorization remain separately scoped. This is a static design reconciliation only; exact relational constraints, normalization policy, indexes and live schema remain subject to Engineering/Security and institutional review.

2. **T-18 execution model:** several command specifications still described SECURITY DEFINER as unapproved or retained the earlier INVOKER/direct-DML compatibility conflict, despite the Decision Register and T18 security review recording PO approval of Option A. The command catalogue, detailed CMD reviews, API/transaction contracts, physical schema, privileged boundary, function-security design and authorization matrix now consistently state: narrow SECURITY DEFINER wrappers for protected writes; SECURITY INVOKER preferred for scoped reads; each function still requires individual owner, effective-privilege, RLS, search_path, exact EXECUTE ACL and caller-JWT path review. No function, grant or migration is approved by this documentation correction.

**Residual status:** these two static contradictions are corrected in the reviewed files, but this is not a complete repository-wide or physical-runtime certification. LOCK-MANIFEST-001 remains 54/54 inventoried and 0/54 lock-complete. LPR-01 and LPR-07–LPR-11 remain open/not executed; DGA-B18/B19/B20 remain partial/open. No live database inventory, SQL, migration, CI, automated test, concurrency test or deployment was executed. G9 remains NOT READY and G10 NOT AUTHORIZED.


## Command lock-manifest source-baseline refresh — 2026-11-24

LOCK-MANIFEST-001 is now v0.3.5. Its §2 source set was refreshed against the current corrective branch after the prior v0.3.2 method paragraph was found to retain historical source labels (including DGA-001 v1.4.0, command catalogue v0.2.0, physical schema v0.2.0 and lock graph v0.1.0). The refreshed baseline records MIB-001 v1.0.1, DGA-001 v1.9.2, IRG-001 v1.0.1, PostgreSQL Command Contract Catalogue v0.3.1, Physical Database Schema v0.3.0, LOCK-GRAPH-001 v0.3.2, CONCURRENCY-001 v0.1.2 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.1.

LOCK-GRAPH-001 was bumped to v0.3.4 solely to synchronize its reference to LOCK-MANIFEST-001 v0.3.4. No candidate lock rank, command contract, physical constraint or PO/security decision was changed.

**Disposition:** DGA-B19 remains OPEN; 54/54 logical command IDs remain inventoried and 0/54 are certified lock-complete. This source-version refresh is not evidence of physical FK/index/trigger/function behavior, effective grants/RLS, acyclic lock graph or passing concurrency tests. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT AUTHORIZED. No SQL, migration, CI, automated test, live database inspection or deployment was performed.

## Candidate lock-rank and notification transaction reconciliation — 2026-11-24

A static cross-document review found that LOCK-GRAPH-001 used a compressed 0–90 rank table while LOCK-PROTOCOL-DECISION-RESOLUTION-001 used the expanded L00–L110 candidate hierarchy. The compressed graph also combined instrument with assignment, claim with inspection, and did not distinguish dependent mutable aggregates from append-only facts. That discrepancy could cause the same rank label to mean different resource classes.

The documentation has now been reconciled as follows:
- LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.2 clarifies L100 dependent mutable aggregates to include notification policy/inbox/delivery projections and L110 append-only facts to include notification escalation/access events. It adds explicit logical mappings for CMD-049–054.
- LOCK-GRAPH-001 v0.3.5 now uses the same L00, L10, L20, L30, L40, L50, L60, L70, L80, L90, L100 and L110 candidate classes.
- LOCK-MANIFEST-001 v0.3.6 marks the old CMD-001–048 rank labels as legacy extraction notation and provides a crosswalk. The L40 and L70 mappings are one-to-many and require per-command resource-level normalization; no mechanical rewrite was made. CMD-049–054 now state resource and transaction boundaries without reusing the legacy labels.

The notification boundary explicitly keeps queue claims in short isolated transactions, commits lease/fencing generation before fan-out/provider I/O, separates recipient read state from delivery state, and leaves provider callback command mapping unresolved. CMD-041–043 remain read/purpose-bound query designs; CMD-044 remains blocked by T-10; CMD-045–048 remain authority/schema/provider/release blocked.

**Disposition:** DGA-B18 remains PARTIAL and DGA-B19 remains OPEN. 54/54 command IDs are inventoried, but 0/54 are normalized and certified lock-complete. LPR-01 and LPR-07–LPR-11 remain open/not executed. No PostgreSQL catalog, trigger/FK/index graph, deployed RLS/ACL, worker principal, CI, test, SQL, migration, live database, deployment or merge was inspected or executed. G3/G4/G5/G7/G9 remain NOT READY; G10 remains NOT AUTHORIZED.

## Lock-rank cross-reference synchronization — 2026-11-24

Following the CMD-049–054 transaction-boundary reconciliation, the controlled-document cross-references were synchronized: LOCK-MANIFEST-001 v0.3.7 now points to LOCK-GRAPH-001 v0.3.6 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.2; LOCK-GRAPH-001 v0.3.6 points to LOCK-MANIFEST-001 v0.3.7. The manifest's source table retains the exact earlier reviewed snapshot identifiers (DGA-001 v1.9.5, LOCK-GRAPH-001 v0.3.4 and protocol resolution v0.2.1) rather than misrepresenting them as the post-edit versions.

**Disposition unchanged:** DGA-B18 PARTIAL; DGA-B19 OPEN; 54/54 inventoried, 0/54 normalized/certified. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No CI, tests, SQL, migrations, live database inspection, deployment or merge occurred.

## Candidate rank summary correction — 2026-11-24

LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.3 now explicitly includes L100 dependent mutable aggregates in its recommended-order summary between L90 inspection and L110 append-only facts. LOCK-GRAPH-001 v0.3.7 and LOCK-MANIFEST-001 v0.3.8 cross-references are synchronized. This removes a summary omission; it does not approve the candidate hierarchy or close any command manifest.

**Disposition unchanged:** DGA-B18 PARTIAL; DGA-B19 OPEN; 54/54 inventoried, 0/54 normalized/certified. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED.

## Final lock artifact parent-version synchronization — 2026-11-24

The final parent/reference chain is synchronized: LOCK-MANIFEST-001 v0.3.9 declares LOCK-GRAPH-001 v0.3.8 as its parent; LOCK-GRAPH-001 v0.3.8 references LOCK-MANIFEST-001 v0.3.9 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.3. The manifest's source snapshot table intentionally retains the older exact versions reviewed at the start of this reconciliation, rather than claiming those snapshots are the latest edited artifacts.

**Disposition unchanged:** DGA-B18 PARTIAL; DGA-B19 OPEN; 54/54 inventoried, 0/54 normalized/certified. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No CI, tests, SQL, migrations, live database inspection, deployment or merge occurred.

## Final parent-chain version correction — 2026-11-24

LOCK-MANIFEST-001 v0.3.10 now declares LOCK-GRAPH-001 v0.3.8 as its parent; LOCK-GRAPH-001 v0.3.9 references LOCK-MANIFEST-001 v0.3.10 and LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.2.3. This is the final synchronized parent/reference chain for this documentation checkpoint.

**Disposition unchanged:** DGA-B18 PARTIAL; DGA-B19 OPEN; 54/54 inventoried, 0/54 normalized/certified. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No CI, tests, SQL, migrations, live database inspection, deployment or merge occurred.

## CMD-001–010 lock normalization checkpoint — 2026-11-24

A row-level resource/lock overlay has been added to LOCK-MANIFEST-001 v0.4.3 and reconciled with CMD-001–010 Detailed Contract Review v0.3.1. The overlay identifies:
- CMD-001 account-request/upsert and unique Auth identity arbitration;
- CMD-002/003 shared target-account transition and terminal-decision race;
- CMD-004/005 T-14 capacity-first eligibility changes and role grant/revoke rows;
- CMD-006/007 scope grant/revocation and authorization freshness;
- CMD-008 unique normalized project-code insert arbitration;
- CMD-009/010 project parent locking, child-writer fencing and closure dependencies.

**New critical finding:** the current L00–L110 candidate hierarchy has no explicit class for mutable app_users, user_roles or user_scope_grants. No rank was invented. LPR-11 and DGA-B21 record the decision and evidence required before CMD-001–007 can be rank-normalized. CMD-009/010 parent-fence completeness, physical row-version fields, and project closure blocker coverage also remain open.

**Disposition:** DGA-B18 remains PARTIAL; DGA-B19 remains OPEN; DGA-B21 is OPEN. 54/54 command IDs are inventoried; 0/54 are certified lock-complete. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 remain NOT READY; G10 NOT AUTHORIZED. No SQL, migration, live database inspection, CI, tests, deployment or merge occurred.

## Controlled-document version synchronization — 2026-11-24

Final versions for this checkpoint: LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.2; LOCK-GRAPH-001 v0.4.3; LOCK-MANIFEST-001 v0.4.5; CMD-001–010 Detailed Contract Review v0.3.2; DGA-001 v1.10.3. The manifest source snapshot table records the exact pre-edit source revisions reviewed at the start of this checkpoint (DGA v1.9.10, graph v0.3.9, protocol v0.2.3, CMD-001–010 review v0.2.0), not the post-edit versions.

**Disposition:** DGA-B18 PARTIAL; DGA-B19 OPEN; DGA-B21 OPEN. 54/54 command IDs inventoried; 0/54 certified lock-complete. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No CI, tests, SQL, migrations, live database inspection, deployment or merge occurred.

## Project/session parent-fence lock compatibility checkpoint — 2026-11-24

The CMD-011–015 detailed review was statically compared with CMD-010 closure:
- CMD-011 proposes project FOR KEY SHARE; CMD-012/013 lock session before resolving/locking project; CMD-014 locks project/session/assignment references after capacity; CMD-015 locks assignment/member/user rows without an explicit project/session parent lock.
- PostgreSQL documents that FOR KEY SHARE is compatible with FOR NO KEY UPDATE, and a non-key UPDATE normally obtains FOR NO KEY UPDATE. Consequently, a plain project status UPDATE is not proven to serialize with CMD-011's proposed FOR KEY SHARE. Exact deployed-major behavior and chosen lock mode must be verified. Reference: PostgreSQL Explicit Locking §13.3.2, https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS.
- CMD-012/013 session-first ordering can invert a project-parent-first close path; CMD-015's parent fence is missing from its stated transaction sequence.

**Disposition:** DGA-B14 remains PARTIAL; DGA-B18 PARTIAL; DGA-B19 OPEN; DGA-B21 OPEN. 54/54 command IDs inventoried; 0/54 certified lock-complete. LPR-01 and LPR-07–LPR-11 remain open/not executed. G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No physical DB inspection, SQL, migration, CI, automated test, concurrency test, deployment or merge occurred.


## CMD-011–020 Product Owner approval synchronization — 2026-11-24

The Product Owner explicitly approved the product-semantic recommendations for CMD-011–020. The Decision Register contains the dated decision record; decision package v0.2.3 records the approved interpretation and response matrix. This closes the PO decision-response dependency for these ten commands only.

The following controlled documents have been reconciled to the approved semantics:
- CMD-011–020 Detailed Contract Review v0.3.2: product semantics marked PO APPROVED; engineering/security contract findings remain open.
- PostgreSQL Command Contract Catalogue v0.4.0: command rows now reflect approved product behavior and identify unresolved technical fields/order.
- Project/Session/Assignment Model v0.3.0: T-07 lifecycle, session, assignment, membership and target-plan semantics synchronized.
- Physical Database Schema v0.4.0 and Data Model/ERD v0.3.0: semantic implications mapped without inventing DDL, columns or constraints.
- Test Case Catalogue v0.3.0 and RTM: product requirements mapped to TC-CMD-CONTRACT-024-011..020; all cases remain planned/not executed.
- RAID: D-029/R-029 record technical dependencies and cross-document consistency risk.

**Residual technical and institutional dependencies are not closed:** exact project/session parent-fence lock mode and total order; LPR-01 and LPR-07–LPR-11; CMD-012/013/016 row-version/CAS physicalization; CMD-014/015 capacity and active-work behavior; CMD-017 quantity units/ranges and draft concurrency; CMD-018 allowed ASCII alphabet/collation; CMD-019 schema bounds, stable child identity, canonical hash and CAS; CMD-020 function owner/ACL/hash/atomic publication evidence; T-10 retention/records/privacy and any operational authority decisions.

**Gate disposition:** DGA-B14 remains PARTIAL; DGA-B17 remains OPEN for technical version-token reconciliation; DGA-B18 remains PARTIAL; DGA-B19 remains OPEN; DGA-B21 remains OPEN. Lock certification remains 0/54. All referenced command tests remain PLANNED / NOT EXECUTED. G3/G4/G5/G7/G9 remain NOT READY; G10 NOT AUTHORIZED. No source code, SQL, migrations, grants, CI, automated/concurrency tests, live database inspection, deployment or merge were performed.



## CMD-011–020 downstream security and concurrency traceability — 2026-11-24

Additional downstream synchronization completed:
- Canonical Permission Registry v0.2.1 clarifies that PO-approved actor/action semantics do not approve role mappings, grants, RLS or EXECUTE ACLs; Korlap cannot final-close or reopen a session.
- Command Authorization Verification Matrix v0.4.1 records the same T-07 transition boundary while retaining security review requirements.
- CMD-001–054 Cross-Command Reconciliation v0.8.3 records that CMD-011–020 product decisions are approved but the engineering command contract remains open.
- Concurrency and Version Token Reconciliation v0.1.3 records CMD-017's approved session-scoped product semantics while preserving unresolved physical session binding and draft CAS.

These changes do not alter any technical lock recommendation or certify a command. DGA-B14 PARTIAL, DGA-B17 OPEN, DGA-B18 PARTIAL, DGA-B19 OPEN and DGA-B21 OPEN remain unchanged; 0/54 lock-complete; G9 NOT READY; G10 NOT AUTHORIZED.


## Engineering/Security technical resolution proposal — 2026-11-24

[TECH-RESOLUTION-LPR-001](../02-architecture/ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) v0.1.0 now defines proposed resolutions for LPR-01 and LPR-07–LPR-11, including identity/authorization rank classes, compatible project/session parent-fence modes, T-14 serialization participation, worker fencing/callback boundaries, 54-command manifest normalization criteria and an adversarial concurrency plan. This is a review package, not technical approval or evidence. LPR-01/LPR-07/LPR-08/LPR-09/LPR-11 remain OPEN; LPR-10 remains NOT EXECUTED. DGA-B14 PARTIAL, DGA-B17 OPEN, DGA-B18 PARTIAL, DGA-B19 OPEN and DGA-B21 OPEN remain unchanged; 54/54 inventoried, 0/54 certified; G9 NOT READY; G10 NOT AUTHORIZED. No SQL, migration, CI, test, live database inspection, deployment or merge occurred.


## LPR technical resolution and T-07 state correction — 2026-11-24

[TECH-RESOLUTION-LPR-001](../02-architecture/ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) v0.1.0 is now cross-referenced by LOCK-PROTOCOL-DECISION-RESOLUTION v0.3.3, GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH v0.4.4 and COMMAND-LEVEL-LOCK-MANIFEST v0.4.6. It provides proposed L15/L16/L17 identity/authorization ranks, conditional L18 authorization-catalog handling, a project-before-session parent-fence recommendation, T-14 writer coverage, worker fencing/callback requirements, 54-manifest normalization schema and LPR-10 test plan. These are review proposals only; LPR-01/LPR-07/LPR-08/LPR-09/LPR-11 remain OPEN and LPR-10 NOT EXECUTED.

The CMD-011–020 decision package is v0.2.2 and explicitly corrects its older candidate state wording to controlling T-07: DRAFT/ACTIVE/PAUSED/CLOSED only; CLOSE_REQUESTED is action/event only. RTM adds LOCK-ORDER-001, AUTH-LOCK-001, PARENT-FENCE-001, WORKER-FENCE-001, LOCK-MANIFEST-001 and CONCURRENCY-TEST-001. RAID adds D-030/R-030/R-031. No technical approval or test evidence is inferred.

**Disposition unchanged:** DGA-B14 PARTIAL; DGA-B17 OPEN; DGA-B18 PARTIAL; DGA-B19 OPEN; DGA-B21 OPEN; 54/54 inventoried, 0/54 certified; G3/G4/G5/G7/G9 NOT READY; G10 NOT AUTHORIZED. No code, SQL, migration, grant, CI, test, live database inspection, deployment or merge occurred.


**T-07 correction verification:** CMD-011–020 decision package v0.2.3 now replaces the stale `PLANNED` and persisted `CLOSE_REQUESTED` proposal rows directly with T-07's `DRAFT/ACTIVE/PAUSED/CLOSED` state set and action/event semantics. This is a documentation correction only; no state-machine implementation or test is claimed.
