import { executeProtectedCommand } from "@/lib/api/command";
import { isClaimUnitInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_claim_unit_v1",
    validator: isClaimUnitInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_unit_id: input.unit_id,
      p_association_id: input.association_id,
      p_assignment_id: input.assignment_id,
      p_claim_ttl_minutes: input.claim_ttl_minutes ?? 120
    })
  });
}
