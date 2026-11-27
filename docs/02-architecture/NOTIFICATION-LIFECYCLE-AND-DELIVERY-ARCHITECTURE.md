# Notification Lifecycle and Delivery Architecture

**Document ID:** NLA-001  
**Version:** 1.0.0  
**Status:** TECHNICAL SSOT CLOSED — READY FOR G9-TECH FREEZE (POQ-01..04 & NLA-MVP-001 APPROVED; F05-T1..T5 DESIGN CLOSED; EXTERNAL PROVIDER ADAPTERS GATED UNTIL T-10/T-12; RUNTIME QA GATED TO G11)  
**Date:** 2026-11-27  
**Product authority:** INS-015, POQ-01..04, NLA-MVP-001 — APPROVED  
**Related controls:** INS-016 / T-15, T-18, T-10, MIB-001, DGA-001  
**Product Owner authorization:** CONDITIONAL IMPLEMENTATION AUTHORIZATION RECEIVED (2026-11-24)  
**G10 implementation activation:** NOT ACTIVE — pending verified G9 and a separate G10 activation record

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
3. An internal fan-out worker claims the outbox row with a bounded lease and idempotently materializes the persisted event-time candidate audience and authorized source scope/checkpoint. Retries reuse that immutable candidate audience; current account/channel restrictions are revalidated before each external send and may suppress candidates but never widen the audience.
4. One `notifications` inbox row is created per recipient. The unique source-outbox/recipient key prevents duplicate inbox records.
5. One `notification_deliveries` row is created per selected external channel. In-app availability is represented by the inbox row; external push/email delivery is tracked separately.
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
- `status` (DRAFT, PUBLISHED, RETIRED), `effective_from`, `effective_until`; DRAFT is reserved for a future separately approved workflow and is not written by CMD-051
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
- `id`, `source_event_id` (canonical `audit_events.id`), `event_type` (audited action), `scope_type`, `scope_id`
- `policy_version_id`, `safe_payload` (minimized, schema-validated JSONB)
- `status` (PENDING, PROCESSING, COMPLETED, RETRY_WAIT, DEAD_LETTER); partial batch progress remains PROCESSING and resumes idempotently
- `attempt_count`, `next_attempt_at`, `lease_owner`, `lease_token_hash`, `lease_generation`, `lease_expires_at`
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
- `created_at`, `expires_at?`, `read_at?`, `dismissed_at?` (reserved; no command or browser mutation until PO/UX approval)

Constraints:
- Unique (`outbox_id`, `recipient_user_id`).
- Recipient and scope are resolved server-side at source-event time into a durable candidate-audience snapshot/checkpoint bound to the source event, scope and policy version. Fan-out and retries reuse this immutable candidate audience. Before each external send, revalidate current account status, channel eligibility, consent/revocation and mandatory security restrictions. Revalidation may suppress a candidate but must never add a recipient outside the original snapshot. The exact durable representation, selector grammar and partial-fan-out checkpoint remain Engineering/Security design items.
- A role label alone never grants access to a notification or its source resource.
- Read is recipient-self only and set-once. dismissed_at is reserved; no dismiss action is exposed until PO/UX approval. The source resource still requires its own authorization.
- Do not place sensitive evidence or full personal data in notification text/payload. Use opaque resource references and re-authorize on navigation.

### 4.4 `notification_deliveries`

Purpose: one current delivery projection per notification/channel.

Minimum fields:
- `id`, `notification_id`, `channel` (WEB_PUSH, DEVICE_PUSH, EMAIL)
- `status` (PENDING, SUPPRESSED, SENDING, SENT, DELIVERED, FAILED, EXPIRED, UNKNOWN)
- `attempt_count`, `next_attempt_at`, `last_attempt_at`, `sent_at?`, `delivered_at?`
- `lease_owner`, `lease_token_hash`, `lease_generation`, `lease_expires_at`
- `provider_message_ref?`, `last_error_code?`, `created_at`, `updated_at`

Constraints:
- Unique (`notification_id`, `channel`).
- Lease finalizers validate owner, token hash, generation and expiry; stale generations cannot commit after reclaim.
- Candidate transition rules: PENDING may enter SENDING, SUPPRESSED or EXPIRED; SENDING may enter SENT, FAILED or UNKNOWN; SENT may advance to DELIVERED or provider-confirmed FAILED; UNKNOWN may advance only after provider reconciliation; terminal DELIVERED/FAILED/EXPIRED states do not regress. SUPPRESSED may return to PENDING only where the pinned policy explicitly permits rescheduling.
- A duplicate or out-of-order callback is an idempotent no-op/denial; it cannot reset the state to an earlier phase.
- Delivery state is not the read state. In-app availability is established by the inbox record and has no external delivery row; do not claim user-read from provider delivery.
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

1. Resolve and persist the event-time candidate audience and authorized source scope/checkpoint as part of durable fan-out intent. The candidate audience is immutable across retries. Before each external send, revalidate current account status, channel eligibility, consent/revocation and mandatory security restrictions; suppress ineligible candidates but never add recipients outside the event-time snapshot. A policy-version pin alone is not a recipient snapshot. Reauthorize independently before any sensitive link or resource access.
2. Recipient selectors must be explicit and bounded: role + effective project/session/location/assignment membership, or a named self/actor selector where approved.
3. Never use global role membership as a substitute for assignment scope.
4. Do not notify a user whose account is disabled, suspended, expired or otherwise ineligible at dispatch time.
5. Deduplicate recipients across multiple matching selectors before creating inbox rows.
6. The inbox query is restricted to `recipient_user_id = auth.uid()`; project scope is additional filtering, not a way to widen recipient ownership.
7. Mark-read requires the caller to own the notification row and is set-once. Dismiss/archive is excluded from MVP by POQ-03: no dismiss command, permission, browser write or UX action exists. Any retained dismissed_at column is dormant with no runtime behavior. A forged notification ID returns a non-enumerating denial/not-found response.
8. Clicking a notification must independently re-authorize access to the referenced resource; the notification itself is not an access token.
9. Role-to-permission grants for policy administration remain unapproved until the canonical permission registry and grantor/SoD matrix receive PO/security approval.

## 6. Channel, quiet-hours and delivery rules

- In-app is the baseline inbox and is not represented as a provider delivery channel.
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
- Each immutable policy version explicitly selects elapsed-time or business-time SLA semantics. Initial-release default is `ELAPSED_UTC`, calculated from a named start event using server/database UTC instants and fixed elapsed durations. Quiet hours defer eligible channel delivery only; they do not pause or stop the SLA clock. Business-time calendars/time zones and pause/reset conditions require separately specified and approved policy rules. Notification processing never changes source business states.
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
- No dismiss/archive operation in MVP (POQ-03 approved exclusion).

