import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isManageTargetPlanInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_manage_target_plan_v1",
    validator: isManageTargetPlanInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_session_id: input.session_id,
      p_action: input.action,
      p_plan_id: input.plan_id ?? null,
      p_expected_row_version: input.expected_row_version
        ? parseRowVersionString(input.expected_row_version)
        : null,
      p_allocations: input.allocations ?? []
    })
  });
}
