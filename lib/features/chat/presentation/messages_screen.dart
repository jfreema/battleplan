import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/chat/application/direct_chats.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/direct_chat.dart';
import 'package:battleplan/features/chat/presentation/direct_actions.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/notifications/notifications.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Messages (CHAT-19): my direct conversations, newest first, each with
/// the other person's photo and name, the newest message, when, and how
/// many I haven't read. New message starts one with anyone on my teams.
class MessagesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chats = ref.watch(myDirectChatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          final id = await showNewMessage(context);
          if (id != null && context.mounted) {
            unawaited(context.push('/messages/${id.value}'));
          }
        },
        icon: const Icon(AppIcons.newMessage),
        label: Text(l10n.newMessage),
      ),
      body: switch (chats) {
        AsyncValue(value: final list?) when list.isEmpty => EmptyState(
          icon: AppIcons.directMessage,
          message: l10n.messagesEmpty,
        ),
        AsyncValue(value: final list?) => ListView.builder(
          // Room under the last row for New message.
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          itemBuilder: (_, i) => _ChatRow(chat: list[i]),
        ),
        AsyncError() => EmptyState(
          icon: AppIcons.error,
          message: l10n.messagesLoadError,
        ),
        _ => const SkeletonList(),
      },
    );
  }
}

/// One conversation in Messages: photo, name, the newest message ("You:"
/// before mine), when, and the unread count, gray when muted (NOTIF-3).
class _ChatRow extends ConsumerWidget {
  const new({required this.chat});

  final DirectChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final other = chat.other;
    final name = other?.name ?? '';
    final photoPath = other?.photoPath;
    final photoUrl = photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(photoPath)).value;
    final text = chat.group.lastMessageText ?? '';
    final preview = chat.lastIsMine ? l10n.directYou(text) : text;
    final unread = chat.hasUnread
        ? ref.watch(unreadCountProvider(chat.group.id)).value ?? 0
        : 0;
    final muted = chat.membership.isMutedAt(DateTime.now());
    final at = chat.lastActivity;
    return ListTile(
      leading: Avatar(
        name: name,
        colorKey: chat.otherUid,
        imageUrl: photoUrl,
        size: 48,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: unread > 0 ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (at != null)
            Text(
              relativeTime(l10n, at, DateTime.now()),
              style: theme.textTheme.labelSmall,
            ),
          const SizedBox(height: Space.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (muted)
                Icon(AppIcons.muted, size: 16, color: scheme.onSurfaceVariant),
              if (unread > 0)
                Badge(
                  label: Text(unreadLabel(unread)),
                  backgroundColor: muted ? scheme.outline : null,
                ),
            ],
          ),
        ],
      ),
      onTap: () => unawaited(context.push('/messages/${chat.group.id.value}')),
    );
  }
}

/// New message (CHAT-19): the people on my teams, searchable by name, each
/// with the teams we share. Picking one finds our conversation, making it
/// the first time; the sheet closes with its ID for the caller to open.
Future<GroupId?> showNewMessage(BuildContext context) =>
    showAdaptiveSheet<GroupId>(context, builder: (_) => const _NewMessage());

class _NewMessage extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends ConsumerState<_NewMessage> {
  final _search = TextEditingController();
  String _query = '';

  /// The person whose conversation is opening, for a spinner on their row.
  String? _opening;

  /// Why the last one couldn't open.
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(MessageablePerson person) async {
    setState(() {
      _opening = person.uid.value;
      _error = null;
    });
    final found = await findDirectChat(
      ref,
      AppLocalizations.of(context),
      person.uid,
    );
    if (!mounted) return;
    if (found.id case final id?) {
      Navigator.of(context).pop(id);
      return;
    }
    // Said here: a snack bar would sit under the sheet.
    setState(() {
      _opening = null;
      _error = found.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(messageablePeopleProvider);
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final p in people)
        if (q.isEmpty || p.name.toLowerCase().contains(q)) p,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.lg,
                Space.lg,
                Space.sm,
              ),
              child: Text(
                l10n.newMessage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search),
                  hintText: l10n.newMessageSearch,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.sm,
                  Space.lg,
                  0,
                ),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: Text(
                          people.isEmpty
                              ? l10n.newMessageNobody
                              : l10n.newMessageNoMatch,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final p = shown[i];
                        return _PersonRow(
                          person: p,
                          opening: _opening == p.uid.value,
                          onTap: _opening == null
                              ? () => unawaited(_open(p))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const new({required this.person, required this.opening, this.onTap});

  final MessageablePerson person;
  final bool opening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = person.photoPath;
    final url = path == null
        ? null
        : ref.watch(teamPhotoUrlProvider(path)).value;
    return ListTile(
      leading: Avatar(
        name: person.name,
        colorKey: person.uid.value,
        imageUrl: url,
      ),
      title: Text(person.name),
      subtitle: Text(
        person.teams.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: opening
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: onTap,
    );
  }
}
