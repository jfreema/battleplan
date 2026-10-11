import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One row of the chat: a system line, or a bubble with the sender's name
/// and photo at the start of their group (CHAT-1). Tapping a bubble shows
/// its time; on the web, hovering does.
class MessageTile extends ConsumerStatefulWidget {
  const new({
    required this.message,
    required this.mine,
    required this.startsGroup,
    required this.endsGroup,
    this.showSent = false,
    super.key,
  });

  final Message message;
  final bool mine;
  final bool startsGroup;
  final bool endsGroup;

  /// Shows "Sent" under it: my newest message, once the server has it.
  final bool showSent;

  @override
  ConsumerState<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends ConsumerState<MessageTile> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (m.isSystem) {
      // CHAT-10: small centered lines like "Sam joined".
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Space.sm,
          horizontal: Space.xl,
        ),
        child: Text(
          m.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final mine = widget.mine;
    final scheme = theme.colorScheme;
    final background = mine ? scheme.primary : scheme.surfaceContainerHighest;
    final foreground = mine ? scheme.onPrimary : scheme.onSurface;
    final time = m.createdAt == null
        ? null
        : MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(m.createdAt!.toLocal()));
    final deleted = m.deletedAt != null;

    final hasText = m.text.trim().isNotEmpty;
    final textBubble = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: deleted ? Colors.transparent : background,
        border: deleted ? Border.all(color: scheme.outlineVariant) : null,
        borderRadius: BorderRadius.circular(Corners.bubble),
      ),
      child: deleted
          ? Text(
              l10n.messageDeleted,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            )
          : LinkifiedText(
              m.text,
              phones: !kIsWeb,
              style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
              linkColor: foreground,
              onOpen: (uri) =>
                  unawaited(ref.read(linkOpenerProvider).open(uri)),
            ),
    );
    // Photos sit above the caption (CHAT-3).
    final photos = deleted || m.attachments.isEmpty
        ? null
        : PhotoGrid(
            count: m.attachments.length,
            single: m.attachments.first.aspectRatio,
            tile: (i) => GestureDetector(
              onTap: () =>
                  unawaited(PhotoViewer.open(context, m.attachments, i)),
              child: StoredPhoto(attachment: m.attachments[i]),
            ),
          );
    final bubble = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?photos,
        if (photos != null && hasText) const SizedBox(height: 2),
        if (photos == null || hasText) textBubble,
      ],
    );

    final header = widget.startsGroup && !mine
        ? Padding(
            padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: nameWithPlayersOf(
                      m.authorName,
                      m.authorPlayerSummary,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (time != null) TextSpan(text: '  $time'),
                ],
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : widget.startsGroup && time != null
        ? Padding(
            padding: const EdgeInsets.only(right: Space.md, bottom: Space.xs),
            child: Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : null;

    final column = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ?header,
        MouseRegion(
          onEnter: (_) => setState(() => _showTime = true),
          onExit: (_) => setState(() => _showTime = false),
          child: GestureDetector(
            onTap: () => setState(() => _showTime = !_showTime),
            child: bubble,
          ),
        ),
        // Delivery state (CHAT-4): sending until the server has it, then
        // "Sent" under my newest message.
        if (m.pending || widget.showSent)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: Space.xs),
            child: Text(
              m.pending ? l10n.messageSending : l10n.messageSent,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else if (_showTime && time != null && !widget.startsGroup)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: Space.md),
            child: Text(time, style: theme.textTheme.labelSmall),
          ),
      ],
    );

    // Others' messages get their photo beside the first bubble of a group.
    final avatarSlot = SizedBox(
      width: 36,
      child: widget.startsGroup
          ? Padding(
              padding: const EdgeInsets.only(top: Space.lg),
              child: _AuthorAvatar(message: m),
            )
          : null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        widget.startsGroup ? Space.sm : 2,
        Space.md,
        widget.endsGroup ? Space.xs : 0,
      ),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[avatarSlot, const SizedBox(width: Space.sm)],
          Flexible(child: column),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends ConsumerWidget {
  const new({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = message.authorPhotoPath;
    final url = path == null
        ? null
        : ref.watch(teamPhotoUrlProvider(path)).value;
    return Avatar(
      name: message.authorName,
      colorKey: message.authorId,
      imageUrl: url,
      size: 32,
    );
  }
}

/// A photo message still uploading (CHAT-3, CHAT-4): the photos with a
/// progress bar, or Retry and Delete if the upload failed.
class OutgoingPhotosTile extends StatelessWidget {
  const new({
    required this.item,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  final OutgoingPhotos item;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: item.failed ? 0.5 : 1,
            child: PhotoGrid(
              count: item.photos.length,
              tile: (i) => LocalPhoto(bytes: item.photos[i].bytes),
            ),
          ),
          if (item.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(item.caption),
            ),
          const SizedBox(height: Space.xs),
          if (item.failed)
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.photosFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(AppIcons.retry),
                  label: Text(l10n.retry),
                ),
                TextButton(onPressed: onDiscard, child: Text(l10n.delete)),
              ],
            )
          else
            SizedBox(
              width: 280,
              child: LinearProgressIndicator(
                value: item.progress == 0 ? null : item.progress,
              ),
            ),
        ],
      ),
    );
  }
}

/// A text message not on the server yet (CHAT-4): "Sending…" while it waits
/// its turn (offline, until the connection returns), or "Not sent" with
/// Retry and Delete if the server refused it.
class OutgoingTextTile extends StatelessWidget {
  const new({
    required this.item,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  final OutgoingText item;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 2, Space.md, Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: item.failed ? 0.6 : 0.8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(Corners.bubble),
              ),
              child: Text(
                item.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
          if (item.failed)
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.messageNotSent,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
                TextButton(onPressed: onRetry, child: Text(l10n.retry)),
                TextButton(onPressed: onDiscard, child: Text(l10n.delete)),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2, right: Space.xs),
              child: Text(
                l10n.messageSending,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
