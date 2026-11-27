import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { GET } from "./route";

vi.mock("@/lib/supabase/server", () => ({ createClient: vi.fn() }));

const exchangeCodeForSession = vi.fn();
const getUser = vi.fn();
const maybeSingle = vi.fn();

function request(url: string) {
  return new NextRequest(url);
}

describe("GET /auth/callback", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    getUser.mockResolvedValue({ data: { user: { id: "auth-1" } } });
    maybeSingle.mockResolvedValue({ data: { account_status: "PENDING" } });
    vi.mocked(createClient).mockResolvedValue({
      auth: { exchangeCodeForSession, getUser },
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({ maybeSingle }))
        }))
      }))
    } as never);
  });

  it("exchanges the one-time code and redirects pending/new users to /auth/pending", async () => {
    exchangeCodeForSession.mockResolvedValue({ error: null });
    const response = await GET(request("https://inspection.example/auth/callback?code=one-time-code"));

    expect(exchangeCodeForSession).toHaveBeenCalledWith("one-time-code");
    expect(response.headers.get("location")).toBe("https://inspection.example/auth/pending");
    expect(response.headers.get("cache-control")).toBe("no-store");
  });

  it("redirects APPROVED users directly to /dashboard after login", async () => {
    exchangeCodeForSession.mockResolvedValue({ error: null });
    maybeSingle.mockResolvedValueOnce({ data: { account_status: "APPROVED" } });
    const response = await GET(request("https://inspection.example/auth/callback?code=one-time-code"));

    expect(response.headers.get("location")).toBe("https://inspection.example/dashboard");
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
