-- Milestone 5 — RAG game-finder schema (see docs/ml-workflows.md §1 and §3).
-- Three tables: game_embeddings (the searchable corpus), rag_chat_sessions and
-- rag_chat_messages (multi-turn history). Plus match_games(), the cosine
-- retrieval RPC shared by the Edge Function and any future client-side backend.
--
-- Standing rule from demo-completion-plan §3.3: migration 0009 set default
-- privileges granting SELECT to anon on every future table, so a new table with
-- RLS *disabled* would be world-readable. Every table below enables RLS.

-- ---------------------------------------------------------------------------
-- game_embeddings — one 384-dim gte-small vector per game.
-- source_text_hash drives incremental re-embedding (re-embed only on change).
-- ---------------------------------------------------------------------------
create table game_embeddings (
  game_id uuid primary key references games(id) on delete cascade,
  embedding vector(384) not null,
  embedding_model text not null,
  source_text_hash text not null,
  updated_at timestamptz not null default now()
);

-- HNSW cosine index (pgvector >= 0.5, installed in 0001). Cosine matches how
-- gte-small embeddings are compared (normalized vectors), and match_games
-- orders by the `<=>` cosine-distance operator this index accelerates.
create index game_embeddings_hnsw_idx
  on game_embeddings using hnsw (embedding vector_cosine_ops);

alter table game_embeddings enable row level security;

-- Read for retrieval is authenticated-only. Embeddings are derived from PUBLIC
-- game metadata, but there is no reason to expose the raw vectors to anon, so we
-- both (a) add an authenticated-only SELECT policy and (b) revoke the blanket
-- anon SELECT that 0009's default privileges granted (matching the friend_edges
-- precedent in 0010). Writes have NO policy: clients are denied insert/update/
-- delete; the embed-games Edge Function writes via the service role, which
-- bypasses RLS.
revoke select on game_embeddings from anon;
create policy game_embeddings_select_authenticated on game_embeddings
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- Chat history — RLS owner-only (a user sees/writes only their own sessions and
-- the messages within them).
-- ---------------------------------------------------------------------------
create table rag_chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index rag_chat_sessions_user_idx on rag_chat_sessions (user_id);

alter table rag_chat_sessions enable row level security;

create policy rag_chat_sessions_select_own on rag_chat_sessions
  for select using (user_id = auth.uid());
create policy rag_chat_sessions_insert_own on rag_chat_sessions
  for insert with check (user_id = auth.uid());
create policy rag_chat_sessions_delete_own on rag_chat_sessions
  for delete using (user_id = auth.uid());

create table rag_chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references rag_chat_sessions(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  retrieved_game_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create index rag_chat_messages_session_idx on rag_chat_messages (session_id, created_at);

alter table rag_chat_messages enable row level security;

-- Ownership is transitive through the parent session: a message is visible/
-- writable only if the caller owns its session.
create policy rag_chat_messages_select_own on rag_chat_messages
  for select using (
    exists (
      select 1 from rag_chat_sessions s
      where s.id = rag_chat_messages.session_id and s.user_id = auth.uid()
    )
  );
create policy rag_chat_messages_insert_own on rag_chat_messages
  for insert with check (
    exists (
      select 1 from rag_chat_sessions s
      where s.id = rag_chat_messages.session_id and s.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- match_games — cosine nearest-neighbour retrieval over game_embeddings.
-- SECURITY INVOKER (the default): runs under the caller's RLS, so the same RPC
-- is safe to expose directly to a future client-side backend — it can only read
-- embeddings the caller is already permitted to read. Similarity is 1 - cosine
-- distance so higher = closer, and the ORDER BY on `<=>` uses the HNSW index.
-- ---------------------------------------------------------------------------
create or replace function match_games(
  query_embedding vector(384),
  match_count int default 24
)
returns table (game_id uuid, similarity float)
language sql
stable
as $$
  select
    ge.game_id,
    1 - (ge.embedding <=> query_embedding) as similarity
  from game_embeddings ge
  order by ge.embedding <=> query_embedding
  limit match_count;
$$;

-- Exposed via PostgREST RPC to authenticated callers (edge function acting as a
-- user, and future client backends). anon has no need for retrieval.
revoke execute on function match_games(vector, int) from public;
grant execute on function match_games(vector, int) to authenticated, service_role;
