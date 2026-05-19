# AGENTS.md

Guidance for AI coding agents working in this repo. Human contributor docs live in `README.md` and `CONTRIBUTING.md`.

## Project at a glance

- Flutter mobile app for **PlayGrid Club** — sports court bookings, open games, groups, tournaments, admin venue management.
- Lives under `apps/mobile/` inside the PlayGrid monorepo. Sibling: `supabase/` (schema + RPCs), `docs/` (spec, launch checklist, privacy, data safety).
- Android package id: `com.venkat.playgridclub`.
- Dart SDK `>=3.5.0 <4.0.0`, Flutter 3.24.x (stable channel).
- Deps live on pub.dev: `flutter_riverpod ^2.6.1`, `go_router ^14.8.1`, `supabase_flutter ^2.12.4`, `flutter_dotenv ^5.2.1`, `intl ^0.19.0`, `uuid ^4.5.1`.

## Repo layout

```
apps/mobile/
  lib/
    app.dart                   # MaterialApp.router(routerConfig: appRouterProvider)
    main.dart                  # entrypoint — initializes Supabase when creds are set
    core/                      # config, router, theme, services, utils, errors
    shared/                    # reusable models + widgets, mock data
    features/<feature>/
      data/                    # repositories, services (mock + supabase variants)
      domain/                  # repository interfaces, controllers
      presentation/            # screens, widgets
  android/, ios/               # platform projects
  test/                        # widget + unit tests
```

Feature-first layering. Domain interfaces live alongside the feature; do not promote them to a top-level `domain/` directory.

## Conventions

- **Immutability**: prefer `final` and `const`. Use `copyWith` for state changes.
- **Null safety**: avoid `!`. Prefer `?.`, `??`, `if (x != null)`, or pattern matching.
- **Errors**: never bare `catch`. Use `AppFailure` (see `lib/core/errors/app_failure.dart`) at boundaries.
- **Imports**: `package:playgrid_mobile/...` only — no relative imports across features.
- **Mock vs Supabase**: every external service has a mock implementation. When `SUPABASE_URL` / `SUPABASE_ANON_KEY` are unset, the app must still boot via mocks. Do not introduce code paths that require real credentials.
- **Lints**: `analysis_options.yaml` enforces `prefer_const_constructors`, `prefer_single_quotes`, `avoid_print`, `prefer_final_locals`, `always_declare_return_types`, etc. Honour them — don't relax them.

## Required checks before claiming a task is done

Run from `apps/mobile/` with Flutter on `PATH`:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --reporter expanded
```

All three must pass. CI gates on the same trio. Don't commit a diff that only passes locally because the formatter wasn't applied.

## Running the app

```bash
flutter pub get
flutter run
# with real Supabase:
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Without `--dart-define`, the app silently falls back to `LocalPlayGridRepository` + `MockAuthService` seeded from `lib/shared/models/playgrid_mock_data.dart`.

## Adding a feature

1. Create `lib/features/<feature>/{data,domain,presentation}/`.
2. Define the domain interface in `domain/`. Add a Riverpod provider in `lib/core/services/providers.dart` if it is consumed beyond the feature.
3. Provide **both** a mock and a Supabase implementation under `data/`. Wire the selection through `AppDependencies` so the mock path keeps working.
4. Add a route to `lib/core/router/app_router.dart` (paths live in `lib/core/router/route_paths.dart`).
5. Add tests under `test/` — at minimum a unit test of the repository's main happy path and a widget test of the screen's loaded state.
6. Update `README.md`'s MVP surface section if the change is user-visible.

## Things not to do

- Don't add real Supabase URLs, anon keys, FCM credentials, or signing keys to source. `--dart-define`, `flutter_dotenv`, and `flutter_secure_storage` only.
- Don't reintroduce vendored local stubs under `packages/`. Pin pub.dev versions in `pubspec.yaml`.
- Don't reach for `package:flutter` inside `domain/` files — keep domain framework-free where possible.
- Don't bypass `AppFailure`. UI screens should render failures via the shared `EmptyState` / error widgets, not raw exception strings.
- Don't edit generated code by hand (none today — keep it that way; if you introduce `freezed`/`json_serializable`, add a build_runner step and commit the generated files).
- Don't disable analyzer rules to make a diff compile. Fix the code.

## Test patterns

- Widget tests pump `ProviderScope` with overrides — see `test/widget_test.dart`.
- Repository tests construct `LocalPlayGridRepository()` directly and assert on returned state. The repository must remain instantiable with zero arguments for tests.
- Prefer hand-written fakes over mock generation. No mockito/mocktail dependency is configured.

## Release readiness

Track Play Store readiness in `../../docs/google-play-launch-checklist.md`. Privacy text lives in `../../docs/privacy-policy-draft.md`; data safety mapping in `../../docs/data-safety-notes.md`. Don't mark a launch checklist box checked from inside source code — only flip the box when the underlying artefact actually exists.
