# RAID Register — Dit. SD Inspection

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
| I-004 | Attendance upload verification authority is unresolved | Assign verifier role and acceptance rules | Product Owner | OPEN |
| I-005 | Report headline/count basis and final reconciliation are unresolved | Define count states and project closure/reconciliation rules | Product Owner | OPEN |
| I-006 | Exact session creation authority and state transitions are unresolved | Approve state machine and role permissions | Product Owner | OPEN |
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
