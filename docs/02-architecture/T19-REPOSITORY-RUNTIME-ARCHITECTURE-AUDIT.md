# T-19 Repository Runtime Architecture Audit

**Document ID:** T19-001  
**Version:** 1.1.0  
**Status:** AUDIT COMPLETE — DOCUMENTATION-PHASE BASELINE CONFIRMED; 2026-11-27 RE-AUDIT RECORDED  
**Audit date:** 2026-11-24  
**Re-audit date:** 2026-11-27  
**Repository:** `itswork-app/dit-sd-inspection`  
**Original audited branch:** `docs/t17-instrument-governance-t18-command-boundary`  
**Original audited branch HEAD:** `843bef813d55d0e82246052bf498b9f282f55a2a`  
**Default branch:** `main`  
**Current default-branch HEAD at re-audit:** `44dce2cbcc052c6e909e1b0a080062a5b60d94eb`  
**Scope:** Read-only GitHub repository tree, selected documentation inspection, and 2026-11-27 live GitHub settings/workflow inspection. No application source, database, provider account, or production system was changed.

## 1. Executive finding

The audited repository currently contains **project documentation, not an application implementation**. Following the Product Owner clarification on 2026-11-24, this is intentional: the repository is the single home for both authoritative documentation and the future application, but the current authorized phase is documentation/SSOT maturation. The absence of application source code is therefore not a defect or a request to scaffold code now.

The recursive Git tree for the audited branch returned 54 blob files, with only `AGENTS.md`, `README.md`, and the `docs/` hierarchy. A static extension/path inventory found **zero** files with implementation/configuration extensions in the searched set (`.ts`, `.tsx`, `.js`, `.jsx`, `.sql`, `.prisma`, `.json`, `.yaml`, `.yml`, `.toml`, `.kt`, `.go`, `.rs`, `.py`). No source-code directories were present in the tree.

The repository default branch `main` was separately inspected: its recursive tree contained only one blob, `README.md`. Therefore this is not merely a limitation of the active documentation branch; the default branch is also not an application implementation at the audited HEAD. This confirms the repository's current documentation-first state; it does not establish a defect against the agreed delivery sequence.

## 2. Evidence

| Check | Observed result | Interpretation |
|---|---|---|
| Active branch recursive tree | 54 blobs; top-level entries `AGENTS.md`, `README.md`, `docs/` | Documentation-only branch |
| Source/config extension scan | 0 matching implementation/config files | No route/client/migration source found |
| Default branch recursive tree | 1 blob: `README.md` | No application code on `main` at audited ref |
| README | Declares greenfield replacement; Vercel + Supabase baseline; Phase 0 foundation | Confirms intended architecture, not implementation |
| AGENTS.md | Requires migrations in repository and prohibits feature work before gates | Governance instruction, not implementation evidence |
| ADR-001 | Accepts Supabase + Vercel and caller/server authorization constraints | Approved target architecture only |

This audit is limited to the repository refs and tree content inspected on 2026-11-24. It does not establish whether application code exists in another repository, untracked local workspace, private deployment artifact, or external environment.

## 3. T-18 implementation evidence disposition

Because no application source or configuration exists in the audited refs, none of the following can be verified:

- Vercel project configuration, framework/build output, serverless runtime, route handlers or deployment protection.
- Supabase client initialization, server/browser client separation, cookie/session handling, token refresh or caller JWT forwarding.
- Whether the server route forwards the caller JWT unchanged to PostgREST RPC.
- Whether service-role credentials are absent from browser bundles and whether any server route substitutes service_role for the caller.
- PostgreSQL migrations, schema/function definitions, SECURITY DEFINER owner, `search_path`, exact EXECUTE ACLs, RLS policies or table grants.
- Route-to-command mapping, request/response schemas, idempotency implementation, transaction boundaries or audit atomicity.
- Unit, integration, authorization, concurrency, end-to-end or deployment tests.

**Important:** The T-18 Option A execution model remains PO APPROVED as a design decision. Its implementation and conformance are **NOT VERIFIED**, not PASS.

## 4. Architecture evidence boundary and required next action

The audit does not identify a current implementation defect because implementation is intentionally not started. The risk is premature implementation before the SSOT and scope-freeze gates are closed. Do not create placeholder route handlers, migrations, credentials, or a speculative scaffold merely to make this audit pass.

Before implementation begins:

1. Repository intent is now confirmed: this repository will contain both the documentation SSOT and the future application.
2. Continue documentation-only work under `docs/00-project-charter/MASTER-IMPLEMENTATION-BLUEPRINT.md` and the documented gate sequence.
3. Complete cross-document reconciliation, requirement traceability, institutional approvals and technical contract closure before requesting scope freeze.
4. Obtain a separate explicit implementation authorization before creating application source, migrations, routes or deployment configuration.
5. Once implementation is authorized and artifacts exist, re-run the runtime audit against actual source and configuration. Prove caller JWT propagation through the real HTTP path; static documentation or SQL Editor evidence is insufficient.

No secrets, access tokens, service-role keys, database URLs or personal data should be committed or pasted into chat.

## 5. QA allocation

