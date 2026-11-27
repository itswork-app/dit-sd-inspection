-- Migration: 20261127050200_i2_cmd001_007_t18_command_wrappers.sql
-- Scope: I2 Privileged Command Runtime — T-18 Option A narrow SECURITY DEFINER
--        wrappers for CMD-001 through CMD-007 + account status transitions.
-- Invariants:
--   * Dedicated NOLOGIN NOBYPASSRLS owner: app_cmd_definer
--   * Fixed SET search_path = '' and fully schema-qualified references
--   * Exact-signature EXECUTE grants to authenticated only (PUBLIC/anon revoked)
--   * Caller identity strictly derived from auth.uid()
--   * L00 idempotency + strictly ascending L15 -> L16 -> L17 -> L100 -> L110 locks
--   * Atomic business mutation + audit_events append + idempotency_records
--   * Hard SoD (actor != target), grantor delegation ceiling, last-admin guard,
--     and expected_row_version CAS (CONCURRENCY-001 v1.0.0).

-- Temporarily grant CREATE during migration DDL so ALTER FUNCTION ... OWNER TO app_cmd_definer
-- succeeds under PostgreSQL 16 non-superuser migration roles; revoked at end of migration.
GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- Ensure SHA-256 helper availability via pgcrypto or built-in sha256() (PG 11+)
CREATE OR REPLACE FUNCTION app_internal.sha256_hex(p_input text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(p_input, 'UTF8')), 'hex');
$$;

