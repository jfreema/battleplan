import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart' show GumdropColors;
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

export 'package:battleplan/core/scheme_defaults.dart';

/// The candy faces, the same in every scheme (SPEC §7.4).
abstract final class CandyFaces {
  static const coral = Color(0xFFF45B5B);
  static const cherry = Color(0xFFF45B5B);
  static const mint = Color(0xFF58C173);
  static const lemon = Color(0xFFF8D84A);
  static const tangerine = Color(0xFFEE8131);
  static const grape = Color(0xFFA57CF5);
  static const bubblegum = Color(0xFFEB50A2);
  static const blueRaspberry = Color(0xFF79BBFF);
}

/// The 32 color roles of one Open Field color scheme (SPEC SET-2, §7.4),
/// from the design's schemes.json, plus the seven values the app derives
/// for colors the design doesn't draw. [GumdropColors.forScheme] fills the
/// theme from them.
@immutable
class SchemeRoles {
  const new({
    required this.page,
    required this.text,
    required this.pageMuted,
    required this.hairline,
    required this.outline,
    required this.tabbar,
    required this.tabbarLine,
    required this.field,
    required this.fieldRim,
    required this.card,
    required this.cardRim,
    required this.cardMuted,
    required this.cardTrack,
    required this.cardOutline,
    required this.candyInk,
    required this.candyLipCoral,
    required this.candyLipMint,
    required this.candyLipLemon,
    required this.candyLipTangerine,
    required this.titleDrop,
    required this.avatarRing,
    required this.accentText,
    required this.accentMark,
    required this.notGoingIcon,
    required this.goingText,
    required this.maybeText,
    required this.cardGoingText,
    required this.cardAccentText,
    required this.gameText,
    required this.typeGame,
    required this.typePractice,
    required this.typeOther,
    required this.grapePageText,
    required this.bubblegumPageText,
    required this.blueRaspberryPageText,
    required this.blueRaspberryCardText,
    required this.grapeLip,
    required this.bubblegumLip,
    required this.blueRaspberryLip,
  });

  /// Page fill; ring around the unread dot and the badge; the game screen's bottom fade.
  final Color page;

  /// Main text and icons on the page, on cards and in the tab bar; status bar; home indicator; ring around the picked icon color.
  final Color text;

  /// Secondary text and icons on the page (times, jersey numbers, chevrons, labels, descriptions); idle tabs; composer hint.
  final Color pageMuted;

  /// Rules on the page: pinned row, day divider, Upcoming row, game rows, counts, people list, settings and Teams rows.
  final Color hairline;

  /// Outlines on the page: unpicked Maybe / Not going (game screen), Add a photo, the color scheme previews.
  final Color outline;

  /// Bottom tab bar fill.
  final Color tabbar;

  /// Rule along the top of the tab bar.
  final Color tabbarLine;

  /// Composer field fill; the "In chat" preview well (Your icon).
  final Color field;

  /// Thin inset ring around the composer field and the preview well (transparent: none).
  final Color fieldRim;

  /// Event card face; the team cards on the Teams screen.
  final Color card;

  /// Event card and team card outline + lip.
  final Color cardRim;

  /// Secondary text and icons on a card: weekday, month, time and place, attendance, RSVP name, unpicked choices; a team card's kind, last message and chevron.
  final Color cardMuted;

  /// Empty part of the attendance mini bar on a card.
  final Color cardTrack;

  /// Outline of the three choices on a card nobody has answered.
  final Color cardOutline;

  /// Text, icons and marks on candy faces: icons, team badges, badge and unread count, your poll bubble, picked RSVP, send, +, crest, picked color's check.
  final Color candyInk;

  /// Outline + lip of coral candy buttons: send, +, picked Not going.
  final Color candyLipCoral;

  /// Outline + lip of the picked Going button.
  final Color candyLipMint;

  /// Outline + lip of the picked Maybe button.
  final Color candyLipLemon;

  /// Outline + lip of the opponent crest.
  final Color candyLipTangerine;

  /// Hard drop under Lilita titles: team name, Teams, opponent, section and screen titles (transparent: none).
  final Color titleDrop;

  /// Thin inset ring on icons (initials or photo), team badges and the icon color swatches (transparent: none).
  final Color avatarRing;

  /// Coral as text on the page: the stencil eyebrow, the Not going count, the picked scheme's check.
  final Color accentText;

