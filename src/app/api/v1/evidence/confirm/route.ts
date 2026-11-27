import { isUuid, mapCommandStatusToHttp, readIdempotencyKey } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId, type ApiErrorCode } from "@/lib/api/errors";
import { parseJsonRequest } from "@/lib/api/json";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { inspectBinaryArtifact } from "@/lib/storage/verify-binary";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

const PRIVATE_BUCKET = "inspection-private";

type ConfirmStorageUploadBody = {
  evidence_asset_id: string;
};

function isConfirmStorageUploadBody(value: unknown): value is ConfirmStorageUploadBody {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const keys = Object.keys(value);
  return keys.length === 1 && keys[0] === "evidence_asset_id" && isUuid((value as Record<string, unknown>).evidence_asset_id);
}

/**
 * CMD-034: Server-verified evidence finalization.
 * Downloads the uploaded object from private Storage using caller JWT (never trusts
 * client-asserted checksum/size/MIME), computes SHA-256 + byte size + magic-byte MIME,
 * and finalizes atomically via cmd_confirm_upload_v1.
 */
export async function POST(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  const idempotencyKey = readIdempotencyKey(request);
  if (!idempotencyKey) return apiErrorResponse(request, "BAD_REQUEST");

  const parsed = await parseJsonRequest(request, isConfirmStorageUploadBody);
  if (!parsed.ok) return apiErrorResponse(request, parsed.code as ApiErrorCode);

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  // Resolve object_key through caller-JWT RLS (never accepts object_key from client!)
  const { data: asset, error: assetErr } = await supabase
    .from("evidence_assets")
    .select("id, object_key, upload_status")
    .eq("id", parsed.data.evidence_asset_id)
    .maybeSingle();

  if (assetErr) return apiErrorResponse(request, "INTERNAL");
  if (!asset) return apiErrorResponse(request, "NOT_FOUND");

  // Download binary from private bucket outside DB transaction
  const { data: blob, error: dlErr } = await supabase.storage
    .from(PRIVATE_BUCKET)
    .download(asset.object_key);

  if (dlErr || !blob) {
    return Response.json(
      { command_id: "CMD-034", status: "OBJECT_MISSING", requestId },
      {
        status: 409,
        headers: {
          "Cache-Control": "no-store",
          "X-Content-Type-Options": "nosniff",
          "X-Request-Id": requestId
        }
      }
    );
  }

  const bytes = new Uint8Array(await blob.arrayBuffer());
  const observed = inspectBinaryArtifact(bytes);
  if (!observed.detectedMime) {
    return Response.json(
      { command_id: "CMD-034", status: "EVIDENCE_INVALID", requestId },
      {
        status: 400,
        headers: {
          "Cache-Control": "no-store",
          "X-Content-Type-Options": "nosniff",
          "X-Request-Id": requestId
        }
      }
    );
  }

  const { data, error } = await supabase.rpc("cmd_confirm_upload_v1", {
    p_idempotency_key: idempotencyKey,
    p_evidence_asset_id: parsed.data.evidence_asset_id,
    p_observed_sha256: observed.sha256,
    p_observed_byte_size: observed.byteSize,
    p_observed_mime: observed.detectedMime
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
