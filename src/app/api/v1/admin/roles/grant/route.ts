import { executeProtectedCommand } from "@/lib/api/command";
import { isGrantRoleInput } from "@/lib/api/rbac-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_grant_role_v1",
    validator: isGrantRoleInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_target_user_id: input.target_user_id,
      p_role_code: input.role_code,
      p_project_id: input.project_id ?? null,
      p_valid_from: input.valid_from ?? new Date().toISOString(),
      p_valid_until: input.valid_until ?? null,
      p_reason: input.reason.trim()
    })
  });
}
