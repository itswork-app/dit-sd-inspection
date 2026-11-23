# Decision Register — Management and Product Baseline

**Status:** Living document. Only explicitly approved decisions are marked APPROVED.

| ID | Decision | Status | Notes |
|---|---|---|---|
| MGT-001 | Production is the release target | APPROVED | User decision, 2026-11-23 |
| MGT-002 | Engineering priority is balanced | APPROVED | Balance quality, security, cost, and delivery speed |
| PRD-001 | Replace existing Dit. SD inspection application | APPROVED | Not a SaaS product |
| PRD-002 | Initial scope is IFP and Standing Bracket only | APPROVED | No other instruments in initial scope |
| PRD-003 | Feature parity first; improvements second | APPROVED | Legacy app is a reference, not a code dependency |
| PRD-004 | No access to legacy source code is assumed | CONFIRMED | Reconstruct from supplied workflow and reference material |
| RBAC-001 | Google sign-in; new users require approval and role assignment | APPROVED | No self-role elevation |
| RBAC-002 | Multi-role accounts allowed with explicit operational assignment | APPROVED | Scope by session/location/instrument; no self-review |
| WF-001 | Reviewer returns corrections to Inspector; Inspector resubmits | APPROVED | Immutable version history |
| WF-002 | Reopening approved inspection requires authority, reason, and audit | APPROVED | Authorized Super Admin or explicitly permitted Admin |
| WF-003 | Session closure requires full process completion | APPROVED | Includes approval, document generation, required printing and documents |
| RPT-001 | Actual and Target reports are separate | APPROVED | Daily, weekly, and final variants |
| RPT-002 | Actual records retain true activity dates/times | APPROVED | Never rewrite actual activity to match target allocation |
| DOC-001 | Wet signature in Phase 1; no digital signature substitution | APPROVED | Per-unit print does not assert signature verification |
| DOC-002 | Per-unit completion follows approval, final PDF generation, and print action | APPROVED | Print action logged; no separate per-unit print confirmation |
| INS-001 | Instrument definitions are versioned; active sessions freeze version | APPROVED | Historic inspections preserve snapshot |
| INS-002 | Exception-based checklist UI | APPROVED | Default OK is not automatic verification; Inspector attests actual checks |
| INS-003 | Limited offline inspection and safe sync | APPROVED | Final submit/approval server-side |
| INS-004 | One active inspection per Inspector | APPROVED | Submitted work is no longer actively edited; avoid blocking next inspection during review unless separately decided |
| INS-005 | SN scan/entry claims a unit; prevent duplicate active claims | APPROVED | Preserve draft and claim history |
| INS-006 | Recovery and claim protection | APPROVED | Device loss/offline must not silently discard evidence |
| INS-007 | Evidence integrity and dual actual/target time dimensions | APPROVED | Device timestamp is not proof of capture time |
| INS-008 | Normalized serial duplicate prevention | APPROVED | Reinspection requires explicit authorization |
| INS-009 | Pre-submit validation | APPROVED | Findings need note/evidence; unresolved sync conflict blocks submit |
| INS-010 | Immutable inspection revisions | APPROVED | Reviewer cannot silently edit Inspector results |
| INS-011 | Approval/PDF/print drives per-unit completion | APPROVED | Print click is logged; reprints increment count |
| INS-012 | Separate Print Officer role | APPROVED | Explicit assignment and scoped permission |
| INS-013 | Scoped assignments and bulk print | APPROVED | Bulk print logs batch and per-document events |
| INS-014 | Role-based operational dashboards | APPROVED | Data scope follows assignments |
| INS-015 | Scoped notification and escalation management | APPROVED | Channels and SLA thresholds configurable; example SLA values not fixed |
| INS-016 | Audit trail and activity monitoring | PROPOSED | Not yet approved |

## Known open decisions
- Complete official IFP and Standing Bracket checklist contents and photo slots.
- BA signatory block configuration and authority.
- Whether executive summaries require signatures.
- Client-facing report delivery channel (PDF only or portal).
- Report headline/count basis and project reconciliation/closure.
- Session creation authority and exact session state transitions.
- Attendance upload verification authority.
- Exact offline package, conflict resolution, and device recovery policy.
- File limits, retention, deletion, privacy, and evidence access policy.
- Hosting, technology stack, environments, and production operational ownership.
- Exact CI provider/quotas and required branch protection checks.

Do not treat proposed decisions or illustrative numbers as approved.
