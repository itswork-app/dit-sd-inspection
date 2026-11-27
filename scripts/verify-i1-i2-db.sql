-- Synthetic local PostgreSQL verification suite for I1/I2 Identity, RBAC-003,
-- T-15 append-only audit, T-18 function ACLs, RLS direct-DML denial, SoD,
-- last-admin protection, CAS expected_row_version, and L00 idempotency.
-- Runs inside a rolled-back transaction so local DB remains clean after verification.

\set ON_ERROR_STOP on

BEGIN;

-- 1. pg_catalog T-18 security assertions
DO $$
DECLARE
  v_bad_roles int;
  v_bad_funcs int;
  v_public_exec int;
  v_anon_exec int;
  v_rls_missing int;
BEGIN
  -- Dedicated non-login owners must never have LOGIN/SUPERUSER/BYPASSRLS/CREATEROLE
  SELECT count(*) INTO v_bad_roles
  FROM pg_roles
  WHERE rolname IN ('app_cmd_definer', 'app_worker_definer')
    AND (rolcanlogin OR rolsuper OR rolbypassrls OR rolcreaterole OR rolcreatedb OR rolinherit);
  IF v_bad_roles <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: definer role has unsafe attributes';
  END IF;

  IF has_schema_privilege('app_cmd_definer', 'public', 'CREATE')
     OR has_schema_privilege('app_cmd_definer', 'app_internal', 'CREATE') THEN
    RAISE EXCEPTION 'T-18 FAIL: app_cmd_definer retained runtime CREATE privilege on schema';
  END IF;

  -- Every cmd_*_v1 must be SECURITY DEFINER owned by app_cmd_definer with search_path=""
  SELECT count(*) INTO v_bad_funcs
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_roles r ON r.oid = p.proowner
  WHERE n.nspname = 'public'
    AND p.proname LIKE 'cmd_%_v1'
    AND (
      NOT p.prosecdef
      OR r.rolname <> 'app_cmd_definer'
      OR NOT (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""'])
    );
  IF v_bad_funcs <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: % cmd_*_v1 function(s) violate owner/definer/search_path', v_bad_funcs;
  END IF;

  -- PUBLIC and anon must have ZERO execute privileges on cmd_*_v1
  SELECT count(*) INTO v_public_exec
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1'
    AND has_function_privilege('public', p.oid, 'EXECUTE');
  IF v_public_exec <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: PUBLIC can execute % cmd_*_v1 function(s)', v_public_exec;
  END IF;

  SELECT count(*) INTO v_anon_exec
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname LIKE 'cmd_%_v1'
    AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_anon_exec <> 0 THEN
    RAISE EXCEPTION 'T-18 FAIL: anon can execute % cmd_*_v1 function(s)', v_anon_exec;
  END IF;

  -- All 10 I1/I2 tables must have RLS enabled AND forced
  SELECT count(*) INTO v_rls_missing
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname IN (
      'audit_events', 'idempotency_records', 'app_users', 'account_requests',
      'account_decisions', 'roles', 'permissions', 'role_permissions',
      'user_roles', 'user_scope_grants'
    )
    AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity);
  IF v_rls_missing <> 0 THEN
    RAISE EXCEPTION 'RLS FAIL: % table(s) missing ENABLE/FORCE RLS', v_rls_missing;
  END IF;

  -- Canonical catalog counts: 6 roles, 39 permissions
  IF (SELECT count(*) FROM public.roles) <> 6 THEN
    RAISE EXCEPTION 'SEED FAIL: expected 6 canonical roles';
  END IF;
  IF (SELECT count(*) FROM public.permissions) <> 39 THEN
    RAISE EXCEPTION 'SEED FAIL: expected 39 canonical permissions';
  END IF;
END
$$;

