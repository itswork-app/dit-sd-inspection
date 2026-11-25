# Institutional and Technical Authority Approval Package — Dit. SD Inspection

**Document ID:** AUTH-001  
**Version:** 0.1.0  
**Status:** REQUEST PACKAGE — NO EXTERNAL APPROVALS RECORDED  
**Date:** 2026-11-24  
**Authority:** MIB-001; DGA-001; Decision Register; RTM-001; RAID-001  
**Purpose:** Route each non-PO decision to the role legally or technically authorized to approve it.

## 1. Use and controls

This package is a structured request for evidence. It does not name or presume any actual institution, official, provider account owner or individual approver. The project owner must route each request through the institution's established delegation and records process.

For every response, retain:
- approving institution/unit and authorized role;
- approver identity and proof of delegated authority (stored in the institution's approved system, not chat);
- decision date, effective date and expiry/review trigger;
- document/version/source reference and signed or otherwise formally authenticated evidence;
- scope, conditions, exclusions and dissent/residual risks;
- affected DGA, RTM, RAID, Decision Register, ADR and specification IDs.

A response is not an approval if it is only a meeting note, informal chat, unverified email, verbal direction or unsigned draft where formal written authority is required.

## 2. Institutional approval requests

### AUTH-01 — Controlled instrument sources and inspection evidence rules

**Requested authority:** Institutional instrument owner / issuing authority; PO for product interpretation.

**Related IDs:** DGA-B01/B02; T-01; IFP-001/002; BRK-001/002; QA-INS-001..006; R-001/R-002; I-001/I-002; D-001.

**Request:**
1. Supply the current controlled IFP instrument/checklist/specification, including document ID, version, issuer, effective date, complete annexes and revision history.
2. Confirm whether the PO-confirmed Standing Bracket source is complete and current; provide any annexes or superseding controlled issue.
3. Approve exact checklist wording, order, grouping, applicability, response options, conditional/N/A rules and model variants.
4. Approve the complete photo/evidence-slot inventory and mark each slot required, conditional or optional, including trigger and rejection behavior.
5. Confirm how conflicting legacy screenshots/transcriptions are treated; preserve them as observations rather than silently merging them into the authoritative master.
6. Identify the authorized owner of future source revisions and change notification.

**Required evidence:** Controlled source files or authenticated references; issuer/owner; signed item-by-item reconciliation; evidence-slot matrix; explicit approval of unresolved ambiguities.

**Gate impact:** G1/G9 remain NOT READY until the applicable source and evidence rules are approved.

### AUTH-02 — BA signatory and attendance authority

**Requested authority:** Institutional document owner / delegated signatory authority / attendance authority; PO for template behavior.

**Related IDs:** DGA-B03; T-02/T-08; DOC-S-001; DOC-003; R-008; I-003.

**Request:**
1. Approve the BA template version and required signatory parties, roles/titles, order, optionality and signing method.
2. Identify which institutional role may authorize each signatory block and who may update the approved template.
3. Approve attendance evidence types, verifier authority, correction/rejection process and separation between upload and verification.
4. Confirm whether any wet-signature, stamp, attendance or archival requirement is mandatory.

**Required evidence:** Approved template; delegated authority matrix; attendance verification procedure; sample output accepted by the institutional owner.

**Boundary:** PO approval of configurable signatory blocks does not establish actual signatory identities or institutional signing authority.

### AUTH-03 — T-10 records, legal, privacy and security policy

**Requested authority:** Authorized institutional records owner, legal function, privacy/data-protection function and information-security function.

**Related IDs:** T-10; DGA-B04/B13; RET-001; INC-001; NOTIF-011; EVD-003; AUD-S-001; D-031; R-011/R-013.

**Request written determinations for:**
1. Record classes and data classification for account, assignment, inspection, photo/video evidence, BA, attendance, notification and audit records.
2. Processing purpose, lawful basis/authority, permitted personal data, data minimization and access population.
3. Evidence format, file/inspection/project limits, sensitive-content restrictions and any required validation.
4. Retention start events, retention periods, archival destination and review triggers for each record class.
5. Legal-hold authority, scope, precedence over disposition, release process and evidence of hold.
6. Deletion/disposition eligibility, approval, execution authority, audit, backup/PITR treatment and object-storage copies.
7. Audit-log retention, access/export approval, integrity controls and disclosure procedure.
8. Local/offline device copies, cache lifetime, encryption/protection, remote purge and device-loss handling.
9. Whether network/device metadata may be collected and the permitted fields, purpose and retention.
10. Incident evidence access, chain-of-custody and cross-system disclosure restrictions.

**Required evidence:** Approved policy or formally issued decision by each delegated function; retention/disposition schedule; data-classification matrix; legal-hold procedure; privacy/security conditions.

**Safety rule:** Until approval, values remain OPEN/NOT SET. Do not invent numeric limits or retention periods, enable irreversible deletion, or treat T-10's PO-approved review path as institutional approval.

### AUTH-04 — T-12 provider ownership, region and operational custody

**Requested authority:** Institutional sponsor/procurement/finance, information security, data-residency authority and designated Operations custodians.

**Related IDs:** T-12; DGA-B05/B06/B08; PROV-001; OPS-003/004/005; D-004/D-006/D-007/D-032; R-006/R-010/R-012.

**Request:**
1. Name the legal owner of each Supabase and Vercel organization/account and identify the billing owner and budget approver.
2. Name primary and secondary custodians/recovery contacts; approve MFA, access grants, offboarding, emergency recovery and credential rotation.
3. Approve the data region/residency arrangement and document any cross-border processing constraints.
4. Confirm actual provider plan, quotas, backup/PITR entitlements, Storage object recovery behavior, support tier and cost/overage controls.
5. Approve project/data ownership, portability, transfer and exit rights, including continuity if a developer or custodian leaves.
6. Assign incident, backup, restore, escalation and provider-contact responsibilities.

**Required evidence:** Signed ownership/RACI; account/organization evidence with secrets redacted; approved region; current plan/quotas/cost sheet; provider capability evidence; recovery contacts; isolated PostgreSQL and Storage restore report with checksums and measured RPO/RTO.

**Boundary:** T-12 option C approves the alternative-ownership path only. It does not name owners, authorize accounts, approve a region or prove recovery.

### AUTH-05 — Security incident authority and break-glass governance

**Requested authority:** Institutional information-security incident owner and legal/privacy/records owners as applicable.

**Related IDs:** DGA-B04/B09/B10; INC-001; CMD-046; D-031/R-032.

**Request:**
1. Decide whether incident case management is inside this application or remains in an external institutional system.
2. Define incident taxonomy, severity, case owner, need-to-know scope, evidence custody and cross-system boundary.
3. Approve emergency/break-glass eligibility, activation, expiry, review, notification and post-incident audit.
4. Define which actions may be taken by the application and which must remain in provider-native or institutional control planes.

**Required evidence:** Approved incident-response policy, authority matrix, case/evidence lifecycle, break-glass procedure and review evidence.

## 3. Technical approval requests

### AUTH-06 — Canonical permission, grantor ceiling and separation of duties

**Requested authority:** Product Owner for business role intent; Security and Database owners for enforceable policy.

**Related IDs:** DGA-B09/B11/B12; RBAC-004; SEC-001..005; D-034/D-036.

**Request:** Review the complete role-to-permission matrix, grantor/delegation ceilings, scope model, SoD pairs, account state, revocation freshness, break-glass and legacy permission-code disposition. For every table, view, function, sequence and Storage object class, approve exact grants, RLS predicates, owner/effective privileges and EXECUTE ACL. Verify PUBLIC/anon denial and caller-JWT propagation. Do not approve wildcard or schema-wide EXECUTE.

**Required evidence:** Signed permission registry; grantor matrix; table/object ACL and RLS review; per-function owner/search_path/signature/EXECUTE review; positive and negative authorization evidence on the exact schema/commit.

### AUTH-07 — Command contracts and lock/concurrency protocol

**Requested authority:** Engineering, Database and Security; PO only for product semantics; Operations/Institution where the resource is externally owned.

**Related IDs:** DGA-B10/B14/B17/B18/B19/B20/B21; CMD-001..054; LPR-01 and LPR-07..LPR-11; D-028/D-030; R-027/R-030.

**Request:**
1. Approve or amend LPR-01 and LPR-07..LPR-11 individually; state explicit approver, rationale and conditions.
2. Complete the per-command manifest for all 54 commands/workers, including exact resource read/write sets, lock modes, deterministic same-rank order, revalidation, transaction boundaries and external side effects.
3. Review physical FK/index/unique/check/trigger/function edges and prove the effective lock graph is acyclic.
4. Resolve CMD-005/007/035/040 concurrency-token target/increment semantics and project/session parent-fence protocol.
5. Review T-13 print-batch durable identity, per-document projection, retries, idempotency and failure/concurrency behavior.
6. Review notification worker lease fencing, recipient snapshot, callback ingress, retry and UNKNOWN reconciliation.

**Required evidence:** Signed technical decision record; exact schema/function/route inventory; complete manifest; graph proof; adversarial concurrency tests on an isolated environment; reproducible build/schema/test SHA. Current state is 10/54 candidate-normalized and 0/54 technically approved/certified; LPR-10 has not been executed.

### AUTH-08 — CI, repository and release control plane

**Requested authority:** Repository administrator, Security and Operations/release owner.

**Related IDs:** DGA-B15; REL-001; CMD-048; D-033/R-033.

**Request:** Verify and approve protected branches/rulesets, required status checks, review/approval requirements, secret/dependency scanning, migration checks, protected environments, deployment approver/operator separation, artifact provenance, immutable release artifacts, rollback and emergency change procedures.

**Required evidence:** Export/screenshot or API evidence of effective rulesets and required checks; successful required-check run on exact commit; protected environment policy; artifact digest/provenance; release RACI and rollback acceptance.

**Current observation:** PR #3's head has no reported status entries and no workflow runs in the inspected query. This is not a successful CI result and does not prove repository ruleset state.

### AUTH-09 — UX, offline, performance and production operations acceptance

**Requested authority:** PO for product acceptance; institutional operational owner, Security, Operations and provider owner for constraints.

**Related IDs:** DGA-B06/B07/B08; OFF-S-001; OPS-002/003/004/005; PERF-001; T-09/T-11/T-12.

**Request:** Approve supported device/OS/browser build matrix; offline/local-data threat model and purge/recovery behavior; measurable latency/error/availability SLOs; workload/media profile; service hours; RPO/RTO; backup cadence; monitoring/alerting; incident response; support coverage; cost envelope.

**Required evidence:** Approved compatibility matrix; threat/privacy review; numeric SLO sheet; measured load report at 10/25/50/75/100 users; isolated DB + Storage restore report; operational runbooks and assigned owners.

## 4. Approval response register

No external or technical approvals are recorded by this request package.

| Request | Authority response | Evidence reference | Approver role / date | Status |
|---|---|---|---|---|
| AUTH-01 | PENDING | — | — | BLOCKED |
| AUTH-02 | PENDING | — | — | BLOCKED |
| AUTH-03 | PENDING | — | — | BLOCKED |
| AUTH-04 | PENDING | — | — | BLOCKED |
| AUTH-05 | PENDING | — | — | BLOCKED |
| AUTH-06 | PENDING | — | — | OPEN |
| AUTH-07 | PENDING | — | — | OPEN |
| AUTH-08 | PENDING | — | — | NOT VERIFIED |
| AUTH-09 | PENDING | — | — | OPEN |

## 5. Routing and evidence handling

1. Route each request only to the actual delegated authority under institutional procedure.
2. Store signed records and sensitive provider evidence in the institution-approved repository; do not paste secrets, tokens, personal data or raw evidence into GitHub or chat.
3. Redact account IDs, credentials, personal data and sensitive provider metadata from any repository reference.
4. Record the evidence URI/reference, version, date, owner and approval scope in the appropriate controlled register.
5. Update DGA/RTM/RAID and dependent specifications only after evidence is authenticated and authority is confirmed.
6. A rejection, conditional approval or deferral must be recorded explicitly with impact and compensating control; do not silently convert it to APPROVED.

---
This package requests authority; it does not create authority. No external approval, technical certification, implementation authorization or release approval is implied.
