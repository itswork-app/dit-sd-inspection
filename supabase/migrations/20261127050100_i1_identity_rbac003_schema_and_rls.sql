-- Migration: 20261127050100_i1_identity_rbac003_schema_and_rls.sql
-- Scope: I1 Identity & RBAC-003 physical tables (8 canonical tables),
--        canonical role/permission catalog seed, internal RLS helpers, and
--        deny-by-default RLS policies (zero browser direct DML).
-- Authority: Physical Schema v1.0.0, RLS Catalogue v1.0.0,
--            Canonical Permission Registry v1.0.0, RBAC-003.

-- ---------------------------------------------------------------------------
-- 1. app_users (L15)
-- ---------------------------------------------------------------------------
CREATE TABLE public.app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
  display_name text NOT NULL CHECK (char_length(trim(display_name)) BETWEEN 2 AND 120),
  account_status text NOT NULL DEFAULT 'PENDING'
    CHECK (account_status IN ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', 'DISABLED')),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_app_users_status ON public.app_users (account_status, id);

-- ---------------------------------------------------------------------------
-- 2. account_requests (L100 — RBAC-003 separated request history)
-- ---------------------------------------------------------------------------
CREATE TABLE public.account_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  requested_display_name text NOT NULL CHECK (char_length(trim(requested_display_name)) BETWEEN 2 AND 120),
  request_note text NULL CHECK (request_note IS NULL OR char_length(trim(request_note)) <= 500),
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz NULL
);

CREATE UNIQUE INDEX uq_account_requests_one_pending_per_user
  ON public.account_requests (user_id)
  WHERE status = 'PENDING';

CREATE INDEX idx_account_requests_user ON public.account_requests (user_id, requested_at DESC);
CREATE INDEX idx_account_requests_status ON public.account_requests (status, requested_at ASC);

-- ---------------------------------------------------------------------------
-- 3. account_decisions (L110 — RBAC-003 append-only decision history)
-- ---------------------------------------------------------------------------
CREATE TABLE public.account_decisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NULL REFERENCES public.account_requests(id) ON DELETE RESTRICT,
  target_user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  actor_user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  decision text NOT NULL
    CHECK (decision IN ('APPROVE', 'REJECT', 'SUSPEND', 'DISABLE', 'REINSTATE')),
  rejection_category text NULL
    CHECK (
      rejection_category IS NULL OR rejection_category IN (
        'UNVERIFIED_IDENTITY',
        'OUT_OF_SCOPE_PERSONNEL',
        'DUPLICATE_ACCOUNT',
        'INCOMPLETE_INFORMATION',
        'POLICY_RESTRICTION'
      )
    ),
  reason text NOT NULL CHECK (char_length(trim(reason)) BETWEEN 3 AND 1000),
  decided_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_account_decisions_sod CHECK (actor_user_id <> target_user_id),
  CONSTRAINT chk_account_decisions_reject_category CHECK (
    (decision = 'REJECT' AND rejection_category IS NOT NULL)
    OR (decision <> 'REJECT' AND rejection_category IS NULL)
  )
);

CREATE UNIQUE INDEX uq_account_decisions_one_per_request
  ON public.account_decisions (request_id)
  WHERE request_id IS NOT NULL;

CREATE INDEX idx_account_decisions_target ON public.account_decisions (target_user_id, decided_at DESC);

CREATE TRIGGER trg_account_decisions_append_only
  BEFORE UPDATE OR DELETE ON public.account_decisions
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

-- ---------------------------------------------------------------------------
-- 4. roles, permissions, role_permissions (L18 — read-only at runtime)
-- ---------------------------------------------------------------------------
CREATE TABLE public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[a-z][a-z0-9_]{1,63}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 100),
  scope_class text NOT NULL CHECK (scope_class IN ('GLOBAL', 'PROJECT')),
  is_system boolean NOT NULL DEFAULT true,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[a-z][a-z0-9_.]{2,63}$'),
  scope_class text NOT NULL,
  description text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.role_permissions (
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE RESTRICT,
  PRIMARY KEY (role_id, permission_id)
);

