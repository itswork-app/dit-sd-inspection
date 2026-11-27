import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

function redirectTo(request: NextRequest, path: string) {
  return NextResponse.redirect(new URL(path, request.url), {
    headers: { "Cache-Control": "no-store", "Referrer-Policy": "no-referrer" }
  });
}

/** Exchange the one-time OAuth authorization code for a server-managed session. */
export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  if (!code) return redirectTo(request, "/login?error=oauth_callback");

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (error) return redirectTo(request, "/login?error=oauth_callback");
    return redirectTo(request, "/auth/pending");
  } catch {
    return redirectTo(request, "/login?error=oauth_callback");
  }
}
