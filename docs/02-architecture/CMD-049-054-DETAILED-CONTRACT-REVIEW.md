# CMD-049–054 Detailed Contract Review

**Document ID:** CMD-REVIEW-049-054  
**Version:** 0.1.3  
**Status:** Engineering contract review — proposal only; PO/security/institutional review required; NOT approved for implementation  
**Date:** 2026-11-24  
**Scope:** CMD-049 through CMD-054  
**Repository phase:** Documentation / SSOT maturation  
**Controls:** INS-015; INS-016 / T-15; T-10; T-18; NLA-001 v0.1.4; POQ-01..03 approved 2026-11-24; DGA-B09, DGA-B10, DGA-B11, DGA-B12, DGA-B13; G9 NOT READY; G10 NOT ACTIVE.

## 1. Purpose and authority boundary

This document expands the six proposed notification commands in the PostgreSQL Command Contract Catalogue. It is a static engineering review of NLA-001, the command catalogue, physical schema proposal, Decision Register, DGA-001 and repository governance.

INS-015 product behavior is PO-approved. NLA-001 lifecycle and PO-approved product semantics are recorded; the physical snapshot representation, selector grammar, worker model, permission grants, provider choices, retention, routes, function signatures and runtime controls remain proposals or open approvals. This document does not authorize SQL, migrations, functions, routes, grants, RLS changes, provider setup, workers, deployment, CI execution or merge.

Stable logical IDs CMD-049–054 extend CMD-001–048. They do not imply physical function names or HTTP routes. The permission registry and role/grantor matrix remain draft; proposed permission labels are not approved for seeding.

## 2. Approved behavior and non-negotiable invariants

The implementation, if separately authorized, must preserve the approved INS-015 direction:

1. In-app inbox is the primary channel.
2. Browser/device push is optional and requires capability and consent.
3. Email is for policy-defined important notices and an approved verified address.
4. WhatsApp is excluded from MVP.
5. Recipient selection is role- and assignment-scoped; role membership alone never creates global broadcast authority.
6. Priority, recipient selectors, channels, quiet hours, reminders, SLA thresholds and escalation paths are configurable.
7. Delivery state and recipient read state are independent facts.
8. Failed external sends retry idempotently, with bounded policy and explicit uncertain outcomes.
9. Notifications never create, approve, return, reopen, pause, close or otherwise mutate inspection, project or session state.
10. Policy changes and escalation decisions are versioned and audited.
11. Illustrative SLA/retry values are not production constants.
12. A notification is not an authorization token: opening its referenced resource requires fresh authorization.

The following are mandatory safety boundaries:

- No browser-callable access to internal worker operations.
- No browser-held service-role key and no ordinary user JWT treated as a worker credential.
- PostgreSQL derives user actor identity from trusted auth context for user commands.
- Worker identity, scheduler trust, database role, function owner, exact EXECUTE ACL, secret custody and rate limits require independent T-18 security approval.
- Provider I/O occurs outside database transactions.
- No exactly-once delivery claim across external providers.
- Audit/outbox failure must fail the originating business mutation where NLA-001 requires atomicity.
- T-10 institutional classification, retention, deletion/disposition, legal hold, audit access/export and network metadata remain blocked.
- No live schema, RLS, grants, worker or provider capability is verified by this document.

## 3. Source and authority reconciliation

| Source | Current authority | Consequence for CMD-049–054 |
|---|---|---|
| INS-015 | APPROVED at PO level | Product behavior is binding within PO authority |
| INS-016 / T-15 | PO-approved audit direction | Append-only audit and critical mutation/audit atomicity direction; T-10 details remain blocked |
| NLA-001 v0.1.4 | PO semantics approved; engineering design proposal | Six canonical notification tables plus one candidate-only audience snapshot relation; physical representation/worker controls require Engineering/Database/Security review |
| Command catalogue v0.4.8 | Proposed logical contracts | IDs are stable; permission labels and transport mappings remain unapproved |
| Physical schema v0.4.4 / RLS v0.2.5 | Proposed physical inventory | Six notification tables are canonical proposal; notification_outbox_recipients and audience header fields are candidate-only, not admitted or live objects |
| DGA-B13 | DESIGN PROPOSAL RECORDED; APPROVALS OPEN | Worker, selectors, providers, T-10 and cross-document approvals remain open |
| T-18 | PO direction approved | Per-function worker/user boundary and actual ACL still require review |
| G9 / G10 | NOT READY / NOT ACTIVE | No implementation or release work may begin |

## 4. Shared notification domain model

### 4.1 Lifecycle and ownership of facts

NLA-001 proposes the following separation:

| Concern | Proposed authoritative object | Invariant |
|---|---|---|
| Event-to-notification intent | notification_outbox | Created atomically with the source domain mutation, canonical event and required audit |
| Recipient inbox | notifications | One recipient-specific row per outbox/recipient; read state belongs to the recipient |
| External channel delivery | notification_deliveries | One delivery projection per notification/channel; not equivalent to read |
| Delivery attempt history | notification_delivery_attempts | Append-only sanitized attempt evidence |
| Policy configuration | notification_policy_versions | Published policy versions immutable and scope-bound |
| Reminder/escalation decision | notification_escalation_events | Append-only, policy-version-pinned; never changes business state |

The six canonical notification objects are proposed, not implemented. POQ-01 additionally requires an immutable event-time recipient/scope snapshot; candidate relation notification_outbox_recipients and candidate outbox snapshot header fields are NOT ADMITTED and excluded from the canonical 48-table inventory. Composite FKs, indexes, check/enum constraints, uniqueness, policy immutability, recipient predicates and worker access require Engineering/Database/Security review.

