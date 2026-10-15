import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Imports through the importEvents callable (ARCH §6.13).
class FunctionsImportRepository implements ImportRepository {
  const new(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<EventImportResult> importEvents(
    GroupId groupId, {
    required ImportSource source,
    required bool includePast,
    required bool dryRun,
    String? url,
    String? ics,
  }) async {
    final Map<String, dynamic> d;
    try {
      d =
          (await _functions
                  .httpsCallable(
                    'importEvents',
                    options: HttpsCallableOptions(
                      timeout: const Duration(minutes: 2),
                    ),
                  )
                  .call<Map<String, dynamic>>({
                    'groupId': groupId.value,
                    'source': source.value,
                    'url': ?url,
                    'ics': ?ics,
                    'includePast': includePast,
                    'dryRun': dryRun,
                  }))
              .data;
    } on FirebaseFunctionsException catch (e) {
      throw failureOf(e.code, serverMessage(e.message));
    }
    return eventImportResultOf(d);
  }
}

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
