import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isReleaseClaimInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_release_unit_claim_v1",
    validator: isReleaseClaimInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_claim_id: input.claim_id,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason?.trim() || null
    })
  });
}
