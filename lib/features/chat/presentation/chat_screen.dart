import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/mentions.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/chat/presentation/message_tile.dart';
import 'package:battleplan/features/chat/presentation/quote_block.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/polls/polls.dart';
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

  /// The list's two halves meet here (CHAT-1): older messages grow up from
  /// it, newer ones down, so loading either never moves what's on screen.
  final GlobalKey _centerKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();

  /// Messages after this time sit below the center: the unread ones when
  /// the chat opened with some, else ones that arrive while it's open.
  DateTime? _split;

  /// The message the next send replies to (CHAT-13).
  Message? _replyTo;

  /// An admin is writing an announcement (CHAT-15).
  bool _announcing = false;

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

  /// The chat opened on a page from the offline cache with nothing unread
  /// in it: the server's first page may still bring unread messages, and
  /// then it opens at the first of them after all (CHAT-1).
  bool _openedFromCache = false;

  /// Whether the newest messages are on screen.
  bool _atBottom = true;

  /// Whether the list is scrolled all the way down, so it stays there as
  /// messages arrive.
  bool _stick = true;

  /// The bottom of the list. Scroll offsets grow upward from where the two
  /// halves meet, so newer messages are at negative offsets.
  double get _bottom => _scroll.position.minScrollExtent;

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
    // Below the center, step down toward it; above, step up.
    final at = ref
        .read(chatMessagesProvider(widget.groupId))
        .messages
        .where((m) => m.id == messageId)
        .firstOrNull
        ?.createdAt;
    final split = _split;
    final down = at != null && split != null && at.isAfter(split);
    // Motion tokens, still when the system reduces motion (SPEC §7.3).
    final duration = highlight
        ? Motion.of(context, Motion.slow)
        : Duration.zero;
    for (var i = 0; i < 200 && mounted; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!_scroll.hasClients) continue;
      final row = _rowKeys[messageId]?.currentContext;
      if (row != null && row.mounted) {
        await Scrollable.ensureVisible(
          row,
          alignment: alignment,
          duration: duration,
          curve: Motion.curve,
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
      if (down
          ? p.pixels <= p.minScrollExtent
          : p.pixels >= p.maxScrollExtent) {
        return;
      }
      final step = p.viewportDimension * 0.8 * (down ? -1 : 1);
      _scroll.jumpTo(
        (p.pixels + step).clamp(p.minScrollExtent, p.maxScrollExtent),
      );
    }
  }

  /// Photos pasted or dropped on the web page (SPEC §4.2), and whether
  /// files are being dragged over it.
  StreamSubscription<List<PickedPhoto>>? _drops;
  StreamSubscription<bool>? _drags;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _scroll
      ..addListener(_maybeLoadOlder)
      ..addListener(_trackBottom);
    final drops = ref.read(photoDropsProvider);
    _drops = drops.photos.listen(_onDropped);
    _drags = drops.dragging.listen((on) {
      if (mounted && on != _dragging) setState(() => _dragging = on);
    });
  }

  /// Whether this chat is the one on screen and can take photos: its tab
  /// showing, nothing covering it, and someone who can post.
  bool get _takesDrops {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return false;
    if (!(ModalRoute.isCurrentOf(context) ?? true)) return false;
    if (ref.read(viewingAsSuperAdminProvider(widget.groupId))) return false;
    final group = ref.read(groupProvider(widget.groupId)).value;
    return group != null && !group.isArchived;
  }

  /// Pasted or dropped photos (CHAT-2) send as picked ones do (CHAT-3),
  /// within the upload limit and not into full storage (STORE-4).
  void _onDropped(List<PickedPhoto> photos) {
    if (!_takesDrops) return;
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    unawaited(_sendPicked(photos, controller));
    _scrollToBottomSoon();
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
    _stick = _scroll.position.pixels <= _bottom + 2;
    final atBottom = _scroll.position.pixels < _bottom + 150;
    if (atBottom != _atBottom) setState(() => _atBottom = atBottom);
    _markRead();
  }

  /// Messages count as read once they're on screen, while this tab is the
  /// one showing and the app is in front (CHAT-9): all of them with the
  /// newest on screen, else up to the newest one showing.
  void _markRead() {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    // A super admin viewing the team has no read marker (ADMIN-3).
    if (ref.read(viewingAsSuperAdminProvider(widget.groupId))) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    final chat = ref.read(chatMessagesProvider(widget.groupId));
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    if (_atBottom && chat.gapAfter == null) {
      unawaited(controller.markRead().catchError((Object _) {}));
      return;
    }
    final upTo = _newestOnScreen(chat.messages);
    if (upTo == null) return;
    unawaited(controller.markRead(upTo: upTo).catchError((Object _) {}));
  }

  /// When the newest message whose bottom edge is on screen was sent, or
  /// null if none newer than the read marker is.
  DateTime? _newestOnScreen(List<Message> messages) {
    final list = _listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.attached || !list.hasSize) return null;
    final top = list.localToGlobal(Offset.zero).dy;
    final bottom = top + list.size.height;
    final read = ref.read(myMembershipProvider(widget.groupId))?.lastReadAt;
    for (final m in messages) {
      final at = m.createdAt;
      if (m.pending || at == null) continue;
      if (read != null && !at.isAfter(read)) return null;
      final row = _rowKeys[m.id]?.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.attached || !row.hasSize) continue;
      final end = row.localToGlobal(Offset.zero).dy + row.size.height;
      if (end > top && end <= bottom + 1) return at;
    }
    return null;
  }

  /// Opens at the message a notification named (NOTIF-6), or else at the
  /// first unread message (CHAT-1, CHAT-9), or else at the bottom.
  void _open(ChatState chat, String? me) {
    _positioned = true;
    final read = _openedReadAt;
    final unread = _hasUnread(chat, me);
    if (unread) {
      _split = read;
    } else {
      _split =
          chat.messages.where((m) => !m.pending).firstOrNull?.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      _openedFromCache = !chat.online;
    }
    final target = widget.initialMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (unread) _toFirstUnread(scroll: target == null);
      if (target != null) unawaited(_jumpTo(target));
    });
  }

  /// Whether [chat] has messages from others after the read marker the
  /// chat opened with.
  bool _hasUnread(ChatState chat, String? me) {
    final read = _openedReadAt;
    return read != null &&
        chat.messages.any(
          (m) =>
              m.authorId != me &&
              !m.pending &&
              !m.isSystem &&
              (m.createdAt?.isAfter(read) ?? false),
        );
  }

  /// The chat opened on the offline cache with nothing unread (bootstrap
  /// keeps a cache, so a reopened chat's first page is the one seen last
  /// time). Once the server's first page is in, open at the first unread
  /// message after all, unless the person has scrolled or a notification
  /// named a message.
  void _reopenFromServer(ChatState chat, String? me) {
    _openedFromCache = false;
    final read = _openedReadAt;
    if (read == null || !_stick || widget.initialMessageId != null) return;
    if (!_hasUnread(chat, me)) return;
    _split = read;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toFirstUnread();
    });
  }

  /// Unread messages go below the center, the first of them at it. More
  /// than the newest page holds load from the read marker on (openAt).
  /// With [scroll], the first of them is brought on screen.
  void _toFirstUnread({bool scroll = true}) {
    final read = _openedReadAt;
    if (read == null) return;
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    unawaited(controller.openAt(read).catchError((_) {}));
    if (!scroll || !_scroll.hasClients) return;
    _stick = false;
    // The first unread message near the top, or the bottom if all of
    // them fit on screen.
    final p = _scroll.position;
    _scroll.jumpTo(math.max(p.minScrollExtent, -p.viewportDimension * 0.85));
  }

  void _loadOlder() => unawaited(
    ref
        .read(chatMessagesProvider(widget.groupId).notifier)
        .loadOlder()
        .catchError((Object _) {}),
  );

  void _loadNewer() => unawaited(
    ref
        .read(chatMessagesProvider(widget.groupId).notifier)
        .loadNewer()
        .catchError((Object _) {}),
  );

  /// After sending, show the bottom, where the new message is.
  void _scrollToBottomSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(_bottom);
      });

  @override
  void dispose() {
    unawaited(_drops?.cancel());
    unawaited(_drags?.cancel());
    _unhighlight?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Older messages are toward the max scroll extent (upward).
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
    // A super admin viewing the team reads it and moderates, nothing more
    // (ADMIN-3): no composer, replies, or reactions.
    final viewing = ref.watch(viewingAsSuperAdminProvider(widget.groupId));
    // The team's chat look (CHAT-18): my bubble color and the background.
    // No color chosen means the team color, as Team settings shows it, so
    // changing only the background never changes the bubbles; a team with
    // neither keeps the brand color and a plain chat.
    final look = group?.chatTheme;
    final bubbleArgb = look?.bubbleColor ?? group?.color;
    final bubbleColor = bubbleArgb == null ? null : Color(bubbleArgb);
    // Full storage stops photos, not text (STORE-4).
    final storageFull = group?.storageFull ?? false;
    final messages = chat.messages;
    final controller = ref.read(chatMessagesProvider(widget.groupId).notifier);
    final picker = ref.watch(photoPickerProvider);
    final candidates = ref.watch(mentionCandidatesProvider(widget.groupId));
    final byId = {for (final m in messages) m.id: m};
    final membership = ref.watch(myMembershipProvider(widget.groupId));
    // Team admins, and super admins on the team (§3): @everyone,
    // announcements, and polls.
    final isAdmin =
        (membership?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    // The bar at the top, newest pin first (CHAT-15).
    final pinnedIds = ref.watch(pinnedMessageIdsProvider(widget.groupId));
    if (!_openedMarkerTaken &&
        !chat.loading &&
        (membership != null || viewing)) {
      _openedMarkerTaken = true;
      _openedReadAt = membership?.lastReadAt;
      _open(chat, me);
    } else if (_openedFromCache && chat.online) {
      _reopenFromServer(chat, me);
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
                    !m.isSystem &&
                    (m.createdAt?.isAfter(_openedReadAt!) ?? false),
              )
              .lastOrNull
              ?.id;
    // "↓ 12 new" while scrolled up with messages after the read marker; with
    // some not loaded yet, the team's unread count says how many.
    final readAt = membership?.lastReadAt;
    final loadedNew = messages
        .where(
          (m) =>
              m.authorId != me &&
              !m.isSystem &&
              (readAt == null || (m.createdAt?.isAfter(readAt) ?? false)),
        )
        .length;
    final unread = chat.gapAfter == null
        ? 0
        : ref.watch(unreadCountProvider(widget.groupId)).value ?? 0;
    final newBelow = _atBottom ? 0 : (unread > loadedNew ? unread : loadedNew);
    // Stay at the bottom as messages arrive, if that's where the person is.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_stick && _scroll.offset != _bottom) _scroll.jumpTo(_bottom);
      _markRead();
    });
    final shownIds = byId.keys.toSet();
    // Things still on their way, shown below everything, oldest first:
    // uploading photos, then queued or refused texts. A queued text whose
    // local write is already in the chat shows there instead.
    final pending = <Widget>[
      for (final item in chat.outgoing)
        OutgoingPhotosTile(
          item: item,
          online: chat.online,
          // Retrying into full storage would only fail again (STORE-4).
          onRetry: storageFull
              ? () => showStorageFull(context)
              : () => unawaited(
                  controller.retryPhotos(item.id).catchError((_) {}),
                ),
          onDiscard: () => controller.discardPhotos(item.id),
        ),
      for (final q in chat.queued)
        if (!shownIds.contains(q.id))
          OutgoingTextTile(
            item: q,
            bubbleColor: bubbleColor,
            onRetry: () =>
                unawaited(controller.retryText(q.id).catchError((_) {})),
            onDiscard: () => controller.discardText(q.id),
          ),
      // Polls waiting their turn, shown by their question (POLL-1).
      for (final p in chat.polls)
        if (!shownIds.contains(p.id))
          OutgoingTextTile(
            item: OutgoingText(
              id: p.id,
              text: '${l10n.pollLabel}: ${p.poll.tidy.question}',
              failed: p.failed,
            ),
            bubbleColor: bubbleColor,
            onRetry: () =>
                unawaited(controller.retryPoll(p.id).catchError((_) {})),
            onDiscard: () => controller.discardPoll(p.id),
          ),
    ];
    // "Sent" stays under my newest message once the server has it, unless
    // something of mine is still on its way; the others show it with their
    // time (CHAT-4).
    final newestMine = messages.where((m) => m.authorId == me).firstOrNull;
    final sentId = pending.isEmpty && newestMine != null && !newestMine.pending
        ? newestMine.id
        : null;

    // Oldest first, to find each message's neighbors across both halves.
    final chrono = messages.reversed.toList();
    final split = _split;
    bool below(Message m) =>
        split != null && (m.createdAt == null || m.createdAt!.isAfter(split));
    final upper = [
      for (final m in messages)
        if (!below(m)) m,
    ];
    final lower = [
      for (final m in chrono)
        if (below(m)) m,
    ];
    final position = {for (final (i, m) in chrono.indexed) m.id: i};

    Widget row(Message m) {
      final i = position[m.id]!;
      final older = i > 0 ? chrono[i - 1] : null;
      final newer = i + 1 < chrono.length ? chrono[i + 1] : null;
      // Across the gap, the next loaded message isn't the next one.
      final afterGap = older != null && older.id == chat.gapAfter;
      final newDay = older == null
          ? chat.reachedStart
          : !_sameDay(older.createdAt, m.createdAt);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (newDay && m.createdAt != null) _DateSeparator(day: m.createdAt!),
          if (m.id == firstUnreadId) const _NewMessagesDivider(),
          MessageTile(
            key: _keyFor(m.id),
            message: m,
            mine: m.authorId == me,
            startsGroup: newDay || afterGap || !_continues(older, m),
            endsGroup:
                newer == null || m.id == chat.gapAfter || !_continues(m, newer),
            showSent: m.id == sentId,
            bubbleColor: bubbleColor,
            highlighted: m.id == _highlighted,
            pinned: pinnedIds.contains(m.id),
            // Until the server writes the quote, show it from the
            // original if it's loaded.
            quoted: m.replyToId == null ? null : byId[m.replyToId],
            onReply: archived || viewing
                ? null
                : () => setState(() => _replyTo = m),
            onOpenQuote: m.replyToId == null
                ? null
                : () => unawaited(_jumpTo(m.replyToId!)),
          ),
        ],
      );
    }

    Widget list;
    if (chat.loading) {
      list = const SkeletonList();
    } else if (messages.isEmpty && pending.isEmpty) {
      list = EmptyState(icon: AppIcons.chat, message: l10n.chatEmpty);
    } else {
      list = CustomScrollView(
        key: _listKey,
        controller: _scroll,
        reverse: true,
        center: _centerKey,
        slivers: [
          // Below the center, top to bottom: newer messages (with the gap
          // still to load, if any), then what's on its way.
          SliverPadding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            sliver: SliverList.list(children: pending),
          ),
          SliverList.builder(
            itemCount: lower.length,
            itemBuilder: (context, index) {
              final m = lower[index];
              if (m.id != chat.gapAfter) return row(m);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(m),
                  _GapLoader(key: ValueKey(m.id), onShown: _loadNewer),
                ],
              );
            },
          ),
          // Above the center, bottom to top: older messages, then the paging
          // footer at the very top.
          SliverList.builder(
            key: _centerKey,
            itemCount: upper.length + 1,
            itemBuilder: (context, index) {
              if (index < upper.length) return row(upper[index]);
              // Coming into view loads more, even without a scroll (say
              // right after opening at the first unread message).
              return chat.reachedStart
                  ? const SizedBox(height: Space.lg)
                  : _GapLoader(
                      key: ValueKey('older${upper.length}'),
                      onShown: _loadOlder,
                    );
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        if (pinnedIds.isNotEmpty)
          _PinnedBar(
            groupId: widget.groupId,
            ids: pinnedIds,
            onOpen: (id) => unawaited(_jumpTo(id)),
          ),
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
                    onPressed: () => Motion.reduced(context)
                        ? _scroll.jumpTo(_bottom)
                        : _scroll.animateTo(
                            _bottom,
                            duration: Motion.slow,
                            curve: Motion.curve,
                          ),
                    icon: const Icon(AppIcons.arrowDown),
                    label: Text(l10n.newMessagesBelow(newBelow)),
                  ),
                ),
              // Files dragged over the page (web): where they'll go.
              if (_dragging && !viewing && !archived)
                Positioned.fill(child: _DropHint(storageFull: storageFull)),
            ],
          ),
        ),
        if (viewing)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(l10n.chatViewingReadOnly, textAlign: TextAlign.center),
          )
        else if (archived)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(l10n.chatArchived, textAlign: TextAlign.center),
          )
        else
          Composer(
            teamName: group?.name ?? '',
            replyingTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            mentionCandidates: candidates,
            // @everyone is for admins (CHAT-14).
            canMentionEveryone: isAdmin,
            onAnnounce: isAdmin
                ? () => setState(() => _announcing = true)
                : null,
            announcing: _announcing && isAdmin,
            onCancelAnnouncement: () => setState(() => _announcing = false),
            onSend: (text) {
              // Whom it names, from the names in the text (CHAT-14).
              final named = mentionsIn(
                text,
                candidates,
                canMentionEveryone: isAdmin,
              );
              unawaited(
                controller.send(
                  text,
                  replyToId: _replyTo?.id,
                  mentions: named.uids,
                  mentionsEveryone: named.everyone,
                  announcement: _announcing && isAdmin,
                ),
              );
              setState(() {
                _replyTo = null;
                _announcing = false;
              });
              _scrollToBottomSoon();
            },
            onPickPhotos: () => unawaited(_pickPhotos(picker, controller)),
            onTakePhoto: picker.canUseCamera
                ? () => unawaited(_takePhoto(picker, controller))
                : null,
            // Polls (POLL-1) for admins, and for members if the team allows
            // it (TEAM-5). Full storage doesn't stop them (STORE-4).
            onCreatePoll:
                isAdmin || (group?.settings.membersCanCreatePolls ?? false)
                ? () => unawaited(_createPoll(controller))
                : null,
            onAttachBlocked: storageFull
                ? () => showStorageFull(context)
                : null,
          ),
      ],
    );
  }
}

