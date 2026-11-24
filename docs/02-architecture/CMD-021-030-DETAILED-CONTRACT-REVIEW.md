# CMD-021–030 Detailed Contract Review

**Status:** Engineering contract review — proposal only; PO/security review required; NOT approved for implementation  
**Version:** 0.3.1  
**Date:** 2026-11-24  
**Scope:** CMD-021 through CMD-030  
**Controls:** T-15 append-only audit direction; T-16 canonical unit identity and association model; T-18 Option A command boundary; G9 NOT READY; G10 NOT AUTHORIZED.

## 1. Purpose, authority and source hierarchy

This document expands the canonical PostgreSQL Command Contract Catalogue for CMD-021–030. It is a documentation-only engineering review. It does not authorize application source changes, SQL, migrations, PostgreSQL functions, grants/revokes, RLS changes, live database changes, deployment, or merge.

Controlling source hierarchy:

1. PostgreSQL Command Contract Catalogue — stable logical command IDs, proposed permission codes, command intent and test-series references.
2. Physical Database Schema and Integrity Specification plus Data Model/ERD — proposed physical entities, keys and constraints; not proof of live schema.
3. Table-by-Table RLS Policy Catalogue and Physical Schema ↔ RLS ↔ Command Reconciliation — proposed access posture; not proof of deployed RLS or grants.
4. Audit Event Catalogue and Governance — proposed event vocabulary and append-only requirements.
5. Canonical Permission Registry and Command Authorization Matrix — permission semantics, scope classes and SoD; role-to-permission grants remain subject to approval.
6. T-15, T-16 and T-18 decisions — approved product/technical direction, without implying implementation readiness.

Where sources omit a field, conflict on lock order, or do not define a lifecycle, this review records a gap. It does not silently add tables, columns, states, permission grants, routes, RPCs or institutional rules.

## 2. Shared command boundary and transaction envelope

### 2.1 Transport, identity and trusted authorization

