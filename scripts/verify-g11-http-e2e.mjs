#!/usr/bin/env node
/**
 * Local G11 Live HTTP + GoTrue JWT + Next.js App Server End-to-End Verification
 * Runs strictly against isolated local Supabase (http://127.0.0.1:54421) and a local
 * Next.js production server (`next start -p 3199`), never touching hosted services or `.env`.
 */
import assert from "node:assert/strict";
import { spawn } from "node:child_process";

const SUPABASE_URL = process.env.LOCAL_SUPABASE_URL ?? "http://127.0.0.1:54421";
const PUBLISHABLE_KEY =
  process.env.LOCAL_SUPABASE_PUBLISHABLE_KEY ?? "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH";
const SERVICE_ROLE_KEY =
  process.env.LOCAL_SUPABASE_SERVICE_ROLE_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";
const APP_PORT = 3199;
const APP_URL = `http://127.0.0.1:${APP_PORT}`;
const CONTAINER = "supabase_db_dit-sd-inspection";

function runPsql(sql) {
  return new Promise((resolve, reject) => {
    const child = spawn(
      "docker",
      ["exec", "-i", CONTAINER, "psql", "-U", "postgres", "-d", "postgres", "-t", "-A", "-v", "ON_ERROR_STOP=1"],
      { stdio: ["pipe", "pipe", "pipe"] }
    );
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => (stdout += d.toString()));
    child.stderr.on("data", (d) => (stderr += d.toString()));
    child.on("close", (code) => {
      if (code !== 0) reject(new Error(`psql failed (${code}): ${stderr}`));
      else resolve(stdout.trim());
    });
    child.stdin.end(sql);
  });
}

