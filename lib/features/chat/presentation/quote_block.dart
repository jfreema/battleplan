import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
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

/// A quoted message (CHAT-13): a recessed block with a mint bar on its
/// left, the author in Fredoka, and one muted line (Gumdrop Pop §3.14). On
/// the page (others' replies, and above the composer) it's a `field` well
/// in the page's text colors. In a bubble ([bubble], with its text color
/// [bubbleText]: my own, or an announcement) it's the bubble's color mixed
/// 40% away from its text, in that text color, so it reads on any Chat look
/// color (CHAT-18).
class QuoteBlock extends StatelessWidget {
  const new({
    required this.authorName,
    required this.text,
    this.deleted = false,
    this.onTap,
    this.bubble,
    this.bubbleText,
    super.key,
  });

  final String authorName;
  final String text;

  /// The original was deleted: shows "Original message was deleted".
  final bool deleted;
  final VoidCallback? onTap;

  /// The bubble it sits in, and the bubble's text color; null on the page.
  final Color? bubble;
  final Color? bubbleText;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(6),
    bottomLeft: Radius.circular(6),
    topRight: Radius.circular(12),
    bottomRight: Radius.circular(12),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final fill = bubble;
    final ink = bubbleText;
    final inBubble = fill != null && ink != null;
    // Away from the text: toward white under dark text, toward black under
    // white text.
    final well = inBubble
        ? Color.lerp(
            fill,
            ink.computeLuminance() < 0.5
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF000000),
            0.4,
          )!
        : c.inputFill;
    final author = inBubble ? ink : c.textOnPage;
    final line = inBubble ? ink.withValues(alpha: 0.8) : c.textMutedOnPage;
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1.25,
      color: line,
    );
    return Semantics(
      button: onTap != null,
      label: deleted
          ? l10n.quoteDeleted
          : l10n.quoteSemantics(authorName, text),
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onTap,
      child: Material(
        color: well,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.mint.face, width: 4)),
            ),
            child: deleted
                ? Text(
                    l10n.quoteDeleted,
                    style: muted.copyWith(fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authorName,
                        style: GumdropStyle.of(context).label(
                          TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.25,
                            color: author,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
