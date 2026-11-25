import { describe, expect, it } from "vitest";
import { apiErrorResponse, getRequestId } from "@/lib/api/errors";

describe("API error contract", () => {
  it("returns a stable, non-sensitive error envelope and correlation header", async () => {
    const request = new Request("https://example.test/api/example", {
      headers: { "x-request-id": "req-test-0001" }
    });

    const response = apiErrorResponse(request, "BAD_REQUEST");
    const body = await response.json();

    expect(response.status).toBe(400);
    expect(body).toEqual({
      error: {
        code: "BAD_REQUEST",
        message: "The request is invalid.",
        requestId: "req-test-0001"
      }
    });
    expect(response.headers.get("X-Request-Id")).toBe("req-test-0001");
    expect(response.headers.get("Cache-Control")).toBe("no-store");
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(JSON.stringify(body)).not.toMatch(/stack|password|token/i);
  });

  it.each([
    ["UNAUTHENTICATED", 401],
    ["FORBIDDEN", 403],
    ["NOT_FOUND", 404],
    ["CONFLICT", 409],
    ["TOO_MANY_REQUESTS", 429],
    ["INTERNAL", 500],
    ["SERVICE_UNAVAILABLE", 503]
  ] as const)("maps %s to HTTP %i", async (code, status) => {
    const response = apiErrorResponse(new Request("https://example.test"), code);
    expect(response.status).toBe(status);
    expect((await response.json()).error.code).toBe(code);
  });

  it("replaces malformed inbound correlation IDs", () => {
    const request = new Request("https://example.test", {
      headers: { "x-request-id": "bad id\r\nforged: yes" }
    });

    expect(getRequestId(request)).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
  });

  it("generates a correlation ID when none is supplied", () => {
    expect(getRequestId(new Request("https://example.test"))).toMatch(
      /^[0-9a-f-]{36}$/i
    );
  });
});
