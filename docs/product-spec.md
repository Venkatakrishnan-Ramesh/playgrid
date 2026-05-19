# PlayGrid Club — Product Spec

## Purpose

PlayGrid Club is an org-internal sports coordination app for booking
courts, organizing open games, and running departmental groups,
tournaments, and announcements. It replaces ad-hoc WhatsApp threads and
shared spreadsheets for the "who is playing what, where, and when"
problem inside a single organization.

## In scope (MVP)

- Email + password authentication (Supabase Auth) with admin-elevated
  roles
- Profile with department, avatar, and per-sport skill levels
- Browse sports catalogue and toggle interests
- Browse venues, view detail, create / cancel court bookings
- Conflict-free booking via the `create_booking_safe` Postgres function
- Open games: create, join, leave, waitlist-aware data model
- Groups: list, detail, join / leave, member placeholder
- Events feed (tournaments, blocked slots, announcements)
- Notifications list with in-app read-state
- Admin surface: dashboard, manage venues (placeholder), block slots
- Settings, hosted privacy policy, account-deletion request
- Mock-data fallback that boots the entire app with no backend
  credentials present (developer ergonomics + offline demo)

## Out of scope (MVP)

- Real-time presence / live scoreboards
- Payments, paid bookings, refunds
- Image uploads beyond avatar URL strings
- Push notifications (FCM is a placeholder; not wired in MVP)
- Multi-org tenancy / org switcher
- Web / desktop builds (mobile only)
- Localization beyond English

## Personas

- **Member** — books courts, joins games, manages personal profile.
- **Admin** — manages venues, blocks slots for maintenance, moderates
  groups, oversees bookings.
- **Super admin** — same as admin plus role assignment.

## Core flows

1. **Sign in → home** — auth, then bootstrap state from Supabase (or
   mock backend if `SUPABASE_URL` / `SUPABASE_ANON_KEY` are not set).
2. **Book a court** — venues → venue detail → slot picker → create
   booking → confirmation. The Postgres `create_booking_safe` RPC
   guarantees no overlapping confirmed bookings for the same venue or
   user.
3. **Cancel a booking** — my bookings → cancel; the `cancel_booking`
   RPC marks the row cancelled and records the reason.
4. **Open game** — create open game with start / end / capacity → other
   members join → waitlist when capacity is reached.
5. **Group** — discover groups → join → see members → leave.
6. **Admin** — log in as admin role → admin dashboard → manage venues
   and slot blocks.

## Data model (high level)

See `supabase/migrations/001_initial_schema.sql` for the source of
truth. Tables: `profiles`, `sports`, `user_sports`, `venues`,
`bookings`, `games`, `game_players`, `groups`, `group_members`,
`events`, `notifications`. RLS is enabled on every table; admin /
super_admin elevation goes through the `current_profile_role` and
`is_admin` SECURITY DEFINER helpers.

## Architecture

- Flutter app at `apps/mobile/`
  - Riverpod for state, GoRouter for navigation
  - Feature-first folders under `lib/features/`
  - Repository pattern with `LocalPlayGridRepository` (mock) and
    `SupabasePlayGridRepository` (real) swapping at boot based on
    `AppConfig.hasSupabaseCredentials`
- Supabase backend at `supabase/`
  - PostgreSQL schema + RLS policies + RPCs in
    `migrations/001_initial_schema.sql`
  - Sample data in `seed.sql`

## Non-goals around correctness

- The MVP intentionally does not solve double-booking via optimistic
  client logic. The Postgres function is the source of truth.
- Profile completion is enforced via a router redirect, not by gating
  every screen.

## Open questions

- FCM integration timing
- Native payment integration for paid venues
- Multi-org tenancy strategy (subdomain vs. role flag)
