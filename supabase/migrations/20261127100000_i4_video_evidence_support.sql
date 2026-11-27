-- Migration: 20261127100000_i4_video_evidence_support.sql
-- Scope: PO Decision PO-2026-11-27-VIDEO-EVIDENCE-001 (Option 2A) — admit video/mp4 & video/webm
--        damage evidence up to 25 MiB (26214400 bytes) in evidence_assets, inspection-private bucket,
--        CMD-019, CMD-033, and CMD-034. Never alters migrations 1-13.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- 1. Expand public.evidence_assets CHECK constraints cleanly for video + 25 MiB cap
DO $$
DECLARE
  v_con text;
BEGIN
  FOR v_con IN
    SELECT c.conname
    FROM pg_catalog.pg_constraint c
    JOIN pg_catalog.pg_class t ON t.oid = c.conrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'evidence_assets'
      AND c.contype = 'c'
      AND (
        pg_catalog.pg_get_constraintdef(c.oid) ILIKE '%mime_type%'
        OR pg_catalog.pg_get_constraintdef(c.oid) ILIKE '%byte_size%'
      )
  LOOP
    EXECUTE pg_catalog.format('ALTER TABLE public.evidence_assets DROP CONSTRAINT %I', v_con);
  END LOOP;
END;
$$;

ALTER TABLE public.evidence_assets
  ADD CONSTRAINT chk_evidence_assets_expected_byte_size_v2
    CHECK (expected_byte_size BETWEEN 1 AND 26214400),
  ADD CONSTRAINT chk_evidence_assets_observed_byte_size_v2
    CHECK (observed_byte_size IS NULL OR observed_byte_size BETWEEN 1 AND 26214400),
  ADD CONSTRAINT chk_evidence_assets_mime_type_v2
    CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'video/mp4', 'video/webm'));

-- 2. Expand private bucket inspection-private file limit (25 MiB) & MIME allowlist
UPDATE storage.buckets
SET file_size_limit = 26214400,
    allowed_mime_types = ARRAY[
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
      'video/mp4',
      'video/webm'
    ]
WHERE id = 'inspection-private';

