import { executeProtectedCommand } from "@/lib/api/command";
import { isGenerateDocumentInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_generate_approved_document_v1",
    validator: isGenerateDocumentInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_document_type: input.document_type,
      p_inspection_id: input.inspection_id,
      p_approved_revision_id: input.approved_revision_id,
      p_template_version_id: input.template_version_id
    })
  });
}