Proposed policy administration operation:
- Create/update draft and publish a new immutable policy version, subject to explicit `notification.policy.manage` grant and scope/SoD approval.

Internal-only operations:
- Claim/fan-out outbox work.
- Claim/send channel delivery.
- Record provider result/webhook through the separately authenticated integration boundary INT-NOTIF-001.
- Evaluate reminders/SLA/escalations.

Internal worker operations must not be exposed as browser-callable RPCs. Their authentication principal, Vercel scheduler trust, database execution role, function owner, exact EXECUTE grants, rate limits and secret custody require a separate T-18 security review. Do not use a browser-held service-role key or treat an ordinary user JWT as a worker credential.

## 10. Proposed command catalogue additions

Stable proposed IDs continue after the existing CMD-001..048; no existing ID is renumbered.

| ID | Logical operation | Proposed permission/principal | Read/write set | Idempotency and audit |
|---|---|---|---|---|
| CMD-049 | `list-own-notifications` | `notification.read`; recipient self via auth.uid() | cursor?, limit, unread_only? | recipient-self only; actor/filter/sort-bound integrity-protected cursor; stable (created_at, id) order; no source-resource authorization inherited | notifications; read only | query + RLS recipient predicate; no cross-user enumeration; no snapshot guarantee | no general audit for page reads; aggregate telemetry only if approved | OK; DENIED; VALIDATION_FAILED | TC-NOTIF-018 |
| CMD-050 | `mark-notification-read` | `notification.read`; recipient self | notification_id only | recipient-self; non-enumerating; no delivery/business mutation | notifications.read_at | guarded read_at IS NULL set-once update; DB UTC; no row-version token | first transition emits notification.read once atomically; duplicate/no-op emits no event | MARKED_READ; NOT_FOUND/DENIED | TC-NOTIF-005/007/019 |
| CMD-051 | `publish-notification-policy` | `notification.policy.manage`; explicit config scope | policy_key, scope_type, scope_id, schema_version, policy_document, expected_current_version_id? | explicit approved scope, grantor ceiling and SoD; no persisted draft CRUD | notification_policy_versions, audit_events | server canonical hash; serialized version allocation; published version immutable | actor + policy/scope/version/hash; notification.policy_published | PUBLISHED; INVALID_POLICY; STALE_POLICY_VERSION; DENIED | TC-NOTIF-012/020 |
| CMD-052 | `fanout-notification-outbox` | Internal worker principal only | outbox_id, lease_token, lease_generation, worker_batch_limit | internal workload only; no user actor; recipient eligibility checkpoint remains to be approved | notification_outbox, notifications, notification_deliveries | safe_payload; owner/token-hash/generation/expiry fencing; bounded lease; partial progress remains PROCESSING; no provider I/O | unique source-event/policy, outbox/recipient and notification/channel; resumable retry | worker telemetry only | COMPLETED; RETRY_WAIT; DEAD_LETTER | TC-NOTIF-002/003/011/021/022 |
| CMD-053 | `dispatch-notification-delivery` | Internal delivery worker only | delivery_id, lease_token, lease_generation, channel, notification_ref | internal worker; consent/quiet-hours; no user actor | notification_deliveries, notification_delivery_attempts | owner/token-hash/generation/expiry fencing; provider I/O outside transaction; UNKNOWN on ambiguous acceptance; callback ingress INT-NOTIF-001 | delivery/channel/attempt idempotency; provider event dedup remains provider-specific | sanitized attempt outcome; no secrets/message bodies | SENT; DELIVERED; FAILED; UNKNOWN; SUPPRESSED | TC-NOTIF-007/009/010/015/016/023/024/026 |
| CMD-054 | `evaluate-notification-escalation` | Internal scheduler/worker only | notification_id, policy_version_id, step_no | internal scheduler; one DB UTC instant; recipients revalidated; no scope widening | notification_escalation_events, notification_outbox | pinned policy; no caller evaluation_time; no business-state mutation | unique notification/policy/step/event | notification.escalation_evaluated | ENQUEUED; NO_ELIGIBLE_RECIPIENT; NOT_DUE | TC-NOTIF-013/014/025 |

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

### 11.1 Additional verification cases — planned only

- TC-NOTIF-019: CMD-050 set-once read emits one notification.read event on the first transition; duplicate requests do not create another event.
- TC-NOTIF-020: concurrent CMD-051 publications serialize against the expected current published version; stale publication is rejected and published policy content remains immutable.
- TC-NOTIF-021: a reclaimed CMD-052 outbox lease increments the fencing generation; the stale worker cannot finalize or overwrite the newer result.
- TC-NOTIF-022: partial CMD-052 fan-out retry uses uniqueness arbiters to avoid duplicate inbox/delivery rows and never loses the durable outbox intent.
- TC-NOTIF-023: INT-NOTIF-001 rejects invalid provider signatures, stale timestamps, replayed event identifiers and unknown provider references without changing delivery state.
- TC-NOTIF-024: accepted provider callback transitions are monotonic and cannot change inbox read state or source business state.
- TC-NOTIF-025: CMD-054 derives one server UTC evaluation instant; client-supplied time cannot force or suppress due escalation.
- TC-NOTIF-026: ambiguous provider acceptance remains UNKNOWN until safe reconciliation; no blind duplicate dispatch is inferred.

All cases are PLANNED / NOT EXECUTED.

## 12. Open approvals and dependencies

1. Engineering/Security design and review of the approved hybrid recipient rule: exact selector grammar, durable event-time candidate snapshot/checkpoint, partial fan-out/retry semantics, and dispatch-time revalidation without recipient widening.
2. PO/security approval of notification policy administrator authority, `notification.policy.manage` scope and role/grantor/SoD matrix.
3. Security approval of internal worker identity, scheduler authentication, database role, function owner and exact EXECUTE ACL.
4. Institutional T-10 approval for classification, content minimization, retention, deletion, legal hold, audit access/export and time-zone/network metadata.
5. Provider decision and verified capabilities/quotas for email and optional browser/device push; cost envelope and failure behavior.
6. Numeric retry horizon, maximum attempts, quiet-hour exception policy and operational alert thresholds. POQ-02 has approved per-policy elapsed/business-time semantics, `ELAPSED_UTC` as the initial default, and quiet hours as delivery deferral only; exact start events, calendar definitions and pause/reset rules remain to be specified where applicable.
7. Dismiss/archive is excluded from MVP by POQ-03; no dismiss UX, command or permission is in scope. Any retained dismissed_at column remains dormant.
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
- Implementation / G10: **NOT ACTIVE**.

---


