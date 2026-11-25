# CMD-041–044 Detailed Contract Review

**Status:** Engineering contract review — proposal only; PO/security/institutional review required; NOT approved for implementation  
**Document version:** 0.1.1  
**Date:** 2026-11-24  
**Scope:** CMD-041 through CMD-044  
**Repository phase:** Documentation / SSOT maturation  
**Controls:** T-05 actual-report metric definition; T-10 institutional records/privacy gate; T-15 append-only audit direction; T-18 command boundary; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Purpose, authority and non-authority

This document expands the logical PostgreSQL command catalogue for CMD-041–044. It is a static documentation review. It does not authorize application source changes, SQL, migrations, PostgreSQL functions, API routes, grants/revokes, RLS changes, live database queries, audit export, Storage writes, deployment, CI execution or merge.

The logical command catalogue defines stable proposed command IDs, permission codes and intended operations. The report functional design defines actual/target semantics. The audit event catalogue defines proposed audit event families and privacy principles. The canonical permission registry and RLS catalogue remain design drafts. MIB-001, AGENTS.md, the Decision Register and institutional approvals retain higher authority.

A PO-approved product direction is not institutional records/privacy authorization:
- T-05 defines separate Inspected, Submitted, Approved and Completed counts. Completed means approved inspection + final PDF generated + Print Officer print action recorded.
- Actual report dates/times derive from actual immutable events; they must never be shifted to match a target plan.
- Target reports use approved target plans/allocations and must not mutate or rewrite actuals.
- T-10 approves a formal institutional review path only. It does not approve classification, legal basis/purpose, retention, deletion/disposition, legal hold, audit retention, audit reader/export authority, export limits or network metadata.
- T-15 approves append-only audit direction, not the complete institutional records policy or live database enforcement.
- T-18 Option A is an approved command-boundary direction; it does not approve a particular function name, owner, signature or EXECUTE grant.

### 1.1 Source facts and boundaries

- CMD-041 get-actual-report and CMD-042 get-target-report are read operations under proposed report.read.
- CMD-043 read-audit is a purpose-bound audit search/read operation under proposed audit.read.
- CMD-044 export-audit is a separate export operation under proposed audit.export; it is blocked by unresolved institutional T-10 authority.
- The permission registry says report access is scoped to assigned project/session and audit access is purpose-bound. No global access may be inferred from a Super Admin label.
- The report functional design requires daily, weekly and final Actual and Target report families. Exact headline count basis, template strategy and client portal versus PDF-only remain open.
- The audit catalogue includes audit.accessed, audit.search_performed and audit.exported, but exact event payloads, access/export policy and retention are not finalized.
- The physical design contains audit_events, report source entities and target plan entities, but does not establish a fully materialized report snapshot store or audit export artifact/job schema.

### 1.2 Shared read-command contract

1. Read routes validate method, content type, schema version, strict allowlisted filters, date bounds, pagination token and request size. They verify the Supabase session and preserve the caller JWT through the approved path.
2. PostgreSQL derives actor identity from trusted auth context and resolves one active/approved application user. Actor, role, permission and effective scope are never accepted as authoritative request fields.
3. Read authorization is evaluated from current persisted permission grants and active project/session/location/assignment scope. A client filter narrows the authorized set; it never widens it.
4. Report reads and audit reads are different data classes. report.read does not grant audit.read; audit.read does not grant export, evidence download or unrestricted source-resource access.
5. RLS remains an independent read boundary. A server route, signed-in user or UI role label is not a substitute for row-level scope predicates.
6. Use SECURITY INVOKER for read functions/views by default. Any SECURITY DEFINER helper is a separately reviewed exception with least-privileged non-login owner, fixed safe/empty search_path, schema-qualified references, PUBLIC EXECUTE revoked and exact grants.
7. Return only allowlisted report/audit fields. Never expose raw evidence, signed URLs, secrets, full personal data beyond approved purpose, internal SQL diagnostics or hidden cross-scope identifiers.
8. Read queries must be bounded by approved date range, scope, row/page limits and statement/runtime budget. Numeric limits and SLOs remain open until workload and provider evidence are approved.
9. Use stable ordering and opaque cursor pagination. Cursor state must be bound to actor, effective scope, filters, sort order and snapshot/watermark. Do not use client-controlled offset pagination for unbounded audit history.
10. Read results are not write-idempotent. A request/correlation ID is sufficient for traceability. Access logging must not recursively trigger an unbounded audit-read loop.
11. All proposed routes, SQL views, RPC/function names and query plans remain candidates until checked against deployed inventory.
12. Planned tests are not executed evidence. All tests below remain PLANNED / NOT EXECUTED.

### 1.3 Common response envelope proposal

Read responses should include schema_version, command_id, outcome, correlation_id, server measured_at or queried_at, applied filters after canonical normalization, effective scope summary safe for the caller, stable pagination cursor and has_more where applicable, data, and typed validation/authorization errors.

Do not return raw SQL, database object names not intended as public contract, full authorization graph, private Storage object keys, or another user's existence details. Report data must distinguish source event time from measurement/query time.

## 2. Contract review — CMD-041 get-actual-report

### 2.1 Intent and report semantics

Return actual operational performance derived from immutable operational events and authoritative persisted inspection state. The report is internal and reflects what actually happened, when it happened and within which authorized scope. Actual activity dates must be based on server-recorded event timestamps, not target allocation dates, user-entered dates or report-generation date. Reassignments and target reallocations must not rewrite historical actual activity.

Required report families are daily Actual, weekly Actual and final Actual.

