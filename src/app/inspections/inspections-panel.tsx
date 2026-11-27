"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type InspectionRow = {
  id: string;
  unit_id: string;
  project_id: string;
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

type InspectionsPanelProps = {
  inspections: InspectionRow[];
  activeClaims: ClaimRow[];
  revisions: RevisionRow[];
  abortRequests: AbortRow[];
};

export function InspectionsPanel({
  inspections,
  activeClaims,
  revisions,
  abortRequests
}: InspectionsPanelProps) {
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);
  const [reasons, setReasons] = useState<Record<string, string>>({});

  const latestRevisionByInspection = new Map<string, RevisionRow>();
  for (const rev of revisions) {
    const existing = latestRevisionByInspection.get(rev.inspection_id);
    if (!existing || rev.revision_no > existing.revision_no) {
      latestRevisionByInspection.set(rev.inspection_id, rev);
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
        | { status?: string; error?: { code?: string; message?: string } }
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
      setFeedback({ kind: "err", text: "Koneksi server terputus. Tidak ada mutasi dikonfirmasi." });
    } finally {
      setBusyKey(null);
    }
  }

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

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
                    Diperbarui: {new Date(insp.updated_at).toLocaleString("id-ID")}
                  </p>
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
                    {insp.status === "DRAFT" ||
                    insp.status === "RETURNED" ||
                    insp.status === "REOPENED" ? (
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
