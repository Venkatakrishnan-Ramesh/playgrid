# PlayGrid Club — Mobile

Flutter Android/iOS client for PlayGrid Club. Part of the monorepo at
the repo root; see the [root README](../../README.md) for layout and
the [docs/](../../docs/) folder for product spec, launch checklist,
privacy policy, and data safety notes.

## Tech stack

- Flutter (stable, 3.24.x)
- Riverpod (`flutter_riverpod ^2.6.1`) for state
- GoRouter (`go_router ^14.8.1`) for navigation
- Supabase Flutter (`supabase_flutter ^2.12.4`) for auth + Postgres
- `flutter_dotenv`, `intl`, `uuid`
- Material 3

## Layout

- `lib/core` — config, router, theme, services, utilities
- `lib/shared` — reusable models, widgets, and mock data
- `lib/features/<feature>/{data,domain,presentation}` — feature-first
- `android/`, `ios/` — platform projects
- `test/` — widget + unit tests

## Setup

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Optional Supabase configuration (otherwise the app boots against the
in-memory mock backend):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## MVP surface

- Auth: login, signup, forgot password placeholder
- Profile: profile editing and sports preferences
- Home: dashboard cards, booking preview, open games preview
- Sports: catalogue and interest selection
- Venues and bookings: venue list, slot picker, create / cancel booking
- Games: open games, create / join / leave, waitlist-aware data model
- Groups: list, detail, join / leave, member placeholder
- Admin: admin dashboard, venue management placeholder, slot blocking
- Notifications: list with in-app read state
- Settings: privacy policy, account deletion request, logout

## Notes

- App package name: `com.venkat.playgridclub`
- Release builds require an upload keystore — see
  `android/key.properties.example` for the template
- FCM is intentionally placeholder-only in this MVP

## Related docs

- [`CONTRIBUTING.md`](CONTRIBUTING.md)
- [`AGENTS.md`](AGENTS.md) — guidance for AI coding agents
- [`../../docs/product-spec.md`](../../docs/product-spec.md)
- [`../../docs/google-play-launch-checklist.md`](../../docs/google-play-launch-checklist.md)
- [`../../docs/privacy-policy-draft.md`](../../docs/privacy-policy-draft.md)
- [`../../docs/data-safety-notes.md`](../../docs/data-safety-notes.md)
