import { mapCommandStatusToHttp } from "@/lib/api/command-primitives";
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
  const unreadOnly = url.searchParams.get("unread_only") === "true";
  const rawLimit = Number(url.searchParams.get("limit") ?? "50");
  const limit = Number.isInteger(rawLimit) && rawLimit >= 1 && rawLimit <= 100 ? rawLimit : 50;

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_list_own_notifications_v1", {
    p_unread_only: unreadOnly,
    p_limit: limit
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
