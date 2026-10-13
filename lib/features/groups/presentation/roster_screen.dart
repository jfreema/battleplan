import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// TEAM-3 at `/g/:groupId/roster`: Admins, then Members, searchable by name,
/// each with their photo or initials. Tapping a person opens their card with
/// only the actions you're allowed. Youth teams add a Players section, each
/// player with their guardians; admins see guardian requests at the top
/// (PLAYER-4), and parents not linked yet get "Who are you here for?".
class RosterScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(rosterProvider(widget.groupId));
    final me = ref.watch(myMembershipProvider(widget.groupId));
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final youth = group?.teamType == TeamType.youth;
    final players = youth
        ? ref.watch(playersProvider(widget.groupId)).value ?? const <Player>[]
        : const <Player>[];
    // Super admins act as the owner here, from the admin panel (ADMIN-3).
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final isAdmin = (me?.isAdmin ?? false) || superAdmin;
    // Guardian requests sit at the top for admins (PLAYER-4).
    final requests = youth && isAdmin
        ? ref.watch(pendingGuardianRequestsProvider(widget.groupId)).value ??
              const <GuardianRequest>[]
        : const <GuardianRequest>[];
    final myUid = ref.watch(authUserProvider).value?.uid;
    final links = youth
        ? ref.watch(guardianLinksProvider(widget.groupId)).value ??
              const <GuardianLink>[]
        : const <GuardianLink>[];
    final linked = links.any((l) => l.uid.value == myUid);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rosterMenu),
        actions: [
          if (youth && isAdmin)
            TextButton(
              onPressed: () =>
                  context.push('/g/${widget.groupId.value}/players/add'),
              child: Text(l10n.addPlayers),
            ),
        ],
      ),
      body: roster.when(
        loading: () => const SkeletonList(),
        error: (_, _) => Center(child: Text(l10n.loadError)),
        data: (members) {
          final q = _query.trim().toLowerCase();
          final shown = q.isEmpty
              ? members
              : members
                    .where((m) => m.displayName.toLowerCase().contains(q))
                    .toList();
          final admins = shown.where((m) => m.isAdmin).toList()
            ..sort((a, b) => a.role == MemberRole.owner ? -1 : 0);
          final others = shown.where((m) => !m.isAdmin).toList();
          final shownPlayers = q.isEmpty
              ? players
              : players
                    .where((p) => p.displayName.toLowerCase().contains(q))
                    .toList();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchByName,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (requests.isNotEmpty) ...[
                _Section(title: l10n.guardianRequestsTitle),
                // A request from someone no longer on the team isn't shown
                // (TEAM-8): the server drops it when they leave.
                for (final r in requests.where(
                  (r) => members.any((m) => m.uid == r.uid),
                ))
                  _RequestRow(
                    request: r,
                    who: members
                        .where((m) => m.uid == r.uid)
                        .firstOrNull
                        ?.displayName,
                    player: players
                        .where((p) => p.id == r.playerId)
                        .firstOrNull
                        ?.label,
                  ),
              ],
              if (youth && !isAdmin && !linked && players.isNotEmpty)
                ListTile(
                  leading: const Icon(AppIcons.invite),
                  title: Text(l10n.whoAreYouHereFor),
                  subtitle: Text(l10n.whoAreYouHereForRosterHint),
                  onTap: () => context.push('/g/${widget.groupId.value}/who'),
                ),
              if (youth) ...[
                _Section(title: l10n.rosterPlayers),
                for (final p in shownPlayers)
                  _PlayerRow(
                    player: p,
                    // TEAM-3: number, name, position, and guardians.
                    guardians: [
                      for (final l in links)
                        if (l.playerId == p.id)
                          ?members
                              .where((m) => m.uid == l.uid)
                              .firstOrNull
                              ?.displayName,
                    ],
                  ),
                _Section(title: l10n.rosterParentsStaff),
                for (final m in [...admins, ...others])
                  _MemberRow(
                    member: m,
                    me: me,
                    players: _playersOf(m.uid, links, players),
                  ),
              ] else ...[
                if (admins.isNotEmpty) _Section(title: l10n.rosterAdmins),
                for (final m in admins) _MemberRow(member: m, me: me),
                if (others.isNotEmpty) _Section(title: l10n.rosterMembers),
                for (final m in others) _MemberRow(member: m, me: me),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The players [uid] is a guardian of, as "Emma #7" (TEAM-3).
List<String> _playersOf(
  UserId uid,
  List<GuardianLink> links,
  List<Player> players,
) => [
  for (final l in links)
    if (l.uid == uid)
      ?players.where((p) => p.id == l.playerId).firstOrNull?.label,
];

/// A player: number, name, position, and guardians (TEAM-3).
class _PlayerRow extends StatelessWidget {
  const new({required this.player, required this.guardians});

  final Player player;
  final List<String> guardians;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (player.position?.isNotEmpty ?? false) player.position!,
      if (guardians.isNotEmpty) guardians.join(', '),
    ];
    return ListTile(
      leading: CircleAvatar(child: Text(player.jerseyNumber ?? '')),
      title: Text(player.displayName),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      onTap: () => context.push(
        '/g/${player.groupId.value}/roster/players/${player.id.value}',
      ),
    );
  }
}

/// A member's photo, or initials when they have none (TEAM-3).
class _MemberAvatar extends ConsumerWidget {
  const new({required this.member, this.size = 40});

  final Membership member;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = member.photoPath;
    final url = path == null
        ? null
        : ref.watch(teamPhotoUrlProvider(path)).value;
    return Avatar(
      name: member.displayName,
      colorKey: member.uid.value,
      imageUrl: url,
      size: size,
    );
  }
}

