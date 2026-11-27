import {
  mapCommandStatusToHttp,
  parseRowVersionString,
  readIdempotencyKey,
  isUuid,
  UUID_PATTERN
} from "@/lib/api/command-primitives";
import { apiErrorResponse, getRequestId, type ApiErrorCode } from "@/lib/api/errors";
import { parseJsonRequest, type JsonBodyValidator } from "@/lib/api/json";
import { getVerifiedIdentity } from "@/lib/auth/identity";
import { logEvent } from "@/lib/observability/logger";
import { createClient } from "@/lib/supabase/server";

export {
  isUuid,
  mapCommandStatusToHttp,
  parseRowVersionString,
  readIdempotencyKey,
  UUID_PATTERN
};

type RpcClient = Awaited<ReturnType<typeof createClient>>;

export async function executeProtectedCommand<TInput>(options: {
  request: Request;
  rpcName: string;
  validator: JsonBodyValidator<TInput>;
  buildParams: (input: TInput, idempotencyKey: string) => Record<string, unknown>;
}): Promise<Response> {
  const startedAt = Date.now();
  const requestId = getRequestId(options.request);

  const identity = await getVerifiedIdentity();
  if (identity.status === "unauthenticated") {
    logEvent("warn", "api.request.completed", {
      requestId,
      component: "api",
      outcome: "denied",
      statusCode: 401,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(options.request, "UNAUTHENTICATED");
  }
  if (identity.status === "unavailable") {
    logEvent("warn", "auth.identity.unavailable", {
      requestId,
      component: "auth",
      outcome: "unavailable",
      statusCode: 503,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(options.request, "SERVICE_UNAVAILABLE");
  }

  const idempotencyKey = readIdempotencyKey(options.request);
  if (!idempotencyKey) {
    return apiErrorResponse(options.request, "BAD_REQUEST");
  }

  const parsed = await parseJsonRequest(options.request, options.validator);
  if (!parsed.ok) {
    return apiErrorResponse(options.request, parsed.code as ApiErrorCode);
  }

  let supabase: RpcClient;
  try {
    supabase = await createClient();
  } catch {
    return apiErrorResponse(options.request, "SERVICE_UNAVAILABLE");
  }

  const { data, error } = await supabase.rpc(
    options.rpcName,
    options.buildParams(parsed.data, idempotencyKey)
  );

  if (error || !data || typeof data !== "object" || Array.isArray(data)) {
    logEvent("error", "api.request.completed", {
      requestId,
      component: "supabase",
      outcome: "failure",
      statusCode: 500,
      durationMs: Date.now() - startedAt
    });
    return apiErrorResponse(options.request, "INTERNAL");
  }

  const payload = data as Record<string, unknown>;
  const httpStatus = mapCommandStatusToHttp(payload.status);

  logEvent(httpStatus >= 500 ? "error" : httpStatus >= 400 ? "warn" : "info", "api.request.completed", {
    requestId,
    component: "api",
    outcome: httpStatus < 400 ? "success" : httpStatus === 401 || httpStatus === 403 ? "denied" : "failure",
    statusCode: httpStatus,
    durationMs: Date.now() - startedAt
  });

  return Response.json(
    { ...payload, requestId },
    {
      status: httpStatus,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}
