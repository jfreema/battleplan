import 'package:battleplan/core/services/photo_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// `gal` behind [PhotoSaver]: the Photos library on iOS (add-only access),
/// the gallery on Android.
class GalPhotoSaver implements PhotoSaver {
  const new();

  @override
  bool get available =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<bool> saveImage(Uint8List bytes, {required String name}) async {
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
      await Gal.putImageBytes(bytes, name: name);
      return true;
    } on GalException {
      return false;
    }
  }
}
