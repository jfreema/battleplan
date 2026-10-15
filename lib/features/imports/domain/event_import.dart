import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';

/// The apps a team's events can come from (SPEC IMPORT-1). GameChanger
/// first; the others in ROADMAP tasks 219 to 227.
enum ImportSource {
  gamechanger('gamechanger');

  new(this.value);

  /// What the importEvents callable takes.
  final String value;
}

/// Why an entry in the calendar wasn't imported (IMPORT-4).
enum ImportSkipReason {
  /// Canceled in the other app.
  canceled,

  /// A repeat other than daily or weekly.
  repeat,

  /// No start, or one that couldn't be read.
  unreadable;

  static ImportSkipReason of(String? value) => switch (value) {
    'canceled' => canceled,
    'repeat' => repeat,
    _ => unreadable,
  };
}

/// One new event a preview found.
final class ImportedEventSample {
  const new({
    required this.title,
    required this.type,
    required this.allDay,
    required this.start,
    required this.timeZone,
    required this.place,
    this.startDate,
  });

  final String title;
  final EventType type;
  final bool allDay;
  final DateTime start;

  /// All-day events' date, 'YYYY-MM-DD', which never shifts with zones.
  final String? startDate;
  final String timeZone;
  final String place;
}

/// An entry left behind, and why.
final class SkippedImport {
  const new({required this.title, required this.reason, this.start});

  final String title;
  final DateTime? start;
  final ImportSkipReason reason;
}

/// What a preview found, or an import did (IMPORT-3, IMPORT-5).
final class EventImportResult {
  const new({
    required this.added,
    required this.alreadyImported,
    required this.past,
    required this.skippedCount,
    this.skipped = const [],
    this.sample = const [],
    this.first,
    this.last,
  });

  /// New events: to add on a preview, added on an import.
  final int added;

  /// Brought in by an earlier import, and left as they are.
  final int alreadyImported;

  /// Ended before now, and left out unless past events were asked for.
  final int past;
  final int skippedCount;

  /// The first of [skippedCount].
  final List<SkippedImport> skipped;

  /// The first of the new events, oldest first.
  final List<ImportedEventSample> sample;

  /// When the new events start: the first and the last.
  final DateTime? first;
  final DateTime? last;
}

/// Previews and runs imports into a team (SPEC §6.15, ARCH §6.13).
abstract interface class ImportRepository {
  /// Previews ([dryRun]) or imports [groupId]'s events from [source], read
  /// from the calendar link [url] or a calendar file's text [ics] (one of
  /// the two). Team admins only. Events only: RSVPs and attendance stay
  /// behind.
  Future<EventImportResult> importEvents(
    GroupId groupId, {
    required ImportSource source,
    required bool includePast,
    required bool dryRun,
    String? url,
    String? ics,
  });
}
