# PlayGrid Club — Project Estimate

| | |
|---|---|
| **Vendor** | Venkatakrishnan Ramesh |
| **Project** | PlayGrid Club — sports coordination mobile app |
| **Repository** | https://github.com/Venkatakrishnan-Ramesh/playgrid |
| **Date** | 2026-05-20 |
| **Quote validity** | 30 days |
| **Total** | **₹20,000 (INR), inclusive of all taxes** |

---

## 1. What the client receives

A working, branded build of PlayGrid Club configured for one
organization, deployed end-to-end:

1. **Android app** signed with an upload keystore, uploaded to a Google
   Play internal-testing track in the client's Play Console.
2. **Supabase project** provisioned with the schema, RLS policies,
   booking RPCs, and seed data already in this repo.
3. **One round of branding** — app name, colour, launcher icon,
   splash, and content for sports / venues seeded from a list the
   client provides.
4. **Source code** in the client's GitHub organization, including:
   - Flutter app at `apps/mobile/`
   - SQL migrations at `supabase/migrations/`
   - CI workflow (`.github/workflows/flutter-ci.yml`)
   - Docs at `docs/`
5. **Handover session** — 30-minute screen-share covering how to:
   - Apply schema changes with the Supabase CLI
   - Build and ship updates with `flutter build appbundle`
   - Read CI status on GitHub

## 2. Feature scope (already implemented)

The price covers the MVP that exists in the repo today. No new
features are added under this estimate.

| Area | Included |
|---|---|
| Auth | Email / password sign-in, signup, password reset placeholder |
| Profile | Edit name / department / avatar URL, per-sport skill levels |
| Sports | Browse catalogue, toggle interests |
| Venues | List, detail, slot picker, **conflict-free booking** via `create_booking_safe` RPC |
| Bookings | Create, cancel, my-bookings list |
| Games | Create open game, join, leave, waitlist data model |
| Groups | List, detail, join, leave |
| Events | Tournaments / blocked slots feed |
| Notifications | In-app list with read state |
| Admin | Dashboard, manage-venues placeholder, slot-blocking placeholder |
| Settings | Privacy policy, account-deletion request, sign out |
| Mock backend | Boots without Supabase credentials for demos and offline dev |

## 3. Branding scope

| Item | Included | Provided by |
|---|---|---|
| App display name | ✅ | Client |
| Android `applicationId` (package name) | ✅ | Client |
| Primary brand colour | ✅ | Client |
| Launcher icon (adaptive — foreground + background) | ✅ | Client supplies a 1024×1024 logo; vendor produces adaptive layers |
| Splash background | ✅ | Vendor |
| Initial sports list (max 12) | ✅ | Client |
| Initial venues (max 10) | ✅ | Client |
| Privacy-policy text + hosting URL | ✅ | Client |

## 4. Out of scope at ₹20,000

Anything below requires a separate estimate before work starts:

- iOS App Store build, signing, and submission (the iOS folder
  compiles but no Apple Developer enrolment is included)
- Push notifications (FCM is intentionally placeholder)
- Payment integration (Razorpay / Stripe / UPI)
- Image uploads beyond avatar URL strings
- Real-time presence or live scoreboards
- Multi-org tenancy / org switcher
- Web build, desktop build
- Localization beyond English
- Custom Flutter screens or DB tables not already in the repo
- Bug fixes after the 14-day support window in §7
- Hosting of the privacy policy or marketing site
- Play Store listing graphics: feature graphic, phone / tablet
  screenshots, copywriting (vendor will produce screenshots from the
  emulator and a 200-word description — anything beyond that is
  additional)

## 5. Tech stack

- Flutter 3.24 stable, Dart 3.5
- Riverpod 2.6 (state), GoRouter 14.8 (navigation)
- Supabase 2.12 — Postgres + Auth + RLS
- GitHub Actions CI: format / analyze / test on every push
- Android: `compileSdk 34`, `minSdk 21`, `targetSdk 34`, R8 minify on
  release builds, network security config blocking cleartext

## 6. Timeline

| Day | Milestone |
|---|---|
| 0 | Estimate signed, 50 % advance received |
| 1 | Client assets received (logo, brand colour, sports list, venues list, privacy URL) |
| 2 | Supabase project provisioned + schema applied |
| 3 | Branded build installed on internal-testing track |
| 4 | Handover session, balance invoice |
| 5–18 | 14-day support window (see §7) |

Slippage caused by missing client assets is not counted against the
4-business-day delivery commitment.

## 7. Support window

For 14 calendar days after handover the vendor will fix, free of
charge, any defect that meets **all** of:

1. Reproducible on the delivered build with the delivered seed data.
2. Caused by code that lives inside this repository.
3. Filed as a GitHub issue with reproduction steps and a screenshot or
   log.

Out of scope of the support window: new features, design changes,
content changes, anything caused by Supabase configuration the client
changed after handover.

## 8. Payment

| Stage | Amount | When |
|---|---|---|
| Advance | ₹10,000 | On estimate sign-off (before work starts) |
| Balance | ₹10,000 | On Play Console internal-track upload + source handover |

- Indian bank transfer (NEFT / IMPS / UPI) preferred. Invoice issued
  for both stages.
- All taxes (including 18 % GST if applicable to the client's billing
  state) are included in the ₹20,000 total. No hidden fees.

## 9. Assumptions

- Client owns a Google Play Console account in good standing and has
  paid the one-time ₹2,000 developer fee. The vendor does not pay
  this on the client's behalf.
- Client provides a Supabase organization the vendor can be added to,
  or a Supabase Pro project the vendor will configure.
- Client provides a public URL where the privacy policy will live.
  Hosting that page is not part of this estimate.
- The repository remains on GitHub. Self-hosted Git (GitLab self-host,
  Bitbucket DC) requires an additional ₹3,000 to migrate the CI
  workflow and document the new setup.

## 10. Acceptance criteria

The project is considered complete and the balance invoice is due
when **all** of the following are demonstrably true:

- [ ] `flutter analyze --fatal-infos` clean on `main`
- [ ] `flutter test` green on `main`
- [ ] Branded debug APK installs on a real Android device with no
      crashes between launch and at least one successful booking
- [ ] Release AAB uploaded to the Play Console internal-testing track
- [ ] Schema and seed applied to the client's Supabase project; one
      admin and one member account exist
- [ ] Source code lives in the client's GitHub organization with CI
      green
- [ ] Handover session completed

## 11. Signatures

| | |
|---|---|
| Client name | _______________________________ |
| Client signature | _______________________________ |
| Date | _______________________________ |
| Vendor signature | Venkatakrishnan Ramesh |
| Date | 2026-05-20 |
