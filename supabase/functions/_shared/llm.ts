// Chat LLM provider abstraction (docs/ml-workflows.md, provider table). The chat
// model is swappable via the OpenAI chat-completions wire format; embeddings are
// gte-small via Supabase.ai and deliberately NOT part of this interface (they are
// a different concern with a different, keyless runtime).
//
// Selection is by env: with an API key set we talk to an OpenAI-compatible
// endpoint (OpenRouter by default); with no key we fall back to a deterministic
// stub so the whole pipeline runs and is testable with zero secrets (CI, local).

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface ChatOptions {
  maxTokens?: number;
  temperature?: number;
}

export interface LlmProvider {
  chat(messages: ChatMessage[], opts?: ChatOptions): Promise<string>;
}

const DEFAULT_BASE_URL = "https://openrouter.ai/api/v1";
const DEFAULT_MODEL = "meta-llama/llama-3.3-70b-instruct:free";
const DEFAULT_MAX_TOKENS = 1024;

// OpenAI-compatible /chat/completions client. The same code targets OpenRouter,
// OpenAI, Ollama, LM Studio or vLLM by changing LLM_BASE_URL — maximum
// swappability. Upstream error bodies are logged but never surfaced to the
// caller (they can carry keys/URLs); the caller maps a throw to a generic 502.
export class OpenAiCompatibleProvider implements LlmProvider {
  constructor(
    private readonly apiKey: string,
    private readonly baseUrl: string = DEFAULT_BASE_URL,
    private readonly model: string = DEFAULT_MODEL,
  ) {}

  async chat(messages: ChatMessage[], opts: ChatOptions = {}): Promise<string> {
    const resp = await fetch(`${this.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages,
        max_tokens: opts.maxTokens ?? DEFAULT_MAX_TOKENS,
        temperature: opts.temperature ?? 0.4,
      }),
    });

    if (!resp.ok) {
      const detail = await resp.text().catch(() => "");
      console.error(`LLM upstream ${resp.status}: ${detail}`);
      throw new Error(`LLM upstream error ${resp.status}`);
    }

    const data = await resp.json();
    const content = data?.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      console.error("LLM response missing message content:", JSON.stringify(data));
      throw new Error("LLM response malformed");
    }
    return content;
  }
}

// Deterministic keyless provider: returns the JSON contract naming the first few
// candidates so the full retrieve→generate→persist pipeline is exercisable with
// no API key. It reads the candidate list the caller embeds in the final user
// message (see buildRagPrompt) so its answer is grounded in real retrieved ids,
// which also lets tests assert game_ids ⊆ candidates end-to-end.
export class StubLlmProvider implements LlmProvider {
  chat(messages: ChatMessage[]): Promise<string> {
    const candidates = parseStubCandidates(messages);
    const chosen = candidates.slice(0, 3);
    const reply = chosen.length
      ? `Based on the catalog, you might enjoy ${chosen
          .map((c) => c.name)
          .join(", ")}.`
      : "I couldn't find a matching game in the catalog for that request.";
    return Promise.resolve(
      JSON.stringify({ reply, game_ids: chosen.map((c) => c.id) }),
    );
  }
}

// Parses the "id\tname" candidate lines the prompt builder embeds between the
// CANDIDATES markers. Only used by the stub; the real model reads the prose.
function parseStubCandidates(
  messages: ChatMessage[],
): Array<{ id: string; name: string }> {
  const last = [...messages].reverse().find((m) => m.role === "user");
  if (!last) return [];
  const block = last.content.match(/<<<CANDIDATES>>>([\s\S]*?)<<<END_CANDIDATES>>>/);
  if (!block) return [];
  return block[1]
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const tab = line.indexOf("\t");
      return tab === -1
        ? null
        : { id: line.slice(0, tab).trim(), name: line.slice(tab + 1).trim() };
    })
    .filter((c): c is { id: string; name: string } => c !== null);
}

// Provider selection: real endpoint when LLM_API_KEY is present, stub otherwise.
export function createLlmProvider(): LlmProvider {
  const apiKey = Deno.env.get("LLM_API_KEY") ?? Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) return new StubLlmProvider();
  const baseUrl = Deno.env.get("LLM_BASE_URL") ?? DEFAULT_BASE_URL;
  const model = Deno.env.get("LLM_MODEL") ?? DEFAULT_MODEL;
  return new OpenAiCompatibleProvider(apiKey, baseUrl, model);
}
