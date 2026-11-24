# Audit Event Catalogue and Governance

**Status:** Design draft — pending Product Owner, institutional security, privacy, and records approval  
**Package:** R  
**Date:** 2026-11-23  
**Implementation status:** Not implemented; no database migration, trigger, policy, export, or tamper-evidence control has been deployed or tested.

## 1. Purpose and governing principles

Define a consistent, privacy-conscious, append-only record of material business and security actions in Dit. SD Inspection. Audit evidence supports accountability, investigation, document provenance, and reconciliation; it is not a substitute for operational telemetry or a general-purpose debug log.

Principles:
- Record who did what, to which resource, in which authorized context, when, with what outcome, and why where required.
- Bind every event to the authenticated actor and the active role/operational scope used for authorization.
- Write critical audit events in the same database transaction as the protected state change.
- Deny ordinary application actors and application roles the ability to update or delete committed audit events.
- Minimize personal and device data; never store secrets, access tokens, signed URL tokens, raw evidence bytes, or unnecessary full payloads.
- Preserve historical meaning and configuration/version references.
- Make access to audit records itself auditable.
- Do not describe database append-only permissions or a hash chain as absolutely tamper-proof against a privileged database owner.

## 2. Event classes

| Class | Purpose | Examples | Storage/handling |
|---|---|---|---|
| Business audit | Evidence of a consequential workflow or record change | Inspection submitted, returned, approved, reopened; target/assignment changed; PDF issued | Durable transactional audit record |
| Security audit | Authentication, authorization, privileged access, and security-relevant outcomes | Account approval/rejection, role/scope change, access denied, privileged command, legal hold | Durable audit record; security alert may be emitted separately |
| Operational telemetry | Availability, latency, retries, resource usage, debugging | Request duration, queue depth, provider error details | Observability system; not automatically audit evidence |

A telemetry event becomes a business/security audit event only when it documents a defined accountable action or security outcome. Do not copy arbitrary debug logs into the audit table.

## 3. Canonical event envelope

Proposed logical fields (physical names/types to be finalized in Package L schema review):

| Field | Meaning | Rule |
|---|---|---|
| event_id | Unique event identifier | UUID; immutable |
| occurred_at | Authoritative event time | Server/database timestamp in UTC |
| recorded_at | Durable append time | Server/database timestamp in UTC |
| event_type | Stable namespaced event key | e.g. `inspection.submitted` |
| event_class | `BUSINESS`, `SECURITY`, or `GOVERNANCE` | Controlled enum |
| actor_user_id | Authenticated user/service identity | Nullable only for explicitly modeled unauthenticated/system events |
| actor_type | `USER`, `SYSTEM`, or `PROVIDER` | Controlled enum |
| active_role_id | Role context used for action | Required for user operational actions |
| project_id / session_id | Project/session scope | Nullable only when not applicable |
| location_id / assignment_id | Operational scope | Nullable only when not applicable |
| instrument_id / instrument_version_id | Instrument configuration context | Required for instrument-related actions |
| resource_type / resource_id | Target resource | Stable typed reference |
| action | Human-readable controlled action | No arbitrary client-supplied action text |
| outcome | `SUCCESS`, `DENIED`, `FAILED`, or `REJECTED` | Controlled enum |
| reason_code | Controlled reason | Required for sensitive rejection, override, reopen, deletion, and administrative changes |
| reason_text | Short explanatory text | Minimize; length limit and content rules |
| correlation_id | End-to-end request/workflow correlation | UUID |
| request_id | Server request identifier | Opaque, non-secret |
| idempotency_key_hash | Non-reversible digest/reference | Never store raw idempotency key |
| source_channel | Web/PWA/API/system/import | Controlled enum |
| client_version | App version, if known | No fingerprinting |
| network_metadata | Minimal security metadata | IP only if institution approves purpose, access, and retention; otherwise omit or truncate |
| before_summary / after_summary | Safe allow-listed field changes | No full row snapshots or secrets |
| metadata | Small typed event-specific attributes | Schema-validated allow-list only |
| previous_event_hash / event_hash | Optional integrity-chain fields | Only if implemented with verified canonical serialization and key management |

Use foreign keys where lifecycle retention permits. Where a referenced record may be lawfully deleted, retain a stable opaque identifier and minimal event context rather than weakening audit integrity or retaining prohibited personal data. This policy requires records/privacy approval.

## 4. Event catalogue

The catalogue below defines required event families. Exact event keys and payload schemas are implementation contracts only after approval.

### 4.1 Identity and access
- `auth.sign_in_succeeded`, `auth.sign_in_failed`, `auth.sign_out`
- `account.approved`, `account.rejected`, `account.suspended`, `account.reactivated`
- `role.assigned`, `role.revoked`, `permission.changed`, `scope.changed`
- `authorization.denied`, `privileged_command.executed`, `privileged_command.rejected`

