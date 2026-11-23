# Evidence Privacy, Retention, Deletion and Recovery Specification

**Status:** Policy and technical design draft — institutional approval required  
**Version:** 0.1.0  
**Package:** O  
**Date:** 2026-11-23

## 1. Purpose and governing principles

This specification defines how inspection photos, uploaded attendance/BA files, generated PDFs, and derived previews are classified, accessed, retained, recovered, and eventually disposed of.

This is a proposed technical control baseline, not a legal determination. The institution/project sponsor must confirm the applicable Indonesian public-sector records, privacy, procurement, archival, and data-residency requirements with its authorized legal/records officers.

Principles:
- Evidence is private by default.
- Collect only data needed for the approved inspection and reporting purpose.
- Keep original evidence and generated official documents distinguishable from previews/derivatives.
- Never overwrite finalized evidence or historical approved documents.
- Deletion is a controlled, authorized, auditable lifecycle event, not a normal user action.
- A backup is not a substitute for a retention schedule, legal hold, or tested restore.
- Cost optimization cannot silently shorten an institutionally required retention period.

## 2. Data and evidence classification proposal

| Class | Examples | Access baseline | Handling |
|---|---|---|---|
| Operational public/internal metadata | Instrument code, non-sensitive status labels, aggregate counts | Authenticated scoped users | Avoid exposing cross-project operational details |
| Personal data | Full name, NIP, rank, institution, account identity, attendance | Minimum role/scope required | Do not place in object keys, URLs, analytics, or general logs |
| Inspection evidence | Serial-number photos, device photos, physical condition photos | Assigned Inspector during draft; assigned Reviewer and specifically authorized operational roles after submission | Private bucket, checksum, immutable finalized object |
| Official records | Approved inspection PDFs, BA, signed attendance records | Explicit project/session document permissions | Versioned, immutable, retention-controlled |
| Security/audit data | Account decisions, role changes, access/security events | Restricted audit permission | Append-only, protected from ordinary mutation |
| Secrets and credentials | Supabase keys, OAuth secrets, signed URL tokens | Server secret store only | Never persist in client, logs, or evidence metadata |

The institution must confirm the formal classification labels and any restrictions for personal data, state assets, procurement evidence, or official records.

## 3. Collection and minimization

- Collect only the configured photo slots and fields required by the published instrument version.
- Do not request location/GPS metadata unless a separately approved requirement exists.
- Do not place personal names, NIP, serials, or descriptive sensitive content in object paths.
- Strip EXIF/GPS from display derivatives by default. Whether original EXIF must be preserved as evidence is an open institutional decision.
- Keep original upload bytes separate from generated thumbnails and transformed previews.
- Do not use inspection images for model training, marketing, public galleries, or unrelated analytics.
- Do not expose signed URLs in support tickets, logs, chat, or screenshots.

## 4. Access and disclosure controls

- Use private Supabase Storage buckets only.
- Authorize every download against current user, active account, permission, project/session/assignment, inspection, revision, and evidence relationship.
- Signed URLs are short-lived, object-specific, and created only after authorization; exact TTL is an implementation parameter requiring security review.
- Re-check access when generating a new URL; an earlier URL is not proof of continuing authorization.
- Support access revocation by disabling the account/grant and preventing new signed URLs.
- Access to bulk export, BA, attendance, and audit logs requires explicit permission.
- Record security-relevant access/export events according to the approved audit policy. Do not log URL tokens or image bytes.
- External sharing or delivery to third parties requires an approved delivery channel and recipient authorization.

## 5. Retention schedule — approval required

No final retention duration is asserted in this draft. The following schedule is a decision template; the Product Owner/project sponsor must supply the authoritative period and trigger for each class before production data is collected.

| Record class | Retention trigger | Proposed disposition | Required approval |
|---|---|---|---|
| Pending/abandoned upload | Upload intent creation or last activity | Quarantine, reconcile, then delete only after approved grace period and confirmation no inspection references it | Project Sponsor + records/privacy owner |
| Draft inspection evidence | Draft abandonment, session closure, or project end | Retain while draft/review/correction remains active; then follow approved project record schedule | Product Owner |
| Submitted/approved evidence | Approval or project close | Retain with the official inspection record for approved statutory/institutional period | Records/legal owner |
| Generated inspection PDF | Final generation / approval | Retain immutable output and source/template hashes for official record period | Records/legal owner |
| BA and attendance documents | Issuance/verification | Retain according to official project record schedule | Records/legal owner |
| Audit/security events | Event timestamp | Retain according to approved security and public-record requirements | Security + records owner |
| Temporary derivatives/previews | Derivative creation | Delete/rebuild according to operational need, without deleting original evidence | Engineering |
| Backups | Backup creation | Retain under approved backup rotation; expire only per documented policy and legal hold | Project Sponsor + engineering |

