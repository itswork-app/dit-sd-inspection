# Master Implementation Blueprint — Dit. SD Inspection

**Document ID:** MIB-001  
**Status:** CONTROLLED BASELINE — STAGED FOUNDATION IMPLEMENTATION  
**Version:** 1.0.19  
**Last reviewed:** 2026-11-27  
**Repository:** `itswork-app/dit-sd-inspection`  
**Product Owner authorization:** CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED (2026-11-24)
**G10-F1 foundation implementation activation:** ACTIVE (2026-11-25, after PR #26); full-system G10 remains staged and feature-gated  
**Scope-freeze status:** G9-F1 FOUNDATION SCOPE FROZEN; full-system G9 NOT READY

**Current gate interpretation (2026-11-25):** Historical sections below that record G9 NOT READY/G10 NOT ACTIVE predate the staged G9-F1/G10-F1 decision. The controlling state is G9-F1 FOUNDATION SCOPE FROZEN and G10-F1 FOUNDATION IMPLEMENTATION ACTIVE. Full-system G9 remains NOT READY; later business features and production operations remain gated.

## 1. Purpose and authority

This document is the navigation and control plane for the project's implementation-ready specification. It does not replace the approved PRD, Decision Register, ADRs, detailed domain specifications, security contracts, or test catalogue. It identifies their authority, dependencies, required evidence, and release gates.

The repository contains authoritative documentation and is authorized to receive bounded G9-F1/G10-F1 foundation implementation. The staged authorization permits foundation source code on a dedicated branch using synthetic data; it does not authorize unresolved business mutations, production data or deployment.

### 1.1 Source-of-truth precedence

When documents conflict, do not silently choose a convenient interpretation. Record the conflict and resolve it through change control. Apply this precedence:

1. Explicitly approved Product Owner (PO) decisions in the Decision Register and linked decision records govern product behavior within PO authority.
2. Formal institutional approvals govern matters reserved to institutional legal, records, privacy, security, finance, or operational authorities. PO approval cannot substitute for them.
3. Approved PRD, acceptance criteria, and controlled source instruments govern product scope and authoritative inspection content.
4. Approved ADRs govern technical choices. Detailed architecture/security specifications must conform to those ADRs.
5. Domain workflows, data contracts, API contracts, UX specifications, and operational runbooks define implementable behavior within the higher-level decisions.
6. QA catalogue and traceability matrix define required verification and evidence; they cannot silently redefine product behavior.
7. Drafts, proposals, examples, screenshots, transcriptions, and unapproved assumptions are non-authoritative.

If two documents at the same authority level conflict, implementation is blocked for the affected requirement until a decision is recorded and all dependent documents are reconciled.

## 2. Product and platform baseline

- Product: replacement application for the Dit. SD inspection workflow; not a SaaS product.
- Release target: production.
- Delivery strategy: feature parity first, controlled improvements second.
- Initial instrument families: Interactive Flat Panel (IFP) and Standing Bracket, with supported declarative instrument configuration for future types.
- Platform: Vercel application hosting; Supabase Auth, PostgreSQL, RLS and private Storage; GitHub source control and CI.
- PostgreSQL is the single source of truth for application data.
- Architecture: modular monolith unless measured evidence justifies another topology.
- Engineering priority: cost-first lifecycle optimization without waiving security, privacy, integrity, backup, recovery, or reliability.
- Repository: this repository is intended to hold both documentation and implementation. Documentation remains authoritative; G10-F1 also authorizes only the bounded foundation source-code and development-configuration work defined in AGENTS.md §3.2, using synthetic/test data on a dedicated branch. Later business-feature implementation and production operations remain gated.

## 3. Non-negotiable engineering invariants

1. Authorization is enforced server-side and in PostgreSQL; UI visibility is never authorization.
2. Tenant, project, location, session, assignment, instrument and resource scope must be checked at the authoritative boundary.
3. No client-supplied actor, role, permission, or scope is trusted.
4. Protected browser-side direct DML is prohibited where the approved command boundary requires server-mediated commands.
5. Supabase caller identity must be preserved through the approved server-to-PostgREST path; service-role credentials must never substitute for the caller.
6. Protected writes use the approved T-18 hybrid command model: individually reviewed SECURITY DEFINER wrappers for protected writes; scoped read-only paths use SECURITY INVOKER/RLS where feasible.
7. Privileged functions use least-privileged ownership, empty search_path, schema-qualified references, exact-signature EXECUTE grants, and reviewed effective privileges.
8. Critical mutation, canonical event, audit evidence and idempotency outcome are atomic; audit failure fails closed.
9. Submitted inspection revisions and original evidence are immutable; correction creates a new revision.
10. Instrument versions and active session snapshots are immutable historical references.
11. Offline sync is bounded, idempotent and conflict-aware; unresolved conflicts block final submission.
12. Evidence storage is private; access is authorized, time-limited, and audited.
13. Actual events and target allocations remain separate facts.
14. Physical printing is not inferred from PDF generation, opening or download; print actions are explicitly recorded.
15. No secrets, service-role keys, database URLs, access tokens or sensitive evidence are committed or pasted into chat.

## 4. Delivery lifecycle and exit gates

A phase is complete only when its exit evidence is recorded and reviewed. A document being present is not evidence that its requirement is approved, implemented, or tested.

| Gate | Workstream | Required exit evidence | Current disposition |
|---|---|---|---|
| G0 | Repository and governance baseline | Repository intent, branch policy, document authority, change control | Repository intent clarified; governance reconciliation in progress |
| G1 | Product closure | Complete requirements, authoritative instrument sources, PO decisions, institutional dependencies | NOT READY |
| G2 | Domain and workflow closure | Actors, permissions, states, transitions, exceptions, invariants, sequence flows | NOT READY |
| G3 | Data and transaction closure | ERD, physical constraints, canonical identity, FK strategy, transaction and idempotency contracts | NOT READY |
| G4 | Security and privacy closure | Threat model, permission registry, table/RPC/storage ACL matrix, RLS, audit, privacy and retention approvals | NOT READY |
| G5 | API and integration closure | Endpoint/RPC contracts, schemas, error model, auth propagation, provider boundaries | NOT READY |
| G6 | UX and accessibility closure | Role journeys, responsive states, offline/error/recovery states, accessibility acceptance | NOT READY |
| G7 | Quality strategy closure | Full RTM, acceptance criteria, test cases, risk-based coverage and test data strategy | NOT READY |
| G8 | Production operations closure | Environments, ownership, region, quotas, backups, restore, monitoring, incident response, cost envelope | NOT READY |
| G9 | Final SSOT and scope-freeze review | Cross-document consistency, no unresolved critical ambiguity, signed scope freeze | Full-system NOT READY; G9-F1 foundation scope frozen |
| G10 | Implementation authorization | Verified scope freeze and explicit activation record for the applicable implementation stage | G10-F1 foundation ACTIVE; later business-feature stages remain gated |
| G11 | Build and verification | CI evidence, functional/security/performance/accessibility/recovery test results | NOT STARTED |
| G12 | Production release approval | Deployment, restore/rollback proof, operational ownership, UAT and go-live acceptance | NOT STARTED |

No gate is passed by inference. G9 cannot pass while any blocker affecting scope, authority, safety, data integrity, or production operation remains unresolved. G10 is a separate explicit authorization and is not implied by G9.

## 5. Required documentation workstreams

### 5.1 Product, authority and source instruments
- Freeze the complete requirement catalogue and acceptance criteria.
- Preserve authoritative IFP and Standing Bracket source documents and exact source wording.
- Reconcile checklist rows, applicability, mandatory/conditional/N/A behavior, evidence/photo slots, model variants and annexes.
- Distinguish PO decisions from institutional approvals and evidence still to be obtained.
- Close BA signatory authority/template, attendance authority, report and closure semantics.

### 5.2 Identity, authorization and operational workflows
- Complete canonical role/permission registry and deny-by-default matrix.
- Define account approval, role assignment, project membership, location/session scope, official team assignment and per-unit claim as distinct concepts.
- Specify all state machines, command preconditions, postconditions, invalid transitions, concurrency behavior and audit events.
- Close session pause/resume/close/reopen, attendance, claims, review/resubmission, approval, document and print workflows.

### 5.3 Data, command and integration architecture
- Reconcile conceptual/logical/physical ERD and every table, view, function, enum and object lifecycle.
- Complete canonical unit identity, project association, serial normalization and exception review contracts.
- Specify every protected command individually: actor source, authorization predicates, scope, state preconditions, input validation, idempotency key, transaction writes, emitted events, audit payload, error codes and concurrency controls.
- Map every API route to a command/query and exact authorization boundary.
- Define Supabase Auth/session handling, caller JWT forwarding, Storage access and provider failure behavior.

### 5.4 Security, privacy and institutional governance
- Complete threat model, abuse cases, trust boundaries and security acceptance criteria.
- Reconcile every database object with exact grants, RLS policy, function owner and EXECUTE ACL.
- Review SECURITY DEFINER effective privileges, ownership, membership, search_path, dynamic SQL, and RLS interaction.
- Obtain institutional decisions for data classification, legal basis, retention, deletion/disposition, legal hold, audit archive and evidence metadata.
- Define key management, incident response, account recovery, device loss and security monitoring.

### 5.5 Offline, evidence and reliability
- Define supported device/OS/browser matrix and bounded offline capabilities.
- Specify local data protection, cache lifetime, purge, retry horizon, duplicate delivery, conflict resolution and device-loss recovery.
- Define evidence file types, size limits, checksum, upload lifecycle, orphan cleanup, private access and retention.
- Define availability assumptions, latency/error objectives, capacity envelope, backup cadence, RPO/RTO and database plus object-storage restore drills.

### 5.6 Reporting, operations and release
- Define report metrics, timestamp semantics, filters, reconciliation, PDF templates, print audit and final closure.
- Define provider organization/owner, data region, plan/quota, billing, alerting, support contacts and budget.
- Define CI tiers, required checks, branch protection, dependency/security scanning and release promotion.
- Define monitoring, structured logs, alert thresholds, incident severity, rollback, backup restore, disaster recovery and operational runbooks.

## 6. Traceability contract

Every requirement must have a stable ID and map to:
- authoritative source and decision status;
- actor/role and permitted scope;
- domain workflow/state transition;
- data entities and invariants;
- API route and/or database command/query;
- security and privacy controls;
- acceptance criteria;
- unit, integration, authorization, concurrency, end-to-end or operational tests as applicable;
- evidence artifact and release gate.

A requirement without a complete trace is not implementation-ready. A test case without a requirement or explicit risk rationale must be reviewed for necessity. A source or decision change must trigger impact analysis across every linked artifact.

## 7. Change control, agent governance and document lifecycle

- Root `AGENTS.md` is mandatory for every contributor and agent. Read it at the beginning of every work session and before each substantive task; if unavailable, stop repository edits. Re-read after any change to the file.
- Follow [Implementation Roadmap and Release Governance](IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) for pre-implementation phases, G10 authorization, implementation phases I0–I7 and release workflow.
- Application releases use Semantic Versioning 2.0.0. Pre-1.0 versions use `0.y.z`; `v1.0.0` is reserved for the first formally accepted stable production release after G12. API, DB migration, documentation baseline, instrument configuration and test evidence have independent version/identity domains.
- Database migrations use immutable monotonic identifiers and compatibility notes; application SemVer does not replace migration ordering.
- Maintain CHANGELOG and immutable release tags; never move a published tag.

### Existing document lifecycle controls

- Use stable IDs for requirements, decisions, ADRs, risks, commands, API operations and test cases.
- Approved decisions are immutable in history; changes create a superseding decision with rationale, approver, date, impact analysis and migration/deprecation notes.
- Every change identifies affected documents and tests before it is merged.
- Mark each statement as approved, confirmed, proposed, open, blocked, superseded or verified; do not mix these states.
- Record evidence location and verification date for every claim of compliance or test success.
- Keep illustrative values clearly labelled; never promote examples into production constants without approval.
- Keep the main branch stable; use focused documentation branches and PRs. Do not merge solely because a diff is large or CI is green; review semantic consistency and evidence.

## 8. Production-readiness definition

“100% ready” is not a documentation-only status. Before go-live, the release must have:
- complete approved scope and institutional authority;
- implemented and independently reviewed security controls;
- successful automated functional, authorization, tenant-isolation, concurrency and regression tests;
- verified performance against approved workload and SLOs;
- tested mobile, accessibility, low-connectivity and recovery behavior;
- successful database and object-storage restore drills;
- production monitoring, alerting, incident response and rollback;
- reconciled UAT and business acceptance;
- operational ownership, support and cost controls;
- no open critical/high-severity release blocker unless formally accepted by the authorized authority.

A claim of production readiness must cite concrete build, test, review, restore and UAT evidence. Passing documentation gates alone cannot establish production readiness.

## 9. Current known blockers and dependencies

The following are known from Package S and the current Decision Register; they must be revalidated against the latest source documents before scope freeze:

- Authoritative IFP source document and its complete checklist/specification/evidence-slot reconciliation.
- Standing Bracket photo-slot rules, additional annex/specification and exact treatment of ambiguous source wording.
- Institutional BA signatory authority and final approved template.
- Institutional records, privacy, legal, retention, deletion/disposition, legal-hold and audit governance decisions.
- Exact offline device/OS/browser matrix, local protection, cache/purge, conflict and recovery behavior.
- Provider ownership, region, plan, quotas, backup/PITR, Storage recovery, billing, contacts and cost envelope.
- Physical schema, composite constraints/FKs, canonical permission registry, table/view/function/storage grants, RLS and per-command contracts.
- Report semantics, performance SLOs, workload profile, CI quota and actual branch protection/required checks.

This list is not exhaustive; the latest RAID, Decision Register, RTM and Package S remain authoritative for detailed status.

## 10. Current project status

- Repository intent: **DOCUMENTATION AND APPLICATION IN ONE REPOSITORY — CONFIRMED BY PRODUCT OWNER**
- Documentation gap audit: **DGA-001 v1.18.0 RECORDED; blocking closure IN PROGRESS**
- Mandatory agent instructions: **AGENTS.md v1.2.5 — READ BEFORE EVERY WORK SESSION/TASK**
- Implementation roadmap: **IRG-001 v1.0.10 — CONTROLLED PLAN, NOT AUTHORIZATION**
- SemVer policy: **2.0.0 adopted; application version not assigned before release**
- Full-system implementation readiness: **NOT READY — see DGA-001; G10-F1 foundation implementation ACTIVE**
- Current phase: **STAGED FOUNDATION IMPLEMENTATION — G9-F1 / G10-F1**
- Application source code: **FOUNDATION BOOTSTRAP LOCALLY VERIFIED on `feat/foundation-bootstrap-v1-rebased` (PR #30 OPEN; `npm ci && npm run check` PASS 2026-11-27; hosted Actions blocked on account billing/spending limit)**
- T-18 hybrid execution model: **PO-APPROVED DESIGN; implementation conformance NOT VERIFIED**
- Notification product semantics: **POQ-01..03 APPROVED; engineering/security/institutional closure OPEN**
- Live Supabase inspection: **NOT EXECUTED**
- Hosted CI, live OAuth, restore, performance and UAT evidence: **NOT EXECUTED / BLOCKED**
- Foundation scope freeze: **G9-F1 FROZEN; full-system G9 NOT READY**
- Product Owner authorization: **CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED (2026-11-24)**
- G10 implementation activation: **G10-F1 ACTIVE (2026-11-25, following PR #26); later business-feature stages remain gated**
- Production readiness: **NOT VERIFIED**

## 11. Immediate next actions

1. Treat [Documentation Gap Audit — Gate Implementation Readiness](DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) as the active evidence-backed closure queue; do not claim readiness while any blocking row remains open.
2. Reconcile historical status language in Package T, Package S, Decision Register, RTM and RAID without changing approved decision meaning.
3. Close instrument source/evidence-slot and BA/template authority dependencies with controlled source evidence.
4. Reconcile the approved POQ-01..03 notification semantics across NLA-001, command/API/schema/RLS/RTM/QA; close durable audience snapshot/checkpoint and selector design, worker identity/ACL, policy grants/SoD, provider callback security, retry horizons and T-10/provider dependencies; then obtain independent technical review of the six notification tables plus T-13 `print_batches` constraints, locks and tests.
5. Complete the 54-operation command review: exact permissions, role/grantor/SoD, schemas, physical read/write sets, route/RPC mapping, transaction boundaries, idempotency, audit and command-specific tests.
6. Reconcile physical schema, RLS, views, functions, triggers, sequences, Storage policies and exact grants.
7. Close offline/device/local-data, evidence lifecycle, report reproducibility, account recovery, provider, backup/restore and measurable SLO specifications.
8. Obtain written institutional T-10/T-12 approvals and current provider capability evidence.
9. Complete requirement-to-design-to-test traceability and independent cross-document consistency review.
10. Only after blockers are closed, request scope-freeze approval; then request separate implementation authorization.

---
This blueprint is a governance/navigation artifact. It does not authorize code, migrations, SQL execution, grants/revokes, live database changes, deployment, or merge.

## 12. Notification and batch-print design reconciliation — 2026-11-24

- INS-015 design proposal is documented in [Notification Lifecycle and Delivery Architecture](../02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) (NLA-001 v0.1.3). POQ-01..03 are approved: hybrid event-time audience with non-widening dispatch revalidation, per-policy SLA with ELAPSED_UTC initial default and quiet-hours delivery deferral only, and no dismiss/archive in MVP. The six notification persistence entities, transactional outbox, worker lease fencing, publish-only policy, INT-NOTIF-001 provider callback ingress and escalation remain proposed pending engineering/security/institutional approval. QA has 29 notification cases, all planned/not executed. CMD-049–054 review v0.1.2 and cross-document mappings are recorded; technical and runtime evidence remain open.
- T-13 PO-approved batch printing is represented by `print_batches` plus append-only per-document `print_events`; no new product decision is inferred beyond T-13.
- Proposed physical schema/RLS inventory is 48/48 by static document comparison. This is not live database verification.
- DGA-B10/B11/B13/B14 remain open or partial pending independent technical review, permission/worker approval, institutional T-10 decisions, provider evidence and test traceability.
- No migrations, SQL, grants, live database changes, provider configuration or implementation are authorized.


> **Historical checkpoint note:** Sections 13–15 below preserve dated snapshots from before the Product Owner's conditional implementation authorization was recorded. Their older G10 NOT AUTHORIZED / NOT GRANTED wording is historical and is superseded by §16 and the current gate fields at the top of this document.

## 13. Cross-document audit and authority request control — 2026-11-24

The current governance review is recorded in:
- [SSOT-AUDIT-001 — Cross-Document Reconciliation Audit](SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md) v0.1.4.
- [POQ-001 — Product Owner Decision Packet](PRODUCT-OWNER-OPEN-DECISION-PACKET.md) v0.1.1.
- [AUTH-001 — Institutional and Technical Authority Approval Package](INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md) v0.1.0.

Package S §9.16 is the current cross-document inventory snapshot; §9.15 and earlier audit sections remain historical. Package T v0.1.1 is a historical decision pack; the Decision Register remains the canonical index of current PO decisions. RTM-001 v0.1.3 and RAID-001 v0.1.1 are synchronized with the audit. The T-13 print test mapping is corrected against QA Catalogue v0.3.6.

POQ-01..03 are approved and recorded. AUTH-001 continues to route institutional, security, database, repository and operations evidence requests to actual delegated authorities; no institutional or technical approval is assumed.

Current gates remain G9 NOT READY and G10 NOT AUTHORIZED. This control-plane update does not authorize code, SQL, migrations, grants/revokes, live database changes, CI execution, deployment, merge or production activation.


## 14. Agent policy and notification decision baseline — 2026-11-24

Root AGENTS.md is updated to v1.2.1. It records POQ-01..03 as approved product semantics and explicitly preserves the technical/institutional boundary. The active current sources are DGA-001 v1.11.27, IRG-001 v1.0.2, SSOT-AUDIT-001 v0.1.5, RTM-001 v0.1.3, QA Catalogue v0.3.6, NLA-001 v0.1.3 and CMD-049–054 review v0.1.2.

The static QA inventory contains 413 unique planned definitions, including TC-NOTIF-001..029; none is execution evidence. G9 remains NOT READY because source authority, institutional approvals, permission/command/database/lock closure, operational evidence and independent review remain incomplete. G10 remains NOT GRANTED. No implementation, SQL, migrations, grants/revokes, CI run, deployment or merge is authorized by this update.


## 15. External inspection evidence baseline — 2026-11-24

[EVID-EXT-001 — External Inspection Evidence Register](EXTERNAL-INSPECTION-EVIDENCE-REGISTER-001.md) v0.1.0 is the current index for the Product Owner-supplied inspection evidence. It records the 20 Nov SB batch BA (460/456/4), 23 Nov IFP visit BA (300/300/0, SB 0/0/0), 23 Nov SB form no. 469, 24 Nov IFP form no. 189, the 13-row serial-number example and the 23–25 Nov attendance sheet. Product Owner acceptance of these artifacts and clarification that the 3TB75B-prefixed examples are correct are recorded. These samples improve G1 evidence traceability but do not replace controlled-source provenance, institutional signatory/attendance authority or full annex verification.

Current gate effect: DGA-B01..B03 evidence-receipt/PO subcomponents are updated; institutional/source closure remains open. G1 and G9 remain NOT READY. G10 remains NOT AUTHORIZED. The existing AGENTS.md authorization boundary is unchanged.


## 16. Product Owner conditional implementation authorization — 2026-11-24

The Product Owner supplied an explicit written authorization to move the project from documentation toward implementation from zero in this repository, using the current SSOT as the build baseline. The authorization directs the team to close G9 prerequisites, freeze scope only after critical blockers are closed, and activate G10 only after verification. It permits source code, database schema, migrations, API, frontend and automated tests on a dedicated implementation branch after G10 activation. Production changes, deployment and operations affecting real data require separate approval. No gate may be marked PASS without required evidence and approvals.

Canonical approval record: [Decision Register — Product Owner conditional implementation authorization](DECISION-REGISTER.md).

**Gate disposition:** PO CONDITIONAL AUTHORIZATION RECEIVED. G9 remains NOT READY; G10 remains NOT ACTIVE; implementation remains prohibited until the G9 scope-freeze and G10 activation records are complete. This authorization does not replace institutional, Security, Database, Operations or provider approvals. The repository root AGENTS.md remains the mandatory execution boundary until updated through the approved gate process.


## 17. Implementation-entry blocker plan — 2026-11-25

[IER-001 — Implementation Entry Readiness and Remaining Blocker Plan](IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md) v0.1.0 consolidates the remaining evidence required for G9 scope freeze and the separate G10 activation. It is a navigation and sequencing artifact, not an approval or a replacement for DGA-001.

Post-PR #19 main baseline: `779f46c45444f7878d2128869288e986ff6b0b7a`; PRs #14–#19 merged. F05-T1..T5 are synchronized candidate specifications, not technical closure. F-04 writer certification remains zero; F-03 resolver certification remains 0/40, application lock certification 0/50 and global graph acyclicity NOT PROVEN. SES-001 business semantics are approved, but technical command/security/physical/QA closure remains outstanding. QA is PLANNED / NOT EXECUTED; CI evidence is ABSENT where unavailable.

**Current gate state:** G9 NOT READY; G10 NOT ACTIVE; implementation NOT STARTED / NOT AUTHORIZED. All work must continue under the current root AGENTS.md boundary.


## 18. Post-PR #23 SSOT and gate checkpoint — 2026-11-25

The verified canonical `main` baseline after PR #23 is `0db79d376face690b353d466a18129b6dd0ae5b2`. PR #23 is merged and its six documentation files are present on `main`. The current readiness references are DGA-001 v1.13.3, IER-001 v0.1.2, PTCM-001 v0.1.1, LOCK-GRAPH-001 v0.4.25, RAID-001 v0.1.30 and RTM-001 v0.1.33.

PTCM-001 consolidates the evidence-oriented closure work for F-03, F-04 and the PO-approved SES-001 packed-unit ABORT semantics. It does not itself approve a technical lock protocol, certify any eligibility writer, assign command IDs or admit physical schema. Current dispositions remain: F-03 NOT PROVEN ACYCLIC; F-04 0 writers certified; resolver paths 0/40 certified; application command lock certification 0/50; SES-001 technical contract OPEN; QA PLANNED / NOT EXECUTED. CI/workflow evidence is ABSENT where no checks/runs are returned.

**Gate disposition remains unchanged:** PO CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED; G9 NOT READY; G10 NOT ACTIVE; implementation NOT STARTED / NOT AUTHORIZED. The next permitted work remains documentation, read-only repository inspection and static consistency analysis. No source code, SQL, migration, grants/RLS, live database inspection, provider change, runtime test, deployment or production data mutation is authorized.


## 19. Staged implementation gate update — 2026-11-25

PR #26 (merge commit 4ef6fb49fcd4c4e83cc4a328a1e2125f96f6dcc2) records Product Owner decision PO-2026-11-25-IMPLEMENTATION-RESPONSIBILITY-001 and activates G9-F1/G10-F1. The Product Owner owns institutional authorization, coordination and compliance; separate institutional approval artifacts are not a prerequisite for bounded engineering development. This is not a claim that an external institution has issued written approval.

G9-F1 FOUNDATION SCOPE FROZEN and G10-F1 FOUNDATION IMPLEMENTATION ACTIVE cover repository/app bootstrap, development configuration, CI, authentication shell, database foundation and development-only migrations, typed API boundary, observability baseline and automated tests using synthetic data. Production data/evidence, irreversible retention/deletion, legal-hold disposition, production provider operations and deployment are excluded.

Full-system G9 remains NOT READY. F-03/F-04, command-level authorization, worker/provider security, physical RLS/grants and unresolved business contracts remain feature-entry gates. No executable business mutation may be implemented until its command, authorization, transaction/lock and acceptance-test contract is resolved. Solo-maintainer self-review, actual automated checks and post-merge verification remain mandatory.
