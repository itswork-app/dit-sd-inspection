import { executeProtectedCommand } from "@/lib/api/command";
import { isRecordPrintBatchInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_record_print_batch_v1",
    validator: isRecordPrintBatchInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_session_id: input.session_id,
      p_items: input.items
    })
  });
}
