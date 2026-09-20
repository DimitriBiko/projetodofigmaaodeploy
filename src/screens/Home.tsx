import { useEffect, useState } from 'react'
import {
  BottomNav,
  ContextRail,
  GroupCard,
  MobileHeader,
  PostCard,
  SidebarNav,
  StoriesRow,
  TopBar,
} from '../components/home'
import Notifications from '../components/Notifications'
import { useAuth } from '../lib/auth'
import { fetchFeedPosts, type DbPost } from '../lib/db'
import { currentUser, groups, posts as mockPosts, stories, type Post } from '../lib/media'

function formatRelativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'agora'
  if (mins < 60) return `${mins} min`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours} h`
  const days = Math.floor(hours / 24)
  return `${days} d`
}

function mapDbPost(row: DbPost): Post {
  return {
    author: row.author?.handle || row.author?.name || '@user',
    avatar: row.author?.avatar_url || currentUser.avatar,
    time: formatRelativeTime(row.created_at),
    text: row.body,
    tags: row.tags ?? [],
    image: row.media?.[0]?.url,
    reactions: [],
    likes: 0,
    comments: 0,
  }
}

export default function Home({
  onNavigate,
  activeKey,
  onOpenGroup,
  onOpenProfile,
  onViewAllPeople,
}: {
  onNavigate?: (key: string) => void
  activeKey?: string
  onOpenGroup?: (id: string) => void
  onOpenProfile?: (id: string) => void
  onViewAllPeople?: () => void
}) {
  const { profile } = useAuth()
  const [showNotifs, setShowNotifs] = useState(false)
  const [feed, setFeed] = useState<Post[]>(mockPosts)
  const [feedError, setFeedError] = useState<string | null>(null)

  const headerUser = {
    ...currentUser,
    name: profile?.name || currentUser.name,
    handle: profile?.handle || currentUser.handle,
    avatar: profile?.avatar_url || currentUser.avatar,
  }

  useEffect(() => {
    let cancelled = false
    fetchFeedPosts()
      .then((rows) => {
        if (cancelled) return
        if (rows.length) setFeed(rows.map(mapDbPost))
      })
      .catch((err) => {
        if (!cancelled) {
          setFeedError(err instanceof Error ? err.message : 'Falha ao carregar feed.')
        }
      })
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="min-h-dvh w-full bg-canvas pb-28 min-[800px]:pb-0">
      <TopBar user={headerUser} onNavigate={onNavigate} onNotifications={() => setShowNotifs(true)} />
      <MobileHeader user={headerUser} onNotifications={() => setShowNotifs(true)} onNavigate={onNavigate} />
      {showNotifs && <Notifications onClose={() => setShowNotifs(false)} />}

      <div className="w-full px-5 min-[1800px]:px-8">
        <section className="py-4">
          <StoriesRow stories={stories} />
        </section>

        <section className="min-[800px]:hidden">
          <h2 className="mb-3 px-0.5 text-[16px] font-semibold text-ink">Grupos para você</h2>
          <div className="no-scrollbar -mx-5 flex gap-3 overflow-x-auto px-5 pb-1">
            {groups.map((g) => (
              <div key={g.name} className="w-[190px] shrink-0 sm:w-[220px]">
                <GroupCard group={g} onOpenGroup={onOpenGroup} />
              </div>
            ))}
          </div>
        </section>

        <div className="grid grid-cols-1 gap-8 py-5 min-[800px]:grid-cols-[max-content_minmax(280px,560px)_minmax(240px,1fr)] min-[1200px]:gap-10 min-[1800px]:gap-12">
          <aside className="hidden min-[800px]:block">
            <div className="sticky top-[68px]">
              <SidebarNav activeKey={activeKey} onNavigate={onNavigate} />
            </div>
          </aside>

          <main className="mx-auto w-full max-w-[640px] space-y-5 min-[800px]:mx-0 min-[800px]:max-w-none">
            {feedError && (
              <p className="rounded-[12px] bg-red-50 px-4 py-3 text-[13px] text-red-600">{feedError}</p>
            )}
            {feed.map((p, i) => (
              <PostCard key={`${p.author}-${p.time}-${i}`} post={p} />
            ))}
          </main>

          <aside className="hidden min-[800px]:block">
            <div
              className="sticky top-[68px] overflow-y-auto"
              style={{
                maxHeight: 'calc(100dvh - 68px)',
                maskImage:
                  'linear-gradient(to bottom, transparent 0px, black 24px, black calc(100% - 24px), transparent 100%)',
                WebkitMaskImage:
                  'linear-gradient(to bottom, transparent 0px, black 24px, black calc(100% - 24px), transparent 100%)',
                scrollbarWidth: 'none',
              }}
            >
              <div className="py-6">
                <ContextRail
                  groups={groups}
                  onOpenGroup={onOpenGroup}
                  onOpenProfile={onOpenProfile}
                  onViewAllPeople={onViewAllPeople}
                  onViewAllGroups={() => onNavigate?.('grupos')}
                />
              </div>
            </div>
          </aside>
        </div>
      </div>

      <BottomNav activeKey={activeKey} onNavigate={onNavigate} />
    </div>
  )
}
