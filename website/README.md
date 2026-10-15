# Website

The static website at the root of `getbattleplan.app` (SPEC §4.3 WEB-1 to WEB-5, ARCH §6.6, D40; ROADMAP tasks 175, 176, 179). Plain HTML and CSS: no framework, no build step, no scripts, no cookies, no analytics or third-party requests. The Flutter web app is served next to it under `/app/`.

## Files

| Path | What |
|---|---|
| `index.html` | `/`: the landing page (features, players and parents, free with no ads, screenshots, FAQ) |
| `support.html` | `/support`: support email, common questions, deleting your account |
| `privacy.html`, `terms.html` | `/privacy`, `/terms`: draft structure; final wording is ROADMAP task 121 |
| `delete-account.html` | `/delete-account`: deletion in the app and by email (LEGAL-3) |
| `404.html` | Hosting's not-found page |
| `site.css` | All styles; light and dark through `prefers-color-scheme`, brand colors from `lib/core/design` |
| `favicon.svg`, `favicon-32.png`, `apple-touch-icon.png` | Icons: the brand mark (SPEC §7.1). `favicon.svg` is also the header mark; `tools/brand_icons.sh` makes the PNGs from it and `assets/brand/icon.svg` |
| `images/*.webp` | App screenshots, light and dark, 600 px wide |
| `images/og.png` | Open Graph and Twitter card image, 1200 × 630 |
| `robots.txt`, `sitemap.xml` | The site is indexed; `/app/` is not |

Hosting serves `support.html` at `/support` because `firebase.json` sets `cleanUrls`. Links between pages use the clean paths (`/support`, not `/support.html`). Every page links to `/app/` (**Log in to Battleplan**, just **Log in** on phones) in the header and footer; the landing page's hero and closing section link to `/app/sign-up` (**Sign up, it's free!**). The site must not have an `app/` folder: `tools/build_hosting.sh` copies this folder into `build/hosting/` and builds Flutter into `build/hosting/app/`.

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

The screenshots are real captures of the web app with sample data, taken locally against the Firebase emulators (never dev or prod):

1. Start the emulators and seed them (DEVELOPMENT.md, `tools/seed`), and add any extra sample messages, polls, events, and documents you want shown.
2. `flutter build web --wasm -t lib/main_dev.dart --dart-define=USE_EMULATORS=true -o <a folder outside the repo>` and serve that folder on a local port.
3. Sign in as a seeded user in headless Chrome at 390 × 844 (device scale 2) and capture each screen with `prefers-color-scheme` set to light and then dark. Hide the "Running in emulator mode" banner, and the "EMU" corner ribbon (build from a scratch copy of the repo with `bannerLabel` in `lib/core/env.dart` returning null; never commit that change).
4. Resize to 600 px wide and save as WebP (quality about 80) under `images/` with the same names, so the pages don't change.

Regenerate `images/og.png` from the new screenshots at 1200 × 630.

## Checking it

Serve the folder with clean URLs (for example `firebase emulators:start --only hosting` after `tools/build_hosting.sh`, or any static server that maps `/support` to `support.html`), then check each page at phone and desktop widths in light and dark: no console errors, no broken links or images, no horizontal scrolling, and no axe (WCAG 2 AA) violations.
