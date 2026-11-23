import 'package:battleplan/core/constants.g.dart';
import 'package:material_ui/material_ui.dart';

/// One Boot Camp Mix color scheme's tokens (#85, owner's pick 2026-11-22:
/// "let's replace the existing themes with these 3 themes"; SPEC §7.4):
/// Army green, Black, and Light, and since #86 Sky Blue, Candy Pop,
/// Central Wildcat, and Geaux Tigahs. Every color the look draws comes from
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
  });

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

  /// Lettering on panels: the page's [text], but navy on Candy Pop's white
  /// panels (#86), the one scheme with two lettering colors.
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
  /// also being the background color of the boxes)"): a sky-blue page and
  /// boxes the same sky blue, set off by navy outlines and hard shadows
  /// (the page keeps its dots, the boxes are plain), navy for every word,
  /// and a navy and sky camouflage with white lettering.
  static const sky = CampPalette(
    ink: Color(0xFF0B1531),
    shadow: Color(0xFF0B1531),
    page: Color(0xFFBCD9F5),
    pageDots: Color(0x210B1531),
    panel: Color(0xFFBCD9F5),
    tabBar: Color(0xFFBCD9F5),
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

  /// Candy Pop (#86, owner's request: "Candy Pop (royal blue/white)"): a
  /// bright blue page under white lettering, white panels under navy
  /// lettering and navy-gray small print, navy ink and tab bar, and
  /// candy-bright accents.
  static const candyPop = CampPalette(
    ink: Color(0xFF0B1640),
    shadow: Color(0xFF0B1640),
    page: Color(0xFF1748D4),
    pageDots: Color(0x21FFFFFF),
    panel: Color(0xFFFFFFFF),
    tabBar: Color(0xFF0B1640),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFDCE6FF),
    panelText: Color(0xFF0B1640),
    panelMuted: Color(0xFF4B5A8C),
    mustard: Color(0xFFFFD43A),
    balloon: Color(0xFFFFD43A),
    red: Color(0xFFF2473D),
    blue: Color(0xFF35B0FF),
    green: Color(0xFF5ED36A),
    orange: Color(0xFFFF9A2E),
    purple: Color(0xFFB58BFF),
    unansweredTag: Color(0xFFC9D3EE),
    answerRow: Color(0xFFFFF1B0),
    toolsRow: Color(0xFF1240B8),
    disabledIcon: Color(0xFFA3B0D6),
    camoGround: Color(0xFF1238A8),
    camoBig: Color(0xFF0C2A86),
    camoMid: Color(0xFF3F6FF2),
    camoSmall: Color(0xFF0B1640),
    headerHalftone: Color(0x38FFFFFF),
    headerLettering: Color(0xFFFFFFFF),
    ballChain: Color(0xFFDCE6FF),
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
}
