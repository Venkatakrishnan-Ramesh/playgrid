# PlayGrid Club — Pilot Estimate

| | |
|---|---|
| **Prepared by** | Venkatakrishnan Ramesh |
| **GitHub** | https://github.com/Venkatakrishnan-Ramesh |
| **Email** | _< add before sending >_ |
| **Date** | 2026-05-27 |
| **Quote validity** | 30 days |
| **Currency** | Indian Rupees (₹). USD line items converted at **₹85 / $1** |
| **Total** | **₹26,000 one-time + ₹0 / month for the pilot quarter** |

A 3-month pilot lets the client validate PlayGrid Club inside one
team or department before committing to the full launch + retainer
budget in [`launch-and-running-costs.md`](launch-and-running-costs.md).

---

## 1. Pilot scope

| | |
|---|---|
| **Duration** | 90 days from handover |
| **Users** | Up to 250 monthly active users in **one** organization / one department |
| **Platforms** | Android only, distributed via Play Console **internal testing** track (no public listing) |
| **Backend** | Supabase **Free tier** — 500 MB DB, 50K MAU, 2 GB egress, 7-day log retention. Sufficient at pilot scale. |
| **Notifications** | In-app only. **No FCM** in pilot (deferred to full launch) |
| **Support** | 30-day defect window after handover. Pay-per-incident after that |
| **Branding** | One round: app name, primary colour, sports list, venues list. Default Flutter launcher icon retained unless client supplies a logo |

## 2. What the pilot delivers

1. Branded Android build installed on internal-testing Play Console
   track (or distributed as a direct APK if the client doesn't want a
   Play Console account yet).
2. Supabase Free-tier project with the schema applied and the
   client's seed data.
3. Source code in the client's private GitHub repo.
4. 30-minute handover screen-share.
5. 90 days of operating window inside Supabase Free quotas.

## 3. Pilot price

