create table custom_lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  visibility list_visibility not null default 'private',
  cover_image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index custom_lists_owner_idx on custom_lists (owner_id) where deleted_at is null;

create trigger custom_lists_set_updated_at
  before update on custom_lists
  for each row execute function set_updated_at();

create table list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references custom_lists(id) on delete cascade,
  game_id uuid not null references games(id) on delete cascade,
  position int not null,
  note text,
  added_at timestamptz not null default now(),
  unique (list_id, game_id)
);

create index list_items_list_idx on list_items (list_id, position);
