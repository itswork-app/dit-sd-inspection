# CMD-045–048 Detailed Contract Review

**Document ID:** CMD-REVIEW-045-048  
**Version:** 0.1.4  
**Status:** Historical engineering boundary analysis; PO-approved external control-plane disposition; residual external dependencies OPEN  
**Date:** 2026-11-24  
**Scope:** CMD-045 through CMD-048  
**Repository phase:** Documentation / SSOT maturation  
**Controls:** T-10 institutional records/privacy; T-12 provider ownership; T-15 append-only audit; T-18 command boundary; DGA-B04, DGA-B05, DGA-B10, DGA-B12, DGA-B15; G9 NOT READY; G10 NOT ACTIVE.

**Current gate clarification (2026-11-24):** the historical G10 NOT AUTHORIZED wording above predates the Product Owner's conditional implementation authorization. Current state: conditional PO authorization received; G9 NOT READY; G10 NOT ACTIVE. No implementation is permitted until G9 passes and a separate G10 activation record is approved.

**Approved resolution:** [CMD-045–048 Control-Plane Resolution Proposal](CMD-045-048-RESOLUTION-PROPOSAL.md) v0.1.2 records PO acceptance of v0.1.0. The application-scope disposition is approved; external authority/evidence remains open.

## Current disposition after Product Owner approval — 2026-11-24

The Product Owner approved CMD-045–048 Control-Plane Resolution Proposal v0.1.0 on 2026-11-24. This decision supersedes the earlier unresolved application-scope question in this review:
- CMD-045 is deferred to the institutional records/legal/privacy control plane.
- CMD-046 is deferred to the designated institutional incident-response control plane.
- CMD-047 is outside the application command surface; provider-native controls and approved secret management are authoritative.
- CMD-048 is outside the application command surface; protected source-control/deployment systems are authoritative.

The four stable IDs remain for traceability only. They are not executable application commands. Do not create app permissions, routes, RPCs, SQL functions, tables, workers or generic CRUD endpoints for them. The detailed risk analysis below remains useful as control-plane requirements and residual dependency evidence; it must not be read as an implementation backlog for application features.

**Residual status:** T-10 institutional records/privacy policy remains BLOCKED; T-12 provider ownership/recovery evidence remains BLOCKED; incident-response RACI remains OPEN; GitHub/release governance remains OPEN/BLOCKING. G9 remains NOT READY and G10 remains NOT ACTIVE. This approval does not close those external gates.

## 1. Purpose and non-authority

This document records the engineering boundary for four traceability IDs assigned to external institutional/provider/release control planes. It explains why no executable contract can responsibly be specified yet, identifies the minimum evidence and authority required to reopen each command, and defines prohibitions that prevent a draft from being mistaken for authorization.

This is a documentation-only review. It does not approve institutional policy, designate an institutional officer, establish provider ownership, create a security-case or release-record system, approve a route/RPC/function, or authorize implementation.

The canonical catalogue remains authoritative for stable logical IDs and current blocked dispositions:

| ID | Logical responsibility | Application permission | Canonical disposition | Residual external dependency |
|---|---|---|---|---|
| CMD-045 | retention/legal-hold | NONE | DEFERRED_EXTERNAL_CONTROL_PLANE | T-10 institutional policy BLOCKED |
| CMD-046 | security incident response | NONE | DEFERRED_EXTERNAL_CONTROL_PLANE | Incident-response RACI OPEN |
| CMD-047 | provider configuration | NONE | OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL | T-12 provider ownership/recovery BLOCKED |
| CMD-048 | production release | NONE | OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL | Repository/release governance OPEN/BLOCKING |

These four IDs are traceability-only. No application permission label, role grant, function, route, table, worker or application lock set is defined or permitted for them.

## 2. Authority and source reconciliation

The review follows this precedence:

1. Formal institutional records, legal, privacy, security and operational decisions govern matters reserved to those authorities.
2. Explicitly approved PO decisions govern product behavior only within PO authority.
3. MIB-001, AGENTS.md and IRG-001 govern gates, change control and execution boundaries.
4. DGA-001 records the active evidence-backed closure queue.
5. The command catalogue, physical schema, permission registry, RLS catalogue, audit policy and security design are proposals unless individually approved.

