import Link from "next/link";
import { redirect } from "next/navigation";
import { WorkspacePanel } from "@/app/workspace/workspace-panel";
import { AppTopbar } from "@/components/app-topbar";
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

  const [
    projectsRes,
    sessionsRes,
    capacitiesRes,
    instrumentsRes,
    conflictsRes,
    locationsRes,
    teamsRes,
    versionsRes,
    assignmentsRes,
    usersRes,
    unitsRes,
    assocRes
  ] = await Promise.all([
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
      .limit(100),
    supabase
      .from("locations")
      .select("id, project_id, code, name, status")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("teams")
      .select("id, project_id, code, name, status")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("instrument_versions")
      .select("id, instrument_id, version_number, status, draft_hash")
      .order("version_number", { ascending: false })
      .limit(100),
    supabase
      .from("operational_assignments")
      .select("id, project_id, session_id, location_id, instrument_id, instrument_version_id, team_id, status")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("app_users")
      .select("id, display_name, account_status")
      .eq("account_status", "APPROVED")
      .order("display_name", { ascending: true })
      .limit(200),
    supabase
      .from("units")
      .select("id, instrument_type, serial_raw, serial_normalized")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("unit_project_associations")
      .select("id, unit_id, project_id, status")
      .eq("status", "ACTIVE")
      .limit(200)
  ]);

  const schemaMissing = Boolean(
    projectsRes.error || sessionsRes.error || capacitiesRes.error || instrumentsRes.error || conflictsRes.error
  );

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="Operational Workspace · Projects, Sessions, Instruments & Units"
        activePath="/workspace"
        canManageIdentity={selfSnapshot.canManageIdentity}
      />

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
          locations={locationsRes.data ?? []}
          teams={teamsRes.data ?? []}
          instrumentVersions={versionsRes.data ?? []}
          assignments={assignmentsRes.data ?? []}
          approvedUsers={usersRes.data ?? []}
          units={unitsRes.data ?? []}
          unitAssociations={assocRes.data ?? []}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · Projects, Sessions, Instruments &amp; Canonical Units</span>
        <span>Server &amp; PostgreSQL RLS enforced</span>
      </footer>
    </main>
  );
}
