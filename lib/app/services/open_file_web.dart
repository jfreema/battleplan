import 'dart:typed_data';

/// Browsers download files the app can't show instead (DOC-4).
Future<bool> openFile(
  Uint8List bytes, {
  required String name,
  required String mimeType,
}) async => false;
