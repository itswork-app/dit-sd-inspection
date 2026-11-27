import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
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

  const [inspectionsRes, claimsRes, abortsRes] = await Promise.all([
    supabase
      .from("inspections")
      .select("id, unit_id, project_id, session_id, assignment_id, instrument_version_id, status, current_revision_no, owner_user_id, row_version, updated_at")
      .order("updated_at", { ascending: false })
      .limit(100),
    supabase
      .from("unit_claims")
      .select("id, unit_id, project_id, assignment_id, inspector_id, status, expires_at, row_version")
      .eq("status", "ACTIVE")
      .limit(100),
    supabase
      .from("inspection_abort_requests")
      .select("id, inspection_id, project_id, status, request_reason, row_version, requested_at")
      .order("requested_at", { ascending: false })
      .limit(50)
  ]);

  if (inspectionsRes.error || claimsRes.error || abortsRes.error) {
    return apiErrorResponse(request, "INTERNAL");
  }

  return Response.json(
    {
      inspections: inspectionsRes.data ?? [],
      active_claims: claimsRes.data ?? [],
      abort_requests: abortsRes.data ?? [],
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
