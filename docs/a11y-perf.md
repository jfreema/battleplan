# Accessibility and performance pass (task 105)

What the M9 pass checked and changed against SPEC §7.6 and §8.1, how it's tested, and what's still open.

## Tests

| File | What it checks |
|---|---|
| `test/accessibility_test.dart` | Flutter's `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, and `textContrastGuideline` on the main screens (sign-in, chat, schedule, event details, documents, admin dashboard) and on the team switcher, message menu, roster, settings, notifications, and calendar, in light and dark. The same screens at 200% text, with no overflow. Screen-reader labels ("Photo from Alex Kim", "Like, 2", the team switcher). RSVP answers shown with words and icons. Keyboard: Ctrl/⌘+K opens the team switcher from any tab, Esc closes sheets, dialogs, and menus, Enter sends and Shift+Enter doesn't, and Tab goes through the header, the chat, the composer, and then the tabs, with focus highlighting on. |
| `test/goldens/screens_golden_test.dart` | Golden images of the six main screens in light and dark at 390 × 844, drawn with the test font (text shows as boxes). Boxes draw the same on every OS, so these run in CI. |
| `test/goldens/screens_readable_golden_test.dart` | The same screens with real fonts at 2x, with real shadows, for reviewing by eye. Fonts rasterize differently on each OS, so these compare only on macOS, where they were made, and are skipped elsewhere. |
| `test/helpers/scenes.dart` | Fake data for those screens, shared by the goldens and the accessibility tests. Dates are fixed: the chat is in March 2025 and the schedule in October 2030, so the images don't change from day to day. |
| `test/helpers/golden.dart` | `loadAppFonts()` loads the fonts in the app's font manifest (Material Symbols, MaterialIcons) and Roboto from the Flutter SDK, standing in for Inter. `useTolerantGoldens()` allows 0.5% of pixels to differ, for small antialiasing differences between machines. |

The goldens are tagged `golden`, a tag declared in `dart_test.yaml`. A plain `flutter test` runs them, which is how CI runs them.

```sh
flutter test --tags golden                   # only the goldens
flutter test --exclude-tags golden           # everything else
flutter test --tags golden --update-goldens  # after an intended UI change; check the PNGs in the diff
```

Update goldens on macOS, so the readable set stays comparable. The test-font set in `test/goldens/ci/` is the one CI compares. If CI on Linux reports a small difference there, raise the tolerance in `useTolerantGoldens` rather than regenerating on Linux. Emoji show as empty boxes in both sets because the tests have no emoji font.

## Accessibility fixes

- **Labels.** Chat photos read "Photo from <name>" and act as buttons that open the viewer. The viewer reads "Photo, 2 of 3". Reaction chips read "Like, 2" instead of the emoji. The skeleton's "Loading" label is now translatable. Event rows read their type ("Game"), which the row otherwise shows only as an icon and color.
- **Screen-reader taps.** A `Semantics(excludeSemantics: true)` around an `InkWell` also drops the InkWell's tap, so screen readers couldn't activate the control. Four places did this; each now passes `onTap` to `Semantics`: the team switcher button, calendar day cells, reply quotes, and the push banner's dismiss button.
- **48 × 48 targets.**
  - Poll options are at least 48 tall.
  - A one-line chat bubble is 48 tall (vertical padding went from 8 to 12).
  - Reaction chips get a 48-point target through the new `TapTargetPadding` in `lib/core/widgets/tap_target.dart`, padded the way Material's buttons are, so the chip looks the same.
  - Reaction picker buttons are at least 48 × 48.
  - The storage banner's dismiss button is no longer compact.
- **Focus.** The theme adds a 3 px primary-colored ring to focused filled, outlined, text, icon, and segmented buttons. `focusColor` is stronger (primary at 24%) for InkWell rows. Material's default focus overlay was hard to see.
- **Large text.**
  - The schedule row's "You: Going" line wraps instead of overflowing.
  - The Documents filter and sort stack when text is above 130%.
  - Calendar day cells grow instead of clipping.
  - The message menu sheet scrolls.
- **Enter to send** no longer sends while an input method is still composing a word (CJK keyboards).

## Performance review (SPEC §8.1, ENG-5)

