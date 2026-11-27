# Post-Merge Repository Audit — Dit. SD Inspection

**Document ID:** PMA-001  
**Version:** 1.2.0  
**Audit date:** 2026-11-27  
**Status:** AUDIT COMPLETE — SSOT DOCUMENTATION REMEDIATION INCLUDED; RUNTIME / EXTERNAL GATES OPEN  
**Repository:** `itswork-app/dit-sd-inspection`  
**Reviewed branch:** `main`  
**Reviewed HEAD:** `706c654a17d415913892b64fe71de59c2a09bafe`  
**Governing policy:** Root `AGENTS.md` v1.3.0  
**Authority:** Decision Register, MIB-001, DGA-001 and approved PR records

## 1. Executive result

The GitHub post-merge audit confirms that PRs **#38, #39, #40 and #41 are merged into `main`**. The current main HEAD is merge commit `706c654` from PR #41.

The merged implementation and local verification evidence are materially ahead of several current-state statements in the controlled documentation. The principal risk is **documentation authority drift**, not a demonstrated runtime defect: MIB-001, DGA-001 and DOC-MAP-001 still contain status text from before the 2026-11-27 G9-TECH freeze and G10 activation. README also retains a route-count value that differs from the latest recorded build evidence.

Current gate interpretation must follow root `AGENTS.md` v1.3.0 and the approved Product Owner sign-off:
- **G9-F1:** FROZEN.
- **G9-TECH:** FROZEN.
- **G10 full-system synthetic implementation:** ACTIVE; I1–I5 are implemented on isolated local/development infrastructure with synthetic data.
- **G11:** PARTIAL; local synthetic verification has passed for the recorded suites; main-push hosted CI is now confirmed PASS on audited HEAD `706c654` (run #77), while repository enforcement and several broader operational/UAT checks remain open or not executed.
- **G12:** NOT VERIFIED / BLOCKED. No production release or real institutional data readiness is established.

This audit does not change any Product Owner decision, authorize production activity, or convert local test evidence into hosted/staging/production evidence.

## 2. Scope and method

Reviewed:
1. Root `AGENTS.md` v1.3.0 and its §3.3 G9-TECH/G10 sign-off.
2. `README.md`, `docs/README.md` (DOC-MAP-001), MIB-001 v1.1.0, DGA-001 v2.2.0 and the Decision Register.
3. GitHub merge metadata and changed-file inventories for PRs #38–#41.
4. The exact main HEAD commit and its diff.
5. Combined commit status and workflow-run records for the exact main HEAD.

This was a GitHub metadata and controlled-document consistency audit. The complete source diff of the large PR #39 was not independently re-reviewed line by line in this task. No repository checkout, local test execution, hosted database inspection, deployment, production mutation, or real-data access was performed. Test results below are reported as evidence recorded in merged PR descriptions and DGA-001, not as tests re-executed by this audit.

## 3. Post-merge inventory

| PR | Merge time (UTC) | Scope confirmed from merge record | Result |
|---|---|---|---|
| #38 | 2026-11-27 06:06:29 | G9 technical SSOT closure and G10 synthetic implementation activation records; documentation-only | MERGED |
| #39 | 2026-11-27 06:06:50 | Full-system synthetic implementation I1–I5, 13 migrations, application/API/UI foundations, private Storage/PDF and local verification scripts | MERGED |
| #40 | 2026-11-27 06:18:49 | Operational UI, bounded offline queue, evidence/PDF controls, protected-page SSR E2E | MERGED |
| #41 | 2026-11-27 06:39:29 | Local PostgreSQL backup/restore rehearsal, local load benchmark and DGA/README evidence update | MERGED |

Main HEAD:
- SHA: `706c654a17d415913892b64fe71de59c2a09bafe`
- Commit: merge PR #41
- PR #41 head commit: `81cee61b7b6360abc4b7aff9fb3470118b3eb07b`

GitHub returned **zero open pull requests** at audit time. The branch search surfaced `main`; this audit does not claim a complete historical branch inventory.

## 4. Verification evidence recorded in merged work

### 4.1 Application and database baseline

The merged PR #39 description records:
- 13 ordered SQL migrations.
- 62 canonical public tables with 62/62 ENABLE + FORCE RLS.
- 52 in-scope application commands; CMD-045..048 remain excluded external control-plane IDs.
- Private Storage with caller-JWT RLS, immutable originals, server-side binary validation and audited short-lived downloads.
- Local unit, migration, database, concurrency and HTTP/JWT verification.

### 4.2 Operational UI and offline behavior

PR #40 records:
- `/operations` page and unified application topbar.
- Bounded IndexedDB offline queue (maximum 50 operations).
- Explicit conflict preservation and manual rebase/discard; no silent overwrite.
- Evidence/PDF controls and live SSR E2E for six protected pages.
- Real-device offline UAT remains NOT EXECUTED.

### 4.3 Local backup/restore and load rehearsal

PR #41 records:
- Local backup/restore rehearsal: PASS; 62/62 tables and RLS parity; row counts and canonical data SHA-256 match; backup 188 ms, restore 2,406 ms.
- Local load baseline: 100 concurrent read requests and 40 concurrent protected writes, zero recorded errors; read p95 756 ms and write p95 258 ms.
- `npm run check`: 15/15 suites, 90/90 tests, 5/5 Node tests and 68 build routes.

Evidence limitations are explicit and remain binding:
- The restore is a local synthetic rehearsal using minimal auth stubs and `--no-owner --no-privileges`; Storage object bytes are not included. It does **not** close DGA-B06.
- The load result is a single local burst on a small dataset, with 10 synthetic authenticated sessions and local SQL setup. It is **not** a 100-user production capacity result or an approved SLO. It does **not** close DGA-B08.
- The initial workflow-run wrapper exposed only PR-triggered runs and therefore did not surface main-push run #77. A direct Actions API query later confirmed run #77 (`45953256570`) on exact HEAD `706c654`, event `push`, conclusion SUCCESS; its Quality checks job and `npm run check` step passed. The combined commit-status endpoint returned no entries, but that is not evidence that the Actions workflow did not run.
- Real-device offline UAT and G12 production readiness remain open.

## 5. Findings

| ID | Severity | Finding | Evidence / impact | Required disposition |
|---|---|---|---|---|
| PMA-F01 | HIGH | MIB-001 current-state header is stale | MIB-001 still says G9-TECH is ready for freeze sign-off and G10 full-system implementation is pending. Root AGENTS.md §3.3 and DGA-001 §22 record the approved freeze and active G10 implementation. This can misdirect future work authorization. | **Remediated in this PR branch:** MIB-001 v1.2.0 updates authority, gate table, current status and post-merge checkpoint; dated snapshots remain preserved. |
| PMA-F02 | HIGH | DGA-001 executive summary and blocker table are not reconciled to §22–§23 | DGA-001 §1 and early blocker/gate sections retain pre-implementation conclusions. §22 records G9-TECH frozen and G10 active; §23 records local backup/restore and load rehearsals, while §22.1 still says those drills were not executed. Readers may mistake local evidence as absent or treat old conclusions as current. | **Remediated in this PR branch:** DGA-001 v2.3.0 updates executive disposition, main HEAD/branch metadata, blocker statuses and local-vs-managed/staging evidence boundaries; remaining external/runtime gates stay open. |
| PMA-F03 | MEDIUM | DGA-001 audit provenance points to an old feature branch and baseline | DGA-001 header still identifies `feat/i4-storage-and-pdf-renderer` and baseline `5b7fdd9`, although the current reviewed main includes PRs #38–#41 and is at `706c654`. | **Remediated in this PR branch:** DGA-001 v2.3.0 identifies audited `main` HEAD `706c654`; prior branch/commit provenance remains in historical checkpoint sections. |
| PMA-F04 | MEDIUM | DOC-MAP-001 metadata is behind governing documents | The index identified AGENTS.md v1.2.5 and DGA-001 v2.0.0, and its gate summary said G9-TECH was awaiting sign-off and G10 pending. | **Remediated in this PR branch:** DOC-MAP-001 v1.2.0 identifies AGENTS.md v1.3.0, MIB-001 v1.2.0, DGA-001 v2.3.0, RTM-001 v1.1.0, RAID-001 v1.1.0 and current gate status. |
| PMA-F05 | LOW | README route-count metadata differs from the latest recorded build | Root README's current implementation summary reported 67 Next.js routes, while PR #41 records 68 routes. | **Remediated as a documentation discrepancy in this PR branch:** root README now reports 68 routes from the PR #41 recorded build. No fresh build was run by this audit; the older 67-route feature-branch checkpoint is explicitly labelled historical. |
| PMA-F06 | INFO | Initial audit query missed the main-push workflow run | The workflow-run wrapper used in the initial audit returned only PR-triggered runs. A direct Actions API query later found main-push run #77 (`45953256570`) on `706c654`, completed SUCCESS; its Quality checks job and `npm run check` step passed. The combined commit-status endpoint remains empty. | Correct the audit record; retain DGA-B15 as PARTIAL until repository ruleset/required-check enforcement is enabled and verified. |

## 6. Current risk and gate disposition

| Gate / dependency | Audit disposition |
|---|---|
| G9-F1 / G9-TECH | FROZEN per approved PO sign-off and root AGENTS.md v1.3.0 |
| G10 I1–I5 | IMPLEMENTED on isolated local/development infrastructure with synthetic data |
| G11 local synthetic verification | PARTIAL — merged local evidence exists; this audit did not rerun it |
| DGA-B06 managed backup + Storage restore | OPEN — local rehearsal is not provider restore evidence |
| DGA-B07 real-device offline UAT | NOT EXECUTED |
| DGA-B08 staging load/SLO | OPEN — local baseline is not an SLO |
| DGA-B15 hosted CI/repository governance | MAIN-PUSH CI PASS on run #77; repository ruleset/required-check enforcement remains OPEN |
| G12 production / real institutional data | NOT VERIFIED / BLOCKED; no production deployment or real-data operation authorized by this audit |

## 7. Remediation sequence

1. **Task 43 — SSOT reconciliation:** update MIB-001, DGA-001, DOC-MAP-001, README, RTM and RAID references to one consistent current gate state. DOC-MAP-001 metadata correction is included in this audit branch; the remaining controlled-document reconciliation is separate work.
2. **Task 44 — G11 evidence closure:** map the remaining QA catalogue to executed evidence; keep hosted CI, real-device UAT, managed restore and staging load testing as separate evidence gates.
3. **Task 45 — G12 readiness preparation:** prepare provider, institutional, privacy, operational ownership, deployment and rollback evidence without executing production actions.

## 8. Audit declaration

- Reviewed branch/HEAD: `main` / `706c654a17d415913892b64fe71de59c2a09bafe`.
- Files changed by this audit/remediation PR branch: `README.md`, `docs/README.md` (DOC-MAP-001), `MIB-001`, `DGA-001`, `RTM-001`, `RAID-001`, and this PMA-001 report (7 files total).
- Application source, scripts, SQL migrations, schema, grants/RLS, secrets, hosted database, deployment and production data: **not changed**.
- Tests rerun by this audit: **none**. PR-recorded results are identified as previously recorded evidence, not new execution.
- Decisions made: no new product or technical decision; gate state follows existing PO sign-off and AGENTS.md.
- Decisions still required: no new PO semantic decision identified by this audit; remediation and external/runtime evidence remain open as listed.
- Out-of-scope actions: **none**.
## 9. SSOT remediation completed in PR #42 branch

The following current-state documentation drift is corrected in the same documentation-only review branch:

| Artifact | Updated version/state | Remediation |
|---|---|---|
| MIB-001 | v1.2.0 | Current G9/G10/G11/G12 state, authority, gate table and post-merge checkpoint updated; dated snapshots retained as historical. |
| DGA-001 | v2.3.0 | Executive summary, audited main HEAD, B06/B07/B08/B15 dispositions and local-versus-managed/staging evidence boundary reconciled. |
| DOC-MAP-001 | v1.2.0 | Governing versions, current gate summary, controlled document counts and audit index updated. |
| RTM-001 | v1.1.0 | Current evidence overlay added; remaining planned cases distinguished from local execution evidence. |
| RAID-001 | v1.1.0 | Current gate/evidence overlay added; I-012 and D-025 CI/scope wording reconciled. |
| Root README | Current status | G11 corrected to PARTIAL, route count reconciled to the PR #41 recorded 68-route build, document count updated to 104, and stale notification status corrected. |

The audited main HEAD still has no workflow/status evidence (`DGA-B15`). A separate PR-triggered CI check was observed in progress while this report was revised; it was not treated as a passing result. Check the live PR #42 status at review time. Managed PostgreSQL + Storage restore (`DGA-B06`), real-device offline UAT (`DGA-B07`), staging SLO/load (`DGA-B08`), and G12 production readiness remain open/blocked. This documentation remediation does not close them. The complete seven-file diff is subject to PR #42 maintainer review; no merge has been performed.


## 10. Audit evidence correction — main-push workflow run discovered

A follow-up read-only GitHub API query identified a main-push Actions run that the initial workflow-run wrapper did not return. That wrapper filters to PR-triggered runs; its empty result was incorrectly interpreted in the original PMA-F06 finding as absence of a main-push workflow.

Corrected evidence for the audited baseline:
- Main commit `706c654a17d415913892b64fe71de59c2a09bafe` (PR #41 merge) had main-push workflow run #77 (`45953256570`), event `push`, conclusion **SUCCESS**.
- Quality checks job `140353765385` completed **SUCCESS**; checkout, Node.js setup, dependency installation and `npm run check` completed successfully.
- The combined commit-status endpoint returned no entries. This does not negate the separately evidenced GitHub Actions workflow run.
- The subsequent PR #42 merge commit `ae271615` also has main-push run #93 (`45965232365`) with Quality checks **SUCCESS**.

The original PMA-F06 “hosted CI absent” conclusion is therefore **SUPERSEDED / CORRECTED**. DGA-B15 is not fully closed: the repository ruleset `main` (ID `28208385`) is currently `disabled`; the available integration cannot read the branch-protection endpoint (HTTP 403). Successful workflow execution and enforced branch governance are separate controls.

This correction is documented in PMA-001 v1.2.0, DGA-001 v2.4.0 and G11-ECP-001 v1.0.0. It does not change G11 PARTIAL or G12 NOT VERIFIED / BLOCKED.
