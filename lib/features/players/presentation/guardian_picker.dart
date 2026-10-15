import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// What "Add a guardian" picked (PLAYER-5): someone already on the team,
/// or to invite someone by email.
sealed class GuardianPick {
  const new();
}

/// Someone on the team, linked with no email.
final class GuardianFromTeam extends GuardianPick {
  const new(this.member);

  final Membership member;
}

/// Someone to invite by email instead.
final class GuardianByEmail extends GuardianPick {
  const new();
}

/// The team members "Add a guardian" offers (PLAYER-5): everyone on the
/// team but [me] and the people already linked to the player, by name.
/// None when the team keeps its people to its admins (TEAM-3) and [isAdmin]
/// is false, so the member invites by email as before.
List<Membership> guardianCandidates(
  List<Membership> roster, {
  required Set<String> linked,
  required String? me,
  required bool isAdmin,
  required bool membersCanSeePeople,
}) {
  if (!isAdmin && !membersCanSeePeople) return const [];
  return [
    for (final m in roster)
      if (m.uid.value != me && !linked.contains(m.uid.value)) m,
  ]..sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
}

/// The list shows a search field past this many people.
const guardianPickerSearchAfter = 6;

/// Picks a guardian from [candidates], or "Invite by email" (PLAYER-5).
/// Null when canceled.
Future<GuardianPick?> pickGuardian(
  BuildContext context, {
  required List<Membership> candidates,
}) => showDialog<GuardianPick>(
  context: context,
  builder: (context) => _GuardianPickerDialog(candidates: candidates),
);

class _GuardianPickerDialog extends StatefulWidget {
  const new({required this.candidates});

  final List<Membership> candidates;

  @override
  State<_GuardianPickerDialog> createState() => _GuardianPickerDialogState();
}

class _GuardianPickerDialogState extends State<_GuardianPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final m in widget.candidates)
        if (q.isEmpty || m.displayName.toLowerCase().contains(q)) m,
    ];
    return AlertDialog(
      title: Text(l10n.addGuardian),
      contentPadding: const EdgeInsets.fromLTRB(
        Space.xl,
        Space.lg,
        Space.xl,
        0,
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addGuardianPickHelp),
            if (widget.candidates.length > guardianPickerSearchAfter)
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search),
                  hintText: l10n.searchByName,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            const SizedBox(height: Space.sm),
            Flexible(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Text(l10n.adminNoUsers),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final m in shown)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Avatar(
                              name: m.displayName,
                              colorKey: m.uid.value,
                            ),
                            title: Text(m.displayName),
                            subtitle: m.pending
                                ? Text(l10n.notJoinedYet)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(GuardianFromTeam(m)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(const GuardianByEmail()),
          icon: const Icon(AppIcons.email),
          label: Text(l10n.inviteGuardianByEmail),
        ),
      ],
    );
  }
}
