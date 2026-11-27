import { isUuid, parseRowVersionString } from "@/lib/api/command-primitives";

export const SESSION_ACTIONS = [
  "ACTIVATE",
  "PAUSE",
  "RESUME",
  "REQUEST_CLOSE",
  "CLOSE",
  "REOPEN"
] as const;

export const OPERATIONAL_MEMBER_ROLES = [
  "korlap",
  "reviewer",
  "inspector",
  "print_officer"
] as const;

export const TARGET_PLAN_ACTIONS = [
  "CREATE_DRAFT",
  "REPLACE_DRAFT_ALLOCATIONS",
  "PUBLISH"
] as const;

export const ASSOCIATION_END_OUTCOMES = ["ENDED", "REVOKED"] as const;
export const CONFLICT_RESOLUTIONS = ["ASSOCIATE_EXISTING", "REJECT"] as const;

const CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{1,63}$/;
const INSTRUMENT_TYPE_PATTERN = /^[A-Za-z][A-Za-z0-9_]{1,63}$/;
const SHA256_HEX_PATTERN = /^[0-9a-f]{64}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

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

function isBoundedString(value: unknown, min: number, max: number): value is string {
  if (typeof value !== "string") return false;
  const len = value.trim().length;
  return len >= min && len <= max;
}

function isIsoTimestamp(value: unknown): value is string {
  return typeof value === "string" && !Number.isNaN(Date.parse(value));
}

// CMD-008: create-project
export type CreateProjectInput = { code: string; name: string; timezone?: string };
export function isCreateProjectInput(value: unknown): value is CreateProjectInput {
  if (!isPlainObjectWithAllowedKeys(value, ["code", "name", "timezone"])) return false;
  if (typeof value.code !== "string" || !CODE_PATTERN.test(value.code.trim())) return false;
  if (!isBoundedString(value.name, 2, 160)) return false;
  if (value.timezone !== undefined && !isBoundedString(value.timezone, 3, 64)) return false;
  return true;
}

// CMD-008 helpers: location & team
export type CreateScopedCodeEntityInput = { project_id: string; code: string; name: string };
export function isCreateScopedCodeEntityInput(
  value: unknown
): value is CreateScopedCodeEntityInput {
  if (!isPlainObjectWithAllowedKeys(value, ["project_id", "code", "name"])) return false;
  return (
    isUuid(value.project_id) &&
    typeof value.code === "string" &&
    CODE_PATTERN.test(value.code.trim()) &&
    isBoundedString(value.name, 2, 160)
  );
}

// CMD-009: update-project
export type UpdateProjectInput = {
  project_id: string;
  expected_row_version: string;
  name: string;
  timezone?: string | null;
};
export function isUpdateProjectInput(value: unknown): value is UpdateProjectInput {
  if (!isPlainObjectWithAllowedKeys(value, ["project_id", "expected_row_version", "name", "timezone"])) {
    return false;
  }
  if (value.timezone !== undefined && value.timezone !== null && !isBoundedString(value.timezone, 3, 64)) {
    return false;
  }
  return (
    isUuid(value.project_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.name, 2, 160)
  );
}

// CMD-010: close-project
export type CloseProjectInput = {
  project_id: string;
  expected_row_version: string;
  reason: string;
};
export function isCloseProjectInput(value: unknown): value is CloseProjectInput {
  if (!isPlainObjectWithAllowedKeys(value, ["project_id", "expected_row_version", "reason"])) {
    return false;
  }
  return (
    isUuid(value.project_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 5, 1000)
  );
}

// CMD-011: create-session
export type CreateSessionInput = {
  project_id: string;
  code: string;
  starts_at: string;
  ends_at: string;
};
export function isCreateSessionInput(value: unknown): value is CreateSessionInput {
  if (!isPlainObjectWithAllowedKeys(value, ["project_id", "code", "starts_at", "ends_at"])) {
    return false;
  }
  return (
    isUuid(value.project_id) &&
    typeof value.code === "string" &&
    CODE_PATTERN.test(value.code.trim()) &&
    isIsoTimestamp(value.starts_at) &&
    isIsoTimestamp(value.ends_at) &&
    Date.parse(value.ends_at) > Date.parse(value.starts_at)
  );
}

