# RAID Register — Dit. SD Inspection

**Document ID:** RAID-001  
**Version:** 0.1.6  
Status: Draft — review required  
Baseline: Phase 0, 2026-11-23  
Owner convention: accountable role is recorded; named individuals are not invented.

## Risks

| ID | Type | Description | Impact | Likelihood | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|---|
| R-001 | Risk | Official IFP or Standing Bracket checklist/photo requirements are incomplete or differ from screenshots | High | Medium | Obtain authorized, current instrument documents; reconcile every item and obtain Product Owner sign-off before PRD freeze | Product Owner | OPEN |
| R-002 | Risk | Legacy screenshots do not expose all edge cases, validations, or document layouts | High | High | Maintain a reference inventory and gap log; request missing screens and sample outputs; label assumptions explicitly | Product Owner | OPEN |
| R-003 | Risk | Offline capture and later synchronization can cause duplicate claims, lost evidence, or conflicting edits | Critical | Medium | Define idempotency, local persistence, server reconciliation, conflict handling, recovery and destructive-action rules; test device-loss scenarios | CTO / Engineering Lead | OPEN |
| R-004 | Risk | Incorrect RLS or assignment scoping exposes records across locations or roles | Critical | Medium | Threat model, deny-by-default policies, server-side authorization, negative tests, and independent policy review | CTO / Engineering Lead | OPEN |
| R-005 | Risk | Photo/video evidence increases storage and egress beyond the cost-first operating envelope | High | Medium | Establish file limits, formats, retention, lifecycle, quotas, and usage alerts before production; keep evidence private | CTO / Engineering Lead | OPEN |
| R-006 | Risk | Free-tier quotas or plan restrictions interrupt production operations | High | Medium | Verify current provider terms/quotas and upgrade triggers; production plan approval must precede go-live | CTO / Engineering Lead + Project Sponsor | OPEN |
| R-007 | Risk | Report target allocation is mistaken for actual inspection activity | High | Medium | Separate actual-event facts from versioned target allocations in schema, APIs, UI, and report tests | CTO / Engineering Lead | MITIGATING |
| R-008 | Risk | Wet-signature, BA signatory, attendance verification, or print responsibilities are ambiguous | High | Medium | Confirm authority, signatory blocks, document lifecycle, and verification responsibilities in PRD | Product Owner | OPEN |
| R-009 | Risk | A single Inspector is assigned to overlapping work across locations | Medium | Medium | Enforce schedule-overlap validation and explicit scoped assignments; capacity is configurable from 1 to 100 (default 50), counting distinct Inspectors combined across both locations | Super Admin / Product Owner | MITIGATING |
| R-010 | Risk | Production backup exists but restore has not been proven | Critical | Medium | Define RPO/RTO, backup schedule, restore runbook, and conduct restore drills before release | CTO / Engineering Lead | OPEN |
| R-011 | Risk | Evidence or personal data is retained, disclosed, or deleted contrary to institutional requirements | Critical | Medium | Approve data classification, legal basis, retention schedule, legal hold, access and deletion workflow before collection | Project Sponsor / Records Owner | OPEN |
| R-012 | Risk | Provider region, quota, billing or plan limits are unknown and may interrupt production | High | Medium | Verify actual account plan, region, quotas, overage behavior, budget owner and alert thresholds before go-live | Project Sponsor / CTO | OPEN |
| R-015 | Risk | Batch printing may produce duplicate, missing or falsely successful print records during partial failure/retry | High | Medium | Use bounded batches, per-document outcomes, failed-only retry, immutable document-version linkage and atomic print ordinals; verify with concurrency and failure-injection tests | CTO / Engineering Lead | OPEN |

## Assumptions

| ID | Assumption | Validation required | Accountable role | Status |
|---|---|---|---|---|
| A-001 | The two initial instruments remain IFP and Standing Bracket | Confirmed by current project baseline; changes require scope approval | Product Owner | BASELINED |
| A-002 | There are two inspection locations | Confirm exact official location names and whether fixed for the full project | Product Owner | OPEN |
| A-003 | Inspector capacity is configurable from 1 to 100 (default 50), up to 100 people total across both locations | Confirmed by user on 2026-11-23; minimum 1, default 50, global hard maximum 100 | Product Owner | CONFIRMED |
| A-004 | Google sign-in is the identity entry point | Confirm institutional account policy and account recovery requirements | Product Owner / Super Admin | OPEN |
| A-005 | Supabase and Vercel are the approved platform baseline | Confirm plan eligibility, institutional procurement, quotas, and data/privacy requirements | Project Sponsor / CTO | OPEN |
| A-006 | The supplied screenshots/workflow descriptions are reference material, not complete formal specifications | Validate against authorized source documents and sample outputs | Product Owner | OPEN |

## Issues

