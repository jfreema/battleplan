import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Photos (DOC-7), from the Documents tab: every photo shared in the team's
/// chat, newest first, as a grid of squares. A tap opens it full screen,
/// where a swipe goes through the others loaded so far, with Share and Save.
/// More load as the grid nears its end.
class TeamPhotosScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  /// The smallest a square is drawn; more columns fit on wider screens.
  static const double _minTile = 110;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(teamPhotosProvider(groupId));
    final photos = state.photos;
    void loadMore() {
      // After this frame: the grid asks while it builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          unawaited(ref.read(teamPhotosProvider(groupId).notifier).loadMore());
        }
      });
    }

    final Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (photos.isEmpty && state.failed) {
      body = Center(child: Text(l10n.loadError));
    } else if (photos.isEmpty && state.reachedEnd) {
      body = EmptyState(icon: AppIcons.photo, message: l10n.photosEmpty);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final gutter = Space.gutter(constraints.maxWidth);
          final width = constraints.maxWidth - 2 * gutter;
          final columns = (width / _minTile).floor().clamp(3, 8);
          const gap = 3.0;
          final tile = (width - gap * (columns - 1)) / columns;
          final more = !state.reachedEnd;
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxl),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemCount: photos.length + (more ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= photos.length - columns && more && !state.failed) {
                loadMore();
              }
              if (i == photos.length) {
                return Center(
                  child: state.failed
                      ? IconButton(
                          tooltip: l10n.retry,
                          icon: const Icon(AppIcons.retry),
                          onPressed: () => unawaited(
                            ref
                                .read(teamPhotosProvider(groupId).notifier)
                                .loadMore(),
                          ),
                        )
                      : const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                );
              }
              final p = photos[i];
              final label = l10n.photoFrom(p.message.authorName);
              return Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Corners.chip),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => unawaited(
                        PhotoViewer.open(context, [
                          for (final q in photos) q.photo,
                        ], i),
                      ),
                      child: StoredPhoto(
                        attachment: p.photo,
                        decodeWidth: tile,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.photosTitle)),
      body: body,
    );
  }
}
