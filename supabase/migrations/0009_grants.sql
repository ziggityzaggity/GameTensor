-- Table-level privileges for the Supabase roles. RLS (enabled in earlier
-- migrations) gates *rows*, but Postgres still requires a table-level GRANT
-- before RLS is even consulted. Newer Supabase CLI defaults do not grant DML
-- to anon/authenticated/service_role automatically, so we grant explicitly and
-- let the existing RLS policies do the row-level enforcement.
grant usage on schema public to anon, authenticated, service_role;

-- anon: read-only (RLS still restricts which rows, e.g. public profiles only).
grant select on all tables in schema public to anon;

-- authenticated: full DML; RLS policies restrict to own/visible rows. Tables
-- with RLS enabled and no matching policy (e.g. service_tokens) remain denied.
grant select, insert, update, delete on all tables in schema public to authenticated;

-- service_role bypasses RLS (used by Edge Functions) but still needs grants.
grant all on all tables in schema public to service_role;

-- Apply the same defaults to tables created by future migrations.
alter default privileges in schema public grant select on tables to anon;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant all on tables to service_role;
