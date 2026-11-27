"use client";

import Link from "next/link";
import { useState } from "react";
import { ROLE_META, type CanonicalRoleCode } from "@/lib/auth/roles";

export type DashboardQueueUnit = {
  id: string;
  serial: string;
  instrumentType: string;
  status: string;
  revisionNo: number;
  updatedAt: string;
};

export type DashboardPendingAccount = {
  id: string;
  displayName: string;
  requestedAt: string;
};

export type DashboardDocSummary = {
  id: string;
  documentType: string;
  versionNo: number;
  generatedAt: string;
};

export type DashboardData = {
  userName: string;
  activeRoles: CanonicalRoleCode[];
  unreadNotifications: number;
  pendingAccountsCount: number;
  pendingAccounts: DashboardPendingAccount[];
  approvedUsersCount: number;
  activeProjectsCount: number;
  activeSessionsCount: number;
  draftSessionsCount: number;
  publishedAssignmentsCount: number;
  openConflictsCount: number;
  activeClaimsCount: number;
  pendingAbortsCount: number;
  unverifiedAttendanceCount: number;
  draftInspectionsCount: number;
  returnedInspectionsCount: number;
  submittedInspectionsCount: number;
  approvedInspectionsCount: number;
  currentDocsCount: number;
  printBatchesCount: number;
  myFieldQueue: DashboardQueueUnit[];
  submittedQueue: DashboardQueueUnit[];
  approvedForPrintQueue: DashboardQueueUnit[];
  currentDocs: DashboardDocSummary[];
};

