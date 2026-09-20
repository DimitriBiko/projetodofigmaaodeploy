import { supabase } from './supabase'

/** Mapa mock contactId → UUID real do seed Supabase */
export const CONTACT_USER_IDS: Record<string, string> = {
  renata: '11111111-1111-4111-8111-111111111101',
  tiago: '11111111-1111-4111-8111-111111111102',
  nicole: '11111111-1111-4111-8111-111111111103',
  bruno: '11111111-1111-4111-8111-111111111104',
  julia: '11111111-1111-4111-8111-111111111105',
  lidiane: '11111111-1111-4111-8111-111111111106',
  camila: '11111111-1111-4111-8111-111111111107',
  marina: '11111111-1111-4111-8111-111111111108',
}

export type DbPost = {
  id: string
  body: string
  audience: string
  location_name: string | null
  created_at: string
  author_id: string
  author?: {
    name: string
    handle: string
    avatar_url: string | null
  } | null
  media?: { url: string; order: number }[]
  tags?: string[]
}

export async function uploadMediaFile(userId: string, file: File | Blob, filename?: string) {
  const ext =
    (filename?.split('.').pop() ||
      (file.type.includes('png') ? 'png' : file.type.includes('webp') ? 'webp' : 'jpg')) ?? 'jpg'
  const path = `${userId}/${crypto.randomUUID()}.${ext}`

  const { error } = await supabase.storage.from('media').upload(path, file, {
    cacheControl: '3600',
    upsert: false,
    contentType: file.type || 'image/jpeg',
  })
  if (error) throw error

  const { data } = supabase.storage.from('media').getPublicUrl(path)
  return data.publicUrl
}

/** Converte blob: URL ou File em URL pública no Storage */
export async function resolveMediaUrl(userId: string, source: string | File | null) {
  if (!source) return null
  if (typeof source !== 'string') {
    return uploadMediaFile(userId, source)
  }
  if (source.startsWith('blob:')) {
    const res = await fetch(source)
    const blob = await res.blob()
    return uploadMediaFile(userId, blob)
  }
  // Já é URL remota (unsplash etc.)
  return source
}

export async function createPost(input: {
  userId: string
  body: string
  audience?: 'PUBLIC' | 'FOLLOWERS' | 'GROUP'
  locationName?: string
  imageUrl?: string | null
  tags?: string[]
}) {
  const { data: post, error } = await supabase
    .from('posts')
    .insert({
      author_id: input.userId,
      body: input.body,
      audience: input.audience ?? 'PUBLIC',
      location_name: input.locationName || null,
    })
    .select('id')
    .single()

  if (error) throw error

  if (input.imageUrl) {
    const { data: media, error: mediaErr } = await supabase
      .from('media')
      .insert({
        uploader_id: input.userId,
        url: input.imageUrl,
        type: 'IMAGE',
      })
      .select('id')
      .single()
    if (mediaErr) throw mediaErr

    const { error: pmErr } = await supabase.from('post_media').insert({
      post_id: post.id,
      media_id: media.id,
      order: 0,
    })
    if (pmErr) throw pmErr
  }

  if (input.tags?.length) {
    const { error: tagErr } = await supabase.from('post_tags').insert(
      input.tags.map((tag) => ({ post_id: post.id, tag })),
    )
    if (tagErr) throw tagErr
  }

  return post.id as string
}

export async function createStory(input: {
  userId: string
  imageUrl: string
}) {
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
  const { data: story, error } = await supabase
    .from('stories')
    .insert({
      author_id: input.userId,
      status: 'ACTIVE',
      expires_at: expiresAt,
    })
    .select('id')
    .single()
  if (error) throw error

  const { data: media, error: mediaErr } = await supabase
    .from('media')
    .insert({
      uploader_id: input.userId,
      url: input.imageUrl,
      type: 'IMAGE',
    })
    .select('id')
    .single()
  if (mediaErr) throw mediaErr

  const { error: smErr } = await supabase.from('story_media').insert({
    story_id: story.id,
    media_id: media.id,
    order: 0,
  })
  if (smErr) throw smErr

  return story.id as string
}

