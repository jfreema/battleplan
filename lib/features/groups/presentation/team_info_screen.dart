import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/color_scheme_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/team_card.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Team settings at `/g/:groupId/info` (SPEC §5.1), from the gear in the
/// team's header (it was Team info, from an ⓘ, until the owner's request
/// of 2026-11-10): the team's card, then **Just for you**, what only
/// changes the app for me (Notifications for this team, Color scheme, and
/// Calendar link), and for the team's admins and super admins **For
/// admins**: Admin settings, Media, Reports, and Import. The roster,
/// Invite, and Dues are on the Team tab (SPEC §5.3). A super admin viewing
/// a team they're not on (ADMIN-3) gets the admin rows only.
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
    final isGroup = group?.isGroup ?? false;

    SettingsRow row(String route, IconData icon, String title) => SettingsRow(
      icon: icon,
      title: title,
      onTap: () => unawaited(context.push('/g/${groupId.value}/$route')),
    );

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: isGroup ? l10n.groupSettings : l10n.teamSettings,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              14,
              Space.page,
              Space.xl,
            ),
            children: [
              // Which team these are for.
              if (group != null) ...[
                TeamCard(group: group),
                const SizedBox(height: 12),
              ],
              // Only how the app works for me on this team; nothing here
              // changes it for anyone else.
              if (!viewing) ...[
                PageHeading(l10n.justForYouHeading),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    row(
                      'notifications',
                      AppIcons.notifications,
                      l10n.teamNotificationsMenu,
                    ),
                    // How I see this team (SET-2): my own pick, else the
                    // team's default.
                    SettingsRow(
                      icon: AppIcons.colorScheme,
                      title: l10n.colorScheme,
                      subtitle:
                          ref
                              .watch(myMembershipProvider(groupId))
                              ?.colorScheme
                              ?.label(l10n) ??
                          schemeDefaultLabel(
                            l10n,
                            isGroup: isGroup,
                            teamDefault: group?.colorScheme,
                            mine: ref.watch(defaultSchemeControllerProvider),
                          ),
                      onTap: () =>
                          unawaited(context.push('/g/${groupId.value}/scheme')),
                    ),
                    // The schedule in your own calendar, kept in sync
                    // (SCHED-11).
                    row(
                      'calendar',
                      AppIcons.calendarLink,
                      l10n.calendarLinkMenu,
                    ),
                    // Leave team is on your own card on the Team tab, out
                    // of the way of a stray tap (TEAM-8).
                  ],
                ),
              ],
              if (admin) ...[
                if (!viewing) const SizedBox(height: 12),
                PageHeading(l10n.teamAdminHeading),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    // The team's own settings, for its admins (TEAM-5):
                    // the sliders, as the gear is this page's.
                    row(
                      'settings',
                      AppIcons.tune,
                      isGroup ? l10n.groupAdmin : l10n.teamAdmin,
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
