-- Milestone 6 — recommendation engine (see docs/ml-workflows.md §2). Pure SQL,
-- no external services. A nightly cron / on-demand recommend-batch Edge Function
-- calls recompute_recommendations(), which (1) rebuilds item-item cosine
-- similarity over the user-signal matrix and (2) rescores every user, writing the
-- top-20 games each into user_recommendations.
--
-- Standing rule (demo-completion-plan §3.3): 0009 grants anon SELECT on every
-- future table by default, so a table without RLS is world-readable. Every table
-- below enables RLS; internal caches get no client policy (deny-all).

-- ---------------------------------------------------------------------------
-- game_similarity_cache — item-item neighbours (top 50/game, sim > 0.1).
-- Purely internal: the "For You" rail reads user_recommendations, never this
-- table, so it is service-role only. Following the game_embeddings precedent in
-- 0012, we revoke the blanket anon SELECT from 0009's default privileges and add
-- NO policy at all — RLS with zero policies denies every client (anon and
-- authenticated) while the service role (which bypasses RLS) still reads/writes.
-- ---------------------------------------------------------------------------
create table game_similarity_cache (
  game_id uuid not null references games(id) on delete cascade,
  neighbor_game_id uuid not null references games(id) on delete cascade,
  sim float not null,
  primary key (game_id, neighbor_game_id)
);

create index game_similarity_cache_game_idx on game_similarity_cache (game_id);

alter table game_similarity_cache enable row level security;
revoke select on game_similarity_cache from anon;

-- ---------------------------------------------------------------------------
-- user_recommendations — precomputed top-N per user, read by the rail.
-- RLS owner-only SELECT (a user sees only their own rail); no client write
-- policy (recompute_recommendations writes via the service role).
-- ---------------------------------------------------------------------------
create table user_recommendations (
  user_id uuid not null references profiles(id) on delete cascade,
  game_id uuid not null references games(id) on delete cascade,
  score float not null,
  strategy text not null check (strategy in ('cf', 'cold_start')),
  computed_at timestamptz not null default now(),
  primary key (user_id, game_id)
);

create index user_recommendations_user_score_idx
  on user_recommendations (user_id, score desc);

alter table user_recommendations enable row level security;

create policy user_recommendations_select_own on user_recommendations
  for select using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- recommendation_impressions — feedback (clicked / dismissed) that feeds the
-- next recompute (dismissal decay, §2.3). RLS owner-only INSERT and SELECT: the
-- user logs and reads their own impressions; the batch job reads them via the
-- service role (RLS bypass).
-- ---------------------------------------------------------------------------
create table recommendation_impressions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  game_id uuid not null references games(id) on delete cascade,
  strategy text,
  action text not null check (action in ('clicked', 'dismissed')),
  shown_at timestamptz not null default now()
);

create index recommendation_impressions_user_game_idx
  on recommendation_impressions (user_id, game_id);

alter table recommendation_impressions enable row level security;

create policy recommendation_impressions_select_own on recommendation_impressions
  for select using (user_id = auth.uid());
create policy recommendation_impressions_insert_own on recommendation_impressions
  for insert with check (user_id = auth.uid());

-- ===========================================================================
-- Signal extraction (§2.1) — factored into a view so both similarity and
-- scoring read the exact same (user, game, signal) matrix. A game a user
-- touched at all produces a row; the signal is the summed contribution of their
-- like/dislike, completion label, favourite flag, and review rating, clamped to
-- [-2, +2]. Positive = affinity, negative = aversion (dislikes penalise).
-- SECURITY INVOKER view: it reads user_game_logs / reviews, which are only ever
-- accessed here by the SECURITY DEFINER recompute functions (running as owner),
-- so RLS on those base tables does not block the batch. No client is granted
-- access to this view (it is not in any client query path).
-- ===========================================================================
create view user_game_signals
with (security_invoker = on) as
with log_signal as (
  select
    l.user_id,
    l.game_id,
    -- like +1 / dislike -1 (NULL liked contributes 0)
    coalesce(case when l.liked then 1.0 when l.liked = false then -1.0 else 0 end, 0)
    -- completion label: finishing is a strong positive, dropping a mild negative
    + case l.completion_status_id
        when 5 then 0.7   -- completed_main
        when 6 then 0.7   -- completed_100
        when 2 then 0.3   -- playing
        when 4 then -0.3  -- dropped
        else 0
      end
    -- an explicit favourite is an additional positive signal
    + case when l.is_favorite then 0.5 else 0 end as signal
  from user_game_logs l
),
review_signal as (
  -- rating 0..10 mapped to -0.5..+0.5 (a middling 5/10 is neutral). Soft-deleted
  -- reviews and null ratings contribute nothing.
  select r.user_id, r.game_id, (r.rating / 10.0 - 0.5) as signal
  from reviews r
  where r.deleted_at is null and r.rating is not null
),
combined as (
  select user_id, game_id, sum(signal) as signal
  from (
    select user_id, game_id, signal from log_signal
    union all
    select user_id, game_id, signal from review_signal
  ) s
  group by user_id, game_id
)
select user_id, game_id, greatest(-2.0, least(2.0, signal)) as signal
from combined
-- drop exactly-neutral rows: they carry no collaborative-filtering information.
where signal <> 0;

-- ===========================================================================
-- recompute_similarity() — item-item cosine similarity (§2.2).
-- SECURITY DEFINER so the service/cron path (which has no auth.uid()) can read
-- through the underlying RLS; revoke PUBLIC + grant service_role per the 0010
-- lesson (revoking PUBLIC also strips service_role, so re-grant explicitly).
-- ===========================================================================
create or replace function recompute_similarity()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  pair_count int;
begin
  -- Rebuild the whole cache each run — the seed/demo dataset is tiny and a full
  -- recompute is simpler and correct (no stale neighbours to expire).
  truncate game_similarity_cache;

  with signals as (
    select user_id, game_id, signal from user_game_signals
  ),
  -- Per-game vector norm over the user-signal matrix (denominator of cosine).
  norms as (
    select game_id, sqrt(sum(signal * signal)) as norm
    from signals
    group by game_id
  ),
  -- Co-rated dot products: for every pair of games rated by the same user, sum
  -- signal_a * signal_b across shared users. game_id < neighbor keeps each
  -- unordered pair once; we emit both directions below.
  dot as (
    select
      a.game_id as game_id,
      b.game_id as neighbor_game_id,
      sum(a.signal * b.signal) as dot
    from signals a
    join signals b on a.user_id = b.user_id and a.game_id < b.game_id
    group by a.game_id, b.game_id
  ),
  -- cosine = dot / (‖a‖·‖b‖). Norms are > 0 here because a game only appears in
  -- `dot` if some user gave it a non-zero signal.
  cosine as (
    select
      d.game_id,
      d.neighbor_game_id,
      d.dot / (na.norm * nb.norm) as sim
    from dot d
    join norms na on na.game_id = d.game_id
    join norms nb on nb.game_id = d.neighbor_game_id
  ),
  -- Emit both directions so scoring can look up neighbours of any game with a
  -- single game_id = ? predicate. (Not named "symmetric" — reserved keyword.)
  bidirectional as (
    select game_id, neighbor_game_id, sim from cosine
    union all
    select neighbor_game_id, game_id, sim from cosine
  ),
  -- Keep only meaningful neighbours (sim > 0.1) and cap at the top 50 per game.
  ranked as (
    select
      game_id, neighbor_game_id, sim,
      row_number() over (partition by game_id order by sim desc) as rn
    from bidirectional
    where sim > 0.1
  )
  insert into game_similarity_cache (game_id, neighbor_game_id, sim)
  select game_id, neighbor_game_id, sim from ranked where rn <= 50;

  get diagnostics pair_count = row_count;
  return pair_count;
end;
$$;

revoke execute on function recompute_similarity() from public;
grant execute on function recompute_similarity() to service_role;

