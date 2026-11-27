import { describe, expect, it } from "vitest";
import {
  isGenerateDocumentInput,
  isMarkNotificationReadInput,
  isPublishNotificationPolicyInput,
  isReadAuditInput,
  isRecordPrintBatchInput,
  isRecordPrintInput,
  isUploadAttendanceInput,
  isVerifyAttendanceInput
} from "./ops-validators";

const U1 = "11111111-1111-4111-8111-111111111111";
const U2 = "22222222-2222-4222-8222-222222222222";
const U3 = "33333333-3333-4333-8333-333333333333";
const SHA = "f".repeat(64);

describe("Slice 4 documents, print, attendance, audit, and notification validators", () => {
  it("validates CMD-036..038 document generation and print payloads", () => {
    expect(
      isGenerateDocumentInput({
        document_type: "INSPECTION_PDF",
        inspection_id: U1,
        approved_revision_id: U2,
        template_version_id: U3
      })
    ).toBe(true);
    expect(
      isRecordPrintInput({
        document_id: U1,
        expected_document_version: 2,
        expected_sequence: 0,
        client_print_signal: "browser-print"
      })
    ).toBe(true);
    expect(
      isRecordPrintBatchInput({
        project_id: U1,
        session_id: U2,
        items: [{ item_key: "doc-1", document_id: U3, expected_document_version: 1 }]
      })
    ).toBe(true);
    expect(isRecordPrintBatchInput({ project_id: U1, session_id: U2, items: [] })).toBe(false);
  });

  it("validates CMD-039..040 attendance and CMD-043 audit read payloads", () => {
    expect(
      isUploadAttendanceInput({
        project_id: U1,
        session_id: U2,
        location_id: U3,
        sha256: SHA,
        byte_size: 4096,
        mime_type: "application/pdf"
      })
    ).toBe(true);
    expect(
      isVerifyAttendanceInput({
        attendance_record_id: U1,
        attendance_document_id: U2,
        decision: "VERIFY",
        expected_row_version: "1"
      })
    ).toBe(true);
    expect(isReadAuditInput({ purpose: "Monthly oversight review", limit: 25 })).toBe(true);
    expect(isReadAuditInput({ purpose: "no" })).toBe(false);
  });

  it("validates CMD-050/051 notifications and rejects dormant dismissed_at fields (POQ-03)", () => {
    expect(isMarkNotificationReadInput({ notification_id: U1 })).toBe(true);
    expect(
      isMarkNotificationReadInput({ notification_id: U1, dismissed_at: "2026-11-27T00:00:00Z" })
    ).toBe(false);
    expect(
      isPublishNotificationPolicyInput({
        policy_key: "SLA_DEFAULT",
        scope_type: "GLOBAL",
        sla_mode: "ELAPSED_UTC",
        policy_document: { sla_minutes: 60 }
      })
    ).toBe(true);
  });
});
