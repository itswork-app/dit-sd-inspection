import { executeProtectedCommand } from "@/lib/api/command";
import { isGrantScopeInput } from "@/lib/api/rbac-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_grant_scope_v1",
    validator: isGrantScopeInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_target_user_id: input.target_user_id,
      p_scope_type: input.scope_type,
      p_scope_id: input.scope_id,
      p_valid_from: input.valid_from ?? new Date().toISOString(),
      p_valid_until: input.valid_until ?? null,
      p_reason: input.reason.trim()
    })
  });
}
