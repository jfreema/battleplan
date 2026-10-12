# Battleplan — Product Spec

| | |
|---|---|
| **Status** | Draft v0.3 |
| **Owner** | Jared Freeman |
| **Last updated** | 2026-10-10 |
| **Companion doc** | [ARCHITECTURE.md](ARCHITECTURE.md): how it's built ("ARCH §n" below) |

---

## 1. Overview

Battleplan is a messaging and scheduling app for sports teams, doing in one app what **GroupMe** (chat) and **TeamReach** (schedules and RSVPs) do. It runs on **iOS, Android, and the web**.

**How it's organized:**

- Any coach or manager can create a **team**. Each team has its own members, admins, chat, schedule, and documents.
- People can belong to many teams and switch between them.
- **Every account belongs to an adult (18+).** On **youth teams**, the players are kids who don't use the app. Their parents and guardians are the members, and they answer RSVPs for their players (§6.3).
- Platform **super admins** ("God admins") oversee every team.

**Rollout.** Our own team uses it first. Then sign-up opens to any team, and every team is **invite-only**.

### Glossary

| Term | Meaning |
|---|---|
| **Team** | A group of people with its own chat, schedule, and documents. Stored as a `group` (ARCH §1). |
| **Member** | A person with an account who belongs to a team |
| **Team admin** | A member who manages the team: a coach, manager, or team parent |
| **Owner** | The one admin per team who created it, or was given it |
| **Super admin** | A platform operator who can see and manage every team and user (the "God admin") |
| **Added account** | An account created by an admin before the person first signs in (the "local account") |
| **Team type** | **Adult**: the members are the players and answer RSVPs for themselves. **Youth**: the players are kids without accounts, and their guardians answer for them. |
| **Player** | On a youth team, a kid on the roster. Players never have accounts. |
| **Guardian** | A member linked to a player on a youth team, usually a parent, who answers RSVPs for that player |
| **Storage limit** | How much a team can store in photos and files: 500 MB unless a super admin raises it (STORE-1) |

### Release tags

| Tag | Meaning |
|---|---|
| **MVP** | Needed to launch |
| **v1.1** | Next, soon after launch |
| **Later** | Backlog |

### MVP success criteria

- Our team moves completely off GroupMe and TeamReach.
- A new coach can sign up, create a team, and have members chatting **within 10 minutes**, without help.
- A youth coach can paste in a roster of players with their parents' emails, then see per-player RSVP counts for the next practice.
- Every MVP feature works the same on iOS, Android, and web (§4).
- Push notifications typically arrive **within 5 seconds**.
- The monthly bill stays within the cost model (ARCH §10).

---

## 2. Requirements coverage

### 2.1 Stated requirements

| # | Requirement | Where it's covered |
|---|---|---|
| 1 | App name: Battleplan | §7.1; ARCH §5.7 (app IDs) |
| 2 | Built in Flutter and Dart in VS Code | ARCH §4, §5, §8 |
| 3 | Deployed to Firebase | ARCH §4 ("Deployed to Firebase, precisely"), §9 |
| 4 | Firebase NoSQL now; Cloud SQL later if usage justifies it | ARCH §6.2, §10, §12 |
| 5 | iOS, Android, and web, fully functional and consistent | §4 |
| 6 | Group messaging | §6.5 (CHAT) |
| 7 | Push notifications | §6.9 (NOTIF); ARCH §6.5 |
| 8 | Polls in group messaging | §6.6 (POLL) |
| 9 | Scheduling events with going / not going | §6.7 (SCHED-3 to SCHED-5); PLAYER-6 on youth teams |
| 10 | Sign in with Google, Apple, or email, on top of local accounts that admins can add | AUTH-1, AUTH-6 to AUTH-8, AUTH-12; ARCH §6.1 |
| 11 | Password reset by email | AUTH-4 |
| 12 | Email invites | INV-4 |
| 13 | Shareable invite links and QR codes | INV-1 to INV-3, INV-6, INV-7 |
| 14 | Light mode and dark mode | SET-2; §7.4 |
| 15 | God admin panel for managing all teams | §6.11 (ADMIN) |
| 16 | Admins in each team | §3; TEAM-4 |
| 17 | Admins can delete messages | CHAT-8 |
| 18 | 👍 ❤️ 👎 😂 reactions on messages | CHAT-6 |
| 19 | Modern, clean UI | §7 |
| 20 | Bottom tabs: Chat, Schedule, Documents | §5.3 |
| 21 | Many sports teams, each with its own members, chat, and schedule | TEAM-1, TEAM-2, SCHED-2, §5.2; ARCH §1, §3 |
| 22 | Youth players don't use the app; their adult parents and guardians do | AUTH-5, §6.3 (PLAYER), SAFE-6; ARCH §1 |
| 23 | Parent/guardian → player relationships, so parents RSVP for their child, not themselves | §6.3 (PLAYER-1 to PLAYER-6); ARCH §6.2 |
| 24 | One RSVP per event and player, so two parents can't create conflicting records | PLAYER-6; ARCH §6.2 |
| 25 | Multiple teams per person | TEAM-2 |
| 26 | Switching between teams | §5.2, TEAM-2 |
| 27 | Battleplan profiles separate from Google and Apple identities | AUTH-12; ARCH §6.1 |
| 28 | Admin-created accounts set up by email; admins never know passwords | AUTH-6; ARCH §6.1 |
| 29 | Safe linking between Google, Apple, and email sign-ins | AUTH-7, AUTH-8; ARCH §6.1 |
| 30 | Unread message counts | CHAT-9 |
| 31 | Message pagination | CHAT-1; ARCH §5.3 |
| 32 | Reply to a message | CHAT-13 |
| 33 | In-app notification center | NOTIF-11; ARCH §6.5 |
| 34 | Per-team notification and mute settings | NOTIF-3 |
| 35 | Rate limiting and abuse controls | SAFE-5; ARCH §6.9 |
| 36 | Account deletion | AUTH-10, LEGAL-3 |
| 37 | Firestore cost-efficiency rules | ENG-5; ARCH §10.2 |
| 38 | No Firebase Dynamic Links: HTTPS URLs with Universal Links and App Links | INV-9, ENG-6; ARCH §6.6 |
| 39 | SQL-shaped Firestore model without deep nesting | ENG-3; ARCH §6.2, §12 |
| 40 | Firebase calls only in the data/repository layer | ENG-1; ARCH §5.2 |
| 41 | No architectural spaghetti | ENG-2, ENG-4; ARCH §5.2, §6.4 |

### 2.2 Additions in this spec

| Addition | Why |
|---|---|
| Photos in chat (CHAT-3) | Core to GroupMe; teams share game photos constantly |
| "Maybe" RSVP, reminders, repeating events, time zones, add to calendar, game details (SCHED) | What makes TeamReach useful for weekly practices and away games |
| "All my teams" schedule (SCHED-2) | Parents and players on several teams need one calendar |
| Unread indicators and offline support (CHAT-4, CHAT-9) | Expected in any chat app |
| Report, block, and Terms acceptance (SAFE) | **Required** by the App Store for apps with user content |
| In-app account deletion (AUTH-10) | **Required** by the App Store and Google Play |
| Youth teams: players without accounts, linked to their parents and guardians, with per-player RSVPs (§6.3) | Kids don't use the app, but coaches still need to know which *players* are coming, not which parents answered |
| Adults-only accounts, 18+ (AUTH-5) | Matches who actually uses the app, and keeps us from collecting data from children |
| Pasted rosters with setup emails (TEAM-7) | Turns "admins can add local accounts" into a fast way for coaches to load a team |
| Spam controls, storage quotas, team suspension (SAFE-5, ADMIN-3) | Needed once anyone can create a team |
| Audit log (ADMIN-6) | Accountability for admin deletions and other admin actions |
| Forced app update (ARCH §9) | Lets us retire old app versions safely, including during a future SQL move |
| Privacy Policy, Terms, store disclosures (LEGAL) | **Required** to publish |
| Accessibility and translation-ready text (§7.6, §7.7) | Good practice, and cheap if done from the start |
| An explainer website at `getbattleplan.app`, with the web app at `/app` (§4.3) | A place to explain Battleplan, host the legal pages, and send people to the stores or the web app |
| Everything free with no ads, and a 500 MB storage limit per team with a Media section to free space (§6.14, [PLANS.md](PLANS.md)) | Keeps adoption easy while capping what one team can cost (Q4); ads may come once adoption justifies them |

---

## 3. Roles and permissions

| Role | Who |
|---|---|
| **Member** | Anyone on the team |
| **Guardian** | On youth teams, a member linked to one or more players, who answers RSVPs for them |
| **Team admin** | Manages the team: coaches, managers, team parents |
| **Owner** | The admin who created the team, or was given it. Exactly one per team. |
| **Super admin** | Runs the platform. Can see and manage every team and user. |
| **Signed-out visitor** | Sees only the sign-in screens and a team's invite preview |

**Permission matrix.** "Setting" means the action is controlled by a per-team permission toggle (TEAM-5), shown with its default.

| Action | Member | Team admin | Owner | Super admin |
|---|:-:|:-:|:-:|:-:|
| Read the team's chat, schedule, documents, members | ✓ | ✓ | ✓ | ✓ any team |
| Send messages and photos, react, vote; RSVP for self (adult teams) | ✓ | ✓ | ✓ | in teams they've joined |
| Delete own messages | ✓ | ✓ | ✓ | ✓ |
| **Delete anyone's message** | — | ✓ | ✓ | ✓ |
| Create polls | setting (on) | ✓ | ✓ | ✓ |
| Close any poll | — | ✓ | ✓ | ✓ |
| Create events | setting (off) | ✓ | ✓ | ✓ |
| Edit, cancel, or delete events | own only | ✓ | ✓ | ✓ |
| RSVP for your own players (youth teams) | guardians | ✓ | ✓ | ✓ |
| RSVP for any member or player | — | ✓ | ✓ | ✓ |
| Add players (youth teams) | as their guardian | ✓ | ✓ | ✓ |
| Add a guardian to a player | own players | ✓ | ✓ | ✓ |
| Remove guardians; approve guardian requests | — | ✓ | ✓ | ✓ |
| Upload documents and add links | setting (on) | ✓ | ✓ | ✓ |
| Delete any document; pin documents | — | ✓ | ✓ | ✓ |
| Share the invite link, QR, or code; send email invites | setting (on) | ✓ | ✓ | ✓ |
| Add people by email (creates accounts) | — | ✓ | ✓ | ✓ |
| Reset or revoke invite links | — | ✓ | ✓ | ✓ |
| Remove members | — | non-admins | ✓ | ✓ |
| Make someone an admin | — | ✓ | ✓ | ✓ |
| Remove someone's admin role | — | — | ✓ | ✓ |
| Edit team profile and settings | — | ✓ | ✓ | ✓ |
| See and act on reports in the team | — | ✓ | ✓ | ✓ |
| Transfer ownership | — | — | ✓ | ✓ |
| Archive or delete the team | — | — | ✓ | ✓ |
| Leave the team | ✓ | ✓ | after transferring | — |
| See all teams and users; suspend teams; disable users; create users anywhere | — | — | — | ✓ |
| Grant or revoke super admin | — | — | — | ✓ |
| See storage used; delete photos and files in Media (STORE-2, STORE-5) | — | ✓ | ✓ | ✓ |
| Raise or lower a team's storage limit (STORE-6) | — | — | — | ✓ |

