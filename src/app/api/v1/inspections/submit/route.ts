import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isSubmitInspectionInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_submit_inspection_v1",
    validator: isSubmitInspectionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_submit_reason: input.submit_reason?.trim() || null
    })
  });
}