| ID | Issue | Required resolution | Accountable role | Status |
|---|---|---|---|---|
| I-001 | Complete official IFP checklist and photo slots are not yet validated against controlled source documents | Obtain authoritative checklist and approve exact wording, order, required/conditional status | Product Owner | OPEN |
| I-002 | Standing Bracket checklist and photo-slot inventory may be incomplete | Obtain full source and approve exact items | Product Owner | OPEN |
| I-003 | BA signatory blocks and signing authority are not fully specified | Confirm parties, number/order of signatories, titles, and configuration authority | Product Owner | OPEN |
| I-004 | Attendance verification workflow still requires implementation/test evidence | Implement Korlap verifier permission scoped to assigned location; separate upload and verify actions | Engineering Lead | OPEN |
| I-005 | Report metric contract and project closure require implementation/test evidence | Implement distinct actual counts and Super Admin final closure gates with audited reconciliation | Engineering Lead | OPEN |
| I-006 | Approved session authority/state machine requires implementation/test evidence | Enforce Super Admin creation/configuration; scoped Korlap transitions; privileged reopen path | Engineering Lead | OPEN |
| I-007 | Evidence limits, retention, deletion, and privacy rules are unresolved | Approve retention schedule, access, legal basis, and deletion workflow | Project Sponsor / Product Owner | OPEN |
| I-008 | Backup/PITR and Storage object recovery capability is not verified against the actual provider plan | Verify provider contract, implement object recovery strategy, approve RPO/RTO, and pass isolated restore drill | Project Sponsor / CTO | OPEN |
| I-009 | Production region, provider quotas, billing ownership, and environment separation are not confirmed | Complete provider capability sheet, institutional region decision, budget approval, and staging/production setup | Project Sponsor | OPEN |

## Dependencies

| ID | Dependency | Needed for | Accountable role | Status |
|---|---|---|---|---|
| D-001 | Authorized IFP and Standing Bracket instrument/checklist documents | PRD and test-case freeze | Product Owner | BLOCKED |
| D-002 | Approved reference screenshots, sample PDFs, BA, and attendance documents | UX and document parity | Product Owner | PARTIAL |
| D-003 | Named project sponsor, Product Owner, and operational approvers | Governance and sign-off | Project Sponsor | OPEN |
| D-004 | Supabase/Vercel organization ownership, billing owner, and production plan decision | Deployment and operations design | Project Sponsor | OPEN |
| D-005 | Institutional privacy, retention, and data-handling requirements | Security architecture and production approval | Project Sponsor | OPEN |
| D-006 | Approved backup/PITR and Storage object recovery entitlement | Disaster recovery readiness | Project Sponsor / CTO | OPEN |
| D-007 | Approved production region, provider plan, quotas, and billing owner | Production environment and go-live | Project Sponsor | OPEN |

## Review rules

- Review RAID at each package gate and before scope freeze.
- A risk is not closed merely because a mitigation is documented; closure requires evidence.
- Assumptions must be validated or explicitly accepted as residual assumptions before they become implementation contracts.
- Any new risk, issue, or dependency receives a stable ID and an accountable role.
- No person or organization is assigned as an owner without explicit confirmation.


## Package R — Audit governance additions

| ID | Type | Description | Impact | Response | Accountable role | Status |
|---|---|---|---|---|---|---|
| R-013 | Risk | Audit history may be incomplete or exposed if event writes, access controls, retention, or export governance are not approved and enforced | Critical | Approve INS-016, transactional append semantics, least-privilege access, privacy-safe payloads, retention/legal hold, and verification before implementation | Project Sponsor / CTO / Records Owner | OPEN |

| I-010 | Issue | Audit retention duration, legal-hold authority, audit-reader roles, export permission, and network metadata policy remain unresolved | High | Obtain institutional security, privacy, records, and legal decisions | Project Sponsor / Records Owner | OPEN |

| D-008 | Dependency | T-15 audit policy and T-18 command architecture are PO-approved; command/schema/RLS grants and executable atomicity verification remain required | Audit implementation and security release gate | CTO / Engineering Lead | BLOCKED (technical verification) |


## Package S — Cross-document audit findings

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| R-014 | Risk | Scope freeze or implementation begins while authoritative instrument, privacy, operations, security, and workflow decisions remain open | Critical | Enforce Package S freeze checklist; no implementation until blockers are approved or explicitly deferred with compensating controls | Product Owner / Project Sponsor / CTO | OPEN |
| I-011 | Issue | Session creation/state transitions, offline device contract, report semantics, and UAT/pilot/rollback ownership remain unresolved | High | Resolve through explicit PO decisions and update all affected docs and tests | Product Owner | OPEN |
| I-012 | Issue | CI execution, branch protection, and provider quota state were not verified in Package S | High | Inspect live repository settings and workflow runs before merge | CTO / Repository Administrator | OPEN |
| D-009 | Dependency | Controlled instrument documents and institutional records/privacy/security approvals | Scope freeze and implementation authorization | Product Owner / Project Sponsor | BLOCKED |


