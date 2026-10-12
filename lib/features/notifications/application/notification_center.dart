import 'dart:async';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_center.freezed.dart';
part 'notification_center.g.dart';

/// What the notification center shows (NOTIF-11).
@freezed
abstract class NotificationCenterState with _$NotificationCenterState {
  const factory({
    /// Every item loaded so far, newest first, before hiding blocked and
    /// expired ones (the screen does that, so unblocking shows them again).
    @Default(<NotificationItem>[]) List<NotificationItem> items,

    /// True until the first page arrives.
    @Default(true) bool loading,
    @Default(false) bool loadingMore,

    /// True once the oldest item is loaded.
    @Default(false) bool reachedEnd,
  }) = _NotificationCenterState;
}

/// The center across all my teams: the live newest 30 plus older pages
/// loaded by scrolling, merged by ID (ARCH §5.3). The listener runs only
/// while the screen is open (ARCH §10.2).
@riverpod
class NotificationCenter extends _$NotificationCenter {
  final Map<String, NotificationItem> _known = {};
  Set<String> _liveIds = {};
  NotificationCursor? _liveCursor;
  NotificationCursor? _olderCursor;
  bool _loadedOlder = false;

  @override
  NotificationCenterState build() {
    final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
    if (uid == null) {
      return const NotificationCenterState(loading: false, reachedEnd: true);
    }
    final sub = ref
        .watch(notificationRepositoryProvider)
        .watchNewest(UserId(uid))
        .listen(_onLivePage);
    ref.onDispose(() => unawaited(sub.cancel()));
    return const NotificationCenterState();
  }

  void _onLivePage(NotificationPage page) {
    final ids = {for (final n in page.items) n.id};
    final oldestLive = page.items.lastOrNull?.createdAt;
    // An item that leaves a full live page has slid out as newer ones
    // arrived (keep it). One that leaves from inside the page was deleted,
    // for example by leaving its team (drop it).
    for (final gone in _liveIds.difference(ids)) {
      final at = _known[gone]?.createdAt;
      final slidOut =
          page.next != null &&
          at != null &&
          oldestLive != null &&
          at.isBefore(oldestLive);
      if (!slidOut) _known.remove(gone);
    }
    _liveIds = ids;
    for (final n in page.items) {
      _known[n.id] = n;
    }
    _liveCursor = page.next;
    _publish(
      reachedEnd: (!_loadedOlder && page.next == null) || state.reachedEnd,
    );
  }

  void _publish({bool? loadingMore, bool? reachedEnd}) {
    final sorted = _known.values.toList()
      ..sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null || bt == null) return at == null ? -1 : 1;
        return bt.compareTo(at);
      });
    state = state.copyWith(
      items: sorted,
      loading: false,
      loadingMore: loadingMore ?? state.loadingMore,
      reachedEnd: reachedEnd ?? state.reachedEnd,
    );
  }

  /// Loads the next 30 older items (scrolling down).
  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || state.reachedEnd) return;
    final uid = ref.read(authUserProvider).value?.uid;
    final cursor = _loadedOlder ? _olderCursor : _liveCursor;
    if (uid == null || cursor == null) {
      state = state.copyWith(reachedEnd: true);
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .loadOlder(UserId(uid), cursor);
      if (!ref.mounted) return;
      for (final n in page.items) {
        _known.putIfAbsent(n.id, () => n);
      }
      _loadedOlder = true;
      _olderCursor = page.next;
      _publish(loadingMore: false, reachedEnd: page.next == null);
    } on Object {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
      rethrow;
    }
  }

  /// Marks an item read when it's opened. The live page picks up the change
  /// at once; older pages are updated here.
  Future<void> markRead(NotificationItem item) async {
    if (item.read) return;
    _known[item.id] = item.copyWith(read: true);
    _publish();
    await ref.read(notificationRepositoryProvider).markRead(item.id);
    if (ref.mounted) ref.invalidate(unreadNotificationCountProvider);
  }

  /// "Mark all as read" (NOTIF-11).
  Future<void> markAllRead() async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    for (final n in _known.values.where((n) => !n.read).toList()) {
      _known[n.id] = n.copyWith(read: true);
    }
    _publish();
    await ref.read(notificationRepositoryProvider).markAllRead(UserId(uid));
    if (ref.mounted) ref.invalidate(unreadNotificationCountProvider);
  }
}
