import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:material_ui/material_ui.dart';

/// One candy color: the gumdrop's [face], the hard [lip] under it, and
/// [text], the color for writing in this hue on the theme's cards.
@immutable
class GumdropAccent {
  const new({
    required this.face,
    required this.lip,
    required this.text,
    this.ink,
  });

  final Color face;
  final Color lip;

  /// Readable (4.5:1) on `surface`.
  final Color text;

  /// Text and icons on [face] when they aren't the scheme's candy ink
  /// ([GumdropColors.ink]): the warning red's white. Read it with
  /// [GumdropColors.inkOn].
  final Color? ink;

  GumdropAccent lerp(GumdropAccent other, double t) => GumdropAccent(
    face: Color.lerp(face, other.face, t)!,
    lip: Color.lerp(lip, other.lip, t)!,
    text: Color.lerp(text, other.text, t)!,
    ink: ink == null && other.ink == null
        ? null
        : Color.lerp(ink ?? other.ink, other.ink ?? ink, t),
  );

  @override
  bool operator ==(Object other) =>
      other is GumdropAccent &&
      other.face == face &&
      other.lip == lip &&
      other.text == text &&
      other.ink == ink;

  @override
  int get hashCode => Object.hash(face, lip, text, ink);
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
    required this.popup,
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
    required this.coral,
    this.onCard = false,
    this.shipped = false,
  });

  /// The colors of [scheme], on the page or ([onCard]) on a card.
  ///
  /// [shipped] takes [scheme] (a built-in one) as the app ships it, without
  /// the theme editor's colors: the Super Admin Panel's (#83), so a theme
  /// that's hard to read can always be put right.
  // A static, not a factory: the name reads as what it picks (spec 4.3).
  // ignore: prefer_constructors_over_static_methods
  static GumdropColors forScheme(
    TeamScheme scheme, {
    bool onCard = false,
    bool shipped = false,
  }) {
    final r = shipped ? SchemeRoles.builtIn(scheme) : SchemeRoles.of(scheme);
    GumdropAccent candy(
      Color face,
      Color lip,
      Color pageText,
      Color cardText, {
      Color? ink,
    }) => GumdropAccent(
      face: face,
      lip: lip,
      text: onCard ? cardText : pageText,
      ink: ink,
    );
    final p = r.palette;
    // The lettering on a colored block (#85: "Lettering on any bright block
    // is always ink"): the ink, or black where the ink doesn't read 4.5:1
    // on it (the reds, Light's blue and purple), or white where neither
    // does. Null keeps the scheme's ink.
    Color? letteringOn(Color face) =>
        ColorMath.contrast(r.candyInk, face) >= 4.5
        ? null
        : ColorMath.onColor(face, dark: const Color(0xFF000000));
    // Red, as the scheme ships it: the "Cherry" a person picks for their
    // icon, which stays red whatever "you" is (#83, #85).
    final coral = candy(
      p.red,
      r.candyLipCoral,
      r.accentText,
      r.cardAccentText,
      ink: letteringOn(p.red),
    );
    // "You": your own balloon's color (#85: mustard, or light blue on
    // Black), its text that color made to read on the page or card, with
    // ink writing on it (white where the ink doesn't read, #83).
    final you = candy(
      r.you,
      r.youLip,
      ColorMath.readable(r.you, [r.page]),
      ColorMath.readable(r.you, [r.card]),
      ink: r.youInk == r.candyInk ? null : r.youInk,
    );
    return GumdropColors(
      scheme: scheme,
      roles: r,
      onCard: onCard,
      shipped: shipped,
      page: r.page,
      surface: r.card,
      // On a card, pop-ups are cards too; from the page, Candy Pop's keep
      // the deeper blue its white rows read on (#72).
      popup: onCard ? r.card : r.popup,
      surfaceBorder: r.cardRim,
      // Boot Camp Mix (#85): panels in a 3 px ink outline on a hard shadow,
      // and push buttons in the panel color, outlined the same.
      surfaceBorderWidth: 3,
      raisedFace: r.card,
      raisedBorder: onCard ? r.cardOutline : r.outline,
      raisedBorderWidth: 3,
      raisedHighlight: const Color(0x00000000),
      raisedLip: p.shadow,
      // Wells (a segmented choice, a number's disc): the panel's track, but
      // on Candy Pop's blue page its deeper blue, where white reads (#86).
      well: onCard || r.cardText == r.text ? r.cardTrack : r.field,
      inputFill: onCard ? r.cardField : r.field,
      inputBorder: onCard ? r.cardOutline : r.outline,
      divider: r.hairline,
      switchOffTrack: r.cardTrack,
      // A card's own text where it isn't the page's (Candy Pop's navy on
      // white, #72).
      textPrimary: onCard ? r.cardText : r.text,
      textMuted: r.cardMuted,
      textOnPage: onCard ? r.cardText : r.text,
      textMutedOnPage: onCard ? r.cardMuted : r.pageMuted,
      successOnPage: onCard ? r.cardGoingText : r.goingText,
      ink: r.candyInk,
      headingText: onCard ? r.cardText : r.text,
      // Headings are plain stencil (#85); the big outlined titles draw
      // their own stroke and drop (`OutlinedText`).
      headingShadow: const Color(0x00000000),
      headingTextOnCard: r.cardText,
      headingShadowOnCard: const Color(0x00000000),
      pageShadow: p.shadow,
      selectedRingOuter: onCard ? r.cardText : r.text,
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
      you: you,
      coral: coral,
      // Warnings: the scheme's red, with black lettering, which reads on
      // it better than white or the ink.
      cherry: candy(
        p.red,
        r.cherryLip,
        r.accentText,
        r.cardAccentText,
        ink: letteringOn(p.red),
      ),
      sticker: you,
      mint: candy(p.green, r.candyLipMint, r.goingText, r.cardGoingText),
      // Maybe is orange in Boot Camp Mix.
      lemon: candy(p.orange, r.candyLipLemon, r.maybeText, r.cardMaybeText),
      // Games are red.
      tangerine: candy(
        p.red,
        r.candyLipTangerine,
        r.gameText,
        r.typeGame,
        ink: letteringOn(p.red),
      ),
      // Practices are blue.
      grape: candy(
        p.blue,
        r.grapeLip,
        r.grapePageText,
        r.typePractice,
        ink: letteringOn(p.blue),
      ),
      // Social events are purple.
      bubblegum: candy(
        p.purple,
        r.bubblegumLip,
        r.bubblegumPageText,
        r.typeOther,
        ink: letteringOn(p.purple),
      ),
      blueRaspberry: candy(
        p.blue,
        r.blueRaspberryLip,
        r.blueRaspberryPageText,
        r.blueRaspberryCardText,
        ink: letteringOn(p.blue),
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

  /// Whether these are a built-in scheme as it ships, without the theme
  /// editor's colors (#83): the Super Admin Panel's. Its card context is
  /// too.
  final bool shipped;

  /// The screen's background.
  final Color page;

  /// Cards, sheets, dialogs.
  final Color surface;

  /// Material's menus and date and time pickers: [surface], but from
  /// Candy Pop's page, the deeper blue its rows' white reads on
  /// ([SchemeRoles.popup]).
  final Color popup;

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

  /// Text in this context: on the page, or on a card.
  final Color textPrimary;

  /// Secondary text on a card.
  final Color textMuted;

  /// Text straight on what this context is drawn on (the page, or in the
  /// card context the card): Material's onSurface.
  final Color textOnPage;

  /// Secondary text straight on the page.
  final Color textMutedOnPage;

  /// A success check or count straight on the page.
  final Color successOnPage;

  /// Text, icons, and marks on every candy face.
  final Color ink;

  /// stencil titles.
  final Color headingText;

  /// The hard drop under stencil titles, or transparent for none.
  final Color headingShadow;

  /// stencil titles inside a card.
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

  /// Coral marks on the page: underlines, the Directions icon, focus.
  final Color accentMark;

  /// The x on an unpicked Not going button.
  final Color notGoingIcon;

  /// Your messages, the main button (send, +), the picked tab, and unread
  /// counts and dots: coral (SPEC §7.2).
  final GumdropAccent you;

  /// Meetings.
  final GumdropAccent blueRaspberry;

  /// Maybe; pinned.
  final GumdropAccent lemon;

  /// Going; switches on.
  final GumdropAccent mint;

  /// Warnings only: Not going, Canceled, what's owed, errors, and Delete
  /// (SPEC §7.2). A deeper red than [you], with white on its face
  /// ([inkOn]).
  final GumdropAccent cherry;

  /// Games.
  final GumdropAccent tangerine;

  /// Practices.
  final GumdropAccent grape;

  /// Other events, your reactions, polls.
  final GumdropAccent bubblegum;

  /// The Open play sticker on a play's picture in the chat: coral, or a
  /// theme's own "you" color. (The stencil eyebrows are muted text since
  /// #12.)
  final GumdropAccent sticker;

  /// Coral as the scheme ships it, whatever a theme sets for [you] (#83):
  /// the "Cherry" people pick for their icon and their bubbles.
  final GumdropAccent coral;

  /// Light, or dark, for Material and the status bar: the page's, or in
  /// the card context the card's. They agree in every scheme but Candy
  /// Pop, whose white cards are light on its dark blue page (#72).
  Brightness get brightness => onCard
      ? ThemeData.estimateBrightnessForColor(surface)
      : scheme.isDark
      ? Brightness.dark
      : Brightness.light;

  /// What text sits on in this context: the page, or a card.
  Color get background => onCard ? surface : page;

  /// Text and icons on [accent]'s face: the candy [ink], or the accent's
  /// own (white on the warning red).
  Color inkOn(GumdropAccent accent) => accent.ink ?? ink;

  /// Can't go (#85): its picked answer and its count, `CampPalette.cantGo`
  /// in every scheme, with ink on it, on the warning red's lip; as text,
  /// the warning red's.
  GumdropAccent get cantGo => GumdropAccent(
    face: CampPalette.cantGo,
    lip: cherry.lip,
    text: cherry.text,
  );

  /// The card context, as `GumdropSurface` applies it.
  GumdropColors get card =>
      onCard ? this : forScheme(scheme, onCard: true, shipped: shipped);

  /// The candy color that marks the event type, by the event type's name
  /// (game, practice, meeting, social, other): in Boot Camp Mix (#85) red
  /// games, blue practices and meetings, purple socials, and orange for
  /// the rest.
  GumdropAccent eventAccent(String type) => switch (type) {
    'game' => tangerine,
    'practice' => grape,
    'meeting' => blueRaspberry,
    'social' => bubblegum,
    _ => lemon,
  };

  /// The hard text-shadow under a stencil heading: [steps] copies of [color]
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
    Color? popup,
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
    GumdropAccent? coral,
    bool? shipped,
  }) => GumdropColors(
    scheme: scheme ?? this.scheme,
    roles: roles ?? this.roles,
    onCard: onCard ?? this.onCard,
    page: page ?? this.page,
    surface: surface ?? this.surface,
    popup: popup ?? this.popup,
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
    coral: coral ?? this.coral,
    shipped: shipped ?? this.shipped,
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
      popup: c(popup, other.popup),
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
      coral: coral.lerp(other.coral, t),
      shipped: near.shipped,
    );
  }
}
