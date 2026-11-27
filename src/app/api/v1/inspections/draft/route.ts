import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isSaveDraftInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_save_draft_v1",
    validator: isSaveDraftInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_inspection_id: input.inspection_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_draft_checklist: input.draft_checklist,
      p_draft_specifications: input.draft_specifications ?? {},
      p_notes: input.notes ?? null
    })
  });
}
