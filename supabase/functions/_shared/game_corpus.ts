// Loads the per-game facts that buildGameDocument() needs, from our own schema,
// via the service-role client. Shared by embed-games (to build+hash documents
// for embedding) and available to rag-chat (to render candidate documents in the
// prompt). Only PUBLIC data is read: game metadata, and review snippets whose
// author profile is public (cross-user privacy, demo-completion-plan §3.7).

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { buildGameDocument, type GameDocInput } from "./game_document.ts";

interface GameRow {
  id: string;
  kind: "video_game" | "tabletop_game";
  canonical_name: string;
  release_date: string | null;
  summary: string | null;
  game_genres: { genres: { display_name: string } | null }[];
  game_platforms: { platforms: { display_name: string } | null }[];
  tabletop_game_details: {
    min_players: number | null;
    max_players: number | null;
    min_playtime_minutes: number | null;
    max_playtime_minutes: number | null;
  } | null;
}

const GAME_SELECT =
  "id, kind, canonical_name, release_date, summary, " +
  "game_genres(genres(display_name)), " +
  "game_platforms(platforms(display_name)), " +
  "tabletop_game_details(min_players, max_players, min_playtime_minutes, max_playtime_minutes)";

// Up to 3 public review snippets per game. Author visibility is enforced by
// joining only profiles with profile_visibility = 'public' (inner join), so
// friends-only / private authors never enter the corpus.
async function loadPublicReviewSnippets(
  admin: SupabaseClient,
  gameIds: string[],
): Promise<Map<string, string[]>> {
  const byGame = new Map<string, string[]>();
  if (!gameIds.length) return byGame;

  const { data, error } = await admin
    .from("reviews")
    .select("game_id, body, profiles!reviews_user_id_fkey!inner(profile_visibility)")
    .in("game_id", gameIds)
    .is("deleted_at", null)
    .eq("profiles.profile_visibility", "public")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("failed loading review snippets:", error);
    return byGame;
  }

  for (const row of data ?? []) {
    const list = byGame.get(row.game_id) ?? [];
    if (list.length < 3 && typeof row.body === "string") {
      list.push(row.body);
      byGame.set(row.game_id, list);
    }
  }
  return byGame;
}

function toDocInput(row: GameRow, reviewSnippets: string[]): GameDocInput {
  return {
    canonicalName: row.canonical_name,
    kind: row.kind,
    releaseYear: row.release_date ? Number(row.release_date.slice(0, 4)) : null,
    genreNames: row.game_genres
      .map((g) => g.genres?.display_name)
      .filter((n): n is string => Boolean(n)),
    platformNames: row.game_platforms
      .map((p) => p.platforms?.display_name)
      .filter((n): n is string => Boolean(n)),
    minPlayers: row.tabletop_game_details?.min_players ?? null,
    maxPlayers: row.tabletop_game_details?.max_players ?? null,
    minPlaytimeMinutes: row.tabletop_game_details?.min_playtime_minutes ?? null,
    maxPlaytimeMinutes: row.tabletop_game_details?.max_playtime_minutes ?? null,
    summary: row.summary,
    reviewSnippets,
  };
}

export interface GameCorpusEntry {
  id: string;
  name: string;
  document: string;
}

// Builds documents for the given game ids (all games if `ids` omitted). Returns
// entries in the same order the DB returns rows.
export async function buildDocumentsForGames(
  admin: SupabaseClient,
  ids?: string[],
): Promise<GameCorpusEntry[]> {
  let query = admin.from("games").select(GAME_SELECT);
  if (ids) query = query.in("id", ids);
  const { data, error } = await query;
  if (error) throw error;

  const rows = (data ?? []) as unknown as GameRow[];
  const snippets = await loadPublicReviewSnippets(admin, rows.map((r) => r.id));

  return rows.map((row) => ({
    id: row.id,
    name: row.canonical_name,
    document: buildGameDocument(toDocInput(row, snippets.get(row.id) ?? [])),
  }));
}