T-05 requires separate labelled counts:
- Inspected: exact canonical definition must be reconciled to the first qualifying inspection event/state and must avoid double-counting reopened/revised inspections.
- Submitted: inspections with a qualifying submission event in the selected period, according to the final event-counting rule.
- Approved: inspections with a qualifying approval decision in the selected period, using the exact approved revision.
- Completed: approved inspection + final PDF generated + Print Officer print action recorded.

The last three definitions are anchored by T-05, but the precise counting unit (distinct inspection, revision, unit, or event) and treatment of reopen/reapproval must be finalized in a metric dictionary before implementation. Never silently count raw event rows where a distinct-resource count is intended. A PDF open/download is not a print event.

### 2.2 Proposed request schema

Required:
- schema_version;
- project_id;
- date_range.start_date and date_range.end_date;
- granularity: DAY, WEEK or FINAL, subject to approved reporting vocabulary.

Optional:
- session_id;
- location_id;
- assignment_id, only if approved report scope and data model support this filter;
- instrument_id/instrument_version_id, only if the report specification authorizes this dimension;
- cursor;
- page_size within server policy;
- timezone only if approved as a presentation filter; it cannot change persisted event timestamps.

Forbidden: actor_user_id, role, permission, scope grants, arbitrary SQL/filter expression, client-provided metric totals, target plan values, arbitrary sort expression, include_deleted, unrestricted export or hidden personal fields. Idempotency is not required for this read operation.

### 2.3 Proposed response schema

Outcome OK returns report_type ACTUAL, project/session/location labels safe for the caller, normalized date range and report timezone, measured_at, applied filters, metric definitions/version, separate counts for inspected/submitted/approved/completed, optional approved breakdowns by day/location/instrument/assignment, productivity measures only where denominator/time basis/inclusion rules are defined, and cursor/has_more/stable sort metadata.

Every count should disclose its unit and period attribution rule. Do not combine target values into Actual metrics. Do not infer physical paper output or signature from a print-click event.

### 2.4 Authorization, scope and SoD

Permission: report.read.

Required checks:
- authenticated actor resolves to one active and approved app_users record;
- active report.read grant is valid at query time;
- project_id is within explicit effective project scope;
- optional session/location/assignment filters are descendants of that authorized project scope and independently authorized;
- if actor is assigned only to a location, aggregate queries cannot return other locations or reveal their counts;
- an omitted client filter means the server returns the actor's entire authorized scope, not global scope;
- Super Admin label alone does not create an exception to explicit scope rules;
- account, role, scope and assignment validity use database time;
- report output is field-minimized for the actor's purpose.

Korlap daily report validation/approval is a separate workflow/permission and is not implemented by CMD-041. CMD-041 is read-only and must not mutate report approval state.

### 2.5 Physical read/write set

Proposed reads:
- inspections;
- inspection_revisions where needed to establish exact approved revision;
- inspection_events and review_events for actual event timestamps and state transitions;
- documents for final PDF generation state and immutable source linkage;
- print_events for application print actions and sequence;
- units and unit_project_associations for canonical unit/project relationship;
- operational_assignments, assignment_members, sessions, locations and projects for authorized scope and report dimensions;
- instrument_versions/snapshots where historical instrument grouping is needed;
- app_users, user_roles, user_scope_grants, permissions and role_permissions through the approved authorization resolver.

Writes:
- No business table mutation.
- Optional audit_events append for report.accessed only if approved access-audit policy requires it. This must use a separate safe access-audit path, not mutate report source records.

No report snapshot/materialized table is assumed to exist. If performance later requires a cache/snapshot, it must be derived, versioned, invalidated/rebuilt safely and approved through an ADR; it cannot become a second source of truth.

### 2.6 Query consistency, pagination and performance

- Define one canonical period attribution rule for each metric: event occurred_at versus current state snapshot. Submitted and Approved may be event-period metrics; Completed may be completion-event period or current completion state with a defined as-of boundary. Do not mix these silently.
- A report response must state measured_at and the effective as-of/watermark used to compute counts.
- Use stable deterministic ordering such as event date + resource UUID. Cursor tokens must be opaque, integrity-protected and bound to actor, scope, filters, schema version and snapshot/watermark.
- For multi-query aggregation, use one consistent database snapshot where feasible. If multi-request reporting cannot preserve a database snapshot, use an explicit watermark and document eventual consistency.
- Apply server-side statement timeout and bounded date range/page size after numeric values are approved. A client must not override limits.
- Use indexes aligned with authorized scope and event-time predicates. Index choices and query plans require EXPLAIN/load evidence; this document does not assert performance.
- Avoid N+1 queries and unrestricted event scans. RLS alone does not make an unbounded query safe.

### 2.7 Audit and typed outcomes

Event candidate: report.accessed. The audit catalogue says access events should be recorded where policy requires. If every report read is auditable, record actor, role, project/session/location scope, normalized date range, report type, filters hash, result size and correlation ID, but not report rows or sensitive filter payload.

Typed outcomes: OK, VALIDATION_FAILED, PERMISSION_DENIED, ACCOUNT_INACTIVE, SCOPE_DENIED, DATE_RANGE_TOO_LARGE, FILTER_NOT_SUPPORTED, CURSOR_INVALID_OR_EXPIRED, REPORT_DEFINITION_UNAVAILABLE, QUERY_TIMEOUT and RETRYABLE_FAILURE.

Unauthorized response must not distinguish a nonexistent project from a project outside actor scope.

### 2.8 Candidate transport mapping — NOT APPROVED

