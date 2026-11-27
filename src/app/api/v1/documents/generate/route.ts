import { mapCommandStatusToHttp, readIdempotencyKey } from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId, type ApiErrorCode } from "@/lib/api/errors";
import { parseJsonRequest } from "@/lib/api/json";
import { isGenerateDocumentInput } from "@/lib/api/ops-validators";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { renderMinimalPdfDocument } from "@/lib/pdf/minimal-pdf";
import { inspectBinaryArtifact } from "@/lib/storage/verify-binary";
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

  const parsed = await parseJsonRequest(request, isGenerateDocumentInput);
  if (!parsed.ok) return apiErrorResponse(request, parsed.code as ApiErrorCode);

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc("cmd_generate_approved_document_v1", {
    p_idempotency_key: idempotencyKey,
    p_document_type: parsed.data.document_type,
    p_inspection_id: parsed.data.inspection_id,
    p_approved_revision_id: parsed.data.approved_revision_id,
    p_template_version_id: parsed.data.template_version_id
  });

  if (error || !data || typeof data !== "object") return apiErrorResponse(request, "INTERNAL");
  const payload = data as Record<string, unknown>;
  const httpStatus = mapCommandStatusToHttp(payload.status);

  // Render deterministic PDF 1.4 binary outside DB transaction & upload to private Storage
  let storageUploaded = false;
  let pdfSha256: string | null = null;
  let pdfByteSize: number | null = null;

  if (payload.status === "GENERATED" && typeof payload.object_key === "string") {
    const pdfBytes = renderMinimalPdfDocument({
      title: `Dit. SD Inspection - ${parsed.data.document_type}`,
      lines: [
        `Document ID: ${String(payload.document_id ?? "")}`,
        `Document Version: v${String(payload.version_no ?? "1")}`,
        `Inspection ID: ${parsed.data.inspection_id}`,
        `Approved Revision ID: ${parsed.data.approved_revision_id}`,
        `Template Version ID: ${parsed.data.template_version_id}`,
        `Output Hash: ${String(payload.output_hash ?? "")}`,
        `Generated At (UTC): ${String(payload.server_time ?? "")}`,
        "Status: APPROVED / IMMUTABLE ARTIFACT (SYNTHETIC DEVELOPMENT)"
      ]
    });

    const meta = inspectBinaryArtifact(pdfBytes);
    pdfSha256 = meta.sha256;
    pdfByteSize = meta.byteSize;

    const uploadRes = await supabase.storage
      .from(PRIVATE_BUCKET)
      .upload(payload.object_key, pdfBytes, {
        contentType: "application/pdf",
        upsert: false
      });

    if (!uploadRes.error) {
      storageUploaded = true;
    }
  }

  return Response.json(
    {
      ...payload,
      bucket: PRIVATE_BUCKET,
      storage_uploaded: storageUploaded,
      pdf_sha256: pdfSha256,
      pdf_byte_size: pdfByteSize,
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
