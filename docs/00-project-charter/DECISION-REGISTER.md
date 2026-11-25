# Decision Register — Dit. SD Inspection

Only explicitly approved decisions are marked APPROVED.

| ID | Decision | Status | Notes |
|---|---|---|---|
| MGT-001 | Production is the release target | APPROVED | User decision, 2026-11-23 |
| MGT-002 | Cost-first engineering priority | APPROVED | Optimize lifecycle cost; retain security and reliability controls |
| TECH-001 | Use Supabase and Vercel | APPROVED | User decision, 2026-11-23 |
| TECH-002 | Supabase PostgreSQL is the single source of truth | APPROVED | No second primary database |
| TECH-003 | GitHub for source control and CI | APPROVED | Existing private repository |
| PRD-001 | Replace existing Dit. SD inspection application | APPROVED | Not SaaS |
| PRD-002 | Initial rollout contains IFP and Standing Bracket; platform supports additional Super Admin-configured instrument types | APPROVED | CFG-001 governs extensibility; additional types require configuration and project-use approval |
| PRD-003 | Feature parity first; improvements second | APPROVED | Legacy app is reference, not code dependency |
| PRD-004 | No access to legacy source code is assumed | CONFIRMED | Reconstruct from supplied references |
| RBAC-001 | Google sign-in; new users require approval and role assignment | APPROVED | No self-role elevation |
| RBAC-002 | Multi-role accounts allowed with explicit operational assignment | APPROVED | Scope by session/location/instrument; no self-review |
| WF-001 | Reviewer returns corrections to Inspector; Inspector resubmits | APPROVED | Immutable version history |
| WF-002 | Reopening approved inspection requires authority, reason, and audit | APPROVED | Explicit permission required |
| SES-001 | Each unit inspection attempt is bound to exactly one session; a returned inspection may be ABORTED only when a detected error cannot be corrected/reinspected because the physical unit has already been packed and prepared for shipment; Inspector requests and Admin/Korlap approves | APPROVED | Normal returned corrections remain with the same Inspector in the original active session; ABORTED is terminal and is not approval/completion; a later session uses a new attempt |
| WF-003 | Session closure requires every assigned unit attempt to reach an allowed terminal outcome; ABORT is permitted only through the SES-001 packed-unit exception with Inspector request and Admin/Korlap approval | APPROVED | Otherwise returned work follows WF-001 correction/resubmission; ABORTED remains explicit non-completion and cannot bypass other close gates |
| RPT-001 | Actual and Target reports are separate | APPROVED | Daily, weekly, and final variants |
| RPT-002 | Actual records retain true activity dates/times | APPROVED | Never rewrite actual activity to match target allocation |
| DOC-001 | Wet signature in Phase 1; no digital signature substitution | APPROVED | Per-unit print does not assert signature verification |
| DOC-002 | Per-unit completion follows approval, final PDF generation, and print action | APPROVED | Print click logged; reprints increment count |
| INS-001 | Instrument definitions are versioned; active sessions freeze version | APPROVED | Historical inspection preserves snapshot |
| CFG-001 | All inspection instrument types are configurable and managed by Super Admin | APPROVED | IFP and Standing Bracket are the initial configured instruments, not a permanent hardcoded limit. Super Admin can create, configure, activate/deactivate, and version instrument definitions using supported configuration primitives; adding a supported instrument must not require application code changes. Existing sessions and historical inspections retain their frozen configuration snapshots. Arbitrary executable/custom code is not part of instrument configuration. User decision, 2026-11-23 |
| INS-002 | Exception-based checklist UI | APPROVED | Default OK presentation is not automatic verification |
| INS-003 | Limited offline inspection and safe sync | APPROVED | Final submit/approval server-side |
| INS-004 | One active inspection per Inspector | APPROVED | Submitted work is no longer actively edited |
| INS-005 | SN scan/entry claims a unit; prevent duplicate active claims | APPROVED | Preserve draft and claim history |
| INS-006 | Recovery and claim protection | APPROVED | Device loss/offline must not discard evidence |
| INS-007 | Evidence integrity and dual actual/target time dimensions | APPROVED | Device timestamp is not proof of capture time |
| INS-008 | Normalized serial duplicate prevention | APPROVED | Reinspection requires authorization |
| INS-009 | Pre-submit validation | APPROVED | Findings need note/evidence; unresolved sync conflict blocks submit |
| INS-010 | Immutable inspection revisions | APPROVED | Reviewer cannot silently edit Inspector results |
| INS-011 | Approval/PDF/print drives per-unit completion | APPROVED | Print click logged; reprints increment count |
| INS-012 | Separate Print Officer role | APPROVED | Explicit assignment and scoped permission |
| INS-013 | Scoped assignments and bulk print | APPROVED | Bulk print logs batch and per-document events |
| INS-014 | Role-based operational dashboards | APPROVED | Data scope follows assignments |
| INS-015 | Scoped notification and escalation management | APPROVED | SLA values configurable; examples are not fixed |
| INS-016 | Audit trail and activity monitoring | PO APPROVED (T-15 option A) | Append-only audit policy; critical mutation + audit atomicity; fail-closed on audit failure; least-privilege read/export. Institutional classification, retention, deletion/disposition, legal hold and network-metadata decisions remain BLOCKED under T-10; implementation and tests are not authorized/verified. |
| OPS-001 | Inspector capacity is configurable from minimum 1 to maximum 100, default 50, across both locations combined | APPROVED | User clarification, 2026-11-23; Super Admin controls the configured capacity and allocation between locations; the limit is global, not per location; values below 1 or above 100 are rejected |

