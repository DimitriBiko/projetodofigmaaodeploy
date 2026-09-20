import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  console.warn(
    '[Gooday] Defina VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no .env para autenticação.',
  )
}

export const supabase = createClient(url ?? '', anonKey ?? '', {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storageKey: 'gooday-auth',
  },
})

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
