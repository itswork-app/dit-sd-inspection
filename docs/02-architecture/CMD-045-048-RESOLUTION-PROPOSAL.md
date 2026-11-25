# CMD-045–048 — Control-Plane Resolution Proposal

**Document ID:** CMD-RESOLUTION-045-048  
**Version:** 0.1.2  
**Date:** 2026-11-24  
**Status:** PO APPROVED application-scope disposition (approval of v0.1.0 recorded 2026-11-24); external evidence gates remain OPEN; no implementation authorization  
**Related:** CMD-REVIEW-045-048 v0.1.0; T-10; T-12; T-15; T-18; DGA-B04/B05/B10/B12/B15; D-031..D-033; R-032/R-033.

## Approval record

The Product Owner approved version 0.1.0 of this proposal on 2026-11-24. Version 0.1.2 reconciles the document with that disposition and preserves the accepted scope unchanged. Approval applies only to the application-surface treatment and traceability status of CMD-045–048. It does not approve institutional T-10 policy, T-12 provider ownership, incident-response authority, release governance, implementation, tests, deployment or production operation. G9 remains NOT READY; G10 remains NOT ACTIVE.

## 1. Approved application-scope disposition

The Product Owner explicitly approved this proposal's v0.1.0 application-scope treatment on 2026-11-24. Version 0.1.2 records the corrected approval state. CMD-045–048 remain stable traceability IDs but are not executable application commands, do not receive application permissions, and must not be implemented as browser-callable CRUD/RPC endpoints, SQL functions, tables, workers or generic administrative interfaces.

The approval closes the product-scope ambiguity only. Institutional records/privacy authority, incident-response ownership, provider custody/recovery, and release governance remain external dependencies with their own accountable authorities and evidence. The application may expose a narrowly scoped read-only evidence reference only under a new requirement/command ID and separate approval.

## 2. Approved disposition by command

| Command | Approved application disposition | Authoritative control plane | What the application may do later | What it must never do |
|---|---|---|---|---|
| CMD-045 retention/legal-hold | DEFER application mutation; no generic retention/legal-hold RPC | Institution-approved records/legal/privacy process and approved records/storage lifecycle controls | Preserve policy/version references and a minimal hold/disposition status reference if an approved integration contract requires it | Invent retention periods, initiate deletion, release a hold, shorten retention, or treat a client approval reference as authority |
| CMD-046 security incident | DEFER case management; no security-case CRUD or generic incident reviewer endpoint | Institution's designated incident-response system/process | Record a minimal incident reference and a separately approved operational linkage, if required | Create security authority, expose incident evidence, grant break-glass access, suspend accounts or revoke credentials implicitly |
| CMD-047 provider configuration | REMOVE from product command surface; no provider configuration CRUD/RPC | Provider-native consoles and institution-approved secret manager / operations control plane | Expose only non-secret health/configuration metadata needed by operations, after explicit approval | Store or return secret values, accept arbitrary secret references, mutate provider account/billing/region/credentials from a normal user session |
| CMD-048 production release | REMOVE from product command surface; no application deployment/rollback RPC | GitHub protected repository/workflows and Vercel protected environments (or an explicitly approved deployment platform) | Maintain a release evidence index tied to immutable commit/artifact/schema identifiers, if required | Deploy or rollback production through a generic app endpoint, bypass branch protections, accept caller-supplied artifact digest/approval as proof |

## 3. Why this reduces risk and closes the application architecture ambiguity

1. Retention/legal-hold authority is institutional records governance, not a product administrator privilege.
2. Incident response requires a staffed and accountable response operation, case-level need-to-know access and chain of custody. A generic application command would create an unapproved security subsystem.
3. Provider configuration and secret rotation belong in provider-native and approved secret-management control planes. Mirroring credentials or broad configuration into application tables increases attack surface and creates split-brain configuration.
4. Production deployment and rollback belong in protected source-control/deployment control planes. An application RPC would create an alternate path around repository rulesets, required CI and protected environments.

The recommended boundary is consistent with least privilege, T-18 caller-JWT execution, no browser-held service-role credentials and the existing physical schema's deliberate absence of retention, incident-case, provider-configuration and release-control tables.

