import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/features/chat/presentation/quote_block.dart';
import 'package:battleplan/features/chat/presentation/reactions.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    this.highlighted = false,
    this.quoted,
    this.onReply,
    this.onOpenQuote,
    super.key,
  });

  final Message message;
  final bool mine;
  final bool startsGroup;
  final bool endsGroup;

  /// Shows "Sent" under it: my newest message, once the server has it.
  final bool showSent;

  /// Briefly tinted after jumping to it from a quote.
  final bool highlighted;

  /// The original of a reply, when loaded, for the quote until the server
  /// has written `replyPreview`.
  final Message? quoted;

  /// Starts a reply (menu, or swipe right on phones). Null where replying
  /// isn't allowed.
  final VoidCallback? onReply;

  /// Jumps to the quoted original (CHAT-13).
  final VoidCallback? onOpenQuote;

  @override
  ConsumerState<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends ConsumerState<MessageTile> {
  bool _showTime = false;
  bool _hovering = false;

  /// How far the bubble is dragged right toward a reply (phones).
  double _swipe = 0;
  static const _swipeToReply = 64.0;

  Future<void> _react(Reaction r) => ref
      .read(chatMessagesProvider(widget.message.groupId).notifier)
      .react(widget.message, r);

  /// On the web, a small button beside a hovered bubble opens the menu.
  Widget _hoverButton() => IconButton(
    tooltip: AppLocalizations.of(context).messageMenu,
    visualDensity: VisualDensity.compact,
    icon: const Icon(AppIcons.addReaction, size: 20),
    onPressed: () => unawaited(_openMenu()),
  );

  /// React, Copy text (and, with later tasks, Reply, Delete, Report).
  Future<void> _openMenu() async {
    final m = widget.message;
    final l10n = AppLocalizations.of(context);
    final me = ref.read(authUserProvider).value?.uid;
    await showAdaptiveSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionPicker(
                mine: me == null ? null : m.reactions[me],
                onPick: (r) {
                  Navigator.of(sheet).pop();
                  fireAndForget(_react(r));
                },
              ),
              const Divider(height: Space.xl),
              if (widget.onReply case final reply?)
                ListTile(
                  leading: const Icon(AppIcons.reply),
                  title: Text(l10n.reply),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    reply();
                  },
                ),
              if (m.text.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(AppIcons.copy),
                  title: Text(l10n.copyText),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(Clipboard.setData(ClipboardData(text: m.text)));
                    showAppSnackBar(context, l10n.textCopied);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    // A reply's quote (CHAT-13): the server's copy, or the loaded original
    // until the server has written it.
    final preview = m.replyPreview;
    final original = widget.quoted;
    final quote = m.replyToId == null || deleted
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: QuoteBlock(
              authorName: preview?.authorName ?? original?.authorName ?? '',
              text: preview != null
                  ? quoteText(l10n, preview.type, preview.text)
                  : original == null
                  ? ''
                  : quoteText(l10n, original.type, original.text),
              deleted:
                  (preview?.deleted ?? false) || original?.deletedAt != null,
              foreground: foreground.withValues(alpha: 0.85),
              onTap: widget.onOpenQuote,
            ),
          );
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ?quote,
                if (hasText)
                  LinkifiedText(
                    m.text,
                    phones: !kIsWeb,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                    ),
                    linkColor: foreground,
                    onOpen: (uri) =>
                        unawaited(ref.read(linkOpenerProvider).open(uri)),
                  ),
              ],
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
        if (photos == null || hasText || quote != null) textBubble,
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
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () => setState(() => _showTime = !_showTime),
            // Swipe right to reply (CHAT-13, phones).
            onHorizontalDragUpdate: widget.onReply == null || kIsWeb
                ? null
                : (d) => setState(
                    () => _swipe = (_swipe + d.delta.dx).clamp(0, 96),
                  ),
            onHorizontalDragEnd: widget.onReply == null || kIsWeb
                ? null
                : (_) {
                    if (_swipe >= _swipeToReply) {
                      unawaited(HapticFeedback.selectionClick());
                      widget.onReply!();
                    }
                    setState(() => _swipe = 0);
                  },
            // The message menu (CHAT-7): long-press on phones, right-click
            // on the web. Double-tap loves it (CHAT-6).
            onLongPress: deleted ? null : () => unawaited(_openMenu()),
            onSecondaryTap: deleted ? null : () => unawaited(_openMenu()),
            onDoubleTap: deleted || kIsWeb
                ? null
                : () => fireAndForget(_react(Reaction.love)),
            child: Transform.translate(
              offset: Offset(_swipe, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mine && _hovering && !deleted) _hoverButton(),
                  Flexible(child: bubble),
                  if (!mine && _hovering && !deleted) _hoverButton(),
                ],
              ),
            ),
          ),
        ),
        if (m.reactions.isNotEmpty && !deleted)
          ReactionChips(
            message: m,
            me: ref.watch(authUserProvider).value?.uid,
            onShowWho: () => unawaited(
              showAdaptiveSheet<void>(
                context,
                builder: (_) => ReactionsSheet(message: m),
              ),
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
        else if ((_showTime || _hovering) &&
            time != null &&
            !widget.startsGroup)
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

    final row = Padding(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: widget.highlighted
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      child: row,
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
