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
| WF-003 | Session closure requires full process completion | APPROVED | Approval, documents, required printing and records |
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
| INS-016 | Audit trail and activity monitoring | PROPOSED | Not yet approved |
| OPS-001 | Inspector capacity is configurable from minimum 1 to maximum 100, default 50, across both locations combined | APPROVED | User clarification, 2026-11-23; Super Admin controls the configured capacity and allocation between locations; the limit is global, not per location; values below 1 or above 100 are rejected |

## Open decisions
- Complete official IFP and Standing Bracket checklists and required photo slots.
- Institutional approval of actual BA signatory roles/identities and the final BA template (template configurability is PO-approved under T-02).
- Official IFP and Standing Bracket source documents and photo-slot requirements remain to be obtained and reconciled (T-01).
- Detailed report metric implementation and acceptance-test evidence (T-05 direction approved).
- Detailed project closure gate enforcement and reconciliation evidence (T-06 direction approved).
- Detailed session pause/reopen command and permission tests (T-07 direction approved).
- Detailed attendance evidence acceptance and verification tests (T-08 direction approved).
- Offline package, conflict resolution, and device recovery details.
- Evidence file limits, retention, deletion, privacy, and access policy.
- Supabase/Vercel project organization, environments, backup and retention configuration.
- Production usage estimates and plan upgrade criteria.
- CI provider quotas and required branch protection checks.

Proposed or illustrative decisions are not approved until explicitly accepted.

## Product Owner decisions — Package T (2026-11-23)

| ID | Decision | State | Qualification / remaining dependency |
|---|---|---|---|
| T-01 | Official, institutionally approved source documents are the authoritative master for IFP and Standing Bracket checklist/specification/evidence requirements. | PO APPROVED | The actual controlled source documents, completeness reconciliation, issuing authority and formal institutional approval evidence are still outstanding. Do not treat current transcriptions/screenshots as approved master data. |
| T-02 | BA signatory blocks are configurable per approved BA template, including number/party, organization, role/title, order and required/optional status. | PO APPROVED | Actual authorized signatory identities, authority and final template remain subject to institutional approval. Sample parties are not universal defaults. |
| T-03 | Executive-summary signature behavior is configurable per report template. | PO APPROVED | Default may be no signature unless the approved template requires it. Any mandatory signature rule must be supported by the approved institutional template. |
| T-04 | Initial release uses PDF-only client report delivery; a client portal is deferred from initial scope. | PO APPROVED | PDF access/distribution remains permission-controlled and audited. Portal requires a later change request and approval. |

Product Owner additionally confirmed on 2026-11-23 that `Pemeriksaan Barang_SB.pdf` is the official Standing Bracket instrument document. The 19 visible rows (6 physical + 13 accessories) are the official baseline from that document. This PO confirmation establishes the document's status for this project; it does not authorize changing ambiguous source wording or infer photo rules absent from the document. Institutional approvals beyond the PO's authority, if required by the institution's governance, remain external. T-05 through T-08 were explicitly approved by the Product Owner on 2026-11-23 (A/A/A/A); T-09 was subsequently approved as option B on 2026-11-23; T-10 option B is PO APPROVED as the required formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED: current mainstream stable browsers with explicit exclusions; exact device/OS/build matrix and numeric SLOs remain open pending UAT and provider verification. T-12 option C is PO APPROVED as an alternative provider-ownership arrangement subject to formal institutional definition and approval; actual owner, billing owner, custodians, region, provider plan and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 through T-18 remain OPEN/BLOCKED.

## Remaining open decisions
- T-01: Standing Bracket official instrument document confirmed by Product Owner on 2026-11-23. Reconcile the 19-row checklist verbatim and preserve ambiguous wording. Remaining: confirm photo-slot requirements, any additional annex/specification, and authoritative IFP source document.
- T-02: obtain institutional approval for authorized BA signatory roles/identities and final template.
- T-09: PO APPROVED option B (limited offline draft editing with controls still gated). T-10: PO APPROVED option B (formal institutional records/legal/privacy review path); resulting institutional policy remains BLOCKED pending written authority. T-11: PO APPROVED option B (current mainstream stable browsers with explicit exclusions); exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12: PO APPROVED option C (alternative provider-ownership arrangement subject to formal institutional definition and approval); actual owner, billing owner, custodians, region, provider plan and recovery evidence remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 through T-18 remain open in Package T.

