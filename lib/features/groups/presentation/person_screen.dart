import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/roster_screen.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// One of the person's teams as their page shows it: the team, my
/// membership of it, and theirs.
typedef SharedTeam = ({MyTeam team, Membership theirs});

/// The teams a person page lists (TEAM-15): teams I'm on that they're on
/// too. Teams stay walled off (TEAM-2), so teams I'm not on never show, and
/// a team that keeps its people to its admins (TEAM-3) shows only when
/// they coach it, I'm one of its admins, or I came from it ([fromTeam]),
/// where I've already seen them. On my own page, all my teams.
List<SharedTeam> sharedTeamsOf(
  List<MyTeam> mine,
  Membership? Function(MyTeam team) theirsOn, {
  required bool isMe,
  GroupId? fromTeam,
}) => [
  for (final t in mine)
    if (theirsOn(t) case final theirs?)
      if (isMe ||
          t.group.settings.membersCanSeePeople ||
          // Nobody coaches a basic group (TEAM-14).
          (t.group.hasPlayers && theirs.isCoach) ||
          t.membership.isAdmin ||
          t.group.id == fromTeam)
        (team: t, theirs: theirs),
];

/// What someone is on one team (TEAM-15): Coach, Owner or Admin, their
/// title, and who's who from their players (PLAYER-8), or Member.
String roleLineOf(
  AppLocalizations l10n,
  Membership m, {
  bool hasPlayers = true,
}) {
  final parts = [
    // Nobody coaches a basic group (TEAM-14).
    if (hasPlayers && m.isCoach) l10n.memberCoach,
    ?roleBadge(l10n, m.role),
    if (m.title?.trim().isNotEmpty ?? false) m.title!.trim(),
    ?whoFromSummary(l10n, m.playerSummary),
    if (m.pending) l10n.notJoinedYet,
  ];
  return parts.isEmpty ? l10n.personRoleMember : parts.join(' · ');
}

/// "Player #12", "Parent of Emma #7", or both, from a membership's player
/// summary ("#12, Emma #7"), as the roster says it (PLAYER-8).
String? whoFromSummary(AppLocalizations l10n, String? summary) {
  final s = summary?.trim() ?? '';
  if (s.isEmpty) return null;
  if (!s.startsWith('#')) return l10n.parentOf(s);
  final comma = s.indexOf(', ');
  final number = (comma < 0 ? s : s.substring(0, comma)).substring(1).trim();
  final own = number.isEmpty
      ? l10n.rosterPlayerLabel
      : l10n.rosterPlayerNumber(number);
  return comma < 0 ? own : '$own · ${l10n.parentOf(s.substring(comma + 2))}';
}

/// A person's page (TEAM-15), opened from their photo or name in a chat,
/// the roster, or a conversation: their photo and name, Message (CHAT-19),
/// and the teams we share with what they are on each (Coach first). Block,
/// unblock, and report are in its menu. My own page lists all my teams,
/// with Edit profile.
class PersonScreen extends ConsumerWidget {
  const new({required this.uid, this.fromTeam, super.key});

  final UserId uid;

