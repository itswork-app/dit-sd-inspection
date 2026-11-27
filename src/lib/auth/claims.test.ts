import { describe, expect, it, vi } from "vitest";
import { resolveVerifiedIdentity, type ClaimsClient } from "@/lib/auth/claims";

function clientWith(result: Awaited<ReturnType<ClaimsClient["auth"]["getClaims"]>>): ClaimsClient {
  return { auth: { getClaims: vi.fn().mockResolvedValue(result) } };
}

describe("resolveVerifiedIdentity", () => {
  it("derives the actor only from verified claims.sub", async () => {
    const client = clientWith({ data: { claims: { sub: "user-123" } }, error: null });
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({
      status: "authenticated",
      actorId: "user-123"
    });
  });

  it("treats a missing session as unauthenticated", async () => {
    const client = clientWith({ data: null, error: { name: "AuthSessionMissingError", status: 400 } });
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({ status: "unauthenticated" });
  });

  it("treats a rejected refresh credential as an expired session", async () => {
    const client = clientWith({ data: null, error: { name: "AuthApiError", status: 400 } });
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({ status: "unauthenticated" });
  });

  it("treats an invalid JWT as unauthenticated", async () => {
    const client = clientWith({ data: null, error: { name: "AuthInvalidJwtError" } });
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({ status: "unauthenticated" });
  });

  it("does not infer identity from absent or malformed subject claims", async () => {
    await expect(resolveVerifiedIdentity(clientWith({ data: { claims: {} }, error: null })))
      .resolves.toEqual({ status: "unavailable" });
    await expect(resolveVerifiedIdentity(clientWith({ data: { claims: { sub: "  " } }, error: null })))
      .resolves.toEqual({ status: "unavailable" });
  });

  it("does not expose provider errors", async () => {
    const client = clientWith({ data: null, error: { name: "AuthApiError", status: 503 } });
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({ status: "unavailable" });
  });

  it("contains thrown provider exceptions", async () => {
    const client: ClaimsClient = {
      auth: { getClaims: vi.fn().mockRejectedValue(new Error("sensitive provider detail")) }
    };
    await expect(resolveVerifiedIdentity(client)).resolves.toEqual({ status: "unavailable" });
  });
});
