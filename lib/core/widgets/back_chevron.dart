import 'dart:math' as math;

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
  const new({
    this.label,
    this.semanticLabel,
    this.onPressed,
    this.showDot = false,
    this.dotLabel,
    super.key,
  });

  /// The screen it goes back to, or null for the chevron alone.
  final String? label;

  /// For the chevron alone: what screen readers hear and the tooltip says
  /// in place of "Back" ("Back to Teams"), so where it goes is said, not
  /// only shown.
  final String? semanticLabel;

  /// What a tap does; pops the route when null, as [BackButton] does.
  final VoidCallback? onPressed;

  /// A coral dot at the chevron's top right: the screen it goes back to has
  /// news (a team's back to Teams: unread notifications or messages in the
  /// other teams, NOTIF-11, CHAT-9).
  final bool showDot;

  /// What screen readers hear, and the tooltip adds, while the dot shows.
  final String? dotLabel;

  /// The chevron as the theme's automatic back button icon
  /// ([ActionIconThemeData.backButtonIconBuilder]).
  static Widget iconBuilder(BuildContext context) =>
      const Icon(AppIcons.chevronLeft, size: 28, weight: 700);

  /// The back label's text style: Fredoka 600 17.
  static TextStyle labelStyle(BuildContext context) =>
      GumdropStyle.of(context).label(
        TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: GumdropColors.of(context).textOnPage,
          shadows: const [],
        ),
      );

  /// How wide the button is with [label] (or the chevron alone), for
  /// laying things out beside it: the page frame's small title (#14).
  static double widthOf(BuildContext context, String? label) {
    if (label == null) return 48;
    final painter = TextPainter(
      text: TextSpan(text: label, style: labelStyle(context)),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    // The padding, the 28 px chevron, and the gap before the label.
    return math.max(48, 10 + 28 + 6 + width + 8);
  }

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

    final dot = showDot ? dotLabel : null;
    // "Back to Teams, news in your other teams": said in full, and shown
    // on hover and long press, so the dot never has to be guessed at.
    final said = [semanticLabel ?? back, ?text, ?dot].join(', ');
    final icon = Icon(
      AppIcons.chevronLeft,
      size: 28,
      weight: 700,
      color: c.textOnPage,
    );
    return Semantics(
      // Its own node: in the team header nothing above starts one, so
      // without it the whole screen became one "Back" button.
      container: true,
      button: true,
      label: said,
      excludeSemantics: true,
      onTap: press,
      child: Tooltip(
        message: text == null ? said : back,
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
                  if (showDot)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        icon,
                        // 9 px of coral in a 2 px ring of the page.
                        Positioned(
                          top: 2,
                          right: -1,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: c.badgeRing,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 9,
                              height: 9,
                              // Coral, as unread is (SPEC §7.2).
                              decoration: BoxDecoration(
                                color: c.you.face,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    icon,
                  if (text != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle(context),
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
