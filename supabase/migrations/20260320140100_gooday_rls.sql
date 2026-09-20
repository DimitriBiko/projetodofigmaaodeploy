-- =============================================================
-- Gooday — Funções auxiliares + RLS
-- =============================================================

-- Membership helpers
create or replace function public.is_group_member(p_group_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = p_user_id
      and gm.status = 'ACTIVE'
  );
$$;

create or replace function public.is_group_admin(p_group_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = p_user_id
      and gm.status = 'ACTIVE'
      and gm.role in ('OWNER', 'ADMIN')
  );
$$;

create or replace function public.is_following(p_follower uuid, p_following uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.follows f
    where f.follower_id = p_follower and f.following_id = p_following
  );
$$;

create or replace function public.can_view_profile(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = p_user_id
      and (
        u.is_private = false
        or u.id = auth.uid()
        or public.is_following(auth.uid(), u.id)
      )
  );
$$;

create or replace function public.can_view_post(p_post_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.posts p
    left join public.group_posts gp on gp.post_id = p.id
    where p.id = p_post_id
      and p.deleted_at is null
      and (
        p.author_id = auth.uid()
        or p.audience = 'PUBLIC'
        or (p.audience = 'FOLLOWERS' and public.is_following(auth.uid(), p.author_id))
        or (p.audience = 'GROUP' and gp.group_id is not null and public.is_group_member(gp.group_id))
      )
  );
$$;

create or replace function public.is_conversation_participant(p_conversation_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id
      and cp.user_id = p_user_id
      and cp.left_at is null
  );
$$;

-- Expire stories older than expires_at
create or replace function public.expire_stories()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  n integer;
begin
  update public.stories
  set status = 'EXPIRED'
  where status = 'ACTIVE'
    and expires_at < now()
    and deleted_at is null;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Touch conversation on new message
create or replace function public.touch_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations set updated_at = now() where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.touch_conversation_on_message();

-- Notify on follow
create or replace function public.notify_on_follow()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (recipient_id, actor_id, type)
  values (new.following_id, new.follower_id, 'FOLLOW');
  return new;
end;
$$;

drop trigger if exists follows_notify on public.follows;
create trigger follows_notify
  after insert on public.follows
  for each row execute function public.notify_on_follow();

-- Notify on like
create or replace function public.notify_on_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
begin
  if new.post_id is not null then
    select author_id into v_author from public.posts where id = new.post_id;
    if v_author is not null and v_author <> new.user_id then
      insert into public.notifications (recipient_id, actor_id, type, post_id)
      values (v_author, new.user_id, 'LIKE', new.post_id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists likes_notify on public.likes;
create trigger likes_notify
  after insert on public.likes
  for each row execute function public.notify_on_like();

-- Notify on comment
create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
begin
  select author_id into v_author from public.posts where id = new.post_id;
  if v_author is not null and v_author <> new.author_id then
    insert into public.notifications (recipient_id, actor_id, type, post_id, comment_id)
    values (v_author, new.author_id, 'COMMENT', new.post_id, new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists comments_notify on public.comments;
create trigger comments_notify
  after insert on public.comments
  for each row execute function public.notify_on_comment();

-- =============================================================
-- ENABLE RLS
-- =============================================================

alter table public.users enable row level security;
alter table public.follows enable row level security;
alter table public.interests enable row level security;
alter table public.user_interests enable row level security;
alter table public.groups enable row level security;
alter table public.group_interests enable row level security;
alter table public.group_members enable row level security;
alter table public.media enable row level security;
alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.post_tags enable row level security;
alter table public.post_mentions enable row level security;
alter table public.group_posts enable row level security;
alter table public.stories enable row level security;
alter table public.story_media enable row level security;
alter table public.story_views enable row level security;
alter table public.story_replies enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;
alter table public.reactions enable row level security;
alter table public.bookmarks enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.user_settings enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.search_history enable row level security;

-- USERS
create policy users_select on public.users for select
  using (public.can_view_profile(id) or id = auth.uid() or is_private = false);
create policy users_update on public.users for update
  using (id = auth.uid()) with check (id = auth.uid());
create policy users_insert on public.users for insert
  with check (id = auth.uid());

-- FOLLOWS
create policy follows_select on public.follows for select using (true);
create policy follows_insert on public.follows for insert with check (follower_id = auth.uid());
create policy follows_delete on public.follows for delete using (follower_id = auth.uid());

-- INTERESTS (catálogo público)
create policy interests_select on public.interests for select using (true);

create policy user_interests_select on public.user_interests for select using (true);
create policy user_interests_write on public.user_interests for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- GROUPS
create policy groups_select on public.groups for select
  using (
    deleted_at is null
    and (privacy = 'PUBLIC' or public.is_group_member(id) or auth.uid() is not null)
  );
create policy groups_insert on public.groups for insert with check (auth.uid() is not null);
create policy groups_update on public.groups for update
  using (public.is_group_admin(id));
create policy groups_delete on public.groups for delete
  using (public.is_group_admin(id));

create policy group_interests_select on public.group_interests for select using (true);
create policy group_interests_write on public.group_interests for all
  using (public.is_group_admin(group_id)) with check (public.is_group_admin(group_id));

create policy group_members_select on public.group_members for select
  using (
    exists (select 1 from public.groups g where g.id = group_id and g.privacy = 'PUBLIC')
    or public.is_group_member(group_id)
    or user_id = auth.uid()
  );
create policy group_members_insert on public.group_members for insert
  with check (user_id = auth.uid() or public.is_group_admin(group_id));
create policy group_members_update on public.group_members for update
  using (public.is_group_admin(group_id) or user_id = auth.uid());
create policy group_members_delete on public.group_members for delete
  using (user_id = auth.uid() or public.is_group_admin(group_id));

-- MEDIA
create policy media_select on public.media for select using (true);
create policy media_insert on public.media for insert with check (uploader_id = auth.uid());
create policy media_update on public.media for update using (uploader_id = auth.uid());
create policy media_delete on public.media for delete using (uploader_id = auth.uid());

-- POSTS
create policy posts_select on public.posts for select using (public.can_view_post(id));
create policy posts_insert on public.posts for insert with check (author_id = auth.uid());
create policy posts_update on public.posts for update using (author_id = auth.uid());
create policy posts_delete on public.posts for delete using (author_id = auth.uid());

create policy post_media_select on public.post_media for select
  using (public.can_view_post(post_id));
create policy post_media_write on public.post_media for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()));

