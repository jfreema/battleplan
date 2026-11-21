import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart' show GumdropColors;
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:battleplan/core/theme_override.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';

export 'package:battleplan/core/scheme_defaults.dart';
export 'package:battleplan/core/theme_override.dart';

/// The candy faces, the same in every scheme (SPEC §7.4).
abstract final class CandyFaces {
  /// You: your messages, the main button, the current tab, and unread.
  /// The red of the owner's team shirt.
  static const coral = Color(0xFFF45B5B);

  /// Warnings only: Not going, Canceled, what's owed, errors, and Delete.
  /// A deeper red than [coral], so the two never read as one (the
  /// usability review's #12, owner's go 2026-11-16; until then both were
  /// coral). Its face takes white ([cherryInk]), not the candy ink, which
  /// reads only 3.6:1 on it.
  static const cherry = Color(0xFFD4343C);

  /// Text and icons on a [cherry] face: 4.8:1.
  static const cherryInk = Color(0xFFFFFFFF);
  static const mint = Color(0xFF58C173);
  static const lemon = Color(0xFFF8D84A);
  static const tangerine = Color(0xFFEE8131);
  static const grape = Color(0xFFA57CF5);
  static const bubblegum = Color(0xFFEB50A2);
  static const blueRaspberry = Color(0xFF79BBFF);
}

