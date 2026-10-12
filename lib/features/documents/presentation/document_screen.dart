import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/presentation/document_actions.dart';
import 'package:battleplan/features/documents/presentation/document_row.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'document_screen.g.dart';

/// Builds the PDF view for a file's bytes.
typedef PdfViewBuilder = Widget Function(Uint8List bytes, String name);

/// The PDF viewer (DOC-4): pdfrx on every platform, the web included.
/// Tests swap it for a stand-in, since PDFium doesn't run in them.
@Riverpod(keepAlive: true)
PdfViewBuilder pdfView(Ref ref) =>
    (bytes, name) => PdfViewer.data(bytes, sourceName: name);

/// `/g/:groupId/documents/d/:docId`, where notification taps land (DOC-4,
/// NOTIF-6): PDFs and images in the viewer, anything else as its details
/// with Open. Share and Download are always at hand.
class DocumentScreen extends ConsumerWidget {
  const new({required this.groupId, required this.docId, super.key});

  final GroupId groupId;
  final DocumentId docId;

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/g/${groupId.value}/documents');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final doc = ref.watch(documentProvider(docId));
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final d = doc.value;
    if (doc.isLoading && d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Gone, or from another team than the route names.
    if (d == null || d.groupId != groupId || group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: AppIcons.documents,
          message: doc.hasError ? l10n.loadError : l10n.documentGone,
        ),
      );
    }
    // HEIC photos show as details on the web, which can't decode them.
    final web = ref.watch(fileChooserProvider).downloadsInsteadOfOpening;
    final viewer = d.opensInAppOn(web: web) && d.path != null;
    return Scaffold(
      backgroundColor: viewer && d.type == DocumentType.image
          ? Colors.black
          : null,
      appBar: AppBar(
        backgroundColor: viewer && d.type == DocumentType.image
            ? Colors.black
            : null,
        foregroundColor: viewer && d.type == DocumentType.image
            ? Colors.white
            : null,
        title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!d.isLink)
            IconButton(
              tooltip: l10n.download,
              icon: const Icon(AppIcons.download),
              onPressed: () => unawaited(downloadDocument(context, ref, d)),
            ),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(AppIcons.share),
            onPressed: () => unawaited(shareDocument(context, ref, d)),
          ),
          DocumentMenu(
            doc: d,
            group: group,
            me: me,
            inViewer: true,
            onDeleted: () => _leave(context),
          ),
        ],
      ),
      body: viewer ? _Viewer(doc: d) : _Details(doc: d),
    );
  }
}

/// A PDF or an image, loaded once (at most 10 MB).
class _Viewer extends ConsumerWidget {
  const new({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bytes = ref.watch(documentFileBytesProvider(doc.path!));
    return switch (bytes) {
      AsyncData(:final value?) when doc.type == DocumentType.image =>
        InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.memory(
              value,
              fit: BoxFit.contain,
              semanticLabel: doc.name,
              // One this platform can't decode can still be downloaded
              // and opened in another app (DOC-4).
              errorBuilder: (_, _, _) =>
                  _Failed(text: l10n.documentImageFailed),
            ),
          ),
        ),
      AsyncData(:final value?) => ref.watch(pdfViewProvider)(
        value,
        doc.fileName,
      ),
      AsyncData() || AsyncError() => _Failed(
        text: doc.type == DocumentType.pdf
            ? l10n.documentPdfFailed
            : l10n.loadError,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Failed extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: AppIcons.error, message: text);
}

/// Everything else (DOC-4): what it is, who added it, the description,
/// and Open (the phone's default app, the browser for links, or a
/// download on the web).
class _Details extends ConsumerWidget {
  const new({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final what = doc.isLink ? (doc.url ?? '') : formatBytes(doc.size ?? 0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.all(gutter),
          children: [
            Row(
              children: [
                DocumentThumbnail(doc: doc),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(doc.name, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            SelectableText(what, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Space.xs),
            Text(
              l10n.documentAddedBy(
                doc.uploaderName,
                documentDate(doc.createdAt, DateTime.now()),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (doc.description.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              Text(doc.description),
            ],
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              icon: const Icon(AppIcons.openExternal),
              label: Text(l10n.documentOpen),
              onPressed: () => unawaited(openDocument(context, ref, doc)),
            ),
          ],
        ),
      ),
    );
  }
}
