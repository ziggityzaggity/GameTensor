create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text,
  profile_visibility profile_visibility not null default 'public',
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_username_idx on profiles (username);

-- Auto-create a stub profile row whenever a new auth user signs up.
-- Username defaults to the local part of the email plus a short random suffix
-- to avoid collisions; the user can change it during onboarding.
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
  candidate_username := base_username || '_' || substr(replace(new.id::text, '-', ''), 1, 6);

  insert into public.profiles (id, username, display_name)
  values (new.id, candidate_username, base_username)
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();