// CMD-012: update-session
export type UpdateSessionInput = {
  session_id: string;
  expected_row_version: string;
  starts_at: string;
  ends_at: string;
  reason: string;
};
export function isUpdateSessionInput(value: unknown): value is UpdateSessionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "session_id",
      "expected_row_version",
      "starts_at",
      "ends_at",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.session_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isIsoTimestamp(value.starts_at) &&
    isIsoTimestamp(value.ends_at) &&
    Date.parse(value.ends_at) > Date.parse(value.starts_at) &&
    isBoundedString(value.reason, 3, 1000)
  );
}

// CMD-013: transition-session
export type TransitionSessionInput = {
  session_id: string;
  action: (typeof SESSION_ACTIONS)[number];
  expected_row_version: string;
  reason: string;
};
export function isTransitionSessionInput(value: unknown): value is TransitionSessionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, ["session_id", "action", "expected_row_version", "reason"])
  ) {
    return false;
  }
  return (
    isUuid(value.session_id) &&
    typeof value.action === "string" &&
    (SESSION_ACTIONS as readonly string[]).includes(value.action) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 3, 1000)
  );
}

type AssignmentMemberItem = {
  user_id: string;
  operational_role: (typeof OPERATIONAL_MEMBER_ROLES)[number];
};

function isAssignmentMemberItem(value: unknown): value is AssignmentMemberItem {
  if (!isPlainObjectWithAllowedKeys(value, ["user_id", "operational_role"])) return false;
  return (
    isUuid(value.user_id) &&
    typeof value.operational_role === "string" &&
    (OPERATIONAL_MEMBER_ROLES as readonly string[]).includes(value.operational_role)
  );
}

// CMD-014: publish-assignment
export type PublishAssignmentInput = {
  project_id: string;
  session_id: string;
  location_id: string;
  instrument_id: string;
  instrument_version_id: string;
  team_id: string;
  starts_at: string;
  ends_at: string;
  members: AssignmentMemberItem[];
};
export function isPublishAssignmentInput(value: unknown): value is PublishAssignmentInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "project_id",
      "session_id",
      "location_id",
      "instrument_id",
      "instrument_version_id",
      "team_id",
      "starts_at",
      "ends_at",
      "members"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.project_id) &&
    isUuid(value.session_id) &&
    isUuid(value.location_id) &&
    isUuid(value.instrument_id) &&
    isUuid(value.instrument_version_id) &&
    isUuid(value.team_id) &&
    isIsoTimestamp(value.starts_at) &&
    isIsoTimestamp(value.ends_at) &&
    Date.parse(value.ends_at) > Date.parse(value.starts_at) &&
    Array.isArray(value.members) &&
    value.members.length >= 1 &&
    value.members.length <= 50 &&
    value.members.every(isAssignmentMemberItem)
  );
}

// CMD-015: change-assignment-members
export type ChangeAssignmentMembersInput = {
  assignment_id: string;
  add_members?: AssignmentMemberItem[];
  end_member_ids?: string[];
  reason: string;
};
export function isChangeAssignmentMembersInput(
  value: unknown
): value is ChangeAssignmentMembersInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "assignment_id",
      "add_members",
      "end_member_ids",
      "reason"
    ])
  ) {
    return false;
  }
  const add = value.add_members ?? [];
  const end = value.end_member_ids ?? [];
  if (!Array.isArray(add) || !Array.isArray(end)) return false;
  if (add.length === 0 && end.length === 0) return false;
  return (
    isUuid(value.assignment_id) &&
    add.every(isAssignmentMemberItem) &&
    end.every(isUuid) &&
    isBoundedString(value.reason, 3, 500)
  );
}

// CMD-016: change-inspector-capacity
export type ChangeInspectorCapacityInput = {
  project_id: string;
  inspector_cap: number;
  expected_row_version: string;
  reason: string;
};
export function isChangeInspectorCapacityInput(
  value: unknown
): value is ChangeInspectorCapacityInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "project_id",
      "inspector_cap",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.project_id) &&
    typeof value.inspector_cap === "number" &&
    Number.isInteger(value.inspector_cap) &&
    value.inspector_cap >= 1 &&
    value.inspector_cap <= 100 &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 3, 500)
  );
}

