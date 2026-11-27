import { executeProtectedCommand } from "@/lib/api/command";
import { isConfirmUploadInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_confirm_upload_v1",
    validator: isConfirmUploadInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_evidence_asset_id: input.evidence_asset_id,
      p_observed_sha256: input.observed_sha256.toLowerCase(),
      p_observed_byte_size: input.observed_byte_size,
      p_observed_mime: input.observed_mime
    })
  });
}