## Product Owner decisions — Package T continuation (2026-11-23)

| ID | Decision | State | Qualification / remaining dependency |
|---|---|---|---|
| T-05 | Actual reports show distinct, separately labelled Inspected, Submitted, Approved and Completed counts. Completed retains the approved inspection + final PDF generated + Print Officer print action recorded definition. | PO APPROVED | Metric definitions, timestamp/filter display and report acceptance tests must be implemented and verified; a print action does not prove physical paper output. |
| T-06 | Super Admin is the final project-closure authority after all required closure gates and actual-versus-target reconciliation are satisfied. Closure is explicit, non-automatic, reasoned and audited. | PO APPROVED | No date-based auto-close. Exceptions require separately permissioned override, reason and audit. Operational gate completeness remains to be implemented and tested. |
| T-07 | Super Admin exclusively creates/configures sessions, targets, locations, instruments and team assignments. Korlap may activate, pause, resume or request closure only within assigned scope and granted permissions. States: DRAFT, ACTIVE, PAUSED, CLOSED; CLOSED is terminal in ordinary flow. | PO APPROVED | Reopening a CLOSED session requires explicit privileged permission, reason and audit. Permission matrix and state-transition tests remain to be completed. |
| T-08 | Korlap verifies attendance within assigned location/scope, with separate permissions for generate, print, upload, download and verify. Upload never automatically sets VERIFIED. | PO APPROVED | Super Admin assigns/grants verifier authority. Artifact integrity, verification rules and audit behavior remain to be implemented and tested. |
| T-13 | Initial release supports individual and bounded batch printing from a permissioned Print Officer queue; per-document outcomes and atomic reprint sequence are recorded. | PO APPROVED (B) | Retry only failed documents; no duplicate success events. Application print action is not proof of physical paper output. Direct printer integration is not selected. |
| T-13 | Initial release supports individual and bounded batch printing from a permissioned Print Officer queue; per-document outcomes and atomic reprint sequence are recorded. | PO APPROVED (B) | Retry only failed documents; no duplicate success events. Application print action is not proof of physical paper output. Direct printer integration is not selected. |

These are Product Owner decisions recorded from the explicit response dated 2026-11-23. They settle the product direction for T-05 through T-08 but do not constitute implementation, UAT, or institutional approval where required.

## Product Owner decision — Package T T-09 (2026-11-23)

**T-09: PO APPROVED option B — limited offline draft editing.** Offline continuation is permitted only for an inspection draft whose unit was already claimed while online. Offline claim acquisition, approval, final submission, role/assignment changes, session administration and privileged actions are prohibited. Reconnection must use authenticated, idempotent synchronization, recheck server authorization and claim/state, reject stale conflicting writes, preserve local and server versions for explicit resolution, and never silently overwrite newer server data. Required evidence must be server-confirmed before final submission.

This approval does not authorize production activation of offline persistence. Supported device/browser matrix, local-data protection/encryption, shared-device logout, retention/purge, local recovery and institutional records/privacy approval remain open dependencies (T-10/T-11). T-09 PO direction is approved; implementation and tests remain pending. T-10 option B is PO APPROVED as the formal institutional records/legal/privacy review path; the resulting institutional policy remains BLOCKED pending written authority. T-11 option B is PO APPROVED; exact OS/device/browser build matrix and numeric SLOs remain open pending validation. T-12 option C is PO APPROVED; the actual alternative arrangement and institutional/provider verification remain BLOCKED. T-13 is PO APPROVED option B (individual + bounded batch printing); T-14 through T-18 remain OPEN/BLOCKED.

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

## Product Owner decision — Package T T-13 (2026-11-23)

PO APPROVED option B — individual and batch printing. Initial release includes individual print and bounded/configurable batch print through the permissioned Print Officer queue. Each document in a batch has an independent outcome; retry targets failed documents only and must not duplicate successful print events. Print/reprint events preserve actor, timestamp, document version, atomic sequence and outcome where available. The application records the print action, not physical printer output. Direct printer integration is excluded from this decision. Implementation and tests remain pending.