-- ---------------------------------------------------------------------------
-- 5. user_roles (L16 — explicit global/project role grants, soft revoke)
-- ---------------------------------------------------------------------------
CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  project_id uuid NULL,
  valid_from timestamptz NOT NULL DEFAULT now(),
  valid_until timestamptz NULL,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
  granted_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  reason text NOT NULL CHECK (char_length(trim(reason)) BETWEEN 3 AND 500),
  revoked_at timestamptz NULL,
  revoked_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  revoke_reason text NULL CHECK (revoke_reason IS NULL OR char_length(trim(revoke_reason)) BETWEEN 3 AND 500),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_user_roles_valid_interval CHECK (valid_until IS NULL OR valid_until > valid_from),
  CONSTRAINT chk_user_roles_no_self_grant CHECK (granted_by <> user_id),
  CONSTRAINT chk_user_roles_no_self_revoke CHECK (revoked_by IS NULL OR revoked_by <> user_id)
);

CREATE INDEX idx_user_roles_user_status ON public.user_roles (user_id, status, id);
CREATE INDEX idx_user_roles_role_status ON public.user_roles (role_id, status, id);
CREATE UNIQUE INDEX uq_user_roles_active_global
  ON public.user_roles (user_id, role_id)
  WHERE status = 'ACTIVE' AND project_id IS NULL;
CREATE UNIQUE INDEX uq_user_roles_active_project
  ON public.user_roles (user_id, role_id, project_id)
  WHERE status = 'ACTIVE' AND project_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. user_scope_grants (L17 — explicit non-inheriting operational scopes)
-- ---------------------------------------------------------------------------
CREATE TABLE public.user_scope_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  scope_type text NOT NULL
    CHECK (scope_type IN ('PROJECT', 'SESSION', 'LOCATION', 'INSTRUMENT', 'TEAM', 'ASSIGNMENT')),
  scope_id uuid NOT NULL,
  valid_from timestamptz NOT NULL DEFAULT now(),
  valid_until timestamptz NULL,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
  granted_by uuid NOT NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  reason text NOT NULL CHECK (char_length(trim(reason)) BETWEEN 3 AND 500),
  revoked_at timestamptz NULL,
  revoked_by uuid NULL REFERENCES public.app_users(id) ON DELETE RESTRICT,
  revoke_reason text NULL CHECK (revoke_reason IS NULL OR char_length(trim(revoke_reason)) BETWEEN 3 AND 500),
  row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_user_scope_grants_valid_interval CHECK (valid_until IS NULL OR valid_until > valid_from),
  CONSTRAINT chk_user_scope_grants_no_self_grant CHECK (granted_by <> user_id),
  CONSTRAINT chk_user_scope_grants_no_self_revoke CHECK (revoked_by IS NULL OR revoked_by <> user_id)
);

CREATE INDEX idx_user_scope_grants_user_status ON public.user_scope_grants (user_id, status, scope_type, scope_id);
CREATE UNIQUE INDEX uq_user_scope_grants_active
  ON public.user_scope_grants (user_id, scope_type, scope_id)
  WHERE status = 'ACTIVE';

-- ---------------------------------------------------------------------------
-- 7. Canonical Role & Permission Catalog Seed (Permission Registry v1.0.0)
--    Excludes retired legacy aliases and PO-excluded CMD-045..048 permissions.
-- ---------------------------------------------------------------------------
INSERT INTO public.roles (code, name, scope_class, is_system, status) VALUES
  ('super_admin', 'Super Admin', 'GLOBAL', true, 'ACTIVE'),
  ('admin', 'Admin', 'PROJECT', true, 'ACTIVE'),
  ('korlap', 'Koordinator Lapangan (Korlap)', 'PROJECT', true, 'ACTIVE'),
  ('reviewer', 'Reviewer', 'PROJECT', true, 'ACTIVE'),
  ('inspector', 'Inspector', 'PROJECT', true, 'ACTIVE'),
  ('print_officer', 'Print Officer', 'PROJECT', true, 'ACTIVE');

