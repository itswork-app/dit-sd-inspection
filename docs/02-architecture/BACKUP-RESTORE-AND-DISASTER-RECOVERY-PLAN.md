# Backup, Restore and Disaster Recovery Plan

**Status:** Operational design draft — provider capability and sponsor approval required  
**Version:** 0.1.0  
**Package:** P  
**Date:** 2026-11-23

## 1. Objective and scope

Protect service continuity and recover the complete inspection record after accidental deletion, application defect, credential compromise, provider incident, or regional outage.

Recovery scope includes:
- Supabase PostgreSQL relational data and schema/migration history;
- private Supabase Storage objects (inspection evidence, BA/attendance scans, generated PDFs, derivatives);
- application source, configuration, and deployment history in GitHub;
- Vercel project configuration and production deployment metadata;
- secrets and identity-provider configuration needed to restore service (without storing secret values in this repository);
- operational runbooks, audit evidence, and approved retention/legal holds.

A database backup alone is insufficient: an inspection is not fully recovered unless its referenced evidence and official documents are also available and integrity-verified.

## 2. Recovery objectives — not yet approved

RPO is the maximum acceptable data-loss window. RTO is the maximum acceptable service-restoration time.

| Service/data class | Proposed initial objective | Status |
|---|---|---|
| PostgreSQL operational records | RPO <= 24 hours; RTO <= 8 hours | Proposal only |
| Finalized evidence and official PDFs | RPO <= 24 hours; RTO <= 12 hours | Proposal only |
| Application source and migrations | RPO <= 1 day; RTO <= 4 hours using Git history | Proposal only |
| Authentication/configuration | RPO <= 24 hours; RTO <= 8 hours | Proposal only |
| Full platform service | RTO <= 12 hours | Proposal only |

These values are planning targets, not provider guarantees. The project sponsor and operational owner must approve realistic values after reviewing the chosen Supabase plan, Storage backup/export behavior, Vercel service limits, and institutional requirements. Do not publish these as an SLA.

## 3. Backup layers

### 3.1 PostgreSQL
- Select a Supabase plan and backup/PITR capability that meets the approved RPO/RTO.
- Confirm exactly which schema/data, WAL/PITR window, and restore methods are included in the subscribed plan.
- Keep migration files version-controlled in Git; database backups do not replace migrations.
- Export a periodic logical backup to a separately controlled destination if approved and technically supported.
- Encrypt backups at rest and in transit; restrict restore/export privileges.
- Record backup creation time, database/project identifier, schema version, encryption/key reference, size, and success/failure.
- Do not claim backup completion based only on provider dashboard configuration; capture evidence of successful backup availability.

### 3.2 Supabase Storage objects
- Verify whether the selected provider plan includes object versioning, backup, point-in-time recovery, or only database metadata backup. Do not assume Storage objects are covered by PostgreSQL PITR.
- Maintain a reconciled object inventory with object key, bucket, byte size, checksum, record reference, creation time, and retention/hold state.
- Define an independent encrypted object backup/export process if native provider protection does not meet the approved RPO/RTO.
- Test restoration of object bytes and verify checksum before restoring database references into service.
- Preserve object versions and legal holds according to Package O.
- Never run broad object deletion or lifecycle expiry without hold and retention checks.

### 3.3 GitHub and Vercel
- GitHub repository history is the source for application code, SQL migrations, documentation, and CI configuration.
- Protect main branch and require reviewed PRs and successful required checks.
- Store Vercel project configuration as reproducible settings where possible; keep secret values in approved secret stores only.
- Document domain/DNS ownership, deployment project, environment variables by name (not value), build command, runtime version, and rollback target.
- Ensure GitHub account recovery and at least two authorized maintainers are available under institutional governance; actual named maintainers must be confirmed.

### 3.4 Secrets and identity
- Maintain an inventory of secret names, purpose, owner role, rotation date, and dependent service; never commit secret values.
- Document recovery and rotation of Supabase keys, OAuth credentials, and any signing keys.
- Rotate credentials after suspected compromise; invalidate old credentials and active sessions as appropriate.
- Do not export or back up user passwords or provider access tokens in application backups.

