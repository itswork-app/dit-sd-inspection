import { executeProtectedCommand } from "@/lib/api/command";
import { isPublishNotificationPolicyInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_publish_notification_policy_v1",
    validator: isPublishNotificationPolicyInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_policy_key: input.policy_key.trim(),
      p_scope_type: input.scope_type,
      p_scope_id: input.scope_id ?? null,
      p_sla_mode: input.sla_mode ?? "ELAPSED_UTC",
      p_policy_document: input.policy_document
    })
  });
}
