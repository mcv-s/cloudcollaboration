import { supabase } from "./supabase.js";
export const auth = {
  getSession: () => supabase.auth.getSession(),
  onChange: (fn) => supabase.auth.onAuthStateChange(fn),
  signIn: (email,password) => supabase.auth.signInWithPassword({email,password}),
  signUp: (email,password,displayName) => supabase.auth.signUp({email,password,options:{data:{display_name:displayName}}}),
  reset: (email) => supabase.auth.resetPasswordForEmail(email),
  signOut: () => supabase.auth.signOut()
};
