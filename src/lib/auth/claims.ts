export type VerifiedIdentity = {
  status: "authenticated";
  actorId: string;
};

export type IdentityResolution =
  | VerifiedIdentity
  | { status: "unauthenticated" }
  | { status: "unavailable" };

type AuthErrorShape = {
  name?: string;
  status?: number;
};

type ClaimsPayload = {
  sub?: unknown;
};

export type ClaimsClient = {
  auth: {
    getClaims: () => Promise<{
      data: { claims?: ClaimsPayload } | null;
      error: AuthErrorShape | null;
    }>;
  };
};

const unauthenticatedErrorNames = new Set([
  "AuthSessionMissingError",
  "AuthInvalidJwtError"
]);

/** Resolve identity exclusively from Supabase-verified JWT claims. */
export async function resolveVerifiedIdentity(
  client: ClaimsClient
): Promise<IdentityResolution> {
  try {
    const { data, error } = await client.auth.getClaims();

    if (error) {
      if (error.status === 401 || (error.status === 400 && error.name === "AuthApiError") || (error.name && unauthenticatedErrorNames.has(error.name))) {
        return { status: "unauthenticated" };
      }
      return { status: "unavailable" };
    }

    const subject = data?.claims?.sub;
    if (typeof subject !== "string" || subject.length === 0 || subject.trim() !== subject) {
      return data?.claims ? { status: "unavailable" } : { status: "unauthenticated" };
    }

    return { status: "authenticated", actorId: subject };
  } catch {
    // Provider exceptions are intentionally not returned or logged here.
    return { status: "unavailable" };
  }
}
