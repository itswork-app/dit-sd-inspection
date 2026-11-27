import { mapCommandStatusToHttp } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId, type ApiErrorCode } from "@/lib/api/errors";
import { parseJsonRequest } from "@/lib/api/json";
import { isMarkNotificationReadInput } from "@/lib/api/ops-validators";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  const parsed = await parseJsonRequest(request, isMarkNotificationReadInput);
  if (!parsed.ok) return apiErrorResponse(request, parsed.code as ApiErrorCode);

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_mark_notification_read_v1", {
    p_notification_id: parsed.data.notification_id
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
