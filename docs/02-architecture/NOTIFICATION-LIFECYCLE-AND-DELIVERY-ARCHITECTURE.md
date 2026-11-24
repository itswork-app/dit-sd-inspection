# Notification Lifecycle and Delivery Architecture

**Document ID:** NLA-001  
**Version:** 0.1.0  
**Status:** ENGINEERING DESIGN PROPOSAL — PO/SECURITY REVIEW REQUIRED  
**Date:** 2026-11-24  
**Product authority:** INS-015 — APPROVED  
**Related controls:** INS-016 / T-15, T-18, T-10, MIB-001, DGA-001  
**Implementation authorization:** NOT GRANTED

## 1. Purpose and authority boundary

This document converts the approved INS-015 product direction into a reviewable notification lifecycle and persistence proposal. INS-015 is approved at Product Owner level; the table design, worker security model, permission grant matrix, retention schedule, provider choices and exact API/function signatures remain proposed until their respective reviewers and authorities approve them.

This document does not authorize migrations, SQL, grants, provider setup, deployment or live database changes.

## 2. Approved product behavior carried forward

The implementation must preserve these INS-015 requirements:

1. In-app notifications are the primary channel.
2. Browser/device push is optional and must respect user/device consent and capability.
3. Email is available for important notices; channel eligibility is policy-controlled.
4. WhatsApp is excluded from the MVP.
5. Recipient selection is role- and assignment-scoped; no global broadcast is inferred from a role label.
6. Priority, recipient selectors, channels, quiet hours, reminders, SLA thresholds and escalation paths are configurable.
7. Delivery state and user read state are independent facts.
8. Failed sends retry idempotently.
9. Notifications never create, approve, return, reopen, pause, close or otherwise change inspection/project/session state.
10. Configuration changes and escalation events are versioned and audited.
11. Example SLA values are illustrative only; no example becomes a production constant without approval.

## 3. Domain lifecycle

### 3.1 End-to-end flow

1. An authorized domain command changes business state and appends its canonical domain event and audit event atomically.
2. If the event matches an enabled notification rule, the same transaction appends a minimal `notification_outbox` record containing the source event reference, scope, event type and immutable policy-version reference. The business transaction does not call an external provider.
3. An internal fan-out worker claims the outbox row with a bounded lease and idempotently resolves recipients from the event-time policy and effective role/assignment scope.
4. One `notifications` inbox row is created per recipient. The unique source-outbox/recipient key prevents duplicate inbox records.
5. One `notification_deliveries` row is created per selected channel. In-app availability is represented by the inbox row; external push/email delivery is tracked separately.
6. A delivery worker claims eligible channel rows, sends through a provider adapter, and appends a `notification_delivery_attempts` record for each attempt. Provider I/O occurs outside a database transaction.
7. A delivery result is persisted using a guarded idempotent completion operation. If the worker crashes after provider acceptance but before recording the result, retry uses provider idempotency where supported; otherwise the system records an uncertain outcome and applies bounded duplicate-tolerant retry rules rather than claiming exactly-once delivery.
8. A user read action updates only that recipient's `read_at`; it does not mutate delivery state or source business state.
9. SLA/reminder/escalation processing evaluates version-pinned rules and appends `notification_escalation_events`; escalation can enqueue another notification but cannot alter the underlying inspection status.

### 3.2 State separation

| Concern | Authoritative record | Meaning |
|---|---|---|
| Notification creation/fan-out | `notification_outbox` | Durable request to create recipient notifications |
| Recipient inbox | `notifications` | One scoped notification per recipient; includes independent read state |
| Channel delivery | `notification_deliveries` | Current per-channel state and next retry time |
| Delivery attempt history | `notification_delivery_attempts` | Append-only evidence of each provider attempt/result |
| Policy configuration | `notification_policy_versions` | Immutable, versioned declarative policy snapshot |
| SLA/escalation history | `notification_escalation_events` | Append-only reminder/escalation decisions and outcomes |
| Business state | Existing domain tables/events | Never changed by notification delivery/read/escalation |

No table named `notification_events` is required in this proposal. It is replaced by explicit lifecycle entities above; the name must be removed from the ERD to avoid conflating inbox state, provider delivery and escalation history.

## 4. Proposed physical model

All identifiers are UUIDs; timestamps are `timestamptz` in UTC. Exact enum/check constraints and composite FK definitions must be finalized in the physical schema review. JSONB is permitted only for validated, versioned declarative policy/payload documents; it must not contain executable expressions, SQL, templates with code, secrets or unrestricted user-controlled routing instructions.

### 4.1 `notification_policy_versions`

Purpose: immutable, scope-bound policy snapshots.

