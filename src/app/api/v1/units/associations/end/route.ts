import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isEndUnitAssociationInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_end_unit_project_association_v1",
    validator: isEndUnitAssociationInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_association_id: input.association_id,
      p_outcome: input.outcome,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason.trim()
    })
  });
}
