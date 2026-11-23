# RAID Register — Risks, Assumptions, Issues, Dependencies

**Status:** Initial baseline; owners and ratings require stakeholder review.

| ID | Type | Description | Impact | Mitigation / next action | Owner | Status |
|---|---|---|---|---|---|---|
| RAID-001 | Risk | Official checklist/photo requirements are incomplete in current visual references | High: incorrect inspection criteria | Obtain complete authorized IFP and Bracket instruments; validate line by line | Product Owner | Open |
| RAID-002 | Risk | Legacy source and backend behavior are unavailable | Medium: hidden workflow rules may be missed | Treat legacy as reference only; validate workflows with process owner and UAT | Product Owner | Open |
| RAID-003 | Risk | Offline inspection and media synchronization can create duplicate/conflicting claims | High: data loss or duplicate inspection | Design idempotent sync, server reconciliation, immutable evidence, conflict queue; test failure scenarios | CTO | Open |
| RAID-004 | Risk | Incorrect role scope may expose inspection data across locations | Critical: unauthorized access | Define assignment model; enforce authorization server-side and at database layer; negative tests | CTO | Open |
| RAID-005 | Risk | PDF/BA/report output may differ from official operational requirements | High: document rejection or rework | Collect official templates and validate generated output during UAT | Product Owner | Open |
| RAID-006 | Risk | Data retention, privacy, and evidence handling requirements are unknown | High: compliance and operational exposure | Obtain institutional policy and approve retention/access/deletion rules before production | Product Owner / Sponsor | Open |
| RAID-007 | Risk | Production hosting and service budget are not yet selected | Medium: deployment delay or cost overrun | Compare options after offline, storage, security, and scale requirements are baselined | CTO | Open |
| RAID-008 | Assumption | Google sign-in is acceptable for all intended users | Medium: account/access friction | Validate identity policy and institutional account availability | Product Owner | To validate |
| RAID-009 | Assumption | Wet signature remains the Phase 1 document process | Medium: printing and physical handoff dependency | Confirm current document SOP and custody responsibilities | Product Owner | Confirmed in current product decisions; validate operational SOP |
| RAID-010 | Dependency | Official logos, institutional text, signatory names/titles, and templates | High: final PDF/BA cannot be approved | Obtain approved assets and document masters | Product Owner | Open |
| RAID-011 | Dependency | Production ownership for support, incident response, and user onboarding | High: operational readiness | Name responsible operational owner and escalation contacts | Sponsor | Open |
| RAID-012 | Issue | Repository branch protection, required checks, and CI are not yet configured | Medium: governance not technically enforced | Configure after stack/CI selection; test PR workflow | CTO | Open |

## Rating convention
- Critical: can cause unauthorized disclosure, irreversible data loss, or materially invalid official records.
- High: can block operational acceptance or cause substantial rework.
- Medium: manageable with planned mitigation.
- Low: limited impact.

## Review cadence
Review RAID at each phase gate and whenever a new risk, issue, assumption, or dependency is discovered.
