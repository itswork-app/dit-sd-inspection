# Master Documentation Index & Architecture Map — Dit. SD Inspection

**Document ID:** DOC-MAP-001  
**Version:** 1.1.0  
**Status:** CONTROLLED MASTER DOCUMENTATION MAP  
**Last updated:** 2026-11-27  
**Applies to:** Repository `itswork-app/dit-sd-inspection`  
**Governing Authority:** [AGENTS.md](../AGENTS.md) v1.2.5 & [Master Implementation Blueprint (MIB-001)](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md)

---

## 1. Documentation Overview & Single Source of Truth (SSOT)

This repository serves as both the **authoritative documentation repository** and the **application implementation repository** (currently under staged foundation authorization `G9-F1 / G10-F1`).

Documentation under `docs/` is organized into 6 functional directories containing **103** controlled documents (**104** Markdown files inside `docs/` including this index), complemented by root [AGENTS.md](../AGENTS.md), root [README.md](../README.md), and the local database migration convention guide [supabase/migrations/README.md](../supabase/migrations/README.md).

### Precedence Hierarchy (Source of Truth)
When interpreting requirements, design, or architecture, adhere strictly to the precedence hierarchy defined in [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) §1.1:
1. **Product Owner Decisions & Approved Register:** [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md)
2. **Institutional Approvals:** Formal written approvals for matters reserved to institutional legal, records, privacy, security, finance, or operational authorities (PO approval cannot substitute for them).
3. **Approved Product Requirements & Instrument Specifications:** [PRD.md](01-product-requirements/PRD.md), [ACCEPTANCE-CRITERIA.md](01-product-requirements/ACCEPTANCE-CRITERIA.md), and controlled source instruments.
4. **Approved Architecture Decision Records (ADRs):** [ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md) and [ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md](02-architecture/ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md).
5. **Governing Blueprints & Roadmaps:** [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md), [DGA-001](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md), [IRG-001](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md).
6. **Detailed Specifications & QA Catalogue:** Architecture, domain, security, API, functional design, UX, and planned verification catalogues.
7. **Historical Audit Packages & Working Proposals:** Informative background only; non-authoritative when superseded by higher registers.

---

## 2. Document Classification Matrix

