#!/usr/bin/env node
/**
 * Local G11 Live Private Storage & Real PDF 1.4 Binary E2E Verification
 * Exercises:
 *   1. CMD-033 create-upload-intent -> server-issued object_key + signed upload URL
 *   2. Real binary PNG upload to private bucket `inspection-private` via signed URL
 *   3. Unauthorized outsider denied download (403/404)
 *   4. Forged/spoofed HTML uploaded as PNG rejected by CMD-034 magic-byte verifier (400 EVIDENCE_INVALID)
 *   5. Valid PNG finalized by CMD-034 via server-side SHA-256 + magic-byte check + audited 60s signed download
 *   6. CMD-036 renders deterministic real %PDF-1.4 binary -> uploads to private Storage -> audited download verifies %PDF-1.4..%%EOF
 */
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawn } from "node:child_process";

const SUPABASE_URL = process.env.LOCAL_SUPABASE_URL ?? "http://127.0.0.1:54421";
const PUBLISHABLE_KEY =
  process.env.LOCAL_SUPABASE_PUBLISHABLE_KEY ?? "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH";
const SERVICE_ROLE_KEY =
  process.env.LOCAL_SUPABASE_SERVICE_ROLE_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";
const APP_PORT = 3198;
const APP_URL = `http://127.0.0.1:${APP_PORT}`;
const CONTAINER = "supabase_db_dit-sd-inspection";

// Valid minimal 1x1 PNG binary
const VALID_PNG_BYTES = Buffer.from(
  "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082",
  "hex"
);
const VALID_PNG_SHA256 = createHash("sha256").update(VALID_PNG_BYTES).digest("hex");

const FORGED_BYTES = Buffer.from("<html><script>alert('xss')</script></html>", "utf8");
const FORGED_SHA256 = createHash("sha256").update(FORGED_BYTES).digest("hex");

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
  if (!createRes.ok) throw new Error(`Create user ${email} failed: ${await createRes.text()}`);
  const created = await createRes.json();

  const tokenRes = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: PUBLISHABLE_KEY, "content-type": "application/json" },
    body: JSON.stringify({ email, password })
  });
  if (!tokenRes.ok) throw new Error(`Sign-in ${email} failed: ${await tokenRes.text()}`);
  const session = await tokenRes.json();
  return { userId: created.id, session, cookie: encodeSupabaseSsrCookie(session) };
}

async function postJson(path, cookie, idemKey, body) {
  const res = await fetch(`${APP_URL}${path}`, {
    method: "POST",
    headers: {
      cookie,
      "content-type": "application/json",
      "idempotency-key": idemKey
    },
    body: JSON.stringify(body)
  });
  const json = await res.json();
  return { status: res.status, json };
}