  /// The team it was opened from, if any.
  final GroupId? fromTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authUserProvider).value?.uid;
    final isMe = me == uid.value;
    final teams = ref.watch(myTeamsProvider);
    final mine = teams.value ?? const <MyTeam>[];
    Membership? theirsOn(MyTeam t) =>
        isMe ? t.membership : ref.watch(memberProvider(t.group.id, uid)).value;
    final shared = sharedTeamsOf(
      mine,
      theirsOn,
      isMe: isMe,
      fromTeam: fromTeam,
    );
    // Coaches first, then the rest as the switcher orders them.
    final rows = [
      ...shared.where((s) => s.team.group.hasPlayers && s.theirs.isCoach),
      ...shared.where((s) => !(s.team.group.hasPlayers && s.theirs.isCoach)),
    ];

    // Their name and photo: from any team we share, else from a
    // conversation with them (CHAT-19), whose people the server keeps.
    final anyMembership = [for (final t in mine) ?theirsOn(t)].firstOrNull;
    final conversation = ref
        .watch(myDirectMembershipsProvider)
        .value
        ?.where((m) => m.otherUid == uid.value)
        .firstOrNull;
    final person = conversation == null
        ? null
        : ref
              .watch(groupProvider(conversation.groupId))
              .value
              ?.people[uid.value];
    final profile = isMe ? ref.watch(myProfileProvider).value : null;
    final name = isMe
        ? (profile?.displayName ?? '')
        : anyMembership?.displayName ?? person?.name ?? '';
    final photoPath = isMe
        ? profile?.photoPath
        : anyMembership?.photoPath ?? person?.photoPath;
    final photoUrl = isMe
        ? ref.watch(myPhotoUrlProvider).value
        : photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(photoPath)).value;
    // Added by an admin and not signed in yet (AUTH-6): nobody to message.
    final notJoined =
        !isMe && rows.isNotEmpty && rows.every((r) => r.theirs.pending);
    final blocked = ref.watch(blockedIdsProvider).contains(uid.value);
    final unknown = !isMe && name.isEmpty && !teams.isLoading;

    // Report needs a team we share: the one I came from, else the first.
    final reportTeam = rows
        .map((r) => r.team.group.id)
        .where((id) => id == fromTeam)
        .followedBy(rows.map((r) => r.team.group.id))
        .firstOrNull;

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.personTitle,
        actions: [
          if (!isMe && !unknown)
            PopupMenuButton<String>(
              tooltip: l10n.directMenuTooltip,
              icon: const Icon(AppIcons.menu),
              onSelected: (action) => unawaited(switch (action) {
                'block' => confirmBlock(context, ref, uid: uid, name: name),
                'unblock' => unblock(context, ref, uid),
                'report' when reportTeam != null => showReportSheet(
                  context,
                  ref,
                  groupId: reportTeam,
                  targetType: ReportTargetType.user,
                  targetId: uid.value,
                ),
                _ => Future<void>.value(),
              }),
              itemBuilder: (_) => [
                if (blocked)
                  PopupMenuItem(value: 'unblock', child: Text(l10n.unblock))
                else
                  PopupMenuItem(
                    value: 'block',
                    child: Text(l10n.blockPerson(name)),
                  ),
                if (reportTeam != null)
                  PopupMenuItem(
                    value: 'report',
                    child: Text(l10n.reportMessage),
                  ),
              ],
            ),
        ],
      ),
      body: unknown
          ? EmptyState(icon: AppIcons.person, message: l10n.personNotFound)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: Space.xl),
              children: [
                Center(
                  child: Avatar(
                    name: name,
                    colorKey: uid.value,
                    imageUrl: photoUrl,
                    size: 96,
                  ),
                ),
                const SizedBox(height: Space.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (notJoined)
                  Text(
                    l10n.notJoinedYet,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GumdropColors.of(context).textMutedOnPage,
                    ),
                  ),
                const SizedBox(height: Space.lg),
                Center(
                  child: isMe
                      ? OutlinedButton.icon(
                          onPressed: () =>
                              unawaited(context.push('/settings/profile')),
                          icon: const Icon(AppIcons.edit),
                          label: Text(l10n.personEditProfile),
                        )
                      : blocked
                      ? OutlinedButton(
                          onPressed: () =>
                              unawaited(unblock(context, ref, uid)),
                          child: Text(l10n.unblock),
                        )
                      : notJoined
                      ? const SizedBox.shrink()
                      : MessageButton(uid: uid, name: name),
                ),
                const SizedBox(height: Space.xl),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: PageHeading(
                    isMe ? l10n.personMyTeams : l10n.personTeamsInCommon,
                  ),
                ),
                if (rows.isEmpty && !teams.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Text(
                      l10n.personNoTeams,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GumdropColors.of(context).textMutedOnPage,
                      ),
                    ),
                  )
                else if (rows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SettingsCard(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final row in rows)
                          ListTile(
                            leading: GroupBadge(
                              group: row.team.group,
                              size: 40,
                            ),
                            title: Text(row.team.group.name),
                            subtitle: Text(
                              roleLineOf(
                                l10n,
                                row.theirs,
                                hasPlayers: row.team.group.hasPlayers,
                              ),
                            ),
                            // Their card on that team: its contact info and
                            // the actions I have there (TEAM-3, TEAM-10).
                            onTap: () => unawaited(
                              showAdaptiveSheet<void>(
                                context,
                                builder: (_) => MemberCard(
                                  member: row.theirs,
                                  me: row.team.membership,
                                  who: whoFromSummary(
                                    l10n,
                                    row.theirs.playerSummary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
