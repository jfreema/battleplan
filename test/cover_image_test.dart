import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [width] x [height] PNG, drawn and encoded by the engine.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF2F5BEA),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Decodes [provider] and returns the decoded image's size.
Future<Size> _decodedSize(ImageProvider provider) {
  final done = Completer<Size>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      done.complete(
        Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      stream.removeListener(listener);
    },
    onError: (e, s) {
      done.completeError(e, s);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return done.future;
}

void main() {
  group('cover decode size (SPEC §8.1)', () {
    test('a landscape image decodes so its height fills the box', () {
      // A 512x256 logo in a 40 pt badge at 3x: 120 px square.
      final size = CoverResizeImage.targetSize(512, 256, 120, 120);
      expect(size.width, 240);
      expect(size.height, 120);
    });

    test('a portrait image decodes so its width fills the box', () {
      final size = CoverResizeImage.targetSize(300, 600, 120, 120);
      expect(size.width, 120);
      expect(size.height, 240);
    });

    test('an image already smaller than the box is never scaled up', () {
      final size = CoverResizeImage.targetSize(100, 50, 120, 120);
      expect(size.width, isNull);
      expect(size.height, isNull);
    });

    testWidgets('the engine decodes a landscape photo at the cover size', (
      tester,
    ) async {
      final decoded = await tester.runAsync(() async {
        final bytes = await _png(512, 256);
        return await _decodedSize(
          CoverResizeImage(MemoryImage(bytes), width: 120, height: 120),
        );
      });
      // cacheWidth: 120 alone would give 120x60, stretched 2x to cover.
      expect(decoded, const Size(240, 120));
    });

    testWidgets('Avatar and TeamBadge decode for both sides of their box', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Avatar(name: 'Alex Kim', imageUrl: 'https://x/a.jpg'),
              TeamBadge(name: 'Hawks', imageUrl: 'https://x/b.jpg', size: 40),
            ],
          ),
        ),
      );
      final images = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => i.image)
          .toList();
      expect(images, hasLength(2));
      for (final (image, px) in [(images[0], 120), (images[1], 120)]) {
        expect(image, isA<CoverResizeImage>());
        final cover = image as CoverResizeImage;
        expect((cover.width, cover.height), (px, px));
      }
    });

    testWidgets('a photo in the grid decodes for both sides of the tile', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final bytes = (await tester.runAsync(() => _png(600, 200)))!;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PhotoGrid(
            count: 1,
            single: 3,
            tile: (_) => LocalPhoto(bytes: bytes),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(image, isA<CoverResizeImage>());
      final cover = image as CoverResizeImage;
      // 280 pt at 2x, on both sides: a 3:1 photo in a 2:1 box fills by height.
      expect((cover.width, cover.height), (560, 560));
    });
  });
}