## 14. Engineering reconciliation addendum — 2026-11-24

This addendum aligns NLA-001 with CMD-049–054 Detailed Contract Review v0.1.1, the canonical command catalogue, physical schema, RLS, audit, API, lock and QA documents. It remains an engineering proposal; no PO/security/institutional/provider approval is implied.

### 14.1 Canonical command boundaries

- **CMD-049:** recipient-self inbox query only. Cursor is server-issued, opaque or integrity-protected, and bound to auth.uid(), normalized filters, sort order and cursor format version. Use stable (created_at, id) ordering; do not claim cross-page snapshot isolation. Server-side page maximum and exact indexes remain to be approved. No provider delivery state or unrestricted source data is returned.
- **CMD-050:** request contains notification_id only. Remove expected_version; notifications has no version column and a monotonic set-once read_at update does not require one. The first successful transition emits one notification.read event atomically with the read change; repeated/no-op requests emit no duplicate event. Inbox page reads do not emit a general audit event. Foreign/unknown IDs have a non-enumerating result.
- **CMD-051:** publish-only in this command set. It validates a submitted candidate policy document, computes the canonical hash server-side and publishes a new immutable version using the expected current published-version reference as the concurrency guard. CMD-051 does not create or edit persisted drafts. If draft CRUD or a separate approval workflow is required, it needs a separately approved command/schema; no hidden draft lifecycle is inferred. notification.policy.manage grants, scope and SoD remain unapproved.
- **CMD-052:** canonical payload field is safe_payload. Outbox lease fields are lease_owner, lease_token_hash, monotonic lease_generation and lease_expires_at; the same fencing contract applies to delivery claims in CMD-053. Claim transactions commit before fan-out work. Partial retries rely on unique source-event/policy, outbox/recipient and notification/channel arbiters. POQ-01 fixes candidate recipient eligibility at source-event time; the exact durable recipient/scope snapshot representation remains an Engineering/Database/Security design item. A policy-version pin alone is not a recipient snapshot.
- **CMD-053:** provider I/O remains outside database transactions. Ambiguous provider acceptance is UNKNOWN, not success. Inbound provider status notifications are a distinct integration ingress, INT-NOTIF-001, not a browser command or a seventh CMD ID. The ingress must authenticate provider-specific signatures, validate freshness and provider/delivery references, deduplicate provider event IDs through an approved durable mechanism, apply only allowlisted monotonic delivery transitions and never mutate read_at or business state. Provider-specific auth/dedup details remain blocked until a provider is selected.
- **CMD-054:** request contains notification_id, policy_version_id and step_no; remove caller-supplied evaluation_time. Capture one database-controlled UTC instant per evaluation transaction and use it for due checks. SLA start event, elapsed/business-time rules, pause/close semantics, timezone and escalation policy remain PO/security decisions.
- **Dismissal:** POQ-03 approves exclusion from MVP. No dismiss command, permission, browser write or UX behavior is in scope. Any retained dismissed_at field is dormant and has no runtime behavior; future inclusion requires a new change request.

### 14.2 Durable worker lease/fencing contract

Outbox and delivery workers use the same logical lease tuple: workload owner identity, server-issued opaque token (persist only its hash), monotonic generation and expiry. Every completion, failure, retry or dead-letter finalizer must prove the current owner/token/generation and unexpired lease. A reclaimed lease advances generation; a stale worker cannot commit after reclaim. Queue locks are released before recipient fan-out continuation or provider network I/O. Exact DB constraints, owner identity, EXECUTE ACL and scheduler authentication remain T-18 security blockers.

### 14.3 Audit and privacy boundary

notification.read is emitted once on the first set-once read transition, not on every inbox page request or duplicate acknowledgement. Routine provider attempts and callbacks stay in dedicated delivery/attempt state and privacy-safe operational telemetry; do not emit one general audit event per retry. Policy publication and escalation decisions use the canonical audit events already listed in the Audit Event Catalogue. No message body, evidence, token, provider credential, full provider response or signed URL enters general audit metadata.

### 14.4 Approval and gate status

The six notification tables remain a proposed subset of the 48-table physical/RLS inventory. INT-NOTIF-001 is an integration contract, not a new CMD ID or table. Physical constraints, indexes, RLS, role grants, worker identity, provider capability, retry horizons, recipient-selector semantics and T-10 retention/privacy still require approval and/or live evidence. QA TC-NOTIF-001..040, TC-RLS-024-049 and TC-FN-SEC-025-064..071 remain PLANNED / NOT EXECUTED. G9 remains NOT READY; G10 remains NOT ACTIVE.


## 15. Product Owner decision reconciliation — POQ-001 (2026-11-24)

The Product Owner explicitly approved POQ-01 Option C, POQ-02 Option C and POQ-03 Option A on 2026-11-24. This section is controlling for product semantics and supersedes earlier statements in this document that described those three semantics as awaiting PO decisions.

### 15.1 POQ-01 — hybrid event-time candidate audience

- At source-event time, resolve and durably persist the candidate recipient audience together with its authorized source scope/checkpoint and immutable policy-version reference.
- Fan-out and partial retries reuse that same candidate audience; they do not re-resolve a wider audience from current role membership.
- Immediately before each external send, revalidate current account status, channel eligibility, consent/revocation and mandatory security restrictions.
- Revalidation may suppress an original candidate. It must never add a recipient who was not in the event-time candidate snapshot.
- Exact selector grammar, durable snapshot representation, checkpointing under partial fan-out and the technical implementation of revalidation remain Engineering/Security review items.

### 15.2 POQ-02 — per-policy SLA semantics

- Every immutable policy version declares `ELAPSED_UTC` or an explicitly defined business-time mode.
- The initial-release default is `ELAPSED_UTC`, using a named start event and server/database UTC instants.
- Quiet hours delay eligible channel delivery only. They do not pause, stop or reset the SLA clock.
- Business-time calendars, authoritative time zones, DST/holiday handling and any pause/reset conditions must be explicitly specified and reviewed before a policy using them can be activated.
- This approval does not select arbitrary calendars or approve unbounded policy expressions.

### 15.3 POQ-03 — dismiss/archive excluded from MVP

- MVP exposes recipient-owned, set-once `read_at` only.
- No dismiss/archive command, permission, browser write or UX action is included.
- If `dismissed_at` remains in a proposed physical schema for compatibility, it is dormant and must not be exposed or mutated.
- Future inclusion requires a separately scoped change request and renewed product, UX, security, schema and QA review.



### 15.4 Remaining notification gates