## 4. Backup schedule — proposed pending plan verification

| Layer | Proposed cadence | Retention | Validation |
|---|---|---|---|
| Provider-managed PostgreSQL backup/PITR | As provided by approved plan | Provider-defined; verify contract | Provider evidence + restore drill |
| Logical PostgreSQL export | Daily | 30 days proposed | Automated integrity and isolated restore |
| Storage object inventory/checksum | Daily | 90 days proposed | Compare DB references with object inventory |
| Storage object backup/export | Daily or provider-supported equivalent | 30 days proposed | Restore sample objects and verify SHA-256 |
| GitHub source/migrations | Every reviewed commit | Repository policy | Clone/build from clean environment |
| Vercel deployment metadata | Each production release | Release history | Redeploy approved prior release |
| Secrets inventory (not values) | On every change; quarterly review | Current + prior rotation record | Recovery tabletop exercise |

The logical export and object-copy cadences/retention are proposals and must not be adopted until storage destination, encryption, cost, provider quotas, and institutional retention requirements are approved.

## 5. Backup security

- Backup destination must be separate from the primary project failure domain where practical and approved.
- Encrypt backup artifacts with managed or institutionally approved keys.
- Restrict backup access to named operational roles and use MFA.
- Log backup creation, download, restore, deletion, and key access.
- Separate backup operator from ordinary application administrator where feasible.
- Never place production dumps in public GitHub, local unencrypted devices, or user-shared folders.
- Do not include secrets in logical dumps unless technically unavoidable; if included, protect and rotate them.
- Test key recovery. An encrypted backup with an unavailable key is not recoverable.

## 6. Restore runbook

### 6.1 Declare incident
1. Incident commander or authorized operational owner declares recovery event.
2. Record start time, suspected cause, affected services/data, severity, and decision authority.
3. Freeze risky writes or enter controlled maintenance mode when necessary.
4. Preserve relevant logs and security evidence.
5. Notify institutional stakeholders according to approved incident plan.

### 6.2 Prepare isolated recovery environment
1. Create or designate isolated recovery project/environment.
2. Verify region, access controls, encryption, and secrets handling.
3. Retrieve selected backup and record checksum/source timestamp.
4. Confirm restore point meets approved RPO.
5. Restore PostgreSQL and apply only migrations consistent with the restored schema; do not blindly apply latest migrations to old data.

### 6.3 Restore and reconcile Storage
1. Restore required object bytes from the selected provider backup/export.
2. Recompute SHA-256 and compare with database metadata.
3. Reconcile every required finalized evidence/document reference.
4. Identify missing, orphaned, or mismatched objects.
5. Do not mark the system ready while required official evidence is missing.
6. Respect deletion tombstones and legal holds; do not resurrect records that should remain deleted.

### 6.4 Validate and cut over
- Verify schema/migration version and core table counts.
- Verify authentication and role/scope mappings.
- Run RLS negative and positive smoke tests.
- Verify sample inspections, revisions, claims, evidence, approved PDFs, BA, attendance, and audit references.
- Verify no duplicate active claims or invalid state transitions.
- Run application smoke tests and representative reports.
- Obtain operational owner approval before switching production traffic.
- Record exact cutover time, recovery point, data-loss assessment, and unresolved exceptions.

### 6.5 Post-incident
- Reconcile writes created after the backup point using approved recovery/replay process.
- Notify affected users/stakeholders.
- Conduct root-cause analysis and document corrective actions.
- Rotate compromised credentials and review access.
- Update runbooks and test cases.

## 7. Recovery scenarios

| Scenario | Response |
|---|---|
| Accidental row update/delete | Stop further writes; identify transaction/time; restore to isolated point; compare and recover only approved records where possible |
| Database corruption or migration failure | Isolate; restore pre-incident backup/PITR; validate migration history; forward-fix only after test |
| Storage object loss | Restore object bytes; verify checksum; reconcile references; block affected finalization until recovered |
| Credential compromise | Revoke/rotate credentials; disable compromised accounts; preserve logs; assess data access; restore only if integrity compromised |
| Vercel deployment failure | Roll back to known-good deployment; preserve DB schema compatibility; forward-fix after validation |
| GitHub repository/account issue | Use protected repository recovery and authorized maintainers; restore from approved mirror/export if available |
| Regional/provider outage | Follow provider status and approved alternate-region recovery strategy; do not improvise data residency transfer |
| Ransomware/mass deletion | Freeze credentials and destructive operations; preserve backups outside compromised identity boundary; restore isolated and validate |

