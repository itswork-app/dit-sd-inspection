import { isUuid, parseRowVersionString } from "@/lib/api/command-primitives";

export const ALLOWED_EVIDENCE_MIMES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf"
] as const;

export const ABORT_DECISIONS = ["APPROVE", "REJECT"] as const;

const SHA256_HEX_PATTERN = /^[0-9a-f]{64}$/i;

function isPlainObjectWithAllowedKeys(
  value: unknown,
  allowedKeys: readonly string[]
): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const allowed = new Set(allowedKeys);
  return Object.keys(value).every((key) => allowed.has(key));
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isBoundedString(value: unknown, min: number, max: number): value is string {
  if (typeof value !== "string") return false;
  const len = value.trim().length;
  return len >= min && len <= max;
}

// CMD-026: claim-unit
export type ClaimUnitInput = {
  unit_id: string;
  association_id: string;
  assignment_id: string;
  claim_ttl_minutes?: number;
};
export function isClaimUnitInput(value: unknown): value is ClaimUnitInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "unit_id",
      "association_id",
      "assignment_id",
      "claim_ttl_minutes"
    ])
  ) {
    return false;
  }
  if (
    value.claim_ttl_minutes !== undefined &&
    (typeof value.claim_ttl_minutes !== "number" ||
      !Number.isInteger(value.claim_ttl_minutes) ||
      value.claim_ttl_minutes < 5 ||
      value.claim_ttl_minutes > 480)
  ) {
    return false;
  }
  return isUuid(value.unit_id) && isUuid(value.association_id) && isUuid(value.assignment_id);
}

// CMD-027: release-unit-claim
export type ReleaseClaimInput = {
  claim_id: string;
  expected_row_version: string;
  reason?: string | null;
};
export function isReleaseClaimInput(value: unknown): value is ReleaseClaimInput {
  if (!isPlainObjectWithAllowedKeys(value, ["claim_id", "expected_row_version", "reason"])) {
    return false;
  }
  if (value.reason !== undefined && value.reason !== null) {
    if (typeof value.reason !== "string" || value.reason.trim().length > 500) return false;
  }
  return isUuid(value.claim_id) && parseRowVersionString(value.expected_row_version) !== null;
}

// CMD-028: save-draft
export type SaveDraftInput = {
  inspection_id: string;
  expected_row_version: string;
  draft_checklist: Record<string, unknown>;
  draft_specifications?: Record<string, unknown>;
  notes?: string | null;
};
export function isSaveDraftInput(value: unknown): value is SaveDraftInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "inspection_id",
      "expected_row_version",
      "draft_checklist",
      "draft_specifications",
      "notes"
    ])
  ) {
    return false;
  }
  if (!isUuid(value.inspection_id) || parseRowVersionString(value.expected_row_version) === null) {
    return false;
  }
  if (!isPlainObject(value.draft_checklist)) return false;
  if (value.draft_specifications !== undefined && !isPlainObject(value.draft_specifications)) {
    return false;
  }
  if (value.notes !== undefined && value.notes !== null) {
    if (typeof value.notes !== "string" || value.notes.length > 2000) return false;
  }
  return true;
}

// CMD-029: submit-inspection
export type SubmitInspectionInput = {
  inspection_id: string;
  expected_row_version: string;
  submit_reason?: string | null;
};
export function isSubmitInspectionInput(value: unknown): value is SubmitInspectionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, ["inspection_id", "expected_row_version", "submit_reason"])
  ) {
    return false;
  }
  if (value.submit_reason !== undefined && value.submit_reason !== null) {
    if (typeof value.submit_reason !== "string" || value.submit_reason.trim().length > 500) {
      return false;
    }
  }
  return isUuid(value.inspection_id) && parseRowVersionString(value.expected_row_version) !== null;
}

// CMD-030: return-inspection
export type ReturnInspectionInput = {
  inspection_id: string;
  revision_id: string;
  expected_revision_no: number;
  reason: string;
};
export function isReturnInspectionInput(value: unknown): value is ReturnInspectionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "inspection_id",
      "revision_id",
      "expected_revision_no",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.inspection_id) &&
    isUuid(value.revision_id) &&
    typeof value.expected_revision_no === "number" &&
    Number.isInteger(value.expected_revision_no) &&
    value.expected_revision_no >= 1 &&
    isBoundedString(value.reason, 5, 1000)
  );
}

// CMD-031: approve-inspection
export type ApproveInspectionInput = {
  inspection_id: string;
  revision_id: string;
  expected_revision_no: number;
  reason?: string | null;
};
export function isApproveInspectionInput(value: unknown): value is ApproveInspectionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "inspection_id",
      "revision_id",
      "expected_revision_no",
      "reason"
    ])
  ) {
    return false;
  }
  if (value.reason !== undefined && value.reason !== null) {
    if (typeof value.reason !== "string" || value.reason.trim().length > 1000) return false;
  }
  return (
    isUuid(value.inspection_id) &&
    isUuid(value.revision_id) &&
    typeof value.expected_revision_no === "number" &&
    Number.isInteger(value.expected_revision_no) &&
    value.expected_revision_no >= 1
  );
}

