-- Migration: 20261127080000_i4_documents_print_attendance_notifications_schema.sql
-- Scope: Slice 4 (I4/I5) — Final 19 canonical tables reaching exact 62/62 physical schema
--        & 62/62 ENABLE + FORCE RLS parity:
--        * Documents & Generation (4): document_template_versions, documents,
--          document_generation_jobs (C36-02 STALE_CANCELLED), document_generation_attempts
--        * Printing (5): document_print_counters, print_batches, print_batch_items,
--          print_batch_item_results, print_events (DOC-003 / T-13)
--        * Attendance (3): attendance_records, attendance_documents, attendance_verification_events (T-08)
--        * Notifications (7): notification_policy_versions, notification_outbox,
--          notification_outbox_recipients (POQ-01/NLA-MVP-001), notifications (POQ-03),
--          notification_deliveries, notification_delivery_attempts, notification_escalation_events
-- Authority: AGENTS.md v1.3.0 (G9-TECH FROZEN / G10 SYNTHETIC ACTIVE),
--            Physical Schema v1.0.0 (62 tables), RLS Catalogue v1.0.0 (62/62),
--            NLA-001 v1.0.0, C36-02, DOC-003, T-08, T-13, POQ-01..03, NLA-MVP-001.

-- ===========================================================================
-- 1. DOCUMENTS & GENERATION LIFECYCLE (4 — C36-02)
-- ===========================================================================

CREATE TABLE public.document_template_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type text NOT NULL CHECK (document_type IN ('INSPECTION_PDF', 'BA_PDF', 'ATTENDANCE_PDF')),
  template_key text NOT NULL CHECK (template_key ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  version_no integer NOT NULL CHECK (version_no >= 1),
  template_hash text NOT NULL CHECK (template_hash ~ '^[0-9a-f]{64}$'),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RETIRED')),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_doc_template_version UNIQUE (document_type, template_key, version_no)
);

CREATE TABLE public.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  inspection_id uuid NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  inspection_revision_id uuid NULL REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  document_type text NOT NULL CHECK (document_type IN ('INSPECTION_PDF', 'BA_PDF', 'ATTENDANCE_PDF')),
  template_version_id uuid NOT NULL REFERENCES public.document_template_versions(id) ON DELETE RESTRICT,
  source_hash text NOT NULL CHECK (source_hash ~ '^[0-9a-f]{64}$'),
  output_hash text NOT NULL CHECK (output_hash ~ '^[0-9a-f]{64}$'),
  object_key text NOT NULL UNIQUE CHECK (char_length(trim(object_key)) BETWEEN 10 AND 300),
  version_no integer NOT NULL DEFAULT 1 CHECK (version_no >= 1),
  is_current boolean NOT NULL DEFAULT true,
  status text NOT NULL DEFAULT 'FINALIZED' CHECK (status IN ('FINALIZED', 'SUPERSEDED')),
  generated_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  generated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_documents_project_session ON public.documents (project_id, session_id, is_current);
CREATE INDEX idx_documents_inspection ON public.documents (inspection_id, version_no DESC);

CREATE TABLE public.document_generation_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  inspection_id uuid NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  inspection_revision_id uuid NULL REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  document_type text NOT NULL CHECK (document_type IN ('INSPECTION_PDF', 'BA_PDF', 'ATTENDANCE_PDF')),
  template_version_id uuid NOT NULL REFERENCES public.document_template_versions(id) ON DELETE RESTRICT,
  source_hash text NOT NULL CHECK (source_hash ~ '^[0-9a-f]{64}$'),
  status text NOT NULL DEFAULT 'QUEUED'
    CHECK (status IN ('QUEUED', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'STALE_CANCELLED')),
  requested_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  lease_owner text NULL,
  lease_token_hash text NULL CHECK (lease_token_hash IS NULL OR lease_token_hash ~ '^[0-9a-f]{64}$'),
  lease_generation bigint NOT NULL DEFAULT 0 CHECK (lease_generation >= 0),
  lease_expires_at timestamptz NULL,
  output_document_id uuid NULL REFERENCES public.documents(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_doc_gen_jobs_insp_status ON public.document_generation_jobs (inspection_id, status);

CREATE TABLE public.document_generation_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.document_generation_jobs(id) ON DELETE RESTRICT,
  attempt_no integer NOT NULL CHECK (attempt_no >= 1),
  outcome text NOT NULL CHECK (outcome IN ('SUCCEEDED', 'FAILED', 'STALE_CANCELLED')),
  safe_error_code text NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_doc_gen_attempts UNIQUE (job_id, attempt_no)
);

