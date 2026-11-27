import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { loadAdminAccountsSnapshot } from "@/lib/auth/account";
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

  const snapshot = await loadAdminAccountsSnapshot(supabase, identity.actorId);
  if (snapshot.status === "forbidden") {
    logEvent("warn", "api.request.completed", {
      requestId,
      component: "api",
      outcome: "denied",
      statusCode: 403,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(request, "FORBIDDEN");
  }
  if (snapshot.status === "schema_unavailable") {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }
  if (snapshot.status === "error") {
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
      actor_user_id: snapshot.actorUserId,
      users: snapshot.users,
      requests: snapshot.requests,
      decisions: snapshot.decisions,
      role_catalog: snapshot.roleCatalog,
      user_roles: snapshot.userRoles,
      user_scopes: snapshot.userScopes,
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
