# Battleplan — Setup TODO

Things only you can do (accounts, payments, decisions), organized in phases. **Nothing is bought until the phase that needs it.** We build and test against Firebase's local emulators first, which need no account and cost nothing. Purchases wait until real people are testing on real phones.

| Phase | When | Spend |
|---|---|---|
| **0 — Get ready to build** | Now | $0 |
| **1 — During development** | When we reach a feature that needs it | $0. A card goes on file for Firebase, but usage is ≈ $0. |
| **2 — Team beta** | When the app is ready for our team on real phones | ~$110–130: Apple Developer ($99/year) and a domain ($10–30/year) |
| **3 — Public launch** | Before opening sign-up to other teams | $25: Google Play (one time) |

Some approvals take days or weeks, so each phase says how far ahead to start.

---

## Phase 0 — Get ready to build (now, free)

### Install the dev tools

Updated 2026-10-08: everything is installed except Xcode and the Android SDK, which need you.

| Tool | Status |
|---|---|
| Homebrew, git, GitHub CLI | ✅ |
| GitHub repo | ✅ `jfreema/battleplan`, private |
| VS Code extensions: Dart, Flutter, ESLint, Prettier | ✅ |
| Google Chrome | ✅ |
| Node 22 | ✅ 22.23.3 |
| Firebase CLI | ✅ 15.33.0 |
| Flutter SDK | ✅ 3.47.6 |
| FlutterFire CLI | ✅ 1.4.1 |
| CocoaPods | ✅ 1.17.0 |
| Google Cloud CLI | ✅ 588.0.0 |
| Java runtime (not the language) | ✅ Bundled with Android Studio |
| Android Studio | ✅ Installed. **The Android SDK is your step 2 below.** |
| Xcode | ❌ **Your step 1 below** |

Your `~/.zshrc` now puts Node 22, Android Studio's Java runtime, and the FlutterFire CLI on your PATH. Open a new terminal to pick them up.

You won't write any Java. Android's build tools and Firebase's local database emulator run on the Java runtime, the way iOS builds need Xcode.

**Your steps**

- [ ] **1. Xcode.** Install it from the Mac App Store (~15 GB) and open it once to accept the license. Then run this in Terminal; it asks for your Mac password:

  ```sh
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch
  ```

- [ ] **2. Android SDK.** Open Android Studio and click through the setup wizard, choosing *Standard*. It downloads the Android SDK and an emulator.
- [ ] **3. Tell me when both are done.** I'll accept the Android licenses and run `flutter doctor` until iOS, Android, and Chrome all show ✓.

### Accounts and decisions

- [ ] **Use the Battle LLC Gmail account**, since the LLC publishes the app.
  - It owns the Firebase projects, and later the billing account and Google Play.
  - Google shows its address to users as the support email on the Google sign-in screen, so your personal address stays private.
  - First, turn on 2-Step Verification, make sure the recovery phone and email are yours, and change the password if anyone else knows it. Whoever can sign in controls the app's servers, billing, and Play listing.
  - After creating the dev project, add your personal Google account as a second owner (*Project settings → Users and permissions*). Losing access to one account then never locks you out.
