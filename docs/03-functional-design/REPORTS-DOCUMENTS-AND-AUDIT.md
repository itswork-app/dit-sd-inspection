# Reports, Documents, Printing, Attendance, and Audit Design

**Status:** Draft v0.1.0 — requires Product Owner validation  
**Package:** C — Functional and Operational Design

## 1. Inspection PDF

The per-unit inspection PDF is generated from an approved immutable inspection revision and its frozen instrument/checklist configuration.

Requirements:
- Include organization/title, Inspector identity, unit identity/serial number, checklist results, relevant evidence references, and configured signature block.
- Inspector name is populated from the inspection record by default; authorized configuration may allow manual override if approved.
- Wet-signature area remains blank for paper signing.
- A PDF generated from an earlier revision remains a historical artifact and is never overwritten in place.
- Regeneration creates a new document version linked to its source inspection revision.
- Print action is a separate auditable event.

## 2. Printing

- Print Officer or another user with explicit `document.print` permission prints approved PDFs.
- Each print event records document version, operator, timestamp, sequence number, and result where available.
- Reprint footer uses a sequential label such as “Cetak ke-2”; sequence must be generated atomically.
- A failed/aborted print attempt must not be represented as a successful print without an explicit result.
- Print action is not equivalent to wet signature.

## 3. Berita Acara (BA)

BA is a session/project-level document, not a per-unit inspection signature.

### Sample evidence — supplied BA photograph

The supplied sample is titled `BERITA ACARA VISIT & PEMERIKSAAN IFP KE GUDANG PENYEDIA DAN PABRIK SEBELUM PENGIRIMAN`. It visibly includes:
- narrative date and location (Purwakarta, 23 November 2026);
- a summary table with `Jenis Barang`, `Jumlah Sampel yang Diperiksa`, `Jumlah Kondisi Baik`, and `Jumlah Kondisi Cacat`;
- separate rows for Interactive Flat Panel (IFP) and Standing Bracket (SB);
- two party/signature blocks: `Tim Pemeriksaan Direktorat SD` and `PT Hisense International Indonesia`;
- printed representative names and an NIP for the Directorate block, plus a company representative name in the other block.

The example records 300 IFP samples, 300 good, 0 defective, and 0 Standing Bracket samples. These are sample values only and must never be hardcoded as project totals.

### BA generation requirements derived from the sample

- Generate the summary by instrument from reconciled inspection outcomes.
- Keep sample count, good count, and defective count as distinct fields; validate that good + defective does not exceed or contradict inspected sample count.
- Support zero-count instrument rows without omitting the instrument from the BA.
- Store the BA date, location, activity title/narrative, and signatory blocks as versioned document data.
- Do not infer signatory authority from application role names; use authorized configured signatory data.

Known reference screenshot shows two signatory blocks:
- Tim Pemeriksaan Direktorat SD
- PT Hisense International Indonesia

Names, titles, block labels, and ordering should be configurable by authorized Super Admin, with versioning and audit. A signed scan/photo/PDF may be uploaded later. Proposed lifecycle:
- `DRAFT`
- `ISSUED` (TERBIT)
- `SIGNED` (DITANDATANGANI)

Original uploaded files must be preserved. Replacement requires a reason and audit event. Whether both signatory parties are always required, number/order of blocks, and authorized verifier remain open.

## 4. Attendance

Attendance list is generated from official assignment membership.

### Sample evidence — supplied attendance photograph

The supplied `DAFTAR HADIR` sample shows an activity title and venue/factory, then a table with columns `No`, `Nama`, `Instansi`, and separate attendance columns for Monday 23 November 2026, Tuesday 24 November 2026, and Wednesday 25 November 2026. Each participant row has space to mark attendance per date. Names and personal identifiers visible in the sample are not copied into this specification; the system should populate authorized roster data from assignments.

### Attendance generation requirements derived from the sample

