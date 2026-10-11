import 'package:battleplan/core/services/photo_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// `image_picker` behind [PhotoPicker]: the photo library or camera on
/// phones, a file picker on web. It resizes and compresses as it picks.
class ImagePickerPhotoPicker implements PhotoPicker {
  const new();

  /// Chat photos: long edge at most 2048 px, JPEG quality 85 (CHAT-3).
  static const _chatEdge = 2048.0;
  static const _chatQuality = 85;

  @override
  Future<Uint8List?> pickProfilePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    return file == null ? null : await file.readAsBytes();
  }

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: _chatEdge,
      maxHeight: _chatEdge,
      imageQuality: _chatQuality,
      limit: limit,
    );
    return [
      for (final f in files.take(limit))
        (bytes: await f.readAsBytes(), contentType: f.mimeType ?? 'image/jpeg'),
    ];
  }

  @override
  Future<PickedPhoto?> takeChatPhoto() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: _chatEdge,
      maxHeight: _chatEdge,
      imageQuality: _chatQuality,
    );
    return f == null
        ? null
        : (
            bytes: await f.readAsBytes(),
            contentType: f.mimeType ?? 'image/jpeg',
          );
  }

  @override
  bool get canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}