- [ ] **Make a Battleplan vault in the family 1Password** for every login and 2FA recovery code. Don't share it with the family.
- [ ] **Create the `battleplan-dev` Firebase project** on the free Spark plan: console.firebase.google.com → *Add project*. Skip Google Analytics, and don't add a card. Project IDs are global and permanent; if the name is taken, try `battleplan-app-dev`.
- [ ] **Log in from the terminal** so I can run setup commands as you: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`.
- [ ] **Pick the app ID** (iOS bundle ID / Android package name), for example `com.<company>.battleplan`, using Battle LLC's name rather than yours. Dev builds add `.dev`. It can change until the first TestFlight upload, but setting it now saves a rename later.

**What this unlocks.** M0 through M3 run entirely on the local emulators, for free:

- sign-in (email, plus simulated Google and Facebook);
- chat, polls, schedule, and documents;
- the server functions and security rules.

iOS runs in the Simulator, and Android runs in an emulator or on your own phone.

---

## Phase 1 — During development (free; when a feature needs it)

I'll tell you when each of these comes up.

- [ ] **Meta for Developers app** (free), when we build Facebook sign-in in M1: developers.facebook.com → *Create app* → *Authenticate and request data from users with Facebook Login*. Development mode is enough. App Review waits for Phase 3.
- [ ] **Upgrade `battleplan-dev` to the Blaze plan** when we first need server functions or photo storage running in the cloud, to test photos and push notifications on real phones (around M3–M4).
  - It needs a card, but expected cost at testing volume is ≈ $0.
  - **Set budget alerts the same day**: Cloud Billing → *Budgets & alerts*, at $5, $25, $50, and $100.

**Testing on your own phones is free.**

- **Android:** install test builds directly on your phone.
- **iPhone:** a free Apple ID can install builds for basic testing. Push notifications, Sign in with Apple, and invite links that open the iPhone app all wait for Phase 2.

---

## Phase 2 — Team beta (buy just before our team starts testing)

**Start about two weeks before the beta**, because Apple's approval can take that long.

- **Battle LLC publishes the app** (SPEC Q13, decided). The stores show its legal name as the seller.
  - [ ] **D-U-N-S number.** Apple and Google Play both require one for an organization. It's free, so do it any time: check whether Battle LLC already has one with Apple's D-U-N-S lookup, and request one there if not (1–2 weeks). The name and address must match the LLC's state filing.
  - Publishing as an organization also skips Google Play's 14-day, 12-tester closed test (Phase 3).
- [ ] **Domain** (SPEC Q8). **Buy it before enrolling with Apple**, or any time sooner; good names are going fast.
  - Apple requires a working website on a domain tied to the LLC, and rejects parked pages and social-media links. I'll build a one-page site on Firebase Hosting that names Battle LLC.
  - Taken as of 2026-10-09: `battleplan.com`, `.app`, `.io`, `.co`, `.net`, `.org`, `.us`, `battleplanapp.com`, and `getbattleplan.com`.
  - Until then we use the free `battleplan-dev.web.app` address.
  - Cloudflare Registrar is a good choice: at-cost pricing, free DNS, and free email forwarding.
- [ ] **Apple Developer Program** ($99/year): developer.apple.com/programs/enroll.
  - Enroll as Battle LLC with an Apple Account at your domain, which Apple recommends. A domain has no email until you add it, so first turn on Cloudflare **Email Routing** (free) and forward an address like `jared@` to the Gmail. It only receives mail, which is all Apple needs.
  - One membership covers every app on every Apple platform, including Mac apps signed for download outside the App Store.
  - Needed for TestFlight, iOS push notifications, Sign in with Apple, and invite links that open the iPhone app.
  - Approval takes from a day to two weeks.
  - [ ] Create the **APNs key** (push) and the **Sign in with Apple key** and Services ID. I'll walk you through it. Each key file downloads only once, so save it to the password manager right away.
- [ ] **Email**, all on free tiers:
  - [ ] **Support address.** Forward `support@yourdomain` to your inbox with Cloudflare Email Routing.
  - [ ] **Email-sending service** for team invites, setup emails, and security notices (Firebase can't send these). Use **Resend**'s free tier. Verify your domain with the DNS records it gives you (SPF, DKIM), plus a DMARC record.
  - [ ] **Firebase's built-in emails from your domain.** Go to *Authentication → Templates → Customize domain* and add the DNS records, so password-reset and verification emails come from `noreply@yourdomain`. Set the sender name to "Battleplan".
  - [ ] **Apple's private email relay.** Register both sending addresses so email reaches people who use "Hide My Email".
- [ ] **Production Firebase project `battleplan-prod`.**
  - **Choose its region first.** Use `us-central1` unless most teams will be outside the US. This is permanent (SPEC Q11).
  - Upgrade it to Blaze and set budget alerts.
  - The beta runs on prod, so our team's data carries straight into launch.
- **Android beta testers** install through Firebase App Distribution, which is free. No Google Play account is needed yet.

---

## Phase 3 — Public launch (before opening sign-up to other teams)

- [ ] **Google Play Console** ($25, one time): play.google.com/console/signup.
  - Identity verification takes a few days.
  - Personal accounts then need a **14-day closed test with 12+ testers**, so start **3–4 weeks before** you want to be on Google Play.
- [ ] **Android upload key.** I'll generate it at the first Play upload. Store the keystore file and its passwords in the password manager, plus an offline backup.
- [ ] **Facebook App Review.** It needs the privacy-policy and data-deletion URLs.
- [ ] **Legal pages**: Privacy Policy, Terms of Use, and a delete-account page.
- [ ] **The rest of the launch checklist** in [docs/SPEC.md](docs/SPEC.md) §10: store listings, screenshots, age ratings, and the App Review demo account.

---

## Where keys and secrets go

**Nothing secret goes in the git repo.** Turn on two-factor sign-in for every account as you create it.

| Item | Phase | Secret? | Where it lives |
|---|---|---|---|
| Firebase app config (`firebase_options_*.dart`, `google-services.json`, `GoogleService-Info.plist`) | 0 | **No.** It only identifies the project; security comes from rules and App Check. | Committed to the repo |
| GitHub Actions deploy access | 0 | Yes | Keyless Workload Identity Federation, which I'll set up. No key file. |
| Service-account JSON key files | — | Avoid creating them | Local admin scripts use your `gcloud auth application-default login` instead |
| Facebook App Secret | 1 | Yes | Entered in Firebase's Facebook sign-in settings; also in the password manager |
| Web push key, reCAPTCHA site key | 1–2 | No (public) | App config in the repo |
| Email service API key | 2 | Yes | Google Secret Manager, via `firebase functions:secrets:set`, plus the password manager |
| APNs key (`.p8`) | 2 | Yes. **Downloads only once.** | Uploaded to Firebase (*Project settings → Cloud Messaging*); the original file in the password manager |
| Sign in with Apple key (`.p8`) | 2 | Yes. Downloads only once. | Entered in Firebase's Apple sign-in settings; the original in the password manager |
| Android upload keystore and passwords | 3 | Yes | Password manager, plus an offline backup |
| App Store Connect and Play upload credentials (automated releases) | 3 | Yes | Password manager and GitHub Actions secrets |

---

## Open questions (not blocking)

SPEC §12 has a working default for each of these, so answer them when convenient:

- Q1: "Team" or "Group"
- Q4: funding
- Q5: direct messages
- Q6: reactions
- Q7: wide-screen tabs
- Q9: logo and colors
- Q10: email service
- Q12: who creates events
- Q14: staff RSVPs
- Q15: guardian approval

---

## What I'll do once Phase 0 is done

- Create the Flutter project (iOS, Android, web) with dev and prod flavors, connected to `battleplan-dev`.
- Set up the emulators with seed data, so the whole app runs locally for free.
- Add starter security rules, indexes, and TTL policies, plus the GitHub Actions workflows, the import-boundary check, and `.gitignore` rules for key files. Cloud deploys of server functions switch on when dev moves to Blaze.
- Tell you when a Phase 1 or 2 item becomes necessary, and walk you through the console-only steps.