// CMD-032: reopen-inspection
export type ReopenInspectionInput = {
  inspection_id: string;
  approved_revision_id: string;
  expected_row_version: string;
  reason: string;
};
export function isReopenInspectionInput(value: unknown): value is ReopenInspectionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "inspection_id",
      "approved_revision_id",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.inspection_id) &&
    isUuid(value.approved_revision_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 5, 1000)
  );
}

// CMD-033: create-upload-intent
export type CreateUploadIntentInput = {
  inspection_id: string;
  slot_definition_id: string;
  mime_type: (typeof ALLOWED_EVIDENCE_MIMES)[number];
  byte_size: number;
  sha256: string;
  client_file_id: string;
};
export function isCreateUploadIntentInput(value: unknown): value is CreateUploadIntentInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "inspection_id",
      "slot_definition_id",
      "mime_type",
      "byte_size",
      "sha256",
      "client_file_id"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.inspection_id) &&
    isUuid(value.slot_definition_id) &&
    typeof value.mime_type === "string" &&
    (ALLOWED_EVIDENCE_MIMES as readonly string[]).includes(value.mime_type) &&
    typeof value.byte_size === "number" &&
    Number.isInteger(value.byte_size) &&
    value.byte_size >= 1 &&
    value.byte_size <= 15728640 &&
    typeof value.sha256 === "string" &&
    SHA256_HEX_PATTERN.test(value.sha256) &&
    isBoundedString(value.client_file_id, 4, 128)
  );
}

// CMD-034: confirm-upload
export type ConfirmUploadInput = {
  evidence_asset_id: string;
  observed_sha256: string;
  observed_byte_size: number;
  observed_mime: (typeof ALLOWED_EVIDENCE_MIMES)[number];
};
export function isConfirmUploadInput(value: unknown): value is ConfirmUploadInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "evidence_asset_id",
      "observed_sha256",
      "observed_byte_size",
      "observed_mime"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.evidence_asset_id) &&
    typeof value.observed_sha256 === "string" &&
    SHA256_HEX_PATTERN.test(value.observed_sha256) &&
    typeof value.observed_byte_size === "number" &&
    Number.isInteger(value.observed_byte_size) &&
    value.observed_byte_size >= 1 &&
    value.observed_byte_size <= 15728640 &&
    typeof value.observed_mime === "string" &&
    (ALLOWED_EVIDENCE_MIMES as readonly string[]).includes(value.observed_mime)
  );
}

// Device Binding (T-09)
export type RegisterDeviceBindingInput = {
  device_fingerprint_hash: string;
  label: string;
};
export function isRegisterDeviceBindingInput(value: unknown): value is RegisterDeviceBindingInput {
  if (!isPlainObjectWithAllowedKeys(value, ["device_fingerprint_hash", "label"])) return false;
  return (
    typeof value.device_fingerprint_hash === "string" &&
    SHA256_HEX_PATTERN.test(value.device_fingerprint_hash) &&
    isBoundedString(value.label, 2, 100)
  );
}

// CMD-035: sync-batch
export type SyncBatchOperationInput = {
  operation_id: string;
  op_type: "SAVE_DRAFT";
  inspection_id: string;
  expected_row_version: string;
  payload: Record<string, unknown>;
};
export type SyncBatchInput = {
  device_id: string;
  batch_key: string;
  operations: SyncBatchOperationInput[];
};
export function isSyncBatchInput(value: unknown): value is SyncBatchInput {
  if (!isPlainObjectWithAllowedKeys(value, ["device_id", "batch_key", "operations"])) return false;
  if (!isUuid(value.device_id) || !isBoundedString(value.batch_key, 8, 128)) return false;
  if (!Array.isArray(value.operations) || value.operations.length < 1 || value.operations.length > 50) {
    return false;
  }
  return value.operations.every(
    (op) =>
      isPlainObjectWithAllowedKeys(op, [
        "operation_id",
        "op_type",
        "inspection_id",
        "expected_row_version",
        "payload"
      ]) &&
      isBoundedString(op.operation_id, 4, 128) &&
      op.op_type === "SAVE_DRAFT" &&
      isUuid(op.inspection_id) &&
      parseRowVersionString(op.expected_row_version) !== null &&
      isPlainObject(op.payload)
  );
}

// CMD-055: request-packed-unit-abort (SES-001)
export type RequestAbortInput = {
  inspection_id: string;
  reason: string;
};
export function isRequestAbortInput(value: unknown): value is RequestAbortInput {
  if (!isPlainObjectWithAllowedKeys(value, ["inspection_id", "reason"])) return false;
  return isUuid(value.inspection_id) && isBoundedString(value.reason, 5, 1000);
}

// CMD-056: decide-packed-unit-abort (SES-001)
export type DecideAbortInput = {
  abort_request_id: string;
  decision: (typeof ABORT_DECISIONS)[number];
  expected_row_version: string;
  reason: string;
};
export function isDecideAbortInput(value: unknown): value is DecideAbortInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "abort_request_id",
      "decision",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.abort_request_id) &&
    typeof value.decision === "string" &&
    (ABORT_DECISIONS as readonly string[]).includes(value.decision) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 5, 1000)
  );
}
