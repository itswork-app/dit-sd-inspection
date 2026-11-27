"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { sha256Hex } from "@/lib/offline/sync-queue";

type ProjectRow = { id: string; code: string; name: string; status: string };
type SessionRow = { id: string; project_id: string; code: string; status: string };
type LocationRow = { id: string; project_id: string; code: string; name: string };
type DocumentRow = {
  id: string;
  project_id: string;
  session_id: string;
  document_type: string;
  version_no: number;
  is_current: boolean;
  status: string;
  generated_at: string;
};
type PrintBatchRow = {
  id: string;
  project_id: string;
  session_id: string;
  requested_count: number;
  status: string;
  created_at: string;
};
type AttendanceRecordRow = {
  id: string;
  project_id: string;
  session_id: string;
  location_id: string;
  status: string;
  row_version: string;
  updated_at: string;
};
type AttendanceDocRow = {
  id: string;
  attendance_record_id: string;
  version_no: number;
  mime_type: string;
  byte_size: number;
  status: string;
  uploaded_at: string;
};

type OperationsPanelProps = {
  projects: ProjectRow[];
  sessions: SessionRow[];
  locations: LocationRow[];
  documents: DocumentRow[];
  printBatches: PrintBatchRow[];
  attendanceRecords: AttendanceRecordRow[];
  attendanceDocuments: AttendanceDocRow[];
};

const ALLOWED_MIMES = new Set(["image/jpeg", "image/png", "image/webp", "application/pdf"]);

