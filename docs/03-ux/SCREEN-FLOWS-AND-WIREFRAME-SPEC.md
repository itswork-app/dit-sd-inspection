# Screen Flows and Wireframe Specification

Status: UX specification draft — not pixel-final
Version: 0.1.0

## 1. Shared application shell
- Header: organization/product identity, current user, active role, connection/sync indicator.
- Context strip: active project, session, location, instrument, team where relevant.
- Main content: one primary task per screen.
- Feedback: loading, empty, validation, offline, permission denied, conflict, and server error states.
- Mobile: single-column layout, large touch targets, sticky primary action where safe.
- Desktop: content width constrained for forms; data tables may use wider layout.

## 2. Core Inspector flow

1. Google sign-in.
2. If account pending, show approval status and no operational navigation.
3. On approval, load explicit assignment(s); if none, show no-assignment state.
4. Select an active assigned session/assignment when multiple are available.
5. Open My Work and claim an available unit.
6. Enter/confirm serial number; show duplicate/claim conflict with safe recovery action.
7. Inspection workspace:
   - Step 1: Identitas unit.
   - Step 2: Dokumentasi foto with named slots and upload state.
   - Step 3: Checklist grouped by instrument category.
   - Step 4: Review completeness and exceptions.
   - Step 5: Submit.
8. Confirmation screen displays server submission reference and status.
9. Track review result; if returned, show reviewer reason and correction task.
10. Correct in a new revision and resubmit; prior revision remains visible read-only.

## 3. Inspection workspace layout requirements
- Show serial number and instrument/session context persistently.
- Display checklist section progress without implying unverified items are complete.
- Every response must be explicit; default visual state must not equal "OK".
- Exceptions require configured reason/note/evidence.
- Photo slots show required/optional status, capture/upload state, preview, retry, and replace-as-new-evidence behavior.
- Prevent submission while mandatory fields, evidence, or sync conflicts remain unresolved.
- Warn before leaving with unsaved local changes; explain whether saved locally or confirmed by server.

## 4. Reviewer flow
- Queue filters are bounded to assigned scope.
- Detail view shows exact submitted revision and its configuration version.
- Reviewer can inspect evidence and checklist; cannot edit Inspector responses.
- Return requires reason and creates a correction task.
- Approve requires confirmation and writes a review event.
- Reviewer cannot approve own work; UI must explain denied action without exposing unauthorized data.

## 5. Korlap/Admin flow
- Location/session dashboard: target, actual, remaining, status, team workload.
- Team view: assigned users, claimed units, drafts, submissions, review backlog, approved and completed counts.
- Session actions show precondition checklist and blocking items.
- Daily report validation shows actual and target dimensions separately.
- No UI action may alter actual timestamps to satisfy a target.

## 6. Super Admin flow
- User approval queue with identity, requested profile, decision, role, and scope.
- Role/permission and assignment editor with explicit scope preview.
- Capacity control: current distinct Inspector count, configured cap (50–100), safe increase/decrease validation.
- Instrument configuration editor with draft version, preview, validation, publish confirmation, and immutable active-session snapshot.
- Project/session/target planner with version history and impact preview.
- Audit viewer with actor, active role, scope, timestamp, action, and correlation reference.

## 7. Print Officer flow
- Approved and eligible PDF queue.
- PDF preview and document metadata.
- Explicit "Catat sudah dicetak" action after physical print; system must not infer printing from PDF open/download.
- Reprint action increments print event count and renders ordinal footer.
- BA and attendance flows must expose their independent lifecycle states.

## 8. Required screen states
For every screen define: initial loading, populated, empty, validation error, permission denied, network unavailable, offline/local-only, sync pending, conflict, server error, and retry. Sensitive data must not appear in generic error messages.

## 9. Wireframe review criteria
- One-handed mobile use for inspection tasks.
- No horizontal scrolling for primary mobile forms.
- Clear progress and explicit completion semantics.
- Visible active assignment context.
- Evidence legibility and upload retry.
- Accessible labels and keyboard operation.
- Confirm destructive/high-impact actions and capture reason where required.

## 10. Reference limitations
This specification is based on the known workflow and transcribed labels recorded in the PRD and instrument specifications. It is not a pixel-perfect reconstruction of the legacy app. Any missing or uncertain legacy behavior must be checked against original screenshots or Product Owner confirmation before being treated as parity requirement.