Fixed:

- **Lists built lazily.** The schedule's Upcoming and Past lists and the Documents list were `ListView(children: [...])`, which builds every row at once. Each schedule row looks up RSVPs, and each image document row fetches a download URL, so a list with more pages loaded built and fetched everything. All three now use `ListView.builder`.
- **Images decoded at display size.**
  - Chat photo thumbnails decode at the grid's width (`cacheWidth` = 280 × device pixel ratio), not the 2048 px upload. Photos still uploading do the same.
  - Avatars and team logos decode at their drawn size.
  - The full-screen viewer still decodes at full size.
  - Media and document thumbnails already set `cacheWidth`.

Reviewed and left as is:

- **Chat.** It's a reversed `ListView.builder`. Loading older pages is guarded against repeats, and rebuilds are limited to the screen and the tile that changed.
- **The chat's listener stays open on the Schedule and Documents tabs.** The shell keeps each tab alive (`StatefulShellRoute.indexedStack`), so the chat stays mounted. Its controller also holds the send queue and photo uploads, so closing it off-screen would drop messages that are still sending. It costs one listener on 50 messages per open team, and it's what makes going back to the chat instant (< 0.5 s, §8.1). Poll and event cards only listen while their rows are built.
- **Admin lists** (teams, users, audit, reports) build 50-row pages with plain tiles and no lookups per row. **Roster** and the **team switcher** lists are bounded by team size and team count.
- **Missing `const`** is caught by the analyzer (`very_good_analysis`).

## Measurements (headless, local)

These numbers come from `flutter build web` with Flutter 3.47.6, built from `lib/main_dev.dart` with `--base-href /app/`. The page was served from `localhost` by `python3 -m http.server` (no compression) and opened in Chrome.

| | Size |
|---|---|
| `main.dart.wasm` (`--wasm` build) | 5.39 MB raw, 1.87 MB gzipped |
| `main.dart.js` (JS fallback) | 6.32 MB raw, 1.61 MB gzipped, plus a 156 KB deferred part (the admin panel, D42) |
| `main.dart.mjs` | 59 KB |
| Engine, from gstatic: `skwasm.wasm` / `canvaskit.wasm` | 3.6 MB / 7.3 MB raw |
| Icon fonts after tree-shaking | Material Symbols Rounded 306 KB (from 15 MB), MaterialIcons 8 KB |
| Whole build folder | 54 MB, mostly engine variants and `.symbols` files that aren't downloaded |

On localhost with a warm cache, the sign-in screen finished drawing in about 0.9 s:

- DOMContentLoaded at 22 ms
- `main.dart.wasm` loaded at 190 ms
- Firebase SDKs loaded by about 670 ms
- `version.json` checked at about 900 ms

The page wasn't cross-origin isolated, so it ran skwasm in single-threaded mode. Cold first loads over broadband depend mostly on the roughly 2 MB of compressed app code plus the engine. Measure them on the deployed preview channel (which serves compressed files) against the < 4 s target.

## Open items for a human

1. **Inter isn't bundled.** ARCH §5.5 says fonts ship as assets, and the theme names `Inter`, but `pubspec.yaml` declares no fonts. On the web, Flutter falls back to downloading Roboto from `fonts.gstatic.com` at first load. That's an extra request to Google (LEGAL-2 no-tracking review) and a font that differs offline and between platforms. Fix: add the Inter font files under `assets/fonts/` with a `fonts:` entry in `pubspec.yaml`. This pass couldn't change `pubspec.yaml`. Once Inter is bundled, point `loadAppFonts()` at it instead of Roboto and run `--update-goldens`.
2. **ARCH §5.6 says images go through `cached_network_image`.** The app uses `Image.network` everywhere and that package isn't a dependency. Either add it (a decision-log entry) or correct the ARCH line. On the web, the browser's HTTP cache does the caching either way.
3. **VoiceOver and TalkBack on devices** (SPEC §7.6, "before launch") still need a person. The automated checks cover labels, actions, sizes, and contrast, but not reading order or how it sounds.
4. **Emoji in goldens** render as boxes. That's harmless, but the reaction chips can't be checked by eye in the PNGs.
