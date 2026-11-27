"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function signOutAction() {
  let signOutError: unknown = null;

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.signOut();
    signOutError = error;
  } catch {
    signOutError = new Error("sign-out unavailable");
  }

  if (signOutError) redirect("/auth/pending?error=signout");
  redirect("/login?status=signed_out");
}
