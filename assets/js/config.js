// Copy this file's values into a deployment-time config override if desired.
// The Supabase publishable/anon key is safe to expose; never put a service-role key here.
export const SUPABASE_URL = window.__CLOUD_COLLAB_SUPABASE_URL__ || "https://YOUR-PROJECT.supabase.co";
export const SUPABASE_ANON_KEY = window.__CLOUD_COLLAB_SUPABASE_ANON_KEY__ || "YOUR-PUBLISHABLE-ANON-KEY";