-- ===========================================================================
-- recompute_user_recs(p_user_id) — per-user scoring (§2.3), writing the top 20
-- per user. Splits collaborative-filtering users (≥ 3 signals) from cold-start
-- users (< 3 signals) and applies the right formula to each.
--
-- p_user_id = null rescores EVERY user (the nightly/batch path); a non-null id
-- rescores only that user — this is the cheap path the per-write triggers below
-- take, so a new review/log/dismissal updates that user's rail immediately
-- against the CURRENT similarity cache (the heavy item-item matrix itself only
-- refreshes in the batch — standard cheap-write/heavy-batch split).
-- ===========================================================================
create or replace function recompute_user_recs(p_user_id uuid default null)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  user_count int;
begin
  -- Clear the affected rails first as a separate statement, then insert fresh
  -- rows. (Not a data-modifying CTE on the same statement as the insert: both
  -- touch the same PK and same-snapshot delete+insert semantics are fragile —
  -- the insert cannot see the delete, so reruns would raise PK violations.)
  delete from user_recommendations
  where p_user_id is null or user_id = p_user_id;

  -- popularity normalised to 0..1 across the whole catalogue (numerator for the
  -- popularity term in both the CF blend and the cold-start blend).
  with pop as (
    select
      id as game_id,
      coalesce(popularity_score, 0)
        / nullif((select max(coalesce(popularity_score, 0)) from games), 0) as pop
    from games
  ),
  -- Signal counts split users into CF vs cold-start branches.
  signal_counts as (
    select user_id, count(*) as n from user_game_signals group by user_id
  ),
  -- Every profile is a candidate user (a brand-new user with zero signals still
  -- gets a cold-start rail, never an empty one). The p_user_id filter narrows
  -- the whole pipeline to one user on the trigger path; both branches below
  -- derive their user sets from here.
  all_users as (
    select p.id as user_id, coalesce(sc.n, 0) as signal_count
    from profiles p
    left join signal_counts sc on sc.user_id = p.id
    where p_user_id is null or p.id = p_user_id
  ),
  -- Games each user already logged, in any way — excluded from their recs so we
  -- only ever surface something new.
  logged as (
    select user_id, game_id from user_game_logs
  ),
  -- Dismissal decay exponent d (§2.3): how many times the user dismissed each
  -- game from the rail. Score is later multiplied by 0.5^d.
  dismissals as (
    select user_id, game_id, count(*) as d
    from recommendation_impressions
    where action = 'dismissed'
    group by user_id, game_id
  ),

  -- ---- CF branch (users with ≥ 3 signals) --------------------------------
  -- cf_score(u,g) = Σ over u's rated items i: signal(u,i) × sim(i,g).
  -- A DISLIKE on i (signal < 0) times a positive sim(i,g) yields a NEGATIVE
  -- contribution, so a candidate similar to something the user disliked is
  -- pushed DOWN — this is the user-confirmed dislike penalty. Net-NEGATIVE
  -- candidates (similar mostly to things the user disliked) are dropped
  -- entirely: without the HAVING, per-user min-max normalisation would let a
  -- lone net-disliked candidate resurface on pure popularity (0.2 × pop),
  -- which contradicts the penalty's intent.
  cf_raw as (
    select
      s.user_id,
      sim.neighbor_game_id as game_id,
      sum(s.signal * sim.sim) as cf_score
    from user_game_signals s
    join all_users au on au.user_id = s.user_id and au.signal_count >= 3
    join game_similarity_cache sim on sim.game_id = s.game_id
    -- never recommend a game the user has already logged
    where not exists (
      select 1 from logged lg
      where lg.user_id = s.user_id and lg.game_id = sim.neighbor_game_id
    )
    group by s.user_id, sim.neighbor_game_id
    having sum(s.signal * sim.sim) > 0
  ),
  -- Normalise cf_score to 0..1 per user (min-max) so it blends comparably with
  -- popularity. If a user's candidates all tie, they collapse to 0 and
  -- popularity breaks the tie.
  cf_bounds as (
    select user_id, min(cf_score) as lo, max(cf_score) as hi
    from cf_raw group by user_id
  ),
  cf_scored as (
    select
      c.user_id,
      c.game_id,
      -- final = 0.8 × normalised(cf) + 0.2 × popularity
      0.8 * case
              when b.hi = b.lo then 0.0
              else (c.cf_score - b.lo) / (b.hi - b.lo)
            end
      + 0.2 * coalesce(p.pop, 0) as base_score
    from cf_raw c
    join cf_bounds b on b.user_id = c.user_id
    left join pop p on p.game_id = c.game_id
  ),
  cf_final as (
    select
      cs.user_id,
      cs.game_id,
      -- apply dismissal decay 0.5^d
      cs.base_score * power(0.5, coalesce(dm.d, 0)) as score,
      'cf' as strategy
    from cf_scored cs
    left join dismissals dm on dm.user_id = cs.user_id and dm.game_id = cs.game_id
  ),

  -- ---- Cold-start branch (users with < 3 signals) ------------------------
  cold_users as (
    select user_id from all_users where signal_count < 3
  ),
  -- genre_match(u,g) = fraction of g's genres that appear among the genres of the
  -- user's LIKED games (0 when the user has liked nothing yet → pure popularity).
  liked_genres as (
    select distinct l.user_id, gg.genre_id
    from user_game_logs l
    join cold_users cu on cu.user_id = l.user_id
    join game_genres gg on gg.game_id = l.game_id
    where l.liked is true
  ),
  candidate_genre_match as (
    select
      cu.user_id,
      g.id as game_id,
      -- share of this game's genres the user has shown they like
      coalesce(
        count(*) filter (where lg.genre_id is not null)::float
          / nullif(count(gg.genre_id), 0),
        0
      ) as genre_match
    from cold_users cu
    cross join games g
    left join game_genres gg on gg.game_id = g.id
    left join liked_genres lg on lg.user_id = cu.user_id and lg.genre_id = gg.genre_id
    -- exclude games the cold-start user already logged
    where not exists (
      select 1 from logged l where l.user_id = cu.user_id and l.game_id = g.id
    )
    group by cu.user_id, g.id
  ),
  cold_final as (
    select
      cgm.user_id,
      cgm.game_id,
      -- cold-start score = 0.7 × popularity + 0.3 × genre_match, then dismissal decay
      (0.7 * coalesce(p.pop, 0) + 0.3 * cgm.genre_match)
        * power(0.5, coalesce(dm.d, 0)) as score,
      'cold_start' as strategy
    from candidate_genre_match cgm
    left join pop p on p.game_id = cgm.game_id
    left join dismissals dm on dm.user_id = cgm.user_id and dm.game_id = cgm.game_id
  ),

  -- ---- Combine + rank ----------------------------------------------------
  -- CF users are covered by cf_final; cold-start users by cold_final. The two
  -- user sets are disjoint (split on signal_count), so a plain union is exact.
  combined as (
    select user_id, game_id, score, strategy from cf_final
    union all
    select user_id, game_id, score, strategy from cold_final
  ),
  ranked as (
    select
      user_id, game_id, score, strategy,
      row_number() over (partition by user_id order by score desc, game_id) as rn
    from combined
  ),
  top_n as (
    select user_id, game_id, score, strategy from ranked where rn <= 20
  )
  insert into user_recommendations (user_id, game_id, score, strategy)
  select user_id, game_id, score, strategy from top_n;

  -- Users that ended up with at least one recommendation this run.
  select count(distinct user_id) into user_count
  from user_recommendations
  where p_user_id is null or user_id = p_user_id;
  return user_count;
