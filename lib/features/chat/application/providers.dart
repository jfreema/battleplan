import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/chat_queue_store.dart';
import 'package:battleplan/features/chat/domain/mentions.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/domain/strong_language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.freezed.dart';
part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Where the send queue is kept on the device (CHAT-4). In memory unless
/// app/providers.dart wires the stored one.
@Riverpod(keepAlive: true)
ChatQueueStore chatQueueStore(Ref ref) => MemoryChatQueueStore();

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

    /// Opened at the first unread message with more unread than the newest
    /// page holds (CHAT-1): the newest message loaded below it, after which
    /// messages are missing until scrolling down loads them. Null when
    /// nothing is missing.
    String? gapAfter,
    @Default(false) bool loadingNewer,

    /// False while the newest page comes from the offline cache: photos
    /// wait for a connection (CHAT-4).
    @Default(true) bool online,

    /// Photo messages still uploading, oldest first (CHAT-3).
    @Default(<OutgoingPhotos>[]) List<OutgoingPhotos> outgoing,

    /// Text messages waiting their turn or refused, oldest first (CHAT-4).
    /// Each disappears once the server has it.
    @Default(<OutgoingText>[]) List<OutgoingText> queued,

    /// Polls waiting their turn in the send queue or refused (POLL-1), so a
    /// poll posted offline behind a queued text still shows as sending.
    @Default(<OutgoingPoll>[]) List<OutgoingPoll> polls,
  }) = _ChatState;
}

/// A poll not yet on the server.
@freezed
abstract class OutgoingPoll with _$OutgoingPoll {
  const factory({
    /// The ID its poll and message will have.
    required String id,
    required NewPoll poll,
    @Default(false) bool failed,
  }) = _OutgoingPoll;
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

    /// Who it names with @, and an admin's @everyone (CHAT-14).
    @Default(<String>[]) List<String> mentions,
    @Default(false) bool mentionsEveryone,

    /// An admin's announcement (CHAT-15).
    @Default(false) bool announcement,
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

    /// Offline: waiting for the connection to come back, then it uploads
    /// by itself (CHAT-4).
    @Default(false) bool waiting,
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
  // Messages from people I blocked are collapsed, so they don't count
  // (CHAT-12); nor do system lines like "Sam joined".
  final blocked = ref.watch(blockedIdsProvider);
  return await ref
      .read(messageRepositoryProvider)
      .countUnread(
        groupId,
        read ?? DateTime.fromMillisecondsSinceEpoch(0),
        skipAuthors: blocked,
      );
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

  /// Continues loading newer messages into the gap (CHAT-1).
  PageCursor? _newerCursor;
  bool _anchored = false;

  /// Set while [openAt] loads; older pages wait for it, since they then
  /// continue from the first unread message back.
  Future<void>? _anchoring;

  /// Texts saved on the device from an earlier run, sent once the newest
  /// page shows which of them the server or the offline cache already has.
  List<SavedText>? _restore;
  Timer? _photoRetry;

