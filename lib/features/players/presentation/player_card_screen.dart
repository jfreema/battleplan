import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/camp_app_bar.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:battleplan/features/players/presentation/date_of_birth_field.dart';
import 'package:battleplan/features/players/presentation/guardian_picker.dart';
import 'package:battleplan/features/players/presentation/player_details_section.dart';
import 'package:battleplan/features/players/presentation/player_dialogs.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-2 at `/g/:groupId/team/players/:playerId`: name, number, walk-up
/// song, date of birth (for those who see the Details), and who's linked, each marked
/// Player, Guardian, or Parent (#95; a guardian picks theirs from their own
/// row). Linked
/// members (the player themselves included) and admins edit the details
/// and add a guardian, picked from the team or by email (PLAYER-5); admins remove links and the player, and
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
        appBar: const CampAppBar(),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: AppIcons.roster,
                message: l10n.playerNotFound,
                actionLabel: l10n.backToRoster,
                onAction: () => context.go('/g/${groupId.value}/team'),
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
    // (PLAYER-12), who also edit them, and super admins, who only read
    // them for support; for anyone else they're never asked for. Read-only
    // on an archived team, as the rules refuse writes there.
    final writesDetails = seesPlayerDetails(
      me,
      playerId,
      teamAdmin: teamAdmin,
      links: links,
    );
    final seesDetails = writesDetails || superAdmin;
    final group = ref.watch(groupProvider(groupId)).value;
    final detailsEditable =
        group != null && !group.isArchived && group.suspendedAt == null;

    return GumdropScaffold(
      title: player.displayName,
      // From the roster, or the chevron alone from a link.
      backLabel: openerLabel(context),
      actions: [
        if (canEdit)
          IconButton(
            tooltip: l10n.editPlayer,
            icon: const Icon(AppIcons.edit),
            onPressed: () => unawaited(
              _edit(
                context,
                ref,
                player,
                viaAdmin: viaAdmin,
                // Admins and the player's own people, as on Details
                // (PLAYER-12); never through the admin callable.
                withDateOfBirth: writesDetails && detailsEditable,
              ),
            ),
          ),
      ],
      body: ListView(
        // Level with the title.
        padding: const EdgeInsets.symmetric(
          horizontal: Space.page,
          vertical: Space.xl,
        ),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.jerseyNumberLabel),
            subtitle: Text(player.jerseyNumber ?? '—'),
          ),
          // The whole team sees the walk-up song (PLAYER-2); the people who
          // edit the player see the row before there's one.
          if ((player.walkUpSong?.isNotEmpty ?? false) || canEdit)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.walkUpSongLabel),
              subtitle: Text(player.walkUpSong ?? '—'),
            ),
          if (seesDetails) DateOfBirthTile(playerId: playerId),
          if (seesDetails) ...[
            const SizedBox(height: Space.lg),
            PlayerDetailsSection(
              groupId: groupId,
              playerId: playerId,
              canEdit: writesDetails && detailsEditable,
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
              _LinkRow(
                member: m,
                isSelf: l.isSelf,
                title: l.title,
                // A guardian changes how they're listed themselves (#95),
                // unless the team is read-only.
                onTitle: !l.isSelf && m.uid.value == me && detailsEditable
                    ? (t) => unawaited(_setTitle(context, ref, t))
                    : null,
                // Admins unlink anyone; a member can unlink themselves.
                onUnlink: isAdmin || m.uid.value == me
                    ? () => unawaited(
                        _unlink(
                          context,
                          ref,
                          player,
                          m,
                          isPlayer: l.isSelf,
                          mine: m.uid.value == me,
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
                onPressed: () => unawaited(
                  _addGuardian(
                    context,
                    ref,
                    guardianCandidates(
                      roster,
                      linked: {for (final l in playerLinks) l.uid.value},
                      me: me,
                      isAdmin: isAdmin,
                      membersCanSeePeople:
                          group?.settings.membersCanSeePeople ?? true,
                    ),
                  ),
                ),
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
                '/g/${groupId.value}/team/players/${playerId.value}/history',
              ),
            ),
          if (isAdmin) ...[
            const SizedBox(height: Space.xl),
            OutlinedButton(
              // The warning red as it reads on the push button's panel
              // color (Candy Pop's white, #86).
              style: OutlinedButton.styleFrom(
                foregroundColor: GumdropColors.of(context).card.cherry.text,
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

  /// "Add a guardian" (PLAYER-5): someone on the team from [candidates],
  /// or by email. With no one to pick, straight to the email.
  Future<void> _addGuardian(
    BuildContext context,
    WidgetRef ref,
    List<Membership> candidates,
  ) async {
    if (candidates.isEmpty) return await _inviteGuardian(context, ref);
    final picked = await pickGuardian(context, candidates: candidates);
    if (!context.mounted) return;
    switch (picked) {
      case null:
        return;
      case GuardianByEmail():
        return await _inviteGuardian(context, ref);
      case GuardianFromTeam(:final member):
        final l10n = AppLocalizations.of(context);
        try {
          await ref
              .read(playerRepositoryProvider)
              .addTeamMemberAsGuardian(groupId, playerId, member.uid);
          if (context.mounted) showAppSnackBar(context, l10n.guardianAdded);
        } on AppFailure catch (e) {
          if (context.mounted) {
            showAppSnackBar(context, _addGuardianFailure(l10n, e));
          }
        }
    }
  }

  String _addGuardianFailure(AppLocalizations l10n, AppFailure e) =>
      switch (e) {
        InvalidInput(message: 'too-many-guardians') => l10n.tooManyGuardians,
        // They're the member who is this player (PLAYER-3).
        InvalidInput(message: 'already-linked') => l10n.guardianAlreadyLinked,
        RateLimited() => l10n.signInRateLimited,
        EmailNotVerified() => l10n.addByEmailNeedsVerified,
        _ => l10n.errorAddGuardian,
      };

  /// Adds a guardian by email (PLAYER-5).
  Future<void> _inviteGuardian(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final email = TextEditingController();
    final name = TextEditingController();
    final ok = await showCardDialog<bool>(
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
        showAppSnackBar(context, switch (invited) {
          GuardianInvite.added => l10n.guardianAdded,
          GuardianInvite.invited => l10n.guardianInvited,
          GuardianInvite.emailFailed => l10n.guardianEmailFailed,
        });
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, _addGuardianFailure(l10n, e));
      }
    }
  }

  /// Unlinks [member] from [player] (PLAYER-5, #37), saying first what
  /// that means: whoever it is stops answering the player's RSVPs and
  /// seeing their details, and stays on the team. My own link ([mine]),
  /// as a guardian or as the player ([isPlayer]), can be claimed again.
  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    Player player,
    Membership member, {
    required bool isPlayer,
    required bool mine,
  }) async {
    final l10n = AppLocalizations.of(context);
    final first = player.firstName;
    final person = member.displayName.trim().split(RegExp(r'\s+')).first;
    final (title, message) = switch ((mine, isPlayer)) {
      (true, true) => (
        l10n.unlinkPlayerSelfTitle(player.label),
        l10n.unlinkPlayerSelfBody,
      ),
      (true, false) => (
        l10n.unlinkGuardianSelfTitle(first),
        l10n.unlinkGuardianSelfBody(first),
      ),
      (false, _) => (
        l10n.unlinkOtherTitle(member.displayName, first),
        l10n.unlinkOtherBody(person, first),
      ),
    };
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: l10n.unlinkAction,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(playerRepositoryProvider)
          .removeGuardian(groupId, playerId, member.uid);
      if (context.mounted) {
        showAppSnackBar(
          context,
          mine ? l10n.unlinkedSelf(first) : l10n.unlinkedOther(person, first),
        );
      }
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.errorRemoveGuardian);
    }
  }

  /// Lists me as [title] on this player's card (#95): Guardian or Parent.
  Future<void> _setTitle(
    BuildContext context,
    WidgetRef ref,
    GuardianTitle title,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(playerRepositoryProvider)
          .setGuardianTitle(groupId, playerId, title);
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.errorGuardianTitle);
    }
  }

  /// Edits the name and number (PLAYER-2), and with
  /// [withDateOfBirth] the date of birth, which is saved in the player's
  /// details (PLAYER-12).
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Player player, {
    required bool viaAdmin,
    required bool withDateOfBirth,
  }) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: player.displayName);
    final number = TextEditingController(text: player.jerseyNumber);
    final song = TextEditingController(text: player.walkUpSong);
    // Only once the details have loaded, so saving keeps the rest of them.
    final stored = withDateOfBirth
        ? ref.read(playerDetailsProvider(playerId))
        : null;
    final withDob = stored != null && stored.hasValue;
    final before = stored?.value;
    var dob = switch (before?.dateOfBirth) {
      final d? => parseDateOfBirth(d),
      null => null,
    };
    final save = await showCardDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                controller: song,
                maxLength: Limits.walkUpSongMax,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.walkUpSongLabel,
                  hintText: l10n.walkUpSongHint,
                ),
              ),
              if (withDob) ...[
                DateOfBirthField(
                  value: dob,
                  onChanged: (d) => setState(() => dob = d),
                ),
                const DateOfBirthPrivacyNote(),
              ],
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
      ),
    );
    if (save != true || name.text.trim().isEmpty) return;
    if (withDob && context.mounted) {
      final newDob = dob == null ? null : formatDateOfBirth(dob!);
      if (newDob != before?.dateOfBirth) {
        await _saveDateOfBirth(context, ref, player, before, newDob);
      }
    }
    try {
      if (viaAdmin) {
        await ref
            .read(adminRepositoryProvider)
            .updatePlayer(
              player.id,
              name: name.text,
              jerseyNumber: number.text,
              walkUpSong: song.text,
            );
      } else {
        await ref
            .read(playerRepositoryProvider)
            .updatePlayer(
              player.id,
              name: name.text,
              jerseyNumber: number.text,
              walkUpSong: song.text,
            );
      }
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }

  /// Saves a new or cleared date of birth in the player's details
  /// (PLAYER-12), keeping the rest of them; details left empty go.
  Future<void> _saveDateOfBirth(
    BuildContext context,
    WidgetRef ref,
    Player player,
    PlayerDetails? before,
    String? dateOfBirth,
  ) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(playerRepositoryProvider);
    final details =
        (before ?? PlayerDetails(playerId: player.id, groupId: player.groupId))
            .copyWith(dateOfBirth: dateOfBirth)
            .cleaned;
    try {
      if (details.isEmpty) {
        if (before != null) await repo.deletePlayerDetails(player.id);
      } else {
        await repo.savePlayerDetails(details, by: UserId(uid));
      }
    } on AppFailure {
      if (context.mounted) {
        showAppSnackBar(context, l10n.playerDetailsSaveFailed);
      }
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
    // The event screen goes back to the player, by first name.
    final first = ref
        .watch(playersProvider(groupId))
        .value
        ?.where((p) => p.id == playerId)
        .firstOrNull
        ?.displayName
        .trim()
        .split(' ')
        .first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.upcomingRsvps, style: theme.textTheme.titleSmall),
        // Placeholder rows while the events load, not a spinner (#37).
        if (list.loading)
          const SkeletonList(rows: 3)
        else if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l10n.noUpcomingRsvps),
          ),
        for (final e in events)
          _UpcomingRow(
            event: e,
            answer: answers[e.id.value],
            when: e.allDay
                ? dates.formatMediumDate(
                    dayOf(e, ViewerZone.of(context) ?? e.timeZone),
                  )
                : '${dates.formatMediumDate(ViewerZone.wallClock(context, e.startAt))} · '
                      '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(ViewerZone.wallClock(context, e.startAt)))}',
            onTap: () => context.push(
              '/g/${groupId.value}/schedule/e/${e.id.value}',
              extra: BackLabel(first),
            ),
          ),
      ],
    );
  }
}

