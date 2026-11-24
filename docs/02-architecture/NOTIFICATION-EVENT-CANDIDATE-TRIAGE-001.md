# Notification Event Candidate Triage — Product Workflow Audit

**Document ID:** NLA-EVENT-TRIAGE-001  
**Version:** 0.1.2  
**Status:** STATIC TRIAGE — 11 FIRST-BATCH CANDIDATES PO-APPROVED FOR SPECIFICATION/REVIEW ONLY; NO EVENT ENABLED  
**Date:** 2026-11-24  
**Branch:** `docs/notification-resolver-lock-closure`  
**Authority:** PRD-001, approved Decision Register, CMD contracts and controlled instrument sources. This document does not supersede them.

## 1. Purpose and scope boundary

Audit the CMD-001–040 source-event declarations against the actual Dit. SD Inspection product workflows before creating an executable event-to-selector registry.

This is an event inventory and product-relevance triage only. It does not:
- enable any notification event, recipient, channel, template or selector;
- infer canonical event names where the source map is composite or ambiguous;
- create role grants, participant fields, schema columns or dispatch predicates;
- turn every source mutation into a user notification;
- change the IFP or Standing Bracket inspection checklist;
- authorize code, SQL, migration, RLS, deployment, tests or G10.

The CMD source map is a producer/transaction inventory. It is not proof that each declaration is a stable canonical event contract or notification trigger.

## 2. Product workflow baseline

The PRD's initial instrument rollout is IFP and Standing Bracket. The common user journeys relevant to notification are:
1. Account request and Super Admin approval/rejection.
2. Project/session planning and assignment of Korlap, Inspector, Reviewer and Print Officer.
3. Inspector claims a unit, performs the configured inspection, records checklist/evidence and submits.
4. Reviewer returns for correction or approves the submitted immutable revision.
5. Approved inspection becomes eligible for final PDF; authorized Print Officer prints/reprints.
6. Attendance evidence and verification are handled under still-open authority/document decisions.
7. Session/project closure occurs only after the PRD's explicit closure conditions are satisfied.

Instrument-specific details do not create notification events. IFP evidence-slot mandatory status remains OPEN; its instrument specification is draft and its controlled-source authority/version is not confirmed. Standing Bracket's 19-row 23-November instrument source is PO-confirmed, but photo-slot completeness/mandatory status, N/A rules and ambiguous quantity wording remain open. Notifications must not encode checklist/photo-slot completion rules or expose evidence content.

## 3. Triage vocabulary

| Classification | Meaning |
|---|---|
| **P — PO discussion candidate** | Product workflow may justify a human-facing notice. This is not an allowlist decision. |
| **O — operational/control event** | Useful for audit, state processing or internal operations; no user notification is justified by current PRD evidence. |
| **X — excluded from ordinary matching** | Read-side, recursive, generic batch envelope or unrelated event must not become an ordinary user-notification trigger by inference. |
| **U — unresolved token** | Source declaration is composite, conditional, ambiguous or lacks an exact canonical token/transaction mapping. Not eligible for policy publication. |

Recipient language in this document is conceptual only (e.g. “requesting user”, “assigned Inspector”, “assigned Reviewer”). It does not assert physical event fields, canonical role IDs, grants, scope columns or participant mappings.

## 4. CMD-001–040 event-by-event triage

