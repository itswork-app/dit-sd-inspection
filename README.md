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
**Current phase:** Full-System Synthetic Implementation (`G10` ACTIVE — `I1 → I5` implemented on isolated synthetic infrastructure; `G11` PARTIAL (local verification recorded; main-push hosted CI passed on merge commit `ae271615`, but `main` ruleset enforcement is disabled; managed restore/staging SLO/real-device UAT remain open); `G12` production readiness remains BLOCKED). Coding is authorized only for isolated local/development environments using synthetic/test data.

**Scope freeze / G9-F1:** FOUNDATION SCOPE FROZEN (2026-11-25)  
**Full-system technical SSOT (`G9-TECH`):** FROZEN (2026-11-27; `PO-2026-11-27-G9-TECH-G10-SYNTHETIC-001` — 14/14 technical DGA blockers closed; 62 canonical tables, 62/62 RLS parity & 52 app commands reconciled)  
**G10 full-system synthetic implementation:** ACTIVE (2026-11-27; local `I1 → I5` slices implemented: 13 SQL migrations, `62/62` `ENABLE + FORCE RLS`, `T-18` `NOLOGIN` wrappers, private Storage RLS + PDF 1.4 renderer, 68 Next.js routes, synthetic data only)  
**G11 verification:** LOCAL SYNTHETIC SUITE PASS (unit/migration/build, SQL RLS/SoD/CAS/idempotency verifiers, multi-connection PostgreSQL concurrency races, live HTTP/JWT E2E, live Private Storage + PDF E2E, local backup/restore rehearsal, local 100-request load baseline — see `DGA-001` §§22–23); main-push GitHub Actions CI **PASS on merge commit `ae271615` (run #93)**, but repository `main` ruleset **DISABLED (`DGA-B15`)**; managed-provider restore (`DGA-B06`), staging load test/SLO (`DGA-B08`) and real-device UAT (`DGA-B07`) **NOT EXECUTED**  
**G12 production / real institutional data readiness:** NOT VERIFIED / BLOCKED (`DGA-B01..B06`, `B08`, `B15`, written `T-10`/`T-12` approvals)  
**Staging (synthetic only):** AUTHORIZED, NOT YET EXECUTED — Supabase project `emqlbtnejinbqlxpoakd` (`PO-2026-11-27-STAGING-SYNTHETIC-001`, `AGENTS.md` v1.4.0 §3.4)

## Engineering instructions and delivery roadmap
**Mandatory:** Every contributor and coding agent must read the root [AGENTS.md](AGENTS.md) before each new work session and substantive task. If it cannot be read, repository edits must stop. The file defines authority, authorization boundaries, security invariants, implementation workflow, SemVer and reporting rules.

The [Implementation Roadmap and Release Governance](docs/00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) defines pre-implementation phases, G9/G10 authorization, implementation phases I0–I7, release controls and Semantic Versioning 2.0.0.

## Documentation authority and delivery gates

The active G11 execution sequence is controlled by [G11-ECP-001 — G11 Evidence Closure Plan](docs/00-project-charter/G11-EVIDENCE-CLOSURE-PLAN.md).
The comprehensive directory map of all 105 controlled documents under `docs/` is provided in the [Master Documentation Index & Architecture Map](docs/README.md).

Start with the [Master Implementation Blueprint](docs/00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md). It defines source-of-truth precedence, non-negotiable engineering invariants, requirement traceability, delivery gates G0–G12, production-readiness evidence, and the next documentation workstreams.

The current [Documentation Gap Audit — Gate Implementation Readiness](docs/00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) is the active closure queue. It records unresolved source, architecture, command, security, operations and verification gaps. The Product Owner owns institutional authorization/coordination; synthetic-data foundation development is not blocked on separate institutional approval artifacts. Do not infer implementation readiness from document count or planned test cases.

The [Decision Register](docs/00-project-charter/DECISION-REGISTER.md) is the index of approved and open Product Owner decisions. The [T-19 Repository Runtime Architecture Audit](docs/02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) is a historical architecture baseline; the current staged foundation implementation status and scope are controlled by this README, root AGENTS.md, MIB-001 and DGA-001.

Notification lifecycle design: [NLA-001 — Notification Lifecycle and Delivery Architecture](docs/02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md) documents the approved INS-015 product policy and POQ-01..04 semantics for recipient scope, channels, retries, audit and escalation. The technical design baseline is included in the frozen G9-TECH SSOT; local synthetic implementation and verification evidence is tracked in DGA-001. External provider dispatch remains gated by written `T-10`/`T-12` approvals, and hosted/runtime evidence remains subject to G11/G12 gates.

For the complete proposed command inventory, see the [CMD-001–054 Cross-Command Reconciliation](docs/02-architecture/CMD-001-054-CROSS-COMMAND-RECONCILIATION.md) and its seven linked detailed command reviews. These are engineering proposals, not executable-contract approval. See docs/00-project-charter/, docs/01-product-requirements/, docs/02-architecture/, docs/03-functional-design/, docs/03-ux/, and docs/04-quality/ for detailed specifications.

## Current cross-document audit and authority requests

The current static reconciliation is recorded in [SSOT-AUDIT-001](docs/00-project-charter/SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md). Unresolved product-semantic questions are separated in [POQ-001](docs/00-project-charter/PRODUCT-OWNER-OPEN-DECISION-PACKET.md); institutional and technical evidence requests are routed in [AUTH-001](docs/00-project-charter/INSTITUTIONAL-AND-TECHNICAL-AUTHORITY-APPROVAL-PACKAGE.md). Package S §9.16 is the current inventory snapshot and §9.17 records the current authorization/gate status; Package T is a historical decision pack and the Decision Register remains the current PO authority. The Product Owner-approved account lifecycle, role delegation and scope governance semantics are specified in [RBAC-003](docs/02-architecture/RBAC-003-ACCOUNT-LIFECYCLE-AND-ROLE-SCOPE-GOVERNANCE.md); physical schema, permission grants, RLS, lock certification and QA remain open.

**Governance:** `G10` Full-System Synthetic Implementation (`AGENTS.md` v1.4.0 §3, §3.3 & §3.4) authorizes ordered `I1 → I5` engineering implementation and local verification on dedicated feature branches using synthetic/test data only, plus bounded synthetic staging solely on Supabase project `emqlbtnejinbqlxpoakd` (`PO-2026-11-27-STAGING-SYNTHETIC-001`). It strictly prohibits real institutional personal/evidence data, production deployment, staging/hosted database mutation outside §3.4, enabling `CMD-044` (`export-audit`) or external notification provider dispatch adapters (`CMD-053` email/push / `INT-NOTIF-001`) prior to written `T-10`/`T-12` approvals, and creating any application surface for PO-excluded external control-plane IDs `CMD-045..048`. `GOV-MERGE-001` continues to govern documentation-only merges; code PRs require actual automated checks and documented solo-maintainer review.


## Historical foundation branch checkpoint — 2026-11-27

## Historical post-merge audit checkpoint (pre-PR #42) — 2026-11-27

PRs #38–#41 are merged to `main`; audited `main` HEAD is `706c654a17d415913892b64fe71de59c2a09bafe`. Current gate state: `G9-F1`/`G9-TECH` FROZEN; `G10` ACTIVE with `I1→I5` implemented on synthetic local/development infrastructure; `G11` PARTIAL; `G12` NOT VERIFIED / BLOCKED. PR #41 records 68 Next.js build routes (the 67-route count in the older feature-branch checkpoint below is historical evidence from that earlier build).

The local backup/restore rehearsal and local burst load baseline are documented in DGA-001 §23. They do not close managed-provider restore (`DGA-B06`) or staging SLO/load (`DGA-B08`). Real-device offline UAT (`DGA-B07`) remains NOT EXECUTED. The initial audit wrapper exposed only PR-triggered workflow runs and missed the main-push run. A direct Actions API query later identified main-push run #77 (`45953256570`) on `706c654`, completed SUCCESS; its Quality checks job and `npm run check` step passed. The combined commit-status endpoint returned no entries; that is not evidence that the workflow did not run.

See [PMA-001 — Post-Merge Repository Audit](docs/00-project-charter/POST-MERGE-REPOSITORY-AUDIT-2026-11-27.md) for the historical post-merge findings. PR #42 is merged; current CI and G11 evidence are recorded in the checkpoint below.



PR #30 (`feat/foundation-bootstrap-v1-rebased`) is OPEN and unmerged. The branch is integrated with `main` through PR #37 (`5b7fdd9`), commits a verified `package-lock.json`, uses reproducible `npm ci --no-audit --no-fund` in `.github/workflows/ci.yml`, activates `src/proxy.ts` for Next.js 16 `src/app/` runtime, preserves `Referrer-Policy: no-referrer` on `/auth/callback`, disables `next dev` auto-modification of `AGENTS.md` (`agentRules: false`), and passes the full local quality gate (`npm ci --no-audit --no-fund && npm run check`), non-mutating live runtime smoke tests, and interactive development Google OAuth sign-in/sign-out round trip against `.env` (deny-by-default `/auth/pending` verified). Hosted GitHub Actions execution on PR #30 remains blocked by the repository account's billing/spending limit (GitHub Check Run `140276596713` annotation: *"The job was not started because recent account payments have failed or your spending limit needs to be increased"*). Do not interpret local checks as hosted GitHub Actions CI PASS, full-system G9 readiness, or production readiness.

## Historical full-system synthetic implementation & local G11 checkpoint — 2026-11-27

Following PO/sole-maintainer sign-off `PO-2026-11-27-G9-TECH-G10-SYNTHETIC-001` (`AGENTS.md` v1.3.0), all four synthetic implementation slices (`I1 → I5`), local `G11` multi-connection concurrency & HTTP/JWT E2E suites, and private Supabase Storage + deterministic `%PDF-1.4` integration were implemented and locally verified on stacked branches culminating in `feat/i4-storage-and-pdf-renderer`:

- **Database & Security:** `13` immutable SQL migrations (`20261127050000`–`20261127090000`) provisioning `62/62` canonical `public` tables with `62/62` `ENABLE + FORCE RLS`, `T-18` `NOLOGIN NOBYPASSRLS NOINHERIT` function owners (`app_cmd_definer`/`app_worker_definer`), `CMD-001..043` / `CMD-049..052` / `CMD-054..056` wrappers, private Storage bucket `inspection-private` RLS (immutable originals, caller-JWT signed upload/download, audited `evidence.accessed` / `document.accessed`), and **zero** application surfaces for `CMD-044`, external `CMD-053` providers, or `CMD-045..048`.
- **Local Verification Executed (PASS):** `npm run check` (ESLint `0` errors, `tsc --noEmit` `0` errors, `13` SQL migrations valid, Vitest `14/14` suites / `87/87` tests, Node `5/5` tests, Next.js 16.4.6 production build `67` routes + `ƒ Proxy`), four PostgreSQL RLS/SoD/CAS/idempotency SQL verification scripts, multi-connection PostgreSQL race suite (`scripts/verify-g11-concurrency.mjs`: `LG-01/03`, `LG-16`, `LG-21`, `LG-31`, `LG-33`, `LG-41`), live HTTP/JWT E2E (`scripts/verify-g11-http-e2e.mjs`), and live Private Storage + magic-byte + `%PDF-1.4` E2E (`scripts/verify-g11-storage-pdf-e2e.mjs`).
- **Remaining Blockers / Not Executed (historical feature-branch checkpoint):** The earlier PR #30 hosted runner attempt reported a billing/spending-limit failure. A later main-push run #77 on commit `706c654` passed. Managed backup/restore drills (`DGA-B06`), staging performance/SLO (`DGA-B08`), real-device offline UAT, and institutional/provider approvals (`DGA-B01..B05`, `T-10`, `T-12`) remain **NOT EXECUTED / BLOCKED**.


## Current post-PR #42 G11 evidence checkpoint — 2026-11-27

Current `main` HEAD is `ae271615bacae3c3b48eeaafee72ae1c6829fbf1`. Main-push GitHub Actions run #93 (`45965232365`) completed SUCCESS on this merge commit; its Quality checks job and `npm run check` step passed. [View run #93](https://github.com/itswork-app/dit-sd-inspection/actions/runs/45965232365).

Repository ruleset `main` (ID `28208385`) is currently DISABLED. Therefore CI execution is verified, but branch enforcement is not. G11 remains PARTIAL: managed PostgreSQL + Storage restore, real-device offline UAT, staging SLO/load and case-level execution mapping for the 558-ID QA catalogue remains open; 25 test-source files were scanned and contain no explicit catalogue-ID references. G12 remains NOT VERIFIED / BLOCKED.

See [DGA-001 v2.4.2](docs/00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) and [G11-ECP-001 v1.0.2](docs/00-project-charter/G11-EVIDENCE-CLOSURE-PLAN.md) for the evidence boundaries, execution sequence and acceptance criteria.
