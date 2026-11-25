# Instrument Requirements Verification Matrix

**Status:** Verification design draft — no tests executed  
**Version:** 0.1.0  
**Date:** 2026-11-23

## 1. Purpose

This matrix links stable instrument requirement IDs to repeatable, data-driven verification procedures. It does not invent checklist wording, add source rows, or assume that identified photo slots are mandatory. It is not evidence that either source checklist is complete or officially approved.

## 2. Source inventory baseline

| Instrument | Identified checklist rows | Model/specification fields | Photo slots | Source status |
|---|---:|---:|---:|---|
| IFP | 49 | 14 | 10 | Checklist text reconciled to supplied two-page sample report; controlled authority/version and photo-slot completeness remain open |
| Standing Bracket | 19 official visible rows | Not established | 5 described | Official instrument document confirmed by Product Owner on 2026-11-23; photo-slot completeness and required status remain open |

## 3. IFP verification coverage

### Checklist IDs

| Category | Requirement IDs | Count | Verification |
|---|---|---:|---|
| Kondisi Fisik | IFP-CHK-001..006 | 6 | TC-IFP-CHK-001 |
| Kelengkapan Dokumen dan Aksesori | IFP-CHK-007..015 | 9 | TC-IFP-CHK-002 |
| Pemeriksaan Operasional | IFP-CHK-016..032 | 17 | TC-IFP-CHK-003 |
| Pengujian Penggunaan | IFP-CHK-033..049 | 17 | TC-IFP-CHK-004 |

The 49 checklist IDs are distinct from the 14 model specification fields.

### Model specification fields

| Requirement IDs | Count | Verification |
|---|---:|---|
| IFP-SP-001..014 | 14 | TC-IFP-SP-001 |

Expected values are model/version configuration data, not hardcoded global constants. Test the sample model 75WM61FE against its approved configuration. Test another model only if it enters project scope.

### Photo slots

| Requirement IDs | Count | Verification |
|---|---:|---|
| IFP-PH-001..010 | 10 | TC-IFP-PH-001 |

All ten labels are currently identified. Required/conditional/optional status remains OPEN. Tests verify display, version snapshot, evidence association, and safe behavior; they must not assert every slot blocks submission until required status is approved.

## 4. Standing Bracket verification coverage

The official 23-November instrument document contains 19 visible checklist rows: six physical and thirteen accessories. The following engineering IDs are traceability identifiers only; they do not alter source wording or order.

| Provisional requirement ID | Visible source row | Verification |
|---|---:|---|
| BRK-CHK-001 | 1 | TC-BRK-CHK-001 |
| BRK-CHK-002 | 2 | TC-BRK-CHK-001 |
| BRK-CHK-003 | 3 | TC-BRK-CHK-001 |
| BRK-CHK-004 | 4 | TC-BRK-CHK-001 |
| BRK-CHK-005 | 5 | TC-BRK-CHK-001 |
| BRK-CHK-006 | 6 | TC-BRK-CHK-001 |
| BRK-CHK-007 | 7 | TC-BRK-CHK-002 |
| BRK-CHK-008 | 8 | TC-BRK-CHK-002 |
| BRK-CHK-009 | 9 | TC-BRK-CHK-002 |
| BRK-CHK-010 | 10 | TC-BRK-CHK-002 |
| BRK-CHK-011 | 11 | TC-BRK-CHK-002 |
| BRK-CHK-012 | 12 | TC-BRK-CHK-002 |
| BRK-CHK-013 | 13 | TC-BRK-CHK-002 |
| BRK-CHK-014 | 14 | TC-BRK-CHK-002 |
| BRK-CHK-015 | 15 | TC-BRK-CHK-002 |
| BRK-CHK-016 | 16 | TC-BRK-CHK-002 |
| BRK-CHK-017 | 17 | TC-BRK-CHK-002 |
| BRK-CHK-018 | 18 | TC-BRK-CHK-002 |
| BRK-CHK-019 | 19 | TC-BRK-CHK-002 |

The ambiguous source transcription in row 14 remains verbatim pending confirmation. If the authorized complete checklist changes row count, wording, or order, reconcile these provisional IDs before freeze.