// CMD-017: manage-target-plan
export type ManageTargetPlanInput = {
  session_id: string;
  action: (typeof TARGET_PLAN_ACTIONS)[number];
  plan_id?: string | null;
  expected_row_version?: string | null;
  allocations?: Array<{ assignment_id: string; target_date: string; quantity: number }>;
};
export function isManageTargetPlanInput(value: unknown): value is ManageTargetPlanInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "session_id",
      "action",
      "plan_id",
      "expected_row_version",
      "allocations"
    ])
  ) {
    return false;
  }
  if (!isUuid(value.session_id)) return false;
  if (
    typeof value.action !== "string" ||
    !(TARGET_PLAN_ACTIONS as readonly string[]).includes(value.action)
  ) {
    return false;
  }
  if (value.plan_id !== undefined && value.plan_id !== null && !isUuid(value.plan_id)) return false;
  if (
    value.expected_row_version !== undefined &&
    value.expected_row_version !== null &&
    parseRowVersionString(value.expected_row_version) === null
  ) {
    return false;
  }
  if (value.allocations !== undefined) {
    if (!Array.isArray(value.allocations) || value.allocations.length > 500) return false;
    const validAllocs = value.allocations.every(
      (item) =>
        isPlainObjectWithAllowedKeys(item, ["assignment_id", "target_date", "quantity"]) &&
        isUuid(item.assignment_id) &&
        typeof item.target_date === "string" &&
        DATE_PATTERN.test(item.target_date) &&
        typeof item.quantity === "number" &&
        Number.isInteger(item.quantity) &&
        item.quantity >= 1 &&
        item.quantity <= 100000
    );
    if (!validAllocs) return false;
  }
  return true;
}

// CMD-018: create-instrument
export type CreateInstrumentInput = {
  instrument_type: string;
  code: string;
  name: string;
  description?: string | null;
  serial_case_insensitive?: boolean;
};
export function isCreateInstrumentInput(value: unknown): value is CreateInstrumentInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "instrument_type",
      "code",
      "name",
      "description",
      "serial_case_insensitive"
    ])
  ) {
    return false;
  }
  if (
    typeof value.instrument_type !== "string" ||
    !INSTRUMENT_TYPE_PATTERN.test(value.instrument_type.trim())
  ) {
    return false;
  }
  if (typeof value.code !== "string" || !CODE_PATTERN.test(value.code.trim())) return false;
  if (!isBoundedString(value.name, 2, 160)) return false;
  if (value.description !== undefined && value.description !== null) {
    if (typeof value.description !== "string" || value.description.trim().length > 1000) return false;
  }
  if (
    value.serial_case_insensitive !== undefined &&
    typeof value.serial_case_insensitive !== "boolean"
  ) {
    return false;
  }
  return true;
}

// CMD-019: save-instrument-draft
export type SaveInstrumentDraftInput = {
  instrument_id: string;
  version_id?: string | null;
  schema_version?: string;
  sections: unknown[];
  spec_fields?: unknown[];
  evidence_slots?: unknown[];
};
export function isSaveInstrumentDraftInput(value: unknown): value is SaveInstrumentDraftInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "instrument_id",
      "version_id",
      "schema_version",
      "sections",
      "spec_fields",
      "evidence_slots"
    ])
  ) {
    return false;
  }
  if (!isUuid(value.instrument_id)) return false;
  if (value.version_id !== undefined && value.version_id !== null && !isUuid(value.version_id)) {
    return false;
  }
  if (value.schema_version !== undefined && !isBoundedString(value.schema_version, 1, 32)) {
    return false;
  }
  if (!Array.isArray(value.sections) || value.sections.length > 50) return false;
  if (value.spec_fields !== undefined && (!Array.isArray(value.spec_fields) || value.spec_fields.length > 100)) {
    return false;
  }
  if (value.evidence_slots !== undefined && (!Array.isArray(value.evidence_slots) || value.evidence_slots.length > 50)) {
    return false;
  }
  return true;
}

