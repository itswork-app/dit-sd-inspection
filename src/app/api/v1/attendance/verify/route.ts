import { executeProtectedCommand, parseRowVersionString } from "@/lib/api/command";
import { isVerifyAttendanceInput } from "@/lib/api/ops-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_verify_attendance_v1",
    validator: isVerifyAttendanceInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_attendance_record_id: input.attendance_record_id,
      p_attendance_document_id: input.attendance_document_id,
      p_decision: input.decision,
      p_expected_row_version: parseRowVersionString(input.expected_row_version),
      p_reason: input.reason?.trim() || null
    })
  });
}
