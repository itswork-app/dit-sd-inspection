import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isReopenInspectionInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_reopen_inspection_v1",
    validator: isReopenInspectionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_approved_revision_id: input.approved_revision_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
