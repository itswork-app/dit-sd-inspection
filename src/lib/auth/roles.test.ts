import { describe, expect, it } from "vitest";
import type { UserRoleRecord } from "@/lib/auth/account";
import {
  extractActiveRoles,
  getAllowedNavPaths,
  getRoleCapabilities,
  type CanonicalRoleCode
} from "./roles";

function makeRole(
  role_code: string,
  status: "ACTIVE" | "REVOKED" = "ACTIVE",
  valid_until: string | null = null
): UserRoleRecord {
  return {
    id: `role-${role_code}`,
    user_id: "user-1",
    role_id: `id-${role_code}`,
    role_code,
    role_name: role_code,
    scope_class: role_code === "super_admin" ? "GLOBAL" : "PROJECT",
    project_id: role_code === "super_admin" ? null : "proj-1",
    status,
    valid_from: "2026-11-01T00:00:00Z",
    valid_until,
    reason: "Test grant",
    row_version: "1",
    granted_at: "2026-11-01T00:00:00Z",
    revoked_at: null
  };
}

describe("roles & capabilities helpers", () => {
  it("extracts active, unexpired, deduplicated roles in canonical order", () => {
    const nowMs = Date.parse("2026-11-27T12:00:00Z");
    const active = extractActiveRoles(
      [
        makeRole("print_officer"),
        makeRole("inspector"),
        makeRole("inspector"),
        makeRole("reviewer", "REVOKED"),
        makeRole("korlap", "ACTIVE", "2026-11-26T00:00:00Z"),
        makeRole("super_admin")
      ],
      nowMs
    );
    expect(active).toEqual(["super_admin", "inspector", "print_officer"]);
  });

  it("assigns focused navigation and capabilities per single role", () => {
    expect(getAllowedNavPaths(["inspector"])).toEqual(["/dashboard", "/inspections", "/notifications"]);
    expect(getAllowedNavPaths(["reviewer"])).toEqual([
      "/dashboard",
      "/inspections",
      "/operations",
      "/notifications"
    ]);
    expect(getAllowedNavPaths(["print_officer"])).toEqual([
      "/dashboard",
      "/inspections",
      "/operations",
      "/notifications"
    ]);
    expect(getAllowedNavPaths(["super_admin"])).toEqual([
      "/dashboard",
      "/workspace",
      "/inspections",
      "/operations",
      "/notifications",
      "/admin/accounts"
    ]);

    const inspectorCaps = getRoleCapabilities(["inspector"]);
    expect(inspectorCaps.canInspectField).toBe(true);
    expect(inspectorCaps.canReviewInspections).toBe(false);
    expect(inspectorCaps.canGenerateOrPrintDocs).toBe(false);

    const reviewerCaps = getRoleCapabilities(["reviewer"]);
    expect(reviewerCaps.canReviewInspections).toBe(true);
    expect(reviewerCaps.canInspectField).toBe(false);
    expect(reviewerCaps.canGenerateOrPrintDocs).toBe(false);

    const printCaps = getRoleCapabilities(["print_officer"]);
    expect(printCaps.canGenerateOrPrintDocs).toBe(true);
    expect(printCaps.canReviewInspections).toBe(false);
    expect(printCaps.canInspectField).toBe(false);
  });

  it("unifies capabilities and navigation cleanly for multi-role users", () => {
    const multi: CanonicalRoleCode[] = ["reviewer", "inspector"];
    expect(getAllowedNavPaths(multi)).toEqual([
      "/dashboard",
      "/inspections",
      "/operations",
      "/notifications"
    ]);
    const caps = getRoleCapabilities(multi);
    expect(caps.canInspectField).toBe(true);
    expect(caps.canReviewInspections).toBe(true);
    expect(caps.canManageAttendance).toBe(true);
    expect(caps.canGenerateOrPrintDocs).toBe(false);
  });
});
