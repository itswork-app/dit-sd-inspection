export type LogLevel = "info" | "warn" | "error";

export type LogEvent =
  | "api.request.completed"
  | "auth.identity.unavailable"
  | "auth.session_refresh.unavailable";

export type SafeLogContext = {
  requestId?: string;
  component?: "api" | "auth" | "runtime" | "supabase";
  outcome?: "success" | "denied" | "failure" | "unavailable";
  statusCode?: number;
  durationMs?: number;
};

const REQUEST_ID_PATTERN = /^[A-Za-z0-9._:-]{8,128}$/;

/**
 * Emits a bounded structured event. Only explicitly allow-listed diagnostic
 * fields are serialized; callers cannot attach arbitrary objects, messages,
 * identities, request payloads, URLs, headers, tokens or provider exceptions.
 */
export function logEvent(
  level: LogLevel,
  event: LogEvent,
  context: SafeLogContext = {}
): void {
  const record: {
    timestamp: string;
    level: LogLevel;
    event: LogEvent;
    requestId?: string;
    component?: SafeLogContext["component"];
    outcome?: SafeLogContext["outcome"];
    statusCode?: number;
    durationMs?: number;
  } = {
    timestamp: new Date().toISOString(),
    level,
    event
  };

  if (context.requestId && REQUEST_ID_PATTERN.test(context.requestId)) {
    record.requestId = context.requestId;
  }
  if (context.component) record.component = context.component;
  if (context.outcome) record.outcome = context.outcome;
  if (
    Number.isInteger(context.statusCode) &&
    context.statusCode !== undefined &&
    context.statusCode >= 100 &&
    context.statusCode <= 599
  ) {
    record.statusCode = context.statusCode;
  }
  if (
    Number.isFinite(context.durationMs) &&
    context.durationMs !== undefined &&
    context.durationMs >= 0
  ) {
    record.durationMs = context.durationMs;
  }

  console[level](JSON.stringify(record));
}