- Candidate route: GET /api/reports/actual
- Candidate query parameters: project_id, session_id, location_id, start_date, end_date, granularity, cursor, page_size.
- Candidate query/view family: report_actual read views or narrowly scoped invoker query.
- Candidate permission: report.read.

No deployed route, view, function, RLS predicate or query plan is verified. A read route must not use service-role credentials to bypass caller scope.

### 2.9 Required tests

Positive: authorized user reads actual report for assigned project and sees only permitted locations; daily/weekly/final grouping follows metric dictionary.

Negative: no grant; inactive account; expired/revoked assignment; cross-project/session/location filter; arbitrary filter injection; client-supplied actor/role/count; excessive date range/page size; hidden-field leakage; report.read cannot approve a report.

Metric correctness: Inspected/Submitted/Approved/Completed remain separate; Completed requires all three T-05 conditions; PDF open does not count as print; target allocation never rewrites actual timestamps; reopen/reapproval does not double-count without an approved metric rule.

Pagination: same-scope cursor continuation; cursor tampering; cursor reused with different actor/filter/scope; stable ordering when new events arrive; no duplicate/omitted rows under selected watermark model.

Concurrency/consistency: events arriving during aggregation; document generation/print event racing with report measurement; assignment revocation between pages; target reallocation concurrent with actual query.

Audit: if access auditing is required, exactly one safe access record is emitted per logical request policy; audit failure follows approved read-audit availability policy and does not mutate business data.

Existing QA mapping: TC-CMD-CONTRACT-024-041 and corresponding report authorization/RLS test series — PLANNED / NOT EXECUTED.

## 3. Contract review — CMD-042 get-target-report

### 3.1 Intent and report semantics

Return client-facing target-plan performance for an explicitly selected published target plan/version and authorized project/session scope. Target values represent approved plan allocations and progress against that plan. They are not actual inspection facts.

Required report families are daily Target, weekly Target and final Target. Target plan and allocation changes are versioned and audited. A report must bind to one explicit immutable published plan version. It must not silently switch to the latest version between pages or after reallocation.

### 3.2 Proposed request schema

Required: schema_version, project_id, date_range.start_date, date_range.end_date and granularity DAY/WEEK/FINAL.

Optional: session_id; plan_version_id (if omitted, server may select current published version only under an explicit rule and must return the chosen version); cursor; page_size within policy; location_id or instrument_id only if approved target allocation model supports those dimensions.

Forbidden: actor_user_id, role, permission, scope override, unpublished draft plan visibility, client-supplied allocation totals, arbitrary grouping/sort expression, mutation flags or client-provided progress calculations.

### 3.3 Proposed response schema

Outcome OK returns report_type TARGET, project/session scope, selected immutable target plan/version ID and label, publication timestamp/status, normalized period and report timezone, measured_at, allocated target counts by approved dimension and period, optional actual progress only if the report specification explicitly allows it and clearly labels it as actual, variance/progress ratio with zero-target handling, and cursor/has_more.

Do not return draft or superseded plan versions unless actor has explicit governance permission and separately approved use case. A target-only report must not imply target allocations are actual activity.

### 3.4 Authorization, scope and SoD

Permission: report.read.

Required checks:
- active account and report.read grant;
- project and optional session are within effective scope;
- selected target plan belongs to same project/session and is published/visible to caller;
- each location/instrument allocation is within authorized scope;
- client cannot select another project's plan by guessing UUID;
- absent plan_version_id follows one documented server selection rule and response returns exact chosen version;
- draft-plan management, reallocation and publication permissions do not follow from report.read;
- Super Admin label alone does not bypass explicit scope.

### 3.5 Physical read/write set

Proposed reads:
- target_plans;
- target_allocations;
- projects and sessions;
- locations and instrument references as required by allocation dimensions;
- operational_assignments and assignment_members only for scope verification and authorized breakdown;
- inspections/inspection_events only if approved report contract requires a clearly labelled actual-progress overlay;
- authorization records through approved resolver.

Writes: no target plan, allocation or inspection mutation. Optional report.accessed event under same policy and safe audit path as CMD-041.

No new target plan version or allocation may be created, changed or published by this read command.

### 3.6 Query consistency, versioning and calculation

- Resolve the published target version once and bind all pages to it.
- Target allocation totals reconcile to the sum of selected plan's persisted allocations for selected dimensions and period.
- Date bucketing uses project's approved timezone. Timezone is not freely client-selectable if it changes business interpretation.
- If actual progress is displayed, its as-of watermark and metric-definition version must be visible and separate from target allocation values.
- Define zero-target behavior explicitly: return a null/not-applicable ratio with explanatory status rather than infinity or misleading 0%.
- A new target version must not change a report already paginating against earlier selected version.
- Bound date range, page size and query time using approved policy; no production numeric limits are assumed here.

### 3.7 Audit and typed outcomes

Event candidate: report.accessed, with report_type TARGET and target_plan_version_id. Do not record allocation rows or unnecessary personal data in audit metadata.

Typed outcomes: OK, VALIDATION_FAILED, PERMISSION_DENIED, ACCOUNT_INACTIVE, SCOPE_DENIED, PLAN_NOT_FOUND_OR_NOT_VISIBLE, PLAN_NOT_PUBLISHED, PLAN_VERSION_MISMATCH, DATE_RANGE_TOO_LARGE, CURSOR_INVALID_OR_EXPIRED, QUERY_TIMEOUT and RETRYABLE_FAILURE.

### 3.8 Candidate transport mapping — NOT APPROVED

