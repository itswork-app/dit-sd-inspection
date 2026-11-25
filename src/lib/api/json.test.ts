import { describe, expect, it, vi } from "vitest";
import { parseJsonRequest, type JsonBodyValidator } from "./json";

type CreateNoteInput = { title: string };

function isCreateNoteInput(value: unknown): value is CreateNoteInput {
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value) &&
    "title" in value &&
    typeof value.title === "string" &&
    value.title.trim().length > 0
  );
}

function jsonRequest(
  body: BodyInit | null,
  headers: Record<string, string> = { "content-type": "application/json" }
): Request {
  return new Request("https://example.test/api/foundation", {
    method: "POST",
    headers,
    body
  });
}

describe("parseJsonRequest", () => {
  it("parses a valid JSON object and validates its shape", async () => {
    const result = await parseJsonRequest(
      jsonRequest(JSON.stringify({ title: "Synthetic test" }), {
        "content-type": "application/json; charset=utf-8"
      }),
      isCreateNoteInput
    );

    expect(result).toEqual({ ok: true, data: { title: "Synthetic test" } });
  });

  it("rejects unsupported or missing content types before reading the body", async () => {
    const result = await parseJsonRequest(
      jsonRequest("{}", { "content-type": "text/plain" }),
      isCreateNoteInput
    );

    expect(result).toEqual({ ok: false, code: "UNSUPPORTED_MEDIA_TYPE" });
  });

  it("rejects a missing content type", async () => {
    const result = await parseJsonRequest(
      jsonRequest("{}", {}),
      isCreateNoteInput
    );

    expect(result).toEqual({ ok: false, code: "UNSUPPORTED_MEDIA_TYPE" });
  });

  it("rejects malformed JSON without returning parser details", async () => {
    const result = await parseJsonRequest(jsonRequest("{invalid"), isCreateNoteInput);
    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("rejects values that do not satisfy the caller's schema", async () => {
    const result = await parseJsonRequest(jsonRequest(JSON.stringify({ title: 42 })), isCreateNoteInput);
    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("contains exceptions thrown by a validator", async () => {
    const validator: JsonBodyValidator<unknown> = vi.fn(() => {
      throw new Error("private validation details");
    });
    const result = await parseJsonRequest(jsonRequest("{}"), validator);

    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
    expect(JSON.stringify(result)).not.toContain("private validation details");
  });

  it("rejects declared bodies above the configured byte limit before reading", async () => {
    const result = await parseJsonRequest(
      jsonRequest("{}", {
        "content-type": "application/json",
        "content-length": "100"
      }),
      isCreateNoteInput,
      16
    );

    expect(result).toEqual({ ok: false, code: "PAYLOAD_TOO_LARGE" });
  });

  it("enforces the byte limit against the actual streamed body", async () => {
    const result = await parseJsonRequest(
      jsonRequest(JSON.stringify({ title: "This body is over the limit" })),
      isCreateNoteInput,
      12
    );

    expect(result).toEqual({ ok: false, code: "PAYLOAD_TOO_LARGE" });
  });

  it("does not wait for a stalled stream cancellation hook after exceeding the limit", async () => {
    const body = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(new Uint8Array(32));
      },
      cancel() {
        return new Promise<void>(() => undefined);
      }
    });
    const request = new Request("https://example.test/api/foundation", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body,
      duplex: "half"
    } as RequestInit & { duplex: "half" });

    await expect(parseJsonRequest(request, isCreateNoteInput, 8)).resolves.toEqual({
      ok: false,
      code: "PAYLOAD_TOO_LARGE"
    });
  });

  it("rejects malformed Content-Length values", async () => {
    const result = await parseJsonRequest(
      jsonRequest("{}", {
        "content-type": "application/json",
        "content-length": "1e2"
      }),
      isCreateNoteInput
    );

    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("rejects invalid UTF-8", async () => {
    const body = new ArrayBuffer(2);
    new Uint8Array(body).set([0xc3, 0x28]);
    const result = await parseJsonRequest(jsonRequest(body), isCreateNoteInput);

    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("rejects a content-length mismatch", async () => {
    const result = await parseJsonRequest(
      jsonRequest("{}", {
        "content-type": "application/json",
        "content-length": "3"
      }),
      isCreateNoteInput
    );

    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("rejects a body stream that is already locked", async () => {
    const request = jsonRequest("{}");
    const reader = request.body?.getReader();

    const result = await parseJsonRequest(request, isCreateNoteInput);
    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });

    reader?.releaseLock();
  });

  it("rejects an empty body", async () => {
    const result = await parseJsonRequest(jsonRequest(null), isCreateNoteInput);
    expect(result).toEqual({ ok: false, code: "BAD_REQUEST" });
  });

  it("rejects invalid internal size configuration", async () => {
    await expect(
      parseJsonRequest(jsonRequest("{}"), isCreateNoteInput, 0)
    ).rejects.toThrow(RangeError);
    await expect(
      parseJsonRequest(jsonRequest("{}"), isCreateNoteInput, 1024 * 1024 + 1)
    ).rejects.toThrow(RangeError);
  });
});
