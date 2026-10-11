import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/chat/presentation/message_tile.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Messages from one person within this long of each other share a header.
const _groupGap = Duration(minutes: 5);

/// The team chat (CHAT-1, CHAT-2): newest at the bottom, 50 at a time, with
/// older pages loading as you scroll up, date separators, and messages
/// grouped by sender.
class ChatScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The list is reversed, so "older" is toward its max scroll extent.
  void _maybeLoadOlder() {
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 600) {
      unawaited(
        ref
            .read(chatMessagesProvider(widget.groupId).notifier)
            .loadOlder()
            .catchError((Object _) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = ref.watch(chatMessagesProvider(widget.groupId));
    final me = ref.watch(authUserProvider).value?.uid;
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final archived = group?.isArchived ?? false;
    final messages = chat.messages;
    final outgoing = chat.outgoing;
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final picker = ref.watch(photoPickerProvider);

    Widget list;
    if (chat.loading) {
      list = const SkeletonList();
    } else if (messages.isEmpty && outgoing.isEmpty) {
      list = EmptyState(icon: AppIcons.chat, message: l10n.chatEmpty);
    } else {
      list = ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        itemCount: outgoing.length + messages.length + 1,
        itemBuilder: (context, index) {
          // Uploading photos sit below everything (the list is reversed).
          if (index < outgoing.length) {
            final item = outgoing[outgoing.length - 1 - index];
            return OutgoingPhotosTile(
              item: item,
              onRetry: () =>
                  unawaited(controller.retryPhotos(item.id).catchError((_) {})),
              onDiscard: () => controller.discardPhotos(item.id),
            );
          }
          final i = index - outgoing.length;
          // The last item (top of the screen) is the paging footer.
          if (i == messages.length) {
            return chat.reachedStart
                ? const SizedBox(height: Space.lg)
                : const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
          }
          final m = messages[i];
          final older = i + 1 < messages.length ? messages[i + 1] : null;
          final newer = i > 0 ? messages[i - 1] : null;
          final newDay = older == null
              ? chat.reachedStart
              : !_sameDay(older.createdAt, m.createdAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay && m.createdAt != null)
                _DateSeparator(day: m.createdAt!),
              MessageTile(
                message: m,
                mine: m.authorId == me,
                startsGroup: newDay || !_continues(older, m),
                endsGroup: newer == null || !_continues(m, newer),
              ),
            ],
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(child: list),
        if (archived)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(l10n.chatArchived, textAlign: TextAlign.center),
          )
        else
          Composer(
            onSend: (text) => unawaited(controller.send(text)),
            onPickPhotos: () => unawaited(_pickPhotos(picker, controller)),
            onTakePhoto: picker.canUseCamera
                ? () => unawaited(_takePhoto(picker, controller))
                : null,
          ),
      ],
    );
  }
}

extension on _ChatScreenState {
  Future<void> _pickPhotos(PhotoPicker picker, ChatMessages controller) async {
    final photos = await picker.pickChatPhotos();
    if (photos.isEmpty) return;
    await controller
        .sendPhotos([
          for (final p in photos) (bytes: p.bytes, contentType: p.contentType),
        ])
        .catchError((Object _) {});
  }

  Future<void> _takePhoto(PhotoPicker picker, ChatMessages controller) async {
    final p = await picker.takeChatPhoto();
    if (p == null) return;
    await controller
        .sendPhotos([(bytes: p.bytes, contentType: p.contentType)])
        .catchError((Object _) {});
  }
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return true;
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Whether [next] continues [prev]'s group: same sender, within 5 minutes.
bool _continues(Message? prev, Message next) {
  if (prev == null || prev.isSystem || next.isSystem) return false;
  if (prev.authorId != next.authorId) return false;
  final a = prev.createdAt;
  final b = next.createdAt;
  return a == null || b == null || b.difference(a).abs() <= _groupGap;
}

/// "Today", "Yesterday", or "Mon, Oct 6" (CHAT-1).
String dayLabel(AppLocalizations l10n, DateTime day, DateTime now) {
  final d = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return l10n.today;
  if (diff == 1) return l10n.yesterday;
  return d.year == today.year
      ? DateFormat.MMMEd(l10n.localeName).format(d)
      : DateFormat.yMMMEd(l10n.localeName).format(d);
}

class _DateSeparator extends StatelessWidget {
  const new({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Center(
        child: Text(
          dayLabel(AppLocalizations.of(context), day.toLocal(), DateTime.now()),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
