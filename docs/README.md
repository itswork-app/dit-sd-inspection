# Master Documentation Index & Architecture Map — Dit. SD Inspection

**Document ID:** DOC-MAP-001  
**Version:** 1.3.2  
**Status:** CONTROLLED MASTER DOCUMENTATION MAP — G9-TECH FROZEN; G10 ACTIVE; G11 PARTIAL (main-push CI PASS; main ruleset DISABLED); G12 BLOCKED  
**Last updated:** 2026-11-27  
**Applies to:** Repository `itswork-app/dit-sd-inspection`  
**Governing Authority:** [AGENTS.md](../AGENTS.md) v1.3.1 & [Master Implementation Blueprint (MIB-001)](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) v1.3.1

---

## 1. Documentation Overview & Single Source of Truth (SSOT)

This repository serves as both the **authoritative documentation repository** and the **application implementation repository**.

Documentation under `docs/` on this branch is organized into 6 functional directories containing **105** controlled documents (**106** Markdown files inside `docs/` including this index), complemented by root [AGENTS.md](../AGENTS.md), root [README.md](../README.md), and [supabase/migrations/README.md](../supabase/migrations/README.md).

### Precedence Hierarchy (Source of Truth)
When interpreting requirements, design, or architecture, adhere strictly to the precedence hierarchy defined in [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) §1.1:
1. **Product Owner Decisions & Approved Register:** [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md)
2. **Institutional Approvals:** Formal written approvals for matters reserved to institutional legal, records, privacy, security, finance, or operational authorities (PO approval cannot substitute for them).
3. **Approved Product Requirements & Instrument Specifications:** [PRD.md](01-product-requirements/PRD.md), [ACCEPTANCE-CRITERIA.md](01-product-requirements/ACCEPTANCE-CRITERIA.md), and controlled source instruments.
4. **Approved Architecture Decision Records (ADRs):** [ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md) and [ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md](02-architecture/ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md).
5. **Governing Blueprints & Roadmaps:** [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md), [DGA-001](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md), [IRG-001](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md).
6. **Detailed Specifications & Planned QA Catalogue:** Architecture, domain, security, API, functional design, UX, and planned verification catalogues.
7. **Historical Audit Packages & Working Proposals:** Informative background only; non-authoritative when superseded by higher registers.

---

## 2. Document Classification Matrix

