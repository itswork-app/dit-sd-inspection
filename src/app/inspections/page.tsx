import Link from "next/link";
import { redirect } from "next/navigation";
import { signOutAction } from "@/app/auth/actions";
import { InspectionsPanel } from "@/app/inspections/inspections-panel";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function InspectionsPage() {
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") redirect("/login?error=session");
  if (identity.status !== "authenticated") redirect("/auth/pending");

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

  const [inspRes, claimsRes, revRes, abortRes] = await Promise.all([
    supabase
      .from("inspections")
      .select("id, unit_id, project_id, status, current_revision_no, row_version, updated_at")
      .order("updated_at", { ascending: false })
      .limit(100),
    supabase
      .from("unit_claims")
      .select("id, unit_id, status, expires_at, row_version")
      .eq("status", "ACTIVE")
      .limit(100),
    supabase
      .from("inspection_revisions")
      .select("id, inspection_id, revision_no, submitted_at")
      .order("submitted_at", { ascending: false })
      .limit(200),
    supabase
      .from("inspection_abort_requests")
      .select("id, inspection_id, status, request_reason, row_version")
      .order("requested_at", { ascending: false })
      .limit(50)
  ]);

  const schemaMissing = Boolean(inspRes.error || claimsRes.error || revRes.error || abortRes.error);

  return (
    <main className="workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span>
            <strong>Dit. SD Inspection</strong>
            <small>Field Inspections, Claims, Review &amp; SES-001</small>
          </span>
        </Link>
        <div className="admin-inline">
          <Link className="auth-link" href="/workspace">
            Workspace
          </Link>
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

      {schemaMissing ? (
        <section className="auth-panel">
          <p className="eyebrow">SCHEMA UNAVAILABLE</p>
          <h1>Skema inspeksi Slice 3 belum aktif pada basis data ini</h1>
          <Link className="auth-link" href="/workspace">
            Kembali ke workspace
          </Link>
        </section>
      ) : (
        <InspectionsPanel
          inspections={(inspRes.data ?? []).map((i) => ({ ...i, row_version: String(i.row_version) }))}
          activeClaims={(claimsRes.data ?? []).map((c) => ({ ...c, row_version: String(c.row_version) }))}
          revisions={revRes.data ?? []}
          abortRequests={(abortRes.data ?? []).map((a) => ({ ...a, row_version: String(a.row_version) }))}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · CMD-026..035 &amp; SES-001 (CMD-055..056)</span>
        <span>Server &amp; PostgreSQL RLS enforced</span>
      </footer>
    </main>
  );
}