### 2.1 Approved direction versus unresolved authority

- **T-10:** PO approval establishes the formal institutional review path only. It does not approve data classification, legal basis/purpose, evidence limits, retention periods, deletion/disposition, legal hold, audit retention/export or network-metadata treatment. Those remain blocked pending written decisions by authorized institutional records/legal/privacy/security functions.
- **T-12:** PO approval selects an alternative provider-ownership arrangement as a direction only. It does not establish the actual legal/account owner, billing owner, custodians, region, provider plan, quotas, budget or recovery entitlements. Those require formal institutional definition and evidence.
- **T-15 / INS-016:** PO-approved direction is append-only audit, atomicity between critical mutation and audit, fail-closed behavior on audit failure, and least-privilege read/export. It does not settle T-10 retention, deletion/disposition, legal hold, classification or network metadata.
- **T-18:** PO-approved execution direction does not waive per-function review, caller identity propagation, least-privilege ownership, exact EXECUTE ACL, search_path, RLS or runtime evidence.
- **G9/G10:** G9 remains NOT READY. G10 remains NOT ACTIVE pending independent G9 verification and a separate G10 activation record. Neither this review nor the CMD-045–048 PO disposition is implementation authorization.

### 2.2 Evidence limitations

The physical database specification is a proposed application schema inventory. It does not establish live database objects, deployed grants, RLS, triggers, functions, Storage policies, external secret-manager resources, GitHub rulesets or Vercel deployment controls. No live environment was queried for this review.

## 3. Shared safety contract

Until the relevant authority and design gates close:

1. Do not expose a browser route, RPC, SQL function, worker job or UI action for any of these commands.
2. Do not seed or grant retention.manage, security.review, provider.manage or release.manage to any role.
3. Do not create placeholder tables, permissive policies, generic admin endpoints or broad SECURITY DEFINER wrappers to make a command appear implementable.
4. Do not infer authority from role names such as Super Admin, Administrator, Security Officer, Provider Owner or Release Manager.
5. Do not accept client-supplied actor, role, approval, scope, provider ownership or deployment status as trusted evidence.
6. Do not place secrets, access tokens, signed URLs, credentials, raw incident evidence or sensitive audit payloads in command requests, logs, audit metadata or repository artifacts.
7. Do not mutate, delete, shorten retention, release a legal hold, alter provider credentials/configuration or deploy/rollback production as a side effect of a documentation decision.
8. Preserve immutable historical evidence and append-only audit direction; any future correction or disposition process must be explicitly authorized and auditable.
9. Any future implementation proposal must map requirement → authority → state transition → physical/external object → command/API → permission/SoD → audit → acceptance test → evidence → gate.
10. All proposed names and examples remain non-authoritative until reviewed against approved documents and actual runtime inventories.

## 4. CMD-045 — retention/legal-hold

### 4.1 Intent and status

CMD-045 is a PO-approved external control-plane deferral, not an application command. The institutional records/legal/privacy operation remains blocked by T-10 because policy, authority and the external lifecycle model are not established.

The operation is not ordinary administrative CRUD. Retention, disposition and legal hold can affect institutional recordkeeping, legal obligations, evidence integrity and data-subject rights. A PO preference or engineering proposal cannot supply the missing institutional authority.

### 4.2 Catalogue input proposal — not an approved API schema

The catalogue currently lists action, record_scope, policy_ref, reason, effective_at and optional approval_ref. This list is a discovery aid only. It is not a request schema and must not be implemented as-is. Arbitrary client-supplied record scopes, policy references, effective timestamps or approval references cannot be trusted. The authorized policy owner must define permitted actions, scope taxonomy, approval evidence, effective-time semantics and whether a request may be prospective, corrective or emergency.

### 4.3 Required institutional decisions

Before detailed physical or command design can proceed, obtain written decisions from authorized institutional records/legal/privacy/security functions covering:

