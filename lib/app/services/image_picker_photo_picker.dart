import 'dart:typed_data';

import 'package:battleplan/core/services/photo_picker.dart';
import 'package:image_picker/image_picker.dart';

/// `image_picker` behind [PhotoPicker]: the photo library on phones, a file
/// picker on web. Profile photos are resized to 512 px and compressed.
class ImagePickerPhotoPicker implements PhotoPicker {
  const new();

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
}
