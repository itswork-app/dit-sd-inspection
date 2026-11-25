# ADR-002 — Application Runtime and Foundation Stack

- Status: ACCEPTED FOR G9-F1/G10-F1 FOUNDATION
- Version: 1.7.0
- Decision date: 2026-11-25
- Decision owner: Product Owner
- Implementation owner: Solo maintainer with AI engineering partner

## Context

The repository has an approved Vercel + Supabase architecture but no application source. The staged G9-F1/G10-F1 decision authorizes a bounded foundation implementation using synthetic data.

## Decision

1. Use Next.js 16 App Router with TypeScript strict mode as the web/PWA application runtime.
2. Target Node.js 22 LTS for local development and CI.
3. Use npm as the package manager. Commit a generated package-lock.json before relying on reproducible installs.
4. Use Supabase PostgreSQL as the only application database and Supabase Auth for identity. No Firebase or parallel database.
5. Use @supabase/ssr with separate browser and server clients. Server-side identity verification must use verified claims, not session-cookie contents.
6. Use the Next.js 16 proxy entry point to refresh Supabase sessions. Keep service-role/secret keys out of browser code; foundation code uses only the public publishable key.
7. Use Vitest for focused unit tests and ESLint + TypeScript + Next.js production build as the initial CI quality gate.
8. Keep the application a modular monolith. Do not introduce microservices, an ORM, a client-side state framework, or UI component framework until a demonstrated need exists.
9. Apply baseline browser security headers globally: nosniff, frame denial, strict-origin-when-cross-origin referrer policy, and least-privilege camera/microphone/geolocation permissions. Emit HSTS only on the Vercel production environment.
10. Expose a minimal, non-sensitive health endpoint with no-store caching and a machine-readable service status.
11. Standardize API failures with a typed, stable error code, safe public message, HTTP status and request correlation ID. Propagate a validated \`X-Request-Id\` response header from the application proxy. Correlation IDs are diagnostic metadata only and must never be used as identity, authorization or resource scope.
12. Use the Supabase CLI migration layout for local development only. Commit a minimal \`supabase/config.toml\`, keep timestamped SQL migrations under \`supabase/migrations/\`, disable automatic seed loading, and validate migration names/timestamps/empty files in the repository quality script. Do not add a business schema migration until its physical schema, authorization, privilege, transaction/lock and QA contracts have been reviewed. The CLI version must be pinned before CI or shared-environment migration execution is enabled.
13. Provide a server-only identity helper that calls Supabase `auth.getClaims()` and derives the actor identifier exclusively from the verified JWT `sub` claim. Return explicit authenticated, unauthenticated or unavailable outcomes; contain provider/configuration exceptions and never expose raw provider errors. This helper establishes identity only, not role assignment, permission evaluation or resource authorization.
14. Implement the approved Google sign-in flow using Supabase Auth OAuth: browser initiation, same-origin callback code exchange into an SSR-managed cookie session, server-side identity re-verification after callback, and explicit sign-out. Callback errors must use fixed generic redirects and must not disclose provider details. Authentication alone does not grant operational access. The account-approval and role-assignment mechanism is not integrated in this foundation, so no operational access decision is made here. No client-controlled metadata or self-selected role may establish access.
15. Keep proxy session refresh best-effort for public navigation: contain thrown refresh/provider exceptions without turning all public requests into failures. This is not an authentication fallback. Any protected server handler must independently call the verified-identity boundary and fail closed when identity is unavailable.
16. Provide a minimal structured logger with a closed event vocabulary and an allow-list of diagnostic fields only. Logs may contain timestamp, level, event, validated request correlation ID, bounded component/outcome, HTTP status and duration. Do not serialize arbitrary objects, request/response bodies, URLs, headers, IP addresses, user identifiers, email addresses, tokens, evidence, raw exceptions or provider messages. Logging must never influence authorization or business state.
17. Provide a reusable typed JSON request parser for foundation/API boundary work. It must require `application/json`, enforce a bounded streamed byte count (64 KiB default, hard maximum 1 MiB), validate declared Content-Length syntax and consistency, decode strict UTF-8, parse JSON and invoke a caller-supplied type guard. Invalid input returns stable generic error codes; it never returns raw parser/validator details. This utility is not a business endpoint, authorization decision or substitute for command-specific schemas.

## Security and operational constraints

- The current foundation exposes no business mutation endpoints and connects no production data.
- Public Supabase configuration is optional for the bootstrap build. When configured, the URL and publishable key must be supplied together.
- The Supabase URL must be an HTTPS project origin outside local development. Reject embedded credentials, non-root paths, query strings and fragments; allow HTTP only for explicit loopback development hosts.
- Only the public publishable key may be exposed to the browser. Service-role and secret keys remain server-only and are not part of this foundation.
- Any protected route must verify claims server-side and enforce authorization at the authoritative server/database boundary. `getVerifiedIdentity()` is the foundation identity primitive: it uses `auth.getClaims()`, accepts only a non-empty `claims.sub`, and distinguishes unauthenticated sessions from unavailable/configuration/provider outcomes. It does not assign roles or authorize resources.
- The proxy refreshes sessions on a best-effort basis and is not, by itself, an authorization policy. A transient refresh exception must not take down public navigation; any protected handler independently verifies claims and denies access when identity cannot be established. OAuth callback exchanges only the one-time authorization code; subsequent identity is independently re-verified through `getVerifiedIdentity()`. A successful OAuth session is not an approved operational account. A successful proxy refresh does not authorize a request; server handlers must independently resolve verified claims. Never derive identity from client input or unverified cookie/session payloads.
- Never trust client-provided actor, role, permission, tenant, project, location, session or unit scope.
- Do not add schema, grants, RLS or privileged RPCs until their exact authorization and transaction contracts are reviewed.
- A Content-Security-Policy is intentionally deferred until the application adopts a nonce-compatible strategy for Next.js runtime scripts and styles; do not ship a policy that silently breaks the app or rely on unsafe-inline as a shortcut.
- Camera access remains permitted for same-origin application use because evidence capture may require it. Microphone and geolocation are disabled by default.
- Inbound correlation IDs are accepted only when they match a bounded safe-character pattern; otherwise the proxy generates a UUID. They are not trusted assertions.
- Public API errors must not expose stack traces, raw exceptions, credentials, tokens, personal data or evidence payloads. JSON request parsing is bounded by actual streamed bytes and requires strict UTF-8, JSON content type and a caller-provided type guard. Structured logging is limited to the explicit allow-list in `src/lib/observability/logger.ts`; arbitrary context and provider exception details are excluded.
- The local Supabase CLI configuration contains no hosted project reference or credentials. Foundation instructions prohibit linking the repository to a hosted project or invoking remote migration commands. The local CLI state directory is ignored by Git.
- No seed SQL or sample personal/evidence data is admitted. Synthetic fixtures, if later needed, must be explicitly scoped and contain no real institutional records.

## Consequences

- Vercel-compatible web runtime with minimal operational footprint.
- Strong compile-time checks and focused unit testing from the first commit.
- Server-side code has a reusable verified-identity primitive without prematurely introducing role or permission semantics.
- Google OAuth has a complete SSR callback and sign-out lifecycle; login is deliberately separated from account approval and role assignment.
- Auth SSR is prepared without requiring live provider credentials for local bootstrap.
- API callers receive a predictable error envelope and can correlate a response with bounded privacy-safe diagnostic events. Proxy refresh failures emit a generic unavailable event without provider details.
- Local database development has a standard migration directory and a deterministic repository-level filename validator without creating speculative business tables.
- Database and business workflows remain deliberately absent until their feature-entry gates are closed.
- Security headers provide a baseline hardening layer but do not replace authentication, authorization, RLS, CSP or a production security review.

## Verification

CI is configured to execute ESLint, TypeScript, migration filename validation, Vitest (including Node's built-in test runner for migration validation) and a production Next.js build. The environment parser has unit cases for absent/partial configuration, HTTPS origin validation, whitespace normalization, embedded credentials, URL path/query/fragment rejection, insecure non-local URLs and loopback development URLs. The health endpoint has tests for its status/body timestamp contract and no-store/nosniff headers. The API error contract has tests for HTTP mapping, safe public envelopes, no-store/security headers and malformed/missing correlation IDs. The JSON request parser has source tests for valid JSON, missing/unsupported media type, malformed JSON, schema rejection, validator exception containment, declared/actual streamed size limits, strict UTF-8, Content-Length syntax and consistency, already-locked/empty streams and lower/upper internal size bounds. The migration validator has Node test cases for an empty foundation directory, valid names, malformed names, invalid calendar timestamps and duplicate timestamps. The verified-identity resolver has unit cases for a verified subject, missing session, invalid JWT, malformed subject, provider errors and thrown exceptions. The OAuth callback has unit cases for successful code exchange, missing code, provider error redaction and thrown exceptions. The proxy session-refresh adapter has unit cases for absent configuration, claim refresh invocation and containment of thrown refresh exceptions. The structured logger has unit cases for allow-listed output, correlation/numeric validation and exclusion of unexpected sensitive properties. These tests are specified in source but remain NOT VERIFIED until they execute successfully. Supabase CLI startup/reset has not been executed, and no migration has been applied. A successful foundation CI run is not evidence of production readiness or business feature correctness.

## References

- ADR-001 — Platform Stack: Supabase + Vercel
- AGENTS.md §3.2 — staged G9-F1/G10-F1 authorization
- MIB-001 — Master Implementation Blueprint
- Supabase CLI local workflow: https://supabase.com/docs/guides/local-development/cli-workflows
- Supabase migration deployment: https://supabase.com/docs/guides/deployment/database-migrations
- Next.js support policy: https://nextjs.org/support-policy
- Supabase SSR guide: https://supabase.com/docs/guides/auth/server-side/creating-a-client
- `AUTHENTICATION-GOOGLE-OAUTH-SETUP.md` — development provider and redirect configuration runbook
