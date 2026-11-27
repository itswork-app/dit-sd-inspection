import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminAccountsPanel } from "@/app/admin/accounts/admin-accounts-panel";
import { AppTopbar } from "@/components/app-topbar";
import { loadAdminAccountsSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function AdminAccountsPage() {
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") redirect("/login?error=session");

  let snapshot: Awaited<ReturnType<typeof loadAdminAccountsSnapshot>> = { status: "error" };
  if (identity.status === "authenticated") {
    try {
      const supabase = await createClient();
      snapshot = await loadAdminAccountsSnapshot(supabase, identity.actorId);
    } catch {
      snapshot = { status: "error" };
    }
  }

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="Administrasi Akun &amp; Peran"
        activePath="/admin/accounts"
        canManageIdentity={snapshot.status === "ok"}
      />

      {identity.status !== "authenticated" || snapshot.status === "schema_unavailable" || snapshot.status === "error" ? (
        <section className="auth-panel" aria-labelledby="admin-unavailable-title">
          <p className="eyebrow">SERVICE UNAVAILABLE</p>
          <h1 id="admin-unavailable-title">Layanan administrasi belum tersedia</h1>
          <p className="auth-description">
            Status otorisasi atau data akun tidak dapat diverifikasi pada lingkungan ini. Akses
            tetap ditolak secara default.
          </p>
          <Link className="auth-link" href="/auth/pending">
            Kembali ke halaman status akun
          </Link>
        </section>
      ) : snapshot.status === "forbidden" ? (
        <section className="auth-panel" aria-labelledby="admin-forbidden-title">
          <p className="eyebrow">403 · ACCESS DENIED</p>
          <h1 id="admin-forbidden-title">Akses administrasi ditolak</h1>
          <p className="auth-description">
            Akun Anda tidak memiliki izin Super Admin aktif untuk mengelola persetujuan akun, role,
            atau cakupan operasional.
          </p>
          <Link className="auth-link" href="/auth/pending">
            Kembali ke halaman status akun
          </Link>
        </section>
      ) : (
        <AdminAccountsPanel
          actorUserId={snapshot.actorUserId}
          users={snapshot.users}
          requests={snapshot.requests}
          decisions={snapshot.decisions}
          roleCatalog={snapshot.roleCatalog}
          userRoles={snapshot.userRoles}
          userScopes={snapshot.userScopes}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · Administrasi Akun &amp; Hak Akses</span>
        <span>Otorisasi terproteksi server</span>
      </footer>
    </main>
  );
}
