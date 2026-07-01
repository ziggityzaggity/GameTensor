create table user_game_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  game_id uuid not null references games(id) on delete cascade,
  completion_status_id smallint not null references completion_status(id),
  liked boolean,
  hours_played numeric,
  hours_source text not null default 'manual' check (hours_source in ('manual', 'xbox_sync')),
  last_played_at timestamptz,
  started_at date,
  finished_at date,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, game_id)
);

create index user_game_logs_user_idx on user_game_logs (user_id);
create index user_game_logs_game_idx on user_game_logs (game_id);

create trigger user_game_logs_set_updated_at
  before update on user_game_logs
  for each row execute function set_updated_at();

create table reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  game_id uuid not null references games(id) on delete cascade,
  body text not null,
  rating numeric check (rating >= 0 and rating <= 10),
  contains_spoilers boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, game_id)
);

create index reviews_game_idx on reviews (game_id) where deleted_at is null;
create index reviews_user_idx on reviews (user_id) where deleted_at is null;

create trigger reviews_set_updated_at
  before update on reviews
  for each row execute function set_updated_at();

create table review_likes (
  review_id uuid references reviews(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_id, user_id)
);
