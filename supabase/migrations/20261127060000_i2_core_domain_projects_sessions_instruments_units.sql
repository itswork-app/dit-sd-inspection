-- Migration: 20261127060000_i2_core_domain_projects_sessions_instruments_units.sql
-- Scope: Slice 2 (I2/I3) Core Operational Schema (19 canonical tables) + RLS + T-14/T-16/T-17 invariants.
-- Tables:
--   Planning (9): projects, project_capacity_settings, locations, sessions, teams,
--                 operational_assignments, assignment_members, target_plans, target_allocations
--   Instruments (7): instruments, instrument_versions, checklist_sections, checklist_items,
--                    specification_fields, evidence_slot_definitions, instrument_version_publications
--   Canonical Units (3): units, unit_project_associations, unit_identity_conflicts
-- Authority: AGENTS.md v1.3.0 (G9-TECH FROZEN / G10 SYNTHETIC ACTIVE),
--            Physical Schema v1.0.0, RLS Catalogue v1.0.0, T-14, T-16, T-17, T-18.

-- ===========================================================================
-- 1. PROJECT & OPERATIONAL PLANNING TABLES (9)
-- ===========================================================================

CREATE TABLE public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 160),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
  timezone text NOT NULL DEFAULT 'Asia/Jakarta' CHECK (char_length(trim(timezone)) BETWEEN 3 AND 64),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz NULL,
  closed_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  close_reason text NULL CHECK (close_reason IS NULL OR char_length(trim(close_reason)) BETWEEN 3 AND 1000)
);

CREATE INDEX idx_projects_status ON public.projects (status, created_at DESC);

-- L10 Shared Invariant Serialization Row (T-14 PO APPROVED Option A)
CREATE TABLE public.project_capacity_settings (
  project_id uuid PRIMARY KEY REFERENCES public.projects(id) ON DELETE RESTRICT,
  inspector_cap integer NOT NULL DEFAULT 50 CHECK (inspector_cap BETWEEN 1 AND 100),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  updated_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 160),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_locations_project_code UNIQUE (project_id, code),
  CONSTRAINT uq_locations_id_project UNIQUE (id, project_id)
);

CREATE INDEX idx_locations_project ON public.locations (project_id, status);

-- T-07 Canonical Session States: DRAFT / ACTIVE / PAUSED / CLOSED
CREATE TABLE public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'PAUSED', 'CLOSED')),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  started_at timestamptz NULL,
  closed_at timestamptz NULL,
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_sessions_interval CHECK (ends_at > starts_at),
  CONSTRAINT uq_sessions_project_code UNIQUE (project_id, code),
  CONSTRAINT uq_sessions_id_project UNIQUE (id, project_id)
);

CREATE INDEX idx_sessions_project_status ON public.sessions (project_id, status, starts_at DESC);

CREATE TABLE public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 160),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_teams_project_code UNIQUE (project_id, code),
  CONSTRAINT uq_teams_id_project UNIQUE (id, project_id)
);

CREATE INDEX idx_teams_project ON public.teams (project_id, status);

-- ===========================================================================
-- 2. EXTENSIBLE INSTRUMENT CATALOGUE & CONFIGURATION TABLES (7 — CFG-001/T-17)
-- ===========================================================================

CREATE TABLE public.instruments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_type text NOT NULL UNIQUE CHECK (instrument_type ~ '^[A-Z][A-Z0-9_]{1,63}$'),
  code text NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{1,63}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 160),
  description text NULL CHECK (description IS NULL OR char_length(trim(description)) <= 1000),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'INACTIVE', 'ARCHIVED')),
  serial_case_insensitive boolean NOT NULL DEFAULT true,
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.instrument_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_id uuid NOT NULL REFERENCES public.instruments(id) ON DELETE RESTRICT,
  version_number integer NOT NULL CHECK (version_number >= 1),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  schema_version text NOT NULL DEFAULT '1.0' CHECK (char_length(trim(schema_version)) BETWEEN 1 AND 32),
  draft_hash text NULL CHECK (draft_hash IS NULL OR char_length(draft_hash) = 64),
  published_snapshot jsonb NULL,
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_instrument_versions_no UNIQUE (instrument_id, version_number),
  CONSTRAINT uq_instrument_versions_id_inst UNIQUE (id, instrument_id)
);

