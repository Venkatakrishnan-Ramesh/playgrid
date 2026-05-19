# Contributing

## Development workflow

1. Create a feature branch.
2. Keep changes focused by feature.
3. Run the checks before submitting changes:

```bash
flutter pub get
flutter analyze
flutter test
```

## Code style

- Prefer immutable models
- Keep feature logic inside `lib/features`
- Reuse the shared widgets and models
- Avoid introducing real credentials into the repo

## Pull request guidance

- Describe the user-facing change
- Note any backend schema assumptions
- Include screenshots for UI work
- Call out any manual setup steps
