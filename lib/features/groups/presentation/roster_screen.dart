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

/// TEAM-3 at `/g/:groupId/roster`: Players, then Admins and Members,
/// searchable by name, each person with their photo or initials. Every team
/// has players, each with who's linked: the member who is the player and
/// their guardians. Admins see pending players and claims at the top with
/// Approve and Decline (PLAYER-4); anyone can add a player (pending until
/// an admin approves, unless they're an admin), and members not linked yet
/// get "Who are you here for?" (PLAYER-3). Tapping a person opens their
/// card with only the actions you're allowed.
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
    final players =
        ref.watch(playersProvider(widget.groupId)).value ?? const <Player>[];
    // Super admins act as the owner here, from the admin panel (ADMIN-3).
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final isAdmin = (me?.isAdmin ?? false) || superAdmin;
    // Pending players: all of them for admins, and the ones I added for
    // everyone else (PLAYER-4).
    final pending =
        (isAdmin
                ? ref.watch(pendingPlayersProvider(widget.groupId))
                : ref.watch(myPendingPlayersProvider(widget.groupId)))
            .value ??
        const <Player>[];
    // Claims sit at the top for admins (PLAYER-4).
    final requests = isAdmin
        ? ref.watch(pendingGuardianRequestsProvider(widget.groupId)).value ??
              const <GuardianRequest>[]
        : const <GuardianRequest>[];
    final myUid = ref.watch(authUserProvider).value?.uid;
    final links =
        ref.watch(guardianLinksProvider(widget.groupId)).value ??
        const <GuardianLink>[];
    final linked = links.any((l) => l.uid.value == myUid);
    final waiting =
        pending.any((p) => p.proposedBy == myUid) ||
        (ref.watch(myGuardianRequestsProvider(widget.groupId)).value ??
                const <GuardianRequest>[])
            .any((r) => r.status == GuardianRequestStatus.pending);
    final canAdd = superAdmin || (me != null && !(group?.isArchived ?? false));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rosterMenu),
        actions: [
          // Anyone can add a player; a member's waits for an admin (PLAYER-4).
          if (canAdd)
            TextButton(
              onPressed: () =>
                  context.push('/g/${widget.groupId.value}/players/add'),
              child: Text(isAdmin ? l10n.addPlayers : l10n.addPlayer),
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
          bool matches(Player p) =>
              q.isEmpty || p.displayName.toLowerCase().contains(q);
          final shownPlayers = players.where(matches).toList();
          String? nameOf(String? uid) =>
              members.where((m) => m.uid.value == uid).firstOrNull?.displayName;
          // A claim from someone no longer on the team isn't shown (TEAM-8):
          // the server drops it when they leave.
          final claims = requests
              .where((r) => members.any((m) => m.uid == r.uid))
              .toList();
          final toDecide = isAdmin ? pending : const <Player>[];
          final mine = isAdmin
              ? const <Player>[]
              : pending.where(matches).toList();
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
              if (toDecide.isNotEmpty || claims.isNotEmpty) ...[
                _Section(title: l10n.playerRequestsTitle),
                for (final p in toDecide)
                  _PendingPlayerRow(player: p, who: nameOf(p.proposedBy)),
                for (final r in claims)
                  _RequestRow(
                    request: r,
                    who: nameOf(r.uid.value),
                    player: players
                        .where((p) => p.id == r.playerId)
                        .firstOrNull
                        ?.label,
                  ),
              ],
              if (!isAdmin && me != null && !linked && !waiting)
                ListTile(
                  leading: const Icon(AppIcons.invite),
                  title: Text(l10n.whoAreYouHereFor),
                  subtitle: Text(l10n.whoAreYouHereForRosterHint),
                  onTap: () => context.push('/g/${widget.groupId.value}/who'),
                ),
              _Section(title: l10n.rosterPlayers),
              if (players.isEmpty && mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.sm,
                  ),
                  child: Text(l10n.adminNoPlayers),
                ),
              // My own players waiting for an admin (PLAYER-4).
              for (final p in mine)
                ListTile(
                  leading: CircleAvatar(child: Text(p.jerseyNumber ?? '')),
                  title: Text(p.displayName),
                  subtitle: Text(l10n.playerPending),
                ),
              for (final p in shownPlayers)
                _PlayerRow(
                  player: p,
                  // TEAM-3: number, name, position, and who's linked.
                  linked: [
                    for (final l in links)
                      if (l.playerId == p.id)
                        if (nameOf(l.uid.value) case final name?)
                          if (l.isSelf) l10n.playerLinkSelfName(name) else name,
                  ],
                ),
              if (admins.isNotEmpty) _Section(title: l10n.rosterAdmins),
              for (final m in admins)
                _MemberRow(
                  member: m,
                  me: me,
                  who: whoLabel(l10n, m.uid, links, players),
                ),
              if (others.isNotEmpty) _Section(title: l10n.rosterMembers),
              for (final m in others)
                _MemberRow(
                  member: m,
                  me: me,
                  who: whoLabel(l10n, m.uid, links, players),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Who's who on the roster (PLAYER-8): "Player #12" for a member who is a
/// player, and "Parent of Emma #7, Liam #23" for a guardian, both when
/// they're both. Null when they aren't linked.
String? whoLabel(
  AppLocalizations l10n,
  UserId uid,
  List<GuardianLink> links,
  List<Player> players,
) {
  Player? playerOf(GuardianLink l) =>
      players.where((p) => p.id == l.playerId).firstOrNull;
  final mine = linksOf(uid, links);
  final self = mine.where((l) => l.isSelf).map(playerOf).nonNulls.firstOrNull;
  final guarded = [
    for (final l in mine)
      if (!l.isSelf) ?playerOf(l)?.label,
  ];
  final parts = [
    if (self?.jerseyNumber case final number? when number.isNotEmpty)
      l10n.rosterPlayerNumber(number)
    else if (self != null)
      l10n.rosterPlayerLabel,
    if (guarded.isNotEmpty) l10n.parentOf(guarded.join(', ')),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// A player: number, name, position, and who's linked (TEAM-3).
class _PlayerRow extends StatelessWidget {
  const new({required this.player, required this.linked});

  final Player player;
  final List<String> linked;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (player.position?.isNotEmpty ?? false) player.position!,
      if (linked.isNotEmpty) linked.join(', '),
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

/// Approve and Decline, with what went wrong said in a snackbar.
class _Decision extends StatelessWidget {
  const new({required this.decide});

  final Future<void> Function({required bool approve}) decide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
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
    );
  }
}

/// Runs an admin's decision on [who]'s request (PLAYER-4), saying what
/// [action] returns, or why it failed. The row is gone once decided, so
/// the snackbar goes through the screen's messenger.
Future<void> _decide(
  BuildContext context,
  Future<String?> Function() action, {
  required String who,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  try {
    if (await action() case final note?) say(note);
  } on AppFailure catch (e) {
    say(decisionFailure(l10n, e, who: who));
  }
}

/// Why an admin's approval failed (PLAYER-3, PLAYER-4): [who] is a player
/// on the team already, someone already is this player, the player's
/// guardians are full, or the roster is.
String decisionFailure(
  AppLocalizations l10n,
  AppFailure e, {
  required String who,
}) => switch (e) {
  InvalidInput(message: 'already-a-player') => l10n.approveAlreadyAPlayer(who),
  InvalidInput(message: 'player-already-claimed') =>
    l10n.approvePlayerAlreadyClaimed,
  InvalidInput(message: 'too-many-guardians') => l10n.claimLimitReached,
  InvalidInput(message: 'too-many-players') => l10n.tooManyPlayers(
    Limits.playersPerGroupMax,
  ),
  _ => l10n.errorGuardianRequest,
};

/// A member's new player waiting for approval: "Emma Rodriguez #7", "Added
/// by Maria Rodriguez as their parent or guardian", with Approve and
/// Decline (PLAYER-4). Declining deletes it.
class _PendingPlayerRow extends ConsumerWidget {
  const new({required this.player, this.who});

  final Player player;
  final String? who;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = who ?? l10n.formerMember;
    return ListTile(
      title: Text(
        player.jerseyNumber?.isNotEmpty ?? false
            ? '${player.displayName} #${player.jerseyNumber}'
            : player.displayName,
      ),
      subtitle: Text(
        player.proposedRelation == PlayerRelation.self
            ? l10n.pendingPlayerSelf(name)
            : l10n.pendingPlayerGuardian(name),
      ),
      trailing: _Decision(
        decide: ({required approve}) => _decide(context, () async {
          final linked = await ref
              .read(playerRepositoryProvider)
              .resolvePendingPlayer(
                player.groupId,
                player.id,
                approve: approve,
              );
          // Added, but its member couldn't be linked to it: say so, so
          // nobody thinks they're on it (PLAYER-4).
          return approve && !linked && player.proposedBy != null
              ? l10n.pendingPlayerNotLinked(player.displayName, name)
              : null;
        }, who: name),
      ),
    );
  }
}

/// A claim: "Maria Rodriguez: parent or guardian of Emma #7", or "Jared
/// Freeman says they're Jared #12", with Approve and Decline (PLAYER-4).
class _RequestRow extends ConsumerWidget {
  const new({required this.request, this.who, this.player});

  final GuardianRequest request;
  final String? who;
  final String? player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(
        request.relation == PlayerRelation.self
            ? l10n.claimSelfFor(who ?? '…', player ?? '…')
            : l10n.claimGuardianFor(who ?? '…', player ?? '…'),
      ),
      trailing: _Decision(
        decide: ({required approve}) => _decide(context, () async {
          await ref
              .read(playerRepositoryProvider)
              .resolvePlayerClaim(
                request.groupId,
                request.playerId,
                request.uid,
                approve: approve,
              );
          return null;
        }, who: who ?? l10n.formerMember),
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
  const new({required this.member, required this.me, this.who});

  final Membership member;
  final Membership? me;

  /// Who's who from their player links ([whoLabel]), for their row and
  /// card (TEAM-3, PLAYER-8).
  final String? who;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = roleBadge(l10n, member.role);
    final details = [
      if (member.title?.isNotEmpty ?? false) member.title!,
      // PLAYER-8: "Player #12", "Parent of Emma #7".
      ?who,
      if (member.pending) l10n.notJoinedYet,
    ];
    return ListTile(
      leading: _MemberAvatar(member: member),
      title: Text(member.displayName),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: badge == null ? null : Chip(label: Text(badge)),
      onTap: () => showAdaptiveSheet<void>(
        context,
        builder: (_) => MemberCard(member: member, me: me, who: who),
      ),
    );
  }
}

/// A person's card (TEAM-3): photo, name, title, role, who's who, and
/// the actions the viewer is allowed (SPEC §3), Report and Block included.
class MemberCard extends ConsumerWidget {
  const new({required this.member, required this.me, this.who, super.key});

  final Membership member;
  final Membership? me;

  /// "Player #12", "Parent of Emma #7" ([whoLabel]), or null.
  final String? who;

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
            e is PermissionDenied ? l10n.notAllowed : l10n.errorMemberAction,
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
            if (who case final label?) ...[
              const SizedBox(height: Space.sm),
              Text(label),
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