CREATE INDEX idx_instrument_versions_inst ON public.instrument_versions (instrument_id, status, version_number DESC);

CREATE TABLE public.checklist_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_version_id uuid NOT NULL REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 1 AND 200),
  sort_order integer NOT NULL CHECK (sort_order >= 1),
  CONSTRAINT uq_checklist_sections_code UNIQUE (instrument_version_id, code),
  CONSTRAINT uq_checklist_sections_order UNIQUE (instrument_version_id, sort_order)
);

CREATE TABLE public.checklist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id uuid NOT NULL REFERENCES public.checklist_sections(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 1 AND 400),
  answer_type text NOT NULL CHECK (answer_type IN ('PASS_FAIL', 'YES_NO', 'TEXT', 'NUMBER', 'SINGLE_SELECT', 'MULTI_SELECT')),
  sort_order integer NOT NULL CHECK (sort_order >= 1),
  required boolean NOT NULL DEFAULT true,
  applicability_rule jsonb NULL CHECK (applicability_rule IS NULL OR jsonb_typeof(applicability_rule) = 'object'),
  validation_config jsonb NULL CHECK (validation_config IS NULL OR jsonb_typeof(validation_config) = 'object'),
  CONSTRAINT uq_checklist_items_code UNIQUE (section_id, code),
  CONSTRAINT uq_checklist_items_order UNIQUE (section_id, sort_order)
);

CREATE TABLE public.specification_fields (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_version_id uuid NOT NULL REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 1 AND 200),
  value_type text NOT NULL CHECK (value_type IN ('TEXT', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'ENUM')),
  expected_value text NULL,
  unit text NULL CHECK (unit IS NULL OR char_length(trim(unit)) <= 40),
  required boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL CHECK (sort_order >= 1),
  CONSTRAINT uq_specification_fields_code UNIQUE (instrument_version_id, code),
  CONSTRAINT uq_specification_fields_order UNIQUE (instrument_version_id, sort_order)
);

CREATE TABLE public.evidence_slot_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_version_id uuid NOT NULL REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (code ~ '^[A-Z0-9][A-Z0-9_-]{0,63}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 1 AND 200),
  required boolean NOT NULL DEFAULT true,
  allowed_media_types text[] NOT NULL CHECK (cardinality(allowed_media_types) BETWEEN 1 AND 10),
  sort_order integer NOT NULL CHECK (sort_order >= 1),
  applicability_rule jsonb NULL CHECK (applicability_rule IS NULL OR jsonb_typeof(applicability_rule) = 'object'),
  CONSTRAINT uq_evidence_slots_code UNIQUE (instrument_version_id, code),
  CONSTRAINT uq_evidence_slots_order UNIQUE (instrument_version_id, sort_order)
);

-- Append-only publication record (T-17)
CREATE TABLE public.instrument_version_publications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_version_id uuid NOT NULL UNIQUE REFERENCES public.instrument_versions(id) ON DELETE RESTRICT,
  published_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_at timestamptz NOT NULL DEFAULT now(),
  change_summary text NOT NULL CHECK (char_length(trim(change_summary)) BETWEEN 3 AND 1000),
  config_hash text NOT NULL CHECK (char_length(config_hash) = 64)
);

CREATE TRIGGER trg_instrument_version_publications_append_only
  BEFORE UPDATE OR DELETE ON public.instrument_version_publications
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ===========================================================================
-- 3. OPERATIONAL ASSIGNMENTS, MEMBERS & TARGETS (remaining 4 planning tables)
-- ===========================================================================

