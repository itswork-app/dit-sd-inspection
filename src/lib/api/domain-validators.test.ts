import { describe, expect, it } from "vitest";
import {
  isAssociateUnitInput,
  isChangeAssignmentMembersInput,
  isChangeInspectorCapacityInput,
  isCloseProjectInput,
  isCreateInstrumentInput,
  isCreateProjectInput,
  isCreateSessionInput,
  isDeactivateInstrumentInput,
  isEndUnitAssociationInput,
  isManageTargetPlanInput,
  isPublishAssignmentInput,
  isPublishInstrumentVersionInput,
  isRegisterCanonicalUnitInput,
  isResolveUnitConflictInput,
  isSaveInstrumentDraftInput,
  isTransitionSessionInput,
  isUpdateProjectInput,
  isUpdateSessionInput
} from "./domain-validators";

const U1 = "11111111-1111-4111-8111-111111111111";
const U2 = "22222222-2222-4222-8222-222222222222";
const HASH64 = "a".repeat(64);

describe("Slice 2 domain strict allowlist validators (CMD-008..025)", () => {
  it("validates project create/update/close payloads and rejects unknown fields", () => {
    expect(isCreateProjectInput({ code: "PRJ-01", name: "Synthetic Project" })).toBe(true);
    expect(isCreateProjectInput({ code: "PRJ-01", name: "Synthetic", status: "ACTIVE" })).toBe(false);
    expect(isUpdateProjectInput({ project_id: U1, expected_row_version: "1", name: "Updated" })).toBe(true);
    expect(isCloseProjectInput({ project_id: U1, expected_row_version: "2", reason: "All sessions closed" })).toBe(true);
    expect(isCloseProjectInput({ project_id: U1, expected_row_version: "2", reason: "no" })).toBe(false);
  });

  it("validates session create/update/transition and enforces interval ordering", () => {
    const t1 = "2026-11-27T01:00:00Z";
    const t2 = "2026-11-27T09:00:00Z";
    expect(isCreateSessionInput({ project_id: U1, code: "SESS-01", starts_at: t1, ends_at: t2 })).toBe(true);
    expect(isCreateSessionInput({ project_id: U1, code: "SESS-01", starts_at: t2, ends_at: t1 })).toBe(false);
    expect(isUpdateSessionInput({ session_id: U1, expected_row_version: "1", starts_at: t1, ends_at: t2, reason: "Shift update" })).toBe(true);
    expect(isTransitionSessionInput({ session_id: U1, action: "REQUEST_CLOSE", expected_row_version: "2", reason: "Ready for closure" })).toBe(true);
    expect(isTransitionSessionInput({ session_id: U1, action: "PLANNED", expected_row_version: "2", reason: "Invalid state" })).toBe(false);
  });

  it("validates assignments, T-14 capacity 1..100 bounds, and target plans", () => {
    const t1 = "2026-11-27T01:00:00Z";
    const t2 = "2026-11-27T05:00:00Z";
    expect(
      isPublishAssignmentInput({
        project_id: U1,
        session_id: U1,
        location_id: U1,
        instrument_id: U1,
        instrument_version_id: U1,
        team_id: U1,
        starts_at: t1,
        ends_at: t2,
        members: [{ user_id: U2, operational_role: "inspector" }]
      })
    ).toBe(true);
    expect(isChangeAssignmentMembersInput({ assignment_id: U1, end_member_ids: [U2], reason: "Rotation" })).toBe(true);
    expect(isChangeAssignmentMembersInput({ assignment_id: U1, reason: "Empty mutation" })).toBe(false);
    expect(isChangeInspectorCapacityInput({ project_id: U1, inspector_cap: 50, expected_row_version: "1", reason: "Standard cap" })).toBe(true);
    expect(isChangeInspectorCapacityInput({ project_id: U1, inspector_cap: 0, expected_row_version: "1", reason: "Zero forbidden" })).toBe(false);
    expect(isChangeInspectorCapacityInput({ project_id: U1, inspector_cap: 101, expected_row_version: "1", reason: "Over 100 forbidden" })).toBe(false);
    expect(
      isManageTargetPlanInput({
        session_id: U1,
        action: "REPLACE_DRAFT_ALLOCATIONS",
        plan_id: U2,
        expected_row_version: "1",
        allocations: [{ assignment_id: U1, target_date: "2026-11-27", quantity: 10 }]
      })
    ).toBe(true);
    expect(
      isManageTargetPlanInput({
        session_id: U1,
        action: "REPLACE_DRAFT_ALLOCATIONS",
        plan_id: U2,
        expected_row_version: "1",
        allocations: [{ assignment_id: U1, target_date: "2026-11-27", quantity: 0 }]
      })
    ).toBe(false);
  });

  it("validates CFG-001/T-17 instruments and T-16 canonical units/associations/conflicts", () => {
    expect(isCreateInstrumentInput({ instrument_type: "IFP_75", code: "IFP-75", name: "IFP 75 Inch" })).toBe(true);
    expect(isSaveInstrumentDraftInput({ instrument_id: U1, sections: [] })).toBe(true);
    expect(
      isPublishInstrumentVersionInput({
        instrument_id: U1,
        version_id: U2,
        expected_draft_hash: HASH64,
        change_summary: "Initial publish"
      })
    ).toBe(true);
    expect(isDeactivateInstrumentInput({ instrument_id: U1, expected_row_version: "2", reason: "Retired model" })).toBe(true);
    expect(isRegisterCanonicalUnitInput({ project_id: U1, instrument_id: U2, serial_raw: "SN-001" })).toBe(true);
    expect(isAssociateUnitInput({ unit_id: U1, project_id: U2, reason: "Transfer unit" })).toBe(true);
    expect(isEndUnitAssociationInput({ association_id: U1, outcome: "ENDED", expected_row_version: "1", reason: "Completed" })).toBe(true);
    expect(
      isResolveUnitConflictInput({
        conflict_id: U1,
        resolution: "ASSOCIATE_EXISTING",
        expected_row_version: "1",
        reason: "Verified physical match",
        verified_unit_id: U2
      })
    ).toBe(true);
  });
});
