import { executeProtectedCommand } from "@/lib/api/command";
import { isReturnInspectionInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_return_inspection_v1",
    validator: isReturnInspectionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_revision_id: input.revision_id,
      p_expected_revision_no: input.expected_revision_no,
      p_reason: input.reason.trim()
    })
  });
}