Before go-live, record an exact duration, time trigger, record owner, legal basis, archive destination (if any), deletion method, and exception/hold process for every class. If policy requires a period after project closure, the project close timestamp must be immutable and recorded.

## 6. Legal hold and preservation

- A legal/institutional hold prevents deletion or lifecycle expiry of covered records.
- Hold creation/release requires a designated authorized role, documented authority, reason, scope, timestamp, and audit event.
- Holds apply to primary objects and all backup generations that can be located under the approved recovery policy.
- Deletion jobs must check hold state immediately before deletion.
- A hold must not silently modify the original evidence or its checksum.
- Exact legal-hold authority, notification, and retention behavior require institutional approval.

## 7. Deletion and disposal workflow

Deletion must be a controlled workflow:
1. Identify candidate record and its retention class.
2. Verify retention expiry and applicable legal hold.
3. Verify no open inspection, appeal, review, correction, audit, or official-record dependency.
4. Obtain required approval (two-person approval is recommended for official records).
5. Create a deletion request with scope, reason, authority, and expected affected objects.
6. Execute object and metadata lifecycle steps in a recoverable order.
7. Verify primary object deletion and record provider result.
8. Record an immutable deletion event/tombstone with object reference, checksum, actor, approver, reason, timestamp, and result; do not retain unnecessary personal content in the tombstone.
9. Allow backup copies to expire only through the documented backup rotation; do not claim immediate physical erasure from immutable backups.
10. Produce a deletion report for authorized audit.

Hard DELETE from normal application roles is prohibited. If a record is legally required to be preserved, use a hold or archive state rather than deletion. If correction is needed, create a new version.

## 8. Upload and evidence integrity

- Accept only configured image/document MIME types after verifying actual file signature.
- Enforce approved byte-size and per-inspection quotas server-side; exact numeric caps remain open pending source legibility and provider quota validation.
- Calculate SHA-256 or an approved cryptographic checksum after upload confirmation.
- Record byte size, detected MIME type, checksum, object key, uploader, server receipt time, instrument version, evidence slot, inspection, and exact revision/draft.
- Finalized original object identity is immutable. Re-upload creates a new asset linked to the correction/revision and reason.
- Quarantine malformed, unsupported, checksum-mismatched, or suspicious objects; do not expose them as verified evidence.
- Malware scanning is a separate capability decision. Do not claim malware-free status unless a scanner is actually deployed and its result is recorded.
- Submission is blocked if a mandatory slot lacks a verified object attached to the exact revision.

## 9. Recovery and incident handling

- Evidence recovery requires both database metadata recovery and object recovery.
- Maintain object inventory/checksum reconciliation to detect missing or orphaned objects.
- Restore into an isolated environment first; validate object key, checksum, revision relationship, access policy, and legal holds before returning to service.
- Record missing/corrupt evidence as an incident; do not silently substitute a thumbnail or a different revision.
- Recovery must preserve immutable audit history and avoid resurrecting objects already legitimately deleted after a hold-free retention expiry.
- Exact restore priority, RPO/RTO, backup retention, and point-in-time recovery capability are specified in Package P.

## 10. Open institutional decisions

1. Formal data classification and personal-data/official-record categories.
2. Applicable legal basis and authorized processing purpose.
3. Exact retention periods and triggers for all record classes.
4. Records custodian and legal-hold authority.
5. Whether original EXIF/GPS metadata must be retained.
6. Required photo resolution/quality and accepted formats.
7. Maximum per-file, per-inspection, and per-project storage quotas.
8. Whether malware scanning is required and who funds/operates it.
9. Whether archives or delivery copies must be transferred to an institutional repository.
10. Whether third-party report recipients can receive direct files or must use an institutional channel.

## 11. Release gates

Production is blocked until:
- institutional privacy and records authority approves classification, legal basis, retention, deletion, and hold policy;
- file limits and accepted formats are validated against official evidence requirements;
- private Storage policies and signed URL behavior pass positive/negative access tests;
- evidence recovery is proven together with database restore;
- deletion and hold workflows are tested without destroying historical records;
- monitoring alerts on missing objects, checksum mismatches, quota thresholds, and failed cleanup.

**Policy status:** DRAFT — NOT INSTITUTIONALLY APPROVED.  
**Deletion workflow:** NOT IMPLEMENTED.  
**Retention periods:** NOT SET.  
**Production evidence collection authorization:** NOT GRANTED.
