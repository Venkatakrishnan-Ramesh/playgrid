# PlayGrid Club

Monorepo for the PlayGrid Club sports coordination product.

## Layout

```
playgrid/
├── apps/
│   └── mobile/                 Flutter app (Android + iOS)
├── supabase/
│   ├── migrations/             SQL schema, RLS, RPCs
│   │   ├── 001_initial_schema.sql
│   │   └── 002_court_slots.sql Court inventory + slot-request RPCs
│   └── seed.sql                Sample sports + venues + admin/member accounts
├── docs/
│   ├── product-spec.md
│   ├── google-play-launch-checklist.md
│   ├── privacy-policy-draft.md
│   └── data-safety-notes.md
└── .github/
    └── workflows/
        └── flutter-ci.yml      analyze + test on every push / PR
```

## Quick start (mobile app)

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Without Supabase credentials the app boots against the in-memory mock
backend seeded from `lib/shared/models/playgrid_mock_data.dart`. Sign in
with any seeded account using the password `password`:

| Email                  | Role   | Notes                                          |
|------------------------|--------|------------------------------------------------|
| `admin@playgrid.club`  | admin  | Lands on the admin dashboard (requests, slots) |
| `arjun@acme.com`       | member | Default test member used in the seed bookings  |
| `priya@acme.com`       | member | Has a seeded pending tennis request            |
| `kevin@acme.com`       | member | Has a seeded pending tennis request            |

Open the **Tennis bookings** tile from the home grid to request a slot,
or the **Admin dashboard** tile (admin-only) to approve / reject
requests and publish new slots across a date range.

To run against a real backend:

```bash
cd apps/mobile
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Database

Apply the schema and seed against a Supabase project:

```bash
# from repo root, with the Supabase CLI logged in to the target project
supabase db push          # applies supabase/migrations/*.sql
psql "$SUPABASE_DB_URL" -f supabase/seed.sql
```

Both migrations are idempotent (use `create ... if not exists`,
`do $$ ... if not exists`, and `create or replace function`) so reapplying
is safe. The seed promotes `admin@playgrid.club` to the `admin` role and
publishes 12 tennis slots (today + next 2 days, 5–9 PM) plus two
competing pending requests on tomorrow's 6 PM slot so the admin
dashboard has something to review immediately.

In the seeded database every demo account (admin and members) uses
`password123`.

## CI

`flutter-ci.yml` runs from `apps/mobile/`:

1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze --fatal-infos`
4. `flutter test --reporter expanded`

Same commands are the local pre-commit contract.

## Further reading

- Mobile-specific conventions: [`apps/mobile/AGENTS.md`](apps/mobile/AGENTS.md)
- Contributor workflow: [`apps/mobile/CONTRIBUTING.md`](apps/mobile/CONTRIBUTING.md)
- Product spec: [`docs/product-spec.md`](docs/product-spec.md)
- Play Store readiness: [`docs/google-play-launch-checklist.md`](docs/google-play-launch-checklist.md)