| Directory | Doc Count | Scope | Canonical SSOT Files | Supporting / Historical / Proposals |
|---|---:|---|---|---|
| [`00-project-charter/`](#3-project-charter--governance) | 26 | Governance, Charter, Gates & Traceability | `PROJECT-CHARTER.md`, `DECISION-REGISTER.md`, `MIB-001`, `DGA-001`, `IRG-001`, `RTM-001`, `RAID-REGISTER.md`, `RACI-MATRIX.md`, `ENGINEERING-GOVERNANCE.md`, `GOV-MERGE-001`, `EVID-EXT-001` | Historical Audit Packages (`PACKAGE-F` through `PACKAGE-T`), `PHASE-0-PLAN.md`, `FINAL-DOCUMENTATION-CLOSURE-AUDIT.md`, `SSOT-AUDIT-001`, `AUTH-001`, `POQ-001`, `IER-001`, `PTCM-001`, `REFERENCE-EVIDENCE-INVENTORY.md` |
| [`01-product-requirements/`](#4-product-requirements) | 5 | Functional Requirements & Instrument Specs | `PRD.md`, `ACCEPTANCE-CRITERIA.md`, `IFP-INSTRUMENT-SPECIFICATION.md`, `STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md` | `PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md` |
| [`02-architecture/`](#5-system-architecture--technical-specifications) | 59 | Architecture, Database, Security, Commands & Locks | `SYSTEM-ARCHITECTURE.md`, `ADR-001`, `ADR-002`, `DATA-MODEL-AND-ERD.md`, `PHYSICAL-DATABASE-SCHEMA...`, `SECURITY-THREAT-MODEL.md`, `RBAC-003...`, `RLS-AND-AUTHORIZATION-DESIGN.md`, `POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md`, `NLA-001` | 7 Detailed Command Reviews (`CMD-001`..`054`), Lock/Concurrency reconciliations, Technical Proposals/RFCs, Notification sub-registries, Operational/Provider runbooks |
| [`03-functional-design/`](#6-functional-design) | 5 | Domain Business Workflows & Session Lifecycles | `INSPECTION-LIFECYCLE-AND-CLAIMS.md`, `PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md`, `OFFLINE-SYNC-AND-RECOVERY.md`, `RBAC-AND-AUTHORIZATION.md`, `REPORTS-DOCUMENTS-AND-AUDIT.md` | Domain rules & state-machine semantics |
| [`03-ux/`](#7-user-experience--design-system) | 3 | UI/UX, Navigation & Screen Wireframes | `DESIGN-SYSTEM-AND-RESPONSIVE-UX.md`, `INFORMATION-ARCHITECTURE-AND-NAVIGATION.md`, `SCREEN-FLOWS-AND-WIREFRAME-SPEC.md` | UI wireframes and token tables |
| [`04-quality/`](#8-quality-assurance--testing) | 5 | QA Strategy, Test Catalogs & Verification | `TEST-STRATEGY-AND-QUALITY-GATES.md`, `TEST-CASE-CATALOG-AND-UAT.md`, `INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md`, `CERT-001...` | `L05-TECHNICAL-REVIEW-001.md` |

---

## 3. Project Charter & Governance (`00-project-charter/` — 26 documents)

### 3.1 Active Baseline Registers & Evidence Indexes
- [PROJECT-CHARTER.md](00-project-charter/PROJECT-CHARTER.md): Project charter, stakeholder context, and business objectives.
- [MASTER-IMPLEMENTATION-BLUEPRINT.md](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) (**MIB-001**): Governance model, source-of-truth precedence, engineering invariants, and delivery gates G0–G12.
- [DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) (**DGA-001**): Active evidence-backed gap register tracking blocking items (`DGA-B01`–`DGA-B22`).
- [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md): Canonical index of approved and open Product Owner decisions (`MGT`, `TECH`, `PRD`, `RBAC`, `WF`, `SES`, `DOC`, `INS`, `OPS`, `T-01..T-18`, `POQ`, `LPR`).
- [IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) (**IRG-001**): Pre-implementation gates, implementation phases `I0–I7`, release controls, and SemVer 2.0.0 policy.
- [REQUIREMENTS-TRACEABILITY-MATRIX.md](00-project-charter/REQUIREMENTS-TRACEABILITY-MATRIX.md) (**RTM-001**): End-to-end traceability from requirements to commands, security controls, planned tests, and gates.
- [RAID-REGISTER.md](00-project-charter/RAID-REGISTER.md) (**RAID-001**): Risks, Assumptions, Issues, and Dependencies register.
- [RACI-MATRIX.md](00-project-charter/RACI-MATRIX.md): Roles and accountability matrix.
- [ENGINEERING-GOVERNANCE.md](00-project-charter/ENGINEERING-GOVERNANCE.md): Engineering standards and documentation discipline.
- [GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md](00-project-charter/GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md) (**GOV-MERGE-001**): Narrow controlled merge policy for documentation-only PRs.
- [EXTERNAL-INSPECTION-EVIDENCE-REGISTER-001.md](00-project-charter/EXTERNAL-INSPECTION-EVIDENCE-REGISTER-001.md) (**EVID-EXT-001**): Inventory of Product Owner-supplied external inspection evidence samples.
- [REFERENCE-EVIDENCE-INVENTORY.md](00-project-charter/REFERENCE-EVIDENCE-INVENTORY.md): Inventory of legacy workflow and output reference artifacts.

### 3.2 Readiness Plans, Authority Packages & Historical Audit Snapshots
> [!NOTE]
> Historical audit snapshots and decision packs below are preserved for complete auditability. Where superseded, the canonical active registers above govern current state.
- [IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md](00-project-charter/IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md) (**IER-001**): Consolidated G9/G10 remaining blocker plan.
- [PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md](00-project-charter/PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md) (**PTCM-001**): Technical closure index for `F-03`, `F-04`, and `SES-001`.
- [INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md](00-project-charter/INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md) (**AUTH-001**): Institutional and technical authority approval requests.
- [PRODUCT-OWNER-OPEN-DECISION-PACKET.md](00-project-charter/PRODUCT-OWNER-OPEN-DECISION-PACKET.md) (**POQ-001**): Notification product-semantic decision packet (closed at PO level; outcomes in Decision Register).
- [SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md](00-project-charter/SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md) (**SSOT-AUDIT-001**): Cross-document reconciliation audit and checkpoints.
- [FINAL-DOCUMENTATION-CLOSURE-AUDIT.md](00-project-charter/FINAL-DOCUMENTATION-CLOSURE-AUDIT.md): Historical documentation closure review.
- [PHASE-0-PLAN.md](00-project-charter/PHASE-0-PLAN.md): Historical Phase 0 work plan.
- [PACKAGE-F-CROSS-DOCUMENT-AUDIT.md](00-project-charter/PACKAGE-F-CROSS-DOCUMENT-AUDIT.md): Historical Package F cross-document audit.
- [PACKAGE-G-PO-DECISION-RESOLUTION-PACK.md](00-project-charter/PACKAGE-G-PO-DECISION-RESOLUTION-PACK.md): Historical Package G PO decision resolution pack.
- [PACKAGE-H-FINAL-REQUIREMENTS-ARCHITECTURE-CONSISTENCY-AUDIT.md](00-project-charter/PACKAGE-H-FINAL-REQUIREMENTS-ARCHITECTURE-CONSISTENCY-AUDIT.md): Historical Package H requirements/architecture audit.
- [PACKAGE-I-FINAL-PO-DECISION-AND-SCOPE-FREEZE-PREP.md](00-project-charter/PACKAGE-I-FINAL-PO-DECISION-AND-SCOPE-FREEZE-PREP.md): Historical Package I scope-freeze prep.
- [PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md](00-project-charter/PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md): Historical Package K security/data-integrity audit.
- [PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md](00-project-charter/PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md): Historical Package S audit with dated reconciliation addenda.
- [PACKAGE-T-PO-DECISION-CLOSURE-PACK.md](00-project-charter/PACKAGE-T-PO-DECISION-CLOSURE-PACK.md): Historical Package T decision pack (outcomes recorded in Decision Register).

---

## 4. Product Requirements (`01-product-requirements/` — 5 documents)

- [PRD.md](01-product-requirements/PRD.md): Product Requirements Document covering IFP and Standing Bracket inspection workflows and configurable instruments.
- [ACCEPTANCE-CRITERIA.md](01-product-requirements/ACCEPTANCE-CRITERIA.md): Formal acceptance criteria per requirement.
- [IFP-INSTRUMENT-SPECIFICATION.md](01-product-requirements/IFP-INSTRUMENT-SPECIFICATION.md): Interactive Flat Panel inspection instrument sections, items, and response rules.
- [STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md](01-product-requirements/STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md): Standing Bracket inspection instrument baseline criteria.
- [PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md](01-product-requirements/PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md): Reconciliation of notification requirements (`INS-015`) into PRD scope.

---

## 5. System Architecture & Technical Specifications (`02-architecture/` — 59 documents)

### 5.1 Core Architecture, Runtime Foundation & Security Baseline
- [SYSTEM-ARCHITECTURE.md](02-architecture/SYSTEM-ARCHITECTURE.md): System architecture, Vercel + Supabase modular-monolith topology, and component boundaries.
- [ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md): Approved ADR-001 (Vercel + Supabase PostgreSQL/Auth/RLS/Storage + GitHub).
- [ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md](02-architecture/ADR-002-APPLICATION-RUNTIME-AND-FOUNDATION-STACK.md): Accepted ADR-002 for G9-F1/G10-F1 foundation runtime (Next.js 16 App Router, strict TypeScript, Node 22, `@supabase/ssr`, verified-claims identity, bounded JSON/error/logging primitives, local migration checks).
- [AUTHENTICATION-GOOGLE-OAUTH-SETUP.md](02-architecture/AUTHENTICATION-GOOGLE-OAUTH-SETUP.md): Development-only Google OAuth provider and redirect allow-list setup runbook.
- [DATA-MODEL-AND-ERD.md](02-architecture/DATA-MODEL-AND-ERD.md): Conceptual/logical data model, entity relationships, and core schema rules.
- [PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md](02-architecture/PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md): Proposed physical tables (48 canonical table-name parity; candidate annexes not admitted), constraints, types, and indexes.
- [PHYSICAL-COMMAND-SCHEMA-RECONCILIATION-001.md](02-architecture/PHYSICAL-COMMAND-SCHEMA-RECONCILIATION-001.md): Reconciliation between command contracts and proposed physical schema objects.
- [PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md](02-architecture/PHYSICAL-SCHEMA-RLS-COMMAND-RECONCILIATION.md): Crosswalk reconciling proposed physical tables, RLS policies, and commands.
- [SECURITY-THREAT-MODEL.md](02-architecture/SECURITY-THREAT-MODEL.md): Threat model, trust boundaries, abuse cases, and mitigations.
- [RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md](02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md): PO-approved account lifecycle, role delegation ceiling, SoD, last-admin protection, and explicit non-inheriting scope semantics.
- [CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md](02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md): Proposed canonical permission registry and command authorization matrix (technical certification open).
- [COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md](02-architecture/COMMAND-AUTHORIZATION-VERIFICATION-MATRIX.md): Verification readiness tracker for command-level authorization contracts.
- [RLS-AND-AUTHORIZATION-DESIGN.md](02-architecture/RLS-AND-AUTHORIZATION-DESIGN.md): Row Level Security architecture and deny-by-default authorization design.
- [TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md](02-architecture/TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md): Proposed per-table RLS policy catalogue (static document parity only).
- [T18-EXECUTION-MODEL-SECURITY-REVIEW.md](02-architecture/T18-EXECUTION-MODEL-SECURITY-REVIEW.md): Security review for PO-approved T-18 Option A hybrid execution model.
- [POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md](02-architecture/POSTGRESQL-FUNCTION-SECURITY-AND-EXECUTE-GRANT-DESIGN.md): Function ownership, `search_path`, `SECURITY DEFINER`/`INVOKER`, and exact-signature `EXECUTE` ACL design.
- [PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md](02-architecture/PRIVILEGED-COMMAND-BOUNDARY-AND-TRANSACTION-SPECIFICATION.md): Route-to-PostgreSQL privileged command boundary, caller JWT propagation, and atomic commit/audit rules.
- [API-AND-TRANSACTION-CONTRACTS.md](02-architecture/API-AND-TRANSACTION-CONTRACTS.md): Application API envelope, idempotency, error handling, and transaction contracts.
- [AUDIT-EVENT-CATALOGUE-AND-GOVERNANCE.md](02-architecture/AUDIT-EVENT-CATALOGUE-AND-GOVERNANCE.md): Append-only audit event catalogue (`INS-016` / `T-15`) and privacy exclusions.
- [T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md](02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) (**T19-001**): Historical repository baseline and 2026-11-27 GitHub remote/control-plane re-audit.

### 5.2 Command Contracts, Concurrency & Lock Manifests (`CMD-001` through `CMD-054`)
- [POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md](02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md): Master inventory of all 54 logical IDs (50 application commands + 4 PO-approved external control-plane IDs).
- [CMD-001-054-CROSS-COMMAND-RECONCILIATION.md](02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md): Cross-command reconciliation synthesis across all 54 IDs.
- [COMMAND-PHYSICAL-OBJECT-CROSSWALK-001.md](02-architecture/COMMAND-PHYSICAL-OBJECT-CROSSWALK-001.md): Mapping between logical commands and proposed physical database objects.
- [COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md](02-architecture/COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) (**LOCK-MANIFEST-001**): Per-command candidate transaction and lock-acquisition manifest (`0/50` technically certified).
- [COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md](02-architecture/COMMAND-LOCK-MANIFEST-NORMALIZATION-REGISTER-001.md): Normalization progress register for command lock manifests.
- [GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md](02-architecture/GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) (**LOCK-GRAPH-001**): Candidate global resource lock hierarchy (`L00–L110` plus candidate `L15–L18` identity/authorization classes) and deadlock analysis (`NOT PROVEN ACYCLIC`).
- [LOCK-PROTOCOL-DECISION-RESOLUTION.md](02-architecture/LOCK-PROTOCOL-DECISION-RESOLUTION.md) (**LOCK-PROTOCOL-DECISION-RESOLUTION-001**): Resolution tracker for `LPR-01`–`LPR-11` (`LPR-02`–`LPR-06` PO-approved; technical items open).
- [ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md](02-architecture/ENGINEERING-SECURITY-TECHNICAL-RESOLUTION-PACKAGE-LPR-001-011.md) (**TECH-RESOLUTION-LPR-001**): Technical resolution decomposition for `LPR-01`–`LPR-11` and command closure evidence.
- [CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md](02-architecture/CONCURRENCY-AND-VERSION-TOKEN-RECONCILIATION.md) (**CONCURRENCY-001**): Version-token, compare-and-swap, sequence, and worker lease-fencing reconciliation proposal.
- [AGGREGATE-CONCURRENCY-RESOLUTION-001.md](02-architecture/AGGREGATE-CONCURRENCY-RESOLUTION-001.md): Aggregate-level concurrency and parent-fence analysis.
- **Detailed Command Reviews (engineering proposals — not executable approvals):**
  - [CMD-001-010-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-001-010-DETAILED-CONTRACT-REVIEW.md): Account lifecycle, role/scope grants, and project creation/update/closure.
  - [CMD-011-020-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-011-020-DETAILED-CONTRACT-REVIEW.md) & [PO Package](02-architecture/CMD-011-020-PO-DECISION-AND-ENGINEERING-REVIEW-PACKAGE.md): Session lifecycle, team assignments, Inspector capacity (`T-14`), target plans, and instrument creation/draft/publication.
  - [CMD-021-030-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-021-030-DETAILED-CONTRACT-REVIEW.md): Instrument deactivation, canonical unit/project association/conflict handling, unit claims, inspection draft/submission, and review return.
  - [CMD-031-040-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-031-040-DETAILED-CONTRACT-REVIEW.md): Inspection approval/reopen, evidence upload/finalization, offline sync, document generation, individual/batch printing, and attendance verification.
  - [CMD-041-044-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-041-044-DETAILED-CONTRACT-REVIEW.md): Scoped read/reporting views, audit query, and governed audit export (`T-10` blocked).
  - [CMD-045-048-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-045-048-DETAILED-CONTRACT-REVIEW.md) & [Proposal](02-architecture/CMD-045-048-RESOLUTION-PROPOSAL.md): External control-plane traceability IDs (PO-approved out of application command surface).
  - [CMD-049-054-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-049-054-DETAILED-CONTRACT-REVIEW.md): Notification policy management, outbox/dispatch/worker lifecycle, escalation, and recipient read acknowledgement.

### 5.3 Technical Proposals & Candidate Lifecycle Designs
- [DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md](02-architecture/DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md): Per-operation sync commits (`CMD-035`), document generation lifecycle (`CMD-036`), and durable print-batch manifests (`CMD-038`).
- [DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md](02-architecture/DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md): Monotonic per-document print sequences (`CMD-037`) and PO-approved current-version-only printing (`DOC-003`).
- [INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md](02-architecture/INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md): Candidate mutable draft context separated from immutable submitted revisions.
- [INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md](02-architecture/INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md): Candidate persisted Reviewer assignment entity.
- [REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md](02-architecture/REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md): Candidate single terminal-decision-per-revision arbiter for return vs approval.

### 5.4 Notification Architecture (`NLA-001`)
- [NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md](02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) (**NLA-001**): `INS-015` lifecycle reconciled to approved `POQ-01..03` product semantics; technical/worker/provider controls open.
- [NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md](02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) (**NLA-L05-TDR-001**): Candidate selector grammar, dispatch matrix, suppression/retry taxonomy, audit evidence, and atomic snapshot boundary (`F05-T1..T5`).
- [NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md](02-architecture/NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md): Triage of candidate notification events.
- [NOTIFICATION-EVENT-REGISTRY-001.md](02-architecture/NOTIFICATION-EVENT-REGISTRY-001.md): Candidate notification event registry (`NREG-001..011`, all not enabled).
- [NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md](02-architecture/NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md): Technical reconciliation of candidate event producers and contracts.
- [NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md](02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md): Lock-set review for notification recipient resolution (`0/40` certified).
- [L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md](02-architecture/L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md): Candidate eligibility-writer participation matrix (`F-04`, `0` writers certified).
- [L05-EVENT-TO-SELECTOR-REGISTRY-001.md](02-architecture/L05-EVENT-TO-SELECTOR-REGISTRY-001.md): Candidate event-to-selector mapping registry.
- [L05-SOURCE-EVENT-PATH-MAPPING-001.md](02-architecture/L05-SOURCE-EVENT-PATH-MAPPING-001.md): Candidate source-event producer path mapping.

### 5.5 Evidence, Operations, Provider & Recovery Runbooks
- [EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md](02-architecture/EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md): Private Storage upload-intent, verification, immutable originals, signed URLs, and orphan cleanup design.
- [EVIDENCE-PRIVACY-RETENTION-DELETION-AND-RECOVERY.md](02-architecture/EVIDENCE-PRIVACY-RETENTION-DELETION-AND-RECOVERY.md): Evidence privacy, retention, legal hold, and disposition governance (`T-10` institutional policy blocked).
- [PERFORMANCE-AND-OPERATIONS-BASELINE.md](02-architecture/PERFORMANCE-AND-OPERATIONS-BASELINE.md): 100-concurrent-user acceptance load profile, operational baseline, and open numeric SLOs.
- [BACKUP-RESTORE-AND-DISASTER-RECOVERY-PLAN.md](02-architecture/BACKUP-RESTORE-AND-DISASTER-RECOVERY-PLAN.md): PostgreSQL and Storage backup/restore plan and required unexecuted restore drills.
- [PRODUCTION-ENVIRONMENT-SECRETS-AND-PROVIDER-GOVERNANCE.md](02-architecture/PRODUCTION-ENVIRONMENT-SECRETS-AND-PROVIDER-GOVERNANCE.md): Environment separation, secret boundaries, and provider ownership governance (`T-12` blocked).
- [SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md](02-architecture/SUPABASE-LIVE-DATABASE-SECURITY-INVENTORY-RUNBOOK.md): Runbook for live PostgreSQL schema, grants, RLS, and function privilege inventory (not executed).

---

## 6. Functional Design (`03-functional-design/` — 5 documents)

- [INSPECTION-LIFECYCLE-AND-CLAIMS.md](03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md): Session-bound inspection attempts, per-unit claims, immutable submitted revisions, `RETURNED_FOR_CORRECTION`, `APPROVED`, privileged reopen, and the narrow `SES-001` packed-unit `ABORTED` exception.
- [OFFLINE-SYNC-AND-RECOVERY.md](03-functional-design/OFFLINE-SYNC-AND-RECOVERY.md): Bounded offline draft editing for already-claimed units (`T-09` Option B), idempotent synchronization, and explicit conflict preservation/resolution (never silent overwrite).
- [PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md](03-functional-design/PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md): Project/session lifecycle (`DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`), location/instrument configuration, team assignments, and `T-14` Inspector capacity.
- [RBAC-AND-AUTHORIZATION.md](03-functional-design/RBAC-AND-AUTHORIZATION.md): Functional roles, explicit non-inheriting scopes, account approval, and separation of duties reconciled to `RBAC-003`.
- [REPORTS-DOCUMENTS-AND-AUDIT.md](03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md): Separate actual vs target reports, PDF generation, per-document/batch print events (`T-13`, `DOC-002`, `DOC-003`), and append-only audit (`INS-016`).

---

## 7. User Experience & Design System (`03-ux/` — 3 documents)

- [DESIGN-SYSTEM-AND-RESPONSIVE-UX.md](03-ux/DESIGN-SYSTEM-AND-RESPONSIVE-UX.md): Typography, color palette, responsive breakpoints, and mobile-first inspector layout.
- [INFORMATION-ARCHITECTURE-AND-NAVIGATION.md](03-ux/INFORMATION-ARCHITECTURE-AND-NAVIGATION.md): App sitemap, route tree, navigation structure, and role-based UI visibility (never authorization).
- [SCREEN-FLOWS-AND-WIREFRAME-SPEC.md](03-ux/SCREEN-FLOWS-AND-WIREFRAME-SPEC.md): Step-by-step wireframe flows for Inspector, Reviewer, Korlap, Print Officer, and Super Admin screens.

---

## 8. Quality Assurance & Testing (`04-quality/` — 5 documents)

- [TEST-STRATEGY-AND-QUALITY-GATES.md](04-quality/TEST-STRATEGY-AND-QUALITY-GATES.md): Quality gates, risk-based test tiers (unit, integration, RLS, concurrency, negative auth, offline, recovery), and acceptance criteria.
- [TEST-CASE-CATALOG-AND-UAT.md](04-quality/TEST-CASE-CATALOG-AND-UAT.md): Planned verification and UAT test-case specifications (`PLANNED / NOT EXECUTED` unless backed by an exact execution record).
- [INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md](04-quality/INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md): Item-by-item verification matrix against IFP and Standing Bracket instrument requirements.
- [CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md](04-quality/CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md): Pre-implementation technical certification assessment across domains.
- [L05-TECHNICAL-REVIEW-001.md](04-quality/L05-TECHNICAL-REVIEW-001.md): Technical review of the L05 notification audience-guard candidate specification.

---

## 9. Current Delivery Gate Status (Summary)

```
[Phase 0] -> [G9-F1 Frozen] -> [G10-F1 Foundation Active] -> [Full-system G9 (Pending)] -> [Production G12 (Pending)]
```

- **G9-F1 Foundation Scope Freeze:** **FROZEN** (2026-11-25)
- **G10-F1 Foundation Implementation:** **ACTIVE** (Authorized on dedicated feature branch using synthetic data only; `AGENTS.md` §3.2)
- **Full-system G9 Scope Freeze:** **NOT READY** (Business command handlers, physical schema/RLS/grants, lock certification, provider accounts, and live DB remain gated)
- **Production Readiness:** **NOT VERIFIED**
