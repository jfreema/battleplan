# Battleplan — Product Spec

| | |
|---|---|
| **Status** | Draft v0.3 |
| **Owner** | Jared Freeman |
| **Last updated** | 2026-10-16 |
| **Companion doc** | [ARCHITECTURE.md](ARCHITECTURE.md): how it's built ("ARCH §n" below) |

---

## 1. Overview

Battleplan is a messaging and scheduling app for sports teams, doing in one app what **GroupMe** (chat) and **TeamReach** (schedules and RSVPs) do. It runs on **iOS, Android, and the web**.

**How it's organized:**

- Any coach or manager can create a **team**. Each team has its own members, admins, chat, schedule, and documents.
- People can belong to many teams and switch between them.
- **Every account belongs to an adult (18+).** Every team has a roster of **players**. A member can be a player themselves, or a parent or guardian who answers for a player who doesn't use the app, such as a kid (§6.3).
- Platform **super admins** ("God admins") oversee every team.

**Rollout.** Go-live happens in phases, web first (§9). Phase 1 is the website and the web app in desktop and phone browsers. The iPhone and iPad app follows in Phase 4 and the Android app in Phase 5. Our own team uses it first. Then sign-up opens to any team, and every team is **invite-only**.

### Glossary

| Term | Meaning |
|---|---|
| **Team** | A group of people with its own chat, schedule, and documents. Stored as a `group` (ARCH §1). |
| **Member** | A person with an account who belongs to a team |
| **Team admin** | A member who manages the team: a coach, manager, or team parent |
| **Owner** | The one admin per team who created it, or was given it |
| **Super admin** | A platform operator who can see and manage every team and user (the "God admin") |
| **Added account** | An account created by an admin before the person first signs in (the "local account") |
| **Player** | Someone on a team's roster, with a name and jersey number. A member can be a player ("I am this player"). Players that others answer for, such as kids, never have accounts. |
| **Guardian** | A member linked to a player as their parent or guardian, who answers RSVPs for that player |
| **Player link** | How a member is linked to a player: as the player (`self`) or as a guardian. A member claims a player, and a team admin approves (§6.3). |
| **Storage limit** | How much a team can store in photos and files: 200 MB unless a super admin gives it its own limit (STORE-1, STORE-6) |

### Release tags

| Tag | Meaning |
|---|---|
| **MVP** | Needed to launch (on the web at Phase 1; in the native apps at Phases 4 and 5) |
| **v1.1** | Next, after the MVP. The web parts are built before the Phase 1 go-live (ROADMAP). |
| **Later** | Backlog |

### MVP success criteria

- Our team moves completely off GroupMe and TeamReach.
- A new coach can sign up, create a team, and have members chatting **within 10 minutes**, without help.
- A coach can paste in a roster of players with their emails or their parents' emails, then see per-player RSVP counts for the next practice.
- Every MVP feature works in desktop and phone browsers at Phase 1, and the same on iOS and Android once they ship in Phases 4 and 5 (§4).
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
| 5 | iOS, Android, and web, fully functional and consistent | §4; web in Phase 1, iOS in Phase 4, Android in Phase 5 (§9) |
| 6 | Group messaging | §6.5 (CHAT) |
| 7 | Push notifications | §6.9 (NOTIF); ARCH §6.5 |
| 8 | Polls in group messaging | §6.6 (POLL) |
| 9 | Scheduling events with going / not going | §6.7 (SCHED-3 to SCHED-5); PLAYER-6 |
| 10 | Sign in with Google, Apple, or email, on top of local accounts that admins can add | AUTH-1 (Apple in Phase 3), AUTH-6 to AUTH-8, AUTH-12; ARCH §6.1 |
| 11 | Password reset by email | AUTH-4 |
| 12 | Email invites | INV-4 |
| 13 | Shareable invite links and QR codes | INV-1 to INV-3, INV-6, INV-7 |
| 14 | Light mode and dark mode | SET-2; §7.4 |
| 15 | God admin panel for managing all teams | §6.11 (ADMIN) |
| 16 | Admins in each team | §3; TEAM-4 |
| 17 | Admins can delete messages | CHAT-8 |
| 18 | 👍 ❤️ 👎 😂 reactions on messages | CHAT-6 |
| 19 | Modern, clean UI | §7 |
| 20 | Bottom tabs: Chat, Schedule, Documents, Plays | §5.3 |
| 21 | Many sports teams, each with its own members, chat, and schedule | TEAM-1, TEAM-2, SCHED-2, §5.2; ARCH §1, §3 |
| 22 | Youth players don't use the app; their adult parents and guardians do (adult players can be members themselves) | AUTH-5, §6.3 (PLAYER), SAFE-6; ARCH §1 |
| 23 | Parent/guardian → player relationships, so parents RSVP for their child, not themselves | §6.3 (PLAYER-1 to PLAYER-6), on every team; ARCH §6.2 |
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
| One team type with players on every team: members claim a player as themselves or as a guardian, members propose players, and admins approve (§6.3) | Kids don't use the app, but coaches still need to know which *players* are coming, not which parents answered. Adult teams work the same way, with each player answering for themselves. |
| Adults-only accounts, 18+ (AUTH-5) | Matches who actually uses the app, and keeps us from collecting data from children |
| Pasted rosters with setup emails (TEAM-7) | Turns "admins can add local accounts" into a fast way for coaches to load a team |
| Spam controls, storage quotas, team suspension (SAFE-5, ADMIN-3) | Needed once anyone can create a team |
| Audit log (ADMIN-6) | Accountability for admin deletions and other admin actions |
| Forced app update (ARCH §9) | Lets us retire old app versions safely, including during a future SQL move |
| Privacy Policy, Terms, store disclosures (LEGAL) | **Required** to publish |
| Accessibility and translation-ready text (§7.6, §7.7) | Good practice, and cheap if done from the start |
| An explainer website at `getbattleplan.app`, with the web app at `/app` (§4.3) | A place to explain Battleplan, host the legal pages, and send people to the stores or the web app |
| Everything free with no ads, and a 200 MB storage limit per team with a Media section to free space (§6.14, [PLANS.md](PLANS.md)) | Keeps adoption easy while capping what one team can cost (Q4); ads may come once adoption justifies them |
| Direct messages and a page for each person (CHAT-19, TEAM-15) | The owner's request (2026-10-16): coaches and parents message one to one, as they did in GroupMe, and see who's who across the teams they share |

---

## 3. Roles and permissions

| Role | Who |
|---|---|
| **Member** | Anyone on the team |
| **Guardian** | A member linked to one or more players as their parent or guardian, who answers RSVPs for them |
| **Player (member)** | A member linked to a player as themselves ("I am this player"), who answers RSVPs on that player's row, never as themselves (admins included) |
| **Team admin** | Manages the team: coaches, managers, team parents |
| **Owner** | The admin who created the team, or was given it. Exactly one per team. |
| **Super admin** | Runs the platform. Can see and manage every team and user. |
| **Signed-out visitor** | Sees only the sign-in screens and a team's invite preview |

**Permission matrix.** "Setting" means the action is controlled by a per-team permission toggle (TEAM-5), shown with its default.

| Action | Member | Team admin | Owner | Super admin |
|---|:-:|:-:|:-:|:-:|
| Read the team's chat, schedule, documents, members | ✓ | ✓ | ✓ | ✓ any team |
| Send messages and photos, react, vote; RSVP for self | ✓ | ✓ | ✓ | in teams they've joined |
| Delete own messages | ✓ | ✓ | ✓ | ✓ |
| Share your own phone and email with the team (TEAM-10) | ✓ | ✓ | ✓ | in teams they've joined |
| **Delete anyone's message** | — | ✓ | ✓ | ✓ |
| Mention people with @ (CHAT-14) | ✓ | ✓ | ✓ | in teams they've joined |
| Message someone you share a team with, one to one (CHAT-19) | ✓ | ✓ | ✓ | on teams they've joined |
| Read a direct conversation (CHAT-19) | their own | their own | their own | their own; others' only what's reported (SAFE-1) |
| Mention @everyone; send announcements; pin messages (CHAT-14, CHAT-15) | — | ✓ | ✓ | pin any team; others in teams they've joined |
| Create polls | setting (on) | ✓ | ✓ | in teams they've joined |
| Close any poll | — | ✓ | ✓ | ✓ |
| Create events | setting (off) | ✓ | ✓ | ✓ |
| Edit, cancel, or delete events | own only | ✓ | ✓ | ✓ |
| RSVP for your linked players (as the player or a guardian) | approved links | ✓ | ✓ | ✓ |
| RSVP for any member or player | — | ✓ | ✓ | ✓ |
| Volunteer for an open assignment, or drop out of your own (SCHED-15) | ✓ | ✓ | ✓ | in teams they've joined |
| Add, edit, and remove assignments; assign anyone on the team (SCHED-15) | — | ✓ | ✓ | ✓ |
| Claim a player ("I am this player" or parent/guardian) | needs admin approval | ✓ at once | ✓ at once | at once, in teams they've joined |
| Add players | pending until an admin approves | ✓ | ✓ | ✓ |
| Add a guardian to a player | players they're linked to (as the player or a guardian) | ✓ | ✓ | ✓ |
| Remove player links; approve or decline claims and pending players | their own link only | ✓ | ✓ | ✓ |
| See and edit a player's details: date of birth, emergency contacts, notes (PLAYER-12) | players they're linked to | ✓ | ✓ | see only |
| Upload documents and add links | setting (on) | ✓ | ✓ | in teams they've joined |
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

| Platform | Minimum | Distribution | Goes live |
|---|---|---|---|
| Web, desktop and mobile | Latest two versions of Chrome, Edge, Firefox, Safari | Firebase Hosting at **`getbattleplan.app/app`**, linked from the website (§4.3). Installable as a home-screen app (PWA). | Phase 1 |
| iPhone and iPad | iOS 15 | App Store | Phase 4 |
| Android phones and tablets | Android 8.0 (API 26) | Google Play | Phase 5 |

**Phase 1 ships the web only.** The iOS and Android apps keep building and passing their tests in CI, but they reach the stores only in Phases 4 and 5 (§9). Until then, iPhone and Android users use the web app in their phone's browser or from their home screen.

### 4.3 The website (WEB)

`getbattleplan.app` is a small explainer website; the web app lives under it at **`getbattleplan.app/app`**. The site's source is the `website/` folder in the repo (ARCH §5.1, §6.6).

- **WEB-1 · MVP · Landing page.** What Battleplan is (team chat, schedule and RSVPs, polls, documents, players and parents for adult and youth teams), that it's free with no ads, screenshots, and clear ways in: **Get Started** (the web app's sign-up page, `/app/sign-up`) and **Login** (`/app`), and App Store and Google Play badges once the apps are listed. Ends with a **Donate to Support This Project** button linking to Jared's Venmo (`https://venmo.com/u/Jared-D-Freeman`), with the handle shown below it. Support is voluntary and unlocks nothing.
- **WEB-2 · MVP · Support and legal pages.** `/privacy`, `/terms`, and `/delete-account` (LEGAL-1, LEGAL-3), and `/support` with the support email. These are the URLs the store listings and Firebase settings use.
- **WEB-3 · MVP · The web app at `/app`.** The Flutter web app is served under `/app/` and linked from every page of the site. Signed-in people who open `/app` go straight to their teams.
- **WEB-4 · MVP · Short links still work.** Invite links and QR codes keep the short form `getbattleplan.app/join/K7XP-M2QR`. With the app installed they open it; otherwise the browser lands in the web app's join page under `/app`. Email and notification links also open the app if installed, or the web app. So does email sign-in's address, `getbattleplan.app/emaillogin` (AUTH-2).
- **WEB-5 · MVP · Fast and plain.** Static pages with no ads, no tracking, and no cookie banner needed; one look, Gumdrop Army's army green, cream, and coral (§7.4), with no light version; the fonts served from the site itself, not Google Fonts (LEGAL-2); readable on phones; indexed by search engines, while `/app` isn't.

### 4.2 The parity rule

- **From Phase 4 on**, every feature ships on every live platform **in the same release**, with the same behavior, layout, and wording: iOS and the web from Phase 4, and Android too from Phase 5.
- A feature is done only after it's been tested on:
  - an iPhone (from Phase 4);
  - an Android phone (from Phase 5);
  - a desktop browser;
  - a phone browser: Safari on an iPhone and Chrome on an Android phone. Until Phase 4 this is the only phone test, so it covers every flow, not just joining.
- Differences are allowed only where the platform forces them:

| Capability | iOS | Android | Web |
|---|---|---|---|
| Push notifications | Yes | Yes | Yes, after browser permission. On iPhone/iPad, only once added to the Home Screen. |
| Sign in with Apple (from Phase 3) | Native sheet | Web sign-in flow | Popup |
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
 ├─ The top: tabs Teams | Profile
 │    ├─ Teams:    your teams (each opens where you left it) · Join a team ·
 │    │            Create a team · Messages · notification bell
 │    │            (no team yet: a welcome with Join and Create)
 │    └─ Profile:  your photo and name · Themes · Settings ·
 │                 Admin panel** · Sign out              (** super admins)
 └─ Team view (the app opens where you left it: the last team and tab, or Teams)
      ├─ Header:     ‹ back to Teams · team switcher ▾ · Messages · notification bell · Team info ⓘ
      ├─ Messages:   your direct conversations → one of them (CHAT-19)
      ├─ A person:   their page, from their photo in chat or the roster (TEAM-15)
      ├─ Tabs:       Chat | Schedule | Documents | Plays
      └─ Team info:  the team · Roster · Invite · Notifications for this team · Calendar link ·
                     Team admin* · Media* · Reports* · Import*    (* admins)
                     (Leave team is on your own card in the Roster, TEAM-8)
