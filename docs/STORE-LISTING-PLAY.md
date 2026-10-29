# Google Play listing

What to paste into the Play Console for the Android app (roadmap task 213, store checklist 1.16, 4.4, and 4.6). The App Store version is [STORE-LISTING.md](STORE-LISTING.md); the privacy answers both stores use are in [STORE-PRIVACY.md](STORE-PRIVACY.md).

Keep it true to the app: change this page when a feature it names changes. Don't name other apps anywhere in the listing, don't mention the iPhone or the App Store, and aim it at coaches and parents, never at kids (store checklist 5.5, 5.6).

## Create app

| Field | Value |
|---|---|
| App name (30 characters) | `Battleplan` (if Play says it's taken: `Battleplan Team Chat`) |
| Package name | `app.getbattleplan` (set by the first App Bundle) |
| Default language | English (United States), en-US |
| App or game | App |
| Free or paid | Free |
| Countries | United States and Canada, as on the App Store. The Android app leaves out Buy Jared a coffee (it's only on the web), so there's nothing to pay for and no Play billing question |

## Main store listing

**Short description** (80 characters at most; this one is 67):

```
Free team chat, schedule, and RSVPs for sports teams. No ads, ever.
```

**Full description** (4,000 characters at most; this one is about 2,000):

```
Battleplan is team chat and scheduling for sports teams, free for every team and with no ads. Coaches, players, and parents get the whole team in one app: the chat, the schedule, who's coming, and the team's files.

TEAM CHAT
• Photos, reactions, replies, @mentions, and pinned messages
• Every photo shared in the chat, in one place
• Announcements from coaches that everyone sees
• Direct messages with anyone you share a team with

SCHEDULE AND RSVPS
• Games, practices, and events with opponents, places, and reminders
• Going, Maybe, or Not going in one tap, for yourself or for each of your players, right from the schedule
• Assignments like snacks, drinks, and scorekeeper that families volunteer for
• Coaches see how many players are coming, with coaches and others counted apart
• Coaches can email everyone who hasn't answered, and they can answer right from the email
• A private calendar link keeps your calendar app in sync

PLAYERS AND PARENTS
• Adult players answer for themselves
• Parents and guardians answer for their kids, who don't need accounts
• Coaches can keep each player's date of birth, emergency contacts, and notes, seen only by coaches and the player's own people

MORE FOR COACHES
• Polls for quick decisions
• Documents: lineups, rules, waivers, and links
• Plays: a whiteboard with real baseball, basketball, soccer, and football fields. Drag players and the ball, draw routes, play the steps back, and save the plays worth keeping, then post them to the chat, or save or share them as animated GIFs
• Bring your team's messages, photos, files, and schedule over from the app or calendar you use now

MAKE IT YOURS
• Five looks: Gumdrop Army, Gumdrop Pop Dark, Gumdrop Pop Light, Gumdrop Candy, and Gumdrop Arena
• Each team picks its color, and in all but Gumdrop Army the team's screens take it on
• Coaches pick the chat's message color and background

SAFE AND PRIVATE
• Teams are invite-only, by link, QR code, or code
• Report and block anyone, and a language filter on every team
• Accounts are for adults 18 and older
• No ads, and we never sell your data

Sign in with Google or Apple.
```

Check the counts after any edit: the short description must stay at 80 characters or fewer, the full description at 4,000 or fewer.

**Graphics** (`store/google-play/`):

| Asset | File | Size |
|---|---|---|
| App icon | `store/google-play/icon-512.png` (from `assets/brand/icon.png`) | 512 × 512 PNG, no transparency |
| Feature graphic | `store/google-play/feature-graphic.png` (source: `feature-graphic.html` beside it, rendered with headless Chrome; the command is at its top) | 1024 × 500 PNG, no transparency |
| Phone screenshots | `store/google-play/phone/01-chat.jpg` to `06-roster.jpg`: chat, schedule, an event's RSVPs, a play, documents, and roster in Gumdrop Pop Dark, the same screens as the App Store set. Rendered from the app's widgets on sample data at 360 × 640 logical pixels × 3 (as website/README.md describes for the site's screenshots), with no device frame or status bar | 1080 × 1920 JPEG, 9:16 |
| Tablet screenshots | Optional (7-inch and 10-inch) | |

## Store settings

| Field | Value |
|---|---|
| App category | Sports |
| Tags (up to 5, from Play's list) | the closest of: Sports, Team management, Messaging, Calendar, Scheduling |
| Email address | `support@getbattleplan.app` |
| Website | `https://getbattleplan.app` |
| Phone number | Leave blank (optional) |
| External marketing | On |

## App content (Policy, App content)

**Privacy policy:** `https://getbattleplan.app/privacy`

**Ads:** No, the app doesn't contain ads.

**App access:** All or some functionality is restricted. Add one set of instructions:

- Name: `Demo team`
- Username: `appreview@getbattleplan.app`
- Password: the demo account's password, typed into the Play Console only (it's in 1Password; never in this repo)
- Any other information:

```
Battleplan is team chat and scheduling for sports teams. Teams are invite-only, so the demo account above already owns a team with players, events, chat, a poll, documents, and a play.

How to get in:
• Sign in with Google on the sign-in screen, then tap Join a Team or Group and enter the demo team's code: [the demo team's code, typed here in the Play Console only].
• Or use the demo account above. Email sign-in isn't on the sign-in screen, which offers Google and Apple; it's at getbattleplan.app/emaillogin. On the device, tap that address (for example from a note or an email) and the app opens its email sign-in.

Where things are:
• Report: press and hold someone's message, then Report.
• Block: press and hold their message and choose Block, or tap their photo to open their page and use the menu at the top (Block, Report).
• Delete account: Profile (at the bottom of the Teams screen), then Settings, then Delete account, or getbattleplan.app/delete-account.
• A language filter is on for every team.

Accounts are for adults 18 and older. Kids don't have accounts: parents and guardians answer for them.
```

The email sign-in link opens the app only once prod App Links verify (`hosting/well-known/prod/assetlinks.json`, task 212); until then it opens the web app in the browser, so the Google sign-in and team code route is the one that works.

**Content rating** (the IARC questionnaire). Email `support@getbattleplan.app`. Category: the one for social and communication apps, where people talk to each other and share content (not a game). Answer it as the app is:

- Violence, blood, fear, sexuality, nudity, crude humor, bad language, controlled substances (drugs, alcohol, tobacco), gambling or simulated gambling: no. A team's posts aren't the app's content, and the language filter is on for every team.
- Users can interact or exchange content with each other (chat, photos, files, direct messages): yes.
- Shares the user's current physical location with other users: no.
- Allows users to buy digital goods: no.
- Unrestricted internet access (a web browser or search engine in the app): no. Links open in the browser, outside the app.
- Is it a news app, or does it feature user-generated content about news: no.

Expect a rating with an "Users interact" notice. Don't pick anything aimed at children.

**Target audience and content:** 18 and over only. The app doesn't appeal to children and isn't designed for them: accounts are for adults (SAFE-6), and players under 18 never sign in. Store listing doesn't unintentionally appeal to children: yes.

**News app:** No.

**COVID-19 contact tracing and status:** Not one of these apps (if asked).

**Data safety:** Answer from [STORE-PRIVACY.md](STORE-PRIVACY.md), "Google Play: Data safety":

- Collects or shares required user data types: yes. Shared with third parties: none (Google Firebase, Apple, and Resend are service providers).
- Encrypted in transit: yes. People can ask for their data to be deleted: yes.
- Account deletion URL: `https://getbattleplan.app/delete-account` (also in the app: Profile, then Settings, then Delete account).
- Data types and purposes: the table in STORE-PRIVACY.md, row for row (name, email, user IDs, phone number, photos, files and docs, other in-app messages, app interactions, other user-generated content, approximate location, crash logs, diagnostics, device or other IDs). Nothing is processed ephemerally, and nothing is used for advertising.

**Government apps:** No, it isn't developed by or for a government.

**Financial features:** None (the app has no financial features).

**Health:** Not a health app (the Health apps declaration: none of the listed features). It stores no health data.

**Account deletion:** `https://getbattleplan.app/delete-account`.

## Release notes (internal and closed testing)

```
Battleplan for Android: team chat, the schedule and RSVPs, polls, documents, and plays. Thanks for testing: tell us what breaks at support@getbattleplan.app.
```
