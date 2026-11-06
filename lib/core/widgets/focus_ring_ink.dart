import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// An [InkWell] that shows the keyboard focus as a 3 px ring in the text
/// color (SPEC §7.6), for rows, cards and tabs that draw no focus of their
/// own.
class FocusRingInk extends StatefulWidget {
  const new({
    required this.onTap,
    required this.child,
    this.radius = BorderRadius.zero,
    super.key,
  });

  final VoidCallback? onTap;
  final BorderRadius radius;
  final Widget child;

  @override
  State<FocusRingInk> createState() => _FocusRingInkState();
}

class _FocusRingInkState extends State<FocusRingInk> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => FocusRing(
    focused: _focused,
    radius: widget.radius,
    child: InkWell(
      onTap: widget.onTap,
      borderRadius: widget.radius,
      focusColor: Colors.transparent,
      onFocusChange: (f) => setState(() => _focused = f),
      child: widget.child,
    ),
  );
}

/// The 3 px focus ring in the text color (SPEC §7.6), drawn over the edge
/// of [child] in the shape [radius] gives, while [focused] and the keyboard
/// is in use (no ring after a tap).
class FocusRing extends StatelessWidget {
  const new({
    required this.focused,
    required this.child,
    this.radius = BorderRadius.zero,
    super.key,
  });

  final bool focused;
  final BorderRadius radius;
  final Widget child;

  /// Whether a focused control shows its ring now: only while the keyboard
  /// is in use.
  static bool get showing =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  /// The ring, as a foreground decoration in the shape [radius] gives.
  static Decoration decoration(BuildContext context, BorderRadius radius) =>
      BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: GumdropColors.of(context).textOnPage,
          width: 3,
        ),
      );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: focused && showing
        ? decoration(context, radius)
        : const BoxDecoration(),
    child: child,
  );
}

/// The focus ring as a foreground decoration for the face of a button that
/// [context] sits inside (an RSVP pill in a [SegmentedButton] segment), or
/// null while that button, the nearest [Focus] above, doesn't have the
/// keyboard focus. [context] rebuilds as that focus changes.
Decoration? buttonFocusRing(BuildContext context, BorderRadius radius) {
  final focused = Focus.maybeOf(context)?.hasPrimaryFocus ?? false;
  return focused && FocusRing.showing
      ? FocusRing.decoration(context, radius)
      : null;
}
