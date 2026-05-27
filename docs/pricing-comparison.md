# PlayGrid Club — Pricing at a glance

One-page comparison of the three engagement options. Drill into each
quote document for the full clauses.

| | **Pilot** | **Build only** | **Full launch** |
|---|---|---|---|
| Detailed quote | [`pilot-estimate.md`](pilot-estimate.md) | [`estimate.md`](estimate.md) | [`launch-and-running-costs.md`](launch-and-running-costs.md) |
| Best for | Validate inside one team for 90 days | Buy the source and operate it yourself | Production launch with a freelance retainer |
| **One-time** | **₹26,000** | **₹30,000** | **₹52,000** |
| **Monthly recurring** | ₹0 (Free tier, 90 days) | ₹0 (client runs it) | ₹12,275 |
| **Year 1 total** | **~₹26,000** | **~₹30,000** | **₹1,99,300** |
| Year 2+ steady state | not applicable (upgrade or drop) | ₹2,125 / mo Supabase (client pays direct) | ₹1,47,300 / yr |
| Users supported (MAU) | ≤ 250 | up to client's own hosting | 5,000+ |
| Platforms | Android only | Android only | Android only (iOS optional add-on) |
| Distribution | Play Console internal track only | client's choice | Play Console internal → closed → production |
| Push notifications (FCM) | ❌ in-app only | ❌ unless client builds it | ✅ included |
| Supabase tier | Free | n/a (client provisions) | Pro + Small compute |
| Daily backups | ❌ best-effort only | client's responsibility | ✅ Supabase Pro daily backups |
| Adaptive launcher icon | ❌ default Flutter icon | client supplies if desired | ✅ produced by freelancer |
| Play Store listing assets | ❌ internal track only | client's responsibility | ✅ 200-word copy + 4 screenshots + feature graphic |
| Initial QA pass | 4 hours | not included | 8 hours |
| Defect support window | 30 days (included) | 14 days (included) | 14 days (included) + ongoing retainer |
| Ongoing maintenance | pay-per-incident @ ₹1,000/hr | client's own team / freelancer rehire | 8 hrs/mo retainer |
| Acceptance criteria | `pilot-estimate.md` §11 | `estimate.md` §10 | `launch-and-running-costs.md` §10 |
| License terms | non-exclusive internal use | non-exclusive internal use | non-exclusive internal use |
| iOS launch add-on | not available | not available | ₹30,000 one-time + ₹700/mo |

## Recommended decision frame

| Client mindset | Pick |
|---|---|
| "We haven't decided if our employees will even use this." | **Pilot** |
| "We have an internal dev team that will own it after delivery." | **Build only** |
| "We're committing to PlayGrid Club as a real product for the org." | **Full launch** |

## Upgrade economics

**Pilot → Full launch.** If the pilot converts at day 90, the
freelancer credits the build delivery (₹30,000) and Play Console
registration (₹2,000) toward the full-launch one-time payment. The
client pays an upgrade one-time of **₹19,500** (instead of the
sticker ₹52,000) plus the standard ₹12,275 / month thereafter.

**Build only → Full launch.** Possible but not pre-credited. The
freelancer charges the full launch sticker minus any items already
shipped (e.g. Play Console reg). Re-quoted at the time of switch.

## What is identical across all three

- Same source codebase, same architecture, same Supabase schema.
- Same license terms: perpetual, worldwide, non-exclusive,
  non-transferable. Client cannot resell or open-source. Freelancer
  retains copyright.
- Same handover format: source in client's GitHub org + 30-minute
  screen-share.
- Same acceptance contract: build green on `flutter analyze`,
  `flutter test`, and the booking flow runs end-to-end on a real
  device.

## What is not in **any** of the three

- iOS App Store launch (full-launch add-on only).
- Payment integration (full-launch add-on only).
- Marketing, paid acquisition, ASO spend.
- Legal review of the privacy policy.
- Salaries or stipends for client-side staff.

---

| | |
|---|---|
| Quote prepared by | Venkatakrishnan Ramesh |
| GitHub | https://github.com/Venkatakrishnan-Ramesh |
| Email | _< add before sending >_ |
| Date | 2026-05-27 |
| Valid for | 30 days |