1. Data and record classification, including inspection data, submitted revisions, evidence objects, generated documents, attendance/BA records, audit events, security records and operational metadata.
2. Purpose and lawful/institutional basis for each processing category, including access, sharing, export and retention.
3. Retention schedule per record class, trigger event, clock start, suspension rules, minimum/maximum periods and authoritative schedule/version.
4. Legal-hold authority, eligible initiators, approval chain, scope, start/end conditions, review cadence, release authority and evidence requirements.
5. Disposition authority, method, verification, exception handling, witness/dual-control requirements and proof of completion.
6. Conflict precedence when a legal hold overlaps an expired retention schedule, an active investigation, an audit obligation, a backup lifecycle or a subject request.
7. Treatment of replicas, object versions, backups, exports, caches, offline devices, derived reports and third-party provider copies.
8. Audit retention and the relationship between immutable audit requirements and lawful disposition. No engineer may resolve this conflict by silently deleting audit rows or retaining all personal data indefinitely.
9. Network metadata, access logs, IP/device data and location metadata: permitted use and retention.
10. Required notices, access restrictions, exceptions, appeals and institutional sign-off.

Each decision must identify the approving authority, approval date, controlled policy/document identifier, version, scope, effective date and review/expiry conditions.

### 4.4 Required domain and physical design after authority

Only after policy approval should engineering propose:
- a versioned retention schedule and classification reference model;
- a legal-hold register with immutable hold/release history;
- an explicit record-scope binding model that resolves covered records deterministically;
- disposition requests, approvals, execution evidence and reconciliation states;
- immutable references to policy versions and approval evidence;
- a durable job/outbox or equivalent for external object disposition, with idempotent retry and compensation;
- conflict/precedence rules for holds, retention expiry, legal requests, backup expiry and provider replicas;
- minimal audit evidence that records who authorized what and when without copying unnecessary sensitive content.

These are design topics, not assertions that such tables or jobs currently exist. The physical schema catalogue does not define a complete retention schedule, legal-hold, disposition or disposition-job model. Do not invent final table names or SQL signatures before approved domain modeling and schema reconciliation.

### 4.5 Authorization and separation of duties

The proposed retention.manage label is not an approved grant. The institution must identify:
- who may propose a hold, approve a hold, release a hold and authorize disposition;
- whether the same person may request and approve;
- who may execute a disposition job versus certify its completion;
- how emergency preservation is authorized and retrospectively reviewed;
- how role, project, record class and institutional jurisdiction constrain scope;
- how revocation and account suspension affect pending requests.

No broad administrator bypass is acceptable. Legal-hold precedence must be defined by the approved policy; the software must not invent precedence beyond the authority's written rule.

### 4.6 Transaction and external-effect boundary

A future request/approval record may be transactional within PostgreSQL, but deletion or preservation across Storage, backups and external providers cannot be represented as a single database transaction. The approved design must specify a durable state machine, idempotency, worker identity, retry, partial-failure handling, verification and reconciliation.

No physical disposition may occur before authorization is durably recorded. An uncertain external result must remain visibly unresolved until reconciled; it must not be marked complete merely because a worker attempted the action.

### 4.7 Audit and privacy

The T-15 atomic append-only audit direction applies to any future authorized state-changing command. T-10 must still determine audit classification, retention, access, export, legal hold and network metadata. Audit payloads must be minimized; do not place raw evidence, credentials or full record contents in audit metadata.

A future disposition process must retain the minimum approved proof that the action was authorized and completed, without violating the approved disposition policy. That balance is an institutional decision, not an implementation assumption.

### 4.8 Required tests — planned only

After authority, schema, command and environment approval:
- unauthorized role, missing authority, wrong institution/scope and forged approval reference;
- legal-hold precedence over retention expiry;
- hold/release race and concurrent disposition request;
- duplicate request and same idempotency key with changed payload;
- retention-policy version change while a request is pending;
- partial Storage/provider failure, retry, uncertain outcome and reconciliation;
- backup/replica/offline-copy treatment;
- audit failure prevents protected state transition;
- dual-control and requestor/approver/executor SoD;
- no deletion while an active hold applies;
- proof-of-disposition completeness and immutable history.

All are **PLANNED / NOT EXECUTED**.

### 4.9 Closure evidence

CMD-045 may be reopened only when DGA-B04 is supported by written institutional decisions, policy owners and controlled policy versions are identified, physical lifecycle design is reviewed, permission/SoD is approved, audit and external-effect handling are reconciled, and test acceptance criteria are approved.