// CMD-020: publish-instrument-version
export type PublishInstrumentVersionInput = {
  instrument_id: string;
  version_id: string;
  expected_draft_hash: string;
  change_summary: string;
};
export function isPublishInstrumentVersionInput(
  value: unknown
): value is PublishInstrumentVersionInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "instrument_id",
      "version_id",
      "expected_draft_hash",
      "change_summary"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.instrument_id) &&
    isUuid(value.version_id) &&
    typeof value.expected_draft_hash === "string" &&
    SHA256_HEX_PATTERN.test(value.expected_draft_hash) &&
    isBoundedString(value.change_summary, 3, 1000)
  );
}

// CMD-021: deactivate-instrument
export type DeactivateInstrumentInput = {
  instrument_id: string;
  expected_row_version: string;
  reason: string;
};
export function isDeactivateInstrumentInput(value: unknown): value is DeactivateInstrumentInput {
  if (!isPlainObjectWithAllowedKeys(value, ["instrument_id", "expected_row_version", "reason"])) {
    return false;
  }
  return (
    isUuid(value.instrument_id) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 3, 1000)
  );
}

// CMD-022: register-canonical-unit
export type RegisterCanonicalUnitInput = {
  project_id: string;
  instrument_id: string;
  serial_raw?: string | null;
  identity_attributes?: Record<string, unknown>;
};
export function isRegisterCanonicalUnitInput(value: unknown): value is RegisterCanonicalUnitInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "project_id",
      "instrument_id",
      "serial_raw",
      "identity_attributes"
    ])
  ) {
    return false;
  }
  if (!isUuid(value.project_id) || !isUuid(value.instrument_id)) return false;
  if (value.serial_raw !== undefined && value.serial_raw !== null) {
    if (typeof value.serial_raw !== "string" || value.serial_raw.length > 160) return false;
  }
  if (
    value.identity_attributes !== undefined &&
    (typeof value.identity_attributes !== "object" ||
      value.identity_attributes === null ||
      Array.isArray(value.identity_attributes))
  ) {
    return false;
  }
  return true;
}

// CMD-023: associate-unit-to-project
export type AssociateUnitInput = {
  unit_id: string;
  project_id: string;
  reason: string;
  evidence_ref?: string | null;
};
export function isAssociateUnitInput(value: unknown): value is AssociateUnitInput {
  if (!isPlainObjectWithAllowedKeys(value, ["unit_id", "project_id", "reason", "evidence_ref"])) {
    return false;
  }
  if (value.evidence_ref !== undefined && value.evidence_ref !== null) {
    if (typeof value.evidence_ref !== "string" || value.evidence_ref.trim().length > 200) return false;
  }
  return (
    isUuid(value.unit_id) &&
    isUuid(value.project_id) &&
    isBoundedString(value.reason, 3, 500)
  );
}

// CMD-024: end-unit-project-association
export type EndUnitAssociationInput = {
  association_id: string;
  outcome: (typeof ASSOCIATION_END_OUTCOMES)[number];
  expected_row_version: string;
  reason: string;
};
export function isEndUnitAssociationInput(value: unknown): value is EndUnitAssociationInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "association_id",
      "outcome",
      "expected_row_version",
      "reason"
    ])
  ) {
    return false;
  }
  return (
    isUuid(value.association_id) &&
    typeof value.outcome === "string" &&
    (ASSOCIATION_END_OUTCOMES as readonly string[]).includes(value.outcome) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 3, 500)
  );
}

// CMD-025: resolve-unit-identity-conflict
export type ResolveUnitConflictInput = {
  conflict_id: string;
  resolution: (typeof CONFLICT_RESOLUTIONS)[number];
  expected_row_version: string;
  reason: string;
  verified_unit_id?: string | null;
};
export function isResolveUnitConflictInput(value: unknown): value is ResolveUnitConflictInput {
  if (
    !isPlainObjectWithAllowedKeys(value, [
      "conflict_id",
      "resolution",
      "expected_row_version",
      "reason",
      "verified_unit_id"
    ])
  ) {
    return false;
  }
  if (
    value.verified_unit_id !== undefined &&
    value.verified_unit_id !== null &&
    !isUuid(value.verified_unit_id)
  ) {
    return false;
  }
  return (
    isUuid(value.conflict_id) &&
    typeof value.resolution === "string" &&
    (CONFLICT_RESOLUTIONS as readonly string[]).includes(value.resolution) &&
    parseRowVersionString(value.expected_row_version) !== null &&
    isBoundedString(value.reason, 5, 1000)
  );
}
