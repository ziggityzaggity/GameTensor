// Search-triggered upsert-on-demand for tabletop games (mirrors igdb-search; see
// plan section "IGDB + BGG Ingestion"). BGG's search endpoint only returns id/name,
// so each match is followed by a `thing` lookup for full detail before upserting.
import { createAdminClient } from "../_shared/supabase_admin.ts";
import { searchBggGames, getBggThing } from "../_shared/bgg_client.ts";
import { mapBggCategoryOrMechanic } from "../_shared/genre_mapping.ts";
import { corsHeaders, handlePreflight } from "../_shared/cors.ts";
import { userIdFromAuthHeader } from "../_shared/auth.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

const TABLETOP_PLATFORM_ID = 9;
const MAX_RESULTS = 10; // cap thing-lookup fan-out per search to stay within BGG's informal rate limits
const RATE_LIMIT = 10; // searches per user per minute
const RATE_WINDOW_SECONDS = 60;

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  const cors = corsHeaders(req);
  const json = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "Content-Type": "application/json" },
    });

  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  try {
    const { query } = await req.json();
    if (typeof query !== "string" || query.trim().length < 2 || query.trim().length > 100) {
      return json({ error: "query must be a string of 2-100 characters" }, 400);
    }

    const admin = createAdminClient();

    const userId = userIdFromAuthHeader(req);
    if (userId) {
      const allowed = await checkRateLimit(admin, userId, "bgg-search", RATE_LIMIT, RATE_WINDOW_SECONDS);
      if (!allowed) {
        return json({ error: "rate limit exceeded" }, 429);
      }
    }

    const searchResults = await searchBggGames(query.trim());
    const upsertedIds: string[] = [];

    for (const searchResult of searchResults.slice(0, MAX_RESULTS)) {
      const detail = await getBggThing(searchResult.id);
      if (!detail) continue;

      const slug = detail.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, "");

      const { data: gameRow, error: gameErr } = await admin
        .from("games")
        .upsert(
          {
            kind: "tabletop_game",
            canonical_name: detail.name,
            slug: `${slug}-${detail.id}`,
            summary: detail.description ?? null,
            cover_image_url: detail.image ?? null,
            bgg_id: detail.id,
            popularity_score: detail.averageRating ?? null,
          },
          { onConflict: "bgg_id" },
        )
        .select("id")
        .single();

      if (gameErr || !gameRow) {
        console.error(`Failed to upsert bgg game ${detail.id}:`, gameErr);
        continue;
      }

      await admin.from("tabletop_game_details").upsert({
        game_id: gameRow.id,
        bgg_type: detail.type,
        min_players: detail.minPlayers ?? null,
        max_players: detail.maxPlayers ?? null,
        min_playtime_minutes: detail.minPlayTime ?? null,
        max_playtime_minutes: detail.maxPlayTime ?? null,
        min_age: detail.minAge ?? null,
        bgg_rank: detail.rank ?? null,
        bgg_average_rating: detail.averageRating ?? null,
      });

      await admin
        .from("game_platforms")
        .upsert({ game_id: gameRow.id, platform_id: TABLETOP_PLATFORM_ID }, { onConflict: "game_id,platform_id" });

      const upstreamTags = [...detail.categories, ...detail.mechanics];
      if (upstreamTags.length) {
        const { data: genreLookup } = await admin.from("genres").select("id, code");
        const genreCodeToId = new Map(genreLookup?.map((g) => [g.code, g.id]) ?? []);
        const genreRows = upstreamTags
          .map((tag) => mapBggCategoryOrMechanic(tag))
          .filter((code): code is string => Boolean(code))
          .map((code) => genreCodeToId.get(code))
          .filter((id): id is number => Boolean(id))
          .map((genre_id) => ({ game_id: gameRow.id, genre_id }));
        if (genreRows.length) {
          await admin.from("game_genres").upsert(genreRows, { onConflict: "game_id,genre_id" });
        }
      }

      upsertedIds.push(gameRow.id);
    }

    const { data: results } = await admin
      .from("games")
      .select("*, tabletop_game_details(*), game_genres(genre_id)")
      .in("id", upsertedIds);

    return json({ results: results ?? [] }, 200);
  } catch (err) {
    // Log detail server-side only; upstream (BGG) error bodies may carry URLs
    // and must never reach the client.
    console.error(err);
    return json({ error: "internal error" }, 500);
  }
});