INSERT INTO public.permissions (code, scope_class, description) VALUES
  ('account.request', 'SELF', 'Submit own pending access request'),
  ('account.approve', 'GLOBAL_IDENTITY', 'Approve, reject, suspend, disable, or reinstate application accounts'),
  ('role.manage', 'GLOBAL_IDENTITY', 'Grant or revoke roles within grantor delegation ceiling'),
  ('scope.manage', 'RESOURCE_SCOPE', 'Grant or revoke explicit non-inheriting operational scopes'),
  ('project.manage', 'PROJECT', 'Create or update project metadata'),
  ('project.close', 'PROJECT', 'Final explicit project closure (T-06)'),
  ('session.manage', 'PROJECT_SESSION', 'Create or update session configuration (T-07)'),
  ('session.transition', 'PROJECT_SESSION', 'Transition session lifecycle within role ceiling'),
  ('assignment.manage', 'PROJECT_SESSION_ASSIGNMENT', 'Publish assignments and manage team rosters'),
  ('capacity.manage', 'PROJECT_CAPACITY', 'Change combined Inspector capacity cap 1..100 (T-14)'),
  ('target.manage', 'PROJECT_SESSION', 'Create, edit, or publish session target plans'),
  ('instrument.manage', 'GLOBAL_CATALOG', 'Create instruments and edit draft definitions (CFG-001)'),
  ('instrument.publish', 'GLOBAL_CATALOG', 'Publish immutable instrument versions (T-17)'),
  ('instrument.deactivate', 'GLOBAL_CATALOG', 'Deactivate instruments for future selection (T-17)'),
  ('unit.register', 'GLOBAL_UNIT_IDENTITY', 'Register canonical physical units (T-16)'),
  ('unit.associate', 'PROJECT_UNIT_ASSOCIATION', 'Associate canonical units to a project'),
  ('unit.association.end', 'PROJECT_UNIT_ASSOCIATION', 'End or revoke project unit association'),
  ('unit.identity.resolve', 'CONFLICT_REVIEW', 'Resolve same-instrument serial identity conflicts'),
  ('inspection.claim', 'PROJECT_SESSION_ASSIGNMENT_UNIT', 'Claim or release canonical units'),
  ('inspection.edit', 'INSPECTION_OWNER', 'Save own claimed inspection draft'),
  ('inspection.submit', 'INSPECTION_OWNER', 'Submit complete immutable inspection revision'),
  ('inspection.review', 'ASSIGNED_REVIEW', 'Return or approve assigned submitted revision'),
  ('inspection.reopen', 'PROJECT_INSPECTION', 'Privileged reasoned reopen of approved inspection'),
  ('inspection.abort.request', 'INSPECTION_OWNER', 'Request packed-unit ABORT after Reviewer return (SES-001)'),
  ('inspection.abort.decide', 'PROJECT_SESSION', 'Approve or reject packed-unit ABORT request (SES-001)'),
  ('evidence.upload', 'INSPECTION_EVIDENCE', 'Create upload intent and finalize private evidence'),
  ('evidence.read', 'INSPECTION_HISTORY', 'Read evidence within authorized scope'),
  ('evidence.export', 'PROJECT_EVIDENCE_EXPORT', 'Export evidence package (T-10 gated)'),
  ('sync.apply', 'SELF_DEVICE_ASSIGNMENT', 'Apply bounded offline draft sync batch (T-09)'),
  ('document.generate', 'RESOURCE_DOCUMENT', 'Generate approved PDF/BA/attendance documents'),
  ('document.print', 'RESOURCE_DOCUMENT', 'Record individual current-version print/reprint (DOC-003)'),
  ('document.print.batch', 'RESOURCE_DOCUMENT_BATCH', 'Orchestrate bounded batch print (T-13)'),
  ('attendance.upload', 'PROJECT_LOCATION_ATTENDANCE', 'Upload or replace attendance evidence (T-08)'),
  ('attendance.verify', 'PROJECT_LOCATION_ATTENDANCE', 'Verify attendance within assigned location (T-08)'),
  ('report.read', 'PROJECT_REPORT', 'Read scoped actual and target reports'),
  ('audit.read', 'AUDIT_SCOPE', 'Read scoped audit events'),
  ('audit.export', 'AUDIT_EXPORT_SCOPE', 'Export audit events (gated OFF until written T-10 approval)'),
  ('notification.read', 'SELF', 'Read and mark-read own notifications (POQ-03)'),
  ('notification.policy.manage', 'NOTIFICATION_CONFIG_SCOPE', 'Publish scoped immutable notification policy versions');

