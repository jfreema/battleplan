import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_tint.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/gumdrop_back_button.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The Gumdrop Pop themes (SPEC §7.3, §7.4, SET-2): Gumdrop Pop Olive (the
/// default), Gumdrop Pop Dark, Gumdrop Pop Light, Gumdrop Candy, and Gumdrop
/// Arena, each
/// optionally in a team's color (team_tint.dart). Every Material widget is
/// themed in the gumdrop style; screens read the full palette with
/// [GumdropColors.of], and the fonts and shapes with [GumdropStyle.of].
abstract final class AppTheme {
  /// The theme a saved preference picks: system (no choice made) is the
  /// default, Gumdrop Pop Olive.
  static GumdropFlavor flavorOf(ThemePreference preference) =>
      switch (preference) {
        ThemePreference.system || ThemePreference.olive => GumdropFlavor.olive,
        ThemePreference.dark => GumdropFlavor.dark,
        ThemePreference.light => GumdropFlavor.light,
        ThemePreference.candy => GumdropFlavor.candy,
        ThemePreference.arena => GumdropFlavor.arena,
      };

  /// The colors of [flavor], tinted with [teamColor] (ARGB), in the page or
  /// card context.
  static GumdropColors colorsFor(
    GumdropFlavor flavor, {
    int? teamColor,
    bool onCard = false,
  }) {
    final tinted = teamTinted(GumdropColors.forFlavor(flavor), teamColor);
    return onCard ? tinted.card : tinted;
  }

  static final _cache = <(GumdropFlavor, int?, bool), ThemeData>{};

  /// The theme for [flavor] in [teamColor] (ARGB), built once and kept:
  /// there are 5 flavors, 16 colors (none and the 15 team colors), and two
  /// contexts.
  static ThemeData of(
    GumdropFlavor flavor, {
    int? teamColor,
    bool onCard = false,
  }) {
    final team = teamColor == null ? null : teamColor | 0xFF000000;
    return _cache.putIfAbsent((
      flavor,
      team,
      onCard,
    ), () => build(colorsFor(flavor, teamColor: team, onCard: onCard)));
  }

  /// The theme for a saved [preference], in [teamColor] (ARGB) inside a
  /// team.
  static ThemeData forPreference(
    ThemePreference preference, {
    int? teamColor,
  }) => of(flavorOf(preference), teamColor: teamColor);

  /// The surfaces Material puts things on, from the page out: lowest (the
  /// well), low (cards, sheets), container (menus), high (dialogs), and
  /// highest (chips, others' old-style bubbles).
  static List<Color> _containers(GumdropColors g) {
    if (g.coloredPage && !g.onCard) {
      // A colored page (Candy's blue, a team's color) has white (or ink)
      // text, so the surfaces that hold that text sit a little further from
      // it than the page does: darker under white text, lighter under ink.
      // The theme's own cards, with their text, are GumdropSurface's.
      final page = ColorMath.lch(g.page);
      final sign = g.textOnPage == g.ink ? 1 : -1;
      Color step(double by) =>
          ColorMath.fromLch((page.l + sign * by).clamp(0, 100), page.c, page.h);
      return [step(3), step(5), step(7), step(9), step(12)];
    }
    return switch (g.flavor) {
      GumdropFlavor.dark || GumdropFlavor.arena => [
        g.well,
        g.surface,
        g.surface,
        g.surface,
        g.raisedFace,
      ],
      _ => [g.surface, g.surface, g.surface, g.surface, g.well],
    };
  }

  static ThemeData build(GumdropColors g) {
    final style = GumdropStyle.forFlavor(g.flavor);
    final colorPage = g.coloredPage && !g.onCard;
    final background = g.background;
    final text = g.textOnPage;
    final muted = g.textMutedOnPage;
    final [lowest, low, container, high, highest] = _containers(g);
    // Text in a role's color must read on the page and on cards.
    final textBackgrounds = [background, low];
    Color readable(Color c) => ColorMath.readable(c, textBackgrounds);
    // White or ink on a role's color; black where neither reads (error on
    // the Black team's Candy page, lifted to a mid red).
    Color on(Color c) {
      final o = ColorMath.onColor(c, dark: g.ink);
      return ColorMath.contrast(o, c) >= 4.5
          ? o
          : ColorMath.onColor(c, dark: const Color(0xFF000000));
    }

    final primary = readable(g.you.face);
    final secondary = readable(g.bubblegum.face);
    final tertiary = readable(g.grape.face);
    final error = readable(g.cherry.text);
    final inverseSurface = g.brightness == Brightness.dark
        ? const Color(0xFFF2F6FF)
        : g.ink;
    final onInverseSurface = g.brightness == Brightness.dark
        ? g.ink
        : const Color(0xFFFFFFFF);
    final scheme = ColorScheme(
      brightness: g.brightness,
      primary: primary,
      onPrimary: on(primary),
      primaryContainer: g.you.face,
      onPrimaryContainer: g.ink,
      secondary: secondary,
      onSecondary: on(secondary),
      secondaryContainer: g.raisedFace,
      onSecondaryContainer: g.textPrimary,
      tertiary: tertiary,
      onTertiary: on(tertiary),
      tertiaryContainer: g.grape.face,
      onTertiaryContainer: g.ink,
      error: error,
      onError: on(error),
      errorContainer: g.cherry.face,
      onErrorContainer: g.ink,
      surface: background,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceDim: lowest,
      surfaceBright: highest,
      surfaceContainerLowest: lowest,
      surfaceContainerLow: low,
      surfaceContainer: container,
      surfaceContainerHigh: high,
      surfaceContainerHighest: highest,
      outline: g.divider,
      outlineVariant: g.divider,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: ColorMath.readable(g.you.face, [inverseSurface]),
      surfaceTint: const Color(0x00000000),
    );
    final appColors = AppColors.fromGumdrop(g, backgrounds: textBackgrounds);
    final textTheme = _textTheme(g, style, text);
    final buttons = GumdropButtons(g, focusRing: text, style: style);
    // Inputs on a colored page hold its text, so they're a step past the
    // page (the deepest blue on Candy's); on a card (GumdropSurface) they're
    // the theme's own.
    final inputFill = colorPage ? highest : g.inputFill;
    final inputBorder = colorPage ? g.pageShadow : g.inputBorder;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Corners.input),
      borderSide: BorderSide(color: color, width: width),
    );
    final cardSide = colorPage || g.surfaceBorderWidth == 0
        ? BorderSide.none
        : BorderSide(color: g.surfaceBorder, width: g.surfaceBorderWidth);
    final label = textTheme.labelLarge!;
    // The selected tab's gumdrop, in the tab bar and the rail.
    final indicator = style.styled(
      GumdropShape(
        lip: 3,
        lipColor: g.you.lip,
        radius: BorderRadius.circular(16),
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: g.brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(
      extensions: [g, appColors, style],
      scaffoldBackgroundColor: background,
      canvasColor: background,
      focusColor: g.you.face.withValues(alpha: 0.24),
      dividerColor: g.divider,
      textTheme: base.textTheme.merge(textTheme),
      iconTheme: IconThemeData(color: text),
      // Every automatic back button is the round lemon one (design §3.2).
      actionIconTheme: const ActionIconThemeData(
        backButtonIconBuilder: GumdropBackButton.iconBuilder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Detail screens' headers (design §3.2, §3.18): the round lemon
        // back button 12 px from the edge, then the title in Lilita One
        // with the 4-step shadow, a size under the design's 32 so the
        // app's longer titles fit beside their actions.
        leadingWidth: 72,
        titleSpacing: 12,
        titleTextStyle: textTheme.headlineMedium?.copyWith(fontSize: 28),
        iconTheme: IconThemeData(color: text),
        actionsIconTheme: IconThemeData(color: text),
        systemOverlayStyle: g.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: low,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: style.cardShape(Corners.card, side: cardSide),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: outline(inputBorder, 2),
        enabledBorder: outline(inputBorder, 2),
        disabledBorder: outline(inputBorder.withValues(alpha: 0.5), 2),
        focusedBorder: outline(colorPage ? g.you.face : primary, 2.5),
        errorBorder: outline(error, 2),
        focusedErrorBorder: outline(error, 2.5),
        hintStyle: textTheme.bodyLarge?.copyWith(color: muted),
        labelStyle: textTheme.bodyLarge?.copyWith(color: muted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        helperStyle: textTheme.bodySmall?.copyWith(color: muted),
        errorStyle: textTheme.bodySmall?.copyWith(color: error),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: Space.md,
        ),
      ),
      chipTheme: _chipTheme(g, style, label),
      filledButtonTheme: FilledButtonThemeData(
        style: buttons.accent(g.you, textStyle: label),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttons.secondary(textStyle: label),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttons.secondary(textStyle: label),
      ),
      textButtonTheme: TextButtonThemeData(
        // The small secondary gumdrop (design §3.1: See votes, Add a note).
        style: buttons.secondary(
          textStyle: label.copyWith(fontSize: TypeScale.secondary),
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
        ),
      ),
      // Every variant shares this theme, so only the focus ring is set:
      // standard icon buttons stay flat. Gumdrop icon buttons pass
      // GumdropButtons.icon as their style.
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? BorderSide(color: text, width: 3)
                : null,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: g.you.face,
        foregroundColor: g.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        iconSize: 28,
        shape: style.styled(GumdropShape(lipColor: g.you.lip)),
        sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 64),
        smallSizeConstraints: const BoxConstraints.tightFor(
          width: 44,
          height: 48,
        ),
        largeSizeConstraints: const BoxConstraints.tightFor(
          width: 96,
          height: 100,
        ),
        // The extended one ("3 new messages") is a 52 px pill on its lip.
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
        extendedTextStyle: label.copyWith(fontSize: TypeScale.secondary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.you.face : g.well,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.ink : g.textMuted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.ink : g.textMuted,
          ),
          textStyle: WidgetStatePropertyAll(label.copyWith(fontSize: 16)),
          shape: WidgetStatePropertyAll(
            style.buttonRadius == null
                ? const StadiumBorder()
                : RoundedRectangleBorder(borderRadius: style.buttonRadius!),
          ),
          // The well around the segments and between them: the track the
          // selected pill sits in (design §3.7).
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? BorderSide(color: text, width: 3)
                : BorderSide(color: g.well, width: 4),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 46)),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed)
                ? g.ink.withValues(alpha: 0.10)
                : s.contains(WidgetState.hovered)
                ? g.ink.withValues(alpha: 0.06)
                : null,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // The tab bar is a white (or card-colored) panel in every theme,
        // so its labels use the card's text colors.
        backgroundColor: g.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 76,
        indicatorColor: g.you.face,
        indicatorShape: indicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? g.ink : g.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => label.copyWith(
            fontSize: 13,
            color: s.contains(WidgetState.selected)
                ? g.textPrimary
                : g.textMuted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: low,
        indicatorColor: g.you.face,
        indicatorShape: indicator,
        selectedIconTheme: IconThemeData(color: g.ink, size: 22),
        unselectedIconTheme: IconThemeData(color: muted, size: 22),
        selectedLabelTextStyle: label.copyWith(fontSize: 13, color: text),
        unselectedLabelTextStyle: label.copyWith(fontSize: 13, color: muted),
        labelType: NavigationRailLabelType.all,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: muted,
        labelStyle: label.copyWith(fontSize: 16),
        unselectedLabelStyle: label.copyWith(fontSize: 16),
        indicatorColor: g.you.face,
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        // As close to design §3.11 as Material's switch goes: a 3 px ink
        // outline, mint when on, a white knob that's the same size on and
        // off (the empty icon keeps it from shrinking when off).
        thumbColor: const WidgetStatePropertyAll(GumdropColors.switchKnob),
        thumbIcon: const WidgetStatePropertyAll(Icon(null)),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? g.mint.face : g.switchOffTrack,
        ),
        trackOutlineColor: WidgetStatePropertyAll(g.ink),
        trackOutlineWidth: const WidgetStatePropertyAll(3),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? g.you.face : null,
        ),
        checkColor: WidgetStatePropertyAll(g.ink),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BorderSide(color: g.you.face, width: 2)
              : BorderSide(color: muted, width: 2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? g.you.face : muted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: g.you.face,
        linearTrackColor: g.well,
        circularTrackColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: g.you.face,
        inactiveTrackColor: g.well,
        thumbColor: g.you.face,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        selectedColor: primary,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: g.cherry.face,
        textColor: g.ink,
        textStyle: label.copyWith(fontSize: 11),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: low,
        modalBackgroundColor: low,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: g.divider,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Corners.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: high,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
        shape: style.cardShape(Corners.panel, side: cardSide),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: container,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.tile),
          side: cardSide,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onInverseSurface,
          fontSize: 15,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.tile),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: onInverseSurface),
      ),
      dividerTheme: DividerThemeData(color: g.divider, space: 2, thickness: 2),
    );
  }

  /// Nunito for text, Fredoka for labels, buttons, and names, and Lilita One
  /// headings with a stacked hard shadow (design §2, §3.3): 4 steps on the
  /// team name and screen titles, 3 on section headings. Gumdrop Arena sets
  /// headings and labels in its condensed italic, over a single shadow.
  static TextTheme _textTheme(GumdropColors g, GumdropStyle style, Color text) {
    TextStyle heading(double size, double height, int steps) => TextStyle(
      fontFamily: style.displayFont,
      fontWeight: style.fontWeight ?? FontWeight.w400,
      fontStyle: style.fontStyle,
      fontSize: size,
      height: height,
      letterSpacing: 0,
      color: g.headingText,
      shadows: style.headingShadow(g.headingShadow, steps),
    );
    TextStyle fredoka(double size, {double height = 1.2}) => TextStyle(
      fontFamily: style.labelFont,
      fontWeight: style.fontWeight ?? FontWeight.w600,
      fontStyle: style.fontStyle,
      fontSize: size,
      height: height,
      letterSpacing: 0,
      color: text,
    );
    TextStyle nunito(double size, {double height = 1.35}) => TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: height,
      letterSpacing: 0,
      color: text,
    );
    return TextTheme(
      displayLarge: heading(57, 1, 4),
      displayMedium: heading(45, 1, 4),
      displaySmall: heading(TypeScale.teamName, 1, 4),
      headlineLarge: heading(TypeScale.teamName, 1, 4),
      headlineMedium: heading(TypeScale.headline, 1.1, 4),
      headlineSmall: heading(TypeScale.section, 1.1, 3),
      titleLarge: heading(TypeScale.title, 1.1, 3),
      titleMedium: fredoka(TypeScale.subtitle),
      titleSmall: fredoka(15),
      bodyLarge: nunito(TypeScale.body),
      bodyMedium: nunito(TypeScale.secondary),
      bodySmall: nunito(13),
      labelLarge: fredoka(15, height: 1),
      labelMedium: fredoka(TypeScale.secondary, height: 1),
      labelSmall: fredoka(TypeScale.label, height: 1),
    );
  }

  /// Chips are 34 px gumdrops (design §3.6, §3.7): the secondary face, or
  /// the "you" color when selected.
  static ChipThemeData _chipTheme(
    GumdropColors g,
    GumdropStyle style,
    TextStyle label,
  ) {
    bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);
    return ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? g.well
            : selected(s)
            ? g.you.face
            : g.raisedFace,
      ),
      shape: WidgetStateOutlinedBorder.resolveWith(
        (s) => style.styled(
          GumdropShape(
            lip: 3,
            lipColor: s.contains(WidgetState.disabled)
                ? Colors.transparent
                : selected(s)
                ? g.you.lip
                : g.raisedLip,
            highlight: selected(s) ? 2 : 1.5,
            highlightColor: selected(s)
                ? GumdropColors.accentHighlight
                : g.raisedHighlight,
          ),
        ),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (s) => selected(s) || g.raisedBorderWidth == 0
            ? BorderSide.none
            : BorderSide(color: g.raisedBorder, width: g.raisedBorderWidth),
      ),
      labelStyle: label.copyWith(
        color: WidgetStateColor.resolveWith(
          (s) => selected(s) ? g.ink : g.textPrimary,
        ),
      ),
      secondaryLabelStyle: label.copyWith(color: g.ink),
      checkmarkColor: g.ink,
      iconTheme: IconThemeData(color: g.textPrimary, size: 18),
      deleteIconColor: g.textMuted,
      // The lip sits inside the chip's box, so the label rides 3 px high.
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 7),
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
    );
  }
}