## Package T decision-closure dependencies

| ID | Type | Description | Impact | Likelihood | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|---|
| D-019 | Dependency | Package T decisions T-01..T-18 require recorded PO outcomes and, where applicable, separate institutional authority/evidence before corresponding scope-freeze gates can close | High | High | Preserve approved PO outcomes in the Decision Register; track residual technical and institutional gates separately; update affected specifications and verification evidence; do not treat PO approval as implementation or institutional approval | Product Owner / Institutional Authority | Open |
| R-020 | Risk | Recommendations in Package T could be mistaken for approved policy | High | Medium | Preserve explicit state labels; only Decision Register entries with explicit approval count as approved; keep PR #2 draft and implementation unauthorized | Product Owner / Engineering Lead | Open |
| D-021 | Dependency | Institutional source evidence, records/privacy direction and provider operational evidence are outside the documentation baseline and remain unverified | High | High | Obtain source documents and written approvals; verify actual provider settings, backup/restore and recovery ownership before production gate | Institutional Authority / Operations Owner | Blocked |


## Package T — partial decision closure update (2026-11-23)

Product Owner explicitly approved T-01=A, T-02=B, T-03=C and T-04=A, then T-05=A, T-06=A, T-07=A and T-08=A on 2026-11-23.
- T-01 Standing Bracket source is confirmed by Product Owner: `Pemeriksaan Barang_SB.pdf`, 19 rows (6 physical + 13 accessories). Official IFP source and SB photo/evidence rules remain outstanding.
- T-02 template configurability is PO-approved; institutional authorization of actual signatory roles/identities and final BA template remains an external dependency.
- T-03 configurable executive-summary signature behavior is PO-approved; approved template determines whether a signature is required.
- T-04 PDF-only initial client delivery is PO-approved; client portal is deferred from initial scope.
- T-05 distinct actual report counts are PO-approved; report metric implementation and tests remain open.
- T-06 Super Admin final project closure after gates/reconciliation is PO-approved; implementation and tests remain open.
- T-07 Super Admin session creation/configuration and scoped Korlap operation are PO-approved; state/permission implementation and tests remain open.
- T-08 Korlap attendance verification within assigned scope is PO-approved; separate permissions and verification tests remain open.

The Decision Register and affected specifications have been updated and fetched back for verification. T-05 through T-09 are PO-approved; T-10 option B is PO APPROVED as the required formal institutional records/legal/privacy review path; written institutional policy remains BLOCKED. T-11 option B is PO APPROVED for current mainstream stable browsers with explicit exclusions; exact device/OS/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED; institutional ownership arrangement and provider/recovery verification remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); detailed implementation and tests remain pending. T-14 is PO APPROVED option A; T-15 through T-18 have PO direction approved; residual design and institutional gates remain OPEN/BLOCKED. Scope freeze remains NOT READY; G10 is NOT ACTIVE pending separate gate activation.


## Package T T-09 decision update (2026-11-23)

T-09 is **PO APPROVED option B**: limited offline draft editing only after an online claim. Offline claim, approval, final submit, role/assignment changes, session administration and privileged actions are prohibited. Sync must be authenticated, idempotent, reauthorize on the server, reject stale conflicts, preserve both sides and require server-confirmed required media before final submit.

Residual risks/dependencies remain OPEN/BLOCKED: browser/device support, local-data encryption/protection, shared-device logout, local retention/purge and recovery controls; institutional privacy/records approval under T-10. PO approval does not mean offline persistence is safe to activate in production. Scope freeze remains NOT READY and implementation remains NOT AUTHORIZED.


## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.


## Package T-11 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — support current mainstream browser versions with explicit exclusions.** Inspector field workflow uses current stable Chrome on Android; Korlap, Reviewer, Super Admin and Print Officer use current stable Chrome or Edge on desktop. Tablet support is conditional on responsive, camera, upload and PDF/print validation. Obsolete/unsupported browser releases, embedded in-app browsers and modified browsers are excluded. Exact OS/device minimums and browser build numbers must be recorded from actual UAT devices; this decision does not invent exact version numbers.

The 100 concurrent authenticated-user load-test target remains the required acceptance profile, tested at 10/25/50/75/100 concurrent users. This is a test target, not a demonstrated production capacity or SLA. Numeric latency/error-rate SLOs remain OPEN pending workload definition, provider plan/region/quota verification and baseline measurement. No implementation, compatibility test or load test is claimed as executed.


