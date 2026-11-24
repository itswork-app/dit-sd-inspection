# Supabase Live Database Security Inventory Runbook

**Status:** Read-only audit runbook — repository-side preparation complete; live inventory NOT executed  
**Version:** 0.1.0 | **Date:** 2026-11-24

## 1. Scope and non-mutation guarantee

This runbook prepares a reproducible, least-disclosure snapshot of the actual Supabase PostgreSQL security posture before approving function execution design, RLS, grants or migrations.

Every SQL statement below is a catalog/introspection SELECT. Do not append DDL, DML, SET ROLE, GRANT, REVOKE, ALTER, CREATE, DROP, TRUNCATE, CALL or migration statements. Do not run against production unless the institutional/provider owner authorizes the audit window and confirms the audit identity is read-only.

Repository inspection did not find supabase/config.toml or supabase/migrations/README.md at the inspected branch paths. This is only a path-level observation, not proof that no migrations or Supabase configuration exist elsewhere. The physical schema and RLS documents describe a proposed design; they do not prove deployed database state.

**Live access:** No Supabase/PostgreSQL connector is available in this workspace. No live database was queried. Never paste database URLs, passwords, service-role keys, JWTs, API keys, private customer data or evidence contents into chat or an issue.

## 2. Safe collection procedure

1. Confirm project reference, environment (development/staging/production), region, audit owner and approval in the institution's approved channel. Record only a non-secret project label/reference.
2. Prefer a dedicated read-only database identity. If using SQL Editor, verify the signed-in operator and environment; do not assume SQL Editor is read-only.
3. Capture query text, UTC execution timestamp, environment label, row counts and results. Preserve raw catalog output in an access-controlled location.
4. Redact emails, personal names, JWT claims, secret values, connection strings and credential-bearing function definitions before sharing.
5. Do not export table data, Auth user records, Storage object contents or application evidence. This is a metadata-only audit.
6. If a query is denied, record the permission error; do not elevate privileges or switch to service_role to make it pass.

## 3. Database identity and extensions

~~~sql
select current_database() as database_name,
       current_user as executing_role,
       session_user as session_role,
       current_setting('server_version') as server_version,
       current_setting('server_version_num') as server_version_num,
       current_timestamp at time zone 'utc' as captured_at_utc;

select extname, extversion, n.nspname as extension_schema
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
order by extname;
~~~

Confirm this is the intended Supabase project/environment. Do not expose connection metadata beyond the approved project label.

## 4. Roles, attributes and memberships

~~~sql
select rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb,
       rolcanlogin, rolreplication, rolbypassrls, rolconnlimit
from pg_roles
order by rolname;

select parent.rolname as granted_role,
       member.rolname as member_role,
       grantor.rolname as grantor_role,
       m.admin_option
from pg_auth_members m
join pg_roles parent on parent.oid = m.roleid
join pg_roles member on member.oid = m.member
join pg_roles grantor on grantor.oid = m.grantor
order by parent.rolname, member.rolname;
~~~

Acceptance checks:
- Identify actual existence and attributes of anon, authenticated, service_role, migration/owner roles and any proposed dedicated function owner.
- Flag browser-reachable roles with SUPERUSER, CREATEROLE, BYPASSRLS or unexpected inherited memberships.
- A candidate SECURITY DEFINER owner must be NOLOGIN, least-privileged, not SUPERUSER/BYPASSRLS and must not inherit table-owner privileges. Verify table ownership separately.

## 5. Schemas and schema-level privileges

~~~sql
select n.nspname as schema_name,
       pg_get_userbyid(n.nspowner) as owner,
       n.nspacl as acl
from pg_namespace n
where n.nspname not like 'pg_%'
  and n.nspname <> 'information_schema'
order by n.nspname;

select n.nspname as schema_name,
       coalesce(r.rolname, 'PUBLIC') as grantee,
       a.privilege_type,
       a.is_grantable
from pg_namespace n
cross join lateral aclexplode(coalesce(n.nspacl, acldefault('n', n.nspowner))) a
left join pg_roles r on r.oid = a.grantee
where n.nspname not like 'pg_%'
  and n.nspname <> 'information_schema'
