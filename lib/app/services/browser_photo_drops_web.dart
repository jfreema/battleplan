import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:battleplan/core/services/photo_drops.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:web/web.dart' as web;

PhotoDrops browserPhotoDrops() => _BrowserPhotoDrops();

/// Listens on the page for pasted images and files dragged in (SPEC §4.2).
/// Text pastes and drags of anything but files are left to the page.
class _BrowserPhotoDrops implements PhotoDrops {
  new() {
    web.document
      ..addEventListener('paste', _onPaste.toJS)
      ..addEventListener('dragenter', _onDragEnter.toJS)
      ..addEventListener('dragover', _onDragOver.toJS)
      ..addEventListener('dragleave', _onDragLeave.toJS)
      ..addEventListener('drop', _onDrop.toJS);
  }

  /// Chat photos: long edge at most 2048 px, JPEG quality 85 (CHAT-3), as
  /// the picker makes them.
  static const _edge = 2048;
  static const _quality = 0.85;

  final _photos = StreamController<List<PickedPhoto>>.broadcast();
  final _dragging = StreamController<bool>.broadcast();

  /// dragenter and dragleave fire for every element crossed.
  int _depth = 0;

  @override
  Stream<List<PickedPhoto>> get photos => _photos.stream;

  @override
  Stream<bool> get dragging => _dragging.stream;

  void _onPaste(web.ClipboardEvent e) {
    final files = _images(e.clipboardData?.files);
    if (files.isEmpty) return;
    e.preventDefault();
    unawaited(_read(files));
  }

  static bool _hasFiles(web.DragEvent e) =>
      e.dataTransfer?.types.toDart.any((t) => t.toDart == 'Files') ?? false;

  void _onDragEnter(web.DragEvent e) {
    if (!_hasFiles(e)) return;
    e.preventDefault();
    if (_depth++ == 0) _dragging.add(true);
  }

  void _onDragOver(web.DragEvent e) {
    if (!_hasFiles(e)) return;
    // Lets the drop happen here instead of the browser opening the file.
    e.preventDefault();
    e.dataTransfer?.dropEffect = 'copy';
  }

  void _onDragLeave(web.DragEvent e) {
    if (!_hasFiles(e)) return;
    _depth = math.max(0, _depth - 1);
    if (_depth == 0) _dragging.add(false);
  }

  void _onDrop(web.DragEvent e) {
    if (!_hasFiles(e)) return;
    e.preventDefault();
    _depth = 0;
    _dragging.add(false);
    final files = _images(e.dataTransfer?.files);
    if (files.isNotEmpty) unawaited(_read(files));
  }

  static List<web.File> _images(web.FileList? list) => [
    if (list != null)
      for (var i = 0; i < list.length; i++)
        if (list.item(i) case final f? when f.type.startsWith('image/')) f,
  ];

  Future<void> _read(List<web.File> files) async {
    final out = <PickedPhoto>[];
    for (final f in files) {
      try {
        out.add(await _resize(f));
      } on Object {
        // An image the browser can't decode is skipped.
      }
    }
    if (out.isNotEmpty) _photos.add(out);
  }

  /// Draws the image at most [_edge] on its long side and encodes it as a
  /// JPEG, which also drops its metadata, location included.
  static Future<PickedPhoto> _resize(web.File file) async {
    final bitmap = await web.window.createImageBitmap(file).toDart;
    final scale = math.min(1, _edge / math.max(bitmap.width, bitmap.height));
    final w = math.max(1, (bitmap.width * scale).round());
    final h = math.max(1, (bitmap.height * scale).round());
    final canvas = web.HTMLCanvasElement()
      ..width = w
      ..height = h;
    (canvas.getContext('2d')! as web.CanvasRenderingContext2D).drawImage(
      bitmap,
      0,
      0,
      w,
      h,
    );
    bitmap.close();
    final done = Completer<web.Blob?>();
    void encoded(web.Blob? blob) => done.complete(blob);
    canvas.toBlob(encoded.toJS, 'image/jpeg', _quality.toJS);
    final blob = await done.future;
    if (blob == null) throw StateError('Encoding failed');
    final buffer = await blob.arrayBuffer().toDart;
    return (bytes: Uint8List.view(buffer.toDart), contentType: 'image/jpeg');
  }
}
