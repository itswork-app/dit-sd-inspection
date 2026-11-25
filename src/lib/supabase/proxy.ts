import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { readSupabasePublicConfig } from "@/lib/env";
import { getRequestId } from "@/lib/api/errors";
import { logEvent } from "@/lib/observability/logger";

export async function updateSession(request: NextRequest) {
  const config = readSupabasePublicConfig(process.env);

  // No protected routes exist in foundation mode. Auth becomes mandatory before
  // any protected route or business command is introduced.
  if (!config) return NextResponse.next({ request });

  let response = NextResponse.next({ request });
  const supabase = createServerClient(config.url, config.publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet, headers) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
        Object.entries(headers).forEach(([key, value]) => response.headers.set(key, value));
      }
    }
  });

  try {
    await supabase.auth.getClaims();
  } catch {
    // Refresh is best-effort for public navigation. Do not serialize provider
    // errors; protected handlers independently verify claims and fail closed.
    logEvent("warn", "auth.session_refresh.unavailable", {
      requestId: getRequestId(request),
      component: "auth",
      outcome: "unavailable"
    });
  }
  return response;
}
