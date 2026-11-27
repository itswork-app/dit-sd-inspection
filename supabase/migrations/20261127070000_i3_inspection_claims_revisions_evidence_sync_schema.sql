-- Migration: 20261127070000_i3_inspection_claims_revisions_evidence_sync_schema.sql
-- Scope: Slice 3 (I3/I4) — 14 canonical tables for Inspection Lifecycle, Unit Claims,
--        Draft Contexts (IDC-O01..O10), Immutable Revisions, Review Arbiter, Packed-Unit
--        Abort (SES-001), Private Evidence Intents/Assets, and Offline Sync (T-09 Option B).
-- Authority: AGENTS.md v1.3.0 (G9-TECH FROZEN / G10 SYNTHETIC ACTIVE),
--            Physical Schema v1.0.0, RLS Catalogue v1.0.0, OFFLINE-SYNC v1.0.0,
--            IDC-O04..O10, SES-001, T-09, T-16, T-18.

-- ===========================================================================
-- 1. INSPECTIONS & MUTABLE DRAFT CONTEXT (IDC-O01..O10)
-- ===========================================================================

CREATE TABLE public.inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
  unit_project_association_id uuid NOT NULL,
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL,
  assignment_id uuid NOT NULL,
  instrument_version_id uuid NOT NULL REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'SUBMITTED', 'RETURNED', 'APPROVED', 'REOPENED', 'ABORTED')),
  current_revision_no integer NOT NULL DEFAULT 0 CHECK (current_revision_no >= 0),
  owner_user_id uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_inspections_unit_assoc
    FOREIGN KEY (unit_project_association_id, unit_id, project_id)
    REFERENCES public.unit_project_associations(id, unit_id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_inspections_session_project
    FOREIGN KEY (session_id, project_id) REFERENCES public.sessions(id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_inspections_assignment_project
    FOREIGN KEY (assignment_id, project_id) REFERENCES public.operational_assignments(id, project_id) ON DELETE RESTRICT
);

-- At most one active non-terminal inspection per (unit_id, session_id).
-- Prior ABORTED attempt remains permanently terminal; reopened session may accept new inspection_id (IDC-O10/SES-T10).
CREATE UNIQUE INDEX uq_inspections_one_active_per_unit_session
  ON public.inspections (unit_id, session_id)
  WHERE status NOT IN ('APPROVED', 'ABORTED');

CREATE INDEX idx_inspections_project_status ON public.inspections (project_id, status, updated_at DESC);
CREATE INDEX idx_inspections_assignment ON public.inspections (assignment_id, status);

CREATE TABLE public.inspection_draft_contexts (
  inspection_id uuid PRIMARY KEY REFERENCES public.inspections(id) ON DELETE RESTRICT,
  draft_checklist jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(draft_checklist) = 'object'),
  draft_specifications jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(draft_specifications) = 'object'),
  notes text NULL CHECK (notes IS NULL OR char_length(notes) <= 2000),
  has_unresolved_sync_conflict boolean NOT NULL DEFAULT false,
  updated_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  updated_at timestamptz NOT NULL DEFAULT now(),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1)
);

-- ===========================================================================
-- 2. IMMUTABLE SUBMITTED REVISIONS & RESPONSES (Append-Only)
-- ===========================================================================

CREATE TABLE public.inspection_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  revision_no integer NOT NULL CHECK (revision_no >= 1),
  instrument_version_id uuid NOT NULL REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  snapshot_hash text NOT NULL CHECK (char_length(snapshot_hash) = 64),
  author_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  payload_snapshot jsonb NOT NULL CHECK (jsonb_typeof(payload_snapshot) = 'object'),
  submit_reason text NULL CHECK (submit_reason IS NULL OR char_length(trim(submit_reason)) <= 500),
  submitted_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_inspection_revisions_no UNIQUE (inspection_id, revision_no)
);

