# Google Play Launch Checklist

## App identity

- [ ] Confirm app name: PlayGrid Club
- [ ] Confirm Android application ID: `com.venkat.playgridclub`
- [ ] Confirm signing key and release keystore are ready

## Product readiness

- [ ] Replace placeholder privacy policy with final text
- [ ] Replace FCM placeholder with a working Firebase configuration
- [ ] Connect Supabase credentials in production
- [ ] Verify booking conflict handling in staging
- [ ] Verify admin role restrictions
- [ ] Verify logout and account deletion request flow

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
