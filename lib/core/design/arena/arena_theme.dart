// Gumdrop Arena (SPEC §7.4, owner's request 2026-10-26): Gumdrop Pop's
// layout with a game-day "battle" feel, from the V3 design. A deep violet
// page, the same candy accents, gumdrops that lean, cards with two corners
// cut off, and headings and labels in Barlow Condensed ExtraBold Italic.
//
// It's kept apart so it can come out cleanly (ARCH §5.5). To remove it:
// delete this folder, assets/fonts/barlow_condensed/ (and its pubspec and
// fontLicenseAssets entries), test/arena_theme_test.dart, and
// test/goldens/arena_golden_test.dart with its *_arena.png images; remove
// `arena` from GumdropFlavor and from themePreference in
// shared/constants.json (then run tools/gen_constants.dart); and follow the
// analyzer to the few switches and the theme list (theme_choices.dart) that
// name it. Widgets that draw differently where gumdrops lean need no
// change. Accounts set to it then read as Gumdrop Pop Dark, as an unknown
// value does.
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// Barlow Condensed ExtraBold Italic, Arena's headings and labels: the one
/// style of the family that's bundled, to keep the app small.
const arenaFont = 'Barlow Condensed';

/// Gumdrop Arena's colors (design V3): a deep violet page, violet cards and
/// buttons, and Gumdrop Pop Dark's candies.
const arenaColors = GumdropColors(
  flavor: GumdropFlavor.arena,
  page: Color(0xFF0F0D24),
  surface: Color(0xFF221D45),
  surfaceBorder: Color(0x0FFFFFFF),
  surfaceBorderWidth: 1,
  raisedFace: Color(0xFF322D61),
  raisedBorder: Color(0x00000000),
  raisedBorderWidth: 0,
  raisedHighlight: Color(0x1AFFFFFF),
  raisedLip: Color(0xFF0B0920),
  well: Color(0xFF0E0C22),
  inputFill: Color(0xFF0E0C22),
  inputBorder: Color(0xFF3E3874),
  divider: Color(0xFF3E3874),
  switchOffTrack: Color(0xFF322D61),
  textPrimary: Color(0xFFF6F4FF),
  textMuted: Color(0xFFBCB6E3),
  textOnPage: Color(0xFFF6F4FF),
  textMutedOnPage: Color(0xFFBCB6E3),
  successOnPage: Color(0xFF5FE69A),
  ink: Color(0xFF14112B),
  headingText: Color(0xFFFFFFFF),
  headingShadow: Color(0xFF2A63C9),
  headingTextOnCard: Color(0xFFFFFFFF),
  headingShadowOnCard: Color(0xFF2A63C9),
  pageShadow: Color(0xFF2A63C9),
  selectedRingOuter: Color(0xFFF6F4FF),
  swatchInsetRing: Color(0x2EFFFFFF),
  badgeRing: Color(0xFF0F0D24),
  you: GumdropAccent(
    face: Color(0xFF4D9BFF),
    lip: Color(0xFF2A63C9),
    text: Color(0xFF4D9BFF),
  ),
  blueRaspberry: GumdropAccent(
    face: Color(0xFF4D9BFF),
    lip: Color(0xFF2A63C9),
    text: Color(0xFF4D9BFF),
  ),
  lemon: GumdropAccent(
    face: Color(0xFFFFD84A),
    lip: Color(0xFFC2950B),
    text: Color(0xFFFFD84A),
  ),
  mint: GumdropAccent(
    face: Color(0xFF4DDC8C),
    lip: Color(0xFF1F9A55),
    text: Color(0xFF5FE69A),
  ),
  cherry: GumdropAccent(
    face: Color(0xFFFF5D73),
    lip: Color(0xFFC42A45),
    text: Color(0xFFFF7A8C),
  ),
  tangerine: GumdropAccent(
    face: Color(0xFFFF9B42),
    lip: Color(0xFFC7600C),
    text: Color(0xFFFF9B42),
  ),
  grape: GumdropAccent(
    face: Color(0xFFA88BFF),
    lip: Color(0xFF6E4FD6),
    text: Color(0xFFA88BFF),
  ),
  bubblegum: GumdropAccent(
    face: Color(0xFFFF7AC8),
    lip: Color(0xFFC93E91),
    text: Color(0xFFFF7AC8),
  ),
);

/// Gumdrop Arena's shapes and type (design V3): headings and labels in the
/// condensed italic, a single 3 px hard shadow under headings, gumdrops
/// leaning 11° with 7 px corners, and cards with their top right and bottom
/// left corners cut 12 px.
const arenaStyle = GumdropStyle(
  displayFont: arenaFont,
  labelFont: arenaFont,
  fontWeight: FontWeight.w800,
  fontStyle: FontStyle.italic,
  headingShadowOffset: 3,
  slant: 11,
  buttonRadius: BorderRadius.all(Radius.circular(7)),
  cardCut: 12,
);