### 4.2 Governance and configuration
- `project.created`, `project.updated`, `project.closed`
- `session.created`, `session.activated`, `session.paused`, `session.resumed`, `session.close_requested`, `session.closed`
- `target.created`, `target.reallocated`, `target.version_published`
- `assignment.created`, `assignment.changed`, `assignment.revoked`
- `capacity.limit_changed`
- `instrument.created`, `instrument.updated`, `instrument.activated`, `instrument.deactivated`
- `instrument.version_drafted`, `instrument.version_published`, `instrument.version_retired`
- `checklist_item.changed`, `evidence_slot.changed`, `document_template.changed`, `workflow_rule.changed`

### 4.3 Inspection lifecycle and evidence
- `unit.claimed`, `unit.claim_released`, `unit.claim_expired`
- `inspection.created`, `inspection.draft_saved`, `inspection.submitted`
- `inspection.returned_for_correction`, `inspection.resubmitted`, `inspection.approved`
- `inspection.reopened`, `inspection.cancelled`
- `evidence.uploaded`, `evidence.downloaded`, `evidence.access_denied`, `evidence.deletion_requested`, `evidence.deleted`
- `inspection_revision.created`, `inspection_revision.superseded`

### 4.4 Documents, reporting, and attendance
- `pdf.generated`, `pdf.regenerated`, `document.printed`, `document.reprinted`
- `ba.generated`, `ba.issued`, `ba.signed_copy_uploaded`, `ba.status_changed`
- `attendance.generated`, `attendance.printed`, `attendance.uploaded`, `attendance.replaced`, `attendance.verified`
- `report.generated`, `report.exported`, `report.approved`

### 4.5 Security, privacy, and operations
- `audit.exported`, `audit.accessed`, `audit.search_performed`
- `legal_hold.created`, `legal_hold.changed`, `legal_hold.released`
- `retention.disposition_requested`, `retention.disposition_completed`
- `security.incident_opened`, `security.incident_updated`, `security.incident_closed`
- `backup.started`, `backup.completed`, `backup.failed`, `restore.started`, `restore.completed`, `restore.failed`
- `provider.configuration_changed`, `production.release_deployed`, `production.rollback_performed`

Do not emit a success event when the operation failed. A denied attempt must be recorded as a security event when it meets the approved audit policy; avoid logging every harmless validation error.

## 5. Transaction and failure semantics

1. For a critical state-changing command, authorize first, perform the domain mutation, and append the corresponding audit event within one database transaction.
2. Commit both mutation and audit event together. If audit append fails, roll back the protected mutation (fail closed).
3. Do not acknowledge success to the caller until the transaction commits.
4. Idempotent retries must not create duplicate business mutations or contradictory audit outcomes. Link retries using correlation/request/idempotency references.
5. For external side effects (e.g. provider calls, file upload, PDF rendering), use an explicit state machine/outbox or reconciliation record. Record intent and final outcome; never claim the external action succeeded solely because the request was queued.
6. Security telemetry that is not part of a critical domain transaction may use a durable queue, but queue failure must be surfaced to monitoring and must not be silently discarded.
7. Define bounded retry, dead-letter, alert, and manual reconciliation behavior before production.
8. Clock source is server/database controlled. Client timestamps may be retained only as untrusted diagnostic metadata.

## 6. Append-only controls and integrity

- Application runtime roles receive INSERT and narrowly scoped SELECT only; no UPDATE or DELETE on committed audit rows.
- Audit writes occur through approved server-side commands or database functions, not arbitrary client DML.
- Audit readers receive least-privilege access by purpose and scope; bulk export is a separate permission.
- Any correction is a new compensating event referencing the prior event; never edit history in place.
- Database owners and provider administrators are privileged trust boundaries. Their actions require provider/platform audit evidence and periodic review.
- A hash chain can detect accidental or partial tampering only when canonicalization, sequencing, concurrency, and key handling are correctly designed. It does not prevent a sufficiently privileged owner from rewriting the database and recomputing hashes.
- If stronger independent evidence is required, evaluate periodic signed checkpoints and export to institution-approved immutable/WORM storage. This creates cost, key custody, retention, and operational dependencies and requires explicit approval; it is not assumed in the cost-first baseline.
- Define reconciliation checks for missing sequence ranges, duplicate IDs, invalid references, and hash verification if a chain is adopted.

## 7. Privacy and safe payload policy

Never include:
- Passwords, OAuth tokens, refresh tokens, API keys, service-role keys, cookies, authorization headers, signed URL query tokens, or raw credentials.
- Raw image/video/document bytes or unrestricted object metadata.
- Full inspection payloads, full user profiles, or unnecessary personal identifiers.
- Sensitive free-text notes unless a specific approved audit purpose requires a minimized excerpt.

Use allow-listed before/after summaries (for example, old/new role ID, old/new session state, old/new target value). Redact or omit fields classified as confidential or personal. Do not put signed Storage URLs in audit records; use object IDs and access events.

## 8. Retention, legal hold, access, and export

