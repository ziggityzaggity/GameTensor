-- Core extensions used across all phases.
-- vector is installed now (Phase 1) even though it's unused until Phase 4 so later
-- migrations never need to worry about extension-install ordering.
create extension if not exists pgcrypto with schema extensions;
create extension if not exists vector with schema extensions;
create extension if not exists pg_trgm with schema extensions;