| R-036 | Alternative provider-ownership arrangement may lack clear legal owner, billing authority, custodian continuity or exit rights | High | Medium | Obtain institutionally approved written ownership/billing/custodian/region/exit arrangement; name primary and secondary recovery contacts; verify access and offboarding | Project Sponsor / Institutional Authority | OPEN |

### T-13 mitigation — print batch integrity

PO approved individual and bounded batch printing. Risk R-015 remains OPEN until per-document outcome persistence, failed-only retry, immutable document-version linkage and atomic sequence allocation are implemented and verified. The PO decision does not authorize implementation before the overall scope-freeze gate.


### R-016 — Inspector capacity predicate drift

**Risk:** UI, API and database may calculate qualifying Inspector accounts differently, allowing over-capacity or incorrect rejection. **Control:** T-14 PO-approved canonical predicate: distinct enabled login accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment within governed project/session scope; deduplicate assignments/roles and exclude pending, rejected, suspended, disabled and expired-role accounts. Enforce atomically against combined cap 1–100 (default 50). **Status:** Open until design consistency, implementation and concurrency tests are verified.



## T-15 — audit policy decision update (2026-11-24)

Product Owner approved T-15 option A: INS-016 append-only audit events, atomic audit + critical mutation, fail-closed rollback on audit failure, actor/role/scope/action/time/correlation/idempotency/privacy-safe context, auditable sensitive evidence access/export and least-privilege audit access. Update R-013 mitigation and D-008 dependency accordingly: Product Owner policy approval is no longer pending, but D-008 remains BLOCKED until command/schema/RLS implementation design is reconciled and verified. I-010 remains OPEN for institutional retention/legal-hold/classification, audit-reader/export authority and network metadata policy under T-10. This decision does not close the risk or authorize implementation; no code/tests are claimed.


### T-16 — Cross-project serial collision and evidence lineage risk (2026-11-24)

**Risk:** A project-local unit model may create duplicate physical identities across projects, while a global serial rule may incorrectly reject a serial reused by another instrument type. Evidence may also become detached from the exact revision/version or be overwritten. **Control:** PO-approved key `(instrument_type, serial_normalized)` across projects; preserve project-scoped authorization via explicit project associations; permit reuse across different instrument types; route same-type conflicts to authorized, reasoned and audited resolution; bind immutable evidence to exact revision/version and prohibit in-place replacement. **Status:** Design reconciliation, institution-approved exception policy, implementation and tests remain OPEN.


## Package T — T-17 publication governance update (2026-11-24)

**D-022 — Dependency — CFG-001 publication authorization reconciliation.** Product Owner approved option A: Super Admin may directly publish a version after server-side schema validation; no second-person approval is required. The explicit `instrument.publish` permission, trusted actor derivation, atomic publication + audit, immutable published version, session/assignment version pinning, historical snapshot retention, and separate audited deactivation are now documented across schema, RLS, command and QA artifacts. **Status:** PO direction approved; cross-document technical review and implementation evidence OPEN. No migration, code or test execution claimed.

**R-023 — Risk — instrument configuration privilege or history drift.** A broad configuration editor or mutable published version could alter inspection meaning or allow privilege escalation. **Mitigation:** bounded allowlists; deny arbitrary executable configuration; server-side authorization; atomic publication/audit; immutable versions and exact snapshots; explicit scoped operational authorization independent of global Super Admin administration. **Status:** Design direction documented; cross-document technical review and verification OPEN.


## T-18 — Privileged command boundary risk and control (2026-11-24)

**D-024 — Architecture decision — PO APPROVED option A.** Standardize Vercel server routes + caller-JWT PostgreSQL command functions. The server verifies caller session and validates request; PostgreSQL derives actor from JWT and enforces account, permission, role, scope, state and separation-of-duties checks. Deny browser direct DML to protected tables. Require least-privilege command grants, idempotency/concurrency controls and atomic business mutation + event/audit; audit failure rolls back. SECURITY DEFINER exceptions require pinned search_path and function-level review; no browser service-role credential. **Residual status:** architecture choice approved; command catalogue and table-by-table grants/RLS require technical review; T-16 association design is documented but needs technical review; command-specific verification remains OPEN. No implementation authorization.

**R-024 — Privileged command bypass or confused-deputy risk.** A route that trusts client actor/scope, uses service-role credentials indiscriminately, exposes generic RPC writes, or omits atomic audit could bypass authorization or corrupt state. **Mitigation:** caller-JWT propagation, database-derived actor, server-side permission/scope checks, direct-DML denial, command-specific least-privilege grants, pinned/reviewed SECURITY DEFINER only where necessary, idempotency, concurrency control and atomic audit. **Status:** architecture direction approved; design and security verification remain OPEN. No code, migration or test execution claimed.


## Documentation Gate Audit — DGA-001 (2026-11-24)

