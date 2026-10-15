# App Store and Google Play checklist

What has to happen before Apple's App Store and Google Play will approve Battleplan, in five phases. Phases 1 to 4 are requirements, grouped by what each needs first. Phase 5 isn't required but lowers the odds of a rejection. After launch, fixes and features go out as ordinary updates.

✅ is done, ⬜ is still to do. 👤 marks your steps: accounts, consoles, and forms only you can fill in. Task numbers are from [ROADMAP.md](ROADMAP.md). Checked against both stores' rules as of October 2026.

## Phase 1 · Before the store accounts and Sign in with Apple

Required, and doable now.

- ✅ 1.1 **Delete account** in the app (Settings → Delete account) and on the web (getbattleplan.app/delete-account).
- ✅ 1.2 **Report and block** for messages, documents, and people. The Terms, accepted at sign-up, say zero tolerance for objectionable content and abusive behavior.
- ✅ 1.3 **Privacy Policy, Terms, and support** live on getbattleplan.app, the Privacy Policy and Terms linked in the app, and support@getbattleplan.app published.
- ✅ 1.4 **iPhone permission prompts** give a clear reason each: camera, photo library, saving photos, calendar, contacts.
- ✅ 1.5 **Android permissions:** photos come through the system picker, with no broad photo, video, or storage access and no advertising ID.
- ✅ 1.6 **Android target API level 36**, required since August 31, 2026: Flutter's current default.
- ✅ 1.7 **A filter for objectionable words** (SAFE-7, task 155), for Apple's guideline 1.2, which asks apps where people post content for "a method for filtering objectionable material." Swear words and slurs in chat messages, captions, and polls show as "f***"; it's on for every team, and admins can turn it off under Team settings → Language.
- ✅ 1.8 **Act on every report within 24 hours.** Reviewers ask for this, and the Terms promise it. Every new report emails each super admin, reports about a team's admins included, and a daily email lists any report open more than 12 hours.
- ⬜ 1.9 **A privacy manifest** (`PrivacyInfo.xcprivacy`) for the iPhone app, declaring why it uses APIs Apple lists, such as stored preferences. Apple refuses uploads without the declarations (ITMS-91053).
- ⬜ 1.10 **Encryption:** `ITSAppUsesNonExemptEncryption` set to NO in Info.plist. Battleplan uses only standard HTTPS, and this stops export compliance from holding up each build.
- ⬜ 1.11 **Android release builds in GitHub Actions** (tasks 126, 214): an upload key, and an Android App Bundle signed with it. Nothing runs on your Mac. Today the release build is set up with the debug key.
- ⬜ 1.12 **iPad.** The app is built for iPad too, so every screen has to work there, in both orientations and in Split View (task 210); review runs on iPads.
- ⬜ 1.13 **It works end to end,** on the iPhone and iPad simulators and on Android with a build from GitHub Actions:
  - sign up and finish setup (Jade's fix);
  - join a team;
  - chat, post photos, and RSVP.

  No crashes, and no "beta," "coming soon," or placeholder text anywhere.
- ⬜ 1.14 👤 **A demo account on prod** for the reviewers (task 132):
  - a password, because reviewers can't get emails;
  - an address you can read (forward appreview@getbattleplan.app; only support@ and privacy@ forward today);
  - a team of its own with players, events, chat, a poll, and documents.
- ⬜ 1.15 **The privacy answers, written down once for both stores,** matching the Privacy Policy. Both stores ask about:
  - names, emails, and the phone numbers people share;
  - messages, photos, and files;
  - **health data** (players' medical notes);
  - players' records entered by parents, which may be children's;
  - device tokens, crash reports, and usage analytics.

  The rest: no tracking, no ads, nothing sold.
- ⬜ 1.16 **The listing, ready to paste in:**
  - name, subtitle or short description, and description;
  - screenshots of the app in use, not the sign-in screen: 6.9-inch iPhone, 13-inch iPad, and Android phone;
  - a 1024 × 500 feature graphic for Google; the 512 px icon is `assets/brand/icon.png`.
- ⬜ 1.17 **App Review notes:**
  - what Battleplan is, and the demo login;
  - that teams are invite-only and the demo account already has one;
  - where Report, Block, and Delete account are, and that the language filter is on for every team;
  - that kids don't have accounts.

## Phase 2 · After Sign in with Apple is set up

Setting it up (the key and Services ID, task 107) happens in your Apple Developer account, so it comes right after you enroll in phase 3. Sign in with Apple is required because Battleplan offers Google sign-in: guideline 4.8 then calls for a sign-in that lets people keep their email private.

- ⬜ 2.1 **Continue with Apple** on the sign-in screen and in Sign-in methods, on iPhone, iPad, and the web, with Apple's standard button (task 109). It's in the app now, hidden.
- ⬜ 2.2 **Email reaches people who hide their address:** register Battleplan's sending domain with Apple's private email relay (task 207).
- ⬜ 2.3 **Delete account also revokes the person's Sign in with Apple token,** through Apple's REST API. Apple requires this of apps that offer Sign in with Apple.
- ⬜ 2.4 **Test it end to end:** a new account with Apple, setup, signing out and back in, and deleting the account.

## Phase 3 · After joining the Apple Developer Program

- ⬜ 3.1 👤 **Enroll** as an individual, $99 a year (task 106). It takes a few days.
- ⬜ 3.2 👤 **Create the app in App Store Connect** under the name "Battleplan." The name has to be free on the App Store.
- ⬜ 3.3 **iPhone release builds** (task 209):
  - signed for the App Store;
  - built with Xcode 26 or later and the iOS 26 SDK, required since April 28, 2026 (this Mac has Xcode 27);
  - built with `FIREBASE_ANALYTICS_WITHOUT_ADID=true`, as Info.plist notes, so Analytics carries no advertising ID;
  - uploaded to TestFlight.
- ⬜ 3.4 👤 **App Privacy labels** from the phase 1 answers (task 130).
- ⬜ 3.5 👤 **Age rating questionnaire** (task 130). Say yes to people chatting and sharing content. Don't pick the Kids category: accounts are for adults.
- ⬜ 3.6 👤 **EU trader status** (task 131). A free app with no ads and no business behind it may qualify as non-trader, which shows nothing; apps that never answer get pulled from EU storefronts.
- ⬜ 3.7 👤 **The listing** from phase 1 (task 129): the Sports category, the support and privacy URLs, and the iPhone and iPad screenshots.
- ⬜ 3.8 👤 **App Review information:** the demo login and the review notes (task 132). Then submit (task 133).

## Phase 4 · After the Google Play Console is set up

- ⬜ 4.1 👤 **Open the Play Console** as a personal account, $25 once (task 125). Google verifies your legal name and address and has you confirm on a real Android phone.
- ⬜ 4.2 **Play App Signing,** and the first App Bundle uploaded to internal testing. Then add Play's signing key fingerprints to Firebase, or Google sign-in fails in builds from Play (task 127).
- ⬜ 4.3 👤 **Closed test:** at least 12 testers opted in for 14 days in a row, then apply for production access (task 128). New personal accounts can't publish without it. Recruit about 15, since testers who leave early don't count.
- ⬜ 4.4 👤 **The App content forms:**
  - Data safety from the phase 1 answers, with the delete-account URL;
  - content rating (IARC);
  - target audience: adults (18+);
  - ads: none;
  - app access: the demo login;
  - the Health apps declaration, which every app files; Battleplan stores medical notes.
- ⬜ 4.5 👤 **EU trader status** in the Play Console.
- ⬜ 4.6 👤 **The listing** from phase 1 (task 213): the short and full descriptions, the Sports category, the contact email, the privacy URL, the icon, the feature graphic, and the phone screenshots. Then submit for production (task 214).

## Phase 5 · Not required, but lowers the odds of a rejection

- ⬜ 5.1 **Test the store builds on real devices first:** TestFlight and Play internal testing, on a small and a large phone and an iPad. Read Play's pre-launch report.
- ⬜ 5.2 **Keep prod working with the build in review:** no breaking backend changes while it waits.
- ⬜ 5.3 **Leave App Check in monitor mode** until real store traffic shows as verified (tasks 104, 214), so a setup slip can't lock the reviewer out.
- ⬜ 5.4 **Run a trademark search on "Battleplan."** Another software company already uses the name.
- ⬜ 5.5 **Keep other apps' names out of Apple's keywords** (GroupMe, TeamSnap, TeamReach, GameChanger), and don't mention Android in the iPhone listing.
- ⬜ 5.6 **Aim the listings at coaches and parents:** no kid-focused art or wording, so neither store treats Battleplan as a kids' app.
- ⬜ 5.7 **Take "position" out of the Privacy Policy and the delete-account page.** Players no longer have one, and the policy should match the app exactly.
