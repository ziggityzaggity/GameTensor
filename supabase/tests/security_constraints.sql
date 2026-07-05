-- ===========================================================================
-- SECURITY via CONSTRAINTS + triggers (docs/demo-completion-plan.md §3.1).
-- These check constraints and the hours_source trigger are a security boundary:
-- they cap storage abuse / UI DoS and stop a client spoofing sync provenance.
-- Each throws_ok pins the exact constraint / sqlstate so a regression is obvious.
-- ===========================================================================
begin;
create extension if not exists pgtap;
select plan(11);

-- One user (real auth path) and a seed game to attach writes to.
insert into auth.users (id, email) values
  ('d0000000-0000-0000-0000-000000000001', 'dave@example.com');

-- --- length / range constraints (rejected writes) ------------------------
select throws_ok(
  $$ insert into reviews (user_id, game_id, body)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002',
             repeat('x', 10001)) $$,
  '23514',
  'new row for relation "reviews" violates check constraint "reviews_body_len"',
  'constraints: an over-length review body (>10000) is rejected'
);

select throws_ok(
  $$ insert into reviews (user_id, game_id, body, rating)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','ok', 11) $$,
  '23514',
  'new row for relation "reviews" violates check constraint "reviews_rating_check"',
  'constraints: a rating above 10 is rejected'
);
select throws_ok(
  $$ insert into reviews (user_id, game_id, body, rating)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','ok', -1) $$,
  '23514',
  'new row for relation "reviews" violates check constraint "reviews_rating_check"',
  'constraints: a negative rating is rejected'
);

select throws_ok(
  $$ insert into user_game_logs (user_id, game_id, completion_status_id, hours_played)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002',2, -5) $$,
  '23514',
  'new row for relation "user_game_logs" violates check constraint "user_game_logs_hours_range"',
  'constraints: negative hours_played is rejected'
);

select throws_ok(
  $$ update profiles set username = 'Has Space'
     where id = 'd0000000-0000-0000-0000-000000000001' $$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_username_format"',
  'constraints: a bad username format is rejected'
);
select throws_ok(
  $$ update profiles set username = 'ab'
     where id = 'd0000000-0000-0000-0000-000000000001' $$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_username_format"',
  'constraints: a too-short username (<3) is rejected'
);
select throws_ok(
  $$ update profiles set bio = repeat('b', 501)
     where id = 'd0000000-0000-0000-0000-000000000001' $$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_bio_len"',
  'constraints: an over-length bio (>500) is rejected'
);

-- --- valid boundary writes succeed (constraints are not over-tight) -------
select lives_ok(
  $$ insert into reviews (user_id, game_id, body, rating)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002',
             repeat('x', 10000), 10) $$,
  'constraints: an exactly-10000-char body with rating 10 is accepted'
);

-- ===========================================================================
-- hours_source spoof: an AUTHENTICATED writer setting 'xbox_sync' is forced
-- back to 'manual' by enforce_manual_hours_source (§3.1.3). A service-role
-- writer (no auth.uid()) is left untouched, so real sync can still write it.
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims to '{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated"}';
insert into user_game_logs (user_id, game_id, completion_status_id, hours_source)
values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003',2,'xbox_sync');
reset role;

select is(
  (select hours_source from user_game_logs
   where user_id = 'd0000000-0000-0000-0000-000000000001'
     and game_id = '00000000-0000-0000-0000-000000000003'),
  'manual',
  'hours_source: an authenticated write of xbox_sync is forced to manual'
);

-- service-role write (bypasses the auth.uid() branch) keeps xbox_sync. Clear the
-- JWT claims first: `set local` above persists to end of txn, so a stale `sub`
-- would make auth.uid() non-null even under service_role and force 'manual'.
set local role service_role;
set local request.jwt.claims to '';
insert into user_game_logs (user_id, game_id, completion_status_id, hours_source)
values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000101',2,'xbox_sync');
reset role;
reset request.jwt.claims;
select is(
  (select hours_source from user_game_logs
   where user_id = 'd0000000-0000-0000-0000-000000000001'
     and game_id = '00000000-0000-0000-0000-000000000101'),
  'xbox_sync',
  'hours_source: a service-role sync write of xbox_sync is preserved'
);

-- The base CHECK still rejects an entirely bogus source value.
select throws_ok(
  $$ insert into user_game_logs (user_id, game_id, completion_status_id, hours_source)
     values ('d0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000102',2,'garbage') $$,
  '23514',
  'new row for relation "user_game_logs" violates check constraint "user_game_logs_hours_source_check"',
  'hours_source: an unknown source value is rejected by the CHECK constraint'
);

select * from finish();
rollback;
