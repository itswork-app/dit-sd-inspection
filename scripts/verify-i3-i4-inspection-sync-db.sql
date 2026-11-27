-- Synthetic local PostgreSQL verification suite for Slice 3 (I3/I4):
-- Claims (CMD-026/027), Draft Context (CMD-028), Immutable Revisions (CMD-029),
-- Reviewer Return/Approve + SoD (CMD-030/031), Reopen (CMD-032),
-- Packed-Unit Abort SES-001 (CMD-055/056), Evidence Intents/Confirm (CMD-033/034),
-- and Offline Draft Sync Conflict Preservation (CMD-035).
-- Runs inside a rolled-back transaction so local DB remains clean.

\set ON_ERROR_STOP on

BEGIN;

-- 1. pg_catalog T-18 + RLS assertions across all 43 public tables & 41 cmd_*_v1 functions
DO $$
DECLARE
  v_cmd_count int;
  v_bad_funcs int;
  v_rls_missing int;
BEGIN
  IF has_schema_privilege('app_cmd_definer', 'public', 'CREATE')
     OR has_schema_privilege('app_cmd_definer', 'app_internal', 'CREATE') THEN
    RAISE EXCEPTION 'T-18 FAIL: app_cmd_definer retained runtime CREATE privilege';
  END IF;

  SELECT count(*) INTO v_cmd_count
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1';
  IF v_cmd_count <> 41 THEN
    RAISE EXCEPTION 'CATALOG FAIL: expected 41 cmd_*_v1 functions (28 prior + 13 Slice 3), got %', v_cmd_count;
  END IF;

  SELECT count(*) INTO v_bad_funcs
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace JOIN pg_roles r ON r.oid = p.proowner
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1'
    AND (NOT p.prosecdef OR r.rolname <> 'app_cmd_definer' OR NOT (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']));
  IF v_bad_funcs <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: % cmd_*_v1 function(s) violate security invariants', v_bad_funcs;
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

-- 2. Seed synthetic users (Super Admin, Inspector1, Inspector2, Reviewer1, Korlap1)
INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES
  ('30000001-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sa3@example.test', '{}', '{}', now(), now()),
  ('30000002-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'insp1_3@example.test', '{}', '{}', now(), now()),
  ('30000003-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'insp2_3@example.test', '{}', '{}', now(), now()),
  ('30000004-0000-4000-8000-000000000004', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'rev1_3@example.test', '{}', '{}', now(), now()),
  ('30000005-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'kor1_3@example.test', '{}', '{}', now(), now());

INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
VALUES
  ('40000001-0000-4000-8000-000000000001', '30000001-0000-4000-8000-000000000001', 'SA Slice3', 'APPROVED', 1),
  ('40000002-0000-4000-8000-000000000002', '30000002-0000-4000-8000-000000000002', 'Inspector 1', 'APPROVED', 1),
  ('40000003-0000-4000-8000-000000000003', '30000003-0000-4000-8000-000000000003', 'Inspector 2', 'APPROVED', 1),
  ('40000004-0000-4000-8000-000000000004', '30000004-0000-4000-8000-000000000004', 'Reviewer 1', 'APPROVED', 1),
  ('40000005-0000-4000-8000-000000000005', '30000005-0000-4000-8000-000000000005', 'Korlap 1', 'APPROVED', 1);

INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
SELECT '40000001-0000-4000-8000-000000000001', r.id, NULL, 'ACTIVE', '40000005-0000-4000-8000-000000000005', 'Bootstrap SA'
FROM public.roles r WHERE r.code = 'super_admin';

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '30000001-0000-4000-8000-000000000001';

DO $$
DECLARE
  v_res jsonb;
  v_proj_id uuid;
  v_loc_id uuid;
  v_team_id uuid;
  v_sess_id uuid;
  v_inst_id uuid;
  v_ver_id uuid;
  v_assign_id uuid;
  v_item_id uuid;
  v_spec_id uuid;
  v_slot_id uuid;
  v_unit_id uuid;
  v_assoc_id uuid;
  v_claim_id uuid;
  v_insp_id uuid;
  v_ev_id uuid;
  v_rev1_id uuid;
  v_rev2_id uuid;
  v_dev_id uuid;
  v_unit2_id uuid;
  v_assoc2_id uuid;
  v_insp2_id uuid;
  v_abort_id uuid;
  v_sha text := repeat('a', 64);
BEGIN
  -- Setup project, location, team, instrument, published version, active session, assignment
  v_res := public.cmd_create_project_v1('s3-p1-0001', 'PRJ-S3-01', 'Slice 3 Project', 'Asia/Jakarta');
  v_proj_id := (v_res->>'project_id')::uuid;
  v_res := public.cmd_create_location_v1('s3-loc-001', v_proj_id, 'LOC-S3', 'Loc S3');
  v_loc_id := (v_res->>'location_id')::uuid;
  v_res := public.cmd_create_team_v1('s3-tm-0001', v_proj_id, 'TM-S3', 'Team S3');
  v_team_id := (v_res->>'team_id')::uuid;

  PERFORM public.cmd_grant_role_v1('s3-gr-i1', '40000002-0000-4000-8000-000000000002', 'inspector', v_proj_id, now(), NULL, 'Insp1');
  PERFORM public.cmd_grant_role_v1('s3-gr-i2', '40000003-0000-4000-8000-000000000003', 'inspector', v_proj_id, now(), NULL, 'Insp2');
  PERFORM public.cmd_grant_role_v1('s3-gr-r1', '40000004-0000-4000-8000-000000000004', 'reviewer', v_proj_id, now(), NULL, 'Rev1');
  -- Also give Inspector 1 reviewer role so we can prove hard SoD blocks self-review!
  PERFORM public.cmd_grant_role_v1('s3-gr-i1r', '40000002-0000-4000-8000-000000000002', 'reviewer', v_proj_id, now(), NULL, 'Dual role for SoD test');
  PERFORM public.cmd_grant_role_v1('s3-gr-k1', '40000005-0000-4000-8000-000000000005', 'korlap', v_proj_id, now(), NULL, 'Korlap1');

  v_res := public.cmd_create_instrument_v1('s3-inst-01', 'IFP_S3', 'IFP-S3', 'IFP S3', NULL, true);
  v_inst_id := (v_res->>'instrument_id')::uuid;
  v_res := public.cmd_save_instrument_draft_v1(
    's3-drft-01', v_inst_id, NULL, '1.0',
    '[{"code":"S1","label":"Check","items":[{"code":"I1","label":"Power on","answer_type":"PASS_FAIL","required":true}]}]'::jsonb,
    '[{"code":"SP1","label":"Voltage","value_type":"INTEGER","expected_value":"220","unit":"V","required":true}]'::jsonb,
    '[{"code":"EV1","label":"Front Photo","required":true,"allowed_media_types":["image/jpeg"]}]'::jsonb
  );
  v_ver_id := (v_res->>'version_id')::uuid;
  PERFORM public.cmd_publish_instrument_version_v1('s3-pub-001', v_inst_id, v_ver_id, v_res->>'draft_hash', 'Publish v1');

  SELECT ci.id INTO v_item_id FROM public.checklist_items ci JOIN public.checklist_sections cs ON cs.id = ci.section_id WHERE cs.instrument_version_id = v_ver_id LIMIT 1;
  SELECT sf.id INTO v_spec_id FROM public.specification_fields sf WHERE sf.instrument_version_id = v_ver_id LIMIT 1;
  SELECT es.id INTO v_slot_id FROM public.evidence_slot_definitions es WHERE es.instrument_version_id = v_ver_id LIMIT 1;

  v_res := public.cmd_create_session_v1('s3-sess-01', v_proj_id, 'SESS-S3', now(), now() + interval '8 hours');
  v_sess_id := (v_res->>'session_id')::uuid;
  PERFORM public.cmd_transition_session_v1('s3-sact-01', v_sess_id, 'ACTIVATE', 1, 'Activate S3');

  v_res := public.cmd_publish_assignment_v1(
    's3-asgn-01', v_proj_id, v_sess_id, v_loc_id, v_inst_id, v_ver_id, v_team_id,
    now(), now() + interval '4 hours',
    '[{"user_id":"40000002-0000-4000-8000-000000000002","operational_role":"inspector"},{"user_id":"40000003-0000-4000-8000-000000000003","operational_role":"inspector"}]'::jsonb
  );
  v_assign_id := (v_res->>'assignment_id')::uuid;

  -- Switch to Inspector 1: Register & Claim unit 1 (CMD-026)
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_register_canonical_unit_v1('s3-u1-0001', v_proj_id, v_inst_id, 'SN-S3-001', '{}'::jsonb);
  v_unit_id := (v_res->>'unit_id')::uuid;
  v_assoc_id := (v_res->>'association_id')::uuid;

  v_res := public.cmd_claim_unit_v1('s3-clm-001', v_unit_id, v_assoc_id, v_assign_id, 60);
  IF v_res->>'status' <> 'CLAIMED' THEN
    RAISE EXCEPTION 'CMD-026 CLAIM FAIL: %', v_res;
  END IF;
  v_claim_id := (v_res->>'claim_id')::uuid;
  v_insp_id := (v_res->>'inspection_id')::uuid;

  -- Inspector 2 CANNOT claim same unit while active (global unique active claim)
  PERFORM set_config('request.jwt.claim.sub', '30000003-0000-4000-8000-000000000003', true);
  v_res := public.cmd_claim_unit_v1('s3-clm-dup', v_unit_id, v_assoc_id, v_assign_id, 60);
  IF v_res->>'status' <> 'ACTIVE_CLAIM_EXISTS' THEN
    RAISE EXCEPTION 'CMD-026 ACTIVE_CLAIM_EXISTS FAIL: %', v_res;
  END IF;

  -- Back to Inspector 1: submit incomplete draft -> INCOMPLETE
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_submit_inspection_v1('s3-sub-inc', v_insp_id, 1, 'Incomplete attempt');
  IF v_res->>'status' <> 'INCOMPLETE' THEN
    RAISE EXCEPTION 'CMD-029 INCOMPLETE FAIL: %', v_res;
  END IF;

  -- Save valid draft (CMD-028: row_version 1 -> 2)
  v_res := public.cmd_save_draft_v1(
    's3-sav-001', v_insp_id, 1,
    pg_catalog.jsonb_build_object(v_item_id::text, 'PASS'),
    pg_catalog.jsonb_build_object(v_spec_id::text, '220'),
    'All checks good'
  );
  IF v_res->>'status' <> 'SAVED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-028 SAVE FAIL: %', v_res;
  END IF;

  -- Submit without finalized evidence -> EVIDENCE_NOT_READY
  v_res := public.cmd_submit_inspection_v1('s3-sub-ev1', v_insp_id, 2, 'No photo yet');
  IF v_res->>'status' <> 'EVIDENCE_NOT_READY' THEN
    RAISE EXCEPTION 'CMD-029 EVIDENCE_NOT_READY FAIL: %', v_res;
  END IF;

  -- Upload intent (CMD-033) + bad checksum confirm fails EVIDENCE_INVALID + good confirm succeeds (CMD-034)
  v_res := public.cmd_create_upload_intent_v1('s3-evi-001', v_insp_id, v_slot_id, 'image/jpeg', 120000, v_sha, 'client-file-0001');
  IF v_res->>'status' <> 'INTENT_CREATED' THEN
    RAISE EXCEPTION 'CMD-033 INTENT FAIL: %', v_res;
  END IF;
  v_ev_id := (v_res->>'evidence_asset_id')::uuid;

  v_res := public.cmd_confirm_upload_v1('s3-evc-001', v_ev_id, v_sha, 120000, 'image/jpeg');
  IF v_res->>'status' <> 'FINALIZED' THEN
    RAISE EXCEPTION 'CMD-034 CONFIRM FAIL: %', v_res;
  END IF;

  -- Offline sync batch (CMD-035): bind device, test stale version conflict preservation + valid apply
  v_res := public.cmd_register_device_binding_v1('s3-dev-001', repeat('b', 64), 'Android Chrome Field 01');
  IF v_res->>'status' <> 'BOUND' THEN
    RAISE EXCEPTION 'DEVICE BIND FAIL: %', v_res;
  END IF;
  v_dev_id := (v_res->>'device_id')::uuid;

  -- Stale version (1 instead of 2) triggers CONFLICTED and sets has_unresolved_sync_conflict = true (blocks submit!)
  v_res := public.cmd_sync_batch_v1(
    's3-syn-stl', v_dev_id, 'batch-stale-0001',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'operation_id', 'op-stale-1', 'op_type', 'SAVE_DRAFT', 'inspection_id', v_insp_id,
      'expected_row_version', '1', 'payload', pg_catalog.jsonb_build_object('notes', 'Stale offline edit')
    ))
  );
  IF v_res->>'status' <> 'CONFLICTED' THEN
    RAISE EXCEPTION 'CMD-035 STALE CONFLICT FAIL: %', v_res;
  END IF;

  -- Submit blocked by unresolved sync conflict
  v_res := public.cmd_submit_inspection_v1('s3-sub-cnf', v_insp_id, 2, 'Blocked by sync conflict');
  IF v_res->>'status' <> 'SYNC_CONFLICT' THEN
    RAISE EXCEPTION 'CMD-029 SYNC_CONFLICT GUARD FAIL: %', v_res;
  END IF;

  -- Explicit online draft save reconciles conflict (row_version 2 -> 3)
  v_res := public.cmd_save_draft_v1(
    's3-sav-rec', v_insp_id, 2,
    pg_catalog.jsonb_build_object(v_item_id::text, 'PASS'),
    pg_catalog.jsonb_build_object(v_spec_id::text, '220'),
    'Reconciled online'
  );
  IF v_res->>'status' <> 'SAVED' OR v_res->>'row_version' <> '3' THEN
    RAISE EXCEPTION 'CMD-028 RECONCILE FAIL: %', v_res;
  END IF;

  -- Valid offline sync batch on current version (3 -> 4)
  v_res := public.cmd_sync_batch_v1(
    's3-syn-ok1', v_dev_id, 'batch-valid-0001',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'operation_id', 'op-valid-1', 'op_type', 'SAVE_DRAFT', 'inspection_id', v_insp_id,
      'expected_row_version', '3', 'payload', pg_catalog.jsonb_build_object('notes', 'Synced offline note')
    ))
  );
  IF v_res->>'status' <> 'APPLIED' THEN
    RAISE EXCEPTION 'CMD-035 APPLIED FAIL: %', v_res;
  END IF;

  -- Submit Revision 1 (CMD-029: row_version 4 -> 5)
  v_res := public.cmd_submit_inspection_v1('s3-sub-ok1', v_insp_id, 4, 'Ready for review');
  IF v_res->>'status' <> 'SUBMITTED' OR v_res->>'revision_no' <> '1' THEN
    RAISE EXCEPTION 'CMD-029 SUBMIT FAIL: %', v_res;
  END IF;
  v_rev1_id := (v_res->>'revision_id')::uuid;

  -- Self-approve by Inspector 1 (who also holds reviewer role) MUST FAIL SOD_VIOLATION!
  v_res := public.cmd_approve_inspection_v1('s3-sod-app', v_insp_id, v_rev1_id, 1, 'Self approve attempt');
  IF v_res->>'status' <> 'SOD_VIOLATION' THEN
    RAISE EXCEPTION 'CMD-031 SOD FAIL: %', v_res;
  END IF;

  -- Release claim while SUBMITTED must fail
  v_res := public.cmd_release_unit_claim_v1('s3-rel-sub', v_claim_id, 1, 'Try release under review');
  IF v_res->>'status' <> 'STATE_CONFLICT' THEN
    RAISE EXCEPTION 'CMD-027 UNDER_REVIEW GUARD FAIL: %', v_res;
  END IF;

  -- Switch to Reviewer 1: Return Revision 1 (CMD-030)
  PERFORM set_config('request.jwt.claim.sub', '30000004-0000-4000-8000-000000000004', true);
  v_res := public.cmd_return_inspection_v1('s3-ret-001', v_insp_id, v_rev1_id, 1, 'Please clarify voltage reading note');
  IF v_res->>'status' <> 'RETURNED' THEN
    RAISE EXCEPTION 'CMD-030 RETURN FAIL: %', v_res;
  END IF;

  -- Inspector 1 corrects and submits Revision 2 (CMD-029)
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_submit_inspection_v1('s3-sub-ok2', v_insp_id, 6, 'Resubmitted revision 2');
  IF v_res->>'status' <> 'SUBMITTED' OR v_res->>'revision_no' <> '2' THEN
    RAISE EXCEPTION 'CMD-029 RESUBMIT REV2 FAIL: %', v_res;
  END IF;
  v_rev2_id := (v_res->>'revision_id')::uuid;

  -- Reviewer 1 approves Revision 2 (CMD-031; releases claim automatically)
  PERFORM set_config('request.jwt.claim.sub', '30000004-0000-4000-8000-000000000004', true);
  v_res := public.cmd_approve_inspection_v1('s3-app-002', v_insp_id, v_rev2_id, 2, 'Verified revision 2');
  IF v_res->>'status' <> 'APPROVED' THEN
    RAISE EXCEPTION 'CMD-031 APPROVE FAIL: %', v_res;
  END IF;

  -- Super Admin reopens approved inspection (CMD-032; clears owner so explicit claim required per IDC-O05)
  PERFORM set_config('request.jwt.claim.sub', '30000001-0000-4000-8000-000000000001', true);
  v_res := public.cmd_reopen_inspection_v1('s3-reo-001', v_insp_id, v_rev2_id, 8, 'Audit discrepancy requires re-check');
  IF v_res->>'status' <> 'REOPENED' THEN
    RAISE EXCEPTION 'CMD-032 REOPEN FAIL: %', v_res;
  END IF;

  -- Inspector 1 cannot edit reopened inspection BEFORE re-claiming it!
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_save_draft_v1('s3-sav-uncl', v_insp_id, 9, '{}'::jsonb, '{}'::jsonb, 'No claim');
  IF v_res->>'status' <> 'CLAIM_INVALID' THEN
    RAISE EXCEPTION 'IDC-O05 REOPEN CLAIM GUARD FAIL: %', v_res;
  END IF;

  -- SES-001 Packed-Unit Abort flow on Unit 2 (CMD-055 -> CMD-056 -> permanently terminal ABORTED)
  v_res := public.cmd_register_canonical_unit_v1('s3-u2-0001', v_proj_id, v_inst_id, 'SN-S3-002', '{}'::jsonb);
  v_unit2_id := (v_res->>'unit_id')::uuid;
  v_assoc2_id := (v_res->>'association_id')::uuid;
  v_res := public.cmd_claim_unit_v1('s3-clm-u2', v_unit2_id, v_assoc2_id, v_assign_id, 60);
  v_insp2_id := (v_res->>'inspection_id')::uuid;

  PERFORM public.cmd_save_draft_v1('s3-sav-u2', v_insp2_id, 1, pg_catalog.jsonb_build_object(v_item_id::text, 'FAIL'), pg_catalog.jsonb_build_object(v_spec_id::text, '0'), 'Packed damage');
  v_res := public.cmd_create_upload_intent_v1('s3-evi-u2', v_insp2_id, v_slot_id, 'image/jpeg', 50000, v_sha, 'file-u2-001');
  PERFORM public.cmd_confirm_upload_v1('s3-evc-u2', (v_res->>'evidence_asset_id')::uuid, v_sha, 50000, 'image/jpeg');
  v_res := public.cmd_submit_inspection_v1('s3-sub-u2', v_insp2_id, 2, 'Submit U2');

  -- Reviewer returns U2
  PERFORM set_config('request.jwt.claim.sub', '30000004-0000-4000-8000-000000000004', true);
  PERFORM public.cmd_return_inspection_v1('s3-ret-u2', v_insp2_id, (v_res->>'revision_id')::uuid, 1, 'Unit already sealed in crate');

  -- Inspector requests packed-unit abort (CMD-055)
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_request_packed_unit_abort_v1('s3-abr-req', v_insp2_id, 'Physical unit packed & palletized');
  IF v_res->>'status' <> 'ACCEPTED' THEN
    RAISE EXCEPTION 'CMD-055 ABORT REQUEST FAIL: %', v_res;
  END IF;
  v_abort_id := (v_res->>'abort_request_id')::uuid;

  -- Korlap approves abort (CMD-056 -> ABORTED)
  PERFORM set_config('request.jwt.claim.sub', '30000005-0000-4000-8000-000000000005', true);
  v_res := public.cmd_decide_packed_unit_abort_v1('s3-abr-dec', v_abort_id, 'APPROVE', 1, 'Confirmed sealed pallet on site');
  IF v_res->>'status' <> 'APPROVED' OR v_res->>'inspection_status' <> 'ABORTED' THEN
    RAISE EXCEPTION 'CMD-056 ABORT DECIDE FAIL: %', v_res;
  END IF;

  -- IDC-O10/SES-T10: Brand-new inspection_id CAN be claimed for unit 2 while prior ABORTED attempt stays terminal!
  PERFORM set_config('request.jwt.claim.sub', '30000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_claim_unit_v1('s3-clm-u2n', v_unit2_id, v_assoc2_id, v_assign_id, 60);
  IF v_res->>'status' <> 'CLAIMED' OR (v_res->>'inspection_id')::uuid = v_insp2_id THEN
    RAISE EXCEPTION 'IDC-O10 NEW INSPECTION AFTER ABORT FAIL: %', v_res;
  END IF;
END
$$;

SELECT 'ALL_SLICE3_I3_I4_INSPECTION_EVIDENCE_SYNC_ASSERTIONS_PASSED' AS verification_result;

ROLLBACK;
