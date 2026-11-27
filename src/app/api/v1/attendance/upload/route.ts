import { executeProtectedCommand } from "@/lib/api/command";
import { isUploadAttendanceInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_upload_attendance_document_v1",
    validator: isUploadAttendanceInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_session_id: input.session_id,
      p_location_id: input.location_id,
      p_sha256: input.sha256.toLowerCase(),
      p_byte_size: input.byte_size,
      p_mime_type: input.mime_type,
      p_replacement_reason: input.replacement_reason?.trim() || null
    })
  });
}