CREATE TRIGGER trg_inspection_revisions_append_only
  BEFORE UPDATE OR DELETE ON public.inspection_revisions
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.checklist_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_revision_id uuid NOT NULL REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  checklist_item_id uuid NOT NULL REFERENCES public.checklist_items(id) ON DELETE RESTRICT,
  answer jsonb NOT NULL,
  note text NULL CHECK (note IS NULL OR char_length(note) <= 1000),
  answered_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  answered_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_checklist_responses_rev_item UNIQUE (inspection_revision_id, checklist_item_id)
);

CREATE TRIGGER trg_checklist_responses_append_only
  BEFORE UPDATE OR DELETE ON public.checklist_responses
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.specification_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_revision_id uuid NOT NULL REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  specification_field_id uuid NOT NULL REFERENCES public.specification_fields(id) ON DELETE RESTRICT,
  observed_value text NOT NULL CHECK (char_length(observed_value) BETWEEN 1 AND 500),
  note text NULL CHECK (note IS NULL OR char_length(note) <= 1000),
  CONSTRAINT uq_spec_responses_rev_field UNIQUE (inspection_revision_id, specification_field_id)
);

CREATE TRIGGER trg_specification_responses_append_only
  BEFORE UPDATE OR DELETE ON public.specification_responses
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 3. GLOBAL UNIT CLAIMS, REVIEW ARBITER, EVENTS & SES-001 ABORT
-- ===========================================================================

CREATE TABLE public.unit_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
  unit_project_association_id uuid NOT NULL,
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  assignment_id uuid NOT NULL,
  inspector_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RELEASED', 'EXPIRED')),
  claimed_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  released_at timestamptz NULL,
  release_reason text NULL CHECK (release_reason IS NULL OR char_length(trim(release_reason)) <= 500),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  CONSTRAINT chk_unit_claims_expiry CHECK (expires_at > claimed_at),
  CONSTRAINT fk_unit_claims_assoc
    FOREIGN KEY (unit_project_association_id, unit_id, project_id)
    REFERENCES public.unit_project_associations(id, unit_id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_unit_claims_assignment
    FOREIGN KEY (assignment_id, project_id) REFERENCES public.operational_assignments(id, project_id) ON DELETE RESTRICT
);

-- T-16 / LPR-02: At most ONE ACTIVE claim globally per canonical physical unit across all projects!
CREATE UNIQUE INDEX uq_unit_claims_one_active_global
  ON public.unit_claims (unit_id)
  WHERE status = 'ACTIVE';

CREATE INDEX idx_unit_claims_inspector ON public.unit_claims (inspector_id, status);
CREATE INDEX idx_unit_claims_project ON public.unit_claims (project_id, status);

CREATE TABLE public.inspection_reviewer_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  reviewer_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ENDED')),
  assigned_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  assigned_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_inspection_reviewer_active
  ON public.inspection_reviewer_assignments (inspection_id, reviewer_id)
  WHERE status = 'ACTIVE';

-- Single terminal-decision-per-revision arbiter (Append-Only)
CREATE TABLE public.review_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  inspection_revision_id uuid NOT NULL UNIQUE REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  reviewer_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  decision text NOT NULL CHECK (decision IN ('RETURN', 'APPROVE')),
  reason text NULL CHECK (reason IS NULL OR char_length(trim(reason)) <= 1000),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_review_return_reason CHECK (
    decision = 'APPROVE' OR (reason IS NOT NULL AND char_length(trim(reason)) >= 5)
  )
);

CREATE TRIGGER trg_review_events_append_only
  BEFORE UPDATE OR DELETE ON public.review_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

CREATE TABLE public.inspection_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  event_type text NOT NULL CHECK (char_length(trim(event_type)) BETWEEN 3 AND 100),
  actor_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  from_state text NULL,
  to_state text NOT NULL,
  reason text NULL CHECK (reason IS NULL OR char_length(trim(reason)) <= 1000),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_inspection_events_insp ON public.inspection_events (inspection_id, created_at DESC);

CREATE TRIGGER trg_inspection_events_append_only
  BEFORE UPDATE OR DELETE ON public.inspection_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- SES-001 Packed-Unit Abort Workflow (CMD-055 / CMD-056)
