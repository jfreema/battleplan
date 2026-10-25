import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/chat/chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/leave_team.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
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
/// get "Who are you here for?" (PLAYER-3). The team's admins see "Age 12"
/// on each player with a date of birth (PLAYER-12). Players are listed by
/// jersey number or by name (TEAM-10), people by name with the owner
/// first. Tapping a person opens their card with only the actions you're
/// allowed, and the phone and email they share with the team (TEAM-10).
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
    // Not on an archived team, which is read-only for everyone (TEAM-9).
    final canAdd = (superAdmin || me != null) && !(group?.isArchived ?? false);
    // Ages for the team's admins and super admins, from one list of the
    // team's player details (PLAYER-12); nobody else's app asks for it.
    final details = isAdmin
        ? ref.watch(teamPlayerDetailsProvider(widget.groupId)).value ??
              const <PlayerId, PlayerDetails>{}
        : const <PlayerId, PlayerDetails>{};
    final today = DateTime.now();
    final order = ref.watch(rosterViewProvider);
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.rosterMenu,
        actions: [
          // By number or by name (TEAM-10).
          PopupMenuButton<RosterOrder>(
            tooltip: l10n.sortRoster,
            icon: const Icon(AppIcons.sort),
            initialValue: order,
            onSelected: (o) => ref.read(rosterViewProvider.notifier).order = o,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: RosterOrder.number,
                checked: order == RosterOrder.number,
                child: Text(l10n.sortByNumber),
              ),
              CheckedPopupMenuItem(
                value: RosterOrder.name,
                checked: order == RosterOrder.name,
                child: Text(l10n.sortByName),
              ),
            ],
          ),
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
          // By name (the roster comes that way), the owner first. Coaches
          // have their own section (TEAM-3), their role on its chip.
          final coaches = [
            ...shown.where((m) => m.isCoach && m.role == MemberRole.owner),
            ...shown.where((m) => m.isCoach && m.role != MemberRole.owner),
          ];
          final admins = [
            ...shown.where((m) => !m.isCoach && m.role == MemberRole.owner),
            ...shown.where((m) => !m.isCoach && m.role == MemberRole.admin),
          ];
          final others = shown.where((m) => !m.isAdmin && !m.isCoach).toList();
          // A team can keep its people to its admins (TEAM-3): members
          // still see the players, the coaches, and their own card, which
          // has Leave team.
          final seePeople =
              isAdmin || (group?.settings.membersCanSeePeople ?? true);
          if (!seePeople) {
            admins.removeWhere((m) => m.uid != me?.uid);
            others.removeWhere((m) => m.uid != me?.uid);
          }
          bool matches(Player p) =>
              q.isEmpty || p.displayName.toLowerCase().contains(q);
          // Players come by number (sortPlayers); by name on request.
          final shownPlayers = players.where(matches).toList();
          if (order == RosterOrder.name) {
            shownPlayers.sort(
              (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
            );
          }
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
          // Each group of rows on its own card (design §3.5).
          Widget card(List<Widget> rows) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SettingsCard(padding: EdgeInsets.zero, children: rows),
          );
          final memberRows = [
            (l10n.rosterCoaches, coaches),
            (l10n.rosterAdmins, admins),
            (l10n.rosterMembers, others),
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: Space.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: TextField(
                  style: gumdropFieldText(context),
                  decoration: gumdropField(hint: l10n.searchByName)
                      .copyWith(prefixIcon: const Icon(AppIcons.search)),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (toDecide.isNotEmpty || claims.isNotEmpty) ...[
                _Section(title: l10n.playerRequestsTitle),
                card([
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
                ]),
              ],
              if (!isAdmin && me != null && !linked && !waiting) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SettingsCard(
                    children: [
                      SettingsRow(
                        icon: AppIcons.invite,
                        highlighted: true,
                        title: l10n.whoAreYouHereFor,
                        subtitle: l10n.whoAreYouHereForRosterHint,
                        subtitleLines: 3,
                        onTap: () =>
                            context.push('/g/${widget.groupId.value}/who'),
                      ),
                    ],
                  ),
                ),
              ],
              _Section(title: l10n.rosterPlayers),
              if (players.isEmpty && mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.sm,
                  ),
                  child: Text(
                    l10n.adminNoPlayers,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GumdropColors.of(context).textMutedOnPage,
                    ),
                  ),
                )
              else if (mine.isNotEmpty || shownPlayers.isNotEmpty)
                card([
                  // My own players waiting for an admin (PLAYER-4).
                  for (final p in mine)
                    ListTile(
                      leading: _JerseyDisc(number: p.jerseyNumber),
                      title: Text(p.displayName),
                      subtitle: Text(l10n.playerPending),
                    ),
                  for (final p in shownPlayers)
                    _PlayerRow(
                      player: p,
                      age: details[p.id]?.ageAt(today),
                      // TEAM-3: number, name, and who's linked.
                      linked: [
                        for (final l in links)
                          if (l.playerId == p.id)
                            if (nameOf(l.uid.value) case final name?)
                              if (l.isSelf)
                                l10n.playerLinkSelfName(name)
                              else
                                name,
                      ],
                    ),
                ]),
              for (final (title, people) in memberRows)
                if (people.isNotEmpty) ...[
                  _Section(title: title),
                  card([
                    for (final m in people)
                      _MemberRow(
                        member: m,
                        me: me,
                        who: whoLabel(l10n, m.uid, links, players),
                      ),
                  ]),
                ],
              if (!seePeople)
                Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Text(
                    l10n.rosterPeopleHidden,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GumdropColors.of(context).textMutedOnPage,
                    ),
                  ),
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