These rules are enforced on the server (Firestore rules and Functions), never only in the UI. The matrix is the source of truth if the backend ever moves to SQL (ARCH §12.2).

---

## 4. Platforms and parity

### 4.1 Supported platforms

| Platform | Minimum | Distribution |
|---|---|---|
| iPhone and iPad | iOS 15 | App Store |
| Android phones and tablets | Android 8.0 (API 26) | Google Play |
| Web, desktop and mobile | Latest two versions of Chrome, Edge, Firefox, Safari | Firebase Hosting at **`getbattleplan.app/app`**, linked from the website (§4.3). Installable as a home-screen app (PWA). |

### 4.3 The website (WEB)

`getbattleplan.app` is a small explainer website; the web app lives under it at **`getbattleplan.app/app`**. The site's source is the `website/` folder in the repo (ARCH §5.1, §6.6).

- **WEB-1 · MVP · Landing page.** What Battleplan is (team chat, schedule and RSVPs, polls, documents, youth teams with parents and guardians), that it's free with no ads, screenshots, and clear ways in: **Open Battleplan** (the web app at `/app`), and App Store and Google Play badges once the apps are listed.
- **WEB-2 · MVP · Support and legal pages.** `/privacy`, `/terms`, and `/delete-account` (LEGAL-1, LEGAL-3), and `/support` with the support email. These are the URLs the store listings and Firebase settings use.
- **WEB-3 · MVP · The web app at `/app`.** The Flutter web app is served under `/app/` and linked from every page of the site. Signed-in people who open `/app` go straight to their teams.
- **WEB-4 · MVP · Short links still work.** Invite links and QR codes keep the short form `getbattleplan.app/join/K7XP-M2QR`. With the app installed they open it; otherwise the browser lands in the web app's join page under `/app`. Email and notification links also open the app if installed, or the web app.
- **WEB-5 · MVP · Fast and plain.** Static pages with no ads, no tracking, and no cookie banner needed; light and dark mode; readable on phones; indexed by search engines, while `/app` isn't.

### 4.2 The parity rule

- Every feature ships on all three platforms **in the same release**, with the same behavior, layout, and wording.
- A feature is done only after it's been tested on:
  - an iPhone;
  - an Android phone;
  - a desktop browser;
  - a phone browser, for the join flow.
- Differences are allowed only where the platform forces them:

| Capability | iOS | Android | Web |
|---|---|---|---|
| Push notifications | Yes | Yes | Yes, after browser permission. On iPhone/iPad, only once added to the Home Screen. |
| Sign in with Apple | Native sheet | Web sign-in flow | Popup |
| Scan a QR code | Camera | Camera | Camera, with browser permission |
| Add photos | Library or camera | Library or camera | File picker, drag and drop, or paste |
| Add to calendar | Calendar sheet | Calendar app | Downloads an .ics file |
| Share | Share sheet | Share sheet | Web Share where supported, otherwise copy link |
| Invite links | Open the app (Universal Links) | Open the app (App Links) | Open the site |
| Save files | Files or Photos | Downloads | Browser download |
| Haptics | Yes | Yes | — |
| Keyboard | — | — | Enter sends, Shift+Enter new line, Esc closes, Ctrl/⌘+K opens the team switcher |
| Offline | Full offline cache | Full offline cache | Offline cache in the browser (lost if site data is cleared) |

---

## 5. Navigation and layout

### 5.1 App map

```
Sign in
 ├─ First time → Profile setup (name, photo, 18+ confirmation, terms)
 │     └─ No teams yet → Welcome: [Join a team]  [Create a team]
 └─ Team view (opens the last team you used)
      ├─ Header:     team switcher ▾ · notification bell · team menu ⋯ · your avatar
      ├─ Tabs:       Chat | Schedule | Documents
      ├─ Team menu:  Roster · Invite · Notifications for this team ·
      │              Team settings* · Reports* · Leave team          (* admins)
      └─ Your avatar: Settings · Admin panel** · Sign out           (** super admins)
```

### 5.2 Team switcher

- **Header.** Shows the current team's logo (or initials on its color), the team name, and ▾. A dot appears on it when another team has unread messages.
- **Opening it.** A bottom sheet on phones; a dropdown panel on wide screens.
- **Contents.**
  - Your teams, most recent activity first.
  - Each team shows its logo, name, sport icon, last-message preview, unread message count, and muted icon.
  - Archived teams collapse into an "Archived" section.
  - At the bottom: **Join a team** (code or QR) and **Create a team**.
- **Switching** keeps you on the same tab: from one team's Schedule to the other team's Schedule.
- **Memory.** The app remembers the last team and tab on each device.

### 5.3 Bottom tabs