## Open decisions
- Complete official IFP and Standing Bracket checklists and required photo slots.
- Institutional approval of actual BA signatory roles/identities and the final BA template (template configurability is PO-approved under T-02).
- Official IFP and Standing Bracket source documents and photo-slot requirements remain to be obtained and reconciled (T-01).
- Detailed report metric implementation and acceptance-test evidence (T-05 direction approved).
- Detailed project closure gate enforcement and reconciliation evidence (T-06 direction approved).
- Detailed session pause/reopen command and permission tests (T-07 direction approved).
- Whether a privilegedly reopened CLOSED session may accept a new inspection attempt under the same session_id; ABORTED attempts remain terminal and must never be reactivated (SES-001 technical/product edge case).
- Detailed attendance evidence acceptance and verification tests (T-08 direction approved).
- Offline package, conflict resolution, and device recovery details.
- Evidence file limits, retention, deletion, privacy, and access policy.
- Supabase/Vercel project organization, environments, backup and retention configuration.
- Production usage estimates and plan upgrade criteria.
- CI provider quotas and required branch protection checks.

Proposed or illustrative decisions are not approved until explicitly accepted.

**POQ-001 disposition (2026-11-24): CLOSED — all three Product Owner questions approved.** POQ-01 = Option C (hybrid event-time candidate audience with dispatch-time account/channel revalidation and no recipient widening); POQ-02 = Option C (versioned per-policy elapsed/business-time choice, initial default `ELAPSED_UTC`; quiet hours defer delivery only and do not pause SLA); POQ-03 = Option A (dismiss/archive excluded from MVP; recipient-owned set-once `read_at` only; no dismiss command or permission). See the dated decision record below. These approvals settle product semantics only and do not approve technical execution, institutional policy, implementation or release.

## Product Owner decisions — Package T (2026-11-23)

| ID | Decision | State | Qualification / remaining dependency |
| T-01 | Official, institutionally approved source documents are the authoritative master for IFP and Standing Bracket checklist/specification/evidence requirements. | PO APPROVED | The actual controlled source documents, completeness reconciliation, issuing authority and formal institutional approval evidence are still outstanding. Do not treat current transcriptions/screenshots as approved master data. |
| T-02 | BA signatory blocks are configurable per approved BA template, including number/party, organization, role/title, order and required/optional status. | PO APPROVED | Actual authorized signatory identities, authority and final template remain subject to institutional approval. Sample parties are not universal defaults. |
| T-03 | Executive-summary signature behavior is configurable per report template. | PO APPROVED | Default may be no signature unless the approved template requires it. Any mandatory signature rule must be supported by the approved institutional template. |
| T-04 | Initial release uses PDF-only client report delivery; a client portal is deferred from initial scope. | PO APPROVED | PDF access/distribution remains permission-controlled and audited. Portal requires a later change request and approval. |

Product Owner additionally confirmed on 2026-11-23 that `Pemeriksaan Barang_SB.pdf` is the official Standing Bracket instrument document. The 19 visible rows (6 physical + 13 accessories) are the official baseline from that document. This PO confirmation establishes the document's status for this project; it does not authorize changing ambiguous source wording or infer photo rules absent from the document. Institutional approvals beyond the PO's authority, if required by the institution's governance, remain external. T-05 through T-08 were explicitly approved by the Product Owner on 2026-11-23 (A/A/A/A); T-09 was subsequently approved as option B on 2026-11-23; T-10 option B is PO APPROVED as the required formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED: current mainstream stable browsers with explicit exclusions; exact device/OS/build matrix and numeric SLOs remain open pending UAT and provider verification. T-12 option C is PO APPROVED as an alternative provider-ownership arrangement subject to formal institutional definition and approval; actual owner, billing owner, custodians, region, provider plan and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 is PO APPROVED (A); T-15 through T-18 have PO direction approved; residual design/implementation gates remain OPEN/BLOCKED.

## Remaining open decisions
- T-01: Standing Bracket official instrument document confirmed by Product Owner on 2026-11-23. Reconcile the 19-row checklist verbatim and preserve ambiguous wording. Remaining: confirm photo-slot requirements, any additional annex/specification, and authoritative IFP source document.
- T-02: obtain institutional approval for authorized BA signatory roles/identities and final template.
- T-09: PO APPROVED option B (limited offline draft editing with controls still gated). T-10: PO APPROVED option B (formal institutional records/legal/privacy review path); resulting institutional policy remains BLOCKED pending written authority. T-11: PO APPROVED option B (current mainstream stable browsers with explicit exclusions); exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12: PO APPROVED option C (alternative provider-ownership arrangement subject to formal institutional definition and approval); actual owner, billing owner, custodians, region, provider plan and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 is PO APPROVED option A; T-15 through T-18 have explicit PO direction approved; detailed design, institutional gates and implementation verification remain open.

## Product Owner decisions — Package T continuation (2026-11-23)

| T-05 | Actual reports show distinct, separately labelled Inspected, Submitted, Approved and Completed counts. Completed retains the approved inspection + final PDF generated + Print Officer print action recorded definition. | PO APPROVED | Metric definitions, timestamp/filter display and report acceptance tests must be implemented and verified; a print action does not prove physical paper output. |
| T-06 | Super Admin is the final project-closure authority after all required closure gates and actual-versus-target reconciliation are satisfied. Closure is explicit, non-automatic, reasoned and audited. | PO APPROVED | No date-based auto-close. Exceptions require separately permissioned override, reason and audit. Operational gate completeness remains to be implemented and tested. |
| T-07 | Super Admin exclusively creates/configures sessions, targets, locations, instruments and team assignments. Korlap may activate, pause, resume or request closure only within assigned scope and granted permissions. States: DRAFT, ACTIVE, PAUSED, CLOSED; CLOSED is terminal in ordinary flow. | PO APPROVED | Reopening a CLOSED session requires explicit privileged permission, reason and audit. Permission matrix and state-transition tests remain to be completed. |
| T-08 | Korlap verifies attendance within assigned location/scope, with separate permissions for generate, print, upload, download and verify. Upload never automatically sets VERIFIED. | PO APPROVED | Super Admin assigns/grants verifier authority. Artifact integrity, verification rules and audit behavior remain to be implemented and tested. |
| T-13 | Initial release supports individual and bounded batch printing from a permissioned Print Officer queue; per-document outcomes and atomic reprint sequence are recorded. | PO APPROVED (B) | Retry only failed documents; no duplicate success events. Application print action is not proof of physical paper output. Direct printer integration is not selected. |

