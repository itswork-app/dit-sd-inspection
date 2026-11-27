import { executeProtectedCommand } from "@/lib/api/command";
import { isCreateSessionInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_create_session_v1",
    validator: isCreateSessionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_code: input.code.trim(),
      p_starts_at: input.starts_at,
      p_ends_at: input.ends_at
    })
  });
}
