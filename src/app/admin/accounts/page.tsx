import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminAccountsPanel } from "@/app/admin/accounts/admin-accounts-panel";
import { signOutAction } from "@/app/auth/actions";
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
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span>
            <strong>Dit. SD Inspection</strong>
            <small>Identity &amp; RBAC Administration</small>
          </span>
        </Link>
        <div className="admin-inline">
          <Link className="auth-link" href="/auth/pending">
            Status Akun
          </Link>
          <form action={signOutAction}>
            <button className="auth-button auth-button-secondary admin-btn-sm" type="submit">
              Keluar
            </button>
          </form>
        </div>
      </header>

      {identity.status !== "authenticated" || snapshot.status === "schema_unavailable" || snapshot.status === "error" ? (
        <section className="auth-panel" aria-labelledby="admin-unavailable-title">
          <p className="eyebrow">SERVICE UNAVAILABLE</p>
          <h1 id="admin-unavailable-title">Layanan administrasi belum tersedia</h1>
          <p className="auth-description">
            Status otorisasi atau skema RBAC tidak dapat diverifikasi pada lingkungan ini. Akses
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
        <span>Dit. SD Inspection · RBAC-003 Command Runtime (CMD-001..007)</span>
        <span>Server &amp; PostgreSQL RLS enforced</span>
      </footer>
    </main>
  );
}
