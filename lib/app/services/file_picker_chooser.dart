import 'package:battleplan/core/services/file_chooser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// `file_picker` behind [FileChooser]: the system's file picker and save
/// dialog on phones, the browser's file input and download on the web.
class FilePickerChooser implements FileChooser {
  const new();

  @override
  Future<PickedFile?> pickFile({required List<String> extensions}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    final size = file.lengthSync() ?? await file.length() ?? 0;
    return (name: file.name, size: size, readBytes: file.readAsBytes);
  }

  @override
  Future<bool> saveFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    try {
      final saved = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: mimeType,
      );
      // Browsers start the download and report no place.
      return kIsWeb || saved != null;
    } on Object {
      return false;
    }
  }

  @override
  bool get downloadsInsteadOfOpening => kIsWeb;
}
