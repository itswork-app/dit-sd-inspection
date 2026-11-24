# PRD Scope and Notification Domain Reconciliation — SCOPE-RECON-001

**Document ID:** SCOPE-RECON-001  
**Version:** 0.1.0  
**Status:** REVIEW CANDIDATE — STATIC RECONCILIATION ONLY  
**Date:** 2026-11-24  
**Branch:** docs/notification-resolver-lock-closure  
**Authority:** PRD and approved Decision Register remain authoritative. This document does not amend either.

## 1. Purpose

Prevent notification architecture and event-selector work from drifting away from the approved Dit. SD Inspection product. Reconcile the notification workstream to the actual product: an operational inspection platform whose initial instrument rollout is Interactive Flat Panel (IFP) and Standing Bracket.

This is a scope-control artifact. It is not a new PRD, a product change, a role approval, a notification-policy approval, or implementation authorization.

## 2. Controlling product scope

The controlling source is `docs/01-product-requirements/PRD.md`.

The initial rollout covers:
- IFP inspection;
- Standing Bracket inspection;
- project, session, location, instrument, team, target and assignment planning;
- account approval, roles, permissions and scoped access;
- serial-number capture, canonical unit identity, claim and duplicate-conflict handling;
- configured checklist and evidence capture;
- limited offline draft and safe synchronization;
- immutable inspection submission/revisions, reviewer return and approval;
- approved PDF generation, print/reprint tracking, BA and attendance evidence;
- actual-versus-target reporting, role-specific dashboards, notifications and audit.

The platform is instrument-extensible through Super Admin-managed configuration, subject to supported configuration primitives and separate approval for future project use. The initial rollout must not be expanded to unrelated modules or additional instrument projects by inference.

## 3. Canonical product actors — as stated by PRD

| Actor / role in PRD | Product responsibility | Notification relevance (not an authorization grant) |
|---|---|---|
| Project Sponsor | Institutional sponsorship and production authorization | No operational notification audience is implied |
| Product Owner | Scope, official instrument content, business rules, acceptance and UAT | No operational notification audience is implied |
| Super Admin | Global administration, approved configuration, project/session planning, assignments and cross-project oversight | May be a candidate only for explicitly approved administrative events |
| Admin / Koordinator Lapangan (Korlap) | Operational supervision within assigned location/session | May be a candidate only within explicitly assigned operational scope |
| Inspector | Performs assigned unit inspections and submits evidence | Candidate for own/assigned inspection lifecycle events where the exact event policy selects them |
| Reviewer | Reviews, returns for correction or approves submitted inspections | Candidate for scoped review-queue and review-outcome events where the exact event policy selects them |
| Print Officer | Prints/reprints approved final PDFs and records print actions | Candidate only for explicitly approved document/print workflow events |
| Attendance Verifier | Proposed functional responsibility; authority remains OPEN pending approval | Must remain NOT ENABLED until authority, permission and scope are approved |

The permission registry's role/grant matrix is explicitly marked NOT APPROVED. These role descriptions are product actors, not proof that any role has a permission or is an enabled notification recipient. Explicit assignment, scope, SoD and institutional/security approval remain mandatory.

## 4. Explicitly out of domain unless a change is approved

The PRD does not define a school-administration product. In particular, the notification design must not invent:
- Principal / Kepala Sekolah as a canonical application role or default recipient;
- teachers, students, parents or school-customer portals as application personas;
- school-wide broadcast or global role-only notification audiences;
- notifications for generic school administration, academic activity, payments, sales, inventory or unrelated modules.

A school or institution may be part of the inspection context or data, but that does not make its head, teachers, students or parents application actors or notification recipients. Adding any such persona, permission, workflow or audience requires formal change control under PRD §13 and Product Owner approval.

## 5. Product-aligned notification domain

Notification is a supporting capability for the inspection workflow. It does not own or mutate inspection, account, assignment, project, session, document or attendance state.

Potential event families for controlled review are:

| Domain family | Existing source command range | Product purpose | Recipient rule |
|---|---|---|---|
| Account access and authority | CMD-001–007 | Account request/decision and role/scope changes | Exact applicant/target/actor selection only when specified by an approved event policy; no implicit participant addition |
| Project/session/assignment/capacity | CMD-008–016 | Plan and staff scoped inspection operations | Explicit project/session/location/assignment membership; never global role-only matching |
| Targets and instrument configuration | CMD-017–021 | Configure target plan and IFP/Standing Bracket instrument versions | No notification is enabled merely because a configuration event exists; recipients and business need require explicit policy |
| Canonical unit and claim lifecycle | CMD-022–027 | Serial identity, project association, claim and release | No broadcast; exact assigned operational audience only if separately approved |
| Inspection and evidence lifecycle | CMD-028–035 | Draft, submit, review, correction, evidence and synchronization | Primary operational notification candidate domain; exact Inspector/Reviewer/Korlap recipient mapping must be approved per event |
| Document, print and attendance | CMD-036–040 | PDF/BA/attendance generation, print/reprint, attendance evidence and verification | Exact Print Officer/Korlap/Attendance Verifier mapping requires approved authority and event-specific policy |
| Read-side access, audit and export | CMD-041–044 | Queries, access evidence and export controls | Not part of the 40-command mutation producer set; no notification side effect is inferred from a read |
| Control-plane and notification lifecycle | CMD-045–054 | Administrative/security control plane and notification internals | Excluded from ordinary domain-event matching by default; prevent recursive notification chains |

This table classifies existing command domains for review. It does not enable any event, selector, audience, notification template or delivery channel.

