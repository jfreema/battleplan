import 'dart:typed_data';

import 'package:battleplan/app/services/web_share_stub.dart'
    if (dart.library.js_interop) 'package:battleplan/app/services/web_share_web.dart'
    as platform;
import 'package:battleplan/core/services/sharer.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:share_plus/share_plus.dart';

/// `share_plus` behind [Sharer].
class SharePlusSharer implements Sharer {
  const new({
    this.web = kIsWeb,
    this.canWebShareLink = platform.canWebShareLink,
  });

  /// Running in a browser.
  final bool web;

  /// Whether the browser has Web Share for a link.
  final bool Function(Uri uri) canWebShareLink;

  /// Links: Web Share where the browser has it, and otherwise false, so the
  /// caller copies the link (SPEC §4.2 parity: "Web Share where supported,
  /// otherwise copy link"). share_plus's own fallback would open an email
  /// instead.
  @override
  Future<bool> shareLink(Uri uri, {String? subject}) =>
      web && !canWebShareLink(uri)
      ? Future.value(false)
      : _share(ShareParams(uri: uri, subject: subject));

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
      return sharedFrom(result.status, web: web);
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