These PO approvals do not close technical or external dependencies: selector grammar and snapshot persistence; policy administration grants/SoD; worker identity and scheduler authentication; function ownership and EXECUTE ACL; provider selection/capability/quotas; retry horizons and alert thresholds; exact schema constraints/indexes/RLS; T-10 institutional privacy/records/retention; QA execution and live evidence. The six notification tables remain proposed and unimplemented. G9 remains NOT READY and G10 remains NOT ACTIVE.


### 15.5 F05-T3 suppression/retry state reconciliation — 2026-11-25

NLA-L05-TDR-001 v0.1.12 §4.2.7 records a candidate suppression/retry taxonomy aligned to the immutable POQ-01 candidate audience, POQ-04 account-reactivation boundary, POQ-02 quiet-hours/SLA semantics, append-only attempt history and explicit UNKNOWN provider outcomes.

A blocking state-graph omission is recorded for review: the current delivery progression defines `SENDING → SENT | FAILED | UNKNOWN`, but does not specify how a retryable provider failure returns to a future attempt. No `RETRY_WAIT` status or `SENDING → PENDING` transition is admitted by this note. Engineering/Database/Security must choose and validate one legal transition, then synchronize the command contract, physical schema proposal, worker lease/fencing rules and QA before implementation.

The following remain unresolved: stable reason-code strings and classification; reschedule rules for consent/channel/security/scope changes; retry owner and scheduler boundary; numeric attempt/age/backoff/dead-letter/alert budgets; provider-specific transient/permanent/unknown mapping; manual reconciliation SLA; and T-10 retention/disposition. No provider is selected. No state transition, physical status, table, schema, migration, grant, RLS or runtime behavior is approved by this addendum. F05-T3 remains OPEN; all QA remains PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.

## 16. POQ-01 durable event-time audience snapshot — physical design candidate (2026-11-24)

**Product semantics are APPROVED; this physical representation is a candidate for Engineering/Database/Security review, NOT approved DDL and NOT part of the canonical 48-table inventory.**

### 16.1 Required invariant

The candidate recipient set and each recipient's authorized source scope are determined at the source event's effective transaction time, bound to the immutable notification policy version, and durably persisted before the source business transaction commits. CMD-052 must consume that persisted set. It must never reconstruct the audience by querying current role or assignment membership during a retry. A policy version reference or a selector string alone is not a recipient snapshot.

### 16.2 Candidate relational representation

Use the existing `notification_outbox` row as the snapshot header and consider one candidate-only relation:

**Candidate table:** `notification_outbox_recipients` (NOT ADMITTED).

Candidate fields on the existing outbox header (NOT ADMITTED additions): `audience_snapshot_version`, `audience_snapshot_hash`, `audience_snapshot_count`, and `audience_snapshot_completed_at`. These identify the canonical serialization version, digest, expected unique recipient count and completion instant for the frozen audience.

Candidate fields on `notification_outbox_recipients`:
- `outbox_id` — FK to the immutable outbox intent;
- `recipient_user_id` — FK to the application identity selected at source-event time;
- `project_id`, `session_id`, `location_id`, `assignment_id` — nullable typed scope references recording the recipient's authorized source scope at that event;
- `scope_snapshot_hash` — digest of the canonical scope/membership evidence used for that recipient;
- `resolved_at` — server transaction timestamp.

Candidate integrity:
- primary/unique key `(outbox_id, recipient_user_id)` deduplicates a recipient matched by multiple selectors;
- composite FKs or equivalent trusted transaction assertions prove the project/session/location/assignment references are mutually consistent;
- candidate rows are immutable after the outbox audience snapshot is finalized;
- canonical snapshot hash and count on the outbox header reconcile to the sorted recipient/scope rows;
- no arbitrary selector SQL, client-supplied recipient IDs, role names or scope claims are accepted;
- the candidate table is not browser-readable or browser-writable.

### 16.3 Transaction and retry protocol

1. The source command resolves the approved, bounded selector grammar against source-event-time account, role, grant and assignment validity.
2. In the same transaction as the source mutation, canonical domain/audit event and `notification_outbox` insert, it inserts the deduplicated candidate recipient/scope rows and finalizes the header's candidate count/hash/completion marker.
3. The source transaction does not commit an outbox marked ready if the candidate snapshot is incomplete. A failure to persist the snapshot follows the source command's approved atomic failure policy; it must not silently defer audience resolution to a later current-state query.
4. CMD-052 reads the immutable candidate rows in deterministic recipient-key order and inserts one `notifications` row per candidate. The existing unique `(outbox_id, recipient_user_id)` key on `notifications` remains a second idempotency arbiter. Partial retry can derive outstanding work by anti-joining candidates to already materialized inbox rows; no mutable rewrite of candidate rows is required.
5. External channel eligibility is revalidated immediately before each send. A candidate may be suppressed for current account/channel/consent/security restrictions, but no new recipient may be added. Suppression belongs to delivery outcome, not mutation of the historical candidate snapshot.

### 16.4 Unresolved engineering decisions

- Exact selector grammar, source-event timestamp semantics and the authoritative temporal records for account/role/scope membership.
- Whether candidate materialization in the source transaction meets approved latency/lock budgets at maximum recipient fan-out.
- Numeric recipient bound, payload/snapshot size bound, query/index strategy and behavior when a configured bound is exceeded. No numeric value is invented here.
- Exact scope columns/composite FK design and canonical hashing/serialization version.
- Whether the outbox header stores snapshot version/hash/count/completed_at or an equivalent immutable snapshot reference.
- RLS/ACL, workload identity, function ownership, lease finalization, monitoring and recovery.
- T-10 classification, retention, legal hold and privacy review of recipient/scope history.

If same-transaction candidate materialization cannot meet the approved bound, Engineering must propose a different immutable event-time snapshot mechanism that still prevents audience widening; current-state re-resolution on retry is prohibited. This annex does not approve a new table, migration, index, policy, grant, worker or implementation.

### 16.5 Gate disposition

POQ-01 recipient semantics: **APPROVED**. Durable relational representation: **CANDIDATE — ENGINEERING/DB/SECURITY REVIEW REQUIRED**. CMD-052 physical read/write set: **PARTIAL — candidate table not admitted**. Worker identity/ACL and runtime verification: **OPEN**. QA TC-NOTIF-001..040, TC-RLS-024-049 and TC-FN-SEC-025-064..071: **PLANNED / NOT EXECUTED**. G9 remains NOT READY; G10 remains NOT ACTIVE.


## 17. Source-event producer lock inventory — 2026-11-24

### 17.1 Producer universe and event allowlisting

The current command catalogue defines 40 application domain command IDs (CMD-001–040) with canonical domain event declarations. Any of those event types may be considered for notification only when an immutable, enabled policy version explicitly allowlists the exact event type and selector grammar. This is not a default broadcast rule: no wildcard event matching, role-only audience, or implicit notification for every audit event is permitted.