### 4.2 Critical transaction and external effects

The intended sequence is:

1. An authorized domain command performs the business mutation.
2. The same PostgreSQL transaction appends the canonical domain/audit event and, if policy matches, a minimal outbox intent pinned to one immutable policy version.
3. At source-event time, the source command resolves and durably persists the deduplicated recipient/scope candidate set and snapshot hash/count before its transaction commits. CMD-052 later consumes that immutable set; it does not resolve current membership.
4. Recipient inbox rows and eligible external channel delivery rows are created idempotently.
5. A delivery worker claims a delivery row, records a durable attempt boundary, performs provider I/O outside the transaction and persists a guarded outcome.
6. Ambiguous provider acceptance is represented as UNKNOWN and reconciled; it is not mislabeled as success or guaranteed exactly-once.
7. Scheduler evaluation records a version-pinned escalation decision and may enqueue another notification. It does not mutate the source business state.

A database transaction cannot atomically include external provider acceptance. The design must make each durable boundary, lease, retry, idempotency key and compensation/reconciliation path explicit.

### 4.3 Data minimization

Notification titles, body keys and safe payloads must contain only the minimum approved information. Prefer opaque resource references and re-authorize on navigation. Do not copy evidence, full inspection answers, sensitive personal records, secrets, JWTs, provider credentials or signed URLs into inbox content, delivery attempts, telemetry or general audit payloads.

T-10 must approve classification, purpose, content minimization, retention, deletion/disposition, legal hold, audit access/export and network/time-zone metadata before production use.

## 5. CMD-049 — list-own-notifications

### 5.1 Intent and status

Read a bounded, paginated inbox belonging exclusively to the authenticated recipient. The catalogue assigns the proposed permission label notification.read and limits ownership to auth.uid(). This is a user-facing read operation, not an administrative search.

### 5.2 Proposed request

Catalogue fields:
- cursor, optional;
- limit;
- unread_only, optional.

The exact schema is not approved. Enforce a server-defined maximum page size and allowlisted filters. A cursor must be opaque or integrity-protected and bound to authenticated recipient identity, normalized filters, sort order and cursor version. Reject a cursor issued for another actor or filter set.

The request must not accept recipient_user_id, actor_id, role, scope, project visibility override or arbitrary source-resource query. Recipient identity is derived from trusted auth.uid().

### 5.3 Proposed response

Return only the current recipient's inbox fields needed for display:
- notification identifier;
- event type and priority;
- safe title/body keys and minimized safe payload;
- created/expiry timestamps;
- read/dismiss state if dismissal is approved;
- opaque resource reference only where policy permits.

Do not return provider credentials, delivery provider payloads, internal lease fields, worker identifiers, unrestricted source-event payloads or evidence. Delivery state is a separate concern and should not be exposed unless a UX decision and policy explicitly define which safe status fields are useful.

### 5.4 Authorization and RLS

- Require authenticated user context.
- Enforce recipient_user_id = auth.uid() at the authoritative query boundary and RLS.
- Project/session/location filters may narrow the caller's own inbox; they must never widen recipient ownership.
- Do not infer read permission from role membership or a notification's referenced resource.
- Clicking a notification must independently authorize the target resource.
- A forged notification ID or cursor must not reveal whether another user's notification exists.
- Permission registry role grants remain unapproved. The self-only predicate is a resource ownership invariant, not permission to browse other recipients.

### 5.5 Physical query and consistency

Proposed read set: notifications, with any minimal policy-safe joins required for display. No mutation is allowed. Use stable deterministic ordering, such as created_at plus immutable id, with a cursor that preserves ordering across pages. Define how concurrent inserts and read-state changes affect page consistency; do not claim a snapshot across pages unless the query mechanism provides one.

The schema lists recipient_user_id, created_at, expires_at, read_at and dismissed_at. Exact indexes for recipient + ordering + unread filtering, composite scope integrity and RLS predicates remain to be reviewed.

### 5.6 Audit and privacy

NLA-001 allows inbox-access auditing only if approved policy requires it. The catalogue references notification.inbox_accessed. Reconcile whether every page read is audited or whether privacy-safe aggregate telemetry is sufficient; do not create high-volume audit noise or recursively audit the audit stream. T-10 controls retention and metadata.

### 5.7 Required tests — planned only

- recipient A cannot list recipient B's inbox;
- anonymous, suspended or disabled account is denied;
- cursor cannot cross recipient identity or filters;
- tampered/expired cursor is rejected safely;
- unread filter and stable pagination work under concurrent insert/read changes;
- project/session/location filters only narrow self-owned rows;
- notification navigation re-authorizes source resource;
- safe payload contains no evidence, secret or unauthorized source data;
- RLS/direct query cannot enumerate other recipients.

Existing mapping: TC-NOTIF-018 and TC-NOTIF-005/006/016 as applicable. **PLANNED / NOT EXECUTED**.

## 6. CMD-050 — mark-notification-read

### 6.1 Intent and status

Set the read state for one notification owned by the authenticated recipient. It must not change channel delivery state or any inspection/project/session state. The operation is intended to be idempotent and non-enumerating.

### 6.2 Proposed request and response

Canonical request after documentation reconciliation:
- notification_id only.

The physical notifications proposal has no version column. CMD-050 is a recipient-owned set-once read_at transition, so an expected_version field is removed rather than adding an unnecessary high-volume inbox version column. The guarded read_at IS NULL update is the state arbiter.

