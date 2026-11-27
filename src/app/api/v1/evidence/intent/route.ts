import { mapCommandStatusToHttp, readIdempotencyKey } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId, type ApiErrorCode } from "@/lib/api/errors";
import { parseJsonRequest } from "@/lib/api/json";
import { isCreateUploadIntentInput } from "@/lib/api/inspection-validators";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

const PRIVATE_BUCKET = "inspection-private";

export async function POST(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  const idempotencyKey = readIdempotencyKey(request);
  if (!idempotencyKey) return apiErrorResponse(request, "BAD_REQUEST");

  const parsed = await parseJsonRequest(request, isCreateUploadIntentInput);
  if (!parsed.ok) return apiErrorResponse(request, parsed.code as ApiErrorCode);

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_create_upload_intent_v1", {
    p_idempotency_key: idempotencyKey,
    p_inspection_id: parsed.data.inspection_id,
    p_slot_definition_id: parsed.data.slot_definition_id,
    p_mime_type: parsed.data.mime_type,
    p_byte_size: parsed.data.byte_size,
    p_sha256: parsed.data.sha256.toLowerCase(),
    p_client_file_id: parsed.data.client_file_id.trim()
  });

  if (error || !data || typeof data !== "object") return apiErrorResponse(request, "INTERNAL");
  const payload = data as Record<string, unknown>;
  const httpStatus = mapCommandStatusToHttp(payload.status);

  // Issue short-lived signed upload URL outside DB transaction using caller JWT + storage.objects RLS
  let signedUploadUrl: string | null = null;
  let uploadToken: string | null = null;
  if (payload.status === "INTENT_CREATED" && typeof payload.object_key === "string") {
    const signed = await supabase.storage
      .from(PRIVATE_BUCKET)
      .createSignedUploadUrl(payload.object_key);
    if (!signed.error && signed.data) {
      signedUploadUrl = signed.data.signedUrl;
      uploadToken = signed.data.token;
    }
  }

  return Response.json(
    {
      ...payload,
      bucket: PRIVATE_BUCKET,
      signed_upload_url: signedUploadUrl,
      upload_token: uploadToken,
      requestId
    },
    {
      status: httpStatus,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}
