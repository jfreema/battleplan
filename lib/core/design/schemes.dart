import 'dart:math' as math;

import 'package:battleplan/core/camp_theme.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/camp_palette.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart' show GumdropColors;
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:battleplan/core/theme_override.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';

export 'package:battleplan/core/design/camp_palette.dart';
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

/// The color roles of one color scheme (SPEC SET-2, §7.4), which
/// [GumdropColors.forScheme] fills the theme from. Since Boot Camp Mix
/// (#85) there are three schemes, Army green, Black and Light, each built
/// from its [CampPalette] ([SchemeRoles.camp]); the roles' names are the
/// Open Field design's, which the widgets read.
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
    this._youLip,
    this._youInk,
    this.palette = CampPalette.army,
  });

  /// A Boot Camp Mix scheme's roles from its tokens (#85): ink outlines and
  /// lips, panels for cards, fields and pop-ups, and the colored words made
  /// to read where they sit.
  factory camp(CampPalette p) {
    Color on(Color c, Color bg, {double minimum = 4.5}) =>
        ColorMath.readable(c, [bg], minimum: minimum);
    // Candy Pop's panels are white under navy lettering while its page is
    // blue under white (#86): text boxes and menus opened from the page
    // take the camouflage's deeper blue, where the page's white reads.
    final twoLetterings = p.panelText != p.text;
    final field = twoLetterings ? p.camoGround : p.panel;
    // Muted text, made to read on the page, fields, and the tab bar alike,
    // and on panels where they share the page's lettering (Army green's
    // panel is a shade lighter than its page).
    final muted = ColorMath.readable(p.muted, [
      p.page,
      field,
      p.tabBar,
      if (!twoLetterings) p.panel,
    ]);
    final cardMuted = twoLetterings
        ? ColorMath.readable(p.panelMuted, [p.panel])
        : muted;
    return SchemeRoles(
      palette: p,
      page: p.page,
      text: p.text,
      pageMuted: muted,
      hairline: p.ink,
      outline: p.ink,
      tabbar: p.tabBar,
      tabbarLine: p.ink,
      field: field,
      fieldRim: p.ink,
      card: p.panel,
      cardRim: p.ink,
      cardMuted: cardMuted,
      // Wells and tracks on panels: the tools row's shade, but on Candy
      // Pop's white panels a pale blue its navy reads on (#86).
      cardTrack: twoLetterings ? p.unansweredTag : p.toolsRow,
      cardOutline: p.ink,
      cardText: p.panelText,
      cardField: p.panel,
      cardMaybeText: on(p.orange, p.panel),
      popup: field,
      candyInk: p.ink,
      candyLipCoral: p.shadow,
      candyLipMint: p.shadow,
      candyLipLemon: p.shadow,
      candyLipTangerine: p.shadow,
      titleDrop: p.shadow,
      avatarRing: p.ink,
      accentText: on(p.red, p.page),
      accentMark: p.mustard,
      notGoingIcon: on(p.red, p.page, minimum: 3),
      goingText: on(p.green, p.page),
      maybeText: on(p.orange, p.page),
      cardGoingText: on(p.green, p.panel),
      cardAccentText: on(p.red, p.panel),
      gameText: on(p.red, p.page),
      typeGame: on(p.red, p.panel),
      typePractice: on(p.blue, p.panel),
      typeOther: on(p.purple, p.panel),
      grapePageText: on(p.blue, p.page),
      bubblegumPageText: on(p.purple, p.page),
      blueRaspberryPageText: on(p.blue, p.page),
      blueRaspberryCardText: on(p.blue, p.panel),
      grapeLip: p.shadow,
      bubblegumLip: p.shadow,
      blueRaspberryLip: p.shadow,
      cherryLip: p.shadow,
      you: p.balloon,
    );
  }

  /// [scheme]'s Boot Camp Mix roles with the theme editor's [colors] (#88):
  /// what the app draws once they're saved, and the editor's preview.
  factory edited(TeamScheme scheme, CampColors colors) => SchemeRoles.camp(
    builtIn(scheme).palette.withColors({
      for (final MapEntry(:key, :value) in colors.entries) key: Color(value),
    }),
  );

  /// The Boot Camp Mix tokens these roles come from (#85): the candy faces,
  /// the camouflage, and the rest the roles don't name.
  final CampPalette palette;

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

  /// Hard drop under stencil titles: team name, Teams, opponent, section and screen titles (transparent: none).
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
  /// scheme; a theme can set its own in the theme editor (#82).
  final Color you;

  final Color? _youLip;
  final Color? _youInk;

  /// The "you" candy's lip: [candyLipCoral] but under a theme's own [you]
  /// (#82), where a coral lip takes a deeper shade of it.
  Color get youLip => _youLip ?? candyLipCoral;

  /// Text and icons on the "you" face: the [candyInk], or white on a theme's
  /// own [you] the ink doesn't read on, like maroon (#83).
  Color get youInk => _youInk ?? candyInk;

  /// These roles with a theme's own colors (#82, #83): the [page], the
  /// [card], the text on them ([text], [cardText]), and [you]. What depends
  /// on them follows, so a theme can't leave anything hard to read that it
  /// didn't have to:
  ///
  /// * The card's text follows [text] where it was the page's (all but
  ///   Candy Pop), and the pop-up color follows [card] where it was the
  ///   card's.
  /// * Muted text, outlines, dividers, and rings in the text's color take
  ///   the new text color; muted text is then made to read 4.5:1.
  /// * Colored text (Going, Maybe, warnings, event types, the candies' text
  ///   shades) on a new page or card is made to read 4.5:1 there, its hue
  ///   kept; marks (the tab marker, underlines, the Not going x) 3:1.
  /// * A new [you] brings its marks along: a coral mark takes it, a coral
  ///   lip ([youLip]) takes a deeper shade of it, and its writing
  ///   ([youInk]) is white where the ink doesn't read; a scheme's own gold,
  ///   silver, or ink stays.
  ///
  /// Anything still hard to read is the theme's own pick (text on a page
  /// too close to it), which `themeProblems` finds and the editor and the
  /// server refuse.
  SchemeRoles withOverrides({
    Color? page,
    Color? card,
    Color? you,
    Color? text,
    Color? cardText,
  }) {
    final newPage = page ?? this.page;
    final newCard = card ?? this.card;
    final newText = text ?? this.text;
    final newCardText =
        cardText ??
        (text != null && this.cardText == this.text ? text : this.cardText);
    final newYou = you != null && you != this.you ? you : null;
    final pageChanged = newPage != this.page;
    final cardChanged = newCard != this.card;
    final textChanged = newText != this.text;
    final cardTextChanged = newCardText != this.cardText;

    // A role in the base text's color, at any opacity, takes the new one's.
    Color onText(Color role) => _sameRgb(role, this.text) && textChanged
        ? newText.withValues(alpha: role.a)
        : role;
    Color onCardText(Color role) =>
        _sameRgb(role, this.cardText) && cardTextChanged
        ? newCardText.withValues(alpha: role.a)
        : role;
    // Muted text: follows the text, as a mix toward the background where
    // it's its own color; then readable, where the text itself is (a text
    // that isn't is the theme's own problem, said once).
    Color muted(Color role, Color fg, Color bg, Color newFg, Color newBg) {
      if (newFg == fg && newBg == bg) return role;
      final mixed = _sameRgb(role, fg)
          ? newFg.withValues(alpha: role.a)
          : Color.lerp(newBg, newFg, _mixOf(role, fg, bg))!;
      return ColorMath.contrast(newFg, newBg) < 4.5
          ? mixed
          : _readableOn(mixed, newBg, 4.5);
    }

    Color onPage(Color role, {double minimum = 4.5}) =>
        pageChanged ? _readableOn(role, newPage, minimum) : role;
    Color onCard(Color role) =>
        cardChanged ? _readableOn(role, newCard, 4.5) : role;

    final youLch = newYou == null ? null : ColorMath.lch(newYou);
    final markBase = newYou != null && _coralish(accentMark)
        ? newYou
        : accentMark;
    return SchemeRoles(
      page: newPage,
      text: newText,
      pageMuted: muted(pageMuted, this.text, this.page, newText, newPage),
      hairline: onText(hairline),
      outline: onText(outline),
      tabbar: tabbar,
      tabbarLine: onText(tabbarLine),
      field: field,
      fieldRim: onText(fieldRim),
      card: newCard,
      cardRim: cardRim,
      cardMuted: muted(
        cardMuted,
        this.cardText,
        this.card,
        newCardText,
        newCard,
      ),
      cardTrack: onCardText(cardTrack),
      cardOutline: onCardText(cardOutline),
      cardText: newCardText,
      cardField: cardField,
      cardMaybeText: onCard(cardMaybeText),
      candyInk: candyInk,
      candyLipCoral: candyLipCoral,
      candyLipMint: candyLipMint,
      candyLipLemon: candyLipLemon,
      candyLipTangerine: candyLipTangerine,
      titleDrop: titleDrop,
      avatarRing: onText(avatarRing),
      accentText: onPage(accentText),
      accentMark: pageChanged || markBase != accentMark
          ? _readableOn(markBase, newPage, 3)
          : accentMark,
      notGoingIcon: onPage(notGoingIcon, minimum: 3),
      goingText: onPage(goingText),
      maybeText: onPage(maybeText),
      cardGoingText: onCard(cardGoingText),
      cardAccentText: onCard(cardAccentText),
      gameText: onPage(gameText),
      typeGame: onCard(typeGame),
      typePractice: onCard(typePractice),
      typeOther: onCard(typeOther),
      grapePageText: onPage(grapePageText),
      bubblegumPageText: onPage(bubblegumPageText),
      blueRaspberryPageText: onPage(blueRaspberryPageText),
      blueRaspberryCardText: onCard(blueRaspberryCardText),
      grapeLip: grapeLip,
      bubblegumLip: bubblegumLip,
      blueRaspberryLip: blueRaspberryLip,
      cherryLip: cherryLip,
      popup: cardChanged && popup == this.card ? newCard : popup,
      you: newYou ?? this.you,
      youLip: youLch == null || ColorMath.luminance(candyLipCoral) < 0.03
          ? _youLip
          : ColorMath.fromLch(math.max(youLch.l - 28, 0), youLch.c, youLch.h),
      youInk: newYou == null ? _youInk : _inkOn(newYou),
      palette: palette,
    );
  }

  /// The ink, or white where the ink doesn't read 4.5:1 and white reads
  /// better (#83): the writing on a "you" face of [face].
  Color _inkOn(Color face) {
    final ink = ColorMath.contrast(candyInk, face);
    if (ink >= 4.5) return candyInk;
    return ColorMath.contrast(_white, face) > ink ? _white : candyInk;
  }

  static const _white = Color(0xFFFFFFFF);

  /// Whether [a] and [b] are the same color but for their opacity.
  static bool _sameRgb(Color a, Color b) =>
      (a.toARGB32() & 0xFFFFFF) == (b.toARGB32() & 0xFFFFFF);

  /// How far [muted] is from [bg] toward [fg] (0 to 1): a muted text color
  /// as a mix of the text and the page, so a new pair mixes the same.
  static double _mixOf(Color muted, Color fg, Color bg) {
    final flat = Color.alphaBlend(muted, bg);
    var sum = 0.0;
    var weight = 0.0;
    for (final (m, f, b) in [
      (flat.r, fg.r, bg.r),
      (flat.g, fg.g, bg.g),
      (flat.b, fg.b, bg.b),
    ]) {
      final span = f - b;
      if (span.abs() < 0.08) continue;
      sum += (m - b) / span * span.abs();
      weight += span.abs();
    }
    return weight == 0 ? 0.8 : (sum / weight).clamp(0.5, 1.0);
  }

  /// [color] (as drawn over [bg], if see-through) made to read [minimum]:1
  /// on [bg], its hue kept; [color] itself when it already does.
  static Color _readableOn(Color color, Color bg, double minimum) {
    final flat = Color.alphaBlend(color, bg);
    if (ColorMath.contrast(flat, bg) >= minimum) return color;
    return ColorMath.readable(flat, [bg], minimum: minimum);
  }

  /// Whether [color] is a coral mark a theme's own "you" color replaces.
  static bool _coralish(Color color) {
    final c = ColorMath.lch(color);
    return c.c > 30 &&
        ColorMath.hueDistance(c.h, ColorMath.lch(CandyFaces.coral).h) < 20;
  }

  /// Army green (#85): an olive page, panels a shade lighter, cream
  /// lettering, woodland camouflage.
  static final army = SchemeRoles.camp(CampPalette.army);

  /// Black (#85; the default, as Dark was): a black page, charcoal panels,
  /// cream lettering, night camouflage, and your own balloons light blue.
  static final dark = SchemeRoles.camp(CampPalette.black);

  /// Light (#85): a sand page, white panels, black lettering, desert
  /// camouflage.
  static final light = SchemeRoles.camp(CampPalette.light);

  /// Sky Blue (#86): a sky-blue page and paler sky-blue panels, navy
  /// lettering, a navy and sky camouflage.
  static final sky = SchemeRoles.camp(CampPalette.sky);

  /// Candy Pop (#86): a bright blue page under white, white panels under
  /// navy.
  static final candypop = SchemeRoles.camp(CampPalette.candyPop);

  /// Central Wildcats (#86): maroon and silver, with black ink.
  static final wildcat = SchemeRoles.camp(CampPalette.wildcat);

  /// Geaux Tigahs (#86): purple and gold.
  static final purplegold = SchemeRoles.camp(CampPalette.purpleGold);

  /// Graphite (#89): slate and coral.
  static final graphite = SchemeRoles.camp(CampPalette.graphite);

  /// Teal Wave (#89): deep teal and aqua.
  static final tealwave = SchemeRoles.camp(CampPalette.tealWave);

  /// Navy Steel (#89), in Open Field's Navy's stored value (D81).
  static final navy = SchemeRoles.camp(CampPalette.navySteel);

  /// Forest (#89), in Open Field's Forest green's stored value (D81).
  static final darkarmy = SchemeRoles.camp(CampPalette.forest);

  /// The roles of [scheme]'s Boot Camp Mix scheme ([TeamSchemeLook.look]),
  /// whatever was stored.
  static SchemeRoles builtIn(TeamScheme scheme) => switch (scheme.look) {
    TeamScheme.army => army,
    TeamScheme.light => light,
    TeamScheme.sky => sky,
    TeamScheme.candypop => candypop,
    TeamScheme.wildcat => wildcat,
    TeamScheme.purplegold => purplegold,
    TeamScheme.graphite => graphite,
    TeamScheme.tealwave => tealwave,
    TeamScheme.navy => navy,
    TeamScheme.darkarmy => darkarmy,
    _ => dark,
  };

  /// The roles [scheme] is drawn in (#85): its Boot Camp Mix scheme's, with
  /// the colors the theme editor changed (#88). The first editor's colors
  /// (#82, `config/app.themes`) no longer apply.
  static SchemeRoles of(TeamScheme scheme) =>
      ThemeCatalog.editedRoles(scheme) ?? builtIn(scheme);

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
      text: color(theme.text),
      cardText: color(theme.cardText),
    );
  }
}

