import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const TWITCH_TOKEN_URL = "https://id.twitch.tv/oauth2/token";
const IGDB_API_URL = "https://api.igdb.com/v4";

export interface IgdbGame {
  id: number;
  name: string;
  slug: string;
  summary?: string;
  first_release_date?: number; // unix seconds
  cover?: { url: string };
  genres?: { name: string }[];
  platforms?: { id: number; name: string }[];
  franchise?: { name: string };
  game_modes?: { name: string }[];
  esrb?: { rating: string };
  total_rating?: number;
}

// Fetches (and caches in `service_tokens`) a Twitch client-credentials app token.
// IGDB rides on Twitch's OAuth2 app tokens; verify current TTL/rate limits against
// Twitch developer docs at implementation time, as noted in the plan.
export async function getIgdbToken(admin: SupabaseClient): Promise<string> {
  const { data: cached } = await admin
    .from("service_tokens")
    .select("access_token, expires_at")
    .eq("provider", "igdb")
    .maybeSingle();

  if (cached && new Date(cached.expires_at).getTime() > Date.now() + 60_000) {
    return cached.access_token;
  }

  const clientId = Deno.env.get("TWITCH_CLIENT_ID");
  const clientSecret = Deno.env.get("TWITCH_CLIENT_SECRET");
  if (!clientId || !clientSecret) {
    throw new Error("TWITCH_CLIENT_ID and TWITCH_CLIENT_SECRET must be set");
  }

  const resp = await fetch(
    `${TWITCH_TOKEN_URL}?client_id=${clientId}&client_secret=${clientSecret}&grant_type=client_credentials`,
    { method: "POST" },
  );
  if (!resp.ok) {
    throw new Error(`Twitch token request failed: ${resp.status} ${await resp.text()}`);
  }
  const body = await resp.json();
  const expiresAt = new Date(Date.now() + body.expires_in * 1000).toISOString();

  await admin.from("service_tokens").upsert({
    provider: "igdb",
    access_token: body.access_token,
    expires_at: expiresAt,
    updated_at: new Date().toISOString(),
  });

  return body.access_token;
}

// Minimal Apicalypse query builder for the fields/search/limit shape IGDB expects.
export function buildApicalypseQuery(opts: {
  fields: string[];
  search?: string;
  where?: string;
  limit?: number;
}): string {
  const parts = [`fields ${opts.fields.join(",")};`];
  if (opts.search) parts.push(`search "${opts.search.replace(/"/g, '\\"')}";`);
  if (opts.where) parts.push(`where ${opts.where};`);
  parts.push(`limit ${opts.limit ?? 20};`);
  return parts.join(" ");
}

const GAME_FIELDS = [
  "name",
  "slug",
  "summary",
  "first_release_date",
  "cover.url",
  "genres.name",
  "platforms.id",
  "platforms.name",
  "franchise.name",
  "game_modes.name",
  "esrb.rating",
  "total_rating",
];

export async function searchIgdbGames(
  admin: SupabaseClient,
  clientId: string,
  query: string,
  limit = 20,
): Promise<IgdbGame[]> {
  const token = await getIgdbToken(admin);
  const body = buildApicalypseQuery({ fields: GAME_FIELDS, search: query, limit });

  const resp = await fetch(`${IGDB_API_URL}/games`, {
    method: "POST",
    headers: {
      "Client-ID": clientId,
      Authorization: `Bearer ${token}`,
      "Content-Type": "text/plain",
    },
    body,
  });

  if (!resp.ok) {
    throw new Error(`IGDB request failed: ${resp.status} ${await resp.text()}`);
  }

  return await resp.json();
}
