import Link from "next/link";
import { isSupabaseConfigured } from "@/lib/env";
import { GoogleSignInButton } from "./google-sign-in-button";

export default function LoginPage() {
  return (
    <main className="workspace auth-workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span><strong>Dit. SD Inspection</strong><small>Digital inspection workspace</small></span>
        </Link>
        <span className="environment-pill">SECURE SIGN-IN</span>
      </header>
      <section className="auth-panel" aria-labelledby="login-title">
        <p className="eyebrow">ACCOUNT ACCESS</p>
        <h1 id="login-title">Masuk ke workspace</h1>
        <p className="auth-description">Gunakan akun Google yang ditetapkan untuk pekerjaan inspeksi Direktorat Sekolah Dasar.</p>
        <GoogleSignInButton configured={isSupabaseConfigured()} />
        <p className="auth-note">Login hanya memverifikasi identitas. Akun baru tetap memerlukan persetujuan dan penetapan role sebelum akses operasional diberikan.</p>
      </section>
      <footer className="footer"><span>Dit. SD Inspection · Development foundation</span><span><Link href="/">Kembali ke beranda</Link></span></footer>
    </main>
  );
}
