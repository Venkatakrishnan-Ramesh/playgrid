begin;

-- ===========================================================================
-- Sports
-- ===========================================================================
insert into public.sports (name, slug, description, icon_name, is_active)
values
  ('Badminton', 'badminton', 'Fast indoor rally sport.', 'sports_tennis', true),
  ('Cricket', 'cricket', 'Organized nets, box cricket, and tournament play.', 'sports_cricket', true),
  ('Football', 'football', '5-a-side and full pitch bookings.', 'sports_soccer', true),
  ('Basketball', 'basketball', 'Half-court and full-court sessions.', 'sports_basketball', true),
  ('Table Tennis', 'table-tennis', 'Quick doubles and ladder matches.', 'table_tennis', true),
  ('Volleyball', 'volleyball', 'Casual and competitive indoor play.', 'sports_volleyball', true)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    icon_name = excluded.icon_name,
    is_active = excluded.is_active;

-- ===========================================================================
-- Venues
-- ===========================================================================
insert into public.venues (name, slug, description, address, city, latitude, longitude, opening_hours, amenities, supported_sports, contact_phone, is_active)
values
  ('PlayGrid Arena', 'playgrid-arena', 'Premium indoor courts with evening lighting and locker rooms.', '12 Tech Park Road', 'Bengaluru', 12.9716000, 77.5946000, '{"mon-fri":{"open":"06:00","close":"22:30"},"sat-sun":{"open":"07:00","close":"22:00"}}', '["parking","washrooms","changing_room","water_station"]', '["badminton","table-tennis","basketball"]', '+91-90000-11111', true),
  ('North Campus Sports Hub', 'north-campus-sports-hub', 'Organized turf and court bookings for teams and employee clubs.', '88 Enterprise Avenue', 'Bengaluru', 12.9352000, 77.6245000, '{"mon-fri":{"open":"05:30","close":"21:30"},"sat-sun":{"open":"06:00","close":"21:30"}}', '["parking","cafe","showers","spectator_seating"]', '["football","cricket","volleyball"]', '+91-90000-22222', true),
  ('Skyline Court Club', 'skyline-court-club', 'Compact venue for after-work games and structured leagues.', '41 Startup Street', 'Bengaluru', 12.9098000, 77.6387000, '{"mon-fri":{"open":"07:00","close":"23:00"},"sat-sun":{"open":"08:00","close":"23:00"}}', '["parking","lights","changing_room"]', '["badminton","football","basketball"]', '+91-90000-33333', true),
  ('Riverside Turf', 'riverside-turf', 'Floodlit 7-a-side turf beside the river promenade.', '5 Riverside Walk', 'Bengaluru', 12.9600000, 77.6400000, '{"mon-fri":{"open":"06:00","close":"23:00"},"sat-sun":{"open":"06:00","close":"23:30"}}', '["parking","lights","cafe"]', '["football","cricket"]', '+91-90000-44444', true),
  ('Downtown Smash Center', 'downtown-smash-center', 'Air-conditioned badminton and table tennis hall.', '210 MG Road', 'Bengaluru', 12.9750000, 77.6050000, '{"mon-fri":{"open":"06:30","close":"22:00"},"sat-sun":{"open":"07:00","close":"22:00"}}', '["parking","ac","pro_shop"]', '["badminton","table-tennis"]', '+91-90000-55555', true)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    address = excluded.address,
    city = excluded.city,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    opening_hours = excluded.opening_hours,
    amenities = excluded.amenities,
    supported_sports = excluded.supported_sports,
    contact_phone = excluded.contact_phone,
    is_active = excluded.is_active;

-- ===========================================================================
-- Demo members (auth users + profiles). These give games/groups/events an
-- owner and populate the "Add friends" directory. Password: password123
-- ===========================================================================
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change, email_change_token_new
)
select
  '00000000-0000-0000-0000-000000000000',
  u.id, 'authenticated', 'authenticated', u.email,
  crypt('password123', gen_salt('bf')),
  now(), now(), now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('name', u.name),
  '', '', '', ''
from (values
  ('11111111-1111-1111-1111-111111111111'::uuid, 'priya@acme.com', 'Priya Nair'),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'kevin@acme.com', 'Kevin Thomas'),
  ('33333333-3333-3333-3333-333333333333'::uuid, 'sara@acme.com', 'Sara Iyer'),
  ('44444444-4444-4444-4444-444444444444'::uuid, 'diego@acme.com', 'Diego Alvarez')
) as u(id, email, name)
on conflict (id) do nothing;

insert into auth.identities (
  provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  u.email, u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email', now(), now(), now()
from (values
  ('11111111-1111-1111-1111-111111111111'::uuid, 'priya@acme.com'),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'kevin@acme.com'),
  ('33333333-3333-3333-3333-333333333333'::uuid, 'sara@acme.com'),
  ('44444444-4444-4444-4444-444444444444'::uuid, 'diego@acme.com')
) as u(id, email)
on conflict do nothing;

-- The on_auth_user_created trigger already created base profile rows; enrich them.
update public.profiles as p set
  department = v.department,
  avatar_url = v.avatar_url,
  skill_level = v.skill_level
