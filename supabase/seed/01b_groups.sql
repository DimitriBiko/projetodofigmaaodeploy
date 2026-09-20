-- Interests
insert into public.interests (id, name, slug) values
  ('22222222-2222-4222-8222-222222222001', 'Corrida', 'corrida'),
  ('22222222-2222-4222-8222-222222222002', 'Ciclismo', 'ciclismo'),
  ('22222222-2222-4222-8222-222222222003', 'Nutrição', 'nutricao'),
  ('22222222-2222-4222-8222-222222222004', 'Yoga', 'yoga'),
  ('22222222-2222-4222-8222-222222222005', 'Vida Natural', 'vida-natural')
on conflict (slug) do nothing;

insert into public.user_interests (user_id, interest_id)
select u.id, i.id
from public.users u
cross join public.interests i
where u.handle in ('@marcos_v', '@bruna_carla', '@pedro.run', '@renata_silva', '@tiago_souza', '@julia_andrade')
  and i.slug in ('corrida', 'nutricao', 'ciclismo')
on conflict do nothing;

-- Follows (Marcos segue vários)
insert into public.follows (follower_id, following_id)
select '11111111-1111-4111-8111-111111111001', id
from public.users
where handle in ('@bruna_carla','@pedro.run','@renata_silva','@tiago_souza','@julia_andrade','@lu_trails','@ana_move')
on conflict do nothing;

insert into public.follows (follower_id, following_id)
select id, '11111111-1111-4111-8111-111111111001'
from public.users
where handle in ('@bruna_carla','@renata_silva','@nicole_bueno','@marina_rocha')
on conflict do nothing;

-- Groups (slugs do mock)
insert into public.groups (id, name, slug, description, cover_url, privacy) values
  ('33333333-3333-4333-8333-333333333001', 'Corrida para Iniciantes', 'corrida', 'Comece a correr com a gente', 'https://images.unsplash.com/photo-1498581444814-7e44d2fbe0e2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC'),
  ('33333333-3333-4333-8333-333333333002', 'Ciclismo Urbano', 'ciclismo', 'Pedal pela cidade', 'https://images.unsplash.com/photo-1606224547099-b15c94ca5ef2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC'),
  ('33333333-3333-4333-8333-333333333003', 'Nutrição Consciente', 'nutricao', 'Comer bem sem neura', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC'),
  ('33333333-3333-4333-8333-333333333004', 'Vida Natural', 'vida', 'Hábitos naturais no dia a dia', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC'),
  ('33333333-3333-4333-8333-333333333005', 'Yoga & Respiração', 'yoga', 'Prática e presença', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC'),
  ('33333333-3333-4333-8333-333333333006', 'Pedal de Fim de Semana', 'pedal', 'Rolês de bike no fim de semana', 'https://images.unsplash.com/photo-1615845522846-02f89af04c2e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=900', 'PUBLIC')
on conflict (slug) do nothing;

insert into public.group_interests (group_id, interest_id)
select g.id, i.id from public.groups g join public.interests i on i.slug = case g.slug
  when 'corrida' then 'corrida'
  when 'ciclismo' then 'ciclismo'
  when 'pedal' then 'ciclismo'
  when 'nutricao' then 'nutricao'
  when 'vida' then 'vida-natural'
  when 'yoga' then 'yoga'
end
on conflict do nothing;

-- Marcos owner de corrida; membros demo
insert into public.group_members (group_id, user_id, role, status) values
  ('33333333-3333-4333-8333-333333333001', '11111111-1111-4111-8111-111111111001', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333001', '11111111-1111-4111-8111-111111111003', 'ADMIN', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333001', '11111111-1111-4111-8111-111111111101', 'MEMBER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333002', '11111111-1111-4111-8111-111111111006', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333002', '11111111-1111-4111-8111-111111111001', 'MEMBER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333003', '11111111-1111-4111-8111-111111111002', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333003', '11111111-1111-4111-8111-111111111001', 'MEMBER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333004', '11111111-1111-4111-8111-111111111010', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333005', '11111111-1111-4111-8111-111111111009', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333006', '11111111-1111-4111-8111-111111111012', 'OWNER', 'ACTIVE'),
  ('33333333-3333-4333-8333-333333333006', '11111111-1111-4111-8111-111111111001', 'MEMBER', 'ACTIVE')
on conflict (group_id, user_id) do nothing;