/// The 32 color roles of one Open Field color scheme (SPEC SET-2, §7.4),
/// from the design's schemes.json, plus the eight values the app derives
/// for colors the design doesn't draw, four for cards whose colors aren't
/// the page's (Candy Pop's white cards, #72), and the "you" candy's face
/// (#82). [GumdropColors.forScheme] fills the theme from them.
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
    required this.cardText,
    required this.cardField,
    required this.cardMaybeText,
    required this.popup,
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
    required this.cherryLip,
    this.you = CandyFaces.coral,
  });

  /// Page fill; ring around the unread dot and the badge; the game screen's bottom fade.
  final Color page;

  /// Main text and icons on the page and in the tab bar (and on cards, but in Candy Pop: [cardText]); status bar; home indicator; ring around the picked icon color.
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

  /// Main text and icons on a card, a sheet, a dialog and a panel: [text]
  /// in every scheme but Candy Pop, whose cards are white with TeamRank's
  /// navy ink on a blue page (#72).
  final Color cardText;

  /// Text fields on a card, a sheet or a dialog: [field] in every scheme
  /// but Candy Pop's, TeamRank's pale sky blue under navy type.
  final Color cardField;

  /// Maybe on a card: the Maybe count, the ? on unpicked Maybe buttons
  /// ([maybeText] in every scheme but Candy Pop, whose page needs a light
  /// yellow and whose white cards a dark one).
  final Color cardMaybeText;

  /// Material's own pop-ups opened from the page, whose rows take the
  /// page's text color: menus, and the date and time pickers. The [card]
  /// in every scheme but Candy Pop, where a white menu would hide its
  /// white rows, so they keep the deeper blue.
  final Color popup;

  /// Text, icons and marks on candy faces: icons, team badges, badge and unread count, your poll bubble, picked RSVP, send, +, crest, picked color's check.
  final Color candyInk;

  /// Outline + lip of coral candy buttons: send, +. (Picked Not going is the warning red's, [cherryLip], since #12.)
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

  /// Red as text on the page: the warning red's (Not going, errors, Delete) and coral's (the picked scheme's check). Red text has to be this light to read on the dark schemes, so the two share it; the stencil eyebrow is muted since #12.
  final Color accentText;

  /// Coral marks on the page: underline under your reaction and under "open", Directions icon. (The pin is lemon since #12.)
  final Color accentMark;

  /// The x on the unpicked Not going button on the page (game screen).
  final Color notGoingIcon;

  /// Going on the page: the Going count, the checks in the people list.
  final Color goingText;

  /// Maybe on the page and on cards: the Maybe count, the ? on unpicked Maybe buttons.
  final Color maybeText;

  /// The check on a card nobody has answered.
  final Color cardGoingText;

  /// Red on a card: the x on a card nobody has answered, and the warning red's text. ("Luke hasn’t answered" is the card's muted text since #12.)
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

  /// Derived: cherry.lip, the warning red's: ink where the candies have ink
  /// lips, otherwise a darker red than [CandyFaces.cherry].
  final Color cherryLip;

  /// The "you" candy's face: the main button, the + and send, your
  /// messages, the picked tab, and unread counts. Coral in every built-in
  /// scheme; a theme can set its own in the theme editor (#82), light
  /// enough for the scheme's [candyInk] on it.
  final Color you;

  /// These roles with a theme's own [page], [card], and [you] (#82). The
  /// pop-up color follows the card where it was the card's. A new [you]
  /// brings its marks along: a coral underline or tab marker
  /// ([accentMark]) takes it, made to read on the page, and a coral lip
  /// ([candyLipCoral]) takes a deeper shade of it; a scheme's own (gold,
  /// silver, a dark ink lip) stays.
  SchemeRoles withOverrides({Color? page, Color? card, Color? you}) {
    final newYou = you != null && you != this.you ? you : null;
    final newPage = page ?? this.page;
    final youLch = newYou == null ? null : ColorMath.lch(newYou);
    return SchemeRoles(
      page: newPage,
      text: text,
      pageMuted: pageMuted,
      hairline: hairline,
      outline: outline,
      tabbar: tabbar,
      tabbarLine: tabbarLine,
      field: field,
      fieldRim: fieldRim,
      card: card ?? this.card,
      cardRim: cardRim,
      cardMuted: cardMuted,
      cardTrack: cardTrack,
      cardOutline: cardOutline,
      cardText: cardText,
      cardField: cardField,
      cardMaybeText: cardMaybeText,
      candyInk: candyInk,
      candyLipCoral: youLch == null || ColorMath.luminance(candyLipCoral) < 0.03
          ? candyLipCoral
          : ColorMath.fromLch(math.max(youLch.l - 28, 0), youLch.c, youLch.h),
      candyLipMint: candyLipMint,
      candyLipLemon: candyLipLemon,
      candyLipTangerine: candyLipTangerine,
      titleDrop: titleDrop,
      avatarRing: avatarRing,
      accentText: accentText,
      accentMark: newYou == null || !_coralish(accentMark)
          ? accentMark
          : ColorMath.readable(newYou, [newPage], minimum: 3),
      notGoingIcon: notGoingIcon,
      goingText: goingText,
      maybeText: maybeText,
      cardGoingText: cardGoingText,
      cardAccentText: cardAccentText,
      gameText: gameText,
      typeGame: typeGame,
      typePractice: typePractice,
      typeOther: typeOther,
      grapePageText: grapePageText,
      bubblegumPageText: bubblegumPageText,
      blueRaspberryPageText: blueRaspberryPageText,
      blueRaspberryCardText: blueRaspberryCardText,
      grapeLip: grapeLip,
      bubblegumLip: bubblegumLip,
      blueRaspberryLip: blueRaspberryLip,
      cherryLip: cherryLip,
      popup: card != null && popup == this.card ? card : popup,
      you: you ?? this.you,
    );
  }

  /// Whether [color] is a coral mark a theme's own "you" color replaces.
  static bool _coralish(Color color) {
    final c = ColorMath.lch(color);
    return c.c > 30 &&
        ColorMath.hueDistance(c.h, ColorMath.lch(CandyFaces.coral).h) < 20;
  }

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
    cardText: Color(0xFFF4EAD0),
    cardField: Color(0xFF2B2F18),
    cardMaybeText: Color(0xFFF8D84A),
    popup: Color(0xFF575A3A),
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
    cherryLip: Color(0xFF1A1A18),
  );

  /// Forest green (#78, owner's request 2026-11-20: "rename the dark army
  /// green theme to "forest green", but first make it a tiny bit darker"):
  /// Army green's cream type, ink, and candies on a deep olive page, its
  /// cards, fields, and tab bar deepened alike. Called Dark army green in
  /// #77, a shade lighter (page 2A2E19); its stored value is still
  /// `darkarmy`, so a pick of it carries over.
  static const darkarmy = SchemeRoles(
    page: Color(0xFF242713),
    text: Color(0xFFF4EAD0),
    pageMuted: Color(0xCCF4EAD0),
    hairline: Color(0x24F4EAD0),
    outline: Color(0x4CF4EAD0),
    tabbar: Color(0xFF1D200F),
    tabbarLine: Color(0x1AF4EAD0),
    field: Color(0xFF14160A),
    fieldRim: Color(0x00000000),
    card: Color(0xFF33361F),
    cardRim: Color(0xFF1A1A18),
    cardMuted: Color(0xE0F4EAD0),
    cardTrack: Color(0x38F4EAD0),
    cardOutline: Color(0x73F4EAD0),
    cardText: Color(0xFFF4EAD0),
    cardField: Color(0xFF14160A),
    cardMaybeText: Color(0xFFF8D84A),
    popup: Color(0xFF33361F),
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
    cherryLip: Color(0xFF1A1A18),
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
    cardText: Color(0xFF1A1A18),
    cardField: Color(0xFFEFE6CC),
    cardMaybeText: Color(0xFF8F6500),
    popup: Color(0xFFFFFFFF),
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
    cherryLip: Color(0xFF1A1A18),
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
    cardText: Color(0xFFF4EAD0),
    cardField: Color(0xFF1F1F1C),
    cardMaybeText: Color(0xFFF8D84A),
    popup: Color(0xFF1B1B19),
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
    cherryLip: Color(0xFF8E1C23),
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
    cardText: Color(0xFFF2F6FF),
    cardField: Color(0xFF07102A),
    cardMaybeText: Color(0xFFF8D84A),
    popup: Color(0xFF18284C),
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
    cherryLip: Color(0xFF8E1C23),
  );

  /// Sky Blue (#75, owner's request 2026-11-20: "add a version of sky blue
  /// that dosnt have the white bubbles. make it more like the army green
  /// one how it is all blended into the background"): Sky Blue Pop's sky
  /// page and navy type, with cards a shade lighter than the page, as Army
  /// green's are, rimmed and lipped in navy ink, and fields a shade deeper.
  static const sky = SchemeRoles(
    page: Color(0xFFBCD9F5),
    text: Color(0xFF0B1531),
    pageMuted: Color(0xFF34476E),
    hairline: Color(0x240B1531),
    outline: Color(0x590B1531),
    tabbar: Color(0xFFAFD0F1),
    tabbarLine: Color(0x1A0B1531),
    field: Color(0xFFA9CCEE),
    fieldRim: Color(0x00000000),
    card: Color(0xFFD3E6F9),
    cardRim: Color(0xFF0B1531),
    cardMuted: Color(0xFF34476E),
    cardTrack: Color(0x1F0B1531),
    cardOutline: Color(0x660B1531),
    cardText: Color(0xFF0B1531),
    cardField: Color(0xFFBCD9F5),
    cardMaybeText: Color(0xFF785200),
    popup: Color(0xFFD3E6F9),
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
    blueRaspberryCardText: Color(0xFF2558B3),
    grapeLip: Color(0xFF0B1531),
    bubblegumLip: Color(0xFF0B1531),
    blueRaspberryLip: Color(0xFF0B1531),
    cherryLip: Color(0xFF0B1531),
  );

  /// Sky Blue Pop (called Light blue until #75): the sky page with white
  /// cards.
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
    cardText: Color(0xFF0B1531),
    cardField: Color(0xFFE3EEFA),
    cardMaybeText: Color(0xFF785200),
    popup: Color(0xFFFFFFFF),
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
    cherryLip: Color(0xFF0B1531),
  );

  /// Candy Pop (#70, owner's request 2026-11-20: "add a scheme that uses
  /// the colors from the TeamRank app"): TeamRank's loud blue page (a shade
  /// deeper than its 1E5BFF, so tinted text reads at 4.5:1), white type,
  /// and its navy ink for every outline, lip and hard drop. Its cards,
  /// sheets and dialogs are white with navy type, as TeamRank's are (#72,
  /// owner's report 2026-11-20: "The candy pop theme should have white
  /// backgrounds inside the bubbles, like it does on the teamrank site"),
  /// so it's the one scheme whose cards take their own text colors; its
  /// fields on a card are TeamRank's sky blue. Material's menus and
  /// pickers keep the deeper blue ([popup]).
  static const candypop = SchemeRoles(
    page: Color(0xFF1748D4),
    text: Color(0xFFFFFFFF),
    pageMuted: Color(0xFFDCE6FF),
    hairline: Color(0x33FFFFFF),
    outline: Color(0x66FFFFFF),
    tabbar: Color(0xFF0B1640),
    tabbarLine: Color(0xFF0B1640),
    field: Color(0xFF1238A8),
    fieldRim: Color(0x33FFFFFF),
    card: Color(0xFFFFFFFF),
    cardRim: Color(0xFF0B1640),
    cardMuted: Color(0xFF4B5A8C),
    cardTrack: Color(0x1F0B1640),
    cardOutline: Color(0x660B1640),
    cardText: Color(0xFF0B1640),
    cardField: Color(0xFFDDE8FF),
    cardMaybeText: Color(0xFF785200),
    popup: Color(0xFF1238A8),
    candyInk: Color(0xFF0B1640),
    candyLipCoral: Color(0xFF0B1640),
    candyLipMint: Color(0xFF0B1640),
    candyLipLemon: Color(0xFF0B1640),
    candyLipTangerine: Color(0xFF0B1640),
    titleDrop: Color(0xFF0B1640),
    avatarRing: Color(0xFF0B1640),
    accentText: Color(0xFFFFC7C7),
    accentMark: Color(0xFFFFC7C7),
    notGoingIcon: Color(0xFFFFC7C7),
    goingText: Color(0xFFB5FAD0),
    maybeText: Color(0xFFFFE45C),
    cardGoingText: Color(0xFF137236),
    cardAccentText: Color(0xFFC0262F),
    gameText: Color(0xFFFFCB99),
    typeGame: Color(0xFF9E4B0A),
    typePractice: Color(0xFF6C46CC),
    typeOther: Color(0xFFAE2770),
    grapePageText: Color(0xFFDDD0FF),
    bubblegumPageText: Color(0xFFFFC7E6),
    blueRaspberryPageText: Color(0xFFCFE3FF),
    blueRaspberryCardText: Color(0xFF1748D4),
    grapeLip: Color(0xFF0B1640),
    bubblegumLip: Color(0xFF0B1640),
    blueRaspberryLip: Color(0xFF0B1640),
    cherryLip: Color(0xFF0B1640),
  );

  /// Central Wildcat (#79, owner's pick 2026-11-20 from the maroon, silver,
  /// white, and black mockups: "add the deep maroon theme you just made to
  /// the available themes. Name it "Central Wildcat""): a deep maroon page
  /// with cards a shade lighter, silver rims and outlines, white type, and
  /// black for the tab bar, the candies' lips, and the drop under titles.
  static const wildcat = SchemeRoles(
    page: Color(0xFF5E1224),
    text: Color(0xFFFFFFFF),
    pageMuted: Color(0xFFCDD1D8),
    hairline: Color(0x33C0C5CC),
    outline: Color(0x99C0C5CC),
    tabbar: Color(0xFF0B0B0B),
    tabbarLine: Color(0x66C0C5CC),
    field: Color(0xFF470C1A),
    fieldRim: Color(0x66C0C5CC),
    card: Color(0xFF701C30),
    cardRim: Color(0xFFC0C5CC),
    cardMuted: Color(0xFFD8DCE2),
    cardTrack: Color(0x38FFFFFF),
    cardOutline: Color(0x99C0C5CC),
    cardText: Color(0xFFFFFFFF),
    cardField: Color(0xFF470C1A),
    cardMaybeText: Color(0xFFFFE680),
    popup: Color(0xFF701C30),
    candyInk: Color(0xFF0B0B0B),
    candyLipCoral: Color(0xFF0B0B0B),
    candyLipMint: Color(0xFF0B0B0B),
    candyLipLemon: Color(0xFF0B0B0B),
    candyLipTangerine: Color(0xFF0B0B0B),
    titleDrop: Color(0xFF0B0B0B),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFFFB3B3),
    accentMark: Color(0xFFC0C5CC),
    notGoingIcon: Color(0xFFFFB3B3),
    goingText: Color(0xFFB8F2C8),
    maybeText: Color(0xFFFFE680),
    cardGoingText: Color(0xFFB8F2C8),
    cardAccentText: Color(0xFFFFB3B3),
    gameText: Color(0xFFFFC999),
    typeGame: Color(0xFFFFC999),
    typePractice: Color(0xFFE0D0FF),
    typeOther: Color(0xFFFFC2E0),
    grapePageText: Color(0xFFE0D0FF),
    bubblegumPageText: Color(0xFFFFC2E0),
    blueRaspberryPageText: Color(0xFFBFDDFF),
    blueRaspberryCardText: Color(0xFFBFDDFF),
    grapeLip: Color(0xFF0B0B0B),
    bubblegumLip: Color(0xFF0B0B0B),
    blueRaspberryLip: Color(0xFF0B0B0B),
    cherryLip: Color(0xFF0B0B0B),
  );

  /// Geaux Tigahs (#80, owner's pick 2026-11-20 from the purple and gold
  /// mockups: "add the LSU inspired theme as well. Name it "Geaux
  /// Tigahs""): a purple page with cards a shade lighter, white type, and gold
  /// for the card rims, outlines, marks, and the drop under titles. Colors
  /// only: no school's name, logo, or mark is in the app.
  static const purplegold = SchemeRoles(
    page: Color(0xFF461D7C),
    text: Color(0xFFFFFFFF),
    pageMuted: Color(0xFFD5C6F0),
    hairline: Color(0x33FDD023),
    outline: Color(0x99FDD023),
    tabbar: Color(0xFF2E1157),
    tabbarLine: Color(0x66FDD023),
    field: Color(0xFF34125F),
    fieldRim: Color(0x66FDD023),
    card: Color(0xFF55278F),
    cardRim: Color(0xFFFDD023),
    cardMuted: Color(0xFFDCCFF3),
    cardTrack: Color(0x38FFFFFF),
    cardOutline: Color(0x99FDD023),
    cardText: Color(0xFFFFFFFF),
    cardField: Color(0xFF34125F),
    cardMaybeText: Color(0xFFFFE680),
    popup: Color(0xFF55278F),
    candyInk: Color(0xFF1E0A3C),
    candyLipCoral: Color(0xFF1E0A3C),
    candyLipMint: Color(0xFF1E0A3C),
    candyLipLemon: Color(0xFF1E0A3C),
    candyLipTangerine: Color(0xFF1E0A3C),
    titleDrop: Color(0xFFFDD023),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFFFB3B3),
    accentMark: Color(0xFFFDD023),
    notGoingIcon: Color(0xFFFFB3B3),
    goingText: Color(0xFFB8F2C8),
    maybeText: Color(0xFFFFE680),
    cardGoingText: Color(0xFFB8F2C8),
    cardAccentText: Color(0xFFFFB3B3),
    gameText: Color(0xFFFFC999),
    typeGame: Color(0xFFFFC999),
    typePractice: Color(0xFFE0D0FF),
    typeOther: Color(0xFFFFC2E0),
    grapePageText: Color(0xFFE0D0FF),
    bubblegumPageText: Color(0xFFFFC2E0),
    blueRaspberryPageText: Color(0xFFBFDDFF),
    blueRaspberryCardText: Color(0xFFBFDDFF),
    grapeLip: Color(0xFF1E0A3C),
    bubblegumLip: Color(0xFF1E0A3C),
    blueRaspberryLip: Color(0xFF1E0A3C),
    cherryLip: Color(0xFF1E0A3C),
  );

  /// Scoreboard (#81, owner's pick 2026-11-20 from the theme mockups: "Add
  /// the scoreboard theme and call it "Scoreboard""): a stadium at night, a
  /// black page with every word in scoreboard amber, cards a shade lighter
  /// rimmed in dim amber, and a burnt-orange drop under titles.
  static const scoreboard = SchemeRoles(
    page: Color(0xFF0B0B0A),
    text: Color(0xFFFFC83D),
    pageMuted: Color(0xFFC2942E),
    hairline: Color(0x24FFC83D),
    outline: Color(0x66FFC83D),
    tabbar: Color(0xFF050505),
    tabbarLine: Color(0x33FFC83D),
    field: Color(0xFF1D1912),
    fieldRim: Color(0x33FFC83D),
    card: Color(0xFF16130E),
    cardRim: Color(0xFF8A6A16),
    cardMuted: Color(0xFFCC9D33),
    cardTrack: Color(0x38FFC83D),
    cardOutline: Color(0x73FFC83D),
    cardText: Color(0xFFFFC83D),
    cardField: Color(0xFF1D1912),
    cardMaybeText: Color(0xFFFFF06B),
    popup: Color(0xFF16130E),
    candyInk: Color(0xFF0B0B0A),
    candyLipCoral: Color(0xFFC0262F),
    candyLipMint: Color(0xFF137236),
    candyLipLemon: Color(0xFFA88A12),
    candyLipTangerine: Color(0xFF9E4B0A),
    titleDrop: Color(0xFFB8480A),
    avatarRing: Color(0x00000000),
    accentText: Color(0xFFFF7566),
    accentMark: Color(0xFFFF7566),
    notGoingIcon: Color(0xFFFF7566),
    goingText: Color(0xFF6FE08A),
    maybeText: Color(0xFFFFF06B),
    cardGoingText: Color(0xFF6FE08A),
    cardAccentText: Color(0xFFFF7566),
    gameText: Color(0xFFFF9D4D),
    typeGame: Color(0xFFFF9D4D),
    typePractice: Color(0xFFC4A7FF),
    typeOther: Color(0xFFFF8AD0),
    grapePageText: Color(0xFFC4A7FF),
    bubblegumPageText: Color(0xFFFF8AD0),
    blueRaspberryPageText: Color(0xFF7CC8FF),
    blueRaspberryCardText: Color(0xFF7CC8FF),
    grapeLip: Color(0xFF6C46CC),
    bubblegumLip: Color(0xFFAE2770),
    blueRaspberryLip: Color(0xFF2A63C9),
    cherryLip: Color(0xFF8E1C23),
  );

  /// The roles a built-in [scheme] ships with; Dark's for a saved theme's
  /// slot, whose base gives its roles instead ([of]).
  static SchemeRoles builtIn(TeamScheme scheme) => switch (scheme) {
    TeamScheme.army => army,
    TeamScheme.darkarmy => darkarmy,
    TeamScheme.light => light,
    TeamScheme.dark => dark,
    TeamScheme.navy => navy,
    TeamScheme.sky => sky,
    TeamScheme.skyblue => skyblue,
    TeamScheme.candypop => candypop,
    TeamScheme.scoreboard => scoreboard,
    TeamScheme.purplegold => purplegold,
    TeamScheme.wildcat => wildcat,
    _ => dark,
  };

  /// The roles of [scheme], with the colors the theme editor set (#82,
  /// [ThemeCatalog]): a built-in scheme's own, or a saved theme's base's.
  static SchemeRoles of(TeamScheme scheme) =>
      themed(scheme, ThemeCatalog.themeOf(scheme));

  /// The roles of [scheme] with [theme]'s colors, saved or not (the theme
  /// editor's preview, #82). A saved slot with no theme is the default's.
  static SchemeRoles themed(TeamScheme scheme, ThemeOverride? theme) {
    final base = builtIn(
      scheme.isCustom ? theme?.base ?? defaultTeamScheme : scheme,
    );
    if (theme == null) return base;
    Color? color(int? argb) => argb == null ? null : Color(argb);
    return base.withOverrides(
      page: color(theme.page),
      card: color(theme.card),
      you: color(theme.accent),
    );
  }
}

