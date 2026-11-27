import { describe, expect, it } from "vitest";
import { readSupabasePublicConfig } from "@/lib/env";

describe("readSupabasePublicConfig", () => {
  it("returns null when no Supabase configuration is supplied", () => {
    expect(readSupabasePublicConfig({})).toBeNull();
  });

  it("accepts a complete HTTPS project origin", () => {
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

  it("trims surrounding whitespace from public configuration", () => {
    expect(
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: " https://example.supabase.co/ ",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: " sb_publishable_test "
      })?.url
    ).toBe("https://example.supabase.co");
  });

  it("rejects partial configuration", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co"
      })
    ).toThrow(/must be configured together/);
  });

  it("rejects malformed absolute URLs", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "not-a-url",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toThrow(/valid absolute URL/);
  });

  it("rejects credentials embedded in the project URL", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "https://user:password@example.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toThrow(/must not contain credentials/);
  });

  it.each([
    "https://example.supabase.co/rest/v1",
    "https://example.supabase.co?apikey=unexpected",
    "https://example.supabase.co#fragment"
  ])("rejects project URLs containing a path, query or fragment: %s", (url) => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: url,
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toThrow(/without a path, query or fragment/);
  });

  it("rejects insecure non-local URLs", () => {
    expect(() =>
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: "http://example.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })
    ).toThrow(/HTTPS/);
  });

  it.each([
    "http://localhost:54321",
    "http://127.0.0.1:54321",
    "http://[::1]:54321"
  ])("allows HTTP only for loopback development hosts: %s", (url) => {
    expect(
      readSupabasePublicConfig({
        NEXT_PUBLIC_SUPABASE_URL: url,
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test"
      })?.url
    ).toBe(url);
  });
});