- Candidate route: GET /api/reports/target
- Candidate query/view family: report_target read views or narrowly scoped invoker query.
- Candidate permission: report.read.

No deployed route, view, query plan or permission grant is verified.

### 3.9 Required tests

Positive: authorized user reads exact published target version; daily/weekly/final grouping reconciles to allocation rows.

Negative: unpublished draft; wrong project/session; out-of-scope location; forged plan ID; client-supplied totals; report.read cannot modify target plan; no implicit global access.

Calculation: allocation totals reconcile; zero target does not divide by zero; project timezone drives buckets; actual overlay is clearly separate with its own watermark; target changes never mutate actual history.

Pagination: cursor cannot be reused for another actor, plan version, project or filter; new target version does not leak into existing cursor session.

Concurrency: target version published/reallocated while report paginates; assignment scope revoked between pages; actual progress changes during target report measurement.

Audit: report access event follows approved access policy and contains only safe filter/version metadata.

Existing QA mapping: TC-CMD-CONTRACT-024-042 and corresponding report authorization/RLS test series — PLANNED / NOT EXECUTED.

## 4. Contract review — CMD-043 read-audit

### 4.1 Intent and security classification

Search/read append-only audit events for an explicitly approved accountability, investigation, records or security purpose. Audit access is a privileged and itself auditable operation. It is not a general-purpose administrator log viewer, analytics endpoint or source-data browsing shortcut.

audit.read is separate from audit.export. It does not authorize export, evidence download, user impersonation, unrestricted source-resource access or legal-hold/retention management.

T-10 institutional approval is not complete. Until the institution approves reader authority, purpose taxonomy, classification, scope, retention and legal constraints, the production reader matrix and fields remain blocked. This is a proposed safe contract, not an enabled capability.

### 4.2 Proposed request schema

Required:
- schema_version;
- purpose_code from an institutionally approved purpose allowlist;
- time_range.start_at and time_range.end_at;
- at least one explicit scope selector or resource reference within actor's authorized audit scope, unless a formally approved global audit investigation scope is granted.

Optional:
- event_types[] from canonical event catalogue;
- actor reference only when approved investigation purpose permits actor lookup;
- resource_type/resource_id;
- project_id/session_id/location_id;
- outcome;
- cursor;
- page_size within policy;
- request/correlation ID for traceability.

Forbidden: client-supplied actor identity for authorization; arbitrary SQL, JSONPath, regex or free-form predicates; include_payload/full_row flags; raw evidence/object key/signed URL/secret retrieval; unrestricted IP/network metadata query; client-selected retention bypass/legal hold override/export flag; arbitrary cross-scope resource enumeration.

Purpose text must not be an unrestricted field for granting access. Use a controlled purpose code plus short explanation only if institutional policy requires it.

### 4.3 Proposed response schema

Outcome OK returns only institutionally approved allowlisted event fields:
- event_id;
- occurred_at and recorded_at;
- event_type and event_class;
- actor reference and actor_type only if authorized for purpose;
- active role and scope references, minimized;
- resource_type/resource_id, opaque or redacted where disclosure is not approved;
- action and outcome;
- reason code/text only when approved;
- correlation/request reference;
- safe typed metadata selected by event schema;
- cursor/has_more.

Do not expose arbitrary metadata JSON wholesale. Use event-type-specific projection and field classification. Do not return raw before/after summaries, full payloads, personal identifiers or network metadata unless the institution approves exact field and purpose.

### 4.4 Authorization, scope, purpose and SoD

Permission: audit.read.

Required checks:
- active account and explicit active audit.read grant;
- audit scope is explicitly granted and does not derive from role name alone;
- caller's approved purpose code is permitted for requested event class/resource scope;
- project/session/location filters are within grant and event's stored scope;
- global audit investigation is unavailable unless separate named institutional authority and grant are evidenced;
- actor filters cannot enumerate all activity across projects;
- sensitive event classes/fields require narrower grants or redaction under approved classification;
- account, role and grant validity are checked at query time;
- audit.read does not imply export authority;
- reader access itself is recorded through a dedicated safe path.

T-10 must define whether audit readers are records officers, security officers, internal auditors, project officers or another named function, and how emergency/break-glass access is authorized, time-limited, approved and reviewed. No role mapping is invented here.

### 4.5 Physical read/write set

Proposed reads:
- audit_events;
- app_users, roles and scope authorization records through a safe resolver;
- projects, sessions and locations only to validate scope/display approved labels;
- approved event schema/classification registry (not yet fully physicalized);
- audit access policy and purpose registry (not yet fully physicalized).

Writes:
- No mutation to committed audit_events.
- A separate audit.accessed or audit.search_performed event may be appended through a dedicated access-audit path after successful/denied query according to approved policy.
- Access event must be emitted without recursively invoking the same audit search path. A narrowly scoped append operation or durable access-log outbox may be considered; exact implementation is unresolved.

Do not update/delete existing audit_events. Do not grant application roles direct INSERT/UPDATE/DELETE on audit_events. Access logging does not make CMD-043 a general audit mutation command.

### 4.6 Transaction, consistency, pagination and anti-recursion

