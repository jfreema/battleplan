import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
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
import 'package:battleplan/features/groups/domain/group.dart';
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
  const new({required this.groupId, this.initialMessageId, super.key});

  final GroupId groupId;

  /// Opens scrolled to this message, briefly highlighted, instead of at the
  /// first unread one (a notification tap, NOTIF-6).
  final String? initialMessageId;

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

  /// The read marker when the chat opened: messages after it get the
  /// "New messages" divider for as long as the screen is open (CHAT-9).
  DateTime? _openedReadAt;
  bool _openedMarkerTaken = false;

  /// True once the chat has opened at the first unread message.
  bool _positioned = false;

  /// Whether the newest messages are on screen (the list is reversed).
  bool _atBottom = true;

  /// Scrolls to [messageId], loading older pages first if needed (CHAT-13).
  Future<void> _jumpTo(String messageId) async {
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final found = await controller.loadUntil(messageId);
    if (!found || !mounted) return;
    await _scrollToRow(messageId, alignment: 0.5, highlight: true);
  }

  /// Rows are built lazily, so step toward older messages until the row
  /// exists, then bring it to [alignment] of the screen.
  Future<void> _scrollToRow(
    String messageId, {
    required double alignment,
    bool highlight = false,
  }) async {
    for (var i = 0; i < 200 && mounted; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!_scroll.hasClients) continue;
      final row = _rowKeys[messageId]?.currentContext;
      if (row != null && row.mounted) {
        await Scrollable.ensureVisible(
          row,
          alignment: alignment,
          duration: highlight
              ? const Duration(milliseconds: 250)
              : Duration.zero,
        );
        if (!highlight || !mounted) return;
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
    _scroll
      ..addListener(_maybeLoadOlder)
      ..addListener(_trackBottom);
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    // Another notification for this chat while it's open.
    final target = widget.initialMessageId;
    if (target != null && target != old.initialMessageId && _positioned) {
      // After this frame: jumping loads older pages, which changes
      // providers, and that can't happen while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_jumpTo(target));
      });
    }
  }

  void _trackBottom() {
    final atBottom = _scroll.position.pixels < 150;
    if (atBottom != _atBottom) setState(() => _atBottom = atBottom);
    if (atBottom) _markRead();
  }

  /// Messages count as read once the newest are on screen, while this tab
  /// is the one showing and the app is in front (CHAT-9).
  void _markRead() {
    if (!mounted || !_atBottom || !TickerMode.valuesOf(context).enabled) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    unawaited(
      ref
          .read(chatMessagesProvider(widget.groupId).notifier)
          .markRead()
          .catchError((Object _) {}),
    );
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
    // A Plus team's chat look (PLAN-8): my bubble color and the background.
    final themed = group?.has(PlanFeature.chatTheme) ?? false;
    final look = themed ? (group!.chatTheme ?? const ChatTheme()) : null;
    final bubbleArgb = look?.bubbleColor ?? (themed ? group!.color : null);
    final bubbleColor = bubbleArgb == null ? null : Color(bubbleArgb);
    final messages = chat.messages;
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final picker = ref.watch(photoPickerProvider);
    final byId = {for (final m in messages) m.id: m};
    final membership = ref.watch(myMembershipProvider(widget.groupId));
    if (!_openedMarkerTaken && !chat.loading && membership != null) {
      _openedMarkerTaken = true;
      _openedReadAt = membership.lastReadAt;
    }
    // The oldest loaded message from someone else after the marker gets
    // the "New messages" divider.
    final firstUnreadId = _openedReadAt == null
        ? null
        : messages
              .where(
                (m) =>
                    m.authorId != me &&
                    !m.pending &&
                    (m.createdAt?.isAfter(_openedReadAt!) ?? false),
              )
              .lastOrNull
              ?.id;
    // Open at the message a notification named (NOTIF-6), or else at the
    // first unread message (CHAT-9), then keep the marker.
    if (!_positioned && !chat.loading) {
      _positioned = true;
      final target = widget.initialMessageId;
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_jumpTo(target));
        });
      } else if (firstUnreadId != null) {
        unawaited(_scrollToRow(firstUnreadId, alignment: 0.9));
      }
    }
    // "↓ 12 new" while scrolled up with messages after the read marker.
    final readAt = membership?.lastReadAt;
    final newBelow = _atBottom
        ? 0
        : messages
              .where(
                (m) =>
                    m.authorId != me &&
                    (readAt == null || (m.createdAt?.isAfter(readAt) ?? false)),
              )
              .length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
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
              if (m.id == firstUnreadId) const _NewMessagesDivider(),
              MessageTile(
                key: _keyFor(m.id),
                message: m,
                mine: m.authorId == me,
                startsGroup: newDay || !_continues(older, m),
                endsGroup: newer == null || !_continues(m, newer),
                showSent: m.id == sentId,
                bubbleColor: bubbleColor,
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
        Expanded(
          child: Stack(
            children: [
              if (look != null) Positioned.fill(child: _Backdrop(look: look)),
              list,
              if (newBelow > 0)
                Positioned(
                  right: Space.lg,
                  bottom: Space.sm,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: () => _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(AppIcons.arrowDown),
                    label: Text(l10n.newMessagesBelow(newBelow)),
                  ),
                ),
            ],
          ),
        ),
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

/// A Plus team's chat background (PLAN-8): a subtle pattern, or a photo
/// under a scrim so messages stay readable.
class _Backdrop extends ConsumerWidget {
  const new({required this.look});

  final ChatTheme look;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    switch (look.background) {
      case ChatBackground.plain:
        return const SizedBox.shrink();
      case ChatBackground.pattern:
        return CustomPaint(
          painter: _DotsPainter(scheme.onSurface.withValues(alpha: 0.06)),
        );
      case ChatBackground.photo:
        final path = look.backgroundPath;
        final url = path == null
            ? null
            : ref.watch(teamPhotoUrlProvider(path)).value;
        if (url == null) return const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            ColoredBox(color: scheme.surface.withValues(alpha: 0.78)),
          ],
        );
    }
  }
}

class _DotsPainter extends CustomPainter {
  new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 22.0;
    for (var y = step / 2; y < size.height; y += step) {
      final offset = (y ~/ step).isEven ? 0.0 : step / 2;
      for (var x = step / 2 + offset; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

/// The line above the first unread message (CHAT-9).
class _NewMessagesDivider extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Divider(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Text(
              AppLocalizations.of(context).newMessages,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color),
            ),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
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
