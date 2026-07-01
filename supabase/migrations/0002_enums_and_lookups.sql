-- Closed, stable enums use native Postgres enum types.
create type game_kind as enum ('video_game', 'tabletop_game');
create type platform_family as enum ('pc', 'playstation', 'xbox', 'nintendo', 'mobile', 'tabletop', 'other');
create type friend_request_status as enum ('pending', 'accepted', 'declined', 'blocked');
create type list_visibility as enum ('private', 'friends', 'public');
create type profile_visibility as enum ('private', 'friends', 'public');

-- Completion label scale is a lookup table (not a native enum) so it stays
-- reorderable/extensible without ALTER TYPE ADD VALUE transactional caveats.
create table completion_status (
  id smallint primary key,
  code text unique not null,
  label text not null
);

insert into completion_status (id, code, label) values
  (0, 'wishlist', 'Wishlist'),
  (1, 'not_started', 'Not Started'),
  (2, 'playing', 'Playing'),
  (3, 'on_hold', 'On Hold'),
  (4, 'dropped', 'Dropped'),
  (5, 'completed_main', 'Completed (Main Story)'),
  (6, 'completed_100', '100% Complete');

create table platforms (
  id smallint primary key,
  code text unique not null,
  family platform_family not null,
  display_name text not null
);

insert into platforms (id, code, family, display_name) values
  (1, 'pc', 'pc', 'PC'),
  (2, 'ps5', 'playstation', 'PlayStation 5'),
  (3, 'ps4', 'playstation', 'PlayStation 4'),
  (4, 'xbox_series', 'xbox', 'Xbox Series X|S'),
  (5, 'xbox_one', 'xbox', 'Xbox One'),
  (6, 'switch', 'nintendo', 'Nintendo Switch'),
  (7, 'ios', 'mobile', 'iOS'),
  (8, 'android', 'mobile', 'Android'),
  (9, 'tabletop', 'tabletop', 'Tabletop');

create table genres (
  id smallint primary key,
  code text unique not null,
  display_name text not null
);

insert into genres (id, code, display_name) values
  (1, 'action', 'Action'),
  (2, 'adventure', 'Adventure'),
  (3, 'rpg', 'RPG'),
  (4, 'strategy', 'Strategy'),
  (5, 'simulation', 'Simulation'),
  (6, 'sports', 'Sports'),
  (7, 'puzzle', 'Puzzle'),
  (8, 'shooter', 'Shooter'),
  (9, 'party', 'Party'),
  (10, 'card_game', 'Card Game'),
  (11, 'deck_building', 'Deck Building'),
  (12, 'cooperative', 'Cooperative'),
  (13, 'family', 'Family'),
  (14, 'racing', 'Racing'),
  (15, 'horror', 'Horror'),
  (16, 'platformer', 'Platformer');
