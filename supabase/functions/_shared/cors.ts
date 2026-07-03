// CORS headers restricted to an allowlist. ALLOWED_ORIGINS is a comma-separated
// env var; the browser dev server default is localhost:8099. The request Origin
// is echoed back only when it is in the allowlist, so unknown origins get no
// Access-Control-Allow-Origin and the browser blocks them.
const DEFAULT_ALLOWED = "http://localhost:8099,http://127.0.0.1:8099";

function allowedOrigins(): string[] {
  return (Deno.env.get("ALLOWED_ORIGINS") ?? DEFAULT_ALLOWED)
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);
}

export function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
  if (allowedOrigins().includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

// Returns a 204 preflight response for OPTIONS, or null to continue handling.
export function handlePreflight(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }
  return null;
}