- Validate purpose, time range, event types, scope and bounded page size before reading.
- Resolve current audit permission/scope and approved purpose authorization.
- Query with stable order, preferably occurred_at + event_id (or recorded_at + event_id where approved policy selects append-time order).
- Use opaque integrity-protected cursor bound to actor, purpose, scope, normalized filters, sort and watermark.
- Do not use unbounded offset or return arbitrary metadata payloads.
- Access audit event is a separate record with query/filter hash, purpose code, result count, caller/scope and correlation ID; do not include returned event rows.
- Avoid recursive access logging: the event generated by reading the audit log must not itself trigger another audit-read event.
- Define behavior if access-event append fails. For regulated access, fail closed or route to durable monitored queue according to institutional policy; do not silently suppress failure.
- No database locks are held over query response serialization or external logging.
- Retention/legal hold filtering is not an ad hoc query filter. It follows approved institutional records policy.

### 4.7 Audit and typed outcomes

Event candidates: audit.accessed, audit.search_performed and authorization.denied where denial qualifies under approved security audit policy.

Audit access metadata should include actor, active role, purpose code, requested scope, event-type filter hash, time range, result count, correlation ID and server timestamp. It must not include returned audit row content or secrets.

Typed outcomes: OK, PURPOSE_REQUIRED, PURPOSE_NOT_ALLOWED, PERMISSION_DENIED, SCOPE_DENIED, ACCOUNT_INACTIVE, EVENT_CLASS_RESTRICTED, FIELD_REDACTED_OR_NOT_AVAILABLE, TIME_RANGE_INVALID, DATE_RANGE_TOO_LARGE, CURSOR_INVALID_OR_EXPIRED, QUERY_TIMEOUT, ACCESS_AUDIT_UNAVAILABLE and RETRYABLE_FAILURE.

Where policy requires non-disclosure, return generic denial without confirming whether target event/resource exists.

### 4.8 Candidate transport mapping — NOT APPROVED

- Candidate route: GET /api/audit-events
- Candidate query parameters: purpose_code, from, to, event_type, project/session/location/resource filters, cursor and page_size.
- Candidate permission: audit.read.
- Candidate read path: scoped SECURITY INVOKER query/view with independent RLS and separately reviewed access-audit append path.

No route, reader role grant, purpose registry, field projection or live RLS predicate is verified.

### 4.9 Required tests

Positive: explicitly authorized audit reader searches events for approved purpose and exact permitted scope; results contain only approved fields.

Negative: report.read without audit.read; audit.read without purpose; unknown/unapproved purpose; cross-project/location; global query without named authority; actor enumeration; arbitrary metadata/full payload; network metadata access without approval; export attempted through read endpoint; direct audit table DML.

Privacy: personal fields redacted; secrets, signed URLs, evidence bytes and object keys never returned; event-specific projection rejects unknown metadata; purpose and result scope are recorded without copying result rows.

Pagination: cursor tampering; cursor reuse across actor/purpose/scope/time range; stable ordering; new events after watermark; no duplicates or omissions.

Audit recursion: reading audit emits at most one access event under policy; access event is not recursively audited as another audit read; append failure follows approved fail-closed/monitored behavior.

Concurrency: permission revocation between pages; scope revocation during query; legal hold/classification policy version change while paging; new event append during pagination.

Existing QA mapping: TC-CMD-CONTRACT-024-043 and corresponding audit/RLS/function-security tests — PLANNED / NOT EXECUTED.

## 5. Contract review — CMD-044 export-audit

### 5.1 Intent and hard institutional gate

Export an approved, bounded, purpose-specific set of audit events into a controlled artifact with integrity and provenance metadata. Export is separate from and higher risk than on-screen audit reading.

**BLOCKED — T-10 institutional approval required.**

T-10 remains BLOCKED. There is no approved classification, legal basis/purpose, reader/export authority, retention, deletion/disposition, legal hold, network metadata policy, export recipient rule, format/volume limit or artifact retention policy. Therefore CMD-044 is not an implementable or operationally authorizable command. The following contract is a design checklist only and must not be used to create an export route, function, grant, job, bucket or artifact.

### 5.2 Proposed request schema — NOT APPROVED

Required candidate fields:
- schema_version;
- purpose_code from an institutionally approved purpose taxonomy;
- scope selector limited to a named approved audit scope;
- time_range.start_at and time_range.end_at;
- event_types[] allowlist;
- format from institutionally approved format set;
- request_id and idempotency_key;
- justification/reference to approved case or records request where policy requires it.

Optional candidate fields:
- explicit approved field projection/version;
- recipient class or destination reference only if institutionally approved and not a free-form external address;
- expected record count ceiling only as server-validated policy, never client override.

Forbidden: actor_user_id, role, authority claims, legal basis assertion, client-supplied scope grant, arbitrary query/SQL, include_all, include_payload, secret/network metadata flags, custom Storage object key, arbitrary recipient email, client-selected retention/delete_after date, client-supplied checksum or manifest.

No format, size, row-count, expiry or retention limit is selected in this proposal.

### 5.3 Proposed response schema — NOT APPROVED

Only after T-10 and security approval, asynchronous ACCEPTED response may include export_request_id, export_job_id, normalized scope/filter hash, policy version, status QUEUED, accepted_at and an estimated/upper-bound class only if policy allows.

Terminal EXPORTED response may include export_artifact_id, generated_at, record_count, output format, artifact checksum and manifest checksum, export policy/version reference, integrity verification status, authorized access reference with separate time-limited access decision, and retention/expiry metadata only as mandated by approved records policy.

No export bytes, signed URL or permanent public URL should be returned as a durable command result. Download authorization is a separate purpose-bound operation and must itself be audited.

### 5.4 Authorization, institutional authority and SoD

Permission: audit.export.