extension on _ChatScreenState {
  /// Storage filled up while the picker was open: say so instead of
  /// uploading into a refusal (STORE-4).
  bool _fullAfterPicking() {
    final full =
        ref.read(groupProvider(widget.groupId)).value?.storageFull ?? false;
    if (full && mounted) showStorageFull(context);
    return full;
  }

  /// The photos within the upload limit (ADMIN-7). A bigger one is left
  /// out, with a message saying so.
  List<PickedPhoto> _withinLimit(List<PickedPhoto> photos) {
    final max = ref.read(maxUploadBytesProvider);
    final big = photos.where((p) => p.bytes.length > max).firstOrNull;
    if (big != null && mounted) fitsUploadLimit(context, ref, big.bytes.length);
    return [
      for (final p in photos)
        if (p.bytes.length <= max) p,
    ];
  }

  Future<void> _pickPhotos(PhotoPicker picker, ChatMessages controller) =>
      _sendPicked(picker.pickChatPhotos(), controller);

  /// Sends picked, pasted, or dropped photos, up to 10 (CHAT-3).
  Future<void> _sendPicked(
    FutureOr<List<PickedPhoto>> picked,
    ChatMessages controller,
  ) async {
    final photos = _withinLimit((await picked).take(10).toList());
    if (photos.isEmpty || _fullAfterPicking()) return;
    await controller
        .sendPhotos([
          for (final p in photos) (bytes: p.bytes, contentType: p.contentType),
        ])
        .catchError((Object _) {});
  }

