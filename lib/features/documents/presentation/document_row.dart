import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/presentation/document_actions.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One document in the list (DOC-1): its type icon or a thumbnail, the
/// name, then size (or the link's site), who added it, and when. Tapping
/// opens it (DOC-4); ⋯ has the rest.
class DocumentRow extends ConsumerWidget {
  const new({
    required this.doc,
    required this.group,
    required this.me,
    required this.onTap,
    super.key,
  });

  final Document doc;
  final Group group;
  final Membership? me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final what = doc.isLink
        ? (Uri.tryParse(doc.url ?? '')?.host ?? l10n.documentKindLink)
        : formatBytes(doc.size ?? 0);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.only(
        left: Space.gutter(MediaQuery.sizeOf(context).width),
        right: Space.xs,
      ),
      leading: DocumentThumbnail(doc: doc),
      title: Row(
        children: [
          if (doc.pinned) ...[
            Icon(
              AppIcons.pin,
              size: 16,
              fill: 1,
              color: theme.colorScheme.primary,
              semanticLabel: l10n.documentPinnedLabel,
            ),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      subtitle: Text(
        l10n.documentRowLine(
          what,
          doc.uploaderName,
          documentDate(doc.createdAt, DateTime.now()),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: DocumentMenu(doc: doc, group: group, me: me),
    );
  }
}

/// A 40 px square: the image itself for images, otherwise the type icon.
class DocumentThumbnail extends ConsumerWidget {
  const new({required this.doc, super.key});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Corners.chip),
      ),
      child: Icon(documentIcon(doc.type), color: scheme.onSurfaceVariant),
    );
    final path = doc.path;
    if (doc.type != DocumentType.image || path == null) return icon;
    final url = ref.watch(documentFileUrlProvider(path)).value;
    if (url == null) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.chip),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        cacheWidth: 120,
        errorBuilder: (_, _, _) => icon,
      ),
    );
  }
}
