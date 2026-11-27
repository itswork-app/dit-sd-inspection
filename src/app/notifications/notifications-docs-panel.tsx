"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type NotificationItem = {
  id: string;
  event_type: string;
  priority: string;
  title_key: string;
  body_key: string;
  created_at: string;
  read_at: string | null;
};

type DocumentRow = {
  id: string;
  document_type: string;
  version_no: number;
  is_current: boolean;
  status: string;
  generated_at: string;
};

type NotificationsAndDocsPanelProps = {
  notifications: NotificationItem[];
  documents: DocumentRow[];
};

export function NotificationsAndDocsPanel({
  notifications,
  documents
}: NotificationsAndDocsPanelProps) {
  const router = useRouter();
  const [busyId, setBusyId] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  async function handleMarkRead(notificationId: string) {
    if (busyId) return;
    setBusyId(notificationId);
    setFeedback(null);
    try {
      const response = await fetch("/api/v1/notifications/read", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ notification_id: notificationId })
      });
      if (!response.ok) {
        setFeedback({ kind: "err", text: "Gagal menandai notifikasi sebagai telah dibaca." });
        return;
      }
      setFeedback({ kind: "ok", text: "Notifikasi ditandai telah dibaca." });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus." });
    } finally {
      setBusyId(null);
    }
  }

  async function handleRecordPrint(doc: DocumentRow) {
    if (busyId) return;
    setBusyId(doc.id);
    setFeedback(null);
    try {
      const response = await fetch("/api/v1/documents/print", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify({
          document_id: doc.id,
          expected_document_version: doc.version_no,
          client_print_signal: "web-ui-print"
        })
      });
      const payload = (await response.json().catch(() => null)) as
        | { status?: string; sequence_no?: number }
        | null;
      if (!response.ok) {
        setFeedback({
          kind: "err",
          text: `Pencatatan cetak ditolak (${payload?.status ?? response.status}).`
        });
        return;
      }
      setFeedback({
        kind: "ok",
        text: `Cetak dokumen tercatat (urutan #${payload?.sequence_no ?? "?"}).`
      });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus." });
    } finally {
      setBusyId(null);
    }
  }

  async function handleDownloadPdf(docId: string) {
    if (busyId) return;
    setBusyId(`dl-${docId}`);
    setFeedback(null);
    try {
      const response = await fetch(`/api/v1/documents/${docId}/download`, { method: "GET" });
      const payload = (await response.json().catch(() => null)) as
        | { signed_download_url?: string; status?: string }
        | null;
      if (!response.ok || !payload?.signed_download_url) {
        setFeedback({
          kind: "err",
          text: `Unduh PDF ditolak (${payload?.status ?? response.status}).`
        });
        return;
      }
      window.open(payload.signed_download_url, "_blank", "noopener,noreferrer");
      setFeedback({ kind: "ok", text: "Tautan unduh PDF aman (berlaku 60 detik) telah diterbitkan." });
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus." });
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="inbox-heading">
          <h2 id="inbox-heading">Notifikasi Dalam Aplikasi ({notifications.length})</h2>
          <p className="rbac-meta">
            Notifikasi dapat ditandai sudah dibaca satu kali dan tetap tersimpan sebagai riwayat operasional.
          </p>
          {notifications.length === 0 ? (
            <p className="rbac-meta">Kotak masuk notifikasi Anda masih kosong.</p>
          ) : (
            <div className="admin-list">
              {notifications.map((n) => (
                <article key={n.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>{n.event_type}</strong>
                    <span
                      className={`status-badge ${
                        n.read_at ? "status-badge-approved" : "status-badge-pending"
                      }`}
                    >
                      {n.read_at ? "DIBACA" : `BELUM DIBACA · ${n.priority}`}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    {n.title_key} · {new Date(n.created_at).toLocaleString("id-ID")}
                  </p>
                  {!n.read_at ? (
                    <button
                      type="button"
                      className="auth-button admin-btn-sm"
                      disabled={busyId !== null}
                      onClick={() => handleMarkRead(n.id)}
                    >
                      Tandai Sudah Dibaca
                    </button>
                  ) : null}
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="admin-panel" aria-labelledby="docs-heading">
          <h2 id="docs-heading">Dokumen Disetujui &amp; Cetak ({documents.length})</h2>
          <p className="rbac-meta">
            Hanya versi dokumen aktif terbaru yang dapat dicetak; versi terdahulu tetap tersimpan
            sebagai riwayat arsip.
          </p>
          {documents.length === 0 ? (
            <p className="rbac-meta">Belum ada dokumen PDF/Berita Acara dalam cakupan akses Anda.</p>
          ) : (
            <div className="admin-list">
              {documents.map((doc) => (
                <article key={doc.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {doc.document_type} v{doc.version_no}
                    </strong>
                    <span
                      className={`status-badge ${
                        doc.is_current ? "status-badge-approved" : "status-badge-disabled"
                      }`}
                    >
                      {doc.is_current ? "VERSI AKTIF" : doc.status}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    Dibuat: {new Date(doc.generated_at).toLocaleString("id-ID")}
                  </p>
                  <div className="admin-inline">
                    <button
                      type="button"
                      className="auth-button admin-btn-sm"
                      disabled={busyId !== null}
                      onClick={() => handleDownloadPdf(doc.id)}
                    >
                      Unduh PDF (60 dtk)
                    </button>
                    {doc.is_current ? (
                      <button
                        type="button"
                        className="auth-button auth-button-secondary admin-btn-sm"
                        disabled={busyId !== null}
                        onClick={() => handleRecordPrint(doc)}
                      >
                        Catat Cetak
                      </button>
                    ) : null}
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
