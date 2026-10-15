import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Imports through the importEvents, importMessages, and importDocuments
/// callables, with photos and files uploaded to Storage first (ARCH §6.13).
class FunctionsImportRepository implements ImportRepository {
  const new(this._functions, this._storage);

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  /// Calls [name] with [data]; refusals become the app's failures.
  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      return (await _functions
              .httpsCallable(
                name,
                options: HttpsCallableOptions(
                  timeout: const Duration(minutes: 2),
                ),
              )
              .call<Map<String, dynamic>>(data))
          .data;
    } on FirebaseFunctionsException catch (e) {
      throw failureOf(e.code, serverMessage(e.message));
    }
  }

  @override
  Future<EventImportResult> importEvents(
    GroupId groupId, {
    required ImportSource source,
    required bool includePast,
    required bool dryRun,
    String? url,
    String? ics,
    List<ListedEvent>? events,
  }) async => eventImportResultOf(
    await _call('importEvents', {
      'groupId': groupId.value,
      'source': source.value,
      'url': ?url,
      'ics': ?ics,
      if (events != null)
        'events': [for (final e in events) listedEventJson(e)],
      'includePast': includePast,
      'dryRun': dryRun,
    }),
  );

  @override
  Future<ChatImportResult> importMessages(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportMessage> messages,
    bool check = false,
  }) async => chatImportResultOf(
    await _call('importMessages', {
      'groupId': groupId.value,
      'source': source.value,
      'messages': [for (final m in messages) chatMessageJson(m)],
      'dryRun': check,
    }),
    missing: 'photosMissing',
  );

  @override
  Future<ChatImportResult> importDocuments(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportDocument> documents,
    bool check = false,
  }) async => chatImportResultOf(
    await _call('importDocuments', {
      'groupId': groupId.value,
      'source': source.value,
      'documents': [
        for (final d in documents)
          {
            'sourceId': d.sourceId,
            'name': d.name,
            'path': d.path,
            'sharedByName': d.sharedByName,
            'sharedAtMs': d.sharedAt.millisecondsSinceEpoch,
          },
      ],
      'dryRun': check,
    }),
    missing: 'missing',
  );

  @override
  Future<void> upload(String path, Uint8List bytes, String contentType) async {
    try {
      await _storage
          .ref(path)
          .putData(bytes, SettableMetadata(contentType: contentType));
    } on FirebaseException catch (e) {
      // Storage rules refuse uploads to a full team (STORE-4) or too big.
      throw switch (e.code) {
        'unauthorized' => const StorageFull('upload-refused'),
        'retry-limit-exceeded' || 'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<({int width, int height})> imageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (width: frame.image.width, height: frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return size;
    } on Object {
      return (width: 0, height: 0);
    }
  }
}

/// A listed event as importEvents takes it.
Map<String, dynamic> listedEventJson(ListedEvent e) => {
  'sourceId': e.sourceId,
  'title': e.title,
  'description': e.description,
  'location': e.location,
  'allDay': e.allDay,
  'startMs': e.start.millisecondsSinceEpoch,
  'endMs': e.end?.millisecondsSinceEpoch,
  'timeZone': e.timeZone,
  'canceled': e.canceled,
};

/// A message as importMessages takes it.
Map<String, dynamic> chatMessageJson(ChatImportMessage m) => {
  'sourceId': m.sourceId,
  'authorSourceId': m.authorSourceId,
  'authorName': m.authorName,
  'text': m.text,
  'createdAtMs': m.createdAt.millisecondsSinceEpoch,
  'replyToSourceId': ?m.replyToSourceId,
  'photos': [
    for (final p in m.photos)
      {'path': p.path, 'width': p.width, 'height': p.height},
  ],
};

/// importMessages' or importDocuments' answer.
ChatImportResult chatImportResultOf(
  Map<String, dynamic> d, {
  required String missing,
}) => ChatImportResult(
  added: (d['added'] as num?)?.toInt() ?? 0,
  alreadyImported: (d['alreadyImported'] as num?)?.toInt() ?? 0,
  missing: (d[missing] as num?)?.toInt() ?? 0,
  existing: {
    for (final id in (d['existing'] as List?) ?? const [])
      if (id is String) id,
  },
);

/// The app's failure for an importEvents refusal: a link or file the app
/// explains (InvalidInput with the server's word for it), a full team, a
/// closed team, too many tries, or no connection.
AppFailure failureOf(String code, String? message) => switch ((code, message)) {
  ('failed-precondition', 'storage-full') => StorageFull(message),
  ('failed-precondition', 'team-archived' || 'team-suspended') =>
    PermissionDenied(message),
  ('invalid-argument' || 'failed-precondition', _) => InvalidInput(message),
  ('permission-denied', _) => PermissionDenied(message),
  ('resource-exhausted', _) => RateLimited(message),
  ('unavailable' || 'deadline-exceeded', _) => Offline(message),
  _ => UnknownFailure('$code: $message'),
};

DateTime? _instant(Object? ms) => ms is num
    ? DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true)
    : null;

/// The callable's answer (functions/src/imports/service.ts EventImportResult).
EventImportResult eventImportResultOf(Map<String, dynamic> d) =>
    EventImportResult(
      added: (d['added'] as num).toInt(),
      alreadyImported: (d['alreadyImported'] as num?)?.toInt() ?? 0,
      past: (d['past'] as num?)?.toInt() ?? 0,
      skippedCount: (d['skippedCount'] as num?)?.toInt() ?? 0,
      first: _instant(d['firstMs']),
      last: _instant(d['lastMs']),
      skipped: [
        for (final s in (d['skipped'] as List?) ?? const [])
          if (s is Map)
            SkippedImport(
              title: '${s['title'] ?? ''}',
              start: _instant(s['startMs']),
              reason: ImportSkipReason.of(s['reason'] as String?),
            ),
      ],
      sample: [
        for (final s in (d['sample'] as List?) ?? const [])
          if (s is Map)
            ImportedEventSample(
              title: '${s['title'] ?? ''}',
              type: EventType.tryParse(s['type'] as String?) ?? EventType.other,
              allDay: s['allDay'] == true,
              start: _instant(s['startMs'])!,
              startDate: s['startDate'] as String?,
              timeZone: '${s['timeZone'] ?? 'UTC'}',
              place: '${s['place'] ?? ''}',
            ),
      ],
    );