Successful response should contain a typed MARKED_READ result, notification identifier and server-generated read timestamp, with a stable idempotent replay indication if supported. It must not return or modify delivery state.

### 6.3 Authorization and state rules

- Derive actor from auth.uid(); require notification recipient_user_id to equal that actor.
- Never accept recipient_user_id, actor_id, role or target read timestamp from the client.
- A repeated mark-read request is idempotent and must not create multiple read transitions.
- The operation sets read_at once using server UTC. It must not clear read_at or provide an unread/reset operation.
- A forged or foreign notification ID returns a non-enumerating NOT_FOUND/DENIED outcome.
- A role or assignment change does not transfer inbox ownership.
- Expired/dismissed behavior must be defined by UX/PO policy; expiry must not silently create a business-state transition.

### 6.4 Physical write and transaction

Proposed read/write set: one notifications row. Use a guarded recipient-owned update and ensure RLS independently enforces recipient ownership. The update should be monotonic and idempotent. Do not update notification_deliveries, notification_delivery_attempts, outbox, escalation history or source business tables.

The canonical audit event is notification.read, emitted once only when the first set-once transition changes read_at from NULL. The event and state transition commit atomically; a required audit failure rolls back the read transition. Repeated/no-op acknowledgements emit no duplicate event. Inbox page access is not a general audit event; use only privacy-safe aggregate telemetry if operationally needed. This is a design reconciliation, not a deployed audit control.

### 6.5 Required tests — planned only

- recipient can mark own notification read;
- recipient cannot mark another user's notification read;
- repeated same request is idempotent;
- client-supplied read timestamp/actor/recipient is rejected;
- notification delivery state remains unchanged;
- source business state remains unchanged;
- concurrent duplicate requests produce one stable read timestamp;
- audit failure follows the approved fail-closed policy;
- no client-supplied actor, recipient or read timestamp is accepted; no row-version token is required.

Existing mapping: TC-NOTIF-005/007/016. **PLANNED / NOT EXECUTED**.

## 7. CMD-051 — publish-notification-policy

### 7.1 Intent and status

Publish a new immutable, scope-bound notification policy version. This is a privileged configuration operation, distinct from ordinary notification reading. The catalogue proposes notification.policy.manage, but the role/grantor/scope/SoD matrix is not approved. NLA-001 requires PO/security approval of policy administrator authority.

### 7.2 Proposed request

Canonical publish-only candidate request:
- policy_key;
- scope_type and scope_id;
- schema_version;
- policy_document;
- optional expected_current_version_id for compare-and-publish against the current published version.

The server canonicalizes and hashes the validated document; callers do not supply policy_hash or version_no.

These are proposals, not an approved API schema. The request must be validated against a versioned allowlist schema. Reject unknown fields, executable content, SQL, code templates, arbitrary routing instructions, secrets and unbounded recipient selectors. The exact selector grammar, allowed event types, priority/channel values, quiet-hours/time-zone rules, reminder schedule, SLA thresholds, escalation steps and expiry/display metadata remain PO/security decisions.

### 7.3 Draft/publish lifecycle gap

CMD-051 is explicitly scoped to publish-only: it accepts a validated candidate policy document and creates a new immutable published version. It does not persist or edit a mutable draft. The DRAFT status remains reserved in the physical proposal and is not written by CMD-051. If product UX requires persisted draft CRUD or multi-stage review, that is a separate command/workflow and schema change requiring PO/security approval before this command set is expanded.

Version allocation is serialized by the exact policy/scope aggregate boundary (the concrete lock implementation remains subject to lock review). expected_current_version_id prevents a stale publisher from silently overwriting a newer current version. The server canonicalizes the allowlisted document, computes policy_hash, assigns the next version and validates effective interval overlap. The unique policy/scope/version constraint and approved exclusion/locking mechanism remain physical-design requirements.

A published policy document/hash/version is immutable. Retirement/supersession may change only explicitly approved lifecycle metadata and must be audited; queued outbox records retain their exact pinned policy version.

### 7.4 Authorization, scope and SoD

- Require an explicit approved notification.policy.manage grant within the exact policy scope.
- Grantor ceiling and role-to-permission mapping must be approved; no global administrator bypass is inferred.
- The caller cannot select a broader scope than their effective grant.
- Separate draft author, approver and publisher where required by approved SoD.
- Actor identity derives from auth.uid(); no client-supplied publisher identity.
- Account and grant validity must be checked at transaction time.
- Policy publication cannot retroactively rewrite existing notification/outbox behavior.

### 7.5 Physical transaction and audit

Proposed read/write set: notification_policy_versions and audit_events. Publication must atomically validate the draft/hash/version, allocate a unique version, freeze the policy document/hash, record publisher and effective interval, and append the required audit event. Published policy immutability must be enforced at the database boundary, not just UI.

The schema proposes unique policy/scope/version and one effective published version per policy/scope/time interval. Exact locking/exclusion strategy, composite scope FK and indexes are not yet approved. Do not infer a deployed constraint.

### 7.6 Required tests — planned only

- unauthorized role, wrong scope and grantor-ceiling denial;
- invalid schema, unknown key and executable/secret content rejection;
- stale expected_current_version_id and concurrent publish race;
- unique version allocation and effective-interval overlap prevention;
- published version cannot be edited/deleted;
- queued outbox retains its original policy version after a later publish;
- requestor/approver/publisher SoD;
- audit failure prevents publication;
- policy changes cannot alter inspection/project/session state;
- recipient selector cannot widen scope.

