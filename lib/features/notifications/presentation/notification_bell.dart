import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The bell with the unread count, 1 to 99+ (NOTIF-11). On Teams it counts
/// and opens every team's notifications; in a team's header, only
/// [groupId]'s (owner's request 2026-11-10). The count is a one-time query,
/// refreshed when the app comes back to the front, on every foreground
/// push, and after marking read.
class NotificationBell extends ConsumerStatefulWidget {
  const new({this.groupId, super.key});

  /// The team whose header it's in, or null on Teams.
  final GroupId? groupId;

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(unreadNotificationCountProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupId = widget.groupId;
    final count =
        ref.watch(unreadNotificationCountProvider(groupId: groupId)).value ?? 0;
    // A 48 px header icon button (SPEC §7.3).
    return GumdropIconButton(
      tooltip: l10n.notificationsTooltip,
      icon: AppIcons.notifications,
      badgeLabel: count > 0 ? unreadLabel(count) : null,
      onPressed: () async {
        await context.push<void>(
          groupId == null ? '/notifications' : '/g/${groupId.value}/activity',
        );
        // Items read in the center lower the count.
        if (mounted) ref.invalidate(unreadNotificationCountProvider);
      },
    );
  }
}
