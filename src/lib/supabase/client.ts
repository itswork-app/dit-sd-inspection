"use client";

import { createBrowserClient } from "@supabase/ssr";
import { readSupabasePublicConfig } from "@/lib/env";

export function createClient() {
  const config = readSupabasePublicConfig({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  });
  if (!config) throw new Error("Supabase is not configured. Set the public environment variables.");
  return createBrowserClient(config.url, config.publishableKey);
}
