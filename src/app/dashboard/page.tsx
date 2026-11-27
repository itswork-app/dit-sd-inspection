import Link from "next/link";
import { redirect } from "next/navigation";
import { RoleDashboard, type DashboardData, type DashboardQueueUnit } from "@/app/dashboard/role-dashboard";
import { AppTopbar } from "@/components/app-topbar";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { extractActiveRoles } from "@/lib/auth/roles";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function RoleDashboardPage() {
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") redirect("/login?error=session");

  if (identity.status !== "authenticated") {
    return (
      <main className="workspace auth-workspace">
        <section className="auth-panel">
          <p className="eyebrow">SERVICE UNAVAILABLE</p>
          <h1>Layanan identitas sementara tidak tersedia</h1>
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

  const activeRoles = extractActiveRoles(selfSnapshot.roles);
  const roleSet = new Set(activeRoles);

  const needsProjects = roleSet.has("super_admin") || roleSet.has("admin") || roleSet.has("korlap");
  const needsInspections =
    roleSet.has("inspector") ||
    roleSet.has("reviewer") ||
    roleSet.has("print_officer") ||
    roleSet.has("korlap") ||
    roleSet.has("super_admin") ||
    roleSet.has("admin");
  const needsDocs = roleSet.has("print_officer") || roleSet.has("super_admin") || roleSet.has("admin");

  const [
    notifRes,
    pendingReqRes,
    approvedUsersRes,
    projectsRes,
    sessionsRes,
    assignmentsRes,
    conflictsRes,
    claimsRes,
    abortsRes,
    attendanceRes,
    inspectionsRes,
    unitsRes,
    docsRes,
    batchesRes
  ] = await Promise.all([
    supabase.from("notifications").select("id").is("read_at", null).limit(100),
    roleSet.has("super_admin")
      ? supabase
          .from("account_requests")
          .select("id, requested_display_name, requested_at")
          .eq("status", "PENDING")
          .order("requested_at", { ascending: false })
          .limit(20)
      : Promise.resolve({ data: [] }),
    roleSet.has("super_admin")
      ? supabase.from("app_users").select("id").eq("account_status", "APPROVED").limit(200)
      : Promise.resolve({ data: [] }),
    needsProjects
      ? supabase.from("projects").select("id, status").limit(100)
      : Promise.resolve({ data: [] }),
    needsProjects
      ? supabase.from("sessions").select("id, status").limit(200)
      : Promise.resolve({ data: [] }),
    roleSet.has("admin") || roleSet.has("inspector")
      ? supabase.from("operational_assignments").select("id").eq("status", "PUBLISHED").limit(200)
      : Promise.resolve({ data: [] }),
    roleSet.has("admin")
      ? supabase.from("unit_identity_conflicts").select("id").eq("status", "OPEN").limit(100)
      : Promise.resolve({ data: [] }),
    roleSet.has("korlap") || roleSet.has("inspector")
      ? supabase.from("unit_claims").select("id").eq("status", "ACTIVE").limit(200)
      : Promise.resolve({ data: [] }),
    roleSet.has("korlap")
      ? supabase.from("inspection_abort_requests").select("id").eq("status", "PENDING").limit(100)
      : Promise.resolve({ data: [] }),
    roleSet.has("korlap") || roleSet.has("reviewer")
      ? supabase.from("attendance_records").select("id, status").limit(100)
      : Promise.resolve({ data: [] }),
    needsInspections
      ? supabase
          .from("inspections")
          .select("id, unit_id, status, current_revision_no, updated_at")
          .order("updated_at", { ascending: false })
          .limit(200)
      : Promise.resolve({ data: [] }),
    needsInspections
      ? supabase
          .from("units")
          .select("id, instrument_type, serial_raw, serial_normalized")
          .order("created_at", { ascending: false })
          .limit(200)
      : Promise.resolve({ data: [] }),
    needsDocs
      ? supabase
          .from("documents")
          .select("id, document_type, version_no, is_current, generated_at")
          .eq("is_current", true)
          .order("generated_at", { ascending: false })
          .limit(50)
      : Promise.resolve({ data: [] }),
    roleSet.has("print_officer")
      ? supabase.from("print_batches").select("id").limit(100)
      : Promise.resolve({ data: [] })
  ]);

  const unitById = new Map(
    (unitsRes.data ?? []).map((u) => [
      u.id,
      {
        serial: u.serial_normalized ?? u.serial_raw ?? u.id.slice(0, 8),
        instrumentType: u.instrument_type
      }
    ])
  );

  const mapQueue = (
    rows: Array<{ id: string; unit_id: string; status: string; current_revision_no: number; updated_at: string }>
  ): DashboardQueueUnit[] =>
    rows.slice(0, 5).map((r) => {
      const unit = unitById.get(r.unit_id);
      return {
        id: r.id,
        serial: unit?.serial ?? r.unit_id.slice(0, 8),
        instrumentType: unit?.instrumentType ?? "UNIT",
        status: r.status,
        revisionNo: r.current_revision_no,
        updatedAt: r.updated_at
      };
    });

  const inspections = inspectionsRes.data ?? [];
  const draftList = inspections.filter((i) => i.status === "DRAFT" || i.status === "REOPENED");
  const returnedList = inspections.filter((i) => i.status === "RETURNED");
  const submittedList = inspections.filter((i) => i.status === "SUBMITTED");
  const approvedList = inspections.filter((i) => i.status === "APPROVED");

  const projects = projectsRes.data ?? [];
  const sessions = sessionsRes.data ?? [];
  const attendance = attendanceRes.data ?? [];
  const docs = docsRes.data ?? [];

  const data: DashboardData = {
    userName: selfSnapshot.user.display_name,
    activeRoles,
    unreadNotifications: (notifRes.data ?? []).length,
    pendingAccountsCount: (pendingReqRes.data ?? []).length,
    pendingAccounts: (pendingReqRes.data ?? []).slice(0, 5).map((r) => ({
      id: r.id,
      displayName: r.requested_display_name,
      requestedAt: r.requested_at
    })),
    approvedUsersCount: (approvedUsersRes.data ?? []).length,
    activeProjectsCount: projects.filter((p) => p.status === "ACTIVE").length,
    activeSessionsCount: sessions.filter((s) => s.status === "ACTIVE").length,
    draftSessionsCount: sessions.filter((s) => s.status === "DRAFT").length,
    publishedAssignmentsCount: (assignmentsRes.data ?? []).length,
    openConflictsCount: (conflictsRes.data ?? []).length,
    activeClaimsCount: (claimsRes.data ?? []).length,
    pendingAbortsCount: (abortsRes.data ?? []).length,
    unverifiedAttendanceCount: attendance.filter((a) => a.status !== "VERIFIED").length,
    draftInspectionsCount: draftList.length,
    returnedInspectionsCount: returnedList.length,
    submittedInspectionsCount: submittedList.length,
    approvedInspectionsCount: approvedList.length,
    currentDocsCount: docs.length,
    printBatchesCount: (batchesRes.data ?? []).length,
    myFieldQueue: mapQueue([...returnedList, ...draftList]),
    submittedQueue: mapQueue(submittedList),
    approvedForPrintQueue: mapQueue(approvedList),
    currentDocs: docs.slice(0, 5).map((d) => ({
      id: d.id,
      documentType: d.document_type,
      versionNo: d.version_no,
      generatedAt: d.generated_at
    }))
  };

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="Dashboard Tugas Berdasarkan Peran"
        activePath="/dashboard"
        activeRoles={activeRoles}
        canManageIdentity={selfSnapshot.canManageIdentity}
      />

      <RoleDashboard data={data} />

      <footer className="footer">
        <span>Dit. SD Inspection · Dashboard Operasional</span>
        <span>Hak akses &amp; menu mengikuti peran aktif Anda</span>
      </footer>
    </main>
  );
}
