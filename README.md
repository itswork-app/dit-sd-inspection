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
**Current phase:** Documentation / SSOT maturation. The repository is intentionally documentation-first and will contain both the authoritative documentation and the future application. Application source code is not yet authorized or started.

**Scope freeze:** NOT READY  
**Implementation authorization:** NOT GRANTED  
**Production readiness:** NOT VERIFIED

## Engineering instructions and delivery roadmap
**Mandatory:** Every contributor and coding agent must read the root [AGENTS.md](AGENTS.md) before each new work session and substantive task. If it cannot be read, repository edits must stop. The file defines authority, authorization boundaries, security invariants, implementation workflow, SemVer and reporting rules.

The [Implementation Roadmap and Release Governance](docs/00-project-charter/IMPLEMENTATION-ROADMAP-AND-RELEASE-GOVERNANCE.md) defines pre-implementation phases, G9/G10 authorization, implementation phases I0–I7, release controls and Semantic Versioning 2.0.0.

## Documentation authority and delivery gates
Start with the [Master Implementation Blueprint](docs/00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md). It defines source-of-truth precedence, non-negotiable engineering invariants, requirement traceability, delivery gates G0–G12, production-readiness evidence, and the next documentation workstreams.

The current [Documentation Gap Audit — Gate Implementation Readiness](docs/00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) is the active closure queue. It records unresolved source, institutional, architecture, command, security, operations and verification gaps. Do not infer implementation readiness from document count or planned test cases.

The [Decision Register](docs/00-project-charter/DECISION-REGISTER.md) is the index of approved and open Product Owner decisions. The [T-19 Repository Runtime Architecture Audit](docs/02-architecture/T19-REPOSITORY-RUNTIME-ARCHITECTURE-AUDIT.md) records why the current absence of application source is intentional during this phase.

See docs/00-project-charter/, docs/01-product-requirements/, docs/02-architecture/, docs/03-functional-design/, docs/03-ux/, and docs/04-quality/ for detailed specifications.

**Governance:** No application code, migrations, SQL execution, grants/revokes, live database changes, deployment, or production activation before scope freeze and separate explicit implementation authorization.
