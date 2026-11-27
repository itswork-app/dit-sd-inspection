#!/usr/bin/env node
/**
 * Local G11 Adversarial Multi-Connection PostgreSQL Concurrency Suite
 * Exercises true parallel database connections against isolated local Supabase PG 16:
 *   - LG-01/LG-03: T-14 Inspector capacity cap race (cap=2 vs 4 concurrent Inspector additions)
 *   - LG-31:       T-16 Cross-project canonical serial race (4 projects registering same serial)
 *   - LG-33:       Global active claim race (4 Inspectors claiming same unit concurrently)
 *   - LG-16:       Single terminal review arbiter race (RETURN vs APPROVE on same revision)
 *   - LG-21:       Monotonic print sequence race (6 concurrent CMD-037 prints)
 *   - LG-41:       Idempotency concurrent replay & tampered-payload rejection
 */
import { spawn } from "node:child_process";
import assert from "node:assert/strict";

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
      if (code !== 0) {
        reject(new Error(`psql exited ${code}: ${stderr.trim() || stdout.trim()}`));
      } else {
        resolve(stdout.trim());
      }
    });
    child.stdin.end(sql);
  });
}

async function runCmdAs(authUid, sqlExpr) {
  const sql = `
    BEGIN;
    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = '${authUid}';
    SELECT (${sqlExpr})::text;
    COMMIT;
  `;
  const out = await runPsql(sql);
  const lines = out.split(/\r?\n/).filter((l) => l.startsWith("{"));
  assert.ok(lines.length >= 1, `Expected JSON line from psql, got: ${out}`);
  return JSON.parse(lines[lines.length - 1]);
}

