-- Bug: handle_new_user() (0003) builds the auto username as
-- <email-local-part> || '_' || <6 hex>, but 0010 added a format constraint
-- capping usernames at 30 chars (^[a-z0-9_]{3,30}$). An email whose local part
-- exceeds 23 chars produced a >30-char username, so the profile insert in the
-- trigger violated the constraint and the whole signup transaction rolled back —
-- i.e. users with long email local parts could not sign up at all.
--
-- Fix: cap the base part to 23 chars so base + '_' + 6 = 30 max. Everything else
-- (lowercasing, stripping to [a-z0-9_], the 'player' fallback) is unchanged.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_username text;
  candidate_username text;
begin
  base_username := lower(regexp_replace(split_part(new.email, '@', 1), '[^a-zA-Z0-9_]', '', 'g'));
  if base_username is null or base_username = '' then
    base_username := 'player';
  end if;
  -- Keep base + '_' + 6 hex within the 30-char username limit (0010 constraint).
  base_username := left(base_username, 23);
  candidate_username := base_username || '_' || substr(replace(new.id::text, '-', ''), 1, 6);

  insert into public.profiles (id, username, display_name)
  values (new.id, candidate_username, base_username)
  on conflict (id) do nothing;

  return new;
end;
$$;
