import { describe, expect, it } from "vitest";
import { GET } from "./route";

describe("GET /api/health", () => {
  it("returns a minimal healthy service response", async () => {
    const response = GET();
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body).toMatchObject({
      status: "ok",
      service: "dit-sd-inspection"
    });
    expect(Number.isNaN(Date.parse(body.timestamp))).toBe(false);
  });

  it("prevents caching and MIME-type sniffing", () => {
    const response = GET();

    expect(response.headers.get("Cache-Control")).toBe("no-store");
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
  });
});