CREATE TABLE public.operational_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL,
  location_id uuid NOT NULL,
  instrument_id uuid NOT NULL REFERENCES public.instruments(id) ON DELETE RESTRICT,
  instrument_version_id uuid NOT NULL,
  team_id uuid NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'PUBLISHED' CHECK (status IN ('PUBLISHED', 'CLOSED', 'CANCELLED')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_assignments_interval CHECK (ends_at > starts_at),
  CONSTRAINT uq_assignments_id_project UNIQUE (id, project_id),
  CONSTRAINT fk_assignments_session_project
    FOREIGN KEY (session_id, project_id) REFERENCES public.sessions(id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_assignments_location_project
    FOREIGN KEY (location_id, project_id) REFERENCES public.locations(id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_assignments_team_project
    FOREIGN KEY (team_id, project_id) REFERENCES public.teams(id, project_id) ON DELETE RESTRICT,
  CONSTRAINT fk_assignments_instrument_version
    FOREIGN KEY (instrument_version_id, instrument_id) REFERENCES public.instrument_versions(id, instrument_id) ON DELETE RESTRICT
);

CREATE INDEX idx_assignments_project_session ON public.operational_assignments (project_id, session_id, status);
CREATE INDEX idx_assignments_location_interval ON public.operational_assignments (location_id, starts_at, ends_at);

CREATE TABLE public.assignment_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  project_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  operational_role text NOT NULL CHECK (operational_role IN ('korlap', 'reviewer', 'inspector', 'print_officer')),
  valid_from timestamptz NOT NULL DEFAULT now(),
  valid_until timestamptz NULL,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ENDED')),
  added_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  ended_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  end_reason text NULL CHECK (end_reason IS NULL OR char_length(trim(end_reason)) BETWEEN 3 AND 500),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_assignment_members_interval CHECK (valid_until IS NULL OR valid_until > valid_from),
  CONSTRAINT chk_assignment_members_no_self_add CHECK (added_by <> user_id),
  CONSTRAINT fk_assignment_members_assignment
    FOREIGN KEY (assignment_id, project_id) REFERENCES public.operational_assignments(id, project_id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX uq_assignment_members_active
  ON public.assignment_members (assignment_id, user_id, operational_role)
  WHERE status = 'ACTIVE';

CREATE INDEX idx_assignment_members_user_project ON public.assignment_members (user_id, project_id, status);
CREATE INDEX idx_assignment_members_assignment ON public.assignment_members (assignment_id, status);

CREATE TABLE public.target_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL,
  version integer NOT NULL CHECK (version >= 1),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'SUPERSEDED')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  published_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_target_plans_session_version UNIQUE (session_id, version),
  CONSTRAINT fk_target_plans_session_project
    FOREIGN KEY (session_id, project_id) REFERENCES public.sessions(id, project_id) ON DELETE RESTRICT
);

CREATE INDEX idx_target_plans_project_session ON public.target_plans (project_id, session_id, version DESC);

CREATE TABLE public.target_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_plan_id uuid NOT NULL REFERENCES public.target_plans(id) ON DELETE RESTRICT,
  assignment_id uuid NOT NULL REFERENCES public.operational_assignments(id) ON DELETE RESTRICT,
  target_date date NOT NULL,
  quantity integer NOT NULL CHECK (quantity >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_target_allocations_key UNIQUE (target_plan_id, assignment_id, target_date)
);

-- ===========================================================================
-- 4. CANONICAL UNITS, ASSOCIATIONS & CONFLICTS (3 — T-16 Option B)
-- ===========================================================================

CREATE TABLE public.units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_type text NOT NULL REFERENCES public.instruments(instrument_type) ON DELETE RESTRICT,
  serial_raw text NULL CHECK (serial_raw IS NULL OR char_length(serial_raw) BETWEEN 1 AND 160),
  serial_normalized text NULL CHECK (serial_normalized IS NULL OR char_length(serial_normalized) BETWEEN 1 AND 160),
  normalization_version text NOT NULL DEFAULT 'v1' CHECK (char_length(trim(normalization_version)) BETWEEN 1 AND 32),
  identity_attributes jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(identity_attributes) = 'object'),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RETIRED')),
  created_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T-16 Option B: global uniqueness strictly on (instrument_type, serial_normalized), zero project_id/instrument_id
CREATE UNIQUE INDEX uq_units_canonical_serial
  ON public.units (instrument_type, serial_normalized)
  WHERE serial_normalized IS NOT NULL;

CREATE INDEX idx_units_type_status ON public.units (instrument_type, status);

CREATE TABLE public.unit_project_associations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ENDED', 'REVOKED')),
  associated_at timestamptz NOT NULL DEFAULT now(),
  associated_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  association_reason text NOT NULL CHECK (char_length(trim(association_reason)) BETWEEN 3 AND 500),
  evidence_ref text NULL CHECK (evidence_ref IS NULL OR char_length(trim(evidence_ref)) <= 200),
  ended_at timestamptz NULL,
  ended_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  end_reason text NULL CHECK (end_reason IS NULL OR char_length(trim(end_reason)) BETWEEN 3 AND 500),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  CONSTRAINT uq_unit_project_assoc_composite UNIQUE (id, unit_id, project_id)
);

