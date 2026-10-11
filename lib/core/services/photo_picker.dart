import 'dart:typed_data';

/// Picks a photo from the library or camera (ARCH §5.2 rule 8: platform
/// services sit behind interfaces). Returns JPEG bytes already resized for
/// upload, or null if the person cancelled.
abstract interface class PhotoPicker {
  Future<Uint8List?> pickProfilePhoto();
}
