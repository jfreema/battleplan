// The GIF maker behind a play's Save as GIF (BOARD-5), read back with a
// small GIF decoder here: the frames come back as drawn, in the palette's
// colors, timed, and looping.
import 'dart:typed_data';

import 'package:battleplan/core/gif.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const red = 0xE53935;
  const green = 0x3B8F43;
  const white = 0xFFFFFF;

  test('frames come back as drawn: the first whole, then only the box '
      'that changed, with the rest left as it was', () {
    final field = _frame(40, 30, green);
    final moved = _frame(40, 30, green);
    _fill(moved, 40, 10, 5, 4, 3, red);
    final gif = GifEncoder(width: 40, height: 30, palette: [green, red, white])
      ..add(field, delay: 150)
      ..add(moved, delay: 5)
      ..add(field, delay: 300);
    final read = _decode(gif.finish());
    expect(read.width, 40);
    expect(read.height, 30);
    expect(read.loops, 0);
    expect(read.frames.map((f) => f.delay), [150, 5, 300]);
    expect(read.frames.first.box, (left: 0, top: 0, width: 40, height: 30));
    expect(read.frames[1].box, (left: 10, top: 5, width: 4, height: 3));
    expect(read.frames[1].transparent, isTrue);
    expect(read.frames[0].pixels, _colors(field));
    expect(read.frames[1].pixels, _colors(moved));
    expect(read.frames[2].pixels, _colors(field));
  });

  test('a frame that changes nothing adds its time to the one before', () {
    final a = _frame(8, 8, green);
    final b = _frame(8, 8, green);
    _fill(b, 8, 0, 0, 1, 1, white);
    final gif = GifEncoder(width: 8, height: 8, palette: [green, white])
      ..add(a, delay: 5)
      ..add(a, delay: 5)
      ..add(b, delay: 5)
      ..add(b, delay: 300)
      ..add(b, delay: 7);
    final read = _decode(gif.finish());
    expect(read.frames.map((f) => f.delay), [10, 312]);
    expect(read.frames.last.pixels, _colors(b));
  });

  test('a busy picture survives LZW past its 4,096 codes', () {
    // 200 colors scattered over 160 by 120 pixels: the code table fills
    // and starts over many times, and codes grow to 12 bits.
    final palette = [for (var i = 0; i < 200; i++) (i * 0x010305) & 0xFFFFFF];
    final busy = Uint8List(160 * 120 * 4);
    var seed = 7;
    for (var p = 0; p < 160 * 120; p++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      _set(busy, p, palette[(seed >> 8) % palette.length]);
    }
    final gif = GifEncoder(width: 160, height: 120, palette: palette, loops: 2)
      ..add(busy, delay: 10);
    final read = _decode(gif.finish());
    expect(read.loops, 2);
    expect(read.frames.single.pixels, _colors(busy));
  });

  test('colors not in the palette take the nearest one', () {
    final frame = _frame(4, 1, 0xE43834);
    _set(frame, 3, 0x3A8E44);
    final gif = GifEncoder(width: 4, height: 1, palette: [white, red, green])
      ..add(frame, delay: 10);
    expect(_decode(gif.finish()).frames.single.pixels, [red, red, red, green]);
  });

  group('the palette', () {
    test('has every color when they fit, the most used first', () {
      final frame = _frame(10, 10, green);
      _fill(frame, 10, 0, 0, 3, 1, red);
      _set(frame, 99, white);
      expect(gifPalette([frame]), [green, red, white]);
    });

    test('keeps the most used exactly and merges the rest', () {
      // A field, a player, and a thousand shades of soft edges.
      final frame = _frame(100, 100, green);
      _fill(frame, 100, 0, 0, 100, 20, red);
      for (var p = 0; p < 1000; p++) {
        _set(frame, 4000 + p, 0x101010 + p * 0x000403);
      }
      final palette = gifPalette([frame]);
      expect(palette.length, lessThanOrEqualTo(gifMaxColors));
      expect(palette.take(2), [green, red]);
      expect(gifPalette([frame], max: 16), hasLength(16));
    });
  });

  test('needs a palette that fits, frames of its size, and a frame', () {
    expect(
      () => GifEncoder(width: 1, height: 1, palette: const []),
      throwsArgumentError,
    );
    expect(
      () => GifEncoder(width: 1, height: 1, palette: List.filled(256, 0)),
      throwsArgumentError,
    );
    final gif = GifEncoder(width: 2, height: 2, palette: [white]);
    expect(() => gif.add(Uint8List(4), delay: 5), throwsArgumentError);
    expect(gif.finish, throwsStateError);
  });
}

/// A [width] × [height] frame all [color] (0xRRGGBB), as RGBA.
Uint8List _frame(int width, int height, int color) {
  final rgba = Uint8List(width * height * 4);
  for (var p = 0; p < width * height; p++) {
    _set(rgba, p, color);
  }
  return rgba;
}

