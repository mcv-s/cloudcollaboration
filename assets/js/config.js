// Supabase settings live in the repository-root SUPABASE.json.
// Only the project URL and publishable/anon key belong in that file.
const fallback = {
  project: {
    url: window.__CLOUD_COLLAB_SUPABASE_URL__ || "https://YOUR-PROJECT.supabase.co",
    publishableKey: window.__CLOUD_COLLAB_SUPABASE_ANON_KEY__ || "YOUR-PUBLISHABLE-ANON-KEY"
  }
};

let settings = fallback;
try {
  const response = await fetch(new URL("../../SUPABASE.json", import.meta.url), { cache: "no-store" });
  if (response.ok) settings = await response.json();
} catch {
  // Local overrides remain available if the JSON file cannot be fetched.
}

export const SUPABASE_URL = settings.project?.url || fallback.project.url;
export const SUPABASE_ANON_KEY = settings.project?.publishableKey || fallback.project.publishableKey;
