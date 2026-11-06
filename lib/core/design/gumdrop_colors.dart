import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:material_ui/material_ui.dart';

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

/// Every color role of an Open Field color scheme (SPEC SET-2, §7.4), as
/// the theme extension screens read with [GumdropColors.of]. The values
/// come from the scheme's [SchemeRoles] ([forScheme]).
///
/// Two contexts: on the page (the default), and on a card ([onCard]),
/// where a few roles differ (muted text, outlines, the candies' text
/// shades). [card] gives the card context, and `GumdropSurface` applies it
/// to a subtree.
@immutable
class GumdropColors extends ThemeExtension<GumdropColors> {
  const new({
    required this.scheme,
    required this.roles,
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
    required this.outline,
    required this.tabBar,
    required this.tabBarLine,
    required this.fieldRim,
    required this.cardTrack,
    required this.cardOutline,
    required this.avatarRing,
    required this.accentMark,
    required this.notGoingIcon,
    required this.you,
    required this.blueRaspberry,
    required this.lemon,
    required this.mint,
    required this.cherry,
    required this.tangerine,
    required this.grape,
    required this.bubblegum,
    required this.sticker,
    this.onCard = false,
  });

  /// The colors of [scheme], on the page or ([onCard]) on a card.
  // A static, not a factory: the name reads as what it picks (spec 4.3).
  // ignore: prefer_constructors_over_static_methods
  static GumdropColors forScheme(TeamScheme scheme, {bool onCard = false}) {
    final r = SchemeRoles.of(scheme);
    GumdropAccent candy(
      Color face,
      Color lip,
      Color pageText,
      Color cardText,
    ) =>
        GumdropAccent(face: face, lip: lip, text: onCard ? cardText : pageText);
    final coral = candy(
      CandyFaces.coral,
      r.candyLipCoral,
      r.accentText,
      r.cardAccentText,
    );
    return GumdropColors(
      scheme: scheme,
      roles: r,
      onCard: onCard,
      page: r.page,
      surface: r.card,
      surfaceBorder: r.cardRim,
      surfaceBorderWidth: 2,
      raisedFace: const Color(0x00000000),
      raisedBorder: onCard ? r.cardOutline : r.outline,
      raisedBorderWidth: 2,
      raisedHighlight: const Color(0x00000000),
      raisedLip: const Color(0x00000000),
      well: onCard ? r.cardTrack : r.field,
      inputFill: r.field,
      inputBorder: onCard ? r.cardOutline : r.outline,
      divider: onCard ? r.cardTrack : r.hairline,
      switchOffTrack: onCard ? r.cardTrack : r.field,
      textPrimary: r.text,
      textMuted: r.cardMuted,
      textOnPage: r.text,
      textMutedOnPage: onCard ? r.cardMuted : r.pageMuted,
      successOnPage: onCard ? r.cardGoingText : r.goingText,
      ink: r.candyInk,
      headingText: r.text,
      headingShadow: onCard ? const Color(0x00000000) : r.titleDrop,
      headingTextOnCard: r.text,
      headingShadowOnCard: const Color(0x00000000),
      pageShadow: r.cardRim,
      selectedRingOuter: r.text,
      swatchInsetRing: onCard ? r.cardOutline : r.outline,
      badgeRing: onCard ? r.card : r.page,
      outline: onCard ? r.cardOutline : r.outline,
      tabBar: r.tabbar,
      tabBarLine: r.tabbarLine,
      fieldRim: r.fieldRim,
      cardTrack: r.cardTrack,
      cardOutline: r.cardOutline,
      avatarRing: r.avatarRing,
      accentMark: r.accentMark,
      notGoingIcon: onCard ? r.cardAccentText : r.notGoingIcon,
      you: coral,
      cherry: coral,
      sticker: coral,
      mint: candy(
        CandyFaces.mint,
        r.candyLipMint,
        r.goingText,
        r.cardGoingText,
      ),
      lemon: candy(CandyFaces.lemon, r.candyLipLemon, r.maybeText, r.maybeText),
      tangerine: candy(
        CandyFaces.tangerine,
        r.candyLipTangerine,
        r.gameText,
        r.typeGame,
      ),
      grape: candy(
        CandyFaces.grape,
        r.grapeLip,
        r.grapePageText,
        r.typePractice,
      ),
      bubblegum: candy(
        CandyFaces.bubblegum,
        r.bubblegumLip,
        r.bubblegumPageText,
        r.typeOther,
      ),
      blueRaspberry: candy(
        CandyFaces.blueRaspberry,
        r.blueRaspberryLip,
        r.blueRaspberryPageText,
        r.blueRaspberryCardText,
      ),
    );
  }