| CMD | Source declaration as recorded | Triage | Product relevance and boundary | Recipient / token status |
|---|---|---|---|---|
| CMD-001 | `account.requested` | P | Acknowledgement or processing notice may help the requesting user, but PRD does not specify notification timing/channel. | Requesting-user intent only; participant field and allowlist require PO approval |
| CMD-002 | `account.approved` | P | Approval is a user-visible access lifecycle transition. | Requesting-user intent only; exact target mapping and policy approval required |
| CMD-003 | `account.rejected` | P | Rejection is a user-visible access lifecycle transition. | Requesting-user intent only; exact target mapping and policy approval required |
| CMD-004 | `role.assigned`; `permission.changed` if bundle changes | U | Authority change may require notice, but the conditional second event and whether one or two canonical events are emitted are unresolved. | Split exact tokens and source conditions; target/actor selection not inferred |
| CMD-005 | `role.revoked` | P | Revocation may require notice to the affected user; POQ-04 defines event-time candidate semantics only, not an enabled notice. | Target only if exact approved selector selects; actor never auto-added |
| CMD-006 | `scope.changed` | U | Scope grant changes may affect access, but event direction and exact target semantics are not distinguished. | Must distinguish grant vs revoke and exact principal/scope references |
| CMD-007 | `scope.changed` | U | Same token is reused for scope revocation; source event needs a distinct exact event identity or explicit discriminator. | No selector until grant/revoke token ambiguity is resolved |
| CMD-008 | `project.created` | O | Administrative setup event; PRD does not define a broadcast or project-created notice. | No recipient implied |
| CMD-009 | `project.updated` | O | Generic updates can be noisy; no field-level material-change policy exists. | No recipient implied; do not notify on every update |
| CMD-010 | `project.closed` | P | Closure is material to assigned operations, but project closure has explicit prerequisites and a transition-specific dispatch hazard. | Assigned operational audience only if PO approves exact policy; no blanket active-parent check |
| CMD-011 | `session.created` | O | Session creation is planning activity; assignment membership is separately managed. | No recipients inferred from future assignments |
| CMD-012 | `session.updated` | O | Generic session update lacks a material-field classification and recipient rule. | No recipient implied |
| CMD-013 | `session.close_requested` action/event; final `session.closed` | U | Request/action is not the final state event. A user notice, if needed, must bind to the final committed close event. | Only exact `session.closed` may be considered after source contract and PO intent are confirmed; close_requested is not interchangeable |
| CMD-014 | `assignment.created` | P | Assignment is the direct mechanism for allocating operational work to a team. | Assigned members may be candidate principals; exact inserted-member mapping and scope required |
| CMD-015 | `assignment.changed` | P | Member changes may materially affect work ownership. | Added/removed member set must be exact; POQ-04 pre-end semantics apply; no substitute recipient |
| CMD-016 | `capacity.limit_changed` | O | Capacity administration is not itself an operational task notice. | No recipient implied |
| CMD-017 | `target.created/reallocated/version_published` | U | Target-plan lifecycle has multiple outcomes; PRD separates planned target from actual inspection activity. | Split exact tokens and establish meaningful audience before review |
| CMD-018 | `instrument.created` | O | Catalog creation is administrative configuration, not an inspection event. | No recipient implied |
| CMD-019 | `instrument.version_drafted`; “config changed events” | U | Draft edits and unspecified configuration events must not trigger operational notices. | “config changed events” has no exact canonical token; unresolved |
| CMD-020 | `instrument.version_published` | P | Publication may affect future session configuration, but active sessions freeze their instrument version. | Potentially scoped administrators only; no active Inspector broadcast; PO intent and exact affected-session semantics required |
| CMD-021 | `instrument.deactivated` | O | Catalog lifecycle event; assignment/reference blockers are separate. | No recipient implied; do not infer cancellation of active work |
| CMD-022 | `unit.registered` OR `identity_conflict_opened` | U | These are distinct outcomes: successful canonical registration vs conflict. | Must split exact tokens; no shared selector assumption |
| CMD-023 | `unit.project_associated` | O | Canonical unit association is a domain relationship change; no human notice is specified. | No recipient implied |
| CMD-024 | `unit.project_association_ended/revoked` | U | Slash notation does not establish whether this is one token, two outcomes or aliases. | Exact token and transition semantics unresolved; no enablement |
| CMD-025 | `unit.identity_conflict_resolved/rejected` | U | Resolution and rejection are different outcomes and may have different affected principals. | Split exact tokens and establish target mapping |
| CMD-026 | `unit.claimed` AND `inspection.created` | U | Two domain facts may be committed by one command; they are not one interchangeable event. Claim/creation is not automatically a user notification. | Exact per-event boundary, correlation and audience intent unresolved |
| CMD-027 | `unit.claim_released` | O | Claim release is a recovery/control transition; no next Inspector may be inferred or automatically substituted. | No recipient implied |
| CMD-028 | `inspection.draft_saved` | O | Draft autosave/retry can be frequent and is not a meaningful user notice. | Exclude from ordinary notifications |
| CMD-029 | `inspection.submitted` AND `inspection_revision.created` | U | Submission is a meaningful review-queue transition; revision creation is a related immutable fact, not necessarily a second notice. | Review submission as a single user-facing intent only after exact event contract, Reviewer assignment and deduplication are approved |
| CMD-030 | `inspection.returned_for_correction` | P | Explicit Reviewer return creates an Inspector action. | Assigned Inspector for that inspection may be candidate; exact assignment/revision mapping required |
| CMD-031 | `inspection.approved` | P | Approval is a meaningful completion transition for the inspection workflow. | Assigned Inspector may be candidate; no inferred project-wide broadcast |
| CMD-032 | `inspection.reopened` | P | Reopening changes approved-work state and may require scoped operational follow-up. | Exact responsible Inspector/Reviewer and scope semantics are unresolved; PO decision required |
| CMD-033 | `evidence.upload_intent_created` | O | Upload intent is a technical intermediate state, not proof that evidence was uploaded. | No user notice; never expose upload intent as evidence completion |
| CMD-034 | `evidence.uploaded` | O | Evidence upload confirmation is an intermediate inspection artifact; no notification requirement is established. | No recipient implied; evidence remains private and independently authorized |
| CMD-035 | `sync.batch_applied/conflicted` plus domain events | U | Batch envelope outcomes and per-operation domain events have different boundaries. Per-operation domain events must be triaged independently; no batch-wide broadcast. | Split exact batch tokens and each domain event; transaction/savepoint/cardinality unresolved |
| CMD-036 | `pdf.generated`, `ba.generated`, `attendance.generated` | U | These are distinct document classes with different readiness and authority. Generation is not proof of print, signature or verification. | Split by document type; recipient and worker/finalizer contract unresolved |
| CMD-037 | `document.printed`, `document.reprinted` | O | Print events are audit records; user notification would generally duplicate the operator action absent an approved need. | No recipient implied; keep print audit distinct from provider delivery |
| CMD-038 | `document.print_batch_created/completed/partial` plus per-document print events | U | Batch envelope and per-document print outcomes must not be collapsed. Partial completion needs per-item evidence. | Split exact batch states and per-document events; no batch-wide notification by default |
| CMD-039 | `attendance.uploaded/replaced` | U | Upload/replacement are different states; Attendance Verifier authority remains open. | Split exact tokens; no verifier notification until role/authority approved |
| CMD-040 | `attendance.verified` | O | Verification is a business record; PRD does not specify who should receive a notification. | No recipient implied; Attendance Verifier authority and sign-off rules remain open |

