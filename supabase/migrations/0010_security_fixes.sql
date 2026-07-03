-- Security fixes for confirmed issues in migrations 0005-0009 (see
-- docs/demo-completion-plan.md section 3.1). Also adds the fixed-window
-- rate-limit table used by the search Edge Functions.

-- 1. friend_edges leaked the whole friendship graph: created without
-- security_invoker (0007), it ran as its owner (postgres) and bypassed
-- friendships RLS, then 0009 granted SELECT on all views to anon.
-- security_invoker makes the underlying friendships RLS apply per caller, and
-- revoking anon closes the unauthenticated read. can_view_profile() is
-- unaffected: it is SECURITY DEFINER (owned by postgres) so it still reads the
-- base table without RLS.
alter view friend_edges set (security_invoker = on);
revoke select on friend_edges from anon;

-- 2. friendships_update let the requester self-accept (using clause matched
-- either party). Restrict updates to the addressee (accept/decline/block);
-- requesters cancel via the existing delete policy.
drop policy friendships_update on friendships;
create policy friendships_update on friendships
  for update using (addressee_id = auth.uid()) with check (addressee_id = auth.uid());

-- Only pending requests may transition, and only to a terminal state. Blocks
-- re-opening (accepted -> pending) or lateral moves. Service-role writes bypass
-- RLS but not triggers, so guard on a status change from a non-pending row.
create or replace function enforce_friendship_transition()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    if old.status <> 'pending' then
      raise exception 'friendship status % is terminal and cannot change', old.status;
    end if;
    if new.status not in ('accepted', 'declined', 'blocked') then
      raise exception 'illegal friendship transition pending -> %', new.status;
    end if;
  end if;
  return new;
end;
$$;

create trigger friendships_enforce_transition
  before update on friendships
  for each row execute function enforce_friendship_transition();

-- Reverse-direction duplicate guard: the (requester_id, addressee_id) unique
-- constraint in 0007 does not stop B requesting A after A requested B. Order the
-- pair so either direction collides.
create unique index friendships_pair_uniq
  on friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));

-- 3. hours_source could be spoofed to 'xbox_sync' by any writer. Client writes
-- carry an auth.uid(); service-role Edge Function sync calls do not. Force
-- 'manual' for authenticated writers and leave service-role writes untouched.
create or replace function enforce_manual_hours_source()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null then
    new.hours_source := 'manual';
  end if;
  return new;
end;
$$;

create trigger user_game_logs_enforce_hours_source
  before insert or update on user_game_logs
  for each row execute function enforce_manual_hours_source();

-- 4. Length bounds on user-supplied text to cap storage abuse / UI DoS.
alter table reviews add constraint reviews_body_len check (char_length(body) <= 10000);
alter table custom_lists add constraint custom_lists_title_len check (char_length(title) <= 120);
alter table custom_lists add constraint custom_lists_description_len check (char_length(description) <= 2000);
alter table list_items add constraint list_items_note_len check (char_length(note) <= 500);
alter table profiles add constraint profiles_bio_len check (char_length(bio) <= 500);
alter table profiles add constraint profiles_display_name_len check (char_length(display_name) <= 50);
-- Guard against absurd/negative hour counts; null (unlogged) stays allowed.
alter table user_game_logs add constraint user_game_logs_hours_range
  check (hours_played is null or (hours_played >= 0 and hours_played <= 100000));

-- 5. Username format. The 0003 trigger already emits lowercase alnum/underscore
-- names; this bounds user-chosen names once profile editing ships.
alter table profiles add constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,30}$');

-- 6. review_likes was world-readable (using true), leaking likes on
-- friends-only profiles. Gate reads on the liker's own visibility.
drop policy review_likes_select on review_likes;
create policy review_likes_select on review_likes
  for select using (can_view_profile(user_id));

-- 7. Fixed-window rate-limit counters, keyed per user + function + window.
-- Written only by Edge Functions via the service role; RLS enabled with no
-- policy denies all client access.
create table function_rate_limits (
  user_id uuid not null,
  function_name text not null,
  window_start timestamptz not null,
  count int not null default 1,
  primary key (user_id, function_name, window_start)
);

alter table function_rate_limits enable row level security;

-- Atomic bump for the current window: seeds count=1 or increments an existing
-- row in a single statement, returning the post-increment count. SECURITY
-- DEFINER so Edge Functions reach it through the service role, which is the only
-- caller (RLS grants no client access to the table). supabase-js upsert cannot
-- express count = count + 1, so this RPC provides the race-free path.
create or replace function increment_rate_limit(
  p_user_id uuid,
  p_function_name text,
  p_window_start timestamptz
)
returns int
language sql
security definer
set search_path = public
as $$
  insert into function_rate_limits (user_id, function_name, window_start, count)
  values (p_user_id, p_function_name, p_window_start, 1)
  on conflict (user_id, function_name, window_start)
    do update set count = function_rate_limits.count + 1
  returning count;
$$;

-- Only the service role invokes this. Postgres grants EXECUTE to PUBLIC by
-- default, so revoking from anon/authenticated alone leaves the PUBLIC grant
-- intact and the function callable — revoke from PUBLIC to actually close it.
-- (Without this, any authenticated user could inflate another user's rate-limit
-- counter via a direct RPC and lock them out of search.) Revoking PUBLIC also
-- strips service_role, so re-grant it explicitly — the Edge Functions call this
-- through the service role and rate limiting fails closed without it.
revoke execute on function increment_rate_limit(uuid, text, timestamptz) from public;
grant execute on function increment_rate_limit(uuid, text, timestamptz) to service_role;
