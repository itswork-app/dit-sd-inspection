import { isUuid, mapCommandStatusToHttp } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  const url = new URL(request.url);
  const projectId = url.searchParams.get("project_id");
  const sessionId = url.searchParams.get("session_id");
  if (!isUuid(projectId) || (sessionId !== null && !isUuid(sessionId))) {
    return apiErrorResponse(request, "BAD_REQUEST");
  }

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_get_actual_report_v1", {
    p_project_id: projectId,
    p_session_id: sessionId
  });

  if (error || !data || typeof data !== "object") return apiErrorResponse(request, "INTERNAL");
  const payload = data as Record<string, unknown>;
  return Response.json(
    { ...payload, requestId },
    {
      status: mapCommandStatusToHttp(payload.status),
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}
