import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/notifications/application/notification_center.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/presentation/notification_labels.dart';
import 'package:battleplan/features/notifications/presentation/open_route.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The notification center (NOTIF-11): activity across all my teams,
/// newest first, 30 at a time, each item under its team's name; or, opened
/// from a team's bell, only [groupId]'s, without the name on every row.
/// Tapping an item marks it read and opens it.
class NotificationsScreen extends ConsumerStatefulWidget {
  const new({this.groupId, super.key});

  /// The team whose bell opened it, or null for every team (Teams' bell).
  final GroupId? groupId;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  /// Set when loading older items fails, so the check after each frame
  /// doesn't retry in a loop. Retry at the end of the list tries again.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_loadFailed) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 400) unawaited(_loadMore());
  }

  NotificationCenterProvider get _center =>
      notificationCenterProvider(groupId: widget.groupId);

  Future<void> _loadMore() async {
    if (_loadFailed) setState(() => _loadFailed = false);
    try {
      await ref.read(_center.notifier).loadMore();
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _open(NotificationItem item) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    // Opening shouldn't wait on the network; a failed mark only leaves the
    // item highlighted.
    unawaited(
      ref.read(_center.notifier).markRead(item).catchError((Object _) {}),
    );
    if (!openNotificationRoute(router, item.route)) {
      showAppSnackBar(context, l10n.notFoundTitle);
    }
  }

  Future<void> _markAll() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(_center.notifier).markAllRead();
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.notificationSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupId = widget.groupId;
    final center = ref.watch(_center);
    final blocked = ref.watch(blockedIdsProvider);
    final now = DateTime.now();
    final items = [
      for (final n in center.items)
        if (n.visibleAt(now, blocked)) n,
    ];
    // Hidden unread items (blocked people, expired) are marked read so the
    // bell matches the list; Mark all as read also covers unread items not
    // loaded yet, so it follows the bell as well as the list.
    final hiddenUnread = [
      for (final n in center.items)
        if (!n.read && !n.visibleAt(now, blocked)) n,
    ];
    if (hiddenUnread.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(_center.notifier)
              .markHiddenRead(hiddenUnread)
              .catchError((Object _) {}),
        );
      });
    }
    final anyUnread =
        items.any((n) => !n.read) ||
        (ref.watch(unreadNotificationCountProvider(groupId: groupId)).value ??
                0) >
            hiddenUnread.length;

    Widget body;
    if (center.loading) {
      body = const SkeletonList();
    } else if (items.isEmpty && center.reachedEnd) {
      final isGroup =
          groupId != null &&
          (ref.watch(groupProvider(groupId)).value?.isGroup ?? false);
      body = EmptyState(
        icon: AppIcons.notifications,
        message: groupId == null
            ? l10n.notificationsPlaceholder
            : isGroup
            ? l10n.groupNotificationsPlaceholder
            : l10n.teamNotificationsPlaceholder,
      );
    } else {
      // A short list can't scroll, so check after layout too. That includes
      // a page whose items are all hidden (blocked or expired): older ones
      // may still show.
      if (!center.reachedEnd && !_loadFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _maybeLoadMore();
        });
      }
      body = ListView.builder(
        controller: _scroll,
        itemCount: items.length + (center.reachedEnd ? 0 : 1),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Center(
                child: _loadFailed
                    ? TextButton(
                        onPressed: () => unawaited(_loadMore()),
                        child: Text(l10n.retry),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          final n = items[i];
          // Plain rows on the page between hairlines (SPEC §7.3).
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: PageListRow(
              index: i,
              child: _NotificationRow(
                item: n,
                now: now,
                showTeam: groupId == null,
                onTap: () => unawaited(_open(n)),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: upButton(context),
        title: Text(l10n.notificationsTooltip),
        actions: [
          // On a phone or with large text, the icon with its name as a
          // tooltip, so the title still fits beside it.
          if (anyUnread &&
              (MediaQuery.sizeOf(context).width < 600 ||
                  MediaQuery.textScalerOf(context).scale(10) > 15))
            IconButton(
              tooltip: l10n.markAllRead,
              onPressed: () => unawaited(_markAll()),
              icon: const Icon(AppIcons.markAllRead),
            )
          else if (anyUnread)
            TextButton.icon(
              onPressed: () => unawaited(_markAll()),
              icon: const Icon(AppIcons.markAllRead),
              label: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: body,
    );
  }
}

/// One notification: its kind's icon on a disc, coral while unread, the
/// title, its team's name (bolder while unread), the body, and when. In one
/// team's list the team is the same on every row, so the body takes the
/// title's place. No colored wash, so every text reads on the page in every
/// scheme.
class _NotificationRow extends StatelessWidget {
  const new({
    required this.item,
    required this.now,
    required this.showTeam,
    required this.onTap,
  });

  final NotificationItem item;
  final DateTime now;

  /// The team's name over the body (every team's list).
  final bool showTeam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final unread = !item.read;
    final at = item.createdAt;
    return Semantics(
      // Read out first, so unread items stand out without the color.
      label: unread ? l10n.unread : null,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: unread ? c.you.face : c.well,
          foregroundColor: unread ? c.ink : c.textOnPage,
          child: Icon(notificationIcon(item.kind), size: 20),
        ),
        title: Text(
          showTeam ? item.title : item.body,
          maxLines: showTeam ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        subtitle: showTeam
            ? Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textMutedOnPage),
              )
            : null,
        trailing: at == null
            ? null
            : Text(
                relativeTime(l10n, at, now, zone: ViewerZone.of(context)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: unread ? c.you.text : c.textMutedOnPage,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