## 8. Restore drills and evidence

Before production:
- Perform a full PostgreSQL restore into an isolated project.
- Restore a representative sample of original evidence and official PDFs.
- Verify checksums, object metadata, access policy, and revision links.
- Demonstrate recovery of an approved inspection with its exact instrument version and generated PDF.
- Demonstrate that legal holds and deletion tombstones remain respected.
- Measure actual RPO/RTO and compare with approved objectives.
- Capture operator, timestamps, source backup, restore logs, validation results, defects, and sign-off.

After launch:
- Monthly sample restore drill is proposed.
- Quarterly full recovery exercise is proposed.
- Run a drill after material provider, storage, schema, or backup-policy changes.
- Review backup failures daily and unresolved failures escalate to the operational owner.

Cadence is subject to owner and cost approval; no drill is considered passed without evidence.

## 9. Ownership and escalation

Roles (named individuals remain unassigned until confirmed):
- Project Sponsor: approves recovery objectives, budget, provider plan, and risk acceptance.
- Operational Owner: declares incident and authorizes service cutover.
- CTO/Engineering Lead: runs technical recovery, validation, and post-incident analysis.
- Security/Privacy Owner: handles suspected exposure, credential compromise, holds, and notifications.
- Records Owner: approves restoration/deletion behavior for official records.
- Provider Support: escalated only under the selected support entitlement.

A single person may temporarily hold multiple responsibilities in a small team, but critical actions (e.g., deletion/hold release and production cutover) should receive independent approval where feasible.

## 10. Provider capability verification checklist

Before choosing a production plan, obtain current written evidence for:
- PostgreSQL backup frequency and retention;
- PITR availability and recovery window;
- restore process, expected duration, and whether restore creates a new project;
- Storage object backup/versioning and whether objects are included in database recovery;
- region/data residency and any cross-region copy;
- backup encryption and key-management model;
- quotas, limits, and overage behavior;
- incident support response and plan entitlement;
- export/exit capability and data portability;
- Vercel deployment rollback and environment separation.

Do not infer these capabilities from generic product marketing or assume they are included in a free plan.

## 11. Release gates

Production is blocked until:
1. Sponsor approves RPO/RTO and recovery budget.
2. Selected Supabase plan's backup/PITR and Storage recovery capabilities are verified.
3. Independent object recovery strategy is in place where required.
4. Restore drill succeeds for database plus evidence objects.
5. Runbook, owner roles, notification tree, and cutover authority are approved.
6. Recovery evidence is stored in the project change/release record.

**Backup configuration:** NOT VERIFIED.  
**Restore drill:** NOT EXECUTED.  
**RPO/RTO:** PROPOSED ONLY.  
**Disaster recovery readiness:** NOT ESTABLISHED.  
**Production authorization:** NOT GRANTED.


## T-12 ownership and recovery governance dependency
The Product Owner approved Package T-12 option C on 2026-11-23: an alternative provider-ownership arrangement, subject to formal institutional approval and written definition. No legal owner, account holder, billing owner, custodian or operational contact is named by this decision.

Before production use, the institution must approve the provider ownership and billing arrangement, primary and secondary recovery contacts, access/MFA/offboarding controls, data/project transfer and exit rights, region authority, incident commander, backup operator and restore authorization. Restore drills must use the actually selected plans/accounts and include PostgreSQL plus Storage object restoration with checksum verification. Proposed RPO/RTO, backup cadence and retention remain proposals until approved against provider capabilities and institutional records policy.

**Status:** T-12 option C is PO APPROVED; institutional ownership authorization, provider capability verification and restore evidence remain BLOCKED. No restore drill or production recovery capability is claimed as tested.
