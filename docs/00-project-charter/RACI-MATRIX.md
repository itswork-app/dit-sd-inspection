# RACI Matrix — Dit. SD Inspection

Status: Draft — stakeholder validation required  
Scope: Project governance and operational lifecycle for IFP and Standing Bracket.

## RACI definitions

- **R — Responsible:** performs the work.
- **A — Accountable:** owns the outcome and final decision. Exactly one A is intended per activity.
- **C — Consulted:** provides input before the decision/action.
- **I — Informed:** receives status or outcome.

Roles are functional roles, not named people. One user may hold multiple roles only through explicit assignment and applicable separation-of-duties controls.

## Role catalogue

| Role | Primary responsibility | Authority boundary |
|---|---|---|
| Project Sponsor | Institutional sponsorship, resources, production/business authorization | Does not replace Product Owner's approval of instrument semantics |
| Product Owner | Scope, business rules, official instrument content, acceptance, UAT | Approves requirements and changes; does not bypass security controls |
| CTO / Engineering Lead | Architecture, engineering governance, security, quality, technical release recommendation | Does not invent or unilaterally approve official inspection criteria |
| Super Admin | Global system administration and approved configuration; creates project/session and assigns teams where authorized | Cannot alter immutable historical inspection evidence; operational Inspector/Reviewer actions require explicit assignment |
| Admin / Koordinator Lapangan (Korlap) | Supervises assigned location/session, monitors progress/issues, manages operational coordination and session close confirmation | Authority limited to assigned scope; cannot approve inspection unless explicitly assigned Reviewer |
| Inspector | Performs assigned unit inspection, captures checklist and evidence, submits/resubmits | Cannot self-assign official teams, self-approve, or edit submitted versions outside correction workflow |
| Reviewer | Reviews submitted inspection, returns with reason or approves | No self-review/self-approval; cannot silently edit Inspector evidence |
| Print Officer | Prints approved final PDFs and records print/reprint events | Cannot approve or change inspection results |
| Attendance Verifier | Verifies uploaded attendance evidence if this role is approved | Role and authority remain unresolved until Product Owner approval |

## Project governance RACI

| Activity | Sponsor | Product Owner | CTO / Engineering Lead | Super Admin | Korlap | Inspector | Reviewer | Print Officer |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Approve project charter and funding | A | R | C | I | I | I | I | I |
| Approve scope and business rules | C | A/R | C | C | C | I | C | I |
| Approve official instrument/checklist content | I | A/R | C | C | C | C | C | I |
| Approve architecture and security design | I | C | A/R | C | I | I | I | I |
| Approve engineering standards and CI gates | I | C | A/R | I | I | I | I | I |
| Accept package deliverables | I | A | R | C | C | I | C | I |
| Approve UAT and business acceptance | C | A/R | C | C | R | R | R | R |
| Authorize production release | A | C | R | I | I | I | I | I |
| Approve scope change | C | A | R (impact analysis) | C | C | I | C | I |

## Operational RACI

| Activity | Super Admin | Korlap | Inspector | Reviewer | Print Officer |
|---|---:|---:|---:|---:|---:|
| Create/configure project and session | A/R | C | I | I | I |
| Set project and session targets | A/R | C | I | I | I |
| Assign location, instrument, team and members | A/R | C | I | I | I |
| Supervise assigned field operation | I | A/R | R | C | I |
| Claim and inspect assigned unit | I | I | A/R | I | I |
| Submit inspection | I | I | A/R | I | I |
| Return inspection with correction reason | I | I | C | A/R | I |
| Correct and resubmit inspection | I | I | A/R | C | I |
| Approve inspection | I | I | I | A/R | I |
| Generate final PDF after approval | I | I | I | A (workflow owner) | R (if assigned) |
| Print/reprint approved document | I | I | I | I | A/R |
| Confirm operational session closure | I | A/R | C | C | C |
| Reopen approved inspection | A/R only with explicit permission | R only with explicit permission | I | C | I |

## Mandatory separation-of-duties constraints

1. The same user cannot review/approve their own inspection.
2. A Korlap is not automatically a Reviewer.
3. Super Admin global administration does not automatically grant operational Inspector or Reviewer authority.
4. Multi-role users must have explicit session/location/instrument assignment for each operational action.
5. An Inspector may not be assigned to overlapping schedules at different locations.
6. Only authorized roles may reopen approved inspections, with a reason and immutable audit event.
7. The Attendance Verifier role remains unapproved until the Product Owner assigns authority.
8. The maximum Inspector population is 50 total across the two locations; Super Admin controls allocation through assignments.

## Open governance confirmations

- Confirm named people for Sponsor and Product Owner.
- Confirm whether Sponsor and Product Owner are separate people.
- Confirm whether Super Admin is the only role allowed to create projects/sessions.
- Confirm Attendance Verifier authority.
- Confirm whether Korlap's session-close confirmation is final or requires Super Admin approval.