/// The colors the theme editor set (#82), from `config/app.themes`, as
/// the app root installs them ([install]) whenever they change, so every
/// [SchemeRoles.of] and `AppTheme` sees them. Held here rather than passed
/// down because the roles are read everywhere a scheme is drawn.
abstract final class ThemeCatalog {
  static Map<TeamScheme, ThemeOverride> _themes = const {};
  static Map<TeamScheme, CampColors> _camp = const {};
  static final _edited = <TeamScheme, SchemeRoles>{};
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

  /// Puts the theme editor's Boot Camp Mix colors in place (#88), from
  /// `config/app.campThemes`: those that read, which every scheme is then
  /// drawn in. Nothing happens when they're what's there.
  static void installCamp(Map<TeamScheme, CampColors> colors) {
    if (campThemesEqual(colors, _camp)) return;
    _camp = Map.unmodifiable(colors);
    _edited.clear();
    _version++;
  }

  /// The Boot Camp Mix colors installed now, by scheme.
  static Map<TeamScheme, CampColors> get campThemes => _camp;

  /// [scheme]'s roles with the theme editor's colors, built once per change,
  /// or null when its Boot Camp Mix scheme has none.
  static SchemeRoles? editedRoles(TeamScheme scheme) {
    final look = scheme.look;
    final colors = _camp[look];
    if (colors == null || colors.isEmpty) return null;
    return _edited.putIfAbsent(look, () => SchemeRoles.edited(look, colors));
  }