The complete producer-to-event-to-candidate-lock mapping is maintained in COMMAND-LEVEL-LOCK-MANIFEST-CMD-001-054.md §7.7 (v0.4.27). It covers all 40 source command declarations and preserves their current candidate lock paths/dispositions. This is a producer coverage inventory, not evidence that any path is safe for recipient resolution or snapshot insertion.

### 17.2 Transactional source boundary

- CMD-001–034: where the canonical domain event is committed by the command transaction, a matching notification outbox intent and complete immutable recipient/scope snapshot must be committed in that same transaction. Failure to persist required audit/outbox/snapshot state follows the source command's approved atomic rollback behavior; no post-commit current-membership reconstruction is allowed.
- CMD-035: each operation-level domain event must be correlated to its durable operation result and its own notification intent/snapshot. The unresolved per-operation transaction versus savepoint decision means batch-level atomicity and snapshot completeness are not yet certifiable.
- CMD-036: the renderer finalizer, not merely the request that reserves a generation job, is the source boundary for a generated-document event. It must validate source revision/template and current lease fencing before atomically appending finalization event, audit, outbox and event-time audience snapshot.
- CMD-037: each recorded print/reprint event is its own source event after the document/version and print sequence arbiter are finalized.
- CMD-038: each item-level print event is distinct from the batch aggregate projection event. The durable item outcome/finalizer is the source boundary; the implementation must not fan out a batch completion notification as if it were every per-document print event.
- CMD-039: attendance upload/replacement is a source event only after private Storage verification and guarded database finalization of the exact document version.
- CMD-040: attendance verification is a source event only after the exact immutable document version, verifier scope and institutional SoD checks are fenced and committed.
- CMD-041/042 conditional report-access events and CMD-043/044 audit-access/export events are not part of this 40-command mutation producer set. They require a separately approved read-side access-event boundary; do not add notification side effects to a read query by assumption.
- CMD-045–048 are external control-plane IDs. CMD-049–054 are notification lifecycle operations/events and are excluded from notification policy matching by default to prevent recursive notification chains. Any future exception requires a separately approved bounded non-recursive policy.

### 17.3 Cross-command lock-order finding

The source-producer matrix confirms that many existing command paths reach L30, L40, L50, L60, L70 or L90 before their terminal event/audit append. The POQ-01 recipient resolver may require L15 principal, L16 role-grant, L17 scope-grant and L30/L50 project/session/assignment resources. Appending those eligibility reads/locks after a higher-ranked aggregate lock may invert the candidate global order. CMD-036/038/039 additionally require finalizer lease/source-version fences to be reconciled with recipient/scope locks.

No generic “append snapshot after source lock” sequence is approved. Before admitting the candidate relation:
1. For every enabled event type, identify its exact producer command or asynchronous finalizer and event cardinality.
2. Define the event-time eligibility linearization point and authoritative temporal source for each role, scope and assignment predicate.
3. Choose a reviewed pre-lock order or an approved temporal snapshot mechanism that preserves the source event's transaction-time semantics.
4. Include every implicit FK KEY SHARE, unique-index, trigger and helper-function edge.
5. Prove CMD-052 and CMD-054 consume snapshots without acquiring lower-ranked domain resources after queue/policy/notification locks.
6. Recompute the complete graph and execute deterministic opposing-transaction tests.

**Current disposition:** 40/40 domain command event declarations mapped to candidate lock paths in LOCK-MANIFEST-001 v0.4.27. Recipient resolver lock-set coverage is incomplete; event allowlist/selector grammar and asynchronous finalizer event cardinality remain open. Candidate relation/header fields remain NOT ADMITTED and excluded from the canonical 48-table inventory. QA TC-NOTIF-001..041 and related RLS/function-security tests remain PLANNED / NOT EXECUTED. G9 NOT READY; G10 NOT ACTIVE; application lock certification 0/50.


## 18. Recipient-resolver lock-set review — 2026-11-24

[NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001](NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) v0.1.5 is the engineering review of the 40 source command resolver lock paths. It distinguishes existing actor/target authorization locks from the complete candidate recipient set and records 0/40 resolver paths certified. It proposes a candidate global L05 audience guard before source locks, or an approved SERIALIZABLE alternative, then deterministic FK parent pre-acquisition and post-lock predicate revalidation. This is not an approved lock recipe. The PO must approve event-time linearization and post-transition audience semantics; Engineering/Database/Security must select the serialization mechanism and prove every writer participates. CMD-052 remains a separate claim/commit then fan-out transaction; CMD-054 must acquire the approved audience serialization boundary before mutable notification/recipient locks; CMD-053 remains provider dispatch/callback and is not a recipient resolver. Candidate relation/header remain NOT ADMITTED. QA TC-NOTIF-001..041 and related RLS/function-security tests remain PLANNED / NOT EXECUTED. G9 NOT READY; G10 NOT ACTIVE; application lock certification 0/50.


### Recipient-resolver QA linkage — 2026-11-24

QA v0.4.4 adds TC-NOTIF-042..051 for source-event recipient resolution versus role/account/scope/assignment/capacity/parent changes, overlapping producers, CMD-052 fan-out, CMD-054 scheduler publication/revocation races and atomic rollback/retry. All remain PLANNED / NOT EXECUTED. The tests are conditional on approval of the event-time linearization and resolver serialization mechanism; they do not approve L05, SERIALIZABLE isolation, schema or runtime implementation.


## 18.1 PO selection of resolver serialization candidate — 2026-11-24

PO selected the global transaction-scoped audience guard (candidate L05) as the primary mechanism for technical approval review. Option B SERIALIZABLE remains a contingency alternative only; do not combine the mechanisms without a separately reviewed design. See [NLA-RESOLVER-LOCK-001 v0.1.6](NOTIFICATION-RECIPIENT-RESOLVER-LOCK-SET-REVIEW-001.md) §11. This is not final technical approval: exact PostgreSQL primitive/key, canonical rank, every eligibility-writer path including CMD-051, FK parent order, timeout/retry, throughput bounds and full acyclicity remain under Engineering/Database/Security review. No schema, lock rank, SQL or implementation is admitted. Candidate snapshot relation/header remain NOT ADMITTED; QA remains PLANNED / NOT EXECUTED; G9 NOT READY; G10 NOT ACTIVE.


## 18.2 L05 technical protocol proposal — 2026-11-24

