import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/presentation/board_painter.dart';
import 'package:material_ui/material_ui.dart';

/// How wide a play's picture in the chat is, in pixels.
const playImageWidth = 1200.0;

/// Each of [play]'s steps as a PNG, as the board draws it, for posting to
/// the chat (BOARD-5): a photo per step, which every version of the app
/// shows, and a swipe in the viewer goes through them.
Future<List<NewPhoto>> playImages(Play play) async {
  final size = Size(
    playImageWidth,
    (playImageWidth / boardAspect(play.board, play.variant)).roundToDouble(),
  );
  return [
    for (final step in play.steps.take(10))
      (bytes: await _png(play, step.elements, size), contentType: 'image/png'),
  ];
}

Future<Uint8List> _png(
  Play play,
  List<BoardElement> elements,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  PlayPainter(
    board: play.board,
    variant: play.variant,
    elements: elements,
  ).paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