These are Product Owner decisions recorded from the explicit response dated 2026-11-23. They settle the product direction for T-05 through T-08 but do not constitute implementation, UAT, or institutional approval where required.

## Product Owner decision — Package T T-09 (2026-11-23)

**T-09: PO APPROVED option B — limited offline draft editing.** Offline continuation is permitted only for an inspection draft whose unit was already claimed while online. Offline claim acquisition, approval, final submission, role/assignment changes, session administration and privileged actions are prohibited. Reconnection must use authenticated, idempotent synchronization, recheck server authorization and claim/state, reject stale conflicting writes, preserve local and server versions for explicit resolution, and never silently overwrite newer server data. Required evidence must be server-confirmed before final submission.

This approval does not authorize production activation of offline persistence. Supported device/browser matrix, local-data protection/encryption, shared-device logout, retention/purge, local recovery and institutional records/privacy approval remain open dependencies (T-10/T-11). T-09 PO direction is approved; implementation and tests remain pending. T-10 option B is PO APPROVED as the formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED; the actual alternative arrangement and institutional/provider verification remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 is PO APPROVED option A; T-15 through T-18 have PO direction approved; residual design/implementation gates remain OPEN/BLOCKED.

## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.

## Package T-11 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — support current mainstream browser versions with explicit exclusions.** The supported baseline is:
- Inspector field workflow: Android devices using a current stable Google Chrome release, with camera permission and evidence upload capability.
- Korlap and Reviewer: desktop Chrome or Microsoft Edge current stable releases.
- Super Admin and Print Officer: desktop Chrome or Microsoft Edge current stable releases, including PDF viewing and browser print workflow.
- Tablet layouts may be used only after responsive, camera, upload and PDF/print validation; tablet support is not presumed from viewport rendering alone.
- Explicit exclusions: obsolete/unsupported browser releases, embedded in-app browsers, modified browsers, and devices that fail required camera, upload, authentication, offline-safety or PDF/print tests.

Exact OS/device minimum versions and the tested browser build numbers must be recorded in the release/UAT compatibility matrix; this PO decision does not invent exact version numbers. The 100 concurrent authenticated-user load-test target remains the required acceptance load profile and must be tested at staged levels (10, 25, 50, 75, 100). This is a test target, not a demonstrated production capacity or service-level guarantee. Numeric latency/error-rate SLOs remain OPEN until workload and actual Supabase/Vercel plan/region/quotas are verified and baseline measurements are collected. No implementation, compatibility test or load test is claimed as executed.

## Package T-12 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option C — an alternative provider-ownership arrangement, subject to formal institutional approval and written definition.** The Product Owner does not designate a specific legal entity, account holder, billing owner, custodian, or contractual arrangement in this approval. Those identities and responsibilities must not be inferred or invented.

Before any production provider account or production data is used, the institution must document and authorize the selected arrangement, including: (1) legal/account owner for Supabase and Vercel; (2) billing owner, payment method and budget authority; (3) named primary and secondary provider custodians/recovery contacts; (4) access grant, MFA, least-privilege and offboarding controls; (5) project/data ownership and transfer/exit rights; (6) region and data-residency approver; and (7) incident, backup, restore and escalation responsibility. The arrangement must ensure continuity if a developer or individual custodian leaves.

This PO decision approves the alternative-arrangement path only. It does not establish institutional authorization, identify the actual owner/custodians, approve a region or provider plan, approve billing, or prove backup/recovery capability. Provider plan/quotas, region, budget, RPO/RTO, Storage object recovery and restore-drill evidence remain OPEN/BLOCKED until verified against actual accounts and approved by authorized institutional parties. No production data deployment or production readiness is authorized by this decision. No implementation or restore test is claimed as executed.

## Product Owner decision — Package T T-13 (2026-11-23)

PO APPROVED option B — individual and batch printing. Initial release includes individual print and bounded/configurable batch print through the permissioned Print Officer queue. Each document in a batch has an independent outcome; retry targets failed documents only and must not duplicate successful print events. Print/reprint events preserve actor, timestamp, document version, atomic sequence and outcome where available. The application records the print action, not physical printer output. Direct printer integration is excluded from this decision. Implementation and tests remain pending.





### T-14 — Inspector capacity counting predicate (2026-11-24)

**Status: PO APPROVED — option A.** Capacity counts distinct accounts that are enabled for login, have an active Inspector role grant, and have at least one currently effective operational Inspector assignment within the governed project/session scope. Count an account once regardless of its number of assignments or roles. Exclude pending, rejected, suspended, disabled, and expired-role accounts. Enforce atomically against the approved combined 1–100 cap (default 50); reject 0, values above 100, and cap reductions below the current qualifying count until reconciled. No silent deactivation. This is PO approval only; implementation and tests remain pending.


### T-14 clarification — registration, roles, teams and staffing (2026-11-24)

A user must register/authenticate before Super Admin can approve the account and configure roles, permissions, scope, team membership and operational assignment. Registration by itself does not grant access and is not sufficient to count toward Inspector capacity. Super Admin exclusively determines the number of teams and the personnel assigned to each team, within the approved capacity and project/session plan. Self-assignment of roles, teams or operational assignments is prohibited.



### T-15 — Audit event policy INS-016 (2026-11-24)

**Status: PO APPROVED — option A.** Approve the proposed append-only audit event catalogue and mandatory atomicity for critical mutations: the state change and audit event must commit in the same database transaction; audit-write failure rolls back/fails closed the critical mutation. Events must capture actor, active role, applicable scope, action/event type, timestamp, correlation/idempotency references and privacy-safe change context. Sensitive evidence access and export must be audited. Audit access is least-privilege; ordinary application roles cannot update/delete recorded events. T-10 institutional approval remains required for classification, retention, deletion/disposition, legal hold and network metadata; no retention duration or metadata collection is approved by T-15. Implementation, schema/RLS reconciliation and tests remain pending; this PO decision does not authorize implementation or production activation.


