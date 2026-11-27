-- Migration: 20261127070100_i3_cmd026_032_and_055_056_claims_inspections_review_abort.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for CMD-026..CMD-032 + CMD-055..056.
-- Authority: AGENTS.md v1.3.0, Command Catalogue v1.0.0, LOCK-GRAPH-001 v1.0.0,
--            IDC-O04..O10, SES-001, T-16, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- ===========================================================================
-- CMD-026: claim-unit (inspection.claim; global 1-active-claim per unit, DB time expiry)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_claim_unit_v1(
  p_idempotency_key text,
  p_unit_id uuid,
  p_association_id uuid,
  p_assignment_id uuid,
  p_claim_ttl_minutes integer DEFAULT 120
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_ttl integer;
  v_req_hash text;
  v_idem jsonb;
  v_assignment public.operational_assignments%ROWTYPE;
  v_project public.projects%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_inst public.instruments%ROWTYPE;
  v_unit public.units%ROWTYPE;
  v_assoc public.unit_project_associations%ROWTYPE;
  v_existing_claim public.unit_claims%ROWTYPE;
  v_claim public.unit_claims%ROWTYPE;
  v_inspection public.inspections%ROWTYPE;
  v_status text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_ttl := coalesce(p_claim_ttl_minutes, 120);
  IF p_unit_id IS NULL OR p_association_id IS NULL OR p_assignment_id IS NULL OR v_ttl NOT BETWEEN 5 AND 480 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'unit_id', p_unit_id, 'association_id', p_association_id,
    'assignment_id', p_assignment_id, 'ttl', v_ttl
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-026', 'unit:' || p_unit_id::text || ':asgn:' || p_assignment_id::text, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  -- Lookup assignment first to lock in strict ascending order: L30 -> L40 -> L50 -> L60 -> L70 -> L80 -> L90
  SELECT * INTO v_assignment FROM public.operational_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_project FROM public.projects WHERE id = v_assignment.project_id FOR SHARE;
  SELECT * INTO v_session FROM public.sessions WHERE id = v_assignment.session_id FOR SHARE;
  SELECT * INTO v_inst FROM public.instruments WHERE id = v_assignment.instrument_id FOR SHARE;
  SELECT * INTO v_assignment FROM public.operational_assignments WHERE id = p_assignment_id FOR SHARE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.claim', v_assignment.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- Verify active Inspector membership on this assignment
  IF NOT EXISTS (
    SELECT 1 FROM public.assignment_members am
    WHERE am.assignment_id = p_assignment_id
      AND am.user_id = v_actor_id
      AND am.operational_role = 'inspector'
      AND am.status = 'ACTIVE'
      AND am.valid_from <= pg_catalog.now()
      AND (am.valid_until IS NULL OR am.valid_until > pg_catalog.now())
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'PERMISSION_DENIED', 'error_code', 'NOT_ASSIGNED_INSPECTOR', 'server_time', pg_catalog.now());
  END IF;

  IF v_project.status <> 'ACTIVE' OR v_session.status <> 'ACTIVE' OR v_assignment.status <> 'PUBLISHED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- L60 canonical unit row lock -> L70 association verification
  SELECT * INTO v_unit FROM public.units WHERE id = p_unit_id FOR UPDATE;
  IF NOT FOUND OR v_unit.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_unit.instrument_type <> v_inst.instrument_type THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'INSTRUMENT_MISMATCH', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_assoc
  FROM public.unit_project_associations
  WHERE id = p_association_id AND unit_id = p_unit_id AND project_id = v_assignment.project_id
  FOR SHARE;
  IF NOT FOUND OR v_assoc.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'ASSOCIATION_REQUIRED', 'server_time', pg_catalog.now());
  END IF;

  -- L80 check active global claim across ALL projects; expire stale claims using DB time only
  SELECT * INTO v_existing_claim
  FROM public.unit_claims
  WHERE unit_id = p_unit_id AND status = 'ACTIVE'
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_claim.expires_at <= pg_catalog.now() THEN
      UPDATE public.unit_claims
      SET status = 'EXPIRED', released_at = pg_catalog.now(), release_reason = 'Claim expired at server takeover', row_version = row_version + 1
      WHERE id = v_existing_claim.id;
    ELSIF v_existing_claim.inspector_id = v_actor_id AND v_existing_claim.assignment_id = p_assignment_id THEN
      -- Same inspector resuming own active claim: extend TTL cleanly
      UPDATE public.unit_claims
      SET expires_at = pg_catalog.now() + pg_catalog.make_interval(mins => v_ttl), row_version = row_version + 1
      WHERE id = v_existing_claim.id
      RETURNING * INTO v_claim;
      v_status := 'RESUMED';
    ELSE
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-026', 'status', 'ACTIVE_CLAIM_EXISTS', 'server_time', pg_catalog.now());
    END IF;
  END IF;

  IF v_claim.id IS NULL THEN
    INSERT INTO public.unit_claims (
      unit_id, unit_project_association_id, project_id, assignment_id,
      inspector_id, status, claimed_at, expires_at, row_version
    ) VALUES (
      p_unit_id, p_association_id, v_assignment.project_id, p_assignment_id,
      v_actor_id, 'ACTIVE', pg_catalog.now(), pg_catalog.now() + pg_catalog.make_interval(mins => v_ttl), 1
    )
    RETURNING * INTO v_claim;
    v_status := 'CLAIMED';
  END IF;

  -- L90 find existing non-terminal inspection for (unit_id, session_id) or create fresh DRAFT
  SELECT * INTO v_inspection
  FROM public.inspections
  WHERE unit_id = p_unit_id AND session_id = v_assignment.session_id
    AND status NOT IN ('APPROVED', 'ABORTED')
  FOR UPDATE;

  IF FOUND THEN
    -- Update owner on claim takeover or reopened inspection claim (IDC-O04..O06)
    UPDATE public.inspections
    SET owner_user_id = v_actor_id,
        assignment_id = p_assignment_id,
        row_version = row_version + 1,
        updated_at = pg_catalog.now()
    WHERE id = v_inspection.id
    RETURNING * INTO v_inspection;
  ELSE
    INSERT INTO public.inspections (
      unit_id, unit_project_association_id, project_id, session_id, assignment_id,
      instrument_version_id, status, current_revision_no, owner_user_id, row_version, created_by
    ) VALUES (
      p_unit_id, p_association_id, v_assignment.project_id, v_assignment.session_id, p_assignment_id,
      v_assignment.instrument_version_id, 'DRAFT', 0, v_actor_id, 1, v_actor_id
    )
    RETURNING * INTO v_inspection;

    INSERT INTO public.inspection_draft_contexts (
      inspection_id, draft_checklist, draft_specifications, updated_by, row_version
    ) VALUES (
      v_inspection.id, '{}'::jsonb, '{}'::jsonb, v_actor_id, 1
    );

    INSERT INTO public.inspection_events (
      inspection_id, event_type, actor_id, from_state, to_state, reason
    ) VALUES (
      v_inspection.id, 'inspection.created', v_actor_id, NULL, 'DRAFT', 'Claimed physical unit'
    );
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'unit.claimed', v_actor_id, v_auth_uid, 'CMD-026',
    'PROJECT', v_assignment.project_id, 'unit_claims', v_claim.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('unit_id', p_unit_id, 'inspection_id', v_inspection.id, 'claim_status', v_status)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-026',
    'status', v_status,
    'claim_id', v_claim.id,
    'claim_row_version', v_claim.row_version::text,
    'expires_at', v_claim.expires_at,
    'inspection_id', v_inspection.id,
    'inspection_status', v_inspection.status,
    'inspection_row_version', v_inspection.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-026', 'unit:' || p_unit_id::text || ':asgn:' || p_assignment_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-027: release-unit-claim (preserves draft/evidence; denies if SUBMITTED/APPROVED)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_release_unit_claim_v1(
  p_idempotency_key text,
  p_claim_id uuid,
  p_expected_row_version bigint,
  p_reason text DEFAULT NULL
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
  v_claim public.unit_claims%ROWTYPE;
  v_inspection public.inspections%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := nullif(pg_catalog.btrim(coalesce(p_reason, '')), '');
  IF p_claim_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'claim_id', p_claim_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-027', 'claim:' || p_claim_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_claim FROM public.unit_claims WHERE id = p_claim_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_claim.inspector_id <> v_actor_id
     AND NOT app_internal.actor_has_permission(v_actor_id, 'session.transition', v_claim.project_id)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'NOT_OWNER', 'server_time', pg_catalog.now());
  END IF;

  IF v_claim.status <> 'ACTIVE' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_claim.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  -- Check linked inspection state: ordinary release prohibited if SUBMITTED
  SELECT * INTO v_inspection
  FROM public.inspections
  WHERE unit_id = v_claim.unit_id AND assignment_id = v_claim.assignment_id
    AND status NOT IN ('APPROVED', 'ABORTED')
  FOR SHARE;

  IF FOUND AND v_inspection.status = 'SUBMITTED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-027', 'status', 'STATE_CONFLICT', 'error_code', 'UNDER_REVIEW', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.unit_claims
  SET status = 'RELEASED',
      released_at = pg_catalog.now(),
      release_reason = coalesce(v_reason, 'Released by inspector'),
      row_version = row_version + 1
  WHERE id = p_claim_id
  RETURNING * INTO v_claim;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'unit.claim_released', v_actor_id, v_auth_uid, 'CMD-027',
    'PROJECT', v_claim.project_id, 'unit_claims', v_claim.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('unit_id', v_claim.unit_id, 'reason', v_claim.release_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-027',
    'status', 'RELEASED',
    'claim_id', v_claim.id,
    'row_version', v_claim.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-027', 'claim:' || p_claim_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-028: save-draft (inspection.edit; requires own live claim + CAS expected_row_version)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_save_draft_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_expected_row_version bigint,
  p_draft_checklist jsonb,
  p_draft_specifications jsonb DEFAULT '{}'::jsonb,
  p_notes text DEFAULT NULL
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
  v_insp public.inspections%ROWTYPE;
  v_claim_ok boolean;
  v_key text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_inspection_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR p_draft_checklist IS NULL OR pg_catalog.jsonb_typeof(p_draft_checklist) <> 'object'
     OR p_draft_specifications IS NULL OR pg_catalog.jsonb_typeof(p_draft_specifications) <> 'object'
     OR (p_notes IS NOT NULL AND pg_catalog.char_length(p_notes) > 2000)
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'expected_row_version', p_expected_row_version::text,
    'checklist', p_draft_checklist, 'specs', p_draft_specifications, 'notes', p_notes
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-028', 'inspection:' || p_inspection_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.edit', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- Verify own live unexpired claim on this unit + project
  SELECT EXISTS (
    SELECT 1 FROM public.unit_claims c
    WHERE c.unit_id = v_insp.unit_id
      AND c.project_id = v_insp.project_id
      AND c.inspector_id = v_actor_id
      AND c.status = 'ACTIVE'
      AND c.expires_at > pg_catalog.now()
  ) INTO v_claim_ok;

  IF NOT v_claim_ok THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'CLAIM_INVALID', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  -- Validate every checklist key belongs to pinned instrument_version_id
  FOR v_key IN SELECT pg_catalog.jsonb_object_keys(p_draft_checklist)
  LOOP
    IF v_key !~ '^[0-9a-fA-F-]{36}$' OR NOT EXISTS (
      SELECT 1
      FROM public.checklist_items ci
      JOIN public.checklist_sections cs ON cs.id = ci.section_id
      WHERE ci.id = v_key::uuid AND cs.instrument_version_id = v_insp.instrument_version_id
    ) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'VALIDATION_FAILED', 'error_code', 'INVALID_CHECKLIST_ITEM', 'server_time', pg_catalog.now());
    END IF;
  END LOOP;

  -- Validate every specification field key belongs to pinned instrument_version_id
  FOR v_key IN SELECT pg_catalog.jsonb_object_keys(p_draft_specifications)
  LOOP
    IF v_key !~ '^[0-9a-fA-F-]{36}$' OR NOT EXISTS (
      SELECT 1
      FROM public.specification_fields sf
      WHERE sf.id = v_key::uuid AND sf.instrument_version_id = v_insp.instrument_version_id
    ) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-028', 'status', 'VALIDATION_FAILED', 'error_code', 'INVALID_SPEC_FIELD', 'server_time', pg_catalog.now());
    END IF;
  END LOOP;

  UPDATE public.inspection_draft_contexts
  SET draft_checklist = p_draft_checklist,
      draft_specifications = p_draft_specifications,
      notes = p_notes,
      has_unresolved_sync_conflict = false,
      updated_by = v_actor_id,
      updated_at = pg_catalog.now(),
      row_version = row_version + 1
  WHERE inspection_id = p_inspection_id;

  UPDATE public.inspections
  SET row_version = row_version + 1, updated_at = pg_catalog.now()
  WHERE id = p_inspection_id
  RETURNING * INTO v_insp;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.draft_saved', v_actor_id, v_auth_uid, 'CMD-028',
    'PROJECT', v_insp.project_id, 'inspections', v_insp.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('row_version', v_insp.row_version::text)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-028',
    'status', 'SAVED',
    'inspection_id', v_insp.id,
    'row_version', v_insp.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-028', 'inspection:' || p_inspection_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-029: submit-inspection (creates immutable revision + responses + locks evidence)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_submit_inspection_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_expected_row_version bigint,
  p_submit_reason text DEFAULT NULL
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
  v_insp public.inspections%ROWTYPE;
  v_draft public.inspection_draft_contexts%ROWTYPE;
  v_claim_ok boolean;
  v_missing_items integer;
  v_missing_specs integer;
  v_missing_evidence integer;
  v_next_rev integer;
  v_snapshot jsonb;
  v_snap_hash text;
  v_rev public.inspection_revisions%ROWTYPE;
  v_prev_status text;
  v_item_rec record;
  v_spec_rec record;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := nullif(pg_catalog.btrim(coalesce(p_submit_reason, '')), '');
  IF p_inspection_id IS NULL OR p_expected_row_version IS NULL OR p_expected_row_version < 1 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-029', 'inspection:' || p_inspection_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.submit', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status NOT IN ('DRAFT', 'RETURNED', 'REOPENED') THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.unit_claims c
    WHERE c.unit_id = v_insp.unit_id AND c.project_id = v_insp.project_id
      AND c.inspector_id = v_actor_id AND c.status = 'ACTIVE' AND c.expires_at > pg_catalog.now()
  ) INTO v_claim_ok;

  IF NOT v_claim_ok THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'CLAIM_INVALID', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_draft FROM public.inspection_draft_contexts WHERE inspection_id = p_inspection_id FOR UPDATE;
  IF v_draft.has_unresolved_sync_conflict THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-029', 'status', 'SYNC_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  -- Completeness check 1: required checklist items
  SELECT pg_catalog.count(*)::integer INTO v_missing_items
  FROM public.checklist_items ci
  JOIN public.checklist_sections cs ON cs.id = ci.section_id
  WHERE cs.instrument_version_id = v_insp.instrument_version_id
    AND ci.required = true
    AND NOT (v_draft.draft_checklist ? ci.id::text);

  -- Completeness check 2: required specification fields
  SELECT pg_catalog.count(*)::integer INTO v_missing_specs
  FROM public.specification_fields sf
  WHERE sf.instrument_version_id = v_insp.instrument_version_id
    AND sf.required = true
    AND NOT (v_draft.draft_specifications ? sf.id::text);

  IF v_missing_items > 0 OR v_missing_specs > 0 THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-029',
      'status', 'INCOMPLETE',
      'missing_checklist_items', v_missing_items,
      'missing_spec_fields', v_missing_specs,
      'server_time', pg_catalog.now()
    );
  END IF;

  -- Completeness check 3: required finalized evidence slots
  SELECT pg_catalog.count(*)::integer INTO v_missing_evidence
  FROM public.evidence_slot_definitions es
  WHERE es.instrument_version_id = v_insp.instrument_version_id
    AND es.required = true
    AND NOT EXISTS (
      SELECT 1 FROM public.evidence_assets ea
      WHERE ea.inspection_id = p_inspection_id
        AND ea.slot_definition_id = es.id
        AND ea.upload_status = 'FINALIZED'
    );

  IF v_missing_evidence > 0 THEN
    RETURN pg_catalog.jsonb_build_object(
      'command_id', 'CMD-029',
      'status', 'EVIDENCE_NOT_READY',
      'missing_evidence_slots', v_missing_evidence,
      'server_time', pg_catalog.now()
    );
  END IF;

  v_next_rev := v_insp.current_revision_no + 1;
  v_prev_status := v_insp.status;

  v_snapshot := pg_catalog.jsonb_build_object(
    'revision_no', v_next_rev,
    'instrument_version_id', v_insp.instrument_version_id,
    'checklist', v_draft.draft_checklist,
    'specifications', v_draft.draft_specifications,
    'notes', v_draft.notes
  );
  v_snap_hash := app_internal.sha256_hex(v_snapshot::text);

  INSERT INTO public.inspection_revisions (
    inspection_id, revision_no, instrument_version_id, snapshot_hash,
    author_id, payload_snapshot, submit_reason
  ) VALUES (
    v_insp.id, v_next_rev, v_insp.instrument_version_id, v_snap_hash,
    v_actor_id, v_snapshot, v_reason
  )
  RETURNING * INTO v_rev;

  -- Persist normalized immutable checklist & spec responses
  FOR v_item_rec IN
    SELECT kv.key::uuid AS item_id, kv.value AS ans
    FROM pg_catalog.jsonb_each(v_draft.draft_checklist) AS kv
  LOOP
    INSERT INTO public.checklist_responses (
      inspection_revision_id, checklist_item_id, answer, answered_by
    ) VALUES (
      v_rev.id, v_item_rec.item_id, v_item_rec.ans, v_actor_id
    );
  END LOOP;

  FOR v_spec_rec IN
    SELECT kv.key::uuid AS field_id, kv.value #>> '{}' AS obs
    FROM pg_catalog.jsonb_each(v_draft.draft_specifications) AS kv
  LOOP
    INSERT INTO public.specification_responses (
      inspection_revision_id, specification_field_id, observed_value
    ) VALUES (
      v_rev.id, v_spec_rec.field_id, v_spec_rec.obs
    );
  END LOOP;

  -- Bind finalized draft evidence (not yet attached to a revision) to this immutable revision
  UPDATE public.evidence_assets
  SET inspection_revision_id = v_rev.id, row_version = row_version + 1
  WHERE inspection_id = v_insp.id
    AND upload_status = 'FINALIZED'
    AND inspection_revision_id IS NULL;

  UPDATE public.inspections
  SET status = 'SUBMITTED',
      current_revision_no = v_next_rev,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_insp.id
  RETURNING * INTO v_insp;

  INSERT INTO public.inspection_events (
    inspection_id, event_type, actor_id, from_state, to_state, reason
  ) VALUES (
    v_insp.id, 'inspection.submitted', v_actor_id, v_prev_status, 'SUBMITTED', v_reason
  );

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.submitted', v_actor_id, v_auth_uid, 'CMD-029',
    'PROJECT', v_insp.project_id, 'inspection_revisions', v_rev.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'revision_no', v_rev.revision_no, 'snapshot_hash', v_snap_hash)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-029',
    'status', 'SUBMITTED',
    'inspection_id', v_insp.id,
    'revision_id', v_rev.id,
    'revision_no', v_rev.revision_no,
    'snapshot_hash', v_snap_hash,
    'row_version', v_insp.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-029', 'inspection:' || p_inspection_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-030: return-inspection (inspection.review; reviewer != author; preserves owner per IDC-O04)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_return_inspection_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_revision_id uuid,
  p_expected_revision_no integer,
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
  v_insp public.inspections%ROWTYPE;
  v_rev public.inspection_revisions%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_inspection_id IS NULL OR p_revision_id IS NULL
     OR p_expected_revision_no IS NULL OR p_expected_revision_no < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'revision_id', p_revision_id,
    'expected_revision_no', p_expected_revision_no, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-030', 'revision:' || p_revision_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.review', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status <> 'SUBMITTED' OR v_insp.current_revision_no <> p_expected_revision_no THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_rev FROM public.inspection_revisions
  WHERE id = p_revision_id AND inspection_id = p_inspection_id AND revision_no = p_expected_revision_no;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- Hard SoD: reviewer cannot review own submitted revision
  IF v_rev.author_id = v_actor_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.review_events (inspection_id, inspection_revision_id, reviewer_id, decision, reason)
    VALUES (v_insp.id, v_rev.id, v_actor_id, 'RETURN', v_reason);
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-030', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END;

  -- IDC-O04 Option A: return stays with original Inspector (owner_user_id preserved)
  UPDATE public.inspections
  SET status = 'RETURNED', row_version = row_version + 1, updated_at = pg_catalog.now()
  WHERE id = v_insp.id
  RETURNING * INTO v_insp;

  INSERT INTO public.inspection_events (
    inspection_id, event_type, actor_id, from_state, to_state, reason
  ) VALUES (
    v_insp.id, 'inspection.returned_for_correction', v_actor_id, 'SUBMITTED', 'RETURNED', v_reason
  );

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.returned_for_correction', v_actor_id, v_auth_uid, 'CMD-030',
    'PROJECT', v_insp.project_id, 'inspections', v_insp.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('revision_id', v_rev.id, 'revision_no', v_rev.revision_no, 'reason', v_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-030',
    'status', 'RETURNED',
    'inspection_id', v_insp.id,
    'revision_id', v_rev.id,
    'row_version', v_insp.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-030', 'revision:' || p_revision_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-031: approve-inspection (inspection.review; reviewer != author; releases claim)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_approve_inspection_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_revision_id uuid,
  p_expected_revision_no integer,
  p_reason text DEFAULT NULL
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
  v_insp public.inspections%ROWTYPE;
  v_rev public.inspection_revisions%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := nullif(pg_catalog.btrim(coalesce(p_reason, '')), '');
  IF p_inspection_id IS NULL OR p_revision_id IS NULL
     OR p_expected_revision_no IS NULL OR p_expected_revision_no < 1
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'revision_id', p_revision_id,
    'expected_revision_no', p_expected_revision_no, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-031', 'revision:' || p_revision_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.review', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status <> 'SUBMITTED' OR v_insp.current_revision_no <> p_expected_revision_no THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_rev FROM public.inspection_revisions
  WHERE id = p_revision_id AND inspection_id = p_inspection_id AND revision_no = p_expected_revision_no;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF v_rev.author_id = v_actor_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.review_events (inspection_id, inspection_revision_id, reviewer_id, decision, reason)
    VALUES (v_insp.id, v_rev.id, v_actor_id, 'APPROVE', v_reason);
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-031', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END;

  UPDATE public.inspections
  SET status = 'APPROVED', row_version = row_version + 1, updated_at = pg_catalog.now()
  WHERE id = v_insp.id
  RETURNING * INTO v_insp;

  -- Release active claim cleanly upon approval
  UPDATE public.unit_claims
  SET status = 'RELEASED', released_at = pg_catalog.now(), release_reason = 'Inspection approved', row_version = row_version + 1
  WHERE unit_id = v_insp.unit_id AND project_id = v_insp.project_id AND status = 'ACTIVE';

  INSERT INTO public.inspection_events (
    inspection_id, event_type, actor_id, from_state, to_state, reason
  ) VALUES (
    v_insp.id, 'inspection.approved', v_actor_id, 'SUBMITTED', 'APPROVED', v_reason
  );

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.approved', v_actor_id, v_auth_uid, 'CMD-031',
    'PROJECT', v_insp.project_id, 'inspections', v_insp.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('revision_id', v_rev.id, 'revision_no', v_rev.revision_no)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-031',
    'status', 'APPROVED',
    'inspection_id', v_insp.id,
    'revision_id', v_rev.id,
    'row_version', v_insp.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-031', 'revision:' || p_revision_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-032: reopen-inspection (inspection.reopen; preserves approved revision; requires explicit claim per IDC-O05)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_reopen_inspection_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
  p_approved_revision_id uuid,
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
  v_insp public.inspections%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_inspection_id IS NULL OR p_approved_revision_id IS NULL
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'approved_revision_id', p_approved_revision_id,
    'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-032', 'inspection:' || p_inspection_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.reopen', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status <> 'APPROVED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.review_events re
    WHERE re.inspection_id = p_inspection_id AND re.inspection_revision_id = p_approved_revision_id AND re.decision = 'APPROVE'
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-032', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  -- IDC-O05 Option A: Reopen clears owner_user_id; explicit claim/reassignment via CMD-026 required before editing
  UPDATE public.inspections
  SET status = 'REOPENED',
      owner_user_id = NULL,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_insp.id
  RETURNING * INTO v_insp;

  INSERT INTO public.inspection_events (
    inspection_id, event_type, actor_id, from_state, to_state, reason
  ) VALUES (
    v_insp.id, 'inspection.reopened', v_actor_id, 'APPROVED', 'REOPENED', v_reason
  );

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.reopened', v_actor_id, v_auth_uid, 'CMD-032',
    'PROJECT', v_insp.project_id, 'inspections', v_insp.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('approved_revision_id', p_approved_revision_id, 'reason', v_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-032',
    'status', 'REOPENED',
    'inspection_id', v_insp.id,
    'row_version', v_insp.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-032', 'inspection:' || p_inspection_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-055: request-packed-unit-abort (SES-001; Inspector owner on RETURNED inspection)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_request_packed_unit_abort_v1(
  p_idempotency_key text,
  p_inspection_id uuid,
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
  v_insp public.inspections%ROWTYPE;
  v_abort public.inspection_abort_requests%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_inspection_id IS NULL OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'inspection_id', p_inspection_id, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-055', 'inspection:' || p_inspection_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.abort.request', v_insp.project_id)
     OR v_insp.owner_user_id IS DISTINCT FROM v_actor_id
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- SES-001: packed-unit abort request allowed strictly after Reviewer return (status = RETURNED)
  IF v_insp.status <> 'RETURNED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  BEGIN
    INSERT INTO public.inspection_abort_requests (
      inspection_id, project_id, requested_by, status, request_reason, row_version
    ) VALUES (
      v_insp.id, v_insp.project_id, v_actor_id, 'PENDING', v_reason, 1
    )
    RETURNING * INTO v_abort;
  EXCEPTION WHEN unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-055', 'status', 'STATE_CONFLICT', 'error_code', 'ABORT_ALREADY_PENDING', 'server_time', pg_catalog.now());
  END;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'inspection.abort_requested', v_actor_id, v_auth_uid, 'CMD-055',
    'PROJECT', v_insp.project_id, 'inspection_abort_requests', v_abort.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'reason', v_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-055',
    'status', 'ACCEPTED',
    'abort_request_id', v_abort.id,
    'row_version', v_abort.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-055', 'inspection:' || p_inspection_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-056: decide-packed-unit-abort (SES-001; SoD; APPROVE -> permanently terminal ABORTED)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_decide_packed_unit_abort_v1(
  p_idempotency_key text,
  p_abort_request_id uuid,
  p_decision text,
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
  v_abort public.inspection_abort_requests%ROWTYPE;
  v_insp public.inspections%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := pg_catalog.btrim(coalesce(p_reason, ''));
  IF p_abort_request_id IS NULL OR p_decision NOT IN ('APPROVE', 'REJECT')
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
     OR pg_catalog.char_length(v_reason) NOT BETWEEN 5 AND 1000
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'abort_request_id', p_abort_request_id, 'decision', p_decision,
    'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-056', 'abort:' || p_abort_request_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_abort FROM public.inspection_abort_requests WHERE id = p_abort_request_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- Ascending order: L90 inspection -> L100 abort request
  SELECT * INTO v_insp FROM public.inspections WHERE id = v_abort.inspection_id FOR UPDATE;
  SELECT * INTO v_abort FROM public.inspection_abort_requests WHERE id = p_abort_request_id FOR UPDATE;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'inspection.abort.decide', v_abort.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_abort.requested_by = v_actor_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  IF v_abort.status <> 'PENDING' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_abort.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-056', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.inspection_abort_requests
  SET status = CASE WHEN p_decision = 'APPROVE' THEN 'APPROVED' ELSE 'REJECTED' END,
      decided_by = v_actor_id,
      decision_reason = v_reason,
      decided_at = pg_catalog.now(),
      row_version = row_version + 1
  WHERE id = v_abort.id
  RETURNING * INTO v_abort;

  IF p_decision = 'APPROVE' THEN
    UPDATE public.inspections
    SET status = 'ABORTED', row_version = row_version + 1, updated_at = pg_catalog.now()
    WHERE id = v_insp.id
    RETURNING * INTO v_insp;

    UPDATE public.unit_claims
    SET status = 'RELEASED', released_at = pg_catalog.now(), release_reason = 'Inspection aborted (SES-001)', row_version = row_version + 1
    WHERE unit_id = v_insp.unit_id AND project_id = v_insp.project_id AND status = 'ACTIVE';

    INSERT INTO public.inspection_events (
      inspection_id, event_type, actor_id, from_state, to_state, reason
    ) VALUES (
      v_insp.id, 'inspection.aborted', v_actor_id, 'RETURNED', 'ABORTED', v_reason
    );
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN p_decision = 'APPROVE' THEN 'inspection.abort_approved' ELSE 'inspection.abort_rejected' END,
    v_actor_id, v_auth_uid, 'CMD-056',
    'PROJECT', v_abort.project_id, 'inspection_abort_requests', v_abort.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'decision', p_decision, 'reason', v_reason)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-056',
    'status', CASE WHEN p_decision = 'APPROVE' THEN 'APPROVED' ELSE 'REJECTED' END,
    'abort_request_id', v_abort.id,
    'inspection_id', v_insp.id,
    'inspection_status', v_insp.status,
    'row_version', v_abort.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-056', 'abort:' || p_abort_request_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_claim_unit_v1(text, uuid, uuid, uuid, integer) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_claim_unit_v1(text, uuid, uuid, uuid, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_claim_unit_v1(text, uuid, uuid, uuid, integer) TO authenticated;