/// The colors the theme editor set (#82), from `config/app.themes`, as
/// the app root installs them ([install]) whenever they change, so every
/// [SchemeRoles.of] and `AppTheme` sees them. Held here rather than passed
/// down because the roles are read everywhere a scheme is drawn.
abstract final class ThemeCatalog {
  static Map<TeamScheme, ThemeOverride> _themes = const {};
  static int _version = 0;

  /// Goes up with each change, so `AppTheme`'s cache knows to rebuild.
  static int get version => _version;

  /// What's installed now.
  static Map<TeamScheme, ThemeOverride> get themes => _themes;

  /// Puts [themes] in place; nothing happens when they're what's there.
  static void install(Map<TeamScheme, ThemeOverride> themes) {
    if (mapEquals(themes, _themes)) return;
    _themes = Map.unmodifiable(themes);
    _version++;
  }

  /// [scheme]'s theme, if the editor set one.
  static ThemeOverride? themeOf(TeamScheme scheme) => _themes[scheme];

  /// The schemes the pickers offer: the built-in ones, then the saved
  /// themes, in slot order.
  static List<TeamScheme> get available => [
    for (final s in TeamScheme.values)
      if (schemeAvailable(s, _themes)) s,
  ];
}

/// What each scheme is called, and whether its page is dark.
extension TeamSchemeLook on TeamScheme {
  /// Light text on a dark page (Army green, Forest green, Dark, Navy,
  /// and Candy Pop's deep blue). The cards are dark too, but Candy Pop's, which are white
  /// ([GumdropColors.brightness] tells a card's own).
  bool get isDark {
    final theme = ThemeCatalog.themeOf(this);
    final page = theme?.page;
    // A theme's own page says it; a saved one is as dark as its base.
    if (page != null) {
      return ThemeData.estimateBrightnessForColor(Color(page)) ==
          Brightness.dark;
    }
    if (isCustom) return (theme?.base ?? defaultTeamScheme).isDark;
    return _shipsDark;
  }

