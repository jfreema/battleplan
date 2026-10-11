import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the light and dark themes from the tokens (SPEC §7.3, §7.4).
abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppTokens.brand,
      // Fidelity keeps the brand blue itself as the primary color.
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ),
    AppColors.light,
  );

  /// Near-black tonal surfaces, not pure black (SPEC §7.4).
  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppTokens.brand,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF121317),
      surfaceContainerLowest: const Color(0xFF0D0E11),
      surfaceContainerLow: const Color(0xFF17181D),
      surfaceContainer: const Color(0xFF1B1D22),
      surfaceContainerHigh: const Color(0xFF22242A),
      surfaceContainerHighest: const Color(0xFF2A2C33),
    ),
    AppColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, AppColors appColors) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final text = base.textTheme;
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Corners.card),
    );

    return base.copyWith(
      extensions: [appColors],
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: TypeScale.headline,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: TypeScale.title,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: TypeScale.subtitle,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: TypeScale.body),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: TypeScale.secondary),
        labelSmall: text.labelSmall?.copyWith(fontSize: TypeScale.label),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.card),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.chip),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Corners.card * 2),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.card * 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
