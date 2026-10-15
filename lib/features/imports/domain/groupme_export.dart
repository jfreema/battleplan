import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';

/// A photo in a GroupMe message: the file in the export that holds it.
final class GroupMePhoto {
  const new({required this.entry, required this.size});

  /// The file's path in the export.
  final String entry;
  final int size;

  /// 'jpg', 'png', 'gif', or 'webp'.
  String get extension => switch (_ext(entry)) {
    'jpeg' => 'jpg',
    final e => e,
  };

  String get contentType => switch (extension) {
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

/// A message someone wrote in the group (IMPORT-9).
final class GroupMeMessage {
  const new({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.photos = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  /// The message this one replies to.
  final String? replyToId;
  final List<GroupMePhoto> photos;
}

/// A file shared in the group, to become a team document (IMPORT-9).
final class GroupMeFile {
  const new({
    required this.id,
    required this.name,
    required this.entry,
    required this.size,
    required this.contentType,
    required this.sharedByName,
    required this.sharedAt,
  });

  final String id;
  final String name;

  /// The file's path in the export.
  final String entry;
  final int size;
  final String contentType;
  final String sharedByName;
  final DateTime sharedAt;
}

/// What an import of the group leaves behind, and why (IMPORT-3, IMPORT-4).
final class GroupMeLeftOut {
  const new({
    this.systemMessages = 0,
    this.videos = 0,
    this.polls = 0,
    this.photosNotInExport = 0,
    this.filesNotInExport = 0,
    this.filesUnsupported = 0,
    this.filesTooLarge = 0,
  });

  /// GroupMe's own lines: who joined, renamed the group, and so on.
  final int systemMessages;
  final int videos;

  /// Polls' questions come along as messages; their options and votes
  /// don't.
  final int polls;

  /// Photos and files messages mention that the export doesn't hold.
  final int photosNotInExport;
  final int filesNotInExport;

  /// Shared files of a kind Documents doesn't take, or over 10 MB.
  final int filesUnsupported;
  final int filesTooLarge;

  bool get isEmpty =>
      systemMessages +
          videos +
          polls +
          photosNotInExport +
          filesNotInExport +
          filesUnsupported +
          filesTooLarge ==
      0;
}

/// One group in a GroupMe data export.
final class GroupMeGroup {
  const new({
    required this.id,
    required this.name,
    required this.messages,
    required this.files,
    required this.events,
    required this.leftOut,
  });

  final String id;
  final String name;

  /// People's messages, oldest first.
  final List<GroupMeMessage> messages;
  final List<GroupMeFile> files;
  final List<ListedEvent> events;
  final GroupMeLeftOut leftOut;

  int get photoCount => messages.fold(0, (n, m) => n + m.photos.length);

  int get photoBytes =>
      messages.fold(0, (n, m) => m.photos.fold(n, (a, p) => a + p.size));

  int get fileBytes => files.fold(0, (n, f) => n + f.size);

  /// When the first and last messages were sent.
  DateTime? get first => messages.isEmpty ? null : messages.first.createdAt;
  DateTime? get last => messages.isEmpty ? null : messages.last.createdAt;
}

/// A GroupMe data export, read on the admin's device (IMPORT-9).
final class GroupMeExport {
  const new({required this.groups, required this._read});

  /// The groups it holds, with messages; direct messages aren't teams.
  final List<GroupMeGroup> groups;
  final Uint8List? Function(String entry) _read;

  /// The bytes of a photo or file in the export, or null if it's missing.
  Uint8List? bytesOf(String entry) => _read(entry);
}

String _ext(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
const _videoExtensions = {'mp4', 'mov', 'm4v', 'webm', '3gp'};

/// Why a file isn't a GroupMe export.
final class NotGroupMeExport implements Exception {
  const new(this.reason);

  /// 'not-a-zip'; 'not-an-export', a zip with no chats in it; or
  /// 'no-groups', an export with direct messages but no group chats.
  final String reason;

  @override
  String toString() => 'NotGroupMeExport($reason)';
}

/// Reads GroupMe's data export (web.groupme.com, Export Data): a zip with
/// a folder per chat, named for the group's ID, holding conversation.json
/// (the group), message.json (its messages, newest first, as GroupMe's API
/// gives them), and gallery/ (photos, videos, and shared files, each named
/// for its message: `<messageId>_<size>.<hash>.<ext>`, or
/// `<messageId>_<fileName>`). Direct messages (folders named `<id>+<id>`)
/// aren't teams and are left out. Messages in the chat name events but don't give their times,
/// so events come from the export's calendar data, wherever it is: lists of
/// objects with GroupMe's event fields (event_id, name, start_at, end_at,
/// is_all_day, timezone, location). Throws [NotGroupMeExport].
GroupMeExport readGroupMeExport(Uint8List zip) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zip);
  } on Object {
    throw const NotGroupMeExport('not-a-zip');
  }
  final entries = <String, ArchiveFile>{
    for (final f in archive.files)
      if (f.isFile) f.name.replaceAll(r'\', '/'): f,
  };
  final chats = <String>{
    for (final path in entries.keys)
      if (_base(path) == 'message.json') _dir(path),
  };
  if (chats.isEmpty) throw const NotGroupMeExport('not-an-export');
  final folders = chats.where((d) => !_base(d).contains('+'));
  final calendar = _calendarEvents(entries);
  final groups = [
    for (final folder in folders) ?_group(folder, entries, calendar),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (groups.isEmpty) throw const NotGroupMeExport('no-groups');
  return GroupMeExport(
    groups: groups,
    read: (entry) => entries[entry]?.readBytes(),
  );
}

String _base(String path) => path.split('/').where((p) => p.isNotEmpty).last;

String _dir(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i);
}

Object? _json(ArchiveFile? f) {
  final bytes = f?.readBytes();
  if (bytes == null) return null;
  try {
    return jsonDecode(utf8.decode(bytes, allowMalformed: true));
  } on FormatException {
    return null;
  }
}

/// [value] as an ID the import callables take: GroupMe's are digits.
String _id(Object? value) {
  final s = '${value ?? ''}'.trim().replaceAll(RegExp('[^A-Za-z0-9_.:-]'), '_');
  return s.length > 64 ? s.substring(0, 64) : s;
}

DateTime? _seconds(Object? value) {
  if (value is! num || value <= 0) return null;
  // Seconds, or milliseconds from a newer export.
  final ms = value > 1e12 ? value.toInt() : (value * 1000).toInt();
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

GroupMeGroup? _group(
  String folder,
  Map<String, ArchiveFile> entries,
  Map<String, List<ListedEvent>> calendar,
) {
  final prefix = folder.isEmpty ? '' : '$folder/';
  final id = _base(folder.isEmpty ? 'export' : folder);
  final conversation = _json(entries['${prefix}conversation.json']);
  final name = switch (conversation) {
    {'name': final String n} when n.trim().isNotEmpty => n.trim(),
    _ => id,
  };
  var raw = _json(entries['${prefix}message.json']);
  if (raw case {'response': {'messages': final List<Object?> list}}) {
    raw = list;
  }
  if (raw is! List) return null;

  // The gallery's files, by the message they belong to.
  final gallery = <String, List<String>>{};
  for (final path in entries.keys) {
    if (!path.startsWith('${prefix}gallery/')) continue;
    final file = _base(path);
    final cut = file.indexOf('_');
    if (cut <= 0) continue;
    (gallery[file.substring(0, cut)] ??= []).add(path);
  }
  final used = <String>{};

  var system = 0;
  var videos = 0;
  var polls = 0;
  var photosMissing = 0;
  var filesMissing = 0;
  var unsupported = 0;
  var tooLarge = 0;
  final messages = <GroupMeMessage>[];
  final files = <GroupMeFile>[];
  for (final m in raw) {
    if (m is! Map) continue;
    final id = _id(m['id']);
    final at = _seconds(m['created_at']);
    if (id.isEmpty || at == null || m['deleted_at'] != null) continue;
    final sender = '${m['sender_type'] ?? 'user'}';
    if (m['system'] == true || sender == 'system' || sender == 'service') {
      system++;
      continue;
    }
    final authorName = switch (m['name']) {
      final String n when n.trim().isNotEmpty => n.trim(),
      _ => 'GroupMe member',
    };
    var text = switch (m['text']) {
      final String t => t,
      _ => '',
    };
    String? replyTo;
    final photos = <GroupMePhoto>[];
    final attachments = switch (m['attachments']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    for (final a in attachments) {
      if (a is! Map) continue;
      switch (a['type']) {
        case 'image' || 'linked_image':
          final entry = _photoEntry(id, '${a['url'] ?? ''}', gallery, used);
          if (entry == null) {
            photosMissing++;
          } else {
            used.add(entry);
            photos.add(GroupMePhoto(entry: entry, size: entries[entry]!.size));
          }
        case 'video':
          videos++;
        case 'poll':
          polls++;
        case 'reply':
          final to = _id(a['reply_id'] ?? a['base_reply_id']);
          if (to.isNotEmpty) replyTo = to;
        case 'location':
          // The place's name stays with the message; the pin doesn't.
          if (a['name'] case final String place when place.trim().isNotEmpty) {
            text = text.trim().isEmpty ? '📍 $place' : '$text\n📍 $place';
          }
        case 'emoji':
          // GroupMe's own emoji are placeholders only its apps draw.
          text = text.replaceAll('�', '').trim();
        case 'file':
          final entry = _fileEntry(id, gallery, used);
          if (entry == null) {
            filesMissing++;
            continue;
          }
          used.add(entry);
          final fileName = _base(entry).substring(id.length + 1);
          final type = documentTypeOf(fileName);
          final size = entries[entry]!.size;
          if (type == null) {
            unsupported++;
          } else if (size > maxDocumentBytes) {
            tooLarge++;
          } else {
            files.add(
              GroupMeFile(
                id: '${id}_${files.length}',
                name: fileName,
                entry: entry,
                size: size,
                contentType: type,
                sharedByName: authorName,
                sharedAt: at,
              ),
            );
          }
      }
    }
    if (text.trim().isEmpty && photos.isEmpty) continue;
    messages.add(
      GroupMeMessage(
        id: id,
        authorId: _id(m['sender_id'] ?? m['user_id']).ifEmpty('unknown'),
        authorName: authorName,
        text: text,
        createdAt: at,
        replyToId: replyTo,
        photos: photos,
      ),
    );
  }
  // Oldest first; GroupMe lists newest first.
  messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  files.sort((a, b) => a.sharedAt.compareTo(b.sharedAt));
  return GroupMeGroup(
    id: id,
    name: name,
    messages: messages,
    files: files,
    events: calendar[id] ?? calendar[''] ?? const [],
    leftOut: GroupMeLeftOut(
      systemMessages: system,
      videos: videos,
      polls: polls,
      photosNotInExport: photosMissing,
      filesNotInExport: filesMissing,
      filesUnsupported: unsupported,
      filesTooLarge: tooLarge,
    ),
  );
}

/// The gallery file for message [id]'s photo at [url]
/// (`https://i.groupme.com/1200x1200.jpeg.<hash>` is
/// `<id>_1200x1200.<hash>.jpeg`), or its next unused photo.
String? _photoEntry(
  String id,
  String url,
  Map<String, List<String>> gallery,
  Set<String> used,
) {
  final candidates = [
    for (final e in gallery[id] ?? const <String>[])
      if (!used.contains(e) && _imageExtensions.contains(_ext(e))) e,
  ];
  final segment = Uri.tryParse(url)?.pathSegments.lastOrNull ?? '';
  final parts = segment.split('.');
  final hash = parts.length >= 3 ? parts.sublist(2).join('.') : '';
  if (hash.isNotEmpty) {
    for (final e in candidates) {
      if (_base(e).contains(hash)) return e;
    }
  }
  return candidates.firstOrNull;
}

/// The gallery file shared with message [id]: `<id>_<file name>`, not a
/// photo or a video.
String? _fileEntry(
  String id,
  Map<String, List<String>> gallery,
  Set<String> used,
) {
  for (final e in gallery[id] ?? const <String>[]) {
    if (used.contains(e)) continue;
    final ext = _ext(e);
    final media =
        RegExp(r'^\d+_\d+x\d+\.').hasMatch(_base(e)) ||
        _videoExtensions.contains(ext);
    if (!media) return e;
  }
  return null;
}

/// Events in the export's calendar data, by the group they belong to (''
/// when it doesn't say). Any JSON other than the chat's own files is
/// searched for lists of GroupMe events.
Map<String, List<ListedEvent>> _calendarEvents(
  Map<String, ArchiveFile> entries,
) {
  final out = <String, Map<String, ListedEvent>>{};
  for (final MapEntry(key: path, value: file) in entries.entries) {
    final name = _base(path);
    if (!name.endsWith('.json') ||
        name == 'message.json' ||
        name == 'conversation.json' ||
        path.contains('/likes/') ||
        path.startsWith('likes/')) {
      continue;
    }
    final folder = _base(_dir(path).isEmpty ? '_' : _dir(path));
    void visit(Object? node) {
      if (node is List) {
        node.forEach(visit);
      } else if (node is Map) {
        final event = _listedEvent(node);
        if (event != null) {
          final group = _id(node['conversation_id'] ?? node['group_id']);
          final key = group.isNotEmpty
              ? group
              : (RegExp(r'^\d+$').hasMatch(folder) ? folder : '');
          (out[key] ??= {})[event.sourceId] = event;
        } else {
          node.values.forEach(visit);
        }
      }
    }

    // Skip anything far too big to be a team's calendar.
    if (file.size <= 20 * 1024 * 1024) visit(_json(file));
  }
  return {
    for (final MapEntry(:key, :value) in out.entries)
      key: value.values.toList()..sort((a, b) => a.start.compareTo(b.start)),
  };
}

/// [m] as an event, if it has GroupMe's event fields.
ListedEvent? _listedEvent(Map<Object?, Object?> m) {
  final start = switch (m['start_at']) {
    final String s => DateTime.tryParse(s),
    _ => null,
  };
  final title = m['name'];
  final id = _id(m['event_id'] ?? m['id']);
  if (start == null || title is! String || id.isEmpty) return null;
  final end = switch (m['end_at']) {
    final String s => DateTime.tryParse(s),
    _ => null,
  };
  final place = switch (m['location']) {
    {'name': final Object? n, 'address': final Object? a} => [
      if (n is String && n.trim().isNotEmpty) n.trim(),
      if (a is String && a.trim().isNotEmpty) a.trim(),
    ].join(', '),
    {'name': final String n} => n.trim(),
    final String s => s.trim(),
    _ => '',
  };
  return ListedEvent(
    sourceId: id,
    title: title.trim(),
    description: switch (m['description']) {
      final String d => d.trim(),
      _ => '',
    },
    location: place,
    allDay: m['is_all_day'] == true,
    start: start.toUtc(),
    end: end?.toUtc(),
    timeZone: switch (m['timezone']) {
      final String z when z.contains('/') => z,
      _ => null,
    },
    canceled: m['deleted_at'] != null || m['canceled_at'] != null,
  );
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
