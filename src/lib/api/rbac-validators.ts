import { isUuid, parseRowVersionString } from "@/lib/api/command-primitives";

export const REJECTION_CATEGORIES = [
  "UNVERIFIED_IDENTITY",
  "OUT_OF_SCOPE_PERSONNEL",
  "DUPLICATE_ACCOUNT",
  "INCOMPLETE_INFORMATION",
  "POLICY_RESTRICTION"
] as const;

export const CANONICAL_ROLE_CODES = [
  "super_admin",
  "admin",
  "korlap",
  "reviewer",
  "inspector",
  "print_officer"
] as const;

export const CANONICAL_SCOPE_TYPES = [
  "PROJECT",
  "SESSION",
  "LOCATION",
  "INSTRUMENT",
  "TEAM",
  "ASSIGNMENT"
] as const;

export const ALLOWED_TRANSITION_ACCOUNT_STATUSES = [
  "SUSPENDED",
  "DISABLED",
  "APPROVED"
] as const;

function isPlainObjectWithAllowedKeys(
  value: unknown,
  allowedKeys: readonly string[]
): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return false;
  }
  const allowed = new Set(allowedKeys);
  return Object.keys(value).every((key) => allowed.has(key));
}

function isBoundedNonEmptyString(value: unknown, min: number, max: number): value is string {
  if (typeof value !== "string") return false;
  const len = value.trim().length;
  return len >= min && len <= max;
}

function isOptionalIsoTimestamp(value: unknown): value is string | null | undefined {
  if (value === undefined || value === null) return true;
  return typeof value === "string" && !Number.isNaN(Date.parse(value));
}

export type RequestAccountAccessInput = {
  display_name: string;
  request_note?: string | null;
};

export function isRequestAccountAccessInput(value: unknown): value is RequestAccountAccessInput {
  if (!isPlainObjectWithAllowedKeys(value, ["display_name", "request_note"])) return false;
  if (!isBoundedNonEmptyString(value.display_name, 2, 120)) return false;
  if (value.request_note !== undefined && value.request_note !== null) {
    if (typeof value.request_note !== "string" || value.request_note.trim().length > 500) {
      return false;
    }
  }
  return true;
}

export type ApproveAccountInput = {
  request_id: string;
  expected_row_version: string;
  reason: string;
};

export function isApproveAccountInput(value: unknown): value is ApproveAccountInput {
  if (!isPlainObjectWithAllowedKeys(value, ["request_id", "expected_row_version", "reason"])) {
    return false;
  }
  return (
    isUuid(value.request_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedNonEmptyString(value.reason, 3, 1000)
  );
}

export type RejectAccountInput = {
  request_id: string;
  expected_row_version: string;
  rejection_category: (typeof REJECTION_CATEGORIES)[number];
  reason: string;
};

export function isRejectAccountInput(value: unknown): value is RejectAccountInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "request_id",
      "expected_row_version",
      "rejection_category",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.request_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    typeof value.rejection_category === "string" &&
    (REJECTION_CATEGORIES as readonly string[]).includes(value.rejection_category) &&
    isBoundedNonEmptyString(value.reason, 5, 1000)
  );
}

export type TransitionAccountStatusInput = {
  target_user_id: string;
  target_status: (typeof ALLOWED_TRANSITION_ACCOUNT_STATUSES)[number];
  expected_row_version: string;
  reason: string;
};

export function isTransitionAccountStatusInput(
  value: unknown
): value is TransitionAccountStatusInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "target_user_id",
      "target_status",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.target_user_id) &&
    typeof value.target_status === "string" &&
    (ALLOWED_TRANSITION_ACCOUNT_STATUSES as readonly string[]).includes(value.target_status) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedNonEmptyString(value.reason, 3, 1000)
  );
}

export type GrantRoleInput = {
  target_user_id: string;
  role_code: (typeof CANONICAL_ROLE_CODES)[number];
  project_id?: string | null;
  valid_from?: string | null;
  valid_until?: string | null;
  reason: string;
};

export function isGrantRoleInput(value: unknown): value is GrantRoleInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "target_user_id",
      "role_code",
      "project_id",
      "valid_from",
      "valid_until",
      "reason"
    ])
  ) {
    return false;
  }
  if (!isUuid(value.target_user_id)) return false;
  if (
    typeof value.role_code !== "string" ||
    !(CANONICAL_ROLE_CODES as readonly string[]).includes(value.role_code)
  ) {
    return false;
  }
  if (value.project_id !== undefined && value.project_id !== null && !isUuid(value.project_id)) {
    return false;
  }
  if (!isOptionalIsoTimestamp(value.valid_from) || !isOptionalIsoTimestamp(value.valid_until)) {
    return false;
  }
  return isBoundedNonEmptyString(value.reason, 3, 500);
}

export type RevokeRoleInput = {
  user_role_id: string;
  expected_row_version: string;
  reason: string;
};

export function isRevokeRoleInput(value: unknown): value is RevokeRoleInput {
  if (!isPlainObjectWithAllowedKeys(value, ["user_role_id", "expected_row_version", "reason"])) {
    return false;
  }
  return (
    isUuid(value.user_role_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedNonEmptyString(value.reason, 3, 500)
  );
}

export type GrantScopeInput = {
  target_user_id: string;
  scope_type: (typeof CANONICAL_SCOPE_TYPES)[number];
  scope_id: string;
  valid_from?: string | null;
  valid_until?: string | null;
  reason: string;
};

export function isGrantScopeInput(value: unknown): value is GrantScopeInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "target_user_id",
      "scope_type",
      "scope_id",
      "valid_from",
      "valid_until",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.target_user_id) &&
    typeof value.scope_type === "string" &&
    (CANONICAL_SCOPE_TYPES as readonly string[]).includes(value.scope_type) &&
    isUuid(value.scope_id) &&
    isOptionalIsoTimestamp(value.valid_from) &&
    isOptionalIsoTimestamp(value.valid_until) &&
    isBoundedNonEmptyString(value.reason, 3, 500)
  );
}

export type RevokeScopeInput = {
  scope_grant_id: string;
  expected_row_version: string;
  reason: string;
};

export function isRevokeScopeInput(value: unknown): value is RevokeScopeInput {
  if (!isPlainObjectWithAllowedKeys(value, ["scope_grant_id", "expected_row_version", "reason"])) {
    return false;
  }
  return (
    isUuid(value.scope_grant_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedNonEmptyString(value.reason, 3, 500)
  );
}
