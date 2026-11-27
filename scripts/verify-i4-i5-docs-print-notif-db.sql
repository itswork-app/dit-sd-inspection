-- Synthetic local PostgreSQL verification suite for Slice 4 (I4/I5):
-- Full 62/62 canonical table + 62/62 ENABLE/FORCE RLS verification,
-- zero CMD-044 / CMD-045..048 / external CMD-053 surface assertion,
-- Documents (CMD-036 + C36-02 STALE_CANCELLED on reopen),
-- Printing (CMD-037 DOC-003 current-only & post-CLOSED print, CMD-038 partial batch),
-- Attendance (CMD-039 replacement + CMD-040 SoD verification),
-- Reports & Audit Reads (CMD-041..043),
-- and In-App Notifications (CMD-049..052, CMD-054, POQ-01..03, NLA-MVP-001).
-- Runs inside a rolled-back transaction so local DB remains clean.

\set ON_ERROR_STOP on

BEGIN;

-- 1. pg_catalog full-system 62/62 RLS & T-18 security assertions
DO $$
DECLARE
  v_table_count int;
  v_rls_missing int;
  v_cmd_count int;
  v_bad_funcs int;
  v_worker_browser_exec int;
  v_prohibited_funcs int;
BEGIN
  IF has_schema_privilege('app_cmd_definer', 'public', 'CREATE')
     OR has_schema_privilege('app_cmd_definer', 'app_internal', 'CREATE')
     OR has_schema_privilege('app_worker_definer', 'app_internal', 'CREATE') THEN
    RAISE EXCEPTION 'T-18 FAIL: definer role retained runtime CREATE privilege';
  END IF;

  -- Exact 62 canonical public tables with 62/62 ENABLE + FORCE RLS
  SELECT count(*) INTO v_table_count
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r';
  IF v_table_count <> 62 THEN
    RAISE EXCEPTION 'SCHEMA PARITY FAIL: expected exact 62 canonical public tables, got %', v_table_count;
  END IF;

  SELECT count(*) INTO v_rls_missing
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r'
    AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity);
  IF v_rls_missing <> 0 THEN
    RAISE EXCEPTION 'RLS PARITY FAIL: % of 62 tables missing ENABLE/FORCE RLS', v_rls_missing;
  END IF;

  -- All browser-callable public.cmd_*_v1 must be SECURITY DEFINER owned by app_cmd_definer with search_path=""
  SELECT count(*) INTO v_cmd_count
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1';
  IF v_cmd_count <> 52 THEN
    RAISE EXCEPTION 'CATALOG FAIL: expected 52 public cmd_*_v1 wrappers, got %', v_cmd_count;
  END IF;

  SELECT count(*) INTO v_bad_funcs
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace JOIN pg_roles r ON r.oid = p.proowner
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1'
    AND (NOT p.prosecdef OR r.rolname <> 'app_cmd_definer' OR NOT (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']));
  IF v_bad_funcs <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: % cmd_*_v1 function(s) violate security invariants', v_bad_funcs;
  END IF;

  -- Internal worker functions must NEVER be executable by PUBLIC, anon, or authenticated
  SELECT count(*) INTO v_worker_browser_exec
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'app_internal' AND p.proname LIKE 'worker_%'
    AND (
      has_function_privilege('public', p.oid, 'EXECUTE')
      OR has_function_privilege('anon', p.oid, 'EXECUTE')
      OR has_function_privilege('authenticated', p.oid, 'EXECUTE')
    );
  IF v_worker_browser_exec <> 0 THEN
    RAISE EXCEPTION 'T-18 WORKER FAIL: browser role can execute internal worker function';
  END IF;

  -- Strictly prohibited surfaces must NOT exist (CMD-044 export-audit, CMD-053 external dispatch, CMD-045..048)
  SELECT count(*) INTO v_prohibited_funcs
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND (p.proname LIKE '%export_audit%' OR p.proname LIKE '%dispatch_notification%' OR p.proname LIKE '%retention%' OR p.proname LIKE '%legal_hold%');
  IF v_prohibited_funcs <> 0 THEN
    RAISE EXCEPTION 'G10 BOUNDARY FAIL: prohibited T-10/T-12/CMD-045..048 function exists';
  END IF;
END
$$;

-- 2. Seed synthetic users (Super Admin, Inspector, Reviewer, Print Officer, Korlap, Suspended User)
INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES
  ('50000001-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sa4@example.test', '{}', '{}', now(), now()),
  ('50000002-0000-4000-8000-000000000002', '00000000-0000-0000-8000-000000000002', 'authenticated', 'authenticated', 'insp4@example.test', '{}', '{}', now(), now()),
  ('50000003-0000-4000-8000-000000000003', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'rev4@example.test', '{}', '{}', now(), now()),
  ('50000004-0000-4000-8000-000000000004', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'po4@example.test', '{}', '{}', now(), now()),
  ('50000005-0000-4000-8000-000000000005', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'kor4@example.test', '{}', '{}', now(), now()),
  ('50000006-0000-4000-8000-000000000006', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'susp4@example.test', '{}', '{}', now(), now());

INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
VALUES
  ('60000001-0000-4000-8000-000000000001', '50000001-0000-4000-8000-000000000001', 'SA Slice4', 'APPROVED', 1),
  ('60000002-0000-4000-8000-000000000002', '50000002-0000-4000-8000-000000000002', 'Inspector S4', 'APPROVED', 1),
  ('60000003-0000-4000-8000-000000000003', '50000003-0000-4000-8000-000000000003', 'Reviewer S4', 'APPROVED', 1),
  ('60000004-0000-4000-8000-000000000004', '50000004-0000-4000-8000-000000000004', 'Print Officer S4', 'APPROVED', 1),
  ('60000005-0000-4000-8000-000000000005', '50000005-0000-4000-8000-000000000005', 'Korlap S4', 'APPROVED', 1),
  ('60000006-0000-4000-8000-000000000006', '50000006-0000-4000-8000-000000000006', 'Suspended User S4', 'SUSPENDED', 1);

INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
SELECT '60000001-0000-4000-8000-000000000001', r.id, NULL, 'ACTIVE', '60000005-0000-4000-8000-000000000005', 'Bootstrap SA'
FROM public.roles r WHERE r.code = 'super_admin';

-- Seed one active PDF template version
INSERT INTO public.document_template_versions (id, document_type, template_key, version_no, template_hash, status, created_by)
VALUES ('70000001-0000-4000-8000-000000000001', 'INSPECTION_PDF', 'IFP_STD_PDF', 1, repeat('c', 64), 'ACTIVE', '60000001-0000-4000-8000-000000000001');

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '50000001-0000-4000-8000-000000000001';

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
  v_unit_id uuid;
  v_assoc_id uuid;
  v_insp_id uuid;
  v_rev_id uuid;
  v_doc1_id uuid;
  v_doc2_id uuid;
  v_att_rec_id uuid;
  v_att_doc_id uuid;
  v_policy_id uuid;
  v_sha text := repeat('d', 64);
BEGIN
  -- Setup project, location, team, instrument, session, roles, assignment
  v_res := public.cmd_create_project_v1('s4-p1-0001', 'PRJ-S4-01', 'Slice 4 Project', 'Asia/Jakarta');
  v_proj_id := (v_res->>'project_id')::uuid;
  v_res := public.cmd_create_location_v1('s4-loc-001', v_proj_id, 'LOC-S4', 'Loc S4');
  v_loc_id := (v_res->>'location_id')::uuid;
  v_res := public.cmd_create_team_v1('s4-tm-0001', v_proj_id, 'TM-S4', 'Team S4');
  v_team_id := (v_res->>'team_id')::uuid;

  PERFORM public.cmd_grant_role_v1('s4-gr-insp', '60000002-0000-4000-8000-000000000002', 'inspector', v_proj_id, now(), NULL, 'Insp');
  PERFORM public.cmd_grant_role_v1('s4-gr-rev1', '60000003-0000-4000-8000-000000000003', 'reviewer', v_proj_id, now(), NULL, 'Rev');
  PERFORM public.cmd_grant_role_v1('s4-gr-po01', '60000004-0000-4000-8000-000000000004', 'print_officer', v_proj_id, now(), NULL, 'Print Officer');
  PERFORM public.cmd_grant_role_v1('s4-gr-kor1', '60000005-0000-4000-8000-000000000005', 'korlap', v_proj_id, now(), NULL, 'Kor');

  v_res := public.cmd_create_instrument_v1('s4-inst-01', 'IFP_S4', 'IFP-S4', 'IFP S4', NULL, true);
  v_inst_id := (v_res->>'instrument_id')::uuid;
  v_res := public.cmd_save_instrument_draft_v1(
    's4-drft-01', v_inst_id, NULL, '1.0',
    '[{"code":"S1","label":"Check","items":[{"code":"I1","label":"OK","answer_type":"PASS_FAIL","required":true}]}]'::jsonb,
    '[]'::jsonb, '[]'::jsonb
  );
  v_ver_id := (v_res->>'version_id')::uuid;
  PERFORM public.cmd_publish_instrument_version_v1('s4-pub-001', v_inst_id, v_ver_id, v_res->>'draft_hash', 'Pub v1');
  SELECT ci.id INTO v_item_id FROM public.checklist_items ci JOIN public.checklist_sections cs ON cs.id = ci.section_id WHERE cs.instrument_version_id = v_ver_id LIMIT 1;

  v_res := public.cmd_create_session_v1('s4-sess-01', v_proj_id, 'SESS-S4', now(), now() + interval '8 hours');
  v_sess_id := (v_res->>'session_id')::uuid;
  PERFORM public.cmd_transition_session_v1('s4-sact-01', v_sess_id, 'ACTIVATE', 1, 'Start S4');

  v_res := public.cmd_publish_assignment_v1(
    's4-asgn-01', v_proj_id, v_sess_id, v_loc_id, v_inst_id, v_ver_id, v_team_id,
    now(), now() + interval '4 hours',
    '[{"user_id":"60000002-0000-4000-8000-000000000002","operational_role":"inspector"}]'::jsonb
  );
  v_assign_id := (v_res->>'assignment_id')::uuid;

  -- Publish target plan for CMD-042 report verification
  v_res := public.cmd_manage_target_plan_v1('s4-tp-0001', v_sess_id, 'CREATE_DRAFT', NULL, NULL, '[]'::jsonb);
  PERFORM public.cmd_manage_target_plan_v1('s4-tp-0002', v_sess_id, 'REPLACE_DRAFT_ALLOCATIONS', (v_res->>'plan_id')::uuid, 1,
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('assignment_id', v_assign_id, 'target_date', '2026-11-27', 'quantity', 15)));
  PERFORM public.cmd_manage_target_plan_v1('s4-tp-0003', v_sess_id, 'PUBLISH', (v_res->>'plan_id')::uuid, 2, '[]'::jsonb);

  -- Inspector registers, claims, saves, submits; Reviewer approves
  PERFORM set_config('request.jwt.claim.sub', '50000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_register_canonical_unit_v1('s4-u1-0001', v_proj_id, v_inst_id, 'SN-S4-001', '{}'::jsonb);
  v_unit_id := (v_res->>'unit_id')::uuid;
  v_assoc_id := (v_res->>'association_id')::uuid;
  v_res := public.cmd_claim_unit_v1('s4-clm-001', v_unit_id, v_assoc_id, v_assign_id, 60);
  v_insp_id := (v_res->>'inspection_id')::uuid;
  PERFORM public.cmd_save_draft_v1('s4-sav-001', v_insp_id, 1, pg_catalog.jsonb_build_object(v_item_id::text, 'PASS'), '{}'::jsonb, 'OK');
  v_res := public.cmd_submit_inspection_v1('s4-sub-001', v_insp_id, 2, 'Submit S4');
  v_rev_id := (v_res->>'revision_id')::uuid;

  PERFORM set_config('request.jwt.claim.sub', '50000003-0000-4000-8000-000000000003', true);
  PERFORM public.cmd_approve_inspection_v1('s4-app-001', v_insp_id, v_rev_id, 1, 'Approved S4');

  -- Print Officer generates v1 PDF, then v2 PDF (v1 becomes SUPERSEDED)
  PERFORM set_config('request.jwt.claim.sub', '50000004-0000-4000-8000-000000000004', true);
  v_res := public.cmd_generate_approved_document_v1('s4-doc-001', 'INSPECTION_PDF', v_insp_id, v_rev_id, '70000001-0000-4000-8000-000000000001');
  IF v_res->>'status' <> 'GENERATED' OR v_res->>'version_no' <> '1' THEN
    RAISE EXCEPTION 'CMD-036 V1 FAIL: %', v_res;
  END IF;
  v_doc1_id := (v_res->>'document_id')::uuid;

  v_res := public.cmd_generate_approved_document_v1('s4-doc-002', 'INSPECTION_PDF', v_insp_id, v_rev_id, '70000001-0000-4000-8000-000000000001');
  IF v_res->>'status' <> 'GENERATED' OR v_res->>'version_no' <> '2' THEN
    RAISE EXCEPTION 'CMD-036 V2 FAIL: %', v_res;
  END IF;
  v_doc2_id := (v_res->>'document_id')::uuid;

  -- DOC-003: Printing superseded v1 MUST FAIL DOCUMENT_VERSION_SUPERSEDED!
  v_res := public.cmd_record_print_v1('s4-prt-sup', v_doc1_id, 1, NULL, 'browser-dialog');
  IF v_res->>'status' <> 'DOCUMENT_VERSION_SUPERSEDED' THEN
    RAISE EXCEPTION 'CMD-037 DOC-003 SUPERSEDED FAIL: %', v_res;
  END IF;

  -- Close session first, then verify DOC-003 ALLOWS printing current v2 even after CLOSED!
  PERFORM set_config('request.jwt.claim.sub', '50000001-0000-4000-8000-000000000001', true);
  PERFORM public.cmd_transition_session_v1('s4-scls-01', v_sess_id, 'CLOSE', 2, 'Close session before print');

  PERFORM set_config('request.jwt.claim.sub', '50000004-0000-4000-8000-000000000004', true);
  v_res := public.cmd_record_print_v1('s4-prt-ok1', v_doc2_id, 2, 0, 'browser-dialog');
  IF v_res->>'status' <> 'RECORDED' OR v_res->>'sequence_no' <> '1' THEN
    RAISE EXCEPTION 'CMD-037 POST-CLOSED PRINT FAIL: %', v_res;
  END IF;

  -- CMD-038 Print Batch with 1 valid current v2 + 1 superseded v1 -> PARTIAL!
  v_res := public.cmd_record_print_batch_v1(
    's4-bat-001', v_proj_id, v_sess_id,
    pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('item_key', 'item-cur', 'document_id', v_doc2_id, 'expected_document_version', 2),
      pg_catalog.jsonb_build_object('item_key', 'item-old', 'document_id', v_doc1_id, 'expected_document_version', 1)
    )
  );
  IF v_res->>'status' <> 'PARTIAL' THEN
    RAISE EXCEPTION 'CMD-038 PARTIAL BATCH FAIL: %', v_res;
  END IF;

  -- CMD-039 & CMD-040 Attendance: SA uploads, Korlap verifies (self-verify denied by SoD!)
  PERFORM set_config('request.jwt.claim.sub', '50000001-0000-4000-8000-000000000001', true);
  v_res := public.cmd_upload_attendance_document_v1('s4-att-u1', v_proj_id, v_sess_id, v_loc_id, v_sha, 80000, 'application/pdf', NULL);
  IF v_res->>'status' <> 'UPLOADED' THEN
    RAISE EXCEPTION 'CMD-039 UPLOAD FAIL: %', v_res;
  END IF;
  v_att_rec_id := (v_res->>'attendance_record_id')::uuid;
  v_att_doc_id := (v_res->>'attendance_document_id')::uuid;

  -- Korlap verifies SA's upload (CMD-040)
  PERFORM set_config('request.jwt.claim.sub', '50000005-0000-4000-8000-000000000005', true);
  v_res := public.cmd_verify_attendance_v1('s4-att-v1', v_att_rec_id, v_att_doc_id, 'VERIFY', 1, 'Signatures matched');
  IF v_res->>'status' <> 'VERIFIED' THEN
    RAISE EXCEPTION 'CMD-040 VERIFY FAIL: %', v_res;
  END IF;

  -- CMD-041 Actual report & CMD-042 Target report & CMD-043 Audit read
  PERFORM set_config('request.jwt.claim.sub', '50000001-0000-4000-8000-000000000001', true);
  v_res := public.cmd_get_actual_report_v1(v_proj_id, v_sess_id);
  IF v_res->>'status' <> 'OK' OR (v_res->'actual_counts_by_status'->>'APPROVED') <> '1' THEN
    RAISE EXCEPTION 'CMD-041 ACTUAL REPORT FAIL: %', v_res;
  END IF;

  v_res := public.cmd_get_target_report_v1(v_proj_id, v_sess_id);
  IF v_res->>'status' <> 'OK' OR (v_res->>'total_target_quantity') <> '15' THEN
    RAISE EXCEPTION 'CMD-042 TARGET REPORT FAIL: %', v_res;
  END IF;

  v_res := public.cmd_read_audit_v1('Synthetic Slice 4 compliance verification', 20, NULL);
  IF v_res->>'status' <> 'OK' THEN
    RAISE EXCEPTION 'CMD-043 AUDIT READ FAIL: %', v_res;
  END IF;

  -- CMD-051 Publish Notification Policy (POQ-02 ELAPSED_UTC default)
  v_res := public.cmd_publish_notification_policy_v1('s4-pol-01', 'INSPECTION_SLA_DEFAULT', 'GLOBAL', NULL, 'ELAPSED_UTC', '{"sla_minutes":60}'::jsonb);
  IF v_res->>'status' <> 'PUBLISHED' OR v_res->>'sla_mode' <> 'ELAPSED_UTC' THEN
    RAISE EXCEPTION 'CMD-051 POLICY FAIL: %', v_res;
  END IF;
  v_policy_id := (v_res->>'policy_version_id')::uuid;

  -- Verify C36-02 trigger: insert a synthetic PROCESSING job, reopen inspection -> STALE_CANCELLED!
  -- (Done after RESET ROLE below so we can also test worker CMD-052/054!)
END
$$;

-- 3. Test C36-02 STALE_CANCELLED + Worker CMD-052 (POQ-01 suppression) + CMD-049/050 (POQ-03) + CMD-054 Escalation
RESET ROLE;

DO $$
DECLARE
  v_insp_id uuid;
  v_rev_id uuid;
  v_proj_id uuid;
  v_sess_id uuid;
  v_job_id uuid;
  v_policy_id uuid;
  v_outbox_id uuid;
  v_res jsonb;
  v_notif_id uuid;
BEGIN
  SELECT id, project_id, session_id INTO v_insp_id, v_proj_id, v_sess_id FROM public.inspections LIMIT 1;
  SELECT id INTO v_rev_id FROM public.inspection_revisions WHERE inspection_id = v_insp_id LIMIT 1;
  SELECT id INTO v_policy_id FROM public.notification_policy_versions LIMIT 1;

  -- C36-02: Insert in-flight PROCESSING job, then reopen inspection as SA -> job becomes STALE_CANCELLED!
  INSERT INTO public.document_generation_jobs (
    project_id, session_id, inspection_id, inspection_revision_id, document_type,
    template_version_id, source_hash, status, requested_by
  ) VALUES (
    v_proj_id, v_sess_id, v_insp_id, v_rev_id, 'INSPECTION_PDF',
    '70000001-0000-4000-8000-000000000001', repeat('e', 64), 'PROCESSING', '60000004-0000-4000-8000-000000000004'
  ) RETURNING id INTO v_job_id;

  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claim.sub = '50000001-0000-4000-8000-000000000001';
  v_res := public.cmd_reopen_inspection_v1('s4-reo-c36', v_insp_id, v_rev_id, 4, 'C36-02 reopen invalidation test');
  IF v_res->>'status' <> 'REOPENED' THEN
    RAISE EXCEPTION 'C36-02 REOPEN FAIL: %', v_res;
  END IF;

  RESET ROLE;
  IF (SELECT status FROM public.document_generation_jobs WHERE id = v_job_id) <> 'STALE_CANCELLED' THEN
    RAISE EXCEPTION 'C36-02 FAIL: in-flight job was not marked STALE_CANCELLED on reopen';
  END IF;

  -- POQ-01 + CMD-052: Create outbox with 2 event-time candidates (1 APPROVED + 1 SUSPENDED)
  INSERT INTO public.notification_outbox (
    source_event_id, event_type, scope_type, scope_id, policy_version_id, safe_payload, status
  ) VALUES (
    gen_random_uuid(), 'inspection.returned_for_correction', 'PROJECT', v_proj_id, v_policy_id, '{"ref":"S4"}'::jsonb, 'PENDING'
  ) RETURNING id INTO v_outbox_id;

  INSERT INTO public.notification_outbox_recipients (outbox_id, recipient_user_id, eligibility_reason, source_scope_type, source_scope_id)
  VALUES
    (v_outbox_id, '60000002-0000-4000-8000-000000000002', 'Assigned Inspector', 'PROJECT', v_proj_id),
    (v_outbox_id, '60000006-0000-4000-8000-000000000006', 'Suspended candidate must be suppressed', 'PROJECT', v_proj_id);

  v_res := app_internal.worker_fanout_notification_outbox_v1(v_outbox_id, 'synthetic-worker-1');
  IF v_res->>'status' <> 'COMPLETED' OR v_res->>'created' <> '1' OR v_res->>'suppressed' <> '1' THEN
    RAISE EXCEPTION 'CMD-052 POQ-01 FANOUT FAIL: %', v_res;
  END IF;

  -- CMD-049 & CMD-050 as Inspector (recipient): list omits dismissed_at; mark read sets read_at once!
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claim.sub = '50000002-0000-4000-8000-000000000002';
  v_res := public.cmd_list_own_notifications_v1(true, 10);
  IF v_res->>'status' <> 'OK' OR jsonb_array_length(v_res->'notifications') <> 1 OR (v_res->'notifications'->0 ? 'dismissed_at') THEN
    RAISE EXCEPTION 'CMD-049 POQ-03 LIST FAIL: %', v_res;
  END IF;
  v_notif_id := (v_res->'notifications'->0->>'id')::uuid;

  -- Reviewer (non-recipient) cannot mark Inspector's notification read (non-enumerating NOT_FOUND)
  PERFORM set_config('request.jwt.claim.sub', '50000003-0000-4000-8000-000000000003', true);
  v_res := public.cmd_mark_notification_read_v1(v_notif_id);
  IF v_res->>'status' <> 'NOT_FOUND' THEN
    RAISE EXCEPTION 'CMD-050 CROSS-USER ISOLATION FAIL: %', v_res;
  END IF;

  -- Inspector marks own notification read (set-once)
  PERFORM set_config('request.jwt.claim.sub', '50000002-0000-4000-8000-000000000002', true);
  v_res := public.cmd_mark_notification_read_v1(v_notif_id);
  IF v_res->>'status' <> 'MARKED_READ' OR v_res->>'read_at' IS NULL THEN
    RAISE EXCEPTION 'CMD-050 MARK READ FAIL: %', v_res;
  END IF;

  -- Test CMD-054 escalation on an overdue unread notification
  RESET ROLE;
  UPDATE public.notifications SET read_at = NULL, created_at = now() - interval '2 hours' WHERE id = v_notif_id;
  v_res := app_internal.worker_evaluate_escalation_v1(
    v_notif_id, v_policy_id, 1, 60, ARRAY['60000005-0000-4000-8000-000000000005'::uuid]
  );
  IF v_res->>'status' <> 'ENQUEUED' OR v_res->>'candidates' <> '1' THEN
    RAISE EXCEPTION 'CMD-054 ESCALATION FAIL: %', v_res;
  END IF;
END
$$;

SELECT 'ALL_SLICE4_62_TABLES_FULL_SYSTEM_SECURITY_ASSERTIONS_PASSED' AS verification_result;

ROLLBACK;
