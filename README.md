# PlayGrid Club

PlayGrid Club is an org-focused sports coordination app for court bookings, open games, groups, tournaments, and admin venue management.

## Tech Stack

- Flutter
- Riverpod-style local provider layer
- `go_router`-style local router layer
- Supabase-compatible backend abstraction
- Material 3

## Repo Layout

- `lib/core` - config, router, theme, services, utilities
- `lib/shared` - reusable models and widgets
- `lib/features` - feature-first presentation screens
- `packages` - local offline-resolvable packages for router and providers
- `android` / `ios` - platform projects

## Setup

1. Install Flutter and make sure the SDK is available.
2. From `playgrid-mobile`, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

3. Optional Supabase configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If the credentials are not provided, the app uses the built-in mock backend and still runs.

## Current MVP Surface

- Auth: login, signup, forgot password placeholder
- Profile: profile editing and sports preferences
- Home: dashboard cards, booking preview, open games preview
- Sports: catalog and interest selection
- Venues and bookings: venue list, slot picker, create/cancel booking
- Games: open games, create/join/leave, waitlist-aware data model
- Groups: list, detail, join/leave, member placeholder
- Admin: admin dashboard, venue management placeholder, slot blocking placeholder
- Notifications: list and in-app placeholder read state
- Settings: privacy policy placeholder, account deletion request, logout

## Notes

- App package name: `com.venkat.playgridclub`
- Mock data is enabled automatically when Supabase credentials are missing
- FCM is intentionally placeholder-only in this MVP

## Related Docs

- `CONTRIBUTING.md`
- `launch-checklist-google-play.md`
- `privacy-policy-draft.md`
- `data-safety-notes.md`
