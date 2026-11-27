"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export function GoogleSignInButton({ configured }: { configured: boolean }) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function signIn() {
    setError(null);
    if (!configured) {
      setError("Login belum tersedia. Konfigurasi Supabase development belum lengkap.");
      return;
    }

    setPending(true);
    try {
      const supabase = createClient();
      const { error: authError } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: { redirectTo: `${window.location.origin}/auth/callback` }
      });

      if (authError) {
        setError("Login Google belum dapat dimulai. Silakan coba kembali.");
        setPending(false);
      }
    } catch {
      setError("Layanan login sementara tidak tersedia.");
      setPending(false);
    }
  }

  return (
    <div className="auth-control">
      <button className="auth-button" type="button" onClick={signIn} disabled={pending || !configured}>
        {pending ? "Menghubungkan ke Google…" : "Lanjutkan dengan Google"}
      </button>
      {error ? <p className="auth-error" role="alert">{error}</p> : null}
      {!configured ? <p className="auth-note">Supabase URL dan publishable key development perlu dikonfigurasi terlebih dahulu.</p> : null}
    </div>
  );
}
