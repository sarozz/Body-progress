/**
 * Compile-time configuration. Values come from `EXPO_PUBLIC_*` env vars,
 * which Expo automatically inlines at bundle time.
 *
 * Set them in `.env` (gitignored) for local dev or via `eas secret` for
 * production builds.
 */
export const Env = {
  supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '',
} as const;

export const supabaseConfigured =
  Env.supabaseUrl.length > 0 && Env.supabaseAnonKey.length > 0;