Existing mapping: TC-NOTIF-012. **PLANNED / NOT EXECUTED**.

## 8. CMD-052 — fanout-notification-outbox

### 8.1 Intent and status

An internal worker claims one bounded outbox item and materializes inbox/channel-delivery records from the immutable event-time candidate audience. It is an internal-only operation, not a user permission and not browser-callable. Worker identity and ACL remain open under DGA-B13/T-18.

### 8.2 Proposed request and principal

Catalogue fields:
- outbox_id;
- lease_token;
- worker_batch_limit.

These are internal protocol fields only. The worker principal must be independently authenticated; an ordinary user JWT, browser credential or exposed service-role key is not an acceptable substitute. The lease token must be issued/validated by a trusted claim operation and bound to the leased row, worker identity and expiry. The client must not be able to invent or extend its own lease.

No worker identity, scheduler trust model, database role, function owner or exact EXECUTE grant is approved.

### 8.3 Recipient resolution

- Resolve against the immutable policy version pinned to the outbox.
- Selector grammar must be explicit and approved; do not interpret free-form role labels.
- POQ-01 fixes the event-time candidate audience. CMD-052 consumes the immutable recipient/scope snapshot; it does not reconstruct recipients from current role/assignment membership.
- Dispatch-time account/channel/consent/revocation/security checks may suppress an original candidate's external delivery but must never add recipients or widen scope.
- Deduplicate recipients across selectors before snapshot finalization.
- An empty event-time audience produces a safe, durable zero-candidate outcome; never widen scope to make fan-out succeed.
- Store only minimum recipient/scope snapshot evidence and safe reason codes.

### 8.4 Physical write set and transaction

Proposed objects: notification_outbox, candidate-only notification_outbox_recipients (NOT ADMITTED), notifications and notification_deliveries. The source domain transaction must persist the event-time candidate rows and snapshot header hash/count/completion marker before the outbox is claimable. CMD-052 claims the outbox with a bounded lease and row-locking strategy equivalent to SKIP LOCKED, commits the claim, then consumes immutable candidates in a separate fan-out transaction. Never hold a transaction across provider I/O. Create one inbox row per outbox/recipient and one external delivery row per selected notification/channel, with uniqueness preventing duplicates.

NLA-001 v0.1.4 proposes unique source_event_id/policy_version_id on the outbox, unique outbox_id/recipient_user_id on candidate rows and notifications, and unique notification_id/channel on notification_deliveries. Partial fan-out remains PROCESSING; retries derive outstanding work by anti-joining immutable candidate rows to existing inbox rows. The outbox and delivery lease tuple is lease_owner, server-issued token hash, monotonic lease_generation and lease_expires_at; every finalizer checks the current tuple. safe_payload is the canonical minimized payload field. Candidate FKs, scope tuple, snapshot hash/count, transaction fan-out bounds, indexes and lock-order/implicit-FK effects remain OPEN.

### 8.5 Side-effect boundary

CMD-052 performs no provider I/O. It must not send email/push, mark a delivery SENT, or alter business state. Provider dispatch belongs to CMD-053. The worker must not use a broad service role to bypass RLS; its narrowly scoped principal and execution path require separate security approval.

### 8.6 Required tests — planned only

- duplicate fan-out creates one inbox row per recipient and one delivery per channel;
- expired lease is reclaimed without duplicate effects;
- invalid/forged lease token and unauthorized worker are denied;
- recipient selector overlap deduplicates users;
- role without effective assignment scope receives no notification;
- disabled/suspended account is excluded at the approved eligibility checkpoint;
- partial batch failure is resumable and does not lose accepted intent;
- policy version remains pinned;
- no provider network call occurs in fan-out;
- no business state changes;
- audit/outbox invariants and append-only history are preserved.

Existing mapping: TC-NOTIF-002/003/004/011/015/017. **PLANNED / NOT EXECUTED**.

## 9. CMD-053 — dispatch-notification-delivery

### 9.1 Intent and status

An internal delivery worker claims one channel-delivery item, validates channel eligibility/consent/quiet hours, calls an approved provider adapter and records a sanitized attempt/result. It is not browser-callable. Provider choices/capabilities, worker identity, secrets custody and exact ACL remain open.

### 9.2 Proposed request and principal

Catalogue fields:
- delivery_id;
- lease_token;
- channel;
- notification_ref.

These fields are internal-only. The worker must be independently authenticated, and the lease must be valid for the exact delivery row and worker identity. Channel must match the persisted delivery record; it must not be caller-selected to override policy. notification_ref must resolve to the exact persisted notification, not arbitrary content.

### 9.3 Pre-dispatch policy checks

- Channel is one of the approved external channels: WEB_PUSH, DEVICE_PUSH or EMAIL.
- User/device consent and capability are current.
- Email address is approved/verified and channel eligibility permits sending.
- Push subscription is active and has not been revoked.
- Quiet hours and recipient/project time-zone policy are evaluated from the pinned policy.
- Missing/invalid time zone follows an explicitly approved safe default; no recipient locale is inferred.
- WhatsApp is excluded from MVP.
- Suppression/deferment is persisted with a safe reason code and must not be reported as provider failure.
- Revalidate recipient account/scope as required by the approved dispatch-time rule.

### 9.4 External provider and transaction boundary

Provider I/O occurs outside PostgreSQL transactions. The worker records a durable attempt identity before/around the call using an idempotency key, invokes the provider, then persists a guarded outcome. Provider idempotency is used where supported. If provider acceptance may have occurred but cannot be confirmed, record UNKNOWN and reconcile; do not claim exactly-once.

