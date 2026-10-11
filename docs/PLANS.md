# Battleplan plans: Free and Plus

This is the one place that says what each plan includes. SPEC §6.14 (PLAN) has the requirements and ARCH §6.11 the design; when they disagree with this table, this table wins and they get fixed.

**Everything a team needs to run is free, forever.** Chat, photos, the schedule and RSVPs, polls, documents, notifications, youth teams and guardians, invites, and every safety feature stay on the Free plan. Plus adds polish, room to grow, and tools for busy admins. Nothing a team already relies on ever moves behind the paywall.

## Price

| | |
|---|---|
| **Plus** | **$70 per team per year**, or **$7 per month** |
| **Free** | $0 |

A Plus license belongs to the person who bought it (or who a super admin granted it to), not to the team. They can move it to any team they're an owner or admin of, and the remaining time moves with it.

## What's different

| Feature | Free | Plus |
|---|---|---|
| **Chat** | | |
| Messages, photos (10 per message), replies, links | ✓ | ✓ |
| Reactions | 👍 ❤️ 👎 😂 | The four, plus 12 more, including sport emojis (🔥 👏 🎉 💯 🙏 😮 😢 😡 ⚾ 🏀 ⚽ 🏆) |
| **Edit your own messages** (marked "edited") | — | ✓ |
| **Customize the chat's look**: bubble color from the team color or a palette, and a chat background | Default look | ✓ |
| Pin messages to the top of the chat | — | ✓ |
| **Schedule and attendance** | | |
| Events, repeating events, reminders, RSVPs, "All my teams" | ✓ | ✓ |
| Attendance history per member or player, and CSV export of RSVPs and the roster | — | ✓ |
| **Storage and files** | | |
| Team storage | 5 GB | 25 GB |
| Largest document upload | 25 MB | 100 MB |
| **Team page** | | |
| Invite page with the team name, sport, and member count | ✓ | ✓ |
| Invite page with the team's logo and color | — | ✓ |
| **Support** | | |
| Help by email | ✓ | ✓, answered first |
| **Always free on both plans** | | |
| Youth teams, guardians, per-player RSVPs | ✓ | ✓ |
| Polls, documents, notifications | ✓ | ✓ |
| Report, block, moderation, account deletion | ✓ | ✓ |

## Getting Plus

- **At launch:** a super admin grants a one-year license from the admin panel, to a person and a team. This is how the first paid teams are handled: they pay outside the app, and we apply the license.
- **Later:** self-serve checkout on the web, for the yearly or monthly price, and in-app purchase in the iPhone and Android apps (SPEC Q19).

**Store rules.** Apple requires anything that unlocks features in the iPhone app to be sold through in-app purchase too: features bought on the web may be unlocked only if they're "also available as in-app purchases within the app" (App Store Review Guideline 3.1.3(b)), and apps may not unlock features with their own license keys (3.1.1). So before the iPhone app is in the App Store with Plus, Plus must also be an in-app purchase. Apple keeps 15% under its Small Business Program (30% above $1M a year), so a $70 year nets about $59.50. In the US storefront the app may also show a button to the web checkout (3.1.1(a)). Google Play's rules are looser in the US for now (other payment methods and links are allowed while a court order is in effect) and stricter elsewhere, so the Android app sells Plus through Google Play Billing too (15% on subscriptions). Licenses a super admin grants stay fine alongside in-app purchase, as purchases made outside the app (3.1.3(b)).

## When Plus ends

Thirty days and seven days before a license ends, the holder and the team's admins get a reminder. When it ends, the team goes back to Free with nothing deleted:

- Edited messages stay as edited; nobody can edit new ones.
- Extra reactions already on messages stay; new ones use the four free reactions.
- The chat goes back to its default look; the custom settings are kept in case Plus returns.
- Pinned messages stay pinned but can't be changed until Plus returns.
- If the team uses more than 5 GB, nothing is deleted, but new uploads stop until it's under 5 GB or Plus returns.
- Attendance history stays; exports stop.

## Moving a license

The holder can move a license to another team they're an owner or admin of. The old team goes back to Free and the new team gets the remaining time. To stop one license rotating across many teams, it can move once every 30 days; a super admin can move it any time.

## Open questions

These have defaults so work can continue; see SPEC §12 (Q17 to Q21).

- **Q17** What's the paid plan called? Default: **Plus**.
- **Q18** Monthly vs yearly when a super admin grants a license. Default: grants are whole months, one year by default; the $7 monthly price applies once self-serve checkout exists.
- **Q19** How people pay. Default: super-admin grants while we're in beta; before Plus ships in the App Store, add in-app purchase in the iPhone and Android apps (required by Apple's guideline 3.1.3(b), about 15% fee) and Stripe checkout on the web (about 3%), at the same $70 / $7 price. US iPhone users also get a button to the web checkout. Decide whether to charge more in the apps to cover the store fee.
- **Q20** Grace period after a license ends. Default: none beyond the reminders; the team returns to Free on the end date.
- **Q21** Should Plus be offered per person as well (for example, extra emojis everywhere)? Default: no, per team only.
