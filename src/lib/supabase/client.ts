"use client";

import { createBrowserClient } from "@supabase/ssr";
import { readSupabasePublicConfig } from "@/lib/env";

export function createClient() {
  const config = readSupabasePublicConfig(process.env);
  if (!config) throw new Error("Supabase is not configured. Set the public environment variables.");
  return createBrowserClient(config.url, config.publishableKey);
}
