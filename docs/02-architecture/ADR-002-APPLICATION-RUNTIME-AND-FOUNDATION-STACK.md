# ADR-002 — Application Runtime and Foundation Stack

- Status: ACCEPTED FOR G9-F1/G10-F1 FOUNDATION
- Version: 1.1.0
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
11. Standardize API failures with a typed, stable error code, safe public message, HTTP status and request correlation ID. Propagate a validated `X-Request-Id` response header from the application proxy. Correlation IDs are diagnostic metadata only and must never be used as identity, authorization or resource scope.

## Security and operational constraints

- The current foundation exposes no business mutation endpoints and connects no production data.
- Public Supabase configuration is optional for the bootstrap build. When configured, the URL and publishable key must be supplied together.
- The Supabase URL must be an HTTPS project origin outside local development. Reject embedded credentials, non-root paths, query strings and fragments; allow HTTP only for explicit loopback development hosts.
- Only the public publishable key may be exposed to the browser. Service-role and secret keys remain server-only and are not part of this foundation.
- Any protected route must verify claims server-side and enforce authorization at the authoritative server/database boundary.
- The proxy refreshes sessions but is not, by itself, an authorization policy.
- Never trust client-provided actor, role, permission, tenant, project, location, session or unit scope.
- Do not add schema, grants, RLS or privileged RPCs until their exact authorization and transaction contracts are reviewed.
- A Content-Security-Policy is intentionally deferred until the application adopts a nonce-compatible strategy for Next.js runtime scripts and styles; do not ship a policy that silently breaks the app or rely on unsafe-inline as a shortcut.
- Camera access remains permitted for same-origin application use because evidence capture may require it. Microphone and geolocation are disabled by default.
- Inbound correlation IDs are accepted only when they match a bounded safe-character pattern; otherwise the proxy generates a UUID. They are not trusted assertions.
- Public API errors must not expose stack traces, raw exceptions, credentials, tokens, personal data or evidence payloads. Internal logging is not introduced by this contract; any future logging must be structured and privacy-safe.

## Consequences

- Vercel-compatible web runtime with minimal operational footprint.
- Strong compile-time checks and focused unit testing from the first commit.
- Auth SSR is prepared without requiring live provider credentials for local bootstrap.
- API callers receive a predictable error envelope and can correlate a response with future privacy-safe diagnostics.
- Database and business workflows remain deliberately absent until their feature-entry gates are closed.
- Security headers provide a baseline hardening layer but do not replace authentication, authorization, RLS, CSP or a production security review.

## Verification

CI executes ESLint, TypeScript, Vitest and a production Next.js build. The environment parser has unit cases for absent/partial configuration, HTTPS origin validation, whitespace normalization, embedded credentials, URL path/query/fragment rejection, insecure non-local URLs and loopback development URLs. The health endpoint has tests for its status/body timestamp contract and no-store/nosniff headers. The API error contract has tests for HTTP mapping, safe public envelopes, no-store/security headers and malformed/missing correlation IDs. These tests are specified in source but remain NOT VERIFIED until CI executes them successfully. A successful foundation CI run is not evidence of production readiness or business feature correctness.

## References

- ADR-001 — Platform Stack: Supabase + Vercel
- AGENTS.md §3.2 — staged G9-F1/G10-F1 authorization
- MIB-001 — Master Implementation Blueprint
- Next.js support policy: https://nextjs.org/support-policy
- Supabase SSR guide: https://supabase.com/docs/guides/auth/server-side/creating-a-client
