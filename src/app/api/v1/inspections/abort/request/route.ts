import { executeProtectedCommand } from "@/lib/api/command";
import { isRequestAbortInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_request_packed_unit_abort_v1",
    validator: isRequestAbortInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_reason: input.reason.trim()
    })
  });
}