Retry policy must be bounded by approved maximum attempts, retry horizon, backoff/jitter and terminal error classification. Numeric values remain open and must not be invented from examples.

### 9.5 Physical write set and history

Proposed objects: notification_deliveries and append-only notification_delivery_attempts. Delivery projection tracks current status; attempts preserve each sanitized try. Provider callback/webhook processing is an untrusted inbound boundary and must authenticate signatures, validate provider reference and legal state transition, deduplicate callbacks and remain idempotent.

**Callback integration boundary:** provider callbacks are assigned to INT-NOTIF-001, a separately authenticated integration ingress, not a new CMD ID and not a browser-callable RPC. It validates provider signature/freshness, maps a known provider message reference to one delivery, uses a durable provider-event deduplication mechanism, and applies only allowlisted monotonic status transitions. Provider-specific authentication, event-ID persistence and dedup retention remain open until a provider is selected; no generic callback mutation path is permitted.

Never persist provider credentials, full provider response bodies, message bodies, access tokens or signed URLs in attempt history. Keep safe provider reference and error codes only.

### 9.6 Audit and state separation

Delivery state does not imply recipient read state. Provider callback must never set notifications.read_at. Delivery failure does not roll back or block the source inspection command. Routine attempts belong in the dedicated append-only attempt table; only security-relevant administration or policy decisions should enter the general audit stream as approved.

### 9.7 Required tests — planned only

- unauthorized worker and invalid/expired lease;
- channel mismatch, disabled channel and revoked consent;
- quiet-hours suppression/deferment and time-zone edge cases;
- provider accepted + worker crash yields UNKNOWN/reconciliation;
- duplicate provider callback/result is idempotent;
- retryable versus permanent error classification;
- bounded retry/dead-letter and no silent drop;
- provider secret and message body never appear in logs/audit/attempt records;
- delivery transition cannot change read_at or business state;
- external timeout and provider outage recovery;
- webhook signature validation and replay protection;
- provider idempotency behavior and duplicate tolerance.

Existing mapping: TC-NOTIF-007/009/010/015/016/017. **PLANNED / NOT EXECUTED**.

## 10. CMD-054 — evaluate-notification-escalation

### 10.1 Intent and status

An internal scheduler/worker evaluates whether a notification has reached a policy-defined reminder/SLA/escalation step. It appends an immutable decision record and may enqueue a new notification. It must never mutate inspection, project, session or assignment state.

Worker identity, scheduler authentication, SLA semantics, recipient selector rules, T-10 retention and exact ACL remain open.

### 10.2 Proposed request and trusted time

Canonical request:
- notification_id;
- policy_version_id;
- step_no.

There is no client-supplied evaluation_time. The worker captures one database-controlled UTC instant for the evaluation transaction and derives due-ness from persisted due timestamps and the pinned policy version. The worker cannot choose an arbitrary policy version or step to force escalation.

### 10.3 Due-time and policy semantics

Before implementation, approve:
- SLA clock start event and timestamp source;
- business/calendar time versus elapsed time;
- timezone and daylight-saving behavior;
- whether paused/closed/reopened business states affect reminder eligibility;
- reminder versus escalation distinction and exact step ordering;
- quiet-hour behavior and high-priority exception policy;
- maximum escalation depth and retry horizon;
- policy version pinning and treatment of policy changes while a notification is pending;
- how acknowledgement/read state affects escalation, if at all;
- expiry and terminal outcomes.

No numeric SLA, retry or escalation values may be inferred from NLA-001 examples.

### 10.4 Recipient revalidation and scope

Recipients for an escalation are resolved at that escalation event's own source-event time under the explicit policy version and approved selector grammar; persist its own immutable candidate/scope snapshot with the escalation event and outbox. Dispatch-time revalidation may suppress external delivery only and cannot widen the audience. If no eligible recipient exists at event time, append NO_ELIGIBLE_RECIPIENT and do not broaden scope. Escalation is communication workflow only; it does not grant permissions or transfer assignment.

### 10.5 Physical write set and idempotency

Proposed objects: notification_escalation_events, notification_outbox and candidate-only notification_outbox_recipients (NOT ADMITTED). Append one event for the unique notification/policy-version/step/event key, create the outbox intent and persist its event-time candidate/scope rows atomically. The uniqueness constraint makes repeated scheduler ticks idempotent.

NLA-001 proposes unique notification_id/policy_version_id/step_no/event_type. Exact locking, due-time predicate, retry, concurrent scheduler behavior, event/outbox atomicity and retention must be reviewed. No provider I/O occurs in this command.

### 10.6 Audit and state separation

Escalation events are append-only. Audit mapping is notification.escalation_evaluated. The event records safe decision metadata and policy version, not sensitive message content. A failed escalation notification must not change source business state or create a false acknowledgement.

### 10.7 Required tests — planned only

- not-due evaluation produces no escalation;
- due step enqueues once across repeated scheduler ticks;
- request schema rejects caller-supplied evaluation_time; future/past client clocks cannot manipulate due-ness;
- policy version cannot be substituted or widened;
- no eligible recipient records a terminal safe outcome without scope widening;
- account/assignment revocation is revalidated;
- concurrent schedulers cannot duplicate a step;
- outbox creation and escalation event are atomic;
- quiet-hours and paused/closed-state semantics follow approved policy;
- escalation never changes inspection/project/session state;
- audit failure and retention behavior follow approved rules.

Existing mapping: TC-NOTIF-013/014. **PLANNED / NOT EXECUTED**.

