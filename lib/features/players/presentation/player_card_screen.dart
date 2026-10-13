import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/players/presentation/player_details_section.dart';
import 'package:battleplan/features/players/presentation/player_dialogs.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-2 at `/g/:groupId/roster/players/:playerId`: name, number,
/// position, and who's linked, each marked Player or Guardian. Linked
/// members (the player themselves included) and admins edit the details
/// and add a guardian (PLAYER-5); admins remove links and the player, and
/// a linked member can remove their own link. A member who isn't linked can claim
/// the player, as the player or a parent or guardian (PLAYER-3). The
/// team's admins and linked members also see the player's Details, and
/// edit them unless the team is archived (PLAYER-12); nobody else sees
/// the section. Upcoming RSVPs list the player's answer on each of the
/// next events that take RSVPs, each opening its event, and the same
/// people (and super admins) open the player's RSVP history (PLAYER-11).
class PlayerCardScreen extends ConsumerWidget {
  const new({required this.groupId, required this.playerId, super.key});

  final GroupId groupId;
  final PlayerId playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref
        .watch(playersProvider(groupId))
        .value
        ?.where((p) => p.id == playerId)
        .firstOrNull;
    final links = ref.watch(guardianLinksProvider(groupId)).value ?? const [];
    final roster = ref.watch(rosterProvider(groupId)).value ?? const [];
    final me = ref.watch(authUserProvider).value?.uid;
    final membership = ref.watch(myMembershipProvider(groupId));
    // Super admins manage players and links from the admin panel too
    // (ADMIN-3).
    final teamAdmin = membership?.isAdmin ?? false;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final isAdmin = teamAdmin || superAdmin;
    if (player == null) {
      final loading =
          !ref.watch(playersProvider(groupId)).hasValue ||
          ref.watch(playersProvider(groupId)).isLoading;
      return Scaffold(
        appBar: AppBar(),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: AppIcons.roster,
                message: l10n.playerNotFound,
                actionLabel: l10n.backToRoster,
                onAction: () => context.go('/g/${groupId.value}/roster'),
              ),
      );
    }
    final playerLinks = [
      for (final l in links)
        if (l.playerId == playerId) l,
    ]..sort((a, b) => a.isSelf == b.isSelf ? 0 : (a.isSelf ? -1 : 1));
    final myLink = playerLinks.where((l) => l.uid.value == me).firstOrNull;
    final canEdit = isAdmin || myLink != null;
    // Any linked member vouches for a guardian, the player themselves
    // included (PLAYER-5).
    final canAddGuardian = isAdmin || myLink != null;
    // The rules let only linked members and the team's admins write a
    // player, so a super admin who is neither saves through the audited
    // admin callable.
    final viaAdmin = superAdmin && !teamAdmin && myLink == null;
    // Details only for the team's admins and members linked to this player
    // (PLAYER-12); for anyone else they're never asked for. Read-only on an
    // archived team, as the rules refuse writes there.
    final seesDetails = seesPlayerDetails(
      me,
      playerId,
      teamAdmin: teamAdmin,
      links: links,
    );
    final group = ref.watch(groupProvider(groupId)).value;
    final detailsEditable =
        group != null && !group.isArchived && group.suspendedAt == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(player.displayName),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: l10n.editPlayer,
              icon: const Icon(AppIcons.edit),
              onPressed: () =>
                  unawaited(_edit(context, ref, player, viaAdmin: viaAdmin)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.jerseyNumberLabel),
            subtitle: Text(player.jerseyNumber ?? '—'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.positionLabel),
            subtitle: Text(player.position ?? '—'),
          ),
          if (seesDetails) ...[
            const SizedBox(height: Space.lg),
            PlayerDetailsSection(
              groupId: groupId,
              playerId: playerId,
              canEdit: detailsEditable,
            ),
          ],
          const SizedBox(height: Space.lg),
          Text(
            l10n.playerLinksLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (playerLinks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text(l10n.noPlayerLinks),
            ),
          for (final l in playerLinks)
            if (roster.where((m) => m.uid == l.uid).firstOrNull case final m?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Avatar(name: m.displayName, colorKey: m.uid.value),
                title: Text(m.displayName),
                subtitle: Text(
                  [
                    if (l.isSelf)
                      l10n.playerLinkPlayer
                    else
                      l10n.playerLinkGuardian,
                    if (m.pending) l10n.notJoinedYet,
                  ].join(' · '),
                ),
                // Admins remove any link; a member can remove their own.
                trailing: isAdmin || m.uid.value == me
                    ? IconButton(
                        tooltip: l.isSelf
                            ? l10n.removePlayerLink
                            : l10n.removeGuardian,
                        icon: const Icon(AppIcons.close),
                        onPressed: () => unawaited(
                          _removeGuardian(
                            context,
                            ref,
                            m.uid,
                            m.displayName,
                            self: l.isSelf,
                          ),
                        ),
                      )
                    : null,
              ),
          // A linked member vouches for a guardian; admins can add anyone
          // (PLAYER-5, PLAYER-2). The player's own link doesn't count
          // toward the 4.
          if (canAddGuardian &&
              guardianCountOf(playerId, links) < Limits.guardiansPerPlayerMax)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => unawaited(_addGuardian(context, ref)),
                icon: const Icon(AppIcons.invite),
                label: Text(l10n.addGuardian),
              ),
            ),
          // PLAYER-3: a member who isn't linked can claim the player.
          if (membership != null && myLink == null)
            _Claim(
              player: player,
              // Nobody is this player yet, and I'm not a player here and
              // haven't asked to be one (PLAYER-3).
              canBeSelf:
                  selfLinkOf(playerId, links) == null &&
                  me != null &&
                  canStillBeAPlayer(
                    UserId(me),
                    links: links,
                    requests:
                        ref.watch(myGuardianRequestsProvider(groupId)).value ??
                        const [],
                    pendingPlayers:
                        ref.watch(myPendingPlayersProvider(groupId)).value ??
                        const [],
                  ),
            ),
          const SizedBox(height: Space.lg),
          _UpcomingRsvps(groupId: groupId, playerId: playerId),
          // Past answers, for the player's people and admins (PLAYER-11).
          if (seesDetails || superAdmin)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.history),
              title: Text(l10n.rsvpHistoryEntry),
              subtitle: Text(l10n.rsvpHistoryEntryHelp),
              trailing: const Icon(AppIcons.chevronRight),
              onTap: () => context.push(
                '/g/${groupId.value}/roster/players/${playerId.value}/history',
              ),
            ),
          if (isAdmin) ...[
            const SizedBox(height: Space.xl),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.removePlayerTitle(player.displayName),
                  confirmLabel: l10n.removePlayer,
                  cancelLabel: l10n.cancel,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                try {
                  await ref
                      .read(playerRepositoryProvider)
                      .removePlayer(groupId, playerId);
                  if (context.mounted) context.pop();
                } on AppFailure {
                  if (context.mounted) {
                    showAppSnackBar(context, l10n.errorRemovePlayer);
                  }
                }
              },
              child: Text(l10n.removePlayer),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addGuardian(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final email = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addGuardian),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addGuardianHelp),
            TextField(
              controller: email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.guardianEmailLabel),
            ),
            TextField(
              controller: name,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.guardianNameLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    final address = email.text.trim();
    if (ok != true || !address.contains('@') || !context.mounted) return;
    try {
      final invited = await ref
          .read(playerRepositoryProvider)
          .inviteGuardian(
            groupId,
            playerId,
            email: address,
            name: name.text.trim().isEmpty ? null : name.text.trim(),
          );
      if (context.mounted) {
        showAppSnackBar(
          context,
          invited ? l10n.guardianInvited : l10n.guardianAdded,
        );
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, switch (e) {
          InvalidInput(message: 'too-many-guardians') => l10n.tooManyGuardians,
          // The email is the member who is this player (PLAYER-3).
          InvalidInput(message: 'already-linked') => l10n.guardianAlreadyLinked,
          RateLimited() => l10n.signInRateLimited,
          EmailNotVerified() => l10n.addByEmailNeedsVerified,
          _ => l10n.errorAddGuardian,
        });
      }
    }
  }

  Future<void> _removeGuardian(
    BuildContext context,
    WidgetRef ref,
    UserId uid,
    String name, {
    required bool self,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: self
          ? l10n.removePlayerLinkTitle(name)
          : l10n.removeGuardianTitle(name),
      confirmLabel: self ? l10n.removePlayerLink : l10n.removeGuardian,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(playerRepositoryProvider)
          .removeGuardian(groupId, playerId, uid);
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.errorRemoveGuardian);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Player player, {
    required bool viaAdmin,
  }) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: player.displayName);
    final number = TextEditingController(text: player.jerseyNumber);
    final position = TextEditingController(text: player.position);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPlayer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: l10n.playerNameLabel),
            ),
            TextField(
              controller: number,
              maxLength: 4,
              decoration: InputDecoration(labelText: l10n.jerseyNumberLabel),
            ),
            TextField(
              controller: position,
              decoration: InputDecoration(labelText: l10n.positionLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (save != true || name.text.trim().isEmpty) return;
    try {
      if (viaAdmin) {
        await ref
            .read(adminRepositoryProvider)
            .updatePlayer(
              player.id,
              name: name.text,
              jerseyNumber: number.text,
              position: position.text,
            );
      } else {
        await ref
            .read(playerRepositoryProvider)
            .updatePlayer(
              player.id,
              name: name.text,
              jerseyNumber: number.text,
              position: position.text,
            );
      }
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }
}

/// How many upcoming events the player card lists (PLAYER-2).
const playerCardEventsShown = 5;

/// The player's answers on the next events that take RSVPs (PLAYER-2),
/// "No answer" where nobody has answered yet. Each opens its event, where
/// linked members and admins answer.
class _UpcomingRsvps extends ConsumerWidget {
  const new({required this.groupId, required this.playerId});

  final GroupId groupId;
  final PlayerId playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final list = ref.watch(teamEventsProvider(groupId, past: false));
    final answers =
        ref.watch(playerRsvpsProvider(groupId, playerId)).value ?? const {};
    final events = list.events
        .where((e) => e.takesRsvps)
        .take(playerCardEventsShown)
        .toList();
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.upcomingRsvps, style: theme.textTheme.titleSmall),
        if (list.loading)
          const Padding(
            padding: EdgeInsets.all(Space.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l10n.noUpcomingRsvps),
          ),
        for (final e in events)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.title),
            subtitle: Text(
              e.allDay
                  ? dates.formatMediumDate(e.startAt)
                  : '${dates.formatMediumDate(e.startAt.toLocal())} · '
                        '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(e.startAt.toLocal()))}',
            ),
            trailing: Text(switch (answers[e.id.value]?.status) {
              RsvpStatus.going => l10n.rsvpGoing,
              RsvpStatus.maybe => l10n.rsvpMaybe,
              RsvpStatus.notGoing => l10n.rsvpNotGoing,
              null => l10n.rsvpNoAnswer,
            }),
            onTap: () =>
                context.push('/g/${groupId.value}/schedule/e/${e.id.value}'),
          ),
      ],
    );
  }
}

