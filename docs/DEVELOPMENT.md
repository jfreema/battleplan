# Developing Battleplan

How to run the app and backend locally. The design is in [ARCHITECTURE.md](ARCHITECTURE.md); the features are in [SPEC.md](SPEC.md).

## Run it locally (no Firebase login needed)

Everything runs against the Firebase Emulator Suite under the project ID `demo-battleplan`. A `demo-` ID can't reach any cloud project, so nothing here touches `battleplan-dev-ecce4` or costs money.

1. **Start the emulators** (Auth, Firestore, Functions, Storage, and the UI at http://localhost:4000):

   ```sh
   npm --prefix functions install && npm --prefix functions run build
   firebase emulators:start --project demo-battleplan --import=./.emulator-data --export-on-exit
   ```

   In VS Code this is the **Emulators** task. `--export-on-exit` keeps your data between runs in `.emulator-data/` (git-ignored).

2. **Load sample data** in a second terminal (first time, or whenever you want a reset):

   ```sh
   npm --prefix tools/seed install
   npm --prefix tools/seed run seed
   ```

   It creates three teams (Thunder, adult softball players; Cyclone, kids' soccer; and Rally Possums, kids' basketball), with common American names and TV characters for people, parents with players on two teams, adults linked to their own players, a pending player to approve, events, RSVPs, polls, documents, two saved plays (Cyclone's relay home from right-center on the diamond, Thunder's pick and roll on the half court, for the landing page's two whiteboard screenshots), messages, and a direct conversation between Andy Bernard and Claire Dunphy (read by both, so Messages shows it with nothing unread). These are also the landing page's screenshots (`website/README.md`). Every password is `password`:

   | Email | Who |
   |---|---|
   | `coach@example.com` | Andy Bernard, owner of Thunder (adult players) and Cyclone (kids) |
   | `claire@example.com` | Claire Dunphy, parent on all three teams, with players on two (Luke and Alex on Cyclone, Haley on Rally Possums); asked to join Thunder's roster as a player (pending) |
   | `rachel@example.com` | Rachel Green, owner of Rally Possums, parent on Cyclone |
   | `jim@example.com`, `andy@example.com` | Jim Halpert and Andy Dwyer, players on Thunder, linked to their own players (Jim is also an admin) |
   | `phil@example.com` | Phil Dunphy, parent and assistant coach on Cyclone |
   | `monica@example.com`, `chandler@example.com` | Monica Geller and Chandler Bing, parents on Rally Possums |
   | `admin@example.com` | Super admin |

   Against the emulators the sign-in screen also shows **Continue with email** for these. Dev and prod builds offer only Google and Apple there, and email sign-in is at `/emaillogin` (SPEC AUTH-1, AUTH-2).

3. **Run the app** with the emulator flag. In VS Code pick **Dev (emulators)** or **Web (Chrome, emulators)**, or:

   ```sh
   flutter run -d chrome -t lib/main_dev.dart --dart-define=USE_EMULATORS=true
   flutter run -d <iphone-simulator> --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATORS=true
   flutter run -d <android-device> --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATORS=true
   ```

   The Android emulator reaches your Mac at `10.0.2.2` automatically. For a real phone on your Wi-Fi, add `--dart-define=EMULATOR_HOST=<your Mac's IP>`, and set each emulator's `"host": "0.0.0.0"` in `firebase.json` locally (don't commit that).

Dev builds show a small **EMU** (emulators) or **DEV** ribbon in the corner. Prod builds show nothing.

## Flavors

| | Dev | Prod |
|---|---|---|
| App ID | `app.getbattleplan.dev` ("Battleplan Dev") | `app.getbattleplan` ("Battleplan") |
| Entry point | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Android | `--flavor dev` | `--flavor prod` |
| iOS | Xcode scheme `dev` (configs `Debug-dev`, `Release-dev`, `Profile-dev`) | scheme `prod` |
| Firebase | `battleplan-dev-ecce4`, or the emulators with `USE_EMULATORS=true` | `battleplan-prod`; never the emulators |

The two can be installed side by side. Plain `flutter run` with no flavor uses dev.

## The cloud projects

`lib/app/firebase_options_dev.dart` and `firebase_options_prod.dart` hold the Firebase config for `battleplan-dev-ecce4` and `battleplan-prod` (registered with `firebase apps:create`). The config isn't secret and is committed (TODO.md, "Where keys and secrets go"). Run without `USE_EMULATORS` to use the dev project:

```sh
flutter run -d chrome -t lib/main_dev.dart
```

Sign-in on the dev project works once Authentication is turned on in the Firebase console.

Photos load in the browser only from origins the Storage bucket allows (CORS). `tools/storage-cors.json` lists them, including `http://localhost:5055`, so run the web app on that port (`--web-port 5055`) against the dev project. After changing the list:

```sh
gcloud storage buckets update gs://battleplan-dev-ecce4.firebasestorage.app --cors-file=tools/storage-cors.json
```

**One-time permission per project:** Storage rules check team membership in Firestore, which needs the Storage service agent to hold `roles/firebaserules.firestoreServiceAgent` (the Firebase console offers this on the Storage rules page). Without it, team logos and chat photos fail with "permission denied".

## Deploying to dev

Every push to `main` deploys Firestore rules, indexes, and the web app to `battleplan-dev-ecce4` through GitHub Actions. For everything, Functions and Storage rules included, run **Release to dev** from the Actions tab (`.github/workflows/release-dev.yml`). It waits for CI to pass on the commit (or skips that with `skip_ci_check`), builds the site and the app for dev, and deploys rules, indexes, Storage rules, Functions, and Hosting, in that order. It can run on a branch too.

From your Mac instead:

```sh
npm --prefix functions run build
firebase deploy --only functions,storage --project battleplan-dev-ecce4
```

## Releasing to prod

Prod (`battleplan-prod`) serves the website and the web app at `getbattleplan.app` (Phase 1). Nothing deploys there automatically.

1. **Once:** after the project is on Blaze, run `tools/setup_prod.sh`. It creates the Firestore database in `us-central1` with point-in-time recovery and daily backups kept 7 days, the TTL policies, the Storage bucket, the Resend key (copied from dev's Secret Manager), the function-image cleanup policy, the sign-in providers and authorized domains, and the custom domains, and prints the DNS records to add in Cloudflare (DNS only).
2. **Once per project, outside GitHub:** `tools/setup_github_deploys.sh dev` and `tools/setup_github_deploys.sh prod`, run as the projects' owner (Claude runs them from the owner's Mac). They give each project's `github-deployer` service account what a release needs and let GitHub Actions use it without a key (Workload Identity Federation). Prod accepts only **Release to prod**, started by hand on `main`. This can't be a workflow: GitHub can't give itself access to Google. The workflows name the provider and the account themselves, so there's nothing to copy into GitHub.
3. **Each release:** push main, then run **Release to prod** from the Actions tab (`.github/workflows/release-prod.yml`). Starting it is the approval. It waits for CI to pass on the commit (`skip_ci_check` skips that, say for a fix during an outage), refuses anything but `main`, builds the site and the app for prod, and deploys rules, indexes, Storage rules, Functions (retrying if Google's quota trips), and Hosting, in that order. Once App Check has a reCAPTCHA site key, add it in GitHub (Settings → Secrets and variables → Actions → Variables) as `APP_CHECK_WEB_KEY_PROD`, and `APP_CHECK_WEB_KEY_DEV` for dev; it isn't a secret.

   From your Mac instead, `tools/release_prod.sh` does the same checks and deploys.
4. **Once, after your first sign-in on prod:** `npm --prefix tools/seed run super-admin -- battleplan-prod <your email>`.

## iPhone and iPad builds

**Release iOS** in the Actions tab (`.github/workflows/release-ios.yml`) builds the prod app (`app.getbattleplan`) on GitHub's macOS machines and uploads it to App Store Connect, where it shows in TestFlight once Apple has processed it. Start it on `main`; it waits for CI on the commit (`skip_ci_check` skips that) before it starts the macOS machine, whose minutes count 10 times against the repository's Actions minutes. The build number is the commit count, as on the web.

Signing is automatic: `xcodebuild` signs in to App Store Connect with the API key in the repository's secrets, `APP_STORE_CONNECT_PRIVATE_KEY` (the `.p8` file's contents), `APP_STORE_CONNECT_KEY_ID`, and `APP_STORE_CONNECT_ISSUER_ID` (a Team key with the Admin role, kept in 1Password), and makes or reuses the distribution certificate and profile for team `885XHF7XLL`. Nothing else is stored. `ios/ExportOptions-AppStore.plist` says how the archive is exported: for the App Store, uploaded, with symbols, keeping the build number.

To check a build on your Mac without signing: `flutter build ios --release --flavor prod -t lib/main_prod.dart --no-codesign`.

## Android builds

Android builds run only in GitHub Actions, never on a Mac (no Java or Gradle locally). **Android build** in the Actions tab takes the app (dev or prod) and makes an App Bundle for Google Play and an APK to install, both signed with the Play upload key, with its SHA-1 and SHA-256 in the run's summary (Firebase needs them for Google sign-in). Download them from the run's Artifacts. The build number is the commit count, as on the web.

The upload key lives in the repository's secrets: `ANDROID_UPLOAD_KEYSTORE_BASE64` (a PKCS #12 keystore), `ANDROID_UPLOAD_KEYSTORE_PASSWORD` (the keystore's and the key's), and `ANDROID_UPLOAD_KEY_ALIAS`. `android/app/build.gradle.kts` signs release builds with it when the workflow provides it, and with the debug key otherwise; the workflow refuses a prod build without it. Keep the keystore and password in 1Password too (ROADMAP task 126). If it's lost, Google Play can reset the upload key, since Google holds the app signing key (Play App Signing).

## End-to-end test

`integration_test/e2e_test.dart` runs the real app against the emulators (store checklist 1.13): the seeded coach opens a team's invite code, then a new parent signs up with email, finishes setup, joins with the code, chats, posts a photo, and answers an RSVP. On an iPad it turns to landscape and back. Any error fails it. Google sign-up needs a real Google account and the system photo picker can't be tapped by a test, so those are checked by hand; a stand-in picker hands the app one photo, which uploads and posts like any other.

With the emulators running and the seed loaded (steps 1 and 2 above):

```sh
flutter test integration_test/e2e_test.dart -d <iPhone or iPad simulator> \
  --flavor dev --dart-define=USE_EMULATORS=true
```

On Android, tick **End-to-end test APK** in **Android build**, install the `-e2e.apk` on an Android emulator (`adb install`), and open it: the test runs as the app starts, against the emulators on this Mac at `10.0.2.2`, and prints its result to `adb logcat` under `flutter`.

## App Check

App Check proves requests come from the real apps (ARCH §6.9). It runs in **monitor mode** until the console shows nearly all traffic verified, then it's enforced on Functions, Firestore, and Storage.

**The app** (`lib/app/app_check.dart`, started in `bootstrap.dart` right after `Firebase.initializeApp`, with token auto-refresh on):

| Build | Provider |
|---|---|
| Emulators (`USE_EMULATORS=true`) | None. The `demo-` project has no App Check backend, and the emulators don't check tokens. |
| Dev on a phone or simulator | Debug provider. Pass `--dart-define=APP_CHECK_DEBUG_TOKEN=<token>` to use a registered token (CI); without it the SDK makes one up and prints it in the native log (Xcode console or `adb logcat`, "debug token" / "debug secret"). |
| Prod on Android / iOS | Play Integrity / App Attest, falling back to DeviceCheck before iOS 14. Never the debug provider. |
| Web | reCAPTCHA Enterprise with `--dart-define=APP_CHECK_WEB_KEY=<site key>`. A dev web build can take `APP_CHECK_DEBUG_TOKEN` instead (generate one under Manage debug tokens). Without either, App Check is off on that build and the startup log says so; it never crashes. |

The web SDK remembers the last provider in the browser's local storage and reuses it on the next load, so after switching keys clear the site data.

**Functions** (`functions/src/shared/callable.ts`): every callable imports `onCall` from there, which sets `enforceAppCheck` from one switch (a unit test fails if a handler imports firebase-functions' `onCall` directly). `getInvitePreview` and `logClientError` still need no sign-in; once enforced, they need an App Check token like every other callable. In monitor mode a request without a valid token still runs, and each call logs `Callable request verification` with `verifications.app` = `VALID`, `MISSING`, or `INVALID`.

**The one-line switch:** in `functions/src/shared/callable.ts`, change

```ts
const enforceAppCheckByDefault = false;
```

to `true`, then deploy Functions. To enforce on one project first, put `ENFORCE_APP_CHECK=true` in `functions/.env.<project id>` (git-ignored, so on the machine that deploys) instead; `false` there turns it back off for that project.

**Console steps, per project** (`battleplan-dev-ecce4` first, then `battleplan-prod`):

1. **Register the apps** in Firebase console → App Check → Apps:
   - Android (`app.getbattleplan.dev`, `app.getbattleplan`): Play Integrity. Add the SHA-256 of the upload key and the Play app signing key in Project settings, and link the Play Console app to the Cloud project (Play Console → App integrity).
   - iOS: App Attest (and DeviceCheck for the fallback). Needs the Team ID. Turn on the App Attest capability for `app.getbattleplan` in the Apple Developer portal; the prod configs already sign with `ios/Runner/RunnerProd.entitlements` (`appattest-environment` = `production`). DeviceCheck needs a DeviceCheck key (.p8) uploaded.
   - Web: create a reCAPTCHA Enterprise key (Google Cloud console → Security → reCAPTCHA, type Website, domains `getbattleplan.app`, `battleplan-dev-ecce4.web.app`, the preview-channel domain, and `localhost`), register it as the web app's provider, and build with `--dart-define=APP_CHECK_WEB_KEY=<site key>`. The key isn't secret; it goes in the build script or CI variables.
2. **Debug tokens** (Apps → ⋮ → Manage debug tokens), dev project only: one per developer machine or simulator (copy it from the native log or browser console on first run), and one for CI, stored as a GitHub secret and passed as `--dart-define=APP_CHECK_DEBUG_TOKEN=${{ secrets.APP_CHECK_DEBUG_TOKEN }}`. Never register debug tokens on prod. The emulator runs need none.
3. **Monitor**: App Check → APIs shows verified, unverified-outdated, and unverified-invalid requests for Firestore and Storage. For Functions, filter Logs Explorer on `jsonPayload.message="Callable request verification passed"` or `"…failed"` and compare `jsonPayload.verifications.app`. Wait until old app versions without App Check have mostly updated (Remote Config `min_supported_version` can force it).
4. **Enforce**: flip the switch above and deploy Functions, then App Check → APIs → **Enforce** for Cloud Firestore and Cloud Storage. Enforcement takes up to 15 minutes. To back out, unenforce in the console and set the switch to `false`.

## Super admins

Grant the `superAdmin` claim to someone who has signed in at least once:

```sh
npm --prefix tools/seed run super-admin -- battleplan-dev-ecce4 someone@example.com
npm --prefix tools/seed run super-admin -- battleplan-dev-ecce4 someone@example.com --revoke
```

## App Review demo account

App Review needs a demo account with a seeded team (SPEC §10). `tools/seed/demo.ts` makes one on the **dev** project (`--write-to-dev`), on **prod** (`--project battleplan-prod --write-to-prod`; App Review uses prod, since Release iOS builds point there), or on the emulators, and refuses every other project. It uses your gcloud sign-in (`gcloud auth application-default login`, then `gcloud auth application-default set-quota-project battleplan-dev-ecce4`), so there's no key file:

```sh
DEMO_PASSWORD='<at least 12 characters>' npm --prefix tools/seed run demo -- \
  --project battleplan-dev-ecce4 --write-to-dev
```

It creates or updates `appreview@getbattleplan.app` (or `DEMO_EMAIL`), which owns *Thunder*, a team of adult players with one player linked to its own member and a pending player to approve, and is a parent on the kids' team *Cyclone*, with messages, events, RSVPs, and a pinned link. Running it again resets the password and rewrites the same `demo-` documents. Put the email and password in the App Review notes, never in the repo, with where to sign in: the sign-in screen offers only Google and Apple (SPEC AUTH-1), so the demo account signs in at `getbattleplan.app/emaillogin` (on dev, `battleplan-dev-ecce4.web.app/emaillogin`). To try it locally, start the emulators and run `npm --prefix tools/seed run demo:emulators`. The prod demo account was made this way on 2026-10-17; its team's invite code is in docs/STORE-LISTING.md.

## App icons and splash screens

The icons and splash screens come from the brand mark (SPEC §7.1) in `assets/brand/*.svg` and `website/favicon.svg`, on `#2F5BEA`; the sign-in screen draws the same shapes in `lib/core/widgets/brand_mark.dart`, and `web/index.html`'s loading screen inlines the favicon. After changing the mark, change all of them, run `tools/brand_icons.sh` (it needs Google Chrome to render the SVGs, and macOS's `sips` to size the web icons) and commit what it writes under `assets/brand/`, `android/`, `ios/`, `web/`, and `website/`.

## Everyday commands

| What | Command |
|---|---|
| Regenerate code after editing a model or provider | `dart run build_runner build` (or the **Code generation (watch)** task) |
| Regenerate shared constants after editing `shared/constants.json` | `dart run tools/gen_constants.dart` |
| Strings | Edit `lib/l10n/app_en.arb`; `flutter gen-l10n` (also run by `flutter run` and `flutter build`) writes `lib/l10n/gen/`, which isn't committed |
| App tests | `flutter test` |
| App coverage (at least 80% of domain and data layers) | `flutter test --coverage && dart run tools/check_coverage.dart` |
| Lints | `flutter analyze` and `tools/check_imports.sh` |
| Functions tests | `npm --prefix functions test` |
| Security-rules tests | `npm --prefix functions run emulators:test` (starts its own emulators) |
| Functions coverage (at least 80%, all functions tests) | `npm --prefix functions run emulators:coverage` |
| Seed and demo-seed tests | `npm --prefix tools/seed test` |

CI runs all of these on every PR (`.github/workflows/ci.yml`). Generated model and provider files (`*.g.dart`, `*.freezed.dart`) and `constants.g.dart` are committed, and CI fails if they're stale.

## Where code goes

- `lib/features/<feature>/` has `domain/` (models and repository interfaces, pure Dart), `data/` (the only Firebase code), `application/` (providers and multi-repository services), and `presentation/` (screens and controllers).
- Repository providers are declared in each feature's `application/providers.dart` and wired to Firebase implementations in one place, `lib/app/providers.dart`. Tests override them with fakes (`test/helpers/fakes.dart`).
- Widgets import `package:material_ui/material_ui.dart`, Flutter's standalone Material library, not `package:flutter/material.dart`.
- Icons come from `AppIcons` (Material Symbols Rounded), spacing and sizes from `core/design/tokens.dart`, and colors from the theme or `AppColors`.
