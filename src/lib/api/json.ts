import type { ApiErrorCode } from "@/lib/api/errors";

export const DEFAULT_MAX_JSON_BODY_BYTES = 64 * 1024;
const ABSOLUTE_MAX_JSON_BODY_BYTES = 1024 * 1024;

export type JsonRequestResult<T> =
  | { ok: true; data: T }
  | { ok: false; code: Extract<ApiErrorCode, "BAD_REQUEST" | "PAYLOAD_TOO_LARGE" | "UNSUPPORTED_MEDIA_TYPE"> };

export type JsonBodyValidator<T> = (value: unknown) => value is T;

/**
 * Reads and validates a JSON request without trusting Content-Length as the
 * sole size control. The streamed byte count is always bounded before parsing.
 *
 * Validators should be pure type guards. Exceptions are contained and treated
 * as invalid input; no request data or exception detail is returned.
 */
export async function parseJsonRequest<T>(
  request: Request,
  validate: JsonBodyValidator<T>,
  maxBytes = DEFAULT_MAX_JSON_BODY_BYTES
): Promise<JsonRequestResult<T>> {
  if (
    !Number.isSafeInteger(maxBytes) ||
    maxBytes < 1 ||
    maxBytes > ABSOLUTE_MAX_JSON_BODY_BYTES
  ) {
    throw new RangeError("maxBytes must be an integer between 1 and 1048576.");
  }

  const contentType = request.headers.get("content-type")?.split(";", 1)[0]?.trim().toLowerCase();
  if (contentType !== "application/json") {
    return { ok: false, code: "UNSUPPORTED_MEDIA_TYPE" };
  }

  const contentLength = request.headers.get("content-length");
  if (contentLength !== null) {
    if (!/^(0|[1-9]\d*)$/.test(contentLength)) {
      return { ok: false, code: "BAD_REQUEST" };
    }
    const declaredBytes = Number(contentLength);
    if (!Number.isSafeInteger(declaredBytes)) {
      return { ok: false, code: "BAD_REQUEST" };
    }
    if (declaredBytes > maxBytes) {
      return { ok: false, code: "PAYLOAD_TOO_LARGE" };
    }
  }

  if (!request.body) return { ok: false, code: "BAD_REQUEST" };

  let reader: ReadableStreamDefaultReader<Uint8Array>;
  try {
    reader = request.body.getReader();
  } catch {
    return { ok: false, code: "BAD_REQUEST" };
  }

  const chunks: Uint8Array[] = [];
  let totalBytes = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (!value) continue;

      totalBytes += value.byteLength;
      if (totalBytes > maxBytes) {
        try {
          await reader.cancel();
        } catch {
          // Cancellation is best-effort; the size limit remains enforced.
        }
        return { ok: false, code: "PAYLOAD_TOO_LARGE" };
      }
      chunks.push(value);
    }
  } catch {
    return { ok: false, code: "BAD_REQUEST" };
  } finally {
    reader.releaseLock();
  }

  if (contentLength !== null && Number(contentLength) !== totalBytes) {
    return { ok: false, code: "BAD_REQUEST" };
  }

  const bytes = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }

  let parsed: unknown;
  try {
    const text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    parsed = JSON.parse(text) as unknown;
  } catch {
    return { ok: false, code: "BAD_REQUEST" };
  }

  try {
    if (!validate(parsed)) return { ok: false, code: "BAD_REQUEST" };
  } catch {
    return { ok: false, code: "BAD_REQUEST" };
  }

  return { ok: true, data: parsed };
}
