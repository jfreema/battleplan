import 'package:battleplan/core/design/color_math.dart';
import 'package:material_ui/material_ui.dart';

/// The three Gumdrop Pop themes (SPEC SET-2).
enum GumdropFlavor {
  /// Gumdrop Pop Dark: navy page, the default.
  dark,

  /// Gumdrop Pop Light: pale page, white cards.
  light,

  /// Gumdrop Candy: blue page, white cards, navy ink.
  candy,
}

/// One candy color: the gumdrop's [face], the hard [lip] under it, and
/// [text], the color for writing in this hue on the theme's cards.
@immutable
class GumdropAccent {
  const new({required this.face, required this.lip, required this.text});

  final Color face;
  final Color lip;

  /// Readable (4.5:1) on `surface`. Text on an accent [face] is always
  /// [GumdropColors.ink].
  final Color text;

  GumdropAccent lerp(GumdropAccent other, double t) => GumdropAccent(
    face: Color.lerp(face, other.face, t)!,
    lip: Color.lerp(lip, other.lip, t)!,
    text: Color.lerp(text, other.text, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is GumdropAccent &&
      other.face == face &&
      other.lip == lip &&
      other.text == text;

  @override
  int get hashCode => Object.hash(face, lip, text);
}

/// Every color role of a Gumdrop theme, as the theme extension screens read
/// with [GumdropColors.of]. The values are the design's tokens (Gumdrop Pop
/// design tokens §1a to §1c); a team's color tints the page and the
/// surfaces under it (team_tint.dart).
///
/// Two contexts: on the page (the default), and on a card ([onCard]). They
/// differ only in Candy, where the page is blue with white text and cards
/// are white with navy text; [card] gives the card context, and
/// `GumdropSurface` applies it to a subtree.
@immutable
class GumdropColors extends ThemeExtension<GumdropColors> {
  const new({
    required this.flavor,
    required this.page,
    required this.surface,
    required this.surfaceBorder,
    required this.surfaceBorderWidth,
    required this.raisedFace,
    required this.raisedBorder,
    required this.raisedBorderWidth,
    required this.raisedHighlight,
    required this.raisedLip,
    required this.well,
    required this.inputFill,
    required this.inputBorder,
    required this.divider,
    required this.switchOffTrack,
    required this.textPrimary,
    required this.textMuted,
    required this.textOnPage,
    required this.textMutedOnPage,
    required this.successOnPage,
    required this.ink,
    required this.headingText,
    required this.headingShadow,
    required this.headingTextOnCard,
    required this.headingShadowOnCard,
    required this.pageShadow,
    required this.selectedRingOuter,
    required this.swatchInsetRing,
    required this.badgeRing,
    required this.you,
    required this.blueRaspberry,
    required this.lemon,
    required this.mint,
    required this.cherry,
    required this.tangerine,
    required this.grape,
    required this.bubblegum,
    this.teamColor,
    this.onCard = false,
  });

  /// Gumdrop Pop Dark (tokens "Navy").
  static const dark = GumdropColors(
    flavor: GumdropFlavor.dark,
    page: Color(0xFF0B1531),
    surface: Color(0xFF16244A),
    surfaceBorder: Color(0x0FFFFFFF),
    surfaceBorderWidth: 1,
    raisedFace: Color(0xFF22355F),
    raisedBorder: Color(0x00000000),
    raisedBorderWidth: 0,
    raisedHighlight: Color(0x1AFFFFFF),
    raisedLip: Color(0xFF050C1F),
    well: Color(0xFF07102A),
    inputFill: Color(0xFF07102A),
    inputBorder: Color(0xFF2D4274),
    divider: Color(0xFF2D4274),
    switchOffTrack: Color(0xFF22355F),
    textPrimary: Color(0xFFF2F6FF),
    textMuted: Color(0xFFB2BFE0),
    textOnPage: Color(0xFFF2F6FF),
    textMutedOnPage: Color(0xFFB2BFE0),
    successOnPage: Color(0xFF5FE69A),
    ink: Color(0xFF0B1531),
    headingText: Color(0xFFFFFFFF),
    headingShadow: Color(0xFF2A63C9),
    headingTextOnCard: Color(0xFFFFFFFF),
    headingShadowOnCard: Color(0xFF2A63C9),
    pageShadow: Color(0xFF2A63C9),
    selectedRingOuter: Color(0xFFF2F6FF),
    swatchInsetRing: Color(0x2EFFFFFF),
    badgeRing: Color(0xFF0B1531),
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

  /// Gumdrop Pop Light.
  static const light = GumdropColors(
    flavor: GumdropFlavor.light,
    page: Color(0xFFF2F5FD),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFDEE4F4),
    surfaceBorderWidth: 1.5,
    raisedFace: Color(0xFFFFFFFF),
    raisedBorder: Color(0xFFD2DBF1),
    raisedBorderWidth: 2,
    raisedHighlight: Color(0xE6FFFFFF),
    raisedLip: Color(0xFFC7D2EC),
    well: Color(0xFFE6ECF9),
    inputFill: Color(0xFFF6F8FE),
    inputBorder: Color(0xFFD2DBF1),
    divider: Color(0xFFD2DBF1),
    switchOffTrack: Color(0xFFE6ECF9),
    textPrimary: Color(0xFF121A35),
    textMuted: Color(0xFF515C7C),
    textOnPage: Color(0xFF121A35),
    textMutedOnPage: Color(0xFF515C7C),
    successOnPage: Color(0xFF0A7540),
    ink: Color(0xFF0D1633),
    headingText: Color(0xFF0D1633),
    headingShadow: Color(0xFF4D9BFF),
    headingTextOnCard: Color(0xFF0D1633),
    headingShadowOnCard: Color(0xFF4D9BFF),
    pageShadow: Color(0xFF4D9BFF),
    selectedRingOuter: Color(0xFF121A35),
    swatchInsetRing: Color(0x240D1633),
    badgeRing: Color(0xFFF2F5FD),
    // The accents' text colors on white cards; the faces are too light to
    // read as text, so blue, tangerine, grape, and bubblegum use their lips.
    you: GumdropAccent(
      face: Color(0xFF4D9BFF),
      lip: Color(0xFF2A63C9),
      text: Color(0xFF2A63C9),
    ),
    blueRaspberry: GumdropAccent(
      face: Color(0xFF4D9BFF),
      lip: Color(0xFF2A63C9),
      text: Color(0xFF2A63C9),
    ),
    lemon: GumdropAccent(
      face: Color(0xFFFFD84A),
      lip: Color(0xFFC2950B),
      text: Color(0xFF7A5E00),
    ),
    mint: GumdropAccent(
      face: Color(0xFF4DDC8C),
      lip: Color(0xFF1F9A55),
      text: Color(0xFF0A7540),
    ),
    cherry: GumdropAccent(
      face: Color(0xFFFF5D73),
      lip: Color(0xFFC42A45),
      text: Color(0xFFBD1D3A),
    ),
    tangerine: GumdropAccent(
      face: Color(0xFFFF9B42),
      lip: Color(0xFFC7600C),
      text: Color(0xFFA34B00),
    ),
    grape: GumdropAccent(
      face: Color(0xFFA88BFF),
      lip: Color(0xFF6E4FD6),
      text: Color(0xFF6E4FD6),
    ),
    bubblegum: GumdropAccent(
      face: Color(0xFFFF7AC8),
      lip: Color(0xFFC93E91),
      text: Color(0xFFB0307C),
    ),
  );

  /// Gumdrop Candy. Its "you" color is lemon, so you and maybe match.
  static const candy = GumdropColors(
    flavor: GumdropFlavor.candy,
    page: Color(0xFF305AF6),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFFFFFFF),
    surfaceBorderWidth: 1,
    raisedFace: Color(0xFFFFFFFF),
    raisedBorder: Color(0xFF0D163D),
    raisedBorderWidth: 2,
    raisedHighlight: Color(0xE6FFFFFF),
    raisedLip: Color(0xFF0D163D),
    well: Color(0xFFDFE8FD),
    inputFill: Color(0xFFDFE8FD),
    inputBorder: Color(0xFF0D163D),
    divider: Color(0xFFD3DEFB),
    switchOffTrack: Color(0xFFDFE8FD),
    textPrimary: Color(0xFF0D163D),
    textMuted: Color(0xFF555B77),
    textOnPage: Color(0xFFFFFFFF),
    textMutedOnPage: Color(0xFFEEF3FF),
    successOnPage: Color(0xFFB5FAD0),
    ink: Color(0xFF0D163D),
    headingText: Color(0xFFFFFFFF),
    headingShadow: Color(0xFF0D163D),
    headingTextOnCard: Color(0xFF0D163D),
    headingShadowOnCard: Color(0xFF305AF6),
    pageShadow: Color(0xFF0D163D),
    selectedRingOuter: Color(0xFFFFFFFF),
    swatchInsetRing: Color(0xFF0D163D),
    badgeRing: Color(0xFF305AF6),
    you: GumdropAccent(
      face: Color(0xFFF8D84A),
      lip: Color(0xFFC29E0E),
      text: Color(0xFF755A00),
    ),
    blueRaspberry: GumdropAccent(
      face: Color(0xFF79BBFF),
      lip: Color(0xFF3D84D6),
      text: Color(0xFF2A63C9),
    ),
    lemon: GumdropAccent(
      face: Color(0xFFF8D84A),
      lip: Color(0xFFC29E0E),
      text: Color(0xFF755A00),
    ),
    mint: GumdropAccent(
      face: Color(0xFF58C173),
      lip: Color(0xFF2F8A4C),
      text: Color(0xFF137236),
    ),
    cherry: GumdropAccent(
      face: Color(0xFFF45B5B),
      lip: Color(0xFFBE2F37),
      text: Color(0xFFC0262F),
    ),
    tangerine: GumdropAccent(
      face: Color(0xFFEE8131),
      lip: Color(0xFFB45810),
      text: Color(0xFF9E4B0A),
    ),
    grape: GumdropAccent(
      face: Color(0xFFA57CF5),
      lip: Color(0xFF6C46CC),
      text: Color(0xFF6C46CC),
    ),
    bubblegum: GumdropAccent(
      face: Color(0xFFEB50A2),
      lip: Color(0xFFAE2770),
      text: Color(0xFFAE2770),
    ),
  );

  /// The untinted colors of [flavor].
  static GumdropColors forFlavor(GumdropFlavor flavor) => switch (flavor) {
    GumdropFlavor.dark => dark,
    GumdropFlavor.light => light,
    GumdropFlavor.candy => candy,
  };

  /// The colors in effect at [context]: the theme's, or Gumdrop Pop Dark
  /// under a bare MaterialApp (some tests).
  static GumdropColors of(BuildContext context) =>
      Theme.of(context).extension<GumdropColors>() ?? dark;

  // Fixed in every theme (tokens §1a).

  /// The top inset on every accent gumdrop: `inset 0 2px 0`.
  static const accentHighlight = Color(0x59FFFFFF);

  /// Ink at 14%: the disc behind a check on a selected accent button.
  static const inkTint14 = Color(0x2414112B);

  /// Ink at 16%: a poll bar's track inside the selected option.
  static const inkTint16 = Color(0x2914112B);

  /// Ink at 30%: the dashed rule inside the game card.
  static const inkTint30 = Color(0x4D14112B);

  /// The @mention pill inside your own bubble.
  static const mentionBg = Color(0xFFFFFFFF);

  /// The switch's knob.
  static const switchKnob = Color(0xFFFFFFFF);

  final GumdropFlavor flavor;

  /// The team color these were tinted with (ARGB), or null outside a team.
  final Color? teamColor;

  /// Whether these are the card context (see [card]).
  final bool onCard;

  /// The screen's background.
  final Color page;

  /// Cards, sheets, others' bubbles, the tab bar.
  final Color surface;
  final Color surfaceBorder;
  final double surfaceBorderWidth;

  /// The secondary gumdrop button: face, outline, top highlight, and lip.
  final Color raisedFace;
  final Color raisedBorder;

  /// 0 in Dark (no outline), 2 in Light and Candy.
  final double raisedBorderWidth;
  final Color raisedHighlight;
  final Color raisedLip;

  /// A recessed fill: tracks, quotes, the segmented control, icon discs.
  final Color well;
  final Color inputFill;

  /// 2 px around text fields.
  final Color inputBorder;

  /// Hairlines, list-row rules, dashed outlines.
  final Color divider;
  final Color switchOffTrack;

  /// Text on [surface] (and on the page in Dark and Light).
  final Color textPrimary;
  final Color textMuted;

  /// Text straight on the [page]. Differs from [textPrimary] only in Candy.
  final Color textOnPage;
  final Color textMutedOnPage;

  /// A success check or note straight on the page.
  final Color successOnPage;

  /// Text and icons on every accent face; the outline ink.
  final Color ink;

  /// Lilita headings on the page, and their stacked hard shadow.
  final Color headingText;
  final Color headingShadow;

  /// Lilita headings inside a card.
  final Color headingTextOnCard;
  final Color headingShadowOnCard;

  /// Hard offset shadows on the page: the back button, the sticker tag, an
  /// on switch.
  final Color pageShadow;

  /// The outer ring around a selected swatch, and the inset ring on every
  /// team-color swatch.
  final Color selectedRingOuter;
  final Color swatchInsetRing;

  /// The cutout ring around an unread badge.
  final Color badgeRing;

  /// Your bubble, send, the FAB, the active tab: blue, or lemon in Candy.
  final GumdropAccent you;
  final GumdropAccent blueRaspberry;

  /// Maybe; pinned.
  final GumdropAccent lemon;

  /// Going; switches on; progress.
  final GumdropAccent mint;

  /// Can't go; unread; errors.
  final GumdropAccent cherry;

  /// Games.
  final GumdropAccent tangerine;

  /// Practices.
  final GumdropAccent grape;

  /// Other events, your reactions, polls.
  final GumdropAccent bubblegum;

  /// Light, or dark, for Material and the status bar: the brightness of
  /// what text sits on in this context (Candy's page is "dark": white text).
  Brightness get brightness => switch (flavor) {
    GumdropFlavor.dark => Brightness.dark,
    GumdropFlavor.light => Brightness.light,
    GumdropFlavor.candy => onCard ? Brightness.light : Brightness.dark,
  };

  /// What text sits on in this context: the page, or a card.
  Color get background => onCard ? surface : page;

  /// The card context: text, headings, and success colors for a [surface],
  /// as `GumdropSurface` applies them. The same colors in Dark and Light,
  /// whose cards share the page's text colors.
  GumdropColors get card => onCard
      ? this
      : copyWith(
          onCard: true,
          textOnPage: textPrimary,
          textMutedOnPage: textMuted,
          headingText: headingTextOnCard,
          headingShadow: headingShadowOnCard,
          successOnPage: mint.text,
        );

  /// The candy color that marks the event type, by the event type's name
  /// (game, practice, meeting, social, other): tangerine, grape, blue
  /// raspberry, mint, and bubblegum.
  GumdropAccent eventAccent(String type) => switch (type) {
    'game' => tangerine,
    'practice' => grape,
    'meeting' => blueRaspberry,
    'social' => mint,
    _ => bubblegum,
  };

  /// The hard text-shadow under a Lilita heading: [steps] copies of [color]
  /// one pixel further down and right each (4 for screen titles and the
  /// team name, 3 for section headings).
  static List<Shadow> stackedShadow(Color color, int steps) => [
    for (var i = 1; i <= steps; i++)
      Shadow(color: color, offset: Offset(i.toDouble(), i.toDouble())),
  ];

  /// Checks [a] against [b] for 4.5:1 (for tests and asserts).
  static bool reads(Color a, Color b) => ColorMath.contrast(a, b) >= 4.5;

  @override
  GumdropColors copyWith({
    GumdropFlavor? flavor,
    Color? teamColor,
    bool? onCard,
    Color? page,
    Color? surface,
    Color? surfaceBorder,
    double? surfaceBorderWidth,
    Color? raisedFace,
    Color? raisedBorder,
    double? raisedBorderWidth,
    Color? raisedHighlight,
    Color? raisedLip,
    Color? well,
    Color? inputFill,
    Color? inputBorder,
    Color? divider,
    Color? switchOffTrack,
    Color? textPrimary,
    Color? textMuted,
    Color? textOnPage,
    Color? textMutedOnPage,
    Color? successOnPage,
    Color? ink,
    Color? headingText,
    Color? headingShadow,
    Color? headingTextOnCard,
    Color? headingShadowOnCard,
    Color? pageShadow,
    Color? selectedRingOuter,
    Color? swatchInsetRing,
    Color? badgeRing,
    GumdropAccent? you,
    GumdropAccent? blueRaspberry,
    GumdropAccent? lemon,
    GumdropAccent? mint,
    GumdropAccent? cherry,
    GumdropAccent? tangerine,
    GumdropAccent? grape,
    GumdropAccent? bubblegum,
  }) => GumdropColors(
    flavor: flavor ?? this.flavor,
    teamColor: teamColor ?? this.teamColor,
    onCard: onCard ?? this.onCard,
    page: page ?? this.page,
    surface: surface ?? this.surface,
    surfaceBorder: surfaceBorder ?? this.surfaceBorder,
    surfaceBorderWidth: surfaceBorderWidth ?? this.surfaceBorderWidth,
    raisedFace: raisedFace ?? this.raisedFace,
    raisedBorder: raisedBorder ?? this.raisedBorder,
    raisedBorderWidth: raisedBorderWidth ?? this.raisedBorderWidth,
    raisedHighlight: raisedHighlight ?? this.raisedHighlight,
    raisedLip: raisedLip ?? this.raisedLip,
    well: well ?? this.well,
    inputFill: inputFill ?? this.inputFill,
    inputBorder: inputBorder ?? this.inputBorder,
    divider: divider ?? this.divider,
    switchOffTrack: switchOffTrack ?? this.switchOffTrack,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    textOnPage: textOnPage ?? this.textOnPage,
    textMutedOnPage: textMutedOnPage ?? this.textMutedOnPage,
    successOnPage: successOnPage ?? this.successOnPage,
    ink: ink ?? this.ink,
    headingText: headingText ?? this.headingText,
    headingShadow: headingShadow ?? this.headingShadow,
    headingTextOnCard: headingTextOnCard ?? this.headingTextOnCard,
    headingShadowOnCard: headingShadowOnCard ?? this.headingShadowOnCard,
    pageShadow: pageShadow ?? this.pageShadow,
    selectedRingOuter: selectedRingOuter ?? this.selectedRingOuter,
    swatchInsetRing: swatchInsetRing ?? this.swatchInsetRing,
    badgeRing: badgeRing ?? this.badgeRing,
    you: you ?? this.you,
    blueRaspberry: blueRaspberry ?? this.blueRaspberry,
    lemon: lemon ?? this.lemon,
    mint: mint ?? this.mint,
    cherry: cherry ?? this.cherry,
    tangerine: tangerine ?? this.tangerine,
    grape: grape ?? this.grape,
    bubblegum: bubblegum ?? this.bubblegum,
  );

  @override
  GumdropColors lerp(GumdropColors? other, double t) {
    if (other == null || identical(other, this)) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    final near = t < 0.5 ? this : other;
    return GumdropColors(
      flavor: near.flavor,
      teamColor: near.teamColor,
      onCard: near.onCard,
      page: c(page, other.page),
      surface: c(surface, other.surface),
      surfaceBorder: c(surfaceBorder, other.surfaceBorder),
      surfaceBorderWidth: d(surfaceBorderWidth, other.surfaceBorderWidth),
      raisedFace: c(raisedFace, other.raisedFace),
      raisedBorder: c(raisedBorder, other.raisedBorder),
      raisedBorderWidth: d(raisedBorderWidth, other.raisedBorderWidth),
      raisedHighlight: c(raisedHighlight, other.raisedHighlight),
      raisedLip: c(raisedLip, other.raisedLip),
      well: c(well, other.well),
      inputFill: c(inputFill, other.inputFill),
      inputBorder: c(inputBorder, other.inputBorder),
      divider: c(divider, other.divider),
      switchOffTrack: c(switchOffTrack, other.switchOffTrack),
      textPrimary: c(textPrimary, other.textPrimary),
      textMuted: c(textMuted, other.textMuted),
      textOnPage: c(textOnPage, other.textOnPage),
      textMutedOnPage: c(textMutedOnPage, other.textMutedOnPage),
      successOnPage: c(successOnPage, other.successOnPage),
      ink: c(ink, other.ink),
      headingText: c(headingText, other.headingText),
      headingShadow: c(headingShadow, other.headingShadow),
      headingTextOnCard: c(headingTextOnCard, other.headingTextOnCard),
      headingShadowOnCard: c(headingShadowOnCard, other.headingShadowOnCard),
      pageShadow: c(pageShadow, other.pageShadow),
      selectedRingOuter: c(selectedRingOuter, other.selectedRingOuter),
      swatchInsetRing: c(swatchInsetRing, other.swatchInsetRing),
      badgeRing: c(badgeRing, other.badgeRing),
      you: you.lerp(other.you, t),
      blueRaspberry: blueRaspberry.lerp(other.blueRaspberry, t),
      lemon: lemon.lerp(other.lemon, t),
      mint: mint.lerp(other.mint, t),
      cherry: cherry.lerp(other.cherry, t),
      tangerine: tangerine.lerp(other.tangerine, t),
      grape: grape.lerp(other.grape, t),
      bubblegum: bubblegum.lerp(other.bubblegum, t),
    );
  }
}