create policy post_tags_select on public.post_tags for select using (public.can_view_post(post_id));
create policy post_tags_write on public.post_tags for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()));

create policy post_mentions_select on public.post_mentions for select using (public.can_view_post(post_id));
create policy post_mentions_write on public.post_mentions for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()));

create policy group_posts_select on public.group_posts for select
  using (public.is_group_member(group_id) or exists (
    select 1 from public.groups g where g.id = group_id and g.privacy = 'PUBLIC'
  ));
create policy group_posts_insert on public.group_posts for insert
  with check (author_id = auth.uid() and public.is_group_member(group_id));

-- STORIES
create policy stories_select on public.stories for select
  using (
    deleted_at is null
    and status = 'ACTIVE'
    and expires_at > now()
    and (
      author_id = auth.uid()
      or not exists (select 1 from public.users u where u.id = author_id and u.is_private)
      or public.is_following(auth.uid(), author_id)
    )
  );
create policy stories_insert on public.stories for insert with check (author_id = auth.uid());
create policy stories_update on public.stories for update using (author_id = auth.uid());
create policy stories_delete on public.stories for delete using (author_id = auth.uid());

create policy story_media_select on public.story_media for select using (true);
create policy story_media_write on public.story_media for all
  using (exists (select 1 from public.stories s where s.id = story_id and s.author_id = auth.uid()))
  with check (exists (select 1 from public.stories s where s.id = story_id and s.author_id = auth.uid()));

create policy story_views_select on public.story_views for select
  using (
    viewer_id = auth.uid()
    or exists (select 1 from public.stories s where s.id = story_id and s.author_id = auth.uid())
  );
create policy story_views_insert on public.story_views for insert with check (viewer_id = auth.uid());

create policy story_replies_select on public.story_replies for select
  using (
    sender_id = auth.uid()
    or exists (select 1 from public.stories s where s.id = story_id and s.author_id = auth.uid())
  );
create policy story_replies_insert on public.story_replies for insert with check (sender_id = auth.uid());

-- COMMENTS / LIKES / REACTIONS / BOOKMARKS
create policy comments_select on public.comments for select
  using (deleted_at is null and public.can_view_post(post_id));
create policy comments_insert on public.comments for insert
  with check (author_id = auth.uid() and public.can_view_post(post_id));
create policy comments_update on public.comments for update using (author_id = auth.uid());
create policy comments_delete on public.comments for delete using (author_id = auth.uid());

create policy likes_select on public.likes for select using (true);
create policy likes_insert on public.likes for insert with check (user_id = auth.uid());
create policy likes_delete on public.likes for delete using (user_id = auth.uid());

create policy reactions_select on public.reactions for select using (true);
create policy reactions_insert on public.reactions for insert with check (user_id = auth.uid());
create policy reactions_delete on public.reactions for delete using (user_id = auth.uid());

create policy bookmarks_select on public.bookmarks for select using (user_id = auth.uid());
create policy bookmarks_insert on public.bookmarks for insert with check (user_id = auth.uid());
create policy bookmarks_delete on public.bookmarks for delete using (user_id = auth.uid());

-- CONVERSATIONS / MESSAGES
create policy conversations_select on public.conversations for select
  using (public.is_conversation_participant(id));
create policy conversations_insert on public.conversations for insert with check (auth.uid() is not null);
create policy conversations_update on public.conversations for update
  using (public.is_conversation_participant(id));

create policy conversation_participants_select on public.conversation_participants for select
  using (public.is_conversation_participant(conversation_id) or user_id = auth.uid());
create policy conversation_participants_insert on public.conversation_participants for insert
  with check (user_id = auth.uid() or public.is_conversation_participant(conversation_id));
create policy conversation_participants_update on public.conversation_participants for update
  using (user_id = auth.uid());

create policy messages_select on public.messages for select
  using (public.is_conversation_participant(conversation_id) and deleted_at is null);
create policy messages_insert on public.messages for insert
  with check (sender_id = auth.uid() and public.is_conversation_participant(conversation_id));
create policy messages_update on public.messages for update using (sender_id = auth.uid());

-- NOTIFICATIONS / SETTINGS / SEARCH
create policy notifications_select on public.notifications for select using (recipient_id = auth.uid());
create policy notifications_update on public.notifications for update using (recipient_id = auth.uid());
create policy notifications_insert on public.notifications for insert with check (true);

create policy user_settings_all on public.user_settings for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy notification_preferences_all on public.notification_preferences for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy search_history_all on public.search_history for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Grants for authenticated / anon
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
