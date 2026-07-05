-- ===========================================================================
-- DATABASE updates/queries: triggers + the recommender (docs/ml-workflows.md §2).
-- Covers handle_new_user, signal extraction weights, and the recommender's
-- correctness properties: CF propagation, cold-start, exclude-already-logged,
-- dismissal decay, the dislike penalty, instant trigger-driven freshness, and
-- double-run safety. Runs in one rolled-back transaction.
--
-- Note on time: now() is constant within a transaction, so "updated_at advanced"
-- is not observable here; we assert the updated_at trigger is WIRED instead
-- (has_trigger), which still catches accidental removal.
-- ===========================================================================
begin;
create extension if not exists pgtap;
select plan(13);

-- ---------------------------------------------------------------------------
-- Utility triggers + signal weights (independent users f/g).
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('f0000000-0000-0000-0000-000000000001', 'frank@example.com'),
  ('ca000000-0000-0000-0000-000000000002', 'grace@example.com');

-- 1-2. handle_new_user created a profile with a format-conforming username.
select isnt_empty(
  $$ select 1 from profiles where id = 'f0000000-0000-0000-0000-000000000001' $$,
  'handle_new_user: a profile row is created for a new auth user'
);
select ok(
  (select username ~ '^[a-z0-9_]{3,30}$'
   from profiles where id = 'f0000000-0000-0000-0000-000000000001'),
  'handle_new_user: the generated username satisfies the format constraint'
);

-- 3. The updated_at trigger is attached (fires now() on update).
select has_trigger(
  'profiles', 'profiles_set_updated_at',
  'updated_at: the set_updated_at trigger is wired on profiles'
);

-- 4. Signal weight: like(+1) + completed_100(+0.7) + favorite(+0.5) = 2.2,
-- clamped to the +2 ceiling.
insert into user_game_logs (user_id, game_id, completion_status_id, liked, is_favorite)
values ('ca000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002',6,true,true);
select is(
  (select signal::numeric from user_game_signals
   where user_id = 'ca000000-0000-0000-0000-000000000002'
     and game_id = '00000000-0000-0000-0000-000000000002'),
  2.0::numeric,
  'signals: like + completed_100 + favorite is clamped to +2.0'
);

-- 5. Signal weight: dislike(-1) + dropped(-0.3) = -1.3 (aversion is negative).
insert into user_game_logs (user_id, game_id, completion_status_id, liked)
values ('ca000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003',4,false);
select is(
  (select signal::numeric from user_game_signals
   where user_id = 'ca000000-0000-0000-0000-000000000002'
     and game_id = '00000000-0000-0000-0000-000000000003'),
  -1.3::numeric,
  'signals: dislike + dropped yields a negative signal (-1.3)'
);

-- ---------------------------------------------------------------------------
-- Recommender scenario. a & b are CF users (3 signals each); e is cold-start
-- (0 signals). a likes Elden Ring + Halo + Catan; b likes Elden Ring + Zelda +
-- Halo. Zelda (which a never logged) should propagate to a via item-item CF
-- through their shared taste with b.
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('e1000000-0000-0000-0000-000000000001', 'erin@example.com'),   -- cold-start
  ('a1000000-0000-0000-0000-000000000002', 'amy@example.com'),    -- CF user a
  ('b1000000-0000-0000-0000-000000000003', 'ben@example.com');    -- CF user b

-- completion_status_id 2 = 'playing' (+0.3); liked = +1 → per-game signal 1.3.
insert into user_game_logs (user_id, game_id, completion_status_id, liked) values
  ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002',2,true), -- a: Elden
  ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003',2,true), -- a: Halo
  ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000101',2,true), -- a: Catan
  ('b1000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000002',2,true), -- b: Elden
  ('b1000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001',2,true), -- b: Zelda
  ('b1000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000003',2,true); -- b: Halo

