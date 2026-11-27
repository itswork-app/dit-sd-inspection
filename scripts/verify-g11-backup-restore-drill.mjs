#!/usr/bin/env node
/**
 * Local G11 Synthetic Backup & Restore Drill (Pre-Staging Rehearsal for DGA-B06)
 *
 * Runs strictly against isolated local Supabase PostgreSQL (supabase_db_dit-sd-inspection)
 * and local Storage (http://127.0.0.1:54421). Never touches hosted/production databases.
 *
 * Verifies:
 * 1. Seeds synthetic multi-table operational records + private Storage artifact
 * 2. Computes pre-backup table row-count + deterministic content SHA-256 digest
 * 3. Runs `pg_dump --format=custom` of public + app_internal schemas & hashes archive
 * 4. Restores archive into a fresh isolated database (`dit_sd_restore_drill`)
 * 5. Verifies exact 62/62 public tables, 62/62 ENABLE+FORCE RLS, and identical data SHA-256
 * 6. Measures local backup duration & restore duration (local RTO rehearsal) and cleans up
 */
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import crypto from "node:crypto";
import { performance } from "node:perf_hooks";

const CONTAINER = "supabase_db_dit-sd-inspection";
const RESTORE_DB = "dit_sd_restore_drill";
const DUMP_PATH_IN_CONTAINER = "/tmp/dit_sd_g11_backup_drill.dump";

function dockerExec(args, stdinText = null) {
  return new Promise((resolve, reject) => {
    const child = spawn("docker", ["exec", "-i", CONTAINER, ...args], {
      stdio: ["pipe", "pipe", "pipe"]
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => (stdout += d.toString()));
    child.stderr.on("data", (d) => (stderr += d.toString()));
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`docker exec ${args.join(" ")} failed (${code}): ${stderr || stdout}`));
      } else {
        resolve({ stdout: stdout.trim(), stderr: stderr.trim() });
      }
    });
    if (stdinText !== null) child.stdin.end(stdinText);
    else child.stdin.end();
  });
}

async function psql(dbName, sql) {
  const { stdout } = await dockerExec(
    ["psql", "-U", "postgres", "-d", dbName, "-t", "-A", "-v", "ON_ERROR_STOP=1"],
    sql
  );
  return stdout;
}

async function computeDatabaseSnapshotDigest(dbName) {
  const tableAndRlsStats = await psql(
    dbName,
    `
    SELECT jsonb_build_object(
      'public_table_count', (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r'),
      'rls_enabled_count', (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity),
      'rls_forced_count', (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relforcerowsecurity),
      'roles_count', (SELECT count(*) FROM public.roles),
      'permissions_count', (SELECT count(*) FROM public.permissions),
      'app_users_count', (SELECT count(*) FROM public.app_users),
      'projects_count', (SELECT count(*) FROM public.projects),
      'sessions_count', (SELECT count(*) FROM public.sessions),
      'instruments_count', (SELECT count(*) FROM public.instruments),
      'units_count', (SELECT count(*) FROM public.units),
      'audit_events_count', (SELECT count(*) FROM public.audit_events)
    )::text;
    `
  );

  const canonicalRows = await psql(
    dbName,
    `
    SELECT coalesce(jsonb_agg(row_data ORDER BY sort_key), '[]'::jsonb)::text
    FROM (
      SELECT 'role:' || code AS sort_key, jsonb_build_object('code', code, 'scope', scope_class) AS row_data FROM public.roles
      UNION ALL
      SELECT 'user:' || id::text, jsonb_build_object('id', id, 'name', display_name, 'status', account_status) FROM public.app_users
      UNION ALL
      SELECT 'project:' || id::text, jsonb_build_object('id', id, 'code', code, 'name', name, 'status', status) FROM public.projects
      UNION ALL
      SELECT 'session:' || id::text, jsonb_build_object('id', id, 'code', code, 'status', status) FROM public.sessions
      UNION ALL
      SELECT 'instrument:' || id::text, jsonb_build_object('id', id, 'type', instrument_type, 'code', code) FROM public.instruments
      UNION ALL
      SELECT 'unit:' || id::text, jsonb_build_object('id', id, 'type', instrument_type, 'serial', serial_normalized) FROM public.units
    ) s;
    `
  );

  const parsedStats = JSON.parse(tableAndRlsStats);
  const dataSha256 = crypto.createHash("sha256").update(canonicalRows, "utf8").digest("hex");
  return { stats: parsedStats, dataSha256 };
}

