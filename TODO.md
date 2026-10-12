# Battleplan — Setup TODO

Things only you can do (accounts, payments, decisions), organized in phases. **Nothing is bought until the phase that needs it,** except the domain, which is worth securing now. We build and test against Firebase's local emulators first, which need no account and cost nothing. Other purchases wait until real people are testing on real phones.

| Phase | When | Spend |
|---|---|---|
| **0 — Get ready to build** | Now | $8.20: the domain's first year (it renews at $14.20/year) |
| **1 — During development** | When we reach a feature that needs it | $0. A card goes on file for Firebase, but usage is ≈ $0. |
| **2 — Team beta** | When the app is ready for our team on real phones | $99/year: Apple Developer |
| **3 — Public launch** | Before opening sign-up to other teams | $25: Google Play (one time) |

Some approvals take days or weeks, so each phase says how far ahead to start.

---

## Phase 0 — Get ready to build (now; free except the domain)

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

- [x] **Use your personal Gmail** for Battleplan's services. Without the LLC, a separate account isn't needed. 2-Step Verification confirmed on 2026-10-10.
  - It owns the Firebase projects, and later the billing account and Google Play.
  - Whoever can sign in controls the app's servers, billing, and Play listing, so keep 2-Step Verification on and your recovery phone and email current (myaccount.google.com/security).
  - Google's sign-in screen shows the project's support email. When you turn on Google sign-in, pick `battleplan-help@googlegroups.com` there, not your Gmail.
  - Optional: after creating the dev project, add a second Google account you control as an owner (*Project settings → Users and permissions*). Losing access to one account then never locks you out.
- [x] **Create a Google Group for that support email**: `battleplan-help@googlegroups.com`, created and tested 2026-10-09.
- [x] **Make a Battleplan vault in the family 1Password** for every login and 2FA recovery code. Don't share it with the family. *Done 2026-10-11: the "Battle" vault.*
- [ ] **Check your legal name and address** where the stores will read them later, and fix any nickname or old address now:
  - your Apple Account at account.apple.com → *Personal Information*. Apple's enrollment uses this name as the App Store seller (Phase 2).
  - your Google payments profile at pay.google.com → *Settings*. Google Play's personal account takes your name and address from it and checks them against your ID (Phase 3).
- [x] **Bought `getbattleplan.app` at Cloudflare** (SPEC Q8) on 2026-10-10: $8.20 the first year, then $14.20/year. It expires 2027-10-10 unless auto-renew (on by default) renews it, so leave auto-renew on.
  - The Cloudflare account signs in with Google, so your Gmail's 2-Step Verification protects it. Cloudflare's own two-factor (*My Profile → Authentication*) is an optional extra layer.
  - [ ] **Verify the domain's contact email if Cloudflare asks.** Cloudflare sends a verification link when the contact address differs from your login, as the Google Group does. Click it by **2026-10-25**: ICANN rules put an unverified domain on hold after 15 days. If it isn't in your Gmail, check the group's pending and spam messages at groups.google.com.
  - Until the beta, the app uses the free `battleplan-dev-ecce4.web.app` address. The domain is for invite links, email, and the privacy and support pages the store listings link to.
  - `battleplan.app`, `.io`, and `.com` are taken. `.io` would have cost the most ($50/year to renew).
- [x] **Created both Firebase projects** on 2026-10-10, on the free Spark plan. IDs are permanent:
  - dev: **`battleplan-dev-ecce4`** ("the dev project" in these docs)
  - prod: **`battleplan-prod`**. It stays on Spark until Phase 2.