ALTER FUNCTION app_internal.sha256_hex(text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.sha256_hex(text) FROM PUBLIC, anon, authenticated;

-- Internal helper: validate idempotency key & check replay (L00)
CREATE OR REPLACE FUNCTION app_internal.check_idempotency(
  p_actor_auth_uid uuid,
  p_command_id text,
  p_resource_scope text,
  p_idempotency_key text,
  p_request_hash text
)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_key_hash text;
  v_existing public.idempotency_records%ROWTYPE;
BEGIN
  IF p_idempotency_key IS NULL OR pg_catalog.char_length(pg_catalog.btrim(p_idempotency_key)) NOT BETWEEN 8 AND 128 THEN
    RETURN pg_catalog.jsonb_build_object(
      'status', 'ERROR',
      'error_code', 'VALIDATION_FAILED',
      'message', 'Idempotency key must be 8..128 characters.'
    );
  END IF;

  v_key_hash := app_internal.sha256_hex(p_idempotency_key);

  SELECT *
  INTO v_existing
  FROM public.idempotency_records r
  WHERE r.actor_auth_uid = p_actor_auth_uid
    AND r.command_id = p_command_id
    AND r.resource_scope = p_resource_scope
    AND r.idempotency_key_hash = v_key_hash;

  IF FOUND THEN
    IF v_existing.request_hash <> p_request_hash THEN
      RETURN pg_catalog.jsonb_build_object(
        'status', 'ERROR',
        'error_code', 'IDEMPOTENCY_KEY_REUSED',
        'message', 'Idempotency key was already used with a different request payload.'
      );
    END IF;
    RETURN pg_catalog.jsonb_build_object(
      'status', 'REPLAY',
      'response', v_existing.response_payload
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'status', 'NEW',
    'key_hash', v_key_hash
  );
END;
$$;

ALTER FUNCTION app_internal.check_idempotency(uuid, text, text, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.check_idempotency(uuid, text, text, text, text) FROM PUBLIC, anon, authenticated;

-- Internal helper: check whether actor has a specific permission (global or project-scoped)
CREATE OR REPLACE FUNCTION app_internal.actor_has_permission(
  p_actor_user_id uuid,
  p_permission_code text,
  p_project_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_users u
    JOIN public.user_roles ur
      ON ur.user_id = u.id
      AND ur.status = 'ACTIVE'
      AND ur.valid_from <= pg_catalog.now()
      AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
    JOIN public.roles r
      ON r.id = ur.role_id
      AND r.status = 'ACTIVE'
    JOIN public.role_permissions rp ON rp.role_id = r.id
    JOIN public.permissions p ON p.id = rp.permission_id
    WHERE u.id = p_actor_user_id
      AND u.account_status = 'APPROVED'
      AND p.code = p_permission_code
      AND (
        (r.scope_class = 'GLOBAL' AND ur.project_id IS NULL)
        OR (r.scope_class = 'PROJECT' AND p_project_id IS NOT NULL AND ur.project_id = p_project_id)
      )
  );
$$;

ALTER FUNCTION app_internal.actor_has_permission(uuid, text, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.actor_has_permission(uuid, text, uuid) FROM PUBLIC, anon, authenticated;

-- Internal helper: count distinct active approved super_admin users excluding a user or role grant
CREATE OR REPLACE FUNCTION app_internal.count_remaining_super_admins(
  p_exclude_user_id uuid DEFAULT NULL,
  p_exclude_user_role_id uuid DEFAULT NULL
)
RETURNS bigint
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.count(DISTINCT u.id)
  FROM public.app_users u
  JOIN public.user_roles ur
    ON ur.user_id = u.id
    AND ur.status = 'ACTIVE'
    AND ur.project_id IS NULL
    AND ur.valid_from <= pg_catalog.now()
    AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
  JOIN public.roles r
    ON r.id = ur.role_id
    AND r.code = 'super_admin'
    AND r.status = 'ACTIVE'
  WHERE u.account_status = 'APPROVED'
    AND (p_exclude_user_id IS NULL OR u.id <> p_exclude_user_id)
    AND (p_exclude_user_role_id IS NULL OR ur.id <> p_exclude_user_role_id);
$$;

ALTER FUNCTION app_internal.count_remaining_super_admins(uuid, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.count_remaining_super_admins(uuid, uuid) FROM PUBLIC, anon, authenticated;

-- ===========================================================================
-- CMD-001: request-account-access
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_request_account_access_v1(
  p_idempotency_key text,
  p_display_name text,
  p_request_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_clean_name text;
  v_clean_note text;
  v_req_hash text;
  v_idem jsonb;
  v_user public.app_users%ROWTYPE;
  v_existing_req public.account_requests%ROWTYPE;
  v_new_req_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-001', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_name := pg_catalog.btrim(coalesce(p_display_name, ''));
  v_clean_note := nullif(pg_catalog.btrim(coalesce(p_request_note, '')), '');

  IF pg_catalog.char_length(v_clean_name) NOT BETWEEN 2 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-001', 'status', 'VALIDATION_FAILED', 'error_code', 'INVALID_DISPLAY_NAME', 'server_time', pg_catalog.now());
  END IF;

  IF v_clean_note IS NOT NULL AND pg_catalog.char_length(v_clean_note) > 500 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-001', 'status', 'VALIDATION_FAILED', 'error_code', 'INVALID_REQUEST_NOTE', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'display_name', v_clean_name, 'request_note', v_clean_note
  )::text);

  -- L00: Idempotency arbitration
  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-001', 'self:' || v_auth_uid::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-001', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L15: Create or lock caller's app_users row
  INSERT INTO public.app_users (auth_user_id, display_name, account_status, row_version)
  VALUES (v_auth_uid, v_clean_name, 'PENDING', 1)
  ON CONFLICT (auth_user_id) DO NOTHING;

  SELECT * INTO v_user
  FROM public.app_users
  WHERE auth_user_id = v_auth_uid
  FOR UPDATE;

  IF v_user.account_status = 'APPROVED' THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-001',
      'status', 'ALREADY_APPROVED',
      'user_id', v_user.id,
      'account_status', v_user.account_status,
      'row_version', v_user.row_version::text,
      'server_time', pg_catalog.now()
    );
  ELSIF v_user.account_status IN ('SUSPENDED', 'DISABLED') THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-001',
      'status', 'ACCOUNT_NOT_ELIGIBLE',
      'account_status', v_user.account_status,
      'server_time', pg_catalog.now()
    );
  END IF;

  -- L100: Check for an existing active PENDING request (RBAC-003 §3.4)
  SELECT * INTO v_existing_req
  FROM public.account_requests
  WHERE user_id = v_user.id AND status = 'PENDING'
  FOR UPDATE;

  IF FOUND THEN
    v_response := pg_catalog.jsonb_build_object(
      'command_id', 'CMD-001',
      'status', 'ALREADY_PENDING',
      'user_id', v_user.id,
      'request_id', v_existing_req.id,
      'account_status', v_user.account_status,
      'row_version', v_user.row_version::text,
      'server_time', pg_catalog.now()
    );
  ELSE
    -- If REJECTED, transition back to PENDING and increment row_version (preserving history)
    IF v_user.account_status = 'REJECTED' THEN
      UPDATE public.app_users
      SET account_status = 'PENDING',
          display_name = v_clean_name,
          row_version = row_version + 1,
          updated_at = pg_catalog.now()
      WHERE id = v_user.id
      RETURNING * INTO v_user;
    END IF;

    INSERT INTO public.account_requests (user_id, status, requested_display_name, request_note)
    VALUES (v_user.id, 'PENDING', v_clean_name, v_clean_note)
    RETURNING id INTO v_new_req_id;

    -- L110: Atomic audit event (T-15)
    INSERT INTO public.audit_events (
      event_type, actor_user_id, actor_auth_uid, command_id,
      scope_type, scope_id, target_table, target_id,
      idempotency_key_hash, outcome, metadata
    ) VALUES (
      'account.requested', v_user.id, v_auth_uid, 'CMD-001',
      'SELF', v_user.id, 'account_requests', v_new_req_id,
      v_idem->>'key_hash', 'SUCCESS',
      pg_catalog.jsonb_build_object('account_status', v_user.account_status, 'row_version', v_user.row_version::text)
    );

    v_response := pg_catalog.jsonb_build_object(
      'command_id', 'CMD-001',
      'status', 'ACCEPTED',
      'user_id', v_user.id,
      'request_id', v_new_req_id,
      'account_status', v_user.account_status,
      'row_version', v_user.row_version::text,
      'server_time', pg_catalog.now()
    );
  END IF;

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-001', 'self:' || v_auth_uid::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_request_account_access_v1(text, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_request_account_access_v1(text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_request_account_access_v1(text, text, text) TO authenticated;

-- ===========================================================================
-- CMD-002: approve-account
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_approve_account_v1(
  p_idempotency_key text,
  p_request_id uuid,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_req public.account_requests%ROWTYPE;
  v_target public.app_users%ROWTYPE;
  v_decision_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_request_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 1000 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL OR NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'request_id', p_request_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_clean_reason
  )::text);

  -- L00: Idempotency arbitration
  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-002', 'request:' || p_request_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- Resolve target user ID before deterministic L15 lock ordering
  SELECT * INTO v_req FROM public.account_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = v_req.user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  -- L15: Lock actor & target in deterministic UUID ascending order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, v_req.user_id) ORDER BY id ASC FOR UPDATE;

  -- Revalidate actor permission under lock
  IF NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_target FROM public.app_users WHERE id = v_req.user_id;
  -- L100: Lock request row
  SELECT * INTO v_req FROM public.account_requests WHERE id = p_request_id FOR UPDATE;

  IF v_req.status <> 'PENDING' OR v_target.account_status <> 'PENDING' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_target.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.app_users
  SET account_status = 'APPROVED',
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_target.id
  RETURNING * INTO v_target;

  UPDATE public.account_requests
  SET status = 'APPROVED', decided_at = pg_catalog.now()
  WHERE id = v_req.id;

  -- L110: Append-only decision + canonical audit
  INSERT INTO public.account_decisions (request_id, target_user_id, actor_user_id, decision, reason)
  VALUES (v_req.id, v_target.id, v_actor_id, 'APPROVE', v_clean_reason)
  RETURNING id INTO v_decision_id;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'account.approved', v_actor_id, v_auth_uid, 'CMD-002',
    'GLOBAL_IDENTITY', v_target.id, 'app_users', v_target.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('request_id', v_req.id, 'decision_id', v_decision_id, 'row_version', v_target.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-002',
    'status', 'APPROVED',
    'user_id', v_target.id,
    'request_id', v_req.id,
    'decision_id', v_decision_id,
    'account_status', v_target.account_status,
    'row_version', v_target.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-002', 'request:' || p_request_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_approve_account_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_approve_account_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_approve_account_v1(text, uuid, bigint, text) TO authenticated;

-- ===========================================================================
-- CMD-003: reject-account
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_reject_account_v1(
  p_idempotency_key text,
  p_request_id uuid,
  p_expected_row_version bigint,
  p_rejection_category text,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_req public.account_requests%ROWTYPE;
  v_target public.app_users%ROWTYPE;
  v_decision_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_request_id IS NULL
     OR p_expected_row_version IS NULL
     OR p_expected_row_version < 1
     OR p_rejection_category NOT IN ('UNVERIFIED_IDENTITY', 'OUT_OF_SCOPE_PERSONNEL', 'DUPLICATE_ACCOUNT', 'INCOMPLETE_INFORMATION', 'POLICY_RESTRICTION')
     OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL OR NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'request_id', p_request_id, 'expected_row_version', p_expected_row_version::text,
    'rejection_category', p_rejection_category, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-003', 'request:' || p_request_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_req FROM public.account_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = v_req.user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  -- L15 deterministic UUID order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, v_req.user_id) ORDER BY id ASC FOR UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_target FROM public.app_users WHERE id = v_req.user_id;
  SELECT * INTO v_req FROM public.account_requests WHERE id = p_request_id FOR UPDATE;

  IF v_req.status <> 'PENDING' OR v_target.account_status <> 'PENDING' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_target.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-003', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.app_users
  SET account_status = 'REJECTED',
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_target.id
  RETURNING * INTO v_target;

  UPDATE public.account_requests
  SET status = 'REJECTED', decided_at = pg_catalog.now()
  WHERE id = v_req.id;

  INSERT INTO public.account_decisions (request_id, target_user_id, actor_user_id, decision, rejection_category, reason)
  VALUES (v_req.id, v_target.id, v_actor_id, 'REJECT', p_rejection_category, v_clean_reason)
  RETURNING id INTO v_decision_id;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'account.rejected', v_actor_id, v_auth_uid, 'CMD-003',
    'GLOBAL_IDENTITY', v_target.id, 'app_users', v_target.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object(
      'request_id', v_req.id, 'decision_id', v_decision_id,
      'rejection_category', p_rejection_category, 'row_version', v_target.row_version::text
    )
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-003',
    'status', 'REJECTED',
    'user_id', v_target.id,
    'request_id', v_req.id,
    'decision_id', v_decision_id,
    'account_status', v_target.account_status,
    'row_version', v_target.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-003', 'request:' || p_request_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_reject_account_v1(text, uuid, bigint, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_reject_account_v1(text, uuid, bigint, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_reject_account_v1(text, uuid, bigint, text, text) TO authenticated;

-- ===========================================================================
-- RBAC-003 §3.3 Account State Transitions: SUSPEND / DISABLE / REINSTATE
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_transition_account_status_v1(
  p_idempotency_key text,
  p_target_user_id uuid,
  p_target_status text,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_target public.app_users%ROWTYPE;
  v_decision_label text;
  v_decision_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_target_user_id IS NULL
     OR p_target_status NOT IN ('SUSPENDED', 'DISABLED', 'APPROVED')
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL OR NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = p_target_user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'target_user_id', p_target_user_id, 'target_status', p_target_status,
    'expected_row_version', p_expected_row_version::text, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-002-STATE', 'user:' || p_target_user_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L15 deterministic lock
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, p_target_user_id) ORDER BY id ASC FOR UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'account.approve', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_target FROM public.app_users WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_target.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  -- Enforce RBAC-003 §3.3 transition table strictly (DISABLED never auto-reactivates)
  IF NOT (
    (v_target.account_status = 'APPROVED' AND p_target_status IN ('SUSPENDED', 'DISABLED'))
    OR (v_target.account_status = 'SUSPENDED' AND p_target_status IN ('APPROVED', 'DISABLED'))
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- L16: Last-active-super-admin protection when suspending/disabling
  IF p_target_status IN ('SUSPENDED', 'DISABLED') THEN
    PERFORM 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id AND r.code = 'super_admin'
    WHERE ur.status = 'ACTIVE' AND ur.project_id IS NULL
    ORDER BY ur.id ASC
    FOR UPDATE OF ur;

    IF app_internal.count_remaining_super_admins(p_target_user_id, NULL) < 1 THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-002-STATE', 'status', 'LAST_ADMIN_PROTECTED', 'server_time', pg_catalog.now());
    END IF;
  END IF;

  v_decision_label := CASE p_target_status
    WHEN 'SUSPENDED' THEN 'SUSPEND'
    WHEN 'DISABLED' THEN 'DISABLE'
    ELSE 'REINSTATE'
  END;

  UPDATE public.app_users
  SET account_status = p_target_status,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_target.id
  RETURNING * INTO v_target;

  INSERT INTO public.account_decisions (request_id, target_user_id, actor_user_id, decision, reason)
  VALUES (NULL, v_target.id, v_actor_id, v_decision_label, v_clean_reason)
  RETURNING id INTO v_decision_id;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'account.' || pg_catalog.lower(p_target_status), v_actor_id, v_auth_uid, 'CMD-002-STATE',
    'GLOBAL_IDENTITY', v_target.id, 'app_users', v_target.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('decision', v_decision_label, 'decision_id', v_decision_id, 'row_version', v_target.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-002-STATE',
    'status', 'TRANSITIONED',
    'user_id', v_target.id,
    'account_status', v_target.account_status,
    'decision_id', v_decision_id,
    'row_version', v_target.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-002-STATE', 'user:' || p_target_user_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_transition_account_status_v1(text, uuid, text, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_transition_account_status_v1(text, uuid, text, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_transition_account_status_v1(text, uuid, text, bigint, text) TO authenticated;

-- ===========================================================================
-- CMD-004: grant-role
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_grant_role_v1(
  p_idempotency_key text,
  p_target_user_id uuid,
  p_role_code text,
  p_project_id uuid DEFAULT NULL,
  p_valid_from timestamptz DEFAULT now(),
  p_valid_until timestamptz DEFAULT NULL,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_role public.roles%ROWTYPE;
  v_target public.app_users%ROWTYPE;
  v_is_super_admin boolean;
  v_grant_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_target_user_id IS NULL
     OR p_role_code IS NULL
     OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 500
     OR (p_valid_until IS NOT NULL AND p_valid_until <= coalesce(p_valid_from, pg_catalog.now()))
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = p_target_user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  -- L18 read-only catalog lookup
  SELECT * INTO v_role FROM public.roles WHERE code = p_role_code AND status = 'ACTIVE';
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'VALIDATION_FAILED', 'error_code', 'UNKNOWN_ROLE', 'server_time', pg_catalog.now());
  END IF;

  -- Enforce RBAC-003 §4.1 global vs project scope class strictly
  IF (v_role.scope_class = 'GLOBAL' AND p_project_id IS NOT NULL)
     OR (v_role.scope_class = 'PROJECT' AND p_project_id IS NULL)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'VALIDATION_FAILED', 'error_code', 'ROLE_SCOPE_CLASS_MISMATCH', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'target_user_id', p_target_user_id, 'role_code', p_role_code,
    'project_id', p_project_id, 'valid_from', p_valid_from, 'valid_until', p_valid_until, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-004',
    'user:' || p_target_user_id::text || ':role:' || p_role_code,
    p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L15 deterministic UUID order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, p_target_user_id) ORDER BY id ASC FOR UPDATE;

  -- Grantor delegation ceiling check under lock:
  -- Only an active super_admin may grant super_admin; other global role.manage holders cannot escalate.
  v_is_super_admin := app_internal.is_active_super_admin();
  IF v_role.code = 'super_admin' THEN
    IF NOT v_is_super_admin THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
  ELSIF NOT app_internal.actor_has_permission(v_actor_id, 'role.manage', NULL) THEN
    IF NOT (
      v_role.scope_class = 'PROJECT'
      AND v_role.code IN ('korlap', 'reviewer', 'inspector', 'print_officer')
      AND app_internal.actor_has_permission(v_actor_id, 'role.manage', p_project_id)
    ) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
  END IF;

  SELECT * INTO v_target FROM public.app_users WHERE id = p_target_user_id;
  IF NOT FOUND OR v_target.account_status <> 'APPROVED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- L16: Insert role grant (unique index arbitrates duplicate active grant)
  BEGIN
    INSERT INTO public.user_roles (
      user_id, role_id, project_id, valid_from, valid_until, status, granted_by, reason, row_version
    ) VALUES (
      p_target_user_id, v_role.id, p_project_id, coalesce(p_valid_from, pg_catalog.now()),
      p_valid_until, 'ACTIVE', v_actor_id, v_clean_reason, 1
    )
    RETURNING id INTO v_grant_id;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-004', 'status', 'STATE_CONFLICT', 'error_code', 'ROLE_ALREADY_ACTIVE', 'server_time', pg_catalog.now());
  END;

  -- L110: Atomic audit event
  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'role.assigned', v_actor_id, v_auth_uid, 'CMD-004',
    CASE WHEN p_project_id IS NULL THEN 'GLOBAL_IDENTITY' ELSE 'PROJECT' END,
    coalesce(p_project_id, p_target_user_id),
    'user_roles', v_grant_id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('target_user_id', p_target_user_id, 'role_code', v_role.code, 'project_id', p_project_id, 'row_version', '1')
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-004',
    'status', 'GRANTED',
    'user_role_id', v_grant_id,
    'target_user_id', p_target_user_id,
    'role_code', v_role.code,
    'project_id', p_project_id,
    'row_version', '1',
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-004', 'user:' || p_target_user_id::text || ':role:' || p_role_code,
    v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_grant_role_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_grant_role_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_grant_role_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) TO authenticated;

-- ===========================================================================
-- CMD-005: revoke-role (mandatory expected_row_version CAS + last-admin guard)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_revoke_role_v1(
  p_idempotency_key text,
  p_user_role_id uuid,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_grant public.user_roles%ROWTYPE;
  v_role public.roles%ROWTYPE;
  v_is_super_admin boolean;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_user_role_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 500 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'user_role_id', p_user_role_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-005', 'user_role:' || p_user_role_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_grant FROM public.user_roles WHERE id = p_user_role_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = v_grant.user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_role FROM public.roles WHERE id = v_grant.role_id;

  -- L15 deterministic UUID order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, v_grant.user_id) ORDER BY id ASC FOR UPDATE;

  -- Grantor delegation ceiling check:
  -- Only an active super_admin may revoke a super_admin grant.
  v_is_super_admin := app_internal.is_active_super_admin();
  IF v_role.code = 'super_admin' THEN
    IF NOT v_is_super_admin THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
  ELSIF NOT app_internal.actor_has_permission(v_actor_id, 'role.manage', NULL) THEN
    IF NOT (
      v_role.scope_class = 'PROJECT'
      AND v_role.code IN ('korlap', 'reviewer', 'inspector', 'print_officer')
      AND app_internal.actor_has_permission(v_actor_id, 'role.manage', v_grant.project_id)
    ) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
  END IF;

  -- L16: If super_admin, lock all active super_admin grants deterministically first
  IF v_role.code = 'super_admin' THEN
    PERFORM 1
    FROM public.user_roles ur
    WHERE ur.role_id = v_role.id AND ur.status = 'ACTIVE' AND ur.project_id IS NULL
    ORDER BY ur.id ASC
    FOR UPDATE;
  END IF;

  SELECT * INTO v_grant FROM public.user_roles WHERE id = p_user_role_id FOR UPDATE;
  IF v_grant.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_grant.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  IF v_role.code = 'super_admin' AND app_internal.count_remaining_super_admins(NULL, v_grant.id) < 1 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-005', 'status', 'LAST_ADMIN_PROTECTED', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.user_roles
  SET status = 'REVOKED',
      revoked_at = pg_catalog.now(),
      revoked_by = v_actor_id,
      revoke_reason = v_clean_reason,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_grant.id
  RETURNING * INTO v_grant;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'role.revoked', v_actor_id, v_auth_uid, 'CMD-005',
    CASE WHEN v_grant.project_id IS NULL THEN 'GLOBAL_IDENTITY' ELSE 'PROJECT' END,
    coalesce(v_grant.project_id, v_grant.user_id),
    'user_roles', v_grant.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('target_user_id', v_grant.user_id, 'role_code', v_role.code, 'row_version', v_grant.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-005',
    'status', 'REVOKED',
    'user_role_id', v_grant.id,
    'target_user_id', v_grant.user_id,
    'role_code', v_role.code,
    'row_version', v_grant.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-005', 'user_role:' || p_user_role_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_revoke_role_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_revoke_role_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_revoke_role_v1(text, uuid, bigint, text) TO authenticated;

-- ===========================================================================
-- CMD-006: grant-scope (explicit non-inheriting operational scope)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_grant_scope_v1(
  p_idempotency_key text,
  p_target_user_id uuid,
  p_scope_type text,
  p_scope_id uuid,
  p_valid_from timestamptz DEFAULT now(),
  p_valid_until timestamptz DEFAULT NULL,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_target public.app_users%ROWTYPE;
  v_grant_id uuid;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_target_user_id IS NULL
     OR p_scope_type NOT IN ('PROJECT', 'SESSION', 'LOCATION', 'INSTRUMENT', 'TEAM', 'ASSIGNMENT')
     OR p_scope_id IS NULL
     OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 500
     OR (p_valid_until IS NOT NULL AND p_valid_until <= coalesce(p_valid_from, pg_catalog.now()))
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = p_target_user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'target_user_id', p_target_user_id, 'scope_type', p_scope_type, 'scope_id', p_scope_id,
    'valid_from', p_valid_from, 'valid_until', p_valid_until, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-006',
    'user:' || p_target_user_id::text || ':scope:' || p_scope_type || ':' || p_scope_id::text,
    p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- L15 deterministic UUID order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, p_target_user_id) ORDER BY id ASC FOR UPDATE;

  IF NOT (
    app_internal.actor_has_permission(v_actor_id, 'scope.manage', NULL)
    OR (p_scope_type = 'PROJECT' AND app_internal.actor_has_permission(v_actor_id, 'scope.manage', p_scope_id))
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_target FROM public.app_users WHERE id = p_target_user_id;
  IF NOT FOUND OR v_target.account_status <> 'APPROVED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- L17 insert
  BEGIN
    INSERT INTO public.user_scope_grants (
      user_id, scope_type, scope_id, valid_from, valid_until, status, granted_by, reason, row_version
    ) VALUES (
      p_target_user_id, p_scope_type, p_scope_id, coalesce(p_valid_from, pg_catalog.now()),
      p_valid_until, 'ACTIVE', v_actor_id, v_clean_reason, 1
    )
    RETURNING id INTO v_grant_id;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-006', 'status', 'STATE_CONFLICT', 'error_code', 'SCOPE_ALREADY_ACTIVE', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'scope.changed', v_actor_id, v_auth_uid, 'CMD-006',
    p_scope_type, p_scope_id, 'user_scope_grants', v_grant_id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('action', 'GRANT', 'target_user_id', p_target_user_id, 'scope_type', p_scope_type, 'scope_id', p_scope_id, 'row_version', '1')
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-006',
    'status', 'GRANTED',
    'scope_grant_id', v_grant_id,
    'target_user_id', p_target_user_id,
    'scope_type', p_scope_type,
    'scope_id', p_scope_id,
    'row_version', '1',
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-006', 'user:' || p_target_user_id::text || ':scope:' || p_scope_type || ':' || p_scope_id::text,
    v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_grant_scope_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_grant_scope_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_grant_scope_v1(text, uuid, text, uuid, timestamptz, timestamptz, text) TO authenticated;

-- ===========================================================================
-- CMD-007: revoke-scope (mandatory expected_row_version CAS per CV-02)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_revoke_scope_v1(
  p_idempotency_key text,
  p_scope_grant_id uuid,
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
  v_clean_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_grant public.user_scope_grants%ROWTYPE;
  v_response jsonb;
BEGIN
  PERFORM pg_catalog.set_config('lock_timeout', '5s', true);
  PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  v_clean_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_scope_grant_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 OR pg_catalog.char_length(v_clean_reason) NOT BETWEEN 3 AND 500 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_actor_id := app_internal.current_app_user_id();
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'scope_grant_id', p_scope_grant_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_clean_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-007', 'scope_grant:' || p_scope_grant_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_grant FROM public.user_scope_grants WHERE id = p_scope_grant_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_actor_id = v_grant.user_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  -- L15 deterministic UUID order
  PERFORM 1 FROM public.app_users WHERE id IN (v_actor_id, v_grant.user_id) ORDER BY id ASC FOR UPDATE;

  IF NOT (
    app_internal.actor_has_permission(v_actor_id, 'scope.manage', NULL)
    OR (v_grant.scope_type = 'PROJECT' AND app_internal.actor_has_permission(v_actor_id, 'scope.manage', v_grant.scope_id))
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- L17 lock
  SELECT * INTO v_grant FROM public.user_scope_grants WHERE id = p_scope_grant_id FOR UPDATE;
  IF v_grant.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_grant.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-007', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.user_scope_grants
  SET status = 'REVOKED',
      revoked_at = pg_catalog.now(),
      revoked_by = v_actor_id,
      revoke_reason = v_clean_reason,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_grant.id
  RETURNING * INTO v_grant;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'scope.changed', v_actor_id, v_auth_uid, 'CMD-007',
    v_grant.scope_type, v_grant.scope_id, 'user_scope_grants', v_grant.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('action', 'REVOKE', 'target_user_id', v_grant.user_id, 'scope_type', v_grant.scope_type, 'scope_id', v_grant.scope_id, 'row_version', v_grant.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-007',
    'status', 'REVOKED',
    'scope_grant_id', v_grant.id,
    'target_user_id', v_grant.user_id,
    'scope_type', v_grant.scope_type,
    'scope_id', v_grant.scope_id,
    'row_version', v_grant.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-007', 'scope_grant:' || p_scope_grant_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

ALTER FUNCTION public.cmd_revoke_scope_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_revoke_scope_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_revoke_scope_v1(text, uuid, bigint, text) TO authenticated;

-- Revoke temporary migration-time schema CREATE privileges (T-18 least privilege at runtime)
REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
