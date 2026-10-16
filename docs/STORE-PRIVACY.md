# Store privacy answers

The answers for the App Store's App Privacy section and Google Play's Data safety form, written once so both match the [Privacy Policy](../website/privacy.html) and the iPhone app's privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`). SPEC LEGAL-4; store checklist 1.15, then 3.4 and 4.4.

If the app starts collecting something new, change the Privacy Policy, the privacy manifest, and this page together, then both stores' answers.

## What Battleplan collects

| Data | Where it comes from | Why | Required? |
|---|---|---|---|
| Name | Sign-in and setup; admins who add someone | Shown to the person's teams | Yes |
| Email address | Sign-in; admins and members who invite or add someone | Sign-in, setup links, invites, security notices | Yes |
| Phone number | A person who shares one with a team (TEAM-10); players' emergency contacts (PLAYER-12) | Shown to that team, or to the player's admins and linked people | No |
| Health information | Players' medical notes, with consent (PLAYER-12) | Seen only by the team's admins and the player's linked people | No |
| Photos | Chat photos, profile photos, team logos and backgrounds | Shown to the team | No |
| Files and documents | Team documents | Shown to the team | No |
| Messages | Team chat | Shown to the team | No |
| Other content | Polls and votes, events, RSVPs and their notes, players' records (name, jersey number, walk-up song, and the optional details), reports | The team's schedule, roster, and moderation | No |
| User ID | The account | Running the app; analytics and crash reports carry it | Yes |
| Device IDs | A notification token per phone or browser; Analytics' app instance ID (never the advertising ID) | Notifications; analytics | Yes |
| App interactions | Google Analytics for Firebase: app opens and screens | Understanding which features are used | Yes |
| Approximate location | Analytics infers the country from the IP address | Analytics | Yes |
| Crash logs and diagnostics | Firebase Crashlytics on phones; sampled error reports from the web app | Fixing bugs | Yes |

Not collected: precise location, contacts (the system calendar sheet reads them, not Battleplan), browsing or search history, purchases, financial information, the advertising ID, and audio. Nothing is used for tracking or advertising, and nothing is sold.

## App Store: App Privacy

- **Do you or your third-party partners collect data from this app?** Yes.
- **Tracking:** no data is used to track. Battleplan never asks for App Tracking Transparency.
- **Linked to the user:** everything below. Analytics and Crashlytics carry the account's user ID.

| App Store data type | Collected | Linked | Purposes |
|---|---|---|---|
| Contact Info: Name | Yes | Yes | App Functionality |
| Contact Info: Email Address | Yes | Yes | App Functionality |
| Contact Info: Phone Number | Yes | Yes | App Functionality |
| Health & Fitness: Health | Yes | Yes | App Functionality |
| User Content: Photos or Videos | Yes | Yes | App Functionality |
| User Content: Other User Content | Yes | Yes | App Functionality |
| Identifiers: User ID | Yes | Yes | App Functionality, Analytics |
| Identifiers: Device ID | Yes | Yes | App Functionality, Analytics |
| Usage Data: Product Interaction | Yes | Yes | Analytics |
| Location: Coarse Location | Yes | Yes | Analytics |
| Diagnostics: Crash Data | Yes | Yes | App Functionality |
| Diagnostics: Other Diagnostic Data | Yes | Yes | App Functionality |

Everything else: not collected. These match the manifest's `NSPrivacyCollectedDataTypes` one for one.

## Google Play: Data safety

- **Does your app collect or share any of the required user data types?** Yes.
- **Is all of the user data collected by your app encrypted in transit?** Yes (HTTPS only).
- **Do you provide a way for users to request that their data is deleted?** Yes: in the app (Settings → Delete account) and at `https://getbattleplan.app/delete-account`.
- **Shared with third parties:** none. Google (Firebase), Apple, and Resend process data for Battleplan as service providers, which Play doesn't count as sharing.
- **Processed ephemerally:** no.

| Play category: type | Collected | Optional? | Purposes |
|---|---|---|---|
| Personal info: Name | Yes | Required | App functionality, Account management |
| Personal info: Email address | Yes | Required | App functionality, Account management, Developer communications |
| Personal info: User IDs | Yes | Required | App functionality, Analytics, Account management |
| Personal info: Phone number | Yes | Optional | App functionality |
| Health and fitness: Health info | Yes | Optional | App functionality |
| Photos and videos: Photos | Yes | Optional | App functionality |
| Files and docs: Files and docs | Yes | Optional | App functionality |
| Messages: Other in-app messages | Yes | Optional | App functionality |
| App activity: App interactions | Yes | Required | Analytics |
| App activity: Other user-generated content | Yes | Optional | App functionality |
| Location: Approximate location | Yes | Required | Analytics |
| App info and performance: Crash logs | Yes | Required | App functionality, Analytics |
| App info and performance: Diagnostics | Yes | Required | App functionality, Analytics |
| Device or other IDs | Yes | Required | App functionality, Analytics |

"Developer communications" is the security notices, setup links, and invites; there are no marketing emails.

## Elsewhere in the consoles

- **Privacy Policy URL:** `https://getbattleplan.app/privacy`. **Account deletion URL** (Play): `https://getbattleplan.app/delete-account`.
- **Play target audience:** adults, 18 and over. Accounts are for adults (SAFE-6); youth players never sign in.
- **Play Health apps declaration:** Battleplan isn't a health app; it keeps optional medical notes that parents and admins enter for coaches.
- **App Store age rating:** say yes to people chatting and sharing content, which comes with Report, Block, and the language filter (SAFE-1, SAFE-2, SAFE-7).
