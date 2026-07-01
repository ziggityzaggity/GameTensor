-- Sample catalog data so `supabase db reset` gives an immediately testable
-- catalog without hitting real IGDB/BGG during local development.

insert into games (id, kind, canonical_name, slug, summary, release_date, cover_image_url, igdb_id, popularity_score)
values
  ('00000000-0000-0000-0000-000000000001', 'video_game', 'The Legend of Zelda: Breath of the Wild', 'zelda-botw',
   'An open-world action-adventure game set in the kingdom of Hyrule.', '2017-03-03', null, 7346, 98),
  ('00000000-0000-0000-0000-000000000002', 'video_game', 'Elden Ring', 'elden-ring',
   'A fantasy action RPG developed by FromSoftware, co-written with George R. R. Martin.', '2022-02-25', null, 119133, 99),
  ('00000000-0000-0000-0000-000000000003', 'video_game', 'Halo Infinite', 'halo-infinite',
   'The sixth mainline entry in the Halo series, a first-person shooter for Xbox and PC.', '2021-12-08', null, 20026, 85);

insert into video_game_details (game_id, franchise, game_modes, esrb_rating, metacritic_score)
values
  ('00000000-0000-0000-0000-000000000001', 'The Legend of Zelda', array['single_player'], 'E10+', 97),
  ('00000000-0000-0000-0000-000000000002', 'Souls-like', array['single_player', 'co_op'], 'M', 96),
  ('00000000-0000-0000-0000-000000000003', 'Halo', array['single_player', 'multiplayer'], 'T', 87);

insert into game_platforms (game_id, platform_id) values
  ('00000000-0000-0000-0000-000000000001', 6), -- switch
  ('00000000-0000-0000-0000-000000000002', 1), -- pc
  ('00000000-0000-0000-0000-000000000002', 2), -- ps5
  ('00000000-0000-0000-0000-000000000002', 4), -- xbox_series
  ('00000000-0000-0000-0000-000000000003', 1), -- pc
  ('00000000-0000-0000-0000-000000000003', 4), -- xbox_series
  ('00000000-0000-0000-0000-000000000003', 5); -- xbox_one

insert into game_genres (game_id, genre_id) values
  ('00000000-0000-0000-0000-000000000001', 2), -- adventure
  ('00000000-0000-0000-0000-000000000001', 1), -- action
  ('00000000-0000-0000-0000-000000000002', 3), -- rpg
  ('00000000-0000-0000-0000-000000000002', 1), -- action
  ('00000000-0000-0000-0000-000000000003', 8); -- shooter

insert into games (id, kind, canonical_name, slug, summary, release_date, cover_image_url, bgg_id, popularity_score)
values
  ('00000000-0000-0000-0000-000000000101', 'tabletop_game', 'Catan', 'catan',
   'Trade, build, and settle the island of Catan in this classic board game.', '1995-01-01', null, 13, 90),
  ('00000000-0000-0000-0000-000000000102', 'tabletop_game', 'Wingspan', 'wingspan',
   'A competitive, medium-weight, card-driven engine-building board game about birds.', '2019-03-01', null, 266192, 92),
  ('00000000-0000-0000-0000-000000000103', 'tabletop_game', 'Codenames', 'codenames',
   'A social word-guessing party game for teams.', '2015-01-01', null, 178900, 88);

insert into tabletop_game_details (game_id, bgg_type, min_players, max_players, min_playtime_minutes, max_playtime_minutes, min_age, bgg_rank, bgg_average_rating)
values
  ('00000000-0000-0000-0000-000000000101', 'boardgame', 3, 4, 60, 120, 10, 400, 7.1),
  ('00000000-0000-0000-0000-000000000102', 'boardgame', 1, 5, 40, 70, 10, 20, 8.1),
  ('00000000-0000-0000-0000-000000000103', 'boardgame', 2, 8, 15, 15, 14, 150, 7.6);

insert into game_genres (game_id, genre_id) values
  ('00000000-0000-0000-0000-000000000101', 4), -- strategy
  ('00000000-0000-0000-0000-000000000102', 4), -- strategy
  ('00000000-0000-0000-0000-000000000102', 13), -- family
  ('00000000-0000-0000-0000-000000000103', 9); -- party
