import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The type size for a big title that may wrap but must never break a word
/// in two (#74, owner's report 2026-11-20: an away game's "@ Springfield
/// Isotopes" came out as "Springfie / ld" with larger text): the first of
/// [sizes], largest first, at which each of [words] (built at that size)
/// fits [maxWidth] on a line of its own, with the text size at [context].
/// When none does, smaller still, until the widest word fits.
///
/// [words] are the title's unbreakable pieces, each one span: usually its
/// words, but a prefix bound to the first word with a no-break space
/// ("@ Springfield") counts as one.
double wholeWordSize(
  BuildContext context, {
  required double maxWidth,
  required List<double> sizes,
  required List<InlineSpan> Function(double size) words,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double widest(double size) {
    var widest = 0.0;
    for (final word in words(size)) {
      final painter = TextPainter(
        text: word,
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }

  for (final size in sizes) {
    if (widest(size) <= maxWidth) return size;
  }
  // Under the smallest: the largest size that fits, found by halving (a
  // piece may hold a part that doesn't shrink, like a prefix's own size).
  var fits = _floor;
  if (widest(fits) > maxWidth) return fits;
  var tooBig = sizes.last;
  for (var i = 0; i < 12; i++) {
    final mid = (fits + tooBig) / 2;
    if (widest(mid) <= maxWidth) {
      fits = mid;
    } else {
      tooBig = mid;
    }
  }
  return fits;
}

/// The least it shrinks to: a word that doesn't fit even so breaks.
const _floor = 8.0;

/// [text]'s words, split at spaces.
List<String> wordsOf(String text) =>
    text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
