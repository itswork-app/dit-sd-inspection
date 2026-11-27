import { executeProtectedCommand } from "@/lib/api/command";
import { isRequestAccountAccessInput } from "@/lib/api/rbac-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_request_account_access_v1",
    validator: isRequestAccountAccessInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_display_name: input.display_name.trim(),
      p_request_note: input.request_note?.trim() || null
    })
  });
}
