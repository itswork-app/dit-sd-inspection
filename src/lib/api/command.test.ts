import { beforeEach, describe, expect, it, vi } from "vitest";
import { executeProtectedCommand } from "./command";

const { mockGetVerifiedIdentity, mockCreateClient, mockLogEvent } = vi.hoisted(() => ({
  mockGetVerifiedIdentity: vi.fn(),
  mockCreateClient: vi.fn(),
  mockLogEvent: vi.fn()
}));

vi.mock("@/lib/auth/identity", () => ({
  getVerifiedIdentity: mockGetVerifiedIdentity
}));

vi.mock("@/lib/supabase/server", () => ({
  createClient: mockCreateClient
}));

vi.mock("@/lib/observability/logger", () => ({
  logEvent: mockLogEvent
}));

const alwaysValid = (value: unknown): value is { name: string } =>
  typeof value === "object" &&
  value !== null &&
  "name" in value &&
  typeof (value as { name: unknown }).name === "string";

function makeJsonRequest(body: unknown, headers: Record<string, string> = {}) {
  return new Request("https://example.test/api/v1/test", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "idempotency-key": "test-idem-key-0001",
      ...headers
    },
    body: JSON.stringify(body)
  });
}

describe("executeProtectedCommand", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 401 UNAUTHENTICATED when identity is unauthenticated", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "unauthenticated" });

    const response = await executeProtectedCommand({
      request: makeJsonRequest({ name: "Test" }),
      rpcName: "cmd_test_v1",
      validator: alwaysValid,
      buildParams: () => ({})
    });

    expect(response.status).toBe(401);
    expect(mockCreateClient).not.toHaveBeenCalled();
  });

  it("returns 503 SERVICE_UNAVAILABLE when identity verification is unavailable", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "unavailable" });

    const response = await executeProtectedCommand({
      request: makeJsonRequest({ name: "Test" }),
      rpcName: "cmd_test_v1",
      validator: alwaysValid,
      buildParams: () => ({})
    });

    expect(response.status).toBe(503);
    expect(mockCreateClient).not.toHaveBeenCalled();
  });

  it("returns 400 BAD_REQUEST when Idempotency-Key header is missing or malformed", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "authenticated", actorId: "auth-1" });

    const request = new Request("https://example.test/api/v1/test", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "Test" })
    });

    const response = await executeProtectedCommand({
      request,
      rpcName: "cmd_test_v1",
      validator: alwaysValid,
      buildParams: () => ({})
    });

    expect(response.status).toBe(400);
    expect(mockCreateClient).not.toHaveBeenCalled();
  });

  it("returns 400 BAD_REQUEST when JSON payload fails strict validator", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "authenticated", actorId: "auth-1" });

    const response = await executeProtectedCommand({
      request: makeJsonRequest({ bad: true }),
      rpcName: "cmd_test_v1",
      validator: alwaysValid,
      buildParams: () => ({})
    });

    expect(response.status).toBe(400);
    expect(mockCreateClient).not.toHaveBeenCalled();
  });

  it("redacts PostgreSQL/RPC errors and returns generic 500 INTERNAL envelope", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "authenticated", actorId: "auth-1" });
    mockCreateClient.mockResolvedValue({
      rpc: vi.fn().mockResolvedValue({
        data: null,
        error: { message: "sensitive postgres detail", code: "42501" }
      })
    });

    const response = await executeProtectedCommand({
      request: makeJsonRequest({ name: "Test" }),
      rpcName: "cmd_test_v1",
      validator: alwaysValid,
      buildParams: (input, idem) => ({ p_name: input.name, p_idem: idem })
    });

    expect(response.status).toBe(500);
    const json = (await response.json()) as { error: { code: string; message: string } };
    expect(json.error.code).toBe("INTERNAL");
    expect(JSON.stringify(json)).not.toContain("sensitive postgres detail");
  });

  it("forwards validated parameters to RPC and maps domain status to HTTP status with no-store headers", async () => {
    mockGetVerifiedIdentity.mockResolvedValue({ status: "authenticated", actorId: "auth-1" });
    const rpc = vi.fn().mockResolvedValue({
      data: { command_id: "CMD-002", status: "STALE_VERSION" },
      error: null
    });
    mockCreateClient.mockResolvedValue({ rpc });

    const response = await executeProtectedCommand({
      request: makeJsonRequest({ name: "Test" }),
      rpcName: "cmd_approve_account_v1",
      validator: alwaysValid,
      buildParams: (input, idem) => ({ p_name: input.name, p_idem: idem })
    });

    expect(rpc).toHaveBeenCalledWith("cmd_approve_account_v1", {
      p_name: "Test",
      p_idem: "test-idem-key-0001"
    });
    expect(response.status).toBe(409);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    expect(response.headers.get("x-request-id")).toBeTruthy();
    const json = (await response.json()) as { status: string; requestId: string };
    expect(json.status).toBe("STALE_VERSION");
    expect(json.requestId).toBeTruthy();
  });
});
