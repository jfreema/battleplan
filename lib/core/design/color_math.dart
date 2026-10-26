import 'dart:math' as math;
import 'dart:ui' show Color;

/// A color in CIE LCh (D65): lightness L* (0 to 100), chroma C, and hue h in
/// degrees. Team colors tint the Gumdrop themes in this space, since keeping
/// L* keeps every text contrast on the color (team_tint.dart).
typedef Lch = ({double l, double c, double h});

/// A color in CIELAB (D65): lightness L* and the a* (green to red) and b*
/// (blue to yellow) axes, where [ColorMath.deltaE] measures how far apart
/// two colors look.
typedef Lab = ({double l, double a, double b});

/// Color arithmetic for the Gumdrop themes: WCAG contrast, and sRGB to and
/// from CIE LCh. The formulas and constants are the ones the design's color
/// tables were computed with, so the tables' hexes come out exactly.
abstract final class ColorMath {
  static const double _xn = 0.95047;
  static const double _yn = 1;
  static const double _zn = 1.08883;
  static const double _epsilon = 216 / 24389;
  static const double _kappa = 24389 / 27;

  static double _lin(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static double _delin(double c) => c <= 0.0031308
      ? 12.92 * c
      : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;

  static double _f(double t) =>
      t > _epsilon ? math.pow(t, 1 / 3).toDouble() : (_kappa * t + 16) / 116;

  static double _fi(double t) {
    final cube = t * t * t;
    return cube > _epsilon ? cube : (116 * t - 16) / _kappa;
  }

  /// WCAG 2 relative luminance.
  static double luminance(Color color) {
    final r = _lin(color.r);
    final g = _lin(color.g);
    final b = _lin(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// The WCAG 2 contrast ratio of [a] and [b], from 1 to 21. Both are taken
  /// as opaque.
  static double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// [color] in CIELAB.
  static Lab lab(Color color) {
    final c = lch(color);
    final rad = c.h * math.pi / 180;
    return (l: c.l, a: c.c * math.cos(rad), b: c.c * math.sin(rad));
  }

  /// How different [a] and [b] look: their distance in CIELAB (CIE76
  /// ΔE). Under about 2 is hard to see; the team colors' tints and shadows
  /// are checked against it.
  static double deltaE(Color a, Color b) {
    final p = lab(a);
    final q = lab(b);
    final dl = p.l - q.l;
    final da = p.a - q.a;
    final db = p.b - q.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  /// [color] in CIE LCh.
  static Lch lch(Color color) {
    final r = _lin(color.r);
    final g = _lin(color.g);
    final b = _lin(color.b);
    final x = 0.4124 * r + 0.3576 * g + 0.1805 * b;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    final z = 0.0193 * r + 0.1192 * g + 0.9505 * b;
    final fx = _f(x / _xn);
    final fy = _f(y / _yn);
    final fz = _f(z / _zn);
    final l = 116 * fy - 16;
    final a = 500 * (fx - fy);
    final bb = 200 * (fy - fz);
    final h = (math.atan2(bb, a) * 180 / math.pi) % 360;
    return (l: l, c: math.sqrt(a * a + bb * bb), h: h);
  }

  static List<double> _linearRgb(double l, double c, double h) {
    final rad = h * math.pi / 180;
    final a = c * math.cos(rad);
    final b = c * math.sin(rad);
    final fy = (l + 16) / 116;
    final fx = fy + a / 500;
    final fz = fy - b / 200;
    final x = _fi(fx) * _xn;
    final y = _fi(fy) * _yn;
    final z = _fi(fz) * _zn;
    return [
      3.2406 * x - 1.5372 * y - 0.4986 * z,
      -0.9689 * x + 1.8758 * y + 0.0415 * z,
      0.0557 * x - 0.2040 * y + 1.0570 * z,
    ];
  }

  /// The sRGB color at [l], [c], [h]. Out of gamut, chroma comes down in
  /// quarter steps until it fits, so lightness and hue stay put.
  static Color fromLch(double l, double c, double h) {
    var chroma = c;
    while (chroma >= 0) {
      if (_linearRgb(l, chroma, h).every((v) => v >= -1e-4 && v <= 1 + 1e-4)) {
        break;
      }
      chroma -= 0.25;
    }
    final rgb = _linearRgb(l, math.max(chroma, 0), h);
    int channel(double v) => (_delin(v.clamp(0, 1)) * 255).round();
    return Color.fromARGB(
      255,
      channel(rgb[0]),
      channel(rgb[1]),
      channel(rgb[2]),
    );
  }

  /// The smaller angle between two hues, from 0 to 180 degrees.
  static double hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// [color] with its lightness moved, a step at a time, away from every one
  /// of [backgrounds] until it reaches [minimum] contrast on all of them:
  /// darker on light backgrounds, lighter on dark ones. Hue stays, so a
  /// blue stays blue. [color] itself when it already reads. With [tint],
  /// it must also read on itself at that opacity over each background (a
  /// label on its own pale chip).
  static Color readable(
    Color color,
    List<Color> backgrounds, {
    double minimum = 4.5,
    double? tint,
  }) {
    bool reads(Color c) => backgrounds.every(
      (b) =>
          contrast(c, b) >= minimum &&
          (tint == null ||
              contrast(c, Color.alphaBlend(c.withValues(alpha: tint), b)) >=
                  minimum),
    );
    if (reads(color)) return color;
    final start = lch(color);
    // Lighter when the backgrounds are dark on average, darker otherwise.
    final meanLum =
        backgrounds.map(luminance).reduce((a, b) => a + b) / backgrounds.length;
    final up = meanLum < 0.18;
    for (var step = 1; step <= 100; step++) {
      final l = (start.l + (up ? step : -step)).clamp(0.0, 100.0);
      final candidate = fromLch(l, start.c, start.h);
      if (reads(candidate)) return candidate;
      if (l == 0 || l == 100) break;
    }
    return up ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  /// Whichever of [light] and [dark] reads better on [background].
  static Color onColor(
    Color background, {
    required Color dark,
    Color light = const Color(0xFFFFFFFF),
  }) =>
      contrast(light, background) >= contrast(dark, background) ? light : dark;

  /// [color] as `#RRGGBB`, for messages and tests.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
