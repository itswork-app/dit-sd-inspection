import { executeProtectedCommand } from "@/lib/api/command";
import { isRegisterDeviceBindingInput } from "@/lib/api/inspection-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_register_device_binding_v1",
    validator: isRegisterDeviceBindingInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_device_fingerprint_hash: input.device_fingerprint_hash.toLowerCase(),
      p_label: input.label.trim()
    })
  });
}
