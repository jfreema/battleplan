import 'dart:typed_data';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A message's photos (CHAT-3): one photo at its own shape, or several as a
/// grid of squares. Tapping one opens the viewer.
class PhotoGrid extends StatelessWidget {
  const new({required this.count, required this.tile, this.single, super.key});

  final int count;

  /// Builds photo number i, filling its cell.
  final Widget Function(int i) tile;

  /// Width over height of a lone photo, when known.
  final double? single;

  /// The widest a grid is drawn, in logical pixels.
  static const double maxWidth = 280;

  @override
  Widget build(BuildContext context) {
    const gap = 3.0;
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Corners.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth, maxHeight: 360),
          child: AspectRatio(
            aspectRatio: (single ?? 1).clamp(0.5, 2.0),
            child: tile(0),
          ),
        ),
      );
    }
    final columns = count == 2 || count == 4 ? 2 : 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.card),
      child: SizedBox(
        width: maxWidth,
        child: GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [for (var i = 0; i < count; i++) tile(i)],
        ),
      ),
    );
  }
}

/// A stored message photo, loaded from its download URL.
class StoredPhoto extends ConsumerWidget {
  const new({
    required this.attachment,
    super.key,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.decodeWidth,
  });

  final Attachment attachment;
  final BoxFit fit;

  /// What screen readers say: "Photo from Alex" (SPEC §7.6).
  final String? semanticLabel;

  /// For thumbnails, the widest it's drawn in logical pixels: the photo is
  /// decoded so its shorter side is that size rather than its full 2048 px,
  /// which keeps memory down and scrolling smooth (SPEC §8.1) while a wide
  /// photo, which cover fills by height, stays sharp. Null decodes it in
  /// full.
  final double? decodeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(attachmentUrlProvider(attachment.path)).value;
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (url == null) return placeholder;
    final width = decodeWidth;
    final network = NetworkImage(url);
    return Image(
      image: width == null
          ? network
          : CoverResizeImage.forBox(
              network,
              logicalWidth: width,
              logicalHeight: width,
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            ),
      fit: fit,
      semanticLabel: semanticLabel,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// A photo still on this device, while it uploads.
class LocalPhoto extends StatelessWidget {
  const new({required this.bytes, super.key});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Image(
    // A thumbnail in the grid: decoded at that size, not the photo's own.
    image: CoverResizeImage.forBox(
      MemoryImage(bytes),
      logicalWidth: PhotoGrid.maxWidth,
      logicalHeight: PhotoGrid.maxWidth,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    ),
    fit: BoxFit.cover,
    gaplessPlayback: true,
  );
}
