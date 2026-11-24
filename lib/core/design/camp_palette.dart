import 'package:battleplan/core/constants.g.dart';
import 'package:material_ui/material_ui.dart';

/// One Boot Camp Mix color scheme's tokens (#85, owner's pick 2026-11-22:
/// "let's replace the existing themes with these 3 themes"; SPEC §7.4):
/// Army green, Black, and Light, since #86 Sky Blue, Candy Pop (Royal &
/// Gold since #90), Central Wildcat, and Geaux Tigahs, since #89 Graphite,
/// Teal Wave, Navy Steel, and Forest, since #90 Tropic Blue and Desert
/// Tan, and since #98 Sugar Rush. Every color the look draws comes from
/// here; `SchemeRoles` and `GumdropColors` are built from it.
@immutable
final class CampPalette {
  const new({
    required this.ink,
    required this.shadow,
    required this.page,
    required this.pageDots,
    required this.panel,
    required this.tabBar,
    required this.text,
    required this.muted,
    required this.panelText,
    required this.panelMuted,
    required this.mustard,
    required this.balloon,
    required this.red,
    required this.blue,
    required this.green,
    required this.orange,
    required this.purple,
    required this.unansweredTag,
    required this.answerRow,
    required this.toolsRow,
    required this.disabledIcon,
    required this.camoGround,
    required this.camoBig,
    required this.camoMid,
    required this.camoSmall,
    required this.headerHalftone,
    required this.headerLettering,
    required this.ballChain,
    this.touches = CandyTouches.none,
  });

  /// The scheme's own candy touches past its colors: Sugar Rush's (#98),
  /// none in the others.
  final CandyTouches touches;

  /// Every outline, and the lettering on any bright block.
  final Color ink;

  /// The hard offset shadows under panels, buttons and titles: ink, but
  /// olive drab on Black's page, so panels still stand off it.
  final Color shadow;

  /// The page, under its 8 px grid of [pageDots].
  final Color page;
  final Color pageDots;

  /// Panels, speech balloons, push buttons, fields, and sheets.
  final Color panel;
  final Color tabBar;

  /// Lettering on the page and on panels.
  final Color text;

  /// Times, places, and other second lines.
  final Color muted;

  /// Lettering on panels: the page's [text], but navy on Tropic Blue's white
  /// panels (#90; Candy Pop's before), the one scheme with two lettering
  /// colors.
  final Color panelText;

  /// Second lines on panels: [muted], or Candy Pop's navy-gray.
  final Color panelMuted;

  /// Tags, the current tab's tile, month labels, row badges, starbursts:
  /// mustard, or the scheme's own (Central Wildcat's silver, Geaux Tigahs'
  /// gold, #86).
  final Color mustard;

  /// Your own speech balloon and the reaction you added: mustard, or light
  /// blue on Black.
  final Color balloon;

  /// Games, warnings, the send and + buttons.
  final Color red;

  /// Practices, Directions.
  final Color blue;

  /// Going: the picked answer, its stamp and count.
  final Color green;

  /// Maybe.
  final Color orange;

  /// Social events.
  final Color purple;

  /// Can't go, the same in every scheme: its count and the picked answer.
  static const cantGo = Color(0xFFFF8A80);

  /// A title's fill, under its ink stroke: white in every scheme.
  static const titleFill = Color(0xFFFFFFFF);

  /// The dog tag of someone who hasn't answered.
  final Color unansweredTag;

  /// The answer row under a schedule panel.
  final Color answerRow;

  /// The whiteboard's tools row.
  final Color toolsRow;

  /// An icon that can't be used yet (redo with nothing to redo).
  final Color disabledIcon;

  /// The camouflage: its ground and three sizes of blotches.
  final Color camoGround;
  final Color camoBig;
  final Color camoMid;
  final Color camoSmall;

  /// The halftone that fades across the header from its top right.
  final Color headerHalftone;

