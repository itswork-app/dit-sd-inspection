import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { readSupabasePublicConfig } from "@/lib/env";
import { updateSession } from "./proxy";

vi.mock("@supabase/ssr", () => ({ createServerClient: vi.fn() }));
vi.mock("@/lib/env", () => ({ readSupabasePublicConfig: vi.fn() }));

const getClaims = vi.fn();

function request() {
  return new NextRequest("http://localhost:3000/");
}

describe("updateSession", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(readSupabasePublicConfig).mockReturnValue({
      url: "http://127.0.0.1:54321",
      publishableKey: "test-publishable-key"
    });
    vi.mocked(createServerClient).mockReturnValue({ auth: { getClaims } } as never);
    getClaims.mockResolvedValue({ data: null, error: null });
  });

  it("skips Supabase when public configuration is absent", async () => {
    vi.mocked(readSupabasePublicConfig).mockReturnValue(null);
    const response = await updateSession(request());

    expect(createServerClient).not.toHaveBeenCalled();
    expect(response.status).toBe(200);
  });

  it("refreshes claims when Supabase is configured", async () => {
    await updateSession(request());
    expect(getClaims).toHaveBeenCalledOnce();
  });

  it("does not make public navigation fail when refresh throws", async () => {
    getClaims.mockRejectedValue(new Error("provider detail must not escape"));
    const response = await updateSession(request());

    expect(response.status).toBe(200);
  });
});
