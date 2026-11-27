-- Migration: 20261127060200_i2_cmd018_025_instruments_and_canonical_units.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for CMD-018..CMD-025
--        (Extensible Instruments CFG-001/T-17 & Canonical Units/Associations/Conflicts T-16).
-- Authority: AGENTS.md v1.3.0, Command Catalogue v1.0.0, LOCK-GRAPH-001 v1.0.0,
--            CONCURRENCY-001 v1.0.0, T-16, T-17, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- ===========================================================================
-- CMD-018: create-instrument (instrument.manage, global catalog, starts DRAFT)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_create_instrument_v1(
  p_idempotency_key text,
  p_instrument_type text,
  p_code text,
  p_name text,
  p_description text DEFAULT NULL,
  p_serial_case_insensitive boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_type text;
  v_code text;
  v_name text;
  v_desc text;
  v_req_hash text;
  v_idem jsonb;
  v_inst public.instruments%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_type := pg_catalog.upper(pg_catalog.btrim(coalesce(p_instrument_type, '')));
  v_code := pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')));
  v_name := pg_catalog.btrim(coalesce(p_name, ''));
  v_desc := nullif(pg_catalog.btrim(coalesce(p_description, '')), '');

  IF v_type !~ '^[A-Z][A-Z0-9_]{1,63}$'
     OR v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'
     OR pg_catalog.char_length(v_name) NOT BETWEEN 2 AND 160
     OR (v_desc IS NOT NULL AND pg_catalog.char_length(v_desc) > 1000)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'instrument_type', v_type, 'code', v_code, 'name', v_name,
    'description', v_desc, 'serial_case_insensitive', coalesce(p_serial_case_insensitive, true)
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-018', 'instrument_code:' || v_code, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'instrument.manage', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.instruments (
      instrument_type, code, name, description, status, serial_case_insensitive, row_version, created_by
    ) VALUES (
      v_type, v_code, v_name, v_desc, 'DRAFT', coalesce(p_serial_case_insensitive, true), 1, v_actor_id
    )
    RETURNING * INTO v_inst;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-018', 'status', 'DUPLICATE_CODE', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'instrument.created', v_actor_id, v_auth_uid, 'CMD-018',
    'INSTRUMENT', v_inst.id, 'instruments', v_inst.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('instrument_type', v_inst.instrument_type, 'code', v_inst.code, 'status', 'DRAFT')
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-018',
    'status', 'CREATED',
    'instrument_id', v_inst.id,
    'instrument_type', v_inst.instrument_type,
    'code', v_inst.code,
    'instrument_status', v_inst.status,
    'row_version', v_inst.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-018', 'instrument_code:' || v_code, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-019: save-instrument-draft (instrument.manage, atomic declarative replace)
-- ===========================================================================
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

  -- L40 lock instrument row
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

    -- Replace draft children atomically
    DELETE FROM public.checklist_items
    WHERE section_id IN (SELECT id FROM public.checklist_sections WHERE instrument_version_id = v_ver.id);
    DELETE FROM public.checklist_sections WHERE instrument_version_id = v_ver.id;
    DELETE FROM public.specification_fields WHERE instrument_version_id = v_ver.id;
    DELETE FROM public.evidence_slot_definitions WHERE instrument_version_id = v_ver.id;
  END IF;

  -- Insert declarative sections & items
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

  -- Insert specification fields
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

  -- Insert evidence slots with strict MIME allowlist
  FOR v_slot IN SELECT * FROM pg_catalog.jsonb_array_elements(p_evidence_slots)
  LOOP
    v_slot_idx := v_slot_idx + 1;
    IF coalesce(v_slot->>'code', '') !~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'
       OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_slot->>'label', ''))) NOT BETWEEN 1 AND 200
       OR v_slot->'allowed_media_types' IS NULL
       OR pg_catalog.jsonb_typeof(v_slot->'allowed_media_types') <> 'array'
       OR pg_catalog.jsonb_array_length(v_slot->'allowed_media_types') NOT BETWEEN 1 AND 5
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    SELECT pg_catalog.array_agg(elem) INTO v_allowed_mimes
    FROM pg_catalog.jsonb_array_elements_text(v_slot->'allowed_media_types') AS elem;

    FOREACH v_mime IN ARRAY v_allowed_mimes
    LOOP
      IF v_mime NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf') THEN
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

