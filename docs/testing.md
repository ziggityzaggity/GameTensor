# GameTensor — Test Suite

Automated tests focused on the three priority areas: **security**, **game
search logic**, and **database updates/queries**. Two runners, both green.

## How to run

Prereqs: Docker running + local Supabase up (`supabase start`), and the toolchain
paths from [handoff.md](handoff.md) on PATH.

```powershell
# Database + security + recommender tests (pgTAP) — from repo root
supabase test db

# Client-side pure-logic tests (Dart) — from app/
flutter test
flutter analyze          # must stay clean
```

`supabase test db` runs each `supabase/tests/*.sql` file in its own transaction
and rolls back, so tests are isolated and repeatable against the seed database
(no `db reset` needed between runs).

## Coverage

### pgTAP — `supabase/tests/` (71 assertions across 4 files)

**`security_rls.sql` (35)** — the §3 security model:
- RLS enabled on every user-data and catalog table.
- Profile visibility (private hidden from strangers, visible to friends), own-row-only update.
- `user_game_logs` / `reviews`: owner-only writes, **forgery blocked** (can't insert with another user's `user_id`), visibility follows `can_view_profile`.
- `custom_lists` / `list_items`: friends-visibility gating, owner-only mutation.
- Friendships: **requester cannot self-accept**, transition trigger rejects `accepted→pending`, reverse-direction duplicate blocked.
- **Function lockdown**: `anon` has no SELECT on `friend_edges` / `game_embeddings` / `game_similarity_cache`; `increment_rate_limit` / `recompute_*` are not executable by `anon` or `authenticated`, only `service_role` (the PUBLIC-revoke guarantee).
- RAG chat + recommendations + impressions: owner-only reads, self-only impression insert.

**`security_constraints.sql` (11)** — constraints as a security boundary:
- Over-length review body / bio, out-of-range rating, negative hours → rejected with the exact constraint name.
- Valid boundary writes (10,000-char body, rating 10) accepted.
- **`hours_source` spoof**: an authenticated `xbox_sync` write is forced to `manual`; a service-role sync write keeps `xbox_sync`; a bogus value is rejected by the CHECK.

**`search_queries.sql` (12)** — the DB search contract (mirrors `GamesRepository.searchLocal`):
- `websearch_to_tsquery` FTS: name match, `OR` syntax, raw operator input never errors, summary words searchable.
- Genre / platform / player-range-overlap filters return the right seed games; combined filters compose; popularity-desc ordering.

**`db_triggers_recommender.sql` (13)** — triggers + recommender (`ml-workflows.md` §2):
- `handle_new_user` creates a format-conforming profile; `updated_at` trigger wired; signal weights (clamp to +2, negative for dislike+dropped).
- Recommender: **CF propagation** (a similar user's liked game surfaces tagged `cf`), already-logged exclusion, **cold-start** popularity rail for zero-signal users, **double-run safety**, **dismissal decay** (score → 0.25× after two dismissals), **dislike penalty** (net-disliked-similar game dropped). The decay and penalty are asserted with **no batch call** — proving the instant per-user rescore triggers fire in-transaction.

### Dart — `app/test/` (19 tests)

- `widget_test.dart`: `validateUsername` (format/length/trim), `playerRangeOverlaps` (overlap edge cases), `Game.fromJson` video-game parse, a leaf widget.
- `search_filters_test.dart`: `GameSearchFilters.copyWith` sentinel semantics (preserve / update-one / **clear-to-null**), `hasPlayerFilter`, and a snake_case regression for nested `tabletop_game_details` parsing (the `build.yaml` `field_rename` guard).
- `feed_merge_test.dart`: `mergeActivity` newest-first ordering + cap.

## Not covered (and why)

- **Storage/avatar RLS** (`storage.objects` per-user-folder policy): verified live via the storage REST API during M3, not in pgTAP (the policy uses `storage.foldername()` against uploaded objects, awkward to fixture in-transaction).
- **Edge Function HTTP paths** (CORS, rate-limit 429, CRON gate, rag-chat generation): exercised via `supabase functions serve` + REST during each milestone. Pure edge helpers have Deno tests (`supabase/functions/_shared/*.test.ts`) that run in CI — `deno` is not installed locally, so they are not part of the local `supabase test db` / `flutter test` run.
