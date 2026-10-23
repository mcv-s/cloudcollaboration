import { createClient } from "@supabase/supabase-js";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";
export const isConfigured = !SUPABASE_URL.includes("YOUR-PROJECT") && !SUPABASE_ANON_KEY.includes("YOUR-");
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } });
