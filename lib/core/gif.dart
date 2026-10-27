import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

/// The most colors a GIF made here has: GIF's 256, less one that means
/// "unchanged" (transparent) in every frame after the first.
const gifMaxColors = 255;

/// The colors for a GIF of [frames] (RGBA, 4 bytes a pixel), as 0xRRGGBB:
/// all of them when there are at most [max]; else the most used quarter
/// exactly (a drawing's fills, lines, and players), and the rest, mostly
/// the soft edges between them, merged by median cut.
List<int> gifPalette(Iterable<Uint8List> frames, {int max = gifMaxColors}) {
  final counts = HashMap<int, int>();
  for (final rgba in frames) {
    // A drawing is mostly runs of one color: count each run once.
    var run = -1;
    var length = 0;
    for (var o = 0; o + 3 < rgba.length; o += 4) {
      final c = (rgba[o] << 16) | (rgba[o + 1] << 8) | rgba[o + 2];
      if (c == run) {
        length++;
        continue;
      }
      if (length > 0) counts[run] = (counts[run] ?? 0) + length;
      run = c;
      length = 1;
    }
    if (length > 0) counts[run] = (counts[run] ?? 0) + length;
  }
  final byUse = counts.keys.toList()
    ..sort((a, b) {
      final d = counts[b]! - counts[a]!;
      return d != 0 ? d : a - b;
    });
  if (byUse.length <= max) return byUse;
  final exact = byUse.sublist(0, max ~/ 4);
  return [
    ...exact,
    ..._medianCut(byUse.sublist(exact.length), counts, max - exact.length),
  ];
}

/// [colors] merged into at most [n], each the average of its box, weighing
/// every color by how much of the picture it covers ([counts]).
List<int> _medianCut(List<int> colors, Map<int, int> counts, int n) {
  final boxes = [_Box(colors)];
  while (boxes.length < n) {
    // Split the box whose colors spread widest on one channel.
    var widest = -1;
    for (final (i, box) in boxes.indexed) {
      if (box.spread > 0 && (widest < 0 || box.spread > boxes[widest].spread)) {
        widest = i;
      }
    }
    if (widest < 0) break;
    final box = boxes[widest];
    final shift = box.shift;
    final sorted = box.colors
      ..sort((a, b) => ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF));
    // At the weighted median, with a color left on each side.
    final total = sorted.fold(0, (sum, c) => sum + counts[c]!);
    var cut = 1;
    var sum = 0;
    for (var i = 0; i < sorted.length - 1; i++) {
      sum += counts[sorted[i]]!;
      cut = i + 1;
      if (sum * 2 >= total) break;
    }
    boxes[widest] = _Box(sorted.sublist(0, cut));
    boxes.add(_Box(sorted.sublist(cut)));
  }
  return [
    for (final box in boxes)
      if (box.colors.isNotEmpty) _average(box.colors, counts),
  ];
}