order by n.nspname, grantee, a.privilege_type;
~~~

The ACL expansion above reports explicit/default schema privileges, including PUBLIC grants. Identify schemas exposed through Supabase/PostgREST Dashboard configuration; exposure is not reliably inferred from catalog grants alone.

## 6. Tables, ownership, ACL, RLS and policies

~~~sql
select n.nspname as schema_name, c.relname as object_name,
       c.relkind, pg_get_userbyid(c.relowner) as owner,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls,
       c.relacl as acl
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r','p','v','m','f')
  and n.nspname not like 'pg_%'
  and n.nspname <> 'information_schema'
order by n.nspname, c.relname;

select schemaname, tablename, policyname, permissive,
       roles, cmd, qual, with_check
from pg_policies
order by schemaname, tablename, policyname;

select grantee, table_schema, table_name, privilege_type, is_grantable
from information_schema.role_table_grants
where table_schema not in ('pg_catalog','information_schema')
order by table_schema, table_name, grantee, privilege_type;
~~~

Acceptance checks:
- Reconcile actual inventory against the proposed 41-table catalogue and explicitly account for print_batches, notification_events, retention/legal-hold, security-case and provider/release domains.
- For every protected table, anon and authenticated must not have direct INSERT/UPDATE/DELETE privileges under T-18. Inspect inherited grants as well as direct ACLs.
- RLS must be enabled on exposed application tables; FORCE RLS and owner/BYPASSRLS behavior require explicit review. Policies must be deny-by-default and scoped by approved actor/project/session/assignment rules.
- A policy permitting a command does not replace table ACL denial for direct browser DML. RLS alone is not proof of the T-18 boundary.

## 7. Functions, ownership, security mode, configuration and EXECUTE ACL

~~~sql
select n.nspname as schema_name,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as identity_arguments,
       pg_get_function_result(p.oid) as result_type,
       pg_get_userbyid(p.proowner) as owner,
       l.lanname as language,
       p.prosecdef as security_definer,
       p.provolatile as volatility,
       p.proparallel as parallel_safety,
       p.proconfig as function_settings,
       p.proacl as execute_acl,
       md5(pg_get_functiondef(p.oid)) as definition_md5
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_language l on l.oid = p.prolang
where n.nspname not in ('pg_catalog','information_schema')
order by n.nspname, p.proname, identity_arguments;

select grantee, routine_schema, routine_name,
       specific_name, privilege_type, is_grantable
from information_schema.routine_privileges
where routine_schema not in ('pg_catalog','information_schema')
order by routine_schema, routine_name, specific_name, grantee;
~~~

Acceptance checks:
- Inventory every overload by identity arguments; never approve grants by function name alone.
- Flag application functions executable by PUBLIC or anon; identify broad schema/default grants and inherited EXECUTE.
- For SECURITY DEFINER, inspect owner attributes/memberships, ownership of protected tables, pinned search_path, schema-qualified references, dynamic SQL, caller-JWT handling and authorization checks. A definition hash is a comparison aid, not a security verdict.
- Identify functions exposed through PostgREST schemas and route-to-function mapping outside the database.
- Match exact signatures to command contracts; a function name resembling CMD-001..048 is not approval.

## 8. Default privileges, sequences, views and triggers

~~~sql
select d.defaclrole::regrole as grantor_role,
       n.nspname as schema_name,
       d.defaclobjtype as object_type,
       d.defaclacl as default_acl
from pg_default_acl d
left join pg_namespace n on n.oid = d.defaclnamespace
order by grantor_role::text, schema_name, object_type;

select n.nspname as schema_name, c.relname as sequence_name,
       pg_get_userbyid(c.relowner) as owner, c.relacl as acl
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind = 'S'
  and n.nspname not in ('pg_catalog','information_schema')
order by n.nspname, c.relname;

select schemaname, viewname, viewowner, definition
from pg_views
where schemaname not in ('pg_catalog','information_schema')
order by schemaname, viewname;

