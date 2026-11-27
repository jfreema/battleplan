import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Icon, one sentence, and at most one action (SPEC §7.5): a 64 px icon
/// and 15 px reading text, both muted, and one coral button, with at most
/// one quiet link under it ([linkLabel]; the team's empty Schedule has
/// Import a schedule, #3).
class EmptyState extends StatelessWidget {
  const new({
    required this.message,
    this.icon,
    this.art,
    this.actionLabel,
    this.onAction,
    this.linkLabel,
    this.onLink,
    super.key,
  }) : assert(icon != null || art != null, 'An icon, or art to draw');

  final IconData? icon;

  /// A drawn icon in place of [icon], such as `PlaysIcon`, in the same size
  /// and color.
  final Widget? art;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A quiet text link under the button, for a second, lesser way forward.
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = actionLabel;
    // Centered, and scrolling where the space is short (a small phone,
    // large text) rather than overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Center(child: _content(context, scheme, label)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme, String? label) {
    return Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 64, color: scheme.onSurfaceVariant),
              child: art ?? Icon(icon),
            ),
            const SizedBox(height: Space.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 21 / 15,
                fontWeight: AppFonts.reading,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (label != null && onAction != null) ...[
              const SizedBox(height: Space.xl),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
            if (linkLabel case final link? when onLink != null) ...[
              const SizedBox(height: Space.sm),
              TextButton(
                style: GumdropButtons.of(context).link(),
                onPressed: onLink,
                child: Text(link, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