CREATE TRIGGER trg_doc_gen_attempts_append_only
  BEFORE UPDATE OR DELETE ON public.document_generation_attempts
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 2. DOCUMENT PRINTING SEQUENCES & BOUNDED BATCHES (5 — DOC-003 / T-13)
-- ===========================================================================

CREATE TABLE public.document_print_counters (
  document_id uuid PRIMARY KEY REFERENCES public.documents(id) ON DELETE RESTRICT,
  last_sequence_no integer NOT NULL DEFAULT 0 CHECK (last_sequence_no >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.print_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  location_id uuid NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
  requested_count integer NOT NULL CHECK (requested_count BETWEEN 1 AND 100),
  status text NOT NULL DEFAULT 'ACCEPTED' CHECK (status IN ('ACCEPTED', 'SUCCEEDED', 'PARTIAL', 'REJECTED')),
  request_hash text NOT NULL CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  retry_of_batch_id uuid NULL REFERENCES public.print_batches(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz NULL
);

CREATE INDEX idx_print_batches_project ON public.print_batches (project_id, created_at DESC);

CREATE TABLE public.print_batch_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.print_batches(id) ON DELETE RESTRICT,
  item_order integer NOT NULL CHECK (item_order >= 1),
  item_key text NOT NULL CHECK (char_length(trim(item_key)) BETWEEN 1 AND 128),
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE RESTRICT,
  expected_document_version integer NOT NULL CHECK (expected_document_version >= 1),
  CONSTRAINT uq_print_batch_items_key UNIQUE (batch_id, item_key),
  CONSTRAINT uq_print_batch_items_order UNIQUE (batch_id, item_order)
);

CREATE TRIGGER trg_print_batch_items_append_only
  BEFORE UPDATE OR DELETE ON public.print_batch_items
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.print_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NULL REFERENCES public.print_batches(id) ON DELETE RESTRICT,
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE RESTRICT,
  actor_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  sequence_no integer NOT NULL CHECK (sequence_no >= 1),
  attempt_no integer NOT NULL DEFAULT 1 CHECK (attempt_no >= 1),
  outcome text NOT NULL CHECK (outcome IN ('RECORDED', 'FAILED')),
  failure_code text NULL,
  client_print_signal text NULL CHECK (client_print_signal IS NULL OR char_length(trim(client_print_signal)) <= 100),
  idempotency_key_hash text NOT NULL CHECK (idempotency_key_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_print_events_doc_seq UNIQUE (document_id, sequence_no)
);

CREATE TRIGGER trg_print_events_append_only
  BEFORE UPDATE OR DELETE ON public.print_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.print_batch_item_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_item_id uuid NOT NULL REFERENCES public.print_batch_items(id) ON DELETE RESTRICT,
  attempt_no integer NOT NULL DEFAULT 1 CHECK (attempt_no >= 1),
  outcome text NOT NULL CHECK (outcome IN ('RECORDED', 'REJECTED', 'FAILED')),
  failure_code text NULL,
  print_event_id uuid NULL REFERENCES public.print_events(id) ON DELETE RESTRICT,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_print_batch_item_results UNIQUE (batch_item_id, attempt_no)
);