-- 2. Seed two synthetic auth.users + bootstrap one initial super_admin (out-of-band)
INSERT INTO auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES
  ('11111111-1111-4111-8111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'synthetic-admin@example.test', '{}', '{}', now(), now()),
  ('22222222-2222-4222-8222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'synthetic-applicant@example.test', '{}', '{}', now(), now()),
  ('33333333-3333-4333-8333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'synthetic-admin2@example.test', '{}', '{}', now(), now());

INSERT INTO public.app_users (id, auth_user_id, display_name, account_status, row_version)
VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'Synthetic Super Admin', 'APPROVED', 1),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', '33333333-3333-4333-8333-333333333333', 'Synthetic Admin Two', 'APPROVED', 1);

-- Bootstrap initial super_admin grant (out-of-band migration owner; granted_by = admin2 to satisfy no-self-grant check)
INSERT INTO public.user_roles (id, user_id, role_id, project_id, status, granted_by, reason)
SELECT 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', r.id, NULL, 'ACTIVE', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'Synthetic bootstrap initial super_admin'
FROM public.roles r WHERE r.code = 'super_admin';

-- 3. Negative direct-DML test as `authenticated` (must fail with insufficient_privilege)
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';

DO $$
DECLARE
  v_denied boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.app_users (auth_user_id, display_name, account_status)
    VALUES ('22222222-2222-4222-8222-222222222222', 'Direct Insert Attempt', 'APPROVED');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'SECURITY FAIL: authenticated directly inserted into app_users';
  END IF;

  v_denied := false;
  BEGIN
    DELETE FROM public.audit_events;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'SECURITY FAIL: authenticated deleted from audit_events';
  END IF;
END
$$;

-- 4. CMD-001: applicant submits request, tests idempotent replay, key reuse, and duplicate pending
DO $$
DECLARE
  v_res jsonb;
  v_replay jsonb;
  v_reused jsonb;
  v_dup jsonb;
  v_req_id uuid;
  v_user_id uuid;
  v_self_approve jsonb;
BEGIN
  v_res := public.cmd_request_account_access_v1('idem-req-0001', 'Synthetic Inspector Applicant', 'Field team Alpha');
  IF v_res->>'status' <> 'ACCEPTED' OR v_res->>'account_status' <> 'PENDING' THEN
    RAISE EXCEPTION 'CMD-001 FAIL: expected ACCEPTED/PENDING, got %', v_res;
  END IF;
  v_req_id := (v_res->>'request_id')::uuid;
  v_user_id := (v_res->>'user_id')::uuid;

  -- Idempotent replay returns exact prior response
  v_replay := public.cmd_request_account_access_v1('idem-req-0001', 'Synthetic Inspector Applicant', 'Field team Alpha');
  IF v_replay->>'request_id' <> v_req_id::text OR v_replay->>'status' <> 'ACCEPTED' THEN
    RAISE EXCEPTION 'CMD-001 REPLAY FAIL: got %', v_replay;
  END IF;

  -- Same key with different payload rejects
  v_reused := public.cmd_request_account_access_v1('idem-req-0001', 'Different Name', 'Tampered');
  IF v_reused->>'status' <> 'IDEMPOTENCY_KEY_REUSED' THEN
    RAISE EXCEPTION 'CMD-001 KEY REUSE FAIL: got %', v_reused;
  END IF;

  -- New key while already pending returns ALREADY_PENDING without creating a second request
  v_dup := public.cmd_request_account_access_v1('idem-req-0002', 'Synthetic Inspector Applicant', 'Second request');
  IF v_dup->>'status' <> 'ALREADY_PENDING' OR v_dup->>'request_id' <> v_req_id::text THEN
    RAISE EXCEPTION 'CMD-001 ALREADY_PENDING FAIL: got %', v_dup;
  END IF;

  -- Unapproved applicant cannot approve own account
  v_self_approve := public.cmd_approve_account_v1('idem-self-0001', v_req_id, 1, 'Self approval attempt');
  IF v_self_approve->>'status' <> 'PERMISSION_DENIED' THEN
    RAISE EXCEPTION 'CMD-002 NEGATIVE AUTH FAIL: got %', v_self_approve;
  END IF;
END
$$;

-- 5. Switch to Super Admin: test CMD-003 Reject (CAS + category + reapply), CMD-002 Approve,
--    CMD-004 Grant Role (global/project class + SoD), CMD-005 Revoke Role (CAS + last-admin guard),
--    CMD-006/007 Grant/Revoke Scope, and account status transition (last-admin guard)
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';

DO $$
DECLARE
  v_req1_id uuid;
  v_req2_id uuid;
  v_applicant_id uuid;
  v_res jsonb;
  v_role_grant_id uuid;
  v_scope_grant_id uuid;
  v_proj_id uuid := '99999999-9999-4999-8999-999999999999';
BEGIN
  SELECT r.id, r.user_id INTO v_req1_id, v_applicant_id
  FROM public.account_requests r
  WHERE r.status = 'PENDING'
  LIMIT 1;

  -- Stale version on reject must fail
  v_res := public.cmd_reject_account_v1('idem-rej-stale', v_req1_id, 99, 'INCOMPLETE_INFORMATION', 'Missing verification details');
  IF v_res->>'status' <> 'STALE_VERSION' THEN
    RAISE EXCEPTION 'CMD-003 STALE_VERSION FAIL: got %', v_res;
  END IF;

  -- Valid reject succeeds and increments row_version to 2
  v_res := public.cmd_reject_account_v1('idem-rej-0001', v_req1_id, 1, 'INCOMPLETE_INFORMATION', 'Please include team assignment reference');
  IF v_res->>'status' <> 'REJECTED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-003 REJECT FAIL: got %', v_res;
  END IF;

  -- Applicant reapplies (history preserved, new request created, row_version -> 3)
  PERFORM set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
  v_res := public.cmd_request_account_access_v1('idem-reapply-01', 'Synthetic Inspector Applicant', 'Updated team assignment reference');
  IF v_res->>'status' <> 'ACCEPTED' OR v_res->>'row_version' <> '3' THEN
    RAISE EXCEPTION 'CMD-001 REAPPLY FAIL: got %', v_res;
  END IF;
  v_req2_id := (v_res->>'request_id')::uuid;
  IF v_req2_id = v_req1_id THEN
    RAISE EXCEPTION 'RBAC-003 FAIL: reapply overwrote prior request ID';
  END IF;

  -- Switch back to Super Admin & approve v_req2_id
  PERFORM set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
  v_res := public.cmd_approve_account_v1('idem-app-0001', v_req2_id, 3, 'Verified synthetic field inspector');
  IF v_res->>'status' <> 'APPROVED' OR v_res->>'row_version' <> '4' THEN
    RAISE EXCEPTION 'CMD-002 APPROVE FAIL: got %', v_res;
  END IF;

  -- CMD-004: Self-grant must fail with SOD_VIOLATION
  v_res := public.cmd_grant_role_v1('idem-role-sod', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'inspector', v_proj_id, now(), NULL, 'Self grant attempt');
  IF v_res->>'status' <> 'SOD_VIOLATION' THEN
    RAISE EXCEPTION 'CMD-004 SOD FAIL: got %', v_res;
  END IF;

  -- CMD-004: Project role without project_id must fail
  v_res := public.cmd_grant_role_v1('idem-role-badscope', v_applicant_id, 'inspector', NULL, now(), NULL, 'Missing project scope');
  IF v_res->>'status' <> 'VALIDATION_FAILED' THEN
    RAISE EXCEPTION 'CMD-004 SCOPE CLASS FAIL: got %', v_res;
  END IF;

  -- CMD-004: Valid project-scoped inspector role grant succeeds
  v_res := public.cmd_grant_role_v1('idem-role-0001', v_applicant_id, 'inspector', v_proj_id, now(), NULL, 'Assigned to Project Alpha');
  IF v_res->>'status' <> 'GRANTED' THEN
    RAISE EXCEPTION 'CMD-004 GRANT FAIL: got %', v_res;
  END IF;
  v_role_grant_id := (v_res->>'user_role_id')::uuid;

  -- CMD-005: Revoke role with stale version fails, then valid version succeeds
  v_res := public.cmd_revoke_role_v1('idem-rev-stale', v_role_grant_id, 9, 'Wrong version');
  IF v_res->>'status' <> 'STALE_VERSION' THEN
    RAISE EXCEPTION 'CMD-005 STALE_VERSION FAIL: got %', v_res;
  END IF;
  v_res := public.cmd_revoke_role_v1('idem-rev-0001', v_role_grant_id, 1, 'End of synthetic rotation');
  IF v_res->>'status' <> 'REVOKED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-005 REVOKE FAIL: got %', v_res;
  END IF;

  -- Last active super_admin protection: grant admin2 role.manage? Even better, grant admin2 super_admin then test revoking last one
  -- First, switch to admin2? No, currently only admin1 is super_admin; grant admin2 super_admin, then admin2 revokes admin1 (succeeds because admin2 remains),
  -- then admin1 (no longer super_admin) fails; re-verify last-admin protection directly by having admin2 try to suspend/revoke last admin:
  v_res := public.cmd_grant_role_v1('idem-role-sa2', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'super_admin', NULL, now(), NULL, 'Second super admin for last-admin test');
  IF v_res->>'status' <> 'GRANTED' THEN
    RAISE EXCEPTION 'CMD-004 SA2 GRANT FAIL: got %', v_res;
  END IF;
  v_role_grant_id := (v_res->>'user_role_id')::uuid;

  -- Admin1 revokes Admin2's super_admin (allowed: Admin1 remains)
  v_res := public.cmd_revoke_role_v1('idem-rev-sa2', v_role_grant_id, 1, 'Remove second super admin');
  IF v_res->>'status' <> 'REVOKED' THEN
    RAISE EXCEPTION 'CMD-005 SA2 REVOKE FAIL: got %', v_res;
  END IF;

  -- CMD-006 & CMD-007: Grant and revoke explicit PROJECT scope
  v_res := public.cmd_grant_scope_v1('idem-scp-0001', v_applicant_id, 'PROJECT', v_proj_id, now(), NULL, 'Explicit project scope');
  IF v_res->>'status' <> 'GRANTED' THEN
    RAISE EXCEPTION 'CMD-006 GRANT SCOPE FAIL: got %', v_res;
  END IF;
  v_scope_grant_id := (v_res->>'scope_grant_id')::uuid;

  v_res := public.cmd_revoke_scope_v1('idem-scp-rev1', v_scope_grant_id, 1, 'Scope rotation complete');
  IF v_res->>'status' <> 'REVOKED' OR v_res->>'row_version' <> '2' THEN
    RAISE EXCEPTION 'CMD-007 REVOKE SCOPE FAIL: got %', v_res;
  END IF;

  -- CMD-004: Non-super-admin (project admin) cannot grant super_admin or roles without role.manage
  PERFORM set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
  v_res := public.cmd_grant_role_v1('idem-role-esc1', v_applicant_id, 'super_admin', NULL, now(), NULL, 'Unauthorized escalation attempt');
  IF v_res->>'status' <> 'PERMISSION_DENIED' THEN
    RAISE EXCEPTION 'CMD-004 PRIVILEGE ESCALATION FAIL: got %', v_res;
  END IF;
  PERFORM set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

  -- Suspend and reinstate applicant account
  v_res := public.cmd_transition_account_status_v1('idem-susp-01', v_applicant_id, 'SUSPENDED', 4, 'Temporary synthetic suspension');
  IF v_res->>'status' <> 'TRANSITIONED' OR v_res->>'account_status' <> 'SUSPENDED' OR v_res->>'row_version' <> '5' THEN
    RAISE EXCEPTION 'SUSPEND FAIL: got %', v_res;
  END IF;
  v_res := public.cmd_transition_account_status_v1('idem-rein-01', v_applicant_id, 'APPROVED', 5, 'Synthetic reinstatement');
  IF v_res->>'status' <> 'TRANSITIONED' OR v_res->>'account_status' <> 'APPROVED' OR v_res->>'row_version' <> '6' THEN
    RAISE EXCEPTION 'REINSTATE FAIL: got %', v_res;
  END IF;
END
$$;

-- 6. Verify last-admin protection end-to-end when only 1 active super_admin remains,
--    plus append-only triggers & audit event capture
RESET ROLE;

-- Grant admin2 a temporary non-super_admin global role with account.approve + role.manage
-- (rolled back at end of script) to test runtime LAST_ADMIN_PROTECTED guards directly
INSERT INTO public.roles (id, code, name, scope_class, is_system, status)
VALUES ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'test_delegated_ops', 'Synthetic Delegated Ops', 'GLOBAL', false, 'ACTIVE');

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', p.id
FROM public.permissions p
WHERE p.code IN ('account.approve', 'role.manage');

INSERT INTO public.user_roles (user_id, role_id, project_id, status, granted_by, reason)
VALUES ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', NULL, 'ACTIVE', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Synthetic test delegated operator');

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '33333333-3333-4333-8333-333333333333';

