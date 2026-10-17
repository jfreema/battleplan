# App Store listing

What to paste into App Store Connect for the iPhone and iPad app (roadmap task 129, store checklist 1.16, 1.17, and 3.2 to 3.8). The privacy answers are in [STORE-PRIVACY.md](STORE-PRIVACY.md). The Google Play listing (task 213) can reuse this text, minus the Apple-only fields.

Keep it true to the app: change this page when a feature it names changes. Don't name other apps anywhere in the listing, don't mention Android, and aim it at coaches and parents, never at kids (store checklist 5.5, 5.6).

## App information

| Field | Value |
|---|---|
| Name | `Battleplan` (if the App Store says it's taken: `Battleplan Team Chat`) |
| Subtitle (30 characters) | `Team chat, schedule, and RSVPs` |
| Bundle ID | `app.getbattleplan` |
| SKU | `battleplan` |
| Primary language | English (U.S.) |
| Primary category | Sports |
| Secondary category | Social Networking |
| Price | Free |
| Availability | United States only, while Buy Jared a coffee links to Venmo (store checklist 5.8) |
| Copyright | `2026` and your legal name, as on your Apple Account |
| Content rights | No third-party content: everything in the app is the team's own or ours |

## Age rating (store checklist 3.5)

Answer the questionnaire as the app is:

- **Messaging and chat, user-generated content:** yes. People post messages, photos, and files to their teams and message each other.
- **Advertising:** no. **In-app purchases:** no.
- **Unrestricted web access:** no. Links open in the browser, outside the app.
- **Violence, mature or suggestive themes, profanity, gambling, contests, alcohol, tobacco, drugs, medical treatment information:** none. A team's posts aren't the app's content, and the language filter is on for every team.
- **Age assurance:** people confirm they're 18 or older at sign-up, and the Terms require it (AUTH-5).

Don't pick the Kids category or "made for kids": accounts are for adults, and players don't get accounts.

## Version information

**Promotional text** (170 characters; can change without a new version):

```
Free for every team, with no ads. Chat with the team, schedule games and practices, see who's coming for every player, and keep files and plays in one place.
```

**Description** (4,000 characters):

```
Battleplan is team chat and scheduling for sports teams, free for every team and with no ads. Coaches, players, and parents get the whole team in one app: the chat, the schedule, who's coming, and the team's files.

TEAM CHAT
• Photos, reactions, replies, @mentions, and pinned messages
• Announcements from coaches that everyone sees
• Direct messages with anyone you share a team with

SCHEDULE AND RSVPS
• Games, practices, and events with opponents, places, and reminders
• Going, Maybe, or Not going in one tap, for yourself or for each of your players
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
• Plays: a whiteboard with real baseball, basketball, soccer, and football fields. Drag players and the ball, draw routes, play the steps back, and save the plays worth keeping
• Bring your team's messages, photos, files, and schedule over from the app or calendar you use now

SAFE AND PRIVATE
• Teams are invite-only, by link, QR code, or code
• Report and block anyone, and a language filter on every team
• Accounts are for adults 18 and older
• No ads, and we never sell your data

Sign in with Apple or Google.
```

**Keywords** (100 characters; the name and subtitle already count, so they aren't repeated):

```
coach,sports,roster,attendance,practice,league,parents,baseball,softball,soccer,basketball,football
```

| Field | Value |
|---|---|
| Support URL | `https://getbattleplan.app/support` |
| Marketing URL | `https://getbattleplan.app` |
| Privacy Policy URL | `https://getbattleplan.app/privacy` |

**Screenshots**, in their file order:

| Folder | Display | Size | Screens |
|---|---|---|---|
| `store/app-store/iphone-6.9/` | iPhone 6.9-inch | 1320 × 2868 | chat, schedule, an event's RSVPs, a play, documents, roster |
| `store/app-store/iphone-6.3/` | iPhone 6.3-inch, only if App Store Connect asks for it | 1206 × 2622 | the same six, scaled down |
| `store/app-store/ipad-13/` | iPad 13-inch | 2064 × 2752 | chat, schedule, an event's RSVPs, a play, documents |

They're captures of the app in the iOS Simulator (iPhone 18 Pro Max and iPad Pro 13-inch) against the Firebase emulators, with the seed data plus sample players, events, documents, and photos made for them (no real people). Retake them when the screens they show change: build from a scratch copy with `bannerLabel` returning null (as website/README.md describes), set the Simulator's status bar to 9:41 with full bars, and capture with `xcrun simctl io <device> screenshot`.

## App Review information (store checklist 1.14, 1.17, 3.8)

- **Sign-in required:** yes. Use the demo account from task 132 (made on prod; its password goes only in App Store Connect's sign-in fields, never in this repo).
- **Contact:** your name, phone, and `support@getbattleplan.app`.
- **Notes** (fill in the demo team's code once task 132 makes it). The demo login works in the iPhone app once Universal Links are on (task 110): a tapped `getbattleplan.app/emaillogin` link opens the app's email sign-in, but a link typed into Safari opens the web app instead.

```
Battleplan is team chat and scheduling for sports teams. Teams are invite-only, so the demo account above already owns a team with players, events, chat, a poll, documents, and a play, and you can sign in with it directly.

How to get in:
• Sign in with Apple or Google on the sign-in screen, then join the demo team with code [DEMO TEAM CODE] (Join a team).
• Or use the demo account above. Email sign-in isn't on the sign-in screen, which offers Apple and Google; it's at getbattleplan.app/emaillogin. On the device, paste that address into Notes and tap it, and the app opens its email sign-in.

Where things are:
• Report: press and hold someone's message, then Report.
• Block: press and hold their message and choose Block, or tap their photo to open their page and use the menu at the top (Block, Report).
• Delete account: Settings, then Delete account. Accounts that use Sign in with Apple sign in with Apple once more, and the app revokes Apple's tokens before deleting.
• A language filter is on for every team.

Accounts are for adults 18 and older. Kids don't have accounts: parents and guardians answer for them.

Buy Jared a coffee (Team settings, About Battleplan) opens the developer's Venmo. It's a voluntary tip that unlocks nothing, and the app is listed in the United States only while it's there.
```