end;
$$;

revoke execute on function recompute_user_recs(uuid) from public;
grant execute on function recompute_user_recs(uuid) to service_role;

-- ===========================================================================
-- recompute_recommendations() — the single entrypoint the recommend-batch Edge
-- Function calls. Rebuilds similarity, then rescores users, returning a small
-- JSON summary. Split into the two helpers above purely for readability: each
-- stage is a self-contained, independently testable CTE pipeline, and the
-- entrypoint just sequences them and reports counts.
-- ===========================================================================
create or replace function recompute_recommendations()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  sim_pairs int;
  users_scored int;
  total_recs int;
begin
  sim_pairs := recompute_similarity();
  users_scored := recompute_user_recs();
  select count(*) into total_recs from user_recommendations;
  return json_build_object(
    'similarities', sim_pairs,
    'users_scored', users_scored,
    'recommendations', total_recs
  );
end;
$$;

revoke execute on function recompute_recommendations() from public;
grant execute on function recompute_recommendations() to service_role;

-- ===========================================================================
-- Instant per-user updates (user-confirmed requirement): any write to a user's
-- logs, reviews, or impressions rescores THAT user's rail in the same
-- transaction, against the CURRENT similarity cache. The full item-item matrix
-- still refreshes only via recompute_recommendations() (nightly cron /
-- recommend-batch) — the standard cheap-write/heavy-batch split.
--
-- No recursion: recompute_user_recs writes only user_recommendations, which has
-- no trigger; the impressions trigger reads impressions but never writes them.
-- SECURITY DEFINER so a plain authenticated write can rescore through RLS;
-- returns trigger so it cannot be RPC'd, but revoke PUBLIC anyway per the 0010
-- hygiene pattern.
-- ===========================================================================
create or replace function rescore_user_recommendations()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform recompute_user_recs(old.user_id);
  else
    perform recompute_user_recs(new.user_id);
    -- user_id never changes in practice (RLS with-check pins it), but if an
    -- UPDATE ever moved a row between users, rescore the previous owner too.
    if tg_op = 'UPDATE' and old.user_id is distinct from new.user_id then
      perform recompute_user_recs(old.user_id);
    end if;
  end if;
  return null;
end;
$$;

revoke execute on function rescore_user_recommendations() from public;

create trigger user_game_logs_rescore_recs
  after insert or update or delete on user_game_logs
  for each row execute function rescore_user_recommendations();

create trigger reviews_rescore_recs
  after insert or update or delete on reviews
  for each row execute function rescore_user_recommendations();

-- Insert-only: impressions are append-only from the client, and a 'dismissed'
-- insert must immediately decay that game on the user's rail.
create trigger recommendation_impressions_rescore_recs
  after insert on recommendation_impressions
  for each row execute function rescore_user_recommendations();
