# Governance Decision — Documentation-Only Merge Exception

**Decision ID:** GOV-MERGE-001  
**Decision date:** 2026-11-25  
**Authority:** Product Owner  
**Status:** PO APPROVED  
**Applies to:** `itswork-app/dit-sd-inspection`

## Decision

The Product Owner approves a narrow exception to the repository's pre-G10 merge prohibition: documentation-only changes may be merged into the default branch before G10 activation, subject to every control in this record.

This is a controlled governance exception. It does not activate G10, establish G9 readiness, freeze product scope, or authorize application implementation.

## Permitted changes

Only changes whose complete diff consists of non-executable project documentation and governance artifacts may use this exception, including PRDs, ADRs, decision records, architecture specifications, threat models, QA catalogues, traceability records, and repository governance documentation.

A PR is not eligible if it contains application source code, executable scripts, SQL, migrations, database policies/grants/RLS, generated runtime artifacts, secrets, provider configuration, or deployment changes. Mixed-content PRs are ineligible even if most changed files are documentation.

## Mandatory merge controls

Every eligible PR must satisfy all of the following:

1. The PR is explicitly labelled and described as documentation-only and references GOV-MERGE-001.
2. The maintainer audits the entire diff, not only the PR title or summary.
3. The diff is limited to the approved project scope and reconciles with the current SSOT, approved PO decisions, and controlled-document versioning.
4. No unresolved blocking review comments or known material contradictions remain.
5. The PR is not a Draft and has a recorded review decision before merge.
6. Available required checks must pass. If no CI checks are configured or reported, this absence must be recorded; it must not be represented as a passing CI result. A documented static validation may supplement, but not impersonate, CI.
7. The merge uses the repository's configured protections and an approved merge method. No bypass, force-push, or protection weakening is permitted.
8. After merge, verify the resulting commit, changed files, default-branch state, and that no prohibited artifact entered the branch.

If any control cannot be verified, do not merge that PR.

## Solo-maintainer review exception

The Product Owner confirmed on 2026-11-25 that this repository is operated as a solo-maintainer project and approved this narrow adjustment:

- The same maintainer account may perform and record the full-diff self-review and maintainer merge decision for an eligible documentation-only PR.
- This self-review is a maintainer attestation, **not** an independent GitHub review approval. It must never be represented as independent approval.
- The review record must identify the reviewed head SHA, enumerate the diff scope, record findings and disposition, and state CI/check status accurately.
- This exception applies only to GOV-MERGE-001 documentation-only PRs. It does not authorize self-approval for code, SQL, migrations, database/security policy, provider, deployment, or release changes.
- If GitHub branch protection or repository rules require an independent approval or another unmet condition, the PR must remain unmerged. Do not bypass, weaken, or disable that protection. Resolve repository settings through the normal authorized path or obtain a genuinely independent reviewer.

## Explicit prohibitions remain in force

This decision does not authorize:
- application scaffolding or feature source code;
- SQL execution, schema changes, migrations, grants/revokes, RLS changes, or live database operations;
- creating or changing Supabase, Vercel, or other provider resources;
- staging/production deployment, release, or data mutation;
- secret handling in chat or commits;
- marking G9/G10 or production readiness as passed/active without their separate evidence and approvals.

G9 remains **NOT READY**. G10 remains **NOT ACTIVE** until its separately required activation record is approved after G9 verification. Production readiness remains **NOT VERIFIED**.

## Scope and duration

This exception applies only to documentation-only merges for this repository, from the date of approval until superseded or revoked by an explicit Product Owner governance decision. It does not automatically approve any existing PR. Each PR requires separate eligibility and review under this policy.

## Audit record

The initial documentation-only merge exception was approved explicitly by the Product Owner in the project conversation on 2026-11-25: “Ya setuju”, in response to the proposed narrow documentation-only merge exception.

The solo-maintainer review adjustment was approved explicitly by the Product Owner in the project conversation on 2026-11-25: “Iya saya solo”, in response to the request to revise the independent-review requirement for a solo-maintainer repository.


## 2026-11-25 staged G9-F1 / G10-F1 gate reconciliation

This addendum reconciles GOV-MERGE-001 with the later Product Owner staged-gate decision recorded in root `AGENTS.md` §3.2 and the Decision Register.

GOV-MERGE-001 was originally approved as a narrow documentation-only merge path before implementation activation. It remains applicable to documentation-only PRs and its merge controls remain binding: complete diff audit, maintainer self-review attestation where applicable, accurate reporting of available/absent checks, normal merge protections, no bypass and post-merge verification.

The pre-G10 statements in the original decision are historical and are superseded only to the extent they conflict with the later staged decision:
- G9-F1 foundation scope is frozen.
- G10-F1 foundation implementation is ACTIVE following the governing decision merge (PR #26).
- Bounded foundation source code and development-only work may proceed on dedicated feature branches using synthetic data.
- Full-system G9 remains NOT READY; later business features, unresolved command handlers, production data, deployment and production operations remain gated.
- GOV-MERGE-001 itself does not activate G10 and is not the source of implementation authorization.

No branch-protection bypass or automatic merge authorization is created by this reconciliation.