# External Inspection Evidence Register — 001

**Document ID:** EVID-EXT-001  
**Version:** 0.1.0  
**Status:** EVIDENCE INVENTORY — PO RECEIPT ACKNOWLEDGED; INSTITUTIONAL AUTHORITY NOT INFERRED  
**Evidence received:** 2026-11-24  
**Project:** Dit. SD Inspection  
**Related:** DGA-B01..B03, DGA-B14, IFP-001..002, BRK-001..002, DOC-S-001, RTM, RAID, QA

## 1. Purpose and handling

This register records the external inspection documents and photographs supplied by the Product Owner in this conversation. The Product Owner's instruction is to accept these as project evidence and preserve the serial-number strings exactly as shown in their source. In particular, the 13-row serial-number list in the photograph is not to be rejected or reclassified merely because its serial-number prefix differs from another sample; it is a valid example as supplied and must be reconciled against its own source document and item context.

The uploaded files remain source artifacts in the conversation. This register records their identity and extracted observations; it does not claim that the files have been committed to Git, cryptographically archived, independently authenticated, or verified against a controlled institutional document repository.

## 2. Evidence inventory

| Evidence ID | Source artifact | Date / context | Directly observed content | Use and limitation |
|---|---|---|---|---|
| E-EXT-001 | `BA_INSPEKSI_SB_KRW_20-11-2026.pdf` | 20 Nov 2026; Gudang PT DUNEX, Karawang | BA reports 460 Standing Bracket samples inspected: 456 good and 4 defective. It identifies the inspection team and PT Hisense representative; annex begins a serial-number list and links documentation. | Primary evidence of the reported SB inspection result and its annex structure. Full 460-row reconciliation, signatures/paraf, source provenance and image/documentation completeness require page-level verification. |
| E-EXT-002 | `Pemeriksaan Barang_SB.pdf` | Form no. 469; 23 Nov 2026; Karawang | One-page inspection checklist for IFP Standing Bracket, brand/type WH3309-LK, physical and package serial `G5SID00000020174WSF4383`; visible physical-condition and accessory checks are marked compliant. Inspector name and signature area are blank in the supplied copy. | Evidence of the form/checklist content and one sample identity; not proof of who performed or authorized the inspection. |
| E-EXT-003 | `Pemeriksaan Barang.pdf` | Form no. 189; 24 Nov 2026; Purwakarta | Two-page IFP checklist, type 75WM61FE, physical/package serial `3TB75B26300R0 17EESJ1633`; checklist covers physical condition, accessories, specifications, operational ports and use tests; visible items are marked compliant. Inspector name and signature area are blank in the supplied copy. | Evidence of the IFP inspection instrument and one completed checklist copy; not independent proof of authority or a complete batch result. |
| E-EXT-004 | Photograph: “Lampiran. Daftar Serial Number Standing Bracket yang Sudah Dicek” | Supplied 24 Nov 2026; 13 visible rows | The page lists 13 serial-number examples beginning `3TB75B...`, all marked BAIK. The document heading identifies the list as Standing Bracket. | Preserve the serial strings and document heading as supplied. Product Owner clarified that these are correct serial-number examples in the PDF. Do not raise a mismatch solely from the prefix. This 13-row photo is not the complete 460-row annex. |
| E-EXT-005 | Photograph: Kemendikdasmen attendance sheet | Activity dates 23–25 Nov 2026; factory visit | Header identifies inspection of PID/IFP and completeness before delivery, at PT GAS, Kawasan Industri SKI 1, Purwakarta. Four attendee rows are visible; date columns are not visibly completed in the supplied photograph. | Evidence of an attendance-sheet template and listed participants; not proof of actual attendance on each date without completed attendance marks/signatures or other corroboration. |
| E-EXT-006 | Photograph: “Berita Acara Visitasi Pemeriksaan IFP ke Gudang Penyedia dan Pabrik Sebelum Pengiriman” | 23 Nov 2026; Purwakarta | Table reports 300 IFP inspected, 300 good, 0 defective; SB reports 0 inspected, 0 good, 0 defective. Named parties are shown for the inspection team and PT Hisense. | Evidence of a separate dated IFP visit report. Keep distinct from the 20 Nov SB BA and the 24 Nov individual IFP form. Signature authenticity and source-control status are not established by the photograph alone. |