  /// Lettering on the camouflage header: the page's text, but white on
  /// Sky Blue's blue camouflage (#86).
  final Color headerLettering;

  /// The ball chain the dog tags hang from.
  final Color ballChain;

  /// The token [color] names, as the theme editor shows and saves it (#88).
  Color colorOf(CampColor color) => switch (color) {
    CampColor.page => page,
    CampColor.panel => panel,
    CampColor.tabBar => tabBar,
    CampColor.ink => ink,
    CampColor.shadow => shadow,
    CampColor.text => text,
    CampColor.muted => muted,
    CampColor.panelText => panelText,
    CampColor.panelMuted => panelMuted,
    CampColor.headerLettering => headerLettering,
    CampColor.mustard => mustard,
    CampColor.balloon => balloon,
    CampColor.red => red,
    CampColor.blue => blue,
    CampColor.green => green,
    CampColor.orange => orange,
    CampColor.purple => purple,
    CampColor.unansweredTag => unansweredTag,
    CampColor.answerRow => answerRow,
    CampColor.toolsRow => toolsRow,
    CampColor.disabledIcon => disabledIcon,
    CampColor.camoGround => camoGround,
    CampColor.camoBig => camoBig,
    CampColor.camoMid => camoMid,
    CampColor.camoSmall => camoSmall,
    CampColor.ballChain => ballChain,
  };

  /// This palette with the theme editor's [colors] in place of its own
  /// (#88); the rest, and the see-through page dots and header halftone,
  /// as they are.
  CampPalette withColors(Map<CampColor, Color> colors) {
    if (colors.isEmpty) return this;
    Color pick(CampColor c) => colors[c] ?? colorOf(c);
    return CampPalette(
      ink: pick(CampColor.ink),
      shadow: pick(CampColor.shadow),
      page: pick(CampColor.page),
      pageDots: pageDots,
      panel: pick(CampColor.panel),
      tabBar: pick(CampColor.tabBar),
      text: pick(CampColor.text),
      muted: pick(CampColor.muted),
      panelText: pick(CampColor.panelText),
      panelMuted: pick(CampColor.panelMuted),
      mustard: pick(CampColor.mustard),
      balloon: pick(CampColor.balloon),
      red: pick(CampColor.red),
      blue: pick(CampColor.blue),
      green: pick(CampColor.green),
      orange: pick(CampColor.orange),
      purple: pick(CampColor.purple),
      unansweredTag: pick(CampColor.unansweredTag),
      answerRow: pick(CampColor.answerRow),
      toolsRow: pick(CampColor.toolsRow),
      disabledIcon: pick(CampColor.disabledIcon),
      camoGround: pick(CampColor.camoGround),
      camoBig: pick(CampColor.camoBig),
      camoMid: pick(CampColor.camoMid),
      camoSmall: pick(CampColor.camoSmall),
      headerHalftone: headerHalftone,
      headerLettering: pick(CampColor.headerLettering),
      ballChain: pick(CampColor.ballChain),
      touches: touches,
    );
  }

  /// Army green: an olive page, panels a shade lighter, cream lettering,
  /// woodland camouflage.
  static const army = CampPalette(
    ink: Color(0xFF1A1A18),
    shadow: Color(0xFF1A1A18),
    page: Color(0xFF474C2B),
    pageDots: Color(0x331A1A18),
    panel: Color(0xFF575A3A),
    tabBar: Color(0xFF3D4124),
    text: Color(0xFFF4EAD0),
    muted: Color(0xFFD3CCAE),
    panelText: Color(0xFFF4EAD0),
    panelMuted: Color(0xFFD3CCAE),
    mustard: Color(0xFFF2C230),
    balloon: Color(0xFFF2C230),
    red: Color(0xFFDB442F),
    blue: Color(0xFF5FA3C8),
    green: Color(0xFF9AD04A),
    orange: Color(0xFFF5A040),
    purple: Color(0xFFAD8CD6),
    unansweredTag: Color(0xFF7E8160),
    answerRow: Color(0xFF4C5130),
    toolsRow: Color(0xFF4C5130),
    disabledIcon: Color(0xFF8E9173),
    camoGround: Color(0xFF3F4722),
    camoBig: Color(0xFF2A3016),
    camoMid: Color(0xFF7F7A48),
    camoSmall: Color(0xFF14170B),
    headerHalftone: Color(0x33F4EAD0),
    headerLettering: Color(0xFFF4EAD0),
    ballChain: Color(0xFF1A1A18),
  );