### T-16 — Serial uniqueness and evidence/revision linkage (PO APPROVED option B, 2026-11-24)

Within each instrument type, a normalized serial number is unique across all projects. The uniqueness scope is `(instrument_type, serial_normalized)` and does not extend across different instrument types. A same-type duplicate found in another project is a controlled conflict: require authorized review, reason and audit; never silently merge, overwrite or discard historical unit/inspection records. Evidence must reference the exact immutable inspection revision and instrument version and preserve original metadata, checksum, uploader, capture/upload timestamps and immutable storage object identity. Evidence replacement creates a new evidence record and audit event; no in-place overwrite. This PO decision does not establish institution-approved exception policy or implementation completion.


## Package T — T-17 decision update (2026-11-24)

| ID | Decision | State | Qualification / remaining dependency |
|---|---|---|---|
| T-17 / CFG-001 | **PO APPROVED option A:** Super Admin may directly publish an instrument version after server-side validation using bounded declarative field types and validation primitives; no second-person publication approval is required. | PO APPROVED (A) | `instrument.publish` remains an explicit Super Admin permission. Publication is an atomic, audited command; published versions are immutable; active sessions/assignments pin versions and historical revisions retain exact snapshots. Deactivation is separate and audited. Schema/RLS/command/test reconciliation remains OPEN; no migration, code or tests are claimed. |

The approval does not relax project/session/assignment-scoped operational access. A globally canonical unit identity does not grant global inspection access; every inspection action remains constrained by project, session, assignment and permission. T-16 canonical identity/association model is documented; technical review and institution-approved serial normalization/exception policy remain required before migration.


## Package T — T-18 decision update (2026-11-24)

**Status: PO APPROVED — option A.** Adopt Vercel server routes as the application command boundary and narrowly scoped PostgreSQL command functions invoked with the caller's authenticated Supabase JWT. The route validates the command envelope and verified session; PostgreSQL derives actor identity from auth.uid(), then checks account state, explicit permission, role, project/session/assignment scope, resource state and separation of duties. Client-supplied actor/role/scope are never authoritative. Browser direct DML to protected tables is denied by grants/RLS. Each command validates inputs/transitions, applies concurrency controls and idempotency, and commits business state plus required event/audit writes atomically; audit failure rolls back. Service-role credentials are never exposed to browsers and are not the default command identity. SECURITY DEFINER exceptions require pinned search_path, strict review and minimal grants. This is architecture approval only; command-specific design, RLS/grants, T-16 technical review and institutional gates, implementation and tests remain pending. Scope freeze remains NOT READY; implementation is NOT AUTHORIZED.


### T-16 design reconciliation — canonical association model (2026-11-24)

Architecture specifications now separate canonical unit identity from project membership: `units` is keyed by instrument + normalized serial; `unit_project_associations` preserves project association episodes; `unit_identity_conflicts` provides reasoned duplicate review; inspections and claims bind to exact association and same-project assignment; active claim uniqueness remains global per physical unit. Cross-project access is not implied by canonical identity. This is a documented design resolution pending technical review and institutional serial policy; implementation/migration/tests remain unexecuted and unauthorized.


## T-18 execution-model clarification — PO APPROVED Option A (2026-11-24)

The Product Owner explicitly approves **Option A: narrow SECURITY DEFINER PostgreSQL command wrappers** for protected state-changing commands, combined with SECURITY INVOKER for read-only/scoped operations where feasible. Each protected-write function must have a dedicated least-privileged NOLOGIN owner, fixed `search_path = ''`, fully qualified references, exact-signature EXECUTE grants, PUBLIC/anon denial, caller-JWT actor derivation through `auth.uid()`, database-backed permission/scope/state/SoD checks, and atomic mutation + event + audit + idempotency. The owner must not be SUPERUSER, BYPASSRLS, LOGIN, protected-table owner, or inherit broad owner privileges. Browser direct DML remains denied; service_role is not the default user-command identity. Option B is not selected; Option C remains incompatible with T-18.

This approval selects the execution model only. Exact functions, owners, signatures, grants, RLS, routes, migration and implementation remain subject to live inventory, per-function threat review, acceptance tests and separate implementation authorization. Live inventory and runtime tests are not executed. Scope freeze remains NOT READY; implementation remains NOT AUTHORIZED. See [T-18 Execution Model Security Review](../02-architecture/T18-EXECUTION-MODEL-SECURITY-REVIEW.md).

## Lock protocol — Product Owner decisions (2026-11-24)

The Product Owner approved the following product/domain decisions in response to LPR-02–LPR-06. These decisions settle product semantics only; they do not approve PostgreSQL lock primitives, physical constraints, function ownership/privileges, RLS, or implementation.

| ID | Decision | State | Qualification / remaining dependency |
|---|---|---|---|
| LPR-02 | Canonical unit identity is the instrument type plus normalized serial number; the identity remains global across projects. | PO APPROVED | Consistent with T-16: uniqueness scope is (instrument_type, serial_normalized). Cross-project duplicates are controlled conflicts requiring authorized review, reason and audit; no silent merge/overwrite. Exact normalization rules, canonical key arbitration, physical constraints and exception policy require technical/institutional review. |
| LPR-03 | A valid active claim is mandatory before every normal inspection workflow. | PO APPROVED | No implicit bypass. Any administrative correction/migration exception must use a separately permissioned, reasoned and audited path; exact command/permission and historical-data treatment require Engineering/Security review. |
| LPR-04 | A closed project/session rejects new normal mutations and finalization. Reopening requires an explicit privileged workflow, reason and audit. | PO APPROVED | Consistent with T-06/T-07: closure remains explicit and gated; CLOSED is terminal in ordinary flow. In-flight writers/finalizers must serialize against the parent closure fence. Exact gate matrix and institutional operational exceptions remain subject to owner review. |
| LPR-05 | T-14 Inspector capacity uses the already approved T-14 predicate and a single serialization point for every eligibility/capacity-changing path. | PO APPROVED — clarification of existing T-14 | Controlling predicate remains T-14: count distinct login-enabled accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment within governed project/session scope; count each account once. Registration alone, pending/rejected/suspended/disabled accounts and expired role grants do not count. Team/membership and assignment changes must participate where they change this qualifying population. This clarification does not replace or weaken T-14 or its approved 1–100 combined cap/default 50. |
| LPR-06 | Instrument deactivation blocks new assignment selection; already-pinned sessions retain their immutable historical instrument version by default. | PO APPROVED | A safety withdrawal may explicitly override continued use through a separately authorized, reasoned and audited safety workflow. Exact withdrawal authority, affected-session handling, concurrency and technical enforcement remain open. |