Minimum fields:
- `id`, `policy_key`, `version_no`, `scope_type`, `scope_id`
- `schema_version`, `policy_document`, `policy_hash`
- `status` (DRAFT, PUBLISHED, RETIRED), `effective_from`, `effective_until`
- `created_by`, `created_at`, `published_by`, `published_at`

Constraints:
- Unique (`policy_key`, `scope_type`, `scope_id`, `version_no`).
- Published versions are immutable; changes create a new version.
- Exactly one effective published version per policy/scope/time interval; enforce with a reviewed exclusion/locking strategy.
- Validate policy JSON against a versioned allowlist schema; reject unknown keys and executable content.
- Policy references must be pinned to the outbox event at creation; later edits do not rewrite queued notifications.

Policy document fields are limited to: event type/rule enablement, priority, recipient selectors, channel enablement, quiet-hours/time-zone policy, reminder schedule, SLA thresholds, escalation steps and expiry/display metadata. Exact allowed values and selector grammar require PO/security approval.

### 4.2 `notification_outbox`

Purpose: transactional bridge from a domain event to asynchronous recipient fan-out.

Minimum fields:
- `id`, `source_event_id`, `event_type`, `scope_type`, `scope_id`
- `policy_version_id`, `payload_ref` or minimized `payload`
- `status` (PENDING, PROCESSING, COMPLETED, RETRY_WAIT, DEAD_LETTER)
- `attempt_count`, `next_attempt_at`, `lease_owner`, `lease_expires_at`
- `created_at`, `processed_at`, `last_error_code`

Constraints:
- Unique (`source_event_id`, `policy_version_id`) for one fan-out evaluation per source event/policy.
- Claim work using short leases and `FOR UPDATE SKIP LOCKED`; never hold a transaction during provider I/O.
- Lease expiry allows recovery after worker crash.
- Retry/dead-letter transitions are bounded and auditable; no silent deletion.
- Store only the minimum event data needed for message rendering and routing. Do not copy evidence, personal records or unrestricted source payloads.

### 4.3 `notifications`

Purpose: recipient-specific in-app inbox record.

Minimum fields:
- `id`, `outbox_id`, `recipient_user_id`
- `project_id?`, `session_id?`, `location_id?`, `assignment_id?`
- `event_type`, `priority`, `title_key`, `body_key`, `safe_payload`
- `created_at`, `expires_at?`, `read_at?`, `dismissed_at?`

Constraints:
- Unique (`outbox_id`, `recipient_user_id`).
- Recipient and scope are resolved server-side from the policy version and effective assignment/role at the defined event-time rule.
- A role label alone never grants access to a notification or its source resource.
- Read/dismiss actions are recipient-self only; the source resource still requires its own authorization.
- Do not place sensitive evidence or full personal data in notification text/payload. Use opaque resource references and re-authorize on navigation.

### 4.4 `notification_deliveries`

Purpose: one current delivery projection per notification/channel.

Minimum fields:
- `id`, `notification_id`, `channel` (IN_APP, WEB_PUSH, DEVICE_PUSH, EMAIL)
- `status` (PENDING, SUPPRESSED, SENDING, SENT, DELIVERED, FAILED, EXPIRED, UNKNOWN)
- `attempt_count`, `next_attempt_at`, `last_attempt_at`, `sent_at?`, `delivered_at?`
- `provider_message_ref?`, `last_error_code?`, `created_at`, `updated_at`

Constraints:
- Unique (`notification_id`, `channel`).
- Delivery state is not the read state. IN_APP availability is established by the inbox record; do not claim user-read from provider delivery.
- Quiet hours and channel eligibility are evaluated before dispatch; suppressed items retain a reason and can be rescheduled if policy allows.
- Provider callbacks are untrusted input: authenticate/signature-check them, validate provider reference and legal state transition, and make webhook processing idempotent.

### 4.5 `notification_delivery_attempts`

Purpose: append-only delivery attempt evidence.

Minimum fields:
- `id`, `delivery_id`, `attempt_no`, `idempotency_key`
- `started_at`, `finished_at?`, `outcome`, `provider_message_ref?`
- `safe_error_code?`, `retryable?`, `worker_correlation_id`

Constraints:
- Unique (`delivery_id`, `attempt_no`) and unique idempotency key.
- Application roles cannot update/delete attempt history.
- Store sanitized provider error codes only; never store credentials, message bodies, full provider responses or tokens.

### 4.6 `notification_escalation_events`

Purpose: append-only SLA/reminder/escalation decision history.

Minimum fields:
- `id`, `notification_id`, `policy_version_id`, `step_no`, `event_type`
- `due_at`, `evaluated_at`, `recipient_resolution_ref?`, `outbox_id?`, `outcome`, `reason_code?`

Constraints:
- Unique (`notification_id`, `policy_version_id`, `step_no`, `event_type`) for idempotent step evaluation.
- Escalation recipients are revalidated against current effective authorization/scope before notification creation.
- An escalation event records communication workflow only; it never changes inspection/project/session state.

