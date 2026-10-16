# Website

The static website at the root of `getbattleplan.app` (SPEC §4.3 WEB-1 to WEB-5, ARCH §6.6, D40; ROADMAP tasks 175, 176, 179). Plain HTML and CSS: no framework, no build step, no scripts, no cookies, no analytics or third-party requests. The Flutter web app is served next to it under `/app/`.

## Files

| Path | What |
|---|---|
| `index.html` | `/`: the landing page (features, players and parents, the coach's whiteboard, switching from other apps, free with no ads, screenshots, FAQ) |
| `support.html` | `/support`: support email, common questions, deleting your account |
| `privacy.html`, `terms.html` | `/privacy`, `/terms`: draft structure; final wording is ROADMAP task 121 |
| `delete-account.html` | `/delete-account`: deletion in the app and by email (LEGAL-3) |
| `404.html` | Hosting's not-found page |
| `site.css` | All styles; light and dark through `prefers-color-scheme`, brand colors from `lib/core/design` |
| `favicon.svg`, `favicon-32.png`, `apple-touch-icon.png` | Icons: the brand mark (SPEC §7.1). `favicon.svg` is also the header mark; `tools/brand_icons.sh` makes the PNGs from it and `assets/brand/icon.svg` |
| `images/*.webp` | App screenshots, light and dark, 600 px wide |
| `images/og.png` | Open Graph and Twitter card image, 1200 × 630 |
| `robots.txt`, `sitemap.xml` | The site is indexed; `/app/` is not |

Hosting serves `support.html` at `/support` because `firebase.json` sets `cleanUrls`. Links between pages use the clean paths (`/support`, not `/support.html`). Every page links to `/app/` (**Login**) in the header and footer; the landing page's hero and closing section link to `/app/sign-up` (**Get Started**). The site must not have an `app/` folder: `tools/build_hosting.sh` copies this folder into `build/hosting/` and builds Flutter into `build/hosting/app/`.

## Editing

- Each page carries its own header and footer. When you change the nav or footer, change it in all six HTML files.
- Keep the page `<title>`, `description`, `og:*`, and `twitter:*` tags in step when you change a page's purpose.
- Images: give every `<img>` a `width`, `height`, and real `alt` text (or `alt=""` when decorative). Use `<picture>` with a `prefers-color-scheme: dark` source for screenshots. Keep `images/` under about 2 MB.
- Text and UI paths should match the app's English strings (`lib/l10n/app_en.arb`), for example **Settings** → **Delete account**.

## Store badges

The App Store and Google Play badges wait for the listings (ROADMAP tasks 130 and 179). They're already in `index.html` (hero) and `support.html` (Getting the app) inside a `<template data-store-badges>`, which the browser never renders or loads. When the apps are listed:

1. Add the official badge artwork to `images/` (`app-store-badge.svg`, `google-play-badge.png`) following Apple's and Google's badge guidelines.
2. Replace `APP_STORE_ID` in the App Store URL, and check the Play package (`app.getbattleplan`). Point the `/ios` redirect in `firebase.json` at the same App Store URL: the web app's iPhone notification tip links there (NOTIF-9), and until then it lands on the home page.
3. Remove the `<template>` wrapper around the `store-badges` div in both files.
4. Update the copy that says the apps are "on the way" (landing page card, support page).

## Screenshots

The screenshots are real captures of the web app with the seeded sample teams (Thunder, Cyclone, and Rally Possums, in navy and orange, Carolina blue and gray, and purple and gold) and people (common American names and TV characters), taken locally against the Firebase emulators (never dev or prod). Each one shows a different screen:

| Image | Signed in as | Screen |
|---|---|---|
| `chat` (hero) | `coach@example.com` | Thunder's chat, opened at the first unread message: the announcement, Jim's mention, the game card, the dinner poll |
| `teams` (hero, behind) | `claire@example.com` | The team switcher over Rally Possums' chat |
| `conversation` | `coach@example.com` | Cyclone's chat: a reply, a mention, reactions |
| `event`, `schedule` | `coach@example.com` | Thunder's game against the Eagles, and Thunder's schedule |
| `poll` | `rachel@example.com` | Rally Possums' tournament poll |
| `documents` | `coach@example.com` | Thunder's documents |
| `youth` | `claire@example.com` | Cyclone's practice, answering for Luke and Alex |
| `whiteboard` | `coach@example.com` | Cyclone: **Plays** → More → **Saved plays** → **Double cut to home** → More → **Put on the whiteboard** → **Next step** (step 2 of 2, the relay lined up) |
| `whiteboard-basketball` | `coach@example.com` | Thunder: **Plays** → More → **Saved plays** → **Pick and roll** → More → **Put on the whiteboard**, in a new sign-in, so Cyclone's whiteboard doesn't carry over |

1. Start the emulators **without functions** (`firebase emulators:start --only auth,firestore,storage`), so the seeded events don't post cards to the chats or send notifications. Then seed them (DEVELOPMENT.md, `npm --prefix tools/seed run seed`). Seed again before each run: opening a chat marks it read.
2. Build from a scratch copy of the repo with `bannerLabel` in `lib/core/env.dart` returning null, so there's no "EMU" corner ribbon (never commit that change): `flutter build web --wasm -t lib/main_dev.dart --dart-define=USE_EMULATORS=true -o <a folder outside the repo>`. Serve that folder on a local port.
3. In headless Chrome at 390 × 844 with a device scale of 600 / 390 (so captures come out 600 px wide), hide the "Running in emulator mode" banner (`.firebase-emulator-warning`), sign in, and open each screen. Move the mouse off the page and blur the focused field before each capture, so no row shows a hover or focus.
4. Capture each screen with `prefers-color-scheme` set to light and then dark, and save as WebP (quality about 80) under `images/` as `<name>-light.webp` and `<name>-dark.webp`.

Regenerate `images/og.png` at 1200 × 630 from the new `chat` and `schedule` shots, keeping its layout: the brand mark and copy on the left, the chat in front of the schedule on the right.

## Checking it

Serve the folder with clean URLs (for example `firebase emulators:start --only hosting` after `tools/build_hosting.sh`, or any static server that maps `/support` to `support.html`), then check each page at phone and desktop widths in light and dark: no console errors, no broken links or images, no horizontal scrolling, and no axe (WCAG 2 AA) violations.
