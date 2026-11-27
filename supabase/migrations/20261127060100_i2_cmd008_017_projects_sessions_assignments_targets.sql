-- Migration: 20261127060100_i2_cmd008_017_projects_sessions_assignments_targets.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for CMD-008..CMD-017
--        (+ scoped location/team configuration helpers under project.manage, and
--         T-14 capacity lock synchronization on CMD-004).
-- Authority: AGENTS.md v1.3.0, Command Catalogue v1.0.0, LOCK-GRAPH-001 v1.0.0,
--            CONCURRENCY-001 v1.0.0, T-06, T-07, T-14, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- ===========================================================================
-- CMD-008: create-project (project.manage) + initializes L10 capacity row
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_create_project_v1(
  p_idempotency_key text,
  p_code text,
  p_name text,
  p_timezone text DEFAULT 'Asia/Jakarta'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_code text;
  v_name text;
  v_tz text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_code := pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')));
  v_name := pg_catalog.btrim(coalesce(p_name, ''));
  v_tz := pg_catalog.btrim(coalesce(p_timezone, 'Asia/Jakarta'));

  IF v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'
     OR pg_catalog.char_length(v_name) NOT BETWEEN 2 AND 160
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = v_tz)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'code', v_code, 'name', v_name, 'timezone', v_tz
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-008', 'project_code:' || v_code, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    IF NOT app_internal.actor_has_permission(v_actor_id, 'project.manage', NULL) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'project.manage', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.projects (code, name, status, timezone, row_version, created_by)
    VALUES (v_code, v_name, 'ACTIVE', v_tz, 1, v_actor_id)
    RETURNING * INTO v_project;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008', 'status', 'DUPLICATE_CODE', 'server_time', pg_catalog.now());
  END;

  -- Initialize L10 capacity row atomically (T-14 default 50)
  INSERT INTO public.project_capacity_settings (project_id, inspector_cap, row_version, updated_by)
  VALUES (v_project.id, 50, 1, v_actor_id);

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'project.created', v_actor_id, v_auth_uid, 'CMD-008',
    'PROJECT', v_project.id, 'projects', v_project.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('code', v_project.code, 'timezone', v_project.timezone)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-008',
    'status', 'CREATED',
    'project_id', v_project.id,
    'code', v_project.code,
    'row_version', v_project.row_version::text,
    'inspector_cap', 50,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-008', 'project_code:' || v_code, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- Helper under CMD-008 family: create project location (project.manage)
CREATE OR REPLACE FUNCTION public.cmd_create_location_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_code text,
  p_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_code text;
  v_name text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_location public.locations%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_code := pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')));
  v_name := pg_catalog.btrim(coalesce(p_name, ''));
  IF p_project_id IS NULL OR v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,63}$' OR pg_catalog.char_length(v_name) NOT BETWEEN 2 AND 160 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object('v', 1, 'project_id', p_project_id, 'code', v_code, 'name', v_name)::text);
  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-008-LOC', 'project:' || p_project_id::text || ':loc:' || v_code, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L30 parent fence
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'project.manage', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.locations (project_id, code, name, status, row_version, created_by)
    VALUES (p_project_id, v_code, v_name, 'ACTIVE', 1, v_actor_id)
    RETURNING * INTO v_location;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-LOC', 'status', 'DUPLICATE_CODE', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'location.created', v_actor_id, v_auth_uid, 'CMD-008-LOC',
    'PROJECT', p_project_id, 'locations', v_location.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('code', v_location.code)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-008-LOC',
    'status', 'CREATED',
    'location_id', v_location.id,
    'project_id', p_project_id,
    'code', v_location.code,
    'row_version', v_location.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-008-LOC', 'project:' || p_project_id::text || ':loc:' || v_code, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- Helper under CMD-008 family: create project team (assignment.manage / project.manage)
