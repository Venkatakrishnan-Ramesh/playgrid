# Google Play Launch Checklist

## App identity

- [x] Confirm app name: PlayGrid Club
- [x] Confirm Android application ID: `com.venkat.playgridclub`
- [ ] Generate upload keystore and `android/key.properties`
      (template at `android/key.properties.example`; signing config is wired
      in `android/app/build.gradle` and activates when the file is present)

## Product readiness

- [ ] Replace placeholder privacy policy with final text
- [ ] Replace FCM placeholder with a working Firebase configuration
- [ ] Replace vendored `packages/supabase_flutter` placeholder with real
      `supabase_flutter` from pub.dev and connect production credentials
- [ ] Verify booking conflict handling in staging
- [ ] Verify admin role restrictions
- [ ] Verify logout and account deletion request flow
- [x] Network security config enforces HTTPS-only in release builds
- [x] `INTERNET` permission declared in the production manifest

## Store assets

- [ ] App icon
- [ ] Feature graphic
- [ ] Phone screenshots
- [ ] Tablet screenshots if needed
- [ ] Short description
- [ ] Full store description

## Compliance

- [ ] Data safety form completed
- [ ] Privacy policy hosted at a public URL
- [ ] Content rating questionnaire completed
- [ ] Target audience and ads declarations completed

## Release process

- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Build release APK or AAB
- [ ] Upload to internal testing first
- [ ] Validate install, sign in, booking, and logout on a real device
- [ ] Promote to closed/open testing before production
