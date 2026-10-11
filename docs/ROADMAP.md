# Battleplan — Roadmap

Every task and feature for Battleplan, in one numbered list, in the order they should happen. It pulls together [SPEC.md](SPEC.md) (features and milestones), [ARCHITECTURE.md](ARCHITECTURE.md) (how it's built), and [TODO.md](../TODO.md) (accounts and purchases).

**How to read it**

- Numbers run continuously from the first task to the last, so "task 14" always means the same thing. Order follows dependencies: a task never needs something further down the list.
- ✅ done · 👤 **Jared** (only you can do it: accounts, payments, decisions) · everything else is build work.
- Feature IDs (AUTH-1, CHAT-6, …) point to SPEC §6. The details live there; this file is the order.
- Each milestone ends working on iOS, Android, and web, with rules tests updated (SPEC §9).

Last updated: 2026-10-11, after M0's code merged.

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
11. 👤 **Jared:** Make a Battleplan vault in 1Password for every login, key file, and recovery code.
12. 👤 **Jared:** Check your legal name and address on your Apple Account and Google payments profile (the stores read them in tasks 104 and 123).
13. ✅ 👤 **Jared:** Log in from the terminal: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`. **This blocks task 23 and spikes 1 to 3 (tasks 27 to 29).**

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
23. Run `flutterfire configure` for dev and prod, replacing the placeholder Firebase options. *Needs task 13.*
24. Set up keyless GitHub Actions deploys (Workload Identity Federation) to the dev project.
25. Turn on Hosting for the dev project; post a web preview link on every PR, and deploy rules, indexes, and hosting to dev on merge to `main`.
26. 👤 **Jared:** Create the Meta for Developers app (free, development mode) for Facebook sign-in.
27. Enable Google and Facebook sign-in on the dev project, then run **spike 1**: the sign-in matrix (provider × platform × new / existing / admin-added account). Apple joins in task 107.
28. Run **spike 2** on the dev Hosting domain: Android App Links, `assetlinks.json`, and email-link sign-in with `linkDomain` (no Dynamic Links). iOS Universal Links join in task 108.
29. Create the web push (VAPID) key on the dev project and run **spike 3**: web push on Chrome, macOS Safari, and an iPhone home-screen web app.

**M0 is done when** the empty app runs on iOS, Android, and Chrome, and every PR gets a web preview link.

## M1 · Accounts

30. Sign-in screen with all four options (AUTH-1); email and password (AUTH-2); Google and Facebook sign-in. Apple's code goes in now and is verified in task 107.
31. Email verification banner (AUTH-3) and password reset by email (AUTH-4).
32. First-run setup: name, photo, 18+ confirmation, Terms acceptance (AUTH-5, SAFE-3, SAFE-6); `ensureUserProfile`; the profile kept separate from sign-in providers (AUTH-12).
33. Sessions: stay signed in, sign out, sign out of all devices (AUTH-9).
34. Safe account linking and the Sign-in methods screen (AUTH-7, AUTH-8, SET-4).
35. Disabled accounts (AUTH-11) and account deletion (AUTH-10).
36. Profile and About screens (SET-1, SET-6); the theme setting syncs to the account (SET-2).
37. The super-admin bootstrap script.
38. Rules and tests for `users`.

**M1 is done when** the sign-in matrix passes on all three platforms (Apple waits for task 107).

## M2 · Teams and invites

39. 👤 **Jared:** Confirm or change the defaults for Q1 ("Team" or "Group"), Q3 (who creates teams), Q14 (staff RSVPs on youth teams), and Q15 (admin approval for guardian links). The build follows the SPEC §12 defaults until you do.
40. Create a team, with adult or youth type (TEAM-1); the welcome screen.
41. Team switcher and many teams per person (TEAM-2, §5.2).
42. Roster screen, roles, and team admins (TEAM-3, TEAM-4).
43. Team settings and member permissions (TEAM-5).
44. Transfer ownership, leave, archive, and delete (TEAM-6, TEAM-8, TEAM-9).
45. 👤 **Jared:** Pick the email provider (Q10; default Resend), sign up for its free tier, and add its SPF, DKIM, and DMARC records in Cloudflare.
46. Email sending from Functions (ARCH §6.7), with the API key in Secret Manager.
47. Add members by email, with account creation and setup emails (TEAM-7, AUTH-6).
48. Invite screen, invite link, QR code, and code (INV-1 to INV-3).
49. Email invites (INV-4).
50. Joining: `getInvitePreview`, `redeemInvite`, join by code or QR scan, the `/join` web page, error states (INV-5 to INV-8).
51. Universal Links and App Links for invites on our domain (INV-9, ENG-6). iOS is verified in task 108.
52. Youth teams: add players and pasted rosters (PLAYER-1), player card (PLAYER-2).
53. Youth teams: "Who are you here for?", guardian requests, adding a co-parent (PLAYER-3 to PLAYER-5).
54. Parent labels in the roster, "Maria R. · Emma #7" (PLAYER-8); kids' privacy limits on player records (PLAYER-10).
55. Storage quota accounting.
56. Rate limits for team creation, invites, and adds (SAFE-5).
57. Rules and tests for teams, members, players, and invites, including **cross-team isolation**.

**M2 is done when** a new coach can get three people in by link, QR, and email; a person on two teams can switch between them; and a pasted youth roster links each parent to the right player.

## M3 · Chat

58. 👤 **Jared:** Upgrade the dev project to the Blaze plan and set budget alerts at $5, $25, $50, and $100 the same day. Needed once Functions and photo storage run in the cloud for testing on real phones.
59. Message list with paging and date separators (CHAT-1).
60. Composer, links, and system messages (CHAT-2, CHAT-5, CHAT-10).
61. Photos and the full-screen viewer (CHAT-3).
62. Delivery states and the offline send queue (CHAT-4).
63. Reactions 👍 ❤️ 👎 😂 (CHAT-6) and the message menu (CHAT-7).
64. Replies with server-written quotes (CHAT-13).
65. Deleting messages through a Function, with the audit log (CHAT-8).
66. Unread counts and the "New messages" divider, synced across devices (CHAT-9).
67. Report and block (SAFE-1, SAFE-2, CHAT-12); the team's Reports screen and acting on reports (SAFE-4); the blocked-people list (SET-5).

**M3 is done when** the CHAT acceptance criteria pass (SPEC §6.5).

## M4 · Notifications

68. Device registration and the `notify` fan-out Function (one pipeline for push and the notification center).
69. Asking permission at the right moment (NOTIF-1).
70. Per-team level and mute, global switches, and the Notifications settings screen (NOTIF-3, NOTIF-4, SET-3).
71. Notification wording, grouping, and multiple devices (NOTIF-5, NOTIF-8, NOTIF-10).
72. Tap to open and in-app banners (NOTIF-6, NOTIF-7).
73. Notification center with the bell (NOTIF-11).
74. Web push and the iOS Safari tip (NOTIF-9).
75. Turn on notifications for chat messages, replies, being added to a team, being made admin, guardian requests, and reports (NOTIF-2).

From here on, each feature ships with its own notifications.

## M5 · Polls

76. Create a poll and the poll card in chat (POLL-1, POLL-2, CHAT-11).
77. Who voted, and anonymous polls (POLL-3).
78. Closing early, auto-close in the `tick` job, and the "Poll closed" notification (POLL-4).
79. Deleting a poll with its message (POLL-5).
80. Rules and tests for polls and votes.

## M6 · Schedule

81. 👤 **Jared:** Confirm Q12 (can members create events by default; default admins only).
82. Create an event with types and game fields (SCHED-3); event details (SCHED-4).
83. RSVPs, including Maybe and admins answering for members (SCHED-5).
84. Per-player RSVPs and guardian notifications on youth teams (PLAYER-6, PLAYER-7).
85. Upcoming, Past, and Calendar views (SCHED-1); All my teams, with each parent's player named (SCHED-2, PLAYER-9).
86. Editing, cancel, and delete, with change notifications (SCHED-6, SCHED-7).
87. Repeating events through `saveEventSeries`: daily and weekly, skip dates, this-and-following edits, cancel, and delete.
88. Duplicate an event (SCHED-3).
89. Reminders in the `tick` job (SCHED-8); event cards in chat (CHAT-11).
90. Time zones (SCHED-9) and Add to calendar (SCHED-10).
91. Rules and tests for events, series, and RSVPs.

**M6 is done when** the SCHED and PLAYER acceptance criteria pass (SPEC §6.3, §6.7).

## M7 · Documents

92. Documents tab, uploads, and links (DOC-1 to DOC-3), with the storage-full message.
93. Opening, sharing, and downloading (DOC-4).
94. Rename, describe, delete, pin (DOC-5).
95. New-document notifications (DOC-6).
96. Rules and tests for documents and Storage.

## M8 · God admin panel

97. Admin panel shell at `/admin`, loaded separately; dashboard (ADMIN-1).
98. Teams list and team detail, including View team, suspend, archive, and delete (ADMIN-2, ADMIN-3).
99. Users: create, disable, reset, sign out everywhere, grant super admin (ADMIN-4).
100. Report queue (ADMIN-5) and audit log (ADMIN-6).
101. Platform settings and the announcement banner (ADMIN-7); safeguards (ADMIN-8).

## M9 · Hardening and team beta

102. Enforce App Check; review rules-test coverage.
103. Accessibility, performance (SPEC §8), and golden-test passes in both themes.
104. 👤 **Jared:** Enroll in the Apple Developer Program as an individual ($99/year). **Start about a week before the beta.**
105. 👤 **Jared:** Create the APNs key, the Sign in with Apple key, and the Services ID. Each key file downloads only once, so save it to 1Password right away.
106. Upload the APNs key to Firebase and turn on iOS push.
107. Turn on Sign in with Apple on iOS, Android, and web, and finish the sign-in matrix (spike 1).
108. Turn on iOS Universal Links with the Associated Domains entitlement (spike 2).
109. 👤 **Jared:** Turn on Cloudflare Email Routing and forward `support@` and `privacy@getbattleplan.app` to your Gmail.
110. 👤 **Jared:** Customize Firebase's email domain (`noreply@getbattleplan.app`, sender "Battleplan") and register both sending addresses with Apple's private email relay.
111. 👤 **Jared:** Confirm Q11 (where most teams are; default US, `us-central1`). **The prod database's region is permanent.**
112. 👤 **Jared:** Upgrade `battleplan-prod` to Blaze and set its budget alerts.
113. Create prod's database in that region; deploy rules, indexes, TTL policies, and functions; turn on daily backups; set the Remote Config minimum version.
114. 👤 **Jared:** Connect `getbattleplan.app` to prod's Hosting, with the Cloudflare records set to **DNS only** (grey cloud).
115. Set up the manual prod release workflow, and decide where iOS builds run (macOS minutes on GitHub are 10×).
116. Bootstrap the first super admin on prod.
117. 👤 **Jared:** Confirm Q9 (logo and primary color; default placeholder mark and blue `#2F5BEA`).
118. App icons and splash screens.
119. Legal pages: Privacy Policy, Terms of Use, `/delete-account` (LEGAL-1, LEGAL-3); no-tracking setup checked (LEGAL-2).
120. Beta with our team: TestFlight on iOS, Firebase App Distribution on Android, and the web; a bug bash.
121. Move our team over: paste the roster, recreate upcoming events as repeating practices, post the invite link in GroupMe and show the QR at practice, and run both apps for about two weeks.

## Launch · Open sign-up

122. 👤 **Jared:** Decide Q4 (how the platform is paid for) before there are hundreds of teams. The default is free with a 5 GB quota per team.
123. 👤 **Jared:** Open the Google Play Console as a personal account ($25 once). **Start 3 to 4 weeks before** you want to be on Google Play.
124. Generate the Android upload key at the first Play upload. 👤 **Jared:** store the keystore and its passwords in 1Password, plus an offline backup.
125. Add the Android SHA-1 and SHA-256 fingerprints (debug, upload, Play App Signing) to Firebase.
126. 👤 **Jared:** Run the Google Play closed test: 12+ testers opted in for 14 days in a row, then request production access.
127. 👤 **Jared:** Submit Facebook App Review, with the privacy-policy and data-deletion URLs (LEGAL-5).
128. Store listings: screenshots, descriptions, keywords, support and privacy URLs.
129. Store disclosures: App Store privacy labels and the Play Data safety form (LEGAL-4); age-rating questionnaires.
130. 👤 **Jared:** Declare EU trader status in both stores.
131. App Review demo account with a seeded team, and review notes explaining that teams are invite-only.
132. Submit to the App Store and Google Play.
133. Production deploy, and open sign-up to other teams.

---

## v1.1 · Soon after launch

In SPEC §9's priority order.

134. @mentions, edits, pins, and announcements (CHAT-14, CHAT-15).
135. Roster details and contact sharing (TEAM-10).
136. "Same answer for all my players" and per-player RSVP history (PLAYER-11).
137. Calendar subscription links (SCHED-11).
138. RSVP nudges and guest counts (SCHED-12).
139. Team-specific link previews for invites (ARCH §6.6).
140. Document folders and the chat photo gallery (DOC-7).
141. Announcement-only mode (TEAM-12).
142. Polls list, reminders to non-voters, member-added options, hidden results (POLL-6).
143. App icon badges, mention notifications, hidden message text (NOTIF-12).
144. Files in chat (CHAT-16).
145. Persistent team list on very wide screens (§5.5).

## Later · Backlog

146. Join requests that need admin approval; copying a team for a new season (TEAM-13).
147. Organizations and leagues; sub-chats within a team (TEAM-13).
148. Coach and staff RSVPs on youth teams (PLAYER-12).
149. Direct messages (Q5); message search; link previews, GIFs, video, voice notes; typing indicators and read receipts (CHAT-17).
150. Attendance tracking, reports with CSV export, game scores (SCHED-13).
151. Volunteer and snack sign-ups, carpools, season availability surveys (SCHED-13).
152. Document version history, comments, and e-signatures (DOC-8).
153. Quiet hours, email digests, SMS (NOTIF-13).
154. Per-team profanity filter (SAFE-7), sooner if App Review asks.
155. Cloud SQL, if usage meets the ARCH §12.1 triggers.

Things that are out of scope for v1 entirely are listed in SPEC §11.
