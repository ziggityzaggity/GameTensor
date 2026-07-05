-- ===========================================================================
-- GAME SEARCH logic. Mirrors the exact query shapes GamesRepository.searchLocal
-- issues (app/lib/data/repositories/games_repository.dart): websearch FTS over
-- the generated search_tsv, and genre / platform / player-overlap filters via
-- inner joins on the same relations the PostgREST embeds target. Asserting them
-- in SQL guards the DB contract the client depends on. Runs against seed data.
-- ===========================================================================
begin;
create extension if not exists pgtap;
select plan(12);

-- --- full-text search (config 'simple', websearch_to_tsquery) --------------
-- A plain name query finds the game.
select set_eq(
  $$ select canonical_name from games
     where search_tsv @@ websearch_to_tsquery('simple', 'elden') $$,
  array['Elden Ring'],
  'fts: a plain name query matches the game by name'
);

-- websearch OR syntax returns both matches and never raises a syntax error
-- (this is why the repo uses websearch_to_tsquery over plainto/to_tsquery).
select set_eq(
  $$ select canonical_name from games
     where search_tsv @@ websearch_to_tsquery('simple', 'catan OR zelda') $$,
  array['Catan', 'The Legend of Zelda: Breath of the Wild'],
  'fts: websearch OR returns both games'
);

-- Raw punctuation / operator soup must not error and yields no spurious rows.
select lives_ok(
  $$ select 1 from games
     where search_tsv @@ websearch_to_tsquery('simple', '!():&|<>') $$,
  'fts: raw operator/punctuation input does not raise a syntax error'
);
select is(
  (select count(*)::int from games
   where search_tsv @@ websearch_to_tsquery('simple', '!():&|<>')),
  0,
  'fts: meaningless operator input matches nothing'
);

-- summary text is weighted into the tsvector, so a summary word still matches.
select isnt_empty(
  $$ select 1 from games
     where search_tsv @@ websearch_to_tsquery('simple', 'birds') $$,
  'fts: a distinctive summary word (Wingspan "birds") is searchable'
);

-- --- genre filter (game_genres) -------------------------------------------
-- genre = strategy (id 4): the repo joins game_genres!inner and filters genre_id.
select set_eq(
  $$ select g.canonical_name from games g
     join game_genres gg on gg.game_id = g.id
     where gg.genre_id = 4 $$,
  array['Catan', 'Wingspan'],
  'genre: strategy(4) returns Catan + Wingspan, excludes Zelda'
);

-- --- platform filter (game_platforms) -------------------------------------
-- platform = switch (id 6): only Zelda ships there in the seed set.
select set_eq(
  $$ select g.canonical_name from games g
     join game_platforms gp on gp.game_id = g.id
     where gp.platform_id = 6 $$,
  array['The Legend of Zelda: Breath of the Wild'],
  'platform: switch(6) returns only Zelda'
);

-- --- player-range OVERLAP (tabletop_game_details) -------------------------
-- "supports at least 5" => max_players >= 5. Mirrors the repo's gte predicate
-- and the Dart playerRangeOverlaps(reqMin: 5) case.
select set_eq(
  $$ select g.canonical_name from games g
     join tabletop_game_details t on t.game_id = g.id
     where t.max_players >= 5 $$,
  array['Wingspan', 'Codenames'],
  'players: min=5 (max_players>=5) returns Wingspan + Codenames, excludes Catan (3-4)'
);

-- A group of exactly 6 => overlap is max_players >= 6 AND min_players <= 6.
select set_eq(
  $$ select g.canonical_name from games g
     join tabletop_game_details t on t.game_id = g.id
     where t.max_players >= 6 and t.min_players <= 6 $$,
  array['Codenames'],
  'players: exactly 6 (overlap) returns only Codenames (2-8)'
);

-- max bound: a 2-player night => min_players <= 2. Catan (min 3) is excluded.
select set_eq(
  $$ select g.canonical_name from games g
     join tabletop_game_details t on t.game_id = g.id
     where t.min_players <= 2 $$,
  array['Wingspan', 'Codenames'],
  'players: max=2 (min_players<=2) excludes Catan (needs 3+)'
);

-- --- combined filters compose (kind + genre + players) --------------------
-- kind=tabletop_game + genre=strategy(4) + players>=5 => only Wingspan.
select set_eq(
  $$ select g.canonical_name from games g
     join game_genres gg on gg.game_id = g.id
     join tabletop_game_details t on t.game_id = g.id
     where g.kind = 'tabletop_game' and gg.genre_id = 4 and t.max_players >= 5 $$,
  array['Wingspan'],
  'combined: tabletop + strategy + players>=5 narrows to Wingspan only'
);

-- default ordering is popularity desc (the repo orders by popularity_score desc);
-- Elden Ring (99) outranks Halo (85) among video games.
select is(
  (select canonical_name from games where kind = 'video_game'
   order by popularity_score desc nulls last limit 1),
  'Elden Ring',
  'ordering: popularity_score desc puts Elden Ring first among video games'
);

select * from finish();
rollback;
