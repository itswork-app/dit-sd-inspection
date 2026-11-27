import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { loadSelfAccountSnapshot } from "@/lib/auth/account";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { logEvent } from "@/lib/observability/logger";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const startedAt = Date.now();
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();

  if (identity.status === "unauthenticated") {
    return apiErrorResponse(request, "UNAUTHENTICATED");
  }
  if (identity.status === "unavailable") {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const snapshot = await loadSelfAccountSnapshot(supabase, identity.actorId);
  if (snapshot.status === "schema_unavailable") {
    logEvent("warn", "api.request.completed", {
      requestId,
      component: "supabase",
      outcome: "unavailable",
      statusCode: 503,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }
  if (snapshot.status === "error") {
    logEvent("error", "api.request.completed", {
      requestId,
      component: "supabase",
      outcome: "failure",
      statusCode: 500,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(request, "INTERNAL");
  }

  logEvent("info", "api.request.completed", {
    requestId,
    component: "api",
    outcome: "success",
    statusCode: 200,
    durationMs: Date.now() - startedAt
  });

  return Response.json(
    {
      user: snapshot.user,
      requests: snapshot.requests,
      decisions: snapshot.decisions,
      roles: snapshot.roles,
      scopes: snapshot.scopes,
      can_manage_identity: snapshot.canManageIdentity,
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