CREATE OR REPLACE FUNCTION public.cmd_create_team_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_code text,
  p_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_code text;
  v_name text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_team public.teams%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_code := pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')));
  v_name := pg_catalog.btrim(coalesce(p_name, ''));
  IF p_project_id IS NULL OR v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,63}$' OR pg_catalog.char_length(v_name) NOT BETWEEN 2 AND 160 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object('v', 1, 'project_id', p_project_id, 'code', v_code, 'name', v_name)::text);
  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-008-TEAM', 'project:' || p_project_id::text || ':team:' || v_code, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT (
    app_internal.actor_has_permission(v_actor_id, 'assignment.manage', p_project_id)
    OR app_internal.actor_has_permission(v_actor_id, 'project.manage', p_project_id)
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.teams (project_id, code, name, status, row_version, created_by)
    VALUES (p_project_id, v_code, v_name, 'ACTIVE', 1, v_actor_id)
    RETURNING * INTO v_team;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-008-TEAM', 'status', 'DUPLICATE_CODE', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'team.created', v_actor_id, v_auth_uid, 'CMD-008-TEAM',
    'PROJECT', p_project_id, 'teams', v_team.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('code', v_team.code)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-008-TEAM',
    'status', 'CREATED',
    'team_id', v_team.id,
    'project_id', p_project_id,
    'code', v_team.code,
    'row_version', v_team.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-008-TEAM', 'project:' || p_project_id::text || ':team:' || v_code, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-009: update-project (project.manage, immutable code, CAS row_version)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_update_project_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_expected_row_version bigint,
  p_name text,
  p_timezone text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_name text;
  v_tz text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_name := pg_catalog.btrim(coalesce(p_name, ''));
  v_tz := nullif(pg_catalog.btrim(coalesce(p_timezone, '')), '');

  IF p_project_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_name) NOT BETWEEN 2 AND 160
     OR (v_tz IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = v_tz))
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'expected_row_version', p_expected_row_version::text,
    'name', v_name, 'timezone', v_tz
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-009', 'project:' || p_project_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L30 lock
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR NO KEY UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'project.manage', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  -- Prevent timezone reinterpretation if sessions already exist
  IF v_tz IS NOT NULL AND v_tz <> v_project.timezone
     AND EXISTS (SELECT 1 FROM public.sessions s WHERE s.project_id = p_project_id)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-009', 'status', 'STATE_CONFLICT', 'error_code', 'TIMEZONE_LOCKED_BY_SESSIONS', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.projects
  SET name = v_name,
      timezone = coalesce(v_tz, timezone),
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = p_project_id
  RETURNING * INTO v_project;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'project.updated', v_actor_id, v_auth_uid, 'CMD-009',
    'PROJECT', v_project.id, 'projects', v_project.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('row_version', v_project.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-009',
    'status', 'UPDATED',
    'project_id', v_project.id,
    'row_version', v_project.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-009', 'project:' || p_project_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-010: close-project (project.close, T-06 explicit final closure + fence)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_close_project_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_expected_row_version bigint,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_open_sessions integer;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_project_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-010', 'project:' || p_project_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L10 capacity -> L30 project -> L30 sessions in deterministic order
  PERFORM 1 FROM public.project_capacity_settings WHERE project_id = p_project_id FOR UPDATE;
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR NO KEY UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'project.close', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-010', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  PERFORM 1 FROM public.sessions WHERE project_id = p_project_id ORDER BY id ASC FOR SHARE;
  SELECT pg_catalog.count(*)::integer INTO v_open_sessions
  FROM public.sessions
  WHERE project_id = p_project_id AND status <> 'CLOSED';

  IF v_open_sessions > 0 THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-010',
      'status', 'CLOSURE_BLOCKED',
      'open_sessions', v_open_sessions,
      'server_time', pg_catalog.now()
    );
  END IF;

  UPDATE public.projects
  SET status = 'CLOSED',
      closed_at = pg_catalog.now(),
      closed_by = v_actor_id,
      close_reason = v_reason,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = p_project_id
  RETURNING * INTO v_project;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'project.closed', v_actor_id, v_auth_uid, 'CMD-010',
    'PROJECT', v_project.id, 'projects', v_project.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('reason', v_reason, 'row_version', v_project.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-010',
    'status', 'CLOSED',
    'project_id', v_project.id,
    'row_version', v_project.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-010', 'project:' || p_project_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-011: create-session (session.manage, always starts in T-07 DRAFT)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_create_session_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_code text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_code text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_code := pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')));
  IF p_project_id IS NULL OR v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'
     OR p_starts_at IS NULL OR p_ends_at IS NULL OR p_ends_at <= p_starts_at
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'code', v_code, 'starts_at', p_starts_at, 'ends_at', p_ends_at
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-011', 'project:' || p_project_id::text || ':session:' || v_code, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L30 project parent fence
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'session.manage', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.sessions (project_id, code, status, starts_at, ends_at, row_version, created_by)
    VALUES (p_project_id, v_code, 'DRAFT', p_starts_at, p_ends_at, 1, v_actor_id)
    RETURNING * INTO v_session;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-011', 'status', 'DUPLICATE_CODE', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'session.created', v_actor_id, v_auth_uid, 'CMD-011',
    'SESSION', v_session.id, 'sessions', v_session.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('project_id', p_project_id, 'code', v_session.code, 'status', 'DRAFT')
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-011',
    'status', 'CREATED',
    'session_id', v_session.id,
    'project_id', p_project_id,
    'session_status', v_session.status,
    'row_version', v_session.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-011', 'project:' || p_project_id::text || ':session:' || v_code, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-012: update-session (session.manage, immutable code, blocks schedule edit if work exists)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_update_session_v1(
  p_idempotency_key text,
  p_session_id uuid,
  p_expected_row_version bigint,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_session_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR p_starts_at IS NULL OR p_ends_at IS NULL OR p_ends_at <= p_starts_at
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'session_id', p_session_id, 'expected_row_version', p_expected_row_version::text,
    'starts_at', p_starts_at, 'ends_at', p_ends_at, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-012', 'session:' || p_session_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- L30 parent project FOR SHARE -> session FOR NO KEY UPDATE
  SELECT * INTO v_project FROM public.projects WHERE id = v_session.project_id FOR SHARE;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR NO KEY UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'session.manage', v_session.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' OR v_session.status = 'CLOSED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_session.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  IF EXISTS (SELECT 1 FROM public.operational_assignments oa WHERE oa.session_id = p_session_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-012', 'status', 'STATE_CONFLICT', 'error_code', 'SCHEDULE_LOCKED_BY_ASSIGNMENTS', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.sessions
  SET starts_at = p_starts_at,
      ends_at = p_ends_at,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = p_session_id
  RETURNING * INTO v_session;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'session.updated', v_actor_id, v_auth_uid, 'CMD-012',
    'SESSION', v_session.id, 'sessions', v_session.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('reason', v_reason, 'row_version', v_session.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-012',
    'status', 'UPDATED',
    'session_id', v_session.id,
    'row_version', v_session.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-012', 'session:' || p_session_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-013: transition-session (session.transition, T-07 states & ceilings)
-- Actions: ACTIVATE | PAUSE | RESUME | REQUEST_CLOSE | CLOSE | REOPEN
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_transition_session_v1(
  p_idempotency_key text,
  p_session_id uuid,
  p_action text,
  p_expected_row_version bigint,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_target_status text;
  v_event_type text;
  v_is_global_authority boolean;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_session_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR p_action NOT IN ('ACTIVATE', 'PAUSE', 'RESUME', 'REQUEST_CLOSE', 'CLOSE', 'REOPEN')
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'session_id', p_session_id, 'action', p_action,
    'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-013', 'session:' || p_session_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- L30 parent project FOR SHARE -> session FOR NO KEY UPDATE
  SELECT * INTO v_project FROM public.projects WHERE id = v_session.project_id FOR SHARE;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR NO KEY UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'session.transition', v_session.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- Role ceiling: final CLOSE and privileged REOPEN require global session.transition (Super Admin)
  v_is_global_authority := app_internal.actor_has_permission(v_actor_id, 'session.transition', NULL);
  IF p_action IN ('CLOSE', 'REOPEN') AND NOT v_is_global_authority THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_session.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  IF p_action = 'ACTIVATE' THEN
    IF v_session.status <> 'DRAFT' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := 'ACTIVE';
    v_event_type := 'session.activated';
  ELSIF p_action = 'PAUSE' THEN
    IF v_session.status <> 'ACTIVE' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := 'PAUSED';
    v_event_type := 'session.paused';
  ELSIF p_action = 'RESUME' THEN
    IF v_session.status <> 'PAUSED' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := 'ACTIVE';
    v_event_type := 'session.resumed';
  ELSIF p_action = 'REQUEST_CLOSE' THEN
    -- T-07: REQUEST_CLOSE is an action/event only, never a persisted session state
    IF v_session.status NOT IN ('ACTIVE', 'PAUSED') THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := v_session.status;
    v_event_type := 'session.close_requested';
  ELSIF p_action = 'CLOSE' THEN
    IF v_session.status NOT IN ('ACTIVE', 'PAUSED') THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := 'CLOSED';
    v_event_type := 'session.closed';
  ELSIF p_action = 'REOPEN' THEN
    IF v_session.status <> 'CLOSED' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-013', 'status', 'INVALID_STATE_TRANSITION', 'server_time', pg_catalog.now());
    END IF;
    v_target_status := 'ACTIVE';
    v_event_type := 'session.reopened';
  END IF;

  UPDATE public.sessions
  SET status = v_target_status,
      started_at = CASE WHEN p_action = 'ACTIVATE' AND started_at IS NULL THEN pg_catalog.now() ELSE started_at END,
      closed_at = CASE WHEN p_action = 'CLOSE' THEN pg_catalog.now() ELSE closed_at END,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = p_session_id
  RETURNING * INTO v_session;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    v_event_type, v_actor_id, v_auth_uid, 'CMD-013',
    'SESSION', v_session.id, 'sessions', v_session.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('action', p_action, 'session_status', v_session.status, 'reason', v_reason, 'row_version', v_session.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-013',
    'status', 'TRANSITIONED',
    'session_id', v_session.id,
    'action', p_action,
    'session_status', v_session.status,
    'row_version', v_session.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-013', 'session:' || p_session_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-014: publish-assignment (assignment.manage, atomic initial roster,
--          cross-location Inspector overlap check, T-14 capacity enforcement)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_publish_assignment_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_session_id uuid,
  p_location_id uuid,
  p_instrument_id uuid,
  p_instrument_version_id uuid,
  p_team_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_members jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_req_hash text;
  v_idem jsonb;
  v_cap public.project_capacity_settings%ROWTYPE;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_instrument public.instruments%ROWTYPE;
  v_version public.instrument_versions%ROWTYPE;
  v_assignment public.operational_assignments%ROWTYPE;
  v_member jsonb;
  v_member_user_id uuid;
  v_member_role text;
  v_member_user public.app_users%ROWTYPE;
  v_overlap_exists boolean;
  v_qualifying_count integer;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_project_id IS NULL OR p_session_id IS NULL OR p_location_id IS NULL
     OR p_instrument_id IS NULL OR p_instrument_version_id IS NULL OR p_team_id IS NULL
     OR p_starts_at IS NULL OR p_ends_at IS NULL OR p_ends_at <= p_starts_at
     OR p_members IS NULL OR pg_catalog.jsonb_typeof(p_members) <> 'array'
     OR pg_catalog.jsonb_array_length(p_members) < 1 OR pg_catalog.jsonb_array_length(p_members) > 50
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'session_id', p_session_id,
    'location_id', p_location_id, 'instrument_id', p_instrument_id,
    'instrument_version_id', p_instrument_version_id, 'team_id', p_team_id,
    'starts_at', p_starts_at, 'ends_at', p_ends_at, 'members', p_members
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-014', 'session:' || p_session_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L10 capacity serialization row first (T-14)
  SELECT * INTO v_cap FROM public.project_capacity_settings WHERE project_id = p_project_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- L15 lock actor + all proposed member accounts in deterministic UUID order
  PERFORM 1
  FROM public.app_users u
  WHERE u.id = v_actor_id
     OR u.id IN (SELECT (elem->>'user_id')::uuid FROM pg_catalog.jsonb_array_elements(p_members) AS elem WHERE elem->>'user_id' ~ '^[0-9a-fA-F-]{36}$')
  ORDER BY u.id ASC
  FOR SHARE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'assignment.manage', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- L30 parent project + session FOR SHARE
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id AND project_id = p_project_id FOR SHARE;
  IF NOT FOUND OR v_project.status <> 'ACTIVE' OR v_session.status = 'CLOSED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- L40 instrument + published version FOR SHARE (T-17)
  SELECT * INTO v_instrument FROM public.instruments WHERE id = p_instrument_id FOR SHARE;
  SELECT * INTO v_version FROM public.instrument_versions WHERE id = p_instrument_version_id AND instrument_id = p_instrument_id FOR SHARE;
  IF NOT FOUND OR v_instrument.status <> 'ACTIVE' OR v_version.status <> 'PUBLISHED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'STATE_CONFLICT', 'error_code', 'INSTRUMENT_NOT_SELECTABLE', 'server_time', pg_catalog.now());
  END IF;

  -- L50 verify location & team belong to project and are ACTIVE
  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE id = p_location_id AND project_id = p_project_id AND status = 'ACTIVE')
     OR NOT EXISTS (SELECT 1 FROM public.teams WHERE id = p_team_id AND project_id = p_project_id AND status = 'ACTIVE')
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  -- Create L50 assignment
  INSERT INTO public.operational_assignments (
    project_id, session_id, location_id, instrument_id, instrument_version_id,
    team_id, starts_at, ends_at, status, row_version, created_by
  ) VALUES (
    p_project_id, p_session_id, p_location_id, p_instrument_id, p_instrument_version_id,
    p_team_id, p_starts_at, p_ends_at, 'PUBLISHED', 1, v_actor_id
  )
  RETURNING * INTO v_assignment;

  -- Validate & insert L55 initial roster atomically
  FOR v_member IN SELECT * FROM pg_catalog.jsonb_array_elements(p_members)
  LOOP
    IF coalesce(v_member->>'user_id', '') !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
       OR coalesce(v_member->>'operational_role', '') NOT IN ('korlap', 'reviewer', 'inspector', 'print_officer')
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    v_member_user_id := (v_member->>'user_id')::uuid;
    v_member_role := v_member->>'operational_role';

    IF v_member_user_id = v_actor_id THEN
      RAISE EXCEPTION 'SOD_VIOLATION' USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_member_user FROM public.app_users WHERE id = v_member_user_id;
    IF NOT FOUND OR v_member_user.account_status <> 'APPROVED' THEN
      RAISE EXCEPTION 'ACCOUNT_NOT_ELIGIBLE' USING ERRCODE = 'P0003';
    END IF;

    -- Member must hold matching active project role
    IF NOT EXISTS (
      SELECT 1
      FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id AND r.code = v_member_role AND r.status = 'ACTIVE'
      WHERE ur.user_id = v_member_user_id
        AND ur.project_id = p_project_id
        AND ur.status = 'ACTIVE'
        AND ur.valid_from <= pg_catalog.now()
        AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
    ) THEN
      RAISE EXCEPTION 'MEMBER_ROLE_MISSING' USING ERRCODE = 'P0004';
    END IF;

    -- Cross-location half-open [starts_at, ends_at) Inspector overlap check
    IF v_member_role = 'inspector' THEN
      SELECT EXISTS (
        SELECT 1
        FROM public.assignment_members am
        JOIN public.operational_assignments oa ON oa.id = am.assignment_id
        WHERE am.user_id = v_member_user_id
          AND am.operational_role = 'inspector'
          AND am.status = 'ACTIVE'
          AND oa.status = 'PUBLISHED'
          AND oa.id <> v_assignment.id
          AND oa.location_id <> p_location_id
          AND oa.starts_at < p_ends_at
          AND p_starts_at < oa.ends_at
      ) INTO v_overlap_exists;

      IF v_overlap_exists THEN
        RAISE EXCEPTION 'ASSIGNMENT_OVERLAP' USING ERRCODE = 'P0005';
      END IF;
    END IF;

    INSERT INTO public.assignment_members (
      assignment_id, project_id, user_id, operational_role, valid_from, status, added_by, row_version
    ) VALUES (
      v_assignment.id, p_project_id, v_member_user_id, v_member_role, pg_catalog.now(), 'ACTIVE', v_actor_id, 1
    );
  END LOOP;

  -- Enforce T-14 combined project Inspector capacity atomically under L10 lock
  v_qualifying_count := app_internal.count_qualifying_inspectors(p_project_id);
  IF v_qualifying_count > v_cap.inspector_cap THEN
    RAISE EXCEPTION 'CAPACITY_EXCEEDED' USING ERRCODE = 'P0006';
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'assignment.created', v_actor_id, v_auth_uid, 'CMD-014',
    'ASSIGNMENT', v_assignment.id, 'operational_assignments', v_assignment.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object(
      'project_id', p_project_id, 'session_id', p_session_id,
      'location_id', p_location_id, 'instrument_version_id', p_instrument_version_id,
      'member_count', pg_catalog.jsonb_array_length(p_members),
      'qualifying_inspectors', v_qualifying_count
    )
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-014',
    'status', 'PUBLISHED',
    'assignment_id', v_assignment.id,
    'project_id', p_project_id,
    'session_id', p_session_id,
    'qualifying_inspectors', v_qualifying_count,
    'row_version', v_assignment.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-014', 'session:' || p_session_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0002' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0003' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0004' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'STATE_CONFLICT', 'error_code', 'MEMBER_ROLE_MISSING', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0005' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'ASSIGNMENT_OVERLAP', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0006' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'CAPACITY_EXCEEDED', 'server_time', pg_catalog.now());
  WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-014', 'status', 'VALIDATION_FAILED', 'error_code', 'DUPLICATE_MEMBER', 'server_time', pg_catalog.now());
END;
$$;

-- ===========================================================================
-- CMD-015: change-assignment-members (assignment.manage, soft-end history, T-14)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_change_assignment_members_v1(
  p_idempotency_key text,
  p_assignment_id uuid,
  p_add_members jsonb DEFAULT '[]'::jsonb,
  p_end_member_ids uuid[] DEFAULT ARRAY[]::uuid[],
  p_reason text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_assignment public.operational_assignments%ROWTYPE;
  v_cap public.project_capacity_settings%ROWTYPE;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_member jsonb;
  v_member_user_id uuid;
  v_member_role text;
  v_end_id uuid;
  v_end_row public.assignment_members%ROWTYPE;
  v_qualifying_count integer;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_assignment_id IS NULL
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 500
     OR p_add_members IS NULL OR pg_catalog.jsonb_typeof(p_add_members) <> 'array'
     OR (pg_catalog.jsonb_array_length(p_add_members) = 0 AND coalesce(pg_catalog.array_length(p_end_member_ids, 1), 0) = 0)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'assignment_id', p_assignment_id, 'add', p_add_members, 'end', p_end_member_ids, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-015', 'assignment:' || p_assignment_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_assignment FROM public.operational_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- L10 capacity -> L30 project/session -> L50 assignment
  SELECT * INTO v_cap FROM public.project_capacity_settings WHERE project_id = v_assignment.project_id FOR UPDATE;
  SELECT * INTO v_project FROM public.projects WHERE id = v_assignment.project_id FOR SHARE;
  SELECT * INTO v_session FROM public.sessions WHERE id = v_assignment.session_id FOR SHARE;
  SELECT * INTO v_assignment FROM public.operational_assignments WHERE id = p_assignment_id FOR UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'assignment.manage', v_assignment.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' OR v_session.status = 'CLOSED' OR v_assignment.status <> 'PUBLISHED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- End specified active memberships (soft-end history, never DELETE)
  FOREACH v_end_id IN ARRAY coalesce(p_end_member_ids, ARRAY[]::uuid[])
  LOOP
    SELECT * INTO v_end_row FROM public.assignment_members
    WHERE id = v_end_id AND assignment_id = p_assignment_id FOR UPDATE;
    IF NOT FOUND OR v_end_row.status <> 'ACTIVE' THEN
      RAISE EXCEPTION 'STATE_CONFLICT' USING ERRCODE = 'P0004';
    END IF;
    UPDATE public.assignment_members
    SET status = 'ENDED',
        valid_until = pg_catalog.now(),
        ended_by = v_actor_id,
        end_reason = v_reason,
        row_version = row_version + 1,
        updated_at = pg_catalog.now()
    WHERE id = v_end_id;
  END LOOP;

  -- Add new members
  FOR v_member IN SELECT * FROM pg_catalog.jsonb_array_elements(p_add_members)
  LOOP
    IF coalesce(v_member->>'user_id', '') !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
       OR coalesce(v_member->>'operational_role', '') NOT IN ('korlap', 'reviewer', 'inspector', 'print_officer')
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;
    v_member_user_id := (v_member->>'user_id')::uuid;
    v_member_role := v_member->>'operational_role';

    IF v_member_user_id = v_actor_id THEN
      RAISE EXCEPTION 'SOD_VIOLATION' USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.app_users WHERE id = v_member_user_id AND account_status = 'APPROVED') THEN
      RAISE EXCEPTION 'ACCOUNT_NOT_ELIGIBLE' USING ERRCODE = 'P0003';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id AND r.code = v_member_role AND r.status = 'ACTIVE'
      WHERE ur.user_id = v_member_user_id AND ur.project_id = v_assignment.project_id
        AND ur.status = 'ACTIVE' AND ur.valid_from <= pg_catalog.now()
        AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
    ) THEN
      RAISE EXCEPTION 'MEMBER_ROLE_MISSING' USING ERRCODE = 'P0004';
    END IF;

    IF v_member_role = 'inspector' AND EXISTS (
      SELECT 1
      FROM public.assignment_members am
      JOIN public.operational_assignments oa ON oa.id = am.assignment_id
      WHERE am.user_id = v_member_user_id
        AND am.operational_role = 'inspector'
        AND am.status = 'ACTIVE'
        AND oa.status = 'PUBLISHED'
        AND oa.id <> v_assignment.id
        AND oa.location_id <> v_assignment.location_id
        AND oa.starts_at < v_assignment.ends_at
        AND v_assignment.starts_at < oa.ends_at
    ) THEN
      RAISE EXCEPTION 'ASSIGNMENT_OVERLAP' USING ERRCODE = 'P0005';
    END IF;

    INSERT INTO public.assignment_members (
      assignment_id, project_id, user_id, operational_role, valid_from, status, added_by, row_version
    ) VALUES (
      p_assignment_id, v_assignment.project_id, v_member_user_id, v_member_role, pg_catalog.now(), 'ACTIVE', v_actor_id, 1
    );
  END LOOP;

  -- Re-check T-14 combined project capacity atomically
  v_qualifying_count := app_internal.count_qualifying_inspectors(v_assignment.project_id);
  IF v_qualifying_count > v_cap.inspector_cap THEN
    RAISE EXCEPTION 'CAPACITY_EXCEEDED' USING ERRCODE = 'P0006';
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'assignment.changed', v_actor_id, v_auth_uid, 'CMD-015',
    'ASSIGNMENT', p_assignment_id, 'assignment_members', p_assignment_id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('reason', v_reason, 'qualifying_inspectors', v_qualifying_count)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-015',
    'status', 'UPDATED',
    'assignment_id', p_assignment_id,
    'qualifying_inspectors', v_qualifying_count,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-015', 'assignment:' || p_assignment_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0002' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0003' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0004' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0005' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'ASSIGNMENT_OVERLAP', 'server_time', pg_catalog.now());
  WHEN SQLSTATE 'P0006' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'CAPACITY_EXCEEDED', 'server_time', pg_catalog.now());
  WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-015', 'status', 'STATE_CONFLICT', 'error_code', 'DUPLICATE_ACTIVE_MEMBER', 'server_time', pg_catalog.now());
