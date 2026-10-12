# Battleplan — Roadmap

Every task and feature for Battleplan, in one numbered list, in the order they should happen. It pulls together [SPEC.md](SPEC.md) (features and milestones), [ARCHITECTURE.md](ARCHITECTURE.md) (how it's built), and [TODO.md](../TODO.md) (accounts and purchases).

**How to read it**

- Numbers run continuously from the first task to the last, so "task 14" always means the same thing. Order follows dependencies: a task never needs something further down the list.
- ✅ done · 👤 **Jared** (only you can do it: accounts, payments, decisions) · everything else is build work.
- Feature IDs (AUTH-1, CHAT-6, …) point to SPEC §6. The details live there; this file is the order.
- Each milestone ends working on iOS, Android, and web, with rules tests updated (SPEC §9).

Last updated: 2026-10-12. M5 (Polls), M6 (Schedule), M7 (Documents), and M8 (God admin panel) are built. Facebook sign-in was removed from the plan; it is a backlog item now.

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
12. 👤 **Jared:** Check your legal name and address on your Apple Account and Google payments profile (the stores read them in tasks 106 and 125).
13. ✅ 👤 **Jared:** Log in from the terminal: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`. **This blocks task 23 and spikes 1 to 3 (tasks 26 to 28).**

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

## Website and the web app at /app · before M9

SPEC §4.3 (WEB-1 to WEB-5), ARCH §6.6 and D40. The website is the `website/` folder: static HTML and CSS with no framework or build step. The Flutter web app moves from the root to `/app`.

175. The website in `website/`: a landing page explaining Battleplan (chat, schedule and RSVPs, polls, documents, youth teams; free, no ads), with screenshots and an **Open Battleplan** button to `/app` on every page; light and dark mode; works well on phones (WEB-1, WEB-5).
176. The website's support and legal pages: `/support`, `/privacy`, `/terms`, `/delete-account` (WEB-2; their wording is task 121).
177. One Hosting site for both: CI copies `website/` into `build/hosting/` and builds Flutter with `--base-href /app/` into `build/hosting/app/`; Hosting rewrites `/app/**` to the app, redirects `/join/*`, `/activate`, and `/g/*` into `/app` keeping query strings, and serves `.well-known` from the website. Dev gets the same layout; PR previews build both (WEB-3).
178. Links follow the move: the app's `LinkService` and the Functions `links` module build `/app/...` links for content and email setup, keep invite links short (`/join/<CODE>`), and push notifications open `https://<host>/app<route>`; the Auth `url` becomes `/app/activate`; Universal Links and App Links also match `/app/*`, and the native apps ignore the `/app` prefix; the web app's service worker, manifest, and push service worker work under `/app/`. Tested on dev: an invite link, a setup email, and a notification click in the browser, and an invite link on the Android emulator (WEB-4).
179. Website polish: favicon, Open Graph image and tags, `robots.txt` and a sitemap (the site indexed, `/app` not), and App Store and Google Play badges once the apps are listed (task 130).

## M9 · Hardening and team beta

104. Enforce App Check; review rules-test coverage.
105. Accessibility, performance (SPEC §8), and golden-test passes in both themes.
106. 👤 **Jared:** Enroll in the Apple Developer Program as an individual ($99/year). **Start about a week before the beta.**
107. 👤 **Jared:** Create the APNs key, the Sign in with Apple key, and the Services ID. Each key file downloads only once, so save it to 1Password right away.
108. Upload the APNs key to Firebase and turn on iOS push.
109. Turn on Sign in with Apple on iOS, Android, and web, and finish the sign-in matrix (spike 1).
110. Turn on iOS Universal Links with the Associated Domains entitlement (spike 2).
111. 👤 **Jared:** Turn on Cloudflare Email Routing and forward `support@` and `privacy@getbattleplan.app` to your Gmail.
112. 👤 **Jared:** Customize Firebase's email domain (`noreply@getbattleplan.app`, sender "Battleplan") and register both sending addresses with Apple's private email relay.
113. 👤 **Jared:** Confirm Q11 (where most teams are; default US, `us-central1`). **The prod database's region is permanent.**
114. 👤 **Jared:** Upgrade `battleplan-prod` to Blaze and set its budget alerts.
115. Create prod's database in that region; deploy rules, indexes, TTL policies, and functions; turn on daily backups; set the Remote Config minimum version.
116. 👤 **Jared:** Connect `getbattleplan.app` to prod's Hosting, with the Cloudflare records set to **DNS only** (grey cloud). It serves the website and the web app at `/app` (tasks 175 to 179).
117. Set up the manual prod release workflow, and decide where iOS builds run (macOS minutes on GitHub are 10×).
118. Bootstrap the first super admin on prod.
119. 👤 **Jared:** Confirm Q9 (logo and primary color; default placeholder mark and blue `#2F5BEA`).
120. App icons and splash screens.
121. Legal pages: Privacy Policy, Terms of Use, `/delete-account` (LEGAL-1, LEGAL-3), as pages on the website (task 176); no-tracking setup checked (LEGAL-2).
122. Beta with our team: TestFlight on iOS, Firebase App Distribution on Android, and the web; a bug bash.
123. Move our team over: paste the roster, recreate upcoming events as repeating practices, post the invite link in GroupMe and show the QR at practice, and run both apps for about two weeks.

## Launch · Open sign-up

124. 👤 **Jared:** Decide Q4 (how the platform is paid for) before there are hundreds of teams. The default is free with a 5 GB quota per team.
125. 👤 **Jared:** Open the Google Play Console as a personal account ($25 once). **Start 3 to 4 weeks before** you want to be on Google Play.
126. Generate the Android upload key at the first Play upload. 👤 **Jared:** store the keystore and its passwords in 1Password, plus an offline backup.
127. Add the Android SHA-1 and SHA-256 fingerprints (debug, upload, Play App Signing) to Firebase.
128. 👤 **Jared:** Run the Google Play closed test: 12+ testers opted in for 14 days in a row, then request production access.
129. Store listings: screenshots, descriptions, keywords, support and privacy URLs.
130. Store disclosures: App Store privacy labels and the Play Data safety form (LEGAL-4); age-rating questionnaires.
131. 👤 **Jared:** Declare EU trader status in both stores.
132. App Review demo account with a seeded team, and review notes explaining that teams are invite-only.
133. Submit to the App Store and Google Play.
134. Production deploy, and open sign-up to other teams.

---

## v1.1 · Soon after launch

In SPEC §9's priority order.

135. @mentions, edits, pins, and announcements (CHAT-14, CHAT-15).
136. Roster details and contact sharing (TEAM-10).
137. "Same answer for all my players" and per-player RSVP history (PLAYER-11).
138. Calendar subscription links (SCHED-11).
139. RSVP nudges and guest counts (SCHED-12).
140. Team-specific link previews for invites (ARCH §6.6).
141. Document folders and the chat photo gallery (DOC-7).
142. Announcement-only mode (TEAM-12).
143. Polls list, reminders to non-voters, member-added options, hidden results (POLL-6).
144. App icon badges, mention notifications, hidden message text (NOTIF-12).
145. Files in chat (CHAT-16).
146. Persistent team list on very wide screens (§5.5).

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
174. **Ads, once adoption justifies them** (SPEC STORE-7, [PLANS.md](PLANS.md)). Youth teams mean parents and guardians use the app for children, so the plan must address children's privacy rules first: COPPA in the US (no behavioral ads to children, verifiable parental consent for any data from under-13s), and Google Play's Families policy (certified ad SDKs only, no personalized ads, if the app targets children or joins the Families program). Likely shape: contextual, non-personalized ads on adult teams only, with the Privacy Policy, store privacy labels, and the Data safety form updated first.

- Facebook sign-in, if needed later (was tasks 101 to 103): Meta app, Continue with Facebook, Limited Login on iOS, App Review, and the data-deletion URL (LEGAL-5).

Things that are out of scope for v1 entirely are listed in SPEC §11.
