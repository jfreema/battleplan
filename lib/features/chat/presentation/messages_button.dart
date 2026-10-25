import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/chat/application/direct_chats.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Messages in the team header (CHAT-19), beside the bell: two speech
/// bubbles with how many conversations have unread messages (muted ones
/// left out), 1 to 99+.
class MessagesButton extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(directUnreadCountProvider);
    // A 38 px round gumdrop (Gumdrop Pop design §3.1).
    return GumdropIconButton(
      tooltip: count > 0
          ? l10n.messagesButtonUnread(count)
          : l10n.messagesButton,
      icon: AppIcons.directMessage,
      badgeLabel: count > 0 ? unreadLabel(count) : null,
      onPressed: () => unawaited(context.push('/messages')),
    );
  }
}
