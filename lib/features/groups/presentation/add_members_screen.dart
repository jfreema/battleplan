import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/results_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Reads "Name, email" lines (or just emails), up to 100 (TEAM-7). Returns
/// the entries and the lines that couldn't be read.
({List<({String? name, String email})> entries, List<String> problems})
parsePeople(String text) {
  final entries = <({String? name, String email})>[];
  final problems = <String>[];
  final email = RegExp(r'^\S+@\S+\.\S+$');
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp('[,\t;]')).map((p) => p.trim()).toList();
    final address = parts.firstWhere(email.hasMatch, orElse: () => '');
    if (address.isEmpty) {
      problems.add(line);
      continue;
    }
    final name = parts.where((p) => p != address && p.isNotEmpty).join(' ');
    entries.add((name: name.isEmpty ? null : name, email: address));
  }
  return (entries: entries, problems: problems);
}

/// TEAM-7 at `/g/:groupId/members/add` (admins): add people by name and
/// email, one per line. Then a results summary.
class AddMembersScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends ConsumerState<AddMembersScreen> {
  final _text = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final parsed = parsePeople(_text.text);
    setState(() => _saving = true);
    try {
      final r = await ref
          .read(memberRepositoryProvider)
          .addByEmail(widget.groupId, parsed.entries);
      if (!mounted) return;
      // TEAM-7: a results screen lists who was added, who was invited,
      // and any problems.
      String person(({String name, String email}) p) =>
          p.name.isEmpty || p.name == p.email
          ? p.email
          : '${p.name} · ${p.email}';
      await AddResultsScreen.show(
        context,
        title: l10n.peopleAddedTitle,
        sections: [
          ResultSection(l10n.resultsAdded, [
            for (final p in r.addedPeople) person(p),
          ]),
          ResultSection(l10n.resultsInvited, [
            for (final p in r.invitedPeople) person(p),
          ]),
          ResultSection(l10n.resultsAlreadyMembers, [
            if (r.alreadyMembers > 0)
              l10n.alreadyMembersCount(r.alreadyMembers),
          ], counted: false),
          ResultSection(l10n.resultsProblems, [
            for (final p in parsed.problems) p,
            for (final p in r.problems) describeAddProblem(l10n, p),
          ], problem: true),
        ],
      );
      if (mounted) context.pop();
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (e) {
            EmailNotVerified() => l10n.addByEmailNeedsVerified,
            RateLimited() => l10n.signInRateLimited,
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
    final parsed = parsePeople(_text.text);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addByEmail)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Text(l10n.addPeopleHelp),
              const SizedBox(height: Space.md),
              TextField(
                controller: _text,
                minLines: 5,
                maxLines: 14,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Sam Rivera, sam@example.com\nalex@example.com',
                ),
              ),
              if (parsed.problems.isNotEmpty) ...[
                const SizedBox(height: Space.sm),
                Text(
                  l10n.addProblems(parsed.problems.join('\n')),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: Space.lg),
              FilledButton(
                onPressed:
                    _saving ||
                        parsed.entries.isEmpty ||
                        parsed.entries.length > 100
                    ? null
                    : () => unawaited(_add()),
                child: Text(l10n.addPeopleCount(parsed.entries.length)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
