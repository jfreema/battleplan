# Battleplan — Product Spec

| | |
|---|---|
| **Status** | Draft v0.3 |
| **Owner** | Jared Freeman |
| **Last updated** | 2026-11-12 |
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
| 14 | Light mode and dark mode | SET-2; §7.4 (Boot Camp Mix's seven color schemes) |
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
| "Your schedule" on Teams (SCHED-2) | Parents and players on several teams need one calendar |
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
| **Play maker** | A member the team's admins let draw, save, change, and delete the team's plays (BOARD-4, #63): an assistant coach or a captain who shouldn't manage the team. Not a role of its own: a switch on their card, beside Coach |
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
| See what you owe, or your players owe, what's been paid, and how to pay (DUES-2, DUES-3) | ✓ | ✓ | ✓ | ✓ any team |
| Add, edit, and delete dues; record what each person paid, in full or a part at a time; see who owes what; set how to pay (DUES-1 to DUES-3, DUES-5) | — (a team's coaches set how to pay) | ✓ | ✓ | ✓ |
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
| Draw, save, change, and delete the team's plays (BOARD-2, BOARD-4) | play makers | ✓ | ✓ | ✓ |
| Make someone a play maker, or stop (#63) | — | ✓ | ✓ | ✓ |
| Remove someone's admin role | — | — | ✓ | ✓ |
| Edit team profile and settings | — | ✓ | ✓ | ✓ |
| See and act on reports in the team | — | ✓ | ✓ | ✓ |
| Transfer ownership | — | — | ✓ | ✓ |
| Archive or delete the team | — | — | ✓ | ✓ |
| Start a new season from the team (TEAM-16) | — | — | ✓ | — |
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

- **WEB-1 · MVP · Landing page.** In few words, what Battleplan is, for groups and sports teams (group chat, schedule and RSVPs, polls, documents, Your schedule across every team, the coach's whiteboard, players and guardians, dues, and switching from other apps; Dues sits below Plays and Players first, owner's request 2026-11-07), that it's free with no ads, a short FAQ, screenshots in all five color schemes, and clear ways in: **Get Started** (the web app's sign-up page, `/app/sign-up`) and **Login** (`/app`), and Apple's **Download on the App Store** badge (with Apple's credit line, as its guidelines ask), and Google Play's once that app is listed. Ends with a **Donate to Support This Project** button linking to Jared's Venmo (`https://venmo.com/u/Jared-D-Freeman`), with the handle shown below it. Support is voluntary and unlocks nothing. The Team chat screen's screenshot is a baseball team's chat as its coach sees it: only messages and one small photo, with no events or polls (owner's request 2026-11-07: "On the landing page there's screenshot of the group chat but it's too generic. Replace it with one about baseball from the perspective of a team chat."). The hero shows the fan of five phones from the Facebook cover, one in each color scheme, with the coach's whiteboard in front, a schedule and a team chat on either side of it, and a group chat and a poll at the ends (owner's request 2026-11-07: "on the landing page use the multi-screenshot image that we used for the facebook background image. the one that has plays and messages."). Picking a color scheme brings that scheme's phone to the front, the others turning around it in the fan's order (owner's request 2026-11-07: "at the top of the page, selecting a color used to change which screen shot was at the front of the image of all the color schemes. they no longer rotate out when you change colors. can you fix that?"). The Light blue phone is Cyclone's team chat, only messages and one post of the owner's two team photos side by side, like the Group chat tile's (owner's request 2026-11-07: "use the images i gave you to turn the light blue screen shot into a screenshot of a Cyclone team chat. should be able to re-use what you did further down the page where you showed a screen shot of the group chat."); the photos show players, so they're never committed to the repo. Beside it, seven feature pages written for what people search for (owner's request 2026-11-09: "find a good SEO skill and use that to give the battleplan landing page good SEO for things like team chat, team messaging, group messaging, baseball team play whiteboard, and things that will help direct potential customers to the site."; [SEO.md](SEO.md)): `/team-chat`, `/baseball-whiteboard`, `/team-schedule`, `/team-dues`, `/groups`, `/teamsnap-alternative`, and `/groupme-alternative`, each with real detail and screenshots from the app, an FAQ, **Get Started**, and Apple's badge, linked from the landing page, `/switch`, and every footer. The landing page was redone shorter on 2026-11-12 (owner's request: "make a cooler, cleaner, more polished, less wordy, and less AI looking version of the landing page. You can re-imagine the page to accomplish the goal. Let's push it to dev and see if I like it. If i do i will push it to prod if i dont we'll roll it back."): the hero; a strip of five screens (Team chat, Schedule and RSVPs, Polls, Documents, and the schedule across every team); Plays, Players first, and Dues, each a title, a line or two, and a phone rising out of a candy panel; switching in one line; seven questions; and **Free for every team** with **Get Started**. No eyebrows over every section, no chips, no tiles of numbers. Later the same day it was sharpened (owner's request: "i liked the color picker better the way it was before. bring back the color list to choose from so its more obvious what the buttons do. go ahead and try to spruce the page up a bit and make it look less AI generated, make it look more polished and cooler."): the picker is a named chip for each scheme again, and the page is five numbered plays (Team chat, Schedule, the whiteboard, Dues, Switching) joined by dashed routes, each a short title, a line or two, and real screens; the Schedule play shows Your schedule on Teams (SCHED-2), not All my teams.
- **WEB-2 · MVP · Support and legal pages.** `/privacy`, `/terms`, and `/delete-account` (LEGAL-1, LEGAL-3), and `/support` with the support email. These are the URLs the store listings and Firebase settings use.
- **WEB-3 · MVP · The web app at `/app`.** The Flutter web app is served under `/app/` and linked from every page of the site. Signed-in people who open `/app` go straight to their teams.
- **WEB-4 · MVP · Short links still work.** Invite links and QR codes keep the short form `getbattleplan.app/join/K7XP-M2QR`. With the app installed they open it; otherwise the browser lands in the web app's join page under `/app`. Email and notification links also open the app if installed, or the web app. So does email sign-in's address, `getbattleplan.app/emaillogin` (AUTH-2).
- **WEB-5 · MVP · Fast and plain.** Static pages with no ads, no tracking, and no cookie banner needed; the app's Open Field look (§7.4) in Army green, with the landing page's hero showing the app in all five schemes on a fan of phones and a color scheme picker that re-colors the page in each and brings that scheme's phone to the front, without JavaScript; the fonts served from the site itself, not Google Fonts (LEGAL-2); readable on every phone, tablet, and computer from 320 px wide, iPhone safe areas included, and WCAG 2 AA; indexed by search engines and open to AI crawlers, with a title, description, Open Graph tags, structured data (JSON-LD: the organization, the site, the app, and the FAQ on the landing page; the page, its breadcrumbs, and its FAQ on each feature page, every FAQ repeated word for word), a sitemap, and `llms.txt`, while `/app` and the whole dev site aren't indexed.

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
| Dues' How to pay (DUES-3) | Copy only: a precaution, not a store rule ([Store payment rules](STORE-CHECKLIST.md#store-payment-rules)) | Copy, or open Venmo and Cash App | Copy, or open Venmo and Cash App |
| Keyboard | — | — | Enter sends, Shift+Enter new line, Esc closes, Ctrl/⌘+K opens the team switcher |
| Offline | Full offline cache | Full offline cache | Offline cache in the browser (lost if site data is cleared) |

---

## 5. Navigation and layout

### 5.1 App map

```
Sign in
 ├─ First time → Profile setup (name, photo, 18+ confirmation, terms)
 ├─ The top: tabs Teams ⌂ | Profile (rail on wide screens: Super Admin Panel** at its foot)
 │    ├─ Teams:    your teams (each opens where you left it) · Your schedule
 │    │            (what's next across them, and See all) · Join a Team or
 │    │            Group · Create a Team · Create a Group · Default color
 │    │            scheme · Super Admin Panel** · Messages · bell
 │    │            (no team yet: a welcome with Join and Create)
 │    └─ Profile:  Your icon · Name · Time zone · Notifications ·
 │                 Color scheme · Settings · Super Admin Panel** · Sign out
 │                                                       (** super admins)
 └─ Team view (the app opens where you left it: the last team and tab, or Teams)
      ├─ Header:     ‹ back to Teams ("‹ Teams" on wide screens; a dot while other teams have news: unread messages or notifications) · team switcher ▾ · Super Admin Panel** · Messages ✉ · this team's notification bell · Team settings ⚙
      │              (wide screens: Teams, Profile and Super Admin Panel** at the foot of the rail instead)
      ├─ Messages:   your direct conversations → one of them (CHAT-19)
      ├─ A person:   their page, from their photo in chat or the Team tab (TEAM-15)
      ├─ Tabs:       Chat | Schedule | Documents | Plays | Team (a group: Chat | Schedule | Documents | People)
      │    └─ Team:  the team's card with Invite and Dues · the roster, with + to add players
      │              (Leave team is on your own card there, TEAM-8)
      └─ Team settings (⚙): the team · Just for you: Notifications for this team · Color scheme ·
                     Calendar link · For admins*: Admin settings · Media · Reports · Import    (* admins)
```

- **The top** (owner's request 2026-10-27). **Teams** and **Profile**, with tabs at the bottom on phones and a rail on wide screens. Teams' icon is a house, the top of the app, and the welcome on an empty Teams has it too; a team's Team tab keeps its three people, so Teams and Team never look alike (#18, 2026-11-16: both had the three people). Teams lists your teams as cards (logo, name with Team or Group, last message, unread count; the team's next event in the next two weeks, "Next: Practice · Sat 4:00 PM", muted, with a coral dot in front and "· Needs your answer" while someone you answer for hasn't (#43, CHAT-21; no line with nothing coming up or on an archived team, and no buttons: the card stays one target); and for a team's admins, "2 requests waiting" in coral when roster requests wait for them, PLAYER-4, its own 48 px button that opens the team's Team tab while the rest of the card opens the team where you left it, #23), with archived teams under an **Archived** row that expands, then **Your schedule** (SCHED-2): the next five events across your teams and groups as the schedule's cards, and **See all**. Then Join a team and Create a team as plain rows, then **Default color scheme** under a Color scheme label (SET-2); someone with no team yet sees a welcome with Join, Create, and the color scheme, and no schedule. Profile is plain rows: **Your icon** (your photo: add, change, or remove it), **Name** (the name your teams see, changed in a dialog), **Time zone** (SET-7), **Notifications** (Notification settings, SET-3), **Color scheme** (your Default color scheme, naming the one picked, SET-2), **Settings**, the **Super Admin Panel** for super admins, and **Sign out**, the app's one plain Sign out (#28, owner's go 2026-11-16: Notifications sat two levels down, under Settings, and Sign out was on both pages).
- **The Super Admin Panel, one tap away** (owner's request 2026-11-07: "make admin panel easier to get to with fewer steps to get there"). A super admin has an **Super Admin Panel** button, a shield, in the Teams header and in a team's header on every tab, before Messages; on wide screens it's at the foot of the rail instead, on Teams, Profile, and a team's tabs. Profile keeps its row. It opens the panel over the page they were on, so Back comes back there. From a team it took three taps (back to Teams, Profile, Super Admin Panel); now it's one. Nobody else sees any of it: their headers and rail are as they were (§6.11).
- **A team's back arrow** (‹ at the top left of the header) goes to Teams; screen readers and its tooltip say "Back to Teams". On wide screens it reads "‹ Teams", as every other back names where it goes; phones keep the arrow alone, since the team's name needs the room for its two lines (#18). Android's Back in a team goes to Teams too, rather than closing the app: first it closes whatever is over the team (a sheet or dialog, a page opened on top, or a tab's own page such as Saved plays), and while viewing a team as a super admin it goes where the banner's Done does. Back on Profile goes to Teams, as Android's bottom bars go to their first tab; on Teams it leaves the app. The web's Back follows the browser's history. Inside a tab, on a page with its own back button (Saved plays, a play), the header leaves its arrow out, so only one back shows. Every back is a plain chevron; on a pushed page it's followed by the name of the page it returns to ("‹ Team settings", "‹ Team" on a player card or a person's page opened from the Team tab) when that's known, with the page's title on its own line below. The back row stays at the top; the big title scrolls away with the page, giving its room back (owner's request 2026-11-05: headers that take less room; #14, 2026-11-16), and once it's out of sight the page's name shows small in the back row's middle, where it fits without crowding the back label, with a hairline under the row. Every page opened on top has this one frame, and keeps its rows and text 20 px from the edge (§7.3); where a page keeps to a centered column (on a wide screen or in a side panel), its big title stands at the column's edge, lined up with the rows under it, not at the window's. A long title takes two lines, stepping down in size before it would split a word; one too long even for that ends in "…" on its second line (#16). Team settings goes back into the team by its name ("‹ Thunder"); its pages (Notifications for this team, Calendar link, Media, Reports, Import) go back to "‹ Team settings" ("‹ Group settings" in a group), or name whatever else opened them (Notification settings, Admin settings, the storage warning, the admin panel). Admin settings' Chat look and Team color scheme pages go back to "‹ Admin settings" (#32). A team's bell opens "Notifications" with the team's name as its back; the bell on Teams goes back to "‹ Teams". Notification settings goes back to "‹ Profile", or to "‹ Notifications" from the bell's gear, or to the team's notifications page whose link opened it; the Default color scheme goes back to "‹ Teams" or "‹ Profile". Invite's Email invites and Add people by email go back to "‹ Invite", and a player's RSVP history to the player by first name ("‹ Mia"). Messages goes back to the team whose header opened it, by name, or to "‹ Teams"; Join a Team or Group and Create a Team go back to "‹ Teams" or to the team whose switcher opened them; Add players to "‹ Team", or to the event whose RSVP section opened it; Team photos to "‹ Documents"; and an event's Assignments to the event by name ("‹ vs. Eagles"), naming the event on the page only when opened from a link. Every "more" menu on these pages shows the app's three dots. Left on purpose, as they work differently: the player's Details and the other X-and-Save forms, as forms are; Who are you here for, a step-by-step flow whose back goes to the step before; the join page an invite link opens, which comes before sign-in; the "Done" summary after adding people or players; the code scanner's camera view; the admin panel, its own console with a rail; chats; and photo and file viewers. A page opened with nothing under it (a link, a web reload, a notification on a cold start) still has the chevron, alone: it goes up to the team's chat, Profile for Settings and Profile's pages, Messages for a conversation, or else Teams. Android's Back goes up with it, rather than closing the app; a dialog or a page over it keeps Back for itself (#14, 2026-11-16: seven pages had no way back at all, among them Reports from a "reported" notification).
- **Tabs** are a bar docked along the bottom, full width under a 3 px ink rule, the current tab's icon on a mustard tile in an ink outline, turned a little (#85); from 840 px wide they're a rail down the side. Their labels share one size (#64, owner's request 2026-11-17: "the words collide with each other"): the text size asked for, or smaller where the longest label wouldn't fit its tab with 4 px on each side, so neighbors are always at least 8 px apart and no label is smaller than the others; the rail's labels share one size too. On the bar, Documents is **Docs**, so five labels keep their size on a 320-point phone; screen readers and the rail still say Documents.
- **Team settings** (the gear ⚙ at the right of the header) is a page with nothing but settings on it (owner's request 2026-11-10: "the icon to get to settings looks like an info icon. i would rather it be obvious that it's settings and configuration for the team"). Under the team's card (logo, name, sport, and member count) come **Just for you**, what changes the app for you alone: **Notifications for this team**, **Color scheme** (the scheme you see this team in: the team's default, or your own pick, SET-2), and **Calendar link** (SCHED-11); then, for the team's admins and super admins, **For admins**: **Admin settings** (TEAM-5), **Media**, **Reports**, and **Import**. A super admin viewing a team they aren't on gets For admins only. A group's is **Group settings**. Until 2026-11-10 it was **Team info**, behind an ⓘ, with the roster, Invite, and Dues on it too; they're the Team tab now (§5.3). Its route is still `/g/{groupId}/info`.
- **Your avatar** left the team's header: what it held is on Profile.

### 5.2 Team switcher

- **Header.** One row: the tab's stencil eyebrow in muted text (coral until 2026-11-16, §7.2) ("TEAM CHAT", "FALL SCHEDULE", "TEAM DOCUMENTS", "PLAYBOOK", "TEAM ROSTER"; a group's "GROUP CHAT", "GROUP SCHEDULE", "GROUP DOCUMENTS", "GROUP MEMBERS") over the team name, and ▾. The name steps down in size to fit one line (27 to 19); a longer one takes two lines at 19, or at 17, breaking only between words and as evenly as it can, and only one too long even for that ends in "…". While the name takes two lines the eyebrow steps aside, so the header stays one slim row (#13, owner's go 2026-11-16: names over about 15 letters used to be cut, and the eyebrow kept was tried and looked cramped); screen readers still hear it. At the largest text sizes, where two lines would make the header taller than 96 px, the name stays on one line. Screen readers hear the eyebrow, then "Switch team: {name}". News in your other teams is the back arrow's one dot (NOTIF-11); there's no dot by the name, and the switcher's list has each team's count. The header has no logo; logos are on the Teams cards, in the switcher, and on the team's card (the Team tab and Team settings).
- **Opening it.** A bottom sheet on phones; a dropdown panel on wide screens.
- **Contents.**
  - Your teams, most recent activity first.
  - Each team shows its logo, name, sport icon, last-message preview, unread message count, and muted icon.
  - **In the app's own rows** (#25, owner's go 2026-11-17: it was a stock list, with the current team's name and check in blue, the groups' color, and the stock red count): "Your teams" as a heading, then each team a row at least 64 tall between hairlines: the 40 px badge, the name in Fredoka in the text color with its sport's icon (a group's own) in muted text, and the last message, muted, on one line. The team I'm on has a faint tint, a bold name, and a coral check at the end; screen readers hear "Thunder, Soccer, current team, 3 unread messages". Unread is Teams' coral count (1 to 99+), an outlined gray one beside the muted icon for a muted team (CHAT-9), or a coral dot before the count loads.
  - Archived teams collapse into an "Archived" row whose chevron turns as it opens them.
  - At the bottom: **Join a Team or Group** (code or QR), **Create a Team**, and below it **Create a Group** (TEAM-14); the team switcher has the same three.
- **Switching** keeps you on the same tab: from one team's Schedule to the other team's Schedule. The other tabs then open on the new team too, at their start, never back on the team you left, and a sheet or dialog left open (a person's card, a message's menu) closes, whatever changed the team: the switcher, a notification or link, or leaving a team for another. Within a team, each tab keeps its place.
- **Memory.** The app remembers the last team and tab on each device, or Teams when you left from there, and opens there. Teams opens each team at the tab you last had in it.

### 5.3 Bottom tabs

| Tab | Icon | Badge |
|---|---|---|
| **Chat** | Speech bubble | Unread message count for this team (CHAT-9) |
| **Schedule** | Calendar | — |
| **Documents** | Folder | — |
| **Plays** | A coach's play, after the Play Call app icon design: an O at the bottom left, its dotted route arcing up to an arrowhead, and an X at the bottom right. Drawn, as no icon font has one; one color in the tabs, and in color on the empty Plays screens (a lemon O and a coral X) | — |
| **Team** (**People** in a group) | Three people | Requests waiting for approval (admins only, PLAYER-4): new players and claims, in coral as Chat's; screen readers hear "Team, 2 waiting for approval". Members and a super admin viewing the team see none (#23) |

- Labels are always visible. The tabs, order, and icons are the same everywhere. On wide screens, Plays sits directly below Documents in the left navigation rail, and Team below Plays; on a window too short for every tab, such as a phone on its side with large text, the rail scrolls. A group has no Plays, so its People tab follows Documents. All five labels fit on a 360-point phone; with larger text, a label too long for its tab shrinks to fit rather than being cut off.
- **Team** (owner's request 2026-11-10: "make it easier to use. re-think and re-imagine the UI layout and navigation if you have to"): the team's card (logo, name, sport, and member count) with **Invite** and **Dues** under it as outlined buttons sharing its width (one above the other with large text); then the roster (TEAM-3): search by name with the sort beside it (TEAM-10), pending players and claims for admins, then Players, Coaches, Admins, and Members. A person's card opens over the whole screen, header and tabs included, and scrolls when its rows don't fit (a small phone with large text). A coral **+** at the bottom right adds players (PLAYER-1, PLAYER-4), as Schedule's adds an event. With no players yet, the Players section says "No players yet." with a coral button right under it, where the players go, so the card, Invite and Dues stay above: **Add your players** for admins, and **Add your player** for members (PLAYER-4) (#3). In a group it's **People**: the card, then its admins and members. Its route is `/g/{groupId}/team`. Until 2026-11-10 the roster was a page in Team info (`/g/{groupId}/roster`); links to it and its player cards, such as older notifications and web app links that open the phone app, open the Team tab.
- Each tab keeps its scroll position when you switch away and back.

### 5.4 Phone layout (Chat tab)

```
┌────────────────────────────────────┐
│ (TU) Thunder U14 v [M] (!) ...(JF) │
├────────────────────────────────────┤
│ ─────────── TUE, OCT 14 ────────── │
│ (AK) Alex Kim #3  5:58 PM          │
│      Field 3 is open. See you      │
│      at 6!                         │
│      👍 4  ❤️ 1                     │
│               ┌──────────────────┐ │
│               │ On my way!       │ │
│               └──────────────────┘ │
│                              Sent  │
│ (AK) ┌───────────────────────────┐ │
│      ┃ vs. Eagles            GAME│ │
│      ┃ Sat 9:00 AM · Riverside   │ │
│      ┃ Emma (Going)(Maybe)(No)   │ │
│      ┃ ▬▬▬▭▭  2/4 going          │ │
│      └───────────────────────────┘ │
├────────────────────────────────────┤
│ (+)  Message Thunder U14...    (>) │
├────────────────────────────────────┤
│ [Chat] Schedule Documents Plays Team│
└────────────────────────────────────┘
```

### 5.5 Wide screens (web and tablets, 840 px and up)

- **Navigation.** The tabs move to a **left rail**: Chat, Schedule, Documents, Plays, and Team, and at its foot **Teams** and **Profile**, then for super admins the **Super Admin Panel**, in place of the header's button (§5.1). Those are buttons, not tabs: no selected state, and not counted among the tabs (#18, 2026-11-16: until then only the header's small, unlabeled arrow led out of a team). The team switcher stays in the header beside the rail. The order, icons, and labels match phones.
- **Chat** is centered at a readable width (about 840 px).
- **One column per page** (#29, owner's go 2026-11-20: on a laptop or iPad, Teams, Profile and the settings pages sat in a 560 px strip in the middle while their title stood at the far left and their icons at the far right; the team header spanned the window over an 840 px chat; Messages and Notifications stretched across the window, with "1h" at its far right). Each page keeps its title, icons and content in one centered column: 560 px for Teams, Profile, Settings and the pages opened on top that are lists or settings, Messages and Notifications among them, with the back row's chevron at the column's left, its icons at the column's right, and a page's floating button (New message) at the column's corner; 840 px for a team's header and its chat and schedule, with nothing taken out of the header. Phones are unchanged. Messages and Notifications still open over the whole window, without the rail, as Settings does.
- **Panels.** Event details, member cards, and settings open as side panels or dialogs instead of full screens, Invite and its two email pages, and Team settings' Media, Reports and Import among them (#14, 2026-11-16; they opened full screen).
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
  - **Under the buttons on sign-in**, one line says so: "First time? Google and Apple also create your free account." ("First time? Google also creates your free account." where Apple is hidden), so new people don't tap Sign up only to find the same buttons (#24, owner's go 2026-11-20). The sign-up page leaves it out: its buttons say Sign up.
  - **On the way to an invite** (sign-in's `from` is `/join/<code>`, INV-5 step 2), a card above the buttons shows the team's badge and "Join Hornets: sign in or create a free account", on sign-in and sign-up alike (in place of sign-up's "Create your free account"). It reads the invite's preview; while that loads, or if the invite can't be used, the screen is the plain one, and the invite page says what was wrong (#24).
  - **The stores allow it.** Neither store asks for email sign-in. Apple's guideline 4.8 does ask an app that offers Google sign-in to offer one that can keep the email private beside it, which Sign in with Apple does, so the iPhone app ships with Apple on (store checklist 2.1). Reviewers sign in with Apple or Google and join the demo team with its code, or use the demo account at `/emaillogin`, which the review notes describe, as Apple's guideline 2.3.1 asks of anything not on screen (store checklist 1.14, 1.17).
  - Google always asks which Google account to use (its account chooser), so a browser signed in to one Google account never picks it silently.
  - **On Android, Google is the phone's own account sheet**, the one other Android apps show, never a browser tab, and so are linking Google in Sign-in methods (AUTH-8) and confirming it's you with Google. Signing in through a browser tab failed for a Google Play tester with "Unable to process request due to missing initial state", because some browsers lose the tab's place on the way back from Google (2026-11-18, ARCH §6.1). The web keeps its popup, the iPhone app its system sheet, and Apple works as before everywhere.
  - The screen is identical on every platform. The Apple button follows Apple's design rules, and the Google button Google's: Google's "G", in its own colors and unaltered, on a white disc before the title, on every Continue with Google button (the owner's request, 2026-10-26).
  - **Continue with Apple** (Phase 3, §9) is on in dev, on the emulators, and in prod since 2026-10-17, when both Firebase projects got Apple's Services ID and key. A switch in the app (`AppEnv.appleSignInInProd`) can hide it in prod again, so prod never offers a button that can't work; hidden, prod shows Google only, and Sign-in methods (AUTH-8) offers Apple only to an account that already has it.
  - Apple asks for the email and, the first time, the name, which prefill the profile (AUTH-12). With Hide My Email, Apple shares a private relay address instead (`…@privaterelay.appleid.com`), which reaches the person as long as our sending domains are registered with Apple (task 207).
  - **A failed sign-in leaves a trace.** When signing in with Google or Apple, linking one in Sign-in methods, or confirming it's you with one fails with "Something went wrong", the app records a non-fatal error with the provider and Firebase's code and message, never the person's email or name: in Crashlytics on iOS and Android, and through `logClientError` on web, sampled like other web errors (ARCH §9). Closing the sheet isn't reported, nor are the failures the screen explains (a blocked popup, no connection, a disabled account, an email that signs in another way). The owner's go (2026-11-10), after a tester's Google sign-in on Android failed with nothing logged, because the prod Firebase project didn't know the key Google Play signs the app with.
  - Continue with Facebook joins in Phase 6, with single sign-on (Q16).
- **AUTH-2 · MVP · Email and password.**
  - At `/emaillogin`, not linked from the sign-in screen (AUTH-1). `getbattleplan.app/emaillogin` works too: Hosting redirects it into the web app, and the phone apps open it. `/sign-in/email`, its old address, redirects there, keeping where to go back to.
  - Sign in, or create an account with name, email, and password, or have a sign-in link emailed.
  - The app shows the address only to people who use a password: their password's row in Sign-in methods (AUTH-8) and the choose-how-to-sign-in screen (AUTH-6) say where it works. The support page asks people with a password to email support.
  - Passwords need 8+ characters, enforced by Firebase's password policy.
  - Show/hide password toggle.
- **AUTH-3 · MVP · Email verification.**
  - Google and Apple sign-ins arrive verified. Email sign-ins get a verification link, and a banner stays up until it's tapped: "Verify your email: we sent a link to pat@example.com." with **Resend** and **I've verified**, in the info color (blue raspberry, as routine announcements are), above every screen.
  - A verified email is required to create a team, send email invites, or add people by email.
  - **Said before it's needed** (owner's go 2026-11-18, "Do #33"), not only when Create fails at the end:
    - **Welcome** (Teams with no teams) has one muted line under its words: "To create a team, first verify your email. We sent a link to pat@example.com." Joining doesn't need it.
    - **Create a Team** and **Create a Group** start with a calm notice card: "Verify your email to create a team" (or "a group"), "We sent a link to pat@example.com. Open it, then come back here.", with **Resend email** and **I've verified**. The form stays usable and Create stays on.
    - **Create tapped too soon** checks with the server first. Still unverified, the card turns to the warning look, "Your email isn't verified yet. Open the link we sent to pat@example.com.", with no second error under the button, and Create waits.
  - **The app checks again by itself:** whenever it comes back to the front (on the web, when its tab is shown again), the usual way back from the email, and every 10 seconds while Create a Team waits, for a link opened on another device. Once verified, the banner and the card go, and a snackbar says "Email verified. You can create your team now." A Create that waited goes ahead by itself, with the same request so it can't make two teams, if the form didn't change meanwhile; otherwise Create is simply ready.
  - **I've verified** checks by hand and says "Not verified yet. Open the link we sent to pat@example.com." when it isn't. **Resend** says "Sent. Check your inbox.", or "Try again in a few minutes." at Firebase's limit.
  - The banner keeps the app's layout the same shape whether it shows or not, so verifying never rebuilds the screens under it.
- **AUTH-4 · MVP · Password reset by email.**
  - "Forgot password?" → enter email → "If an account exists for that email, we've sent a reset link."
  - The link opens the reset page; then the user signs in with the new password at `/emaillogin` (AUTH-2), where "Forgot password?" is. A reset a super admin sends continues there.
  - The screen notes that people who use Google or Apple don't have a Battleplan password.
- **AUTH-5 · MVP · First-run setup.**
  - Name and photo, prefilled once from the sign-in provider (AUTH-12), or with the name typed at an email sign-up (AUTH-2), and Terms acceptance.
  - Confirm "I'm 18 or older". Accounts are for adults only. Adult players use the app themselves, and youth players never sign in: their parents and guardians use the app for them (§6.3).
  - Only the confirmation and its date are stored.
  - On the way to an invite, a card at the top shows the team's badge and "Finish setting up, then you'll join Hornets" (#24).
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
  - Sign out from Profile; that stops push notifications on that device.
  - "Sign out of all devices" ends every session at once.
- **AUTH-10 · MVP · Delete account.**
  - Settings → Account → Delete account explains what will happen, asks the user to sign in again, then deletes everything.
  - In the iPhone, iPad, and Mac apps, an account with Apple sign-in signs in with Apple once more, so the app can revoke Apple's tokens first (App Review 5.1.1(v)). Closing Apple's sheet deletes nothing. The web and Android can't revoke; people there can remove Battleplan under Sign in with Apple in their Apple Account settings.
  - Owners pick a new owner for each team they own. If they skip it, ownership goes to the longest-serving admin, otherwise the longest-serving member. Teams with nobody else are archived.
  - Their player links end (as a player or a guardian). A player left with no links stays on the roster for admins to manage. Their player claims, and the players they added that no admin approved yet, are deleted.
  - Their past messages stay, shown from "Deleted user".
  - Their own shares of a group's dues stay with its admins, shown from "Deleted user", and how to pay they saved for a team is removed (DUES-2, DUES-3).
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
  - **Who:** any signed-in user with a verified email. Super admins can turn this off, and each person can create up to 5 teams a day (super admins can change the limit, ADMIN-7). An email account not verified yet sees a notice at the top of the form saying so, with Resend email and I've verified; a Create tapped too soon waits and goes ahead by itself once the email is verified (AUTH-3, #33).
  - **Fields:**
    - Name (required, ≤ 50 characters).
    - Sport: Baseball, Basketball, Football, Hockey, Lacrosse, Soccer, Softball, Volleyball, or Other.
    - Logo or photo (optional).
    - Team color (optional). Chosen from 15 colors, navy and gold among them. It's on the team's badge, in the team switcher, and as its dot in Your schedule, and doesn't tint the pages (§7.4); badges show white or black text on it, whichever reads better.
    - Time zone (defaults to the device's).
    - Description (optional).
  - The creator becomes the **owner**, and the next screen is Invite, titled "Hornets is ready!" (INV-1, #16).
  - **The setup card** (owner's go 2026-11-16, #3): **Continue** lands in the new team's chat, where its admins (the owner and admins; not members, and not a super admin viewing it) find a card at the top of the history, above the first message: **Get Hornets ready**, then three steps in the order to do them, each a row opening its screen:
    1. **Add your players**, "So parents can pick theirs when they join" (Add players).
    2. **Invite families**, "Share the link or QR code" (Invite).
    3. **Add your first practice or game** (the new event form; full storage says why, STORE-4).
    - Under them a quiet link, **Coming from TeamSnap or GroupMe? Import your team**, opens Import (IMPORT), which stays in Team settings under For admins.
    - **The steps tick themselves off**, with no button to press: a player on the roster, someone else on the team (more than one member), and any event, upcoming or past. An import that brings players or events ticks those too. A done step has a mint check in place of its empty circle, goes muted, and still opens its screen. The first step not done has a coral circle and a bold name, the only coral on the card.
    - With every step done it says **Hornets is ready**, with **Done**. Done, or leaving the chat once it says so, puts it away for good; so does its **X** ("Hide setup") at the top right, at any time. Putting it away is saved on the admin's own membership (`setupClosed`), so it stays away on every device and for that admin only.
    - It shows only on teams made on or after 17 Nov 2026, when it shipped, and for their first 30 days, so no existing team suddenly gets one. Not on archived or suspended teams.
    - It's a true card (§7.5) as wide as a message can be (520 px) and scrolls away with the oldest messages as the chat fills, so it never takes room from a busy chat. While the chat is empty it takes the empty chat's place, right under the header, so there's never a second Invite. Screen readers hear its title as a heading and each step as "Add your players, not done" (or "done") with its hint.
  - **Create a team** shows a spinner while it saves. One that fails, or gets no answer within 30 seconds, says so ("Couldn't create the team. Check your connection and try again."), and is reported. Trying again is safe: a first request that arrives late and the retry make one team between them.
  - **Create a Team** and **Create a Group** (TEAM-14) are separate entries. A team has a roster of players and works for adult and youth teams alike (§6.3); a group is for anything else, with no players. Create a Group asks only for the name and an optional color, as simply as it can: the time zone is the device's, and a logo and description can be added in Admin settings.
  - **Goal:** create a team and share an invite in under 2 minutes.
- **TEAM-2 · MVP · Many teams per person.**
  - A person can be on up to 100 teams and switches between them with the team switcher (§5.2).
  - Each team has its own chat, schedule, documents, members, admins, settings, and notification level.
  - Teams are walled off from each other. Nothing shows which other teams a member belongs to: a person's page (TEAM-15) lists only the teams you share with them.
- **TEAM-3 · MVP · Roster (the Team tab).**
  - The roster is the **Team** tab (§5.3), under the team's card with Invite and Dues.
  - A **Players** section on every team (jersey number on a plain disc, name, and who's linked: "Player" or "Guardian"), then sections for **Coaches**, Admins, and Members. Each member shows their players: a guardian shows "Emma #7", and a member who is a player shows their number (PLAYER-8).
  - **Who sees the people:** with the team setting "Everyone can see who's on the team" off (TEAM-5), members see the players, the coaches, and their own card (which has Leave team), and a line saying the admins keep the rest private; admins see everyone. Names still show where people act, as authors in chat and on RSVPs. The phone and email people share (TEAM-10) follow the same rule in the database, not just on screen (#45, owner's go 2026-11-19: "do #24, #34, and #44, #45, and #29"): with the setting off, only the admins, super admins, and the person can read a member's, and everyone a coach's.
  - **Coaches:** team admins turn on **Coach** on a person's card, for a parent who coaches too, for example. Coaches are listed together, their Owner or Admin badge kept. Until someone sets it, the owner counts as a coach.
  - **Play makers** (owner's request 2026-11-17, #63): under Coach, team admins turn on **Play maker** ("Can draw, save, and change the team's plays") on a member's card, so an assistant coach or a captain makes plays without managing the team (BOARD-4). Their card shows a Play maker tag beside Coach. Admins make plays anyway, so an admin's card has no switch; a group (TEAM-14) has no plays, so none there. It's set through `updateGroupMember`, audited, and a play maker brought into a new season stays one (TEAM-16).
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
- **TEAM-5 · MVP · Admin settings (admins).** Called Team settings until 2026-10-27, and Team admin until 2026-11-10; it opens from Team settings (the gear), under For admins.
  - **The order** (#32, owner's go 2026-11-17: it was about five phone screens, with three look-alike color settings far apart and three ways of saving): the team's panel (logo, name, sport, description, Save); a card with **Time zone** and **Manage invite link**; **Look**, with the team color, then **Chat look** and **Team color scheme** ("Group color scheme" in a group) as rows that open their own pages; then member permissions, Language, default event reminders, notifications for new members, Storage, Owner actions (owners and super admins), and About last. At 390 px it's 2,238 px from the team's panel to About's end, from 3,376.
  - Edit name, sport, logo, color, description, and time zone.
  - **One Save for the name and description** (#32): the panel's coral Save saves both together, and is on only while one differs from what's saved and the name isn't empty; Enter in the name does the same. The sport, logo, color, switches, and chips save as soon as they're touched. If another admin renames the team meanwhile, the fields follow unless I've typed in them.
  - **"Save your changes?"** (#32): leaving with the name or description changed and not saved asks first, from the back chevron, Android's Back, the iOS back swipe, and on wide screens the rail and the team header: "Your changes to the team's name and description aren't saved yet." ("the group's" in a group), with Discard in the warning red and a coral Save, which saves, then leaves (or stays, saying why, if the save fails). Closing it stays with the text as typed; with nothing changed, leaving never asks.
  - **Team color:** the 15 colors as swatches, in this order: Blue (new teams start on it), Light blue, Navy, Teal, Green, Olive, Yellow, Mustard, Orange, Red, Maroon, Pink, Purple, Gray, and Black, under "Your team color is on the team's badge and in the team switcher." (TEAM-1, §7.4); a group's says "The color is on the group's badge and in the switcher." Royal blue and Violet were taken out in 1.1 as too close to Blue and Purple: a team still set to one keeps it, and the app shows it as Blue or Purple (its swatch picked and its badge in that color).
  - **Member permissions** (defaults in brackets):
    - create events [off]
    - create polls [on]
    - upload documents [on]
    - invite others [on]
    - allow "Maybe" RSVPs [on]
    - everyone can see who's on the team [on]: off, only admins see all the people on the roster (TEAM-3), and the phone numbers and emails members share (TEAM-10, #45)
  - **Language:** filter strong language [on] (SAFE-7).
  - Default event reminders: none, so reminders are off until a team or an event turns them on (owner's request 2026-11-01).
  - **Notifications for new members:** All activity [default], Important only, or Off: where the team notification level (NOTIF-3) starts for people who join from then on, whether by the team link, an email invite, being added by email, or being linked to a player. Each person can still change their own, people already on the team keep theirs, and the owner who creates a team starts on All activity (owner's request 2026-11-10: "Turn off notifications on the tester teams. Allow them to opt in if they want.").
  - **Manage invite link** opens Link settings (INV-2) over Admin settings: the link's expiry and uses, Reset, and Turn off, or Turn on a new link while it's off (#16).
  - See storage used, e.g. "112 MB of 200 MB", and open Media to free space (STORE-2, STORE-5).
  - **About**, at the end, at the owner's request: the version and build, "Developed by Jared Freeman", that Battleplan is free and Jared builds it as a volunteer, and **Buy Jared a coffee**, which shows his Venmo card (a QR code to scan) and **Open Venmo** for paying from the same phone. A tip is voluntary and unlocks nothing.
- **TEAM-6 · MVP · Transfer ownership.** The owner picks a member to take over and becomes an admin.
- **TEAM-7 · MVP · Add members by email (admins).**
  - Add one person at a time, or paste a list of "Name, email" lines (up to 100).
  - People who already have accounts are added and notified. New emails get an account and a setup email (AUTH-6).
  - A results screen lists who was added, who was invited, and any problems. People whose setup email didn't send (most often past the day's email limit) are added all the same and listed under **Added, but the setup email didn't send**, with "Try again tomorrow when the limits are reset, with Resend setup email on their card." Adding a guardian by email (PLAYER-5) and **Resend setup email** say the same when the email doesn't send.
  - **Today's email limit** (#47): setup emails are essential, so they use the room kept back from invites and RSVP emails; past the whole day's budget they wait, the people are still added, and the results say "2 setup emails couldn't be sent today because of the daily email limit. Use Resend setup email on each tomorrow." "Added to team" notes are bulk: when they can't go, the person is still added and gets the in-app notification.
  - To fill the Players section, admins add players with the player's or their parents' emails instead (PLAYER-1).
- **TEAM-8 · MVP · Leave a team.**
  - Anyone can leave, from their own card on the roster (the **Team** tab → their name → **Leave team**), after confirming. It isn't in Team settings, as it once was in the team menu, where it was too easy to tap by mistake (2026-10-15, at the owner's request).
  - The owner must transfer ownership first. If they're the only member, they archive or delete the team instead.
- **TEAM-9 · MVP · Archive or delete (owner, super admins).**
  - **Archive** makes the team read-only and moves it to "Archived" in the switcher. It can be restored.
  - **Delete** requires typing the team name. It permanently removes all messages, events, documents, and files. A big team can take minutes; if it stops partway, whoever started it can try again, and the server finishes it within the hour either way.
- **TEAM-10 · v1.1 · Roster details.** Built (task 136).
  - Sort the roster's players by jersey number (the default; players without one come last) or by name, from the sort button. (Numbers live on players, PLAYER-1, and a member who is a player shows theirs.) Admins and members are listed by name, the owner first.
  - Optional contact sharing: on their own card, members share a phone number and email with that team ("Share my phone and email"; the account's email is offered), and change them or stop sharing at any time. They appear on their card with call, text, and email buttons for everyone who sees that card (TEAM-3): the whole team, or with "Everyone can see who's on the team" off, the admins, and everyone for a coach. They're kept in a record of their own that the database shows only to those people (#45), since anyone on the team could read the membership they were on before, with a little technical effort; the first night after the release moves what was shared before, and until then the card still shows it. Each team is separate. Sharing needs an open team; stopping works even on an archived or suspended one. Leaving the team or deleting the account removes them.
- **TEAM-11 · MVP · Players on every team.** Players, guardians, and claims are specified in §6.3 (PLAYER).
- **TEAM-12 · v1.1 · Announcement-only mode.** Only admins can post in chat. Everyone can still react, vote, and RSVP.
- **TEAM-14 · v1.1 · Groups beside teams.** (Owner's request 2026-10-29.) Created from **Create a Team** or **Create a Group** (TEAM-1). Its owner (or a super admin) can **Make it a team** in Admin settings, picking its sport: it gets players, the parents who answer for them, coaches, and Plays, keeps its people, chat, schedule, answers, and documents, its owner coaches from then on, and the chat says "Pat made this group a team" (owner's request 2026-10-29). A team can't become a group. A group is for extreme simplicity; a team has everything. A group has every feature a team has (chat, schedule and RSVPs, assignments, dues, polls, documents and photos, invites, admins, notifications, imports, calendar links) except what's about players: no roster players, guardians, claims, "Who are you here for?", coaches, player details, or **Plays**, and no sport. Everyone in a group chats and answers RSVPs for themselves, and counts are of its members ("4/8 going"). In a group, as on a team, its admins set the default color scheme and each person can pick their own (SET-2). Its roster is the **People** tab (admins and members), its card says "Group · 8 members", **Group settings** and **Admin settings** have no sport, it has a group icon in Teams and the switcher, joining one (Join group) goes straight to its chat, and its tabs are Chat, Schedule, Documents, and People. The TeamSnap import has no Players box for a group. **Group words throughout** (#30, owner's go 2026-11-16): a group's settings say "Notifications for this group" (and its pushes "from this group"); Admin settings says Group name, Color with "The color is on the group's badge and in the switcher.", "Everyone can see who's in the group" ("Off: only admins see everyone in the group. Members see only themselves."), a chat look whose preview is a friend's message ("Sam: Moved to 7 tonight, same place."), not a coach's, and Group color among the message colors; and **Archive group**, **Restore group**, and **Delete group** ("Type the group name to confirm"). A group keeps **Start a new season**, since groups get everything that isn't about players, in group words: "A new group for the next season, with the people you choose", New group name, and "They're in the new group at once". Media names the group logo, and a member's own card has **Leave group**. A new group's setup card (TEAM-1) has no players step: **Get Book club ready**, **Invite people** and **Add your first event**, and the link says **Coming from GroupMe? Import**; its empty chat says "Only you so far. Invite people.", and its empty Schedule tells members "Admins will add them here." Versions of the app before groups show a group as a team, so the server and rules refuse players, guardians, player answers, coaches, a sport, and plays in a group whatever app asks.
- **TEAM-13 · Later.**
  - Join requests that need admin approval.
  - Organizations and leagues with club admins.
  - Sub-chats within a team ("Parents", "Coaches").

- **TEAM-15 · MVP · A person's page.** Owner's request (2026-10-16): "click on another user's icon to get to their user profile page… show what teams they're a member of and if they're a coach show that as well."
  - **Opening it:** tap someone's photo beside their messages in a team's chat or a direct conversation, **Profile** on their roster card (TEAM-3), or their name at the top of a direct conversation (CHAT-19).
  - **What it shows:** their photo and name, **Message** (CHAT-19), and **Teams in common**: each team you're both on, with its badge and what they are there: Coach, Owner or Admin, their title, and who's who from their players ("Player #12", "Parent of Emma #7", PLAYER-8), or Member. Teams they coach come first. Tapping a team opens their card on that team, with what they share there (TEAM-10) and the actions you have there.
  - **Only teams you share.** Teams stay walled off (TEAM-2): a team you're not on never shows. A team that keeps its people to its admins (TEAM-3) shows only when they coach it, you're one of its admins, or you opened the page from that team, where you've already seen them.
  - Its menu has **Block** or **Unblock** (SAFE-2), and **Report** on a team you share (SAFE-1).
  - **Your own page** lists all your teams, with **Edit profile** (SET-1).
  - Someone you share no team or conversation with shows only "This person isn't on any of your teams."
- **TEAM-16 · v1.1 · Start a new season.** A team starts its next season without inviting everyone again, which is where families drop off between seasons.
  - **Who:** the owner, on an open team, from **Start a new season** in Admin settings' owner actions. A super admin can't: the new team would be theirs.
  - **The screen:** the new team's name (it starts as this team's, and must change, "Thunder U15 · Spring 2027"), then **Who comes along**, all checked to start, each with its count:
    - **Players and their parents:** the active players, with their links, so parents and players answer as before without claiming them again. Their details (PLAYER-12) come too. Players waiting for approval stay behind.
    - **Coaches and admins**, keeping their roles, Coach, and titles. A coach who's also a parent comes as a parent when this box is off and the players' is on.
    - **Everyone else**, people added by email who haven't joined yet included.
  - **Also copy**, both off to start: **Documents** (files and links, without notifying anyone) and **Saved plays**. A group (TEAM-14) has no players or plays to bring.
  - The new team gets this team's logo, color, sport, description, time zone, settings, chat look, default color scheme, and default reminders, and a storage limit a super admin gave it (STORE-6). Everyone brought along keeps their notification level, what they share (TEAM-10), their color scheme (SET-2), and what they said to "Who are you here for?" without picking a player (PLAYER-3), so the new season doesn't ask again.
  - After a confirmation, everyone brought along is on the new team at once, with nothing to accept, and gets a notification: "Pat started the new season, and you're on the team." The owner lands in its chat, which says "Pat started this season from Thunder".
  - This team is archived (TEAM-9), its chat, photos, schedule, and results kept. Its chat says "Pat started the next season: Thunder U15 · Spring 2027", and its archived footer has **Go to Thunder U15 · Spring 2027** for people on the new team.
  - It counts as creating a team: a verified email, the day's limit and the on/off switch (TEAM-1, ADMIN-7), and the 100-team limit (TEAM-2). Someone already on 100 teams stays behind, and the owner is told how many.
  - Calendar links for this team go empty, as for any archived team; links for all my teams pick up the new one (SCHED-11).
  - It's audited, and super admins hear about the new team (ADMIN-9).

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
  - Linked members and admins can add a guardian (PLAYER-5). Admins can also unlink anyone and remove the player, and a linked member can unlink themselves (PLAYER-5).
  - **Upcoming RSVPs** (#37, owner's go 2026-11-17: "do #25, #36, and #37"): each event's title and when, with the player's answer at the end in its color with its icon (Going, Maybe, Not going), as RSVP history shows answers; "No answer" and "Canceled" are muted, with no icon. With large text the answer goes under the event, and the day and time wrap rather than end in "…". Screen readers hear each event as one line: "vs. Eagles, Mon, Oct 14 · 6:00 PM, Maybe". Tapping one opens the event. While they load, placeholder rows show, not a spinner.
- **PLAYER-3 · MVP · Claim a player.** Any member can claim an active player and say how they're linked: **"I am this player"** or **"I'm their parent or guardian"**.
  - A claim needs a team admin's approval (Q15). Until then, the member can chat but can't answer RSVPs for that player.
  - When an admin claims a player, it's approved at once, and so is a claim by a super admin who's on the team. A super admin who isn't on the team can't claim a player.
  - A player has at most one `self` link, and a member is `self` for at most one player per team. A player can have up to 4 guardians; the `self` link doesn't count toward the 4.
  - **Who are you here for?** Joining a team goes straight into its chat, with no questions first (owner's request 2026-11-10: "When people get invited to and join a team, let them go directly into the team without having to answer the questions about if they are claiming a player or need to add a player. They can claim a player once they're into the team."). A member who isn't linked to a player yet finds **Who are you here for?** from the prompts below, and it has three choices:
    - **I'm a player.** Pick yourself from the roster (a claim as yourself), or add yourself if you're not listed (a pending player linked to you as yourself, PLAYER-4).
    - **I'm here for a player.** Pick your player from the roster, or several (a claim as guardian), or add a player who isn't listed (a pending player with you as guardian).
    - **I'm a coach or another adult.** Nothing claimed, and remembered for that team.
  - **The prompts that lead there** (owner's go 2026-11-16: "Do #11", the usability review's "New parents can't tell how to answer RSVPs"), so someone who just joined learns how to answer RSVPs. They're for a team's members who aren't linked to a player: never its admins, super admins, a group, or an archived team.
    - **A card at the top of the team's chat:** "Here for a player? Pick who's yours so you can answer RSVPs." with **Pick my player** and **Not now**. It never has to be answered, and one tap closes it. A coach doesn't get it.
    - **A line on schedule cards** that show a count and no answer buttons, in a team's Schedule and in Your schedule: **Pick your player to answer**, on a team with players to pick from. The one-tap Going, Maybe, and Not going buttons stay for everyone who's linked.
    - **The event page** (PLAYER-6) and **Dues**, where they'd answer or pay.
    - **The Team tab's row,** above the roster, which always stays, so they can link later; it's bold only until they've answered.
    - **Remembered for each team, on every device:** **Not now** (or closing the card) and **I'm a coach or another adult** are saved on their membership (`hereFor`), and after either the card and the schedule's line don't come back. A new season (TEAM-16) brings the answer along.
    - **Asking comes back to where they were** (the chat, the schedule, an event, the Team tab, Teams, or Dues), with "Request sent to the team admins". Opened by its address, it goes to the team's chat.
    - **While a claim or a player they added waits,** each of those places says who for, instead of going quiet: "Waiting for the coach to approve Max" ("Max and Sofia" for two). The chat's card can still be closed, and the Team tab's row still opens the screen, for a second player. Once a team admin approves, all of it goes and the answer buttons show.
  - People whose email an admin already entered for a player (PLAYER-1) are linked automatically and never see it.
- **PLAYER-4 · MVP · Add a player (members), and admin approval.**
  - Any member can add a player: name, jersey number, date of birth (optional, PLAYER-12), and how they're linked (the player or a guardian).
  - A member's new player is **pending** until a team admin approves or declines it. A player an admin adds is active at once (PLAYER-1).
  - Pending players are shown only to admins and to the person who added them. They're not on the roster for everyone else, and can't get RSVPs or be claimed.
  - Claims and pending players appear at the top of the Team tab under **Waiting for approval**, oldest first, and admins get a notification for each one (NOTIF-2). The person is notified when it's approved. Admins also see how many wait on the Team tab's icon and on the team's card on Teams (§5.1, §5.3; #23, owner's go 2026-11-16). Schedule still has no count, and nothing reminds anyone later.
  - **Each request is one plain sentence** beside the requester's photo, with **Decline** (outlined) and **Approve** (coral) on their own line under it, each a full 48 px target, so the buttons never squeeze the words (#23). Nobody's pronouns are guessed:
    - a new player, as the player: "**Claire Dunphy** wants to join the roster as a player." (or "as player #7.");
    - a new player, as a guardian: "**Maria Rodriguez** wants to add **Emma Rodriguez #7** to the roster, as Emma's parent or guardian.";
    - a claim, as a guardian: "**Phil Dunphy** says they're a parent or guardian of **Noah #4**.";
    - a claim, as the player: "**Jared Freeman** says they're **Jared #12** on the roster."
  - **Tapping a request** opens it over the whole app (a dialog on wide screens), titled "Add this player?" or "Approve this link?". A new player's **Name** and **Number** are filled in and editable (a name of 1 to 60 characters, a number of up to 4); Approve saves a change first and then approves, and if the save fails it doesn't approve and says so. A claim shows who's **already linked** to the player ("Claire Dunphy, parent or guardian"), so the coach can tell a real parent from a mistake. Decline and Approve work as on the row; closing it changes nothing. Screen readers hear each row as its sentence, with "double tap to review".
  - **After deciding**, a snackbar says what changed for the person: "Phil can answer Noah's RSVPs now." for a claim; "Emma is on the roster. Maria can answer Emma's RSVPs now." for a new player ("Claire is on the roster." for a player who added themselves), with **Add number**, which opens the player, when it has no number; and "Declined. Phil can ask again."

  - Once an admin taps Approve or Decline, both buttons turn off and the tapped one spins until the server answers. Each claim and pending player is decided once: tapping again, or a second admin deciding at the same moment, changes nothing, so the person is notified once (owner's report 2026-11-10).
  - Admins can correct a pending player's name and number before deciding.
  - Approving a pending player makes it active with its link. Declining deletes the pending player and its link. A declined member can ask again.
  - Approving checks the PLAYER-3 limits again when the link is made. If they no longer allow it (say the member became a player meanwhile, or someone else is already this player), a claim isn't approved and the app says why, so the admin can decline it. A pending player is still added, without the link, and the app says so.
- **PLAYER-5 · MVP · Add another guardian.** From the player card, a linked member (the player themselves or a guardian) or an admin can add a guardian: someone already on the team, picked from a list, or anyone by email. An existing link is vouching for them, so no admin approval is needed. Someone picked from the team gets no email, only a notification that they're now the player's guardian. The list leaves out the people already linked to the player, and members of a team that keeps its people to its admins (TEAM-3) get only the email. New emails get an added account and a setup email. A player has up to 4 guardians, and the player can't also be their own guardian.
  - **Unlinking** (#37, owner's go 2026-11-17: "do #25, #36, and #37"). Each link someone may remove (any, for an admin; their own, for a linked member) ends in a worded **Unlink**, heard as "Unlink Sam Rivera", where a bare X didn't say what it does. With large text it goes under the name, so the name and "Guardian" keep the row's width. It asks first, saying who stops answering and seeing what, and that they stay on the team, with **Unlink** as the red button:
    - a guardian's own link: "Stop answering for Leo?" and "You won't answer Leo's RSVPs or see their details any more. You'll stay on the team, and you can claim Leo again later.";
    - the player's own link: "Unlink yourself from Leo #9?" and "You won't answer this player's RSVPs or see their details any more. You'll stay on the team, and you can claim the player again later.";
    - an admin unlinking someone else: "Unlink Sam Rivera from Leo?" and "Sam won't answer Leo's RSVPs or see their details any more. They'll stay on the team."
    - Afterward a snackbar says "You're no longer linked to Leo." or "Sam is no longer linked to Leo.", and claiming again works as any claim does (PLAYER-3).
- **PLAYER-6 · MVP · RSVPs per player, on every event.**
  - **On a team, only players have RSVPs** (owner's request 2026-11-06: "Let's not even track status of parents or coaches for now. Let's focus on players."). **Exactly one RSVP per event and player.** In a group, which has no players, everyone answers for themselves (TEAM-14).
  - A player's RSVP can be answered by the member who is that player, by its guardians, or by admins. When two people answer, they update the same record instead of creating two. The latest answer counts and shows who gave it ("Answered by Maria"), so attendance never conflicts or double-counts.
  - Guardians see one RSVP row per player, named by first name ("Luke"); an adult player answers on their own player's row, through their self link, named "You". There's no Me row: coaches and other adults have no answer of their own. Team admins and super admins can still answer for a player ("RSVP for a player").
  - Someone on a team with players who has nobody to answer for (a parent not linked yet, an adult player who hasn't claimed themselves) gets the next step where the answer buttons would be: "Pick your player to answer RSVPs" and a **Pick my player** button, which opens **Who are you here for?** (PLAYER-3; owner's go 2026-11-16: "Do #11", the usability review's "New parents can't tell how to answer RSVPs"; until then it stated the rule, with a small link). A coach who isn't an admin, and anyone who said **I'm a coach or another adult**, still gets the rule, "On a team, only players have RSVPs.", with the small **Who are you here for?** link. Someone whose claim is waiting is told who for: "Waiting for the coach to approve Max". Admins with nobody to answer for see no RSVP section, not even its heading, so Who's going follows the event's details with "RSVP for a player" beside it; the section shows only to give the deadline or say "RSVPs are closed." A team with no players shows its admins "Add players to take RSVPs" and nobody any buttons or counts; others, and everyone on an archived team, see no RSVP section, unless their claim is waiting.
  - When a member becomes linked as the player, their own answers to upcoming events move to the player's row. Where the player already has an answer, the player's answer stays and theirs is dropped.
  - Counts are players only: "12 of 15 players going". A team with no players shows none. A group counts everyone: "12 going · 3 maybe · 2 no".
  - Members' own answers from before (2026-11-06) are hidden on teams, not deleted, and don't count or decide who hears (PLAYER-7). Old builds may still write them until task 349.
- **PLAYER-7 · MVP · Reminders and changes.** Event reminders and event changes go to the member who is the player and to the guardians of the affected players, as one notification per person naming their players: "Emma, Liam: Practice today at 6:00 PM". For a member's own player, there's no name prefix. On a team, coaches and members not linked to any player have no answer, so they hear every change and reminder; in a group, members go by their own answer.
- **PLAYER-8 · MVP · Who's who.** In chat and on the roster, each member's name shows their players. A guardian shows "Maria R. · Emma #7". A member who is a player shows their number when it's set: "Jared F. #12".
- **PLAYER-9 · MVP · Players on several teams.** A person on two teams is a separate player on each team. In Your schedule (SCHED-2), each event shows which of a member's players it's for.
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
- **PLAYER-11 · v1.1 · Answering for several players, and RSVP history.** Built (task 137); the all-players shortcut was taken out on 2026-11-06 (task 358).
  - **Each player on their own row.** The owner's request (2026-11-06): "Remove the “all my players” option. Each player should be individually listed and addressed in the RSVP section." A member who answers for two or more players gets a row for each of them, named by first name ("Emma", or "You" for an adult player's own row), with that player's own Going / Maybe / Not going, wherever RSVPs are answered: the event's page, its chat card, the schedule list (a team's and Your schedule, SCHED-2), and an RSVP email and its answer page (SCHED-14). A tap answers for that player alone, and each keeps their own note. Nothing answers for all of them at once: the "All my players" row from task 137 is gone, and the RSVP email no longer asks "Are Emma and Liam going?" with one answer for both.
  - **RSVP history.** From the player card, the player's linked members (the player and their parents or guardians), the team's admins, and super admins open the player's RSVP history: the team's past events that took RSVPs in the last 3 months (or 6, or 12), newest first, each with the player's answer (Going, Maybe, Not going, or No answer) and opening its event, under totals for those events ("12 past events: Going · 9, Not going · 2, No answer · 1"). Canceled events are listed but not counted, and events from before the player was added to the roster aren't shown. Other members don't see it.

**Acceptance (MVP)**

- A coach pastes a roster of 15 players and their parents' emails, and every parent who finishes setup is linked to the right player.
- An adult player who joins by link picks "I'm a player", claims themselves on the roster, and answers RSVPs for themselves once an admin approves.
- A parent who scans the team's QR code at practice can claim their player, and is linked once an admin approves.
- A member who adds a missing player sees it as pending; it shows on the roster for everyone only after an admin approves, and a decline removes it.
- A parent with two players on the team answers for each one separately, and the coach sees accurate player counts.

### 6.4 Invites and joining (INV)

- **INV-1 · MVP · Invite screen.** It says what to do, with one main button (owner's go 2026-11-17, #16: it used to be titled just "Invite", with Copy link coral and checked before a tap, the QR code twice, and the link's settings out in the open).
  - Opens from **Invite** on the Team tab's card ("‹ Team", "‹ People" in a group), the setup card and the empty chat ("‹ Chat", #3), and right after creating a team.
  - **The title and a line under it**, muted, the page's first line:
    - Right after Create (TEAM-1), and only then: **"Hornets is ready!"** and "Send this link to your families so they can join." A group's says "Send this link to the people you want in the group."
    - Opened any other way, a web reload or a link included: **"Invite to Hornets"** and "Anyone with this link or code can join."
    - A long name takes two lines, as every page's title does (§5.1).
  - **The QR code**, black on white in every scheme so any camera reads it. Tapping it opens it full screen, to hold up at practice; a small round badge with an expand icon on its corner, half off the card and clear of the code's white margin, says so. Screen readers hear "QR code for the team's invite link, button, show full screen". Then the invite code (e.g. `K7XP-M2QR`) and the link as text, which can be selected.
  - **Share**, the one coral button, full width (at most 400 px on a wide screen or in the side panel): the system share sheet, or Web Share in a browser. **Copy link** is outlined under it. Copy link shows no check until it's tapped; then its icon becomes a check and it says **Copied** for 2 seconds, and screen readers hear "Link copied." (no snackbar). In a browser without Web Share (most computers), Share isn't shown and Copy link is the coral button. A share that fails anyway copies the link and says "Link copied."
  - **Email invites**, "Email each person their own link. They join when they're ready." (INV-4), and for admins **Add people by email**, "Put people on the team now. New people get an email to set up their account." ("on the group now" in a group, TEAM-7). Neither is bold, so the coral button is the page's one main action. They stay while the link is turned off, as neither needs it.
  - **Link settings**, for admins only: one row with the link's summary ("Never expires · Used 3 times", or "Expires Nov 30 · Used 3 of 20 times"), which opens the link's settings (INV-2).
  - **Continue to Hornets ›**, whenever the page has nothing under it (right after Create, or a reload): the third button, right under Share and Copy link, as wide and outlined like Copy link, so Share stays the one coral button, into the team's chat, where the setup card waits (#3). It was plain text pinned at the bottom of the page until the owner's report of 2026-11-19 (#69: "the continue to group/team button is not as obvious. it should be a 3rd button under share and copy link"); the bottom keeps it only while there's no link to show (loading, refused, or the link turned off).
- **INV-2 · MVP · Team invite link.**
  - Reusable.
  - Admins manage it in **Link settings** (#16), a sheet (a dialog on wide screens) opened from the Invite screen's Link settings row or Admin settings' Manage invite link (TEAM-5): the heading, the link's summary, then **Expiry and uses**, "How long the link works, and how many people can use it"; **Reset link**, "A new link and QR code. The old ones stop working."; and **Turn off link**, "Nobody can join with it until an admin turns on a new one.", in the warning red. Each closes the sheet, then asks as before. While the link is off the sheet says "The team's invite link is turned off." with **Turn on a new link**.
  - Admins can set an expiration (never, 1 day, 7 days, or 30 days) and a maximum number of uses.
  - **Reset link** turns the old link off immediately.
  - Members see the link only when "Members can invite" is on, and never see Link settings.
- **INV-3 · MVP · QR code.** Encodes the invite link. Works with the phone's camera app or the in-app scanner.
- **INV-4 · MVP · Email invites.**
  - Type or paste up to 50 addresses at a time, separated by commas or new lines, plus an optional note.
  - Each address gets its own single-use link that expires in 14 days.
  - A list shows Pending, Joined, and Expired invites, with Resend and Revoke.
  - Requires a verified email. Daily limits apply per person and per team.
  - **Today's email limit** (#47): invites are bulk email, so they send only as many as today's room allows, and the rest stay in the box for tomorrow, not invited and not counted: "Sent 12. Today's email limit is reached, so the other 8 weren't sent. Try again tomorrow." With no room, nothing is sent ("Today's email limit is reached. Try again tomorrow."), and a Resend says the same.
- **INV-5 · MVP · Joining.**
  1. Open a link. It opens the app if installed, otherwise the web app (WEB-4).
  2. Sign in or create an account if needed; the app continues automatically afterward. Sign-in, sign-up and first-run setup show the team on the way (its badge and "Join Hornets: sign in or create a free account", AUTH-1, AUTH-5, #24), so nobody wonders whether the invite was lost.
  3. See the team preview: logo, name, sport, member count, "Invited by Alex". Signed in (the apps, or the web app), it's a short confirmation on the app's frame (#20, owner's go 2026-11-16): **Join Thunder?** over the team's card (its badge, name, "Soccer · 12 members" (no sport in a group), and "Invited by Alex"), one coral **Join team** (**Join group**), and nothing about installing the app. It's the check that the code is for the right team, so a mistyped code never drops anyone into a stranger's team.
  4. Tap **Join team**: they're in the team's chat, whose card at the top says how to answer RSVPs. Claiming or adding a player waits until they want to, through **Pick my player** there or **Who are you here for?** on the Team tab (PLAYER-3).
  5. Land in the team's chat, where "Sam joined" appears.

  People who are already members just go to the team.
- **INV-6 · MVP · Join without a link.** "Join a team" (on Teams and in the team switcher) offers **Enter code** and **Scan QR code**, using the camera on phones and in the browser.
  - The code box is labeled "Invite code", with "8 letters and numbers from whoever invited you" under it (no sample code, which looked filled in). It takes the code with or without the dash, in any case, or a pasted link.
  - Its button says **Continue** (#20): it opens the preview (INV-5) over the box, so "Join team" is tapped once, on the real decision. The preview's back row says "‹ Join a Team or Group", and a quiet **Not this team? Enter another code** under Join also goes back; either way the code is still in the box, to fix a typo. A wrong code's message (INV-8) has the same way back.
- **INV-7 · MVP · Web join page.**
  - `/join/<code>` (served by the web app under `/app`, WEB-4) shows the team preview with one coral button for whoever opens it (#20):

    | Who | Coral button | Quiet button | Code and "Installing the app first?" | App Store badge |
    |---|---|---|---|---|
    | Signed in, any app, from the code box or a link | Join team | Not this team? (from the box) | no | no |
    | Signed in, phone browser, from a link | Join team | Open in app | no | no |
    | Signed out, phone browser | Continue in browser | Open in app | yes | iPhone and iPad |
    | Signed out, computer browser | Continue in browser | none | yes | yes |
    | Signed out, phone app | Sign in to join | none | no | no |

    Open in app is an outlined button, only in phone and tablet browsers (iPhone, iPad, Android), where the app can be installed. Apple's App Store badge and its credit line show in browsers not on Android; Google Play's badge joins it once that app is listed (Phase 5). Signed in from a link, with nothing under the page, its chevron goes up to Teams.
  - Shared in a messaging app (iMessage, WhatsApp, Messenger, Slack, Discord, and others), the link's preview says "Join Thunder U14 on Battleplan" and who sent the invite, with the team's logo, or Battleplan's card when the team has none or the link no longer works (1.1, ARCH §6.6).
  - Signed out in a browser, the invite code is shown large, so people can type it in after installing the app.
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
  - Day lines: small spaced capitals between hairlines (TODAY, YESTERDAY, SAT, MAR 8, 2025).
  - **Every message is a speech balloon** (Boot Camp Mix, #85, owner's pick 2026-11-22): a rounded box (corner 19) in a 3 px ink outline with a pointed tail. **Others'** are in the panel color, on the left, the first of a run with its tail pointing from near the top toward their **dog tag**: a 42 × 30 tag in their color (SET-8) with a punched hole and their initials in ink stencil (or their photo), in an ink outline on a hard shadow, turned -7°. Above the balloon, on the first of a run, their name in stencil capitals, their players or number muted ("MARIA R. · Emma #7", or "JARED F. #12" for a member who is a player, PLAYER-8) and the time. Photos sit inside the balloon, above the caption. A person's run of messages (within 5 minutes) shows the tag and name on the first. In a direct conversation (CHAT-19) the other person's messages have no tag or name beside them. An admin's announcement (CHAT-15) is a mustard balloon. A deleted message is an empty outline.
  - **Mine** are balloons on the right in my own color (mustard, or light blue in Black), or the one the chat look picks (CHAT-18), with ink text, the last of a run with its tail from near the bottom right, fitting their text up to 75% of the column (at most 520 px). "Sent" shows under my newest. "edited" and "Pinned" go beside the time.
  - Message text is Comic Neue Bold, 17 points on 23, the same on every platform (§7.3).
  - Times appear on tap (phones), on hover (web), and at the start of each group.
  - **An empty chat** says "No messages yet. Say hi to the team!" A team admin who is its only member is told "Only you so far. Invite your team." ("Invite people" in a group), with a coral **Invite** button (#3). While a new team's setup card shows (TEAM-1), the card takes the empty chat's place. Once the chat has messages, the card sits above the first one, at the very top of the history. A direct conversation's empty chat is unchanged.
- **CHAT-2 · MVP · Composer.**
  - Multi-line text up to 4,000 characters, with a counter near the limit, and a Send button.
  - One rounded panel (corner 27) in a 3 px ink outline on a hard shadow, with the **+** inside its left edge, the hint "Message Thunder U14…", and Send inside its right edge: a 36 px red round button in an ink outline with a white arrow, faded while there's nothing to send (#85).
  - The **+** menu: Photo library, Camera (phones), Create poll.
  - On web, Enter sends, Shift+Enter adds a line, and images can be pasted or dragged in; they wait in the tray above the box until Send (CHAT-3).
- **CHAT-3 · MVP · Photos.**
  - Up to 10 per message, resized before upload, with progress shown on each photo.
  - **A preview before sending** (#26, owner's go 2026-11-16): photos from the library, the camera, or pasted or dropped on the web wait in a tray above the message box, nothing reaching the team until **Send**: 72 px thumbnails, each with an **X** to take it out ("Remove photo 2"), and a tile to add more from the library until there are 10 (more say "A message holds up to 10 photos."). The box's hint becomes "Add a caption…": what's typed goes with them as their caption, and Send works with no caption too. Taking the last one out leaves the box as it was. They start uploading as they're added, with a ring on each until it's up, so Send is quick; one whose upload failed (offline, say) is marked and uploads again on Send. Before, a picked photo went to every family at once, and deleting it left "This message was deleted." after the push had gone out. A photo taken out, or a tray never sent, has its upload deleted by the daily cleanup after a day (ARCH §6.4).
  - Shown as a grid. Tap for a full-screen viewer with pinch-zoom, swipe between photos, save/download, and share.
- **CHAT-4 · MVP · Delivery states.**
  - Each message shows sending, sent, or failed (tap to retry or delete).
  - Offline, text messages queue and send by themselves when the connection returns. Photos wait for a connection.
  - The send queue spaces messages at least 1 second apart, which keeps everyone under the posting limit (SAFE-5) without noticing.
- **CHAT-5 · MVP · Links.** URLs are tappable and open in the browser. On phones, phone numbers and email addresses are tappable too.
- **CHAT-6 · MVP · Reactions: 👍 Like · ❤️ Love · 👎 Dislike · 😂 LOL, plus 🔥 👏 🎉 💯 🙏 😮 😢 😡 ⚾ 🏀 ⚽ 🏆.**
  - Open the picker with a long-press (phones), the hover button, or a right-click (web). Double-tap a message to ❤️ it (phones).
  - The picker, at the top of the message menu: the four favorites on one row, then the other 12 in two rows of 6, each emoji centered in an equal cell, so they sit in straight columns with no ragged last row; where 6 won't fit with 48 px targets (a narrow phone with large text), three rows of 4. Every target is at least 48 × 48 (§7.6), and the dialog on wide screens has the same grid (#19, 2026-11-16: a wrap made rows of 4, 8 and 4).
  - **One reaction per person per message.** Picking another replaces yours; picking the same one removes it.
  - Under the message, each reaction is a pill chip (#85): the emoji and its count in stencil, on the panel color, yours on your own color, in a 2.5 px ink outline, 6 px apart, set in from the balloon's edge and overlapping its bottom: its 48 px tap area reaches up over the balloon rather than pushing the layout down. Tap one to add that reaction, or to take yours back if it's yours. Long-press or right-click one, or choose See who reacted in the message menu, to see who reacted.
  - ❤️ is always red, on fonts that only have a plain heart too.
- **CHAT-7 · MVP · Message menu** (long-press or right-click), from anywhere on the message's row: its full width and the padding between messages, not only the words, since others' messages have no bubble and a press beside a short one did nothing (#19, 2026-11-16). With a mouse, the hover button and the time show while the pointer is anywhere on the row, and the row is faintly tinted (5% of the text color) so it's clear whose button it is; the row keeps the tint while its menu is open, which also shows a long-press registered. Tap (the time), double-tap ❤️, swipe to reply, the keyboard, and a screen reader's action stay on the message, and the photo, reaction chips, links, and poll and event cards keep their own presses. A deleted message has no menu.
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
  - **Chat tab.** A badge shows the current team's count. Another team's unread messages put a dot on the header's arrow back to Teams, the one sign of news in your other teams (NOTIF-11); a muted team's don't. Until 2026-11-16 they put a second dot by the team name.
  - **Inside the chat.** A "New messages" divider marks the first unread message, and a "↓ 12 new" button appears while scrolled up.
  - Messages count as read once they're on screen, and sending a message marks the chat read.
  - Read position syncs across devices: reading on the phone clears the count on the web.
- **CHAT-10 · MVP · System messages.** Small, centered lines for: joined, left, removed, made admin, team renamed.
- **CHAT-11 · MVP · Cards in chat.**
  - New polls appear as interactive poll cards (POLL-2).
  - New events appear as event cards when their creator checks "Post to chat" (off by default, SCHED-3): the schedule's card (SCHED-1) beside the author's icon, with its type's edge, the title and type, the time and place, the schedule's attendance line (the mini bar, "2/4 going", and "Luke hasn't answered" for someone you answer for), and an RSVP row per person you answer for. Polls are as wide as the column allows, up to 420 px; yours sit on the right in your bubble. Members linked to players answer for each of their players right on the card (PLAYER-6).
- **CHAT-12 · MVP · Blocked people.** Their messages are collapsed ("Message from someone you blocked · Show"), and they don't notify you.
- **CHAT-13 · MVP · Reply to a message.**
  - Reply from the message menu, or swipe right on a message (phones).
  - The composer shows the quoted message (the author and first line, or "Photo" or "Poll") with ✕ to cancel.
  - The sent message shows the quote above the reply: on the page for others' replies, and in your bubble in its own colors for yours, readable in every scheme and Chat look color. Tapping the quote jumps to the original, loading older messages if needed.
  - The server creates quotes from the original message, so they can't be faked.
  - If the original is deleted, the quote shows "Original message was deleted".
  - The person replied to gets a notification, even at "Important only", and a notification-center item (NOTIF-11).
- **CHAT-14 · v1.1 · @mentions.** Built (task 135).
  - Typing @ suggests team members whose name, or a word of it, starts with what's typed, up to 5, never yourself. Tap one, or use the arrow keys and Enter or Tab on a keyboard; Escape closes the list. Picking one puts "@Full Name " in the message.
  - A message names whoever's full name follows an @, matched without regard to case, with the longest name winning ("@Mary Ann Lee" over "Mary Ann"). An @ inside an email address never counts. Up to 20 people per message, on text messages and photo captions.
  - Mentions are shown in bold, with the name the person had when it was sent, and a mention of you, or @everyone, is highlighted. They reach the person even at "Important only", with a notification-center item ("Alex mentioned you: …"). Someone who is both replied to and mentioned gets only the reply. The Mentions switch (NOTIF-4) turns the push off; the message then reaches them like any other.
  - @everyone is for admins only, and reaches everyone on the team as a mention. A member typing "@everyone" names nobody.
  - Editing a message doesn't notify anyone new.
- **CHAT-15 · Edit (MVP), pin and announce (v1.1).** All built: editing in the MVP, pins and announcements in task 135.
  - **Edit** your own messages; edited messages are marked "edited", and quotes in replies follow.
  - Admins can **pin** up to 3 messages to a bar at the top of the chat, from the message menu (Pin, Unpin). The bar shows the newest pin first, "Pinned 1 of 3" when there are several; tapping it opens that message, loading older messages if needed, and moves on to the next pin. Pinned messages say "Pinned" beside their time. A fourth pin is refused with "Unpin one first." Deleting a pinned message takes it off the bar. Not on an archived team.
  - Admins can send **announcements**: + → Announcement, then the next text message is one ("Announcement: notifies everyone on the team, even at Important only", with ✕ to cancel). It shows as a lemon card with a lip, a megaphone and "Announcement" at its head, in the chat, and notifies everyone who hasn't turned the team off or muted it, even at "Important only", with a notification-center item ("Announcement from Coach: …"). It stands in for the reply and mention notifications. There's no switch to turn announcements off; muting the team or setting it to Off does.
- **CHAT-16 · v1.1 · Files in chat.** Attach any document type; it's also saved to the Documents tab.
- **CHAT-17 · Later.**
  - Searching all of a person's chats at once, or for part of a word, which needs a search service or SQL (ARCH §12). Searching one chat by whole words is built (CHAT-20).
  - Link previews, GIFs, video, voice notes.
  - Typing indicators and read receipts.

- **CHAT-18 · MVP · Chat look.** On its own page, from Admin settings → Look → **Chat look** (#32; until 2026-11-17 a section near the bottom of Admin settings), which says the color and background ("Cherry, plain background"). Team admins choose the chat's message color and background (Plain; Sprinkles, small candy-colored dashes; or a photo), which everyone on the team sees, with text kept readable (WCAG AA): the sprinkles and the photo sit under the page color, as much of it as keeps the scheme's text and muted text at 4.5:1 over any sprinkle or a photo's white or black (a photo at least 78%). The colors are seven candies, Blue raspberry, Bubblegum, Grape, Mint, Lemon, Tangerine, and Cherry, and the team color last. Each color scheme draws a candy in its own shade, with dark text on it; the team color has white or dark text, whichever reads better. Nothing picked is coral (Cherry), every scheme's "you" color, listed first, on a team; in a group (TEAM-14) it's light blue, Blue raspberry (owner's request 2026-11-08: "make light blue the default message color for groups."), shown as picked until an admin picks another. Team color is saved as that choice, not a copy of today's color, so the bubbles change when the team color does, and a team with no color gets coral (#34, owner's go 2026-11-20). A palette color saved before #34 (by Team color then, or from the old 13-color palette before 1.1) stays as it was and shows as a swatch of its own after Team color, named for its color ("Green") and marked as picked; it goes away once an admin picks something else, and Admin settings names it the same way ("Green, plain background").
- **CHAT-19 · MVP · Direct messages.** Owner's request (2026-10-16): "add a direct messaging feature that allows users to directly message each other." Q5 had put them after launch.
  - **The same chat, for two.** A conversation works as a team's chat does: text, photos (CHAT-3), replies (CHAT-13), reactions (CHAT-6), editing and deleting your own (CHAT-8, CHAT-15), delivery states and the offline queue (CHAT-4), links (CHAT-5), the read position across devices, and the language filter (SAFE-7). What belongs to a team isn't there: polls, announcements, @mentions, pins, the chat look, and system lines.
  - **Who you can message:** anyone you share a team with who has joined (not "Not joined yet"), from **Message** on their page (TEAM-15) or their roster card (TEAM-3), or from **New message** in Messages, which lists the people your rosters show you (TEAM-3) with the teams you share, searchable by name. A suspended team doesn't count. Once started, a conversation stays, even when you no longer share a team.
  - **Messages:** the envelope button in the header, beside the bell, on every screen size (two speech bubbles until 2026-11-16, which looked like the Chat tab's). The same envelope marks Messages, a conversation's header, and direct-message notifications. It counts the conversations with unread messages, muted ones left out, and opens Messages: your conversations, newest first, each with the other person's photo and name, the newest message ("You: …" for yours), when, and how many you haven't read (gray when muted). A conversation shows there once it has a message. **New message** starts one.
  - **A conversation:** the other person's photo and name at the top, which open their page, and a menu with Profile, Mute or Unmute (pushes only; unread counts stay, NOTIF-3), and Block or Unblock. An empty one says "Say hi to Jordan. Only the two of you see this conversation."
  - **Private.** Only the two people read it, not super admins, who can read team content (LEGAL-1). A report (SAFE-1) shows super admins what was reported, and they act on it from the admin panel.
  - **Blocking (SAFE-2).** You can't message someone you blocked: the composer says so, with Unblock. Someone you blocked can still send, unknowing, but nothing reaches you: their conversation leaves your Messages, their messages are collapsed if you open it, and you get no notification. Nobody is told they're blocked.
  - **A deleted account (AUTH-10).** The other person keeps the conversation, read-only, with the messages from "Deleted user", and can still delete their own. A conversation nobody is left in is deleted with everything in it.
  - **Photos:** a conversation holds up to 50 MB of photos, apart from any team's storage (STORE-1). Once full it says so, and text still sends.
  - **Limits (SAFE-5):** 20 new conversations per person per day; sending is spaced as in team chat, 1 message a second.
- **CHAT-20 · v1.1 · Search.** Owner's request (2026-11-02, from the list of features to add: "implement feature #5, search in the chat"). A chat's messages, found by the words in them, in a team's chat and in a direct conversation.
  - **Where:** the magnifier on the Chat tab's pinned row, at the top of the chat (with nothing pinned, the row is a quiet "Search {team}" entry that opens the search), the magnifier in a conversation's header, or Ctrl/⌘+F on web and desktop.
  - **Searching:** type words and press Enter (Search on a phone's keyboard). The results are the messages with every word, newest first, 20 at a time with more as the list nears its end: who sent each, its day ("Today", "Mon, Oct 6"), a mark for a photo, poll, or event, and its text from a little before the first word found, with the words found in bold. It searches text, photo captions, poll questions, and event cards (their title, time, and place), not system lines, and leaves out deleted messages and messages from people I blocked (SAFE-2). Nothing found: `No messages with "pizza".`
  - **Words, not letters:** "tournament" finds "Tournament!", "tournaments", and "TOURNAMENT"; accents don't matter ("jose" finds "José"), nor apostrophes ("obrien" finds "O'Brien's"). Part of a word doesn't ("tourn"). One letter and everyday words ("the", "and") aren't searched; a search of only those says to try a longer word. The steps and the list of everyday words are in `shared/search_words.json`.
  - **Opening a result:** tapping one opens the chat at that message, briefly highlighted. One from long ago opens the chat there in a page: newer messages load as you scroll down, older ones as you scroll up, and **Newest messages** goes back down.
  - **Coming back:** search keeps the last search and its results while the app is open; Clear starts over.
  - **Offline:** it searches the messages the device has, and says so.

- **CHAT-21 · MVP · Next up.** Owner's go (2026-11-19, #43): the next practice or game showed in a team's chat only if its card happened to be in view, and answering took three taps. At the very top of a team's or group's chat, under the header and above the pinned row (and the player pick card, PLAYER-3), one slim row on the page with a hairline under it, not a card and never a message: nothing is posted, and "Post to chat" stays off by default (SCHED-3).
  - **What it names:** the team's next event that hasn't ended, within the next 14 days: a muted calendar icon, "Next up", the title (the type alone for a plain "Practice", the type before a "vs." title: "Game vs. Hornets"), when ("Today 4:00 PM", "Tomorrow", "Sat 4:00 PM", "Sat, Nov 28" after this week, "All day"), and the place, on one line or two with large text, cut with "…". Nothing coming up in 14 days: no row and no gap.
  - **Answering in one tap:** while the one person I answer for hasn't answered, **Going** and **Not going** as the cards' pills, at the end of the row on a wide screen and under it on a phone or with large text; a tap saves as the Schedule's buttons do and turns into the answer as a flat tag in its color with its icon. Maybe is on the event's page. Answering for several people (a guardian of two players, PLAYER-6): a coral dot and "Answer for Leo and Noah" ("for 3 people" past two) instead, which opens the event, where each has a row.
  - **No buttons and no coral dot** past the deadline (for members) or once it starts, for a member not linked to a player yet (the pick card under it says how), and for a super admin viewing (ADMIN-3); a canceled event says Canceled in a muted tag. An archived team has no row.
  - **A tap** anywhere but the buttons opens the event; Back returns to the chat. It isn't in a direct conversation, and it's gone while the keyboard is up.
  - **Screen readers** hear "Next up: Practice, Saturday 4:00 PM, Field 3. Needs your answer." (or "Your answer: Going."), then the buttons.
  - **One source:** the row and the line on the team's card on Teams (§5.1) read the same next event and answers as the Schedule, so the three always agree.

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
  - **Look** (Open Field, 1.1): my own poll is drawn inside my coral bubble in dark text: a POLL head with the time, the question in Nunito extra bold, each option a row with a ring (filled, with a check, when chosen), its votes and share ("8 votes · 73%") and a 6 px bar, and a footer rule with "11 people voted" and underlined See votes and Close poll links. Others' polls are Open Field cards (rim, lip, corner 18) beside the author's icon.
  - **A closed poll reads as a result** (owner's go 2026-11-17, #53: it kept the rings of an open poll, and its winner was barely bolder): no rings or squares, only a plain check on my own choices, with the ring's room kept so the options line up; a filled trophy right after the option or options with the most votes (a tie marks each, no votes marks none), which stay bold and keep their mint bar while the other bars go quiet gray (in my bubble, ink and faded ink). The rows aren't buttons; the count still shows who chose it, as does a long-press (POLL-3). Screen readers hear "Saturday, 8 votes, 73%, your choice, most votes". A poll nobody can vote in yet (an archived team, a super admin viewing) drops its rings the same way and keeps my check, with no winner marked. With large text an option's count goes under it, and who asked and when go under POLL, so no word is split or cut off.
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
  - **Upcoming** (default): a list of event panels under month labels (an ink block with the month in mustard stencil and a mustard star, turned a little). Each panel (Boot Camp Mix, #85) has a **date pennant** down its left side in the event's color (red game, blue practice and meeting, purple social, orange other) under a halftone, ending in a point, with the weekday in small stencil over the day in big outlined stencil; then the title in stencil ("VS. EAGLES"), the time, and the place with how many are going, out of the players on a team or the members of a group ("Riverside Park · 7/12 going", no count on a team with no players). Your answer is stamped at its top right ("GOING!", "MAYBE", "CAN'T GO") where everyone you answer for gave the same one. Under a 3 px ink rule, on the answer row's own color, an RSVP row per person you answer for (SCHED-4, PLAYER-6): their name with a question mark ("NOAH?", mustard on Army green and Black, ink on Light), with a dot in your own color while they haven't answered, and the push buttons.
  - **Past**: the same list, newest first.
  - **Calendar**: a month grid with a dot for each event; tap a day to see its events.
  - **The + and the filter** (#85): round buttons in an ink outline at the right of the Upcoming, Past and Calendar row, the + red with a white plus; the current view is on a mustard tile, turned a little. **Import a schedule** (#22): for the team's admins, a quiet outlined button floating at the bottom right opens Import, which stays in Team settings under For admins. Not while the empty Upcoming offers it already (below), so it's never on the screen twice, and not before the schedule has loaded. On a narrow screen with large text its words are cut short rather than crowding the +.
  - **Nothing coming up** (#3): a team's Upcoming, with no filter on, says "No upcoming events." with a coral **Add an event**, which does what the **+** does (full storage says why, STORE-4), for anyone who can make events (SCHED-3), and under it, for the team's admins, a quiet **Import a schedule** link to Import. People who can't make events read "No upcoming events. Your coaches will add them here." ("Admins will add them here." in a group). Past, a filtered view, an archived team, and Your schedule just say there's nothing.
  - **When it can't load** (#40): an event the app can't read (a field of the wrong type) is left out and reported once to the crash log by its id, so one damaged event never hides the rest; RSVPs and assignments too. A list that stops before showing anything says "Couldn't load this. Check your connection and try again." with **Try again**, which starts it over with placeholder rows, and never the empty state, so nobody mistakes a failure for "No upcoming events". One that stops after showing events keeps them, under a slim "Couldn't refresh. Try again" in the scheme's warning look, gone with the next fresh read. This holds for Upcoming, Past, the calendar, and Your schedule's See all; Your schedule on Teams says it in one muted line with Try again, so it doesn't take over Teams. A Load more that fails says "Couldn't load more. Try again" at the end of the list, and an event's page that can't read its event says it couldn't load, with Try again.
- **SCHED-2 · MVP · Your schedule.** Every team's events in one place, at the top of the app and not inside a team (the owner's request, 2026-11-12: "Im not real fond of the "All my teams Every team you're on, in one schedule." feature. not sure people want that because it can be confusing if you have another team's event on the team's schedule. rethink that and the screenshots. maybe add an overall consolidated schedule at the top level where you choose teams, below the teams it could be like "your schedule" that shows the consolidated schedule and events of all teams and groups you are a member of.").
  - **The same next event everywhere** (#43): each team's card above it says the team's next event and whether it needs your answer, and the team's chat starts with it (CHAT-21), from the same reads, so they agree with Your schedule.
  - **On Teams**, below your teams and above Join and Create (§5.1): the heading **Your schedule** and what's next across every team and group you're on, soonest first, as the schedule's cards (SCHED-1). Each card names its team beside its color dot and, for members linked to players on several teams, their player ("Lightning U10 · For Emma", PLAYER-9), and you answer right on it, a row per person you answer for, exactly as on a team's schedule (SCHED-4). Tapping a card opens the event in its own team, in that team's color scheme; Back returns to Teams.
  - **The next five**, so Join and Create stay within reach, then a **See all** row. Next means not over yet: an event that has ended today is left off here (See all still has it, under Upcoming, which runs from the start of today like a team's). The five always show every type, whatever the type filter is set to.
  - **Archived teams are left out**; their events stay on their own Schedule tab. A person on one team still gets Your schedule: it's their what's next. Someone with no team (the welcome), or only archived ones, doesn't see it.
  - **With nothing coming up** it says "No upcoming events." in one quiet line, and still offers See all, for the past.
  - **See all** opens Your schedule as a page of its own (`/teams/schedule`) in your default color scheme, with "‹ Teams": **Upcoming**, **Past** (Load more), and **Calendar** across the same teams, with the type filter, each event naming its team and opening in it (Back returns to the page). There's no **+**: events are made in a team.
  - **A team's own schedule shows only that team's events.** Until 2026-11-12 an All my teams switch in its filter sheet merged every team's into it, which put another team's events on a team's schedule. The calendar link's All my teams (SCHED-11) is a different thing and stays.
  - Built for parents with kids on several teams, and for players on several teams.
  - **Filter by type:** Games, Practices, Other. One filter icon at the right of the Upcoming / Past / Calendar row opens a sheet with the type filters; changes apply at once, and the icon shows a coral dot while one is on. The filter is one setting, shared by every team's schedule and Your schedule's page, so a filter left on in a team can make the page show fewer events than Teams' five; the dot says why.
- **SCHED-3 · MVP · Create an event.** The **+** button, if you're allowed.
  - **Type:** Game, Practice, Meeting, Social, or Other.
  - **Basics:**
    - Title. Left blank, a game fills itself in as "vs. Opponent" or "@ Opponent", and a Practice, Meeting or Social is saved as its type ("Practice"); the field shows that in grey before Save, following the type picked. Only Other needs one typed (#17, 2026-11-16: Practice, Meeting and Social always needed one, and Save said so out of sight).
    - Date; start and end time, or all-day; time zone, defaulting to the team's. A new event starts today at 6 PM in the team's time zone, or **tomorrow** at 6 PM once it's 6 PM there, so one made in the evening isn't already over (#17).
    - Location (name and address, with Open in Maps).
    - Notes.
  - **Game fields:** opponent, home or away, arrival time ("Arrive 30 min early").
  - **RSVP:** on or off (default on), with an optional deadline.
  - **Reminders:** defaults from Admin settings. **No reminders** (picked while no time is, and the default for new teams) or any of 15 min, 1 h, 2 h, 1 day, 2 days, or 1 week before; tapping No reminders clears the times picked. Admin settings' Default event reminders offers the same No reminders choice (owner's request 2026-11-08: "make sure it's possible to set events to have no reminders and to have it set to no reminders as a default"). Teams made before 2026-11-01, when new teams started with No reminders, kept the old default of a reminder the day before; those still on exactly that were switched to No reminders once, on the first night after the release that brought #48 (owner's go 2026-11-19). Teams whose admins had chosen anything else, and every event already made, kept theirs; nobody was told, and admins can turn reminders back on in Admin settings.
  - **Counters** (0/100 and the like) show under a field only once its text reaches 80% of the limit (#17).
  - **Saving.** When something keeps it from saving (a title for Other, a date, a deadline after the start, the repeat settings, or text over a limit), Save scrolls to the first field with the problem, puts the cursor there, and says what's wrong in a message screen readers hear. A **new** event (or a duplicate) whose start has already passed (all day: a day before today) asks first: "This is in the past. Save anyway?" with **Save anyway** and **Change date**, which goes to the date and opens its picker. Past events stay allowed, as for last season's games; editing one, as to fix last week's notes, doesn't ask.
  - **Notify team** (default on) and **Post to chat** (default off). The team isn't notified about an event made after it started: the server leaves out the "new event" push however the box is set, while Post to chat still posts its card (#17). An event goes in the chat only when its creator checks Post to chat, since the schedule and Notify team already cover it (owner's request 2026-11-10: "events dont need to go to the chat by default. that makes it too cluttered and redundant. only put event info in the chat when the user explicitly checks the “notify team in chat” option, or something similar to that."). Builds of the app from before then still start it checked.
  - **Repeat:** doesn't repeat (default), or:
    - **Daily**, every N days, for tournaments and camps.
    - **Weekly** on selected days, every N weeks, for practices.
    - **Ends** on a date or after a number of events, no more than 12 months out.
    - **Skip dates** for holidays and breaks: the form lists the dates it will create ("24 practices · Tue and Thu · Oct 13 – Dec 17"), and tapping one removes it.
    - Times stay the same in the event's time zone across daylight-saving changes.
    - Creating a series sends **one** notification for the whole series ("New: Practice, Tue and Thu at 6:00 PM, Oct 13 – Dec 17") and, with Post to chat checked, posts **one** event card to chat.
  - **Duplicate:** from an event's details, anyone who can create events can tap **Duplicate**. It opens this form filled in from that event.
    - Everything is copied except the date: type, title, times, time zone, location, notes, game fields, RSVP settings, reminders, and Notify team. Post to chat starts off, as on a new event, even when the original went in the chat.
    - The date is empty and gets focus, so it can't be saved as an accidental copy on the same day.
    - Nothing else carries over: no RSVPs, no Canceled state, and no link to the original's series. The copy is a new one-off event, unless Repeat is set on it.
    - Works on past and canceled events too, which covers "same game as last season".
- **SCHED-4 · MVP · Event details.**
  - Every field from creation.
  - **A past event** (#35, owner's go 2026-11-16): once it has ended, a quiet **Ended** pill sits where "In 3 days" would (Canceled wins over it), the list is titled **Who said they'd go**, and the reminder line is gone. The header is as designed. In the event's menu, **Cancel event** and **Delete** come last, under a line, in the warning red (§7.2); both still ask first.
  - **The layout** (Open Field, 2026-11-06): a back row with the chevron and the screen it came from ("Schedule" from the Schedule tab, "Chat" from a chat card, "Teams" from Your schedule on Teams and "Your schedule" from its page (SCHED-2), the player's first name from a player card or RSVP history; the chevron alone from a notification, a link or a reload), with Add to calendar, Share and More on the right as round buttons in an ink outline, and no title row. Then (Boot Camp Mix, #85) the kind on a mustard tag ("GAME · HOME") with "IN 5 DAYS!" on a mustard starburst on the right; for a game against an opponent, a round red crest in an ink outline with the opponent's initial beside the title, which is white stencil capitals in a thick ink outline on a hard shadow, turned a little ("VS. EAGLES", 51); it steps down (to 44, 38, 32, then 27) until each word fits a line whole, so a long name with large text or on a small phone wraps between words, never inside one, and "vs." or "@" stays with the first word (#74, owner's report 2026-11-20: "makes event header too big", "@ Springfield Isotopes" broken as "Springfie / ld"); "Who's going" keeps RSVP for a player beside it while both fit and puts it under the heading when they don't; when, in stencil in an ink-outlined box, turned a little ("SAT, OCT 31 · 10:00–11:30 AM"); and one ink panel of detail rows, split by ink lines, each with its icon on a mustard round badge (the other zone's time and arrival, the place with **Directions** as a blue push button, repeats, opponent, reminders, notes, and Assignments, where an open slot's "open" is underlined). Under the answers, the counts are four big stencil numbers in an ink outline, Going green, Maybe orange, Can't go salmon, No reply white (ink-free on Light: the text color), each labeled under it; then "10 of 12 players going", and for each answer an ink label in its color ("GOING · 10"), and its people, each on a row ruled off by a ball chain from which their dog tag hangs (in their color when going, plain while maybe, can't go or not answered), their name, and a round badge in the answer's color with its icon.
  - Large **Going / Maybe / Not going** buttons, three outlined across the width with the picked one in its candy color, and under them **Add a note** ("Leaving at halftime"). Tapping the chosen answer again clears it, as everywhere the buttons show (below). On a team, one set per player you answer for, under "Is Luke going?", "Are you going?" for your own player, or "Are your players going?"; in a group, your own (PLAYER-6). Someone with nobody to answer for gets the PLAYER-6 empty states instead.
  - The same buttons without opening the event (the owner's request, 2026-10-26; on the card since 2026-10-28): on the schedule list, and on Your schedule (SCHED-2), an upcoming event I can still answer has **Going**, **Maybe** (where the team allows it), and **Not going** across the bottom of its card, under the counts, a row per person I answer for, named ("Emma", or "You" for my own player and in a group), with a coral dot while it's unanswered. The buttons are pills: the chosen answer is filled in its color (mint, lemon, or the warning red with white text); with no answer all three are outlined; tapping the chosen one again clears it, back to No response, as on the event's page and the chat's event card. Closed or ongoing events show the answer but it can't be changed there; canceled and past events have no row. Notes are on the event's page. The rest of the card opens the event.
  - **Who's going:** four big counts (Going, Maybe, Not going, No reply; three with Maybe off), then "10 of 12 players going" on a team (none with no players) or "6 of 9 going" in a group, then the people grouped by answer ("GOING · 10"), a row each with their icon, name and number, their note in quotes, "Answered by Tasha R.", and the answer's mark. On a team, the lists show players only; in a group, everyone.
  - Actions for everyone: Add to calendar, Share, Directions.
  - Admin actions: Edit, Cancel event, Delete in the More menu, and, for team admins and super admins, **RSVP for a player** (on a team) or **Set RSVP for someone** (in a group) beside the Who's going heading.
  - **Duplicate**, for anyone who can create events (SCHED-3).
  - Events in a series show "Repeats weekly on Tue and Thu until Dec 17".
- **SCHED-5 · MVP · RSVPs.**
  - The answers are **Going**, **Maybe**, and **Can't go** (called Not going until Boot Camp Mix, #85, whose design names it so; the reminder emails and the answer page say it too). They're push buttons: the panel color in an ink outline on a hard shadow; picked, the answer's color (green, orange, or Can't go's salmon `#FF8A80`) with its icon, pressed onto its shadow; 50 tall on the event's page and 36 on the cards.
  - One tap, instant, and it works offline.
  - Change your answer any time before the deadline; after it, only admins can change answers.
  - **A locked answer is drawn flat** (owner's go 2026-11-17, #53): where it can't change (past the deadline for members, once the event has started on the schedule, on an archived team, or for a super admin viewing), the three buttons give way to one tag at the start of the row: the answer's icon and word on its candy (green, orange, or Can't go's salmon), with no lip, raise, or outline, or "No reply" in muted text, outlined. The row keeps its height, so nothing moves when the deadline passes. A locked row on a schedule card has no "yours to answer" dot. Screen readers hear "Going. RSVPs are closed." Admins keep the buttons until the event starts.
  - The requirement was Going / Not going. **Maybe** is a recommended addition: on by default, and each team can turn it off (TEAM-5).
  - Not answering shows as "No reply". One rule wherever the buttons show (the event's page, the chat's event card, the schedule list, and Your schedule): tapping the chosen answer again takes it back to No reply, and a snack bar says **Answer cleared** with **Undo**, which puts the answer and its note back (#44, owner's go 2026-11-19: "do #44"). There's no separate Clear link, and a double tap that clears an answer is never silent. Whoever may give the answer may clear it, under the same deadline; if the deadline passes before Undo, Undo says RSVPs are closed.
  - On a team, there's one RSVP per event and player, answered by the member who is the player, its guardians, or admins; in a group, one per member, their own (PLAYER-6).
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
- **SCHED-8 · MVP · Reminders.** A push at each reminder time to people who said Going or Maybe or haven't answered, but not Not going: "Reminder: Practice today at 6:00 PM · Riverside Park". On a team, reminders go to each player's member and guardians, and always to coaches and members not linked to a player; in a group, to members by their own answer (PLAYER-7).
  - **All-day events** start at midnight, so their reminders go out at **6 PM** in the event's time zone instead: 1 day before is 6 PM the evening before, and 2 days or a week before, 6 PM that day. The form offers them only 1 day, 2 days, and 1 week. A minute or hour reminder an all-day event carries anyway (from the 1.0 app, an import, or an older event) goes out at 6 PM the evening before too, once, and its page says "Reminders 1 day before, at 6 PM" (owner's request 2026-11-01).
  - **A reminder by hand:** the event's menu has **Post a reminder in chat** for team admins and the event's creator, after asking. It posts the event in the chat, marked Reminder, with its live RSVPs, the answer buttons, and how many players haven't answered, and the same people get the reminder push. Not on a canceled or finished event; once an hour per event.
- **SCHED-9 · MVP · Time zones.**
  - Times show in the viewer's time zone: the one they picked under **Profile → Time zone** (SET-7), or, on Automatic (the default), the device's.
  - If the event's time zone is different, both appear: "6:00 PM CDT · 7:00 PM your time".
  - All-day events never shift to another day.
  - Time zones are shown by the names people know them by (the owner's request, 2026-10-26): the US and Canada's first, as "Central Time (Chicago)" or "Mountain Time (Phoenix)", then the rest of the world by city and offset from GMT, "Berlin (GMT+1)", in Create team, Team settings, and the event form. Search finds a zone by its name, city, or ID. What's stored is still the IANA ID ("America/Chicago").
- **SCHED-10 · MVP · Add to calendar.** The native calendar sheet on iOS and Android; an .ics download on web.
- **SCHED-11 · v1.1 · Calendar subscription.** Built (task 138). A private link that keeps Google, Apple, or Outlook Calendar in sync with the schedule, so a time change or a rainout reaches the calendar a player or guardian already checks (ARCH §6.15).
  - **Where:** **Calendar link** in Team settings, under Just for you: a link for that team, or, under **All my teams**, one for every team you're on, including teams you join later. A link is made only when asked (**Make my calendar link**).
  - **Sync to my calendar** (#22, owner's go 2026-11-16): a quiet row at the top of Upcoming, a muted icon, words, and chevron, which scrolls away with the list. On a team's Schedule it opens that team's calendar link ("‹ Schedule"); on Your schedule's See all (SCHED-2), the link for every team ("‹ Your schedule"), with no team to choose. Not on Past or Calendar, and not for a super admin viewing a team they aren't on.
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
  - **Email people who haven't RSVP'd**, in the event's menu, for team admins and the event's creator, while the event takes RSVPs, hasn't started, and is before its deadline. It emails everyone linked to a player with no answer yet (the player, when they're on the team, and their guardians), one email per person naming their players, but not the person sending. It asks first, with the count ("Email 3 people who haven't RSVP'd?"), and says when there's no one to email. Each person gets at most one a week per event; sending again that week emails only people who haven't had one (2026-11-01, the owner's request).
  - **Daily limits:** 15 RSVP emails a day per team, within the bulk room left in the day's one email budget (#47, ADMIN-7), which keeps the rest for setup and account emails. An email that doesn't send doesn't count: that person can be emailed again. When today's limit leaves some out, the question and the result say so ("Try again tomorrow when the limits are reset to email 4 more."), and sending again on a later day emails only the people left out. With none left today: "Today's RSVP emails are used up. Try again tomorrow when the limits are reset."
  - **The email** names the team, the event, its time and place, and asks about each of the person's players on their own (PLAYER-11): "Is Emma going?" ("Are you going?" for their own player), each with their own **Going**, **Maybe** (when the team allows it, TEAM-5), and **Not going**, and says who sent it.
  - **Answering:** each answer opens a small page on getbattleplan.app that lists each player on their own, with their own answers and optional note: the answer tapped is picked for that player, and the others show what's saved. **Send** saves each player given an answer and leaves the rest as they were. Opening the link never answers by itself, because email services open links to check them; Send does. No sign-in: the link works only for that person, that event, and the players it names, until the event starts or its deadline passes, and it can change the answer until then. The page says who's answering, and offers to open the event in Battleplan.
  - Every answer follows SCHED-5 (the deadline, whether Maybe is allowed, who may answer for whom) and is recorded as that person's answer.
  - **Later** (tasks 287 to 290): Going, Maybe, and Not going buttons on event notifications (the iPhone and Android apps show all three; Chrome and Edge show Going and Not going), and reminder emails sent on their own to people who can't get notifications, with **Stop these emails** and a Settings switch.
- **SCHED-15 · 1.1 · Assignments.** An event can have assignments: tasks such as **Snacks**, **Drinks**, **Scorekeeper**, or **Other** (the admin names it, "Field setup"), each with optional details ("Halftime oranges") and at most one person. They're a secondary part of the event, so an **Assignments** row sits last among the event's detail rows, above the RSVPs: "3 of 4 taken", "2 open", or "You: Snacks" for your own. It shows for members once the event has assignments, and always for admins, to add the first. It opens the list (route `/g/{groupId}/schedule/e/{eventId}/assignments`).
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
  - **When it can't load** (#40): a document the app can't read is left out and reported once, so the rest show. A list that stops before showing anything says "Couldn't load this" with **Try again**; one that stops after keeps its documents under a slim "Couldn't refresh. Try again". A document's page that can't read its document says it couldn't load, with Try again.
- **DOC-2 · MVP · Upload files** (if you're allowed).
  - PDF, images, Word, Excel, PowerPoint, text, and CSV, up to 10 MB each (STORE-1).
  - Rename before uploading, add an optional description, and see progress with Cancel.
  - If the team's storage is full, uploading is disabled with the message from STORE-4.
- **DOC-3 · MVP · Add links.** A name and a URL, such as a Google Drive folder, a sign-up form, or a league website. Links open in the browser.
- **DOC-4 · MVP · Open.**
  - PDFs and images open in an in-app viewer. A photo shows on black, and its bar is black with the name, Back, Download, Share, and the menu in white, with no title drop, in every color scheme (#71, owner's report 2026-11-20: in Light blue the name was navy with a white outline on the black bar, and Back nearly invisible).
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
  - If they decline, Profile → Notifications explains how to turn notifications on.
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

  \* For players, these go to the member who is the player and to the guardians of the matching players, and to coaches and unlinked members; in a group, to members who answered for themselves (PLAYER-7).

  Plain chat messages and direct messages don't appear in the notification center; unread counts and Messages cover them (CHAT-9, CHAT-19).

  Admins can email the people who haven't RSVP'd, who answer from the email (SCHED-14). Answer buttons on pushes, and reminder emails sent on their own, come later.
- **NOTIF-3 · MVP · Notification settings for each team.**
  - Set them from Team settings ("Notifications for this team") or from Notification settings (Profile → Notifications), which every team's page links to at its foot as **Notification settings for all teams** (#28). They sync across your devices.
  - **Level:** All activity, Important only, or Off. It starts where the team's admins set Notifications for new members (TEAM-5), All activity unless they picked another, and the person can change it any time.
  - **Mute** for 1 hour, 8 hours, 1 week, or until unmuted. Muted teams show a muted icon, and their unread counts turn gray.
  - These settings control pushes only. Notification-center items and unread counts still appear, so nothing is lost.
- **NOTIF-4 · MVP · Global switches.** Notification settings (Profile → Notifications, or the gear on the bell's page) has switches for Messages, Direct messages (CHAT-19), Replies, Mentions (v1.1, CHAT-14), Polls, New events, Event changes, Reminders, and Documents. They apply to every team. Announcements have no switch (CHAT-15).
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
  - **Where you are decides what it covers** (owner's request 2026-11-10: "when the user is in the team or group, would it be a good idea to have the notifications bell only show notifications related to the group, but when the user backs out to the higher level view it shows all notifications?", then "go"):
    - **On Teams**, the bell counts and opens activity **across all your teams**, newest first, loading 30 at a time. Each item shows the team, an icon, a one-line summary, and the time, as plain rows between hairlines.
    - **In a team or group**, its header's bell counts and opens **only that team's** activity, in the team's color scheme. The team is the same on every row, so each row shows the summary (up to two lines) in the team name's place.
    - While another team has news, the **arrow back to Teams** has a small coral dot: unread items the bell on Teams counts that this team's bell doesn't, or another team's unread messages (CHAT-9; a muted team's don't count). It's the header's one dot (#13, owner's go 2026-11-16). Screen readers hear "Back to Teams", and "Back to Teams, news in your other teams" while the dot shows, and its tooltip says the same.
  - The rows are plain: every icon on a quiet disc and every time in muted text. An unread item has a small coral dot by its time and a bolder title (#12, 2026-11-16; until then a coral icon disc and a coral time).
  - Tapping an item opens the exact place, switching teams if needed, and marks it read. "Mark all as read" clears the rest of the list it's on: every team's on Teams, or only that team's.
  - A gear beside Mark all as read, "Notification settings", opens Notification settings (NOTIF-4), so what you're told about is one tap from what you were told (#28).
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
- **NOTIF-14 · MVP · Delivery that doesn't drop or repeat** (#41). A push that hits a passing error is sent again, a few times over about 20 seconds, only to the phones it missed, so nobody gets the same push twice. A notification that fails partway is finished within a minute or two: the notification-center items not written yet (one already read stays read) and pushes to the people not reached yet. One that can't go out within 10 minutes isn't pushed at all, since a late "Practice moved to 5:00" is worse than none; its center item, if written, still shows.

### 6.10 Profile and settings (SET)

- **SET-1 · MVP · Profile.** Photo (cropped to a circle) and display name, used on every team. The photo is on **Profile → Your icon** (SET-8), at 96 px with Add a photo, or Change photo and Remove photo. Removing or changing a photo deletes the old one, so earlier messages that showed it show initials instead; the name changes in **Name**'s dialog on Profile (§5.1). The email shows on Sign out ("Signed in as …"); it changes in Sign-in methods.
- **SET-2 · MVP · Color schemes.** The app has one look, **Boot Camp Mix**, in seven color schemes: **Army green**, **Black** (the default; owner's request 2026-11-10: "make the dark theme the default theme", stored as `dark`), **Light**, **Sky Blue**, **Candy Pop**, **Central Wildcats**, and **Geaux Tigahs** (§7.4; #85, owner's pick 2026-11-22: "let's replace the existing themes with these 3 themes", then #86 the same day: "add 4 new themes to the UI"). The last four keep the stored values they had in Open Field (`sky`, `candypop`, `wildcat`, `purplegold`), so whoever had picked one gets it back as it is now. The other Open Field schemes and the themes saved in the Super Admin Panel's Themes (ADMIN-10) left the pickers. A pick of one of them is read as the closest of the seven and never rewritten: Forest green as Army green; Navy and Scoreboard as Black; Sky Blue Pop as Sky Blue; and a saved theme as Light when its page is light, else Black (Black when it's gone). So someone who picked Navy sees Black, and an app from before #85 still shows them Navy. A team's admins (and super admins) set the **team's default color scheme** in **Admin settings → Look → Team color scheme** (Group color scheme in a group), its own page, whose row says the default ("Army green") or "System default" (#32, #73), next to the chat look (owner's request 2026-11-08: "make sure the team admin sets the default theme for the team and that users can override but only if they explicitly choose a different theme."). Its page lists **System default** first ("Everyone sees their own default": no team default, so each member sees their own Default color scheme; checked until one is set, and tapping it takes the team's default away), then the seven (#73, owner's request 2026-11-20: "allow a team admin to be able to set the theme to system default which means if you reset it, each user just gets their theme for that team reset to their default theme they have in the overall app."). Under them, **Reset for everyone** (owner's request the same day: "a team admin can reset it for everyone if they want. add a button for that with a confirmation to the team admin settings") asks "Reset everyone's color scheme?" ("Everyone will see Thunder in Army green. They can still pick their own afterward.", or with System default "in their own default color scheme"), then takes back every member's own pick for the team, the admin's too, and says how many ("Reset for 2 people."; "Nobody had picked their own."); everyone then sees the team's default, or with System default their own default, and can pick their own again. It's audited, and a super admin can do it on any team. A new team has none set, so nothing changes for anyone until an admin picks one; a new season keeps it (TEAM-16). What each member sees on a team is, in order: their own **explicit pick** for it, else the team's default, else their personal **Default color scheme**, else Black. **Team settings → Color scheme** lists the team's default first, as "Team default (Army green)" ("Group default" in a group), checked while they have no pick of their own, then the seven with a short line under each; tapping one of the seven is an explicit pick, which only changes how that team looks for them, and tapping the default row takes the pick back, so later changes an admin makes reach them again, live. With no team default set, the first row reads "Your default (Black)" and follows their Default color scheme. Only that tap saves a pick: nothing writes one on joining, on opening the screen, or by migration, and picks saved before 2026-11-08 stay as they are. The **Default color scheme** on Teams (and Profile's **Color scheme** row, which names it, #28) themes Teams, Profile, Messages, and settings, and every team or group without a pick or a team default, including ones they join later. A super admin looking at a team they aren't on has no Color scheme row there and sees it in their default. Accounts from before 1.1 start from their old theme: Gumdrop Army becomes Army green, Gumdrop Pop Dark becomes Navy (so Black), Gumdrop Pop Light and Gumdrop Candy become Light, and Gumdrop Arena becomes Black. Accounts that never picked one (System, or nothing set) and new accounts start on the default, Black (Army green until 2026-11-10; called Dark until #85). Nothing is stored for them, so anyone who picked a scheme, Army green included, keeps it; app builds from before the change still show Army green for them until they update. A change applies instantly, is remembered on the device so the app opens in it, and syncs to the account. Signed-out screens (sign-in and setup) and the splash screens are Black.
- **SET-3 · MVP · Notifications.** **Notification settings**, from Profile → **Notifications** (in Settings until 2026-11-17, #28), the bell's gear (NOTIF-11), or the foot of a team's notifications page: global switches (NOTIF-4) and each team's level (NOTIF-3). Later, **Email reminders when I can't get notifications** (SCHED-14). Calendar links are in each team's menu (SCHED-11).
- **SET-4 · MVP · Sign-in methods** (AUTH-8).
- **SET-5 · MVP · Blocked people.** View the list and unblock.
- **SET-6 · MVP · About and account.**
  - App version, Terms, Privacy Policy, open-source licenses.
  - Contact support.
  - Sign out of all devices; Delete account (AUTH-10). Sign out itself is on Profile (§5.1), and not here too since 2026-11-17 (#28).
- **SET-7 · v1.1 · Time zone.** (The owner's request, 2026-11-01: "i want the user to be able to select their timezone and it always adhere to that instead of adjusting automatically as they travel".) On Profile: **Automatic: Central Time (Chicago)**, following the device as it does today, or a zone picked from the same list as Create team's, which stays put wherever the person is. It's saved to the account, so it follows them to every device. Every time the app shows uses it: the schedule and events (with the event's own time beside it when that differs, SCHED-9), message times and the chat's day lines, poll close times, mute and notification times, document, media, play, report, and invite dates, a player's events, import previews, and the admin panel. Times picked in the app (a poll's close time, an announcement's end, the audit log's days) are in it too. A new team starts in it. New events still start in their team's zone, and push notifications still give the event's time in its own zone.
- **SET-8 · v1.1 · Your icon.** (The owner's request, 2026-11-06: "Let each user pick a color they want their icon to be if they don't choose an image. Show the icon in the bubble next to their messages in chat.") Everyone's icon is their photo, or their initials on one of seven candy colors they pick: **Blue raspberry**, **Lemon**, **Mint**, **Grape**, **Bubblegum**, **Tangerine**, or **Cherry**. **Profile → Your icon** says "A photo, or your initials on a color you pick. People see it next to your messages in chat.", then the photo controls (SET-1), the seven swatches ("Or pick a color", or "Color when there's no photo" with a photo), and an **In chat** preview of a message as others see it. Each tap saves. Until someone picks, their icon keeps the color it always had, shown as picked. Profile's Your icon row says **Photo** or the color's name. The icon shows beside their messages (CHAT-1), on the roster, person pages, reactions, poll voters, and Messages; each message keeps the color it was sent with, so changing it doesn't recolor older messages. The admin console, @mention suggestions, and Blocked people keep the default color. In Light blue, every icon has a thin ring.

### 6.11 God admin panel (ADMIN)

This is for platform operators (super admins) to manage every team and user.

**Access and layout**

- **It's called the Super Admin Panel** (owner's request 2026-11-18, #67: it was the "Admin panel", easy to mix up with a team's own admins and Team settings): on Profile's row, the header's button and the rail's link (which wraps, "Super Admin / Panel"), its menu's heading, Leave the Super Admin Panel, Back to the Super Admin Panel, what screen readers hear, and the alert emails' Open in the Super Admin Panel.
- Only super admins see it, at `/admin`, one tap from where they usually are (owner's request 2026-11-07: "make admin panel easier to get to with fewer steps to get there"; §5.1): the **Super Admin Panel** button in the Teams header and a team's header on phones, **Super Admin Panel** at the foot of the rail on wide screens, and the Super Admin Panel row on Profile. Viewing a team they aren't on (ADMIN-3), the phone header has no button, since the banner has **Back to the Super Admin Panel**. It opens over the page they were on, so Back returns there. **Back is at the top left of every page of the panel**, as everywhere in the app (owner's request 2026-11-18, #68: on phones the menu sat there, and the way out was an icon at the top right): to the page before (a team's or a person's page goes to its list, a section to the Dashboard), or, with none, out of the panel to the team and tab they were last on, or Teams, heard as "Leave the Super Admin Panel". On phones the menu is at the top right, on every page, and its sections slide in from that side.
- It's designed for a desktop browser but works on phones, where tables become lists.
- **Its sections** (Dashboard, Teams, Users, Reports, Audit log, Platform settings) are a rail on wide screens and a menu (☰) on phones. Every section has the menu, also when the panel opened over another page, so any section is two taps from any other; a team's or a person's page in the panel, and a person's or a team's audit entries opened from it, have Back instead. On the dashboard, the Users, Teams, and Open reports totals open their lists.
- It's loaded separately, so regular users never download it. The buttons that lead to it are part of the app, not the panel.

**Requirements**

- **ADMIN-1 · MVP · Dashboard.** Totals for:
  - users and teams (direct conversations, CHAT-19, aren't teams and don't count);
  - new teams this week;
  - active teams (a message in the last 7 days);
  - messages in the last 7 days;
  - total storage;
  - open reports;
  - **Emails today** (#47): "38 of 90" of the day's budget, saying "Invites and RSVP emails stop at 63. Setup emails can use the rest." Its badge is mint, the warning yellow once invites and RSVP emails have stopped, and red with the number when the day is full.
  - **The Boot Camp Mix look** (#85): the panel's name on a mustard tag over DASHBOARD in outlined stencil on the camouflage, with refresh and the menu as round buttons; each total a square ink panel on a hard shadow, with a 44 px rounded badge in its color (Users blue, Teams purple, New teams green, Active teams orange, Messages red, Storage mustard), the label in stencil over the muted line, and the number in big outlined stencil (solid ink on Light; open reports in salmon in an ink outline), with a chevron where it opens a list.
  - **Each total is a card across the page** (owner's report 2026-11-18, #66: the cards filled only half a phone's width; then "the teams listing may be a better example of the look"), in the look of the team cards on Teams: its icon on a 48 px badge of its color, the label (Users, Teams, New teams, Active teams, Messages, Storage, Open reports) over a muted line saying what it counts ("Made in the last 7 days"), and the number at the card's end, or under the line with large text. One column on a phone, two from 600 px, three from 900, so all seven fit on one phone screen. Users, Teams, and Open reports open their lists, with the card's chevron; waiting reports turn that badge and number the warning red, and its line says "Waiting for a decision" (else "None waiting"). Screen readers hear each as "New teams: 4. Made in the last 7 days."
- **ADMIN-2 · MVP · Teams.**
  - Search by name.
  - Sort by any column either way (owner's request 2026-11-14: "similarly, in the admin panel make the teams and audit logs both sortable by each column"), as the users list does (ADMIN-4): tap a heading on a computer, or **Sort by** and the direction button on a phone. Newest first by default. Names, sports, owners, and status start A to Z (Active, Archived, Suspended), members, storage, and the dates largest or newest first; teams with no owner or no messages yet come last.
  - Filter by Active, Archived, or Suspended.
  - Columns: name, sport, owner, members, last activity, storage, status, created.
- **ADMIN-3 · MVP · Team detail.**
  - **Edit:** the team's profile and settings.
  - **People:** change roles, remove members, add by email, transfer ownership, manage players and guardians.
  - **Content:** revoke invite links; review recent messages (delete any), events, and documents.
  - **Storage:** see usage, open the team's Media, and raise or lower its limit (STORE-6).
  - **Actions:**
    - **View team**: opens its tabs without joining, with a "Viewing as super admin" banner, and recorded in the audit log. Team settings, the Team tab, schedule, documents, and Admin settings work as §3 gives super admins; posting, voting, and RSVPing for themselves need them to join.
    - Archive or Restore.
    - Suspend or Unsuspend (members see "This team has been suspended").
    - Delete (type the name to confirm).
- **ADMIN-4 · MVP · Users.**
  - **Find:** search by name or email; filter by Added (not joined yet), Active, Disabled, or Super admin.
  - **Sort:** by any column, Name, Email, Status, Joined, or Last active, either way (owner's request 2026-11-14: "In the admin panel, allow me to sort users by any of the fields."). On a computer, tap a column's heading, and tap it again to flip it; on a phone, **Sort by** and the Ascending/Descending button. A column starts A to Z (Status as Active, Added, Disabled), or newest first for the dates; people without a value come last. It covers everyone the filter matches, not just the loaded page, and a search's matches sort the same way. Newest joined first by default.
  - **Details:** profile, status, sign-in methods, teams and roles, joined date, last active.
  - **Google Play's test accounts** (owner's go 2026-11-18, "Do #33 and #52"): after every Android upload, Google Play's automatic checks sign up with throwaway accounts. An email at Google's test lab (`@cloudtestlabaccounts.com`), or a Gmail address shaped like `name.12345@gmail.com`, gets a flat, muted **Play test** tag beside the name, in the table and the phone rows, heard as "likely Google Play test account", and its own page says "Likely a Google Play test account. It isn't blocked." It's a guess for a label only: nothing about the account is blocked, hidden, or treated differently (the owner's rule). The app and Functions share the one rule (`likelyPlayTestAccount`).
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
  - Sort by any column, When, Who, Action, Team, or Target, either way (owner's request 2026-11-14: "similarly, in the admin panel make the teams and audit logs both sortable by each column"), the same way as the users and teams. Newest first by default; Who sorts by the person's name, or their ID once they're gone; entries for no team come last.
  - Read-only, kept for 1 year.
- **ADMIN-7 · MVP · Platform settings.**
  - Whether anyone can create teams, and the teams-per-person-per-day limit.
  - Storage per team, for every team without its own limit (STORE-1, STORE-6), and maximum upload size.
  - Support email.
  - Whether super admins get alert emails about new accounts and teams (ADMIN-9).
  - **Emails a day** (#47): the email plan's daily limit for this project, "Dev and prod share Resend's 100": 90 in prod and 10 in dev until set, 1 to 10,000. Every email the server sends counts toward it, one total per UTC day. Essential emails (setup and account setup links, password resets, security notices, super admins' alerts) may use all of it; bulk ones (email invites, "added to team" notes, RSVP emails) stop at 70%, so the rest is always there for the emails that let people in. An email past its room doesn't go out, and a refused one still counts, as the provider counts.
  - A banner announcement for all users, with text, severity, and an end date. Screen readers read it, and its Dismiss, before the page, and announce it when it appears (§7.6).
- **ADMIN-8 · MVP · Safeguards.**
  - Destructive actions require confirmation.
  - Every admin action writes an audit entry.
  - Nobody can set or see another person's password. Admins can only send setup and password-reset emails (AUTH-6).
  - The Privacy Policy states that super admins can access team content for moderation and support (LEGAL-1).
- **ADMIN-9 · MVP · Alert emails.** Every super admin gets an email, at the owner's request:
  - **New account:** when someone finishes first-run setup (AUTH-5), once: their name, email, how they sign in, and whether a team admin added them first (AUTH-6), linking to them in the Super Admin Panel. Someone who signs in but never finishes setup isn't counted. A likely Google Play test account (ADMIN-4) is said in the subject, "New account (likely Google Play test): Pat Lee", and a first line: "This looks like one of Google Play's test accounts, from its automatic checks after an Android upload. Nothing needs doing." (#52)
  - **Sign-up spike** (#52): when 10 or more people finish first-run setup within any 60 minutes, one email, "Sign-up spike: 10 new accounts in the last hour", naming the newest 20 ("and 7 more" past that), with "If these look like bots, you can disable them on the Users page. Google Play test accounts aren't counted." and **Open Users**. Then none for 6 hours, however many more arrive. Accounts an admin added (TEAM-7) and likely Google Play test accounts don't count. It always sends, like report alerts, since it's a safety alert and rare. The count is a server-only document (`ops/signupBursts`) holding the last hour's sign-ups (who and when) and when the last spike email went. App Check (SAFE-5) is what stops bots; this only says when something looks unusual.
  - **New team:** who created it and its sport, linking to it in the Super Admin Panel.
  - **Team deleted:** who deleted it (the owner, or a super admin) and how many members it had, linking to its audit entries.
  - Platform settings (ADMIN-7) has **Email super admins about new accounts and teams**, on by default. Report alerts (SAFE-4) and the sign-up spike always email.
  - An email that fails never stops what it's about; it's logged.

- **ADMIN-10 · MVP · Themes** (#82, owner's request 2026-11-20: "make the app's default buttons and whatever is always coral colored, customizable for the theme. To do that I want you to create a theme editor in the super admin menu that makes those adjustable so that each theme doesnt have to have coral text boxes. Allow the background and the background of the bubbles to be changed in the theme editor and allow new themes to be saved.").
  - **Hidden since Boot Camp Mix** (#85, owner's pick 2026-11-22: "let's replace the existing themes with these 3 themes"). The Super Admin Panel no longer lists **Themes**, and no theme's colors are drawn: the Boot Camp Mix schemes are drawn as they ship. What was saved (`config/app.themes`) is left as it is and the server's `adminSaveTheme` and `adminDeleteTheme` still check and audit, so the editor can come back; a pick of a saved theme reads as Light or Black (SET-2). Until then:
  - **Themes** in the Super Admin Panel lists the saved themes, with **New theme**, then the eleven built-in ones, each "As it ships" or "Colors changed" ("Turned off: some of its colors are nearly the same. Open it to fix it." for one that fails the check below). Each opens the editor.
  - Any theme can set five colors, each left empty for the original (#82; the two text colors since #83, owner's request 2026-11-21: "all the text color to be changed"): **Buttons and your messages** (coral in every built-in scheme: the main buttons, + and send, your messages, the picked tab, and unread counts; coral checks, underlines and the tab marker take it too, made to read on the page, while a scheme's own gold or silver marks stay; the writing on it is the scheme's ink, or white where the ink doesn't read, as on maroon), **Background** (the page), **Text** (on the background, and in the tab bar and text boxes), **Cards and bubbles** (cards, sheets, pop-ups, and the polls and events in the chat), and **Text on cards and bubbles** (empty follows the text where the scheme's card text is its text, all but Candy Pop). Muted text, outlines, and the colored words (Going, Maybe, warnings, event types) follow the new colors and are made to read. A team that picks its own bubble color in Chat look (CHAT-18) keeps it for its messages; the theme's color is the bubbles' where the team hasn't picked one (Chat look's first color, "Cherry", or "Theme color" under a theme with its own).
  - Each color shows its name and code: "Coral #F45B5B", or for a code typed in, the nearest name ("Close to Maroon"). **Choose a color** lists, by name and code, the candy colors, the team colors, and each built-in theme's own (its background, cards, text, and marks: maroon and silver, purple and gold, navy, amber, and the rest) (#83, owner's request: "add more colors to each option ... have it say the name of the color in addition to showing the color code"). An empty box says what it keeps: "Empty uses the original, Dark maroon (#5E1224)."
  - A **saved theme** also has a **Name** (up to 30 characters) and **Start from**, the built-in scheme it takes everything else from: its fields and tab bar. There's room for 12; with all taken, "All 12 saved theme spaces are taken. Delete one to save another."
  - **No same-color pairs** (#83, owner's requests 2026-11-21: "put a protection in there that prevents text and background from being the same color and effectively making it almost impossible to change the theme back to a readable theme without intervention via code", then, when it refused a yellow background, "The color check is too sensitive ... I only want to block colors that are nearly identical"). A **Preview** shows the colors as they're typed. Only a color that looks nearly the same as what it sits on is refused (closer than 15 in CIE Lab, ΔE): the text and the background, the tab bar and text boxes (which keep the starting scheme's colors), the cards, and pop-ups; the writing on the button color; and the button color and the background, cards, and tab bar. Anything else goes, however it reads: a yellow background, dark text where the tab bar stays dark. Muted text, colored words, and marks still follow the new colors and are made to read where they can. A color that's nearly the same says so under the field that can fix it ("This is nearly the same color as the text. Pick one that stands apart from it."), and Save says "Fix the colors marked above, then save." The server checks the same pairs and refuses such a theme ("Some of those colors are nearly the same as what they sit on, so the theme wasn't saved."). A theme that has one anyway (saved by hand, or before the checks) is never drawn: everyone sees the scheme as it ships, and the Themes page lists it turned off. The Super Admin Panel itself is always drawn in the built-in scheme as it ships (a saved theme's starting one), so its Themes page and **Put back as it ships** always read.
  - **Save** changes the theme for everyone at once, live. **Delete theme** (a saved theme) asks "Delete Night Game?" ("Anyone using it, and any team that has it as its default, goes back to their team's or their own default.") and clears every pick of it. **Put back as it ships** (a built-in theme with changed colors) asks first, then the scheme is as the app ships it. Each is audited (ADMIN-8).

### 6.12 Safety and moderation (SAFE)

The App Store requires these for apps with user-generated content (guideline 1.2), and they matter more once anyone can create a team.

- **SAFE-1 · MVP · Report.**
  - Report a message, document, or person.
  - Reasons: Spam, Harassment or bullying, Inappropriate content, or Other, plus optional details.
  - The report goes to the team's admins (Team settings → Reports) and to the super-admin queue; a report about one of the team's admins goes to the super-admin queue only (SAFE-4). The form says so before it's sent.
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
  - While any report has been open more than 12 hours, super admins get one reminder email a day saying how many are waiting and how old the oldest is. It's the night's first job, so nothing that runs long before it can stop it (#41).
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
  - On for every team; admins can turn it off in Admin settings (TEAM-5). It applies to what's posted, or edited, while it's on.
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
- **STORE-2 · MVP · Storage used.** Admin settings shows "112 MB of 200 MB used" with a meter, for the team's admins.
- **STORE-3 · MVP · Nearly full.** At **90%**, the meter turns amber, the team's admins see a warning at the top of the team ("Storage is 90% full. Free up space in Media."), and they get a notification (NOTIF-2).
- **STORE-4 · MVP · Full.**
  - New uploads (chat photos, documents, the team logo, a chat background), attachments, and **scheduling new events** are disabled until storage is freed up.
  - Everyone on the team sees: "Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up." Admins also get a notification.
  - Nothing else turns off: text messages, replies, reactions, polls, RSVPs, and existing events keep working. Nothing is ever deleted automatically.
- **STORE-5 · MVP · Media (admins).**
  - Team settings → **Media** lists every photo, attachment, document, the team logo, and the chat background, largest first, with a preview, size, who added it, and when.
  - Admins delete items to free space, after confirming. Deleting a chat photo removes it from its message, and a message left with no text or photos reads "Photo removed by a team admin"; deleting the logo or background resets it.
- **STORE-6 · MVP · A team's own limit.** A super admin can give one team its own limit, higher or lower than the default, from the admin panel (ADMIN-3) or from Admin settings while signed in as a super admin, and put it back on the default with **Use the default**. A team with its own limit keeps it when the default changes. The option isn't announced or advertised anywhere.
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
- **IMPORT-7 · GameChanger events (built).** GameChanger has no export file or public API. Its supported path is the team's calendar link, an iCalendar feed: in the GameChanger app, open the team, tap the gear, then **Schedule Sync**, **Sync Schedule to Your Calendar**, and **Copy Calendar Link**. Coaches, players, and parents get every event from it; followers get only games. Team admins open **Import** in Team settings, paste the link or choose a downloaded `.ics` file (up to 1 MB), and preview before anything is added. Only **Events** can be chosen: GameChanger exports no chat and has no team documents, and RSVPs and attendance aren't imported.
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
- **BOARD-2 · The whiteboard.** **Plays** in the main navigation opens it for the team's admins and play makers (TEAM-3, #63): the team's sport's board, ready to draw. Drag players, opponents, and the ball with a finger, a pencil, or a mouse to show how a play unfolds; add more; label one with a number, a position, or a roster player; draw run (solid), pass (dashed), and block or screen (T) arrows, freehand lines, and text; erase; undo and redo (and ⌘/Ctrl+Z, Delete, and Escape on a keyboard). The tools sit beside the board on a tablet or laptop and below it on a phone, each big enough for a finger. On a phone the board runs the screen's width, under one bar: the step's controls (or, with something picked, what to do with it), undo, redo, and More, which holds **Save to plays**, **New board**, **Saved plays**, and whatever else has no room. Players, arrows, and text stay the same size however big the board is drawn. A drag moves a player; a tap picks one. The drawing stays on that device until it's cleared, so leaving never loses it; **New board** starts over (asking first) on any board.
  - **The Boot Camp Mix look** (#85): the header's tag says PLAYBOOK; on a phone the bar over the board has **Saved** and **Add step** as push buttons and undo, redo and More as round buttons in an ink outline (redo greyed with nothing to redo); the board runs edge to edge; the tools sit on their own row's color under an ink rule, each a round button in an ink outline, the one in hand mustard and turned a little. The field drawing is unchanged.
- **BOARD-3 · Steps.** A play can have up to 10 steps. A new step starts where everyone stands; **Play** moves the players and the ball smoothly from each step to the next.
- **BOARD-4 · Saved plays.** **Save to plays** keeps a copy, named, for the team: everyone on the team opens Plays to see them (for them it shows the saved plays, starting right under the team's header with the list, or "No plays yet. Your coaches' plays will show up here.", with no back row or second Plays title of its own; #31, owner's go 2026-11-16), step by step. The whiteboard's bar has **Saved** (on a phone) or **Saved plays** to open them. Admins edit, duplicate, delete, or put a saved play back on the whiteboard. Positions are only labels on the drawing; nothing is saved on a player (players have no position field, ROADMAP task 234).
- **BOARD-5 · Sharing a play.** Under a saved play's steps, for everyone on the team (owner's request 2026-10-27, ROADMAP task 315):
  - **Post to chat** posts a picture of the play's last step to the team's chat, with the play's name, and goes to the chat. The picture carries an **Open play** sticker: a tap opens that play in Plays, where anyone can play its steps and stop them. A deleted play opens to "This play was deleted." The switcher's preview reads "Play: Relay", and the push "Alex posted a play: Relay". Photos (DOC-7) leaves posted plays out. Versions of the app before 1.1 show the picture and name as a photo. Archived teams don't post.
  - **Save as GIF** makes an animated GIF of the play: the first step for 1.5 seconds, each later step gliding into place over 1.5 seconds (20 frames a second), and the last step held for 3 seconds before it starts over, forever. 720 pixels on its longer side. On a phone it's saved to the photo library (asking for add-only access the first time); in a browser it's shared where the browser can, or downloaded. It's named for the play.
  - **Share** makes the same GIF and opens the share sheet with it, to send in a text, an email, or another app (owner's request 2026-10-28, ROADMAP task 318). A browser without a share sheet downloads it. A public link to a play, and importing someone's play, are on hold.

**Acceptance**

- Each board looks like its field or court, with its starting positions and the ball, on a tablet, a laptop, and a phone. On a phone the board, and a saved play for the team, run the screen's width.
- A coach drags players and the ball to show a play unfolding, draws arrows, adds steps, plays them back, and saves only when they want to keep one.
- Members view saved plays but can't change them, unless an admin made them a play maker; people not on the team can't read them; archived teams' plays are read-only.
- Anyone on the team posts a saved play to the chat, where its picture opens the play, and saves it as a GIF that plays its steps, holds the last for 3 seconds, and repeats, or shares that GIF through the share sheet.

---

### 6.17 Dues (DUES) · Built

The owner's request (2026-11-06): team admins assign dues and fees, such as uniforms or the team fee, to players on a team or to people in a group, and track who paid and who still owes. Admins can share how to pay with Venmo, Cash App, or Apple Cash, but Battleplan never takes or sends money: paying is person to person, outside the app. Nobody but the admins sees what anyone else owes or paid.

The owner's request (2026-11-07): "In the dues section, allow for and account for partial payments for items. In the admin page make sure there's a good breakdown of who owes what." Admins record what each person paid, a part at a time or all of it (DUES-2), and see who owes what by due and by person (DUES-5). It's still a record of payments made outside the app: Battleplan never takes or moves money.

**Dues** is a button on the Team tab's card (the People tab's in a group), beside Invite, for everyone: admins see every due, and everyone else sees only what they owe (route `/g/{groupId}/dues`).

- **DUES-1 · v1.1 · Adding a due.** Team admins (and super admins, §3) tap **New due** (`/g/{groupId}/dues/new`): **What it's for** (up to 60 characters, "Uniform fee"), the **Amount** in US dollars, from 1 cent up to $10,000, an optional **Due date**, an optional **Note** (up to 280) that everyone who owes it sees, and **Who owes it**: on a team, every active player, and in a group, every member, each checked to start and any unchecked (up to 100 people a due). Saving again after a lost connection never adds the due twice. Admins see each due on the Dues screen with how it's going: "4 of 12 paid · 1 partly paid · $90 left", with a bar for how much of the money is in, or "All waived". **Edit due** (`/g/{groupId}/dues/{dueId}/edit`) changes what it's for, the amount, the date, and the note, and everyone's share changes with it, keeping every payment recorded on it: a share whose payments cover the new amount is Paid, and one they don't owes the rest. When the amount changes and someone has paid anything, it asks first ("1 person has paid some or all of it. What they paid stays recorded, and anyone who paid less than $50 will owe the rest."). An amount below what someone already paid is refused ("Emma #7 has already paid $30. Undo a payment on their share first, or keep the amount at least that.", or for a share marked paid before payments were recorded, "Emma #7 is marked paid at $45. Mark their share not paid first, or keep the amount at least that."), in the app and again on the server, which checks every share in the same transaction as the edit, so a payment recorded at that moment can't slip past it; the app doesn't cap or rewrite a payment, since it records money that really changed hands. A share marked paid before payments were recorded (2026-11-07) counts as paid in full at its amount: when the amount changes, it becomes one payment of that amount, on the day it was marked paid. On a due's screen, admins **Add people** it left out, such as a player who joins mid-season; their share starts owed. Waive takes someone off. **Delete due** asks first ("Everyone's record of it goes too.") and removes the due and every share of it.
- **DUES-2 · v1.1 · Who paid, in full or a part at a time.** Each person on a due has their own share: a player on a team, or a member in a group. Admins open a due (`/g/{groupId}/dues/{dueId}`) to see what's owed in all, paid, and left on it, then everyone on it, who owes most first (by what's left, then by name), then who paid, then who's waived. Above the shares, admins read "Tap someone to record a payment, mark them paid, or waive the rest.", and each share they can change has a chevron beside where it stands, so it's plain the row opens (2026-11-07: the owner couldn't find how to record a partial payment). Each share says where it stands: **Owes** ("$45"), **Partly paid** ("$20 of $45 paid · $25 left"), **Paid** ("$45 paid"), or **Waived** ("$20 of $45 paid · rest waived" when some was paid first). Tapping one opens it: **Record a payment** (any amount from 1 cent up to what's left, the day it was paid, today unless changed, and a short note of up to 60 characters, like "Venmo" or "Cash at practice", which whoever owes it can see too), **Mark paid in full** (records what's left, today, in one tap), and **Waive** (or **Waive the rest** once some is paid: what was paid stays, and nothing more is owed); a waived share has **Undo waive**, back to Paid if its payments cover it, or owing the rest. Its **Payments**, newest first, show the amount, the day, who recorded it ("Recorded by Coach Lee", or "a former member"), and the note, each with **Undo** for a mistake, which asks first ("$20 comes off what Emma #7 has paid.") and owes that much again. A share can hold up to 50 payments; one more, Mark paid in full included, says so ("Undo one and record it again with this one added, or waive the rest."). Screen readers hear each change ("Emma #7: $25 left of $45"), and each share as one sentence ("Emma #7, $25 left of $45, Due Nov 30"). A share marked paid before payments were recorded (2026-11-07) reads Paid, as paid in full, with **Mark not paid** instead of Undo; one owed counts nothing paid, and waived stays waived. Two admins recording at once both count: each payment is added to the share as it is when saved, never to an older copy, and nothing is ever more than what's owed. On an archived team, admins can still open a share to see its payments, and change nothing. Everyone else sees only their own, under **What you owe** with the total still owed ("$70 owed", "All paid. Thanks!", or "Nothing owed."), each share with what's been paid and what's left ("$20 of $45 paid · $25 left") and its pill, and the due's note; a share with payments opens to show each one, its amount, the day, who recorded it, and its note, with nothing to change: in a group, the member's own share; on a team, the shares of the players they answer for, as a parent or guardian or as the player themselves ("For Emma" when the shares are for more than one person), and on a team that was a group (TEAM-14) their own shares from before. On a team, someone not linked to a player yet is pointed to **Who are you here for?** (PLAYER-3), or told their claim is waiting. A share still owed after its date reads "Overdue since Nov 13". Shares keep the player's or member's current name. Nobody else sees them, not even that they exist.
- **DUES-3 · v1.1 · How to pay.** Admins, and on a team its coaches (TEAM-3; owner's request: "the team admin or coach"), **Edit how to pay** on the Dues screen: a Venmo username, a Cash App $cashtag (a pasted profile link saves as the handle it names), an Apple Cash phone number or email, and a note ("Put your player's name in the note"), any of them left empty. Dues and who paid stay the admins'. Everyone on the team sees them, with who saved them last ("Updated by Coach Lee", or "a former member") and "Pay the team directly. Battleplan doesn't handle payments." Each has **Copy**; on the web and in the Android app, Venmo and Cash App also have **Open**, which opens the person's Venmo or Cash App page. The iPhone app only copies, as a precaution; Apple's rules would allow Open too. Paying never happens in Battleplan, and nothing is marked paid on its own: an admin records each payment once the money arrives.
- **DUES-4 · v1.1 · Privacy.** Enforced by the server's rules, not only the app: a due itself is seen only by the team's admins and super admins; a share by them, the member it's for, or the people linked to its player (a parent or guardian, or the player themselves); how to pay by everyone on the team. Only the team's admins (and super admins) add, change, and delete them, except that a team's coaches also change how to pay: a due and everyone's share of it are added, changed, and deleted together on the server, which checks who's asking and who's charged, while admins record payments and waive shares in the app, where the rules accept only one payment added (in their own name, from 1 cent up to what's left, at most 50 a share) or one taken back, with the share's total and status to match. Members, guardians, and coaches record none, their own included. Archived teams are read-only. Dues go with the team when it's deleted (TEAM-9). Direct conversations have no dues.
- **DUES-5 · v1.1 · Who owes what.** For admins only (owner's request, 2026-11-07, above). The Dues screen opens with what's owed in all, paid, and left across every due, with a bar for what's paid, read by screen readers as one sentence ("$270 owed in all, $150 paid, $120 left"), and **Who owes what** under it (`/g/{groupId}/dues/people`), one tap away. Who owes what has the same totals, then each person (a player on a team, a member in a group), who owes most first, then by name: their name and what's left ("$65 left", or "Nothing left"), what they've paid of what they owe in all ("$10 of $75 paid"), and a row for each due they're on, with what it's for, where it stands, its date while something's left, and its pill. Each person reads as one heading ("Ava #12, $65 left of $75"), and each row as one sentence ("Ava #12, Tournament fee, $20 left of $30"). Tapping a row opens that due, to record a payment, with **Who owes what** to go back. A due's own screen has its totals the same way (DUES-2). Members who open the address are told "Only admins see what everyone owes." and read nothing; What you owe shows them only their own (DUES-2). It fits every color scheme, phones and wide screens (up to 560 points wide, centered), and text at 200%.

Store payment rules: dues are paid person to person, outside the app, for real-world things like uniforms and team fees, so neither store's in-app billing applies and neither takes a cut. The guidelines, with links and the date they were read, are in [STORE-CHECKLIST.md, Store payment rules](STORE-CHECKLIST.md#store-payment-rules).

**Acceptance**

- An admin adds a $45 uniform fee for the whole roster in under a minute, and marks people paid as the money comes in, seeing "4 of 12 paid · $90 owed".
- A parent sees what their own players owe, the total, and how to pay, and never what anyone else owes or paid; a member of a group sees only their own.
- Venmo and Cash App copy everywhere and open on the web and Android; no payment is made or recorded by Battleplan itself.
- Someone not an admin can't read another person's share or any due through the server, whatever app asks.

## 7. Design system and UI

### 7.1 Brand

- **Name:** Battleplan.
- **Logo:** the Stencil Crest (owner's pick, 2026-11-06: "I like the Stencil crest. Let's use that."): an upright team-patch shield with a flat top, cut corners and a long point, with an ink edge, a thick cream rim, a card-olive field, a big cream Black Ops One stencil B and a coral hem at the point, on an ink hard shadow, on an Army green tile, plus the wordmark. The same mark is the website's header mark, the web app's loading screen, the app icons (Android's themed icon is the shield's outline, rim, hem and B as one shape), and the splash screens on Army green's page. The browser tab draws a simpler copy on the 16 px grid (`favicon-small.svg`: no shadows, a 1 px rim, a solid B), and the 32 px favicon draws the crest 10% bigger with no stencil cut. From 2026-10-26 to 2026-11-06 the mark was the Sticker Crest, a tilted lemon shield with a B in a chat bubble on blue raspberry (iOS 1.1 keeps it); before that, a white flag on a pole with an angular B cut out of it (2026-10-14), which the 1.0 build keeps.
- **Primary color:** Army green `#474C2B`, the app icon's background (a radial gradient from `#50552F` to `#3D4124`). The splash screens are on `#0E0E0D`, Dark's page from when Dark became the default color scheme (2026-11-10, SET-2), near Black's `#0D0D0C`; they were Army green before. Blue raspberry `#4D9BFF` was the 1.1 icon's background and is still a candy; deep blue `#2F5BEA` (Q9) was the 1.0 mark's color and is still the first team color.
- **Team colors** mark which team is which: the color is on the team's logo or initials badge, in the switcher, and as its dot in Your schedule. It doesn't tint the pages, which follow the color scheme each person sees (SET-2, §7.4). My chat balloons keep the scheme's own color (mustard, or light blue in Black) unless the chat look picks the team color (CHAT-18).

### 7.2 Look and feel

**Boot Camp Mix**, from #85 (the owner's pick, 2026-11-22: "let's replace the existing themes with these 3 themes", from the Boot Camp Mix mockups; Open Field before it, from 1.1, and Gumdrop Pop before that): a comic-book boot camp, loud and friendly:

- stencil capitals for titles, labels, buttons, tabs, and counts; a plain rounded reading font for messages and everything you read;
- ink everywhere: a 3 px ink outline on every panel, button, field, and balloon, and hard offset shadows with no blur, down and to the right;
- square panels on the page, a dot grid behind them, and rows split by 3 px ink lines;
- camouflage only in headers: our own soft blotches, never a real pattern or insignia, with a halftone fading in from the top right;
- push buttons: a rounded face on a hard shadow that shifts down and right onto it when pressed or picked;
- mustard tags, turned a little, over titles ("TEAM CHAT", "GAME · HOME"), and big outlined titles in white with an ink stroke and a hard shadow;
- your own balloon and reactions in the scheme's trim (mustard; light blue in Black, silver in Central Wildcats, gold in Geaux Tigahs); others' balloons in the panel color;
- colors with meanings: green for Going, orange for Maybe, `#FF8A80` for Can't go, red for games, warnings, and the send and + buttons, blue for practices and Directions, purple for social events;
- dog tags for players; the current tab's icon on a mustard tile.

Today's layout and wording stay; the content still carries the visual weight.

### 7.3 Design tokens

| Token | Values |
|---|---|
| **Color** | Seven color schemes (§7.4), each a `CampPalette`: ink, shadow, page and its dots, panel, tab bar, the lettering on the page and on panels (they differ only in Candy Pop, white on its blue page and navy on its white panels) with their muted shades, the trim (mustard, silver, or gold), your balloon, red, blue, green, orange, purple, the unanswered dog tag, the answer row, the tools row, the disabled icon, four camouflage colors, the header's halftone and lettering (white on Sky Blue's blue camouflage, over its navy-lettered page), and the ball chain. Can't go (`#FF8A80`) and a title's white fill are the same in every scheme. Lettering on any bright block (the trim, green, orange, light blue) is ink; on the red, the ink or white, whichever reads. Every text color is contrast-checked in all seven. |
| **Type** | Bundled with the app, the same on every platform: **Battleplan Stencil** (Big Shoulders Stencil at weight 900, always capitals; `tools/make_fonts.sh` cuts it) for titles, labels, buttons, tabs, and counts, spaced 0.05 em (tags 0.09 em), and **Comic Neue** Bold for messages and body text, in Latin letters (other scripts draw in the platform's fallback font). Both are under the SIL Open Font License, bundled with their OFL.txt and listed in Licenses. Sizes: the team name 32 (stepping down to 28, 25, 22, then two lines at 22 or 19 to fit, §5.2), page titles 50, push buttons 16.5, tab labels 12, tags 11. Layouts survive system text scaling up to 200%. |
| **Buttons** | Push buttons: 40 tall, corner 11, a 3 px ink outline, a panel face on a hard 3/3 shadow; picked or pressed, the face shifts 3 px right and down onto it. The main action's face is your color (mustard, or light blue in Black). Round icon buttons: a 36 px circle, a 2.5 px ink outline, a 2/2 shadow; an unread dot is 13 px red with a 2.5 px ink outline. What can't be pressed doesn't look pressable: a locked RSVP answer is one flat tag, and a closed poll has no rings (#53). |
| **Spacing** | 4-point grid: 4, 8, 12, 16, 24, 32, 48. Teams, Profile, and pushed screens keep their rows and text 20 from the edge, level with their titles; elsewhere side padding is 16 on phones and 24 on wide screens. |
| **Corners** | Square for panels, cards, sheets, and menus; 11 for push buttons; 19 for speech balloons; 10 for the current tab's tile; round for icon buttons, row badges, and avatars. |
| **Elevation** | No soft shadows. Depth is the hard offset shadow: 4/4 under panels, 3/3 under push buttons and titles, 2/2 under round buttons and the tab tile. |
| **Icons** | Material Symbols Rounded, the same set on every platform |
| **Motion** | 150–250 ms with standard easing. Respect the system "reduce motion" setting. |

### 7.4 Boot Camp Mix and its color schemes

From #85 the app has one look, **Boot Camp Mix**, in seven color schemes (three from #85 and four from #86); they share every shape, font, and part, and differ only in color. **Black** is the default (owner's request 2026-11-10: "make the dark theme the default theme"; called Dark until #85, and still stored as `dark`). In list order:

- **Army green** (`army`; olive page, cream lettering, woodland camouflage): an olive page (`#474C2B`) under a dark dot grid, panels a shade lighter (`#575A3A`), a deeper olive tab bar, cream lettering (`#F4EAD0`), ink (`#1A1A18`) outlines and shadows, and mustard (`#F2C230`) for tags and your balloon.
- **Black** (`dark`; black page, cream lettering, night camouflage): a black page (`#0D0D0C`) under a faint cream dot grid, charcoal panels (`#252522`), cream lettering, black outlines with olive-drab shadows (`#363A28`) so panels still stand off the page, and your balloon and reactions in light blue (`#93CFF5`) rather than mustard.
- **Light** (`light`; sand page, white panels, desert camouflage): a sand page (`#F2EBE0`), white panels and tab bar, black lettering (`#1A1A18`) for every word and outline, and mustard (`#EFBE2B`) for tags and your balloon. On the admin dashboard, numbers are solid ink, and the open-reports number red with an ink outline.
- **Sky Blue** (`sky`; #86, owner's request 2026-11-22: "Sky Blue (with sky blue also being the background color of the boxes)"): a sky-blue page (`#BCD9F5`) under a navy dot grid, boxes, balloons, and the tab bar the same sky blue, set off by navy (`#0B1531`) outlines and hard shadows, navy for every word, mustard (`#F5C731`) trim, and a navy and sky camouflage lettered in white. Admin dashboard numbers are solid ink. Sky Blue Pop's picks show as Sky Blue.
- **Candy Pop** (`candypop`; #86: "Candy Pop (royal blue/white)"): a bright blue page (`#1748D4`) under white lettering, white panels and balloons under navy (`#0B1640`) lettering and navy-gray (`#4B5A8C`) small print, a navy tab bar, yellow (`#FFD43A`) trim, candy-bright accents, and a royal-blue camouflage. Text boxes and menus opened from the page are a deeper blue (`#1238A8`), where its white lettering reads; the message box is a white panel. Admin dashboard numbers are solid ink.
- **Central Wildcats** (`wildcat`; #86: "Central Wildcats (maroon)"): a maroon page (`#5E1224`), panels a shade lighter (`#701C30`), white lettering, black (`#0B0B0B`) ink and tab bar, silver (`#C9CED6`) where the others have mustard (tags, stars, the current tab, your balloon, the ball chain), and a maroon and black camouflage. Colors only: no school's name, logo, or mark.
- **Geaux Tigahs** (`purplegold`; #86: "Geaux Tigahs (purple)"): a purple page (`#461D7C`), panels a shade lighter (`#55278F`), white lettering, a deeper purple tab bar, gold (`#FDD023`) trim, social events in lavender (`#C7A6FF`) so they show on the purple, and a purple camouflage. Colors only: no school's name, logo, or mark.

Forest green, Dark (now Black), Navy, Sky Blue Pop, and Scoreboard, and saved themes, are gone from the pickers; a pick of one reads as the closest of the seven (SET-2).

**Who picks.** A team's admins set its default scheme in Admin settings; each person can pick their own for a team or group in Team settings → Color scheme, which wins over the team's default, plus a default on Teams for the top level and every team with neither (SET-2).

**Team colors** don't tint the pages: a team's color is on its badge, in the switcher, and as its dot in Your schedule (TEAM-1, §7.1). The dot is the team's true color, never lightened, 10 px; where it stands out from the card under it by less than 3:1, a 1.5 px ring in the card's muted text outlines it, one rule in every scheme (#36). It's decorative; the name beside it says the team.

- A team still on a retired color (Royal blue or Violet) shows as its replacement (Blue or Purple) everywhere (TEAM-5).

Photos are never dimmed. Every scheme meets **WCAG AA contrast** (4.5:1 for body text). Every key screen has golden images in all seven schemes, for reviewing changes by eye (they don't fail CI), and accessibility checks, including contrast, in all seven.

### 7.5 Components

Build these once in `core/` and reuse them everywhere:

- Team header with switcher, on camouflage (`CampHeader`, `CampAppBar`)
- Navigation bar and rail
- Avatar (photo, or initials on the color the person picked, SET-8, else a consistent one)
- Message tile (others' on the page, mine in a bubble)
- Reactions row and picker
- Poll card
- Event card and event row
- RSVP button group
- Document row (a plain row between hairlines, like the settings rows)
- Member row
- Settings rows (Boot Camp Mix, #85): one square ink panel of rows on a hard shadow, the rows split by 3 px ink lines, each with its icon in ink on a 36 px mustard round badge in an ink outline, a title and muted subtitle, and a chevron; a destructive row's badge is red and its title in the accent text. Section headings over them are stencil capitals ("JUST FOR YOU", "FOR ADMINS"), and page titles white stencil in a thick ink outline, turned a little ("TEAM SETTINGS"). A true card (the team's card on the Team tab and in Team settings, a player card) is the same square ink panel.
- Headings: page headings and card headings in the stencil, small capitals labels in the section label style; big titles outlined (`OutlinedText`) and tags (`CampTag`), §7.2
- Empty state (a 64 px muted icon, one sentence, one coral button, and at most one quiet link under it: the team's empty Schedule's Import a schedule, SCHED-1)
- Load error (#40, #42): every "Couldn't load" says it this one way and offers Try again, the full form for a page or tab and the inline form for a section within one; never a bare sentence. The chat, its search, and Messages keep their own sentences in it. The empty state's look with the error icon, "Couldn't load this. Check your connection and try again." and a coral **Try again**, read once to screen readers; inline, one muted "Couldn't load this." and a quiet **Try again**, for a section within a page; and over a list that keeps what it shows, a slim band in the scheme's warning look, "Couldn't refresh. Try again". Try again starts the list over, with its placeholder rows meanwhile
- Skeleton loaders (no spinners for lists): placeholder rows for lists, and for grids placeholder tiles in the grid's own columns, as Saved plays and Team photos load (#25)
- Snackbar
- Confirm dialog (destructive actions in red, with the verb on the button: "Delete message")
- Bottom sheet on phones, dialog or popover on wide screens

Sheets, dialogs, menus, snack bars, inputs, buttons, chips, and switches take their look from the app theme, so every screen the Boot Camp Mix mockups don't draw (Docs, Team, profile, sign-in, dialogs, sheets) follows the same rules on today's layout and wording; dialogs and sheets are panels.

### 7.6 Accessibility

- Screen-reader labels on every icon button and image. Photos read as "Photo from Alex".
- The banners above every screen, the email verification banner (AUTH-3) and the super admins' announcement (ADMIN-7), are read before the page, with their buttons, and announced when they appear. They sit above the navigator, so the pages are one screen-reader node of their own; without it, each page's modal barrier hid them (#33).
- Logical focus order, a visible focus ring, and full keyboard navigation on web.
- Touch targets at least 48 × 48.
- Outlined lettering (page titles, the event's title and counts, the team's name; Boot Camp Mix, #85) reads by its thick ink outline on a light page and by its fill on a dark one: in every scheme one or the other stands at least 3:1 from the page, the panels, and the camouflage (#86).
- Color is never the only signal: RSVP states also use icons and words.
- Text contrast meets WCAG AA in all eleven color schemes (§7.4), checked by the accessibility tests.
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
- [ ] RSVPs, including Maybe and admins answering for members; per-player RSVPs, and notifications to players and guardians (PLAYER-6, PLAYER-7, PLAYER-9).
- [ ] Upcoming, Past, and Calendar views; Your schedule.
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
2. Roster details and contact sharing (TEAM-10); answering for several players, each on their own row, and RSVP history (PLAYER-11). Built (tasks 136 and 137).
3. Calendar subscription (SCHED-11)
4. RSVP nudges and guest counts (SCHED-12)
5. Team-specific link previews for invites (ARCH §6.6). Built (task 140).
6. Folders and the chat photo gallery (DOC-7). The gallery is built (task 141); folders aren't.
7. Announcement-only mode (TEAM-12), polls list (POLL-6)
8. App icon badges, hidden notification text (NOTIF-12), files in chat (CHAT-16)
9. Persistent team list on very wide screens (§5.5)
10. Attendance history and CSV exports of RSVPs and the roster for admins
11. A branded invite page with the team's logo and color (`/join`)

**Built 2026-10-29:** groups beside teams (TEAM-14). **Built 2026-11-02:** search in the chat (CHAT-20), and starting a new season from a team (TEAM-16).

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
- Searching all chats at once, or for part of a word (searching one chat by its words is CHAT-20)
- Link previews in chat, GIFs, video, voice notes
- Voice and video calls
- SMS
- Email digests (reminders by email for people who can't get notifications are SCHED-14)
- Typing indicators and read receipts
- Attendance tracking, stats, and scores
- Taking payments in the app (DUES tracks who paid, in full or in part, and shows how to pay the team; the money moves person to person, outside Battleplan)
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
| Q14 | ~~On youth teams, should coaches and staff also RSVP for themselves?~~ **Decided 2026-10-11:** yes. Team admins RSVP for themselves and are counted apart from players (PLAYER-6). **2026-10-12:** on every team, admins and members not linked to a player answer for themselves, counted apart as "others". A member who is a player answers on their player's row instead, admins included. **2026-11-06:** on a team, only players have RSVPs (PLAYER-6, task 347). | — |
| Q15 | ~~When a parent picks an existing player, must an admin approve the link?~~ **Decided 2026-10-11:** yes (PLAYER-3). **2026-10-12:** this covers every claim, as the player or a guardian; an admin's own claim is approved at once. | — |
| Q16 | ~~Is Facebook sign-in needed at launch?~~ **Decided 2026-10-11:** not for now. Launch with Google, Apple, and email. **2026-10-12:** Facebook sign-in was removed from the plan. **Later on 2026-10-12:** it returns as go-live Phase 6, with single sign-on (§9, ARCH D60). | — |
| Q17 | ~~Should there be separate adult and youth team types?~~ **Decided 2026-10-12 (the owner's request):** no. There's one team type. Every team has players; any member can claim a player as "I am this player" or as a parent or guardian, and any member can add a player. Team admins approve or decline claims and members' new players (§6.3). | — |
| Q18 | ~~Should we store player details such as date of birth?~~ **Decided 2026-10-12 (the owner's request):** yes, as optional details seen only by the team's admins and the player's linked people, with consent for medical notes (PLAYER-12, ARCH D63). **2026-10-20 (the owner's request):** medical notes and their consent stamp were removed, so no health data is stored. Date of birth, emergency contacts, and notes stay. | — |
