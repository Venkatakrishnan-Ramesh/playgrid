-- ============================================================================
-- 002_court_slots.sql
--
-- Adds the admin-published court-slot inventory + member request flow that the
-- mobile app drives through `requestSlot`, `approveSlotRequest`,
-- `rejectSlotRequest`, `addCourtSlots`, and `removeCourtSlot`. Approving a
-- request must atomically: mark the request approved, auto-reject every other
-- still-pending sibling for the same slot once capacity is reached, create a
-- backing row in `public.bookings`, and notify every affected member. That
-- whole sequence runs server-side in `public.approve_slot_request()` so RLS
-- can stay strict without forcing the client to coordinate multiple writes.
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'slot_request_status') then
    create type public.slot_request_status as enum (
      'pending',
      'approved',
      'rejected',
      'cancelled'
    );
  end if;
end $$;

create table if not exists public.court_slots (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  sport_id uuid not null references public.sports(id) on delete restrict,
  start_at timestamptz not null,
  end_at timestamptz not null,
  capacity integer not null default 1 check (capacity >= 1),
  is_open boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint court_slots_valid_range check (end_at > start_at)
);

create unique index if not exists court_slots_unique_start
  on public.court_slots (venue_id, sport_id, start_at);

create index if not exists court_slots_open_idx
  on public.court_slots (sport_id, start_at)
  where is_open = true;