-- Canonical Role -> Permission seed (Permission Registry v1.0.0 §9.2)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON (
  (r.code = 'super_admin' AND p.code IN (
    'account.request', 'account.approve', 'role.manage', 'scope.manage',
    'project.manage', 'project.close', 'session.manage', 'session.transition',
    'assignment.manage', 'capacity.manage', 'target.manage',
    'instrument.manage', 'instrument.publish', 'instrument.deactivate',
    'unit.register', 'unit.associate', 'unit.association.end', 'unit.identity.resolve',
    'inspection.claim', 'inspection.reopen', 'inspection.abort.decide',
    'evidence.read', 'document.generate', 'attendance.upload',
    'report.read', 'audit.read', 'notification.read', 'notification.policy.manage'
  ))
  OR (r.code = 'admin' AND p.code IN (
    'account.request', 'scope.manage', 'target.manage',
    'unit.register', 'unit.associate', 'unit.association.end', 'unit.identity.resolve',
    'inspection.claim', 'inspection.abort.decide', 'evidence.read',
    'document.generate', 'attendance.upload', 'report.read', 'notification.read'
  ))
  OR (r.code = 'korlap' AND p.code IN (
    'account.request', 'session.transition', 'unit.register', 'unit.associate',
    'inspection.claim', 'inspection.abort.decide', 'evidence.read',
    'document.generate', 'attendance.upload', 'attendance.verify',
    'report.read', 'notification.read'
  ))
  OR (r.code = 'reviewer' AND p.code IN (
    'account.request', 'inspection.review', 'evidence.read',
    'document.generate', 'report.read', 'notification.read'
  ))
  OR (r.code = 'inspector' AND p.code IN (
    'account.request', 'unit.register', 'inspection.claim', 'inspection.edit',
    'inspection.submit', 'inspection.abort.request', 'evidence.upload',
    'evidence.read', 'sync.apply', 'report.read', 'notification.read'
  ))
  OR (r.code = 'print_officer' AND p.code IN (
    'account.request', 'document.generate', 'document.print',
    'document.print.batch', 'report.read', 'notification.read'
  ))
);

-- ---------------------------------------------------------------------------
-- 8. Row Level Security & Least-Privilege Table Grants
-- ---------------------------------------------------------------------------
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users FORCE ROW LEVEL SECURITY;
ALTER TABLE public.account_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE public.account_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_decisions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_scope_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_scope_grants FORCE ROW LEVEL SECURITY;

-- Deny all direct DML from PUBLIC, anon, authenticated (T-18 invariant)
REVOKE ALL ON TABLE
  public.app_users,
  public.account_requests,
  public.account_decisions,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.user_roles,
  public.user_scope_grants
FROM PUBLIC, anon, authenticated;

-- Browser authenticated role gets SELECT only (governed strictly by RLS below)
GRANT SELECT ON TABLE
  public.app_users,
  public.account_requests,
  public.account_decisions,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.user_roles,
  public.user_scope_grants,
  public.audit_events
