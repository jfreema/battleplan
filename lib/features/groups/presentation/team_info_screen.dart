import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Team info at `/g/:groupId/info` (SPEC §5.2), from the ⓘ in the team's
/// header: the team, then Roster, Invite, Notifications, and Calendar
/// link, and for the team's admins and super admins Team admin, Media,
/// Reports, and Import. A super admin viewing a team they're not on
/// (ADMIN-3) gets the roster, invite, and admin rows only.
class TeamInfoScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final viewing = ref.watch(viewingAsSuperAdminProvider(groupId));
    final admin =
        (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;

    SettingsRow row(String route, IconData icon, String title) => SettingsRow(
      icon: icon,
      title: title,
      onTap: () => unawaited(context.push('/g/${groupId.value}/$route')),
    );

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: group?.isGroup ?? false ? l10n.groupInfo : l10n.teamInfo,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
            children: [
              if (group != null) ...[
                SettingsPanel(
                  child: Row(
                    children: [
                      GroupBadge(group: group, size: 56),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CardHeading(group.name),
                            Text(
                              [
                                // A basic group has no sport (TEAM-14).
                                if (group.hasPlayers)
                                  sportName(l10n, group.sport)
                                else
                                  l10n.kindGroup,
                                l10n.membersCount(group.memberCount),
                              ].join(' · '),
                              style: text.bodyMedium?.copyWith(
                                color: c.card.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SettingsCard(
                children: [
                  row(
                    'roster',
                    AppIcons.roster,
                    group?.hasPlayers ?? true
                        ? l10n.rosterMenu
                        : l10n.groupPeople,
                  ),
                  row('invite', AppIcons.invite, l10n.inviteMenu),
                  if (!viewing) ...[
                    row(
                      'notifications',
                      AppIcons.notifications,
                      l10n.teamNotificationsMenu,
                    ),
                    // The schedule in your own calendar, kept in sync
                    // (SCHED-11).
                    row(
                      'calendar',
                      AppIcons.calendarLink,
                      l10n.calendarLinkMenu,
                    ),
                  ],
                  // Leave team is on your own card in the roster, out of the
                  // way of a stray tap (TEAM-8).
                ],
              ),
              if (admin) ...[
                const SizedBox(height: 12),
                PageHeading(l10n.teamAdminHeading),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    row(
                      'settings',
                      AppIcons.settings,
                      group?.isGroup ?? false
                          ? l10n.groupAdmin
                          : l10n.teamAdmin,
                    ),
                    row('media', AppIcons.media, l10n.mediaMenu),
                    row('reports', AppIcons.report, l10n.reportsMenu),
                    // Bringing the schedule over from another app (SPEC
                    // §6.15).
                    row('import', AppIcons.download, l10n.importMenu),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