/// "Claim this player" for a member who isn't linked (PLAYER-3), or that
/// their claim is waiting for an admin.
class _Claim extends ConsumerStatefulWidget {
  const new({required this.player, required this.canBeSelf});

  final Player player;
  final bool canBeSelf;

  @override
  ConsumerState<_Claim> createState() => _ClaimState();
}

class _ClaimState extends ConsumerState<_Claim> {
  bool _saving = false;

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context);
    final relation = await askClaimRelation(
      context,
      playerName: widget.player.displayName,
      canBeSelf: widget.canBeSelf,
    );
    if (relation == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final outcome = await ref
          .read(playerRepositoryProvider)
          .claimPlayer(widget.player.groupId, widget.player.id, relation);
      if (mounted) {
        showAppSnackBar(
          context,
          outcome == ClaimOutcome.linked
              ? l10n.claimLinked
              : l10n.guardianRequestSent,
        );
      }
    } on AppFailure catch (e) {
      if (mounted) showAppSnackBar(context, playerRequestFailure(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waiting =
        (ref.watch(myGuardianRequestsProvider(widget.player.groupId)).value ??
                const <GuardianRequest>[])
            .any(
              (r) =>
                  r.playerId == widget.player.id &&
                  r.status == GuardianRequestStatus.pending,
            );
    if (waiting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Text(l10n.claimWaiting),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _saving ? null : () => unawaited(_claim()),
        icon: const Icon(AppIcons.family),
        label: Text(l10n.claimPlayer),
      ),
    );
  }
}