CREATE UNIQUE INDEX uq_unit_project_assoc_active
  ON public.unit_project_associations (unit_id, project_id)
  WHERE status = 'ACTIVE';

CREATE INDEX idx_unit_project_assoc_project ON public.unit_project_associations (project_id, status);

CREATE TABLE public.unit_identity_conflicts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_type text NOT NULL REFERENCES public.instruments(instrument_type) ON DELETE RESTRICT,
  serial_normalized text NOT NULL CHECK (char_length(serial_normalized) BETWEEN 1 AND 160),
  serial_raw_submitted text NOT NULL CHECK (char_length(serial_raw_submitted) BETWEEN 1 AND 160),
  proposed_project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
  candidate_unit_id uuid NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
  reported_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'RESOLVED', 'REJECTED')),
  resolution text NULL CHECK (resolution IS NULL OR resolution IN ('ASSOCIATE_EXISTING', 'REJECT')),
  resolved_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  resolution_reason text NULL CHECK (resolution_reason IS NULL OR char_length(trim(resolution_reason)) BETWEEN 3 AND 1000),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz NULL
);

CREATE UNIQUE INDEX uq_unit_conflicts_open_key
  ON public.unit_identity_conflicts (instrument_type, serial_normalized, proposed_project_id)
  WHERE status = 'OPEN';

CREATE INDEX idx_unit_conflicts_project_status ON public.unit_identity_conflicts (proposed_project_id, status);

-- ===========================================================================
-- 5. RLS ENABLE + FORCE, LEAST-PRIVILEGE GRANTS & INTERNAL HELPERS
-- ===========================================================================

DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'projects', 'project_capacity_settings', 'locations', 'sessions', 'teams',
    'operational_assignments', 'assignment_members', 'target_plans', 'target_allocations',
    'instruments', 'instrument_versions', 'checklist_sections', 'checklist_items',
    'specification_fields', 'evidence_slot_definitions', 'instrument_version_publications',
    'units', 'unit_project_associations', 'unit_identity_conflicts'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', v_tbl);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, anon, authenticated', v_tbl);
    EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated', v_tbl);
  END LOOP;
END
$$;

-- Narrow grants for app_cmd_definer:
-- Mutable tables: SELECT, INSERT, UPDATE (no DELETE except draft child replacement tables)
GRANT SELECT, INSERT, UPDATE ON TABLE
  public.projects,
  public.project_capacity_settings,
  public.locations,
  public.sessions,
  public.teams,
  public.operational_assignments,
  public.assignment_members,
  public.target_plans,
  public.instruments,
  public.instrument_versions,
  public.units,
  public.unit_project_associations,
  public.unit_identity_conflicts
TO app_cmd_definer;

-- Draft child replacement tables (CMD-017 target draft & CMD-019 instrument draft only)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.target_allocations,
  public.checklist_sections,
  public.checklist_items,
  public.specification_fields,
  public.evidence_slot_definitions
TO app_cmd_definer;

-- Append-only publication record: SELECT, INSERT only
GRANT SELECT, INSERT ON TABLE public.instrument_version_publications TO app_cmd_definer;

-- Explicit RLS policies for app_cmd_definer (no BYPASSRLS)
DO $$
DECLARE
  v_tbl text;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY[
    'projects', 'project_capacity_settings', 'locations', 'sessions', 'teams',
    'operational_assignments', 'assignment_members', 'target_plans',
    'instruments', 'instrument_versions',
    'units', 'unit_project_associations', 'unit_identity_conflicts'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true)', v_tbl || '_cmd_upd', v_tbl);
  END LOOP;

  FOREACH v_tbl IN ARRAY ARRAY[
    'target_allocations', 'checklist_sections', 'checklist_items',
    'specification_fields', 'evidence_slot_definitions'
  ] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO app_cmd_definer USING (true)', v_tbl || '_cmd_sel', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO app_cmd_definer WITH CHECK (true)', v_tbl || '_cmd_ins', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true)', v_tbl || '_cmd_upd', v_tbl);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR DELETE TO app_cmd_definer USING (true)', v_tbl || '_cmd_del', v_tbl);
  END LOOP;
END
$$;