Before implementation, obtain written evidence for:
- institutionally designated audit export authority and named accountable owner;
- approved legal basis and purpose taxonomy;
- data classification and field-level redaction rules;
- permitted scope and whether any global audit export exists;
- recipient classes, transfer method and onward-disclosure restrictions;
- export format, maximum records/bytes/time window, rate and concurrency limits;
- artifact location, encryption/key management, access expiry, retention, deletion/disposition and legal hold behavior;
- dual control or independent approval requirement;
- emergency/break-glass process and subsequent review;
- audit of export request, approval, generation, download, failed attempt and disposition.

A user with audit.read must not inherit audit.export. A generic Super Admin label must not substitute for institutional export authority. audit.export grant itself cannot be treated as proof that T-10 approval exists.

### 5.5 Physical read/write set — NOT APPROVED

Candidate reads:
- audit_events;
- authorization and scope records;
- approved purpose/classification/export policy version;
- approved case/records request reference, if established.

Candidate writes, only after approval and schema design:
- dedicated audit_export_requests/audit_export_jobs entity or equivalent durable job model;
- immutable export manifest and artifact metadata;
- audit_events for audit.exported and separately defined request/approval/download/failure events;
- private Storage artifact under institution-approved bucket/policy;
- idempotency outcome.

No export job, manifest or artifact table is assumed to exist. documents and notification outbox must not be repurposed without approved data model. Current physical table specification does not establish export lifecycle, manifest schema, artifact ACL, expiry, retention or deletion proof.

### 5.6 Transaction, asynchronous generation and integrity — NOT APPROVED

After T-10 approval only, design should consider:
1. Validate institutional authority, purpose, scope, policy version, record/time bounds and idempotency.
2. In a short transaction, create durable export request/job and append accepted/requested audit event. Do not create a publicly accessible artifact.
3. A separately approved worker reads a fixed, policy-versioned snapshot/watermark and generates export outside database locks.
4. Build integrity manifest identifying exact filter/policy version, snapshot/watermark, event count, ordered event identity range and output checksum. Canonical serialization and hashing are security design decisions.
5. Store artifact in approved private storage with encryption and least-privilege access. Never use guessable object key or public bucket.
6. Finalize job and append audit.exported atomically with artifact metadata; handle uncertain Storage outcomes by reconciliation rather than overwriting.
7. Require separate authorized download/access decision with expiry and audit evidence.
8. Enforce approved retention, legal hold, disposition and verified deletion controls. No duration or deletion behavior is invented here.
9. Define retries, dead-letter, alerting, worker identity, lease, concurrency, key rotation, backup/restore and incident response before production.

Do not hold PostgreSQL locks during export rendering, object upload or download. Do not create export output while T-10 remains blocked.

### 5.7 Audit and typed outcomes — NOT APPROVED

Event candidates: audit.exported; audit.export_requested; audit.export_approved/audit.export_rejected if dual approval is selected; audit.export_downloaded; audit.export_failed; authorization.denied.

The existing audit catalogue explicitly includes audit.exported; other event keys require reconciliation/approval before adoption.

Candidate outcomes: ACCEPTED, EXPORTED, POLICY_NOT_APPROVED, AUTHORITY_NOT_ESTABLISHED, PURPOSE_NOT_ALLOWED, PERMISSION_DENIED, SCOPE_DENIED, EXPORT_LIMIT_EXCEEDED, CLASSIFICATION_RESTRICTED, APPROVAL_REQUIRED, GENERATION_FAILED, INTEGRITY_CHECK_FAILED, ARTIFACT_ACCESS_DENIED and RETRYABLE_FAILURE.

While T-10 is blocked, safe operational behavior is to keep feature unavailable and return a non-disclosing policy-not-approved result. No job or artifact may be created.

### 5.8 Candidate transport mapping — NOT APPROVED

- Candidate route: POST /api/audit-exports
- Candidate permission: audit.export.
- Candidate worker, request table, manifest, private bucket and download boundary: TBD and blocked.

These names are placeholders only. Do not add a route or grant based on this review.

### 5.9 Required tests — FUTURE, NOT EXECUTABLE

After institutional and security approval:
- Positive: named export authority requests permitted bounded export for approved purpose and scope.
- Negative: audit.read without audit.export; missing T-10 approval; generic Super Admin; wrong scope; unapproved purpose; recipient outside approved class; export size/window over policy; restricted fields; legal hold conflict; arbitrary query or object key.
- SoD: requester/approver separation if required; worker cannot approve own request; download actor independently authorized.
- Idempotency: same request/key returns same job; same key/different filter hash rejected; uncertain worker/Storage outcome reconciles without duplicate artifact.
- Integrity: manifest matches exact selected events, event order, count, policy version and output checksum; tampered artifact rejected.
- Concurrency: duplicate workers; concurrent export requests; permission revocation during generation/download; legal hold applied during queued generation; retention policy change.
- Privacy: no secrets, signed URLs, raw evidence, unnecessary personal fields or unapproved network metadata.
- Audit: request, approval, generation, download, failure and disposition events complete and do not recursively export themselves.
- Recovery: orphan artifact, partial job, worker lease expiry, checksum mismatch and failed deletion are recoverable and auditable.

Existing QA mapping: TC-CMD-CONTRACT-024-044 and corresponding audit-export security/records tests — PLANNED / NOT EXECUTED. Do not run against production or real audit data before T-10 and environment authorization.

## 6. Cross-command findings and required decisions

The findings below are design gaps identified from static documents. No live database, deployed route, RLS policy or runtime behavior was inspected.

