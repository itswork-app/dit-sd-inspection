# T-19 Repository Runtime Architecture Audit

**Status:** AUDIT COMPLETE — IMPLEMENTATION ABSENT FROM AUDITED REPOSITORY REFS  
**Audit date:** 2026-11-24  
**Repository:** `itswork-app/dit-sd-inspection`  
**Audited branch:** `docs/t17-instrument-governance-t18-command-boundary`  
**Audited branch HEAD:** `843bef813d55d0e82246052bf498b9f282f55a2a`  
**Default branch:** `main`  
**Scope:** Read-only GitHub repository tree and selected documentation inspection. No source code, configuration, database, CI execution, or deployment was changed or executed.

## 1. Executive finding

The audited repository currently contains **project documentation, not an application implementation**.

The recursive Git tree for the audited branch returned 54 blob files, with only `AGENTS.md`, `README.md`, and the `docs/` hierarchy. A static extension/path inventory found **zero** files with implementation/configuration extensions in the searched set (`.ts`, `.tsx`, `.js`, `.jsx`, `.sql`, `.prisma`, `.json`, `.yaml`, `.yml`, `.toml`, `.kt`, `.go`, `.rs`, `.py`). No source-code directories were present in the tree.

The repository default branch `main` was separately inspected: its recursive tree contained only one blob, `README.md`. Therefore this is not merely a limitation of the active documentation branch; the default branch is also not an application implementation at the audited HEAD.

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

## 4. Architecture risk and required next action

The immediate blocker is not a code defect identified by this audit; it is the absence of implementation artifacts in the audited repository. Do not create placeholder route handlers, migrations, credentials, or a speculative scaffold merely to make this audit pass.

Before implementation begins:

1. Confirm whether this repository is intentionally documentation-only through Phase 0 and whether a separate application repository is planned.
2. If a separate application repository already exists, identify its exact repository and branch; audit that repository before implementation.
3. If this is the intended application repository, obtain explicit scope-freeze approval and then create the implementation baseline in a dedicated implementation branch, following `AGENTS.md`.
4. Add the Vercel app, server-only Supabase client, caller-session propagation, migration directory and automated checks only after the approved design and prerequisites are reconciled.
5. Re-run T-19 against actual source and configuration. Prove JWT propagation via the real HTTP path; static documentation or SQL Editor evidence is insufficient.

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
- Application implementation in audited repository refs: **NOT PRESENT**.
- T-18 Option A architecture decision: **PO APPROVED**.
- T-18 implementation conformance: **NOT VERIFIED**.
- Live Supabase inventory: **NOT EXECUTED**.
- Runtime/CI/deployment tests: **NOT EXECUTED**.
- Scope freeze: **NOT READY**.
- Feature implementation, migrations, grants, deployment and merge: **NOT AUTHORIZED**.

