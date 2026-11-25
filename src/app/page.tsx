import Link from "next/link";
import { isSupabaseConfigured } from "@/lib/env";

const foundationItems = [
  {
    number: "01",
    title: "Application shell",
    description: "Next.js App Router, strict TypeScript, responsive layout and health endpoint."
  },
  {
    number: "02",
    title: "Identity boundary",
    description: "Supabase SSR client separation and verified-claims session refresh."
  },
  {
    number: "03",
    title: "Delivery pipeline",
    description: "Configured lint, type, unit-test and production-build quality checks."
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
            <small>Digital inspection workspace</small>
          </span>
        </Link>
        <Link className="auth-link" href="/login">Sign in</Link>
        <span className="environment-pill">
          <span className="status-dot" />
          FOUNDATION
        </span>
      </header>

      <section className="hero">
        <p className="eyebrow">ENGINEERING FOUNDATION · PHASE I0</p>
        <h1>Inspection operations,<br /><span>built on a reliable core.</span></h1>
        <p className="hero-copy">
          Fondasi aplikasi telah disiapkan. Identitas, batas keamanan, database,
          dan alur inspeksi akan dibangun bertahap di atas satu sumber data yang konsisten.
        </p>
        <div className="hero-meta">
          <span className="meta-check"><span aria-hidden="true">✓</span> Application shell loaded</span>
          <span className={supabaseConfigured ? "meta-check" : "meta-pending"}>
            <span aria-hidden="true">{supabaseConfigured ? "✓" : "○"}</span>
            Supabase environment {supabaseConfigured ? "configured" : "awaiting development credentials"}
          </span>
        </div>
      </section>

      <section className="foundation-section" aria-labelledby="foundation-title">
        <div className="section-heading">
          <div>
            <p className="eyebrow">BUILD SEQUENCE</p>
            <h2 id="foundation-title">Foundation workstreams</h2>
          </div>
          <span className="section-note">No production data connected</span>
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
        <span>Direktorat Sekolah Dasar · Internal application foundation</span>
        <span>Development workspace</span>
      </footer>
    </main>
  );
}