CREATE TRIGGER trg_print_batch_item_results_append_only
  BEFORE UPDATE OR DELETE ON public.print_batch_item_results
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 3. ATTENDANCE RECORDS, REPLACEMENT DOCUMENTS & VERIFICATION (3 — T-08)
-- ===========================================================================

CREATE TABLE public.attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL,
  location_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'UPLOADED', 'VERIFIED', 'REJECTED')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_attendance_session_location UNIQUE (session_id, location_id),
  CONSTRAINT fk_attendance_session_proj FOREIGN KEY (session_id, project_id) REFERENCES public.sessions(id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_attendance_loc_proj FOREIGN KEY (location_id, project_id) REFERENCES public.locations(id, project_id) ON DELETE RESTRICT
);

CREATE TABLE public.attendance_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_record_id uuid NOT NULL REFERENCES public.attendance_records(id) ON DELETE RESTRICT,
  version_no integer NOT NULL CHECK (version_no >= 1),
  object_key text NOT NULL UNIQUE CHECK (char_length(trim(object_key)) BETWEEN 10 AND 300),
  sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  byte_size integer NOT NULL CHECK (byte_size BETWEEN 1 AND 15728640),
  mime_type text NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  uploaded_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  replacement_reason text NULL CHECK (replacement_reason IS NULL OR char_length(trim(replacement_reason)) BETWEEN 3 AND 500),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUPERSEDED')),
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_attendance_docs_version UNIQUE (attendance_record_id, version_no)
);

CREATE TABLE public.attendance_verification_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_record_id uuid NOT NULL REFERENCES public.attendance_records(id) ON DELETE RESTRICT,
  attendance_document_id uuid NOT NULL REFERENCES public.attendance_documents(id) ON DELETE RESTRICT,
  verifier_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  decision text NOT NULL CHECK (decision IN ('VERIFY', 'REJECT')),
  reason text NULL CHECK (reason IS NULL OR char_length(trim(reason)) <= 1000),
  decided_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_attendance_verif_append_only
  BEFORE UPDATE OR DELETE ON public.attendance_verification_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 4. NOTIFICATION LIFECYCLE TABLES (7 — NLA-001 / POQ-01..03 / NLA-MVP-001)
-- ===========================================================================

CREATE TABLE public.notification_policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_key text NOT NULL CHECK (policy_key ~ '^[A-Z0-9][A-Z0-9_.-]{2,63}$'),
  version_no integer NOT NULL CHECK (version_no >= 1),
  scope_type text NOT NULL CHECK (scope_type IN ('GLOBAL', 'PROJECT')),
  scope_id uuid NULL,
  schema_version text NOT NULL DEFAULT '1.0',
  sla_mode text NOT NULL DEFAULT 'ELAPSED_UTC' CHECK (sla_mode IN ('ELAPSED_UTC', 'BUSINESS_TIME')),
  policy_document jsonb NOT NULL CHECK (jsonb_typeof(policy_document) = 'object'),
  policy_hash text NOT NULL CHECK (policy_hash ~ '^[0-9a-f]{64}$'),
  status text NOT NULL DEFAULT 'PUBLISHED' CHECK (status IN ('PUBLISHED', 'RETIRED')),
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_until timestamptz NULL,
  published_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_notif_policy_version UNIQUE (policy_key, scope_type, version_no)
);

CREATE TABLE public.notification_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_event_id uuid NOT NULL,
  event_type text NOT NULL CHECK (char_length(trim(event_type)) BETWEEN 3 AND 128),
  scope_type text NOT NULL,
  scope_id uuid NULL,
  policy_version_id uuid NOT NULL REFERENCES public.notification_policy_versions(id) ON DELETE RESTRICT,
  safe_payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(safe_payload) = 'object'),
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'RETRY_WAIT', 'DEAD_LETTER')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  lease_owner text NULL,
  lease_token_hash text NULL CHECK (lease_token_hash IS NULL OR lease_token_hash ~ '^[0-9a-f]{64}$'),
  lease_generation bigint NOT NULL DEFAULT 0 CHECK (lease_generation >= 0),
  lease_expires_at timestamptz NULL,
  last_error_code text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz NULL,
  CONSTRAINT uq_notif_outbox_source_policy UNIQUE (source_event_id, policy_version_id)
);

