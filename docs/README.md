# Master Documentation Index & Architecture Map — Dit. SD Inspection

**Document ID:** DOC-MAP-001  
**Version:** 1.0.0  
**Status:** CONTROLLED MASTER DOCUMENTATION MAP  
**Applies to:** Repository `itswork-app/dit-sd-inspection`  
**Governing Authority:** [AGENTS.md](../AGENTS.md) v1.2.5 & [Master Implementation Blueprint (MIB-001)](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md)

---

## 1. Documentation Overview & Single Source of Truth (SSOT)

This repository serves as both the **authoritative documentation repository** and the **application implementation repository**.
Currently, documentation is organized into 6 functional directories containing 106 controlled documents.

### Precedence Hierarchy (Source of Truth)
When interpreting requirements, design, or architecture, adhere strictly to the following precedence hierarchy (defined in [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) §2):
1. **Product Owner Decisions & Approved Register:** [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md)
2. **Approved Product Requirements & Instrument Specifications:** [PRD.md](01-product-requirements/PRD.md)
3. **Approved Architecture Decision Records (ADRs):** [02-architecture/ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md)
4. **Governing Blueprints & Roadmaps:** [MIB-001](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md), [DGA-001](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md), [IRG-001](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md)
5. **Detailed Specifications:** Architecture, Domain, Security, API, Functional Design, and QA.
6. **Historical Audit Packages & Working Proposals:** Informative background only; non-authoritative when superseded by higher registers.

---

## 2. Document Classification Matrix