**Authority boundary:** LPR-01 candidate global rank hierarchy and LPR-07–LPR-10 remain OPEN for Engineering/Security/QA/Operations and, where applicable, institutional approval and evidence. These PO decisions do not close DGA-B18/B19/B20, certify the lock graph, or authorize tests, SQL, migrations, grants, deployment or implementation.



## Product Owner decisions — CMD-011–020 (2026-11-24)

**Approval record:** The Product Owner explicitly approved the recommended product decisions in the CMD-011–020 decision package on 2026-11-24. This record approves product semantics and business invariants only. It does not approve PostgreSQL lock modes, constraints, function ownership/privileges, RLS, implementation, tests, deployment or institutional matters reserved to authorized institutional owners.

| Decision group | Approved product direction | Qualification / remaining dependency |
|---|---|---|
| CMD-011 — session creation | Server selects the initial session state; session creation is permitted only under a project state that the canonical project lifecycle defines as planning/open; session times are UTC instants interpreted from local input using the project's canonical IANA timezone; overlapping sessions are not prohibited by default. | **Compatibility resolution:** initial state is the already-governed `DRAFT` from T-07, not a new `PLANNED` enum. Exact project-state labels must be copied from the canonical project state machine. DST-ambiguous/nonexistent local input must be rejected. Project/code uniqueness and parent closure fencing remain technical design items. |
| CMD-012 — session update | Session code is immutable after creation; only allowlisted non-identity metadata may be updated; once dependent work references the session, schedule changes that reinterpret existing work are rejected; every accepted metadata update requires a non-empty reason. | Exact dependent-work predicate, metadata allowlist, row-version token and concurrency enforcement require Engineering/QA reconciliation. |
| CMD-013 — session transition/closure | Preserve T-07's canonical session states: `DRAFT`, `ACTIVE`, `PAUSED`, `CLOSED`; allowed transitions are explicit; `CLOSED` is terminal in ordinary flow. Korlap may activate/pause/resume/request closure only within assigned scope and explicit permission. Final closure is a distinct authorized action after checklist/gate validation; reopening requires a separate privileged, reasoned and audited workflow. | **Compatibility resolution:** `CLOSE_REQUESTED` is a request action/event, not a new persisted session state. Super Admin remains the final closure authority consistent with T-06/T-07. Permission edges, closure checklist and privileged reopen authority require detailed reconciliation and institutional review where applicable. |
| CMD-014 — assignment publication | Create-only command; one command creates one assignment and its complete initial roster atomically; server selects the initial published state after all validations; assignment intervals are half-open `[start,end)`; overlapping effective membership is rejected only where it creates duplicate/conflicting Inspector eligibility in the same governed project/session scope. | Exact lifecycle enum, overlap predicate, T-14 capacity serialization and roster transaction design require Engineering/Security/QA review. |
| CMD-015 — assignment membership changes | Each membership end has its own `effective_at`; accepted changes require a reason; membership history is ended, not hard-deleted; submitted inspections are never deleted, reassigned or invalidated by member removal. | Active claims/in-progress workflow orphaning behavior and any transfer/grandfathering exception require operational-owner review. Retention duration remains governed by T-10 institutional approval and is not set here. |
| CMD-016 — Inspector capacity | Reaffirm existing T-14: integer cap 1–100, default 50; count distinct enabled login accounts with active Inspector role and at least one currently effective operational Inspector assignment in governed project/session scope; reject cap reduction below current qualifying count and never silently revoke roles/assignments. | Existing T-14 remains controlling; no new or altered capacity decision is created. Atomic serialization, row version and physical enforcement remain technical work. |
| CMD-017 — target plans | Prefer session-scoped plans; project-wide plans require a separately justified and explicitly scoped product change. Commands use one explicit action from `CREATE_DRAFT`, `REPLACE_DRAFT_ALLOCATIONS`, `PUBLISH`; published plans are immutable and corrections create a new version. Allocation uniqueness is `(target_plan_id, assignment_id, target_date)`; duplicate rows are rejected; zero quantity is rejected. | Canonical project/session lifecycle and exact target quantity units/ranges must be reconciled in contracts and validation. |
| CMD-018 — instrument creation | New instruments are created in a non-selectable draft/inactive state and cannot be assigned until a version is published. Instrument codes are normalized using Unicode NFKC, surrounding-whitespace trim, invariant uppercase for the approved ASCII code alphabet, rejection of internal whitespace/control characters, and uniqueness on normalized value. | Engineering/Security must validate Unicode edge cases, permitted alphabet and database collation/constraint implementation before making the normalization contract executable. |
| CMD-019 — instrument draft | Draft save replaces the complete declarative configuration atomically; omitted children are removed from the draft only; published snapshots remain immutable; each save requires a meaningful change summary. Configuration is restricted to versioned, allowlisted declarative primitives and excludes executable expressions, dynamic code, arbitrary regex execution and unbounded recursion. | Security/Engineering must approve the exact schema, primitive allowlist, depth/size bounds, stable child identity rules, canonical hash and concurrency token. |
| CMD-020 — instrument publication | Reaffirm T-17: Super Admin with explicit `instrument.publish` may publish after server-side validation; `instrument.manage` alone is insufficient; published version and children are immutable; corrections create a new version; assignments/sessions remain pinned; same idempotency key returns the original result and a different key against an already-published version returns an immutable/already-published outcome without a duplicate publication event. | T-17 remains controlling and is not reopened. Exact command, hash, ACL, publication atomicity and audit behavior require Engineering/Security/QA review. |

