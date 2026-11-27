# Database migrations

This directory is the ordered, immutable SQL migration history for the local
development database.

## Naming and ordering

- Use the Supabase CLI timestamp format: `YYYYMMDDHHMMSS_short_snake_case_name.sql`.
- Timestamps must be valid UTC calendar/time values and unique.
- Never edit or rename a migration after it has been applied in a shared
  development environment; create a forward migration instead.
- Keep each migration focused, reviewable, and safe to apply from an empty
  local database.
- The repository validator checks names, timestamp uniqueness/order, and
  rejects empty SQL files. It does not prove SQL correctness or security.

## Admission boundary

No business schema, custom role, grant, RLS policy, privileged function,
trigger, seed data, or production migration is admitted by this foundation
scaffold. Add the first SQL migration only after the corresponding physical
schema, authorization, ownership, privilege, transaction/lock, and QA
contracts have been reviewed. A migration file is not approval evidence.

## Local-only workflow

After installing a reviewed Supabase CLI version and Docker:

```sh
supabase start
supabase status
supabase migration new descriptive_change_name
# Edit and review the generated SQL migration.
supabase db reset
supabase stop
```

Use only the local stack during this foundation stage. Do not run `supabase
link`, `supabase db push --remote`, `supabase db pull --remote`, or any
command that targets a hosted project. No project ref or database credential
belongs in this repository or chat.

The Supabase CLI version is not yet pinned. Pin and verify it before making
the migration workflow a CI requirement or applying migrations to any shared
environment.
