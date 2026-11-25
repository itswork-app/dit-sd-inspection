# Security Threat Model — Dit. SD Inspection

Status: Initial threat model — security review required  
Version: 0.1.0

## 1. Assets to protect

- Google identity and application accounts.
- Project, session, location, team, assignment, and target data.
- Serial numbers and inspection results.
- Original photo/video evidence and generated PDFs.
- Wet-signature scans, attendance, and BA documents.
- Role/permission/scope configuration.
- Audit events and operational credentials.

## 2. Trust boundaries

1. Mobile/desktop browser and local offline storage.
2. Vercel-hosted application and server operations.
3. Supabase Auth.
4. PostgreSQL/RLS and privileged database functions.
5. Private Storage and signed URL access.
6. GitHub source, CI, deployment secrets, and preview environments.

## 3. Threats and required controls

| Threat | Example | Required controls |
|---|---|---|
| Account takeover | Stolen Google session | Provider MFA where available, session revocation, least privilege, account suspension |
| Unauthorized approval | Inspector calls reviewer endpoint | Server-side permission and separation-of-duties checks; RLS and negative tests |
| IDOR/cross-location access | Change inspection UUID in request | Resource-scope authorization on every read/write; private storage policy |
| Privilege escalation | User changes role in browser payload | Derive grants from trusted database state; deny client-controlled role/scope |
| Duplicate claim race | Two Inspectors claim same serial | Unique constraints/transactional lock/idempotency |
| Evidence substitution | Replace photo after approval | Immutable object identity/checksum; revisions append new evidence |
| Signed URL leakage | URL copied/shared | Short TTL, no token logging, private buckets, narrow object scope |
| Offline device loss | Phone lost with unsynced evidence | Minimize local data, device/browser storage policy, encryption feasibility review, remote account revocation |
| Sync replay/duplication | Retry creates duplicate inspection | Idempotency keys, request hashes, monotonic resource versions |
| Malicious upload | Executable renamed as image | File signature validation, strict allowlist, size caps, optional malware scanning |
| Data exfiltration | Bulk export by compromised account | Least privilege, export authorization, audit, rate limits, monitoring |
| CI/deployment compromise | Secret exposed in preview build | Environment-scoped secrets, protected branches, least-privilege tokens, secret scanning |
| Resource exhaustion | 100 users upload many large images | Quotas, rate limiting, upload limits, load testing, usage alerts |

## 4. Security requirements

- Deny by default at application and database layers.
- RLS enabled on every exposed table.
- No service-role key in client bundles, logs, or public repositories.
- Private evidence buckets; no public listing.
- Validate all inputs and enforce file type/size server-side.
- Use HTTPS; secure cookie/session configuration according to framework/provider guidance.
- Do not log passwords, tokens, signed URLs, or raw evidence.
- Append-only audit for security-relevant actions; audit scope and retention require approval.
- Restrict preview deployments from production data and credentials.
- Revoke access promptly when user or assignment is suspended.

## 5. Abuse and operational monitoring

Monitor authentication failures, permission denials, unusual exports, repeated claim conflicts, upload failures, sync failures, rate-limit events, database saturation, storage growth, and provider quota thresholds. Alert thresholds and notification channels are to be set during operations design.

## 6. Security verification plan

- Threat-model review before implementation.
- RLS tests for each role and negative scope.
- IDOR and direct API tests.
- Capacity/claim concurrency tests.
- Evidence object access and signed URL expiry tests.
- Upload validation tests.
- Dependency and secret scanning in CI.
- Restore/recovery test and incident tabletop.
- Independent security review before production if risk/organizational policy requires it.

## 7. Open decisions

- Data classification, privacy owner, legal basis, retention and deletion.
- Local offline encryption and supported device baseline.
- MFA/session policy and institutional identity requirements.
- Malware scanning feasibility.
- Security incident owner and response SLA.
