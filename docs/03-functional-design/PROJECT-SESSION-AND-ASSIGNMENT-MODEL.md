# Project, Session, Target, and Assignment Model

**Status:** Draft v0.2.0 — requires Product Owner validation  
**Package:** C — Functional and Operational Design

## 1. Core hierarchy

The application distinguishes planning from actual field activity:

- **Project:** overall inspection program, target, period, locations, instruments, and governance.
- **Session:** a managed operational period with a lifecycle and assigned work.
- **Operational Assignment:** one location + one instrument + one team within a session.
- **Team membership:** named users with explicit roles within that assignment.
- **Inspection:** one physical unit inspected under one applicable assignment and instrument configuration version.

An assignment must never span multiple locations or multiple instruments. Parallel assignments may run during the same session period, for example IFP/Purwakarta/team A and Standing Bracket/Karawang/team B.

## 2. Planning authority

Super Admin determines and versions:
- project-wide target;
- target per instrument;
- weekly and session targets;
- session periods and dates;
- locations and instruments;
- operational assignments and team membership;
- Admin/Korlap, Reviewer, and Inspector assignments.

Inspectors cannot self-select official teams, locations, sessions, or instruments. A user may participate in different teams on non-overlapping sessions/days only when explicitly assigned. Overlapping assignments in different locations must be rejected unless the overlap is explicitly resolved by an authorized administrator.

The exact authority to create a session (Super Admin only vs delegated Admin) remains open. Admin/Korlap may open/close an assigned session as already decided, subject to workflow gates.

## 3. Session lifecycle

Proposed states:

- `DRAFT`: planning/configuration only; not available for field work.
- `ACTIVE`: assigned Inspectors may claim and work on units.
- `PAUSED`: no new claims or submissions unless an explicit recovery/admin policy allows them; existing drafts are preserved.
- `CLOSED`: terminal operational state after closure gates pass.

Transitions and authority (PO approved T-07, 2026-11-23):
- Super Admin exclusively creates/configures sessions, targets, locations, instruments and team assignments.
- DRAFT → ACTIVE: Korlap may activate only within assigned scope and explicit permission.
- ACTIVE → PAUSED: Korlap may pause only within assigned scope and explicit permission.
- PAUSED → ACTIVE: Korlap may resume only within assigned scope and explicit permission.
- ACTIVE/PAUSED → CLOSED: Korlap may request closure within assigned scope; final project closure is separately reserved to Super Admin under T-06.
- CLOSED is terminal in ordinary flow. Reopening requires explicit privileged permission, reason and audit.

No automatic closure based only on calendar date. Backend authorization must enforce every transition; UI visibility alone is insufficient.

## 4. Assignment invariants

Each operational assignment has exactly one session, location, instrument, and team. Membership has one or more roles with an explicit assignment scope.

- A person cannot be assigned overlapping field shifts in different locations.
- Admin/Korlap supervises only the assigned location/assignment.
- Reviewer approval scope is limited to explicitly assigned assignments.
- Inspector assignment is explicit; no self-claiming into another team.
- Global Inspector capacity is configurable below or above 50; initial/default value is 50 and hard ceiling is 100 distinct active Inspector accounts across both locations combined. Super Admin controls the configured value and allocation.
- This is a combined project capacity, not a per-location allowance. Allocation between locations may be uneven.
- A person holding Inspector role counts once, even if assigned to multiple sessions/teams.
- Capacity changes require authorization, audit history, and atomic enforcement during Inspector activation; a UI-only count is insufficient.

## 5. Targets versus actuals

Targets are planning/reporting data. Actuals are derived from immutable inspection activity and timestamps.

- Target allocation may be configured by day/session/instrument/location/team.
- Admin may manually reallocate target allocation to dates where authorized.
- Target schedule changes are versioned and audited.
- Reallocation never changes actual inspection dates, counts, timestamps, or productivity.
- System calculates actual progress, target progress, remaining quantity, and percentage; it does not silently create sessions or change official targets.

Dashboard dimensions include project, week, session, instrument, location, and team. State counts must distinguish at least: claimed/draft, submitted, returned for correction, approved, PDF generated, printed, and completed.

## 6. Completion and closure

A unit is considered **COMPLETED** only when:
1. inspection is approved;
2. final PDF has been generated;
3. a Print Officer print action has been recorded.