| Directory | Doc Count | Scope | Canonical SSOT Files (`v1.0.0+` G9-TECH Baseline) | Supporting / Historical / Proposals |
|---|---:|---|---|---|
| [`00-project-charter/`](#3-project-charter--governance) | 28 | Governance, Charter, Gates & Traceability | `PROJECT-CHARTER.md`, `DECISION-REGISTER.md`, `MIB-001` (v1.3.1), `DGA-001` (v2.4.1), `IRG-001` (v1.1.0), `IER-001` (v1.0.0), `PTCM-001` (v1.0.0), `RTM-001` (v1.1.0), `RAID-REGISTER.md` (v1.1.0), `SSOT-AUDIT-001` (v1.0.0), `RACI-MATRIX.md`, `ENGINEERING-GOVERNANCE.md`, `GOV-MERGE-001`, `EVID-EXT-001` | Historical Audit Packages (`PACKAGE-F` through `PACKAGE-T`), `PHASE-0-PLAN.md`, `FINAL-DOCUMENTATION-CLOSURE-AUDIT.md`, `AUTH-001`, `POQ-001`, `REFERENCE-EVIDENCE-INVENTORY.md` |
| [`01-product-requirements/`](#4-product-requirements) | 5 | Functional Requirements & Instrument Specs | `PRD.md`, `ACCEPTANCE-CRITERIA.md`, `IFP-INSTRUMENT-SPECIFICATION.md`, `STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md` | `PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md` |
| [`02-architecture/`](#5-system-architecture--technical-specifications) | 59 | Architecture, Database (62 tables), Security, Commands (52 app) & Locks | `SYSTEM-ARCHITECTURE.md`, `ADR-001`, `DATA-MODEL-AND-ERD.md`, `PHYSICAL-DATABASE-SCHEMA...` (v1.0.0), `TABLE-BY-TABLE-RLS...` (v1.0.0), `CANONICAL-PERMISSION-REGISTRY...` (v1.0.0), `POSTGRESQL-FUNCTION-SECURITY...` (v1.0.0), `POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md` (v1.0.0), `CONCURRENCY-001` (v1.0.0), `LOCK-PROTOCOL-DECISION-RESOLUTION-001` (v1.0.0), `LOCK-GRAPH-001` (v1.0.0), `LOCK-MANIFEST-001` (v1.0.0), `NLA-001` (v1.0.0), `NLA-L05-WRITER-MATRIX-001` (v1.0.0) | 7 Detailed Command Reviews (`CMD-001`..`054`), Technical Proposals/RFCs, Notification sub-registries, Operational/Provider runbooks |
| [`03-functional-design/`](#6-functional-design) | 5 | Domain Business Workflows & Session Lifecycles | `INSPECTION-LIFECYCLE-AND-CLAIMS.md`, `PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md`, `OFFLINE-SYNC-AND-RECOVERY.md` (v1.0.0), `RBAC-AND-AUTHORIZATION.md`, `REPORTS-DOCUMENTS-AND-AUDIT.md` | Domain rules & state-machine semantics |
| [`03-ux/`](#7-user-experience--design-system) | 3 | UI/UX, Navigation & Screen Wireframes | `DESIGN-SYSTEM-AND-RESPONSIVE-UX.md`, `INFORMATION-ARCHITECTURE-AND-NAVIGATION.md`, `SCREEN-FLOWS-AND-WIREFRAME-SPEC.md` | UI wireframes and token tables |
| [`04-quality/`](#8-quality-assurance--testing) | 5 | QA Strategy, Test Catalogs & Verification | `TEST-STRATEGY-AND-QUALITY-GATES.md`, `TEST-CASE-CATALOG-AND-UAT.md`, `INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md`, `CERT-001...` | `L05-TECHNICAL-REVIEW-001.md` |

---

## 3. Project Charter & Governance (`00-project-charter/` — 28 documents)

### 3.1 Active Baseline Registers & Evidence Indexes
- [PROJECT-CHARTER.md](00-project-charter/PROJECT-CHARTER.md): Project charter, stakeholder context, and business objectives.
- [MASTER-IMPLEMENTATION-BLUEPRINT.md](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) (**MIB-001** v1.3.1): Governance model, source-of-truth precedence, engineering invariants, and delivery gates G0–G12.
- [DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) (**DGA-001** v2.4.1): Active gap register (`DGA-B01`–`DGA-B22`; local G11 evidence and external/runtime gates preserved).
- [POST-MERGE-REPOSITORY-AUDIT-2026-11-27.md](00-project-charter/POST-MERGE-REPOSITORY-AUDIT-2026-11-27.md) (**PMA-001** v1.2.0): Post-merge audit of PRs #38–#41, main HEAD `706c654`, SSOT remediation, and correction of the initial CI evidence query (main-push run #77 PASS).
- [G11-EVIDENCE-CLOSURE-PLAN.md](00-project-charter/G11-EVIDENCE-CLOSURE-PLAN.md) (**G11-ECP-001** v1.0.1): Execution/evidence plan for hosted CI, repository enforcement, managed PostgreSQL + Storage recovery, real-device offline UAT, staging load/SLO and QA catalogue closure.
- [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md): Canonical index of approved Product Owner decisions through 2026-11-27 (`T-01..T-18`, `POQ-01..04`, `LPR-02..06`, `RBAC-003`, `SES-001`, `DOC-003`, `C36-02`, `IDC-O04..O10`, `NLA-MVP-001`).
- [IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) (**IRG-001** v1.1.0): Pre-implementation gates, ordered phases `I0–I7`, release controls, and SemVer 2.0.0 policy.
- [REQUIREMENTS-TRACEABILITY-MATRIX.md](00-project-charter/REQUIREMENTS-TRACEABILITY-MATRIX.md) (**RTM-001** v1.1.0): End-to-end traceability from requirements to 52 commands, 62 tables, security controls, planned QA, and gates.
- [RAID-REGISTER.md](00-project-charter/RAID-REGISTER.md) (**RAID-001** v1.1.0): Risks, Assumptions, Issues, and Dependencies register.
- [RACI-MATRIX.md](00-project-charter/RACI-MATRIX.md): Roles and accountability matrix.
- [ENGINEERING-GOVERNANCE.md](00-project-charter/ENGINEERING-GOVERNANCE.md): Engineering standards and documentation discipline.
- [GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md](00-project-charter/GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md) (**GOV-MERGE-001**): Narrow controlled merge policy for documentation-only PRs.
- [EXTERNAL-INSPECTION-EVIDENCE-REGISTER-001.md](00-project-charter/EXTERNAL-INSPECTION-EVIDENCE-REGISTER-001.md) (**EVID-EXT-001**): Inventory of Product Owner-supplied external inspection evidence samples.
- [REFERENCE-EVIDENCE-INVENTORY.md](00-project-charter/REFERENCE-EVIDENCE-INVENTORY.md): Inventory of legacy workflow and output reference artifacts.

### 3.2 Readiness Plans, Authority Packages & Historical Audit Snapshots
> [!NOTE]
> Historical audit snapshots and decision packs below are preserved for complete auditability. Where superseded, the canonical active registers above govern current state.
- [IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md](00-project-charter/IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md) (**IER-001** v1.0.0): G9/G10 readiness plan and `G9-TECH` closure record.
- [PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md](00-project-charter/PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md) (**PTCM-001** v1.0.0): Technical closure matrix for `F-03`, `F-04`, and `SES-001`.
- [SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md](00-project-charter/SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md) (**SSOT-AUDIT-001** v1.0.0): Cross-document reconciliation audit and `G9-TECH` checkpoint.
- [INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md](00-project-charter/INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md) (**AUTH-001**): Institutional and external authority evidence requests.
- [PRODUCT-OWNER-OPEN-DECISION-PACKET.md](00-project-charter/PRODUCT-OWNER-OPEN-DECISION-PACKET.md) (**POQ-001**): Notification product-semantic decision packet (closed at PO level).
- [FINAL-DOCUMENTATION-CLOSURE-AUDIT.md](00-project-charter/FINAL-DOCUMENTATION-CLOSURE-AUDIT.md): Historical documentation closure review.
- [PHASE-0-PLAN.md](00-project-charter/PHASE-0-PLAN.md): Historical Phase 0 work plan.
- [PACKAGE-F-CROSS-DOCUMENT-AUDIT.md](00-project-charter/PACKAGE-F-CROSS-DOCUMENT-AUDIT.md): Historical Package F cross-document audit.
- [PACKAGE-G-PO-DECISION-RESOLUTION-PACK.md](00-project-charter/PACKAGE-G-PO-DECISION-RESOLUTION-PACK.md): Historical Package G PO decision resolution pack.
- [PACKAGE-H-FINAL-REQUIREMENTS-ARCHITECTURE-CONSISTENCY-AUDIT.md](00-project-charter/PACKAGE-H-FINAL-REQUIREMENTS-ARCHITECTURE-CONSISTENCY-AUDIT.md): Historical Package H requirements/architecture audit.
- [PACKAGE-I-FINAL-PO-DECISION-AND-SCOPE-FREEZE-PREP.md](00-project-charter/PACKAGE-I-FINAL-PO-DECISION-AND-SCOPE-FREEZE-PREP.md): Historical Package I scope-freeze prep.
- [PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md](00-project-charter/PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md): Historical Package K security/data-integrity audit.
- [PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md](00-project-charter/PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md): Historical Package S audit with dated reconciliation addenda.
- [PACKAGE-T-PO-DECISION-CLOSURE-PACK.md](00-project-charter/PACKAGE-T-PO-DECISION-CLOSURE-PACK.md): Historical Package T decision pack (outcomes in Decision Register).

---

## 4. Product Requirements (`01-product-requirements/` — 5 documents)

- [PRD.md](01-product-requirements/PRD.md): Product Requirements Document covering IFP and Standing Bracket inspection workflows and configurable instruments.
- [ACCEPTANCE-CRITERIA.md](01-product-requirements/ACCEPTANCE-CRITERIA.md): Formal acceptance criteria per requirement.
- [IFP-INSTRUMENT-SPECIFICATION.md](01-product-requirements/IFP-INSTRUMENT-SPECIFICATION.md): Interactive Flat Panel inspection instrument sections, items, and response rules.
- [STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md](01-product-requirements/STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md): Standing Bracket inspection instrument baseline criteria.
- [PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md](01-product-requirements/PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md): Reconciliation of notification requirements (`INS-015`) into PRD scope.

---

## 5. System Architecture & Technical Specifications (`02-architecture/` — 59 documents)

### 5.1 Core Architecture, Physical Schema (62 Tables) & Security Foundation
- [SYSTEM-ARCHITECTURE.md](02-architecture/SYSTEM-ARCHITECTURE.md): System architecture, Vercel + Supabase modular-monolith topology, and component boundaries.
- [ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md): Approved ADR-001 (Vercel + Supabase PostgreSQL/Auth/RLS/Storage + GitHub).
- [ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md](02-architecture/ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md): Accepted ADR-002 foundation runtime stack (Next.js 16, strict TS, `@supabase/ssr`, verified claims, local migrations).
- [AUTHENTICATION-GOOGLE-OAUTH-SETUP.md](02-architecture/AUTHENTICATION-GOOGLE-OAUTH-SETUP.md): Development Google OAuth setup and verified interactive round-trip runbook.
- [DATA-MODEL-AND-ERD.md](02-architecture/DATA-MODEL-AND-ERD.md): Conceptual/logical data model, entity relationships, and core schema rules.
- [PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md](02-architecture/PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md) (**v1.0.0**): Canonical **62-table** physical specification, constraints, types, and indexes (`G9-TECH` design closed).
- [PHYSICAL-COMMAND-SCHEMA-RECONCILIATION-001.md](02-architecture/PHYSICAL-COMMAND-SCHEMA-RECONCILIATION-001.md): Reconciliation between command contracts and physical schema objects.
- [PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md](02-architecture/PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md): Crosswalk reconciling physical tables, RLS policies, and commands.
- [SECURITY-THREAT-MODEL.md](02-architecture/SECURITY-THREAT-MODEL.md): Threat model, trust boundaries, abuse cases, and mitigations.
- [RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md](02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md): PO-approved account lifecycle, role delegation ceiling, SoD, last-admin protection, and explicit non-inheriting scope semantics.
- [CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md](02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md) (**v1.0.0**): Closed canonical permission registry, role-to-permission matrix, grantor delegation ceiling, and SoD rules (`G9-TECH`).
- [COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md](02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md) (**v1.0.0**): Command-level authorization verification matrix reconciled to 62 tables and `CMD-055`/`CMD-056`.
- [RLS-AND-AUTHORIZATION-DESIGN.md](02-architecture/RLS-AND-AUTHORIZATION-DESIGN.md): Row Level Security architecture and deny-by-default authorization design.
- [TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md](02-architecture/TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md) (**v1.0.0**): Complete **62/62** table-by-table RLS policy catalogue (`G9-TECH` design closed).
- [T18-EXECUTION-MODEL-SECURITY-REVIEW.md](02-architecture/T18-EXECUTION-MODEL-SECURITY-REVIEW.md): Security review for PO-approved T-18 Option A hybrid execution model.
- [POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md](02-architecture/POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md) (**v1.0.0**): Closed `T-18` `app_cmd_definer`/`app_worker_definer` role ownership, `search_path = ''`, and exact-signature `EXECUTE` ACL design.
- [PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md](02-architecture/PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md): Route-to-PostgreSQL privileged command boundary, caller JWT propagation, and atomic commit/audit rules.
- [API-AND-TRANSACTION-CONTRACTS.md](02-architecture/API-AND-TRANSACTION-CONTRACTS.md): Application API envelope, idempotency, error handling, and transaction contracts.
- [AUDIT-EVENT-CATALOGUE-AND-GOVERNANCE.md](02-architecture/AUDIT-EVENT-CATALOGUE-AND-GOVERNANCE.md): Append-only audit event catalogue (`INS-016` / `T-15`) and privacy exclusions.
- [T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md](02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) (**T19-001**): Historical repository baseline and 2026-11-27 GitHub remote/control-plane re-audit.

### 5.2 Command Contracts (52 App Commands), Concurrency & Lock Manifests (`CMD-001`–`CMD-056`)
- [POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md](02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md) (**v1.0.0**): Master inventory of all 56 IDs (**52 in-scope application commands** including `CMD-055`/`CMD-056` + 4 excluded external control-plane IDs `CMD-045..048`).
- [CMD-001-054-CROSS-COMMAND-RECONCILIATION.md](02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md): Cross-command reconciliation synthesis.
- [COMMAND-PHYSICAL-OBJECT-CROSSWALK-001.md](02-architecture/COMMAND-PHYSICAL-OBJECT-CROSSWALK-001.md): Mapping between logical commands and physical database objects.
- [COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md](02-architecture/COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) (**LOCK-MANIFEST-001** v1.0.0): Normalized lock manifests for all **52 application commands** (`G9-TECH` design closed; `LPR-10` gated to `G11`).
- [COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md](02-architecture/COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md): Normalization tracking register for command lock manifests.
- [GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md](02-architecture/GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) (**LOCK-GRAPH-001** v1.0.0): Total ascending lock hierarchy `L00–L110` with all 9 conflict classes (`F03-C01..C09`) resolved into a statically acyclic design DAG.
- [LOCK-PROTOCOL-DECISION-RESOLUTION.md](02-architecture/LOCK-PROTOCOL-DECISION-RESOLUTION.md) (**LOCK-PROTOCOL-DECISION-RESOLUTION-001** v1.0.0): Resolution of `LPR-01..LPR-09` & `LPR-11` (`LPR-10` gated to `G11`).
- [ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md](02-architecture/ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) (**TECH-RESOLUTION-LPR-001**): Technical resolution decomposition for `LPR-01`–`LPR-11`.
- [CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md](02-architecture/CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) (**CONCURRENCY-001** v1.0.0): Closed `CV-01..CV-08` decimal-string `expected_row_version` CAS, hash, sequence, and worker lease contract.
- [AGGREGATE-CONCURRENCY-RESOLUTION-001.md](02-architecture/AGGREGATE-CONCURRENCY-RESOLUTION-001.md): Aggregate-level concurrency and parent-fence analysis.
- **Detailed Command Reviews:**
  - [CMD-001-010-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-001-010-DETAILED-CONTRACT-REVIEW.md): Account lifecycle, role/scope grants, and project creation/update/closure.
  - [CMD-011-020-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-011-020-DETAILED-CONTRACT-REVIEW.md) & [PO Package](02-architecture/CMD-011-020-PO-DECISION-AND-ENGINEERING-REVIEW-PACKAGE.md): Session lifecycle, team assignments, Inspector capacity (`T-14`), target plans, and instrument creation/draft/publication.
  - [CMD-021-030-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-021-030-DETAILED-CONTRACT-REVIEW.md): Instrument deactivation, canonical unit/project association/conflict handling, unit claims, inspection draft/submission, and review return.
  - [CMD-031-040-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-031-040-DETAILED-CONTRACT-REVIEW.md): Inspection approval/reopen, evidence upload/finalization, offline sync, document generation, individual/batch printing, and attendance verification.
  - [CMD-041-044-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-041-044-DETAILED-CONTRACT-REVIEW.md): Scoped read/reporting views, audit query, and governed audit export (`CMD-044` gated until `T-10`).
  - [CMD-045-048-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-045-048-DETAILED-CONTRACT-REVIEW.md) & [Proposal](02-architecture/CMD-045-048-RESOLUTION-PROPOSAL.md): External control-plane traceability IDs (PO-approved out of application command surface).
  - [CMD-049-054-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-049-054-DETAILED-CONTRACT-REVIEW.md): Notification policy management, outbox/dispatch/worker lifecycle, escalation, and recipient read acknowledgement.

### 5.3 Technical Proposals & Admitted Lifecycle Designs
- [DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md](02-architecture/DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md): Per-operation sync commits (`CMD-035`), document generation lifecycle (`CMD-036`, `C36-02`), and durable print-batch manifests (`CMD-038`).
- [DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md](02-architecture/DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md): Monotonic per-document print sequences (`CMD-037`) and PO-approved current-version-only printing (`DOC-003`).
- [INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md](02-architecture/INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md): Admitted `inspection_draft_contexts` separated from immutable submitted revisions (`IDC-O01..O10`).
- [INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md](02-architecture/INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md): Admitted `inspection_reviewer_assignments` entity.
- [REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md](02-architecture/REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md): Single terminal-decision-per-revision arbiter on `review_events`.

### 5.4 Notification Architecture (`NLA-001`)
- [NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md](02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) (**NLA-001** v1.0.0): Closed `INS-015` / `F05-T1..T5` / `NLA-MVP-001` technical design (`SENDING → RETRY_WAIT`, atomic `notification_outbox_recipients`; external provider adapters disabled until `T-10`/`T-12`).
- [NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md](02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) (**NLA-L05-TDR-001**): Selector grammar, dispatch matrix, suppression/retry taxonomy, audit evidence, and atomic snapshot rules (`F05-T1..T5`).
- [NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md](02-architecture/NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md): Triage of candidate notification events.
- [NOTIFICATION-EVENT-REGISTRY-001.md](02-architecture/NOTIFICATION-EVENT-REGISTRY-001.md): Notification event registry (`NREG-001..011`).
- [NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md](02-architecture/NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md): Technical reconciliation of event producers and contracts.
- [NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md](02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md): Lock-set review for notification recipient resolution.
- [L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md](02-architecture/L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md) (**NLA-L05-WRITER-MATRIX-001** v1.0.0): Closed design-level `F-04` writer universe and zero-backward-lock snapshot rule.
- [L05-EVENT-TO-SELECTOR-REGISTRY-001.md](02-architecture/L05-EVENT-TO-SELECTOR-REGISTRY-001.md): Event-to-selector mapping registry.
- [L05-SOURCE-EVENT-PATH-MAPPING-001.md](02-architecture/L05-SOURCE-EVENT-PATH-MAPPING-001.md): Source-event producer path mapping.

### 5.5 Evidence, Operations, Provider & Recovery Runbooks
- [EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md](02-architecture/EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md): Private Storage upload-intent, verification, immutable originals, signed URLs, and orphan cleanup design.
- [EVIDENCE-PRIVACY-RETENTION-DELETION-AND-RECOVERY.md](02-architecture/EVIDENCE-PRIVACY-RETENTION-DELETION-AND-RECOVERY.md): Evidence privacy, retention, legal hold, and disposition governance (`T-10` production gate).
- [PERFORMANCE-AND-OPERATIONS-BASELINE.md](02-architecture/PERFORMANCE-AND-OPERATIONS-BASELINE.md): 100-concurrent-user acceptance load profile, operational baseline, and open numeric SLOs.
- [BACKUP-RESTORE-AND-DISASTER-RECOVERY-PLAN.md](02-architecture/BACKUP-RESTORE-AND-DISASTER-RECOVERY-PLAN.md): PostgreSQL and Storage backup/restore plan and required `G11`/`G12` restore drills.
- [PRODUCTION-ENVIRONMENT-SECRETS-AND-PROVIDER-GOVERNANCE.md](02-architecture/PRODUCTION-ENVIRONMENT-SECRETS-AND-PROVIDER-GOVERNANCE.md): Environment separation, secret boundaries, and provider ownership governance (`T-12` production gate).
- [SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md](02-architecture/SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md): Runbook for live PostgreSQL `pg_catalog` schema, grants, RLS, and function privilege audit (`G11`).

---

## 6. Functional Design (`03-functional-design/` — 5 documents)

- [INSPECTION-LIFECYCLE-AND-CLAIMS.md](03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md): Session-bound inspection attempts, per-unit claims, immutable submitted revisions, `RETURNED_FOR_CORRECTION`, `APPROVED`, privileged reopen, and the narrow `SES-001` packed-unit `ABORTED` exception (`CMD-055`/`CMD-056`).
- [OFFLINE-SYNC-AND-RECOVERY.md](03-functional-design/OFFLINE-SYNC-AND-RECOVERY.md) (**v1.0.0**): Closed `T-09` Option B / `T-11` Option B offline draft editing for already-claimed units, device binding, local protection/purge, idempotent sync, and explicit conflict preservation (never silent overwrite).
- [PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md](03-functional-design/PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md): Project/session lifecycle (`DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`), location/instrument configuration, team assignments, and `T-14` Inspector capacity.
- [RBAC-AND-AUTHORIZATION.md](03-functional-design/RBAC-AND-AUTHORIZATION.md): Functional roles, explicit non-inheriting scopes, account approval, and separation of duties reconciled to `RBAC-003`.
- [REPORTS-DOCUMENTS-AND-AUDIT.md](03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md): Separate actual vs target reports, PDF generation (`C36-02`), per-document/batch print events (`T-13`, `DOC-002`, `DOC-003`), and append-only audit (`INS-016`).

---

## 7. User Experience & Design System (`03-ux/` — 3 documents)

- [DESIGN-SYSTEM-AND-RESPONSIVE-UX.md](03-ux/DESIGN-SYSTEM-AND-RESPONSIVE-UX.md): Typography, color palette, responsive breakpoints, and mobile-first inspector layout.
- [INFORMATION-ARCHITECTURE-AND-NAVIGATION.md](03-ux/INFORMATION-ARCHITECTURE-AND-NAVIGATION.md): App sitemap, route tree, navigation structure, and role-based UI visibility (never authorization).
- [SCREEN-FLOWS-AND-WIREFRAME-SPEC.md](03-ux/SCREEN-FLOWS-AND-WIREFRAME-SPEC.md): Step-by-step wireframe flows for Inspector, Reviewer, Korlap, Print Officer, and Super Admin screens.

---

## 8. Quality Assurance & Testing (`04-quality/` — 5 documents)

- [TEST-STRATEGY-AND-QUALITY-GATES.md](04-quality/TEST-STRATEGY-AND-QUALITY-GATES.md): Quality gates, risk-based test tiers (unit, integration, RLS, concurrency, negative auth, offline, recovery), and acceptance criteria.
- [TEST-CASE-CATALOG-AND-UAT.md](04-quality/TEST-CASE-CATALOG-AND-UAT.md): Planned verification and UAT test-case specifications (`v0.7.4`; 558 distinct explicit IDs; case-level execution mapping incomplete).
- [INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md](04-quality/INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md): Item-by-item verification matrix against IFP and Standing Bracket instrument requirements.
- [CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md](04-quality/CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md): Pre-implementation technical certification assessment across domains.
- [L05-TECHNICAL-REVIEW-001.md](04-quality/L05-TECHNICAL-REVIEW-001.md): Technical review of the L05 notification audience-guard specification.

---

## 9. Current Delivery Gate Status (Summary)

```
[Phase 0] -> [G9-F1 + G9-TECH Frozen] -> [G10 Full-System Synthetic Active] -> [G11 Local Verification Partial] -> [G12 Production (Blocked)]
```

- **G9-F1 Foundation Scope Freeze:** **FROZEN** (`G10-F1` ACTIVE)
- **G9-TECH Full-System Technical SSOT:** **FROZEN** (2026-11-27; PO sign-off recorded in `AGENTS.md` §3.3 and `DECISION-REGISTER.md`).
- **G10 Full-System Synthetic Implementation:** **ACTIVE**; I1–I5 implemented on isolated local/development infrastructure with synthetic data.
- **G11 Runtime/DB Verification:** **PARTIAL** — local synthetic suites and rehearsals are recorded in DGA-001 §22–§23; main-push hosted CI passed on merge commit `ae271615`, but the `main` ruleset is DISABLED (`DGA-B15`), real-device UAT is NOT EXECUTED (`DGA-B07`), managed restore remains OPEN (`DGA-B06`), and staging SLO/load remains OPEN (`DGA-B08`).
- **G12 Production Readiness:** **NOT VERIFIED / BLOCKED** on institutional, provider, operational and hosted CI evidence (`DGA-B01..B06`, `B08`, `B15`, `T-10`, `T-12`).