  bool get _shipsDark =>
      this == TeamScheme.army ||
      this == TeamScheme.darkarmy ||
      this == TeamScheme.dark ||
      this == TeamScheme.navy ||
      this == TeamScheme.candypop ||
      this == TeamScheme.wildcat ||
      this == TeamScheme.purplegold ||
      this == TeamScheme.scoreboard;

  /// "Army green", and the rest.
  String label(AppLocalizations l10n) => switch (this) {
    TeamScheme.army => l10n.schemeArmy,
    TeamScheme.darkarmy => l10n.schemeDarkarmy,
    TeamScheme.light => l10n.schemeLight,
    TeamScheme.dark => l10n.schemeDark,
    TeamScheme.navy => l10n.schemeNavy,
    TeamScheme.sky => l10n.schemeSky,
    TeamScheme.skyblue => l10n.schemeSkyblue,
    TeamScheme.candypop => l10n.schemeCandypop,
    TeamScheme.scoreboard => l10n.schemeScoreboard,
    TeamScheme.purplegold => l10n.schemePurplegold,
    TeamScheme.wildcat => l10n.schemeWildcat,
    _ => ThemeCatalog.themeOf(this)?.name ?? l10n.savedThemeUnnamed,
  };

  /// The short line under the name: "Army green page, cream type".
  String shortLabel(AppLocalizations l10n) => switch (this) {
    TeamScheme.army => l10n.schemeArmyShort,
    TeamScheme.darkarmy => l10n.schemeDarkarmyShort,
    TeamScheme.light => l10n.schemeLightShort,
    TeamScheme.dark => l10n.schemeDarkShort,
    TeamScheme.navy => l10n.schemeNavyShort,
    TeamScheme.sky => l10n.schemeSkyShort,
    TeamScheme.skyblue => l10n.schemeSkyblueShort,
    TeamScheme.candypop => l10n.schemeCandypopShort,
    TeamScheme.scoreboard => l10n.schemeScoreboardShort,
    TeamScheme.purplegold => l10n.schemePurplegoldShort,
    TeamScheme.wildcat => l10n.schemeWildcatShort,
    _ => l10n.savedThemeShort(
      (ThemeCatalog.themeOf(this)?.base ?? defaultTeamScheme).label(l10n),
    ),
  };
}