  /// Black: a black page, charcoal panels, cream lettering, night
  /// camouflage; olive drab shadows, and your own balloons light blue.
  static const black = CampPalette(
    ink: Color(0xFF000000),
    shadow: Color(0xFF363A28),
    page: Color(0xFF0D0D0C),
    pageDots: Color(0x0EF4EAD0),
    panel: Color(0xFF252522),
    tabBar: Color(0xFF070707),
    text: Color(0xFFF4EAD0),
    muted: Color(0xFFB5B1A2),
    panelText: Color(0xFFF4EAD0),
    panelMuted: Color(0xFFB5B1A2),
    mustard: Color(0xFFF2C230),
    balloon: Color(0xFF93CFF5),
    red: Color(0xFFDB442F),
    blue: Color(0xFF4F93B9),
    green: Color(0xFF8DC63F),
    orange: Color(0xFFF2983A),
    purple: Color(0xFF9B79C4),
    unansweredTag: Color(0xFF47473F),
    answerRow: Color(0xFF1B1B19),
    toolsRow: Color(0xFF1A1A18),
    disabledIcon: Color(0xFF64645C),
    camoGround: Color(0xFF23241F),
    camoBig: Color(0xFF161713),
    camoMid: Color(0xFF3A3C33),
    camoSmall: Color(0xFF070706),
    headerHalftone: Color(0x1FF4EAD0),
    headerLettering: Color(0xFFF4EAD0),
    ballChain: Color(0xFF77786E),
  );

