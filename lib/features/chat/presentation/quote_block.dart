import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// What a quote shows of a message: its first line, or "Photo" or "Poll".
String quoteText(AppLocalizations l10n, MessageType type, String text) {
  final first = text.trim().split('\n').first;
  if (first.isNotEmpty) return first;
  return switch (type) {
    MessageType.image => l10n.quotePhoto,
    MessageType.poll => l10n.quotePoll,
    MessageType.event => l10n.quoteEvent,
    _ => '',
  };
}

/// A quoted message: a colored bar, the author, and one line (CHAT-13).
class QuoteBlock extends StatelessWidget {
  const new({
    required this.authorName,
    required this.text,
    this.deleted = false,
    this.onTap,
    this.foreground,
    super.key,
  });

  final String authorName;
  final String text;

  /// The original was deleted: shows "Original message was deleted".
  final bool deleted;
  final VoidCallback? onTap;

  /// Text color, to sit inside a colored bubble.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = foreground ?? theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: onTap != null,
      label: deleted
          ? l10n.quoteDeleted
          : l10n.quoteSemantics(authorName, text),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.chip),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            Space.sm,
            Space.xs,
            Space.sm,
            Space.xs,
          ),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: deleted
              ? Text(
                  l10n.quoteDeleted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authorName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
