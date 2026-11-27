-- Migration: 20261127080100_i4_cmd036_043_documents_print_attendance_reports.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for CMD-036..CMD-043
--        (Documents/C36-02, Print Sequences/DOC-003/T-13, Attendance/T-08,
--         Scoped Actual/Target Reports, and Scoped Audit Reads).
--        CMD-044 (export-audit) remains STRICTLY DISABLED until written T-10 approval!
-- Authority: AGENTS.md v1.3.0, Command Catalogue v1.0.0, C36-02, DOC-003, T-08, T-13, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

-- ===========================================================================
-- C36-02 Trigger: Reopening an approved inspection marks in-flight PDF jobs STALE_CANCELLED
-- ===========================================================================
CREATE OR REPLACE FUNCTION app_internal.cancel_inflight_doc_jobs_on_reopen()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.status = 'APPROVED' AND NEW.status = 'REOPENED' THEN
    UPDATE public.document_generation_jobs
    SET status = 'STALE_CANCELLED', updated_at = pg_catalog.now()
    WHERE inspection_id = NEW.id AND status IN ('QUEUED', 'PROCESSING');
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION app_internal.cancel_inflight_doc_jobs_on_reopen() OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.cancel_inflight_doc_jobs_on_reopen() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_inspections_reopen_cancel_doc_jobs
  AFTER UPDATE OF status ON public.inspections
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.cancel_inflight_doc_jobs_on_reopen();

