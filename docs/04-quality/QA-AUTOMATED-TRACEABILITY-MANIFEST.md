# QA Automated Traceability Manifest

**Document ID:** QA-TRACE-001  
**Version:** 1.0.0  
**Date:** 2026-11-27  
**Baseline:** `main` (`c3eb81c` + PR #46)  
**Authority:** [G11-ECP-001](../00-project-charter/G11-EVIDENCE-CLOSURE-PLAN.md) (`WP-06` §7.1); [DGA-001](../00-project-charter/DOCUMENTATION-GAP-AUDIT-GATE-READINESS.md); [TEST-CASE-CATALOG-AND-UAT.md](TEST-CASE-CATALOG-AND-UAT.md)  
**Status:** PARTIAL — maps **24** explicitly verified catalogue IDs to executable assertions while keeping all remaining unmapped cases in the 558-ID catalogue strictly `PLANNED / NOT EXECUTED` or `EXTERNAL / BLOCKED`.

## 1. Security & Integrity Static Scans (2026-11-27)

Executed on workspace `main` (`c3eb81c`):

| Check | Scope | Command / Method | Observed Result |
|---|---|---|---|
| Dependency vulnerability audit | Locked `package-lock.json` tree | `npm audit --json` | `0` vulnerabilities (`info:0, low:0, moderate:0, high:0, critical:0, total:0`) |
| Tracked secrets / credentials scan | `git ls-files` | Pattern check `.env`, `.pem`, `.key`, `credentials`, `secret` | `NO_SECRET_FILES_TRACKED` (`0` matches) |
| Server runtime `service_role` exclusion | `src/` application runtime | `grep -rnE "service_role\|SERVICE_ROLE_KEY\|sb_secret_" src/` | `ZERO_SERVICE_ROLE_IN_SRC` (`0` matches) |

## 2. Mapped Automated Assertions → Catalogue IDs (`WP-06` Subset)

Every mapping below links a catalogue ID in `TEST-CASE-CATALOG-AND-UAT.md` to concrete executable assertions in repository test/verification files. Only cases actually verified by those assertions are listed; no bulk status promotion is claimed.

| Catalogue ID | Test / Script Source | Assertion & Observed Behavior | Environment Class | Status |
|---|---|---|---|---|
| `TC-AUTH-001` | `scripts/verify-i1-i2-db.sql`; live staging `emqlbtnejinbqlxpoakd` | Google sign-in maps via `CMD-001` to single `app_users` + `account_requests` row (`6d6bf1be-…`) | Local SQL + Staging OAuth | PASS (synthetic) |
| `TC-AUTH-002` | `scripts/verify-g11-http-e2e.mjs` (`[TC-AUTH-002]`) | `PENDING` applicant denied `403` on `/api/v1/admin/accounts`; unauthenticated routes `307 /login` / `401` | Local HTTP/JWT E2E | PASS (synthetic) |
| `TC-AUTH-003` | `scripts/verify-g11-http-e2e.mjs` (`[TC-AUTH-003]`); `scripts/verify-i1-i2-db.sql` | `CMD-002` Super Admin approval + explicit `CMD-004`/`CMD-006` role/scope grant enables access | Local HTTP/JWT + SQL | PASS (synthetic) |
| `TC-AUTH-005` | `scripts/verify-i1-i2-db.sql` (lines 179, 234–237, 290–294, 337–342) | Self-approve denied; `CMD-004` self-grant returns `SOD_VIOLATION`; non-`super_admin` escalation & delegation ceiling return `PERMISSION_DENIED` | Local PostgreSQL | PASS (synthetic) |
| `TC-AUTH-009` | `scripts/verify-g11-http-e2e.mjs` (`[TC-AUTH-009]`); `supabase db query --remote --read-only` | Direct PostgREST anon table access denied `401` (`SQLSTATE 42501`); `62/62` `ENABLE + FORCE RLS` | Local + Staging RLS audit | PASS (synthetic) |
| `TC-CAP-002` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 246–249, 287); `scripts/verify-g11-concurrency.mjs` | `CMD-016` updates `inspector_cap` below 50 (`1`, `2`, `4`) | Local PostgreSQL | PASS (synthetic) |
| `TC-CAP-004` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 298–302) | `CMD-016` reduction below qualifying Inspector count rejected (`BELOW_COUNT`) | Local PostgreSQL | PASS (synthetic) |
| `TC-CAP-005` | `scripts/verify-g11-concurrency.mjs` (`LG-01/LG-03`, `[TC-CAP-005]`) | 4 parallel Inspector additions against `cap=2` yield `2 UPDATED`, `2 CAPACITY_EXCEEDED`, count=`2`, 0 deadlocks | Local parallel PostgreSQL | PASS (synthetic) |
| `TC-UNIT-016-001` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 330–350) | Duplicate normalized serial in same `instrument_type` across project routes to `CONFLICT_REVIEW_REQUIRED` with zero `unit_id` leak | Local PostgreSQL | PASS (synthetic) |
| `TC-UNIT-016-002` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 340–343) | Same normalized serial succeeds for a different `instrument_type` | Local PostgreSQL | PASS (synthetic) |
| `TC-UNIT-016-003` | `scripts/verify-g11-concurrency.mjs` (`LG-31`, `[TC-UNIT-016-003]`) | 4-project concurrent registration of same serial produces `1 REGISTERED`, `3 CONFLICT_REVIEW_REQUIRED`, `1` canonical row | Local parallel PostgreSQL | PASS (synthetic) |
| `TC-UNIT-016-004` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 352–363) | `CMD-025` controlled conflict resolution & `CMD-024` association end with audit | Local PostgreSQL | PASS (synthetic) |
| `TC-EVD-002` | `src/lib/storage/verify-binary.test.ts` (`[TC-EVD-002]`); `scripts/verify-g11-storage-pdf-e2e.mjs` (`[TC-EVD-002]`) | Magic-byte verifier accepts valid PNG/JPEG/WebP/PDF; forged HTML uploaded as PNG rejected `400 EVIDENCE_INVALID` | Vitest (CI + Local) + Storage E2E | PASS (synthetic) |
| `TC-EVD-004` | `scripts/verify-g11-storage-pdf-e2e.mjs` (`[TC-EVD-004]`) | Valid PNG confirmed only after server SHA-256 + magic-byte check (`FINALIZED`); outsider denied `403`; 60s signed download audited | Local Storage E2E | PASS (synthetic) |
| `TC-EVD-005` | `supabase/migrations/20261127090000_i4_private_storage_bucket_and_rls.sql` | Zero `UPDATE`/`DELETE` policies on `storage.objects` in `inspection-private` for client roles (immutable originals) | Local + Staging catalog | PASS (schema/RLS) |
| `TC-OFF-002` | `scripts/verify-i3-i4-inspection-sync-db.sql`; `src/lib/offline/sync-queue.ts` | Reconnect `CMD-035` batch submission (`operation_id` + `batch_key` idempotency) | Local PostgreSQL | PASS (synthetic) |
| `TC-OFF-003` | `src/lib/offline/sync-queue.test.ts` (`[TC-OFF-003]`) | Conflicting edits preserve `CONFLICT` status and local notes without silent overwrite; explicit rebase required | Vitest (CI + Local) | PASS (unit) |
| `TC-OFF-008` | `src/lib/offline/sync-queue.test.ts` (`[TC-OFF-008]`) | Server `VERSION_CONFLICT` surfaces conflict & preserves local draft version until explicit user rebase | Vitest (CI + Local) | PASS (unit) |
| `TC-OFF-010` | `scripts/verify-g11-concurrency.mjs` (`LG-41` idempotency); `scripts/verify-i3-i4-inspection-sync-db.sql` | Duplicate operation / idempotency replay returns original result; tampered payload rejected `IDEMPOTENCY_KEY_REUSED` | Local PostgreSQL | PASS (synthetic) |
| `TC-DOC-001` | `scripts/verify-g11-storage-pdf-e2e.mjs` (`[TC-DOC-001]`); `src/lib/storage/verify-binary.test.ts` | Approved revision generates deterministic `%PDF-1.4..%%EOF` in private Storage; SHA-256 matches 60s audited download; outsider `403` | Vitest + Local Storage E2E | PASS (synthetic) |
| `TC-DOC-004` | `scripts/verify-i4-i5-docs-print-notif-db.sql`; `scripts/verify-g11-concurrency.mjs` (`LG-21`) | Reprint ordinal increments atomically while retaining prior `print_events` | Local PostgreSQL | PASS (synthetic) |
| `TC-PRINT-001` | `scripts/verify-i4-i5-docs-print-notif-db.sql` | `CMD-037` permits Print Officer to print `is_current` finalized document and denies superseded versions (`DOC-003`) | Local PostgreSQL | PASS (synthetic) |
| `TC-PRINT-005` | `scripts/verify-g11-concurrency.mjs` (`LG-21`, `[TC-PRINT-005]`) | 6 parallel `CMD-037` requests allocate contiguous atomic ordinals `[1, 2, 3, 4, 5, 6]` | Local parallel PostgreSQL | PASS (synthetic) |
| `TC-SESSION-001` | `scripts/verify-i2-i3-core-domain-db.sql` (lines 235–240, 380–386) | Session/project close blocked while incomplete work/open session exists; succeeds only after prerequisite transitions complete | Local PostgreSQL | PASS (synthetic) |

## 3. Explicit Exclusion & Remaining Backlog (`534 / 558` Catalogue IDs Unmapped)

- **`PLANNED / NOT EXECUTED`:** All remaining catalogue IDs not explicitly row-mapped in §2 (`534` IDs, including real-device Android Chrome UAT `TC-OFF-001/005/006/011`, full `TC-INS-DRAFT-*`, `TC-NOTIF-*`, `TC-CMD-CONTRACT-024-*`, `TC-CMD-AUTHZ-024-*`, `TC-RLS-024-*`, `TC-FN-SEC-025-*`, `TC-EXEC-MODEL-027-*`, `TC-LIVE-INV-026-*`, `TC-REPO-AUDIT-028-*`).
- **`EXTERNAL / BLOCKED`:** `TC-EVD-006..010` (`T-10` institutional policy), `TC-AUDIT-EXPORT-*` (`CMD-044`), external `TC-NOTIF-*` email/push callbacks (`T-12`), `TC-CMD-045-048-*` (external control planes).
- **`WP-06` gate status:** Remains **PARTIAL** until remaining in-scope catalogue cases receive executed case-level evidence or owned `NOT APPLICABLE` / `DEFERRED` dispositions.
