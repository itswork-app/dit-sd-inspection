-- Migration: 20261127070200_i4_cmd033_035_evidence_and_offline_sync.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for CMD-033 (upload intent),
--        CMD-034 (confirm upload), T-09 device binding, and CMD-035 (offline draft sync batch).
-- Authority: AGENTS.md v1.3.0, Command Catalogue v1.0.0, OFFLINE-SYNC v1.0.0, T-09, T-16, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- ===========================================================================
-- CMD-033: create-upload-intent (evidence.upload; server-generated private object_key)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_create_upload_intent_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_slot_definition_id uuid,
  p_mime_type text,
  p_byte_size integer,
  p_sha256 text,
  p_client_file_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_sha text;
  v_file_id text;
  v_req_hash text;
  v_idem jsonb;
  v_insp public.inspections%ROWTYPE;
  v_slot public.evidence_slot_definitions%ROWTYPE;
  v_claim_ok boolean;
  v_object_key text;
  v_asset public.evidence_assets%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_sha := pg_catalog.lower(pg_catalog.btrim(coalesce(p_sha256, '')));
  v_file_id := pg_catalog.btrim(coalesce(p_client_file_id, ''));
  IF p_inspection_id IS NULL OR p_slot_definition_id IS NULL
     OR p_mime_type NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
     OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 15728640
     OR v_sha !~ '^[0-9a-f]{64}$'
     OR pg_catalog.char_length(v_file_id) NOT BETWEEN 4 AND 128
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'slot_definition_id', p_slot_definition_id,
    'mime_type', p_mime_type, 'byte_size', p_byte_size, 'sha256', v_sha, 'client_file_id', v_file_id
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-033', 'inspection:' || p_inspection_id::text || ':file:' || v_file_id, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'evidence.upload', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.unit_claims c
    WHERE c.unit_id = v_insp.unit_id AND c.project_id = v_insp.project_id
      AND c.inspector_id = v_actor_id AND c.status = 'ACTIVE' AND c.expires_at > pg_catalog.now()
  ) INTO v_claim_ok;

  IF NOT v_claim_ok THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'CLAIM_INVALID', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_slot FROM public.evidence_slot_definitions
  WHERE id = p_slot_definition_id AND instrument_version_id = v_insp.instrument_version_id;
  IF NOT FOUND OR NOT (p_mime_type = ANY(v_slot.allowed_media_types)) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'SLOT_INVALID', 'server_time', pg_catalog.now());
  END IF;

  -- Server-generated private Storage object key (never accepts raw object key from client!)
  v_object_key := 'private/projects/' || v_insp.project_id::text
    || '/inspections/' || v_insp.id::text
    || '/' || pg_catalog.gen_random_uuid()::text;

  BEGIN
    INSERT INTO public.evidence_assets (
      inspection_id, slot_definition_id, client_file_id, object_key,
      expected_sha256, expected_byte_size, mime_type, upload_status, uploaded_by, row_version
    ) VALUES (
      v_insp.id, v_slot.id, v_file_id, v_object_key,
      v_sha, p_byte_size, p_mime_type, 'INTENT_CREATED', v_actor_id, 1
    )
    RETURNING * INTO v_asset;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-033', 'status', 'STATE_CONFLICT', 'error_code', 'DUPLICATE_CLIENT_FILE_ID', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'evidence.upload_intent_created', v_actor_id, v_auth_uid, 'CMD-033',
    'PROJECT', v_insp.project_id, 'evidence_assets', v_asset.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'slot_id', v_slot.id, 'mime_type', p_mime_type, 'byte_size', p_byte_size)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-033',
    'status', 'INTENT_CREATED',
    'evidence_asset_id', v_asset.id,
    'object_key', v_asset.object_key,
    'row_version', v_asset.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-033', 'inspection:' || p_inspection_id::text || ':file:' || v_file_id, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-034: confirm-upload (evidence.upload; verifies sha256/size/mime match intent)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_confirm_upload_v1(
  p_idempotency_key text,
  p_evidence_asset_id uuid,
  p_observed_sha256 text,
  p_observed_byte_size integer,
  p_observed_mime text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_obs_sha text;
  v_req_hash text;
  v_idem jsonb;
  v_asset public.evidence_assets%ROWTYPE;
  v_insp public.inspections%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_obs_sha := pg_catalog.lower(pg_catalog.btrim(coalesce(p_observed_sha256, '')));
  IF p_evidence_asset_id IS NULL OR v_obs_sha !~ '^[0-9a-f]{64}$'
     OR p_observed_byte_size IS NULL OR p_observed_byte_size NOT BETWEEN 1 AND 15728640
     OR p_observed_mime IS NULL
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'evidence_asset_id', p_evidence_asset_id, 'sha256', v_obs_sha,
    'size', p_observed_byte_size, 'mime', p_observed_mime
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-034', 'evidence:' || p_evidence_asset_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_asset FROM public.evidence_assets WHERE id = p_evidence_asset_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = v_asset.inspection_id FOR SHARE;
  IF NOT app_internal.actor_has_permission(v_actor_id, 'evidence.upload', v_insp.project_id)
     OR v_asset.uploaded_by <> v_actor_id
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_asset.upload_status <> 'INTENT_CREATED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- Server-verified object metadata must match declared upload intent exactly
  IF v_obs_sha <> v_asset.expected_sha256
     OR p_observed_byte_size <> v_asset.expected_byte_size
     OR p_observed_mime <> v_asset.mime_type
  THEN
    UPDATE public.evidence_assets
    SET upload_status = 'FAILED', observed_sha256 = v_obs_sha, observed_byte_size = p_observed_byte_size, row_version = row_version + 1
    WHERE id = v_asset.id;
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-034', 'status', 'EVIDENCE_INVALID', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.evidence_assets
  SET upload_status = 'FINALIZED',
      observed_sha256 = v_obs_sha,
      observed_byte_size = p_observed_byte_size,
      finalized_at = pg_catalog.now(),
      row_version = row_version + 1
  WHERE id = v_asset.id
  RETURNING * INTO v_asset;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'evidence.uploaded', v_actor_id, v_auth_uid, 'CMD-034',
    'PROJECT', v_insp.project_id, 'evidence_assets', v_asset.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'sha256', v_obs_sha, 'byte_size', p_observed_byte_size)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-034',
    'status', 'FINALIZED',
    'evidence_asset_id', v_asset.id,
    'row_version', v_asset.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-034', 'evidence:' || p_evidence_asset_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- T-09 Helper: register-device-binding (for bounded offline draft sync)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_register_device_binding_v1(
  p_idempotency_key text,
  p_device_fingerprint_hash text,
  p_label text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_fp text;
  v_label text;
  v_req_hash text;
  v_idem jsonb;
  v_dev public.device_bindings%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035-DEV', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035-DEV', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_fp := pg_catalog.lower(pg_catalog.btrim(coalesce(p_device_fingerprint_hash, '')));
  v_label := pg_catalog.btrim(coalesce(p_label, ''));
  IF v_fp !~ '^[0-9a-f]{64}$' OR pg_catalog.char_length(v_label) NOT BETWEEN 2 AND 100 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035-DEV', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object('v', 1, 'fp', v_fp, 'label', v_label)::text);
  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-035-DEV', 'device:' || v_fp, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035-DEV', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_dev FROM public.device_bindings
  WHERE user_id = v_actor_id AND device_fingerprint_hash = v_fp AND status = 'ACTIVE';

  IF NOT FOUND THEN
    INSERT INTO public.device_bindings (user_id, device_fingerprint_hash, label, status)
    VALUES (v_actor_id, v_fp, v_label, 'ACTIVE')
    RETURNING * INTO v_dev;
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'device.bound', v_actor_id, v_auth_uid, 'CMD-035-DEV',
    'SELF', v_actor_id, 'device_bindings', v_dev.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('label', v_dev.label)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-035-DEV',
    'status', 'BOUND',
    'device_id', v_dev.id,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-035-DEV', 'device:' || v_fp, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-035: sync-batch (T-09 Option B bounded offline SAVE_DRAFT sync; conflict-preserving)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_sync_batch_v1(
  p_idempotency_key text,
  p_device_id uuid,
  p_batch_key text,
  p_operations jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_batch_key text;
  v_payload_hash text;
  v_req_hash text;
  v_idem jsonb;
  v_dev public.device_bindings%ROWTYPE;
  v_batch public.sync_batches%ROWTYPE;
  v_op jsonb;
  v_op_id text;
  v_insp_id uuid;
  v_exp_ver bigint;
  v_op_payload jsonb;
  v_insp public.inspections%ROWTYPE;
  v_claim_ok boolean;
  v_applied_count integer := 0;
  v_conflict_count integer := 0;
  v_denied_count integer := 0;
  v_op_results jsonb := '[]'::jsonb;
  v_batch_status text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_batch_key := pg_catalog.btrim(coalesce(p_batch_key, ''));
  IF p_device_id IS NULL
     OR pg_catalog.char_length(v_batch_key) NOT BETWEEN 8 AND 128
     OR p_operations IS NULL OR pg_catalog.jsonb_typeof(p_operations) <> 'array'
     OR pg_catalog.jsonb_array_length(p_operations) NOT BETWEEN 1 AND 50
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_payload_hash := app_internal.sha256_hex(p_operations::text);
  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'device_id', p_device_id, 'batch_key', v_batch_key, 'payload_hash', v_payload_hash
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-035', 'device:' || p_device_id::text || ':batch:' || v_batch_key, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- Verify active caller-owned device binding (T-09)
  SELECT * INTO v_dev FROM public.device_bindings
  WHERE id = p_device_id AND user_id = v_actor_id AND status = 'ACTIVE';
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'PERMISSION_DENIED', 'error_code', 'DEVICE_NOT_BOUND', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.sync_batches (
      actor_user_id, device_id, batch_key, payload_hash, status, operation_count
    ) VALUES (
      v_actor_id, p_device_id, v_batch_key, v_payload_hash, 'ACCEPTED', pg_catalog.jsonb_array_length(p_operations)
    )
    RETURNING * INTO v_batch;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'IDEMPOTENCY_KEY_REUSED', 'server_time', pg_catalog.now());
  END;

  -- Process each SAVE_DRAFT operation with strict reauthorization & conflict preservation (no last-write-wins!)
  FOR v_op IN SELECT * FROM pg_catalog.jsonb_array_elements(p_operations)
  LOOP
    v_op_id := pg_catalog.btrim(coalesce(v_op->>'operation_id', ''));
    IF pg_catalog.char_length(v_op_id) NOT BETWEEN 4 AND 128
       OR coalesce(v_op->>'op_type', '') <> 'SAVE_DRAFT'
       OR coalesce(v_op->>'inspection_id', '') !~ '^[0-9a-fA-F-]{36}$'
       OR coalesce(v_op->>'expected_row_version', '') !~ '^[1-9]\d{0,15}$'
       OR v_op->'payload' IS NULL OR pg_catalog.jsonb_typeof(v_op->'payload') <> 'object'
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    v_insp_id := (v_op->>'inspection_id')::uuid;
    v_exp_ver := (v_op->>'expected_row_version')::bigint;
    v_op_payload := v_op->'payload';

    SELECT * INTO v_insp FROM public.inspections WHERE id = v_insp_id FOR UPDATE;
    IF NOT FOUND
       OR NOT app_internal.actor_has_permission(v_actor_id, 'sync.apply', v_insp.project_id)
       OR NOT app_internal.actor_has_permission(v_actor_id, 'inspection.edit', v_insp.project_id)
    THEN
      v_denied_count := v_denied_count + 1;
      INSERT INTO public.sync_batch_operations (
        batch_id, operation_id, inspection_id, op_type, expected_row_version, payload, outcome
      ) VALUES (
        v_batch.id, v_op_id, v_insp_id, 'SAVE_DRAFT', v_exp_ver, v_op_payload, 'DENIED'
      );
      v_op_results := v_op_results || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'operation_id', v_op_id, 'outcome', 'DENIED'
      ));
      CONTINUE;
    END IF;

    -- Re-check live claim ownership
    SELECT EXISTS (
      SELECT 1 FROM public.unit_claims c
      WHERE c.unit_id = v_insp.unit_id AND c.project_id = v_insp.project_id
        AND c.inspector_id = v_actor_id AND c.status = 'ACTIVE' AND c.expires_at > pg_catalog.now()
    ) INTO v_claim_ok;

    IF NOT v_claim_ok OR v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') OR v_insp.row_version <> v_exp_ver THEN
      v_conflict_count := v_conflict_count + 1;
      UPDATE public.inspection_draft_contexts
      SET has_unresolved_sync_conflict = true, updated_at = pg_catalog.now()
      WHERE inspection_id = v_insp.id;

      INSERT INTO public.sync_batch_operations (
        batch_id, operation_id, inspection_id, op_type, expected_row_version, payload,
        outcome, conflict_snapshot, resulting_row_version
      ) VALUES (
        v_batch.id, v_op_id, v_insp.id, 'SAVE_DRAFT', v_exp_ver, v_op_payload,
        'CONFLICTED',
        pg_catalog.jsonb_build_object(
          'reason', CASE WHEN NOT v_claim_ok THEN 'CLAIM_EXPIRED' WHEN v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') THEN 'STATE_CONFLICT' ELSE 'STALE_VERSION' END,
          'server_status', v_insp.status,
          'server_row_version', v_insp.row_version::text
        ),
        v_insp.row_version
      );

      v_op_results := v_op_results || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'operation_id', v_op_id,
        'outcome', 'CONFLICTED',
        'reason', CASE WHEN NOT v_claim_ok THEN 'CLAIM_EXPIRED' WHEN v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') THEN 'STATE_CONFLICT' ELSE 'STALE_VERSION' END,
        'server_row_version', v_insp.row_version::text
      ));
      CONTINUE;
    END IF;

    -- Apply valid draft patch safely
    UPDATE public.inspection_draft_contexts
    SET draft_checklist = coalesce(v_op_payload->'draft_checklist', draft_checklist),
        draft_specifications = coalesce(v_op_payload->'draft_specifications', draft_specifications),
        notes = CASE WHEN v_op_payload ? 'notes' THEN v_op_payload->>'notes' ELSE notes END,
        updated_by = v_actor_id,
        updated_at = pg_catalog.now(),
        row_version = row_version + 1
    WHERE inspection_id = v_insp.id;

    UPDATE public.inspections
    SET row_version = row_version + 1, updated_at = pg_catalog.now()
    WHERE id = v_insp.id
    RETURNING * INTO v_insp;

    v_applied_count := v_applied_count + 1;
    INSERT INTO public.sync_batch_operations (
      batch_id, operation_id, inspection_id, op_type, expected_row_version, payload,
      outcome, resulting_row_version
    ) VALUES (
      v_batch.id, v_op_id, v_insp.id, 'SAVE_DRAFT', v_exp_ver, v_op_payload,
      'APPLIED', v_insp.row_version
    );

    v_op_results := v_op_results || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'operation_id', v_op_id,
      'outcome', 'APPLIED',
      'resulting_row_version', v_insp.row_version::text
    ));
  END LOOP;

  IF v_applied_count > 0 AND v_conflict_count = 0 AND v_denied_count = 0 THEN
    v_batch_status := 'APPLIED';
  ELSIF v_applied_count > 0 THEN
    v_batch_status := 'PARTIAL';
  ELSE
    v_batch_status := 'CONFLICTED';
  END IF;

  UPDATE public.sync_batches
  SET status = v_batch_status, acknowledged_at = pg_catalog.now()
  WHERE id = v_batch.id;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN v_conflict_count > 0 THEN 'sync.batch_conflicted' ELSE 'sync.batch_applied' END,
    v_actor_id, v_auth_uid, 'CMD-035',
    'SELF', v_actor_id, 'sync_batches', v_batch.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('applied', v_applied_count, 'conflicted', v_conflict_count, 'denied', v_denied_count)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-035',
    'status', v_batch_status,
    'batch_id', v_batch.id,
    'results', v_op_results,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-035', 'device:' || p_device_id::text || ':batch:' || v_batch_key, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' OR unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-035', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) TO authenticated;

ALTER FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) TO authenticated;

ALTER FUNCTION public.cmd_register_device_binding_v1(text, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_register_device_binding_v1(text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_register_device_binding_v1(text, text, text) TO authenticated;

ALTER FUNCTION public.cmd_sync_batch_v1(text, uuid, text, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_sync_batch_v1(text, uuid, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_sync_batch_v1(text, uuid, text, jsonb) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
