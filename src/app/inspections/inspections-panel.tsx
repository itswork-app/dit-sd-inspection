"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
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
};

const ALLOWED_MIME_SET = new Set(["image/jpeg", "image/png", "image/webp", "application/pdf"]);

function buildInitialDraftState(draftContexts: DraftContextRow[]) {
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
  draftContexts
}: InspectionsPanelProps) {
  const initialDrafts = buildInitialDraftState(draftContexts);
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);
  const [reasons, setReasons] = useState<Record<string, string>>({});
  const [draftNotes, setDraftNotes] = useState<Record<string, string>>(initialDrafts.notesMap);
  const [checklistAnswers, setChecklistAnswers] = useState<Record<string, Record<string, string>>>(
    initialDrafts.checklistMap
  );
  const [specValues, setSpecValues] = useState<Record<string, Record<string, string>>>(
    initialDrafts.specsMap
  );
  const [selectedSlotByInsp, setSelectedSlotByInsp] = useState<Record<string, string>>({});
  const [selectedTemplateByInsp, setSelectedTemplateByInsp] = useState<Record<string, string>>({});

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

  async function refreshOfflineQueue() {
    const ops = await getDefaultOfflineQueueStore().getAll();
    setOfflineOps(ops);
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
            payload?.error?.message ?? "Periksa klaim aktif, kelengkapan, izin, atau SoD."
          }`
        });
        return;
      }

      setFeedback({ kind: "ok", text: `${successMsg} (${payload?.status ?? "OK"}).` });
      router.refresh();
    } catch {
      setFeedback({
        kind: "err",
        text: "Koneksi server terputus. Gunakan antrean offline T-09 untuk menyimpan draft lokal."
      });
    } finally {
      setBusyKey(null);
    }
  }

  function buildDraftPayloads(inspectionId: string) {
    const rawCl = checklistAnswers[inspectionId] ?? {};
    const draft_checklist: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(rawCl)) {
      if (v.trim() !== "") draft_checklist[k] = v.trim();
    }
    const rawSp = specValues[inspectionId] ?? {};
    const draft_specifications: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(rawSp)) {
      if (v.trim() !== "") draft_specifications[k] = v.trim();
    }
    return { draft_checklist, draft_specifications };
  }

  async function handleEnqueueOfflineDraft(insp: InspectionRow) {
    if (busyKey) return;
    setBusyKey(`off-${insp.id}`);
    setFeedback(null);
    try {
      const note = (draftNotes[insp.id] ?? "").trim();
      const { draft_checklist, draft_specifications } = buildDraftPayloads(insp.id);
      const op = await enqueueDraftOperation({
        inspection_id: insp.id,
        expected_row_version: insp.row_version,
        draft_checklist,
        draft_specifications,
        notes: note || "Draft offline tersimpan lokal"
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
      setFeedback({ kind: "ok", text: `Perangkat terdaftar untuk T-09 sync (${binding.device_id.slice(0, 8)}…).` });
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
        text: "Daftarkan perangkat terlebih dahulu sebelum menjalankan sinkronisasi batch T-09."
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
      setFeedback({ kind: "err", text: `Tipe file ${file.type || "tidak dikenal"} ditolak. Gunakan JPEG/PNG/WebP/PDF.` });
      return;
    }
    if (file.size < 1 || file.size > 15728640) {
      setFeedback({ kind: "err", text: "Ukuran file harus antara 1 byte dan 15 MiB." });
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
          evidence_asset_id: intentPayload.evidence_asset_id,
          observed_sha256: digest,
          observed_byte_size: file.size,
          observed_mime: file.type
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
        text: `Bukti terunggah & terverifikasi SHA-256/magic-byte (${confirmPayload?.status ?? "FINALIZED"}).`
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
      setFeedback({ kind: "ok", text: "Signed URL bukti 60 detik diterbitkan & diaudit (evidence.accessed)." });
    } catch {
      setFeedback({ kind: "err", text: "Gagal mengambil signed download URL." });
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

      <section className="admin-panel" aria-labelledby="offline-queue-heading">
        <div className="admin-item-header">
          <h2 id="offline-queue-heading">Antrean Offline &amp; Sinkronisasi T-09 ({offlineOps.length}/50)</h2>
          <span className={`status-badge ${effectiveDeviceId ? "status-badge-approved" : "status-badge-pending"}`}>
            {effectiveDeviceId ? `DEVICE ${effectiveDeviceId.slice(0, 8)}…` : "PERANGKAT BELUM TERDAFTAR"}
          </span>
        </div>
        <p className="rbac-meta">
          Perubahan draft offline disimpan terikat batas maksimum 50 operasi di IndexedDB browser. Konflik versi
          (`CONFLICT`) tidak pernah menimpa server secara diam-diam — pengguna harus memilih rebase eksplisit atau membuang draft lokal.
        </p>

        <div className="admin-inline">
          <input
            aria-label="Label perangkat T-09"
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
            Daftarkan Perangkat (T-09)
          </button>
          <button
            type="button"
            className="auth-button admin-btn-sm"
            disabled={busyKey !== null || offlineOps.filter((o) => o.status === "PENDING").length === 0}
            onClick={handleSyncOfflineBatch}
          >
            Sinkronkan Batch (CMD-035)
          </button>
          <button
            type="button"
            className="auth-button auth-button-secondary admin-btn-sm"
            disabled={busyKey !== null}
            onClick={async () => {
              await purgeOfflineLocalState();
              setStoredDevice(null);
              setOfflineOps([]);
              setFeedback({ kind: "ok", text: "Cache offline & ikatan perangkat lokal dibersihkan (shared-device purge)." });
            }}
          >
            Purge Cache Lokal
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
            Belum ada inspeksi dalam cakupan proyek Anda. Klaim unit aktif melalui API `CMD-026`
            untuk memulai draft inspeksi.
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

              return (
                <article key={insp.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      Inspeksi {insp.id.slice(0, 8)}… · Unit {insp.unit_id.slice(0, 8)}…
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
                              </strong>
                            </p>
                            {secItems.map((item) => {
                              const currentVal = checklistAnswers[insp.id]?.[item.id] ?? "";
                              return (
                                <div key={item.id} className="checklist-row">
                                  <label htmlFor={`ci-${insp.id}-${item.id}`} className="rbac-meta">
                                    {item.label} {item.required ? "*" : ""}
                                  </label>
                                  {item.answer_type === "PASS_FAIL" || item.answer_type === "YES_NO" ? (
                                    <select
                                      id={`ci-${insp.id}-${item.id}`}
                                      className="inline-input"
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
                                    >
                                      <option value="">-- Pilih --</option>
                                      {item.answer_type === "PASS_FAIL" ? (
                                        <>
                                          <option value="PASS">PASS</option>
                                          <option value="FAIL">FAIL</option>
                                        </>
                                      ) : (
                                        <>
                                          <option value="YA">YA</option>
                                          <option value="TIDAK">TIDAK</option>
                                        </>
                                      )}
                                    </select>
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
                        <label htmlFor={`draft-${insp.id}`}>Catatan Draft Inspeksi (CMD-028 / Offline T-09)</label>
                        <input
                          id={`draft-${insp.id}`}
                          type="text"
                          value={draftNotes[insp.id] ?? ""}
                          onChange={(e) =>
                            setDraftNotes((prev) => ({ ...prev, [insp.id]: e.target.value }))
                          }
                          placeholder="Hasil pemeriksaan fisik IFP / Standing Bracket"
                        />
                      </div>
                      <div className="admin-inline">
                        <button
                          type="button"
                          className="auth-button admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => {
                            const { draft_checklist, draft_specifications } = buildDraftPayloads(insp.id);
                            void callApi(
                              `draft-${insp.id}`,
                              "/api/v1/inspections/draft",
                              {
                                inspection_id: insp.id,
                                expected_row_version: insp.row_version,
                                draft_checklist,
                                draft_specifications,
                                notes: note || "Draft diperbarui dari UI"
                              },
                              "Draft inspeksi tersimpan di server"
                            );
                          }}
                        >
                          Simpan Draft Online (CMD-028)
                        </button>
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleEnqueueOfflineDraft(insp)}
                        >
                          Simpan ke Antrean Offline (T-09)
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
                            Unggah Bukti (JPEG/PNG/WebP/PDF)
                            <input
                              type="file"
                              accept="image/jpeg,image/png,image/webp,application/pdf"
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
                        onClick={() =>
                          callApi(
                            `sub-${insp.id}`,
                            "/api/v1/inspections/submit",
                            {
                              inspection_id: insp.id,
                              expected_row_version: insp.row_version,
                              submit_reason: reason || null
                            },
                            "Inspeksi berhasil disubmit (revisi baru dibuat)"
                          )
                        }
                      >
                        Submit (CMD-029)
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
                          Approve (CMD-031)
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
                          Return (CMD-030)
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
                                  "Dokumen PDF 1.4 berhasil dibuat & disimpan di Private Storage"
                                );
                              }}
                            >
                              Generate PDF (CMD-036)
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
                          Reopen (CMD-032)
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
                            "Permintaan SES-001 packed-unit abort diajukan"
                          )
                        }
                      >
                        Ajukan Abort SES-001 (CMD-055)
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
                    Lepas Klaim (CMD-027)
                  </button>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="admin-panel" aria-labelledby="aborts-heading">
          <h2 id="aborts-heading">Permintaan Abort SES-001 ({abortRequests.length})</h2>
          {abortRequests.length === 0 ? (
            <p className="rbac-meta">Tidak ada permintaan packed-unit abort.</p>
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
                              reason: "Disetujui sesuai kondisi unit terkemas SES-001"
                            },
                            "Packed-unit abort disetujui (ABORTED)"
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