## 6. Mandatory event-to-recipient guardrails

1. Every notification must originate from an exact canonical business event explicitly allowlisted in an approved immutable policy version.
2. A CMD declaration inventory is not an enabled notification registry. Composite, conditional, batch and item-level event declarations must be split into exact event tokens before any policy can enable them.
3. For every enabled event, the registry must identify the authoritative producer/transaction boundary, exact event token, eligible participant fields, allowed role/scope selector, source scope, dispatch profile and dependency references.
4. Candidate recipients must be determined from the PO-approved event-time snapshot semantics. Dispatch-time security/account/channel/consent checks may suppress an original candidate but never widen the audience.
5. A recipient's notification access does not grant access to the underlying inspection, evidence, project, session or document. Opening the resource requires independent authorization.
6. Notifications must not silently change inspection state, approve/return inspections, release claims, verify attendance, close sessions/projects, or create/alter evidence.
7. No recipient may be inferred solely from being a school principal, institution contact, global role holder, event actor or target. The exact approved event selector controls inclusion.
8. A notification failure must not roll back an already accepted inspection workflow transition; source-event/outbox atomicity and asynchronous delivery behavior remain governed by the approved architecture and technical gates.

## 7. PO decision interpretation — do not over-read approvals

- POQ-01 approves immutable event-time candidate audience semantics and dispatch-time suppression without audience widening.
- POQ-02 approves per-policy SLA semantics and ELAPSED_UTC as the initial default.
- POQ-03 excludes dismiss/archive from MVP; only recipient-owned set-once `read_at`.
- POQ-04 approves the five transition outcomes for role revoke, account reject/disable/suspend, assignment-member end, project/session close and self-revoke.

These decisions do **not** approve:
- any new application persona or role;
- any event as notification-enabled;
- a complete event-to-recipient registry;
- a canonical role/scope identifier catalogue;
- the selector grammar or its provisional eight-clause bound;
- a physical snapshot relation/header, SQL, RLS, grants or worker ACL;
- any unapproved attendance-verifier authority;
- technical sign-off, G9 scope freeze or G10 implementation activation.

## 8. Reconciliation findings

| Finding | Disposition |
|---|---|
| Product scope is IFP + Standing Bracket initial rollout | CONFIRMED against PRD |
| Operational actors are the PRD actors listed in §3 | CONFIRMED as product descriptions; grants remain unapproved |
| Kepala Sekolah as application role/default recipient | NOT IN PRD — MUST NOT BE INTRODUCED |
| Inspector, Reviewer and Korlap operational workflows | IN PRD; recipient selectors still require exact event policy |
| Print Officer workflow | IN PRD; notification audience not yet approved |
| Attendance Verifier | PROPOSED / AUTHORITY OPEN — NOT ENABLED |
| All CMD-001–040 events as notification triggers | NOT APPROVED; inventory only |
| CMD-041–044 read-side notification side effects | NOT IMPLIED |
| CMD-045–048 control-plane events | Separate control-plane review required |
| CMD-049–054 recursive notification matching | EXCLUDED BY DEFAULT |
| Exact IFP/Standing Bracket checklist/evidence requirements | Controlled instrument source reconciliation remains open; do not infer requirements from sample transcriptions |

## 9. Required next work before an event registry can be approved

1. Validate each candidate event against the approved PRD workflow and detailed CMD contract.
2. For each candidate event, record whether it is operationally meaningful to Inspector, Reviewer, Korlap, Super Admin, Print Officer or another explicitly approved actor.
3. Separate event-time participant qualification from dispatch-time authorization and resource access.
4. Mark event tokens with unresolved participant mapping, ambiguous cardinality, composite outcomes or unproven transaction boundaries as `UNRESOLVED — NOT ENABLED`.
5. Obtain Product Owner approval for the exact notification event allowlist and audience intent; obtain Security/Engineering/Database review for the executable registry and dispatch profiles.
6. Update RTM, QA and DGA only after the approved event list and traceable acceptance criteria exist.

Do not create a complete enabled registry by mechanically converting all 40 command declarations into notifications.

## 10. Current gate and work boundary

- PRD remains the scope authority; no PRD change is made by this artifact.
- Notification selector grammar and event-specific dispatch profiles remain review candidates.
- F-05 remains OPEN pending technical validation.
- F-04 remains OPEN pending complete selector dependency and physical writer/bypass inventory.
- F-03 and F-07 remain OPEN.
- Resolver certification: 0/40.
- Application lock certification: 0/50.
- Global lock graph: NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header: NOT ADMITTED.
- QA cases remain PLANNED / NOT EXECUTED.
- G9: NOT READY. G10: NOT ACTIVE.

This work is documentation/static reconciliation only. No source code, SQL, migration, grant, RLS, live database change, runtime test, deployment, merge or G10 activation is performed or authorized by this document.

## 11. Sources of truth reviewed

- `docs/01-product-requirements/PRD.md` §§3–7, 10, 13 and Package T decisions.
- `docs/01-product-requirements/IFP-INSTRUMENT-SPECIFICATION.md`.
- `docs/01-product-requirements/STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md`.
- `docs/02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md` §5 (role/grant matrix NOT APPROVED).
- `docs/02-architecture/L05-SOURCE-EVENT-PATH-MAPPING-001.md` §§3–6 (producer inventory, not enabled policy).
- `docs/02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md` §§5–8, 20–22.
- `docs/02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md` §§4.2.4–4.2.6.
- `docs/00-project-charter/DECISION-REGISTER.md` POQ-001 and POQ-04.
- Root `AGENTS.md` v1.2.2.