## 4. Residual requirements that this proposal does not waive

### 4.1 CMD-045 / T-10 — still a production data gate

Even if the product does not expose a retention command, production evidence collection and lifecycle cannot proceed without the institution's written decisions on:
- classification and purpose/legal basis;
- record-class retention triggers and periods;
- legal-hold authority, precedence, release and review;
- deletion/disposition authority and proof;
- backup, replica, export, offline-cache and provider-copy treatment;
- audit retention/access/export and network metadata.

Until then, values remain OPEN/NOT SET. Do not enable destructive disposition or claim that indefinite retention is a compliant workaround.

### 4.2 CMD-046 — incident response readiness

The institution must identify the accountable incident owner, escalation contacts, external incident system/process, privacy/legal handoff, evidence preservation and break-glass procedure. This can be an operational dependency rather than an application feature.

### 4.3 CMD-047 / T-12 — provider operations readiness

The actual legal/account owner, billing owner, primary/secondary custodians, region, plan, quotas, budget, support, backup/PITR and Storage recovery entitlements, secret-manager ownership, rotation and exit rights must be documented. This remains a G8/G9 dependency regardless of whether the product has a provider-management command.

### 4.4 CMD-048 — release governance readiness

Repository administrator and Operations must evidence protected branches/rulesets, required checks, workflow permissions, secret scanning, protected environments, deployment approvals, artifact provenance, migration compatibility, rollback/forward-fix and operator/approver separation. This is a release-control-plane requirement, not an app feature.

## 5. Canonical command catalogue semantics — PO APPROVED

The following canonical dispositions are approved and must remain synchronized across the command catalogue, crosswalk, permission registry, RTM, RAID, DGA and QA:
- CMD-045: `DEFERRED_EXTERNAL_CONTROL_PLANE` — institutional T-10 policy remains a production blocker.
- CMD-046: `DEFERRED_EXTERNAL_CONTROL_PLANE` — incident-response process/RACI remains an operational dependency.
- CMD-047: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL` — T-12 evidence remains a production operations blocker.
- CMD-048: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL` — CI/repository/deployment governance remains a release blocker.

They must not be counted as executable application commands or seeded permissions. Any future application integration requires a new, narrowly scoped requirement/command ID, explicit data contract, threat model, owner, approval, audit and test plan. Do not recycle the four IDs into unrelated features.

## 6. Gate impact

The PO approval closes the **application-surface design ambiguity** for CMD-045–048 and establishes their non-executable application boundary. It does not close:
- DGA-B04/T-10 institutional records/privacy policy;
- DGA-B05/T-12 provider ownership and recovery evidence;
- DGA-B15 repository/release governance;
- DGA-B09/B10/B12 permission and command-security review;
- G8 operational readiness or G9 scope freeze.

No G9 or G10 PASS may be inferred from this proposal alone.

## 7. Approval boundary and remaining accountable owners

The Product Owner decision is recorded in the canonical Decision Register dated 2026-11-24. No repeat PO approval is required for the accepted application-scope treatment. The remaining work is evidence collection and review by the accountable institutional records/legal/privacy/security authority (T-10), incident-response owner, provider/account custodians and Operations (T-12), and repository administrator/release authority (DGA-B15). These authorities must supply their own evidence; PO approval cannot substitute for it.

## 8. Traceability and verification status

- [x] Product Owner decision recorded in Decision Register on 2026-11-24.
- [x] CMD-045–048 retain stable IDs and have canonical non-executable dispositions in the command catalogue.
- [x] Application permission column is NONE for all four IDs; no role grants are approved.
- [x] Physical crosswalk excludes all four IDs from application read/write sets and lock manifests.
- [ ] Independent inspection of live database grants, routes, workers, provider controls and GitHub/Vercel release settings remains outstanding; documentation alone cannot prove absence in deployed systems.
- [ ] T-10, T-12, incident-response RACI and release-governance evidence must be supplied by their accountable owners.
- [ ] RTM/RAID/DGA/QA cross-document evidence mapping requires final independent review.

**Final status:** PO-approved application-scope disposition recorded; external authority/evidence remains OPEN. No implementation or external control-plane action is authorized by this document.
