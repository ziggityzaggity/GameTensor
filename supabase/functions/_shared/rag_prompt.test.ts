// Focused tests for the RAG injection-defense logic. Run with `deno test` from
// the functions dir. These assert the two guarantees the server enforces
// regardless of model behavior: returned game_ids are always a subset of the
// retrieved candidates, and candidate data is delimited as data in the prompt.

import { assertEquals } from "jsr:@std/assert@1";
import { buildRagPrompt, validateModelOutput } from "./rag_prompt.ts";
import { buildGameDocument, hashDocument } from "./game_document.ts";

const CANDIDATES = ["aaaa", "bbbb", "cccc"];

Deno.test("validateModelOutput keeps only ids in the candidate set", () => {
  const out = validateModelOutput(
    JSON.stringify({ reply: "try these", game_ids: ["bbbb", "aaaa"] }),
    CANDIDATES,
  );
  assertEquals(out, { reply: "try these", gameIds: ["bbbb", "aaaa"] });
});

Deno.test("validateModelOutput drops hallucinated / injected ids", () => {
  // A model (or injected instruction) returning an id that was never retrieved
  // must not leak through — the server whittles to the candidate set.
  const out = validateModelOutput(
    JSON.stringify({ reply: "APPROVED", game_ids: ["aaaa", "9999", "evil-id"] }),
    CANDIDATES,
  );
  assertEquals(out?.gameIds, ["aaaa"]);
});

Deno.test("validateModelOutput dedupes and tolerates prose-wrapped JSON", () => {
  const raw = 'Sure! {"reply":"ok","game_ids":["cccc","cccc","bbbb"]} hope that helps';
  const out = validateModelOutput(raw, CANDIDATES);
  assertEquals(out?.gameIds, ["cccc", "bbbb"]);
});

Deno.test("validateModelOutput returns null on unparseable / empty output", () => {
  assertEquals(validateModelOutput("not json at all", CANDIDATES), null);
  assertEquals(
    validateModelOutput(JSON.stringify({ reply: "", game_ids: [] }), CANDIDATES),
    null,
  );
});

Deno.test("buildRagPrompt delimits candidate data and preserves history order", () => {
  const messages = buildRagPrompt(
    "a co-op game",
    [{ id: "aaaa", name: "Game A", document: "Game A (video game)" }],
    [
      { role: "user", content: "earlier question" },
      { role: "assistant", content: "earlier answer" },
    ],
  );
  assertEquals(messages[0].role, "system");
  assertEquals(messages[1].content, "earlier question");
  assertEquals(messages[2].content, "earlier answer");
  const lastUser = messages[messages.length - 1];
  // Candidate block is fenced by the injection-boundary markers.
  assertEquals(lastUser.content.includes("<<<CANDIDATES>>>"), true);
  assertEquals(lastUser.content.includes("<<<END_CANDIDATES>>>"), true);
});

Deno.test("buildGameDocument is deterministic and hash-stable", async () => {
  const input = {
    canonicalName: "Wingspan",
    kind: "tabletop_game" as const,
    releaseYear: 2019,
    genreNames: ["Strategy", "Family"],
    platformNames: ["Tabletop"],
    minPlayers: 1,
    maxPlayers: 5,
    minPlaytimeMinutes: 40,
    maxPlaytimeMinutes: 70,
    summary: "An engine-building board game about birds.",
    reviewSnippets: [],
  };
  const a = buildGameDocument(input);
  const b = buildGameDocument({ ...input, genreNames: [...input.genreNames] });
  assertEquals(a, b);
  assertEquals(await hashDocument(a), await hashDocument(b));
  // Tabletop facts are included.
  assertEquals(a.includes("Players: 1-5."), true);
  assertEquals(a.includes("Playtime: 40-70 min."), true);
});