-- 3. CMD-019: Update allowed_media_types validation to allow video/mp4 & video/webm (up to 6 per slot)
CREATE OR REPLACE FUNCTION public.cmd_save_instrument_draft_v1(
  p_idempotency_key text,
  p_instrument_id uuid,
  p_version_id uuid DEFAULT NULL,
  p_schema_version text DEFAULT '1.0',
  p_sections jsonb DEFAULT '[]'::jsonb,
  p_spec_fields jsonb DEFAULT '[]'::jsonb,
  p_evidence_slots jsonb DEFAULT '[]'::jsonb
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
  v_inst public.instruments%ROWTYPE;
  v_ver public.instrument_versions%ROWTYPE;
  v_next_ver integer;
  v_sec jsonb;
  v_sec_row public.checklist_sections%ROWTYPE;
  v_item jsonb;
  v_field jsonb;
  v_slot jsonb;
  v_allowed_mimes text[];
  v_mime text;
  v_draft_hash text;
  v_sec_idx integer := 0;
  v_item_idx integer;
  v_field_idx integer := 0;
  v_slot_idx integer := 0;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_instrument_id IS NULL
     OR p_sections IS NULL OR pg_catalog.jsonb_typeof(p_sections) <> 'array'
     OR p_spec_fields IS NULL OR pg_catalog.jsonb_typeof(p_spec_fields) <> 'array'
     OR p_evidence_slots IS NULL OR pg_catalog.jsonb_typeof(p_evidence_slots) <> 'array'
     OR pg_catalog.jsonb_array_length(p_sections) > 50
     OR pg_catalog.jsonb_array_length(p_spec_fields) > 100
     OR pg_catalog.jsonb_array_length(p_evidence_slots) > 50
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_draft_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'schema_version', coalesce(p_schema_version, '1.0'),
    'sections', p_sections,
    'spec_fields', p_spec_fields,
    'evidence_slots', p_evidence_slots
  )::text);

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'instrument_id', p_instrument_id, 'version_id', p_version_id, 'draft_hash', v_draft_hash
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-019',
    'instrument:' || p_instrument_id::text || ':ver:' || coalesce(p_version_id::text, 'new'),
    p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'instrument.manage', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_inst FROM public.instruments WHERE id = p_instrument_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF p_version_id IS NULL THEN
    SELECT coalesce(pg_catalog.max(version_number), 0) + 1 INTO v_next_ver
    FROM public.instrument_versions WHERE instrument_id = p_instrument_id;

    INSERT INTO public.instrument_versions (
      instrument_id, version_number, status, schema_version, draft_hash, row_version, created_by
    ) VALUES (
      p_instrument_id, v_next_ver, 'DRAFT', coalesce(p_schema_version, '1.0'), v_draft_hash, 1, v_actor_id
    )
    RETURNING * INTO v_ver;
  ELSE
    SELECT * INTO v_ver FROM public.instrument_versions
    WHERE id = p_version_id AND instrument_id = p_instrument_id FOR UPDATE;
    IF NOT FOUND THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
    END IF;
    IF v_ver.status <> 'DRAFT' THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'PUBLISHED_IMMUTABLE', 'server_time', pg_catalog.now());
    END IF;

    DELETE FROM public.checklist_items
    WHERE section_id IN (SELECT id FROM public.checklist_sections WHERE instrument_version_id = v_ver.id);
    DELETE FROM public.checklist_sections WHERE instrument_version_id = v_ver.id;
    DELETE FROM public.specification_fields WHERE instrument_version_id = v_ver.id;
    DELETE FROM public.evidence_slot_definitions WHERE instrument_version_id = v_ver.id;
  END IF;

  FOR v_sec IN SELECT * FROM pg_catalog.jsonb_array_elements(p_sections)
  LOOP
    v_sec_idx := v_sec_idx + 1;
    IF coalesce(v_sec->>'code', '') !~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'
       OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_sec->>'label', ''))) NOT BETWEEN 1 AND 200
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.checklist_sections (instrument_version_id, code, label, sort_order)
    VALUES (v_ver.id, v_sec->>'code', pg_catalog.btrim(v_sec->>'label'), v_sec_idx)
    RETURNING * INTO v_sec_row;

    IF v_sec->'items' IS NOT NULL THEN
      IF pg_catalog.jsonb_typeof(v_sec->'items') <> 'array' THEN
        RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
      END IF;
      v_item_idx := 0;
      FOR v_item IN SELECT * FROM pg_catalog.jsonb_array_elements(v_sec->'items')
      LOOP
        v_item_idx := v_item_idx + 1;
        IF coalesce(v_item->>'code', '') !~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'
           OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_item->>'label', ''))) NOT BETWEEN 1 AND 400
           OR coalesce(v_item->>'answer_type', '') NOT IN ('PASS_FAIL', 'YES_NO', 'TEXT', 'NUMBER', 'SINGLE_SELECT', 'MULTI_SELECT')
        THEN
          RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
        END IF;

        INSERT INTO public.checklist_items (
          section_id, code, label, answer_type, sort_order, required, applicability_rule, validation_config
        ) VALUES (
          v_sec_row.id,
          v_item->>'code',
          pg_catalog.btrim(v_item->>'label'),
          v_item->>'answer_type',
          v_item_idx,
          coalesce((v_item->>'required')::boolean, true),
          CASE WHEN v_item ? 'applicability_rule' AND pg_catalog.jsonb_typeof(v_item->'applicability_rule') = 'object' THEN v_item->'applicability_rule' ELSE NULL END,
          CASE WHEN v_item ? 'validation_config' AND pg_catalog.jsonb_typeof(v_item->'validation_config') = 'object' THEN v_item->'validation_config' ELSE NULL END
        );
      END LOOP;
    END IF;
  END LOOP;

  FOR v_field IN SELECT * FROM pg_catalog.jsonb_array_elements(p_spec_fields)
  LOOP
    v_field_idx := v_field_idx + 1;
    IF coalesce(v_field->>'code', '') !~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'
       OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_field->>'label', ''))) NOT BETWEEN 1 AND 200
       OR coalesce(v_field->>'value_type', '') NOT IN ('TEXT', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'ENUM')
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.specification_fields (
      instrument_version_id, code, label, value_type, expected_value, unit, required, sort_order
    ) VALUES (
      v_ver.id,
      v_field->>'code',
      pg_catalog.btrim(v_field->>'label'),
      v_field->>'value_type',
      nullif(pg_catalog.btrim(coalesce(v_field->>'expected_value', '')), ''),
      nullif(pg_catalog.btrim(coalesce(v_field->>'unit', '')), ''),
      coalesce((v_field->>'required')::boolean, true),
      v_field_idx
    );
  END LOOP;

  FOR v_slot IN SELECT * FROM pg_catalog.jsonb_array_elements(p_evidence_slots)
  LOOP
    v_slot_idx := v_slot_idx + 1;
    IF coalesce(v_slot->>'code', '') !~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'
       OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_slot->>'label', ''))) NOT BETWEEN 1 AND 200
       OR v_slot->'allowed_media_types' IS NULL
       OR pg_catalog.jsonb_typeof(v_slot->'allowed_media_types') <> 'array'
       OR pg_catalog.jsonb_array_length(v_slot->'allowed_media_types') NOT BETWEEN 1 AND 6
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    SELECT pg_catalog.array_agg(elem) INTO v_allowed_mimes
    FROM pg_catalog.jsonb_array_elements_text(v_slot->'allowed_media_types') AS elem;

    FOREACH v_mime IN ARRAY v_allowed_mimes
    LOOP
      IF v_mime NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'video/mp4', 'video/webm') THEN
        RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
      END IF;
    END LOOP;

    INSERT INTO public.evidence_slot_definitions (
      instrument_version_id, code, label, required, allowed_media_types, sort_order
    ) VALUES (
      v_ver.id,
      v_slot->>'code',
      pg_catalog.btrim(v_slot->>'label'),
      coalesce((v_slot->>'required')::boolean, true),
      v_allowed_mimes,
      v_slot_idx
    );
  END LOOP;

  UPDATE public.instrument_versions
  SET schema_version = coalesce(p_schema_version, schema_version),
      draft_hash = v_draft_hash,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_ver.id
  RETURNING * INTO v_ver;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'instrument.version_drafted', v_actor_id, v_auth_uid, 'CMD-019',
    'INSTRUMENT', p_instrument_id, 'instrument_versions', v_ver.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('version_number', v_ver.version_number, 'draft_hash', v_draft_hash, 'row_version', v_ver.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-019',
    'status', 'SAVED',
    'instrument_id', p_instrument_id,
    'version_id', v_ver.id,
    'version_number', v_ver.version_number,
    'draft_hash', v_ver.draft_hash,
    'row_version', v_ver.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-019',
    'instrument:' || p_instrument_id::text || ':ver:' || coalesce(p_version_id::text, 'new'),
    v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' OR unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-019', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
END;
$$;

-- 4. CMD-033: create-upload-intent (admit video/mp4 & video/webm up to 25 MiB)
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
     OR p_mime_type NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'video/mp4', 'video/webm')
     OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 26214400
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

-- 5. CMD-034: confirm-upload (admit up to 25 MiB server-verified binaries)
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
     OR p_observed_byte_size IS NULL OR p_observed_byte_size NOT BETWEEN 1 AND 26214400
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

ALTER FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) TO authenticated;

ALTER FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cmd_create_upload_intent_v1(text, uuid, uuid, text, integer, text, text) TO authenticated;

ALTER FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cmd_confirm_upload_v1(text, uuid, text, integer, text) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
