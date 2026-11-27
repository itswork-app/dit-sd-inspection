import { apiErrorResponse, getRequestId } from "@/lib/api/errors";
import { executeProtectedCommand } from "@/lib/api/command";
import { isCreateInstrumentInput } from "@/lib/api/domain-validators";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const requestId = getRequestId(request);
  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") return apiErrorResponse(request, "UNAUTHENTICATED");
  if (identity.status === "unavailable") return apiErrorResponse(request, "SERVICE_UNAVAILABLE");

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(request, "SERVICE_UNAVAILABLE");
  }

  const [instrumentsRes, versionsRes] = await Promise.all([
    supabase
      .from("instruments")
      .select("id, instrument_type, code, name, description, status, serial_case_insensitive, row_version, created_at")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("instrument_versions")
      .select("id, instrument_id, version_number, status, schema_version, draft_hash, row_version, published_at")
      .order("version_number", { ascending: false })
      .limit(200)
  ]);

  if (instrumentsRes.error || versionsRes.error) {
    return apiErrorResponse(request, "INTERNAL");
  }

  return Response.json(
    {
      instruments: instrumentsRes.data ?? [],
      versions: versionsRes.data ?? [],
      requestId
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}

export async function POST(request: Request) {
  return executeProtectedCommand({
    request,
    rpcName: "cmd_create_instrument_v1",
    validator: isCreateInstrumentInput,
    buildParams: (input, idempotencyKey) => ({
      p_idempotency_key: idempotencyKey,
      p_instrument_type: input.instrument_type.trim(),
      p_code: input.code.trim(),
      p_name: input.name.trim(),
      p_description: input.description?.trim() || null,
      p_serial_case_insensitive: input.serial_case_insensitive ?? true
    })
  });
}
