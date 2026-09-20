-- =============================================================
-- Gooday — Schema inicial (PostgreSQL / Supabase)
-- Adaptado do Prisma: Account → auth.users; IDs → uuid
-- =============================================================

create extension if not exists "pgcrypto";

-- =============================================================
-- ENUMS
-- =============================================================

create type public.privacy as enum ('PUBLIC', 'PRIVATE');
create type public.group_member_role as enum ('OWNER', 'ADMIN', 'MEMBER');
create type public.group_member_status as enum ('ACTIVE', 'PENDING', 'BANNED');
create type public.notification_type as enum (
  'FOLLOW', 'LIKE', 'COMMENT', 'MENTION',
  'GROUP_INVITE', 'GROUP_REQUEST', 'GROUP_ACCEPTED',
  'MESSAGE', 'STORY_REPLY', 'POST_SHARE'
);
create type public.media_type as enum ('IMAGE', 'VIDEO');
create type public.post_audience as enum ('PUBLIC', 'FOLLOWERS', 'GROUP');
create type public.story_status as enum ('ACTIVE', 'EXPIRED', 'DELETED');

-- =============================================================
-- HELPERS
-- =============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =============================================================
-- USERS (perfil público; id = auth.users.id)
-- =============================================================

create table public.users (
  id           uuid primary key references auth.users (id) on delete cascade,
  email        text,
  name         text not null,
  handle       text not null unique,
  avatar_url   text,
  cover_url    text,
  bio          text,
  location     text,
  website      text,
  is_verified  boolean not null default false,
  is_private   boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint users_handle_format check (handle ~ '^@[a-z0-9._]+$')
);

create index users_name_idx on public.users using gin (to_tsvector('simple', coalesce(name, '')));
create index users_handle_idx on public.users (handle);

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

-- Auto-criar perfil ao cadastrar no Auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_handle text;
  v_name text;