Five Standing Bracket photo labels are currently identified as BRK-PH-001..005. Completeness and required/conditional/optional status remain OPEN.

## 5. Data-driven verification procedures

### TC-IFP-CHK-001 — Physical condition
For each configured IFP-CHK-001..006: render exact approved wording/order; initial state is unanswered; require explicit Inspector response; capture finding note/evidence for non-compliance according to configuration; preserve item ID, result, and checklist version in immutable revision and PDF.

### TC-IFP-CHK-002 — Accessories and documents
For each IFP-CHK-007..015, apply the same state, finding, validation, version, and PDF checks. Preserve “Baterai A3” exactly until an authorized source resolves it.

### TC-IFP-CHK-003 — Operational checks
For each IFP-CHK-016..032, verify exact text, explicit result, finding handling, revision immutability, and report parity.

### TC-IFP-CHK-004 — Usage checks
For each IFP-CHK-033..049, verify exact text, explicit result, finding handling, revision immutability, and report parity.

### TC-IFP-SP-001 — Model specifications
For IFP-SP-001..014: load applicable model configuration; render expected and actual values separately where applicable; flag mismatch; preserve configuration version in historical inspections; ensure later configuration changes do not rewrite old records or PDFs.

### TC-IFP-PH-001 — IFP evidence slots
For IFP-PH-001..010: render configured label/status; link evidence to inspection, revision, slot, and uploader; make retries idempotent; enforce private access; gate submission only according to approved required status; preserve the frozen slot configuration.

### TC-BRK-CHK-001 — Standing Bracket physical rows
For provisional BRK-CHK-001..006: verify exact visible transcription, unanswered initial state, explicit result, finding handling, immutable revision, and report parity.

### TC-BRK-CHK-002 — Standing Bracket accessory rows
For provisional BRK-CHK-007..019: verify exact visible transcription and quantities, explicit result, finding handling, immutable revision, and report parity. Do not normalize row 14 quantity or wording before source confirmation.

### TC-BRK-PH-001 — Standing Bracket evidence slots
For BRK-PH-001..005: verify configured label display, correct evidence association, private access, retry/idempotency, frozen configuration, and gating only when an approved rule exists.

## 6. Cross-instrument integrity tests

| Test ID | Scenario | Expected result |
|---|---|---|
| TC-INSTR-001 | Same serial entered under different instrument | Follow approved serial identity policy; no accidental silent collision |
| TC-INSTR-002 | Instrument configuration updated while session is active | Active session retains frozen version |
| TC-INSTR-003 | Historical inspection opened after configuration update | Original labels, values, responses, and evidence slots remain unchanged |
| TC-INSTR-004 | Checklist item removed from current configuration | Historical inspection remains readable with original item snapshot |
| TC-INSTR-005 | Unknown or retired requirement ID submitted by client | Server rejects or safely quarantines unsupported input |
| TC-INSTR-006 | Concurrent edits to one inspection | Stale update is rejected with conflict; no silent overwrite |
| TC-INSTR-007 | PDF generated from approved inspection | PDF reconciles to exact approved revision and instrument version |
| TC-INSTR-008 | Evidence configuration changes after inspection starts | Inspection continues under frozen configuration; no retroactive gating change |

## 7. Acceptance and release gates

- Every identified source item must have a stable requirement ID and linked verification procedure.
- Every test execution records build SHA, environment, data fixture, tester, timestamp, actual result, and evidence.
- The 19 Standing Bracket traceability IDs must remain mapped verbatim to the Product-Owner-confirmed official 23-November instrument document; reconcile the earlier screenshot transcription separately and record any non-equivalence.
- Photo-slot required/conditional/optional status must be approved before mandatory submission gates are enabled.
- A test cannot pass solely because a UI default displays an OK/compliant state.
- No item is officially approved solely because it appears in a sample or screenshot.
- Tests in this document are designed, not executed.

## 8. Current status

- IFP checklist ID coverage: 49/49 identified; source authority open.
- IFP model fields: 14/14 identified; model applicability requires confirmation.
- IFP photo labels: 10/10 identified; completeness and mandatory status open.
- Standing Bracket official document: 19/19 visible checklist rows identified (6 physical + 13 accessories); source confirmed by Product Owner. Photo-slot completeness and mandatory status remain open.
- Standing Bracket photo labels: 5/5 identified from legacy reference; completeness and mandatory status open.
- Test execution: NOT STARTED.
- Scope freeze: NOT READY.


