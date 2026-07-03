// Backfill/cron embedder for the RAG corpus (docs/ml-workflows.md §1.2). NOT
// user-facing: it is invoked on a schedule or manually for backfill, so it
// authenticates via a shared CRON_SECRET header instead of a user JWT
// (config.toml sets verify_jwt = false for this function). It builds each game's
// document, embeds it with gte-small via Supabase.ai, and upserts into
// game_embeddings, skipping games whose source_text_hash is unchanged.
//
// Returns {embedded, skipped, remaining} so a backfill loop can drive it until
// remaining = 0. Batch capped at 50 per call to stay within function time limits.

import { createAdminClient } from "../_shared/supabase_admin.ts";
import { buildDocumentsForGames } from "../_shared/game_corpus.ts";
import { hashDocument } from "../_shared/game_document.ts";

const EMBEDDING_MODEL = "gte-small";
const MAX_BATCH = 50;

// deno-lint-ignore no-explicit-any
declare const Supabase: any;

Deno.serve(async (req) => {
  const json = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    });

  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  // Shared-secret gate: this function must never be callable by end users. A
  // missing/mismatched header is rejected before any work. CRON_SECRET is set in
  // Edge Function secrets, never shipped to the client.
  const expected = Deno.env.get("CRON_SECRET");
  if (!expected || req.headers.get("x-cron-secret") !== expected) {
    return json({ error: "unauthorized" }, 401);
  }

  try {
    const admin = createAdminClient();

    // Existing hashes so we can skip unchanged games without re-embedding.
    const { data: existing, error: existErr } = await admin
      .from("game_embeddings")
      .select("game_id, source_text_hash");
    if (existErr) throw existErr;
    const currentHash = new Map(
      (existing ?? []).map((r) => [r.game_id, r.source_text_hash]),
    );

    const documents = await buildDocumentsForGames(admin);

    // Determine which games are stale (missing or changed hash) before batching.
    const stale: { id: string; name: string; document: string; hash: string }[] = [];
    for (const doc of documents) {
      const hash = await hashDocument(doc.document);
      if (currentHash.get(doc.id) !== hash) {
        stale.push({ ...doc, hash });
      }
    }

    const skipped = documents.length - stale.length;
    const batch = stale.slice(0, MAX_BATCH);

    // gte-small runs inside the Edge Runtime (Supabase.ai), returning a 384-float
    // mean-pooled, normalized vector — same embedding space as the query in
    // rag-chat, so retrieval is semantic with zero external calls.
    const session = new Supabase.ai.Session(EMBEDDING_MODEL);
    let embedded = 0;

    for (const game of batch) {
      const embedding: number[] = await session.run(game.document, {
        mean_pool: true,
        normalize: true,
      });

      const { error: upsertErr } = await admin.from("game_embeddings").upsert(
        {
          game_id: game.id,
          embedding: JSON.stringify(embedding),
          embedding_model: EMBEDDING_MODEL,
          source_text_hash: game.hash,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "game_id" },
      );

      if (upsertErr) {
        console.error(`failed upserting embedding for ${game.id}:`, upsertErr);
        continue;
      }
      embedded++;
    }

    const remaining = stale.length - embedded;
    return json({ embedded, skipped, remaining }, 200);
  } catch (err) {
    console.error(err);
    return json({ error: "internal error" }, 500);
  }
});
