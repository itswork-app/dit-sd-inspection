# Phase 0 — Project Foundation

**Status:** In progress  
**Exit condition:** Project foundation reviewed and approved; open assumptions and ownership are explicit.

## Objectives
1. Establish project identity, authority, scope boundaries, and release target.
2. Establish repository and engineering governance.
3. Create traceability from product decisions to requirements, implementation, tests, and release evidence.
4. Identify stakeholder inputs needed before product specification freeze.

## Confirmed management decisions
- Release target: **Production**.
- Engineering priority: **Balanced**.
- Product: replacement inspection application, not SaaS.
- Initial instruments: IFP and Standing Bracket.
- Strategy: feature parity first, improvements after.
- Legacy source code is not available; reference is user-provided workflow/screenshots.
- Repository: itswork-app/dit-sd-inspection, private, default branch main.

## Phase 0 work items

| ID | Work item | Exit evidence | Status |
|---|---|---|---|
| P0-01 | Confirm charter and product boundaries | Approved charter | Drafted |
| P0-02 | Define roles and decision authority | Stakeholder/RACI matrix | Drafted; validate |
| P0-03 | Establish Git and PR governance | Branch/PR policy | Drafted; configure |
| P0-04 | Establish quality gates and DoD | Approved governance | Drafted; validate |
| P0-05 | Create decision and requirement traceability | Decision Register + requirement IDs | Pending |
| P0-06 | Inventory source references and evidence gaps | Reference inventory | Pending stakeholder review |
| P0-07 | Record risks, assumptions, dependencies | RAID register | Pending |
| P0-08 | Define production constraints | Hosting/privacy/retention/operations decisions | Pending stakeholder input |

## Phase 0 exit checklist
- [ ] Project Charter approved by Product Owner.
- [ ] Stakeholder roles and final decision authority confirmed.
- [ ] Scope and exclusions accepted.
- [ ] Engineering Governance accepted.
- [ ] Repository rules and required reviews configured.
- [ ] Decision Register and traceability method established.
- [ ] Reference material inventory and checklist gaps documented.
- [ ] RAID register reviewed with owners.
- [ ] Production constraints and compliance owners identified.
- [ ] Phase 1 entry criteria accepted.

## Phase 1 entry criteria
No feature implementation begins until:
- Phase 0 is approved.
- PRD is consolidated and open decisions are explicitly identified.
- Official IFP and Standing Bracket checklist/photo requirements are validated against authorized reference documents.
- Acceptance criteria are testable and traceable.
