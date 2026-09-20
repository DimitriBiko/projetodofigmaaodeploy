import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { hasSupabaseConfig, supabase, type Profile } from './supabase'

type AuthContextValue = {
  session: Session | null
  user: User | null
  profile: Profile | null
  loading: boolean
  isAdmin: boolean
  configError: string | null
  signIn: (email: string, password: string) => Promise<{ error: string | null }>
  signUp: (input: {
    name: string
    email: string
    password: string
  }) => Promise<{ error: string | null }>
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

const CONFIG_ERROR =
  'Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY na Vercel (Environment Variables) e faça um novo deploy.'

async function fetchProfile(userId: string): Promise<Profile | null> {
  if (!hasSupabaseConfig) return null
  const { data, error } = await supabase
    .from('users')
    .select(
      'id, email, name, handle, avatar_url, cover_url, bio, location, is_admin, is_verified, is_private',
    )
    .eq('id', userId)
    .maybeSingle()

  if (error) {
    console.error('[Gooday] profile fetch', error.message)
    return null
  }
  return data as Profile | null
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const configError = hasSupabaseConfig ? null : CONFIG_ERROR

  const refreshProfile = useCallback(async () => {
    if (!hasSupabaseConfig) return
    const uid = (await supabase.auth.getUser()).data.user?.id
    if (!uid) {
      setProfile(null)
      return
    }
    setProfile(await fetchProfile(uid))
  }, [])

  useEffect(() => {
    let mounted = true

    if (!hasSupabaseConfig) {
      setLoading(false)
      return
    }

    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      if (data.session?.user) {
        fetchProfile(data.session.user.id).then((p) => {
          if (mounted) setProfile(p)
        })
      }
      setLoading(false)
    })

    const { data: sub } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
      if (next?.user) {
        fetchProfile(next.user.id).then(setProfile)
      } else {
        setProfile(null)
      }
      setLoading(false)
    })

    return () => {
      mounted = false
      sub.subscription.unsubscribe()
    }
  }, [])

  const signIn = useCallback(async (email: string, password: string) => {
    if (!hasSupabaseConfig) return { error: CONFIG_ERROR }
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) return { error: error.message }
    return { error: null }
  }, [])

  const signUp = useCallback(
    async ({ name, email, password }: { name: string; email: string; password: string }) => {
      if (!hasSupabaseConfig) return { error: CONFIG_ERROR }
      const handleBase = email
        .split('@')[0]
        .toLowerCase()
        .replace(/[^a-z0-9._]/g, '')
      const handle = `@${handleBase || 'user'}`

      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, handle },
        },
      })
      if (error) return { error: error.message }
      return { error: null }
    },
    [],
  )

  const signOut = useCallback(async () => {
    if (!hasSupabaseConfig) return
    await supabase.auth.signOut()
    setProfile(null)
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      loading,
      isAdmin: !!profile?.is_admin,
      configError,
      signIn,
      signUp,
      signOut,
      refreshProfile,
    }),
    [session, profile, loading, configError, signIn, signUp, signOut, refreshProfile],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
