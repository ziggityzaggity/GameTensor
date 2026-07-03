import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Fixed-window per-user rate limit against function_rate_limits (RLS deny-all,
// service-role only). Buckets requests into windowSeconds slots and atomically
// increments the counter for the current bucket. Returns true if the request is
// within limit, false if it should be rejected (HTTP 429).
export async function checkRateLimit(
  admin: SupabaseClient,
  userId: string,
  functionName: string,
  limit: number,
  windowSeconds: number,
): Promise<boolean> {
  const windowMs = windowSeconds * 1000;
  const windowStart = new Date(Math.floor(Date.now() / windowMs) * windowMs).toISOString();

  // Upsert-or-increment in one round trip: the insert seeds count=1, and the
  // conflict path bumps the existing counter so concurrent calls can't race
  // past the limit via read-then-write.
  const { data, error } = await admin.rpc("increment_rate_limit", {
    p_user_id: userId,
    p_function_name: functionName,
    p_window_start: windowStart,
  });

  if (error) {
    console.error("rate limit check failed:", error);
    // Fail closed: a broken limiter must not become an open door.
    return false;
  }

  return (data as number) <= limit;
}
