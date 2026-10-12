import 'dart:async';

import 'package:battleplan/app/router.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/notifications/presentation/open_route.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_handler.g.dart';

/// Pushes the person taps, and pushes that arrive while the app is open
/// (NOTIF-6, NOTIF-7, ARCH §6.5 "In the app"). In app/ because it drives
/// the router. Started from app.dart.
@Riverpod(keepAlive: true)
class PushHandler extends _$PushHandler {
  @override
  void build() {
    final push = ref.watch(pushRepositoryProvider);
    final subs = [
      push.openedMessages().listen(open),
      push.foregroundMessages().listen(_onForeground),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    unawaited(_openLaunchMessage(push));
  }

  /// Opens a tapped push (or the banner's Open) and marks its center item
  /// read. [coldStart] replaces the stack, since nothing is underneath.
  void open(PushMessage message, {bool coldStart = false}) {
    final signedIn = ref.read(authUserProvider).value != null;
    final opened = openNotificationRoute(
      ref.read(routerProvider),
      message.route,
      replace: coldStart || !signedIn,
    );
    if (opened) unawaited(_markRead(message));
  }

  /// The push whose tap launched the app. It waits for the first frame (so
  /// the router has its first route) and for sign-in to resolve; signed out,
  /// the router keeps the route through sign-in (`?from=`).
  Future<void> _openLaunchMessage(PushRepository push) async {
    final message = await push.initialMessage();
    if (message == null || !ref.mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await ref.read(authUserProvider.future);
    if (ref.mounted) open(message, coldStart: true);
  }

  /// A banner instead of a system notification, except in that team's
  /// chat, where the message is already on screen (NOTIF-7). The bell
  /// count goes up either way.
  void _onForeground(PushMessage message) {
    ref.invalidate(unreadNotificationCountProvider);
    final path = ref
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    final groupId = message.groupId;
    if (groupId != null && isTeamChatPath(path, groupId)) return;
    ref.read(pushBannerProvider.notifier).show(message);
  }

  /// Best effort: the item is `notifications/{nkey}_{uid}`, and only kinds
  /// listed in the center have one (plain messages don't).
  Future<void> _markRead(PushMessage message) async {
    final nkey = message.nkey;
    final kind = message.kind;
    final uid = ref.read(authUserProvider).value?.uid;
    if (nkey == null || uid == null) return;
    if (kind != null && !(notifyKindInfo[kind]?.center ?? false)) return;
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markRead(notificationIdFor(nkey, UserId(uid)));
      if (ref.mounted) ref.invalidate(unreadNotificationCountProvider);
    } on Object catch (e) {
      Log.warn('Could not mark the notification read', e);
    }
  }
}
