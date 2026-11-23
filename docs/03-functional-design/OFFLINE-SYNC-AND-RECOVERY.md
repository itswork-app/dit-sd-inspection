# Offline, Synchronization, Conflict, and Recovery Design

**Status:** Draft v0.1.1 — T-09 scope approved by Product Owner; device/local-data controls remain pending  
**Package:** C — Functional and Operational Design

## 1. Design objective

Support field inspection in unreliable connectivity without losing draft data or creating silent overwrites, duplicate submissions, or ambiguous evidence ownership. Offline behavior is not permission to bypass authorization or server-side validation.

## 2. Approved T-09 offline boundary

The initial offline-capable workflow should be limited to an already authenticated and explicitly assigned Inspector working on a unit that has been claimed while online. The client may retain the minimum required session/assignment metadata, instrument configuration version, checklist definition, draft answers, and pending media needed to continue that inspection.

New claims, role changes, assignment changes, approvals, session administration, and other privileged actions require connectivity unless a separately approved design explicitly permits them.

**PO decision:** T-09 option B was explicitly approved on 2026-11-23. The scope choice is APPROVED; implementation and production activation remain gated. This is the approved product boundary for the initial release. It does not authorize production activation until device/browser support, local-data protection, retention/purge, shared-device logout and recovery controls are approved.

## 3. Local persistence

- Persist drafts and queued evidence in durable browser storage suitable for the supported PWA browsers.
- Use a local transactional data model; avoid treating volatile in-memory state as saved work.
- Store local operation identifiers and idempotency keys.
- Track each item as local-only, queued, syncing, synchronized, or conflict.
- Protect sensitive cached data; define logout, device-sharing, and local-data cleanup behavior before production.
- Do not store Google access tokens or service-role credentials in application-managed local storage.

## 4. Synchronization protocol

1. Client records an operation with a unique operation ID and local sequence.
2. Client queues metadata and media separately but links them to the same inspection revision.
3. On reconnect, client submits operations in dependency order.
4. Server authenticates user and re-evaluates current role, assignment scope, claim ownership, and state.
5. Server processes idempotently; retries with the same operation ID return the original result.
6. Server acknowledges accepted operations and returns authoritative version/state.
7. Client marks only acknowledged operations as synchronized.

Media upload must be resumable/retryable where supported. A successful metadata save must not falsely imply that all required media has been uploaded.

## 5. Conflict policy

No last-write-wins for inspection answers, approvals, configuration, or evidence metadata.

- If server version is unchanged, accept the operation.
- If server version has advanced, reject conflicting writes with a structured conflict response.
- Preserve both local pending data and server state until a user with appropriate authority resolves the conflict.
- Never silently replace a newer server revision.
- A changed instrument/checklist configuration does not rewrite the configuration version already bound to an active inspection.
- A claim that expired or was revoked while client was offline requires controlled reconciliation before submission.

## 6. Recovery behavior

- Refresh/browser restart must restore the locally persisted draft.
- Connectivity loss must show a clear unsynchronized indicator.
- Failed upload must retain the original media and retry state.
- User must be able to see which answers/media are not yet synchronized.
- Logout on a shared device must warn about pending local work and follow a defined secure retention policy.
- If local storage is unavailable or near quota, block new evidence capture with a clear warning rather than pretending data is saved.

## 7. Security

- RLS and backend authorization apply to all synchronized operations.
- Client-side cache is untrusted input.
- Validate file type, file size, content signature, ownership, and association on server.
- Use private Storage buckets and short-lived authorized access for media retrieval.
- Define device/session revocation behavior.
- Do not expose service-role keys in browser code.

## 8. Observability

Record sync attempts, operation IDs, result status, retry count, conflict type, media upload state, and timestamps. Avoid logging image contents, tokens, or unnecessary personal data.

## 9. Acceptance criteria

- Draft survives refresh and browser restart within supported browser constraints.
- Network retries do not duplicate writes or submissions.
- Pending media remains available after upload failure.
- Stale writes are rejected and surfaced as conflicts.
- Server authorization is rechecked during sync.
- No user can submit an inspection with required media still unsynchronized.
- Offline state is visibly distinguishable from server-confirmed saved state.

## 10. Remaining implementation and governance decisions

- Supported browsers/devices and minimum storage capability.
- Maximum photo size, image count, compression, and total local queue size.
- Whether offline continuation after claim expiry is allowed and under what recovery process.
- Cache encryption and shared-device logout policy.
- Exact local cache encryption/protection and supported browser/device controls.
- Institutional approval of retention, purge and legal-hold rules (T-10).
- Whether offline continuation after claim expiry is allowed; until decided, require controlled online reconciliation before submit.
- Whether the pilot can require online claim acquisition and online submission.