**Authority and status boundary:** These decisions close the Product Owner decision response for the product-semantic portions of CMD-011–020. They do not close DGA-B10/B18/B19/B21, certify any lock manifest, or authorize source code, SQL, migrations, CI, automated/concurrency tests, live database inspection, deployment or merge. LPR-01 and LPR-07–LPR-11 remain with Engineering/Security/Database/QA/Operations as specified in the decision package. T-10 institutional records/legal/privacy decisions and other external authorities remain outstanding where applicable.


## Product Owner decisions — POQ-001 notification semantics (2026-11-24)

**Approval record:** The Product Owner explicitly approved the three recommended options on 2026-11-24. These decisions close POQ-01 through POQ-03 at Product Owner authority level only.

| ID | Decision | State | Qualification / remaining dependency |
|---|---|---|---|
| POQ-01 | **APPROVED — Option C (hybrid recipient eligibility).** At source-event time, persist the deterministic candidate audience and its authorized source scope/checkpoint. Before each external send, revalidate current account status, channel eligibility, consent/revocation and mandatory security restrictions. Revalidation may suppress an original candidate but must never add a recipient outside the persisted event-time candidate audience. Retries reuse the same immutable candidate audience/checkpoint. | PO APPROVED | Exact selector grammar, durable snapshot representation/checkpoint, partial fan-out/retry semantics, current-scope revalidation and security controls require Engineering/Security review and cross-document implementation design. |
| POQ-02 | **APPROVED — Option C (per-policy SLA semantics).** Each immutable policy version declares elapsed-time or business-time semantics. Initial release default is `ELAPSED_UTC`. Quiet hours delay eligible channel delivery only and do not pause or stop the SLA clock. | PO APPROVED | Business-time calendars/time zones, pause/reset conditions, named SLA start events, and any policy-specific exceptions require explicit design and Security/Operations review. Do not activate unapproved calendars or pause rules. |
| POQ-03 | **APPROVED — Option A (dismiss/archive excluded from MVP).** Initial release exposes recipient-owned set-once `read_at` only. No dismiss/archive command, permission, browser write or UX action is in MVP scope. `dismissed_at`, if retained in a physical proposal, is dormant and has no behavior. | PO APPROVED | Remove dismissal from MVP command/API/permission/UX contracts; any future inclusion requires a separately scoped change request and review. |

These decisions are effective 2026-11-24 for documentation and design reconciliation. They do not approve selector implementation, SLA worker execution, schema/RLS/grants, providers, institutional retention/privacy policy, G9 scope freeze, G10 implementation authorization, tests, deployment or merge.



## Product Owner decision — CMD-045–048 control-plane disposition (2026-11-24)

**Decision: APPROVED — CMD-045–048 Control-Plane Resolution Proposal v0.1.0.** The Product Owner explicitly accepted the proposal on 2026-11-24.

The four stable logical IDs remain reserved for traceability, but the operations are not application commands and must not be implemented as browser routes, RPCs, PostgreSQL functions, generic CRUD endpoints, application permission grants or application-managed control planes:
- CMD-045 retention/legal-hold: institutional records/legal/privacy control plane. The application must not invent retention schedules, initiate disposition, or release legal holds.
- CMD-046 security incident review: institution-designated incident-response control plane. No application security-case CRUD, generic reviewer permission or implicit account/provider mitigation.
- CMD-047 provider configuration: provider-native console and institution-approved secret-management/operations control plane. No application credential/configuration CRUD and no secret material in application data, requests, logs or audit.
- CMD-048 production release: protected source-control/deployment control plane. No application deploy/rollback endpoint or bypass of GitHub/Vercel protections.

Canonical disposition:
- CMD-045: `DEFERRED_EXTERNAL_CONTROL_PLANE`.
- CMD-046: `DEFERRED_EXTERNAL_CONTROL_PLANE`.
- CMD-047: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL`.
- CMD-048: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL`.

These dispositions close the application-surface design ambiguity only. They do not close T-10 institutional records/privacy policy, T-12 provider ownership and recovery evidence, security incident-response RACI, repository/release governance, CI/protected-environment verification, DGA-B04/B05/B15, or G8/G9 operational readiness. No permission grants, source code, SQL, migrations, live provider changes, deployment, CI execution or release is authorized by this decision. G9 remains NOT READY; G10 remains NOT ACTIVE pending its separate gate.

## Product Owner conditional implementation authorization — 2026-11-24

**Approval source:** Explicit written Product Owner authorization supplied in the project conversation on 2026-11-24, titled “PRODUCT OWNER AUTHORIZATION — DIT SD INSPECTION”. The approval authorizes transition from documentation toward implementation of the application from zero in `itswork-app/dit-sd-inspection`, with the existing SSOT as the build baseline.

**Authorized intent and conditions:**
- The Product Owner authorizes closure of all G9 prerequisites and scope freeze after critical blockers are closed.
- G10 Implementation Authorization is to be activated only after G9 verification and the required scope-freeze record.
- After G10 activation, source code, database schema, migrations, API, frontend and automated testing may be implemented on a dedicated implementation branch.
- Production changes, deployment and operations affecting real data require separate approval.
- No gate may be reported PASS without the required evidence and approvals.

**Status:** PO CONDITIONAL AUTHORIZATION RECEIVED; G9 NOT READY; G10 NOT ACTIVE. This record is not a waiver of institutional, security, database, operations or provider approvals and does not itself permit implementation before the G9/G10 conditions are satisfied. Root AGENTS.md remains controlling until formally updated through the authorized gate process.


## Product Owner clarification — all permissions to proceed confirmed — 2026-11-24

