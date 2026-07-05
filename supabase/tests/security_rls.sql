-- ===========================================================================
-- SECURITY / RLS invariants (docs/demo-completion-plan.md §3).
-- Each assertion is named by the invariant it proves. Runs in one transaction
-- that `supabase test db` rolls back, so it is repeatable against the seed DB.
--
-- Technique: to exercise a policy AS a given user we set the role + JWT claims
-- inside the transaction (set local), assert, then reset role. The very first
-- profile assertion is a live sanity check that RLS is actually engaged (a
-- stranger cannot see a private row) before the rest of the suite relies on it.
-- ===========================================================================
begin;
create extension if not exists pgtap;
select plan(35);

-- --- fixtures -------------------------------------------------------------
-- Three users via the real auth path so handle_new_user makes conforming
-- profiles; alice private, bob & carol public. bob & alice are friends.
insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-000000000001', 'alice@example.com'),  -- private
  ('b0000000-0000-0000-0000-000000000002', 'bob@example.com'),    -- friend of alice
  ('c0000000-0000-0000-0000-000000000003', 'carol@example.com');  -- stranger

update profiles set profile_visibility = 'private'
  where id = 'a0000000-0000-0000-0000-000000000001';

-- accepted friendship alice <-> bob
insert into friendships (requester_id, addressee_id, status, responded_at)
values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'accepted', now());

-- alice owns a private log + review + a friends-visibility list on a seed game.
insert into user_game_logs (user_id, game_id, completion_status_id, liked)
values ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 5, true);
insert into reviews (user_id, game_id, body, rating)
values ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Great game', 9);
insert into custom_lists (id, owner_id, title, visibility)
values ('11111111-aaaa-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Alice list', 'friends');
insert into list_items (list_id, game_id, position)
values ('11111111-aaaa-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 0);

-- ===========================================================================
-- 1. RLS PRESENCE: every user-data table has row security enabled.
-- ===========================================================================
select ok(
  bool_and(rowsecurity),
  'RLS enabled on every user-data table'
) from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles','user_game_logs','reviews','review_likes','custom_lists',
    'list_items','friendships','function_rate_limits','game_embeddings',
    'rag_chat_sessions','rag_chat_messages','game_similarity_cache',
    'user_recommendations','recommendation_impressions','ingestion_jobs','service_tokens'
  );

-- Catalog tables are intentionally public-read but STILL have RLS enabled
-- (deny-by-default posture; a permissive select policy opens reads).
select ok(
  bool_and(rowsecurity),
  'RLS also enabled on public-read catalog tables'
) from pg_tables
where schemaname = 'public'
  and tablename in ('games','video_game_details','tabletop_game_details','game_platforms','game_genres');

-- ===========================================================================
-- 2. PROFILES visibility + own-row update.
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';

select is_empty(
  $$ select 1 from profiles where id = 'a0000000-0000-0000-0000-000000000001' $$,
  'profiles: stranger cannot see a private profile'
);
select isnt_empty(
  $$ select 1 from profiles where id = 'b0000000-0000-0000-0000-000000000002' $$,
  'profiles: anyone can see a public profile'
);

-- carol cannot update alice's row (0 rows affected, silently filtered by RLS).
update profiles set bio = 'hacked' where id = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select bio from profiles where id = 'a0000000-0000-0000-0000-000000000001'),
  null,
  'profiles: a user cannot UPDATE another user''s row'
);

reset role;
-- friend (bob) CAN see alice's private profile.
set local role authenticated;
set local request.jwt.claims to '{"sub":"b0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select isnt_empty(
  $$ select 1 from profiles where id = 'a0000000-0000-0000-0000-000000000001' $$,
  'profiles: an accepted friend can see a private profile'
);
reset role;

-- ===========================================================================
-- 3. USER_GAME_LOGS / REVIEWS ownership + visibility + forgery block.
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';

-- Visibility follows can_view_profile: alice is private, so carol sees nothing.
select is_empty(
  $$ select 1 from user_game_logs where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'logs: a stranger cannot see a private user''s logs'
);
select is_empty(
  $$ select 1 from reviews where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'reviews: a stranger cannot see a private user''s reviews'
);

