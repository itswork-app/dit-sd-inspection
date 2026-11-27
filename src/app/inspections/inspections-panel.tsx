"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { SerialScanner } from "@/components/serial-scanner";
import { ALLOWED_EVIDENCE_MIMES, MAX_EVIDENCE_BYTES } from "@/lib/api/inspection-validators";
import {
  enqueueDraftOperation,
  getDefaultOfflineQueueStore,
  loadStoredDeviceBinding,
  purgeOfflineLocalState,
  rebaseConflictOperation,
  reconcileSyncResults,
  saveStoredDeviceBinding,
  sha256Hex,
  type OfflineSyncOperation,
  type StoredDeviceBinding,
  type SyncServerOpResult
} from "@/lib/offline/sync-queue";

type InspectionRow = {
  id: string;
  unit_id: string;
  project_id: string;
  session_id: string;
  instrument_version_id: string;
  status: string;
  current_revision_no: number;
  row_version: string;
  updated_at: string;
};

type ClaimRow = {
  id: string;
  unit_id: string;
  status: string;
  expires_at: string;
  row_version: string;
};

type RevisionRow = {
  id: string;
  inspection_id: string;
  revision_no: number;
  submitted_at: string;
};

type AbortRow = {
  id: string;
  inspection_id: string;
  status: string;
  request_reason: string;
  row_version: string;
};

type EvidenceAssetRow = {
  id: string;
  inspection_id: string;
  slot_definition_id: string;
  mime_type: string;
  observed_byte_size: number | null;
  expected_byte_size: number;
  upload_status: string;
  created_at: string;
};

type EvidenceSlotRow = {
  id: string;
  instrument_version_id: string;
  code: string;
  label: string;
  required: boolean;
};

type TemplateRow = {
  id: string;
  document_type: string;
  template_key: string;
  version_no: number;
  status: string;
};

type DeviceBindingRow = {
  id: string;
  label: string;
  status: string;
  bound_at: string;
};

type ChecklistSectionRow = {
  id: string;
  instrument_version_id: string;
  code: string;
  label: string;
  sort_order: number;
};

type ChecklistItemRow = {
  id: string;
  section_id: string;
  code: string;
  label: string;
  answer_type: string;
  required: boolean;
  sort_order: number;
};

type SpecFieldRow = {
  id: string;
  instrument_version_id: string;
  code: string;
  label: string;
  value_type: string;
  expected_value: string | null;
  unit: string | null;
  required: boolean;
  sort_order: number;
};

type DraftContextRow = {
  inspection_id: string;
  draft_checklist: Record<string, unknown>;
  draft_specifications: Record<string, unknown>;
  notes: string | null;
};

type AssignmentRow = {
  id: string;
  project_id: string;
  session_id: string;
  instrument_id: string;
  instrument_version_id: string;
  status: string;
};

type InstrumentRow = {
  id: string;
  code: string;
  name: string;
  instrument_type: string;
};

type UnitRow = {
  id: string;
  instrument_type: string;
  serial_raw: string | null;
  serial_normalized: string | null;
};

type InspectionsPanelProps = {
  inspections: InspectionRow[];
  activeClaims: ClaimRow[];
  revisions: RevisionRow[];
  abortRequests: AbortRow[];
  evidenceAssets: EvidenceAssetRow[];
  evidenceSlots: EvidenceSlotRow[];
  documentTemplates: TemplateRow[];
  activeDevices: DeviceBindingRow[];
  checklistSections: ChecklistSectionRow[];
  checklistItems: ChecklistItemRow[];
  specFields: SpecFieldRow[];
  draftContexts: DraftContextRow[];
  assignments: AssignmentRow[];
  instruments: InstrumentRow[];
  units: UnitRow[];
};

const ALLOWED_MIME_SET = new Set<string>(ALLOWED_EVIDENCE_MIMES);

/**
 * PO-2026-11-27-CHECKLIST-DEFAULT-OK-001 (Option 1B):
 * Defaults PASS_FAIL -> PASS and YES_NO -> YA when not yet recorded, so field Inspectors
 * focus on photo/video documentation and simply uncheck items with defects/shortages.
 */
function buildInitialDraftState(
  inspections: InspectionRow[],
  checklistSections: ChecklistSectionRow[],
  checklistItems: ChecklistItemRow[],
  draftContexts: DraftContextRow[]
) {
  const notesMap: Record<string, string> = {};
  const checklistMap: Record<string, Record<string, string>> = {};
  const specsMap: Record<string, Record<string, string>> = {};

  for (const ctx of draftContexts) {
    if (ctx.notes) notesMap[ctx.inspection_id] = ctx.notes;
    const cl: Record<string, string> = {};
    for (const [k, v] of Object.entries(ctx.draft_checklist ?? {})) {
      if (v !== null && v !== undefined) cl[k] = String(v);
    }
    checklistMap[ctx.inspection_id] = cl;

    const sp: Record<string, string> = {};
    for (const [k, v] of Object.entries(ctx.draft_specifications ?? {})) {
      if (v !== null && v !== undefined) sp[k] = String(v);
    }
    specsMap[ctx.inspection_id] = sp;
  }

  for (const insp of inspections) {
    const existingCl = { ...(checklistMap[insp.id] ?? {}) };
    const matchingSectionIds = new Set(
      checklistSections
        .filter((s) => s.instrument_version_id === insp.instrument_version_id)
        .map((s) => s.id)
    );
    for (const item of checklistItems) {
      if (!matchingSectionIds.has(item.section_id)) continue;
      if (existingCl[item.id] === undefined) {
        if (item.answer_type === "PASS_FAIL") existingCl[item.id] = "PASS";
        else if (item.answer_type === "YES_NO") existingCl[item.id] = "YA";
      }
    }
    checklistMap[insp.id] = existingCl;
  }

  return { notesMap, checklistMap, specsMap };
}