END;
$$;

-- ===========================================================================
-- CMD-016: change-inspector-capacity (capacity.manage, T-14 1..100, never below count)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_change_inspector_capacity_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_inspector_cap integer,
  p_expected_row_version bigint,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_cap public.project_capacity_settings%ROWTYPE;
  v_current_count integer;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_project_id IS NULL OR p_inspector_cap IS NULL OR p_inspector_cap NOT BETWEEN 1 AND 100
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 500
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'inspector_cap', p_inspector_cap,
    'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-016', 'project_cap:' || p_project_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L10 serialization lock
  SELECT * INTO v_cap FROM public.project_capacity_settings WHERE project_id = p_project_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'capacity.manage', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_cap.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-016', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  v_current_count := app_internal.count_qualifying_inspectors(p_project_id);
  IF p_inspector_cap < v_current_count THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-016',
      'status', 'CAPACITY_BELOW_CURRENT_COUNT',
      'current_qualifying_count', v_current_count,
      'requested_cap', p_inspector_cap,
      'server_time', pg_catalog.now()
    );
  END IF;

  UPDATE public.project_capacity_settings
  SET inspector_cap = p_inspector_cap,
      row_version = row_version + 1,
      updated_by = v_actor_id,
      updated_at = pg_catalog.now()
  WHERE project_id = p_project_id
  RETURNING * INTO v_cap;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'capacity.limit_changed', v_actor_id, v_auth_uid, 'CMD-016',
    'PROJECT', p_project_id, 'project_capacity_settings', p_project_id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspector_cap', v_cap.inspector_cap, 'current_qualifying_count', v_current_count, 'reason', v_reason, 'row_version', v_cap.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-016',
    'status', 'UPDATED',
    'project_id', p_project_id,
    'inspector_cap', v_cap.inspector_cap,
    'current_qualifying_count', v_current_count,
    'row_version', v_cap.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-016', 'project_cap:' || p_project_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-017: manage-target-plan (target.manage, session-scoped, immutable published)
