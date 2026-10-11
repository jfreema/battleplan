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

  /// The message the next send replies to (CHAT-13).
  Message? _replyTo;

  /// Keys for message rows, so a tapped quote can scroll to its original.
  final Map<String, GlobalKey> _rowKeys = {};

  /// The message just jumped to, briefly highlighted.
  String? _highlighted;
  Timer? _unhighlight;

  GlobalKey _keyFor(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls to [messageId], loading older pages first if needed (CHAT-13).
  Future<void> _jumpTo(String messageId) async {
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final found = await controller.loadUntil(messageId);
    if (!found || !mounted) return;
    // Rows are built lazily, so step toward older messages until the
    // original's row exists, then bring it to the middle of the screen.
    for (var i = 0; i < 200 && mounted; i++) {
      await WidgetsBinding.instance.endOfFrame;
      final row = _rowKeys[messageId]?.currentContext;
      if (row != null && row.mounted) {
        await Scrollable.ensureVisible(
          row,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
        );
        setState(() => _highlighted = messageId);
        _unhighlight?.cancel();
        _unhighlight = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _highlighted = null);
        });
        return;
      }
      final p = _scroll.position;
      if (p.pixels >= p.maxScrollExtent) return;
      _scroll.jumpTo(
        (p.pixels + p.viewportDimension * 0.8).clamp(0, p.maxScrollExtent),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _unhighlight?.cancel();
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
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final picker = ref.watch(photoPickerProvider);
    final byId = {for (final m in messages) m.id: m};
    final shownIds = byId.keys.toSet();
    // Things still on their way, shown below everything (the list is
    // reversed): uploading photos, then queued or refused texts. A queued
    // text whose local write is already in the chat shows there instead.
    final pending = <Widget>[
      for (final item in chat.outgoing)
        OutgoingPhotosTile(
          item: item,
          onRetry: () =>
              unawaited(controller.retryPhotos(item.id).catchError((_) {})),
          onDiscard: () => controller.discardPhotos(item.id),
        ),
      for (final q in chat.queued)
        if (!shownIds.contains(q.id))
          OutgoingTextTile(
            item: q,
            onRetry: () =>
                unawaited(controller.retryText(q.id).catchError((_) {})),
            onDiscard: () => controller.discardText(q.id),
          ),
    ].reversed.toList();
    // "Sent" goes under my newest message once the server has it, unless
    // something of mine is still on its way.
    final newestMine = messages.where((m) => m.authorId == me).firstOrNull;
    final sentId = pending.isEmpty && newestMine != null && !newestMine.pending
        ? newestMine.id
        : null;

    Widget list;
    if (chat.loading) {
      list = const SkeletonList();
    } else if (messages.isEmpty && pending.isEmpty) {
      list = EmptyState(icon: AppIcons.chat, message: l10n.chatEmpty);
    } else {
      list = ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        itemCount: pending.length + messages.length + 1,
        itemBuilder: (context, index) {
          if (index < pending.length) return pending[index];
          final i = index - pending.length;
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
                key: _keyFor(m.id),
                message: m,
                mine: m.authorId == me,
                startsGroup: newDay || !_continues(older, m),
                endsGroup: newer == null || !_continues(m, newer),
                showSent: m.id == sentId,
                highlighted: m.id == _highlighted,
                // Until the server writes the quote, show it from the
                // original if it's loaded.
                quoted: m.replyToId == null ? null : byId[m.replyToId],
                onReply: archived ? null : () => setState(() => _replyTo = m),
                onOpenQuote: m.replyToId == null
                    ? null
                    : () => unawaited(_jumpTo(m.replyToId!)),
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
            replyingTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            onSend: (text) {
              unawaited(controller.send(text, replyToId: _replyTo?.id));
              setState(() => _replyTo = null);
            },
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
