import 'dart:typed_data';

/// Saves a chat photo (CHAT-3) or a play's GIF (BOARD-5) to the phone's
/// photo library. The web uses Download instead.
abstract interface class PhotoSaver {
  /// Whether this device has a photo library to save to.
  bool get available;

  /// Saves an image, a JPEG or an animated GIF, named [name] (no
  /// extension). False if the person said no to adding photos, or saving
  /// failed.
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