## 5. First-batch PO-approved specification candidates — not an enabled allowlist

The Product Owner approved the following eleven exact candidate intents on 2026-11-24 for registry specification and Security/Engineering/Database review only. This approval is not event enablement, recipient/channel approval or technical admission. Other rows classified P remain secondary candidates and must not be silently treated as rejected or approved; for example, account.requested (CMD-001) remains deferred.

| Priority | Exact event candidate / unresolved source | Why PO review is justified | Required PO decision |
|---|---|---|---|
| 1 | `assignment.created` (CMD-014) | A team member is assigned operational work | Should assigned members receive an in-app notice? Which member classes and what exact assignment event? |
| 2 | `assignment.changed` (CMD-015) | Assignment membership changes work ownership | Should only added/removed members receive a notice? Define treatment of retained members and ended membership |
| 3 | `inspection.submitted` (CMD-029) | A submitted immutable revision enters the Reviewer queue | Should the currently assigned Reviewer receive a notice? Define duplicate relationship to revision-created fact |
| 4 | `inspection.returned_for_correction` (CMD-030) | Inspector must act on explicit correction feedback | Should the assigned Inspector receive a notice? |
| 5 | `inspection.approved` (CMD-031) | Inspector needs a clear review outcome | Should the submitting/assigned Inspector receive a notice? |
| 6 | `inspection.reopened` (CMD-032) | Previously approved work returns to active work | Who owns the next action, and is a notice required? |
| 7 | `account.approved` / `account.rejected` (CMD-002/003) | Applicant's account lifecycle outcome is user-visible | Is an in-app notice required in addition to account status visibility? |
| 8 | `role.revoked` (CMD-005) | Affected user may lose operational authority | Is a notice required, and how does it coexist with access revocation? POQ-04 semantics remain binding |
| 9 | `project.closed` / exact `session.closed` (CMD-010/013) | Closure affects assigned operations | Should scoped assigned members receive a closure notice? Which closure events and recipients? |

