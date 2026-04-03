import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Server-side client (for API routes)
export function createServerClient(cookieHeader?: string) {
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: cookieHeader ? { cookie: cookieHeader } : {},
    },
  });
}
