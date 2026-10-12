import 'dart:typed_data';

/// Shares through the system share sheet, or Web Share in browsers
/// (SPEC §4.2). Returns false if sharing isn't available here, so the caller
/// can copy the link or download instead.
abstract interface class Sharer {
  Future<bool> shareLink(Uri uri, {String? subject});

  /// Shares an image file. On phones the sheet also offers Save Image.
  Future<bool> shareImage(Uint8List bytes, {required String name});

  /// Shares any file, such as a team document (DOC-4). On phones the sheet
  /// also offers Save to Files.
  Future<bool> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  });
}

class NoopSharer implements Sharer {
  const new();

  @override
  Future<bool> shareLink(Uri uri, {String? subject}) async => false;

  @override
  Future<bool> shareImage(Uint8List bytes, {required String name}) async =>
      false;

  @override
  Future<bool> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async => false;
}
