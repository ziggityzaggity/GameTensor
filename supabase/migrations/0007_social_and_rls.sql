-- Phase 3 schema included now so RLS visibility rules (friends-only) are stable
-- from day one, even though the friends UI doesn't ship until Phase 3.
create table friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references profiles(id) on delete cascade,
  addressee_id uuid not null references profiles(id) on delete cascade,
  status friend_request_status not null default 'pending',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id),
  unique (requester_id, addressee_id)
);

create index friendships_requester_idx on friendships (requester_id, status);
create index friendships_addressee_idx on friendships (addressee_id, status);

create view friend_edges as
  select requester_id as user_id, addressee_id as friend_id from friendships where status = 'accepted'
  union
  select addressee_id as user_id, requester_id as friend_id from friendships where status = 'accepted';

-- Reusable visibility helper: self, public profile, or accepted friend.
create or replace function can_view_profile(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    target_user_id = auth.uid()
    or exists (
      select 1 from profiles p
      where p.id = target_user_id and p.profile_visibility = 'public'
    )
    or exists (
      select 1 from friend_edges f
      where f.user_id = target_user_id and f.friend_id = auth.uid()
    );
$$;

alter table profiles enable row level security;
alter table games enable row level security;
alter table video_game_details enable row level security;
alter table tabletop_game_details enable row level security;
alter table game_platforms enable row level security;
alter table game_genres enable row level security;
alter table user_game_logs enable row level security;
alter table reviews enable row level security;
alter table review_likes enable row level security;
alter table custom_lists enable row level security;
alter table list_items enable row level security;
alter table friendships enable row level security;

-- profiles
create policy profiles_select on profiles
  for select using (can_view_profile(id));
create policy profiles_update_own on profiles
  for update using (id = auth.uid());

-- catalog: public read, service-role write only (ingestion Edge Functions use the
-- service role key which bypasses RLS, so no explicit write policy is needed/granted)
create policy games_select_all on games for select using (true);
create policy video_game_details_select_all on video_game_details for select using (true);
create policy tabletop_game_details_select_all on tabletop_game_details for select using (true);
create policy game_platforms_select_all on game_platforms for select using (true);
create policy game_genres_select_all on game_genres for select using (true);

-- user_game_logs: owner-write, visibility follows the owning profile
create policy user_game_logs_select on user_game_logs
  for select using (can_view_profile(user_id));
create policy user_game_logs_insert_own on user_game_logs
  for insert with check (user_id = auth.uid());
create policy user_game_logs_update_own on user_game_logs
  for update using (user_id = auth.uid());
create policy user_game_logs_delete_own on user_game_logs
  for delete using (user_id = auth.uid());

-- reviews: same visibility pattern
create policy reviews_select on reviews
  for select using (deleted_at is null and can_view_profile(user_id));
create policy reviews_insert_own on reviews
  for insert with check (user_id = auth.uid());
create policy reviews_update_own on reviews
  for update using (user_id = auth.uid());
create policy reviews_delete_own on reviews
  for delete using (user_id = auth.uid());

create policy review_likes_select on review_likes
  for select using (true);
create policy review_likes_insert_own on review_likes
  for insert with check (user_id = auth.uid());
create policy review_likes_delete_own on review_likes
  for delete using (user_id = auth.uid());

-- custom_lists: visibility gated by the list's own visibility column
create policy custom_lists_select on custom_lists
  for select using (
    deleted_at is null and (
      visibility = 'public'
      or owner_id = auth.uid()
      or (visibility = 'friends' and exists (
        select 1 from friend_edges f where f.user_id = owner_id and f.friend_id = auth.uid()
      ))
    )
  );
create policy custom_lists_insert_own on custom_lists
  for insert with check (owner_id = auth.uid());
create policy custom_lists_update_own on custom_lists
  for update using (owner_id = auth.uid());
create policy custom_lists_delete_own on custom_lists
  for delete using (owner_id = auth.uid());

-- list_items: inherits visibility from the parent list
create policy list_items_select on list_items
  for select using (
    exists (
      select 1 from custom_lists l
      where l.id = list_items.list_id
        and l.deleted_at is null
        and (
          l.visibility = 'public'
          or l.owner_id = auth.uid()
          or (l.visibility = 'friends' and exists (
            select 1 from friend_edges f where f.user_id = l.owner_id and f.friend_id = auth.uid()
          ))
        )
    )
  );
create policy list_items_mutate_own on list_items
  for all using (
    exists (select 1 from custom_lists l where l.id = list_items.list_id and l.owner_id = auth.uid())
  ) with check (
    exists (select 1 from custom_lists l where l.id = list_items.list_id and l.owner_id = auth.uid())
  );

-- friendships: visible/mutable by either party
create policy friendships_select on friendships
  for select using (requester_id = auth.uid() or addressee_id = auth.uid());
create policy friendships_insert on friendships
  for insert with check (requester_id = auth.uid());
create policy friendships_update on friendships
  for update using (requester_id = auth.uid() or addressee_id = auth.uid());
create policy friendships_delete on friendships
  for delete using (requester_id = auth.uid() or addressee_id = auth.uid());