export function OperationsPanel({
  projects,
  sessions,
  locations,
  documents,
  printBatches,
  attendanceRecords,
  attendanceDocuments
}: OperationsPanelProps) {
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  // Batch print selection
  const [selectedDocIds, setSelectedDocIds] = useState<Record<string, boolean>>({});

  // Attendance upload form
  const [attProjectId, setAttProjectId] = useState(projects[0]?.id ?? "");
  const [attSessionId, setAttSessionId] = useState(sessions[0]?.id ?? "");
  const [attLocationId, setAttLocationId] = useState(locations[0]?.id ?? "");
  const [attReason, setAttReason] = useState("");

  // Reports state
  const [reportProjectId, setReportProjectId] = useState(projects[0]?.id ?? "");
  const [reportSessionId, setReportSessionId] = useState("");
  const [targetReport, setTargetReport] = useState<Record<string, unknown> | null>(null);
  const [actualReport, setActualReport] = useState<Record<string, unknown> | null>(null);

  // Audit viewer (CMD-043 read-only — CMD-044 export intentionally absent!)
  const [auditPurpose, setAuditPurpose] = useState("Pemeriksaan kepatuhan operasional rutin");
  const [auditEventFilter, setAuditEventFilter] = useState("");
  const [auditRows, setAuditRows] = useState<Array<Record<string, unknown>>>([]);

  async function handleDownloadDocument(docId: string) {
    if (busyKey) return;
    setBusyKey(`dl-${docId}`);
    setFeedback(null);
    try {
      const res = await fetch(`/api/v1/documents/${docId}/download`, { method: "GET" });
      const payload = (await res.json().catch(() => null)) as
        | { signed_download_url?: string; status?: string; error?: { message?: string } }
        | null;
      if (!res.ok || !payload?.signed_download_url) {
        setFeedback({
          kind: "err",
          text: `Unduh PDF ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Tidak berwenang."}`
        });
        return;
      }
      window.open(payload.signed_download_url, "_blank", "noopener,noreferrer");
      setFeedback({ kind: "ok", text: "Tautan unduh PDF aman (berlaku 60 detik) berhasil diterbitkan." });
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus saat mengunduh dokumen." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleSinglePrint(doc: DocumentRow) {
    if (busyKey) return;
    setBusyKey(`pr-${doc.id}`);
    setFeedback(null);
    try {
      const res = await fetch("/api/v1/documents/print", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          document_id: doc.id,
          expected_document_version: doc.version_no,
          client_print_signal: "operations-ui-print"
        })
      });
      const payload = (await res.json().catch(() => null)) as
        | { status?: string; sequence_no?: number; error?: { message?: string } }
        | null;
      if (!res.ok) {
        setFeedback({
          kind: "err",
          text: `Catat cetak ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Periksa izin document.print."}`
        });
        return;
      }
      setFeedback({ kind: "ok", text: `Cetak dokumen tercatat (urutan #${payload?.sequence_no ?? "?"}).` });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat mencatat cetak." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleBatchPrint() {
    if (busyKey) return;
    const picked = documents.filter((d) => selectedDocIds[d.id] && d.is_current);
    if (picked.length === 0) {
      setFeedback({ kind: "err", text: "Pilih minimal satu dokumen CURRENT untuk cetak batch." });
      return;
    }
    const projectId = picked[0].project_id;
    const sessionId = picked[0].session_id;
    if (picked.some((d) => d.project_id !== projectId || d.session_id !== sessionId)) {
      setFeedback({ kind: "err", text: "Semua dokumen dalam satu batch harus berasal dari proyek & sesi yang sama." });
      return;
    }

    setBusyKey("batch-print");
    setFeedback(null);
    try {
      const res = await fetch("/api/v1/documents/print/batch", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          project_id: projectId,
          session_id: sessionId,
          items: picked.map((doc, idx) => ({
            item_key: `item-${idx + 1}-${doc.id.slice(0, 8)}`,
            document_id: doc.id,
            expected_document_version: doc.version_no
          }))
        })
      });
      const payload = (await res.json().catch(() => null)) as
        | { status?: string; batch_id?: string; error?: { message?: string } }
        | null;
      if (!res.ok) {
        setFeedback({
          kind: "err",
          text: `Cetak batch ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Periksa izin batch print."}`
        });
        return;
      }
      setSelectedDocIds({});
      setFeedback({
        kind: "ok",
        text: `Batch cetak tercatat (${payload?.status ?? "SUCCEEDED"}, batch ${payload?.batch_id?.slice(0, 8) ?? "?"}…).`
      });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat mengirim batch print." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleUploadAttendance(file: File | null) {
    if (!file || busyKey) return;
    if (!attProjectId || !attSessionId || !attLocationId) {
      setFeedback({ kind: "err", text: "Pilih proyek, sesi, dan lokasi absensi terlebih dahulu." });
      return;
    }
    if (!ALLOWED_MIMES.has(file.type)) {
      setFeedback({ kind: "err", text: "Format absensi harus JPEG/PNG/WebP/PDF." });
      return;
    }

    setBusyKey("att-upload");
    setFeedback(null);
    try {
      const digest = await sha256Hex(await file.arrayBuffer());
      const res = await fetch("/api/v1/attendance/upload", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          project_id: attProjectId,
          session_id: attSessionId,
          location_id: attLocationId,
          sha256: digest,
          byte_size: file.size,
          mime_type: file.type,
          replacement_reason: attReason.trim() || null
        })
      });
      const payload = (await res.json().catch(() => null)) as
        | { status?: string; error?: { message?: string } }
        | null;
      if (!res.ok) {
        setFeedback({
          kind: "err",
          text: `Unggah absensi ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Periksa izin."}`
        });
        return;
      }
      setFeedback({ kind: "ok", text: `Dokumen absensi tercatat (${payload?.status ?? "UPLOADED"}).` });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat mengunggah absensi." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleVerifyAttendance(
    rec: AttendanceRecordRow,
    doc: AttendanceDocRow,
    decision: "VERIFY" | "REJECT"
  ) {
    if (busyKey) return;
    setBusyKey(`att-${decision}-${rec.id}`);
    setFeedback(null);
    try {
      const res = await fetch("/api/v1/attendance/verify", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          attendance_record_id: rec.id,
          attendance_document_id: doc.id,
          decision,
          expected_row_version: rec.row_version,
          reason: decision === "VERIFY" ? "Absensi sesuai daftar hadir sesi" : "Dokumen absensi tidak terbaca"
        })
      });
      const payload = (await res.json().catch(() => null)) as
        | { status?: string; error?: { message?: string } }
        | null;
      if (!res.ok) {
        setFeedback({
          kind: "err",
          text: `Verifikasi absensi ditolak (${payload?.status ?? res.status}): ${payload?.error?.message ?? "Periksa hak akses Anda."}`
        });
        return;
      }
      setFeedback({ kind: "ok", text: `Absensi ${decision} berhasil (${payload?.status ?? "OK"}).` });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat verifikasi absensi." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleLoadReports() {
    if (busyKey || !reportProjectId) return;
    setBusyKey("reports");
    setFeedback(null);
    try {
      const qs = new URLSearchParams({ project_id: reportProjectId });
      if (reportSessionId) qs.set("session_id", reportSessionId);

      const [tRes, aRes] = await Promise.all([
        fetch(`/api/v1/reports/target?${qs.toString()}`),
        fetch(`/api/v1/reports/actual?${qs.toString()}`)
      ]);
      const tJson = (await tRes.json().catch(() => null)) as Record<string, unknown> | null;
      const aJson = (await aRes.json().catch(() => null)) as Record<string, unknown> | null;

      if (!tRes.ok || !aRes.ok) {
        setFeedback({ kind: "err", text: "Gagal memuat laporan target/aktual (periksa izin laporan)." });
        return;
      }
      setTargetReport(tJson);
      setActualReport(aJson);
      setFeedback({ kind: "ok", text: "Laporan Target & Aktual berhasil dimuat." });
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat memuat laporan." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleReadAudit() {
    if (busyKey) return;
    if (auditPurpose.trim().length < 5) {
      setFeedback({ kind: "err", text: "Tujuan pembacaan riwayat audit minimal 5 karakter." });
      return;
    }
    setBusyKey("audit-read");
    setFeedback(null);
    try {
      const res = await fetch("/api/v1/audit/read", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          purpose: auditPurpose.trim(),
          limit: 25,
          event_type: auditEventFilter.trim() || null
        })
      });
      const payload = (await res.json().catch(() => null)) as
        | { status?: string; events?: Array<Record<string, unknown>>; rows?: Array<Record<string, unknown>> }
        | null;
      if (!res.ok) {
        setFeedback({ kind: "err", text: `Pembacaan audit ditolak (${payload?.status ?? res.status}).` });
        return;
      }
      const rows = payload?.events ?? payload?.rows ?? [];
      setAuditRows(rows);
      setFeedback({ kind: "ok", text: `Audit trail dimuat (${rows.length} entri). Akses baca ini turut diaudit.` });
    } catch {
      setFeedback({ kind: "err", text: "Koneksi terputus saat membaca audit trail." });
    } finally {
      setBusyKey(null);
    }
  }

  const filteredSessions = sessions.filter((s) => !attProjectId || s.project_id === attProjectId);
  const filteredLocations = locations.filter((l) => !attProjectId || l.project_id === attProjectId);

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

      <section className="admin-panel" aria-labelledby="ops-docs-heading">
        <div className="admin-item-header">
          <h2 id="ops-docs-heading">Dokumen PDF &amp; Cetak Batch ({documents.length})</h2>
          <button
            type="button"
            className="auth-button admin-btn-sm"
            disabled={busyKey !== null || Object.values(selectedDocIds).every((v) => !v)}
            onClick={handleBatchPrint}
          >
            Cetak Batch Terpilih
          </button>
        </div>
        <p className="rbac-meta">
          Unduhan PDF menggunakan tautan aman sementara (60 detik) dan tercatat otomatis. Hanya
          versi dokumen aktif terbaru yang dapat dicetak.
        </p>
        {documents.length === 0 ? (
          <p className="rbac-meta">Belum ada dokumen PDF yang dibuat.</p>
        ) : (
          <div className="admin-list">
            {documents.map((doc) => (
              <article key={doc.id} className="admin-item">
                <div className="admin-item-header">
                  <label className="admin-inline">
                    {doc.is_current ? (
                      <input
                        type="checkbox"
                        checked={Boolean(selectedDocIds[doc.id])}
                        onChange={(e) =>
                          setSelectedDocIds((prev) => ({ ...prev, [doc.id]: e.target.checked }))
                        }
                      />
                    ) : null}
                    <strong>
                      {doc.document_type} v{doc.version_no} ({doc.id.slice(0, 8)}…)
                    </strong>
                  </label>
                  <span
                    className={`status-badge ${
                      doc.is_current ? "status-badge-approved" : "status-badge-disabled"
                    }`}
                  >
                    {doc.is_current ? "VERSI AKTIF" : doc.status}
                  </span>
                </div>
                <p className="rbac-meta">
                  Dibuat: {new Date(doc.generated_at).toLocaleString("id-ID")} · Sesi {doc.session_id.slice(0, 8)}…
                </p>
                <div className="admin-inline">
                  <button
                    type="button"
                    className="auth-button admin-btn-sm"
                    disabled={busyKey !== null}
                    onClick={() => handleDownloadDocument(doc.id)}
                  >
                    Unduh PDF (60 dtk)
                  </button>
                  {doc.is_current ? (
                    <button
                      type="button"
                      className="auth-button auth-button-secondary admin-btn-sm"
                      disabled={busyKey !== null}
                      onClick={() => handleSinglePrint(doc)}
                    >
                      Catat Cetak
                    </button>
                  ) : null}
                </div>
              </article>
            ))}
          </div>
        )}
        {printBatches.length > 0 ? (
          <p className="rbac-meta">
            Riwayat batch cetak terbaru:{" "}
            {printBatches
              .slice(0, 5)
              .map((b) => `${b.id.slice(0, 6)} (${b.status}, ${b.requested_count} item)`)
              .join(" · ")}
          </p>
        ) : null}
      </section>

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="ops-att-heading">
          <h2 id="ops-att-heading">Absensi Sesi &amp; Verifikasi</h2>
          <div className="rbac-form">
            <div className="rbac-field">
              <label htmlFor="att-project">Proyek</label>
              <select
                id="att-project"
                value={attProjectId}
                onChange={(e) => setAttProjectId(e.target.value)}
              >
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.code} — {p.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="att-session">Sesi</label>
              <select
                id="att-session"
                value={attSessionId}
                onChange={(e) => setAttSessionId(e.target.value)}
              >
                {filteredSessions.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.code} ({s.status})
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="att-location">Lokasi</label>
              <select
                id="att-location"
                value={attLocationId}
                onChange={(e) => setAttLocationId(e.target.value)}
              >
                {filteredLocations.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.code} — {l.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="att-reason">Alasan penggantian (opsional)</label>
              <input
                id="att-reason"
                type="text"
                value={attReason}
                onChange={(e) => setAttReason(e.target.value)}
                placeholder="Isi bila mengganti daftar hadir sebelumnya"
              />
            </div>
            <label className="auth-button admin-btn-sm file-upload-label">
              Pilih File Absensi &amp; Catat
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp,application/pdf"
                disabled={busyKey !== null}
                style={{ display: "none" }}
                onChange={(e) => {
                  const file = e.target.files?.[0] ?? null;
                  void handleUploadAttendance(file);
                  e.currentTarget.value = "";
                }}
              />
            </label>
          </div>

          <div className="admin-list">
            {attendanceRecords.map((rec) => {
              const activeDoc = attendanceDocuments.find(
                (d) => d.attendance_record_id === rec.id && d.status === "ACTIVE"
              );
              return (
                <article key={rec.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>Absensi {rec.id.slice(0, 8)}…</strong>
                    <span className="status-badge">
                      {rec.status} · v{rec.row_version}
                    </span>
                  </div>
                  {activeDoc ? (
                    <div className="admin-inline">
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() => handleVerifyAttendance(rec, activeDoc, "VERIFY")}
                      >
                        Verifikasi
                      </button>
                      <button
                        type="button"
                        className="auth-button admin-btn-sm admin-btn-danger"
                        disabled={busyKey !== null}
                        onClick={() => handleVerifyAttendance(rec, activeDoc, "REJECT")}
                      >
                        Tolak
                      </button>
                    </div>
                  ) : null}
                </article>
              );
            })}
          </div>
        </section>

        <section className="admin-panel" aria-labelledby="ops-reports-heading">
          <h2 id="ops-reports-heading">Laporan Target vs Aktual</h2>
          <div className="rbac-form">
            <div className="rbac-field">
              <label htmlFor="rep-project">Proyek</label>
              <select
                id="rep-project"
                value={reportProjectId}
                onChange={(e) => setReportProjectId(e.target.value)}
              >
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.code} — {p.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="rep-session">Filter Sesi (opsional)</label>
              <select
                id="rep-session"
                value={reportSessionId}
                onChange={(e) => setReportSessionId(e.target.value)}
              >
                <option value="">Semua sesi proyek</option>
                {sessions
                  .filter((s) => s.project_id === reportProjectId)
                  .map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.code} ({s.status})
                    </option>
                  ))}
              </select>
            </div>
            <button
              type="button"
              className="auth-button admin-btn-sm"
              disabled={busyKey !== null || !reportProjectId}
              onClick={handleLoadReports}
            >
              Muat Laporan Target &amp; Aktual
            </button>
          </div>

          {targetReport || actualReport ? (() => {
            const totalTarget = Number(targetReport?.total_target_quantity ?? 0);
            const allocations = Array.isArray(targetReport?.allocations)
              ? (targetReport.allocations as Array<Record<string, unknown>>)
              : [];
            const actualCounts = (
              actualReport?.actual_counts_by_status &&
              typeof actualReport.actual_counts_by_status === "object"
                ? actualReport.actual_counts_by_status
                : {}
            ) as Record<string, number>;
            const approvedCount = Number(actualCounts.APPROVED ?? 0);
            const submittedCount = Number(actualCounts.SUBMITTED ?? 0);
            const draftCount = Number(actualCounts.DRAFT ?? 0) + Number(actualCounts.RETURNED ?? 0) + Number(actualCounts.REOPENED ?? 0);
            const abortedCount = Number(actualCounts.ABORTED ?? 0);
            const totalActual = Object.values(actualCounts).reduce((sum, v) => sum + Number(v || 0), 0);
            const pctApproved = totalTarget > 0 ? Math.min(999, Math.round((approvedCount / totalTarget) * 100)) : 0;

            return (
              <div className="admin-list">
                <div className="kpi-grid">
                  <div className="kpi-card">
                    <span className="kpi-label">Total Target</span>
                    <strong className="kpi-value">{totalTarget}</strong>
                  </div>
                  <div className="kpi-card">
                    <span className="kpi-label">Total Inspeksi</span>
                    <strong className="kpi-value">{totalActual}</strong>
                  </div>
                  <div className="kpi-card">
                    <span className="kpi-label">Disetujui (APPROVED)</span>
                    <strong className="kpi-value">{approvedCount}</strong>
                  </div>
                  <div className="kpi-card">
                    <span className="kpi-label">Capaian Target</span>
                    <strong className="kpi-value">{totalTarget > 0 ? `${pctApproved}%` : "-"}</strong>
                  </div>
                  <div className="kpi-card">
                    <span className="kpi-label">Submitted / Draft</span>
                    <strong className="kpi-value">{submittedCount} / {draftCount}</strong>
                  </div>
                  <div className="kpi-card">
                    <span className="kpi-label">Dibatalkan (Aborted)</span>
                    <strong className="kpi-value">{abortedCount}</strong>
                  </div>
                </div>

                {allocations.length > 0 ? (
                  <div className="ops-table-wrap">
                    <table className="ops-table">
                      <thead>
                        <tr>
                          <th>Tanggal Target</th>
                          <th>Versi Plan</th>
                          <th>Penugasan</th>
                          <th>Kuantitas</th>
                        </tr>
                      </thead>
                      <tbody>
                        {allocations.map((row, idx) => (
                          <tr key={`${String(row.assignment_id ?? idx)}-${String(row.target_date ?? idx)}`}>
                            <td>{String(row.target_date ?? "-")}</td>
                            <td>v{String(row.version ?? 1)}</td>
                            <td>{String(row.assignment_id ?? "").slice(0, 8)}…</td>
                            <td><strong>{String(row.quantity ?? 0)}</strong></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p className="rbac-meta">Belum ada Rencana Target aktif pada cakupan proyek/sesi ini.</p>
                )}

                <details>
                  <summary className="rbac-meta" style={{ cursor: "pointer" }}>
                    Lihat detail data laporan
                  </summary>
                  <pre className="json-pre">
                    {JSON.stringify({ targetReport, actualReport }, null, 2)}
                  </pre>
                </details>
              </div>
            );
          })() : null}
        </section>
      </div>

      <section className="admin-panel" aria-labelledby="ops-audit-heading">
        <div className="admin-item-header">
          <h2 id="ops-audit-heading">Riwayat Audit Aktivitas</h2>
          <span className="status-badge status-badge-pending">MODE BACA SAJA</span>
        </div>
        <div className="admin-inline">
          <input
            aria-label="Tujuan baca audit"
            className="inline-input"
            type="text"
            value={auditPurpose}
            onChange={(e) => setAuditPurpose(e.target.value)}
            placeholder="Tujuan pembacaan audit (wajib min. 5 karakter)"
          />
          <input
            aria-label="Filter jenis aktivitas audit"
            className="inline-input"
            type="text"
            value={auditEventFilter}
            onChange={(e) => setAuditEventFilter(e.target.value)}
            placeholder="Filter jenis aktivitas (opsional)"
          />
          <button
            type="button"
            className="auth-button auth-button-secondary admin-btn-sm"
            disabled={busyKey !== null}
            onClick={handleReadAudit}
          >
            Baca Riwayat Audit
          </button>
        </div>
        {auditRows.length > 0 ? (
          <div className="admin-list">
            {auditRows.map((row, idx) => (
              <article key={String(row.id ?? idx)} className="admin-item">
                <div className="admin-item-header">
                  <strong>{String(row.event_type ?? "audit.event")}</strong>
                  <span className="status-badge">{String(row.outcome ?? "OK")}</span>
                </div>
                <p className="rbac-meta">
                  Entity: {String(row.entity_type ?? "-")} · {String(row.occurred_at ?? row.created_at ?? "")}
                </p>
              </article>
            ))}
          </div>
        ) : null}
      </section>
    </div>
  );
}
