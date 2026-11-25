import { afterEach, describe, expect, it, vi } from "vitest";
import { logEvent } from "./logger";

afterEach(() => {
  vi.restoreAllMocks();
});

describe("logEvent", () => {
  it("emits a timestamped structured record with allow-listed fields", () => {
    const output = vi.spyOn(console, "info").mockImplementation(() => undefined);

    logEvent("info", "api.request.completed", {
      requestId: "req-12345678",
      component: "api",
      outcome: "success",
      statusCode: 200,
      durationMs: 12.5
    });

    expect(output).toHaveBeenCalledOnce();
    const record = JSON.parse(String(output.mock.calls[0][0])) as Record<string, unknown>;
    expect(record).toMatchObject({
      level: "info",
      event: "api.request.completed",
      requestId: "req-12345678",
      component: "api",
      outcome: "success",
      statusCode: 200,
      durationMs: 12.5
    });
    expect(Number.isNaN(Date.parse(String(record.timestamp)))).toBe(false);
  });

  it("drops malformed correlation IDs and out-of-range numeric values", () => {
    const output = vi.spyOn(console, "warn").mockImplementation(() => undefined);

    logEvent("warn", "auth.session_refresh.unavailable", {
      requestId: "email=person@example.com",
      component: "auth",
      outcome: "unavailable",
      statusCode: 700,
      durationMs: -1
    });

    const record = JSON.parse(String(output.mock.calls[0][0])) as Record<string, unknown>;
    expect(record).not.toHaveProperty("requestId");
    expect(record).not.toHaveProperty("statusCode");
    expect(record).not.toHaveProperty("durationMs");
    expect(record).toMatchObject({
      level: "warn",
      event: "auth.session_refresh.unavailable",
      component: "auth",
      outcome: "unavailable"
    });
  });

  it("does not serialize unexpected properties supplied at runtime", () => {
    const output = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const context = {
      component: "runtime" as const,
      outcome: "failure" as const,
      accessToken: "secret-token",
      email: "private@example.com",
      error: new Error("provider detail")
    };

    logEvent("error", "auth.identity.unavailable", context);

    const serialized = String(output.mock.calls[0][0]);
    expect(serialized).not.toContain("secret-token");
    expect(serialized).not.toContain("private@example.com");
    expect(serialized).not.toContain("provider detail");
    expect(serialized).toContain('"event":"auth.identity.unavailable"');
  });
});