-- POQ-01 Option C / NLA-MVP-001 Option A: immutable event-time candidate audience snapshot
CREATE TABLE public.notification_outbox_recipients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id uuid NOT NULL REFERENCES public.notification_outbox(id) ON DELETE RESTRICT,
  recipient_user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  eligibility_reason text NOT NULL CHECK (char_length(trim(eligibility_reason)) BETWEEN 3 AND 200),
  source_scope_type text NOT NULL,
  source_scope_id uuid NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_notif_outbox_recipient UNIQUE (outbox_id, recipient_user_id)
);

CREATE TRIGGER trg_notif_outbox_recipients_append_only
  BEFORE UPDATE OR DELETE ON public.notification_outbox_recipients
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- POQ-03 Option A: recipient-owned set-once read_at ONLY; dismissed_at strictly dormant
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id uuid NOT NULL REFERENCES public.notification_outbox(id) ON DELETE RESTRICT,
  recipient_user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  project_id uuid NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  event_type text NOT NULL CHECK (char_length(trim(event_type)) BETWEEN 3 AND 128),
  priority text NOT NULL DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL')),
  title_key text NOT NULL CHECK (char_length(trim(title_key)) BETWEEN 3 AND 128),
  body_key text NOT NULL CHECK (char_length(trim(body_key)) BETWEEN 3 AND 128),
  safe_payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(safe_payload) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NULL,
  read_at timestamptz NULL,
  dismissed_at timestamptz NULL,
  CONSTRAINT uq_notifications_outbox_recipient UNIQUE (outbox_id, recipient_user_id),
  CONSTRAINT chk_notifications_dismissed_dormant CHECK (dismissed_at IS NULL)
);

CREATE INDEX idx_notifications_recipient_created ON public.notifications (recipient_user_id, created_at DESC, id DESC);

CREATE TABLE public.notification_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE RESTRICT,
  channel text NOT NULL CHECK (channel IN ('IN_APP', 'EMAIL', 'PUSH')),
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'SENDING', 'RETRY_WAIT', 'SENT', 'DELIVERED', 'SUPPRESSED', 'FAILED', 'UNKNOWN')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at timestamptz NULL,
  last_attempt_at timestamptz NULL,
  sent_at timestamptz NULL,
  delivered_at timestamptz NULL,
  lease_owner text NULL,
  lease_token_hash text NULL CHECK (lease_token_hash IS NULL OR lease_token_hash ~ '^[0-9a-f]{64}$'),
  lease_generation bigint NOT NULL DEFAULT 0 CHECK (lease_generation >= 0),
  lease_expires_at timestamptz NULL,
  provider_message_ref text NULL,
  last_error_code text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_notif_deliveries_channel UNIQUE (notification_id, channel)
);

CREATE TABLE public.notification_delivery_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id uuid NOT NULL REFERENCES public.notification_deliveries(id) ON DELETE RESTRICT,
  attempt_no integer NOT NULL CHECK (attempt_no >= 1),
  idempotency_key_hash text NOT NULL CHECK (idempotency_key_hash ~ '^[0-9a-f]{64}$'),
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz NOT NULL DEFAULT now(),
  outcome text NOT NULL CHECK (outcome IN ('SENT', 'DELIVERED', 'SUPPRESSED', 'FAILED', 'UNKNOWN')),
  safe_error_code text NULL,
  retryable boolean NOT NULL DEFAULT false,
  CONSTRAINT uq_notif_delivery_attempts UNIQUE (delivery_id, attempt_no)
);