  /// The colors in effect at [context]: the theme's, or Army green under a
  /// bare MaterialApp (some tests).
  static GumdropColors of(BuildContext context) =>
      Theme.of(context).extension<GumdropColors>() ?? _army;

  static final GumdropColors _army = forScheme(TeamScheme.army);

  /// The top inset on every candy gumdrop: `inset 0 2px 0`.
  static const accentHighlight = Color(0x59FFFFFF);

  /// The @mention pill inside your own bubble.
  static const mentionBg = Color(0xFFFFFFFF);

  /// The switch's knob.
  static const switchKnob = Color(0xFFFFFFFF);

  /// The color scheme these come from.
  final TeamScheme scheme;

  /// Its roles, for what the fields above don't name.
  final SchemeRoles roles;

  /// Whether these are the card context (see [card]).
  final bool onCard;

  /// The screen's background.
  final Color page;

  /// Cards, sheets, dialogs.
  final Color surface;

  /// A card's 2 px rim, and its hard lip.
  final Color surfaceBorder;

  /// 2 in every scheme.
  final double surfaceBorderWidth;

  /// The secondary button's face: none, it's an outlined pill.
  final Color raisedFace;

  /// The outlined pill's border.
  final Color raisedBorder;

  /// 2 in every scheme.
  final double raisedBorderWidth;

  /// The top inset on the secondary button: none.
  final Color raisedHighlight;

  /// The secondary button's lip: none.
  final Color raisedLip;

  /// A recessed fill: tracks, quotes, the segmented control, icon discs.
  final Color well;

  /// Text fields and the composer.
  final Color inputFill;

  /// Around text fields.
  final Color inputBorder;

  /// Hairlines and list-row rules.
  final Color divider;

  /// An off switch's track.
  final Color switchOffTrack;

  /// Text on cards and on the page.
  final Color textPrimary;

  /// Secondary text on a card.
  final Color textMuted;

  /// Text straight on the page.
  final Color textOnPage;

  /// Secondary text straight on the page.
  final Color textMutedOnPage;

  /// A success check or count straight on the page.
  final Color successOnPage;

  /// Text, icons, and marks on every candy face.
  final Color ink;

  /// Lilita titles.
  final Color headingText;

  /// The hard drop under Lilita titles, or transparent for none.
  final Color headingShadow;

  /// Lilita titles inside a card.
  final Color headingTextOnCard;

  /// No drop inside a card.
  final Color headingShadowOnCard;

  /// Hard lips of things on the page.
  final Color pageShadow;

  /// The ring around a picked swatch.
  final Color selectedRingOuter;

  /// The inset ring on swatches.
  final Color swatchInsetRing;

  /// The cutout ring around an unread badge or dot.
  final Color badgeRing;

  /// Outlines on the page: unpicked choices, Add a photo, previews.
  final Color outline;

  /// The bottom tab bar's fill.
  final Color tabBar;

  /// The rule along the top of the tab bar.
  final Color tabBarLine;

  /// A thin inset ring around fields, or transparent for none.
  final Color fieldRim;

  /// The empty part of a bar on a card.
  final Color cardTrack;

  /// Outlines on a card.
  final Color cardOutline;

  /// A thin inset ring on icons and badges, or transparent for none.
  final Color avatarRing;

  /// Coral marks on the page: the pin, underlines, the Directions icon.
  final Color accentMark;

  /// The x on an unpicked Not going button.
  final Color notGoingIcon;

  /// Your messages, send, the + button, the picked tab: coral.
  final GumdropAccent you;

  /// Meetings.
  final GumdropAccent blueRaspberry;

  /// Maybe; pinned.
  final GumdropAccent lemon;

  /// Going; switches on.
  final GumdropAccent mint;

  /// Can't go; unread; errors.
  final GumdropAccent cherry;

