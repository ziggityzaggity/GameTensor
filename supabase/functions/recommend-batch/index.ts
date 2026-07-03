// On-demand/cron recompute for the recommendation engine (docs/ml-workflows.md
// §2). NOT user-facing: like embed-games it authenticates via a shared
// CRON_SECRET header instead of a user JWT (config.toml sets verify_jwt = false
// for this function). All the work happens in SQL — this function just invokes
// recompute_recommendations() with the service role and relays its summary
// ({similarities, users_scored, recommendations}).

import { createAdminClient } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const json = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    });

  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  // Shared-secret gate: this function must never be callable by end users. A
  // missing/mismatched header is rejected before any work. CRON_SECRET is set in
  // Edge Function secrets, never shipped to the client.
  const expected = Deno.env.get("CRON_SECRET");
  if (!expected || req.headers.get("x-cron-secret") !== expected) {
    return json({ error: "unauthorized" }, 401);
  }

  try {
    const admin = createAdminClient();
    const { data, error } = await admin.rpc("recompute_recommendations");
    if (error) throw error;
    return json(data, 200);
  } catch (err) {
    console.error(err);
    return json({ error: "internal error" }, 500);
  }
});