/// A player: number, name, age for admins (PLAYER-12), and who's linked
/// (TEAM-3).
class _PlayerRow extends StatelessWidget {
  const new({required this.player, required this.linked, this.age});

  final Player player;
  final List<String> linked;

  /// Null without a date of birth, and for everyone but admins.
  final int? age;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      if (age case final age?) l10n.playerAge(age),
      if (linked.isNotEmpty) linked.join(', '),
    ];
    return ListTile(
      leading: _JerseyDisc(number: player.jerseyNumber),
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
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: PageHeading(title),
  );
}

/// A player's jersey number on a 40 px candy disc (design §3.9).
class _JerseyDisc extends StatelessWidget {
  const new({required this.number});

  final String? number;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.you.face, shape: BoxShape.circle),
      child: Text(
        number ?? '',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.ink),
      ),
    );
  }
}

/// Role badge text: Owner or Admin. A direct conversation's people
/// (CHAT-19) aren't on a roster.
String? roleBadge(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.owner => l10n.roleOwner,
  MemberRole.admin => l10n.roleAdmin,
  MemberRole.member || MemberRole.participant => null,
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

/// A person's card (TEAM-3): photo, name, title, role, who's who, the
/// phone and email they share with the team with call, text, and email
/// buttons (TEAM-10), and the actions the viewer is allowed (SPEC §3),
/// Report and Block included. On my own card I share or stop sharing my
/// phone and email.
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
    // Kept live, so sharing my contact info shows on the card at once.
    final member =
        ref
            .watch(rosterProvider(this.member.groupId))
            .value
            ?.where((m) => m.uid == this.member.uid)
            .firstOrNull ??
        this.member;
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
            if (badge != null || member.isCoach) ...[
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                children: [
                  if (member.isCoach) Chip(label: Text(l10n.memberCoach)),
                  if (badge != null) Chip(label: Text(badge)),
                ],
              ),
            ],
            if (who case final label?) ...[
              const SizedBox(height: Space.sm),
              Text(label),
            ],
            const SizedBox(height: Space.lg),
            // Their page (TEAM-15), and a direct message (CHAT-19) to
            // someone who has joined and isn't blocked.
            if (!isSelf)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  if (!member.pending &&
                      !ref.watch(blockedIdsProvider).contains(member.uid.value))
                    MessageButton(uid: member.uid, name: member.displayName),
                  OutlinedButton.icon(
                    onPressed: () {
                      // The card closes first; its context goes with it.
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      unawaited(
                        router.push(
                          personPageLocation(
                            member.uid,
                            teamId: member.groupId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(AppIcons.person),
                    label: Text(l10n.viewProfile),
                  ),
                ],
              ),
            if (!isSelf) const SizedBox(height: Space.md),
            _SharedContact(member: member, isSelf: isSelf),
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
            // A parent who also coaches (TEAM-3): with the coaches on the
            // roster, and answering for themselves on events (PLAYER-6).
            if (canEditTitle)
              SwitchListTile(
                title: Text(l10n.memberCoach),
                subtitle: Text(l10n.memberCoachHelp),
                value: member.isCoach,
                onChanged: (coach) async {
                  try {
                    await repo.updateMember(
                      member.groupId,
                      member.uid,
                      coach: coach,
                    );
                  } on AppFailure catch (e) {
                    if (!context.mounted) return;
                    showAppSnackBar(
                      context,
                      e is PermissionDenied
                          ? l10n.notAllowed
                          : l10n.errorMemberAction,
                    );
                  }
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
            // Leaving is here, on my own card, rather than in the team
            // menu, where it was too easy to tap by mistake (TEAM-8).
            if (isSelf)
              ListTile(
                leading: Icon(
                  AppIcons.leave,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.leaveTeamMenu,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                // Asked over the card; leaving goes home, which closes it.
                onTap: () async {
                  final group = ref.read(groupProvider(member.groupId)).value;
                  if (group != null) await leaveTeam(context, ref, group);
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

/// The phone and email someone shares with the team (TEAM-10), with call,
/// text, and email buttons; on my own card, sharing them, changing them,
/// and stopping. Sharing needs an open team; stopping always works.
class _SharedContact extends ConsumerWidget {
  const new({required this.member, required this.isSelf});

  final Membership member;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = member.displayName;
    final group = ref.watch(groupProvider(member.groupId)).value;
    final open = group != null && !group.isArchived;
    Future<void> launch(Uri uri) async {
      final opened = await ref.read(linkOpenerProvider).open(uri);
      if (!opened && context.mounted) {
        showAppSnackBar(context, l10n.linkOpenFailed);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (member.contactPhone case final phone?)
          ListTile(
            leading: const Icon(AppIcons.call),
            title: Text(phone),
            subtitle: Text(l10n.contactPhoneLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.callContact(name),
                  icon: const Icon(AppIcons.call),
                  onPressed: () => unawaited(
                    launch(Uri(scheme: 'tel', path: dialable(phone))),
                  ),
                ),
                IconButton(
                  tooltip: l10n.textContact(name),
                  icon: const Icon(AppIcons.sms),
                  onPressed: () => unawaited(
                    launch(Uri(scheme: 'sms', path: dialable(phone))),
                  ),
                ),
              ],
            ),
          ),
        if (member.contactEmail case final email?)
          ListTile(
            leading: const Icon(AppIcons.email),
            title: Text(email),
            subtitle: Text(l10n.contactEmailLabel),
            trailing: IconButton(
              tooltip: l10n.emailContact(name),
              icon: const Icon(AppIcons.send),
              onPressed: () =>
                  unawaited(launch(Uri(scheme: 'mailto', path: email))),
            ),
          ),
        if (isSelf && open)
          ListTile(
            leading: const Icon(AppIcons.contactInfo),
            title: Text(
              member.sharesContact
                  ? l10n.editContactInfo
                  : l10n.shareContactInfo,
            ),
            subtitle: Text(l10n.contactInfoHelp(group.name)),
            onTap: () => unawaited(_edit(context, ref, group.name)),
          )
        else if (isSelf && member.sharesContact)
          ListTile(
            leading: const Icon(AppIcons.contactInfo),
            title: Text(l10n.stopSharingContact),
            onTap: () => unawaited(_save(context, ref, null, null)),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String team) async {
    final account = ref.read(authUserProvider).value?.email;
    final result = await showDialog<({String? phone, String? email})>(
      context: context,
      builder: (_) => _ContactDialog(
        team: team,
        phone: member.contactPhone,
        // Offered from the account when nothing's shared yet.
        email: member.sharesContact ? member.contactEmail : account,
        canStop: member.sharesContact,
      ),
    );
    if (result == null || !context.mounted) return;
    await _save(context, ref, result.phone, result.email);
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String? phone,
    String? email,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(memberRepositoryProvider)
          .setContact(member.groupId, member.uid, phone: phone, email: email);
      if (context.mounted) {
        showAppSnackBar(
          context,
          phone == null && email == null
              ? l10n.contactStopped
              : l10n.contactSaved,
        );
      }
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.contactSaveFailed);
    }
  }
}

/// My phone and email for this team (TEAM-10), either left blank to keep
/// it to myself. Pops the two (null for blank), or both null for Stop
/// sharing.
class _ContactDialog extends StatefulWidget {
  const new({
    required this.team,
    required this.canStop,
    this.phone,
    this.email,
  });

  final String team;
  final String? phone;
  final String? email;

  /// Something is shared already, so Stop sharing is offered.
  final bool canStop;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.phone);
  late final _email = TextEditingController(text: widget.email);

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _blank(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.contactInfoTitle),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.contactInfoHelp(widget.team)),
            TextFormField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              maxLength: Limits.contactPhoneMax,
              decoration: InputDecoration(labelText: l10n.contactPhoneLabel),
              validator: (v) => v == null || v.trim().isEmpty
                  ? null
                  : hasDialableDigits(v) &&
                        v.trim().length <= Limits.contactPhoneMax
                  ? null
                  : l10n.contactPhoneInvalid(Limits.contactPhoneMax),
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              maxLength: Limits.contactEmailMax,
              decoration: InputDecoration(labelText: l10n.contactEmailLabel),
              validator: (v) => v == null || v.trim().isEmpty
                  ? null
                  : looksLikeEmail(v.trim())
                  ? null
                  : l10n.contactEmailInvalid,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.canStop)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop((phone: null, email: null)),
            child: Text(l10n.stopSharingContact),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context)
                .pop((phone: _blank(_phone.text), email: _blank(_email.text)));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
