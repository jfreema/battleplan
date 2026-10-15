import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// What a finished import did (IMPORT-5): a line per kind, and where to go
/// to see it.
class ImportReport {
  const new({required this.lines, required this.actions});

  final List<String> lines;
  final List<({String label, String route})> actions;
}

/// A button's spinner while it works.
class ButtonSpinner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

/// Why an import was refused, in words (IMPORT-1, IMPORT-5).
String importFailureText(
  AppLocalizations l10n,
  AppFailure e,
  ImportSource source,
) => switch (e) {
  InvalidInput(message: 'bad-link') => l10n.importBadLink(source.label),
  InvalidInput(message: 'calendar-unreachable') => l10n.importUnreachable,
  InvalidInput(message: 'not-a-calendar') => l10n.importNotCalendar(
    source.label,
  ),
  InvalidInput(message: 'calendar-too-large') => l10n.importTooLarge,
  InvalidInput(message: 'too-many-events') => l10n.importTooMany,
  StorageFull() => l10n.importStorageFull,
  PermissionDenied(message: 'team-archived') => l10n.teamArchived,
  PermissionDenied() => l10n.notAllowed,
  RateLimited() => l10n.signInRateLimited,
  Offline() => l10n.signInOffline,
  _ => l10n.importFailed,
};

/// When an event starts, in its own zone, as the schedule shows it.
String _when(BuildContext context, ImportedEventSample e) {
  final locale = Localizations.localeOf(context).toString();
  if (e.allDay && e.startDate != null) {
    return DateFormat.MMMEd(locale).format(DateTime.parse(e.startDate!));
  }
  final wall = ZonedTime.isKnown(e.timeZone)
      ? ZonedTime.wallClock(e.timeZone, e.start)
      : e.start.toLocal();
  return DateFormat.MMMEd(locale).add_jm().format(wall);
}

/// The events importing would add, with what it leaves and why (IMPORT-3).
class EventPreview extends StatelessWidget {
  const new({required this.result, required this.source, super.key});

  final EventImportResult result;
  final ImportSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final r = result;
    final lines = [
      if (r.alreadyImported > 0) l10n.importAlready(r.alreadyImported),
      if (r.past > 0) l10n.importPast(r.past),
      if (r.skippedCount > 0) l10n.importSkipped(r.skippedCount),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          r.added == 0 ? l10n.importNothingNew : l10n.importToAdd(r.added),
          style: theme.textTheme.titleMedium,
        ),
        if (r.first case final first?)
          Text(
            r.last == null || r.last == first
                ? dates.formatMediumDate(first.toLocal())
                : '${dates.formatMediumDate(first.toLocal())} – '
                      '${dates.formatMediumDate(r.last!.toLocal())}',
          ),
        if (lines.isNotEmpty) Text(lines.join(' · ')),
        const SizedBox(height: Space.sm),
        for (final e in r.sample)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(typeIcon(e.type), color: typeColor(context, e.type)),
            title: Text(e.title),
            subtitle: Text(
              [_when(context, e), if (e.place.isNotEmpty) e.place].join(' · '),
            ),
          ),
        if (r.added > r.sample.length)
          Text(l10n.importAndMore(r.added - r.sample.length)),
        if (r.skipped.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(l10n.importSkippedTitle, style: theme.textTheme.titleSmall),
          for (final s in r.skipped)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.title.isEmpty ? l10n.importUntitled : s.title),
              subtitle: Text(switch (s.reason) {
                ImportSkipReason.canceled => l10n.importSkipCanceled(
                  source.label,
                ),
                ImportSkipReason.repeat => l10n.importSkipRepeat,
                ImportSkipReason.unreadable => l10n.importSkipUnreadable,
              }),
            ),
        ],
      ],
    );
  }
}
