import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:material_ui/material_ui.dart';

/// The Open Field back button (SPEC §7.3): a 28 px chevron in the text
/// color and, when given, the screen it goes back to ([label], "Team
/// info") in Fredoka 600 17, in one tap area at least 48 tall, with the
/// 3 px focus ring for the keyboard. It keeps Material's "Back" tooltip,
/// and is a "Back" button node of its own for screen readers.
class BackChevron extends StatelessWidget {
  const new({this.label, this.onPressed, super.key});

  /// The screen it goes back to, or null for the chevron alone.
  final String? label;

  /// What a tap does; pops the route when null, as [BackButton] does.
  final VoidCallback? onPressed;

  /// The chevron as the theme's automatic back button icon
  /// ([ActionIconThemeData.backButtonIconBuilder]).
  static Widget iconBuilder(BuildContext context) =>
      const Icon(AppIcons.chevronLeft, size: 28, weight: 700);

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final back = MaterialLocalizations.of(context).backButtonTooltip;
    final text = label;
    void press() {
      if (onPressed != null) {
        onPressed!();
      } else {
        Navigator.maybePop(context);
      }
    }

    return Semantics(
      // Its own node: in the team header nothing above starts one, so
      // without it the whole screen became one "Back" button.
      container: true,
      button: true,
      label: text == null ? back : '$back, $text',
      excludeSemantics: true,
      onTap: press,
      child: Tooltip(
        message: back,
        child: FocusRingInk(
          onTap: press,
          radius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: text == null ? 10 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.chevronLeft,
                    size: 28,
                    weight: 700,
                    color: c.textOnPage,
                  ),
                  if (text != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GumdropStyle.of(context).label(
                          TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: c.textOnPage,
                            shadows: const [],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
