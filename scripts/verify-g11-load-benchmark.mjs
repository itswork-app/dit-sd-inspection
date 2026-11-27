#!/usr/bin/env node
/**
 * Local G11 Synthetic 100-Concurrent-User Load Benchmark (Pre-Staging Baseline for DGA-B08)
 *
 * Runs strictly against isolated local Next.js production server (`next start -p 3197`)
 * and isolated local Supabase (`http://127.0.0.1:54421`). Never touches hosted/production services.
 *
 * Workload:
 * - 100 concurrent synthetic requests across authenticated API reads (`/api/v1/account/me`,
 *   `/api/v1/projects`, `/api/v1/notifications`) and concurrent protected writes (`CMD-022`
 *   unique unit registration) plus health checks.
 * - Reports p50 / p95 / p99 / max latencies (ms), throughput (req/s), and asserts 0% error rate.
 */
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { performance } from "node:perf_hooks";

const SUPABASE_URL = process.env.LOCAL_SUPABASE_URL ?? "http://127.0.0.1:54421";
const PUBLISHABLE_KEY =
  process.env.LOCAL_SUPABASE_PUBLISHABLE_KEY ?? "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH";
const SERVICE_ROLE_KEY =
  process.env.LOCAL_SUPABASE_SERVICE_ROLE_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";
const APP_PORT = 3197;
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
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error("Next.js server did not become healthy in time");
}

function encodeCookie(sessionJson) {
  const b64url = Buffer.from(JSON.stringify(sessionJson), "utf8").toString("base64url");
  return `sb-127-auth-token=base64-${b64url}`;
}

async function createAndSignIn(email, password) {
  const createRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE_KEY,
      authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({ email, password, email_confirm: true })
  });
  if (!createRes.ok) throw new Error(`Create user failed: ${await createRes.text()}`);
  const created = await createRes.json();

  const tokenRes = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: PUBLISHABLE_KEY, "content-type": "application/json" },
    body: JSON.stringify({ email, password })
  });
  if (!tokenRes.ok) throw new Error(`Sign-in failed: ${await tokenRes.text()}`);
  const session = await tokenRes.json();
  return { userId: created.id, cookie: encodeCookie(session) };
}

function percentile(sorted, p) {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1);
  return Number(sorted[idx].toFixed(1));
}

async function timedFetch(url, options) {
  const t0 = performance.now();
  const res = await fetch(url, options);
  await res.text();
  return { status: res.status, ms: performance.now() - t0 };
}