TO authenticated;

-- Narrow minimum privileges for dedicated NOLOGIN command owner (app_cmd_definer)
GRANT SELECT, INSERT, UPDATE ON TABLE
  public.app_users,
  public.account_requests,
  public.user_roles,
  public.user_scope_grants
TO app_cmd_definer;

-- Append-only: INSERT + SELECT only for account_decisions (no UPDATE/DELETE)
GRANT SELECT, INSERT ON TABLE public.account_decisions TO app_cmd_definer;

-- Read-only L18 catalog for app_cmd_definer (no INSERT/UPDATE/DELETE at runtime)
GRANT SELECT ON TABLE
  public.roles,
  public.permissions,
  public.role_permissions
TO app_cmd_definer;

-- Explicit RLS policies for app_cmd_definer (no BYPASSRLS needed!)
CREATE POLICY app_users_cmd_all ON public.app_users FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY app_users_cmd_ins ON public.app_users FOR INSERT TO app_cmd_definer WITH CHECK (true);
CREATE POLICY app_users_cmd_upd ON public.app_users FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true);

CREATE POLICY account_requests_cmd_sel ON public.account_requests FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY account_requests_cmd_ins ON public.account_requests FOR INSERT TO app_cmd_definer WITH CHECK (true);
CREATE POLICY account_requests_cmd_upd ON public.account_requests FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true);

CREATE POLICY account_decisions_cmd_sel ON public.account_decisions FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY account_decisions_cmd_ins ON public.account_decisions FOR INSERT TO app_cmd_definer WITH CHECK (true);

CREATE POLICY roles_cmd_sel ON public.roles FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY permissions_cmd_sel ON public.permissions FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY role_permissions_cmd_sel ON public.role_permissions FOR SELECT TO app_cmd_definer USING (true);

CREATE POLICY user_roles_cmd_sel ON public.user_roles FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY user_roles_cmd_ins ON public.user_roles FOR INSERT TO app_cmd_definer WITH CHECK (true);
CREATE POLICY user_roles_cmd_upd ON public.user_roles FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true);

CREATE POLICY user_scope_grants_cmd_sel ON public.user_scope_grants FOR SELECT TO app_cmd_definer USING (true);
CREATE POLICY user_scope_grants_cmd_ins ON public.user_scope_grants FOR INSERT TO app_cmd_definer WITH CHECK (true);
CREATE POLICY user_scope_grants_cmd_upd ON public.user_scope_grants FOR UPDATE TO app_cmd_definer USING (true) WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- 9. Internal RLS Helper Functions (F3 — owned by app_cmd_definer, non-recursive)
--    Always derive caller strictly from auth.uid(); never accept caller user ID.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_internal.current_app_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.id
  FROM public.app_users u
  WHERE u.auth_user_id = app_internal.current_auth_uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION app_internal.has_global_permission(p_permission_code text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_users u
    JOIN public.user_roles ur
      ON ur.user_id = u.id
      AND ur.status = 'ACTIVE'
      AND ur.project_id IS NULL
      AND ur.valid_from <= now()
      AND (ur.valid_until IS NULL OR ur.valid_until > now())
    JOIN public.roles r
      ON r.id = ur.role_id
      AND r.status = 'ACTIVE'
      AND r.scope_class = 'GLOBAL'
    JOIN public.role_permissions rp ON rp.role_id = r.id
    JOIN public.permissions p ON p.id = rp.permission_id
    WHERE u.auth_user_id = app_internal.current_auth_uid()
      AND u.account_status = 'APPROVED'
      AND p.code = p_permission_code
  );
$$;

