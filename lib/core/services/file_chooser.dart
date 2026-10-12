import 'dart:typed_data';

/// A file picked from the device (DOC-2). The size comes first, so a file
/// over the limit is refused without reading it.
typedef PickedFile = ({
  String name,
  int size,
  Future<Uint8List> Function() readBytes,
});

/// Picks files to upload and saves files people download (ARCH §5.2 rule
/// 8: platform services sit behind interfaces).
abstract interface class FileChooser {
  /// One file with one of [extensions] (no dots), or null if the person
  /// cancelled.
  Future<PickedFile?> pickFile({required List<String> extensions});

  /// Saves [bytes] as [name]: the browser's download on the web, the
  /// system's save dialog on phones (DOC-4). False if it didn't save.
  Future<bool> saveFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  });

  /// True in browsers, where files the app can't show download instead of
  /// opening in another app (DOC-4).
  bool get downloadsInsteadOfOpening;
}

class NoopFileChooser implements FileChooser {
  const new();

  @override
  Future<PickedFile?> pickFile({required List<String> extensions}) async =>
      null;

  @override
  Future<bool> saveFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async => false;

  @override
  bool get downloadsInsteadOfOpening => false;
}
