begin;

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'profile_role') then
    create type public.profile_role as enum ('member', 'admin', 'super_admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'skill_level') then
    create type public.skill_level as enum ('beginner', 'intermediate', 'advanced', 'pro');
  end if;

  if not exists (select 1 from pg_type where typname = 'booking_status') then
    create type public.booking_status as enum ('confirmed', 'cancelled', 'completed', 'blocked');
  end if;

  if not exists (select 1 from pg_type where typname = 'game_status') then
    create type public.game_status as enum ('open', 'full', 'in_progress', 'completed', 'cancelled');
  end if;

  if not exists (select 1 from pg_type where typname = 'player_status') then
    create type public.player_status as enum ('joined', 'waitlisted', 'left');
  end if;

  if not exists (select 1 from pg_type where typname = 'membership_status') then
    create type public.membership_status as enum ('member', 'pending', 'left');
  end if;

  if not exists (select 1 from pg_type where typname = 'group_visibility') then
    create type public.group_visibility as enum ('public', 'closed', 'private');
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum ('booking', 'game', 'group', 'event', 'system');
  end if;

  if not exists (select 1 from pg_type where typname = 'event_type') then
    create type public.event_type as enum ('tournament', 'blocked_slot', 'announcement', 'other');
  end if;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text not null unique,
  department text,
  avatar_url text,
  role public.profile_role not null default 'member',
  skill_level public.skill_level not null default 'beginner',
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sports (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  icon_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_sports (
  user_id uuid not null references public.profiles(id) on delete cascade,
  sport_id uuid not null references public.sports(id) on delete cascade,
  interest_level integer not null default 3 check (interest_level between 1 and 5),
  skill_level public.skill_level not null default 'beginner',
  created_at timestamptz not null default now(),
  primary key (user_id, sport_id)
);

create table if not exists public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  address text not null,
  city text not null,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  opening_hours jsonb not null default '{}'::jsonb,
  amenities jsonb not null default '[]'::jsonb,
  supported_sports jsonb not null default '[]'::jsonb,
  contact_phone text,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  venue_id uuid not null references public.venues(id) on delete restrict,
  sport_id uuid references public.sports(id) on delete set null,
  status public.booking_status not null default 'confirmed',
  slot_start timestamptz not null,
  slot_end timestamptz not null,
  booking_range tstzrange generated always as (tstzrange(slot_start, slot_end, '[)')) stored,
  notes text,
  cancellation_reason text,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookings_valid_range check (slot_end > slot_start)
);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  venue_id uuid references public.venues(id) on delete set null,
  sport_id uuid not null references public.sports(id) on delete restrict,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  max_players integer not null default 10 check (max_players > 0),
  waitlist_enabled boolean not null default true,
  status public.game_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint games_valid_range check (end_time > start_time)
);

create table if not exists public.game_players (
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.player_status not null default 'joined',
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (game_id, user_id)
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  department_scope text,
  visibility public.group_visibility not null default 'public',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null default 'member',
  status public.membership_status not null default 'member',
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  venue_id uuid references public.venues(id) on delete set null,
  group_id uuid references public.groups(id) on delete set null,
  sport_id uuid references public.sports(id) on delete set null,
  event_kind public.event_type not null default 'other',
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  capacity integer,
  status text not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint events_valid_range check (end_time > start_time)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null default 'system',
  title text not null,
  body text not null,
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists venues_name_city_key on public.venues (name, city);
create index if not exists venues_active_idx on public.venues (is_active);
create index if not exists sports_active_idx on public.sports (is_active);
create index if not exists bookings_user_time_idx on public.bookings (user_id, slot_start desc);
create index if not exists bookings_venue_time_idx on public.bookings (venue_id, slot_start desc);
create index if not exists games_status_time_idx on public.games (status, start_time);
create index if not exists groups_active_idx on public.groups (is_active);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

alter table public.bookings
  add constraint bookings_venue_no_overlap
  exclude using gist (
    venue_id with =,
    booking_range with &&
  )
  where (status in ('confirmed', 'blocked'));

alter table public.bookings
  add constraint bookings_user_no_overlap
  exclude using gist (
    user_id with =,
    booking_range with &&
  )
  where (status = 'confirmed');

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_sports_updated_at on public.sports;
create trigger touch_sports_updated_at
before update on public.sports
for each row execute function public.touch_updated_at();

drop trigger if exists touch_user_sports_updated_at on public.user_sports;
create trigger touch_user_sports_updated_at
before update on public.user_sports
for each row execute function public.touch_updated_at();

drop trigger if exists touch_venues_updated_at on public.venues;
create trigger touch_venues_updated_at
before update on public.venues
for each row execute function public.touch_updated_at();

drop trigger if exists touch_bookings_updated_at on public.bookings;
create trigger touch_bookings_updated_at
before update on public.bookings
for each row execute function public.touch_updated_at();

drop trigger if exists touch_games_updated_at on public.games;
create trigger touch_games_updated_at
before update on public.games
for each row execute function public.touch_updated_at();

drop trigger if exists touch_groups_updated_at on public.groups;
create trigger touch_groups_updated_at
before update on public.groups
for each row execute function public.touch_updated_at();

drop trigger if exists touch_game_players_updated_at on public.game_players;
create trigger touch_game_players_updated_at
before update on public.game_players
for each row execute function public.touch_updated_at();

drop trigger if exists touch_group_members_updated_at on public.group_members;
create trigger touch_group_members_updated_at
before update on public.group_members
for each row execute function public.touch_updated_at();

drop trigger if exists touch_events_updated_at on public.events;
create trigger touch_events_updated_at
before update on public.events
for each row execute function public.touch_updated_at();

drop trigger if exists touch_notifications_updated_at on public.notifications;
create trigger touch_notifications_updated_at
before update on public.notifications
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role, skill_level)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(new.email, ''),
    'member',
    'beginner'
  )
  on conflict (id) do update
    set email = excluded.email,
        name = coalesce(nullif(public.profiles.name, ''), excluded.name),
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.current_profile_role()
returns public.profile_role
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'member'::public.profile_role
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_profile_role() in ('admin', 'super_admin');
$$;