  /// Coral marks on the page: pin, underline under your reaction and under "open", Directions icon.
  final Color accentMark;

  /// The x on the unpicked Not going button on the page (game screen).
  final Color notGoingIcon;

  /// Going on the page: the Going count, the checks in the people list.
  final Color goingText;

  /// Maybe on the page and on cards: the Maybe count, the ? on unpicked Maybe buttons.
  final Color maybeText;

  /// The check on a card nobody has answered.
  final Color cardGoingText;

  /// Coral on a card: "Luke hasn’t answered" / "You haven’t answered", the x on a card nobody has answered.
  final Color cardAccentText;

  /// The game color as text on the page: "Game · Home" eyebrow, the clock by "In 5 days".
  final Color gameText;

  /// Type word GAME on a card.
  final Color typeGame;

  /// Type word PRACTICE on a card.
  final Color typePractice;

  /// Type word OTHER on a card.
  final Color typeOther;

  /// Derived: grape.text, page context.
  final Color grapePageText;

  /// Derived: bubblegum.text, page context.
  final Color bubblegumPageText;

  /// Derived: blueRaspberry.text, page context.
  final Color blueRaspberryPageText;

  /// Derived: blueRaspberry.text, card context.
  final Color blueRaspberryCardText;

  /// Derived: grape.lip.
  final Color grapeLip;

  /// Derived: bubblegum.lip.
  final Color bubblegumLip;

  /// Derived: blueRaspberry.lip.
  final Color blueRaspberryLip;