## 9. Reconciliation against newly supplied operational documents (2026-11-23)

New evidence reviewed:
- `Pemeriksaan Barang_SB.pdf`, one-page inspection report dated 23 November 2026, inspection no. 469, supplier PT Hisense International Indonesia, location Karawang, model WH3309-LK.
- `BA_INSPEKSI_SB_KRW_20-11-2026.pdf`, 20-page visitasi BA dated 20 November 2026 for Standing Bracket at PT DUNEX, Karawang.

The Product Owner confirmed on 2026-11-23 that `Pemeriksaan Barang_SB.pdf` is the official Standing Bracket instrument document. It visibly contains 19 checklist statements: six under “01 Kondisi Fisik” and thirteen under “02 Kelengkapan Dokumen dan Aksesories”. The earlier screenshot transcription remains a separate source observation; its mapping to this official source must be reconciled, not silently merged or discarded. Therefore:
- Keep the earlier 19-row transcription as a separate source-observation set; do not silently delete or renumber it.
- Add a source-specific 19-row set for the 23 November form, preserving its exact wording and grouping.
- Treat the overlap (first six physical checks and many accessories) as candidate equivalence, not confirmed identity, until a controlled source is supplied.
- Preserve the ambiguous line “Ring/klem Roda (4 pcs) + 4 (4pcs)” exactly as printed.
- The form displays a yes/no conformity column; the sample marks visible rows as conforming. It does not define finding notes, evidence requirements, N/A behavior, or mandatory photo slots.

The 20 November BA provides a real output example: 460 Standing Bracket samples checked, 456 good and 4 defective; it includes a serial-number annex with condition values, documentation links separated by good/defective headings, and two paraf columns (Tim Pemeriksa Dit.SD and PT Hisense). This is evidence for report/annex parity tests, not a new fixed product limit or approved signatory policy.

### Additional source-specific verification requirements
- TC-BRK-SRC-001: render and preserve the exact 19-row 23-November sample form independently of the earlier 19-row screenshot set.
- TC-BRK-SRC-002: verify source mapping between the two 19-row source sets; unresolved/ambiguous mappings remain visible and cannot be auto-merged.
- TC-BRK-BA-001: generate a BA summary whose sample, good, and defective counts reconcile to the serial annex; test 460 = 456 + 4 using a fixture only.
- TC-BRK-BA-002: ensure every annex serial has exactly one allowed condition value and totals match the summary; flag duplicates, missing serials, and count mismatch before issuance.
- TC-BRK-BA-003: generate condition-grouped evidence references and configurable paraf blocks without exposing public or signed URLs.
- TC-BRK-BA-004: preserve BA date, inspection location, supplier, instrument, and signatory labels from the approved BA configuration; do not hardcode the sample names or date.

These are designed tests, not executed tests. The Product Owner has confirmed the 23-November document as the official Standing Bracket instrument source; this does not establish missing photo rules or prove the test cases have been executed.


## T-17 — Instrument configuration governance verification (design only)

- CFG-001-001: reject an unsupported field type or validation primitive; no dynamic code/expression execution occurs.
- CFG-001-002: validate checklist section/item ordering, applicability, expected values and evidence-slot definitions as one versioned declarative configuration.
- CFG-001-003: an authorized Super Admin with `instrument.publish` can publish a valid draft without a second-person approval; an unauthorized actor or missing permission is denied.
- CFG-001-004: publication and audit record are atomic; forced audit failure leaves the draft unpublished and creates no partial publication.
- CFG-001-005: published version and child configuration cannot be edited/deleted; corrections require a new version.
- CFG-001-006: active sessions/assignments and historical revisions retain their pinned version after a newer version is published or an older version is deactivated.
- CFG-001-007: deactivation is separately permissioned, reasoned and audited and does not rewrite historical records.
- CFG-001-008: catalog administration/publication does not grant inspection access across projects; unit access still requires project association, session, assignment and permission.

These are verification specifications only. No test execution is claimed.
