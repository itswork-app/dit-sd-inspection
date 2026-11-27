import { executeProtectedCommand } from "@/lib/api/command";
import { isRegisterCanonicalUnitInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_register_canonical_unit_v1",
    validator: isRegisterCanonicalUnitInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_instrument_id: input.instrument_id,
      p_serial_raw: input.serial_raw ?? null,
      p_identity_attributes: input.identity_attributes ?? {}
    })
  });
}
