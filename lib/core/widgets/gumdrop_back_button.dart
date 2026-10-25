import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The round lemon back button (Gumdrop Pop design §3.2): a 48 px lemon
/// disc with a 2.5 px ink outline, a hard offset shadow, and an ink
/// chevron. It's the app's back button: the theme draws every AppBar's
/// automatic back button with it ([GumdropBackButton.iconBuilder]), and
/// custom headers use [GumdropBackButton] itself.
class GumdropBackButton extends StatelessWidget {
  const new({this.onPressed, super.key});

  /// What a tap does; pops the route when null, as [BackButton] does.
  final VoidCallback? onPressed;

  /// The disc's size (design §3.2).
  static const double size = 48;

  /// For [ActionIconThemeData.backButtonIconBuilder]: the disc in place of
  /// the arrow inside Material's [BackButton], which keeps its tooltip,
  /// its tap, and its semantics. The disc is drawn over the icon button's
  /// own 40 px face, so it shows the keyboard focus itself.
  static Widget iconBuilder(BuildContext context) => const SizedBox.square(
    dimension: 24,
    child: OverflowBox(
      maxWidth: size + 8,
      maxHeight: size + 8,
      child: _FocusAwareDisc(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.backButtonTooltip,
      excludeSemantics: true,
      onTap: () => _press(context),
      child: Tooltip(
        message: l10n.backButtonTooltip,
        child: InkResponse(
          onTap: () => _press(context),
          radius: size / 2,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: const Padding(
            // The shadow sits outside the disc, to its right and below.
            padding: EdgeInsets.only(right: 4, bottom: 4),
            child: _FocusAwareDisc(),
          ),
        ),
      ),
    );
  }

  void _press(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else {
      Navigator.maybePop(context);
    }
  }
}

/// [GumdropBackDisc] with a ring when its button has the keyboard focus.
class _FocusAwareDisc extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final focused =
        (Focus.maybeOf(context)?.hasFocus ?? false) &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return GumdropBackDisc(focused: focused);
  }
}

/// The back button's look alone, with no tap: the lemon disc and chevron.
class GumdropBackDisc extends StatelessWidget {
  const new({this.focused = false, super.key});

  /// Draws the keyboard focus ring around the disc.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      width: GumdropBackButton.size,
      height: GumdropBackButton.size,
      decoration: BoxDecoration(
        color: c.lemon.face,
        shape: BoxShape.circle,
        border: Border.all(color: c.ink, width: 2.5),
        boxShadow: [
          BoxShadow(color: c.pageShadow, offset: const Offset(4, 4)),
          if (focused) BoxShadow(color: c.textOnPage, spreadRadius: 3),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(AppIcons.chevronLeft, size: 34, weight: 700, color: c.ink),
    );
  }
}