## 5. Recipient, scope and authorization rules

1. Resolve recipients using the immutable policy version and approved event-time semantics; the proposed default is event-time eligibility for the initial audience, with a second current-authorization check before any sensitive link or resource access.
2. Recipient selectors must be explicit and bounded: role + effective project/session/location/assignment membership, or a named self/actor selector where approved.
3. Never use global role membership as a substitute for assignment scope.
4. Do not notify a user whose account is disabled, suspended, expired or otherwise ineligible at dispatch time.
5. Deduplicate recipients across multiple matching selectors before creating inbox rows.
6. The inbox query is restricted to `recipient_user_id = auth.uid()`; project scope is additional filtering, not a way to widen recipient ownership.
7. Mark-read/dismiss operations require the caller to own the notification row. A forged notification ID returns a non-enumerating denial/not-found response.
8. Clicking a notification must independently re-authorize access to the referenced resource; the notification itself is not an access token.
9. Role-to-permission grants for policy administration remain unapproved until the canonical permission registry and grantor/SoD matrix receive PO/security approval.

## 6. Channel, quiet-hours and delivery rules

- IN_APP is the baseline channel.
- WEB_PUSH/DEVICE_PUSH are optional and require explicit device/browser capability and consent; revocation stops future sends and invalidates relevant subscriptions.
- EMAIL is used only for policy-defined important notices and only where an approved verified address exists.
- WhatsApp is not an MVP channel.
- Channel selection is captured against the policy version; a later policy change does not silently rewrite an already-created notification.
- Quiet-hours evaluation uses the configured recipient/project time-zone rule. Missing/invalid time zone fails to the safe policy default and must not invent a recipient locale.
- High-priority or safety-critical exceptions to quiet hours require explicit policy approval; no implicit bypass.
- Provider delivery callbacks may update delivery state only; they cannot mark the in-app notification as read.
- No exactly-once guarantee is claimed across external providers. Use idempotency keys, provider idempotency when available, webhook deduplication, attempt history and an explicit UNKNOWN state for ambiguous outcomes.

## 7. Retry, SLA and escalation

- Retry only retryable failures with bounded exponential backoff, jitter and a maximum attempt/age policy approved before production.
- Permanent errors (invalid address, revoked push subscription, rejected payload) become terminal or suppressed with a safe reason code.
- A worker claim is leased; expired leases are reclaimable. A worker must not hold DB locks across provider network calls.
- SLA clocks use a named start event and server UTC timestamps. Paused/closed business states may affect reminder eligibility only if a policy explicitly defines it; notification processing itself never changes those states.
- Reminder/escalation steps are version-pinned, idempotent and append-only.
- Escalation may target only recipients resolved from explicit policy and currently valid scope. If no valid recipient exists, record NO_ELIGIBLE_RECIPIENT and do not broaden scope.
- Failed delivery does not block or roll back the underlying inspection command. Failure is visible to operations through delivery state and monitoring.
- Outbox/fan-out failure is recoverable and must be monitored; it must not silently drop an accepted notification intent.

## 8. Audit and privacy

- Policy create/edit/publish/retire, recipient-resolution exceptions, escalation decisions and security-relevant delivery administration are audited.
- Delivery attempts are preserved in their dedicated append-only table; do not duplicate every routine retry into the general audit stream.
- Business mutation + domain event + audit + outbox intent are one transaction. Failure to append required audit/outbox intent rolls back the business mutation.
- External provider delivery is asynchronous and cannot be in the business transaction.
- Audit payloads contain actor, action, target, scope, correlation and policy version references; never include message secrets, JWTs, provider credentials or sensitive evidence.
- Retention, deletion, legal hold, audit export and data classification remain blocked by T-10 institutional approval. No production purge/retention duration is defined here.

## 9. Internal worker and API boundary

Proposed externally visible user operations:
- Read own notification inbox (cursor pagination; unread filter).
- Mark own notification read (idempotent).
- Dismiss own notification if the product UX/PO confirms this state.

Proposed policy administration operation:
- Create/update draft and publish a new immutable policy version, subject to explicit `notification.policy.manage` grant and scope/SoD approval.

Internal-only operations:
- Claim/fan-out outbox work.
- Claim/send channel delivery.
- Record provider result/webhook.
- Evaluate reminders/SLA/escalations.

Internal worker operations must not be exposed as browser-callable RPCs. Their authentication principal, Vercel scheduler trust, database execution role, function owner, exact EXECUTE grants, rate limits and secret custody require a separate T-18 security review. Do not use a browser-held service-role key or treat an ordinary user JWT as a worker credential.

## 10. Proposed command catalogue additions

Stable proposed IDs continue after the existing CMD-001..048; no existing ID is renumbered.