The Product Owner explicitly clarified in the project conversation on 2026-11-24: **“Semua ijin sudah diberikan”** (all permissions have been given). For project execution, this is accepted as confirmation that the Product Owner has granted the permissions within the Product Owner's authority for the team/agent to continue the authorized work without repeatedly requesting the same PO permission.

This clarification does not fabricate or substitute a third party's signed institutional delegation, security certification, provider ownership evidence, repository administrator evidence, or independent technical review. Where AUTH-001 requires evidence from a separately accountable authority, the evidence must be attached or referenced and verified before that specific gate is marked approved. The team must continue all work that is already authorized and does not depend on the missing evidence; do not pause unrelated engineering preparation or ask the Product Owner to repeat the same authorization.


## Product Owner decision — L05 audience-guard candidate direction (2026-11-24)

**Decision:** APPROVED — select one global transaction-scoped PostgreSQL advisory guard, candidate rank L05, as the primary mechanism for formal technical review. The Product Owner endorses the direction initially represented by NLA-L05-TDR-001 v0.1.1 and its controlled technical amendments; the current technical proposal is v0.1.3. This remains candidate-direction approval, not an executable implementation.

**Approved direction only:**
- Continue formal review of `pg_advisory_xact_lock(int,int)` as the candidate primitive with one reserved global key pair; actual key values and namespace remain unapproved.
- Continue formal review of READ COMMITTED with lock acquisition completed before a separate audience-resolution query.
- Require all source-event and eligibility-changing writer paths, including policy publication and asynchronous finalizers, to participate before conflicting mutable locks.
- Require event-time recipient snapshots to remain immutable and fan-out to consume only the persisted candidate set.

**Technical amendments requiring validation:** TDR v0.1.2 proposes VOLATILE PostgREST RPC wrappers with separate internal SQL commands and one `clock_timestamp()` audience-evaluation instant captured immediately after L05. The half-open effective-interval convention `[valid_from, valid_until)` is a technical proposal only and is not approved where it changes an existing domain contract.

**Not approved / not authorized:**
- canonical L05 rank admission, numeric advisory key values or global lock namespace;
- deployed isolation, function volatility metadata, function ownership/search_path/ACL, direct-DML denial or helper signatures;
- complete source-event/eligibility-writer lock matrix, FK/unique/trigger/helper graph, acyclicity or any resolver certification;
- candidate snapshot relation/header DDL, constraints or indexes;
- numeric lock/statement/transaction timeouts, retry/backoff, audience maximum or performance SLO;
- SQL, migration, source code, grants/revokes, RLS changes, live database inspection, runtime tests, provider setup, deployment or production operations.

**Authority and gate boundary:** This decision is Product Owner candidate-direction approval only. It does not substitute for Engineering, Database, Security, Operations or institutional approvals and evidence. F-01/F-02 remain open pending authenticated RPC/database evidence and adversarial tests. Resolver lock certification remains 0/40; application lock certification remains 0/50; global graph acyclicity is NOT PROVEN; candidate snapshot relation remains NOT ADMITTED; G9 remains NOT READY and G10 remains NOT ACTIVE.


## Product Owner decision — POQ-04 event-transition recipient semantics (2026-11-24)

**Status: PO APPROVED — 2026-11-24.** The Product Owner explicitly approved all five recommendations in full. POQ-04 resolves the product-decision portion of L05-REVIEW-001 F-05. It supplements POQ-01 through POQ-03 without changing them. Technical validation and implementation authorization remain separate.

**Recommended common rule:** the immutable candidate audience is evaluated against the serialized pre-mutation state at the single captured `audience_evaluated_at`. The source mutation, canonical event and candidate snapshot commit atomically. Actor, target and affected member are included only when the exact approved event selector selects them; no participant is silently appended. After commit, dispatch-time account, channel, consent/revocation, current-scope and mandatory security revalidation may suppress an existing candidate but may never add a recipient. A retry reuses the same candidate set and checkpoint.

| Transition | Proposed event-time candidate result | Proposed dispatch/retry result |
|---|---|---|
| Role revoke (CMD-005) | Evaluate selectors before the revoke mutation. The revoked target is included only if eligible under the pre-mutation role/scope state and selected by policy; actor is not auto-added. | Current role/scope revalidation may suppress delivery after revocation. No new candidate is added. |
| Account reject/disable/suspend (CMD-002/003) | Evaluate selectors before the account-state mutation. A selected account may exist in the immutable snapshot if eligible immediately before the transition. | Non-enabled account is suppressed before each send attempt. Re-enable may permit a later retry only for that same original candidate; it never creates a new candidate. |
| Assignment-member end (CMD-015) | Evaluate membership and selectors before ending membership, using the captured instant and half-open effective intervals. | Current-scope revalidation may suppress delivery when the assignment/member scope is no longer effective. No replacement member is added. |
| Project/session close (CMD-010/013) | Evaluate selectors against the pre-close parent state. Selected candidates are persisted atomically with the closure event. | Closed parent/current-scope policy may suppress delivery where the policy requires current active scope. No post-close recipient is added. |
| Self-revoke by actor | Actor is included only if the exact event selector independently selects the actor under pre-mutation eligibility. No implicit actor inclusion or exclusion. | The actor's post-revoke role/scope state is revalidated; delivery is suppressed if no longer authorized by the applicable current-scope rule. |

**Invariant:** snapshot membership is immutable and records the event-time decision; dispatch suppression is a separate outcome and cannot mutate or widen the snapshot. Suppression reasons and each attempt outcome must be auditable without storing unnecessary sensitive data.

**Approval record (2026-11-24):** Product Owner approved the complete five-row matrix without changes. The approved product rule is the immutable pre-mutation event-time candidate set, exact-selector-only participant inclusion, dispatch-time suppression without widening, and retry reuse of the original candidate set/checkpoint. Security/Engineering must validate current-scope suppression, retry-after-reactivation, audit semantics, exact selector behavior and consistency with the final technical design before F-05 can close. This decision does not approve physical schema, lock ranks, SQL, implementation, runtime tests, G9 or G10.



