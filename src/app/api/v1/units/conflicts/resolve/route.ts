import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isResolveUnitConflictInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_resolve_unit_identity_conflict_v1",
    validator: isResolveUnitConflictInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_conflict_id: input.conflict_id,
      p_resolution: input.resolution,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim(),
      p_verified_unit_id: input.verified_unit_id ?? null
    })
  });
}
