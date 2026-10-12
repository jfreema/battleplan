import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/roster_parser.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-1 at `/g/:groupId/players/add` (admins): add one player with up
/// to 4 guardians, or paste a list with one line per guardian. Guardians
/// with accounts are linked now; new emails get an account and, once email
/// sending is live, a setup email.
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
      guardians: [
        for (var i = 0; i < _guardianRows; i++)
          if (_guardianEmails[i].text.trim().isNotEmpty)
            NewGuardian(
              name: _guardianNames[i].text.trim(),
              email: _guardianEmails[i].text.trim(),
            ),
      ],
    ),
  ];

  Future<void> _add(List<NewPlayer> players) async {
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
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.playersAddedTitle),
          content: Text(
            [
              l10n.playersAddedCount(result.playersAdded),
              l10n.guardiansLinkedCount(result.guardiansLinked),
              l10n.guardiansInvitedCount(result.guardiansInvited),
              if (result.problems.isNotEmpty)
                l10n.addProblems(result.problems.join('\n')),
            ].join('\n'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (e) {
            RateLimited() => l10n.signInRateLimited,
            EmailNotVerified() => l10n.addByEmailNeedsVerified,
            _ => l10n.signInUnknownError,
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = parsePastedRoster(_paste.text);
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
                        'Arjun Shah, Priya Shah, priya@example.com',
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(l10n.pastePreview(parsed.players.length)),
                if (parsed.problems.isNotEmpty)
                  Text(
                    l10n.addProblems(parsed.problems.join('\n')),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: _saving || parsed.players.isEmpty
                      ? null
                      : () => unawaited(_add(parsed.players)),
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