**D-025 — Dependency — Documentation gap closure.** The evidence-backed [Documentation Gap Audit — Gate Implementation Readiness](DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md) is the active closure queue for G1–G9. It records source authority, institutional approvals, permission/command completeness, ERD-only entities, exact RLS/grants, runtime JWT proof, offline/device security, report/notification lifecycle, provider/restore/SLO and CI evidence gaps. **Status: OPEN / BLOCKING SCOPE FREEZE.** Each DGA-Bxx item must be closed with referenced evidence or an explicitly authorized exclusion/deferment and compensating control; a status-only edit is insufficient.

**R-025 — Risk — premature implementation gate entry.** Entering implementation with incomplete source authority, unresolved command contracts, unapproved institutional policy or unverified security/operations controls may cause architectural rework or production data exposure. **Mitigation:** enforce MIB-001 G0–G12 and DGA-001; no implementation until G9 scope freeze and separate G10 authorization. **Status: OPEN / CRITICAL.**

## NLA-001 / T-13 design risks and dependencies — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| D-026 | Dependency | INS-015 notification lifecycle is PO-approved; exact selector grammar, event-time recipient/scope snapshot representation, policy permission/SoD, worker identity/ACL, provider callback capability, retry horizons and T-10 retention/privacy remain unresolved | Scope freeze and notification implementation | NLA-001 v0.1.4; candidate notification_outbox_recipients is NOT ADMITTED; reconcile schema/RLS/ERD/command/lock/QA and obtain accountable approvals/provider evidence; execute tests only after G10 | PO / Security / Institution / Operations / Engineering | OPEN — BLOCKING |
| R-026 | Risk | External notification providers have at-least-once/ambiguous acceptance behavior; retries or unauthenticated/replayed callbacks can duplicate delivery, corrupt status or silently lose notices | High | Transactional outbox, unique recipient/channel arbiters, append-only attempt evidence, owner/token-hash/generation/expiry fencing, INT-NOTIF-001 signature/freshness/replay validation, UNKNOWN state and backlog/dead-letter monitoring | Engineering / Security / Operations | MITIGATING BY DESIGN; PROVIDER/WORKER VERIFICATION OPEN |
| D-027 | Dependency | T-13 batch print decision requires physical batch persistence and append-only per-document outcomes to be reconciled with RLS, commands and tests | Scope freeze and print implementation | Include `print_batches`; link `print_events`; review lock/projection/retry contract and failure/concurrency tests | PO / Engineering / Security | DESIGN RECORDED; REVIEW OPEN |

## Lock protocol PO decision and technical dependencies — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| D-028 | Dependency | LPR-02–LPR-06 product semantics are PO-approved, but canonical lock rank, exact command manifests, implicit PostgreSQL lock paths, physical constraints, function/trigger graph and effective privileges remain unapproved/unverified | G3/G4/G5/G7/G9 and implementation entry | Complete Engineering/Security review of LPR-01 and LPR-07–LPR-11; reconcile all 54 manifests; obtain authorized isolated concurrency evidence for LPR-10 | Engineering / Security / Database / QA | OPEN — BLOCKING; 10/54 CANDIDATE-NORMALIZED, 0/54 CERTIFIED |
| R-027 | Risk | A command or asynchronous finalizer may acquire shared resources in conflicting order or bypass a shared invariant, causing deadlocks, stale finalization, duplicate claims or capacity/closure races | Critical | Enforce one approved total order; require complete per-command/worker manifests; include trigger/FK/unique-index/helper-function lock edges; use fencing and adversarial concurrency tests before implementation | Engineering / Security / QA | OPEN — CRITICAL |
| R-028 | Risk | Canonical unit identity or T-14 eligibility may be implemented inconsistently across commands, causing duplicate physical units or over/under-counted Inspector capacity | High | Use the exact Decision Register predicates; centralize normalization/eligibility semantics; enumerate every competing writer and verify shared constraints/serialization | Engineering / Database / Security | MITIGATING BY SPECIFICATION; IMPLEMENTATION/VERIFICATION OPEN |

The PO decisions recorded in LPR-02–LPR-06 are product direction only. They do not close D-028/R-027/R-028 or authorize implementation. G9 remains NOT READY; G10 remains NOT AUTHORIZED.


## CMD-011–020 Product Owner decision closure — 2026-11-24

**D-029 — Dependency — CMD-011–020 product semantics approved; technical physicalization remains open.** The Product Owner approved the recommended product semantics for CMD-011–020. Decision Register and the v0.2.0 decision package record the approval, including compatibility with T-07, T-14 and T-17. **Residual work:** synchronize command contracts, logical/physical data model, concurrency tokens, permission/security review and QA traceability; obtain Engineering/Security/Database/QA and institutional/operational decisions within their authority. **Accountable:** Engineering lead / Security / Database / QA; PO remains owner of product changes. **Status:** PO DECISION COMPLETE; TECHNICAL / INSTITUTIONAL DEPENDENCIES OPEN.

