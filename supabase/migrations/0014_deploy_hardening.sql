-- Hardening surfaced by Supabase's security advisor on the hosted project
-- (issues that exist in every environment; the local workflow had no linter).

-- 1. Lookup tables never had RLS enabled, so the blanket authenticated
-- INSERT/UPDATE/DELETE grant from 0009 let any signed-in user WRITE reference
-- data. Enable RLS with public read + no write policy (matches the games/
-- details posture): reads stay open, writes fall to service_role only.
alter table completion_status enable row level security;
create policy completion_status_select_all on completion_status for select using (true);

alter table platforms enable row level security;
create policy platforms_select_all on platforms for select using (true);

alter table genres enable row level security;
create policy genres_select_all on genres for select using (true);

-- 2. SECURITY DEFINER function lockdown. Supabase grants EXECUTE on public
-- functions to anon/authenticated directly (for PostgREST RPC exposure), so the
-- earlier `revoke ... from public` alone left these callable by signed-in users:
-- a user could spam the expensive recompute_* jobs or inflate another user's
-- rate-limit counter. Revoke from the client roles explicitly. These are only
-- ever invoked by triggers (which run regardless of caller EXECUTE) or by Edge
-- Functions via the service role (whose grant is untouched).
revoke execute on function handle_new_user() from public, anon, authenticated;
revoke execute on function set_updated_at() from public, anon, authenticated;
revoke execute on function games_search_tsv_update() from public, anon, authenticated;
revoke execute on function enforce_friendship_transition() from public, anon, authenticated;
revoke execute on function enforce_manual_hours_source() from public, anon, authenticated;
revoke execute on function rescore_user_recommendations() from public, anon, authenticated;
revoke execute on function increment_rate_limit(uuid, text, timestamptz) from public, anon, authenticated;
revoke execute on function recompute_similarity() from public, anon, authenticated;
revoke execute on function recompute_user_recs(uuid) from public, anon, authenticated;
revoke execute on function recompute_recommendations() from public, anon, authenticated;
-- can_view_profile stays executable by anon/authenticated: it is called inside
-- RLS USING clauses, which require the querying role to hold EXECUTE. It only
-- returns a visibility boolean, so exposure is benign.

-- 3. Pin a stable search_path on the remaining functions the advisor flagged as
-- mutable (defence against search_path-based privilege tricks).
alter function set_updated_at() set search_path = public;
alter function games_search_tsv_update() set search_path = public;
alter function enforce_friendship_transition() set search_path = public;
alter function enforce_manual_hours_source() set search_path = public;
alter function match_games(vector, int) set search_path = public;

-- 4. The avatars bucket is public, so object URLs resolve without any SELECT
-- policy; the broad public-read policy on storage.objects only enabled LISTING
-- every file in the bucket. Drop it — display via public URL is unaffected.
drop policy avatars_public_read on storage.objects;
