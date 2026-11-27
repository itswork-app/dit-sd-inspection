# Dit. SD Inspection

Replacement application for the existing inspection workflow used by Direktorat Sekolah Dasar (Dit. SD).

## Initial scope
- Interactive Flat Panel (IFP)
- Standing Bracket

Feature parity first; controlled improvements second. The legacy application is a workflow/output reference only. This is a greenfield project; no legacy source-code or database access is assumed.

## Approved management and technology baseline
- Release target: Production
- Engineering priority: Cost-first
- Web application/PWA hosting and deployment: Vercel
- Backend platform: Supabase (PostgreSQL, Auth, Row Level Security, Storage)
- Source control and CI: GitHub

Cost-first means optimizing total lifecycle cost without waiving security, privacy, data integrity, backup/recovery, or production reliability.

## Status
**Current phase:** Staged foundation implementation (G10-F1 ACTIVE). The repository contains authoritative documentation and is now authorized to receive application implementation. Coding is authorized only for the bounded foundation scope using synthetic/test data.

**Scope freeze / G9-F1:** FOUNDATION SCOPE FROZEN (2026-11-25)  
**Full-system G9:** NOT READY — business-feature gates remain open  
**G10-F1 foundation implementation:** ACTIVE (2026-11-25; PR #26)  
**Full-system / production readiness:** NOT VERIFIED

## Engineering instructions and delivery roadmap
**Mandatory:** Every contributor and coding agent must read the root [AGENTS.md](AGENTS.md) before each new work session and substantive task. If it cannot be read, repository edits must stop. The file defines authority, authorization boundaries, security invariants, implementation workflow, SemVer and reporting rules.

The [Implementation Roadmap and Release Governance](docs/00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) defines pre-implementation phases, G9/G10 authorization, implementation phases I0–I7, release controls and Semantic Versioning 2.0.0.

## Documentation authority and delivery gates
The comprehensive directory map of all 103 controlled documents under `docs/` is provided in the [Master Documentation Index & Architecture Map](docs/README.md).

Start with the [Master Implementation Blueprint](docs/00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md). It defines source-of-truth precedence, non-negotiable engineering invariants, requirement traceability, delivery gates G0–G12, production-readiness evidence, and the next documentation workstreams.

The current [Documentation Gap Audit — Gate Implementation Readiness](docs/00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) is the active closure queue. It records unresolved source, architecture, command, security, operations and verification gaps. The Product Owner owns institutional authorization/coordination; synthetic-data foundation development is not blocked on separate institutional approval artifacts. Do not infer implementation readiness from document count or planned test cases.

The [Decision Register](docs/00-project-charter/DECISION-REGISTER.md) is the index of approved and open Product Owner decisions. The [T-19 Repository Runtime Architecture Audit](docs/02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) is a historical architecture baseline; the current staged foundation implementation status and scope are controlled by this README, root AGENTS.md, MIB-001 and DGA-001.

Notification lifecycle design: [NLA-001 — Notification Lifecycle and Delivery Architecture](docs/02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) documents the approved INS-015 product policy and POQ-01..04 semantics for recipient scope, channels, retries, audit and escalation. Technical selector, snapshot, dispatch, worker, schema, security and runtime admission remain open; this is not implementation authorization.

For the complete proposed command inventory, see the [CMD-001–054 Cross-Command Reconciliation](docs/02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md) and its seven linked detailed command reviews. These are engineering proposals, not executable-contract approval. See docs/00-project-charter/, docs/01-product-requirements/, docs/02-architecture/, docs/03-functional-design/, docs/03-ux/, and docs/04-quality/ for detailed specifications.

## Current cross-document audit and authority requests

The current static reconciliation is recorded in [SSOT-AUDIT-001](docs/00-project-charter/SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md). Unresolved product-semantic questions are separated in [POQ-001](docs/00-project-charter/PRODUCT-OWNER-OPEN-DECISION-PACKET.md); institutional and technical evidence requests are routed in [AUTH-001](docs/00-project-charter/INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md). Package S §9.16 is the current inventory snapshot and §9.17 records the current authorization/gate status; Package T is a historical decision pack and the Decision Register remains the current PO authority. The Product Owner-approved account lifecycle, role delegation and scope governance semantics are specified in [RBAC-003](docs/02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md); physical schema, permission grants, RLS, lock certification and QA remain open.

**Governance:** G10-F1 authorizes bounded foundation source code and development-only schema/migrations on a dedicated feature branch, using synthetic data. It does not authorize unresolved business command handlers, production data, production provider operations, deployment, release or production activation. F-03/F-04 and command/security/physical-schema contracts remain feature-entry gates. GOV-MERGE-001 continues to govern documentation-only merges; code PRs require actual automated checks and maintainer review.


## Foundation branch checkpoint — 2026-11-27

PR #30 (`feat/foundation-bootstrap-v1-rebased`) is OPEN and unmerged. The branch is integrated with `main` through PR #37 (`5b7fdd9`), commits a verified `package-lock.json`, uses reproducible `npm ci --no-audit --no-fund` in `.github/workflows/ci.yml`, activates `src/proxy.ts` for Next.js 16 `src/app/` runtime, preserves `Referrer-Policy: no-referrer` on `/auth/callback`, and passes both the full local quality gate (`npm ci --no-audit --no-fund && npm run check`: ESLint, TypeScript `tsc --noEmit`, migration filename check, 63 Vitest unit tests, 5 Node migration tests, and Next.js 16.4.6 production build) and non-mutating live runtime smoke tests against a development `.env` (Supabase Auth reachable, `external.google = true`, OAuth authorize handshake `302` to Google OAuth2 verified; interactive browser round trip not yet executed). Hosted GitHub Actions execution on PR #30 remains blocked by the repository account's billing/spending limit (GitHub Check Run `140276596713` annotation: *"The job was not started because recent account payments have failed or your spending limit needs to be increased"*). Do not interpret local checks as hosted GitHub Actions CI PASS, full-system G9 readiness, or production readiness.
