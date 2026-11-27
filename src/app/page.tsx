import Link from "next/link";
import { isSupabaseConfigured } from "@/lib/env";

const foundationItems = [
  {
    number: "01",
    title: "Akses & Peran Terkontrol",
    description: "Autentikasi akun Google terverifikasi dengan persetujuan dan penetapan peran operasional."
  },
  {
    number: "02",
    title: "Inspeksi & Bukti Lapangan",
    description: "Scan QR/Barcode & OCR Nomor Seri, klaim unit, checklist cepat, dan unggah foto atau video kerusakan."
  },
  {
    number: "03",
    title: "Dokumen & Pelaporan",
    description: "Review hasil inspeksi, pembuatan Berita Acara PDF, absensi sesi, serta pantauan capaian target."
  }
];

export default function HomePage() {
  const supabaseConfigured = isSupabaseConfigured();

  return (
    <main className="workspace">
      <header className="topbar">
        <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
          <span className="brand-mark">SD</span>
          <span>
            <strong>Dit. SD Inspection</strong>
            <small>Portal Inspeksi Digital</small>
          </span>
        </Link>
        <Link className="auth-link" href="/login">Masuk</Link>
        <span className="environment-pill">
          <span className="status-dot" />
          OPERASIONAL
        </span>
      </header>

      <section className="hero">
        <p className="eyebrow">DIREKTORAT SEKOLAH DASAR</p>
        <h1>Operasional inspeksi,<br /><span>terpusat dan terstruktur.</span></h1>
        <p className="hero-copy">
          Sistem inspeksi lapangan terintegrasi mulai dari pengelolaan proyek, sesi pemeriksaan,
          klaim unit berbasis Nomor Seri, hingga dokumentasi dan penerbitan dokumen resmi.
        </p>
        <div className="hero-meta">
          <span className="meta-check"><span aria-hidden="true">✓</span> Layanan aplikasi siap</span>
          <span className={supabaseConfigured ? "meta-check" : "meta-pending"}>
            <span aria-hidden="true">{supabaseConfigured ? "✓" : "○"}</span>
            {supabaseConfigured
              ? "Koneksi basis data terkonfigurasi"
              : "Menunggu konfigurasi lingkungan basis data"}
          </span>
        </div>
      </section>

      <section className="foundation-section" aria-labelledby="foundation-title">
        <div className="section-heading">
          <div>
            <p className="eyebrow">ALUR UTAMA</p>
            <h2 id="foundation-title">Modul operasional inspeksi</h2>
          </div>
          <span className="section-note">Lingkungan kerja internal</span>
        </div>
        <div className="workstream-grid">
          {foundationItems.map((item) => (
            <article className="workstream-card" key={item.number}>
              <span className="card-number">{item.number}</span>
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </article>
          ))}
        </div>
      </section>

      <footer className="footer">
        <span>Direktorat Sekolah Dasar · Sistem Inspeksi Digital</span>
        <span>Portal Kerja Operasional</span>
      </footer>
    </main>
  );
}
