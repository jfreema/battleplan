import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:battleplan/features/chat/domain/message.dart';
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
    super.key,
  });

  final Message message;
  final bool mine;
  final bool startsGroup;
  final bool endsGroup;

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

    final bubble = Container(
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
        if (m.pending)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: Space.xs),
            child: Text(
              l10n.messageSending,
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
