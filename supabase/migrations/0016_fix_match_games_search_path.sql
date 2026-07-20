-- Regression from 0014: pinning match_games to `search_path = public` (to clear
-- the advisor's mutable-search_path warning) removed the `extensions` schema from
-- its path. pgvector is installed in `extensions` (migration 0001), so the `<=>`
-- cosine-distance operator became unresolvable at runtime:
--   ERROR: operator does not exist: extensions.vector <=> extensions.vector
-- which made rag-chat's match_games RPC 500. Keep the path pinned (advisor stays
-- satisfied) but include extensions so the vector operators resolve.
alter function match_games(vector, int) set search_path = public, extensions;