[NLA-L05-TDR-001 v0.1.0](NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md) specifies the proposed transaction-level audience guard primitive, key registry requirements, READ COMMITTED snapshot rule, CMD-051 participation, CMD-052/CMD-054 boundaries, FK edge review and adversarial tests. This remains a technical proposal pending Engineering/Database/Security approval. No exact key constants, timeout/retry values, audience cap, performance SLO, schema or function is admitted. Candidate snapshot relation/header remain NOT ADMITTED; QA remains PLANNED / NOT EXECUTED.


## 19. Current L05 review baseline — 2026-11-24

Current controlled L05 references are:
- Resolver review NLA-RESOLVER-LOCK-001 v0.1.10.
- Technical decision record NLA-L05-TDR-001 v0.1.8; parent resolver review v0.1.11.
- Source-event path map NLA-L05-SOURCE-MAP-001 v0.1.0.
- Eligibility-writer matrix NLA-L05-WRITER-MATRIX-001 v0.1.4.
- LOCK-MANIFEST-001 v0.4.30 §7.7 and §7.13; LOCK-GRAPH-001 v0.4.23 §§28–30.
- RTM-001 v0.1.12; RAID-001 v0.1.11; QA Catalogue v0.5.2; L05-REVIEW-001 v0.1.7; DGA-001 v1.11.73; NLA-EVENT-TRIAGE-001 v0.1.1; SCOPE-RECON-001 v0.1.2; POQ-04 PO APPROVED.

Earlier dated sections retain the versions that were actually reviewed at those checkpoints and are historical, not current pointers. The CMD-031–040 overlay remains candidate-only; 0/40 resolver paths and 0/50 application commands are certified. Candidate snapshot relation/header remain NOT ADMITTED. NRL-T01..T13 and TC-NOTIF-001..074 remain PLANNED / NOT EXECUTED. G9 NOT READY; G10 NOT ACTIVE.


## 20. POQ-04 event-transition recipient semantics — PO APPROVED (2026-11-24)

The Product Owner approved all five transition outcomes in DECISION-REGISTER.md POQ-04 without changes. The immutable event-time candidate audience is evaluated against serialized pre-mutation state at the single captured `audience_evaluated_at`; the source mutation, canonical event and candidate snapshot must commit atomically. Actor, target and affected member are included only when selected by the exact approved event selector; no participant is implicitly appended. Dispatch-time account, channel, consent/revocation, current-scope and mandatory security checks may suppress an existing candidate but must never widen the audience. Retries reuse the original candidate set and checkpoint.

The approved transition-specific assertions are: (1) role revoke — target only if selected and eligible pre-revoke; actor not auto-added; current role/scope may suppress; (2) account reject/disable/suspend — snapshot may retain a selected pre-transition candidate, suppress while not enabled, and permit a later retry only for that same candidate after reactivation; (3) assignment-member end — evaluate pre-end membership at the captured instant using half-open effective intervals; current scope may suppress, with no substitute member; (4) project/session close — evaluate pre-close parent state and commit snapshot with closure event; current active-scope policy may suppress, with no post-close additions; (5) self-revoke — actor only if exact selector independently selects under pre-revoke eligibility, followed by current role/scope revalidation.

This PO approval settles product semantics only. Selector grammar, physical snapshot schema, source-path and writer participation, lock ordering, function/RLS/ACL details, technical approval and runtime evidence remain OPEN. F-05 remains OPEN pending Security/Engineering validation; G9 NOT READY; G10 NOT ACTIVE.


## 21. F-05 technical validation addendum — selector, suppression and audit

POQ-04 is approved, but its exact technical enforcement remains open. The selector sentence in §5.2 is a category-level constraint, not a complete executable grammar. Before technical approval, Engineering/Security must define a versioned event allowlist and typed selector grammar, including allowed principal/scope references, actor/self/target treatment, boolean composition, null behavior, effective-time boundaries, canonicalization, deduplication, complexity/cardinality bounds, and fail-closed validation. The exact set of referenced columns/tables must feed the L05 eligibility-writer inventory.

Dispatch checks must be defined per event/selector. A captured qualification predicate is not automatically equivalent to a current authorization predicate. In particular, a role-revocation notice and a project/session-closure notice must not be accidentally suppressed by a blanket rule that requires the revoked role or active parent to remain true. Conversely, notification delivery must never grant access to the underlying resource; resource access is independently authorized when the notice is opened.

Suppression requires stable reason codes and a deterministic state transition. The approved account-reactivation allowance is limited to an existing immutable candidate; it does not authorize rebuilding the audience, resetting the snapshot, bypassing consent/channel/security checks, or clearing unrelated suppression reasons. Retry limits, expiry, owner, backoff and the set of reschedulable reason codes remain unapproved technical/operational inputs.

Every suppression and retry attempt must be auditable through append-only outcome evidence bound to the source event, outbox, immutable candidate, pinned policy and attempt/checkpoint. The exact reason-code catalog, correlation fields, identity provenance, retention and data-minimization rules remain to be reviewed by Security and the applicable Records/Privacy authority.

See NLA-L05-TDR-001 v0.1.8 §4.2.4–4.2.6 for F05-T1..T5, candidate selector grammar and event-specific dispatch profiles. Until these are approved and evidenced, F-05 remains OPEN; the candidate snapshot relation/header remains NOT ADMITTED; G9 NOT READY and G10 NOT ACTIVE.


## 22. Selector registry and event-specific dispatch profiles — F-05 candidate

NLA-L05-TDR-001 v0.1.8 §4.2.5–4.2.6 defines a bounded review-candidate grammar with only ROLE_SCOPE and EVENT_PARTICIPANT clauses. It is not approved for publication or implementation. A selector is not executable policy until an exact event-to-selector registry entry exists.

The registry must bind an exact canonical event token to its source transaction/worker, grammar version, permitted clause kinds, source-scope binding, participant field mappings, dependency references and dispatch profile. Source map v0.1.0 is only a CMD/event declaration inventory; it does not itself enable notifications. Composite/conditional event declarations must be split into exact tokens and mapped before enablement. No wildcard, prefix event matching, arbitrary JSON path or SQL expression is permitted.

Dispatch profiles must separately state account, channel, consent, mandatory security, current role/scope, parent-state, retry and suppression-reason predicates. In particular:
- a role-revocation notice must not require the revoked role to remain effective merely to deliver the notice;
- an assignment-member-end notice must not universally require current membership in the ended assignment;
- a project/session-closure notice must not be suppressed by a blanket current-active-parent predicate;
- account reactivation may reconsider only a candidate already in the immutable snapshot and cannot clear unrelated restrictions.

The source resource is independently re-authorized when opened. Notification delivery is not an access grant. The candidate grammar's eight-clause bound is a review proposal only and requires Engineering resource validation plus Security/PO approval. F-05 and F-04 remain OPEN; no physical schema, selector registry table, SQL, migration or runtime behavior is admitted by this document.


