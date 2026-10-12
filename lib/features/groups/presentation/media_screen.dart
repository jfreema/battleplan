import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Team menu → Media at `/g/:groupId/media` (STORE-5), for team admins:
/// the storage meter, then every stored file largest first with a preview,
/// what it is and who added it, its size and date, and Delete after
/// confirming.
class MediaScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final (title, body) = _deleteWording(l10n, item);
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: body,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    String done;
    try {
      await ref.read(mediaRepositoryProvider).delete(groupId, item.path);
      done = l10n.mediaDeleted;
    } on AppFailure catch (e) {
      done = e is PermissionDenied ? l10n.notAllowed : l10n.signInUnknownError;
    }
    if (!context.mounted) return;
    showAppSnackBar(context, done);
    // Read the list again either way: what's stored is the server's to say.
    ref.invalidate(teamMediaProvider(groupId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    if (membership != null && !membership.isAdmin && !superAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.mediaMenu)),
        body: EmptyState(icon: AppIcons.media, message: l10n.notAllowed),
      );
    }
    final group = ref.watch(groupProvider(groupId)).value;
    final media = ref.watch(teamMediaProvider(groupId));
    final items = media.value?.items;

    final Widget content;
    if (items != null && items.isEmpty) {
      content = EmptyState(icon: AppIcons.media, message: l10n.mediaEmpty);
    } else if (items != null) {
      content = RefreshIndicator(
        onRefresh: () => ref.refresh(teamMediaProvider(groupId).future),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _MediaRow(
            item: items[i],
            onDelete: () => unawaited(_delete(context, ref, items[i])),
          ),
        ),
      );
    } else if (media.hasError) {
      content = EmptyState(
        icon: AppIcons.error,
        message: l10n.loadError,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(teamMediaProvider(groupId)),
      );
    } else {
      content = const SkeletonList();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaMenu)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.sm,
                ),
                // The team's live numbers, which drop within seconds of a
                // delete; the list's own until the team has loaded.
                child: StorageMeter(
                  usedBytes:
                      group?.storageBytes ?? media.value?.storageBytes ?? 0,
                  quotaBytes:
                      group?.storageQuotaBytes ??
                      media.value?.storageQuotaBytes ??
                      0,
                ),
              ),
              if (media.value?.truncated ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Text(
                    l10n.mediaTruncated,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

/// One file: a preview (images) or an icon, what it is, size and date, and
/// Delete.
class _MediaRow extends ConsumerWidget {
  const new({required this.item, required this.onDelete});

  final MediaItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = mediaKindLabel(l10n, item);
    final url = item.isImage
        ? ref.watch(teamPhotoUrlProvider(item.path)).value
        : null;
    final date = item.createdAt == null
        ? null
        : MaterialLocalizations.of(context)
              .formatShortDate(item.createdAt!.toLocal());
    final placeholder = Icon(
      item.isImage ? AppIcons.photo : AppIcons.file,
      color: scheme.onSurfaceVariant,
    );
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(Corners.chip),
        child: Container(
          width: 56,
          height: 56,
          color: scheme.surfaceContainerHigh,
          child: url == null
              ? placeholder
              : Image(
                  // Previews are small; don't decode a 2048 px photo.
                  image: CoverResizeImage.forBox(
                    NetworkImage(url),
                    logicalWidth: 56,
                    logicalHeight: 56,
                    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  ),
                  fit: BoxFit.cover,
                  semanticLabel: label,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
      title: Text(label),
      subtitle: Text(
        date == null
            ? formatBytes(item.size)
            : l10n.mediaSizeDate(formatBytes(item.size), date),
      ),
      trailing: IconButton(
        tooltip: l10n.delete,
        icon: Icon(AppIcons.delete, color: scheme.error),
        onPressed: onDelete,
      ),
    );
  }
}

/// "Chat photo · Sam Rivera", "Team logo", "Chat background", a document
/// ("Fall roster.pdf · Sam Rivera", or "Document" once its record is gone),
/// or "Unused file" (STORE-5). A photo no message shows (say, from a send
/// that failed), or a logo or background the team no longer uses, says so.
String mediaKindLabel(AppLocalizations l10n, MediaItem item) =>
    switch (item.kind) {
      MediaKind.chatPhoto when item.current == false =>
        l10n.mediaKindUnusedChatPhoto,
      MediaKind.chatPhoto => switch (item.authorName) {
        final name? when name.isNotEmpty => l10n.mediaKindChatPhoto(name),
        _ => l10n.mediaKindChatPhotoNoName,
      },
      MediaKind.logo =>
        item.current == false ? l10n.mediaKindOldLogo : l10n.mediaKindLogo,
      MediaKind.background =>
        item.current == false
            ? l10n.mediaKindOldBackground
            : l10n.mediaKindBackground,
      MediaKind.document => switch ((item.documentName, item.authorName)) {
        (final doc?, final name?) when doc.isNotEmpty && name.isNotEmpty =>
          l10n.mediaKindDocumentNamed(doc, name),
        (final doc?, _) when doc.isNotEmpty => doc,
        _ => l10n.mediaKindDocument,
      },
      MediaKind.other => l10n.mediaKindOther,
    };

/// What deleting does, in the confirm dialog: a chat photo leaves its
/// message, and the logo or background resets (ARCH §6.11). A file nothing
/// shows gets the plain wording.
(String, String) _deleteWording(AppLocalizations l10n, MediaItem item) =>
    switch (item.kind) {
      MediaKind.chatPhoto when item.current != false => (
        l10n.deleteMediaPhotoTitle,
        l10n.deleteMediaPhotoBody,
      ),
      MediaKind.logo when item.current != false => (
        l10n.deleteMediaLogoTitle,
        l10n.deleteMediaLogoBody,
      ),
      MediaKind.background when item.current != false => (
        l10n.deleteMediaBackgroundTitle,
        l10n.deleteMediaBackgroundBody,
      ),
      MediaKind.document => (
        l10n.deleteMediaDocumentTitle,
        l10n.deleteMediaDocumentBody,
      ),
      _ => (l10n.deleteMediaFileTitle, l10n.deleteMediaFileBody),
    };
