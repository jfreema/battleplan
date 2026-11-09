# SEO plan: getbattleplan.app

How the website gets found: what people search for, which page answers each search, and what's still to do. The owner asked for it on 2026-11-09: "find a good SEO skill and use that to give the battleplan landing page good SEO for things like team chat, team messaging, group messaging, baseball team play whiteboard, and things that will help direct potential customers to the site." ROADMAP task 368 did the first round; the audit below, made the same day with the `seo-audit` skill's process, is the plan to keep following. How the pages are built, and the rules they keep, are in [website/README.md](../website/README.md).

## Status

**Done (2026-11-09, task 368).** Quick wins Q1 to Q7, Q9, and Q11, and new pages S1 to S6, as the audit specifies them, with these differences:

- **Q1, Q3:** the landing page's title, description, Open Graph and Twitter text, eyebrow ("Team chat for groups and sports teams"), and lead are as in §3. The heading still reads "Every team needs a Battleplan.", with the eyebrow inside the `<h1>`, looking as it did, so the heading carries "team chat". `images/og.jpg` still shows the old eyebrow.
- **Q2:** the whiteboard section names baseball and softball, Post to chat, and Save as GIF, with Softball and Save as GIF chips.
- **Q4:** `/switch` has the new title, description, and H1, a "Why teams switch" line linking both alternative pages, breadcrumbs with `BreadcrumbList`, the badge letters beside the headings rather than in them, and **Get Started** at the end.
- **Q5, S6:** every page's footer has **Features** (Team chat, Schedule and RSVPs, Team dues, Baseball whiteboard, Groups) and **Switching** (Switch from GroupMe or TeamSnap, TeamSnap alternative, GroupMe alternative). The landing page links each feature page under its tiles ("Take a closer look") and from the whiteboard, Players first, Dues, and Switching sections; its feature tiles themselves are unchanged. The 404 page lists the most visited pages.
- **Q6:** the color scheme answer says a team's admins set its scheme, in the page and the `FAQPage`. The landing page also has three new questions (is it a team chat app, does it sync with Google Calendar, can we draw plays), each linking to its page.
- **Q7:** `alternateName` ("Battleplan Team Chat", "Battleplan team app") on `WebSite` and `SoftwareApplication`, a fuller `featureList`, the whiteboard screenshot, and `twitter:image:alt` on every page. `Organization` has no `sameAs` yet: the Facebook page's address isn't in the repo.
- **Q9:** `tools/build_hosting.sh dev` adds a robots `noindex` to every website page on the dev site.
- **S1 to S5:** `/team-chat`, `/baseball-whiteboard`, `/team-schedule`, `/team-dues`, `/groups`, `/teamsnap-alternative`, and `/groupme-alternative`, at the URLs, titles, H1s, and descriptions in §8, each with breadcrumbs, an FAQ, and `WebPage`, `BreadcrumbList`, and `FAQPage` JSON-LD, in `sitemap.xml` and `llms.txt`. They reuse the landing page's screenshots: `/baseball-whiteboard` shows the still Relay home screenshot, not the looping animation (to do, below). The alternative pages state only Battleplan's facts and make no claims about the other apps.
- Players and guardians throughout: "parents" is still not used on any page (the owner's call, §2.2).

**Waiting on Jared.** Q8 (verify the site in Google Search Console and Bing Webmaster Tools, submit `sitemap.xml`, and request indexing of `/`, `/switch`, and the seven new pages) and Q10 (free listings on AlternativeTo, Capterra and GetApp, G2, and Product Hunt). Q8 comes first: nothing else can be measured without it.

**Still to do.** S1's looping play animation (an animated WebP or muted video from Save as GIF), a 1200 × 630 share image for each new page, S7 (the animated baseball play library), S8 (App Store keywords at the next version), S9 (outreach), S10 (real quotes and ratings, once there are some), S11 (Google Play, when it's live), S12 (Search Console every month), S13 (later pages), and `sameAs` for the Facebook page.

---

## The audit (2026-11-09)
Full site audit, run with the `seo-audit` skill's process (keyword research, on-page audit, content gaps, technical checklist, competitor comparison), adapted to a static site we control. Audited 2026-11-09 against `website/` at `abcba0f` (the live site matches the repo byte for byte).

**Tools and limits.** No SEO tool (Ahrefs, Semrush) or Search Console was connected, so search demand and difficulty are relative estimates from what ranks today (who owns the results, how strong they are, how many results are app-store listings or thin pages). PageSpeed Insights' API was over its daily quota, so speed is judged from the page's weight, headers, and markup. For real numbers, connect an SEO tool or verify the site in Google Search Console (action Q8).

---

### 1. Executive summary

Battleplan's site is technically excellent: static HTML with 8 KB of compressed markup, a 140 ms time to first byte, clean URLs with 301s from `.html`, `www`, and `http`, self-canonicals, valid JSON-LD (Organization, WebSite, SoftwareApplication, FAQPage), Open Graph and Twitter cards on every page, a welcoming `robots.txt`, a dated sitemap, and a thorough `llms.txt`. That foundation is its biggest strength. The problem is that search engines have almost nothing to rank it for. One marketing page tries to cover every keyword. Its title starts with the brand, its H1 is a slogan ("Every team needs a Battleplan."), and "softball", "group messaging", "play designer", and "dues tracker" don't appear on it at all. In about 25 web searches for the owner's terms and the brand, the site never showed up once, and "Battleplan" is shared with a WW2 strategy game and several "Battle Plan" apps.

**Top three priorities:**

1. **Get indexed, measured, and told apart from the other Battleplans.** Verify the site in Google Search Console and Bing Webmaster Tools and submit the sitemap. Add `alternateName` and `sameAs` to the JSON-LD, and make page titles pair "Battleplan" with "team chat".
2. **Build keyword landing pages.** Start with the **baseball and softball whiteboard**, where the competition is mostly old iPad apps and thin pages and Battleplan is the only free option that animates plays, exports GIFs, and posts them to the team chat. Then build **team chat and group messaging** and the **team dues tracker**, followed by **team schedule and RSVPs**.
3. **Earn authority.** Write TeamSnap and GroupMe alternative pages, get listed on AlternativeTo, Capterra, G2, and Product Hunt, get links from Battle Baseball's own channels, and build an animated baseball plays library that other sites will want to link to.

**Overall assessment: strong technical foundation, but content and authority need work.** Nothing is broken. The site just doesn't have pages built to win searches yet.

---

### 2. Keyword research

#### 2.1 What the results pages show