/// One person linked to the player: their name and how they're linked
/// ("Guardian", "Player · Not joined yet"), and a worded, quiet Unlink
/// where a bare X didn't say what it does (PLAYER-5, #37). Unlink sits at
/// the row's end, or under the name with large text, as page rows put
/// theirs, so the name and "Guardian" keep the row's width and never break
/// inside a word.
class _LinkRow extends StatelessWidget {
  const new({
    required this.member,
    required this.isSelf,
    this.title = GuardianTitle.guardian,
    this.onTitle,
    this.onUnlink,
  });

  final Membership member;

  /// Linked as the player, not as a guardian.
  final bool isSelf;

  /// A guardian's label (#95): "Guardian" or "Parent".
  final GuardianTitle title;

  /// Where the viewer is this guardian, changes how they're listed (#95):
  /// their label is a dropdown. Null for everyone else's row.
  final ValueChanged<GuardianTitle>? onTitle;

  /// Null where the viewer may not unlink them.
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final below =
        onUnlink != null && MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final unlink = switch (onUnlink) {
      final tap? => Semantics(
        // Its own button, apart from the row's text.
        container: true,
        label: l10n.unlinkPerson(member.displayName),
        excludeSemantics: true,
        button: true,
        child: TextButton(
          style: GumdropButtons.of(context).link().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            // Under the name, its word starts where the name's does.
            padding: below
                ? const WidgetStatePropertyAll(EdgeInsets.zero)
                : null,
          ),
          onPressed: tap,
          child: Text(l10n.unlinkAction),
        ),
      ),
      null => null,
    };
    final role = switch (onTitle) {
      // My own guardian row: Guardian or Parent, mine to pick (#95).
      final pick? => Semantics(
        // "Listed as, Guardian": what it is, then what it says.
        label: l10n.guardianTitleLabel,
        child: DropdownButton<GuardianTitle>(
          value: title,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: [
            for (final t in GuardianTitle.values)
              DropdownMenuItem(
                value: t,
                child: Text(guardianTitleName(l10n, t)),
              ),
          ],
          onChanged: (t) {
            if (t != null && t != title) pick(t);
          },
        ),
      ),
      null => Text(
        [
          if (isSelf) l10n.playerLinkPlayer else guardianTitleName(l10n, title),
          if (member.pending) l10n.notJoinedYet,
        ].join(' · '),
      ),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Avatar(
        name: member.displayName,
        colorKey: member.uid.value,
        color: member.avatarColor,
      ),
      title: Text(member.displayName),
      subtitle: switch ((below, unlink)) {
        (true, final button?) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [role, button],
        ),
        _ => role,
      },
      trailing: below ? null : unlink,
    );
  }
}

