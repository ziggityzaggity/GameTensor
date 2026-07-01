// Search-triggered upsert-on-demand for video games (see plan section "IGDB + BGG
// Ingestion"). Called by the Flutter client's games_repository when a local Postgres
// search returns few/no hits. Always upserts into `games`/`video_game_details`/
// `game_platforms`/`game_genres` and returns the resulting rows, so the client keeps
// reading from our own schema rather than IGDB directly.
import { createAdminClient } from "../_shared/supabase_admin.ts";
import { searchIgdbGames } from "../_shared/igdb_client.ts";
import { mapIgdbGenre } from "../_shared/genre_mapping.ts";

const PLATFORM_NAME_TO_ID: Record<string, number> = {
  "pc (microsoft windows)": 1,
  "playstation 5": 2,
  "playstation 4": 3,
  "xbox series x|s": 4,
  "xbox one": 5,
  "nintendo switch": 6,
  "ios": 7,
  "android": 8,
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const { query } = await req.json();
    if (!query || typeof query !== "string") {
      return new Response(JSON.stringify({ error: "query is required" }), { status: 400 });
    }

    const clientId = Deno.env.get("TWITCH_CLIENT_ID");
    if (!clientId) throw new Error("TWITCH_CLIENT_ID must be set");

    const admin = createAdminClient();
    const igdbGames = await searchIgdbGames(admin, clientId, query);

    const upsertedIds: string[] = [];

    for (const igdbGame of igdbGames) {
      const { data: gameRow, error: gameErr } = await admin
        .from("games")
        .upsert(
          {
            kind: "video_game",
            canonical_name: igdbGame.name,
            slug: igdbGame.slug,
            summary: igdbGame.summary ?? null,
            release_date: igdbGame.first_release_date
              ? new Date(igdbGame.first_release_date * 1000).toISOString().slice(0, 10)
              : null,
            cover_image_url: igdbGame.cover?.url
              ? `https:${igdbGame.cover.url.replace("t_thumb", "t_cover_big")}`
              : null,
            igdb_id: igdbGame.id,
            popularity_score: igdbGame.total_rating ?? null,
          },
          { onConflict: "igdb_id" },
        )
        .select("id")
        .single();

      if (gameErr || !gameRow) {
        console.error(`Failed to upsert igdb game ${igdbGame.id}:`, gameErr);
        continue;
      }

      await admin.from("video_game_details").upsert({
        game_id: gameRow.id,
        igdb_slug: igdbGame.slug,
        franchise: igdbGame.franchise?.name ?? null,
        game_modes: igdbGame.game_modes?.map((m) => m.name) ?? [],
        esrb_rating: igdbGame.esrb?.rating ?? null,
        metacritic_score: igdbGame.total_rating ? Math.round(igdbGame.total_rating) : null,
      });

      if (igdbGame.platforms?.length) {
        const platformRows = igdbGame.platforms
          .map((p) => PLATFORM_NAME_TO_ID[p.name.toLowerCase()])
          .filter((id): id is number => Boolean(id))
          .map((platform_id) => ({ game_id: gameRow.id, platform_id }));
        if (platformRows.length) {
          await admin.from("game_platforms").upsert(platformRows, { onConflict: "game_id,platform_id" });
        }
      }

      if (igdbGame.genres?.length) {
        const { data: genreLookup } = await admin.from("genres").select("id, code");
        const genreCodeToId = new Map(genreLookup?.map((g) => [g.code, g.id]) ?? []);
        const genreRows = igdbGame.genres
          .map((g) => mapIgdbGenre(g.name))
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
      .select("*, video_game_details(*), game_platforms(platform_id), game_genres(genre_id)")
      .in("id", upsertedIds);

    return new Response(JSON.stringify({ results: results ?? [] }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
