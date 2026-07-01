import { createClient } from "jsr:@supabase/supabase-js@2";

// Service-role client for Edge Functions: bypasses RLS, used only server-side
// for catalog upserts and reading/writing secret-holding tables.
export function createAdminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set");
  }
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
}