## 3. Reconciliation rules

1. Keep each inspection event separate by date, location, item type and source artifact.
2. Do not combine the 20 Nov SB batch (460/456/4), 23 Nov IFP visit report (300/300/0; SB 0/0/0), 23 Nov SB sample form no. 469, and 24 Nov IFP form no. 189 into one inspection event.
3. Preserve every serial-number string exactly, including embedded spaces, letters, digits and leading zeros. Normalized comparison keys may be derived only as a separate field with a documented deterministic rule; never overwrite the source value.
4. Treat a photographed list as the number of rows actually visible in that image, not as a complete annex unless all pages and row ranges are present and reconciled.
5. Record source heading, source file, page, row, item type, date, location, condition and evidence link independently. A serial number is not a substitute for item classification.
6. A ticked checklist is evidence of the supplied form's recorded answer, not proof that the check was independently witnessed or that the named institution authorized the examiner.
7. Do not infer missing signatures, attendance marks, photo-slot requirements, legal basis, retention periods or institutional approval.
8. PO acceptance of the supplied artifacts for product/documentation analysis does not replace an institutional instrument owner, records/legal/privacy authority, authorized BA signatory, or attendance verifier.

## 4. Gate impact and disposition

| Gap | Evidence contribution | Remaining closure evidence |
|---|---|---|
| DGA-B01 — IFP instrument | E-EXT-003 and E-EXT-006 provide an IFP checklist example and a dated visit-report example. | Controlled instrument source/version, complete checklist and photo/evidence-slot rules, applicability approval and institutional instrument-owner provenance. |
| DGA-B02 — Standing Bracket instrument | Existing PO confirmation of the SB instrument baseline plus E-EXT-001, E-EXT-002 and E-EXT-004 provide a BA, sample checklist and serial-list example. | Full official source/annex inventory, complete row reconciliation, exact ambiguous wording and photo/evidence-slot applicability. |
| DGA-B03 — BA and attendance authority | E-EXT-001/E-EXT-006 show BA layouts and named parties; E-EXT-005 shows an attendance-sheet layout. | Institution-approved BA template, actual signatory/attendance authority matrix, and completed/verified attendance and sign-off evidence. |
| DGA-B14 — Inspection closure | E-EXT-001 and E-EXT-006 provide distinct sample outcomes and E-EXT-002/E-EXT-003 provide individual checklist examples. | Reconciliation rules, closure invariants and approved operational acceptance; runtime/QA execution remains separate. |

## 5. Product Owner disposition

The Product Owner's approval/acceptance of the supplied evidence examples is acknowledged for project requirements, document interpretation and design reconciliation. Previously recorded PO decisions remain approved and must not be requested again unless formally superseded.

This disposition does **not** create or imply institutional approval, signatory delegation, legal/records/privacy approval, provider ownership, independent technical certification, test execution, CI success, G9 scope-freeze approval or G10 implementation authorization.

## 6. Verification checklist

- [x] Source filenames and received artifacts inventoried.
- [x] Separate inspection dates/events preserved.
- [x] Serial-number example correction from Product Owner recorded.
- [x] Directly observed values separated from unresolved authority claims.
- [ ] Full 20-page SB BA and all annex rows reconciled, including count, duplicate detection and condition totals.
- [ ] Source-document provenance/version and institutional instrument-owner confirmation attached.
- [ ] BA signatory and attendance authority matrix supplied by authorized institution.
- [ ] Original signed/initialed copies or authorized digital-signature verification recorded.
- [ ] Evidence/photo URL reachability, authorization and required-slot mapping verified.
- [ ] Institutional records/privacy classification, purpose, retention and disposition approved.

## 7. Audit statement

This register improves evidence traceability and closes the ambiguity that the 13 serial-number examples should be rejected merely due to their prefix. It does not claim that DGA-B01..B03 are fully closed. Their Product Owner/documentation subcomponents may be treated as accepted; institutional provenance, signatory authority and source completeness remain explicitly outstanding. G9 must not pass until every gate-critical dependency has evidence and independent review.