This approved batch is intentionally narrow. It authorizes only draft registry specification and technical review. All eleven rows remain UNRESOLVED — NOT ENABLED until exact source contracts, participant mappings, selectors, dispatch profiles, deduplication, atomicity and required approvals are evidenced. Other U events require exact source-contract decomposition before product review; O/X events are not notification candidates under current evidence.

## 6. Hard exclusions and anti-noise rules

1. No notification for every draft save, evidence upload, read, query, audit row, print action, retry or generic update.
2. No notification on a command merely because it writes an audit record or an outbox-capable event.
3. No generic “all school users”, “all teachers”, “principal”, “all project users” or global-role audience.
4. No inferred recipient from institution affiliation, actor/target presence, or future assignment.
5. No notification for an IFP/Standing Bracket checklist item or photo slot. Checklist/evidence completeness remains inside inspection validation and review.
6. No attachment of evidence bytes, permanent Storage URLs, JWTs, provider secrets or sensitive finding payloads to notification content.
7. No duplicate notices for one logical transition merely because a command writes both an aggregate event and a revision/audit/child event.
8. Batch envelopes do not substitute for per-operation/per-document event semantics.
9. A notice is not an authorization token; resource access is re-authorized independently.
10. POQ-01/04 immutable candidate and no-widening semantics remain mandatory.

## 7. Exact event registry admission checklist

An event cannot be marked ENABLED until all fields below are resolved and approved:

- Exact canonical event token (no slash alternatives, conditional prose, prefix matching or wildcard).
- Owning command/worker and exact transaction/finalization boundary.
- Whether event is a domain state transition, action request, batch envelope, item event or technical intermediate.
- Product workflow reference and explicit PO-approved human notification purpose.
- Exact event-time participant mapping from trusted source fields; no guessed JSON paths or client-supplied principal IDs.
- Exact permitted selector kind, canonical role/scope references and effective-time semantics.
- Event-specific dispatch profile (account, channel, consent, security, current scope, parent state, retry and suppression reason codes).
- Deduplication/correlation behavior where multiple facts represent one logical transition.
- Selector dependency columns/tables and complete writer/bypass inventory input for F-04.
- Atomic source mutation + event + audit + idempotency + outbox + immutable candidate snapshot proof.
- Security/Engineering/Database review and required Records/Privacy approval.
- Traceable acceptance tests, all executed only after G10 activation.

If any required field is unknown, the registry row remains `UNRESOLVED — NOT ENABLED`.

## 8. Findings and next controlled action

