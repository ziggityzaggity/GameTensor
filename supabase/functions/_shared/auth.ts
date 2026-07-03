// Reads the user id (JWT `sub`) from the Authorization header. The gateway runs
// with verify_jwt = true, so the signature is already validated before the
// function executes; we only need to decode the payload, not verify it. Returns
// null if the header is missing or malformed.
export function userIdFromAuthHeader(req: Request): string | null {
  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;

  const segments = auth.slice("Bearer ".length).split(".");
  if (segments.length !== 3) return null;

  try {
    const payload = JSON.parse(base64UrlDecode(segments[1]));
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

function base64UrlDecode(segment: string): string {
  const base64 = segment.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), "=");
  return atob(padded);
}
