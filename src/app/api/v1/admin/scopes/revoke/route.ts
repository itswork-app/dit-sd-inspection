import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isRevokeScopeInput } from "@/lib/api/rbac-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_revoke_scope_v1",
    validator: isRevokeScopeInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_scope_grant_id: input.scope_grant_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
