# CMD-045–048 — Control-Plane Resolution Proposal

**Document ID:** CMD-RESOLUTION-045-048  
**Version:** 0.1.0  
**Date:** 2026-11-24  
**Status:** Engineering recommendation — Product Owner disposition required; NOT approved for implementation  
**Related:** CMD-REVIEW-045-048 v0.1.0; T-10; T-12; T-15; T-18; DGA-B04/B05/B10/B12/B15; D-031..D-033; R-032/R-033.

## 1. Executive recommendation

The four logical IDs currently grouped as blocked commands do not belong to one application command surface. They are governance/control-plane capabilities with different accountable owners and external systems.

**Recommendation:** retain CMD-045..048 as stable traceability IDs, but do not implement them as browser-callable application CRUD/RPC endpoints in the DIT SD Inspection product. Treat them as external institutional/provider/release control-plane responsibilities. The application may later expose narrowly scoped, read-only evidence references or integration status only if a separately approved requirement justifies it.

This recommendation is a scope/design proposal. It is not a Product Owner decision, institutional approval, provider authorization, release authority, or permission grant. The four IDs remain BLOCKED until the Product Owner accepts the disposition and the external dependencies below are evidenced.

## 2. Proposed disposition by command

| Command | Proposed application disposition | Authoritative control plane | What the application may do later | What it must never do |
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

## 5. Proposed command catalogue semantics after PO acceptance

If the Product Owner accepts this proposal, preserve CMD-045..048 as stable historical/traceability IDs but change their canonical status to:
- CMD-045: `DEFERRED_EXTERNAL_CONTROL_PLANE` — institutional T-10 policy remains a production blocker.
- CMD-046: `DEFERRED_EXTERNAL_CONTROL_PLANE` — incident-response process/RACI remains an operational dependency.
- CMD-047: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_PROVIDER_CONTROL` — T-12 evidence remains a production operations blocker.
- CMD-048: `OUT_OF_APPLICATION_SCOPE_EXTERNAL_RELEASE_CONTROL` — CI/repository/deployment governance remains a release blocker.

They must not be counted as executable application commands or seeded permissions. Any future application integration requires a new, narrowly scoped requirement/command ID, explicit data contract, threat model, owner, approval, audit and test plan. Do not recycle the four IDs into unrelated features.

## 6. Gate impact

Accepting this proposal can close the **application-surface design ambiguity** for CMD-046, CMD-047 and CMD-048, and define the non-destructive application boundary for CMD-045. It does not close:
- DGA-B04/T-10 institutional records/privacy policy;
- DGA-B05/T-12 provider ownership and recovery evidence;
- DGA-B15 repository/release governance;
- DGA-B09/B10/B12 permission and command-security review;
- G8 operational readiness or G9 scope freeze.

No G9 or G10 PASS may be inferred from this proposal alone.

## 7. Required Product Owner disposition

The Product Owner must explicitly accept, reject or amend the proposed scope treatment in Section 2 and the canonical status semantics in Section 5. If accepted, the document owner must update the command catalogue, cross-command reconciliation, RTM, RAID, DGA and QA catalogue consistently. Accountable institutional, Security, Database, Operations and repository/provider owners must then supply their own evidence for the residual gates.

## 8. Acceptance criteria for this proposal

- [ ] Product Owner decision recorded with date and exact option.
- [ ] CMD-045..048 catalogue rows retain stable IDs and show the accepted non-executable disposition.
- [ ] No role permission is seeded for the four proposed labels.
- [ ] No route, RPC, function, table, worker or generic admin endpoint is created for these commands.
- [ ] RTM/RAID/DGA/QA traceability is updated without closing external dependencies prematurely.
- [ ] T-10, T-12, incident response and release governance evidence is tracked to the correct accountable owner.
- [ ] G9 remains NOT READY until every applicable upstream gate has objective evidence.

**Final status:** recommendation prepared; Product Owner disposition and external evidence pending. No implementation is authorized by this proposal.
