import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The signed-in person's teams that need a new owner if they leave
/// (AUTH-10): the ones they own that aren't archived.
List<MyTeam> ownedTeams(List<MyTeam> teams) => [
  for (final t in teams)
    if (t.membership.role == MemberRole.owner && !t.group.isArchived) t,
];

/// AUTH-10: before deleting the account, an owner picks a new owner for
/// each team they own. A team left on "Automatic" goes to its
/// longest-serving admin, otherwise its longest-serving member (or is
/// archived when nobody else is on it). Returns team ID → picked member,
/// or null if they cancelled.
Future<Map<String, String>?> pickNewOwners(
  BuildContext context,
  List<MyTeam> teams,
) => showDialog<Map<String, String>>(
  context: context,
  builder: (_) => NewOwnersDialog(teams: teams),
);

class NewOwnersDialog extends ConsumerStatefulWidget {
  const new({required this.teams, super.key});

  final List<MyTeam> teams;

  @override
  ConsumerState<NewOwnersDialog> createState() => _NewOwnersDialogState();
}

class _NewOwnersDialogState extends ConsumerState<NewOwnersDialog> {
  final _picks = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newOwnersTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.newOwnersBody),
              for (final team in widget.teams) ...[
                const SizedBox(height: Space.lg),
                _teamPicker(l10n, team),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({..._picks}),
          child: Text(l10n.activateContinue),
        ),
      ],
    );
  }

  Widget _teamPicker(AppLocalizations l10n, MyTeam team) {
    final groupId = team.group.id;
    final me = team.membership.uid;
    final others = [
      for (final m
          in ref.watch(rosterProvider(groupId)).value ?? const <Membership>[])
        if (m.uid != me && !m.pending) m,
    ];
    return DropdownButtonFormField<String>(
      initialValue: _picks[groupId.value] ?? '',
      isExpanded: true,
      decoration: InputDecoration(labelText: team.group.name),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            others.isEmpty ? l10n.newOwnerNobody : l10n.newOwnerAutomatic,
          ),
        ),
        for (final m in others)
          DropdownMenuItem(
            value: m.uid.value,
            child: Text(m.displayName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: others.isEmpty
          ? null
          : (v) => setState(() {
              if (v == null || v.isEmpty) {
                _picks.remove(groupId.value);
              } else {
                _picks[groupId.value] = v;
              }
            }),
    );
  }
}
