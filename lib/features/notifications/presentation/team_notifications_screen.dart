import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/groups.dart';
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

    // Opened from Team settings, as usual; Settings' Notifications says so
    // when it's the opener (#14).
    final back = backLabelFrom(
      context,
      (group?.isGroup ?? false) ? l10n.groupSettings : l10n.teamSettings,
    );
    if (membership == null) {
      return GumdropScaffold(
        maxWidth: 560,
        title: l10n.teamNotificationsMenu,
        backLabel: back,
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

    final muted = muteLabel(
      l10n,
      membership,
      now,
      zone: ViewerZone.of(context),
    );
    const headingGap = SizedBox(height: 10);
    const gap = SizedBox(height: 12);
    // The app's frame and Team settings' rows (#14, 2026-11-16; it had a
    // plain bar with the team's name under it).
    return GumdropScaffold(
      maxWidth: 560,
      title: l10n.teamNotificationsMenu,
      backLabel: back,
      body: PageList(
        children: [
          // Which team, as the title is the same for every team.
          if (group != null) ...[
            Text(group.name, style: Theme.of(context).textTheme.titleMedium),
            gap,
          ],
          PageHeading(l10n.pushLevelSection),
          headingGap,
          RadioGroup<NotificationLevel>(
            groupValue: membership.notificationLevel,
            onChanged: setLevel,
            child: SettingsCard(
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
          gap,
          PageHeading(l10n.muteSection),
          headingGap,
          SettingsCard(
            children: [
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
        ],
      ),
    );
  }
}
