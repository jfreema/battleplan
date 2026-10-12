import 'dart:typed_data';

import 'package:battleplan/core/photo_location.dart';

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

/// Wraps a [PhotoPicker] so every photo it picks has its location removed
/// before anything uploads it (Privacy Policy; ARCH §6.8). Chat photos,
/// camera photos, profile photos, team logos and chat backgrounds all come
/// through here.
class LocationStrippingPhotoPicker implements PhotoPicker {
  const new(this._inner);

  final PhotoPicker _inner;

  @override
  Future<Uint8List?> pickProfilePhoto() async {
    final bytes = await _inner.pickProfilePhoto();
    return bytes == null ? null : stripPhotoLocation(bytes);
  }

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async => [
    for (final p in await _inner.pickChatPhotos(limit: limit)) _strip(p),
  ];

  @override
  Future<PickedPhoto?> takeChatPhoto() async {
    final p = await _inner.takeChatPhoto();
    return p == null ? null : _strip(p);
  }

  @override
  bool get canUseCamera => _inner.canUseCamera;

  static PickedPhoto _strip(PickedPhoto p) =>
      (bytes: stripPhotoLocation(p.bytes), contentType: p.contentType);
}