- Candidate transport: \`POST /api/commands/{logical-command-name}\`. Exact route names, API version and OpenAPI definitions remain provisional.
- Candidate RPC convention: \`public.cmd_<logical_command_name>_v1(...)\`. No candidate function is asserted to exist or approved for creation.
- Browser/PWA → Vercel server route → PostgreSQL command function, forwarding the authenticated caller JWT, is the PO-approved T-18 Option A flow.
- The route validates method, content type, body size, schema version, allowlisted fields and Supabase session. It must not replace a user-initiated caller identity with a service-role identity.
- PostgreSQL derives actor identity from \`auth.uid()\`, resolves exactly one approved/enabled \`app_users\` identity, and evaluates permission, scope, assignment membership, SoD, resource state and effective dates inside the mutation transaction.
- Client-supplied actor ID, reviewer/author ID, Inspector ID, role, permission, project scope, association status, claim expiry, inspection state, revision number, evidence verification status or audit actor is never authoritative.
- Protected business tables are command-only mutations. Browser-facing \`anon\`/\`authenticated\` roles receive no direct INSERT/UPDATE/DELETE. RLS remains an independent read boundary.
- Protected writes follow PO-approved T-18 Option A using narrow SECURITY DEFINER wrappers; each function requires individual approval, dedicated least-privileged NOLOGIN owner, fixed empty search_path, schema-qualified references, PUBLIC/anon denial and exact-signature EXECUTE grants. SECURITY INVOKER remains preferred for scoped reads and non-elevated helpers.
- Actual function owner, security mode, search_path, table privileges, function EXECUTE ACL and live RLS have not been verified against Supabase.

### 2.2 Proposed common mutation request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {}
}
\`\`\`

Actor and trusted authorization context are server-derived. Expected version fields are required only where the physical specification defines a concurrency token; do not invent one for entities without a defined version column.

### 2.3 Proposed common response

\`\`\`json
{
  "command_id": "uuid",
  "status": "accepted",
  "resource_id": "uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {},
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

Do not disclose canonical unit existence, candidate IDs, another project's association, inspection history, reviewer identity or other protected metadata to an unauthorized caller.

### 2.4 Idempotency and audit

- Mutation idempotency scope: authenticated actor + command type + resource/canonical identity scope + opaque key.
- Hash canonical schema version and normalized semantic payload. Transport-only metadata is excluded.
- Same key and same hash returns the original committed result after current authorization is re-evaluated. Same key and different hash returns \`IDEMPOTENCY_KEY_REUSED\`.
- Concurrent same-key requests produce one logical execution through atomic idempotency arbitration and a unique constraint.
- Idempotency record, domain mutation and required audit event commit or roll back atomically.
- Critical audit append failure aborts the domain mutation and suppresses success (T-15).
- Audit payloads are allowlisted and privacy-minimized. Never store secrets, signed URLs, raw evidence bytes, unrestricted inspection payloads or unnecessary personal data.
- Use database/server time for claim expiry, association validity, membership validity, inspection state and audit timestamps. Client timestamps may be retained only as untrusted diagnostic metadata.

### 2.5 Lock order and known catalogue conflict

The global command catalogue specifies the lock order:

\`idempotency arbitration → capacity row when relevant → canonical serial key → project/session/assignment → unit → association → inspection → evidence/document → append-only events\`.

Multi-row locks must be acquired in deterministic UUID/key order. The CMD-026 row in the command catalogue describes unit → association → assignment/claim, which conflicts with the global order. This review follows the global order as the candidate system-wide invariant and records the CMD-026 row for reconciliation; do not implement either order until the complete lock graph has been reviewed for deadlocks across all writers.

Do not hold database locks during Storage transfer, image inspection, malware scanning, PDF rendering or external network calls. External work uses an explicit intent/finalization or outbox/reconciliation state.

### 2.6 Shared verification minimum

Every command must have concrete test IDs allocated from the test catalogue and cover:

1. Authorized positive case and exact persisted state.
2. Unauthenticated, pending, rejected, suspended, disabled, expired and revoked identity cases as applicable.
3. Missing permission, wrong project/assignment/association scope and SoD violation.
4. Forged actor, author, reviewer, Inspector, project, association, status, revision, expiry, verification and audit fields.
5. Unknown/missing/extra fields, malformed IDs, invalid enum values, boundary values and oversized payloads.
6. Same-key/same-payload replay and same-key/different-payload rejection.
7. Concurrent conflicting commands, lock order and deadlock behavior.
8. Required audit append failure rollback.
9. Direct browser DML denial and exact function EXECUTE ACL.
10. Cross-project, cross-unit, cross-assignment, cross-instrument and cross-revision reference substitution.
11. Historical immutability and preservation of submitted evidence/revisions.

These are test specifications, not executed tests.

## 3. Detailed command contracts

## CMD-021 — deactivate-instrument

**Permission:** \`instrument.deactivate\`  
**Candidate route:** \`POST /api/commands/deactivate-instrument\`  
**Candidate RPC:** \`public.cmd_deactivate_instrument_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "instrument_id": "uuid",
    "reason": "string",
    "expected_version": 4
  }
}
\`\`\`

\`expected_version\` is included by the canonical command catalogue but the physical \`instruments\` table does not define a version/row_version field. The request is therefore provisional until the physical concurrency contract is approved.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "deactivated",
  "resource_id": "instrument-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "previous_status": "ACTIVE",
    "status": "INACTIVE",
    "future_assignment_selection_allowed": false
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

The result field \`future_assignment_selection_allowed\` is descriptive only; its exact meaning and whether INACTIVE and ARCHIVED have distinct selection behavior require approval.

### Authorization, scope and SoD

- Caller must be an approved/enabled Super Admin with explicit \`instrument.deactivate\`; \`instrument.manage\` or \`instrument.publish\` alone is insufficient.
- Global catalog authority does not grant operational project access.
- Instrument must exist and be in a state that permits deactivation. Only ACTIVE → INACTIVE is a safe candidate transition; INACTIVE replay and ARCHIVED behavior require a defined state matrix.
- Require a non-empty bounded reason.
- Deactivation must not rewrite published versions, assignment bindings, inspection snapshots, revisions, evidence, reports or history.
- Deactivation should prevent new assignment selection only if that rule is explicitly approved. Existing assignments already pinned to published versions must retain historical meaning; whether active assignments may continue or must be operationally closed is unresolved.
- No second-person approval is implied by T-17 for this command; T-17's direct-publish decision is not a blanket exemption from other institutional controls.

### Physical read/write set

- Read: \`instruments\`, \`instrument_versions\`, \`operational_assignments\` (future/current selection impact), \`idempotency_records\`.
- Write: \`instruments\`, \`idempotency_records\`, \`audit_events\`.
- No write to \`instrument_versions\`, \`instrument_version_publications\`, assignment rows, inspections or historical records.
- Physical \`instruments\` columns are \`id, code, name, description, status, created_by\`; no version column is specified.

### Transaction, lock and idempotency

- Claim idempotency key; lock instrument row.
- Re-evaluate permission and current catalog state under lock.
- Check assignment references to determine the effect on future selection and whether an approved operational guard blocks deactivation. Do not infer an unapproved rule from the mere existence of active assignments.
- Apply only the approved lifecycle transition; preserve all published version and assignment references.
- Append \`instrument.deactivated\` and idempotency result atomically.
- A concurrency token must be specified before using \`expected_version\`; do not substitute updated_at or client-supplied values.

### Audit and typed outcomes

- Required event: \`instrument.deactivated\`; include actor, instrument ID, previous/new status, reason and correlation reference.
- Outcomes: \`DEACTIVATED\`, \`ALREADY_INACTIVE\`, \`INVALID_STATE\`, \`ACTIVE_ASSIGNMENT_GUARD\` (only if approved), \`STALE_VERSION\` (only after physical versioning exists), \`NOT_FOUND\` (only where disclosure is authorized), \`DENIED\`, \`VALIDATION_FAILED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Authorized ACTIVE → INACTIVE.
- \`instrument.manage\` without \`instrument.deactivate\` denied.
- Non-Super-Admin, inactive account and unauthorized global catalog scope denied.
- Reject missing/blank reason and forged status/actor/version.
- Verify no published version, assignment, inspection or revision is rewritten.
- Verify new assignment selection behavior and existing assignment behavior after PO decision.
- Concurrent deactivate vs assignment publication; deterministic outcome under approved lock strategy.
- Audit failure rolls back status change.

### Open decisions

1. Define ACTIVE/INACTIVE/ARCHIVED transition matrix and idempotent repeated-deactivation behavior.
2. Decide whether deactivation is blocked by future/current assignments or merely prevents new selection.
3. Add an explicit instrument concurrency token or remove expected_version from the contract.
4. Define whether reactivation exists and its permission/approval path.

## CMD-022 — register-canonical-unit

**Permission:** \`unit.register\`  
**Candidate route:** \`POST /api/commands/register-canonical-unit\`  
**Candidate RPC:** \`public.cmd_register_canonical_unit_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "instrument_id": "uuid",
    "serial_raw": "string-or-null",
    "identity_attributes": {
      "manufacturer": "optional string",
      "model": "optional string"
    },
    "registration_context": {
      "project_id": "uuid",
      "assignment_id": "uuid"
    }
  }
}
\`\`\`

The command catalogue describes \`serial_raw?\` and \`identity_attributes?\`, but not a physical identity-attributes schema or explicit registration_context object. The context above is a proposed minimum authorization envelope, not an approved field schema. The server must verify context against the caller's actual project/assignment scope; it must not create an association as an implicit side effect.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "registered",
  "resource_id": "canonical-unit-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "instrument_id": "instrument-uuid",
    "serial_state": "KNOWN",
    "registration_outcome": "REGISTERED"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

For privacy, a collision response must not disclose the existing canonical unit ID or another project's association. A conflict result should return only the conflict resource ID and next permitted action, subject to conflict-reviewer access.

### Authorization, canonical identity and privacy

- Caller must be an approved/enabled actor with \`unit.register\` and explicit project/assignment authority to register a unit in the supplied context. A permission code alone is not proof of assignment scope.
- Validate that the assignment, project and instrument are mutually consistent and that the caller has the required operational role/scope.
- The physical canonical \`units\` table is project-independent; it has no \`project_id\`. Do not add project ownership to the unit.
- T-16 PO-approved option B: a known serial is unique per instrument across all projects, using \`(instrument_type, serial_normalized)\`; project ID is not part of the canonical key.
- Preserve exact submitted value in \`serial_raw\`. Candidate normalization: Unicode NFC, trim leading/trailing whitespace, collapse repeated internal whitespace to one ASCII space; case folding only when the instrument's published policy declares case-insensitive identifiers; preserve punctuation and leading zeroes; record \`normalization_version\`.
- Instrument-specific normalization policy must be published/versioned and tested before use. No policy may silently strip hyphens, slashes or leading zeros.
- Null/unknown serial must not receive a shared normalized key; the command catalogue says an unknown serial receives a distinct UUID. The exact unknown-serial identity/duplicate-prevention workflow remains unresolved.
- If a known serial already exists under the same instrument, do not create a second canonical unit. If the caller is not authorized to view that unit/association, return a privacy-safe conflict outcome without confirming cross-project existence. The canonical command catalogue says a same-type collision opens a controlled conflict record; exact conflict-creation trigger and disclosure policy require reconciliation.
- Registration creates canonical identity only. It does not create a project association, claim or inspection.

### Physical read/write set

- Read: \`instruments\`, \`units\`, \`operational_assignments\`, \`projects\`, \`idempotency_records\`; read existing \`unit_project_associations\` only when the approved collision/visibility policy requires it.
- Write: \`units\` for a genuinely new canonical identity; \`unit_identity_conflicts\` for a controlled collision workflow if the approved policy says registration creates a conflict; \`idempotency_records\`; \`audit_events\`.
- No write to \`unit_project_associations\`, \`unit_claims\` or \`inspections\`.
- Physical columns: \`units(id, instrument_type, serial_raw, serial_normalized, normalization_version, status)\`; known serial unique key is \`(instrument_type, serial_normalized)\` for non-null serials.

### Transaction, lock and idempotency

- Claim idempotency key.
- Resolve and authorize instrument/project/assignment context.
- Normalize known serial with the instrument's approved versioned policy.
- Arbitrate canonical key atomically using the unique constraint; if concurrency races, exactly one canonical unit may be created.
- For a same-key collision, follow the approved conflict workflow; do not create a duplicate unit or reveal protected candidate details.
- For unknown serial, generate a new server UUID and store no shared normalized key. Any later identification/merge is outside this command and must use an approved conflict workflow.
- Append \`unit.registered\` for a successful canonical insert; if conflict record creation is an approved outcome, append the exact conflict event only after its event key is added to the audit catalogue.
- Insert idempotency result and required audit event atomically.

### Audit and typed outcomes

- Successful event: \`unit.registered\`.
- The command catalogue also describes \`identity_conflict_opened\`, but that exact event key is absent from the current audit event catalogue. It must not be emitted until formally added/approved; reconcile with the canonical conflict lifecycle event naming.
- Outcomes: \`REGISTERED\`, \`EXISTING_AUTHORIZED\` (only when disclosure is explicitly permitted), \`CONFLICT_REVIEW_REQUIRED\`, \`INSTRUMENT_NOT_FOUND\`, \`ASSIGNMENT_SCOPE_DENIED\`, \`SERIAL_POLICY_UNAVAILABLE\`, \`SERIAL_INVALID\`, \`DUPLICATE_CANONICAL_KEY\`, \`VALIDATION_FAILED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Register known serial with canonical normalization and preserve raw input.
- Test NFC-equivalent values, whitespace normalization, case-sensitive vs case-insensitive instrument policy, punctuation and leading zeros.
- Same instrument + same normalized serial in two projects never creates two units.
- Same serial under different instrument IDs remains a distinct canonical identity.
- Unknown/null serial creates distinct server-generated unit IDs and no shared normalized key.
- Race concurrent registration of same normalized serial; unique constraint allows one canonical unit.
- Unauthorized project/assignment context denied; no cross-project existence disclosure.
- Verify no association, claim or inspection is created.
- Audit failure rolls back unit/conflict record and idempotency result.

### Open decisions

1. Approve identity_attributes schema, allowable values and whether they are stored on \`units\` or a separate approved entity; current physical table does not define those columns.
2. Define unknown-serial registration and later identification policy.
3. Define exact duplicate/collision behavior and privacy-safe response semantics.
4. Add/approve the canonical audit event for opening a unit identity conflict.
5. Finalize instrument-specific serial policy storage, versioning and activation process.
6. Confirm whether a registration context must include assignment, project, both, or a separately authorized registration scope.

## CMD-023 — associate-unit-to-project

**Permission:** \`unit.associate\`  
**Candidate route:** \`POST /api/commands/associate-unit-to-project\`  
**Candidate RPC:** \`public.cmd_associate_unit_to_project_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "unit_id": "canonical-unit-uuid",
    "project_id": "project-uuid",
    "reason": "string",
    "evidence_ref": null
  }
}
\`\`\`

\`evidence_ref\` is present in the canonical catalogue as optional but is not mapped to a physical association-proof table or a defined evidence reference type. It must remain omitted/null until its contract and retention/privacy rules are approved.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "associated",
  "resource_id": "association-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "unit_id": "canonical-unit-uuid",
    "project_id": "project-uuid",
    "status": "ACTIVE"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope and SoD

- Caller must hold \`unit.associate\` and explicit authority for the target project; global visibility of a canonical unit does not establish project authority.
- Caller must be authorized to identify the unit candidate. A unit UUID alone is not a proof of project association or permission.
- Verify unit and project exist; verify unit instrument is compatible with the project's authorized operational use. Exact instrument/project allowlist is not yet defined.
- If the unit is the candidate of an unresolved identity conflict, require the designated conflict-resolution workflow (CMD-025); CMD-023 must not bypass conflict review.
- Reject if an ACTIVE association for the same \`(unit_id, project_id)\` already exists. A historical ENDED/REVOKED association does not itself prohibit a new association episode if institutional policy permits re-association.
- Require a bounded, non-empty reason. Whether second-person verification is required is not specified and must not be invented.
- Association is a project visibility/workflow boundary. It does not create a claim or grant access to other projects.

### Physical read/write set

- Read: \`units\`, \`projects\`, \`unit_project_associations\`, \`unit_identity_conflicts\`, and project-scoped instrument/assignment configuration as needed; \`idempotency_records\`.
- Write: \`unit_project_associations\`, \`idempotency_records\`, \`audit_events\`.
- No write to \`units\`, \`unit_claims\`, \`inspections\` or historical association rows.
- Physical association columns: \`id, unit_id, project_id, status, associated_at, associated_by, association_reason, ended_at, ended_by, end_reason\`; partial unique ACTIVE \`(unit_id, project_id)\`; unique \`(id, unit_id, project_id)\` supports composite references.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock canonical unit row, then target project row and association-key range/unique key in the globally approved lock order. The final lock order must be reconciled with all unit/assignment commands.
- Re-check caller project authority and conflict status under lock.
- Insert a new ACTIVE association episode with server-derived associated_by/time and reason.
- Let the partial unique index arbitrate concurrent duplicate ACTIVE association creation.
- Append \`unit.project_associated\` and idempotency result atomically.
- Never update a historical ENDED/REVOKED episode to ACTIVE; create a new association episode if re-association is allowed.

### Audit and typed outcomes

- Required event: \`unit.project_associated\`; include unit ID, project ID, association ID, actor, reason and correlation reference, but no unrelated project history.
- Outcomes: \`ASSOCIATED\`, \`ACTIVE_ASSOCIATION_EXISTS\`, \`CONFLICT_OPEN\`, \`UNIT_NOT_FOUND\` (only if disclosure is authorized), \`PROJECT_NOT_FOUND\` (only if disclosure is authorized), \`INSTRUMENT_NOT_ALLOWED\`, \`SCOPE_DENIED\`, \`REASON_REQUIRED\`, \`VALIDATION_FAILED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Authorized association creates exactly one ACTIVE episode.
- Same unit can have separate project associations when policy permits, without changing canonical identity.
- Duplicate concurrent ACTIVE association requests yield one row.
- Cross-project authority denied; unit ID alone grants no access.
- Unresolved conflict cannot be bypassed.
- Historical ENDED/REVOKED association remains unchanged.
- Verify no claim or inspection side effect.
- Audit failure rolls back association and idempotency result.

### Open decisions

1. Define instrument/project compatibility and registration/association eligibility.
2. Decide if re-association after ENDED/REVOKED is permitted and under which evidence/approval rules.
3. Define the optional evidence_ref schema and physical provenance model, or remove it from the request.
4. Define any independent verification/SoD requirement for association.

## CMD-024 — end-unit-project-association

**Permission:** \`unit.association.end\`  
**Candidate route:** \`POST /api/commands/end-unit-project-association\`  
**Candidate RPC:** \`public.cmd_end_unit_project_association_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "association_id": "uuid",
    "outcome": "ENDED",
    "reason": "string",
    "expected_version": 2
  }
}
\`\`\`

Allowed outcomes in the canonical catalogue: \`ENDED\` or \`REVOKED\`. \`expected_version\` is listed but association physical schema has no version field; the request is provisional until versioning is resolved.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "ended",
  "resource_id": "association-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "previous_status": "ACTIVE",
    "status": "ENDED",
    "ended_at": "UTC timestamp"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope and SoD

- Caller must hold \`unit.association.end\` for the association's project; derive project_id from the stored association, never from client input.
- Require an explicit reason. \`ENDED\` and \`REVOKED\` must have distinct approved meanings, authority and downstream effects; do not treat them as synonyms.
- Preserve all historical inspections, claims, revisions, responses and evidence referencing the association.
- The physical specification says an association may be ended without rewriting historical inspections. An ACTIVE claim or in-progress workflow may block the operation; the exact gate and whether a future-effective end is allowed remain unresolved.
- Do not release a claim, cancel an inspection, delete evidence, reassign work or change user roles as an implicit side effect.
- If the association has active work, return a typed blocker unless the approved policy explicitly defines a safe future-effective transition.

### Physical read/write set

- Read: \`unit_project_associations\`, \`units\`, \`unit_claims\`, \`inspections\`, \`operational_assignments\`, \`assignment_members\`, and related active workflow state; \`idempotency_records\`.
- Write: \`unit_project_associations\` (status, ended_at, ended_by, end_reason only); \`idempotency_records\`; \`audit_events\`.
- No writes to \`units\`, \`unit_claims\`, \`inspections\`, \`inspection_revisions\`, evidence or assignment/member rows.
- Physical association schema has no row_version/updated_at column despite the catalogue's expected_version field.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock canonical unit, association and relevant active claim/inspection rows in the globally approved deterministic order.
- Re-check association is ACTIVE, actor has project authority, and outcome is valid.
- Evaluate active claim and workflow dependencies using database time. If a dependency blocks, make no mutation and return the exact safe typed outcome.
- If permitted, set status and server-derived ended_at/ended_by/end_reason; preserve association row as durable history.
- Append \`unit.project_association_ended\` or \`unit.project_association_revoked\` as the exact event key. These keys are in the audit catalogue only in the family form; confirm final key mapping before implementation.
- Commit mutation, audit and idempotency result atomically.

### Audit and typed outcomes

- Required event: exact event for ENDED vs REVOKED; do not collapse two outcomes into an ambiguous generic event without catalogue approval.
- Outcomes: \`ENDED\`, \`REVOKED\`, \`ACTIVE_WORK_BLOCKS\`, \`ALREADY_ENDED\`, \`INVALID_OUTCOME\`, \`STALE_VERSION\` (only after physical versioning exists), \`SCOPE_DENIED\`, \`REASON_REQUIRED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- End and revoke each follow separately approved semantics.
- Reject invalid outcome, missing reason and unauthorized project scope.
- Active claim and in-progress inspection gate behaves exactly as approved; no hidden release/cancel side effect.
- Historical submitted inspections/revisions/evidence remain readable in their original scope after association end.
- Concurrent claim acquisition vs association end serializes without leaving a claim attached to an invalid association.
- Re-association creates a new episode; prior association is not reactivated.
- Audit failure rolls back association transition.

### Open decisions

1. Define ENDED vs REVOKED semantics, permissions and any independent approval.
2. Define behavior for active claim, draft inspection, submitted/reviewable inspection and future-effective association end.
3. Add row_version or remove expected_version from the contract.
4. Finalize exact audit event keys and payload.

## CMD-025 — resolve-unit-identity-conflict

**Permission:** \`unit.identity.resolve\`  
**Candidate route:** \`POST /api/commands/resolve-unit-identity-conflict\`  
**Candidate RPC:** \`public.cmd_resolve_unit_identity_conflict_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "conflict_id": "uuid",
    "resolution": "ASSOCIATE_EXISTING",
    "verified_unit_id": "canonical-unit-uuid",
    "reason": "string"
  }
}
\`\`\`

For \`REJECT\`, \`verified_unit_id\` must be omitted. The server rejects a candidate ID supplied for a REJECT action. Exact allowed resolution values follow the canonical catalogue: \`ASSOCIATE_EXISTING\` or \`REJECT\`.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "resolved",
  "resource_id": "conflict-uuid",
  "resource_version": null,
  "server_time": "UTC timestamp",
  "result": {
    "resolution": "ASSOCIATE_EXISTING",
    "association_id": "new-association-uuid"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

The response must not return unrelated candidate-project data. For REJECT, association_id is null.

### Authorization, scope and SoD

- Caller must be an approved/enabled designated conflict reviewer with explicit \`unit.identity.resolve\`; project operational membership alone is insufficient.
- Enforce independent verification. The conflict reporter, candidate submitter and resolver relationship must be evaluated under an approved SoD policy. The exact non-self-resolution rule is not yet stated in the physical schema/command catalogue and requires PO/security approval.
- Resolve only a conflict in an open/reviewable state.
- For \`ASSOCIATE_EXISTING\`, candidate must match the conflict's \`instrument_type\` and \`serial_normalized\` exactly under the same normalization version/policy; never accept a different instrument or normalized key.
- Do not create a new canonical unit, clone a unit, merge identities, rewrite historical inspection/claim rows or expose the candidate's other project history.
- Create a new project association episode only if the proposed project and reviewer authority are valid and no ACTIVE association already exists.
- For \`REJECT\`, close the conflict with a reason and no association side effect.
- The institution-specific exception policy for duplicate serials remains open; do not invent an exception path.

### Physical read/write set

- Read: \`unit_identity_conflicts\`, \`units\`, \`projects\`, \`unit_project_associations\`, reviewer identity/permission/scope state; \`idempotency_records\`.
- Write: \`unit_identity_conflicts\` (resolution, resolved_by, resolution_reason, resolved_at, status); \`unit_project_associations\` only for approved ASSOCIATE_EXISTING; \`idempotency_records\`; \`audit_events\`.
- No write to canonical \`units\`, historical associations, inspections, claims, revisions or evidence.
- Physical conflict columns include \`instrument_type, serial_normalized, serial_raw_submitted, proposed_project_id, candidate_unit_id, reported_by, status, resolution, resolved_by, resolution_reason, created_at, resolved_at\`.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock conflict row first; then candidate unit and project/association key in deterministic order, reconciling with the global canonical serial/project/unit lock hierarchy.
- Re-evaluate reviewer authority, conflict state, candidate match and independent verification under lock.
- ASSOCIATE_EXISTING inserts a new ACTIVE association episode; REJECT writes only the conflict resolution fields.
- Use unique ACTIVE association constraint as the final concurrency arbiter.
- Append the exact conflict-resolved or conflict-rejected audit event and idempotency result atomically.
- A second concurrent resolver must receive a typed already-resolved/state-conflict result and must not append a second resolution event.

### Audit and typed outcomes

- The command catalogue names \`unit.identity_conflict_resolved\` and \`unit.identity_conflict_rejected\`; these exact event keys are not currently enumerated in the audit event catalogue. Add and approve them before implementation.
- Outcomes: \`RESOLVED\`, \`REJECTED\`, \`CANDIDATE_MISMATCH\`, \`CONFLICT_NOT_OPEN\`, \`ASSOCIATION_EXISTS\`, \`SOD_VIOLATION\`, \`DENIED\`, \`REASON_REQUIRED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Valid candidate with exact instrument and normalized serial creates one new association.
- Reject candidate with wrong instrument, serial, normalization version or project.
- REJECT closes conflict with reason and creates no association.
- Non-reviewer, unauthorized scope and prohibited self-resolution denied.
- Concurrent resolution attempts produce exactly one resolution and one audit event.
- No canonical unit clone/merge or historical rewrite occurs.
- Cross-project metadata disclosure denied.
- Audit failure rolls back conflict resolution and any new association.

### Open decisions

1. Approve conflict-reviewer appointment and exact SoD (including reporter/resolver independence).
2. Define conflict status machine and allowed transitions.
3. Add exact audit event keys and payload schemas.
4. Define association behavior where proposed project already has an ACTIVE association.
5. Approve institution-specific serial exception process before any exception is implemented.

## CMD-026 — claim-unit

**Permission:** \`inspection.claim\`  
**Candidate route:** \`POST /api/commands/claim-unit\`  
**Candidate RPC:** \`public.cmd_claim_unit_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "unit_id": "canonical-unit-uuid",
    "association_id": "association-uuid",
    "assignment_id": "assignment-uuid"
  }
}
\`\`\`

The command catalogue permits unit ID or serial input. This review recommends a canonical unit ID after an authorized scoped lookup; if serial lookup is retained, it must use the exact instrument policy and never reveal cross-project canonical identity. \`expected_version?\` is listed ambiguously in the catalogue; the physical \`unit_claims\` table has \`row_version\`, but the exact expected version target (unit, claim or inspection) is not specified. Do not include an undefined expected field in the frozen API schema.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "claimed",
  "resource_id": "claim-uuid",
  "resource_version": 1,
  "server_time": "UTC timestamp",
  "result": {
    "inspection_id": "inspection-uuid",
    "unit_id": "canonical-unit-uuid",
    "association_id": "association-uuid",
    "assignment_id": "assignment-uuid",
    "claim_status": "ACTIVE",
    "expires_at": "UTC timestamp"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

Expiry duration and renewal policy are not specified here; the server must not accept a client-chosen expires_at.

### Authorization, scope, SoD and invariants

- Caller must be an approved/enabled Inspector with \`inspection.claim\` and effective membership in the exact active assignment.
- Association must be ACTIVE at the database serialization point and match the canonical unit and project.
- Assignment must be active/effective, belong to the same project as the association, and reference the same instrument as the canonical unit.
- Caller must be an active assignment member with operational role Inspector for the effective time.
- Enforce one ACTIVE claim globally per canonical unit across all projects using the partial unique index on \`unit_claims(unit_id)\`.
- A unit UUID alone does not grant project visibility; all access flows through \`unit_project_associations\` and explicit assignment scope.
- If an ACTIVE claim exists, return a privacy-safe \`ACTIVE_CLAIM_EXISTS\` or authorized resume outcome. Do not disclose holder identity or other project information unless the caller is explicitly authorized.
- The command catalogue says \`CLAIMED/RESUMED\` and that claim creates inspection. Exact resume behavior, claim ownership transfer and existing draft selection must be specified. A resume must not silently create a second active inspection lifecycle.
- Reinspection after completed/approved work follows a separately authorized lifecycle; claim command must not bypass reopen/reinspection policy.
- Server/database time controls claim expiry. Client clock and client-provided expiry are ignored.

### Physical read/write set

- Read: \`units\`, \`unit_project_associations\`, \`projects\`, \`operational_assignments\`, \`assignment_members\`, \`instruments\`, \`instrument_versions\`, \`unit_claims\`, \`inspections\`, \`idempotency_records\`.
- Write: \`unit_claims\`, \`inspections\`, \`inspection_events\` (if inspection.created is represented there), \`idempotency_records\`, \`audit_events\`.
- The command catalogue explicitly states claim and inspection creation; the physical schema requires an inspection lifecycle and claim references. Exact event-row creation and initial inspection revision creation need final mapping.
- No write to \`units\`, association, assignment membership, instrument configuration, checklist responses or evidence.
- Physical \`unit_claims\` contains \`row_version\`; \`inspections\` contains \`row_version\`. Both must have defined initial/increment rules.

### Transaction, lock and idempotency

- Claim idempotency key.
- Resolve the canonical serial key if serial lookup is supported; then acquire locks in the globally approved order: canonical serial key → project/session/assignment → unit → association → inspection/claim rows.
- Recheck caller permission, assignment membership, association status, instrument match and all effective intervals under lock.
- Check claim expiry using database time. If an expired claim can be taken over, the policy must preserve draft/evidence and explicitly define whether the existing inspection remains with the previous owner, is handed off, or is locked pending reconciliation.
- Insert ACTIVE claim and inspection lifecycle atomically; enforce partial unique active claim index as the final arbiter.
- If an existing inspection is resumed, link the new claim only under the approved lifecycle; do not create a duplicate active inspection.
- Append \`unit.claimed\` and \`inspection.created\` if a new inspection is created; a resumed claim needs a separately defined event (do not falsely emit inspection.created).
- Insert idempotency result in the same transaction. Audit failure rolls back claim and inspection creation.

### Audit and typed outcomes

- Required events: \`unit.claimed\`; \`inspection.created\` only for a newly created inspection. The audit catalogue also defines \`unit.claim_expired\` and \`unit.claim_released\`.
- Outcomes: \`CLAIMED\`, \`RESUMED\`, \`ACTIVE_CLAIM_EXISTS\`, \`ASSOCIATION_REQUIRED\`, \`ASSOCIATION_INACTIVE\`, \`ASSIGNMENT_INVALID\`, \`ASSIGNMENT_SCOPE_DENIED\`, \`INSTRUMENT_MISMATCH\`, \`CLAIM_EXPIRED\`, \`INSPECTION_LIFECYCLE_BLOCKED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Valid Inspector claims a unit in an active same-project assignment.
- Reject inactive association, wrong project, wrong instrument, expired membership and non-Inspector assignment member.
- Concurrent claims from different projects result in exactly one ACTIVE claim globally.
- Expiry takeover uses server time and preserves draft/evidence.
- Test same-key replay and distinct-key repeat claim.
- Test resume vs new inspection lifecycle; no duplicate active inspection.
- Unauthorized caller cannot enumerate canonical units or discover cross-project claim holder.
- Audit failure rolls back claim and inspection creation.
- Verify lock order against CMD-023/024/025/027 and all association writers.

### Open decisions

1. Resolve catalogue lock-order conflict for CMD-026 and publish one global lock graph.
2. Define claim TTL, expiry scheduler/command, renewal, takeover and offline grace semantics.
3. Define resume and reassignment behavior, especially preservation/ownership of existing draft and evidence.
4. Define one-active-inspection lifecycle and reinspection/reopen interaction.
5. Define exact expected_version target and row_version increment rules.
6. Finalize whether claim creates inspection revision zero/draft context and which event records it.

## CMD-027 — release-unit-claim

**Permission:** \`inspection.claim\`  
**Candidate route:** \`POST /api/commands/release-unit-claim\`  
**Candidate RPC:** \`public.cmd_release_unit_claim_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "claim_id": "uuid",
    "reason": "string",
    "expected_version": 3
  }
}
\`\`\`

The canonical catalogue lists \`reason?\` and \`expected_version?\`; this review recommends requiring reason for an explicit user-initiated release. The physical claim table defines row_version, but whether expected_version is mandatory and which claim lifecycle transitions increment it need approval.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "released",
  "resource_id": "claim-uuid",
  "resource_version": 4,
  "server_time": "UTC timestamp",
  "result": {
    "inspection_id": "inspection-uuid",
    "claim_status": "RELEASED",
    "inspection_status": "DRAFT_PRESERVED"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

\`DRAFT_PRESERVED\` is descriptive, not an approved inspection status. The inspection's actual state must not change unless a separate approved transition explicitly requires it.

### Authorization, scope and SoD

- Caller must be the current claim owner with \`inspection.claim\`, or an explicitly authorized supervisor with the exact release permission and scope. Generic Super Admin title alone is insufficient.
- Derive claim owner, unit, association, project and assignment from database state.
- Verify claim is ACTIVE and belongs to the caller, unless a specific supervisor release rule is approved.
- Reject release if inspection is in a state that the approved workflow prohibits releasing (e.g. submitted/reviewable); the exact state matrix is not complete.
- Release must preserve draft response data, uploaded/finalized evidence, revision history and association reference.
- Release does not cancel inspection, end association, reassign work, delete evidence or modify assignment membership.
- If claim has expired, distinguish already expired from explicitly released; do not rewrite the expiry event as a user release.

### Physical read/write set

- Read: \`unit_claims\`, \`units\`, \`inspections\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`idempotency_records\`.
- Write: \`unit_claims\` (status, released_at, row_version); \`idempotency_records\`; \`audit_events\`.
- Write to \`inspection_events\` only if the approved state machine explicitly defines a corresponding inspection transition; otherwise no inspection write.
- No write to checklist/specification responses, inspection revisions, evidence assets, canonical unit or association.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock canonical unit, association, assignment, claim and inspection in globally approved order.
- Recheck current owner/supervisor authority, claim state, expected row_version and inspection state.
- Update claim to released with server time and increment row_version atomically.
- Append \`unit.claim_released\` and idempotency result in the same transaction.
- Concurrent release vs claim expiry/takeover must yield exactly one terminal claim outcome; no double release or overlapping ACTIVE claims.
- Audit failure rolls back release and version increment.

### Audit and typed outcomes

- Required event: \`unit.claim_released\`; distinguish actor-initiated release from system expiry through actor_type/event metadata.
- Outcomes: \`RELEASED\`, \`ALREADY_RELEASED\`, \`ALREADY_EXPIRED\`, \`NOT_OWNER\`, \`SUPERVISOR_SCOPE_DENIED\`, \`INVALID_STATE\`, \`STALE_VERSION\`, \`REASON_REQUIRED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Claim owner releases ACTIVE claim; draft/evidence remain unchanged.
- Non-owner and unauthorized supervisor denied.
- Submitted/reviewable/approved state behavior follows approved gate.
- Concurrent release vs expiry/takeover produces one terminal state and one event.
- Stale expected version rejected.
- Verify no association, inspection response or evidence mutation.
- Audit failure rolls back claim release.

### Open decisions

1. Define supervisor authority and exact permission/scope; do not infer from role name.
2. Approve whether release reason is mandatory.
3. Define release eligibility by inspection lifecycle state.
4. Define claim row_version initialization/increment and whether expected_version is required.
5. Define expiry vs release event ordering and scheduler interaction.

## CMD-028 — save-draft

**Permission:** \`inspection.edit\`  
**Candidate route:** \`POST /api/commands/save-draft\`  
**Candidate RPC:** \`public.cmd_save_draft_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "inspection_id": "uuid",
    "expected_row_version": 12,
    "patch": {
      "checklist_responses": [
        {
          "checklist_item_id": "uuid",
          "answer": true,
          "note": null
        }
      ],
      "specification_responses": [
        {
          "specification_field_id": "uuid",
          "observed_value": {
            "decimal": "12.50"
          },
          "note": null
        }
      ],
      "notes": null
    }
  }
}
\`\`\`

The payload is a strict patch schema, not an arbitrary JSON merge. Exact answer/value unions must be derived from the published instrument schema version pinned to the inspection. Numeric values must be decimal-safe; do not parse measurements through binary floating point.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "saved",
  "resource_id": "inspection-uuid",
  "resource_version": 13,
  "server_time": "UTC timestamp",
  "result": {
    "current_revision_no": 1,
    "saved_checklist_response_count": 1,
    "saved_specification_response_count": 1,
    "changed": true
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope and SoD

- Caller must be the Inspector who owns the current ACTIVE claim and holds \`inspection.edit\` within the exact assignment scope.
- Inspection, claim, association, project, assignment and Inspector membership must match; derive all relationships from stored records.
- Claim must be ACTIVE and unexpired at database time; association and assignment membership must be effective.
- Inspection must be in the approved editable draft state. Submitted, returned, approved, cancelled or otherwise terminal states must not be writable unless the approved lifecycle explicitly allows a draft after return.
- Each checklist item and specification field must belong to the exact instrument version pinned to the inspection/assignment. Reject cross-version item/field substitution.
- Validate answer type, required fields, applicability, bounds, enum choices, decimal precision, unit, note length and supported declarative rules server-side.
- Client cannot set \`answered_by\`, \`answered_at\`, author, actor, current_revision_no, row_version, status, instrument_version_id, association, assignment or evidence verification.
- Notes are potentially sensitive free text; enforce size limits and approved privacy policy. Never copy unrestricted notes into audit metadata.
- Patch semantics must define omitted vs explicit null vs empty list. A missing array must not implicitly delete prior responses.

### Physical read/write set

- Read: \`inspections\`, \`unit_claims\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, existing \`checklist_responses\`, \`specification_responses\`, \`idempotency_records\`.
- Write: \`inspections\` (row_version and any approved draft aggregate metadata); \`checklist_responses\`; \`specification_responses\`; \`idempotency_records\`; \`audit_events\`.
- \`inspection_revisions\` should not be mutated as a submitted immutable revision. Whether a DRAFT revision row exists and is mutable is unresolved.
- No write to \`inspection_events\` unless the audit/state model explicitly records draft save there; the audit catalogue defines \`inspection.draft_saved\` as a business event but physical mapping must be finalized.
- Physical response tables key rows by \`inspection_revision_id\`; the physical model does not fully specify how a mutable draft revision is represented separately from submitted immutable revisions.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock inspection aggregate row; lock active claim, association and assignment dependencies in global deterministic order; reauthorize under lock.
- Compare \`expected_row_version\` against \`inspections.row_version\`; stale writes return \`STALE_VERSION\`.
- Validate the full patch against the exact pinned instrument version before any child mutation.
- Upsert only the specified response IDs/keys; never delete omitted responses unless explicit deletion semantics are separately defined.
- Increment inspection row_version exactly once for a semantic mutation; define no-op behavior (same canonical payload may return unchanged without increment, but must be specified).
- Append \`inspection.draft_saved\` audit event atomically. Audit metadata contains changed item/field IDs or counts as approved, not answer values or sensitive notes by default.
- Audit failure rolls back inspection version and all response changes.

### Audit and typed outcomes

- Required event: \`inspection.draft_saved\`; event key is in the audit catalogue.
- Outcomes: \`SAVED\`, \`NO_CHANGE\`, \`STALE_VERSION\`, \`CLAIM_INVALID\`, \`CLAIM_EXPIRED\`, \`ASSOCIATION_INACTIVE\`, \`ASSIGNMENT_INVALID\`, \`INSPECTION_NOT_EDITABLE\`, \`INSTRUMENT_VERSION_MISMATCH\`, \`RESPONSE_INVALID\`, \`FIELD_NOT_APPLICABLE\`, \`VALIDATION_FAILED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Valid owner saves checklist and typed specification responses.
- Non-owner, expired claim, inactive association, wrong assignment and cross-project references denied.
- Cross-version checklist/specification IDs rejected.
- Validate each supported answer/value type, decimal precision, bounds and applicability.
- Omitted/null/empty patch semantics tested; no accidental response deletion.
- Concurrent writes with same expected_row_version: one succeeds, the other receives stale version.
- Submitted/approved revision and non-editable state cannot be changed.
- Audit failure rolls back all response writes and row_version increment.
- Direct browser DML denied on response tables.

### Open decisions

1. Define draft revision representation and relationship between \`inspections.current_revision_no\`, \`inspection_revisions\` and response tables.
2. Define patch semantics for omitted/null/empty collections and explicit response deletion.
3. Define whether every save appends an inspection event/audit event or whether audit is sampled/coalesced; T-15 requires critical material changes be auditable.
4. Define no-op save behavior and row_version increment rules.
5. Finalize versioned answer/value schema and note privacy/retention policy.

## CMD-029 — submit-inspection

**Permission:** \`inspection.submit\`  
**Candidate route:** \`POST /api/commands/submit-inspection\`  
**Candidate RPC:** \`public.cmd_submit_inspection_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "inspection_id": "uuid",
    "expected_row_version": 13,
    "submit_reason": null
  }
}
\`\`\`

\`submit_reason\` is optional in the canonical catalogue; the policy for when a reason is required must be approved. Caller cannot supply revision_no, author_id, submitted_at, status, snapshot_hash, payload_snapshot, evidence verification, actor or reviewer.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "submitted",
  "resource_id": "inspection-uuid",
  "resource_version": 14,
  "server_time": "UTC timestamp",
  "result": {
    "revision_id": "revision-uuid",
    "revision_no": 1,
    "snapshot_hash": "sha256-hex",
    "submitted_at": "UTC timestamp",
    "status": "SUBMITTED"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

### Authorization, scope, completeness and immutability

- Caller must be the Inspector/claim owner with \`inspection.submit\` and active assignment authority.
- Claim must be ACTIVE and unexpired at the transaction serialization point; association and assignment must remain valid/effective.
- Inspection must be in the exact submit-eligible state. Returned-for-correction workflows must use an explicitly defined new draft/revision context.
- Validate all required applicable checklist responses, specification responses and evidence slots against the pinned published instrument version.
- Applicability rules must be evaluated server-side using the versioned declarative rule engine; unknown rule types fail closed.
- Every required evidence slot must have a finalized/verified evidence asset, not merely an upload intent or client assertion. Verify object identity/checksum/size/MIME using the approved server-side evidence verification workflow.
- No unresolved sync conflict may exist for the inspection. The command catalogue requires this gate, but current physical schema lists \`sync_batches\` and does not fully define durable operation-level conflict rows or a direct inspection-to-conflict relationship.
- Create an immutable submitted revision snapshot with exact instrument version ID, canonical payload snapshot and hash; later draft edits must not mutate this snapshot.
- Author identity is derived from authenticated claim owner. Do not permit submitter to change author.
- Submission must not auto-approve, assign a reviewer, generate a PDF or alter canonical unit/association history unless a separate command explicitly performs that action.
- Once submitted, submitted revision content and finalized evidence identity are immutable under normal application roles.

### Physical read/write set

- Read: \`inspections\`, \`unit_claims\`, \`unit_project_associations\`, \`operational_assignments\`, \`assignment_members\`, \`instrument_versions\`, \`checklist_sections\`, \`checklist_items\`, \`specification_fields\`, \`evidence_slot_definitions\`, \`checklist_responses\`, \`specification_responses\`, \`evidence_assets\`, \`sync_batches\`, \`idempotency_records\`.
- Write: \`inspections\` (status, current_revision_no, row_version); append \`inspection_revisions\`; append \`inspection_events\`; \`idempotency_records\`; \`audit_events\`.
- No write to response content or evidence object identity as part of submission. If the physical design stores a frozen payload snapshot on \`inspection_revisions\`, snapshot creation must be atomic with status transition.
- Do not mutate published instrument configuration, assignment, association, canonical unit or historical revisions.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock inspection aggregate row, then validate active claim/association/assignment and relevant evidence rows in deterministic order; reauthorize under lock.
- Compare expected_row_version and reject stale submission.
- Validate all required response/evidence/completeness rules and sync-conflict state before any state mutation.
- Build canonical snapshot from server-read persisted responses and verified evidence references; compute hash with a deterministic canonicalization algorithm.
- Allocate next revision number under the inspection row lock; enforce unique \`(inspection_id, revision_no)\`.
- Insert immutable revision, update inspection state/current_revision_no/row_version, append \`inspection.submitted\` and \`inspection_revision.created\`, and write idempotency result in one transaction.
- The audit catalogue requires both submission and revision-created event families; exact event cardinality and whether both are represented in \`audit_events\` vs one domain event table must be finalized.
- Audit failure rolls back revision, state transition and idempotency result.

### Audit and typed outcomes

- Required events: \`inspection.submitted\` and \`inspection_revision.created\`; preserve correlation and immutable revision reference.
- Outcomes: \`SUBMITTED\`, \`INCOMPLETE\`, \`EVIDENCE_NOT_READY\`, \`EVIDENCE_INVALID\`, \`SYNC_CONFLICT\`, \`CLAIM_INVALID\`, \`CLAIM_EXPIRED\`, \`ASSOCIATION_INACTIVE\`, \`ASSIGNMENT_INVALID\`, \`STALE_VERSION\`, \`INSPECTION_NOT_SUBMITTABLE\`, \`SNAPSHOT_FAILED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Complete inspection with all required applicable answers and finalized evidence submits successfully.
- Missing required response, missing evidence, pending upload, invalid checksum/MIME/size or wrong slot blocks submission.
- Cross-version response/evidence reference rejected.
- Claim expiry or association/assignment invalidation at submission boundary blocks.
- Sync batch conflict blocks; clean fully acknowledged batch permits submission.
- Same-key replay returns same revision; different-key repeated submit does not create a second submitted revision.
- Concurrent save-draft vs submit serializes; one deterministic result, no lost response writes.
- Submitted revision snapshot/hash is stable and immutable.
- Audit failure rolls back status, revision, events and idempotency result.

### Open decisions

1. Define durable sync conflict representation and query predicate for the submit gate.
2. Define evidence verification boundary, including object existence, checksum, MIME sniffing, malware scanning and provider outage behavior.
3. Define canonical snapshot serialization/hash algorithm and schema version.
4. Define returned-for-correction resubmission revision lifecycle.
5. Define claim behavior after submission (auto-release, remain active until review, or explicit release); do not infer.
6. Define exact audit event storage/cardinality for submitted + revision-created.

## CMD-030 — return-inspection

**Permission:** \`inspection.review\`  
**Candidate route:** \`POST /api/commands/return-inspection\`  
**Candidate RPC:** \`public.cmd_return_inspection_v1\`

### Request

\`\`\`json
{
  "command_id": "uuid",
  "idempotency_key": "opaque-random-key",
  "schema_version": 1,
  "payload": {
    "inspection_id": "uuid",
    "revision_id": "uuid",
    "reason": "string",
    "expected_revision_no": 1
  }
}
\`\`\`

The caller cannot provide reviewer_id, author_id, decision timestamp, from/to status, assigned reviewer identity or scope. All are derived or validated from trusted records.

### Response

\`\`\`json
{
  "command_id": "uuid",
  "status": "returned_for_correction",
  "resource_id": "inspection-uuid",
  "resource_version": 15,
  "server_time": "UTC timestamp",
  "result": {
    "revision_id": "revision-uuid",
    "revision_no": 1,
    "decision": "RETURN",
    "inspection_status": "RETURNED_FOR_CORRECTION"
  },
  "replayed": false,
  "correlation_id": "uuid"
}
\`\`\`

The exact inspection state enum and whether a return changes the aggregate row_version are required schema/workflow decisions.

### Authorization, scope and SoD

- Caller must be the currently assigned reviewer with \`inspection.review\` for the exact inspection/project/session/assignment scope.
- Verify the submitted revision belongs to the inspection, is the exact current reviewable revision and has not already received a terminal review decision.
- Enforce reviewer != revision author using authenticated actor identity and stored \`inspection_revisions.author_id\`; no client author ID is accepted.
- A user who is both Inspector and Reviewer must still be denied when reviewing their own revision.
- Reviewer assignment source is not concretely identified in the current physical schema. Do not infer reviewer authority from Super Admin, project membership, generic \`assignment_members\` or a role title alone.
- Require a bounded non-empty return reason. The reason should be visible only to authorized workflow participants and retained under the approved privacy/records policy.
- Return does not edit submitted responses, snapshot, evidence, author, or submitted revision. It appends a review decision and changes only the inspection aggregate lifecycle state if the approved workflow requires it.
- Repeated return on the same revision is a state conflict, not a second decision event. Re-review after resubmission must target a new current revision under an approved revision lifecycle.

### Physical read/write set

- Read: \`inspections\`, \`inspection_revisions\`, \`review_events\`, reviewer permission/scope and reviewer assignment source (currently unresolved), \`idempotency_records\`.
- Write: append \`review_events\`; update \`inspections\` state/row_version; append \`inspection_events\`; \`idempotency_records\`; \`audit_events\`.
- No write to \`inspection_revisions\`, \`checklist_responses\`, \`specification_responses\`, \`evidence_assets\`, \`unit_claims\`, \`units\` or association.
- Physical \`review_events\` contains \`inspection_revision_id, reviewer_id, decision, reason, created_at\` and is append-only. \`inspection_events\` is also append-only.
- **Schema gap:** the physical review event table does not define an explicit reviewer-assignment ID, decision sequence, or review round identifier. The inspection state/row_version model must prevent multiple terminal decisions for the same revision unless an approved workflow says otherwise.

### Transaction, lock and idempotency

- Claim idempotency key.
- Lock inspection aggregate row, then target revision and review decision key in deterministic order.
- Re-evaluate reviewer assignment, permission, scope, reviewer != author, revision ownership, current reviewable state and expected_revision_no under lock.
- Ensure no terminal review event already exists for the target revision.
- Append \`review_events\` decision RETURN; update inspection state and row_version atomically; append \`inspection.returned_for_correction\` to \`inspection_events\` and required audit event; insert idempotency result.
- Do not mutate the submitted revision snapshot or response rows.
- Concurrent approve vs return must serialize so exactly one terminal review decision commits.
- Audit failure rolls back review event, state change and idempotency result.

### Audit and typed outcomes

- Required event: \`inspection.returned_for_correction\`; corresponding \`review_events\` and \`inspection_events\` records must be consistent.
- Outcomes: \`RETURNED\`, \`SOD_VIOLATION\`, \`REVIEWER_NOT_ASSIGNED\`, \`REVISION_NOT_CURRENT\`, \`REVISION_NOT_SUBMITTED\`, \`ALREADY_REVIEWED\`, \`INVALID_STATE\`, \`STALE_REVISION\`, \`REASON_REQUIRED\`, \`DENIED\`, \`IDEMPOTENCY_KEY_REUSED\`, \`AUDIT_WRITE_FAILED\`.

### Tests

- Assigned reviewer returns a current submitted revision with a reason.
- Inspector author cannot review own revision even when holding Reviewer permission.
- Unassigned reviewer, wrong project/session scope and unauthorized account denied.
- Revision from another inspection or stale/non-current revision rejected.
- Concurrent approve and return produce exactly one terminal review event.
- Duplicate same-key request replays; distinct-key duplicate decision is rejected.
- Submitted revision, responses and evidence remain unchanged after return.
- New resubmission/review round follows the approved revision lifecycle.
- Audit failure rolls back review event and inspection state change.

### Open decisions

1. Define reviewer assignment entity/source and exact effective scope predicate.
2. Define inspection state machine, reviewable states, return target state and resubmission lifecycle.
3. Define review round/decision uniqueness and whether re-review of a revision is ever allowed.
4. Define review event schema additions if assignment/round linkage is required.
5. Define reviewer note privacy, retention and notification behavior (notifications must not change inspection status).

## 4. Cross-command invariants and dependency map

| Invariant | Commands | Required control |
|---|---|---|
| Instrument lifecycle | CMD-018–021, CMD-014, CMD-026–029 | Manage, publish and deactivate are separate permissions; assignments/inspections remain pinned to immutable published versions |
| Canonical serial identity | CMD-022, CMD-025, CMD-026 | One normalized serial per instrument globally; normalization policy versioned; unique constraint is final arbiter |
| Project association lifecycle | CMD-023–026 | Unit identity is global; project visibility only through durable association episodes; no scope inference from unit ID |
| Conflict resolution | CMD-022, CMD-023, CMD-025 | Collision cannot clone/merge canonical units; designated reviewer, exact candidate match and reasoned audit |
| Active claim exclusivity | CMD-026–027 | One ACTIVE claim per canonical unit globally; unit/claim lock and partial unique index; server-time expiry |
| Draft preservation | CMD-026–029 | Claim release/expiry/takeover must preserve drafts/evidence and must not create duplicate active inspection lifecycle |
| Inspection concurrency | CMD-028–030 | Inspection row_version and aggregate lock serialize save, submit, return and approve (CMD-031) |
| Immutable submission | CMD-029–030 | Submission creates immutable revision snapshot/hash; return appends decision/state, never edits submitted content |
| Reviewer SoD | CMD-030–031 | Reviewer != revision author; reviewer must be explicitly assigned; approve/return race permits one terminal decision |
| Audit atomicity | CMD-021–030 | Exact domain event and protected mutation commit atomically; audit failure aborts mutation |
| Direct DML/ACL | CMD-021–030 | Browser INSERT/UPDATE/DELETE denied; exact function EXECUTE grants and RLS separately verified |

## 5. Consolidated findings and blockers

### F-021-01 — Instrument concurrency token is missing

CMD-021 requires \`expected_version\`, but physical \`instruments\` does not define a row_version/version field. Add an approved token and increment rule or remove expected_version.

### F-021-02 — Deactivation effects on existing assignments are unresolved

The catalog says deactivation must not rewrite pinned history. It does not decide whether existing active assignments continue, are blocked from future work, or must be closed. Define behavior without retroactive mutation.

### F-022-01 — Unit identity attributes are not physicalized

CMD-022 accepts \`identity_attributes?\`, but \`units\` has no corresponding attributes field or related table in the physical schema. Define an allowlisted storage model or remove the field.

### F-022-02 — Unknown serial and duplicate conflict workflow are incomplete

T-16 defines canonical known-serial uniqueness and controlled collision resolution, but the command contract does not fully define unknown serial lifecycle, conflict creation event, or privacy-safe response semantics. The audit catalogue lacks exact conflict-open/resolved/rejected event keys named by the command matrix.

### F-023-01 — Association evidence reference is undefined

CMD-023 includes optional \`evidence_ref?\`, but no physical provenance entity or typed reference contract is specified. Do not accept an arbitrary URL/object key.

### F-024-01 — Association expected_version has no physical column

CMD-024 includes expected_version, but \`unit_project_associations\` has no row_version. Resolve the contract before optimistic concurrency is claimed.

### F-024-02 — Active-work gate and ENDED/REVOKED semantics are incomplete

The physical model preserves historical references but does not define how an active claim, draft inspection, submitted/reviewable inspection or future-effective end is handled. ENDED and REVOKED must have distinct approved meanings.

### F-025-01 — Conflict reviewer SoD and audit events are not finalized

The designated reviewer and independent verification requirement lack an explicit physical reviewer assignment model and exact audit event keys. Add them to the canonical governance sources before implementation.

### F-026-01 — Claim lock order conflicts with global lock hierarchy

The CMD-026 matrix row places assignment after unit/association, while the global hierarchy places project/session/assignment before unit/association. Reconcile and test the full cross-command lock graph before code.

### F-026-02 — Claim expiry, takeover and resume lifecycle are incomplete

TTL, renewal, expiry worker, offline grace, draft ownership and inspection resume semantics are not defined. Preserve drafts/evidence; never infer ownership transfer or create duplicate active inspections.

### F-028-01 — Draft revision model is not explicit

Response rows reference \`inspection_revision_id\`, while the inspection aggregate holds \`current_revision_no\` and submitted revisions are immutable. Define how mutable draft response rows are attached to a draft revision and how submission freezes them.

### F-028-02 — Draft patch deletion/no-op semantics are incomplete

The API must distinguish omitted, null, empty and explicit deletion. Do not delete prior responses merely because an array was omitted. Define row_version increment behavior for semantic no-op saves.

### F-029-01 — Sync conflict gate is not fully physicalized

CMD-029 blocks submission when unresolved sync conflicts exist, but the current physical schema does not define a clear durable per-operation conflict entity or exact query predicate. Define the data model and conflict resolution lifecycle.

### F-029-02 — Evidence verification contract and canonical snapshot algorithm are incomplete

Submission needs trusted evidence finalization, checksum/MIME/size verification, malware-scan policy and deterministic snapshot/hash serialization. Provider outage and retry behavior must be explicit.

### F-030-01 — Reviewer assignment source is missing

CMD-030 requires an assigned reviewer, but no explicit reviewer-assignment entity/source is identified in the current physical schema. Do not infer reviewer authority from broad role/project membership.

### F-030-02 — Review decision uniqueness and resubmission lifecycle are incomplete

Define review round, terminal decision uniqueness, return target state and new revision behavior. Concurrent approve/return must allow one terminal decision only.

## 6. Required PO/security/institutional decisions before contract freeze

1. Define instrument deactivation state matrix, effects on existing assignments and concurrency token.
2. Approve unit identity_attributes storage, unknown-serial workflow and conflict-open audit event.
3. Define project/instrument compatibility and association reactivation/episode policy.
4. Define association evidence provenance and ENDED/REVOKED meanings, expected_version handling and active-work gate.
5. Approve conflict reviewer appointment, reporter/resolver SoD, conflict states and exact audit events.
6. Reconcile CMD-026 lock order with the global lock hierarchy; approve claim TTL, expiry, renewal, takeover, resume and ownership rules.
7. Define inspection draft revision representation, response patch semantics and row_version increment/no-op behavior.
8. Define sync conflict persistence/query model and evidence verification controls.
9. Define canonical submission snapshot/hash format, returned-for-correction revision lifecycle and claim behavior after submission.
10. Define reviewer assignment source, review round, decision uniqueness, inspection state transitions and reviewer note privacy.

## 7. Verification and implementation status

| Area | Status |
|---|---|
| Canonical CMD-021–030 catalogue review | DOCUMENTED |
| Proposed request/response contracts | DOCUMENTED; PO/API review required |
| Permission/scope/SoD review | DOCUMENTED; role grants and reviewer assignment model not approved |
| Physical read/write set | DOCUMENTED against proposed schema only |
| Lock/transaction/idempotency design | DOCUMENTED; lock-order conflict remains open |
| Audit event mapping | DOCUMENTED; conflict event names need reconciliation |
| RLS/privilege posture | DOCUMENTED against proposed catalogues only |
| Live Supabase table/RLS/function owner/EXECUTE verification | NOT PERFORMED |
| Positive/negative/replay/concurrency/audit-failure tests | SPECIFIED ONLY; NOT EXECUTED |
| T-10/T-12 institutional/provider evidence | OPEN |
| CMD-045–048 institutional authority | BLOCKED |
| Notification worker identity and ACL | PENDING APPROVAL |
| G9 | NOT READY |
| G10 | NOT AUTHORIZED |
| Source code / SQL / migration / grants / live DB / deployment / merge | NOT PERFORMED |

No implementation readiness or production readiness is claimed by this review.

## 8. Change control

- This document is a detailed engineering proposal, not a PO/security approval.
- Do not implement candidate routes, RPCs, SQL, indexes, triggers, grants or RLS policies solely from this document.
- Update the canonical command catalogue, permission registry, physical schema, RLS catalogue, audit catalogue and test catalogue together when an issue is resolved.
- Preserve immutable command IDs. Breaking contract changes require a new schema/API version and explicit compatibility plan.
- Re-review CMD-021–030 against CMD-011–020 where shared invariants intersect, especially instrument lifecycle, canonical unit identity, T-16 association model, lock order, claim lifecycle and inspection row_version.

## Draft-context lifecycle proposal cross-check — 2026-11-24

[INSPECTION-DRAFT-001](INSPECTION-DRAFT-CONTEXT-AND-REVISION-LIFECYCLE-PROPOSAL-001.md) v0.1.0 proposes a distinct mutable `inspection_draft_contexts` workspace and preserves `inspection_revisions` as immutable submitted snapshots. The candidate flow is: CMD-026 creates the initial active context; CMD-028 patches only that context under the inspection aggregate row_version; CMD-029 seals the context and atomically creates the immutable revision; CMD-030 creates a new correction context from the returned revision without editing that revision.

The proposal also clarifies that CMD-033/034's unresolved `revision_context` should refer to the active draft context, and that evidence is bound to the exact immutable revision at successful submission. Evidence carry-forward across revisions remains OPEN and must not be inferred.

This is a candidate cross-check only. The physical relation, payload schema, claim/resume semantics, evidence linkage, state vocabulary, lock order and all tests remain unapproved. CMD-026/028/029/030 remain NOT CERTIFIED; no command contract or canonical schema is changed by this addendum.