The QA catalogue adds `TC-REPO-AUDIT-028-001..008` for:
- repository/source presence and intended repository identity;
- Vercel route/runtime configuration;
- browser/server Supabase client separation;
- caller JWT propagation and service-role non-substitution;
- migration inventory and exact function/grant review;
- route-to-command contract mapping;
- automated security/integration coverage;
- reproducible build/deployment evidence.

All eight cases are **BLOCKED / NOT EXECUTED** because the corresponding implementation artifacts are absent from the audited refs. They are not passing tests.

## 6. Status

- Repository tree audit: **COMPLETE** for the inspected refs.
- Application implementation in audited repository refs: **INTENTIONALLY NOT STARTED IN CURRENT PHASE**.
- T-18 Option A architecture decision: **PO APPROVED**.
- T-18 implementation conformance: **NOT VERIFIED**.
- Live Supabase inventory: **NOT EXECUTED**.
- Runtime/CI/deployment tests: **NOT EXECUTED**.
- Documentation/SSOT maturation: **IN PROGRESS**.
- Scope freeze: **NOT READY**.
- Feature implementation, migrations, grants and deployment: **NOT AUTHORIZED**.
- Repository purpose (documentation and future application in one repository): **CONFIRMED BY PRODUCT OWNER, 2026-11-24**.

## 7. Re-audit of GitHub remote and default-branch tree — 2026-11-27

This addendum supersedes only the dated file-count and GitHub-settings observations below. Sections 1–6 remain the 2026-11-24 historical snapshot. They must not be cited as the current `main` inventory.

**Method:** read-only `gh` inspection of `itswork-app/dit-sd-inspection` as account `itswork-app`, plus local clone of `main` at `44dce2c`. Org audit-log API is unavailable because the owner is a GitHub **User**, not an Organization.

### 7.1 Default-branch tree

| Check | 2026-11-24 snapshot | 2026-11-27 observation |
|---|---|---|
| `main` recursive blobs | 1 (`README.md`) | **102** blobs |
| Top-level entries | `README.md` | `AGENTS.md`, `README.md`, `docs/` |
| Implementation/config extensions (`.ts`, `.tsx`, `.js`, `.jsx`, `.sql`, `.prisma`, `.json`, `.yaml`, `.yml`, `.toml`, `.kt`, `.go`, `.rs`, `.py`) on `main` | 0 | **0** |
| Canonical repository identity | Confirmed PO intent | Unchanged: `itswork-app/dit-sd-inspection`, private, default `main` |

`main` is now the documentation SSOT, not a README-only stub. Absence of application source on `main` remains intentional for the documentation baseline. Foundation source, if any, lives only on the unmerged feature PR and is **not** present on `main`.

### 7.2 GitHub control-plane evidence (DGA-B15)

| Control | Observation | Disposition |
|---|---|---|
| Visibility | Private | Confirmed |
| Collaborators | `itswork-app` admin only; no teams | Confirmed solo-maintainer |
| Branch protection / rulesets | API 403: not available on GitHub Free + private repository | **NOT CONFIGURABLE on current plan** |
| Dependabot / vulnerability / code / secret scanning | Disabled | **NOT ENABLED** |
| GitHub Pages, deploy keys, webhooks, Actions secrets, environments | Absent | Confirmed |
| Actions permissions | Enabled; `allowed_actions: all`; SHA pinning not required; default workflow token **read** | Enabled, not hardened |
| `delete_branch_on_merge` | Enabled 2026-11-27 | Confirmed |
| Default-branch HEAD commits | Latest `main` commits include verified signatures; older commits include unsigned | Mixed |
| Orphan workflow `bootstrap-npm-lockfile.yml` | File absent on current foundation PR; workflow disabled 2026-11-27 | Disabled |

Branch hygiene 2026-11-27: 34 merged/closed remote heads deleted. Remaining heads: `main`, four open documentation PRs (`docs/cmd-035`…`cmd-038` = PR #32–#35), and `feat/foundation-bootstrap-v1-rebased` (PR #30). Historical names `feat/foundation-bootstrap-v1` and PR #28 are closed/deleted and must not be cited as current.

### 7.3 CI execution evidence

PR #30 workflow `.github/workflows/ci.yml` exists on the foundation branch. Re-run of Actions run `45732607600` on 2026-11-27 still concluded **failure in ~5 seconds** with empty `runner_name`, empty job steps, and no job logs (`BlobNotFound`). This is **runner provisioning failure**, not an npm/lint/test result. It is **not PASS** and does not satisfy DGA-B15 required-check evidence.

### 7.4 Gate impact

- G9-F1 / G10-F1 remain as recorded in root `AGENTS.md` §3.2.
- Full-system G9 remains **NOT READY**.
- Production readiness remains **NOT VERIFIED**.
- T-18 implementation conformance remains **NOT VERIFIED**.
- TC-REPO-AUDIT-028-001 repository identity is **PARTIAL** (canonical repo confirmed; `main` tree inventoried). TC-REPO-AUDIT-028-002..008 remain **BLOCKED / NOT EXECUTED**.
- DGA-B15 is **PARTIAL — SETTINGS INSPECTED; REQUIRED CHECKS NOT PASSED**. Live branch protection cannot be created on the current GitHub plan; Actions hosted runners did not start.

