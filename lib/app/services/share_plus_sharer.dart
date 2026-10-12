import 'dart:typed_data';

import 'package:battleplan/core/services/sharer.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:share_plus/share_plus.dart';

/// `share_plus` behind [Sharer].
class SharePlusSharer implements Sharer {
  const new();

  @override
  Future<bool> shareLink(Uri uri, {String? subject}) =>
      _share(ShareParams(uri: uri, subject: subject));

  @override
  Future<bool> shareImage(Uint8List bytes, {required String name}) => _share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/jpeg', name: name)],
    ),
  );

  @override
  Future<bool> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) => _share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType, name: name)],
      fileNameOverrides: [name],
    ),
  );

  Future<bool> _share(ShareParams params) async {
    try {
      final result = await SharePlus.instance.share(params);
      return sharedFrom(result.status, web: kIsWeb);
    } on Object {
      return false;
    }
  }
}

/// Whether share_plus's [status] means it shared. On the web it reports
/// `unavailable` even after Web Share worked, or after its own fallback
/// downloaded the file or opened an email, so it counts as shared there
/// (DOC-4); a real failure there throws. On phones `unavailable` means
/// there's no share sheet.
@visibleForTesting
bool sharedFrom(ShareResultStatus status, {required bool web}) =>
    web || status != ShareResultStatus.unavailable;
