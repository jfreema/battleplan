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

   It creates three teams (one adult, two youth), parents with players on two teams, events, RSVPs, and messages. Every password is `password`:

   | Email | Who |
   |---|---|
   | `coach@example.com` | Owner of Thunder (adult) and Lightning U10 (youth) |
   | `maria@example.com` | Parent on three teams, with players on two |
   | `priya@example.com` | Owner of Hawks U14, parent on Lightning U10 |
   | `alex@example.com`, `sam@example.com`, `luis@example.com` | Members |
   | `admin@example.com` | Super admin |

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

Every push to `main` deploys Firestore rules, indexes, and the web app to `battleplan-dev-ecce4` through GitHub Actions. Functions and Storage rules deploy from your Mac for now, because the GitHub deploy account would need more permissions for them:

```sh
npm --prefix functions run build
firebase deploy --only functions,storage --project battleplan-dev-ecce4
```

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

## Everyday commands

| What | Command |
|---|---|
| Regenerate code after editing a model or provider | `dart run build_runner build` (or the **Code generation (watch)** task) |
| Regenerate shared constants after editing `shared/constants.json` | `dart run tools/gen_constants.dart` |
| Strings | Edit `lib/l10n/app_en.arb`; `flutter gen-l10n` (also run by `flutter run` and `flutter build`) writes `lib/l10n/gen/`, which isn't committed |
| App tests | `flutter test` |
| Lints | `flutter analyze` and `tools/check_imports.sh` |
| Functions tests | `npm --prefix functions test` |
| Security-rules tests | `npm --prefix functions run emulators:test` (starts its own emulators) |

CI runs all of these on every PR (`.github/workflows/ci.yml`). Generated model and provider files (`*.g.dart`, `*.freezed.dart`) and `constants.g.dart` are committed, and CI fails if they're stale.

## Where code goes

- `lib/features/<feature>/` has `domain/` (models and repository interfaces, pure Dart), `data/` (the only Firebase code), `application/` (providers and multi-repository services), and `presentation/` (screens and controllers).
- Repository providers are declared in each feature's `application/providers.dart` and wired to Firebase implementations in one place, `lib/app/providers.dart`. Tests override them with fakes (`test/helpers/fakes.dart`).
- Widgets import `package:material_ui/material_ui.dart`, Flutter's standalone Material library, not `package:flutter/material.dart`.
- Icons come from `AppIcons` (Material Symbols Rounded), spacing and sizes from `core/design/tokens.dart`, and colors from the theme or `AppColors`.
