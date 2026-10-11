import 'dart:typed_data';

import 'package:battleplan/core/services/sharer.dart';
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

  Future<bool> _share(ShareParams params) async {
    try {
      final result = await SharePlus.instance.share(params);
      return result.status != ShareResultStatus.unavailable;
    } on Object {
      return false;
    }
  }
}