CREATE POLICY instrument_version_publications_cmd_sel ON public.instrument_version_publications FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY instrument_version_publications_cmd_ins ON public.instrument_version_publications FOR INSERT TO app_cmd_definer WITH CHECK (true);

-- Internal RLS & T-14 helpers owned by app_cmd_definer
GRANT CREATE ON SCHEMA app_internal TO app_cmd_definer;

CREATE OR REPLACE FUNCTION app_internal.has_project_access(p_project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_users u
    WHERE u.auth_user_id = app_internal.current_auth_uid()
      AND u.account_status = 'APPROVED'
      AND (
        EXISTS (
          SELECT 1
          FROM public.user_roles ur
          JOIN public.roles r ON r.id = ur.role_id AND r.status = 'ACTIVE'
          WHERE ur.user_id = u.id
            AND ur.status = 'ACTIVE'
            AND ur.valid_from <= pg_catalog.now()
            AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
            AND (
              (r.scope_class = 'GLOBAL' AND ur.project_id IS NULL)
              OR (r.scope_class = 'PROJECT' AND ur.project_id = p_project_id)
            )
        )
        OR EXISTS (
          SELECT 1
          FROM public.user_scope_grants sg
          WHERE sg.user_id = u.id
            AND sg.status = 'ACTIVE'
            AND sg.scope_type = 'PROJECT'
            AND sg.scope_id = p_project_id
            AND sg.valid_from <= pg_catalog.now()
            AND (sg.valid_until IS NULL OR sg.valid_until > pg_catalog.now())
        )
      )
  );
$$;

-- T-14 Canonical Inspector Capacity Predicate (PO APPROVED Option A):
-- Count distinct APPROVED accounts with BOTH:
--   (1) an active Inspector role grant in p_project_id, AND
--   (2) at least one currently effective ACTIVE operational_role='inspector' assignment_members row in p_project_id.
CREATE OR REPLACE FUNCTION app_internal.count_qualifying_inspectors(p_project_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT pg_catalog.count(DISTINCT u.id)::integer
  FROM public.app_users u
  JOIN public.user_roles ur
    ON ur.user_id = u.id
    AND ur.project_id = p_project_id
    AND ur.status = 'ACTIVE'
    AND ur.valid_from <= pg_catalog.now()
    AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.now())
  JOIN public.roles r
    ON r.id = ur.role_id
    AND r.code = 'inspector'
    AND r.status = 'ACTIVE'
  JOIN public.assignment_members am
    ON am.user_id = u.id
    AND am.project_id = p_project_id
    AND am.operational_role = 'inspector'
    AND am.status = 'ACTIVE'
    AND am.valid_from <= pg_catalog.now()
    AND (am.valid_until IS NULL OR am.valid_until > pg_catalog.now())
  JOIN public.operational_assignments oa
    ON oa.id = am.assignment_id
    AND oa.project_id = p_project_id
    AND oa.status = 'PUBLISHED'
  WHERE u.account_status = 'APPROVED';
$$;

-- Canonical serial normalizer (T-16): NFC/trim/collapse internal whitespace, optional case folding
CREATE OR REPLACE FUNCTION app_internal.normalize_serial(
  p_serial_raw text,
  p_case_insensitive boolean DEFAULT true
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_clean text;
BEGIN
  IF p_serial_raw IS NULL THEN
    RETURN NULL;
  END IF;
  -- Reject ASCII control characters
  IF p_serial_raw ~ '[[:cntrl:]]' THEN
    RETURN NULL;
  END IF;
  v_clean := pg_catalog.btrim(pg_catalog.regexp_replace(p_serial_raw, '[[:space:]]+', ' ', 'g'));
  IF v_clean = '' THEN
    RETURN NULL;
  END IF;
  IF p_case_insensitive THEN
    v_clean := pg_catalog.upper(v_clean);
  END IF;
  RETURN v_clean;
END;
$$;

ALTER FUNCTION app_internal.has_project_access(uuid) OWNER TO app_cmd_definer;
ALTER FUNCTION app_internal.count_qualifying_inspectors(uuid) OWNER TO app_cmd_definer;
ALTER FUNCTION app_internal.normalize_serial(text, boolean) OWNER TO app_cmd_definer;

REVOKE ALL ON FUNCTION app_internal.has_project_access(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_internal.count_qualifying_inspectors(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_internal.normalize_serial(text, boolean) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION app_internal.has_project_access(uuid) TO authenticated;
REVOKE CREATE ON SCHEMA app_internal FROM app_cmd_definer;

-- ===========================================================================
-- 6. BROWSER `authenticated` SELECT RLS POLICIES (Deny-by-default scoped reads)
-- ===========================================================================

CREATE POLICY projects_select_scoped ON public.projects
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(id));

CREATE POLICY project_capacity_select_scoped ON public.project_capacity_settings
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY locations_select_scoped ON public.locations
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY sessions_select_scoped ON public.sessions
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY teams_select_scoped ON public.teams
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY operational_assignments_select_scoped ON public.operational_assignments
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY assignment_members_select_scoped ON public.assignment_members
  FOR SELECT TO authenticated
  USING (
    user_id = app_internal.current_app_user_id()
    OR app_internal.has_project_access(project_id)
  );

CREATE POLICY target_plans_select_scoped ON public.target_plans
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY target_allocations_select_scoped ON public.target_allocations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.target_plans tp
      WHERE tp.id = target_plan_id AND app_internal.has_project_access(tp.project_id)
    )
  );

