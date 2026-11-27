import { describe, expect, it } from "vitest";
import { mapCommandStatusToHttp, parseRowVersionString, readIdempotencyKey } from "./command-primitives";
import {
  isApproveAccountInput,
  isGrantRoleInput,
  isGrantScopeInput,
  isRejectAccountInput,
  isRequestAccountAccessInput,
  isRevokeRoleInput,
  isRevokeScopeInput,
  isTransitionAccountStatusInput
} from "./rbac-validators";

const VALID_UUID = "11111111-1111-4111-8111-111111111111";

describe("command boundary primitives", () => {
  it("parses canonical decimal-string row versions and rejects invalid forms", () => {
    expect(parseRowVersionString("1")).toBe(1);
    expect(parseRowVersionString("42")).toBe(42);
    expect(parseRowVersionString("0")).toBeNull();
    expect(parseRowVersionString("-1")).toBeNull();
    expect(parseRowVersionString("01")).toBeNull();
    expect(parseRowVersionString(1)).toBeNull();
    expect(parseRowVersionString("1e2")).toBeNull();
  });

  it("validates Idempotency-Key header syntax", () => {
    const ok = new Request("https://example.test", {
      headers: { "idempotency-key": "cmd-001-req-20261127" }
    });
    const tooShort = new Request("https://example.test", {
      headers: { "idempotency-key": "short" }
    });
    const invalidChars = new Request("https://example.test", {
      headers: { "idempotency-key": "bad key with spaces!" }
    });

    expect(readIdempotencyKey(ok)).toBe("cmd-001-req-20261127");
    expect(readIdempotencyKey(tooShort)).toBeNull();
    expect(readIdempotencyKey(invalidChars)).toBeNull();
  });

  it("maps command outcomes to expected HTTP statuses", () => {
    expect(mapCommandStatusToHttp("ACCEPTED")).toBe(200);
    expect(mapCommandStatusToHttp("VALIDATION_FAILED")).toBe(400);
    expect(mapCommandStatusToHttp("UNAUTHENTICATED")).toBe(401);
    expect(mapCommandStatusToHttp("SOD_VIOLATION")).toBe(403);
    expect(mapCommandStatusToHttp("NOT_FOUND")).toBe(404);
    expect(mapCommandStatusToHttp("STALE_VERSION")).toBe(409);
    expect(mapCommandStatusToHttp("LAST_ADMIN_PROTECTED")).toBe(409);
    expect(mapCommandStatusToHttp("UNKNOWN_CODE")).toBe(500);
  });
});

describe("RBAC-003 strict request allowlist validators", () => {
  it("rejects unknown or forged actor/role fields on CMD-001", () => {
    expect(isRequestAccountAccessInput({ display_name: "Synthetic User" })).toBe(true);
    expect(
      isRequestAccountAccessInput({
        display_name: "Synthetic User",
        role: "super_admin"
      })
    ).toBe(false);
    expect(isRequestAccountAccessInput({ display_name: "A" })).toBe(false);
  });

  it("validates CMD-002 approve and CMD-003 reject payloads", () => {
    expect(
      isApproveAccountInput({
        request_id: VALID_UUID,
        expected_row_version: "1",
        reason: "Verified personnel"
      })
    ).toBe(true);
    expect(
      isRejectAccountInput({
        request_id: VALID_UUID,
        expected_row_version: "1",
        rejection_category: "INCOMPLETE_INFORMATION",
        reason: "Missing unit assignment info"
      })
    ).toBe(true);
    expect(
      isRejectAccountInput({
        request_id: VALID_UUID,
        expected_row_version: "1",
        rejection_category: "INVALID_CATEGORY",
        reason: "Missing unit assignment info"
      })
    ).toBe(false);
  });

  it("validates status transition and CMD-004..007 payloads", () => {
    expect(
      isTransitionAccountStatusInput({
        target_user_id: VALID_UUID,
        target_status: "SUSPENDED",
        expected_row_version: "2",
        reason: "Temporary suspension"
      })
    ).toBe(true);
    expect(
      isGrantRoleInput({
        target_user_id: VALID_UUID,
        role_code: "inspector",
        project_id: VALID_UUID,
        reason: "Project Alpha assignment"
      })
    ).toBe(true);
    expect(
      isGrantRoleInput({
        target_user_id: VALID_UUID,
        role_code: "legacy_admin",
        reason: "Invalid role"
      })
    ).toBe(false);
    expect(
      isRevokeRoleInput({
        user_role_id: VALID_UUID,
        expected_row_version: "1",
        reason: "Rotation complete"
      })
    ).toBe(true);
    expect(
      isGrantScopeInput({
        target_user_id: VALID_UUID,
        scope_type: "PROJECT",
        scope_id: VALID_UUID,
        reason: "Explicit project grant"
      })
    ).toBe(true);
    expect(
      isRevokeScopeInput({
        scope_grant_id: VALID_UUID,
        expected_row_version: "1",
        reason: "Scope ended"
      })
    ).toBe(true);
  });
});