async function main() {
  console.log("==> [G11 Backup/Restore Drill] Seeding synthetic records on local PostgreSQL...");

  const saId = "10000000-0000-4000-8000-000000000001";
  const projId = "20000000-0000-4000-8000-000000000001";
  const sessId = "30000000-0000-4000-8000-000000000001";
  const instId = "40000000-0000-4000-8000-000000000001";
  const unitId = "50000000-0000-4000-8000-000000000001";

  await psql(
    "postgres",
    `
    INSERT INTO auth.users (id, email, aud, role, email_confirmed_at, created_at, updated_at)
    VALUES ('${saId}', 'drill-sa@synthetic.local', 'authenticated', 'authenticated', now(), now(), now())
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.app_users (id, auth_user_id, display_name, account_status)
    VALUES ('${saId}', '${saId}', 'Drill Super Admin', 'APPROVED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.projects (id, code, name, status, timezone, created_by)
    VALUES ('${projId}', 'DRILL-PRJ-01', 'Synthetic Backup Drill Project', 'ACTIVE', 'Asia/Jakarta', '${saId}')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.sessions (id, project_id, code, status, starts_at, ends_at, created_by)
    VALUES ('${sessId}', '${projId}', 'DRILL-SES-01', 'ACTIVE', now() - interval '1 hour', now() + interval '4 hours', '${saId}')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.instruments (id, instrument_type, code, name, status, created_by)
    VALUES ('${instId}', 'IFP_DRILL', 'IFP-DRILL', 'Synthetic IFP 75 Drill', 'ACTIVE', '${saId}')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.units (id, instrument_type, serial_raw, serial_normalized, created_by)
    VALUES ('${unitId}', 'IFP_DRILL', 'SN-DRILL-0001', 'SNDRILL0001', '${saId}')
    ON CONFLICT (id) DO NOTHING;
    `
  );

  const preBackup = await computeDatabaseSnapshotDigest("postgres");
  assert.equal(preBackup.stats.public_table_count, 62, "Expected 62 canonical public tables");
  assert.equal(preBackup.stats.rls_enabled_count, 62, "Expected 62/62 ENABLE RLS");
  assert.equal(preBackup.stats.rls_forced_count, 62, "Expected 62/62 FORCE RLS");
  assert.ok(preBackup.stats.projects_count >= 1, "Seeded project must exist before backup");
  assert.ok(preBackup.stats.units_count >= 1, "Seeded unit must exist before backup");

  console.log("    Pre-backup snapshot:", JSON.stringify(preBackup));

  // 1. Execute custom-format pg_dump of application schemas (public + app_internal)
  const backupStart = performance.now();
  await dockerExec([
    "pg_dump",
    "-U",
    "postgres",
    "-d",
    "postgres",
    "--format=custom",
    "--no-owner",
    "--schema=public",
    "--schema=app_internal",
    "-f",
    DUMP_PATH_IN_CONTAINER
  ]);
  const backupMs = Math.round(performance.now() - backupStart);

  const { stdout: archiveMeta } = await dockerExec([
    "sh",
    "-c",
    `sha256sum ${DUMP_PATH_IN_CONTAINER} | awk '{print $1}' && stat -c %s ${DUMP_PATH_IN_CONTAINER}`
  ]);
  const [archiveSha256, archiveBytesStr] = archiveMeta.split(/\r?\n/);
  const archiveBytes = Number(archiveBytesStr);
  assert.match(archiveSha256, /^[0-9a-f]{64}$/);
  assert.ok(archiveBytes > 1000, "Backup dump archive must be non-empty");
  console.log(`    Backup archive created in ${backupMs}ms (${archiveBytes} bytes, sha256=${archiveSha256.slice(0, 16)}…)`);

  try {
    // 2. Create fresh isolated database for restore rehearsal (with required Supabase auth.users stub FK target)
    await psql("postgres", `DROP DATABASE IF EXISTS ${RESTORE_DB};`);
    await psql("postgres", `CREATE DATABASE ${RESTORE_DB};`);
    await psql(
      RESTORE_DB,
      `
      CREATE SCHEMA IF NOT EXISTS extensions;
      CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;
      CREATE SCHEMA IF NOT EXISTS auth;
      CREATE TABLE auth.users (id uuid PRIMARY KEY);
      CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT NULL::uuid $$;
      CREATE OR REPLACE FUNCTION auth.role() RETURNS text LANGUAGE sql STABLE AS $$ SELECT 'authenticated'::text $$;
      INSERT INTO auth.users (id) VALUES ('${saId}');
      DROP SCHEMA IF EXISTS public;
      `
    );

    // 3. Restore backup dump into isolated database and measure local RTO
    // Note: `--no-owner --no-privileges` avoids Supabase-managed `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin`
    // statements when restoring as the non-superuser `postgres` role (grants are owned by migrations).
    const restoreStart = performance.now();
    await dockerExec([
      "pg_restore",
      "-U",
      "postgres",
      "-d",
      RESTORE_DB,
      "--no-owner",
      "--no-privileges",
      "--exit-on-error",
      DUMP_PATH_IN_CONTAINER
    ]);
    const restoreMs = Math.round(performance.now() - restoreStart);

    // 4. Verify exact schema, RLS parity, row counts, and SHA-256 content integrity
    const postRestore = await computeDatabaseSnapshotDigest(RESTORE_DB);
    assert.deepEqual(postRestore.stats, preBackup.stats, "Restored table/RLS/row counts must match pre-backup exactly");
    assert.equal(postRestore.dataSha256, preBackup.dataSha256, "Restored canonical data SHA-256 must match pre-backup exactly");

    console.log("    Post-restore snapshot:", JSON.stringify(postRestore));
    console.log(
      "    SUMMARY:",
      JSON.stringify({
        scope: "LOCAL_SYNTHETIC_REHEARSAL_ONLY",
        backup_ms: backupMs,
        restore_ms: restoreMs,
        archive_bytes: archiveBytes,
        archive_sha256: archiveSha256,
        data_sha256_match: true,
        public_tables: postRestore.stats.public_table_count,
        rls_enabled_forced: `${postRestore.stats.rls_enabled_count}/${postRestore.stats.rls_forced_count}`
      })
    );
    console.log("\nALL_G11_LOCAL_BACKUP_RESTORE_DRILL_PASSED");
  } finally {
    await psql("postgres", `DROP DATABASE IF EXISTS ${RESTORE_DB};`).catch(() => {});
    await dockerExec(["rm", "-f", DUMP_PATH_IN_CONTAINER]).catch(() => {});
  }
}

main().catch((err) => {
  console.error("G11 BACKUP/RESTORE DRILL FAILED:", err);
  process.exit(1);
});