  /// Light: a sand page, white panels, black lettering for every outline
  /// and word, desert camouflage.
  static const light = CampPalette(
    ink: Color(0xFF1A1A18),
    shadow: Color(0xFF1A1A18),
    page: Color(0xFFF2EBE0),
    pageDots: Color(0x1A1A1A18),
    panel: Color(0xFFFFFFFF),
    tabBar: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A18),
    muted: Color(0xFF5E584B),
    panelText: Color(0xFF1A1A18),
    panelMuted: Color(0xFF5E584B),
    mustard: Color(0xFFEFBE2B),
    balloon: Color(0xFFEFBE2B),
    red: Color(0xFFD4432C),
    blue: Color(0xFF4A86A8),
    green: Color(0xFF86B93B),
    orange: Color(0xFFEE9230),
    purple: Color(0xFF8C68AD),
    unansweredTag: Color(0xFFDCD3C3),
    answerRow: Color(0xFFFAEDB2),
    toolsRow: Color(0xFFE6DCCB),
    disabledIcon: Color(0xFFB2AB9B),
    camoGround: Color(0xFFC7B787),
    camoBig: Color(0xFFA69468),
    camoMid: Color(0xFFE0D4AC),
    camoSmall: Color(0xFF6E6143),
    headerHalftone: Color(0x73FFFFFF),
    headerLettering: Color(0xFF1A1A18),
    ballChain: Color(0xFF1A1A18),
  );

  /// Sky Blue (#86, owner's request 2026-11-22: "Sky Blue (with sky blue
  /// also being the background color of the boxes)"; since #90, 2026-11-23:
  /// "update the sky blue theme to be like the new mockup with the white
  /// boxes", style 49): a sky-blue page, white boxes and tab bar, navy
  /// outlines and hard shadows, navy for every word, and a navy and sky
  /// camouflage with white lettering.
  static const sky = CampPalette(
    ink: Color(0xFF0B1531),
    shadow: Color(0xFF0B1531),
    page: Color(0xFFBCD9F5),
    pageDots: Color(0x210B1531),
    // White boxes and tab bar since #90 (the page's sky blue before).
    panel: Color(0xFFFFFFFF),
    tabBar: Color(0xFFFFFFFF),
    text: Color(0xFF0B1531),
    muted: Color(0xFF34476E),
    panelText: Color(0xFF0B1531),
    panelMuted: Color(0xFF34476E),
    mustard: Color(0xFFF5C731),
    balloon: Color(0xFFF5C731),
    red: Color(0xFFE2463A),
    blue: Color(0xFF4C90E2),
    green: Color(0xFF7CC84E),
    orange: Color(0xFFF5943A),
    purple: Color(0xFFA98BEB),
    unansweredTag: Color(0xFFE6F1FC),
    answerRow: Color(0xFFFBEFB4),
    toolsRow: Color(0xFFA9CBEE),
    disabledIcon: Color(0xFF6F86AB),
    camoGround: Color(0xFF2F5596),
    camoBig: Color(0xFF1E3A70),
    camoMid: Color(0xFF6390CC),
    camoSmall: Color(0xFF0E1D42),
    headerHalftone: Color(0x57FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFF0B1531),
  );

  /// Royal & Gold (#90, owner's request 2026-11-23: "replace the candy pop
  /// theme with the Royal and Gold theme"; the mockups' style 45), in Candy
  /// Pop's place and its stored value: a royal-blue page, panels a shade
  /// lighter, white lettering, gold trim and balloons, practices in sky blue
  /// so they show on the royal, and a royal camouflage.
  static const royalGold = CampPalette(
    ink: Color(0xFF050B24),
    shadow: Color(0xFF050B24),
    page: Color(0xFF17307F),
    pageDots: Color(0x12FFFFFF),
    panel: Color(0xFF22409E),
    tabBar: Color(0xFF0E1E54),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFC9D3F2),
    panelText: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFC9D3F2),
    mustard: Color(0xFFF5C431),
    balloon: Color(0xFFF5C431),
    red: Color(0xFFE8473A),
    blue: Color(0xFF6FC0FF),
    green: Color(0xFF86D04F),
    orange: Color(0xFFF79A3C),
    purple: Color(0xFFC3A6FF),
    unansweredTag: Color(0xFF4560B0),
    answerRow: Color(0xFF13286A),
    toolsRow: Color(0xFF1A3486),
    disabledIcon: Color(0xFF7A8CC4),
    camoGround: Color(0xFF1B3690),
    camoBig: Color(0xFF112468),
    camoMid: Color(0xFF2F52B8),
    camoSmall: Color(0xFF070F33),
    headerHalftone: Color(0x24FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFF5C431),
  );

  /// Central Wildcats (#86, owner's request: "Central Wildcats
  /// (maroon)"): a maroon page, panels a shade lighter, white lettering,
  /// black ink and tab bar, and silver where the others have mustard.
  /// Colors only: no school's name, logo, or mark.
  static const wildcat = CampPalette(
    ink: Color(0xFF0B0B0B),
    shadow: Color(0xFF0B0B0B),
    page: Color(0xFF5E1224),
    pageDots: Color(0x1CC0C5CC),
    panel: Color(0xFF701C30),
    tabBar: Color(0xFF0B0B0B),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFCDD1D8),
    panelText: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFCDD1D8),
    mustard: Color(0xFFC9CED6),
    balloon: Color(0xFFC9CED6),
    red: Color(0xFFEE4B37),
    blue: Color(0xFF5FA8E0),
    green: Color(0xFF86C94A),
    orange: Color(0xFFF59A3A),
    purple: Color(0xFFB08AE0),
    unansweredTag: Color(0xFF8A5562),
    answerRow: Color(0xFF5A1525),
    toolsRow: Color(0xFF681A2E),
    disabledIcon: Color(0xFFA88892),
    camoGround: Color(0xFF55111F),
    camoBig: Color(0xFF350A14),
    camoMid: Color(0xFF8A2E42),
    camoSmall: Color(0xFF0B0B0B),
    headerHalftone: Color(0x24FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFC0C5CC),
  );

  /// Geaux Tigahs (#86, owner's request: "Geaux Tigahs (purple)"): a purple
  /// page, panels a shade lighter, white lettering, and gold where the
  /// others have mustard; social events in lavender so they show on the
  /// purple. Colors only: no school's name, logo, or mark.
  static const purpleGold = CampPalette(
    ink: Color(0xFF170730),
    shadow: Color(0xFF170730),
    page: Color(0xFF461D7C),
    pageDots: Color(0x1CFDD023),
    panel: Color(0xFF55278F),
    tabBar: Color(0xFF2E1157),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFD5C6F0),
    panelText: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFD5C6F0),
    mustard: Color(0xFFFDD023),
    balloon: Color(0xFFFDD023),
    red: Color(0xFFE8473A),
    blue: Color(0xFF5AA5EE),
    green: Color(0xFF7FCB52),
    orange: Color(0xFFF79A3C),
    purple: Color(0xFFC7A6FF),
    unansweredTag: Color(0xFF7A56AE),
    answerRow: Color(0xFF481F7C),
    toolsRow: Color(0xFF4E2287),
    disabledIcon: Color(0xFF9A86C0),
    camoGround: Color(0xFF3F1A72),
    camoBig: Color(0xFF2A0F50),
    camoMid: Color(0xFF6C3DB0),
    camoSmall: Color(0xFF150628),
    headerHalftone: Color(0x29FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFFDD023),
  );

  /// Graphite (#89, owner's request 2026-11-23: "add Slate & Coral theme but
  /// call it "Graphite""; the mockup's style 47): a slate page, panels a
  /// shade lighter, coral trim and balloons, and games, send and alerts a
  /// deeper coral, since a true red clashed with it.
  static const graphite = CampPalette(
    ink: Color(0xFF070A0D),
    shadow: Color(0xFF070A0D),
    page: Color(0xFF2B323B),
    pageDots: Color(0x0FF1F4F7),
    panel: Color(0xFF3A434E),
    tabBar: Color(0xFF1E242B),
    text: Color(0xFFF1F4F7),
    muted: Color(0xFFAEB8C4),
    panelText: Color(0xFFF1F4F7),
    panelMuted: Color(0xFFAEB8C4),
    mustard: Color(0xFFFF7F66),
    balloon: Color(0xFFFF7F66),
    red: Color(0xFFF26A50),
    blue: Color(0xFF5AA7F0),
    green: Color(0xFF8DC63F),
    orange: Color(0xFFF5A93A),
    purple: Color(0xFFB49AF0),
    unansweredTag: Color(0xFF4F5966),
    answerRow: Color(0xFF2E2A2D),
    toolsRow: Color(0xFF2F3740),
    disabledIcon: Color(0xFF6F7A87),
    camoGround: Color(0xFF333B45),
    camoBig: Color(0xFF232A32),
    camoMid: Color(0xFF4A5562),
    camoSmall: Color(0xFF12161B),
    headerHalftone: Color(0x1FFFFFFF),
    headerLettering: Color(0xFFF1F4F7),
    ballChain: Color(0xFFFF7F66),
  );

  /// Teal Wave (#89, "Also add the Teal Wave theme."; style 43): a deep
  /// teal page, aqua trim, your balloons coral, teal camouflage.
  static const tealWave = CampPalette(
    ink: Color(0xFF021214),
    shadow: Color(0xFF021214),
    page: Color(0xFF0B3B40),
    pageDots: Color(0x12F0FBFA),
    panel: Color(0xFF135058),
    tabBar: Color(0xFF062A2E),
    text: Color(0xFFF0FBFA),
    muted: Color(0xFFA9D3D0),
    panelText: Color(0xFFF0FBFA),
    panelMuted: Color(0xFFA9D3D0),
    mustard: Color(0xFF5CE1D3),
    balloon: Color(0xFFFF8D75),
    red: Color(0xFFFF6B57),
    blue: Color(0xFF5AA7F0),
    green: Color(0xFF8DD85A),
    orange: Color(0xFFFFB347),
    purple: Color(0xFFB99AF0),
    unansweredTag: Color(0xFF3D6B70),
    answerRow: Color(0xFF0A3035),
    toolsRow: Color(0xFF10464D),
    disabledIcon: Color(0xFF5F8E91),
    camoGround: Color(0xFF0E4A50),
    camoBig: Color(0xFF083338),
    camoMid: Color(0xFF1F6E73),
    camoSmall: Color(0xFF03191C),
    headerHalftone: Color(0x24F0FBFA),
    headerLettering: Color(0xFFF0FBFA),
    ballChain: Color(0xFF5FE0D6),
  );

  /// Navy Steel (#89, "Add Navy Steel theme to the app, as well"; style 39):
  /// a deep navy page, steel-gray panels, white lettering, trim and
  /// balloons, steel camouflage.
  static const navySteel = CampPalette(
    ink: Color(0xFF02060F),
    shadow: Color(0xFF02060F),
    page: Color(0xFF101D3A),
    pageDots: Color(0x12F2F6FF),
    panel: Color(0xFF2B3850),
    tabBar: Color(0xFF08101F),
    text: Color(0xFFF2F6FF),
    muted: Color(0xFFAFBACB),
    panelText: Color(0xFFF2F6FF),
    panelMuted: Color(0xFFAFBACB),
    mustard: Color(0xFFF2F5FA),
    balloon: Color(0xFFF2F5FA),
    red: Color(0xFFE2463A),
    blue: Color(0xFF5AA0E0),
    green: Color(0xFF7CC84E),
    orange: Color(0xFFF5943A),
    purple: Color(0xFFA98BEB),
    unansweredTag: Color(0xFF4A5670),
    answerRow: Color(0xFF1A2742),
    toolsRow: Color(0xFF22304A),
    disabledIcon: Color(0xFF6B7790),
    camoGround: Color(0xFF1C2840),
    camoBig: Color(0xFF121A2C),
    camoMid: Color(0xFF3A4760),
    camoSmall: Color(0xFF060A14),
    headerHalftone: Color(0x21F2F6FF),
    headerLettering: Color(0xFFF2F6FF),
    ballChain: Color(0xFF8E9AB4),
  );

  /// Forest (#89, "add the Forest & White theme, but call it "Forest" and
  /// make the forest green a tiny bit darker"; style 48, Forest & White's
  /// greens about 10% darker): a forest-green page, white lettering, trim and
  /// balloons, forest camouflage.
  static const forest = CampPalette(
    ink: Color(0xFF050D09),
    shadow: Color(0xFF050D09),
    page: Color(0xFF0F2E1F),
    pageDots: Color(0x0FFFFFFF),
    panel: Color(0xFF183E2C),
    tabBar: Color(0xFF081F14),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFB5CFC0),
    panelText: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFB5CFC0),
    mustard: Color(0xFFFFFFFF),
    balloon: Color(0xFFFFFFFF),
    red: Color(0xFFE5483A),
    blue: Color(0xFF5BA8E0),
    green: Color(0xFF8BDB5A),
    orange: Color(0xFFF5A03A),
    purple: Color(0xFFB794E8),
    unansweredTag: Color(0xFF375A48),
    answerRow: Color(0xFF0C2619),
    toolsRow: Color(0xFF14382A),
    disabledIcon: Color(0xFF6A897A),
    camoGround: Color(0xFF133524),
    camoBig: Color(0xFF0B2418),
    camoMid: Color(0xFF28543D),
    camoSmall: Color(0xFF05110B),
    headerHalftone: Color(0x21FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFCFE3D6),
  );

  /// Tropic Blue (#90, "Add the Tropic Blue theme to the app as well.";
  /// style 50): Candy Pop's arrangement, an ocean-blue page under white
  /// lettering and white panels under deep-sea navy lettering, sunny yellow
  /// trim and balloons, and a blue camouflage.
  static const tropicBlue = CampPalette(
    ink: Color(0xFF062033),
    shadow: Color(0xFF062033),
    // A hair deeper than the mockup's #0A84B4, so its white lettering
    // reads at 4.5:1 (WCAG AA, SPEC §7.6).
    page: Color(0xFF0A7EAC),
    pageDots: Color(0x21FFFFFF),
    panel: Color(0xFFFFFFFF),
    tabBar: Color(0xFF062A45),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFD8F1FF),
    panelText: Color(0xFF062033),
    panelMuted: Color(0xFF3D5F7A),
    mustard: Color(0xFFFFD23F),
    balloon: Color(0xFFFFD23F),
    red: Color(0xFFFF5A4E),
    blue: Color(0xFF4FCBF7),
    green: Color(0xFF4FD38A),
    orange: Color(0xFFFF9A2E),
    purple: Color(0xFFB58BFF),
    unansweredTag: Color(0xFFCDE7F2),
    answerRow: Color(0xFFFFF1B0),
    toolsRow: Color(0xFF0B76A3),
    disabledIcon: Color(0xFF9CC3D6),
    camoGround: Color(0xFF0A6E99),
    camoBig: Color(0xFF075478),
    camoMid: Color(0xFF1E9CC8),
    camoSmall: Color(0xFF04324A),
    headerHalftone: Color(0x38FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFFFD23F),
  );

  /// Desert Tan (#90, "also add the Desert Tan theme to the app"; style
  /// 38): a sand page, khaki-cream panels and tab bar, dark lettering, olive
  /// trim and balloons, and a khaki camouflage lettered in ink: a light
  /// scheme that reads in bright sun.
  static const desertTan = CampPalette(
    ink: Color(0xFF24231B),
    shadow: Color(0xFF24231B),
    page: Color(0xFFE4D6B4),
    pageDots: Color(0x1F24231B),
    panel: Color(0xFFF4ECD8),
    tabBar: Color(0xFFF4ECD8),
    text: Color(0xFF24231B),
    muted: Color(0xFF615A45),
    panelText: Color(0xFF24231B),
    panelMuted: Color(0xFF615A45),
    mustard: Color(0xFFA3A95A),
    balloon: Color(0xFFA3A95A),
    red: Color(0xFFC9452E),
    blue: Color(0xFF4A86A8),
    green: Color(0xFF6DB33F),
    orange: Color(0xFFE08A2E),
    purple: Color(0xFF8C68AD),
    unansweredTag: Color(0xFFD3C6A6),
    answerRow: Color(0xFFE6E2C0),
    toolsRow: Color(0xFFD8C9A5),
    disabledIcon: Color(0xFFA39A80),
    camoGround: Color(0xFFA8956A),
    camoBig: Color(0xFF8A7A52),
    camoMid: Color(0xFFC9B88C),
    camoSmall: Color(0xFF5C5236),
    headerHalftone: Color(0x47FFFFFF),
    headerLettering: Color(0xFF24231B),
    ballChain: Color(0xFF24231B),
  );

  /// Sugar Rush (#98, owner's go 2026-11-23: "also add the Sugar Rush theme
  /// as another theme option."; mockup 53): a vanilla page, white panels,
  /// deep grape ink and lettering, bubblegum trim and balloons, candy
  /// brights, and a cotton-candy camouflage lettered in grape, with its own
  /// candy touches ([CandyTouches.sugarRush]). A light scheme.
  static const sugarRush = CampPalette(
    ink: Color(0xFF2B1A4A),
    shadow: Color(0xFF2B1A4A),
    page: Color(0xFFFFF4EA),
    pageDots: Color(0x24FF5FA8),
    panel: Color(0xFFFFFFFF),
    tabBar: Color(0xFFFFFFFF),
    text: Color(0xFF2B1A4A),
    muted: Color(0xFF6E5F87),
    panelText: Color(0xFF2B1A4A),
    panelMuted: Color(0xFF6E5F87),
    mustard: Color(0xFFFF8CC6),
    balloon: Color(0xFFFF8CC6),
    red: Color(0xFFF2473D),
    blue: Color(0xFF35B0FF),
    green: Color(0xFF5ED36A),
    orange: Color(0xFFFF9A2E),
    purple: Color(0xFFB58BFF),
    unansweredTag: Color(0xFFEDE6F5),
    answerRow: Color(0xFFFFF0F7),
    toolsRow: Color(0xFFF5E1EE),
    disabledIcon: Color(0xFFB6A9C9),
    camoGround: Color(0xFFFFC4DD),
    camoBig: Color(0xFFFF9FCB),
    camoMid: Color(0xFFA9DCFF),
    camoSmall: Color(0xFFFFE27D),
    headerHalftone: Color(0x8CFFFFFF),
    headerLettering: Color(0xFF2B1A4A),
    ballChain: Color(0xFF2B1A4A),
    touches: CandyTouches.sugarRush,
  );
}