/// "Maria Rodriguez for Emma #7" with Approve and Decline (PLAYER-4).
class _RequestRow extends ConsumerWidget {
  const new({required this.request, this.who, this.player});

  final GuardianRequest request;
  final String? who;
  final String? player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> decide({required bool approve}) async {
      try {
        await ref
            .read(playerRepositoryProvider)
            .resolveGuardianRequest(
              request.groupId,
              request.playerId,
              request.uid,
              approve: approve,
            );
      } on AppFailure {
        if (context.mounted) showAppSnackBar(context, l10n.signInUnknownError);
      }
    }

    return ListTile(
      title: Text(l10n.guardianRequestFor(who ?? '…', player ?? '…')),
      trailing: Wrap(
        children: [
          TextButton(
            onPressed: () => unawaited(decide(approve: false)),
            child: Text(l10n.decline),
          ),
          FilledButton(
            onPressed: () => unawaited(decide(approve: true)),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.xs),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Role badge text: Owner or Admin.
String? roleBadge(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.owner => l10n.roleOwner,
  MemberRole.admin => l10n.roleAdmin,
  MemberRole.member => null,
};

class _MemberRow extends StatelessWidget {
  const new({required this.member, required this.me, this.players = const []});

  final Membership member;
  final Membership? me;

  /// The players they're a guardian of, for their card (TEAM-3).
  final List<String> players;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = roleBadge(l10n, member.role);
    final details = [
      if (member.title?.isNotEmpty ?? false) member.title!,
      // PLAYER-8: "Parent of Emma #7".
      if (member.playerSummary?.isNotEmpty ?? false)
        l10n.parentOf(member.playerSummary!),
      if (member.pending) l10n.notJoinedYet,
    ];
    return ListTile(
      leading: _MemberAvatar(member: member),
      title: Text(member.displayName),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: badge == null ? null : Chip(label: Text(badge)),
      onTap: () => showAdaptiveSheet<void>(
        context,
        builder: (_) => MemberCard(member: member, me: me, players: players),
      ),
    );
  }
}

/// A person's card (TEAM-3): photo, name, title, role, their players, and
/// the actions the viewer is allowed (SPEC §3), Report and Block included.
class MemberCard extends ConsumerWidget {
  const new({
    required this.member,
    required this.me,
    this.players = const [],
    super.key,
  });

  final Membership member;
  final Membership? me;

  /// The players they're a guardian of, "Emma #7" (youth teams).
  final List<String> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(memberRepositoryProvider);
    final viewer = me;
    final isSelf = viewer?.uid == member.uid;
    // A super admin can do what the owner can (SPEC §3).
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final viewerIsOwner = viewer?.role == MemberRole.owner || superAdmin;
    final viewerIsAdmin = (viewer?.isAdmin ?? false) || superAdmin;
    final targetIsOwner = member.role == MemberRole.owner;
    final targetIsAdmin = member.role == MemberRole.admin;

    final canPromote = viewerIsAdmin && member.role == MemberRole.member;
    final canDemote = viewerIsOwner && targetIsAdmin;
    final canEditTitle = viewerIsAdmin;
    final canRemove =
        !isSelf &&
        !targetIsOwner &&
        (viewerIsOwner || (viewerIsAdmin && !targetIsAdmin));

    Future<void> run(Future<void> Function() action, String done) async {
      Navigator.of(context).pop();
      try {
        await action();
        if (context.mounted) showAppSnackBar(context, done);
      } on AppFailure catch (e) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            e is PermissionDenied ? l10n.notAllowed : l10n.signInUnknownError,
          );
        }
      }
    }