- Audit retention duration, archive tier, deletion authority, and legal-hold rules are OPEN pending institutional records/privacy/legal approval.
- Default design assumption: audit rows are not user-editable and are not deleted through ordinary application workflows.
- Retention disposition must be authorized, reasoned, scoped, approved, and audited; legal hold suspends disposition.
- Audit export must be purpose-bound, scoped, logged, integrity-checked, and protected as a sensitive document.
- Record who queried/exported audit data, the filter/scope, time, result count, and export artifact reference; avoid logging sensitive query contents.
- Audit access must not grant broader access to the underlying inspection/evidence data.

## 9. Roles and separation of duties

Proposed permission boundaries:
- Super Admin: manage audit policy/configuration only through explicit permission; read global audit where institutionally authorized; cannot erase history.
- Korlap/Admin: read operational events within assigned scope; no global audit access by default.
- Reviewer/Inspector/Print Officer: no general audit search; may view only relevant status/history required for their workflow.
- Security/Records Auditor: dedicated read/export permission, scoped or global as formally approved; no mutation.
- Database/provider administrator: privileged infrastructure access; independently monitored and periodically reviewed.

The actual role names, scope, auditor appointment, and export authority remain subject to institutional approval.

## 10. Verification requirements

- AUD-T01: every critical state transition commits exactly one corresponding audit event.
- AUD-T02: audit append failure rolls back critical domain mutation.
- AUD-T03: ordinary application roles cannot update/delete audit rows.
- AUD-T04: denied cross-scope access creates the configured security event without leaking protected data.
- AUD-T05: role, permission, scope, instrument version, target, and assignment changes record actor and before/after allow-listed summaries.
- AUD-T06: inspection revision, evidence, PDF, print/reprint, BA, attendance, and report events reference the correct immutable revision/configuration.
- AUD-T07: idempotent retry does not duplicate business outcome or corrupt event sequence.
- AUD-T08: audit search/export is itself audited and permission checked.
- AUD-T09: secret/token/URL-token/raw-media fields are rejected or redacted.
- AUD-T10: legal hold prevents retention disposition.
- AUD-T11: hash/checkpoint verification detects a deliberately modified test fixture if integrity mechanism is adopted.
- AUD-T12: backup/restore preserves audit sequence and verifiability.

Tests are specified only; none have been executed.

## 11. Open approvals and dependencies

1. **Superseded by T-15 (2026-11-24): INS-016 is PO APPROVED option A.** Append-only audit records, atomic critical mutation + audit, fail-closed behavior, privacy-safe event context and least-privilege read/export are approved product/technical direction. Institutional classification, retention, legal hold, disposition, network metadata and final export authority remain external approvals under T-10.
2. Records/privacy/legal owner must approve audit classification, retention duration, deletion/disposition, legal hold, and access/export authority.
3. Security owner must approve whether IP/network metadata is collected and its retention.
4. Project Sponsor must decide whether independent immutable/WORM archive is required and fund it if selected.
5. Database schema review must finalize indexes, partitioning, event payload schema, foreign-key/deletion strategy, and event sequencing.
6. T-18 has PO-approved the trusted caller-JWT command architecture; command-by-command contracts, RLS/EXECUTE grants, transactional audit implementation and security verification remain open.
7. Provider operational audit capabilities and retention must be verified against the actual plan.
8. Named accountable operational roles and incident escalation must be confirmed.

## 12. Scope and implementation gate

This package is a governance and architecture specification only. It does not authorize migrations, triggers, application code, external archive procurement, or production configuration. Implementation may begin only after the PO-approved T-15 audit direction is reconciled with institutional T-10 privacy/records obligations, Package L schema technical review, Package M RLS/grants, and the detailed T-18 Package N command contracts are approved and reconciled.



## 13. Product Owner decision — INS-016 approved direction (T-15, 2026-11-24)

**PO APPROVED option A.** The controls in this catalogue are approved as the required product/technical direction:

- Append-only audit records; ordinary application roles have no update/delete path.
- Critical state mutation and corresponding audit event are one atomic database transaction. Audit insertion failure aborts the critical mutation (fail closed).
- Event context includes actor identity, active role, scope, event/action, timestamp, correlation/idempotency references and privacy-safe change context.
- Sensitive evidence access and export generate auditable events.
- Audit read/export permissions are least-privilege and independently granted; never put secrets, credentials, raw evidence or unnecessary personal data into event payloads.

**Remaining external and technical gates:** T-10 institutional records/privacy/legal approval still controls classification, retention duration, deletion/disposition, legal hold and any network metadata collection. No duration, IP/network metadata policy, independent WORM archive or provider capability is approved here. Final schema/index/partition and deletion-linkage decisions, RLS grants, privileged command transaction implementation, provider verification and tests remain pending.

### Superseded status for section 11, item 1

The earlier statement that INS-016 awaits Product Owner approval is superseded by the T-15 decision dated 2026-11-24. INS-016 is **PO APPROVED (A)**; institutional records/privacy/security approvals and implementation evidence remain OPEN/BLOCKED as specified above.

This remains a design/governance document. No migrations, triggers, application code, archive procurement, or production configuration are authorized or claimed.