## 23. PRD domain and recipient scope guard — SCOPE-RECON-001

[PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001](../01-product-requirements/PRD-SCOPE-AND-NOTIFICATION-DOMAIN-RECONCILIATION-001.md) v0.1.0 is the static scope reconciliation for this notification workstream. The product's initial instrument rollout is IFP and Standing Bracket. The PRD actor set is Project Sponsor, Product Owner, Super Admin, Admin/Korlap, Inspector, Reviewer, Print Officer and the proposed Attendance Verifier (authority OPEN). The canonical permission/grant matrix remains NOT APPROVED; these actor descriptions do not create grants or recipient eligibility.

No Principal/Kepala Sekolah, teacher, student, parent or school-customer persona is defined as an application role or default notification recipient by the PRD. Institutional affiliation or being named in an inspection context does not create application identity, permission, scope or notification eligibility. Adding such a persona/workflow/audience requires formal PRD change control and Product Owner approval.

The CMD-001–040 source map is a producer/event declaration inventory, not a notification allowlist. CMD-041–044 read-side activity does not gain notification side effects by inference; CMD-045–048 require separate control-plane review; CMD-049–054 remain excluded from ordinary matching by default to avoid recursion. No event is enabled merely because it appears in a command catalogue. Only exact event tokens with approved product purpose, participant mapping, scope selector, dispatch profile and required technical approvals may be enabled.

Do not mechanically convert all 40 source commands into notification triggers. Prioritize review of actual IFP/Standing Bracket operational workflows (assignment, inspection submission, review/return/approval, and explicitly approved document/attendance workflows), but keep every event `UNRESOLVED — NOT ENABLED` until the exact event allowlist and recipient intent are approved. Notifications remain advisory delivery artifacts: they do not mutate inspection outcomes or grant access to underlying resources.

SCOPE-RECON-001 is a scope-control review artifact, not a PRD amendment, PO approval, role grant, enabled event registry, technical sign-off or implementation authorization. F-05 and F-04 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.


## 24. Product workflow event triage — NLA-EVENT-TRIAGE-001

[NLA-EVENT-TRIAGE-001](NOTIFICATION-EVENT-CANDIDATE-TRIAGE-001.md) v0.1.1 audits each CMD-001–040 event declaration against the PRD's actual inspection workflows. It classifies source declarations as PO discussion candidates, operational/control events, excluded ordinary events or unresolved composite/conditional tokens. This is not an enabled event allowlist.

The Product Owner approved the eleven first-batch candidate intents on 2026-11-24 for registry specification and technical review only: account.approved, account.rejected, role.revoked, project.closed, exact final session.closed (not session.close_requested), assignment.created, assignment.changed, inspection.submitted (inspection_revision.created remains a related fact, not a second notice), inspection.returned_for_correction, inspection.approved and inspection.reopened. This does not approve event publication, recipient mappings, channels or technical admission. All eleven rows remain UNRESOLVED — NOT ENABLED in NLA-EVENT-REGISTRY-001 v0.1.0.

No notification should be emitted for generic project/session updates, instrument draft/configuration edits, unit registration/association/claim mechanics, inspection draft saves, upload intents, evidence-upload confirmations, print audit events, or read-side operations unless a separate approved product requirement establishes a concrete human action. Batch envelopes and per-item domain events must remain distinct. Attendance Verifier remains proposed with authority OPEN and cannot be used as a recipient role.

Composite/conditional source declarations are not policy keys. Exact token and transaction decomposition is required for CMD-004, CMD-006/007, CMD-013, CMD-017, CMD-019, CMD-022, CMD-024/025, CMD-026, CMD-029, CMD-035/036, CMD-038 and CMD-039. Unknown or ambiguous tokens remain `UNRESOLVED — NOT ENABLED`. No slash-alternative, wildcard, prefix or generic command-to-event mapping is permitted.

The IFP instrument source remains draft; its photo-slot required status is OPEN. Standing Bracket's 19-row checklist baseline is PO-confirmed, but evidence/photo rules remain OPEN. Neither instrument checklist/evidence details nor a photo slot is a notification event. Notification payloads must not include evidence bytes or permanent evidence URLs.

The PO decision is recorded in DECISION-REGISTER.md. NLA-EVENT-REGISTRY-001 v0.1.0 is a draft inventory for specification/review only. Engineering/Security/Database must complete exact event contract, participant mapping, selector dependency, deduplication, atomicity and dispatch profile review before any row can be technically admitted. F-05/F-04 remain OPEN; no physical schema, SQL, migration or runtime behavior is admitted.


**Current pointer synchronization — 2026-11-24:** NLA-001 v0.1.21; NLA-L05-TDR-001 v0.1.8; L05 source map v0.1.0; writer matrix v0.1.4; QA v0.5.3; L05 review v0.1.7; DGA v1.11.74; SCOPE-RECON-001 v0.1.2; NLA-EVENT-TRIAGE-001 v0.1.2. TC-NOTIF-001..072 remain PLANNED / NOT EXECUTED. This pointer refresh does not close F-05/F-04 or enable any event.


## 25. PO-approved event candidate registry — specification only

The Product Owner approved exactly eleven first-batch event candidate intents for registry specification and technical review only. The decision is recorded in `docs/00-project-charter/DECISION-REGISTER.md`; the draft inventory is [NLA-EVENT-REGISTRY-001](NOTIFICATION-EVENT-REGISTRY-001.md) v0.1.0. The approved set is account.approved, account.rejected, role.revoked, project.closed, final session.closed, assignment.created, assignment.changed, inspection.submitted, inspection.returned_for_correction, inspection.approved and inspection.reopened.

All eleven rows remain `UNRESOLVED — NOT ENABLED`. This PO decision does not establish canonical source contracts, event fields, recipient mappings, selectors, dispatch profiles, channels, templates, grants, publication or implementation. `account.requested` remains deferred, neither approved nor rejected. `session.close_requested` is not the final `session.closed`; `inspection_revision.created` is not a second approved notice. F-05/F-04/F-03/F-07 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.

## 26. F05-T4 append-only audit evidence refinement — 2026-11-25

NLA-L05-TDR-001 v0.1.13 §17 defines the candidate logical evidence envelope for notification attempts and suppression/reconciliation outcomes. Delivery attempts remain in dedicated append-only `notification_delivery_attempts`; security/governance actions remain in canonical `audit_events`; routine retries/callbacks do not flood the general audit stream. Candidate suppression/reschedule evidence must preserve the original source-event/outbox/candidate/policy/delivery/checkpoint correlation chain. Its final physical representation remains a Database decision and the candidate snapshot relation/header remains NOT ADMITTED.

