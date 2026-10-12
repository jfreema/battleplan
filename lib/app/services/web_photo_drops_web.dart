import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:battleplan/core/services/photo_picker.dart';
import 'package:web/web.dart' as web;

/// Image files pasted (Ctrl+V or Cmd+V) or dropped anywhere on the page,
/// while something listens (CHAT-2). Text pastes go on as usual.
Stream<List<PickedPhoto>> photoDrops({
  required double maxEdge,
  required double quality,
  required int limit,
}) {
  final listeners = <(String, JSFunction)>[];
  late final StreamController<List<PickedPhoto>> out;

  void handle(web.FileList? files, web.Event event) {
    final images = _images(files, limit);
    if (images.isEmpty) return;
    // Keep the browser from opening a dropped photo in the tab.
    event.preventDefault();
    unawaited(
      Future.wait([
        for (final f in images) _resize(f, maxEdge: maxEdge, quality: quality),
      ]).then((list) {
        if (!out.isClosed) out.add([for (final p in list) ?p]);
      }),
    );
  }

  void on(String type, JSFunction f) {
    listeners.add((type, f));
    web.document.addEventListener(type, f);
  }

  out = StreamController<List<PickedPhoto>>.broadcast(
    onListen: () {
      on(
        'paste',
        ((web.ClipboardEvent e) => handle(e.clipboardData?.files, e)).toJS,
      );
      // A drop only arrives if dragging over the page was allowed.
      on(
        'dragover',
        ((web.DragEvent e) {
          final types = e.dataTransfer?.types.toDart ?? const <JSString>[];
          if (types.any((t) => t.toDart == 'Files')) e.preventDefault();
        }).toJS,
      );
      on('drop', ((web.DragEvent e) => handle(e.dataTransfer?.files, e)).toJS);
    },
    onCancel: () {
      for (final (type, f) in listeners) {
        web.document.removeEventListener(type, f);
      }
      listeners.clear();
    },
  );
  return out.stream;
}

List<web.File> _images(web.FileList? files, int limit) {
  if (files == null) return const [];
  return [
    for (var i = 0; i < files.length; i++)
      if (files.item(i) case final f? when f.type.startsWith('image/')) f,
  ].take(limit).toList();
}

/// Draws the image at most [maxEdge] on its long side on a white canvas
/// (transparent screenshots stay readable) and encodes it as JPEG. Null if
/// the browser can't read it.
Future<PickedPhoto?> _resize(
  web.File file, {
  required double maxEdge,
  required double quality,
}) async {
  try {
    final bitmap = await web.window.createImageBitmap(file).toDart;
    final scale = math.min(1, maxEdge / math.max(bitmap.width, bitmap.height));
    final w = math.max(1, (bitmap.width * scale).round());
    final h = math.max(1, (bitmap.height * scale).round());
    final canvas = web.HTMLCanvasElement()
      ..width = w
      ..height = h;
    (canvas.getContext('2d')! as web.CanvasRenderingContext2D)
      ..fillStyle = 'white'.toJS
      ..fillRect(0, 0, w, h)
      ..drawImage(bitmap, 0, 0, w, h);
    bitmap.close();
    final done = Completer<web.Blob?>();
    canvas.toBlob(
      // A typed closure: JS interop can't convert complete's FutureOr.
      // ignore: unnecessary_lambdas
      ((web.Blob? b) => done.complete(b)).toJS,
      'image/jpeg',
      quality.toJS,
    );
    final blob = await done.future;
    if (blob == null) return null;
    final buffer = await blob.arrayBuffer().toDart;
    return (bytes: Uint8List.view(buffer.toDart), contentType: 'image/jpeg');
  } on Object {
    return null;
  }
}
