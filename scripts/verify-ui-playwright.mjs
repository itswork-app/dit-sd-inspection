#!/usr/bin/env node
/**
 * Local Playwright Real-Browser UI E2E Verification
 * Starts isolated local `next start -p 3197` against local Supabase (`http://127.0.0.1:54421`),
 * verifies clean UI text (no internal governance/decision/command codes), and walks through the
 * real mobile Inspector flow: SN Input -> Auto-Register & Claim -> Pre-Checked Checklist ->
 * Uncheck Defect Guard -> MP4 Video Evidence Upload -> Submit.
 */
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = (() => {
  try {
    return require("playwright");
  } catch {
    return require(process.env.PLAYWRIGHT_PATH ?? "/home/kangza/.nvm/versions/node/v22.12.0/lib/node_modules/playwright");
  }
})();

const SUPABASE_URL = process.env.LOCAL_SUPABASE_URL ?? "http://127.0.0.1:54421";
const PUBLISHABLE_KEY =
  process.env.LOCAL_SUPABASE_PUBLISHABLE_KEY ?? "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH";
const SERVICE_ROLE_KEY =
  process.env.LOCAL_SUPABASE_SERVICE_ROLE_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";
const APP_PORT = 3197;
const APP_URL = `http://127.0.0.1:${APP_PORT}`;
const CONTAINER = "supabase_db_dit-sd-inspection";

const FORBIDDEN_UI_CODE_REGEX =
  /\b(CMD-\d{3}|POQ-\d{2}|PO 1B|PO-2026-|RBAC-003|SES-001|INS-005|NLA-001|DOC-003|T-09|T-10|T-12|T-14|T-16|T-17|T-18|PHASE I0|62\/62)\b|PRIMARY KEY:|evidence\.accessed|document\.accessed/i;

// Minimal valid MP4 header (`ftypisom`) accepted by detectAllowedMimeFromBytes
const SYNTHETIC_MP4_BYTES = Buffer.from(
  "000000186674797069736f6d0000020069736f6d69736f326d703431000000086d646174",
  "hex"
);

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
  return { userId: created.id, session, cookieStr: encodeSupabaseSsrCookie(session) };
}

async function apiJson(cookieStr, path, body, idemKey) {
  const res = await fetch(`${APP_URL}${path}`, {
    method: "POST",
    headers: {
      cookie: cookieStr,
      "content-type": "application/json",
      "idempotency-key": idemKey
    },
    body: JSON.stringify(body)
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`POST ${path} failed (${res.status}): ${text}`);
  }
  return JSON.parse(text);
}

function assertNoForbiddenCodes(label, bodyText) {
  const match = bodyText.match(FORBIDDEN_UI_CODE_REGEX);
  assert.equal(
    match,
    null,
    `UI page "${label}" still contains internal doc/command code: ${match?.[0] ?? ""}`
  );
}

async function launchChromium() {
  try {
    return await chromium.launch({ headless: true });
  } catch {
    return await chromium.launch({
      headless: true,
      executablePath: "/snap/bin/chromium"
    });
  }
}

