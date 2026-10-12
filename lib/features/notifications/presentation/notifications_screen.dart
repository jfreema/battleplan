import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
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

/// The notification center (NOTIF-11): activity across all my teams, newest
/// first, 30 at a time. Tapping an item marks it read and opens it.
class NotificationsScreen extends ConsumerStatefulWidget {
  const new({super.key});

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

  Future<void> _loadMore() async {
    if (_loadFailed) setState(() => _loadFailed = false);
    try {
      await ref.read(notificationCenterProvider.notifier).loadMore();
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
      ref
          .read(notificationCenterProvider.notifier)
          .markRead(item)
          .catchError((Object _) {}),
    );
    if (!openNotificationRoute(router, item.route)) {
      showAppSnackBar(context, l10n.notFoundTitle);
    }
  }

  Future<void> _markAll() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(notificationCenterProvider.notifier).markAllRead();
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.notificationSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final center = ref.watch(notificationCenterProvider);
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
              .read(notificationCenterProvider.notifier)
              .markHiddenRead(hiddenUnread)
              .catchError((Object _) {}),
        );
      });
    }
    final anyUnread =
        items.any((n) => !n.read) ||
        (ref.watch(unreadNotificationCountProvider).value ?? 0) >
            hiddenUnread.length;

    Widget body;
    if (center.loading) {
      body = const SkeletonList();
    } else if (items.isEmpty && center.reachedEnd) {
      body = EmptyState(
        icon: AppIcons.notifications,
        message: l10n.notificationsPlaceholder,
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
          return _NotificationRow(
            item: n,
            now: now,
            onTap: () => unawaited(_open(n)),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTooltip),
        actions: [
          if (anyUnread)
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

class _NotificationRow extends StatelessWidget {
  const new({required this.item, required this.now, required this.onTap});

  final NotificationItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = !item.read;
    final at = item.createdAt;
    return Semantics(
      // Read out first, so unread items stand out without the color.
      label: unread ? l10n.unread : null,
      child: ListTile(
        tileColor: unread
            ? scheme.primaryContainer.withValues(alpha: 0.45)
            : null,
        leading: CircleAvatar(
          backgroundColor: unread
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          foregroundColor: unread ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: Icon(notificationIcon(item.kind), size: 20),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: unread ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
        subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: at == null
            ? null
            : Text(
                relativeTime(l10n, at, now),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: unread ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