select event_object_schema, event_object_table, trigger_name,
       action_timing, event_manipulation, action_orientation,
       action_statement
from information_schema.triggers
where event_object_schema not in ('pg_catalog','information_schema')
order by event_object_schema, event_object_table, trigger_name;
~~~

Acceptance checks:
- Default privileges must not silently reintroduce PUBLIC or broad application-role EXECUTE/DML grants.
- Review sequence privileges separately; table DML denial does not automatically imply sequence access is safe.
- Review view ownership/security-invoker behavior and trigger function targets. A view or trigger must not become an unintended privilege bypass.

## 9. Storage metadata and policy inventory

~~~sql
select schemaname, tablename, policyname, permissive,
       roles, cmd, qual, with_check
from pg_policies
where schemaname = 'storage'
order by tablename, policyname;

select table_schema, table_name, column_name, data_type
from information_schema.columns
where table_schema = 'storage'
  and table_name in ('buckets','objects')
order by table_name, ordinal_position;
~~~

Do not select object names, paths, metadata values or contents. Reconcile bucket privacy, upload/download/delete policies, signed URL issuance, size/MIME restrictions and ownership checks with the approved evidence policy. T-10 institutional retention/privacy requirements remain blocked; do not infer numeric limits.

## 10. Supabase Dashboard checks outside SQL

Capture evidence only through approved access controls:
- Project environment/reference and region.
- API settings: exposed schemas and PostgREST configuration.
- Auth settings relevant to JWT issuer/audience, session lifetime and enabled providers; do not export secrets.
- Edge Functions/Vercel deployment inventory and environment-variable names only, never values.
- Storage buckets: bucket names, public/private setting and configured file-size/MIME limits.
- Backup/PITR availability, retention and restore capability; record plan/region and a restore-test reference, not credentials.
- Network restrictions, connection pooler mode and database connection policy.
- Billing/quotas/ownership and named operational recovery owners (T-12).

Dashboard checks are not substitutes for SQL catalog evidence.

## 11. Evidence package and decision gates

Create an access-controlled audit bundle containing environment label, non-secret project reference, reviewer/approval reference, UTC capture time, query outputs for sections 3–9, Dashboard evidence, row counts/permission errors, and object-by-object reconciliation against the physical schema, RLS catalogue, 48 logical command contracts and 63 planned function-security tests.

Redact personal data and secrets before review. Preserve hashes and timestamps where useful. Never edit raw evidence after capture; record redaction as a separate derived copy.

The inventory is acceptable only when:
1. Actual environment identity and database version are verified.
2. Roles, memberships, ownership, schema/table/routine/sequence ACLs and default ACLs are inventoried.
3. Every exposed application table has reviewed RLS status/policies and no unauthorized browser direct DML.
4. Every application function has exact signature, owner, security mode, configuration, exposure and EXECUTE ACL reviewed; PUBLIC/anon and inherited grants are resolved.
5. SECURITY DEFINER owners satisfy least privilege and cannot bypass intended RLS/ownership controls.
6. Views, triggers, sequences, Storage policies and API-exposed schemas have no unreviewed bypass.
7. Actual deployed objects are reconciled against the 41-table proposal and known missing ERD/registry domains.
8. T-18 INVOKER/DEFINER/executor conflict has explicit PO/security resolution; this runbook cannot make that decision.
9. T-10 institutional records/privacy decisions and T-12 provider/backup/ownership evidence are closed before production activation.
10. Every discrepancy has an owner and closure evidence. Completion of this audit alone does not authorize a migration.

## 12. Current status

- Repository-side path check: supabase/config.toml and supabase/migrations/README.md not found at inspected branch paths.
- Repository design docs: proposed 41-table inventory, 48 logical commands and 63 planned function-security tests; not deployed-state evidence.
- Live Supabase inventory: NOT EXECUTED — no database connector/session available.
- SQL mutations, grants/revokes, RLS changes, migrations and runtime tests: NOT EXECUTED.
- T-18 execution-model resolution: OPEN.
- Scope freeze: NOT READY. Implementation: NOT AUTHORIZED.