-- ===========================================================================
-- CMD-036: generate-approved-document (document.generate; rejects pre-start session!)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_generate_approved_document_v1(
  p_idempotency_key text,
  p_document_type text,
  p_inspection_id uuid,
  p_approved_revision_id uuid,
  p_template_version_id uuid
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
  v_session public.sessions%ROWTYPE;
  v_rev public.inspection_revisions%ROWTYPE;
  v_tpl public.document_template_versions%ROWTYPE;
  v_next_ver integer;
  v_output_hash text;
  v_object_key text;
  v_doc public.documents%ROWTYPE;
  v_job public.document_generation_jobs%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_document_type NOT IN ('INSPECTION_PDF', 'BA_PDF')
     OR p_inspection_id IS NULL OR p_approved_revision_id IS NULL OR p_template_version_id IS NULL
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'document_type', p_document_type, 'inspection_id', p_inspection_id,
    'approved_revision_id', p_approved_revision_id, 'template_version_id', p_template_version_id
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-036', 'doc:' || p_inspection_id::text || ':' || p_document_type, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_insp FROM public.inspections WHERE id = p_inspection_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'document.generate', v_insp.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = v_insp.session_id FOR SHARE;
  IF v_session.started_at IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'SESSION_NOT_STARTED', 'server_time', pg_catalog.now());
  END IF;

  IF v_insp.status <> 'APPROVED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'SOURCE_NOT_APPROVED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_rev FROM public.inspection_revisions
  WHERE id = p_approved_revision_id AND inspection_id = p_inspection_id;
  IF NOT FOUND OR NOT EXISTS (
    SELECT 1 FROM public.review_events re
    WHERE re.inspection_revision_id = v_rev.id AND re.decision = 'APPROVE'
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'SOURCE_REVISION_MISMATCH', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_tpl FROM public.document_template_versions
  WHERE id = p_template_version_id AND document_type = p_document_type AND status = 'ACTIVE';
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-036', 'status', 'TEMPLATE_VERSION_UNAVAILABLE', 'server_time', pg_catalog.now());
  END IF;

  -- Supersede prior current version (DOC-003: superseded versions preserved historically, never deleted)
  SELECT coalesce(pg_catalog.max(version_no), 0) + 1 INTO v_next_ver
  FROM public.documents
  WHERE inspection_id = p_inspection_id AND document_type = p_document_type;

  UPDATE public.documents
  SET is_current = false, status = 'SUPERSEDED'
  WHERE inspection_id = p_inspection_id AND document_type = p_document_type AND is_current = true;

  v_output_hash := app_internal.sha256_hex(v_rev.snapshot_hash || ':' || v_tpl.template_hash || ':' || v_next_ver::text);
  v_object_key := 'private/projects/' || v_insp.project_id::text || '/documents/' || p_document_type || '/' || pg_catalog.gen_random_uuid()::text || '.pdf';

  INSERT INTO public.documents (
    project_id, session_id, inspection_id, inspection_revision_id, document_type,
    template_version_id, source_hash, output_hash, object_key, version_no,
    is_current, status, generated_by
  ) VALUES (
    v_insp.project_id, v_insp.session_id, v_insp.id, v_rev.id, p_document_type,
    v_tpl.id, v_rev.snapshot_hash, v_output_hash, v_object_key, v_next_ver,
    true, 'FINALIZED', v_actor_id
  )
  RETURNING * INTO v_doc;

  INSERT INTO public.document_print_counters (document_id, last_sequence_no)
  VALUES (v_doc.id, 0);

  INSERT INTO public.document_generation_jobs (
    project_id, session_id, inspection_id, inspection_revision_id, document_type,
    template_version_id, source_hash, status, requested_by, output_document_id
  ) VALUES (
    v_insp.project_id, v_insp.session_id, v_insp.id, v_rev.id, p_document_type,
    v_tpl.id, v_rev.snapshot_hash, 'SUCCEEDED', v_actor_id, v_doc.id
  )
  RETURNING * INTO v_job;

  INSERT INTO public.document_generation_attempts (job_id, attempt_no, outcome)
  VALUES (v_job.id, 1, 'SUCCEEDED');

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN p_document_type = 'BA_PDF' THEN 'ba.generated' ELSE 'pdf.generated' END,
    v_actor_id, v_auth_uid, 'CMD-036',
    'PROJECT', v_insp.project_id, 'documents', v_doc.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('inspection_id', v_insp.id, 'revision_id', v_rev.id, 'version_no', v_doc.version_no, 'output_hash', v_output_hash)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-036',
    'status', 'GENERATED',
    'document_id', v_doc.id,
    'version_no', v_doc.version_no,
    'output_hash', v_output_hash,
    'object_key', v_doc.object_key,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-036', 'doc:' || p_inspection_id::text || ':' || p_document_type, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-037: record-print (document.print; DOC-003 current-version-only + monotonic sequence)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_record_print_v1(
  p_idempotency_key text,
  p_document_id uuid,
  p_expected_document_version integer,
  p_expected_sequence integer DEFAULT NULL,
  p_client_print_signal text DEFAULT NULL
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
  v_doc public.documents%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_counter public.document_print_counters%ROWTYPE;
  v_next_seq integer;
  v_evt public.print_events%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_document_id IS NULL OR p_expected_document_version IS NULL OR p_expected_document_version < 1 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'document_id', p_document_id, 'expected_document_version', p_expected_document_version,
    'expected_sequence', p_expected_sequence, 'signal', p_client_print_signal
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-037', 'doc:' || p_document_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_doc FROM public.documents WHERE id = p_document_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'document.print', v_doc.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'PRINT_SCOPE_DENIED', 'server_time', pg_catalog.now());
  END IF;

  -- DOC-003: source session must have started; CLOSED session is ALLOWED for current version!
  SELECT * INTO v_session FROM public.sessions WHERE id = v_doc.session_id FOR SHARE;
  IF v_session.started_at IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'SESSION_NOT_STARTED', 'server_time', pg_catalog.now());
  END IF;

  IF v_doc.version_no <> p_expected_document_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'DOCUMENT_VERSION_MISMATCH', 'server_time', pg_catalog.now());
  END IF;

  -- DOC-003: Superseded versions rejected WITHOUT consuming sequence
  IF NOT v_doc.is_current OR v_doc.status <> 'FINALIZED' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'DOCUMENT_VERSION_SUPERSEDED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_counter FROM public.document_print_counters WHERE document_id = v_doc.id FOR UPDATE;
  IF p_expected_sequence IS NOT NULL AND v_counter.last_sequence_no <> p_expected_sequence THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-037', 'status', 'STALE_SEQUENCE', 'current_sequence', v_counter.last_sequence_no, 'server_time', pg_catalog.now());
  END IF;

  v_next_seq := v_counter.last_sequence_no + 1;
  UPDATE public.document_print_counters
  SET last_sequence_no = v_next_seq, updated_at = pg_catalog.now()
  WHERE document_id = v_doc.id;

  INSERT INTO public.print_events (
    document_id, actor_id, sequence_no, attempt_no, outcome,
    client_print_signal, idempotency_key_hash
  ) VALUES (
    v_doc.id, v_actor_id, v_next_seq, 1, 'RECORDED',
    nullif(pg_catalog.btrim(coalesce(p_client_print_signal, '')), ''), v_idem->>'key_hash'
  )
  RETURNING * INTO v_evt;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN v_next_seq = 1 THEN 'document.printed' ELSE 'document.reprinted' END,
    v_actor_id, v_auth_uid, 'CMD-037',
    'PROJECT', v_doc.project_id, 'print_events', v_evt.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('document_id', v_doc.id, 'sequence_no', v_next_seq)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-037',
    'status', 'RECORDED',
    'print_event_id', v_evt.id,
    'document_id', v_doc.id,
    'sequence_no', v_next_seq,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-037', 'doc:' || p_document_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-038: record-print-batch (document.print.batch + per-item DOC-003 check; T-13)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_record_print_batch_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_session_id uuid,
  p_items jsonb
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
  v_batch public.print_batches%ROWTYPE;
  v_item jsonb;
  v_idx integer := 0;
  v_bi public.print_batch_items%ROWTYPE;
  v_doc public.documents%ROWTYPE;
  v_session public.sessions%ROWTYPE;
  v_next_seq integer;
  v_evt public.print_events%ROWTYPE;
  v_ok_count integer := 0;
  v_fail_count integer := 0;
  v_results jsonb := '[]'::jsonb;
  v_batch_status text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_project_id IS NULL OR p_session_id IS NULL
     OR p_items IS NULL OR pg_catalog.jsonb_typeof(p_items) <> 'array'
     OR pg_catalog.jsonb_array_length(p_items) NOT BETWEEN 1 AND 100
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'session_id', p_session_id, 'items', p_items
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-038', 'print_batch:' || p_session_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT (
    app_internal.actor_has_permission(v_actor_id, 'document.print.batch', p_project_id)
    AND app_internal.actor_has_permission(v_actor_id, 'document.print', p_project_id)
  ) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id AND project_id = p_project_id FOR SHARE;
  IF NOT FOUND OR v_session.started_at IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'SESSION_NOT_STARTED', 'server_time', pg_catalog.now());
  END IF;

  INSERT INTO public.print_batches (
    actor_id, project_id, session_id, requested_count, status, request_hash
  ) VALUES (
    v_actor_id, p_project_id, p_session_id, pg_catalog.jsonb_array_length(p_items), 'ACCEPTED', v_req_hash
  )
  RETURNING * INTO v_batch;

  FOR v_item IN SELECT * FROM pg_catalog.jsonb_array_elements(p_items)
  LOOP
    v_idx := v_idx + 1;
    IF coalesce(v_item->>'document_id', '') !~ '^[0-9a-fA-F-]{36}$'
       OR coalesce(v_item->>'expected_document_version', '') !~ '^[1-9]\d{0,5}$'
       OR pg_catalog.char_length(pg_catalog.btrim(coalesce(v_item->>'item_key', ''))) NOT BETWEEN 1 AND 128
    THEN
      RAISE EXCEPTION 'VALIDATION_FAILED' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.print_batch_items (batch_id, item_order, item_key, document_id, expected_document_version)
    VALUES (v_batch.id, v_idx, pg_catalog.btrim(v_item->>'item_key'), (v_item->>'document_id')::uuid, (v_item->>'expected_document_version')::integer)
    RETURNING * INTO v_bi;

    SELECT * INTO v_doc FROM public.documents
    WHERE id = v_bi.document_id AND project_id = p_project_id AND session_id = p_session_id FOR SHARE;

    IF NOT FOUND OR v_doc.version_no <> v_bi.expected_document_version OR NOT v_doc.is_current OR v_doc.status <> 'FINALIZED' THEN
      v_fail_count := v_fail_count + 1;
      INSERT INTO public.print_batch_item_results (batch_item_id, attempt_no, outcome, failure_code)
      VALUES (v_bi.id, 1, 'REJECTED', CASE WHEN NOT FOUND THEN 'NOT_FOUND' WHEN NOT v_doc.is_current THEN 'DOCUMENT_VERSION_SUPERSEDED' ELSE 'DOCUMENT_VERSION_MISMATCH' END);
      v_results := v_results || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'item_key', v_bi.item_key, 'outcome', 'REJECTED',
        'failure_code', CASE WHEN NOT FOUND THEN 'NOT_FOUND' WHEN NOT v_doc.is_current THEN 'DOCUMENT_VERSION_SUPERSEDED' ELSE 'DOCUMENT_VERSION_MISMATCH' END
      ));
      CONTINUE;
    END IF;

    UPDATE public.document_print_counters
    SET last_sequence_no = last_sequence_no + 1, updated_at = pg_catalog.now()
    WHERE document_id = v_doc.id
    RETURNING last_sequence_no INTO v_next_seq;

    INSERT INTO public.print_events (
      batch_id, document_id, actor_id, sequence_no, attempt_no, outcome, idempotency_key_hash
    ) VALUES (
      v_batch.id, v_doc.id, v_actor_id, v_next_seq, 1, 'RECORDED',
      app_internal.sha256_hex(p_idempotency_key || ':' || v_bi.item_key)
    )
    RETURNING * INTO v_evt;

    INSERT INTO public.print_batch_item_results (batch_item_id, attempt_no, outcome, print_event_id)
    VALUES (v_bi.id, 1, 'RECORDED', v_evt.id);

    v_ok_count := v_ok_count + 1;
    v_results := v_results || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'item_key', v_bi.item_key, 'outcome', 'RECORDED', 'sequence_no', v_next_seq, 'print_event_id', v_evt.id
    ));
  END LOOP;

  IF v_ok_count > 0 AND v_fail_count = 0 THEN
    v_batch_status := 'SUCCEEDED';
  ELSIF v_ok_count > 0 THEN
    v_batch_status := 'PARTIAL';
  ELSE
    v_batch_status := 'REJECTED';
  END IF;

  UPDATE public.print_batches
  SET status = v_batch_status, completed_at = pg_catalog.now()
  WHERE id = v_batch.id;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN v_batch_status = 'SUCCEEDED' THEN 'document.print_batch_completed' ELSE 'document.print_batch_partial' END,
    v_actor_id, v_auth_uid, 'CMD-038',
    'PROJECT', p_project_id, 'print_batches', v_batch.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('status', v_batch_status, 'succeeded', v_ok_count, 'rejected', v_fail_count)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-038',
    'status', v_batch_status,
    'batch_id', v_batch.id,
    'results', v_results,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-038', 'print_batch:' || p_session_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