- [ ] **Log in from the terminal** so I can run setup commands as you: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`.
- [x] **App ID** (iOS bundle ID / Android package name): `app.getbattleplan`, the domain reversed, so it stays with the app if an LLC takes it over later. Dev builds use `app.getbattleplan.dev`. It can change until the first TestFlight upload.

**What this unlocks.** M0 through M3 run entirely on the local emulators, for free:

- sign-in (email, plus simulated Google);
- chat, polls, schedule, and documents;
- the server functions and security rules.

iOS runs in the Simulator, and Android runs in an emulator or on your own phone.

---

## Phase 1 — During development (free; when a feature needs it)

I'll tell you when each of these comes up.

- [ ] **Upgrade the dev project (`battleplan-dev-ecce4`) to the Blaze plan** when we first need server functions or photo storage running in the cloud, to test photos and push notifications on real phones (around M3–M4).
  - It needs a card, but expected cost at testing volume is ≈ $0.
  - **Set budget alerts the same day**: Cloud Billing → *Budgets & alerts*, at $5, $25, $50, and $100.

**Testing on your own phones is free.**

- **Android:** install test builds directly on your phone.
- **iPhone:** a free Apple ID can install builds for basic testing. Push notifications, Sign in with Apple, and invite links that open the iPhone app all wait for Phase 2.

---

## Phase 2 — Team beta (buy just before our team starts testing)

**Start about a week before the beta.** Apple usually approves an individual in a day or two, but it can take longer if Apple asks for ID.

- **You publish the app under your own name** (SPEC Q13, decided). The LLC is no longer registered, so both stores list you as an individual, with your legal name as the seller. No D-U-N-S number or company website is needed.
  - Without an LLC, you're personally liable for the apps.
  - If you form or reinstate an LLC later, both stores upgrade the account in place and keep the apps: Apple through a membership update request, and Google Play under *Developer account → About you → Change account type*. Both need the LLC's D-U-N-S number (free, 1–2 weeks).
- [ ] **Apple Developer Program** ($99/year): developer.apple.com/programs/enroll.
  - Enroll as an individual with your own Apple Account. Enter your legal name exactly as on your ID, and pay with a card in your name; otherwise Apple asks for a photo ID, which slows approval.
  - One membership covers every app on every Apple platform, including Mac apps signed for download outside the App Store.
  - Needed for TestFlight, iOS push notifications, Sign in with Apple, and invite links that open the iPhone app.
  - [ ] Create the **APNs key** (push) and the **Sign in with Apple key** and Services ID. I'll walk you through it. Each key file downloads only once, so save it to the password manager right away.
- [ ] **Email**, all on free tiers:
  - [ ] **Support address.** In Cloudflare, turn on Email Routing for `getbattleplan.app` (*Compute → Email Service → Email Routing*), verify your Gmail as the destination, and forward `support@getbattleplan.app` and `privacy@getbattleplan.app` to it.
  - [ ] **Email-sending service** for team invites, setup emails, and security notices (Firebase can't send these). Sign up for **Resend**'s free tier at resend.com/signup with your Gmail, add `getbattleplan.app`, and add the DNS records it gives you (SPF, DKIM) in Cloudflare, plus a DMARC record.
  - [ ] **Firebase's built-in emails from your domain.** Go to *Authentication → Templates → Customize domain* and add the DNS records, so password-reset and verification emails come from `noreply@getbattleplan.app`. Set the sender name to "Battleplan".
  - [ ] **Apple's private email relay.** Register both sending addresses so email reaches people who use "Hide My Email".
- [ ] **Set up the production project, `battleplan-prod`** (created 2026-10-10).
  - **Choose its region before creating its database.** Use `us-central1` unless most teams will be outside the US. The database's region is permanent (SPEC Q11).
  - Upgrade it to Blaze and set budget alerts.
  - Connect `getbattleplan.app` on its Hosting page (*Add custom domain*). In Cloudflare, add the records Firebase shows and set each to **DNS only** (grey cloud). A proxied (orange) record points the domain at Cloudflare instead of Firebase, so Firebase can't verify it or issue the certificate.
  - The beta runs on prod, so our team's data carries straight into launch.
- **Android beta testers** install through Firebase App Distribution, which is free. No Google Play account is needed yet.
  - Or, if 12 or more of the team use Android, run the Android beta as a Google Play closed test instead. That moves buying the Play account (Phase 3) up to now, but the beta then counts toward the 14-day test a personal account must pass before it can publish.

---

## Phase 3 — Public launch (before opening sign-up to other teams)

- [ ] **Google Play Console** ($25, one time): play.google.com/console/signup.
  - Create a **personal** account with your Gmail. Google verifies your legal name and address, which takes a few days, and you confirm you have a real Android phone (Android 10 or later) with the Play Console app. Borrow one if you need to.
  - Google Play shows your legal name, your country, and a developer email on the app's page. Use `support@getbattleplan.app` for that email, not your Gmail.
  - Personal accounts then need a **closed test with 12+ testers who stay opted in for 14 days in a row**, and Google takes up to a week to review the request for production access. Start **3–4 weeks before** you want to be on Google Play.
- [ ] **EU trader status**, in both stores. Apple asks even if you skip the EU.
  - A trader's address and phone number appear on EU store pages. Apple lets an individual show a P.O. box instead of a home address.
  - A free app with no business behind it may count as non-trader, which shows nothing. Revisit if Battleplan starts charging (SPEC Q4).
- [ ] **Android upload key.** I'll generate it at the first Play upload. Store the keystore file and its passwords in the password manager, plus an offline backup.
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
| Web push key, reCAPTCHA site key | 1–2 | No (public) | App config in the repo |
| Email service API key | 2 | Yes | Google Secret Manager as `RESEND_API_KEY` (dev, set 2026-10-11), plus the Battle vault in 1Password |
| APNs key (`.p8`) | 2 | Yes. **Downloads only once.** | Uploaded to Firebase (*Project settings → Cloud Messaging*); the original file in the password manager |
| Sign in with Apple key (`.p8`) | 2 | Yes. Downloads only once. | Entered in Firebase's Apple sign-in settings; the original in the password manager |
| Android upload keystore and passwords | 3 | Yes | Password manager, plus an offline backup |
| App Store Connect and Play upload credentials (automated releases) | 3 | Yes | Password manager and GitHub Actions secrets |

---

## Open questions (not blocking)

SPEC §12 has a working default for each of these, so answer them when convenient:

- Q4: funding
- Q5: direct messages
- Q6: reactions
- Q7: wide-screen tabs
- Q9: logo and colors
- Q10: email service
- Q12: who creates events

---

## What I'll do once Phase 0 is done

- Create the Flutter project (iOS, Android, web) with dev and prod flavors, connected to the dev project, `battleplan-dev-ecce4`.
- Set up the emulators with seed data, so the whole app runs locally for free.
- Add starter security rules, indexes, and TTL policies, plus the GitHub Actions workflows, the import-boundary check, and `.gitignore` rules for key files. Cloud deploys of server functions switch on when dev moves to Blaze.
- Tell you when a Phase 1 or 2 item becomes necessary, and walk you through the console-only steps.