async function main() {
  console.log("==> [Playwright UI E2E] Starting local Next.js server pointed at local Supabase...");
  const server = spawn("npx", ["next", "start", "-H", "127.0.0.1", "-p", String(APP_PORT)], {
    detached: true,
    env: {
      ...process.env,
      NEXT_PUBLIC_SUPABASE_URL: SUPABASE_URL,
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: PUBLISHABLE_KEY
    },
    stdio: ["ignore", "ignore", "ignore"]
  });

  let browser = null;

  try {
    await waitForHealth();
    console.log("    Next.js server healthy on", APP_URL);

    // 1. Seed Super Admin + Inspector via GoTrue & DB bootstrap
    const runTag = Date.now().toString(36);
    const sa = await createAndSignInLocalUser(`pw-sa-${runTag}@example.test`, "SyntheticPass123!");
    const insp = await createAndSignInLocalUser(`pw-insp-${runTag}@example.test`, "SyntheticPass123!");

    const saAppId = crypto.randomUUID();
    const helperAppId = crypto.randomUUID();
    const helperAuthId = crypto.randomUUID();
    const inspAppId = crypto.randomUUID();

    await runPsql(`
      INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
      VALUES ('${helperAuthId}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'pw-seed-${runTag}@example.test', '{}', '{}', now(), now());
      INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
      VALUES
        ('${saAppId}', '${sa.userId}', 'PW Super Admin', 'APPROVED', 1),
        ('${inspAppId}', '${insp.userId}', 'PW Field Inspector', 'APPROVED', 1),
        ('${helperAppId}', '${helperAuthId}', 'PW Bootstrap Helper', 'APPROVED', 1);
      INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
      SELECT '${saAppId}', r.id, NULL, 'ACTIVE', '${helperAppId}', 'PW SA bootstrap'
      FROM public.roles r WHERE r.code = 'super_admin';
    `);

    // 2. Provision Project, Location, Team, Instrument + Draft (with EVD_DEFECT video) + Publish, Session + Assignment via live APIs
    const prj = await apiJson(
      sa.cookieStr,
      "/api/v1/projects",
      { code: `PW-PRJ-${runTag.toUpperCase()}`, name: "Playwright Test Project", timezone: "Asia/Jakarta" },
      `pw-prj-${runTag}`
    );
    await apiJson(
      sa.cookieStr,
      "/api/v1/admin/roles/grant",
      {
        target_user_id: inspAppId,
        role_code: "inspector",
        project_id: prj.project_id,
        reason: "Playwright synthetic inspector assignment"
      },
      `pw-role-${runTag}`
    );
    const loc = await apiJson(
      sa.cookieStr,
      "/api/v1/projects/locations",
      { project_id: prj.project_id, code: "LOC-PW-01", name: "SDN Playwright 01" },
      `pw-loc-${runTag}`
    );
    const team = await apiJson(
      sa.cookieStr,
      "/api/v1/projects/teams",
      { project_id: prj.project_id, code: "TIM-PW-01", name: "Tim Lapangan Playwright" },
      `pw-tim-${runTag}`
    );
    const instType = `IFP_${runTag.toUpperCase()}`;
    const inst = await apiJson(
      sa.cookieStr,
      "/api/v1/instruments",
      { instrument_type: instType, code: `PW-IFP-${runTag.toUpperCase()}`, name: "IFP 75 Inch PW" },
      `pw-inst-${runTag}`
    );
    const draft = await apiJson(
      sa.cookieStr,
      "/api/v1/instruments/draft",
      {
        instrument_id: inst.instrument_id,
        schema_version: "1.0",
        sections: [
          {
            code: "SEC_FISIK",
            label: "Pemeriksaan Fisik & Layar",
            items: [
              { code: "ITEM_BODY", label: "Fisik bodi & panel mulus", answer_type: "PASS_FAIL", required: true },
              { code: "ITEM_POWER", label: "Unit menyala normal", answer_type: "YES_NO", required: true }
            ]
          }
        ],
        spec_fields: [
          { code: "SPEC_SIZE", label: "Ukuran Layar", value_type: "INTEGER", expected_value: "75", unit: "inch", required: true }
        ],
        evidence_slots: [
          {
            code: "EVD_DEFECT",
            label: "Dokumentasi Kerusakan (Foto/Video)",
            required: false,
            allowed_media_types: ["image/jpeg", "image/png", "image/webp", "video/mp4", "video/webm"]
          }
        ]
      },
      `pw-draft-${runTag}`
    );
    await apiJson(
      sa.cookieStr,
      "/api/v1/instruments/publish",
      {
        instrument_id: inst.instrument_id,
        version_id: draft.version_id,
        expected_draft_hash: draft.draft_hash,
        change_summary: "Playwright publish"
      },
      `pw-pub-${runTag}`
    );
    const now = Date.now();
    const sess = await apiJson(
      sa.cookieStr,
      "/api/v1/sessions",
      {
        project_id: prj.project_id,
        code: `SESS-PW-${runTag.toUpperCase()}`,
        starts_at: new Date(now - 3600_000).toISOString(),
        ends_at: new Date(now + 86400_000).toISOString()
      },
      `pw-sess-${runTag}`
    );
    await apiJson(
      sa.cookieStr,
      "/api/v1/sessions/transition",
      {
        session_id: sess.session_id,
        action: "ACTIVATE",
        expected_row_version: "1",
        reason: "Aktifkan sesi untuk uji Playwright"
      },
      `pw-sess-act-${runTag}`
    );
    await apiJson(
      sa.cookieStr,
      "/api/v1/assignments",
      {
        project_id: prj.project_id,
        session_id: sess.session_id,
        location_id: loc.location_id,
        instrument_id: inst.instrument_id,
        instrument_version_id: draft.version_id,
        team_id: team.team_id,
        starts_at: new Date(now - 3600_000).toISOString(),
        ends_at: new Date(now + 86400_000).toISOString(),
        members: [{ user_id: inspAppId, operational_role: "inspector" }]
      },
      `pw-asgn-${runTag}`
    );

    // 3. Launch Chromium and verify public + SA + Inspector UI
    browser = await launchChromium();

    const unauthCtx = await browser.newContext();
    const unauthPage = await unauthCtx.newPage();
    const unauthErrors = [];
    unauthPage.on("pageerror", (e) => unauthErrors.push(e.message));

    await unauthPage.goto(`${APP_URL}/`, { waitUntil: "networkidle" });
    assertNoForbiddenCodes("/", await unauthPage.locator("body").innerText());

    await unauthPage.goto(`${APP_URL}/login`, { waitUntil: "networkidle" });
    assertNoForbiddenCodes("/login", await unauthPage.locator("body").innerText());

    await unauthPage.goto(`${APP_URL}/inspections`, { waitUntil: "networkidle" });
    assert.ok(unauthPage.url().includes("/login"), `Expected /inspections unauth redirect to /login, got ${unauthPage.url()}`);
    assert.equal(unauthErrors.length, 0, `Unexpected unauth pageerrors: ${unauthErrors.join("; ")}`);
    await unauthCtx.close();
    console.log("    PASS: Public pages & unauth redirect verified clean in Chromium");

    // 4. Super Admin check across operational routes
    const saCtx = await browser.newContext();
    await saCtx.addCookies([
      {
        name: "sb-127-auth-token",
        value: sa.cookieStr.replace("sb-127-auth-token=", ""),
        domain: "127.0.0.1",
        path: "/"
      }
    ]);
    const saPage = await saCtx.newPage();
    const saErrors = [];
    saPage.on("pageerror", (e) => saErrors.push(e.message));

    for (const route of ["/admin/accounts", "/workspace", "/operations", "/notifications"]) {
      const resp = await saPage.goto(`${APP_URL}${route}`, { waitUntil: "networkidle" });
      assert.equal(resp?.status(), 200, `Expected 200 on ${route}`);
      const text = await saPage.locator("body").innerText();
      assertNoForbiddenCodes(route, text);
    }
    assert.equal(saErrors.length, 0, `Unexpected SA pageerrors: ${saErrors.join("; ")}`);
    await saCtx.close();
    console.log("    PASS: Super Admin routes render with 200 and zero leaked internal codes");

    // 5. Mobile Inspector flow on /inspections
    const inspCtx = await browser.newContext({ viewport: { width: 412, height: 915 } });
    await inspCtx.addCookies([
      {
        name: "sb-127-auth-token",
        value: insp.cookieStr.replace("sb-127-auth-token=", ""),
        domain: "127.0.0.1",
        path: "/"
      }
    ]);
    const page = await inspCtx.newPage();
    const inspErrors = [];
    page.on("pageerror", (e) => inspErrors.push(e.message));

    await page.goto(`${APP_URL}/inspections`, { waitUntil: "networkidle" });
    assertNoForbiddenCodes("/inspections (initial)", await page.locator("body").innerText());

    // Verify camera QR/OCR controls exist
    await page.getByRole("button", { name: "Scan QR / OCR Kamera" }).waitFor({ state: "visible" });
    await page.getByRole("button", { name: "Foto Label (OCR)" }).waitFor({ state: "visible" });

    // Enter SN and auto-register + auto-claim
    const sn = `PWSN${runTag.toUpperCase()}`;
    await page.getByLabel("Serial Number unit").fill(sn);
    await page.getByRole("button", { name: "Cek SN & Klaim Unit" }).click();

    await page.getByText(`SN ${sn} diklaim`).waitFor({ state: "visible", timeout: 15000 });
    await page.getByText(`SN ${sn} · Inspeksi`).waitFor({ state: "visible", timeout: 15000 });

    // Option 1B: both checklist items must be pre-checked
    const bodyCheckbox = page.locator('input[type="checkbox"]').nth(0);
    const powerCheckbox = page.locator('input[type="checkbox"]').nth(1);
    assert.equal(await bodyCheckbox.isChecked(), true, "ITEM_BODY must default to pre-checked OK");
    assert.equal(await powerCheckbox.isChecked(), true, "ITEM_POWER must default to pre-checked OK");

    // Uncheck ITEM_BODY -> defect note input appears; submitting without note must be blocked
    await bodyCheckbox.uncheck();
    const defectInput = page.getByLabel("Keterangan kekurangan Fisik bodi & panel mulus");
    await defectInput.waitFor({ state: "visible" });

    await page.getByRole("button", { name: "Kirim untuk Review" }).click();
    await page.getByText("wajib diisi keterangan kekurangannya sebelum Submit").waitFor({ state: "visible" });

    // Fill defect note + required specification field and save draft
    await defectInput.fill("Baret halus di sudut kanan frame");
    await page.getByLabel(/Ukuran Layar/).fill("75");
    await page.getByRole("button", { name: "Simpan Draft Online" }).click();
    await page.getByText("Draft inspeksi tersimpan di server").waitFor({ state: "visible", timeout: 15000 });

    // Option 2A: Upload synthetic valid MP4 video to EVD_DEFECT slot
    const evidenceFileInput = page
      .locator("label")
      .filter({ hasText: "Unggah Bukti Foto / Video (maks. 25 MiB)" })
      .locator('input[type="file"]');
    await evidenceFileInput.setInputFiles({
      name: "defect-clip.mp4",
      mimeType: "video/mp4",
      buffer: SYNTHETIC_MP4_BYTES
    });
    await page.getByText("Bukti berhasil diunggah & terverifikasi").waitFor({ state: "visible", timeout: 20000 });

    // Submit inspection -> transitions to SUBMITTED
    await page.getByRole("button", { name: "Kirim untuk Review" }).click();
    await page.getByText("Inspeksi berhasil disubmit (revisi baru dibuat)").waitFor({ state: "visible", timeout: 15000 });
    await page.getByText("SUBMITTED · rev 1").waitFor({ state: "visible", timeout: 15000 });

    assertNoForbiddenCodes("/inspections (after submit)", await page.locator("body").innerText());
    assert.equal(inspErrors.length, 0, `Unexpected Inspector pageerrors: ${inspErrors.join("; ")}`);
    await inspCtx.close();

    console.log("    PASS: Full mobile Inspector flow verified in real Chromium (Scanner UI, Claim, Pre-checked Checklist, Defect Guard, MP4 Video Upload, Submit)!");
    console.log("\nALL_PLAYWRIGHT_UI_E2E_ASSERTIONS_PASSED");
  } finally {
    if (browser) {
      await browser.close().catch(() => {});
    }
    try {
      process.kill(-server.pid, "SIGTERM");
    } catch {
      // ignore if exited
    }
  }
}

main().catch((err) => {
  console.error("PLAYWRIGHT UI E2E FAILED:", err);
  process.exit(1);
});
