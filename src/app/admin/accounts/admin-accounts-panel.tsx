"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type {
  AccountDecisionRecord,
  AccountRequestRecord,
  AppUserRecord,
  RoleCatalogRecord,
  UserRoleRecord,
  UserScopeGrantRecord
} from "@/lib/auth/account";
import {
  CANONICAL_SCOPE_TYPES,
  REJECTION_CATEGORIES
} from "@/lib/api/rbac-validators";

type AdminAccountsPanelProps = {
  actorUserId: string;
  users: AppUserRecord[];
  requests: AccountRequestRecord[];
  decisions: AccountDecisionRecord[];
  roleCatalog: RoleCatalogRecord[];
  userRoles: UserRoleRecord[];
  userScopes: UserScopeGrantRecord[];
};

const REJECTION_LABELS: Record<(typeof REJECTION_CATEGORIES)[number], string> = {
  UNVERIFIED_IDENTITY: "Identitas belum terverifikasi",
  OUT_OF_SCOPE_PERSONNEL: "Di luar cakupan personel",
  DUPLICATE_ACCOUNT: "Akun duplikat",
  INCOMPLETE_INFORMATION: "Informasi belum lengkap",
  POLICY_RESTRICTION: "Pembatasan kebijakan"
};

export function AdminAccountsPanel({
  actorUserId,
  users,
  requests,
  decisions,
  roleCatalog,
  userRoles,
  userScopes
}: AdminAccountsPanelProps) {
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  // Per-request inline inputs
  const [approveReasons, setApproveReasons] = useState<Record<string, string>>({});
  const [rejectCategories, setRejectCategories] = useState<
    Record<string, (typeof REJECTION_CATEGORIES)[number]>
  >({});
  const [rejectReasons, setRejectReasons] = useState<Record<string, string>>({});

  // Role grant form
  const [roleTargetUserId, setRoleTargetUserId] = useState("");
  const [roleCode, setRoleCode] = useState(roleCatalog[0]?.code ?? "inspector");
  const [roleProjectId, setRoleProjectId] = useState("");
  const [roleReason, setRoleReason] = useState("");

  // Scope grant form
  const [scopeTargetUserId, setScopeTargetUserId] = useState("");
  const [scopeType, setScopeType] = useState<(typeof CANONICAL_SCOPE_TYPES)[number]>("PROJECT");
  const [scopeId, setScopeId] = useState("");
  const [scopeReason, setScopeReason] = useState("");

  const userById = new Map(users.map((u) => [u.id, u]));
  const pendingRequests = requests.filter((r) => r.status === "PENDING");
  const eligibleTargetUsers = users.filter(
    (u) => u.account_status === "APPROVED" && u.id !== actorUserId
  );
  const selectedRoleCatalog = roleCatalog.find((r) => r.code === roleCode);

  async function invokeCommand(
    actionKey: string,
    url: string,
    body: Record<string, unknown>,
    successLabel: string
  ) {
    if (busyKey) return;
    setBusyKey(actionKey);
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
            payload?.error?.message ?? "Periksa status data, versi baris, atau izin."
          }`
        });
        return;
      }

      setFeedback({
        kind: "ok",
        text: `${successLabel} (${payload?.status ?? "OK"}).`
      });
      router.refresh();
    } catch {
      setFeedback({
        kind: "err",
        text: "Gagal menghubungi server. Tidak ada perubahan yang dikonfirmasi."
      });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleApprove(requestRow: AccountRequestRecord) {
    const user = userById.get(requestRow.user_id);
    if (!user) return;
    const reason = (approveReasons[requestRow.id] ?? "").trim() || "Disetujui setelah verifikasi";
    await invokeCommand(
      `approve-${requestRow.id}`,
      "/api/v1/admin/accounts/approve",
      {
        request_id: requestRow.id,
        expected_row_version: user.row_version,
        reason
      },
      `Akun ${user.display_name} disetujui`
    );
  }

  async function handleReject(requestRow: AccountRequestRecord) {
    const user = userById.get(requestRow.user_id);
    if (!user) return;
    const category = rejectCategories[requestRow.id] ?? "INCOMPLETE_INFORMATION";
    const reason = (rejectReasons[requestRow.id] ?? "").trim();
    if (reason.length < 5) {
      setFeedback({
        kind: "err",
        text: "Alasan penolakan wajib diisi minimal 5 karakter."
      });
      return;
    }
    await invokeCommand(
      `reject-${requestRow.id}`,
      "/api/v1/admin/accounts/reject",
      {
        request_id: requestRow.id,
        expected_row_version: user.row_version,
        rejection_category: category,
        reason
      },
      `Permintaan ${user.display_name} ditolak`
    );
  }

  async function handleStatusTransition(
    user: AppUserRecord,
    targetStatus: "SUSPENDED" | "DISABLED" | "APPROVED"
  ) {
    const reason =
      targetStatus === "APPROVED"
        ? "Pengaktifan kembali akun oleh Super Admin"
        : `Perubahan status akun ke ${targetStatus} oleh Super Admin`;
    await invokeCommand(
      `status-${user.id}-${targetStatus}`,
      "/api/v1/admin/accounts/status",
      {
        target_user_id: user.id,
        target_status: targetStatus,
        expected_row_version: user.row_version,
        reason
      },
      `Status akun ${user.display_name} diubah ke ${targetStatus}`
    );
  }

  async function handleGrantRole(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!roleTargetUserId) {
      setFeedback({ kind: "err", text: "Pilih pengguna tujuan terlebih dahulu." });
      return;
    }
    await invokeCommand(
      "grant-role",
      "/api/v1/admin/roles/grant",
      {
        target_user_id: roleTargetUserId,
        role_code: roleCode,
        project_id:
          selectedRoleCatalog?.scope_class === "PROJECT" ? roleProjectId.trim() || null : null,
        reason: roleReason.trim()
      },
      `Role ${roleCode} berhasil diberikan`
    );
  }

  async function handleRevokeRole(roleRow: UserRoleRecord) {
    await invokeCommand(
      `revoke-role-${roleRow.id}`,
      "/api/v1/admin/roles/revoke",
      {
        user_role_id: roleRow.id,
        expected_row_version: roleRow.row_version,
        reason: "Pencabutan role melalui panel administrasi RBAC"
      },
      `Role ${roleRow.role_code} dicabut`
    );
  }

  async function handleGrantScope(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!scopeTargetUserId) {
      setFeedback({ kind: "err", text: "Pilih pengguna tujuan terlebih dahulu." });
      return;
    }
    await invokeCommand(
      "grant-scope",
      "/api/v1/admin/scopes/grant",
      {
        target_user_id: scopeTargetUserId,
        scope_type: scopeType,
        scope_id: scopeId.trim(),
        reason: scopeReason.trim()
      },
      `Scope ${scopeType} berhasil diberikan`
    );
  }

  async function handleRevokeScope(scopeRow: UserScopeGrantRecord) {
    await invokeCommand(
      `revoke-scope-${scopeRow.id}`,
      "/api/v1/admin/scopes/revoke",
      {
        scope_grant_id: scopeRow.id,
        expected_row_version: scopeRow.row_version,
        reason: "Pencabutan scope eksplisit melalui panel administrasi RBAC"
      },
      `Scope ${scopeRow.scope_type} dicabut`
    );
  }

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

      <section className="admin-panel" aria-labelledby="pending-queue-heading">
        <h2 id="pending-queue-heading">
          Antrean Permintaan Akun ({pendingRequests.length})
        </h2>
        {pendingRequests.length === 0 ? (
          <p className="rbac-meta">Tidak ada permintaan akun berstatus PENDING saat ini.</p>
        ) : (
          <div className="admin-list">
            {pendingRequests.map((req) => {
              const user = userById.get(req.user_id);
              const isSelf = req.user_id === actorUserId;
              return (
                <article key={req.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>{req.requested_display_name}</strong>
                    <span className="status-badge status-badge-pending">PENDING</span>
                  </div>
                  <p className="rbac-meta">
                    Diajukan: {new Date(req.requested_at).toLocaleString("id-ID")} · Versi akun:{" "}
                    {user?.row_version ?? "-"}
                  </p>
                  {req.request_note ? (
                    <p className="rbac-meta">
                      <strong>Catatan pemohon:</strong> {req.request_note}
                    </p>
                  ) : null}

                  {isSelf ? (
                    <p className="rbac-meta">
                      Anda tidak dapat menyetujui atau menolak akun Anda sendiri.
                    </p>
                  ) : (
                    <>
                      <div className="rbac-field">
                        <label htmlFor={`approve-reason-${req.id}`}>Catatan persetujuan</label>
                        <input
                          id={`approve-reason-${req.id}`}
                          type="text"
                          value={approveReasons[req.id] ?? ""}
                          onChange={(e) =>
                            setApproveReasons((prev) => ({ ...prev, [req.id]: e.target.value }))
                          }
                          placeholder="Disetujui sesuai daftar personel inspeksi"
                        />
                      </div>
                      <div className="admin-inline">
                        <button
                          type="button"
                          className="auth-button admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleApprove(req)}
                        >
                          Setujui Akun
                        </button>
                      </div>
                      <div className="rbac-field">
                        <label htmlFor={`reject-cat-${req.id}`}>Kategori penolakan</label>
                        <select
                          id={`reject-cat-${req.id}`}
                          value={rejectCategories[req.id] ?? "INCOMPLETE_INFORMATION"}
                          onChange={(e) =>
                            setRejectCategories((prev) => ({
                              ...prev,
                              [req.id]: e.target.value as (typeof REJECTION_CATEGORIES)[number]
                            }))
                          }
                        >
                          {REJECTION_CATEGORIES.map((cat) => (
                            <option key={cat} value={cat}>
                              {REJECTION_LABELS[cat]}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div className="rbac-field">
                        <label htmlFor={`reject-reason-${req.id}`}>Alasan penolakan (min. 5 karakter)</label>
                        <input
                          id={`reject-reason-${req.id}`}
                          type="text"
                          value={rejectReasons[req.id] ?? ""}
                          onChange={(e) =>
                            setRejectReasons((prev) => ({ ...prev, [req.id]: e.target.value }))
                          }
                          placeholder="Jelaskan kekurangan informasi atau alasan penolakan"
                        />
                      </div>
                      <div className="admin-inline">
                        <button
                          type="button"
                          className="auth-button admin-btn-sm admin-btn-danger"
                          disabled={busyKey !== null}
                          onClick={() => handleReject(req)}
                        >
                          Tolak Permintaan
                        </button>
                      </div>
                    </>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </section>

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="grant-role-heading">
          <h2 id="grant-role-heading">Tetapkan Peran (Role)</h2>
          <form className="rbac-form" onSubmit={handleGrantRole}>
            <div className="rbac-field">
              <label htmlFor="role-user">Pengguna aktif (selain diri sendiri)</label>
              <select
                id="role-user"
                required
                value={roleTargetUserId}
                onChange={(e) => setRoleTargetUserId(e.target.value)}
              >
                <option value="">-- Pilih pengguna --</option>
                {eligibleTargetUsers.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.display_name} ({u.id.slice(0, 8)}…)
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="role-code">Peran operasional</label>
              <select
                id="role-code"
                value={roleCode}
                onChange={(e) => setRoleCode(e.target.value)}
              >
                {roleCatalog.map((r) => (
                  <option key={r.id} value={r.code}>
                    {r.name} [{r.scope_class}]
                  </option>
                ))}
              </select>
            </div>
            {selectedRoleCatalog?.scope_class === "PROJECT" ? (
              <div className="rbac-field">
                <label htmlFor="role-project-id">Project UUID (wajib untuk role PROJECT)</label>
                <input
                  id="role-project-id"
                  type="text"
                  required
                  value={roleProjectId}
                  onChange={(e) => setRoleProjectId(e.target.value)}
                  placeholder="xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx"
                />
              </div>
            ) : null}
            <div className="rbac-field">
              <label htmlFor="role-reason">Alasan penetapan</label>
              <input
                id="role-reason"
                type="text"
                required
                minLength={3}
                maxLength={500}
                value={roleReason}
                onChange={(e) => setRoleReason(e.target.value)}
                placeholder="Dasar surat tugas / penugasan proyek"
              />
            </div>
            <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
              Berikan Role
            </button>
          </form>
        </section>

        <section className="admin-panel" aria-labelledby="grant-scope-heading">
          <h2 id="grant-scope-heading">Tetapkan Cakupan Proyek / Lokasi</h2>
          <form className="rbac-form" onSubmit={handleGrantScope}>
            <div className="rbac-field">
              <label htmlFor="scope-user">Pengguna aktif (selain diri sendiri)</label>
              <select
                id="scope-user"
                required
                value={scopeTargetUserId}
                onChange={(e) => setScopeTargetUserId(e.target.value)}
              >
                <option value="">-- Pilih pengguna --</option>
                {eligibleTargetUsers.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.display_name} ({u.id.slice(0, 8)}…)
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="scope-type">Tipe scope</label>
              <select
                id="scope-type"
                value={scopeType}
                onChange={(e) =>
                  setScopeType(e.target.value as (typeof CANONICAL_SCOPE_TYPES)[number])
                }
              >
                {CANONICAL_SCOPE_TYPES.map((st) => (
                  <option key={st} value={st}>
                    {st}
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="scope-id">Resource UUID</label>
              <input
                id="scope-id"
                type="text"
                required
                value={scopeId}
                onChange={(e) => setScopeId(e.target.value)}
                placeholder="xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx"
              />
            </div>
            <div className="rbac-field">
              <label htmlFor="scope-reason">Alasan pemberian scope</label>
              <input
                id="scope-reason"
                type="text"
                required
                minLength={3}
                maxLength={500}
                value={scopeReason}
                onChange={(e) => setScopeReason(e.target.value)}
                placeholder="Cakupan penugasan operasional"
              />
            </div>
            <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
              Berikan Scope
            </button>
          </form>
        </section>
      </div>

      <section className="admin-panel" aria-labelledby="users-heading">
        <h2 id="users-heading">Daftar Akun, Role &amp; Scope ({users.length})</h2>
        <div className="admin-list">
          {users.map((user) => {
            const isSelf = user.id === actorUserId;
            const activeRoles = userRoles.filter(
              (ur) => ur.user_id === user.id && ur.status === "ACTIVE"
            );
            const activeScopes = userScopes.filter(
              (sc) => sc.user_id === user.id && sc.status === "ACTIVE"
            );
            return (
              <article key={user.id} className="admin-item">
                <div className="admin-item-header">
                  <strong>
                    {user.display_name} {isSelf ? "(Anda)" : ""}
                  </strong>
                  <span
                    className={`status-badge status-badge-${user.account_status.toLowerCase()}`}
                  >
                    {user.account_status} · v{user.row_version}
                  </span>
                </div>

                <div className="admin-inline">
                  <span className="rbac-meta">
                    <strong>Role aktif:</strong>{" "}
                    {activeRoles.length === 0 ? "Tidak ada" : ""}
                  </span>
                  {activeRoles.map((ur) => (
                    <span key={ur.id} className="admin-inline">
                      <span className="status-badge">
                        {ur.role_code}
                        {ur.project_id ? `:${ur.project_id.slice(0, 6)}…` : ":GLOBAL"}
                      </span>
                      {!isSelf ? (
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleRevokeRole(ur)}
                        >
                          Cabut
                        </button>
                      ) : null}
                    </span>
                  ))}
                </div>

                <div className="admin-inline">
                  <span className="rbac-meta">
                    <strong>Scope aktif:</strong>{" "}
                    {activeScopes.length === 0 ? "Tidak ada" : ""}
                  </span>
                  {activeScopes.map((sc) => (
                    <span key={sc.id} className="admin-inline">
                      <span className="status-badge">
                        {sc.scope_type}:{sc.scope_id.slice(0, 6)}…
                      </span>
                      {!isSelf ? (
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleRevokeScope(sc)}
                        >
                          Cabut
                        </button>
                      ) : null}
                    </span>
                  ))}
                </div>

                {!isSelf ? (
                  <div className="admin-inline">
                    {user.account_status === "APPROVED" ? (
                      <>
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleStatusTransition(user, "SUSPENDED")}
                        >
                          Tangguhkan
                        </button>
                        <button
                          type="button"
                          className="auth-button admin-btn-sm admin-btn-danger"
                          disabled={busyKey !== null}
                          onClick={() => handleStatusTransition(user, "DISABLED")}
                        >
                          Nonaktifkan
                        </button>
                      </>
                    ) : null}
                    {user.account_status === "SUSPENDED" || user.account_status === "DISABLED" ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() => handleStatusTransition(user, "APPROVED")}
                      >
                        Aktifkan Kembali
                      </button>
                    ) : null}
                  </div>
                ) : (
                  <p className="rbac-meta">
                    Perubahan status atau peran pada akun sendiri tidak diizinkan.
                  </p>
                )}
              </article>
            );
          })}
        </div>
      </section>

      <section className="admin-panel" aria-labelledby="decisions-heading">
        <h2 id="decisions-heading">Riwayat Keputusan Akun Terbaru ({decisions.length})</h2>
        {decisions.length === 0 ? (
          <p className="rbac-meta">Belum ada keputusan akun yang tercatat.</p>
        ) : (
          <div className="admin-list">
            {decisions.slice(0, 15).map((dec) => {
              const target = userById.get(dec.target_user_id);
              return (
                <div key={dec.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {dec.decision} — {target?.display_name ?? dec.target_user_id.slice(0, 8)}
                    </strong>
                    <span className="rbac-meta">
                      {new Date(dec.decided_at).toLocaleString("id-ID")}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    {dec.rejection_category ? `[${dec.rejection_category}] ` : ""}
                    {dec.reason}
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
