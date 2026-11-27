import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isTransitionSessionInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_transition_session_v1",
    validator: isTransitionSessionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_session_id: input.session_id,
      p_action: input.action,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