| ID | Logical operation | Proposed permission/principal | Read/write set | Idempotency and audit |
|---|---|---|---|---|
| CMD-049 | `list-own-notifications` | `notification.read`; recipient self via auth.uid() | notifications; read only | Cursor bound to actor/filter; no broad source access |
| CMD-050 | `mark-notification-read` | `notification.read`; recipient self | notifications.read_at | Actor + notification + key; `notification.read` |
| CMD-051 | `publish-notification-policy` | `notification.policy.manage`; explicit config scope | notification_policy_versions, audit_events | Policy key/version/hash + key; `notification.policy_published` |
| CMD-052 | `fanout-notification-outbox` | Internal worker principal only | notification_outbox, notifications, notification_deliveries | Unique outbox/recipient/channel; worker event |
| CMD-053 | `dispatch-notification-delivery` | Internal delivery worker only | notification_deliveries, notification_delivery_attempts | Delivery/channel/attempt key; sanitized attempt result |
| CMD-054 | `evaluate-notification-escalation` | Internal scheduler/worker only | notification_escalation_events, notification_outbox | Notification/policy/step unique key; escalation event |

These are design IDs, not approved PostgreSQL function names, routes, grants or role assignments. The exact permission registry, request/response schemas, worker principal and API/RPC mappings require review before implementation.

## 11. Verification catalogue

Allocate these stable test IDs in the QA catalogue; they are planned, not executed:

- TC-NOTIF-001: source event and outbox intent commit atomically; audit/outbox failure rolls back the business mutation.
- TC-NOTIF-002: duplicate outbox processing creates one inbox row per recipient.
- TC-NOTIF-003: multiple selectors resolving the same user produce one recipient notification.
- TC-NOTIF-004: role membership without matching assignment scope cannot receive or read scoped notification.
- TC-NOTIF-005: recipient A cannot list/read/mark-read recipient B's notification.
- TC-NOTIF-006: notification link does not bypass authorization on the referenced resource.
- TC-NOTIF-007: delivery state and read state remain independent under all transitions.
- TC-NOTIF-008: quiet hours suppress/defer only channels allowed by the pinned policy and correct time zone.
- TC-NOTIF-009: provider retry is idempotent; duplicate webhook/result does not create duplicate state transitions.
- TC-NOTIF-010: provider accepted + worker crash yields safe UNKNOWN/reconciliation behavior, not false exactly-once claims.
- TC-NOTIF-011: expired worker lease is reclaimable without duplicate fan-out.
- TC-NOTIF-012: policy publish creates immutable version/hash; old outbox retains old policy version.
- TC-NOTIF-013: escalation step runs once; no eligible recipient does not widen scope.
- TC-NOTIF-014: failed notification delivery never changes inspection/project/session status.
- TC-NOTIF-015: revoked/disabled account or push subscription is excluded at dispatch.
- TC-NOTIF-016: sensitive payloads, tokens and provider secrets are absent from logs/audit/attempt records.
- TC-NOTIF-017: outbox backlog, dead-letter, retry age and provider failure metrics/alerts are observable.
- TC-NOTIF-018: cursor pagination cannot cross recipient identity or filter scope.

## 12. Open approvals and dependencies

1. PO/security approval of the exact notification recipient-selector grammar and event-time versus dispatch-time eligibility semantics.
2. PO/security approval of notification policy administrator authority, `notification.policy.manage` scope and role/grantor/SoD matrix.
3. Security approval of internal worker identity, scheduler authentication, database role, function owner and exact EXECUTE ACL.
4. Institutional T-10 approval for classification, content minimization, retention, deletion, legal hold, audit access/export and time-zone/network metadata.
5. Provider decision and verified capabilities/quotas for email and optional browser/device push; cost envelope and failure behavior.
6. Numeric retry horizon, maximum attempts, SLA clock semantics, quiet-hour exception policy and operational alert thresholds.
7. UX decision on dismiss/archive behavior and unread/read retention.
8. Exact physical composite FKs, indexes, enum/check definitions and RLS predicates reviewed across all six proposed tables.

## 13. Gate disposition

- INS-015 product direction: **APPROVED**.
- Lifecycle and persistence proposal: **DOCUMENTED; PO/SECURITY REVIEW REQUIRED**.
- ERD-only `notification_events`: **PROPOSED FOR REMOVAL / REPLACEMENT BY EXPLICIT LIFECYCLE TABLES**.
- Physical schema/RLS: **PROPOSED, NOT IMPLEMENTED OR LIVE-VERIFIED**.
- Permission and worker execution authority: **OPEN**.
- T-10 retention/privacy: **BLOCKED PENDING INSTITUTIONAL APPROVAL**.
- Tests: **PLANNED, NOT EXECUTED**.
- Scope freeze / G9: **NOT READY**.
- Implementation / G10: **NOT AUTHORIZED**.

---
