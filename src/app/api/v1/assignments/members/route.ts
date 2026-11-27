import { executeProtectedCommand } from "@/lib/api/command";
import { isChangeAssignmentMembersInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_change_assignment_members_v1",
    validator: isChangeAssignmentMembersInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_assignment_id: input.assignment_id,
      p_add_members: input.add_members ?? [],
      p_end_member_ids: input.end_member_ids ?? [],
      p_reason: input.reason.trim()
    })
  });
}
