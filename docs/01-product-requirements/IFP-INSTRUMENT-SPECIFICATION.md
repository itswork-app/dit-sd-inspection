# IFP Instrument Specification

Status: Draft — official source validation required  
Instrument: Interactive Flat Panel (IFP)  
Source basis: Requirements and labels transcribed from legacy reference-screen descriptions. This is not yet an authoritative controlled checklist.

## 1. Configuration and versioning

- IFP is a separately configurable instrument.
- Checklist category/item wording, order, expected values, evidence slots, mandatory status, and applicability are configurable by authorized Super Admin.
- Configuration is versioned.
- An active session freezes the instrument version; existing inspections preserve that snapshot.
- Changes do not retroactively alter historical inspections or reports.

## 2. Evidence/photo slots currently identified

The following ten labels have been described from the reference application. Completeness and mandatory/conditional status require confirmation.

| Slot ID | Display label from reference | Current status |
|---|---|---|
| IFP-PH-001 | Serial Number Dus | Label known; required status OPEN |
| IFP-PH-002 | Serial di Belakang Layar | Label known; required status OPEN |
| IFP-PH-003 | RAM pada Developer Mode | Label known; required status OPEN |
| IFP-PH-004 | Kelengkapan Kabel dengan Serial dan Garansi | Label known; required status OPEN |
| IFP-PH-005 | External Port Depan | Label known; required status OPEN |
| IFP-PH-006 | External Port Belakang | Label known; required status OPEN |
| IFP-PH-007 | Serial dan Penyimpanan pada Pengaturan | Label known; required status OPEN |
| IFP-PH-008 | Logo Merah Putih | Label known; required status OPEN |
| IFP-PH-009 | Kamera/Webcam | Label known; required status OPEN |
| IFP-PH-010 | Stiker Barang Milik Negara | Label known; required status OPEN |

## 3. Checklist categories and identified items

### 3.1 Kondisi Fisik

| Item ID | Checklist statement |
|---|---|
| IFP-CHK-001 | Kemasan tanpa kerusakan atau cacat fisik. |
| IFP-CHK-002 | Serial number pada kemasan sama dengan pada perangkat. |
| IFP-CHK-003 | Alat merupakan barang baru. |
| IFP-CHK-004 | Alat kuat dan kokoh. |
| IFP-CHK-005 | Alat tanpa kerusakan atau cacat fisik. |
| IFP-CHK-006 | Alat memiliki identitas permanen (lambang/merek) dari produsen. |

### 3.2 Kelengkapan Dokumen dan Aksesori

| Item ID | Checklist statement |
|---|---|
| IFP-CHK-007 | Kartu Garansi. |
| IFP-CHK-008 | Petunjuk Instalasi atau Petunjuk Operasi dan video tutorial. |
| IFP-CHK-009 | Kabel Power (1 Pcs). |
| IFP-CHK-010 | Kabel HDMI 3 Meter (1 pcs). |
| IFP-CHK-011 | Kabel USB-A to USB-B 3 Meter (1 pcs). |
| IFP-CHK-012 | Remote + Baterai A3 (2 pcs). |

**Validation note:** "Baterai A3" is transcribed as currently described and may be a source typo or product-specific designation. Do not silently change it to another battery size. Confirm against official checklist.

| Item ID | Checklist statement |
|---|---|
| IFP-CHK-013 | Pena Stylus (2 pcs). |
| IFP-CHK-014 | Terdapat Stiker Barang Milik Negara. |
| IFP-CHK-015 | Terdapat Logo Merah Putih. |

### 3.3 Kesesuaian Spesifikasi

The following is an example specification for a model described in the reference material. It is not a universal IFP specification and must be configurable/versioned per applicable model.

| Item ID | Specification field | Example expected value |
|---|---|---|
| IFP-SP-001 | Merk | Hisense |
| IFP-SP-002 | Tipe | 75WM61FE |
| IFP-SP-003 | Processor | - |
| IFP-SP-004 | Memori | 16 GB |
| IFP-SP-005 | Kapasitas Penyimpanan | 256 GB |
| IFP-SP-006 | Layar Monitor | 75 Inch |
| IFP-SP-007 | Jenis Layar | Layar Sentuh |
| IFP-SP-008 | OS | Android 13 |
| IFP-SP-009 | Audio | Terintegrasi |
| IFP-SP-010 | Kamera | Terintegrasi dengan Pelindung |
| IFP-SP-011 | Power Supply | Maksimal 350 Watt |
| IFP-SP-012 | Konektivitas | Support Wifi 6, LAN, Bluetooth |
| IFP-SP-013 | I/O Port | USB Type A 3 port, USB Type B, USB Type C 1 port, HDMI In 3 port, HDMI Out 1 port, LAN 1 port, Audio 1 port, Data 1 port |
| IFP-SP-014 | Garansi | 3 Tahun On-site |

