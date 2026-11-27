# Google OAuth Development Setup

**Scope:** local/development Supabase Auth configuration for the Dit. SD Inspection foundation.

## Application flow

1. The user starts Google OAuth from `/login` using the public Supabase browser client.
2. Supabase redirects the browser to the application callback at `/auth/callback`.
3. The callback exchanges the one-time authorization code through the server Supabase client. The SSR cookie adapter stores the session in HTTP-only-compatible Supabase cookies.
4. The application independently calls `auth.getClaims()` on the server at `/auth/pending` and accepts only the verified JWT `sub` as identity.
5. This foundation does not grant operational access or evaluate account approval/role assignment; those authoritative mechanisms are not integrated yet.
6. Sign-out runs as a server action through the server Supabase client.

## Supabase project configuration

1. In the Supabase development project, enable Google under Authentication → Providers.
2. Configure the Google OAuth client ID and client secret in the Supabase provider settings. Keep the client secret in the provider dashboard; never commit it, paste it into chat, or expose it as a `NEXT_PUBLIC_*` variable.
3. Copy the Supabase provider callback URL shown in the Google provider settings and register that exact URL as an authorized redirect URI in Google Cloud Console. This is the Supabase provider callback, not the application's `/auth/callback` route.
4. In Supabase Authentication URL Configuration, set the development Site URL and add exact application callback URLs to the Redirect URLs allow list, for example:
   - `http://localhost:3000/auth/callback`
   - `http://127.0.0.1:3000/auth/callback` only if that host is used locally
   - The exact HTTPS development/preview callback URL when that environment is configured
5. Supply only the public project URL and publishable key in the local environment:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
6. Restart the Next.js development server after changing environment variables.

Do not add a production project reference, production secrets, service-role key, or real institutional data to the development environment.

## Security and access semantics

- The OAuth redirect URI must be on the Supabase allow list. Do not accept a user-supplied post-login destination.
- The callback uses fixed local paths and generic error redirects; provider error descriptions are not displayed or logged.
- A valid Google identity is not proof of account approval, role assignment, operational assignment, or resource authorization.
- Do not place roles, permissions, tenant, project, location, session, or instrument scope in user-editable metadata and trust it for authorization.
- Do not expose service-role credentials to the browser. The current flow uses the publishable key and the caller's SSR session.
- Provider configuration is environment setup only; it does not authorize production deployment or production data access.

## Verification boundary

- **Unit & build verification (2026-11-27, Node v22.12.0 / npm 10.9.0):** PASS via `npm run check` — OAuth callback unit tests (successful exchange, missing code, generic provider failure, thrown exceptions), verified-claims unit tests, and `src/proxy.ts` session-refresh/request-ID tests all pass (63/63 Vitest tests).
- **Live development runtime smoke verification (2026-11-27, local Next.js production server against `.env`):** PASS for non-mutating foundation paths:
  - Development Supabase Auth `/auth/v1/health` and `/auth/v1/settings` returned HTTP `200`.
  - `src/proxy.ts` (`ƒ Proxy (Middleware)`) active on all matched routes, propagating valid `X-Request-Id` and replacing malformed inbound IDs with UUIDs.
  - `/auth/pending` (unauthenticated) failed closed via live `getClaims()` and redirected `307` to `/login?error=session`.
  - `/auth/callback` (missing code and synthetic invalid code) redirected `307` to `/login?error=oauth_callback` with `Cache-Control: no-store` and `Referrer-Policy: no-referrer`, leaking zero provider details.
- **Google OAuth authorize preflight (2026-11-27):** Read-only inspection of `/auth/v1/settings` confirms `external.google = true`, and `/auth/v1/authorize?provider=google&redirect_to=http://localhost:3000/auth/callback` returns HTTP `302` to `accounts.google.com` OAuth2 with a configured `client_id` and Supabase `/auth/v1/callback` redirect URI (`errorCode = null`). Ensure `http://localhost:3000/auth/callback` is listed in Supabase Authentication → URL Configuration → Redirect URLs, then run `npm run dev` and complete an interactive sign-in/sign-out round trip in the browser. Live interactive Google OAuth round trip remains **NOT VERIFIED** until that browser flow completes.
