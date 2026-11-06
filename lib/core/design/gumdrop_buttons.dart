import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// Button styles in the gumdrop recipe (design §3.1), for any Material
/// button's `style:`. The theme already gives FilledButton the accent style
/// in the "you" color, and OutlinedButton, TextButton, and ElevatedButton the
/// secondary style; use these for another accent (a cherry Delete, a mint
/// Going), another size, or a gumdrop icon button:
///
/// ```dart
/// final buttons = GumdropButtons.of(context);
/// FilledButton(style: buttons.accent(colors.cherry), ...);
/// IconButton(style: buttons.icon(size: 38), ...);
/// ```
///
/// Pressed, the face sinks onto its lip; disabled, it sits flat in the
/// well's color.
@immutable
class GumdropButtons {
  const new(
    this.colors, {
    required this.focusRing,
    this.style = GumdropStyle.openField,
  });

  /// For the colors and style at [context].
  factory of(BuildContext context) {
    final colors = GumdropColors.of(context);
    return GumdropButtons(
      colors,
      focusRing: colors.textOnPage,
      style: GumdropStyle.of(context),
    );
  }

  final GumdropColors colors;

  /// The theme's style: the candy outline's width.
  final GumdropStyle style;

  /// The keyboard focus ring's color: the text color, which shows on every
  /// face.
  final Color focusRing;

  /// A candy-colored gumdrop: [accent]'s face, a 2 px outline and lip in
  /// its lip color, and ink text. [height] includes the lip, which is 3 px
  /// up to a 38 px face and 4 above.
  ButtonStyle accent(
    GumdropAccent accent, {
    double height = 48,
    double? width,
    BorderRadius? radius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18),
    TextStyle? textStyle,
    Size? minimumSize,
  }) => _style(
    face: accent.face,
    lip: accent.lip,
    foreground: colors.ink,
    highlight: 2,
    highlightColor: GumdropColors.accentHighlight,
    side: style.accentSide(accent.lip),
    height: height,
    width: width,
    radius: radius,
    padding: padding,
    textStyle: textStyle,
    minimumSize: minimumSize,
  );

  /// The secondary button: an outlined pill with no face or lip, in the
  /// text color.
  ButtonStyle secondary({
    double height = 48,
    double? width,
    BorderRadius? radius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18),
    TextStyle? textStyle,
    Size? minimumSize,
  }) => _style(
    face: colors.raisedFace,
    lip: colors.raisedLip,
    foreground: colors.textPrimary,
    highlight: 1.5,
    highlightColor: colors.raisedHighlight,
    side: colors.raisedBorderWidth == 0
        ? BorderSide.none
        : BorderSide(
            color: colors.raisedBorder,
            width: colors.raisedBorderWidth,
          ),
    height: height,
    width: width,
    radius: radius,
    padding: padding,
    textStyle: textStyle,
    minimumSize: minimumSize,
  );

  /// A quiet text link for small actions (Terms of Use, Load more, Use a
  /// different account, Turn off link): underlined text in the text color,
  /// with no face or lip, so it reads as less important than the gumdrops
  /// beside it. Its tap target stays 48 by 44.
  ButtonStyle link({TextStyle? textStyle}) {
    final foreground = colors.onCard ? colors.textPrimary : colors.textOnPage;
    final muted = colors.onCard ? colors.textMuted : colors.textMutedOnPage;
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? muted : foreground,
      ),
      iconColor: WidgetStatePropertyAll(foreground),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.pressed) || s.contains(WidgetState.focused)
            ? foreground.withValues(alpha: 0.10)
            : s.contains(WidgetState.hovered)
            ? foreground.withValues(alpha: 0.06)
            : null,
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? BorderSide(color: focusRing, width: 3)
            : BorderSide.none,
      ),
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        (textStyle ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
          decorationColor: foreground,
        ),
      ),
    );
  }

  /// A round gumdrop icon button [size] px across (38 in headers, 46 in
  /// the composer), secondary, or in [accent]. Its tap target stays 48.
  ButtonStyle icon({double size = 38, GumdropAccent? accent}) {
    final lip = GumdropShape.lipFor(size);
    final box = Size(size, size + lip);
    final style = accent == null
        ? secondary(height: box.height, width: size, padding: EdgeInsets.zero)
        : this.accent(
            accent,
            height: box.height,
            width: size,
            padding: EdgeInsets.zero,
          );
    return style.copyWith(
      fixedSize: WidgetStatePropertyAll(box),
      minimumSize: WidgetStatePropertyAll(box),
      iconSize: WidgetStatePropertyAll(size <= 38 ? 19 : 22),
    );
  }

  ButtonStyle _style({
    required Color face,
    required Color lip,
    required Color foreground,
    required double highlight,
    required Color highlightColor,
    required BorderSide side,
    required double height,
    required EdgeInsetsGeometry padding,
    double? width,
    BorderRadius? radius,
    TextStyle? textStyle,
    Size? minimumSize,
  }) {
    final lipHeight = GumdropShape.lipFor(height - 4);
    bool down(Set<WidgetState> s) =>
        s.contains(WidgetState.pressed) || s.contains(WidgetState.disabled);
    final disabledFace = colors.well;
    final disabledForeground = colors.textMuted;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? disabledFace : face,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.disabled) ? disabledForeground : foreground,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.disabled) ? disabledForeground : foreground,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed)
            ? foreground.withValues(alpha: 0.10)
            : s.contains(WidgetState.hovered)
            ? foreground.withValues(alpha: 0.06)
            : s.contains(WidgetState.focused)
            ? foreground.withValues(alpha: 0.10)
            : null,
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStateProperty.resolveWith(
        (s) => GumdropShape(
          lip: lipHeight,
          lipColor: lip,
          highlight: s.contains(WidgetState.disabled) ? 0 : highlight,
          highlightColor: highlightColor,
          radius: radius,
          pressed: down(s) ? 1 : 0,
        ),
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? BorderSide(color: focusRing, width: 3)
            : s.contains(WidgetState.disabled)
            ? BorderSide.none
            : side,
      ),
      // The label rides on the face: up by the lip at rest, down with it
      // when pressed.
      padding: WidgetStateProperty.resolveWith(
        (s) => padding.add(
          EdgeInsets.only(
            top: down(s) ? lipHeight : 0,
            bottom: down(s) ? 0 : lipHeight,
          ),
        ),
      ),
      minimumSize: WidgetStatePropertyAll(
        minimumSize ?? Size(width ?? 48, height),
      ),
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
      animationDuration: const Duration(milliseconds: 80),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
