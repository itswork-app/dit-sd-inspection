import Link from "next/link";
import { redirect } from "next/navigation";
import { NotificationsAndDocsPanel } from "@/app/notifications/notifications-docs-panel";
import { AppTopbar } from "@/components/app-topbar";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function NotificationsAndDocumentsPage() {
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

  // POQ-03: intentionally NEVER select dismissed_at!
  const [notifRes, docsRes] = await Promise.all([
    supabase
      .from("notifications")
      .select("id, event_type, priority, title_key, body_key, created_at, read_at")
      .order("created_at", { ascending: false })
      .limit(50),
    supabase
      .from("documents")
      .select("id, document_type, version_no, is_current, status, generated_at")
      .order("generated_at", { ascending: false })
      .limit(50)
  ]);

  const schemaMissing = Boolean(notifRes.error || docsRes.error);

  return (
    <main className="workspace">
      <AppTopbar
        subtitle="In-App Notifications, Documents & Print (POQ-03)"
        activePath="/notifications"
        canManageIdentity={selfSnapshot.canManageIdentity}
      />

      {schemaMissing ? (
        <section className="auth-panel">
          <p className="eyebrow">SCHEMA UNAVAILABLE</p>
          <h1>Skema dokumen &amp; notifikasi Slice 4 belum aktif</h1>
          <Link className="auth-link" href="/workspace">
            Kembali ke workspace
          </Link>
        </section>
      ) : (
        <NotificationsAndDocsPanel
          notifications={notifRes.data ?? []}
          documents={docsRes.data ?? []}
        />
      )}

      <footer className="footer">
        <span>Dit. SD Inspection · 62/62 Tables · CMD-036..043 &amp; CMD-049..051</span>
        <span>CMD-044 &amp; external CMD-053 disabled until T-10/T-12</span>
      </footer>
    </main>
  );
}