export async function updateProfile(
  userId: string,
  patch: {
    name?: string
    handle?: string
    bio?: string | null
    location?: string | null
    avatar_url?: string | null
    cover_url?: string | null
    email?: string
  },
) {
  const { email, ...profilePatch } = patch
  if (Object.keys(profilePatch).length) {
    const { error } = await supabase.from('users').update(profilePatch).eq('id', userId)
    if (error) throw error
  }
  if (email) {
    const { error } = await supabase.auth.updateUser({ email })
    if (error) throw error
  }
}

export async function fetchFeedPosts(limit = 30): Promise<DbPost[]> {
  const { data, error } = await supabase
    .from('posts')
    .select(
      `
      id, body, audience, location_name, created_at, author_id,
      author:users!posts_author_id_fkey ( name, handle, avatar_url ),
      post_media ( order, media:media_id ( url ) ),
      post_tags ( tag )
    `,
    )
    .is('deleted_at', null)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) throw error

  return (data ?? []).map((row: any) => ({
    id: row.id,
    body: row.body,
    audience: row.audience,
    location_name: row.location_name,
    created_at: row.created_at,
    author_id: row.author_id,
    author: Array.isArray(row.author) ? row.author[0] : row.author,
    media: (row.post_media ?? [])
      .map((pm: any) => ({
        url: pm.media?.url,
        order: pm.order ?? 0,
      }))
      .filter((m: any) => m.url)
      .sort((a: any, b: any) => a.order - b.order),
    tags: (row.post_tags ?? []).map((t: any) => t.tag),
  }))
}

export async function getOrCreateDmConversation(myId: string, otherUserId: string) {
  // Busca conversas 1:1 onde ambos participam
  const { data: mine, error } = await supabase
    .from('conversation_participants')
    .select('conversation_id')
    .eq('user_id', myId)
    .is('left_at', null)

  if (error) throw error

  const myConvIds = (mine ?? []).map((r) => r.conversation_id)
  if (myConvIds.length) {
    const { data: shared, error: sErr } = await supabase
      .from('conversation_participants')
      .select('conversation_id')
      .eq('user_id', otherUserId)
      .in('conversation_id', myConvIds)
      .is('left_at', null)
      .limit(1)

    if (sErr) throw sErr
    if (shared?.[0]?.conversation_id) return shared[0].conversation_id as string
  }

  const { data: conv, error: cErr } = await supabase
    .from('conversations')
    .insert({ is_group: false })
    .select('id')
    .single()
  if (cErr) throw cErr

  // Inserir em sequência: RLS só permite o 2º participante depois que eu já estou na conversa
  const { error: meErr } = await supabase.from('conversation_participants').insert({
    conversation_id: conv.id,
    user_id: myId,
  })
  if (meErr) throw meErr

  const { error: otherErr } = await supabase.from('conversation_participants').insert({
    conversation_id: conv.id,
    user_id: otherUserId,
  })
  if (otherErr) throw otherErr

  return conv.id as string
}

export async function fetchMessages(conversationId: string) {
  const { data, error } = await supabase
    .from('messages')
    .select('id, body, sender_id, sent_at, deleted_at')
    .eq('conversation_id', conversationId)
    .is('deleted_at', null)
    .order('sent_at', { ascending: true })

  if (error) throw error
  return data ?? []
}

export async function sendMessage(input: {
  conversationId: string
  senderId: string
  body: string
}) {
  const { data, error } = await supabase
    .from('messages')
    .insert({
      conversation_id: input.conversationId,
      sender_id: input.senderId,
      body: input.body,
    })
    .select('id, body, sender_id, sent_at')
    .single()

  if (error) throw error
  return data
}