## 5. CMD-046 — review-security-incident

### 5.1 Intent and status

CMD-046 is a PO-approved external control-plane deferral, not an application command. The institution-designated incident-response process remains open because accountable security authority, RACI, case system and evidence-handling rules are not established.

The current threat model lists security incidents and monitoring as concerns, but it does not create incident-response authority, an approved case lifecycle, evidence-handling policy, retention schedule or operational service-level agreement.

### 5.2 Catalogue input proposal — not an approved API schema

The catalogue currently lists incident_ref, action, reason and case_scope. These are placeholders, not an implementable schema. The institution/security owner must define incident taxonomy, permitted actions, case identity, evidence references, severity model, access scope, status transitions and approval requirements.

An incident reference supplied by a caller must never by itself confer access to a case. Case scope must be derived from trusted case ownership/assignment and approved security authority.

### 5.3 Required authority and operating model

Obtain written approval for:
- accountable security incident owner and delegated reviewers;
- incident intake, triage, severity classification, escalation and closure authority;
- case assignment and reassignment rules;
- evidence collection, chain of custody, integrity verification and access logging;
- privacy/legal/records escalation for incidents involving personal data or institutional records;
- notification obligations, external reporting and communication authority;
- response targets, on-call coverage and escalation when the owner is unavailable;
- conflict-of-interest handling and independent review for privileged-user incidents;
- preservation/legal-hold handoff and post-incident disposition;
- incident closure criteria, lessons learned and reopening rules.

A generic security.review permission cannot substitute for this operating model.

### 5.4 Required domain and physical design after authority

A complete design must specify:
- security case identity and immutable case history;
- severity, category, source, timestamps and status transitions;
- trusted case ownership/assignment and narrowly scoped reviewer access;
- evidence references and integrity metadata, without copying raw secrets into case records;
- action records, approval references, rationale and immutable audit links;
- escalation, response deadlines, acknowledgement and closure;
- relationships to audit events, affected resources, accounts and legal holds;
- access logging and anti-enumeration behavior;
- retention/disposition under T-10;
- incident reporting and notification pathways, including privacy-safe content.

No security-case table or canonical physical lifecycle is present in the reviewed physical schema inventory. Do not add a placeholder table or invent a case schema until the accountable authority approves the model.

### 5.5 Authorization, SoD and sensitive access

The proposed security.review label is not approved for role assignment. The approved authority must define:
- named security roles and their grantors;
- case-level assignment and jurisdiction;
- whether a reviewer may review their own actions or an incident they caused;
- elevated/break-glass access, time limit, reason, approval and retrospective review;
- access to raw evidence versus metadata and audit;
- suspension/revocation behavior for reviewers;
- independent oversight for privileged-user or administrator incidents.

Security review access must be narrowly scoped, time-bounded where appropriate, and itself auditable. Do not infer global access from a Super Admin role.

### 5.6 Transaction and external-effect boundary

Case state changes, assignment changes and audit records may require atomic persistence once a schema is approved. External notifications, evidence acquisition, account suspension, credential revocation or provider actions are separate side effects and require explicit command boundaries, approvals and reconciliation. Reviewing an incident must not silently suspend an account, change provider configuration, export audit data or deploy a mitigation unless a separately authorized workflow explicitly permits it.

### 5.7 Audit and evidence integrity

Preserve append-only history for case actions and access. Record actor, assigned case scope, action, reason, approval reference, timestamp and integrity references at the minimum approved level. Never log credentials, tokens, raw secrets, full evidence payloads or sensitive content unnecessarily.

### 5.8 Required tests — planned only

After authority and schema approval:
- non-reviewer, unassigned reviewer and out-of-scope case denial;
- case enumeration resistance and resource-ID substitution;
- self-review/conflict-of-interest restrictions;
- break-glass authorization, expiry and retrospective review;
- evidence integrity, access audit and chain-of-custody checks;
- concurrent assignment/reassignment and case closure;
- duplicate action and idempotent retry;
- notification/mitigation side effects require separate authority;
- audit failure and immutable case history;
- legal-hold and retention integration;
- reviewer revocation during an active session.

