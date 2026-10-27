import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/gif.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/plays/domain/board_edit.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_gif.dart';
import 'package:battleplan/features/plays/presentation/board_painter.dart';
import 'package:material_ui/material_ui.dart';

/// How wide a play's picture in the chat is, in pixels.
const playImageWidth = 1200.0;

/// The longest side of a play's GIF, in pixels.
const playGifSide = 720.0;

/// [play]'s last step as a PNG, as the board draws it, for posting to the
/// chat (BOARD-5): where the play ends up, which opens the play itself.
Future<NewPhoto> playImage(Play play) async {
  final size = Size(
    playImageWidth,
    (playImageWidth / boardAspect(play.board, play.variant)).roundToDouble(),
  );
  final image = await _render(play, play.steps.last.elements, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return (bytes: data!.buffer.asUint8List(), contentType: 'image/png');
}

/// [play] as an animated GIF that plays its steps as the board does and
/// starts over (BOARD-5), timed by [playGifFrames]. [onProgress] hears
/// from 0 to 1 as the frames are drawn.
Future<Uint8List> playGif(Play play, {ValueChanged<double>? onProgress}) async {
  final aspect = boardAspect(play.board, play.variant);
  final size = aspect >= 1
      ? Size(playGifSide, (playGifSide / aspect).roundToDouble())
      : Size((playGifSide * aspect).roundToDouble(), playGifSide);
  // Every step as it stands, which also gives the palette: the frames
  // between them are the same things in other places.
  final stills = [
    for (final step in play.steps) await _rgba(play, step.elements, size),
  ];
  final gif = GifEncoder(
    width: size.width.round(),
    height: size.height.round(),
    palette: gifPalette(stills),
  );
  final frames = playGifFrames(play.steps.length);
  for (final (i, f) in frames.indexed) {
    gif.add(
      f.t == 0
          ? stills[f.step]
          : await _rgba(
              play,
              elementsBetween(
                play.steps[f.step].elements,
                play.steps[f.step + 1].elements,
                Curves.easeInOut.transform(f.t),
              ),
              size,
            ),
      delay: f.delay,
    );
    onProgress?.call((i + 1) / frames.length);
  }
  return gif.finish();
}

Future<Uint8List> _rgba(
  Play play,
  List<BoardElement> elements,
  Size size,
) async {
  final image = await _render(play, elements, size);
  final data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

/// The board with [elements] on it, [size] pixels.
Future<ui.Image> _render(
  Play play,
  List<BoardElement> elements,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
  PlayPainter(
    board: play.board,
    variant: play.variant,
    elements: elements,
  ).paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}
