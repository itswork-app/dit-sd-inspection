import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { readSupabasePublicConfig } from "@/lib/env";

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
        headers.forEach((value, key) => response.headers.set(key, value));
      }
    }
  });

  await supabase.auth.getClaims();
  return response;
}
