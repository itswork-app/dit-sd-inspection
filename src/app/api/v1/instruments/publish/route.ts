import { executeProtectedCommand } from "@/lib/api/command";
import { isPublishInstrumentVersionInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_publish_instrument_version_v1",
    validator: isPublishInstrumentVersionInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_instrument_id: input.instrument_id,
      p_version_id: input.version_id,
      p_expected_draft_hash: input.expected_draft_hash,
      p_change_summary: input.change_summary.trim()
    })
  });
}