## Product Owner decision — first-batch notification event candidates (2026-11-24)

**Status: PO APPROVED — specification and review only.** The Product Owner explicitly approved the eleven first-batch candidates from NLA-EVENT-TRIAGE-001 for progression into a draft event registry and subsequent Security/Engineering/Database review:

1. `account.approved` (CMD-002)
2. `account.rejected` (CMD-003)
3. `role.revoked` (CMD-005)
4. `project.closed` (CMD-010)
5. exact final `session.closed` (CMD-013); not `session.close_requested`
6. `assignment.created` (CMD-014)
7. `assignment.changed` (CMD-015)
8. `inspection.submitted` (CMD-029); `inspection_revision.created` is a related fact, not a second approved notice
9. `inspection.returned_for_correction` (CMD-030)
10. `inspection.approved` (CMD-031)
11. `inspection.reopened` (CMD-032)

**Scope of approval:** record the candidates, prepare exact registry specifications and submit unresolved contracts/mappings for technical review. This decision does not approve canonical producer contracts, physical event fields, recipient mappings, selectors, role/scope grants, dispatch profiles, channels, templates, publication, event enablement, schema, SQL, implementation or tests. All eleven registry rows must remain `UNRESOLVED — NOT ENABLED` until each admission criterion is satisfied and required technical/institutional authorities approve.

**Preserved exclusions:** `account.requested` (CMD-001) remains a secondary P-class candidate, deferred and neither approved nor rejected. `session.close_requested` is not interchangeable with final `session.closed`. No other CMD declaration is approved by implication. No school-principal, teacher, student, parent, school-customer or Attendance Verifier recipient is introduced.

**Binding constraints:** POQ-01 and POQ-04 immutable event-time candidate, exact-selector-only inclusion, dispatch-time suppression without widening, and retry reuse rules remain binding. Security/Engineering/Database review, F-05/F-04/F-03/F-07 closure evidence and G9/G10 gate approvals remain mandatory. G9 remains NOT READY; G10 remains NOT ACTIVE.

**Recorded artifact:** NLA-EVENT-REGISTRY-001 v0.1.0 is the controlled draft inventory for these eleven candidates. It is not an enabled registry or implementation authorization.


## Product Owner decision — SES-001 session-bound unit inspection (2026-11-24)

**Status: PO APPROVED.** Each inspection attempt for one physical unit is valid within exactly one inspection session. The inspection record and all draft/evidence work must remain bound to that session; a draft or claim must never be resumed, transferred or continued in a different session.

**Required behavior:**
1. CMD-026 may create/claim an inspection attempt only in the caller's currently active, authorized session and binds the attempt immutably to that session.
2. Draft editing, offline continuation under T-09, evidence upload/finalization, submit and any returned correction are confined to that same session. The responsible Inspector remains the same Inspector for a returned correction, consistent with WF-001 and the separate PO decision on correction ownership.
3. Before a session is finally closed, every unit attempt must reach an allowed terminal outcome. Returned work that remains practically correctable follows WF-001 correction/resubmission. ABORT is allowed only for a Reviewer-returned error where the physical unit is already packed/boxed and prepared for shipment so correction/reinspection is impracticable, and only after Inspector request plus Admin/Korlap approval. A generic incomplete/hanging attempt is not eligible for ABORT.
4. Abort is a terminal, auditable outcome for that inspection attempt. It preserves the attempt history, prior revisions, evidence metadata and audit trail; it is not a successful inspection, approval or completion.
5. A later session must create a new inspection attempt bound to that new session. It must not reactivate or mutate the aborted attempt. Prior evidence is historical and is not automatically reused to satisfy the new attempt.
6. Session closure must be blocked while unresolved unit attempts or pending ABORT requests remain. A qualifying ABORT must be explicitly approved before final session closure; CMD-013 cannot initiate or approve it.

**Scope:** IFP and Standing Bracket inspections by the Dit. SD inspection team only. This decision does not add school-side personas or workflows.

**Technical constraints still requiring review:** exact abort command/API mapping and permission; whether existing CMD-027 release semantics can be reused or a dedicated abort command is required; atomic abort + claim release + audit/event/idempotency; handling of a returned correction that remains unresolved at session close; and physical uniqueness allowing a new session-bound attempt while preserving canonical unit identity. These are not silently inferred as implementation-ready. No DDL, RLS, grants, code or tests are approved by this decision.

## SES-001 PO clarification — exceptional abort for packed shipment unit (2026-11-24)

**Status: PO APPROVED.** This clarification supersedes any broader interpretation that all unfinished, hanging, or returned attempts may be aborted as routine session cleanup.

ABORT is an exceptional disposition for this specific path:
1. Inspector submits an inspection attempt.
2. Reviewer returns it because an error was found.
3. The physical unit has already been packed/boxed and prepared for shipment, so the Inspector cannot practically correct or reinspect that unit.
4. Inspector submits an ABORT request with the reason.
5. Admin/Korlap reviews and explicitly approves or rejects the request. Only an approved request may transition the attempt to ABORTED.

If the unit remains practically accessible for correction/reinspection, the normal WF-001 path applies: the same Inspector corrects and resubmits in the original active session. Packing alone is not a substitute for Reviewer return, and ABORT is not a way to avoid an available correction.

ABORTED is terminal and is not a good/defective classification, inspection approval, inspection completion, or print completion. Preserve the submitted revision, Reviewer return decision, evidence and audit history. A later inspection, if required, is a new attempt with a new inspection_id and its own session binding; the ABORTED attempt is never reactivated. CMD-013 FINAL_CLOSE cannot create, approve or bulk-apply aborts and cannot use ABORT to bypass unrelated evidence, document, print or attendance requirements.

The exact command identity, permission/grant and SoD matrix, reason taxonomy, evidence requirements for proving packed/shipment-ready state, atomic state/claim/audit/event/idempotency write set, lock order, schema/RLS and QA execution remain technical design work. This PO clarification does not invent a command ID or authorize implementation.