| Tab | Icon | Badge |
|---|---|---|
| **Chat** | Speech bubble | Unread message count for this team (CHAT-9) |
| **Schedule** | Calendar | Number of events in the next 14 days still waiting for your RSVP (or your players') |
| **Documents** | Folder | — |

- Labels are always visible. The tabs, order, and icons are the same everywhere.
- Each tab keeps its scroll position when you switch away and back.

### 5.4 Phone layout (Chat tab)

```
┌────────────────────────────────────┐
│ (TU) Thunder U14 v       ...  (JF) │
├────────────────────────────────────┤
│               Today                │
│ (AK) Alex Kim                      │
│      ┌─────────────────────────┐   │
│      │ Field 3 is open. See    │   │
│      │ you at 6!               │   │
│      └─────────────────────────┘   │
│       (Like 4) (Love 1)            │
│               ┌──────────────────┐ │
│               │ On my way!       │ │
│               └──────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ PRACTICE  Tue Oct 14, 6:00 PM  │ │
│ │ Riverside Park, Field 3        │ │
│ │ [Going] [Maybe] [Not going]    │ │
│ │ 12 going · 3 maybe · 2 no      │ │
│ └────────────────────────────────┘ │
├────────────────────────────────────┤
│ (+)  Message Thunder U14...    (>) │
├────────────────────────────────────┤
│  [Chat]     Schedule    Documents  │
└────────────────────────────────────┘
```

### 5.5 Wide screens (web and tablets, 840 px and up)

- **Navigation.** The tabs move to a **left rail**: the team switcher at the top, then Chat, Schedule, and Documents, with your avatar at the bottom. The order, icons, and labels match phones.
- **Chat** is centered at a readable width (about 840 px).
- **Panels.** Event details, member cards, and settings open as side panels or dialogs instead of full screens.
- **v1.1.** On very wide screens (1200 px and up), a persistent team list column, like Slack's.

---

## 6. Features

Each requirement has an ID, a release tag, and a short description. IDs are stable; reference them in issues and PRs.

### 6.1 Accounts and sign-in (AUTH)

- **AUTH-1 · MVP · Sign-in screen.**
  - Buttons in this order: Continue with Google, Continue with Apple, Continue with email.
  - Logo and a one-line tagline above them.
  - Footer: "By continuing you agree to the Terms and Privacy Policy", with links.
  - The screen is identical on every platform. The Apple button follows Apple's design rules.
- **AUTH-2 · MVP · Email and password.**
  - Sign in, or create an account with name, email, and password.
  - Passwords need 8+ characters, enforced by Firebase's password policy.
  - Show/hide password toggle.
- **AUTH-3 · MVP · Email verification.**
  - Google and Apple sign-ins arrive verified. Email sign-ins get a verification link, and a banner stays up until it's tapped.
  - A verified email is required to create a team, send email invites, or add people by email.
- **AUTH-4 · MVP · Password reset by email.**
  - "Forgot password?" → enter email → "If an account exists for that email, we've sent a reset link."
  - The link opens the reset page; then the user signs in with the new password.
  - The screen notes that people who use Google or Apple don't have a Battleplan password.
- **AUTH-5 · MVP · First-run setup.**
  - Name and photo, prefilled once from the sign-in provider (AUTH-12), and Terms acceptance.
  - Confirm "I'm 18 or older". Accounts are for adults only: youth players never sign in, and their parents and guardians use the app for them (§6.3).
  - Only the confirmation and its date are stored.
- **AUTH-6 · MVP · Accounts added by admins.**
  - Team admins and super admins add people with just a **name and email** (TEAM-7, PLAYER-1, ADMIN-4).
  - **Admins never set, see, or know anyone's password.** No screen or tool lets them. They can only send setup and password-reset emails.
  - The person gets a **setup email**. Its link signs them in, verifies their email, and asks how they want to sign in from now on: Google, Apple, or a password they create.
  - Setup links expire, and admins can resend a fresh one.
  - Until setup, the person appears on the roster as "Not joined yet", and admins can RSVP for them.
- **AUTH-7 · MVP · Safe account linking.**
  - **Prove both sides.** A sign-in method is added only when the person is signed in to their Battleplan account (recently) and completes the provider's own sign-in.
  - **No merging just because emails match.** If someone tries a new method with an email that already has an account, the app explains ("You've signed in with Google before. We sent you a link to confirm it's you.") and links the new method only after that emailed link is opened. The one exception is Google sign-in for a Gmail address, because Google vouches for those itself.
  - **Security emails.** Adding or removing a sign-in method, or changing the email or password, sends a notice: "Google sign-in was added to your Battleplan account. Not you? Contact support."
  - **A fresh sign-in is required** for linking, unlinking, changing the email or password, and deleting the account.
  - **Two separate accounts are never merged automatically.** Support can move memberships by hand.
- **AUTH-8 · MVP · Sign-in methods screen.**
  - Settings → Sign-in methods lists the linked methods (Google, Apple, password).
  - Link another, unlink one (never the last), or set or change a password.
  - Change the account email, confirmed through a link sent to the new address. The old address gets a notice.
- **AUTH-9 · MVP · Sessions.**
  - Stay signed in across app restarts and browser sessions.
  - Sign out from Settings; that stops push notifications on that device.
  - "Sign out of all devices" ends every session at once.
- **AUTH-10 · MVP · Delete account.**
  - Settings → Account → Delete account explains what will happen, asks the user to sign in again, then deletes everything.
  - Owners pick a new owner for each team they own. If they skip it, ownership goes to the longest-serving admin, otherwise the longest-serving member. Teams with nobody else are archived.
  - They stop being a guardian of any players. A player left with no guardian stays on the roster for admins to manage.
  - Their past messages stay, shown from "Deleted user".
  - Required by the App Store and Google Play. A web page also explains how to request deletion (LEGAL-3).
- **AUTH-11 · MVP · Disabled accounts.** Signing in shows only "This account has been disabled. Contact support@…".
- **AUTH-12 · MVP · Battleplan profile, separate from sign-in methods.**
  - The profile (name, photo, contact email, preferences) belongs to the Battleplan account, not to Google or Apple.
  - Provider details are used once, to prefill the profile at first sign-in, and the photo is copied into Battleplan then.
  - After that, only the person changes their profile. Linking or unlinking a sign-in method, or changes made at Google or Apple, never change it.
  - Teams, roles, messages, and RSVPs belong to the Battleplan account, so they survive any change of sign-in method.

**Edge cases**

- Cancelling the Google or Apple sheet returns to sign-in with no error.
- If a browser blocks the sign-in popup, explain how to allow popups.
- Apple "Hide My Email" works normally. People added by an admin are told to use the link in their setup email first (ARCH §6.1).
- Offline: an inline error with Retry.

### 6.2 Teams and membership (TEAM)

- **TEAM-1 · MVP · Create a team.**
  - **Who:** any signed-in user with a verified email. Super admins can turn this off, and each person can create up to 5 teams a day.
  - **Fields:**
    - **Team type:** Adult team (the members are the players) or Youth team (kids are the players; parents and guardians use the app). Admins can change it later; events already on the schedule keep the RSVPs they have.
    - Name (required, ≤ 50 characters).
    - Sport: Baseball, Basketball, Football, Hockey, Lacrosse, Soccer, Softball, Volleyball, or Other.
    - Logo or photo (optional).
    - Team color (optional). Chosen from 13 colors that pass contrast checks in both themes.
    - Time zone (defaults to the device's).
    - Description (optional).
  - The creator becomes the **owner**, and the next screen is "Invite your team" (INV-1).
  - **Goal:** create a team and share an invite in under 2 minutes.
- **TEAM-2 · MVP · Many teams per person.**
  - A person can be on up to 100 teams and switches between them with the team switcher (§5.2).
  - Each team has its own chat, schedule, documents, members, admins, settings, and notification level.
  - Teams are walled off from each other. Nothing shows which other teams a member belongs to.
- **TEAM-3 · MVP · Roster screen.**
  - **Adult teams:** sections for Admins and Members.
  - **Youth teams:** a **Players** section (jersey number, name, position, guardians) and a **Parents & staff** section, where each parent shows their players ("Parent of Emma #7").
  - Each person row shows a photo or initials, name, title, role badge (Owner/Admin), and "Not joined yet" for added accounts.
  - Search by name.
  - Tap a person to open their card: photo, name, title, role, their players, and only the actions you're allowed. Actions: Make admin / Remove admin, Edit title, Remove from team, Resend setup email, Report, Block.
  - Tap a player to open the player card (PLAYER-2).
- **TEAM-4 · MVP · Team admins.**
  - The owner and admins run the team (§3).
  - Admins can make other members admins. Only the owner, or a super admin, can take admin away.
  - Every team has exactly one owner.
- **TEAM-5 · MVP · Team settings (admins).**
  - Edit name, sport, logo, color, description, and time zone.
  - **Member permissions** (defaults in brackets):
    - create events [off]
    - create polls [on]
    - upload documents [on]
    - invite others [on]
    - allow "Maybe" RSVPs [on]
  - Default event reminders: 1 day before.
  - Manage the invite link.
  - See storage used, e.g. "212 MB of 500 MB", and open Media to free space (STORE-2, STORE-5).
- **TEAM-6 · MVP · Transfer ownership.** The owner picks a member to take over and becomes an admin.
- **TEAM-7 · MVP · Add members by email (admins).**
  - Add one person at a time, or paste a list of "Name, email" lines (up to 100).
  - People who already have accounts are added and notified. New emails get an account and a setup email (AUTH-6).
  - A results screen lists who was added, who was invited, and any problems.
  - On youth teams, admins usually add players with their parents' emails instead (PLAYER-1).
- **TEAM-8 · MVP · Leave a team.**
  - Anyone can leave.
  - The owner must transfer ownership first. If they're the only member, they archive or delete the team instead.
- **TEAM-9 · MVP · Archive or delete (owner, super admins).**
  - **Archive** makes the team read-only and moves it to "Archived" in the switcher. It can be restored.
  - **Delete** requires typing the team name. It permanently removes all messages, events, documents, and files.
- **TEAM-10 · v1.1 · Roster details.**
  - Adult teams: jersey number and position for each member, and the roster can be sorted by number. (Youth teams already have these on players, PLAYER-1.)
  - Optional contact sharing: members can share a phone number and email with a team. These appear on their card with call, text, and email buttons.
- **TEAM-11 · MVP · Youth teams.** Players and guardians are specified in §6.3 (PLAYER).
- **TEAM-12 · v1.1 · Announcement-only mode.** Only admins can post in chat. Everyone can still react, vote, and RSVP.
- **TEAM-13 · Later.**
  - Join requests that need admin approval.
  - Copying a team for a new season (members and settings).
  - Organizations and leagues with club admins.
  - Sub-chats within a team ("Parents", "Coaches").

### 6.3 Players and guardians on youth teams (PLAYER)

On youth teams, the kids are the players, but they never use the app. Their parents and guardians are the members: they chat, get notifications, and answer RSVPs for their players. This section applies only to teams whose type is **Youth**.

- **PLAYER-1 · MVP · Add players (admins).**
  - Add one at a time: name (required), jersey number, position, and up to 4 guardians (name and email, both optional).
  - Or paste a list with one line per guardian: "Player name, Guardian name, Guardian email". Lines with the same player name become one player with several guardians. Up to 200 lines.
  - Guardians who already have accounts are linked right away. New emails get an added account and a setup email (AUTH-6), and the guardian is linked once they finish setup.
  - A results screen shows the players added, guardians linked, guardians invited, and any problems.
- **PLAYER-2 · MVP · Player card.**
  - Shows the name, jersey number, position, guardians ("Not joined yet" where it applies), and upcoming RSVPs.
  - Guardians can edit the name, number, and position.
  - Admins can also add or remove guardians and remove the player.
- **PLAYER-3 · MVP · Parents joining by link or QR.** After joining a youth team, a parent sees "Who are you here for?":
  - **Pick your player** from the roster, or several. This sends a request to the team's admins (Q15). Until an admin approves, the parent can chat but can't answer RSVPs for that player.
  - **Add a player who isn't listed.** This creates the player with the parent as guardian. Admins are notified and can edit or remove it.
  - **I'm a coach or another adult.** Skips this step.
  - Parents whose email an admin already entered for a player (PLAYER-1) are linked automatically and never see this step.
- **PLAYER-4 · MVP · Guardian requests (admins).** Requests appear at the top of the roster with Approve and Decline, and admins get a notification. A declined parent can ask again.
- **PLAYER-5 · MVP · Add another guardian.** From the player card, a guardian can add a co-parent by email. An existing guardian is vouching for them, so no admin approval is needed. New emails get an added account and a setup email.
- **PLAYER-6 · MVP · RSVPs per player.**
  - On each event, guardians see one RSVP row per player: "Emma: Going · Liam: Not going".
  - **Exactly one RSVP per event and player.** When both parents answer, they update the same record instead of creating two. The latest answer counts and shows who gave it ("Answered by Maria"), so attendance never conflicts or double-counts.
  - Counts are about players: "12 of 15 players going".
  - Admins can answer for any player.
  - Coaches and staff (the team's admins) also RSVP for themselves on youth teams, and their answers are counted separately: "12 of 15 players going · 2 coaches". Parents answer only for their players (Q14).
- **PLAYER-7 · MVP · Notifications for guardians.** Event reminders and event changes go to the guardians of the affected players, as one notification per guardian naming their players: "Emma, Liam: Practice today at 6:00 PM".
- **PLAYER-8 · MVP · Who's who.** In chat and on the roster, each parent's name shows their players ("Maria R. · Emma #7"), so coaches and other parents know who's who.
- **PLAYER-9 · MVP · Kids on several teams.** A child on two teams is a separate player on each team. In "All my teams" (SCHED-2), each event shows which of a parent's players it's for.
- **PLAYER-10 · MVP · Kids' privacy.**
  - Players never get accounts.
  - A player's record holds only a name, jersey number, and position: no photos, birthdates, or contact details.
  - Photos shared in team chat may still show kids. They're visible only to the team's members, and anyone can report one.
- **PLAYER-11 · v1.1.** "Same answer for all my players" in one tap, and each player's season RSVP history for guardians and admins.

**Acceptance (MVP)**

- A youth coach pastes a roster of 15 players and their parents' emails, and every parent who finishes setup is linked to the right player.
- A parent who scans the team's QR code at practice can request their player, and is linked once an admin approves.
- A parent with two players on the team answers for each one separately, and the coach sees accurate player counts.

### 6.4 Invites and joining (INV)

- **INV-1 · MVP · Invite screen.**
  - Opens from the team menu, and right after creating a team.
  - Shows the team's invite link, a QR code, and the invite code (e.g. `K7XP-M2QR`).
  - Actions:
    - Copy link.
    - Share: the system share sheet (Web Share or copy on web).
    - Show QR full screen, to hold up at practice.
    - Email invites.
    - Add by email (admins).
- **INV-2 · MVP · Team invite link.**
  - Reusable.
  - Admins can set an expiration (never, 1 day, 7 days, or 30 days) and a maximum number of uses.
  - **Reset link** turns the old link off immediately.
  - Members see the link only when "Members can invite" is on.
- **INV-3 · MVP · QR code.** Encodes the invite link. Works with the phone's camera app or the in-app scanner.
- **INV-4 · MVP · Email invites.**
  - Type or paste up to 50 addresses at a time, separated by commas or new lines, plus an optional note.
  - Each address gets its own single-use link that expires in 14 days.
  - A list shows Pending, Joined, and Expired invites, with Resend and Revoke.
  - Requires a verified email. Daily limits apply per person and per team.
- **INV-5 · MVP · Joining.**
  1. Open a link. It opens the app if installed, otherwise the web app (WEB-4).
  2. Sign in or create an account if needed; the app continues automatically afterward.
  3. See the team preview: logo, name, sport, member count, "Invited by Alex".
  4. Tap **Join team**. On youth teams, answer "Who are you here for?" (PLAYER-3).
  5. Land in the team's chat, where "Sam joined" appears.

  People who are already members just go to the team.
- **INV-6 · MVP · Join without a link.** "Join a team" (on the welcome screen and in the team switcher) offers **Enter code** and **Scan QR code**, using the camera on phones and in the browser.
- **INV-7 · MVP · Web join page.**
  - `/join/<code>` (served by the web app under `/app`, WEB-4) shows the team preview, **Open in app**, App Store and Google Play badges, and **Continue in browser**.
  - The invite code is shown large, so people can type it in after installing the app.
- **INV-8 · MVP · Problems.**
  - Expired, revoked, used-up, or unknown codes get a plain explanation and "Ask a team admin for a new link."
  - Too many attempts: "Try again in a few minutes."

- **INV-9 · MVP · Standard links, no Dynamic Links.**
  - Invite links, QR codes, and email links are plain HTTPS addresses on Battleplan's own domain, such as `https://getbattleplan.app/join/K7XP-M2QR`.
  - With the app installed, iOS Universal Links and Android App Links open it directly. Otherwise the same address opens the web app.
  - **Battleplan doesn't use Firebase Dynamic Links**, which Google shut down on August 25, 2025. Firebase Hosting serves the domain and the Apple and Android verification files (ARCH §6.6).

**Acceptance (MVP)**

- On a phone with the app installed, tapping an invite link opens the app on the team preview.
- On a phone without the app, the same link opens the web app, where the person can join and chat right away.
- A new coach can create a team and get three people in, by link, QR, and email, in under 10 minutes in total.

### 6.5 Chat (CHAT)

- **CHAT-1 · MVP · Message list and paging.**
  - One chat per team, newest messages at the bottom.
  - **Paging.** The chat loads the newest 50 messages and keeps them live. Scrolling up loads 50 older messages at a time, so a chat with years of history opens as fast as a new one.
  - With unread messages, the chat opens at the first unread message and loads newer ones as you scroll down.
  - Date separators: Today, Yesterday, Mon Oct 6.
  - Consecutive messages from one person are grouped, with their name and photo shown once. On youth teams, a parent's name shows their players ("Maria R. · Emma #7", PLAYER-8).
  - Your messages sit on the right in the brand color; others' sit on the left on a neutral background.
  - Times appear on tap (phones), on hover (web), and at the start of each group.
- **CHAT-2 · MVP · Composer.**
  - Multi-line text up to 4,000 characters, with a counter near the limit, and a Send button.
  - The **+** menu: Photo library, Camera (phones), Create poll.
  - On web, Enter sends, Shift+Enter adds a line, and images can be pasted or dragged in.
- **CHAT-3 · MVP · Photos.**
  - Up to 10 per message, resized before upload, with progress shown in the bubble.
  - Shown as a grid. Tap for a full-screen viewer with pinch-zoom, swipe between photos, save/download, and share.
- **CHAT-4 · MVP · Delivery states.**
  - Each message shows sending, sent, or failed (tap to retry or delete).
  - Offline, text messages queue and send by themselves when the connection returns. Photos wait for a connection.
  - The send queue spaces messages at least 1 second apart, which keeps everyone under the posting limit (SAFE-5) without noticing.
- **CHAT-5 · MVP · Links.** URLs are tappable and open in the browser. On phones, phone numbers and email addresses are tappable too.
- **CHAT-6 · MVP · Reactions: 👍 Like · ❤️ Love · 👎 Dislike · 😂 LOL, plus 🔥 👏 🎉 💯 🙏 😮 😢 😡 ⚾ 🏀 ⚽ 🏆.**
  - Open the picker with a long-press (phones), the hover button, or a right-click (web). Double-tap a message to ❤️ it (phones).
  - **One reaction per person per message.** Picking another replaces yours; picking the same one removes it.
  - Chips under the bubble show each reaction with its count, and yours is highlighted. Tap them to see who reacted.
- **CHAT-7 · MVP · Message menu** (long-press or right-click).
  - React, Reply, Copy text, Delete (your own; admins can delete any), Report (other people's).
  - Edit and Pin come in v1.1.
- **CHAT-8 · MVP · Deleting messages.**
  - Always asks for confirmation.
  - When the author deletes, everyone sees "This message was deleted." When an admin deletes, everyone sees "Removed by a team admin."
  - The text, photos, and reactions are **erased from the server**, not just hidden, and the placeholder updates live on every device.
  - Replies that quoted it show "Original message was deleted".
  - Admin deletions are recorded in the audit log. Super admins can delete in any team.
  - Deleting a poll's message deletes the poll. Deleting an event card removes only the card; the event stays on the schedule.
- **CHAT-9 · MVP · Unread counts.**
  - **Team switcher.** Each team shows its unread message count (1–99, then "99+"). Muted teams show the count in gray.
  - **Chat tab.** A badge shows the current team's count. The switcher button in the header shows a dot when another team has unread messages.
  - **Inside the chat.** A "New messages" divider marks the first unread message, and a "↓ 12 new" button appears while scrolled up.
  - Messages count as read once they're on screen, and sending a message marks the chat read.
  - Read position syncs across devices: reading on the phone clears the count on the web.
- **CHAT-10 · MVP · System messages.** Small, centered lines for: joined, left, removed, made admin, team renamed.
- **CHAT-11 · MVP · Cards in chat.**
  - New polls appear as interactive poll cards (POLL-2).
  - New events appear as event cards when "Post to chat" is on. They show date, time, location, Going / Maybe / Not going buttons, and live counts. On youth teams, guardians answer for each of their players right on the card.
- **CHAT-12 · MVP · Blocked people.** Their messages are collapsed ("Message from someone you blocked · Show"), and they don't notify you.
- **CHAT-13 · MVP · Reply to a message.**
  - Reply from the message menu, or swipe right on a message (phones).
  - The composer shows the quoted message (the author and first line, or "Photo" or "Poll") with ✕ to cancel.
  - The sent message shows the quote above the reply. Tapping the quote jumps to the original, loading older messages if needed.
  - The server creates quotes from the original message, so they can't be faked.
  - If the original is deleted, the quote shows "Original message was deleted".
  - The person replied to gets a notification, even at "Important only", and a notification-center item (NOTIF-11).
- **CHAT-14 · v1.1 · @mentions.**
  - Typing @ suggests team members.
  - Mentions are highlighted and reach the person even at "Important only".
  - @everyone is for admins only.
- **CHAT-15 · Edit (MVP), pin and announce (v1.1).** Editing is built: people edit the text of their own messages, which then show "edited", and quotes in replies follow.
  - **Edit** your own messages; edited messages are marked "edited".
  - Admins can **pin** messages to a bar at the top.
  - Admins can send **announcements**, which notify everyone who hasn't turned the team off.
- **CHAT-16 · v1.1 · Files in chat.** Attach any document type; it's also saved to the Documents tab.
- **CHAT-17 · Later.**
  - Message search, which needs a search service or SQL (ARCH §12).
  - Link previews, GIFs, video, voice notes.
  - Typing indicators and read receipts.
  - Direct messages (Q5).

- **CHAT-18 · MVP · Chat look.** Team admins choose the chat's message color (the team color or any of the 13 palette colors) and background (plain, a subtle pattern, or a photo), which everyone on the team sees, with text kept readable (WCAG AA).

**Acceptance (MVP)**

- With cached data, a team's chat opens in under 0.5 seconds.
- A chat with 10,000+ messages opens as fast as a new one, and scrolling back stays smooth.
- A sent message appears on other open devices in about 1 second.
- Unread counts match on phone and web within a few seconds of reading.
- Tapping a reply's quote jumps to the original, even when it's hundreds of messages back.

### 6.6 Polls (POLL)

- **POLL-1 · MVP · Create a poll.**
  - From the chat **+** menu, if you're allowed.
  - Question (≤ 200 characters) and 2–10 options (≤ 80 characters each, reorderable).
  - Settings: Allow multiple answers (off), Anonymous voting (off), Close automatically at a date and time (optional).
  - The poll posts to chat as a card.
- **POLL-2 · MVP · Poll card.**
  - **Shows:** the question; each option with a live result bar, count, and percentage; checkmarks on your choices; the number of voters; and the status ("Closes Fri 5:00 PM" or "Closed").
  - **Voting:** tap an option to vote and tap again to remove the vote. You can change your vote until the poll closes.
  - Results are always visible.
- **POLL-3 · MVP · Who voted.**
  - On regular polls, tap an option to see who chose it, and see who hasn't voted yet.
  - On anonymous polls only counts are shown. Nobody in the app can see individual votes, admins included.
- **POLL-4 · MVP · Closing.**
  - The creator or an admin can close a poll early. Polls with a close time close by themselves.
  - Voters get a "Poll closed" notification with the result.
  - Closed polls can't be reopened.
- **POLL-5 · MVP · Deleting.** Deleting the poll's chat message deletes the poll. The creator or an admin can do this.
- **POLL-6 · v1.1.**
  - A list of the team's open and closed polls.
  - Reminders to people who haven't voted.
  - Members adding options.
  - Hiding results until the poll closes.

### 6.7 Schedule and RSVPs (SCHED)

- **SCHED-1 · MVP · Schedule tab.** Three views:
  - **Upcoming** (default): a list grouped by day. Each row has a date block, an event-type color and icon, the title ("vs. Eagles"), time, location, your RSVP (one per player on youth teams), and counts ("12 going · 3 maybe · 2 no"; on youth teams these count players).
  - **Past**: the same list, newest first.
  - **Calendar**: a month grid with a dot for each event; tap a day to see its events.
- **SCHED-2 · MVP · All my teams.**
  - A toggle that merges every team's events into one schedule, each labeled with its team's name and color. For parents, each event also names their player (PLAYER-9).
  - Built for parents with kids on several teams, and for players on several teams.
  - Filter by type: Games, Practices, Other.
- **SCHED-3 · MVP · Create an event.** The **+** button, if you're allowed.
  - **Type:** Game, Practice, Meeting, Social, or Other.
  - **Basics:**
    - Title. For games it fills itself in as "vs. Opponent" or "@ Opponent".
    - Date; start and end time, or all-day; time zone, defaulting to the team's.
    - Location (name and address, with Open in Maps).
    - Notes.
  - **Game fields:** opponent, home or away, arrival time ("Arrive 30 min early").
  - **RSVP:** on or off (default on), with an optional deadline.
  - **Reminders:** defaults from team settings. Choose any of 15 min, 1 h, 2 h, 1 day, 2 days, or 1 week before.
  - **Notify team** (default on) and **Post to chat** (default on).
  - **Repeat:** doesn't repeat (default), or:
    - **Daily**, every N days, for tournaments and camps.
    - **Weekly** on selected days, every N weeks, for practices.
    - **Ends** on a date or after a number of events, no more than 12 months out.
    - **Skip dates** for holidays and breaks: the form lists the dates it will create ("24 practices · Tue and Thu · Oct 13 – Dec 17"), and tapping one removes it.
    - Times stay the same in the event's time zone across daylight-saving changes.
    - Creating a series posts **one** event card to chat and sends **one** notification for the whole series ("New: Practice, Tue and Thu at 6:00 PM, Oct 13 – Dec 17").
  - **Duplicate:** from an event's details, anyone who can create events can tap **Duplicate**. It opens this form filled in from that event.
    - Everything is copied except the date: type, title, times, time zone, location, notes, game fields, RSVP settings, reminders, Notify team, and Post to chat.
    - The date is empty and gets focus, so it can't be saved as an accidental copy on the same day.
    - Nothing else carries over: no RSVPs, no Canceled state, and no link to the original's series. The copy is a new one-off event, unless Repeat is set on it.
    - Works on past and canceled events too, which covers "same game as last season".
- **SCHED-4 · MVP · Event details.**
  - Every field from creation.
  - Large **Going / Maybe / Not going** buttons, with an optional note ("Leaving at halftime"). On youth teams, guardians get one set per player (PLAYER-6).
  - Attendee lists grouped by Going, Maybe, Not going, and No response, with notes. On youth teams the lists show players and who answered for them.
  - Actions for everyone: Add to calendar, Share, Directions.
  - Admin actions: Edit, Cancel event, Delete, Set RSVP for a member or player.
  - **Duplicate**, for anyone who can create events (SCHED-3).
  - Events in a series show "Repeats weekly on Tue and Thu until Dec 17".
- **SCHED-5 · MVP · RSVPs.**
  - One tap, instant, and it works offline.
  - Change your answer any time before the deadline; after it, only admins can change answers.
  - The requirement was Going / Not going. **Maybe** is a recommended addition: on by default, and each team can turn it off (TEAM-5).
  - Not answering shows as "No response".
  - On youth teams, RSVPs are per player and answered by guardians (PLAYER-6).
- **SCHED-6 · MVP · Editing.**
  - Changing the date, time, or location notifies everyone except people who said Not going ("Practice moved to 6:30 PM").
  - For repeating events, admins choose "This event" or "This and following events".
    - **This event** changes only that event. It stays in the series, and later series edits leave its changed fields alone.
    - **This and following** applies the change to that event and every later one, including the repeat days and end date. Extending the end date is how a season that runs long gets more practices.
    - Events that still fall on a repeat day keep their RSVPs. Changing the days or shortening the series removes events, and their RSVPs go with them. The confirmation says so: "Removes 4 practices; 9 people had answered."
    - Past events are never changed by a series edit.
    - A series edit notifies the team once, not once per event.
- **SCHED-7 · MVP · Cancel vs. delete.**
  - **Cancel** keeps the event on the schedule, struck through with a "Canceled" badge, closes RSVPs, and notifies the team.
  - **Delete** removes the event without notifying anyone. Its confirmation suggests canceling instead if the event is within 7 days.
  - For repeating events, both ask "This event" or "This and following events". Canceling or deleting the rest of a series notifies the team once.
- **SCHED-8 · MVP · Reminders.** A push at each reminder time to people who said Going or Maybe or haven't answered, but not Not going: "Reminder: Practice today at 6:00 PM · Riverside Park". On youth teams, reminders go to those players' guardians (PLAYER-7).
- **SCHED-9 · MVP · Time zones.**
  - Times show in the viewer's local time.
  - If the event's time zone is different, both appear: "6:00 PM CDT · 7:00 PM your time".
  - All-day events never shift to another day.
- **SCHED-10 · MVP · Add to calendar.** The native calendar sheet on iOS and Android; an .ics download on web.
- **SCHED-11 · v1.1 · Calendar subscription.**
  - A private link that keeps Google, Apple, or Outlook Calendar in sync, for one team or all of a person's teams.
  - Regenerating the link turns off the old one.
- **SCHED-12 · v1.1 · Follow-ups.**
  - Admins can "Nudge" people who haven't answered; it also happens automatically 24 h before the RSVP deadline.
  - Guest counts (+1, +2).
- **SCHED-13 · Later.**
  - Attendance tracking: who actually came.
  - RSVP and attendance reports with CSV export.
  - Game scores.
  - Volunteer and snack sign-ups.
  - Carpools.
  - Season availability surveys.

**Acceptance (MVP)**

- A coach can create a weekly practice through the end of the season in under a minute, skipping holiday dates, and the team gets one chat card and one notification for it.
- A coach can duplicate last week's game, change the date and opponent, and save it in under 30 seconds.
- Canceling one practice in a series leaves the others unchanged; moving the rest of a series from Tue/Thu to Mon/Wed removes the remaining Tue/Thu practices with their RSVPs and leaves past practices untouched.
- An RSVP made on a phone shows on the web within a few seconds.
- A canceled event is clearly marked everywhere and notifies everyone who hadn't said Not going.

### 6.8 Documents (DOC)

- **DOC-1 · MVP · Documents tab.**
  - Pinned items first, then everything else.
  - Each row shows a type icon or image thumbnail, the name, size, who added it, and when.
  - Sort by Recent or Name, and filter by typing part of a name.
  - Empty state: "Share schedules, forms, and playbooks with your team."
- **DOC-2 · MVP · Upload files** (if you're allowed).
  - PDF, images, Word, Excel, PowerPoint, text, and CSV, up to 10 MB each (STORE-1).
  - Rename before uploading, add an optional description, and see progress with Cancel.
  - If the team's storage is full, uploading is disabled with the message from STORE-4.
- **DOC-3 · MVP · Add links.** A name and a URL, such as a Google Drive folder, a sign-up form, or a league website. Links open in the browser.
- **DOC-4 · MVP · Open.**
  - PDFs and images open in an in-app viewer.
  - Other types open in the phone's default app, or download in the browser.
  - Share and Download work everywhere.
- **DOC-5 · MVP · Manage.**
  - The uploader and admins can rename, edit the description, and delete (with confirmation).
  - Admins can pin and unpin.
- **DOC-6 · MVP · Notify.** Uploading sends a "New document: Fall roster.pdf" notification, following each member's notification level. The uploader can switch "Notify team" off.
- **DOC-7 · v1.1.** Folders (one level deep), and a Photos section that collects every photo shared in the team's chat.
- **DOC-8 · Later.** Version history, comments, and e-signatures for waivers.

### 6.9 Notifications (NOTIF)

- **NOTIF-1 · MVP · Asking permission.**
  - Ask after the person joins or creates their first team, never on first launch.
  - Show a short explainer first: "Get notified about messages, schedule changes, and reminders."
  - If they decline, Settings → Notifications explains how to turn notifications on.
- **NOTIF-2 · MVP · What sends a notification.**

  | Activity | Who gets it | Push at "Important only"? | In notification center | Release |
  |---|---|:-:|:-:|---|
  | New message or photo | Everyone except the sender | No | — | MVP |
  | Reply to your message | The person replied to | **Yes** | ✓ | MVP |
  | New poll | Everyone except the creator | No | ✓ | MVP |
  | Poll closed | Voters | No | ✓ | MVP |
  | New event | Everyone | No | ✓ | MVP |
  | Event changed or canceled | Everyone except Not going\* | **Yes** | ✓ | MVP |
  | Event reminder | Going, Maybe, No response\* | **Yes** | ✓ | MVP |
  | New document | Everyone except the uploader | No | ✓ | MVP |
  | Added to a team; made an admin | That person | **Yes** | ✓ | MVP |
  | Guardian request (youth teams) | Team admins | **Yes** | ✓ | MVP |
  | Guardian request approved | The parent | **Yes** | ✓ | MVP |
  | Content reported | Team admins | **Yes** | ✓ | MVP |
  | Storage 90% full, or full (STORE-3, STORE-4) | Team admins | **Yes** | ✓ | MVP |
  | @mention; announcement | The person mentioned; everyone | **Yes** | ✓ | v1.1 |
  | RSVP nudge | People who haven't answered\* | **Yes** | ✓ | v1.1 |

  \* On youth teams, these go to the guardians of the matching players (PLAYER-7).

  Plain chat messages don't appear in the notification center; unread counts cover them (CHAT-9).
- **NOTIF-3 · MVP · Notification settings for each team.**
  - Set them from the team menu ("Notifications for this team") or from Settings → Notifications. They sync across your devices.
  - **Level:** All activity (default), Important only, or Off.
  - **Mute** for 1 hour, 8 hours, 1 week, or until unmuted. Muted teams show a muted icon, and their unread counts turn gray.
  - These settings control pushes only. Notification-center items and unread counts still appear, so nothing is lost.
- **NOTIF-4 · MVP · Global switches.** Settings → Notifications has switches for Messages, Replies, Polls, New events, Event changes, Reminders, and Documents. They apply to every team.
- **NOTIF-5 · MVP · Wording.** The title is always the team name. Examples:
  - "Alex: Field 3 is open"
  - "Alex replied to you: Sounds good"
  - "Alex sent a photo"
  - "Alex created a poll: Pizza after the game?"
  - "New game: vs. Eagles · Sat Oct 18, 10:00 AM"
  - "Emma, Liam: Practice today at 6:00 PM" (youth teams)
- **NOTIF-6 · MVP · Tap to open.** Tapping a notification opens the exact message, poll, event, or document, switching teams if needed.
- **NOTIF-7 · MVP · While the app is open.** A small in-app banner appears instead of a system notification. Nothing appears if you're already in that team's chat.
- **NOTIF-8 · MVP · Grouping.** The phone's notification list groups Battleplan notifications by team.
- **NOTIF-9 · MVP · Web.**
  - Browser notifications work after permission is granted, even with the tab closed.
  - On iPhone and iPad they work only after "Add to Home Screen". iOS Safari users see a tip saying so, with a link to the App Store.
- **NOTIF-10 · MVP · Multiple devices.** Every signed-in device gets notifications. Signing out stops them on that device.
- **NOTIF-11 · MVP · Notification center.**
  - A **bell** in the header, on every platform, with a count of unread items (up to 99+).
  - It opens a list of activity **across all your teams**, newest first, loading 30 at a time. Each item shows the team, an icon, a one-line summary, and the time. Unread items are highlighted.
  - Tapping an item opens the exact place, switching teams if needed, and marks it read. "Mark all as read" clears the rest.
  - It lists everything marked "In notification center" in NOTIF-2. Plain chat messages aren't listed.
  - Items appear even when pushes are muted or off for that team. Activity from people you blocked never appears.
  - Read state syncs across devices. Items older than 90 days are removed automatically.
- **NOTIF-12 · v1.1.**
  - App icon badge: the number of unread notification-center items.
  - Mention notifications.
  - A "Hide message text in notifications" option.
- **NOTIF-13 · Later.**
  - Quiet hours.
  - Email notifications or a daily digest for members without the app.
  - SMS, which costs money per message.

### 6.10 Profile and settings (SET)

- **SET-1 · MVP · Profile.** Photo (cropped to a circle) and display name, used on every team. Email is shown read-only.
- **SET-2 · MVP · Appearance.** System (default), Light, or Dark. The change applies instantly, is remembered on the device, and syncs to the account.
- **SET-3 · MVP · Notifications.** Global switches (NOTIF-4) and each team's level (NOTIF-3).
- **SET-4 · MVP · Sign-in methods** (AUTH-8).
- **SET-5 · MVP · Blocked people.** View the list and unblock.
- **SET-6 · MVP · About and account.**
  - App version, Terms, Privacy Policy, open-source licenses.
  - Contact support.
  - Sign out; Delete account (AUTH-10).

### 6.11 God admin panel (ADMIN)

This is for platform operators (super admins) to manage every team and user.

**Access and layout**

- Only super admins see it: it's in their profile menu, at `/admin`.
- It's designed for a desktop browser but works on phones, where tables become lists.
- It's loaded separately, so regular users never download it.

**Requirements**

- **ADMIN-1 · MVP · Dashboard.** Totals for:
  - users and teams;
  - new teams this week;
  - active teams (a message in the last 7 days);
  - messages in the last 7 days;
  - total storage;
  - open reports.
- **ADMIN-2 · MVP · Teams.**
  - Search by name.
  - Sort by created date, last activity, members, or storage.
  - Filter by Active, Archived, or Suspended.
  - Columns: name, sport, owner, members, last activity, storage, status.
- **ADMIN-3 · MVP · Team detail.**
  - **Edit:** the team's profile and settings.
  - **People:** change roles, remove members, add by email, transfer ownership, manage players and guardians.
  - **Content:** revoke invite links; review recent messages (delete any), events, and documents.
  - **Storage:** see usage, open the team's Media, and raise or lower its limit (STORE-6).
  - **Actions:**
    - **View team**: opens its tabs without joining, read-only plus moderation, with a "Viewing as super admin" banner, and recorded in the audit log.
    - Archive or Restore.
    - Suspend or Unsuspend (members see "This team has been suspended").
    - Delete (type the name to confirm).
- **ADMIN-4 · MVP · Users.**
  - **Find:** search by name or email; filter by Added (not joined yet), Active, Disabled, or Super admin.
  - **Details:** profile, status, sign-in methods, teams and roles, joined date, last active.
  - **Actions:**
    - Create a user (with an optional team and role).
    - Edit name; add to a team.
    - Send a password reset; sign out everywhere.
    - Disable or enable; delete.
    - Grant or revoke super admin. This needs confirmation, and the last super admin can't be removed.
- **ADMIN-5 · MVP · Reports.**
  - Open reports from every team, with a content preview, the reporter, and the team.
  - Actions: delete the content, remove the person from the team, disable the person, suspend the team, or dismiss.
  - Each resolution saves a note.
- **ADMIN-6 · MVP · Audit log.**
  - Records every admin or destructive action: who, what, which team, when, and before/after values.
  - Filter by person, action, team, or date.
  - Read-only, kept for 1 year.
- **ADMIN-7 · MVP · Platform settings.**
  - Whether anyone can create teams, and the teams-per-person-per-day limit.
  - Default storage quota and maximum upload size.
  - Support email.
  - A banner announcement for all users, with text, severity, and an end date.
- **ADMIN-8 · MVP · Safeguards.**
  - Destructive actions require confirmation.
  - Every admin action writes an audit entry.
  - Nobody can set or see another person's password. Admins can only send setup and password-reset emails (AUTH-6).
  - The Privacy Policy states that super admins can access team content for moderation and support (LEGAL-1).

### 6.12 Safety and moderation (SAFE)

The App Store requires these for apps with user-generated content (guideline 1.2), and they matter more once anyone can create a team.

- **SAFE-1 · MVP · Report.**
  - Report a message, document, or person.
  - Reasons: Spam, Harassment or bullying, Inappropriate content, or Other, plus optional details.
  - The report goes to the team's admins (Team menu → Reports) and to the super-admin queue.
  - The reporter gets a confirmation. The reported person is never told who reported them.
- **SAFE-2 · MVP · Block.**
  - Hides that person's messages from you (collapsed) and stops notifications from them, in every team.
  - They aren't told.
  - Blocking doesn't remove anyone from a team.
- **SAFE-3 · MVP · Terms.** Everyone accepts the Terms of Use at sign-up, including zero tolerance for objectionable content and abusive behavior.
- **SAFE-4 · MVP · Acting on reports.**
  - Team admins act in their own team: delete content, remove members.
  - Super admins act anywhere: disable accounts, suspend teams.
  - Goal: act on every report within 24 hours.
- **SAFE-5 · MVP · Rate limits and abuse controls.**
  - **Limits**, defined in one place (full table in ARCH §6.9):

    | Action | Limit |
    |---|---|
    | Sending messages | 1 per second per person per team |
    | Creating teams | 5 per person per day |
    | Email invites | 50 per person and 200 per team per day |
    | Adding people or players by email | 200 per team per day |
    | Invite code attempts | 20 per person per hour |
    | Guardian requests | 10 per person per day |
    | Reports | 20 per person per day |

  - Real people shouldn't notice them. The app spaces messages automatically, and anyone who hits a limit sees "Slow down, try again in a minute" without losing what they typed.
  - A verified email is required to create teams, send email invites, or add people by email.
  - App Check blocks traffic that doesn't come from the real apps.
  - Every team has a storage limit (STORE-1).
  - Super admins can disable people and suspend teams (ADMIN-3, ADMIN-4).
- **SAFE-6 · MVP · Adults only.**
  - Accounts are for adults 18 and older (AUTH-5, Terms of Use).
  - Youth players never sign in or get accounts, and adults enter only minimal details about them (PLAYER-10).
- **SAFE-7 · Later.** An optional per-team profanity filter. Do it sooner if App Review asks.

### 6.13 Privacy and legal (LEGAL)

- **LEGAL-1 · MVP · Policies.**
  - Privacy Policy at `/privacy` and Terms of Use at `/terms`, on the website (WEB-2).
  - Linked from sign-in, Settings, the store listings, and the Apple developer settings.
  - The Privacy Policy covers:
    - what we collect: name, email, photo, messages, files, device tokens, usage analytics, crash reports, and, on youth teams, the player details adults enter (name, jersey number, position);
    - that super admins can access content for moderation and support;
    - how long data is kept;
    - how to delete it.
  - The Terms of Use require account holders to be 18 or older.
- **LEGAL-2 · MVP · No tracking.**
  - No ads, no selling data, no cross-app tracking, so no App Tracking Transparency prompt.
  - Analytics runs without advertising IDs.
- **LEGAL-3 · MVP · Deletion.** In-app account deletion (AUTH-10), plus a public `/delete-account` page explaining how to request deletion (required by Google Play).
- **LEGAL-4 · MVP · Store disclosures.** The App Store privacy labels and the Google Play Data safety form match LEGAL-1.
- **LEGAL-5 · Removed.** Facebook's data-deletion URL moved to the ROADMAP backlog with Facebook sign-in (Q16).
- **LEGAL-6 · MVP · Retention.**
  - Content stays until its author, an admin, or the team's deletion removes it.
  - Deleted content is erased from the database immediately and from backups within 7 days.

### 6.14 Free for everyone, and team storage (STORE)

**Everything is free, with no ads.** Every team gets every feature. Ads may come later, once enough teams use Battleplan to justify the work; any ads plan has to respect children's privacy rules, because youth teams' guardians use the app (ROADMAP "Ads, later"). [PLANS.md](PLANS.md) summarizes this.

What does cost money as teams grow is storage, so each team has a limit, and admins can see and free their space.

**Requirements**

- **STORE-1 · MVP · A storage limit per team.**
  - Each team can store **500 MB**: chat photos, documents, the team logo, and the chat background all count (ARCH §6.8).
  - A single file can be at most **10 MB** (chat photos are resized well under that before upload).
- **STORE-2 · MVP · Storage used.** Team settings shows "212 MB of 500 MB used" with a meter, for the team's admins.
- **STORE-3 · MVP · Nearly full.** At **90%**, the meter turns amber, the team's admins see a warning at the top of the team ("Storage is 90% full. Free up space in Media."), and they get a notification (NOTIF-2).
- **STORE-4 · MVP · Full.**
  - New uploads (chat photos, documents, the team logo, a chat background), attachments, and **scheduling new events** are disabled until storage is freed up.
  - Everyone on the team sees: "Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up." Admins also get a notification.
  - Nothing else turns off: text messages, replies, reactions, polls, RSVPs, and existing events keep working. Nothing is ever deleted automatically.
- **STORE-5 · MVP · Media (admins).**
  - Team menu → **Media** lists every photo, attachment, document, the team logo, and the chat background, largest first, with a preview, size, who added it, and when.
  - Admins delete items to free space, after confirming. Deleting a chat photo removes it from its message, and a message left with no text or photos reads "Photo removed by a team admin"; deleting the logo or background resets it.
- **STORE-6 · MVP · Raising a team's limit.** A super admin can raise (or lower) one team's limit, from the admin panel (ADMIN-3), and until that exists from Team settings while signed in as a super admin. The option isn't announced or advertised anywhere.
- **STORE-7 · Later · Ads.** See ROADMAP "Ads, later".

**Acceptance (MVP)**

- A team at 90% sees the warning and its admins are notified once.
- A full team can't upload or attach, even by calling the database directly, and still chats.
- Deleting photos in Media frees space within seconds, and uploads work again.
- A super admin raises one team to 2 GB and only that team can store more.

---

## 7. Design system and UI

### 7.1 Brand

- **Name:** Battleplan.
- **Logo:** to be designed (Q9). Until then, a simple placeholder mark plus the wordmark. The app icon has to read clearly at small sizes in both light and dark mode.
- **Primary color:** proposed deep blue `#2F5BEA` (Q9).
- **Team colors** personalize each team without competing with the brand. They're used only for the team's logo or initials badge, the switcher, and calendar dots in the all-teams view. Chat bubbles always use the brand color.

### 7.2 Look and feel

Modern and clean:

- generous whitespace;
- flat tonal surfaces instead of borders and heavy shadows;
- rounded corners;
- one accent color;
- a clear type hierarchy;
- quick, subtle motion.

The content carries the visual weight: messages, photos, and event cards. The target feel is closer to iMessage and Apple Calendar than to a dense sports-admin tool.

### 7.3 Design tokens

| Token | Values |
|---|---|
| **Color** | Material 3 light and dark schemes generated from the brand color, then hand-tuned. Semantic colors: Going (green), Maybe (amber), Not going (red), and one color per event type. Every color is contrast-checked in both themes. |
| **Type** | Inter, bundled with the app. Sizes 28 / 22 / 18 / 16 / 14 / 12 (headline, title, subtitle, body, secondary, label). Layouts survive system text scaling up to 200%. |
| **Spacing** | 4-point grid: 4, 8, 12, 16, 24, 32, 48. Side padding is 16 on phones and 24 on wide screens. |
| **Corners** | 8 for chips, 12 for cards and inputs, 18 for chat bubbles, fully round for avatars and pills |
| **Elevation** | Tonal surface levels. Shadows only on floating things: menus, sheets, the + button. |
| **Icons** | Material Symbols Rounded, the same set on every platform |
| **Motion** | 150–250 ms with standard easing. Respect the system "reduce motion" setting. |

### 7.4 Light and dark mode

- Dark mode uses near-black tonal surfaces (not pure black), with accents lightened for contrast. Photos are never dimmed.
- Both themes meet **WCAG AA contrast** (4.5:1 for body text).
- Every key screen has golden tests in both themes.

### 7.5 Components

Build these once in `core/` and reuse them everywhere:

- Team header with switcher
- Navigation bar and rail
- Avatar (photo, or initials on a consistent color)
- Message bubble
- Reaction chips and picker
- Poll card
- Event card and event row
- RSVP button group
- Document row
- Member row
- Empty state (icon, one sentence, one action)
- Skeleton loaders (no spinners for lists)
- Snackbar
- Confirm dialog (destructive actions in red, with the verb on the button: "Delete message")
- Bottom sheet on phones, dialog or popover on wide screens

### 7.6 Accessibility

- Screen-reader labels on every icon button and image. Photos read as "Photo from Alex".
- Logical focus order, a visible focus ring, and full keyboard navigation on web.
- Touch targets at least 48 × 48.
- Color is never the only signal: RSVP states also use icons and words.
- Test with VoiceOver and TalkBack before launch.

### 7.7 Writing

- Plain, friendly, and short, in sentence case.
- Buttons are verbs: "Join team", "Send invites".
- Error messages say what happened and what to do next.
- All text lives in ARB files (English at launch), so other languages can be added later.

---

## 8. Non-functional and engineering requirements

### 8.1 Quality targets

| Area | Requirement |
|---|---|
| **Speed** | Signed-in launch to content in **< 2 s** on a mid-range phone. Web first load **< 4 s** on broadband; repeat visits **< 2 s**. A cached chat opens in **< 0.5 s**. Scrolling stays at 60 fps with photos. Messages reach open devices in **~1 s**; push notifications in **≤ 5 s** typically. |
| **Reliability** | Nothing is lost on flaky connections (offline queue). Server functions are safe to retry. Daily backups are kept for 7 days. |
| **Security** | Deny-by-default rules, tested for every collection and role. App Check enforced. Secrets in Secret Manager. HTTPS only. No message content or personal data in logs or analytics. |
| **Team isolation** | A member of one team can **never** read or change another team's data. Covered by automated rules tests. |
| **Scale** | Meets the ARCH §2 targets without design changes. |
| **Cost** | Stays within the ARCH §10.1 model, with budget alerts. Every query follows the cost rules (ENG-5). |
| **Accessibility** | §7.6 |
| **Supported versions** | iOS 15+, Android 8.0+, latest two versions of Chrome, Edge, Firefox, and Safari |
| **Maintainability** | Lints and formatting enforced; tests run in CI; ≥ 80% coverage of the domain and data layers. The engineering rules below are enforced in CI and code review. |

### 8.2 Engineering rules (ENG)

These are requirements on how Battleplan is built. Pull requests that break them don't merge.

- **ENG-1 · Firebase only in the data layer.**
  - Firebase calls (Firestore, Auth, Storage, Functions, Messaging) live only in each feature's repository implementations and in app bootstrap.
  - Screens, widgets, and controllers never import Firebase. A CI check fails the build if they do (ARCH §5.2).
- **ENG-2 · Clear layers, no spaghetti.**
  - Every feature has the same layers: presentation → application → domain ← data.
  - Each Firestore collection has exactly one owning repository. Other features go through it.
  - Features use each other only through domain models and interfaces.
  - There's one way to do each thing (routing, state, errors, logging, links). A second way needs a decision-log entry (ARCH §5.2).
- **ENG-3 · SQL-shaped data model.**
  - Top-level Firestore collections only, one per future SQL table; no subcollections.
  - Relationships are explicit ID fields. One-per-pair records use composite IDs, such as `rsvps/{eventId}_{participantId}`.
  - Only small, bounded lists owned by a document are embedded in it (ARCH §6.2, §12).
- **ENG-4 · Predictable server logic.**
  - Thin entry points call domain services, and each service owns its collections.
  - Callables do their own follow-up work. Triggers only react to direct client writes, and every trigger is listed in the trigger map.
  - All push notifications and notification-center items go through one pipeline (ARCH §6.4, §6.5).
- **ENG-5 · Firestore cost rules.** Every query follows the cost-efficiency rules and stays within its screen's read budget (ARCH §10.2):
  - every query has a limit;
  - pages use cursors;
  - listeners only for what's on screen;
  - no per-row lookups;
  - counts are capped;
  - TTL cleanup and index exemptions.
- **ENG-6 · Standard links only.**
  - Invites, QR codes, and email links are HTTPS URLs on Battleplan's domain, opened by iOS Universal Links and Android App Links, with the web app as the fallback.
  - **No Firebase Dynamic Links** (shut down August 25, 2025).
  - Firebase Hosting serves the domain and the Apple and Android verification files (ARCH §6.6).
- **ENG-7 · Tests with every rule and server change.**
  - Security-rule changes ship with rules tests, including cross-team isolation and one RSVP per event and player.
  - Functions changes ship with tests, including every trigger's early-exit conditions (ARCH §9).
- **ENG-8 · One source for shared constants.** Enums, limits, and collection names are defined once in `shared/constants.json` and generated for Dart and TypeScript (ARCH §4).
- **ENG-9 · Decisions are written down.** New libraries or patterns get a decision-log entry (ARCH §14), and data-model changes update ARCH §6.2 in the same PR.

---

## 9. Delivery plan

Every milestone ends with its features working on **iOS, Android, and web**, and with rules tests updated.

### M0 · Foundation

- [ ] Create the Firebase projects on the free plan (done 2026-10-10: dev `battleplan-dev-ecce4`, prod `battleplan-prod`) and build against the Emulator Suite. Paid plans and purchases wait until a phase needs them ([TODO.md](../TODO.md)): dev moves to Blaze when we first deploy Functions or Storage, and prod gets Blaze and its database, in its permanent region (ARCH §6.10), for the team beta.
- [x] `flutter create` with the org ID; dev and prod flavors. `flutterfire configure` for each waits on `firebase login`.
- [x] Repo layout, lints, CI, and VS Code launch configs.
- [x] Emulator Suite with seed data: several teams, with some people on more than one.
- [x] Design tokens, light and dark themes, core components.
- [x] The three-tab shell with placeholder screens, and go_router with its guards.
- [x] Remote Config minimum-version check, Crashlytics, Analytics, web error reporting (wired; live once the cloud config exists).
- [x] The import-boundary check in CI (ENG-1), Firestore index exemptions, and TTL policies (ARCH §6.2).
- [ ] **Spikes**, each with a short written result ([docs/spikes/M0.md](spikes/M0.md); 4 and 5 done):
  1. The sign-in matrix: provider × platform × new / existing / admin-added account.
  2. Universal Links, App Links, and email-link sign-in (`linkDomain`) on our Hosting domain, with no Dynamic Links.
  3. Web push on Chrome, macOS Safari, and an iPhone home-screen web app.
  4. A WASM web build with our plugins.
  5. Security rules on the flat collections: membership checks from a query's `groupId` filter, one RSVP per event and player, and the message rate limit.

  Apple sign-in and iOS Universal Links need the paid Apple Developer membership. They join the matrix when it's bought, just before the team beta.

**Done when:** the empty app, with tabs and a theme switch, runs on iOS (Simulator or your iPhone), an Android phone, and Chrome, and every PR gets a web preview link.

### M1 · Accounts

- [ ] All four sign-in options, email verification, and password reset.
- [ ] First-run setup with the 18+ confirmation and Terms; `ensureUserProfile`.
- [ ] Account linking (AUTH-7, AUTH-8), account deletion, disabled accounts.
- [ ] The super-admin bootstrap script.
- [ ] Rules and tests for `users`.

**Done when:** the M0 sign-in matrix passes on all three platforms. Apple sign-in is verified once the Apple Developer membership is active, before the team beta.

### M2 · Teams and invites

- [ ] Create team, team switcher, welcome screen.
- [ ] Roster screen, roles, team settings; transfer, leave, archive, delete.
- [ ] Add by email, with account creation and setup emails. Set up the email provider and sending domain.
- [ ] Invite link, QR, and code; email invites; the `/join` page; `getInvitePreview` and `redeemInvite`; Universal Links and App Links.
- [ ] Youth teams: team type, players, pasted rosters, guardian linking and requests, parent labels (PLAYER-1 to PLAYER-5, PLAYER-8).
- [ ] Storage quota accounting.
- [ ] Rules and tests, including **cross-team isolation**.

**Done when:** a new coach can create a team and get three people in by link, QR, and email; a person on two teams can switch between them; and on a youth team, a pasted roster links each parent to the right player.

### M3 · Chat

- [x] Message list with paging, composer, photos and viewer, reactions.
- [x] Replies, delete (through a Function), unread counts, system messages, links.
- [x] Report, block, offline states.

**Done when:** the CHAT acceptance criteria pass.

### Free for everyone and team storage · after M4

- [x] Remove the paid tier; its features are free for everyone (edit messages, 16 reactions, chat look).
- [x] 500 MB per team and 10 MB files; the 90% warning; full blocks uploads, attachments, and new events (STORE-1 to STORE-4).
- [x] Media for admins and the unannounced super-admin limit (STORE-5, STORE-6).

**Done when:** the STORE acceptance criteria pass.

### M4 · Notifications

- [x] Device registration and the fan-out Function.
- [x] Per-team level and mute; global switches.
- [x] Tap-to-open and in-app banners.
- [x] The notification center (NOTIF-11), on the same server pipeline as push.
- [x] Web push and the iOS Safari tip.

From here on, each feature ships with its own notifications.

### M5 · Polls

- [ ] POLL-1 to POLL-5.

### M6 · Schedule

- [ ] Events with types and game fields.
- [ ] RSVPs, including Maybe and admins answering for members; per-player RSVPs and guardian notifications on youth teams (PLAYER-6, PLAYER-7, PLAYER-9).
- [ ] Upcoming, Past, and Calendar views; All my teams.
- [ ] Repeating events (daily and weekly, skip dates, this-and-following edits, cancel, and delete) and Duplicate.
- [ ] Reminders; event cards in chat.
- [ ] Add to calendar; time zones.

**Done when:** the SCHED and PLAYER acceptance criteria pass.

### M7 · Documents

- [ ] DOC-1 to DOC-6, including the storage-full message.

### M8 · God admin panel

- [ ] ADMIN-1 to ADMIN-8.

### M9 · Hardening and launch

- [ ] Enforce App Check and review rules-test coverage.
- [ ] Accessibility, performance (§8), and golden-test passes.
- [ ] The website at `getbattleplan.app` with the legal and support pages, and the web app moved to `/app` (§4.3); store listings, privacy forms.
- [ ] An App Review demo account with a seeded team.
- [ ] Beta with our team: TestFlight (iOS), Firebase App Distribution (Android), and the web; a bug bash; the production deploy.
- [ ] Google Play: open the Play Console account (a personal one, Q13) and run the 14-day closed test with 12+ testers before the public Android release.
- [ ] Move our team over (below), then open sign-up to other teams.

### Moving our team over

1. Create our team and paste in the roster (TEAM-7; on a youth team, players with their parents' emails, PLAYER-1).
2. Recreate upcoming events, using repeating events for practices.
3. Post the invite link in the old GroupMe and show the QR code at practice.
4. Run both apps for about two weeks, then announce the switch.
5. GroupMe and TeamReach history isn't imported (§11).

### v1.1 backlog, in priority order

1. @mentions, pins, announcements (CHAT-14, CHAT-15)
2. Roster details and contact sharing (TEAM-10); "Same answer for all my players" and RSVP history (PLAYER-11)
3. Calendar subscription (SCHED-11)
4. RSVP nudges and guest counts (SCHED-12)
5. Team-specific link previews for invites (ARCH §6.6)
6. Folders and the chat photo gallery (DOC-7)
7. Announcement-only mode (TEAM-12), polls list (POLL-6)
8. App icon badges, hidden notification text (NOTIF-12), files in chat (CHAT-16)
9. Persistent team list on very wide screens (§5.5)
10. Attendance history and CSV exports of RSVPs and the roster for admins
11. A branded invite page with the team's logo and color (`/join`)

---

## 10. Launch checklist

When to buy or set up each item is in [TODO.md](../TODO.md). Purchases happen just in time, not up front.

**Accounts and fees**

- [ ] Apple Developer Program, $99/year, as an individual (Q13). The App Store shows your legal name as the seller; no D-U-N-S number or company website is needed.
- [ ] Google Play Console, $25 once, as a personal account (Q13). Google Play shows your legal name, and production access needs a 14-day closed test with 12+ testers.
- [x] A domain name: `getbattleplan.app` (Q8).
- [ ] A Meta developer app and an email provider account.

**Platform setup**

- [ ] APNs key uploaded to Firebase.
- [ ] Android SHA-1 and SHA-256 fingerprints (debug, upload, and Play App Signing) in Firebase, for Google sign-in and App Links.
- [ ] Sign in with Apple capability, and a Services ID for Android and web.
- [ ] reCAPTCHA Enterprise key and web push VAPID key.
- [ ] `apple-app-site-association` and `assetlinks.json` served from Hosting; the Associated Domains entitlement; Android intent filters with `autoVerify`.
- [ ] Sending domain with SPF, DKIM, and DMARC, registered with Apple's private email relay. Firebase Auth email templates branded.

**Backend**

- [ ] App Check enforced; rules and indexes deployed.
- [ ] Budget alerts and daily backups on.
- [ ] Remote Config minimum version set.
- [ ] First super admin bootstrapped.

**Stores**

- [ ] App icons, splash screens, and screenshots for each required device size.
- [ ] Descriptions, keywords, support URL, privacy URL.
- [ ] Age-rating questionnaires (chat and user-generated content).
- [ ] App Review notes: a demo account with a seeded team, and an explanation that teams are invite-only.
- [ ] Privacy labels (Apple) and Data safety form (Google).
- [ ] EU trader status declared in both stores.

**Legal**

- [ ] Privacy Policy, Terms of Use, `/delete-account` page, support email.

---

## 11. Out of scope for v1

Not in v1; some may come later:

- Direct messages (Q5)
- Sub-chats or channels within a team
- Organizations and leagues
- A public team directory
- Message search
- Link previews in chat, GIFs, video, voice notes
- Voice and video calls
- SMS
- Email digests
- Typing indicators and read receipts
- Attendance tracking, stats, and scores
- Payments and team dues
- Volunteer and snack sign-ups
- Carpools
- Importing GroupMe or TeamReach history
- Languages other than English
- Native desktop apps (the web app covers desktop)
- Widgets and watch apps
- Cloud SQL (ARCH §12)

---

## 12. Open questions

Each question has a default. The build follows the default until someone decides otherwise.

| # | Question | Default until decided |
|---|---|---|
| Q1 | ~~Should the app say "Team" or "Group"?~~ **Decided 2026-10-11:** "Team". | — |
| Q2 | ~~Will youth players use Battleplan?~~ **Decided:** no. Accounts are for adults (18+), and parents and guardians answer for youth players (§6.3). | — |
| Q3 | ~~Who can create teams?~~ **Decided 2026-10-11:** anyone with a verified email; super admins can turn it off. | — |
| Q4 | ~~How will the platform be paid for once there are hundreds of teams?~~ **Decided 2026-10-12:** everything is free with no ads for now; ads may come once adoption justifies them (ROADMAP "Ads, later"). Each team has a 500 MB storage limit that a super admin can raise (§6.14). A paid plan was planned on 2026-10-11 and dropped. | — |
| Q5 | Are direct messages needed at launch? GroupMe has them. | Later |
| Q6 | Reactions: one per person per message, or several? | One |
| Q7 | On wide screens, bottom tabs or a side rail? | Side rail at 840 px and wider |
| Q8 | ~~What domain name for invite links and email?~~ **Decided:** `getbattleplan.app`, registered at Cloudflare ($8.20 the first year, then $14.20/year). battleplan.com, .app, and .io are taken. App ID `app.getbattleplan` (`.dev` for dev builds). | — |
| Q9 | Logo and primary color? | Placeholder mark; blue `#2F5BEA` |
| Q10 | Which email provider? | One with a free tier (e.g. Postmark or Resend) |
| Q11 | Where are most teams located? | US, so `us-central1` |
| Q12 | ~~Can members create events by default?~~ **Decided 2026-10-12:** only admins create events by default; each team can let members create them in Team settings (TEAM-5). | — |
| Q13 | ~~Apple developer account as an individual or an organization?~~ **Decided:** individual, for now. The LLC is no longer registered, so the apps are published under your own name in both stores. Both stores can upgrade the account to an organization in place later (it needs the LLC's D-U-N-S number) and keep the apps. | — |
| Q14 | ~~On youth teams, should coaches and staff also RSVP for themselves?~~ **Decided 2026-10-11:** yes. Team admins RSVP for themselves and are counted apart from players (PLAYER-6). | — |
| Q15 | ~~When a parent picks an existing player, must an admin approve the link?~~ **Decided 2026-10-11:** yes (PLAYER-3). | — |
| Q16 | ~~Is Facebook sign-in needed at launch?~~ **Decided 2026-10-11:** not for now. Launch with Google, Apple, and email. **2026-10-12:** Facebook sign-in was removed from the plan. It may be added later as a backlog item (ROADMAP, Later · Backlog). | — |