- **"Team chat app" and "team messaging app"** are workplace terms. Slack, Microsoft Teams, RingCentral, Pumble, ClickUp, and business roundups fill the results. Battleplan can't win them as written, but it can win the **sports versions** ("team chat app for sports teams"), which Spond, BenchApp, TeamSnap, GroupMe's blog, and vendor roundups (Jersey Watch, TeamLinkt, DialMyCalls) compete for.
- **"Group messaging app" and "group chat app"** belong to WhatsApp, GroupMe, Signal, and Telegram. Win them through long-tail versions: GroupMe alternative, group chat for clubs, and group chat with no ads.
- **Baseball and softball play whiteboard terms are wide open.** The results are mostly App Store listings (Baseball WhiteBoard, free but last updated in 2021; Baseball Board, $4.99 for iPad; Baseball Board – Tactics; TacticalPad), plus ConceptDraw's static diagrams and tactical-board.com's page of about 120 words. No strong web page owns these terms. Battleplan's web, iPhone, and iPad app with animation, GIF export, and team chat is a better product than anything ranking.
- **Dues tracking** is served by small apps (TeamTracky, Team Dues, Team Fund Tracker, PayUp) and vendor blogs (BenchApp, Jersey Watch, TeamLinkt). The difficulty is easy to moderate. Battleplan's angle stands out: no fees, money never goes through the app, and partial payments are supported.
- **"Free TeamSnap alternative" and "GroupMe alternative"** are proven terms. BenchApp has six "alternative" pages, and TeamSideline, Cactusware, AlternativeTo, and Capterra all rank. Most free rivals carry ads (Heja's free tier, Stack Team App, The Futures App, TeamReach) or charge for key features (BenchApp's text RSVPs, TeamSnap's paid plans). **"Free, every feature, no ads" is a real point of difference.**
- **Scheduling and youth sports app terms are hard.** TeamSnap, SportsEngine, GameChanger, BenchApp, and Spond have strong domains and dedicated pages.
- **AI answers:** assistants cite vendor blog posts with FAQ sections (Spond, BenchApp). BenchApp also publishes `.md` copies of its pages for language models. Battleplan's `llms.txt` and welcoming `robots.txt` are a good start. Pages that answer the questions directly will get cited.

#### 2.2 Keyword opportunity table

Demand and difficulty are estimated as described above. "Not found" means the site didn't appear in the web searches run for this audit; confirm in Search Console.

| # | Keyword | Demand | Est. Difficulty | Opportunity Score | Current Ranking | Intent | Recommended Content Type / Page |
|---|---|---|---|---|---|---|---|
| 1 | baseball whiteboard app | Low–Med | Easy | **High** | Not found | Commercial | Landing page `/baseball-whiteboard` |
| 2 | baseball play designer / baseball playbook app | Low–Med | Easy–Moderate | **High** | Not found | Commercial | `/baseball-whiteboard` (title + H2) |
| 3 | softball play maker / softball playbook app | Low | Easy | **High** | Not found | Commercial | `/baseball-whiteboard` ("Softball too" section) |
| 4 | animated baseball plays / baseball relay and cutoff diagram | Low–Med | Moderate (ConceptDraw) | **High** | Not found | Informational | Animated play library `/plays/baseball/<play>` (GIF + steps) |
| 5 | team chat app for sports teams | Medium | Moderate | **High** | Not found | Commercial | `/team-chat` |
| 6 | free team app no ads / sports team app with no ads | Low | Easy–Moderate | **High** | Not found | Commercial | Homepage + `/teamsnap-alternative` |
| 7 | free TeamSnap alternative | Medium | Moderate | **High** | Not found | Commercial (decision) | `/teamsnap-alternative` |
| 8 | GroupMe alternative for sports teams | Low–Med | Easy–Moderate | **High** | Not found | Commercial (decision) | `/groupme-alternative` |
| 9 | team dues tracker / track team dues app | Low–Med | Easy–Moderate | **High** | Not found | Commercial | `/team-dues` |
| 10 | Battleplan team app / Battleplan team chat (brand) | Low | Moderate (name clash) | **High** | Not found | Navigational | Homepage title + JSON-LD `alternateName` |
| 11 | how to collect team dues (Venmo) | Low–Med | Moderate | Medium | Not found | Informational | `/team-dues` FAQ + "Ditch the spreadsheet" section |
| 12 | move GroupMe group to another app / import GroupMe chat | Low–Med | Moderate (Microsoft support owns "export") | Medium | Not found | Informational | `/switch` (retitled) + `/groupme-alternative` |
| 13 | TeamReach alternative | Low | Easy | Medium | Not found | Commercial | `/switch` + `/teamsnap-alternative` mention |
| 14 | sports team scheduling app (free) | Medium | Moderate–Hard | Medium | Not found | Commercial | `/team-schedule` |
| 15 | team RSVP app / sports team attendance app | Low–Med | Moderate | Medium | Not found | Commercial | `/team-schedule` |
| 16 | sync team schedule to Google Calendar | Low | Easy | Medium | Not found | Commercial / informational | `/team-schedule` ("Sync to your calendar") |
| 17 | group chat app for clubs (no ads) | Medium | Moderate–Hard | Medium | Not found | Commercial | `/groups` |
| 18 | app for coaches to communicate with parents | Medium | Moderate | Medium (wording rule, see note) | Not found | Commercial | `/team-chat` or a later `/youth-teams` |
| 19 | youth sports team app | Med–High | Hard | Medium | Not found | Commercial | Homepage + later `/youth-teams` |
| 20 | team snack sign-up / team snack schedule | Medium | Moderate–Hard (SignUpGenius) | Low–Med | Not found | Transactional | `/team-schedule` ("Snacks, drinks, scorekeeper") |
| 21 | basketball play designer / soccer tactics board / football play designer | Medium | Hard | Low–Med | Not found | Commercial | Later: `/plays` hub + sport pages |
| 22 | team messaging app | High | Hard (workplace) | Low | Not found | Commercial (workplace) | Secondary on `/team-chat` |
| 23 | group messaging app / group chat app | High | Very hard | Low | Not found | Commercial / navigational | Secondary on `/team-chat` and `/groups` |
| 24 | team chat app (head term) | High | Hard (workplace) | Low (direct) | Not found | Commercial | Homepage title (with "sports teams") |
| 25 | GameChanger alternative | Low | Moderate | Low | Not found | Commercial | Don't target: Battleplan has no scoring; use "Use it with GameChanger" on `/switch` |

**Note on "parents":** `website/README.md` says the landing page says **players** and **guardians**, never kids, children, or parents. That rule is the owner's. "Parents" is the higher-demand word in search ("app for coaches to communicate with parents"). The App Store listing already aims at "coaches and parents". This audit keeps "guardians" in every page outline below. Allowing "parents" on one page (for example a later `/youth-teams`) would be Jared's call.

#### 2.3 Long-tail and question variants (for H2s, FAQs, and guides)

- **Team chat:** "best free app for team communication for sports", "group chat app for a sports team", "team chat app with polls", "team chat app without ads", "is there an app like GroupMe for teams", "how do I make a group chat for my team", "team chat app for youth baseball".
- **Whiteboard:** "baseball play designer app free", "softball play maker free", "baseball defensive plays diagram", "relay and cutoff positions baseball", "how to draw baseball plays", "baseball playbook app for iPad", "coach whiteboard app for iPad", "baseball whiteboard online", "first and third defense diagram", "bunt coverage diagram", "save a play as a GIF".
- **Schedule and RSVPs:** "free sports team scheduling app", "app to see who's coming to practice", "team availability app", "how do I get my team to RSVP", "sync team schedule with Google Calendar", "team snack schedule app".
- **Dues:** "how to track team dues", "how to collect team fees with Venmo", "team fee tracker instead of a spreadsheet", "track partial payments for team fees", "who has paid team dues".
- **Switching:** "how to export GroupMe chat history", "move a GroupMe group to another app", "export TeamSnap roster", "TeamSnap export schedule", "TeamReach alternative".
- **Free, no ads:** "free team app with no ads", "is TeamSnap free", "apps like TeamSnap but free".
- **Groups:** "group chat app for clubs", "run club app", "app for group events with RSVPs".

---

### 3. On-page SEO audit

Measured from the HTML. Titles should be 50–60 characters, meta descriptions 150–160 with a call to action, and each page should have one H1 with the keyword in the first 100 words.

| Page | Title (chars) | Meta (chars) | H1 | Words in `<main>` | Notes |
|---|---|---|---|---|---|
| `/` | 65 | 157, no CTA | "Every team needs a Battleplan." | ~656 (many are chips) | "team chat" in the first 15 words; "softball" 0 times; "baseball" only in chips, alt text, and the footer |
| `/switch` | 20 | 132, no CTA | "Switch to Battleplan" | ~559 | Not in any footer; no Get Started |
| `/support` | 20 | 103 | "Support" | ~653 | Fine for a help page |
| `/privacy` | 27 | 131 | "Privacy Policy" | ~3,669 | Fine |
| `/terms` | 25 | 100 | "Terms of Use" | ~2,230 | Fine |
| `/delete-account` | 32 | 101 | "Delete your Battleplan account" | ~774 | Fine |
| `/404` | — | — | "Page not found" | ~52 | `noindex`, real 404 status: correct |

#### On-page issues table

| Page | Issue | Severity | Recommended Fix |
|---|---|---|---|
| `/` | Title is 65 characters (cut off in results) and starts with a brand that has no recognition yet, while the brand name clashes with a game | High | `Free team chat & scheduling for sports teams · Battleplan` (57). Copy it to `og:title` and `twitter:title` |
| `/` | Meta description has no call to action and spends words on guardians rather than search terms | Medium | `Free team chat app for sports teams and groups: group messaging, schedules and RSVPs, dues, polls, and a coach's play whiteboard. No ads. Get started free.` (155) |
| `/` | H1 is a slogan with no keyword | Medium | Keep the slogan as the H1 (it's the brand and the og image). Put the keyword in the eyebrow above it, `Team chat for groups and sports teams`, and in the lead: `Team chat, schedules, RSVPs, dues, and plays for sports teams and groups. Free, with no ads.` (Stronger but bigger change: make the H1 the keyword line and the slogan the eyebrow. That's a design call for Jared.) |
| `/` | "Softball" never appears; the whiteboard is one sentence; nothing says "animated", "Save as GIF", or "Post to chat" | High | Whiteboard copy: `Draw baseball and softball plays on the diamond, add steps, and press play. Post a play to the team chat or save it as a GIF. Made for an iPad at practice.` Chips: Baseball, Softball, Basketball, Soccer, Football, Blank board, Save as GIF. Softball uses the baseball diamond, so say "baseball and softball", not "a softball field" |
| `/` | Feature tiles and spotlights don't link to deeper pages (there are none yet) | High (once the pages exist) | Link "Group chat" → `/team-chat`, "Games and RSVPs" → `/team-schedule`, the whiteboard → `/baseball-whiteboard`, Dues → `/team-dues`, Switching → `/groupme-alternative` and `/teamsnap-alternative` |
| `/` | FAQ "Can I change how my team looks?" says "Everyone picks their own". Since `ed6ccfd` team admins set a team default (`llms.txt` already says so). The JSON-LD copy is stale too | Medium | Update the answer in the HTML and the FAQPage JSON-LD together (README rule) |
| `/` | FAQ, support page, and `llms.txt` say "Dues and the new color schemes come to the iPhone app in its next update" | Low | Already tracked in ROADMAP task 352: remove it when iOS 1.2 is out |
| `/` | No social proof (no quotes, ratings, or team counts) | Medium | Add 2–3 real coach quotes and the App Store rating once there are some. Never invent them |
| `/` | Hero image alt text runs ~800 characters (others 450–690) | Low | Keep the descriptions for screen readers but trim to ~150–250 characters with the keywords (for example "Battleplan on five phones: a baseball play on the coach's whiteboard, a team schedule with RSVPs, team chat, group chat, and a poll") |
| `/` | Anchor text "Bring your history." is vague | Low | "Switch from GroupMe or TeamSnap" |
| `/switch` | Title "Switch to Battleplan" (20) has no search terms | High | `Move your team from GroupMe or TeamSnap · Battleplan` (52) |
| `/switch` | Meta description has no call to action | Medium | `Bring your team's chat history, schedule, roster, and files over from GroupMe, TeamSnap, TeamReach, GameChanger, or Google Calendar, step by step. Start free.` (158) |
| `/switch` | H1 has no search terms | Medium | `Move your team from GroupMe, TeamSnap, and more` |
| `/switch` | No Get Started button: a reader convinced to switch has only Login | High (conversion) | Add the closing call to action from the homepage (Get Started → `/app/sign-up`) |
| `/switch` | Each H2 reads "GFrom GroupMe" or "TFrom TeamSnap" to crawlers, because the badge letter is inside the heading (`aria-hidden` doesn't hide it from search engines) | Low | Move the badge `<span>` before the `<h2>`, or draw the letter with CSS `::before` and `attr(data-letter)` |
| `/switch` | Only linked from the homepage body: no footer or header link on any page | Medium | Add "Switch from GroupMe or TeamSnap" to every footer (all HTML files, README rule) |
| `/switch` | Explains how but not why: nothing on free, no ads, plays, or dues | Medium | Add one short "Why teams switch" line plus links to the new alternative pages |
| All subpages | `twitter:image:alt` missing (the homepage has it) | Low | Add it to match `og:image:alt` |
| All subpages | Same og image everywhere | Low | New keyword pages should get their own 1200 × 630 image (for example the whiteboard page shows a play) |
| All subpages | No `BreadcrumbList` | Low | Add one to each new keyword page (Home › Team chat) |
| `/support` | Short title and meta (fine for help) | Low | Optional: `Battleplan support: help with team chat, RSVPs, invites` (55) |
| Header and footer | Navigation has only in-page anchors, Support, and Login: no links to features | Medium | Add a footer "Features" list: Team chat · Schedule & RSVPs · Dues · Baseball whiteboard · Groups · Switch from GroupMe or TeamSnap |

What passes: every indexable page has exactly one H1, a logical H2/H3 order, a unique title and description, an absolute self-canonical, and alt text on every image (decorative ones `alt=""`). URLs are short, readable, and have no query strings, and screenshot filenames describe the screen (`team-chat-navy.webp`, `whiteboard-army.webp`).

---

### 4. Content gap analysis

Competitors checked: **BenchApp** (15 feature pages, 14 sport pages, 6 "alternative" pages, a blog, and `.md` copies for AI), **Spond** (feature pages, plus blog posts of ~1,100 words with FAQs that target "best team chat and scheduling app"), **TeamSnap** (sport pages, club and league focus, strong domain), **GroupMe** (blog pages targeting youth baseball and high-school football), **Heja**, plus the play-designer tools (Baseball WhiteBoard, Baseball Board, TacticalPad, tactical-board.com, ConceptDraw).

**Funnel gaps:** the **awareness** stage (guides, play library) and the **consideration** stage (feature pages, alternative pages) are both missing. Only the **decision** stage (homepage, `/switch`, FAQ) exists.

**Topic clusters to build:**
- **Plays:** pillar `/baseball-whiteboard`, then animated play pages (`/plays/baseball/relay-home` and others), later a `/plays` hub for the other sports.
- **Team app:** pillar `/` (homepage), with `/team-chat`, `/team-schedule`, `/team-dues`, and `/groups`.
- **Switching:** pillar `/switch`, with `/groupme-alternative` and `/teamsnap-alternative`.

**Freshness:** every page changed in November 2026. **Thin content:** the homepage is short on purpose (README rule: "short on words"). Don't add bulk to it; put the depth on the new pages.

| # | Topic or keyword | Why it matters | Recommended format | Priority | Estimated effort |
|---|---|---|---|---|---|
| 1 | Baseball & softball whiteboard / play designer | The owner's term. Weakest competition of any target, and Battleplan's product is better than what ranks. Battle Baseball heritage gives credibility | Landing page `/baseball-whiteboard` with a looping play animation | **High** | Moderate (half day, plus GIF/video export) |
| 2 | Team chat & group messaging for teams | The owner's top terms. Spond, BenchApp, and TeamSnap all have a chat page; Battleplan doesn't | Landing page `/team-chat` | **High** | Moderate (half day) |
| 3 | Team dues tracker | Small-app competition; "no fees, money never goes through us, partial payments" stands out; a fresh feature | Landing page `/team-dues` | **High** | Moderate (half day) |
| 4 | Free TeamSnap alternative | Proven decision-stage term; BenchApp has a page for it; "free, no ads, no paid tier" sets Battleplan apart | Comparison page `/teamsnap-alternative` | **High** | Moderate (half day) |
| 5 | GroupMe alternative for sports teams | Battleplan imports GroupMe history (rare); GroupMe's blog shows sports teams are a big GroupMe audience | Comparison page `/groupme-alternative` | **High** | Moderate (half day) |
| 6 | Sports team scheduling & RSVPs | Core feature; harder terms, but needed for the cluster and for internal links | Landing page `/team-schedule` | Medium | Moderate (half day) |
| 7 | Animated baseball plays (relays, cutoffs, bunt coverage, first-and-third) | Informational searches with static-diagram competition (ConceptDraw). Animated GIFs are link-worthy and show off Plays | Guide library `/plays/baseball/<play>`, one short page per play | Medium–High | Substantial (multi-day; about 1–2 hours per play) |
| 8 | Group chat for clubs and groups | Groups are a real feature (Saturday Run Club) with nowhere to rank | Landing page `/groups` | Medium | Moderate (half day) |
| 9 | Sport pages (baseball team app, softball team app) | BenchApp and TeamSnap each have 8–14 sport pages; baseball fits the brand | `/baseball-team-app`, later others | Medium | Moderate each |
| 10 | Guides: collect dues without awkwardness; run a snack schedule; move off GroupMe without losing photos | Question searches that AI assistants answer from vendor blogs | Short guides (600–900 words, FAQ) | Medium | Moderate each |
| 11 | Social proof (quotes, ratings, team counts) | Trust signals for both rankings and conversion; every competitor has them | Homepage strip plus a line on each landing page | Medium | Quick win once quotes exist |
| 12 | Youth teams and guardians | "Youth sports team app" is hard, but guardians answering per player sets Battleplan apart | `/youth-teams` (see "parents" note) | Low–Med | Moderate |

---

### 5. Technical SEO checklist

| Check | Status | Details |
|---|---|---|
| HTTPS | Pass | HSTS on every response; `http://` → `https://` 301 |
| Host canonicalization | Pass | `www.getbattleplan.app` → apex 301; `/index.html` → `/` 301; `/switch.html` → `/switch` 301 (`cleanUrls`) |
| robots.txt | Pass | `Allow: /` for all, AI crawlers named, sitemap listed; `/app/` stays crawlable so crawlers see its `noindex` |
| XML sitemap | Pass | 6 URLs with `lastmod`. New pages must be added; submission to Search Console not confirmed |
| Canonical tags | Pass | Absolute self-canonical on all six indexable pages; 404 has none (correct) |
| noindex usage | Pass | `/404` meta `noindex`; `/app/**` `X-Robots-Tag: noindex` header (confirmed live) |
| Duplicate hosts | Warning | `battleplan-prod.web.app`, `battleplan-prod.firebaseapp.com`, and the dev site `battleplan-dev-ecce4.web.app` serve the same pages. Canonicals point to getbattleplan.app, which mitigates it, but the dev site is crawlable and indexable. (BenchApp's preview and staging builds show up in search results today, a live example of the risk.) Fix: have `tools/build_hosting.sh dev` add `<meta name="robots" content="noindex">` to the website pages, keeping canonicals |
| Indexation | **Fail (unverified)** | The site didn't appear in any of ~25 searches, including brand + feature queries; the `site:` operator wasn't supported. Verify in Search Console and Bing Webmaster Tools, submit the sitemap, and request indexing of `/` and `/switch` |
| Brand disambiguation | Warning | "Battleplan" collides with Slitherine's WW2 game and several "Battle Plan" apps. Add `alternateName` (`Battleplan Team Chat`, `Battleplan team app`) to WebSite and SoftwareApplication, add `sameAs` (App Store, Facebook page, later Google Play) to Organization, and pair the brand with "team chat" in titles |
| Structured data | Warning | Valid graph: Organization, WebSite, SoftwareApplication, FAQPage. Since 2023 Google shows FAQ rich results only for government and health sites, so FAQPage helps Bing and AI answers, not Google snippets. SoftwareApplication rich results need `aggregateRating` or `review`: add them only from real, visible ratings. One FAQ answer is stale (see on-page). New pages: WebPage + BreadcrumbList, `about` → `#app` |
| Open Graph / Twitter | Pass | All pages; 1200 × 630 JPEG, 137 KB, with alt. Subpages lack `twitter:image:alt` (Low) |
| Mobile-friendliness | Pass | `viewport-fit=cover`, safe-area padding, 44 px tap targets, no horizontal scroll at 320 px (README checks 320–1920 px) |
| Page speed | Pass (estimated) | Brotli HTML 8 KB, TTFB ~140 ms, no framework JS (one tiny inline script), hero images 242 KB WebP, CSS 29 KB. PageSpeed Insights wasn't available (quota) |
| Core Web Vitals signals | Pass (estimated) | LCP image has `fetchpriority="high"`; every `<img>` has width and height (no layout shift); 3 preloaded fonts (~74 KB). Optional: drop the Black Ops One preload (eyebrows only) so it doesn't compete with the LCP image. No field data yet (new site) |
| Caching | Warning (Low) | HTML `no-cache` (right for edits); `/images/` and `/fonts/` get Firebase's default `max-age=3600`. Fine for first visits; longer caching would need versioned filenames |
| Broken links | Pass | Every internal link and asset returns 200; App Store returns 301 (normal). The Google Play badge and URL return 404 but sit inside an inert `<template>` (not rendered or followed) |
| Mixed content / third parties | Pass | No third-party requests, cookies, or analytics on the website |
| 404 handling | Pass | Real 404 status with a custom `noindex` page |
| llms.txt | Pass | Complete and current (already has the team-default color scheme). Add "softball" to the whiteboard line and the new pages to Links as they ship |
| AI crawler access | Pass | GPTBot, ClaudeBot, PerplexityBot, Google-Extended, Applebot-Extended, and others allowed by name |
| hreflang | N/A | English only, US and Canada |
| Measurement | Warning | No analytics by design (privacy promise), so Search Console and Bing Webmaster Tools are the only SEO measurement. Both need setting up (Q8) |

---

### 6. Competitor comparison

#### 6.1 Team apps

| Dimension | Battleplan | BenchApp | Spond | TeamSnap | GroupMe | Winner |
|---|---|---|---|---|---|---|
| Keyword footprint (est.) | ~0: not found for any target or brand query | Large: 15 feature, 14 sport, 6 alternative pages, plus a blog | Large: feature pages plus a blog targeting "best team chat and scheduling app" | Very large: sport pages, club and league focus | Very large brand; blog pages on youth baseball and HS football | TeamSnap / GroupMe |
| Content depth | 6 pages; homepage ~650 words, mostly chips | Homepage ~2,000 words; feature pages ~500 words with 6–8 FAQs | Posts ~1,100 words with 5 FAQs | Enterprise pages, light on chat and RSVP | Posts ~650–700 words | BenchApp |
| Publishing frequency | None (no blog) | Frequent | Regular | Regular | Regular | Competitors |
| Backlink signals | Near zero (new domain, no mentions found) | Moderate–strong; in many roundups | Strong in Europe, moderate in US | Very strong | Very strong (Microsoft) | TeamSnap / GroupMe |
| Technical score | Excellent: static, fast, schema, llms.txt, AI-crawler friendly | Good, plus `.md` copies for AI; staging builds leaking into the index | Good; heavy scripts and cookie banner | Heavy scripts | Good | **Battleplan** |
| SERP feature presence | None | Cited in AI answers; in roundups | Cited in AI answers | Knowledge panel, app packs | Knowledge panel | TeamSnap / GroupMe |
| Offer | Free, every feature, no ads, no paid tier | Free plus PRO ($9/mo for text RSVPs) | Free; fees on payments | Limited free; paid plans | Free chat only | **Battleplan** (strongest message, unused in search) |
| Feature coverage | Chat, schedule, RSVPs, polls, dues tracking, documents, plays whiteboard, imports | No whiteboard | No whiteboard | No whiteboard | Chat, polls, events only | **Battleplan** |

**Keyword overlap and gaps.** The overlap is "free team app", "team chat and scheduling", and "TeamSnap alternative". The gaps where competitors have pages and Battleplan doesn't are team chat, scheduling and RSVPs, payments and dues, sport pages, alternative pages, and "app for coaches to communicate with parents". No team-app competitor targets **play whiteboard** terms at all. That's Battleplan's open lane.

**What gets competitors links:** inclusion in "best free team apps" roundups, comparison pages, sport-specific landing pages, and parent and coach guides.

#### 6.2 Play whiteboard tools

| Tool | Platform | Price | Animation | Shares to team | Web page strength |
|---|---|---|---|---|---|
| **Battleplan Plays** | iPhone, iPad, web | Free, no ads | Yes, step by step, Save as GIF | Post to chat | None yet (one section of the homepage) |
| Baseball WhiteBoard | iPad | Free | No (dry-erase style) | No | App Store listing only; last updated 2021 |
| Baseball Board (Farrell) | iPad | $4.99 | Not stated; baseball or softball toggle | Share diagrams | App Store listing |
| Baseball Board – Tactics | iPad | Free | Not stated | No | App Store listing |
| TacticalPad | iPad | Free + $24.99/yr | Yes | No | App Store listing |
| tactical-board.com | Web | Unclear | Yes, video download | No | ~120-word page |
| ConceptDraw | Desktop | Paid | No (static diagrams) | No | Ranks for "relay and cutoff diagrams" |

A strong, focused web page plus an App Store listing that names plays and whiteboard (see S8) can realistically rank on the first page for "baseball whiteboard app" and "softball play maker".

---

### 7. Keyword map

| Page | Primary keywords | Secondary keywords |
|---|---|---|
| `/` (existing) | free team chat & scheduling app for sports teams; free team app no ads | team chat app; sports team app; Battleplan team app (brand); group messaging; coach's whiteboard |
| `/switch` (existing, retitle) | move team from GroupMe / TeamSnap; import GroupMe chat history | export GroupMe chat; TeamSnap export roster/schedule; TeamReach alternative; GameChanger calendar link |
| `/support`, `/privacy`, `/terms`, `/delete-account` (existing) | Brand help and legal only | Don't target marketing keywords |
| **NEW** `/team-chat` | team chat app for sports teams; team chat & group messaging for teams | team messaging app (sports); group chat for a sports team; team chat with polls; team chat app without ads; coach-to-team communication app |
| **NEW** `/baseball-whiteboard` | baseball whiteboard app; baseball play designer; softball play maker | baseball playbook app; animated baseball plays; coach's whiteboard app for iPad; save plays as GIF |
| **NEW** `/team-dues` | team dues tracker; track team dues | sports team fee tracker; how to collect team dues; team dues Venmo; partial payments |
| **NEW** `/team-schedule` | sports team scheduling app; team RSVP app | team attendance app; sync team schedule to Google Calendar; team snack sign-up; practice schedule app |
| **NEW** `/teamsnap-alternative` | free TeamSnap alternative | TeamSnap alternative no ads; apps like TeamSnap; TeamReach alternative |
| **NEW** `/groupme-alternative` | GroupMe alternative for sports teams | GroupMe alternative no ads; move GroupMe group; apps like GroupMe for teams |
| **NEW** `/groups` | group chat app for clubs and groups | group messaging app with events; run club app; club RSVP app |
| **LATER** `/plays/baseball/<play>` | animated baseball plays; baseball relay and cutoff diagram | bunt coverage diagram; first and third defense; backing up bases |
| **LATER** `/plays` hub + sport pages | coach's whiteboard app; play designer app | basketball play designer; soccer tactics board; football play designer |
| **LATER** `/youth-teams` | youth sports team app | app for coaches to communicate with guardians/parents (owner's wording call) |

**Avoiding overlap:** the homepage owns the combined "team chat **and scheduling**" and "free team app" terms. `/team-chat` owns "team chat **and group messaging**" and `/team-schedule` owns "scheduling and RSVPs", and each links back to the homepage. Use each page's primary keyword in its own title only.

---

### 8. New page specs

Every new page should follow `website/README.md`. Plain HTML in `website/<slug>.html` (served at `/<slug>` by `cleanUrls`) and the shared header and footer (change all HTML files when the nav or footer changes, and update the README's "all six" count). Open Field styles from `site.css` (Army green), short sentences, and app UI names in the app's own words. Say players and guardians. Real screenshots via the README's retake process, `width`/`height`/alt on every image, `loading="lazy"` below the fold, and `images/` under ~2 MB: show animations as animated WebP or a muted looping `<video>` rather than raw GIFs. One App Store badge with the credit line, a canonical, and Open Graph and Twitter tags. JSON-LD WebPage + BreadcrumbList (+ FAQPage when the page has an FAQ, matching it word for word). A `sitemap.xml` entry with `lastmod` and a line under Links in `llms.txt`. Each page ends with the Get Started call to action → `/app/sign-up` and links to its sibling pages.

#### 8.1 `/baseball-whiteboard` (priority 1)

- **Title (58):** `Baseball & softball whiteboard app: draw and animate plays`
- **H1:** `Baseball and softball whiteboard`
- **Meta (156):** `Draw baseball and softball plays on a real diamond, add steps, and watch them move. Post plays to your team chat or save them as GIFs. Free, no ads. Try it.`
- **Eyebrow / lead:** "Coach's whiteboard" / "Draw baseball and softball plays on the diamond, add steps, and press play. Free, with no ads."
- **Outline:**
  1. Hero: H1, lead, Get Started, App Store badge, looping animation of Thunder's *Relay home* (from Save as GIF, converted to WebP or video)
  2. H2 **Draw a play in seconds:** the nine at P, C, 1B, 2B, 3B, SS, LF, CF, RF; drag players and the ball, draw throws and routes; start with a batter or the bases loaded
  3. H2 **Add steps, press play:** each step glides into the next; made for an iPad at practice, works with a mouse on a computer
  4. H2 **Share it with the team:** Post to chat (opens the play in Plays); Save as GIF for texts and social posts
  5. H2 **Plays coaches draw:** Relay home, cutoff to third, bunt coverage, first-and-third defense, backing up bases (later each links to `/plays/baseball/<play>`)
  6. H2 **Softball too:** the same diamond for softball teams
  7. H2 **Other sports:** basketball court, soccer pitch, football field, blank board
  8. H2 **More than a whiteboard:** one line each linking `/team-chat`, `/team-schedule`, `/team-dues`
  9. H2 **Questions:** Is it free? Does it work on iPad and computers? Can I save a play as a GIF? Does it work for softball? Who can see our plays?
  10. Closing call to action
- **Schema:** WebPage, BreadcrumbList, FAQPage; VideoObject if a video is used.

#### 8.2 `/team-chat` (priority 2)

- **Title (54):** `Team chat & group messaging app for teams · Battleplan`
- **H1:** `Team chat for sports teams and groups`
- **Meta (158):** `Free team chat and group messaging for sports teams and groups: photos, replies, reactions, @mentions, pinned announcements, and DMs. No ads. Start your team.`
- **Lead:** "Battleplan is a free team chat app for sports teams and groups: one place for every message, with no ads."
- **Outline:**
  1. Hero with `team-chat-navy` or `team-chat-skyblue`
  2. H2 **Everything a group chat should do:** photos, replies, reactions, @mentions, chat search
  3. H2 **Announcements that don't get buried:** pinned messages and announcements
  4. H2 **Direct messages:** one to one with anyone you share a team with
  5. H2 **Chat, schedule, and plays together:** game cards, polls, and plays posted to chat (links to `/team-schedule` and `/baseball-whiteboard`)
  6. H2 **Made for teams:** invite by link, QR code, or code; report and block; accounts for adults 18+; guardians answer for players
  7. H2 **Bring your GroupMe chat:** imports history with names and dates (links to `/switch#groupme` and `/groupme-alternative`)
  8. H2 **On every phone and computer:** iPhone, iPad, any browser; Android on the way
  9. H2 **Questions:** Is it free? Are there ads? Can a group that isn't a team use it? Can we import our GroupMe chat? Do players need accounts?
  10. Closing call to action

#### 8.3 `/team-dues` (priority 3)

- **Title (59):** `Team dues tracker: see who's paid and who owes · Battleplan`
- **H1:** `Team dues tracker`
- **Meta (159):** `Track team dues for uniforms, fees, and tournaments: partial payments, who owes what, and your Venmo or Cash App. Money never goes through us. Free. Start now.`
- **Lead:** "Track team dues for uniforms, league fees, and tournaments: who's paid, who owes what, and partial payments. Free, and money never goes through Battleplan."
- **Outline:**
  1. Hero with `dues-army` and `dues-mine-light`
  2. H2 **Every due in one place:** an amount and due date for every player on a team or every member of a group
  3. H2 **Partial payments:** record a part at a time
  4. H2 **Who owes what:** by due and by person
  5. H2 **How to pay:** the team's Venmo, Cash App, or Apple Cash; people pay the team directly; no fees
  6. H2 **Private:** only admins see what others owe; everyone sees What you owe
  7. H2 **Ditch the spreadsheet:** a short answer to "how to track team dues" (Venmo plus a spreadsheet versus one shared record)
  8. H2 **Questions:** Does Battleplan collect payments? Are there fees? Can people pay part now? Who can see what I owe? Can a group track dues?
  9. Closing call to action
- Keep the iPhone app's payment rules in mind: on the site, say people pay the team directly, as the homepage does.

#### 8.4 `/team-schedule` (priority 4)

- **Title (56):** `Sports team scheduling app with RSVPs, free · Battleplan`
- **H1:** `Team schedule and RSVPs`
- **Meta (157):** `Schedule games and practices, get Going, Maybe, or Not going for every player, send reminders, and sync to Google or Apple Calendar. Free, no ads. Start now.`
- **Lead:** "A free sports team scheduling app: games, practices, and events, with RSVPs in one tap."
- **Outline:**
  1. Hero with `schedule-army` and `event-skyblue`
  2. H2 **Games, practices, and events:** opponent, home or away, the field with directions
  3. H2 **RSVPs for every player:** Going, Maybe, Not going; guardians answer for each player; counts are players only; an email to whoever hasn't answered
  4. H2 **Reminders:** per event and the team's defaults
  5. H2 **Snacks, drinks, scorekeeper:** assignments people volunteer for
  6. H2 **Sync to your calendar:** one private link for Google, Apple, or Outlook
  7. H2 **All my teams:** every team in one schedule (`allteams-skyblue`)
  8. H2 **Bring your schedule:** TeamSnap, TeamReach, GameChanger, Google Calendar (links to `/switch`)
  9. H2 **Questions:** Is it free? Does it sync with Google Calendar? Can a guardian answer for two players? Can I import from TeamSnap or GameChanger? Can people answer from an email?
  10. Closing call to action

#### 8.5 `/teamsnap-alternative` (priority 5)

- **Title (50):** `Free TeamSnap alternative with no ads · Battleplan`
- **H1:** `A free TeamSnap alternative`
- **Meta (157):** `Looking for a free TeamSnap alternative? Battleplan gives every team chat, schedules, RSVPs, dues, and plays, with no ads and no paid tier. Import your team.`
- **Outline:**
  1. Hero: every feature free, no ads, no paid tier
  2. H2 **What every team gets:** chat, schedule and RSVPs, polls, dues tracking, documents, plays, calendar sync
  3. H2 **Bring your TeamSnap team:** schedule link, roster CSV, files; chat and contact details stay behind (link to `/switch#teamsnap`)
  4. H2 **Players and guardians:** a row for each player
  5. H2 **What Battleplan doesn't do:** no payment processing, registration, live scoring, or streaming (honesty builds trust and filters fit)
  6. H2 **Questions**
  7. Fineprint: trademarks belong to their owners, no affiliation (as on `/switch`)
- State only Battleplan's facts, and competitor facts only with a source and date. No logos.

#### 8.6 `/groupme-alternative` (priority 5)

- **Title (55):** `GroupMe alternative for sports teams, free · Battleplan`
- **H1:** `A GroupMe alternative built for teams`
- **Meta (155):** `Keep your GroupMe chat history and add schedules, RSVPs, polls, dues, and plays. Battleplan is free with no ads. Import your group in a few taps and start.`
- **Outline:**
  1. Hero
  2. H2 **Keep your chat history:** messages, photos, files, and events, with names and original dates; nothing imported sends notifications
  3. H2 **Add what group chats are missing:** schedule and RSVPs, documents, dues, plays
  4. H2 **For groups too:** clubs that aren't teams (link to `/groups`)
  5. H2 **Move in three steps:** a summary that links to `/switch#groupme`
  6. H2 **Questions:** Does our history come with us? Is it free? Does everyone need the app? (Answer honestly: the app or any browser, with no SMS-only members.)
  7. Fineprint

#### 8.7 `/groups` (priority 6)

- **Title (58):** `Group chat & event RSVPs for clubs and groups · Battleplan`
- **H1:** `Group chat and events for any group`
- **Meta (158):** `Free group chat for run clubs, leagues, and any group: messages, photos, events with RSVPs, polls, documents, and dues in one place. No ads. Start your group.`
- **Outline:**
  1. Hero with `group-chat-light` (Saturday Run Club)
  2. H2 **Group chat**
  3. H2 **Events and RSVPs:** everyone answers for themselves
  4. H2 **Polls, documents, and dues**
  5. H2 **Make it a team later**
  6. H2 **Questions**
  7. Closing call to action

#### 8.8 Later: animated baseball play library

One short page per play at `/plays/baseball/<play>` (relay-home, cutoff-to-third, bunt-coverage, first-and-third-defense, backing-up-bases). Each page has an H1 with the play name ("Baseball relay home: who goes where"), the looping animation, 4–6 numbered steps for each position, a "Draw it yourself in Battleplan" call to action, and a link up to `/baseball-whiteboard`. These are the most link-worthy pages the site can have: coaches share them, and nobody else offers free animated versions.

---

### 9. Prioritized action plan

#### Quick wins (do this week)

| # | Action | Expected impact | Effort | Dependencies |
|---|---|---|---|---|
| Q1 | Homepage title → `Free team chat & scheduling for sports teams · Battleplan`; meta description as in §3; copy both to `og:` and `twitter:` | High | 15 min | None |
| Q2 | Homepage whiteboard: add Softball and Save as GIF chips and the new copy (§3) | High | 30 min | None |
| Q3 | Homepage eyebrow `Team chat for groups and sports teams`; lead adds "and groups" | Medium | 15 min | Jared's OK on hero wording (design) |
| Q4 | `/switch`: new title, meta, and H1; Get Started call to action; badge letters out of the H2s; a "Why teams switch" line | High | 1 hr | None |
| Q5 | Add `/switch` (and each new page as it ships) to the footer of every HTML file | Medium | 30 min | README "all HTML files" rule |
| Q6 | Fix the stale FAQ "Can I change how my team looks?" in the HTML and JSON-LD | Medium | 15 min | None |
| Q7 | JSON-LD: `alternateName` on WebSite and SoftwareApplication; `sameAs` (App Store, Facebook page) on Organization; `twitter:image:alt` on subpages | Medium | 20 min | Facebook page URL |
| Q8 | **Jared:** verify getbattleplan.app in Google Search Console (Domain property, DNS TXT) and Bing Webmaster Tools; submit `sitemap.xml`; request indexing of `/` and `/switch` | **Critical** | 30 min | DNS access |
| Q9 | Dev site `noindex`: `tools/build_hosting.sh dev` adds a robots `noindex` meta to the website pages | Medium | 30–60 min | Dev deploy |
| Q10 | **Jared:** free listings on AlternativeTo (as an alternative to GroupMe, TeamSnap, TeamReach, BAND, Spond), Capterra/GetApp, G2, Product Hunt | High (links and referrals) | 1–2 hrs | His accounts |
| Q11 | `llms.txt`: add softball to the whiteboard line | Low | 5 min | None |

#### Strategic investments (this quarter)

| # | Action | Expected impact | Effort | Dependencies |
|---|---|---|---|---|
| S1 | Build `/baseball-whiteboard` (§8.1) with a looping play animation | High | Half day + export | Save as GIF export → WebP or video; screenshots per README |
| S2 | Build `/team-chat` (§8.2) | High | Half day | — |
| S3 | Build `/team-dues` (§8.3) | High | Half day | — |
| S4 | Build `/teamsnap-alternative` and `/groupme-alternative` (§8.5–8.6) | High | 1 day | Facts reviewed and dated; trademark fineprint |
| S5 | Build `/team-schedule` (§8.4) and `/groups` (§8.7) | Medium | 1 day | — |
| S6 | Link the homepage tiles and spotlights to the new pages; add a footer Features list | High | 1 hr | S1–S5 |
| S7 | Animated baseball play library (§8.8), 5 plays to start | Medium–High (link magnet) | Multi-day | Plays drawn in the app; GIF export |
| S8 | App Store keywords: App Store listings rank on Google for whiteboard searches. Consider "plays", "whiteboard", "dues", "group" in the keyword field (today: `coach,sports,roster,attendance,practice,league,parents,baseball,softball,soccer,basketball,football`) or the subtitle | Medium | 1 hr | Next app version; STORE-LISTING rules |
| S9 | Outreach: ask to be added to "best free team apps" roundups (sportplan.net, psu.com, DialMyCalls, TeamLinkt's list); share plays with youth baseball communities (r/BaseballCoaching, Facebook coaching groups, following their rules); links from Battle Baseball's site and social channels; local league pages | High (authority) | Ongoing, 2 hrs/week | S1, S7 give something to share |
| S10 | Social proof: collect real coach quotes and show the App Store rating; mark up ratings only when real and visible | Medium | 2 hrs once quotes exist | Users |
| S11 | Google Play: when it's live, add the badge (the `<template>` is ready), `operatingSystem` "iOS, iPadOS, Android, Web", and `sameAs` | Medium | 30 min | Play production release |
| S12 | Measure monthly in Search Console: impressions and clicks per page and query; refresh titles where impressions are high and clicks low | Medium | 30 min/month | Q8 |
| S13 | Later: `/plays` hub with basketball, soccer, and football pages; `/baseball-team-app`; `/youth-teams` (owner's wording decision) | Medium | 1–2 days | S1 results |

---

### 10. Sources

Keyword and competitor research (web searches and page fetches, 2026-11-09):

- [BenchApp homepage](https://www.benchapp.com/), [team chat page](https://www.benchapp.com/features/team-chat), [best TeamSnap alternatives](https://www.benchapp.com/blog/best-teamsnap-alternatives), [best free team management apps](https://www.benchapp.com/blog/best-free-sports-team-management-apps)
- [Spond: best team chat and scheduling app](https://www.spond.com/en-us/news-and-blog/best-team-chat-and-scheduling-app/), [Spond: app for coaches to communicate with parents](https://www.spond.com/en-us/add-guardians/)
- [TeamSnap homepage](https://www.teamsnap.com/), [Heja homepage](https://heja.io/)
- [GroupMe: best team communication app for youth baseball](https://groupme.com/blog/best-team-communication-app-for-youth-baseball-groupme-for-coaches-parents-players), [GroupMe export help](https://support.microsoft.com/en-us/groupme/how-do-i-export-my-groupme-data)
- [Jersey Watch: best communication apps for sports teams](https://www.jerseywatch.com/blog/best-communication-apps-for-sports-teams), [Jersey Watch: sports team payment apps](https://www.jerseywatch.com/blog/sports-team-payment-apps), [TeamLinkt comparison](https://teamlinkt.com/comparing-team-chat-platforms), [The Futures App ranking](https://www.thefuturesapp.com/news/the-best-team-communication-apps-in-2026-(ranked)), [DialMyCalls](https://www.dialmycalls.com/blog/best-group-text-app-for-sports-teams)
- [TeamSideline vs TeamSnap](https://go.teamsideline.com/teamsnap-alternative-teamsideline), [Cactusware: TeamSnap free alternative](https://www.cactusware.com/blog/teamsnap-free-alternative), [AlternativeTo: TeamSnap](https://alternativeto.net/software/teamsnap/), [AlternativeTo: GroupMe](https://alternativeto.net/software/groupme), [Capterra: TeamSnap alternatives](https://www.capterra.com/p/123208/TeamSnap/alternatives/)
- [GameChanger: what is GameChanger](https://help.gc.com/hc/en-us/articles/115005511266-What-is-GameChanger)
- Whiteboard tools: [Baseball WhiteBoard](https://apps.apple.com/app/id317282434), [Baseball Board](https://apps.apple.com/us/app/id6751254549), [Baseball Board – Tactics](https://apps.apple.com/app/id6763575410), [TacticalPad](https://apps.apple.com/app/id512949303), [tactical-board.com baseball](https://tactical-board.com/uk/baseball), [ConceptDraw cutoff diagrams](https://www.conceptdraw.com/examples/baseball-cutoffs-and-relays-diagrams)
- Workplace results: [RingCentral](https://www.ringcentral.com/us/en/blog/team-messaging-apps/), [Pumble](https://pumble.com/best-team-messaging-apps), [ClickUp](https://clickup.com/blog/team-chat-apps/)
- Dues apps: [TeamTracky](https://apps.apple.com/us/app/teamtracky/id977344537), [Team Dues](https://apps.apple.com/us/app/id6569254949), [Team Fund Tracker](https://apps.apple.com/bf/app/team-fund-tracker/id6499107887)
- Snack sign-ups: [SignUp team snack schedule](https://blog.signup.com/SignUp-Sheet/Team-Snack-Schedule), [SignUpGenius](https://www.signupgenius.com/resources/youth-sports-organization)
- Brand clash: [Slitherine's Battleplan](https://www6.slitherine.com/game/battleplan), [Battle Plan SWAT Tactics](https://apps.apple.com/us/app/-/id6757082641)

Site checks: live `curl` of every page, header, redirect, and link on getbattleplan.app and the Firebase default domains (2026-11-09); files in `website/`, `firebase.json`, `tools/build_hosting.sh`, `docs/STORE-LISTING.md`.