-- Instruments: approved users see ACTIVE/INACTIVE catalog; instrument.manage sees DRAFT as well
CREATE POLICY instruments_select_authorized ON public.instruments
  FOR SELECT TO authenticated
  USING (
    app_internal.has_global_permission('instrument.manage')
    OR (
      status IN ('ACTIVE', 'INACTIVE')
      AND EXISTS (
        SELECT 1 FROM public.app_users u
        WHERE u.id = app_internal.current_app_user_id() AND u.account_status = 'APPROVED'
      )
    )
  );

CREATE POLICY instrument_versions_select_authorized ON public.instrument_versions
  FOR SELECT TO authenticated
  USING (
    app_internal.has_global_permission('instrument.manage')
    OR (
      status IN ('PUBLISHED', 'RETIRED')
      AND EXISTS (
        SELECT 1 FROM public.app_users u
        WHERE u.id = app_internal.current_app_user_id() AND u.account_status = 'APPROVED'
      )
    )
  );

CREATE POLICY checklist_sections_select_authorized ON public.checklist_sections
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.instrument_versions iv
      WHERE iv.id = instrument_version_id
        AND (
          app_internal.has_global_permission('instrument.manage')
          OR iv.status IN ('PUBLISHED', 'RETIRED')
        )
    )
  );

CREATE POLICY checklist_items_select_authorized ON public.checklist_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.checklist_sections cs
      JOIN public.instrument_versions iv ON iv.id = cs.instrument_version_id
      WHERE cs.id = section_id
        AND (
          app_internal.has_global_permission('instrument.manage')
          OR iv.status IN ('PUBLISHED', 'RETIRED')
        )
    )
  );

CREATE POLICY specification_fields_select_authorized ON public.specification_fields
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.instrument_versions iv
      WHERE iv.id = instrument_version_id
        AND (
          app_internal.has_global_permission('instrument.manage')
          OR iv.status IN ('PUBLISHED', 'RETIRED')
        )
    )
  );

CREATE POLICY evidence_slot_definitions_select_authorized ON public.evidence_slot_definitions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.instrument_versions iv
      WHERE iv.id = instrument_version_id
        AND (
          app_internal.has_global_permission('instrument.manage')
          OR iv.status IN ('PUBLISHED', 'RETIRED')
        )
    )
  );

CREATE POLICY instrument_version_publications_select_authorized ON public.instrument_version_publications
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.app_users u
      WHERE u.id = app_internal.current_app_user_id() AND u.account_status = 'APPROVED'
    )
  );

-- T-16: Canonical units visible ONLY via authorized unit_project_associations (never global unscoped read)
CREATE POLICY units_select_via_project_association ON public.units
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.unit_project_associations upa
      WHERE upa.unit_id = id AND app_internal.has_project_access(upa.project_id)
    )
  );

CREATE POLICY unit_project_associations_select_scoped ON public.unit_project_associations
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(project_id));

CREATE POLICY unit_identity_conflicts_select_scoped ON public.unit_identity_conflicts
  FOR SELECT TO authenticated
  USING (app_internal.has_project_access(proposed_project_id));
