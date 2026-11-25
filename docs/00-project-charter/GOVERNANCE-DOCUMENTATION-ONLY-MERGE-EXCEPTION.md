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
2. The reviewer audits the entire diff, not only the PR title or summary.
3. The diff is limited to the approved project scope and reconciles with the current SSOT, approved PO decisions, and controlled-document versioning.
4. No unresolved blocking review comments or known material contradictions remain.
5. The PR is not a Draft and has the required review approval(s).
6. Available required checks must pass. If no CI checks are configured or reported, this absence must be recorded; it must not be represented as a passing CI result. A documented static validation may supplement, but not impersonate, CI.
7. The merge uses the repository's configured protections and an approved merge method. No bypass, force-push, or protection weakening is permitted.
8. After merge, verify the resulting commit, changed files, default-branch state, and that no prohibited artifact entered the branch.

If any control cannot be verified, do not merge that PR.

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

This exception applies only to documentation-only merges for this repository, from the date of approval until superseded or revoked by an explicit Product Owner governance decision. It does not automatically approve any existing PR. Each PR requires independent eligibility and review.

## Audit record

The approval was given explicitly by the Product Owner in the project conversation on 2026-11-25: “Ya setuju”, in response to the proposed narrow documentation-only merge exception.

**Implementation requirement:** Root `AGENTS.md` must reference this decision and replace its blanket default-branch merge prohibition with this narrowly bounded exception. Until that controlled policy update is committed, the stricter wording in `AGENTS.md` remains the operational blocker and no PR may be merged under this exception.
