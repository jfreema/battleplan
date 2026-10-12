import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// The side of a cropped profile photo, in pixels (SET-1).
const croppedPhotoSize = 512;

/// The most a photo can be zoomed in the crop step.
const maxCropZoom = 4.0;

/// Opens the crop step for a picked profile photo (SET-1): the person drags
/// and zooms it inside a circle. Returns a square PNG of what's in the
/// circle, or null if they cancelled or the photo can't be read. Rendering
/// it again also leaves every bit of metadata behind.
Future<Uint8List?> cropProfilePhoto(BuildContext context, Uint8List bytes) =>
    Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CropPhotoScreen(bytes: bytes),
      ),
    );

/// The part of an [image] of this size that a square viewport of side
/// [viewport] shows, with the image covering the viewport at [zoom] 1 and
/// moved by [offset] (the image's top-left corner in the viewport).
@visibleForTesting
Rect cropSourceRect(Size image, double viewport, Offset offset, double zoom) {
  final k = coverScale(image, viewport) * zoom;
  return Rect.fromLTWH(
    -offset.dx / k,
    -offset.dy / k,
    viewport / k,
    viewport / k,
  );
}

/// The scale at which [image] just covers a square of side [viewport].
@visibleForTesting
double coverScale(Size image, double viewport) =>
    viewport / math.min(image.width, image.height);

/// Keeps the image covering the whole viewport: no empty edge in the
/// circle, whatever the drag.
@visibleForTesting
Offset clampCropOffset(
  Size image,
  double viewport,
  Offset offset,
  double zoom,
) {
  final k = coverScale(image, viewport) * zoom;
  final minX = viewport - image.width * k;
  final minY = viewport - image.height * k;
  return Offset(
    offset.dx.clamp(minX, 0).toDouble(),
    offset.dy.clamp(minY, 0).toDouble(),
  );
}

/// Draws [source] of [image] into a [size]-pixel square PNG.
Future<Uint8List> renderCrop(ui.Image image, Rect source, int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    source,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final out = await picture.toImage(size, size);
  picture.dispose();
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  out.dispose();
  return data!.buffer.asUint8List();
}

/// The crop step itself (SET-1). Drag to move, pinch or use the slider to
/// zoom; the circle shows what others will see.
class CropPhotoScreen extends StatefulWidget {
  const new({required this.bytes, super.key});

  final Uint8List bytes;

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _viewport = 0;

  // Where a pinch or drag started.
  double _startZoom = 1;
  Offset _startFocal = Offset.zero;
  Offset _startOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Size get _imageSize =>
      Size(_image!.width.toDouble(), _image!.height.toDouble());

  /// Centers the image the first time the viewport size is known.
  void _layout(double viewport) {
    if (viewport == _viewport) return;
    final first = _viewport == 0;
    _viewport = viewport;
    if (first) {
      final k = coverScale(_imageSize, viewport);
      _offset = Offset(
        (viewport - _imageSize.width * k) / 2,
        (viewport - _imageSize.height * k) / 2,
      );
    }
    _offset = clampCropOffset(_imageSize, viewport, _offset, _zoom);
  }

  /// Zooms to [zoom] around [focal] (a point in the viewport).
  void _zoomTo(double zoom, Offset focal, {Offset? from, double? fromZoom}) {
    final z = zoom.clamp(1.0, maxCropZoom);
    final base = from ?? _offset;
    final ratio = z / (fromZoom ?? _zoom);
    final next = focal - (focal - base) * ratio;
    setState(() {
      _zoom = z;
      _offset = clampCropOffset(_imageSize, _viewport, next, z);
    });
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null) return;
    setState(() => _saving = true);
    final png = await renderCrop(
      image,
      cropSourceRect(_imageSize, _viewport, _offset, _zoom),
      croppedPhotoSize,
    );
    if (mounted) Navigator.of(context).pop(png);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final image = _image;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cropPhotoTitle),
        actions: [
          TextButton(
            onPressed: image == null || _saving
                ? null
                : () => unawaited(_save()),
            child: Text(l10n.cropPhotoUse),
          ),
        ],
      ),
      body: SafeArea(
        child: _failed
            ? Center(child: Text(l10n.cropPhotoFailed))
            : image == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final side = math.min<double>(
                            math.min(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            420,
                          );
                          _layout(side);
                          return Center(child: _cropArea(image, side));
                        },
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      l10n.cropPhotoHelp,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: _zoom,
                      min: 1,
                      max: maxCropZoom,
                      label: l10n.cropPhotoZoom,
                      semanticFormatterCallback: (_) => l10n.cropPhotoZoom,
                      onChanged: (z) =>
                          _zoomTo(z, Offset(_viewport / 2, _viewport / 2)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _cropArea(ui.Image image, double side) => Semantics(
    label: AppLocalizations.of(context).cropPhotoHelp,
    child: GestureDetector(
      onScaleStart: (d) {
        _startZoom = _zoom;
        _startFocal = d.localFocalPoint;
        _startOffset = _offset;
      },
      onScaleUpdate: (d) {
        final moved = _startOffset + (d.localFocalPoint - _startFocal);
        _zoomTo(
          _startZoom * d.scale,
          d.localFocalPoint,
          from: moved,
          fromZoom: _startZoom,
        );
      },
      child: SizedBox.square(
        dimension: side,
        child: ClipRect(
          child: CustomPaint(
            painter: _CropPainter(
              image: image,
              source: cropSourceRect(_imageSize, side, _offset, _zoom),
              shade: Colors.black54,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The visible part of the photo, with everything outside the circle
/// shaded.
class _CropPainter extends CustomPainter {
  const new({required this.image, required this.source, required this.shade});

  final ui.Image image;
  final Rect source;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.drawImageRect(image, source, box, Paint());
    final circle = Path()..addOval(box.deflate(1));
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, Path()..addRect(box), circle),
        Paint()..color = shade,
      )
      ..drawPath(
        circle,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.source != source || old.shade != shade;
}
