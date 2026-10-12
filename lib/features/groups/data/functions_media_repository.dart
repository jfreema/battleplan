import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/domain/media_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Media through `listTeamMedia` and `deleteTeamMedia` (ARCH §6.11): only
/// Functions list the bucket and know what each file belongs to.
class FunctionsMediaRepository implements MediaRepository {
  new(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<TeamMedia> list(GroupId groupId) async => teamMediaFromCallable(
    await _call('listTeamMedia', {'groupId': groupId.value}),
  );

  @override
  Future<void> delete(GroupId groupId, String path) =>
      _call('deleteTeamMedia', {'groupId': groupId.value, 'path': path});

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>?>(data);
      return result.data ?? const {};
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'not-found' => NotFound(e.message),
        'invalid-argument' => InvalidInput(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}

/// What `listTeamMedia` returns: `{items, truncated, storageBytes,
/// storageQuotaBytes}` (functions/src/teams/media.ts), largest first.
TeamMedia teamMediaFromCallable(Map<String, Object?> d) => TeamMedia(
  items: [
    for (final x
        in ((d['items'] as List?) ?? const []).cast<Map<Object?, Object?>>())
      mediaItemFromCallable(x.cast<String, Object?>()),
  ]..sort((a, b) => b.size.compareTo(a.size)),
  truncated: d['truncated'] == true,
  storageBytes: (d['storageBytes'] as num?)?.toInt() ?? 0,
  storageQuotaBytes: (d['storageQuotaBytes'] as num?)?.toInt() ?? 0,
);

/// One `listTeamMedia` item. Unknown kinds read as [MediaKind.other], so a
/// newer server never breaks the list.
MediaItem mediaItemFromCallable(Map<String, Object?> x) => MediaItem(
  path: x['path']! as String,
  size: (x['size'] as num?)?.toInt() ?? 0,
  kind: MediaKind.values.asNameMap()[x['kind']] ?? MediaKind.other,
  contentType: x['contentType'] as String?,
  createdAt: switch (x['createdAt']) {
    final String iso => DateTime.tryParse(iso),
    final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
    _ => null,
  },
  messageId: x['messageId'] as String?,
  authorName: x['authorName'] as String?,
  current: x['current'] as bool?,
);