    final badge = roleBadge(l10n, member.role);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MemberAvatar(member: member, size: 72),
            const SizedBox(height: Space.md),
            Text(
              member.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (member.title?.isNotEmpty ?? false) Text(member.title!),
            if (badge != null) ...[
              const SizedBox(height: Space.sm),
              Chip(label: Text(badge)),
            ],
            if (players.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(l10n.parentOf(players.join(', '))),
            ],
            const SizedBox(height: Space.lg),
            if (canPromote)
              ListTile(
                title: Text(l10n.makeAdmin),
                onTap: () => run(
                  () => repo.updateMember(
                    member.groupId,
                    member.uid,
                    role: MemberRole.admin,
                  ),
                  l10n.madeAdminDone(member.displayName),
                ),
              ),
            if (canDemote)
              ListTile(
                title: Text(l10n.removeAdmin),
                onTap: () => run(
                  () => repo.updateMember(
                    member.groupId,
                    member.uid,
                    role: MemberRole.member,
                  ),
                  l10n.removedAdminDone(member.displayName),
                ),
              ),
            if (canEditTitle)
              ListTile(
                title: Text(l10n.editTitle),
                onTap: () async {
                  final title = await askText(
                    context,
                    title: l10n.editTitle,
                    label: l10n.titleLabel,
                    helper: l10n.titleHelp,
                  );
                  if (title == null || !context.mounted) return;
                  await run(
                    () => repo.updateMember(
                      member.groupId,
                      member.uid,
                      title: title.trim(),
                      clearTitle: title.trim().isEmpty,
                    ),
                    l10n.profileSaved,
                  );
                },
              ),
            if (viewerIsAdmin && member.pending)
              ListTile(
                title: Text(l10n.resendSetupEmail),
                onTap: () => run(
                  () => repo.resendSetupEmail(member.groupId, member.uid),
                  l10n.setupEmailSent,
                ),
              ),
            if (canRemove)
              ListTile(
                title: Text(
                  l10n.removeFromTeam,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: l10n.removeFromTeamTitle(member.displayName),
                    confirmLabel: l10n.removeFromTeam,
                    cancelLabel: l10n.cancel,
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  unawaited(
                    run(
                      () => repo.removeMember(member.groupId, member.uid),
                      l10n.removedDone(member.displayName),
                    ),
                  );
                },
              ),
            // Report or block someone else (SAFE-1, SAFE-2).
            if (me != null && member.uid != me!.uid) ...[
              ListTile(
                title: Text(l10n.reportMessage),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    showReportSheet(
                      context,
                      ref,
                      groupId: member.groupId,
                      targetType: ReportTargetType.user,
                      targetId: member.uid.value,
                    ),
                  );
                },
              ),
              if (ref.watch(blockedIdsProvider).contains(member.uid.value))
                ListTile(
                  title: Text(l10n.unblock),
                  onTap: () => unawaited(unblock(context, ref, member.uid)),
                )
              else
                ListTile(
                  title: Text(l10n.blockPerson(member.displayName)),
                  onTap: () => unawaited(
                    confirmBlock(
                      context,
                      ref,
                      uid: member.uid,
                      name: member.displayName,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
