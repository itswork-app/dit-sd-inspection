import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isTransitionAccountStatusInput } from "@/lib/api/rbac-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_transition_account_status_v1",
    validator: isTransitionAccountStatusInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_target_user_id: input.target_user_id,
      p_target_status: input.target_status,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
