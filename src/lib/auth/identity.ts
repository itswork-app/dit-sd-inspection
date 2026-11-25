import "server-only";

import { createClient } from "@/lib/supabase/server";
import { resolveVerifiedIdentity } from "@/lib/auth/claims";
import type { IdentityResolution } from "@/lib/auth/claims";

/**
 * Resolve the current request identity from cryptographically verified claims.
 * This is an identity primitive only; it does not assign roles or authorize resources.
 */
export async function getVerifiedIdentity(): Promise<IdentityResolution> {
  try {
    const supabase = await createClient();
    return await resolveVerifiedIdentity(supabase);
  } catch {
    // Configuration and provider details must never escape this server boundary.
    return { status: "unavailable" };
  }
}
