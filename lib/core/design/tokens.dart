import 'package:material_ui/material_ui.dart';

/// Design tokens from SPEC §7.3. Screens use these, never raw numbers.
abstract final class AppTokens {
  /// Brand blue (SPEC §7.1, Q9).
  static const Color brand = Color(0xFF2F5BEA);

  static const String fontFamily = 'Inter';
}

/// 4-point spacing grid.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Side padding on phones and on wide screens.
  static double gutter(double width) => width >= Breakpoints.wide ? xl : lg;
}

abstract final class Corners {
  static const double chip = 8;
  static const double card = 12;
  static const double bubble = 18;
  static const double pill = 999;
}

abstract final class Breakpoints {
  /// At and above this width the tabs move to a left rail (SPEC §5.5, D9).
  static const double wide = 840;

  /// Readable width for chat and other centered content.
  static const double contentMax = 840;
}

/// Quick, subtle motion: 150 to 250 ms with standard easing, and none at
/// all when the system asks to reduce motion (SPEC §7.3).
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);

  /// Material 3's standard easing.
  static const Curve curve = Easing.standard;

  /// Whether the system asks to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when the system asks to reduce motion (SPEC §7.3).
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Type scale: 28 / 22 / 18 / 16 / 14 / 12.
abstract final class TypeScale {
  static const double headline = 28;
  static const double title = 22;
  static const double subtitle = 18;
  static const double body = 16;
  static const double secondary = 14;
  static const double label = 12;
}
