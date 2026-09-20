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