  /// Each send starts at least this long after the server confirmed the
  /// previous one. The server stamps a message before it confirms, so two
  /// stamps are always more than a second apart, which keeps everyone under
  /// the one-message-a-second rule without noticing (CHAT-4, SAFE-5).
  static const sendSpacing = Duration(milliseconds: 1050);
  Future<void> _sendQueue = Future.value();
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ChatState build(GroupId groupId) {
    final saved = ref.read(chatQueueStoreProvider).load(groupId);
    _restore = saved.isEmpty ? null : saved;
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
          final wasOnline = state.online;
          _publish(
            reachedStart:
                (!_loadedOlder && page.next == null) || state.reachedStart,
          );
          state = state.copyWith(online: !page.fromCache);
          // Back online: photos waiting for the connection go now.
          if (!wasOnline && state.online) _retryWaitingPhotos();
          _restoreQueue();
        });
    ref.onDispose(() {
      unawaited(sub.cancel());
      _markAgain?.cancel();
      _photoRetry?.cancel();
    });
    return const ChatState();
  }

  /// Sends texts saved from an earlier run (CHAT-4). One already in the
  /// chat (the server has it, or the offline cache will send it) is done.
  void _restoreQueue() {
    final saved = _restore;
    if (saved == null) return;
    _restore = null;
    final items = [
      for (final s in saved)
        if (!_known.containsKey(s.id) && !state.queued.any((q) => q.id == s.id))
          OutgoingText(
            id: s.id,
            text: s.text,
            replyToId: s.replyToId,
            mentions: s.mentions,
            mentionsEveryone: s.mentionsEveryone,
            announcement: s.announcement,
          ),
    ];
    state = state.copyWith(queued: [...state.queued, ...items]);
    _saveQueue();
    for (final item in items) {
      unawaited(_sendText(item));
    }
  }

  /// Keeps the queued texts on the device, so closing the app offline
  /// loses none of them (CHAT-4).
  void _saveQueue() => unawaited(
    ref
        .read(chatQueueStoreProvider)
        .save(groupId, [
          for (final q in state.queued)
            SavedText(
              id: q.id,
              text: q.text,
              replyToId: q.replyToId,
              mentions: q.mentions,
              mentionsEveryone: q.mentionsEveryone,
              announcement: q.announcement,
            ),
        ])
        .catchError((Object _) {}),
  );

  /// Opens the chat at the first unread message (CHAT-1, CHAT-9). When more
  /// arrived since [readAt] than the newest page holds, loads the 50 just
  /// after it; the rest load as the person scrolls down ([loadNewer]).
  Future<void> openAt(DateTime readAt) async {
    if (_anchored) return;
    _anchored = true;
    // The newest page holds the whole chat, or reaches back to the marker.
    if (_liveCursor == null) return;
    final live = [for (final id in _liveIds) ?_known[id]?.createdAt];
    if (live.isEmpty || live.any((at) => !at.isAfter(readAt))) return;
    final done = Completer<void>();
    _anchoring = done.future;
    state = state.copyWith(loadingNewer: true);
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .loadNewer(groupId, after: readAt);
      _addNewer(page);
      // Older pages now continue from the first unread message back.
      _loadedOlder = true;
      _olderCursor = page.older;
      _publish(reachedStart: page.older == null);
    } finally {
      _anchoring = null;
      done.complete();
      state = state.copyWith(loadingNewer: false);
    }
  }

  /// The newer page loading now, so a second caller waits for it instead
  /// of returning before it's in ([loadUntil]).
  Future<void>? _newerLoad;

  /// Loads the next 50 newer messages into the gap below the first unread
  /// ones (scrolling down, CHAT-1), until it meets the newest page. While
  /// one is already loading, waits for that one.
  Future<void> loadNewer() {
    if (_newerLoad case final load?) return load;
    final cursor = _newerCursor;
    if (cursor == null || state.loadingNewer) return Future.value();
    return _newerLoad = _loadNewer(cursor)
        .whenComplete(() => _newerLoad = null);
  }

  Future<void> _loadNewer(PageCursor cursor) async {
    state = state.copyWith(loadingNewer: true);
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .loadNewer(groupId, cursor: cursor);
      _addNewer(page);
      _publish();
    } finally {
      state = state.copyWith(loadingNewer: false);
    }
  }

  /// Merges a newer page; the gap closes once it reaches the newest page.
  void _addNewer(MessagePage page) {
    for (final m in page.messages) {
      _known.putIfAbsent(m.id, () => m);
    }
    final joined =
        page.next == null ||
        page.messages.isEmpty ||
        page.messages.any((m) => _liveIds.contains(m.id));
    _newerCursor = joined ? null : page.next;
    state = state.copyWith(gapAfter: joined ? null : page.messages.first.id);
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
    if (_anchoring case final anchoring?) await anchoring;
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
      caption: _filtered(caption.trim()),
    );
    state = state.copyWith(outgoing: [...state.outgoing, item]);
    return _upload(item);
  }

  /// Tries a failed photo message again.
  Future<void> retryPhotos(int id) {
    final item = state.outgoing.where((o) => o.id == id).firstOrNull;
    if (item == null) return Future.value();
    _updateOutgoing(
      id,
      (o) => o.copyWith(failed: false, waiting: false, progress: 0),
    );
    return _upload(item, evenOffline: true);
  }

  /// Drops a failed photo message.
  void discardPhotos(int id) => state = state.copyWith(
    outgoing: state.outgoing.where((o) => o.id != id).toList(),
  );

  /// Photos wait for a connection (CHAT-4): uploads that stopped offline
  /// start again when the chat is back online, and every 30 seconds in
  /// case the chat doesn't notice.
  void _retryWaitingPhotos() {
    _photoRetry?.cancel();
    _photoRetry = null;
    for (final o in state.outgoing) {
      if (o.waiting) unawaited(retryPhotos(o.id));
    }
  }

  void _waitForConnection(int id) {
    _updateOutgoing(id, (o) => o.copyWith(waiting: true, progress: 0));
    _photoRetry ??= Timer(const Duration(seconds: 30), _retryWaitingPhotos);
  }

  void _updateOutgoing(int id, OutgoingPhotos Function(OutgoingPhotos) f) =>
      state = state.copyWith(
        outgoing: [
          for (final o in state.outgoing)
            if (o.id == id) f(o) else o,
        ],
      );

  /// Uploads right away, then joins the send queue only to post, so a slow
  /// upload never holds up text messages sent after it.
  Future<void> _upload(OutgoingPhotos item, {bool evenOffline = false}) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(messageRepositoryProvider);
    // Offline: wait for the connection instead of failing (CHAT-4).
    if (!state.online && !evenOffline) {
      _waitForConnection(item.id);
      return;
    }
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
    } on Offline {
      // The connection dropped mid-upload: wait for it, then go again.
      _waitForConnection(item.id);
    } on Object {
      // Shown in the chat with Retry and Delete; nothing else to report.
      _updateOutgoing(item.id, (o) => o.copyWith(failed: true));
    }
  }

  /// Sends a text message, spaced from the previous one (CHAT-2, CHAT-4).
  /// It shows as "sending" at once; offline, it waits in the queue and goes
  /// out when the connection returns. [mentions] and [mentionsEveryone] are
  /// who it names with @ (CHAT-14), and [announcement] makes it an admin's
  /// announcement (CHAT-15).
  Future<void> send(
    String text, {
    String? replyToId,
    List<String> mentions = const [],
    bool mentionsEveryone = false,
    bool announcement = false,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    final item = OutgoingText(
      id: ref.read(messageRepositoryProvider).newMessageId(),
      text: _filtered(trimmed),
      replyToId: replyToId,
      mentions: mentions,
      mentionsEveryone: mentionsEveryone,
      announcement: announcement,
    );
    state = state.copyWith(queued: [...state.queued, item]);
    _saveQueue();
    return _sendText(item);
  }

  /// Posts a poll (POLL-1), spaced from other sends like a message. It
  /// shows as sending at once, even while it waits behind queued texts.
  /// Throws if the server refuses it; it then stays with Retry and Delete.
  Future<void> sendPoll(NewPoll poll) {
    final item = OutgoingPoll(
      id: ref.read(messageRepositoryProvider).newMessageId(),
      poll: poll.copyWith(
        question: _filtered(poll.question),
        options: [for (final o in poll.options) _filtered(o)],
      ),
    );
    state = state.copyWith(polls: [...state.polls, item]);
    return _sendPoll(item);
  }

  /// Tries a refused poll again.
  Future<void> retryPoll(String id) {
    final item = state.polls.where((p) => p.id == id).firstOrNull;
    if (item == null) return Future.value();
    _setPoll(id, failed: false);
    return _sendPoll(item);
  }

  /// Drops a refused poll.
  void discardPoll(String id) => state = state.copyWith(
    polls: state.polls.where((p) => p.id != id).toList(),
  );

  void _setPoll(String id, {required bool failed}) => state = state.copyWith(
    polls: [
      for (final p in state.polls)
        if (p.id == id) p.copyWith(failed: failed) else p,
    ],
  );

  Future<void> _sendPoll(OutgoingPoll item) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(messageRepositoryProvider);
    try {
      await _enqueue(
        () => repo.sendPoll(groupId, UserId(uid), item.poll, id: item.id),
      );
      discardPoll(item.id);
    } on Object {
      _setPoll(item.id, failed: true);
      rethrow;
    }
  }

  /// Tries a refused message again.
  Future<void> retryText(String id) {
    final item = state.queued.where((q) => q.id == id).firstOrNull;
    if (item == null) return Future.value();
    _setQueued(id, failed: false);
    return _sendText(item);
  }

  /// Drops a refused message.
  void discardText(String id) {
    state = state.copyWith(
      queued: state.queued.where((q) => q.id != id).toList(),
    );
    _saveQueue();
  }

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
          mentions: item.mentions,
          mentionsEveryone: item.mentionsEveryone,
          announcement: item.announcement,
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

  /// Loads pages until [messageId] is loaded or the chat's start is
  /// reached, for jumping to a quoted message (CHAT-13): first the gap
  /// below the first unread messages, if any, then older pages. Gives up
  /// after [maxPages] pages (2,000 messages) each way, so a long gap never
  /// uses up the older pages a quote usually needs. A gap page already
  /// loading is waited for rather than skipped.
  Future<bool> loadUntil(String messageId, {int maxPages = 40}) async {
    for (var i = 0; i < maxPages; i++) {
      if (state.gapAfter == null || _known.containsKey(messageId)) break;
      await loadNewer();
    }
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
  DateTime? _markUpTo;

  /// Marks messages read as they come on screen (CHAT-9): all of them when
  /// the newest is on screen, or up to [upTo], the newest one on screen,
  /// while reading partway up. At most every 2 seconds, and only when it
  /// moves the marker forward.
  Future<void> markRead({DateTime? upTo}) async {
    final uid = ref.read(authUserProvider).value?.uid;
    final newest = state.messages.where((m) => !m.pending).firstOrNull;
    final newestAt = newest?.createdAt;
    if (uid == null || newestAt == null) return;
    // Up to the newest message is the same as all of it, and when there's
    // a gap below, the newest message isn't the last one: say so exactly.
    final partial = upTo != null && upTo.isBefore(newestAt) ? upTo : null;
    final read = ref.read(myMembershipProvider(groupId))?.lastReadAt;
    if (read != null && !(partial ?? newestAt).isAfter(read)) return;
    final since = DateTime.now().difference(_lastMarked);
    if (since < const Duration(seconds: 2)) {
      // Try again once the 2 seconds are up, so the last message counts.
      _markUpTo = partial;
      _markAgain ??= Timer(const Duration(seconds: 2) - since, () {
        _markAgain = null;
        unawaited(markRead(upTo: _markUpTo).catchError((Object _) {}));
      });
      return;
    }
    _lastMarked = DateTime.now();
    await ref
        .read(memberRepositoryProvider)
        .markRead(groupId, UserId(uid), upTo: partial);
  }

  /// Edits my message's text (CHAT-15). Rules allow only the author.
  Future<void> edit(Message message, String text) => ref
      .read(messageRepositoryProvider)
      .editText(message.id, _filtered(text.trim()));

  /// [text] with strong language masked when the team filters it (SAFE-7),
  /// as the sender sees it at once; the server masks anything that gets
  /// past an older app.
  String _filtered(String text) =>
      ref.read(groupProvider(groupId)).value?.settings.filterLanguage ?? true
      ? maskStrongLanguage(text)
      : text;

  /// Pins or unpins a message on the bar at the top (CHAT-15). Admins.
  Future<void> setPinned(Message message, {required bool pinned}) =>
      ref.read(messageRepositoryProvider).setPinned(message.id, pinned: pinned);
}

/// A pinned message, live, for the bar at the top of the chat (CHAT-15).
@riverpod
Stream<Message?> pinnedMessage(Ref ref, GroupId groupId, String messageId) =>
    ref.watch(messageRepositoryProvider).watchMessage(groupId, messageId);

/// The team's pinned messages, newest pin first (CHAT-15).
@riverpod
List<String> pinnedMessageIds(Ref ref, GroupId groupId) => [
  ...?ref
      .watch(groupProvider(groupId).select((g) => g.value?.pinnedMessageIds))
      ?.reversed,
];

/// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).
@riverpod
Map<String, String> memberNames(Ref ref, GroupId groupId) => {
  for (final m
      in ref.watch(rosterProvider(groupId)).value ?? const <Membership>[])
    if (m.displayName.trim().isNotEmpty) m.uid.value: m.displayName.trim(),
};

/// Who can be named with @ in a team's chat (CHAT-14): everyone on the
/// team but me, by name.
@riverpod
List<MentionCandidate> mentionCandidates(Ref ref, GroupId groupId) {
  final me = ref.watch(authUserProvider).value?.uid;
  return [
    for (final e in ref.watch(memberNamesProvider(groupId)).entries)
      if (e.key != me) (uid: e.key, name: e.value),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
