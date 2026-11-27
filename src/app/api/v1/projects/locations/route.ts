import { executeProtectedCommand } from "@/lib/api/command";
import { isCreateScopedCodeEntityInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_create_location_v1",
    validator: isCreateScopedCodeEntityInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_code: input.code.trim(),
      p_name: input.name.trim()
    })
  });
}
