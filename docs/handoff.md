# GameTensor — Handoff

Resume doc for continuing work on GameTensor with Claude. Last updated 2026-07-01.

## What this project is

Cross-platform (iOS/Android/Web) app for logging, reviewing, and discovering
games — both video games (Steam/PlayStation/Xbox/Nintendo/PC) and tabletop
games (board/card). Stack: **Flutter** client + **Supabase** (Postgres, Auth,
Storage, Edge Functions, pgvector). Catalog data comes from **IGDB** (video
games) and **BoardGameGeek XML API2** (tabletop). Console linking targets
**Xbox Live only** for v1. AI game-finder uses RAG over pgvector with a
swappable LLM provider.

The full architecture + phased roadmap lives in the approved plan:
`C:\Users\aliza\.claude\plans\i-want-to-make-squishy-hellman.md` — read it first.

## Current status: Phase 1 built and verified end-to-end

Phase 1 = auth, unified game catalog + search, game logging (completion label +
like/dislike + reviews), custom lists, and the manual-add onboarding flow.
It compiles, runs on web, and was verified against a live local Supabase stack
(signup + profile trigger, RLS reads/writes, RLS forgery block, catalog FTS).

Git history (branch `main`):
- `717ae50` Scaffold Phase 1 (Supabase migrations + Flutter app)
- `b825c51` Native platform folders, codegen, snake_case JSON fix
- `cba53c4` Supabase config schema fix + table-level grants for RLS

Working tree is clean as of handoff (except local-only, gitignored `app/env/dev.json`).

## Repo layout

```
/app                 Flutter app (lib/ is feature-first: core, data, features)
/supabase            migrations/ (0001-0009), functions/ (igdb-search, bgg-search), config.toml, seed.sql
/docs                this file
.claude/launch.json  `flutter run -d web-server` config for the preview tool
```

Key files:
- `supabase/migrations/0004_games_catalog.sql` — unified games schema (foundation)
- `supabase/migrations/0007_social_and_rls.sql` — `can_view_profile()` + all RLS policies
- `supabase/migrations/0009_grants.sql` — table grants (RLS needs these first)
- `app/lib/core/router/app_router.dart` — auth + onboarding redirect gates
- `app/lib/data/repositories/games_repository.dart` — local-first search w/ IGDB/BGG remote fallback
- `app/build.yaml` — `field_rename: snake` so models parse snake_case Postgres rows

## Toolchain (NOT on default PATH — prepend these each session)

```
Flutter 3.44.4 / Dart 3.12.2 : C:\Users\aliza\Documents\flutter\bin
Supabase CLI 2.109           : C:\Users\aliza\scoop\shims
Docker CLI (Desktop)         : C:\Program Files\Docker\Docker\resources\bin
```

PowerShell one-liner to set PATH for a session:
```powershell
$env:Path = "C:\Users\aliza\Documents\flutter\bin;C:\Program Files\Docker\Docker\resources\bin;C:\Users\aliza\scoop\shims;$env:Path"
```

## How to run it (from scratch)

1. **Start Docker Desktop** (wait for the daemon to be up).
2. **Start Supabase** (from repo root `C:\PROJECTS\GameTensor`):
   ```powershell
   supabase start          # or `supabase db reset` to reapply migrations + seed
   ```
   Copy the printed **PUBLISHABLE_KEY** (`sb_publishable_...`).
3. **Env file** — `app/env/dev.json` (gitignored; recreate if missing):
   ```json
   { "SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_ANON_KEY": "sb_publishable_..." }
   ```
   Note: bootstrap.dart maps this to supabase_flutter's `publishableKey` param, so use
   the `sb_publishable_...` value, not the legacy JWT anon key.
4. **Run the app** (from `app/`):
   ```powershell
   flutter run -d chrome --dart-define-from-file=env/dev.json
   # or -d web-server --web-port 8099 for headless
   ```

Local URLs: API `http://127.0.0.1:54321` · Studio `http://127.0.0.1:54323` · Mail `http://127.0.0.1:54324`

## Verify quickly

```powershell
cd C:\PROJECTS\GameTensor\app
flutter analyze          # should be clean
flutter test             # unit tests (model JSON + a widget)
```
After changing any freezed/json model or Riverpod provider, regenerate:
```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Gotchas already hit (don't re-discover these)

- **Grants before RLS**: this Supabase CLI's default privileges only grant
  anon/authenticated/service_role non-DML perms. Any new table needs DML grants
  (0009 adds `alter default privileges`, so *new* tables inherit them — but
  double-check with a REST read as anon if something 403s with code 42501).
- **snake_case JSON**: `build.yaml` handles it globally. New models just need
  `@freezed` + camelCase fields; don't hand-write `@JsonKey`.
- **Flutter web is canvas-rendered**: DOM-selector UI automation (preview_click/fill)
  doesn't work on it. Verify data flows via REST or Supabase Studio instead.
- **OAuth disabled locally**: Google/Apple providers are `enabled = false` in
  config.toml until real credentials are supplied.

## Next steps (pick up here)

> **See [demo-completion-plan.md](demo-completion-plan.md) for the full work
> order**: gap analysis, security audit (including 3 confirmed bugs in the
> committed migrations — fix those first), and milestone-by-milestone
> instructions to ship a deployed web demo. The list below is the short version.

Immediate wiring to make Phase 1 fully functional:
1. **IGDB/BGG live search** — create a Twitch dev app, set `TWITCH_CLIENT_ID` /
   `TWITCH_CLIENT_SECRET` (+ `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`) in
   `supabase/.env.local`, then `supabase functions serve igdb-search --env-file supabase/.env.local`.
   Test the `games_repository` remote-fallback path (searches beyond the 6 seed games).
2. **Google/Apple OAuth** — real credentials, flip `enabled = true` in config.toml,
   register the `io.supabase.gametensor://login-callback` deep link on iOS/Android.
3. **Interactive click-through** — manually walk signup → onboarding → search →
   log a game → create/reorder a list to confirm the UI wiring (couldn't be
   scripted due to canvas rendering).

Later phases (architecture already in the plan + schema tables already exist):
- **Phase 2** Xbox linking (`linked_accounts`, `xbox_title_history` tables ready)
- **Phase 3** Friends/social (`friendships` + `friend_edges` ready; RLS friend-branch ready)
- **Phase 4** RAG assistant (`game_embeddings`, `rag_chat_*`; pgvector installed)
- **Phase 5** Recommendation engine (`recommendation_impressions`, `*_similarity_cache`)

## Prompt to resume with Claude

> Read docs/handoff.md and the plan at
> C:\Users\aliza\.claude\plans\i-want-to-make-squishy-hellman.md, then help me
> [wire up IGDB/BGG live search | do the interactive click-through | start Phase 2 Xbox linking].