All are **PLANNED / NOT EXECUTED**.

### 5.9 Closure evidence

CMD-046 may be reopened only after the institutional security owner, incident-response RACI, case lifecycle, evidence-handling and retention rules are approved; physical schema and permission/SoD design are reviewed; and tests and operational evidence are defined.

## 6. CMD-047 — manage-provider-configuration

### 6.1 Intent and status

CMD-047 is PO-approved out of application scope. Provider configuration remains under provider-native controls and approved secret management; T-12 provider ownership is still blocked because legal/account owner, billing owner, custodians, region, plan, quotas, budget and recovery entitlements remain unverified.

The command must not be interpreted as permission to store provider secrets in PostgreSQL or expose a generic configuration editor to application administrators.

### 6.2 Catalogue input proposal — not an approved API schema

The catalogue currently lists provider_key, config_version, secret_reference and change_reason. These are placeholders. No secret value may be supplied in a browser request, persisted in an ordinary application table, returned in an API response or copied into logs/audit metadata.

A future secret_reference must be an opaque, server-resolved reference to an approved secret-manager resource. Its format, namespace, allowed provider, rotation policy and access path must be established by the provider custodian and security owner. A client must never select an arbitrary secret-manager path.

### 6.3 Required ownership and provider evidence

Before design can proceed, obtain:
- signed provider ownership/RACI identifying legal account owner, organization owner, billing owner, technical custodian, security custodian and backup/recovery owner;
- current evidence of account ownership and authorized administrators;
- approved data region and residency requirements;
- provider product/plan, quota and limit evidence;
- billing method, budget envelope, cost alerts and escalation owner;
- backup/PITR and Storage recovery entitlements, retention and restore capability;
- support contacts, incident escalation and account recovery procedure;
- secret-manager ownership, access policy, audit capability and rotation/revocation process;
- environment separation for development, preview, staging and production;
- approved configuration inventory, allowed keys, validation rules and rollback procedure.

These are DGA-B05 closure artifacts. A PO-approved ownership pattern is not evidence that any specific account or custodian has been assigned.

### 6.4 Configuration model and security boundary

Only after ownership approval should engineering classify configuration into:
1. non-secret application settings;
2. secret references resolved only in trusted server/worker contexts;
3. provider-account controls managed directly in the provider console and not mirrored into the application database;
4. deployment/environment variables managed through the approved CI/CD secret mechanism.

For each category, define the authoritative store, source of truth, change approver, validation, versioning, audit evidence, propagation, rollback and emergency rotation.

Do not create a generic key/value configuration table with arbitrary keys or unrestricted secret references. The physical schema currently has no approved provider-configuration table; provider credentials and account settings are not ordinary business data.

### 6.5 Authorization and SoD

The proposed provider.manage label is not approved. The provider owner/security authority must define named custodians and exact permissions for view metadata, propose change, approve change, execute change, rotate secret, revoke credential and verify recovery. Separate requestor, approver and executor where required. Enforce least privilege and environment boundaries.

Super Admin, project administrator or general application administrator status does not confer provider-console or secret-manager authority.

### 6.6 Transaction, versioning and external effects

A future configuration change must use an approved allowlist and versioned change record. The system must distinguish proposed, approved, applied, verified, failed and rolled-back states. Provider API or console changes occur outside a PostgreSQL transaction; durable orchestration, idempotency, uncertain outcomes and reconciliation must be specified.

A configuration version must not be marked applied until authoritative provider state is verified. Secret rotation must avoid exposing old/new secret values in application state, logs, diffs or audit. Rollback semantics must account for credential revocation and provider-side irreversibility.

### 6.7 Audit and secret hygiene

Audit only safe metadata: provider identifier, environment, configuration key/category, version, actor, approver, reason, timestamp, outcome and non-sensitive change reference. Never record secret values, tokens, connection strings, private keys or full environment variable payloads.

### 6.8 Required tests — planned only

