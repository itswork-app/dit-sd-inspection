-- Synthetic local PostgreSQL verification suite for Slice 2 (I2/I3):
-- Projects, Sessions (T-07), Assignments & Cross-Location Overlap, Inspector Capacity (T-14),
-- Target Plans, Extensible Instruments (CFG-001 / T-17), and Canonical Units/Associations/Conflicts (T-16).
-- Runs inside a rolled-back transaction so local DB remains clean after verification.

\set ON_ERROR_STOP on

BEGIN;

-- 1. pg_catalog T-18 + RLS assertions across all 29 I1/I2/I3 tables & 28 cmd_*_v1 functions
DO $$
DECLARE
  v_bad_funcs int;
  v_public_exec int;
  v_anon_exec int;
  v_rls_missing int;
  v_cmd_count int;
BEGIN
  IF has_schema_privilege('app_cmd_definer', 'public', 'CREATE')
     OR has_schema_privilege('app_cmd_definer', 'app_internal', 'CREATE') THEN
    RAISE EXCEPTION 'T-18 FAIL: app_cmd_definer retained runtime CREATE privilege';
  END IF;

  SELECT count(*) INTO v_cmd_count
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1';
  IF v_cmd_count < 28 THEN
    RAISE EXCEPTION 'CATALOG FAIL: expected >= 28 cmd_*_v1 functions, got %', v_cmd_count;
  END IF;

  SELECT count(*) INTO v_bad_funcs
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_roles r ON r.oid = p.proowner
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1'
    AND (NOT p.prosecdef OR r.rolname <> 'app_cmd_definer' OR NOT (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']));
  IF v_bad_funcs <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: % cmd_*_v1 function(s) violate security invariants', v_bad_funcs;
  END IF;

  SELECT count(*) INTO v_public_exec
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1' AND has_function_privilege('public', p.oid, 'EXECUTE');
  SELECT count(*) INTO v_anon_exec
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1' AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_public_exec <> 0 OR v_anon_exec <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: PUBLIC/anon can execute cmd_*_v1';
  END IF;

  SELECT count(*) INTO v_rls_missing
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r'
    AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity);
  IF v_rls_missing <> 0 THEN
    RAISE EXCEPTION 'RLS FAIL: % public table(s) missing ENABLE/FORCE RLS', v_rls_missing;
  END IF;
END
$$;

-- 2. Seed synthetic auth.users + app_users (Super Admin, Korlap, Inspector1, Inspector2, Outsider)
INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES
  ('10000001-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sa@example.test', '{}', '{}', now(), now()),
  ('10000002-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'korlap@example.test', '{}', '{}', now(), now()),
  ('10000003-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'insp1@example.test', '{}', '{}', now(), now()),
  ('10000004-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'insp2@example.test', '{}', '{}', now(), now()),
  ('10000005-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'outsider@example.test', '{}', '{}', now(), now());

INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
VALUES
  ('20000001-0000-4000-8000-000000000001', '10000001-0000-4000-8000-000000000001', 'Synthetic SA', 'APPROVED', 1),
  ('20000002-0000-4000-8000-000000000002', '10000002-0000-4000-8000-000000000002', 'Synthetic Korlap', 'APPROVED', 1),
  ('20000003-0000-4000-8000-000000000003', '10000003-0000-4000-8000-000000000003', 'Synthetic Inspector 1', 'APPROVED', 1),
  ('20000004-0000-4000-8000-000000000004', '10000004-0000-4000-8000-000000000004', 'Synthetic Inspector 2', 'APPROVED', 1),
  ('20000005-0000-4000-8000-000000000005', '10000005-0000-4000-8000-000000000005', 'Synthetic Outsider', 'APPROVED', 1);

INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
SELECT '20000001-0000-4000-8000-000000000001', r.id, NULL, 'ACTIVE', '20000002-0000-4000-8000-000000000002', 'Synthetic bootstrap SA'
FROM public.roles r WHERE r.code = 'super_admin';

-- 3. End-to-end verification as authenticated callers
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000001-0000-4000-8000-000000000001';

DO $$
DECLARE
  v_res jsonb;
  v_proj1_id uuid;
  v_proj2_id uuid;
  v_loc1_id uuid;
  v_loc2_id uuid;
  v_team1_id uuid;
  v_sess1_id uuid;
  v_inst_id uuid;
  v_inst2_id uuid;
  v_ver1_id uuid;
  v_draft_hash text;
  v_assign1_id uuid;
  v_plan_id uuid;
  v_unit1_id uuid;
  v_assoc1_id uuid;
  v_conflict_id uuid;
  v_denied boolean := false;
BEGIN
  -- Direct DML must fail
  BEGIN
    INSERT INTO public.projects (code, name, timezone, created_by)
    VALUES ('HACK', 'Direct Insert', 'Asia/Jakarta', '20000001-0000-4000-8000-000000000001');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'SECURITY FAIL: authenticated inserted directly into projects';
  END IF;

  -- CMD-008: Create two projects + locations + team
  v_res := public.cmd_create_project_v1('idem-p1-0001', 'PRJ-IFP-2026', 'Synthetic IFP Project A', 'Asia/Jakarta');
  IF v_res->>'status' <> 'CREATED' OR v_res->>'inspector_cap' <> '50' THEN
    RAISE EXCEPTION 'CMD-008 P1 FAIL: %', v_res;
  END IF;
  v_proj1_id := (v_res->>'project_id')::uuid;

  -- Duplicate code rejected
  v_res := public.cmd_create_project_v1('idem-p1-dup1', 'PRJ-IFP-2026', 'Dup', 'Asia/Jakarta');
  IF v_res->>'status' <> 'DUPLICATE_CODE' THEN
    RAISE EXCEPTION 'CMD-008 DUP FAIL: %', v_res;
  END IF;

  v_res := public.cmd_create_project_v1('idem-p2-0001', 'PRJ-IFP-2026-B', 'Synthetic IFP Project B', 'Asia/Jakarta');
  v_proj2_id := (v_res->>'project_id')::uuid;

  -- CMD-009: Update project with CAS check
  v_res := public.cmd_update_project_v1('idem-p1-upd-stale', v_proj1_id, 99, 'Stale', NULL);
  IF v_res->>'status' <> 'STALE_VERSION' THEN
    RAISE EXCEPTION 'CMD-009 STALE FAIL: %', v_res;
  END IF;
  v_res := public.cmd_update_project_v1('idem-p1-upd-01', v_proj1_id, 1, 'Synthetic IFP Project A Updated', NULL);
  IF v_res->>'status' <> 'UPDATED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-009 UPDATE FAIL: %', v_res;
  END IF;

  -- Locations & Team
  v_res := public.cmd_create_location_v1('idem-loc1-01', v_proj1_id, 'LOC-A', 'Warehouse Alpha');
  v_loc1_id := (v_res->>'location_id')::uuid;
  v_res := public.cmd_create_location_v1('idem-loc2-01', v_proj1_id, 'LOC-B', 'Warehouse Beta');
  v_loc2_id := (v_res->>'location_id')::uuid;
  v_res := public.cmd_create_team_v1('idem-team1-01', v_proj1_id, 'TEAM-1', 'Inspection Team 1');
  v_team1_id := (v_res->>'team_id')::uuid;

  -- Grant project roles (korlap, inspector1, inspector2 in P1; inspector1 in P2; korlap in P2)
  PERFORM public.cmd_grant_role_v1('idem-gr-kor1', '20000002-0000-4000-8000-000000000002', 'korlap', v_proj1_id, now(), NULL, 'Korlap P1');
  PERFORM public.cmd_grant_role_v1('idem-gr-ins1', '20000003-0000-4000-8000-000000000003', 'inspector', v_proj1_id, now(), NULL, 'Inspector 1 P1');
  PERFORM public.cmd_grant_role_v1('idem-gr-ins2', '20000004-0000-4000-8000-000000000004', 'inspector', v_proj1_id, now(), NULL, 'Inspector 2 P1');
  PERFORM public.cmd_grant_role_v1('idem-gr-ins1p2', '20000003-0000-4000-8000-000000000003', 'inspector', v_proj2_id, now(), NULL, 'Inspector 1 P2');
  PERFORM public.cmd_grant_role_v1('idem-gr-adm2', '20000002-0000-4000-8000-000000000002', 'admin', v_proj2_id, now(), NULL, 'Admin P2');

  -- CMD-018/019/020: Create IFP instrument, save draft, publish (T-17)
  v_res := public.cmd_create_instrument_v1('idem-inst-01', 'IFP_75', 'IFP-75-STD', 'Interactive Flat Panel 75"', 'Synthetic IFP spec', true);
  IF v_res->>'status' <> 'CREATED' OR v_res->>'instrument_status' <> 'DRAFT' THEN
    RAISE EXCEPTION 'CMD-018 FAIL: %', v_res;
  END IF;
  v_inst_id := (v_res->>'instrument_id')::uuid;

  v_res := public.cmd_create_instrument_v1('idem-inst-02', 'STANDING_BRACKET', 'SB-STD', 'Standing Bracket', 'Different instrument type', true);
  v_inst2_id := (v_res->>'instrument_id')::uuid;

  -- Save draft config (sections, items, spec_fields, evidence_slots)
  v_res := public.cmd_save_instrument_draft_v1(
    'idem-drft-01',
    v_inst_id,
    NULL,
    '1.0',
    '[{"code":"SEC_PHYS","label":"Physical Check","items":[{"code":"ITEM_SCREEN","label":"Screen intact","answer_type":"PASS_FAIL","required":true}]}]'::jsonb,
    '[{"code":"SPEC_DIAG","label":"Diagonal Size","value_type":"INTEGER","expected_value":"75","unit":"inch","required":true}]'::jsonb,
    '[{"code":"EV_FRONT","label":"Front Panel Photo","required":true,"allowed_media_types":["image/jpeg","image/png"]}]'::jsonb
  );
  IF v_res->>'status' <> 'SAVED' THEN
    RAISE EXCEPTION 'CMD-019 FAIL: %', v_res;
  END IF;
  v_ver1_id := (v_res->>'version_id')::uuid;
  v_draft_hash := v_res->>'draft_hash';

  -- Publish with wrong draft hash fails STALE_DRAFT
  v_res := public.cmd_publish_instrument_version_v1('idem-pub-stale', v_inst_id, v_ver1_id, repeat('0', 64), 'Bad hash');
  IF v_res->>'status' <> 'STALE_DRAFT' THEN
    RAISE EXCEPTION 'CMD-020 STALE_DRAFT FAIL: %', v_res;
  END IF;

  -- Valid publish succeeds and activates instrument
  v_res := public.cmd_publish_instrument_version_v1('idem-pub-01', v_inst_id, v_ver1_id, v_draft_hash, 'Initial synthetic IFP v1');
  IF v_res->>'status' <> 'PUBLISHED' OR v_res->>'instrument_status' <> 'ACTIVE' THEN
    RAISE EXCEPTION 'CMD-020 PUBLISH FAIL: %', v_res;
  END IF;

  -- Attempting to edit published version must fail PUBLISHED_IMMUTABLE
  v_res := public.cmd_save_instrument_draft_v1('idem-drft-imm', v_inst_id, v_ver1_id, '1.0', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb);
  IF v_res->>'status' <> 'PUBLISHED_IMMUTABLE' THEN
    RAISE EXCEPTION 'CMD-019 IMMUTABILITY FAIL: %', v_res;
  END IF;

  -- Also publish Standing Bracket v1 so we can test same serial across different instrument_types (T-16)
  v_res := public.cmd_save_instrument_draft_v1(
    'idem-drft-sb', v_inst2_id, NULL, '1.0',
    '[{"code":"SEC_FRAME","label":"Frame","items":[{"code":"ITEM_BOLT","label":"Bolts complete","answer_type":"PASS_FAIL","required":true}]}]'::jsonb,
    '[]'::jsonb, '[]'::jsonb
  );
  v_res := public.cmd_publish_instrument_version_v1('idem-pub-sb', v_inst2_id, (v_res->>'version_id')::uuid, v_res->>'draft_hash', 'Initial SB v1');
  IF v_res->>'status' <> 'PUBLISHED' THEN
    RAISE EXCEPTION 'CMD-020 SB PUBLISH FAIL: %', v_res;
  END IF;

  -- CMD-011/012/013: Session lifecycle (DRAFT -> ACTIVATE -> PAUSE -> RESUME -> REQUEST_CLOSE)
  v_res := public.cmd_create_session_v1('idem-s1-01', v_proj1_id, 'SESS-01', now(), now() + interval '8 hours');
  IF v_res->>'status' <> 'CREATED' OR v_res->>'session_status' <> 'DRAFT' THEN
    RAISE EXCEPTION 'CMD-011 FAIL: %', v_res;
  END IF;
  v_sess1_id := (v_res->>'session_id')::uuid;

  -- Update session schedule before assignments exist
  v_res := public.cmd_update_session_v1('idem-s1-upd', v_sess1_id, 1, now(), now() + interval '10 hours', 'Extended window');
  IF v_res->>'status' <> 'UPDATED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-012 FAIL: %', v_res;
  END IF;

  -- Switch to Korlap: can ACTIVATE and REQUEST_CLOSE, CANNOT final CLOSE!
  PERFORM set_config('request.jwt.claim.sub', '10000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_transition_session_v1('idem-s1-act', v_sess1_id, 'ACTIVATE', 2, 'Field start');
  IF v_res->>'status' <> 'TRANSITIONED' OR v_res->>'session_status' <> 'ACTIVE' THEN
    RAISE EXCEPTION 'CMD-013 KORLAP ACTIVATE FAIL: %', v_res;
  END IF;

  v_res := public.cmd_transition_session_v1('idem-s1-kclose', v_sess1_id, 'CLOSE', 3, 'Korlap trying final close');
  IF v_res->>'status' <> 'PERMISSION_DENIED' THEN
    RAISE EXCEPTION 'CMD-013 KORLAP CLOSE CEILING FAIL: %', v_res;
  END IF;

  v_res := public.cmd_transition_session_v1('idem-s1-reqc', v_sess1_id, 'REQUEST_CLOSE', 3, 'Requesting SA closure');
  IF v_res->>'status' <> 'TRANSITIONED' OR v_res->>'session_status' <> 'ACTIVE' THEN
    RAISE EXCEPTION 'CMD-013 REQUEST_CLOSE FAIL (must keep ACTIVE state): %', v_res;
  END IF;

  -- Switch back to Super Admin
  PERFORM set_config('request.jwt.claim.sub', '10000001-0000-4000-8000-000000000001', true);

  -- CMD-016: Lower cap to 1 before publishing assignment with 1 inspector
  v_res := public.cmd_change_inspector_capacity_v1('idem-cap-1', v_proj1_id, 1, 1, 'Tight synthetic cap for T-14 test');
  IF v_res->>'status' <> 'UPDATED' OR v_res->>'inspector_cap' <> '1' THEN
    RAISE EXCEPTION 'CMD-016 SET CAP=1 FAIL: %', v_res;
  END IF;

  -- CMD-014: Publish assignment at LOC-A with Inspector 1 (succeeds: count=1 <= cap=1)
  v_res := public.cmd_publish_assignment_v1(
    'idem-asgn-01', v_proj1_id, v_sess1_id, v_loc1_id, v_inst_id, v_ver1_id, v_team1_id,
    now(), now() + interval '4 hours',
    '[{"user_id":"20000003-0000-4000-8000-000000000003","operational_role":"inspector"}]'::jsonb
  );
  IF v_res->>'status' <> 'PUBLISHED' OR v_res->>'qualifying_inspectors' <> '1' THEN
    RAISE EXCEPTION 'CMD-014 PUBLISH FAIL: %', v_res;
  END IF;
  v_assign1_id := (v_res->>'assignment_id')::uuid;

  -- CMD-014: Cross-location overlapping assignment for Inspector 1 at LOC-B MUST FAIL ASSIGNMENT_OVERLAP!
  v_res := public.cmd_publish_assignment_v1(
    'idem-asgn-ovlp', v_proj1_id, v_sess1_id, v_loc2_id, v_inst_id, v_ver1_id, v_team1_id,
    now() + interval '1 hour', now() + interval '3 hours',
    '[{"user_id":"20000003-0000-4000-8000-000000000003","operational_role":"inspector"}]'::jsonb
  );
  IF v_res->>'status' <> 'ASSIGNMENT_OVERLAP' THEN
    RAISE EXCEPTION 'CMD-014 OVERLAP FAIL: %', v_res;
  END IF;

  -- CMD-015: Adding Inspector 2 while cap=1 MUST FAIL CAPACITY_EXCEEDED!
  v_res := public.cmd_change_assignment_members_v1(
    'idem-mem-cap', v_assign1_id,
    '[{"user_id":"20000004-0000-4000-8000-000000000004","operational_role":"inspector"}]'::jsonb,
    ARRAY[]::uuid[],
    'Exceeds T-14 cap of 1'
  );
  IF v_res->>'status' <> 'CAPACITY_EXCEEDED' THEN
    RAISE EXCEPTION 'CMD-015 T-14 CAP FAIL: %', v_res;
  END IF;

  -- Raise cap to 2, add Inspector 2 (succeeds), then try lowering cap back to 1 (MUST FAIL CAPACITY_BELOW_CURRENT_COUNT!)
  v_res := public.cmd_change_inspector_capacity_v1('idem-cap-2', v_proj1_id, 2, 2, 'Raise cap to 2');
  IF v_res->>'status' <> 'UPDATED' THEN
    RAISE EXCEPTION 'CMD-016 CAP=2 FAIL: %', v_res;
  END IF;

  v_res := public.cmd_change_assignment_members_v1(
    'idem-mem-add2', v_assign1_id,
    '[{"user_id":"20000004-0000-4000-8000-000000000004","operational_role":"inspector"}]'::jsonb,
    ARRAY[]::uuid[],
    'Add second inspector under cap 2'
  );
  IF v_res->>'status' <> 'UPDATED' OR v_res->>'qualifying_inspectors' <> '2' THEN
    RAISE EXCEPTION 'CMD-015 ADD2 FAIL: %', v_res;
  END IF;

  v_res := public.cmd_change_inspector_capacity_v1('idem-cap-low', v_proj1_id, 1, 3, 'Try reducing below count 2');
  IF v_res->>'status' <> 'CAPACITY_BELOW_CURRENT_COUNT' THEN
    RAISE EXCEPTION 'CMD-016 BELOW_COUNT FAIL: %', v_res;
  END IF;

  -- CMD-017: Target plan draft -> allocate -> publish -> reject mutation of published plan
  v_res := public.cmd_manage_target_plan_v1('idem-tp-cr', v_sess1_id, 'CREATE_DRAFT', NULL, NULL, '[]'::jsonb);
  IF v_res->>'status' <> 'DRAFTED' THEN
    RAISE EXCEPTION 'CMD-017 DRAFT FAIL: %', v_res;
  END IF;
  v_plan_id := (v_res->>'plan_id')::uuid;

  v_res := public.cmd_manage_target_plan_v1(
    'idem-tp-alloc', v_sess1_id, 'REPLACE_DRAFT_ALLOCATIONS', v_plan_id, 1,
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('assignment_id', v_assign1_id, 'target_date', '2026-11-27', 'quantity', 25))
  );
  IF v_res->>'status' <> 'UPDATED' THEN
    RAISE EXCEPTION 'CMD-017 ALLOC FAIL: %', v_res;
  END IF;

  v_res := public.cmd_manage_target_plan_v1('idem-tp-pub', v_sess1_id, 'PUBLISH', v_plan_id, 2, '[]'::jsonb);
  IF v_res->>'status' <> 'PUBLISHED' THEN
    RAISE EXCEPTION 'CMD-017 PUBLISH FAIL: %', v_res;
  END IF;

  v_res := public.cmd_manage_target_plan_v1('idem-tp-mut', v_sess1_id, 'REPLACE_DRAFT_ALLOCATIONS', v_plan_id, 3, '[]'::jsonb);
  IF v_res->>'status' <> 'IMMUTABLE' THEN
    RAISE EXCEPTION 'CMD-017 IMMUTABLE FAIL: %', v_res;
  END IF;

  -- CMD-022 / 023 / 024 / 025: T-16 Canonical Unit, Cross-Type Same Serial, Cross-Project Conflict & Resolution
  PERFORM set_config('request.jwt.claim.sub', '10000003-0000-4000-8000-000000000003', true); -- Inspector 1
  v_res := public.cmd_register_canonical_unit_v1('idem-u1-p1', v_proj1_id, v_inst_id, '  sn-ifp-0001  ', '{"batch":"B1"}'::jsonb);
  IF v_res->>'status' <> 'REGISTERED' OR v_res->>'serial_normalized' <> 'SN-IFP-0001' THEN
    RAISE EXCEPTION 'CMD-022 REG FAIL: %', v_res;
  END IF;
  v_unit1_id := (v_res->>'unit_id')::uuid;
  v_assoc1_id := (v_res->>'association_id')::uuid;

  -- Same serial under DIFFERENT instrument_type (STANDING_BRACKET) MUST SUCCEED as distinct canonical unit (T-16)!
  v_res := public.cmd_register_canonical_unit_v1('idem-u1-sb', v_proj1_id, v_inst2_id, 'SN-IFP-0001', '{}'::jsonb);
  IF v_res->>'status' <> 'REGISTERED' OR (v_res->>'unit_id')::uuid = v_unit1_id THEN
    RAISE EXCEPTION 'CMD-022 DIFFERENT INSTRUMENT TYPE FAIL: %', v_res;
  END IF;

  -- Same serial under SAME instrument_type in Project 2 MUST OPEN CONFLICT (never clone, never leak P1)!
  v_res := public.cmd_register_canonical_unit_v1('idem-u1-p2', v_proj2_id, v_inst_id, 'sn-ifp-0001', '{}'::jsonb);
  IF v_res->>'status' <> 'CONFLICT_REVIEW_REQUIRED' OR v_res ? 'unit_id' THEN
    RAISE EXCEPTION 'CMD-022 CROSS-PROJECT CONFLICT FAIL (or leaked unit_id): %', v_res;
  END IF;
  v_conflict_id := (v_res->>'conflict_id')::uuid;

  -- Admin P2 resolves conflict by associating existing canonical unit (no second unit cloned!)
  PERFORM set_config('request.jwt.claim.sub', '10000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_resolve_unit_identity_conflict_v1('idem-c-res', v_conflict_id, 'ASSOCIATE_EXISTING', 1, 'Verified physical serial transfer to P2', v_unit1_id);
  IF v_res->>'status' <> 'RESOLVED' OR (v_res->>'unit_id')::uuid <> v_unit1_id THEN
    RAISE EXCEPTION 'CMD-025 RESOLVE FAIL: %', v_res;
  END IF;

  -- End association in P2 (CMD-024)
  v_res := public.cmd_end_unit_project_association_v1('idem-end-a2', (v_res->>'association_id')::uuid, 'ENDED', 1, 'Unit returned from Project B');
  IF v_res->>'status' <> 'ENDED' THEN
    RAISE EXCEPTION 'CMD-024 END FAIL: %', v_res;
  END IF;

  -- Outsider without project access sees ZERO projects, ZERO units, ZERO conflicts via RLS
  PERFORM set_config('request.jwt.claim.sub', '10000005-0000-4000-8000-000000000005', true);
  IF (SELECT count(*) FROM public.projects) <> 0
     OR (SELECT count(*) FROM public.units) <> 0
     OR (SELECT count(*) FROM public.unit_identity_conflicts) <> 0
  THEN
    RAISE EXCEPTION 'RLS PROJECT ISOLATION FAIL: outsider saw scoped domain rows';
  END IF;

  -- Switch to Super Admin: test CMD-021 deactivate instrument + CMD-010 project closure fence (blocked while session open, succeeds after session CLOSED)
  PERFORM set_config('request.jwt.claim.sub', '10000001-0000-4000-8000-000000000001', true);
  v_res := public.cmd_deactivate_instrument_v1('idem-deact-1', v_inst_id, 2, 'Retiring synthetic IFP for future use');
  IF v_res->>'status' <> 'DEACTIVATED' THEN
    RAISE EXCEPTION 'CMD-021 DEACTIVATE FAIL: %', v_res;
  END IF;

  -- Project closure blocked while session is still ACTIVE
  v_res := public.cmd_close_project_v1('idem-p1-cls-blk', v_proj1_id, 2, 'Premature closure attempt');
  IF v_res->>'status' <> 'CLOSURE_BLOCKED' THEN
    RAISE EXCEPTION 'CMD-010 CLOSURE_BLOCKED FAIL: %', v_res;
  END IF;

  -- Close session then close project
  v_res := public.cmd_transition_session_v1('idem-s1-close', v_sess1_id, 'CLOSE', 4, 'Session complete');
  IF v_res->>'status' <> 'TRANSITIONED' OR v_res->>'session_status' <> 'CLOSED' THEN
    RAISE EXCEPTION 'CMD-013 SA CLOSE FAIL: %', v_res;
  END IF;

  v_res := public.cmd_close_project_v1('idem-p1-cls-ok', v_proj1_id, 2, 'All sessions closed cleanly');
  IF v_res->>'status' <> 'CLOSED' THEN
    RAISE EXCEPTION 'CMD-010 CLOSE FAIL: %', v_res;
  END IF;
END
$$;

SELECT 'ALL_SLICE2_I2_I3_POSTGRESQL_DOMAIN_SECURITY_ASSERTIONS_PASSED' AS verification_result;

ROLLBACK;