  /// The schemes the pickers offer: Boot Camp Mix's eleven (#85, #86, #89). The
  /// other built-in schemes and saved themes are no longer offered; a pick
  /// of one shows in its closest ([TeamSchemeLook.look]).
  static const List<TeamScheme> available = bootCampSchemes;
}

/// The Boot Camp Mix schemes, in picker order (#85, owner's pick
/// 2026-11-22: "let's replace the existing themes with these 3 themes";
/// #86, the same day: "add 4 new themes to the UI"; and #89, the next:
/// Graphite, Teal Wave, Navy Steel, and Forest).
const List<TeamScheme> bootCampSchemes = [
  TeamScheme.army,
  TeamScheme.dark,
  TeamScheme.light,
  TeamScheme.sky,
  TeamScheme.candypop,
  TeamScheme.wildcat,
  TeamScheme.purplegold,
  TeamScheme.graphite,
  TeamScheme.tealwave,
  TeamScheme.navy,
  TeamScheme.darkarmy,
];

/// What each scheme is called, which Boot Camp Mix scheme it's drawn in,
/// and whether its page is dark.
extension TeamSchemeLook on TeamScheme {
  /// The Boot Camp Mix scheme this is drawn in (#85, #86, #89): itself for
  /// the eleven; for a scheme the app no longer offers, the closest. Stored
  /// picks are never rewritten, so an older app still shows its own. Since
  /// #89 Open Field's Navy is Navy Steel and its Forest green is Forest
  /// (D81); Scoreboard goes to Black; Sky Blue Pop to Sky Blue; a saved
  /// theme to Black or Light by how dark its page is.
  TeamScheme get look => switch (this) {
    TeamScheme.army => TeamScheme.army,
    TeamScheme.light => TeamScheme.light,
    TeamScheme.sky || TeamScheme.skyblue => TeamScheme.sky,
    TeamScheme.candypop => TeamScheme.candypop,
    TeamScheme.wildcat => TeamScheme.wildcat,
    TeamScheme.purplegold => TeamScheme.purplegold,
    TeamScheme.graphite => TeamScheme.graphite,
    TeamScheme.tealwave => TeamScheme.tealwave,
    TeamScheme.navy => TeamScheme.navy,
    TeamScheme.darkarmy => TeamScheme.darkarmy,
    TeamScheme.dark || TeamScheme.scoreboard => TeamScheme.dark,
    _ => _savedLook,
  };

