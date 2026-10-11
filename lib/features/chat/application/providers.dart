import 'dart:async';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
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
  }) = _ChatState;
}

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.
@riverpod
class ChatMessages extends _$ChatMessages {
  final Map<String, Message> _known = {};
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
          for (final m in page.messages) {
            _known[m.id] = m;
          }
          _liveCursor = page.next;
          _publish(
            reachedStart:
                (!_loadedOlder && page.next == null) || state.reachedStart,
          );
        });
    ref.onDispose(sub.cancel);
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

  /// Sends a text message, spaced from the previous one (CHAT-2, CHAT-4).
  Future<void> send(String text) {
    final trimmed = text.trim();
    final uid = ref.read(authUserProvider).value?.uid;
    if (trimmed.isEmpty || uid == null) return Future.value();
    final repo = ref.read(messageRepositoryProvider);
    final next = _sendQueue.then((_) async {
      final wait = sendSpacing - DateTime.now().difference(_lastSend);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      try {
        await repo.sendText(groupId, UserId(uid), trimmed);
      } finally {
        _lastSend = DateTime.now();
      }
    });
    // One failed send doesn't stop the ones queued after it.
    _sendQueue = next.catchError((Object _) {});
    return next;
  }
}
