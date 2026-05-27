# PlayGrid Club — Launch and Running Cost Estimate

| | |
|---|---|
| **Prepared by** | Venkatakrishnan Ramesh |
| **GitHub** | https://github.com/Venkatakrishnan-Ramesh |
| **Email** | _< add before sending >_ |
| **Date** | 2026-05-27 |
| **Quote validity** | 30 days |
| **Currency** | Indian Rupees (₹). USD line items converted at **₹85 / $1** |

This document covers the **total cost to launch and run PlayGrid Club
for one year**, on top of the one-time build delivery quoted
separately in [`estimate.md`](estimate.md).

---

## Scope assumptions (locked with client)

| Question | Assumption |
|---|---|
| Year 1 user scale | 5,000+ monthly active users (multi-department / growth scenario) |
| Platforms | Android only (Google Play). iOS is deferred. |
| Push notifications | FCM included in launch scope |
| Ongoing role | Monthly retainer for bug fixes, compliance, monitoring |
| Hosting | Supabase Pro + Small compute add-on; privacy policy on GitHub Pages |

**⚠️ Honesty note.** The ₹30,000 build fee covers the existing MVP
re-branded for one organization. The 5,000+ user scenario will
**exercise** that MVP — performance tuning, query optimization,
Realtime config, and admin tooling beyond the placeholders all
become real work the moment the user count climbs. If utilization
hits the upper end of this estimate, expect a re-quote against
actual usage data after month 3.

---

## 1. One-time costs (launch)

| Item | Cost (₹) | Notes |
|---|---:|---|
| Build delivery (existing MVP, re-branded) | 30,000 | Per `estimate.md` §1 |
| FCM (push notifications) — code, AndroidManifest, server-key wiring, one test campaign | 10,000 | Free at runtime; this is dev time |
| Google Play Console developer registration | 2,000 | One-time, lifetime, paid to Google |
| Launch QA pass on a real device (8 hours) | 5,000 | Tracked as a separate sprint after handover |
| Adaptive launcher icon production (foreground + background + 512×512 store icon) | 3,000 | Only if client doesn't already have a design system |
| Play Store listing — 200-word description, 4 emulator screenshots, one feature graphic | 2,000 | Anything more (video, copywriting) is extra |
| **One-time subtotal** | **₹52,000** | |

## 2. Year 1 monthly recurring

| Item | Monthly (₹) | Annual (₹) | Notes |
|---|---:|---:|---|
| Supabase Pro tier | 2,125 | 25,500 | $25/mo. Includes 8 GB DB, 100K MAU, 250 GB bandwidth, daily backups |
| Supabase Small compute add-on | 2,550 | 30,600 | $30/mo. 1 vCPU / 1 GB RAM. Headroom for 5K MAU. Upgrade to Medium ($60) if p95 query latency exceeds 300 ms |
| Maintenance retainer (≈ 8 hours / month) | 7,500 | 90,000 | Bug fixes, dependency bumps, Play Store target-SDK compliance, Supabase log review, schema migrations |
| Custom domain for privacy policy + landing (`.com`, optional) | 100 | 1,200 | Skip if using GitHub Pages on the default subdomain |
| Firebase Cloud Messaging | 0 | 0 | FCM is free at any scale; only dev cost is the one-time setup |
| **Monthly subtotal** | **₹12,275** | **₹147,300** | |

## 3. Year 1 grand total

| | Amount |
|---|---:|
| One-time (§1) | ₹52,000 |
| Annual recurring (§2 × 12) | ₹147,300 |
| **Year 1 total** | **₹199,300** |

Payable as a ₹52,000 launch payment up front, then ₹12,275 per
month. The retainer can be paid quarterly (₹22,500) or annually
(₹85,000 — 6 % discount) if preferred.

## 4. Year 2+ steady state

| Item | Monthly (₹) | Annual (₹) |
|---|---:|---:|
| Supabase Pro + Small compute | 4,675 | 56,100 |
| Maintenance retainer | 7,500 | 90,000 |
| Domain renewal | 100 | 1,200 |
| **Year 2+ annual** | | **₹147,300** |

No further one-time spend unless new features are commissioned. Year
2 budget can drop to **₹56,100** if the client takes ownership of
maintenance and the retainer is dropped (Supabase + domain only).

## 5. Optional add-ons (not in the base estimate)