CREATE TABLE public.inspection_abort_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  requested_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  request_reason text NOT NULL CHECK (char_length(trim(request_reason)) BETWEEN 5 AND 1000),
  decided_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  decision_reason text NULL CHECK (decision_reason IS NULL OR char_length(trim(decision_reason)) BETWEEN 5 AND 1000),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz NULL,
  CONSTRAINT chk_abort_request_sod CHECK (decided_by IS NULL OR decided_by <> requested_by)
);

CREATE UNIQUE INDEX uq_abort_requests_one_pending
  ON public.inspection_abort_requests (inspection_id)
  WHERE status = 'PENDING';

-- ===========================================================================
-- 4. PRIVATE EVIDENCE ASSETS (CMD-033 / CMD-034 + IDC-O04..O06 carry-forward)
-- ===========================================================================

CREATE TABLE public.evidence_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  inspection_revision_id uuid NULL REFERENCES public.inspection_revisions(id) ON DELETE RESTRICT,
  slot_definition_id uuid NOT NULL REFERENCES public.evidence_slot_definitions(id) ON DELETE RESTRICT,
  origin_evidence_asset_id uuid NULL REFERENCES public.evidence_assets(id) ON DELETE RESTRICT,
  client_file_id text NOT NULL CHECK (char_length(trim(client_file_id)) BETWEEN 4 AND 128),
  object_key text NOT NULL UNIQUE CHECK (char_length(trim(object_key)) BETWEEN 10 AND 300),
  expected_sha256 text NOT NULL CHECK (expected_sha256 ~ '^[0-9a-f]{64}$'),
  observed_sha256 text NULL CHECK (observed_sha256 IS NULL OR observed_sha256 ~ '^[0-9a-f]{64}$'),
  expected_byte_size integer NOT NULL CHECK (expected_byte_size BETWEEN 1 AND 15728640),
  observed_byte_size integer NULL CHECK (observed_byte_size IS NULL OR observed_byte_size BETWEEN 1 AND 15728640),
  mime_type text NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  upload_status text NOT NULL DEFAULT 'INTENT_CREATED'
    CHECK (upload_status IN ('INTENT_CREATED', 'FINALIZED', 'FAILED', 'SUPERSEDED')),
  uploaded_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  finalized_at timestamptz NULL,
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  CONSTRAINT uq_evidence_assets_client_file UNIQUE (inspection_id, client_file_id)
);

CREATE INDEX idx_evidence_assets_inspection ON public.evidence_assets (inspection_id, slot_definition_id, upload_status);

-- ===========================================================================
-- 5. OFFLINE DEVICE BINDING & DURABLE SYNC LEDGER (T-09 Option B / CMD-035)
-- ===========================================================================

CREATE TABLE public.device_bindings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  device_fingerprint_hash text NOT NULL CHECK (device_fingerprint_hash ~ '^[0-9a-f]{64}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 2 AND 100),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REVOKED')),
  bound_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz NULL
);

CREATE UNIQUE INDEX uq_device_bindings_active
  ON public.device_bindings (user_id, device_fingerprint_hash)
  WHERE status = 'ACTIVE';

CREATE TABLE public.sync_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  device_id uuid NOT NULL REFERENCES public.device_bindings(id) ON DELETE RESTRICT,
  batch_key text NOT NULL CHECK (char_length(trim(batch_key)) BETWEEN 8 AND 128),
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  status text NOT NULL CHECK (status IN ('ACCEPTED', 'APPLIED', 'PARTIAL', 'CONFLICTED')),
  operation_count integer NOT NULL CHECK (operation_count BETWEEN 1 AND 50),
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_sync_batches_key UNIQUE (actor_user_id, device_id, batch_key)
);

