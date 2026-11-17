import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The photos waiting above the message box (CHAT-3, #26): a row of 72 px
/// thumbnails, each with an X that takes it out, a ring while it uploads,
/// and a tile to add more until the message holds 10. Nothing is sent until
/// Send, with the box's text as the caption.
class PhotoTrayStrip extends StatelessWidget {
  const new({
    required this.photos,
    required this.onRemove,
    this.onAddMore,
    super.key,
  });

  final List<TrayPhoto> photos;
  final void Function(int key) onRemove;

  /// Opens the library for more; null hides the tile.
  final VoidCallback? onAddMore;

  /// A thumbnail's side, and the room each takes with its X.
  static const double _thumb = 72;
  static const double _cell = _thumb + 14;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final more =
        onAddMore != null && photos.length < Limits.messageAttachmentsMax;
    return SizedBox(
      height: _cell,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // Level with the box below it.
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final (i, t) in photos.indexed)
            SizedBox(
              key: ValueKey(t.key),
              width: _cell,
              height: _cell,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    width: _thumb,
                    height: _thumb,
                    child: Semantics(
                      image: true,
                      label: [
                        l10n.trayPhoto(i + 1, photos.length),
                        if (t.failed) l10n.trayUploadFailed,
                      ].join('. '),
                      child: _Thumb(photo: t),
                    ),
                  ),
                  // A 48 px target whose 26 px disc sits on the corner.
                  Positioned(
                    right: 0,
                    top: 0,
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: l10n.trayRemovePhoto(i + 1),
                      padding: EdgeInsets.zero,
                      onPressed: () => onRemove(t.key),
                      icon: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c.textOnPage,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.page, width: 2),
                        ),
                        child: Icon(
                          AppIcons.close,
                          size: 16,
                          weight: 700,
                          color: c.page,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (more)
            Align(
              alignment: Alignment.bottomLeft,
              child: Tooltip(
                message: l10n.trayAddMore,
                child: Material(
                  color: c.inputFill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: c.outline, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onAddMore,
                    child: SizedBox.square(
                      dimension: _thumb,
                      child: Icon(
                        AppIcons.photo,
                        color: c.textMutedOnPage,
                        semanticLabel: l10n.trayAddMore,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One waiting photo: the picture, corners 14, dimmed with a ring while it
/// uploads, or with a mark when its upload failed (it goes again on Send).
class _Thumb extends StatelessWidget {
  const new({required this.photo});

  final TrayPhoto photo;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final busy = !photo.uploaded && !photo.failed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            photo.photo.bytes,
            fit: BoxFit.cover,
            cacheWidth: (PhotoTrayStrip._thumb * dpr).round(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => ColoredBox(color: c.well),
          ),
          if (busy || photo.failed)
            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          if (busy)
            Center(
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(
                  value: photo.progress > 0 ? photo.progress : null,
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          if (photo.failed)
            const Center(
              child: Icon(AppIcons.warning, color: Colors.white, size: 26),
            ),
        ],
      ),
    );
  }
}