/// One upcoming event on the player card: its title and when, and the
/// player's answer at the end in its color with its icon, as the RSVP
/// history page shows answers (#37), or "No answer" and "Canceled" muted.
/// Screen readers hear one line: "Practice, Sat, Nov 21 · 4:00 PM, Going".
class _UpcomingRow extends StatelessWidget {
  const new({
    required this.event,
    required this.answer,
    required this.when,
    required this.onTap,
  });

  final Event event;
  final Rsvp? answer;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final status = answer?.status;
    final quiet = event.isCanceled || status == null;
    final label = event.isCanceled
        ? l10n.eventCanceled
        : status == null
        ? l10n.rsvpNoAnswer
        : statusLabel(l10n, status);
    final color = quiet
        ? (c.onCard ? c.textMuted : c.textMutedOnPage)
        : statusColor(context, status);
    // A page row: the answer at its end, or under the event with large
    // text, so it never crowds the title.
    return PageRow(
      title: event.title,
      subtitle: when,
      semanticsLabel: '${event.title}, $when, $label',
      // When wraps with large text rather than losing its time.
      subtitleMaxLines: null,
      onTap: onTap,
      chevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!quiet) ...[
            Icon(statusIcon(status), size: 18, weight: 700, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
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
    final choice = await askClaimRelation(
      context,
      playerName: widget.player.displayName,
      canBeSelf: widget.canBeSelf,
    );
    if (choice == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final outcome = await ref
          .read(playerRepositoryProvider)
          .claimPlayer(
            widget.player.groupId,
            widget.player.id,
            choice.relation,
            title: choice.title,
          );
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
