import { executeProtectedCommand } from "@/lib/api/command";
import { isAssociateUnitInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_associate_unit_to_project_v1",
    validator: isAssociateUnitInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_unit_id: input.unit_id,
      p_project_id: input.project_id,
      p_reason: input.reason.trim(),
      p_evidence_ref: input.evidence_ref?.trim() || null
    })
  });
}