After T-12 closure and security approval:
- unauthorized custodian, wrong environment and unapproved provider;
- arbitrary secret-reference/path injection;
- secret values absent from responses, logs, audit and repository artifacts;
- change approval and requestor/approver/executor SoD;
- version conflict and concurrent configuration update;
- provider timeout/uncertain outcome and state reconciliation;
- secret rotation, revocation, expiry and emergency recovery;
- rollback after partial provider-side application;
- quota/billing alert routing and owner escalation;
- audit failure and safe failure behavior;
- environment isolation and least-privilege secret access.

All are **PLANNED / NOT EXECUTED**.

### 6.9 Closure evidence

CMD-047 may be reopened only when DGA-B05 has signed ownership/RACI and provider evidence, the approved secret-management mechanism and custodians are established, the configuration inventory and change workflow are approved, and permission/SoD, audit, recovery and tests are reviewed.

## 7. CMD-048 — manage-production-release

### 7.1 Intent and status

CMD-048 is PO-approved out of application scope. Production release and rollback remain under protected source-control/deployment systems; named release ownership, approval, separation of duties, deployment evidence and operational acceptance remain open.

Production deployment is not an ordinary application-domain database command. A PostgreSQL function or generic application endpoint must not become an alternate control plane for GitHub or Vercel deployment.

### 7.2 Catalogue input proposal — not an approved API schema

The catalogue currently lists release_ref, artifact_digest, environment, action (DEPLOY or ROLLBACK) and approval_ref. These are discovery fields only. They do not define an approved deployment API.

A future release process must bind immutable source commit, build artifact digest, migration head, environment, approval record, test evidence and deployment outcome. A caller-supplied artifact digest or approval reference is not proof that the artifact was built, reviewed or approved.

### 7.3 Required release authority and operating model

Before release control is designed, approve:
- release owner and named authorized operators;
- approval authority for staging and production;
- required independent review and requestor/approver/executor separation;
- protected branch, review, status-check and artifact provenance policy;
- CI workflow ownership, permissions and deployment credentials;
- environment promotion and production data isolation;
- migration approval, ordering, compatibility and rollback/forward-fix policy;
- pre-deployment backup/recovery decision where required;
- deployment windows, freeze periods and emergency release criteria;
- rollback authority, decision criteria, schema compatibility and recovery procedure;
- post-deployment smoke checks, monitoring, incident escalation and release acceptance;
- immutable release evidence and retention policy under T-10.

### 7.4 Required architecture boundary

The release control plane should remain in the approved source-control and deployment systems unless an explicit architecture decision establishes a justified integration. GitHub and Vercel remain the named platform baseline; their actual rulesets, required checks, environments, deployment permissions and audit logs must be inspected before any claim of control effectiveness.

If an application-facing release register is required, define it as an evidence index, not a mechanism that can deploy production. It must not store deployment credentials or permit a normal user session to invoke production deployment.

No release-record schema is present in the reviewed physical application schema inventory. Do not create a release.manage RPC or browser route as a proxy for provider deployment privileges.

### 7.5 Authorization and SoD

The proposed release.manage label is not approved. Define distinct authority for:
- preparing a release candidate;
- approving source and artifact;
- authorizing production promotion;
- executing deployment;
- authorizing and executing rollback;
- verifying post-deployment health;
- accepting the release.

Where organizational policy requires, requestor, approver and executor must be different people. Emergency release must have a defined time-bounded exception, reason, approval/notification and retrospective review. No role name alone confers these privileges.

### 7.6 Release evidence and version governance

A release record, if approved, must reference:
- immutable Git commit SHA and reviewed PR;
- immutable build artifact digest and provenance;
- application SemVer and changelog entry;
- immutable ordered migration identifiers and resulting schema head;
- exact environment and deployment identity;
- required CI/security/test evidence tied to the exact commit/artifact;
- approval identity, authority, reason and timestamp;
- deployment/rollback event and result;
- post-deployment verification, monitoring and acceptance;
- rollback/forward-fix reference where applicable.

Application SemVer follows AGENTS.md and IRG-001. Do not invent or tag a version before a release artifact exists. Documentation version, API contract version, migration identifiers and application SemVer remain separate version domains.

### 7.7 Transaction, rollback and data safety

Deployment and database migration are not one atomic transaction. A rollback of application code may be unsafe after an incompatible migration or data transformation. The release plan must explicitly use compatible expand/migrate/verify/contract sequencing where needed and define whether rollback, roll-forward or restore is the valid recovery path.

