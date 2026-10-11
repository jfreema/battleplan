import 'dart:typed_data';

/// A photo picked for chat, already resized for upload.
typedef PickedPhoto = ({Uint8List bytes, String contentType});

/// Picks photos from the library or camera (ARCH §5.2 rule 8: platform
/// services sit behind interfaces). Photos come back resized and
/// compressed, or empty/null if the person cancelled.
abstract interface class PhotoPicker {
  /// One square-ish profile photo, 512 px.
  Future<Uint8List?> pickProfilePhoto();

  /// Up to [limit] chat photos from the library, at most 2048 px (CHAT-3).
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10});

  /// One chat photo from the camera (phones only).
  Future<PickedPhoto?> takeChatPhoto();

  /// Whether this device has a camera to take photos with.
  bool get canUseCamera;
}