| Directory | Scope | Canonical SSOT Files | Supporting / Historical / Proposals |
|---|---|---|---|
| [`00-project-charter/`](#3-project-charter--governance) | Governance, Charter, Gates & Traceability | `PROJECT-CHARTER.md`, `DECISION-REGISTER.md`, `MIB-001`, `DGA-001`, `IRG-001`, `RTM-001`, `RAID-REGISTER.md`, `RACI-MATRIX.md`, `ENGINEERING-GOVERNANCE.md` | Historical Audit Packages (`PACKAGE-F` through `PACKAGE-T`, `PHASE-0-PLAN.md`, `SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md`) |
| [`01-product-requirements/`](#4-product-requirements) | Functional Requirements & Instrument Specs | `PRD.md`, `ACCEPTANCE-CRITERIA.md`, `IFP-INSTRUMENT-SPECIFICATION.md`, `STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md` | `PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md` |
| [`02-architecture/`](#5-system-architecture--technical-specifications) | Architecture, Database, Security, Commands & Locks | `SYSTEM-ARCHITECTURE.md`, `ADR-001`, `DATA-MODEL-AND-ERD.md`, `PHYSICAL-DATABASE-SCHEMA...`, `SECURITY-THREAT-MODEL.md`, `RBAC-003...`, `COMMAND-LEVEL-LOCK-MANIFEST...`, `GLOBAL-LOCK-ORDER...`, `POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md` | 7 Detailed Command Reviews (`CMD-001`..`054`), Proposals (Durable Ledger, Print Sequence, Review Arbiter, etc.), Notification sub-registries |
| [`03-functional-design/`](#6-functional-design) | Domain Business Workflows & Session Lifecycles | `INSPECTION-LIFECYCLE-AND-CLAIMS.md`, `PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md`, `OFFLINE-SYNC-AND-RECOVERY.md`, `RBAC-AND-AUTHORIZATION.md`, `REPORTS-DOCUMENTS-AND-AUDIT.md` | Supporting domain narratives |
| [`03-ux/`](#7-user-experience--design-system) | UI/UX, Navigation & Screen Wireframes | `DESIGN-SYSTEM-AND-RESPONSIVE-UX.md`, `INFORMATION-ARCHITECTURE-AND-NAVIGATION.md`, `SCREEN-FLOWS-AND-WIREFRAME-SPEC.md` | UI wireframes and token tables |
| [`04-quality/`](#8-quality-assurance--testing) | QA Strategy, Test Catalogs & Verification | `TEST-STRATEGY-AND-QUALITY-GATES.md`, `TEST-CASE-CATALOG-AND-UAT.md`, `INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md`, `CERT-001...` | `L05-TECHNICAL-REVIEW-001.md` |

---

## 3. Project Charter & Governance (`00-project-charter/`)

### 3.1 Active Baseline Registers (Living SSOT)
- [PROJECT-CHARTER.md](00-project-charter/PROJECT-CHARTER.md): Project charter, stakeholder context, business objectives.
- [MASTER-IMPLEMENTATION-BLUEPRINT.md](00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md) (**MIB-001**): Governance model, gate criteria G0–G12, source-of-truth definitions.
- [DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md](00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) (**DGA-001**): Active audit queue tracking all open blocking items (B01–B22).
- [DECISION-REGISTER.md](00-project-charter/DECISION-REGISTER.md): Official Product Owner decisions (POQ, DOC, RBAC, etc.).
- [IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md](00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) (**IRG-001**): Implementation phases I0–I7, gate transitions, SemVer policy.
- [REQUIREMENTS-TRACEABILITY-MATRIX.md](00-project-charter/REQUIREMENTS-TRACEABILITY-MATRIX.md) (**RTM-001**): End-to-end trace from requirements to commands, tests, and evidence.
- [RAID-REGISTER.md](00-project-charter/RAID-REGISTER.md) (**RAID-001**): Risks, Assumptions, Issues, Dependencies index.
- [RACI-MATRIX.md](00-project-charter/RACI-MATRIX.md): Roles and accountability matrix.
- [ENGINEERING-GOVERNANCE.md](00-project-charter/ENGINEERING-GOVERNANCE.md): Engineering standards and documentation discipline.
- [GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md](00-project-charter/GOVERNANCE-DOCUMENTATION-ONLY-MERGE-EXCEPTION.md) (**GOV-MERGE-001**): Controlled rules for documentation-only merges before G10.

### 3.2 Historical Audit Snapshots (Archival / Contextual)
> [!NOTE]
> The following documents represent dated audit snapshots and decision resolution packets from earlier review cycles. While preserved for complete audit trails, their conclusions are superseded by the canonical registers above.
- `PACKAGE-F-CROSS-DOCUMENT-AUDIT.md` (Package F audit baseline)
- `PACKAGE-G-PO-DECISION-RESOLUTION-PACK.md` (Package G resolution pack)
- `PACKAGE-H-FINAL-REQUIREMENTS-ARCHITECTURE-CONSISTENCY-AUDIT.md` (Package H audit)
- `PACKAGE-I-FINAL-PO-DECISION-AND-SCOPE-FREEZE-PREP.md` (Package I prep)
- `PACKAGE-K-SECURITY-DATA-INTEGRITY-PRODUCTION-READINESS-AUDIT.md` (Package K security audit)
- `PACKAGE-S-FINAL-CROSS-DOCUMENT-AUDIT-AND-SCOPE-FREEZE-READINESS.md` (Package S snapshot)
- `PACKAGE-T-PO-DECISION-CLOSURE-PACK.md` (Package T decision pack)
- `PHASE-0-PLAN.md` (Initial Phase 0 roadmap)
- `FINAL-DOCUMENTATION-CLOSURE-AUDIT.md` (Historical closure review)
- `SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md` (**SSOT-AUDIT-001**)
- `PRE-IMPLEMENTATION-TECHNICAL-CLOSURE-MATRIX.md`
- `IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md`
- `INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md` (**AUTH-001**)
- `PRODUCT-OWNER-OPEN-DECISION-PACKET.md` (**POQ-001**)

---

## 4. Product Requirements (`01-product-requirements/`)

- [PRD.md](01-product-requirements/PRD.md): Product Requirements Document covering IFP and Standing Bracket inspections.
- [ACCEPTANCE-CRITERIA.md](01-product-requirements/ACCEPTANCE-CRITERIA.md): Formal user acceptance criteria per requirement.
- [IFP-INSTRUMENT-SPECIFICATION.md](01-product-requirements/IFP-INSTRUMENT-SPECIFICATION.md): Interactive Flat Panel inspection instrument sections, items, and response rules.
- [STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md](01-product-requirements/STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md): Standing Bracket inspection instrument criteria.
- [PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md](01-product-requirements/PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md): Reconciliation of notification requirements (INS-015) into PRD scope.

---

## 5. System Architecture & Technical Specifications (`02-architecture/`)

### 5.1 Core Architecture & Security Foundation
- [SYSTEM-ARCHITECTURE.md](02-architecture/SYSTEM-ARCHITECTURE.md): System architecture, Vercel + Supabase topology, component boundaries.
- [ADR-001-platform-stack.md](02-architecture/ADR-001-platform-stack.md): Architectural Decision Record 001 (Supabase + Next.js SSR + Vercel).
- [DATA-MODEL-AND-ERD.md](02-architecture/DATA-MODEL-AND-ERD.md): Logical data model, entity relationships, and core schema rules.
- [PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md](02-architecture/PHYSICAL-DATABASE-SCHEMA-AND-INTEGRITY-SPECIFICATION.md): Canonical physical tables, constraints, column types, and indices.
- [SECURITY-THREAT-MODEL.md](02-architecture/SECURITY-THREAT-MODEL.md): Threat modeling, trust boundaries, attack vectors, and mitigations.
- [RLS-AND-AUTHORIZATION-DESIGN.md](02-architecture/RLS-AND-AUTHORIZATION-DESIGN.md) & [TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md](02-architecture/TABLE-BY-TABLE-RLS-POLICY-CATALOGUE.md): Row Level Security baseline and table policies.
- [T18-EXECUTION-MODEL-SECURITY-REVIEW.md](02-architecture/T18-EXECUTION-MODEL-SECURITY-REVIEW.md): Privileged command execution model (T-18 Option A).
- [T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md](02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) (**T19-001**): Repository runtime audit and 2026-11-27 live inspection.
- [RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md](02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md): Approved account state transitions, role classes, and scope enforcement.
- [CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md](02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md): Definitive permission registry.

### 5.2 Command Contracts & Lock Manifests (CMD-001 through CMD-054)
- [POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md](02-architecture/POSTGRESQL-COMMAND-CONTRACT-CATALOGUE.md): Master inventory of all 54 commands, input/output schemas, and atomicity semantics.
- [COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md](02-architecture/COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md) (**LOCK-MANIFEST-001**): Per-command lock acquisition sequence.
- [GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md](02-architecture/GLOBAL-LOCK-ORDER-AND-CONCURRENCY-GRAPH.md) (**LOCK-GRAPH-001**): Concurrency tiers L01–L20 and dead-lock prevention rules.
- [CMD-001-054-CROSS-COMMAND-RECONCILIATION.md](02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md): Global command reconciliation report.
- **Detailed Command Reviews:**
  - [CMD-001-010-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-001-010-DETAILED-CONTRACT-REVIEW.md): Authentication, user provisioning, project/session lifecycle.
  - [CMD-011-020-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-011-020-DETAILED-CONTRACT-REVIEW.md) & [PO Package](02-architecture/CMD-011-020-PO-DECISION-AND-ENGINEERING-REVIEW-PACKAGE.md): Inspection draft creation, checklist item responses, evidence attachments.
  - [CMD-021-030-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-021-030-DETAILED-CONTRACT-REVIEW.md): Finalization, signing, review assignment, review decisions.
  - [CMD-031-040-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-031-040-DETAILED-CONTRACT-REVIEW.md): Offline sync, document generation, printing, batch printing.
  - [CMD-041-044-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-041-044-DETAILED-CONTRACT-REVIEW.md): Project management, assignment re-allocation, template versioning.
  - [CMD-045-048-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-045-048-DETAILED-CONTRACT-REVIEW.md) & [Proposal](02-architecture/CMD-045-048-RESOLUTION-PROPOSAL.md): External control-plane resolution (PO approved: deferred/out of app scope).
  - [CMD-049-054-DETAILED-CONTRACT-REVIEW.md](02-architecture/CMD-049-054-DETAILED-CONTRACT-REVIEW.md): Notification dispatch, candidate queuing, in-app read marks.

### 5.3 Technical Proposals & RFCs
- [DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md](02-architecture/DURABLE-OPERATION-LEDGER-AND-ARTIFACT-LIFECYCLE-PROPOSAL-001.md): Manifest persistence and per-operation commit boundaries.
- [DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md](02-architecture/DOCUMENT-PRINT-SEQUENCE-AND-VERSION-PROPOSAL-001.md): Monotonic print sequences and current-version-only printing policy (DOC-003, merged into main).
- [INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md](02-architecture/INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md)
- [INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md](02-architecture/INSPECTION-REVIEWER-ASSIGNMENT-ENTITY-PROPOSAL-001.md)
- [REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md](02-architecture/REVIEW-DECISION-ARBITER-TECHNICAL-PROPOSAL-001.md)

### 5.4 Notification Architecture (NLA-001)
- [NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md](02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) (**NLA-001**): Approved INS-015 lifecycle (POQ-01..03).
- Sub-specifications:
  - `NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md`
  - `NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md`
  - `NOTIFICATION-EVENT-REGISTRY-001.md` & `NOTIFICATION-EVENT-REGISTRY-TECHNICAL-RECONCILIATION-001.md`
  - `NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md`
  - `L05-ELIGIBILITY-WRITER-PARTICIPATION-MATRIX-001.md`
  - `L05-EVENT-TO-SELECTOR-REGISTRY-001.md`
  - `L05-SOURCE-EVENT-PATH-MAPPING-001.md`

---

## 6. Functional Design (`03-functional-design/`)

- [INSPECTION-LIFECYCLE-AND-CLAIMS.md](03-functional-design/INSPECTION-LIFECYCLE-AND-CLAIMS.md): Inspection states (DRAFT -> SUBMITTED -> UNDER_REVIEW -> APPROVED/REVISION_REQUESTED/REJECTED).
- [OFFLINE-SYNC-AND-RECOVERY.md](03-functional-design/OFFLINE-SYNC-AND-RECOVERY.md): Offline storage, batch submission, conflict resolution (last-write-wins with version guard).
- [PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md](03-functional-design/PROJECT-SESSION-AND-ASSIGNMENT-MODEL.md): School assignment, session windows, inspector assignment.
- [RBAC-AND-AUTHORIZATION.md](03-functional-design/RBAC-AND-AUTHORIZATION.md): Functional user roles, capabilities, and separation of duties.
- [REPORTS-DOCUMENTS-AND-AUDIT.md](03-functional-design/REPORTS-DOCUMENTS-AND-AUDIT.md): Final inspection report generation, BA annexes, and print history.

---

## 7. User Experience & Design System (`03-ux/`)

- [DESIGN-SYSTEM-AND-RESPONSIVE-UX.md](03-ux/DESIGN-SYSTEM-AND-RESPONSIVE-UX.md): Typography, color palette, responsive breakpoints, mobile-first inspector layout.
- [INFORMATION-ARCHITECTURE-AND-NAVIGATION.md](03-ux/INFORMATION-ARCHITECTURE-AND-NAVIGATION.md): App sitemap, route tree, drawer navigation, role-based visibility.
- [SCREEN-FLOWS-AND-WIREFRAME-SPEC.md](03-ux/SCREEN-FLOWS-AND-WIREFRAME-SPEC.md): Step-by-step wireframe flows for inspector, reviewer, and admin screens.

---

## 8. Quality Assurance & Testing (`04-quality/`)

- [TEST-STRATEGY-AND-QUALITY-GATES.md](04-quality/TEST-STRATEGY-AND-QUALITY-GATES.md): Quality gates, test tiers (unit, integration, RLS, concurrency, negative auth), SLOs.
- [TEST-CASE-CATALOG-AND-UAT.md](04-quality/TEST-CASE-CATALOG-AND-UAT.md): Executable test case inventory (TC-AUTH, TC-INSP, TC-SYNC, TC-NOTIF, etc.).
- [INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md](04-quality/INSTRUMENT-REQUIREMENTS-VERIFICATION-MATRIX.md): Item-by-item verification against official Dit. SD instruments.
- [CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md](04-quality/CERT-001-TECHNICAL-CERTIFICATION-ASSESSMENT.md): Pre-implementation certification status across all domains.
- [L05-TECHNICAL-REVIEW-001.md](04-quality/L05-TECHNICAL-REVIEW-001.md): Technical review of L05 notification candidate lock tier.

---

## 9. Current Delivery Gate Status (Summary)

```
[Phase 0] -> [G9-F1 Frozen] -> [G10-F1 Foundation Active] -> [Full-system G9 (Pending)] -> [Production G12 (Pending)]
```

- **G9-F1 Foundation Scope Freeze:** **FROZEN** (2026-11-25)
- **G10-F1 Foundation Implementation:** **ACTIVE** (Authorized on feature branch with synthetic data only)
- **Full-system G9 Scope Freeze:** **NOT READY** (Business command handlers, provider accounts, and live DB remain gated)
- **Production Readiness:** **NOT VERIFIED**