## 11. Cross-command findings and required decisions

| Finding | Commands | Gap / impact | Required closure |
|---|---|---|---|
| N49-01 | 049 | Self-only read is specified; exact index plan, maximum page size and live RLS evidence remain open | Cursor is actor/filter-bound and integrity-protected; stable (created_at, id) order; no snapshot claim; approve exact indexes/page cap and verify RLS |
| N50-01 | 050 | Previous optional expected_version conflicted with no physical row-version field | RESOLVED AT DOCUMENTATION BOUNDARY: remove expected_version; guarded set-once read_at is the concurrency/idempotency arbiter |
| N50-02 | 050 | Inbox page reads could create high-volume audit noise | RESOLVED AT DOCUMENTATION BOUNDARY: no inbox-access audit; emit notification.read once on first read-state transition only; no duplicate event on retry |
| N51-01 | 051 | Persisted mutable draft lifecycle was conflated with publish command | RESOLVED AT COMMAND SCOPE: CMD-051 is publish-only; draft CRUD is excluded and requires a separate approved command/schema if later needed |
| N51-02 | 051 | notification.policy.manage role/grantor/scope/SoD is not approved | Approve canonical permission registry and policy-administrator matrix |
| N51-03 | 051 | Exact recipient selector grammar and policy JSON schema remain open | PO/security approve versioned allowlist and validation |
| N52-01 | 052 | Worker identity, scheduler trust, database role, owner and exact EXECUTE ACL unresolved | Security-approved worker principal and least-privilege execution design |
| N52-02 | 052 | POQ-01 event-time candidate audience semantics are approved; durable representation and snapshot completeness are not admitted | Review candidate recipient/scope relation, header hash/count, source-transaction bounds and non-widening dispatch suppression |
| N52-03 | 052 | NLA/schema/catalogue payload and lease field descriptions differed | RESOLVED AT DOCUMENTATION BOUNDARY: safe_payload; lease_owner, lease_token_hash, lease_generation, lease_expires_at; partial work remains PROCESSING and resumes through uniqueness arbiters |
| N53-01 | 053 | Provider selection, capability, quota, cost and secret custody unverified | Provider decision and evidence; approved adapter/credential boundary |
| N53-02 | 053 | Provider callback/webhook operation was not assigned a boundary | RESOLVED AT INTEGRATION BOUNDARY: INT-NOTIF-001 is a separate provider-authenticated ingress, not a CMD ID or browser RPC; provider-specific signature and durable dedup remain open |
| N53-03 | 053 | UNKNOWN and bounded retry are described but numeric retry horizon/attempt policy remains open | Approve retry/UNKNOWN reconciliation policy and operations alerts |
| N54-01 | 054 | Caller-supplied evaluation_time could conflict with trusted time | RESOLVED AT REQUEST BOUNDARY: remove evaluation_time; capture one DB UTC instant. SLA start, calendar/timezone and pause/close semantics remain open |
| N54-02 | 054 | Worker/scheduler identity and ACL remain unresolved | Approve scheduler principal, lease, exact owner/EXECUTE ACL |
| N54-03 | 054 | T-10 retention/legal-hold applies to notification content and history | Written institutional classification, retention and disposition decisions |
| N49-54-01 | 049–054 | Six canonical tables plus candidate-only recipient snapshot relation/header fields; exact composite FKs, indexes, enums/checks and RLS remain proposed | Review/admit candidate notification_outbox_recipients only after source-event snapshot, scope FKs, hash/count, fan-out bounds and RLS/ACL are proven |
| N49-54-02 | 049–054 | Permission registry, worker role grants and SoD remain unapproved | PO/security approval before role seeding or worker grants |
| N49-54-03 | 049–054 | Provider capability and worker runtime evidence absent | Approved provider evidence and non-production operational verification |
| N49-54-04 | 049–054 | Tests are catalogue plans only | Execute only after G10 in authorized environment and attach evidence to exact commit/schema |

## 12. Cross-document reconciliation required

Before CMD-049–054 can be considered implementation-ready:

1. Obtain PO/security approval of NLA-001 and the exact recipient-selector grammar, event-time/dispatch-time rules, policy administrator and SoD.
2. Obtain security approval for worker/scheduler identities, authentication, database roles, function ownership, exact EXECUTE ACL, secret custody, rate limits and lease handling.
3. Obtain institutional T-10 decisions for classification, content minimization, retention, deletion/disposition, legal hold, audit access/export and network/time-zone metadata.
4. Obtain provider evidence for email and optional push capability, quotas, costs, delivery callbacks, idempotency support, failure modes and support ownership.
5. Reconcile all six proposed tables with the physical schema and RLS catalogues: exact columns, FKs, indexes, unique constraints, status values, immutability, grants and predicates.
6. Resolve CMD-050 expected_version mismatch.
7. Resolve policy draft lifecycle and policy-document schema/hash semantics for CMD-051.
8. Resolve outbox payload and lease-field discrepancies for CMD-052.
9. Add or explicitly map provider callback/webhook ingestion for CMD-053.
10. Define server-clock SLA semantics and scheduler behavior for CMD-054.
11. Reconcile event names and audit payloads with T-15 and the audit event catalogue.
12. Synchronize RTM, QA, DGA, RAID, lock manifest, audit and physical/RLS crosswalk to this proposal; accountable approvals and runtime evidence remain separate gates.
13. Reconcile POQ-01 candidate snapshot creation against the global L15–L110 resource order and implicit FK KEY SHARE edges. Do not claim the source command or CMD-052 is deadlock-safe until all recipient/account/scope locks and foreign-key checks are included in the manifest and adversarial tests.

