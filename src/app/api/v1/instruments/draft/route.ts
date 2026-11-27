import { executeProtectedCommand } from "@/lib/api/command";
import { isSaveInstrumentDraftInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_save_instrument_draft_v1",
    validator: isSaveInstrumentDraftInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_instrument_id: input.instrument_id,
      p_version_id: input.version_id ?? null,
      p_schema_version: input.schema_version?.trim() || "1.0",
      p_sections: input.sections,
      p_spec_fields: input.spec_fields ?? [],
      p_evidence_slots: input.evidence_slots ?? []
    })
  });
}