1. The PRD confirms notification as a supporting product capability but does not provide an event-level allowlist or notification recipient matrix.
2. Nine workflow areas are candidates for Product Owner discussion; no event is approved by this triage.
3. Composite/conditional declarations CMD-004, 006–007, 013, 017, 019, 022, 024–026, 029, 035–036, 038–039 require exact token/transaction decomposition before registry admission.
4. CMD-041–044 read-side activity is not a notification source by inference. CMD-045–048 require separate control-plane review. CMD-049–054 remain excluded from ordinary domain matching by default.
5. Attendance Verifier authority remains open; attendance notifications cannot target that role.
6. The IFP instrument specification remains draft and the ten photo slots' mandatory status is open. Standing Bracket's official 19-row checklist is PO-confirmed, but evidence/photo requirements remain open. These content gaps do not block documenting event triage, but they prohibit notification rules that assume checklist/evidence completion semantics.
7. Next action: prepare and review the eleven candidate rows in NLA-EVENT-REGISTRY-001 v0.1.0. Engineering/Security/Database must resolve source contracts, trusted participant mappings, selector dependencies and dispatch profiles. Secondary P candidates (including account.requested) remain deferred for a later PO decision. Do not enable any event or expand this batch without explicit change control and required approvals.

## 9. Current status and gate boundary

- This document is a static audit; no notification event is enabled.
- NLA-EVENT-REGISTRY-001 v0.1.0: draft candidate inventory exists; 11 PO intents approved for specification/review only; 0 technically admitted; 0 enabled.
- Selector grammar and dispatch profiles: REVIEW CANDIDATES ONLY.
- F-05: OPEN. F-04: OPEN. F-03/F-07: OPEN.
- Resolver certification 0/40; application lock certification 0/50.
- Global lock graph NOT PROVEN ACYCLIC.
- Candidate snapshot relation/header NOT ADMITTED.
- TC-NOTIF-001..072 remain PLANNED / NOT EXECUTED.
- G9 NOT READY; G10 NOT ACTIVE.

No source code, SQL, migration, grant/revoke, RLS, live DB, runtime test, deployment, merge or implementation activation was performed or authorized.

## 10. Sources reviewed

- `docs/01-product-requirements/PRD.md` §§3–7, 10, 13.
- `docs/01-product-requirements/IFP-INSTRUMENT-SPECIFICATION.md` §§1–6 (draft; source authority and evidence mandatory status open).
- `docs/01-product-requirements/STANDING-BRACKET-INSTRUMENT-SPECIFICATION.md` §§1–7 (PO-confirmed official 19-row baseline; evidence and remaining interpretation gaps open).
- `docs/02-architecture/L05-SOURCE-EVENT-PATH-MAPPING-001.md` §3 (CMD-001–040 producer/event declaration inventory).
- `docs/02-architecture/NOTIFICATION-LIFECYCLE-AND-DELIVERY-ARCHITECTURE.md` §§5–8, 20–23.
- `docs/02-architecture/NOTIFICATION-AUDIENCE-GUARD-TECHNICAL-DECISION-RECORD-001.md` §§4.2.4–4.2.6.
- `docs/02-architecture/CANONICAL-PERMISSION-REGISTRY-AND-COMMAND-AUTHORIZATION-MATRIX.md` §5 (role/grant matrix NOT APPROVED).
- `docs/00-project-charter/DECISION-REGISTER.md` POQ-001 and POQ-04.
- Root `AGENTS.md` v1.2.2.


## 11. PO decision update — 2026-11-24

The Product Owner approved all eleven first-batch candidates listed in §5 for specification and technical review only. The canonical decision is recorded in `docs/00-project-charter/DECISION-REGISTER.md`; the controlled draft registry is `NLA-EVENT-REGISTRY-001 v0.1.0`. This does not enable any event or approve recipients, channels, physical fields, role grants, selectors, dispatch profiles, implementation or tests. All registry rows remain UNRESOLVED — NOT ENABLED. `account.requested` remains deferred, neither approved nor rejected. F-05/F-04/F-03/F-07 remain OPEN; G9 NOT READY; G10 NOT ACTIVE.
