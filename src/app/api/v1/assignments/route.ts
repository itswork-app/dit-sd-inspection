import { executeProtectedCommand } from "@/lib/api/command";
import { isPublishAssignmentInput } from "@/lib/api/domain-validators";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_publish_assignment_v1",
    validator: isPublishAssignmentInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_project_id: input.project_id,
      p_session_id: input.session_id,
      p_location_id: input.location_id,
      p_instrument_id: input.instrument_id,
      p_instrument_version_id: input.instrument_version_id,
      p_team_id: input.team_id,
      p_starts_at: input.starts_at,
      p_ends_at: input.ends_at,
      p_members: input.members
    })
  });
}