-- ===========================================================================
-- CMD-020: publish-instrument-version (T-17 explicit instrument.publish only)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_publish_instrument_version_v1(
  p_idempotency_key text,
  p_instrument_id uuid,
  p_version_id uuid,
  p_expected_draft_hash text,
  p_change_summary text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_summary text;
  v_req_hash text;
  v_idem jsonb;
  v_inst public.instruments%ROWTYPE;
  v_ver public.instrument_versions%ROWTYPE;
  v_item_count integer;
  v_snapshot jsonb;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_summary := pg_catalog.btrim(coalesce(p_change_summary, ''));
  IF p_instrument_id IS NULL OR p_version_id IS NULL
     OR pg_catalog.char_length(coalesce(p_expected_draft_hash, '')) <> 64
     OR pg_catalog.char_length(v_summary) NOT BETWEEN 3 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'instrument_id', p_instrument_id, 'version_id', p_version_id,
    'expected_draft_hash', p_expected_draft_hash, 'change_summary', v_summary
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-020', 'instrument_version:' || p_version_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- T-17: explicit instrument.publish permission required (instrument.manage alone insufficient)
  IF NOT app_internal.actor_has_permission(v_actor_id, 'instrument.publish', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- L40 lock instrument -> version
  SELECT * INTO v_inst FROM public.instruments WHERE id = p_instrument_id FOR UPDATE;
  SELECT * INTO v_ver FROM public.instrument_versions WHERE id = p_version_id AND instrument_id = p_instrument_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_ver.status <> 'DRAFT' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_ver.draft_hash IS DISTINCT FROM p_expected_draft_hash THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'STALE_DRAFT', 'server_time', pg_catalog.now());
  END IF;

  SELECT pg_catalog.count(*)::integer INTO v_item_count
  FROM public.checklist_items ci
  JOIN public.checklist_sections cs ON cs.id = ci.section_id
  WHERE cs.instrument_version_id = v_ver.id;

  IF v_item_count < 1 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-020', 'status', 'SCHEMA_INVALID', 'server_time', pg_catalog.now());
  END IF;

  -- Build immutable canonical snapshot JSON
  SELECT pg_catalog.jsonb_build_object(
    'instrument_id', v_inst.id,
    'instrument_type', v_inst.instrument_type,
    'version_number', v_ver.version_number,
    'schema_version', v_ver.schema_version,
    'sections', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', cs.id, 'code', cs.code, 'label', cs.label, 'sort_order', cs.sort_order,
        'items', coalesce((
          SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
            'id', ci.id, 'code', ci.code, 'label', ci.label, 'answer_type', ci.answer_type,
            'required', ci.required, 'sort_order', ci.sort_order
          ) ORDER BY ci.sort_order)
          FROM public.checklist_items ci WHERE ci.section_id = cs.id
        ), '[]'::jsonb)
      ) ORDER BY cs.sort_order)
      FROM public.checklist_sections cs WHERE cs.instrument_version_id = v_ver.id
    ), '[]'::jsonb),
    'specification_fields', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', sf.id, 'code', sf.code, 'label', sf.label, 'value_type', sf.value_type,
        'expected_value', sf.expected_value, 'unit', sf.unit, 'required', sf.required, 'sort_order', sf.sort_order
      ) ORDER BY sf.sort_order)
      FROM public.specification_fields sf WHERE sf.instrument_version_id = v_ver.id
    ), '[]'::jsonb),
    'evidence_slots', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', es.id, 'code', es.code, 'label', es.label, 'required', es.required,
        'allowed_media_types', es.allowed_media_types, 'sort_order', es.sort_order
      ) ORDER BY es.sort_order)
      FROM public.evidence_slot_definitions es WHERE es.instrument_version_id = v_ver.id
    ), '[]'::jsonb)
  ) INTO v_snapshot;

  UPDATE public.instrument_versions
  SET status = 'PUBLISHED',
      published_snapshot = v_snapshot,
      published_by = v_actor_id,
      published_at = pg_catalog.now(),
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_ver.id
  RETURNING * INTO v_ver;

  IF v_inst.status = 'DRAFT' THEN
    UPDATE public.instruments
    SET status = 'ACTIVE', row_version = row_version + 1, updated_at = pg_catalog.now()
    WHERE id = v_inst.id
    RETURNING * INTO v_inst;
  END IF;

  INSERT INTO public.instrument_version_publications (
    instrument_version_id, published_by, change_summary, config_hash
  ) VALUES (
    v_ver.id, v_actor_id, v_summary, v_ver.draft_hash
  );

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'instrument.version_published', v_actor_id, v_auth_uid, 'CMD-020',
    'INSTRUMENT', v_inst.id, 'instrument_versions', v_ver.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('version_number', v_ver.version_number, 'config_hash', v_ver.draft_hash, 'change_summary', v_summary)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-020',
    'status', 'PUBLISHED',
    'instrument_id', v_inst.id,
    'instrument_status', v_inst.status,
    'version_id', v_ver.id,
    'version_number', v_ver.version_number,
    'config_hash', v_ver.draft_hash,
    'row_version', v_ver.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-020', 'instrument_version:' || p_version_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-021: deactivate-instrument (T-17 explicit instrument.deactivate, preserves history)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_deactivate_instrument_v1(
  p_idempotency_key text,
  p_instrument_id uuid,
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
  v_inst public.instruments%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_instrument_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'instrument_id', p_instrument_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-021', 'instrument:' || p_instrument_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'instrument.deactivate', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_inst FROM public.instruments WHERE id = p_instrument_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_inst.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_inst.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-021', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.instruments
  SET status = 'INACTIVE', row_version = row_version + 1, updated_at = pg_catalog.now()
  WHERE id = p_instrument_id
  RETURNING * INTO v_inst;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'instrument.deactivated', v_actor_id, v_auth_uid, 'CMD-021',
    'INSTRUMENT', v_inst.id, 'instruments', v_inst.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('reason', v_reason, 'row_version', v_inst.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-021',
    'status', 'DEACTIVATED',
    'instrument_id', v_inst.id,
    'row_version', v_inst.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-021', 'instrument:' || p_instrument_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-022: register-canonical-unit (T-16 Option B global canonical key)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_register_canonical_unit_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_instrument_id uuid,
  p_serial_raw text DEFAULT NULL,
  p_identity_attributes jsonb DEFAULT '{}'::jsonb
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
  v_project public.projects%ROWTYPE;
  v_inst public.instruments%ROWTYPE;
  v_serial_norm text;
  v_unit public.units%ROWTYPE;
  v_assoc public.unit_project_associations%ROWTYPE;
  v_conflict public.unit_identity_conflicts%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_project_id IS NULL OR p_instrument_id IS NULL
     OR (p_identity_attributes IS NOT NULL AND pg_catalog.jsonb_typeof(p_identity_attributes) <> 'object')
     OR (p_serial_raw IS NOT NULL AND (pg_catalog.char_length(p_serial_raw) > 160 OR p_serial_raw ~ '[[:cntrl:]]'))
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'instrument_id', p_instrument_id,
    'serial_raw', p_serial_raw, 'identity_attributes', coalesce(p_identity_attributes, '{}'::jsonb)
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-022',
    'project:' || p_project_id::text || ':inst:' || p_instrument_id::text,
    p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- Resolve instrument type first so L20 canonical key lock precedes L30 project fence
  SELECT * INTO v_inst FROM public.instruments WHERE id = p_instrument_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  v_serial_norm := app_internal.normalize_serial(p_serial_raw, v_inst.serial_case_insensitive);

  -- L20 canonical identity arbitration lock (only when serial is known)
  IF v_serial_norm IS NOT NULL THEN
    PERFORM pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(v_inst.instrument_type || ':' || v_serial_norm, 0)
    );
  END IF;

  -- L30 project parent fence -> L40 instrument lock
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'unit.register', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' OR v_inst.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-022', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- Check if canonical unit already exists for (instrument_type, serial_normalized)
  IF v_serial_norm IS NOT NULL THEN
    SELECT * INTO v_unit
    FROM public.units
    WHERE instrument_type = v_inst.instrument_type AND serial_normalized = v_serial_norm
    FOR SHARE;
  END IF;

  IF v_unit.id IS NULL THEN
    -- Brand-new canonical unit (or unknown-serial distinct UUID) + ACTIVE project association
    INSERT INTO public.units (
      instrument_type, serial_raw, serial_normalized, normalization_version,
      identity_attributes, status, created_by
    ) VALUES (
      v_inst.instrument_type,
      nullif(p_serial_raw, ''),
      v_serial_norm,
      'v1',
      coalesce(p_identity_attributes, '{}'::jsonb),
      'ACTIVE',
      v_actor_id
    )
    RETURNING * INTO v_unit;

    INSERT INTO public.unit_project_associations (
      unit_id, project_id, status, associated_by, association_reason, row_version
    ) VALUES (
      v_unit.id, p_project_id, 'ACTIVE', v_actor_id, 'Initial canonical unit registration', 1
    )
    RETURNING * INTO v_assoc;

    INSERT INTO public.audit_events (
      event_type, actor_user_id, actor_auth_uid, command_id,
      scope_type, scope_id, target_table, target_id,
      idempotency_key_hash, outcome, metadata
    ) VALUES (
      'unit.registered', v_actor_id, v_auth_uid, 'CMD-022',
      'PROJECT', p_project_id, 'units', v_unit.id,
      v_idem->>'key_hash', 'SUCCESS',
      pg_catalog.jsonb_build_object('instrument_type', v_unit.instrument_type, 'association_id', v_assoc.id)
    );

    v_response := pg_catalog.jsonb_build_object(
      'command_id', 'CMD-022',
      'status', 'REGISTERED',
      'unit_id', v_unit.id,
      'association_id', v_assoc.id,
      'instrument_type', v_unit.instrument_type,
      'serial_normalized', v_unit.serial_normalized,
      'server_time', pg_catalog.now()
    );
  ELSE
    -- Canonical unit already exists: check if actively associated to THIS project
    SELECT * INTO v_assoc
    FROM public.unit_project_associations
    WHERE unit_id = v_unit.id AND project_id = p_project_id AND status = 'ACTIVE';

    IF FOUND THEN
      v_response := pg_catalog.jsonb_build_object(
        'command_id', 'CMD-022',
        'status', 'EXISTING_AUTHORIZED',
        'unit_id', v_unit.id,
        'association_id', v_assoc.id,
        'instrument_type', v_unit.instrument_type,
        'serial_normalized', v_unit.serial_normalized,
        'server_time', pg_catalog.now()
      );
    ELSE
      -- T-16 collision: DO NOT disclose other project activity; open controlled conflict workflow
      SELECT * INTO v_conflict
      FROM public.unit_identity_conflicts
      WHERE instrument_type = v_inst.instrument_type
        AND serial_normalized = v_serial_norm
        AND proposed_project_id = p_project_id
        AND status = 'OPEN';

      IF NOT FOUND THEN
        INSERT INTO public.unit_identity_conflicts (
          instrument_type, serial_normalized, serial_raw_submitted,
          proposed_project_id, candidate_unit_id, reported_by, status, row_version
        ) VALUES (
          v_inst.instrument_type, v_serial_norm, p_serial_raw,
          p_project_id, v_unit.id, v_actor_id, 'OPEN', 1
        )
        RETURNING * INTO v_conflict;

        INSERT INTO public.audit_events (
          event_type, actor_user_id, actor_auth_uid, command_id,
          scope_type, scope_id, target_table, target_id,
          idempotency_key_hash, outcome, metadata
        ) VALUES (
          'unit.identity_conflict_opened', v_actor_id, v_auth_uid, 'CMD-022',
          'PROJECT', p_project_id, 'unit_identity_conflicts', v_conflict.id,
          v_idem->>'key_hash', 'CONFLICT',
          pg_catalog.jsonb_build_object('instrument_type', v_inst.instrument_type)
        );
      END IF;

      -- Notice: candidate_unit_id and other project details are NOT disclosed to caller!
      v_response := pg_catalog.jsonb_build_object(
        'command_id', 'CMD-022',
        'status', 'CONFLICT_REVIEW_REQUIRED',
        'conflict_id', v_conflict.id,
        'instrument_type', v_inst.instrument_type,
        'server_time', pg_catalog.now()
      );
    END IF;
  END IF;

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-022',
    'project:' || p_project_id::text || ':inst:' || p_instrument_id::text,
    v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-023: associate-unit-to-project (unit.associate, T-16)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_associate_unit_to_project_v1(
  p_idempotency_key text,
  p_unit_id uuid,
  p_project_id uuid,
  p_reason text,
  p_evidence_ref text DEFAULT NULL
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
  v_ev_ref text;
  v_req_hash text;
  v_idem jsonb;
  v_project public.projects%ROWTYPE;
  v_unit public.units%ROWTYPE;
  v_assoc public.unit_project_associations%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  v_ev_ref := nullif(pg_catalog.btrim(coalesce(p_evidence_ref, '')), '');
  IF p_unit_id IS NULL OR p_project_id IS NULL OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 500 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'unit_id', p_unit_id, 'project_id', p_project_id, 'reason', v_reason, 'evidence_ref', v_ev_ref
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-023', 'unit:' || p_unit_id::text || ':project:' || p_project_id::text, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- Ascending order: L30 project FOR SHARE -> L60 unit FOR SHARE
  SELECT * INTO v_project FROM public.projects WHERE id = p_project_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'unit.associate', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_unit FROM public.units WHERE id = p_unit_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' OR v_unit.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.unit_identity_conflicts c
    WHERE c.candidate_unit_id = p_unit_id AND c.proposed_project_id = p_project_id AND c.status = 'OPEN'
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'CONFLICT_OPEN', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.unit_project_associations (
      unit_id, project_id, status, associated_by, association_reason, evidence_ref, row_version
    ) VALUES (
      p_unit_id, p_project_id, 'ACTIVE', v_actor_id, v_reason, v_ev_ref, 1
    )
    RETURNING * INTO v_assoc;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-023', 'status', 'ACTIVE_ASSOCIATION_EXISTS', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'unit.project_associated', v_actor_id, v_auth_uid, 'CMD-023',
    'PROJECT', p_project_id, 'unit_project_associations', v_assoc.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('unit_id', p_unit_id, 'reason', v_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-023',
    'status', 'ASSOCIATED',
    'association_id', v_assoc.id,
    'unit_id', p_unit_id,
    'project_id', p_project_id,
    'row_version', v_assoc.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-023', 'unit:' || p_unit_id::text || ':project:' || p_project_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-024: end-unit-project-association (unit.association.end, soft ENDED/REVOKED)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_end_unit_project_association_v1(
  p_idempotency_key text,
  p_association_id uuid,
  p_outcome text,
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
  v_assoc public.unit_project_associations%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_association_id IS NULL OR p_outcome NOT IN ('ENDED', 'REVOKED')
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 3 AND 500
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'association_id', p_association_id, 'outcome', p_outcome,
    'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-024', 'association:' || p_association_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_assoc FROM public.unit_project_associations WHERE id = p_association_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'unit.association.end', v_assoc.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_assoc.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_assoc.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-024', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.unit_project_associations
  SET status = p_outcome,
      ended_at = pg_catalog.now(),
      ended_by = v_actor_id,
      end_reason = v_reason,
      row_version = row_version + 1
  WHERE id = p_association_id
  RETURNING * INTO v_assoc;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN p_outcome = 'ENDED' THEN 'unit.project_association_ended' ELSE 'unit.project_association_revoked' END,
    v_actor_id, v_auth_uid, 'CMD-024',
    'PROJECT', v_assoc.project_id, 'unit_project_associations', v_assoc.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('unit_id', v_assoc.unit_id, 'outcome', p_outcome, 'reason', v_reason, 'row_version', v_assoc.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-024',
    'status', p_outcome,
    'association_id', v_assoc.id,
    'row_version', v_assoc.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-024', 'association:' || p_association_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-025: resolve-unit-identity-conflict (unit.identity.resolve, T-16)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_resolve_unit_identity_conflict_v1(
  p_idempotency_key text,
  p_conflict_id uuid,
  p_resolution text,
  p_expected_row_version bigint,
  p_reason text,
  p_verified_unit_id uuid DEFAULT NULL
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
  v_conflict public.unit_identity_conflicts%ROWTYPE;
  v_assoc public.unit_project_associations%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_conflict_id IS NULL OR p_resolution NOT IN ('ASSOCIATE_EXISTING', 'REJECT')
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'conflict_id', p_conflict_id, 'resolution', p_resolution,
    'expected_row_version', p_expected_row_version::text, 'verified_unit_id', p_verified_unit_id, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-025', 'conflict:' || p_conflict_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_conflict FROM public.unit_identity_conflicts WHERE id = p_conflict_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'unit.identity.resolve', v_conflict.proposed_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_conflict.reported_by = v_actor_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  IF v_conflict.status <> 'OPEN' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_conflict.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  IF p_resolution = 'ASSOCIATE_EXISTING' THEN
    IF p_verified_unit_id IS NOT NULL AND p_verified_unit_id <> v_conflict.candidate_unit_id THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-025', 'status', 'CANDIDATE_MISMATCH', 'server_time', pg_catalog.now());
    END IF;

    BEGIN
      INSERT INTO public.unit_project_associations (
        unit_id, project_id, status, associated_by, association_reason, row_version
      ) VALUES (
        v_conflict.candidate_unit_id, v_conflict.proposed_project_id, 'ACTIVE', v_actor_id,
        'Resolved identity conflict: ' || v_reason, 1
      )
      RETURNING * INTO v_assoc;
    EXCEPTION WHEN unique_violation THEN
      SELECT * INTO v_assoc FROM public.unit_project_associations
      WHERE unit_id = v_conflict.candidate_unit_id AND project_id = v_conflict.proposed_project_id AND status = 'ACTIVE';
    END;

    UPDATE public.unit_identity_conflicts
    SET status = 'RESOLVED',
        resolution = 'ASSOCIATE_EXISTING',
        resolved_by = v_actor_id,
        resolution_reason = v_reason,
        resolved_at = pg_catalog.now(),
        row_version = row_version + 1
    WHERE id = p_conflict_id
    RETURNING * INTO v_conflict;

    INSERT INTO public.audit_events (
      event_type, actor_user_id, actor_auth_uid, command_id,
      scope_type, scope_id, target_table, target_id,
      idempotency_key_hash, outcome, metadata
    ) VALUES (
      'unit.identity_conflict_resolved', v_actor_id, v_auth_uid, 'CMD-025',
      'PROJECT', v_conflict.proposed_project_id, 'unit_identity_conflicts', v_conflict.id,
      v_idem->>'key_hash', 'SUCCESS',
      pg_catalog.jsonb_build_object('unit_id', v_conflict.candidate_unit_id, 'association_id', v_assoc.id, 'reason', v_reason)
    );

    v_response := pg_catalog.jsonb_build_object(
      'command_id', 'CMD-025',
      'status', 'RESOLVED',
      'conflict_id', v_conflict.id,
      'unit_id', v_conflict.candidate_unit_id,
      'association_id', v_assoc.id,
      'row_version', v_conflict.row_version::text,
      'server_time', pg_catalog.now()
    );
  ELSE
    UPDATE public.unit_identity_conflicts
    SET status = 'REJECTED',
        resolution = 'REJECT',
        resolved_by = v_actor_id,
        resolution_reason = v_reason,
        resolved_at = pg_catalog.now(),
        row_version = row_version + 1
    WHERE id = p_conflict_id
    RETURNING * INTO v_conflict;

    INSERT INTO public.audit_events (
      event_type, actor_user_id, actor_auth_uid, command_id,
      scope_type, scope_id, target_table, target_id,
      idempotency_key_hash, outcome, metadata
    ) VALUES (
      'unit.identity_conflict_rejected', v_actor_id, v_auth_uid, 'CMD-025',
      'PROJECT', v_conflict.proposed_project_id, 'unit_identity_conflicts', v_conflict.id,
      v_idem->>'key_hash', 'SUCCESS',
      pg_catalog.jsonb_build_object('reason', v_reason)
    );

    v_response := pg_catalog.jsonb_build_object(
      'command_id', 'CMD-025',
      'status', 'REJECTED',
      'conflict_id', v_conflict.id,
      'row_version', v_conflict.row_version::text,
      'server_time', pg_catalog.now()
    );
  END IF;

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-025', 'conflict:' || p_conflict_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_create_instrument_v1(text, text, text, text, text, boolean) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_create_instrument_v1(text, text, text, text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_create_instrument_v1(text, text, text, text, text, boolean) TO authenticated;

ALTER FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_save_instrument_draft_v1(text, uuid, uuid, text, jsonb, jsonb, jsonb) TO authenticated;

ALTER FUNCTION public.cmd_publish_instrument_version_v1(text, uuid, uuid, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_publish_instrument_version_v1(text, uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_publish_instrument_version_v1(text, uuid, uuid, text, text) TO authenticated;

ALTER FUNCTION public.cmd_deactivate_instrument_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_deactivate_instrument_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_deactivate_instrument_v1(text, uuid, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_register_canonical_unit_v1(text, uuid, uuid, text, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_register_canonical_unit_v1(text, uuid, uuid, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_register_canonical_unit_v1(text, uuid, uuid, text, jsonb) TO authenticated;

ALTER FUNCTION public.cmd_associate_unit_to_project_v1(text, uuid, uuid, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_associate_unit_to_project_v1(text, uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_associate_unit_to_project_v1(text, uuid, uuid, text, text) TO authenticated;

ALTER FUNCTION public.cmd_end_unit_project_association_v1(text, uuid, text, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_end_unit_project_association_v1(text, uuid, text, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_end_unit_project_association_v1(text, uuid, text, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_resolve_unit_identity_conflict_v1(text, uuid, text, bigint, text, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_resolve_unit_identity_conflict_v1(text, uuid, text, bigint, text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_resolve_unit_identity_conflict_v1(text, uuid, text, bigint, text, uuid) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