EXCEPTION
  WHEN SQLSTATE 'P0001' OR unique_violation THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-038', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
END;
$$;

-- ===========================================================================
-- CMD-039: upload-attendance-document (attendance.upload; append-only replacements; never auto-verifies)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_upload_attendance_document_v1(
  p_idempotency_key text,
  p_project_id uuid,
  p_session_id uuid,
  p_location_id uuid,
  p_sha256 text,
  p_byte_size integer,
  p_mime_type text,
  p_replacement_reason text DEFAULT NULL
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
  v_reason text;
  v_req_hash text;
  v_idem jsonb;
  v_rec public.attendance_records%ROWTYPE;
  v_next_ver integer;
  v_doc public.attendance_documents%ROWTYPE;
  v_object_key text;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_sha := pg_catalog.lower(pg_catalog.btrim(coalesce(p_sha256, '')));
  v_reason := nullif(pg_catalog.btrim(coalesce(p_replacement_reason, '')), '');
  IF p_project_id IS NULL OR p_session_id IS NULL OR p_location_id IS NULL
     OR v_sha !~ '^[0-9a-f]{64}$'
     OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 15728640
     OR p_mime_type NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'project_id', p_project_id, 'session_id', p_session_id, 'location_id', p_location_id,
    'sha256', v_sha, 'size', p_byte_size, 'mime', p_mime_type, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(
    v_auth_uid, 'CMD-039', 'att:' || p_session_id::text || ':' || p_location_id::text, p_idempotency_key, v_req_hash
  );
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'attendance.upload', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_rec FROM public.attendance_records
  WHERE session_id = p_session_id AND location_id = p_location_id FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.attendance_records (project_id, session_id, location_id, status, row_version, created_by)
    VALUES (p_project_id, p_session_id, p_location_id, 'UPLOADED', 1, v_actor_id)
    RETURNING * INTO v_rec;
    v_next_ver := 1;
  ELSE
    SELECT coalesce(pg_catalog.max(version_no), 0) + 1 INTO v_next_ver
    FROM public.attendance_documents WHERE attendance_record_id = v_rec.id;

    IF v_next_ver > 1 AND (v_reason IS NULL OR pg_catalog.char_length(v_reason) < 3) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-039', 'status', 'VALIDATION_FAILED', 'error_code', 'REPLACEMENT_REASON_REQUIRED', 'server_time', pg_catalog.now());
    END IF;

    UPDATE public.attendance_documents
    SET status = 'SUPERSEDED'
    WHERE attendance_record_id = v_rec.id AND status = 'ACTIVE';

    -- Upload NEVER auto-verifies: resets status to UPLOADED for fresh verification
    UPDATE public.attendance_records
    SET status = 'UPLOADED', row_version = row_version + 1, updated_at = pg_catalog.now()
    WHERE id = v_rec.id
    RETURNING * INTO v_rec;
  END IF;

  v_object_key := 'private/projects/' || p_project_id::text || '/attendance/' || v_rec.id::text || '/v' || v_next_ver::text || '_' || pg_catalog.gen_random_uuid()::text;

  INSERT INTO public.attendance_documents (
    attendance_record_id, version_no, object_key, sha256, byte_size, mime_type,
    uploaded_by, replacement_reason, status
  ) VALUES (
    v_rec.id, v_next_ver, v_object_key, v_sha, p_byte_size, p_mime_type,
    v_actor_id, v_reason, 'ACTIVE'
  )
  RETURNING * INTO v_doc;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    CASE WHEN v_next_ver = 1 THEN 'attendance.uploaded' ELSE 'attendance.replaced' END,
    v_actor_id, v_auth_uid, 'CMD-039',
    'PROJECT', p_project_id, 'attendance_documents', v_doc.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('attendance_record_id', v_rec.id, 'version_no', v_next_ver)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-039',
    'status', 'UPLOADED',
    'attendance_record_id', v_rec.id,
    'attendance_document_id', v_doc.id,
    'version_no', v_next_ver,
    'row_version', v_rec.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-039', 'att:' || p_session_id::text || ':' || p_location_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-040: verify-attendance (attendance.verify; SoD verifier != uploader; CAS)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_verify_attendance_v1(
  p_idempotency_key text,
  p_attendance_record_id uuid,
  p_attendance_document_id uuid,
  p_decision text,
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
  v_rec public.attendance_records%ROWTYPE;
  v_doc public.attendance_documents%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_reason := nullif(pg_catalog.btrim(coalesce(p_reason, '')), '');
  IF p_attendance_record_id IS NULL OR p_attendance_document_id IS NULL
     OR p_decision NOT IN ('VERIFY', 'REJECT')
     OR p_expected_row_version IS NULL OR p_expected_row_version < 1
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_req_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'v', 1, 'record_id', p_attendance_record_id, 'doc_id', p_attendance_document_id,
    'decision', p_decision, 'expected_row_version', p_expected_row_version::text, 'reason', v_reason
  )::text);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-040', 'att_doc:' || p_attendance_document_id::text, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  SELECT * INTO v_rec FROM public.attendance_records WHERE id = p_attendance_record_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'attendance.verify', v_rec.project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  IF v_rec.row_version <> p_expected_row_version THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'STALE_VERSION', 'server_time', pg_catalog.now());
  END IF;

  SELECT * INTO v_doc FROM public.attendance_documents
  WHERE id = p_attendance_document_id AND attendance_record_id = p_attendance_record_id AND status = 'ACTIVE';
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'STATE_CONFLICT', 'server_time', pg_catalog.now());
  END IF;

  IF v_doc.uploaded_by = v_actor_id THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-040', 'status', 'SOD_VIOLATION', 'server_time', pg_catalog.now());
  END IF;

  INSERT INTO public.attendance_verification_events (
    attendance_record_id, attendance_document_id, verifier_id, decision, reason
  ) VALUES (
    v_rec.id, v_doc.id, v_actor_id, p_decision, v_reason
  );

  UPDATE public.attendance_records
  SET status = CASE WHEN p_decision = 'VERIFY' THEN 'VERIFIED' ELSE 'REJECTED' END,
      row_version = row_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = v_rec.id
  RETURNING * INTO v_rec;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'attendance.verified', v_actor_id, v_auth_uid, 'CMD-040',
    'PROJECT', v_rec.project_id, 'attendance_records', v_rec.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('decision', p_decision, 'document_id', v_doc.id)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-040',
    'status', CASE WHEN p_decision = 'VERIFY' THEN 'VERIFIED' ELSE 'REJECTED' END,
    'attendance_record_id', v_rec.id,
    'row_version', v_rec.row_version::text,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-040', 'att_doc:' || p_attendance_document_id::text, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-041: get-actual-report (report.read; strictly scoped actual activity)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_get_actual_report_v1(
  p_project_id uuid,
  p_session_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_summary jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-041', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-041', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_project_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-041', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'report.read', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-041', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT coalesce(pg_catalog.jsonb_object_agg(status, cnt), '{}'::jsonb) INTO v_summary
  FROM (
    SELECT i.status, pg_catalog.count(*)::integer AS cnt
    FROM public.inspections i
    WHERE i.project_id = p_project_id
      AND (p_session_id IS NULL OR i.session_id = p_session_id)
    GROUP BY i.status
  ) t;

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-041',
    'status', 'OK',
    'project_id', p_project_id,
    'session_id', p_session_id,
    'actual_counts_by_status', v_summary,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- CMD-042: get-target-report (report.read; separate from actual report)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_get_target_report_v1(
  p_project_id uuid,
  p_session_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_total_target bigint;
  v_rows jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-042', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-042', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_project_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-042', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'report.read', p_project_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-042', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT
    coalesce(pg_catalog.sum(ta.quantity), 0),
    coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'plan_id', tp.id, 'session_id', tp.session_id, 'version', tp.version,
      'assignment_id', ta.assignment_id, 'target_date', ta.target_date, 'quantity', ta.quantity
    ) ORDER BY ta.target_date ASC), '[]'::jsonb)
  INTO v_total_target, v_rows
  FROM public.target_plans tp
  JOIN public.target_allocations ta ON ta.target_plan_id = tp.id
  WHERE tp.project_id = p_project_id
    AND tp.status = 'PUBLISHED'
    AND (p_session_id IS NULL OR tp.session_id = p_session_id);

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-042',
    'status', 'OK',
    'project_id', p_project_id,
    'session_id', p_session_id,
    'total_target_quantity', v_total_target,
    'allocations', v_rows,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- CMD-043: read-audit (audit.read; mandatory purpose; logs audit.accessed)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_read_audit_v1(
  p_purpose text,
  p_limit integer DEFAULT 50,
  p_event_type text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_purpose text;
  v_lim integer;
  v_events jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-043', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-043', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_purpose := pg_catalog.btrim(coalesce(p_purpose, ''));
  v_lim := least(greatest(coalesce(p_limit, 50), 1), 100);
  IF pg_catalog.char_length(v_purpose) NOT BETWEEN 5 AND 500 THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-043', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'audit.read', NULL) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-043', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', ae.id, 'event_type', ae.event_type, 'command_id', ae.command_id,
    'actor_user_id', ae.actor_user_id, 'target_table', ae.target_table,
    'target_id', ae.target_id, 'outcome', ae.outcome, 'created_at', ae.created_at
  ) ORDER BY ae.created_at DESC, ae.id DESC), '[]'::jsonb)
  INTO v_events
  FROM (
    SELECT * FROM public.audit_events
    WHERE p_event_type IS NULL OR event_type = p_event_type
    ORDER BY created_at DESC, id DESC
    LIMIT v_lim
  ) ae;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    outcome, metadata
  ) VALUES (
    'audit.accessed', v_actor_id, v_auth_uid, 'CMD-043',
    'GLOBAL', NULL, 'audit_events', NULL,
    'SUCCESS',
    pg_catalog.jsonb_build_object('purpose', v_purpose, 'limit', v_lim)
  );

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-043',
    'status', 'OK',
    'events', v_events,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_generate_approved_document_v1(text, text, uuid, uuid, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_generate_approved_document_v1(text, text, uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_generate_approved_document_v1(text, text, uuid, uuid, uuid) TO authenticated;

ALTER FUNCTION public.cmd_record_print_v1(text, uuid, integer, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_record_print_v1(text, uuid, integer, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_record_print_v1(text, uuid, integer, integer, text) TO authenticated;

ALTER FUNCTION public.cmd_record_print_batch_v1(text, uuid, uuid, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_record_print_batch_v1(text, uuid, uuid, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_record_print_batch_v1(text, uuid, uuid, jsonb) TO authenticated;

ALTER FUNCTION public.cmd_upload_attendance_document_v1(text, uuid, uuid, uuid, text, integer, text, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_upload_attendance_document_v1(text, uuid, uuid, uuid, text, integer, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_upload_attendance_document_v1(text, uuid, uuid, uuid, text, integer, text, text) TO authenticated;

ALTER FUNCTION public.cmd_verify_attendance_v1(text, uuid, uuid, text, bigint, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_verify_attendance_v1(text, uuid, uuid, text, bigint, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_verify_attendance_v1(text, uuid, uuid, text, bigint, text) TO authenticated;

ALTER FUNCTION public.cmd_get_actual_report_v1(uuid, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_get_actual_report_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_get_actual_report_v1(uuid, uuid) TO authenticated;

ALTER FUNCTION public.cmd_get_target_report_v1(uuid, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_get_target_report_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_get_target_report_v1(uuid, uuid) TO authenticated;

ALTER FUNCTION public.cmd_read_audit_v1(text, integer, text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_read_audit_v1(text, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_read_audit_v1(text, integer, text) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