ALTER FUNCTION public.cmd_release_unit_claim_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_release_unit_claim_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_release_unit_claim_v1(text, uuid, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_save_draft_v1(text, uuid, bigint, jsonb, jsonb, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_save_draft_v1(text, uuid, bigint, jsonb, jsonb, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_save_draft_v1(text, uuid, bigint, jsonb, jsonb, text) TO authenticated;

ALTER FUNCTION public.cmd_submit_inspection_v1(text, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_submit_inspection_v1(text, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_submit_inspection_v1(text, uuid, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_return_inspection_v1(text, uuid, uuid, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_return_inspection_v1(text, uuid, uuid, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_return_inspection_v1(text, uuid, uuid, integer, text) TO authenticated;

ALTER FUNCTION public.cmd_approve_inspection_v1(text, uuid, uuid, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_approve_inspection_v1(text, uuid, uuid, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_approve_inspection_v1(text, uuid, uuid, integer, text) TO authenticated;

ALTER FUNCTION public.cmd_reopen_inspection_v1(text, uuid, uuid, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_reopen_inspection_v1(text, uuid, uuid, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_reopen_inspection_v1(text, uuid, uuid, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_request_packed_unit_abort_v1(text, uuid, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_request_packed_unit_abort_v1(text, uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_request_packed_unit_abort_v1(text, uuid, text) TO authenticated;

ALTER FUNCTION public.cmd_decide_packed_unit_abort_v1(text, uuid, text, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_decide_packed_unit_abort_v1(text, uuid, text, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_decide_packed_unit_abort_v1(text, uuid, text, bigint, text) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
