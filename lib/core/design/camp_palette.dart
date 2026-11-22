import 'package:material_ui/material_ui.dart';

/// One Boot Camp Mix color scheme's tokens (#85, owner's pick 2026-11-22:
/// "let's replace the existing themes with these 3 themes"; SPEC §7.4):
/// Army green, Black, and Light. Every color the look draws comes from
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

  /// Tags, the current tab's tile, month labels, row badges, starbursts.
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

  /// Lettering on the camouflage header.
  final Color headerLettering;

  /// The ball chain the dog tags hang from.
  final Color ballChain;

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
}
