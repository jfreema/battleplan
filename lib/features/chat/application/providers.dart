import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.freezed.dart';
part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// What the chat screen shows (CHAT-1).
@freezed
abstract class ChatState with _$ChatState {
  const factory({
    /// Every message loaded so far, newest first.
    @Default(<Message>[]) List<Message> messages,

    /// True until the newest page first arrives.
    @Default(true) bool loading,
    @Default(false) bool loadingOlder,

    /// True once the first message of the chat is loaded.
    @Default(false) bool reachedStart,

    /// Photo messages still uploading, oldest first (CHAT-3).
    @Default(<OutgoingPhotos>[]) List<OutgoingPhotos> outgoing,

    /// Text messages waiting their turn or refused, oldest first (CHAT-4).
    /// Each disappears once the server has it.
    @Default(<OutgoingText>[]) List<OutgoingText> queued,
  }) = _ChatState;
}

/// A text message not yet on the server: waiting in the send queue (for
/// example while offline), or refused and waiting for Retry or Delete.
@freezed
abstract class OutgoingText with _$OutgoingText {
  const factory({
    /// The message ID it will have on the server.
    required String id,
    required String text,
    String? replyToId,
    @Default(false) bool failed,
  }) = _OutgoingText;
}

/// A photo message on its way up, shown in the chat with its progress.
@freezed
abstract class OutgoingPhotos with _$OutgoingPhotos {
  const factory({
    required int id,
    required List<NewPhoto> photos,
    @Default('') String caption,
    @Default(0) double progress,
    @Default(false) bool failed,
  }) = _OutgoingPhotos;
}

/// A team's unread message count for the switcher and the Chat tab, up to
/// 100 (CHAT-9). It only queries when the team's last message is newer
/// than the person's read marker, so a read team costs nothing.
@riverpod
Future<int> unreadCount(Ref ref, GroupId groupId) async {
  final last = ref.watch(groupProvider(groupId)).value?.lastMessageAt;
  final membership = ref.watch(myMembershipProvider(groupId));
  if (last == null || membership == null) return 0;
  final read = membership.lastReadAt;
  if (read != null && !last.isAfter(read)) return 0;
  return await ref
      .read(messageRepositoryProvider)
      .countUnread(groupId, read ?? DateTime.fromMillisecondsSinceEpoch(0));
}

/// "1" to "99", then "99+" (CHAT-9).
String unreadLabel(int count) => count > 99 ? '99+' : '$count';

/// A URL to show a message photo.
@riverpod
Future<String?> attachmentUrl(Ref ref, String path) =>
    ref.watch(messageRepositoryProvider).attachmentUrl(path);

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.
@riverpod
class ChatMessages extends _$ChatMessages {
  final Map<String, Message> _known = {};
  Set<String> _liveIds = {};
  PageCursor? _liveCursor;
  PageCursor? _olderCursor;
  bool _loadedOlder = false;

  /// Each send starts at least this long after the server confirmed the
  /// previous one. The server stamps a message before it confirms, so two
  /// stamps are always more than a second apart, which keeps everyone under
  /// the one-message-a-second rule without noticing (CHAT-4, SAFE-5).
  static const sendSpacing = Duration(milliseconds: 1050);
  Future<void> _sendQueue = Future.value();
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ChatState build(GroupId groupId) {
    final sub = ref
        .watch(messageRepositoryProvider)
        .watchNewest(groupId)
        .listen((page) {
          final ids = {for (final m in page.messages) m.id};
          // A message that leaves the live page has either slid out as newer
          // ones arrived (keep it) or was a local write the server refused
          // (drop it; the send queue shows it as failed).
          for (final gone in _liveIds.difference(ids)) {
            if (_known[gone]?.pending ?? false) _known.remove(gone);
          }
          _liveIds = ids;
          for (final m in page.messages) {
            _known[m.id] = m;
          }
          _liveCursor = page.next;
          _publish(
            reachedStart:
                (!_loadedOlder && page.next == null) || state.reachedStart,
          );
        });
    ref.onDispose(() {
      unawaited(sub.cancel());
      _markAgain?.cancel();
    });
    return const ChatState();
  }