from (values
  ('11111111-1111-1111-1111-111111111111'::uuid, 'Design', 'https://i.pravatar.cc/150?img=5', 'advanced'::public.skill_level),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'Sales', 'https://i.pravatar.cc/150?img=12', 'intermediate'::public.skill_level),
  ('33333333-3333-3333-3333-333333333333'::uuid, 'Engineering', 'https://i.pravatar.cc/150?img=32', 'advanced'::public.skill_level),
  ('44444444-4444-4444-4444-444444444444'::uuid, 'Marketing', 'https://i.pravatar.cc/150?img=15', 'beginner'::public.skill_level)
) as v(id, department, avatar_url, skill_level)
where p.id = v.id;

-- ===========================================================================
-- Games (status 'open' so every signed-in member can see them)
-- ===========================================================================
insert into public.games (created_by, venue_id, sport_id, title, description, start_time, end_time, max_players, waitlist_enabled, status)
values
  ('11111111-1111-1111-1111-111111111111', (select id from public.venues where slug='playgrid-arena'), (select id from public.sports where slug='badminton'), 'Badminton Corporate Clash', '4v4 ladder match with rolling substitutions.', now() + interval '2 days', now() + interval '2 days 2 hours', 8, true, 'open'),
  ('22222222-2222-2222-2222-222222222222', (select id from public.venues where slug='riverside-turf'), (select id from public.sports where slug='football'), 'Friday Turf Sprint', 'Fast-paced 7-a-side for mixed skill levels.', now() + interval '3 days', now() + interval '3 days 2 hours', 14, true, 'open'),
  ('33333333-3333-3333-3333-333333333333', (select id from public.venues where slug='downtown-smash-center'), (select id from public.sports where slug='table-tennis'), 'Lunchtime Table Tennis', 'Quick doubles ladder over the lunch break.', now() + interval '1 day', now() + interval '1 day 1 hour', 4, true, 'open'),
  ('44444444-4444-4444-4444-444444444444', (select id from public.venues where slug='skyline-court-club'), (select id from public.sports where slug='basketball'), 'Weekend Basketball Run', 'Half-court 3v3 runs, winner stays on.', now() + interval '4 days', now() + interval '4 days 2 hours', 12, true, 'open');

-- A few joined players so creators see populated rosters.
insert into public.game_players (game_id, user_id, status)
select g.id, p.user_id, 'joined'::public.player_status
from public.games g
join (values
  ('Badminton Corporate Clash', '33333333-3333-3333-3333-333333333333'::uuid),
  ('Friday Turf Sprint', '11111111-1111-1111-1111-111111111111'::uuid),
  ('Friday Turf Sprint', '44444444-4444-4444-4444-444444444444'::uuid)
) as p(title, user_id) on p.title = g.title
on conflict (game_id, user_id) do nothing;

-- ===========================================================================
-- Groups (public + active so they appear for everyone)
-- ===========================================================================
insert into public.groups (created_by, name, slug, description, department_scope, visibility, is_active)
values
  ('33333333-3333-3333-3333-333333333333', 'Engineering Badminton Club', 'engineering-badminton-club', 'Weekly ladder for the product and platform teams.', 'Engineering', 'public', true),
  ('22222222-2222-2222-2222-222222222222', 'Open Turf Crew', 'open-turf-crew', 'Open invites for football and futsal evenings.', 'All', 'public', true),
  ('11111111-1111-1111-1111-111111111111', 'Table Tennis Ladder', 'table-tennis-ladder', 'Friendly office-wide TT ranking ladder.', 'All', 'public', true)
on conflict (slug) do nothing;

insert into public.group_members (group_id, user_id, member_role, status)
select grp.id, m.user_id, m.member_role, 'member'::public.membership_status
from public.groups grp
join (values
  ('engineering-badminton-club', '33333333-3333-3333-3333-333333333333'::uuid, 'owner'),
  ('engineering-badminton-club', '11111111-1111-1111-1111-111111111111'::uuid, 'member'),
  ('open-turf-crew', '22222222-2222-2222-2222-222222222222'::uuid, 'owner'),
  ('open-turf-crew', '44444444-4444-4444-4444-444444444444'::uuid, 'member'),
  ('table-tennis-ladder', '11111111-1111-1111-1111-111111111111'::uuid, 'owner')
) as m(slug, user_id, member_role) on m.slug = grp.slug
on conflict (group_id, user_id) do nothing;

-- ===========================================================================
-- Events (status 'published' so everyone can see them)
-- ===========================================================================
insert into public.events (created_by, venue_id, sport_id, event_kind, title, description, start_time, end_time, capacity, status)
values
  ('33333333-3333-3333-3333-333333333333', (select id from public.venues where slug='playgrid-arena'), (select id from public.sports where slug='badminton'), 'tournament', 'Inter-Department Tournament', 'Badminton and football finals this quarter.', now() + interval '7 days', now() + interval '7 days 4 hours', 64, 'published'),
  ('22222222-2222-2222-2222-222222222222', (select id from public.venues where slug='north-campus-sports-hub'), null, 'announcement', 'Summer Sports Meet — Registrations Open', 'Sign up your team across five sports.', now() + interval '14 days', now() + interval '14 days 6 hours', null, 'published');

commit;