**R-029 — Risk — approved product semantics may be implemented inconsistently across command, schema, permission and QA artifacts.** A stale candidate enum, ambiguous membership effective time, project-wide target plan, weak instrument normalization, mutable published configuration or unproven closure/capacity serialization could create inconsistent behavior or data integrity defects. **Mitigation:** maintain this crosswalk; preserve T-07/T-14/T-17; do not infer physical columns or lock modes; require static cross-document review and authorized tests before gate closure. **Accountable:** Engineering / Security / Database / QA. **Status:** MITIGATING BY DOCUMENTATION; VERIFICATION OPEN.


## Engineering/Security lock and concurrency technical resolution — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| D-030 | Dependency | LPR-01 and LPR-07–LPR-11 need accountable Engineering/Database/Security/QA/Operations review; CMD-001–010 are now candidate-normalized in the detailed review/manifest/graph, while CMD-011–054 still require per-command normalization; proposed identity ranks, parent-fence modes, worker trust and concurrency suite are not approved/evidenced | G3/G4/G5/G7/G9 | Review TECH-RESOLUTION-LPR-001; record explicit approve/reject/amend per LPR; inspect exact PostgreSQL object/privilege graph; normalize CMD-011–054 after review of the CMD-001–010 overlay; execute authorized isolated concurrency suite | Engineering / Database / Security / QA / Operations | OPEN — BLOCKING |
| R-030 | Risk | Unapproved parent lock modes, unverified identity/authorization lock coverage, implicit trigger/FK/index edges or stale worker finalizers can cause deadlock, authorization race, closure race, capacity drift or duplicate side effects | Critical | Approve one effective total order; require parent-first fencing and worker generation checks; validate all paths and constraints; prove with adversarial tests on exact schema/commit | Engineering / Security / QA | OPEN — CRITICAL |
| R-031 | Risk | Stale CMD-011–020 decision-package wording may cause implementation to persist non-T-07 session states PLANNED or CLOSE_REQUESTED | High | Decision package v0.2.4 explicitly supersedes candidate state wording; T-07 controls DRAFT/ACTIVE/PAUSED/CLOSED; CLOSE_REQUESTED is action/event only; add static test/traceability check | Engineering / QA | MITIGATING BY DOCUMENTATION; VERIFICATION OPEN |


## CMD-001–010 lock normalization checkpoint — 2026-11-24

D-030 remains OPEN/BLOCKING. The first ten command manifests now have a candidate resource order, lock-mode proposal where applicable, actor/target/grantor revalidation, T-14 capacity conditionality, competing-command map and planned test anchors. This reduces documentation ambiguity but does not approve the technical graph, close DGA-B18/B19/B21, or provide execution evidence. Continue with CMD-011–020 after reviewing this baseline; keep 0/54 certified until authority review and evidence exist.


**Current normalization references:** CMD-001–010 Detailed Contract Review v0.3.4; LOCK-MANIFEST-001 v0.4.10; LOCK-GRAPH-001 v0.4.8; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.6; QA Catalogue v0.3.2; DGA-001 v1.11.12. All remain proposals / planned evidence except the documentation normalization itself.


**Final reviewed source snapshot for CMD-001–010 checkpoint:** CMD detail v0.3.4; LOCK-MANIFEST-001 v0.4.13; LOCK-GRAPH-001 v0.4.10; LOCK-PROTOCOL-DECISION-RESOLUTION-001 v0.3.8; Cross-Command Reconciliation v0.8.8; QA Catalogue v0.3.3; DGA-001 v1.11.15. D-030/R-030 remain OPEN; no implementation or concurrency evidence is claimed.



## CMD-045–048 Product Owner disposition — 2026-11-24

Product Owner approved CMD-045–048 Control-Plane Resolution Proposal v0.1.0. The application-surface design ambiguity is CLOSED: the four IDs remain for traceability but are not executable application commands; no app permission, route, RPC, function, table, worker or generic CRUD is permitted. Their responsibilities are assigned to institutional records governance, institutional incident response, provider-native/secret-management operations and protected source-control/deployment systems respectively.

This decision closes the application-feature design question only. It does not close external dependencies D-031 through D-033 or critical risk R-033 until accountable owners supply objective evidence. DGA-B04/B05/B15 remain open; G9 remains NOT READY; G10 remains NOT ACTIVE. The former proposed app-command acceptance tests are no longer an application implementation backlog; control-plane verification requirements remain in the RTM and detailed review.


