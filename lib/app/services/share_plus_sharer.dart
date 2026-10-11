import 'package:battleplan/core/services/sharer.dart';
import 'package:share_plus/share_plus.dart';

/// `share_plus` behind [Sharer].
class SharePlusSharer implements Sharer {
  const new();

  @override
  Future<bool> shareLink(Uri uri, {String? subject}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(uri: uri, subject: subject),
      );
      return result.status != ShareResultStatus.unavailable;
    } on Object {
      return false;
    }
  }
}
