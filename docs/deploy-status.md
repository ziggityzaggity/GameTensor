# GameTensor — Deploy Status: LIVE

**Production app: https://gametensor.vercel.app**

## What's live and verified end-to-end
- **Frontend**: Flutter Web on Vercel (team PyChess, project `gametensor`),
  static prebuilt build with SPA rewrite + security headers (HSTS, nosniff,
  frame-deny, referrer/permissions policy). Bundle contains only the publishable
  key (no secrets).
- **Backend**: Supabase project `gametensor` (`guhayxjezauhigybwmib`,
  `https://guhayxjezauhigybwmib.supabase.co`), region us-east-1. All 16
  migrations applied; 6 seed games; 6 gte-small embeddings; security advisor
  clean of errors.
- **Edge Functions** (all ACTIVE): igdb-search, bgg-search, rag-chat
  (verify_jwt), embed-games, recommend-batch (CRON_SECRET-gated).
- **Secrets**: CRON_SECRET, ALLOWED_ORIGINS (→ the Vercel origins) set.
- **Auth**: email confirmation OFF (instant signup), site_url + redirect
  allowlist → Vercel, password min length 8.

Live smoke test passed: signup → profile trigger → RLS blocks lookup-table
writes (403) → log a game (201) → AI Finder retrieves Wingspan for "bird themed
board game" → cold-start "For You" rail populated by the trigger. CORS echoes
the deployed origin and blocks others.

## Two real bugs the smoke test caught (fixed: migrations 0015, 0016)
- Long-email signups failed (auto-username exceeded the 30-char constraint).
- AI chat 500'd (0014 over-pinned match_games' search_path, hiding the pgvector
  `<=>` operator that lives in the `extensions` schema).

## Free-tier caveats
- **Project auto-pauses after ~1 week idle.** If the app shows connection
  errors later, restore it: Supabase dashboard → project → Restore (or
  `POST /v1/projects/guhayxjezauhigybwmib/restore` with an access token). Data
  is retained across pause.
- **Leaked-password protection (HIBP)** is Pro-only (advisor WARN); left off.
- Supabase Auth rate-limits signups per IP (a handful/hour) — normal.

## Optional add-ons (not needed for the demo; graceful fallbacks in place)
- **Twitch (IGDB) live search** — set `TWITCH_CLIENT_ID` / `TWITCH_CLIENT_SECRET`
  in Edge Function secrets. Until then, search covers the 6 seed games.
- **Real chat LLM** — set `OPENROUTER_API_KEY` (+ optional `LLM_MODEL`). Until
  then, the AI Finder uses the deterministic stub (grounded, canned phrasing)
  over real semantic retrieval.
- **Google sign-in** — you're configuring the Google Cloud OAuth client; enable
  the provider in Supabase Auth once you have the client id/secret. The app's
  "Continue with Google" button + redirect already exist.

## Re-deploy notes
- Frontend: `flutter build web --release --dart-define-from-file=env/prod.json`
  then `vercel deploy --prod` (project already linked; token required).
- DB changes: add a migration and `supabase db push` (or apply via the dashboard).