/// A scheme's own candy touches past its colors (#98): Sugar Rush's, none
/// in the others. They come with the scheme, fixed: the theme editor has
/// no roles for them, and keeps them whatever colors it sets.
@immutable
final class CandyTouches {
  const new({
    this.titleDrop,
    this.burst,
    this.panelLip,
    this.panelRadius,
    this.pills = false,
    this.stripes = false,
    this.candyDots = false,
    this.sprinkles,
    this.sprinkleCount,
    this.twinkles,
  });

  /// None: the other schemes'.
  static const none = CandyTouches();

  /// Sugar Rush's (mockup 53): a bubblegum drop under outlined titles,
  /// lemon starbursts, panels with corners of 20 on a lavender lip, pill
  /// buttons, candy-striped pennants and game headers, four-color page
  /// dots, and its own sprinkles and twinkles.
  static const sugarRush = CandyTouches(
    titleDrop: Color(0xFFFF5FA8),
    burst: Color(0xFFFFD43A),
    panelLip: Color(0xFFE3D7F7),
    panelRadius: 20,
    pills: true,
    stripes: true,
    candyDots: true,
    sprinkles: [
      Color(0xFFF2473D),
      Color(0xFF35B0FF),
      Color(0xFF5ED36A),
      Color(0xFFB58BFF),
      Color(0xFFFF9A2E),
      Color(0xFFFFFFFF),
    ],
    sprinkleCount: 50,
    twinkles: (first: Color(0xFFFFD43A), second: Color(0xFF8FD8FF)),
  );

  /// The drop under outlined titles (the team's name, a page's title), in
  /// place of the scheme's shadow.
  final Color? titleDrop;

  /// The starbursts' color, in place of the scheme's mustard.
  final Color? burst;

  /// Panels sit on a lip of this color, 7 deep with the ink carried round
  /// under it, in place of their hard offset shadow; unpicked push
  /// buttons take it for their lips too.
  final Color? panelLip;

  /// The panels' corners, in place of 15.
  final double? panelRadius;

  /// Whether push buttons are pills.
  final bool pills;

  /// Whether the date pennants and the chat's game header have candy
  /// stripes over the event's color: white at 20%, 7 wide every 18, at
  /// 135°.
  final bool stripes;

  /// Whether the page's dots are four candy colors on an 18 px grid.
  final bool candyDots;

  /// The header sprinkles' colors in turn, in place of the six candies,
  /// and how many to a 400 × 140 tile (40 elsewhere).
  final List<Color>? sprinkles;
  final int? sprinkleCount;

  /// The twinkles' two colors, in place of the light schemes' mustard and
  /// pink.
  final ({Color first, Color second})? twinkles;
}
