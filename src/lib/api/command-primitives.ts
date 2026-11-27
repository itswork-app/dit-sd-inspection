const IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9._:-]{8,128}$/;

export const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const POSITIVE_INT_STRING_PATTERN = /^[1-9]\d{0,15}$/;

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

/**
 * Validates decimal-string expected_row_version per CONCURRENCY-001 v1.0.0.
 * Accepts canonical base-10 positive integer strings within JS safe integer range.
 */
export function parseRowVersionString(value: unknown): number | null {
  if (typeof value !== "string" || !POSITIVE_INT_STRING_PATTERN.test(value)) {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed < 1) return null;
  return parsed;
}

export function readIdempotencyKey(request: Request): string | null {
  const raw = request.headers.get("idempotency-key")?.trim();
  if (!raw || !IDEMPOTENCY_KEY_PATTERN.test(raw)) return null;
  return raw;
}

const COMMAND_STATUS_HTTP_MAP: Record<string, number> = {
  ACCEPTED: 200,
  ALREADY_PENDING: 200,
  ALREADY_APPROVED: 200,
  APPROVED: 200,
  REJECTED: 200,
  TRANSITIONED: 200,
  GRANTED: 200,
  REVOKED: 200,
  VALIDATION_FAILED: 400,
  UNAUTHENTICATED: 401,
  PERMISSION_DENIED: 403,
  SOD_VIOLATION: 403,
  ACCOUNT_NOT_ELIGIBLE: 403,
  NOT_FOUND: 404,
  STATE_CONFLICT: 409,
  STALE_VERSION: 409,
  IDEMPOTENCY_KEY_REUSED: 409,
  LAST_ADMIN_PROTECTED: 409
};

export function mapCommandStatusToHttp(status: unknown): number {
  if (typeof status !== "string") return 500;
  return COMMAND_STATUS_HTTP_MAP[status] ?? 500;
}
