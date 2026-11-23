import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The Open Field theme (SPEC §7.3, §7.4, SET-2) in each of its five color
/// schemes. Every Material widget is themed to match; screens read the full
/// palette with [GumdropColors.of], and the fonts and shapes with
/// [GumdropStyle.of].
abstract final class AppTheme {
  static final _cache = <(TeamScheme, bool, bool), ThemeData>{};

  /// The theme for [scheme], on the page or ([onCard]) on a card, built once
  /// and kept: two per scheme. [shipped] is a built-in [scheme] as the app
  /// ships it, without the theme editor's colors (#83): the Super Admin
  /// Panel's.
  static ThemeData of(
    TeamScheme scheme, {
    bool onCard = false,
    bool shipped = false,
  }) {
    // Built again once the theme editor's colors change (#82).
    if (_version != ThemeCatalog.version) {
      _cache.clear();
      _version = ThemeCatalog.version;
    }
    return _cache.putIfAbsent(
      (scheme, onCard, shipped),
      () => build(
        GumdropColors.forScheme(scheme, onCard: onCard, shipped: shipped),
      ),
    );
  }

  static int _version = 0;

  /// How many themes have been built (for a test).
  @visibleForTesting
  static int get cachedThemes => _cache.length;

  static ThemeData build(GumdropColors g) {
    const style = GumdropStyle.openField;
    final background = g.background;
    final text = g.textOnPage;
    final muted = g.textMutedOnPage;
    // From the page out: lowest (the well), low (cards, sheets), container
    // (menus), high (dialogs, pickers), and highest (chips). Menus and
    // pickers are Material's own, with rows in this context's text color,
    // so they take the pop-up color: the card's, but from Candy Pop's page
    // the deeper blue, since its cards are white (#72). Our cards, sheets,
    // dialogs and panels put their content in the card context.
    final [lowest, low, container, high, highest] = [
      g.inputFill,
      g.surface,
      g.popup,
      g.popup,
      g.inputFill,
    ];
    // Text in a role's color must read on what this context's text is on:
    // the page and its pop-ups, or the card.
    final textBackgrounds = [background, container];
    // Writing on the "you" face: the ink, or white on a theme's own dark
    // "you" (#83).
    final youInk = g.inkOn(g.you);
    Color readable(Color c) => ColorMath.readable(c, textBackgrounds);
    // White or ink on a role's color; black where neither reads.
    Color on(Color c) {
      final o = ColorMath.onColor(c, dark: g.ink);
      return ColorMath.contrast(o, c) >= 4.5
          ? o
          : ColorMath.onColor(c, dark: const Color(0xFF000000));
    }

    // Where "you" is red (coral, in every scheme) like the warning red,
    // Material's primary is the blue raspberry, so selection, focus, and
    // "normal" never look like an error. Your bubbles, the FAB, and
    // buttons keep the "you" color.
    final youIsRed =
        ColorMath.hueDistance(
          ColorMath.lch(g.you.face).h,
          ColorMath.lch(g.cherry.face).h,
        ) <
        30;
    final primary = readable(youIsRed ? g.blueRaspberry.face : g.you.face);
    final secondary = readable(g.bubblegum.face);
    final tertiary = readable(g.grape.face);
    final error = readable(g.cherry.text);
    // Snack bars and tooltips: the text color as the fill, what it's on
    // (the page, or the card) as the label (7.5:1 or better in every
    // scheme; Candy Pop's card text is navy on its white cards, #72).
    final inverseSurface = g.textOnPage;
    final onInverseSurface = background;
    final scheme = ColorScheme(
      brightness: g.brightness,
      primary: primary,
      onPrimary: on(primary),
      primaryContainer: g.you.face,
      onPrimaryContainer: youInk,
      secondary: secondary,
      onSecondary: on(secondary),
      secondaryContainer: g.inputFill,
      onSecondaryContainer: g.textPrimary,
      tertiary: tertiary,
      onTertiary: on(tertiary),
      tertiaryContainer: g.grape.face,
      onTertiaryContainer: g.inkOn(g.grape),
      error: error,
      onError: on(error),
      errorContainer: g.cherry.face,
      onErrorContainer: g.inkOn(g.cherry),
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
      outline: g.outline,
      outlineVariant: g.divider,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: onInverseSurface,
      surfaceTint: const Color(0x00000000),
    );
    final appColors = AppColors.fromGumdrop(g, backgrounds: textBackgrounds);
    final textTheme = _textTheme(g, style, text);
    final buttons = GumdropButtons(g, focusRing: text);
    final inputFill = g.inputFill;
    final inputBorder = g.inputBorder;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Corners.input),
      borderSide: BorderSide(color: color, width: width),
    );
    final cardSide = BorderSide(
      color: g.surfaceBorder,
      width: g.surfaceBorderWidth,
    );
    final label = textTheme.labelLarge!;

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
      focusColor: g.accentMark.withValues(alpha: 0.24),
      dividerColor: g.divider,
      textTheme: base.textTheme.merge(textTheme),
      iconTheme: IconThemeData(color: text),
      // Every automatic back button is the 28 px chevron (SPEC §7.3).
      actionIconTheme: const ActionIconThemeData(
        backButtonIconBuilder: BackChevron.iconBuilder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Pushed screens' plain app bars: the 28 px chevron in a 48 px tap
        // area by the edge, as on the pushed-screen bar, and the title in
        // stencil 25 outlined just after it.
        leadingWidth: 52,
        titleSpacing: 8,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 25),
        iconTheme: IconThemeData(color: text),
        actionsIconTheme: IconThemeData(color: text),
        // The status bar sits on the camouflage (#85), so its icons go by
        // the camouflage's ground: light on Sky Blue's blue one over a
        // light page (#86).
        systemOverlayStyle:
            ThemeData.estimateBrightnessForColor(g.roles.palette.camoGround) ==
                Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: low,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: style.cardShape(18, side: cardSide),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        // Boot Camp Mix (#85): fields outlined in ink, like panels.
        border: outline(inputBorder, 2.5),
        enabledBorder: outline(inputBorder, 2.5),
        disabledBorder: outline(inputBorder.withValues(alpha: 0.5), 2.5),
        focusedBorder: outline(text, 3),
        errorBorder: outline(g.cherry.text, 2.5),
        focusedErrorBorder: outline(g.cherry.text, 3),
        hintStyle: textTheme.bodyLarge?.copyWith(color: muted),
        labelStyle: textTheme.bodyLarge?.copyWith(color: muted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        helperStyle: textTheme.bodySmall?.copyWith(color: muted),
        errorStyle: textTheme.bodySmall?.copyWith(color: g.cherry.text),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: Space.md,
        ),
      ),
      chipTheme: _chipTheme(g, style, label),
      filledButtonTheme: FilledButtonThemeData(
        // The coral gumdrop: stencil 700 16 in ink.
        style: buttons.accent(
          g.you,
          textStyle: label.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      // The outlined pill: stencil 600 16.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttons.secondary(textStyle: label.copyWith(fontSize: 16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttons.secondary(textStyle: label.copyWith(fontSize: 16)),
      ),
      // Text buttons are plain text: stencil 600 15 in the text color.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? muted : text,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? muted : text,
          ),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.pressed) ||
                    s.contains(WidgetState.focused)
                ? text.withValues(alpha: 0.10)
                : s.contains(WidgetState.hovered)
                ? text.withValues(alpha: 0.06)
                : null,
          ),
          textStyle: WidgetStatePropertyAll(
            label.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.md),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? BorderSide(color: text, width: 3)
                : BorderSide.none,
          ),
          elevation: const WidgetStatePropertyAll(0),
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
        foregroundColor: youInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        iconSize: 28,
        shape: GumdropShape(lipColor: g.you.lip, side: style.accentSide(g.ink)),
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 60),
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
      // Boot Camp Mix (#85): the picked choice on a mustard tile in ink.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.accentMark : g.well,
          ),
          // Unpicked: the muted text of where the well is, the page's or
          // the card's.
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.ink : muted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? g.ink : muted,
          ),
          textStyle: WidgetStatePropertyAll(label.copyWith(fontSize: 16)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
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
      // The Open Field tab bar: a flat bar with a rule on top, no
      // indicator, the picked tab's icon coral.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: g.tabBar,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? g.you.face : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => label.copyWith(
            fontSize: 13,
            color: s.contains(WidgetState.selected) ? text : muted,
          ),
        ),
      ),
      // Boot Camp Mix (#85): the current section on a mustard tile.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: g.tabBar,
        indicatorColor: g.accentMark,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: g.ink, width: 2.5),
        ),
        selectedIconTheme: IconThemeData(color: g.ink, size: 24),
        unselectedIconTheme: IconThemeData(color: muted, size: 24),
        selectedLabelTextStyle: label.copyWith(fontSize: 13, color: text),
        unselectedLabelTextStyle: label.copyWith(fontSize: 13, color: muted),
        labelType: NavigationRailLabelType.all,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: muted,
        labelStyle: label.copyWith(fontSize: 16),
        unselectedLabelStyle: label.copyWith(fontSize: 16),
        indicatorColor: g.accentMark,
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        // On: the mint face with a white knob. Off: the field with a 2 px
        // outline and a muted knob.
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? GumdropColors.switchKnob
              : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? g.mint.face : g.switchOffTrack,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? g.mint.lip : g.outline,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(2),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? g.you.face : null,
        ),
        checkColor: WidgetStatePropertyAll(youInk),
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
        color: g.accentMark,
        linearTrackColor: g.well,
        circularTrackColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: g.you.face,
        inactiveTrackColor: g.well,
        thumbColor: g.you.face,
      ),
      // No textColor: ListTile puts it on the subtitle too, over the muted
      // color below.
      listTileTheme: ListTileThemeData(
        iconColor: text,
        selectedColor: primary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          color: text,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: text,
        selectionColor: g.accentMark.withValues(alpha: 0.3),
        selectionHandleColor: g.accentMark,
      ),
      // Unread counts are coral, "you" (SPEC §7.2), not the warning red.
      // Unread is red in Boot Camp Mix (#85), as unreadBadge draws it.
      badgeTheme: BadgeThemeData(
        backgroundColor: g.cherry.face,
        textColor: g.inkOn(g.cherry),
        // Nothing under 12 px (SPEC §7.3).
        textStyle: label.copyWith(fontSize: 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: low,
        modalBackgroundColor: low,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: g.textMuted,
        dragHandleSize: const Size(36, 4),
        // Square, like every Boot Camp Mix panel (#85).
        shape: Border(top: cardSide),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: high,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 25),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: style.cardShape(22, side: cardSide),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: container,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyLarge?.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(side: cardSide),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onInverseSurface,
          fontSize: 15,
        ),
        actionTextColor: onInverseSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: g.ink, width: 2.5),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: inverseSurface,
          border: Border.all(color: g.ink, width: 2),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: onInverseSurface),
      ),
      dividerTheme: DividerThemeData(color: g.divider, space: 1, thickness: 1),
    );
  }

  /// Boot Camp Mix (#85): Nunito SemiBold for reading text (#97), and the
  /// stencil, always in capitals and a little spaced, for headings, labels,
  /// buttons, and names.
  static TextTheme _textTheme(GumdropColors g, GumdropStyle style, Color text) {
    TextStyle heading(double size, double height) => TextStyle(
      fontFamily: style.displayFont,
      fontWeight: FontWeight.w900,
      fontSize: size,
      height: height,
      letterSpacing: size * 0.04,
      color: g.headingText,
      shadows: style.headingShadow(g.headingShadow, big: size > 32),
    );
    TextStyle fredoka(double size, {double height = 1.2}) => TextStyle(
      fontFamily: style.labelFont,
      fontWeight: FontWeight.w900,
      fontSize: size,
      height: height,
      letterSpacing: GumdropStyle.stencilSpacing(size),
      color: text,
    );
    TextStyle reading(double size, {double height = 1.35}) => TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: AppFonts.reading,
      fontSize: size,
      height: height,
      letterSpacing: 0,
      color: text,
    );
    return TextTheme(
      displayLarge: heading(57, 1),
      displayMedium: heading(45, 1),
      displaySmall: heading(TypeScale.teamName, 1),
      headlineLarge: heading(TypeScale.teamName, 1),
      headlineMedium: heading(TypeScale.headline, 1.1),
      headlineSmall: heading(TypeScale.section, 1.1),
      titleLarge: heading(TypeScale.title, 1.1),
      titleMedium: fredoka(TypeScale.subtitle),
      titleSmall: fredoka(15),
      bodyLarge: reading(TypeScale.body),
      bodyMedium: reading(TypeScale.secondary),
      bodySmall: reading(14),
      labelLarge: fredoka(15, height: 1),
      labelMedium: fredoka(TypeScale.secondary, height: 1),
      labelSmall: fredoka(TypeScale.label, height: 1),
    );
  }

  /// Chips: coral with a 2 px lip-colored outline when selected, a 1.5 px
  /// outline otherwise.
  static ChipThemeData _chipTheme(
    GumdropColors g,
    GumdropStyle style,
    TextStyle label,
  ) {
    bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);
    final youInk = g.inkOn(g.you);
    return ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? g.well
            : selected(s)
            ? g.you.face
            : Colors.transparent,
      ),
      shape: const StadiumBorder(),
      side: WidgetStateBorderSide.resolveWith(
        (s) => selected(s)
            ? BorderSide(color: g.you.lip, width: 2)
            : BorderSide(color: g.outline, width: 1.5),
      ),
      labelStyle: label.copyWith(
        fontSize: 14,
        color: WidgetStateColor.resolveWith(
          (s) => selected(s) ? youInk : g.textPrimary,
        ),
      ),
      secondaryLabelStyle: label.copyWith(color: youInk),
      checkmarkColor: youInk,
      iconTheme: IconThemeData(color: g.textPrimary, size: 18),
      deleteIconColor: g.textMutedOnPage,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
    );
  }
}
