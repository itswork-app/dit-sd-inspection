import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { executeProtectedCommand } from "@/lib/api/command";
import { isCreateProjectInput } from "@/lib/api/domain-validators";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const [projectsRes, capacityRes] = await Promise.all([
    supabase
      .from("projects")
      .select("id, code, name, status, timezone, row_version, created_at, updated_at, closed_at")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("project_capacity_settings")
      .select("project_id, inspector_cap, row_version, updated_at")
      .limit(100)
  ]);

  if (projectsRes.error || capacityRes.error) {
    return apiErrorResponse(request, "INTERNAL");
  }

  return Response.json(
    {
      projects: projectsRes.data ?? [],
      capacity_settings: capacityRes.data ?? [],
      requestId
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_create_project_v1",
    validator: isCreateProjectInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_code: input.code.trim(),
      p_name: input.name.trim(),
      p_timezone: input.timezone?.trim() || "Asia/Jakarta"
    })
  });
}
