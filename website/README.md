# Website

The static website at the root of `getbattleplan.app` (SPEC §4.3 WEB-1 to WEB-5, ARCH §6.6, D40; ROADMAP tasks 175, 176, 179). Plain HTML and CSS: no framework, no build step, no cookies, no analytics or third-party requests. The one script, inline at the end of `index.html`, gives the Plays slider its dots; without it the slider still swipes. The Flutter web app is served next to it under `/app/`.

## Files

| Path | What |
|---|---|
| `index.html` | `/`: the landing page (features, players and parents, the coach's whiteboard, switching from other apps, free with no ads, screenshots, FAQ) |
| `switch.html` | `/switch`: switching from GroupMe, TeamSnap, TeamReach, GameChanger, or Google Calendar, the steps for each (the landing page's Switching section and FAQ link here). Other apps appear by name in a neutral badge, never their logos |
| `support.html` | `/support`: support email, common questions, deleting your account |
| `privacy.html`, `terms.html` | `/privacy`, `/terms`: the Privacy Policy and Terms of Use, in effect since 2026-10-13 (LEGAL-1, ROADMAP task 121) |
| `delete-account.html` | `/delete-account`: deletion in the app and by email (LEGAL-3) |
| `404.html` | Hosting's not-found page |
| `site.css` | All styles, in one theme: Gumdrop Army, the app's default (an army-green page with cream text, cream cards with ink text, gumdrop buttons outlined in ink on a hard ink lip, coral accents, and cream Lilita One headings outlined in ink over a stacked ink shadow; headings on the cream cards are plain ink, with no shadow). No light theme and no `prefers-color-scheme` switch |
| `fonts/` | Lilita One (headings), Fredoka (buttons, labels, questions), Nunito (body), and Black Ops One (the coral sticker, capitals only) as Latin `woff2` files from Google Fonts, served from this site so it makes no third-party requests, with each font's `*-OFL.txt` license. Fredoka and Nunito are variable fonts (one file covers every weight) |
| `favicon.svg`, `favicon-32.png`, `apple-touch-icon.png` | Icons: the brand mark (SPEC §7.1). `favicon.svg` is also the header mark; `tools/brand_icons.sh` makes the PNGs from it and `assets/brand/icon.svg` |
| `images/*-dark.webp` | App screenshots in Gumdrop Pop Dark with the teams' color set to Black, 600 × 1298 |
| `images/og.png` | Open Graph and Twitter card image, 1200 × 630 |
| `robots.txt`, `sitemap.xml` | The site is indexed; `/app/` is not |

Hosting serves `support.html` at `/support` because `firebase.json` sets `cleanUrls`. Links between pages use the clean paths (`/support`, not `/support.html`). Every page links to `/app/` (**Login**) in the header and footer; the landing page's hero and closing section link to `/app/sign-up` (**Get Started**). The site must not have an `app/` folder: `tools/build_hosting.sh` copies this folder into `build/hosting/` and builds Flutter into `build/hosting/app/`.

## Editing

- Fonts: use the `--display` (Lilita One), `--label` (Fredoka), and `--body` (Nunito) stacks in `site.css`. Don't link Google Fonts or any other CDN: a new weight or font goes in `fonts/` with its license.
- Colors: use the tokens on `:root` in `site.css` (the app's Gumdrop Army colors): `--text` and `--muted` on the olive page, `--card-text`, `--card-muted`, and `--card-link` on cream cards. Text needs 4.5:1 contrast on its background; the coral is for faces with ink on them, never for text on the page.
- Each page carries its own header and footer. When you change the nav or footer, change it in all six HTML files.
- Keep the page `<title>`, `description`, `og:*`, and `twitter:*` tags in step when you change a page's purpose.
- Images: give every `<img>` a `width`, `height`, and real `alt` text (or `alt=""` when decorative). Screenshots use the `-dark` capture, on black: only screens inside a team take its color, so a top-level screen (Teams, Profile) would show Dark's navy. Keep `images/` under about 2 MB.
- Text and UI paths should match the app's English strings (`lib/l10n/app_en.arb`), for example **Settings** → **Delete account**.
- On the landing page, say **players** and **guardians**: never kids, children, or parents (the owner's rule, 2026-10-16). Accounts are for adults; players who don't use the app are roster entries their guardians answer for.
- A pair of phones (`feature-media pair`) shows both side by side from 1100 px and only the first below that. Add `slider`, with the phones in a `slides` div and a `slider-dots` div after it, as the Plays pair has, to let narrower screens swipe between them.

## Store badges

The App Store and Google Play badges wait for the listings (ROADMAP tasks 130 and 179). They're already in `index.html` (hero) and `support.html` (Getting the app) inside a `<template data-store-badges>`, which the browser never renders or loads. When the apps are listed:

1. Add the official badge artwork to `images/` (`app-store-badge.svg`, `google-play-badge.png`) following Apple's and Google's badge guidelines.
2. Replace `APP_STORE_ID` in the App Store URL, and check the Play package (`app.getbattleplan`). Point the `/ios` redirect in `firebase.json` at the same App Store URL: the web app's iPhone notification tip links there (NOTIF-9), and until then it lands on the home page.
3. Remove the `<template>` wrapper around the `store-badges` div in both files.
4. Update the copy that says the apps are "on the way" (landing page card, support page).

## Screenshots

The screenshots show the app with the seeded sample teams (Thunder, Cyclone, and Rally Possums, in navy, Carolina blue, and purple) and people (common American names and TV characters), the same data `tools/seed/seed.ts` loads into the emulators. Each one shows a different screen:

| Image | Signed in as | Screen |
|---|---|---|
| `chat` (hero) | `coach@example.com` | Thunder's chat, opened at the first unread message: the announcement, Jim's mention, the game card, the dinner poll |
| `allteams` (hero, behind) | `claire@example.com` | Cyclone's schedule with **All my teams** on: her three teams' events together, answering for Luke and Alex |
| `conversation` | `coach@example.com` | Cyclone's chat: a reply, a mention, reactions |
| `event`, `schedule` | `coach@example.com` | Thunder's game against the Eagles, and Thunder's schedule |
| `poll` | `rachel@example.com` | Rally Possums' tournament poll |
| `documents` | `coach@example.com` | Thunder's documents |
| `youth` | `claire@example.com` | Cyclone's practice, answering for Luke and Alex |
| `whiteboard` | `coach@example.com` | Cyclone's whiteboard with **Relay home from right-center** on it, at **Next step** (step 2 of 2, the throws: RF to 2B, the relay, to 1B, the cutoff) |
| `whiteboard-basketball` | `coach@example.com` | Thunder's whiteboard with **Pick and roll** on it (step 1 of 2) |

The current set (Gumdrop Pop Dark on black, 2026-10-29, the owner's request) are captures of the real web app against the emulators: start them, seed them (DEVELOPMENT.md), set `themeMode` to `dark` on `users/coach`, `users/claire`, and `users/rachel` and `color` to `#111111` (Black) on `groups/thunder`, `groups/cyclone`, and `groups/possums` (the emulator's REST API with `Authorization: Bearer owner`), and build from a scratch copy with `bannerLabel` in `lib/core/env.dart` returning null (never commit that), with `flutter build web -t lib/main_dev.dart --dart-define=USE_EMULATORS=true --no-web-resources-cdn --base-href /app/` (CanvasKit: headless Chrome doesn't paint the wasm build), plus `tools/fetch_fallback_fonts.dart` into its `fonts/fallback/` for the emoji. Serve it under `/app/` and drive headless Chrome at 390 × 844 with a device scale of 600 / 390: hide `.firebase-emulator-warning`, sign in with the keyboard alone (Tab to Email and to Password, typing in each, then Sign in through the semantics tree: Flutter keeps a mouse's hover where it last clicked, which lights up whatever later sits there), open each screen by its route (`history.pushState` and a `popstate` event, since a reload signs out), and press buttons through the semantics tree (clicking a `flt-semantics[role=button]` element), since synthetic mouse clicks don't reach some of them. Take Thunder's chat first after seeding, so it opens at the first unread message. Then convert each PNG to WebP at quality 80 (headless Chrome's `canvas.toDataURL('image/webp', 0.8)` works where `cwebp` isn't installed) as `images/<name>-dark.webp`.

Regenerate `images/og.png` at 1200 × 630 from the new `chat` and `schedule` shots, keeping its layout: the brand mark, the coral sticker (in Black Ops One), and the heading and copy on the left, the chat in front of the schedule on the right. It's a plain HTML page using `fonts/` and the two PNG captures, screenshotted in headless Chrome at 1200 × 630.

## Checking it

Serve the folder with clean URLs (for example `firebase emulators:start --only hosting` after `tools/build_hosting.sh`, or any static server that maps `/support` to `support.html`), then check each page at phone (down to 320 px) and desktop widths: no console errors, no broken links or images, no horizontal scrolling, and no axe (WCAG 2 AA) violations.
