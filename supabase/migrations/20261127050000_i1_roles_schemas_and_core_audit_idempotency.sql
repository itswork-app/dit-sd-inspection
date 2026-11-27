-- Migration: 20261127050000_i1_roles_schemas_and_core_audit_idempotency.sql
-- Scope: I1/I2 Database Foundation — T-18 non-login roles, app_internal schema,
--        append-only audit_events (T-15), and L00 idempotency_records.
-- Authority: AGENTS.md v1.3.0 (G9-TECH FROZEN / G10 SYNTHETIC ACTIVE),
--            Physical Schema v1.0.0, Function Security v1.0.0, RLS Catalogue v1.0.0.

CREATE SCHEMA IF NOT EXISTS app_internal;
REVOKE ALL ON SCHEMA app_internal FROM PUBLIC;
REVOKE ALL ON SCHEMA app_internal FROM anon;
REVOKE ALL ON SCHEMA app_internal FROM authenticated;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'app_cmd_definer') THEN
    CREATE ROLE app_cmd_definer
      NOLOGIN
      NOSUPERUSER
      NOCREATEDB
      NOCREATEROLE
      NOREPLICATION
      NOBYPASSRLS
      NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'app_worker_definer') THEN
    CREATE ROLE app_worker_definer
      NOLOGIN
      NOSUPERUSER
      NOCREATEDB
      NOCREATEROLE
      NOREPLICATION
      NOBYPASSRLS
      NOINHERIT;
  END IF;

  -- PostgreSQL 16+ requires SET OPTION on target owner role for non-superuser migration roles (e.g., Supabase `postgres`)
  -- before `ALTER FUNCTION ... OWNER TO app_cmd_definer` can execute during migrations.
  EXECUTE format('GRANT app_cmd_definer TO %I WITH SET TRUE', current_user);
  EXECUTE format('GRANT app_worker_definer TO %I WITH SET TRUE', current_user);
END
$$;

GRANT USAGE ON SCHEMA public TO app_cmd_definer;
GRANT USAGE ON SCHEMA app_internal TO app_cmd_definer;
GRANT USAGE ON SCHEMA public TO app_worker_definer;
GRANT USAGE ON SCHEMA app_internal TO app_worker_definer;

-- Canonical verified JWT subject extractor for NOLOGIN SECURITY DEFINER functions.
-- Mirrors Supabase auth.uid() without requiring non-grantable USAGE on schema `auth`.
GRANT CREATE ON SCHEMA app_internal TO app_cmd_definer;

CREATE OR REPLACE FUNCTION app_internal.current_auth_uid()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_raw text;
BEGIN
  v_raw := coalesce(
    nullif(pg_catalog.current_setting('request.jwt.claim.sub', true), ''),
    (nullif(pg_catalog.current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  );
  IF v_raw IS NULL OR v_raw !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
    RETURN NULL;
  END IF;
  RETURN v_raw::uuid;
END;
$$;

ALTER FUNCTION app_internal.current_auth_uid() OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION app_internal.current_auth_uid() FROM PUBLIC, anon, authenticated;
REVOKE CREATE ON SCHEMA app_internal FROM app_cmd_definer;

-- Append-only immutability trigger function (F4)
CREATE OR REPLACE FUNCTION app_internal.prevent_append_only_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'Append-only table %.% does not allow %', TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP
    USING ERRCODE = '55000';
END;
$$;

REVOKE ALL ON FUNCTION app_internal.prevent_append_only_mutation() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Core Table: audit_events (T-15 / INS-016 append-only canonical audit log)
-- ---------------------------------------------------------------------------
CREATE TABLE public.audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL CHECK (char_length(trim(event_type)) BETWEEN 3 AND 128),
  actor_user_id uuid NULL,
  actor_auth_uid uuid NULL,
  command_id text NOT NULL CHECK (char_length(trim(command_id)) BETWEEN 3 AND 32),
  scope_type text NULL,
  scope_id uuid NULL,
  target_table text NOT NULL CHECK (char_length(trim(target_table)) BETWEEN 1 AND 64),
  target_id uuid NULL,
  idempotency_key_hash text NULL,
  correlation_id text NULL,
  outcome text NOT NULL CHECK (outcome IN ('SUCCESS', 'DENIED', 'CONFLICT', 'FAILED')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_events_created_at ON public.audit_events (created_at DESC, id DESC);
CREATE INDEX idx_audit_events_actor ON public.audit_events (actor_user_id, created_at DESC);
CREATE INDEX idx_audit_events_event_type ON public.audit_events (event_type, created_at DESC);
CREATE INDEX idx_audit_events_target ON public.audit_events (target_table, target_id, created_at DESC);

CREATE TRIGGER trg_audit_events_append_only
  BEFORE UPDATE OR DELETE ON public.audit_events
  FOR EACH ROW
  EXECUTE FUNCTION app_internal.prevent_append_only_mutation();

ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.audit_events FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.audit_events TO app_cmd_definer;
GRANT SELECT, INSERT ON TABLE public.audit_events TO app_worker_definer;

CREATE POLICY audit_events_cmd_insert ON public.audit_events
  FOR INSERT TO app_cmd_definer
  WITH CHECK (true);

CREATE POLICY audit_events_cmd_select ON public.audit_events
  FOR SELECT TO app_cmd_definer
  USING (true);

CREATE POLICY audit_events_worker_insert ON public.audit_events
  FOR INSERT TO app_worker_definer
  WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- Core Table: idempotency_records (L00 command idempotency arbitration)
-- ---------------------------------------------------------------------------
CREATE TABLE public.idempotency_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_auth_uid uuid NOT NULL,
  command_id text NOT NULL CHECK (char_length(trim(command_id)) BETWEEN 3 AND 32),
  resource_scope text NOT NULL CHECK (char_length(trim(resource_scope)) BETWEEN 1 AND 128),
  idempotency_key_hash text NOT NULL CHECK (char_length(idempotency_key_hash) = 64),
  request_hash text NOT NULL CHECK (char_length(request_hash) = 64),
  response_payload jsonb NOT NULL CHECK (jsonb_typeof(response_payload) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_idempotency_actor_cmd_scope_key
    UNIQUE (actor_auth_uid, command_id, resource_scope, idempotency_key_hash)
);

CREATE INDEX idx_idempotency_records_created_at ON public.idempotency_records (created_at DESC);

ALTER TABLE public.idempotency_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idempotency_records FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.idempotency_records FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.idempotency_records TO app_cmd_definer;
GRANT SELECT, INSERT ON TABLE public.idempotency_records TO app_worker_definer;

CREATE POLICY idempotency_records_cmd_select ON public.idempotency_records
  FOR SELECT TO app_cmd_definer
  USING (true);

CREATE POLICY idempotency_records_cmd_insert ON public.idempotency_records
  FOR INSERT TO app_cmd_definer
  WITH CHECK (true);

CREATE POLICY idempotency_records_worker_select ON public.idempotency_records
  FOR SELECT TO app_worker_definer
  USING (true);

CREATE POLICY idempotency_records_worker_insert ON public.idempotency_records
  FOR INSERT TO app_worker_definer
  WITH CHECK (true);
