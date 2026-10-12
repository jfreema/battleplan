import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Decodes [image] just large enough to fill a [width] x [height] box (in
/// device pixels) with [BoxFit.cover]: its shorter side, relative to the box,
/// lands on the box, and the aspect ratio is kept (SPEC §8.1).
///
/// `cacheWidth` alone under-samples landscape photos, and
/// [ResizeImagePolicy.fit] decodes to fit *inside* the box, which is the same
/// problem: a 512x256 logo in a 120 px square would decode at 120x60 and
/// then be stretched 2x to cover it. Never decodes larger than the image.
@immutable
class CoverResizeImage extends ImageProvider<CoverResizeImageKey> {
  const new(this.image, {required this.width, required this.height});

  /// Wraps [image] for a box of [logicalWidth] x [logicalHeight] logical
  /// pixels at [devicePixelRatio].
  factory forBox(
    ImageProvider image, {
    required double logicalWidth,
    required double logicalHeight,
    required double devicePixelRatio,
  }) => CoverResizeImage(
    image,
    width: (logicalWidth * devicePixelRatio).ceil(),
    height: (logicalHeight * devicePixelRatio).ceil(),
  );

  final ImageProvider image;
  final int width;
  final int height;

  /// The decode size for an image of [intrinsicWidth] x [intrinsicHeight]
  /// covering a [boxWidth] x [boxHeight] box.
  static ui.TargetImageSize targetSize(
    int intrinsicWidth,
    int intrinsicHeight,
    int boxWidth,
    int boxHeight,
  ) {
    if (intrinsicWidth <= 0 || intrinsicHeight <= 0) {
      return const ui.TargetImageSize();
    }
    final scaleW = boxWidth / intrinsicWidth;
    final scaleH = boxHeight / intrinsicHeight;
    final scale = scaleW > scaleH ? scaleW : scaleH;
    // Already small enough: decode as is.
    if (scale >= 1) return const ui.TargetImageSize();
    return ui.TargetImageSize(
      width: (intrinsicWidth * scale).ceil(),
      height: (intrinsicHeight * scale).ceil(),
    );
  }

  @override
  Future<CoverResizeImageKey> obtainKey(ImageConfiguration configuration) =>
      image
          .obtainKey(configuration)
          .then((key) => CoverResizeImageKey._(key, width, height));

  @override
  ImageStreamCompleter loadImage(
    CoverResizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeCover(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      assert(
        getTargetSize == null,
        'CoverResizeImage cannot wrap a provider that sets its own size.',
      );
      return decode(
        buffer,
        getTargetSize: (w, h) => targetSize(w, h, width, height),
      );
    }

    return image.loadImage(key._inner, decodeCover);
  }

  @override
  bool operator ==(Object other) =>
      other is CoverResizeImage &&
      other.image == image &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(image, width, height);

  @override
  String toString() => 'CoverResizeImage($image, ${width}x$height)';
}

/// The cache key for a [CoverResizeImage].
@immutable
class CoverResizeImageKey {
  const new _(this._inner, this._width, this._height);

  final Object _inner;
  final int _width;
  final int _height;

  @override
  bool operator ==(Object other) =>
      other is CoverResizeImageKey &&
      other._inner == _inner &&
      other._width == _width &&
      other._height == _height;

  @override
  int get hashCode => Object.hash(_inner, _width, _height);
}
