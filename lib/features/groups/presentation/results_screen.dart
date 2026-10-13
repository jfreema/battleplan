import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One part of a results screen: a heading with its count, and the lines
/// under it. [problem] parts are drawn in the error color; [counted] puts
/// the number of lines after the heading.
class ResultSection {
  const new(
    this.heading,
    this.lines, {
    this.problem = false,
    this.counted = true,
  });

  final String heading;
  final List<String> lines;
  final bool problem;
  final bool counted;
}

/// What happened after adding people (TEAM-7) or players (PLAYER-1): who
/// was added, who was invited, and any problems, one list per part. Done
/// closes it. Empty parts aren't shown.
class AddResultsScreen extends StatelessWidget {
  const new({required this.title, required this.sections, super.key});

  final String title;
  final List<ResultSection> sections;

  /// Shows the screen over the current one and waits for Done.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<ResultSection> sections,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AddResultsScreen(title: title, sections: sections),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shown = sections.where((s) => s.lines.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(Space.lg),
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.done),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.lg),
            children: [
              if (shown.isEmpty) Text(l10n.resultsNothingAdded),
              for (final s in shown) ...[
                Padding(
                  padding: const EdgeInsets.only(top: Space.lg),
                  child: Text(
                    s.counted ? '${s.heading} (${s.lines.length})' : s.heading,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: s.problem ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                for (final line in s.lines)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      s.problem ? AppIcons.warning : AppIcons.check,
                      color: s.problem ? theme.colorScheme.error : null,
                    ),
                    title: Text(line),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A server problem line in words: "lee@example.com (too-many-teams)"
/// becomes "lee@example.com: already on 100 teams" (TEAM-2), and a link
/// the PLAYER-3 limits refused says which one.
String describeAddProblem(AppLocalizations l10n, String problem) {
  final reasons = <String, String Function(String)>{
    'too-many-teams': l10n.problemOnTooManyTeams,
    'already-a-player': l10n.problemAlreadyAPlayer,
    'player-already-claimed': l10n.problemPlayerAlreadyClaimed,
    'too-many-guardians': l10n.problemTooManyGuardians,
    'already-linked': l10n.problemAlreadyLinked,
  };
  for (final MapEntry(key: code, value: say) in reasons.entries) {
    final suffix = ' ($code)';
    if (problem.endsWith(suffix)) {
      return say(problem.substring(0, problem.length - suffix.length));
    }
  }
  return problem;
}
