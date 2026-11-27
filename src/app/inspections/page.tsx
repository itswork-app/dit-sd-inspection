import Link from "next/link";
import { redirect } from "next/navigation";
import { InspectionsPanel } from "@/app/inspections/inspections-panel";
import { AppTopbar } from "@/components/app-topbar";
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

  const [
    inspRes,
    claimsRes,
    revRes,
    abortRes,
    evRes,
    slotsRes,
    tmplRes,
    devRes,
    secRes,
    itemRes,
    specRes,
    draftCtxRes,
    assignRes,
    instRes,
    unitsRes
  ] = await Promise.all([
    supabase
      .from("inspections")
      .select("id, unit_id, project_id, session_id, instrument_version_id, status, current_revision_no, row_version, updated_at")
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
      .limit(50),
    supabase
      .from("evidence_assets")
      .select("id, inspection_id, slot_definition_id, mime_type, observed_byte_size, expected_byte_size, upload_status, created_at")
      .order("created_at", { ascending: false })
      .limit(200),
    supabase
      .from("evidence_slot_definitions")
      .select("id, instrument_version_id, code, label, required")
      .order("sort_order", { ascending: true })
      .limit(200),
    supabase
      .from("document_template_versions")
      .select("id, document_type, template_key, version_no, status")
      .eq("status", "ACTIVE")
      .order("version_no", { ascending: false })
      .limit(50),
    supabase
      .from("device_bindings")
      .select("id, label, status, bound_at")
      .eq("status", "ACTIVE")
      .order("bound_at", { ascending: false })
      .limit(20),
    supabase
      .from("checklist_sections")
      .select("id, instrument_version_id, code, label, sort_order")
      .order("sort_order", { ascending: true })
      .limit(200),
    supabase
      .from("checklist_items")
      .select("id, section_id, code, label, answer_type, required, sort_order")
      .order("sort_order", { ascending: true })
      .limit(500),
    supabase
      .from("specification_fields")
      .select("id, instrument_version_id, code, label, value_type, expected_value, unit, required, sort_order")
      .order("sort_order", { ascending: true })
      .limit(200),
    supabase
      .from("inspection_draft_contexts")
      .select("inspection_id, draft_checklist, draft_specifications, notes")
      .limit(100),
    supabase
      .from("operational_assignments")
      .select("id, project_id, session_id, instrument_id, instrument_version_id, status")
      .eq("status", "PUBLISHED")
      .limit(100),
    supabase
      .from("instruments")
      .select("id, code, name, instrument_type")
      .limit(100),
    supabase
      .from("units")
      .select("id, instrument_type, serial_raw, serial_normalized")
      .order("created_at", { ascending: false })
      .limit(200)
  ]);

  const schemaMissing = Boolean(inspRes.error || claimsRes.error || revRes.error || abortRes.error);

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="Scan Serial, Checklist Lapangan & Bukti Foto/Video"
        activePath="/inspections"
        canManageIdentity={selfSnapshot.canManageIdentity}
      />

      {schemaMissing ? (
        <section className="auth-panel">
          <p className="eyebrow">SCHEMA UNAVAILABLE</p>
          <h1>Skema inspeksi belum aktif pada basis data ini</h1>
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
          evidenceAssets={evRes.data ?? []}
          evidenceSlots={slotsRes.data ?? []}
          documentTemplates={tmplRes.data ?? []}
          activeDevices={devRes.data ?? []}
          checklistSections={secRes.data ?? []}
          checklistItems={itemRes.data ?? []}
          specFields={specRes.data ?? []}
          draftContexts={(draftCtxRes.data ?? []).map((d) => ({
            inspection_id: d.inspection_id,
            draft_checklist: (d.draft_checklist ?? {}) as Record<string, unknown>,
            draft_specifications: (d.draft_specifications ?? {}) as Record<string, unknown>,
            notes: d.notes ?? null
          }))}
          assignments={assignRes.data ?? []}
          instruments={instRes.data ?? []}
          units={unitsRes.data ?? []}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · Pemeriksaan Unit &amp; Sinkronisasi Offline</span>
        <span>Penyimpanan bukti privat terenkripsi</span>
      </footer>
    </main>
  );
}