Do not treat a notification command as a substitute for any domain command or as authority to mutate the underlying workflow.

## 13. Consolidated verification plan

All cases below are specifications, not executed evidence.

| Dimension | Minimum coverage |
|---|---|
| Recipient isolation | Self-only read/write, cross-recipient denial, cursor binding, IDOR and non-enumerating errors |
| Policy security | Role/scope/grantor ceiling, schema allowlist, immutable publish, version pinning, SoD |
| Worker security | Authenticated internal principal, lease validation, exact EXECUTE ACL, no browser exposure |
| Idempotency | Duplicate outbox, recipient/channel uniqueness, delivery attempt keys, webhook replay, escalation step uniqueness |
| Concurrency | Lease reclaim, concurrent publish, concurrent mark-read, duplicate fan-out, duplicate scheduler ticks |
| Provider effects | Consent, quiet hours, timeout, provider accepted/worker crash, UNKNOWN, retry/dead-letter, callback authentication |
| Privacy | Minimal payload, no evidence/secrets/tokens, approved retention, safe audit metadata |
| State isolation | Delivery/read/escalation cannot change inspection/project/session state |
| Recovery | Partial fan-out, expired lease, provider outage, dead-letter reconciliation and policy-version preservation |
| Operations | Backlog age, retry age, dead-letter count, provider error rate, worker health and alert routing |

Existing QA references include TC-NOTIF-001 through TC-NOTIF-018. They remain **PLANNED / NOT EXECUTED**. No unit, integration, security, concurrency, provider, UAT or operational test was run for this document.

## 14. Gate disposition

| Item | Status | Evidence boundary |
|---|---|---|
| CMD-049 detailed review | DOCUMENTED — PROPOSAL | Static review of catalogue, NLA-001 and schema proposal |
| CMD-050 detailed review | DOCUMENTED — PROPOSAL; VERSION FIELD REMOVED | Static review; set-once read_at contract aligned to physical proposal |
| CMD-051 detailed review | DOCUMENTED — PROPOSAL; AUTHORITY OPEN | Policy lifecycle and permission/SoD approval outstanding |
| CMD-052 detailed review | DOCUMENTED — PROPOSAL; WORKER SECURITY OPEN | No worker principal or ACL verified |
| CMD-053 detailed review | DOCUMENTED — PROPOSAL; INT-NOTIF-001 BOUNDARY DEFINED; PROVIDER OPEN | No provider, signature scheme or callback runtime verified |
| CMD-054 detailed review | DOCUMENTED — PROPOSAL; SLA/WORKER GAP OPEN | No scheduler identity or SLA clock approval |
| Physical schema / RLS | PROPOSED; NOT LIVE-VERIFIED | No live catalog or policy query |
| Routes / RPCs / functions | NOT APPROVED OR VERIFIED | No route/function inventory asserted; INT-NOTIF-001 is a logical integration contract only |
| Permission grants / worker ACL | NOT APPROVED OR VERIFIED | No grants or roles changed |
| Provider setup | NOT PERFORMED | No provider selected/configured |
| Tests | PLANNED / NOT EXECUTED | No test execution |
| G9 | NOT READY | NLA, T-10, worker, provider and design approvals remain open |
| G10 | NOT ACTIVE | Separate activation record required after independent G9 verification |
| Source code / SQL / migrations / grants / RLS | NOT PERFORMED | Outside authorized scope |
| Live database / provider / deployment / CI / merge | NOT PERFORMED | Outside authorized scope |

## 15. Next work

1. Perform a full CMD-001–054 cross-command reconciliation against physical schema, permission registry, RLS catalogue, audit catalogue, API/route design, RTM, QA, DGA and RAID.
2. Resolve all identified command-level mismatches and update the canonical catalogue and dependent documents through controlled change.
3. Obtain PO/security/institutional/provider decisions before treating any notification contract as approved.
4. Reassess G9 only when objective closure evidence exists. G10 remains a separate explicit authorization.

**Final boundary:** This review changes documentation only. No source code, SQL, migration, grant/revoke, RLS, Storage policy, worker, provider configuration, live database, deployment, CI execution or merge was performed.


## 16. Notification engineering reconciliation addendum — 2026-11-24

This addendum records the static contract decisions and remaining approval boundary after reconciliation with NLA-001 v0.1.4. It does not change the proposal status or authorize implementation.

| Area | Documentation-level disposition | Remaining blocker |
|---|---|---|
| CMD-049 cursor/read boundary | Self-only, actor/filter-bound integrity-protected cursor; stable (created_at, id) order; no snapshot guarantee | Exact indexes, page-size cap and live RLS evidence |
| CMD-050 read state | expected_version removed; set-once read_at; one notification.read event on first transition only | T-15 implementation verification and audit test |
| CMD-051 policy | Publish-only; server canonical hash and expected current published version; no persisted draft CRUD | Permission/grantor/SoD authority, selector schema and effective interval constraints |
| CMD-052 fan-out | Canonical safe_payload; explicit lease owner/token hash/generation/expiry; PROCESSING + unique arbiters for partial retry | Worker identity/ACL and approved hybrid event-time candidate-audience snapshot/checkpoint with dispatch-time revalidation that cannot widen recipients |
| CMD-053 delivery | External I/O outside transactions; UNKNOWN on ambiguous acceptance; INT-NOTIF-001 callback ingress | Provider choice/capability, callback signature and durable event deduplication |
| CMD-054 escalation | No caller evaluation_time; one database UTC instant per transaction | named SLA start event, per-policy elapsed/business-time mode, ELAPSED_UTC initial default, quiet-hours delivery deferral without SLA pause, and unapproved calendar/pause semantics |
| Dismissal | dismissed_at reserved only | POQ-03 approval; no dismiss command, permission or browser mutation is in MVP |

