import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';

/// Owns `notifications` (ARCH §5.2): the notification center across all of
/// a person's teams (NOTIF-11). The server writes items; the app only marks
/// them read, which rules allow and nothing else.
abstract interface class NotificationRepository {
  /// My newest [limit] items, newest first, kept live. Listen only while the
  /// center is open (ARCH §10.2).
  Stream<NotificationPage> watchNewest(
    UserId uid, {
    int limit = Limits.notificationPageSize,
  });

  /// The [limit] items older than [after], newest first.
  Future<NotificationPage> loadOlder(
    UserId uid,
    NotificationCursor after, {
    int limit = Limits.notificationPageSize,
  });

  /// My unread items, counted up to [cap] for the bell badge.
  Future<int> countUnread(UserId uid, {int cap = Limits.unreadCountCap});

  /// Marks one item read. Read state syncs across devices.
  Future<void> markRead(String id);

  /// Marks every unread item read ("Mark all as read").
  Future<void> markAllRead(UserId uid);
}