Actor provenance is server-derived for users, authenticated for internal workers and provider-validated for callbacks. Worker lease-generation fencing prevents stale outcomes. Timestamps are server/database UTC instants; they do not alone establish concurrency-safe ordering. Committed evidence is corrected additively, never updated/deleted in place. Message bodies, inspection/evidence content, tokens, credentials, signed URLs, raw idempotency keys and full provider responses are excluded.

Stable literal reason codes, physical constraints/ACL, integrity verification mechanism, and the exact evidence representation remain subject to Security/Engineering/Database review. T-10 classification, retention, legal hold, disposition, audit access/export and network metadata remain BLOCKED pending written institutional approval; no duration or purge policy is set. TC-NOTIF-095..099 are specification cases only. F05-T4 and F-05 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.


## 27. F05-T5 atomicity and immutable snapshot binding — candidate (2026-11-25)

NLA-L05-TDR-001 v0.1.14 §18 defines the candidate logical transaction boundary for each eventually admitted notification source event. The source-domain mutation, canonical event, required audit evidence, idempotency outcome, outbox intent, exact immutable policy-version reference, complete event-time candidate recipient/scope set and initial checkpoint must commit together or roll back together.

The producer evaluates the complete candidate set against the serialized pre-mutation state using one database-controlled UTC `audience_evaluated_at`, captured immediately after the separately approved audience-serialization point. That same instant governs every effective-time predicate and policy-effective selection. A fully evaluated empty audience is distinct from an incomplete/failed snapshot; unresolved mappings or integrity errors fail the source transaction closed.

After commit, fan-out and retries consume only the committed immutable snapshot and checkpoint. They never re-resolve membership, widen/substitute recipients, reset the checkpoint or create another source event/outbox. Provider I/O remains outside the source transaction. Exact producer contracts, policy/selector registry, physical snapshot/header, uniqueness and digest format, FK/trigger/helper graph, lock rank, writer coverage and Database/Security approvals remain OPEN.

TC-NOTIF-100..105 are planned acceptance cases only. F05-T5 and F-05 remain OPEN; resolver certification 0/40; application lock certification 0/50; global lock graph NOT PROVEN ACYCLIC; candidate snapshot relation/header NOT ADMITTED; G9 NOT READY; G10 NOT ACTIVE.


## 28. Implementation-entry readiness cross-reference — 2026-11-25

The current F05-T4/T5 candidate specifications and their remaining technical admission criteria are consolidated in [IER-001](../00-project-charter/IMPLEMENTATION-ENTRY-READINESS-AND-BLOCKER-PLAN.md) v0.1.0 and DGA-001 v1.13.1. Current linked baselines: NLA-L05-TDR-001 v0.1.14; QA v0.7.3; RTM-001 v0.1.32; RAID-001 v0.1.29.

F05-T1..T5 remain OPEN; no event candidate is technically admitted or enabled. F-04 writer inventory is incomplete; F-03 resolver certification is 0/40, application lock certification 0/50 and global graph acyclicity is NOT PROVEN. F05-T3 retry transition, F05-T4 physical evidence/T-10 approval and F05-T5 producer/snapshot/lock proof remain blocking. G9 NOT READY; G10 NOT ACTIVE. This pointer does not authorize event publication, physical schema, SQL, migration, grants/RLS, provider setup or runtime behavior.


## 29. Technical SSOT Closure — F05-T1 through F05-T5 & NLA-MVP-001 Admission (2026-11-27)

Pursuant to Product Owner decision `NLA-MVP-001` (2026-11-27), this section closes the technical design of `DGA-B13` and `F05-T1` through `F05-T5` for **Full-System Technical SSOT (`G9-TECH`)**:

1. **`F05-T1` (Selector Grammar):** Canonical JSON selector grammar v1 (strict object keys, duplicate-key rejection before parsing, exact canonical role/scope identifiers, `ROLE_SCOPE` and `EVENT_PARTICIPANT` clauses, deterministic sorting) is adopted for `NREG-001..011`.
2. **`F05-T2` (Event-Specific Dispatch Profiles):** All eleven `NREG-001..011` source events emit to the transactional `notification_outbox` + immutable `notification_outbox_recipients` snapshot inside their owning source command (`CMD-002/003`, `CMD-010`, `CMD-013`, `CMD-014/015`, `CMD-029/030/031/032`, `CMD-055/056`). In-app delivery is enabled in MVP; external email/push channels remain feature-flagged OFF until `T-10`/`T-12`.
3. **`F05-T3` (Retry State Machine — `SENDING` Gap Closed):** The canonical `notification_deliveries.status` state graph is formally closed as:
   - `PENDING → SENDING` (claimed under `lease_generation`)
   - `SENDING → SENT | DELIVERED | SUPPRESSED | UNKNOWN | RETRY_WAIT | FAILED | DEAD_LETTER`
   - `RETRY_WAIT → SENDING` (when `now() >= next_retry_at` and `attempt_count < max_attempts`; bounded exponential backoff defaults: `max_attempts = 5`, max retry horizon 24h, configurable per immutable policy version)
   - `UNKNOWN → DELIVERED | FAILED | DEAD_LETTER` (via authenticated reconciliation / `INT-NOTIF-001` once external provider is approved).
   - Quiet hours defer eligible external delivery only (`RETRY_WAIT`) and never pause or reset `ELAPSED_UTC` SLA (`POQ-02`).
4. **`F05-T4` (Append-Only Audit & Attempt Evidence):** `notification_delivery_attempts` and `notification_escalation_events` are append-only (`NONE` browser DML, `app_worker_definer` insert-only), storing sanitized reason codes, correlation IDs, lease generation, and server UTC timestamps with zero secrets, signed URLs, or sensitive message payloads. Retention/purge remains disabled until written `T-10` approval.
5. **`F05-T5` (Atomic Snapshot Binding):** `notification_outbox_recipients` is formally admitted into `Physical Schema v1.0.0` (table #62) and `RLS Catalogue v1.0.0`. Source commands capture one DB UTC `audience_evaluated_at` and write source state + canonical event + audit + idempotency + `notification_outbox` + `notification_outbox_recipients` atomically without backward lock acquisition (`NLA-L05-WRITER-MATRIX-001` v1.0.0 §11.2). Empty evaluated audiences are explicitly marked `audience_empty = true` on `notification_outbox` to distinguish from incomplete materialization.

**Closure disposition (2026-11-27):** `DGA-B13` technical design (`F05-T1..T5`) is **CLOSED** for `G9-TECH` freeze. External provider dispatch (`CMD-053` external adapters & `INT-NOTIF-001`) remains gated until `T-10`/`T-12`; `TC-NOTIF-001..105` execution remains gated to `G11`.
