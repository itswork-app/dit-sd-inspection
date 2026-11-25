import { describe, expect, it } from "vitest";
import { readSupabasePublicConfig } from "@/lib/env";

describe("readSupabasePublicConfig", () => {
  it("returns null when no Supabase configuration is supplied", () => {
    expect(readSupabasePublicConfig({})).toBeNull();
  });

  it("accepts a complete HTTPS project configuration", () => {
    expect(
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toEqual({
      url: "https://example.supabase.co",
      publishableKey: "sb_publishable_test"
    });
  });

  it("rejects partial configuration", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co"
      })
    ).toThrow(/must be configured together/);
  });

  it("rejects insecure non-local URLs", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "http://example.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toThrow(/HTTPS/);
  });

  it("allows HTTP only for localhost development", () => {
    expect(
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })?.url
    ).toBe("http://127.0.0.1:54321");
  });
});