  /// A saved theme's: Light when its page (its own, or its base's) is
  /// light, else Black, as for a slot with no theme.
  TeamScheme get _savedLook {
    final theme = ThemeCatalog.themeOf(this);
    final page = theme?.page;
    final light = page != null
        ? ThemeData.estimateBrightnessForColor(Color(page)) == Brightness.light
        : theme?.base?.look == TeamScheme.light;
    return light ? TeamScheme.light : TeamScheme.dark;
  }

  /// Light text on a dark page: every scheme but Light and Sky Blue, as
  /// its page decides.
  bool get isDark =>
      ThemeData.estimateBrightnessForColor(
        SchemeRoles.builtIn(this).palette.page,
      ) ==
      Brightness.dark;

  /// "Army green", "Black", "Sky Blue" and the rest: what this is drawn in.
  String label(AppLocalizations l10n) => switch (look) {
    TeamScheme.army => l10n.schemeArmy,
    TeamScheme.light => l10n.schemeLight,
    TeamScheme.sky => l10n.schemeSky,
    TeamScheme.candypop => l10n.schemeCandypop,
    TeamScheme.wildcat => l10n.schemeWildcat,
    TeamScheme.purplegold => l10n.schemePurplegold,
    TeamScheme.graphite => l10n.schemeGraphite,
    TeamScheme.tealwave => l10n.schemeTealwave,
    TeamScheme.navy => l10n.schemeNavy,
    TeamScheme.darkarmy => l10n.schemeDarkarmy,
    _ => l10n.schemeDark,
  };

  /// The short line under the name: "Olive page, cream lettering".
  String shortLabel(AppLocalizations l10n) => switch (look) {
    TeamScheme.army => l10n.schemeArmyShort,
    TeamScheme.light => l10n.schemeLightShort,
    TeamScheme.sky => l10n.schemeSkyShort,
    TeamScheme.candypop => l10n.schemeCandypopShort,
    TeamScheme.wildcat => l10n.schemeWildcatShort,
    TeamScheme.purplegold => l10n.schemePurplegoldShort,
    TeamScheme.graphite => l10n.schemeGraphiteShort,
    TeamScheme.tealwave => l10n.schemeTealwaveShort,
    TeamScheme.navy => l10n.schemeNavyShort,
    TeamScheme.darkarmy => l10n.schemeDarkarmyShort,
    _ => l10n.schemeDarkShort,
  };
}