void _set(Uint8List rgba, int p, int color) => rgba
  ..[p * 4] = color >> 16
  ..[p * 4 + 1] = (color >> 8) & 0xFF
  ..[p * 4 + 2] = color & 0xFF
  ..[p * 4 + 3] = 0xFF;

void _fill(
  Uint8List rgba,
  int width,
  int left,
  int top,
  int w,
  int h,
  int color,
) {
  for (var y = top; y < top + h; y++) {
    for (var x = left; x < left + w; x++) {
      _set(rgba, y * width + x, color);
    }
  }
}

/// Each pixel's color, 0xRRGGBB.
List<int> _colors(Uint8List rgba) => [
  for (var o = 0; o < rgba.length; o += 4)
    rgba[o] << 16 | rgba[o + 1] << 8 | rgba[o + 2],
];

typedef _Box = ({int left, int top, int width, int height});

typedef _Read = ({
  int width,
  int height,
  int loops,
  List<({int delay, _Box box, bool transparent, List<int> pixels})> frames,
});

/// Reads [gif] back: each frame as it shows, drawn over the one before.
_Read _decode(Uint8List gif) {
  expect(String.fromCharCodes(gif.sublist(0, 6)), 'GIF89a');
  int u16(int at) => gif[at] | gif[at + 1] << 8;
  final width = u16(6);
  final height = u16(8);
  expect(gif[10] & 0x80, 0x80, reason: 'a global color table');
  final colors = 2 << (gif[10] & 7);
  final table = [
    for (var i = 0; i < colors; i++)
      gif[13 + i * 3] << 16 | gif[14 + i * 3] << 8 | gif[15 + i * 3],
  ];
  var at = 13 + colors * 3;
  var loops = -1;
  var delay = 0;
  int? clear;
  final canvas = List.filled(width * height, -1);
  final frames =
      <({int delay, _Box box, bool transparent, List<int> pixels})>[];

  List<int> blocks() {
    final data = <int>[];
    while (gif[at] != 0) {
      data.addAll(gif.sublist(at + 1, at + 1 + gif[at]));
      at += gif[at] + 1;
    }
    at++;
    return data;
  }

  while (gif[at] != 0x3B) {
    switch (gif[at]) {
      case 0x21:
        final label = gif[at + 1];
        at += 2;
        final data = blocks();
        if (label == 0xF9) {
          expect(data[0] >> 2 & 7, 1, reason: 'each frame stays up');
          delay = data[1] | data[2] << 8;
          clear = data[0] & 1 == 1 ? data[3] : null;
        } else if (label == 0xFF &&
            String.fromCharCodes(data.sublist(0, 11)) == 'NETSCAPE2.0') {
          loops = data[12] | data[13] << 8;
        }
      case 0x2C:
        final box = (
          left: u16(at + 1),
          top: u16(at + 3),
          width: u16(at + 5),
          height: u16(at + 7),
        );
        expect(gif[at + 9], 0, reason: 'no local table, not interlaced');
        final minCodeSize = gif[at + 10];
        at += 11;
        final indices = _lzw(blocks(), minCodeSize);
        expect(indices, hasLength(box.width * box.height));
        for (var i = 0; i < indices.length; i++) {
          if (indices[i] == clear) continue;
          final x = box.left + i % box.width;
          final y = box.top + i ~/ box.width;
          canvas[y * width + x] = table[indices[i]];
        }
        frames.add((
          delay: delay,
          box: box,
          transparent: clear != null,
          pixels: List.of(canvas),
        ));
      default:
        fail('Unexpected block ${gif[at]} at $at');
    }
  }
  return (width: width, height: height, loops: loops, frames: frames);
}

/// GIF's LZW, decoded the textbook way.
List<int> _lzw(List<int> data, int minCodeSize) {
  final clearCode = 1 << minCodeSize;
  final endCode = clearCode + 1;
  var codeSize = minCodeSize + 1;
  List<List<int>> fresh() => [
    for (var i = 0; i < clearCode; i++) [i],
    <int>[],
    <int>[],
  ];
  var table = fresh();
  final out = <int>[];
  var bit = 0;
  List<int>? previous;
  while (true) {
    var code = 0;
    for (var i = 0; i < codeSize; i++, bit++) {
      if (data[bit >> 3] >> (bit & 7) & 1 == 1) code |= 1 << i;
    }
    if (code == clearCode) {
      table = fresh();
      codeSize = minCodeSize + 1;
      previous = null;
      continue;
    }
    if (code == endCode) break;
    final List<int> entry;
    if (code < table.length) {
      entry = table[code];
    } else if (code == table.length && previous != null) {
      entry = [...previous, previous.first];
    } else {
      fail('Code $code with ${table.length} in the table');
    }
    out.addAll(entry);
    if (previous != null && table.length < 4096) {
      table.add([...previous, entry.first]);
      if (table.length == 1 << codeSize && codeSize < 12) codeSize++;
    }
    previous = entry;
  }
  return out;
}
