// Normalizes upstream genre/category strings from IGDB and BGG into the shared
// `genres.code` taxonomy (see migrations/0002_enums_and_lookups.sql) so cross-catalog
// genre search works without the client knowing which source a game came from.
const IGDB_GENRE_MAP: Record<string, string> = {
  "role-playing (rpg)": "rpg",
  "shooter": "shooter",
  "platform": "platformer",
  "puzzle": "puzzle",
  "racing": "racing",
  "real time strategy (rts)": "strategy",
  "turn-based strategy (tbs)": "strategy",
  "strategy": "strategy",
  "simulator": "simulation",
  "sport": "sports",
  "adventure": "adventure",
  "hack and slash/beat 'em up": "action",
  "arcade": "action",
  "horror": "horror",
  "fighting": "action",
};

const BGG_CATEGORY_MECHANIC_MAP: Record<string, string> = {
  "strategy game": "strategy",
  "card game": "card_game",
  "deck bag and pool building": "deck_building",
  "cooperative game": "cooperative",
  "party game": "party",
  "family game": "family",
  "wargame": "strategy",
  "abstract strategy": "strategy",
};

export function mapIgdbGenre(igdbGenreName: string): string | null {
  return IGDB_GENRE_MAP[igdbGenreName.trim().toLowerCase()] ?? null;
}

export function mapBggCategoryOrMechanic(name: string): string | null {
  return BGG_CATEGORY_MECHANIC_MAP[name.trim().toLowerCase()] ?? null;
}
