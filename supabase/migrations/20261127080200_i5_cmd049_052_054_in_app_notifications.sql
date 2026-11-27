-- Migration: 20261127080200_i5_cmd049_052_054_in_app_notifications.sql
-- Scope: T-18 Option A narrow SECURITY DEFINER wrappers for In-App Notifications:
--        CMD-049 (list-own-notifications), CMD-050 (mark-notification-read; POQ-03),
--        CMD-051 (publish-notification-policy; POQ-02),
--        CMD-052 (internal worker fanout of immutable POQ-01 recipient snapshot),
--        CMD-054 (internal SLA escalation evaluation; ELAPSED_UTC default).
--        External email/push delivery adapters (CMD-053 / INT-NOTIF-001) remain
--        STRICTLY DISABLED until written T-10 and T-12 approvals!
-- Authority: AGENTS.md v1.3.0, NLA-001 v1.0.0, POQ-01..03, NLA-MVP-001, T-18.

GRANT CREATE ON SCHEMA app_internal, public TO app_cmd_definer;
GRANT CREATE ON SCHEMA app_internal TO app_worker_definer;

-- ===========================================================================
-- CMD-049: list-own-notifications (notification.read; self-only; omits dormant dismissed_at)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_list_own_notifications_v1(
  p_unread_only boolean DEFAULT false,
  p_limit integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_lim integer;
  v_items jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-049', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-049', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_lim := least(greatest(coalesce(p_limit, 50), 1), 100);

  -- POQ-03: dismissed_at is intentionally omitted from projection!
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', n.id,
    'event_type', n.event_type,
    'priority', n.priority,
    'title_key', n.title_key,
    'body_key', n.body_key,
    'safe_payload', n.safe_payload,
    'project_id', n.project_id,
    'session_id', n.session_id,
    'created_at', n.created_at,
    'read_at', n.read_at
  ) ORDER BY n.created_at DESC, n.id DESC), '[]'::jsonb)
  INTO v_items
  FROM (
    SELECT * FROM public.notifications
    WHERE recipient_user_id = v_actor_id
      AND (NOT coalesce(p_unread_only, false) OR read_at IS NULL)
    ORDER BY created_at DESC, id DESC
    LIMIT v_lim
  ) n;

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-049',
    'status', 'OK',
    'notifications', v_items,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- CMD-050: mark-notification-read (POQ-03: recipient-owned set-once read_at ONLY)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_mark_notification_read_v1(
  p_notification_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_notif public.notifications%ROWTYPE;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-050', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-050', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  IF p_notification_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-050', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  -- Non-enumerating recipient-self predicate
  SELECT * INTO v_notif FROM public.notifications
  WHERE id = p_notification_id AND recipient_user_id = v_actor_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-050', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  -- Set-once read_at; emit notification.read audit event ONLY on first transition
  IF v_notif.read_at IS NULL THEN
    UPDATE public.notifications
    SET read_at = pg_catalog.now()
    WHERE id = v_notif.id AND read_at IS NULL
    RETURNING * INTO v_notif;

    INSERT INTO public.audit_events (
      event_type, actor_user_id, actor_auth_uid, command_id,
      scope_type, scope_id, target_table, target_id,
      outcome, metadata
    ) VALUES (
      'notification.read', v_actor_id, v_auth_uid, 'CMD-050',
      'SELF', v_actor_id, 'notifications', v_notif.id,
      'SUCCESS', pg_catalog.jsonb_build_object('read_at', v_notif.read_at)
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-050',
    'status', 'MARKED_READ',
    'notification_id', v_notif.id,
    'read_at', v_notif.read_at,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- CMD-051: publish-notification-policy (notification.policy.manage; POQ-02 ELAPSED_UTC default)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.cmd_publish_notification_policy_v1(
  p_idempotency_key text,
  p_policy_key text,
  p_scope_type text,
  p_scope_id uuid DEFAULT NULL,
  p_sla_mode text DEFAULT 'ELAPSED_UTC',
  p_policy_document jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_actor_id uuid;
  v_key text;
  v_policy_hash text;
  v_req_hash text;
  v_idem jsonb;
  v_next_ver integer;
  v_pol public.notification_policy_versions%ROWTYPE;
  v_response jsonb;
BEGIN
  v_auth_uid := app_internal.current_auth_uid();
  IF v_auth_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-051', 'status', 'UNAUTHENTICATED', 'server_time', pg_catalog.now());
  END IF;

  SELECT id INTO v_actor_id FROM public.app_users WHERE auth_user_id = v_auth_uid AND account_status = 'APPROVED';
  IF v_actor_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-051', 'status', 'ACCOUNT_NOT_ELIGIBLE', 'server_time', pg_catalog.now());
  END IF;

  v_key := pg_catalog.upper(pg_catalog.btrim(coalesce(p_policy_key, '')));
  IF v_key !~ '^[A-Z0-9][A-Z0-9_.-]{2,63}$'
     OR p_scope_type NOT IN ('GLOBAL', 'PROJECT')
     OR (p_scope_type = 'GLOBAL' AND p_scope_id IS NOT NULL)
     OR (p_scope_type = 'PROJECT' AND p_scope_id IS NULL)
     OR coalesce(p_sla_mode, 'ELAPSED_UTC') NOT IN ('ELAPSED_UTC', 'BUSINESS_TIME')
     OR p_policy_document IS NULL OR pg_catalog.jsonb_typeof(p_policy_document) <> 'object'
  THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-051', 'status', 'VALIDATION_FAILED', 'server_time', pg_catalog.now());
  END IF;

  v_policy_hash := app_internal.sha256_hex(pg_catalog.jsonb_build_object(
    'policy_key', v_key, 'scope_type', p_scope_type, 'scope_id', p_scope_id,
    'sla_mode', coalesce(p_sla_mode, 'ELAPSED_UTC'), 'doc', p_policy_document
  )::text);
  v_req_hash := app_internal.sha256_hex(v_policy_hash);

  v_idem := app_internal.check_idempotency(v_auth_uid, 'CMD-051', 'policy:' || v_key || ':' || p_scope_type, p_idempotency_key, v_req_hash);
  IF v_idem->>'status' = 'ERROR' THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-051', 'status', v_idem->>'error_code', 'server_time', pg_catalog.now());
  ELSIF v_idem->>'status' = 'REPLAY' THEN
    RETURN v_idem->'response';
  END IF;

  IF NOT app_internal.actor_has_permission(v_actor_id, 'notification.policy.manage', p_scope_id) THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-051', 'status', 'PERMISSION_DENIED', 'server_time', pg_catalog.now());
  END IF;

  SELECT coalesce(pg_catalog.max(version_no), 0) + 1 INTO v_next_ver
  FROM public.notification_policy_versions
  WHERE policy_key = v_key AND scope_type = p_scope_type;

  INSERT INTO public.notification_policy_versions (
    policy_key, version_no, scope_type, scope_id, sla_mode,
    policy_document, policy_hash, status, published_by
  ) VALUES (
    v_key, v_next_ver, p_scope_type, p_scope_id, coalesce(p_sla_mode, 'ELAPSED_UTC'),
    p_policy_document, v_policy_hash, 'PUBLISHED', v_actor_id
  )
  RETURNING * INTO v_pol;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    idempotency_key_hash, outcome, metadata
  ) VALUES (
    'notification.policy_published', v_actor_id, v_auth_uid, 'CMD-051',
    p_scope_type, p_scope_id, 'notification_policy_versions', v_pol.id,
    v_idem->>'key_hash', 'SUCCESS',
    pg_catalog.jsonb_build_object('policy_key', v_pol.policy_key, 'version_no', v_pol.version_no, 'sla_mode', v_pol.sla_mode)
  );

  v_response := pg_catalog.jsonb_build_object(
    'command_id', 'CMD-051',
    'status', 'PUBLISHED',
    'policy_version_id', v_pol.id,
    'version_no', v_pol.version_no,
    'sla_mode', v_pol.sla_mode,
    'policy_hash', v_pol.policy_hash,
    'server_time', pg_catalog.now()
  );

  INSERT INTO public.idempotency_records (
    actor_auth_uid, command_id, resource_scope, idempotency_key_hash, request_hash, response_payload
  ) VALUES (
    v_auth_uid, 'CMD-051', 'policy:' || v_key || ':' || p_scope_type, v_idem->>'key_hash', v_req_hash, v_response
  );

  RETURN v_response;
END;
$$;

-- ===========================================================================
-- CMD-052 (Internal Worker): fanout-notification-outbox
-- Owned by app_worker_definer; NOT browser callable (REVOKED from PUBLIC/anon/authenticated).
-- Consumes immutable POQ-01 notification_outbox_recipients; suppresses inactive users,
-- NEVER widens audience; materializes IN_APP notifications + deliveries only (no external adapters).
-- ===========================================================================
CREATE OR REPLACE FUNCTION app_internal.worker_fanout_notification_outbox_v1(
  p_outbox_id uuid,
  p_lease_owner text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_outbox public.notification_outbox%ROWTYPE;
  v_cand record;
  v_notif public.notifications%ROWTYPE;
  v_created integer := 0;
  v_suppressed integer := 0;
BEGIN
  SELECT * INTO v_outbox FROM public.notification_outbox
  WHERE id = p_outbox_id AND status IN ('PENDING', 'RETRY_WAIT')
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-052', 'status', 'NOT_FOUND_OR_LOCKED', 'server_time', pg_catalog.now());
  END IF;

  UPDATE public.notification_outbox
  SET status = 'PROCESSING',
      lease_owner = p_lease_owner,
      lease_generation = lease_generation + 1,
      lease_expires_at = pg_catalog.now() + interval '5 minutes',
      attempt_count = attempt_count + 1
  WHERE id = v_outbox.id
  RETURNING * INTO v_outbox;

  -- POQ-01 Option C: iterate strictly over immutable event-time candidate snapshot
  FOR v_cand IN
    SELECT r.recipient_user_id, u.account_status
    FROM public.notification_outbox_recipients r
    JOIN public.app_users u ON u.id = r.recipient_user_id
    WHERE r.outbox_id = v_outbox.id
    ORDER BY r.recipient_user_id ASC
  LOOP
    -- Dispatch-time revalidation may SUPPRESS non-APPROVED accounts, NEVER widen!
    IF v_cand.account_status <> 'APPROVED' THEN
      v_suppressed := v_suppressed + 1;
      CONTINUE;
    END IF;

    INSERT INTO public.notifications (
      outbox_id, recipient_user_id,
      project_id,
      event_type, priority, title_key, body_key, safe_payload
    ) VALUES (
      v_outbox.id, v_cand.recipient_user_id,
      CASE WHEN v_outbox.scope_type = 'PROJECT' THEN v_outbox.scope_id ELSE NULL END,
      v_outbox.event_type, 'NORMAL',
      'notif.' || v_outbox.event_type || '.title',
      'notif.' || v_outbox.event_type || '.body',
      v_outbox.safe_payload
    )
    ON CONFLICT (outbox_id, recipient_user_id) DO NOTHING
    RETURNING * INTO v_notif;

    IF v_notif.id IS NOT NULL THEN
      INSERT INTO public.notification_deliveries (
        notification_id, channel, status, sent_at, delivered_at
      ) VALUES (
        v_notif.id, 'IN_APP', 'DELIVERED', pg_catalog.now(), pg_catalog.now()
      )
      ON CONFLICT (notification_id, channel) DO NOTHING;
      v_created := v_created + 1;
    END IF;
  END LOOP;

  UPDATE public.notification_outbox
  SET status = 'COMPLETED', processed_at = pg_catalog.now()
  WHERE id = v_outbox.id;

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-052',
    'status', 'COMPLETED',
    'outbox_id', v_outbox.id,
    'created', v_created,
    'suppressed', v_suppressed,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- CMD-054 (Internal Scheduler/Worker): evaluate-notification-escalation
-- Owned by app_worker_definer; NOT browser callable.
-- Uses DB UTC time (POQ-02 ELAPSED_UTC); quiet hours never pause SLA.
-- ===========================================================================
CREATE OR REPLACE FUNCTION app_internal.worker_evaluate_escalation_v1(
  p_notification_id uuid,
  p_policy_version_id uuid,
  p_step_no integer,
  p_sla_minutes integer,
  p_escalation_recipients uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_notif public.notifications%ROWTYPE;
  v_due_at timestamptz;
  v_outbox public.notification_outbox%ROWTYPE;
  v_rec_id uuid;
  v_eligible_count integer := 0;
BEGIN
  SELECT * INTO v_notif FROM public.notifications WHERE id = p_notification_id;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-054', 'status', 'NOT_FOUND', 'server_time', pg_catalog.now());
  END IF;

  v_due_at := v_notif.created_at + pg_catalog.make_interval(mins => greatest(coalesce(p_sla_minutes, 60), 1));

  -- If already read or not yet due under DB UTC clock
  IF v_notif.read_at IS NOT NULL OR pg_catalog.now() < v_due_at THEN
    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-054', 'status', 'NOT_DUE', 'due_at', v_due_at, 'server_time', pg_catalog.now());
  END IF;

  IF coalesce(pg_catalog.array_length(p_escalation_recipients, 1), 0) = 0 THEN
    INSERT INTO public.notification_escalation_events (
      notification_id, policy_version_id, step_no, event_type, due_at, outcome, reason_code
    ) VALUES (
      v_notif.id, p_policy_version_id, p_step_no, 'notification.escalated', v_due_at, 'NO_ELIGIBLE_RECIPIENT', 'EMPTY_CANDIDATES'
    )
    ON CONFLICT (notification_id, policy_version_id, step_no, event_type) DO NOTHING;

    RETURN pg_catalog.jsonb_build_object('command_id', 'CMD-054', 'status', 'NO_ELIGIBLE_RECIPIENT', 'server_time', pg_catalog.now());
  END IF;

  -- Persist escalation outbox + immutable event-time candidate snapshot atomically
  INSERT INTO public.notification_outbox (
    source_event_id, event_type, scope_type, scope_id, policy_version_id, safe_payload, status
  ) VALUES (
    pg_catalog.gen_random_uuid(), 'notification.escalated',
    CASE WHEN v_notif.project_id IS NOT NULL THEN 'PROJECT' ELSE 'GLOBAL' END,
    v_notif.project_id,
    p_policy_version_id,
    pg_catalog.jsonb_build_object('parent_notification_id', v_notif.id, 'step_no', p_step_no),
    'PENDING'
  )
  RETURNING * INTO v_outbox;

  FOREACH v_rec_id IN ARRAY p_escalation_recipients
  LOOP
    IF EXISTS (SELECT 1 FROM public.app_users WHERE id = v_rec_id AND account_status = 'APPROVED') THEN
      INSERT INTO public.notification_outbox_recipients (
        outbox_id, recipient_user_id, eligibility_reason, source_scope_type, source_scope_id
      ) VALUES (
        v_outbox.id, v_rec_id, 'SLA escalation step ' || p_step_no::text,
        v_outbox.scope_type, v_outbox.scope_id
      )
      ON CONFLICT (outbox_id, recipient_user_id) DO NOTHING;
      v_eligible_count := v_eligible_count + 1;
    END IF;
  END LOOP;

  INSERT INTO public.notification_escalation_events (
    notification_id, policy_version_id, step_no, event_type, due_at, outbox_id, outcome
  ) VALUES (
    v_notif.id, p_policy_version_id, p_step_no, 'notification.escalated', v_due_at, v_outbox.id,
    CASE WHEN v_eligible_count > 0 THEN 'ENQUEUED' ELSE 'NO_ELIGIBLE_RECIPIENT' END
  )
  ON CONFLICT (notification_id, policy_version_id, step_no, event_type) DO NOTHING;

  INSERT INTO public.audit_events (
    event_type, actor_user_id, actor_auth_uid, command_id,
    scope_type, scope_id, target_table, target_id,
    outcome, metadata
  ) VALUES (
    'notification.escalation_evaluated', NULL, NULL, 'CMD-054',
    v_outbox.scope_type, v_outbox.scope_id, 'notification_outbox', v_outbox.id,
    'SUCCESS', pg_catalog.jsonb_build_object('notification_id', v_notif.id, 'step_no', p_step_no, 'candidates', v_eligible_count)
  );

  RETURN pg_catalog.jsonb_build_object(
    'command_id', 'CMD-054',
    'status', CASE WHEN v_eligible_count > 0 THEN 'ENQUEUED' ELSE 'NO_ELIGIBLE_RECIPIENT' END,
    'outbox_id', v_outbox.id,
    'candidates', v_eligible_count,
    'server_time', pg_catalog.now()
  );
END;
$$;

-- ===========================================================================
-- Exact-signature ownership & EXECUTE grants (T-18)
-- ===========================================================================
ALTER FUNCTION public.cmd_list_own_notifications_v1(boolean, integer) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_list_own_notifications_v1(boolean, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_list_own_notifications_v1(boolean, integer) TO authenticated;

ALTER FUNCTION public.cmd_mark_notification_read_v1(uuid) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_mark_notification_read_v1(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_mark_notification_read_v1(uuid) TO authenticated;

ALTER FUNCTION public.cmd_publish_notification_policy_v1(text, text, text, uuid, text, jsonb) OWNER TO app_cmd_definer;
REVOKE ALL ON FUNCTION public.cmd_publish_notification_policy_v1(text, text, text, uuid, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cmd_publish_notification_policy_v1(text, text, text, uuid, text, jsonb) TO authenticated;

-- Internal worker functions: owned by app_worker_definer, ZERO browser EXECUTE grants!
ALTER FUNCTION app_internal.worker_fanout_notification_outbox_v1(uuid, text) OWNER TO app_worker_definer;
REVOKE ALL ON FUNCTION app_internal.worker_fanout_notification_outbox_v1(uuid, text) FROM PUBLIC, anon, authenticated;

ALTER FUNCTION app_internal.worker_evaluate_escalation_v1(uuid, uuid, integer, integer, uuid[]) OWNER TO app_worker_definer;
REVOKE ALL ON FUNCTION app_internal.worker_evaluate_escalation_v1(uuid, uuid, integer, integer, uuid[]) FROM PUBLIC, anon, authenticated;

REVOKE CREATE ON SCHEMA app_internal, public FROM app_cmd_definer;
REVOKE CREATE ON SCHEMA app_internal FROM app_worker_definer;
