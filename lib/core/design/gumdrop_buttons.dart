import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// Button styles in the gumdrop recipe (design §3.1), for any Material
/// button's `style:`. Since the candy finish (#98, SPEC §7.4) they're
/// glossy gumdrops: a 3 px ink outline, corners of 17 (14 on small ones),
/// on a lip of a darker shade of the face 7 px deep with the ink carried
/// round under it, a white highlight along the top and a shine streak at
/// the top left; round icon buttons are glossy balls in a 2.5 px outline on
/// a 4 px lip. The theme already gives FilledButton the accent style in
/// the "you" color, and OutlinedButton, TextButton, and ElevatedButton the
/// secondary style (a licorice gumdrop in the panel color); use these for
/// another accent (a cherry Delete, a mint Going), another size, or a
/// gumdrop icon button:
///
/// ```dart
/// final buttons = GumdropButtons.of(context);
/// FilledButton(style: buttons.accent(colors.cherry), ...);
/// IconButton(style: buttons.icon(size: 38), ...);
/// ```
///
/// Pressed, the face sinks 3 px onto its lip; disabled, it sits down
/// flat in the well's color, with no lip.
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

  /// A candy-colored push button: [accent]'s face, a 3 px ink outline on
  /// its lip, and ink lettering. [height] includes the lip
  /// ([GumdropShape.depthFor]).
  ButtonStyle accent(
    GumdropAccent accent, {
    double height = 48,
    double? width,
    BorderRadius? radius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18),
    TextStyle? textStyle,
    Size? minimumSize,
    double? depth,
  }) => _style(
    face: accent.face,
    lip: accent.lip,
    foreground: colors.inkOn(accent),
    side: style.accentSide(colors.ink),
    height: height,
    width: width,
    radius: radius,
    padding: padding,
    textStyle: textStyle,
    minimumSize: minimumSize,
    depth: depth,
  );

  /// The secondary button: a licorice gumdrop, the panel color on a lip of
  /// a darker shade of it, outlined in ink, lettered in the panel's text
  /// color (#85, #98).
  ButtonStyle secondary({
    double height = 48,
    double? width,
    BorderRadius? radius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18),
    TextStyle? textStyle,
    Size? minimumSize,
    double? depth,
  }) => _style(
    face: colors.raisedFace,
    lip: colors.raisedLip,
    // The panel's lettering, on the panel color (Candy Pop's navy on
    // white, #86).
    foreground: colors.roles.cardText,
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
    depth: depth,
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
      // The theme's text button type (stencil 600 15) unless given: a
      // button's own text style replaces the theme's whole, so without it
      // the link fell back to the platform's font (#3).
      textStyle: WidgetStatePropertyAll(
        (textStyle ??
                style.label(
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ))
            .copyWith(
              decoration: TextDecoration.underline,
              decorationColor: foreground,
            ),
      ),
    );
  }

  /// A round icon button [size] px across (38 in headers, 46 in the
  /// composer), secondary, or in [accent]: a glossy ball in a 2.5 px ink
  /// outline on a 4 px lip, its shine a tilted oval (#98). Its tap target
  /// stays 48.
  ButtonStyle icon({double size = 38, GumdropAccent? accent}) {
    const lip = GumdropShape.roundDepth;
    final box = Size(size, size + lip);
    final style = accent == null
        ? secondary(
            height: box.height,
            width: size,
            padding: EdgeInsets.zero,
            depth: lip,
          )
        : this.accent(
            accent,
            height: box.height,
            width: size,
            padding: EdgeInsets.zero,
            depth: lip,
          );
    return style.copyWith(
      fixedSize: WidgetStatePropertyAll(box),
      minimumSize: WidgetStatePropertyAll(box),
      iconSize: WidgetStatePropertyAll(size <= 38 ? 19 : 22),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? BorderSide(color: focusRing, width: 3)
            : s.contains(WidgetState.disabled)
            ? BorderSide.none
            : BorderSide(color: colors.ink, width: 2.5),
      ),
    );
  }

  ButtonStyle _style({
    required Color face,
    required Color lip,
    required Color foreground,
    required BorderSide side,
    required double height,
    required EdgeInsetsGeometry padding,
    double? width,
    BorderRadius? radius,
    TextStyle? textStyle,
    Size? minimumSize,
    double? depth,
  }) {
    // The lip (#98): 7 under the usual 48 px button, 6 under small ones, 8
    // under big ones, 4 under round ones; pressed, the face sinks onto it.
    final lipHeight = depth ?? GumdropShape.depthFor(height);
    final sink = GumdropShape.sinkFor(lipHeight);
    final faceHeight = height - lipHeight;
    // Round ones (no radius, a square face) are balls; push buttons have
    // corners of 17, 14 on small ones (#98).
    final round = width != null && width <= faceHeight + 0.5;
    // Pills on Sugar Rush (#98).
    final corners =
        radius ??
        (round || style.pills
            ? null
            : BorderRadius.circular(faceHeight <= 38 ? 14 : 17));
    // The shine: a tilted oval near a ball's top left (9 x 5 at 6, 5 on a
    // 36 px ball), a streak on a push button, sized to it (16 x 4.5 at 10, 4
    // on a 41 px face).
    final shine = round
        ? Rect.fromLTWH(
            faceHeight * 0.17,
            faceHeight * 0.14,
            faceHeight * 0.25,
            faceHeight * 0.14,
          )
        : faceHeight < 34
        ? const Rect.fromLTWH(9, 3, 12, 3.5)
        : faceHeight < 39
        ? const Rect.fromLTWH(8, 3.5, 13, 4.5)
        : faceHeight < 46
        ? const Rect.fromLTWH(10, 4, 16, 4.5)
        : const Rect.fromLTWH(12, 5, 20, 5);
    bool pressed(Set<WidgetState> s) => s.contains(WidgetState.pressed);
    bool disabled(Set<WidgetState> s) => s.contains(WidgetState.disabled);
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
        (s) => disabled(s)
            // Sat down flat, with no lip, in the well's color.
            ? GumdropShape(
                lip: lipHeight,
                radius: corners,
                pressed: 1,
                sink: lipHeight,
              )
            : GumdropShape(
                lip: lipHeight,
                lipColor: lip,
                lipEdge: colors.ink,
                highlight: Candy.highlightHeight,
                highlightColor: Candy.highlightOn(face),
                shine: shine,
                shineColor: round
                    ? Candy.ballShineOn(face)
                    : Candy.streakOn(face),
                ball: round,
                radius: corners,
                pressed: pressed(s) ? 1 : 0,
                sink: sink,
              ),
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? BorderSide(color: focusRing, width: 3)
            : s.contains(WidgetState.disabled)
            ? BorderSide.none
            : side,
      ),
      // The label rides on the face: above the lip at rest, sunk with the
      // face when pressed, and down on it when disabled.
      padding: WidgetStateProperty.resolveWith((s) {
        final down = disabled(s)
            ? lipHeight
            : pressed(s)
            ? sink
            : 0.0;
        return padding.add(
          EdgeInsets.only(top: down, bottom: lipHeight - down),
        );
      }),
      minimumSize: WidgetStatePropertyAll(
        minimumSize ?? Size(width ?? 48, height),
      ),
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
      animationDuration: const Duration(milliseconds: 80),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
