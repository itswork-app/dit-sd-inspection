# Stakeholder and Decision Authority (RACI)

**Status:** Draft — requires Product Owner confirmation.

R = Responsible, A = Accountable, C = Consulted, I = Informed. This matrix describes the proposed project governance and must not be confused with runtime application roles.

| Activity | Product Owner / Sponsor | CTO / Engineering Lead | Super Admin | Korlap | Inspector | Reviewer | Print Officer |
|---|---|---|---|---|---|---|---|
| Approve product scope and business rules | A | C | I | C | I | C | I |
| Approve official inspection instrument content | A | C | C | C | C | C | I |
| Approve technical architecture and engineering standards | C | A/R | I | I | I | I | I |
| Implement and test application | I | A/R | I | C | C | C | C |
| Approve users and assign system roles | I | C | A/R* | I | I | I | I |
| Create/maintain project operational assignments | A* | C | R* | C | I | I | I |
| Perform assigned inspection | I | I | I | C | A/R | I | I |
| Review, return, or approve inspection | I | I | I | I | C | A/R | I |
| Print approved documents | I | I | I | C | I | I | A/R |
| Accept UAT and authorize production release | A | R (recommendation) | C | C | C | C | C |

* Exact authority for initial Super Admin bootstrap, user administration, and official project/session assignments must be confirmed. The application role model already requires explicit assignment scope and backend enforcement.

## Governance notes
- Product Owner retains authority over business meaning and acceptance.
- CTO/Engineering Lead owns technical execution and may block a release for unresolved critical security, reliability, or data-integrity risk.
- Runtime role combinations are permitted only through explicit authorization and scope.
- No person may review or approve their own inspection.
- Korlap supervises assigned field operations; Reviewer retains inspection approval authority.
- A user holding Super Admin privileges does not automatically gain operational Inspector/Reviewer/Print Officer assignment in every location/session.