## CMD-045–048 blocked-command review — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| D-031 | Dependency | CMD-045 retention/legal-hold cannot be designed as an executable command until T-10 institutional records/legal/privacy/security policy defines record classes, retention triggers, hold authority/precedence, disposition and backup/object treatment | G1/G4/G5/G8/G9; risk of unlawful or irreversible disposition | Obtain written institutional policy; define versioned policy and hold/disposition lifecycle; prove hold-vs-disposition concurrency and audit evidence before any implementation | Institutional records/legal/privacy/security owners | BLOCKED |
| R-032 | Risk | A generic security-incident command without an approved case owner, need-to-know scope, evidence chain-of-custody and break-glass process could expose sensitive incident data or create unauthorized response powers | Critical | Decide product-owned vs external incident system; approve incident taxonomy, roles, scope, evidence and response lifecycle; keep command unavailable until physical/security review | Security owner / Institution / PO | OPEN — BLOCKING |
| D-032 | Dependency | CMD-047 provider configuration lacks T-12 named account/billing owners, custodians, region, plan, secret-manager and rotation/recovery evidence | G4/G8/G9 and provider continuity | Complete signed ownership/RACI and provider evidence; approve server-side secret references, environment isolation, rotation, audit redaction and rollback | Sponsor / Institution / Operations / Security | BLOCKED |
| D-033 | Dependency | CMD-048 release management has no verified release operator, branch/ruleset, required CI, protected environment, artifact provenance or deployment SoD evidence | G4/G8/G9 | Verify GitHub rulesets, CI and Vercel protected environments; define immutable artifact provenance, approval, rollback and schema compatibility; decide whether product-side command is unnecessary | Repository administrator / Operations / Security | OPEN — BLOCKING |
| R-033 | Risk | Implementing CMD-047/048 as generic application CRUD/actions could bypass provider-native controls, expose credentials or allow deployment without independent approval | Critical | Prefer narrowly scoped provider/repository control planes; prohibit raw secrets and browser credentials; require exact allowlists, SoD, immutable evidence and independent review | Engineering / Security / Operations | OPEN — CRITICAL |

CMD-045–048 Detailed Contract Review v0.1.0 records the present safe-unavailable behavior and required closure evidence. This documentation does not close DGA-B04/B05/B15, authorize any provider setup, or establish incident/release control-plane ownership. All subcases remain PLANNED / NOT EXECUTED.


## CMD-049–054 notification contract closure dependencies — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| D-034 | Dependency | CMD-052/053 worker identity, scheduler trust, database role, function owner, exact EXECUTE ACL, lease-token custody and monotonic fencing have no approved runtime principal or evidence | G4/G7/G9; stale worker or privilege escalation risk | Security/Operations approve a non-login least-privilege workload identity, exact owner/ACL, token handling, generation fencing, rate limits and isolated verification | Security / Operations / Engineering | OPEN — BLOCKING |
| D-035 | Dependency | INT-NOTIF-001 provider callback ingress requires a selected provider, signature/freshness model, stable event identity, durable deduplication and provider-message mapping | Delivery state integrity and provider operations | Select provider only after T-12 ownership/cost/capability evidence; define callback authentication, replay defense, monotonic transitions and failure reconciliation | Provider owner / Security / Operations | OPEN — BLOCKING |
| D-036 | Dependency | CMD-051 policy publish requires an approved notification.policy.manage grant, scope, grantor ceiling, policy schema/selector allowlist and SoD; persisted draft CRUD is excluded | G5/G9; unauthorized global policy mutation | PO/Security approve exact policy schema, role/scope/grantor matrix and publish authority; any draft workflow requires separate command/schema approval | PO / Security | OPEN — BLOCKING |
| R-034 | Risk | Event-time audience semantics are PO-approved, but the durable recipient/scope snapshot is not admitted; if fan-out retries re-resolve current role/assignment membership, recipients may be added, omitted or exposed outside the original event scope | High | Persist immutable event-time recipient/scope candidates and snapshot hash/count before source transaction commit; retries consume only that set; dispatch-time revalidation may suppress only; never widen audience | PO / Security / Engineering / Database | OPEN — BLOCKING |
| R-035 | Risk | Ambiguous provider acceptance followed by blind retry may duplicate a sensitive notification; callbacks may arrive late or out of order | High | Keep UNKNOWN until safe reconciliation, use provider idempotency where supported, authenticate INT-NOTIF-001, enforce monotonic transitions and alert on unresolved age | Engineering / Security / Operations | MITIGATING BY DESIGN; VERIFICATION OPEN |

CMD-049–054 Detailed Contract Review v0.1.1 and NLA-001 v0.1.2 resolve several documentation-level mismatches only. D-034..D-036 and R-034..R-035 remain open; no worker, provider, role, grant, route, table, SQL or test execution is authorized by this register update.


## Identifier uniqueness audit correction — 2026-11-24

The final documentation audit detected a duplicate risk identifier. R-014 remains assigned to the project-wide scope-freeze risk. The alternative provider-ownership continuity risk is now R-036. The risk description, impact, likelihood, mitigation, owner and OPEN status are unchanged. RAID identifiers are unique within this register.