CREATE TABLE public.sync_batch_operations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.sync_batches(id) ON DELETE RESTRICT,
  operation_id text NOT NULL CHECK (char_length(trim(operation_id)) BETWEEN 4 AND 128),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id) ON DELETE RESTRICT,
  op_type text NOT NULL CHECK (op_type IN ('SAVE_DRAFT')),
  expected_row_version bigint NOT NULL CHECK (expected_row_version >= 1),
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
  outcome text NOT NULL CHECK (outcome IN ('APPLIED', 'CONFLICTED', 'DENIED', 'FAILED')),
  conflict_snapshot jsonb NULL,
  resulting_row_version bigint NULL,
  processed_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_sync_batch_ops_key UNIQUE (batch_id, operation_id)
);

-- ===========================================================================
-- 6. RLS ENABLE + FORCE, LEAST-PRIVILEGE GRANTS & SCOPED SELECT POLICIES
-- ===========================================================================

DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'inspections', 'inspection_draft_contexts', 'inspection_revisions',
    'checklist_responses', 'specification_responses', 'unit_claims',
    'inspection_reviewer_assignments', 'review_events', 'inspection_events',
    'inspection_abort_requests', 'evidence_assets', 'device_bindings',
    'sync_batches', 'sync_batch_operations'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, anon, authenticated', v_tbl);
    EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated', v_tbl);
  END LOOP;
END
$$;

-- Narrow grants for app_cmd_definer
GRANT SELECT, INSERT, UPDATE ON TABLE
  public.inspections,
  public.inspection_draft_contexts,
  public.unit_claims,
  public.inspection_reviewer_assignments,
  public.inspection_abort_requests,
  public.evidence_assets,
  public.device_bindings,
  public.sync_batches
TO app_cmd_definer;

-- Append-only tables: SELECT + INSERT only (zero UPDATE/DELETE)
GRANT SELECT, INSERT ON TABLE
  public.inspection_revisions,
  public.checklist_responses,
  public.specification_responses,
  public.review_events,
  public.inspection_events,
  public.sync_batch_operations
TO app_cmd_definer;

-- Explicit RLS policies for app_cmd_definer (no BYPASSRLS)
DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'inspections', 'inspection_draft_contexts', 'unit_claims',
    'inspection_reviewer_assignments', 'inspection_abort_requests',
    'evidence_assets', 'device_bindings', 'sync_batches'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true)', v_tbl || '_cmd_upd', v_tbl);
  END LOOP;

  FOREACH v_tbl IN ARRAY ARRAY[
    'inspection_revisions', 'checklist_responses', 'specification_responses',
    'review_events', 'inspection_events', 'sync_batch_operations'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
  END LOOP;
END
$$;

-- Browser `authenticated` scoped SELECT policies (deny-by-default)
CREATE POLICY inspections_select_scoped ON public.inspections
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY draft_contexts_select_scoped ON public.inspection_draft_contexts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY revisions_select_scoped ON public.inspection_revisions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY checklist_responses_select_scoped ON public.checklist_responses
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.inspection_revisions r
      JOIN public.inspections i ON i.id = r.inspection_id
      WHERE r.id = inspection_revision_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY spec_responses_select_scoped ON public.specification_responses
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.inspection_revisions r
      JOIN public.inspections i ON i.id = r.inspection_id
      WHERE r.id = inspection_revision_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY unit_claims_select_scoped ON public.unit_claims
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY reviewer_assignments_select_scoped ON public.inspection_reviewer_assignments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY review_events_select_scoped ON public.review_events
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY inspection_events_select_scoped ON public.inspection_events
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY abort_requests_select_scoped ON public.inspection_abort_requests
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY evidence_assets_select_scoped ON public.evidence_assets
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND app_internal.has_project_access(i.project_id)
    )
  );

CREATE POLICY device_bindings_select_self ON public.device_bindings
  FOR SELECT TO authenticated
  USING (user_id = app_internal.current_app_user_id());

CREATE POLICY sync_batches_select_self ON public.sync_batches
  FOR SELECT TO authenticated
  USING (actor_user_id = app_internal.current_app_user_id());

CREATE POLICY sync_batch_operations_select_self ON public.sync_batch_operations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.sync_batches sb
      WHERE sb.id = batch_id AND sb.actor_user_id = app_internal.current_app_user_id()
    )
  );
