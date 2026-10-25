import 'package:battleplan/core/design/fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Design tokens from SPEC §7.3. Screens use these, never raw numbers.
abstract final class AppTokens {
  /// Brand blue (SPEC §7.1, Q9): the brand mark, and a team with no color.
  static const Color brand = Color(0xFF2F5BEA);
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

/// Chat messages' text (CHAT-1): Nunito on every platform, as Gumdrop Pop
/// sets it: 16 px on a 1.35 line, bold in others' bubbles and extra bold in
/// mine.
abstract final class ChatText {
  static const double size = 16;
  static const double height = 1.35;

  /// [base] as message text: the face, size, line height, and weight.
  /// [mine] for my own bubbles.
  static TextStyle of(TextStyle? base, {bool mine = false}) =>
      face(base).copyWith(
        fontSize: size,
        height: height,
        fontWeight: mine ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: 0,
      );

  /// [base] in the message face only, for the name and time beside it.
  static TextStyle face(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(fontFamily: AppFonts.body);
}

/// Corner radii (Gumdrop Pop design §3).
abstract final class Corners {
  static const double chip = 8;

  /// Text fields and selects.
  static const double input = 14;

  /// Small cards: attendee rows, stat tiles, picker tiles.
  static const double tile = 18;

  /// Cards and settings sections.
  static const double card = 20;

  /// Chat bubbles; the tail corner is [bubbleTail].
  static const double bubble = 20;
  static const double bubbleTail = 6;

  /// Large cards: the poll card, dialogs.
  static const double panel = 22;

  /// Sheets, the tab bar, the game card.
  static const double sheet = 26;
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

/// Type scale (Gumdrop Pop design §2): the headings are Lilita One, which
/// the theme's headline and title styles carry.
abstract final class TypeScale {
  /// The team's name on its tab screens.
  static const double teamName = 36;

  /// A screen's title.
  static const double headline = 32;

  /// A section heading.
  static const double section = 24;
  static const double title = 22;
  static const double subtitle = 17;
  static const double body = 16;
  static const double secondary = 14;
  static const double label = 12;
}
