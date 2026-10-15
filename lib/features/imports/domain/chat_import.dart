import 'dart:convert';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:crypto/crypto.dart';

/// What an imported item is in Battleplan.
enum ImportItemKind { message, document }

/// An imported message's or document's ID in Battleplan: the same for the
/// same team, app, and item, so importing again adds only what's new
/// (IMPORT-5). The server works it out the same way (functions/src/
/// imports/messages.ts importedItemId); the app needs it first, to upload
/// photos and files to the item's own folder.
String importedItemId(
  GroupId groupId,
  ImportSource source,
  ImportItemKind kind,
  String sourceId,
) {
  final key = '${groupId.value}\n${source.value}\n${kind.name}\n$sourceId';
  return 'imp-${sha256.convert(utf8.encode(key)).toString().substring(0, 28)}';
}

/// A photo already uploaded to its message's folder.
final class ChatImportPhoto {
  const new({required this.path, required this.width, required this.height});

  final String path;
  final int width;
  final int height;
}

/// A message from another app, as the importMessages callable takes it
/// (IMPORT-9).
final class ChatImportMessage {
  const new({
    required this.sourceId,
    required this.authorSourceId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.replyToSourceId,
    this.photos = const [],
  });

  final String sourceId;
  final String authorSourceId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final String? replyToSourceId;
  final List<ChatImportPhoto> photos;
}

/// A file shared in another app, already uploaded to its document's
/// folder, as the importDocuments callable takes it (IMPORT-9).
final class ChatImportDocument {
  const new({
    required this.sourceId,
    required this.name,
    required this.path,
    required this.sharedByName,
    required this.sharedAt,
  });

  final String sourceId;
  final String name;
  final String path;
  final String sharedByName;
  final DateTime sharedAt;
}

/// What one batch of messages or documents did, or would do.
final class ChatImportResult {
  const new({
    required this.added,
    required this.alreadyImported,
    this.missing = 0,
    this.existing = const {},
  });

  /// New ones: to add on a check, added otherwise.
  final int added;
  final int alreadyImported;

  /// Photos or files that weren't uploaded, left out.
  final int missing;

  /// On a check: the source IDs already imported.
  final Set<String> existing;
}

/// An event from an app's own data rather than a calendar (GroupMe's), as
/// the importEvents callable takes it (IMPORT-9).
final class ListedEvent {
  const new({
    required this.sourceId,
    required this.title,
    required this.allDay,
    required this.start,
    this.end,
    this.description = '',
    this.location = '',
    this.timeZone,
    this.canceled = false,
  });

  final String sourceId;
  final String title;
  final String description;

  /// The place on one line: its name, then the street address.
  final String location;
  final bool allDay;
  final DateTime start;
  final DateTime? end;

  /// IANA, or null for the team's.
  final String? timeZone;
  final bool canceled;
}

/// The largest file Documents takes (STORE-1, storage.rules isDocument).
const int maxDocumentBytes = 10 * 1024 * 1024;

/// The type Documents stores a file as, by its extension, or null for a
/// kind it doesn't take (storage.rules isDocument).
String? documentTypeOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (fileName.substring(dot + 1).toLowerCase()) {
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    _ => null,
  };
}

/// The extensions Documents takes, for a file picker.
const documentExtensions = [
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', //
  'jpg', 'jpeg', 'png', 'gif', 'webp',
];

/// A file's ID in its source when the source has none: the same file (by
/// name and size) is the same document, so choosing it again adds nothing.
String fileSourceId(String name, int size) =>
    sha256.convert(utf8.encode('$name\n$size')).toString().substring(0, 32);