  Future<void> _createPoll(ChatMessages controller) async {
    final poll = await showCreatePoll(context);
    if (poll == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    await controller.sendPoll(poll).catchError((Object _) {
      if (mounted) showAppSnackBar(context, l10n.pollSendFailed);
    });
  }

  Future<void> _takePhoto(PhotoPicker picker, ChatMessages controller) async {
    final p = await picker.takeChatPhoto();
    if (p == null || _withinLimit([p]).isEmpty || _fullAfterPicking()) return;
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

/// The team's chat background (CHAT-18): a subtle pattern, or a photo
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

/// The pinned messages at the top of the chat (CHAT-15): one at a time,
/// newest pin first, "Pinned 1 of 3" when there are more. Tapping opens
/// the message, loading older pages if needed, and moves on to the next.
class _PinnedBar extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.ids, required this.onOpen});

  final GroupId groupId;
  final List<String> ids;
  final void Function(String messageId) onOpen;

  @override
  ConsumerState<_PinnedBar> createState() => _PinnedBarState();
}

class _PinnedBarState extends ConsumerState<_PinnedBar> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = widget.ids.length;
    final index = _index % count;
    final id = widget.ids[index];
    final message = ref.watch(pinnedMessageProvider(widget.groupId, id)).value;
    final label = count > 1
        ? l10n.pinnedOf(index + 1, count)
        : l10n.pinnedMessage;
    final preview = message == null
        ? ''
        : [
            if (message.authorName.isNotEmpty) message.authorName,
            quoteText(l10n, message.type, message.text),
          ].where((p) => p.isNotEmpty).join(': ');
    return Semantics(
      button: true,
      label: l10n.pinnedBarLabel(label, preview),
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        child: InkWell(
          onTap: () {
            widget.onOpen(id);
            setState(() => _index = index + 1);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.xs,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.pin, size: 20, color: scheme.primary),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where messages are still missing (CHAT-1): below the first unread ones,
/// or above the oldest loaded. A spinner that loads the next 50 as it comes
/// into view.
class _GapLoader extends StatefulWidget {
  const new({required this.onShown, super.key});

  final VoidCallback onShown;

  @override
  State<_GapLoader> createState() => _GapLoaderState();
}

class _GapLoaderState extends State<_GapLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(Space.lg),
    child: Center(child: CircularProgressIndicator()),
  );
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

/// "Drop photos to send" over the chat while files are dragged over the
/// page (SPEC §4.2), or why they can't be added.
class _DropHint extends StatelessWidget {
  const new({required this.storageFull});

  final bool storageFull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ColoredBox(
        color: scheme.surface.withValues(alpha: 0.85),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.photo, size: 48, color: scheme.primary),
                const SizedBox(height: Space.md),
                Text(
                  storageFull ? l10n.storageFullMessage : l10n.chatDropPhotos,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
