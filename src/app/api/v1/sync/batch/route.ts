import { executeProtectedCommand } from "@/lib/api/command";
import { isSyncBatchInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_sync_batch_v1",
    validator: isSyncBatchInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_device_id: input.device_id,
      p_batch_key: input.batch_key.trim(),
      p_operations: input.operations
    })
  });
}
