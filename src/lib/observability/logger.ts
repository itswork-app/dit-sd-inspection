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
const LOG_LEVELS = new Set<LogLevel>(["info", "warn", "error"]);
const LOG_EVENTS = new Set<LogEvent>([
  "api.request.completed",
  "auth.identity.unavailable",
  "auth.session_refresh.unavailable"
]);
const LOG_COMPONENTS = new Set<NonNullable<SafeLogContext["component"]>>([
  "api",
  "auth",
  "runtime",
  "supabase"
]);
const LOG_OUTCOMES = new Set<NonNullable<SafeLogContext["outcome"]>>([
  "success",
  "denied",
  "failure",
  "unavailable"
]);

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
  if (!LOG_LEVELS.has(level) || !LOG_EVENTS.has(event)) return;

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
  if (context.component && LOG_COMPONENTS.has(context.component)) {
    record.component = context.component;
  }
  if (context.outcome && LOG_OUTCOMES.has(context.outcome)) {
    record.outcome = context.outcome;
  }
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
