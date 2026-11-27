import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isDecideAbortInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_decide_packed_unit_abort_v1",
    validator: isDecideAbortInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_abort_request_id: input.abort_request_id,
      p_decision: input.decision,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
