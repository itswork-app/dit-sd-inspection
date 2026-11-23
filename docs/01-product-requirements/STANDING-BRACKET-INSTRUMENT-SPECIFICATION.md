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


## 7. Additional supplied operational evidence — 20 and 23 November 2026

### 7.1 Sample inspection form dated 23 November 2026

The supplied one-page `Pemeriksaan Barang_SB.pdf` is headed “Laporan Hasil Pemeriksaan Peralatan Digitalisasi Pembelajaran” and records:
- Nomor Pemeriksaan: 469.
- Nama Perusahaan: PT. Hisense International Indonesia.
- Tanggal Pemeriksaan: Senin, 23/11/2026.
- Tempat: Karawang.
- Nama Pemeriksa: blank line.
- Nama Item Barang: “Interactive Flat Panel (IFP) Standing Bracket” (retained verbatim; the label is ambiguous and must not be silently normalized to one instrument).
- Merk, Tipe: WH3309-LK.
- Nomor Seri Fisik and Nomor Seri Kemasan: G5SID00000020174WSF4383 in both fields.

The form contains 18 visible checklist statements grouped as follows:

**01 Kondisi Fisik (6 rows)**
1. Kemasan tanpa kerusakan atau cacat fisik
2. Serial number pada kemasan sama dengan pada perangkat
3. Alat merupakan barang baru
4. Alat kuat dan kokoh
5. Alat tanpa kerusakan atau cacat fisik
6. Alat memiliki identitas permanen (lambang/merk) dari produsen

**02 Kelengkapan Dokumen dan Aksesories (12 rows)**
7. Petunjuk Instalasi atau Petunjuk Operasi
8. Rangka R-L (2pcs)
9. Tiang Sambung atas R-L (2pcs)
10. Tiang sambung bawah R-L (2pcs)
11. Rak Tengah (1pcs)
12. Wall Mount Bracket ( 1 pcs )
13. Roda Bracket (4 pcs)
14. Ring/klem Roda (4 pcs) + 4 (4pcs)
15. Standing Hook/Pengait Bracket ( 2 pcs )
16. Baut Standing Bracket ( 4 pcs )
17. Ring/klem Standing Bracket ( 4 pcs )
18. Baut Bracket (18 pcs)
19. Kunci pas (1 pcs)

**Important count clarification:** the form has 18 checklist rows total: six physical plus twelve accessories. The numbering above is a continuous reference index, not a claim that there are 19 rows. Preserve the exact spelling, spacing, and ambiguous quantity as source data. The form's visible result column is “Sesuai? Ya/Tdk”; it does not define mandatory photo slots, N/A rules, notes, or evidence requirements.

This 18-row sample differs from the earlier 19-row screenshot transcription. Keep both source versions distinct pending controlled master checklist confirmation; do not delete, merge, or renumber the earlier record. The phrase “Interactive Flat Panel (IFP) Standing Bracket” also requires Product Owner confirmation of the exact instrument label and whether it refers to SB or a combined display label.

### 7.2 BA visitasi dated 20 November 2026

The supplied 20-page `BA_INSPEKSI_SB_KRW_20-11-2026.pdf` records a visitasi inspection of Standing Bracket at Gudang PT DUNEX, Karawang, for PT Hisense International Indonesia. Its summary states:
- Standing Bracket samples checked: 460.
- Good condition: 456.
- Defective condition: 4.
- IFP sample count in this BA: 0.

The annex contains a numbered serial-number list with a condition field (Baik/Cacat), documentation headings for good and defective conditions, and paraf columns for Tim Pemeriksa Dit.SD and PT Hisense. The first page shows signature blocks for Tim Pemeriksaan Direktorat SD and PT Hisense International Indonesia. These are sample document structures, not fixed business rules or fixed signatory identities.

Requirements derived from these samples:
1. The inspection register must preserve exact serial number and final condition for each unit.
2. BA summary counts must reconcile to serial annex rows and condition values; reject issuance when counts differ.
3. The report model must support multiple instrument types and zero-count instruments without fabricating rows.
4. Good/defective evidence groups must reference private evidence objects through controlled access, not permanent public URLs.
5. Paraf and signatory blocks must be configurable document-template elements; the sample does not settle mandatory signatory count, order, or signing authority.
6. Inspection number, date, location, supplier, model, inspector, physical serial, and package serial are explicit report fields. Whether the inspection number is project-global or session-scoped remains open.
7. The 460/456/4 values are a reconciliation test fixture only, not a configured maximum or expected operational quantity.

### 7.3 Required reconciliation tests

- Compare the source-specific 18-row form with the earlier 19-row screenshot transcription; preserve both until an authorized master is supplied.
- Verify physical serial and package serial separately, including exact-match and mismatch cases.
- Verify 460 = 456 + 4 on a sample fixture and reconcile all serial annex rows against those totals.
- Detect duplicate serials, missing serials, invalid condition values, and summary/annex count mismatch before BA issuance.
- Verify condition-grouped evidence references and configurable paraf/signatory blocks.

No new checklist version is declared authoritative by this evidence alone. Product Owner and institutional source authority approval remain required.