create or replace function public.create_booking_safe(
  p_venue_id uuid,
  p_sport_id uuid,
  p_slot_start timestamptz,
  p_slot_end timestamptz,
  p_notes text default null
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_booking public.bookings;
begin
  if v_user_id is null then
    raise exception 'auth_required';
  end if;

  if p_slot_end <= p_slot_start then
    raise exception 'invalid_slot_range';
  end if;

  perform 1
  from public.venues
  where id = p_venue_id
    and is_active = true;

  if not found then
    raise exception 'venue_not_found_or_inactive';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.user_id = v_user_id
      and b.status = 'confirmed'
      and b.booking_range && tstzrange(p_slot_start, p_slot_end, '[)')
  ) then
    raise exception 'user_booking_conflict';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.venue_id = p_venue_id
      and b.status = 'confirmed'
      and b.booking_range && tstzrange(p_slot_start, p_slot_end, '[)')
  ) then
    raise exception 'venue_booking_conflict';
  end if;

  insert into public.bookings (
    user_id,
    venue_id,
    sport_id,
    status,
    slot_start,
    slot_end,
    notes
  )
  values (
    v_user_id,
    p_venue_id,
    p_sport_id,
    'confirmed',
    p_slot_start,
    p_slot_end,
    p_notes
  )
  returning * into v_booking;

  return v_booking;
exception
  when exclusion_violation then
    raise exception 'booking_conflict_detected';
end;
$$;

create or replace function public.cancel_booking(p_booking_id uuid, p_reason text default null)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings;
begin
  update public.bookings
  set status = 'cancelled',
      cancelled_at = now(),
      cancellation_reason = coalesce(p_reason, cancellation_reason)
  where id = p_booking_id
    and user_id = auth.uid()
  returning * into v_booking;

  if not found then
    raise exception 'booking_not_found_or_not_owned';
  end if;

  return v_booking;
end;
$$;

alter table public.profiles enable row level security;
alter table public.sports enable row level security;
alter table public.user_sports enable row level security;
alter table public.venues enable row level security;
alter table public.bookings enable row level security;
alter table public.games enable row level security;
alter table public.game_players enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.events enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles
for select
using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles
for update
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists "sports_read_active" on public.sports;
create policy "sports_read_active"
on public.sports
for select
using (is_active = true);

drop policy if exists "sports_admin_manage" on public.sports;
create policy "sports_admin_manage"
on public.sports
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "user_sports_select_own" on public.user_sports;
create policy "user_sports_select_own"
on public.user_sports
for select
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "user_sports_manage_own" on public.user_sports;
create policy "user_sports_manage_own"
on public.user_sports
for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "venues_read_active" on public.venues;
create policy "venues_read_active"
on public.venues
for select
using (is_active = true or public.is_admin());

drop policy if exists "venues_admin_manage" on public.venues;
create policy "venues_admin_manage"
on public.venues
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "bookings_select_own" on public.bookings;
create policy "bookings_select_own"
on public.bookings
for select
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "bookings_insert_own" on public.bookings;
create policy "bookings_insert_own"
on public.bookings
for insert
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "bookings_update_own_or_admin" on public.bookings;
create policy "bookings_update_own_or_admin"
on public.bookings
for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "games_read_open_or_own" on public.games;
create policy "games_read_open_or_own"
on public.games
for select
using (
  status in ('open', 'full')
  or created_by = auth.uid()
  or public.is_admin()
);

drop policy if exists "games_manage_own_or_admin" on public.games;
create policy "games_manage_own_or_admin"
on public.games
for all
using (created_by = auth.uid() or public.is_admin())
with check (created_by = auth.uid() or public.is_admin());

drop policy if exists "game_players_select_own_or_creator" on public.game_players;
create policy "game_players_select_own_or_creator"
on public.game_players
for select
using (
  user_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1 from public.games g
    where g.id = game_id and g.created_by = auth.uid()
  )
);

drop policy if exists "game_players_manage_own_or_admin" on public.game_players;
create policy "game_players_manage_own_or_admin"
on public.game_players
for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "groups_read_active" on public.groups;
create policy "groups_read_active"
on public.groups
for select
using (is_active = true or public.is_admin());

drop policy if exists "groups_manage_own_or_admin" on public.groups;
create policy "groups_manage_own_or_admin"
on public.groups
for all
using (created_by = auth.uid() or public.is_admin())
with check (created_by = auth.uid() or public.is_admin());

drop policy if exists "group_members_select_own_or_group_owner" on public.group_members;
create policy "group_members_select_own_or_group_owner"
on public.group_members
for select
using (
  user_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1 from public.groups g
    where g.id = group_id and g.created_by = auth.uid()
  )
);

drop policy if exists "group_members_manage_own_or_admin" on public.group_members;
create policy "group_members_manage_own_or_admin"
on public.group_members
for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "events_read_public_or_own" on public.events;
create policy "events_read_public_or_own"
on public.events
for select
using (public.is_admin() or created_by = auth.uid() or status = 'published');

drop policy if exists "events_admin_manage" on public.events;
create policy "events_admin_manage"
on public.events
for all
using (public.is_admin() or created_by = auth.uid())
with check (public.is_admin() or created_by = auth.uid());

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

commit;