```

- **The top** (owner's request 2026-10-27). **Teams** and **Profile**, with tabs at the bottom on phones and a rail on wide screens. Teams lists your teams as cards (logo, name, sport, last message, unread count), then Join a team and Create a team; someone with no team yet sees a welcome with the same two. Profile has your photo (Change photo) and the name your teams see, then **Themes** (SET-2), **Settings**, the **Admin panel** for super admins, and **Sign out**, each its own rounded card.
- **A team's back arrow** (‹ at the top left of the header) goes to Teams. Inside a tab, on a page with its own back button (Saved plays, a play), the header leaves its arrow out, so only one back shows.
- **Team info** (ⓘ in the header) is a page: the team's logo, name, sport, and member count, then what the team menu had. **Team admin** was called Team settings.
- **Your avatar** left the team's header: what it held is on Profile.

### 5.2 Team switcher

- **Header.** Shows the current team's logo (or initials on its color), the team name, and ▾. A dot appears on it when another team has unread messages.
- **Opening it.** A bottom sheet on phones; a dropdown panel on wide screens.
- **Contents.**
  - Your teams, most recent activity first.
  - Each team shows its logo, name, sport icon, last-message preview, unread message count, and muted icon.
  - Archived teams collapse into an "Archived" section.
  - At the bottom: **Join a team** (code or QR) and **Create a team**.
- **Switching** keeps you on the same tab: from one team's Schedule to the other team's Schedule.
- **Memory.** The app remembers the last team and tab on each device, or Teams when you left from there, and opens there. Teams opens each team at the tab you last had in it.

### 5.3 Bottom tabs

| Tab | Icon | Badge |
|---|---|---|
| **Chat** | Speech bubble | Unread message count for this team (CHAT-9) |
| **Schedule** | Calendar | — |
| **Documents** | Folder | — |
| **Plays** | A coach's play, after the Play Call app icon design: an O at the bottom left, its dotted route arcing up to an arrowhead, and an X at the bottom right. Drawn, as no icon font has one; one color in the tabs, and in color on the empty Plays screens (a lemon O and a cherry X) | — |

- Labels are always visible. The tabs, order, and icons are the same everywhere. On wide screens, Plays sits directly below Documents in the left navigation rail.
- Each tab keeps its scroll position when you switch away and back.

### 5.4 Phone layout (Chat tab)

```
┌────────────────────────────────────┐
│ (TU) Thunder U14 v [M] (!) ...(JF) │
├────────────────────────────────────┤
│              ( Today )             │
│ (AK) ┌─────────────────────────┐   │
│      │ Alex Kim  5:58 PM       │   │
│      │ Field 3 is open. See    │   │
│      │ you at 6!               │   │
│      └─────────────────────────┘   │
│       (Like 4) (Love 1)            │
│               ┌──────────────────┐ │
│               │ 6:02 PM          │ │
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
│ [Chat] Schedule Documents Plays     │
└────────────────────────────────────┘
```

### 5.5 Wide screens (web and tablets, 840 px and up)

- **Navigation.** The tabs move to a **left rail**: Chat, Schedule, Documents, and Plays, with your avatar at the bottom. The team switcher stays in the header beside the rail. The order, icons, and labels match phones.
- **Chat** is centered at a readable width (about 840 px).
- **Panels.** Event details, member cards, and settings open as side panels or dialogs instead of full screens.
- **v1.1.** On very wide screens (1200 px and up), a persistent team list column, like Slack's.

---

## 6. Features

Each requirement has an ID, a release tag, and a short description. IDs are stable; reference them in issues and PRs.

### 6.1 Accounts and sign-in (AUTH)

- **AUTH-1 · MVP · Sign-in screen.**
  - Buttons in this order: Continue with Google, then Continue with Apple. Single sign-on is the way in, at the owner's request.
  - **No email button.** Email sign-in (AUTH-2) is at `/emaillogin`, which nothing on the sign-in screens or the website links to. It's for special cases: someone without a Google or Apple account, App Review's demo account, and testing. Builds that run against the emulators also show Continue with email, so developers can sign in to the seeded accounts.
  - Logo and a one-line tagline above them.
  - Footer: "By continuing you agree to the Terms and Privacy Policy", with links.
  - A link to the sign-up page: "New here? Sign up, it's free". The sign-up page (`/sign-up`, where the website's Sign up button goes) is the same screen saying "Create your free account", with Sign up with Google (and Apple once it's on), and "Already have an account? Sign in". Google and Apple make the account the first time either way.
  - **The stores allow it.** Neither store asks for email sign-in. Apple's guideline 4.8 does ask an app that offers Google sign-in to offer one that can keep the email private beside it, which Sign in with Apple does, so the iPhone app ships with Apple on (store checklist 2.1). Reviewers sign in with Apple or Google and join the demo team with its code, or use the demo account at `/emaillogin`, which the review notes describe, as Apple's guideline 2.3.1 asks of anything not on screen (store checklist 1.14, 1.17).
  - Google always asks which Google account to use (its account chooser), so a browser signed in to one Google account never picks it silently.
  - The screen is identical on every platform. The Apple button follows Apple's design rules, and the Google button Google's: Google's "G", in its own colors and unaltered, on a white disc before the title, on every Continue with Google button (the owner's request, 2026-10-26).
  - **Continue with Apple** (Phase 3, §9) is on in dev, on the emulators, and in prod since 2026-10-17, when both Firebase projects got Apple's Services ID and key. A switch in the app (`AppEnv.appleSignInInProd`) can hide it in prod again, so prod never offers a button that can't work; hidden, prod shows Google only, and Sign-in methods (AUTH-8) offers Apple only to an account that already has it.
  - Apple asks for the email and, the first time, the name, which prefill the profile (AUTH-12). With Hide My Email, Apple shares a private relay address instead (`…@privaterelay.appleid.com`), which reaches the person as long as our sending domains are registered with Apple (task 207).
  - Continue with Facebook joins in Phase 6, with single sign-on (Q16).
- **AUTH-2 · MVP · Email and password.**
  - At `/emaillogin`, not linked from the sign-in screen (AUTH-1). `getbattleplan.app/emaillogin` works too: Hosting redirects it into the web app, and the phone apps open it. `/sign-in/email`, its old address, redirects there, keeping where to go back to.
  - Sign in, or create an account with name, email, and password, or have a sign-in link emailed.
  - The app shows the address only to people who use a password: their password's row in Sign-in methods (AUTH-8) and the choose-how-to-sign-in screen (AUTH-6) say where it works. The support page asks people with a password to email support.
  - Passwords need 8+ characters, enforced by Firebase's password policy.
  - Show/hide password toggle.
- **AUTH-3 · MVP · Email verification.**
  - Google and Apple sign-ins arrive verified. Email sign-ins get a verification link, and a banner stays up until it's tapped.
  - A verified email is required to create a team, send email invites, or add people by email.
- **AUTH-4 · MVP · Password reset by email.**
  - "Forgot password?" → enter email → "If an account exists for that email, we've sent a reset link."
  - The link opens the reset page; then the user signs in with the new password at `/emaillogin` (AUTH-2), where "Forgot password?" is. A reset a super admin sends continues there.
  - The screen notes that people who use Google or Apple don't have a Battleplan password.
- **AUTH-5 · MVP · First-run setup.**
  - Name and photo, prefilled once from the sign-in provider (AUTH-12), and Terms acceptance.
  - Confirm "I'm 18 or older". Accounts are for adults only. Adult players use the app themselves, and youth players never sign in: their parents and guardians use the app for them (§6.3).
  - Only the confirmation and its date are stored.
  - It says which account is signed in ("Signed in as …"), with **Use a different account**, which signs out and goes back to the sign-in choices: for a Google account picked by mistake.
  - **Continue** shows a spinner while it saves. A save that fails, or gets no answer within 30 seconds, says so ("Couldn't save your profile. Check your connection and try again.") and Continue works again; the error is reported like other app errors.
  - **Setup comes first, always.** A new account goes to setup even before the server has made its profile (a request can sit on a phone for minutes before it's sent): Continue makes the profile with the answers. Nobody gets into the app, or creates a team, before confirming 18+ and accepting the Terms.
- **AUTH-6 · MVP · Accounts added by admins.**
  - Team admins and super admins add people with just a **name and email** (TEAM-7, PLAYER-1, ADMIN-4).
  - **Admins never set, see, or know anyone's password.** No screen or tool lets them. They can only send setup and password-reset emails.
  - The person gets a **setup email**. Its link signs them in, verifies their email, and asks how they want to sign in from now on: Google (the main button), Apple (where it's on, AUTH-1), or **Use a password instead**, whose dialog says they'll sign in with it at `/emaillogin` (AUTH-2).
  - A setup or sign-in link that's expired or broken says so, and **Back to sign-in** opens email sign-in, where "Email me a sign-in link instead" sends a new one.
  - Setup links expire, and admins can resend a fresh one.
  - Until setup, the person appears on the roster as "Not joined yet", and admins can RSVP for them.
- **AUTH-7 · MVP · Safe account linking.**
  - **Prove both sides.** A sign-in method is added only when the person is signed in to their Battleplan account (recently) and completes the provider's own sign-in.
  - **No merging just because emails match.** If someone tries a new method with an email that already has an account, the app explains ("You've signed in with Google before. We sent you a link to confirm it's you.") and links the new method only after that emailed link is opened, offering to finish adding it (Google, or Apple where it's on). The exceptions are the providers Firebase trusts to vouch for an address themselves: Google for a Gmail address, and Apple, whose addresses Firebase always treats as verified. Signing in with either joins the account with that email and adds the method, and replaces a password whose email was never verified. A Hide My Email relay address matches no account, so it starts a new one; to use Apple on an existing account, link it from Sign-in methods (AUTH-8).
  - **Security emails.** Adding or removing a sign-in method, or changing the email or password, sends a notice: "Google sign-in was added to your Battleplan account. Not you? Contact support." That includes a method Firebase adds or replaces at sign-in by itself (the exceptions above).
  - **A fresh sign-in is required** for linking, unlinking, changing the email or password, and deleting the account.
  - **Two separate accounts are never merged automatically.** Support can move memberships by hand.
- **AUTH-8 · MVP · Sign-in methods screen.**
  - Settings → Sign-in methods lists the linked methods (Google, Apple, password). A linked password says where it works: "Linked. Sign in with it at getbattleplan.app/emaillogin." Apple is listed where it's on (AUTH-1), and on any account that already has it.
  - Link another, unlink one (never the last), or set or change a password. Linking uses the provider's own sign-in: Apple's sheet on an iPhone, iPad, or Mac, and a popup on the web. Closing it links nothing and says nothing.
  - Change the account email, confirmed through a link sent to the new address. The old address gets a notice.
- **AUTH-9 · MVP · Sessions.**
  - Stay signed in across app restarts and browser sessions.
  - Sign out from Settings; that stops push notifications on that device.
  - "Sign out of all devices" ends every session at once.
- **AUTH-10 · MVP · Delete account.**
  - Settings → Account → Delete account explains what will happen, asks the user to sign in again, then deletes everything.
  - In the iPhone, iPad, and Mac apps, an account with Apple sign-in signs in with Apple once more, so the app can revoke Apple's tokens first (App Review 5.1.1(v)). Closing Apple's sheet deletes nothing. The web and Android can't revoke; people there can remove Battleplan under Sign in with Apple in their Apple Account settings.
  - Owners pick a new owner for each team they own. If they skip it, ownership goes to the longest-serving admin, otherwise the longest-serving member. Teams with nobody else are archived.
  - Their player links end (as a player or a guardian). A player left with no links stays on the roster for admins to manage. Their player claims, and the players they added that no admin approved yet, are deleted.
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
  - **Who:** any signed-in user with a verified email. Super admins can turn this off, and each person can create up to 5 teams a day (super admins can change the limit, ADMIN-7).
  - **Fields:**
    - Name (required, ≤ 50 characters).
    - Sport: Baseball, Basketball, Football, Hockey, Lacrosse, Soccer, Softball, Volleyball, or Other.
    - Logo or photo (optional).
    - Team color (optional). Chosen from 15 colors, navy and gold among them. It shows in the background of every screen inside the team, in every theme (§7.4); badges show white or black text on it, whichever reads better.
    - Time zone (defaults to the device's).
    - Description (optional).
  - The creator becomes the **owner**, and the next screen is "Invite your team" (INV-1).
  - **Create a team** shows a spinner while it saves. One that fails, or gets no answer within 30 seconds, says so ("Couldn't create the team. Check your connection and try again."), and is reported. Trying again is safe: a first request that arrives late and the retry make one team between them.
  - There's one kind of team, with no team type to pick. Every team has a roster of players, and works for adult and youth teams alike (§6.3). Teams are stored with kind `team`, so a basic group without players can be added later (TEAM-14).
  - **Goal:** create a team and share an invite in under 2 minutes.
- **TEAM-2 · MVP · Many teams per person.**
  - A person can be on up to 100 teams and switches between them with the team switcher (§5.2).
  - Each team has its own chat, schedule, documents, members, admins, settings, and notification level.
  - Teams are walled off from each other. Nothing shows which other teams a member belongs to: a person's page (TEAM-15) lists only the teams you share with them.
- **TEAM-3 · MVP · Roster screen.**
  - A **Players** section on every team (jersey number, name, and who's linked: "Player" or "Guardian"), then sections for **Coaches**, Admins, and Members. Each member shows their players: a guardian shows "Emma #7", and a member who is a player shows their number (PLAYER-8).
  - **Who sees the people:** with the team setting "Everyone can see who's on the team" off (TEAM-5), members see the players, the coaches, and their own card (which has Leave team), and a line saying the admins keep the rest private; admins see everyone. Names still show where people act, as authors in chat and on RSVPs.
  - **Coaches:** team admins turn on **Coach** on a person's card, for a parent who coaches too, for example. Coaches are listed together, their Owner or Admin badge kept, and answer for themselves on events (PLAYER-6). Until someone sets it, the owner counts as a coach.
  - Admins see pending players and claims at the top, with Approve and Decline (PLAYER-4).
  - Each person row shows a photo or initials, name, title, role badge (Owner/Admin), and "Not joined yet" for added accounts.
  - Search by name.
  - Tap a person to open their card: photo, name, title, role, Coach, their players, and only the actions you're allowed. Actions: Make admin / Remove admin, Edit title, Coach (on or off), Remove from team, Resend setup email, Report, Block.
  - Someone else's card also has **Message** (CHAT-19), when they've joined and you haven't blocked them, and **Profile**, their page (TEAM-15).
  - Tap a player to open the player card (PLAYER-2).
- **TEAM-4 · MVP · Team admins.**
  - The owner and admins run the team (§3).
  - Admins can make other members admins. Only the owner, or a super admin, can take admin away.
  - Every team has exactly one owner.
- **TEAM-5 · MVP · Team admin (admins).** Called Team settings until 2026-10-27; it opens from Team info.
  - Edit name, sport, logo, color, description, and time zone.
  - **Team color:** the 15 colors as swatches, in this order: Blue (new teams start on it), Light blue, Navy, Teal, Green, Olive, Yellow, Mustard, Orange, Red, Maroon, Pink, Purple, Gray, and Black, under "Your team color shows in the background of every screen in the team." (TEAM-1, §7.4). Royal blue and Violet were taken out in 1.1 as too close to Blue and Purple: a team still set to one keeps it, and the app shows it as Blue or Purple (its swatch picked, its badge and backgrounds in that color).
  - **Member permissions** (defaults in brackets):
    - create events [off]
    - create polls [on]
    - upload documents [on]
    - invite others [on]
    - allow "Maybe" RSVPs [on]
    - everyone can see who's on the team [on]: off, only admins see all the people on the roster (TEAM-3)
  - **Language:** filter strong language [on] (SAFE-7).
  - Default event reminders: 1 day before.
  - Manage the invite link.
  - See storage used, e.g. "112 MB of 200 MB", and open Media to free space (STORE-2, STORE-5).
  - **About**, at the end, at the owner's request: the version and build, "Developed by Jared Freeman", that Battleplan is free and Jared builds it as a volunteer, and **Buy Jared a coffee**, which shows his Venmo card (a QR code to scan) and **Open Venmo** for paying from the same phone. A tip is voluntary and unlocks nothing.
- **TEAM-6 · MVP · Transfer ownership.** The owner picks a member to take over and becomes an admin.
- **TEAM-7 · MVP · Add members by email (admins).**
  - Add one person at a time, or paste a list of "Name, email" lines (up to 100).
  - People who already have accounts are added and notified. New emails get an account and a setup email (AUTH-6).
  - A results screen lists who was added, who was invited, and any problems.
  - To fill the Players section, admins add players with the player's or their parents' emails instead (PLAYER-1).
- **TEAM-8 · MVP · Leave a team.**
  - Anyone can leave, from their own card in the roster (Team info → **Roster** → their name → **Leave team**), after confirming. It isn't on Team info, as it once was in the team menu, where it was too easy to tap by mistake (2026-10-15, at the owner's request).
  - The owner must transfer ownership first. If they're the only member, they archive or delete the team instead.
- **TEAM-9 · MVP · Archive or delete (owner, super admins).**
  - **Archive** makes the team read-only and moves it to "Archived" in the switcher. It can be restored.
  - **Delete** requires typing the team name. It permanently removes all messages, events, documents, and files.
- **TEAM-10 · v1.1 · Roster details.** Built (task 136).
  - Sort the roster's players by jersey number (the default; players without one come last) or by name, from the sort button. (Numbers live on players, PLAYER-1, and a member who is a player shows theirs.) Admins and members are listed by name, the owner first.
  - Optional contact sharing: on their own card, members share a phone number and email with that team ("Share my phone and email"; the account's email is offered), and change them or stop sharing at any time. They appear on their card for everyone on the team with call, text, and email buttons. Each team is separate. Sharing needs an open team; stopping works even on an archived or suspended one. Leaving the team or deleting the account removes them.
- **TEAM-11 · MVP · Players on every team.** Players, guardians, and claims are specified in §6.3 (PLAYER).
- **TEAM-12 · v1.1 · Announcement-only mode.** Only admins can post in chat. Everyone can still react, vote, and RSVP.
- **TEAM-13 · Later.**
  - Join requests that need admin approval.
  - Copying a team for a new season (members and settings).
  - Organizations and leagues with club admins.
  - Sub-chats within a team ("Parents", "Coaches").

- **TEAM-15 · MVP · A person's page.** Owner's request (2026-10-16): "click on another user's icon to get to their user profile page… show what teams they're a member of and if they're a coach show that as well."
  - **Opening it:** tap someone's photo beside their messages in a team's chat or a direct conversation, **Profile** on their roster card (TEAM-3), or their name at the top of a direct conversation (CHAT-19).
  - **What it shows:** their photo and name, **Message** (CHAT-19), and **Teams in common**: each team you're both on, with its badge and what they are there: Coach, Owner or Admin, their title, and who's who from their players ("Player #12", "Parent of Emma #7", PLAYER-8), or Member. Teams they coach come first. Tapping a team opens their card on that team, with what they share there (TEAM-10) and the actions you have there.
  - **Only teams you share.** Teams stay walled off (TEAM-2): a team you're not on never shows. A team that keeps its people to its admins (TEAM-3) shows only when they coach it, you're one of its admins, or you opened the page from that team, where you've already seen them.
  - Its menu has **Block** or **Unblock** (SAFE-2), and **Report** on a team you share (SAFE-1).
  - **Your own page** lists all your teams, with **Edit profile** (SET-1).
  - Someone you share no team or conversation with shows only "This person isn't on any of your teams."

### 6.3 Players, guardians, and claims (PLAYER)

Every team has a roster of players. There's one kind of team, so this works the same for adult and youth teams. A member can be linked to a player in one of two ways:

- **As the player** ("I am this player", relation `self`). An adult player answers RSVPs for themselves on their player's row.
- **As a parent or guardian** (relation `guardian`). They answer RSVPs for a player who doesn't use the app, such as a kid.

Players that others answer for never get accounts, and every account belongs to an adult (18+).

- **PLAYER-1 · MVP · Add players (admins).**
  - Add one at a time: name (required), jersey number, and date of birth (optional, kept in the player's details, PLAYER-12).
  - Or paste a list with one player per line: "Player name, jersey number", the number optional. Lines that can't be read, such as ones with more than a name and a number, and names given twice are listed afterward. Up to 200 lines.
  - Players that admins add are active right away. Nobody is linked to them here: parents, guardians, and adult players link themselves when they join the team and claim the player (PLAYER-3), and admins can still add a guardian from the player card, from the team or by email (PLAYER-5). The form says so.
  - Afterward the app says how many players were added; a pasted list with lines it couldn't read shows them on a results screen.
- **PLAYER-2 · MVP · Player card.**
  - Shows the name, jersey number, walk-up song, date of birth and age (for the people who see the player's details, PLAYER-12), who's linked, each marked "Player" or "Guardian" ("Not joined yet" where it applies), and upcoming RSVPs. The player's linked members and the team's admins also open its RSVP history (PLAYER-11).
  - The player's linked members can edit the name and number, and, with admins, the date of birth in the same Edit player dialog (PLAYER-12).
  - A member who isn't linked sees **Claim this player** (PLAYER-3).
  - Linked members and admins can add a guardian (PLAYER-5). Admins can also remove links and remove the player, and a linked member can remove their own link.
- **PLAYER-3 · MVP · Claim a player.** Any member can claim an active player and say how they're linked: **"I am this player"** or **"I'm their parent or guardian"**.
  - A claim needs a team admin's approval (Q15). Until then, the member can chat but can't answer RSVPs for that player.
  - When an admin claims a player, it's approved at once, and so is a claim by a super admin who's on the team. A super admin who isn't on the team can't claim a player.
  - A player has at most one `self` link, and a member is `self` for at most one player per team. A player can have up to 4 guardians; the `self` link doesn't count toward the 4.
  - **Who are you here for?** After joining any team, a member sees three choices:
    - **I'm a player.** Pick yourself from the roster (a claim as yourself), or add yourself if you're not listed (a pending player linked to you as yourself, PLAYER-4).
    - **I'm here for a player.** Pick your player from the roster, or several (a claim as guardian), or add a player who isn't listed (a pending player with you as guardian).
    - **I'm a coach or another adult.** Skips this step.
  - People whose email an admin already entered for a player (PLAYER-1) are linked automatically and never see this step.
- **PLAYER-4 · MVP · Add a player (members), and admin approval.**
  - Any member can add a player: name, jersey number, date of birth (optional, PLAYER-12), and how they're linked (the player or a guardian).
  - A member's new player is **pending** until a team admin approves or declines it. A player an admin adds is active at once (PLAYER-1).
  - Pending players are shown only to admins and to the person who added them. They're not on the roster for everyone else, and can't get RSVPs or be claimed.
  - Claims and pending players appear at the top of the roster's Players section with **Approve** and **Decline**, and admins get a notification for each one (NOTIF-2). The person is notified when it's approved.
  - Admins can correct a pending player's name and number before deciding.
  - Approving a pending player makes it active with its link. Declining deletes the pending player and its link. A declined member can ask again.
  - Approving checks the PLAYER-3 limits again when the link is made. If they no longer allow it (say the member became a player meanwhile, or someone else is already this player), a claim isn't approved and the app says why, so the admin can decline it. A pending player is still added, without the link, and the app says so.
- **PLAYER-5 · MVP · Add another guardian.** From the player card, a linked member (the player themselves or a guardian) or an admin can add a guardian: someone already on the team, picked from a list, or anyone by email. An existing link is vouching for them, so no admin approval is needed. Someone picked from the team gets no email, only a notification that they're now the player's guardian. The list leaves out the people already linked to the player, and members of a team that keeps its people to its admins (TEAM-3) get only the email. New emails get an added account and a setup email. A player has up to 4 guardians, and the player can't also be their own guardian.
- **PLAYER-6 · MVP · RSVPs per player, on every event.**
  - **Exactly one RSVP per event and participant.** A participant is an active player or a member answering for themselves.
  - A player's RSVP can be answered by the member who is that player, by its guardians, or by admins. When two people answer, they update the same record instead of creating two. The latest answer counts and shows who gave it ("Answered by Maria"), so attendance never conflicts or double-counts.
  - Linked members see one RSVP row per player, first: "Emma: Going · Liam: Not going". A member who is a player answers on their player's row.
  - A **Me** row, below the players, is offered to coaches (TEAM-3) and to members who aren't linked to any player, such as other adults. A parent who isn't a coach answers only for their players, admin or not. A member who is a player, coaches included, has no Me row: they answer only on their player's row, so they never have two answers of their own.
  - When a member becomes linked as the player, their own answers to upcoming events move to the player's row. Where the player already has an answer, the player's answer stays and theirs is dropped.
  - Counts show players going, with everyone else counted apart: "12 of 15 players going · 2 others" (Q14). A team with no players counts everyone together: "12 going · 3 maybe · 2 no".
  - Events made before the one-type change count as per-player too. Members' own answers on them stay valid and count as others.
- **PLAYER-7 · MVP · Reminders and changes.** Event reminders and event changes go to the member who is the player and to the guardians of the affected players, as one notification per person naming their players: "Emma, Liam: Practice today at 6:00 PM". For a member's own player, there's no name prefix. Coaches and members not linked to any player go by their own answer.
- **PLAYER-8 · MVP · Who's who.** In chat and on the roster, each member's name shows their players. A guardian shows "Maria R. · Emma #7". A member who is a player shows their number when it's set: "Jared F. #12".
- **PLAYER-9 · MVP · Players on several teams.** A person on two teams is a separate player on each team. In "All my teams" (SCHED-2), each event shows which of a member's players it's for.
- **PLAYER-10 · MVP · Players' privacy.** This applies to every player record.
  - The roster record everyone on the team sees holds only a name, jersey number, and walk-up song: no photos, birthdates, or contact details. (Players added before positions left the roster may still carry one, which the app no longer shows.)
  - **Walk-up song:** the song played as the player comes up, "Thunderstruck, AC/DC", up to 100 characters, set in Edit player by the player's linked members and the team's admins (and super admins, ADMIN-3). The whole team sees it on the player card, and the people who edit the player see the row before there's one.
  - Optional details for running the team (PLAYER-12) are kept apart from the roster record and seen only by the team's admins and the people linked to that player.
  - Players never get accounts of their own. Accounts are for adults only (18+), and a `self` link just means that member is the player.
  - Player records that others manage may be children's, so we treat every record this way (LEGAL-1).
  - Photos shared in team chat may still show kids. They're visible only to the team's members, and anyone can report one.
- **PLAYER-12 · MVP · Player details for coaches.** Owner's request (2026-10-12): "store player info, like date of birth, and such for easy administration as a coach." On 2026-10-20, at the owner's request, medical notes and their consent stamp were removed, so Battleplan collects no health data.
  - Each player can have optional details: date of birth, up to 2 emergency contacts (name, phone, relationship), and notes for coaches (up to 500 characters). There are no medical notes: Battleplan doesn't collect health data.
  - Who sees and edits them: the team's admins and the members linked to that player (the player themselves or a parent or guardian). Other members never see them, not even that they exist. Super admins can see them for support but can't change them.
  - The date of birth can also be given when a player is added (PLAYER-1, PLAYER-4) and changed in Edit player on the card; it's still stored only in the details. A member's pending player keeps it, and a decline deletes it with the player.
  - On the player card, the Details section shows the age and date of birth, the emergency contacts with tap to call, and the notes, with Edit. On the roster, admins see each player's age.
  - Details are deleted with the player or the team. Removing a guardian or deleting a linked account doesn't delete them, since they belong to the player. They never appear in notifications, chat, search, logs, or analytics.
  - Archived teams are read-only.
- **PLAYER-11 · v1.1 · Answering for several players, and RSVP history.** Built (task 137).
  - **Same answer for all my players.** A member who answers for two or more players gets an "All my players" row above the per-player rows, on the event's page and its chat card: one tap gives each of those players that answer, saved together (all or none), each keeping their note. It shows that answer while every one of them has it. Their own answer as a member (Me) stays apart.
  - **RSVP history.** From the player card, the player's linked members (the player and their parents or guardians), the team's admins, and super admins open the player's RSVP history: the team's past events that took RSVPs in the last 3 months (or 6, or 12), newest first, each with the player's answer (Going, Maybe, Not going, or No answer) and opening its event, under totals for those events ("12 past events: Going · 9, Not going · 2, No answer · 1"). Canceled events are listed but not counted, and events from before the player was added to the roster aren't shown. Other members don't see it.

**Acceptance (MVP)**

- A coach pastes a roster of 15 players and their parents' emails, and every parent who finishes setup is linked to the right player.
- An adult player who joins by link picks "I'm a player", claims themselves on the roster, and answers RSVPs for themselves once an admin approves.
- A parent who scans the team's QR code at practice can claim their player, and is linked once an admin approves.
- A member who adds a missing player sees it as pending; it shows on the roster for everyone only after an admin approves, and a decline removes it.
- A parent with two players on the team answers for each one separately, and the coach sees accurate player counts with coaches counted apart.

### 6.4 Invites and joining (INV)

- **INV-1 · MVP · Invite screen.**
  - Opens from Team info, and right after creating a team.
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
  4. Tap **Join team**, then answer "Who are you here for?" (PLAYER-3): I'm a player, I'm here for a player, or I'm a coach or another adult. People an admin already linked to a player skip it.
  5. Land in the team's chat, where "Sam joined" appears.

  People who are already members just go to the team.
- **INV-6 · MVP · Join without a link.** "Join a team" (on Teams and in the team switcher) offers **Enter code** and **Scan QR code**, using the camera on phones and in the browser.
- **INV-7 · MVP · Web join page.**
  - `/join/<code>` (served by the web app under `/app`, WEB-4) shows the team preview, **Open in app**, App Store and Google Play badges once the apps are listed (Phases 4 and 5), and **Continue in browser**.
  - Shared in a messaging app (iMessage, WhatsApp, Messenger, Slack, Discord, and others), the link's preview says "Join Thunder U14 on Battleplan" and who sent the invite, with the team's logo, or Battleplan's card when the team has none or the link no longer works (1.1, ARCH §6.6).
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
  - Date separators, as small pills: Today, Yesterday, Mon Oct 6.
  - Each message is its own bubble, compact as GroupMe's (the owner's request, 2026-10-16). A person's run of messages (within 5 minutes) has their photo beside the first bubble, and their name and time inside it at the top; my own bubbles show just the time there. Photos sit inside the bubble, above the caption, and "edited" and "Pinned" go inside too. Polls and event cards keep the name and time above them. A member's name shows their players ("Maria R. · Emma #7", or "Jared F. #12" for a member who is a player, PLAYER-8).
  - Laid out as iMessage lays them out (the owner's request, 2026-10-16): others' messages sit on the left on a neutral background, mine on the right in the theme's own color (blue raspberry, or lemon in Gumdrop Candy) or the one the chat look picks (CHAT-18). Each bubble fits its text, its longest line setting its width, and grows to about four fifths of the chat's width (at most 520 px) before the text wraps, so the two sides stay apart. In a direct conversation (CHAT-19) the other person's messages have no photo or name beside them.
  - Message text is Nunito, 16 points, bold on others' messages and extra bold on mine, the same on every platform (§7.3; 1.1 replaced iMessage's type, San Francisco on Apple's platforms and Inter elsewhere).
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
  - Chips under the bubble show each reaction with its count, and yours is highlighted. Tap a chip to add that reaction, or to take yours back if it's yours. Long-press or right-click a chip, or choose See who reacted in the message menu, to see who reacted.
  - ❤️ is always red, on fonts that only have a plain heart too.
- **CHAT-7 · MVP · Message menu** (long-press or right-click).
  - React, Reply, Edit (your own, CHAT-15), Copy text, Pin and Unpin (admins, CHAT-15), Delete (your own; admins can delete any), Report (other people's).
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
  - New events appear as event cards when "Post to chat" is on. They show date, time, location, Going / Maybe / Not going buttons, and live counts. Members linked to players answer for each of their players right on the card (PLAYER-6).
- **CHAT-12 · MVP · Blocked people.** Their messages are collapsed ("Message from someone you blocked · Show"), and they don't notify you.
- **CHAT-13 · MVP · Reply to a message.**
  - Reply from the message menu, or swipe right on a message (phones).
  - The composer shows the quoted message (the author and first line, or "Photo" or "Poll") with ✕ to cancel.
  - The sent message shows the quote above the reply. Tapping the quote jumps to the original, loading older messages if needed.
  - The server creates quotes from the original message, so they can't be faked.
  - If the original is deleted, the quote shows "Original message was deleted".
  - The person replied to gets a notification, even at "Important only", and a notification-center item (NOTIF-11).
- **CHAT-14 · v1.1 · @mentions.** Built (task 135).
  - Typing @ suggests team members whose name, or a word of it, starts with what's typed, up to 5, never yourself. Tap one, or use the arrow keys and Enter or Tab on a keyboard; Escape closes the list. Picking one puts "@Full Name " in the message.
  - A message names whoever's full name follows an @, matched without regard to case, with the longest name winning ("@Mary Ann Lee" over "Mary Ann"). An @ inside an email address never counts. Up to 20 people per message, on text messages and photo captions.
  - Mentions are shown in bold, and a mention of you, or @everyone, is highlighted. They reach the person even at "Important only", with a notification-center item ("Alex mentioned you: …"). Someone who is both replied to and mentioned gets only the reply. The Mentions switch (NOTIF-4) turns the push off; the message then reaches them like any other.
  - @everyone is for admins only, and reaches everyone on the team as a mention. A member typing "@everyone" names nobody.
  - Editing a message doesn't notify anyone new.
- **CHAT-15 · Edit (MVP), pin and announce (v1.1).** All built: editing in the MVP, pins and announcements in task 135.
  - **Edit** your own messages; edited messages are marked "edited", and quotes in replies follow.
  - Admins can **pin** up to 3 messages to a bar at the top of the chat, from the message menu (Pin, Unpin). The bar shows the newest pin first, "Pinned 1 of 3" when there are several; tapping it opens that message, loading older messages if needed, and moves on to the next pin. Pinned messages say "Pinned" beside their time. A fourth pin is refused with "Unpin one first." Deleting a pinned message takes it off the bar. Not on an archived team.
  - Admins can send **announcements**: + → Announcement, then the next text message is one ("Announcement: notifies everyone on the team, even at Important only", with ✕ to cancel). It shows with a megaphone and "Announcement" in the chat, and notifies everyone who hasn't turned the team off or muted it, even at "Important only", with a notification-center item ("Announcement from Coach: …"). It stands in for the reply and mention notifications. There's no switch to turn announcements off; muting the team or setting it to Off does.
- **CHAT-16 · v1.1 · Files in chat.** Attach any document type; it's also saved to the Documents tab.
- **CHAT-17 · Later.**
  - Message search, which needs a search service or SQL (ARCH §12).
  - Link previews, GIFs, video, voice notes.
  - Typing indicators and read receipts.

- **CHAT-18 · MVP · Chat look.** Team admins choose the chat's message color and background (Plain; Sprinkles, small candy-colored dashes; or a photo), which everyone on the team sees, with text kept readable (WCAG AA). The colors are seven candies, Blue raspberry, Bubblegum, Grape, Mint, Lemon, Tangerine, and Cherry, and the team color last. Each theme draws a candy in its own shade, with dark text on it; the team color has white or dark text, whichever reads better. Nothing picked is the theme's own color, the first candy: Blue raspberry, or Lemon in Gumdrop Candy, which lists Lemon first. A color picked from the old 13-color palette before 1.1 still shows as it was, with Team color marked.
- **CHAT-19 · MVP · Direct messages.** Owner's request (2026-10-16): "add a direct messaging feature that allows users to directly message each other." Q5 had put them after launch.
  - **The same chat, for two.** A conversation works as a team's chat does: text, photos (CHAT-3), replies (CHAT-13), reactions (CHAT-6), editing and deleting your own (CHAT-8, CHAT-15), delivery states and the offline queue (CHAT-4), links (CHAT-5), the read position across devices, and the language filter (SAFE-7). What belongs to a team isn't there: polls, announcements, @mentions, pins, the chat look, and system lines.
  - **Who you can message:** anyone you share a team with who has joined (not "Not joined yet"), from **Message** on their page (TEAM-15) or their roster card (TEAM-3), or from **New message** in Messages, which lists the people your rosters show you (TEAM-3) with the teams you share, searchable by name. A suspended team doesn't count. Once started, a conversation stays, even when you no longer share a team.
  - **Messages:** the two-bubbles button in the header, beside the bell, on every screen size. It counts the conversations with unread messages, muted ones left out, and opens Messages: your conversations, newest first, each with the other person's photo and name, the newest message ("You: …" for yours), when, and how many you haven't read (gray when muted). A conversation shows there once it has a message. **New message** starts one.
  - **A conversation:** the other person's photo and name at the top, which open their page, and a menu with Profile, Mute or Unmute (pushes only; unread counts stay, NOTIF-3), and Block or Unblock. An empty one says "Say hi to Jordan. Only the two of you see this conversation."
  - **Private.** Only the two people read it, not super admins, who can read team content (LEGAL-1). A report (SAFE-1) shows super admins what was reported, and they act on it from the admin panel.
  - **Blocking (SAFE-2).** You can't message someone you blocked: the composer says so, with Unblock. Someone you blocked can still send, unknowing, but nothing reaches you: their conversation leaves your Messages, their messages are collapsed if you open it, and you get no notification. Nobody is told they're blocked.
  - **A deleted account (AUTH-10).** The other person keeps the conversation, read-only, with the messages from "Deleted user", and can still delete their own. A conversation nobody is left in is deleted with everything in it.
  - **Photos:** a conversation holds up to 50 MB of photos, apart from any team's storage (STORE-1). Once full it says so, and text still sends.
  - **Limits (SAFE-5):** 20 new conversations per person per day; sending is spaced as in team chat, 1 message a second.

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
  - **Upcoming** (default): a list grouped by day. Each row has a date block, an event-type color and icon, the title ("vs. Eagles"), time, location, your RSVP (one per linked player, plus a Me row for admins and members not linked to a player, but never for a member who is a player), and the counts: players going, with others counted apart ("12 of 15 players going · 2 others"), or everyone together on a team with no players ("12 going · 3 maybe · 2 no", PLAYER-6).
  - **Past**: the same list, newest first.
  - **Calendar**: a month grid with a dot for each event; tap a day to see its events.
- **SCHED-2 · MVP · All my teams.**
  - A toggle that merges every team's events into one schedule, each labeled with its team's name and color. For members linked to players on several teams, each event also names their player (PLAYER-9).
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
  - **Reminders:** defaults from Team admin. Choose any of 15 min, 1 h, 2 h, 1 day, 2 days, or 1 week before.
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
  - Large **Going / Maybe / Not going** buttons, with an optional note ("Leaving at halftime"). Members linked to players get one set per player, and admins and members not linked to a player get a Me set, unless they're a player themselves (PLAYER-6).
  - The same buttons without opening the event (the owner's request, 2026-10-26): on the schedule list, my answer on an upcoming event I can still answer is a button that opens them in a sheet (a panel on wide screens), with All my players, a set per person, Maybe where the team allows it, Clear, a note, and **See event**. The rest of the card opens the event.
  - Attendee lists grouped by Going, Maybe, Not going, and No response, with notes. The lists show players and who answered for them, with coaches and others listed apart.
  - Actions for everyone: Add to calendar, Share, Directions.
  - Admin actions: Edit, Cancel event, Delete, Set RSVP for a member or player.
  - **Duplicate**, for anyone who can create events (SCHED-3).
  - Events in a series show "Repeats weekly on Tue and Thu until Dec 17".
- **SCHED-5 · MVP · RSVPs.**
  - One tap, instant, and it works offline.
  - Change your answer any time before the deadline; after it, only admins can change answers.
  - The requirement was Going / Not going. **Maybe** is a recommended addition: on by default, and each team can turn it off (TEAM-5).
  - Not answering shows as "No response". **Clear**, beside the note, takes an answer back to No response; whoever may give the answer may clear it, under the same deadline.
  - On every team, there's one RSVP per event and participant: each active player, answered by the member who is the player, its guardians, or admins, and members answering for themselves (PLAYER-6).
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
- **SCHED-8 · MVP · Reminders.** A push at each reminder time to people who said Going or Maybe or haven't answered, but not Not going: "Reminder: Practice today at 6:00 PM · Riverside Park". For players, reminders go to the member who is the player and to the player's guardians (PLAYER-7).
  - **A reminder by hand:** the event's menu has **Post a reminder in chat** for team admins and the event's creator, after asking. It posts the event in the chat again, marked Reminder, with its live RSVPs, the answer buttons, and how many players haven't answered, and the same people get the reminder push. Not on a canceled or finished event; once an hour per event.
- **SCHED-9 · MVP · Time zones.**
  - Times show in the viewer's local time.
  - If the event's time zone is different, both appear: "6:00 PM CDT · 7:00 PM your time".
  - All-day events never shift to another day.
  - Time zones are shown by the names people know them by (the owner's request, 2026-10-26): the US and Canada's first, as "Central Time (Chicago)" or "Mountain Time (Phoenix)", then the rest of the world by city and offset from GMT, "Berlin (GMT+1)", in Create team, Team settings, and the event form. Search finds a zone by its name, city, or ID. What's stored is still the IANA ID ("America/Chicago").
- **SCHED-10 · MVP · Add to calendar.** The native calendar sheet on iOS and Android; an .ics download on web.
- **SCHED-11 · v1.1 · Calendar subscription.** Built (task 138). A private link that keeps Google, Apple, or Outlook Calendar in sync with the schedule, so a time change or a rainout reaches the calendar a player or guardian already checks (ARCH §6.15).
  - **Where:** **Calendar link** on Team info: a link for that team, or, under **All my teams**, one for every team you're on, including teams you join later. A link is made only when asked (**Make my calendar link**).
  - **Adding it:** buttons for Google Calendar, Apple Calendar (on an iPhone, iPad, or Mac, where its links open), and Outlook, and **Copy link** for anything else. Google Calendar adds links on its website, not in its phone app: on a phone the button opens the website, and once it's added the calendar shows in the app too.
  - **What's in it:** every event from 60 days back through the next 12 months, with its title (a canceled one starts "Canceled:"), time (all-day events stay on their dates, SCHED-9), place, notes, arrival time for games, and a link that opens it in Battleplan. A link for all your teams puts the team's name before each title. Nothing else: no names, answers, or roster.
  - **Staying in sync:** each calendar app checks the link on its own schedule. Apple Calendar and Outlook check about every hour; Google Calendar can take up to a day. The screen says so, and when a calendar last checked the link.
  - **It's private:** anyone with the link sees that schedule, so the screen says not to share it. **Reset link** turns off the old link (calendars using it stop updating) and makes a new one; **Turn off** stops it. Each person has at most one link per team and one for all teams.
  - **Leaving:** once you leave a team or are removed, its events drop out of your links. A disabled or deleted account's links stop working.
- **SCHED-12 · v1.1 · Follow-ups.**
  - Admins can "Nudge" people who haven't answered; it also happens automatically 24 h before the RSVP deadline.
  - Guest counts (+1, +2).
- **SCHED-13 · Later.**
  - Attendance tracking: who actually came.
  - RSVP and attendance reports with CSV export.
  - Game scores.
  - Volunteer and snack sign-ups (built as assignments, SCHED-15).
  - Carpools.
  - Season availability surveys.
- **SCHED-14 · v1.1 · Answering without opening the app.** The people who don't answer tend to be the ones who rarely open the app, so they can answer from an email (ARCH §6.15). Built for now as a button (task 286), at the owner's request: emails go out only when a coach sends them.
  - **Email people who haven't RSVP'd**, in the event's menu, for team admins and the event's creator, while the event takes RSVPs, hasn't started, and is before its deadline. It emails everyone linked to a player with no answer yet (the player, when they're on the team, and their guardians), one email per person naming their players, but not the person sending. It asks first, with the count ("Email 3 people who haven't RSVP'd?"), and says when there's no one to email. Once an hour per event, up to 100 people.
  - **The email** names the team, the event, its time and place, and asks "Is Emma going?" ("Are you going?" for a player's own email) with **Going**, **Maybe** (when the team allows it, TEAM-5), and **Not going**, and says who sent it.
  - **Answering:** each answer opens a small page on getbattleplan.app with that answer picked, an optional note, and **Send**. Opening the link never answers by itself, because email services open links to check them; Send does. No sign-in: the link works only for that person, that event, and the players it names, until the event starts or its deadline passes, and it can change the answer until then. The page says who's answering, and offers to open the event in Battleplan.
  - Every answer follows SCHED-5 (the deadline, whether Maybe is allowed, who may answer for whom) and is recorded as that person's answer.
  - **Later** (tasks 287 to 290): Going, Maybe, and Not going buttons on event notifications (the iPhone and Android apps show all three; Chrome and Edge show Going and Not going), and reminder emails sent on their own to people who can't get notifications, with **Stop these emails** and a Settings switch.
- **SCHED-15 · 1.1 · Assignments.** An event can have assignments: tasks such as **Snacks**, **Drinks**, **Scorekeeper**, or **Other** (the admin names it, "Field setup"), each with optional details ("Halftime oranges") and at most one person. They're a secondary part of the event, so an **Assignments** row sits near the bottom of the event's page, under who's coming: "3 of 4 taken", or "You: Snacks" for your own. It shows for members once the event has assignments, and always for admins, to add the first. It opens the list (route `/g/{groupId}/schedule/e/{eventId}/assignments`).
  - **Volunteering:** anyone on the team taps **Volunteer** on an open task, and **Drop out** on their own. Guardians volunteer as themselves. If someone else took it a moment before, the app says so.
  - **Admins** (and super admins, §3) add assignments (up to 20 an event), assign anyone on the team (or assign someone as they add it), make a task open again, edit its kind and details, and remove it.
  - Each task shows who has it: "Open", "You", "Alex Kim volunteered", or "Assigned to Alex Kim".
  - Assignments go with their event when it's deleted, and with the team. Someone who leaves the team, or deletes their account, comes off their tasks, which are open again.
  - No notifications yet (a reminder for the person on a task would be a later addition).

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
  - **Photos** is built (the owner's go, 2026-10-26): the first row of the Documents tab opens every photo shared in the team's chat, newest first, as a grid of squares, without deleted messages or people I blocked. A tap opens the chat's photo viewer, which swipes through them, with Share and Save. Folders aren't built yet.
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
  | Player request: a claim or a pending player (PLAYER-3, PLAYER-4) | Team admins | **Yes** | ✓ | MVP |
  | Player request approved | The member who asked | **Yes** | ✓ | MVP |
  | Content reported | Team admins | **Yes** | ✓ | MVP |
  | Storage 90% full, or full (STORE-3, STORE-4) | Team admins | **Yes** | ✓ | MVP |
  | @mention (CHAT-14) | The people mentioned; everyone, for an admin's @everyone | **Yes** | ✓ | v1.1 (built) |
  | Announcement (CHAT-15) | Everyone except the sender | **Yes** | ✓ | v1.1 (built) |
  | Direct message (CHAT-19) | The other person in the conversation | **Yes** | — | MVP |
  | RSVP nudge | People who haven't answered\* | **Yes** | ✓ | v1.1 |

  \* For players, these go to the member who is the player and to the guardians of the matching players, plus members who answered for themselves (PLAYER-7).

  Plain chat messages and direct messages don't appear in the notification center; unread counts and Messages cover them (CHAT-9, CHAT-19).

  Admins can email the people who haven't RSVP'd, who answer from the email (SCHED-14). Answer buttons on pushes, and reminder emails sent on their own, come later.
- **NOTIF-3 · MVP · Notification settings for each team.**
  - Set them from Team info ("Notifications for this team") or from Settings → Notifications. They sync across your devices.
  - **Level:** All activity (default), Important only, or Off.
  - **Mute** for 1 hour, 8 hours, 1 week, or until unmuted. Muted teams show a muted icon, and their unread counts turn gray.
  - These settings control pushes only. Notification-center items and unread counts still appear, so nothing is lost.
- **NOTIF-4 · MVP · Global switches.** Settings → Notifications has switches for Messages, Direct messages (CHAT-19), Replies, Mentions (v1.1, CHAT-14), Polls, New events, Event changes, Reminders, and Documents. They apply to every team. Announcements have no switch (CHAT-15).
- **NOTIF-5 · MVP · Wording.** The title is the team name, or for a direct message the sender's name, with the message alone as the text ("See you at 6", "Sent a photo", CHAT-19). Examples:
  - "Alex: Field 3 is open"
  - "Alex replied to you: Sounds good"
  - "Alex mentioned you: Can you bring the cones?" (CHAT-14)
  - "Announcement from Coach: No practice Friday" (CHAT-15)
  - "Alex sent a photo"
  - "Alex created a poll: Pizza after the game?"
  - "New game: vs. Eagles · Sat Oct 18, 10:00 AM"
  - "Emma, Liam: Practice today at 6:00 PM" (to a guardian; no names for a member's own player)
- **NOTIF-6 · MVP · Tap to open.** Tapping a notification opens the exact message, poll, event, or document, switching teams if needed.
- **NOTIF-7 · MVP · While the app is open.** A small in-app banner appears instead of a system notification. Nothing appears if you're already in that team's chat, or in that conversation (CHAT-19).
- **NOTIF-8 · MVP · Grouping.** The phone's notification list groups Battleplan notifications by team.
- **NOTIF-9 · MVP · Web.**
  - Browser notifications work after permission is granted, even with the tab closed.
  - On iPhone and iPad they work only after "Add to Home Screen". iOS Safari users see a tip saying so. Once the iPhone app is listed (Phase 4), the tip also links to the App Store.
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
  - Mention notifications. Built with CHAT-14 (task 135).
  - A "Hide message text in notifications" option.
- **NOTIF-13 · Later.**
  - Quiet hours.
  - Email for anything beyond event reminders and nudges (SCHED-14), or a daily digest.
  - SMS, which costs money per message.

### 6.10 Profile and settings (SET)

- **SET-1 · MVP · Profile.** Photo (cropped to a circle) and display name, used on every team, at the top of **Profile** (§5.1). The email shows on Sign out ("Signed in as …"); it changes in Sign-in methods.
- **SET-2 · MVP · Appearance.** Five themes, each shown as a small preview: **Gumdrop Army** (the default), **Gumdrop Pop Dark**, **Gumdrop Pop Light**, **Gumdrop Candy**, and **Gumdrop Arena** (§7.4, 1.1). **Themes** lays the previews out five across where they fit, otherwise in rows of three. It's a card on Profile, which names the theme in use (§5.1). The change applies instantly, is remembered on the device, and syncs to the account. System is no longer offered: an account or device still set to it, or never set, gets the default, Gumdrop Army; new accounts start on it.
- **SET-3 · MVP · Notifications.** Global switches (NOTIF-4) and each team's level (NOTIF-3). Later, **Email reminders when I can't get notifications** (SCHED-14). Calendar links are in each team's menu (SCHED-11).
- **SET-4 · MVP · Sign-in methods** (AUTH-8).
- **SET-5 · MVP · Blocked people.** View the list and unblock.
- **SET-6 · MVP · About and account.**
  - App version, Terms, Privacy Policy, open-source licenses.
  - Contact support.
  - Sign out; Delete account (AUTH-10).

### 6.11 God admin panel (ADMIN)

This is for platform operators (super admins) to manage every team and user.

**Access and layout**

- Only super admins see it: it's on their Profile, at `/admin`.
- It's designed for a desktop browser but works on phones, where tables become lists.
- It's loaded separately, so regular users never download it.

**Requirements**

- **ADMIN-1 · MVP · Dashboard.** Totals for:
  - users and teams (direct conversations, CHAT-19, aren't teams and don't count);
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
    - **View team**: opens its tabs without joining, with a "Viewing as super admin" banner, and recorded in the audit log. Team info, the roster, schedule, documents, and Team settings work as §3 gives super admins; posting, voting, and RSVPing for themselves need them to join.
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
  - A report from a direct conversation (CHAT-19) says **Direct message** instead of a team, and offers delete the message, disable the person, or dismiss: there's no team to remove anyone from or suspend.
- **ADMIN-6 · MVP · Audit log.**
  - Records every admin or destructive action: who, what, which team, when, and before/after values.
  - Filter by person, action, team, or date.
  - Read-only, kept for 1 year.
- **ADMIN-7 · MVP · Platform settings.**
  - Whether anyone can create teams, and the teams-per-person-per-day limit.
  - Storage per team, for every team without its own limit (STORE-1, STORE-6), and maximum upload size.
  - Support email.
  - Whether super admins get alert emails about new accounts and teams (ADMIN-9).
  - A banner announcement for all users, with text, severity, and an end date.
- **ADMIN-8 · MVP · Safeguards.**
  - Destructive actions require confirmation.
  - Every admin action writes an audit entry.
  - Nobody can set or see another person's password. Admins can only send setup and password-reset emails (AUTH-6).
  - The Privacy Policy states that super admins can access team content for moderation and support (LEGAL-1).
- **ADMIN-9 · MVP · Alert emails.** Every super admin gets an email, at the owner's request:
  - **New account:** when someone finishes first-run setup (AUTH-5), once: their name, email, how they sign in, and whether a team admin added them first (AUTH-6), linking to them in the admin panel. Someone who signs in but never finishes setup isn't counted.
  - **New team:** who created it and its sport, linking to it in the admin panel.
  - **Team deleted:** who deleted it (the owner, or a super admin) and how many members it had, linking to its audit entries.
  - Platform settings (ADMIN-7) has **Email super admins about new accounts and teams**, on by default. Report alerts (SAFE-4) always email.
  - An email that fails never stops what it's about; it's logged.

### 6.12 Safety and moderation (SAFE)

The App Store requires these for apps with user-generated content (guideline 1.2), and they matter more once anyone can create a team.

- **SAFE-1 · MVP · Report.**
  - Report a message, document, or person.
  - Reasons: Spam, Harassment or bullying, Inappropriate content, or Other, plus optional details.
  - The report goes to the team's admins (Team info → Reports) and to the super-admin queue; a report about one of the team's admins goes to the super-admin queue only (SAFE-4). The form says so before it's sent.
  - The reporter gets a confirmation that it will be reviewed within 24 hours. The reported person is never told who reported them.
  - A report from a direct conversation (CHAT-19) goes to the super-admin queue only, since a conversation has no admins. The form says so.
- **SAFE-2 · MVP · Block.**
  - Hides that person's messages from you (collapsed) and stops notifications from them, in every team.
  - They aren't told.
  - Blocking doesn't remove anyone from a team.
  - In direct messages (CHAT-19) you can't message someone you blocked, and what they send never reaches you: their conversation leaves your Messages, and you aren't notified.
- **SAFE-3 · MVP · Terms.** Everyone accepts the Terms of Use at sign-up, including zero tolerance for objectionable content and abusive behavior.
- **SAFE-4 · MVP · Acting on reports.**
  - Team admins act in their own team: delete content, remove members.
  - Super admins act anywhere: disable accounts, suspend teams.
  - Goal: act on every report within 24 hours.
  - Every super admin gets an email for each new report, about any team: the team, what was reported (a message, a person, or a document), and the reason, never who reported it or what was said, with a link to the reports queue. A report about one of the team's admins says only super admins see it.
  - While any report has been open more than 12 hours, super admins get one reminder email a day saying how many are waiting and how old the oldest is.
- **SAFE-5 · MVP · Rate limits and abuse controls.**
  - **Limits**, defined in one place (full table in ARCH §6.9):

    | Action | Limit |
    |---|---|
    | Sending messages | 1 per second per person per team |
    | Creating teams | 5 per person per day (super admins can change it, ADMIN-7) |
    | Email invites | 50 per person and 200 per team per day |
    | Adding people or players by email | 200 per team per day |
    | Invite code attempts | 20 per person per hour |
    | Player claims and added players | 10 per person per day |
    | Reports | 20 per person per day |
    | Starting direct conversations (CHAT-19) | 20 per person per day |
    | Reposting an event to chat | 1 per event per hour |
    | Web error reports | 30 per IP address per hour |
    | Security notice emails | 10 per person per day |
    | Alert emails to super admins | 50 a day in all (the daily report reminder always goes) |
    | Profile photos | The newest 3 per person, plus the one in use |

  - Real people shouldn't notice them. The app spaces messages automatically, and anyone who hits a limit sees "Slow down, try again in a minute" without losing what they typed.
  - A verified email is required to create teams, send email invites, or add people by email.
  - App Check blocks traffic that doesn't come from the real apps.
  - Every team has a storage limit (STORE-1).
  - Super admins can disable people and suspend teams (ADMIN-3, ADMIN-4).
- **SAFE-6 · MVP · Adults only.**
  - Accounts are for adults 18 and older (AUTH-5, Terms of Use).
  - Players never get accounts of their own. Youth players never sign in. The roster shows only a name and number, and optional details are seen only by admins and the player's linked people (PLAYER-10, PLAYER-12).
- **SAFE-7 · MVP · Language filter.** Apple asks apps where people post content for a way to filter objectionable material (guideline 1.2).
  - Swear words and slurs in chat messages, photo captions, and polls are masked when they're posted, keeping the first letter: "What the f***".
  - Whole words only, ignoring case, so "Scunthorpe" and "cockpit" stay as they are; links are left alone.
  - The words are listed once, in `shared/strong_language.json`, for the app and the server.
  - On for every team; admins can turn it off in Team admin (TEAM-5). It applies to what's posted, or edited, while it's on.
  - The app masks before it sends, so the sender sees the masked text at once. The server masks anything that gets past an older app before the chat preview and the push are written, and masks imported chat history (IMPORT-9) too.

### 6.13 Privacy and legal (LEGAL)

- **LEGAL-1 · MVP · Policies.**
  - Privacy Policy at `/privacy` and Terms of Use at `/terms`, on the website (WEB-2).
  - Linked from sign-in, Settings, the store listings, and the Apple developer settings.
  - The Privacy Policy covers:
    - what we collect: name, email, photo, messages, files, the phone number and email members choose to share with a team (TEAM-10), device tokens, usage analytics, crash reports, and the player records members enter on any team (name, jersey number, walk-up song, plus the optional details in PLAYER-12: date of birth, emergency contacts, and notes, seen only by the team's admins and the player's linked people). Some player records are managed by parents and may be children's. Battleplan collects no health information;
    - that super admins can access team content for moderation and support, and see a direct message (CHAT-19) only when it's reported;
    - how long data is kept;
    - how to delete it.
  - The Terms of Use require account holders to be 18 or older.
- **LEGAL-2 · MVP · No tracking.**
  - No ads, no selling data, no cross-app tracking, so no App Tracking Transparency prompt.
  - Analytics runs without advertising IDs.
- **LEGAL-3 · MVP · Deletion.** In-app account deletion (AUTH-10), plus a public `/delete-account` page explaining how to request deletion (required by Google Play).
- **LEGAL-4 · MVP · Store disclosures.** The App Store privacy labels (Phase 4) and the Google Play Data safety form (Phase 5) match LEGAL-1, with the answers written once in [STORE-PRIVACY.md](STORE-PRIVACY.md), and so does the iPhone app's privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`): no tracking, the data types the policy lists, and the reasons for the APIs Apple asks about (stored preferences, file timestamps in the app's own container, and elapsed time). Info.plist also declares no non-exempt encryption (`ITSAppUsesNonExemptEncryption` false): the app's only encryption is HTTPS.
- **LEGAL-5 · Phase 6 · Facebook data deletion.** Facebook's data-deletion URL comes back with Facebook sign-in in Phase 6 (Q16).
- **LEGAL-6 · MVP · Retention.**
  - Content stays until its author, an admin, or the team's deletion removes it.
  - Deleted content is erased from the database immediately and from backups within 7 days. No backup, in Google Cloud or off-site, is kept longer than 7 days (ARCH §6.12).
- **LEGAL-7 · Phase 2 · GDPR and EU.** Done in Phase 2, after the web go-live (§9):
  - the Privacy Policy's EU sections: who the controller is, the lawful basis for each use, people's rights (access, correction, erasure, portability, objection), how to complain to a data protection authority, and transfers to the US under each provider's data processing terms;
  - **Download my data** in Settings → Account, a file with the person's profile, memberships, messages, RSVPs, and player links, plus the details of the players they're linked to (PLAYER-12);
  - no special-category data: player details (PLAYER-12) hold no health information, since medical notes were removed on 2026-10-20 at the owner's request;
  - no cookie banner needed: the website sets no cookies, the web app stores only what sign-in and the offline cache need, and Google Analytics on the web is off for EU visitors or asks first;
  - the EU Digital Services Act basics: a point of contact, Report as the way to flag content, and a reason given when content is removed;
  - a data breach plan, with notice to the authority within 72 hours.

### 6.14 Free for everyone, and team storage (STORE)

**Everything is free, with no ads.** Every team gets every feature. Ads may come later, once enough teams use Battleplan to justify the work; any ads plan has to respect children's privacy rules, because parents and guardians manage youth players' records in the app (ROADMAP "Ads, later"). [PLANS.md](PLANS.md) summarizes this.

What does cost money as teams grow is storage, so each team has a limit, and admins can see and free their space.

**Requirements**

- **STORE-1 · MVP · A storage limit per team.**
  - Each team can store **200 MB** (500 MB until 2026-10-15), the default for every team without its own limit (STORE-6), which super admins change in platform settings (ADMIN-7): chat photos, documents, the team logo, and the chat background all count (ARCH §6.8).
  - Saving platform settings puts every team without its own limit on the default, existing teams too, and says how many moved. A team already using more than its new limit is full until it frees space (STORE-4), and its admins are told.
  - A single file can be at most **10 MB** (chat photos are resized well under that before upload).
- **STORE-2 · MVP · Storage used.** Team admin shows "112 MB of 200 MB used" with a meter, for the team's admins.
- **STORE-3 · MVP · Nearly full.** At **90%**, the meter turns amber, the team's admins see a warning at the top of the team ("Storage is 90% full. Free up space in Media."), and they get a notification (NOTIF-2).
- **STORE-4 · MVP · Full.**
  - New uploads (chat photos, documents, the team logo, a chat background), attachments, and **scheduling new events** are disabled until storage is freed up.
  - Everyone on the team sees: "Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up." Admins also get a notification.
  - Nothing else turns off: text messages, replies, reactions, polls, RSVPs, and existing events keep working. Nothing is ever deleted automatically.
- **STORE-5 · MVP · Media (admins).**
  - Team info → **Media** lists every photo, attachment, document, the team logo, and the chat background, largest first, with a preview, size, who added it, and when.
  - Admins delete items to free space, after confirming. Deleting a chat photo removes it from its message, and a message left with no text or photos reads "Photo removed by a team admin"; deleting the logo or background resets it.
- **STORE-6 · MVP · A team's own limit.** A super admin can give one team its own limit, higher or lower than the default, from the admin panel (ADMIN-3) or from Team admin while signed in as a super admin, and put it back on the default with **Use the default**. A team with its own limit keeps it when the default changes. The option isn't announced or advertised anywhere.
- **STORE-7 · Later · Ads.** See ROADMAP "Ads, later".

**Acceptance (MVP)**

- A team at 90% sees the warning and its admins are notified once.
- A full team can't upload or attach, even by calling the database directly, and still chats.
- Deleting photos in Media frees space within seconds, and uploads work again.
- A super admin raises one team to 2 GB and only that team can store more.

---

### 6.15 Import and migration (IMPORT) · GroupMe, TeamSnap, TeamReach, GameChanger, and Google Calendar built

Requested 2026-10-13. Built at the owner's request: GameChanger's events (2026-10-15, IMPORT-7, ROADMAP task 241), then GroupMe's messages, documents, and events, TeamReach's events, Google Calendar's events, and TeamSnap's events, players, and documents (2026-10-15, IMPORT-8 to IMPORT-11, tasks 249, 250, 252, and 254). This does not block the initial go-live. The website's Questions explain each app's steps (task 253).

- **IMPORT-1 · Source and destination.** Team admins choose a supported source and a Battleplan team they administer. Each adapter documents the verified export format or API, required permissions, supported categories, and known losses. Importing history does not create accounts, memberships, or invitations automatically.
- **IMPORT-2 · Independent choices.** Messages, Documents, and Events/calendar have separate selections. A category is selectable only when both the adapter and the supplied export or connection can provide usable data. Unavailable categories explain why. Documents and events do not depend on selecting messages; message photos are identified separately from documents.
- **IMPORT-3 · Preview.** Before importing, show available categories, counts, sample content, date ranges, destination, storage estimate, and skipped or unsupported data. Require at least one available category and explicit confirmation. Do not infer structured events from ordinary message text.
- **IMPORT-4 · Preserve history.** Keep source IDs, original timestamps, and author names where available; distinguish imported authors from signed-in Battleplan users. Preserve event time zones. Copy supported accessible files into team storage within existing limits. Explain any loss of reactions, replies, recurrence, RSVPs, or attachments. Never overwrite unrelated existing content.
- **IMPORT-5 · Jobs and results.** Show progress, cancellation, and a completion report with imported, skipped, and failed counts per category. Retries and repeat imports must not duplicate previously imported source items. Imports enforce team permissions and storage limits and suppress historical chat, mention, email, and reminder notifications; future imported events use normal reminder behavior after completion.
- **IMPORT-6 · Discovery first.** Each source's export or API is checked before it's built: what it holds, what it needs, and what can't come along. GroupMe's [data export](https://support.microsoft.com/en-us/groupme/how-do-i-export-my-groupme-data) was checked against a real export published on GitHub and GroupMe's own web app (IMPORT-9); its [API](https://dev.groupme.com/docs/v3) isn't used, since its terms limit exports to a person's own content.
- **IMPORT-7 · GameChanger events (built).** GameChanger has no export file or public API. Its supported path is the team's calendar link, an iCalendar feed: in the GameChanger app, open the team, tap the gear, then **Schedule Sync**, **Sync Schedule to Your Calendar**, and **Copy Calendar Link**. Coaches, players, and parents get every event from it; followers get only games. Team admins open **Import** from the team menu, paste the link or choose a downloaded `.ics` file (up to 1 MB), and preview before anything is added. Only **Events** can be chosen: GameChanger exports no chat and has no team documents, and RSVPs and attendance aren't imported.
  - Each event keeps its title, notes, place and address, start and end or all-day dates, and time zone: the event's own, then the calendar's, then the team's. GameChanger's own feeds (checked with a real team's link, 2026-10-15) give times in UTC with no zone, so they show in the team's zone, and put the team's name before every title ("Thunder 12U Practice"), which is dropped ("Practice"); other calendars' titles stay as people wrote them.
  - Games are found by "vs." (home) or "@" (away), and the opponent comes from the title. Practices, meetings, and social events are found by keywords; anything else is Other.
  - Daily and weekly repeats become single events, from a year back to a year ahead. Other repeat patterns, canceled events, and past events (unless **Include past events** is checked) are left out, and the preview lists them with the reason.
  - Imported events don't post to the chat or send a new-event notification. They have RSVPs on and the team's default reminders, so future ones remind as usual.
  - Importing again adds only events that are new. Events imported before stay as they are, including any changes made in Battleplan.
  - One import adds up to 500 events and runs while the screen waits, so it needs no job, progress, or cancellation (IMPORT-5's jobs are for message imports). A team can import or preview 30 times a day. A full team can preview but not add.
- **IMPORT-8 · TeamReach events (built).** TeamReach has no public API or export file. Its terms forbid copying "roster data, contact information, schedules, message history" without its written permission (checked 2026-10-13, ROADMAP task 225); the owner chose to offer the schedule anyway, read from the calendar (iCal) link TeamReach gives its users for calendar apps, and nothing else. It imports exactly as IMPORT-7, under TeamReach's name: canceled events say "Canceled in TeamReach". Messages and Documents show as unavailable, with why. The menu path to TeamReach's link hasn't been checked against a real team yet, so the app's steps describe it generally.
- **IMPORT-9 · GroupMe messages, documents, and events (built).** From GroupMe's data export: on a computer, at web.groupme.com, the profile picture, **Export my data**, then **Create export**, choosing only the team's group if GroupMe asks which chats to include (GroupMe's help shows a chat picker; on 2026-10-15 the export took every chat). It's downloaded from **Export my data** when it's ready; a large export comes in parts, each imported on its own. An export of every chat is fine: only the picked group is read and uploaded, and the rest never leaves the device. The admin chooses the export's `.zip` in Import; the app reads it on their device (up to 2 GB), lists its group chats (direct messages are left out), and the admin picks the group. Messages, Documents, and Events are chosen separately, each available only when the export has some.
  - **Messages** keep their writer's GroupMe name and their original time, in order, and show "from GroupMe" beside the name; no Battleplan account wrote them, so they can be reported but their writers can't be blocked. Replies keep their quote. Photos come too (a choice of their own), into the team's storage. A shared place keeps its name. GroupMe's notices (who joined, who renamed the group), likes, polls' options and votes, videos, deleted messages, and GroupMe's own emoji are left out, and the preview counts what's left out.
  - **Documents** are the files shared in the group, of the kinds and sizes Documents takes (PDF, Office files, text, CSV, and pictures, up to 10 MB each). "Added by" names who shared it in GroupMe, and each keeps the date it was shared.
  - **Events** come from the export's calendar data, as IMPORT-7 imports them. GroupMe's chat names events but doesn't say when they are, so an export without calendar data offers no events, and says why.
  - The preview shows the counts, the dates, the latest messages, the files, the events, the photos' and files' size against the team's free space, and what's left out. Importing shows its progress and can be stopped between batches; what's done stays. A team whose storage fills partway keeps getting messages, without the photos and files that didn't fit.
  - Nothing imported notifies anyone. Importing again adds only what's new, and leaves what came before as it is.
- **IMPORT-11 · TeamSnap events, players, and documents (built).** Checked 2026-10-15 against TeamSnap's help center, real feeds, and its API (live, but its docs are offline and new apps may not be able to register, so it isn't used). **Events**, **Players**, and **Documents** are chosen separately; **Chat** shows as unavailable, because TeamSnap has no way to export chat. One preview covers all of them, then one import.
  - **Events** come from the schedule's calendar link (on the web: Schedule, **Settings**, **Sync Calendar / Export**; on an iPhone: Schedule, the share button, **Subscribe**), up to 6 months back, imported as IMPORT-7. TeamSnap puts the team's name before every title: "Thunder at Eagles" is an away game (@ Eagles), "Thunder vs Hawks" a home one, and "Thunder - Practice" is "Practice". The place's name comes from the notes' "Location:" line, its address from the feed.
  - **Players** come from the roster's **Export**, **Export CSV File** (on the web). The admin chooses the file; names, jersey numbers, and birthdates (MM/DD/YYYY) come along, as the Add players form takes them (PLAYER-1, PLAYER-12). Coaches, managers, volunteers, and other non-players (TeamSnap's Non-Player or Member Type columns) stay behind, and so do contact details: parents and adult players link themselves by claiming players (PLAYER-3). A player already on the roster, by name, is left as it is; the preview counts them.
  - **Documents** are files the admin downloads from TeamSnap's **Media**, **Files** (TeamSnap has no download-all) and chooses together, of the kinds and sizes Documents takes. "Added by" names the admin, and choosing the same file again adds nothing.
- **IMPORT-10 · Google Calendar events (built).** A team that keeps its schedule in Google Calendar imports it from the calendar's **Secret address in iCal format** (Google Calendar **Settings**, the calendar under **Settings for my calendars**, **Integrate calendar**), or from a calendar file from **Import & export**. It imports exactly as IMPORT-7, under Google Calendar's name, with Google's repeats (daily and weekly) and time zones. Messages and Documents show as unavailable.

**Acceptance**

- Every available category can be selected alone or in combination; unavailable categories cannot be submitted.
- A preview makes unsupported and missing data clear before any team content is written.
- Importing twice or resuming after interruption creates no duplicate content and sends no historical notifications.
- A non-admin cannot import; a job cannot write to another team or exceed storage limits.
- Original author names and event times are preserved, and imported history grants nobody account access.

---

### 6.16 Whiteboard (BOARD) · Built

Requested 2026-10-15; built the same day (ROADMAP tasks 242–248). The coach's whiteboard, in **Plays** (directly after Documents in the main navigation; Coach's whiteboard until 2026-10-15), made for an iPad's touch and a laptop's mouse alike: plays are mostly drawn, shown to the team, and erased, like a real whiteboard. Saving one is optional. Plays are visual aids only: they aren't attached to events, but a saved play can be posted to the team's chat or saved as a GIF (BOARD-5). This does not block any go-live phase.

- **BOARD-1 · Four boards.** Each is drawn from a real field's measurements, with its own starting positions:
  - **Baseball** (also softball's): the field itself, with striped outfield grass, the warning track and fence, the infield dirt and grass, base paths, bases, home plate, the mound and rubber, batter's boxes, and foul lines. The board is cut to the fence, so the field fills it: the fence runs to the board's edges, and there's room behind home for the pitcher backing up the plate. The nine stand at P, C, 1B, 2B, 3B, SS, LF, CF, and RF; the other side can start with a batter, or the bases loaded.
  - **Basketball**: a half or full court, with the lane, free-throw circle, three-point line, and hoop; the five at PG, SG, SF, PF, and C, and the other side in man-to-man or a 2-3 zone.
  - **Soccer**: a full or half pitch with its boxes, arcs, and goals; 4-4-2, 4-3-3, 3-5-2, 9v9, and 7v7, for either side.
  - **Football (American), X's and O's**: yard lines, hash marks, the line of scrimmage, and the line to gain; the offense as O's in the I formation or shotgun, the defense as X's in a 4-3 or 3-4.
  - Every board starts with the ball in play: in the pitcher's hand, with the point guard, on the center spot, on the line of scrimmage. Teams of other sports get a blank board, and any board can be picked.
- **BOARD-2 · The whiteboard.** **Plays** in the main navigation opens it for the team's admins: the team's sport's board, ready to draw. Drag players, opponents, and the ball with a finger, a pencil, or a mouse to show how a play unfolds; add more; label one with a number, a position, or a roster player; draw run (solid), pass (dashed), and block or screen (T) arrows, freehand lines, and text; erase; undo and redo (and ⌘/Ctrl+Z, Delete, and Escape on a keyboard). The tools sit beside the board on a tablet or laptop and below it on a phone, each big enough for a finger. On a phone the board runs the screen's width, under one bar: the step's controls (or, with something picked, what to do with it), undo, redo, and More, which holds **Save to plays**, **New board**, **Saved plays**, and whatever else has no room. Players, arrows, and text stay the same size however big the board is drawn. A drag moves a player; a tap picks one. The drawing stays on that device until it's cleared, so leaving never loses it; **New board** starts over (asking first) on any board.
- **BOARD-3 · Steps.** A play can have up to 10 steps. A new step starts where everyone stands; **Play** moves the players and the ball smoothly from each step to the next.
- **BOARD-4 · Saved plays.** **Save to plays** keeps a copy, named, for the team: everyone on the team opens Plays to see them (for them it shows the saved plays), step by step. The whiteboard's bar has **Saved** (on a phone) or **Saved plays** to open them. Admins edit, duplicate, delete, or put a saved play back on the whiteboard. Positions are only labels on the drawing; nothing is saved on a player (players have no position field, ROADMAP task 234).
- **BOARD-5 · Sharing a play.** Under a saved play's steps, for everyone on the team (owner's request 2026-10-27, ROADMAP task 315):
  - **Post to chat** posts a picture of the play's last step to the team's chat, with the play's name, and goes to the chat. The picture carries an **Open play** sticker: a tap opens that play in Plays, where anyone can play its steps and stop them. A deleted play opens to "This play was deleted." The switcher's preview reads "Play: Relay", and the push "Alex posted a play: Relay". Photos (DOC-7) leaves posted plays out. Versions of the app before 1.1 show the picture and name as a photo. Archived teams don't post.
  - **Save as GIF** makes an animated GIF of the play: the first step for 1.5 seconds, each later step gliding into place over 1.5 seconds (20 frames a second), and the last step held for 3 seconds before it starts over, forever. 720 pixels on its longer side. On a phone it's saved to the photo library (asking for add-only access the first time); in a browser it's shared where the browser can, or downloaded. It's named for the play.

**Acceptance**

- Each board looks like its field or court, with its starting positions and the ball, on a tablet, a laptop, and a phone. On a phone the board, and a saved play for the team, run the screen's width.
- A coach drags players and the ball to show a play unfolding, draws arrows, adds steps, plays them back, and saves only when they want to keep one.
- Members view saved plays but can't change them; people not on the team can't read them; archived teams' plays are read-only.
- Anyone on the team posts a saved play to the chat, where its picture opens the play, and saves it as a GIF that plays its steps, holds the last for 3 seconds, and repeats.

## 7. Design system and UI

### 7.1 Brand

- **Name:** Battleplan.
- **Logo:** the Sticker Crest (owner's pick, 2026-10-26, for 1.1): a fat lemon shield tilted 7° to the left, outlined in navy on a navy hard shadow, with a white chat bubble saying B, on a blue raspberry gradient tile, plus the wordmark. The same mark is the website's favicon and header mark, the web app's tab icon and loading screen, the app icons (Android's themed icon is the shield as one shape), and the splash screens on Gumdrop Army's army green. The favicon draws the crest 10% bigger so it reads at 32 px. Before 1.1 the mark was a white flag on a pole with an angular B cut out of it (2026-10-14); the 1.0 App Store build keeps it.
- **Primary color:** blue raspberry `#4D9BFF`, the app icon's background (a gradient from `#6DB3FF` to `#2F6FDE`) and Gumdrop Pop's main accent (§7.3). Deep blue `#2F5BEA` (Q9) was the 1.0 mark's color and is still the first team color.
- **Team colors** make each team's screens its own: the color shows in the background of every screen inside the team (§7.4), and shows on the team's logo or initials badge, the switcher, and calendar dots in the all-teams view. Buttons and the candy accents keep the theme's colors, and so do my chat bubbles unless the chat look picks the team color (CHAT-18).

### 7.2 Look and feel

**Gumdrop Pop**, from 1.1 (the owner's pick, 2026-10-25): bright and playful, like candy, and still clean:

- an army-green page in the default theme (Gumdrop Army), with cream cards;
- gumdrop buttons: a rounded face on a hard lip in a darker shade, with a thin highlight along the top, that sinks onto its lip when pressed;
- candy accents, each with a meaning: blue raspberry for you and the main action, mint for Going, lemon for Maybe and pins, cherry for Not going and unread, tangerine for games, grape for practices, and bubblegum for polls, other events, and your reactions;
- chunky headings with a stacked hard shadow;
- generous rounding and whitespace;
- quick motion.

The content still carries the visual weight: messages, photos, and event cards.

### 7.3 Design tokens

| Token | Values |
|---|---|
| **Color** | Five themes (§7.4), each with a full set of roles: page, cards, raised buttons, wells, inputs, lines, text, and headings. Seven candy accents (§7.2), each with a face, a darker lip, and a shade for text on cards; text on a candy face is ink, a dark navy. Every text color is contrast-checked in every theme, under every team color too. |
| **Type** | Bundled with the app, the same on every platform: **Lilita One** for headings, **Fredoka** (500 to 700) for buttons, labels, and names, and **Nunito** (400, and 600 to 900) for body text and messages. Sizes 36 / 32 / 24 / 22 / 17 / 16 / 14 / 12 (team name, screen title, section, title, subtitle, body, secondary, label); chat messages are 16 (CHAT-1). Headings carry a stacked hard shadow: four steps on screen titles and the team name, three on sections. Gumdrop Arena sets headings and labels in **Barlow Condensed** ExtraBold Italic instead, over a single 3 px shadow; its body text is Nunito too. Layouts survive system text scaling up to 200%. |
| **Buttons** | Gumdrops: the face sits on a hard lip, 3 px under faces up to 38 px tall and 4 px above, with a highlight along its top. The main action is a candy gumdrop (the theme's own color, or a candy for its meaning); the rest are raised gumdrops in the card color. Pressed, the face sinks onto the lip; disabled, it's flat and muted. Chips, segmented buttons, the + button, and the navigation indicator are gumdrops too. In Gumdrop Arena every gumdrop leans 11° (its label stays upright) and has 7 px corners. |
| **Spacing** | 4-point grid: 4, 8, 12, 16, 24, 32, 48. Side padding is 16 on phones and 24 on wide screens. |
| **Corners** | 14 for inputs, 18 for tiles, 20 for cards and chat bubbles (6 at a bubble's tail), 22 for panels, 26 for sheets, fully round for avatars, pills, and buttons. Gumdrop Arena cuts 12 px off the top-right and bottom-left corners of cards, panels, and dialogs instead. |
| **Elevation** | No soft shadows on cards: they're flat, with a thin outline in Gumdrop Pop Light. Depth comes from the lips under buttons and the hard shadows under headings, the back button, and stickers. |
| **Icons** | Material Symbols Rounded, the same set on every platform |
| **Motion** | 150–250 ms with standard easing. Respect the system "reduce motion" setting. |

### 7.4 Themes

Five themes, picked in Profile → Themes (SET-2), from 1.1:

- **Gumdrop Army**, the default (the owner's request, 2026-10-26, from the V1 Olive design, after the owner's team t-shirt, and renamed with a darker green on 2026-10-27): an army-green page (`#474C2B`) with cream text, cream cards and buttons (`#F4EAD0`) outlined in near-black on a hard near-black lip, coral (`#F45B5B`) for your messages, the sticker, and the back button, Candy's candies outlined in near-black, and cream headings outlined in near-black over a near-black shadow. Headings on its cream cards are plain near-black, with no shadow: a coral one looked smudged (the owner's request, 2026-10-27). It keeps its army-green page in every team.
- **Gumdrop Pop Dark**: a navy page (`#0B1531`), navy cards a step lighter (`#16244A`), white text, and white headings with a blue shadow.
- **Gumdrop Pop Light**: a pale blue-gray page (`#F2F5FD`), white cards with a thin outline, navy text, and navy headings with a light blue shadow.
- **Gumdrop Candy**: a bright blue page (`#305AF6`) with white text and headings, white cards with navy text, and lemon as your color.
- **Gumdrop Arena** (the owner's request, 2026-10-26, from the V3 design): Gumdrop Pop's layout with a game-day feel. A deep violet page (`#0F0D24`), violet cards (`#221D45`), white text, the same candies, headings and labels in a condensed bold italic over one blue shadow, gumdrops that lean, and cards with two corners cut. It's kept apart in the code, so it can be taken out cleanly; an account set to it would then get Gumdrop Pop Dark.

**Team colors.** In every theme but Gumdrop Army, every screen inside a team takes the team's color (TEAM-1) in its background (owner's requests, 2026-10-26). Screens outside a team keep the theme's own. Gumdrop Army keeps its army-green page and cream cards in every team, as its design does; the team's color shows in its logo.

- **Gumdrop Pop Light** stays a light off-white page, shaded slightly toward the team color (a pale blush for Red, cream for Yellow, a gray off-white for Gray and Black), with its lines and button edges in the same hue. Its white cards, text, headings, and candies don't change.
- **Gumdrop Pop Dark, Gumdrop Arena, and Gumdrop Candy** take the team color itself as the page, not a blend, as in the Rounded Candy Pop design the picker comes from; it's a little darker only where neither white nor navy text would read on it (Green). In Dark and Arena, the cards, chat bubbles, event cards, tab bar, buttons, and inputs are a muted, dark version of the team color (a deep red for Red, a dark brown for Orange, grays for Black), each as dark as the navy (or violet) it replaces, with its text tinted to match, so every contrast stays as designed. Candy keeps its white cards. The candies don't change.
- On those colored pages, text straight on the page is white, or navy on light colors (Light blue, Yellow), with a heading shadow in the other one. Hard shadows on the page (the back button, the sticker) are navy, or the team color lifted lighter where navy wouldn't show (Navy, Maroon, Gray, Black). A candy or a button too close to the page (lemon on Yellow, Dark's buttons on Gray or Black) gets a navy edge so it still stands out, and a red team's unread badge a navy ring.
- Blue and Navy are the theme's own navy, so Dark, Light, and Arena keep their own colors for them; new teams start on Blue, so a new team looks as the theme was designed. Candy's page takes them as it takes every color.
- A team still on a retired color (Royal blue or Violet) shows as its replacement (Blue or Purple) everywhere (TEAM-5).

Photos are never dimmed. Every theme meets **WCAG AA contrast** (4.5:1 for body text), under every team color too. Every key screen has golden images in Olive, Dark, Light, and Candy, and five of them in Arena, for reviewing changes by eye (they don't fail CI), and accessibility checks, including contrast, in all five.

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
- Test with VoiceOver and TalkBack: in phone browsers before Phase 1, and in the native apps before Phases 4 and 5.

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
| **Reliability** | Nothing is lost on flaky connections (offline queue). Server functions are safe to retry. Point-in-time recovery, daily backups, and an encrypted off-site copy, none kept longer than 7 days (ARCH §6.12). |
| **Security** | Deny-by-default rules, tested for every collection and role. App Check enforced (from Phase 2). Secrets in Secret Manager. HTTPS only. No message content or personal data in logs or analytics. |
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

Milestones M0 to M8 each ended with their features working on **iOS, Android, and web**, and with rules tests updated. Go-live then happens in six phases, web first (below). The task-level order is in [ROADMAP.md](ROADMAP.md).

### M0 · Foundation

- [ ] Create the Firebase projects on the free plan (done 2026-10-10: dev `battleplan-dev-ecce4`, prod `battleplan-prod`) and build against the Emulator Suite. Paid plans and purchases wait until a phase needs them ([TODO.md](../TODO.md)): dev moves to Blaze when we first deploy Functions or Storage, and prod gets Blaze and its database, in its permanent region (ARCH §6.10), in Phase 1.
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

  Apple sign-in and iOS Universal Links need the paid Apple Developer membership. Apple sign-in joins the matrix in Phase 3, and Universal Links in Phase 4.

**Done when:** the empty app, with tabs and a theme switch, runs on iOS (Simulator or your iPhone), an Android phone, and Chrome, and every PR gets a web preview link.

### M1 · Accounts

- [ ] All four sign-in options, email verification, and password reset.
- [ ] First-run setup with the 18+ confirmation and Terms; `ensureUserProfile`.
- [ ] Account linking (AUTH-7, AUTH-8), account deletion, disabled accounts.
- [ ] The super-admin bootstrap script.
- [ ] Rules and tests for `users`.

**Done when:** the M0 sign-in matrix passes on all three platforms. Apple sign-in is verified in Phase 3, once the Apple Developer membership is active.

### M2 · Teams and invites

- [ ] Create team, team switcher, welcome screen.
- [ ] Roster screen, roles, team settings; transfer, leave, archive, delete.
- [ ] Add by email, with account creation and setup emails. Set up the email provider and sending domain.
- [ ] Invite link, QR, and code; email invites; the `/join` page; `getInvitePreview` and `redeemInvite`; Universal Links and App Links.
- [ ] Players on every team: pasted rosters, claims (as the player or a guardian), member-added players with admin approval, who's-who labels (PLAYER-1 to PLAYER-5, PLAYER-8).
- [ ] Storage quota accounting.
- [ ] Rules and tests, including **cross-team isolation**.

**Done when:** a new coach can create a team and get three people in by link, QR, and email; a person on two teams can switch between them; and a pasted roster links each player or parent to the right player.

### M3 · Chat

- [x] Message list with paging, composer, photos and viewer, reactions.
- [x] Replies, delete (through a Function), unread counts, system messages, links.
- [x] Report, block, offline states.

**Done when:** the CHAT acceptance criteria pass.

### Free for everyone and team storage · after M4

- [x] Remove the paid tier; its features are free for everyone (edit messages, 16 reactions, chat look).
- [x] 200 MB per team (500 MB until 2026-10-15) and 10 MB files; the 90% warning; full blocks uploads, attachments, and new events (STORE-1 to STORE-4).
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
- [ ] RSVPs, including Maybe and admins answering for members; per-player RSVPs with others counted apart, and notifications to players and guardians (PLAYER-6, PLAYER-7, PLAYER-9).
- [ ] Upcoming, Past, and Calendar views; All my teams.
- [ ] Repeating events (daily and weekly, skip dates, this-and-following edits, cancel, and delete) and Duplicate.
- [ ] Reminders; event cards in chat.
- [ ] Add to calendar; time zones.

**Done when:** the SCHED and PLAYER acceptance criteria pass.

### M7 · Documents

- [ ] DOC-1 to DOC-6, including the storage-full message.

### M8 · God admin panel

- [ ] ADMIN-1 to ADMIN-8.

### Go-live phases

Decided 2026-10-12, at the owner's request (ARCH D60). The first go-live is the website and the web app only. Each phase finishes before the next starts.

### Phase 1 · Website and web app

- [ ] The website at `getbattleplan.app` and the web app at `/app` (§4.3) on the prod project, working well in desktop and phone browsers (§4.2).
- [ ] Accessibility, performance (§8), and golden-test passes, and a web proof pass of every MVP flow.
- [ ] Prod on Blaze with budget alerts, and two weeks of measured bills that match the cost model (ARCH §10.1).
- [ ] Signup and account emails sent by Firebase Auth from `noreply@getbattleplan.app`; setup links, invites, and notices by Resend; `support@` and `privacy@` received through Cloudflare Email Routing (ARCH §6.7).
- [ ] The legal and support pages (LEGAL-1 to LEGAL-3).
- [x] Continue with Apple hidden (AUTH-1), and no store badges yet.
- [ ] Beta with our team on the web; move our team over (below); then the production deploy and open sign-up on the web.

**Done when:** our team runs on the web app on prod in desktop and phone browsers, signup emails arrive from our domain, and the bills match the cost model.

### Phase 2 · GDPR and EU, backup and restore, security hardening

- [ ] GDPR and EU readiness (LEGAL-7).
- [ ] Backup and restore (ARCH §6.12), with a restore drill from the off-site copy.
- [ ] App Check enforced on the web; a security review; security headers; prod locked down; DMARC enforced.

### Phase 3 · Sign in with Apple

- [ ] The Apple Developer Program (individual, Q13); Sign in with Apple on the web; Continue with Apple shown again; Apple's private email relay set up.

### Phase 4 · iPhone and iPad on the App Store

- [ ] iOS push, Universal Links, iPad layouts, a TestFlight beta, the App Store listing and privacy labels (LEGAL-4), and an App Review demo account; then submit.

**Done when:** the app is on the App Store. The parity rule (§4.2) covers iOS and the web from here on.

### Phase 5 · Android on Google Play

- [ ] The Play Console (a personal account, Q13), the 14-day closed test with 12+ testers, App Links on prod, and the Data safety form (LEGAL-4); then submit.

**Done when:** the app is on Google Play. The parity rule covers all three platforms from here on.

### Phase 6 · Facebook sign-in and SSO

- [ ] Continue with Facebook (Q16), Meta App Review, the data-deletion URL (LEGAL-5), and single sign-on for the providers teams ask for.

### Moving our team over (Phase 1)

1. Create our team and paste in the roster (TEAM-7, or players with their own or their parents' emails, PLAYER-1).
2. Recreate upcoming events, using repeating events for practices.
3. Post the invite link in the old GroupMe and show the QR code at practice.
4. Run both apps for about two weeks, then announce the switch.
5. Bring the chat, files, and events over from GroupMe; the schedule, players, and files from TeamSnap; and the schedule from TeamReach, GameChanger, or Google Calendar, with **Import** (IMPORT-7 to IMPORT-11).

### v1.1 backlog, in priority order

The web parts are built before the Phase 1 go-live (ROADMAP). Native-only parts, such as app icon badges, come with Phases 4 and 5.


1. @mentions, pins, announcements (CHAT-14, CHAT-15). Built (task 135).
2. Roster details and contact sharing (TEAM-10); "Same answer for all my players" and RSVP history (PLAYER-11). Built (tasks 136 and 137).
3. Calendar subscription (SCHED-11)
4. RSVP nudges and guest counts (SCHED-12)
5. Team-specific link previews for invites (ARCH §6.6). Built (task 140).
6. Folders and the chat photo gallery (DOC-7). The gallery is built (task 141); folders aren't.
7. Announcement-only mode (TEAM-12), polls list (POLL-6)
8. App icon badges, hidden notification text (NOTIF-12), files in chat (CHAT-16)
9. Persistent team list on very wide screens (§5.5)
10. Attendance history and CSV exports of RSVPs and the roster for admins
11. A branded invite page with the team's logo and color (`/join`)

**After v1.1:** group types beyond Team (TEAM-14). Keep the standard **Team** and add a more basic **Group** for general use (no roster, players, or RSVP counts by default), chosen at creation. Teams store `kind: 'team'` from the one-type change on, so adding Group needs no migration.

---

## 10. Launch checklist

When to buy or set up each item is in [TODO.md](../TODO.md). Purchases happen just in time, not up front. Items are grouped by the go-live phase that needs them (§9).

**Phase 1 · Website and web app**

- [x] A domain name: `getbattleplan.app` (Q8).
- [x] An email provider account: Resend (Q10).
- [ ] Prod on Blaze, with budget alerts, point-in-time recovery, and daily backups on.
- [ ] `getbattleplan.app` connected to prod's Hosting, with DNS-only records.
- [ ] Firebase Auth email templates branded and sent from `noreply@getbattleplan.app`; SPF, DKIM, and a DMARC record for the domain.
- [ ] Web push VAPID key on prod; the reCAPTCHA Enterprise key registered for App Check, in monitor mode.
- [ ] Rules and indexes deployed; Remote Config minimum version set; first super admin bootstrapped.
- [ ] Privacy Policy, Terms of Use, `/delete-account` page, support email.

**Phase 2 · GDPR, backups, security**

- [ ] The Privacy Policy's EU sections, Download my data, and the providers' data processing terms (LEGAL-7).
- [ ] The off-site backup copy in Cloudflare R2 and a restore drill that worked (ARCH §6.12).
- [ ] App Check enforced on the web; DMARC at `p=reject`.

**Phase 3 · Sign in with Apple**

- [ ] Apple Developer Program, $99/year, as an individual (Q13). The App Store shows your legal name as the seller; no D-U-N-S number or company website is needed.
- [ ] Sign in with Apple capability, and a Services ID for the web and Android.
- [ ] The sending domains registered with Apple's private email relay.

**Phase 4 · App Store**

- [ ] APNs key uploaded to Firebase.
- [ ] `apple-app-site-association` served from Hosting, and the Associated Domains entitlement.
- [ ] App icons, splash screens, and screenshots for each required iPhone and iPad size.
- [ ] Description, keywords, support URL, privacy URL.
- [ ] Age-rating questionnaire (chat and user-generated content).
- [ ] App Review notes: a demo account with a seeded team, and an explanation that teams are invite-only.
- [ ] Privacy labels (LEGAL-4).
- [ ] EU trader status declared in App Store Connect.

**Phase 5 · Google Play**

- [ ] Google Play Console, $25 once, as a personal account (Q13). Google Play shows your legal name, and production access needs a 14-day closed test with 12+ testers.
- [ ] Android SHA-1 and SHA-256 fingerprints (debug, upload, and Play App Signing) in Firebase, for Google sign-in and App Links.
- [ ] `assetlinks.json` with the prod fingerprints, and Android intent filters with `autoVerify`.
- [ ] Screenshots, description, content rating, the Data safety form (LEGAL-4), and EU trader status in the Play Console.

**Phase 6 · Facebook sign-in and SSO**

- [ ] A Meta developer app through Meta App Review, with the data-deletion URL (LEGAL-5).

---

## 11. Out of scope for v1

Not in v1; some may come later:

- Sub-chats or channels within a team
- Organizations and leagues
- A public team directory
- Message search
- Link previews in chat, GIFs, video, voice notes
- Voice and video calls
- SMS
- Email digests (reminders by email for people who can't get notifications are SCHED-14)
- Typing indicators and read receipts
- Attendance tracking, stats, and scores
- Payments and team dues
- Volunteer and snack sign-ups beyond assignments (SCHED-15 has one person a task, chosen in the app)
- Carpools
- Importing chat from TeamSnap, which doesn't export it. GroupMe, TeamSnap, TeamReach, GameChanger, and Google Calendar imports are built (§6.15; ROADMAP tasks 241, 249, 250, 252, 254).
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
| Q2 | ~~Will youth players use Battleplan?~~ **Decided:** no. Accounts are for adults (18+), and parents and guardians answer for youth players (§6.3). **2026-10-12:** adult players can be members and claim their own player ("I am this player"). | — |
| Q3 | ~~Who can create teams?~~ **Decided 2026-10-11:** anyone with a verified email; super admins can turn it off. | — |
| Q4 | ~~How will the platform be paid for once there are hundreds of teams?~~ **Decided 2026-10-12:** everything is free with no ads for now; ads may come once adoption justifies them (ROADMAP "Ads, later"). Each team has a storage limit, 200 MB since 2026-10-15 (500 MB before), that a super admin can change for every team or give one team its own (§6.14). A paid plan was planned on 2026-10-11 and dropped. | — |
| Q5 | ~~Are direct messages needed at launch?~~ **Decided 2026-10-12 (the recommended default):** later, not at launch. **2026-10-16 (the owner's request):** built (CHAT-19). | — |
| Q6 | ~~Reactions: one per person per message, or several?~~ **Decided 2026-10-12 (the recommended default):** one. | — |
| Q7 | ~~On wide screens, bottom tabs or a side rail?~~ **Decided 2026-10-12 (the recommended default):** a side rail at 840 px and wider. | — |
| Q8 | ~~What domain name for invite links and email?~~ **Decided:** `getbattleplan.app`, registered at Cloudflare ($8.20 the first year, then $14.20/year). battleplan.com, .app, and .io are taken. App ID `app.getbattleplan` (`.dev` for dev builds). | — |
| Q9 | ~~Logo and primary color?~~ **Decided 2026-10-12:** blue `#2F5BEA`; **2026-10-14:** the flag-and-B mark (§7.1). | — |
| Q10 | ~~Which email provider?~~ **Decided 2026-10-12:** Resend, for the emails Functions send. Firebase Auth sends signup and account emails itself, for free (ARCH §6.7, D61). | — |
| Q11 | ~~Where are most teams located?~~ **Decided 2026-10-12:** the US, so prod's database is in `us-central1` (permanent). | — |
| Q12 | ~~Can members create events by default?~~ **Decided 2026-10-12:** only admins create events by default; each team can let members create them in Team settings (TEAM-5). | — |
| Q13 | ~~Apple developer account as an individual or an organization?~~ **Decided:** individual, for now. The LLC is no longer registered, so the apps are published under your own name in both stores. Both stores can upgrade the account to an organization in place later (it needs the LLC's D-U-N-S number) and keep the apps. | — |
| Q14 | ~~On youth teams, should coaches and staff also RSVP for themselves?~~ **Decided 2026-10-11:** yes. Team admins RSVP for themselves and are counted apart from players (PLAYER-6). **2026-10-12:** on every team, admins and members not linked to a player answer for themselves, counted apart as "others". A member who is a player answers on their player's row instead, admins included. | — |
| Q15 | ~~When a parent picks an existing player, must an admin approve the link?~~ **Decided 2026-10-11:** yes (PLAYER-3). **2026-10-12:** this covers every claim, as the player or a guardian; an admin's own claim is approved at once. | — |
| Q16 | ~~Is Facebook sign-in needed at launch?~~ **Decided 2026-10-11:** not for now. Launch with Google, Apple, and email. **2026-10-12:** Facebook sign-in was removed from the plan. **Later on 2026-10-12:** it returns as go-live Phase 6, with single sign-on (§9, ARCH D60). | — |
| Q17 | ~~Should there be separate adult and youth team types?~~ **Decided 2026-10-12 (the owner's request):** no. There's one team type. Every team has players; any member can claim a player as "I am this player" or as a parent or guardian, and any member can add a player. Team admins approve or decline claims and members' new players (§6.3). | — |
| Q18 | ~~Should we store player details such as date of birth?~~ **Decided 2026-10-12 (the owner's request):** yes, as optional details seen only by the team's admins and the player's linked people, with consent for medical notes (PLAYER-12, ARCH D63). **2026-10-20 (the owner's request):** medical notes and their consent stamp were removed, so no health data is stored. Date of birth, emergency contacts, and notes stay. | — |