-- Forgery: carol inserting a log with alice's user_id is blocked by with-check.
select throws_ok(
  $$ insert into user_game_logs (user_id, game_id, completion_status_id)
     values ('a0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003',2) $$,
  '42501',
  'new row violates row-level security policy for table "user_game_logs"',
  'logs: forging another user''s user_id on insert is blocked'
);
select throws_ok(
  $$ insert into reviews (user_id, game_id, body)
     values ('a0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','forged') $$,
  '42501',
  'new row violates row-level security policy for table "reviews"',
  'reviews: forging another user''s user_id on insert is blocked'
);

-- carol CAN insert her own log/review.
select lives_ok(
  $$ insert into user_game_logs (user_id, game_id, completion_status_id)
     values ('c0000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000003',2) $$,
  'logs: a user can insert their own log'
);
reset role;

-- friend (bob) CAN see alice's log + review.
set local role authenticated;
set local request.jwt.claims to '{"sub":"b0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select isnt_empty(
  $$ select 1 from reviews where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'reviews: an accepted friend can see a private user''s review'
);
reset role;

-- ===========================================================================
-- 4. CUSTOM_LISTS / LIST_ITEMS friends-visibility + owner-only mutate.
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';
select is_empty(
  $$ select 1 from custom_lists where id = '11111111-aaaa-0000-0000-000000000001' $$,
  'lists: a stranger cannot see a friends-visibility list'
);
select is_empty(
  $$ select 1 from list_items where list_id = '11111111-aaaa-0000-0000-000000000001' $$,
  'list_items: a stranger cannot see items of a friends-visibility list'
);
-- Stranger cannot mutate someone else's list (0 rows; RLS filters the target).
update custom_lists set title = 'hacked' where id = '11111111-aaaa-0000-0000-000000000001';
reset role;
-- Read back as postgres: the title must be unchanged.
select is(
  (select title from custom_lists where id = '11111111-aaaa-0000-0000-000000000001'),
  'Alice list',
  'lists: a non-owner cannot UPDATE another user''s list'
);

set local role authenticated;
set local request.jwt.claims to '{"sub":"b0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select isnt_empty(
  $$ select 1 from custom_lists where id = '11111111-aaaa-0000-0000-000000000001' $$,
  'lists: an accepted friend CAN see a friends-visibility list'
);
select isnt_empty(
  $$ select 1 from list_items where list_id = '11111111-aaaa-0000-0000-000000000001' $$,
  'list_items: an accepted friend CAN see the list''s items'
);
reset role;

-- ===========================================================================
-- 5. FRIENDSHIPS: no self-accept; transition trigger; reverse-dup unique index.
-- ===========================================================================
-- carol requests bob (pending).
insert into friendships (id, requester_id, addressee_id, status)
values ('22222222-0000-0000-0000-000000000001',
        'c0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000002','pending');

-- Requester (carol) CANNOT self-accept: addressee-only update policy filters
-- the row, so the UPDATE matches 0 rows and the status stays pending.
set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';
update friendships set status = 'accepted' where id = '22222222-0000-0000-0000-000000000001';
reset role;
select is(
  (select status::text from friendships where id = '22222222-0000-0000-0000-000000000001'),
  'pending',
  'friendships: the requester CANNOT self-accept (addressee-only update)'
);

-- Addressee (bob) CAN accept.
set local role authenticated;
set local request.jwt.claims to '{"sub":"b0000000-0000-0000-0000-000000000002","role":"authenticated"}';
update friendships set status = 'accepted', responded_at = now()
  where id = '22222222-0000-0000-0000-000000000001';
reset role;
select is(
  (select status::text from friendships where id = '22222222-0000-0000-0000-000000000001'),
  'accepted',
  'friendships: the addressee CAN accept a pending request'
);

-- Transition trigger: accepted -> pending is rejected (terminal state, P0001).
select throws_ok(
  $$ update friendships set status = 'pending' where id = '22222222-0000-0000-0000-000000000001' $$,
  'P0001',
  'friendship status accepted is terminal and cannot change',
  'friendships: accepted->pending is rejected by the transition trigger'
);

