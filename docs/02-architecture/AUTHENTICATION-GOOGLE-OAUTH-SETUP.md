# Google OAuth Development Setup

**Scope:** local/development Supabase Auth configuration for the Dit. SD Inspection foundation.

## Application flow

1. The user starts Google OAuth from `/login` using the public Supabase browser client.
2. Supabase redirects the browser to the application callback at `/auth/callback`.
3. The callback exchanges the one-time authorization code through the server Supabase client. The SSR cookie adapter stores the session in HTTP-only-compatible Supabase cookies.
4. The application independently calls `auth.getClaims()` on the server at `/auth/pending` and accepts only the verified JWT `sub` as identity.
5. The account remains without operational access until the separately approved account-approval and role-assignment mechanism is implemented.
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

The source includes tests for the OAuth callback's successful exchange, missing code, generic provider failure, and thrown exception handling. These tests remain NOT VERIFIED until executed in a working Node 22 dependency environment. A live Google OAuth round trip also remains NOT VERIFIED until a development Supabase project and Google provider are configured by the maintainer.