### 3.4 Pemeriksaan Operasional

| Item ID | Checklist statement |
|---|---|
| IFP-CHK-016 | Tombol Power dan Lampu Indikator berfungsi baik. |
| IFP-CHK-017 | OS dapat dioperasikan. |
| IFP-CHK-018 | USB Type A (3) (Bagian Depan) berfungsi baik. |
| IFP-CHK-019 | HDMI In (1) (Bagian Depan) berfungsi baik. |
| IFP-CHK-020 | USB Type C (1) (Bagian Depan) berfungsi baik. |
| IFP-CHK-021 | Audio Port (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-022 | HDMI In (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-023 | HDMI Out (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-024 | LAN Port (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-025 | LAN Port (1) (Bagian Belakang Kamera Atas) berfungsi baik. |
| IFP-CHK-026 | USB Type A (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-027 | USB Type B (1) (Bagian Belakang) berfungsi baik. |
| IFP-CHK-028 | LAN RS232-1 (1) (Bagian Belakang Kiri Bawah) berfungsi baik. |
| IFP-CHK-029 | LAN RS232-2 (1) (Bagian Belakang Kiri Bawah) berfungsi baik. |
| IFP-CHK-030 | Audio Digital Out (1) (Bagian Belakang Kiri Bawah) berfungsi baik. |
| IFP-CHK-031 | Line In (Audio In) (1) (Bagian Belakang Kiri Bawah) berfungsi baik. |
| IFP-CHK-032 | Handle (Pegangan IFP) (2) kondisi baik. |

### 3.5 Pengujian Penggunaan

| Item ID | Checklist statement |
|---|---|
| IFP-CHK-033 | Dapat melakukan Pengaturan layar (brightness, contrast, dan seterusnya). |
| IFP-CHK-034 | Fitur Papan Tulis Digital dapat dioperasikan. |
| IFP-CHK-035 | Fitur Multi Finger dapat digunakan. |
| IFP-CHK-036 | Fitur multi touch dapat digunakan. |
| IFP-CHK-037 | Pena Stylus dapat digunakan. |
| IFP-CHK-038 | Keyboard digital (karakter dalam alfabet latin) dapat digunakan. |
| IFP-CHK-039 | Fitur Berbagi Layar dengan kabel dapat dioperasikan. |
| IFP-CHK-040 | Fitur Berbagi Layar tanpa kabel dapat dioperasikan. |
| IFP-CHK-041 | Koneksi Wifi berfungsi dengan baik. |
| IFP-CHK-042 | Koneksi Hotspot berfungsi dengan baik. |
| IFP-CHK-043 | Koneksi Bluetooth berfungsi dengan baik. |
| IFP-CHK-044 | Dapat menambahkan Akun Pengguna. |
| IFP-CHK-045 | Dapat melakukan Update Sistem. |
| IFP-CHK-046 | Kamera berfungsi dengan baik. |
| IFP-CHK-047 | Dapat menginstal aplikasi Hwinfo/CPU-Z atau yang lainnya. |
| IFP-CHK-048 | Output Audio dapat berfungsi dengan baik. |
| IFP-CHK-049 | Pengaturan Suara dapat berfungsi dengan baik. |

## 4. Checklist behavior

- UI may present the compliant/OK state as the low-friction default, but this must never count as evidence that the Inspector physically verified the item.
- Inspector must explicitly verify the item as part of the inspection flow.
- If an item does not comply, Inspector records a finding note and supporting evidence according to configured rules.
- NOT_TESTABLE and NOT_APPLICABLE are allowed only when enabled by configuration, with a reason and any required Reviewer decision.
- A required evidence slot may be waived only through an authorized exception with reason and alternative evidence where required.
- Final submission is blocked while required checklist statuses, finding notes/evidence, required photo slots, or synchronization conflicts remain incomplete.
- PDF highlights findings and preserves the approved checklist version and results.

## 5. Open validation items

1. Confirm official checklist source, version, wording, order, and completeness.
2. Confirm whether each item is binary or requires expected/actual values.
3. Confirm meaning and expected value for Processor "-".
4. Confirm "Baterai A3" exact wording/specification.
5. Confirm exact port counts and locations, including repeated HDMI/LAN descriptions.
6. Confirm all ten photo slots and required/conditional status.
7. Confirm whether one IFP model or multiple models are in project scope.
8. Confirm how findings are classified and whether severity is required.
9. Confirm whether photo evidence can satisfy more than one slot or checklist item.
10. Confirm official PDF presentation and checklist grouping.
