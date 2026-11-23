# Phase 0 — Project Foundation

Status: In progress  
Exit condition: Project foundation reviewed and approved; open assumptions and owners are explicit.

## Confirmed management decisions
- Release target: Production.
- Engineering priority: Cost-first.
- Platform: Supabase + Vercel; GitHub for source control and CI.
- Supabase PostgreSQL is the single source of truth.
- Product is a replacement inspection application, not SaaS.
- Initial instruments: IFP and Standing Bracket.
- Strategy: feature parity first, improvements after.
- Legacy source code is unavailable; use supplied workflows/screenshots as reference.
- Repository: itswork-app/dit-sd-inspection; private; default branch main.

## Work items
| ID | Work item | Exit evidence | Status |
|---|---|---|---|
| P0-01 | Confirm charter and product boundaries | Approved charter | Drafted |
| P0-02 | Define roles and decision authority | Stakeholder/RACI matrix | Drafted; validate |
| P0-03 | Establish Git and PR governance | Branch/PR policy | Drafted; configure |
| P0-04 | Establish quality and cost gates | Approved governance | Drafted; validate |
| P0-05 | Create decision and requirement traceability | Decision Register and requirement IDs | Pending |
| P0-06 | Inventory reference material and evidence gaps | Reference inventory | Pending review |
| P0-07 | Record risks, assumptions, dependencies | RAID register | Pending |
| P0-08 | Define production constraints and cost envelope | Hosting, privacy, retention, budget and operations decisions | Pending stakeholder input |
| P0-09 | Record Supabase/Vercel platform baseline | ADR-001 | Drafted |
| P0-10 | Validate production plan eligibility and quotas | Cost and operational assessment | Pending |

## Phase 0 exit checklist
- [ ] Charter approved by Product Owner.
- [ ] Stakeholder roles and final decision authority confirmed.
- [ ] Scope and exclusions accepted.
- [ ] Engineering Governance accepted.
- [ ] Repository protection and required reviews configured.
- [ ] Decision Register and traceability established.
- [ ] Reference inventory and checklist gaps documented.
- [ ] RAID register reviewed with owners.
- [ ] Production constraints, budget owner, and compliance owners identified.
- [ ] Supabase/Vercel plan eligibility and production constraints reviewed.
- [ ] Phase 1 entry criteria accepted.

## Phase 1 entry criteria
Do not begin feature implementation until Phase 0 is approved, PRD decisions are consolidated, official IFP and Standing Bracket checklist/photo requirements are validated against authorized references, and acceptance criteria are testable and traceable.
