import { useRef, useState, type ChangeEvent } from 'react'
import { ChevronLeft, Settings, Grid3x3, Heart, Camera, Edit3 } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { resolveMediaUrl, updateProfile } from '../lib/db'
import { currentUser } from '../lib/media'

const myData = {
  name: 'Marcos Vinícius',
  handle: '@marcos_v',
  avatar: currentUser.avatar,
  cover:
    'https://images.unsplash.com/photo-1530143311094-34d807799e8f?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900&h=400',
  location: 'São Paulo, SP',
  bio: 'Corredor amador e entusiasta de vida saudável. Acredito que movimento é remédio. 🏃‍♂️',
  interests: ['Corrida', 'Nutrição', 'Hiking', 'Ciclismo'],
  followers: 1240,
  following: 318,
  posts: [
    'https://images.unsplash.com/photo-1498581444814-7e44d2fbe0e2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
    'https://images.unsplash.com/photo-1530143311094-34d807799e8f?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
    'https://images.unsplash.com/photo-1606224547099-b15c94ca5ef2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
    'https://images.unsplash.com/photo-1533240332313-0db49b459ad6?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=400',
  ],
}

type Tab = 'posts' | 'curtidas'

export default function MyProfile({
  onBack,
  onSettings,
}: {
  onBack: () => void
  onSettings: () => void
}) {
  const { user, profile, refreshProfile } = useAuth()
  const [tab, setTab] = useState<Tab>('posts')
  const [editing, setEditing] = useState(false)
  const [bio, setBio] = useState(profile?.bio || myData.bio)
  const [draftBio, setDraftBio] = useState(bio)
  const [avatarUrl, setAvatarUrl] = useState(profile?.avatar_url || myData.avatar)
  const [coverUrl, setCoverUrl] = useState(profile?.cover_url || myData.cover)
  const [avatarFile, setAvatarFile] = useState<File | null>(null)
  const [coverFile, setCoverFile] = useState<File | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const avatarInputRef = useRef<HTMLInputElement>(null)
  const coverInputRef = useRef<HTMLInputElement>(null)

  const displayName = profile?.name || myData.name
  const displayHandle = profile?.handle || myData.handle
  const displayLocation = profile?.location || myData.location

  const onPickAvatar = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file || !file.type.startsWith('image/')) return
    setAvatarFile(file)
    setAvatarUrl(URL.createObjectURL(file))
    e.target.value = ''
  }

  const onPickCover = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file || !file.type.startsWith('image/')) return
    setCoverFile(file)
    setCoverUrl(URL.createObjectURL(file))
    e.target.value = ''
  }

  const persistProfile = async (nextBio?: string) => {
    if (!user || busy) return
    setBusy(true)
    setError(null)
    try {
      const nextAvatar = avatarFile
        ? await resolveMediaUrl(user.id, avatarFile)
        : avatarUrl.startsWith('blob:')
          ? await resolveMediaUrl(user.id, avatarUrl)
          : avatarUrl
      const nextCover = coverFile
        ? await resolveMediaUrl(user.id, coverFile)
        : coverUrl.startsWith('blob:')
          ? await resolveMediaUrl(user.id, coverUrl)
          : coverUrl

      await updateProfile(user.id, {
        bio: (nextBio ?? bio).trim() || null,
        avatar_url: nextAvatar,
        cover_url: nextCover,
      })
      await refreshProfile()
      setAvatarFile(null)
      setCoverFile(null)
      if (nextAvatar) setAvatarUrl(nextAvatar)
      if (nextCover) setCoverUrl(nextCover)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar o perfil.')
      throw err
    } finally {
      setBusy(false)
    }
  }

  const saveBio = async () => {
    try {
      setBio(draftBio)
      await persistProfile(draftBio)
      setEditing(false)
    } catch {
      /* error already set */
    }
  }

  return (
    <div className="fixed inset-0 z-60 flex flex-col bg-canvas overflow-y-auto">
      <input
        ref={avatarInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={onPickAvatar}
      />
      <input
        ref={coverInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={onPickCover}
      />

      <header className="sticky top-0 z-10 flex items-center gap-3 bg-surface px-4 py-3 border-b border-neutral-200">
        <button
          type="button"
          onClick={onBack}
          aria-label="Voltar"
          className="grid h-9 w-9 place-items-center rounded-full text-ink transition-colors hover:bg-neutral-100"
        >
          <ChevronLeft size={22} />
        </button>
        <span className="flex-1 text-[17px] font-semibold text-ink">Meu Perfil</span>
        <button
          type="button"
          onClick={onSettings}
          aria-label="Configurações"
          className="grid h-9 w-9 place-items-center rounded-full text-neutral-500 transition-colors hover:bg-neutral-100"
        >
          <Settings size={20} />
        </button>
      </header>

      <div className="mx-auto w-full max-w-[700px] px-4 pt-5 pb-10">
        <div className="relative h-[160px] w-full overflow-hidden rounded-[18px]">
          <img src={coverUrl} alt="" className="h-full w-full object-cover" />
          <button
            type="button"
            aria-label="Alterar capa"
            onClick={() => coverInputRef.current?.click()}
            className="absolute right-3 bottom-3 flex items-center gap-1.5 rounded-full bg-black/50 px-3 py-1.5 text-[12px] font-medium text-white backdrop-blur-sm transition-colors hover:bg-black/70"
          >
            <Camera size={13} />
            Alterar capa
          </button>
        </div>

        <div className="-mt-10 ml-4 mb-4 flex items-end justify-between">
          <div className="relative">
            <div className="h-[88px] w-[88px] overflow-hidden rounded-full ring-[3px] ring-canvas">
              <img src={avatarUrl} alt={displayName} className="h-full w-full object-cover" />
            </div>
            <button
              type="button"
              aria-label="Alterar foto"
              onClick={() => avatarInputRef.current?.click()}
              className="absolute -bottom-1 -right-1 grid h-7 w-7 place-items-center rounded-full bg-secondary-500 text-white ring-2 ring-canvas transition-colors hover:bg-secondary-600"
            >
              <Camera size={13} />
            </button>
          </div>
          {(avatarFile || coverFile) && (
            <button
              type="button"
              disabled={busy}
              onClick={() => void persistProfile()}
              className="mb-1 rounded-full bg-secondary-500 px-4 py-1.5 text-[13px] font-semibold text-white disabled:opacity-60"
            >
              {busy ? 'Salvando…' : 'Salvar fotos'}
            </button>
          )}
        </div>

        <h1 className="text-[22px] font-bold text-ink leading-tight">{displayName}</h1>
        <p className="mt-0.5 text-[14px] text-neutral-500">
          {displayHandle}
          {displayLocation ? ` · ${displayLocation}` : ''}
        </p>

        {editing ? (
          <div className="mt-3">
            <textarea
              value={draftBio}
              onChange={(e) => setDraftBio(e.target.value)}
              rows={3}
              className="w-full rounded-[12px] border border-neutral-200 bg-surface px-3.5 py-2.5 text-[14px] leading-relaxed text-ink outline-none focus:border-secondary-500 resize-none"
              autoFocus
            />
            <div className="mt-2 flex gap-2">
              <button
                type="button"
                disabled={busy}
                onClick={() => void saveBio()}
                className="rounded-full bg-secondary-500 px-4 py-1.5 text-[13px] font-semibold text-white transition-colors hover:bg-secondary-600 disabled:opacity-60"
              >
                {busy ? 'Salvando…' : 'Salvar'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setDraftBio(bio)
                  setEditing(false)
                }}
                className="rounded-full bg-neutral-100 px-4 py-1.5 text-[13px] font-semibold text-neutral-700 transition-colors hover:bg-neutral-200"
              >
                Cancelar
              </button>
            </div>
          </div>
        ) : (
          <p
            className="mt-3 cursor-text text-[14px] leading-relaxed text-neutral-700"
            onClick={() => {
              setDraftBio(bio)
              setEditing(true)
            }}
          >
            {bio}
          </p>
        )}

        {error && <p className="mt-2 text-[13px] text-red-600">{error}</p>}

        <div className="mt-3 flex flex-wrap gap-2">
          {myData.interests.map((interest) => (
            <span
              key={interest}
              className="rounded-full bg-neutral-100 px-3.5 py-1 text-[13px] font-medium text-neutral-700"
            >
              {interest}
            </span>
          ))}
        </div>

        <div className="mt-5 flex gap-8">
          {[
            { label: 'seguidores', value: myData.followers.toLocaleString('pt-BR') },
            { label: 'seguindo', value: myData.following.toLocaleString('pt-BR') },
            { label: 'publicações', value: myData.posts.length.toString() },
          ].map(({ label, value }) => (
            <button key={label} type="button" className="flex flex-col items-start gap-0.5 transition-opacity hover:opacity-70">
              <span className="text-[20px] font-bold text-ink leading-none">{value}</span>
              <span className="text-[12px] text-neutral-500">{label}</span>
            </button>
          ))}
        </div>

        <div className="mt-5 flex gap-3">
          <button
            type="button"
            onClick={() => {
              setDraftBio(bio)
              setEditing(true)
            }}
            className="flex flex-1 items-center justify-center gap-2 rounded-[14px] bg-secondary-500 py-3.5 text-[15px] font-semibold text-white transition-colors hover:bg-secondary-600"
          >
            <Edit3 size={16} />
            Editar perfil
          </button>
          <button
            type="button"
            onClick={onSettings}
            className="flex flex-1 items-center justify-center gap-2 rounded-[14px] bg-neutral-100 py-3.5 text-[15px] font-semibold text-neutral-700 transition-colors hover:bg-neutral-200"
          >
            <Settings size={16} />
            Configurações
          </button>
        </div>

        <div className="mt-7 flex border-b border-neutral-200">
          {(
            [
              { key: 'posts', label: 'Publicações', icon: Grid3x3 },
              { key: 'curtidas', label: 'Curtidas', icon: Heart },
            ] as { key: Tab; label: string; icon: typeof Grid3x3 }[]
          ).map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              type="button"
              onClick={() => setTab(key)}
              className={`flex flex-1 items-center justify-center gap-2 pb-3 text-[14px] font-semibold transition-colors ${
                tab === key
                  ? 'border-b-2 border-secondary-500 text-secondary-500'
                  : 'text-neutral-400 hover:text-ink'
              }`}
            >
              <Icon size={16} />
              {label}
            </button>
          ))}
        </div>

        {tab === 'posts' &&
          (myData.posts.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-16">
              <div className="grid h-14 w-14 place-items-center rounded-full bg-neutral-100">
                <Grid3x3 size={24} className="text-neutral-400" />
              </div>
              <p className="text-[15px] font-semibold text-ink">Nada publicado ainda</p>
              <p className="text-[13px] text-neutral-500">Compartilhe seu primeiro momento.</p>
            </div>
          ) : (
            <div className="mt-3 grid grid-cols-3 gap-1 overflow-hidden rounded-[14px]">
              {myData.posts.map((src, i) => (
                <div key={i} className="aspect-square overflow-hidden">
                  <img src={src} alt="" className="h-full w-full object-cover transition-transform hover:scale-105" />
                </div>
              ))}
            </div>
          ))}

        {tab === 'curtidas' && (
          <div className="flex flex-col items-center gap-3 py-16">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-neutral-100">
              <Heart size={24} className="text-neutral-400" />
            </div>
            <p className="text-[15px] font-semibold text-ink">Nenhuma curtida ainda</p>
            <p className="text-[13px] text-neutral-500">Os posts que você curtir aparecem aqui.</p>
          </div>
        )}
      </div>
    </div>
  )
}
