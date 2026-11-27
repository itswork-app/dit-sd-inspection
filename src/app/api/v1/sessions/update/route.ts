import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isUpdateSessionInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_update_session_v1",
    validator: isUpdateSessionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_session_id: input.session_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_starts_at: input.starts_at,
      p_ends_at: input.ends_at,
      p_reason: input.reason.trim()
    })
  });
}
