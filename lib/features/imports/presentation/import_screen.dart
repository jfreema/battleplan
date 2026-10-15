import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/presentation/calendar_import.dart';
import 'package:battleplan/features/imports/presentation/groupme_import.dart';
import 'package:battleplan/features/imports/presentation/import_parts.dart';
import 'package:battleplan/features/imports/presentation/teamsnap_import.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Import at `/g/:groupId/import` (SPEC §6.15): the team's admins bring
/// their team over from another app. GroupMe's messages, documents, and
/// events come from its data export (IMPORT-9); TeamSnap's schedule,
/// players, and documents from its calendar link, roster export, and
/// files (IMPORT-11); TeamReach's,
/// GameChanger's, and Google Calendar's events from their calendar links
/// (IMPORT-7, IMPORT-8, IMPORT-10).
/// Choose the app, then what to bring, preview it, and import. Importing
/// again adds only what's new.
class ImportScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportSource? _source;
  bool _busy = false;
  ImportReport? _done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final admin =
        (ref.watch(myMembershipProvider(widget.groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final Widget body;
    if (!admin) {
      body = EmptyState(icon: AppIcons.block, message: l10n.notAllowed);
    } else if (_done case final done?) {
      body = _Done(report: done);
    } else {
      final source = _source;
      void done(ImportReport r) => setState(() => _done = r);
      body = ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          Text(l10n.importIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.lg),
          Text(l10n.importFrom, style: theme.textTheme.titleSmall),
          // The app it comes from (IMPORT-1).
          RadioGroup<ImportSource>(
            groupValue: source,
            onChanged: (s) {
              if (!_busy) setState(() => _source = s);
            },
            child: Column(
              children: [
                for (final s in ImportSource.values)
                  RadioListTile<ImportSource>(
                    contentPadding: EdgeInsets.zero,
                    value: s,
                    enabled: !_busy,
                    title: Text(s.label),
                    subtitle: Text(switch (s) {
                      ImportSource.groupme => l10n.importGroupMeHelp,
                      ImportSource.teamsnap => l10n.importTeamSnapHelp,
                      ImportSource.teamreach => l10n.importTeamReachHelp,
                      ImportSource.gamechanger => l10n.importGameChangerHelp,
                      ImportSource.google => l10n.importGoogleHelp,
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          // A fresh form for each app, so nothing carries over.
          if (source == ImportSource.groupme)
            GroupMeImportForm(
              key: const ValueKey(ImportSource.groupme),
              groupId: widget.groupId,
              onBusy: (b) => setState(() => _busy = b),
              onDone: done,
            )
          else if (source == ImportSource.teamsnap)
            TeamSnapImportForm(
              key: const ValueKey(ImportSource.teamsnap),
              groupId: widget.groupId,
              onBusy: (b) => setState(() => _busy = b),
              onDone: done,
            )
          else if (source != null)
            CalendarImportForm(
              key: ValueKey(source),
              groupId: widget.groupId,
              source: source,
              onBusy: (b) => setState(() => _busy = b),
              onDone: done,
            ),
        ],
      );
    }
    return PopScope(
      // Leaving in the middle would stop the import partway.
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.importTitle)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// The report once it's done (IMPORT-5), and the ways to see it.
class _Done extends StatelessWidget {
  const new({required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const Icon(AppIcons.going, size: 48),
        const SizedBox(height: Space.md),
        for (final line in report.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: Space.xl),
        for (final (i, a) in report.actions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: i == 0
                ? FilledButton(
                    onPressed: () => context.go(a.route),
                    child: Text(a.label),
                  )
                : OutlinedButton(
                    onPressed: () => context.go(a.route),
                    child: Text(a.label),
                  ),
          ),
      ],
    );
  }
}
