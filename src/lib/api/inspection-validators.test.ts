import { describe, expect, it } from "vitest";
import {
  isApproveInspectionInput,
  isClaimUnitInput,
  isConfirmUploadInput,
  isCreateUploadIntentInput,
  isDecideAbortInput,
  isRegisterDeviceBindingInput,
  isReleaseClaimInput,
  isReopenInspectionInput,
  isRequestAbortInput,
  isReturnInspectionInput,
  isSaveDraftInput,
  isSubmitInspectionInput,
  isSyncBatchInput
} from "./inspection-validators";

const U1 = "11111111-1111-4111-8111-111111111111";
const U2 = "22222222-2222-4222-8222-222222222222";
const U3 = "33333333-3333-4333-8333-333333333333";
const SHA = "a".repeat(64);

describe("Slice 3 inspection, evidence, SES-001 abort & offline sync validators", () => {
  it("validates claim/release and rejects invalid TTL bounds", () => {
    expect(isClaimUnitInput({ unit_id: U1, association_id: U2, assignment_id: U3, claim_ttl_minutes: 60 })).toBe(true);
    expect(isClaimUnitInput({ unit_id: U1, association_id: U2, assignment_id: U3, claim_ttl_minutes: 2 })).toBe(false);
    expect(isReleaseClaimInput({ claim_id: U1, expected_row_version: "1", reason: "Shift ended" })).toBe(true);
  });

  it("validates draft save, submit, return, approve, reopen, and SES-001 abort payloads", () => {
    expect(isSaveDraftInput({ inspection_id: U1, expected_row_version: "1", draft_checklist: { [U2]: "PASS" } })).toBe(true);
    expect(isSubmitInspectionInput({ inspection_id: U1, expected_row_version: "2" })).toBe(true);
    expect(isReturnInspectionInput({ inspection_id: U1, revision_id: U2, expected_revision_no: 1, reason: "Clarify photo" })).toBe(true);
    expect(isReturnInspectionInput({ inspection_id: U1, revision_id: U2, expected_revision_no: 1, reason: "no" })).toBe(false);
    expect(isApproveInspectionInput({ inspection_id: U1, revision_id: U2, expected_revision_no: 2 })).toBe(true);
    expect(isReopenInspectionInput({ inspection_id: U1, approved_revision_id: U2, expected_row_version: "5", reason: "Audit recount" })).toBe(true);
    expect(isRequestAbortInput({ inspection_id: U1, reason: "Unit sealed inside crate" })).toBe(true);
    expect(isDecideAbortInput({ abort_request_id: U1, decision: "APPROVE", expected_row_version: "1", reason: "Verified sealed pallet" })).toBe(true);
  });

  it("validates evidence intent/confirm and strictly rejects non-SAVE_DRAFT offline operations (T-09)", () => {
    expect(
      isCreateUploadIntentInput({
        inspection_id: U1,
        slot_definition_id: U2,
        mime_type: "image/jpeg",
        byte_size: 102400,
        sha256: SHA,
        client_file_id: "file-001"
      })
    ).toBe(true);
    expect(
      isConfirmUploadInput({
        evidence_asset_id: U1,
        observed_sha256: SHA,
        observed_byte_size: 102400,
        observed_mime: "image/jpeg"
      })
    ).toBe(true);
    expect(isRegisterDeviceBindingInput({ device_fingerprint_hash: SHA, label: "Android Chrome 01" })).toBe(true);
    expect(
      isSyncBatchInput({
        device_id: U1,
        batch_key: "batch-20261127-01",
        operations: [
          {
            operation_id: "op-0001",
            op_type: "SAVE_DRAFT",
            inspection_id: U2,
            expected_row_version: "2",
            payload: { notes: "Offline edit" }
          }
        ]
      })
    ).toBe(true);
    expect(
      isSyncBatchInput({
        device_id: U1,
        batch_key: "batch-20261127-02",
        operations: [
          {
            operation_id: "op-0002",
            op_type: "SUBMIT" as "SAVE_DRAFT",
            inspection_id: U2,
            expected_row_version: "2",
            payload: {}
          }
        ]
      })
    ).toBe(false);
  });
});