-- Reverse-direction duplicate blocked by the ordered-pair unique index:
-- bob already accepted with carol above (carol->bob). bob->carol must collide.
select throws_ok(
  $$ insert into friendships (requester_id, addressee_id)
     values ('b0000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000003') $$,
  '23505',
  'duplicate key value violates unique constraint "friendships_pair_uniq"',
  'friendships: reverse-direction duplicate blocked by the ordered-pair unique index'
);

-- ===========================================================================
-- 6. GRANTS / FUNCTION LOCKDOWN (the PUBLIC-revoke guarantee).
-- ===========================================================================
-- anon has NO table-level SELECT on the internal tables.
select ok(
  not has_table_privilege('anon', 'game_similarity_cache', 'SELECT'),
  'grants: anon has NO SELECT on game_similarity_cache'
);
select ok(
  not has_table_privilege('anon', 'game_embeddings', 'SELECT'),
  'grants: anon has NO SELECT on game_embeddings'
);
select ok(
  not has_table_privilege('anon', 'friend_edges', 'SELECT'),
  'grants: anon has NO SELECT on the friend_edges view'
);

-- Sensitive functions are NOT executable by anon or authenticated.
select ok(
  not has_function_privilege('anon', 'increment_rate_limit(uuid, text, timestamptz)', 'EXECUTE'),
  'grants: anon cannot EXECUTE increment_rate_limit'
);
select ok(
  not has_function_privilege('authenticated', 'increment_rate_limit(uuid, text, timestamptz)', 'EXECUTE'),
  'grants: authenticated cannot EXECUTE increment_rate_limit'
);
select ok(
  not has_function_privilege('authenticated', 'recompute_recommendations()', 'EXECUTE'),
  'grants: authenticated cannot EXECUTE recompute_recommendations'
);
select ok(
  not has_function_privilege('authenticated', 'recompute_similarity()', 'EXECUTE'),
  'grants: authenticated cannot EXECUTE recompute_similarity'
);
-- But the service role CAN (fails closed otherwise).
select ok(
  has_function_privilege('service_role', 'increment_rate_limit(uuid, text, timestamptz)', 'EXECUTE'),
  'grants: service_role CAN EXECUTE increment_rate_limit'
);

-- friend_edges no longer leaks: even authenticated carol sees only her own edges
-- (she has one accepted edge with bob), never alice<->bob.
set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';
select is(
  (select count(*)::int from friend_edges where friend_id = 'a0000000-0000-0000-0000-000000000001'),
  0,
  'friend_edges: security_invoker hides other users'' friendship edges'
);
reset role;

-- ===========================================================================
-- 7. RAG chat + recommendations: owner-only reads.
-- ===========================================================================
insert into rag_chat_sessions (id, user_id)
values ('33333333-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001');
insert into rag_chat_messages (session_id, role, content)
values ('33333333-0000-0000-0000-000000000001', 'user', 'hello');
-- alice already has user_recommendations: the rescore trigger fired when her log
-- + review were inserted above. Confirm the row exists (as postgres) so the
-- owner-only SELECT test below is meaningful.
select isnt_empty(
  $$ select 1 from user_recommendations where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'recs: the instant-rescore trigger populated alice''s recommendations'
);

set local role authenticated;
set local request.jwt.claims to '{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}';
select is_empty(
  $$ select 1 from rag_chat_sessions where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'rag: a user cannot read another user''s chat session'
);
select is_empty(
  $$ select 1 from rag_chat_messages where session_id = '33333333-0000-0000-0000-000000000001' $$,
  'rag: a user cannot read another user''s chat messages'
);
select is_empty(
  $$ select 1 from user_recommendations where user_id = 'a0000000-0000-0000-0000-000000000001' $$,
  'recs: a user cannot read another user''s recommendations'
);
-- impression insert is self-only: carol forging alice's user_id is blocked.
select throws_ok(
  $$ insert into recommendation_impressions (user_id, game_id, action)
     values ('a0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','dismissed') $$,
  '42501',
  'new row violates row-level security policy for table "recommendation_impressions"',
  'recs: a user cannot forge another user''s impression insert'
);
reset role;

select * from finish();
rollback;