| Finding | Commands | Evidence / impact | Required closure |
|---|---|---|---|
| C41-01 | 041 | T-05 fixes four labels and Completed components, but exact count unit, period attribution and reopen/reapproval treatment are not fully defined | Approve metric dictionary with event/state basis, distinct-resource key, time attribution and edge-case examples |
| C41-02 | 041 | Report design leaves exact headline count basis, template strategy and client portal/PDF-only open | PO resolves output/channel and report layout without conflating read query and report approval |
| C41-03 | 041–042 | Numeric date/page/query limits and performance SLO are not approved/measured | Approve workload bounds and validate query plans/load in authorized staging after G10 |
| C42-01 | 042 | Target report must bind to immutable published plan version; cursor/snapshot semantics are not defined in a physical report contract | Define version selection, timezone, watermark and cursor binding |
| C42-02 | 042 | Target progress overlay is not explicitly settled | PO approves whether actual progress is included and requires separate labels/watermark/metric version |
| C43-01 | 043 | T-10 blocks audit reader authority, purpose taxonomy, classification, retention and audit field disclosure | Obtain written institutional records/privacy/security authority and field-level access matrix |
| C43-02 | 043 | Audit access must itself be recorded, but recursive read logging and failure semantics are not specified | Approve dedicated non-recursive access-audit path and fail-closed/monitored availability policy |
| C43-03 | 043 | Audit metadata is typed but arbitrary JSON projection/field classification is not physicalized | Define event-schema registry and per-event reader projection/redaction |
| C44-01 | 044 | T-10 leaves export authority, legal basis, limits, recipient, retention, legal hold and disposition blocked | Institutional written approval before implementation |
| C44-02 | 044 | No export request/job/manifest/artifact lifecycle is specified in physical schema | Define durable job, immutable manifest, private artifact ACL, checksum, download and recovery model after T-10 |
| C44-03 | 044 | No worker identity, lease, retry, encryption/key management or artifact deletion proof is verified | Security/operations architecture and provider evidence required |
| C41-044-01 | 041–044 | report.read, audit.read and audit.export are draft permissions; role grants and grantor ceiling are not approved | Approve canonical permission registry and role/scope matrix |
| C41-044-02 | 041–044 | Candidate API/view/function names and effective RLS/EXECUTE ACL are not verified | Reconcile contracts against actual route/function/owner/privilege/RLS inventory after explicit G10 |
| C41-044-03 | 041–044 | Tests are catalogue specifications only; no report correctness, privacy, query performance or export security test has executed | Run authorized reproducible suite after design approval and G10; attach exact commit/schema/environment evidence |

### 6.1 Required cross-document reconciliation

Before CMD-041–044 can be frozen:
1. Reconcile T-05 and report functional design into a versioned report metric dictionary. Include distinct-resource counting, event-time versus as-of-state semantics, reopening/reapproval, duplicate revisions, final PDF generation and print action.
2. Define project timezone and date-boundary semantics, including daylight-saving behavior if any supported project timezone requires it.
3. Define immutable target plan version selection and report cursor/watermark semantics.
4. Decide whether actual progress appears in target reports; if yes, keep target allocation and actual progress separately labelled and separately versioned.
5. Reconcile report access logging with audit event catalogue and define safe, non-recursive behavior.
6. Obtain institutional T-10 decisions for audit purpose, classification, reader/export authority, field redaction, retention, legal hold, disposition, recipient and network metadata.
7. Define audit event field classification and event-specific reader projections; arbitrary metadata JSON must not be exposed.
8. Design export job, manifest, private artifact, integrity verification, download authorization and deletion lifecycle only after T-10.
9. Reconcile report.read, audit.read and audit.export to approved role/grantor/scope matrix.
10. Update RTM, DGA-001 and RAID only after accountable document owner accepts finding mapping and closure evidence. Do not mark DGA blockers closed merely because this review documents them.

## 7. Consolidated test plan

All tests below are specifications, not executed evidence.

| Test dimension | Minimum coverage across CMD-041–044 |
|---|---|
| Positive | Authorized Actual/Target report read; authorized audit search only after T-10; export tests only after institutional approval |
| Authorization | Wrong project/session/location, inactive account, missing/expired/revoked permission, no implicit Super Admin global access |
| Purpose/classification | Purpose required/allowed; event-class and field-level redaction; no raw payload or secret leakage |
| Metric correctness | Four T-05 counts separate; Completed requires approved + final PDF + print action; actual timestamps immutable; target version immutable |
| Time/timezone | Inclusive/exclusive date boundary, timezone conversion, DST where relevant, server timestamp and measurement watermark |
| Pagination | Tampered/reused cursor, actor/scope/filter mismatch, stable order, concurrent new events and plan versions |
| Privacy | No evidence bytes, signed URLs, secrets, unapproved personal/network metadata or arbitrary JSON |
| Audit access | Access event itself recorded once; no recursive audit loop; append failure follows approved policy |
| Export integrity | Exact filter/policy snapshot, count/order/hash manifest, checksum, private artifact and authorized download |
| Concurrency | Permission/scope revocation between pages; target version publication; audit append during query; duplicate export workers |
| Performance | Bounded date range/page size, query plan, statement timeout, representative workload and approved SLO |
| Recovery | Cursor expiry, partial export job, worker lease expiry, orphan artifact, checksum mismatch, retention/legal-hold conflict |

Existing catalogue mappings:
- TC-CMD-CONTRACT-024-041 through TC-CMD-CONTRACT-024-044.
- Related RLS, function-security, audit and report test families.
- All remain PLANNED / NOT EXECUTED. No test run is claimed.

## 8. Gate and verification disposition