  /// Games.
  final GumdropAccent tangerine;

  /// Practices.
  final GumdropAccent grape;

  /// Other events, your reactions, polls.
  final GumdropAccent bubblegum;

  /// The stencil eyebrow and the back button: coral.
  final GumdropAccent sticker;

  /// Light, or dark, for Material and the status bar: the page and the
  /// cards agree in every scheme.
  Brightness get brightness =>
      scheme.isDark ? Brightness.dark : Brightness.light;

  /// What text sits on in this context: the page, or a card.
  Color get background => onCard ? surface : page;

  /// The card context, as `GumdropSurface` applies it.
  GumdropColors get card => onCard ? this : forScheme(scheme, onCard: true);

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
  /// one pixel further down each, or none when [color] is transparent.
  static List<Shadow> stackedShadow(Color color, int steps) => [
    if (color.a > 0)
      for (var i = 1; i <= steps; i++)
        Shadow(color: color, offset: Offset(0, i.toDouble())),
  ];

  /// Checks [a] against [b] for 4.5:1 (for tests and asserts).
  static bool reads(Color a, Color b) => ColorMath.contrast(a, b) >= 4.5;

  @override
  GumdropColors copyWith({
    TeamScheme? scheme,
    SchemeRoles? roles,
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
    Color? outline,
    Color? tabBar,
    Color? tabBarLine,
    Color? fieldRim,
    Color? cardTrack,
    Color? cardOutline,
    Color? avatarRing,
    Color? accentMark,
    Color? notGoingIcon,
    GumdropAccent? you,
    GumdropAccent? blueRaspberry,
    GumdropAccent? lemon,
    GumdropAccent? mint,
    GumdropAccent? cherry,
    GumdropAccent? tangerine,
    GumdropAccent? grape,
    GumdropAccent? bubblegum,
    GumdropAccent? sticker,
  }) => GumdropColors(
    scheme: scheme ?? this.scheme,
    roles: roles ?? this.roles,
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
    outline: outline ?? this.outline,
    tabBar: tabBar ?? this.tabBar,
    tabBarLine: tabBarLine ?? this.tabBarLine,
    fieldRim: fieldRim ?? this.fieldRim,
    cardTrack: cardTrack ?? this.cardTrack,
    cardOutline: cardOutline ?? this.cardOutline,
    avatarRing: avatarRing ?? this.avatarRing,
    accentMark: accentMark ?? this.accentMark,
    notGoingIcon: notGoingIcon ?? this.notGoingIcon,
    you: you ?? this.you,
    blueRaspberry: blueRaspberry ?? this.blueRaspberry,
    lemon: lemon ?? this.lemon,
    mint: mint ?? this.mint,
    cherry: cherry ?? this.cherry,
    tangerine: tangerine ?? this.tangerine,
    grape: grape ?? this.grape,
    bubblegum: bubblegum ?? this.bubblegum,
    sticker: sticker ?? this.sticker,
  );

  @override
  GumdropColors lerp(GumdropColors? other, double t) {
    if (other == null || identical(other, this)) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    final near = t < 0.5 ? this : other;
    return GumdropColors(
      scheme: near.scheme,
      roles: near.roles,
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
      outline: c(outline, other.outline),
      tabBar: c(tabBar, other.tabBar),
      tabBarLine: c(tabBarLine, other.tabBarLine),
      fieldRim: c(fieldRim, other.fieldRim),
      cardTrack: c(cardTrack, other.cardTrack),
      cardOutline: c(cardOutline, other.cardOutline),
      avatarRing: c(avatarRing, other.avatarRing),
      accentMark: c(accentMark, other.accentMark),
      notGoingIcon: c(notGoingIcon, other.notGoingIcon),
      you: you.lerp(other.you, t),
      blueRaspberry: blueRaspberry.lerp(other.blueRaspberry, t),
      lemon: lemon.lerp(other.lemon, t),
      mint: mint.lerp(other.mint, t),
      cherry: cherry.lerp(other.cherry, t),
      tangerine: tangerine.lerp(other.tangerine, t),
      grape: grape.lerp(other.grape, t),
      bubblegum: bubblegum.lerp(other.bubblegum, t),
      sticker: sticker.lerp(other.sticker, t),
    );
  }
}