async function main() {
  console.log("==> [G11 Concurrency] Seeding isolated synthetic actors...");

  const SA_AUTH = "90000001-0000-4000-8000-000000000001";
  const SA_USER = "91000001-0000-4000-8000-000000000001";
  const INSP_AUTHS = [
    "90000002-0000-4000-8000-000000000002",
    "90000003-0000-4000-8000-000000000003",
    "90000004-0000-4000-8000-000000000004",
    "90000005-0000-4000-8000-000000000005"
  ];
  const INSP_USERS = [
    "91000002-0000-4000-8000-000000000002",
    "91000003-0000-4000-8000-000000000003",
    "91000004-0000-4000-8000-000000000004",
    "91000005-0000-4000-8000-000000000005"
  ];
  const REV1_AUTH = "90000006-0000-4000-8000-000000000006";
  const REV1_USER = "91000006-0000-4000-8000-000000000006";
  const REV2_AUTH = "90000007-0000-4000-8000-000000000007";
  const REV2_USER = "91000007-0000-4000-8000-000000000007";
  const PO_AUTH = "90000008-0000-4000-8000-000000000008";
  const PO_USER = "91000008-0000-4000-8000-000000000008";
  const TPL_ID = "92000001-0000-4000-8000-000000000001";

  const seedSql = `
    INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES
      ('${SA_AUTH}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'g11-sa@example.test', '{}', '{}', now(), now()),
      ('${INSP_AUTHS[0]}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'g11-i1@example.test', '{}', '{}', now(), now()),
      ('${INSP_AUTHS[1]}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-i2@example.test', '{}', '{}', now(), now()),
      ('${INSP_AUTHS[2]}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-i3@example.test', '{}', '{}', now(), now()),
      ('${INSP_AUTHS[3]}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-i4@example.test', '{}', '{}', now(), now()),
      ('${REV1_AUTH}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-r1@example.test', '{}', '{}', now(), now()),
      ('${REV2_AUTH}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-r2@example.test', '{}', '{}', now(), now()),
      ('${PO_AUTH}', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'g11-po@example.test', '{}', '{}', now(), now());

    INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
    VALUES
      ('${SA_USER}', '${SA_AUTH}', 'G11 SA', 'APPROVED', 1),
      ('${INSP_USERS[0]}', '${INSP_AUTHS[0]}', 'G11 Insp 1', 'APPROVED', 1),
      ('${INSP_USERS[1]}', '${INSP_AUTHS[1]}', 'G11 Insp 2', 'APPROVED', 1),
      ('${INSP_USERS[2]}', '${INSP_AUTHS[2]}', 'G11 Insp 3', 'APPROVED', 1),
      ('${INSP_USERS[3]}', '${INSP_AUTHS[3]}', 'G11 Insp 4', 'APPROVED', 1),
      ('${REV1_USER}', '${REV1_AUTH}', 'G11 Rev 1', 'APPROVED', 1),
      ('${REV2_USER}', '${REV2_AUTH}', 'G11 Rev 2', 'APPROVED', 1),
      ('${PO_USER}', '${PO_AUTH}', 'G11 Print Officer', 'APPROVED', 1);

    INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
    SELECT '${SA_USER}', r.id, NULL, 'ACTIVE', '${REV1_USER}', 'G11 synthetic SA bootstrap'
    FROM public.roles r WHERE r.code = 'super_admin';

    INSERT INTO public.document_template_versions (id, document_type, template_key, version_no, template_hash, status, created_by)
    VALUES ('${TPL_ID}', 'INSPECTION_PDF', 'G11_PDF_TPL', 1, repeat('a', 64), 'ACTIVE', '${SA_USER}');
  `;
  await runPsql(seedSql);

  // Create 4 projects + published instrument + active session + assignment on Project 0
  const projects = [];
  for (let i = 0; i < 4; i++) {
    const p = await runCmdAs(
      SA_AUTH,
      `public.cmd_create_project_v1('g11-prj-000${i}', 'G11-PRJ-${i}', 'G11 Project ${i}', 'Asia/Jakarta')`
    );
    assert.equal(p.status, "CREATED");
    projects.push(p.project_id);
  }

  const inst = await runCmdAs(
    SA_AUTH,
    `public.cmd_create_instrument_v1('g11-inst-001', 'IFP_G11', 'IFP-G11', 'IFP G11', NULL, true)`
  );
  const draft = await runCmdAs(
    SA_AUTH,
    `public.cmd_save_instrument_draft_v1('g11-drft-001', '${inst.instrument_id}', NULL, '1.0', '[{"code":"S1","label":"Check","items":[{"code":"I1","label":"OK","answer_type":"PASS_FAIL","required":true}]}]'::jsonb, '[]'::jsonb, '[]'::jsonb)`
  );
  const pub = await runCmdAs(
    SA_AUTH,
    `public.cmd_publish_instrument_version_v1('g11-pub-0001', '${inst.instrument_id}', '${draft.version_id}', '${draft.draft_hash}', 'G11 Publish')`
  );
  assert.equal(pub.status, "PUBLISHED");
  const itemId = await runPsql(
    `SELECT ci.id FROM public.checklist_items ci JOIN public.checklist_sections cs ON cs.id = ci.section_id WHERE cs.instrument_version_id = '${draft.version_id}' LIMIT 1;`
  );

  // Grant roles on Project 0..3
  for (let i = 0; i < 4; i++) {
    await runCmdAs(
      SA_AUTH,
      `public.cmd_grant_role_v1('g11-gr-i${i}-p0', '${INSP_USERS[i]}', 'inspector', '${projects[0]}', now(), NULL, 'G11 Inspector')`
    );
    await runCmdAs(
      SA_AUTH,
      `public.cmd_grant_role_v1('g11-gr-i${i}-p${i}', '${INSP_USERS[i]}', 'inspector', '${projects[i]}', now(), NULL, 'G11 Inspector Cross')`
    );
  }
  await runCmdAs(SA_AUTH, `public.cmd_grant_role_v1('g11-gr-r1-p0', '${REV1_USER}', 'reviewer', '${projects[0]}', now(), NULL, 'G11 Rev 1')`);
  await runCmdAs(SA_AUTH, `public.cmd_grant_role_v1('g11-gr-r2-p0', '${REV2_USER}', 'reviewer', '${projects[0]}', now(), NULL, 'G11 Rev 2')`);
  await runCmdAs(SA_AUTH, `public.cmd_grant_role_v1('g11-gr-po-p0', '${PO_USER}', 'print_officer', '${projects[0]}', now(), NULL, 'G11 Print Officer')`);

  const loc0 = await runCmdAs(SA_AUTH, `public.cmd_create_location_v1('g11-loc-0001', '${projects[0]}', 'LOC-G11', 'G11 Warehouse')`);
  const team0 = await runCmdAs(SA_AUTH, `public.cmd_create_team_v1('g11-tm-00001', '${projects[0]}', 'TM-G11', 'G11 Team')`);
  const sess0 = await runCmdAs(SA_AUTH, `public.cmd_create_session_v1('g11-ses-0001', '${projects[0]}', 'SESS-G11', now(), now() + interval '8 hours')`);
  await runCmdAs(SA_AUTH, `public.cmd_transition_session_v1('g11-sact-001', '${sess0.session_id}', 'ACTIVATE', 1, 'Start G11')`);

  // =========================================================================
  // TEST 1: LG-01/LG-03 — T-14 Inspector Capacity Race (cap=2 vs 4 concurrent additions)
  // =========================================================================
  console.log("==> [LG-01/LG-03] Running 4-way concurrent T-14 Inspector capacity race (cap=2)...");
  const capRes = await runCmdAs(SA_AUTH, `public.cmd_change_inspector_capacity_v1('g11-cap-0002', '${projects[0]}', 2, 1, 'Set cap=2 for concurrency test')`);
  assert.equal(capRes.status, "UPDATED");

  // Publish assignment with reviewer first so we can race 4 concurrent CMD-015 additions
  const asgn0 = await runCmdAs(
    SA_AUTH,
    `public.cmd_publish_assignment_v1('g11-asgn-001', '${projects[0]}', '${sess0.session_id}', '${loc0.location_id}', '${inst.instrument_id}', '${draft.version_id}', '${team0.team_id}', now(), now() + interval '4 hours', '[{"user_id":"${REV1_USER}","operational_role":"reviewer"}]'::jsonb)`
  );
  assert.equal(asgn0.status, "PUBLISHED");

  const capRaceResults = await Promise.all(
    INSP_USERS.map((uid, idx) =>
      runCmdAs(
        SA_AUTH,
        `public.cmd_change_assignment_members_v1('g11-race-cap-${idx}', '${asgn0.assignment_id}', '[{"user_id":"${uid}","operational_role":"inspector"}]'::jsonb, ARRAY[]::uuid[], 'Concurrent T-14 add ${idx}')`
      )
    )
  );
  const capWinners = capRaceResults.filter((r) => r.status === "UPDATED");
  const capRejected = capRaceResults.filter((r) => r.status === "CAPACITY_EXCEEDED");
  const actualQualifying = Number(await runPsql(`SELECT app_internal.count_qualifying_inspectors('${projects[0]}');`));
  assert.equal(capWinners.length, 2, `Expected exactly 2 cap winners, got ${JSON.stringify(capRaceResults)}`);
  assert.equal(capRejected.length, 2, `Expected exactly 2 CAPACITY_EXCEEDED, got ${JSON.stringify(capRaceResults)}`);
  assert.equal(actualQualifying, 2, `Expected qualifying count = 2, got ${actualQualifying}`);
  console.log("    PASS: 2 UPDATED, 2 CAPACITY_EXCEEDED, final qualifying count = 2 (0 deadlocks)");

  // Raise cap to 4 & add remaining 2 inspectors so all 4 can race on LG-33 claim!
  await runCmdAs(SA_AUTH, `public.cmd_change_inspector_capacity_v1('g11-cap-0004', '${projects[0]}', 4, 2, 'Raise cap=4 for LG-33')`);
  for (let i = 0; i < 4; i++) {
    await runCmdAs(
      SA_AUTH,
      `public.cmd_change_assignment_members_v1('g11-ensure-i${i}', '${asgn0.assignment_id}', '[{"user_id":"${INSP_USERS[i]}","operational_role":"inspector"}]'::jsonb, ARRAY[]::uuid[], 'Ensure all 4 assigned')`
    );
  }

  // =========================================================================
  // TEST 2: LG-31 — T-16 Cross-Project Canonical Serial Race (4 projects same serial)
  // =========================================================================
  console.log("==> [LG-31] Running 4-way concurrent T-16 cross-project canonical serial race...");
  const serialRaceResults = await Promise.all(
    projects.map((pid, idx) =>
      runCmdAs(
        INSP_AUTHS[idx],
        `public.cmd_register_canonical_unit_v1('g11-race-sn-${idx}', '${pid}', '${inst.instrument_id}', '  g11-shared-sn-999  ', '{}'::jsonb)`
      )
    )
  );
  const regWinners = serialRaceResults.filter((r) => r.status === "REGISTERED");
  const regConflicts = serialRaceResults.filter((r) => r.status === "CONFLICT_REVIEW_REQUIRED");
  const canonicalCount = Number(
    await runPsql(`SELECT count(*) FROM public.units WHERE instrument_type = 'IFP_G11' AND serial_normalized = 'G11-SHARED-SN-999';`)
  );
  assert.equal(regWinners.length, 1, `Expected 1 REGISTERED winner, got ${JSON.stringify(serialRaceResults)}`);
  assert.equal(regConflicts.length, 3, `Expected 3 CONFLICT_REVIEW_REQUIRED, got ${JSON.stringify(serialRaceResults)}`);
  assert.equal(canonicalCount, 1, `Expected exactly 1 canonical unit row, got ${canonicalCount}`);
  assert.ok(regConflicts.every((c) => !("unit_id" in c)), "Conflict response must never leak candidate unit_id!");
  console.log("    PASS: 1 REGISTERED, 3 CONFLICT_REVIEW_REQUIRED (zero unit_id leak), 1 canonical row");

  // =========================================================================
  // TEST 3: LG-33 — Global Active Claim Race (4 Inspectors claiming same unit)
  // =========================================================================
  console.log("==> [LG-33] Running 4-way concurrent global active unit claim race...");
  const unitRes = await runCmdAs(
    INSP_AUTHS[0],
    `public.cmd_register_canonical_unit_v1('g11-u-claim1', '${projects[0]}', '${inst.instrument_id}', 'G11-CLAIM-UNIT-1', '{}'::jsonb)`
  );
  assert.equal(unitRes.status, "REGISTERED");

  const claimRaceResults = await Promise.all(
    INSP_AUTHS.map((authUid, idx) =>
      runCmdAs(
        authUid,
        `public.cmd_claim_unit_v1('g11-race-clm-${idx}', '${unitRes.unit_id}', '${unitRes.association_id}', '${asgn0.assignment_id}', 60)`
      )
    )
  );
  const claimWinners = claimRaceResults.filter((r) => r.status === "CLAIMED");
  const claimLosers = claimRaceResults.filter((r) => r.status === "ACTIVE_CLAIM_EXISTS");
  const activeClaimRows = Number(
    await runPsql(`SELECT count(*) FROM public.unit_claims WHERE unit_id = '${unitRes.unit_id}' AND status = 'ACTIVE';`)
  );
  assert.equal(claimWinners.length, 1, `Expected 1 CLAIMED winner, got ${JSON.stringify(claimRaceResults)}`);
  assert.equal(claimLosers.length, 3, `Expected 3 ACTIVE_CLAIM_EXISTS, got ${JSON.stringify(claimRaceResults)}`);
  assert.equal(activeClaimRows, 1, `Expected 1 ACTIVE claim row, got ${activeClaimRows}`);
  console.log("    PASS: 1 CLAIMED, 3 ACTIVE_CLAIM_EXISTS, exactly 1 ACTIVE claim row");

  // =========================================================================
  // TEST 4: LG-16 — Single Terminal Review Decision Arbiter Race (RETURN vs APPROVE)
  // =========================================================================
  console.log("==> [LG-16] Running concurrent RETURN vs APPROVE review arbiter race...");
  const winnerIdx = claimRaceResults.findIndex((r) => r.status === "CLAIMED");
  const winnerAuth = INSP_AUTHS[winnerIdx];
  const inspId = claimWinners[0].inspection_id;

  const saveRes = await runCmdAs(
    winnerAuth,
    `public.cmd_save_draft_v1('g11-sav-0001', '${inspId}', 1, '{"${itemId}":"PASS"}'::jsonb, '{}'::jsonb, 'G11 draft')`
  );
  assert.equal(saveRes.status, "SAVED");
  const subRes = await runCmdAs(winnerAuth, `public.cmd_submit_inspection_v1('g11-sub-0001', '${inspId}', 2, 'G11 submit')`);
  assert.equal(subRes.status, "SUBMITTED");

  const [retRes, appRes] = await Promise.all([
    runCmdAs(REV1_AUTH, `public.cmd_return_inspection_v1('g11-race-ret1', '${inspId}', '${subRes.revision_id}', 1, 'Concurrent return')`),
    runCmdAs(REV2_AUTH, `public.cmd_approve_inspection_v1('g11-race-app1', '${inspId}', '${subRes.revision_id}', 1, 'Concurrent approve')`)
  ]);
  const reviewOutcomes = [retRes.status, appRes.status].sort();
  const reviewRowCount = Number(
    await runPsql(`SELECT count(*) FROM public.review_events WHERE inspection_revision_id = '${subRes.revision_id}';`)
  );
  assert.equal(reviewRowCount, 1, `Expected exactly 1 terminal review_events row, got ${reviewRowCount}`);
  assert.ok(
    (reviewOutcomes[0] === "APPROVED" && reviewOutcomes[1] === "STATE_CONFLICT") ||
      (reviewOutcomes[0] === "RETURNED" && reviewOutcomes[1] === "STATE_CONFLICT"),
    `Expected 1 winner + 1 STATE_CONFLICT, got ${JSON.stringify([retRes, appRes])}`
  );
  console.log(`    PASS: Outcomes = ${JSON.stringify(reviewOutcomes)}, exactly 1 review_events row`);

  // Ensure inspection is APPROVED so we can run LG-21 print race!
  let approvedRevId = subRes.revision_id;
  if (retRes.status === "RETURNED") {
    const sub2 = await runCmdAs(winnerAuth, `public.cmd_submit_inspection_v1('g11-sub-0002', '${inspId}', 4, 'G11 resubmit')`);
    assert.equal(sub2.status, "SUBMITTED");
    const app2 = await runCmdAs(REV2_AUTH, `public.cmd_approve_inspection_v1('g11-app-0002', '${inspId}', '${sub2.revision_id}', 2, 'Final approve')`);
    assert.equal(app2.status, "APPROVED");
    approvedRevId = sub2.revision_id;
  }

  // =========================================================================
  // TEST 5: LG-21 — 6-Way Concurrent Monotonic Document Print Sequence Race
  // =========================================================================
  console.log("==> [LG-21] Running 6-way concurrent CMD-037 monotonic print sequence race...");
  const docRes = await runCmdAs(
    PO_AUTH,
    `public.cmd_generate_approved_document_v1('g11-doc-0001', 'INSPECTION_PDF', '${inspId}', '${approvedRevId}', '${TPL_ID}')`
  );
  assert.equal(docRes.status, "GENERATED");

  const printRaceResults = await Promise.all(
    Array.from({ length: 6 }, (_, idx) =>
      runCmdAs(
        PO_AUTH,
        `public.cmd_record_print_v1('g11-prt-race-${idx}', '${docRes.document_id}', 1, NULL, 'parallel-${idx}')`
      )
    )
  );
  const seqs = printRaceResults.map((r) => {
    assert.equal(r.status, "RECORDED", `Print race failure: ${JSON.stringify(r)}`);
    return r.sequence_no;
  }).sort((a, b) => a - b);
  assert.deepEqual(seqs, [1, 2, 3, 4, 5, 6], `Expected contiguous [1..6], got ${JSON.stringify(seqs)}`);
  console.log("    PASS: 6 concurrent prints yielded exact contiguous sequences [1, 2, 3, 4, 5, 6]");

  // =========================================================================
  // TEST 6: LG-41 — Idempotency Replay vs Tampered Payload Rejection
  // =========================================================================
  console.log("==> [LG-41] Verifying idempotency replay and key-reuse tampering guard...");
  const idem1 = await runCmdAs(SA_AUTH, `public.cmd_create_project_v1('g11-idem-same', 'G11-IDEM-P', 'Idem Project', 'Asia/Jakarta')`);
  assert.equal(idem1.status, "CREATED");
  const replays = await Promise.all([
    runCmdAs(SA_AUTH, `public.cmd_create_project_v1('g11-idem-same', 'G11-IDEM-P', 'Idem Project', 'Asia/Jakarta')`),
    runCmdAs(SA_AUTH, `public.cmd_create_project_v1('g11-idem-same', 'G11-IDEM-P', 'Idem Project', 'Asia/Jakarta')`)
  ]);
  for (const r of replays) {
    assert.equal(r.project_id, idem1.project_id, "Replay must return exact original project_id");
  }
  const tampered = await runCmdAs(SA_AUTH, `public.cmd_create_project_v1('g11-idem-same', 'G11-IDEM-P', 'Tampered Name', 'Asia/Jakarta')`);
  assert.equal(tampered.status, "IDEMPOTENCY_KEY_REUSED");
  console.log("    PASS: Concurrent replays returned identical project_id; tampered payload rejected with IDEMPOTENCY_KEY_REUSED");

  console.log("\nALL_G11_LOCAL_ADVERSARIAL_CONCURRENCY_TESTS_PASSED");
}

main().catch((err) => {
  console.error("G11 CONCURRENCY FAILED:", err);
  process.exit(1);
});
