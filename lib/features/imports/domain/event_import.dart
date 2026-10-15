import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';

/// The apps a team's chat, documents, and events can come from (SPEC
/// IMPORT-1, IMPORT-7 to IMPORT-9): GroupMe's data export, and TeamReach's
/// and GameChanger's calendar links.
enum ImportSource {
  groupme('groupme', 'GroupMe'),
  teamreach('teamreach', 'TeamReach'),
  gamechanger('gamechanger', 'GameChanger');

  new(this.value, this.label);

  /// What the import callables take.
  final String value;

  /// The app's name, which isn't translated.
  final String label;

  /// Whether the events come from a calendar link (or a calendar file),
  /// and only events can be imported. GroupMe's come from its export.
  bool get fromCalendarLink => this != groupme;
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

/// Previews and runs imports into a team (SPEC §6.15, ARCH §6.13). Team
/// admins only.
abstract interface class ImportRepository {
  /// Previews ([dryRun]) or imports [groupId]'s events from [source]: read
  /// from a calendar app's link [url] or calendar file [ics], or GroupMe's
  /// [events] read from its export (one of the three). RSVPs and attendance
  /// stay behind.
  Future<EventImportResult> importEvents(
    GroupId groupId, {
    required ImportSource source,
    required bool includePast,
    required bool dryRun,
    String? url,
    String? ics,
    List<ListedEvent>? events,
  });

  /// Adds a batch of chat history, oldest first, each message's photos
  /// already uploaded to its folder (IMPORT-9). A [check] writes nothing
  /// and says which are already here, so photos go up only for new ones.
  Future<ChatImportResult> importMessages(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportMessage> messages,
    bool check = false,
  });

  /// Adds shared files as the team's documents, each already uploaded to
  /// its document's folder (IMPORT-9). A [check] works as for messages.
  Future<ChatImportResult> importDocuments(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportDocument> documents,
    bool check = false,
  });

  /// Uploads an imported photo or file to [path] in the team's storage.
  /// Storage rules check the room and size, as for any upload.
  Future<void> upload(String path, Uint8List bytes, String contentType);

  /// A photo's width and height, or zeros when it can't be read.
  Future<({int width, int height})> imageSize(Uint8List bytes);
}
