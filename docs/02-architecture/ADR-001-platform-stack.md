# ADR-001 — Platform Stack: Supabase + Vercel

- Status: Accepted
- Decision date: 2026-11-23
- Decision owner: Product Owner
- Engineering owner: CTO / Engineering Lead

## Context
The project is a production-targeted replacement for the Dit. SD inspection application. Engineering priority is cost-first. The solution must support relational inspection data, scoped authorization, evidence uploads, web/PWA delivery, and economical deployment.

## Decision
Use the following platform baseline:

1. **Supabase**
   - PostgreSQL is the sole primary database and source of truth.
   - Supabase Auth handles identity, including Google sign-in.
   - PostgreSQL Row Level Security (RLS) enforces data access boundaries.
   - Supabase Storage holds private inspection evidence and generated artifacts where appropriate.
   - Database migrations are version-controlled in the repository.
2. **Vercel**
   - Hosts and deploys the web application/PWA.
   - Provides Git-connected deployments and preview environments.
   - Frontend/server functions may be used where appropriate, but privileged database operations must remain server-authorized and must not expose service-role credentials.
3. **GitHub**
   - Source control, pull requests, review, and cost-conscious CI.

Supabase PostgreSQL remains the only primary database. Do not add Firebase or another database as a parallel source of truth.

## Security constraints
- Never expose Supabase service-role keys in browser code.
- Enforce authorization at the server and database layers; use RLS for user-scoped access.
- Keep evidence buckets private. Use short-lived signed URLs only after authorization.
- Validate Google identity and map it to an approved application user and assigned roles.
- Apply least privilege to database, storage, and deployment credentials.
- Preserve immutable evidence and inspection history.

## Cost strategy
- Begin development using suitable free tiers where practical.
- Before production, validate plan terms, quotas, inactivity behavior, backups, support, usage limits, and provider terms for the intended organizational use.
- Monitor database compute/size, storage, egress, authentication usage, Vercel compute/transfer, and GitHub Actions minutes.
- Upgrade only when measured production requirements or risk controls justify it.
- Do not compromise backup/recovery, privacy, authorization, or evidence integrity to remain on a free tier.

## Consequences
Positive:
- One managed relational backend reduces operational complexity.
- Supabase provides integrated database, authentication, RLS, and object storage.
- Vercel provides straightforward web deployment and preview workflows.
- No separate server fleet or second primary database is required initially.

Trade-offs:
- Production plan eligibility and cost must be verified; free tiers may have inactivity pauses, quota limits, or restrictions.
- Offline sync and conflict resolution remain application responsibilities.
- Backups, evidence retention, egress, and provider-specific limits require explicit operational design.
- Vendor dependency is accepted for the initial release; schema and application layers should remain portable where practical.

## Alternatives not selected
- Firebase as a second backend/database: rejected to avoid split source of truth.
- Self-managed server/database: rejected for initial release due to operational burden.
- Microservices: rejected absent a measured need.
