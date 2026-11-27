import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isChangeInspectorCapacityInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_change_inspector_capacity_v1",
    validator: isChangeInspectorCapacityInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_inspector_cap: input.inspector_cap,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
