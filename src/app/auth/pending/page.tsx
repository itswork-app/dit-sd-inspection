import Link from "next/link";
import { redirect } from "next/navigation";
import { signOutAction } from "@/app/auth/actions";
import { AccountRequestForm } from "@/app/auth/pending/account-request-form";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

type PendingPageProps = {
  searchParams: Promise<{ error?: string }>;
};

const REJECTION_CATEGORY_LABELS: Record<string, string> = {
  UNVERIFIED_IDENTITY: "Identitas belum terverifikasi",
  OUT_OF_SCOPE_PERSONNEL: "Di luar cakupan personel inspeksi",
  DUPLICATE_ACCOUNT: "Akun duplikat",
  INCOMPLETE_INFORMATION: "Informasi permintaan belum lengkap",
  POLICY_RESTRICTION: "Pembatasan kebijakan akses"
};

export default async function PendingAccessPage({ searchParams }: PendingPageProps) {
  const identity = await getVerifiedIdentity();
  const params = await searchParams;

  if (identity.status === "unauthenticated") redirect("/login?error=session");

  let snapshot: Awaited<ReturnType<typeof loadSelfAccountSnapshot>> | null = null;
  if (identity.status === "authenticated") {
    try {
      const supabase = await createClient();
      snapshot = await loadSelfAccountSnapshot(supabase, identity.actorId);
    } catch {
      snapshot = { status: "error" };
    }
  }

  const latestRequest = snapshot?.status === "ok" ? snapshot.requests[0] ?? null : null;
  const latestDecision = snapshot?.status === "ok" ? snapshot.decisions[0] ?? null : null;
  const activeRoles =
    snapshot?.status === "ok"
      ? snapshot.roles.filter((role) => role.status === "ACTIVE")
      : [];
  const activeScopes =
    snapshot?.status === "ok"
      ? snapshot.scopes.filter((scope) => scope.status === "ACTIVE")
      : [];

  return (
    <main className="workspace auth-workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span>
            <strong>Dit. SD Inspection</strong>
            <small>Digital inspection workspace</small>
          </span>
        </Link>
        <span className="environment-pill">
          {snapshot?.status === "ok" && snapshot.user
            ? `ACCOUNT · ${snapshot.user.account_status}`
            : "ACCOUNT STATUS"}
        </span>
      </header>

      <section className="auth-panel" aria-labelledby="pending-title">
        {identity.status !== "authenticated" ? (
          <>
            <p className="eyebrow">AUTHENTICATION SERVICE</p>
            <h1 id="pending-title">Layanan identitas sementara tidak tersedia</h1>
            <p className="auth-description">
              Status sesi tidak dapat diverifikasi saat ini. Tidak ada akses operasional yang
              diberikan. Silakan coba kembali beberapa saat lagi.
            </p>
            <Link className="auth-link" href="/login">
              Kembali ke halaman login
            </Link>
          </>
        ) : !snapshot || snapshot.status !== "ok" ? (
          <>
            <p className="eyebrow">IDENTITY VERIFIED</p>
            <h1 id="pending-title">Akses operasional belum aktif</h1>
            <p className="auth-description">
              Identitas Google berhasil diverifikasi dan sesi server telah dibuat. Layanan status
              akun RBAC belum tersedia pada basis data lingkungan ini, sehingga aplikasi tetap
              menolak akses operasional secara default.
            </p>
            <p className="auth-note">
              Login tidak memberikan role atau hak akses operasional secara otomatis.
            </p>
          </>
        ) : !snapshot.user ? (
          <>
            <p className="eyebrow">IDENTITY VERIFIED · REQUEST ACCESS</p>
            <h1 id="pending-title">Ajukan persetujuan akun</h1>
            <p className="auth-description">
              Identitas Google Anda telah terverifikasi. Untuk mendapatkan akses operasional,
              ajukan permintaan akun terlebih dahulu agar ditinjau oleh Super Admin.
            </p>
            <AccountRequestForm mode="initial" />
            <p className="auth-note">
              Pengajuan akun hanya membuat permintaan berstatus PENDING. Role dan cakupan akses
              ditetapkan secara terpisah setelah akun disetujui.
            </p>
          </>
        ) : snapshot.user.account_status === "PENDING" ? (
          <>
            <p className="eyebrow">APPROVAL PENDING</p>
            <h1 id="pending-title">Menunggu persetujuan akun</h1>
            <p className="auth-description">
              Permintaan akses atas nama <strong>{snapshot.user.display_name}</strong> sedang
              menunggu peninjauan oleh Super Admin. Akses operasional tetap terkunci hingga akun
              disetujui dan role ditetapkan.
            </p>
            {latestRequest ? (
              <div className="rbac-card">
                <p className="rbac-meta">
                  <strong>Status permintaan:</strong> {latestRequest.status}
                </p>
                <p className="rbac-meta">
                  <strong>Diajukan pada:</strong>{" "}
                  {new Date(latestRequest.requested_at).toLocaleString("id-ID")}
                </p>
                {latestRequest.request_note ? (
                  <p className="rbac-meta">
                    <strong>Catatan:</strong> {latestRequest.request_note}
                  </p>
                ) : null}
              </div>
            ) : null}
          </>
        ) : snapshot.user.account_status === "REJECTED" ? (
          <>
            <p className="eyebrow">REQUEST REJECTED</p>
            <h1 id="pending-title">Permintaan akses ditolak</h1>
            <p className="auth-description">
              Permintaan akun sebelumnya belum dapat disetujui. Riwayat keputusan tersimpan secara
              permanen dan Anda dapat mengajukan permintaan ulang dengan informasi yang diperbarui.
            </p>
            {latestDecision ? (
              <div className="rbac-card rbac-card-warn">
                <p className="rbac-meta">
                  <strong>Kategori:</strong>{" "}
                  {latestDecision.rejection_category
                    ? (REJECTION_CATEGORY_LABELS[latestDecision.rejection_category] ??
                      latestDecision.rejection_category)
                    : "-"}
                </p>
                <p className="rbac-meta">
                  <strong>Alasan:</strong> {latestDecision.reason}
                </p>
              </div>
            ) : null}
            <AccountRequestForm
              mode="reapply"
              initialDisplayName={snapshot.user.display_name}
            />
          </>
        ) : snapshot.user.account_status === "SUSPENDED" ||
          snapshot.user.account_status === "DISABLED" ? (
          <>
            <p className="eyebrow">ACCOUNT {snapshot.user.account_status}</p>
            <h1 id="pending-title">
              {snapshot.user.account_status === "SUSPENDED"
                ? "Akun sedang ditangguhkan"
                : "Akun dinonaktifkan"}
            </h1>
            <p className="auth-description">
              Akses operasional untuk <strong>{snapshot.user.display_name}</strong> saat ini tidak
              aktif. Hubungi Super Admin untuk peninjauan atau pengaktifan kembali akun.
            </p>
            {latestDecision ? (
              <div className="rbac-card rbac-card-warn">
                <p className="rbac-meta">
                  <strong>Keputusan terakhir:</strong> {latestDecision.decision}
                </p>
                <p className="rbac-meta">
                  <strong>Catatan:</strong> {latestDecision.reason}
                </p>
              </div>
            ) : null}
          </>
        ) : (
          <>
            <p className="eyebrow">ACCOUNT APPROVED</p>
            <h1 id="pending-title">Akun telah disetujui</h1>
            <p className="auth-description">
              Selamat datang, <strong>{snapshot.user.display_name}</strong>. Status akun Anda
              adalah <strong>APPROVED</strong>. Hak akses operasional mengikuti role dan cakupan
              eksplisit yang aktif di bawah ini.
            </p>
            <div className="rbac-card">
              <p className="rbac-meta">
                <strong>Role aktif ({activeRoles.length}):</strong>{" "}
                {activeRoles.length > 0
                  ? activeRoles
                      .map((role) =>
                        role.project_id
                          ? `${role.role_name} (Project ${role.project_id.slice(0, 8)}…)`
                          : `${role.role_name} (Global)`
                      )
                      .join(", ")
                  : "Belum ada role operasional yang ditetapkan"}
              </p>
              <p className="rbac-meta">
                <strong>Scope eksplisit aktif ({activeScopes.length}):</strong>{" "}
                {activeScopes.length > 0
                  ? activeScopes
                      .map((scope) => `${scope.scope_type}:${scope.scope_id.slice(0, 8)}…`)
                      .join(", ")
                  : "Belum ada scope eksplisit"}
              </p>
            </div>
            {snapshot.canManageIdentity ? (
              <div className="rbac-actions">
                <Link className="auth-button rbac-link-button" href="/admin/accounts">
                  Buka Manajemen Akun &amp; RBAC
                </Link>
              </div>
            ) : null}
          </>
        )}

        {identity.status === "authenticated" ? (
          <div className="rbac-footer-actions">
            {params.error === "signout" ? (
              <p className="auth-error" role="alert">
                Sesi belum berhasil diakhiri. Silakan coba kembali.
              </p>
            ) : null}
            <form action={signOutAction}>
              <button className="auth-button auth-button-secondary" type="submit">
                Keluar dari akun
              </button>
            </form>
          </div>
        ) : null}
      </section>

      <footer className="footer">
        <span>Dit. SD Inspection · I1/I2 Identity &amp; RBAC-003</span>
        <span>Access remains deny-by-default</span>
      </footer>
    </main>
  );
}
