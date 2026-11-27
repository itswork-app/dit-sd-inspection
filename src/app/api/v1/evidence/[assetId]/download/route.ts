import { isUuid, mapCommandStatusToHttp } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

const PRIVATE_BUCKET = "inspection-private";
const SIGNED_URL_TTL_SECONDS = 60;

export async function GET(
  request: Request,
  context: { params: Promise<{ assetId: string }> }
) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  const { assetId } = await context.params;
  if (!isUuid(assetId)) return apiErrorResponse(request, "BAD_REQUEST");

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_authorize_artifact_download_v1", {
    p_artifact_kind: "EVIDENCE",
    p_artifact_id: assetId
  });
  if (error || !data || typeof data !== "object") return apiErrorResponse(request, "INTERNAL");

  const payload = data as Record<string, unknown>;
  if (payload.status !== "OK" || typeof payload.object_key !== "string") {
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

  const signed = await supabase.storage
    .from(PRIVATE_BUCKET)
    .createSignedUrl(payload.object_key, SIGNED_URL_TTL_SECONDS);

  if (signed.error || !signed.data) return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  return Response.json(
    {
      status: "OK",
      signed_url: signed.data.signedUrl,
      expires_in_seconds: SIGNED_URL_TTL_SECONDS,
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
