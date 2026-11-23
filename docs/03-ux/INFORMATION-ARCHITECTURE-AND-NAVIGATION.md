# Information Architecture and Navigation

Status: UX design draft — validation required
Version: 0.1.0

## 1. Design principles
- Field-first: primary inspection actions must work comfortably on a phone.
- Task-oriented navigation; avoid exposing administrative complexity to Inspectors.
- Preserve the known legacy workflow where requirements are evidenced; improvements must not remove required capability.
- Clear status and next action on every work item.
- No action may appear successful until the server confirms it, except an explicitly marked locally saved offline draft.
- Responsive layout for mobile and desktop; exact supported browser/device matrix remains open.

## 2. Application areas

### Public / account
- Sign in with Google.
- Pending approval / rejected / suspended access state.
- Account profile and sign-out.

### Inspector workspace
- Assigned session and assignment overview.
- My work: available units within assignment, claimed units, drafts, corrections, submitted history.
- Start/resume inspection.
- Instrument selection limited to explicit assignments.
- Serial number entry and duplicate/claim conflict handling.
- Documentation/evidence capture.
- Checklist by category.
- Review before submit and validation summary.
- Sync status and unresolved offline conflict state.

### Reviewer workspace
- Assigned review queue.
- Inspection detail and evidence.
- Return with mandatory correction reason.
- Approve with confirmation.
- Review history and immutable submitted revision.

### Korlap/Admin workspace
- Assigned location/session overview.
- Team and Inspector activity/progress.
- Operational issues and claim visibility.
- Session open/pause/close actions subject to completion gates.
- Daily report validation where authorized.

### Print Officer workspace
- Approved inspection PDF queue.
- Document preview and print action.
- Reprint history and print ordinal.
- BA and attendance document handling only within assigned scope.

### Super Admin workspace
- Global project overview.
- User approval and role/scope assignment.
- Project/session/location/team/target configuration.
- Inspector capacity setting (50–100 combined).
- Instrument/checklist/photo-slot version management.
- Workflow, permissions, templates, and reporting configuration.
- Audit search/export.

## 3. Navigation model
Mobile primary navigation should expose only the active user's operational workspace: Beranda, Pekerjaan, Notifikasi/Status, Profil. Contextual inspection steps use a persistent step indicator rather than nested menus. Administrative workspaces may use a desktop sidebar and mobile drawer.

Navigation visibility is convenience only; authorization is enforced server-side and by RLS.

## 4. Information hierarchy
Project → Session period → Operational assignment (location + instrument + team) → Unit → Inspection → Revision → Evidence/checklist/review/document events.

An assignment is the Inspector's operational boundary. Do not let an Inspector browse or select another location/team/instrument outside assigned scope.

## 5. Status language
Use explicit Indonesian labels with consistent semantic meaning:
- Menunggu persetujuan akun
- Belum ditugaskan
- Tersedia
- Sedang diperiksa
- Draft tersimpan di perangkat
- Menunggu sinkronisasi
- Menunggu review
- Perlu perbaikan
- Disetujui
- PDF siap dicetak
- Sudah dicetak
- Selesai

The final glossary and status mapping must align with the approved state machine.

## 6. UX open decisions
- Whether the app supports installation as PWA or browser-only for first release.
- Exact browser and device matrix.
- Whether Inspector home defaults to current assignment or My Work.
- Notification channels and read/unread behavior.
- Accessibility target and localization beyond Indonesian.
