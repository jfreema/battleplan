# Website

The static website at the root of `getbattleplan.app` (SPEC §4.3 WEB-1 to WEB-5, ARCH §6.6, D40; ROADMAP tasks 175, 176, 179, 351). Plain HTML and CSS: no framework, no build step, no cookies, no analytics or third-party requests. The landing page's color scheme picker is pure CSS; its one inline script only sets the browser's `theme-color` to match, and the page works the same without it. The Flutter web app is served next to it under `/app/`.

## Files

| Path | What |
|---|---|
| `index.html` | `/`: the landing page (below) |
| `switch.html` | `/switch`: switching from GroupMe, TeamSnap, TeamReach, GameChanger, or Google Calendar, the steps for each (the landing page's Switching section and FAQ link here). Other apps appear by name in a neutral badge, never their logos |
| `support.html` | `/support`: support email, common questions, deleting your account |
| `privacy.html`, `terms.html` | `/privacy`, `/terms`: the Privacy Policy and Terms of Use, in effect since 2026-10-13 and last changed 2026-11-06, for dues (LEGAL-1, ROADMAP task 121). When the app starts collecting something new, change the policy, `docs/STORE-PRIVACY.md`, and the iPhone app's privacy manifest together |
| `delete-account.html` | `/delete-account`: deletion in the app and by email (LEGAL-3) |
| `404.html` | Hosting's not-found page |
| `site.css` | All styles, in the app's Open Field look (below) |
| `fonts/` | Lilita One (titles), Fredoka (buttons, labels, chips, questions), Nunito (body), and Black Ops One (the stencil eyebrows, capitals only) as Latin `woff2` files from Google Fonts, served from this site so it makes no third-party requests, with each font's `*-OFL.txt` license. Fredoka and Nunito are variable fonts (one file covers every weight) |
| `favicon.svg`, `favicon-small.svg`, `favicon-32.png`, `apple-touch-icon.png` | Icons: the brand mark, the Stencil Crest (SPEC §7.1). `favicon-small.svg` is the browser-tab icon, drawn on the 16 px grid, which every page links as `rel=icon`; `favicon.svg` is the header mark; `tools/brand_icons.sh` makes the PNGs from it and `assets/brand/icon.svg` |
| `images/*.webp` | App screenshots in Open Field, 600 × 1298, each named for its screen and color scheme (Screenshots, below) |
| `images/app-store-badge.svg` | Apple's official black **Download on the App Store** badge (US English), exactly as Apple's marketing tools supply it (The App Store and Google Play, below) |
| `images/og.jpg` | Open Graph and Twitter card image, 1200 × 630, a JPEG under 300 KB so messaging apps show it (the invite links' preview uses it too). `firebase.json` redirects the old `og.png` here |
| `robots.txt` | Everything may be crawled, and AI crawlers (GPTBot, ClaudeBot, PerplexityBot, Google-Extended, and others) are welcomed by name. `/app/` stays crawlable so crawlers see its `noindex` |
| `sitemap.xml` | The six pages, each with its `lastmod`: the date the page's text last changed. Change it with the text, not for edits to the `<head>` alone |
| `llms.txt` | A short Markdown summary of Battleplan for language models ([llms.txt](https://llmstxt.org/)): what it is, features, pricing, platforms, privacy, and the key links. Hosting serves it as `text/plain`. Keep it in step with the landing page |

Hosting serves `support.html` at `/support` because `firebase.json` sets `cleanUrls`. Links between pages use the clean paths (`/support`, not `/support.html`). Every page links to `/app/` (**Login**) in the header and footer; the landing page's hero and closing section link to `/app/sign-up` (**Get Started**). The site must not have an `app/` folder: `tools/build_hosting.sh` copies this folder (`llms.txt` and all) into `build/hosting/` and builds Flutter into `build/hosting/app/`.

## The landing page

Short on words: a headline, one line under it, and feature tiles with a two-to-four-word title and one short sentence. In order:

1. **Hero:** "For Groups and Sports Teams" over "Every team needs a Battleplan.", **Get Started** and **Login**, the App Store badge, and the color scheme picker: Thunder's schedule on five phones, one per scheme, in a fan. Picking a scheme's chip (Army green, Light, Dark, Navy, Light blue, the app's names) brings its phone to the front and re-colors the whole page in that scheme. Phones narrower than 600 px show the front phone and its two neighbors.
2. **Features** (`#features`), "Built for game day.": tiles for Group chat, Games and RSVPs, Polls, Documents, and All my teams, each with a phone rising out of it, and an And more tile of chips.
3. **Dues** (`#dues`), "Dues, sorted.": the admin's view and What you owe, side by side.
4. **Players and guardians** (`#players`), "Players first."
5. **The coach's whiteboard** (`#whiteboard`).
6. **Switching** (`#switch`), "Switching is easy.": the five apps, linking to `/switch`.
7. **Free** (`#free`), "Free. No ads. No catch.": a scoreboard of three big numbers.
8. **FAQ** (`#faq`): eight short questions. The `FAQPage` in the page's JSON-LD repeats each question and answer word for word: change both together.
9. **Closing call to action**, then **Donate to Support This Project** (WEB-1).

The `<head>` has the title, description, canonical link, Open Graph and Twitter tags, and one JSON-LD `@graph`: `Organization`, `WebSite`, `SoftwareApplication` (`SportsApplication`, "iOS, iPadOS, Web", the App Store listing as its `downloadUrl`, free), and `FAQPage`.

## The look

`site.css` follows the app's Open Field (SPEC §7.4): Lilita One titles on a hard drop in the scheme's `title-drop`, Black Ops One eyebrows in `accent-text`, cards in the scheme's `card` with a 2 px rim and a 4 px lip (the event cards), a 6 px candy edge on feature tiles, coral candy buttons on a lip, and pill chips. Army green is the default and the only scheme on the other pages.

- **Colors:** use the role tokens on `:root` (`--page`, `--band`, `--text`, `--muted`, `--card`, `--rim`, `--card-muted`, `--drop`, `--accent`, `--going`, `--maybe`, and the rest), never a literal color. They're the app's roles from `lib/core/design/schemes.dart`; `:root:has(#s-light:checked)` and the other three re-define them for the picker. Text on `--page` or `--band` uses `--text`, `--muted`, or the page roles (`--accent`, `--going`, `--maybe`); text on `--card` uses `--text` or `--card-muted`. Each pair is 4.5:1 or more in every scheme. Candy faces (`--coral`, `--mint`, …) are the same in every scheme and carry ink (`--ink`) on them.
- **The picker:** five radio buttons (`.scheme-input`, visually hidden) come first in the `fieldset`, so plain sibling selectors place the phones (`--d`, `-2` to `2`, from the checked one) and mark the chips, and focus shows on the chip. The page colors use `:has()`; a browser without it still turns the fan.
- **Tags:** a chip on each screenshot names its scheme, in that scheme's own colors (`.tag[data-s="navy"]`).
- **Every device:** `viewport-fit=cover` with `env(safe-area-inset-*)` padding on the header, page edges, and footer; tap targets 44 px or more; no horizontal scrolling down to 320 px (the hero and the spotlights clip their overflow); motion off under `prefers-reduced-motion`.

## Editing

- Fonts: use the `--display` (Lilita One), `--stencil` (Black Ops One), `--label` (Fredoka), and `--body` (Nunito) stacks in `site.css`. Don't link Google Fonts or any other CDN: a new weight or font goes in `fonts/` with its license. Black Ops One has capitals only and no middle dot.
- Each page carries its own header and footer. When you change the nav or footer, change it in all six HTML files.
- Keep the page `<title>`, `description`, `og:*`, and `twitter:*` tags in step when you change a page's purpose, and the JSON-LD and `llms.txt` in step with the landing page.
- Images: give every `<img>` a `width`, `height`, and real `alt` text naming the screen and its scheme (or `alt=""` when decorative). Below the hero, `loading="lazy"`; the hero's Army green phone loads first with `fetchpriority="high"`. Keep `images/` under about 2 MB.
- Text and UI paths should match the app's English strings (`lib/l10n/app_en.arb`), for example **Settings** → **Delete account**, and the schemes' names.
- On the landing page, say **players** and **guardians**: never kids, children, or parents (the owner's rule, 2026-10-16). Accounts are for adults; players who don't use the app are roster entries their guardians answer for.

## The App Store and Google Play

The iPhone and iPad app is on the App Store at `https://apps.apple.com/app/id6823884728` (Apple ID 6823884728, bundle `app.getbattleplan`). The landing page's hero and the support page's Getting the app show Apple's **Download on the App Store** badge linking there (ROADMAP task 353, with the owner's OK to use Apple's artwork, 2026-11-06), and so does the web app's invite page, `/join/<code>`, in a browser that isn't on Android (INV-7). The landing page's FAQ, `llms.txt`, and the JSON-LD link to the listing in plain text; `/ios` in `firebase.json` redirects to it, and the web app's iPhone notification tip opens it (NOTIF-9, `LinkService.iosApp`). Android is "on the way" everywhere until it's on Google Play.

Apple's rules for the badge ([App Store marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/), "App Store badges"), which the pages follow:

- **The artwork as Apple supplies it.** `images/app-store-badge.svg` is the black US-English badge from Apple's marketing tools (`https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us`), byte for byte: never recolor, crop, angle, or animate it, and never translate "App Store". The app's copy, `assets/store/app-store-badge.png`, is the same artwork rendered at 3×.
- **The black badge, on every scheme.** Apple prefers it in all marketing, and requires it once another store's badge sits beside it; its gray rim is part of the artwork and keeps it clear on Army green, Dark, and Navy. The white badge is only an alternative, so the page doesn't load it.
- **Size and space.** At least 40 px tall on screen (48 px here, 44 in the app), with a quarter of its height clear all round (12 px), in a subordinate spot under the main message, and one badge per page (the FAQ keeps its plain link).
- **Order.** The App Store badge comes first in a row of badges.
- **Credit line.** Each page that shows the badge ends its footer with "Apple and the Apple logo are trademarks of Apple Inc., registered in the U.S. and other countries. App Store is a service mark of Apple Inc." (`.credit`).

Google Play's badge waits (ROADMAP task 214) in a `<template data-store-badges>` after Apple's, in `index.html` and `support.html`, which the browser never renders or loads. To turn it on:

1. Add the official "Get it on Google Play" artwork to `images/` as `google-play-badge.png`, following Google's badge guidelines, at the same height as Apple's.
2. Check the package (`app.getbattleplan`).
3. Move its `<a>` out of the `<template>` into the `div.store-badges`, after Apple's, in both files, and on the web app's `/join` page for Android browsers.
4. Change the copy that says the Android app is "on the way" (the FAQ and its JSON-LD copy, the support page, `llms.txt`, the README) and set the JSON-LD `operatingSystem` to "iOS, iPadOS, Android, Web".

## Screenshots

The screenshots show the app with the seeded sample teams (Thunder, Cyclone, and Rally Possums, in navy, Carolina blue, and purple), the seeded group Saturday Run Club (green, at `/g/run-club/chat`: a chat of only messages and one small photo, which the coach is in and has read), and people (common American names and TV characters), the same data `tools/seed/seed.ts` loads into the emulators. Each one is named for its screen and the color scheme it's in, and together they show all five:

| Image | Scheme | Signed in as | Screen |
|---|---|---|---|
| `schedule-army`, `-light`, `-dark`, `-navy`, `-skyblue` (hero) | all five | `jim@example.com` | Thunder's schedule as a player: their own Going, Maybe, and Not going on the cards and a practice still to answer, the same screen in each scheme |
| `group-chat-navy` | Navy | a member of the group | A group's chat: messages from several people and a small photo only, with no event cards or polls in view |
| `event-skyblue` | Light blue | `coach@example.com` | Thunder's game against the Eagles, with the RSVPs |
| `poll-dark` | Dark | `rachel@example.com` | Rally Possums' tournament poll |
| `documents-navy` | Navy | `coach@example.com` | Thunder's documents |
| `allteams-skyblue` | Light blue | `claire@example.com` | Cyclone's schedule with **All my teams** on |
| `youth-light` | Light | `claire@example.com` | Cyclone's practice, answering for Luke and Alex |
| `dues-army` | Army green | `coach@example.com` | Team info → **Dues**, an admin's view: who's paid and what's owed |
| `dues-mine-light` | Light | `claire@example.com` | **What you owe** and **How to pay** |
| `whiteboard-army` | Army green | `coach@example.com` | Plays, the coach's whiteboard |

The current set (Open Field, all five schemes, 2026-11-06, the owner's request) are captures of the real web app against the emulators. To retake them: start the emulators fresh (restart rather than clearing over REST), seed them (DEVELOPMENT.md), and build from a scratch copy with `bannerLabel` in `lib/core/env.dart` returning null (never commit that), with `flutter build web -t lib/main_dev.dart --dart-define=USE_EMULATORS=true --no-web-resources-cdn --base-href /app/` (CanvasKit: headless Chrome doesn't paint the wasm build), plus `tools/fetch_fallback_fonts.dart` into its `fonts/fallback/` for the emoji. Seed and browse in one time zone where it's currently daytime (seed with `TZ=` set and the seed's `America/Chicago` swapped to match in a scratch copy, and `page.emulateTimezone` in Chrome), so message times look normal and cards skip the "your time" line. Serve the build under `/app/` and drive headless Chrome at 390 × 844 with a device scale of 600 / 390: hide `.firebase-emulator-warning`, sign in with the keyboard alone (Tab to Email and to Password, typing in each, then Sign in through the semantics tree: Flutter keeps a mouse's hover where it last clicked, which lights up whatever later sits there), open each screen by its route (`history.pushState` and a `popstate` event, since a reload signs out), and press buttons through the semantics tree (clicking a `flt-semantics[role=button]` element), since synthetic mouse clicks don't reach some of them.

- **Schemes:** after signing in, PATCH `users/<uid>` with `colorScheme` (`army`, `light`, `dark`, `navy`, or `skyblue`) through the emulator's REST API (`Authorization: Bearer owner`, `updateMask.fieldPaths=colorScheme`). The app recolors live, so the five `schedule-*` shots come from one sign-in. Per-team picks (`groupMembers/<groupId>_<uid>.colorScheme`) aren't seeded, so the default applies everywhere.
- **Schedule:** Jim's account is linked to the player Jim Halpert on Thunder, so every card on that schedule has an answer row; the seed answers Going, Maybe, and Not going and leaves the third practice unanswered. The coach has no player, so the coach's cards only count who's going. Open `/g/thunder/schedule` (Upcoming).
- **Group chat:** open the seeded group's chat (`/g/<groupId>/chat`) and check that only messages and the small photo are in view: no event cards or polls. Chat opens at the first unread message, so take it first after seeding, or as someone who has read it.
- **Dues:** open `/g/<team>/info`, then press **Dues** (going there directly leaves the app bar without its back button). The seed's dues are on Thunder and Cyclone.
- **All my teams:** press **Filter**, the **All my teams** switch, then **Dismiss**.
- **Whiteboard:** open `/g/thunder/plays/thunder-relay-home`, press **Next step**, and wait about 4 seconds.
- **Focus rings:** run `document.activeElement.blur()` before each shot (the documents filter field and closed sheets leave focus behind).

Convert each PNG to WebP at quality 80 (headless Chrome's `canvas.toDataURL('image/webp', 0.8)` works where `cwebp` isn't installed) as `images/<name>-<scheme>.webp`, using the names in the table.

Regenerate `images/og.jpg` at 1200 × 630 when the hero's heading or its schedule shots change: the brand mark, the stencil eyebrow, the page's heading ("Every team needs a Battleplan."), and one line of copy on the left, and a fan of the five `images/schedule-*.webp` on the Army green page color on the right. It's a plain HTML page using `fonts/` and those images, outside this folder, screenshotted in headless Chrome at 1200 × 630 as a JPEG at quality 85 (about 140 KB).

## Checking it

Serve the folder with clean URLs (for example `firebase emulators:start --only hosting` after `tools/build_hosting.sh`, or any static server that maps `/support` to `support.html`), then check each page at 320, 375, 390, 768, 1024, and 1440 px: no console errors, no broken links or images, no horizontal scrolling, and no axe (WCAG 2 AA) violations. On the landing page, check all five schemes, with and without JavaScript, and that the JSON-LD parses and its FAQ matches the page. Where the App Store badge shows, check it's at least 40 px tall with 12 px clear around it.