async function main() {
  console.log("==> [G11 Load Benchmark] Starting local Next.js production server...");
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
    const runTag = Date.now().toString(36);

    // Seed 1 bootstrap grantor + 10 synthetic approved Super Admin sessions (respecting RBAC-003 chk_user_roles_no_self_grant)
    const grantor = await createAndSignIn(`load-grantor-${runTag}@synthetic.local`, "LoadTestPass!2026");
    const users = [];
    for (let i = 0; i < 10; i += 1) {
      const u = await createAndSignIn(`load-u${i}-${runTag}@synthetic.local`, "LoadTestPass!2026");
      users.push(u);
    }

    const grantorSql = `
      INSERT INTO public.app_users (id, auth_user_id, display_name, account_status)
      VALUES ('${grantor.userId}', '${grantor.userId}', 'Load Benchmark Bootstrap Grantor', 'APPROVED')
      ON CONFLICT (id) DO NOTHING;
    `;
    const seedSql =
      grantorSql +
      users
        .map(
          (u, idx) => `
      INSERT INTO public.app_users (id, auth_user_id, display_name, account_status)
      VALUES ('${u.userId}', '${u.userId}', 'Load Operator ${idx}', 'APPROVED')
      ON CONFLICT (id) DO NOTHING;
      INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
      SELECT '${u.userId}', id, NULL, 'ACTIVE', '${grantor.userId}', 'Local G11 load benchmark synthetic operator'
      FROM public.roles WHERE code = 'super_admin'
      ON CONFLICT DO NOTHING;
    `
        )
        .join("\n");
    await runPsql(seedSql);

    // Create 1 synthetic project + instrument for write load
    const prjRes = await fetch(`${APP_URL}/api/v1/projects`, {
      method: "POST",
      headers: {
        cookie: users[0].cookie,
        "content-type": "application/json",
        "idempotency-key": `load-prj-${runTag}`
      },
      body: JSON.stringify({ code: `LOAD-${runTag.toUpperCase()}`, name: "Local 100-User Load Project", timezone: "Asia/Jakarta" })
    });
    assert.equal(prjRes.status, 201);
    const prjJson = await prjRes.json();

    const instRes = await fetch(`${APP_URL}/api/v1/instruments`, {
      method: "POST",
      headers: {
        cookie: users[0].cookie,
        "content-type": "application/json",
        "idempotency-key": `load-ins-${runTag}`
      },
      body: JSON.stringify({
        instrument_type: `IFP_LOAD_${runTag.toUpperCase()}`,
        code: `IFP-L-${runTag.toUpperCase()}`,
        name: "Load Benchmark IFP"
      })
    });
    assert.equal(instRes.status, 201);
    const instJson = await instRes.json();
    await runPsql(`UPDATE public.instruments SET status = 'ACTIVE' WHERE id = '${instJson.instrument_id}';`);

    // Warmup 1 request
    await timedFetch(`${APP_URL}/api/v1/account/me`, { headers: { cookie: users[0].cookie } });

    // Wave 1: 100 concurrent mixed authenticated reads (account/me, projects, notifications, health)
    console.log("==> [Wave 1] Dispatching 100 concurrent mixed authenticated read requests...");
    const wave1Start = performance.now();
    const wave1Promises = Array.from({ length: 100 }, (_, i) => {
      const user = users[i % users.length];
      const mod = i % 4;
      if (mod === 0) return timedFetch(`${APP_URL}/api/v1/account/me`, { headers: { cookie: user.cookie } });
      if (mod === 1) return timedFetch(`${APP_URL}/api/v1/projects`, { headers: { cookie: user.cookie } });
      if (mod === 2) return timedFetch(`${APP_URL}/api/v1/notifications`, { headers: { cookie: user.cookie } });
      return timedFetch(`${APP_URL}/api/health`, {});
    });
    const wave1 = await Promise.all(wave1Promises);
    const wave1TotalMs = performance.now() - wave1Start;
    const wave1Errors = wave1.filter((r) => r.status !== 200);
    assert.equal(wave1Errors.length, 0, `Wave 1 had ${wave1Errors.length} non-200 responses`);
    const w1Lat = wave1.map((r) => r.ms).sort((a, b) => a - b);

    // Wave 2: 40 concurrent protected T-18 writes (CMD-022 unique unit registrations)
    console.log("==> [Wave 2] Dispatching 40 concurrent protected CMD-022 unit registrations...");
    const wave2Start = performance.now();
    const wave2Promises = Array.from({ length: 40 }, (_, i) => {
      const user = users[i % users.length];
      return timedFetch(`${APP_URL}/api/v1/units/register`, {
        method: "POST",
        headers: {
          cookie: user.cookie,
          "content-type": "application/json",
          "idempotency-key": `load-unit-${runTag}-${String(i).padStart(3, "0")}`
        },
        body: JSON.stringify({
          project_id: prjJson.project_id,
          instrument_id: instJson.instrument_id,
          serial_raw: `SN-LOAD-${runTag}-${String(i).padStart(4, "0")}`
        })
      });
    });
    const wave2 = await Promise.all(wave2Promises);
    const wave2TotalMs = performance.now() - wave2Start;
    const wave2Errors = wave2.filter((r) => r.status !== 201 && r.status !== 200);
    assert.equal(wave2Errors.length, 0, `Wave 2 had ${wave2Errors.length} non-2xx write responses`);
    const w2Lat = wave2.map((r) => r.ms).sort((a, b) => a - b);

    const summary = {
      scope: "LOCAL_SYNTHETIC_BENCHMARK_ONLY",
      wave1_100_concurrent_reads: {
        requests: wave1.length,
        errors: wave1Errors.length,
        wall_ms: Math.round(wave1TotalMs),
        rps: Number((wave1.length / (wave1TotalMs / 1000)).toFixed(1)),
        p50_ms: percentile(w1Lat, 50),
        p95_ms: percentile(w1Lat, 95),
        p99_ms: percentile(w1Lat, 99),
        max_ms: percentile(w1Lat, 100)
      },
      wave2_40_concurrent_t18_writes: {
        requests: wave2.length,
        errors: wave2Errors.length,
        wall_ms: Math.round(wave2TotalMs),
        rps: Number((wave2.length / (wave2TotalMs / 1000)).toFixed(1)),
        p50_ms: percentile(w2Lat, 50),
        p95_ms: percentile(w2Lat, 95),
        p99_ms: percentile(w2Lat, 99),
        max_ms: percentile(w2Lat, 100)
      }
    };

    console.log("    SUMMARY:", JSON.stringify(summary, null, 2));
    console.log("\nALL_G11_LOCAL_LOAD_BENCHMARK_PASSED");
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
  console.error("G11 LOAD BENCHMARK FAILED:", err);
  process.exit(1);
});
