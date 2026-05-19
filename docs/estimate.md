# PlayGrid Club — Freelance Project Estimate

| | |
|---|---|
| **Freelancer** | Venkatakrishnan Ramesh |
| **GitHub** | https://github.com/Venkatakrishnan-Ramesh |
| **Email** | _< add before sending >_ |
| **Project** | PlayGrid Club — sports coordination mobile app |
| **Source** | https://github.com/Venkatakrishnan-Ramesh/playgrid |
| **Quote date** | 2026-05-20 |
| **Valid for** | 30 days |
| **Total** | **₹20,000 (flat)** |

This is an independent-contractor engagement. The freelancer is not
an employee of the client and is responsible for their own taxes.

---

## 1. Deliverables

A branded, working build of PlayGrid Club configured for one
organization:

1. **Android app** signed with an upload keystore and uploaded to the
   client's Google Play internal-testing track.
2. **Supabase project** provisioned with the schema, RLS policies,
   booking RPCs, and seed data from this repository.
3. **One round of branding** — app name, primary colour, adaptive
   launcher icon, splash, and the client's initial sports and venue
   lists seeded into the database.
4. **Source code** delivered as a private fork in the client's
   GitHub organization, including the Flutter app, SQL migrations,
   CI workflow, and docs.
5. **30-minute handover screen-share** covering schema changes,
   building updates, and reading CI status.

## 2. What's included (already built)

The price covers the MVP that exists in the repo today. No new
features are added under this estimate.

| Area | Included |
|---|---|
| Auth | Email / password sign-in, signup, password reset placeholder |
| Profile | Name, department, avatar URL, per-sport skill levels |
| Sports | Browse catalogue, toggle interests |
| Venues + bookings | List, detail, slot picker, **conflict-free booking** via `create_booking_safe` Postgres RPC, cancel |
| Games | Create open game, join, leave, waitlist data model |
| Groups | List, detail, join, leave |
| Events / tournaments feed | Read-only |
| Notifications | In-app list with read state |
| Admin | Dashboard, manage-venues placeholder, slot-blocking placeholder |
| Settings | Privacy policy, account-deletion request, sign out |
| Mock backend | Boots without Supabase credentials for demos |

## 3. Out of scope at ₹20,000

Requires a separate estimate:

- iOS App Store build, signing, or submission
- Push notifications (FCM is intentionally placeholder)
- Payments (Razorpay / Stripe / UPI)
- Image uploads beyond avatar URL strings
- Real-time presence / live scoreboards
- Multi-org tenancy
- Web or desktop builds
- Localization beyond English
- Custom screens or DB tables not already in the repo
- Hosting of the privacy policy or marketing site
- Play Store listing graphics beyond a 200-word description and four
  emulator screenshots (extended copy, feature graphics, video → add-on)

## 4. Branding inputs from client

Required before day 1 of work:

- App display name and Android package id (e.g. `com.acme.playgrid`)
- 1024×1024 logo (PNG with transparent background)
- Primary brand colour (hex code)
- Initial sports list (up to 12)
- Initial venues (up to 10, with address + city)
- Publicly hosted privacy-policy URL
- Google Play Console access (or invite to add freelancer as a
  release manager)
- Supabase organization invite (or Supabase access token if a Pro
  project already exists)

## 5. Timeline

| Day | Milestone |
|---|---|
| 0 | Quote signed, ₹10,000 advance received, client assets handed over |
| 1 | Supabase project provisioned, schema applied, seed data inserted |
| 2 | Branded debug build installed on a real Android device |
| 3 | Release AAB uploaded to Play Console internal-testing track |
| 4 | Handover session, balance invoice |
| 5–18 | 14-day support window (see §8) |

Days slip 1:1 with any late client asset. The 4-business-day clock
starts when **all** items in §4 are received.

## 6. Payment

| Stage | Amount | When |
|---|---|---|
| Advance | ₹10,000 | On quote sign-off, before work starts |
| Balance | ₹10,000 | On Play Console internal-track upload + GitHub handover |

NEFT / IMPS / UPI to the freelancer's bank account. ₹20,000 is a
flat fee; no additional charges unless explicitly agreed in writing
via a separate change-order.

## 7. Intellectual property — License, not transfer

The freelancer retains all copyright and ownership of the source code
and underlying product, **PlayGrid Club**.

On full payment the client receives:

- A **perpetual, worldwide, non-exclusive, non-transferable license**
  to use, run, modify, and distribute the delivered build **for the
  client's own internal organizational use only**.
- The right to maintain the delivered codebase in the client's
  private GitHub repository.

The client may **not**:

- Re-sell, sub-license, or distribute the codebase as a product to
  any third party.
- Open-source the codebase or any substantial part of it.
- Use the "PlayGrid" name or branding for any product offered to
  parties outside the client's organization.

The freelancer is free to continue developing PlayGrid Club, offer it
to other clients, and ship it as an open-source or SaaS product.

Anything the client supplies (logo, brand colour, sports / venue
data, privacy text) remains the client's property.

## 8. Support window

For 14 calendar days after handover the freelancer will fix, free of
charge, any defect that meets **all three** of:

1. Reproducible on the delivered build with the delivered seed data.
2. Caused by code that lives inside the delivered repository.
3. Filed as a GitHub issue with reproduction steps + screenshot / log.

After day 14, or for new features, design changes, or content
changes, the freelancer's hourly rate applies (quoted separately).

## 9. Cancellation and refunds

- If the client cancels before any work has started (day 0): full
  refund of the advance, minus payment-gateway fees if any.
- If the client cancels after work has started but before handover:
  the freelancer keeps the advance; no balance is owed.
- If the freelancer is unable to deliver within timeline + 10
  business days of all client assets being received, the client may
  cancel and receive a full refund of the advance.
- No refunds after handover.

## 10. Acceptance criteria

The project is complete and the balance invoice is due when **all**
are demonstrably true:

- [ ] `flutter analyze --fatal-infos` green on `main`
- [ ] `flutter test` green on `main`
- [ ] Branded debug APK installs on a real Android device and
      completes the login → home → create booking flow without crash
- [ ] Release AAB uploaded to the Play Console internal track
- [ ] Schema and seed applied to the client's Supabase project; one
      admin and one member account exist for the client to log in
- [ ] Source code in the client's GitHub org with CI green
- [ ] Handover screen-share completed

## 11. Sign-off

| | |
|---|---|
| Client name | _______________________________ |
| Client signature | _______________________________ |
| Date | _______________________________ |
| Freelancer signature | Venkatakrishnan Ramesh |
| Date | 2026-05-20 |
