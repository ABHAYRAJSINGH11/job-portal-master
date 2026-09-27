import { createClient } from "@supabase/supabase-js";

export const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Clerk is registered with Supabase as a Third-Party Auth provider
// (Supabase Dashboard > Authentication > Sign In / Up > Add provider > Clerk).
// We just need to hand Supabase the current Clerk session token on every
// request; Supabase verifies it directly against Clerk's JWKS, no shared
// signing secret / JWT template required.
const supabaseClient = async (supabaseAccessToken) => {
  const supabase = createClient(supabaseUrl, supabaseKey, {
    accessToken: async () => supabaseAccessToken ?? null,
  });
  return supabase;
};

export default supabaseClient;