## Cross-document governance audit checkpoint — 2026-11-24

The static audit in [SSOT-AUDIT-001](SSOT-CROSS-DOCUMENT-RECONCILIATION-AUDIT.md) reconciled the current DGA, RTM, Decision Register, Package S and Package T status without changing the authority or risk meaning of existing entries.

- Existing 53 unique RAID identifiers are retained; no risk, assumption, issue or dependency is marked closed by this documentation audit.
- D-031..D-036 remain institutional/provider/worker/policy dependencies as recorded.
- R-032..R-036 remain open or verification-open; documentation mitigations do not establish technical or operational closure.
- T-10 and T-12 PO decisions approve governance paths only; institutional/provider evidence remains outstanding.
- RTM T-13 print verification now maps to TC-PRINT-001..007 and TC-PRINT-BATCH-001..008; no test has been executed.
- Package S §9.15 remains historical; §9.16 is the current inventory snapshot. Package T v0.1.1 remains a historical decision pack, with the Decision Register as current PO authority.

No RAID owner has been replaced with an invented person or institution. No new risk is assigned without evidence of a distinct risk beyond the existing DGA/RAID register. The PO and authority requests are tracked in POQ-001 and AUTH-001.

**Status:** RAID review remains OPEN for the existing dependencies and risks. No external approval, technical certification, implementation, test, merge or release evidence is implied.


## Notification audience snapshot lock-order risk — 2026-11-24

| ID | Type | Description | Impact | Mitigation / response | Accountable role | Status |
|---|---|---|---|---|---|---|
| R-037 | Risk | POQ-01 event-time audience snapshot persistence may introduce implicit FK KEY SHARE locks to app_users and project/session/location/assignment rows after a source command, CMD-052 or CMD-054 already holds higher-ranked aggregate/queue/policy locks; this may invert L15/L16/L17/L30/L50/L55 order and create deadlocks or inconsistent eligibility snapshots | Critical | Keep notification_outbox_recipients candidate-only until every source event/worker path, competing account/scope writer and implicit FK/index/trigger/helper edge is mapped; define one event-time linearization and canonical order; prove the full graph acyclic and execute deterministic opposing-transaction tests before G9 | Engineering / Database / Security / QA | OPEN — CRITICAL |


### R-037 resolver lock-set refinement — 2026-11-24

The source event declaration inventory is complete at 40/40 in LOCK-MANIFEST-001 §7.7. The remaining gap is complete recipient-resolver lock-set coverage: 0/40 source paths certified. [NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001](../02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) v0.1.5 proposes a global L05 audience guard or a SERIALIZABLE predicate snapshot and records required writer participation, FK pre-acquisition and adversarial tests. These are alternatives for review, not approved controls. R-037 remains OPEN — CRITICAL until the event-time linearization, selected mechanism, exact FK graph, every eligibility-changing writer, acyclicity and authorized runtime evidence are closed. 0/50 application lock-certified; G9 NOT READY; G10 NOT ACTIVE.


### R-037 decision update — 2026-11-24

PO has selected candidate L05 (global transaction-scoped audience guard) as the primary mechanism for technical approval review; Option B SERIALIZABLE remains contingency-only. See [NLA-RESOLVER-LOCK-001 v0.1.6](../02-architecture/NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) §11. R-037 remains OPEN — CRITICAL pending Engineering/Database/Security approval of the exact PostgreSQL primitive/key, rank/order, complete eligibility-writer participation, FK/trigger/helper edges, timeout/retry, contention bounds and graph acyclicity. This PO selection does not authorize implementation or admit L05 as a canonical rank. Resolver certification 0/40; application lock certification 0/50; G9 NOT READY; G10 NOT ACTIVE.


### R-037 technical protocol checkpoint — 2026-11-24

[NLA-L05-TDR-001 v0.1.0](../02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) proposes a transaction-scoped two-key PostgreSQL advisory lock at candidate L05. Exact key pair/registry, deployed READ COMMITTED configuration, complete writer mapping, helper ACL, FK/unique/trigger graph, numeric lock/transaction/retry budgets, audience cap, SLO and acyclicity evidence remain OPEN. R-037 remains OPEN — CRITICAL; no technical approval or implementation authorization is inferred. Resolver certification 0/40; application lock certification 0/50.


### R-037 PO decision — 2026-11-24

The Product Owner approved NLA-L05-TDR-001 v0.1.1 as the preferred technical candidate for Engineering/Database/Security review. This is candidate-direction approval only. L05 remains unadmitted; R-037 remains OPEN — CRITICAL until technical approvals, complete 40-source resolver lock coverage, FK/trigger graph, acyclicity proof and concurrency evidence are complete. No implementation authorization is created.
