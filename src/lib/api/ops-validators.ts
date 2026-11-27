import { isUuid, parseRowVersionString } from "@/lib/api/command-primitives";
import { ALLOWED_EVIDENCE_MIMES } from "@/lib/api/inspection-validators";

export const DOCUMENT_TYPES = ["INSPECTION_PDF", "BA_PDF"] as const;
export const ATTENDANCE_DECISIONS = ["VERIFY", "REJECT"] as const;
export const NOTIFICATION_SCOPE_TYPES = ["GLOBAL", "PROJECT"] as const;
export const NOTIFICATION_SLA_MODES = ["ELAPSED_UTC", "BUSINESS_TIME"] as const;

const SHA256_HEX_PATTERN = /^[0-9a-f]{64}$/i;
const POLICY_KEY_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_.-]{2,63}$/;

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

// CMD-036: generate-approved-document
export type GenerateDocumentInput = {
  document_type: (typeof DOCUMENT_TYPES)[number];
  inspection_id: string;
  approved_revision_id: string;
  template_version_id: string;
};
export function isGenerateDocumentInput(value: unknown): value is GenerateDocumentInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "document_type",
      "inspection_id",
      "approved_revision_id",
      "template_version_id"
    ])
  ) {
    return false;
  }
  return (
    typeof value.document_type === "string" &&
    (DOCUMENT_TYPES as readonly string[]).includes(value.document_type) &&
    isUuid(value.inspection_id) &&
    isUuid(value.approved_revision_id) &&
    isUuid(value.template_version_id)
  );
}

// CMD-037: record-print
export type RecordPrintInput = {
  document_id: string;
  expected_document_version: number;
  expected_sequence?: number | null;
  client_print_signal?: string | null;
};
export function isRecordPrintInput(value: unknown): value is RecordPrintInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "document_id",
      "expected_document_version",
      "expected_sequence",
      "client_print_signal"
    ])
  ) {
    return false;
  }
  if (
    value.expected_sequence !== undefined &&
    value.expected_sequence !== null &&
    (typeof value.expected_sequence !== "number" ||
      !Number.isInteger(value.expected_sequence) ||
      value.expected_sequence < 0)
  ) {
    return false;
  }
  if (value.client_print_signal !== undefined && value.client_print_signal !== null) {
    if (typeof value.client_print_signal !== "string" || value.client_print_signal.trim().length > 100) {
      return false;
    }
  }
  return (
    isUuid(value.document_id) &&
    typeof value.expected_document_version === "number" &&
    Number.isInteger(value.expected_document_version) &&
    value.expected_document_version >= 1
  );
}

// CMD-038: record-print-batch
export type PrintBatchItemInput = {
  item_key: string;
  document_id: string;
  expected_document_version: number;
};
export type RecordPrintBatchInput = {
  project_id: string;
  session_id: string;
  items: PrintBatchItemInput[];
};
export function isRecordPrintBatchInput(value: unknown): value is RecordPrintBatchInput {
  if (!isPlainObjectWithAllowedKeys(value, ["project_id", "session_id", "items"])) return false;
  if (!isUuid(value.project_id) || !isUuid(value.session_id)) return false;
  if (!Array.isArray(value.items) || value.items.length < 1 || value.items.length > 100) return false;
  return value.items.every(
    (item) =>
      isPlainObjectWithAllowedKeys(item, ["item_key", "document_id", "expected_document_version"]) &&
      isBoundedString(item.item_key, 1, 128) &&
      isUuid(item.document_id) &&
      typeof item.expected_document_version === "number" &&
      Number.isInteger(item.expected_document_version) &&
      item.expected_document_version >= 1
  );
}