- Support one activity roster spanning multiple calendar dates.
- Generate one attendance column per configured activity date, preserving weekday and date labels.
- Include participant name and institution; NIP and rank/grade may be included when present in the authorized personnel record and required by the approved template.
- Support blank attendance cells for manual signature/marking after printing.
- Do not mark a participant present merely because they are assigned to the activity.

Proposed fields:
- full name;
- NIP, if available;
- rank/grade, if available;
- institution, if available;
- attendance date/session.

Workflow states:
- `GENERATED`
- `PRINTED`
- `PENDING_UPLOAD`
- `UPLOADED`
- `VERIFIED`

Support multi-page output and upload of PDF/JPG/PNG. Original uploaded file is retained. Replacement requires reason and audit. Verification authority remains open.

## 5. Standing Bracket serial-number annex

The supplied serial-number annex sample is a distinct output from the per-unit inspection PDF and BA. It contains condition-separated documentation links, instrument sections, serial-number rows with a `BAIK/CACAT` condition, and paraf blocks for the Directorate inspection team and PT Hisense. Generate it from inspection records, reconcile its rows and totals, and preserve each issued version. Do not hardcode the sample's 13 rows or all-good outcome.

## 6. Reporting

Two report perspectives remain distinct:

### Actual report — internal
Reflects real activity dates, times, counts, status, and productivity. Actual timestamps come from immutable inspection events. Never shift actual dates to satisfy a target schedule.

### Target report — client-facing
Reflects approved target plan, planned daily distribution, target allocation, and progress against plan. Target allocation may be reconfigured by authorized Admin/Super Admin; changes are versioned and audited and never mutate actuals.

Required report families:
- daily Actual and Target;
- weekly Actual and Target;
- final Actual and Target.

Korlap validates/approves daily reports within assigned location. Super Admin monitors all locations. Exact headline count basis, separate templates versus one configurable template, and client portal versus PDF-only remain open.

## 7. Audit trail

Proposed event coverage:
- authentication/account approval/rejection/suspension;
- role, permission, scope, and assignment changes;
- session lifecycle and target changes;
- claim acquisition/release/expiry;
- checklist/evidence edits and submissions;
- review, return, approval, reopen, and resubmission;
- configuration/version changes;
- PDF generation, printing, BA, and attendance upload/verification;
- report generation/validation/export;
- offline synchronization and conflict resolution.

Each event should record actor, active role, timestamp, action, entity reference, session/assignment scope, outcome, reason where applicable, and correlation ID. Audit log is append-only. Super Admin may view/export but not edit or delete audit records through the application.

INS-016 is still a proposal until explicitly approved; this document defines a design proposal, not an approved policy.

## 8. Acceptance criteria

- PDF content maps to the exact approved inspection revision.
- Regeneration does not overwrite prior PDF artifacts.
- Print sequence is concurrency-safe and every print event is attributable.
- BA signatory configuration is versioned.
- Attendance upload preserves original and replacement history.
- Actual reporting is derived from actual event timestamps.
- Target reallocation does not rewrite actuals.
- Audit coverage includes all high-impact operational and administrative actions.

## 9. Open decisions

- Mandatory BA signatories and authorized verifier.
- Executive summary signature requirement.
- Client report portal versus PDF-only.
- Actual headline count basis.
- Project closure and final reconciliation process.
- Attendance verification authority.
- Print Officer distinct role versus permission-based capability.
- Retention/deletion schedule for PDFs, attendance, BA, and audit evidence.


## Package T — approved Product Owner direction (2026-11-23)

- **BA template:** Signatory blocks are configurable per approved BA template, including number of parties, organization, role/title, order and required/optional status. Actual authorized signatory identities and authority remain subject to institutional approval.
- **Executive summary:** Signature behavior is configurable per report template; default is no signature unless the approved template requires it.
- **Client delivery:** Initial release is PDF-only. Client portal is deferred and requires a later approved change request.

The available sample BA does not establish who is legally/administratively authorized to sign. This document therefore records configurable template behavior, not approval of any named signatory. PDF generation/access/distribution remains scoped, versioned and audited. T-05 report metric semantics, project closure and attendance verification remain open.
