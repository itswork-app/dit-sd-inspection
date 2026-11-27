import Link from "next/link";
import { redirect } from "next/navigation";
import { OperationsPanel } from "@/app/operations/operations-panel";
import { AppTopbar } from "@/components/app-topbar";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function OperationsPage() {
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

  const [projectsRes, sessionsRes, locationsRes, docsRes, batchesRes, attRecRes, attDocRes] =
    await Promise.all([
      supabase.from("projects").select("id, code, name, status").order("created_at", { ascending: false }).limit(50),
      supabase.from("sessions").select("id, project_id, code, status").order("starts_at", { ascending: false }).limit(100),
      supabase.from("locations").select("id, project_id, code, name").order("created_at", { ascending: false }).limit(100),
      supabase
        .from("documents")
        .select("id, project_id, session_id, document_type, version_no, is_current, status, generated_at")
        .order("generated_at", { ascending: false })
        .limit(100),
      supabase
        .from("print_batches")
        .select("id, project_id, session_id, requested_count, status, created_at")
        .order("created_at", { ascending: false })
        .limit(30),
      supabase
        .from("attendance_records")
        .select("id, project_id, session_id, location_id, status, row_version, updated_at")
        .order("updated_at", { ascending: false })
        .limit(50),
      supabase
        .from("attendance_documents")
        .select("id, attendance_record_id, version_no, mime_type, byte_size, status, uploaded_at")
        .order("uploaded_at", { ascending: false })
        .limit(100)
    ]);

  const schemaMissing = Boolean(
    projectsRes.error || sessionsRes.error || docsRes.error || attRecRes.error
  );

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="Dokumen, Cetak, Absensi, Laporan & Audit"
        activePath="/operations"
        canManageIdentity={selfSnapshot.canManageIdentity}
      />

      {schemaMissing ? (
        <section className="auth-panel">
          <p className="eyebrow">SCHEMA UNAVAILABLE</p>
          <h1>Skema dokumen &amp; laporan belum aktif pada basis data ini</h1>
          <Link className="auth-link" href="/workspace">
            Kembali ke workspace
          </Link>
        </section>
      ) : (
        <OperationsPanel
          projects={projectsRes.data ?? []}
          sessions={sessionsRes.data ?? []}
          locations={locationsRes.data ?? []}
          documents={docsRes.data ?? []}
          printBatches={batchesRes.data ?? []}
          attendanceRecords={(attRecRes.data ?? []).map((r) => ({ ...r, row_version: String(r.row_version) }))}
          attendanceDocuments={attDocRes.data ?? []}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · Dokumen, Absensi &amp; Laporan Operasional</span>
        <span>Unduhan dokumen teraudit otomatis</span>
      </footer>
    </main>
  );
}