// CMD-039: upload-attendance-document
export type UploadAttendanceInput = {
  project_id: string;
  session_id: string;
  location_id: string;
  sha256: string;
  byte_size: number;
  mime_type: (typeof ALLOWED_EVIDENCE_MIMES)[number];
  replacement_reason?: string | null;
};
export function isUploadAttendanceInput(value: unknown): value is UploadAttendanceInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "project_id",
      "session_id",
      "location_id",
      "sha256",
      "byte_size",
      "mime_type",
      "replacement_reason"
    ])
  ) {
    return false;
  }
  if (value.replacement_reason !== undefined && value.replacement_reason !== null) {
    if (typeof value.replacement_reason !== "string" || value.replacement_reason.trim().length > 500) {
      return false;
    }
  }
  return (
    isUuid(value.project_id) &&
    isUuid(value.session_id) &&
    isUuid(value.location_id) &&
    typeof value.sha256 === "string" &&
    SHA256_HEX_PATTERN.test(value.sha256) &&
    typeof value.byte_size === "number" &&
    Number.isInteger(value.byte_size) &&
    value.byte_size >= 1 &&
    value.byte_size <= 15728640 &&
    typeof value.mime_type === "string" &&
    (ALLOWED_EVIDENCE_MIMES as readonly string[]).includes(value.mime_type)
  );
}

// CMD-040: verify-attendance
export type VerifyAttendanceInput = {
  attendance_record_id: string;
  attendance_document_id: string;
  decision: (typeof ATTENDANCE_DECISIONS)[number];
  expected_row_version: string;
  reason?: string | null;
};
export function isVerifyAttendanceInput(value: unknown): value is VerifyAttendanceInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "attendance_record_id",
      "attendance_document_id",
      "decision",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  if (value.reason !== undefined && value.reason !== null) {
    if (typeof value.reason !== "string" || value.reason.trim().length > 1000) return false;
  }
  return (
    isUuid(value.attendance_record_id) &&
    isUuid(value.attendance_document_id) &&
    typeof value.decision === "string" &&
    (ATTENDANCE_DECISIONS as readonly string[]).includes(value.decision) &&
    parseRowVersionString(value.expected_row_version) !== null
  );
}

// CMD-043: read-audit
export type ReadAuditInput = {
  purpose: string;
  limit?: number;
  event_type?: string | null;
};
export function isReadAuditInput(value: unknown): value is ReadAuditInput {
  if (!isPlainObjectWithAllowedKeys(value, ["purpose", "limit", "event_type"])) return false;
  if (
    value.limit !== undefined &&
    (typeof value.limit !== "number" || !Number.isInteger(value.limit) || value.limit < 1 || value.limit > 100)
  ) {
    return false;
  }
  if (value.event_type !== undefined && value.event_type !== null) {
    if (!isBoundedString(value.event_type, 3, 128)) return false;
  }
  return isBoundedString(value.purpose, 5, 500);
}

// CMD-050: mark-notification-read (POQ-03: read_at ONLY, never dismissed_at!)
export type MarkNotificationReadInput = { notification_id: string };
export function isMarkNotificationReadInput(value: unknown): value is MarkNotificationReadInput {
  return isPlainObjectWithAllowedKeys(value, ["notification_id"]) && isUuid(value.notification_id);
}

// CMD-051: publish-notification-policy (POQ-02)
export type PublishNotificationPolicyInput = {
  policy_key: string;
  scope_type: (typeof NOTIFICATION_SCOPE_TYPES)[number];
  scope_id?: string | null;
  sla_mode?: (typeof NOTIFICATION_SLA_MODES)[number];
  policy_document: Record<string, unknown>;
};
export function isPublishNotificationPolicyInput(
  value: unknown
): value is PublishNotificationPolicyInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "policy_key",
      "scope_type",
      "scope_id",
      "sla_mode",
      "policy_document"
    ])
  ) {
    return false;
  }
  if (typeof value.policy_key !== "string" || !POLICY_KEY_PATTERN.test(value.policy_key.trim())) {
    return false;
  }
  if (
    typeof value.scope_type !== "string" ||
    !(NOTIFICATION_SCOPE_TYPES as readonly string[]).includes(value.scope_type)
  ) {
    return false;
  }
  if (value.scope_id !== undefined && value.scope_id !== null && !isUuid(value.scope_id)) {
    return false;
  }
  if (
    value.sla_mode !== undefined &&
    (typeof value.sla_mode !== "string" ||
      !(NOTIFICATION_SLA_MODES as readonly string[]).includes(value.sla_mode))
  ) {
    return false;
  }
  return isPlainObject(value.policy_document);
}
