# Design System and Responsive UX

Status: Design system draft — visual tokens to be approved
Version: 0.1.0

## 1. Product design direction
Professional, restrained, government-institution appropriate, high legibility in varied field lighting. Prioritize clarity and trust over decorative styling. Avoid relying on color alone to communicate status.

## 2. Design tokens (initial proposals)
- Typography: system sans-serif stack; clear hierarchy for page title, section title, field label, helper text.
- Spacing: 4px base scale; consistent 8/12/16/24/32px steps.
- Radius: modest 8–12px for cards/inputs; consistent control geometry.
- Borders: subtle neutral borders; visible focus ring.
- Elevation: limited to menus/dialogs; avoid heavy shadows.
- Color: neutral surfaces with one primary action color; semantic success/warning/error/info colors must be paired with text/icon labels. Exact palette and contrast verification pending.
- Touch: target at least 44×44 CSS px for primary interactive controls where practical.

## 3. Component inventory
- App shell, responsive navigation, role/scope context selector.
- Status badge with text and icon.
- Buttons: primary, secondary, destructive, quiet; disabled/loading states.
- Text input, numeric/serial input, select, date/time input, textarea.
- Checklist response control with explicit unanswered/OK/not-OK/N/A states only where configured.
- Evidence slot card: label, required indicator, capture/upload state, preview, retry, replace-as-new.
- Progress indicator and validation summary.
- Data table with server pagination, filter, sort, empty state.
- Confirmation dialog and reason-required dialog.
- Toast/inline alert; do not rely on transient toast for critical transaction confirmation.
- Offline/sync banner with local/server persistence distinction.
- Audit timeline and version history.
- PDF preview/print action panel.

## 4. Responsive behavior
- Mobile-first for Inspector capture/checklist.
- Tablet: split-pane inspection only if it does not reduce evidence readability or form usability.
- Desktop: wider dashboards, reviewer queue, Super Admin configuration, and reports.
- Tables convert to stacked summary cards on narrow viewports; preserve essential identifiers and status.
- Avoid loading large images in list views; use thumbnails and explicit full-size preview.
- Dialogs become full-screen sheets on narrow devices when content requires it.

## 5. Accessibility
- Semantic HTML controls and labels.
- Full keyboard navigation and visible focus.
- Screen-reader names for icon-only controls.
- Error messages associated with fields.
- Contrast target WCAG 2.2 AA as a proposed baseline; validate actual tokens.
- Do not encode status only by color.
- Respect reduced-motion preference.
- Accessible PDF output is a separate requirement to validate.

## 6. Data-entry safeguards
- Never preselect OK or complete for checklist answers.
- Preserve text on validation failure.
- Prevent accidental double-submit with UI state plus server idempotency.
- Explain server-confirmed save versus local-only save.
- Confirm leave/navigation when local changes are not safely persisted.
- Do not show an action button if the role lacks permission, but still enforce permission on server.

## 7. Visual QA
Test at narrow mobile, common Android viewport sizes, tablet, and desktop; exact device/browser matrix remains open. Verify portrait/landscape, zoom, long labels, large text, slow network, and high-contrast/accessibility settings.


## T-11 supported browser baseline
The Product Owner approved Package T-11 option B on 2026-11-23: current stable Chrome on Android for Inspector field workflows; current stable Chrome or Edge on desktop for Korlap, Reviewer, Super Admin and Print Officer. Tablet support requires validation of responsive layout, camera, upload and PDF/print. Obsolete/unsupported releases, embedded in-app browsers, modified browsers, and devices failing required capabilities are excluded. Exact OS/device minimums and browser build numbers must be recorded from actual UAT devices. This decision does not claim compatibility testing has been completed.
