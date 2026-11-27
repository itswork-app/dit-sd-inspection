import { executeProtectedCommand } from "@/lib/api/command";
import { isCreateUploadIntentInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_create_upload_intent_v1",
    validator: isCreateUploadIntentInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_slot_definition_id: input.slot_definition_id,
      p_mime_type: input.mime_type,
      p_byte_size: input.byte_size,
      p_sha256: input.sha256.toLowerCase(),
      p_client_file_id: input.client_file_id.trim()
    })
  });
}
