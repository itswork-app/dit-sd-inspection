# Evidence Storage and Media Lifecycle — Dit. SD Inspection

Status: Technical design draft — limits and retention require approval  
Version: 0.1.0

## 1. Goals

Protect original inspection evidence, minimize upload failures on mobile networks, prevent cross-scope access, and keep object storage cost predictable.

## 2. Storage model

- Use private Supabase Storage buckets; no public evidence bucket.
- Store object metadata in PostgreSQL `evidence_assets`.
- Object keys are opaque and non-guessable; do not embed personal names or serial numbers in public paths.
- Suggested key structure: `project_id/inspection_id/revision_or_draft_id/evidence_asset_uuid`; IDs are not an authorization mechanism.
- Access requires authenticated authorization against project, assignment, inspection, and evidence-slot scope.
- Signed URLs are short-lived and generated only after authorization; exact TTL is configurable after security review.

## 3. Upload lifecycle

1. Client requests an upload intent for a known inspection draft and allowed evidence slot.
2. Server validates identity, assignment, draft state, slot/version, file type/size policy, and quota.
3. Server creates a pending evidence metadata row and returns a narrowly scoped upload authorization.
4. Client uploads bytes directly to private Storage; large uploads should use resumable upload if supported and justified by field-network tests.
5. Client confirms completion; server verifies object existence, size, MIME type, and checksum where available.
6. Asset becomes VERIFIED/AVAILABLE only after server confirmation.
7. Inspection submission validates all mandatory evidence assets are available and attached to the exact revision.
8. Original finalized object is immutable; replacement is a new asset with reason and audit trail.

## 4. Media validation and safety

- Allow only approved image types; initial candidate JPEG/PNG/WEBP requires Product Owner/operations confirmation.
- Validate actual file signature, not only filename or browser MIME header.
- Reject executable content, malformed images, unsupported formats, and files above configured limit.
- Strip unnecessary EXIF metadata from derivatives where privacy requires; preserve original only if metadata is needed as evidence and retention is approved.
- Generate thumbnails/preview derivatives without modifying originals.
- Do not trust client timestamps as authoritative server event timestamps.
- Malware scanning approach is an open decision; do not claim files are malware-free without scanning.

## 5. Reliability and cost

- Upload retries use an idempotency key and stable asset ID.
- Partial/abandoned uploads remain pending and are reconciled; do not delete automatically until safe retention/expiry policy is approved.
- Compress client-side copies for preview/upload only if image legibility remains adequate for evidence.
- Measure average and p95 file size, upload duration, retry rate, storage growth, and egress.
- Avoid repeatedly downloading original images for list views; use appropriately sized previews.
- Do not set final file-size caps, retention duration, or deletion schedule until official evidence requirements and provider quotas are reviewed.

## 6. Evidence integrity

- Record checksum, byte size, MIME, uploader, server receipt time, object key, slot/item, inspection/revision, and verification status.
- Submitted evidence metadata and finalized objects are immutable to ordinary application roles.
- Corrections append new evidence; they do not replace the historical original.
- A missing object or checksum mismatch blocks submission/finalization and raises an operational issue.
- Access logs/audit events must not contain signed URL tokens or raw sensitive media.

## 7. Open decisions

- Required image resolution/legibility and accepted formats.
- Per-file and per-inspection size limits.
- Resumable upload implementation and threshold.
- Retention, archival, deletion, legal hold, and privacy policy.
- Whether EXIF is evidentiary or should be stripped.
- Malware scanning capability/cost.
- Whether generated PDFs are stored alongside evidence or regenerated from immutable snapshots.


## Package T-10 — Product Owner decision (2026-11-23)

**Decision: PO APPROVED option B — formal institutional records/legal/privacy review before defining the evidence policy.** The project must obtain a documented review by the institution's authorized records, legal and privacy functions before approving data classification, permitted personal information and processing purpose, accepted evidence formats, per-file/per-inspection/per-project limits, retention periods and triggers, legal-hold authority, deletion eligibility/approval/audit, private access rules, backup/restore and post-deletion treatment, and any local/offline copy controls.

**Important boundary:** this is Product Owner approval of the governance path, not institutional legal/records approval and not approval of any numeric limit, retention period, lawful basis, deletion schedule or production evidence collection. Until the authorized institutional review supplies written direction, retain all such values as OPEN/NOT SET; do not invent limits or retention durations, enable irreversible deletion, or authorize production evidence collection. T-10 remains BLOCKED for scope freeze and production activation pending that external evidence. No implementation or tests are claimed.
