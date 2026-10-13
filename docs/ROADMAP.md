# Battleplan — Roadmap

Every task and feature for Battleplan, in one numbered list, in the order they should happen. It pulls together [SPEC.md](SPEC.md) (features and milestones), [ARCHITECTURE.md](ARCHITECTURE.md) (how it's built), and [TODO.md](../TODO.md) (accounts and purchases).

**How to read it**

- Numbers run continuously from the first task to the last, so "task 14" always means the same thing. Order follows dependencies: a task never needs something further down the list.
- ✅ done · 👤 **Jared** (only you can do it: accounts, payments, decisions) · everything else is build work.
- Feature IDs (AUTH-1, CHAT-6, …) point to SPEC §6. The details live there; this file is the order.
- Milestones M0 to M8 each ended working on iOS, Android, and web, with rules tests updated (SPEC §9). Go-live then runs in six phases, web first (below). Until Phase 4 the native apps keep building and passing tests, but don't ship.

Last updated: 2026-10-12. M5 (Polls), M6 (Schedule), M7 (Documents), and M8 (God admin panel) are built, and the website is live on dev with the web app at /app. Teams are now one type with players on every team, claims, and admin approval (tasks 181 to 186). The old M9 and Launch sections are replaced by six go-live phases: the website and web app first, then GDPR, backups, and security, then Sign in with Apple, the App Store, Google Play, and Facebook sign-in, each in its own phase (D60).

---

## Phase 0 · Get ready to build

1. ✅ 👤 **Jared:** Install the dev tools: Homebrew, git, GitHub CLI, Node 22, Firebase CLI, Flutter, FlutterFire CLI, CocoaPods, Google Cloud CLI, Android Studio, VS Code extensions.
2. ✅ 👤 **Jared:** Install Xcode and accept its license.
3. ✅ 👤 **Jared:** Install the Android SDK through Android Studio's setup wizard.
4. ✅ Run `flutter doctor` until iOS, Android, and Chrome all pass (clean on 2026-10-11).
5. ✅ 👤 **Jared:** Use your personal Gmail for Battleplan's Google services, with 2-Step Verification on.
6. ✅ 👤 **Jared:** Create the `battleplan-help@googlegroups.com` support group.
7. ✅ 👤 **Jared:** Buy `getbattleplan.app` at Cloudflare (Q8).
8. ✅ 👤 **Jared:** Create the Firebase projects on the free plan: dev `battleplan-dev-ecce4`, prod `battleplan-prod`.
9. ✅ 👤 **Jared:** Choose the app ID `app.getbattleplan` (`.dev` for dev builds).
10. ✅ 👤 **Jared:** Verify the domain's contact email if Cloudflare asks. **Deadline 2026-10-25**, or the domain goes on hold. (no verification email came; the Cloudflare account signs in with Google, so its email is already verified, checked 2026-10-11)
11. ✅ 👤 **Jared:** Make a Battleplan vault in 1Password for every login, key file, and recovery code. *Done 2026-10-11: the "Battle" vault (it holds the Resend API key).*
13. ✅ 👤 **Jared:** Log in from the terminal: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`. **This blocks task 23 and spikes 1 to 3 (tasks 26 to 28).**

Task 12, checking your legal name for the stores, moved to Phase 3.

## M0 · Foundation

14. ✅ `flutter create` with dev and prod flavors.
15. ✅ Repo layout, lints, CI, and VS Code launch configs.
16. ✅ Emulator Suite with seed data: adult and youth teams, people on several teams.
17. ✅ Design tokens, light and dark themes, core components.
18. ✅ Three-tab shell with placeholder screens; go_router with its guards.
19. ✅ Remote Config minimum-version check, Crashlytics, Analytics, web error reporting (wired; live once task 23 is done).
20. ✅ Import-boundary check in CI (ENG-1), Firestore index exemptions, TTL policies.
21. ✅ Spike 4: WASM web build with our plugins.
22. ✅ Spike 5: security rules on the flat collections (28 rules tests).
23. ✅ Register the iOS, Android, and web apps in dev and prod and put their Firebase config in the app (`lib/app/firebase_options_dev.dart`, `_prod.dart`). The dev Firestore database exists (us-central1) with the rules deployed; TTL policies wait for Blaze (task 25 deploys indexes).
24. ✅ Set up keyless GitHub Actions deploys (Workload Identity Federation) to the dev project.
25. ✅ Turn on Hosting for the dev project (https://battleplan-dev-ecce4.web.app); every push to `main` deploys Firestore rules and hosting there. PR previews are wired but unused, since work goes straight to `main`. Indexes and Storage rules join the deploy once dev is on Blaze (task 57).
26. Run **spike 1**: the sign-in matrix (provider × platform × new / existing / admin-added account) for Google and email. Apple joins in task 109.
27. ✅ Run **spike 2** on the dev Hosting domain: Android App Links, `assetlinks.json`, and email-link sign-in with `linkDomain` (no Dynamic Links). iOS Universal Links join in task 110. *Done 2026-10-11: App Links and email-link sign-in work on Android and web; `linkDomain` must be a custom domain (docs/spikes/M0.md).*
28. Create the web push (VAPID) key on the dev project and run **spike 3**: web push on Chrome, macOS Safari, and an iPhone home-screen web app.

**M0 is done when** the empty app runs on iOS, Android, and Chrome, and every PR gets a web preview link.

## M1 · Accounts

29. ✅ Sign-in screen (AUTH-1) with Google, Apple, and email; email and password (AUTH-2). Apple's code goes in now and is verified in task 109.
30. ✅ Email verification banner (AUTH-3) and password reset by email (AUTH-4).
31. ✅ First-run setup: name, photo, 18+ confirmation, Terms acceptance (AUTH-5, SAFE-3, SAFE-6); `ensureUserProfile`; the profile kept separate from sign-in providers (AUTH-12).
32. ✅ Sessions: stay signed in, sign out, sign out of all devices (AUTH-9).
33. ✅ Safe account linking and the Sign-in methods screen (AUTH-7, AUTH-8, SET-4).
34. ✅ Disabled accounts (AUTH-11) and account deletion (AUTH-10).
35. ✅ Profile and About screens (SET-1, SET-6); the theme setting syncs to the account (SET-2).
36. ✅ The super-admin bootstrap script (`npm --prefix tools/seed run super-admin -- <project> <email>`). Jared is a super admin on dev.
37. ✅ Rules and tests for `users` (and profile photos in Storage).

**M1 is done when** the sign-in matrix passes on all three platforms (Apple waits for task 109).

## M2 · Teams and invites

38. ✅ 👤 **Jared:** Decided 2026-10-11: Q1 "Team", Q3 anyone with a verified email, Q14 coaches and staff RSVP for themselves on youth teams, Q15 admins approve guardian links.
39. ✅ Create a team, with adult or youth type (TEAM-1); the welcome screen. *The logo upload is part of team settings (task 42), and the "Invite your team" step after creating joins with the invite screen (task 47).*
40. ✅ Team switcher and many teams per person (TEAM-2, §5.2): most recent first, sport icons, muted icon, unread dot, archived section, Join and Create, same tab on switch, last team remembered, Ctrl/⌘+K, and the 100-team limit. *Unread counts in the switcher arrive with CHAT-9 (task 65).*
41. ✅ Roster screen, roles, and team admins (TEAM-3, TEAM-4). *"Not joined yet" and Resend setup email arrive with add-by-email (task 46), the Players section with task 51, and Report/Block with task 66.*
42. ✅ Team settings and member permissions (TEAM-5). *Managing the invite link joins with the invite screen (task 47).*
43. ✅ Transfer ownership, leave, archive, and delete (TEAM-6, TEAM-8, TEAM-9).
44. ✅ 👤 **Jared:** Pick the email provider (Q10; default Resend), sign up for its free tier, and add its SPF, DKIM, and DMARC records in Cloudflare. *Done 2026-10-11: Resend, with `getbattleplan.app` verified (DNS added through Resend's Cloudflare sign-in); the API key is in Secret Manager as `RESEND_API_KEY` and in the Battle vault. A DMARC record isn't added yet.*
45. ✅ Email sending from Functions (ARCH §6.7), with the API key in Secret Manager. *Resend, from noreply@getbattleplan.app; security notices for sign-in method changes now go out too (task 33).*
46. ✅ Add members by email, with account creation and setup emails (TEAM-7, AUTH-6). *Tested on dev end to end: the setup email arrived and its link signed the new person in to first-run setup. The "How do you want to sign in next time?" prompt is covered by Settings → Sign-in methods for now.*
47. ✅ Invite screen, invite link, QR code, and code (INV-1 to INV-3); creating a team lands on it. *The in-app QR scanner is part of joining (task 49).*
48. ✅ Email invites (INV-4). *Tested on dev: invites to Resend test addresses, a wrong-account redeem refused, the right account joined, used-up and revoked links refused, Resend gives a revoked invite a fresh 14 days.*
49. ✅ Joining: `getInvitePreview`, `redeemInvite`, join by code or QR scan, the `/join` web page, error states (INV-5 to INV-8). *App Store and Google Play badges on the web page join when the apps are listed (task 130); youth teams' "Who are you here for?" step is task 52.*
50. ✅ Universal Links and App Links for invites on our domain (INV-9, ENG-6). iOS is verified in task 110. *Android App Links verified on dev for `/join/`, `/activate`, and `/g/` (spike 2); prod uses `getbattleplan.app` once it is on prod Hosting (task 116). The `apple-app-site-association` file needs the Apple team ID (tasks 109 and 110).*
51. ✅ Youth teams: add players and pasted rosters (PLAYER-1), player card (PLAYER-2). *Setup emails for newly added guardians go out with task 46; adding or removing a guardian from the card is task 52.*
52. ✅ Youth teams: "Who are you here for?", guardian requests, adding a co-parent (PLAYER-3 to PLAYER-5). *Admins see requests at the top of the roster; the push notification to admins arrives with notifications (M4). Tested on dev: request, decline, ask again, approve, add an unlisted player, add and remove a co-parent.*
53. ✅ Parent labels in the roster, "Maria R. · Emma #7" (PLAYER-8); kids' privacy limits on player records (PLAYER-10). *The roster shows "Parent of Emma #7"; `Membership.nameWithPlayers` gives the short "Maria R. · Emma #7" form that chat uses in M3. Rules hold player records to a name, number, and position.*
54. ✅ Storage quota accounting. *Storage triggers add and subtract each file under `groups/{g}/` from `groups.storageBytes`; a daily job recomputes every team from the bucket; Team settings shows "1.2 GB of 5 GB used". Tested on dev with real uploads and a delete.*
55. ✅ Rate limits for team creation, invites, and adds (SAFE-5). *Every limit in the ARCH §6.9 table is enforced. A bulk request counts all its uses at once and is all or nothing: one over the limit adds nobody and uses none of the allowance.*
56. ✅ Rules and tests for teams, members, players, and invites, including **cross-team isolation**. *`functions/test/rules/teams.test.ts`: 17 more rules tests (59 in all), including Storage uploads and the quota.*

**M2 is done when** a new coach can get three people in by link, QR, and email; a person on two teams can switch between them; and a pasted youth roster links each parent to the right player.

## M3 · Chat

57. ✅ 👤 **Jared:** Upgrade the dev project to the Blaze plan and set budget alerts at $5, $25, $50, and $100 the same day. Needed once Functions and photo storage run in the cloud for testing on real phones. *Done in M1; the budget alert is at $5.*
58. ✅ Message list with paging and date separators (CHAT-1). *Tested on dev in Chrome with 120 seeded messages: the newest 50 load, scrolling up pages back to the first. Opening at the first unread message comes with unread counts (task 65).*
59. ✅ Composer, links, and system messages (CHAT-2, CHAT-5, CHAT-10). *A message reached another signed-in browser in under a second, and three quick sends in a row all landed. The + menu arrives with photos (task 60) and polls (M5).*
60. ✅ Photos and the full-screen viewer (CHAT-3). *Tested on dev in Chrome: two photos uploaded as one message with their sizes, the other member saw them, and the team storage total counted them. Pasting and dragging images in on web come later.*
61. ✅ Delivery states and the offline send queue (CHAT-4). *Tested on dev in Chrome: three messages typed offline showed as "Sending…" and all reached the server in order once back online. The queue lives in memory, so messages still queued when the app is closed are lost (Firestore keeps the first one).*
62. ✅ Reactions 👍 ❤️ 👎 😂 (CHAT-6) and the message menu (CHAT-7). *Tested on dev: right-clicking a message and picking 👍 saved the reaction. Reply, Delete, and Report join the menu with tasks 63, 64, and 66.*
63. ✅ Replies with server-written quotes (CHAT-13). *Tested on dev: replying from the menu sent only the original's ID, and the server wrote the quote within a second. The notification to the person replied to comes with M4 (NOTIF-11).*
64. ✅ Deleting messages through a Function, with the audit log (CHAT-8). *Tested on dev: an admin deleted a member's photo message; the text, photo file, and reactions were erased, the reply quoting it showed "Original message was deleted", the audit log recorded it, and a member couldn't delete someone else's message. Deleting a poll's message deletes the poll in M5.*
65. ✅ Unread counts and the "New messages" divider, synced across devices (CHAT-9). *Tested on dev with two browsers: three messages showed as 3 on the other person's Chat tab; opening the chat showed the divider and set their read marker past the last message, clearing the count. With more than 50 unread, the chat opens at the oldest loaded one.*
66. ✅ Report and block (SAFE-1, SAFE-2, CHAT-12); the team's Reports screen and acting on reports (SAFE-4); the blocked-people list (SET-5). *Tested on dev: a member's report reached the admin's Reports screen with a copy of the message, and Delete message erased it and closed the report. Notifying admins of new reports comes with M4 (task 74); the super-admin queue with M8.*

**M3 is done when** the CHAT acceptance criteria pass (SPEC §6.5).

## Plus plan · removed

Tasks 157 to 167 built a paid Plus tier on 2026-10-11 (licenses, grants, moving, reminders, and Plus-only features). It was dropped on 2026-10-12 in favor of free for everyone with no ads (SPEC Q4, ARCH D39); task 168 removes it. The features it gated (editing messages, 16 reactions, and the chat look) stay, free for every team. Task 167, in-app purchase, is no longer needed.

## M4 · Notifications

67. ✅ Device registration and the `notify` fan-out Function (one pipeline for push and the notification center). *Tested on dev: the Android emulator registered a real FCM token, and account deletion removed its device.*
68. ✅ Asking permission at the right moment (NOTIF-1). *The pre-prompt showed on the Android emulator after the first team, then the system prompt.*
69. ✅ Per-team level and mute, global switches, and the Notifications settings screen (NOTIF-3, NOTIF-4, SET-3). *New events and Event changes are separate switches.*
70. ✅ Notification wording, grouping, and multiple devices (NOTIF-5, NOTIF-8, NOTIF-10). *iOS stacks by team (`thread-id`); Android and web are bundled by the OS, since a replacing tag would hide earlier notifications. Android has six channels. The iOS entitlement comes with the APNs key (task 108).*
71. ✅ Tap to open and in-app banners (NOTIF-6, NOTIF-7). *Tested on the Android emulator: tapping a reply push opened the chat at the reply, and a push while on Schedule showed the in-app banner instead of a system notification.*
72. ✅ Notification center with the bell (NOTIF-11). *Tested on dev in Chrome: the bell counted a reply, and tapping it opened the message and marked it read.*
73. ✅ Web push and the iOS Safari tip (NOTIF-9). *Web pushes carry a click link to the route. A project VAPID key (task 28) and the production service worker (task 116) come before launch; the tip gets an App Store link once the listing exists.*
74. ✅ Turn on notifications for chat messages, replies, being added to a team, being made admin, guardian requests, and reports (NOTIF-2). *Also guardian approved and player added (PLAYER-3). A milestone review with independent skeptics confirmed 11 problems, all fixed with tests.*

From here on, each feature ships with its own notifications.

## Free for everyone and team storage · after M4

SPEC §6.14 (STORE), ARCH §6.11, [PLANS.md](PLANS.md).

168. ✅ Remove the paid tier: plans, licenses, the Plan section, Plus badges, Plus checks in rules and Functions, and license reminders. Editing, 16 reactions, and the chat look are free for every team. *Done: no Plus code, rules, callables, or screens remain; the old callables were deleted from dev.*
169. ✅ 500 MB per team and 10 MB files; the storage meter in Team settings; the 90% warning in the team and a notification to admins (STORE-1 to STORE-3). *Tested on dev: a team set to 1 MB warned admins at 960 KB with a notification and the in-team banner.*
170. ✅ Full storage: uploads, attachments, and scheduling new events stop, with one message for all three; nothing else turns off and nothing is deleted (STORE-4). The `hasRoom` rule is ready for events in M6. *Tested on dev: past the limit, uploads were refused, admins were notified, and freeing space let uploads work again; an 11 MB document was refused.*
171. ✅ Media for admins: every photo, attachment, document, logo, and chat background, largest first, with delete (STORE-5). *Tested on dev: members can't list or delete; deleting a message's last photo left "Photo removed by a team admin".*
172. ✅ The unannounced super-admin storage limit for one team (STORE-6), in Team settings until the admin panel (M8) has it. *Tested on dev: only a super admin could change it.*
173. ✅ Rules and tests for storage limits and Media. *130 rules and emulator tests in all.*

**Done when** the STORE acceptance criteria pass (SPEC §6.14).

## M5 · Polls

75. ✅ Create a poll and the poll card in chat (POLL-1, POLL-2, CHAT-11).
76. ✅ Who voted, and anonymous polls (POLL-3).
77. ✅ Closing early, auto-close in the `tick` job, and the "Poll closed" notification (POLL-4).
78. ✅ Deleting a poll with its message (POLL-5).
79. ✅ Rules and tests for polls and votes.

## M6 · Schedule

80. ✅ 👤 **Jared:** Confirm Q12 (can members create events by default). Decided 2026-10-12: admins only by default; each team can change it.
81. ✅ Create an event with types and game fields (SCHED-3); event details (SCHED-4).
82. ✅ RSVPs, including Maybe and admins answering for members (SCHED-5).
83. ✅ Per-player RSVPs and guardian notifications on youth teams, plus coaches' and staff's own RSVPs counted apart from players (PLAYER-6, PLAYER-7, Q14).
84. ✅ Upcoming, Past, and Calendar views (SCHED-1); All my teams, with each parent's player named (SCHED-2, PLAYER-9).
85. ✅ Editing, cancel, and delete, with change notifications (SCHED-6, SCHED-7).
86. ✅ Repeating events through `saveEventSeries`: daily and weekly, skip dates, this-and-following edits, cancel, and delete.
87. ✅ Duplicate an event (SCHED-3).
88. ✅ Reminders in the `tick` job (SCHED-8); event cards in chat (CHAT-11).
89. ✅ Time zones (SCHED-9) and Add to calendar (SCHED-10).
90. ✅ Rules and tests for events, series, and RSVPs.

**M6 is done when** the SCHED and PLAYER acceptance criteria pass (SPEC §6.3, §6.7).

## M7 · Documents

91. ✅ Documents tab, uploads, and links (DOC-1 to DOC-3), with the storage-full message.
92. ✅ Opening, sharing, and downloading (DOC-4).
93. ✅ Rename, describe, delete, pin (DOC-5).
94. ✅ New-document notifications (DOC-6).
95. ✅ Rules and tests for documents and Storage.

## M8 · God admin panel

96. ✅ Admin panel shell at `/admin`, loaded separately; dashboard (ADMIN-1).
97. ✅ Teams list and team detail, including View team, suspend, archive, and delete (ADMIN-2, ADMIN-3).
98. ✅ Users: create, disable, reset, sign out everywhere, grant super admin (ADMIN-4).
99. ✅ Report queue (ADMIN-5) and audit log (ADMIN-6).
100. ✅ Platform settings and the announcement banner (ADMIN-7); safeguards (ADMIN-8).

## Website and the web app at /app · after M8

SPEC §4.3 (WEB-1 to WEB-5), ARCH §6.6 and D40. The website is the `website/` folder: static HTML and CSS with no framework or build step. The Flutter web app moves from the root to `/app`.

175. ✅ The website in `website/`: a landing page explaining Battleplan (chat, schedule and RSVPs, polls, documents, youth teams; free, no ads), with screenshots and an **Open Battleplan** button to `/app` on every page; light and dark mode; works well on phones (WEB-1, WEB-5).
176. ✅ The website's support and legal pages: `/support`, `/privacy`, `/terms`, `/delete-account` (WEB-2; their wording is task 121).
177. ✅ One Hosting site for both: CI copies `website/` into `build/hosting/` and builds Flutter with `--base-href /app/` into `build/hosting/app/`; Hosting rewrites `/app/**` to the app, redirects `/join/*`, `/activate`, and `/g/*` into `/app` keeping query strings, and serves `.well-known` from the website. Dev gets the same layout; PR previews build both (WEB-3).
178. ✅ Links follow the move: the app's `LinkService` and the Functions `links` module build `/app/...` links for content and email setup, keep invite links short (`/join/<CODE>`), and push notifications open `https://<host>/app<route>`; the Auth `url` becomes `/app/activate`; Universal Links and App Links also match `/app/*`, and the native apps ignore the `/app` prefix; the web app's service worker, manifest, and push service worker work under `/app/`. Tested on dev: an invite link, a setup email, and a notification click in the browser, and an invite link on the Android emulator (WEB-4).
179. ✅ Website polish (store badges in place but off until the apps are listed, task 130): favicon, Open Graph image and tags, `robots.txt` and a sitemap (the site indexed, `/app` not), and App Store and Google Play badges once the apps are listed (task 130).

## One team type · after M8

SPEC Q17, §6.3 (PLAYER-1 to PLAYER-11), ARCH §6.2 and D59. The owner asked for one kind of team instead of adult and youth types. Every team has players; any member can claim a player as "I am this player" or as a parent or guardian, and can add players that team admins approve or decline.

181. ✅ Data and migration: `groups.teamType` and `events.rsvpFor` removed, `groups.kind: 'team'`, `players.status` (active or pending) with `proposedBy`, and `relation` (`self` or `guardian`) on player links and claims; a dev-only, idempotent migration fills in old docs.
182. ✅ Server: `createGroup` with no type; `proposePlayer`, `claimPlayer`, `resolvePlayerClaim`, and `resolvePendingPlayer` replace the old guardian callables; player requests notify admins; RSVP recounts keep players and others apart; reminders and changes go to each player's own member and guardians.
183. ✅ Rules: pending players hidden from other members; RSVPs for players by their linked members or admins, and any member for themselves; rules tests for each case.
184. ✅ App: no type step when creating a team; a Players section on every roster with Add player (pending for members), Claim this player, and Approve and Decline for admins; "Who are you here for?" on every team; RSVP rows per player plus a Me row, with "12 players going · 2 others" (PLAYER-3, PLAYER-4, PLAYER-6).
185. ✅ Labels and notifications: "Jared F. #12" for a member who is a player, "Maria R. · Emma #7" for a guardian; youth-team wording removed (PLAYER-7, PLAYER-8).
186. ✅ Docs and website: SPEC, ARCH, and the landing and support pages describe one team type ("Players and parents").

## Go-live in six phases

Decided 2026-10-12, at the owner's request (SPEC §9, ARCH D60). The first go-live is the website and the web app only. Sign in with Apple, the App Store, Google Play, and Facebook each get a later phase of their own, in this order:

| Phase | What goes live | New fixed cost |
|---|---|---|
| **1** | The website and the web app at `getbattleplan.app`, in desktop and phone browsers, on a prod project proven to run cheaply; signup emails from Firebase | None. Firebase ≈ $0–3/month for a few teams; email $0 |
| **2** | GDPR and EU readiness; backup and restore; security hardening | Backups under $1/month |
| **3** | Sign in with Apple, on the web first | Apple Developer Program, $99/year |
| **4** | The iPhone and iPad app on the App Store | None (the same Apple membership) |
| **5** | The Android app on Google Play | $25 once |
| **6** | Facebook sign-in and single sign-on (SSO) | None for Facebook |

- Every Apple, App Store, Google Play, and Facebook task moved out of M9 and Launch into its phase. Task numbers stay the same, and each moved task says where it came from. New tasks start at 187.
- Until Phase 4, the iOS and Android builds keep compiling and passing their tests in CI, but they don't ship. The parity rule (SPEC §4.2) applies again from Phase 4.

## v1.1 features · before Phase 1 go-live

In SPEC §9's priority order. These are web build work, so they're built before go-live (task 134). Parts that need the native apps wait for Phases 4 and 5.

135. @mentions, edits, pins, and announcements (CHAT-14, CHAT-15).
136. Roster details and contact sharing (TEAM-10).
137. "Same answer for all my players" and per-player RSVP history (PLAYER-11).
138. Calendar subscription links (SCHED-11).
139. RSVP nudges and guest counts (SCHED-12).
140. Team-specific link previews for invites (ARCH §6.6).
141. Document folders and the chat photo gallery (DOC-7).
142. Announcement-only mode (TEAM-12).
143. Polls list, reminders to non-voters, member-added options, hidden results (POLL-6).
144. App icon badges, mention notifications, hidden message text (NOTIF-12). *The web gets mention notifications and hidden text now; icon badges on iPhone and Android come with Phases 4 and 5.*
145. Files in chat (CHAT-16).
146. Persistent team list on very wide screens (§5.5).

## Phase 1 · Website and web app go-live

The website and the web app at `getbattleplan.app/app`, working well in desktop and phone browsers, on a prod project that costs close to nothing. No Apple sign-in, App Store, or Google Play yet.

**Email choice (ARCH §6.7, D61).** Firebase Auth sends every signup and account email: verification, password reset, email-link sign-in, and change of email. It costs $0, and Blaze allows 100,000 verification and 10,000 password-reset emails a day. Cloudflare Email Sending would cost at least $5/month (it needs Workers Paid) and is still in beta, so Firebase is the cheaper choice. Resend Free ($0, up to 100 emails a day and 3,000 a month) keeps sending setup links, invites, and security notices from Functions. Cloudflare Email Routing (free) receives mail to `support@` and `privacy@`.

**Build quality**

105. Accessibility, performance (SPEC §8), and golden-test passes in both themes. *Moved from M9. A first pass is in the code (commit e1eab87); check it against the web proof pass (task 188).*
187. Hide Continue with Apple on the sign-in screen and in Sign-in methods until Phase 3 (AUTH-1). Today it shows, disabled, with "Coming soon".
120. App icons and splash screens. *Moved from M9. The web's favicon and home-screen icons ship now; the store icon sizes come with Phases 4 and 5.*
188. Web proof pass: every MVP flow in desktop Chrome, Edge, Firefox, and Safari, and in phone browsers (Safari on iPhone, Chrome on Android), including web push from the iPhone home-screen web app. Web first load under 4 s (SPEC §8.1). Fix what it finds before go-live.

**Prod project**

113. ✅ 👤 **Jared:** Confirm Q11 (where most teams are; default US, `us-central1`). **The prod database's region is permanent.** *Moved from M9.*
114. 👤 **Jared:** Upgrade `battleplan-prod` to Blaze and set its budget alerts at $5, $25, $50, and $100. *Moved from M9.*
115. Create prod's database in that region; deploy rules, indexes, TTL policies, and functions; turn on point-in-time recovery and daily backups kept 7 days (the full backup design is Phase 2); register the web app with App Check in monitor mode; set the function-image cleanup policy; set the Remote Config minimum version. *Moved from M9.*
116. 👤 **Jared:** Connect `getbattleplan.app` to prod's Hosting, with the Cloudflare records set to **DNS only** (grey cloud). It serves the website and the web app at `/app` (tasks 175 to 179). *Moved from M9.*
189. Production web push: create prod's VAPID key and check the service worker under `/app/` on the domain (tasks 28 and 73).
117. Set up the manual prod release workflow for the backend and the web. *Moved from M9. Deciding where iOS builds run moved to task 209 (Phase 4).*
118. Bootstrap the first super admin on prod. *Moved from M9.*
119. ✅ 👤 **Jared:** Confirm Q9 (logo and primary color; default placeholder mark and blue `#2F5BEA`). *Moved from M9.*
121. Legal pages: Privacy Policy, Terms of Use, `/delete-account` (LEGAL-1, LEGAL-3), as pages on the website (task 176); no-tracking setup checked (LEGAL-2). *Moved from M9. Draft wording is in (commit ff20178), with placeholders for 👤 **Jared** to fill. The GDPR and EU additions come in Phase 2 (task 193).*

**Email**

111. 👤 **Jared:** Turn on Cloudflare Email Routing and forward `support@` and `privacy@getbattleplan.app` to your Gmail. It also adds the apex MX records and SPF. *Moved from M9.*
112. 👤 **Jared:** Customize Firebase's email domain on prod, after task 116: *Authentication → Templates → Customize domain*, add the TXT and CNAME records (CNAMEs DNS only), and merge Firebase's SPF entry into the one apex `v=spf1` record. Sender "Battleplan" `<noreply@getbattleplan.app>`, reply-to `support@getbattleplan.app`. Then send yourself an email-link sign-in to check it comes from the domain too. *Moved from M9. Registering the addresses with Apple's private email relay moved to task 207 (Phase 3).*
190. 👤 **Jared:** Add a DMARC record, `v=DMARC1; p=none; rua=...`, and turn on Cloudflare DMARC Management to read the reports. Keep one `_dmarc` record. Task 44 left this out. Tightening it is task 206.
191. Add a log-based alert on `email_send_failed`. Resend Free stops at 100 emails a day, and one large roster import (up to 200 adds a day per team) can reach that. When the cap starts to bind, move the Functions mail to Cloudflare Email Sending ($5/month for 3,000, then $0.35 per 1,000), which is cheaper than Resend Pro ($20/month) below about 46,000 emails a month. Only `sendEmail()` changes (ARCH §6.7).

**Go-live and cost proof**

124. ✅ 👤 **Jared:** Decide Q4 (how the platform is paid for). *Decided 2026-10-12: free for everyone, with no ads (SPEC Q4). Moved from Launch.*
122. Beta with our team on the web: desktop and phone browsers, with the iPhone home-screen web app for push; a bug bash. *Moved from M9. TestFlight moved to task 211 (Phase 4); Android testing is part of Phase 5.*
123. Move our team over: paste the roster, recreate upcoming events as repeating practices, post the invite link in GroupMe and show the QR at practice, and run both apps for about two weeks. *Moved from M9.*
192. Prove the hosting is cheap: after two weeks of our team on prod, read the bill per service in Cloud Billing reports and compare it with ARCH §10.1, and check Firestore reads per screen against the read budgets (ARCH §10.2). Write the measured numbers into ARCH §10.1.
134. Production deploy of the web app, and open sign-up to other teams on the web. *Moved from Launch.*

**Phase 1 is done when** our team runs on the web app on prod in desktop and phone browsers, signup emails arrive from `noreply@getbattleplan.app`, and two weeks of bills match the cost model.

## Phase 2 · GDPR and EU, backup and restore, security hardening

**GDPR and EU (LEGAL-7)**

193. GDPR review of what Battleplan collects: a lawful basis for each use, how long each kind of data is kept, and a short record of processing. Add the EU sections to the Privacy Policy: who the controller is, people's rights (access, correction, erasure, portability, objection), how to complain to a data protection authority, and transfers to the US under Google's, Cloudflare's, and Resend's data processing terms.
194. 👤 **Jared:** Accept Google's data processing terms for both Firebase projects, and keep copies of Resend's and Cloudflare's. Decide whether Battleplan serves EU teams on purpose; if so, GDPR Art. 27 asks for a representative in the EU.
195. Download my data: Settings → Account → **Download my data** gives a person a file with their profile, memberships, messages, RSVPs, and player links (GDPR access and portability).
196. Cookies and consent: the website sets no cookies (WEB-5), and the web app stores only what sign-in and the offline cache need. Turn off Google Analytics on the web for EU visitors, or ask first, so no cookie banner is needed.
197. EU Digital Services Act basics for a service that hosts people's posts: `support@` as the point of contact, Report as the way to flag content (SAFE-1), and a reason given when content is removed.
198. A data breach plan: who checks, who is told, and how to notify the authority within 72 hours.

**Backup and restore (ARCH §6.12, D62)**

The choice: Google's own protection inside the prod project for everyday mistakes, plus one small encrypted copy in Cloudflare R2 in case the project itself is lost. Nothing is kept longer than 7 days, because LEGAL-6 promises deleted content leaves backups within 7 days. At our size this costs under $1/month: point-in-time recovery about the database's size at $0.15/GiB-month, daily backups $0.03/GiB-month each, and R2 free up to 10 GB ($0.015/GB-month after, with no download fees). Wasabi (about $7/month minimum, with a 90-day minimum charge per file) and Azure Blob ($0.0208/GB-month, plus download fees for a restore) both cost more at this size.

199. Turn on the in-project protection on prod, if task 115 didn't: point-in-time recovery (7 days), daily Firestore backups kept 7 days, and 7-day soft delete on the Storage bucket.
200. 👤 **Jared:** Create a Cloudflare R2 bucket for backups with an API token that can reach only that bucket, and save the token and the backup encryption key in 1Password, with an offline copy of the key.
201. The nightly off-site copy: a scheduled job exports Firestore, encrypts the export, and uploads it to R2; it also mirrors new and deleted Storage files, encrypted, so a file deleted in the app leaves R2 the next night. An R2 lifecycle rule deletes each export after 6 days. Copying only what changed keeps Google's download charges near $0.
202. A restore runbook and drills, run in dev: restore a daily backup to a new database, recover one deleted document with point-in-time recovery, and rebuild a fresh project from the R2 copy, timing each. Repeat the drills every 3 months.

**Security hardening**

104. Enforce App Check on Firestore, Storage, and Functions for the web (reCAPTCHA Enterprise), after a week of monitor-mode numbers from prod; review rules-test coverage. *Moved from M9. Monitor mode and the rules-coverage review are done (commit 53043eb, docs/rules-coverage.md). App Attest and Play Integrity are enforced in Phases 4 and 5.*
203. A security review of rules, callables, and Storage paths, and a dependency audit, with Dependabot alerts on for npm and pub.
204. Security headers on the website and `/app` through Hosting: HSTS, a Content Security Policy, `X-Content-Type-Options`, `Referrer-Policy`, and `frame-ancestors` so pages can't be framed.
205. Lock down prod: restrict the web API key to `getbattleplan.app`, trim Auth's authorized domains, give the deploy service account only the roles it needs, and add Cloud Monitoring alerts for Functions errors and sign-in spikes.
206. 👤 **Jared:** Turn on 2-Step Verification on every Battleplan account (Google, Cloudflare, GitHub, Resend, 1Password) and DNSSEC in Cloudflare. Move DMARC to `p=quarantine`, then `p=reject`, after 2 to 4 weeks of reports showing Firebase and Resend passing (task 190).

**Phase 2 is done when** an EU visitor can read how their data is handled and download it, a restore drill from R2 has worked, and App Check is enforced on the web.

## Phase 3 · Sign in with Apple

Apple sign-in on the web first (a popup). The iPhone's native sheet is checked in Phase 4 and Android's web flow in Phase 5. New fixed cost: the Apple Developer Program, $99/year.

12. 👤 **Jared:** Check your legal name and address on your Apple Account and Google payments profile (the stores read them in tasks 106 and 125). *Moved from Phase 0.*
106. 👤 **Jared:** Enroll in the Apple Developer Program as an individual ($99/year). **Start about a week before this phase.** *Moved from M9.*
107. 👤 **Jared:** Create the Sign in with Apple key and the Services ID. The key file downloads only once, so save it to 1Password right away. *Moved from M9. The APNs key moved to task 208 (Phase 4).*
207. 👤 **Jared:** Register `getbattleplan.app` and `send.getbattleplan.app` as email sources with Apple's private email relay, so email reaches people who use Hide My Email. Add `cf-bounce.getbattleplan.app` if Cloudflare sending comes later. *Split from task 112.*
109. Turn on Sign in with Apple on the web, show Continue with Apple again (task 187), and finish the sign-in matrix (spike 1) for the web. *Moved from M9. iOS joins in Phase 4 and Android in Phase 5.*

## Phase 4 · iPhone and iPad on the App Store

208. 👤 **Jared:** Create the APNs key. The key file downloads only once, so save it to 1Password right away. *Split from task 107.*
108. Upload the APNs key to Firebase and turn on iOS push. *Moved from M9.*
110. Turn on iOS Universal Links with the Associated Domains entitlement (spike 2). *Moved from M9.*
209. Decide where iOS builds run (macOS minutes on GitHub count 10×) and add the iOS build to the prod release workflow. *Split from task 117.*
210. iPad pass: every screen on iPad sizes, in portrait, landscape, and Split View, with the side rail at 840 px and up (SPEC §5.5).
211. TestFlight beta with our team's iPhone and iPad users; Sign in with Apple's native sheet and App Attest join the sign-in matrix and App Check enforcement.
129. App Store listing: screenshots for iPhone and iPad, description, keywords, support and privacy URLs. *Moved from Launch. The Google Play listing moved to task 213.*
130. App Store privacy labels and the age-rating questionnaire (LEGAL-4). *Moved from Launch. The Play Data safety form moved to task 213.*
131. 👤 **Jared:** Declare EU trader status in App Store Connect. *Moved from Launch. Google Play's is part of task 213.*
132. App Review demo account with a seeded team, made by hand on prod (D54), and review notes explaining that teams are invite-only. *Moved from Launch.*
133. Submit to the App Store. Once it's listed, turn on the App Store badge on the website and the `/join` page (task 179) and the App Store link in the iOS Safari tip (task 73). *Moved from Launch. The Google Play submission moved to task 214.*

**Phase 4 is done when** the app is on the App Store for iPhone and iPad. From here on, every feature ships on iOS and the web in the same release.

## Phase 5 · Android on Google Play

New fixed cost: the Google Play Console, $25 once.

125. 👤 **Jared:** Open the Google Play Console as a personal account ($25 once). **Start 3 to 4 weeks before** you want to be on Google Play. *Moved from Launch.*
126. Generate the Android upload key at the first Play upload. 👤 **Jared:** store the keystore and its passwords in 1Password, plus an offline backup. *Moved from Launch.*
127. Add the Android SHA-1 and SHA-256 fingerprints (debug, upload, Play App Signing) to Firebase. *Moved from Launch.*
212. Verify App Links on prod: `assetlinks.json` on `getbattleplan.app` with the upload and Play App Signing fingerprints, then check `/join/`, `/activate`, `/g/`, and `/app/` open the app on a phone (task 50).
128. 👤 **Jared:** Run the Google Play closed test: 12+ testers opted in for 14 days in a row, then request production access. *Moved from Launch.*
213. Google Play listing: phone and tablet screenshots, description, the Data safety form (LEGAL-4), the content rating, the target audience (adults), the review demo account, and 👤 **Jared:** EU trader status in the Play Console. *Split from tasks 129 to 132.*
214. Add the Android build to the prod release workflow, submit to Google Play, enforce Play Integrity in App Check, and turn on the Google Play badge on the website and the `/join` page. *Split from task 133.*

**Phase 5 is done when** the app is on Google Play. From here on, the parity rule covers all three platforms.

## Phase 6 · Facebook sign-in and SSO

Brought back from the backlog (tasks 101 to 103, SPEC Q16).

101. 👤 **Jared:** Create a Meta developer account and app, with business verification if Meta asks. *Moved from Later · Backlog.*
102. Continue with Facebook on the web, iOS (Limited Login), and Android, with the same safe-linking rules as the other providers (AUTH-7). *Moved from Later · Backlog.*
103. Meta App Review, and the data-deletion URL (LEGAL-5). *Moved from Later · Backlog.*
215. Single sign-on: decide which other sign-ins teams ask for, such as Microsoft accounts or a club's own SAML or OIDC login. SAML and OIDC need Firebase's Identity Platform upgrade, which bills per monthly active user past its free tier (ARCH §6.1), so check the price first.

---

## Later · Backlog

147. Join requests that need admin approval; copying a team for a new season (TEAM-13).
148. Organizations and leagues; sub-chats within a team (TEAM-13).
149. ~~Coach and staff RSVPs on youth teams~~ (moved into task 83, Q14).
150. Direct messages (Q5); message search; link previews, GIFs, video, voice notes; typing indicators and read receipts (CHAT-17).
151. Attendance tracking, reports with CSV export, game scores (SCHED-13).
152. Volunteer and snack sign-ups, carpools, season availability surveys (SCHED-13).
153. Document version history, comments, and e-signatures (DOC-8).
154. Quiet hours, email digests, SMS (NOTIF-13).
155. Per-team profanity filter (SAFE-7), sooner if App Review asks.
156. Cloud SQL, if usage meets the ARCH §12.1 triggers.
180. **Group types beyond Team** (TEAM-14): keep the standard **Team** and add a more basic **Group** for general use (for example, no roster, players, or RSVP counts by default), chosen when it's created. The one-type model stores `groups.kind: 'team'` so this needs no migration.
174. **Ads, once adoption justifies them** (SPEC STORE-7, [PLANS.md](PLANS.md)). Parents and guardians manage youth players' records in the app, on any team, so the plan must address children's privacy rules first: COPPA in the US (no behavioral ads to children, verifiable parental consent for any data from under-13s), and Google Play's Families policy (certified ad SDKs only, no personalized ads, if the app targets children or joins the Families program). Likely shape: contextual, non-personalized ads only, and none on teams with players that guardians manage, with the Privacy Policy, store privacy labels, and the Data safety form updated first.

Things that are out of scope for v1 entirely are listed in SPEC §11.
