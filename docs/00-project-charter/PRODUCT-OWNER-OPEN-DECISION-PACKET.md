# Product Owner Open Decision Packet — Dit. SD Inspection

**Document ID:** POQ-001  
**Version:** 0.1.0  
**Status:** DECISIONS RECORDED — POQ-01..03 APPROVED 2026-11-24  
**Date:** 2026-11-24  
**Authority:** Decision Register; Package T historical decision pack; MIB-001; DGA-001  
**Purpose:** Request only unresolved product-semantic decisions within Product Owner authority.

## 1. Instructions and authority boundary

This packet does not reopen decisions already approved in the Decision Register. T-05..T-18 and LPR-02..LPR-06 retain their recorded PO outcomes. A response to this packet becomes authoritative only after it is explicitly recorded in the Decision Register or a dated superseding decision record.

Do not use this packet to approve institutional records/privacy/legal matters, actual BA signatory authority, provider ownership, PostgreSQL privileges, RLS, function security, lock modes, production SLOs or implementation. Those require the authorities identified in AUTH-001.

For each question, the PO may select an option, amend it, or defer it with a reason and scope consequence. If source evidence is missing, the correct response may be BLOCKED — SOURCE REQUIRED.

## 2. Decisions requested

### POQ-01 — Notification recipient eligibility snapshot

**Related authority:** INS-015; T-18 Option A; DGA-B13; NOTIF-007/008/012; D-034/D-035; R-034.

**Question:** At what business point should the intended notification audience be determined when an inspection, assignment or other source event occurs and delivery may be delayed?

- **Option A — Event-time audience snapshot:** Resolve the eligible recipients from the source event's authorized scope and persist an immutable recipient snapshot/checkpoint. Retries use that same audience and cannot widen it. Immediately before external delivery, the system still rechecks current account status, channel eligibility and any mandatory revocation/security restrictions.
- **Option B — Fan-out-time audience:** Resolve eligible recipients when the worker begins fan-out. Delayed events may therefore target a different audience if assignments or roles changed after the source event. Retry behavior must still be deterministic within a persisted fan-out attempt.
- **Option C — Hybrid:** Persist the event-time candidate audience and its source scope; before each external send, revalidate current account/channel restrictions without adding recipients who were not in the original snapshot. This preserves event-time scope while respecting later revocation.
- **Defer:** Keep notification fan-out unavailable until the audience semantics are decided.

**Recommendation for review:** Option C. It preserves deterministic event scope and retry behavior while allowing current security/revocation checks. This is a recommendation, not an approval.

**Required response:** Selected option or amended rule; treatment of assignment changes between event and send; treatment of disabled/revoked accounts; whether the audience is immutable after first fan-out; effective date.

**Downstream updates:** Decision Register; NLA-001; CMD-049–054 review; notification schema/RLS/API; RTM NOTIF-007/008/012; QA TC-NOTIF-001..026; DGA-B13; RAID R-034.

### POQ-02 — Notification SLA clock semantics

**Related authority:** INS-015; DGA-B13; NOTIF-010; R-034/R-035.

**Question:** Should reminder/escalation thresholds use elapsed wall-clock time or an approved business-hours calendar?

- **Option A — Elapsed time:** Calculate from one server/database UTC instant using fixed elapsed durations. Quiet hours may defer delivery but do not pause the SLA clock.
- **Option B — Business time:** Calculate only within an approved business-hours calendar and time zone. Calendar, holidays, pause states and DST behavior must be specified.
- **Option C — Per-policy choice:** Each versioned policy explicitly selects elapsed or business-time semantics, with an approved calendar/time zone when required.
- **Defer:** No reminder/escalation policy is activated until clock semantics are specified.

**Recommendation for review:** Option C, provided the first release uses one explicitly approved default policy and does not permit arbitrary unbounded calendar expressions.

**Required response:** Selected option; default semantics for initial release; authoritative time zone/calendar source; whether quiet hours affect delivery only or also the SLA clock; conditions that pause/reset an SLA; effective date.

**Downstream updates:** Decision Register; NLA-001; CMD-054; notification policy schema; RTM NOTIF-010; QA TC-NOTIF-013/014/025; DGA-B13.

### POQ-03 — Notification dismissal/archive behavior

**Related authority:** INS-015; NLA-001; DGA-B13; CMD-050; RLS catalogue.

**Question:** Is a separate user-facing dismiss/archive action required in the initial release, distinct from marking a notification as read?

- **Option A — Exclude from initial release:** Keep recipient-owned set-once `read_at` only. `dismissed_at` remains dormant; no dismiss command or permission is exposed.
- **Option B — Include in initial release:** Define the exact semantics (recipient-only, reversible or set-once, unread interaction, retention, audit, bulk behavior) and request a new command/schema/security review before scope freeze.
- **Defer:** Leave the feature explicitly out of scope until a later change request.

**Recommendation for review:** Option A / defer. The current design intentionally exposes no dismiss command; do not infer one from a dormant physical field.

**Required response:** Explicit inclusion/exclusion; if included, business meaning and acceptance criteria. No response means the feature remains excluded from implementation scope.

**Downstream updates:** Decision Register; NLA-001; command catalogue/review; RLS; RTM; QA; DGA-B13.

## 3. Decisions explicitly not requested again

The following remain recorded PO decisions and must not be presented as undecided in a new review:

- T-05 actual report counts and Completed definition.
- T-06 explicit Super Admin project closure after required gates and reconciliation.
- T-07 session creation authority and DRAFT/ACTIVE/PAUSED/CLOSED state model.
- T-08 scoped attendance verification; upload does not imply verification.
- T-09 limited offline editing only for already-claimed drafts; no offline claim, approval or final submission.
- T-10 option B institutional records/legal/privacy review path. Institutional policy itself remains unapproved.
- T-11 option B current mainstream browser baseline; exact device/build matrix and numeric SLO remain open.
- T-12 option C alternative provider-ownership path. Actual owner/custodian/provider evidence remains open.
- T-13 option B individual + bounded batch print, per-document outcomes and failed-only retry.
- T-14 option A capacity predicate and combined cap 1–100/default 50.
- T-15 option A INS-016 append-only audit and atomic critical mutation/audit.
- T-16 option B global uniqueness within instrument type and immutable evidence/revision linkage; normalization and exception policy remain subject to technical/institutional review.
- T-17 option A CFG-001 declarative instrument publication direction.
- T-18 option A Vercel route + caller-JWT PostgreSQL command boundary and narrow SECURITY DEFINER protected-write model.
- LPR-02..LPR-06 PO product semantics.

## 4. Product-owner response record

No responses are recorded in this document yet.

| Question | PO response | Rationale / amendment | Effective date | Decision Register reference |
|---|---|---|---|---|
| POQ-01 | **Option C — APPROVED** | Hybrid event-time candidate audience; dispatch-time revalidation can suppress but never widen recipients | 2026-11-24 | Decision Register — POQ-01 |
| POQ-02 | **Option C — APPROVED** | Versioned per-policy elapsed/business-time semantics; initial default `ELAPSED_UTC`; quiet hours defer delivery only and do not pause SLA | 2026-11-24 | Decision Register — POQ-02 |
| POQ-03 | **Option A — APPROVED** | Dismiss/archive excluded from MVP; set-once recipient-owned `read_at` only | 2026-11-24 | Decision Register — POQ-03 |

PO responses were explicitly approved and recorded in the Decision Register on 2026-11-24. Dependent design documents must now be reconciled to those decisions; no technical, institutional or implementation approval is implied.

---
This packet is a request for product decisions only. It does not approve institutional policy, technical design, implementation or release.