  void _publish({bool? loadingOlder, bool? reachedStart}) {
    final sorted = _known.values.toList()
      ..sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null || bt == null) return at == null ? -1 : 1;
        return bt.compareTo(at);
      });
    state = state.copyWith(
      messages: sorted,
      loading: false,
      loadingOlder: loadingOlder ?? state.loadingOlder,
      reachedStart: reachedStart ?? state.reachedStart,
    );
  }

  /// Loads the next 50 older messages (scrolling up).
  Future<void> loadOlder() async {
    if (state.loadingOlder || state.reachedStart) return;
    final cursor = _loadedOlder ? _olderCursor : _liveCursor;
    if (cursor == null) {
      state = state.copyWith(reachedStart: true);
      return;
    }
    state = state.copyWith(loadingOlder: true);
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .loadOlder(groupId, cursor);
      for (final m in page.messages) {
        _known.putIfAbsent(m.id, () => m);
      }
      _loadedOlder = true;
      _olderCursor = page.next;
      _publish(loadingOlder: false, reachedStart: page.next == null);
    } on Object {
      state = state.copyWith(loadingOlder: false);
      rethrow;
    }
  }

  int _nextOutgoing = 0;

  /// Uploads photos, then posts them as one message (CHAT-3). The chat shows
  /// them with progress meanwhile; a failed upload stays with Retry.
  Future<void> sendPhotos(List<NewPhoto> photos, {String caption = ''}) {
    if (photos.isEmpty) return Future.value();
    final item = OutgoingPhotos(
      id: _nextOutgoing++,
      photos: photos.take(10).toList(),
      caption: caption.trim(),
    );
    state = state.copyWith(outgoing: [...state.outgoing, item]);
    return _upload(item);
  }

  /// Tries a failed photo message again.
  Future<void> retryPhotos(int id) {
    final item = state.outgoing.where((o) => o.id == id).firstOrNull;
    if (item == null) return Future.value();
    _updateOutgoing(id, (o) => o.copyWith(failed: false, progress: 0));
    return _upload(item);
  }

  /// Drops a failed photo message.
  void discardPhotos(int id) => state = state.copyWith(
    outgoing: state.outgoing.where((o) => o.id != id).toList(),
  );

  void _updateOutgoing(int id, OutgoingPhotos Function(OutgoingPhotos) f) =>
      state = state.copyWith(
        outgoing: [
          for (final o in state.outgoing)
            if (o.id == id) f(o) else o,
        ],
      );

  /// Uploads right away, then joins the send queue only to post, so a slow
  /// upload never holds up text messages sent after it.
  Future<void> _upload(OutgoingPhotos item) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(messageRepositoryProvider);
    try {
      final uploaded = await repo.uploadPhotos(
        groupId,
        item.photos,
        onProgress: (p) =>
            _updateOutgoing(item.id, (o) => o.copyWith(progress: p)),
      );
      await _enqueue(
        () => repo.sendPhotos(
          groupId,
          UserId(uid),
          uploaded,
          caption: item.caption,
        ),
      );
      discardPhotos(item.id);
    } on Object {
      // Shown in the chat with Retry and Delete; nothing else to report.
      _updateOutgoing(item.id, (o) => o.copyWith(failed: true));
    }
  }

  /// Sends a text message, spaced from the previous one (CHAT-2, CHAT-4).
  /// It shows as "sending" at once; offline, it waits in the queue and goes
  /// out when the connection returns.
  Future<void> send(String text, {String? replyToId}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    final item = OutgoingText(
      id: ref.read(messageRepositoryProvider).newMessageId(),
      text: trimmed,
      replyToId: replyToId,
    );
    state = state.copyWith(queued: [...state.queued, item]);
    return _sendText(item);
  }

  /// Tries a refused message again.
  Future<void> retryText(String id) {
    final item = state.queued.where((q) => q.id == id).firstOrNull;
    if (item == null) return Future.value();
    _setQueued(id, failed: false);
    return _sendText(item);
  }

  /// Drops a refused message.
  void discardText(String id) => state = state.copyWith(
    queued: state.queued.where((q) => q.id != id).toList(),
  );

  void _setQueued(String id, {required bool failed}) => state = state.copyWith(
    queued: [
      for (final q in state.queued)
        if (q.id == id) q.copyWith(failed: failed) else q,
    ],
  );

  Future<void> _sendText(OutgoingText item) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(messageRepositoryProvider);
    try {
      await _enqueue(
        () => repo.sendText(
          groupId,
          UserId(uid),
          item.text,
          id: item.id,
          replyToId: item.replyToId,
        ),
      );
      discardText(item.id);
    } on Object {
      // Shown in the chat as "Not sent" with Retry and Delete.
      _setQueued(item.id, failed: true);
    }
  }

  /// Runs [send] after the previous send, spaced by [sendSpacing].
  Future<void> _enqueue(Future<void> Function() send) {
    final next = _sendQueue.then((_) async {
      final wait = sendSpacing - DateTime.now().difference(_lastSend);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      try {
        await send();
      } finally {
        _lastSend = DateTime.now();
      }
    });
    // One failed send doesn't stop the ones queued after it.
    _sendQueue = next.catchError((Object _) {});
    return next;
  }

  /// Picks a reaction for me (CHAT-6): the same one again removes it, a
  /// different one replaces mine.
  Future<void> react(Message message, Reaction reaction) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final current = message.reactions[uid];
    await ref
        .read(messageRepositoryProvider)
        .setReaction(
          message.id,
          UserId(uid),
          current == reaction ? null : reaction,
        );
  }

  /// Loads older pages until [messageId] is loaded or the chat's start is
  /// reached, for jumping to a quoted message (CHAT-13). Gives up after
  /// [maxPages] pages (2,000 messages).
  Future<bool> loadUntil(String messageId, {int maxPages = 40}) async {
    for (var i = 0; i < maxPages; i++) {
      if (_known.containsKey(messageId)) return true;
      if (state.reachedStart) return false;
      await loadOlder();
    }
    return _known.containsKey(messageId);
  }

  /// Deletes a message for everyone (CHAT-8).
  Future<void> delete(Message message) =>
      ref.read(messageRepositoryProvider).deleteMessage(message.id);

  DateTime _lastMarked = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _markAgain;

  /// Marks the chat read when its newest message is on screen (CHAT-9), at
  /// most every 2 seconds and only when something is newer than the marker.
  Future<void> markRead() async {
    final uid = ref.read(authUserProvider).value?.uid;
    final newest = state.messages.where((m) => !m.pending).firstOrNull;
    if (uid == null || newest?.createdAt == null) return;
    final read = ref.read(myMembershipProvider(groupId))?.lastReadAt;
    if (read != null && !newest!.createdAt!.isAfter(read)) return;
    final since = DateTime.now().difference(_lastMarked);
    if (since < const Duration(seconds: 2)) {
      // Try again once the 2 seconds are up, so the last message counts.
      _markAgain ??= Timer(const Duration(seconds: 2) - since, () {
        _markAgain = null;
        unawaited(markRead().catchError((Object _) {}));
      });
      return;
    }
    _lastMarked = DateTime.now();
    await ref.read(memberRepositoryProvider).markRead(groupId, UserId(uid));
  }

  /// Edits my message's text (CHAT-15). Rules allow only the author.
  Future<void> edit(Message message, String text) =>
      ref.read(messageRepositoryProvider).editText(message.id, text.trim());
}