create table if not exists public.slot_requests (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid not null references public.court_slots(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.slot_request_status not null default 'pending',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles(id) on delete set null
);

-- A user can only have one live request per slot. We allow re-requesting once
-- a previous attempt was cancelled or rejected.
create unique index if not exists slot_requests_one_live
  on public.slot_requests (slot_id, user_id)
  where status in ('pending', 'approved');

create index if not exists slot_requests_status_idx
  on public.slot_requests (status, slot_id);

create index if not exists slot_requests_user_idx
  on public.slot_requests (user_id, created_at desc);

drop trigger if exists touch_court_slots_updated_at on public.court_slots;
create trigger touch_court_slots_updated_at
before update on public.court_slots
for each row execute function public.touch_updated_at();

drop trigger if exists touch_slot_requests_updated_at on public.slot_requests;
create trigger touch_slot_requests_updated_at
before update on public.slot_requests
for each row execute function public.touch_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================

alter table public.court_slots enable row level security;
alter table public.slot_requests enable row level security;

drop policy if exists "court_slots_read_all" on public.court_slots;
create policy "court_slots_read_all"
  on public.court_slots
  for select
  using (true);

drop policy if exists "court_slots_admin_manage" on public.court_slots;
create policy "court_slots_admin_manage"
  on public.court_slots
  for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "slot_requests_select_own_or_admin" on public.slot_requests;
create policy "slot_requests_select_own_or_admin"
  on public.slot_requests
  for select
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "slot_requests_insert_own" on public.slot_requests;
create policy "slot_requests_insert_own"
  on public.slot_requests
  for insert
  with check (user_id = auth.uid());

drop policy if exists "slot_requests_update_own_or_admin" on public.slot_requests;
create policy "slot_requests_update_own_or_admin"
  on public.slot_requests
  for update
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- ============================================================================
-- Functions
-- ============================================================================

-- Approve a request, optionally auto-reject siblings, mint a booking, notify.
create or replace function public.approve_slot_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_request public.slot_requests;
  v_slot public.court_slots;
  v_approved_count int;
  v_actor_name text;
  v_slot_label text;
  v_other public.slot_requests%rowtype;
begin
  if v_actor is null then
    raise exception 'auth_required';
  end if;

  if not public.is_admin() then
    raise exception 'admin_required';
  end if;

  select * into v_request from public.slot_requests where id = request_id for update;
  if not found then
    raise exception 'request_not_found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'request_not_pending';
  end if;

  select * into v_slot from public.court_slots where id = v_request.slot_id for update;
  if not found then
    raise exception 'slot_not_found';
  end if;

  select count(*)
    into v_approved_count
    from public.slot_requests
    where slot_id = v_slot.id
      and status = 'approved';

  if v_approved_count >= v_slot.capacity then
    raise exception 'slot_capacity_reached';
  end if;

  update public.slot_requests
    set status = 'approved',
        decided_at = now(),
        decided_by = v_actor
    where id = v_request.id;

  -- Mint the booking so the user sees it in their bookings list.
  insert into public.bookings (user_id, venue_id, sport_id, status,
                               slot_start, slot_end, notes)
  values (
    v_request.user_id,
    v_slot.venue_id,
    v_slot.sport_id,
    'confirmed',
    v_slot.start_at,
    v_slot.end_at,
    v_request.notes
  );

  select coalesce(name, 'Member') into v_actor_name
    from public.profiles where id = v_request.user_id;

  v_slot_label := to_char(v_slot.start_at at time zone 'UTC', 'DD/MM HH24:MI')
                  || '-' || to_char(v_slot.end_at at time zone 'UTC', 'HH24:MI');

  insert into public.notifications (user_id, type, title, body)
  values (
    v_request.user_id,
    'booking',
    'Request approved',
    'Your ' || v_slot_label || ' slot has been approved.'
  );

  -- Auto-reject the rest if capacity is now full.
  if v_approved_count + 1 >= v_slot.capacity then
    for v_other in
      select * from public.slot_requests
        where slot_id = v_slot.id
          and id <> v_request.id
          and status = 'pending'
    loop
      update public.slot_requests
        set status = 'rejected',
            decided_at = now(),
            decided_by = v_actor
        where id = v_other.id;

      insert into public.notifications (user_id, type, title, body)
      values (
        v_other.user_id,
        'booking',
        'Request not approved',
        'Your ' || v_slot_label
          || ' slot was given to another member. Try another time?'
      );
    end loop;

    update public.court_slots
      set is_open = false
      where id = v_slot.id;
  end if;
end;
$$;

grant execute on function public.approve_slot_request(uuid) to authenticated;

-- Reject a single request with an optional reason.
create or replace function public.reject_slot_request(
  request_id uuid,
  reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_request public.slot_requests;
  v_slot public.court_slots;
  v_slot_label text;
begin
  if v_actor is null then
    raise exception 'auth_required';
  end if;

  if not public.is_admin() then
    raise exception 'admin_required';
  end if;

  select * into v_request from public.slot_requests where id = request_id for update;
  if not found then
    raise exception 'request_not_found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'request_not_pending';
  end if;

  select * into v_slot from public.court_slots where id = v_request.slot_id;
  if not found then
    raise exception 'slot_not_found';
  end if;

  update public.slot_requests
    set status = 'rejected',
        decided_at = now(),
        decided_by = v_actor
    where id = v_request.id;

  v_slot_label := to_char(v_slot.start_at at time zone 'UTC', 'DD/MM HH24:MI')
                  || '-' || to_char(v_slot.end_at at time zone 'UTC', 'HH24:MI');

  insert into public.notifications (user_id, type, title, body)
  values (
    v_request.user_id,
    'booking',
    'Request not approved',
    case
      when coalesce(trim(reason), '') = '' then
        'Your ' || v_slot_label || ' slot was not approved.'
      else
        'Your ' || v_slot_label || ' slot was not approved: ' || trim(reason)
    end
  );
end;
$$;

grant execute on function public.reject_slot_request(uuid, text) to authenticated;

-- Remove a slot: cancel still-pending requests and cancel any matching
-- bookings created from approvals on this slot.
create or replace function public.remove_court_slot(slot_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_slot public.court_slots;
  v_slot_label text;
  v_req public.slot_requests%rowtype;
begin
  if v_actor is null then
    raise exception 'auth_required';
  end if;

  if not public.is_admin() then
    raise exception 'admin_required';
  end if;

  select * into v_slot from public.court_slots where id = slot_id for update;
  if not found then
    raise exception 'slot_not_found';
  end if;

  v_slot_label := to_char(v_slot.start_at at time zone 'UTC', 'DD/MM HH24:MI')
                  || '-' || to_char(v_slot.end_at at time zone 'UTC', 'HH24:MI');

  for v_req in
    select * from public.slot_requests
      where slot_id = v_slot.id and status in ('pending', 'approved')
  loop
    update public.slot_requests
      set status = 'cancelled',
          decided_at = now(),
          decided_by = v_actor
      where id = v_req.id;

    if v_req.status = 'approved' then
      update public.bookings
        set status = 'cancelled',
            cancelled_at = now(),
            cancellation_reason = 'slot_removed'
        where user_id = v_req.user_id
          and venue_id = v_slot.venue_id
          and slot_start = v_slot.start_at;
    end if;

    insert into public.notifications (user_id, type, title, body)
    values (
      v_req.user_id,
      'booking',
      case when v_req.status = 'approved'
           then 'Booking cancelled'
           else 'Slot removed'
      end,
      'The ' || v_slot_label || ' slot was removed by the admin.'
    );
  end loop;

  delete from public.court_slots where id = v_slot.id;
end;
$$;

grant execute on function public.remove_court_slot(uuid) to authenticated;

-- ============================================================================
-- Realtime
--
-- Register the booking-flow tables with Supabase's `supabase_realtime`
-- publication so authenticated clients can subscribe via
-- `supabase.channel(...).onPostgresChanges(...)`. RLS still gates which rows
-- a given user actually receives — members see their own slot_requests/
-- notifications/bookings, admins see everything. court_slots is publicly
-- readable so every signed-in user gets slot inventory changes.
-- ============================================================================

do $$
declare
  v_tbl text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach v_tbl in array array['court_slots', 'slot_requests', 'bookings', 'notifications']
    loop
      if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = v_tbl
      ) then
        execute format('alter publication supabase_realtime add table public.%I', v_tbl);
      end if;
    end loop;
  end if;
end $$;

commit;