Session closure is separate from project closure. Korlap may request session closure within assigned scope; Super Admin is final project-closure authority. A session close action must be disabled until all configured requirements are met, including:
- no open drafts or active claims;
- no submitted inspections awaiting review;
- no returned inspections awaiting correction;
- all required inspections approved;
- final PDFs generated;
- required print events recorded;
- required BA and recap documents completed;
- attendance generated, printed, uploaded, and verified where required;
- Korlap submits the session closure request; authorized session closure follows the approved scope/permission workflow.

Project closure is performed only by Super Admin after every session is closed, no unresolved claims/drafts/corrections/reviews remain, required inspections and PDFs/print events/BA/attendance artifacts are complete and verified, and actual-versus-target reconciliation is reviewed. The action records reason/confirmation and audit; no date-based auto-close.

Printing may occur days after field inspection; the session remains open until required closure tasks are complete. No auto-close by date.

## 7. Versioning and audit

Changes to target, schedule, location, instrument, assignment, and team membership create versioned records or immutable change events. Historical inspections retain the assignment and configuration context under which they were performed.

## 8. Proposed logical entities

- `projects`
- `project_targets`
- `target_allocations`
- `sessions`
- `locations`
- `operational_assignments`
- `assignment_members`
- `assignment_versions`
- `inspection_claims`

## 9. Acceptance criteria

- An assignment cannot represent more than one location or instrument.
- User cannot work outside explicit assignment scope.
- Conflicting overlapping assignments are rejected.
- Concurrent Inspector activation cannot exceed the configured capacity (maximum 100) distinct Inspector accounts across both locations; capacity changes and activation are atomic and audited.
- Target changes never mutate actual activity data.
- Session cannot close while any required gate is incomplete.
- All planning and assignment changes are auditable and historical records remain attributable to their original versions.

## 10. Open decisions

- Exact pause behavior for already-open drafts and offline submissions.
- Detailed operational closure checklist and privileged reopening command contract.
- Final source-of-truth rule for target quantity when project, instrument, and session targets do not reconcile.


## Super Admin authority for team structure and staffing (PO clarification, 2026-11-24)

Super Admin controls the number of teams created for the project/session and the personnel assigned to each team. Personnel must first have registered application accounts; registration does not automatically place a person on a team or grant an operational role. Super Admin approves the account and assigns role(s), permissions, scope, team membership, and the operational assignment. Users cannot self-enroll into teams or self-assign inspection work. Team size and staffing are explicit planning data and must respect the approved combined Inspector cap and session/location/instrument plan.

## Product Owner decision update — closure, capacity and instrument deactivation (2026-11-24)

### Closed project/session fence — LPR-04

- Once a project or session is CLOSED, no new normal mutation or finalization is accepted, including child creation, assignment changes, claim acquisition/release, inspection changes, evidence/document finalization, attendance verification or worker completion that advances scoped work.
- Closure must serialize against every child writer and asynchronous finalizer. A preflight completeness read is advisory; the closure transaction must revalidate the gates under the approved parent-fence protocol.
- Reopening requires an explicit privileged workflow, recorded reason and audit. No ordinary transition silently reopens CLOSED state.
- Existing work is preserved as historical evidence; no automatic deletion or mutation is implied by closure.

### Inspector capacity — LPR-05 / T-14

The already approved T-14 predicate remains authoritative: count distinct login-enabled accounts with an active Inspector role grant and at least one currently effective operational Inspector assignment within the governed project/session scope. Count each account once. Registration alone, pending/rejected/suspended/disabled accounts and expired role grants do not count. Team membership/assignment, role grant/revoke/expiry, account disable/suspension and capacity changes must share one serialization point whenever they can change the qualifying population. The combined 1–100 cap/default 50 and existing no-silent-deactivation rule remain unchanged.

### Instrument deactivation — LPR-06

Deactivation blocks new assignment selection. An already-pinned session/assignment continues to reference its exact immutable historical instrument version by default. A safety withdrawal may override continued use only through a separately authorized, reasoned and audited workflow identifying affected sessions and required operational action. Deactivation must never rewrite historical instrument snapshots.

**Approval boundary:** these are PO-approved product semantics. Exact parent/child lock order, all eligibility-changing paths, safety-withdrawal authority, database enforcement and concurrency tests remain open for Engineering/Security and relevant institutional/operational owners. No implementation or tests are claimed.