CREATE TRIGGER trg_notif_delivery_attempts_append_only
  BEFORE UPDATE OR DELETE ON public.notification_delivery_attempts
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.notification_escalation_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE RESTRICT,
  policy_version_id uuid NOT NULL REFERENCES public.notification_policy_versions(id) ON DELETE RESTRICT,
  step_no integer NOT NULL CHECK (step_no >= 1),
  event_type text NOT NULL CHECK (char_length(trim(event_type)) BETWEEN 3 AND 128),
  due_at timestamptz NOT NULL,
  evaluated_at timestamptz NOT NULL DEFAULT now(),
  outbox_id uuid NULL REFERENCES public.notification_outbox(id) ON DELETE RESTRICT,
  outcome text NOT NULL CHECK (outcome IN ('ENQUEUED', 'NO_ELIGIBLE_RECIPIENT', 'NOT_DUE')),
  reason_code text NULL,
  CONSTRAINT uq_notif_escalation_step UNIQUE (notification_id, policy_version_id, step_no, event_type)
);

CREATE TRIGGER trg_notif_escalation_append_only
  BEFORE UPDATE OR DELETE ON public.notification_escalation_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 5. RLS ENABLE + FORCE (62/62 PARITY), GRANTS & SCOPED SELECT POLICIES
-- ===========================================================================

DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'document_template_versions', 'documents', 'document_generation_jobs', 'document_generation_attempts',
    'document_print_counters', 'print_batches', 'print_batch_items', 'print_batch_item_results', 'print_events',
    'attendance_records', 'attendance_documents', 'attendance_verification_events',
    'notification_policy_versions', 'notification_outbox', 'notification_outbox_recipients',
    'notifications', 'notification_deliveries', 'notification_delivery_attempts', 'notification_escalation_events'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, anon, authenticated', v_tbl);
  END LOOP;
END
$$;

-- Browser `authenticated` SELECT only on user-readable tables (worker queues stay internal)
GRANT SELECT ON TABLE
  public.document_template_versions,
  public.documents,
  public.document_generation_jobs,
  public.document_print_counters,
  public.print_batches,
  public.print_batch_items,
  public.print_batch_item_results,
  public.print_events,
  public.attendance_records,
  public.attendance_documents,
  public.attendance_verification_events,
  public.notification_policy_versions,
  public.notifications
TO authenticated;

-- Narrow grants for app_cmd_definer & app_worker_definer
GRANT SELECT, INSERT, UPDATE ON TABLE
  public.document_template_versions,
  public.documents,
  public.document_generation_jobs,
  public.document_print_counters,
  public.print_batches,
  public.attendance_records,
  public.attendance_documents,
  public.notification_policy_versions,
  public.notification_outbox,
  public.notifications,
  public.notification_deliveries
TO app_cmd_definer;

GRANT SELECT, INSERT ON TABLE
  public.document_generation_attempts,
  public.print_batch_items,
  public.print_batch_item_results,
  public.print_events,
  public.attendance_verification_events,
  public.notification_outbox_recipients,
  public.notification_delivery_attempts,
  public.notification_escalation_events
TO app_cmd_definer;

GRANT SELECT, INSERT, UPDATE ON TABLE
  public.notification_outbox,
  public.notifications,
  public.notification_deliveries
TO app_worker_definer;

GRANT SELECT, INSERT ON TABLE
  public.notification_outbox_recipients,
  public.notification_delivery_attempts,
  public.notification_escalation_events
TO app_worker_definer;

GRANT SELECT ON TABLE public.app_users, public.notification_policy_versions TO app_worker_definer;

