import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/notifications/presentation/notification_labels.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Notifications for this team" (NOTIF-3): the push level, and muting for
/// a while or until unmuted. Both live on my membership, so they sync to my
/// other devices, and they control pushes only: the bell and unread counts
/// still show everything.
class TeamNotificationsScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(myMembershipProvider(groupId));
    final group = ref.watch(groupProvider(groupId)).value;
    final now = DateTime.now();

    if (membership == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.teamNotificationsMenu)),
        body: EmptyState(icon: AppIcons.group, message: l10n.notAMember),
      );
    }

    Future<void> save(
      Future<void> Function(MemberRepository repo, UserId uid) write,
    ) async {
      try {
        await write(ref.read(memberRepositoryProvider), membership.uid);
      } on Object {
        if (context.mounted) {
          showAppSnackBar(context, l10n.notificationSaveFailed);
        }
      }
    }

    void setLevel(NotificationLevel? level) {
      if (level == null || level == membership.notificationLevel) return;
      unawaited(
        save((repo, uid) => repo.setNotificationLevel(groupId, uid, level)),
      );
    }

    void mute(Duration? length) {
      final until = length == null
          ? DateTime.fromMillisecondsSinceEpoch(
              Limits.mutedForeverMs,
              isUtc: true,
            )
          : DateTime.now().add(length);
      unawaited(save((repo, uid) => repo.setMutedUntil(groupId, uid, until)));
    }

    // The mute choices (NOTIF-3). Null is until unmuted.
    final muteChoices = <(Duration?, String)>[
      (const Duration(hours: 1), l10n.muteFor1Hour),
      (const Duration(hours: 8), l10n.muteFor8Hours),
      (const Duration(days: 7), l10n.muteFor1Week),
      (null, l10n.muteUntilUnmuted),
    ];

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.sm,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );

    final muted = muteLabel(l10n, membership, now);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamNotificationsMenu),
        bottom: group == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(Space.xl),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(group.name),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xl),
        children: [
          section(l10n.pushLevelSection),
          RadioGroup<NotificationLevel>(
            groupValue: membership.notificationLevel,
            onChanged: setLevel,
            child: Column(
              children: [
                for (final level in NotificationLevel.values)
                  RadioListTile<NotificationLevel>(
                    value: level,
                    title: Text(notificationLevelLabel(l10n, level)),
                    subtitle: Text(notificationLevelHelp(l10n, level)),
                  ),
              ],
            ),
          ),
          section(l10n.muteSection),
          ListTile(
            leading: Icon(
              muted == null ? AppIcons.notificationsOn : AppIcons.muted,
            ),
            title: Text(muted ?? l10n.notMuted),
            subtitle: Text(l10n.muteHelp),
          ),
          if (muted != null)
            ListTile(
              leading: const Icon(AppIcons.notifications),
              title: Text(l10n.unmute),
              onTap: () => unawaited(
                save((repo, uid) => repo.setMutedUntil(groupId, uid, null)),
              ),
            ),
          for (final (length, label) in muteChoices)
            ListTile(
              leading: const SizedBox(width: Space.xl),
              title: Text(label),
              onTap: () => mute(length),
            ),
        ],
      ),
    );
  }
}