async function waitForHealth(timeoutMs = 20000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${APP_URL}/api/health`);
      if (res.ok) return;
    } catch {
      // retry
    }
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error("Next.js server did not become healthy in time");
}

function encodeSupabaseSsrCookie(sessionJson) {
  // @supabase/ssr stores `base64-<base64url(JSON)>` in `sb-127-auth-token` for http://127.0.0.1:54421
  const b64url = Buffer.from(JSON.stringify(sessionJson), "utf8").toString("base64url");
  return `sb-127-auth-token=base64-${b64url}`;
}

async function createAndSignInLocalUser(email, password) {
  const createRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE_KEY,
      authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({ email, password, email_confirm: true })
  });
  if (!createRes.ok) {
    throw new Error(`Failed creating local synthetic user ${email}: ${await createRes.text()}`);
  }
  const created = await createRes.json();

  const tokenRes = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      apikey: PUBLISHABLE_KEY,
      "content-type": "application/json"
    },
    body: JSON.stringify({ email, password })
  });
  if (!tokenRes.ok) {
    throw new Error(`Failed signing in local user ${email}: ${await tokenRes.text()}`);
  }
  const session = await tokenRes.json();
  return { userId: created.id, session, cookie: encodeSupabaseSsrCookie(session) };
}

async function main() {
  console.log("==> [G11 HTTP E2E] Starting local Next.js server pointed at isolated local Supabase...");
  const server = spawn("npx", ["next", "start", "-H", "127.0.0.1", "-p", String(APP_PORT)], {
    detached: true,
    env: {
      ...process.env,
      NEXT_PUBLIC_SUPABASE_URL: SUPABASE_URL,
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: PUBLISHABLE_KEY
    },
    stdio: ["ignore", "ignore", "ignore"]
  });

  try {
    await waitForHealth();
    console.log("    Next.js server healthy on", APP_URL);

    // 1. Verify unauthenticated routes & security headers
    const healthRes = await fetch(`${APP_URL}/api/health`);
    assert.equal(healthRes.status, 200);
    assert.ok(healthRes.headers.get("x-request-id"), "Proxy must inject X-Request-Id");
    assert.equal(healthRes.headers.get("cache-control"), "no-store");

    for (const protectedPage of ["/auth/pending", "/admin/accounts", "/workspace", "/inspections", "/notifications"]) {
      const res = await fetch(`${APP_URL}${protectedPage}`, { redirect: "manual" });
      assert.equal(res.status, 307, `Expected 307 redirect on unauth ${protectedPage}, got ${res.status}`);
      assert.ok((res.headers.get("location") ?? "").includes("/login"), `Expected redirect to /login on ${protectedPage}`);
    }

    for (const protectedApi of [
      ["GET", "/api/v1/account/me"],
      ["GET", "/api/v1/admin/accounts"],
      ["GET", "/api/v1/projects"],
      ["GET", "/api/v1/notifications"]
    ]) {
      const res = await fetch(`${APP_URL}${protectedApi[1]}`, { method: protectedApi[0] });
      assert.equal(res.status, 401, `Expected 401 on unauth ${protectedApi[1]}, got ${res.status}`);
    }
    console.log("    PASS: All unauthenticated UI pages redirect to /login and APIs fail closed with 401");

    // 2. Provision two synthetic local GoTrue users: Super Admin & Applicant
    const sa = await createAndSignInLocalUser("e2e-sa@example.test", "SyntheticPass123!");
    const applicant = await createAndSignInLocalUser("e2e-applicant@example.test", "SyntheticPass123!");

    // Bootstrap SA in DB (out-of-band)
    const saAppUserId = "99000001-0000-4000-8000-000000000001";
    const seedHelperId = "99000002-0000-4000-8000-000000000002";
    await runPsql(`
      INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
      VALUES ('99000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'e2e-seed@example.test', '{}', '{}', now(), now());
      INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
      VALUES
        ('${saAppUserId}', '${sa.userId}', 'E2E Super Admin', 'APPROVED', 1),
        ('${seedHelperId}', '99000000-0000-4000-8000-000000000002', 'E2E Bootstrap Helper', 'APPROVED', 1);
      INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
      SELECT '${saAppUserId}', r.id, NULL, 'ACTIVE', '${seedHelperId}', 'E2E SA bootstrap'
      FROM public.roles r WHERE r.code = 'super_admin';
    `);

    // 3. Applicant submits CMD-001 via live Next.js POST /api/v1/account/request
    const reqRes = await fetch(`${APP_URL}/api/v1/account/request`, {
      method: "POST",
      headers: {
        cookie: applicant.cookie,
        "content-type": "application/json",
        "idempotency-key": "e2e-cmd001-req-0001"
      },
      body: JSON.stringify({ display_name: "E2E Field Inspector", request_note: "Synthetic E2E test" })
    });
    assert.equal(reqRes.status, 200, `CMD-001 failed: ${await reqRes.clone().text()}`);
    const reqJson = await reqRes.json();
    assert.equal(reqJson.status, "ACCEPTED");
    assert.equal(reqJson.account_status, "PENDING");

    // Applicant MUST receive 403 on GET /api/v1/admin/accounts
    const deniedAdmin = await fetch(`${APP_URL}/api/v1/admin/accounts`, {
      headers: { cookie: applicant.cookie }
    });
    assert.equal(deniedAdmin.status, 403, "Pending applicant must get 403 on /api/v1/admin/accounts");

    // 4. Super Admin reads admin queue & approves applicant via live Next.js POST /api/v1/admin/accounts/approve
    const queueRes = await fetch(`${APP_URL}/api/v1/admin/accounts`, {
      headers: { cookie: sa.cookie }
    });
    assert.equal(queueRes.status, 200);
    const queueJson = await queueRes.json();
    assert.ok(queueJson.requests.some((r) => r.id === reqJson.request_id));

    const approveRes = await fetch(`${APP_URL}/api/v1/admin/accounts/approve`, {
      method: "POST",
      headers: {
        cookie: sa.cookie,
        "content-type": "application/json",
        "idempotency-key": "e2e-cmd002-app-0001"
      },
      body: JSON.stringify({
        request_id: reqJson.request_id,
        expected_row_version: "1",
        reason: "Verified E2E synthetic inspector"
      })
    });
    assert.equal(approveRes.status, 200);
    const approveJson = await approveRes.json();
    assert.equal(approveJson.status, "APPROVED");

    // 5. Super Admin creates Project (CMD-008) & Instrument (CMD-018) via live Next.js APIs
    const prjRes = await fetch(`${APP_URL}/api/v1/projects`, {
      method: "POST",
      headers: {
        cookie: sa.cookie,
        "content-type": "application/json",
        "idempotency-key": "e2e-cmd008-prj-0001"
      },
      body: JSON.stringify({ code: "E2E-PRJ-01", name: "E2E Live Project", timezone: "Asia/Jakarta" })
    });
    assert.equal(prjRes.status, 201);
    const prjJson = await prjRes.json();
    assert.equal(prjJson.status, "CREATED");

    const instRes = await fetch(`${APP_URL}/api/v1/instruments`, {
      method: "POST",
      headers: {
        cookie: sa.cookie,
        "content-type": "application/json",
        "idempotency-key": "e2e-cmd018-ins-0001"
      },
      body: JSON.stringify({ instrument_type: "IFP_E2E", code: "IFP-E2E", name: "E2E IFP 75" })
    });
    assert.equal(instRes.status, 201);

    // 6. Verify authenticated SSR pages render HTTP 200 cleanly for SA
    for (const authedPage of ["/auth/pending", "/admin/accounts", "/workspace", "/inspections", "/notifications"]) {
      const pageRes = await fetch(`${APP_URL}${authedPage}`, {
        headers: { cookie: sa.cookie },
        redirect: "manual"
      });
      assert.equal(pageRes.status, 200, `Expected 200 on authed ${authedPage}, got ${pageRes.status}`);
      const html = await pageRes.text();
      assert.ok(html.includes("Dit. SD Inspection"), `Missing workspace header on ${authedPage}`);
    }

    // 7. Verify applicant sees 200 on /notifications and /api/v1/notifications (empty inbox, zero cross-user leakage)
    const notifRes = await fetch(`${APP_URL}/api/v1/notifications`, {
      headers: { cookie: applicant.cookie }
    });
    assert.equal(notifRes.status, 200);
    const notifJson = await notifRes.json();
    assert.equal(notifJson.status, "OK");
    assert.deepEqual(notifJson.notifications, []);

    console.log("    PASS: Full authenticated Next.js API + GoTrue JWT + SSR UI E2E flow verified!");
    console.log("\nALL_G11_LOCAL_HTTP_E2E_ASSERTIONS_PASSED");
  } finally {
    if (server.pid) {
      try {
        process.kill(-server.pid, "SIGTERM");
      } catch {
        server.kill("SIGTERM");
      }
    }
  }
}

main().catch((err) => {
  console.error("G11 HTTP E2E FAILED:", err);
  process.exit(1);
});
