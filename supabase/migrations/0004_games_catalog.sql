-- Unified catalog: one row per "loggable thing" regardless of upstream source
-- (IGDB for video games, BoardGameGeek for tabletop games). Kind-specific facts
-- live in narrow side tables so the core table stays lean for search/browse.
create table games (
  id uuid primary key default gen_random_uuid(),
  kind game_kind not null,
  canonical_name text not null,
  slug text unique not null,
  summary text,
  release_date date,
  cover_image_url text,
  igdb_id bigint unique,
  bgg_id integer unique,
  search_tsv tsvector,
  popularity_score numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint games_source_check check (
    (kind = 'video_game' and igdb_id is not null) or
    (kind = 'tabletop_game' and bgg_id is not null)
  )
);

create or replace function games_search_tsv_update()
returns trigger
language plpgsql
as $$
begin
  new.search_tsv :=
    setweight(to_tsvector('simple', coalesce(new.canonical_name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.summary, '')), 'C');
  return new;
end;
$$;

create trigger games_search_tsv_trigger
  before insert or update on games
  for each row execute function games_search_tsv_update();

create trigger games_set_updated_at
  before update on games
  for each row execute function set_updated_at();

create index games_search_tsv_idx on games using gin (search_tsv);
create index games_name_trgm_idx on games using gin (canonical_name gin_trgm_ops);
create index games_kind_idx on games (kind);
create index games_popularity_idx on games (popularity_score desc nulls last);

create table video_game_details (
  game_id uuid primary key references games(id) on delete cascade,
  igdb_slug text,
  franchise text,
  game_modes text[],
  esrb_rating text,
  metacritic_score int
);

create table tabletop_game_details (
  game_id uuid primary key references games(id) on delete cascade,
  bgg_type text,
  min_players int,
  max_players int,
  min_playtime_minutes int,
  max_playtime_minutes int,
  min_age int,
  bgg_rank int,
  bgg_average_rating numeric
);

create table game_platforms (
  game_id uuid references games(id) on delete cascade,
  platform_id smallint references platforms(id),
  igdb_release_id bigint,
  primary key (game_id, platform_id)
);

create table game_genres (
  game_id uuid references games(id) on delete cascade,
  genre_id smallint references genres(id),
  primary key (game_id, genre_id)
);

create index game_platforms_platform_idx on game_platforms (platform_id);
create index game_genres_genre_idx on game_genres (genre_id);
