import 'package:battleplan/core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A screen that opens full screen on phones and as a dialog over the
/// current screen on wide screens (SPEC §5.5: event details, member cards,
/// and settings open "as side panels or dialogs instead of full screens").
/// The screen keeps its own app bar; on wide screens its back button is a
/// close button, and a tap outside or Esc closes it too. Opened from a
/// link with nothing under it, it fills the screen.
class PanelPage<T> extends Page<T> {
  const new({required this.child, super.key, super.name, super.arguments});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    if (!wide) {
      return MaterialPageRoute<T>(settings: this, builder: (_) => child);
    }
    return _PanelRoute<T>(
      page: this,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
      transitionDuration: Motion.of(context, Motion.normal),
    );
  }
}

/// The panel's largest size: about the width of the readable column.
const panelMaxWidth = 720.0;

class _PanelRoute<T> extends PageRoute<T> {
  new({
    required PanelPage<T> page,
    required this.barrierLabel,
    required this.barrierColor,
    required this.transitionDuration,
  }) : super(settings: page, fullscreenDialog: true);

  @override
  final Duration transitionDuration;

  PanelPage<T> get _page => settings as PanelPage<T>;

  @override
  final String barrierLabel;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Opened straight from a link, with nothing under it: full screen.
    if (isFirst) return _page.child;
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: panelMaxWidth,
              maxHeight: size.height * 0.9,
            ),
            child: Material(
              elevation: 6,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(Corners.card + Space.xs),
              child: _page.child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
