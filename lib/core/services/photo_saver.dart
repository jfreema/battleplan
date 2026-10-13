import 'dart:typed_data';

/// Saves a chat photo to the phone's photo library (CHAT-3). The web uses
/// Download instead.
abstract interface class PhotoSaver {
  /// Whether this device has a photo library to save to.
  bool get available;

  /// Saves a JPEG named [name] (no extension). False if the person said no
  /// to adding photos, or saving failed.
  Future<bool> saveImage(Uint8List bytes, {required String name});
}

/// The web and tests: nothing to save to.
class NoPhotoSaver implements PhotoSaver {
  const new();

  @override
  bool get available => false;

  @override
  Future<bool> saveImage(Uint8List bytes, {required String name}) async =>
      false;
}
