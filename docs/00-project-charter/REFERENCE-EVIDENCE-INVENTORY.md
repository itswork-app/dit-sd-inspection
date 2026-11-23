# Reference & Evidence Inventory — Dit. SD Inspection

Status: Draft — source completeness review required  
Purpose: Track all source material used to reconstruct the legacy workflow and identify evidence that must be obtained before requirements freeze.

## Source handling rules

- The legacy application is a reference only; no source-code or database access is assumed.
- A description of a screen is not equivalent to an approved official instrument or policy document.
- Preserve original supplied files when they are provided; do not overwrite source evidence.
- Record filename, source/issuer, received date, version/date, and reviewer for each controlled artifact.
- If a source is unavailable, mark the related requirement OPEN. Do not infer missing official wording.

## Known reference coverage from product discovery

| Ref ID | Artifact / screen group | Known content | Completeness | Required follow-up |
|---|---|---|---|---|
| REF-001 | Login / identity screen | Unit/agency, full name, session code, start inspection action | Described | Obtain original screenshot and confirm field validation |
| REF-002 | Session and instrument selection | Session switch/selection; IFP and Standing Bracket instrument selection | Described | Obtain complete screenshots and permitted transition behavior |
| REF-003 | Serial number entry | Serial number capture/entry and unit identity | Described | Confirm official serial format, normalization, barcode/QR support |
| REF-004 | IFP documentation tab | Ten photo labels: box serial, rear display serial, RAM in developer mode, cable completeness with serial/warranty, front external ports, rear external ports, settings serial/storage, red-white logo, camera/webcam, state-asset sticker | Labels described; official rules unverified | Obtain complete original screen and confirm required/conditional status |
| REF-005 | Standing Bracket documentation tab | Five photo labels: box serial, top layer when opened, second layer with bolts, bolts only, bracket serial | Labels described; completeness unverified | Obtain full original screen and confirm all photo slots |
| REF-006 | IFP checklist and sample inspection report | Five categories; 49 checklist statements; 14 model specification entries; inspection identity fields; Ya/Tdk response column | Reconciled against user-uploaded `Pemeriksaan Barang.pdf` (2 pages; sample inspection no. 189, 24/11/2026) | Confirm issuing authority, controlled version/date, and whether sample remains current |
| REF-007 | Standing Bracket checklist | Detailed authoritative checklist not available in current baseline | Missing / incomplete | Obtain official controlled checklist |
| REF-008 | Validation and submit | Pre-submit validation and submission action | Described | Obtain validation/error states and confirmation behavior |
| REF-009 | Recap screen | IFP/Bracket tabs, search/filter, counts/cap, Inspector, date/time, BA number, status, print/delete actions | Described | Obtain complete screen states and define delete/archive permissions |
| REF-010 | Inspection PDF | Sample report with inspection identity, item/serial identity, checklist and Inspector sign area | Two-page user-uploaded PDF sample inspected; separate legacy screenshot showed a three-page print preview, so pagination/template variant remains to reconcile | Confirm canonical approved template and whether page count varies by instrument/content |
| REF-011 | Berita Acara (BA) | Two party blocks described: Tim Pemeriksaan Direktorat SD and PT Hisense International Indonesia | Partial | Obtain approved BA template, signatory names/titles and authority |
| REF-012 | Attendance document | Generated attendance list and signed/uploaded evidence workflow | Workflow described | Obtain approved template and sample signed document |
| REF-013 | Target and actual reporting | Planned targets versus actual inspection facts; daily/weekly/final reporting | Business rules described | Obtain legacy report samples and stakeholder-approved definitions |
| REF-014 | Notifications and operational dashboards | Role-specific dashboards and configurable notifications described | Requirements-level only | Confirm exact legacy screens and operational expectations |

## Additional supplied evidence

| Ref ID | Artifact | Observed content | Evidence status | Remaining limitation |
|---|---|---|---|---|
| REF-015 | `Pemeriksaan Barang.pdf` (user-uploaded, 2 pages) | Filled IFP inspection report no. 189; PT Hisense International Indonesia; 24/11/2026; Purwakarta; IFP 75WM61FE; physical/packaging serial numbers; five checklist sections; Ya/Tdk responses; Inspector signature area | Available and parsed; suitable as a sample-output and checklist-transcription baseline | Authority, controlled revision, and whether this is the canonical PDF template are not established |

## Controlled source documents required

| Source ID | Required source | Why required | Acceptance evidence | Status |
|---|---|---|---|---|
| SRC-001 | Controlled IFP inspection checklist/specification | Establish authorized criteria and values | Supplied filled sample report reconciled; Product Owner confirms issuing authority and controlled version | PARTIAL — sample evidence available; authority/version OPEN |
| SRC-002 | Official Standing Bracket inspection checklist/specification | Establish complete criteria | Product Owner confirms source authority and version | BLOCKED |
| SRC-003 | Official IFP and Bracket photo/evidence requirements | Establish mandatory evidence | Approved slot matrix | OPEN |
| SRC-004 | Approved inspection PDF template/sample | Establish output parity | Approved template comparison | OPEN |
| SRC-005 | Approved BA template and signatory policy | Establish parties and signature authority | Signed-off template and authority record | OPEN |
| SRC-006 | Approved attendance template and verification policy | Establish attendance evidence lifecycle | Approved template and role assignment | OPEN |
| SRC-007 | Approved daily/weekly/final report samples | Establish reporting parity and definitions | Reconciled sample reports | OPEN |
| SRC-008 | Institutional privacy, retention, and data-handling policy | Establish lawful processing and retention | Written institutional policy/approval | OPEN |

## Evidence intake checklist

For every newly supplied source:
- [ ] Store original without modification.
- [ ] Record source ID, filename, source/issuer, received date, version/date, and custodian.
- [ ] Confirm whether it is authoritative, illustrative, or obsolete.
- [ ] Extract requirements with stable IDs and exact wording.
- [ ] Record ambiguity and obtain Product Owner decision.
- [ ] Link extracted requirements in the Requirements Traceability Matrix.
- [ ] Keep the original available for future audit and regression comparison.