async function main() {
  console.log("==> [G11 Storage+PDF E2E] Starting local Next.js server against local Supabase Storage...");
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

    // 1. Provision synthetic users (SA, Inspector, Reviewer, Print Officer, Outsider)
    const sa = await createAndSignInLocalUser("st-sa@example.test", "SyntheticPass123!");
    const insp = await createAndSignInLocalUser("st-insp@example.test", "SyntheticPass123!");
    const rev = await createAndSignInLocalUser("st-rev@example.test", "SyntheticPass123!");
    const po = await createAndSignInLocalUser("st-po@example.test", "SyntheticPass123!");
    const outsider = await createAndSignInLocalUser("st-out@example.test", "SyntheticPass123!");

    const SA_U = "88000001-0000-4000-8000-000000000001";
    const INSP_U = "88000002-0000-4000-8000-000000000002";
    const REV_U = "88000003-0000-4000-8000-000000000003";
    const PO_U = "88000004-0000-4000-8000-000000000004";
    const OUT_U = "88000005-0000-4000-8000-000000000005";
    const TPL_ID = "88000099-0000-4000-8000-000000000099";

    await runPsql(`
      INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
      VALUES
        ('${SA_U}', '${sa.userId}', 'Storage SA', 'APPROVED', 1),
        ('${INSP_U}', '${insp.userId}', 'Storage Insp', 'APPROVED', 1),
        ('${REV_U}', '${rev.userId}', 'Storage Rev', 'APPROVED', 1),
        ('${PO_U}', '${po.userId}', 'Storage PO', 'APPROVED', 1),
        ('${OUT_U}', '${outsider.userId}', 'Storage Outsider', 'APPROVED', 1);

      INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
      SELECT '${SA_U}', r.id, NULL, 'ACTIVE', '${REV_U}', 'Storage E2E SA bootstrap'
      FROM public.roles r WHERE r.code = 'super_admin';

      INSERT INTO public.document_template_versions (id, document_type, template_key, version_no, template_hash, status, created_by)
      VALUES ('${TPL_ID}', 'INSPECTION_PDF', 'ST_IFP_PDF', 1, repeat('b', 64), 'ACTIVE', '${SA_U}');
    `);

    // 2. Setup project, location, team, instrument (with required PNG evidence slot), session, assignment
    const prj = await postJson("/api/v1/projects", sa.cookie, "st-prj-0001", { code: "ST-PRJ-01", name: "Storage E2E Project" });
    assert.equal(prj.status, 201);
    const projectId = prj.json.project_id;

    const loc = await postJson("/api/v1/projects/locations", sa.cookie, "st-loc-0001", { project_id: projectId, code: "LOC-ST", name: "Loc ST" });
    const team = await postJson("/api/v1/projects/teams", sa.cookie, "st-tm-00001", { project_id: projectId, code: "TM-ST", name: "Team ST" });

    for (const [uid, role, key] of [
      [INSP_U, "inspector", "st-gr-insp1"],
      [REV_U, "reviewer", "st-gr-rev01"],
      [PO_U, "print_officer", "st-gr-po001"]
    ]) {
      const gr = await postJson("/api/v1/admin/roles/grant", sa.cookie, key, {
        target_user_id: uid,
        role_code: role,
        project_id: projectId,
        reason: "Storage E2E role"
      });
      assert.equal(gr.status, 200);
    }

    const inst = await postJson("/api/v1/instruments", sa.cookie, "st-inst-001", { instrument_type: "IFP_ST", code: "IFP-ST", name: "IFP Storage" });
    const draft = await postJson("/api/v1/instruments/draft", sa.cookie, "st-drft-001", {
      instrument_id: inst.json.instrument_id,
      sections: [{ code: "S1", label: "Check", items: [{ code: "I1", label: "Panel OK", answer_type: "PASS_FAIL", required: true }] }],
      spec_fields: [],
      evidence_slots: [{ code: "EV_FRONT", label: "Front PNG", required: true, allowed_media_types: ["image/png"] }]
    });
    const pub = await postJson("/api/v1/instruments/publish", sa.cookie, "st-pub-0001", {
      instrument_id: inst.json.instrument_id,
      version_id: draft.json.version_id,
      expected_draft_hash: draft.json.draft_hash,
      change_summary: "Publish Storage E2E instrument"
    });
    assert.equal(pub.status, 200);

    const itemId = await runPsql(`SELECT ci.id FROM public.checklist_items ci JOIN public.checklist_sections cs ON cs.id = ci.section_id WHERE cs.instrument_version_id = '${draft.json.version_id}' LIMIT 1;`);
    const slotId = await runPsql(`SELECT id FROM public.evidence_slot_definitions WHERE instrument_version_id = '${draft.json.version_id}' LIMIT 1;`);

    const now = new Date();
    const later = new Date(now.getTime() + 6 * 3600 * 1000);
    const sess = await postJson("/api/v1/sessions", sa.cookie, "st-ses-0001", {
      project_id: projectId,
      code: "SESS-ST",
      starts_at: now.toISOString(),
      ends_at: later.toISOString()
    });
    await postJson("/api/v1/sessions/transition", sa.cookie, "st-sact-001", {
      session_id: sess.json.session_id,
      action: "ACTIVATE",
      expected_row_version: "1",
      reason: "Activate Storage E2E session"
    });

    const asgn = await postJson("/api/v1/assignments", sa.cookie, "st-asgn-001", {
      project_id: projectId,
      session_id: sess.json.session_id,
      location_id: loc.json.location_id,
      instrument_id: inst.json.instrument_id,
      instrument_version_id: draft.json.version_id,
      team_id: team.json.team_id,
      starts_at: now.toISOString(),
      ends_at: later.toISOString(),
      members: [{ user_id: INSP_U, operational_role: "inspector" }]
    });
    assert.equal(asgn.status, 200);

    // 3. Inspector registers & claims unit, saves draft
    const unit = await postJson("/api/v1/units/register", insp.cookie, "st-unit-001", {
      project_id: projectId,
      instrument_id: inst.json.instrument_id,
      serial_raw: "SN-STORAGE-001"
    });
    const claim = await postJson("/api/v1/claims", insp.cookie, "st-clm-0001", {
      unit_id: unit.json.unit_id,
      association_id: unit.json.association_id,
      assignment_id: asgn.json.assignment_id
    });
    const inspId = claim.json.inspection_id;

    await postJson("/api/v1/inspections/draft", insp.cookie, "st-sav-0001", {
      inspection_id: inspId,
      expected_row_version: "1",
      draft_checklist: { [itemId]: "PASS" }
    });

    // 4. Test forged HTML spoofed as PNG -> rejected by CMD-034 magic-byte verifier! [TC-EVD-002]
    const forgedIntent = await postJson("/api/v1/evidence/intent", insp.cookie, "st-evi-forg", {
      inspection_id: inspId,
      slot_definition_id: slotId,
      mime_type: "image/png",
      byte_size: FORGED_BYTES.byteLength,
      sha256: FORGED_SHA256,
      client_file_id: "forged-html-01"
    });
    assert.equal(forgedIntent.status, 201);
    assert.ok(forgedIntent.json.signed_upload_url, "CMD-033 must return signed_upload_url");

    const uploadForgedRes = await fetch(forgedIntent.json.signed_upload_url, {
      method: "PUT",
      headers: { "content-type": "image/png" },
      body: FORGED_BYTES
    });
    assert.ok(uploadForgedRes.ok, `Signed upload failed: ${await uploadForgedRes.text()}`);

    const confirmForged = await postJson("/api/v1/evidence/confirm", insp.cookie, "st-evc-forg", {
      evidence_asset_id: forgedIntent.json.evidence_asset_id
    });
    assert.equal(confirmForged.status, 400);
    assert.equal(confirmForged.json.status, "EVIDENCE_INVALID");
    console.log("    PASS: Spoofed HTML uploaded as PNG rejected server-side with 400 EVIDENCE_INVALID");

    // 5. Upload real valid PNG -> server verifies SHA-256 + PNG magic bytes -> FINALIZED! [TC-EVD-004]
    const validIntent = await postJson("/api/v1/evidence/intent", insp.cookie, "st-evi-ok01", {
      inspection_id: inspId,
      slot_definition_id: slotId,
      mime_type: "image/png",
      byte_size: VALID_PNG_BYTES.byteLength,
      sha256: VALID_PNG_SHA256,
      client_file_id: "valid-png-001"
    });
    assert.equal(validIntent.status, 201);

    const uploadValidRes = await fetch(validIntent.json.signed_upload_url, {
      method: "PUT",
      headers: { "content-type": "image/png" },
      body: VALID_PNG_BYTES
    });
    assert.ok(uploadValidRes.ok, `Valid PNG upload failed: ${await uploadValidRes.text()}`);

    const confirmValid = await postJson("/api/v1/evidence/confirm", insp.cookie, "st-evc-ok01", {
      evidence_asset_id: validIntent.json.evidence_asset_id
    });
    assert.equal(confirmValid.status, 200);
    assert.equal(confirmValid.json.status, "FINALIZED");

    // Outsider CANNOT get signed download URL for private evidence
    const outsiderDl = await fetch(`${APP_URL}/api/v1/evidence/${validIntent.json.evidence_asset_id}/download`, {
      headers: { cookie: outsider.cookie }
    });
    assert.equal(outsiderDl.status, 403, `Expected 403 for outsider evidence download, got ${outsiderDl.status}`);

    // Authorized Inspector gets 60s audited signed download URL and downloads exact PNG bytes
    const authedDl = await fetch(`${APP_URL}/api/v1/evidence/${validIntent.json.evidence_asset_id}/download`, {
      headers: { cookie: insp.cookie }
    });
    assert.equal(authedDl.status, 200);
    const dlJson = await authedDl.json();
    const downloadedPng = Buffer.from(await (await fetch(dlJson.signed_url)).arrayBuffer());
    assert.equal(createHash("sha256").update(downloadedPng).digest("hex"), VALID_PNG_SHA256);
    console.log("    PASS: Real PNG uploaded, server SHA-256/magic-byte verified, outsider 403 denied, audited 60s download matched exact bytes");

    // 6. Submit, Approve, and Generate real %PDF-1.4 document into private Storage (CMD-036)! [TC-DOC-001]
    const sub = await postJson("/api/v1/inspections/submit", insp.cookie, "st-sub-0001", {
      inspection_id: inspId,
      expected_row_version: "2",
      submit_reason: "Submit with verified PNG"
    });
    assert.equal(sub.status, 200);

    const app = await postJson("/api/v1/inspections/approve", rev.cookie, "st-app-0001", {
      inspection_id: inspId,
      revision_id: sub.json.revision_id,
      expected_revision_no: 1,
      reason: "Approved for PDF generation"
    });
    assert.equal(app.status, 200);

    const gen = await postJson("/api/v1/documents/generate", po.cookie, "st-pdf-0001", {
      document_type: "INSPECTION_PDF",
      inspection_id: inspId,
      approved_revision_id: sub.json.revision_id,
      template_version_id: TPL_ID
    });
    assert.equal(gen.status, 201);
    assert.equal(gen.json.storage_uploaded, true, `PDF upload to private storage failed: ${JSON.stringify(gen.json)}`);

    // Outsider denied PDF download; Print Officer gets audited signed URL & downloads valid %PDF-1.4 binary
    const outPdf = await fetch(`${APP_URL}/api/v1/documents/${gen.json.document_id}/download`, {
      headers: { cookie: outsider.cookie }
    });
    assert.equal(outPdf.status, 403);

    const poPdf = await fetch(`${APP_URL}/api/v1/documents/${gen.json.document_id}/download`, {
      headers: { cookie: po.cookie }
    });
    assert.equal(poPdf.status, 200);
    const poPdfJson = await poPdf.json();
    const pdfBytes = Buffer.from(await (await fetch(poPdfJson.signed_url)).arrayBuffer());
    const pdfText = pdfBytes.toString("ascii");
    assert.ok(pdfText.startsWith("%PDF-1.4\n"), "Downloaded PDF must start with %PDF-1.4");
    assert.ok(pdfText.endsWith("%%EOF\n"), "Downloaded PDF must end with %%EOF");
    assert.equal(createHash("sha256").update(pdfBytes).digest("hex"), gen.json.pdf_sha256);

    // Verify audit_events captured both evidence.accessed and document.accessed
    const accessAuditCount = Number(
      await runPsql(`SELECT count(*) FROM public.audit_events WHERE event_type IN ('evidence.accessed', 'document.accessed');`)
    );
    assert.equal(accessAuditCount, 2, `Expected 2 artifact access audit events, got ${accessAuditCount}`);

    console.log("    PASS: Real %PDF-1.4 binary rendered, stored in private bucket, outsider 403 denied, audited 60s download verified!");
    console.log("\nALL_G11_LOCAL_STORAGE_AND_PDF_E2E_ASSERTIONS_PASSED");
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
  console.error("G11 STORAGE+PDF E2E FAILED:", err);
  process.exit(1);
});