A deployment timeout or uncertain provider result must be reconciled against authoritative deployment state before retry. Duplicate deploy requests must not cause uncontrolled parallel production changes. No deployment or rollback action is authorized by this document.

### 7.8 Required tests and evidence — planned only

Before CMD-048 can be considered design-ready:
- unauthorized operator and missing/expired approval;
- wrong environment, untrusted commit or artifact digest mismatch;
- required review/check failure prevents promotion;
- requestor/approver/executor SoD;
- duplicate deployment request and uncertain provider result;
- incompatible migration and rollback/forward-fix decision;
- failed health check and rollback authorization;
- deployment credential isolation and secret scanning;
- immutable release evidence and audit completeness;
- emergency release, retrospective approval and incident linkage;
- exact commit/artifact/schema-head traceability.

Actual production release tests and operational drills require authorized processes and are **NOT EXECUTED**.

### 7.9 Closure evidence

CMD-048 may be reopened only when named release authority and SoD are approved, GitHub/Vercel governance and deployment ownership are evidenced, the release evidence model is approved, migration/rollback and operational procedures are reviewed, and required checks are defined. Actual settings and runtime evidence must be independently verified before G10/G12 claims.

## 8. Cross-command dependencies and decisions

| Finding | Commands | Gap | Required closure |
|---|---|---|---|
| C45-01 | 045 | T-10 policy path approved but substantive records/privacy policy absent | Written classification, purpose/legal basis, retention, disposition and legal-hold decisions |
| C45-02 | 045 | No physical retention/legal-hold/disposition lifecycle in schema inventory | Approved lifecycle, object/backup scope, immutable history and external-effect model |
| C45-03 | 045, 043–044 | Audit retention/export and legal hold can conflict | Institutional precedence and audit retention/disposition policy |
| C46-01 | 046 | Security incident authority and RACI absent | Named security owner, reviewer authority, incident process and SoD |
| C46-02 | 046 | No approved security-case schema/evidence lifecycle | Approved case model, access scope, chain of custody and retention |
| C46-03 | 046, 043–045 | Incident review may need audit access, preservation or legal hold | Separate least-privilege commands and approved handoff; no implicit cross-command authority |
| C47-01 | 047 | T-12 direction does not identify actual owner/custodians | Signed provider ownership/RACI and account evidence |
| C47-02 | 047 | Provider plan, region, quotas, budget and recovery entitlements unverified | Current provider evidence and approved operational/cost envelope |
| C47-03 | 047 | Secret-manager and configuration change model unapproved | Approved external secret store, key allowlist, custodian and rotation/rollback process |
| C48-01 | 048 | Release operator, approver and deployment owner not named | Approved release RACI and SoD |
| C48-02 | 048 | Actual GitHub/Vercel rulesets, required checks and environment protections unverified | Read-only platform evidence and approved governance |
| C48-03 | 048 | Release evidence and migration rollback model incomplete | Approved release register/evidence contract and recovery procedure |
| C45-48-01 | 045–048 | Proposed permission codes not approved in canonical registry | Complete role/grantor/scope/SoD approval before any permission grant |
| C45-48-02 | 045–048 | No approved routes, RPCs, functions, workers or exact ACLs | Do not create; later per-operation API/database/security review |
| C45-48-03 | 045–048 | No executable acceptance evidence | Approve test cases and execute only after G10 and authorized environments |

## 9. Cross-document reconciliation required

Before any of these commands is considered implementation-ready:

