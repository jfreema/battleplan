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
  Widget build(BuildContext context) {
    final ring =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        border: ring
            ? Border.all(color: GumdropColors.of(context).textOnPage, width: 3)
            : null,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.radius,
        focusColor: Colors.transparent,
        onFocusChange: (f) => setState(() => _focused = f),
        child: widget.child,
      ),
    );
  }
}