-- Explicit RLS policies for app_cmd_definer & app_worker_definer (no BYPASSRLS)
DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'document_template_versions', 'documents', 'document_generation_jobs', 'document_print_counters',
    'print_batches', 'attendance_records', 'attendance_documents',
    'notification_policy_versions', 'notification_outbox', 'notifications', 'notification_deliveries'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true)', v_tbl || '_cmd_upd', v_tbl);
  END LOOP;

  FOREACH v_tbl IN ARRAY ARRAY[
    'document_generation_attempts', 'print_batch_items', 'print_batch_item_results', 'print_events',
    'attendance_verification_events', 'notification_outbox_recipients', 'notification_delivery_attempts',
    'notification_escalation_events'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
  END LOOP;

  FOREACH v_tbl IN ARRAY ARRAY['notification_outbox', 'notifications', 'notification_deliveries'] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_worker_definer USING (true)', v_tbl || '_wrk_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_worker_definer WITH CHECK (true)', v_tbl || '_wrk_ins', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO app_worker_definer USING (true) WITH CHECK (true)', v_tbl || '_wrk_upd', v_tbl);
  END LOOP;

  FOREACH v_tbl IN ARRAY ARRAY['notification_outbox_recipients', 'notification_delivery_attempts', 'notification_escalation_events'] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_worker_definer USING (true)', v_tbl || '_wrk_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_worker_definer WITH CHECK (true)', v_tbl || '_wrk_ins', v_tbl);
  END LOOP;
END
$$;

CREATE POLICY app_users_wrk_sel ON public.app_users FOR SELECT TO app_worker_definer USING (true);
CREATE POLICY notif_policy_wrk_sel ON public.notification_policy_versions FOR SELECT TO app_worker_definer USING (true);

-- Browser `authenticated` scoped SELECT RLS policies
CREATE POLICY doc_templates_select_approved ON public.document_template_versions
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.app_users u WHERE u.id = app_internal.current_app_user_id() AND u.account_status = 'APPROVED'));

CREATE POLICY documents_select_scoped ON public.documents
  FOR SELECT TO authenticated USING (app_internal.has_project_access(project_id));

CREATE POLICY doc_gen_jobs_select_scoped ON public.document_generation_jobs
  FOR SELECT TO authenticated USING (app_internal.has_project_access(project_id));

CREATE POLICY doc_print_counters_select_scoped ON public.document_print_counters
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.documents d WHERE d.id = document_id AND app_internal.has_project_access(d.project_id)));

CREATE POLICY print_batches_select_scoped ON public.print_batches
  FOR SELECT TO authenticated USING (app_internal.has_project_access(project_id));

CREATE POLICY print_batch_items_select_scoped ON public.print_batch_items
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.print_batches b WHERE b.id = batch_id AND app_internal.has_project_access(b.project_id)));

CREATE POLICY print_batch_item_results_select_scoped ON public.print_batch_item_results
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.print_batch_items bi JOIN public.print_batches b ON b.id = bi.batch_id
    WHERE bi.id = batch_item_id AND app_internal.has_project_access(b.project_id)
  ));

CREATE POLICY print_events_select_scoped ON public.print_events
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.documents d WHERE d.id = document_id AND app_internal.has_project_access(d.project_id)));

CREATE POLICY attendance_records_select_scoped ON public.attendance_records
  FOR SELECT TO authenticated USING (app_internal.has_project_access(project_id));

CREATE POLICY attendance_docs_select_scoped ON public.attendance_documents
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.attendance_records ar WHERE ar.id = attendance_record_id AND app_internal.has_project_access(ar.project_id)));

CREATE POLICY attendance_verif_select_scoped ON public.attendance_verification_events
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.attendance_records ar WHERE ar.id = attendance_record_id AND app_internal.has_project_access(ar.project_id)));

CREATE POLICY notif_policy_select_authorized ON public.notification_policy_versions
  FOR SELECT TO authenticated
  USING (
    app_internal.has_global_permission('notification.policy.manage')
    OR (scope_type = 'PROJECT' AND app_internal.has_project_access(scope_id))
  );

-- POQ-03: Strict recipient-self read only; zero cross-user enumeration
CREATE POLICY notifications_select_self ON public.notifications
  FOR SELECT TO authenticated
  USING (recipient_user_id = app_internal.current_app_user_id());
