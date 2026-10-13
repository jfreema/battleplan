import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Full-screen photos (CHAT-3): pinch or scroll to zoom, swipe between a
/// message's photos, and Share (which offers Save on phones) or Download
/// (web).
class PhotoViewer extends ConsumerStatefulWidget {
  const new({required this.photos, this.initial = 0, super.key});

  final List<Attachment> photos;
  final int initial;

  static Future<void> open(
    BuildContext context,
    List<Attachment> photos,
    int initial,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PhotoViewer(photos: photos, initial: initial),
    ),
  );

  @override
  ConsumerState<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final photo = widget.photos[_index];
    final bytes = await ref
        .read(messageRepositoryProvider)
        .attachmentBytes(photo.path);
    final shared =
        bytes != null &&
        await ref
            .read(sharerProvider)
            .shareImage(bytes, name: 'battleplan-photo-${_index + 1}.jpg');
    if (!shared && mounted) showAppSnackBar(context, l10n.photoShareFailed);
  }

  Future<void> _download() async {
    final url = await ref
        .read(messageRepositoryProvider)
        .attachmentUrl(widget.photos[_index].path);
    if (url != null) await ref.read(linkOpenerProvider).open(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = widget.photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: count > 1 ? Text(l10n.photoCount(_index + 1, count)) : null,
        actions: [
          if (ref.watch(browserInfoProvider).isWeb)
            IconButton(
              tooltip: l10n.download,
              icon: const Icon(AppIcons.download),
              onPressed: () => unawaited(_download()),
            ),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(AppIcons.share),
            onPressed: () => unawaited(_share()),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: count,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: StoredPhoto(
              attachment: widget.photos[i],
              fit: BoxFit.contain,
              semanticLabel:
                  '${l10n.quotePhoto}, ${l10n.photoCount(i + 1, count)}',
            ),
          ),
        ),
      ),
    );
  }
}