function renderRoleSection(role: CanonicalRoleCode, data: DashboardData) {
  if (role === "super_admin") {
    return (
      <section className="admin-panel" aria-label="Dashboard Super Admin">
        <div className="admin-item-header">
          <div>
            <h2>Dashboard Super Admin</h2>
            <p className="rbac-meta">{ROLE_META.super_admin.description}</p>
          </div>
          <Link className="auth-button admin-btn-sm" href="/admin/accounts">
            Kelola Akun &amp; Peran
          </Link>
        </div>

        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">Permintaan Akun Pending</span>
            <strong className="kpi-value">{data.pendingAccountsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Akun Disetujui</span>
            <strong className="kpi-value">{data.approvedUsersCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Proyek Aktif</span>
            <strong className="kpi-value">{data.activeProjectsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Sesi Aktif</span>
            <strong className="kpi-value">{data.activeSessionsCount}</strong>
          </div>
        </div>

        {data.pendingAccounts.length > 0 ? (
          <div className="admin-list">
            {data.pendingAccounts.map((req) => (
              <article key={req.id} className="admin-item">
                <div className="admin-item-header">
                  <strong>{req.displayName}</strong>
                  <span className="status-badge status-badge-pending">MENUNGGU PERSETUJUAN</span>
                </div>
                <p className="rbac-meta">
                  Diajukan: {new Date(req.requestedAt).toLocaleString("id-ID")}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <p className="rbac-meta">Tidak ada permintaan akun baru yang menunggu persetujuan.</p>
        )}

        <div className="admin-inline">
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/workspace">
            Buka Workspace Proyek
          </Link>
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/operations">
            Laporan &amp; Riwayat Audit
          </Link>
        </div>
      </section>
    );
  }

  if (role === "admin") {
    return (
      <section className="admin-panel" aria-label="Dashboard Admin Proyek">
        <div className="admin-item-header">
          <div>
            <h2>Dashboard Admin Proyek</h2>
            <p className="rbac-meta">{ROLE_META.admin.description}</p>
          </div>
          <Link className="auth-button admin-btn-sm" href="/workspace">
            Buka Workspace Operasional
          </Link>
        </div>

        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">Proyek Aktif</span>
            <strong className="kpi-value">{data.activeProjectsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Sesi Aktif / Draft</span>
            <strong className="kpi-value">
              {data.activeSessionsCount} / {data.draftSessionsCount}
            </strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Penugasan Terbit</span>
            <strong className="kpi-value">{data.publishedAssignmentsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Konflik Serial Terbuka</span>
            <strong className="kpi-value">{data.openConflictsCount}</strong>
          </div>
        </div>

        <div className="admin-inline">
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/operations">
            Lihat Target vs Aktual
          </Link>
        </div>
      </section>
    );
  }

  if (role === "korlap") {
    return (
      <section className="admin-panel" aria-label="Dashboard Koordinator Lapangan">
        <div className="admin-item-header">
          <div>
            <h2>Dashboard Koordinator Lapangan</h2>
            <p className="rbac-meta">{ROLE_META.korlap.description}</p>
          </div>
          <Link className="auth-button admin-btn-sm" href="/operations">
            Kelola Absensi &amp; Laporan
          </Link>
        </div>

        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">Sesi Aktif</span>
            <strong className="kpi-value">{data.activeSessionsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Klaim Unit Aktif</span>
            <strong className="kpi-value">{data.activeClaimsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Absensi Perlu Verifikasi</span>
            <strong className="kpi-value">{data.unverifiedAttendanceCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Permintaan Pembatalan Pending</span>
            <strong className="kpi-value">{data.pendingAbortsCount}</strong>
          </div>
        </div>

        <div className="admin-inline">
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/inspections">
            Pantau Klaim &amp; Pembatalan Unit
          </Link>
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/workspace">
            Atur Penugasan Tim
          </Link>
        </div>
      </section>
    );
  }

  if (role === "inspector") {
    return (
      <section className="admin-panel" aria-label="Dashboard Inspector">
        <div className="admin-item-header">
          <div>
            <h2>Dashboard Inspector</h2>
            <p className="rbac-meta">{ROLE_META.inspector.description}</p>
          </div>
          <Link className="auth-button admin-btn-sm" href="/inspections">
            Scan SN &amp; Mulai Inspeksi
          </Link>
        </div>

        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">Penugasan Aktif</span>
            <strong className="kpi-value">{data.publishedAssignmentsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Klaim Unit Aktif</span>
            <strong className="kpi-value">{data.activeClaimsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Draft Inspeksi</span>
            <strong className="kpi-value">{data.draftInspectionsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Perlu Perbaikan (Returned)</span>
            <strong className="kpi-value">{data.returnedInspectionsCount}</strong>
          </div>
        </div>

        {data.myFieldQueue.length > 0 ? (
          <div className="admin-list">
            {data.myFieldQueue.map((item) => (
              <article key={item.id} className="admin-item">
                <div className="admin-item-header">
                  <strong>
                    {item.instrumentType} · SN {item.serial}
                  </strong>
                  <span
                    className={`status-badge ${
                      item.status === "RETURNED" ? "status-badge-rejected" : "status-badge-pending"
                    }`}
                  >
                    {item.status} · rev {item.revisionNo}
                  </span>
                </div>
                <p className="rbac-meta">
                  Diperbarui: {new Date(item.updatedAt).toLocaleString("id-ID")}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <p className="rbac-meta">
            Belum ada unit aktif yang sedang Anda periksa. Buka halaman Inspeksi untuk scan QR/Barcode atau input SN.
          </p>
        )}
      </section>
    );
  }

  if (role === "reviewer") {
    return (
      <section className="admin-panel" aria-label="Dashboard Reviewer">
        <div className="admin-item-header">
          <div>
            <h2>Dashboard Reviewer</h2>
            <p className="rbac-meta">{ROLE_META.reviewer.description}</p>
          </div>
          <Link className="auth-button admin-btn-sm" href="/inspections">
            Buka Antrean Review
          </Link>
        </div>

        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">Menunggu Review (Submitted)</span>
            <strong className="kpi-value">{data.submittedInspectionsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Sudah Disetujui</span>
            <strong className="kpi-value">{data.approvedInspectionsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Dikembalikan untuk Perbaikan</span>
            <strong className="kpi-value">{data.returnedInspectionsCount}</strong>
          </div>
          <div className="kpi-card">
            <span className="kpi-label">Absensi Perlu Verifikasi</span>
            <strong className="kpi-value">{data.unverifiedAttendanceCount}</strong>
          </div>
        </div>

        {data.submittedQueue.length > 0 ? (
          <div className="admin-list">
            {data.submittedQueue.map((item) => (
              <article key={item.id} className="admin-item">
                <div className="admin-item-header">
                  <strong>
                    {item.instrumentType} · SN {item.serial}
                  </strong>
                  <span className="status-badge status-badge-pending">
                    SUBMITTED · rev {item.revisionNo}
                  </span>
                </div>
                <p className="rbac-meta">
                  Masuk review: {new Date(item.updatedAt).toLocaleString("id-ID")}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <p className="rbac-meta">Tidak ada hasil inspeksi berstatus SUBMITTED yang menunggu tinjauan saat ini.</p>
        )}

        <div className="admin-inline">
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/operations">
            Verifikasi Absensi Sesi
          </Link>
        </div>
      </section>
    );
  }

  return (
    <section className="admin-panel" aria-label="Dashboard Petugas Cetak">
      <div className="admin-item-header">
        <div>
          <h2>Dashboard Petugas Cetak</h2>
          <p className="rbac-meta">{ROLE_META.print_officer.description}</p>
        </div>
        <Link className="auth-button admin-btn-sm" href="/operations">
          Unduh &amp; Cetak Dokumen
        </Link>
      </div>

      <div className="kpi-grid">
        <div className="kpi-card">
          <span className="kpi-label">Unit Disetujui (Siap PDF)</span>
          <strong className="kpi-value">{data.approvedInspectionsCount}</strong>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">Dokumen Versi Aktif</span>
          <strong className="kpi-value">{data.currentDocsCount}</strong>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">Riwayat Batch Cetak</span>
          <strong className="kpi-value">{data.printBatchesCount}</strong>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">Notifikasi Belum Dibaca</span>
          <strong className="kpi-value">{data.unreadNotifications}</strong>
        </div>
      </div>

      {data.approvedForPrintQueue.length > 0 ? (
        <div className="admin-list">
          {data.approvedForPrintQueue.map((item) => (
            <article key={item.id} className="admin-item">
              <div className="admin-item-header">
                <strong>
                  {item.instrumentType} · SN {item.serial}
                </strong>
                <span className="status-badge status-badge-approved">
                  APPROVED · rev {item.revisionNo}
                </span>
              </div>
              <p className="rbac-meta">
                Disetujui: {new Date(item.updatedAt).toLocaleString("id-ID")}
              </p>
            </article>
          ))}
        </div>
      ) : (
        <p className="rbac-meta">Belum ada inspeksi berstatus APPROVED untuk diterbitkan PDF.</p>
      )}

      {data.currentDocs.length > 0 ? (
        <div className="admin-list">
          {data.currentDocs.map((doc) => (
            <article key={doc.id} className="admin-item">
              <div className="admin-item-header">
                <strong>
                  {doc.documentType} v{doc.versionNo}
                </strong>
                <span className="status-badge status-badge-approved">SIAP CETAK</span>
              </div>
              <p className="rbac-meta">
                Dibuat: {new Date(doc.generatedAt).toLocaleString("id-ID")}
              </p>
            </article>
          ))}
        </div>
      ) : null}

      <div className="admin-inline">
        <Link className="auth-button auth-button-secondary admin-btn-sm" href="/inspections">
          Buat PDF dari Unit Disetujui
        </Link>
      </div>
    </section>
  );
}

function getSummaryMetricForRole(role: CanonicalRoleCode, data: DashboardData): string {
  switch (role) {
    case "super_admin":
      return `${data.pendingAccountsCount} akun menunggu persetujuan · ${data.activeProjectsCount} proyek aktif`;
    case "admin":
      return `${data.activeProjectsCount} proyek aktif · ${data.activeSessionsCount} sesi aktif`;
    case "korlap":
      return `${data.activeClaimsCount} klaim aktif · ${data.pendingAbortsCount} pembatalan pending`;
    case "reviewer":
      return `${data.submittedInspectionsCount} unit menunggu review · ${data.approvedInspectionsCount} disetujui`;
    case "inspector":
      return `${data.draftInspectionsCount} draft · ${data.returnedInspectionsCount} perlu perbaikan`;
    case "print_officer":
      return `${data.approvedInspectionsCount} unit disetujui · ${data.currentDocsCount} dokumen siap cetak`;
  }
}

export function RoleDashboard({ data }: { data: DashboardData }) {
  const isMultiRole = data.activeRoles.length > 1;
  const [selectedTab, setSelectedTab] = useState<"all" | CanonicalRoleCode>(
    data.activeRoles.length === 1 ? data.activeRoles[0] : "all"
  );

  if (data.activeRoles.length === 0) {
    return (
      <section className="admin-panel" aria-label="Menunggu penetapan peran">
        <h2>Akun Disetujui — Menunggu Penetapan Peran</h2>
        <p className="rbac-meta">
          Akun Anda atas nama <strong>{data.userName}</strong> sudah disetujui, namun belum memiliki peran
          operasional aktif. Hubungi Super Admin untuk menetapkan peran dan cakupan proyek Anda.
        </p>
        <div className="admin-inline">
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/auth/pending">
            Lihat Status Akun
          </Link>
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/notifications">
            Buka Notifikasi ({data.unreadNotifications})
          </Link>
        </div>
      </section>
    );
  }

  return (
    <div className="admin-section">
      <section className="admin-panel" aria-label="Ringkasan Pengguna">
        <div className="admin-item-header">
          <div>
            <h2>Selamat datang, {data.userName}</h2>
            <p className="rbac-meta">
              {isMultiRole
                ? `Anda memiliki ${data.activeRoles.length} peran aktif. Pilih tampilan tugas di bawah ini.`
                : `Menampilkan ringkasan tugas untuk peran ${ROLE_META[data.activeRoles[0]].label}.`}
            </p>
          </div>
          <Link className="auth-button auth-button-secondary admin-btn-sm" href="/notifications">
            Notifikasi Belum Dibaca ({data.unreadNotifications})
          </Link>
        </div>

        {isMultiRole ? (
          <div className="admin-inline" role="tablist" aria-label="Pilih Tampilan Peran">
            <button
              type="button"
              role="tab"
              aria-selected={selectedTab === "all"}
              className={`auth-button admin-btn-sm ${
                selectedTab === "all" ? "" : "auth-button-secondary"
              }`}
              onClick={() => setSelectedTab("all")}
            >
              Ringkasan Semua Peran
            </button>
            {data.activeRoles.map((role) => (
              <button
                key={role}
                type="button"
                role="tab"
                aria-selected={selectedTab === role}
                className={`auth-button admin-btn-sm ${
                  selectedTab === role ? "" : "auth-button-secondary"
                }`}
                onClick={() => setSelectedTab(role)}
              >
                {ROLE_META[role].shortLabel}
              </button>
            ))}
          </div>
        ) : null}
      </section>

      {selectedTab === "all" && isMultiRole ? (
        <div className="admin-grid">
          {data.activeRoles.map((role) => (
            <article key={role} className="admin-panel">
              <div className="admin-item-header">
                <h3>{ROLE_META[role].label}</h3>
                <span className="status-badge status-badge-approved">PERAN AKTIF</span>
              </div>
              <p className="rbac-meta">{ROLE_META[role].description}</p>
              <p className="rbac-meta">
                <strong>Ringkasan:</strong> {getSummaryMetricForRole(role, data)}
              </p>
              <div className="admin-inline">
                <button
                  type="button"
                  className="auth-button admin-btn-sm"
                  onClick={() => setSelectedTab(role)}
                >
                  Buka Panel {ROLE_META[role].shortLabel}
                </button>
                <Link
                  className="auth-button auth-button-secondary admin-btn-sm"
                  href={ROLE_META[role].primaryHref}
                >
                  {ROLE_META[role].primaryCta}
                </Link>
              </div>
            </article>
          ))}
        </div>
      ) : (
        renderRoleSection(selectedTab === "all" ? data.activeRoles[0] : selectedTab, data)
      )}
    </div>
  );
}