1. Update DGA-001 only when the accountable document owner accepts each finding and evidence; do not mark DGA-B04 or DGA-B05 closed from PO direction alone.
2. Reconcile T-10 institutional policy with T-15 audit policy and CMD-043/CMD-044 read/export boundaries.
3. Reconcile CMD-045 retention/legal-hold with evidence lifecycle, private Storage, backups, offline cache/purge, generated documents and provider replicas.
4. Reconcile CMD-046 incident case access with threat model, account/credential response, audit read, legal hold and notification policy.
5. Reconcile CMD-047 with provider RACI, environment architecture, secret-management ADR, cost envelope, backup/recovery and incident response.
6. Reconcile CMD-048 with IRG-001, AGENTS.md, GitHub rulesets, Vercel environments, migration governance, SemVer, CHANGELOG, CI and release acceptance.
7. Reconcile proposed permission labels with the canonical permission registry, role matrix, grantor ceiling, scope, SoD and revocation freshness.
8. Reconcile future routes/RPCs/functions against actual schema and deployed inventory; candidate names must remain provisional.
9. Update RTM, RAID, security test catalogue and operational runbooks after approved decisions, not before.
10. Preserve G9 NOT READY and G10 NOT ACTIVE until their independent exit criteria and explicit activation record are evidenced.

## 10. Consolidated verification plan

All tests below are specifications, not executed evidence.

| Dimension | Minimum coverage |
|---|---|
| Authority | Missing, expired, wrong-scope or forged institutional/provider/release approval |
| Authorization | Wrong role, inactive account, unassigned case/provider/environment, revoked authority |
| SoD | Requestor/approver/executor separation; self-approval and conflict-of-interest cases |
| Scope | Cross-institution, cross-project, cross-record-class, cross-environment access |
| Idempotency | Same key/same payload; same key/different payload; uncertain external outcome |
| Concurrency | Hold vs disposition; case reassignment vs action; provider config update race; concurrent production promotion |
| Audit | Atomic append-only audit; failure prevents protected state transition; no secret/evidence leakage |
| External effects | Storage/provider/secret manager/GitHub/Vercel timeout, partial completion and reconciliation |
| Recovery | Retry, compensation, rollback/forward-fix, legal-hold preservation and evidence integrity |
| Privacy | Minimum necessary data, access logging, retention/disposition, no unauthorized export |
| Supply chain | Immutable commit/artifact provenance, required checks, secret scanning and deployment credential isolation |

No tests were run for this document. No live database, Supabase, Storage, GitHub ruleset, Vercel environment or production system was queried as part of this contract review.

## 11. Gate disposition

| Item | Status | Evidence boundary |
|---|---|---|
| CMD-045 application boundary | PO-APPROVED — DEFERRED_EXTERNAL_CONTROL_PLANE | Stable traceability ID; no app command/permission/physical object; T-10 remains BLOCKED |
| CMD-046 application boundary | PO-APPROVED — DEFERRED_EXTERNAL_CONTROL_PLANE | Stable traceability ID; incident-response RACI remains OPEN |
| CMD-047 application boundary | PO-APPROVED — OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL | Stable traceability ID; T-12 remains BLOCKED |
| CMD-048 application boundary | PO-APPROVED — OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL | Stable traceability ID; repository/release governance remains OPEN/BLOCKING |
| Request/response schemas | NOT APPROVED | Catalogue fields are placeholders only |
| Physical schema / routes / RPCs | NOT DEFINED OR VERIFIED | No new objects or candidate signatures asserted |
| Permission grants / SoD | NOT APPROVED | Proposed labels only |
| Provider and release runtime controls | NOT VERIFIED | No live provider/platform inspection |
| Tests | PLANNED / NOT EXECUTED | No test execution |
| G9 | NOT READY | Institutional and operational blockers remain |
| G10 | NOT ACTIVE | Separate activation record required after independent G9 verification |
| Source code / SQL / migrations / grants / RLS | NOT PERFORMED | Outside authorized scope |
| Live database / Storage / deployment / CI / merge | NOT PERFORMED | Outside authorized scope |

## 12. Next work

1. Review CMD-049–054 separately against NLA-001, INS-015 and notification worker identity/ACL blockers.
2. Complete a command-level crosswalk for CMD-001–054 against physical schema, permission registry, RLS catalogue, audit catalogue, API/route design, RTM, QA and DGA.
3. Keep CMD-045–048 non-executable in the application; their external control-plane dependencies remain blocked/open until the exact authority and evidence listed above are supplied and approved.
4. Reassess G9 only after the DGA closure queue has objective evidence; G10 remains a separate explicit authorization.

**Final boundary:** This review changes documentation only. No source code, SQL, migration, grant/revoke, RLS, Storage policy, live database, provider configuration, production release, deployment, CI execution or merge was performed.
