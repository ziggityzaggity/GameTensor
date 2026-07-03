// User-facing RAG game-finder (docs/ml-workflows.md §1.3-1.5, demo-completion
// §3.7). Flow: validate → session → embed query (gte-small) → match_games RPC →
// filter out the user's completed games, keep top 8 → build grounded prompt from
// delimited candidate data → LlmProvider.chat → validate+whittle game_ids to the
// candidate set → persist user+assistant turns → return {reply, game_ids,
// sessionId}. verify_jwt = true (config.toml); we still decode the JWT to get the
// user id for ownership and rate limiting.

import { createAdminClient } from "../_shared/supabase_admin.ts";
import { corsHeaders, handlePreflight } from "../_shared/cors.ts";
import { userIdFromAuthHeader } from "../_shared/auth.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { buildDocumentsForGames } from "../_shared/game_corpus.ts";
import { createLlmProvider } from "../_shared/llm.ts";
import {
  buildRagPrompt,
  type Candidate,
  validateModelOutput,
} from "../_shared/rag_prompt.ts";

const RATE_LIMIT = 20; // messages per user per hour
const RATE_WINDOW_SECONDS = 3600;
const RETRIEVE_COUNT = 24;
const CANDIDATE_COUNT = 8;
const HISTORY_TURNS = 10;
const MESSAGE_MAX = 2000;

// deno-lint-ignore no-explicit-any
declare const Supabase: any;

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  const cors = corsHeaders(req);
  const json = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "Content-Type": "application/json" },
    });

  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const userId = userIdFromAuthHeader(req);
  if (!userId) return json({ error: "unauthorized" }, 401);

  try {
    const body = await req.json();
    const message = typeof body?.message === "string" ? body.message.trim() : "";
    if (message.length < 1 || message.length > MESSAGE_MAX) {
      return json({ error: `message must be 1-${MESSAGE_MAX} characters` }, 400);
    }
    const requestedSessionId =
      typeof body?.sessionId === "string" ? body.sessionId : null;

    const admin = createAdminClient();

    // Cost/abuse cap: 20 messages/user/hour (demo-completion §3.5). Fail-closed.
    const allowed = await checkRateLimit(admin, userId, "rag-chat", RATE_LIMIT, RATE_WINDOW_SECONDS);
    if (!allowed) return json({ error: "rate limit exceeded" }, 429);

    const sessionId = await resolveSession(admin, userId, requestedSessionId);
    if (!sessionId) return json({ error: "session not found" }, 404);

    // Query embedding shares gte-small with the corpus — same space, no external
    // call. Cast to the pgvector literal the RPC expects.
    const session = new Supabase.ai.Session("gte-small");
    const queryEmbedding: number[] = await session.run(message, {
      mean_pool: true,
      normalize: true,
    });

    // Retrieval runs over PUBLIC game embeddings, so using the service client is
    // acceptable (no per-user rows are involved); the match_games RPC is
    // SECURITY INVOKER and would also work under a user-scoped client. We then
    // post-filter with the requesting user's OWN completed games only — their
    // private logs inform filtering but never enter the prompt.
    const { data: matches, error: matchErr } = await admin.rpc("match_games", {
      query_embedding: JSON.stringify(queryEmbedding),
      match_count: RETRIEVE_COUNT,
    });
    if (matchErr) throw matchErr;

    const completed = await loadCompletedGameIds(admin, userId);
    const rankedIds = (matches ?? [])
      .map((m: { game_id: string }) => m.game_id)
      .filter((id: string) => !completed.has(id))
      .slice(0, CANDIDATE_COUNT);

    const candidates = await buildCandidates(admin, rankedIds);
    const history = await loadHistory(admin, sessionId);

    const prompt = buildRagPrompt(message, candidates, history);

    // The assistant has NO tools; injected instructions in candidate documents
    // can at worst produce bad text. Returned ids are re-validated below.
    let output;
    try {
      const provider = createLlmProvider();
      const raw = await provider.chat(prompt, { maxTokens: 1024 });
      output = validateModelOutput(raw, candidates.map((c) => c.id));
    } catch (err) {
      // Never leak the upstream provider body; log server-side, generic 502.
      console.error("LLM provider failed:", err);
      return json({ error: "assistant temporarily unavailable" }, 502);
    }

    if (!output) {
      return json({ error: "assistant returned an unusable response" }, 502);
    }

    // Persist both turns with the retrieved ids for auditability (§3.7).
    await admin.from("rag_chat_messages").insert([
      { session_id: sessionId, role: "user", content: message, retrieved_game_ids: rankedIds },
      { session_id: sessionId, role: "assistant", content: output.reply, retrieved_game_ids: output.gameIds },
    ]);

    return json({ reply: output.reply, game_ids: output.gameIds, sessionId }, 200);
  } catch (err) {
    console.error(err);
    return json({ error: "internal error" }, 500);
  }
});

// Reuses the caller's session when they own it, else creates a fresh one. The
// service client bypasses RLS, so ownership is checked explicitly here.
async function resolveSession(
  // deno-lint-ignore no-explicit-any
  admin: any,
  userId: string,
  requestedSessionId: string | null,
): Promise<string | null> {
  if (requestedSessionId) {
    const { data } = await admin
      .from("rag_chat_sessions")
      .select("id")
      .eq("id", requestedSessionId)
      .eq("user_id", userId)
      .maybeSingle();
    return data ? data.id : null;
  }
  const { data, error } = await admin
    .from("rag_chat_sessions")
    .insert({ user_id: userId })
    .select("id")
    .single();
  if (error) throw error;
  return data.id;
}

// The requesting user's completed games — excluded from recommendations. Only
// the caller's own logs are read (privacy: never another user's data).
async function loadCompletedGameIds(
  // deno-lint-ignore no-explicit-any
  admin: any,
  userId: string,
): Promise<Set<string>> {
  // completion_status ids 5 (completed_main) and 6 (completed_100) per 0002.
  const { data, error } = await admin
    .from("user_game_logs")
    .select("game_id")
    .eq("user_id", userId)
    .in("completion_status_id", [5, 6]);
  if (error) {
    console.error("failed loading completed games:", error);
    return new Set();
  }
  return new Set((data ?? []).map((r: { game_id: string }) => r.game_id));
}

async function buildCandidates(
  // deno-lint-ignore no-explicit-any
  admin: any,
  ids: string[],
): Promise<Candidate[]> {
  if (!ids.length) return [];
  const entries = await buildDocumentsForGames(admin, ids);
  const byId = new Map(entries.map((e) => [e.id, e]));
  // Preserve retrieval ranking order (buildDocumentsForGames returns DB order).
  return ids
    .map((id) => byId.get(id))
    .filter((e): e is NonNullable<typeof e> => Boolean(e))
    .map((e) => ({ id: e.id, name: e.name, document: e.document }));
}

async function loadHistory(
  // deno-lint-ignore no-explicit-any
  admin: any,
  sessionId: string,
): Promise<{ role: "user" | "assistant"; content: string }[]> {
  const { data, error } = await admin
    .from("rag_chat_messages")
    .select("role, content")
    .eq("session_id", sessionId)
    .order("created_at", { ascending: false })
    .limit(HISTORY_TURNS);
  if (error) {
    console.error("failed loading history:", error);
    return [];
  }
  // Fetched newest-first for the LIMIT; reverse to chronological for the prompt.
  return (data ?? [])
    .reverse()
    .map((m: { role: "user" | "assistant"; content: string }) => ({
      role: m.role,
      content: m.content,
    }));
}
