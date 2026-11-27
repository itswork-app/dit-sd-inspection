import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isDeactivateInstrumentInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_deactivate_instrument_v1",
    validator: isDeactivateInstrumentInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_instrument_id: input.instrument_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
