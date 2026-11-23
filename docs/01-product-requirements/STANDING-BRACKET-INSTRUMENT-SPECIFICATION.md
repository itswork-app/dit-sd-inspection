# Standing Bracket Instrument Specification

Status: Draft — reconciled with supplied legacy screenshots and serial-number annex sample; controlled checklist authority/version remains open  
Instrument: Standing Bracket

## 1. Configuration and versioning

- Standing Bracket is a separate instrument from IFP.
- Checklist categories/items, expected values, photo slots, required status, and applicability must be configurable by authorized Super Admin.
- Instrument configuration is versioned.
- Active sessions freeze the instrument version.
- Historical inspections preserve their original configuration snapshot.

## 2. Evidence/photo slots currently identified

Five labels have been described from earlier legacy reference material. This list is not confirmed complete and no mandatory status is assumed.

| Slot ID | Display label from reference | Current status |
|---|---|---|
| BRK-PH-001 | Nomor Seri pada Dus | Label known; required status OPEN |
| BRK-PH-002 | Layer Atas (Ketika Dibuka) | Label known; required status OPEN |
| BRK-PH-003 | Layer Kedua (dengan baut) | Label known; required status OPEN |
| BRK-PH-004 | Foto Baut Only | Label known; required status OPEN |
| BRK-PH-005 | Nomor Seri pada Bracket | Label known; required status OPEN |

The supplied photographs include a paper attachment titled `Lampiran. Daftar Serial Number Standing Bracket yang Sudah Dicek`. It references two documentation links for Standing Bracket conditions (baik/cacat), and contains a serial-number table with a condition column. This supports the need for a generated serial-number annex linked to the inspection documentation. It does not prove that the five legacy photo slots above are complete or mandatory.

## 3. Checklist items transcribed from newly supplied screenshots

The screenshots show 19 distinct checklist rows in the visible sequence. The second screenshot repeats the first two rows at the bottom as an apparent scroll overlap; they are not counted twice.

### 3.1 Initial physical-condition rows

The first six visible rows are:

1. Kemasan tanpa kerusakan atau cacat fisik
2. Serial number pada kemasan sama dengan pada perangkat
3. Alat merupakan barang baru
4. Alat kuat dan kokoh
5. Alat tanpa kerusakan atau cacat fisik
6. Alat memiliki identitas permanen (lambang/merek) dari produsen

The final row is clipped at the right edge of the screenshot after “dari”; the wording above is retained from the existing reference transcription and is not independently fully legible in this image.

### 3.2 Accessory/completeness rows

The following 13 rows are visible after the initial six:

7. Petunjuk Instalasi atau Petunjuk Operasi
8. Rangka R-L (2pcs)
9. Tiang Sambung atas R-L (2pcs)
10. Tiang sambung bawah R-L (2pcs)
11. Rak Tengah (1pcs)
12. Wall Mount Bracket (1 pcs)
13. Roda Bracket (4 pcs)
14. Ring/klem Roda (4 pcs) + 4 (4pcs)
15. Standing Hook/Pengait Bracket (2 pcs)
16. Baut Standing Bracket (4 pcs)
17. Ring/klem Standing Bracket (4 pcs)
18. Baut Bracket (18 pcs)
19. Kunci pas (1 pcs)

**Transcription cautions**
- Preserve the wording and quantities exactly as shown until the official instrument document is obtained.
- In particular, “Ring/klem Roda (4 pcs) + 4 (4pcs)” is ambiguous; do not normalize its quantity or interpretation.
- Capitalization and spacing are retained as close as practical to the screenshot.
- The screenshot does not show the full category headings, so the grouping above is descriptive, not a claim about official category names.
- The screenshots do not establish whether each row is mandatory, optional, conditional, or supports N/A.

## 4. Serial-number annex evidence and requirements

The supplied sample annex establishes the following visible structure:
- Title identifying it as a list of Standing Bracket serial numbers already checked.
- Documentation links separated by condition: `Kondisi Baik` and `Kondisi Cacat`.
- A separate Interactive Flat Panel (IFP) section is also shown, with condition headings; the sample leaves its entries blank.
- Table columns: `No`, `Serial Number`, and `Kondisi (baik/cacat)`.
- A `Paraf` area with two columns: `Tim Pemeriksa Dit.SD` and `PT Hisense`.

System requirements derived from this sample:
1. Generate annex rows from the authoritative inspection records, not manually retyped serial lists.
2. Preserve the exact physical serial number and condition outcome for each inspected unit.
3. Separate instrument and condition groups in the output.
4. Include links or document references to the corresponding evidence package, subject to access control; do not expose permanent public storage URLs.
5. Support the two paraf columns as configurable document blocks; whether both are mandatory remains an open Product Owner decision.
6. Reconcile annex totals and serial rows against the inspection register before issuance.

The photograph visibly shows 13 Standing Bracket serial-number rows, each marked `BAIK`. This is a sample, not a fixed limit or a rule that all records must be good.

## 5. Required validation

1. Obtain the complete authorized source checklist and version.
2. Obtain complete original screenshots for every checklist and evidence screen.
3. Confirm whether the five known photo labels are complete.
4. Confirm which evidence slots are mandatory, conditional, or optional.
5. Confirm whether checklist items require notes, measurements, or quantity entry.
6. Confirm the exact meaning and quantity of “Ring/klem Roda (4 pcs) + 4 (4pcs)”.
7. Confirm official PDF/report grouping and finding presentation.
8. Confirm whether the six initial physical-condition rows use the same wording and semantics as IFP.

## 6. Submission behavior

The common inspection engine rules apply: serial claim, versioned checklist, explicit verification, finding note/evidence, configured exceptions, pre-submit validation, immutable revisions, and server-side submission. Instrument-specific criteria must not be inferred from IFP.
