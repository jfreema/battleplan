import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/chat/application/direct_chats.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Messages in the team header (CHAT-19), beside the bell: two speech
/// bubbles with how many conversations have unread messages (muted ones
/// left out), 1 to 99+. On Teams too, where Messages goes back to Teams.
class MessagesButton extends ConsumerWidget {
  const new({this.backLabel, super.key});

  /// What Messages' back label says (#14): the team's name in its header;
  /// null on Teams, where it's Messages' usual "Teams".
  final String? backLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(directUnreadCountProvider);
    // A 48 px header icon button (SPEC §7.3).
    return GumdropIconButton(
      tooltip: count > 0
          ? l10n.messagesButtonUnread(count)
          : l10n.messagesButton,
      icon: AppIcons.directMessage,
      badgeLabel: count > 0 ? unreadLabel(count) : null,
      onPressed: () => unawaited(
        context.push(
          '/messages',
          extra: backLabel == null ? null : BackLabel(backLabel),
        ),
      ),
    );
  }
}
