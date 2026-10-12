import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';

/// One notification-center item (`notifications/{nkey}_{uid}`, NOTIF-11).
/// Written only by the server's notify pipeline (ARCH §6.5).
@freezed
abstract class NotificationItem with _$NotificationItem {
  const factory({
    required String id,
    required GroupId groupId,

    /// Null for a kind this build doesn't know yet; it still shows.
    required NotifyKind? kind,

    /// The team name (NOTIF-5).
    required String title,

    /// "Alex replied to you: Sounds good", rendered by the server.
    required String body,

    /// Where a tap goes (NOTIF-6).
    required String route,

    /// Who caused it, so items from people I blocked can be hidden. Null
    /// when the actor is kept private (reports).
    String? actorId,
    @Default(false) bool read,
    DateTime? createdAt,

    /// TTL deletion can lag by a day, so expired items are hidden here too.
    DateTime? expiresAt,
  }) = _NotificationItem;

  const new _();

  /// Shown unless it's expired or from someone I blocked (NOTIF-11).
  bool visibleAt(DateTime now, Set<String> blockedIds) =>
      (expiresAt == null || expiresAt!.isAfter(now)) &&
      !blockedIds.contains(actorId);
}

/// Where the next older page starts. Opaque outside the data layer.
class NotificationCursor {
  const new(this.handle);

  final Object handle;
}

/// A page of notification-center items, newest first.
class NotificationPage {
  const new({required this.items, this.next});

  final List<NotificationItem> items;

  /// Null when this is the last page.
  final NotificationCursor? next;
}

/// The center item ID for a push's [nkey] (ARCH §6.5). Not built with
/// CompositeIds: dedupe keys may contain the separator themselves.
String notificationIdFor(String nkey, UserId uid) =>
    '$nkey$idSeparator${uid.value}';

/// Whether a push or center item may navigate to [route] (NOTIF-6). Only
/// in-app team paths and the center itself, so a bad payload can't send
/// the app anywhere else.
bool isAllowedNotificationRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return false;
  }
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  final segments = uri.pathSegments;
  if (segments.isEmpty) return false;
  return (segments.first == 'g' && segments.length >= 2) ||
      segments.first == 'notifications';
}

/// Whether [path] is [groupId]'s chat (or a message in it), where a push
/// for that team shows no banner (NOTIF-7).
bool isTeamChatPath(String path, String groupId) {
  final s = Uri.tryParse(path)?.pathSegments ?? const [];
  return s.length >= 3 && s[0] == 'g' && s[1] == groupId && s[2] == 'chat';
}

/// Team tabs replace the stack when opened (switching teams, like the
/// switcher); other screens are pushed so Back returns (ARCH §5.4).
bool isTeamTabRoute(String route) {
  final s = Uri.tryParse(route)?.pathSegments ?? const [];
  return s.length >= 3 &&
      s[0] == 'g' &&
      const {'chat', 'schedule', 'docs'}.contains(s[2]);
}