/// Colors in median cut, with the channel they spread most on.
class _Box {
  new(this.colors) {
    for (final s in const [16, 8, 0]) {
      var lo = 255;
      var hi = 0;
      for (final c in colors) {
        final v = (c >> s) & 0xFF;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
      if (hi - lo > spread) {
        spread = hi - lo;
        shift = s;
      }
    }
  }

  final List<int> colors;

  /// How far apart its colors are on [shift]'s channel; 0 for one color.
  int spread = 0;

  /// Red (16), green (8), or blue (0).
  int shift = 16;
}

int _average(List<int> colors, Map<int, int> counts) {
  var r = 0;
  var g = 0;
  var b = 0;
  var total = 0;
  for (final c in colors) {
    final n = counts[c]!;
    r += ((c >> 16) & 0xFF) * n;
    g += ((c >> 8) & 0xFF) * n;
    b += (c & 0xFF) * n;
    total += n;
  }
  int channel(int sum) => (sum / total).round();
  return (channel(r) << 16) | (channel(g) << 8) | channel(b);
}

/// Makes an animated GIF (GIF89a) from frames of RGBA pixels, for a play's
/// Save as GIF (BOARD-5). Every frame shares one palette, from
/// [gifPalette], and each pixel takes its nearest color. After the first,
/// a frame keeps only the box that changed, with what didn't change inside
/// it transparent, so a drawing where a few things move stays small; a
/// frame that changes nothing adds its time to the one before.
class GifEncoder {
  /// A GIF [width] by [height] pixels in [palette]'s colors (0xRRGGBB, at
  /// most [gifMaxColors]) that plays [loops] times, or forever when 0.
  new({
    required this.width,
    required this.height,
    required List<int> palette,
    int loops = 0,
  }) : _palette = palette {
    if (palette.isEmpty || palette.length > gifMaxColors) {
      throw ArgumentError.value(palette.length, 'palette', 'colors');
    }
    for (final (i, c) in palette.indexed) {
      _index.putIfAbsent(c & 0xFFFFFF, () => i);
    }
    _out
      ..add('GIF89a'.codeUnits)
      ..add(_u16(width))
      ..add(_u16(height))
      // A global table of 256 colors, 8 bits a channel.
      ..add(const [0xF7, 0, 0]);
    for (var i = 0; i < 256; i++) {
      final c = i < palette.length ? palette[i] : 0;
      _out.add([(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF]);
    }
    // How many times it plays (the NETSCAPE2.0 extension).
    _out
      ..add([0x21, 0xFF, 11, ...'NETSCAPE2.0'.codeUnits, 3, 1])
      ..add(_u16(loops))
      ..addByte(0);
  }

  final int width;
  final int height;
  final List<int> _palette;

  /// The palette index that means "unchanged".
  static const _clear = 255;

  /// The palette index of each color seen so far (0xRRGGBB).
  final _index = HashMap<int, int>();
  final _out = BytesBuilder(copy: false);

  /// The last frame's pixels, to find what the next one changes.
  Uint32List? _last;

  /// The last frame, written once the next shows whether it gets more time.
  _Frame? _held;

  /// LZW's table of (code, index) pairs, kept between frames: an entry
  /// counts only while its top bits match [_generation].
  final _table = Int32List(1 << 20);
  var _generation = 0;

  /// Adds a frame: [rgba] is [width] × [height] pixels, 4 bytes each,
  /// shown for [delay] hundredths of a second.
  void add(Uint8List rgba, {required int delay}) {
    final count = width * height;
    if (rgba.length != count * 4) {
      throw ArgumentError.value(rgba.length, 'rgba', 'not $width × $height');
    }
    final bytes = rgba.offsetInBytes % 4 == 0 ? rgba : Uint8List.fromList(rgba);
    final pixels = Uint32List.fromList(
      bytes.buffer.asUint32List(bytes.offsetInBytes, count),
    );
    final last = _last;
    _last = pixels;
    if (last == null) {
      final indices = _indices(bytes, pixels, null, 0, 0, width, height);
      _hold(_Frame(0, 0, width, height, indices, delay, transparent: false));
      return;
    }
    // The box around what changed.
    var top = -1;
    var bottom = -1;
    var left = width;
    var right = -1;
    for (var y = 0; y < height; y++) {
      final row = y * width;
      var x = 0;
      while (x < width && pixels[row + x] == last[row + x]) {
        x++;
      }
      if (x == width) continue;
      if (top < 0) top = y;
      bottom = y;
      left = math.min(left, x);
      var r = width - 1;
      while (r > right && pixels[row + r] == last[row + r]) {
        r--;
      }
      right = math.max(right, r);
    }
    if (top < 0) {
      _held!.delay += delay;
      return;
    }
    final w = right - left + 1;
    final h = bottom - top + 1;
    final indices = _indices(bytes, pixels, last, left, top, w, h);
    _hold(_Frame(left, top, w, h, indices, delay, transparent: true));
  }

  /// The finished GIF. Needs a frame.
  Uint8List finish() {
    final held = _held;
    if (held == null) throw StateError('No frames');
    _write(held);
    _held = null;
    _out.addByte(0x3B);
    return _out.takeBytes();
  }

  /// The palette index of each pixel in the box, or [_clear] where it's
  /// the same as in [last].
  Uint8List _indices(
    Uint8List rgba,
    Uint32List pixels,
    Uint32List? last,
    int left,
    int top,
    int w,
    int h,
  ) {
    final out = Uint8List(w * h);
    var i = 0;
    for (var y = top; y < top + h; y++) {
      for (var x = left; x < left + w; x++, i++) {
        final p = y * width + x;
        if (last != null && pixels[p] == last[p]) {
          out[i] = _clear;
          continue;
        }
        final o = p * 4;
        final c = (rgba[o] << 16) | (rgba[o + 1] << 8) | rgba[o + 2];
        out[i] = _index[c] ??= _nearest(c);
      }
    }
    return out;
  }

  /// The palette color closest to [c], weighing green most, as eyes do.
  int _nearest(int c) {
    final r = (c >> 16) & 0xFF;
    final g = (c >> 8) & 0xFF;
    final b = c & 0xFF;
    var best = 0;
    var bestDistance = 1 << 30;
    for (var i = 0; i < _palette.length; i++) {
      final p = _palette[i];
      final dr = r - ((p >> 16) & 0xFF);
      final dg = g - ((p >> 8) & 0xFF);
      final db = b - (p & 0xFF);
      final d = 2 * dr * dr + 4 * dg * dg + 3 * db * db;
      if (d < bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    return best;
  }

  void _hold(_Frame frame) {
    if (_held case final held?) _write(held);
    _held = frame;
  }

  void _write(_Frame f) {
    _out
      // It stays up under the next frame (disposal 1), for its time, and
      // in later frames "unchanged" is transparent.
      ..add([0x21, 0xF9, 4, if (f.transparent) 5 else 4])
      ..add(_u16(math.min(f.delay, 0xFFFF)))
      ..add([if (f.transparent) _clear else 0, 0])
      // Where its box sits, with the global table and no interlacing.
      ..addByte(0x2C)
      ..add(_u16(f.left))
      ..add(_u16(f.top))
      ..add(_u16(f.width))
      ..add(_u16(f.height))
      ..addByte(0);
    _lzw(f.indices);
  }

  /// [indices] as GIF's LZW codes, which start at 9 bits for 8-bit colors
  /// and grow to 12, packed into sub-blocks of up to 255 bytes.
  void _lzw(Uint8List indices) {
    const clearCode = 256;
    const endCode = 257;
    final data = _Bytes();
    var codeSize = 9;
    var next = 258;
    var bits = 0;
    var pending = 0;
    void emit(int code) {
      pending |= code << bits;
      bits += codeSize;
      while (bits >= 8) {
        data.add(pending & 0xFF);
        pending >>= 8;
        bits -= 8;
      }
    }

    var generation = _nextGeneration();
    emit(clearCode);
    var prefix = indices[0];
    for (var i = 1; i < indices.length; i++) {
      final k = indices[i];
      final key = (prefix << 8) | k;
      final entry = _table[key];
      if (entry >> 12 == generation) {
        prefix = entry & 0xFFF;
        continue;
      }
      emit(prefix);
      if (next == 4096) {
        // The table is full: start it over.
        emit(clearCode);
        codeSize = 9;
        next = 258;
        generation = _nextGeneration();
      } else {
        // The decoder widens its codes once it fills the current width,
        // one code behind the encoder.
        if (next >= 1 << codeSize) codeSize++;
        _table[key] = (generation << 12) | next++;
      }
      prefix = k;
    }
    emit(prefix);
    emit(endCode);
    if (bits > 0) data.add(pending & 0xFF);

    _out.addByte(8);
    final bytes = data.bytes;
    for (var o = 0; o < bytes.length; o += 255) {
      final end = math.min(o + 255, bytes.length);
      _out
        ..addByte(end - o)
        ..add(Uint8List.sublistView(bytes, o, end));
    }
    _out.addByte(0);
  }

  /// A fresh generation for [_table], which empties it.
  int _nextGeneration() {
    if (_generation == 0x7FFFF) {
      _table.fillRange(0, _table.length, 0);
      _generation = 0;
    }
    return ++_generation;
  }

  static List<int> _u16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
}

/// A frame waiting to be written: its box and the palette index of each
/// pixel in it.
class _Frame {
  new(
    this.left,
    this.top,
    this.width,
    this.height,
    this.indices,
    this.delay, {
    required this.transparent,
  });

  final int left;
  final int top;
  final int width;
  final int height;
  final Uint8List indices;
  int delay;
  final bool transparent;
}

/// A growing byte buffer.
class _Bytes {
  var _bytes = Uint8List(4096);
  var _length = 0;

  void add(int byte) {
    if (_length == _bytes.length) {
      _bytes = Uint8List(_length * 2)..setRange(0, _length, _bytes);
    }
    _bytes[_length++] = byte;
  }

  Uint8List get bytes => Uint8List.sublistView(_bytes, 0, _length);
}
