-- Migration: 20261127120000_i2_fix_capacity_count_clock_timestamp.sql
-- Scope: Fix T-14 concurrent capacity check under-counting when FOR UPDATE waiters start
--        milliseconds apart (`pg_catalog.now()` is fixed at transaction_timestamp(), so an
--        earlier-started waiter could miss a later-started winner's committed valid_from).
--        Switching count_qualifying_inspectors to VOLATILE + clock_timestamp() ensures every
--        committed row is counted strictly in serialization order. Never alters migrations 1-15.

GRANT CREATE ON SCHEMA app_internal TO app_cmd_definer;

CREATE OR REPLACE FUNCTION app_internal.count_qualifying_inspectors(p_project_id uuid)
RETURNS integer
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT pg_catalog.count(DISTINCT u.id)::integer
  FROM public.app_users u
  JOIN public.user_roles ur
    ON ur.user_id = u.id
    AND ur.project_id = p_project_id
    AND ur.status = 'ACTIVE'
    AND ur.valid_from <= pg_catalog.clock_timestamp()
    AND (ur.valid_until IS NULL OR ur.valid_until > pg_catalog.clock_timestamp())
  JOIN public.roles r
    ON r.id = ur.role_id
    AND r.code = 'inspector'
    AND r.status = 'ACTIVE'
  JOIN public.assignment_members am
    ON am.user_id = u.id
    AND am.project_id = p_project_id
    AND am.operational_role = 'inspector'
    AND am.status = 'ACTIVE'
    AND am.valid_from <= pg_catalog.clock_timestamp()
    AND (am.valid_until IS NULL OR am.valid_until > pg_catalog.clock_timestamp())
  JOIN public.operational_assignments oa
    ON oa.id = am.assignment_id
    AND oa.project_id = p_project_id
    AND oa.status = 'PUBLISHED'
  WHERE u.account_status = 'APPROVED';
$$;

ALTER FUNCTION app_internal.count_qualifying_inspectors(uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.count_qualifying_inspectors(uuid) FROM PUBLIC, anon, authenticated;
REVOKE CREATE ON SCHEMA app_internal FROM app_cmd_definer;
