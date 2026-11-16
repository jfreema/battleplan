import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/presentation/player_dialogs.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-3 at `/g/:groupId/who`, opened from the chat's card, a schedule
/// card, an event, the Team tab, or Dues by someone on a team who isn't
/// linked to a player yet. Joining goes straight into the team instead
/// (owner's request 2026-11-10):
///
/// - **I'm a player**: pick yourself from the roster (a claim as yourself),
///   or add yourself (a pending player linked to you, PLAYER-4).
/// - **I'm here for a player**: pick your players (claims as their parent
///   or guardian), or add one who isn't listed.
/// - **I'm a coach or another adult**: saved on their membership
///   ([HereFor.nobody]), so the team's prompts stop asking them.
///
/// Claims and new players wait for a team admin (Q15). Every way out goes
/// back to where they came from (owner's go 2026-11-16), which then says
/// who they're waiting on; opened by its address, with nothing under it,
/// it goes to the team's chat. People an admin already linked to a player
/// (PLAYER-1) are sent straight back.
class WhoAreYouScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<WhoAreYouScreen> createState() => _WhoAreYouScreenState();
}

class _WhoAreYouScreenState extends ConsumerState<WhoAreYouScreen> {
  /// Null until they pick: `self` is "I'm a player", `guardian` is "I'm
  /// here for a player".
  PlayerRelation? _as;
  final Set<PlayerId> _picked = {};
  bool _adding = false;
  bool _saving = false;
  bool _checkedLinks = false;