Quoted at the time of work. Indicative prices for context only:

| Add-on | One-time (₹) | Recurring (₹/mo) |
|---|---:|---:|
| iOS App Store launch (Apple Developer + signing + submission) | 30,000 | 700 (Apple Dev: $99/yr ÷ 12) |
| Razorpay / UPI payments for paid bookings | 20,000 | 0 (Razorpay charges 2 % per txn, billed to client by Razorpay) |
| Image uploads (avatars, venue photos) via Supabase Storage | 8,000 | 850 (storage + egress at projected volume) |
| Real-time presence on open games | 15,000 | included (already on Pro tier) |
| Multi-org tenancy (org switcher + RLS rewrite) | 60,000 | 0 |
| Web build (`flutter build web` + hosting) | 12,000 | 500 (Cloudflare Pages — likely free, budget conservative) |
| Localization to one Indian language | 10,000 | 0 |
| Performance audit + query tuning if Supabase compute hits Medium | 8,000 | 0 (covered by retainer if already on it) |

## 6. Cost drivers worth watching

These are the levers most likely to make the budget go up or down:

1. **MAU growth past 100,000.** Supabase Pro covers 100K MAU. Beyond
   that, each additional 1,000 MAU is roughly $0.00325 (~₹0.28). A
   200K MAU month would add ~₹28,000/year.
2. **Bandwidth.** 250 GB/mo is generous for this app's payload sizes,
   but if avatar / venue images get added, this can spike. Each
   extra 100 GB is $9 (~₹765/mo).
3. **Database storage.** 8 GB covers tens of thousands of bookings.
   At 10K bookings/year per 1,000 users, this is comfortable for at
   least 3 years. After that, archive cold rows.
4. **Compute upgrade.** Small → Medium is the most common upgrade.
   Trigger: sustained p95 query latency above 300 ms or CPU above
   60 % for a week. Cost delta: +$30/mo (~₹2,550/mo).
5. **Retainer hours.** 8 hrs/month is a midpoint. If the first
   quarter shows < 4 hrs/month of real work, drop the retainer to a
   pay-per-incident structure and save ~₹40,000/year.

## 7. What the retainer covers

The ₹7,500/month retainer entitles the client to:

- Up to **8 hours of work per month**, billed in 30-minute blocks.
  Unused hours expire at end of month (no rollover).
- Bug fixes for defects matching the criteria in `estimate.md` §8,
  beyond the initial 14-day support window.
- Dependency security patches (Dart / Flutter / package CVEs).
- Annual Google Play `targetSdkVersion` bumps required by Play
  policy.
- Supabase log review once per quarter and a 1-page health report.
- One re-deployment of the Play Store listing per month.

**Excluded** from the retainer:

- New features or screens (separate quote).
- Design changes beyond minor visual tweaks.
- Recovery from data loss caused by client actions in the Supabase
  dashboard.
- Performance incidents originating outside the codebase (Supabase
  region outage, Google Play store rejection on policy grounds).

Hours beyond the monthly 8 are billed at **₹1,000 / hour** with the
client's written approval before work starts.

## 8. Payment schedule (summary)

| Stage | Amount (₹) | When |
|---|---:|---|
| Build advance | 10,000 | Quote sign-off, before work starts |
| Build balance | 20,000 | On Play Console internal-track upload + GitHub handover |
| Launch payment | 22,000 | After acceptance criteria pass (§10 of `estimate.md`) — covers FCM + Play registration + QA + icon + listing |
| Monthly retainer + infra | 12,275 | First of each month, starting month 2 |

Optional discount: paying the full Year 1 (₹199,300 − 6 % retainer
discount = **₹194,000**) up front locks the retainer rate against
revision for 12 months.

## 9. What's outside this estimate entirely

- Salaries or stipends for client-side staff (admins, moderators).
- Marketing, paid acquisition, ASO spend.
- Legal review of the privacy policy or data-handling practices.
- HR / device management for distributing the APK internally before
  Play Store rollout.
- Anything not in `estimate.md` §2 or in this document's §1–§5.

## 10. Sign-off

| | |
|---|---|
| Client name | _______________________________ |
| Client signature | _______________________________ |
| Date | _______________________________ |
| Freelancer signature | Venkatakrishnan Ramesh |
| Date | 2026-05-27 |