The six notification tables remain a proposed subset of the 48-table physical/RLS inventory. INT-NOTIF-001 is an integration contract, not a new CMD ID or table. TC-NOTIF-001..040, TC-RLS-024-049 and TC-FN-SEC-025-064..071 remain PLANNED / NOT EXECUTED. Worker identities, exact function owners/EXECUTE ACLs, live RLS/grants, provider capability and T-10 institutional retention/privacy remain open. G9 NOT READY; G10 NOT ACTIVE.


## Product Owner notification decisions — POQ-001 (2026-11-24)

POQ-01 Option C, POQ-02 Option C and POQ-03 Option A were explicitly approved by the Product Owner on 2026-11-24 and are recorded in the Decision Register. These approvals close the three product-semantic questions only:

- **Audience (POQ-01):** persist the event-time candidate audience and authorized source scope/checkpoint; fan-out/retries reuse it; dispatch-time account/channel/consent/revocation checks may suppress candidates but must never widen the audience.
- **SLA (POQ-02):** immutable policy versions declare elapsed or business-time semantics; initial default is `ELAPSED_UTC`. Quiet hours defer delivery only and do not pause/stop/reset the SLA clock. Business calendars, time zones and pause/reset conditions need explicit policy specification before activation.
- **Dismissal (POQ-03):** dismiss/archive is excluded from MVP. Only recipient-owned set-once `read_at` is exposed; no dismiss command, permission, browser write or UX action exists. Any `dismissed_at` field retained in a proposal is dormant.

The following technical details remain open: exact selector grammar and snapshot/checkpoint representation; partial fan-out fencing; policy schema and worker authorization; provider capability/callback security; exact schema constraints/indexes/RLS; institutional T-10 retention/privacy; test execution and live evidence. G9 remains NOT READY and G10 NOT AUTHORIZED.


## 17. POQ-01 event-time audience snapshot and lock-order addendum — 2026-11-24

POQ-01 fixes product semantics: resolve and durably persist the recipient/scope candidate set at source-event time; retries reuse that set; dispatch-time revalidation may suppress only. NLA-001 v0.1.4 proposes candidate relation `notification_outbox_recipients` and candidate outbox header fields `audience_snapshot_version/hash/count/completed_at`. They are NOT ADMITTED and are excluded from the canonical 48-table inventory.

### 17.1 CMD-052 and CMD-054 physical candidate boundary

- CMD-052 claim remains a short transaction on one outbox row with owner/token-hash/generation/expiry fencing. It commits before fan-out.
- Fan-out reads immutable candidate rows in deterministic recipient-key order, inserts inbox rows idempotently, and derives remaining work by anti-joining candidates to materialized notifications. It must not re-resolve current membership.
- CMD-054 captures one DB UTC instant, serializes the unique notification/policy/step event, and creates its own outbox plus event-time candidate snapshot atomically.
- CMD-053 provider I/O remains outside DB transactions. Callback ingress INT-NOTIF-001 is a separate F5 integration trust boundary; provider-specific event identity/dedup remains open.

### 17.2 Lock-order and implicit-edge blocker

The candidate snapshot relation introduces possible foreign-key checks to `app_users`, projects, sessions, locations and assignments. PostgreSQL FK validation can acquire implicit KEY SHARE locks on referenced rows. A source command may already hold L30/L50/L55 domain locks when it inserts outbox recipient rows, while account/scope revocation paths may acquire L15/L16/L17 before those domain locks. CMD-052 and CMD-054 may also hold queue/policy/notification rows before creating inbox/outbox rows with user/scope FKs.

Therefore the source-event snapshot write and worker materialization paths have a new potential lower-rank-after-higher-rank edge. No candidate rank is assigned to the unadmitted relation. Before admission, Engineering/Database must:
1. enumerate every source command/event that can create an outbox and its already-held lock set;
2. enumerate account, role, scope and assignment writers that compete with event-time recipient resolution;
3. define a single linearization strategy for recipient eligibility (sorted L15/L16/L17 and applicable L30/L50/L55 resources, or an approved temporal snapshot mechanism);
4. include every implicit FK KEY SHARE/unique-index/trigger/function edge for candidate and notification inserts;
5. prove that CMD-052/CMD-054 never acquire a lower-ranked domain resource after outbox/policy/notification locks;
6. validate the final candidate lock graph for cycles and add deterministic adversarial concurrency tests.

A preflight recipient SELECT alone is not a consistency guarantee. Do not suppress FK integrity merely to avoid a lock edge. Candidate schema, exact ranks, lock modes and transaction ordering remain OPEN; this addendum is a blocker record, not a certified solution.

### 17.3 Certification disposition

CMD-049/050 remain recipient-self read/set-once operations; CMD-051 remains publish-only; CMD-052/054 remain internal workload operations; CMD-053 remains provider dispatch plus separately authenticated callback ingress. Candidate audience snapshot design is documented but not admitted. Worker identity/ACL, provider callback dedup/auth, exact lock graph, implicit PostgreSQL edges, RLS and runtime tests remain OPEN. G9 NOT READY; G10 NOT ACTIVE; application lock certification remains 0/50.