begin
  v_name := coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1), 'Usuário');
  v_handle := coalesce(
    new.raw_user_meta_data->>'handle',
    '@' || lower(regexp_replace(split_part(coalesce(new.email, new.id::text), '@', 1), '[^a-z0-9._]', '', 'g'))
  );
  if v_handle not like '@%' then
    v_handle := '@' || v_handle;
  end if;

  insert into public.users (id, email, name, handle, avatar_url)
  values (
    new.id,
    new.email,
    v_name,
    v_handle,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.user_settings (user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.notification_preferences (user_id) values (new.id) on conflict (user_id) do nothing;

  return new;
end;
$$;

-- =============================================================
-- FOLLOWS
-- =============================================================

create table public.follows (
  id           uuid primary key default gen_random_uuid(),
  follower_id  uuid not null references public.users (id) on delete cascade,
  following_id uuid not null references public.users (id) on delete cascade,
  created_at   timestamptz not null default now(),
  constraint follows_no_self check (follower_id <> following_id),
  unique (follower_id, following_id)
);

create index follows_follower_idx on public.follows (follower_id);
create index follows_following_idx on public.follows (following_id);

-- =============================================================
-- INTERESTS
-- =============================================================

create table public.interests (
  id   uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique
);

create table public.user_interests (
  user_id     uuid not null references public.users (id) on delete cascade,
  interest_id uuid not null references public.interests (id) on delete cascade,
  primary key (user_id, interest_id)
);

create table public.groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  description text,
  cover_url   text,
  avatar_url  text,
  privacy     public.privacy not null default 'PUBLIC',
  parent_id   uuid references public.groups (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create trigger groups_set_updated_at
  before update on public.groups
  for each row execute function public.set_updated_at();

create table public.group_interests (
  group_id    uuid not null references public.groups (id) on delete cascade,
  interest_id uuid not null references public.interests (id) on delete cascade,
  primary key (group_id, interest_id)
);

create table public.group_members (
  id        uuid primary key default gen_random_uuid(),
  group_id  uuid not null references public.groups (id) on delete cascade,
  user_id   uuid not null references public.users (id) on delete cascade,
  role      public.group_member_role not null default 'MEMBER',
  status    public.group_member_status not null default 'ACTIVE',
  joined_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create index group_members_user_idx on public.group_members (user_id);
create index group_members_group_idx on public.group_members (group_id);

-- =============================================================
-- MEDIA / POSTS / STORIES
-- =============================================================

create table public.media (
  id          uuid primary key default gen_random_uuid(),
  uploader_id uuid not null references public.users (id) on delete cascade,
  url         text not null,
  type        public.media_type not null default 'IMAGE',
  mime_type   text,
  width       int,
  height      int,
  duration    int,
  size_bytes  int,
  alt_text    text,
  created_at  timestamptz not null default now()
);

create table public.posts (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references public.users (id) on delete cascade,
  body          text not null default '',
  audience      public.post_audience not null default 'PUBLIC',
  location_name text,
  latitude      double precision,
  longitude     double precision,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();

create index posts_author_idx on public.posts (author_id, created_at desc);
create index posts_created_idx on public.posts (created_at desc);

create table public.post_media (
  post_id  uuid not null references public.posts (id) on delete cascade,
  media_id uuid not null references public.media (id) on delete cascade,
  "order"  int not null default 0,
  primary key (post_id, media_id)
);

create table public.post_tags (
  post_id uuid not null references public.posts (id) on delete cascade,
  tag     text not null,
  primary key (post_id, tag)
);

create table public.post_mentions (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  primary key (post_id, user_id)
);

create table public.group_posts (
  id        uuid primary key default gen_random_uuid(),
  group_id  uuid not null references public.groups (id) on delete cascade,
  post_id   uuid not null unique references public.posts (id) on delete cascade,
  author_id uuid not null references public.users (id) on delete cascade
);

create table public.stories (
  id         uuid primary key default gen_random_uuid(),
  author_id  uuid not null references public.users (id) on delete cascade,
  status     public.story_status not null default 'ACTIVE',
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index stories_author_idx on public.stories (author_id, created_at desc);
create index stories_active_idx on public.stories (status, expires_at);

create table public.story_media (
  story_id uuid not null references public.stories (id) on delete cascade,
  media_id uuid not null references public.media (id) on delete cascade,
  "order"  int not null default 0,
  primary key (story_id, media_id)
);

create table public.story_views (
  story_id  uuid not null references public.stories (id) on delete cascade,
  viewer_id uuid not null references public.users (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

create table public.story_replies (
  id        uuid primary key default gen_random_uuid(),
  story_id  uuid not null references public.stories (id) on delete cascade,
  sender_id uuid not null references public.users (id) on delete cascade,
  body      text not null,
  sent_at   timestamptz not null default now()
);

-- =============================================================
-- COMMENTS / LIKES / REACTIONS / BOOKMARKS
-- =============================================================

create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts (id) on delete cascade,
  author_id  uuid not null references public.users (id) on delete cascade,
  parent_id  uuid references public.comments (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index comments_post_idx on public.comments (post_id, created_at);

create table public.likes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users (id) on delete cascade,
  post_id    uuid references public.posts (id) on delete cascade,
  comment_id uuid references public.comments (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint likes_target check (
    (post_id is not null and comment_id is null)
    or (post_id is null and comment_id is not null)
  )
);

create unique index likes_user_post_uidx on public.likes (user_id, post_id) where post_id is not null;
create unique index likes_user_comment_uidx on public.likes (user_id, comment_id) where comment_id is not null;

create table public.reactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users (id) on delete cascade,
  post_id    uuid not null references public.posts (id) on delete cascade,
  emoji      text not null,
  created_at timestamptz not null default now(),
  unique (user_id, post_id, emoji)
);

create table public.bookmarks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users (id) on delete cascade,
  post_id    uuid not null references public.posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

-- =============================================================
-- MESSAGES
-- =============================================================

create table public.conversations (
  id         uuid primary key default gen_random_uuid(),
  is_group   boolean not null default false,
  title      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger conversations_set_updated_at
  before update on public.conversations
  for each row execute function public.set_updated_at();

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id         uuid not null references public.users (id) on delete cascade,
  joined_at       timestamptz not null default now(),
  last_read_at    timestamptz,
  left_at         timestamptz,
  primary key (conversation_id, user_id)
);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references public.users (id) on delete cascade,
  body            text not null,
  media_url       text,
  sent_at         timestamptz not null default now(),
  deleted_at      timestamptz
);

create index messages_conversation_idx on public.messages (conversation_id, sent_at);

-- =============================================================
-- NOTIFICATIONS / SETTINGS / SEARCH
-- =============================================================

create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.users (id) on delete cascade,
  actor_id     uuid references public.users (id) on delete set null,
  type         public.notification_type not null,
  post_id      uuid references public.posts (id) on delete cascade,
  comment_id   uuid references public.comments (id) on delete cascade,
  group_id     uuid references public.groups (id) on delete cascade,
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);

create index notifications_recipient_idx on public.notifications (recipient_id, created_at desc);

create table public.user_settings (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null unique references public.users (id) on delete cascade,
  language         text not null default 'pt-BR',
  theme            text not null default 'light',
  reduce_motion    boolean not null default false,
  text_size_offset int not null default 0
);

create table public.notification_preferences (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null unique references public.users (id) on delete cascade,
  push_enabled          boolean not null default true,
  email_weekly_summary  boolean not null default false,
  notify_follows        boolean not null default true,
  notify_likes          boolean not null default true,
  notify_comments       boolean not null default true,
  notify_mentions       boolean not null default true,
  notify_group_activity boolean not null default true,
  notify_messages       boolean not null default true
);

create table public.search_history (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users (id) on delete cascade,
  query      text not null,
  created_at timestamptz not null default now()
);

create index search_history_user_idx on public.search_history (user_id, created_at desc);

-- Trigger handle_new_user AFTER tables it depends on exist
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
