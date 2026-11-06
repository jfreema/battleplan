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
/// is in use (no ring after a tap). It follows the highlight mode, so a
/// ring left on a control goes away as soon as the person touches the
/// screen.
class FocusRing extends StatefulWidget {
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
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    super.dispose();
  }

  void _modeChanged(FocusHighlightMode _) {
    if (widget.focused) setState(() {});
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: widget.focused && FocusRing.showing
        ? FocusRing.decoration(context, widget.radius)
        : const BoxDecoration(),
    child: widget.child,
  );
}

/// The focus ring around the face of a button that this sits inside (an
/// RSVP pill in a [SegmentedButton] segment), while that button, the
/// nearest [Focus] above, has the keyboard focus.
class ButtonFocusRing extends StatelessWidget {
  const new({required this.radius, required this.child, super.key});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusRing(
    // Rebuilds as that focus changes.
    focused: Focus.maybeOf(context)?.hasPrimaryFocus ?? false,
    radius: radius,
    child: child,
  );
}
