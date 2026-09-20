-- =============================================================
-- Gooday — Seed a partir dos mocks (src/lib/media.ts)
-- Senha demo de todos: GoodayDemo123!
-- =============================================================

create or replace function public.seed_demo_user(
  p_id uuid,
  p_email text,
  p_password text,
  p_name text,
  p_handle text,
  p_avatar text,
  p_bio text default null
) returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if exists (select 1 from auth.users where id = p_id) then
    update public.users
    set name = p_name, handle = p_handle, avatar_url = p_avatar, bio = coalesce(p_bio, bio), email = p_email
    where id = p_id;
    return;
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000',
    p_id,
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', p_name, 'handle', p_handle, 'avatar_url', p_avatar),
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(),
    p_id,
    jsonb_build_object('sub', p_id::text, 'email', p_email),
    'email',
    p_id::text,
    now(),
    now(),
    now()
  )
  on conflict do nothing;

  -- Garante perfil (trigger pode ter criado)
  insert into public.users (id, email, name, handle, avatar_url, bio)
  values (p_id, p_email, p_name, p_handle, p_avatar, p_bio)
  on conflict (id) do update set
    name = excluded.name,
    handle = excluded.handle,
    avatar_url = excluded.avatar_url,
    bio = excluded.bio,
    email = excluded.email;

  insert into public.user_settings (user_id) values (p_id) on conflict (user_id) do nothing;
  insert into public.notification_preferences (user_id) values (p_id) on conflict (user_id) do nothing;
end;
$$;

-- IDs fixos (espelham mocks)
-- marcos (currentUser), bruna, story users, contacts

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111001',
  'marcos@gooday.app', 'GoodayDemo123!',
  'Marcos Vinícius', '@marcos_v',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  'Corrida · vida saudável · Gooday'
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111002',
  'bruna@gooday.app', 'GoodayDemo123!',
  'Bruna Carla', '@bruna_carla',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  'Nutrição e bem-estar'
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111003',
  'pedro@gooday.app', 'GoodayDemo123!',
  'Pedro Runner', '@pedro.run',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  '10K e trilhas'
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111004',
  'lu@gooday.app', 'GoodayDemo123!',
  'Lu Trails', '@lu_trails',
  'https://images.unsplash.com/photo-1589729132389-8f0e0b55b91e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111005',
  'ana@gooday.app', 'GoodayDemo123!',
  'Ana Move', '@ana_move',
  'https://images.unsplash.com/photo-1701096351544-7de3c7fa0272?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111006',
  'ciclo@gooday.app', 'GoodayDemo123!',
  'Ciclo Urbano', '@ciclo_urb',
  'https://images.unsplash.com/photo-1651684215020-f7a5b6610f23?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111007',
  'joana@gooday.app', 'GoodayDemo123!',
  'Joana K', '@joana.k',
  'https://images.unsplash.com/photo-1604072366595-e75dc92d6bdc?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111008',
  'rafa@gooday.app', 'GoodayDemo123!',
  'Rafa Fit', '@rafa_fit',
  'https://images.unsplash.com/photo-1580489944761-15a19d654956?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111009',
  'mind@gooday.app', 'GoodayDemo123!',
  'Mind Zen', '@mind_zen',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111010',
  'verde@gooday.app', 'GoodayDemo123!',
  'Verde Vida', '@verdevida',
  'https://images.unsplash.com/photo-1589729132389-8f0e0b55b91e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111011',
  'carol@gooday.app', 'GoodayDemo123!',
  'Carol Fit', '@carol.fit',
  'https://images.unsplash.com/photo-1701096351544-7de3c7fa0272?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111012',
  'bike@gooday.app', 'GoodayDemo123!',
  'Bike SP', '@bike_sp',
  'https://images.unsplash.com/photo-1651684215020-f7a5b6610f23?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111013',
  'hiking@gooday.app', 'GoodayDemo123!',
  'Hiking BR', '@hiking_br',
  'https://images.unsplash.com/photo-1580489944761-15a19d654956?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  null
);

select public.seed_demo_user(
  '11111111-1111-4111-8111-111111111014',
  'natfit@gooday.app', 'GoodayDemo123!',
  'Natural Fit', '@natfit',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',
  'Conta oficial #naturalfit'
);

-- Contacts (mensagens / perfis)
select public.seed_demo_user('11111111-1111-4111-8111-111111111101','renata@gooday.app','GoodayDemo123!','Renata Silva','@renata_silva','/assets/0b179.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111102','tiago@gooday.app','GoodayDemo123!','Tiago Souza','@tiago_souza','/assets/4b35d.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111103','nicole@gooday.app','GoodayDemo123!','Nicole Bueno','@nicole_bueno','/assets/7c77a.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111104','bruno@gooday.app','GoodayDemo123!','Bruno Mendes','@bruno_mendes','/assets/2f96e.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111105','julia@gooday.app','GoodayDemo123!','Júlia Andrade','@julia_andrade','/assets/a35b8.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111106','lidiane@gooday.app','GoodayDemo123!','Lidiane Costa','@lidiane_costa','/assets/988ee.png',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111107','camila@gooday.app','GoodayDemo123!','Camila Ferreira','@camila_ferreira','https://images.unsplash.com/photo-1526080652727-5b77f74eacd2?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',null);
select public.seed_demo_user('11111111-1111-4111-8111-111111111108','marina@gooday.app','GoodayDemo123!','Marina Rocha','@marina_rocha','https://images.unsplash.com/photo-1701096351544-7de3c7fa0272?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=80&w=160&h=160',null);

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
