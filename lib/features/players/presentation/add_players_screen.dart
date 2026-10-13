import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/roster_parser.dart';
import 'package:battleplan/features/players/presentation/player_dialogs.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-1 and PLAYER-4 at `/g/:groupId/players/add`. Admins add one
/// player with the player's own email (optional, for an adult player) and
/// up to 4 guardians, or paste a list with one line per guardian or
/// player's email; people with accounts are linked now, new emails get an
/// account and a setup email, and a results screen follows. Members add a
/// player with how they're linked ("I am this player" or their parent or
/// guardian), pending until an admin approves it.
class AddPlayersScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends ConsumerState<AddPlayersScreen> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _position = TextEditingController();
  final _email = TextEditingController();
  final List<TextEditingController> _guardianNames = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _guardianEmails = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final _paste = TextEditingController();
  bool _pasting = false;
  bool _saving = false;
  int _guardianRows = 1;

  @override
  void dispose() {
    for (final c in [
      _name,
      _number,
      _position,
      _email,
      _paste,
      ..._guardianNames,
      ..._guardianEmails,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<NewPlayer> _single() => [
    NewPlayer(
      name: _name.text.trim(),
      jerseyNumber: _number.text.trim(),
      position: _position.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      // Name and email are both optional (PLAYER-1); a name alone is kept,
      // and the results say it couldn't be linked.
      guardians: [
        for (var i = 0; i < _guardianRows; i++)
          if (_guardianEmails[i].text.trim().isNotEmpty ||
              _guardianNames[i].text.trim().isNotEmpty)
            NewGuardian(
              name: _guardianNames[i].text.trim().isEmpty
                  ? null
                  : _guardianNames[i].text.trim(),
              email: _guardianEmails[i].text.trim().isEmpty
                  ? null
                  : _guardianEmails[i].text.trim(),
            ),
      ],
    ),
  ];

  /// Adds [players]; [skipped] are pasted lines that couldn't be read,
  /// listed with the results (PLAYER-1).
  Future<void> _add(
    List<NewPlayer> players, {
    List<String> skipped = const [],
  }) async {
    final l10n = AppLocalizations.of(context);
    if (players.isEmpty || players.any((p) => p.name.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.playerNameRequired)));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(playerRepositoryProvider)
          .addPlayers(widget.groupId, players);
      if (!mounted) return;
      // PLAYER-1: a results screen with the players added, guardians linked
      // and invited, and any problems.
      await AddResultsScreen.show(
        context,
        title: l10n.playersAddedTitle,
        sections: [
          ResultSection(l10n.resultsSummary, [
            l10n.playersAddedCount(result.playersAdded),
            l10n.guardiansLinkedCount(result.guardiansLinked),
            l10n.guardiansInvitedCount(result.guardiansInvited),
            // Players' own emails (PLAYER-1), when any were given.
            if (result.playersLinked > 0)
              l10n.playersLinkedCount(result.playersLinked),
            if (result.playersInvited > 0)
              l10n.playersInvitedCount(result.playersInvited),
          ], counted: false),
          ResultSection(l10n.guardiansWithoutEmailHeading, [
            ...result.guardiansWithoutEmail,
          ], problem: true),
          ResultSection(l10n.resultsProblems, [
            for (final p in result.problems) describeAddProblem(l10n, p),
          ], problem: true),
          ResultSection(l10n.linesSkipped, skipped, problem: true),
        ],
      );
      if (mounted) context.pop();
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (e) {
            RateLimited() => l10n.signInRateLimited,
            EmailNotVerified() => l10n.addByEmailNeedsVerified,
            InvalidInput(message: 'too-many-players') => l10n.tooManyPlayers(
              Limits.playersPerGroupMax,
            ),
            InvalidInput() => l10n.tooManyRosterLines(
              Limits.pastedRosterLinesMax,
            ),
            PermissionDenied(message: 'team-archived') => l10n.teamArchived,
            PermissionDenied() => l10n.notAllowed,
            Offline() => l10n.signInOffline,
            _ => l10n.errorAddPlayers,
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// A member's player, pending until an admin approves (PLAYER-4).
  Future<void> _propose(ProposedPlayer p) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final status = await ref
          .read(playerRepositoryProvider)
          .proposePlayer(
            widget.groupId,
            name: p.name,
            relation: p.relation,
            jerseyNumber: p.jerseyNumber,
            position: p.position,
          );
      if (!mounted) return;
      showAppSnackBar(
        context,
        status == PlayerStatus.pending ? l10n.playerProposed : l10n.playerAdded,
      );
      context.pop();
    } on AppFailure catch (e) {
      if (mounted) showAppSnackBar(context, playerRequestFailure(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamAdmin =
        ref.watch(myMembershipProvider(widget.groupId))?.isAdmin ?? false;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    if (!teamAdmin && !superAdmin) {
      final me = ref.watch(authUserProvider).value?.uid;
      // A member is a player at most once per team, counting a claim or
      // player of their own still waiting for an admin (PLAYER-3).
      final canBeSelf =
          me != null &&
          canStillBeAPlayer(
            UserId(me),
            links:
                ref.watch(guardianLinksProvider(widget.groupId)).value ??
                const [],
            requests:
                ref.watch(myGuardianRequestsProvider(widget.groupId)).value ??
                const [],
            pendingPlayers:
                ref.watch(myPendingPlayersProvider(widget.groupId)).value ??
                const [],
          );
      return Scaffold(
        appBar: AppBar(title: Text(l10n.addPlayer)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: [
                ProposePlayerForm(
                  canBeSelf: canBeSelf,
                  saving: _saving,
                  onSubmit: (p) => unawaited(_propose(p)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final parsed = parsePastedRoster(_paste.text);
    // Up to 200 lines (PLAYER-1).
    final tooManyLines = parsed.lines > Limits.pastedRosterLinesMax;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addPlayers)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.addOnePlayer)),
                  ButtonSegment(value: true, label: Text(l10n.pasteAList)),
                ],
                selected: {_pasting},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _pasting = s.first),
              ),
              const SizedBox(height: Space.xl),
              if (!_pasting) ...[
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.playerNameLabel),
                ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: l10n.jerseyNumberLabel,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: TextField(
                        controller: _position,
                        decoration: InputDecoration(
                          labelText: l10n.positionLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                // An adult player's own email links them as the player
                // (PLAYER-1), not as their own guardian.
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.playerEmailLabel,
                    helperText: l10n.playerEmailHelp,
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: Space.xl),
                Text(
                  l10n.guardiansLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (var i = 0; i < _guardianRows; i++) ...[
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: _guardianNames[i],
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.guardianNameLabel,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: _guardianEmails[i],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.guardianEmailLabel,
                    ),
                  ),
                ],
                if (_guardianRows < 4)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _guardianRows++),
                      child: Text(l10n.addAnotherGuardian),
                    ),
                  ),
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: _saving ? null : () => unawaited(_add(_single())),
                  child: Text(l10n.addPlayer),
                ),
              ] else ...[
                Text(l10n.pasteRosterHelp),
                const SizedBox(height: Space.md),
                TextField(
                  controller: _paste,
                  minLines: 6,
                  maxLines: 14,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText:
                        'Emma Rodriguez, Maria Rodriguez, maria@example.com\n'
                        'Emma Rodriguez, Luis Rodriguez, luis@example.com\n'
                        'Arjun Shah, Priya Shah, priya@example.com\n'
                        'Jared Freeman, jared@example.com',
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(l10n.pastePreview(parsed.players.length)),
                if (tooManyLines)
                  Text(
                    l10n.tooManyRosterLines(Limits.pastedRosterLinesMax),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (parsed.problems.isNotEmpty)
                  Text(
                    l10n.addProblems(parsed.problems.join('\n')),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: _saving || parsed.players.isEmpty || tooManyLines
                      ? null
                      : () => unawaited(
                          _add(parsed.players, skipped: parsed.problems),
                        ),
                  child: Text(l10n.addPlayersCount(parsed.players.length)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
