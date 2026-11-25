import Link from "next/link";
import { redirect } from "next/navigation";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { signOutAction } from "@/app/auth/actions";

type PendingPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function PendingAccessPage({ searchParams }: PendingPageProps) {
  const identity = await getVerifiedIdentity();
  const params = await searchParams;

  if (identity.status === "unauthenticated") redirect("/login?error=session");

  return (
    <main className="workspace auth-workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span><strong>Dit. SD Inspection</strong><small>Digital inspection workspace</small></span>
        </Link>
        <span className="environment-pill">ACCOUNT STATUS</span>
      </header>
      <section className="auth-panel" aria-labelledby="pending-title">
        {identity.status === "authenticated" ? (
          <>
            <p className="eyebrow">IDENTITY VERIFIED</p>
            <h1 id="pending-title">Akses operasional belum aktif</h1>
            <p className="auth-description">Identitas Google berhasil diverifikasi dan sesi server telah dibuat. Mekanisme persetujuan akun dan penetapan role belum diintegrasikan ke fondasi ini, sehingga aplikasi belum dapat menetapkan hak akses operasional.</p>
            <p className="auth-note">Login tidak memberikan role atau hak akses operasional secara otomatis.</p>
            {params.error === "signout" ? <p className="auth-error" role="alert">Sesi belum berhasil diakhiri. Silakan coba kembali.</p> : null}
            <form action={signOutAction}><button className="auth-button auth-button-secondary" type="submit">Keluar dari akun</button></form>
          </>
        ) : (
          <>
            <p className="eyebrow">AUTHENTICATION SERVICE</p>
            <h1 id="pending-title">Layanan identitas sementara tidak tersedia</h1>
            <p className="auth-description">Status sesi tidak dapat diverifikasi saat ini. Tidak ada akses operasional yang diberikan. Silakan coba kembali beberapa saat lagi.</p>
            <Link className="auth-link" href="/login">Kembali ke halaman login</Link>
          </>
        )}
      </section>
      <footer className="footer"><span>Dit. SD Inspection · Development foundation</span><span>Access remains deny-by-default</span></footer>
    </main>
  );
}