-- Build the full model (similarity matrix + everyone's rails).
select recompute_recommendations();

-- 6. DOUBLE-RUN: a second full recompute must not raise a PK violation
-- (validates the delete-then-insert restructure).
select lives_ok(
  $$ select recompute_recommendations() $$,
  'recompute: running the full batch twice in a row does not raise a PK violation'
);

-- 7. CF PROPAGATION: Zelda reaches a via collaborative filtering, tagged 'cf'.
select is(
  (select strategy from user_recommendations
   where user_id = 'a1000000-0000-0000-0000-000000000002'
     and game_id = '00000000-0000-0000-0000-000000000001'),
  'cf',
  'recommender: a game a similar user liked (Zelda) propagates to a as strategy cf'
);

-- 8. EXCLUDE ALREADY-LOGGED: a's rail never surfaces a game a already logged.
select is_empty(
  $$ select 1 from user_recommendations r
     where r.user_id = 'a1000000-0000-0000-0000-000000000002'
       and r.game_id in (
         '00000000-0000-0000-0000-000000000002',  -- Elden
         '00000000-0000-0000-0000-000000000003',  -- Halo
         '00000000-0000-0000-0000-000000000101'   -- Catan
       ) $$,
  'recommender: games the user already logged are excluded from their rail'
);

-- 9-10. COLD-START: a zero-signal user still gets a non-empty, popularity-based
-- rail, tagged 'cold_start' (never empty, never 'cf').
select isnt_empty(
  $$ select 1 from user_recommendations where user_id = 'e1000000-0000-0000-0000-000000000001' $$,
  'recommender: a zero-signal user gets a non-empty cold-start rail'
);
select is(
  (select bool_and(strategy = 'cold_start')
   from user_recommendations where user_id = 'e1000000-0000-0000-0000-000000000001'),
  true,
  'recommender: every cold-start rail row is tagged cold_start (not cf)'
);

-- 11. DISMISSAL DECAY + INSTANT FRESHNESS: capture Zelda's baseline score for a,
-- then insert two 'dismissed' impressions. The impression trigger rescores a in
-- the same transaction (NO batch call), so Zelda's score must drop to exactly
-- 0.5^2 = 0.25x — proving both the decay math and trigger-driven freshness.
create temp table _baseline as
  select score from user_recommendations
  where user_id = 'a1000000-0000-0000-0000-000000000002'
    and game_id = '00000000-0000-0000-0000-000000000001';

insert into recommendation_impressions (user_id, game_id, action) values
  ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','dismissed'),
  ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','dismissed');

select ok(
  abs(
    (select score from user_recommendations
       where user_id = 'a1000000-0000-0000-0000-000000000002'
         and game_id = '00000000-0000-0000-0000-000000000001')
    - (select score * 0.25 from _baseline)
  ) < 1e-9,
  'recommender: two dismissals decay the score to 0.25x, applied instantly by the trigger (no batch)'
);

-- 12-13. DISLIKE PENALTY + FRESHNESS: flipping a's likes on Elden Ring and Halo
-- to dislikes makes Zelda net-negatively-similar for a. The log-update trigger
-- rescores a immediately (NO batch), and the HAVING cf_score > 0 filter drops
-- the now net-disliked candidate entirely.
update user_game_logs set liked = false
  where user_id = 'a1000000-0000-0000-0000-000000000002'
    and game_id = '00000000-0000-0000-0000-000000000002';  -- Elden -> dislike
update user_game_logs set liked = false
  where user_id = 'a1000000-0000-0000-0000-000000000002'
    and game_id = '00000000-0000-0000-0000-000000000003';  -- Halo -> dislike

select is_empty(
  $$ select 1 from user_recommendations
     where user_id = 'a1000000-0000-0000-0000-000000000002'
       and game_id = '00000000-0000-0000-0000-000000000001' $$,
  'recommender: the dislike penalty drops a net-disliked-similar game from the rail (trigger, no batch)'
);
select is(
  (select count(*)::int from user_recommendations
   where user_id = 'a1000000-0000-0000-0000-000000000002'),
  0,
  'recommender: with all CF candidates net-negative, the CF user''s rail is empty'
);

select * from finish();
rollback;
