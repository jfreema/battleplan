import 'dart:typed_data';

import 'package:battleplan/core/design/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    const gap = 3.0;
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Corners.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 360),
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
        width: 280,
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
  const new({required this.attachment, super.key, this.fit = BoxFit.cover});

  final Attachment attachment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(attachmentUrlProvider(attachment.path)).value;
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: fit,
      semanticLabel: 'Photo',
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
  Widget build(BuildContext context) =>
      Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
}
