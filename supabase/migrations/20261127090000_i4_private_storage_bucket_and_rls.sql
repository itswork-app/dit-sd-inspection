-- Migration: 20261127090000_i4_private_storage_bucket_and_rls.sql
-- Scope: Private Supabase Storage bucket (`inspection-private`), strict caller-JWT
--        `storage.objects` RLS policies (authorized intent-bound upload, project-scoped
--        read, zero UPDATE/DELETE), and audited artifact-access command helper.
-- Authority: AGENTS.md v1.3.0 §4 (Evidence storage is private; authorized access is
--            time-limited and audited; no service_role substitute for caller identity),
--            EVIDENCE-STORAGE-AND-MEDIA-LIFECYCLE.md, T-16, T-18.

-- 1. Provision private bucket (idempotent)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'inspection-private',
  'inspection-private',
  false,
  15728640,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Internal SECURITY DEFINER helpers for storage.objects RLS (owned by app_cmd_definer)
GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;

CREATE OR REPLACE FUNCTION app_internal.can_upload_private_object(p_object_key text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.evidence_assets ea
      WHERE ea.object_key = p_object_key
        AND ea.upload_status = 'INTENT_CREATED'
        AND ea.uploaded_by = app_internal.current_app_user_id()
    )
    OR EXISTS (
      SELECT 1
      FROM public.documents d
      WHERE d.object_key = p_object_key
        AND d.generated_by = app_internal.current_app_user_id()
    )
    OR EXISTS (
      SELECT 1
      FROM public.attendance_documents ad
      WHERE ad.object_key = p_object_key
        AND ad.uploaded_by = app_internal.current_app_user_id()
    );
$$;

CREATE OR REPLACE FUNCTION app_internal.can_read_private_object(p_object_key text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.evidence_assets ea
      JOIN public.inspections i ON i.id = ea.inspection_id
      WHERE ea.object_key = p_object_key
        AND app_internal.has_project_access(i.project_id)
    )
    OR EXISTS (
      SELECT 1
      FROM public.documents d
      WHERE d.object_key = p_object_key
        AND app_internal.has_project_access(d.project_id)
    )
    OR EXISTS (
      SELECT 1
      FROM public.attendance_documents ad
      JOIN public.attendance_records ar ON ar.id = ad.attendance_record_id
      WHERE ad.object_key = p_object_key
        AND app_internal.has_project_access(ar.project_id)
    );
$$;

ALTER FUNCTION app_internal.can_upload_private_object(text) OWNER TO app_cmd_definer;
ALTER FUNCTION app_internal.can_read_private_object(text) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.can_upload_private_object(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_internal.can_read_private_object(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_internal.can_upload_private_object(text) TO authenticated;
GRANT EXECUTE ON FUNCTION app_internal.can_read_private_object(text) TO authenticated;

-- 3. Narrow T-18 audited read-authorization wrapper for time-limited signed downloads
CREATE OR REPLACE FUNCTION public.cmd_authorize_artifact_download_v1(
  p_artifact_kind text,
  p_artifact_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_project_id uuid;
  v_object_key text;
  v_event_type text;
  v_target_table text;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_artifact_id IS NULL OR p_artifact_kind NOT IN ('EVIDENCE', 'DOCUMENT') THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  IF p_artifact_kind = 'EVIDENCE' THEN
    SELECT i.project_id, ea.object_key INTO v_project_id, v_object_key
    FROM public.evidence_assets ea
    JOIN public.inspections i ON i.id = ea.inspection_id
    WHERE ea.id = p_artifact_id AND ea.upload_status = 'FINALIZED';

    IF NOT FOUND THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
    END IF;
    IF NOT app_internal.actor_has_permission(v_actor_id, 'evidence.read', v_project_id) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
    v_event_type := 'evidence.accessed';
    v_target_table := 'evidence_assets';
  ELSE
    SELECT d.project_id, d.object_key INTO v_project_id, v_object_key
    FROM public.documents d
    WHERE d.id = p_artifact_id;

    IF NOT FOUND THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
    END IF;
    IF NOT (
      app_internal.actor_has_permission(v_actor_id, 'document.generate', v_project_id)
      OR app_internal.actor_has_permission(v_actor_id, 'document.print', v_project_id)
      OR app_internal.actor_has_permission(v_actor_id, 'report.read', v_project_id)
    ) THEN
      RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-ARTIFACT-DL', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
    END IF;
    v_event_type := 'document.accessed';
    v_target_table := 'documents';
  END IF;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    outcome, metadata
  ) VALUES (
    v_event_type, v_actor_id, v_auth_uid, 'CMD-ARTIFACT-DL',
    'PROJECT', v_project_id, v_target_table, p_artifact_id,
    'SUCCESS', pg_catalog.jsonb_build_object('artifact_kind', p_artifact_kind)
  );

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-ARTIFACT-DL',
    'status', 'OK',
    'object_key', v_object_key,
    'project_id', v_project_id,
    'server_time', pg_catalog.now()
  );
END;
$$;

ALTER FUNCTION public.cmd_authorize_artifact_download_v1(text, uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_authorize_artifact_download_v1(text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_authorize_artifact_download_v1(text, uuid) TO authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;

-- 4. Strict caller-JWT storage.objects RLS policies (no UPDATE/DELETE -> immutable originals!)
CREATE POLICY inspection_private_insert_intent_bound
  ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'inspection-private'
    AND app_internal.can_upload_private_object(name)
  );

CREATE POLICY inspection_private_select_project_scoped
  ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'inspection-private'
    AND app_internal.can_read_private_object(name)
  );
