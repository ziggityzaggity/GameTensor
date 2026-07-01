-- Job queue coordinating IGDB/BGG upsert requests (search-triggered + cron-triggered)
-- through a single rate-limited path, per the ingestion strategy in the plan.
create table ingestion_jobs (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('igdb', 'bgg')),
  query text not null,
  status text not null default 'pending' check (status in ('pending', 'running', 'done', 'error')),
  attempts int not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now()
);

create index ingestion_jobs_status_idx on ingestion_jobs (status, next_attempt_at);

-- Cached upstream app tokens (e.g. IGDB's Twitch client-credentials token).
-- No client access at all; only Edge Functions using the service-role key touch this.
create table service_tokens (
  provider text primary key,
  access_token text not null,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table ingestion_jobs enable row level security;
alter table service_tokens enable row level security;
-- Intentionally no policies: service_role bypasses RLS entirely, and no policy
-- means authenticated/anon clients get zero access to either table.