  static const army = SchemeRoles(
    page: Color(0xFF474C2B),
    text: Color(0xFFF4EAD0),
    pageMuted: Color(0xCCF4EAD0),
    hairline: Color(0x24F4EAD0),
    outline: Color(0x4CF4EAD0),
    tabbar: Color(0xFF3D4124),
    tabbarLine: Color(0x1AF4EAD0),
    field: Color(0xFF2B2F18),
    fieldRim: Color(0x00000000),
    card: Color(0xFF575A3A),
    cardRim: Color(0xFF1A1A18),
    cardMuted: Color(0xE0F4EAD0),
    cardTrack: Color(0x38F4EAD0),
    cardOutline: Color(0x73F4EAD0),
    candyInk: Color(0xFF1A1A18),
    candyLipCoral: Color(0xFF1A1A18),
    candyLipMint: Color(0xFF1A1A18),
    candyLipLemon: Color(0xFF1A1A18),
    candyLipTangerine: Color(0xFF1A1A18),
    titleDrop: Color(0xFF1A1A18),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFF9A5A5),
    accentMark: Color(0xFFF45B5B),
    notGoingIcon: Color(0xFFFBC0C0),
    goingText: Color(0xFFB5FAD0),
    maybeText: Color(0xFFF8D84A),
    cardGoingText: Color(0xFFB5FAD0),
    cardAccentText: Color(0xFFFBC0C0),
    gameText: Color(0xFFF4AD79),
    typeGame: Color(0xFFF8CDAD),
    typePractice: Color(0xFFDBCBFB),
    typeOther: Color(0xFFF8C2DE),
    grapePageText: Color(0xFFC9B0F9),
    bubblegumPageText: Color(0xFFF5A8D0),
    blueRaspberryPageText: Color(0xFF86C2FF),
    blueRaspberryCardText: Color(0xFFAFD6FF),
    grapeLip: Color(0xFF1A1A18),
    bubblegumLip: Color(0xFF1A1A18),
    blueRaspberryLip: Color(0xFF1A1A18),
  );

  static const light = SchemeRoles(
    page: Color(0xFFFBF5E6),
    text: Color(0xFF1A1A18),
    pageMuted: Color(0xFF5F5A4D),
    hairline: Color(0x1F1A1A18),
    outline: Color(0x4C1A1A18),
    tabbar: Color(0xFFFFFFFF),
    tabbarLine: Color(0xFF1A1A18),
    field: Color(0xFFEFE6CC),
    fieldRim: Color(0x00000000),
    card: Color(0xFFFFFFFF),
    cardRim: Color(0xFF1A1A18),
    cardMuted: Color(0xFF5F5A4D),
    cardTrack: Color(0x1F1A1A18),
    cardOutline: Color(0x661A1A18),
    candyInk: Color(0xFF1A1A18),
    candyLipCoral: Color(0xFF1A1A18),
    candyLipMint: Color(0xFF1A1A18),
    candyLipLemon: Color(0xFF1A1A18),
    candyLipTangerine: Color(0xFF1A1A18),
    titleDrop: Color(0x00000000),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFC0262F),
    accentMark: Color(0xFFC0262F),
    notGoingIcon: Color(0xFFC0262F),
    goingText: Color(0xFF137236),
    maybeText: Color(0xFF8F6500),
    cardGoingText: Color(0xFF137236),
    cardAccentText: Color(0xFFC0262F),
    gameText: Color(0xFF9E4B0A),
    typeGame: Color(0xFF9E4B0A),
    typePractice: Color(0xFF6C46CC),
    typeOther: Color(0xFFAE2770),
    grapePageText: Color(0xFF6C46CC),
    bubblegumPageText: Color(0xFFAE2770),
    blueRaspberryPageText: Color(0xFF2A63C9),
    blueRaspberryCardText: Color(0xFF2A63C9),
    grapeLip: Color(0xFF1A1A18),
    bubblegumLip: Color(0xFF1A1A18),
    blueRaspberryLip: Color(0xFF1A1A18),
  );

  static const dark = SchemeRoles(
    page: Color(0xFF0E0E0D),
    text: Color(0xFFF4EAD0),
    pageMuted: Color(0xBFF4EAD0),
    hairline: Color(0x1FF4EAD0),
    outline: Color(0x4CF4EAD0),
    tabbar: Color(0xFF161615),
    tabbarLine: Color(0x1AF4EAD0),
    field: Color(0xFF1F1F1C),
    fieldRim: Color(0x00000000),
    card: Color(0xFF1B1B19),
    cardRim: Color(0xFF363631),
    cardMuted: Color(0xC7F4EAD0),
    cardTrack: Color(0x2EF4EAD0),
    cardOutline: Color(0x73F4EAD0),
    candyInk: Color(0xFF1A1A18),
    candyLipCoral: Color(0xFFC0262F),
    candyLipMint: Color(0xFF137236),
    candyLipLemon: Color(0xFFA88A12),
    candyLipTangerine: Color(0xFF9E4B0A),
    titleDrop: Color(0x00000000),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFF76F6F),
    accentMark: Color(0xFFF45B5B),
    notGoingIcon: Color(0xFFF76F6F),
    goingText: Color(0xFF58C173),
    maybeText: Color(0xFFF8D84A),
    cardGoingText: Color(0xFF58C173),
    cardAccentText: Color(0xFFF76F6F),
    gameText: Color(0xFFEE8131),
    typeGame: Color(0xFFEE8131),
    typePractice: Color(0xFFA57CF5),
    typeOther: Color(0xFFF06AAF),
    grapePageText: Color(0xFFA57CF5),
    bubblegumPageText: Color(0xFFEB50A2),
    blueRaspberryPageText: Color(0xFF79BBFF),
    blueRaspberryCardText: Color(0xFF79BBFF),
    grapeLip: Color(0xFF6C46CC),
    bubblegumLip: Color(0xFFAE2770),
    blueRaspberryLip: Color(0xFF2A63C9),
  );

  static const navy = SchemeRoles(
    page: Color(0xFF0B1531),
    text: Color(0xFFF2F6FF),
    pageMuted: Color(0xFFB2BFE0),
    hairline: Color(0x1FF2F6FF),
    outline: Color(0x4CF2F6FF),
    tabbar: Color(0xFF07102A),
    tabbarLine: Color(0x1AF2F6FF),
    field: Color(0xFF07102A),
    fieldRim: Color(0x1AF2F6FF),
    card: Color(0xFF18284C),
    cardRim: Color(0xFF35466D),
    cardMuted: Color(0xFFC2CCE8),
    cardTrack: Color(0x38F2F6FF),
    cardOutline: Color(0x73F2F6FF),
    candyInk: Color(0xFF050C1F),
    candyLipCoral: Color(0xFFC0262F),
    candyLipMint: Color(0xFF137236),
    candyLipLemon: Color(0xFFA88A12),
    candyLipTangerine: Color(0xFF9E4B0A),
    titleDrop: Color(0xFF2A63C9),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFF78C8C),
    accentMark: Color(0xFFF45B5B),
    notGoingIcon: Color(0xFFF78C8C),
    goingText: Color(0xFF79CD8F),
    maybeText: Color(0xFFF8D84A),
    cardGoingText: Color(0xFF79CD8F),
    cardAccentText: Color(0xFFF78C8C),
    gameText: Color(0xFFF19A5A),
    typeGame: Color(0xFFF19A5A),
    typePractice: Color(0xFFB796F7),
    typeOther: Color(0xFFF184BE),
    grapePageText: Color(0xFFA57CF5),
    bubblegumPageText: Color(0xFFEB50A2),
    blueRaspberryPageText: Color(0xFF79BBFF),
    blueRaspberryCardText: Color(0xFF79BBFF),
    grapeLip: Color(0xFF6C46CC),
    bubblegumLip: Color(0xFFAE2770),
    blueRaspberryLip: Color(0xFF2A63C9),
  );

  static const skyblue = SchemeRoles(
    page: Color(0xFFBCD9F5),
    text: Color(0xFF0B1531),
    pageMuted: Color(0xFF34476E),
    hairline: Color(0x240B1531),
    outline: Color(0x590B1531),
    tabbar: Color(0xFFFFFFFF),
    tabbarLine: Color(0xFF0B1531),
    field: Color(0xFFE3EEFA),
    fieldRim: Color(0x00000000),
    card: Color(0xFFFFFFFF),
    cardRim: Color(0xFF0B1531),
    cardMuted: Color(0xFF34476E),
    cardTrack: Color(0x1F0B1531),
    cardOutline: Color(0x660B1531),
    candyInk: Color(0xFF0B1531),
    candyLipCoral: Color(0xFF0B1531),
    candyLipMint: Color(0xFF0B1531),
    candyLipLemon: Color(0xFF0B1531),
    candyLipTangerine: Color(0xFF0B1531),
    titleDrop: Color(0xFFFFFFFF),
    avatarRing: Color(0xFF0B1531),
    accentText: Color(0xFFAB222A),
    accentMark: Color(0xFFAB222A),
    notGoingIcon: Color(0xFFAB222A),
    goingText: Color(0xFF116530),
    maybeText: Color(0xFF785200),
    cardGoingText: Color(0xFF137236),
    cardAccentText: Color(0xFFC0262F),
    gameText: Color(0xFF8D4309),
    typeGame: Color(0xFF9E4B0A),
    typePractice: Color(0xFF6C46CC),
    typeOther: Color(0xFFAE2770),
    grapePageText: Color(0xFF6642C0),
    bubblegumPageText: Color(0xFFA7256C),
    blueRaspberryPageText: Color(0xFF2558B3),
    blueRaspberryCardText: Color(0xFF2A63C9),
    grapeLip: Color(0xFF0B1531),
    bubblegumLip: Color(0xFF0B1531),
    blueRaspberryLip: Color(0xFF0B1531),
  );

  /// The roles of [scheme].
  static SchemeRoles of(TeamScheme scheme) => switch (scheme) {
    TeamScheme.army => army,
    TeamScheme.light => light,
    TeamScheme.dark => dark,
    TeamScheme.navy => navy,
    TeamScheme.skyblue => skyblue,
  };
}

/// What each scheme is called, and whether its page is dark.
extension TeamSchemeLook on TeamScheme {
  /// Light text on a dark page and dark cards (Army green, Dark, Navy).
  bool get isDark =>
      this == TeamScheme.army ||
      this == TeamScheme.dark ||
      this == TeamScheme.navy;

  /// "Army green", and the rest.
  String label(AppLocalizations l10n) => switch (this) {
    TeamScheme.army => l10n.schemeArmy,
    TeamScheme.light => l10n.schemeLight,
    TeamScheme.dark => l10n.schemeDark,
    TeamScheme.navy => l10n.schemeNavy,
    TeamScheme.skyblue => l10n.schemeSkyblue,
  };

  /// The short line under the name: "Army green page, cream type".
  String shortLabel(AppLocalizations l10n) => switch (this) {
    TeamScheme.army => l10n.schemeArmyShort,
    TeamScheme.light => l10n.schemeLightShort,
    TeamScheme.dark => l10n.schemeDarkShort,
    TeamScheme.navy => l10n.schemeNavyShort,
    TeamScheme.skyblue => l10n.schemeSkyblueShort,
  };
}
