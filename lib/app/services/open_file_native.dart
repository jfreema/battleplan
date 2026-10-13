import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// iOS and Android: saves [bytes] in the app's cache and hands the file to
/// the phone's default app for its type (DOC-4). Files there need no
/// storage permission, and the system clears them when it needs room.
Future<bool> openFile(
  Uint8List bytes, {
  required String name,
  required String mimeType,
}) async {
  final cache = await getTemporaryDirectory();
  final folder = Directory('${cache.path}/opened');
  await folder.create(recursive: true);
  final safe = name.replaceAll(RegExp(r'[/\\]'), '_').trim();
  final file = File('${folder.path}/${safe.isEmpty ? 'document' : safe}');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path, type: mimeType);
  return result.type == ResultType.done;
}