  /// Back to the screen this was opened from: it's pushed, so that's a pop.
  /// With nothing under it (opened by its address), the team's chat.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/g/${widget.groupId.value}/chat');
    }
  }

  /// "I'm a coach or another adult": remembered for this team, so its card
  /// and schedule hints stop asking (PLAYER-3). Not waited for: the save
  /// reaches the server whenever it can, and leaving shouldn't hang on it.
  void _notHereForAPlayer() {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid != null) {
      unawaited(
        ref
            .read(memberRepositoryProvider)
            .setMyHereFor(widget.groupId, UserId(uid), HereFor.nobody)
            .catchError((Object e) {
              Log.warn("Saving I'm a coach or another adult failed", e);
            }),
      );
    }
    _leave();
  }

  Future<void> _run(Future<String> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final done = await action();
      if (!mounted) return;
      showAppSnackBar(context, done);
      _leave();
    } on AppFailure catch (e) {
      if (mounted) showAppSnackBar(context, playerRequestFailure(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Claims every picked player as [_as] (PLAYER-3).
  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context);
    final relation = _as!;
    await _run(() async {
      var linked = true;
      for (final id in _picked) {
        final outcome = await ref
            .read(playerRepositoryProvider)
            .claimPlayer(widget.groupId, id, relation);
        linked = linked && outcome == ClaimOutcome.linked;
      }
      return linked ? l10n.claimLinked : l10n.guardianRequestSent;
    });
  }

  /// Adds a player who isn't listed, linked as [_as] (PLAYER-4).
  Future<void> _propose(ProposedPlayer p) async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      final status = await ref
          .read(playerRepositoryProvider)
          .proposePlayer(
            widget.groupId,
            name: p.name,
            relation: p.relation,
            jerseyNumber: p.jerseyNumber,
            dateOfBirth: p.dateOfBirth,
          );
      return status == PlayerStatus.pending
          ? l10n.playerProposed
          : l10n.playerAdded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authUserProvider).value?.uid;
    final players = ref.watch(playersProvider(widget.groupId));
    final links = ref.watch(guardianLinksProvider(widget.groupId));
    final myRequests =
        ref.watch(myGuardianRequestsProvider(widget.groupId)).value ??
        const <GuardianRequest>[];
    final requested = {
      for (final r in myRequests)
        if (r.status == GuardianRequestStatus.pending) r.playerId,
    };
    final allLinks = links.value ?? const <GuardianLink>[];
    final mine = {
      for (final l in allLinks)
        if (l.uid.value == me) l.playerId,
    };
    // Already linked by an admin (PLAYER-1): nothing to ask.
    if (!_checkedLinks && links.hasValue) {
      _checkedLinks = true;
      if (mine.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leave();
        });
      }
    }
    final as = _as;
    // "I'm a player" lists players nobody claimed as themselves yet.
    final list = (players.value ?? const <Player>[])
        .where(
          (p) =>
              !mine.contains(p.id) &&
              (as != PlayerRelation.self || selfLinkOf(p.id, allLinks) == null),
        )
        .toList();
    final myName = ref.watch(myMembershipProvider(widget.groupId))?.displayName;

    Widget body;
    if (as == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.whoAreYouHelp),
          const SizedBox(height: Space.md),
          _Choice(
            icon: AppIcons.roster,
            title: l10n.whoImAPlayer,
            subtitle: l10n.whoImAPlayerHelp,
            onTap: () => setState(() => _as = PlayerRelation.self),
          ),
          _Choice(
            icon: AppIcons.family,
            title: l10n.whoImHereForAPlayer,
            subtitle: l10n.whoImHereForAPlayerHelp,
            onTap: () => setState(() => _as = PlayerRelation.guardian),
          ),
          _Choice(
            icon: AppIcons.group,
            title: l10n.imACoachOrAdult,
            onTap: _notHereForAPlayer,
          ),
        ],
      );
    } else if (_adding) {
      body = ProposePlayerForm(
        relation: as,
        name: as == PlayerRelation.self ? myName : null,
        saving: _saving,
        onSubmit: (p) => unawaited(_propose(p)),
      );
    } else {
      final self = as == PlayerRelation.self;
      // One player at most (PLAYER-3): with a claim as the player or a
      // player of their own already waiting, they can't ask again.
      final selfTaken =
          self &&
          (me == null ||
              !canStillBeAPlayer(
                UserId(me),
                links: allLinks,
                requests: myRequests,
                pendingPlayers:
                    ref.watch(myPendingPlayersProvider(widget.groupId)).value ??
                    const [],
              ));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(self ? l10n.whoPickYourself : l10n.whoAreYouHereForHelp),
          if (selfTaken) ...[
            const SizedBox(height: Space.sm),
            Text(l10n.whoAlreadyAskedAsPlayer),
          ],
          const SizedBox(height: Space.md),
          if (!players.hasValue) const LinearProgressIndicator(),
          if (players.hasValue && list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text(l10n.whoNobodyToPick),
            ),
          for (final p in list)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: requested.contains(p.id) || _picked.contains(p.id),
              onChanged: requested.contains(p.id) || selfTaken
                  ? null
                  : (v) => setState(() {
                      // You're one player at most (PLAYER-3).
                      if (self) _picked.clear();
                      if (v ?? false) _picked.add(p.id);
                      if (v != true) _picked.remove(p.id);
                    }),
              title: Text(p.displayName),
              subtitle: requested.contains(p.id)
                  ? Text(l10n.guardianRequestPending)
                  : p.jerseyNumber == null
                  ? null
                  : Text('#${p.jerseyNumber}'),
            ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _saving || _picked.isEmpty
                ? null
                : () => unawaited(_claim()),
            child: Text(
              self
                  ? l10n.claimMyself
                  : l10n.sendGuardianRequest(_picked.length),
            ),
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton(
            onPressed: _saving || selfTaken
                ? null
                : () => setState(() => _adding = true),
            child: Text(self ? l10n.addMyself : l10n.addMyPlayer),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whoAreYouHereFor),
        leading: as == null
            ? null
            : BackButton(
                onPressed: () => setState(() {
                  if (_adding) {
                    _adding = false;
                  } else {
                    _as = null;
                    _picked.clear();
                  }
                }),
              ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [body],
          ),
        ),
      ),
    );
  }
}

/// One of the three answers to "Who are you here for?" (PLAYER-3).
class _Choice extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: Space.sm),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(AppIcons.chevronRight),
      onTap: onTap,
    ),
  );
}
