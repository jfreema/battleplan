import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// A flat tag for status and information (a role, when reminders go, a
/// count): outlined, with no lip or face, so it never looks like a button.
/// Gumdrops are only for things that do something.
class InfoTag extends StatelessWidget {
  const new({required this.text, this.icon, this.iconColor, super.key});

  final String text;
  final IconData? icon;

  /// The icon's color when it means something (an answer's color);
  /// otherwise the text's.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final color = c.onCard ? c.textPrimary : c.textOnPage;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: 16, color: iconColor ?? color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: GumdropStyle.of(context).label(
                TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.2,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
