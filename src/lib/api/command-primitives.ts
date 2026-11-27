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
  CREATED: 201,
  UPDATED: 200,
  CLOSED: 200,
  PUBLISHED: 200,
  DRAFTED: 200,
  SAVED: 200,
  DEACTIVATED: 200,
  REGISTERED: 201,
  EXISTING_AUTHORIZED: 200,
  ASSOCIATED: 201,
  ENDED: 200,
  RESOLVED: 200,
  CLAIMED: 201,
  RESUMED: 200,
  RELEASED: 200,
  SUBMITTED: 200,
  RETURNED: 200,
  REOPENED: 200,
  INTENT_CREATED: 201,
  FINALIZED: 200,
  BOUND: 201,
  APPLIED: 200,
  PARTIAL: 200,
  CONFLICTED: 409,
  VALIDATION_FAILED: 400,
  SCHEMA_INVALID: 400,
  CANDIDATE_MISMATCH: 400,
  INCOMPLETE: 400,
  EVIDENCE_NOT_READY: 400,
  EVIDENCE_INVALID: 400,
  SLOT_INVALID: 400,
  INSTRUMENT_MISMATCH: 400,
  UNAUTHENTICATED: 401,
  PERMISSION_DENIED: 403,
  SOD_VIOLATION: 403,
  ACCOUNT_NOT_ELIGIBLE: 403,
  NOT_OWNER: 403,
  NOT_FOUND: 404,
  DUPLICATE_CODE: 409,
  STATE_CONFLICT: 409,
  INVALID_STATE_TRANSITION: 409,
  CLOSURE_BLOCKED: 409,
  ASSIGNMENT_OVERLAP: 409,
  CAPACITY_EXCEEDED: 409,
  CAPACITY_BELOW_CURRENT_COUNT: 409,
  IMMUTABLE: 409,
  PUBLISHED_IMMUTABLE: 409,
  STALE_DRAFT: 409,
  CONFLICT_REVIEW_REQUIRED: 409,
  CONFLICT_OPEN: 409,
  ACTIVE_ASSOCIATION_EXISTS: 409,
  ASSOCIATION_REQUIRED: 409,
  ACTIVE_CLAIM_EXISTS: 409,
  CLAIM_INVALID: 409,
  SYNC_CONFLICT: 409,
  STALE_VERSION: 409,
  IDEMPOTENCY_KEY_REUSED: 409,
  LAST_ADMIN_PROTECTED: 409
};

export function mapCommandStatusToHttp(status: unknown): number {
  if (typeof status !== "string") return 500;
  return COMMAND_STATUS_HTTP_MAP[status] ?? 500;
}
