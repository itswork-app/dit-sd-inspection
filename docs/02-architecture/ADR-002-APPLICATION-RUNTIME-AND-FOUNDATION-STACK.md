# ADR-002 — Application Runtime and Foundation Stack

- Status: ACCEPTED FOR G9-F1/G10-F1 FOUNDATION
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

## Security and operational constraints

- The current foundation exposes no business mutation endpoints and connects no production data.
- Public Supabase configuration is optional for the bootstrap build; when configured, URL and publishable key must be supplied together and HTTPS is mandatory except localhost development.
- Any protected route must verify claims server-side and enforce authorization at the authoritative server/database boundary.
- The proxy refreshes sessions but is not, by itself, an authorization policy.
- Never trust client-provided actor, role, permission, tenant, project, location, session or unit scope.
- Never expose service-role credentials in browser bundles, public env vars, logs or commits.
- Do not add schema, grants, RLS or privileged RPCs until their exact authorization and transaction contracts are reviewed.

## Consequences

- Vercel-compatible web runtime with minimal operational footprint.
- Strong compile-time checks and focused unit testing from the first commit.
- Auth SSR is prepared without requiring live provider credentials for local bootstrap.
- Database and business workflows remain deliberately absent until their feature-entry gates are closed.

## Verification

CI executes ESLint, TypeScript, Vitest and a production Next.js build. The first successful run is the evidence that this foundation compiles; it is not evidence of production readiness or business feature correctness.

## References

- ADR-001 — Platform Stack: Supabase + Vercel
- AGENTS.md §3.2 — staged G9-F1/G10-F1 authorization
- MIB-001 — Master Implementation Blueprint
- Next.js support policy: https://nextjs.org/support-policy
- Supabase SSR guide: https://supabase.com/docs/guides/auth/server-side/creating-a-client