CREATE OR REPLACE FUNCTION app_internal.is_active_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_users u
    JOIN public.user_roles ur
      ON ur.user_id = u.id
      AND ur.status = 'ACTIVE'
      AND ur.project_id IS NULL
      AND ur.valid_from <= now()
      AND (ur.valid_until IS NULL OR ur.valid_until > now())
    JOIN public.roles r
      ON r.id = ur.role_id
      AND r.code = 'super_admin'
      AND r.status = 'ACTIVE'
    WHERE u.auth_user_id = app_internal.current_auth_uid()
      AND u.account_status = 'APPROVED'
  );
$$;

GRANT CREATE ON SCHEMA app_internal TO app_cmd_definer;
ALTER FUNCTION app_internal.current_app_user_id() OWNER TO app_cmd_definer;
ALTER FUNCTION app_internal.has_global_permission(text) OWNER TO app_cmd_definer;
ALTER FUNCTION app_internal.is_active_super_admin() OWNER TO app_cmd_definer;
REVOKE CREATE ON SCHEMA app_internal FROM app_cmd_definer;

REVOKE ALL ON FUNCTION app_internal.current_app_user_id() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_internal.has_global_permission(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_internal.is_active_super_admin() FROM PUBLIC, anon, authenticated;

-- Allow RLS predicates evaluated for `authenticated` to invoke internal read helpers.
-- Note: `app_internal` is NOT exposed in PostgREST schemas (`supabase/config.toml`).
GRANT USAGE ON SCHEMA app_internal TO authenticated;
GRANT EXECUTE ON FUNCTION app_internal.current_app_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION app_internal.has_global_permission(text) TO authenticated;
GRANT EXECUTE ON FUNCTION app_internal.is_active_super_admin() TO authenticated;

-- ---------------------------------------------------------------------------
-- 10. Browser `authenticated` SELECT RLS Policies (R-self / R-admin only)
-- ---------------------------------------------------------------------------
CREATE POLICY app_users_select_self_or_admin ON public.app_users
  FOR SELECT TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR app_internal.has_global_permission('account.approve')
    OR app_internal.has_global_permission('role.manage')
    OR app_internal.has_global_permission('scope.manage')
  );

CREATE POLICY account_requests_select_self_or_admin ON public.account_requests
  FOR SELECT TO authenticated
  USING (
    user_id = app_internal.current_app_user_id()
    OR app_internal.has_global_permission('account.approve')
  );

CREATE POLICY account_decisions_select_self_or_admin ON public.account_decisions
  FOR SELECT TO authenticated
  USING (
    target_user_id = app_internal.current_app_user_id()
    OR app_internal.has_global_permission('account.approve')
  );

CREATE POLICY roles_select_active_authenticated ON public.roles
  FOR SELECT TO authenticated
  USING (
    status = 'ACTIVE'
    OR app_internal.is_active_super_admin()
  );

CREATE POLICY permissions_select_admin ON public.permissions
  FOR SELECT TO authenticated
  USING (
    app_internal.is_active_super_admin()
    OR app_internal.has_global_permission('role.manage')
  );

CREATE POLICY role_permissions_select_admin ON public.role_permissions
  FOR SELECT TO authenticated
  USING (
    app_internal.is_active_super_admin()
    OR app_internal.has_global_permission('role.manage')
  );

CREATE POLICY user_roles_select_self_or_admin ON public.user_roles
  FOR SELECT TO authenticated
  USING (
    user_id = app_internal.current_app_user_id()
    OR app_internal.has_global_permission('role.manage')
    OR app_internal.has_global_permission('account.approve')
  );

CREATE POLICY user_scope_grants_select_self_or_admin ON public.user_scope_grants
  FOR SELECT TO authenticated
  USING (
    user_id = app_internal.current_app_user_id()
    OR app_internal.has_global_permission('scope.manage')
    OR app_internal.has_global_permission('account.approve')
  );

CREATE POLICY audit_events_select_authorized ON public.audit_events
  FOR SELECT TO authenticated
  USING (app_internal.has_global_permission('audit.read'));
