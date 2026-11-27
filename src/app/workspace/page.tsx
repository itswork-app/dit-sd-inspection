import Link from "next/link";
import { redirect } from "next/navigation";
import { signOutAction } from "@/app/auth/actions";
import { WorkspacePanel } from "@/app/workspace/workspace-panel";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function OperationalWorkspacePage() {
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") redirect("/login?error=session");

  if (identity.status !== "authenticated") {
    return (
      <main className="workspace auth-workspace">
        <section className="auth-panel">
          <p className="eyebrow">SERVICE UNAVAILABLE</p>
          <h1>Layanan identitas tidak tersedia</h1>
          <Link className="auth-link" href="/login">
            Kembali ke halaman login
          </Link>
        </section>
      </main>
    );
  }

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    redirect("/auth/pending");
  }

  const selfSnapshot = await loadSelfAccountSnapshot(supabase, identity.actorId);
  if (selfSnapshot.status !== "ok" || !selfSnapshot.user || selfSnapshot.user.account_status !== "APPROVED") {
    redirect("/auth/pending");
  }

  const [projectsRes, sessionsRes, capacitiesRes, instrumentsRes, conflictsRes] = await Promise.all([
    supabase
      .from("projects")
      .select("id, code, name, status, timezone, row_version")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("sessions")
      .select("id, project_id, code, status, starts_at, ends_at, row_version")
      .order("starts_at", { ascending: false })
      .limit(100),
    supabase
      .from("project_capacity_settings")
      .select("project_id, inspector_cap, row_version")
      .limit(100),
    supabase
      .from("instruments")
      .select("id, instrument_type, code, name, status, row_version")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("unit_identity_conflicts")
      .select("id, instrument_type, serial_normalized, proposed_project_id, status, row_version")
      .order("created_at", { ascending: false })
      .limit(100)
  ]);

  const schemaMissing = Boolean(
    projectsRes.error || sessionsRes.error || capacitiesRes.error || instrumentsRes.error || conflictsRes.error
  );

  return (
    <main className="workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span>
            <strong>Dit. SD Inspection</strong>
            <small>Operational Workspace · Slice 2 (I2/I3)</small>
          </span>
        </Link>
        <div className="admin-inline">
          <Link className="auth-link" href="/inspections">
            Inspeksi
          </Link>
          <Link className="auth-link" href="/auth/pending">
            Status Akun
          </Link>
          {selfSnapshot.canManageIdentity ? (
            <Link className="auth-link" href="/admin/accounts">
              Admin RBAC
            </Link>
          ) : null}
          <form action={signOutAction}>
            <button className="auth-button auth-button-secondary admin-btn-sm" type="submit">
              Keluar
            </button>
          </form>
        </div>
      </header>

      {schemaMissing ? (
        <section className="auth-panel">
          <p className="eyebrow">SCHEMA UNAVAILABLE</p>
          <h1>Skema operasional belum aktif pada basis data ini</h1>
          <p className="auth-description">
            Basis data yang terhubung belum menjalankan migrasi domain Slice 2. Akses operasional
            tetap ditolak secara aman.
          </p>
          <Link className="auth-link" href="/auth/pending">
            Kembali ke status akun
          </Link>
        </section>
      ) : (
        <WorkspacePanel
          projects={(projectsRes.data ?? []).map((p) => ({ ...p, row_version: String(p.row_version) }))}
          sessions={(sessionsRes.data ?? []).map((s) => ({ ...s, row_version: String(s.row_version) }))}
          capacities={(capacitiesRes.data ?? []).map((c) => ({ ...c, row_version: String(c.row_version) }))}
          instruments={(instrumentsRes.data ?? []).map((i) => ({ ...i, row_version: String(i.row_version) }))}
          conflicts={(conflictsRes.data ?? []).map((c) => ({ ...c, row_version: String(c.row_version) }))}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · Projects, Sessions, Instruments &amp; Canonical Units</span>
        <span>Server &amp; PostgreSQL RLS enforced</span>
      </footer>
    </main>
  );
}
