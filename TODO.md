# Battleplan — Setup TODO

Things only you can do (accounts, payments, decisions), organized by phase. **Nothing is bought until the phase that needs it,** except the domain, which was worth securing early. We build and test against Firebase's local emulators first, which need no account and cost nothing.

Go-live happens in six phases, web first (decided 2026-10-12; [docs/ROADMAP.md](docs/ROADMAP.md), ARCH D60). Apple sign-in, the App Store, Google Play, and Facebook each wait for a phase of their own.

| Phase | When | Spend |
|---|---|---|
| **0 · Get ready to build** | Done | $8.20: the domain's first year (it renews at $14.20/year) |
| **During development** | When a feature needs it | $0. A card is on file for the dev project's Blaze plan, but usage is ≈ $0. |
| **1 · Website and web app go-live** | Before our team moves over | ≈ $0–3/month for Firebase at a few teams. Email $0: Firebase Auth sends signup emails, Resend Free sends invites |
| **2 · GDPR and EU, backups, security** | Right after Phase 1 | Backups under $1/month (Cloudflare R2's free tier covers 10 GB) |
| **3 · Sign in with Apple** | After Phase 2 | $99/year: Apple Developer |
| **4 · iPhone and iPad on the App Store** | After Phase 3 | $0 more (the same Apple membership) |
| **5 · Android on Google Play** | After Phase 4 | $25: Google Play (one time) |
| **6 · Facebook sign-in and SSO** | After Phase 5 | $0 for Facebook |

Some approvals take days or weeks, so each phase says how far ahead to start.

---

## Phase 0 · Get ready to build (done; free except the domain)

### Install the dev tools

Updated 2026-10-11: everything is installed, and `flutter doctor` is clean for iOS, Android, and Chrome.

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
| Android Studio and the Android SDK | ✅ |
| Xcode | ✅ |

Your `~/.zshrc` now puts Node 22, Android Studio's Java runtime, and the FlutterFire CLI on your PATH. Open a new terminal to pick them up.

You won't write any Java. Android's build tools and Firebase's local database emulator run on the Java runtime, the way iOS builds need Xcode.

**Your steps**

- [x] **1. Xcode.** Install it from the Mac App Store (~15 GB) and open it once to accept the license. Then run this in Terminal; it asks for your Mac password:

  ```sh
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch
  ```

- [x] **2. Android SDK.** Open Android Studio and click through the setup wizard, choosing *Standard*. It downloads the Android SDK and an emulator.
- [x] **3. Tell me when both are done.** I accepted the Android licenses and ran `flutter doctor` until iOS, Android, and Chrome all showed ✓ (2026-10-11).

### Accounts and decisions

- [x] **Use your personal Gmail** for Battleplan's services. Without the LLC, a separate account isn't needed. 2-Step Verification confirmed on 2026-10-10.
  - It owns the Firebase projects, and later the billing account and Google Play.
  - Whoever can sign in controls the app's servers, billing, and Play listing, so keep 2-Step Verification on and your recovery phone and email current (myaccount.google.com/security).
  - Google's sign-in screen shows the project's support email. When you turn on Google sign-in, pick `battleplan-help@googlegroups.com` there, not your Gmail.
  - Optional: after creating the dev project, add a second Google account you control as an owner (*Project settings → Users and permissions*). Losing access to one account then never locks you out.
- [x] **Create a Google Group for that support email**: `battleplan-help@googlegroups.com`, created and tested 2026-10-09.
- [x] **Make a Battleplan vault in the family 1Password** for every login and 2FA recovery code. Don't share it with the family. *Done 2026-10-11: the "Battle" vault.*
- [x] **Bought `getbattleplan.app` at Cloudflare** (SPEC Q8) on 2026-10-10: $8.20 the first year, then $14.20/year. It expires 2027-10-10 unless auto-renew (on by default) renews it, so leave auto-renew on.
  - The Cloudflare account signs in with Google, so your Gmail's 2-Step Verification protects it. Cloudflare's own two-factor (*My Profile → Authentication*) is an optional extra layer.
  - [x] **Verify the domain's contact email if Cloudflare asks.** No verification email came; the Cloudflare account signs in with Google, so its email is already verified (checked 2026-10-11).
  - Until Phase 1, the app uses the free `battleplan-dev-ecce4.web.app` address. The domain is for the website, the web app at `/app`, invite links, email, and the privacy and support pages.
  - `battleplan.app`, `.io`, and `.com` are taken. `.io` would have cost the most ($50/year to renew).
- [x] **Created both Firebase projects** on 2026-10-10, on the free Spark plan. IDs are permanent:
  - dev: **`battleplan-dev-ecce4`** ("the dev project" in these docs)
  - prod: **`battleplan-prod`**. It stays on Spark until Phase 1.
- [x] **Log in from the terminal** so I can run setup commands as you: `firebase login`, then `gcloud auth login` and `gcloud auth application-default login`.
- [x] **App ID** (iOS bundle ID / Android package name): `app.getbattleplan`, the domain reversed, so it stays with the app if an LLC takes it over later. Dev builds use `app.getbattleplan.dev`. It can change until the first TestFlight upload (Phase 4).

**What this unlocks.** M0 through M3 run entirely on the local emulators, for free:

- sign-in (email, plus simulated Google);
- chat, polls, schedule, and documents;
- the server functions and security rules.

iOS runs in the Simulator, and Android runs in an emulator or on your own phone.

---

## During development (free; when a feature needs it)

- [x] **Upgrade the dev project (`battleplan-dev-ecce4`) to the Blaze plan** when we first need server functions or photo storage running in the cloud. *Done in M1, with a budget alert at $5.*
  - It needs a card, but expected cost at testing volume is ≈ $0.
  - Budget alerts: Cloud Billing → *Budgets & alerts*, at $5, $25, $50, and $100.
- [x] **Email-sending service** for setup emails, team invites, and security notices (Firebase can't send these): Resend's free tier, with `getbattleplan.app` verified. *Done 2026-10-11: the API key is in Secret Manager as `RESEND_API_KEY` and in the Battle vault. The DMARC record is part of Phase 1.*

**Testing on your own phones is free.**

- **Android:** install test builds directly on your phone.
- **iPhone:** a free Apple ID can install builds for basic testing. Push notifications, Sign in with Apple, and invite links that open the iPhone app wait for Phases 3 and 4. Until then, use the web app in Safari or from the Home Screen.

---

## Phase 1 · Website and web app go-live (before our team moves over)

The website and the web app at `getbattleplan.app/app`, in desktop and phone browsers. No Apple, App Store, or Google Play steps yet.

**Email, the cheapest way** (ARCH §6.7, D61): Firebase Auth sends every signup and account email for $0 (Cloudflare's sending would cost at least $5/month). Resend Free keeps sending invites and setup emails for $0, up to 100 a day. Cloudflare Email Routing receives `support@` and `privacy@` for free.

- [ ] **Set up the production project, `battleplan-prod`** (created 2026-10-10).
  - Its region is decided: `us-central1` (SPEC Q11). The database's region is permanent.
  - Upgrade it to Blaze and set budget alerts the same day, at $5, $25, $50, and $100.
  - Connect `getbattleplan.app` on its Hosting page (*Add custom domain*). In Cloudflare, add the records Firebase shows and set each to **DNS only** (grey cloud). A proxied (orange) record points the domain at Cloudflare instead of Firebase, so Firebase can't verify it or issue the certificate.
  - Our team's data on prod carries straight into every later phase.
- [ ] **Support address.** In Cloudflare, turn on Email Routing for `getbattleplan.app` (*Compute → Email Service → Email Routing*), verify your Gmail as the destination, and forward `support@getbattleplan.app` and `privacy@getbattleplan.app` to it.
- [ ] **Firebase's built-in emails from your domain**, after the domain is connected to prod Hosting. In prod, go to *Authentication → Templates → Customize domain* and add the records it lists, with the CNAMEs set to DNS only. Merge Firebase's SPF entry into the one apex `v=spf1` record; a domain can have only one. Set the sender to "Battleplan" `<noreply@getbattleplan.app>` and the reply-to to `support@getbattleplan.app`. Verification can take up to 24 hours.
- [ ] **DMARC record.** Add `_dmarc` with `v=DMARC1; p=none; rua=...` and turn on Cloudflare DMARC Management to read the reports. It gets stricter in Phase 2.
- [ ] **Bootstrap yourself as prod's first super admin.** I'll give you the one command to run.
- [ ] **Fill in the legal pages.** The Privacy Policy, Terms of Use, and delete-account drafts have bracketed placeholders for your legal name, governing law, and effective date.
- [ ] **Move our team over:** beta on the web with our team, then post the invite link in GroupMe and show the QR code at practice. Run both apps for about two weeks.
- [ ] **Check the bill** after those two weeks: Cloud Billing → *Reports*, by service. I'll compare it with the cost model.

---

## Phase 2 · GDPR and EU, backups, security (right after Phase 1)

- [ ] **Data processing terms.** Accept Google's data processing terms for both Firebase projects (in the Firebase console's project settings), and keep copies of Resend's and Cloudflare's.
- [ ] **Decide whether Battleplan serves EU teams on purpose.** If it does, GDPR Art. 27 asks for a representative in the EU, which is a paid service.
- [ ] **Backups off-site** (ARCH §6.12, D62). In Cloudflare, create an R2 bucket for backups and an API token that can reach only that bucket. Save the token and the backup encryption key I give you in the Battle vault, and keep an offline copy of the key. R2 is free up to 10 GB, then $0.015/GB-month; Wasabi and Azure cost more at our size.
- [ ] **Two-factor everywhere.** Turn on 2-Step Verification on every Battleplan account: Google, Cloudflare, GitHub, Resend, and 1Password.
- [ ] **DNSSEC.** Turn it on for `getbattleplan.app` in Cloudflare (*DNS → Settings*).
- [ ] **Stricter DMARC.** After 2 to 4 weeks of reports showing Firebase and Resend passing, change the record to `p=quarantine`, then `p=reject`.

---

## Phase 3 · Sign in with Apple (buy about a week before)

**Start about a week before this phase.** Apple usually approves an individual in a day or two, but it can take longer if Apple asks for ID.

- [ ] **Check your legal name and address** on your Apple Account at account.apple.com → *Personal Information*, and fix any nickname or old address. Apple's enrollment uses this name as the App Store seller.
- **You publish under your own name** (SPEC Q13, decided). The LLC is no longer registered, so both stores list you as an individual, with your legal name as the seller. No D-U-N-S number or company website is needed.
  - Without an LLC, you're personally liable for the apps.
  - If you form or reinstate an LLC later, both stores upgrade the account in place and keep the apps: Apple through a membership update request, and Google Play under *Developer account → About you → Change account type*. Both need the LLC's D-U-N-S number (free, 1–2 weeks).
- [ ] **Apple Developer Program** ($99/year): developer.apple.com/programs/enroll.
  - Enroll as an individual with your own Apple Account. Enter your legal name exactly as on your ID, and pay with a card in your name; otherwise Apple asks for a photo ID, which slows approval.
  - One membership covers every app on every Apple platform, including Mac apps signed for download outside the App Store.
  - Needed for Sign in with Apple now, and for TestFlight, iOS push notifications, and invite links that open the iPhone app in Phase 4.
  - [ ] Create the **Sign in with Apple key** and Services ID. I'll walk you through it. The key file downloads only once, so save it to the password manager right away.
- [ ] **Apple's private email relay.** Register `getbattleplan.app` and `send.getbattleplan.app` as email sources so email reaches people who use "Hide My Email".

---

## Phase 4 · iPhone and iPad on the App Store

- [ ] Create the **APNs key** (push). I'll walk you through it. The key file downloads only once, so save it to the password manager right away.
- [ ] **Invite our team's iPhone and iPad users to TestFlight.**
- [ ] **EU trader status** in App Store Connect. Apple asks even if you skip the EU.
  - A trader's address and phone number appear on EU store pages. Apple lets an individual show a P.O. box instead of a home address.
  - A free app with no business behind it may count as non-trader, which shows nothing. Revisit if Battleplan ever charges (SPEC Q4).
- [ ] **The rest of the Phase 4 checklist** in [docs/SPEC.md](docs/SPEC.md) §10: the store listing, screenshots, the age rating, and the App Review demo account.

---

## Phase 5 · Android on Google Play (start 3–4 weeks before)

- [ ] **Check your legal name and address** on your Google payments profile at pay.google.com → *Settings*. Google Play's personal account takes your name and address from it and checks them against your ID.
- [ ] **Google Play Console** ($25, one time): play.google.com/console/signup.
  - Create a **personal** account with your Gmail. Google verifies your legal name and address, which takes a few days, and you confirm you have a real Android phone (Android 10 or later) with the Play Console app. Borrow one if you need to.
  - Google Play shows your legal name, your country, and a developer email on the app's page. Use `support@getbattleplan.app` for that email, not your Gmail.
  - Personal accounts then need a **closed test with 12+ testers who stay opted in for 14 days in a row**, and Google takes up to a week to review the request for production access. Start **3–4 weeks before** you want to be on Google Play.
- [ ] **Android upload key.** I'll generate it at the first Play upload. Store the keystore file and its passwords in the password manager, plus an offline backup.
- [ ] **EU trader status** in the Play Console, as for Apple in Phase 4.
- [ ] **The rest of the Phase 5 checklist** in [docs/SPEC.md](docs/SPEC.md) §10: the listing, the Data safety form, and the content rating.

---

## Phase 6 · Facebook sign-in and SSO

- [ ] **Meta developer account and app** at developers.facebook.com, with business verification if Meta asks. I'll walk you through the app settings and Meta's App Review.
- [ ] **Decide which single sign-on options teams want**, such as Microsoft accounts or a club's own login. SAML or OIDC sign-in needs Firebase's paid Identity Platform upgrade past its free tier, so we'll check the price first.

---

## Where keys and secrets go

**Nothing secret goes in the git repo.** Turn on two-factor sign-in for every account as you create it.

| Item | Phase | Secret? | Where it lives |
|---|---|---|---|
| Firebase app config (`firebase_options_*.dart`, `google-services.json`, `GoogleService-Info.plist`) | 0 | **No.** It only identifies the project; security comes from rules and App Check. | Committed to the repo |
| GitHub Actions deploy access | 0 | Yes | Keyless Workload Identity Federation, which I'll set up. No key file. |
| Service-account JSON key files | — | Avoid creating them | Local admin scripts use your `gcloud auth application-default login` instead |
| Web push key, reCAPTCHA site key | 1 | No (public) | App config in the repo |
| Email service API key | During development | Yes | Google Secret Manager as `RESEND_API_KEY` (dev, set 2026-10-11; prod in Phase 1), plus the Battle vault in 1Password |
| R2 backup token and backup encryption key | 2 | Yes | Google Secret Manager, plus the Battle vault; an offline copy of the encryption key |
| Sign in with Apple key (`.p8`) | 3 | Yes. Downloads only once. | Entered in Firebase's Apple sign-in settings; the original in the password manager |
| APNs key (`.p8`) | 4 | Yes. **Downloads only once.** | Uploaded to Firebase (*Project settings → Cloud Messaging*); the original file in the password manager |
| App Store Connect upload credentials (automated releases) | 4 | Yes | Password manager and GitHub Actions secrets |
| Android upload keystore and passwords | 5 | Yes | Password manager, plus an offline backup |
| Play upload credentials (automated releases) | 5 | Yes | Password manager and GitHub Actions secrets |
| Meta app secret | 6 | Yes | Entered in Firebase's Facebook sign-in settings; the original in the password manager |

---

## Open questions

Every question in SPEC §12 is decided as of 2026-10-12.

---

## What I'll do once Phase 0 is done

- Create the Flutter project (iOS, Android, web) with dev and prod flavors, connected to the dev project, `battleplan-dev-ecce4`.
- Set up the emulators with seed data, so the whole app runs locally for free.
- Add starter security rules, indexes, and TTL policies, plus the GitHub Actions workflows, the import-boundary check, and `.gitignore` rules for key files. Cloud deploys of server functions switch on when dev moves to Blaze.
- Tell you when an item in a later phase becomes necessary, and walk you through the console-only steps.
