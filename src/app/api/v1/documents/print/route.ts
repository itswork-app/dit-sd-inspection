import { executeProtectedCommand } from "@/lib/api/command";
import { isRecordPrintInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_record_print_v1",
    validator: isRecordPrintInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_document_id: input.document_id,
      p_expected_document_version: input.expected_document_version,
      p_expected_sequence: input.expected_sequence ?? null,
      p_client_print_signal: input.client_print_signal?.trim() || null
    })
  });
}
