-- Posts do feed (mocks)
insert into public.media (id, uploader_id, url, type, alt_text) values
  ('44444444-4444-4444-8444-444444444001', '11111111-1111-4111-8111-111111111002',
   'https://images.unsplash.com/photo-1610970881699-44a5587cabec?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=1080', 'IMAGE', 'Smoothie'),
  ('44444444-4444-4444-8444-444444444002', '11111111-1111-4111-8111-111111111003',
   'https://images.unsplash.com/photo-1530143311094-34d807799e8f?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'IMAGE', 'Trail run')
on conflict (id) do nothing;

insert into public.posts (id, author_id, body, audience, created_at) values
  ('55555555-5555-4555-8555-555555555001', '11111111-1111-4111-8111-111111111002',
   'Hoje foi o dia daquela bebida natural', 'PUBLIC', now() - interval '5 minutes'),
  ('55555555-5555-4555-8555-555555555002', '11111111-1111-4111-8111-111111111003',
   'Fechei os 10K de manhã cedo. Respeite sua mente e trate seu corpo bem!', 'PUBLIC', now() - interval '32 minutes')
on conflict (id) do nothing;

insert into public.post_media (post_id, media_id, "order") values
  ('55555555-5555-4555-8555-555555555001', '44444444-4444-4444-8444-444444444001', 0),
  ('55555555-5555-4555-8555-555555555002', '44444444-4444-4444-8444-444444444002', 0)
on conflict do nothing;

insert into public.post_tags (post_id, tag) values
  ('55555555-5555-4555-8555-555555555001', '#natural'),
  ('55555555-5555-4555-8555-555555555001', '#suconatural'),
  ('55555555-5555-4555-8555-555555555002', '#corrida'),
  ('55555555-5555-4555-8555-555555555002', '#10k')
on conflict do nothing;

insert into public.post_mentions (post_id, user_id) values
  ('55555555-5555-4555-8555-555555555001', '11111111-1111-4111-8111-111111111014')
on conflict do nothing;

-- Reactions (amostra representativa dos counts do mock)
insert into public.reactions (user_id, post_id, emoji)
select u.id, '55555555-5555-4555-8555-555555555001', e.emoji
from (values
  ('11111111-1111-4111-8111-111111111001'::uuid, '💪'),
  ('11111111-1111-4111-8111-111111111003', '💪'),
  ('11111111-1111-4111-8111-111111111101', '💪'),
  ('11111111-1111-4111-8111-111111111105', '🌱'),
  ('11111111-1111-4111-8111-111111111107', '🌱')
) as e(uid, emoji)
join public.users u on u.id = e.uid
on conflict do nothing;

insert into public.reactions (user_id, post_id, emoji)
select e.uid, '55555555-5555-4555-8555-555555555002', e.emoji
from (values
  ('11111111-1111-4111-8111-111111111001'::uuid, '🔥'),
  ('11111111-1111-4111-8111-111111111002', '🔥'),
  ('11111111-1111-4111-8111-111111111101', '🏃'),
  ('11111111-1111-4111-8111-111111111102', '🏃')
) as e(uid, emoji)
on conflict do nothing;

insert into public.likes (user_id, post_id)
select id, '55555555-5555-4555-8555-555555555001'
from public.users
where handle in ('@marcos_v','@pedro.run','@renata_silva','@julia_andrade','@tiago_souza')
on conflict do nothing;

insert into public.likes (user_id, post_id)
select id, '55555555-5555-4555-8555-555555555002'
from public.users
where handle in ('@marcos_v','@bruna_carla','@renata_silva','@ana_move','@lu_trails','@rafa_fit')
on conflict do nothing;

insert into public.comments (id, post_id, author_id, body, created_at) values
  ('66666666-6666-4666-8666-666666666001', '55555555-5555-4555-8555-555555555001',
   '11111111-1111-4111-8111-111111111001', 'Quero a receita! 🌱', now() - interval '3 minutes'),
  ('66666666-6666-4666-8666-666666666002', '55555555-5555-4555-8555-555555555002',
   '11111111-1111-4111-8111-111111111101', 'Monstro! Bora domingo?', now() - interval '20 minutes')
on conflict (id) do nothing;

insert into public.bookmarks (user_id, post_id) values
  ('11111111-1111-4111-8111-111111111001', '55555555-5555-4555-8555-555555555002')
on conflict do nothing;

-- Stories (ativos 24h) — um por autor do carousel (exceto "Você"/marcos já incluso)
insert into public.stories (id, author_id, status, expires_at, created_at) values
  ('77777777-7777-4777-8777-777777777001', '11111111-1111-4111-8111-111111111001', 'ACTIVE', now() + interval '24 hours', now() - interval '1 hour'),
  ('77777777-7777-4777-8777-777777777002', '11111111-1111-4111-8111-111111111002', 'ACTIVE', now() + interval '24 hours', now() - interval '2 hours'),
  ('77777777-7777-4777-8777-777777777003', '11111111-1111-4111-8111-111111111004', 'ACTIVE', now() + interval '24 hours', now() - interval '3 hours'),
  ('77777777-7777-4777-8777-777777777004', '11111111-1111-4111-8111-111111111003', 'ACTIVE', now() + interval '24 hours', now() - interval '30 minutes'),
  ('77777777-7777-4777-8777-777777777005', '11111111-1111-4111-8111-111111111005', 'ACTIVE', now() + interval '24 hours', now() - interval '4 hours'),
  ('77777777-7777-4777-8777-777777777006', '11111111-1111-4111-8111-111111111006', 'ACTIVE', now() + interval '24 hours', now() - interval '5 hours'),
  ('77777777-7777-4777-8777-777777777007', '11111111-1111-4111-8111-111111111007', 'ACTIVE', now() + interval '24 hours', now() - interval '1 hour'),
  ('77777777-7777-4777-8777-777777777008', '11111111-1111-4111-8111-111111111008', 'ACTIVE', now() + interval '24 hours', now() - interval '6 hours'),
  ('77777777-7777-4777-8777-777777777009', '11111111-1111-4111-8111-111111111009', 'ACTIVE', now() + interval '24 hours', now() - interval '2 hours'),
  ('77777777-7777-4777-8777-777777777010', '11111111-1111-4111-8111-111111111010', 'ACTIVE', now() + interval '24 hours', now() - interval '90 minutes'),
  ('77777777-7777-4777-8777-777777777011', '11111111-1111-4111-8111-111111111011', 'ACTIVE', now() + interval '24 hours', now() - interval '7 hours'),
  ('77777777-7777-4777-8777-777777777012', '11111111-1111-4111-8111-111111111012', 'ACTIVE', now() + interval '24 hours', now() - interval '40 minutes'),
  ('77777777-7777-4777-8777-777777777013', '11111111-1111-4111-8111-111111111013', 'ACTIVE', now() + interval '24 hours', now() - interval '8 hours'),
  ('77777777-7777-4777-8777-777777777014', '11111111-1111-4111-8111-111111111014', 'ACTIVE', now() + interval '24 hours', now() - interval '50 minutes')
on conflict (id) do nothing;

insert into public.media (id, uploader_id, url, type) values
  ('44444444-4444-4444-8444-444444444101', '11111111-1111-4111-8111-111111111001', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444102', '11111111-1111-4111-8111-111111111002', 'https://images.unsplash.com/photo-1518708909080-704599b19972?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444103', '11111111-1111-4111-8111-111111111004', 'https://images.unsplash.com/photo-1522075782449-e45a34f1ddfb?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444104', '11111111-1111-4111-8111-111111111003', 'https://images.unsplash.com/photo-1744060204728-f68e434a3edf?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444105', '11111111-1111-4111-8111-111111111005', 'https://images.unsplash.com/photo-1759476530066-94bee6a30c40?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444106', '11111111-1111-4111-8111-111111111006', 'https://images.unsplash.com/photo-1606224547099-b15c94ca5ef2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444107', '11111111-1111-4111-8111-111111111007', 'https://images.unsplash.com/photo-1480179087180-d9f0ec044897?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444108', '11111111-1111-4111-8111-111111111008', 'https://images.unsplash.com/photo-1567013514336-6de53c9e7e63?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444109', '11111111-1111-4111-8111-111111111009', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444110', '11111111-1111-4111-8111-111111111010', 'https://images.unsplash.com/photo-1543352632-5a4b24e4d2a6?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444111', '11111111-1111-4111-8111-111111111011', 'https://images.unsplash.com/photo-1606858374191-c18040e98ad7?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444112', '11111111-1111-4111-8111-111111111012', 'https://images.unsplash.com/photo-1615845522846-02f89af04c2e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444113', '11111111-1111-4111-8111-111111111013', 'https://images.unsplash.com/photo-1533240332313-0db49b459ad6?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE'),
  ('44444444-4444-4444-8444-444444444114', '11111111-1111-4111-8111-111111111014', 'https://images.unsplash.com/photo-1530143311094-34d807799e8f?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=400&h=700', 'IMAGE')
on conflict (id) do nothing;

insert into public.story_media (story_id, media_id, "order")
select s.id, m.id, 0
from (values
  ('77777777-7777-4777-8777-777777777001'::uuid, '44444444-4444-4444-8444-444444444101'::uuid),
  ('77777777-7777-4777-8777-777777777002', '44444444-4444-4444-8444-444444444102'),
  ('77777777-7777-4777-8777-777777777003', '44444444-4444-4444-8444-444444444103'),
  ('77777777-7777-4777-8777-777777777004', '44444444-4444-4444-8444-444444444104'),
  ('77777777-7777-4777-8777-777777777005', '44444444-4444-4444-8444-444444444105'),
  ('77777777-7777-4777-8777-777777777006', '44444444-4444-4444-8444-444444444106'),
  ('77777777-7777-4777-8777-777777777007', '44444444-4444-4444-8444-444444444107'),
  ('77777777-7777-4777-8777-777777777008', '44444444-4444-4444-8444-444444444108'),
  ('77777777-7777-4777-8777-777777777009', '44444444-4444-4444-8444-444444444109'),
  ('77777777-7777-4777-8777-777777777010', '44444444-4444-4444-8444-444444444110'),
  ('77777777-7777-4777-8777-777777777011', '44444444-4444-4444-8444-444444444111'),
  ('77777777-7777-4777-8777-777777777012', '44444444-4444-4444-8444-444444444112'),
  ('77777777-7777-4777-8777-777777777013', '44444444-4444-4444-8444-444444444113'),
  ('77777777-7777-4777-8777-777777777014', '44444444-4444-4444-8444-444444444114')
) as x(sid, mid)
join public.stories s on s.id = x.sid
join public.media m on m.id = x.mid
on conflict do nothing;

-- Story views (seen flags do mock)
insert into public.story_views (story_id, viewer_id)
select s.id, '11111111-1111-4111-8111-111111111001'
from public.stories s
where s.id in (
  '77777777-7777-4777-8777-777777777002',
  '77777777-7777-4777-8777-777777777003',
  '77777777-7777-4777-8777-777777777006',
  '77777777-7777-4777-8777-777777777008',
  '77777777-7777-4777-8777-777777777011',
  '77777777-7777-4777-8777-777777777013'
)
on conflict do nothing;

