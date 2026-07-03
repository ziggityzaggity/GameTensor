// BoardGameGeek XML API2 client. No API key required, but some endpoints (notably
// collection requests, and occasionally `thing`) return 202 while BGG queues the
// request server-side and must be polled until a real response is ready.
// Verify current async/rate-limit behavior against BGG's XML API2 wiki at
// implementation time, per the plan's open-items list.
import { DOMParser, Element } from "https://deno.land/x/deno_dom@v0.1.45/deno-dom-wasm.ts";

const BGG_BASE_URL = "https://boardgamegeek.com/xmlapi2";

export interface BggSearchResult {
  id: number;
  name: string;
  yearPublished?: number;
}

export interface BggThingDetail {
  id: number;
  name: string;
  type: string;
  description?: string;
  image?: string;
  minPlayers?: number;
  maxPlayers?: number;
  minPlayTime?: number;
  maxPlayTime?: number;
  minAge?: number;
  rank?: number;
  averageRating?: number;
  categories: string[];
  mechanics: string[];
}

async function fetchWithRetry(url: string, maxAttempts = 5): Promise<string> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const resp = await fetch(url);
    if (resp.status === 202) {
      // BGG is preparing the response asynchronously; back off and retry.
      await new Promise((r) => setTimeout(r, attempt * 1000));
      continue;
    }
    if (!resp.ok) {
      throw new Error(`BGG request failed: ${resp.status} ${await resp.text()}`);
    }
    return await resp.text();
  }
  throw new Error(`BGG request did not resolve after ${maxAttempts} attempts (still 202): ${url}`);
}

function textOf(el: Element | null, attr = "value"): string | undefined {
  return el?.getAttribute(attr) ?? undefined;
}

// BGG descriptions arrive as HTML with escaped entities. Strip tags and decode
// the entities BGG actually emits so the stored `summary` is plain text, safe
// for any future renderer (Next.js frontend, email digests). Order matters:
// decode &amp; last so it can't resurrect other entities.
export function sanitizeDescription(raw: string): string {
  return raw
    .replace(/<[^>]*>/g, " ")
    .replace(/&#10;/g, "\n")
    .replace(/&mdash;/g, "—")
    .replace(/&ndash;/g, "–")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();
}

export async function searchBggGames(query: string): Promise<BggSearchResult[]> {
  const xml = await fetchWithRetry(
    `${BGG_BASE_URL}/search?query=${encodeURIComponent(query)}&type=boardgame`,
  );
  const doc = new DOMParser().parseFromString(xml, "text/xml");
  if (!doc) return [];

  const items = Array.from(doc.querySelectorAll("item"));
  return items.map((item) => ({
    id: Number(item.getAttribute("id")),
    name: textOf(item.querySelector("name")) ?? "Unknown",
    yearPublished: item.querySelector("yearpublished")
      ? Number(textOf(item.querySelector("yearpublished")))
      : undefined,
  }));
}

export async function getBggThing(id: number): Promise<BggThingDetail | null> {
  const xml = await fetchWithRetry(`${BGG_BASE_URL}/thing?id=${id}&stats=1`);
  const doc = new DOMParser().parseFromString(xml, "text/xml");
  const item = doc?.querySelector("item");
  if (!item) return null;

  const primaryName =
    Array.from(item.querySelectorAll("name")).find(
      (n) => n.getAttribute("type") === "primary",
    ) ?? item.querySelector("name");

  const links = Array.from(item.querySelectorAll("link"));
  const categories = links
    .filter((l) => l.getAttribute("type") === "boardgamecategory")
    .map((l) => l.getAttribute("value") ?? "");
  const mechanics = links
    .filter((l) => l.getAttribute("type") === "boardgamemechanic")
    .map((l) => l.getAttribute("value") ?? "");

  const rankEl = item.querySelector('rank[name="boardgame"]');
  const ratingEl = item.querySelector("ratings > average");

  const rawDescription = item.querySelector("description")?.textContent;

  return {
    id,
    name: textOf(primaryName) ?? "Unknown",
    type: item.getAttribute("type") ?? "boardgame",
    description: rawDescription ? sanitizeDescription(rawDescription) : undefined,
    image: item.querySelector("image")?.textContent,
    minPlayers: item.querySelector("minplayers") ? Number(textOf(item.querySelector("minplayers"))) : undefined,
    maxPlayers: item.querySelector("maxplayers") ? Number(textOf(item.querySelector("maxplayers"))) : undefined,
    minPlayTime: item.querySelector("minplaytime") ? Number(textOf(item.querySelector("minplaytime"))) : undefined,
    maxPlayTime: item.querySelector("maxplaytime") ? Number(textOf(item.querySelector("maxplaytime"))) : undefined,
    minAge: item.querySelector("minage") ? Number(textOf(item.querySelector("minage"))) : undefined,
    rank: rankEl && textOf(rankEl) !== "Not Ranked" ? Number(textOf(rankEl)) : undefined,
    averageRating: ratingEl ? Number(textOf(ratingEl)) : undefined,
    categories,
    mechanics,
  };
}