| Item | Cost (₹) | Notes |
|---|---:|---|
| Build delivery (existing MVP, re-branded) | 20,000 | Discounted pilot rate (standalone build is ₹30,000 — see `estimate.md` §1) |
| Google Play Console developer registration | 2,000 | Skip if client already has a console; deduct ₹2,000 |
| Pilot launch QA pass (4 hours, sanity flow on a real device) | 2,500 | Tighter than the 8-hour full-launch QA |
| Initial seed data load (sports + venues from client's spreadsheet) | 1,500 | Up to 20 rows total |
| **Pilot total** | **₹26,000** | (or ₹24,000 if Play Console already exists) |

**Monthly cost during the pilot quarter:** ₹0.

- Supabase Free tier carries the entire pilot. The client pays
  Supabase **nothing** for 90 days as long as the quotas in §1 are
  respected.
- No retainer is billed during the pilot. The 30-day defect window
  in §6 is included in the one-time price.

## 4. What's deliberately not in the pilot

| Skipped | Why |
|---|---|
| Public Google Play listing | Internal track lets a closed group test without store review and without store-listing graphics. Saves time and reduces decision pressure. |
| FCM (push notifications) | The pilot is short enough that in-app notifications give a clean read on whether users return. Adding FCM now risks confusing engagement metrics. |
| iOS build | Out of scope at this price point. Re-evaluate after pilot results. |
| Adaptive launcher icon and store graphics | Default Flutter icon is acceptable for internal testers. Designed icon is part of the full launch budget. |
| Performance tuning, query optimization | Supabase Free at 250 MAU does not need it. |
| Daily backups (paid Supabase Pro feature) | Free tier only does best-effort backups. The pilot tolerates that risk; production launch should not. |
| Compliance updates (Play target-SDK bumps) | Google ships the deadline annually; the pilot quarter is short enough to land before any cliff. |

## 5. Free-tier limits to watch

Supabase Free tier will start failing gracefully (read-only mode,
project paused) if any of these are crossed. The freelancer will
**not** be on retainer to fix this — it's a signal to upgrade to the
full launch tier.

| Resource | Free tier cap | Conservative pilot ceiling |
|---|---:|---:|
| Database size | 500 MB | ~25,000 bookings + 100 venues + 5,000 profiles |
| Monthly active users | 50,000 | n/a at 250 MAU |
| Bandwidth (egress) | 2 GB / month | Comfortable at < 500 MAU; tight if image uploads are added |
| Edge function invocations | 500K / month | Unused in this build |
| Project pause after 7 days of inactivity | Yes | Pilot must run an automated cron (or the client opens the dashboard weekly) to keep the project warm. **The freelancer will not babysit this during the pilot.** |

## 6. Support during the pilot

For 30 calendar days after handover the freelancer will fix, free of
charge, any defect that meets **all three** of:

1. Reproducible on the delivered build with the delivered seed data.
2. Caused by code that lives inside the delivered repository.
3. Filed as a GitHub issue with reproduction steps + screenshot / log.

After day 30 of the pilot, defects are billed at **₹1,000 / hour** on
written approval. The pilot does **not** include the monthly
retainer described in `launch-and-running-costs.md`.

## 7. Upgrade path after the pilot

At day 90 the client has three options:

### Option A — Drop it

Pay nothing further. The freelancer archives the GitHub repo and
Supabase project after a 7-day data-export window. The client owns
the data they put in but no further license to run new builds.

### Option B — Run as-is with no support

Take ownership of the codebase and Supabase project. Pay **₹2,125 /
month** to Supabase directly to stay on Free tier hardening or
upgrade themselves. No work from the freelancer. The license terms
in `estimate.md` §7 apply.

### Option C — Promote to full launch

Switch to [`launch-and-running-costs.md`](launch-and-running-costs.md).
The launch payment drops from ₹52,000 to **₹22,000** because the
build, QA, and seed work are already done:

| Item | Pilot | Full launch upgrade |
|---|---:|---:|
| Build delivery | ✅ paid | already credited |
| FCM integration | — | 10,000 |
| Google Play developer fee | ✅ paid | already credited |
| Launch QA (additional 4 hours for public-listing readiness) | — | 2,500 |
| Adaptive launcher icon + store graphics | — | 5,000 |
| Store listing copy + screenshots | — | 2,000 |
| Supabase Pro upgrade | — | starts at first month, ₹4,675 / mo |
| Retainer | — | ₹7,500 / mo, starts month after upgrade |
| **Upgrade one-time** | | **₹19,500** |
| **Upgrade monthly (recurring)** | | **₹12,275** |

## 8. Payment

| Stage | Amount (₹) | When |
|---|---:|---|
| Pilot advance | 13,000 | Quote sign-off, before work starts |
| Pilot balance | 13,000 | On handover (internal-track upload + GitHub handover + Supabase project provisioned) |

Indian bank transfer (NEFT / IMPS / UPI). ₹26,000 is a flat fee for
the pilot. No retainer is billed during the 90-day window unless
explicitly added via change order.

## 9. Cancellation and refunds

- Pre-work cancellation (day 0): full refund.
- During delivery: advance kept, no balance owed.
- After handover: no refund.
- Freelancer fails to deliver within 4 business days of receiving
  all client assets + 10 calendar days of slack: full refund.

## 10. License

Same as `estimate.md` §7 — perpetual, worldwide, non-exclusive,
non-transferable license for the client's own internal organizational
use only. The freelancer retains all copyright and ownership of the
PlayGrid Club source.

## 11. Acceptance criteria

The pilot is complete and the balance invoice is due when **all** are
true:

- [ ] Branded debug APK installs on a real Android device
- [ ] Internal-testing track in Play Console accepts the AAB (or the
      client confirms they don't want Play Console and the APK is
      installed on at least two real devices)
- [ ] Schema applied to the client's Supabase Free project; one admin
      account and one member account exist
- [ ] Source code in the client's GitHub org
- [ ] Handover screen-share completed

## 12. Sign-off

| | |
|---|---|
| Client name | _______________________________ |
| Client signature | _______________________________ |
| Date | _______________________________ |
| Freelancer signature | Venkatakrishnan Ramesh |
| Date | 2026-05-27 |
