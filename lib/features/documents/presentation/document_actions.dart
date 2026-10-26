import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// "2:15 PM" today, "Oct 6" this year, "Oct 6, 2025" before (DOC-1).
String documentDate(DateTime? when, DateTime now) {
  if (when == null) return '';
  final t = when.toLocal();
  final n = now.toLocal();
  if (t.year == n.year && t.month == n.month && t.day == n.day) {
    return DateFormat.jm().format(t);
  }
  return t.year == n.year
      ? DateFormat.MMMd().format(t)
      : DateFormat.yMMMd().format(t);
}

/// The icon for a document's type (DOC-1).
IconData documentIcon(DocumentType type) => switch (type) {
  DocumentType.pdf => AppIcons.pdf,
  DocumentType.image => AppIcons.image,
  DocumentType.word || DocumentType.text => AppIcons.document,
  DocumentType.excel || DocumentType.csv => AppIcons.spreadsheet,
  DocumentType.powerpoint => AppIcons.slides,
  DocumentType.link => AppIcons.link,
  DocumentType.other => AppIcons.file,
};

/// Opens a document (DOC-4): PDFs and images in the app's viewer, links in
/// the browser, and other files in the phone's default app, or as a
/// download in the browser.
Future<void> openDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  if (doc.isLink) {
    final uri = Uri.tryParse(doc.url ?? '');
    final opened = uri != null && await ref.read(linkOpenerProvider).open(uri);
    if (!opened && context.mounted) {
      showAppSnackBar(context, l10n.documentOpenFailed);
    }
    return;
  }
  final web = ref.read(fileChooserProvider).downloadsInsteadOfOpening;
  if (doc.opensInAppOn(web: web)) {
    unawaited(
      context.push('/g/${doc.groupId.value}/documents/d/${doc.id.value}'),
    );
    return;
  }
  if (web) {
    await downloadDocument(context, ref, doc);
    return;
  }
  // On phones the file itself goes to the default app for its type; when
  // no app takes it, the browser gets its address instead.
  final bytes = await _bytes(ref, doc);
  var opened =
      bytes != null &&
      await ref
          .read(fileChooserProvider)
          .openFile(
            bytes,
            name: doc.fileName,
            mimeType: doc.contentType ?? 'application/octet-stream',
          );
  if (!opened) {
    final path = doc.path;
    final url = path == null
        ? null
        : await ref.read(documentRepositoryProvider).fileUrl(path);
    opened =
        url != null && await ref.read(linkOpenerProvider).open(Uri.parse(url));
  }
  if (!opened && context.mounted) {
    showAppSnackBar(context, l10n.documentOpenFailed);
  }
}

/// Shares a document (DOC-4): the file itself through the share sheet, or
/// a link's address. Where the browser has no Web Share, a link's address
/// is copied instead (SPEC §4.2), as shareEvent does.
Future<void> shareDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  final sharer = ref.read(sharerProvider);
  bool shared;
  if (doc.isLink) {
    final uri = Uri.tryParse(doc.url ?? '');
    shared = uri != null && await sharer.shareLink(uri, subject: doc.name);
    if (!shared && uri != null) {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (context.mounted) showAppSnackBar(context, l10n.linkCopied);
      return;
    }
  } else {
    final bytes = await _bytes(ref, doc);
    shared =
        bytes != null &&
        await sharer.shareFile(
          bytes,
          name: doc.fileName,
          mimeType: doc.contentType ?? 'application/octet-stream',
        );
  }
  if (!shared && context.mounted) {
    showAppSnackBar(context, l10n.documentShareFailed);
  }
}

/// Downloads a file (DOC-4): the browser saves it on the web, the system's
/// save dialog on phones.
Future<void> downloadDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  final bytes = await _bytes(ref, doc);
  final saved =
      bytes != null &&
      await ref
          .read(fileChooserProvider)
          .saveFile(
            bytes,
            name: doc.fileName,
            mimeType: doc.contentType ?? 'application/octet-stream',
          );
  if (!context.mounted) return;
  showAppSnackBar(
    context,
    saved ? l10n.documentDownloaded : l10n.documentDownloadFailed,
  );
}

Future<Uint8List?> _bytes(WidgetRef ref, Document doc) async {
  final path = doc.path;
  if (path == null) return null;
  try {
    return await ref.read(documentFileBytesProvider(path).future);
  } on Object {
    return null;
  }
}

/// Renames a document and edits its description (DOC-5).
Future<void> editDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showAdaptiveSheet<(String, String)>(
    context,
    builder: (_) => _EditForm(doc: doc),
  );
  if (result == null) return;
  try {
    await ref
        .read(documentRepositoryProvider)
        .update(doc, name: result.$1, description: result.$2);
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.documentActionFailed);
  }
}

/// Deletes a document after asking (DOC-5). Returns true if deleted.
Future<bool> deleteDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.documentDeleteTitle(doc.name),
    message: l10n.documentDeleteBody,
    confirmLabel: l10n.deleteDocumentAction,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!ok) return false;
  try {
    await ref.read(documentRepositoryProvider).delete(doc);
    if (context.mounted) showAppSnackBar(context, l10n.documentDeleted);
    return true;
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.documentActionFailed);
    return false;
  }
}

/// Pins or unpins a document (admins, DOC-5).
Future<void> togglePin(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await ref
        .read(documentRepositoryProvider)
        .setPinned(doc, pinned: !doc.pinned);
    if (context.mounted) {
      showAppSnackBar(
        context,
        doc.pinned ? l10n.documentUnpinnedDone : l10n.documentPinnedDone,
      );
    }
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.documentActionFailed);
  }
}