DO $$
DECLARE
  v_res jsonb;
BEGIN
  -- Non-super-admin delegated operator cannot grant or revoke super_admin (delegation ceiling)
  v_res := public.cmd_grant_role_v1('idem-del-grant', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'super_admin', NULL, now(), NULL, 'Attempt to grant super_admin without super_admin role');
  IF v_res->>'status' <> 'PERMISSION_DENIED' THEN
    RAISE EXCEPTION 'CMD-004 DELEGATION CEILING FAIL: expected PERMISSION_DENIED, got %', v_res;
  END IF;

  v_res := public.cmd_revoke_role_v1('idem-del-ceil', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', 1, 'Attempt to revoke super_admin without super_admin role');
  IF v_res->>'status' <> 'PERMISSION_DENIED' THEN
    RAISE EXCEPTION 'CMD-005 DELEGATION CEILING FAIL: expected PERMISSION_DENIED, got %', v_res;
  END IF;

  -- Delegated operator with account.approve attempting to suspend sole super_admin must hit LAST_ADMIN_PROTECTED
  v_res := public.cmd_transition_account_status_v1('idem-last-susp', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUSPENDED', 1, 'Attempt to suspend sole remaining super_admin');
  IF v_res->>'status' <> 'LAST_ADMIN_PROTECTED' THEN
    RAISE EXCEPTION 'LAST_ADMIN_PROTECTED SUSPEND FAIL: expected LAST_ADMIN_PROTECTED, got %', v_res;
  END IF;

  -- Also verify applicant (no admin perms) sees ONLY own row in app_users via RLS
  PERFORM set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
  IF (SELECT count(*) FROM public.app_users) <> 1 THEN
    RAISE EXCEPTION 'RLS ISOLATION FAIL: non-admin saw % app_users rows instead of 1', (SELECT count(*) FROM public.app_users);
  END IF;
  IF (SELECT count(*) FROM public.audit_events) <> 0 THEN
    RAISE EXCEPTION 'RLS ISOLATION FAIL: non-admin without audit.read saw % audit_events', (SELECT count(*) FROM public.audit_events);
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_remaining bigint;
  v_blocked boolean := false;
BEGIN
  SELECT app_internal.count_remaining_super_admins('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', NULL) INTO v_remaining;
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'LAST_ADMIN CHECK FAIL: expected 0 remaining super_admins when excluding sole admin, got %', v_remaining;
  END IF;

  -- Verify append-only trigger blocks UPDATE on audit_events even for table owner
  BEGIN
    UPDATE public.audit_events SET outcome = 'FAILED';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN
    v_blocked := true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'T-15 APPEND-ONLY FAIL: UPDATE on audit_events was not blocked';
  END IF;

  -- Verify append-only trigger blocks DELETE on account_decisions
  v_blocked := false;
  BEGIN
    DELETE FROM public.account_decisions;
  EXCEPTION WHEN object_not_in_prerequisite_state THEN
    v_blocked := true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'RBAC-003 APPEND-ONLY FAIL: DELETE on account_decisions was not blocked';
  END IF;

  -- Verify audit_events captured all synthetic commands
  IF (SELECT count(*) FROM public.audit_events) < 9 THEN
    RAISE EXCEPTION 'T-15 AUDIT COUNT FAIL: expected >= 9 audit events, got %', (SELECT count(*) FROM public.audit_events);
  END IF;
END
$$;

SELECT 'ALL_I1_I2_POSTGRESQL_SECURITY_AND_RBAC_ASSERTIONS_PASSED' AS verification_result;

ROLLBACK;