export function InspectionsPanel({
  inspections,
  activeClaims,
  revisions,
  abortRequests,
  evidenceAssets,
  evidenceSlots,
  documentTemplates,
  activeDevices,
  checklistSections,
  checklistItems,
  specFields,
  draftContexts,
  assignments,
  instruments,
  units
}: InspectionsPanelProps) {
  const initialDrafts = buildInitialDraftState(
    inspections,
    checklistSections,
    checklistItems,
    draftContexts
  );
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);
  const [reasons, setReasons] = useState<Record<string, string>>({});
  const [draftNotes, setDraftNotes] = useState<Record<string, string>>(initialDrafts.notesMap);
  const [defectNotes, setDefectNotes] = useState<Record<string, Record<string, string>>>({});
  const [checklistAnswers, setChecklistAnswers] = useState<Record<string, Record<string, string>>>(
    initialDrafts.checklistMap
  );
  const [specValues, setSpecValues] = useState<Record<string, Record<string, string>>>(
    initialDrafts.specsMap
  );
  const [selectedSlotByInsp, setSelectedSlotByInsp] = useState<Record<string, string>>({});
  const [selectedTemplateByInsp, setSelectedTemplateByInsp] = useState<Record<string, string>>({});
  const [scanAssignmentId, setScanAssignmentId] = useState(assignments[0]?.id ?? "");
  const [scanSerial, setScanSerial] = useState("");

  // T-09 Offline Queue state
  const [offlineOps, setOfflineOps] = useState<OfflineSyncOperation[]>([]);
  const [storedDevice, setStoredDevice] = useState<StoredDeviceBinding | null>(null);
  const [deviceLabel, setDeviceLabel] = useState("Perangkat Inspeksi Lapangan");

  useEffect(() => {
    let active = true;
    const savedDevice = loadStoredDeviceBinding();
    getDefaultOfflineQueueStore()
      .getAll()
      .then((ops) => {
        if (!active) return;
        setStoredDevice(savedDevice);
        setOfflineOps(ops);
      })
      .catch(() => {
        if (active) setStoredDevice(savedDevice);
      });
    return () => {
      active = false;
    };
  }, []);

  const latestRevisionByInspection = new Map<string, RevisionRow>();
  for (const rev of revisions) {
    const existing = latestRevisionByInspection.get(rev.inspection_id);
    if (!existing || rev.revision_no > existing.revision_no) {
      latestRevisionByInspection.set(rev.inspection_id, rev);
    }
  }

  const inspectionById = new Map(inspections.map((i) => [i.id, i]));
  const unitById = new Map(units.map((u) => [u.id, u]));
  const instrumentById = new Map(instruments.map((inst) => [inst.id, inst]));

  async function refreshOfflineQueue() {
    const ops = await getDefaultOfflineQueueStore().getAll();
    setOfflineOps(ops);
  }

  async function handleScanRegisterAndClaim(serialOverride?: string) {
    if (busyKey) return;
    const rawSn = (serialOverride ?? scanSerial).trim();
    const asgn = assignments.find((a) => a.id === scanAssignmentId);
    if (!asgn) {
      setFeedback({ kind: "err", text: "Pilih Penugasan Operasional (Assignment) terlebih dahulu." });
      return;
    }
    if (rawSn.length < 2) {
      setFeedback({ kind: "err", text: "Scan QR/Barcode atau ketik Nomor Seri (SN) unit minimal 2 karakter." });
      return;
    }

    setBusyKey("scan-claim");
    setFeedback(null);
    try {
      // 1. CMD-022: Register or resolve existing canonical unit in this project
      const regRes = await fetch("/api/v1/units/register", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          project_id: asgn.project_id,
          instrument_id: asgn.instrument_id,
          serial_raw: rawSn
        })
      });
      const regPayload = (await regRes.json().catch(() => null)) as
        | {
            status?: string;
            unit_id?: string;
            association_id?: string;
            serial_normalized?: string;
            error?: { message?: string };
          }
        | null;

      if (!regRes.ok || !regPayload?.unit_id || !regPayload.association_id) {
        setFeedback({
          kind: "err",
          text: `Registrasi SN gagal (${regPayload?.status ?? regRes.status}): ${
            regPayload?.error?.message ?? "Kemungkinan Nomor Seri terdaftar di proyek lain atau izin ditolak."
          }`
        });
        return;
      }

      // 2. CMD-026: Claim unit atomically into this assignment
      const claimRes = await fetch("/api/v1/claims", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          unit_id: regPayload.unit_id,
          association_id: regPayload.association_id,
          assignment_id: asgn.id,
          claim_ttl_minutes: 120
        })
      });
      const claimPayload = (await claimRes.json().catch(() => null)) as
        | { status?: string; inspection_id?: string; error?: { message?: string } }
        | null;

      if (!claimRes.ok) {
        setFeedback({
          kind: "err",
          text: `Klaim unit ${regPayload.serial_normalized ?? rawSn} ditolak (${claimPayload?.status ?? claimRes.status}): ${
            claimPayload?.error?.message ?? "Unit mungkin sedang diklaim Inspector lain atau sesi belum aktif."
          }`
        });
        return;
      }

      setScanSerial("");
      setFeedback({
        kind: "ok",
        text: `SN ${regPayload.serial_normalized ?? rawSn} diklaim (${claimPayload?.status ?? "CLAIMED"}). Checklist siap untuk dokumentasi!`
      });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus saat scan & klaim unit." });
    } finally {
      setBusyKey(null);
    }
  }

  async function callApi(
    key: string,
    url: string,
    body: Record<string, unknown>,
    successMsg: string
  ) {
    if (busyKey) return;
    setBusyKey(key);
    setFeedback(null);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify(body)
      });
      const payload = (await response.json().catch(() => null)) as
        | { status?: string; error?: { code?: string; message?: string }; document_id?: string }
        | null;

      if (!response.ok) {
        setFeedback({
          kind: "err",
          text: `Perintah ditolak (${payload?.status ?? payload?.error?.code ?? response.status}): ${
            payload?.error?.message ?? "Periksa klaim aktif, kelengkapan, atau hak akses."
          }`
        });
        return;
      }

      setFeedback({ kind: "ok", text: `${successMsg} (${payload?.status ?? "OK"}).` });
      router.refresh();
    } catch {
      setFeedback({
        kind: "err",
        text: "Koneksi server terputus. Gunakan antrean offline untuk menyimpan draft lokal."
      });
    } finally {
      setBusyKey(null);
    }
  }

  function buildDraftPayloads(inspectionId: string) {
    const draft_checklist: Record<string, unknown> = {};
    const insp = inspectionById.get(inspectionId);
    if (insp) {
      const secIds = new Set(
        checklistSections
          .filter((s) => s.instrument_version_id === insp.instrument_version_id)
          .map((s) => s.id)
      );
      for (const item of checklistItems) {
        if (!secIds.has(item.section_id)) continue;
        if (item.answer_type === "PASS_FAIL") {
          draft_checklist[item.id] = "PASS";
        } else if (item.answer_type === "YES_NO") {
          draft_checklist[item.id] = "YA";
        }
      }
    }

    const rawCl = checklistAnswers[inspectionId] ?? {};
    for (const [k, v] of Object.entries(rawCl)) {
      if (v.trim() !== "") draft_checklist[k] = v.trim();
    }
    const rawSp = specValues[inspectionId] ?? {};
    const draft_specifications: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(rawSp)) {
      if (v.trim() !== "") draft_specifications[k] = v.trim();
    }

    const defectEntries = Object.entries(defectNotes[inspectionId] ?? {})
      .filter(([, txt]) => txt.trim() !== "")
      .map(([itemId, txt]) => {
        const item = checklistItems.find((i) => i.id === itemId);
        return `${item ? item.code : itemId.slice(0, 6)}: ${txt.trim()}`;
      });
    const baseNote = (draftNotes[inspectionId] ?? "").trim();
    const combinedNote = [baseNote, defectEntries.length > 0 ? `[Kekurangan] ${defectEntries.join("; ")}` : ""]
      .filter(Boolean)
      .join(" | ")
      .slice(0, 2000);

    return { draft_checklist, draft_specifications, combinedNote };
  }

  async function handleEnqueueOfflineDraft(insp: InspectionRow) {
    if (busyKey) return;
    setBusyKey(`off-${insp.id}`);
    setFeedback(null);
    try {
      const { draft_checklist, draft_specifications, combinedNote } = buildDraftPayloads(insp.id);
      const op = await enqueueDraftOperation({
        inspection_id: insp.id,
        expected_row_version: insp.row_version,
        draft_checklist,
        draft_specifications,
        notes: combinedNote || "Draft offline tersimpan lokal"
      });
      await refreshOfflineQueue();
      setFeedback({
        kind: "ok",
        text: `Draft masuk antrean offline IndexedDB (${op.operation_id.slice(0, 12)}…, v${insp.row_version}).`
      });
    } catch (err) {
      setFeedback({
        kind: "err",
        text: err instanceof Error ? err.message : "Gagal menyimpan draft ke antrean offline."
      });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleRegisterDevice() {
    if (busyKey) return;
    setBusyKey("reg-device");
    setFeedback(null);
    try {
      const ua = typeof navigator !== "undefined" ? navigator.userAgent : "unknown-browser";
      const fingerprintHash = await sha256Hex(`${ua}|${crypto.randomUUID()}`);
      const trimmedLabel = deviceLabel.trim() || "Perangkat Inspeksi";

      const response = await fetch("/api/v1/sync/devices", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          device_fingerprint_hash: fingerprintHash,
          label: trimmedLabel
        })
      });
      const payload = (await response.json().catch(() => null)) as
        | { status?: string; device_id?: string; error?: { message?: string } }
        | null;

      if (!response.ok || !payload?.device_id) {
        setFeedback({
          kind: "err",
          text: `Registrasi perangkat gagal (${payload?.status ?? response.status}): ${
            payload?.error?.message ?? "Periksa status akun dan izin sinkronisasi."
          }`
        });
        return;
      }

      const binding: StoredDeviceBinding = {
        device_id: payload.device_id,
        label: trimmedLabel,
        fingerprint_hash: fingerprintHash,
        registered_at: new Date().toISOString()
      };
      saveStoredDeviceBinding(binding);
      setStoredDevice(binding);
      setFeedback({ kind: "ok", text: `Perangkat terdaftar untuk sinkronisasi offline (${binding.device_id.slice(0, 8)}…).` });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Gagal menghubungi server saat mendaftarkan perangkat." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleSyncOfflineBatch() {
    if (busyKey) return;
    const activeDeviceId = storedDevice?.device_id ?? activeDevices[0]?.id ?? null;
    if (!activeDeviceId) {
      setFeedback({
        kind: "err",
        text: "Daftarkan perangkat terlebih dahulu sebelum menjalankan sinkronisasi antrean offline."
      });
      return;
    }

    const pendingOps = offlineOps.filter((op) => op.status === "PENDING");
    if (pendingOps.length === 0) {
      setFeedback({ kind: "ok", text: "Tidak ada operasi PENDING di antrean offline." });
      return;
    }

    setBusyKey("sync-batch");
    setFeedback(null);
    try {
      const response = await fetch("/api/v1/sync/batch", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          device_id: activeDeviceId,
          batch_key: `batch-${crypto.randomUUID()}`,
          operations: pendingOps.map((op) => ({
            operation_id: op.operation_id,
            op_type: op.op_type,
            inspection_id: op.inspection_id,
            expected_row_version: op.expected_row_version,
            payload: op.payload
          }))
        })
      });

      const payload = (await response.json().catch(() => null)) as
        | {
            status?: string;
            results?: SyncServerOpResult[];
            operations?: SyncServerOpResult[];
            error?: { message?: string };
          }
        | null;

      if (!response.ok) {
        setFeedback({
          kind: "err",
          text: `Sinkronisasi batch ditolak (${payload?.status ?? response.status}): ${
            payload?.error?.message ?? "Periksa perangkat aktif atau status koneksi."
          }`
        });
        return;
      }

      const opResults = payload?.results ?? payload?.operations ?? [];
      const updated = await reconcileSyncResults(opResults);
      setOfflineOps(updated);
      const appliedCount = updated.filter((o) => o.status === "APPLIED").length;
      const conflictCount = updated.filter((o) => o.status === "CONFLICT").length;
      setFeedback({
        kind: conflictCount > 0 ? "err" : "ok",
        text: `Batch selesai (${payload?.status ?? "OK"}): ${appliedCount} APPLIED, ${conflictCount} CONFLICT (tidak menimpa otomatis).`
      });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat sinkronisasi. Antrean lokal tetap aman." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleUploadEvidence(insp: InspectionRow, file: File | null) {
    if (!file || busyKey) return;
    const matchingSlots = evidenceSlots.filter((s) => s.instrument_version_id === insp.instrument_version_id);
    const slotId = selectedSlotByInsp[insp.id] ?? matchingSlots[0]?.id;
    if (!slotId) {
      setFeedback({ kind: "err", text: "Slot bukti instrumen tidak ditemukan untuk inspeksi ini." });
      return;
    }
    if (!ALLOWED_MIME_SET.has(file.type)) {
      setFeedback({
        kind: "err",
        text: `Tipe file ${file.type || "tidak dikenal"} ditolak. Gunakan JPEG/PNG/WebP/PDF/MP4/WebM.`
      });
      return;
    }
    if (file.size < 1 || file.size > MAX_EVIDENCE_BYTES) {
      setFeedback({ kind: "err", text: "Ukuran file harus antara 1 byte dan 25 MiB." });
      return;
    }

    setBusyKey(`ev-${insp.id}`);
    setFeedback(null);
    try {
      const arrayBuf = await file.arrayBuffer();
      const digest = await sha256Hex(arrayBuf);
      const clientFileId = `web-${crypto.randomUUID()}`;

      // 1. CMD-033: create-upload-intent -> returns signed_upload_url
      const intentRes = await fetch("/api/v1/evidence/intent", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          inspection_id: insp.id,
          slot_definition_id: slotId,
          mime_type: file.type,
          byte_size: file.size,
          sha256: digest,
          client_file_id: clientFileId
        })
      });
      const intentPayload = (await intentRes.json().catch(() => null)) as
        | {
            status?: string;
            evidence_asset_id?: string;
            signed_upload_url?: string | null;
            error?: { message?: string };
          }
        | null;

      if (!intentRes.ok || !intentPayload?.evidence_asset_id || !intentPayload.signed_upload_url) {
        setFeedback({
          kind: "err",
          text: `Intent upload ditolak (${intentPayload?.status ?? intentRes.status}): ${
            intentPayload?.error?.message ?? "Pastikan klaim aktif & bucket private tersedia."
          }`
        });
        return;
      }

      // 2. Upload binary directly to private Storage via signed URL
      const uploadRes = await fetch(intentPayload.signed_upload_url, {
        method: "PUT",
        headers: { "content-type": file.type },
        body: file
      });
      if (!uploadRes.ok) {
        setFeedback({
          kind: "err",
          text: `Unggah biner ke Private Storage gagal (HTTP ${uploadRes.status}).`
        });
        return;
      }

      // 3. CMD-034: server-side SHA-256 + magic-byte verification & confirm
      const confirmRes = await fetch("/api/v1/evidence/confirm", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          evidence_asset_id: intentPayload.evidence_asset_id
        })
      });
      const confirmPayload = (await confirmRes.json().catch(() => null)) as
        | { status?: string; error?: { code?: string; message?: string } }
        | null;

      if (!confirmRes.ok) {
        setFeedback({
          kind: "err",
          text: `Verifikasi biner server gagal (${confirmPayload?.error?.code ?? confirmPayload?.status ?? confirmRes.status}): ${
            confirmPayload?.error?.message ?? "Magic-byte / SHA-256 tidak cocok."
          }`
        });
        return;
      }

      setFeedback({
        kind: "ok",
        text: `Bukti berhasil diunggah & terverifikasi (${confirmPayload?.status ?? "FINALIZED"}).`
      });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat mengunggah bukti." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleAuditedDownloadEvidence(assetId: string) {
    if (busyKey) return;
    setBusyKey(`dl-${assetId}`);
    setFeedback(null);
    try {
      const res = await fetch(`/api/v1/evidence/${assetId}/download`, { method: "GET" });
      const payload = (await res.json().catch(() => null)) as
        | { signed_download_url?: string; status?: string; error?: { message?: string } }
        | null;
      if (!res.ok || !payload?.signed_download_url) {
        setFeedback({
          kind: "err",
          text: `Akses unduh ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Tidak berwenang."}`
        });
        return;
      }
      window.open(payload.signed_download_url, "_blank", "noopener,noreferrer");
      setFeedback({ kind: "ok", text: "Tautan unduh bukti aman (berlaku 60 detik) berhasil dibuat." });
    } catch {
      setFeedback({ kind: "err", text: "Gagal mengambil tautan unduh bukti." });
    } finally {
      setBusyKey(null);
    }
  }

  const effectiveDeviceId = storedDevice?.device_id ?? activeDevices[0]?.id ?? null;

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

      <section className="admin-panel" aria-labelledby="scanner-heading">
        <div className="admin-item-header">
          <h2 id="scanner-heading">Scan QR / Input Serial Number → Klaim Unit</h2>
          <span className="status-badge status-badge-approved">SCAN KAMERA / OCR</span>
        </div>
        <p className="rbac-meta">
          Arahkan kamera HP ke QR/Barcode unit, gunakan baca teks OCR, atau ketik manual SN. Jika unit belum diklaim,
          sistem otomatis mengklaim unit atas nama Anda dan membuka formulir pemeriksaan siap dokumentasi.
        </p>
        {assignments.length === 0 ? (
          <p className="rbac-meta">
            Belum ada Penugasan Operasional (Assignment) aktif. Minta Super Admin / Korlap membuat Assignment di /workspace.
          </p>
        ) : (
          <div className="rbac-form">
            <div className="admin-inline">
              <select
                aria-label="Pilih Assignment"
                className="inline-input"
                value={scanAssignmentId}
                onChange={(e) => setScanAssignmentId(e.target.value)}
              >
                {assignments.map((a) => {
                  const inst = instrumentById.get(a.instrument_id);
                  return (
                    <option key={a.id} value={a.id}>
                      {inst?.code ?? "INST"} · Asgn {a.id.slice(0, 8)}… ({a.status})
                    </option>
                  );
                })}
              </select>
              <input
                aria-label="Serial Number unit"
                className="inline-input"
                type="text"
                value={scanSerial}
                onChange={(e) => setScanSerial(e.target.value)}
                placeholder="Scan atau ketik SN unit (mis. 3TB75B...)"
              />
              <button
                type="button"
                className="auth-button admin-btn-sm"
                disabled={busyKey !== null || scanSerial.trim().length < 2}
                onClick={() => void handleScanRegisterAndClaim()}
              >
                Cek SN &amp; Klaim Unit
              </button>
            </div>
            <SerialScanner
              onDetected={(detectedSn, source) => {
                setScanSerial(detectedSn);
                if (source === "barcode") {
                  void handleScanRegisterAndClaim(detectedSn);
                } else {
                  setFeedback({
                    kind: "ok",
                    text: `OCR membaca SN "${detectedSn}". Periksa kesesuaian SN di kotak input lalu tekan Cek SN & Klaim Unit.`
                  });
                }
              }}
            />
          </div>
        )}
      </section>

      <section className="admin-panel" aria-labelledby="offline-queue-heading">
        <div className="admin-item-header">
          <h2 id="offline-queue-heading">Antrean Offline &amp; Sinkronisasi ({offlineOps.length}/50)</h2>
          <span className={`status-badge ${effectiveDeviceId ? "status-badge-approved" : "status-badge-pending"}`}>
            {effectiveDeviceId ? `PERANGKAT ${effectiveDeviceId.slice(0, 8)}…` : "PERANGKAT BELUM TERDAFTAR"}
          </span>
        </div>
        <p className="rbac-meta">
          Perubahan draft offline disimpan di perangkat (maksimum 50 antrean). Jika terjadi konflik versi
          di server, Anda dapat meninjau dan menyelaraskan ulang sebelum sinkronisasi.
        </p>

        <div className="admin-inline">
          <input
            aria-label="Label perangkat inspeksi"
            className="inline-input"
            type="text"
            value={deviceLabel}
            onChange={(e) => setDeviceLabel(e.target.value)}
            placeholder="Label perangkat lapangan"
          />
          <button
            type="button"
            className="auth-button auth-button-secondary admin-btn-sm"
            disabled={busyKey !== null}
            onClick={handleRegisterDevice}
          >
            Daftarkan Perangkat
          </button>
          <button
            type="button"
            className="auth-button admin-btn-sm"
            disabled={busyKey !== null || offlineOps.filter((o) => o.status === "PENDING").length === 0}
            onClick={handleSyncOfflineBatch}
          >
            Sinkronkan Antrean
          </button>
          <button
            type="button"
            className="auth-button auth-button-secondary admin-btn-sm"
            disabled={busyKey !== null}
            onClick={async () => {
              await purgeOfflineLocalState();
              setStoredDevice(null);
              setOfflineOps([]);
              setFeedback({ kind: "ok", text: "Cache offline & ikatan perangkat lokal dibersihkan." });
            }}
          >
            Bersihkan Cache Lokal
          </button>
        </div>

        {offlineOps.length > 0 ? (
          <div className="admin-list">
            {offlineOps.map((op) => {
              const liveInsp = inspectionById.get(op.inspection_id);
              return (
                <article key={op.operation_id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {op.op_type} · Inspeksi {op.inspection_id.slice(0, 8)}… (target v{op.expected_row_version})
                    </strong>
                    <span
                      className={`status-badge ${
                        op.status === "APPLIED"
                          ? "status-badge-approved"
                          : op.status === "PENDING"
                            ? "status-badge-pending"
                            : "status-badge-rejected"
                      }`}
                    >
                      {op.status}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    Catatan: {op.payload.notes ?? "-"} · Diantrekan: {new Date(op.queued_at).toLocaleString("id-ID")}
                    {op.last_error ? ` · Server: ${op.last_error}` : ""}
                  </p>
                  <div className="admin-inline">
                    {op.status === "CONFLICT" && liveInsp ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={async () => {
                          await rebaseConflictOperation(op.operation_id, liveInsp.row_version);
                          await refreshOfflineQueue();
                          setFeedback({
                            kind: "ok",
                            text: `Konflik di-rebase ke versi terbaru server v${liveInsp.row_version}. Siap disinkronkan ulang.`
                          });
                        }}
                      >
                        Rebase ke v{liveInsp.row_version}
                      </button>
                    ) : null}
                    <button
                      type="button"
                      className="auth-button auth-button-secondary admin-btn-sm"
                      disabled={busyKey !== null}
                      onClick={async () => {
                        await getDefaultOfflineQueueStore().delete(op.operation_id);
                        await refreshOfflineQueue();
                      }}
                    >
                      Hapus dari Antrean
                    </button>
                  </div>
                </article>
              );
            })}
          </div>
        ) : null}
      </section>

      <section className="admin-panel" aria-labelledby="inspections-list-heading">
        <h2 id="inspections-list-heading">Daftar Inspeksi Unit ({inspections.length})</h2>
        {inspections.length === 0 ? (
          <p className="rbac-meta">
            Belum ada inspeksi aktif. Scan QR/Barcode atau masukkan Nomor Seri unit di atas untuk memulai pemeriksaan.
          </p>
        ) : (
          <div className="admin-list">
            {inspections.map((insp) => {
              const latestRev = latestRevisionByInspection.get(insp.id);
              const reason = (reasons[insp.id] ?? "").trim();
              const note = (draftNotes[insp.id] ?? "").trim();
              const inspAssets = evidenceAssets.filter((a) => a.inspection_id === insp.id);
              const matchingSlots = evidenceSlots.filter((s) => s.instrument_version_id === insp.instrument_version_id);
              const activeTemplates = documentTemplates.filter(
                (t) => t.document_type === "INSPECTION_PDF" || t.document_type === "BA_PDF"
              );
              const editable =
                insp.status === "DRAFT" || insp.status === "RETURNED" || insp.status === "REOPENED";

              const matchingSections = checklistSections.filter(
                (s) => s.instrument_version_id === insp.instrument_version_id
              );
              const matchingSpecs = specFields.filter(
                (f) => f.instrument_version_id === insp.instrument_version_id
              );
              const unitRow = unitById.get(insp.unit_id);
              const unitDisplay = unitRow?.serial_normalized ?? unitRow?.serial_raw ?? insp.unit_id.slice(0, 8);

              return (
                <article key={insp.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {unitRow?.instrument_type ?? "UNIT"} · SN {unitDisplay} · Inspeksi {insp.id.slice(0, 8)}…
                    </strong>
                    <span className="status-badge">
                      {insp.status} · rev {insp.current_revision_no} · v{insp.row_version}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    Diperbarui: {new Date(insp.updated_at).toLocaleString("id-ID")} · Bukti: {inspAssets.length}
                  </p>

                  {editable ? (
                    <div className="rbac-card">
                      {matchingSections.map((sec) => {
                        const secItems = checklistItems.filter((it) => it.section_id === sec.id);
                        return (
                          <div key={sec.id} className="checklist-group">
                            <p className="rbac-meta">
                              <strong>
                                {sec.code} — {sec.label}
                              </strong>{" "}
                              (tercentang baik; hilangkan centang bila ada kekurangan)
                            </p>
                            {secItems.map((item) => {
                              const isBoolLike = item.answer_type === "PASS_FAIL" || item.answer_type === "YES_NO";
                              const okValue = item.answer_type === "YES_NO" ? "YA" : "PASS";
                              const failValue = item.answer_type === "YES_NO" ? "TIDAK" : "FAIL";
                              const currentVal = checklistAnswers[insp.id]?.[item.id] ?? (isBoolLike ? okValue : "");
                              const isChecked = isBoolLike && currentVal !== failValue;

                              return (
                                <div key={item.id} className="admin-list">
                                  <div className="checklist-row">
                                    <label htmlFor={`ci-${insp.id}-${item.id}`} className="rbac-meta">
                                      {item.label} {item.required ? "*" : ""}
                                    </label>
                                    {isBoolLike ? (
                                      <label className="admin-inline rbac-meta" style={{ cursor: "pointer" }}>
                                        <input
                                          id={`ci-${insp.id}-${item.id}`}
                                          type="checkbox"
                                          checked={isChecked}
                                          onChange={(e) => {
                                            const nextVal = e.target.checked ? okValue : failValue;
                                            setChecklistAnswers((prev) => ({
                                              ...prev,
                                              [insp.id]: {
                                                ...(prev[insp.id] ?? {}),
                                                [item.id]: nextVal
                                              }
                                            }));
                                          }}
                                        />
                                        <span>{isChecked ? `${okValue} (Baik)` : `${failValue} (Ada Kekurangan)`}</span>
                                      </label>
                                    ) : (
                                      <input
                                        id={`ci-${insp.id}-${item.id}`}
                                        className="inline-input"
                                        type={item.answer_type === "NUMBER" ? "number" : "text"}
                                        value={currentVal}
                                        onChange={(e) =>
                                          setChecklistAnswers((prev) => ({
                                            ...prev,
                                            [insp.id]: {
                                              ...(prev[insp.id] ?? {}),
                                              [item.id]: e.target.value
                                            }
                                          }))
                                        }
                                        placeholder="Isi jawaban"
                                      />
                                    )}
                                  </div>
                                  {isBoolLike && !isChecked ? (
                                    <input
                                      aria-label={`Keterangan kekurangan ${item.label}`}
                                      className="inline-input"
                                      type="text"
                                      value={defectNotes[insp.id]?.[item.id] ?? ""}
                                      onChange={(e) =>
                                        setDefectNotes((prev) => ({
                                          ...prev,
                                          [insp.id]: {
                                            ...(prev[insp.id] ?? {}),
                                            [item.id]: e.target.value
                                          }
                                        }))
                                      }
                                      placeholder="Wajib isi keterangan kekurangan & unggah bukti foto/video di bawah"
                                    />
                                  ) : null}
                                </div>
                              );
                            })}
                          </div>
                        );
                      })}

                      {matchingSpecs.length > 0 ? (
                        <div className="checklist-group">
                          <p className="rbac-meta">
                            <strong>Spesifikasi Teknis</strong>
                          </p>
                          {matchingSpecs.map((sp) => (
                            <div key={sp.id} className="checklist-row">
                              <label htmlFor={`sp-${insp.id}-${sp.id}`} className="rbac-meta">
                                {sp.label}
                                {sp.unit ? ` (${sp.unit})` : ""}
                                {sp.expected_value ? ` · standar: ${sp.expected_value}` : ""}
                              </label>
                              <input
                                id={`sp-${insp.id}-${sp.id}`}
                                className="inline-input"
                                type="text"
                                value={specValues[insp.id]?.[sp.id] ?? ""}
                                onChange={(e) =>
                                  setSpecValues((prev) => ({
                                    ...prev,
                                    [insp.id]: {
                                      ...(prev[insp.id] ?? {}),
                                      [sp.id]: e.target.value
                                    }
                                  }))
                                }
                                placeholder={sp.expected_value ?? "Nilai aktual"}
                              />
                            </div>
                          ))}
                        </div>
                      ) : null}

                      <div className="rbac-field">
                        <label htmlFor={`draft-${insp.id}`}>Catatan Draft Inspeksi</label>
                        <input
                          id={`draft-${insp.id}`}
                          type="text"
                          value={draftNotes[insp.id] ?? ""}
                          onChange={(e) =>
                            setDraftNotes((prev) => ({ ...prev, [insp.id]: e.target.value }))
                          }
                          placeholder="Hasil pemeriksaan fisik unit"
                        />
                      </div>
                      <div className="admin-inline">
                        <button
                          type="button"
                          className="auth-button admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => {
                            const { draft_checklist, draft_specifications, combinedNote } = buildDraftPayloads(insp.id);
                            void callApi(
                              `draft-${insp.id}`,
                              "/api/v1/inspections/draft",
                              {
                                inspection_id: insp.id,
                                expected_row_version: insp.row_version,
                                draft_checklist,
                                draft_specifications,
                                notes: combinedNote || note || "Draft diperbarui dari UI"
                              },
                              "Draft inspeksi tersimpan di server"
                            );
                          }}
                        >
                          Simpan Draft Online
                        </button>
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleEnqueueOfflineDraft(insp)}
                        >
                          Simpan ke Antrean Offline
                        </button>
                      </div>

                      {matchingSlots.length > 0 ? (
                        <div className="admin-inline">
                          <select
                            aria-label={`Slot bukti ${insp.id}`}
                            className="inline-input"
                            value={selectedSlotByInsp[insp.id] ?? matchingSlots[0].id}
                            onChange={(e) =>
                              setSelectedSlotByInsp((prev) => ({ ...prev, [insp.id]: e.target.value }))
                            }
                          >
                            {matchingSlots.map((slot) => (
                              <option key={slot.id} value={slot.id}>
                                {slot.code} — {slot.label}
                              </option>
                            ))}
                          </select>
                          <label className="auth-button auth-button-secondary admin-btn-sm file-upload-label">
                            Unggah Bukti Foto / Video (maks. 25 MiB)
                            <input
                              type="file"
                              accept="image/jpeg,image/png,image/webp,video/mp4,video/webm,application/pdf"
                              disabled={busyKey !== null}
                              style={{ display: "none" }}
                              onChange={(e) => {
                                const file = e.target.files?.[0] ?? null;
                                void handleUploadEvidence(insp, file);
                                e.currentTarget.value = "";
                              }}
                            />
                          </label>
                        </div>
                      ) : null}
                    </div>
                  ) : null}

                  {inspAssets.length > 0 ? (
                    <div className="admin-inline">
                      {inspAssets.map((asset) => (
                        <button
                          key={asset.id}
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null || asset.upload_status !== "FINALIZED"}
                          onClick={() => handleAuditedDownloadEvidence(asset.id)}
                        >
                          Unduh Bukti {asset.id.slice(0, 6)} ({asset.upload_status} · {asset.observed_byte_size ?? asset.expected_byte_size}B)
                        </button>
                      ))}
                    </div>
                  ) : null}

                  <div className="rbac-field">
                    <label htmlFor={`reason-${insp.id}`}>Alasan aksi (return / reopen / abort)</label>
                    <input
                      id={`reason-${insp.id}`}
                      type="text"
                      value={reasons[insp.id] ?? ""}
                      onChange={(e) =>
                        setReasons((prev) => ({ ...prev, [insp.id]: e.target.value }))
                      }
                      placeholder="Catatan verifikasi atau alasan pengembalian/pembukaan ulang"
                    />
                  </div>

                  <div className="admin-inline">
                    {editable ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() => {
                          const sectionIds = new Set(matchingSections.map((sec) => sec.id));
                          const missingDefectCodes = checklistItems
                            .filter((item) => sectionIds.has(item.section_id))
                            .filter((item) => {
                              const val = checklistAnswers[insp.id]?.[item.id];
                              if (val !== "FAIL" && val !== "TIDAK") return false;
                              return !(defectNotes[insp.id]?.[item.id] ?? "").trim();
                            })
                            .map((item) => item.code);

                          if (missingDefectCodes.length > 0) {
                            setFeedback({
                              kind: "err",
                              text: `Item kekurangan (${missingDefectCodes.join(", ")}) wajib diisi keterangan kekurangannya sebelum Submit.`
                            });
                            return;
                          }

                          void callApi(
                            `sub-${insp.id}`,
                            "/api/v1/inspections/submit",
                            {
                              inspection_id: insp.id,
                              expected_row_version: insp.row_version,
                              submit_reason: reason || null
                            },
                            "Inspeksi berhasil disubmit (revisi baru dibuat)"
                          );
                        }}
                      >
                        Kirim untuk Review
                      </button>
                    ) : null}
                    {insp.status === "SUBMITTED" && latestRev ? (
                      <>
                        <button
                          type="button"
                          className="auth-button admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() =>
                            callApi(
                              `app-${insp.id}`,
                              "/api/v1/inspections/approve",
                              {
                                inspection_id: insp.id,
                                revision_id: latestRev.id,
                                expected_revision_no: latestRev.revision_no,
                                reason: reason || null
                              },
                              "Revisi inspeksi disetujui"
                            )
                          }
                        >
                          Setujui Hasil
                        </button>
                        <button
                          type="button"
                          className="auth-button admin-btn-sm admin-btn-danger"
                          disabled={busyKey !== null}
                          onClick={() =>
                            callApi(
                              `ret-${insp.id}`,
                              "/api/v1/inspections/return",
                              {
                                inspection_id: insp.id,
                                revision_id: latestRev.id,
                                expected_revision_no: latestRev.revision_no,
                                reason
                              },
                              "Inspeksi dikembalikan untuk perbaikan"
                            )
                          }
                        >
                          Kembalikan untuk Perbaikan
                        </button>
                      </>
                    ) : null}
                    {insp.status === "APPROVED" && latestRev ? (
                      <>
                        {activeTemplates.length > 0 ? (
                          <>
                            <select
                              aria-label={`Template PDF ${insp.id}`}
                              className="inline-input"
                              value={selectedTemplateByInsp[insp.id] ?? activeTemplates[0].id}
                              onChange={(e) =>
                                setSelectedTemplateByInsp((prev) => ({ ...prev, [insp.id]: e.target.value }))
                              }
                            >
                              {activeTemplates.map((t) => (
                                <option key={t.id} value={t.id}>
                                  {t.document_type} · {t.template_key} v{t.version_no}
                                </option>
                              ))}
                            </select>
                            <button
                              type="button"
                              className="auth-button admin-btn-sm"
                              disabled={busyKey !== null}
                              onClick={() => {
                                const tmplId = selectedTemplateByInsp[insp.id] ?? activeTemplates[0].id;
                                const tmpl = activeTemplates.find((t) => t.id === tmplId) ?? activeTemplates[0];
                                void callApi(
                                  `pdf-${insp.id}`,
                                  "/api/v1/documents/generate",
                                  {
                                    document_type: tmpl.document_type,
                                    inspection_id: insp.id,
                                    approved_revision_id: latestRev.id,
                                    template_version_id: tmpl.id
                                  },
                                  "Dokumen PDF berhasil dibuat & disimpan"
                                );
                              }}
                            >
                              Buat Dokumen PDF
                            </button>
                          </>
                        ) : null}
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() =>
                            callApi(
                              `reo-${insp.id}`,
                              "/api/v1/inspections/reopen",
                              {
                                inspection_id: insp.id,
                                approved_revision_id: latestRev.id,
                                expected_row_version: insp.row_version,
                                reason
                              },
                              "Inspeksi dibuka ulang (klaim eksplisit diperlukan)"
                            )
                          }
                        >
                          Buka Ulang
                        </button>
                      </>
                    ) : null}
                    {insp.status === "RETURNED" ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm admin-btn-danger"
                        disabled={busyKey !== null}
                        onClick={() =>
                          callApi(
                            `abr-${insp.id}`,
                            "/api/v1/inspections/abort/request",
                            { inspection_id: insp.id, reason },
                            "Permintaan pembatalan unit terkemas diajukan"
                          )
                        }
                      >
                        Ajukan Pembatalan Unit
                      </button>
                    ) : null}
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </section>

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="claims-heading">
          <h2 id="claims-heading">Klaim Unit Aktif ({activeClaims.length})</h2>
          {activeClaims.length === 0 ? (
            <p className="rbac-meta">Tidak ada klaim unit aktif saat ini.</p>
          ) : (
            <div className="admin-list">
              {activeClaims.map((claim) => (
                <article key={claim.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>Unit {claim.unit_id.slice(0, 8)}…</strong>
                    <span className="status-badge status-badge-approved">
                      ACTIVE · v{claim.row_version}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    Kedaluwarsa: {new Date(claim.expires_at).toLocaleString("id-ID")}
                  </p>
                  <button
                    type="button"
                    className="auth-button auth-button-secondary admin-btn-sm"
                    disabled={busyKey !== null}
                    onClick={() =>
                      callApi(
                        `rel-${claim.id}`,
                        "/api/v1/claims/release",
                        {
                          claim_id: claim.id,
                          expected_row_version: claim.row_version,
                          reason: "Pelepasan klaim manual oleh pengguna"
                        },
                        "Klaim unit dilepas (draft & bukti tetap tersimpan)"
                      )
                    }
                  >
                    Lepas Klaim
                  </button>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="admin-panel" aria-labelledby="aborts-heading">
          <h2 id="aborts-heading">Permintaan Pembatalan Unit ({abortRequests.length})</h2>
          {abortRequests.length === 0 ? (
            <p className="rbac-meta">Tidak ada permintaan pembatalan unit terkemas.</p>
          ) : (
            <div className="admin-list">
              {abortRequests.map((req) => (
                <article key={req.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>Inspeksi {req.inspection_id.slice(0, 8)}…</strong>
                    <span className="status-badge status-badge-pending">
                      {req.status} · v{req.row_version}
                    </span>
                  </div>
                  <p className="rbac-meta">{req.request_reason}</p>
                  {req.status === "PENDING" ? (
                    <div className="admin-inline">
                      <button
                        type="button"
                        className="auth-button admin-btn-sm admin-btn-danger"
                        disabled={busyKey !== null}
                        onClick={() =>
                          callApi(
                            `ab-app-${req.id}`,
                            "/api/v1/inspections/abort/decide",
                            {
                              abort_request_id: req.id,
                              decision: "APPROVE",
                              expected_row_version: req.row_version,
                              reason: "Disetujui sesuai kondisi unit terkemas"
                            },
                            "Pembatalan unit disetujui"
                          )
                        }
                      >
                        Setujui Abort
                      </button>
                      <button
                        type="button"
                        className="auth-button auth-button-secondary admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() =>
                          callApi(
                            `ab-rej-${req.id}`,
                            "/api/v1/inspections/abort/decide",
                            {
                              abort_request_id: req.id,
                              decision: "REJECT",
                              expected_row_version: req.row_version,
                              reason: "Unit masih dapat diperiksa ulang"
                            },
                            "Permintaan abort ditolak"
                          )
                        }
                      >
                        Tolak
                      </button>
                    </div>
                  ) : null}
                </article>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
