export type ApiErrorCode =
  | "BAD_REQUEST"
  | "UNAUTHENTICATED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "PAYLOAD_TOO_LARGE"
  | "UNSUPPORTED_MEDIA_TYPE"
  | "TOO_MANY_REQUESTS"
  | "INTERNAL"
  | "SERVICE_UNAVAILABLE";

const ERROR_DEFINITIONS: Record<ApiErrorCode, { status: number; message: string }> = {
  BAD_REQUEST: { status: 400, message: "The request is invalid." },
  UNAUTHENTICATED: { status: 401, message: "Authentication is required." },
  FORBIDDEN: { status: 403, message: "The requested action is not permitted." },
  NOT_FOUND: { status: 404, message: "The requested resource was not found." },
  CONFLICT: { status: 409, message: "The request conflicts with the current resource state." },
  PAYLOAD_TOO_LARGE: { status: 413, message: "The request body is too large." },
  UNSUPPORTED_MEDIA_TYPE: { status: 415, message: "The request content type is not supported." },
  TOO_MANY_REQUESTS: { status: 429, message: "Too many requests. Try again later." },
  INTERNAL: { status: 500, message: "An unexpected error occurred." },
  SERVICE_UNAVAILABLE: { status: 503, message: "The service is temporarily unavailable." }
};

const REQUEST_ID_PATTERN = /^[A-Za-z0-9._:-]{8,128}$/;

/**
 * Returns a safe correlation identifier. An inbound value is accepted only
 * as an opaque, syntax-checked correlation token; it is never an identity,
 * authorization input, or trusted security assertion.
 */
export function getRequestId(request: Request): string {
  const candidate = request.headers.get("x-request-id");
  if (candidate && REQUEST_ID_PATTERN.test(candidate)) return candidate;
  return crypto.randomUUID();
}

/**
 * Creates the stable public API error envelope. Internal exceptions and
 * diagnostic details must never be passed through to this response.
 */
export function apiErrorResponse(request: Request, code: ApiErrorCode): Response {
  const requestId = getRequestId(request);
  const definition = ERROR_DEFINITIONS[code];

  return Response.json(
    {
      error: {
        code,
        message: definition.message,
        requestId
      }
    },
    {
      status: definition.status,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "X-Request-Id": requestId
      }
    }
  );
}