| Item | Current status | Evidence boundary |
|---|---|---|
| CMD-041–044 detailed review | DOCUMENTED — PROPOSAL | Static review of canonical repository documents |
| CMD-041/042 report semantics | PARTIAL — REVIEW REQUIRED | T-05 labels/Completed components approved; exact metric dictionary and output decisions remain open |
| CMD-043 audit reader | BLOCKED — T-10 | Institutional purpose, classification, reader authority, retention and field policy not approved |
| CMD-044 audit export | BLOCKED — T-10 | Institutional export authority, legal basis, limits, recipient, retention and artifact policy not approved |
| Permission grants | NOT APPROVED | Canonical registry and role/grantor matrix remain draft |
| Physical read/write sets | DOCUMENTED WITH GAPS | Static physical schema; report snapshot/export entities not assumed |
| Route/view/function mapping | CANDIDATE ONLY | No deployed route/function inventory verified |
| RLS and effective privileges | NOT VERIFIED | No live database/policy inspection performed |
| Tests | PLANNED / NOT EXECUTED | No unit, integration, privacy, security, load or UAT test run |
| G9 | NOT READY | DGA blockers and contract/design gaps remain |
| G10 | NOT AUTHORIZED | No implementation authorization record |
| Source code / SQL / migration / grants | NOT PERFORMED | Outside permitted scope |
| Live database / export / deployment / merge | NOT PERFORMED | Outside permitted scope |

## 9. Next work

1. Continue CMD-045–048 only as read-only contract review and preserve their institutional-authority blockers; do not implement them.
2. Then review CMD-049–054 separately against NLA-001 and notification worker identity/ACL decisions.
3. After CMD-001–054, perform full cross-command reconciliation against physical schema, permission registry, RLS, audit catalogue, API mapping, test catalogue, RTM, DGA and RAID.
4. Keep audit export disabled and unimplemented while T-10 remains blocked.
5. Reassess G9 only when closure evidence exists. G10 remains a separate explicit authorization.

**Final boundary:** This review changes documentation only. No source code, SQL, migration, grant/revoke, RLS, live database query, audit export, deployment, CI execution or merge was performed.

## 6.2 Physical read-set and cursor reconciliation — 2026-11-24

The companion COMMAND-PHYSICAL-OBJECT-CROSSWALK-001 now enumerates candidate source read sets for CMD-041/042 and the bounded purpose/scope read set for CMD-043. The source sets are proposals against the current 48-table physical inventory, not a deployed query plan or final index contract.

- CMD-041 reads authoritative inspection/revision/event/review, document/print, unit association, assignment, session/location/project and immutable instrument-version sources. It performs no business mutation. Report metrics remain blocked on a versioned metric dictionary that settles the distinct counting unit, event-time versus state-as-of attribution, reopen/reapproval and Completed finalization boundary.
- CMD-042 reads target plan/allocation plus only the scope and dimension references needed for the selected published plan. One immutable published plan version is pinned for the full cursor chain. Actual-progress overlay remains a PO decision and cannot be merged into target allocation totals.
- CMD-043 reads audit_events through a bounded, event-specific projection plus minimum authorization/scope references. Arbitrary metadata JSON, raw payloads and unapproved personal/network fields remain prohibited. Access append is a separate non-recursive operation; at most one access event per request/correlation ID. The failure policy remains an institutional T-10 decision.
- CMD-041/042 do not assume materialized report tables. Any future cache/snapshot is derived only, requires ADR and invalidation/rebuild proof, and cannot become a second source of truth.
- Cursor binding must include actor, effective scope, normalized filters, sort, schema/policy version and snapshot/watermark. Target cursor additionally pins plan_version_id. A cursor never freezes authorization: current permission/scope is rechecked on every page.

## 6.3 CMD-044 candidate export physical model — NOT ADMITTED

The physical schema, RLS catalogue and ERD now contain matching candidate-only annexes for audit_export_jobs, audit_export_manifests and audit_export_artifacts. These are NOT tables in the canonical 48-table inventory and are not approved for creation. They exist only to make the future design gap explicit.

The candidate model separates: (1) durable request/job and idempotency/lease state; (2) immutable ordered selection manifest and policy/snapshot provenance; and (3) private artifact metadata with verified checksum and encryption/key reference. It prohibits browser DML, public artifacts, caller-selected object keys and reuse of documents or notification_outbox. Exact relationships, retries/attempt cardinality, approval records, worker identity, Storage provider/region, download authority, encryption, retention/legal hold and deletion proof remain OPEN.

T-10 remains BLOCKED. No export route, function, grant, worker, bucket, job or artifact may be created. audit.export does not imply artifact download. Candidate event names beyond existing audit.exported remain unapproved.

## 6.4 Disposition after static reconciliation

| Area | Static documentation result | Remaining blocker |
|---|---|---|
| CMD-041 physical source mapping | RECONCILED AS PROPOSAL | Metric dictionary, scope-safe query plan, indexes, bounds and performance evidence |
| CMD-042 physical source mapping | RECONCILED AS PROPOSAL | Plan version selection rule, target progress PO decision, query plan and numeric bounds |
| CMD-043 read boundary | RECONCILED AS PROPOSAL | T-10 reader/purpose/field/retention policy and access-append failure semantics |
| CMD-044 export lifecycle | CANDIDATE MODEL DOCUMENTED; NOT ADMITTED | T-10 and T-18 institutional/security/operations approvals |

This update closes only the static object-mapping omission for CMD-041/042 and creates a reviewable candidate export model for CMD-044. It does not close the underlying business, institutional, runtime or certification gates.