-- Actions: CREATE_DRAFT | REPLACE_DRAFT_ALLOCATIONS | PUBLISH
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_manage_target_plan_v1(
  p_idempotency_key text,
  p_session_id uuid,
  p_action text,
  p_plan_id uuid DEFAULT NULL,
  p_expected_row_version bigint DEFAULT NULL,
  p_allocations jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_req_hash text;
  v_idem jsonb;
  v_session public.sessions%ROWTYPE;
  v_plan public.target_plans%ROWTYPE;
  v_next_version integer;
  v_alloc jsonb;
  v_alloc_assignment_id uuid;
  v_alloc_date date;
  v_alloc_qty integer;
  v_event_type text;
  v_status text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_session_id IS NULL OR p_action NOT IN ('CREATE_DRAFT', 'REPLACE_DRAFT_ALLOCATIONS', 'PUBLISH') THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'session_id', p_session_id, 'action', p_action,
    'plan_id', p_plan_id, 'expected_row_version', p_expected_row_version, 'allocations', p_allocations
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-017', 'session:' || p_session_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'target.manage', v_session.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF p_action = 'CREATE_DRAFT' THEN
    SELECT coalesce(pg_catalog.max(version), 0) + 1 INTO v_next_version
    FROM public.target_plans WHERE session_id = p_session_id;

    INSERT INTO public.target_plans (project_id, session_id, version, status, row_version, created_by)
    VALUES (v_session.project_id, p_session_id, v_next_version, 'DRAFT', 1, v_actor_id)
    RETURNING * INTO v_plan;

    v_event_type := 'target.created';
    v_status := 'DRAFTED';
  ELSE
    IF p_plan_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
    END IF;

    SELECT * INTO v_plan FROM public.target_plans WHERE id = p_plan_id AND session_id = p_session_id FOR UPDATE;
    IF NOT FOUND THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
    END IF;

    IF v_plan.status <> 'DRAFT' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'IMMUTABLE', 'server_time', pg_catalog.now());
    END IF;

    IF v_plan.row_version <> p_expected_row_version THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
    END IF;

    IF p_action = 'REPLACE_DRAFT_ALLOCATIONS' THEN
      IF p_allocations IS NULL OR pg_catalog.jsonb_typeof(p_allocations) <> 'array' THEN
        RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
      END IF;

      DELETE FROM public.target_allocations WHERE target_plan_id = v_plan.id;

      FOR v_alloc IN SELECT * FROM pg_catalog.jsonb_array_elements(p_allocations)
      LOOP
        IF coalesce(v_alloc->>'assignment_id', '') !~ '^[0-9a-fA-F-]{36}$'
           OR coalesce(v_alloc->>'target_date', '') !~ '^\d{4}-\d{2}-\d{2}$'
           OR coalesce(v_alloc->>'quantity', '') !~ '^[1-9]\d{0,5}$'
        THEN
          RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
        END IF;

        v_alloc_assignment_id := (v_alloc->>'assignment_id')::uuid;
        v_alloc_date := (v_alloc->>'target_date')::date;
        v_alloc_qty := (v_alloc->>'quantity')::integer;

        IF NOT EXISTS (
          SELECT 1 FROM public.operational_assignments oa
          WHERE oa.id = v_alloc_assignment_id AND oa.session_id = p_session_id
        ) THEN
          RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
        END IF;

        INSERT INTO public.target_allocations (target_plan_id, assignment_id, target_date, quantity)
        VALUES (v_plan.id, v_alloc_assignment_id, v_alloc_date, v_alloc_qty);
      END LOOP;

      UPDATE public.target_plans
      SET row_version = row_version + 1, updated_at = pg_catalog.now()
      WHERE id = v_plan.id
      RETURNING * INTO v_plan;

      v_event_type := 'target.reallocated';
      v_status := 'UPDATED';
    ELSE
      -- PUBLISH
      IF NOT EXISTS (SELECT 1 FROM public.target_allocations WHERE target_plan_id = v_plan.id) THEN
        RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'error_code', 'EMPTY_ALLOCATIONS', 'server_time', pg_catalog.now());
      END IF;

      UPDATE public.target_plans
      SET status = 'SUPERSEDED', row_version = row_version + 1, updated_at = pg_catalog.now()
      WHERE session_id = p_session_id AND status = 'PUBLISHED';

      UPDATE public.target_plans
      SET status = 'PUBLISHED',
          published_by = v_actor_id,
          published_at = pg_catalog.now(),
          row_version = row_version + 1,
          updated_at = pg_catalog.now()
      WHERE id = v_plan.id
      RETURNING * INTO v_plan;

      v_event_type := 'target.version_published';
      v_status := 'PUBLISHED';
    END IF;
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    v_event_type, v_actor_id, v_auth_uid, 'CMD-017',
    'SESSION', p_session_id, 'target_plans', v_plan.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('action', p_action, 'version', v_plan.version, 'status', v_plan.status, 'row_version', v_plan.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-017',
    'status', v_status,
    'plan_id', v_plan.id,
    'version', v_plan.version,
    'plan_status', v_plan.status,
    'row_version', v_plan.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-017', 'session:' || p_session_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-017', 'status', 'VALIDATION_FAILED', 'error_code', 'DUPLICATE_ALLOCATION_KEY', 'server_time', pg_catalog.now());
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_create_project_v1(text, text, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_project_v1(text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_project_v1(text, text, text, text) TO authenticated;

ALTER FUNCTION public.cmd_create_location_v1(text, uuid, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_location_v1(text, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_location_v1(text, uuid, text, text) TO authenticated;

ALTER FUNCTION public.cmd_create_team_v1(text, uuid, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_team_v1(text, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_team_v1(text, uuid, text, text) TO authenticated;

ALTER FUNCTION public.cmd_update_project_v1(text, uuid, bigint, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_update_project_v1(text, uuid, bigint, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_update_project_v1(text, uuid, bigint, text, text) TO authenticated;

ALTER FUNCTION public.cmd_close_project_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_close_project_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_close_project_v1(text, uuid, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_create_session_v1(text, uuid, text, timestamptz, timestamptz) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_session_v1(text, uuid, text, timestamptz, timestamptz) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_session_v1(text, uuid, text, timestamptz, timestamptz) TO authenticated;

ALTER FUNCTION public.cmd_update_session_v1(text, uuid, bigint, timestamptz, timestamptz, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_update_session_v1(text, uuid, bigint, timestamptz, timestamptz, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_update_session_v1(text, uuid, bigint, timestamptz, timestamptz, text) TO authenticated;

ALTER FUNCTION public.cmd_transition_session_v1(text, uuid, text, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_transition_session_v1(text, uuid, text, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_transition_session_v1(text, uuid, text, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_publish_assignment_v1(text, uuid, uuid, uuid, uuid, uuid, uuid, timestamptz, timestamptz, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_publish_assignment_v1(text, uuid, uuid, uuid, uuid, uuid, uuid, timestamptz, timestamptz, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_publish_assignment_v1(text, uuid, uuid, uuid, uuid, uuid, uuid, timestamptz, timestamptz, jsonb) TO authenticated;

ALTER FUNCTION public.cmd_change_assignment_members_v1(text, uuid, jsonb, uuid[], text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_change_assignment_members_v1(text, uuid, jsonb, uuid[], text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_change_assignment_members_v1(text, uuid, jsonb, uuid[], text) TO authenticated;

ALTER FUNCTION public.cmd_change_inspector_capacity_v1(text, uuid, integer, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_change_inspector_capacity_v1(text, uuid, integer, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_change_inspector_capacity_v1(text, uuid, integer, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_manage_target_plan_v1(text, uuid, text, uuid, bigint, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_manage_target_plan_v1(text, uuid, text, uuid, bigint, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_manage_target_plan_v1(text, uuid, text, uuid, bigint, jsonb) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