enum DocumentAction {
  open,
  share,
  download,
  details,
  edit,
  pin,
  delete,
  report,
}

/// The actions [me] may take on [doc], in menu order (DOC-4, DOC-5,
/// SAFE-1). [inViewer] leaves out what the viewer shows as buttons.
List<DocumentAction> documentActions(
  Document doc,
  Group group,
  Membership? me, {
  bool superAdmin = false,
  bool inViewer = false,
}) => [
  if (!inViewer) DocumentAction.open,
  if (!inViewer) DocumentAction.share,
  if (!inViewer && !doc.isLink) DocumentAction.download,
  if (!inViewer) DocumentAction.details,
  if (canManageDocument(doc, group, me, superAdmin: superAdmin))
    DocumentAction.edit,
  if (canPinDocument(group, me, superAdmin: superAdmin)) DocumentAction.pin,
  if (canDeleteDocument(doc, group, me, superAdmin: superAdmin))
    DocumentAction.delete,
  if (canReportDocument(doc, me)) DocumentAction.report,
];

/// A document's ⋯ menu, for its row and its viewer.
class DocumentMenu extends ConsumerWidget {
  const new({
    required this.doc,
    required this.group,
    required this.me,
    this.inViewer = false,
    this.onDeleted,
    super.key,
  });

  final Document doc;
  final Group group;
  final Membership? me;
  final bool inViewer;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final actions = documentActions(
      doc,
      group,
      me,
      superAdmin: superAdmin,
      inViewer: inViewer,
    );
    if (actions.isEmpty) return const SizedBox.shrink();
    String label(DocumentAction a) => switch (a) {
      DocumentAction.open => l10n.documentOpen,
      DocumentAction.share => l10n.share,
      DocumentAction.download => l10n.download,
      DocumentAction.details => l10n.documentDetails,
      DocumentAction.edit => l10n.documentEdit,
      DocumentAction.pin => doc.pinned ? l10n.documentUnpin : l10n.documentPin,
      DocumentAction.delete => l10n.documentDelete,
      DocumentAction.report => l10n.documentReport,
    };
    IconData icon(DocumentAction a) => switch (a) {
      DocumentAction.open => AppIcons.openExternal,
      DocumentAction.share => AppIcons.share,
      DocumentAction.download => AppIcons.download,
      DocumentAction.details => AppIcons.info,
      DocumentAction.edit => AppIcons.edit,
      DocumentAction.pin => AppIcons.pin,
      DocumentAction.delete => AppIcons.delete,
      DocumentAction.report => AppIcons.report,
    };
    Future<void> run(DocumentAction a) async {
      switch (a) {
        case DocumentAction.open:
          await openDocument(context, ref, doc);
        case DocumentAction.share:
          await shareDocument(context, ref, doc);
        case DocumentAction.download:
          await downloadDocument(context, ref, doc);
        case DocumentAction.details:
          unawaited(
            context.push('/g/${doc.groupId.value}/documents/d/${doc.id.value}'),
          );
        case DocumentAction.edit:
          await editDocument(context, ref, doc);
        case DocumentAction.pin:
          await togglePin(context, ref, doc);
        case DocumentAction.delete:
          if (await deleteDocument(context, ref, doc)) onDeleted?.call();
        case DocumentAction.report:
          await showReportSheet(
            context,
            ref,
            groupId: doc.groupId,
            targetType: ReportTargetType.document,
            targetId: doc.id.value,
          );
      }
    }

    return PopupMenuButton<DocumentAction>(
      tooltip: l10n.documentMoreActions,
      // A hamburger at the viewer's top right, dots on a row.
      icon: Icon(inViewer ? AppIcons.menu : AppIcons.more),
      onSelected: (a) => unawaited(run(a)),
      itemBuilder: (_) => [
        for (final a in actions)
          PopupMenuItem(
            value: a,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon(a)),
              title: Text(label(a)),
            ),
          ),
      ],
    );
  }
}

/// Name and description (DOC-5).
class _EditForm extends StatefulWidget {
  const new({required this.doc});

  final Document doc;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final _name = TextEditingController(text: widget.doc.name);
  late final _description = TextEditingController(text: widget.doc.description);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid =
        isValidDocumentName(_name.text) &&
        isValidDocumentDescription(_description.text);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.xl,
          Space.xl,
          Space.xl,
          Space.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.documentEditTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.lg),
            DocumentFields(
              name: _name,
              description: _description,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: valid
                  ? () =>
                        Navigator.of(context)
                            .pop((_name.text.trim(), _description.text.trim()))
                  : null,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// The name and optional description fields every document form has.
class DocumentFields extends StatelessWidget {
  const new({
    required this.name,
    required this.description,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController name;
  final TextEditingController description;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameBad =
        name.text.isNotEmpty && !isValidDocumentName(name.text) ||
        name.text.runes.length > Limits.documentNameMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: name,
          enabled: enabled,
          maxLength: Limits.documentNameMax,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.documentNameLabel,
            errorText: nameBad
                ? l10n.documentNameInvalid(Limits.documentNameMax)
                : null,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: description,
          enabled: enabled,
          maxLength: Limits.documentDescriptionMax,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.documentDescriptionLabel,
            errorText: isValidDocumentDescription(description.text)
                ? null
                : l10n.documentDescriptionTooLong(
                    Limits.documentDescriptionMax,
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
