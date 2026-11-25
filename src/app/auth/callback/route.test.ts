import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { GET } from "./route";

vi.mock("@/lib/supabase/server", () => ({ createClient: vi.fn() }));

const exchangeCodeForSession = vi.fn();

function request(url: string) {
  return new NextRequest(url);
}

describe("GET /auth/callback", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(createClient).mockResolvedValue({
      auth: { exchangeCodeForSession }
    } as never);
  });

  it("exchanges the one-time code and redirects to the pending-access screen", async () => {
    exchangeCodeForSession.mockResolvedValue({ error: null });
    const response = await GET(request("https://inspection.example/auth/callback?code=one-time-code"));

    expect(exchangeCodeForSession).toHaveBeenCalledWith("one-time-code");
    expect(response.headers.get("location")).toBe("https://inspection.example/auth/pending");
    expect(response.headers.get("cache-control")).toBe("no-store");
  });

  it("rejects a callback without an authorization code", async () => {
    const response = await GET(request("https://inspection.example/auth/callback?error=access_denied"));

    expect(createClient).not.toHaveBeenCalled();
    expect(response.headers.get("location")).toBe("https://inspection.example/login?error=oauth_callback");
  });

  it("does not expose provider error details in redirects", async () => {
    exchangeCodeForSession.mockResolvedValue({ error: { message: "sensitive provider response" } });
    const response = await GET(request("https://inspection.example/auth/callback?code=bad-code"));

    expect(response.headers.get("location")).toBe("https://inspection.example/login?error=oauth_callback");
    expect(response.headers.get("location")).not.toContain("sensitive");
  });

  it("contains thrown provider exceptions", async () => {
    exchangeCodeForSession.mockRejectedValue(new Error("sensitive provider response"));
    const response = await GET(request("https://inspection.example/auth/callback?code=bad-code"));

    expect(response.headers.get("location")).toBe("https://inspection.example/login?error=oauth_callback");
  });
});
