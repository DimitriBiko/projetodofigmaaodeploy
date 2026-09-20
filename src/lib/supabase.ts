import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const hasSupabaseConfig = Boolean(url && anonKey)

if (!hasSupabaseConfig) {
  console.warn(
    '[Gooday] Defina VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no .env / Vercel para autenticação.',
  )
}

/**
 * Never call createClient with empty strings — @supabase/supabase-js throws
 * "supabaseUrl is required" and crashes the whole app before React mounts.
 */
export const supabase: SupabaseClient = hasSupabaseConfig
  ? createClient(url!, anonKey!, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storageKey: 'gooday-auth',
      },
    })
  : (null as unknown as SupabaseClient)

export type Profile = {
  id: string
  email: string | null
  name: string
  handle: string
  avatar_url: string | null
  cover_url: string | null
  bio: string | null
  location: string | null
  is_admin: boolean
  is_verified: boolean
  is_private: boolean
}
